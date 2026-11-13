// A chainless bicycle drive in a road frame: a shaft sealed inside the drive-side chainstay, a
// step-up gearbox inside the bottom bracket's shell and a step-down gearbox inside the drive-side
// dropout, with prototype torque joints and bought-part envelopes. See engineering/specification.html
// for manufacturing and assembly gates, and `dims.sv` for the numbers.
//
// The world is the bicycle's: `std.x` forward, `std.y` to the rider's left, `std.z` up, the
// bottom bracket's centre at the origin, the frame's mid-plane `y = 0`.  The drive side is the
// right, toward −y.
unit mm
use std
use std.sets
use std.solids
use std.solids (cut, union, common)
use std.rounds (round)
use std.place (seats, right_of)
use spiral_bevel.angled_bevel (BevelPair)
use planetary
use frame
use hardware
use interfaces
use wheel
use dims (cs_length, bb_drop, pinion_y, ring_y, pinion_teeth, gear_teeth, bevel_module,
          bevel_angle, bevel_backlash, bevel_tip_relief, bevel_end_relief, bevel_cutter_radius,
          shell_od, shell_id, case_left, case_right, end_wall, bearing_od, sleeve_bearing_od,
          diaphragm, cup, boss_r, boss_ahead, boss_behind, wall, web, pinion_bearing, sleeve_r,
          bb_bearing, sun_bearing, pinion_ac, case_bearing_y, pinion_second, shaft_spline_start,
          shaft_spline_length, shaft_tube_start, crank_t, bevel_front_y, sun_spline_from, sun_spline_to,
          dropout_t, hub_r, hub_bore, hub_seat, hub_span, hub_bearings, flange_r, flanges, spokes,
          rear_case_r, rear_case, axle_d, old, shaft_od, shaft_id, tube_od, tube_id, spindle_d,
          spindle_bore, crank_throw, crank_face, b6804, b6805, b6903, b6901, r471_20, r471_25,
          r471_17, r472_24)

// -- the frame's datums --------------------------------------------------------------------------
// The bottom bracket's axis is the world's `std.y`.  The rear axle stands `cs_length` from it,
// `bb_drop` above it, behind; its axis runs along `std.y` through its centre.
in std.front {
  axle_c := point
  std.origin distance(bb_drop, along: v) axle_c
  std.origin distance(cs_length) axle_c
  std.origin distance(<= 0mm, along: u) axle_c
  construction centres := line(std.origin, axle_c)
  mid := point
  mid midpoint centres
}
axle := axis
axle parallel(sense: same) std.y
axle_c coincident axle
// the two axes as drawn lines, for ordinates along them and the sets about them
y_end := point
y_end coincident std.y
std.origin distance(10mm, along: std.y) y_end
construction bb_line := line(std.origin, y_end)
axle_end := point
axle_end coincident axle
axle_c distance(10mm, along: std.y) axle_end
construction axle_line := line(axle_c, axle_end)
drive_side := axis
drive_side parallel(sense: opposite) std.y
std.origin coincident drive_side

// -- the spiral bevel pairs ---------------------------------------------------------------------
// One pair, laid out and cut once, standing twice.  At the bottom bracket its gear rides the sun's
// sleeve, its axis the bracket's, and drives the pinion, whose axis is the shaft's: it runs back
// along the line of centres seen from the side, splaying `splay` outward on the drive side seen
// from above, the pair's shafts meeting at `bevel_angle`.  The pinion's mean point stands
// `pinion_y` out on the drive side.
//
// At the hub the same pair stands turned end for end: half a turn about `flip`, the line square to
// the axles and to the shaft through the shaft's point over the middle of the line of centres.
// The turn takes the bracket's axis to a line along the axle's, through the axle's centre, and the
// shaft's axis to itself, run the other way: so the hub's gear turns on the axle and the shaft's
// two pinions share one axis by construction.  The shaft's pinion drives the hub's gear.
//
// The pair is placed by what it does (#904 A5): its frame's origin on the bracket's axis, its
// gear's axis along it, its pinion's axis square to `flip` and running back, the pinion's mean
// point at `pinion_y`.  With no offset the face mill's shift is found where the pinion's two
// flanks stand equally far from undercut (`hypoid.sv`).
pair := BevelPair(pinion_teeth: pinion_teeth, gear_teeth: gear_teeth,
  mean_module: bevel_module, shaft_angle: bevel_angle, offset: 0mm, spiral_angle: 25deg,
  backlash: bevel_backlash, tip_relief: bevel_tip_relief, end_relief: bevel_end_relief,
  pressure_shift: hint(10deg), cutter_radius: bevel_cutter_radius, least: hint(0.5))
pair.margins.pinion_inner regular(pair.least, by: pair.margins.pinion_cut) within pair.margins.pinion
pair.margins.pinion_outer regular(pair.least, by: pair.margins.pinion_cut) within pair.margins.pinion
flip := axis
flip perpendicular std.y
flip perpendicular centres
pair.std.origin coincident std.y
pair.gear_member.ax parallel(sense: same) std.y
pair.pinion_member.ax perpendicular flip
pair.pinion_member.ax.p1 distance(<= 0mm, along: std.x) pair.pinion_member.ax.p2
std.origin distance(pinion_y, along: std.y) pair.pinion_member.foot
flip_c := point
flip_c coincident pair.pinion_member.ax
mid distance(0mm, along: centres) flip_c
flip_c coincident flip

// The pinion's mean point at the hub, on the shaft's axis.
hub_foot := pair.pinion_member.foot at(under: flip) 180deg
claim hub_foot coincident pair.pinion_member.ax

// Each member is made one part with a web filling its core: the points deeper inside its pitch
// cone than its blank's back, in a band along its axis about the foot of its mean point (as
// `hypoid_drive/drive.sv` hubs its members).  The bracket's gear's web is bored to sit on the sun's
// sleeve, the hub's on the hub's shell, each pinion's to take the shaft's end.  The hub's gear
// and pinion are made where the bracket's stand, and turned to the hub.
gear_web := { q | q not in pair.gear_member.back
                  q not in std.sets.Cylinder(bb_line, r: sleeve_r - 1mm)
                  pair.gear_member.foot distance(in: (web.x, web.y), along: bb_line) q }
