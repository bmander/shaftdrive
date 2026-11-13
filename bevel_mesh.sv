// Independent rolling check of the corrected 94.5 degree, 18/54 bevel pair.
// Tooth solids only; the proof is sampled by solventc, not continuous certification.
unit mm
use std
use std.motion (turns)
use spiral_bevel.angled_bevel (BevelPair)
use dims (pinion_teeth, gear_teeth, bevel_module, bevel_angle, bevel_backlash,
          bevel_tip_relief, bevel_end_relief, bevel_cutter_radius)
pair := BevelPair(pinion_teeth: pinion_teeth, gear_teeth: gear_teeth,
  mean_module: bevel_module, shaft_angle: bevel_angle, offset: 0mm, spiral_angle: 25deg,
  backlash: bevel_backlash, tip_relief: bevel_tip_relief, end_relief: bevel_end_relief,
  pressure_shift: hint(-1deg), cutter_radius: bevel_cutter_radius, least: hint(0.5))
pair.margins.pinion_inner regular(pair.least, by: pair.margins.pinion_cut) within pair.margins.pinion
pair.margins.pinion_outer regular(pair.least, by: pair.margins.pinion_cut) within pair.margins.pinion
param t: Angle over (0deg, 360deg / gear_teeth)
gear_turn := frame
gear_turn turns(1) pair.gear_member.ax
fix(value == t) gear_turn
pinion_turn := frame
pinion_turn turns(-gear_teeth / pinion_teeth) pair.pinion_member.ax
fix(value == t) pinion_turn
gear_at := pair.gear_member.body at gear_turn
pinion_at := pair.pinion_member.body at pinion_turn
claim over t {
  gear_at clear(0.001mm) pinion_at
}
