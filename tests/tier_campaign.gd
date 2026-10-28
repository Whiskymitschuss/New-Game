extends SceneTree
# Six complete milestone runs. Only public player actions change the live run.
# Boss-bound weapons are tested after legitimately recorded boss completion.
var game
var failures=0
func _initialize() -> void:call_deferred("run")
func select_card() -> void:
 var choice=1
 var best=-1
 for i in range(game.cards.size()):
  var stat=String(Content.UPGRADES[game.cards[i]][2])
  var score=0
  if game.ammo<90 and stat in ["ammo","drop","collection","attempt","salvage"]:score=4
  elif stat in ["pierce","splash","multishot","damage","speed"]:score=3
  elif game.hp<float(game.stats["max_hp"])*0.6 and stat in ["heal","max_hp","regen","vitality"]:score=2
  if score>best:best=score;choice=i
 var buttons=[]
 for control in game.controls.get_children():
  if control is Button:buttons.append(control)
 buttons[choice].pressed.emit()
func supply() -> void:
 var left=1;var right=1
 for gate in game.layout["gates"]:
  left*=maxi(1,int(gate["left"]));right*=maxi(1,int(gate["right"]))
 # The portal near 140/400 can divert a nominal high-value lane into a
 # weaker downstream path. The open outer corridors preserve this estimate.
 game.set_aim(85 if left>right else 455)
 game.drop_ammo()
func run() -> void:
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 for pair in [[1,0],[4,2],[7,3],[11,4],[15,5],[20,6]]:
  var number=int(pair[0]);var id=int(pair[1])
  game.profile.reset()
  # All scenarios are first attempts except the sniper's explicit boss-20 replay.
  var completed=number if id==6 else number-1
  game.profile.data["unlocked"]=completed+1
  for sector in range(1,completed+1):game.profile.data["stars"][str(sector)]=1
  if not Progression.equip(game.profile.data,id):
   failures+=1;push_error("FAIL: tier pilot requires a valid unlocked weapon");break
  game.start_level(number)
  if int(game.profile.data["weapon"])!=id:
   failures+=1;push_error("FAIL: tier pilot silently fell back to another weapon");break
  var elapsed=0.0
  var minimum_ammo=game.ammo
  var maximum_enemies=0
  var damaged=false
  var shot=false
  while game.mode not in ["victory","defeat"] and elapsed<600:
   if game.mode=="play":
    var threshold=90 if float(game.weapon()[2])<=0.2 else 50
    if game.ammo<threshold and game.active_balls()==0 and game.pending_balls.is_empty() and game.attempts>0:supply()
    if game.energy>=70 and game.enemies.size()>2:game.special_attack()
    if game.magazine<int(game.weapon()[4]):shot=true
    if game.hp<float(game.stats["max_hp"]):damaged=true
   elif game.mode=="upgrade":select_card()
   minimum_ammo=mini(minimum_ammo,game.ammo)
   maximum_enemies=maxi(maximum_enemies,game.enemies.size())
   await physics_frame
   elapsed+=1.0/60.0
  var expected=1 if number%10==0 else 0
  for wave in range(1,game.wave_count+1):expected+=Content.wave_enemy_count(number,wave)
  print("TIER CAMPAIGN level=%d weapon=%s rank=0 result=%s seconds=%.1f kills=%d minimum_ammo=%d final_ammo=%d produced=%d actual_drops=%d peak_enemies=%d hp_damaged=%s"%[number,Content.WEAPONS[id][0],game.mode,elapsed,game.run_kills,minimum_ammo,game.ammo,game.produced,int(game.profile.data["stats"]["drops"]),maximum_enemies,str(damaged)])
  if game.mode!="victory" or not shot or game.produced<=0 or game.run_kills<expected or game.remaining>0 or maximum_enemies<6 or game.ammo>int(game.stats["capacity"]):
   failures+=1;push_error("FAIL: milestone campaign did not complete with valid resource flow")
 print("TIER CAMPAIGN RESULT: 6 scenarios, %d failures"%failures)
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(0 if failures==0 else 1)
