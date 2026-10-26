extends Node2D
# RF Worlds · original vector art, physics production and automatic combat.
const BG = Color("091320")
const PANEL = Color("142536")
const INK = Color("e8f1ef")
const MUTED = Color("8ba3b3")
const LIME = Color("c9fc60")
const CORAL = Color("ff795f")
const CYAN = Color("66dbe6")
const MAX_BALLS = 128
var font = preload("res://assets/fonts/Interface.ttf")
var profile = Profile.new()
var audio: GameAudio
var ui: CanvasLayer
var controls: Control
var geometry: Node2D
var pool: Array[AmmoBall] = []
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

func label(text: String,at: Vector2,size: int=18,color: Color=INK,width: float=460) -> Label:
 var item=Label.new()
 item.text=text
 item.position=at
 item.size=Vector2(width,60)
 item.add_theme_font_override("font",font)
 item.add_theme_font_size_override("font_size",size)
 item.add_theme_color_override("font_color",color)
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
 normal.set_corner_radius_all(14)
 normal.content_margin_left=12
 normal.content_margin_right=12
 normal.border_color=Color("335064")
 normal.set_border_width_all(0 if accent else 1)
 item.add_theme_stylebox_override("normal",normal)
 var hover=normal.duplicate()
 hover.bg_color=Color("aee54b") if accent else Color("284254")
 item.add_theme_stylebox_override("hover",hover)
 item.add_theme_stylebox_override("pressed",hover)
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
 label("RF WORLDS  /  ORIGINAL GAMES",Vector2(32,30),12,LIME)
 label("DEADWAVE",Vector2(30,96),53)
 label("HEROES",Vector2(32,155),64,LIME)
 label("DIE HORDE KOMMT. DU LIEFERST DIE MUNITION.",Vector2(34,246),11,MUTED)
 label("01  /  PRODUZIEREN     02  /  ÜBERLEBEN",Vector2(34,592),12,CYAN)
 var unlocked=int(profile.data["unlocked"])
 button("EINSATZ STARTEN  →  LEVEL %02d"%unlocked,Rect2(30,642,480,64),func(): start_level(unlocked),true)
 button("WELTKARTE",Rect2(30,722,232,55),show_map)
 button("HELD & ARSENAL",Rect2(278,722,232,55),show_armory)
 button("EINSTELLUNGEN",Rect2(30,793,480,48),show_settings)
 label("OFFLINE  •  KEINE WERBUNG  •  v0.1.0",Vector2(34,901),12,MUTED)