hub_web := { q | q not in pair.gear_member.back
                 q not in std.sets.Cylinder(bb_line, r: hub_r - 1mm)
                 pair.gear_member.foot distance(in: (web.x, web.y), along: bb_line) q }
pinion_web := { q | q not in pair.pinion_member.back
                    pair.pinion_member.foot distance(in: (web.x, web.y), along: pair.pinion_member.ax) q }
construction gear_web_solid := solid(gear_web)
construction hub_web_solid := solid(hub_web)
construction pinion_web_solid := solid(pinion_web)
bb_gear := solid(pair.gear_member.body)
bb_gear_core := solid(gear_web_solid)
construction hub_gear_here := solid(pair.gear_member.body)
construction hub_core_here := solid(hub_web_solid)
construction pinion_part := solid(pinion_web_solid)
construction pinion_stub := solid({q | q in std.sets.Cylinder(pair.pinion_member.ax, r: 8.5mm)
  pair.pinion_member.foot distance(in: (0mm, shaft_spline_start), along: pair.pinion_member.ax) q})
pinion_stub union pinion_part
pinion_spline_station := At(pair.pinion_member.ax, pair.pinion_member.foot, d: shaft_spline_start)
construction pinion_spline := interfaces.StraightSpline(root: 14mm, major: 17mm, tooth: 3.8mm, n: 6, length: shaft_spline_length)
pinion_spline seats(turn: 0deg, up: pair.pinion_member.ax, east: flip) pinion_spline_station.p
pinion_spline.body union pinion_part
gear_joint_station := At(bb_line, pair.gear_member.foot, d: -5mm)
construction gear_hub := interfaces.Annulus(d: 33.08mm, D: 43mm, length: 10mm)
gear_hub seats(turn: 0deg, up: std.y, east: std.x) gear_joint_station.p
gear_hub.body union bb_gear_core
construction gear_spline_cut := interfaces.StraightSpline(root: 33.08mm, major: 35.08mm, tooth: 4.06mm, n: 12, length: 10mm)
gear_spline_cut seats(turn: 0deg, up: std.y, east: std.x) gear_joint_station.p
gear_spline_cut.body cut bb_gear_core
hub_joint_here := At(bb_line, pair.gear_member.foot, d: -6mm)
construction hub_gear_collar := interfaces.Annulus(d: 28.08mm, D: 40mm, length: 12mm)
hub_gear_collar seats(turn: 0deg, up: std.y, east: std.x) hub_joint_here.p
hub_gear_collar.body union hub_core_here
construction hub_gear_spline := interfaces.StraightSpline(root: 28.08mm, major: 30.08mm, tooth: 3.56mm, n: 12, length: 12mm)
hub_gear_spline seats(turn: 0deg, up: std.y, east: std.x) hub_joint_here.p
hub_gear_spline.body cut hub_core_here
construction pinion_shoulder := solid({q | q in std.sets.Cylinder(pair.pinion_member.ax, r: 12mm)
  pair.pinion_member.foot distance(in: (3mm, 5mm), along: pair.pinion_member.ax) q})
pinion_shoulder union pinion_part
construction clip_groove := solid({q | q in std.sets.Cylinder(pair.pinion_member.ax, r: 9mm)
  q not in std.sets.Cylinder(pair.pinion_member.ax, r: 8.1mm)
  pair.pinion_member.foot distance(in: (43.5mm, 44.5mm), along: pair.pinion_member.ax) q})
clip_groove cut pinion_part
bb_pinion := solid(pair.pinion_member.body)
bb_pinion_core := solid(pinion_part)
hub_gear := hub_gear_here at(under: flip) 180deg
hub_gear_core := hub_core_here at(under: flip) 180deg
hub_pinion := pair.pinion_member.body at(under: flip) 180deg
hub_pinion_core := pinion_part at(under: flip) 180deg

// -- the planetary -------------------------------------------------------------------------------
// Its mid-plane `ring_y` out on the non-drive side, its axis the bracket's, toward the drive side.
bb_mid := point
bb_mid coincident std.y
std.origin distance(ring_y, along: std.y) bb_mid
box := planetary.Planetary()
box seats(turn: 0deg, up: drive_side, east: std.x) bb_mid

// -- stations, where the hardware is seated --------------------------------------------------------
// Along the bracket's axis (from its centre, +y to the left), the axle's (from its centre) and the
// shaft's (from the bracket's pinion's mean point, rearward, or from the hub's, forward).
component At(ax: line, from: point, d: Length) {
  p := point
  p coincident ax
  from distance(d, along: ax) p
}
right_bb := At(bb_line, std.origin, d: -case_bearing_y)
left_bb := At(bb_line, std.origin, d: case_bearing_y)
sleeve_bb := At(bb_line, std.origin, d: (diaphragm.x + diaphragm.y) / 2)
right_clip := At(bb_line, std.origin, d: case_right + end_wall + 0.8mm)
left_clip := At(bb_line, std.origin, d: cup.x + 0.2mm)
sleeve_clip := At(bb_line, std.origin, d: diaphragm.y + 0.8mm)
bb_pinion_bearing := At(pair.pinion_member.ax, pair.pinion_member.foot,
  d: (pinion_bearing.x + pinion_bearing.y) / 2)
hub_pinion_bearing := At(pair.pinion_member.ax, hub_foot, d: -(pinion_bearing.x + pinion_bearing.y) / 2)
bb_shaft_clip := At(pair.pinion_member.ax, pair.pinion_member.foot, d: pinion_bearing.y + 0.8mm)
hub_shaft_clip := At(pair.pinion_member.ax, hub_foot, d: -pinion_bearing.y - 0.8mm)
right_hub := At(axle_line, axle_c, d: hub_bearings.x)
left_hub := At(axle_line, axle_c, d: hub_bearings.y)
right_hub_clip := At(axle_line, axle_c, d: hub_bearings.x - 3mm - 0.8mm)
left_hub_clip := At(axle_line, axle_c, d: hub_bearings.y + 3mm + 0.8mm)

