extends Node2D
# RF Worlds · original vector art, physics production and automatic combat.
const BG = Color("070c18")
const PANEL = Color("111d32")
const INK = Color("eef4ff")
const MUTED = Color("8a9dbb")
const LIME = Color("5af5c5")
const CORAL = Color("ff7286")
const CYAN = Color("55d8ff")
const MAX_BALLS = 128
var font = preload("res://assets/fonts/SpaceGrotesk.ttf")
var future: FutureArt
var profile = Profile.new()
var audio: GameAudio
var ui: CanvasLayer
var controls: Control
var geometry: Node2D
var pool: Array[AmmoBall] = []
var ball_visuals: BallVisuals
var pending_balls: Array = []
var drop_emit_timer := 0.0
const DROP_INTERVAL := 0.065
var rotors: Array = []
var obstacles: Array = []
var enemies: Array = []
var sparks: Array = []
var tracers: Array = []
var floats: Array = []
var mode = "menu"
var clock = 0.0
var level = 1
var layout: Dictionary = {}
var wave = 1
var wave_count = 5
var stats: Dictionary = {}
var hp = 120.0
var ammo: int = 40
var attempts = 5
var aim = 270.0
var fire_timer = 0.0
var spawn_timer = 0.0
var remaining = 0
var magazine = 12
var reload_timer = 0.0
var energy = 0.0
var shield = 0.0
var damage_flash = 0.0
var shoot_flash = 0.0
var hero_pose = "idle"
var run_coins = 0
var run_kills = 0
var collected: int = 0
var produced: int = 0
var dropped: int = 0
var status_text = ""
var wave_delay = 0.0
var cards: Array = []
var menu_page = 0
var rng = RandomNumberGenerator.new()
var drop_button: Button
var special_button: Button
var hud_label: Label
var dragging = false
var paused_from = "play"
var quality = 1
var boss_spawned = false
var drone_timer = 0.0
var auto_test = false
var styles: Dictionary = {}
var hero_dot = 0.0
var boss_slow = 0.0

func _ready() -> void:
 future=FutureArt.new(self)
 profile.load_game()
 rng.randomize()
 quality=int(profile.data["settings"]["quality"])
 audio=GameAudio.new()
 add_child(audio)
 audio.music_volume=float(profile.data["settings"]["music"])
 audio.effects_volume=float(profile.data["settings"]["sfx"])
 ui=CanvasLayer.new()
 add_child(ui)
 controls=Control.new()
 ui.add_child(controls)
 geometry=Node2D.new()
 add_child(geometry)
 for i in range(MAX_BALLS):
  var ball=AmmoBall.new()
  add_child(ball)
  pool.append(ball)
 ball_visuals=BallVisuals.new()
 ball_visuals.balls=pool
 add_child(ball_visuals)
 show_menu()
 if "--smoke" in OS.get_cmdline_user_args():
  auto_test=true
  start_level(1)

func clear_ui() -> void:
 for child in controls.get_children():
  controls.remove_child(child)
  child.queue_free()
 drop_button=null
 special_button=null
 hud_label=null

func label(text: String,at: Vector2,size: int=18,color: Color=INK,width: float=460,wrap: bool=false) -> Label:
 var item=Label.new()
 item.add_theme_font_override("font",font)
 item.add_theme_font_size_override("font_size",size)
 item.add_theme_color_override("font_color",color)
 if wrap:
  item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  item.clip_text=true
 item.text=text
 item.position=at
 item.size=Vector2(width,60)
 item.mouse_filter=Control.MOUSE_FILTER_IGNORE
 controls.add_child(item)
 return item

func button(text: String,rect: Rect2,callback: Callable,accent: bool=false) -> Button:
 var item=Button.new()
 item.text=text
 item.position=rect.position
 item.size=rect.size
 item.add_theme_font_override("font",font)
 item.add_theme_font_size_override("font_size",16)
 var normal=StyleBoxFlat.new()
 normal.bg_color=LIME if accent else PANEL
 normal.set_corner_radius_all(9)
 normal.content_margin_left=12
 normal.content_margin_right=12
 normal.border_color=Color("294261")
 normal.set_border_width_all(1)
 normal.shadow_color=Color(CYAN,0.08)
 normal.shadow_size=4 if accent else 0
 item.add_theme_stylebox_override("normal",normal)
 var hover=normal.duplicate()
 hover.bg_color=Color("a1ffe5") if accent else Color("223854")
 item.add_theme_stylebox_override("hover",hover)
 item.add_theme_stylebox_override("pressed",hover)
 var disabled=normal.duplicate()
 disabled.bg_color=Color("0c1727")
 disabled.border_color=Color("1d2e46")
 item.add_theme_stylebox_override("disabled",disabled)
 item.add_theme_color_override("font_disabled_color",Color("59708b"))
 item.add_theme_color_override("font_color",BG if accent else INK)
 item.add_theme_color_override("font_hover_color",BG if accent else LIME)
 item.add_theme_color_override("font_pressed_color",BG if accent else LIME)
 item.pressed.connect(func(): audio.play_effect("click"); callback.call())
 controls.add_child(item)
 return item

func show_menu() -> void:
 mode="menu"
 clear_balls()
 clear_geometry()
 enemies.clear()
 clear_ui()
 audio.play_music("menu")
 label("RF  /  WORLDS                 PROTOCOL 02",Vector2(32,26),11,CYAN)
 label("DEADWAVE",Vector2(28,77),55)
 label("HEROES",Vector2(28,133),73,INK)
 label("DEIN REAKTOR. DEINE MUNITION. DEIN ÜBERLEBEN.",Vector2(31,224),10,MUTED)
 label("01 / ERZEUGEN    →    02 / ÜBERLEBEN",Vector2(32,602),11,CYAN)
 var unlocked=int(profile.data["unlocked"])
 button("EINSATZ STARTEN  →  LEVEL %02d"%unlocked,Rect2(30,642,480,64),func(): start_level(unlocked),true)
 button("WELTKARTE",Rect2(30,722,232,55),show_map)
 button("HELD & ARSENAL",Rect2(278,722,232,55),show_armory)
 button("EINSTELLUNGEN",Rect2(30,793,480,48),show_settings)
 label("OFFLINE  •  KEINE WERBUNG  •  v0.2.1",Vector2(34,901),12,MUTED)

func page_header(title: String,subtitle: String) -> void:
 clear_ui()
 label("RF / WORLDS     •     DEADWAVE SYSTEMS",Vector2(28,26),11,CYAN)
 label(title,Vector2(28,70),32)
 label(subtitle,Vector2(30,122),13,MUTED)
 button("← ZURÜCK",Rect2(30,888,480,48),show_menu)

