class_name CombatMotion
extends Node2D
# Presentation only: no combat values, enemy positions, physics clocks or gameplay RNG.
# A clipped child canvas keeps impacts and shockwaves out of the HUD and factory.
const STAGE := Rect2(0,121,540,229)
const CYAN := Color("6ee8ff")
const GOLD := Color("ffcd83")
const PINK := Color("ff7996")
const ENEMY_ATLAS = [0,1,2,2,3,4,4,4,0,4,4,4,2,5,2]
const ENEMY_HEIGHT = [83,83,94,86,47,96,85,112,56,129,106,99,87,91,103]
const BOSS_ATLAS = [2,4,2,4,5,2,4,4,4,5]
class PaintLayer extends Node2D:
 var fx
 func _draw() -> void:fx.paint(self)
var game: Node2D
var events: Array = []
var particles: Array = []
var corpses: Array = []
var visual_rng := RandomNumberGenerator.new()
var clock := 0.0
var recoil := 0.0
var hurt := 0.0
var special := 0.0
var trauma := 0.0
var shot_hold := 0.0
var glow: GradientTexture2D
var clipper: Control
var painter: PaintLayer

func _ready() -> void:
 z_index=8
 visual_rng.seed=723049
 var ramp=Gradient.new()
 ramp.offsets=PackedFloat32Array([0,0.15,0.46,1])
 ramp.colors=PackedColorArray([Color(1,1,1,0.8),Color(1,1,1,0.3),Color(1,1,1,0.06),Color(1,1,1,0)])
 glow=GradientTexture2D.new()
 glow.gradient=ramp;glow.width=64;glow.height=64
 glow.fill=GradientTexture2D.FILL_RADIAL
 glow.fill_from=Vector2(0.5,0.5);glow.fill_to=Vector2(1,0.5)
 clipper=Control.new()
 clipper.position=STAGE.position;clipper.size=STAGE.size
 clipper.clip_contents=true
 clipper.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(clipper)
 painter=PaintLayer.new();painter.fx=self;painter.position=-STAGE.position
 clipper.add_child(painter)

func reset() -> void:
 events.clear();particles.clear();corpses.clear()
 recoil=0;hurt=0;special=0;trauma=0;shot_hold=0
 if is_instance_valid(painter):painter.queue_redraw()

func high_quality() -> bool:return game==null or game.quality==1
func running() -> bool:return game!=null and game.mode=="play"
func reduced_motion() -> bool:
 return game!=null and bool(game.profile.data.get("settings",{}).get("reduced_motion",false))
func add_event(kind: String,at: Vector2,color: Color,strength: float=1.0) -> void:
 if not running():return
 # One visible impact per nearby group, instead of white noise over a crowd.
 for event in events:
  if event["kind"]==kind and event["at"].distance_to(at)<15 and event["age"]<0.045:
   event["strength"]=minf(1.6,float(event["strength"])+0.12)
   return
 var limit=20 if high_quality() else 10
 while events.size()>=limit:events.pop_front()
 events.append({"kind":kind,"at":at,"color":color,"strength":strength,"age":0.0,"life":0.22 if kind=="muzzle" else 0.34})

func add_particle(at: Vector2,velocity: Vector2,color: Color,kind: String="spark") -> void:
 if reduced_motion():return
 var limit=90 if high_quality() else 32
 if particles.size()>=limit:return
 particles.append({"at":at,"vel":velocity,"color":color,"kind":kind,"life":0.62 if kind=="shell" else 0.34,"age":0.0,"angle":visual_rng.randf_range(-PI,PI),"spin":visual_rng.randf_range(-9,9),"bounced":false})

func on_shot(target_at: Vector2,weapon_id: int,critical: bool=false) -> void:
 if not running():return
 var id=clampi(weapon_id,0,11)
 var color=CYAN if id>=10 else GOLD
 recoil=minf(1.4,recoil+0.8+(0.3 if id in [1,4,6,8,9] else 0.0))
 trauma=maxf(trauma,0.24 if id in [4,8,9] else 0.08)
 if critical:shot_hold=0.035
 add_event("muzzle",Vector2(146,263),color,1.25 if critical else 1.0)
 if id<=6:
  add_particle(Vector2(126,266),Vector2(visual_rng.randf_range(-72,-34),visual_rng.randf_range(-112,-70)),GOLD,"shell")
 else:
  for i in range(2 if high_quality() else 1):
   add_particle(Vector2(148,263),Vector2(visual_rng.randf_range(35,100),visual_rng.randf_range(-22,22)),color)
 if id in [8,9,11]:add_event("blast",target_at,color,1.2)

