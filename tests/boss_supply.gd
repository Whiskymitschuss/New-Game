extends SceneTree
# A boss adds one production opportunity, never direct ammunition. Ordinary
# waves and paused/finished runs cannot repeatedly collect that opportunity.
var checks=0
var failures=0
var game
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func prepare(number: int) -> void:
 game.profile.reset();game.start_level(number)
 game.set_process(false);game.set_physics_process(false)
 game.wave=game.wave_count;game.remaining=0;game.spawn_timer=1
 game.enemies.clear();game.ammo=0;game.energy=0;game.attempts=2
func campaign() -> void:
 game.profile.reset();game.profile.data["class"]=2
 game.profile.data["unlocked"]=10
 for sector in range(1,10):game.profile.data["stars"][str(sector)]=1
 game.profile.data["weapon"]=3;game.profile.data["weapon_levels"]["3"]=1
 game.start_level(10);game.set_process(true);game.set_physics_process(true)
 var elapsed=0.0;var boss_drop_seen=false;var shots=false
 while game.mode not in ["victory","defeat"] and elapsed<600:
  if game.mode=="play":
   if game.ammo<45 and game.active_balls()==0 and game.pending_balls.is_empty() and game.attempts>0:
    var left=1;var right=1
    for gate in game.layout["gates"]:
     left*=maxi(1,int(gate["left"]));right*=maxi(1,int(gate["right"]))
    game.set_aim(85 if left>right else 455)
    if game.boss_spawned:boss_drop_seen=true
    game.drop_ammo()
   if game.energy>=70 and game.enemies.size()>2:game.special_attack()
   if game.magazine<int(game.weapon()[4]):shots=true
  elif game.mode=="upgrade":
   var choice=1
   if game.ammo<70:
    for i in range(game.cards.size()):
     if Content.UPGRADES[game.cards[i]][2] in ["ammo","drop","collection","attempt"]:choice=i;break
   var buttons=[]
   for control in game.controls.get_children():
    if control is Button:buttons.append(control)
   buttons[choice].pressed.emit()
  await physics_frame
  elapsed+=1.0/60.0
 var expected=1
 for wave in range(1,game.wave_count+1):expected+=Content.wave_enemy_count(10,wave)
 print("BOSS SUPPLY CAMPAIGN mode=%s seconds=%.1f kills=%d ammo=%d produced=%d drops=%d"%[game.mode,elapsed,game.run_kills,game.ammo,game.produced,int(game.profile.data["stats"]["drops"])])
 check(game.mode=="victory" and game.run_kills==expected and game.remaining==0,"previously starved survivor clears the real boss encounter")
 check(shots and boss_drop_seen and game.produced>0 and game.ammo<=int(game.stats["capacity"]),"boss completion uses real shots and an actual bounded production drop")
func run() -> void:
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 for number in range(10,101,10):
  prepare(number)
  var initial=game.profile.data.duplicate(true)
  game.update_combat(0)
  check(game.boss_spawned and game.enemies.size()==1 and game.enemies[0]["boss"],"sector %d starts its real boss"%number)
  check(game.attempts==3 and game.ammo==0 and game.active_balls()==0 and game.pending_balls.is_empty(),"sector %d grants one attempt and no ammunition or automatic balls"%number)
  check(game.profile.data==initial,"boss supply does not award credits, equipment or completion proof")
  check(game.power_message.contains("+1") and game.power_message_left>0,"boss production opportunity has visible temporary feedback")
  game.update_combat(0);game.update_combat(0)
  check(game.attempts==3 and game.enemies.size()==1,"repeated combat ticks cannot duplicate the boss or its supply")
  game.enemies.clear();game.update_combat(0)
  check(game.attempts==3,"removing a defeated boss cannot grant another supply attempt")
 prepare(10);game.wave=1;game.update_combat(0)
 check(not game.boss_spawned and game.attempts==2,"an ordinary wave in a boss sector has no emergency bonus")
 prepare(10);game.remaining=1;game.update_combat(0)
 check(not game.boss_spawned and game.attempts==2,"the boss reserve waits for actual boss arrival")
 prepare(9);game.update_combat(0)
 check(not game.boss_spawned and game.attempts==2,"a normal sector never grants boss supply")
 for stopped in ["pause","upgrade","victory","defeat"]:
  prepare(10);game.mode=stopped;game._physics_process(0.1)
  check(not game.boss_spawned and game.attempts==2,"%s freezes boss arrival and its reserve"%stopped)
 prepare(10);game.ammo=int(game.stats["capacity"]);game.update_combat(0)
 check(game.ammo==int(game.stats["capacity"]) and game.attempts==3,"a full magazine reserve receives an unused chance without overfilling")
 if "--campaign" in OS.get_cmdline_user_args():await campaign()
 print("BOSS SUPPLY RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(1 if failures else 0)
