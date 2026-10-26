extends SceneTree
var checks=0
var failures=0
var game
func check(ok: bool,message: String) -> void:
 checks+=1
 print(("PASS: " if ok else "FAIL: ")+message)
 if not ok:failures+=1
func _initialize() -> void:call_deferred("run")
func run() -> void:
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.start_level(1);game.set_physics_process(false)
 game.layout["pieces"]=[];game.build_maze()
 await physics_frame
 for quality in [0,1]:
  game.quality=quality
  for cycle in range(12):
   # Reuse the same actual server bodies: no replacing the pool between drops.
   if cycle==4 or cycle==8:
    game.wave+=1
    game.begin_wave()
   game.layout["gates"]=Content.level_data(1)["gates"]
   game.clear_balls();game.ammo=0;game.attempts=2;game.aim=410
   var before=game.collected;game.drop_ammo()
   var board_frames=0;var ready_in_factory=false;var maximum=0;var ticks=0
   for tick in range(600):
    game.physics_balls(1.0/60.0)
    await physics_frame
    ticks+=1;maximum=maxi(maximum,game.active_balls())
    var on_board=false
    for ball in game.pool:
     if ball.live and not ball.reset_pending and ball.position.y>=490 and ball.position.y<835:
      on_board=true
      if tick<12:ready_in_factory=true
    if on_board:board_frames+=1
    if tick==35 and cycle%3==0:
     for ball in game.pool:
      if ball.live:ball.freeze=true
     await physics_frame
     for ball in game.pool:
      if ball.live:ball.freeze=false
    if game.pending_balls.is_empty() and game.active_balls()==0:break
   var name="quality %d drop %d"%[quality,cycle+1]
   check(ready_in_factory,name+": reused body starts inside factory")
   check(board_frames>=75,name+": visible trajectory lasts at least 1.25 seconds")
   check(game.collected-before==216,name+": all twelve units follow x3 x2 x3 exactly")
   check(ticks<600 and game.active_balls()==0 and game.pending_balls.is_empty(),name+": completes without timeout collection")
   check(maximum<=(64 if quality==0 else 128),name+": respects pool limit")
 print("REUSE RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(0 if failures==0 else 1)
