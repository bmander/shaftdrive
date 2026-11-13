// The shaft drive's numbers, stated once: a chainless bicycle transmission whose shaft runs
// sealed inside the drive-side chainstay, its step-up gearbox inside an oversized bottom bracket
// and its step-down gearbox inside the rear dropout.
//
// **Why the shaft spins fast.**  A drive shaft is a torsion spring between the cranks and the
// wheel: under a pedal stroke it winds up, and gives the energy back late and out of phase.  Its
// wind-up at a given torque is `T L / (G J)`, and the torque it carries is the crank's divided by
// how much faster than the crank it turns.  So the bottom bracket steps the speed up by `k`
// before the shaft and the hub steps it down again: the shaft carries `1/k` of the crank torque,
// winds up `1/k` as far, and that angle is seen at the crank `1/k` again.  The crank feels a
// spring `k²` stiffer than the same shaft driven at crank speed (`wind_gain` below, 81).
//
// Fixed-gear train: 30/15/60 planetary steps up 3x; 54/18 front spiral bevel
// steps up another 3x. Shaft speed is 9x crank speed. The reversed rear pair
// reduces 3x, giving 3x wheel/crank speed. Both bevel shaft angles are 94.5deg.
// Torque reverses during backpedaling: no freewheel, no threaded-only torque joint.
//
// Every figure that carries a unit says it, so the arithmetic is checked; claims over the figures
// are judged before the solve.
unit mm

// -- the rider and the wheel --------------------------------------------------------------------
cadence := 90rpm                       // a brisk cruising cadence
crank_cruise := 250W / (cadence / 1rad) // mean torque: P / angular velocity; no alternating-leg divisor
crank_peak := 180Nm
roll_out := pi * (622mm + 2 * 37mm) // unloaded geometric circumference; measure loaded rollout

// -- the planetary at the bottom bracket ---------------------------------------------------------
Zs := 30                               // sun
Zp := 15                               // planets
Zr := 60
planets := 3
mn := 1.25mm
alpha := 20deg                         // normal pressure angle
beta := 20deg                          // helix angle: sun right-handed, planets and ring left-handed
pw := 23mm
ha := 1mm
hf := 1.25mm
backlash := 0.10mm
edge := 0.3mm                          // the chamfer that breaks every tooth's end

mt := mn / cos(beta)
alpha_t := atan(tan(alpha) / cos(beta))
rs := Zs * mt / 2
rpl := Zp * mt / 2
rr := Zr * mt / 2
a := rs + rpl
planet_tip := rpl + ha

step_planetary := 1 + Zr / Zs

// -- the spiral bevel pairs ---------------------------------------------------------------------
// The corrected pair in `spiral_bevel/angled_bevel.sv`, 18 and 54 teeth, zero offset: its
// axes meeting, which wastes none of its work in the lengthwise sliding a hypoid's offset brings.
// Mean module is 1.5 mm; pitch-cone dimensions account for the non-right shaft angle. Its
// shafts meet at `bevel_angle`, not square: the drive-side chainstay splays `splay` outward toward
// the hub, as a frame's chainstays do, and the shaft runs along it.
scale := 0.75
pinion_teeth := 18
gear_teeth := 54
splay := 4.5deg
bevel_angle := 90deg + splay           // between each gear's axis and its pinion's
bevel_module := 2mm * scale
bevel_backlash := 0.14mm
bevel_tip_relief := 0.2mm * scale
bevel_end_relief := 0.2mm * scale
bevel_cutter_radius := 75.6122mm * scale  // the face mill: hypoid.sv's, chosen, not found
step_bevel := gear_teeth / pinion_teeth

// -- what the train does ---------------------------------------------------------------------------
k := step_planetary * step_bevel
overall := k / step_bevel
shaft_speed := cadence * k
wheel_speed := cadence * overall
road_speed := wheel_speed / turn * roll_out
shaft_cruise := crank_cruise / k
shaft_peak := crank_peak / k

// The planetary's shares of the crank's torque: the sun carries Zs / (Zs + Zr) of it, the ring
// reacts the rest into the shell.  Each of the three planets takes a third of the sun's
// tangential force.
sun_peak := crank_peak * Zs / (Zs + Zr)
mesh_force := sun_peak / rs / planets
// Lewis's bending stress at the planet's root, its form factor at the planet's virtual count
// (Zp / cos³β ≈ 18): an estimate, to be checked to ISO 6336 before tooling.
lewis_y := 0.31
sigma_planet := mesh_force / (pw * mn * lewis_y)
case_steel := 450MPa

