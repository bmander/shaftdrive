# Bottom-bracket shell correction

The original round drive-side cap was united with the frame **after** the pinion bore was cut. Its plate consequently closed part of that bore. The non-drive chainstay also extended through the cap into the spindle envelope, outside the main-case bore's axial extent.

The correction is in `drive.sv`. The coped cap and its final union with the housing lobe are separate solid stages, so the coping cut cannot remove the lobe again:

- The drive cap incorporates the outboard pinion-housing lobe, split at the main-case face (y = −36.5 mm). Its plate and pilot are coped to the bore and fixed housing. The bearing seats retain their original diameters and stations.
- A local flange and two M5 positions support the lobe. The remaining circular pilot and a Ø4 clocking-dowel hole locate the matched cover. Finish the split bearing bores and retainer threads with that cover dowelled and clamped.
- A Ø36 mm front socket bridges the Ø28 mm shaft tube to the housing behind the seal bore. The cover lobe ends on a constant-x plane parallel to its withdrawal direction, avoiding an undercut against the socket caused by the shaft angle.
- The non-drive stay root clears the Ø129 mm cap-withdrawal envelope outside y = +36.5 mm. A short collar connects the stay to the fixed shell outside the cap rim.
- The drive-side circular O-ring is no longer fitted: its path is interrupted by the pinion opening. The joint uses an oil-compatible anaerobic flange sealant on metal-to-metal faces. The non-drive cap retains its O-ring. The report gives the revised assembly sequence.

Gear geometry, ratio, shaft angle and wheel dimensions are unchanged.

## Clearance evidence

Solvent v0.1.19 reports signed spacing: a negative value is interference. These are nominal rigid-part results, not operating clearances after tolerances, load and thermal movement.

| Pair | Before, measured | After, measured | After, conservative interval lower end | Required |
| --- | ---: | ---: | ---: | ---: |
| Front pinion teeth / assembled frame | −4.369 mm | 6.656 mm | 6.650 mm | 0.5 mm |
| Spindle / assembled frame | −1.779 mm | 4.999 mm | 4.998 mm | 0.2 mm |

Both checks are now permanent claims in `drive.sv`. The assembled `frame` target includes the fixed housing, both main-case caps and the rear housings/covers. The checks use the production solids, with no display crops or hidden housing geometry.

The [before log](validation/bb-shell-before.txt) was made from main commit `a043d06` with the original clearance claims replaced temporarily by four focused checks: front pinion/frame, sun/frame, planet 0/frame and spindle/frame. It identifies the intersecting cap plate and chainstay directly. The sun's nominal 0.5 mm spacing was within the evaluator's uncertainty at a 0.5 mm threshold; this was not a proven collision. The planet had 8 mm spacing.

All 20 selected assembly clearance claims hold. The [current assembly log](validation/drive-release.txt) records those checks and successful kernel exports of the assembled frame, fixed housing and separate drive cap. The exported cap is one connected shell. Reproduce it with:

```sh
solventc drive.sv --no-progress --timings
```

The refreshed wheel-envelope bounds are in [clearance-final.json](clearance-final.json). The README's assembly and bottom-bracket images are regenerated from this model; the close-up cuts through z = 0 solely for presentation.

These selected checks are not an exhaustive assembly interference search. No general collision engine was added. The cover's clamp load, dowel fits, sealant process, stay-root strength and final tool/extraction access still require manufacturing and structural validation; the existing gear/bearing release gates remain open.
