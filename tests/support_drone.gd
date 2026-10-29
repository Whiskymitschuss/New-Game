extends SceneTree
class StubGame extends Node2D:
 var mode="play"
 var quality=1
 var profile=Profile.new()
 var rng=RandomNumberGenerator.new()
 var stats={"drone":1.0,"damage":1.0}
 func _draw() -> void:draw_rect(Rect2(0,0,540,960),Color("08151c"))
var checks=0
var failures=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func run() -> void:
 var game=StubGame.new();root.add_child(game)
 var drone=load("res://scripts/support_drone.gd").new();drone.game=game;game.add_child(drone)
 drone.set_process(false)
 var before=game.stats.duplicate(true);var rng_before=game.rng.state
 check(drone.running() and drone.visible,"actual support stat makes a combat craft visible")
 check(drone.clipper.clip_contents and drone.clipper.position==Vector2(0,121) and drone.clipper.size==Vector2(540,229),"drone draws only inside the combat stage")
 check(drone.position_for()==Vector2(132,192),"new craft has a deliberate anchor above the hero helmet")
 var origin=drone.muzzle_position()
 check(origin==Vector2(160,198),"neutral tracer origin is the actual forward gun muzzle")
 var target=Vector2(420,310)
 drone.on_shot(target)
 check(drone.shot_left==0.16 and drone.recoil>0 and drone.aim_angle>0,"a real shot produces a brief flash, recoil and target bank")
 check(drone.target==target and drone.muzzle_position()!=origin,"shot source follows the same banked body pose")
 var clock=drone.clock;var held=drone.shot_left;var held_recoil=drone.recoil
 for mode in ["pause","upgrade","victory","menu"]:
  game.mode=mode;drone._process(2);drone.on_shot(Vector2(20,20))
  check(not drone.visible and drone.clock==clock and drone.shot_left==held and drone.recoil==held_recoil,"noncombat mode hides and freezes the craft without a phantom shot")
 game.mode="play";drone._process(0.4)
 check(drone.visible and drone.shot_left==0 and drone.recoil==0,"combat resumes and finite flash/recoil expire")
 var within_hover=true
 for i in range(200):
  drone.on_shot(Vector2(10 if i%2 else 530,121 if i%3 else 349));drone._process(0.016)
  within_hover=within_hover and drone.position_for().distance_to(Vector2(132,192))<4.0 and absf(drone.angle_for())<=0.13
 check(within_hover,"a sustained 200-shot sweep retains a restrained hovering silhouette")
 check(game.stats==before and game.rng.state==rng_before,"drone art cannot mutate damage, support level or gameplay RNG")
 game.stats["drone"]=0;drone._process(1)
 check(not drone.visible and not drone.running(),"no upgrade means no phantom support drone")
 game.stats["drone"]=1;game.profile.data["settings"]["reduced_motion"]=true;drone.reset()
 drone.on_shot(Vector2(420,310));drone._process(0.03)
 check(drone.position_for()==Vector2(132,192) and drone.angle_for()==0 and drone.recoil==0,"reduced motion fixes the hover and suppresses recoil and bank")
 check(drone.shot_left>0 and drone.muzzle_position()==Vector2(160,198),"reduced motion retains the essential real muzzle flash")
 drone.reset()
 check(drone.clock==0 and drone.recoil==0 and drone.shot_left==0 and drone.target==Vector2.ZERO,"new deployment clears old aiming and firing presentation")
 if "--render" in OS.get_cmdline_user_args():
  root.size=Vector2i(540,960)
  await process_frame;await RenderingServer.frame_post_draw
  var pixels=root.get_texture().get_image()
  var colored=0
  for y in range(176,213):
   for x in range(103,163):
    var color=pixels.get_pixel(x,y)
    if color.r+color.g+color.b>0.8:colored+=1
  check(colored>100,"actual renderer shows substantial detailed drone body pixels")
  check(pixels.get_pixel(132,220)==pixels.get_pixel(20,220),"new craft clears the hero helmet below its hover position")
  pixels.save_png("res://builds/support-drone-proof.png")
 print("SUPPORT DRONE RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(1 if failures else 0)
