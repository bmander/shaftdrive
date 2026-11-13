"""Continuous wheel rotation clearance against exported frame triangles.

Branch-and-bound minimises a 1-Lipschitz signed distance over each STL
triangle. Bounds include a configurable STL surface error. Tire is a solid
torus envelope; spokes are their complete rotational swept envelopes.
Spoke meridians are approximated by chords with an explicit curvature bound.
No finite set of wheel angles substitutes for the swept envelope.
"""
import hashlib
import argparse, heapq, itertools, json, math, struct
from pathlib import Path
import numpy as np

def read_stl(path):
    raw=Path(path).read_bytes()
    dtype=np.dtype([('n','<f4',(3,)),('v','<f4',(3,3)),('a','<u2')])
    return np.frombuffer(raw, dtype=dtype, offset=84)['v'].astype(float)

def torus_distance(points, center, major, minor):
    p=np.asarray(points)-center
    r=np.hypot(p[...,0],p[...,2])
    return np.hypot(r-major,p[...,1])-minor

def spoke_function(center, flange, rim_r=298, hub_r=24, cross=3, count=32,
                   spoke_radius=1.05, lateral_allowance=0):
    # Alternating 3-cross spokes: +/-67.5 degrees with sixteen per flange.
    angle=2*math.pi*cross/(count/2)
    t=np.linspace(0,1,257)
    r=np.sqrt((1-t)**2*hub_r**2+t*t*rim_r**2+2*t*(1-t)*hub_r*rim_r*math.cos(angle))
    starts=[];ends=[]
    for f in flange:
        for elbow in [-2.55,2.55]:
            y=(f+elbow)*(1-t)+math.copysign(1.5,f)*t
            curve=np.stack([r,y],axis=1)
            starts.extend(curve[:-1]);ends.extend(curve[1:])
    starts=np.array(starts);vectors=np.array(ends)-starts
    lengths=(vectors*vectors).sum(axis=1)
    # r'' <= R^2 sin(angle)^2 / hub_r for this monotonically increasing radius.
    approximation_error=rim_r**2*math.sin(angle)**2/hub_r/(8*256**2)
    def sdf(points):
        p=np.asarray(points)-center
        q=np.stack([np.hypot(p[...,0],p[...,2]),p[...,1]],axis=-1)
        out=[]
        for batch in np.array_split(q,max(1,math.ceil(len(q)/128))):
            d=batch[:,None,:]-starts
            u=np.clip((d*vectors).sum(axis=2)/lengths,0,1)
            distance=np.linalg.norm(d-u[:,:,None]*vectors,axis=2).min(axis=1)
            out.extend(distance-spoke_radius-lateral_allowance)
        return np.array(out)
    return sdf,approximation_error

def minimum_on_mesh(triangles, sdf, tolerance=.08, mesh_error=.03):
    center=triangles.mean(axis=1)
    d=sdf(center)
    radii=np.linalg.norm(triangles-center[:,None,:],axis=2).max(axis=1)
    best=float(d.min());point=center[d.argmin()].copy()
    serial=itertools.count();heap=[]
    for i in np.where(d-radii<best-tolerance)[0]:
        heapq.heappush(heap,(float(d[i]-radii[i]),next(serial),triangles[i]))
    iterations=0
    while heap and heap[0][0]<best-tolerance:
        lower,_,triangle=heapq.heappop(heap)
        edges=[(0,1),(1,2),(2,0)]
        a,b=max(edges,key=lambda ab:np.linalg.norm(triangle[ab[0]]-triangle[ab[1]]))
        m=(triangle[a]+triangle[b])/2
        children=np.stack([triangle.copy(),triangle.copy()]);children[0,a]=m;children[1,b]=m
        centers=children.mean(axis=1);ds=sdf(centers)
        for child,c,dc in zip(children,centers,ds):
            if dc<best:best=float(dc);point=c.copy()
            lb=float(dc-np.linalg.norm(child-c,axis=1).max())
            if lb<best-tolerance:heapq.heappush(heap,(lb,next(serial),child))
        iterations+=1
        if iterations>2000000:raise RuntimeError('Clearance refinement did not converge')
    lower=min(best-tolerance,heap[0][0] if heap else best-tolerance)
    return {'measured_mm':best,'conservative_lower_mm':lower-mesh_error,
            'upper_mm':best+mesh_error,'closest_frame_point_mm':point.tolist(),
            'refined_triangles':iterations,'tolerance_mm':tolerance,'mesh_error_mm':mesh_error}

def run(frame,cs,drop,flanges):
    center=np.array([-math.sqrt(cs*cs-drop*drop),0,drop]);tri=read_stl(frame)
    result={'frame':str(frame),'frame_sha256':hashlib.sha256(Path(frame).read_bytes()).hexdigest(),'axle_center_mm':center.tolist(),'flange_centers_mm':flanges}
    for name,major,minor in [('tire_37',329.5,18.5),('tire_40',331,20),('tire_40_movement',331,22)]:
        # The final envelope adds 2 mm in every direction, conservatively
        # bounding +/-2 mm lateral movement and up to 2 mm radial growth.
        result[name]=minimum_on_mesh(tri,lambda p:torus_distance(p,center,major,minor))
    fn,err=spoke_function(center,flanges)
    result['spokes_full_rotation']=minimum_on_mesh(tri,fn,mesh_error=.03+err)
    result['spoke_chord_error_mm']=err
    return result

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('frame');p.add_argument('--cs',type=float,default=430)
    p.add_argument('--drop',type=float,default=70);p.add_argument('--flanges',type=float,nargs=2,default=[-12.5,34.5])
    p.add_argument('--out',required=True);a=p.parse_args()
    result=run(a.frame,a.cs,a.drop,a.flanges)
    Path(a.out).write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