func show_map() -> void:
 mode="map"
 page_header("EINSATZGEBIETE","100 Einsätze · feste Seeds · 10 Bossbegegnungen")
 var world=menu_page
 label("%02d / %s"%[world+1,Content.WORLDS[world]],Vector2(30,177),22,CYAN)
 for i in range(10):
  var n=world*10+i+1
  var star_count=int(profile.data["stars"].get(str(n),0))
  var text="%02d%s\n%s"%[n,"  BOSS" if n%10==0 else "","★".repeat(star_count) if star_count>0 else "EINSATZ"]
  var item=button(text,Rect2(30+(i%2)*248,240+(i/2)*106,232,88),func(): start_level(n),n==int(profile.data["unlocked"]))
  item.disabled=n>int(profile.data["unlocked"])
 button("← WELT",Rect2(30,802,232,52),func(): menu_page=posmod(menu_page-1,10); show_map())
 button("WELT →",Rect2(278,802,232,52),func(): menu_page=(menu_page+1)%10; show_map())

func show_armory() -> void:
 mode="armory"
 page_header("HELD & ARSENAL","Level %d · %d XP · %d Münzen"%[profile.data["level"],profile.data["xp"],profile.data["coins"]])
 for i in range(3):
  var c=Content.CLASSES[i]
  var x=30+i*164
  var selected=int(profile.data["class"])==i
  var item=button("",Rect2(x,171,152,213),func(): profile.data["class"]=i; profile.save_game(); show_armory())
  var box=StyleBoxFlat.new()
  box.bg_color=Color("172d40") if selected else Color("111c31")
  box.border_color=CYAN if selected else Color("2c405a")
  box.set_border_width_all(2 if selected else 1)
  box.set_corner_radius_all(9)
  item.add_theme_stylebox_override("normal",box)
  var portrait=TextureRect.new()
  portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  var image=AtlasTexture.new()
  image.atlas=future.heroes
  image.region=future.frame_region("heroes",i,future.heroes,3,1)
  portrait.texture=image
  portrait.position=Vector2(x+13,190)
  portrait.size=Vector2(126,126)
  portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
  controls.add_child(portrait)
  var title=label(c["name"],Vector2(x+8,322),16,INK,136)
  title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  var detail=label(["PRÄZISION / SCHADEN","DROHNEN / ENERGIE","VITALITÄT / REGEN"][i],Vector2(x+7,350),8,CYAN if selected else MUTED,138)
  detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label("WAFFE AUSWÄHLEN",Vector2(30,405),13,CYAN)
 button("ATTRIBUTE →",Rect2(349,399,161,34),show_character)
 for i in range(12):
  var weapon=Content.WEAPONS[i]
  var rank=int(profile.data["weapon_levels"].get(str(i),0))
  var text=weapon[0]+" +%d"%rank if int(profile.data["unlocked"])>=weapon[7] else "Ab Level %d"%weapon[7]
  var item=button(text,Rect2(30+(i%2)*248,450+(i/2)*50,232,42),func(): profile.data["weapon"]=i; profile.save_game(); show_armory(),int(profile.data["weapon"])==i)
  item.add_theme_font_size_override("font_size",13)
  item.disabled=not weapon_available(i)
 var rank=int(profile.data["weapon_levels"].get(str(profile.data["weapon"]),0))
 var cost=60*(rank+1)
 label("%s · %s"%[Content.WEAPONS[int(profile.data["weapon"])][0],Content.RARITIES[mini(rank/3,5)]],Vector2(30,764),14,LIME)
 var buy=button("AUFWERTEN +10%%  /  %d MÜNZEN"%cost,Rect2(30,807,480,53),func():
  profile.data["coins"]-=cost
  profile.data["weapon_levels"][str(profile.data["weapon"])]=rank+1
  profile.save_game()
  audio.play_effect("upgrade")
  show_armory())
 buy.disabled=int(profile.data["coins"])<cost

func weapon_available(id: int) -> bool:
 var requirement=int(Content.WEAPONS[id][7])
 if int(profile.data["unlocked"])<requirement:
  return false
 return requirement%10!=0 or int(profile.data["stars"].get(str(requirement),0))>0

func show_character() -> void:
 mode="character"
 page_header("CHARAKTERPROFIL","Dauerhafte Entwicklung · drei unterschiedliche Klassen")
 var cls=Content.CLASSES[int(profile.data["class"])]
 var w=weapon()
 var rank=int(profile.data["weapon_levels"].get(str(profile.data["weapon"]),0))
 label(cls["name"].to_upper()+" / LEVEL %d"%int(profile.data["level"]),Vector2(30,188),24,LIME)
 var values=["Erfahrung|%d / %d"%[profile.data["xp"],int(profile.data["level"])*100],"Maximalleben|%d"%int(float(cls["hp"])+(int(profile.data["level"])-1)*4),"Angriffsschaden|%.1f"%(float(w[1])*float(cls["damage"])*(1+rank*0.1)),"Schüsse / Sekunde|%.2f"%(1.0/float(w[2])),"Kritische Chance|5%", "Kritischer Schaden|175%", "Rüstung|0 + Run-Upgrades", "Ausweichchance|0% + Run-Upgrades", "Regeneration|%.1f HP / s"%cls["regen"], "Munitionskapazität|5000", "Spezialenergie|100 / Impuls kostet 50", "Entdeckte Fähigkeiten|%d / %d"%[profile.data["abilities"].size(),Content.UPGRADES.size()]]
 for i in range(values.size()):
  var parts=values[i].split("|")
  label(parts[0],Vector2(30,260+i*43),14,MUTED)
  label(parts[1],Vector2(286,260+i*43),14,INK,230)
 button("← ZUM ARSENAL",Rect2(30,812,480,52),show_armory)

func show_settings() -> void:
 mode="settings"
 page_header("EINSTELLUNGEN","Lokaler Speicherstand mit Backup · vollständig offline")
 for i in range(2):
  var key="music" if i==0 else "sfx"
  label("MUSIK" if i==0 else "EFFEKTE",Vector2(30,230+i*130),16,CYAN)
  var slider=HSlider.new()
  slider.position=Vector2(30,290+i*130)
  slider.size=Vector2(480,40)
  slider.min_value=0
  slider.max_value=1
  slider.step=0.05
  slider.value=float(profile.data["settings"][key])
  slider.value_changed.connect(func(value):
   profile.data["settings"][key]=value
   audio.music_volume=float(profile.data["settings"]["music"])
   audio.effects_volume=float(profile.data["settings"]["sfx"])
   audio.play_music("menu")
   profile.save_game())
  future.style_slider(slider)
  controls.add_child(slider)
 button("QUALITÄT: "+("STANDARD" if quality==1 else "SPARSAM"),Rect2(30,560,480,60),func(): quality=1-quality; profile.data["settings"]["quality"]=quality; profile.save_game(); show_settings())
 button("OUTFIT: "+["PATROUILLE","NACHTWACHE","RETTUNG"][int(profile.data["outfit"])],Rect2(30,650,480,60),func(): profile.data["outfit"]=(int(profile.data["outfit"])+1)%3; profile.save_game(); show_settings())
 button("LIZENZEN & CREDITS",Rect2(30,815,480,48),show_licenses)
 label("Fortschritt: %d Siege · %d Abschüsse"%[profile.data["stats"]["wins"],profile.data["stats"]["kills"]],Vector2(30,756),16,MUTED)