// -- the shaft and its tube --------------------------------------------------------------------------
shaft_od := 18mm
shaft_id := 12mm
shaft_G := 80000MPa                    // shear modulus of steel
cs_length := 460mm
bb_drop := 70mm                        // the axle stands this far above the bottom bracket
pinion_y := -39mm
J := pi * (shaft_od^4 - shaft_id^4) / 32
shaft_tau := shaft_peak * (shaft_od / 2) / J
// The wind-up the crank feels at the sprint peak, the shaft driven at k times crank speed, and
// the same shaft driven 1:1 at the crank's speed and torque.
wind := shaft_peak * cs_length / (shaft_G * J) * 1rad / k
wind_direct := crank_peak * cs_length / (shaft_G * J) * 1rad
wind_gain := wind_direct / wind
tube_od := 28mm
tube_id := 25mm

// -- the frame: a 56 cm road frame in 7005 aluminium ------------------------------------------------
seat_angle := 73.5deg
seat_length := 540mm                   // the bracket's centre to the seat tube's top
stack := 575mm                         // the head tube's top over the bracket
reach := 385mm                         //                    and ahead of it
head_angle := 72deg
head_length := 160mm
cluster := 30mm                        // the top tube and seat stays meet the seat tube this far below its top
stay_spread := 24mm
stay_below := 28mm                     // and this far down the seat tube from the top tube's axis
old := 142mm
dropout_t := 7mm
dropout_r := 32mm                      // the non-drive dropout's plate about the axle
stay_short := 26mm                     // the stays end this far short of the axle's centre, on the dropouts
ns_stay_y := 42mm
head_od := 50mm
head_id := 44mm
down_od := 44mm
down_id := 41mm
seat_od := 34.9mm
seat_id := 31.6mm
top_od := 31.8mm
top_id := 28.8mm
stay_od := 16mm
stay_id := 13mm
ns_stay_od := 22mm
ns_stay_id := 19mm

// -- the bottom bracket: a 73 mm case, with external bearing caps -----------------------------------------
shell_od := 128mm
shell_id := 110mm
case_left := 36.5mm                      // its faces, either side of the mid-plane: the left one open for
case_right := -36.5mm                    // the bearing cup, the right one closed round the right bearing
end_wall := 7mm
diaphragm := (-13mm, -4mm)
                                       // planetary and the bevel gear
cup := (29mm, 38.5mm)                    // the left bearing cup, pressed into the shell's open end
boss_r := 26.5mm
                                       // round a bevel pinion 46.8 mm across
boss_ahead := 12mm                     // from this far ahead of the pinion's mean point: short of the
                                       // hub, whose axle the shaft's axis meets
boss_behind := 52mm
wall := 2.5mm
web := (-1.5mm, 4mm)                   // a bevel member's web: its band along the axis from the foot
                                       // of its mean point, filling its core out to the blank's back
pinion_bearing := (9mm, 23mm)
crank_throw := 170mm
crank_face := 73mm
                                       // clear of the pinion's housing
ring_od := 94mm
spindle_d := 25mm
spindle_bore := 8.5mm
sun_bore := 31mm
sleeve_r := 17.5mm
sleeve_to := 48mm
sleeve_groove_z := ring_y - diaphragm.y - 0.8mm
spindle_tau := crank_peak * (spindle_d / 2) / (pi * (spindle_d^4 - spindle_bore^4) / 32)
planet_bore := 10mm
pin_d := 8mm
ring_y := 14.5mm
plate_t := 2.5mm
plate_r := 36mm
gap := 0.3mm
bridge_w := 20mm
bridge_r := 23.5mm

// -- the hub ---------------------------------------------------------------------------------------
hub_r := 15mm
hub_bore := 8mm                        // between the bearings
hub_seat := 12mm
hub_span := (-93mm, 67mm)
hub_bearings := (-85mm, 62mm)
flange_r := 28mm
flanges := (-31.5mm, 28.5mm)
                                       // of the hub's pinion housing
