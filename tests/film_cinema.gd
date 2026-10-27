extends SceneTree
# Actual native viewport clicks: MovieMaker records renderer and game audio.
var game
var special_release=-1
var special_used=false
func _initialize() -> void:call_deferred("run")
func pointer(at: Vector2,down: bool) -> void:
 var input=InputEventMouseButton.new()
 input.position=at;input.global_position=at
 input.button_index=MOUSE_BUTTON_LEFT;input.pressed=down
 input.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
 root.push_input(input)
func run() -> void:
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.profile.reset();game.show_menu()
 for tick in range(570):
  match tick:
   75:pointer(Vector2(270,725),true)
   78:pointer(Vector2(270,725),false)
   88:pointer(Vector2(410,452),true)
   91:pointer(Vector2(410,452),false)
   96,240:pointer(Vector2(179,915),true)
   99,243:pointer(Vector2(179,915),false)
   450:pointer(Vector2(487,46),true)
   453:pointer(Vector2(487,46),false)
   477:pointer(Vector2(270,766),true)
   480:pointer(Vector2(270,766),false)
   495:pointer(Vector2(105,814),true)
   498:pointer(Vector2(105,814),false)
  if game.mode=="play" and tick<435 and game.energy>=50 and game.enemies.size()>2 and not special_used:
   pointer(Vector2(433,915),true);special_release=tick+3;special_used=true
  if tick==special_release:pointer(Vector2(433,915),false)
  await process_frame
 if game.mode!="armory" or game.dropped<=0 or game.run_kills<=0:
  push_error("FAIL: recorded native input flow did not reach real combat and arsenal")
  quit(1);return
 print("FILM RESULT: native clicks, kills=",game.run_kills," dropped=",game.dropped," end=",game.mode)
 game.queue_free();await process_frame;OS.delay_msec(100);await process_frame;quit()
