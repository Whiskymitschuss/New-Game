extends SceneTree
# Controlled, disposable fixtures exercise real shot/combat hooks. Render
# comparisons isolate each presentation canvas from an otherwise frozen game.
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
func fixture() -> Dictionary:
 game.profile.reset();game.start_level(1)
 InterfaceMotion.cancel(game.controls)
 freeze_tree(game)
 game.enemies.clear();game.tracers.clear();game.sparks.clear();game.floats.clear()
 game.stats["crit"]=0;game.stats["recycle"]=0;game.stats["drone"]=0
 game.spawn_timer=999;game.fire_timer=999;game.remaining=1
 game.wave_banner=0;game.clock=3;game.deployment_age=2;game.screen_age=2
 game.ammo=6;game.magazine=12
 game.elemental_fx._process(0);game.support_drone._process(0)
 var enemy=game.spawn_enemy()
 enemy["type"]=0;enemy["x"]=325.0;enemy["y"]=325.0
 enemy["hp"]=1000.0;enemy["max_hp"]=1000.0
 enemy["speed"]=0.0;enemy["timer"]=99.0;enemy["age"]=2.0
 return enemy
func arm(kind: String) -> void:
 game.ammo_cargo.reset();game.ammo_cargo.begin_drop()
 if kind!="normal":game.ammo_cargo.add_refined(kind,6)
func image_frame() -> Image:
 game.queue_redraw()
 for i in range(2):await process_frame
 await RenderingServer.frame_post_draw
 return root.get_texture().get_image()
func distance(a: Color,b: Color) -> float:
 return absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
func pixel_changes(a: Image,b: Image,rect: Rect2i,threshold: float=0.15) -> int:
 var count=0
 for y in range(rect.position.y,rect.end.y):
  for x in range(rect.position.x,rect.end.x):
   if distance(a.get_pixel(x,y),b.get_pixel(x,y))>threshold:count+=1
 return count
func outside_changes(a: Image,b: Image) -> int:
 return pixel_changes(a,b,Rect2i(0,0,540,121),0.025)+pixel_changes(a,b,Rect2i(0,350,540,610),0.025)
func colored_changes(a: Image,b: Image,kind: String) -> int:
 var count=0
 for y in range(190,340):
  for x in range(250,405):
   var pixel=b.get_pixel(x,y)
   if distance(a.get_pixel(x,y),pixel)<0.15:continue
   if kind=="fire" and pixel.r>0.45 and pixel.r>pixel.g*1.15 and pixel.r>pixel.b*1.3:count+=1
   elif kind=="frost" and pixel.g>0.4 and pixel.b>pixel.r*1.12:count+=1
   elif kind=="emp" and pixel.b>0.45 and pixel.r>pixel.g*1.1:count+=1
 return count