func on_hit(at: Vector2,critical: bool=false) -> void:
 if not running():return
 add_event("hit",at,GOLD if critical else CYAN,1.35 if critical else 0.85)
 for i in range((7 if critical else 3) if high_quality() else 2):
  var angle=visual_rng.randf_range(-PI,PI)
  add_particle(at,Vector2.from_angle(angle)*visual_rng.randf_range(45,145),GOLD if critical else CYAN)
 if critical:trauma=maxf(trauma,0.28)

func on_death(enemy_snapshot: Dictionary) -> void:
 if not running():return
 var limit=12 if high_quality() else 5
 while corpses.size()>=limit:corpses.pop_front()
 var kind=clampi(int(enemy_snapshot.get("type",0)),0,14)
 var boss=bool(enemy_snapshot.get("boss",false))
 var atlas=BOSS_ATLAS[clampi(int(enemy_snapshot.get("boss_id",0)),0,9)] if boss else ENEMY_ATLAS[kind]
 var height=160.0 if boss else float(ENEMY_HEIGHT[kind])
 # Snapshot only the values needed by presentation; never retain/mutate the AI dict.
 corpses.append({"at":Vector2(float(enemy_snapshot.get("x",400)),float(enemy_snapshot.get("y",320))),"atlas":atlas,"height":height,"age":0.0,"life":0.58,"tilt":visual_rng.randf_range(0.26,0.52)})
 var at=Vector2(float(enemy_snapshot.get("x",400)),float(enemy_snapshot.get("y",320))-height*0.35)
 add_event("death",at,Color("70d8b7"),1.3 if boss else 0.8)
 for i in range(5 if high_quality() else 2):
  add_particle(at,Vector2(visual_rng.randf_range(-65,100),visual_rng.randf_range(-85,25)),Color("80cfa6"))

func on_special() -> void:
 if not running():return
 special=1.0;trauma=1.0
 add_event("special",Vector2(94,304),CYAN,1.5)

func on_hurt() -> void:
 if not running():return
 hurt=1.0;trauma=maxf(trauma,0.6)
 add_event("hurt",Vector2(94,289),PINK,0.8)

func hero_pose() -> Dictionary:
 if reduced_motion():return {"offset":Vector2.ZERO,"angle":0.0,"scale":Vector2.ONE}
 var breathe=sin(clock*3.2)
 var kick=recoil*recoil
 return {"offset":Vector2(-5.5*kick+hurt*2,-breathe*1.2-special*3),"angle":-0.035*kick+0.065*hurt,"scale":Vector2(1+0.026*kick+0.008*breathe,1-0.025*kick-0.009*breathe)}

func enemy_pose(enemy: Dictionary) -> Dictionary:
 if reduced_motion():return {"offset":Vector2.ZERO,"angle":0.0,"scale":Vector2.ONE}
 var age=float(enemy.get("age",0))
 var speed=float(enemy.get("speed",17))
 var step=sin(age*(7+minf(5,speed*0.08)))
 var flash=clampf(float(enemy.get("flash",0))/0.12,0,1)
 var boss=bool(enemy.get("boss",false))
 var stride=0.55 if boss else 1.0
 return {"offset":Vector2(step*0.7+flash*5,-absf(step)*2.7*stride),"angle":step*0.045*stride+flash*0.075,"scale":Vector2(1+absf(step)*0.018+flash*0.065,1-absf(step)*0.028-flash*0.05)}

func camera_offset() -> Vector2:
 if reduced_motion():return Vector2.ZERO
 return Vector2(sin(clock*73),cos(clock*89)*0.6)*trauma*1.5

