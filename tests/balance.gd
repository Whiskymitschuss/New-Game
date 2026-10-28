extends SceneTree
var checks=0
var failures=0
var game
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 for number in range(1,101):
  var data=Content.level_data(number)
  var previous=[]
  for wave in range(1,int(data["waves"])+1):
   var gates=Content.wave_gates(number,wave,data["gates"])
   check(gates==Content.wave_gates(number,wave,data["gates"]),"wave gates are reproducible")
   check(gates!=previous,"multipliers change every wave")
   previous=gates
   for gate in gates:
    check(int(gate["left"]) in [0]+Content.MULTIPLIERS and int(gate["right"]) in [0]+Content.MULTIPLIERS,"only real multipliers or an open lane are generated")
   check(Content.wave_enemy_count(number,wave)>=15 and Content.wave_enemy_count(number,wave)<=90,"bounded increased horde quota")
 game.start_level(3);game.set_physics_process(false)
 check(game.remaining==15,"sector 3 starts with 15 instead of 4 zombies")
 check(game.stats["capacity"]==264,"early ammo capacity is bounded")
 game.ammo=int(game.stats["capacity"])
 var attempts=game.attempts
 game.drop_ammo()
 check(game.pending_balls.is_empty() and game.attempts==attempts,"full magazine store cannot waste drops")
 var first=game.layout["gates"].duplicate(true)
 game.wave+=1;game.begin_wave()
 check(game.layout["gates"]!=first,"real wave transition updates gate values")
 var total=0
 for w in range(1,6):total+=Content.wave_enemy_count(3,w)
 check(total==105,"early level has 105 enemies instead of 30")
 print("BALANCE RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(0 if failures==0 else 1)
