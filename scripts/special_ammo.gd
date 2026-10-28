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

static func paint(canvas: Node2D,enemy: Dictionary,clock: float,reduced: bool=false,quality: int=1) -> void:
 if bool(enemy.get("dead",false)):return
 var at=Vector2(float(enemy.get("x",400)),float(enemy.get("y",320)))
 var phase=0.0 if reduced else clock
 if float(enemy.get("ammo_fire",0))>0:
  var tint=color("fire")
  for i in range(3 if quality==1 else 2):
   var p=at+Vector2(-12+i*11,-17-absf(sin(phase*4+i))*3)
   var height=8+maxf(0,sin(phase*5+i*1.9))*5
   var flame=PackedVector2Array([p+Vector2(-3,2),p+Vector2(-2,-4),p+Vector2(1,-height),p+Vector2(4,-2),p+Vector2(3,2)])
   canvas.draw_colored_polygon(flame,Color(tint,0.62))
   canvas.draw_line(p,p-Vector2(0,4),Color("ffe0a3"),1.2,true)
 if float(enemy.get("ammo_frost",0))>0:
  var tint=color("frost")
  for i in range(3 if quality==1 else 2):
   var p=at+Vector2(-16+i*14,-8)
   canvas.draw_colored_polygon(PackedVector2Array([p+Vector2(-3,0),p+Vector2(0,-10-i%2*3),p+Vector2(4,0)]),Color(tint,0.48))
   canvas.draw_line(p+Vector2(0,-8),p+Vector2(0,-2),Color(tint,0.8),0.8,true)
 if float(enemy.get("ammo_emp",0))>0:
  var tint=color("emp")
  var offset=sin(phase*19)*2
  var arc=PackedVector2Array([at+Vector2(-21,-43),at+Vector2(-9,-39+offset),at+Vector2(-13,-31),at+Vector2(2,-35-offset),at+Vector2(9,-23),at+Vector2(21,-29)])
  canvas.draw_polyline(arc,Color(tint,0.18),4,true)
  canvas.draw_polyline(arc,Color(tint,0.9),1.2,true)
