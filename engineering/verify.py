#!/usr/bin/env python3
"""Reproducible sizing screens, NOT ISO gear, wheel, frame or bearing certification."""
import json, math
from pathlib import Path
import re
source=(Path(__file__).parent.parent/"dims.sv").read_text()
for key,value in {"pinion_teeth":18,"gear_teeth":54,"mn":1.25,"pw":23,"planet_bore":10,"pin_d":8,"splay":4.5,"cs_length":460,"shaft_od":18,"shaft_id":12}.items():
 assert float(re.search(r"^"+key+r" := ([0-9.]+)",source,re.M)[1])==value, "Update independent calculation inputs: "+key
pi=math.pi
rad=math.radians
T=180000.0; proof=2; n=90; mass=110
sigma=rad(94.5); ratio=3; dp=math.atan2(math.sin(sigma),ratio+math.cos(sigma));dg=sigma-dp
m=1.5; rp=18*m/2;rg=54*m/2;R=rg/math.sin(dg);b=.3*R;mn=m*math.cos(rad(25))
J=pi*(18**4-12**4)/32
pitch=1.25/math.cos(rad(20));rs=30*pitch/2
Ft=T/9/rp
Y=pi*(.154-.912/(18/(math.cos(dp)*math.cos(rad(25))**3)))
# Lewis-style screening approximation; taper applied even though module is at mean cone.
bevel_stress=Ft*1.25/(b*mn*Y)*(R/(R-b))
# Pitch-point line contact approximation; elastic steel, equal E=210GPa, nu=.3.
alpha=rad(20);spiral=rad(25)
Fr=Ft*(math.tan(alpha)*math.cos(dp)/math.cos(spiral)+math.sin(dp)*math.tan(spiral))
Fa=Ft*(math.tan(alpha)*math.sin(dp)/math.cos(spiral)+math.cos(dp)*math.tan(spiral))
bearing_limits = [float(x) for x in re.search(r"pinion_bearing := \(([0-9.]+)mm, ([0-9.]+)mm\)", source).groups()]
prox_station = sum(bearing_limits)/2
far_station = float(re.search(r"pinion_second := ([0-9.]+)mm", source)[1])
transverse=math.hypot(Ft,Fr);prox=transverse*far_station/(far_station-prox_station)
Eprime=1/(2*(1-.3**2)/210000)
rho_p=rp*math.sin(alpha);rho_g=rg*math.sin(alpha);rho=rho_p*rho_g/(rho_p+rho_g)
Fn=Ft/math.cos(alpha)/math.cos(spiral)
hertz=math.sqrt(Fn*1.25*Eprime/(pi*b*rho))
L=lambda y:math.sqrt(298**2+24**2-2*298*24*math.cos(rad(67.5))+(y-1.5)**2)
lever=24*298*math.sin(rad(67.5))/L(30)
results={
 'status':'Engineering proposal; geometric checks plus preliminary strength screens, not fabrication release',
 'inputs':{'crank_peak_Nm':180,'proof_crank_Nm':360,'cruise_W':250,'cadence_rpm':90,'system_mass_kg':110,'static_rear_share':.65,'vertical_load_factor':3,'steel_G_MPa':80000,'steel_E_MPa':210000,'assumed_core_yield_MPa':900,'assumed_reversed_gear_bending_allowable_MPa':450,'assumed_contact_allowable_MPa':1500},
 'kinematics':{'planetary_ratio':3,'front_bevel_ratio':3,'rear_bevel_ratio':1/3,'overall_ratio':3,'shaft_rpm':810,'wheel_rpm':270,'cruise_crank_Nm':250/(2*pi*n/60),'unloaded_rollout_m':pi*.696,'geometric_kph_at_90rpm':pi*.696*270*60/1000,'shaft_peak_Nm':20,'sun_and_wheel_peak_Nm':60,'fixed_ring_peak_Nm':120},
 'bevel_geometry':{'shaft_angle_deg':94.5,'pinion_cone_deg':math.degrees(dp),'gear_cone_deg':math.degrees(dg),'pinion_mean_pitch_radius_mm':rp,'gear_mean_pitch_radius_mm':rg,'mean_cone_mm':R,'face_width_mm':b,'normal_module_mm':mn,'normal_backlash_allowance_mm':.14},
 'screens':{'planet_bending_MPa_at_2x_peak_1p3_sharing':(T/3/rs/3)/(23*1.25*.31)*2*1.3,'bevel_bending_MPa_peak_K1p25':bevel_stress,'bevel_bending_margin_assumed_allowable':450/bevel_stress,'pitch_point_Hertz_MPa_peak_K1p25':hertz,'bevel_tangential_N':Ft,'pinion_axial_N_worst_hand':Fa,'pinion_transverse_N':transverse,'pinion_bearing_centers_mm':[prox_station,far_station],'proximal_bearing_radial_N_peak':prox,'bearing_C0_over_2x_radial':8000/(2*prox),'shaft_J_mm4':J,'shaft_tau_MPa_peak':T/9*9/J,'crank_referred_tube_windup_deg_conservative_460mm':math.degrees(T*460/(80000*J*81)),'crank_referred_bevel_lash_deg_upper_estimate':math.degrees(2*.14/(math.cos(spiral)*rp)/9),'spindle_root_torsion_VM_MPa_at_proof_Kt1p8':math.sqrt(3)*1.8*16*(2*T)*22/(pi*(22**4-8.5**4))},
 'wheel':{'tire_ETRTO':'37-622; check 40-622 plus 2mm movement envelope','flange_centers_mm':[-30,30],'flange_span_mm':60,'rim_ERD_mm':596,'spokes':32,'cross':3,'nominal_centerline_spoke_length_mm':L(30),'alternating_endpoint_lengths_mm':[L(27.45),L(32.55)],'nominal_bracing_deg':math.degrees(math.asin(28.5/L(30))),'left_right_tension_ratio':1.0,'original_tension_ratio_approx':34.5/12.5,'target_tension_N':1000,'torque_increment_N_per_spoke_peak':60000/(32*lever),'torque_increment_N_per_spoke_proof':120000/(32*lever),'rear_vertical_load_N_3g':mass*9.81*.65*3},
 'joints':{},
 'planet_pin':{'diameter_mm':8,'bush_OD_mm':10,'proof_force_N':2*(T/3/rs/3)*2*1.3,'proof_uniform_load_bending_MPa':32*(2*(T/3/rs/3)*2*1.3)*(23+2*.3+2.5)/8/(pi*8**3),'proof_bush_pressure_MPa':(2*(T/3/rs/3)*2*1.3)/(8*23)}
}
for name,torque,r,h,length,effective in [('shaft',40000,7.75,1.5,21,3),('sun_bevel',120000,17,1,10,6),('hub_bevel',120000,14.5,1,12,6),('carrier',360000,11.75,1.5,25.8,8),('crank',360000,11.75,1.5,15,8),('ring_dogs',240000,47.75,1.5,23,3)]:
 results['joints'][name]={'proof_torque_Nm':torque/1000,'effective_flanks':effective,'mean_flank_pressure_MPa':torque/(r*h*length*effective)}
results['joints']['ring_pins']={'proof_torque_Nm':240,'effective_pins':3,'single_shear_MPa':240000/(55*3*pi*6**2/4)}
assert abs(math.sin(dg)/math.sin(dp)-3)<1e-10
assert abs(dp+dg-sigma)<1e-10
assert results['screens']['planet_bending_MPa_at_2x_peak_1p3_sharing']<450/1.5
assert results['screens']['spindle_root_torsion_VM_MPa_at_proof_Kt1p8']<900/1.5
assert results['wheel']['alternating_endpoint_lengths_mm'][0]>280
assert 250/(2*pi*90/60)<27
Path(__file__).with_name('calculations.json').write_text(json.dumps(results,indent=2)+'\n')
print(json.dumps(results,indent=2))
