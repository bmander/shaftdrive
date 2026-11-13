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
mkdir -p "$out/png" "$out/stl/exact" "$out/stl/faceted" "$out/reports"
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

# The drive: solved, its clearance claims judged, every exactly built part written as an STL and
# five pictures drawn, each solid built once.
run drive drive.sv \
  --png "$out/png/drive_iso.png" --view 300,25 --size 1600 \
  --png "$out/png/drive_cutaway.png" --view 300,25 --size 1600 --hide frame \
  --png "$out/png/drive_section.png" --view 290,30 --size 1600 --section 'y=-40mm' \
  --png "$out/png/drive_top.png" --view top --size 1600 --hide frame \
  --png "$out/png/drive_right.png" --view right --size 1600 \
  --stl "$out/stl/exact/frame.stl" --solid frame \
  --stl "$out/stl/exact/sun.stl" --solid box.sun.body \
  --stl "$out/stl/exact/ring.stl" --solid box.ring.body \
  --stl "$out/stl/exact/carrier.stl" --solid box.carrier \
  --stl "$out/stl/exact/shaft.stl" --solid shaft \
  --stl "$out/stl/exact/spindle.stl" --solid spindle \
  --stl "$out/stl/exact/hub.stl" --solid hub \
  --stl "$out/stl/exact/crank.stl" --solid right_crank.body \
  --stl "$out/stl/exact/bb_pinion.stl" --solid bb_pinion \
  --stl "$out/stl/exact/hub_pinion.stl" --solid hub_pinion

# The hypoid gears are read from their material fields where they stand in the bicycle, not built
# (README), so they are written by the faceted kernel: meshes to look at, not to make parts from.
run hypoid drive.sv --no-check --stl-backend mesh \
  --stl "$out/stl/faceted/bb_gear.stl" --solid bb_gear \
  --stl "$out/stl/faceted/hub_gear.stl" --solid hub_gear

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
  echo
  echo "STL, faceted from the field: $(cd "$out/stl/faceted" && ls | tr '\n' ' ')"
  if [ ${#failed[@]} -gt 0 ]; then echo; echo "**Failed runs:** ${failed[*]}"; fi
  if [ -n "$refuted" ]; then echo; echo '**Refuted claims:**'; echo '```'; echo "$refuted"; echo '```'; fi
} >> "$summary"

if [ ${#failed[@]} -gt 0 ] || [ -n "$refuted" ]; then
  echo "failed: ${failed[*]:-}" >&2
  [ -z "$refuted" ] || echo "refuted: $refuted" >&2
  exit 1
fi
