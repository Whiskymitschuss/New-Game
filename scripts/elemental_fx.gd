class_name ElementalFx
extends Node2D
# Presentation of actual refined shots. No enemy dictionaries or gameplay RNG
# are retained, and nothing in this canvas can change damage or ammunition.
const STAGE := Rect2(0,121,540,229)
const HIGH_EVENTS := 14
const LOW_EVENTS := 8
const HIGH_PARTICLES := 72
const LOW_PARTICLES := 24
class PaintLayer extends Node2D:
 var fx
 func _draw() -> void:fx.paint(self)
var game: Node2D
var events: Array = []
var particles: Array = []
var visual_rng := RandomNumberGenerator.new()
var clock := 0.0
var shot_flash := 0.0
var last_kind := "normal"
var glow: GradientTexture2D
var clipper: Control
var painter: PaintLayer

func _ready() -> void:
 z_index=10
 visual_rng.seed=915208
 var ramp=Gradient.new()
 ramp.offsets=PackedFloat32Array([0,0.16,0.43,1])
 ramp.colors=PackedColorArray([Color(1,1,1,0.9),Color(1,1,1,0.42),Color(1,1,1,0.11),Color(1,1,1,0)])
 glow=GradientTexture2D.new()
 glow.gradient=ramp;glow.width=64;glow.height=64
 glow.fill=GradientTexture2D.FILL_RADIAL
 glow.fill_from=Vector2(0.5,0.5);glow.fill_to=Vector2(1,0.5)
 clipper=Control.new()
 clipper.position=STAGE.position;clipper.size=STAGE.size
 clipper.clip_contents=true;clipper.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(clipper)
 painter=PaintLayer.new();painter.fx=self;painter.position=-STAGE.position
 clipper.add_child(painter)

func running() -> bool:return is_instance_valid(game) and game.mode=="play"
func high_quality() -> bool:return not is_instance_valid(game) or game.quality==1
func reduced_motion() -> bool:
 return is_instance_valid(game) and bool(game.profile.data.get("settings",{}).get("reduced_motion",false))

func reset() -> void:
 events.clear();particles.clear();clock=0;shot_flash=0;last_kind="normal"
 if is_instance_valid(painter):painter.queue_redraw()

func on_shot(kind: String,from: Vector2,to: Vector2,enemy: Dictionary) -> void:
 if not running() or not kind in SpecialAmmo.KINDS or bool(enemy.get("dead",false)):return
 var limit=HIGH_EVENTS if high_quality() else LOW_EVENTS
 while events.size()>=limit:events.pop_front()
 var chain=PackedVector2Array()
 var direction=(to-from).normalized()
 var normal=direction.orthogonal()
 # A stored, irregular electrical path avoids frame-to-frame flashing noise.
 for i in range(9):
  var along=float(i)/8.0
  chain.append(from.lerp(to,along)+normal*(visual_rng.randf_range(-5,5) if i>0 and i<8 else 0.0))
 events.append({"kind":kind,"from":from,"at":to,"age":0.0,"life":0.48 if kind=="fire" else (0.54 if kind=="frost" else 0.4),"scale":1.3 if bool(enemy.get("boss",false)) else 1.0,"phase":visual_rng.randf_range(0,TAU),"chain":chain})
 last_kind=kind;shot_flash=1.0
 if reduced_motion():return
 var amount=(11 if kind=="fire" else (10 if kind=="frost" else 6)) if high_quality() else 4
 var particle_limit=HIGH_PARTICLES if high_quality() else LOW_PARTICLES
 for i in range(amount):
  if particles.size()>=particle_limit:break
  var angle=visual_rng.randf_range(-PI,PI)
  var speed=visual_rng.randf_range(32,112)
  var velocity=Vector2.from_angle(angle)*speed
  if kind=="fire":velocity.y-=55
  particles.append({"kind":kind,"at":to,"vel":velocity,"age":0.0,"life":visual_rng.randf_range(0.3,0.55),"angle":angle,"spin":visual_rng.randf_range(-3,3),"size":visual_rng.randf_range(2,4.5)})

