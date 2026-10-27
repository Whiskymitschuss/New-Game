extends SceneTree
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var profile=Profile.new()
 check(Progression.unlocked_ids(profile.data)==[0],"fresh profile has exactly the pistol")
 profile.add_xp(100000)
 check(Progression.unlocked_ids(profile.data)==[0],"hero XP cannot bypass campaign weapon locks")
 for id in range(1,Content.WEAPONS.size()):
  profile.reset()
  var req=int(Content.WEAPONS[id][7])
  var proof=Progression.completion_sector(id)
  profile.data["unlocked"]=req
  check(not Progression.available(profile.data,id),"sector number alone cannot grant weapon %d"%id)
  profile.data["stars"][str(proof)]=1
  check(Progression.available(profile.data,id),"completion proof unlocks weapon %d"%id)
  var before=Profile.new().data
  check(Progression.newly_unlocked(before,profile.data).has(id),"new weapon %d appears in unlock delta"%id)
  check(Progression.requirement_text(id).contains("%02d"%proof),"weapon %d names its real requirement"%id)
  profile.data["unlocked"]=req-1
  check(not Progression.available(profile.data,id),"campaign reach also guards weapon %d"%id)
  if req%10==0:
   profile.data["unlocked"]=req
   profile.data["stars"]={str(req-1):3}
   check(not Progression.available(profile.data,id),"boss weapon %d requires the boss, not entry"%id)
 profile.reset()
 var old_weapon=profile.data["weapon"]
 check(not Progression.equip(profile.data,2) and profile.data["weapon"]==old_weapon,"locked SMG cannot be equipped by calling the transaction")
 check(not Progression.equip(profile.data,-1) and not Progression.equip(profile.data,12),"invalid weapon indices are rejected")
 profile.data["unlocked"]=4;profile.data["stars"]={"1":1,"3":2}
 check(Progression.equip(profile.data,2) and profile.data["weapon"]==2,"SMG equips after completing sector three")
 check(Progression.pending_unlocks(profile.data)==[1,2],"unseen real unlocks are deterministic")
 Progression.mark_seen(profile.data,2)
 check(Progression.pending_unlocks(profile.data)==[1],"viewing one unlock acknowledges only that weapon")
 Progression.mark_seen(profile.data)
 check(Progression.pending_unlocks(profile.data).is_empty(),"arsenal can acknowledge all available weapons")
 check(Progression.next_unlock(profile.data)["id"]==3,"next milestone is the first locked weapon")
 profile.data["coins"]=100000
 var before=profile.data.duplicate(true)
 check(not Progression.upgrade_weapon(profile.data,3) and profile.data==before,"locked weapon upgrades cannot spend coins")
 profile.data["coins"]=119
 before=profile.data.duplicate(true)
 check(not Progression.upgrade_weapon(profile.data,0) and profile.data==before,"insufficient funds leave coins and rank unchanged")
 profile.data["coins"]=100000
 var spent=0
 for rank in range(Progression.MAX_RANK):
  var price=Progression.upgrade_cost(profile.data,0)
  spent+=price
  check(price==120*(rank+1)*(rank+1),"rank prices have a defined increasing economy")
  check(Progression.upgrade_weapon(profile.data,0),"valid rank purchase succeeds")
  check(Progression.effective_rank(profile.data,0)==rank+1,"purchase grants exactly one rank")
 check(profile.data["coins"]==100000-spent,"purchases deduct exact cumulative cost")
 before=profile.data.duplicate(true)
 check(not Progression.upgrade_weapon(profile.data,0) and profile.data==before,"maximum rank cannot be purchased again")
 profile.data["weapon_levels"]["0"]=99
 check(Progression.effective_rank(profile.data,0)==5 and profile.data["weapon_levels"]["0"]==99,"legacy ranks are preserved but effective combat rank is capped")
 profile.data["weapon"]=11
 profile.data["coins"]=2345
 profile.data["settings"]["music"]=0.2
 check(profile.save_game(),"v1 save with legacy data writes")
 var restored=Profile.new()
 check(restored.load_game(),"existing v1 schema loads")
 check(restored.data["weapon"]==0,"illegal saved loadout falls back to the starter pistol")
 check(restored.data["coins"]==2345 and restored.data["weapon_levels"]["0"]==99,"currency and stored ranks survive migration")
 check(is_equal_approx(restored.data["settings"]["music"],0.2) and restored.data["seen_weapons"].has(2),"settings and acknowledged unlocks survive reload")
 var all=Profile.new().data
 all["unlocked"]=100
 for n in range(1,101):all["stars"][str(n)]=1
 check(Progression.unlocked_ids(all).size()==12 and Progression.next_unlock(all).is_empty(),"all twelve weapons unlock at complete campaign proof")
 print("PROGRESSION RESULT: %d checks, %d failures"%[checks,failures])
 quit(0 if failures==0 else 1)
