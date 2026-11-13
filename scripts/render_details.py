#!/usr/bin/env python3
"""Render README section views from drive.sv without changing the design model.

SOLVENTC=/path/to/solventc python scripts/render_details.py /absolute/output
The upper half is sectioned through the relevant axle; frame and shaft are
cropped in temporary copies solely to keep the view focused on that gearbox.
"""
import argparse
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]

BB = {
    'frame', 'shaft', 'bb_gear', 'bb_gear_core', 'bb_pinion', 'bb_pinion_core',
    'box', 'front_coupler', 'spindle', 'right_6804', 'left_6804', 'sleeve_6805',
    'bb_6903', 'bb_pinion_second', 'left_seal', 'right_seal', 'bb_pinion_seal',
    'left_static_seal', 'right_static_seal', 'inner_spacer', 'outer_spacer',
    'pinion_retainer', 'pinion_clip', 'sun_locknut', 'ring_adapter', 'adapter_spacer',
    'ring_dowel', 'spindle_adjuster',
}
REAR = {
    'frame', 'shaft', 'hub', 'thru_axle', 'hub_gear', 'hub_gear_core',
    'hub_pinion', 'hub_pinion_core', 'rear_coupler', 'rear_inner_spacer',
    'rear_outer_spacer', 'rear_pinion_retainer', 'rear_pinion_clip', 'hub_6903',
    'hub_pinion_second', 'right_6901', 'left_6901', 'hub_pinion_seal', 'hub_seal',
    'rear_oring', 'hub_inner_spacer', 'hub_locknut', 'axle_nut', 'right_endspacer',
    'left_endspacer', 'right_hub_ring', 'left_hub_ring',
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    parser.add_argument('--view', choices=['bottom-bracket', 'rear-hub', 'both'], default='both')
    parser.add_argument('--size', type=int, default=1400)
    args = parser.parse_args()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=True)
    source = (ROOT / 'drive.sv').read_text()
    # Native --hide is a list of object names, not a change to model constraints.
    names = BB | REAR | {'right_crank', 'left_crank', 'rear_wheel'}
    views = [
        ('bottom-bracket', BB, 'std.origin', (-135, 85, -95, 95, -80, 80), 'z=0mm', '300,35'),
        ('rear-hub', REAR, 'axle_c', (-80, 150, -125, 90, -80, 80), 'z=70mm', '300,35'),
    ]
    with tempfile.TemporaryDirectory(prefix='detail-model-', dir=output) as temp:
        temp = Path(temp)
        for file in ROOT.glob('*.sv'):
            shutil.copy2(file, temp / file.name)
        shutil.copytree(ROOT / 'spiral_bevel', temp / 'spiral_bevel')
        for name, keep, center, bounds, section, view in views:
            if args.view not in ('both', name):
                continue
            x0, x1, y0, y1, z0, z1 = bounds
            crop = f'''\n// Presentation-only crop. Production geometry is in drive.sv.
construction detail_window := solid({{q |
  {center} distance(in: ({x0}mm, {x1}mm), along: std.x) q
  {center} distance(in: ({y0}mm, {y1}mm), along: std.y) q
  {center} distance(in: ({z0}mm, {z1}mm), along: std.z) q
}})
detail_window common frame
detail_window common shaft
'''
            model = temp / f'{name}.sv'
            model.write_text(source + crop)
            hidden = names - keep
            for array, count in [('ring_dowel', 6), ('spindle_adjuster', 2)]:
                if array in hidden:
                    hidden.remove(array)
                    hidden.update(f'{array}[{i}]' for i in range(count))
            command = [os.environ.get('SOLVENTC', 'solventc'), str(model),
                       '--no-check', '--no-progress', '--timings', '--png',
                       str(output / f'{name}-cutaway.png'), '--view', view,
                       '--section', section, '--size', str(args.size),
                       '--hide', ','.join(sorted(hidden))]
            with (output / f'{name}-render.txt').open('w') as log:
                result = subprocess.run(command, cwd=temp, stdout=log, stderr=subprocess.STDOUT)
            if result.returncode:
                raise SystemExit(f'{name}: renderer exited {result.returncode}; see {output / (name + "-render.txt")}')
            print(f'Rendered {output / (name + "-cutaway.png")}', flush=True)


if __name__ == '__main__':
    main()
