// 700c touring wheel packaging model. Millimeters; axle is local +y, z up.
// Reference tire: Schwalbe Marathon Mondial 37-622 (French 700x35C).
// Reference rim: DT Swiss R460 32H, 596 ERD, 622 BSD, 22 outer width, 23 height.
// Rim is a conservative extrusion envelope, not a reverse-engineered rim section.
// Spokes are a 32-hole, three-cross J-bend layout with alternating flange sides.
// The complete rotational spoke envelope is verified separately by engineering/clearance.py.
unit mm
use std
use std.sets
use std.solids
use std.solids (union)
use dims (wheel_bsd, wheel_erd, wheel_tire, wheel_check_tire, wheel_rim_outer,
          wheel_rim_inner, wheel_rim_width, wheel_spoke_d, wheel_flange_pcd,
          wheel_cross, flanges, spokes)

component TouringWheel() {
  in std.side {
    section_c := point
    fix((0mm, wheel_bsd / 2 + wheel_tire / 2)) section_c
    section := circle(center: section_c)
    radius(wheel_tire / 2) section
    check_c := point
    fix((0mm, wheel_bsd / 2 + wheel_check_tire / 2)) check_c
    check_section := circle(center: check_c)
    radius(wheel_check_tire / 2) check_section
  }
  tire := solid(std.solids.Revolution(face(section), about: std.y))
  construction tire_envelope := solid(std.solids.Revolution(face(check_section), about: std.y))
  axle_end := point
  fix((0mm, 10mm, 0mm)) axle_end
  construction axle_line := line(std.origin, axle_end)
  rim := solid({q | q in std.sets.Cylinder(axle_line, r: wheel_rim_outer)
                    q not in std.sets.Cylinder(axle_line, r: wheel_rim_inner)
                    std.origin distance(in: (-wheel_rim_width / 2, wheel_rim_width / 2), along: axle_line) q})
  repeat 2 as side {
    flange_y := if(side == 0, flanges.x + 1.5mm, flanges.y + 1.5mm)
    rim_y := if(side == 0, -1.5mm, 1.5mm)
    repeat spokes as i {
      sense := if(i - 2 * floor(i / 2) == 0, 1, -1)
      rim_angle := (i + side / 2) * 360deg / spokes
      hub_angle := rim_angle + sense * wheel_cross * 360deg / spokes
      hub_point := point
      rim_point := point
      fix((wheel_flange_pcd / 2 * cos(hub_angle), flange_y + sense * 2.55mm,
           wheel_flange_pcd / 2 * sin(hub_angle))) hub_point
      fix((wheel_erd / 2 * cos(rim_angle), rim_y, wheel_erd / 2 * sin(rim_angle))) rim_point
      construction wire := line(hub_point, rim_point)
      spoke := solid({q | q in std.sets.Cylinder(wire, r: wheel_spoke_d / 2)
                          hub_point distance(>= 0mm, along: wire) q
                          rim_point distance(<= 0mm, along: wire) q})
      nipple := solid({q | q in std.sets.Cylinder(wire, r: 2mm)
                           rim_point distance(in: (-6mm, 6mm), along: wire) q})
    }
  }
}

preview {
  wheel := TouringWheel()
}
