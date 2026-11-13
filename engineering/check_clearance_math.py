"""Small independent regressions for the clearance calculation's conventions."""
import numpy as np
from clearance import torus_distance,spoke_function,minimum_on_mesh
O=np.zeros(3)
assert np.allclose(torus_distance([[348,0,0],[329.5,18.5,0],[329.5,0,0]],O,329.5,18.5),[0,0,-18.5])
assert np.isclose(torus_distance([[353,0,0]],O,329.5,18.5)[0],5)
sdf,error=spoke_function(O,[-30,30])
# Elbow endpoints are on the swept centerline; the function subtracts radius 1.05.
assert np.isclose(sdf(np.array([[24,-32.55,0]]))[0],-1.05)
assert 0<error<.007
# A constant-z triangle's exact distance to z=0 is 5 mm.
tri=np.array([[[0.,0.,5.],[1.,0.,5.],[0.,1.,5.]]])
r=minimum_on_mesh(tri,lambda p:p[:,2],tolerance=.01,mesh_error=0)
assert r['conservative_lower_mm']<=5<=r['upper_mm']
assert r['upper_mm']-r['conservative_lower_mm']<=.01000001
print('PASS: torus coordinates, spoke endpoint convention and triangle distance bounds')
