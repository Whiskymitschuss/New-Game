extends SceneTree
# Staged visual regression scene, using actual game systems and assets.
# -- --4k produces native 2160x3840 captures from the vector-scaled UI.
var game
var suffix=""
func shot(name: String) -> void:
 for i in range(3):await process_frame
 await RenderingServer.frame_post_draw
 var image=root.get_texture().get_image()
 image.save_png("res://builds/neon-"+name+suffix+".png")
 print("CAPTURE ",name,": ",image.get_width(),"x",image.get_height())
func _initialize() -> void:call_deferred("run")
func run() -> void:
 if "--4k" in OS.get_cmdline_user_args():
  root.content_scale_size=Vector2i(540,960)
  root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
  root.size=Vector2i(2160,3840)
  suffix="-4k"
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 await shot("menu")
 game.start_level(1);game.set_physics_process(false)
 for i in range(3):
  var e=game.spawn_enemy();e["type"]=[0,1,2][i];e["x"]=342+i*73;e["y"]=327.0;e["age"]=i*1.3
 game.aim=400;game.drop_ammo()
 for i in range(65):
  game.physics_balls(1.0/60.0)
  await physics_frame
 await shot("gameplay")
 game.choose_upgrade();await shot("upgrades")
 for control in game.controls.get_children():
  if control is Label and control.autowrap_mode!=TextServer.AUTOWRAP_OFF:
   if control.size.x>132.1:
    push_error("Upgrade text exceeds its card: "+control.text)
    quit(1)
    return
 game.show_armory();await shot("armory")
 game.menu_page=0;game.show_map();await shot("map")
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit()