func render_checks() -> void:
 for kind in SpecialAmmo.KINDS:
  var enemy=fixture();arm(kind);game.shoot()
  game.combat_motion.hide();game.blood_fx.hide()
  game.elemental_fx._process(0.09);game.elemental_fx.hide()
  var before=await image_frame()
  game.elemental_fx.show();game.elemental_fx.painter.queue_redraw()
  var after=await image_frame()
  check(pixel_changes(before,after,Rect2i(250,190,155,150))>150,"actual %s shot and status produce a body-sized visible effect"%kind)
  check(colored_changes(before,after,kind)>35,"actual %s effect has its own recognizable color family"%kind)
  check(outside_changes(before,after)==0,"%s effects leave HUD, ammunition panel and reactor pixels untouched"%kind)
  game.elemental_fx._process(0.08)
  var moved=await image_frame()
  check(pixel_changes(after,moved,Rect2i(250,190,155,150),0.1)>45,"%s effect visibly animates rather than remaining an icon"%kind)
  moved.save_png("res://builds/elemental-presentation-"+kind+".png")
  # Extreme edge fixtures prove clipping even when burst radii extend beyond
  # the legal combat rectangle. Earlier body-size checks prevent a blank pass.
  game.elemental_fx.reset()
  game.elemental_fx.on_shot(kind,Vector2(150,121),Vector2(300,122),enemy)
  game.elemental_fx.on_shot(kind,Vector2(150,347),Vector2(300,349),enemy)
  game.elemental_fx._process(0.07);game.elemental_fx.hide()
  before=await image_frame();game.elemental_fx.show()
  after=await image_frame()
  check(outside_changes(before,after)==0,"%s boundary impacts remain clipped at both stage edges"%kind)
 fixture();game.stats["drone"]=1;game.elemental_fx.hide()
 game.combat_motion.hide();game.blood_fx.hide();game.support_drone.hide()
 var before=await image_frame()
 game.support_drone._process(0);game.support_drone.show();game.support_drone.painter.queue_redraw()
 var after=await image_frame()
 check(pixel_changes(before,after,Rect2i(90,165,90,65),0.1)>220,"real renderer shows a substantial detailed support craft")
 var left=540;var right=0
 for y in range(170,219):
  for x in range(90,180):
   if distance(before.get_pixel(x,y),after.get_pixel(x,y))>0.15:left=mini(left,x);right=maxi(right,x)
 check(right-left>=40,"support craft has a readable wide silhouette at native phone resolution")
 check(outside_changes(before,after)==0,"support craft and its lighting remain outside HUD and reactor")
 after.save_png("res://builds/elemental-presentation-drone.png")
 game.profile.data["settings"]["reduced_motion"]=true
 var enemy=fixture();game.profile.data["settings"]["reduced_motion"]=true
 arm("fire");game.shoot();game.combat_motion.hide();game.blood_fx.hide()
 game.elemental_fx._process(0.08);game.elemental_fx.hide()
 before=await image_frame();game.elemental_fx.show()
 after=await image_frame()
 check(colored_changes(before,after,"fire")>35,"reduced motion retains unmistakable fire feedback")
 check(game.elemental_fx.particles.is_empty(),"reduced-motion render does not require flying particles")