func page_header(title: String,subtitle: String) -> void:
 clear_ui()
 label("RF WORLDS / DEADWAVE HEROES",Vector2(28,26),12,LIME)
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
  var item=button(("● " if int(profile.data["class"])==i else "")+c["name"]+"\n"+c["desc"],Rect2(30,173+i*74,480,62),func(): profile.data["class"]=i; profile.save_game(); show_armory(),int(profile.data["class"])==i)
  item.add_theme_font_size_override("font_size",14)
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
 for path in ["res://assets/licenses/Godot-LICENSE.txt","res://assets/licenses/Godot-COPYRIGHT.txt","res://assets/licenses/DejaVu.txt"]:
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
 button("Ⅱ",Rect2(468,22,48,42),pause_game)
 drop_button=button("ABWERFEN",Rect2(24,888,310,54),drop_ammo,true)
 special_button=button("IMPULS",Rect2(350,888,166,54),special_attack)
 var slider=HSlider.new()
 slider.position=Vector2(45,438)
 slider.size=Vector2(450,28)
 slider.min_value=50
 slider.max_value=490
 slider.value=aim
 slider.value_changed.connect(func(value): aim=value)
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
 if mode!="play" or attempts<=0:
  return
 var count=int(stats["drop"])
 if active_balls()+count>(MAX_BALLS if quality==1 else 64):
  status_text="Kugeln unterwegs – gleich ist wieder Platz."
  return
 attempts-=1
 dropped+=count
 profile.data["stats"]["drops"]+=1
 for i in range(count):
  emit_ball(Vector2(aim+rng.randf_range(-9,9),488-i*2),Vector2(rng.randf_range(-35,35)+(aim-270)*0.16,rng.randf_range(5,35)))
 audio.play_effect("drop")
 status_text="Jede Kugel zählt. Multiplikatoren vervielfachen ihren Wert."

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
 for rotor in rotors:
  if rotor["kind"]=="trapdoor":
   rotor["body"].rotation=sin(clock*rotor["speed"])*1.25
  else:
   rotor["body"].rotation+=delta*rotor["speed"]
 for ball in pool:
  if not ball.live:
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
      ball.position=Vector2(540-ob["pos"].x,ob["pos"].y+35)
      ball.portal_used=true
      ball.linear_velocity=Vector2(30*(variant-1),180)
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
   ball.position.x=clampf(ball.position.x,30,510)
   ball.linear_velocity.x*=-0.5
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
 var e={"type":kind,"x":555.0,"y":rng.randf_range(283,335),"hp":health,"max_hp":health,"speed":float(template[2]),"damage":float(template[3])*(1+level*0.018),"reward":int(template[5]),"timer":1.0,"flash":0.0,"age":0.0,"poison":0.0,"burn":0.0,"slow":0.0,"boss":boss,"boss_id":boss_id,"telegraph":0.0,"phase":1,"dead":false}
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
 elif ammo<=0 and attempts<=0 and active_balls()==0:
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
 tracers.append({"from":Vector2(124,292),"to":impact,"life":0.12 if effect!="laser" else 0.2,"color":CYAN if effect in ["laser","plasma"] else LIME})
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
 clear_ui()
 cards.clear()
 while cards.size()<3:
  var id=rng.randi_range(0,Content.UPGRADES.size()-1)
  var card=Content.UPGRADES[id]
  if card.size()>4 and int(card[4])!=int(profile.data["class"]):
   continue
  if not id in cards:
   cards.append(id)
 label("WELLE %d ABGESCHLOSSEN"%wave,Vector2(30,395),14,LIME)
 label("Werde zur Gegenwelle.",Vector2(30,428),28)
 label("Wähle eine kostenlose Verbesserung.",Vector2(30,475),14,MUTED)
 for i in range(3):
  var card=Content.UPGRADES[cards[i]]
  button("%02d   %s\n%s"%[i+1,card[0],card[1]],Rect2(30,535+i*104,480,88),func():
   apply_upgrade(cards[i])
   mode="play"
   wave+=1
   attempts+=2
   build_hud()
   begin_wave(),i==0)
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
  drop_button.text="ABWERFEN  ·  %d ÜBRIG"%attempts
  drop_button.disabled=attempts<=0
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
 var color=Color(Content.COLORS[world])
 draw_rect(Rect2(0,top,540,bottom-top),color)
 draw_circle(Vector2(433,top+49),27,Color(color.lightened(0.32),0.55))
 # Layered skyline: deterministic silhouettes, antennas, windows, vegetation.
 for layer in range(3):
  var shade=color.darkened(0.15+layer*0.19)
  for i in range(11):
   var x=float(i*59-18)+sin(i*17.1+world)*14
   var height=42+fmod(i*73+world*31+layer*43,98)
   var ground=bottom-31+layer*8
   if world in [1,5,6]:
    line(Vector2(x+16,ground),Vector2(x+16,ground-height),shade,8)
    for j in range(3):
     polygon([Vector2(x-13,ground-height*0.35-j*21),Vector2(x+16,ground-height-23-j*7),Vector2(x+47,ground-height*0.35-j*21)],shade)
   else:
    var r=Rect2(x,ground-height,46,height)
    draw_rect(r,shade)
    if i%3==0:
     line(Vector2(x+25,r.position.y),Vector2(x+25,r.position.y-23),shade,3)
     line(Vector2(x+17,r.position.y-17),Vector2(x+35,r.position.y-17),shade,2)
    for j in range(2):
     for k in range(3):
      if (i+j+k)%3!=0:
       draw_rect(Rect2(x+8+j*19,ground-height+14+k*21,7,10),Color("c2c394").darkened(layer*0.25))
 draw_rect(Rect2(0,bottom-24,540,24),Color("15232b"))
 for i in range(16):
  line(Vector2(i*39,bottom-14),Vector2(i*39+19,bottom-14),Color("32433d"),2)

