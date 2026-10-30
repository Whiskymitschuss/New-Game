extends SceneTree
var game
var checks=0
var failures=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func run() -> void:
 root.content_scale_size=Vector2i(540,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,960)
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.profile.reset();game.start_level(1);game.set_process(false);game.set_physics_process(false)
 var original=game.rng.state
 game.update_launcher(0.1)
 check(is_equal_approx(game.aim,334.0),"automatic injector travels sixty-four pixels in one tenth second")
 game.set_aim(480);game.update_launcher(0.1)
 check(is_equal_approx(game.aim,436.0),"edge overshoot reflects rather than clipping or teleporting")
 var stable=true
 for i in range(200):
  game.update_launcher(0.077)
  stable=stable and game.aim>=50 and game.aim<=490
 check(stable,"rapid motion always stays inside physical emission boundaries")
 var position=game.aim;game.mode="pause";game.update_launcher(5)
 check(game.aim==position,"pause holds the actual rail")
 game.mode="upgrade";game.update_launcher(5);check(game.aim==position,"upgrade selection holds the rail")
 game.mode="play";game.update_launcher(-1);check(game.aim==position,"negative time cannot move the rail backwards")
 check(game.rng.state==original,"automatic rail never consumes gameplay randomness")
 game.set_aim(400);game.ammo=0;game.drop_ammo()
 var attempts=game.attempts;position=game.aim
 game.update_launcher(1)
 check(game.aim==position,"the whole queued salvo stays under its visible injector")
 var centers=true
 for pending in game.pending_balls:centers=centers and absf(pending["at"].x-position)<=20.01
 check(centers,"all queued balls use the position captured at release")
 game.drop_ammo();check(game.attempts==attempts,"timing input cannot spend two attempts during one salvo")
 game.pending_balls.clear();game.emit_ball(Vector2(400,600),Vector2.ZERO)
 game.update_launcher(0.1)
 check(game.aim!=position and game.active_balls()>0,"rail resumes while existing physical balls keep falling")
 check(not game.aim_slider.editable and game.aim_slider.mouse_filter==Control.MOUSE_FILTER_IGNORE,"rail display cannot be dragged or focused")
 game.start_level(1)
 check(game.aim==270 and game.launcher_phase==220,"new deployment resets the timing phase consistently")
 var args=OS.get_cmdline_user_args()
 if "--campaign" in args:
  game.set_process(true);game.set_physics_process(true)
  var elapsed=0.0;var timed_drops=0
  while game.mode not in ["victory","defeat"] and elapsed<300:
   if game.mode=="play" and game.ammo<75 and game.active_balls()==0 and game.pending_balls.is_empty() and game.attempts>0:
    var left=1;var right=1
    for gate in game.layout["gates"]:
     left*=maxi(1,int(gate["left"]));right*=maxi(1,int(gate["right"]))
    if (left>right and game.aim<105) or (left<=right and game.aim>435):
     game.drop_button.pressed.emit();timed_drops+=1
   elif game.mode=="upgrade":
    var choice=0;var best=-1
    for i in range(game.cards.size()):
     var key=String(Content.UPGRADES[game.cards[i]][2]);var score=0
     if key in ["damage","speed","pierce","multishot"]:score=2
     if game.ammo<100 and key in ["ammo","drop","collection","attempt"]:score=3
     if score>best:best=score;choice=i
    var buttons=[]
    for item in game.controls.get_children():
     if item is Button:buttons.append(item)
    buttons[choice].pressed.emit()
   if game.mode=="play" and game.energy>=70 and game.enemies.size()>2:game.special_attack()
   await physics_frame;elapsed+=1.0/60
  check(game.mode=="victory" and timed_drops>0,"complete first deployment wins by timing the moving rail without setting aim")
  print("TIMING CAMPAIGN result=",game.mode," seconds=",elapsed," timed_drops=",timed_drops," kills=",game.run_kills)
 if "--render" in args or "--film" in args:
  game.start_level(1);game.set_process(true);game.set_physics_process(true)
  var film="--film" in args
  for frame in range(360):
   if frame==55 or frame==235:
    var press=InputEventMouseButton.new();press.button_index=MOUSE_BUTTON_LEFT;press.pressed=true;press.position=Vector2(130,915);press.global_position=press.position
    root.push_input(press)
    if frame==55:check(not game.pending_balls.is_empty(),"native button captures the drop on press rather than delayed release")
   if frame==57 or frame==237:
    var release=InputEventMouseButton.new();release.button_index=MOUSE_BUTTON_LEFT;release.position=Vector2(130,915);release.global_position=release.position
    root.push_input(release)
   if frame==80 and not film:
    await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("res://builds/timing-rail-v0.2.11.png")
   await process_frame
  check(game.dropped>=12,"native drop button releases a real timed physical stream")
 print("AUTO LAUNCHER RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(1 if failures else 0)