func run() -> void:
 root.content_scale_size=Vector2i(540,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 root.size=Vector2i(540,960)
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 check(is_instance_valid(game.get("elemental_fx")) and is_instance_valid(game.get("support_drone")),"actual game initializes both presentation systems")
 if failures:game.queue_free();await process_frame;quit(1);return
 for kind in SpecialAmmo.KINDS:
  var enemy=fixture();arm(kind)
  var hp=float(enemy["hp"]);var expected=float(game.weapon()[1])*float(game.stats["damage"])
  game.shoot()
  check(game.ammo==5 and game.ammo_cargo.count(kind)==5,"actual %s shot spends one reserve round and its existing refined charge"%kind)
  check(is_equal_approx(float(enemy["hp"]),hp-expected),"%s presentation preserves ordinary primary hit damage"%kind)
  check(game.elemental_fx.events.size()==1 and game.elemental_fx.events[0]["kind"]==kind,"actual %s shooting creates its matching presentation event"%kind)
  check(float(enemy.get("ammo_"+kind,0))>0,"actual %s shooting retains its real gameplay status"%kind)
  enemy=fixture();arm(kind);enemy["hp"]=1
  game.shoot()
  check(enemy["dead"] and game.elemental_fx.events.size()==1,"lethal %s shots still retain their visible impact"%kind)
  var impact: Vector2=game.elemental_fx.events[0]["at"]
  enemy["x"]=10
  check(game.elemental_fx.events[0]["at"]==impact,"%s impact snapshots cannot follow a subsequently changed enemy"%kind)
 var enemy=fixture();arm("normal");game.shoot()
 check(game.ammo==5 and game.elemental_fx.events.is_empty(),"ordinary ammunition never creates a false elemental effect")
 enemy=fixture()
 var original=enemy.duplicate(true);var ammo=game.ammo;var rng_state=game.rng.state
 var profile=game.profile.data.duplicate(true);var stats=game.stats.duplicate(true)
 game.elemental_fx.on_shot("fire",Vector2(146,263),Vector2(325,297),enemy)
 game.elemental_fx._process(0.1)
 check(enemy==original and game.ammo==ammo and game.rng.state==rng_state and game.profile.data==profile and game.stats==stats,"drawing actual shot feedback cannot mutate combat, currency, ammunition or gameplay randomness")
 var age=game.elemental_fx.events[0]["age"];var clock=game.elemental_fx.clock
 game.mode="pause";game.elemental_fx._process(2)
 check(not game.elemental_fx.visible and game.elemental_fx.clock==clock and game.elemental_fx.events[0]["age"]==age,"pause freezes and hides the real elemental event canvas")
 game.mode="upgrade";game.elemental_fx._process(2)
 check(game.elemental_fx.clock==clock and not game.elemental_fx.visible,"upgrade cards hold the elemental effect clock")
 game.mode="play";game.elemental_fx._process(0.01)
 check(game.elemental_fx.visible and game.elemental_fx.clock>clock,"resuming continues the preserved event")
 enemy=fixture();game.stats["drone"]=1;game.ammo=0;game.drone_timer=0
 game.support_drone._process(0.4)
 var hp=float(enemy["hp"])
 game.update_combat(0)
 check(is_equal_approx(float(enemy["hp"]),hp-8*(1+game.level*0.03)) and game.ammo==0,"actual drone shot preserves its original damage and independent ammunition rule")
 check(game.tracers.size()==1 and game.tracers[0]["from"].distance_to(game.support_drone.muzzle_position())<0.01,"actual drone tracer originates at its moving physical-looking gun barrel")
 check(game.support_drone.shot_left>0 and game.support_drone.target==game.tracers[0]["to"],"actual drone combat triggers its target-specific muzzle animation")
 check(is_equal_approx(game.drone_timer,0.8),"redesigned drone retains its actual firing cooldown")
 var drone_clock=game.support_drone.clock;var drone_flash=game.support_drone.shot_left
 game.mode="pause";game.support_drone._process(1)
 check(not game.support_drone.visible and game.support_drone.clock==drone_clock and game.support_drone.shot_left==drone_flash,"pause freezes and hides the real drone pose and muzzle feedback")
 enemy=fixture();game.ammo=0;game.drone_timer=0;hp=float(enemy["hp"])
 game.update_combat(0);game.support_drone._process(0)
 check(game.tracers.is_empty() and float(enemy["hp"])==hp and not game.support_drone.visible,"a hero without drone support cannot display or fire a phantom craft")
 game.stats["drone"]=1;game.profile.data["settings"]["reduced_motion"]=true
 var anchor=game.support_drone.position_for()
 game.support_drone.on_shot(Vector2(325,300));game.support_drone._process(0.02)
 check(game.support_drone.position_for()==anchor and game.support_drone.angle_for()==0 and game.support_drone.shot_left>0,"reduced motion retains real drone firing identity without banking or recoil movement")
 game.start_level(1);freeze_tree(game)
 check(game.elemental_fx.events.is_empty() and game.elemental_fx.particles.is_empty() and game.elemental_fx.clock==0,"next real deployment removes prior elemental impacts and particle state")
 check(game.support_drone.clock==0 and game.support_drone.shot_left==0 and game.support_drone.target==Vector2.ZERO,"next real deployment removes the old drone target and muzzle animation")
 for canvas in [game.elemental_fx,game.support_drone]:
  check(canvas.clipper.clip_contents and canvas.clipper.position==Vector2(0,121) and canvas.clipper.size==Vector2(540,229) and canvas.clipper.mouse_filter==Control.MOUSE_FILTER_IGNORE,"real presentation canvas clips to combat and never intercepts touch input")
 if "--render" in OS.get_cmdline_user_args():await render_checks()
 print("ELEMENTAL PRESENTATION RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame
 quit(1 if failures else 0)