// A ring's groove: a band `t` wide about `ax` at `at`, from radius `r` out to `r_out`.
component Groove(ax: line, at: point, r: Length, r_out: Length, t: Length) {
  band := { q | q in std.sets.Cylinder(ax, r: r_out)
                q not in std.sets.Cylinder(ax, r: r)
                at distance(in: (-t / 2, t / 2), along: ax) q }
  body := solid(band)
}

// -- the shaft ---------------------------------------------------------------------------------
// A tube from pinion to pinion, its ends in the members' webs, grooved for the rings that hold its
// bearings.
shaft := solid({ q | q in std.sets.Cylinder(pair.pinion_member.ax, r: shaft_od / 2)
                     q not in std.sets.Cylinder(pair.pinion_member.ax, r: shaft_id / 2)
                     pair.pinion_member.foot distance(>= shaft_tube_start, along: pair.pinion_member.ax) q
                     hub_foot distance(<= -99.5mm, along: pair.pinion_member.ax) q })
front_coupling_station := At(pair.pinion_member.ax, pair.pinion_member.foot, d: shaft_spline_start)
front_coupler := interfaces.Annulus(d: 14.08mm, D: 22mm, length: 32mm)
front_coupler seats(turn: 0deg, up: pair.pinion_member.ax, east: flip) front_coupling_station.p
construction front_spline_cut := interfaces.StraightSpline(root: 14.08mm, major: 17.08mm, tooth: 3.86mm, n: 6, length: 22.6mm)
front_spline_cut seats(turn: 0deg, up: pair.pinion_member.ax, east: flip) front_coupling_station.p
front_spline_cut.body cut front_coupler.body
construction front_socket := solid({q | q in std.sets.Cylinder(pair.pinion_member.ax, r: 9.02mm)
  pair.pinion_member.foot distance(in: (75mm, 85.1mm), along: pair.pinion_member.ax) q})
front_socket cut front_coupler.body
rear_adapter_station := At(pair.pinion_member.ax, hub_foot, d: -97.5mm)
rear_adapter := interfaces.StraightSpline(root: 14mm, major: 17mm, tooth: 3.8mm, n: 6, length: 22mm)
rear_adapter seats(turn: 0deg, up: pair.pinion_member.ax, east: flip) rear_adapter_station.p
construction adapter_neck := solid({q | q in std.sets.Cylinder(pair.pinion_member.ax, r: shaft_od / 2)
  hub_foot distance(in: (-101mm, -97.5mm), along: pair.pinion_member.ax) q})
adapter_neck union shaft
rear_adapter.body union shaft
rear_coupler := interfaces.SplitCoupler()
rear_coupler seats(turn: 0deg, up: pair.pinion_member.ax, east: flip) rear_adapter_station.p

// -- the crank spindle and the cranks -------------------------------------------------------------
spindle := solid({ q | q in std.sets.Cylinder(bb_line, r: spindle_d / 2)
                       q not in std.sets.Cylinder(bb_line, r: spindle_bore / 2)
                       std.origin distance(in: (-crank_face - crank_t, crank_face + crank_t), along: bb_line) q })
carrier_shaft_station := At(bb_line, std.origin, d: ring_y - 11.5mm)
construction carrier_male := interfaces.StraightSpline(root: 22mm, major: 25mm, tooth: 2.2mm, n: 16, length: 25.8mm)
carrier_male seats(turn: 0deg, up: std.y, east: std.x) carrier_shaft_station.p
construction carrier_mask := interfaces.Annulus(d: 21.9mm, D: 25.2mm, length: 25.8mm)
carrier_mask seats(turn: 0deg, up: std.y, east: std.x) carrier_shaft_station.p
carrier_male.body cut carrier_mask.body
carrier_mask.body cut spindle
// One crank, placed twice on the spindle's ends: the right one forward, the left turned half a turn
// about the spindle, behind.  Each stands on the spindle's axis at its outer face.
right_end := At(bb_line, std.origin, d: -crank_face - crank_t)
left_end := At(bb_line, std.origin, d: crank_face + crank_t)
down := axis
down parallel(sense: opposite) std.z
std.origin coincident down
right_crank := Crank(throw: crank_throw, boss: 20mm, eye: 12mm, bore: 22.08mm)
right_crank seats(turn: 0deg, up: std.z, east: std.x) right_end.p
left_crank := Crank(throw: crank_throw, boss: 20mm, eye: 12mm, bore: 22.08mm)
left_crank seats(turn: 180deg, up: down, east: std.x) left_end.p

repeat 2 as side {
  joint_y := if(side == 0, -crank_face - crank_t, crank_face)
  joint_station := At(bb_line, std.origin, d: joint_y)
  construction crank_spline := interfaces.StraightSpline(root: 22mm, major: 25mm, tooth: 2.2mm, n: 16, length: crank_t)
  crank_spline seats(turn: 0deg, up: std.y, east: std.x) joint_station.p
  construction crank_mask := interfaces.Annulus(d: 21.9mm, D: 25.2mm, length: crank_t)
  crank_mask seats(turn: 0deg, up: std.y, east: std.x) joint_station.p
  crank_spline.body cut crank_mask.body
  crank_mask.body cut spindle
  construction crank_female := interfaces.StraightSpline(root: 22.08mm, major: 25.08mm, tooth: 2.26mm, n: 16, length: crank_t)
  crank_female seats(turn: 0deg, up: std.y, east: std.x) joint_station.p
}
crank_female[0].body cut right_crank.body
crank_female[1].body cut left_crank.body

