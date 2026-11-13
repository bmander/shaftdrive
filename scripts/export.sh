#!/usr/bin/env bash
# Check the drive and export its pictures and meshes: `scripts/export.sh [OUT]` (default `out`).
#
# Each run's report is kept under OUT/reports.  The script carries on past a refused output, so
# every picture and mesh that can be made is made, and exits non-zero at the end if any run
# failed or any claim was refuted.  SOLVENTC names the binary (default: `solventc` on the PATH).
set -uo pipefail

cd "$(dirname "$0")/.."
out=${1:-out}
solventc=${SOLVENTC:-solventc}
mkdir -p "$out/png" "$out/stl/exact" "$out/reports"
failed=()

run() {   # run NAME ARGS…: one solventc run, its report in reports/NAME.txt
  local name=$1; shift
  echo "::group::$name"
  local start=$SECONDS
  "$solventc" --no-progress --timings "$@" > "$out/reports/$name.txt" 2>&1
  local status=$?
  cat "$out/reports/$name.txt"
  echo "$name: exit $status in $((SECONDS - start)) s"
  echo "::endgroup::"
  [ "$status" -eq 0 ] || failed+=("$name (exit $status)")
}

soft=()
soft_run() {   # soft_run NAME ARGS…: a run expected to fail on a known finding; noted, not fatal
  local before=${#failed[@]}
  run "$@"
  if [ ${#failed[@]} -gt "$before" ]; then
    soft+=("${failed[-1]}")
    unset 'failed[-1]'
  fi
}

"$solventc" --version

# The design table: every claim over its numbers.
run dims dims.sv

# One planet on its own, from gears.sv's preview: the planets in the drive are this binding.
run planet gears.sv \
  --stl "$out/stl/exact/planet.stl" --solid planet.body \
  --png "$out/png/planet.png" --view 20,25 --size 900

# The planetary from above, its carrier hidden.
run planetary planetary.sv \
  --png "$out/png/planetary_top.png" --view top --size 1200 --hide box.carrier \
  --png "$out/png/planetary_iso.png" --view 30,35 --size 1200

# The drive in its frame: solved, its clearance claims judged, every exactly built part written as
# an STL and five pictures drawn, each solid built once.
run drive drive.sv \
  --png "$out/png/drive_iso.png" --view 300,20 --size 1600 \
  --png "$out/png/drive_cutaway.png" --view 300,20 --size 1600 --hide frame,bearing_cup \
  --png "$out/png/drive_section.png" --view 290,25 --size 1600 --section 'y=-30mm' \
  --png "$out/png/drive_top.png" --view top --size 1600 --hide frame,bearing_cup \
  --png "$out/png/drive_right.png" --view right --size 1600 \
  --stl "$out/stl/exact/frame.stl" --solid frame \
  --stl "$out/stl/exact/bearing_cup.stl" --solid bearing_cup \
  --stl "$out/stl/exact/sun.stl" --solid box.sun.body \
  --stl "$out/stl/exact/ring.stl" --solid box.ring.body \
  --stl "$out/stl/exact/carrier.stl" --solid box.carrier \
  --stl "$out/stl/exact/shaft.stl" --solid shaft \
  --stl "$out/stl/exact/spindle.stl" --solid spindle \
  --stl "$out/stl/exact/hub.stl" --solid hub \
  --stl "$out/stl/exact/thru_axle.stl" --solid thru_axle \
  --stl "$out/stl/exact/crank.stl" --solid right_crank.body \
  --stl "$out/stl/exact/bb_gear.stl" --solid bb_gear \
  --stl "$out/stl/exact/hub_gear.stl" --solid hub_gear \
  --stl "$out/stl/exact/bb_pinion.stl" --solid bb_pinion \
  --stl "$out/stl/exact/hub_pinion.stl" --solid hub_pinion \
  --stl "$out/stl/exact/bearing_6804_outer.stl" --solid right_6804.outer_ring \
  --stl "$out/stl/exact/bearing_6804_inner.stl" --solid right_6804.inner_ring \
  --stl "$out/stl/exact/bearing_6804_balls.stl" --solid right_6804.ball_set \
  --stl "$out/stl/exact/ring_471_20.stl" --solid right_ring.ring.body \
  --stl "$out/stl/exact/ring_472_24.stl" --solid right_hub_ring.ring.body

# The bearings near the hub: their rings build, but their balls mesh to nothing so far from the
# origin (README, finding 19), so the balls are written in a run of their own, which is expected to
# fail and does not fail the job.
run hub_bearings drive.sv --no-check \
  --stl "$out/stl/exact/bearing_6903_outer.stl" --solid hub_6903.outer_ring \
  --stl "$out/stl/exact/bearing_6901_outer.stl" --solid right_6901.outer_ring
soft_run hub_balls drive.sv --no-check \
  --stl "$out/stl/exact/bearing_6901_balls.stl" --solid right_6901.ball_set

# The planetary's meshes, rolled over a sun pitch with every joint at its ratio: the claims judge
# the backlash at 37 poses (README: what solventc says of them).
run mesh mesh.sv

refuted=$(grep -h -E 'refuted|claim independent' "$out"/reports/*.txt || true)

summary=${GITHUB_STEP_SUMMARY:-/dev/null}
{
  echo "## Shaft drive"
  echo
  echo '```'
  "$solventc" --version
  head -3 "$out/reports/drive.txt"
  grep -E '^  claim' "$out/reports/drive.txt"
  grep -E '^  claim' "$out/reports/mesh.txt" | cut -c1-200
  echo '```'
  echo
  echo "Pictures: $(cd "$out/png" && ls | tr '\n' ' ')"
  echo
  echo "STL, exact: $(cd "$out/stl/exact" && ls | tr '\n' ' ')"
  if [ ${#soft[@]} -gt 0 ]; then echo; echo "Known failures (README): ${soft[*]}"; fi
  if [ ${#failed[@]} -gt 0 ]; then echo; echo "**Failed runs:** ${failed[*]}"; fi
  if [ -n "$refuted" ]; then echo; echo '**Refuted claims:**'; echo '```'; echo "$refuted"; echo '```'; fi
} >> "$summary"

if [ ${#failed[@]} -gt 0 ] || [ -n "$refuted" ]; then
  echo "failed: ${failed[*]:-}" >&2
  [ -z "$refuted" ] || echo "refuted: $refuted" >&2
  exit 1
fi
