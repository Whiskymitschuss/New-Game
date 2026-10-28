class_name HeroGear
extends RefCounted
# Equipment is a direct view of real run stats and the equipped weapon's rank.
# It owns no save state, timers, nodes, textures or random stream.
const STEEL := Color("263f42")
const EDGE := Color("102426")
const CYAN := Color("91d6cf")
const BRASS := Color("d3aa67")

static func gear_state(game: Node) -> Dictionary:
 var stats: Dictionary=game.get("stats")
 var profile=game.get("profile")
 var data: Dictionary=profile.data
 var cls=clampi(int(data.get("class",0)),0,Content.CLASSES.size()-1)
 var baseline: Dictionary=Content.CLASSES[cls]
 var level=clampi(int(game.get("level")),1,100)
 var capacity=maxf(0,float(stats.get("capacity",Content.ammo_capacity(level)))-Content.ammo_capacity(level))
 var magazines=maxf(0,float(stats.get("magazine",0)))
 var drop=maxf(0,float(stats.get("drop",12))-12)
 var belt=clampi(ceili(capacity/250.0)+ceili(magazines/6.0)+ceili(drop/4.0),0,3)
 var armor=maxf(0,float(stats.get("armor",0)))
 var thorns=float(stats.get("thorns",0))>0
 var plates=clampi(ceili(armor/3.0),0,3)
 var rank=Progression.effective_rank(data,int(data.get("weapon",0)))
 var extra_damage=maxf(0,float(stats.get("damage",baseline["damage"]))-float(baseline["damage"]))
 var weapon=clampi(maxi(rank,ceili(maxf(0,extra_damage-0.00001)/0.30)),0,3)
 var power=game.get("overdrive_left")
 return {"belt":belt,"armor":plates,"thorns":thorns,"weapon":weapon,"rank":rank,"medic":float(stats.get("regen",baseline["regen"]))>float(baseline["regen"])+0.01,"shield":float(game.get("shield"))>0,"overdrive":power!=null and float(power)>0,"class":cls,"outfit":clampi(int(data.get("outfit",0)),0,2),"drone":float(stats.get("drone",0))>(1.0 if cls==1 else 0.0)}

static func attachment_pose(game: Node,base: Vector2,scale_value: float,motion: Dictionary,tilt: float=0.0) -> Dictionary:
 # This is exactly the same top-half interpolation as ActorRig.draw_pose.
 var settings: Dictionary=game.profile.data.get("settings",{})
 var reduced=bool(settings.get("reduced_motion",false))
 var entry_age=float(game.deployment_age) if game.mode in ["play","pause","upgrade"] else -1.0
 var rig=ActorRig.hero_pose(float(game.combat_motion.clock),entry_age,reduced)
 var h=112.0*scale_value
 var torso: Vector2=rig["torso"]*h
 var upper=torso+Vector2(float(rig["lean"])*h,0)
 var offset: Vector2=motion.get("offset",Vector2.ZERO)
 var origin=base+Vector2(offset.x*scale_value,0)+game.combat_motion.camera_offset()+rig["entry"]*h
 return {"height":h,"upper":upper,"hip":torso*0.35,"transform":Transform2D(tilt+float(motion.get("angle",0)),motion.get("scale",Vector2.ONE),0.0,origin),"reduced":reduced,"clock":float(game.combat_motion.clock)}

static func point(pose: Dictionary,p: Vector2) -> Vector2:
 var blend=clampf((1+p.y)/ActorRig.HIP,0,1)
 return p*float(pose["height"])+Vector2(pose["upper"]).lerp(pose["hip"],blend)

static func poly(canvas: Node2D,pose: Dictionary,vertices: Array,color: Color) -> void:
 var points=PackedVector2Array()
 for vertex in vertices:points.append(point(pose,vertex))
 canvas.draw_colored_polygon(points,color)

static func stroke(canvas: Node2D,pose: Dictionary,a: Vector2,b: Vector2,color: Color,width: float=0.01) -> void:
 canvas.draw_line(point(pose,a),point(pose,b),color,maxf(0.6,width*float(pose["height"])),true)