// -- the frame -------------------------------------------------------------------------------------
// The tubes, stays and the non-drive dropout (`frame.sv`), and about the drive: the bracket's shell,
// the pinion's housing where it leaves the shell, the chainstay round the shaft, the drive-side
// dropout's gear case round the hub's gear and its pinion's housing, the hub's turned end for end.
// Each is a cylinder about the axis it houses, a revolution built exactly; the frame is their union
// less their bores, then the webs that seat the bearings.
tubes := frame.Frame(std.origin, axle_c)
case_outer_set := { q | q in std.sets.Cylinder(bb_line, r: shell_od / 2)
    std.origin distance(in: (case_right, case_left), along: bb_line) q }
construction case_outer := solid(case_outer_set)
case_bore_set := { q | q in std.sets.Cylinder(bb_line, r: shell_id / 2)
    std.origin distance(in: (case_right - 1mm, case_left + 1mm), along: bb_line) q }
construction case_bore := solid(case_bore_set)
right_seat_set := { q | q in std.sets.Cylinder(bb_line, r: bearing_od / 2)
    std.origin distance(in: (case_right - 1mm, case_right + end_wall + 1mm), along: bb_line) q }
construction right_seat := solid(right_seat_set)
boss_set := { q | q in std.sets.Cylinder(pair.pinion_member.ax, r: boss_r)
    pair.pinion_member.foot distance(in: (-boss_ahead, boss_behind), along: pair.pinion_member.ax) q }
construction boss := solid(boss_set)
boss_bore_set := { q | q in std.sets.Cylinder(pair.pinion_member.ax, r: boss_r - wall)
    pair.pinion_member.foot distance(in: (-boss_ahead - 1mm, boss_behind - wall), along: pair.pinion_member.ax) q }
construction boss_bore := solid(boss_bore_set)
stay_set := { q | q in std.sets.Cylinder(pair.pinion_member.ax, r: tube_od / 2)
    pair.pinion_member.foot distance(>= boss_behind - 1mm, along: pair.pinion_member.ax) q
    hub_foot distance(<= 1mm - boss_behind, along: pair.pinion_member.ax) q }
construction stay := solid(stay_set)
stay_bore_set := { q | q in std.sets.Cylinder(pair.pinion_member.ax, r: tube_id / 2)
    pair.pinion_member.foot distance(>= 0mm, along: pair.pinion_member.ax) q
    hub_foot distance(<= 0mm, along: pair.pinion_member.ax) q }
construction stay_bore := solid(stay_bore_set)
dropout_set := { q | q in std.sets.Cylinder(axle_line, r: rear_case_r)
    axle_c distance(in: (rear_case.x, rear_case.y), along: axle_line) q }
construction dropout := solid(dropout_set)
dropout_bore_set := { q | q in std.sets.Cylinder(axle_line, r: rear_case_r - wall)
    axle_c distance(in: (rear_case.x - 1mm, rear_case.y - wall), along: axle_line) q }
construction dropout_bore := solid(dropout_bore_set)
// the hub's shell runs out through the case's inner wall; the axle through its outer wall
hub_way_set := { q | q in std.sets.Cylinder(axle_line, r: hub_r + 1mm)
    axle_c distance(in: (rear_case.x + wall - 1mm, rear_case.y + 1mm), along: axle_line) q }
construction hub_way := solid(hub_way_set)
axle_way_set := { q | q in std.sets.Cylinder(axle_line, r: axle_d / 2)
    axle_c distance(in: (rear_case.x - 1mm, rear_case.x + wall + 1mm), along: axle_line) q }
construction axle_way := solid(axle_way_set)
construction hub_boss := boss at(under: flip) 180deg
construction hub_boss_bore := boss_bore at(under: flip) 180deg

construction coupling_chamber := solid({q | q in std.sets.Cylinder(pair.pinion_member.ax, r: 23mm)
  hub_foot distance(in: (-110mm, -52mm), along: pair.pinion_member.ax) q})
construction coupling_bore := solid({q | q in std.sets.Cylinder(pair.pinion_member.ax, r: 21mm)
  hub_foot distance(in: (-111mm, -51.5mm), along: pair.pinion_member.ax) q})
// Frame carrier is outside the nominal 142mm wheel interface. Rear pod unbolts from this register.
construction pod_carrier := solid({q | q in std.sets.Cylinder(axle_line, r: 72mm)
  q not in std.sets.Cylinder(axle_line, r: 60.1mm)
  axle_c distance(in: (-78mm, -71mm), along: axle_line) q})
construction pod_flange := solid({q | q in std.sets.Cylinder(axle_line, r: 72mm)
  q not in std.sets.Cylinder(axle_line, r: rear_case_r - wall)
  axle_c distance(in: (-82mm, -78mm), along: axle_line) q})
frame_main := solid(case_outer)
tubes.body union frame_main
boss union frame_main
stay union frame_main
coupling_chamber union frame_main
pod_carrier union frame_main
case_bore cut frame_main
right_seat cut frame_main
boss_bore cut frame_main
stay_bore cut frame_main
coupling_bore cut frame_main
rear_pod := solid(dropout)
hub_boss union rear_pod
pod_flange union rear_pod
dropout_bore cut rear_pod
hub_way cut rear_pod
axle_way cut rear_pod
hub_boss_bore cut rear_pod
stay_bore cut rear_pod
// Bearing seats: matched 7303BW DB pairs, 24mm center spacing.
diaphragm_set := { q | q in std.sets.Cylinder(bb_line, r: shell_id / 2)
    q not in std.sets.Cylinder(bb_line, r: sleeve_bearing_od / 2)
    std.origin distance(in: (diaphragm.x, diaphragm.y), along: bb_line) q }
construction diaphragm_ring := solid(diaphragm_set)
diaphragm_ring union frame_main
pinion_seat_set := { q | q in std.sets.Cylinder(pair.pinion_member.ax, r: boss_r - wall + 0.5mm)
    q not in std.sets.Cylinder(pair.pinion_member.ax, r: pinion_ac.D / 2)
    pair.pinion_member.foot distance(in: (pinion_bearing.x, pinion_bearing.y), along: pair.pinion_member.ax) q }
