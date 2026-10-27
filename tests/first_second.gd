extends SceneTree
var game
var failures=0
var checks=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 for level in [1,2,3]:
  game.profile.reset();game.hero_pose="victory";game.shoot_flash=1
  game.start_level(level)
  check(game.hero_pose=="idle" and game.shoot_flash==0 and game.damage_flash==0,"new level clears prior victory and impact presentation")
  var ammo=game.ammo
  for frame in range(60):await physics_frame
  check(game.ammo<ammo,"tutorial begins with real automatic shots within one second")
  check(game.remaining+game.enemies.size()+game.run_kills==Content.wave_enemy_count(level,1),"opening stages existing quota instead of adding fake enemies")
  check(game.mode=="play" and game.hp>0,"first-second opening remains playable")
 game.profile.data["settings"]["reduced_motion"]=true
 game.pause_game();game.show_menu()
 check(bool(game.profile.data["settings"]["reduced_motion"]),"motion preference survives ordinary navigation")
 print("FIRST SECOND RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(1 if failures else 0)