func show_licenses() -> void:
 mode="licenses"
 page_header("CREDITS & LIZENZEN","RF Worlds · Originalcode, Grafik und synthetisiertes Audio")
 var scroll=ScrollContainer.new()
 scroll.position=Vector2(30,185)
 scroll.size=Vector2(480,670)
 controls.add_child(scroll)
 var copy=Label.new()
 copy.custom_minimum_size=Vector2(450,0)
 copy.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 copy.add_theme_font_override("font",font)
 copy.add_theme_font_size_override("font_size",12)
 copy.text="DEADWAVE HEROES / RF Worlds\nGodot 4.6.3 / DejaVu Sans\n\n"
 for path in ["res://assets/licenses/Godot-LICENSE.txt","res://assets/licenses/Godot-COPYRIGHT.txt","res://assets/licenses/DejaVu.txt","res://assets/licenses/SpaceGrotesk.txt","res://assets/licenses/JetBrainsMono.txt"]:
  copy.text+=FileAccess.get_file_as_string(path)+"\n\n"
 scroll.add_child(copy)

func start_level(number: int) -> void:
 level=clampi(number,1,100)
 layout=profile.get_level(level)
 profile.save_game()
 rng.seed=int(layout["seed"])+int(profile.data["stats"]["wins"])*31
 var cls=Content.CLASSES[int(profile.data["class"])]
 stats={"max_hp":float(cls["hp"])+float(profile.data["level"]-1)*4,"damage":float(cls["damage"]),"speed":1.0,"crit":0.05,"crit_damage":1.75,"armor":0.0,"dodge":0.0,"regen":float(cls["regen"]),"capacity":5000.0,"pierce":0.0,"multishot":0.0,"poison":0.0,"burn":0.0,"drone":1.0 if int(profile.data["class"])==1 else 0.0,"slow":0.0,"recycle":0.0,"splash":0.0,"leech":0.0,"bounty":1.0,"wisdom":1.0,"drop":12.0,"collection":1.0,"reload":0.0,"magazine":0.0,"special":1.0,"energy_regen":4.0 if int(profile.data["class"])==1 else 2.0,"range":0.0,"thorns":0.0}
 hp=stats["max_hp"]
 ammo=int(cls["ammo"])
 shield=0
 hero_dot=0
 boss_slow=0
 energy=30
 attempts=5+level/10
 wave=1
 wave_count=int(layout["waves"])
 run_coins=0
 run_kills=0
 collected=0
 produced=0
 dropped=0
 sparks.clear()
 tracers.clear()
 floats.clear()
 clear_balls()
 enemies.clear()
 build_maze()
 mode="play"
 build_hud()
 begin_wave()
 audio.play_music("battle")
 status_text="Ziehen: Abwurfposition wählen. Dann ABWERFEN." if level<=3 else "Produziere Munition. Halte die Stellung."

func build_hud() -> void:
 clear_ui()
 button("Ⅱ",Rect2(467,27,43,39),pause_game)
 drop_button=button("ABWERFEN",Rect2(24,888,310,54),drop_ammo,true)
 special_button=button("IMPULS",Rect2(350,888,166,54),special_attack)
 var slider=HSlider.new()
 slider.position=Vector2(45,438)
 slider.size=Vector2(450,28)
 slider.min_value=50
 slider.max_value=490
 slider.value=aim
 slider.value_changed.connect(func(value): aim=value)
 future.style_slider(slider)
 controls.add_child(slider)

func clear_geometry() -> void:
 for child in geometry.get_children():
  geometry.remove_child(child)
  child.queue_free()
 rotors.clear()
 obstacles.clear()

func solid(at: Vector2,size: Vector2,angle: float=0.0,rotating: bool=false) -> Node2D:
 var body: PhysicsBody2D=AnimatableBody2D.new() if rotating else StaticBody2D.new()
 body.position=at
 body.rotation=angle
 var collider=CollisionShape2D.new()
 var shape=RectangleShape2D.new()
 shape.size=size
 collider.shape=shape
 body.add_child(collider)
 geometry.add_child(body)
 return body

func build_maze() -> void:
 clear_geometry()
 solid(Vector2(22,680),Vector2(16,405))
 solid(Vector2(518,680),Vector2(16,405))
 for item in layout["pieces"]:
  var x=float(item["x"])
  var y=float(item["y"])
  var variant=int(item["variant"])
  var kind=String(item["kind"])
  var ob={"kind":kind,"pos":Vector2(x,y),"variant":variant,"body":null,"broken":false}
  match kind:
   "ramp","wall","reverse","breakable":
    var angle=([0.4,-0.4,0.65][variant] if kind!="wall" else PI/2)
    ob["body"]=solid(Vector2(x,y),Vector2(65+variant*12,9),angle)
   "peg":
    var body=StaticBody2D.new()
    body.position=Vector2(x,y)
    var shape=CircleShape2D.new()
    shape.radius=10+variant*3
    var collider=CollisionShape2D.new()
    collider.shape=shape
    body.add_child(collider)
    geometry.add_child(body)
    ob["body"]=body
   "rotor","trapdoor":
    var body=solid(Vector2(x,y),Vector2(65+variant*12,8),0,true)
    ob["body"]=body
    rotors.append({"body":body,"kind":kind,"speed":0.6+variant*0.5})
  obstacles.append(ob)

func clear_balls() -> void:
 pending_balls.clear()
 drop_emit_timer=0
 for ball in pool:
  ball.deactivate()

func active_balls() -> int:
 var count=0
 for ball in pool:
  if ball.live:
   count+=1
 return count

func emit_ball(at: Vector2,velocity: Vector2,amount: int=1,mask: int=0) -> bool:
 var limit=MAX_BALLS if quality==1 else 64
 for i in range(limit):
  if not pool[i].live:
   pool[i].activate(at,velocity,amount,mask)
   return true
 return false

func drop_ammo() -> void:
 if mode!="play" or attempts<=0 or not pending_balls.is_empty():
  return
 var count=int(stats["drop"])
 if active_balls()+pending_balls.size()+count>(MAX_BALLS if quality==1 else 64):
  status_text="Kugeln unterwegs – gleich ist wieder Platz."
  return
 attempts-=1
 dropped+=count
 profile.data["stats"]["drops"]+=1
 for i in range(count):
  pending_balls.append({"at":Vector2(aim+rng.randf_range(-20,20),498),"velocity":Vector2(rng.randf_range(-48,48)+(aim-270)*0.16,rng.randf_range(8,25))})
 drop_emit_timer=0
 audio.play_effect("drop")
 status_text="Jede Kugel zählt. Multiplikatoren vervielfachen ihren Wert."