construction pinion_seat := solid(pinion_seat_set)
construction second_seat := solid({q | q in std.sets.Cylinder(pair.pinion_member.ax, r: boss_r - wall + 0.5mm)
    q not in std.sets.Cylinder(pair.pinion_member.ax, r: pinion_ac.D / 2)
    pair.pinion_member.foot distance(in: (29mm, 43mm), along: pair.pinion_member.ax) q})
construction hub_pinion_seat := pinion_seat at(under: flip) 180deg
construction hub_second_seat := second_seat at(under: flip) 180deg
pinion_seat union frame_main
second_seat union frame_main
hub_pinion_seat union rear_pod
hub_second_seat union rear_pod
construction shaft_gland := solid({q | q in std.sets.Cylinder(pair.pinion_member.ax, r: boss_r - wall + 0.5mm)
  q not in std.sets.Cylinder(pair.pinion_member.ax, r: 14mm)
  pair.pinion_member.foot distance(in: (45mm, 52mm), along: pair.pinion_member.ax) q})
construction shaft_seal_drill := solid({q | q in std.sets.Cylinder(pair.pinion_member.ax, r: 14mm)
  pair.pinion_member.foot distance(in: (44.9mm, 53mm), along: pair.pinion_member.ax) q})
construction rear_gland := shaft_gland at(under: flip) 180deg
construction rear_seal_drill := shaft_seal_drill at(under: flip) 180deg
shaft_gland union frame_main
shaft_seal_drill cut frame_main
rear_gland union rear_pod
rear_seal_drill cut rear_pod
construction hub_seal_drill := solid({q | q in std.sets.Cylinder(axle_line, r: 21mm)
  axle_c distance(in: (-48mm, -40.9mm), along: axle_line) q})
hub_seal_drill cut rear_pod
construction ring_support := solid({q | q in std.sets.Cylinder(bb_line, r: shell_id / 2)
  q not in std.sets.Cylinder(bb_line, r: 47mm)
  std.origin distance(in: (-4mm, 3mm), along: bb_line) q})
ring_support union frame_main
// Four M6 mounting holes and two 6mm locating dowels on a 132mm circle.
repeat 4 as i {
  c := point
  angle := 45deg + i * 90deg
  axle_c distance(66mm * cos(angle), along: std.x) c
  axle_c distance(66mm * sin(angle), along: std.z) c
  axle_c distance(-82mm, along: std.y) c
  e := frame.Beside(c, dy: 10mm)
  construction ax := line(c, e.p)
  construction mount_drill := solid({q | q in std.sets.Cylinder(ax, r: 3.3mm)
    c distance(in: (-1mm, 12mm), along: ax) q})
  mount_drill cut rear_pod
  mount_drill cut frame_main
}
repeat 2 as i {
  c := point
  axle_c distance(0mm, along: std.x) c
  axle_c distance(if(i == 0, 66mm, -66mm), along: std.z) c
  axle_c distance(-82mm, along: std.y) c
  e := frame.Beside(c, dy: 12mm)
  construction ax := line(c, e.p)
  construction drill := solid({q | q in std.sets.Cylinder(ax, r: 3mm)
    c distance(in: (0mm, 11mm), along: ax) q})
  drill cut rear_pod
  drill cut frame_main
}
repeat 6 as i {
  c := point
  fix((59.5mm * cos(i * 60deg), 0mm, 59.5mm * sin(i * 60deg))) c
  e := frame.Beside(c, dy: 10mm)
  construction ax := line(c, e.p)
  repeat 2 as side {
    construction tapped_pilot := solid({q | q in std.sets.Cylinder(ax, r: 2.1mm)
      c distance(in: (if(side == 0, -36.6mm, 26.5mm), if(side == 0, -26.5mm, 36.6mm)), along: ax) q})
    tapped_pilot cut frame_main
  }
}
// Separate outboard service cover, with an annular bolt land and static face seal.
construction cover_land := solid({q | q in std.sets.Cylinder(axle_line, r: 63mm)
  q not in std.sets.Cylinder(axle_line, r: 51mm)
  axle_c distance(in: (-99mm, -91mm), along: axle_line) q})
cover_land union rear_pod
rear_cover_station := At(axle_line, axle_c, d: -105mm)
rear_cover := interfaces.Annulus(d: 12.2mm, D: 126mm, length: 6mm)
rear_cover seats(turn: 0deg, up: std.y, east: std.x) rear_cover_station.p
construction cover_groove := solid({q | q in std.sets.Cylinder(axle_line, r: 55.9mm)
  q not in std.sets.Cylinder(axle_line, r: 52.5mm)
  axle_c distance(in: (-99mm, -97.1mm), along: axle_line) q})
cover_groove cut rear_pod
rear_oring_station := At(axle_line, axle_c, d: -98.35mm)
rear_oring := interfaces.Oring(major: 54.2mm, section: 2.5mm)
rear_oring seats(turn: 0deg, up: std.y, east: std.x) rear_oring_station.p
repeat 6 as i {
  c := point
  axle_c distance(57.5mm * cos(i * 60deg), along: std.x) c
  axle_c distance(57.5mm * sin(i * 60deg), along: std.z) c
  axle_c distance(-105mm, along: std.y) c
  e := frame.Beside(c, dy: 14mm)
  construction ax := line(c, e.p)
  construction clearance_drill := solid({q | q in std.sets.Cylinder(ax, r: 2.75mm)
    c distance(in: (-1mm, 6.1mm), along: ax) q})
  construction tap_drill := solid({q | q in std.sets.Cylinder(ax, r: 2.1mm)
    c distance(in: (5.9mm, 14mm), along: ax) q})
  clearance_drill cut rear_cover.body
  tap_drill cut rear_pod
}
// Dry service chamber has a removable half-shell; split coupling lifts out radially.
construction chamber_half := solid({q | q in std.sets.Cylinder(pair.pinion_member.ax, r: 24mm)
  hub_foot distance(in: (-110mm, -52mm), along: pair.pinion_member.ax) q
  hub_foot distance(>= 0mm, along: flip) q})
