class_name TimingStrike
extends Node2D
# Run-local skill reward and overflow sink. No per-virtual-ball objects or RNG.
const GOLD := Color("ffd68b")
const CHARGE_PER_OVERFLOW := 0.5
const PERFECT_CHARGE := 12.0
const WINDOW_HALF := 27.0
const STAGE := Rect2(0,121,540,229)
const WARNING := 0.45
const BEAM := 0.7
const COOLDOWN := 8.0
class StageLayer extends Node2D:
 var owner_fx
 func _draw() -> void:owner_fx.paint_stage(self)
var game: Node2D
var charge := 0.0
var target_clock := 0.0
var perfect_flash := 0.0
var perfect_count := 0
var cooldown := 0.0
var strike_age := -1.0
var detonated := false
var hit_points := PackedVector2Array()
var orbit_button: Button
var clipper: Control
var painter: StageLayer

func _ready() -> void:
 z_index=21
 clipper=Control.new();clipper.position=STAGE.position;clipper.size=STAGE.size
 clipper.clip_contents=true;clipper.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(clipper)
 painter=StageLayer.new();painter.owner_fx=self;painter.position=-STAGE.position
 clipper.add_child(painter)

func reset() -> void:
 charge=0;target_clock=0;perfect_flash=0;perfect_count=0;cooldown=0
 strike_age=-1;detonated=false;hit_points.clear()
 sync_button()
 queue_redraw()
 if is_instance_valid(painter):painter.queue_redraw()

func mount() -> void:
 orbit_button=game.button("ORBIT  0%",Rect2(378,355,138,55),activate)
 orbit_button.add_theme_font_size_override("font_size",12)
 orbit_button.tooltip_text="Überlauf: 2 Munition = 1% Orbit. Perfekte Kugel: +12%. Bei 100% trifft der Orbitalschlag sichtbare Gegner, Bosse höchstens für 12% Maximalleben. 8 Sekunden Abklingzeit."
 orbit_button.action_mode=BaseButton.ACTION_MODE_BUTTON_PRESS
 var ready_style=orbit_button.get_theme_stylebox("normal").duplicate()
 ready_style.border_color=GOLD;ready_style.bg_color=Color("30291d")
 orbit_button.add_theme_stylebox_override("hover",ready_style)
 orbit_button.add_theme_stylebox_override("pressed",ready_style)
 orbit_button.add_theme_color_override("font_color",GOLD)
 orbit_button.add_theme_color_override("font_hover_color",Color("fff0d4"))
 orbit_button.add_theme_color_override("font_pressed_color",Color("fff0d4"))
 sync_button()

func target_x() -> float:
 # A slower target creates readable intercepts with the fast automatic rail.
 return 270.0+sin(target_clock*0.9)*148.0

func in_window() -> bool:return absf(float(game.aim)-target_x())<=WINDOW_HALF
func busy() -> bool:return strike_age>=0
func visible_enemies() -> Array:
 var targets=[]
 for enemy in game.enemies:
  if not bool(enemy.get("dead",false)) and float(enemy["x"])>=115 and float(enemy["x"])<=535:targets.append(enemy)
 return targets
func can_activate() -> bool:
 return game.mode=="play" and charge>=100 and cooldown<=0 and not busy() and not visible_enemies().is_empty()

func capture_drop() -> bool:
 if game.mode!="play" or not in_window():return false
 perfect_flash=1;perfect_count+=1
 game.power_message="PERFEKT · GOLDKUGEL · +12% ORBIT BEIM SAMMELN"
 game.power_message_left=2.5
 game.reactor_fx.pulse(Vector2(game.aim,480),GOLD,"perfect",1.6)
 game.audio.play_effect("multiply",1.15)
 return true

func add_overflow(amount: int) -> void:
 if game.mode!="play" or amount<=0:return
 charge=minf(100,charge+amount*CHARGE_PER_OVERFLOW)
 sync_button()

func collect_perfect(ball: AmmoBall) -> void:
 if game.mode!="play" or not ball.live or not ball.perfect_ticket:return
 # Only the original representative owns this ticket; splits inherit the
 # physical trait, never a second reward. Consume before any presentation hook.
 ball.perfect_ticket=false
 charge=minf(100,charge+PERFECT_CHARGE)
 game.floating("+12% ORBIT",Vector2(clampf(ball.position.x,85,440),829),GOLD)
 game.reactor_fx.pulse(Vector2(clampf(ball.position.x,38,502),852),GOLD,"perfect",1.5)
 sync_button()

func activate() -> void:
 if not can_activate():return
 charge=0;cooldown=COOLDOWN;strike_age=0;detonated=false;hit_points.clear()
 game.audio.play_effect("special",0.7)
 sync_button()

