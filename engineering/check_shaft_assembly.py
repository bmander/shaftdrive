#!/usr/bin/env python3
"""Continuous conservative tube/shaft assembly sweeps against exported fixed housings.

Requires native frame_main and drive_cap meshes and solventc --json --where
assembly_front --where hub_foot --where flip output. Fitted threads, seal lips,
bearing fits and intentional tooth engagement are checked separately in the notes.
"""
import argparse
import hashlib
import json
from pathlib import Path
import numpy as np
from clearance import read_stl, minimum_on_mesh


def swept_cylinder(points, front, axis, lift, start, end, radius, travel=0):
    """Exact SDF of a finite cylinder swept sideways along lift by [0, travel]."""
    p = points - front
    t = p @ axis
    v = p @ lift
    side = np.cross(axis, lift)
    w = p @ side
    radial = np.hypot(w, v - np.clip(v, 0, travel)) - radius
    axial = np.abs(t - (start + end)/2) - (end - start)/2
    return np.minimum(np.maximum(radial, axial), 0) + np.hypot(
        np.maximum(radial, 0), np.maximum(axial, 0))


def run(meshes, datums, moving):
    doc = json.loads(datums.read_text())["documents"][0]
    assert doc["solve"]["success"]
    pos = doc["positions"]
    rear = np.array([pos["hub_foot."+c] for c in "xyz"])
    front = np.array([pos["assembly_front."+c] for c in "xyz"])
    lift = np.array([pos["flip."+c] for c in "xyz"])
    length = np.linalg.norm(rear-front)
    axis = (rear-front)/length
    assert abs(axis @ lift) < 1e-8 and abs(np.linalg.norm(lift)-1) < 1e-8
    # Outer envelopes include tube walls, front female fitting, rear capture
    # shoulder, rotating front coupling, tube shaft and rear male spline.
    # Empty internal volume is deliberately included: conservative for obstacles.
    sections = [(55, 67, 20), (63, length-106, 14),
                (length-116, length-114, 16), (53, 85, 11),
                (75, length-75.5, 9)]
    # Inflate the analytic envelopes by 0.03 mm, then prove that every
    # triangle of the exported moving parts lies in one convex cylinder.
    sections = [(lo-.03, hi+.03, r+.03) for lo, hi, r in sections]
    containment = {}
    for path in moving:
        part = read_stl(path)
        distances = [swept_cylinder(part.reshape(-1, 3), front, axis, lift, lo, hi, r)
                     .reshape(-1, 3).max(axis=1) for lo, hi, r in sections]
        worst = float(np.min(distances, axis=0).max())
        if worst > 0:
            raise ValueError(f"{path}: moving envelope misses a triangle by {worst} mm")
        containment[path.name] = worst
    tri = np.concatenate([read_stl(p) for p in meshes])
    def field(stage):
        def sdf(points):
            if stage == "radial_entry":
                # First stage: case and shaft held 25 mm rearward, then raised
                # from 80 mm below the open service chamber onto the shaft axis.
                values = [swept_cylinder(points, front, axis, lift, lo+25, hi+25, r, 80)
                          for lo, hi, r in sections]
            else:
                # Then advance 25 mm. Circular envelopes also cover case-tube
                # rotation while engaging its M34x1 thread in the final 8 mm.
                values = [swept_cylinder(points, front, axis, lift, lo, hi+25, r)
                          for lo, hi, r in sections]
            return np.min(values, axis=0)
        return sdf
    result = {"method": "1-Lipschitz continuous swept-envelope bounds over every STL triangle",
              "removed": ["rear wheel/pod", "dry service cover", "split rear case closure"],
              "excluded_from_sweep": ["M34 thread and carrier faces", "front spline engagement", "bearing/seal fits", "gear tooth engagement"],
              "front_mm": front.tolist(), "rear_mm": rear.tolist(),
              "entry_direction": lift.tolist(), "rearward_offset_mm": 25,
              "radial_travel_mm": 80,
              "moving_envelope_max_signed_mm": containment,
              "mesh_sha256": {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in meshes+moving}}
    for stage in ["radial_entry", "axial_engagement"]:
        result[stage] = minimum_on_mesh(tri, field(stage), tolerance=.20, mesh_error=.02)
        print(stage, result[stage]["conservative_lower_mm"], "mm lower bound", flush=True)
        result[stage]["passes_0_5mm"] = result[stage]["conservative_lower_mm"] >= .5
    # The advance starts with a 3 mm gap between female fitting and pinion tip.
    result["initial_spline_tip_gap_mm"] = 53 + 25 - 75
    result["front_case_thread_engagement_mm"] = 63 - 55
    result["front_female_to_seal_axial_gap_mm"] = 53 - 52
    result["front_female_to_carrier_radial_gap_mm"] = 12.5 - 11
    return result


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("frame_main", type=Path)
    p.add_argument("drive_cap", type=Path)
    p.add_argument("datums", type=Path)
    p.add_argument("--moving", type=Path, nargs=3, required=True, metavar=("CASE", "SHAFT", "COUPLER"))
    p.add_argument("--out", type=Path, required=True)
    a = p.parse_args()
    result = run([a.frame_main, a.drive_cap], a.datums, a.moving)
    a.out.write_text(json.dumps(result, indent=2)+"\n")
    print(json.dumps(result, indent=2))
    if not all(result[s]["passes_0_5mm"] for s in ["radial_entry", "axial_engagement"]):
        raise SystemExit("Assembly envelope does not establish 0.5 mm clearance")
