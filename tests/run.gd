extends SceneTree
var checks=0
var failures=0
var game
func check(condition: bool,message: String) -> void:
 checks+=1
 if not condition:
  failures+=1
  push_error("FAIL: "+message)
 else:
  print("PASS: "+message)

func _initialize() -> void:
 call_deferred("run")

func run() -> void:
 game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 check(game.mode=="menu","main menu starts")
 game.show_map()
 check(game.controls.get_child_count()>=16,"level map has real navigation and ten level buttons")
 game.show_armory()
 check(game.controls.get_child_count()>=20,"class selection and twelve weapon controls")
 game.show_settings()
 check(game.controls.get_child_count()>=10,"settings controls exist")
 var distinct={}
 for n in range(1,101):
  var a=Content.level_data(n)
  var b=Content.level_data(n)
  check(a==b and a["waves"]>=5 and a["gates"].size()==3,"deterministic level %d"%n)
  distinct[a["seed"]]=true
  game.start_level(n)
  check(game.obstacles.size()>=3 and game.layout["number"]==n,"load playable geometry %d"%n)
 check(distinct.size()==100,"100 unique level seeds")
 check(Content.modules().size()==30,"30 module configurations")
 check(Content.ENEMIES.size()==15 and Content.WEAPONS.size()==12,"15 enemy and 12 weapon definitions")
 check(Content.UPGRADES.size()>=40,"at least forty upgrades")
 game.start_level(1)
 game.set_physics_process(false)
 var before=game.stats.duplicate(true)
 game.apply_upgrade(2)
 check(game.stats["damage"]>before["damage"],"damage upgrade changes consumed combat stat")
 for id in range(Content.UPGRADES.size()):
  game.start_level(1)
  game.set_physics_process(false)
  var old=JSON.stringify([game.stats,game.hp,game.ammo,game.attempts,game.shield,game.energy,game.profile.data["coins"]])
  if id==9:
   game.hp=20
   old=JSON.stringify([game.stats,game.hp,game.ammo,game.attempts,game.shield,game.energy,game.profile.data["coins"]])
  game.apply_upgrade(id)
  check(old!=JSON.stringify([game.stats,game.hp,game.ammo,game.attempts,game.shield,game.energy,game.profile.data["coins"]]),"upgrade has effect: "+Content.UPGRADES[id][0])
 # Exact count through x3 then x5, including all representative splits.
 game.start_level(1)
 game.set_physics_process(false)
 game.layout["gates"][0]["left"]=3
 game.layout["gates"][1]["left"]=5
 game.emit_ball(Vector2(90,550),Vector2.ZERO,10)
 var first=game.pool[0]
 game.multiply_ball(first,0)
 var snapshot=[]
 for ball in game.pool:
  if ball.live:
   snapshot.append(ball)
 for ball in snapshot:
  game.multiply_ball(ball,1)
 var total=0
 for ball in game.pool:
  if ball.live:
   total+=ball.weight
 check(total==150,"10 ×3 ×5 conserves exactly 150 virtual balls")
 var initial_ammo=game.ammo
 for ball in game.pool:
  if ball.live:
   game.collect_ball(ball)
 check(game.ammo==initial_ammo+150 and game.collected==150,"collector credits virtual quantity exactly")
 game.start_level(1)
 game.set_physics_process(false)
 for i in range(1000):
  game.emit_ball(Vector2(100,500),Vector2.ZERO,1000000)
 check(game.active_balls()==128,"pool hard limit survives 1000 emission attempts")
 game.clear_balls()
 # Valid campaign proof is required even in direct combat tests.
 game.profile.data["unlocked"]=100
 for sector in range(1,101):game.profile.data["stars"][str(sector)]=3
 # All weapons fire a real hit, consume reserve, initiate reload and differ in timing.
 for id in range(12):
  game.start_level(1)
  game.set_physics_process(false)
  game.profile.data["weapon"]=id
  game.ammo=100
  game.magazine=10
  var enemy=game.spawn_enemy()
  enemy["x"]=180.0
  enemy["hp"]=10000.0
  enemy["max_hp"]=10000.0
  game.shoot()
  check(enemy["hp"]<10000 and game.ammo==99 and game.fire_timer>0,"weapon damages and consumes ammo: "+Content.WEAPONS[id][0])
  game.magazine=0
  game.shoot()
  check(game.reload_timer>0,"weapon reload: "+Content.WEAPONS[id][0])
 game.profile.data["weapon"]=0
 # Ten boss encounters, telegraph and phase transition.
 for n in range(10,101,10):
  game.start_level(n)
  game.set_physics_process(false)
  var boss=game.spawn_enemy(true)
  boss["timer"]=0
  game.update_boss(boss,0.1)
  check(boss["telegraph"]>0,"boss %d announces attack"%n)
  boss["hp"]=boss["max_hp"]*0.4
  var old_hp=game.hp
  game.update_boss(boss,2.1)
  check(boss["phase"]==2 and game.hp<old_hp,"boss %d phase two attacks"%n)
 # True engine physics, no manual motion. Stop combat only, leave physics simulation live.
 game.start_level(1)
 game.set_physics_process(false)
 game.aim=410
 game.drop_ammo()
 var start_y=game.pool[0].position.y
 for i in range(480):
  game.physics_balls(1.0/60.0)
  await physics_frame
 check(game.pool[0].position.y>start_y or not game.pool[0].live,"RigidBody2D gravity advances ball")
 check(game.collected>0 and game.ammo>40,"physical drop crosses gates and produces usable ammunition")
 # Enemy behavior and result screens.
 game.start_level(1)
 game.set_physics_process(false)
 var zombie=game.spawn_enemy()
 zombie["x"]=120.0
 zombie["timer"]=0
 var previous_hp=game.hp
 game.update_combat(0.1)
 check(game.hp<previous_hp,"zombie reaches hero and attacks")
 var old_kills=game.run_kills
 game.hit_enemy(zombie,10000)
 check(game.run_kills==old_kills+1 and zombie["dead"],"death grants kill reward")
 game.pause_game()
 var frozen=game.hp
 game._physics_process(1.0)
 check(game.mode=="pause" and game.hp==frozen,"pause stops combat")
 game.start_level(1)
 game.set_physics_process(false)
 game.profile.data["unlocked"]=1
 game.finish_level(true)
 check(game.mode=="victory" and game.profile.data["unlocked"]==2,"victory awards stars and unlocks next level")
 var p=Profile.new()
 check(p.load_game() and int(p.data["unlocked"])==2,"offline save survives profile reload")
 check(p.save_game(),"atomic save succeeds")
 var file=FileAccess.open(Profile.PATH,FileAccess.WRITE)
 file.store_string("{broken")
 file.close()
 var backup=Profile.new()
 check(backup.load_game() and int(backup.data["unlocked"])==2,"corrupt primary recovers from backup")
 backup.save_game()
 game.start_level(1)
 game.set_physics_process(false)
 game.hp=0
 game.update_combat(0)
 check(game.mode=="defeat","zero health produces defeat screen")
 print("RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free()
 await process_frame
 # Let the audio mixing thread release stopped playbacks before engine shutdown.
 OS.delay_msec(150)
 await process_frame
 quit(0 if failures==0 else 1)