func detonate() -> void:
 if detonated:return
 detonated=true
 var damage=(45.0+float(game.level)*2.5)*float(game.stats["special"])
 for enemy in visible_enemies():
  hit_points.append(Vector2(float(enemy["x"]),float(enemy["y"])-25))
  var amount=minf(damage,float(enemy["max_hp"])*0.12) if bool(enemy.get("boss",false)) else damage
  game.hit_enemy(enemy,amount)
 game.combat_motion.on_special()
 game.audio.play_effect("special",0.85)

func sync_button() -> void:
 if not is_instance_valid(orbit_button):return
 orbit_button.text="ORBIT · FEUERN" if can_activate() else ("ORBIT · %ds"%ceili(cooldown) if cooldown>0 else "ORBIT  %02d%%"%floori(charge))
 if busy():orbit_button.text="ORBIT · AKTIV"
 elif charge>=100 and visible_enemies().is_empty() and cooldown<=0:orbit_button.text="ORBIT · ZIEL FEHLT"
 orbit_button.disabled=not can_activate()

func update(delta: float) -> void:
 if game.mode!="play":return
 var dt=maxf(0,delta)
 if game.pending_balls.is_empty():target_clock+=dt
 perfect_flash=maxf(0,perfect_flash-dt*1.6)
 cooldown=maxf(0,cooldown-dt)
 if busy():
  strike_age+=dt
  if strike_age>=WARNING:detonate()
  if strike_age>=WARNING+BEAM:strike_age=-1;hit_points.clear()
 sync_button()

func _process(_delta: float) -> void:
 visible=game.mode=="play"
 if not visible:return
 sync_button()
 queue_redraw();painter.queue_redraw()

func reduced_motion() -> bool:return bool(game.profile.data["settings"].get("reduced_motion",false))

func _draw() -> void:
 if game.mode!="play":return
 var x=target_x();var hit=in_window()
 var color=GOLD if hit else Color("9f9071")
 # Brackets, a short gold rail and a moving nozzle remain readable at native
 # phone resolution. This foreground drawing does not intercept touch input.
 draw_line(Vector2(x-WINDOW_HALF,452),Vector2(x+WINDOW_HALF,452),Color(GOLD,0.15),13,true)
 draw_line(Vector2(x-WINDOW_HALF,452),Vector2(x+WINDOW_HALF,452),Color(color,0.85),2.5,true)
 for side in [-1,1]:
  var edge=x+side*WINDOW_HALF
  draw_polyline(PackedVector2Array([Vector2(edge-side*6,441),Vector2(edge,441),Vector2(edge,463),Vector2(edge-side*6,463)]),color,1.5,true)
 if absf(game.aim-x)>56:
  draw_string(game.font,Vector2(x-20,470),"PERFEKT",HORIZONTAL_ALIGNMENT_LEFT,-1,9,color)
 if perfect_flash>0:
  draw_arc(Vector2(game.aim,480),29+(0 if reduced_motion() else (1-perfect_flash)*24),PI*1.1,PI*2.9,32,Color(GOLD,perfect_flash*0.8),2,true)

func paint_stage(canvas: Node2D) -> void:
 if not busy() or game.mode!="play":return
 var reduced=reduced_motion()
 if strike_age<WARNING:
  var alpha=0.45+strike_age/WARNING*0.45
  for enemy in visible_enemies():
   var at=Vector2(float(enemy["x"]),float(enemy["y"])-25)
   canvas.draw_arc(at,22,0,TAU,28,Color(GOLD,alpha),1.5,true)
   for side in [-1,1]:canvas.draw_line(at+Vector2(side*27,0),at+Vector2(side*16,0),Color(GOLD,alpha),2,true)
  canvas.draw_string(game.font,Vector2(218,231),"ORBITAL · ZIEL ERFASST",HORIZONTAL_ALIGNMENT_LEFT,-1,12,GOLD)
  return
 var t=clampf((strike_age-WARNING)/BEAM,0,1)
 var fade=pow(1-t,1.4)
 for at in hit_points:
  var end=Vector2(at.x,339)
  var top=Vector2(at.x-35,121)
  # Layered column, hot core and ground shock ring; deliberately no fullscreen
  # white flash. Low quality and reduced motion use fewer restrained layers.
  canvas.draw_line(top,end,Color(GOLD,fade*(0.12 if reduced else 0.22)),12 if reduced else 26,true)
  canvas.draw_line(top,end,Color("ffb45f",fade*0.85),5 if reduced else 8,true)
  canvas.draw_line(top,end,Color("fff1cc",fade),2.2,true)
  var spread=12+(6 if reduced else t*44)
  var ring=PackedVector2Array()
  for i in range(25):
   var a=TAU*i/24
   ring.append(end+Vector2(cos(a)*spread,sin(a)*spread*0.3))
  canvas.draw_polyline(ring,Color(GOLD,fade*0.8),2,true)
  if game.quality==1 and not reduced:
   for i in range(4):
    var origin=at+Vector2((i-1.5)*9,0)
    var spark=origin+Vector2((i-1.5)*t*24,-t*(32+i*9))
    canvas.draw_line(spark-Vector2(0,5),spark,Color("ffe2a1",fade),1.4,true)