service_cover := solid(coupling_chamber)
chamber_half common service_cover
coupling_bore cut service_cover
service_cover cut frame_main
// This union is a clearance target; frame_main and rear_pod remain separate service parts.
left_cap_station := At(bb_line, std.origin, d: case_left)
right_cap_station := At(bb_line, std.origin, d: case_right)
left_cap := interfaces.EndCap()
left_cap seats(turn: 0deg, up: std.y, east: std.x) left_cap_station.p
right_cap := interfaces.EndCap()
right_cap seats(turn: 0deg, up: drive_side, east: std.x) right_cap_station.p
construction bearing_cup := solid(left_cap.body)
// Ring gear is located by a replaceable keyed adapter, not by unquantified press-fit friction.
ring_adapter := solid({q | q in std.sets.Cylinder(bb_line, r: shell_id / 2)
  q not in std.sets.Cylinder(bb_line, r: 47mm)
  std.origin distance(in: (ring_y - 11.5mm, ring_y + 11.5mm), along: bb_line) q})

adapter_station := At(bb_line, std.origin, d: 3mm)
construction dog_pockets := interfaces.StraightSpline(root: 94.08mm, major: 97.08mm, tooth: 6.06mm, n: 6, length: 23mm)
dog_pockets seats(turn: 0deg, up: std.y, east: std.x) adapter_station.p
dog_pockets.body cut ring_adapter
adapter_spacer_station := At(bb_line, std.origin, d: 26mm)
adapter_spacer := interfaces.Annulus(d: 94mm, D: 110mm, length: 4mm)
adapter_spacer seats(turn: 0deg, up: std.y, east: std.x) adapter_spacer_station.p
repeat 6 as i {
  angle := 30deg + i * 60deg
  p0 := point
  p1 := point
  fix((50mm * cos(angle), ring_y, 50mm * sin(angle))) p0
  fix((64mm * cos(angle), ring_y, 64mm * sin(angle))) p1
  construction pin_ax := line(p0, p1)
  construction pin_hole := solid({q | q in std.sets.Cylinder(pin_ax, r: 3mm)
    p0 distance(in: (0mm, 14.1mm), along: pin_ax) q})
  pin_hole cut ring_adapter
  pin_hole cut frame_main
  ring_dowel := solid({q | q in std.sets.Cylinder(pin_ax, r: 3mm)
    p0 distance(in: (0mm, 14mm), along: pin_ax) q})
}

// -- the hub and the thru-axle ---------------------------------------------------------------------
// A shell on the axle, its drive-side end carrying the hub's gear in the dropout's case, two spoke
// flanges drilled for `spokes` spokes each, a 6901 seated in each end and held by a ring.
hub := solid({ q | q in std.sets.Cylinder(axle_line, r: hub_r)
                   q not in std.sets.Cylinder(axle_line, r: hub_bore)
                   axle_c distance(in: (hub_span.x, hub_span.y), along: axle_line) q })
flange_right_set := { q | q in std.sets.Cylinder(axle_line, r: flange_r)
    q not in std.sets.Cylinder(axle_line, r: hub_bore)
    axle_c distance(in: (flanges.x, flanges.x + 3mm), along: axle_line) q }
construction flange_right := solid(flange_right_set)
flange_left_set := { q | q in std.sets.Cylinder(axle_line, r: flange_r)
    q not in std.sets.Cylinder(axle_line, r: hub_bore)
    axle_c distance(in: (flanges.y, flanges.y + 3mm), along: axle_line) q }
construction flange_left := solid(flange_left_set)
flange_right union hub
flange_left union hub
right_hub_seat_set := { q | q in std.sets.Cylinder(axle_line, r: hub_seat)
    axle_c distance(in: (hub_span.x - 1mm, hub_bearings.x + 3mm), along: axle_line) q }
construction right_hub_seat := solid(right_hub_seat_set)
left_hub_seat_set := { q | q in std.sets.Cylinder(axle_line, r: hub_seat)
    axle_c distance(in: (hub_bearings.y - 3mm, hub_span.y + 1mm), along: axle_line) q }
construction left_hub_seat := solid(left_hub_seat_set)
right_hub_seat cut hub
left_hub_seat cut hub
right_hub_groove := Groove(axle_line, right_hub_clip.p, r: hub_seat - 0.5mm, r_out: r472_24.groove / 2,
  t: r472_24.t)
left_hub_groove := Groove(axle_line, left_hub_clip.p, r: hub_seat - 0.5mm, r_out: r472_24.groove / 2,
  t: r472_24.t)
right_hub_groove.body cut hub
left_hub_groove.body cut hub
repeat 2 as side {
  fy := if(side == 0, flanges.x, flanges.y)
  repeat spokes as i {
    angle := (i + side / 2) * 360deg / spokes
    hole_point := point
    axle_c distance((flange_r - 4mm) * cos(angle), along: std.x) hole_point
    axle_c distance((flange_r - 4mm) * sin(angle), along: std.z) hole_point
    axle_c distance(fy, along: std.y) hole_point
    end_point := frame.Beside(hole_point, dy: 10mm)
    construction drill_ax := line(hole_point, end_point.p)
    construction flange_drill := solid({q | q in std.sets.Cylinder(drill_ax, r: 1.3mm)
      hole_point distance(in: (-0.1mm, 3.1mm), along: drill_ax) q})
    flange_drill cut hub
  }
}
thru_axle := solid({ q | q in std.sets.Cylinder(axle_line, r: axle_d / 2)
                         axle_c distance(in: (rear_case.x - 17mm, old / 2 + dropout_t + 3mm), along: axle_line) q })
axle_head_set := { q | q in std.sets.Cylinder(axle_line, r: 9mm)
    axle_c distance(in: (old / 2 + dropout_t, old / 2 + dropout_t + 3mm), along: axle_line) q }
construction axle_head := solid(axle_head_set)
axle_head union thru_axle

