class_name Workshop
extends RefCounted
# Permanent suit modules use the existing offline profile and ordinary credits.
# Reading a rank is pure; only sanitize/buy change profile data.
const KEYS := ["belt","armor","weapon"]
const MAX_RANK := 3
const COSTS := [180,540,1080]
const SECTORS := [1,5,10]

static func valid_key(key: String) -> bool:
 return key in KEYS

static func bounded_rank(value: Variant) -> int:
 if typeof(value) not in [TYPE_INT,TYPE_FLOAT]:return 0
 if not is_finite(float(value)):return 0
 return floori(clampf(float(value),0,MAX_RANK))

static func rank(data: Dictionary,key: String) -> int:
 if not valid_key(key):return 0
 var equipment=data.get("equipment",{})
 if not equipment is Dictionary:return 0
 var modules=equipment.get("workshop",{})
 if not modules is Dictionary:return 0
 return bounded_rank(modules.get(key,0))

static func sanitize(data: Dictionary) -> void:
 var equipment=data.get("equipment",{})
 if not equipment is Dictionary:equipment={}
 var modules=equipment.get("workshop",{})
 if not modules is Dictionary:modules={}
 for key in KEYS:modules[key]=bounded_rank(modules.get(key,0))
 equipment["workshop"]=modules
 data["equipment"]=equipment

static func next_cost(data: Dictionary,key: String) -> int:
 if not valid_key(key):return 0
 var current=rank(data,key)
 return 0 if current>=MAX_RANK else int(COSTS[current])

static func requirement_sector(data: Dictionary,key: String) -> int:
 if not valid_key(key):return 0
 var current=rank(data,key)
 return 0 if current>=MAX_RANK else int(SECTORS[current])

static func available(data: Dictionary,key: String) -> bool:
 if not valid_key(key) or rank(data,key)>=MAX_RANK:return false
 var stars=data.get("stars",{})
 if not stars is Dictionary:return false
 var proof=stars.get(str(requirement_sector(data,key)),0)
 return typeof(proof) in [TYPE_INT,TYPE_FLOAT] and is_finite(float(proof)) and float(proof)>0

static func requirement(data: Dictionary,key: String) -> String:
 if not valid_key(key):return "Unbekanntes Modul"
 if rank(data,key)>=MAX_RANK:return "Dauerhaft vollständig ausgebaut"
 var sector=requirement_sector(data,key)
 return "Boss in Einsatz 10 besiegen" if sector==10 else "Einsatz %02d abschließen"%sector

static func buy(data: Dictionary,key: String,expected_rank: int=-1) -> bool:
 if not available(data,key):return false
 var current=rank(data,key)
 if expected_rank>=0 and expected_rank!=current:return false
 var coins=data.get("coins",0)
 if typeof(coins) not in [TYPE_INT,TYPE_FLOAT] or not is_finite(float(coins)):return false
 var cost=next_cost(data,key)
 if cost<=0 or float(coins)<cost:return false
 var equipment=data.get("equipment",{})
 if not equipment is Dictionary:equipment={}
 var modules=equipment.get("workshop",{})
 if not modules is Dictionary:modules={}
 modules[key]=current+1
 equipment["workshop"]=modules
 data["equipment"]=equipment
 data["coins"]=int(coins)-cost
 return true

static func apply_stats(data: Dictionary,stats: Dictionary) -> void:
 # Caller starts from fresh class/level stats once per deployment or preview.
 stats["capacity"]=float(stats.get("capacity",0))+40.0*rank(data,"belt")
 stats["armor"]=float(stats.get("armor",0))+rank(data,"armor")
 stats["damage"]=float(stats.get("damage",1))*(1.0+0.05*rank(data,"weapon"))
