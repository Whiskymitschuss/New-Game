extends SceneTree
var game
var failures=0
var checks=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:
  failures+=1
  push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.start_level(1);game.set_physics_process(false)
 game.mode="upgrade"
 for first in range(0,Content.UPGRADES.size(),3):
  game.cards=[first,mini(first+1,Content.UPGRADES.size()-1),mini(first+2,Content.UPGRADES.size()-1)]
  game.build_upgrade_picker()
  await process_frame
  await process_frame
  var wrapped=0
  for control in game.controls.get_children():
   if control is Label and control.autowrap_mode!=TextServer.AUTOWRAP_OFF:
    wrapped+=1
    check(control.size.x<=132.1,"upgrade text crosses card boundary: "+control.text)
    check(control.get_minimum_size().y<=control.size.y+1,"upgrade text is cut off vertically: "+control.text)
  check(wrapped==6,"all three upgrade cards have title and description")
  var buttons=0
  for control in game.controls.get_children():
   if control is Button:buttons+=1
  check(buttons==3,"each card has a working selection control")
 game.show_armory();await process_frame
 var portraits=0
 for control in game.controls.get_children():
  if control is TextureRect:
   portraits+=1
   check(control.size.x<=128 and control.size.y<=128,"hero portrait stays inside its class card")
 check(portraits==3,"three textured class portraits")
 print("UI RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(0 if failures==0 else 1)