func emit_pending_balls(delta: float) -> void:
 if pending_balls.is_empty():
  return
 drop_emit_timer-=delta
 while drop_emit_timer<=0 and not pending_balls.is_empty():
  var next: Dictionary=pending_balls[0]
  if not emit_ball(next["at"],next["velocity"]):
   return # Preserve queued units when representative splits occupy the pool.
  pending_balls.pop_front()
  drop_emit_timer+=DROP_INTERVAL

func gate_split(row: int) -> float:
 return 270.0+sin(clock*1.3)*75 if bool(layout["gates"][row]["moving"]) else 270.0

func multiply_ball(ball: AmmoBall,row: int) -> void:
 var bit=1<<row
 if ball.gates & bit:
  return
 ball.gates |= bit
 var gate=layout["gates"][row]
 var factor=int(gate["left"] if ball.position.x<gate_split(row) else gate["right"])
 ball.weight*=factor
 ball.queue_redraw()
 # Split representative weights exactly, never instantiate factor-many bodies.
 if ball.weight>=4 and active_balls()<48 and quality==1:
  var portion=int(ball.weight/2)
  if emit_ball(ball.position+Vector2(8,8),ball.linear_velocity+Vector2(45,0),portion,ball.gates):
   ball.weight-=portion
 if floats.size()<16:
  floating("×%d"%factor,ball.position,LIME)
 audio.play_effect("multiply",0.9+row*0.15)

func collect_ball(ball: AmmoBall) -> void:
 var amount=ball.weight
 collected+=amount
 var credited=int(amount*float(stats["collection"]))
 var accepted=mini(credited,maxi(0,int(stats["capacity"])-ammo))
 ammo+=accepted
 produced+=accepted
 energy=minf(100,energy+0.15)
 ball.deactivate()
 if floats.size()<14:
  floating("+%s"%compact(amount),Vector2(rng.randf_range(80,460),850),CYAN)
 audio.play_effect("collect",rng.randf_range(0.85,1.2))

func physics_balls(delta: float) -> void:
 emit_pending_balls(delta)
 for rotor in rotors:
  if rotor["kind"]=="trapdoor":
   rotor["body"].rotation=sin(clock*rotor["speed"])*1.25
  else:
   rotor["body"].rotation+=delta*rotor["speed"]
 for ball in pool:
  if not ball.live or ball.reset_pending:
   continue
  ball.age+=delta
  for row in range(3):
   var y=float(layout["gates"][row]["y"])
   if ball.previous.y<y and ball.position.y>=y:
    multiply_ball(ball,row)
  for ob in obstacles:
   if ob["broken"]:
    continue
   var distance=ball.position.distance_to(ob["pos"])
   var variant=int(ob["variant"])
   match ob["kind"]:
    "portal":
     if distance<20 and not ball.portal_used:
      ball.teleport_to(Vector2(540-ob["pos"].x,ob["pos"].y+35),Vector2(30*(variant-1),180))
      ball.portal_used=true
    "boost":
     if distance<32:
      ball.apply_central_force(Vector2((variant-1)*400,1100))
    "bonus":
     if distance<23 and not ball.gates & (1<<5):
      ball.weight+=5*(variant+1)
      ball.gates |= 1<<5
    "reverse":
     if distance<40:
      ball.apply_central_force(Vector2((1 if variant%2==0 else -1)*600,-80))
    "breakable":
     if distance<40:
      ob["broken"]=true
      ob["body"].collision_layer=0
      burst(ob["pos"],CORAL,5)
  # Every represented unit eventually reaches collection, even if it rests on a peg.
  if ball.age>7:
   ball.collision_mask=0
   ball.apply_central_force(Vector2(0,900))
  if ball.position.y>=854 or ball.age>10:
   collect_ball(ball)
  elif ball.position.x<28 or ball.position.x>512:
   ball.teleport_to(Vector2(clampf(ball.position.x,30,510),ball.position.y),Vector2(-ball.linear_velocity.x*0.5,ball.linear_velocity.y))
  ball.previous=ball.position

func begin_wave() -> void:
 remaining=3+wave+level/5
 spawn_timer=0.8
 fire_timer=0
 magazine=int(weapon()[4])+int(stats["magazine"])
 reload_timer=0
 boss_spawned=false
 wave_delay=0
 status_text="Welle %d / %d"%[wave,wave_count]

func weapon() -> Array:
 return Content.WEAPONS[int(profile.data["weapon"])]

func spawn_enemy(boss: bool=false) -> Dictionary:
 var max_type=mini(14,1+(level-1)/6)
 var kind=rng.randi_range(0,max_type)
 if level>=80 and rng.randf()<0.4:
  kind=14
 var template=Content.ENEMIES[kind]
 var scaling=1.0+level*0.045+wave*0.075
 var health=float(template[1])*scaling
 var boss_id=int(layout["world"])
 if boss:
  kind=9
  template=Content.ENEMIES[kind]
  health=(450+boss_id*200)*(1+level*0.025)
 var e={"type":kind,"x":520.0,"y":rng.randf_range(283,335),"hp":health,"max_hp":health,"speed":float(template[2]),"damage":float(template[3])*(1+level*0.018),"reward":int(template[5]),"timer":1.0,"flash":0.0,"age":0.0,"poison":0.0,"burn":0.0,"slow":0.0,"boss":boss,"boss_id":boss_id,"telegraph":0.0,"phase":1,"dead":false}
 enemies.append(e)
 return e

