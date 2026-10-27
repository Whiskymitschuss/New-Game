extends SceneTree
# Real combat and physics, only ordinary player actions. No enemy/stats placement.
var game
var capture_4k=false
func _initialize() -> void:call_deferred("run")
func save_shot(name: String) -> void:
 if capture_4k:
  root.content_scale_size=Vector2i(540,960)
  root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
  root.size=Vector2i(2160,3840)
  for i in range(3):await process_frame
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 image.save_png("res://builds/"+name+("-4k" if capture_4k else "")+".png")
 print("LIVE CAPTURE ",name," wave=",game.wave," ammo=",game.ammo," enemies=",game.enemies.size()," balls=",game.active_balls())
 if capture_4k:root.size=Vector2i(540,960)
func run() -> void:
 capture_4k="--4k" in OS.get_cmdline_user_args()
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.profile.reset();game.start_level(3);game.set_aim(400)
 var captured=false
 var upgrade_captured=false
 for frame in range(18000):
  if game.mode=="play":
   if game.active_balls()==0 and game.pending_balls.is_empty() and game.attempts>0:
    if game.ammo<45 or (game.wave>=2 and game.enemies.size()>=8 and game.ammo<110):game.drop_ammo()
   if game.wave>=2 and game.enemies.size()>=8 and game.active_balls()>=7 and not game.reactor_fx.events.is_empty() and not captured:
    await save_shot("reactor-v0.2.3")
    captured=true
   if game.energy>=75 and game.enemies.size()>16:game.special_attack()
  elif game.mode=="upgrade":
   if captured:
    await save_shot("reactor-upgrades-v0.2.3")
    upgrade_captured=true
    break
   var picks=[]
   for control in game.controls.get_children():
    if control is Button:picks.append(control)
   picks[1].pressed.emit()
  elif game.mode in ["victory","defeat"]:break
  await physics_frame
 if not captured or not upgrade_captured:push_error("Live reactor capture did not reach both requested states")
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(0 if captured and upgrade_captured else 1)
