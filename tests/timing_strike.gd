extends SceneTree
var game
var checks=0
var failures=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func freeze_tree(node: Node) -> void:
 node.set_process(false);node.set_physics_process(false)
 for child in node.get_children():freeze_tree(child)
func fixture() -> void:
 game.profile.reset();game.start_level(1);freeze_tree(game)
 game.enemies.clear();game.stats["drone"]=0;game.stats["crit"]=0
 game.ammo=0;game.remaining=1;game.spawn_timer=999;game.fire_timer=999
 game.screen_age=3;game.deployment_age=3;game.clock=3;game.wave_banner=0
func enemy(at: float=320,hp: float=500,boss: bool=false) -> Dictionary:
 var e=game.spawn_enemy(boss);e["type"]=0;e["x"]=at;e["y"]=320.0
 e["hp"]=hp;e["max_hp"]=hp;e["speed"]=0.0;e["timer"]=999.0
 return e
func pointer(at: Vector2,pressed: bool) -> void:
 var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_LEFT;e.pressed=pressed;e.position=at;e.global_position=at;root.push_input(e)
func image_frame() -> Image:
 game.queue_redraw();game.timing_strike.queue_redraw();game.timing_strike.painter.queue_redraw()
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 return root.get_texture().get_image()
func differences(a: Image,b: Image,rect: Rect2i) -> int:
 var n=0
 for y in range(rect.position.y,rect.end.y):
  for x in range(rect.position.x,rect.end.x):
   var c=a.get_pixel(x,y);var d=b.get_pixel(x,y)
   if absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b)>0.12:n+=1
 return n