func update_combat(delta: float) -> void:
 hp=minf(float(stats["max_hp"]),hp+float(stats["regen"])*delta)
 boss_slow=maxf(0,boss_slow-delta)
 if hero_dot>0:
  hero_dot=maxf(0,hero_dot-delta)
  hp-=2.5*delta
 energy=minf(100,energy+float(stats["energy_regen"])*delta)
 spawn_timer-=delta
 if remaining>0 and spawn_timer<=0 and enemies.size()<28:
  spawn_enemy()
  remaining-=1
  spawn_timer=maxf(0.35,1.6-level*0.008)
 if remaining==0 and wave==wave_count and bool(layout["boss"]) and not boss_spawned:
  spawn_enemy(true)
  boss_spawned=true
  audio.play_music("boss")
 for e in enemies:
  if e["dead"]:
   continue
  e["age"]+=delta
  e["timer"]-=delta
  e["flash"]=maxf(0,e["flash"]-delta)
  var dot=float(e["poison"])+float(e["burn"])
  if dot>0:
   hit_enemy(e,dot*delta,false)
  if e["dead"]:
   continue
  var speed=float(e["speed"])*(1-clampf(float(stats["slow"])+float(e["slow"]),0,0.75))
  if int(e["type"])==1:
   speed*=1.0+0.3*sin(e["age"]*5)
  var ranged=int(e["type"]) in [5,12,13] and level>=20
  var stop=330.0 if ranged else 120.0
  if e["x"]>stop:
   e["x"]-=speed*delta
  elif e["timer"]<=0 and not e["boss"]:
   hurt_hero(float(e["damage"]))
   if int(e["type"]) in [5,11]:
    hero_dot=4.0
   if int(e["type"])==10:
    boss_slow=3.0
   e["timer"]=1.25
   tracers.append({"from":Vector2(e["x"],e["y"]-25),"to":Vector2(94,310),"life":0.22,"color":CORAL})
   if float(stats["thorns"])>0:
    hit_enemy(e,float(stats["thorns"]))
   if int(e["type"])==6:
    hit_enemy(e,999999)
  if e["boss"]:
   update_boss(e,delta)
 for i in range(enemies.size()-1,-1,-1):
  if enemies[i]["dead"]:
   enemies.remove_at(i)
 fire_timer-=delta
 reload_timer-=delta
 if fire_timer<=0 and reload_timer<=0 and ammo>0:
  shoot()
 drone_timer-=delta
 if float(stats["drone"])>0 and drone_timer<=0 and not enemies.is_empty():
  hit_enemy(enemies[0],8*float(stats["drone"])*(1+level*0.03))
  tracers.append({"from":Vector2(122,242),"to":Vector2(enemies[0]["x"],enemies[0]["y"]-20),"life":0.15,"color":CYAN})
  drone_timer=0.8
 if hp<=0:
  finish_level(false)
 elif remaining==0 and enemies.is_empty():
  wave_delay+=delta
  if wave_delay>0.9:
   if wave>=wave_count:
    finish_level(true)
   else:
    choose_upgrade()
 elif ammo<=0 and attempts<=0 and active_balls()==0 and pending_balls.is_empty():
  status_text="Keine Munition. Halte mit IMPULS und Drohnen durch!"
  # Explicit surrender avoids a soft lock with regenerating/armored targets.

func update_boss(e: Dictionary,delta: float) -> void:
 e["phase"]=2 if e["hp"]<e["max_hp"]*0.5 else 1
 if e["telegraph"]>0:
  e["telegraph"]-=delta
  if e["telegraph"]<=0:
   var identity=int(e["boss_id"])
   hurt_hero((12+identity*2)*int(e["phase"]))
   burst(Vector2(95,315),CORAL,18)
   # Distinct world abilities; all share a visible two-second warning.
   match identity:
    0: shield=maxf(0,shield-8) # scrap slam shreds armor field
    1:
     if enemies.size()<25:
      spawn_enemy()
      spawn_enemy()
    2:
     for shot in range(3):
      hurt_hero(3+int(e["phase"]))
      tracers.append({"from":Vector2(e["x"],e["y"]-60-shot*10),"to":Vector2(95,300+shot*10),"life":0.4,"color":CORAL})
    3: ammo=maxi(0,ammo-15*int(e["phase"]))
    4:
     e["hp"]=minf(e["max_hp"],e["hp"]+e["max_hp"]*0.05)
     if enemies.size()<25:
      var minion=spawn_enemy()
      minion["type"]=13
    5:
     boss_slow=4.0
     for ob in obstacles:
      if ob["kind"]=="boost":
       ob["variant"]=2
    6:
     boss_slow=6.0
     fire_timer=maxf(fire_timer,1.5)
    7: hero_dot=8.0
    8:
     if enemies.size()<25:
      var clone=spawn_enemy()
      clone["type"]=7
      clone["hp"]*=2
      clone["max_hp"]=clone["hp"]
    9:
     energy=maxf(0,energy-20)
     hero_dot=4.0
     boss_slow=2.0
   e["timer"]=5.5 if e["phase"]==1 else 3.8
 elif e["timer"]<=0:
  e["telegraph"]=2.0
  status_text=Content.BOSS_ATTACKS[int(e["boss_id"])]+"! IMPULS schützt dich."
  audio.play_effect("warning")

func shoot() -> void:
 var w=weapon()
 var target: Dictionary={}
 for e in enemies:
  if not e["dead"] and float(e["x"])-95<=float(w[5])+float(stats["range"]):
   if target.is_empty() or float(e["x"])<float(target["x"]):
    target=e
 if target.is_empty():
  return
 if magazine<=0:
  reload_timer=float(w[3])*maxf(0.2,1-float(stats["reload"]))
  magazine=int(w[4])+int(stats["magazine"])
  status_text="NACHLADEN …"
  return
 var rank=int(profile.data["weapon_levels"].get(str(profile.data["weapon"]),0))
 var damage=float(w[1])*float(stats["damage"])*(1+rank*0.1)
 var critical=rng.randf()<minf(0.85,float(stats["crit"]))
 if critical:
  damage*=float(stats["crit_damage"])
 var effect=String(w[6])
 var hits=1+int(stats["pierce"])+(2 if effect in ["pierce","laser"] else 0)
 var extra=1+int(stats["multishot"])
 damage*=extra
 if rng.randf()>=minf(0.8,float(stats["recycle"])):
  ammo-=1
 magazine-=1
 fire_timer=float(w[2])/maxf(0.2,float(stats["speed"]))* (1.7 if boss_slow>0 else 1.0)
 shoot_flash=0.1
 hero_pose="attack"
 hit_enemy(target,damage,true,critical)
 target["poison"]=float(stats["poison"])
 target["burn"]=float(stats["burn"])+(8 if effect=="fire" else 0)
 var impact=Vector2(target["x"],target["y"]-28)
 tracers.append({"from":Vector2(146,263),"to":impact,"life":0.12 if effect!="laser" else 0.2,"color":CYAN if effect in ["laser","plasma"] else LIME})
 var count=1
 for e in enemies:
  if e==target or e["dead"]:
   continue
  if count<hits:
   hit_enemy(e,damage*0.7)
   count+=1
  elif absf(float(e["x"])-float(target["x"]))<85:
   var area=float(stats["splash"])+(damage*0.6 if effect in ["blast","spread","plasma","fire"] else 0)
   if area>0:
    hit_enemy(e,area)
 if effect in ["blast","plasma"]:
  burst(impact,CORAL,12)
 audio.play_effect("gun%d"%int(profile.data["weapon"]),rng.randf_range(0.94,1.06))

func hit_enemy(e: Dictionary,amount: float,visual: bool=true,critical: bool=false) -> void:
 if e["dead"]:
  return
 if int(e["type"]) in [2,13]:
  amount*=0.65
 if int(e["type"])==10:
  amount*=0.8
 e["hp"]-=amount
 if visual:
  e["flash"]=0.12
  burst(Vector2(e["x"],e["y"]-24),LIME,3)
  if floats.size()<20:
   floating(str(int(amount))+("!" if critical else ""),Vector2(e["x"],e["y"]-50),LIME if critical else INK)
 if e["hp"]<=0:
  e["dead"]=true
  run_kills+=1
  var coins=int(int(e["reward"])*float(stats["bounty"]))*(5 if e["boss"] else 1)
  run_coins+=coins
  profile.data["coins"]+=coins
  profile.data["stats"]["kills"]+=1
  profile.add_xp(int((6+level)*float(stats["wisdom"])))
  hp=minf(float(stats["max_hp"]),hp+float(stats["leech"]))
  energy=minf(100,energy+2)
  burst(Vector2(e["x"],e["y"]-15),Color("7f9a80"),8)
  audio.play_effect("zombie",rng.randf_range(0.8,1.25))
  if int(e["type"])==6 and float(e["x"])<185:
   hurt_hero(12)

