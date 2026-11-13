# Bottom-bracket shell correction

The original round drive-side cap was united with the frame **after** the pinion bore was cut. Its plate consequently closed part of that bore. The non-drive chainstay also extended through the cap into the spindle envelope, outside the main-case bore's axial extent.

The correction is in `drive.sv`. The coped cap and its final union with the housing lobe are separate solid stages, so the coping cut cannot remove the lobe again:

- The drive cap incorporates the outboard pinion-housing lobe, split at the main-case face (y = −36.5 mm). Its plate and pilot are coped to the bore and fixed housing. The bearing-seat diameters are retained; the first bearing moves to stations 9–23 mm to clear the pinion teeth, with 6 mm spacers to the second bearing at 29–43 mm. Bores and added support features use separate solid stages so the bores cannot erase the seats.
- A local flange and two M5 positions support the lobe. The remaining circular pilot and a Ø4 clocking-dowel hole locate the matched cover. Finish the split bearing bores and retainer threads with that cover dowelled and clamped.
- The pinion housing has a solid forward end wall. Its removable rear seal carrier and shaft-case tube provide the assembly access described in [the shaft assembly audit](shaft-assembly.md). The cap travels with its pinion stack; it is not independently withdrawn across the bearing seats.
- The non-drive stay root clears the Ø129 mm cap-withdrawal envelope outside y = +36.5 mm. A short collar connects the stay to the fixed shell outside the cap rim.
- The drive-side circular O-ring is no longer fitted: its path is interrupted by the pinion opening. The joint uses an oil-compatible anaerobic flange sealant on metal-to-metal faces. The non-drive cap retains its O-ring. The report gives the revised assembly sequence.

Gear tooth geometry, ratio, shaft angle and wheel dimensions are unchanged. The changed bearing span is included in the revised load screen.

## Clearance evidence

Solvent reports signed spacing: a negative value is interference. These are nominal rigid-part results, not operating clearances after tolerances, load and thermal movement.

| Pair | Before, measured | After, measured | After, conservative interval lower end | Required |
| --- | ---: | ---: | ---: | ---: |
| Front pinion teeth / assembled frame | −4.369 mm | 4.096 mm | 4.091 mm | 0.5 mm |
| Spindle / assembled frame | −1.779 mm | 4.999 mm | 4.998 mm | 0.2 mm |

The current checks use solventc v0.1.21 after rebasing onto the standard bearing-port implementation. Front bearing ports cut `unsplit_frame` before the drive cap is separated, so both halves receive the bores. The original before logs use v0.1.19.

Both checks are now permanent claims in `drive.sv`. The assembled `frame` target includes the fixed housing, both main-case caps and the rear housings/covers. The checks use the production solids, with no display crops or hidden housing geometry.

The [before log](validation/bb-shell-before.txt) was made from main commit `a043d06` with the original clearance claims replaced temporarily by four focused checks: front pinion/frame, sun/frame, planet 0/frame and spindle/frame. It identifies the intersecting cap plate and chainstay directly. The sun's nominal 0.5 mm spacing was within the evaluator's uncertainty at a 0.5 mm threshold; this was not a proven collision. The planet had 8 mm spacing.

All 22 selected solid claims hold (21 clearance checks and one pinion-head containment check). The [current assembly log](validation/drive-release.txt) records those checks; the [export log](validation/drive-exports.txt) records successful kernel exports of the assembled frame, fixed housing and separate drive cap. The exported cap is one connected shell. Reproduce it with:

```sh
solventc drive.sv --no-progress --timings
```

The refreshed wheel-envelope bounds are in [clearance-final.json](clearance-final.json). The README's assembly and bottom-bracket images are regenerated from this model; the close-up cuts through z = 0 solely for presentation.

These selected checks are not an exhaustive assembly interference search. No general collision engine was added. The cover's clamp load, dowel fits, sealant process, stay-root strength and final tool/extraction access still require manufacturing and structural validation; the existing gear/bearing release gates remain open.