static func draw(canvas: Node2D,game: Node,base: Vector2,scale_value: float,motion: Dictionary,tilt: float=0.0) -> void:
 var state=gear_state(game)
 if int(state["belt"])+int(state["armor"])+int(state["weapon"])==0 and not state["thorns"] and not state["medic"] and not state["shield"] and not state["overdrive"] and not state["drone"]:return
 var pose=attachment_pose(game,base,scale_value,motion,tilt)
 var trans: Transform2D=pose["transform"]
 canvas.draw_set_transform(trans.origin,trans.get_rotation(),trans.get_scale())
 var ceramic=[Color("cdbb99"),Color("a2c7c5"),Color("b8a8ba")][int(state["class"])]
 if int(state["outfit"])==1:ceramic=ceramic.lerp(Color("8cbecb"),0.30)
 elif int(state["outfit"])==2:ceramic=ceramic.lerp(Color("db9f8b"),0.25)
 ceramic=ceramic.darkened(0.12)
 if int(state["belt"])>0:
  # A curved load belt under the rifle; the brass tips remain readable at 112px.
  poly(canvas,pose,[Vector2(-0.31,-0.55),Vector2(0.025,-0.515),Vector2(0.015,-0.465),Vector2(-0.32,-0.50)],EDGE)
  poly(canvas,pose,[Vector2(-0.305,-0.542),Vector2(0.016,-0.509),Vector2(0.01,-0.479),Vector2(-0.312,-0.511)],Color("61523a"))
  var count=3+int(state["belt"])
  for i in range(count):
   var x=-0.285+i*0.047
   var y=-0.533+(x+0.285)*0.11
   poly(canvas,pose,[Vector2(x,y),Vector2(x+0.031,y+0.003),Vector2(x+0.028,y+0.068),Vector2(x-0.002,y+0.064)],STEEL)
   stroke(canvas,pose,Vector2(x+0.012,y+0.011),Vector2(x+0.010,y+0.049),BRASS,0.014)
   stroke(canvas,pose,Vector2(x+0.011,y-0.004),Vector2(x+0.012,y+0.009),Color("f4d59a"),0.009)
  stroke(canvas,pose,Vector2(-0.313,-0.537),Vector2(0.02,-0.502),ceramic.darkened(0.20),0.009)
  if int(state["belt"])>=2:
   # High-capacity upgrades add a back-mounted magazine carrier.
   poly(canvas,pose,[Vector2(-0.365,-0.68),Vector2(-0.30,-0.66),Vector2(-0.295,-0.555),Vector2(-0.358,-0.566)],EDGE)
   for i in range(3):stroke(canvas,pose,Vector2(-0.352+i*0.019,-0.655),Vector2(-0.35+i*0.019,-0.585),BRASS.darkened(0.15),0.012)
 if int(state["armor"])>0:
  # The left shoulder and breast are clear of face, visor, barrel and hands.
  poly(canvas,pose,[Vector2(-0.325,-0.825),Vector2(-0.214,-0.838),Vector2(-0.155,-0.785),Vector2(-0.181,-0.703),Vector2(-0.284,-0.70),Vector2(-0.345,-0.761)],Color(EDGE,0.55))
  poly(canvas,pose,[Vector2(-0.318,-0.812),Vector2(-0.221,-0.823),Vector2(-0.171,-0.781),Vector2(-0.192,-0.721),Vector2(-0.278,-0.717),Vector2(-0.329,-0.763)],Color(ceramic,0.78))
  poly(canvas,pose,[Vector2(-0.318,-0.812),Vector2(-0.221,-0.823),Vector2(-0.207,-0.794),Vector2(-0.314,-0.766)],ceramic.lightened(0.16))
  poly(canvas,pose,[Vector2(-0.329,-0.763),Vector2(-0.278,-0.717),Vector2(-0.192,-0.721),Vector2(-0.206,-0.742),Vector2(-0.28,-0.745)],ceramic.darkened(0.30))
  stroke(canvas,pose,Vector2(-0.308,-0.762),Vector2(-0.213,-0.745),STEEL,0.012)
  stroke(canvas,pose,Vector2(-0.308,-0.789),Vector2(-0.292,-0.784),Color(ceramic.lightened(0.4),0.8),0.004)
  stroke(canvas,pose,Vector2(-0.244,-0.77),Vector2(-0.217,-0.766),Color(EDGE,0.6),0.005)
  for rivet in [Vector2(-0.307,-0.797),Vector2(-0.195,-0.777),Vector2(-0.273,-0.733)]:
   canvas.draw_circle(point(pose,rivet),float(pose["height"])*0.008,EDGE)
   canvas.draw_circle(point(pose,rivet)+Vector2(-0.3,-0.3),float(pose["height"])*0.003,BRASS)

  stroke(canvas,pose,Vector2(-0.275,-0.804),Vector2(-0.224,-0.79),CYAN,0.009)
  poly(canvas,pose,[Vector2(-0.17,-0.715),Vector2(-0.069,-0.687),Vector2(-0.063,-0.591),Vector2(-0.161,-0.577),Vector2(-0.215,-0.62)],Color(EDGE,0.60))
  poly(canvas,pose,[Vector2(-0.166,-0.7),Vector2(-0.082,-0.677),Vector2(-0.079,-0.604),Vector2(-0.157,-0.593),Vector2(-0.196,-0.627)],Color(ceramic.darkened(0.10),0.80))
  stroke(canvas,pose,Vector2(-0.165,-0.687),Vector2(-0.156,-0.612),ceramic.lightened(0.23),0.009)
  poly(canvas,pose,[Vector2(-0.196,-0.627),Vector2(-0.157,-0.593),Vector2(-0.079,-0.604),Vector2(-0.083,-0.621),Vector2(-0.151,-0.611)],ceramic.darkened(0.34))
  stroke(canvas,pose,Vector2(-0.183,-0.644),Vector2(-0.166,-0.64),Color(ceramic.lightened(0.3),0.7),0.004)
  for rivet in [Vector2(-0.166,-0.684),Vector2(-0.094,-0.615)]:
   canvas.draw_circle(point(pose,rivet),float(pose["height"])*0.007,EDGE)
   canvas.draw_circle(point(pose,rivet)+Vector2(-0.25,-0.25),float(pose["height"])*0.0025,ceramic.lightened(0.4))
  for i in range(int(state["armor"])):
   var y=-0.669+i*0.024
   stroke(canvas,pose,Vector2(-0.141,y),Vector2(-0.1,y+0.005),CYAN,0.007)
  if int(state["armor"])>=2:
   poly(canvas,pose,[Vector2(-0.255,-0.631),Vector2(-0.205,-0.61),Vector2(-0.211,-0.562),Vector2(-0.266,-0.578)],ceramic.darkened(0.18))
 if state["thorns"]:
  for i in range(3):
   var x=-0.319+i*0.045
   poly(canvas,pose,[Vector2(x,-0.807),Vector2(x-0.023,-0.873+i*0.008),Vector2(x+0.033,-0.811)],ceramic.lightened(0.14))
 if int(state["weapon"])>0:
  # Visible weapon tuning follows actual permanent ranks or damage cards.
  poly(canvas,pose,[Vector2(0.135,-0.708),Vector2(0.283,-0.689),Vector2(0.28,-0.664),Vector2(0.132,-0.682)],EDGE)
  for i in range(2+int(state["weapon"])):
   var x=0.145+i*0.027
   stroke(canvas,pose,Vector2(x,-0.701+(x-0.145)*0.12),Vector2(x-0.003,-0.675+(x-0.145)*0.12),CYAN,0.011)
  stroke(canvas,pose,Vector2(0.144,-0.711),Vector2(0.27,-0.694),ceramic,0.008)
 if state["medic"]:
  poly(canvas,pose,[Vector2(-0.36,-0.72),Vector2(-0.315,-0.713),Vector2(-0.318,-0.665),Vector2(-0.364,-0.675)],EDGE)
  stroke(canvas,pose,Vector2(-0.35,-0.693),Vector2(-0.327,-0.69),Color("9ce6b9"),0.009)
  stroke(canvas,pose,Vector2(-0.339,-0.706),Vector2(-0.34,-0.679),Color("9ce6b9"),0.009)
 if state["drone"]:
  poly(canvas,pose,[Vector2(-0.385,-0.765),Vector2(-0.348,-0.75),Vector2(-0.353,-0.713),Vector2(-0.391,-0.724)],STEEL)
  stroke(canvas,pose,Vector2(-0.38,-0.745),Vector2(-0.361,-0.738),CYAN,0.018)
 if state["shield"]:
  stroke(canvas,pose,Vector2(-0.276,-0.684),Vector2(-0.229,-0.674),CYAN,0.016)
 if state["overdrive"]:
  var pulse=0.7 if pose["reduced"] else 0.7+sin(float(pose["clock"])*7.0)*0.2
  stroke(canvas,pose,Vector2(-0.297,-0.733),Vector2(-0.271,-0.71),Color("ffca80",pulse),0.022)
  stroke(canvas,pose,Vector2(0.15,-0.695),Vector2(0.272,-0.68),Color("ffca80",pulse),0.013)
 var upgrade_signal=game.get("gear_flash")
 if upgrade_signal!=null and float(upgrade_signal)>0 and not bool(pose["reduced"]):
  var signal_color=Color(CYAN,minf(0.65,float(upgrade_signal)*0.5))
  if int(state["armor"])>0:stroke(canvas,pose,Vector2(-0.32,-0.81),Vector2(-0.22,-0.823),signal_color,0.018)
  if int(state["belt"])>0:stroke(canvas,pose,Vector2(-0.31,-0.544),Vector2(0.015,-0.512),signal_color,0.016)
  if int(state["weapon"])>0:stroke(canvas,pose,Vector2(0.145,-0.709),Vector2(0.276,-0.694),signal_color,0.014)
 canvas.draw_set_transform(Vector2.ZERO)
