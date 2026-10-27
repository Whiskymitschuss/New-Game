extends SceneTree
# Isolated presentation checks; no game timings or combat values are changed by FX.
class StubGame extends Node2D:
 var mode="play"
 var quality=1
 var rng=RandomNumberGenerator.new()
 var profile=Profile.new()
 var future
 func _draw() -> void:draw_rect(Rect2(0,0,540,960),Color("081020"))
var checks=0
var failures=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func run() -> void:
 var game=StubGame.new();root.add_child(game)
 var fx=load("res://scripts/combat_motion.gd").new();fx.game=game;game.add_child(fx)
 fx.set_process(false)
 var gameplay_rng=game.rng.state
 var enemy={"type":2,"x":405.0,"y":320.0,"age":0.4,"speed":17.0,"flash":0.12,"hp":0.0,"boss":false}
 var snapshot=enemy.duplicate(true)
 fx.on_shot(Vector2(405,290),0,true)
 check(fx.recoil>0 and fx.hero_pose()["offset"].x<0,"shot produces immediate hero recoil")
 check(fx.particles.size()==1 and fx.particles[0]["kind"]=="shell","ballistic shot ejects a visible casing")
 check(fx.hero_pose()["scale"]!=Vector2.ONE,"shot uses a squash/return pose rather than a static tint")
 var pose=fx.enemy_pose(enemy)
 check(pose["offset"].x>0 and pose["scale"]!=Vector2.ONE,"hit enemy has visual recoil and body compression")
 check(enemy==snapshot,"pose calculation preserves enemy positions and combat state")
 fx.on_death(enemy)
 check(fx.corpses.size()==1,"a real kill retains a short death animation")
 enemy["x"]=100.0
 check(fx.corpses[0]["at"].x==405,"death visual snapshots position without retaining the live dictionary")
 fx.on_special();fx.on_hurt()
 check(fx.special>0 and fx.hurt>0 and fx.trauma>0,"special and damage have separate visual envelopes")
 check(fx.clipper.clip_contents and fx.clipper.position==Vector2(0,121) and fx.clipper.size==Vector2(540,229),"effect canvas clips exactly to combat stage")
 for quality in [0,1]:
  game.quality=quality;fx.reset()
  for i in range(400):
   fx.on_shot(Vector2(350+i%100,270),i%12,i%5==0)
   fx.on_hit(Vector2(130+(i%30)*12,160+(i%11)*14),i%7==0)
   fx.on_death(snapshot)
  check(fx.events.size()<=(20 if quality==1 else 10),"effect events obey quality budget")
  check(fx.particles.size()<=(90 if quality==1 else 32),"casings and sparks obey quality budget")
  check(fx.corpses.size()<=(12 if quality==1 else 5),"death sprites obey quality budget")
 check(gameplay_rng==game.rng.state,"presentation randomness never consumes gameplay RNG")
 var clock=fx.clock;var age=fx.events[0]["age"]
 game.mode="pause";fx._process(0.4)
 check(fx.clock==clock and fx.events[0]["age"]==age and not fx.visible,"pause freezes and hides combat presentation")
 game.mode="upgrade";fx._process(0.4)
 check(fx.clock==clock and fx.events[0]["age"]==age,"upgrade picker freezes transient combat presentation")
 game.mode="play";fx._process(1.0)
 check(fx.events.is_empty() and fx.particles.is_empty() and fx.corpses.is_empty(),"short combat effects expire completely after resuming")
 check(fx.visible,"combat effects become visible again when play resumes")
 fx.reset();game.profile.data["settings"]["reduced_motion"]=true
 fx.on_shot(Vector2(300,290),0,true);fx.on_special();fx.on_hit(Vector2(300,290),true)
 check(fx.hero_pose()["offset"]==Vector2.ZERO and fx.hero_pose()["scale"]==Vector2.ONE and fx.camera_offset()==Vector2.ZERO,"reduced motion suppresses recoil, breathing and camera displacement")
 check(fx.enemy_pose(snapshot)["offset"]==Vector2.ZERO and fx.enemy_pose(snapshot)["scale"]==Vector2.ONE,"reduced motion preserves static enemy poses")
 check(fx.particles.is_empty() and not fx.events.is_empty(),"reduced motion keeps essential local hit flashes while suppressing flying particles")
 fx.reset()
 check(fx.events.is_empty() and fx.corpses.is_empty() and fx.particles.is_empty() and fx.recoil==0 and fx.special==0,"new run reset clears all presentation state")
 if "--render" in OS.get_cmdline_user_args():
  game.profile.data["settings"]["reduced_motion"]=false
  fx.on_hit(Vector2(200,349),true);fx.on_hit(Vector2(200,122),true);fx.on_special()
  await process_frame
  await RenderingServer.frame_post_draw
  var pixels=root.get_texture().get_image()
  var inside=pixels.get_pixel(200,347);var below=pixels.get_pixel(200,360);var lower_base=pixels.get_pixel(200,420)
  var above=pixels.get_pixel(200,112);var upper_base=pixels.get_pixel(200,30)
  check(inside.r+inside.g+inside.b>below.r+below.g+below.b+0.25,"real renderer draws a readable combat hit flare")
  check(absf(below.r-lower_base.r)+absf(below.g-lower_base.g)+absf(below.b-lower_base.b)<0.02,"combat flare cannot spill into resource HUD or factory")
  check(absf(above.r-upper_base.r)+absf(above.g-upper_base.g)+absf(above.b-upper_base.b)<0.02,"combat flare cannot spill into upper HUD")
  pixels.save_png("res://builds/combat-motion-clipping.png")
 print("COMBAT MOTION RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;quit(0 if failures==0 else 1)
