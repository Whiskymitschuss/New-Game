class_name SpecialAmmo
extends RefCounted
# Refined charges are a bounded subset of the ordinary reserve, never extra ammo.
# Three kind buckets keep first-arrival priority without one object per unit.
const KINDS := ["fire","frost","emp"]
const MAX_PER_DROP := 12
const MAX_RESERVE := 36
const FIRE_SECONDS := 2.0
const FROST_SECONDS := 1.5
const EMP_SECONDS := 0.35
const EMP_BOSS_SECONDS := 0.12
const EMP_COOLDOWN := 1.2
var reserve: Dictionary = {"fire":0,"frost":0,"emp":0}
var order: Array[String] = []
var drop_remaining := MAX_PER_DROP

func reset() -> void:
 for kind in KINDS:reserve[kind]=0
 order.clear()
 drop_remaining=MAX_PER_DROP

func begin_drop() -> void:
 drop_remaining=MAX_PER_DROP

func count(kind: String) -> int:
 return maxi(0,int(reserve.get(kind,0))) if kind in KINDS else 0

func total() -> int:
 return count("fire")+count("frost")+count("emp")

func summary() -> Dictionary:
 return {"fire":count("fire"),"frost":count("frost"),"emp":count("emp")}

func add_refined(kind: String,accepted: int) -> int:
 if not kind in KINDS or accepted<=0:return 0
 var refined=mini(accepted,mini(drop_remaining,maxi(0,MAX_RESERVE-total())))
 if refined<=0:return 0
 if count(kind)==0:order.append(kind)
 reserve[kind]=count(kind)+refined
 drop_remaining-=refined
 return refined

func reconcile(total_ammo: int) -> void:
 # Losses/old fixtures may change the authoritative ordinary reserve directly.
 # Preserve earlier groups and remove newest refined cargo first, never add it.
 var excess=maxi(0,total()-maxi(0,total_ammo))
 for i in range(order.size()-1,-1,-1):
  var kind=order[i]
  var remove=mini(count(kind),excess)
  reserve[kind]=count(kind)-remove
  excess-=remove
  if count(kind)==0:order.remove_at(i)

func peek() -> String:
 while not order.is_empty() and count(order[0])<=0:order.pop_front()
 return "normal" if order.is_empty() else order[0]

func consume() -> String:
 var kind=peek()
 if kind!="normal":
  reserve[kind]=count(kind)-1
  if count(kind)==0:order.pop_front()
 return kind

static func color(kind: String) -> Color:
 match kind:
  "fire":return Color("ffad68")
  "frost":return Color("8de5ff")
  "emp":return Color("b7a5ff")
 return Color("98c9b4")

static func display_name(kind: String) -> String:
 match kind:
  "fire":return "BRAND"
  "frost":return "KRYO"
  "emp":return "EMP"
 return "STANDARD"

static func apply_hit(game: Node,enemy: Dictionary,kind: String,base_damage: float) -> void:
 if game==null or String(game.get("mode"))!="play" or bool(enemy.get("dead",false)) or not kind in KINDS:return
 match kind:
  "fire":
   enemy["ammo_fire"]=FIRE_SECONDS
   var dps=clampf(maxf(0,base_damage)*0.08,1.0,6.0)
   enemy["ammo_fire_dps"]=maxf(float(enemy.get("ammo_fire_dps",0)),dps)
  "frost":enemy["ammo_frost"]=FROST_SECONDS
  "emp":
   if float(enemy.get("ammo_emp_cooldown",0))<=0:
    enemy["ammo_emp"]=EMP_BOSS_SECONDS if bool(enemy.get("boss",false)) else EMP_SECONDS
    enemy["ammo_emp_cooldown"]=EMP_COOLDOWN
   if int(enemy.get("type",0)) in [2,13] and base_damage>0:
    game.hit_enemy(enemy,base_damage*0.18,false)

static func speed_factor(enemy: Dictionary) -> float:
 if bool(enemy.get("dead",false)) or float(enemy.get("ammo_frost",0))<=0:return 1.0
 return 0.82 if bool(enemy.get("boss",false)) else 0.65

static func tick_enemy(game: Node,enemy: Dictionary,delta: float) -> bool:
 if game==null or bool(enemy.get("dead",false)):return false
 if String(game.get("mode"))!="play":return float(enemy.get("ammo_emp",0))>0
 var elapsed=maxf(0,delta)
 var fire=maxf(0,float(enemy.get("ammo_fire",0)))
 if fire>0:
  # A large frame may only burn for the portion before the effect expires.
  var active=minf(fire,elapsed)
  enemy["ammo_fire"]=maxf(0,fire-elapsed)
  if active>0:game.hit_enemy(enemy,maxf(0,float(enemy.get("ammo_fire_dps",0)))*active,false)
  if float(enemy["ammo_fire"])<=0:enemy["ammo_fire_dps"]=0.0
 for key in ["ammo_frost","ammo_emp","ammo_emp_cooldown"]:
  if enemy.has(key):enemy[key]=maxf(0,float(enemy[key])-elapsed)
 return not bool(enemy.get("dead",false)) and float(enemy.get("ammo_emp",0))>0

# Curved tongues share a small fixed vertex budget for both body and impacts.
static func flame_shape(at: Vector2,height: float,width: float,lean: float) -> PackedVector2Array:
 var points=PackedVector2Array()
 var start=Vector2(-width*0.5,0)
 var tip=Vector2(lean,-height)
 var shoulder=Vector2(width*0.49,-height*0.25)
 var end=Vector2(width*0.5,0)
 for i in range(6):
  points.append(at+start.bezier_interpolate(Vector2(-width*0.91,-height*0.31),Vector2(lean-width*0.38,-height*0.46),tip,float(i)/5))
 for i in range(1,6):
  points.append(at+tip.bezier_interpolate(Vector2(lean+width*0.09,-height*0.64),Vector2(width*0.91,-height*0.59),shoulder,float(i)/5))
 for i in range(1,5):
  points.append(at+shoulder.bezier_interpolate(Vector2(width*0.7,-height*0.13),Vector2(width*0.66,-height*0.03),end,float(i)/4))
 return points

