extends SceneTree
# Cross-system tests use real GUI callbacks, pooled physics bodies and combat.
# Earned-star/credit fixtures are isolated test inputs, never production rewards.
var game
var checks=0
var failures=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func click(at: Vector2) -> void:
 var event=InputEventMouseButton.new()
 event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
 event.button_mask=MOUSE_BUTTON_MASK_LEFT;event.position=at;event.global_position=at
 root.push_input(event)
 event=event.duplicate();event.pressed=false;event.button_mask=0
 root.push_input(event)
func workshop_button(key: String) -> Button:
 for child in game.controls.get_children():
  if child is Button and child.get_meta("workshop_key","")==key:return child
 return null
func settle(frames: int=3) -> void:
 for i in range(frames):await physics_frame
func fresh() -> void:
 game.profile.reset();game.start_level(1)
 game.set_process(false);game.set_physics_process(false)
func live_mass() -> int:
 var total=0
 for ball in game.pool:
  if ball.live:total+=ball.weight
 return total
func all_kind(kind: String) -> bool:
 for ball in game.pool:
  if ball.live and ball.ammo_kind!=kind:return false
 return true
func collect_live() -> void:
 for ball in game.pool:
  if ball.live:game.collect_ball(ball)
func quiet_combat() -> void:
 game.ammo=0;game.spawn_timer=999;game.remaining=1;game.fire_timer=999
 game.stats["drone"]=0;game.stats["crit"]=0
func target(at: float=300) -> Dictionary:
 var enemy=game.spawn_enemy()
 enemy["type"]=0;enemy["x"]=at;enemy["y"]=320.0
 enemy["hp"]=1000.0;enemy["max_hp"]=1000.0;enemy["speed"]=20.0;enemy["timer"]=10.0
 return enemy
