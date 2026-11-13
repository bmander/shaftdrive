// Prototype interfaces. Ideal profiles; thread helices and seal lip springs are
// represented by their manufacturing envelopes. See engineering/specification.html.
unit mm
use std
use std.solids
use std.sets
use std.solids (union, cut, common)

component StraightSpline(root: Length, major: Length, tooth: Length, n: Int, length: Length) {
  in std.top {
    root_circle := circle(center: std.top.origin)
    radius(root / 2) root_circle
    outside := circle(center: std.top.origin)
    radius(major / 2) outside
    a := point
    b := point
    c := point
    d := point
    fix((root / 2 - 1mm, -tooth / 2)) a
    fix((major / 2, -tooth / 2)) b
    fix((major / 2, tooth / 2)) c
    fix((root / 2 - 1mm, tooth / 2)) d
    edge_a := line(a, b)
    edge_b := line(b, c)
    edge_c := line(c, d)
    edge_d := line(d, a)
  }
  body := solid(std.solids.Prism(face(root_circle), from: 0mm, to: length))
  construction blank := solid(std.solids.Prism(face(outside), from: 0mm, to: length))
  construction tooth_body := solid(std.solids.Prism(face(edge_a, edge_b, edge_c, edge_d), from: 0mm, to: length))
  blank common tooth_body
  repeat n as i {
    construction turned := tooth_body at(under: std.z) i * 360deg / n
    turned union body
  }
}

component Annulus(d: Length, D: Length, length: Length) {
  in std.top {
    outside := circle(center: std.top.origin)
    inside := circle(center: std.top.origin)
    radius(D / 2) outside
    radius(d / 2) inside
  }
  body := solid(std.solids.Prism(face(outside, holes: inside), from: 0mm, to: length))
}

component EndCap() {
  // z=0 is the +/-36.5 main-case face. Bearing 25x37x7 is at z=2.5..9.5.
  // Lip seal 25x35x5 is at z=-2.5..2.5. Pilot O-ring groove is z=-5.8..-2.4.
  p := point
  fix((0mm, 0mm, 10mm)) p
  construction ax := line(std.origin, p)
  body := solid({q | q in std.sets.Cylinder(ax, r: 64mm)
                     q not in std.sets.Cylinder(ax, r: 12.75mm)
                     std.origin distance(in: (0mm, 4.5mm), along: ax) q})
  construction pilot := solid({q | q in std.sets.Cylinder(ax, r: 55mm)
                                  q not in std.sets.Cylinder(ax, r: 50mm)
                                  std.origin distance(in: (-6.5mm, 0mm), along: ax) q})
  construction boss := solid({q | q in std.sets.Cylinder(ax, r: 23mm)
                                 q not in std.sets.Cylinder(ax, r: 12.75mm)
                                 std.origin distance(in: (-2.5mm, 10mm), along: ax) q})
  pilot union body
  boss union body
  construction bearing_bore := solid({q | q in std.sets.Cylinder(ax, r: 18.5mm)
    std.origin distance(in: (2.5mm, 11mm), along: ax) q})
  construction seal_bore := solid({q | q in std.sets.Cylinder(ax, r: 17.5mm)
    std.origin distance(in: (-3mm, 2.5mm), along: ax) q})
  bearing_bore cut body
  seal_bore cut body
  construction groove := solid({q | q in std.sets.Cylinder(ax, r: 56mm)
    q not in std.sets.Cylinder(ax, r: 52.9mm)
    std.origin distance(in: (-5.8mm, -2.4mm), along: ax) q})
  groove cut body
  in std.top {
    ring 6 about std.top.origin {
      hole_c := point
      std.top.origin distance(59.5mm) hole_c
      hole := circle(center: hole_c)
      radius(2.75mm) hole
      construction drill := solid(std.solids.Prism(face(hole), from: -1mm, to: 6mm))
    }
    std.top.origin distance(0mm, along: v) hole_c[0]
    std.top.origin distance(>= 0mm, along: u) hole_c[0]
  }
  repeat 6 as i { drill[i] cut body }
}

component Oring(major: Length, section: Length) {
  in std.front {
    c := point
    fix((major, 0mm)) c
    circle_ := circle(center: c)
    radius(section / 2) circle_
  }
  body := solid(std.solids.Revolution(face(circle_), about: std.z))
}

preview {
  spline := StraightSpline(root: 14mm, major: 17mm, tooth: 3.8mm, n: 6, length: 22mm)
}

// Radially removable rear coupling, with four M4 retaining screws.
component SplitCoupler() {
  blank := Annulus(d: 14.08mm, D: 32mm, length: 43.5mm)
  female := StraightSpline(root: 14.08mm, major: 17.08mm, tooth: 3.86mm, n: 6, length: 43.5mm)
  female.body cut blank.body
  repeat 2 as side {
    repeat 2 as station {
      p := point
      e := point
      fix((-20mm, if(side == 0, -12mm, 12mm), if(station == 0, 7mm, 36.5mm))) p
      fix((20mm, if(side == 0, -12mm, 12mm), if(station == 0, 7mm, 36.5mm))) e
      construction ax := line(p, e)
      construction drill := solid({q | q in std.sets.Cylinder(ax, r: 2.2mm)
        p distance(in: (0mm, 40mm), along: ax) q})
      drill cut blank.body
    }
  }
  construction left_half := solid({q | std.origin distance(in: (-20mm, -0.05mm), along: std.x) q
    std.origin distance(in: (-20mm, 20mm), along: std.y) q
    std.origin distance(in: (0mm, 43.5mm), along: std.z) q})
  construction right_half := solid({q | std.origin distance(in: (0.05mm, 20mm), along: std.x) q
    std.origin distance(in: (-20mm, 20mm), along: std.y) q
    std.origin distance(in: (0mm, 43.5mm), along: std.z) q})
  left := solid(blank.body)
  right := solid(blank.body)
  left_half common left
  right_half common right
  body := solid(left)
  right union body
}
