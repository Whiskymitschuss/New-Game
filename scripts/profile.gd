class_name Profile
extends RefCounted
const PATH = "user://progress.json"
var data: Dictionary = {}

func _init() -> void:
 reset()

func reset() -> void:
 data={"version":1,"level":1,"xp":0,"coins":0,"class":0,"weapon":0,"unlocked":1,"stars":{},"seeds":{},"layouts":{},"weapon_levels":{},"seen_weapons":[0],"stats":{"kills":0,"wins":0,"drops":0},"settings":{"music":0.45,"sfx":0.65,"quality":1},"outfit":0,"abilities":[],"equipment":{}}

func load_game() -> bool:
 for path in [PATH,PATH+".bak"]:
  if not FileAccess.file_exists(path):
   continue
  var f := FileAccess.open(path,FileAccess.READ)
  if not f:
   continue
  var parser := JSON.new()
  if parser.parse(f.get_as_text()) != OK:
   continue
  var value = parser.data
  if value is Dictionary and value.get("version",0)==1 and value.get("stats") is Dictionary and value.get("settings") is Dictionary:
   for key in data:
    if value.has(key) and typeof(value[key])==typeof(data[key]):
     data[key]=value[key]
    elif value.has(key) and value[key] is float and data[key] is int:
     data[key]=int(value[key])
   data["unlocked"]=clampi(int(data["unlocked"]),1,100)
   # JSON stores array numbers as floats; acknowledgement IDs are discrete IDs.
   var seen: Array[int]=[]
   for value_id in data["seen_weapons"]:
    var id=int(value_id)
    if Progression.valid_weapon(id) and not id in seen:seen.append(id)
   data["seen_weapons"]=seen
   Progression.sanitize_loadout(data)
   return true
 return false

func save_game() -> bool:
 var temp := PATH+".tmp"
 var f := FileAccess.open(temp,FileAccess.WRITE)
 if not f:
  return false
 f.store_string(JSON.stringify(data))
 f.flush()
 f.close()
 var root := ProjectSettings.globalize_path("user://")
 if FileAccess.file_exists(PATH):
  if DirAccess.copy_absolute(root+"progress.json",root+"progress.json.bak")!=OK:
   return false
 return DirAccess.rename_absolute(root+"progress.json.tmp",root+"progress.json")==OK

func get_level(number: int) -> Dictionary:
 var key := str(number)
 if not data["layouts"].has(key):
  var layout := Content.level_data(number)
  data["layouts"][key]=layout
  data["seeds"][key]=layout["seed"]
 return data["layouts"][key].duplicate(true)

func add_xp(amount: int) -> void:
 data["xp"]+=amount
 while data["xp"] >= int(data["level"])*100:
  data["xp"]-=int(data["level"])*100
  data["level"]+=1