# These body treatments are rendered by ElementalFx's clipped stage canvas.
# They read the actual status timers and never attach data to the live enemy.
static func paint(canvas: Node2D,enemy: Dictionary,clock: float,reduced: bool=false,quality: int=1) -> void:
 if bool(enemy.get("dead",false)):return
 var at=Vector2(float(enemy.get("x",400)),float(enemy.get("y",320)))
 var kind=clampi(int(enemy.get("type",0)),0,14)
 var body_height=160.0 if bool(enemy.get("boss",false)) else float([83,83,94,86,47,96,85,112,56,129,106,99,87,91,103][kind])
 var scale=clampf(body_height/85.0,0.7,1.65)
 var phase=0.0 if reduced else clock
 if float(enemy.get("ammo_fire",0))>0:
  # Tall, licked edges and a pale hot core remain recognizable behind blood and
  # muzzle flashes. The face is left readable above the flame envelope.
  var count=5 if quality==1 else 3
  for i in range(count):
   var spread=float(i)/maxf(1,float(count-1))*2-1
   var origin=at+Vector2(spread*21*scale,-4-(i%2)*12*scale)
   var height=(27+absf(spread)*12+sin(phase*7+i*2.2)*7)*scale
   var lean=sin(phase*5+i*1.7)*5*scale
   var width=(10 if quality==1 else 13)*scale
   canvas.draw_colored_polygon(flame_shape(origin,height,width*1.5,lean),Color("d94216",0.26))
   canvas.draw_colored_polygon(flame_shape(origin,height*0.9,width*1.08,lean*0.8),Color("ff8b28",0.65))
   canvas.draw_colored_polygon(flame_shape(origin-Vector2(0,1),height*0.55,width*0.57,lean*0.4),Color("ffeaa0",0.9))
  for i in range(6 if quality==1 else 3):
   var rise=0.45 if reduced else fposmod(phase*(0.48+i*0.035)+i*0.19,1)
   var ember=at+Vector2(sin(i*4.7+phase*1.7)*25*scale,-(12+rise*(body_height*0.85)))
   canvas.draw_line(ember,ember+Vector2(-1.5,4.5)*scale,Color("ffb15c",(1-rise)*0.85),1.4,true)
   canvas.draw_circle(ember,0.9*scale,Color("fff0bc",1-rise))
 if float(enemy.get("ammo_frost",0))>0:
  var tint=color("frost")
  # A faceted body rim, with brighter edges, communicates ice rather than a
  # blue recolor. Shard positions are stable even when reduced motion is used.
  var count=4 if quality==1 else 2
  for side in [-1,1]:
   for i in range(count):
    var p=at+Vector2(side*(16+i%2*5)*scale,-(8+i*body_height*0.18))
    var length=(9+i%2*4)*scale
    var tip=p+Vector2(side*4*scale,-length)
    var shard=PackedVector2Array([p+Vector2(-4,2)*scale,tip,p+Vector2(4,2)*scale])
    canvas.draw_colored_polygon(shard,Color(tint,0.55))
    canvas.draw_line(p,tip,Color("e9fcff",0.95),1.1,true)
  var center=at-Vector2(0,body_height*0.35)
  var diamond=PackedVector2Array([center+Vector2(-13,0)*scale,center+Vector2(-3,-17)*scale,center+Vector2(12,-6)*scale,center+Vector2(9,13)*scale,center+Vector2(-9,15)*scale])
  canvas.draw_colored_polygon(diamond,Color(tint,0.19))
  var vein=PackedVector2Array([center+Vector2(-12,-1)*scale,center+Vector2(-3,-4)*scale,center+Vector2(1,4)*scale,center+Vector2(10,8)*scale])
  canvas.draw_polyline(vein,Color("d7f6ff",0.8),1,true)
  for arm in range(3):
   var ray=Vector2.from_angle(arm*PI/3)*5*scale
   canvas.draw_line(center-ray,center+ray,Color("dff9ff",0.8),1.1,true)
 if float(enemy.get("ammo_emp",0))>0:
  var tint=color("emp")
  var offset=sin(phase*9)*2.5*scale
  for side in [-1,1]:
   var rail=PackedVector2Array([at+Vector2(side*17*scale,-7),at+Vector2(side*23*scale,-body_height*0.23),at+Vector2(side*12*scale+offset,-body_height*0.39),at+Vector2(side*24*scale,-body_height*0.57),at+Vector2(side*12*scale,-body_height*0.76)])
   canvas.draw_polyline(rail,Color(tint,0.22),5,true)
   canvas.draw_polyline(rail,Color("e8ddff",0.95),1.5,true)
  var center=at-Vector2(0,body_height*0.42)
  var cross=PackedVector2Array([center+Vector2(-24,-10)*scale,center+Vector2(-8,-6+offset)*scale,center+Vector2(-12,2)*scale,center+Vector2(5,-3)*scale,center+Vector2(10,10)*scale,center+Vector2(24,5)*scale])
  canvas.draw_polyline(cross,Color(tint,0.3),6,true)
  canvas.draw_polyline(cross,Color("e8ddff",0.98),1.5,true)
  canvas.draw_set_transform(at+Vector2(0,-6),0,Vector2(1,0.28))
  canvas.draw_arc(Vector2.ZERO,28*scale,0,TAU,30,Color(tint,0.8),1.6,true)
  canvas.draw_set_transform(Vector2.ZERO)
