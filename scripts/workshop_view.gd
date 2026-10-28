class_name WorkshopView
extends RefCounted
# Menu-only fixtures show the exact permanent suit state without touching a run.
var g: Node2D
var feedback := ""
var feedback_error := false
const KEYS = ["belt","armor","weapon"]
const NAMES = ["Munitionsgürtel","Schutzpanzer","Waffenmodul"]
const CAPTIONS = ["Mehr Vorrat für jeden Einsatz","Schutz für alle drei Klassen","Zusatzschaden mit jeder Waffe"]
const ACCENTS = [Color("90d6cf"),Color("b1c8bc"),Color("d9aa70")]

class PreviewMotion extends RefCounted:
 var clock := 0.0
 func camera_offset() -> Vector2:return Vector2.ZERO

class PreviewActor extends Node2D:
 var profile=Profile.new()
 var stats: Dictionary={}
 var level := 1
 var mode := "workshop"
 var deployment_age := 1.0
 var shield := 0.0
 var overdrive_left := 0.0
 var gear_flash := 0.0
 var combat_motion=PreviewMotion.new()

class SuitPreview extends Node2D:
 var actor: PreviewActor
 var texture: Texture2D
 var source: Rect2
 var quality := 1
 func _process(delta: float) -> void:
  if actor==null:return
  if not bool(actor.profile.data.get("settings",{}).get("reduced_motion",false)):
   actor.combat_motion.clock+=delta
  queue_redraw()
 func _draw() -> void:
  if actor==null or texture==null:return
  # Technical floor beneath the body, rather than a floating portrait sticker.
  draw_line(Vector2(28,169),Vector2(194,169),Color("345353"),1,true)
  draw_line(Vector2(45,172),Vector2(180,172),Color(0.56,0.84,0.81,0.13),4,true)
  var base=Vector2(112,167)
  var reduced=bool(actor.profile.data.get("settings",{}).get("reduced_motion",false))
  var outfit=clampi(int(actor.profile.data.get("outfit",0)),0,2)
  var tint=[Color.WHITE,Color(0.72,0.9,1.12),Color(1.12,0.85,0.83)][outfit]
  ActorRig.draw_hero(self,texture,source,base,143.36,tint,actor.combat_motion.clock,-1,reduced,quality)
  HeroGear.draw(self,actor,base,1.28,{"offset":Vector2.ZERO,"angle":0.0,"scale":Vector2.ONE})

func _init(game: Node2D) -> void:g=game

func note(text: String,at: Vector2,size: int,color: Color,width: float,height: float=20) -> Label:
 var label=g.label(text,at,size,color,width,true)
 label.size=Vector2(width,height)
 return label

func surface(rect: Rect2,color: Color) -> void:
 var panel=Panel.new()
 panel.position=rect.position;panel.size=rect.size
 panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var skin=StyleBoxFlat.new()
 skin.bg_color=Color("0b1c20")
 skin.border_color=Color(color,0.27);skin.set_border_width_all(1)
 skin.set_corner_radius_all(9);skin.shadow_color=Color(0,0,0,0.35);skin.shadow_size=5
 panel.add_theme_stylebox_override("panel",skin)
 g.controls.add_child(panel)
 var rail=ColorRect.new()
 rail.position=rect.position+Vector2(0,18);rail.size=Vector2(2,rect.size.y-36)
 rail.color=Color(color,0.68);rail.mouse_filter=Control.MOUSE_FILTER_IGNORE
 g.controls.add_child(rail)

func icon(key: String,at: Vector2,tint: Color) -> void:
 var item=TextureRect.new()
 item.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 item.texture=load("res://assets/ui/"+key+".svg")
 item.position=at;item.size=Vector2(35,35)
 item.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 item.modulate=tint;item.mouse_filter=Control.MOUSE_FILTER_IGNORE
 g.controls.add_child(item)

func permanent_preview() -> Dictionary:
 var actor=PreviewActor.new()
 actor.profile.data=g.profile.data.duplicate(true)
 actor.level=clampi(int(actor.profile.data.get("unlocked",1)),1,100)
 var class_id=clampi(int(actor.profile.data.get("class",0)),0,2)
 actor.profile.data["class"]=class_id
 var cls=Content.CLASSES[class_id]
 actor.stats={"capacity":float(Content.ammo_capacity(actor.level)),"magazine":0.0,"drop":12.0,"armor":0.0,"thorns":0.0,"damage":float(cls["damage"]),"regen":float(cls["regen"]),"drone":1.0 if int(actor.profile.data["class"])==1 else 0.0}
 Workshop.apply_stats(actor.profile.data,actor.stats)
 var frame=Control.new()
 frame.position=Vector2(30,172);frame.size=Vector2(480,178)
 frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
 frame.set_meta("workshop_preview",true)
 var preview=SuitPreview.new()
 preview.actor=actor;preview.texture=g.future.heroes;preview.quality=int(g.quality)
 preview.source=g.future.frame_region("heroes",int(actor.profile.data["class"]),preview.texture,3,1)
 preview.add_child(actor)
 frame.add_child(preview)
 g.controls.add_child(frame)
 return actor.stats.duplicate(true)