hub_gear_station := pair.gear_member.foot at(under: flip) 180deg
hub_spline_station := At(axle_line, hub_gear_station, d: -6mm)
construction hub_male := interfaces.StraightSpline(root: 28mm, major: 30mm, tooth: 3.5mm, n: 12, length: 12mm)
hub_male seats(turn: 0deg, up: std.y, east: std.x) hub_spline_station.p
construction hub_spline_mask := interfaces.Annulus(d: 27.9mm, D: 30.2mm, length: 12mm)
hub_spline_mask seats(turn: 0deg, up: std.y, east: std.x) hub_spline_station.p
hub_male.body cut hub_spline_mask.body
hub_spline_mask.body cut hub

// -- bearings and retaining rings ------------------------------------------------------------------
// Each seated on its station, square to the axis it turns about.
right_6804 := hardware.Bearing(bb_bearing)
right_6804 seats(turn: 0deg, up: drive_side, east: std.x) right_bb.p
left_6804 := hardware.Bearing(bb_bearing)
left_6804 seats(turn: 0deg, up: drive_side, east: std.x) left_bb.p
sleeve_6805 := hardware.Bearing(sun_bearing)
sleeve_6805 seats(turn: 0deg, up: drive_side, east: std.x) sleeve_bb.p
bb_6903 := hardware.Bearing(pinion_ac)
bb_6903 seats(turn: 0deg, up: pair.pinion_member.ax, east: flip) bb_pinion_bearing.p
hub_6903 := hardware.Bearing(pinion_ac)
hub_6903 seats(turn: 0deg, up: pair.pinion_member.ax, east: flip) hub_pinion_bearing.p
right_6901 := hardware.Bearing(b6901)
right_6901 seats(turn: 0deg, up: axle, east: std.x) right_hub.p
left_6901 := hardware.Bearing(b6901)
left_6901 seats(turn: 0deg, up: axle, east: std.x) left_hub.p

second_bb_station := At(pair.pinion_member.ax, pair.pinion_member.foot, d: pinion_second)
second_hub_station := At(pair.pinion_member.ax, hub_foot, d: -pinion_second)
bb_pinion_second := hardware.Bearing(pinion_ac)
bb_pinion_second seats(turn: 180deg, up: pair.pinion_member.ax, east: flip) second_bb_station.p
hub_pinion_second := hardware.Bearing(pinion_ac)
hub_pinion_second seats(turn: 180deg, up: pair.pinion_member.ax, east: flip) second_hub_station.p
// Lip-seal envelopes. Actual spring and lip profiles are bought-part details.
left_seal_pos := At(bb_line, std.origin, d: 34mm)
right_seal_pos := At(bb_line, std.origin, d: -39mm)
left_seal := interfaces.Annulus(d: 25mm, D: 35mm, length: 5mm)
left_seal seats(turn: 0deg, up: std.y, east: std.x) left_seal_pos.p
right_seal := interfaces.Annulus(d: 25mm, D: 35mm, length: 5mm)
right_seal seats(turn: 0deg, up: std.y, east: std.x) right_seal_pos.p
bb_seal_pos := At(pair.pinion_member.ax, pair.pinion_member.foot, d: 45mm)
hub_seal_pos := At(pair.pinion_member.ax, hub_foot, d: -52mm)
bb_pinion_seal := interfaces.Annulus(d: 17mm, D: 28mm, length: 7mm)
bb_pinion_seal seats(turn: 0deg, up: pair.pinion_member.ax, east: flip) bb_seal_pos.p
hub_pinion_seal := interfaces.Annulus(d: 17mm, D: 28mm, length: 7mm)
hub_pinion_seal seats(turn: 0deg, up: pair.pinion_member.ax, east: flip) hub_seal_pos.p
hub_seal_station := At(axle_line, axle_c, d: -48mm)
hub_seal := interfaces.Annulus(d: 30mm, D: 42mm, length: 7mm)
hub_seal seats(turn: 0deg, up: std.y, east: std.x) hub_seal_station.p
left_static_pos := At(bb_line, std.origin, d: 32.4mm)
right_static_pos := At(bb_line, std.origin, d: -32.4mm)
left_static_seal := interfaces.Oring(major: 54.15mm, section: 2.5mm)
left_static_seal seats(turn: 0deg, up: std.y, east: std.x) left_static_pos.p
right_static_seal := interfaces.Oring(major: 54.15mm, section: 2.5mm)
right_static_seal seats(turn: 0deg, up: std.y, east: std.x) right_static_pos.p
// Ground bearing spacers and retaining envelopes (threads specified in the drawing notes).
spacer_pos := At(pair.pinion_member.ax, pair.pinion_member.foot, d: 19mm)
inner_spacer := interfaces.Annulus(d: 17.05mm, D: 24mm, length: 10mm)
inner_spacer seats(turn: 0deg, up: pair.pinion_member.ax, east: flip) spacer_pos.p
outer_spacer := interfaces.Annulus(d: 41mm, D: 47mm, length: 10mm)
outer_spacer seats(turn: 0deg, up: pair.pinion_member.ax, east: flip) spacer_pos.p
rear_inner_spacer := inner_spacer.body at(under: flip) 180deg
rear_outer_spacer := outer_spacer.body at(under: flip) 180deg
retainer_pos := At(pair.pinion_member.ax, pair.pinion_member.foot, d: 43mm)
pinion_retainer := interfaces.Annulus(d: 28mm, D: 48mm, length: 2mm)
pinion_retainer seats(turn: 0deg, up: pair.pinion_member.ax, east: flip) retainer_pos.p
rear_pinion_retainer := pinion_retainer.body at(under: flip) 180deg
clip_pos := At(pair.pinion_member.ax, pair.pinion_member.foot, d: 44mm)
pinion_clip := hardware.Ring471(r471_17)
pinion_clip seats(turn: 0deg, up: pair.pinion_member.ax, east: flip) clip_pos.p
rear_pinion_clip := pinion_clip.ring.body at(under: flip) 180deg
hub_inner_spacer_pos := At(axle_line, axle_c, d: -82mm)
hub_inner_spacer := interfaces.Annulus(d: 12.1mm, D: 15.8mm, length: 141mm)
hub_inner_spacer seats(turn: 0deg, up: std.y, east: std.x) hub_inner_spacer_pos.p
sun_nut_pos := At(bb_line, pair.gear_member.foot, d: -8mm)
sun_locknut := interfaces.Annulus(d: 35mm, D: 42mm, length: 3mm)
sun_locknut seats(turn: 0deg, up: std.y, east: std.x) sun_nut_pos.p
hub_nut_pos := At(axle_line, hub_gear_station, d: -9mm)
hub_locknut := interfaces.Annulus(d: 30mm, D: 40mm, length: 3mm)
hub_locknut seats(turn: 0deg, up: std.y, east: std.x) hub_nut_pos.p
repeat 2 as side {
  pos := At(bb_line, std.origin, d: if(side == 0, -51mm, 47mm))
  spindle_adjuster := interfaces.Annulus(d: 25mm, D: 34mm, length: 4mm)
  spindle_adjuster seats(turn: 0deg, up: std.y, east: std.x) pos.p
}
axle_nut_station := At(axle_line, axle_c, d: -115mm)
axle_nut := interfaces.Annulus(d: 12mm, D: 22mm, length: 10mm)
axle_nut seats(turn: 0deg, up: std.y, east: std.x) axle_nut_station.p
right_endspacer_station := At(axle_line, axle_c, d: -99mm)
right_endspacer := interfaces.Annulus(d: 12.1mm, D: 16mm, length: 11mm)
right_endspacer seats(turn: 0deg, up: std.y, east: std.x) right_endspacer_station.p
left_endspacer_station := At(axle_line, axle_c, d: 65mm)
left_endspacer := interfaces.Annulus(d: 12.1mm, D: 16mm, length: 6mm)
left_endspacer seats(turn: 0deg, up: std.y, east: std.x) left_endspacer_station.p
rear_wheel := wheel.TouringWheel()
rear_wheel seats(turn: 0deg, up: std.z, east: std.x) axle_c

