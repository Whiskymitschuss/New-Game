class_name Progression
extends RefCounted
# Weapon access follows completed campaign sectors, never the repeatable hero XP level.
const MAX_RANK := 5

static func valid_weapon(id: int) -> bool:
 return id>=0 and id<Content.WEAPONS.size()

static func completion_sector(id: int) -> int:
 if not valid_weapon(id):return 100
 var requirement=int(Content.WEAPONS[id][7])
 if requirement<=1:return 0
 return requirement if requirement%10==0 else requirement-1

static func available(data: Dictionary,id: int) -> bool:
 if not valid_weapon(id):return false
 if id==0:return true
 var requirement=int(Content.WEAPONS[id][7])
 if int(data.get("unlocked",1))<requirement:return false
 var stars=data.get("stars",{})
 return stars is Dictionary and int(stars.get(str(completion_sector(id)),0))>0

static func requirement_text(id: int) -> String:
 if not valid_weapon(id):return "Unbekannte Waffe"
 var sector=completion_sector(id)
 if sector==0:return "Von Beginn an verfügbar"
 if sector%10==0:return "Boss in Einsatz %02d besiegen"%sector
 return "Einsatz %02d abschließen"%sector

static func unlocked_ids(data: Dictionary) -> Array[int]:
 var result: Array[int]=[]
 for id in range(Content.WEAPONS.size()):
  if available(data,id):result.append(id)
 return result

static func newly_unlocked(before: Dictionary,after: Dictionary) -> Array[int]:
 var result: Array[int]=[]
 for id in range(Content.WEAPONS.size()):
  if available(after,id) and not available(before,id):result.append(id)
 return result

static func next_unlock(data: Dictionary) -> Dictionary:
 for id in range(Content.WEAPONS.size()):
  if not available(data,id):
   var sector=completion_sector(id)
   return {"id":id,"name":Content.WEAPONS[id][0],"requirement":requirement_text(id),"sector":sector,"boss":sector%10==0}
 return {}

static func effective_rank(data: Dictionary,id: int) -> int:
 if not valid_weapon(id):return 0
 var ranks=data.get("weapon_levels",{})
 if not ranks is Dictionary:return 0
 return clampi(int(ranks.get(str(id),0)),0,MAX_RANK)

static func upgrade_cost(data: Dictionary,id: int) -> int:
 if not valid_weapon(id) or effective_rank(data,id)>=MAX_RANK:return 0
 var next_rank=effective_rank(data,id)+1
 return 120*next_rank*next_rank

static func equip(data: Dictionary,id: int) -> bool:
 if not available(data,id):return false
 data["weapon"]=id
 return true

static func upgrade_weapon(data: Dictionary,id: int) -> bool:
 if not available(data,id) or effective_rank(data,id)>=MAX_RANK:return false
 var cost=upgrade_cost(data,id)
 if int(data.get("coins",0))<cost:return false
 var ranks=data.get("weapon_levels",{})
 if not ranks is Dictionary:return false
 data["coins"]=int(data["coins"])-cost
 ranks[str(id)]=effective_rank(data,id)+1
 data["weapon_levels"]=ranks
 return true

static func sanitize_loadout(data: Dictionary) -> bool:
 var id=int(data.get("weapon",0))
 if available(data,id):return false
 data["weapon"]=0
 return true

static func pending_unlocks(data: Dictionary) -> Array[int]:
 var result: Array[int]=[]
 var seen=data.get("seen_weapons",[0])
 for id in unlocked_ids(data):
  if not id in seen:result.append(id)
 return result

static func mark_seen(data: Dictionary,id: int=-1) -> void:
 var seen=data.get("seen_weapons",[0])
 for weapon_id in unlocked_ids(data):
  if (id<0 or id==weapon_id) and not weapon_id in seen:seen.append(weapon_id)
 data["seen_weapons"]=seen
