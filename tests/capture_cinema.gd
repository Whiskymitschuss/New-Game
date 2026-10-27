extends SceneTree
var game
var large=false
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
 if large:
  root.content_scale_size=Vector2i(540,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
  root.size=Vector2i(2160,3840)
 for i in range(24):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/cinema-"+name+".png")
 print("CINEMA CAPTURE ",name," ",root.size)
 if large:root.size=Vector2i(540,960)
func run() -> void:
 large="--4k" in OS.get_cmdline_user_args()
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.profile.reset();game.show_menu();await shot("menu")
 game.show_armory(2);await shot("arsenal")
 game.start_level(1);game.set_aim(410)
 for frame in range(900):
  if game.mode=="play" and game.ammo<45 and game.active_balls()==0 and game.attempts>0:game.drop_ammo()
  if frame==280 and game.active_balls()==0:game.drop_ammo()
  if frame==335:await shot("gameplay")
  await physics_frame
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit()