spokes := 16
rear_case_r := 60mm
rear_case := (-99mm, -41mm)
axle_d := 12mm                         // the thru-axle

// -- the bearings and retaining rings ---------------------------------------------------------------
// The catalogue's rows are `std.bearings` (ISO 15: b6901 at the hub, b6805 in the bracket's caps)
// and `std.retaining` (DIN 471 / 472).  The two no catalogue there holds, `sun_bearing` and the
// pinions' angular-contact `pinion_ac`, are the drive's own, below; each is a `BearingSize`.

// -- claims over the design table --------------------------------------------------------------------
claim Zr == Zs + 2 * Zp
claim (Zs + Zr) / planets == floor((Zs + Zr) / planets)
// The rack cuts no undercut: its tip stays above the interference point, rp sin² αt inside the
// pitch circle, on the smallest gear.
claim hf <= rpl * sin(alpha_t)^2
// The contact ratios: how many tooth pairs share the load on average, across the face (the overlap
// ratio, the helix's gift) and round the profile (transverse: sun–planet, and planet–ring,
// internal).  A helical mesh runs quiet where their sum stays above two.
eps_beta := pw * sin(beta) / (pi * mn)
base_pitch := pi * mt * cos(alpha_t)
reach_s := sqrt((rs + ha)^2 - (rs * cos(alpha_t))^2)       // each tip's reach along the line of action
reach_p := sqrt((rpl + ha)^2 - (rpl * cos(alpha_t))^2)
reach_r := sqrt((rr - ha)^2 - (rr * cos(alpha_t))^2)
eps_sp := (reach_s + reach_p - a * sin(alpha_t)) / base_pitch
eps_pr := (reach_p - reach_r + (rr - rpl) * sin(alpha_t)) / base_pitch
claim eps_beta >= 1
claim eps_sp >= 1.1 and eps_pr >= 1.1
claim eps_sp + eps_beta >= 2.2 and eps_pr + eps_beta >= 2.2
claim sigma_planet <= case_steel
claim shaft_tau <= 200MPa
claim spindle_tau <= 300MPa
claim wind <= 0.5deg

// Wheel reference: Schwalbe Marathon Mondial 37-622; DT Swiss R460 32H, ERD596.
wheel_bsd := 622mm
wheel_erd := 596mm
wheel_tire := 37mm
wheel_check_tire := 40mm
wheel_rim_outer := 314mm
wheel_rim_inner := 291mm
wheel_rim_width := 22mm
wheel_spoke_d := 2mm
wheel_flange_pcd := 48mm
wheel_cross := 3
wheel_clearance := 6mm
service_factor := 2
planet_share_factor := 1.3
planet_root_screen := sigma_planet * service_factor * planet_share_factor
claim planet_root_screen <= case_steel / 1.5

// Detailed bought-part envelopes and shaft stations. Bearing internals are illustrative only.
sun_bearing := {d: 35mm, D: 62mm, B: 9mm, balls: 13, dw: 6.35mm}
pinion_ac := {d: 17mm, D: 47mm, B: 14mm, balls: 10, dw: 8mm}
case_bearing_y := 42.5mm
pinion_second := 36mm
shaft_spline_start := 53mm
shaft_spline_length := 22mm
shaft_tube_start := 75mm
crank_t := 15mm
bevel_delta_p := atan2(sin(bevel_angle), step_bevel + cos(bevel_angle))
bevel_delta_g := bevel_angle - bevel_delta_p
bevel_R := gear_teeth * bevel_module / 2 / sin(bevel_delta_g)
bevel_pitch_gear := gear_teeth * bevel_module / 2
bevel_pitch_pinion := pinion_teeth * bevel_module / 2
bevel_front_y := pinion_y + bevel_R * cos(bevel_delta_p) * sin(splay) + bevel_R * cos(bevel_delta_g)
sun_spline_from := ring_y - bevel_front_y - 5mm
sun_spline_to := ring_y - bevel_front_y + 5mm
claim abs(sin(bevel_delta_g) / sin(bevel_delta_p) - step_bevel) < 0.000001
claim abs(bevel_delta_p + bevel_delta_g - bevel_angle) < 0.000001deg

r471_35 := {groove: 33.4mm, t: 1.5mm, band: 3mm, r_eye: 21mm, eye: 4mm, hole: 1.8mm}