func _process(delta: float) -> void:
 if game==null:return
 visible=running()
 if game.mode in ["pause","upgrade"]:return
 clock+=delta
 if shot_hold>0:shot_hold=maxf(0,shot_hold-delta)
 else:recoil=maxf(0,recoil-delta*7)
 hurt=maxf(0,hurt-delta*6)
 special=maxf(0,special-delta*1.7)
 trauma=maxf(0,trauma-delta*4)
 for array in [events,corpses,particles]:
  for i in range(array.size()-1,-1,-1):
   array[i]["age"]+=delta
   if array[i]["age"]>=array[i]["life"]:array.remove_at(i)
 for particle in particles:
  particle["at"]+=particle["vel"]*delta
  particle["angle"]+=particle["spin"]*delta
  if particle["kind"]=="shell":
   particle["vel"].y+=440*delta
   if particle["at"].y>=344 and not particle["bounced"]:
    particle["at"].y=344;particle["vel"].y=-absf(particle["vel"].y)*0.28
    particle["vel"].x*=0.7;particle["bounced"]=true
  else:particle["vel"]*=maxf(0,1-delta*3)
 if is_instance_valid(painter):painter.queue_redraw()

func halo(canvas: Node2D,at: Vector2,size: Vector2,color: Color,alpha: float) -> void:
 canvas.draw_texture_rect(glow,Rect2(at-size*0.5,size),false,Color(color,alpha))

func paint(canvas: Node2D) -> void:
 if glow==null or game==null:return
 var art=game.future
 for corpse in corpses:
  if art==null or art.enemies==null:continue
  var t=float(corpse["age"])/float(corpse["life"])
  var source: Rect2=art.frame_region("enemies",int(corpse["atlas"]),art.enemies,3,2)
  var height=float(corpse["height"])
  var width=height*source.size.x/maxf(1,source.size.y)
  var p: Vector2=corpse["at"]+Vector2.ZERO if reduced_motion() else corpse["at"]+Vector2(t*19,t*t*22)
  canvas.draw_set_transform(p,0.0 if reduced_motion() else float(corpse["tilt"])*t,Vector2.ONE if reduced_motion() else Vector2(1+t*0.09,1-t*0.55))
  canvas.draw_texture_rect_region(art.enemies,Rect2(-width*0.5,-height,width,height),source,Color(0.72,0.83,0.87,pow(1-t,1.5)))
  canvas.draw_set_transform(Vector2.ZERO)
 for event in events:
  var t=float(event["age"])/float(event["life"])
  var fade=pow(1-t,2)
  var at: Vector2=event["at"]
  var color: Color=event["color"]
  var strength=float(event["strength"])
  var kind=String(event["kind"])
  halo(canvas,at,Vector2(66,66)*strength,color,fade*0.5)
  if kind=="muzzle":
   halo(canvas,at,Vector2(86,14)*strength,color,fade*0.65)
   canvas.draw_line(at-Vector2(5,0),at+Vector2(21*strength,0),Color(1,0.98,0.87,fade),2.3,true)
   canvas.draw_line(at-Vector2(0,9)*strength,at+Vector2(0,9)*strength,Color(color,fade),1.5,true)
  elif kind=="special":
   canvas.draw_set_transform(at,0,Vector2(1,0.55))
   var ring_t=0.04 if reduced_motion() else t
   canvas.draw_arc(Vector2.ZERO,20+ring_t*390,-0.8,TAU-0.8,64,Color(CYAN,fade*0.7),4.0*(1-t)+1,true)
   canvas.draw_arc(Vector2.ZERO,10+ring_t*330,-0.8,TAU-0.8,64,Color(CYAN,fade*0.25),10,true)
   canvas.draw_set_transform(Vector2.ZERO)
  else:
   var local_t=0.0 if reduced_motion() else t
   var radius=(5+local_t*(45 if kind=="blast" else 21))*strength
   canvas.draw_arc(at,radius,0,TAU,24,Color(color,fade*0.65),1.4,true)
   for arm in range(4):
    var direction=Vector2.from_angle(PI*0.25+arm*PI*0.5)
    canvas.draw_line(at+direction*(3+local_t*7),at+direction*(10+local_t*23)*strength,Color(color,fade),1.8,true)
 for particle in particles:
  var fade=1-float(particle["age"])/float(particle["life"])
  if particle["kind"]=="shell":
   canvas.draw_set_transform(particle["at"],particle["angle"])
   canvas.draw_line(Vector2(-2.6,0),Vector2(2.6,0),Color(particle["color"],fade),2.1,true)
   canvas.draw_line(Vector2(-2,0),Vector2(1.7,0),Color(1,0.95,0.75,fade),0.7,true)
   canvas.draw_set_transform(Vector2.ZERO)
  else:
   canvas.draw_line(particle["at"]-particle["vel"]*0.025,particle["at"],Color(particle["color"],fade*0.85),1.5,true)