func draw_hero(at: Vector2,scale_value: float=1.0,pose: String="idle") -> void:
 var bob=sin(clock*3)*1.5
 var suit=[Color("e99b54"),Color("74bdc7"),Color("d65e62")][int(profile.data["outfit"])]
 if damage_flash>0:
  suit=Color.WHITE
 draw_set_transform(at+Vector2(0,-12 if pose=="defeat" else 0),-PI/2 if pose=="defeat" else 0,Vector2.ONE*scale_value)
 draw_ellipse_shadow(Vector2(0,4),27,8)
 # Boots, legs, utility coat and backpack.
 line(Vector2(-10,-18),Vector2(-13,0),Color("0b1421"),13)
 line(Vector2(8,-18),Vector2(13,0),Color("0b1421"),13)
 panel(Rect2(-24,-51+bob,17,30),Color("25364a"),5)
 polygon([Vector2(-18,-49+bob),Vector2(13,-49+bob),Vector2(20,-15),Vector2(-20,-15)],Color("101b2b"))
 polygon([Vector2(-16,-48+bob),Vector2(10,-48+bob),Vector2(16,-24),Vector2(-16,-21)],suit)
 line(Vector2(-10,-43+bob),Vector2(9,-30),Color("f5d99a"),4)
 draw_rect(Rect2(-17,-25,34,7),Color("26354a"))
 draw_rect(Rect2(-5,-24,9,6),Color("c7c9a2"))
 # Face mask, swept hair and luminous visor.
 panel(Rect2(-17,-76+bob,35,31),Color("101a29"),9)
 panel(Rect2(-13,-72+bob,28,23),Color("e3b48d"),7)
 polygon([Vector2(-18,-68+bob),Vector2(-13,-84+bob),Vector2(7,-89+bob),Vector2(3,-81+bob),Vector2(20,-80+bob),Vector2(14,-68+bob),Vector2(-2,-73+bob)],Color("3a292c"))
 panel(Rect2(-5,-67+bob,25,10),CYAN,3)
 line(Vector2(0,-65+bob),Vector2(12,-65+bob),Color("e8ffff"),2)
 panel(Rect2(-4,-53+bob,19,8),Color("26364b"),2)
 # Arm, glove and weapon silhouette.
 var recoil=-5.0 if shoot_flash>0 else 0.0
 line(Vector2(9,-42+bob),Vector2(29+recoil,-40+bob),suit,12)
 draw_circle(Vector2(27+recoil,-40+bob),6,Color("e3b48d"))
 var w=int(profile.data["weapon"])
 panel(Rect2(24+recoil,-48+bob,26+(w%4)*5,11),Color("0b1421"),2)
 draw_rect(Rect2(30+recoil,-49+bob,15,3),Color("89a2ab"))
 line(Vector2(33+recoil,-40+bob),Vector2(30+recoil,-29+bob),Color("101a29"),7)
 if shoot_flash>0:
  polygon([Vector2(51,-43),Vector2(66,-51),Vector2(61,-42),Vector2(76,-36),Vector2(55,-34)],LIME)
 if shield>0 or pose=="special":
  draw_arc(Vector2(0,-35),49,-1.6,1.6,24,Color(CYAN,0.65),3,true)
 if pose=="victory":
  line(Vector2(-15,-40),Vector2(-30,-78+sin(clock*5)*5),suit,10)
 if pose=="defeat":
  line(Vector2(-18,-4),Vector2(26,-4),CORAL,3)
 draw_set_transform(Vector2.ZERO)

func draw_ellipse_shadow(at: Vector2,w: float,h: float) -> void:
 var points=PackedVector2Array()
 for i in range(24):
  points.append(at+Vector2(cos(i*TAU/24)*w,sin(i*TAU/24)*h))
 draw_colored_polygon(points,Color(0,0,0,0.25))

