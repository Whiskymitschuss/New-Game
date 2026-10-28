extends SceneTree
var checks=0
var failures=0
class CombatStub extends Node2D:
 var mode="play"
 var calls=0
 var deaths=0
 var reward=0
 var rng=RandomNumberGenerator.new()
 func hit_enemy(enemy: Dictionary,amount: float,_visual: bool=false) -> void:
  if enemy.get("dead",false):return
  calls+=1
  enemy["hp"]-=amount
  if enemy["hp"]<=0:
   enemy["dead"]=true;deaths+=1;reward+=int(enemy.get("reward",4))
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func foe(hp: float=100.0,kind: int=0,boss: bool=false) -> Dictionary:
 return {"hp":hp,"dead":false,"type":kind,"boss":boss,"reward":4,"burn":3.0,"slow":0.1,"x":350.0,"y":320.0}
func run() -> void:
 var cargo=SpecialAmmo.new()
 check(cargo.total()==0 and cargo.peek()=="normal","fresh deployment has only ordinary ammunition")
 check(cargo.add_refined("normal",100)==0 and cargo.add_refined("unknown",12)==0 and cargo.add_refined("fire",-4)==0,"plain, invalid or negative input cannot mint typed ammunition")
 check(cargo.add_refined("fire",200000)==12 and cargo.count("fire")==12,"huge virtual cargo refines only twelve accepted rounds per drop")
 check(cargo.add_refined("frost",2)==0,"all collection representatives share the same drop budget")
 cargo.begin_drop();cargo.add_refined("frost",10);cargo.add_refined("fire",2)
 check(cargo.total()==24 and cargo.order.size()==2 and cargo.peek()=="fire","type buckets merge without adding per-unit objects and preserve first-kind priority")
 cargo.begin_drop();cargo.add_refined("emp",100)
 check(cargo.total()==36 and cargo.order.size()==3,"three packets cover a capped thirty-six-round special reserve")
 cargo.begin_drop()
 check(cargo.add_refined("fire",100)==0 and cargo.total()==36,"a new drop cannot exceed the global special reserve cap")
 var copy=cargo.summary();copy["fire"]=999
 check(cargo.count("fire")==14,"UI summary is a snapshot and cannot mutate cargo")
 for i in range(14):check(cargo.consume()=="fire","oldest type remains selected until its bucket is empty")
 check(cargo.peek()=="frost" and cargo.count("fire")==0,"depleted type advances to the next produced ammunition")
 var before=cargo.summary();var repeated=cargo.peek()
 check(repeated=="frost" and cargo.summary()==before,"peeking supports recycled shots without consuming their charge")
 cargo.reconcile(4)
 check(cargo.total()==4 and cargo.count("frost")==4 and cargo.count("emp")==0,"ammo theft trims newest refined groups and preserves the authoritative total")
 cargo.reconcile(-1)
 check(cargo.total()==0 and cargo.peek()=="normal" and cargo.consume()=="normal","an empty or externally cleared ammo reserve cannot fire ghost elemental rounds")
 cargo.begin_drop();cargo.add_refined("emp",5);cargo.reset()
 check(cargo.total()==0 and cargo.drop_remaining==12,"new deployment clears every temporary charge and drop budget")
 var combat=CombatStub.new();root.add_child(combat);combat.rng.seed=17
 var enemy=foe();var random_state=combat.rng.state
 SpecialAmmo.apply_hit(combat,enemy,"fire",50)
 check(enemy["burn"]==3.0 and enemy["slow"]==0.1,"elemental effects preserve the existing card and weapon status fields")
 SpecialAmmo.tick_enemy(combat,enemy,0.5)
 check(is_equal_approx(enemy["hp"],98.0) and is_equal_approx(enemy["ammo_fire"],1.5),"a burn causes real finite damage through the combat callback")
 combat.mode="pause";var held=enemy.duplicate(true)
 SpecialAmmo.tick_enemy(combat,enemy,10)
 check(enemy==held,"paused gameplay freezes all elemental timers and damage")
 combat.mode="upgrade";SpecialAmmo.apply_hit(combat,enemy,"frost",50)
 check(not enemy.has("ammo_frost"),"upgrade screens cannot apply fresh combat status effects")
 combat.mode="play";SpecialAmmo.tick_enemy(combat,enemy,10)
 check(is_equal_approx(enemy["hp"],92.0) and enemy["ammo_fire"]==0 and enemy["ammo_fire_dps"]==0,"large timesteps burn only the remaining duration rather than infinitely damaging")
 var calls=combat.calls;SpecialAmmo.tick_enemy(combat,enemy,1)
 check(combat.calls==calls,"expired fire produces no later hit callbacks")
 SpecialAmmo.apply_hit(combat,enemy,"fire",1000)
 check(enemy["ammo_fire_dps"]==6.0,"heavy weapon burn damage has a finite ceiling")
 SpecialAmmo.apply_hit(combat,enemy,"fire",1)
 check(enemy["ammo_fire_dps"]==6.0,"weaker refreshes cannot silently erase a stronger active burn")
 SpecialAmmo.apply_hit(combat,enemy,"frost",20)
 check(SpecialAmmo.speed_factor(enemy)==0.65,"frost slows ordinary movement by thirty-five percent")
 SpecialAmmo.tick_enemy(combat,enemy,1.6)
 check(SpecialAmmo.speed_factor(enemy)==1.0,"frost expires and restores ordinary movement")
 var boss=foe(100,9,true);SpecialAmmo.apply_hit(combat,boss,"frost",20)
 check(SpecialAmmo.speed_factor(boss)==0.82,"boss frost effect is deliberately smaller")
 var robot=foe(100,13);SpecialAmmo.apply_hit(combat,robot,"emp",50)
 check(is_equal_approx(robot["hp"],91.0) and is_equal_approx(robot["ammo_emp"],0.35),"EMP deals real bonus damage to robotic targets and briefly stuns")
 SpecialAmmo.tick_enemy(combat,robot,0.1);var stun=robot["ammo_emp"]
 SpecialAmmo.apply_hit(combat,robot,"emp",0)
 check(robot["ammo_emp"]==stun,"EMP cooldown prevents a fast weapon from permanently refreshing the stun")
 check(SpecialAmmo.tick_enemy(combat,robot,0.1),"active EMP tells the caller to skip movement and attack logic")
 check(not SpecialAmmo.tick_enemy(combat,robot,0.3),"expired EMP releases movement while its cooldown remains active")
 SpecialAmmo.tick_enemy(combat,robot,1)
 SpecialAmmo.apply_hit(combat,robot,"emp",0)
 check(is_equal_approx(robot["ammo_emp"],0.35),"stun can trigger again after its visible finite cooldown")
 SpecialAmmo.apply_hit(combat,boss,"emp",50)
 check(is_equal_approx(boss["ammo_emp"],0.12) and boss["hp"]==100,"boss stun is short and a nonrobot boss gets no armor bonus")
 var walker=foe();SpecialAmmo.apply_hit(combat,walker,"emp",50)
 check(walker["hp"]==100,"EMP bonus damage is restricted to actual armored or robotic targets")
 check(combat.rng.state==random_state,"element rules never consume gameplay random values")
 var doomed=foe(0.5);SpecialAmmo.apply_hit(combat,doomed,"fire",10)
 SpecialAmmo.tick_enemy(combat,doomed,1);SpecialAmmo.tick_enemy(combat,doomed,1)
 SpecialAmmo.apply_hit(combat,doomed,"emp",100)
 check(doomed["dead"] and combat.deaths==1 and combat.reward==4,"a finite burn death grants the normal reward once and cannot be rewarded again")
 if "--integration" in OS.get_cmdline_user_args():
  var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
  game.profile.reset();game.start_level(1);game.set_physics_process(false)
  var target=game.spawn_enemy();target["hp"]=0.5
  var kills=game.run_kills;var coins=int(game.profile.data["coins"])
  SpecialAmmo.apply_hit(game,target,"fire",10);SpecialAmmo.tick_enemy(game,target,1)
  SpecialAmmo.tick_enemy(game,target,10);SpecialAmmo.apply_hit(game,target,"emp",100)
  check(target["dead"] and game.run_kills==kills+1 and int(game.profile.data["coins"])>coins,"real gameplay burn uses the existing death, coin and kill path once")
  var after_coins=int(game.profile.data["coins"])
  SpecialAmmo.tick_enemy(game,target,10)
  check(int(game.profile.data["coins"])==after_coins and game.run_kills==kills+1,"real defeated target cannot grant duplicate rewards")
  game.queue_free();await process_frame
 combat.queue_free();await process_frame
 print("SPECIAL AMMO RESULT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
