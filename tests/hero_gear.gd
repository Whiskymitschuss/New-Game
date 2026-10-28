extends SceneTree
var game
var checks=0
var failures=0
class GearPainter extends Node2D:
 var fixtures: Array = []
 var equipped=false
 func _draw() -> void:
  draw_rect(Rect2(0,0,540,960),Color("071418"))
  for row in range(2):
   for cls in range(3):
    var actor=fixtures[cls]
    var texture=actor.future.heroes
    var source=actor.future.frame_region("heroes",cls,texture,3,1)
    var base=Vector2(100+cls*170,295+row*355)
    ActorRig.draw_hero(self,texture,source,base,179.2,Color.WHITE,0,-1,true,1)
    if equipped and row==1:HeroGear.draw(self,actor,base,1.6,{"offset":Vector2.ZERO,"angle":0.0,"scale":Vector2.ONE})
  var face=load("res://assets/fonts/JetBrainsMono.ttf")
  draw_string(face,Vector2(25,65),"BASIS / IDENTISCHE KLASSEN",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("99adaa"))
  draw_string(face,Vector2(25,420),"NACH ECHTEN UPGRADE-KARTEN",HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("91d6cf"))
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func upgrade_key(key: String) -> int:
 for i in range(Content.UPGRADES.size()):
  if Content.UPGRADES[i][2]==key:return i
 return -1
func run() -> void:
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.profile.reset();game.start_level(1)
 var initial=HeroGear.gear_state(game)
 check(initial["belt"]==0 and initial["armor"]==0 and initial["weapon"]==0 and not initial["medic"],"new hero has no unearned upgraded equipment")
 var before=game.profile.data.duplicate(true);var rng_before=game.rng.state
 var stats=game.stats.duplicate(true)
 HeroGear.gear_state(game)
 check(game.profile.data==before and game.stats==stats and game.rng.state==rng_before,"gear inspection preserves progression, combat values and random stream")
 game.apply_upgrade(upgrade_key("capacity"))
 check(HeroGear.gear_state(game)["belt"]==1,"actual capacity upgrade adds a visible ammunition belt")
 game.apply_upgrade(upgrade_key("magazine"))
 check(HeroGear.gear_state(game)["belt"]==2,"actual magazine upgrade increases carried gear")
 game.apply_upgrade(upgrade_key("armor"))
 check(HeroGear.gear_state(game)["armor"]==1,"actual armor card adds shoulder and chest plates")
 game.apply_upgrade(upgrade_key("armor"))
 check(HeroGear.gear_state(game)["armor"]==2,"stacked armor visibly reinforces the plates")
 game.apply_upgrade(upgrade_key("thorns"))
 check(HeroGear.gear_state(game)["thorns"],"contact damage upgrade adds real armor spikes")
 game.apply_upgrade(upgrade_key("damage"))
 check(HeroGear.gear_state(game)["weapon"]>0,"damage card adds weapon tuning detail")
 game.apply_upgrade(upgrade_key("regen"))
 check(HeroGear.gear_state(game)["medic"],"regeneration upgrade mounts a medical module")
 game.apply_upgrade(upgrade_key("shield"))
 check(HeroGear.gear_state(game)["shield"],"shield indicator reflects actual remaining protection")
 game.shield=0
 check(not HeroGear.gear_state(game)["shield"],"depleted shield cannot retain an active protection light")
 game.start_level(1)
 var reset=HeroGear.gear_state(game)
 check(reset["belt"]==0 and reset["armor"]==0 and not reset["thorns"] and not reset["medic"],"new level removes only the expired run gear")
 game.apply_upgrade(upgrade_key("drop"))
 check(HeroGear.gear_state(game)["belt"]==1,"real larger-drop card adds visible carried ammunition gear")
 game.start_level(1)
 game.profile.data["coins"]=1000
 check(Progression.upgrade_weapon(game.profile.data,0),"test buys an actual permanent pistol upgrade")
 game.start_level(1)
 check(HeroGear.gear_state(game)["rank"]==1 and HeroGear.gear_state(game)["weapon"]==1,"real permanent weapon rank remains visible on a new deployment")
 for cls in range(3):
  game.profile.data["class"]=cls;game.start_level(1)
  check(not HeroGear.gear_state(game)["medic"] and HeroGear.gear_state(game)["class"]==cls,"natural class regeneration does not fabricate a medical upgrade")
 var motion=game.combat_motion.hero_pose()
 game.deployment_age=0.2
 var pose=HeroGear.attachment_pose(game,Vector2(94,340),1.1,motion)
 var arrived=pose["transform"].origin
 game.deployment_age=2
 var fixed=HeroGear.attachment_pose(game,Vector2(94,340),1.1,motion)
 check(arrived.x<fixed["transform"].origin.x,"equipment follows the same short hero arrival step")
 game.profile.data["settings"]["reduced_motion"]=true
 game.deployment_age=0.1
 var quiet=HeroGear.attachment_pose(game,Vector2(94,340),1.1,game.combat_motion.hero_pose())
 check(quiet["transform"].origin==Vector2(94,340) and quiet["upper"]==Vector2.ZERO and quiet["hip"]==Vector2.ZERO,"reduced motion keeps attachments fixed and retains the actual gear")
 if "--render" in OS.get_cmdline_user_args():
  root.size=Vector2i(540,960)
  game.hide();game.controls.hide();game.set_process(false);game.set_physics_process(false)
  var fixtures=[]
  for cls in range(3):
   var actor=load("res://main.tscn").instantiate();root.add_child(actor);await process_frame
   actor.profile.reset();actor.profile.data["class"]=cls;actor.start_level(1)
   actor.profile.data["settings"]["reduced_motion"]=true
   actor.combat_motion.reset();actor.combat_motion.clock=0;actor.combat_motion.set_process(false)
   for key in ["capacity","armor","thorns","damage","regen"]:actor.apply_upgrade(upgrade_key(key))
   actor.mode="menu";actor.set_process(false);actor.set_physics_process(false)
   actor.hide();actor.controls.hide();fixtures.append(actor)
  var painter=GearPainter.new();painter.fixtures=fixtures;root.add_child(painter)
  await process_frame;await RenderingServer.frame_post_draw
  var before_pixels=root.get_texture().get_image()
  painter.equipped=true;painter.queue_redraw()
  await process_frame;await RenderingServer.frame_post_draw
  var after_pixels=root.get_texture().get_image()
  var changed=0;var face_changed=0
  for cls in range(3):
   var local_changed=0
   for y in range(485,570):
    for x in range(40+cls*170,160+cls*170):
     var a=before_pixels.get_pixel(x,y);var b=after_pixels.get_pixel(x,y)
     if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.15:local_changed+=1
   check(local_changed>60,"real equipment remains visible on each of the three class silhouettes")
   changed+=local_changed
   for y in range(474,488):
    for x in range(86+cls*170,104+cls*170):
     var a=before_pixels.get_pixel(x,y);var b=after_pixels.get_pixel(x,y)
     if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.08:face_changed+=1
  check(changed>200,"real renderer shows substantial body-mounted armor, ammunition and weapon details")
  check(face_changed==0,"new equipment preserves the original face and visor pixels")
  after_pixels.save_png("res://builds/hero-gear-proof.png")
  painter.queue_free()
  for actor in fixtures:actor.queue_free()
  await process_frame
 print("HERO GEAR RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;OS.delay_msec(100);await process_frame;quit(1 if failures else 0)