func draw_enemy(e: Dictionary) -> void:
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
 if mode=="menu":
  backdrop(0,305,567)
  draw_hero(Vector2(144,547),2.15)
  var preview={"type":7,"boss":false,"x":424.0,"y":541.0,"age":clock,"flash":0.0,"hp":1.0,"max_hp":1.0,"telegraph":0.0}
  draw_enemy(preview)
  line(Vector2(218,451),Vector2(359,457),LIME,3)
  panel(Rect2(31,279,116,26),Color("243a40"),6)
  text_at("PHYSICS × SURVIVAL",Vector2(41,297),10,LIME)
  return
 if mode in ["map","armory","settings","character","licenses"]:
  for i in range(12):
   line(Vector2(0,155+i*64),Vector2(540,155+i*64),Color("0d1c2a"),1)
  return
 if layout.is_empty():
  return
 backdrop(int(layout["world"]),121,380)
 # Tactical HUD, two readable levels of information.
 text_at("DEADWAVE / %02d"%level,Vector2(24,39),17,LIME)
 text_at("%s"%Content.WORLDS[int(layout["world"])],Vector2(24,61),12,MUTED)
 text_at("WELLE %02d / %02d"%[wave,wave_count],Vector2(291,42),14,INK)
 bar(Rect2(24,82,260,10),hp/maxf(1,float(stats["max_hp"])),CORAL)
 text_at("%d / %d HP%s"%[maxi(0,int(hp)),int(stats["max_hp"]),"  +%d SCHILD"%int(shield) if shield>0 else ""],Vector2(24,113),12,INK)
 text_at("%d MÜNZEN"%int(profile.data["coins"]),Vector2(357,104),13,LIME)
 draw_hero(Vector2(94,340),1.1,hero_pose)
 if float(stats.get("drone",0))>0:
  var p=Vector2(122,239+sin(clock*4)*4)
  panel(Rect2(p-Vector2(14,6),Vector2(28,12)),CYAN,4)
  line(p+Vector2(-24,-9),p+Vector2(-5,-9),INK,2)
  line(p+Vector2(5,-9),p+Vector2(24,-9),INK,2)
 for e in enemies:
  draw_enemy(e)
 for t in tracers:
  line(t["from"],t["to"],Color(t["color"],clampf(t["life"]*7,0,1)),3)
 panel(Rect2(16,354,508,53),PANEL,10)
 text_at("MUNITION",Vector2(30,373),10,MUTED)
 text_at(compact(ammo),Vector2(30,398),25,LIME)
 text_at("%s  +%d"%[weapon()[0],int(profile.data["weapon_levels"].get(str(profile.data["weapon"]),0))],Vector2(181,379),13,INK)
 text_at("NACHLADEN" if reload_timer>0 else "%d IM MAGAZIN"%magazine,Vector2(181,398),11,MUTED)
 text_at("ENERGIE",Vector2(405,375),10,MUTED)
 bar(Rect2(404,387,99,7),energy/100.0,CYAN)
 # The lower factory: original teal / acid art direction.
 panel(Rect2(16,471,508,403),Color("0d1e2a"),12)
 for i in range(12):
  line(Vector2(30,495+i*31),Vector2(510,495+i*31),Color("152b38"),1)
 for i in range(15):
  line(Vector2(32+i*34,480),Vector2(32+i*34,863),Color("122735"),1)
 draw_rect(Rect2(18,481,9,378),Color("3b5664"))
 draw_rect(Rect2(513,481,9,378),Color("3b5664"))
 for row in range(3):
  var gate=layout["gates"][row]
  var y=float(gate["y"])
  var split=gate_split(row)
  for side in range(2):
   var x=31.0 if side==0 else split+5
   var width=split-36 if side==0 else 509-split
   var tint=LIME if int(gate["left"] if side==0 else gate["right"])>=3 else CYAN
   panel(Rect2(x,y-11,width,23),Color(tint,0.13),3)
   line(Vector2(x,y+11),Vector2(x+width,y+11),Color(tint,0.6),1)
   text_at("×%d"%int(gate["left"] if side==0 else gate["right"]),Vector2(x+width/2-15,y+7),18,tint)
  draw_circle(Vector2(split,y),4,INK)
 for ob in obstacles:
  if ob["broken"]:
   continue
  var p: Vector2=ob["pos"]
  var kind=String(ob["kind"])
  var variant=int(ob["variant"])
  if ob["body"]!=null:
   var body=ob["body"]
   if kind=="peg":
    draw_circle(p,12+variant*3,Color("406073"))
    draw_circle(p-Vector2(2,2),5,CYAN)
   else:
    draw_set_transform(p,body.rotation)
    panel(Rect2(-33-variant*6,-5,66+variant*12,10),Color("6e8794") if kind!="breakable" else Color("b47657"),4)
    line(Vector2(-25,-2),Vector2(25,-2),Color("c6d4ce"),1)
    if kind in ["rotor","trapdoor"]:
     draw_circle(Vector2.ZERO,7,CORAL)
     draw_circle(Vector2.ZERO,3,INK)
    draw_set_transform(Vector2.ZERO)
  elif kind=="portal":
   draw_arc(p,18,clock*2,clock*2+5.4,24,CYAN,4)
   draw_arc(Vector2(540-p.x,p.y+35),18,-clock*2,-clock*2+5.4,24,Color("bc8df4"),4)
  elif kind=="boost":
   for i in range(3):
    line(p+Vector2(-9,-8+i*9),p+Vector2(0,-1+i*9),CYAN,3)
    line(p+Vector2(0,-1+i*9),p+Vector2(9,-8+i*9),CYAN,3)
  elif kind=="bonus":
   draw_circle(p,20,Color(LIME,0.12))
   text_at("+%d"%(5*(variant+1)),p+Vector2(-13,6),15,LIME)
 # Articulated launcher above board, collection trough below.
 line(Vector2(aim,467),Vector2(aim,493),Color("44596c"),15)
 panel(Rect2(aim-23,467,46,22),Color("849caa"),5)
 line(Vector2(aim-14,470),Vector2(aim+14,470),LIME,3)
 panel(Rect2(29,839,482,26),Color("234953"),6)
 for i in range(12):
  line(Vector2(42+i*39,846),Vector2(53+i*39,857),Color("40767a"),3)
 text_at("SAMMLER",Vector2(231,858),10,INK)
 text_at(status_text.left(72),Vector2(27,429),11,MUTED)
 for particle in sparks:
  draw_circle(particle["pos"],2.2,Color(particle["color"],clampf(particle["life"]*3,0,1)))
 for f in floats:
  text_at(f["text"],f["pos"],15,Color(f["color"],minf(1,f["life"]*2)))
 if mode in ["upgrade","pause","victory","defeat"]:
  draw_rect(Rect2(0,387,540,573),Color(BG,0.97))
 if damage_flash>0:
  draw_rect(Rect2(0,0,540,960),Color(CORAL,damage_flash*0.25))