func run() -> void:
 root.content_scale_size=Vector2i(540,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.size=Vector2i(540,960)
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 if "--film" in OS.get_cmdline_user_args():
  await film()
  print("TIMING STRIKE FILM: %d checks, %d failures"%[checks,failures])
  game.queue_free();await process_frame;quit(1 if failures else 0);return
 fixture();var fx=game.timing_strike
 var random_state=game.rng.state
 fx.update(0.1);check(game.rng.state==random_state,"timing target and charge UI do not consume gameplay RNG")
 var p=fx.target_x();game.mode="pause";fx.update(1);check(fx.target_x()==p,"pause holds the target")
 game.mode="upgrade";fx.update(1);check(fx.target_x()==p,"upgrade cards hold the target")
 game.mode="play";game.set_aim(fx.target_x()+TimingStrike.WINDOW_HALF);check(fx.in_window(),"inclusive timing window edge is attainable")
 game.set_aim(fx.target_x()+TimingStrike.WINDOW_HALF+0.1);check(not fx.in_window(),"outside the narrow window is an ordinary release")
 fixture();fx=game.timing_strike;game.set_aim(270);game.drop_ammo()
 check(fx.perfect_count==1 and game.pending_balls.size()==12,"perfect release keeps the ordinary twelve units and one attempt")
 var golden=0
 for pending in game.pending_balls:golden+=int(pending["perfect"])
 check(golden==1 and fx.charge==0,"one gold representative is queued; no reward before collection")
 var target=fx.target_x();fx.update(0.5);check(fx.target_x()==target,"target holds still for the captured salvo")
 game.drop_ammo();check(fx.perfect_count==1,"repeated input during a salvo cannot create another perfect reward")
 game.emit_pending_balls(0)
 var ball=game.pool[0]
 check(ball.live and ball.perfect and ball.perfect_ticket and ball.collision_mask==0,"gold ball actually bypasses physical obstacles")
 game.layout["gates"][0]["left"]=3;game.layout["gates"][0]["right"]=3
 game.layout["gates"][1]["left"]=3;game.layout["gates"][1]["right"]=3
 game.multiply_ball(ball,0)
 var weight=0;var tickets=0;var copies=0
 for unit in game.pool:
  if unit.live:
   weight+=unit.weight;tickets+=int(unit.perfect_ticket);copies+=int(unit.perfect)
 check(weight==int(game.layout["gates"][0]["right"]),"gold uses the exact existing multiplier mathematics")
 # Force a second multiplication to exercise representative splitting.
 game.multiply_ball(ball,1);tickets=0;copies=0
 for unit in game.pool:
  if unit.live:tickets+=int(unit.perfect_ticket);copies+=int(unit.perfect)
 check(tickets==1 and copies>=2,"split representatives inherit penetration but never duplicate the charge ticket")
 game.collect_ball(ball);check(fx.charge==12,"gold collection grants exactly twelve percent")
 var produced=game.produced;game.collect_ball(ball)
 check(fx.charge==12 and game.produced==produced,"collecting a deactivated body cannot grant charge or ammo twice")
 for unit in game.pool:
  if unit.live:game.collect_ball(unit)
 check(fx.charge==12,"gold descendants do not multiply the perfect reward")
 fixture();fx=game.timing_strike;game.set_aim(90);game.drop_ammo()
 check(fx.perfect_count==0,"a missed window still allows a normal physical drop")
 fixture();fx=game.timing_strike;game.ammo=int(game.stats["capacity"])-3
 game.emit_ball(Vector2(200,852),Vector2.ZERO,23);game.collect_ball(game.pool[0])
 check(game.ammo==int(game.stats["capacity"]) and game.drop_overflow==20 and fx.charge==10,"actual collector overflow converts two excess units to one percent")
 fx.add_overflow(1);check(fx.charge==10.5,"odd overflow units retain their half-percent remainder")
 fx.add_overflow(-4);check(fx.charge==10.5,"negative overflow cannot change charge")
 fx.add_overflow(2147483647);check(fx.charge==100,"huge virtual overflow stays bounded at one stored attack")
 game.mode="pause";fx.add_overflow(10);fx.activate();check(fx.charge==100 and not fx.busy(),"pause cannot earn or spend orbital charge")
 game.mode="play";fx.activate();check(fx.charge==100 and not fx.busy(),"no visible target means no charge consumed")
 var offscreen=enemy(560);fx.activate();check(not fx.busy() and fx.charge==100,"offscreen arrivals are not orbital targets")
 var target_enemy=enemy();fx.activate();check(fx.busy() and fx.charge==0 and target_enemy["hp"]==500,"activation consumes once and announces before damage")
 fx.add_overflow(200);fx.activate();check(fx.charge==100,"recharging during an active attack cannot bypass the input guard")
 fx.update(0.2);check(target_enemy["hp"]==500,"warning window contains no hidden early damage")
 game.mode="pause";var age=fx.strike_age;fx.update(5);check(fx.strike_age==age and target_enemy["hp"]==500,"pause freezes attack countdown and damage")
 game.mode="play";fx.update(0.25)
 check(is_equal_approx(target_enemy["hp"],452.5) and offscreen["hp"]==500,"detonation hits real visible targets with the documented damage")
 var hp=target_enemy["hp"];fx.update(0.1);check(target_enemy["hp"]==hp,"beam animation cannot repeat damage")
 fx.update(1);check(not fx.busy() and not fx.can_activate(),"finished beam retains its eight-second cooldown")
 fx.update(8);check(fx.can_activate(),"cooldown expires in active game time")
 fixture();fx=game.timing_strike;game.level=100
 var boss=enemy(320,100,true);fx.add_overflow(200);fx.activate();fx.update(TimingStrike.WARNING)
 check(is_equal_approx(boss["hp"],88),"boss damage is capped at twelve percent of maximum health")
 fixture();fx=game.timing_strike
 var victim=enemy(320,10);fx.add_overflow(200);fx.activate();fx.update(TimingStrike.WARNING)
 var kills=game.run_kills;var coins=game.profile.data["coins"]
 fx.update(0.1)
 check(victim["dead"] and kills==1 and game.run_kills==1 and game.profile.data["coins"]==coins,"orbital kills use ordinary rewards exactly once")
 fixture();fx=game.timing_strike;enemy();fx.add_overflow(200);fx.activate()
 game.remaining=0;game.enemies.clear();game.wave_delay=0.89;game.update_combat(0.05)
 check(game.mode=="play","wave transition waits for an active strike instead of dropping its effect")
 fx.update(2);game.update_combat(0.05);check(game.mode=="upgrade","completed strike releases normal wave progression")
 game.start_level(1);freeze_tree(game);fx=game.timing_strike
 check(fx.charge==0 and not fx.busy() and fx.perfect_count==0 and fx.cooldown==0,"new deployment resets all run-local rewards and cooldown")
 if "--render" in OS.get_cmdline_user_args():await render_checks()
 if "--film" in OS.get_cmdline_user_args():await film()
 print("TIMING STRIKE RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(1 if failures else 0)
func render_checks() -> void:
 fixture();var fx=game.timing_strike;enemy(315);enemy(440)
 InterfaceMotion.cancel(game.controls);game.set_process(true);fx.set_process(true)
 await process_frame
 pointer(Vector2(120,914),true);pointer(Vector2(120,914),false)
 check(game.pending_balls.size()==12 and fx.perfect_count==1,"native drop button creates a genuinely perfect salvo inside the window")
 game.emit_pending_balls(0);game.pool[0].teleport_to(Vector2(270,565),Vector2(0,180));game.pool[0].reset_pending=false
 game.ball_visuals.queue_redraw()
 var before=await image_frame();before.save_png("res://builds/perfect-drop-v0.2.12.png")
 check(game.pool[0].perfect and before.get_pixel(270,565).r>0.7,"real renderer shows the bright gold ball core")
 fx.add_overflow(200);await process_frame
 pointer(Vector2(442,380),true);pointer(Vector2(442,380),false)
 check(fx.busy() and fx.charge==0,"native orbital HUD button starts an actual charged attack")
 fx.update(TimingStrike.WARNING+0.08);game.blood_fx.hide();game.combat_motion.hide()
 freeze_tree(game)
 for ball in game.pool:
  if ball.live:ball.freeze=true
 InterfaceMotion.cancel(game.controls)
 fx.painter.hide();before=await image_frame();fx.painter.show();var after=await image_frame()
 check(differences(before,after,Rect2i(250,121,240,229))>1500,"orbital columns and impact rings are substantial at native phone resolution")
 check(differences(before,after,Rect2i(0,0,540,121))+differences(before,after,Rect2i(0,350,540,610))==0,"orbital stage effects never cover HUD or physical reactor")
 after.save_png("res://builds/orbital-strike-v0.2.12.png")
 game.profile.data["settings"]["reduced_motion"]=true;game.quality=0
 fx.painter.hide();before=await image_frame();fx.painter.show();after=await image_frame()
 check(differences(before,after,Rect2i(250,121,240,229))>400,"low quality and reduced motion retain readable orbital effects")
func film() -> void:
 fixture();enemy(315,1500);enemy(440,1500)
 # Controlled visual demonstration: high-health stationary targets and a full
 # inventory and 4x collection make overflow repeatable, not earned play.
 game.ammo=int(game.stats["capacity"])-4;game.stats["collection"]=4;game.set_aim(270)
 game.set_process(true);game.set_physics_process(true)
 game.bonus_ops.set_process(false);game.timing_strike.set_process(true)
 for frame in range(480):
  if frame==35:
   # Waited intercept is exercised by the render test; this fixture aligns the
   # moving target for a readable full sequence in the demonstration video.
   game.set_aim(game.timing_strike.target_x());pointer(Vector2(130,914),true)
  if frame==37:pointer(Vector2(130,914),false)
  if frame==300 and game.timing_strike.can_activate():pointer(Vector2(442,380),true)
  if frame==302:pointer(Vector2(442,380),false)
  await process_frame
 check(game.timing_strike.perfect_count>0,"film includes an actual perfect drop")
 check(game.timing_strike.cooldown>0,"film includes an actual orbit attack")
