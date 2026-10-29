extends SceneTree
# Explicit controlled FX showcase. Charges, unlocked rifle and sturdy targets
# are fixtures; every visible shot, status tick, drone shot and ball uses the game.
var game
var film=false
var large=false
var pilot=false
var shown={}
func _initialize() -> void:call_deferred("run")
func fixture(kind: String) -> void:
 game.profile.reset()
 game.profile.data["class"]=1
 game.profile.data["weapon"]=3
 game.profile.data["unlocked"]=7
 for level in range(1,7):game.profile.data["stars"][str(level)]=1
 game.start_level(7)
 game.remaining=0;game.spawn_timer=9999
 game.ammo=180
 if kind!="normal":
  for i in range(3):
   game.ammo_cargo.begin_drop();game.ammo_cargo.add_refined(kind,12)
 for i in range(3):
  var enemy=game.spawn_enemy()
  enemy["type"]=[0,2,7][i]
  var template=Content.ENEMIES[int(enemy["type"])]
  enemy["speed"]=float(template[2]);enemy["damage"]=float(template[3])*(1+game.level*0.018)
  enemy["reward"]=int(template[5])
  enemy["x"]=330+i*66;enemy["y"]=322-i*7
  enemy["hp"]=650.0;enemy["max_hp"]=650.0
 game.set_aim(85 if kind=="fire" else (455 if kind=="frost" else 140))
 game.label("FX-VORSCHAU · GEZIELTES TESTSZENARIO",Vector2(24,946),9,Color("a4bcb9"),490,true)
 game.label(("BRAND / FLAMMEN & GLUT" if kind=="fire" else ("KRYO / EIS & KRISTALLE" if kind=="frost" else ("EMP / ELEKTRISCHE ENTLADUNG" if kind=="emp" else "DROHNE / ANTRIEB & WAFFENSYSTEM"))),Vector2(185,179),9,Color("fff0db"),460,true)
func shot(name: String) -> void:
 if film or pilot:return
 var held_pause=paused
 paused=true
 RenderingServer.set_render_loop_enabled(true)
 if large:root.size=Vector2i(2160,3840)
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/"+name+"-v0.2.9.png")
 print("ELEMENTAL CAPTURE ",name," ",root.size)
 if large:root.size=Vector2i(540,960)
 RenderingServer.set_render_loop_enabled(false)
 paused=held_pause
func run() -> void:
 var args=OS.get_cmdline_user_args()
 film="--film" in args;large="--4k" in args;pilot="--pilot" in args
 root.content_scale_size=Vector2i(540,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 root.size=Vector2i(540,960)
 if not film and not pilot:RenderingServer.set_render_loop_enabled(false)
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 var index=0
 for kind in ["fire","frost","emp","normal"]:
  fixture(kind)
  var observed=false
  var drone_shot=false
  var drops=0
  var captured=false
  for frame in range(240):
   if frame==10:game.drop_ammo();drops+=1
   if game.reactor_switch.can_toggle() and frame==30:game.toggle_switch()
   for event in game.elemental_fx.events:
    if event["kind"]==kind:observed=true
   if game.support_drone.shot_left>0:drone_shot=true
   var ready=kind=="normal" and game.support_drone.shot_left>0.12
   if kind!="normal":
    for event in game.elemental_fx.events:
     if event["kind"]==kind and float(event["age"])<=0.035:ready=true
    if kind=="emp":
     var stunned=false
     for enemy in game.enemies:
      if float(enemy.get("ammo_emp",0))>0.12:stunned=true
     ready=ready and stunned
   if not captured and frame>=35 and (ready or frame==110):
    var name="elemental-"+kind if kind!="normal" else "support-drone"
    await shot(name);captured=true
   await process_frame
  var valid=(observed or kind=="normal") and drone_shot and drops==1 and game.mode=="play"
  shown[kind]=valid
  print("ELEMENTAL SHOWCASE ",kind," real_typed_shot=",observed," drone_shot=",drone_shot," ammo=",game.ammo," actual_drops=",game.profile.data["stats"]["drops"]," valid=",valid)
  index+=1
 var valid=true
 for result in shown.values():valid=valid and result
 print("ELEMENTAL MEDIA RESULT: valid=",valid," phases=",shown," frame=",Engine.get_process_frames())
 if not valid:push_error("FAIL: every controlled phase must show actual shot effects and actual support fire")
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(0 if valid else 1)