func _process(delta: float) -> void:
 visible=running()
 if not running():return
 var elapsed=maxf(0,delta)
 clock+=elapsed;shot_flash=maxf(0,shot_flash-elapsed*4)
 var event_limit=HIGH_EVENTS if high_quality() else LOW_EVENTS
 var particle_limit=HIGH_PARTICLES if high_quality() else LOW_PARTICLES
 while events.size()>event_limit:events.pop_front()
 while particles.size()>particle_limit:particles.pop_front()
 for list in [events,particles]:
  for i in range(list.size()-1,-1,-1):
   list[i]["age"]+=elapsed
   if float(list[i]["age"])>=float(list[i]["life"]):list.remove_at(i)
 for particle in particles:
  particle["at"]+=particle["vel"]*elapsed
  particle["angle"]+=particle["spin"]*elapsed
  particle["vel"]*=maxf(0,1-elapsed*2)
  particle["vel"].y+=(-24 if particle["kind"]=="fire" else 65)*elapsed
 if is_instance_valid(painter):painter.queue_redraw()

func halo(canvas: Node2D,at: Vector2,size: Vector2,tint: Color,alpha: float) -> void:
 if glow!=null:canvas.draw_texture_rect(glow,Rect2(at-size*0.5,size),false,Color(tint,alpha))

func flame(canvas: Node2D,at: Vector2,height: float,width: float,lean: float,alpha: float) -> void:
 canvas.draw_colored_polygon(SpecialAmmo.flame_shape(at,height,width*1.4,lean),Color("e24818",alpha*0.5))
 canvas.draw_colored_polygon(SpecialAmmo.flame_shape(at,height*0.91,width,lean*0.8),Color("ff9d36",alpha))
 canvas.draw_colored_polygon(SpecialAmmo.flame_shape(at-Vector2(0,1),height*0.58,width*0.55,lean*0.4),Color("fff1a8",alpha*0.95))

