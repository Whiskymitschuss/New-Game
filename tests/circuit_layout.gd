extends SceneTree
# Circuit content/migration contracts; live physics and balance run separately.
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var physical=["ramp","peg","rotor","wall","trapdoor","reverse","breakable"]
 var early_kinds=[]
 for number in range(1,101):
  var level=Content.level_data(number)
  check(level==Content.level_data(number),"all one hundred new circuits repeat from the same seed")
  var pieces=level["pieces"]
  var solid_count=0;var portals=[]
  for piece in pieces:
   if String(piece["kind"]) in physical:solid_count+=1
   if piece["kind"]=="portal":portals.append(piece)
   if number<=3:early_kinds.append(piece["kind"])
   check(float(piece["x"])>60 and float(piece["x"])<480 and float(piece["y"])>580 and float(piece["y"])<820,"obstacles stay inside usable playfield and above collector")
  check(pieces.size()==(4 if number<50 else 5) and solid_count==(3 if number<50 else 4),"circuit has a sparse bounded physical obstacle budget")
  check(portals.size()==1,"each circuit has exactly one two-ended directional portal")
  var portal=portals[0]
  var entry=Vector2(portal["x"],portal["y"])
  var exit=Vector2(540-entry.x,entry.y+35)
  check(entry.y>560+25 and exit.y<665-20 and absf(entry.x-exit.x)>200,"portal crosses the field safely between multiplier rows")
  for piece in pieces:
   if piece["kind"]=="portal":continue
   var at=Vector2(piece["x"],piece["y"])
   check(at.distance_to(entry)>85 and at.distance_to(exit)>65,"portal mouths do not overlap physical obstacles")
  var powers=0
  for wave in range(1,int(level["waves"])+1):
   var gates=Content.wave_gates(number,wave,level["gates"])
   for gate in gates:
    check(int(gate["left"])!=1 and int(gate["right"])!=1,"x1 fields are absent from runtime gate plans")
   var power=Content.power_plan(number,wave)
   check(power==Content.power_plan(number,wave),"power scheduling has its own reproducible content seed")
   if not power.is_empty():
    powers+=1
    check(power["kind"] in ["energy","overdrive","shield"] and power["x"] in [140.0,400.0] and power["y"]==725.0,"occasional power occupies a clear lower route")
  check(Content.power_plan(number,1).is_empty() and powers>=1 and powers<=ceili(int(level["waves"])/3.0),"powers occur occasionally and never clutter the first wave")
 check("ramp" in early_kinds and "peg" in early_kinds and "rotor" in early_kinds,"tutorials teach distinct real ramp, bumper and moving obstacle interactions")
 var profile=Profile.new()
 profile.data["coins"]=3721;profile.data["unlocked"]=18;profile.data["stars"]={"1":3,"17":2}
 var old=Content.level_data(17)
 old.erase("circuit_version");old["seed"]=99887766;old["pieces"]=[];old["custom_note"]="preserve me"
 var original=old.duplicate(true)
 profile.data["layouts"]["17"]=old;profile.data["seeds"]["17"]=99887766
 var migrated=profile.get_level(17)
 check(migrated["pieces"]==Content.circuit_pieces(17,99887766) and int(migrated["circuit_version"])==Content.CIRCUIT_VERSION,"legacy circuit upgrades once from its own stored seed")
 for key in original:
  if key=="pieces":continue
  check(migrated[key]==original[key],"migration preserves original seed, gates and custom level metadata")
 check(profile.data["coins"]==3721 and profile.data["unlocked"]==18 and profile.data["stars"]=={"1":3,"17":2},"circuit migration cannot reset currency or campaign progress")
 check(profile.get_level(17)==migrated,"reloading an already revised circuit does not reroll it")
 migrated["pieces"][0]["x"]=-999
 check(profile.get_level(17)["pieces"][0]["x"]!=-999,"runtime mutations cannot rewrite the permanent circuit")
 check(profile.save_game(),"migrated old save remains writable")
 var restored=Profile.new()
 var loaded=restored.load_game()
 # JSON intentionally restores numeric IDs as floats; compare the serialized
 # value contract rather than requiring those IDs to retain Variant integer type.
 var expected_after_json=JSON.parse_string(JSON.stringify(profile.get_level(17)))
 check(loaded and restored.get_level(17)==expected_after_json,"versioned save reload retains every serialized migrated layout value")
 var power=Content.power_plan(3,2)
 power["kind"]="spent"
 check(Content.power_plan(3,2)["kind"]!="spent","runtime power consumption never changes the stored content plan")
 print("CIRCUIT LAYOUT RESULT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