right_hub_ring := hardware.Ring472(r472_24)
right_hub_ring seats(turn: 0deg, up: axle, east: std.x) right_hub_clip.p
left_hub_ring := hardware.Ring472(r472_24)
left_hub_ring seats(turn: 0deg, up: axle, east: std.x) left_hub_clip.p

frame := solid(frame_main)
rear_pod union frame
rear_cover.body union frame
service_cover union frame
left_cap.body union frame
right_cap.body union frame

// Full-turn crank swept envelopes, not just the drawn pedal orientation.
construction right_crank_sweep := solid({q | q in std.sets.Cylinder(bb_line, r: crank_throw + 12mm)
  q not in std.sets.Cylinder(bb_line, r: 11.04mm)
  std.origin distance(in: (-crank_face - crank_t, -crank_face), along: bb_line) q})
construction left_crank_sweep := solid({q | q in std.sets.Cylinder(bb_line, r: crank_throw + 12mm)
  q not in std.sets.Cylinder(bb_line, r: 11.04mm)
  std.origin distance(in: (crank_face, crank_face + crank_t), along: bb_line) q})
claim right_crank_sweep clear(2mm) frame
claim left_crank_sweep clear(2mm) frame

// -- claims ----------------------------------------------------------------------------------------
// The shaft runs clear inside the chainstay, and every turning part clear of the frame.
claim shaft clear(3mm) frame
claim front_coupler.body clear(1mm) frame
claim rear_coupler.body clear(1.9mm) frame
claim rear_wheel.tire_envelope clear(6mm) frame
claim rear_wheel.rim clear(6mm) frame
claim box.carrier clear(0.5mm) frame
claim bb_gear clear(0.5mm) frame
claim bb_gear_core clear(0.5mm) frame
claim hub clear(0.5mm) frame
claim hub_gear clear(0.5mm) frame
claim hub_gear_core clear(0.5mm) frame
// The pinions clear what turns beside them: the sun's sleeve, the spindle's right bearing, and
// the hub.
claim box.turns.sun clear(0.5mm) bb_pinion
claim right_6804.outer_ring clear(0.5mm) bb_pinion
claim hub clear(0.5mm) hub_pinion
// The cranks clear the frame.
claim right_crank.body clear(2mm) frame
claim left_crank.body clear(2mm) frame

// -- the parts -------------------------------------------------------------------------------------
// A crank arm as it is drawn face on, in its frame's front: a boss about the spindle and an eye
// `throw` along `std.x`, joined by the two lines tangent to both, bored for the spindle and the
// pedal's 9/16" thread; 11 mm thick, in front of the front.
component Crank(throw: Length, boss: Length, eye: Length, bore: Length) {
  in std.front {
    c := point
    c right_of(d: throw) std.origin
    a := point hint((0mm, boss))
    b := point hint((0mm, -boss))
    d := point hint((throw, eye))
    e := point hint((throw, -eye))
    lower := line(b, e)
    small := arc(center: c, start: e, end: d)
    upper := line(d, a)
    big := arc(center: std.origin, start: a, end: b)
    radius(boss) big
    radius(eye) small
    // the outer tangents: each tangent point on its own side of the line of centres
    ccw(std.origin, c, a)
    ccw(std.origin, c, d)
    cw(std.origin, c, b)
    cw(std.origin, c, e)
    lower tangent(at: p1) big
    lower tangent(at: p2) small
    upper tangent(at: p1) small
    upper tangent(at: p2) big
    spindle_hole := circle(center: std.origin)
    radius(bore / 2) spindle_hole
    pedal_hole := circle(center: c)
    radius(0.5625in / 2) pedal_hole
  }
  body := solid(std.solids.Prism(face(lower, small, upper, big, holes: spindle_hole, pedal_hole),
    from: -crank_t, to: 0mm))
}
