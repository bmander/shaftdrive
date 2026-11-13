#!/usr/bin/env bash
# Rebuild the engineering revision. The rolling checks took 40+ minutes before solventc v0.1.21,
# which builds each gear once and moves it to every sample; on v0.1.21 they take about a minute each.
# SOLVENTC=/path/to/solventc scripts/export.sh /absolute/output
# SKIP_ROLLING=1 is a geometry-only build and leaves mesh verification unperformed.
set -uo pipefail
cd "$(dirname "$0")/.."
out=${1:-out}
mkdir -p "$out"
out=$(cd "$out" && pwd)
solventc=${SOLVENTC:-solventc}
mkdir -p "$out/png" "$out/stl/exact" "$out/stl/visualization" "$out/reports"
failed=0
run() {
  local name=$1; shift
  "$solventc" --no-progress --timings "$@" > "$out/reports/$name.txt" 2>&1
  local status=$?
  echo "$name: compiler exit $status; see $out/reports/$name.txt"
  [ "$status" -eq 0 ] || failed=1
}
run dims-release dims.sv
python engineering/verify.py > "$out/reports/physics.txt" || failed=1
python engineering/check_clearance_math.py > "$out/reports/clearance-math.txt" || failed=1
run wheel wheel.sv --no-check --png "$out/png/wheel.png" --view 300,20 --size 1200
run planetary-exact planetary.sv --no-check \
 --stl "$out/stl/exact/sun.stl" --solid box.sun.body \
 --stl "$out/stl/exact/ring.stl" --solid box.ring.body \
 --png "$out/png/planetary_iso.png" --view 30,35 --size 1100 \
 --png "$out/png/planetary_top.png" --view top --size 1100 --hide box.carrier
run planetary-release planetary.sv --no-check --stl-backend mesh --stl "$out/stl/visualization/planet.stl" --solid box.planet[0].body
args=()
for binding in 'frame:frame' 'frame_main:frame_main' 'rear_pod:rear_pod' 'rear_cover:rear_cover.body' 'service_cover:service_cover' 'bearing_cup:left_cap.body' 'drive_cap:drive_cap' 'shaft_case:shaft_case' 'front_seal_carrier:front_seal_carrier' 'front_coupler:front_coupler.body' 'rear_case_closure_lower:rear_case_closure[0]' 'rear_case_closure_upper:rear_case_closure[1]' 'hub:hub' 'shaft:shaft' 'spindle:spindle' 'crank:right_crank.body' 'carrier:box.carrier_base' 'carrier_cover:box.plate_drive' 'rear_coupler:rear_coupler.body' 'ring_adapter:ring_adapter' 'thru_axle:thru_axle' 'bb_gear_core:bb_gear_core' 'hub_gear_core:hub_gear_core' 'bb_pinion_core:bb_pinion_core' 'hub_pinion_core:hub_pinion_core'; do
 name=${binding%%:*}; solid=${binding#*:}
 args+=(--stl "$out/stl/exact/$name.stl" --solid "$solid")
done
run drive-release drive.sv "${args[@]}" \
 --png "$out/png/drive_iso.png" --view 300,20 --size 1400 \
 --png "$out/png/drive_cutaway.png" --view 300,20 --size 1400 --hide frame \
 --png "$out/png/drive_top.png" --view top --size 1400 --hide frame \
 --png "$out/png/drive_right.png" --view right --size 1400
run bevel-exports drive.sv --no-check --stl-backend mesh \
 --stl "$out/stl/visualization/bb_gear.stl" --solid bb_gear \
 --stl "$out/stl/visualization/hub_gear.stl" --solid hub_gear \
 --stl "$out/stl/visualization/bb_pinion.stl" --solid bb_pinion \
 --stl "$out/stl/visualization/hub_pinion.stl" --solid hub_pinion
python engineering/clearance.py "$out/stl/exact/frame.stl" --cs 460 --flanges -30 30 --out engineering/clearance-final.json > "$out/reports/clearance-final.txt" 2>&1 || failed=1
"$solventc" drive.sv --no-check --no-progress --json --where assembly_front --where hub_foot --where flip > "$out/reports/assembly-datums.json" 2> "$out/reports/assembly-datums.stderr.txt" || failed=1
python engineering/check_shaft_assembly.py "$out/stl/exact/frame_main.stl" "$out/stl/exact/drive_cap.stl" "$out/reports/assembly-datums.json" --moving "$out/stl/exact/shaft_case.stl" "$out/stl/exact/shaft.stl" "$out/stl/exact/front_coupler.stl" --out engineering/assembly-clearance.json > "$out/reports/assembly-clearance.txt" 2>&1 || failed=1
if [ "${SKIP_ROLLING:-0}" != 1 ]; then
 run mesh-release mesh.sv
 run bevel_mesh-final bevel_mesh.sv
else
 echo 'Rolling checks skipped by caller; this is not a mesh verification run.'
fi
MPLCONFIGDIR=/tmp/shaftdrive-mpl python engineering/drawings.py || failed=1
MPLCONFIGDIR=/tmp/shaftdrive-mpl python engineering/draw_assembly.py "$out/stl/exact" engineering/assembly-clearance.json || failed=1
python engineering/make_report.py || failed=1
if grep -nE '— refuted|error\[E' "$out"/reports/*.txt; then failed=1; fi
if grep -nE '— undecided|continuous interval unproven' "$out"/reports/*.txt; then
 echo 'REVIEW REQUIRED: inconclusive / sampled-only checks remain. Read the engineering report.'
fi
exit "$failed"
