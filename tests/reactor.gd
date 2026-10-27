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
 game.start_level(1);game.set_physics_process(false)
 game.reactor_fx.set_process(false)
 # The large real touch control updates the slider without ever firing ammunition.
 var surface: Control=game.controls.get_child(game.controls.get_child_count()-1)
 var touch=InputEventScreenTouch.new();touch.pressed=true;touch.position=Vector2(380,100)
 var attempts=game.attempts
 surface.gui_input.emit(touch)
 check(game.aim==410 and game.aim_slider.value==410,"touch chamber and slider agree in local coordinates")
 check(game.attempts==attempts and game.pending_balls.is_empty(),"positioning does not accidentally drop")
 var drag=InputEventScreenDrag.new();drag.position=Vector2(-200,20)
 surface.gui_input.emit(drag)
 check(game.aim==50,"touch drag is clamped to the safe injection region")
 var mouse=InputEventMouseMotion.new();mouse.button_mask=MOUSE_BUTTON_MASK_LEFT;mouse.position=Vector2(470,70)
 surface.gui_input.emit(mouse)
 check(game.aim==490,"mouse drag follows the same input path")
 game.aim=410
 game.drop_ammo()
 game.emit_pending_balls(0.07)
 var after=game.attempts
 game.drop_ammo()
 check(game.attempts==after,"a running injection cannot consume another attempt")
 game.pending_balls.clear()
 game.drop_ammo()
 check(game.attempts==after,"live physical balls also prevent accidental duplicate drops")
 game.clear_balls();game.drop_running=false
 # Representative grouping must never change a fractional collection upgrade.
 game.ammo=0;game.stats["capacity"]=999;game.stats["collection"]=1.25
 for i in range(4):
  game.emit_ball(Vector2(180,854),Vector2.ZERO,1)
  game.collect_ball(game.pool[0])
 check(game.ammo==5,"four single units with +25% collect exactly five ammo")
 game.ammo=0;game.collection_remainder=0
 game.emit_ball(Vector2(180,854),Vector2.ZERO,4)
 game.collect_ball(game.pool[0])
 check(game.ammo==5,"grouped virtual mass gives the identical collection reward")
 game.ammo=998;game.drop_credited=0;game.drop_overflow=0
 game.emit_ball(Vector2(180,854),Vector2.ZERO,4)
 game.collect_ball(game.pool[0])
 check(game.ammo==999 and game.drop_credited==1 and game.drop_overflow==4,"accepted ammo and capacity overflow are distinguished exactly")
 # Bounded additive particles cannot alter gameplay RNG or mutate counts.
 var state=game.rng.state
 for quality in [0,1]:
  game.quality=quality;game.reactor_fx.reset()
  for i in range(250):
   game.reactor_fx.pulse(Vector2(40+(i%10)*48,520+(i/10%4)*80),Color.CYAN,"gate")
  check(game.reactor_fx.events.size()<=(24 if quality==1 else 10),"light flare budget obeys quality setting")
  check(game.reactor_fx.motes.size()<=(96 if quality==1 else 24),"spark budget obeys quality setting")
  game.reactor_fx.gate_hit(Vector2(140,560),0,0,3)
  check(game.reactor_fx.gate_charge[0]>0,"a real gate hit charges only its feedback channel")
 check(state==game.rng.state,"visual randomness never affects enemy or ball RNG")
 game.reactor_fx._process(0.7)
 check(game.reactor_fx.events.is_empty() and game.reactor_fx.motes.is_empty(),"transient effects expire instead of accumulating")
 game.reactor_fx.pulse(Vector2(180,600),Color.CYAN)
 var age=game.reactor_fx.events[0]["age"]
 game.pause_game();game.reactor_fx._process(0.4)
 check(not game.reactor_fx.visible and game.reactor_fx.events[0]["age"]==age,"pause hides and freezes reactor effects")
 game.mode="play";game.reactor_fx._process(0.6)
 check(game.reactor_fx.visible and game.reactor_fx.events.is_empty(),"resuming clears expired effects normally")
 print("REACTOR RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(0 if failures==0 else 1)
