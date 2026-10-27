extends SceneTree
var game
var failed=false
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 for scenario in [[0,1],[0,2],[0,3],[1,1],[1,3],[2,1],[2,3],[0,10],[1,10],[2,10]]:
  var cls=int(scenario[0]);var n=int(scenario[1])
  # Fresh permanent stats: wins must not depend on earlier test rewards.
  game.profile.reset()
  game.profile.data["class"]=cls
  if n==10:
   game.profile.data["unlocked"]=10
   for sector in range(1,10):game.profile.data["stars"][str(sector)]=1
   game.profile.data["weapon"]=3
   game.profile.data["weapon_levels"]["3"]=1
  game.start_level(n)
  game.aim=413
  var elapsed=0.0
  var fired_shots=0
  var peak_ammo=game.ammo
  var peak_enemies=0
  var fired=false
  while game.mode not in ["victory","defeat"] and elapsed<600:
   if game.mode=="play":
    if game.ammo<45 and game.active_balls()==0 and game.attempts>0:
     var left=1;var right=1
     for gate in game.layout["gates"]:
      left*=int(gate["left"]);right*=int(gate["right"])
     game.set_aim(125 if left>right else 415)
     game.drop_ammo()
    if game.energy>=70 and game.enemies.size()>2:
     game.special_attack()
    if game.magazine<int(game.weapon()[4]):
     fired=true
   elif game.mode=="upgrade":
    # Choose the middle displayed card through its real UI signal.
    var buttons=[]
    for control in game.controls.get_children():
     if control is Button:
      buttons.append(control)
    var choice=1
    if game.ammo<70:
     for i in range(game.cards.size()):
      if Content.UPGRADES[game.cards[i]][2] in ["ammo","drop","collection","attempt"]:choice=i;break
    buttons[choice].pressed.emit()
   var before_ammo=game.ammo
   peak_ammo=maxi(peak_ammo,game.ammo)
   peak_enemies=maxi(peak_enemies,game.enemies.size())
   await physics_frame
   fired_shots+=maxi(0,before_ammo-game.ammo)
   elapsed+=1.0/60.0
  print("CAMPAIGN class=%s level=%d mode=%s seconds=%.1f hp=%.1f ammo=%d produced=%d kills=%d"%[Content.CLASSES[cls]["name"],n,game.mode,elapsed,game.hp,game.ammo,game.produced,game.run_kills])
  print("BALANCE shots=%d peak_ammo=%d peak_enemies=%d drops=%d"%[fired_shots,peak_ammo,peak_enemies,game.dropped/12])
  var expected=1 if n%10==0 else 0
  for w in range(1,game.wave_count+1):expected+=Content.wave_enemy_count(n,w)
  if game.mode!="victory" or not fired or game.produced<=0 or game.run_kills!=expected or peak_enemies<6 or peak_ammo>int(game.stats["capacity"]):
   failed=true
   push_error("Full run failed at level %d"%n)
  if failed:
   break
 game.queue_free()
 await process_frame
 # Let the audio mixing thread release stopped playbacks before engine shutdown.
 OS.delay_msec(150)
 await process_frame
 quit(1 if failed else 0)
