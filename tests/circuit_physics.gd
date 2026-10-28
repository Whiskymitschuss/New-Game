extends SceneTree
# Real pooled bodies and public combat hooks. Fixtures isolate conservation from
# the intended multipliers, so an empty lane is never disguised as a multiplier.
var game
var checks=0
var failures=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func live_mass() -> int:
 var total=0
 for ball in game.pool:
  if ball.live:total+=ball.weight
 return total
func settle() -> void:
 for i in range(3):await physics_frame
func open_gates() -> void:
 for gate in game.layout["gates"]:
  gate["left"]=0;gate["right"]=0
func capsule(kind: String,at: Vector2) -> Dictionary:
 return {"kind":kind,"x":at.x,"y":at.y,"consumed":false}
func run() -> void:
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.profile.reset();game.start_level(1)
 game.set_physics_process(false);game.set_process(false)
 game.choose_upgrade()
 check(23 in game.cards and 13 in game.cards,"tutorial offers actual ammunition-belt and armor cards")
 var choices=[]
 for control in game.controls.get_children():
  if control is Button:choices.append(control)
 choices[game.cards.find(23)].pressed.emit()
 check(HeroGear.gear_state(game)["belt"]>0 and game.wave==2,"normal tutorial choice equips its real visible ammunition belt")
 game.choose_upgrade()
 check(13 in game.cards,"second tutorial choice keeps the missing visible armor discoverable")
 choices=[]
 for control in game.controls.get_children():
  if control is Button:choices.append(control)
 choices[game.cards.find(13)].pressed.emit()
 check(HeroGear.gear_state(game)["armor"]>0,"normal armor choice strengthens the real hero and draws plates")
 game.start_level(1)
 game.quality=0;game.clear_balls();game.reactor_fx.reset();open_gates()
 game.emit_ball(Vector2(100,550),Vector2.ZERO,3)
 await settle()
 var ball: AmmoBall=game.pool[0]
 game.multiply_ball(ball,0)
 check(ball.weight==3 and live_mass()==3,"an open lane conserves every represented unit")
 check(game.reactor_fx.events.is_empty() and game.reactor_fx.gate_charge[0]==0,"an empty lane produces no fake multiplier flare")
 game.multiply_ball(ball,0)
 check(live_mass()==3,"re-crossing an open row cannot destroy or award ammunition")
 game.layout["gates"][1]["left"]=2
 game.multiply_ball(ball,1);game.multiply_ball(ball,1)
 check(ball.weight==6 and live_mass()==6,"a real x2 aperture multiplies once even on a repeated crossing")
 game.quality=1;game.clear_balls();game.emit_ball(Vector2(100,740),Vector2.ZERO,5)
 await settle();ball=game.pool[0]
 game.layout["gates"][2]["left"]=3
 game.multiply_ball(ball,2)
 check(live_mass()==15 and game.active_balls()==2,"representative splitting conserves exact x3 mass")
 game.multiply_ball(ball,2)
 check(live_mass()==15,"split representatives retain the already-crossed aperture mask")
 # Use the real, seeded portal in the actual board. All gate bits are already set
 # here, so neither its destination nor later rows may multiply the test cargo.
 game.clear_balls();game.start_level(1);game.set_physics_process(false);game.set_process(false)
 var portal: Dictionary={}
 for obstacle in game.obstacles:
  if obstacle["kind"]=="portal":portal=obstacle;break
 check(not portal.is_empty(),"the first playable board contains a real portal")
 if portal.is_empty():
  game.queue_free();await process_frame;quit(1);return
 var entry: Vector2=portal["pos"]
 var exit=Vector2(540-entry.x,entry.y+35)
 game.emit_ball(entry,Vector2(0,30),17,7)
 await settle();ball=game.pool[0]
 var before_mass=live_mass()
 game.physics_balls(1.0/60.0)
 check(ball.portal_used and live_mass()==before_mass,"portal transfer preserves virtual cargo and one-use state")
 await settle()
 var server_pose: Transform2D=PhysicsServer2D.body_get_state(ball.get_rid(),PhysicsServer2D.BODY_STATE_TRANSFORM)
 check(server_pose.origin.distance_to(exit)<18,"portal relocates the actual physics-server body to its visible exit")
 var prior=game.collected
 for tick in range(480):
  game.physics_balls(1.0/60.0);await physics_frame
  if game.active_balls()==0:break
 check(game.active_balls()==0 and game.collected-prior==17,"the transported cargo reaches collection without duplication or loss")
 # Ordinary twelve-ball drops travel through the complete obstacle board. Empty
 # apertures isolate its mass accounting; no body is replaced between qualities.
 for quality in [0,1]:
  game.clear_balls();game.quality=quality;open_gates();game.wave_booster={}
  game.ammo=0;game.stats["capacity"]=9999;game.stats["collection"]=1.0;game.collection_remainder=0
  game.attempts=2;game.set_aim(410)
  var collected_before=game.collected
  game.drop_ammo()
  var peak_bodies=0;var longest_age=0.0;var ticks=0
  for tick in range(600):
   game.physics_balls(1.0/60.0);await physics_frame;ticks+=1
   peak_bodies=maxi(peak_bodies,game.active_balls())
   for active in game.pool:
    if active.live:longest_age=maxf(longest_age,active.age)
   if game.pending_balls.is_empty() and game.active_balls()==0:break
  check(game.collected-collected_before==12 and game.ammo==12,"ordinary obstacle drop preserves twelve units in quality %d"%quality)
  check(ticks<600 and longest_age<7,"ordinary obstacle drop clears before anti-stall fallback in quality %d"%quality)
  check(peak_bodies<=(64 if quality==0 else 128),"obstacle drop keeps the physical body budget in quality %d"%quality)
  print("CIRCUIT DROP quality=%d frames=%d maximum_age=%.2f collected=%d"%[quality,ticks,longest_age,game.collected-collected_before])
 # Splitting after a portal must carry its spent history to every child; a
 # clone must not gain a second traversal merely because a body came from a pool.
 game.clear_balls();game.quality=1;game.emit_ball(Vector2(100,620),Vector2.ZERO,5,0,true)
 await settle();ball=game.pool[0];game.layout["gates"][1]["left"]=2
 game.multiply_ball(ball,1)
 var spent_history=true
 for representative in game.pool:
  if representative.live:spent_history=spent_history and representative.portal_used
 check(game.active_balls()==2 and live_mass()==10 and spent_history,"split cargo inherits its spent portal state instead of re-opening a route")
 # Power is triggered by a live physical representative, not once per unit of its
 # virtual weight, and not by stale bodies waiting for their server reset.
 game.clear_balls();game.energy=30;game.mode="play"
 var at=Vector2(200,620)
 game.wave_booster=capsule("energy",at)
 game.emit_ball(at,Vector2.ZERO,100,7);ball=game.pool[0]
 game.activate_booster(ball)
 check(game.energy==30 and not game.wave_booster["consumed"],"pending server resets cannot collect a power capsule")
 await settle();game.activate_booster(ball)
 check(game.energy==42 and game.wave_booster["consumed"] and live_mass()==100,"an energy capsule applies once and does not alter virtual ammunition")
 game.activate_booster(ball);game.emit_ball(at,Vector2.ZERO,100,7);await settle();game.activate_booster(game.pool[1])
 check(game.energy==42,"another representative cannot re-use the same capsule")
 game.energy=96;game.wave_booster=capsule("energy",ball.position);game.activate_booster(ball)
 check(game.energy==100,"energy power respects the existing energy limit")
 game.wave_booster=capsule("energy",ball.position+Vector2(100,0));game.energy=30;game.activate_booster(ball)
 check(game.energy==30 and not game.wave_booster["consumed"],"distant capsules require an actual physical hit")
 game.wave_booster=capsule("energy",ball.position);game.mode="pause";game.activate_booster(ball)
 check(game.energy==30 and not game.wave_booster["consumed"],"paused combat cannot collect a capsule")
 game.mode="play";game.wave_booster=capsule("overdrive",ball.position);game.activate_booster(ball)
 check(is_equal_approx(game.overdrive_left,5.0),"overdrive starts a finite five-second combat effect")
 var duration=game.overdrive_left
 game.mode="pause";game._physics_process(0.25)
 check(game.overdrive_left==duration,"pause freezes the remaining overdrive duration")
 game.mode="play";game.spawn_timer=999;game._physics_process(0.25)
 check(game.overdrive_left<duration and game.overdrive_left>=duration-0.251,"active combat advances the overdrive duration")
 game.clear_balls();game.enemies.clear()
 var target=game.spawn_enemy();target["x"]=250.0;target["hp"]=100000.0
 game.ammo=30;game.magazine=12;var permanent_speed=game.stats["speed"]
 game.overdrive_left=0;game.shoot();var normal=game.fire_timer
 game.overdrive_left=5;game.shoot();var boosted=game.fire_timer
 check(is_equal_approx(boosted,normal/1.25) and game.ammo==28,"overdrive improves real firing cadence while each shot still consumes ammunition")
 check(game.stats["speed"]==permanent_speed,"temporary power cannot permanently change an upgrade stat")
 game.overdrive_left=0.1;game._physics_process(0.2)
 check(game.overdrive_left==0,"expired overdrive returns to the ordinary cadence")
 game.clear_balls();game.emit_ball(at,Vector2.ZERO,1,7);await settle();ball=game.pool[0]
 var cap=float(game.stats["max_hp"])*0.75
 game.shield=cap-2;game.wave_booster=capsule("shield",ball.position);game.activate_booster(ball)
 check(is_equal_approx(game.shield,cap),"shield power stops at its intended capacity")
 game.shield=cap+25;game.wave_booster=capsule("shield",ball.position);game.activate_booster(ball)
 check(is_equal_approx(game.shield,cap+25),"a power capsule never removes a stronger previously earned shield")
 game.overdrive_left=3;game.start_level(2)
 check(game.overdrive_left==0,"starting another level clears temporary power")
 print("CIRCUIT PHYSICS RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame
 quit(1 if failures else 0)