func hurt_hero(amount: float) -> void:
 if rng.randf()<minf(0.65,float(stats["dodge"])):
  floating("AUSGEWICHEN",Vector2(60,255),CYAN)
  return
 var damage=maxf(1,amount-float(stats["armor"]))
 var absorbed=minf(shield,damage)
 shield-=absorbed
 hp-=damage-absorbed
 damage_flash=0.25
 hero_pose="hit"
 audio.play_effect("hit")

func special_attack() -> void:
 if mode!="play" or energy<50:
  return
 energy-=50
 shield+=28*float(stats["special"])
 for e in enemies:
  hit_enemy(e,55*float(stats["special"])*(1+level*0.025))
  e["slow"]=0.3
 burst(Vector2(95,300),CYAN,28)
 hero_pose="special"
 shoot_flash=0.35
 audio.play_effect("special")

func choose_upgrade() -> void:
 mode="upgrade"
 ball_visuals.hide()
 clear_ui()
 cards.clear()
 while cards.size()<3:
  var id=rng.randi_range(0,Content.UPGRADES.size()-1)
  var card=Content.UPGRADES[id]
  if card.size()>4 and int(card[4])!=int(profile.data["class"]):continue
  if not id in cards:cards.append(id)
 build_upgrade_picker()

func build_upgrade_picker() -> void:
 clear_ui()
 label("WELLE %02d GESICHERT   /   EVOLUTION BEREIT"%wave,Vector2(30,414),10,CYAN)
 label("Wähle deine Evolution.",Vector2(28,446),31,INK)
 label("Ein Upgrade. Neue Möglichkeiten. Kostenlos.",Vector2(30,492),13,MUTED)
 for i in range(3):
  var card=Content.UPGRADES[cards[i]]
  var x=24+i*168
  var tint=[CYAN,Color("ad8cff"),Color("ffc880")][i]
  var pick=button("",Rect2(x,544,156,261),func():
   apply_upgrade(cards[i])
   mode="play"
   wave+=1
   attempts+=2
   build_hud()
   begin_wave())
  var normal=StyleBoxFlat.new()
  normal.bg_color=Color("142039")
  normal.border_color=Color(tint,0.65)
  normal.set_border_width_all(1)
  normal.set_corner_radius_all(10)
  normal.shadow_color=Color(tint,0.08)
  normal.shadow_size=8
  pick.add_theme_stylebox_override("normal",normal)
  var hover=normal.duplicate()
  hover.bg_color=Color("203554")
  hover.border_color=tint
  pick.add_theme_stylebox_override("hover",hover)
  pick.add_theme_stylebox_override("pressed",hover)
  var index_label=label("MOD / %02d"%(i+1),Vector2(x+13,557),10,tint,130)
  var icon=TextureRect.new()
  icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  icon.texture=future.icons[future.icon_key(cards[i])]
  icon.position=Vector2(x+26,586)
  icon.size=Vector2(104,104)
  icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  icon.mouse_filter=Control.MOUSE_FILTER_IGNORE
  controls.add_child(icon)
  var title=label(card[0],Vector2(x+13,697),17,INK,130,true)
  title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  title.size=Vector2(130,51)
  title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  var description=label(card[1],Vector2(x+12,751),11,MUTED,132,true)
  description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
  description.size=Vector2(132,46)
  description.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 label("DEINE WAHL GILT FÜR DIESEN EINSATZ",Vector2(105,835),10,MUTED)
 audio.play_effect("upgrade")

func apply_upgrade(id: int) -> void:
 var c=Content.UPGRADES[id]
 var key=String(c[2])
 var value=float(c[3])
 match key:
  "max_hp":
   hp+=float(stats["max_hp"])*value
   stats["max_hp"]*=1+value
  "heal": hp=minf(float(stats["max_hp"]),hp+value)
  "ammo": ammo=mini(int(stats["capacity"]),ammo+int(value))
  "shield": shield+=value
  "energy": energy=minf(100,energy+value)
  "attempt": attempts+=int(value)
  "vitality": stats["max_hp"]+=value; hp+=value
  "salvage": ammo+=int(value); profile.data["coins"]+=int(value)
  "field": shield+=value; stats["regen"]+=0.5
  _: stats[key]+=value
 if not id in profile.data["abilities"]:
  profile.data["abilities"].append(id)

func finish_level(win: bool) -> void:
 mode="victory" if win else "defeat"
 ball_visuals.hide()
 hero_pose="victory" if win else "defeat"
 clear_ui()
 var stars=clampi(ceili(hp/float(stats["max_hp"])*3),1,3) if win else 0
 if win:
  profile.data["stars"][str(level)]=maxi(stars,int(profile.data["stars"].get(str(level),0)))
  profile.data["unlocked"]=maxi(int(profile.data["unlocked"]),mini(100,level+1))
  profile.data["stats"]["wins"]+=1
  profile.data["coins"]+=40+level*8
  profile.add_xp(40+level*5)
 profile.save_game()
 label("EINSATZ %02d / %s"%[level,Content.WORLDS[int(layout["world"])]],Vector2(30,420),13,CYAN)
 label("SEKTOR GESICHERT" if win else "SIGNAL VERLOREN",Vector2(30,465),32,LIME if win else CORAL)
 label("★ ".repeat(stars) if win else "Deine erbeuteten Münzen bleiben erhalten.",Vector2(30,526),30 if win else 15,INK)
 label("%d Abschüsse    ·    %d Münzen\n%s Munition produziert"%[run_kills,run_coins+(40+level*8 if win else 0),compact(produced)],Vector2(30,604),17,MUTED)
 button("WEITER →" if win and level<100 else "NOCH EINMAL",Rect2(30,741,480,62),func(): start_level(mini(100,level+1) if win else level),true)
 button("ZUM HAUPTMENÜ",Rect2(30,821,480,54),show_menu)
 audio.play_music("victory" if win else "defeat")

func pause_game() -> void:
 if mode!="play":
  return
 mode="pause"
 ball_visuals.hide()
 clear_ui()
 label("DURCHATMEN.",Vector2(30,422),38,LIME)
 label("Physik und Kampf pausieren vollständig.",Vector2(30,484),15,MUTED)
 button("WEITERSPIELEN",Rect2(30,574,480,65),func(): mode="play"; build_hud(),true)
 button("EINSATZ AUFGEBEN",Rect2(30,661,480,55),func(): finish_level(false))
 button("SPEICHERN & HAUPTMENÜ",Rect2(30,738,480,55),func(): profile.save_game(); show_menu())

