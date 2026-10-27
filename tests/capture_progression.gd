extends SceneTree
# Real sector3 run with proof of the two preceding sectors, ordinary inputs only.
var game
var large=false
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
 if large:
  root.content_scale_size=Vector2i(540,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
  root.size=Vector2i(2160,3840)
 for i in range(18):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/progression-"+name+".png")
 print("PROGRESSION CAPTURE ",name," ",root.size)
 if large:root.size=Vector2i(540,960)
func run() -> void:
 large="--4k" in OS.get_cmdline_user_args()
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.profile.reset();game.profile.data["unlocked"]=3;game.profile.data["stars"]={"1":3,"2":3}
 game.start_level(3);game.set_aim(410)
 for frame in range(36000):
  if game.mode=="play":
   if game.ammo<45 and game.active_balls()==0 and game.attempts>0:game.drop_ammo()
   if game.energy>=70 and game.enemies.size()>2:game.special_attack()
  elif game.mode=="upgrade":
   var buttons=[]
   for control in game.controls.get_children():
    if control is Button:buttons.append(control)
   if game.wave==2:await shot("upgrades")
   buttons[1].pressed.emit()
  elif game.mode=="victory":break
  elif game.mode=="defeat":push_error("Capture campaign failed");quit(1);return
  await physics_frame
 await shot("unlock")
 game.show_armory(2);await shot("arsenal")
 game.show_armory(3);await shot("locked")
 game.show_menu();await shot("menu")
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit()
