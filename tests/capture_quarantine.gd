extends SceneTree
# Unmodified combat and ordinary production choices, captured by the real renderer.
var game
var large=false
var gameplay=false
var upgrades=false
func _initialize() -> void:call_deferred("run")
func shot(name: String,settle: int=24) -> void:
 if large:
  root.content_scale_size=Vector2i(540,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
  root.size=Vector2i(2160,3840)
 for i in range(settle):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/quarantine-"+name+".png")
 print("QUARANTINE CAPTURE ",name," ",root.size)
 if large:root.size=Vector2i(540,960)
func run() -> void:
 large="--4k" in OS.get_cmdline_user_args()
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.profile.reset();game.show_menu();await shot("menu")
 game.show_armory(2);await shot("arsenal")
 game.show_map();await shot("map")
 game.show_settings();await shot("settings")
 game.start_level(1);game.set_aim(410)
 for frame in range(6000):
  if game.mode=="play" and game.ammo<45 and game.active_balls()==0 and game.attempts>0:game.drop_ammo()
  if frame==280 and game.active_balls()==0:game.drop_ammo()
  if frame>300 and not gameplay and game.active_balls()>0 and not game.blood_fx.bursts.is_empty():
   await shot("gameplay",3);gameplay=true
   print("CAPTURE COMBAT kills=",game.run_kills," blood_stains=",game.blood_fx.stains.size()," balls=",game.active_balls())
  if game.mode=="upgrade":
   await shot("upgrades");upgrades=true;break
  if game.mode=="defeat":break
  await physics_frame
 if not gameplay or not upgrades:
  push_error("FAIL: ordinary capture must reach live balls, blood combat and an actual upgrade choice")
  quit(1);return
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit()