func _notification(what: int) -> void:
 if what==NOTIFICATION_APPLICATION_PAUSED:
  profile.save_game()
  pause_game()
 if what==NOTIFICATION_WM_GO_BACK_REQUEST:
  if mode=="play":
   pause_game()
  elif mode=="pause":
   mode="play"
   build_hud()
  else:
   show_menu()

func _physics_process(delta: float) -> void:
 var running=mode=="play"
 for ball in pool:
  if ball.live:
   ball.freeze=not running
 if running:
  physics_balls(delta)
  update_combat(delta)
 if auto_test and clock>1.0 and attempts>0 and active_balls()==0 and mode=="play":
  drop_ammo()
 if auto_test and mode=="upgrade":
  apply_upgrade(cards[0])
  mode="play"
  wave+=1
  attempts+=2
  build_hud()
  begin_wave()

func _process(delta: float) -> void:
 if is_instance_valid(ball_visuals):
  ball_visuals.visible=mode=="play"
 if mode!="pause" and mode!="upgrade":
  clock+=delta
  damage_flash=maxf(0,damage_flash-delta)
  shoot_flash=maxf(0,shoot_flash-delta)
  for i in range(sparks.size()-1,-1,-1):
   sparks[i]["life"]-=delta
   sparks[i]["pos"]+=sparks[i]["vel"]*delta
   sparks[i]["vel"].y+=400*delta
   if sparks[i]["life"]<=0:
    sparks.remove_at(i)
  for i in range(tracers.size()-1,-1,-1):
   tracers[i]["life"]-=delta
   if tracers[i]["life"]<=0:
    tracers.remove_at(i)
  for i in range(floats.size()-1,-1,-1):
   floats[i]["life"]-=delta
   floats[i]["pos"].y-=28*delta
   if floats[i]["life"]<=0:
    floats.remove_at(i)
 if is_instance_valid(drop_button):
  drop_button.text="ABWURF LÄUFT …" if not pending_balls.is_empty() else "ABWERFEN  ·  %d ÜBRIG"%attempts
  drop_button.disabled=attempts<=0 or not pending_balls.is_empty()
 if is_instance_valid(special_button):
  special_button.text="IMPULS %d%%"%int(energy)
  special_button.disabled=energy<50
 queue_redraw()

func burst(at: Vector2,color: Color,count: int) -> void:
 for i in range(count if quality==1 else mini(count,4)):
  if sparks.size()>=180:
   return
  sparks.append({"pos":at,"vel":Vector2(rng.randf_range(-100,100),rng.randf_range(-130,30)),"life":rng.randf_range(0.15,0.5),"color":color})

func floating(text: String,at: Vector2,color: Color) -> void:
 if floats.size()<28:
  floats.append({"text":text,"pos":at,"life":0.9,"color":color})

func compact(number: int) -> String:
 if number>=1000000:
  return "%.1fM"%(number/1000000.0)
 if number>=10000:
  return "%.1fK"%(number/1000.0)
 return str(number)