func paint(canvas: Node2D) -> void:
 if glow==null or not is_instance_valid(game):return
 var reduced=reduced_motion()
 var rich_statuses=0
 for enemy in game.enemies:
  if bool(enemy.get("dead",false)):continue
  var active=false
  for key in ["ammo_fire","ammo_frost","ammo_emp"]:
   if float(enemy.get(key,0))>0:active=true;break
  if not active:continue
  # Detailed auras favor the nearest, oldest threats; every affected enemy still
  # receives its identifying body treatment, with a cheaper distant variant.
  var detail=1 if high_quality() and rich_statuses<8 else 0
  rich_statuses+=1
  var at=Vector2(float(enemy.get("x",400)),float(enemy.get("y",320))-30)
  if detail==1:
   if float(enemy.get("ammo_fire",0))>0:halo(canvas,at,Vector2(69,96),SpecialAmmo.color("fire"),0.23)
   elif float(enemy.get("ammo_frost",0))>0:halo(canvas,at,Vector2(69,83),SpecialAmmo.color("frost"),0.21)
   else:halo(canvas,at,Vector2(77,86),SpecialAmmo.color("emp"),0.24)
  SpecialAmmo.paint(canvas,enemy,clock,reduced,detail)
 for event in events:
  var kind=String(event["kind"])
  var tint=SpecialAmmo.color(kind)
  var age=float(event["age"])
  var t=age/float(event["life"])
  var fade=pow(1-t,1.5)
  var phase=float(event["phase"])
  var at: Vector2=event["at"]
  var from: Vector2=event["from"]
  var scale=float(event["scale"])
  var motion=0.12 if reduced else t
  var trail=clampf(1-age/0.16,0,1)
  var ray=(at-from).normalized()
  if trail>0:
   halo(canvas,from,Vector2(72,42),tint,trail*0.9)
   if kind=="emp":
    canvas.draw_polyline(event["chain"],Color(tint,trail*0.25),7,true)
    canvas.draw_polyline(event["chain"],Color(tint,trail),2.2,true)
    canvas.draw_polyline(event["chain"],Color("f1edff",trail*0.9),0.9,true)
   else:
    canvas.draw_line(from,at,Color(tint,trail*0.2),9 if kind=="fire" else 6,true)
    canvas.draw_line(from,at,Color(tint,trail*0.9),2.2,true)
    var head=at if reduced else from.lerp(at,clampf(age/0.085,0,1))
    halo(canvas,head,Vector2(50,25),tint,trail*0.85)
    canvas.draw_line(head-ray*(23 if kind=="fire" else 17),head,Color("fff4cf" if kind=="fire" else "effdff",trail),3,true)
    if kind=="fire":
     canvas.draw_colored_polygon(PackedVector2Array([head+Vector2(2,-4),head-ray*24,head+Vector2(2,4)]),Color(tint,trail*0.8))
  halo(canvas,at,Vector2(92,87)*scale,tint,fade*0.75)
  if kind=="fire":
   halo(canvas,at+Vector2(0,-11),Vector2(76,109)*scale,Color("ff6d27"),fade*0.5)
   for i in range(5 if high_quality() else 3):
    var x=(i-2)*9.0 if high_quality() else (i-1)*11.0
    var rise=(13+sin(phase+i*1.7)*4+motion*17)*scale
    flame(canvas,at+Vector2(x,motion*10),rise,(12-motion*5)*scale,sin(phase+i)*5,fade*0.8)
   canvas.draw_arc(at,8+motion*23,0.2,PI-0.2,20,Color("ffb65b",fade*0.75),2,true)
  elif kind=="frost":
   var radius=(12+motion*29)*scale
   canvas.draw_arc(at,radius,0,TAU,32,Color(tint,fade*0.65),1.6,true)
   canvas.draw_arc(at,radius+4,0,TAU,32,Color(tint,fade*0.14),5,true)
   for i in range(6):
    var direction=Vector2.from_angle(i*TAU/6+phase*0.15)
    var normal=direction.orthogonal()
    var tip=at+direction*radius
    var base=at+direction*radius*0.33
    canvas.draw_colored_polygon(PackedVector2Array([base-normal*3.4,tip,base+normal*3.4]),Color(tint,fade*0.72))
    canvas.draw_line(base,tip,Color("effdff",fade*0.9),1,true)
  else:
   var radius=(15+motion*29)*scale
   canvas.draw_arc(at,radius,phase,phase+TAU*0.78,30,Color(tint,fade*0.85),2.4,true)
   canvas.draw_arc(at,radius+5,phase+PI,phase+PI*2.6,24,Color("8ccaff",fade*0.45),1.2,true)
   for i in range(3):
    var direction=Vector2.from_angle(phase+i*TAU/3)
    var normal=direction.orthogonal()
    var branch=PackedVector2Array([at,at+direction*11+normal*5,at+direction*17-normal*4,at+direction*(radius+11)])
    canvas.draw_polyline(branch,Color(tint,fade*0.24),5,true)
    canvas.draw_polyline(branch,Color("e6dcff",fade*0.9),1.4,true)
 for particle in particles:
  var fade=pow(1-float(particle["age"])/float(particle["life"]),1.25)
  var at: Vector2=particle["at"]
  var tint=SpecialAmmo.color(String(particle["kind"]))
  if particle["kind"]=="frost":
   var direction=Vector2.from_angle(float(particle["angle"]))*float(particle["size"])
   var normal=direction.orthogonal()*0.4
   canvas.draw_colored_polygon(PackedVector2Array([at-direction,at+normal,at+direction,at-normal]),Color(tint,fade*0.95))
   canvas.draw_line(at-direction,at+direction,Color("effdff",fade),0.8,true)
  elif particle["kind"]=="fire":
   canvas.draw_line(at-particle["vel"]*0.035,at,Color("ff8d3d",fade),2,true)
   canvas.draw_circle(at,float(particle["size"])*0.36,Color("ffe69c",fade))
  else:
   canvas.draw_line(at-Vector2(3,0),at+Vector2(3,0),Color(tint,fade),1.3,true)
   canvas.draw_line(at-Vector2(0,3),at+Vector2(0,3),Color("ece4ff",fade),1.1,true)
