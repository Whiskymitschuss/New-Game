class_name BloodFX
extends Node2D
# Visual snapshots only. Blood never changes damage, collision, enemy AI or game RNG.
const STAGE := Rect2(0,121,540,229)
const RED := Color("c62936")
const WET := Color("ef4a4c")
const DRY := Color("571923")
const OIL := Color("152a35")
const COOLANT := Color("70e0e6")
const PARTICLE_LIMIT = [48,128]
const STAIN_LIMIT = [16,36]
const BURST_LIMIT = [8,16]
class PaintLayer extends Node2D:
 var fx
 func _draw() -> void:fx.paint(self)
var game: Node2D
var particles: Array = []
var stains: Array = []
var bursts: Array = []
var visual_rng := RandomNumberGenerator.new()
var clock := 0.0
var clipper: Control
var painter: PaintLayer

func _ready() -> void:
 z_index=7
 visual_rng.seed=608274
 clipper=Control.new()
 clipper.position=STAGE.position;clipper.size=STAGE.size
 clipper.clip_contents=true;clipper.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(clipper)
 painter=PaintLayer.new();painter.fx=self;painter.position=-STAGE.position
 clipper.add_child(painter)

func quality() -> int:return 0 if game!=null and game.quality==0 else 1
func enabled() -> bool:
 return game!=null and bool(game.profile.data.get("settings",{}).get("blood_fx",true))
func running() -> bool:return enabled() and game.mode=="play"
func reduced_motion() -> bool:
 return game!=null and bool(game.profile.data.get("settings",{}).get("reduced_motion",false))
func reset() -> void:
 particles.clear();stains.clear();bursts.clear();clock=0
 if is_instance_valid(painter):painter.queue_redraw()

func jagged_shape(size: Vector2,rays: int=12) -> PackedVector2Array:
 var points=PackedVector2Array()
 for i in range(rays):
  var angle=TAU*float(i)/float(rays)
  var radius=visual_rng.randf_range(0.48,1.0) if i%2==0 else visual_rng.randf_range(0.22,0.62)
  points.append(Vector2(cos(angle)*size.x,sin(angle)*size.y)*radius)
 return points

func add_stain(at: Vector2,size: float,oil: bool=false,brief: bool=false) -> void:
 var where=Vector2(clampf(at.x,4,536),clampf(at.y,STAGE.position.y+2,348))
 # Nearby impacts build one pool instead of indefinitely layering draw calls.
 for stain in stains:
  if bool(stain["oil"])==oil and stain["at"].distance_to(where)<9:
   stain["age"]=minf(float(stain["age"]),0.3)
   return
 var limit=int(STAIN_LIMIT[quality()])
 while stains.size()>=limit:stains.pop_front()
 var shape=jagged_shape(Vector2(size,size*0.27),14 if quality()==1 else 10)
 var flecks=[]
 for i in range(4 if quality()==1 else 2):
  flecks.append(Vector2(visual_rng.randf_range(-size*1.4,size*1.4),visual_rng.randf_range(-size*0.35,size*0.35)))
 stains.append({"at":where,"shape":shape,"flecks":flecks,"oil":oil,"age":0.0,"life":1.2 if brief else (9.0 if oil else 12.0)})

func spray(at: Vector2,floor_y: float,direction: float,strength: float,oil: bool=false) -> void:
 if not running():return
 var q=quality()
 while bursts.size()>=int(BURST_LIMIT[q]):bursts.pop_front()
 var burst_shape=jagged_shape(Vector2(15*strength,11*strength),12)
 bursts.append({"at":at,"shape":burst_shape,"oil":oil,"age":0.0,"life":0.22 if oil else 0.19,"dir":direction})
 if reduced_motion():return
 var count=int((9 if q==1 else 4)*strength)
 for i in range(count):
  if particles.size()>=int(PARTICLE_LIMIT[q]):break
  var velocity=Vector2(direction*visual_rng.randf_range(35,165)*strength,visual_rng.randf_range(-110,12)*strength)
  particles.append({"at":at+Vector2(visual_rng.randf_range(-2,2),visual_rng.randf_range(-4,4)),"vel":velocity,"age":0.0,"life":visual_rng.randf_range(0.45,0.8),"floor":clampf(floor_y,STAGE.position.y+3,346),"oil":oil,"size":visual_rng.randf_range(1.3,2.8)*sqrt(strength)})

func on_hit(enemy: Dictionary,critical: bool=false) -> void:
 if not running():return
 var oil=int(enemy.get("type",0))==13
 var floor_y=float(enemy.get("y",320))
 var height=18.0 if int(enemy.get("type",0)) in [4,8] else (56.0 if bool(enemy.get("boss",false)) else 32.0)
 var at=Vector2(float(enemy.get("x",400)),floor_y-height)
 spray(at,floor_y,1.0,1.65 if critical else 1.0,oil)
 if reduced_motion():add_stain(at,7 if oil else 10,oil,true)