# ---------- Original procedural illustration and interface ----------
func text_at(text: String,at: Vector2,size: int=16,color: Color=INK) -> void:
 draw_string(font,at,text,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func panel(rect: Rect2,color: Color=PANEL,radius: int=12) -> void:
 var key=color.to_html()+str(radius)
 if not styles.has(key):
  var style=StyleBoxFlat.new()
  style.bg_color=color
  style.set_corner_radius_all(radius)
  styles[key]=style
 draw_style_box(styles[key],rect)

func line(a: Vector2,b: Vector2,color: Color,width: float=2.0) -> void:
 draw_line(a,b,color,width,true)

func polygon(points: Array,color: Color) -> void:
 draw_colored_polygon(PackedVector2Array(points),color)

func bar(rect: Rect2,value: float,color: Color) -> void:
 panel(rect,Color("08111c"),4)
 if value>0:
  panel(Rect2(rect.position,Vector2(rect.size.x*clampf(value,0,1),rect.size.y)),color,4)

func backdrop(world: int,top: float=120.0,bottom: float=380.0) -> void:
 future.skyline(world,top,bottom)

func draw_hero(at: Vector2,scale_value: float=1.0,pose: String="idle") -> void:
 future.hero(at,scale_value,pose)

func draw_ellipse_shadow(at: Vector2,w: float,h: float) -> void:
 var points=PackedVector2Array()
 for i in range(24):
  points.append(at+Vector2(cos(i*TAU/24)*w,sin(i*TAU/24)*h))
 draw_colored_polygon(points,Color(0,0,0,0.25))

func draw_enemy(e: Dictionary) -> void:
 if future.enemy(e):
  return
 var kind=int(e["type"])
 var boss=bool(e["boss"])
 var size_value=1.0
 if kind in [7,9]:
  size_value=1.4 if kind==7 else 1.8
 if boss:
  size_value=2.2
 var pos=Vector2(e["x"],e["y"])
 var step=sin(float(e["age"])*7)
 draw_set_transform(pos,0,Vector2.ONE*size_value)
 var skin=[Color("83ad71"),Color("9bb877"),Color("6e9d8c"),Color("8ca17c"),Color("8c9575"),Color("a5b35a"),Color("d39a69"),Color("97a3ae"),Color("819b6a"),Color("859b7a"),Color("8edee4"),Color("ee9b69"),Color("8ab190"),Color("9ba9c0"),Color("be90ba")][kind]
 if float(e["flash"])>0:
  skin=Color.WHITE
 if boss:
  skin=Color(Content.COLORS[int(e["boss_id"])]).lightened(0.45)
 var cloth=Color("433f4d") if kind%2==0 else Color("586357")
 draw_ellipse_shadow(Vector2.ZERO,22,6)
 if kind in [4,8]:
  # Four-legged hound / grounded crawler have unique silhouettes.
  for i in range(4):
   line(Vector2(-18+i*11,-13),Vector2(-22+i*12+step*3,0),cloth,5)
  panel(Rect2(-26,-29,42,18),cloth,7)
  panel(Rect2(-33,-38,24,23),skin,5)
  polygon([Vector2(-30,-37),Vector2(-31,-52),Vector2(-19,-39)],skin)
  line(Vector2(-22,-27),Vector2(-39,-25),Color("e6d5ae"),4)
  draw_circle(Vector2(-28,-33),2,CORAL)
  if kind==8:
   line(Vector2(-15,-18),Vector2(-43+step*4,-6),skin,6)
 else:
  line(Vector2(-10,-20),Vector2(-13+step*3,0),cloth,9)
  line(Vector2(8,-20),Vector2(12-step*3,0),cloth,9)
  polygon([Vector2(-17,-47),Vector2(14,-45),Vector2(20,-18),Vector2(-21,-18)],cloth)
  line(Vector2(-12,-42),Vector2(-32+step*2,-34),skin,7)
  line(Vector2(9,-42),Vector2(-20,-28),skin.darkened(0.12),6)
  panel(Rect2(-19,-72+step,35,31),Color("10212a"),6)
  panel(Rect2(-16,-69+step,30,25),skin,5)
  polygon([Vector2(-19,-64+step),Vector2(-14,-77+step),Vector2(4,-74+step),Vector2(17,-67+step),Vector2(1,-68+step)],cloth.darkened(0.3))
  draw_rect(Rect2(-14,-60+step,7,4),LIME if kind!=11 else CORAL)
  draw_rect(Rect2(2,-60+step,6,4),LIME)
  line(Vector2(-11,-48+step),Vector2(7,-49+step),Color("1f3434"),3)
  if kind in [2,3,14]:
   panel(Rect2(-19,-49,37,26),Color("5b7382"),3)
   line(Vector2(-15,-45),Vector2(10,-25),Color("bdd0bf"),3)
   panel(Rect2(-21,-77+step,39,16),Color("41596a"),5)
  if kind in [5,6]:
   draw_circle(Vector2(0,-30),14,Color("a8bc51") if kind==5 else CORAL)
   for i in range(3):
    draw_circle(Vector2(-7+i*7,-32+i%2*6),3,Color("35483e"))
  if kind in [7,10,11,14]:
   for i in range(3):
    polygon([Vector2(12,-47+i*12),Vector2(27,-49+i*12),Vector2(15,-36+i*12)],skin.lightened(0.2))
  if kind in [3,12]:
   line(Vector2(-14,-34),Vector2(-40,-34),Color("0b1521"),6)
  if kind==13:
   panel(Rect2(-20,-70,39,31),Color("71889d"),2)
   draw_rect(Rect2(-16,-61,29,7),CORAL)
   line(Vector2(-20,-49),Vector2(-30,-63),CYAN,3)
 if boss:
  var identity=int(e["boss_id"])
  match identity:
   0:
    line(Vector2(-25,-35),Vector2(-39,-4),Color("738894"),10)
    draw_rect(Rect2(-51,-10,25,13),Color("99aab1"))
   1,8:
    for limb in range(3):
     draw_arc(Vector2(15,-20-limb*13),22,PI/2,-PI/2+sin(clock*2+limb)*0.5,12,skin,5)
   2:
    panel(Rect2(-24,-85,47,12),Color("425847"),3)
    line(Vector2(-25,-28),Vector2(-48,-35),CORAL,7)
   3:
    draw_arc(Vector2(-8,-38),21,0.2,TAU-0.2,24,Color("15202b"),9)
   4,9:
    draw_arc(Vector2(0,-37),40,-clock,4-clock,20,CYAN,3)
    draw_circle(Vector2(0,-30),10,CYAN)
   5:
    line(Vector2(-26,-64),Vector2(26,-64),Color("d9bc83"),11)
    line(Vector2(-20,-48),Vector2(20,-48),Color("d9bc83"),10)
   6:
    for spike in range(4):
     polygon([Vector2(-20+spike*12,-60),Vector2(-28+spike*12,-98),Vector2(-8+spike*12,-61)],CYAN)
   7:
    for flame in range(5):
     polygon([Vector2(-24+flame*10,-40),Vector2(-28+flame*10,-80-sin(clock*5+flame)*8),Vector2(-10+flame*10,-42)],CORAL)
  for i in range(3+identity%4):
   polygon([Vector2(-22+i*11,-65),Vector2(-27+i*11,-88-identity%3*5),Vector2(-12+i*11,-67)],CORAL if int(e["phase"])==2 else LIME)
  draw_arc(Vector2(0,-38),42,clock,clock+3.8,16,Color(CYAN,0.45),2)
 draw_set_transform(Vector2.ZERO)
 if boss:
  panel(Rect2(153,132,360,45),Color("14202c"),7)
  text_at(Content.BOSSES[int(e["boss_id"])]+" / PHASE %d"%int(e["phase"]),Vector2(163,151),12,CORAL)
  bar(Rect2(163,160,340,6),float(e["hp"])/float(e["max_hp"]),CORAL)
 else:
  bar(Rect2(pos.x-20*size_value,pos.y-83*size_value,40*size_value,4),float(e["hp"])/float(e["max_hp"]),LIME)
 if float(e["telegraph"])>0:
  draw_arc(Vector2(95,315),48,0,TAU,32,CORAL,3)
  text_at("⚠ IMPULS!",Vector2(170,228),18,CORAL)

func _draw() -> void:
 draw_rect(Rect2(0,0,540,960),BG)
 if future==null:return
 if mode=="menu":
  future.menu()
  return
 if mode in ["map","armory","settings","character","licenses"]:
  future.page_background()
  future.plate(Rect2(16,15,508,138),CYAN,Color(0.04,0.07,0.13,0.85),10)
  return
 if layout.is_empty():return
 backdrop(int(layout["world"]),121,380)
 draw_hero(Vector2(94,340),1.1,hero_pose)
 if float(stats.get("drone",0))>0:
  var p=Vector2(125,211+sin(clock*4)*4)
  draw_circle(p,14,Color(CYAN,0.08))
  future.plate(Rect2(p-Vector2(12,5),Vector2(24,12)),CYAN,Color("30455c"),3)
  draw_circle(p,3,CYAN)
  line(p+Vector2(-22,-9),p+Vector2(-7,-9),INK,1.5)
  line(p+Vector2(7,-9),p+Vector2(22,-9),INK,1.5)
 for e in enemies:draw_enemy(e)
 for t in tracers:
  line(t["from"],t["to"],Color(t["color"],clampf(t["life"]*3,0,0.25)),7)
  line(t["from"],t["to"],Color(t["color"],clampf(t["life"]*7,0,1)),2)
 future.hud()
 future.factory()
 future.text("INJECTION CONTROL",Vector2(26,432),9,CYAN,true)
 future.text("POSITION WÄHLEN  /  ABWERFEN",Vector2(278,432),9,MUTED,true)
 for particle in sparks:
  draw_circle(particle["pos"],3,Color(particle["color"],clampf(particle["life"]*0.9,0,0.3)))
  draw_circle(particle["pos"],1.4,Color(particle["color"],clampf(particle["life"]*3,0,1)))
 for f in floats:text_at(f["text"],f["pos"],14,Color(f["color"],minf(1,f["life"]*2)))
 if mode in ["upgrade","pause","victory","defeat"]:
  draw_rect(Rect2(0,387,540,573),Color(BG,0.98))
  future.plate(Rect2(16,398,508,474),CYAN,Color("0b1426"),12)
 if damage_flash>0:draw_rect(Rect2(0,0,540,960),Color(CORAL,damage_flash*0.25))
