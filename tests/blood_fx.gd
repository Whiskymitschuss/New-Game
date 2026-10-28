extends SceneTree
# Isolated blood snapshots are presentation-only; native combat does the damage.
class StubGame extends Node2D:
 var mode="play"
 var quality=1
 var profile=Profile.new()
 var rng=RandomNumberGenerator.new()
 func _draw() -> void:draw_rect(Rect2(0,0,540,960),Color("081020"))
var checks=0
var failures=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func run() -> void:
 root.size=Vector2i(540,960)
 var game=StubGame.new();root.add_child(game);game.rng.seed=9304
 var fx=load("res://scripts/blood_fx.gd").new();fx.game=game;game.add_child(fx);fx.set_process(false)
 var enemy={"type":0,"x":350.0,"y":320.0,"boss":false,"hp":17.0,"speed":20.0}
 var original=enemy.duplicate(true);var rng_before=game.rng.state
 fx.on_hit(enemy)
 check(fx.particles.size()==9 and fx.bursts.size()==1,"hit emits a bounded directional blood spray")
 check(fx.particles[0]["vel"].x>0 and fx.particles[0]["vel"].y<20,"bullet blood travels away from the firing hero")
 var velocity: Vector2=fx.particles[0]["vel"]
 fx._process(0.05)
 check(fx.particles[0]["vel"].y>velocity.y,"droplets fall under visual gravity")
 fx.on_death(enemy)
 check(fx.stains.size()>0 and fx.stains[0]["shape"].size()>=10,"death creates an irregular floor pool")
 check(float(fx.stains[0]["life"])==12.0,"blood persists for twelve seconds before removal")
 check(enemy==original and game.rng.state==rng_before,"blood snapshots preserve enemy state and gameplay random stream")
 var age=fx.stains[0]["age"];var clock=fx.clock
 game.mode="pause";fx._process(0.5)
 check(not fx.visible and fx.clock==clock and fx.stains[0]["age"]==age,"pause freezes and hides blood")
 game.mode="upgrade";fx._process(0.5)
 check(fx.clock==clock and fx.stains[0]["age"]==age,"upgrade choice freezes blood and stain age")
 game.mode="play";fx._process(0.05)
 check(fx.visible and fx.clock>clock,"resuming makes blood visible and advances effects")
 fx.reset();fx.on_hero_hurt()
 check(fx.particles.size()>0 and fx.particles[0]["vel"].x<0,"real hero injury sprays toward the attacked side")
 fx.reset()
 var robot=enemy.duplicate(true);robot["type"]=13
 fx.on_hit(robot,true);fx.on_death(robot)
 check(fx.bursts[0]["oil"] and fx.particles[0]["oil"] and fx.stains[0]["oil"],"robot hits use oil and coolant rather than blood")
 for quality in [1,0]:
  game.quality=quality;fx.reset()
  for i in range(300):
   var at=enemy.duplicate(true);at["x"]=20+(i%25)*20;at["y"]=280+(i%4)*16
   fx.on_hit(at,i%2==0);fx.on_death(at)
  check(fx.particles.size()<=(128 if quality==1 else 48),"airborne droplets respect the chosen quality budget")
  check(fx.stains.size()<=(36 if quality==1 else 16),"floor pools respect the chosen quality budget")
  check(fx.bursts.size()<=(16 if quality==1 else 8),"impact fans respect the chosen quality budget")
 game.quality=1;fx.reset();fx.on_death(enemy)
 for i in range(30):fx._process(0.05)
 check(fx.particles.is_empty() and fx.bursts.is_empty() and not fx.stains.is_empty(),"moving sprays finish while landed pools remain")
 fx._process(12.1)
 check(fx.stains.is_empty(),"all old pools expire without accumulating across waves")
 fx.reset();game.profile.data["settings"]["reduced_motion"]=true
 fx.on_hit(enemy);fx.on_death(enemy);fx.on_hero_hurt()
 check(fx.particles.is_empty() and not fx.bursts.is_empty() and not fx.stains.is_empty(),"reduced motion keeps local feedback without flying drops")
 check(float(fx.stains[0]["life"])<=1.2,"reduced motion uses brief local stains")
 game.profile.data["settings"]["blood_fx"]=false;fx._process(0.1)
 fx.on_hit(enemy);fx.on_death(enemy);fx.on_hero_hurt()
 check(not fx.visible and fx.particles.is_empty() and fx.stains.is_empty() and fx.bursts.is_empty(),"blood option clears existing effects and prevents new blood")
 check(fx.clipper.clip_contents and fx.clipper.position==Vector2(0,121) and fx.clipper.size==Vector2(540,229) and fx.clipper.mouse_filter==Control.MOUSE_FILTER_IGNORE,"blood canvas clips to combat without intercepting input")
 game.profile.data["settings"]["blood_fx"]=true;game.profile.data["settings"]["reduced_motion"]=false
 if "--render" in OS.get_cmdline_user_args():
  fx.reset();fx.add_stain(Vector2(200,349),30);fx.spray(Vector2(200,123),320,1,2)
  # This isolated test disables automatic processing. Resume the same visibility
  # update that the real game performs after turning the blood option back on.
  fx.on_hit(enemy,true);fx._process(0.0)
  await process_frame;await RenderingServer.frame_post_draw
  var pixels=root.get_texture().get_image();var red_pixels=0
  for y in range(121,350):
   for x in range(180,410):
    var c=pixels.get_pixel(x,y)
    if c.r>0.23 and c.r>c.g*1.7 and c.r>c.b*1.4:red_pixels+=1
  check(red_pixels>80,"real renderer shows readable red splatters and wet pools")
  var below=pixels.get_pixel(200,358);var reference=pixels.get_pixel(200,420)
  var above=pixels.get_pixel(200,112);var top_reference=pixels.get_pixel(200,30)
  check(absf(below.r-reference.r)+absf(below.g-reference.g)+absf(below.b-reference.b)<0.01,"blood never spills into resources or factory")
  check(absf(above.r-top_reference.r)+absf(above.g-top_reference.g)+absf(above.b-top_reference.b)<0.01,"blood never spills into the upper HUD")
  pixels.save_png("res://builds/blood-fx-clipping.png")
 fx.reset()
 check(fx.particles.is_empty() and fx.stains.is_empty() and fx.bursts.is_empty() and fx.clock==0,"new run reset removes all blood and visual clock")
 print("BLOOD FX RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;quit(1 if failures else 0)