func on_death(enemy: Dictionary) -> void:
 if not running():return
 var oil=int(enemy.get("type",0))==13
 var at=Vector2(float(enemy.get("x",400)),float(enemy.get("y",320)))
 var boss=bool(enemy.get("boss",false))
 spray(at-Vector2(0,40 if boss else 24),at.y,1.0,2.0 if boss else 1.4,oil)
 add_stain(at+Vector2(8,1),24 if boss else 17,oil,reduced_motion())

func on_hero_hurt() -> void:
 if not running():return
 spray(Vector2(94,281),325,-1.0,0.8)
 if reduced_motion():add_stain(Vector2(94,281),8,false,true)

func _process(delta: float) -> void:
 if game==null:return
 if not enabled():
  visible=false
  if not particles.is_empty() or not stains.is_empty() or not bursts.is_empty():reset()
  return
 visible=game.mode=="play"
 if game.mode in ["pause","upgrade"]:return
 if game.mode!="play":return
 clock+=delta
 # Toggling sparse quality in a saved game cannot retain the larger budget.
 while particles.size()>int(PARTICLE_LIMIT[quality()]):particles.pop_front()
 while stains.size()>int(STAIN_LIMIT[quality()]):stains.pop_front()
 while bursts.size()>int(BURST_LIMIT[quality()]):bursts.pop_front()
 for array in [stains,bursts]:
  for i in range(array.size()-1,-1,-1):
   array[i]["age"]+=delta
   if float(array[i]["age"])>=float(array[i]["life"]):array.remove_at(i)
 for i in range(particles.size()-1,-1,-1):
  var p=particles[i]
  p["age"]+=delta
  p["vel"].y+=370*delta
  p["at"]+=p["vel"]*delta
  if p["at"].y>=p["floor"]:
   add_stain(Vector2(p["at"].x,p["floor"]),float(p["size"])*2.7,bool(p["oil"]))
   particles.remove_at(i)
  elif float(p["age"])>=float(p["life"]) or p["at"].x< -12 or p["at"].x>552:particles.remove_at(i)
 if is_instance_valid(painter):painter.queue_redraw()

func paint(canvas: Node2D) -> void:
 # Decals have irregular pools, distinct satellite droplets and tiny wet glints.
 for stain in stains:
  var t=float(stain["age"])/float(stain["life"])
  var alpha=minf(1.0,(1-t)*3.0)
  var oil=bool(stain["oil"])
  var color=OIL if oil else RED.lerp(DRY,clampf(t*1.8,0,1))
  canvas.draw_set_transform(stain["at"])
  canvas.draw_colored_polygon(stain["shape"],Color(color,alpha*0.9))
  for fleck in stain["flecks"]:
   canvas.draw_line(fleck-Vector2(1.6,0),fleck+Vector2(1.6,0),Color(color,alpha*0.85),1.4,true)
  canvas.draw_line(Vector2(-2,-0.7),Vector2(3,-0.7),Color(COOLANT if oil else WET,alpha*(0.42 if oil else 0.3)*(1-t)),0.8,true)
  canvas.draw_set_transform(Vector2.ZERO)
 for burst in bursts:
  var t=float(burst["age"])/float(burst["life"])
  var oil=bool(burst["oil"])
  var size=1.0 if reduced_motion() else 0.78+t*0.7
  var at: Vector2=burst["at"]
  canvas.draw_set_transform(at,0,Vector2(size*float(burst["dir"]),size))
  canvas.draw_colored_polygon(burst["shape"],Color(OIL if oil else RED,pow(1-t,1.25)*0.95))
  canvas.draw_set_transform(at+Vector2(float(burst["dir"])*3,-2),0,Vector2(size*0.43,size*0.45))
  canvas.draw_colored_polygon(burst["shape"],Color(COOLANT if oil else WET,pow(1-t,2)*0.7))
  canvas.draw_set_transform(Vector2.ZERO)
 for p in particles:
  var fade=minf(1.0,(1-float(p["age"])/float(p["life"]))*4)
  var oil=bool(p["oil"])
  var at: Vector2=p["at"];var vel: Vector2=p["vel"]
  var tail=vel.normalized()*minf(10,vel.length()*0.035)
  var color=COOLANT if oil and int(float(p["size"])*10)%3==0 else (OIL if oil else RED)
  canvas.draw_line(at-tail,at,Color(color,fade),float(p["size"]),true)
  var normal=Vector2(-vel.y,vel.x).normalized()*float(p["size"])*0.62
  canvas.draw_colored_polygon(PackedVector2Array([at+vel.normalized()*float(p["size"]),at+normal,at-tail,at-normal]),Color(color,fade))
