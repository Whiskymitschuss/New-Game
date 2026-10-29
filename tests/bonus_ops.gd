extends SceneTree
var failures=0
var checks=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.profile.reset();game.start_level(1);game.set_process(false);game.set_physics_process(false)
 var ops=game.bonus_ops;ops.set_process(false);ops._process(0)
 var rng=game.rng.state
 ops.offer();check(ops.state=="offer" and ops.sequence.size()==3,"first optional offer has three swipe directions")
 check(game.rng.state==rng,"side objectives do not alter combat RNG")
 ops.open();game.ammo=10
 var expected=ops.sequence.duplicate()
 for value in expected:
  var offset=[Vector2(80,0),Vector2(0,50),Vector2(-80,0),Vector2(0,-50)][value]
  ops.swipe(offset)
 check(game.ammo==34 and ops.state=="result","three real directions credit bounded ammunition")
 ops.submit(expected[-1]);check(game.ammo==34,"stale callbacks cannot double reward")
 ops.dismiss();ops.offer();ops.open();check(ops.kind=="code" and ops.sequence.size()==4,"second event is a four digit code")
 ops.submit(0);check(ops.progress==0,"wrong digit resets the sequence without charging currency")
 var before=game.profile.data["coins"]
 for digit in ops.sequence.duplicate():ops.submit(digit)
 check(game.profile.data["coins"]==before+18,"valid code grants eighteen permanent credits")
 var saved=Profile.new();saved.load_game();check(saved.data["coins"]==before+18,"code credits survive reload")
 ops.dismiss();ops.offer();check(ops.state=="idle","wave budget prevents repeated farming")
 ops.reset();ops._process(0);ops.offer();ops.open()
 var time=ops.remaining;game.mode="pause";ops._process(20)
 check(ops.remaining==time,"pause freezes the minigame deadline")
 ops.submit(ops.sequence[0]);check(ops.progress==0,"paused inputs cannot advance or reward")
 game.mode="play";ops._process(8)
 check(ops.state=="idle" and game.profile.data["coins"]==before+18,"expired challenge closes without a penalty")
 ops.reset();ops._process(0);ops.offer();ops.open();game.ammo=int(game.stats["capacity"]);game.energy=98
 for value in ops.sequence.duplicate():ops.submit(value)
 check(game.ammo==int(game.stats["capacity"]) and game.energy==100,"full ammo falls back to capped energy")
 ops.reset();ops._process(0);ops.offer();ops.open();ops.submit(ops.sequence[0]);game.wave+=1;ops._process(0)
 check(ops.state=="idle" and ops.offered==0 and ops.progress<=1,"next wave clears old challenge and restores its budget")
 check(game.COMBAT_PACE==1.25,"combat pace is twenty five percent faster without global time scale")
 if "--render" in OS.get_cmdline_user_args():
  root.size=Vector2i(540,960);game.set_process(true);game.set_physics_process(true)
  ops.reset();ops._process(0);ops.offer();ops.open()
  game.set_process(false);game.set_physics_process(false);ops.set_process(false)
  game.ammo=10
  await process_frame;await process_frame
  for direction in ops.sequence.duplicate():
   var offset=[Vector2(65,0),Vector2(0,27),Vector2(-65,0),Vector2(0,-27)][direction]
   for pressed in [true,false]:
    var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
    event.position=Vector2(350,293)+(Vector2.ZERO if pressed else offset);event.global_position=event.position
    root.push_input(event);await process_frame
  check(ops.state=="result" and game.ammo==34,"native pointer swipes complete the real input surface")
  ops.dismiss();ops.offer();ops.open();await process_frame;await process_frame
  before=int(game.profile.data["coins"])
  for digit in ops.sequence.duplicate():
   for pressed in [true,false]:
    var event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=pressed
    event.position=Vector2(241+(digit-1)*74,298);event.global_position=event.position
    root.push_input(event);await process_frame
  check(ops.state=="result" and game.profile.data["coins"]==before+18,"native number buttons persist the actual reward")
  ops.reset();ops._process(0);ops.offer();ops.open();await process_frame
  game.label("WISCH-KOMBO · FREIWILLIGER BONUS",Vector2(24,946),10,Color.WHITE,490)
  for i in range(5):await process_frame
  await RenderingServer.frame_post_draw
  root.get_texture().get_image().save_png("res://builds/live-ops-v0.2.10.png")
 print("BONUS OPS RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(1 if failures else 0)
