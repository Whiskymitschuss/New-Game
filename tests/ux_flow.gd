extends SceneTree
var checks=0
var failures=0
var game
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func run() -> void:
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.profile.reset();game.show_armory(2);await process_frame
 var equip: Button
 var upgrade: Button
 for control in game.controls.get_children():
  if control.has_meta("equip_weapon"):equip=control
  if control.has_meta("upgrade_weapon"):upgrade=control
 check(equip.disabled and upgrade.disabled,"SMG preview cannot equip or upgrade before sector3")
 check(game.profile.data["weapon"]==0,"previewing locked weapon preserves equipped pistol")
 # Actual gun access is guarded after UI, rather than trusting disabled controls.
 game.profile.data["weapon"]=2;game.start_level(1);game.set_physics_process(false)
 check(game.profile.data["weapon"]==0,"start sanitizes an illegally equipped weapon")
 game.profile.data["weapon"]=2
 check(game.weapon()[0]=="Pistole" and game.profile.data["weapon"]==0,"combat lookup itself also enforces weapon locks")
 game.profile.data["unlocked"]=3;game.profile.data["stars"]={"1":3,"2":3}
 game.start_level(3);game.set_physics_process(false)
 game.finish_level(true)
 check(game.result_unlocks==[2],"sector3 victory reveals exactly the newly unlocked SMG")
 var coins=game.profile.data["coins"];var wins=game.profile.data["stats"]["wins"]
 game.finish_level(true)
 check(game.profile.data["coins"]==coins and game.profile.data["stats"]["wins"]==wins,"duplicate completion cannot grant duplicate rewards")
 game.show_armory(2);await process_frame
 for control in game.controls.get_children():
  if control.has_meta("equip_weapon"):equip=control
 check(not equip.disabled,"SMG becomes equipable immediately after real reward transition")
 equip.pressed.emit()
 check(game.profile.data["weapon"]==2,"arsenal equip action commits the unlocked weapon")
 game.start_level(4);game.set_physics_process(false)
 var before_coins=game.profile.data["coins"]
 for id in range(Content.UPGRADES.size()):
  if Content.UPGRADES[id][2]=="salvage":game.apply_upgrade(id)
 check(game.profile.data["coins"]-before_coins==game.run_coins,"salvage credits appear in actual earnings and result totals")
 for trial in range(20):
  game.start_level(4);game.set_physics_process(false)
  game.ammo=10;game.hp=game.stats["max_hp"];game.energy=100
  game.choose_upgrade()
  var has_supply=false
  check(game.cards.size()==3,"upgrade choice always has three distinct useful options")
  var unique={}
  for id in game.cards:
   unique[id]=true
   check(game.can_offer_upgrade(id),"offered card is useful for current stats and class")
   if Content.UPGRADES[id][2] in ["ammo","drop","attempt","collection"]:has_supply=true
  check(has_supply and unique.size()==3,"low reserve guarantees one real supply option without duplicates")
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame
 print("UX FLOW RESULT: %d checks, %d failures"%[checks,failures]);quit(0 if failures==0 else 1)
