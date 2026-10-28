extends SceneTree
# Real PhysicsServer movement and the same pooled rigid body on both slopes.
class StubGame extends Node2D:
 var mode="play"
 var drop_running=false
 var pending_balls: Array=[]
 var live_count=0
 var attempts=3
 var ammo=45
 var stats={"damage":1.25,"armor":0.0}
 var rng=RandomNumberGenerator.new()
 func active_balls() -> int:return live_count
var checks=0
var failures=0
var game
var lever
var ramp
var ball
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func advance(frames: int) -> void:
 for frame in range(frames):
  lever.update(1.0/60.0)
  await physics_frame
func flight() -> Vector2:
 ball.activate(Vector2(270,530),Vector2.ZERO,7,5)
 game.live_count=1
 for tick in range(240):
  lever.update(1.0/60.0)
  await physics_frame
  if not ball.reset_pending and ball.position.y>720:return ball.position
 return ball.position
func run() -> void:
 game=StubGame.new();root.add_child(game);game.rng.seed=7013
 var random_before=game.rng.state
 var stats_before=game.stats.duplicate(true)
 ramp=AnimatableBody2D.new();ramp.position=Vector2(270,603)
 var shape=RectangleShape2D.new();shape.size=Vector2(77,9)
 var collider=CollisionShape2D.new();collider.shape=shape;ramp.add_child(collider)
 game.add_child(ramp)
 ball=AmmoBall.new();game.add_child(ball)
 lever=ReactorSwitch.new();lever.game=game;lever.attach_body(ramp,1)
 await advance(3)
 check(is_equal_approx(ramp.rotation,0.4),"new switch begins as a right-sloping real ramp")
 check(not lever.can_toggle() and not lever.toggle(),"idle controls cannot move the collider")
 game.drop_running=true;game.pending_balls=[{}];lever.begin_drop()
 check(lever.can_toggle(),"an accepted queued drop enables one switch action")
 check(lever.caption().contains("←") and lever.caption().contains("1×"),"caption names the available opposite direction and single use")
 check(lever.toggle(),"queued balls permit the one active-drop switch press")
 check(not lever.toggle() and not lever.can_toggle() and lever.spent,"repeated taps cannot move the switch twice in one drop")
 lever.update(0.09)
 # AnimatableBody publishes a requested transform on the next physics sync.
 await physics_frame;await physics_frame
 check(ramp.rotation<0.4 and ramp.rotation> -0.4 and lever.turning,"physical rotation interpolates instead of jumping between endpoints")
 var paused_angle=ramp.rotation
 game.mode="pause";lever.update(1)
 check(ramp.rotation==paused_angle,"pause freezes a partly turned physical ramp")
 game.mode="upgrade";lever.update(1)
 check(ramp.rotation==paused_angle,"upgrade decisions freeze switch motion")
 game.mode="play";await advance(12)
 check(is_equal_approx(ramp.rotation,-0.4) and not lever.turning,"resuming finishes the left slope within a bounded turn")
 var server_pose: Transform2D=PhysicsServer2D.body_get_state(ramp.get_rid(),PhysicsServer2D.BODY_STATE_TRANSFORM)
 check(is_equal_approx(server_pose.get_rotation(),-0.4),"switch changes the actual PhysicsServer collider transform")
 check(game.ammo==45 and game.attempts==3 and game.stats==stats_before and game.rng.state==random_before,"pressing the switch never buys a drop or changes resources, stats or gameplay RNG")
 lever.end_drop();game.drop_running=false;game.pending_balls=[]
 check(not lever.toggle() and not lever.can_toggle(),"finishing a drop does not grant a free idle turn")
 game.drop_running=true;game.live_count=1;lever.begin_drop()
 check(lever.can_toggle() and not lever.spent,"only the next accepted drop renews the one-use action")
 check(lever.toggle(),"live balls can activate the next drop's switch")
 await advance(15)
 check(is_equal_approx(ramp.rotation,0.4),"a second accepted drop can restore the original right slope")
 game.pending_balls=[];game.live_count=0
 var right: Vector2=await flight()
 check(right.y>720 and right.x>285,"right slope sends the actual rigid body into the right corridor")
 check(ball.weight==7 and ball.gates==5,"physical deflection preserves represented cargo and visited multiplier mask")
 ball.deactivate();game.live_count=0
 game.pending_balls=[{}];lever.end_drop();lever.begin_drop();lever.toggle()
 await advance(15)
 var left: Vector2=await flight()
 check(left.y>720 and left.x<255,"left slope sends the same pooled rigid body into the left corridor")
 check(right.x-left.x>40,"opposite switch positions produce meaningfully different real trajectories")
 check(ball.weight==7 and ball.gates==5,"reusing the switch and ball cannot duplicate or erase ammunition")
 game.live_count=0;game.pending_balls=[];lever.end_drop();lever.begin_drop()
 check(not lever.can_toggle(),"an empty queue and no live balls cannot consume a switch charge")
 game.live_count=1;game.mode="pause"
 check(not lever.toggle(),"paused input cannot spend a prepared switch charge")
 game.mode="play";lever.reset()
 check(lever.body==null and not lever.armed and not lever.spent and lever.direction==1,"new-level reset detaches old geometry and restores the default direction")
 check(not lever.can_toggle(),"detached old geometry cannot be operated")
 print("REACTOR SWITCH RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;OS.delay_msec(120);await process_frame
 quit(1 if failures else 0)
