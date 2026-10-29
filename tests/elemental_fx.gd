extends SceneTree
# Resource budgets and lifecycle of presentation triggered by actual refined shots.
class StubGame extends Node2D:
 var mode="play"
 var quality=1
 var profile=Profile.new()
 var rng=RandomNumberGenerator.new()
 var enemies: Array=[]
var checks=0
var failures=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func run() -> void:
 var game=StubGame.new();root.add_child(game)
 game.rng.seed=1934
 var fx=ElementalFx.new();fx.game=game;game.add_child(fx);fx.set_process(false)
 var enemy={"x":320.0,"y":320.0,"hp":80.0,"max_hp":80.0,"type":0,"boss":false,"dead":false,"ammo_fire":1.2,"ammo_frost":0.6,"ammo_emp":0.2}
 var before_enemy=enemy.duplicate(true)
 var before_profile=game.profile.data.duplicate(true)
 var rng_before=game.rng.state
 check(fx.clipper.clip_contents and fx.clipper.position==Vector2(0,121) and fx.clipper.size==Vector2(540,229),"typed effects are physically clipped to the battlefield and cannot cover menus or balls")
 for kind in ["normal","unknown",""]:
  fx.on_shot(kind,Vector2(146,263),Vector2(320,292),enemy)
 check(fx.events.is_empty() and fx.particles.is_empty(),"ordinary and invalid rounds cannot fabricate elemental presentation")
 for kind in SpecialAmmo.KINDS:
  fx.reset();fx.on_shot(kind,Vector2(146,263),Vector2(320,292),enemy)
  check(fx.events.size()==1 and fx.events[0]["kind"]==kind,"each actual refined shot records its own elemental identity")
  check(fx.events[0]["life"]>=0.35 and fx.events[0]["life"]<=0.6,"impact feedback remains readable for several mobile display frames")
  check(fx.particles.size()>0 and fx.shot_flash>0 and fx.last_kind==kind,"an actual shot drives local particles and the matching HUD envelope")
  check(enemy==before_enemy and game.profile.data==before_profile,"creating elemental presentation never alters enemy statuses, health or saved progression")
 enemy["x"]=85;enemy["dead"]=true
 check(fx.events[0]["at"]==Vector2(320,292),"shot impact snapshots coordinates rather than retaining the mutable enemy")
 fx._process(0.12)
 check(fx.events.size()==1 and fx.events[0]["age"]>0,"a lethal shot retains its short visible impact after the target dies")
 var recorded=fx.events.size()
 fx.on_shot("fire",Vector2(146,263),Vector2(320,292),enemy)
 check(fx.events.size()==recorded,"a later request against an already dead target creates no extra shot")
 enemy=before_enemy.duplicate(true)
 for quality in [0,1]:
  game.quality=quality;fx.reset()
  for i in range(500):fx.on_shot(SpecialAmmo.KINDS[i%3],Vector2(146,263),Vector2(250+i%200,292),enemy)
  check(fx.events.size()<=(ElementalFx.HIGH_EVENTS if quality==1 else ElementalFx.LOW_EVENTS),"sustained automatic fire respects the quality-specific event budget")
  check(fx.particles.size()<=(ElementalFx.HIGH_PARTICLES if quality==1 else ElementalFx.LOW_PARTICLES),"sustained automatic fire never grows an unbounded particle pool")
 check(game.rng.state==rng_before,"every elemental random choice belongs to the private visual generator")
 game.quality=0;fx._process(0)
 check(fx.events.size()<=ElementalFx.LOW_EVENTS and fx.particles.size()<=ElementalFx.LOW_PARTICLES,"switching quality trims existing presentation to the lower resource budget")
 var age=fx.events[0]["age"];var clock=fx.clock
 game.mode="pause";fx._process(2)
 check(fx.events[0]["age"]==age and fx.clock==clock and not fx.visible,"pause freezes event age and hides presentation")
 var count=fx.events.size();fx.on_shot("fire",Vector2(146,263),Vector2(320,292),enemy)
 check(fx.events.size()==count,"paused input cannot queue fresh elemental effects")
 game.mode="upgrade";fx._process(2)
 check(fx.events[0]["age"]==age and fx.clock==clock and not fx.visible,"upgrade selection keeps battlefield presentation frozen and hidden")
 game.mode="play";fx._process(1)
 check(fx.visible and fx.events.is_empty() and fx.particles.is_empty(),"finite impacts and particles expire after gameplay resumes")
 fx.reset();game.profile.data["settings"]["reduced_motion"]=true
 for kind in SpecialAmmo.KINDS:fx.on_shot(kind,Vector2(146,263),Vector2(320,292),enemy)
 check(fx.particles.is_empty() and fx.events.size()==3,"reduced motion retains all three essential elemental identities without flying particles")
 fx.reset()
 check(fx.events.is_empty() and fx.particles.is_empty() and fx.shot_flash==0 and fx.clock==0 and fx.last_kind=="normal","new deployment clears all previous trails, statuses' presentation envelope and HUD flash")
 game.queue_free();await process_frame
 # Integration: a real one-hit kill must still paint the special impact after
 # the normal damage/reward code removes its living target.
 var actual=load("res://main.tscn").instantiate();root.add_child(actual);await process_frame
 actual.profile.reset();actual.start_level(1)
 actual.set_process(false);actual.set_physics_process(false);actual.elemental_fx.set_process(false)
 actual.enemies.clear();actual.stats["crit"]=0;actual.stats["drone"]=0
 actual.ammo=10;actual.magazine=12
 actual.ammo_cargo.begin_drop();actual.ammo_cargo.add_refined("fire",2)
 var doomed=actual.spawn_enemy();doomed["x"]=300.0;doomed["y"]=320.0;doomed["hp"]=1.0
 var ammo_before=actual.ammo;var kills_before=actual.run_kills
 actual.shoot()
 check(doomed["dead"] and actual.run_kills==kills_before+1,"actual refined shot still follows the normal lethal damage and reward path")
 check(actual.elemental_fx.events.size()==1 and actual.elemental_fx.events[0]["kind"]=="fire","actual lethal special shot creates visible typed feedback before its target dies")
 check(actual.ammo==ammo_before-1 and actual.ammo_cargo.count("fire")==1,"visible special presentation spends exactly the ordinary round and its existing refined charge")
 actual.queue_free();await process_frame;OS.delay_msec(150);await process_frame
 print("ELEMENTAL FX RESULT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
