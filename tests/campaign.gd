extends SceneTree
var game
var failed=false
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.profile.reset()
 for n in [1,2,3]:
  game.start_level(n)
  game.aim=413
  var elapsed=0.0
  var fired_shots=0
  var peak_ammo=game.ammo
  var peak_enemies=0
  var fired=false
  while game.mode not in ["victory","defeat"] and elapsed<600:
   if game.mode=="play":
    if game.ammo<60 and game.active_balls()==0 and game.attempts>0:
     game.drop_ammo()
    if game.energy>=75 and game.enemies.size()>2:
     game.special_attack()
    if game.magazine<int(game.weapon()[4]):
     fired=true
   elif game.mode=="upgrade":
    # Choose the middle displayed card through its real UI signal.
    var buttons=[]
    for control in game.controls.get_children():
     if control is Button:
      buttons.append(control)
    buttons[1].pressed.emit()
   var before_ammo=game.ammo
   peak_ammo=maxi(peak_ammo,game.ammo)
   peak_enemies=maxi(peak_enemies,game.enemies.size())
   await physics_frame
   fired_shots+=maxi(0,before_ammo-game.ammo)
   elapsed+=1.0/60.0
  print("CAMPAIGN level=%d mode=%s seconds=%.1f hp=%.1f ammo=%d produced=%d kills=%d"%[n,game.mode,elapsed,game.hp,game.ammo,game.produced,game.run_kills])
  print("BALANCE shots=%d peak_ammo=%d peak_enemies=%d drops=%d"%[fired_shots,peak_ammo,peak_enemies,game.dropped/12])
  if game.mode!="victory" or not fired or game.produced<=0 or game.run_kills<100 or peak_enemies<6:
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