func value_text(key: String,current: int) -> String:
 var next=mini(3,current+1)
 match key:
  "belt":return "+%d → +%d Munition"%[current*40,next*40] if current<3 else "+120 Munition"
  "armor":return "%d → %d Rüstung"%[current,next] if current<3 else "+3 Rüstung"
  _:return "+%d%% → +%d%% Schaden"%[current*5,next*5] if current<3 else "+15% Schaden"

func buy(key: String,expected_rank: int) -> void:
 if not is_instance_valid(g) or g.mode!="workshop":return
 var before=g.profile.data.duplicate(true)
 if not Workshop.buy(g.profile.data,key,expected_rank):
  feedback="Ausbau nicht verfügbar. Voraussetzungen und Credits prüfen."
  feedback_error=true
  build()
  return
 if not g.profile.save_game():
  g.profile.data=before
  feedback="Speichern fehlgeschlagen. Credits und Ausbaustufe zurückgesetzt."
  feedback_error=true
  build()
  return
 feedback="%s · STUFE %d DAUERHAFT GESPEICHERT"%[NAMES[KEYS.find(key)].to_upper(),Workshop.rank(g.profile.data,key)]
 feedback_error=false
 g.audio.play_effect("upgrade")
 build()

func build() -> void:
 g.mode="workshop"
 g.page_header("DEINE WERKBANK","Dauerhafte Ausrüstung · %s CR verfügbar"%g.compact(int(g.profile.data["coins"])))
 surface(Rect2(30,169,480,181),Color("90d6cf"))
 var stats=permanent_preview()
 note("DAUERHAFT AKTIV",Vector2(248,188),10,g.CYAN,246)
 note(Content.CLASSES[clampi(int(g.profile.data.get("class",0)),0,2)]["name"],Vector2(247,213),21,g.INK,245,28)
 note("%d MUNITION"%int(stats["capacity"]),Vector2(249,249),11,g.MUTED,240)
 note("%d RÜSTUNG · +%d%% MODULSCHADEN"%[int(stats["armor"]),Workshop.rank(g.profile.data,"weapon")*5],Vector2(249,272),10,g.MUTED,240,30)
 note("Gilt auch nach dem nächsten Einsatz.",Vector2(249,316),10,g.CYAN,240,22)
 for i in range(KEYS.size()):
  var key=String(KEYS[i]);var y=370+i*154
  var current=Workshop.rank(g.profile.data,key)
  var can_buy=Workshop.available(g.profile.data,key)
  var cost=Workshop.next_cost(g.profile.data,key)
  var affordable=int(g.profile.data["coins"])>=cost
  var color=ACCENTS[i]
  surface(Rect2(30,y,480,142),color)
  note(NAMES[i],Vector2(44,y+12),18,g.INK,302,28)
  note("STUFE %d / 3"%current,Vector2(382,y+16),10,color,115)
  icon(["ammo","shield","damage"][i],Vector2(44,y+54),color)
  note(value_text(key,current),Vector2(91,y+52),15,color,250,25)
  note(CAPTIONS[i],Vector2(91,y+81),10,g.MUTED,250,22)
  var title="MAXIMALSTUFE" if current>=3 else ("AUSBAU\n%s CR"%g.compact(cost) if can_buy else "GESPERRT\n%s CR"%g.compact(cost))
  var button=g.button(title,Rect2(354,y+56,144,54),func():buy(key,current),can_buy and affordable and current<3)
  button.add_theme_font_size_override("font_size",12)
  button.disabled=current>=3 or not can_buy or not affordable
  button.set_meta("workshop_key",key)
  button.set_meta("workshop_track",key)
  button.set_meta("workshop_rank",current)
  button.tooltip_text=Workshop.requirement(g.profile.data,key)
  var requirement="VOLLSTÄNDIG AUSGEBAUT" if current>=3 else ("FREIGESCHALTET · DAUERHAFTER AUSBAU" if can_buy else Workshop.requirement(g.profile.data,key))
  if can_buy and not affordable:requirement="NOCH %s CR · FREIGESCHALTET"%g.compact(maxi(0,cost-int(g.profile.data["coins"])))
  note(requirement,Vector2(44,y+116),10,g.MUTED if can_buy else FutureArt.AMBER,452,19)
 var message=note(feedback if not feedback.is_empty() else "Einmal ausbauen. In jedem Einsatz nutzen.",Vector2(32,843),11,FutureArt.AMBER if feedback_error else g.CYAN,476,35)
 message.set_meta("workshop_feedback",true)
 if g.has_method("reveal_ui"):g.reveal_ui(165)