func run() -> void:
 root.content_scale_size=Vector2i(540,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 root.size=Vector2i(540,960)
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 fresh()
 check(game.stats["capacity"]==248 and game.stats["armor"]==0 and is_equal_approx(game.stats["damage"],1.25),"fresh profile receives no unearned permanent workshop statistics")
 game.profile.data["coins"]=1000;game.show_workshop();await process_frame
 var locked=workshop_button("belt")
 var wallet=int(game.profile.data["coins"])
 click(locked.get_global_rect().get_center());await process_frame
 check(locked.disabled and Workshop.rank(game.profile.data,"belt")==0 and game.profile.data["coins"]==wallet,"native workshop control cannot buy through a missing completion requirement")
 game.profile.data["stars"]["1"]=1;game.profile.data["unlocked"]=2
 game.show_workshop();await process_frame
 click(workshop_button("belt").get_global_rect().get_center());await process_frame
 check(Workshop.rank(game.profile.data,"belt")==1 and int(game.profile.data["coins"])==820,"native workshop purchase charges the real first-rank cost")
 check(workshop_button("belt").disabled,"second workshop rank remains locked before sector five")
 game.profile.data["stars"]["5"]=1;game.profile.data["stars"]["10"]=1
 game.show_workshop();await process_frame
 var stale=workshop_button("armor")
 click(stale.get_global_rect().get_center())
 var paid=int(game.profile.data["coins"])
 if is_instance_valid(stale):stale.pressed.emit()
 await process_frame
 check(Workshop.rank(game.profile.data,"armor")==1 and int(game.profile.data["coins"])==paid and paid==640,"stale workshop callback cannot spend again on an already changed rank")
 click(workshop_button("weapon").get_global_rect().get_center());await process_frame
 var restored=Profile.new()
 check(restored.load_game() and Workshop.rank(restored.data,"belt")==1 and Workshop.rank(restored.data,"armor")==1 and Workshop.rank(restored.data,"weapon")==1 and int(restored.data["coins"])==460,"all three native purchases survive versioned save reload with exact credits")
 game.profile=restored;game.start_level(1)
 check(game.stats["capacity"]==288 and game.stats["armor"]==1 and is_equal_approx(game.stats["damage"],1.3125),"new deployment consumes the actual saved workshop bonuses")
 var gear=HeroGear.gear_state(game)
 check(gear["belt"]==1 and gear["armor"]==1 and gear["weapon"]==1,"saved workshop ranks also activate the corresponding visible suit tiers")
 game.start_level(1)
 check(game.stats["capacity"]==288 and game.stats["armor"]==1 and is_equal_approx(game.stats["damage"],1.3125),"restarting a level does not apply permanent bonuses twice")
 check(not Progression.available(game.profile.data,2),"workshop equipment does not bypass the campaign weapon unlock policy")
 # One native switch press spends only its accepted drop charge and physically
 # turns the existing collider. There is no extra obstacle or ammunition reward.
 fresh();game._process(0)
 check(game.obstacles[0]["kind"]=="switch" and game.reactor_switch.body is AnimatableBody2D,"the switch controls the existing first obstacle's actual animatable body")
 var before_ammo=game.ammo;var before_coins=game.profile.data["coins"]
 click(Vector2(179,915));game._process(0)
 var attempts=game.attempts
 check(game.drop_running and game.pending_balls.size()==12 and not game.switch_button.disabled,"accepted native drop opens one available switch action")
 click(Vector2(324,915));game._process(0)
 var direction=game.reactor_switch.direction
 click(Vector2(324,915));game._process(0)
 check(direction==-1 and game.reactor_switch.direction==direction and game.reactor_switch.spent and game.switch_button.disabled,"native switch action is spent once and cannot be repeated during the same drop")
 check(game.ammo==before_ammo and game.profile.data["coins"]==before_coins and game.attempts==attempts,"operating the switch cannot spend another drop or invent a resource cost")
 for i in range(14):
  game.physics_balls(1.0/60.0);await physics_frame
 var server_pose: Transform2D=PhysicsServer2D.body_get_state(game.reactor_switch.body.get_rid(),PhysicsServer2D.BODY_STATE_TRANSFORM)
 check(absf(server_pose.get_rotation()+0.4)<0.01,"native switch input reaches the real physics-server collider angle")
 game.pause_game();var held_angle=game.reactor_switch.body.rotation
 game.reactor_switch.update(0.5)
 check(game.reactor_switch.body.rotation==held_angle and not game.reactor_switch.can_toggle(),"pause preserves the collider state and prevents switch input")
 game.mode="play";game.build_hud();game.clear_balls();game.drop_running=false;game.ammo=0;game.attempts=2;game._process(0)
 click(Vector2(179,915));game._process(0)
 check(not game.reactor_switch.spent and not game.switch_button.disabled,"the next accepted drop restores exactly one switch action")
 # Real middle-aperture refinement, exact representative inheritance and cargo
 # collection feed the same ammunition reserve that shooting consumes.
 fresh();game.clear_balls();game.ammo=0;game.quality=1
 game.layout["gates"][1]["left"]=2;game.layout["gates"][1]["right"]=3
 game.emit_ball(Vector2(110,650),Vector2.ZERO,3,1)
 await settle();var ball: AmmoBall=game.pool[0]
 game.multiply_ball(ball,1)
 check(live_mass()==6 and game.active_balls()==2 and all_kind("fire"),"active left middle aperture refines the exact multiplied cargo and its split representative")
 game.multiply_ball(ball,1)
 check(live_mass()==6,"refinement does not let an already crossed multiplier award twice")
 collect_live()
 check(game.ammo==6 and game.ammo_cargo.total()==6 and game.ammo_cargo.count("fire")==6,"collected refined rounds are a subset of the unchanged accepted ammunition total")
 game.enemies.clear();var burning=target(250)
 game.stats["recycle"]=0;game.stats["crit"]=0;game.magazine=12
 game.shoot()
 check(game.ammo==5 and game.ammo_cargo.count("fire")==5 and float(burning.get("ammo_fire",0))>0,"a real shot consumes one actual round and one refined charge then ignites its actual target")
 game.fire_timer=999;game.spawn_timer=999;game.remaining=1
 var after_shot=float(burning["hp"])
 game.update_combat(3.0);var after_burn=float(burning["hp"])
 game.update_combat(0.5)
 check(after_burn<after_shot and is_equal_approx(float(burning["hp"]),after_burn) and float(burning.get("ammo_fire",0))==0,"finite fire damage runs through ordinary combat and stops after expiry")
 fresh();game.clear_balls();game.ammo=0
 var portal: Dictionary={}
 for obstacle in game.obstacles:
  if obstacle["kind"]=="portal":portal=obstacle;break
 game.emit_ball(portal["pos"],Vector2(0,30),8,1)
 await settle();ball=game.pool[0];game.physics_balls(1.0/60.0);await settle()
 check(ball.portal_used and ball.ammo_kind=="emp","a real portal transport imprints EMP on ordinary cargo")
 game.layout["gates"][1]["right"]=3
 game.multiply_ball(ball,1)
 check(live_mass()==24 and all_kind("emp"),"later middle-aperture crossing preserves the earlier EMP imprint on every split")
 collect_live()
 check(game.ammo==24 and game.ammo_cargo.count("emp")==12 and game.ammo_cargo.total()<=game.ammo,"one drop refines at most twelve charges while the remaining accepted cargo stays ordinary")
 game.ammo_cargo.reset();game.ammo=int(game.stats["capacity"])-2
 game.emit_ball(Vector2(100,854),Vector2.ZERO,10,7,false,"frost");game.collect_ball(game.pool[0])
 check(game.ammo==int(game.stats["capacity"]) and game.ammo_cargo.count("frost")==2 and game.drop_overflow>=8,"capacity overflow cannot create unaccepted refined charges")
 game.clear_balls();game.emit_ball(Vector2(100,520),Vector2.ZERO)
 check(game.pool[0].ammo_kind=="normal","reusing a pooled body removes its previous elemental imprint")
 game.ammo=0;game.spawn_timer=999;game.remaining=1;game.update_combat(0)
 check(game.ammo_cargo.total()==0,"authoritative ammunition loss cannot leave ghost refined charges")
 # Compare two otherwise equal live AI bodies to prove the temporary effects
 # affect actual movement rather than just status icons.
 fresh();quiet_combat();game.enemies.clear()
 var chilled=target();var plain=target()
 SpecialAmmo.apply_hit(game,chilled,"frost",15)
 game.update_combat(0.5)
 check(float(chilled["x"])>float(plain["x"]),"Kryo ammunition slows actual enemy travel compared with an ordinary peer")
 game.update_combat(2.0)
 var expired_x=float(chilled["x"]);var plain_x=float(plain["x"])
 game.update_combat(0.1)
 check(is_equal_approx(expired_x-float(chilled["x"]),plain_x-float(plain["x"])),"expired Kryo returns the enemy to its ordinary movement rate")
 SpecialAmmo.apply_hit(game,chilled,"emp",0)
 var emp_x=float(chilled["x"])
 game.update_combat(0.1)
 check(is_equal_approx(float(chilled["x"]),emp_x),"EMP briefly stops the actual enemy AI movement")
 game.update_combat(0.5);SpecialAmmo.apply_hit(game,chilled,"emp",0)
 var recovered=float(chilled["x"]);game.update_combat(0.1)
 check(float(chilled["x"])<recovered and float(chilled.get("ammo_emp",0))==0,"EMP cooldown prevents an immediately repeated permanent stun")
 game.enemies.clear();var doomed=target(250);doomed["hp"]=0.7
 var kills=game.run_kills;var credits=int(game.profile.data["coins"])
 SpecialAmmo.apply_hit(game,doomed,"fire",15);game.update_combat(1.0)
 var paid_credits=int(game.profile.data["coins"])
 game.update_combat(1.0)
 check(game.run_kills==kills+1 and paid_credits>credits and int(game.profile.data["coins"])==paid_credits,"elemental DOT kills grant the real reward exactly once")
 print("FORGE INTEGRATION RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(1 if failures else 0)
