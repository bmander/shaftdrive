#!/usr/bin/env python3
"""Draw the checked installation path as sections through native STL geometry."""
import argparse
import json
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.collections import LineCollection
from clearance import read_stl


def section(path, origin, axis, down):
    tri = read_stl(path) - origin
    normal = np.cross(axis, down)
    d = tri @ normal
    tri = tri[(d.min(1) < 0) & (d.max(1) > 0)]
    segments = []
    for t in tri:
        ds = t @ normal
        hit = []
        for i,j in [(0,1),(1,2),(2,0)]:
            if (ds[i] < 0) != (ds[j] < 0):
                hit.append(t[i] + (t[j]-t[i]) * ds[i]/(ds[i]-ds[j]))
        if len(hit) == 2:
            segments.append([[p @ axis, -p @ down] for p in hit])
    return np.array(segments)


if __name__ == '__main__':
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('meshes',type=Path)
    p.add_argument('data',type=Path)
    p.add_argument('--out',type=Path,default=Path(__file__).with_name('shaft-assembly.png'))
    args=p.parse_args()
    data=json.loads(args.data.read_text())
    front=np.array(data['front_mm']);rear=np.array(data['rear_mm']);down=np.array(data['entry_direction'])
    length=np.linalg.norm(rear-front);axis=(rear-front)/length
    fixed=np.concatenate([section(args.meshes/(n+'.stl'),front,axis,down) for n in ['frame_main','drive_cap']])
    moving=np.concatenate([section(args.meshes/(n+'.stl'),front,axis,down) for n in ['shaft_case','shaft','front_coupler']])
    fig,axs=plt.subplots(2,1,figsize=(12,8),sharex=True)
    fig.patch.set_facecolor('#f7f9f6')
    for ax in axs:
        ax.set_facecolor('#f7f9f6')
        ax.add_collection(LineCollection(fixed,colors='#59655f',linewidths=1.2))
        ax.axhline(0,color='#afb8b1',lw=.7,ls='--')
        ax.set_xlim(-30,length+5);ax.set_ylim(-112,56);ax.set_aspect('equal')
        ax.set_ylabel('Distance above shaft axis (mm)')
        ax.spines[['top','right']].set_visible(False)
        ax.grid(alpha=.15)
    axs[0].add_collection(LineCollection(moving+[25,-80],colors='#176b9b',linewidths=1.6))
    axs[0].add_collection(LineCollection(moving+[25,0],colors='#176b9b',linewidths=1,alpha=.3))
    axs[0].annotate('Raise 80 mm',xy=(190,-5),xytext=(190,-65),ha='center',arrowprops={'arrowstyle':'->','color':'#176b9b','lw':2})
    axs[0].set_title('1  Raise the case and shaft from below, held 25 mm rearward',loc='left',fontweight='bold')
    axs[1].add_collection(LineCollection(moving+[25,0],colors='#176b9b',linewidths=1,alpha=.3))
    axs[1].add_collection(LineCollection(moving,colors='#176b9b',linewidths=1.6))
    axs[1].annotate('Advance 25 mm',xy=(170,-42),xytext=(245,-42),va='center',arrowprops={'arrowstyle':'->','color':'#176b9b','lw':2})
    axs[1].text(62,-76,'Final 8 mm: screw the outer case onto M34×1.\nClock and advance the inner shaft independently.',fontsize=10)
    axs[1].set_title('2  Engage the front spline and case thread; then fit the closures',loc='left',fontweight='bold')
    axs[1].set_xlabel('Station from front pinion mean point, along shaft (mm)')
    bound=min(data[k]['conservative_lower_mm'] for k in ['radial_entry','axial_engagement'])
    fig.suptitle('Driveshaft installation — sectioned native CAD geometry',fontsize=16,fontweight='bold',y=.98)
    fig.text(.08,.925,'Grey: fixed frame and BB cover. Blue: removable case, driveshaft and front coupling.',fontsize=10)
    fig.text(.08,.05,f'Wheel/pod, dry service cover and split closure removed. Continuous housing-clearance bound: {bound:.2f} mm.\nThread, spline, seal and bearing fits are assessed separately; this is not a manufacturing drawing.',fontsize=9,color='#4b5b52')
    fig.subplots_adjust(top=.89,bottom=.13,hspace=.25)
    fig.savefig(args.out,dpi=160)
