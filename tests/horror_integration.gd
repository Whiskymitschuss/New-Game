extends SceneTree
var game
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.profile.reset();game.start_level(1)
 game.stats["armor"]=0;game.stats["dodge"]=0
 game.shield=100
 var hp=game.hp
 game.blood_fx.reset();game.hurt_hero(10)
 check(game.hp==hp and game.blood_fx.particles.is_empty() and game.blood_fx.bursts.is_empty(),"shield-only impact cannot cause hero blood")
 game.shield=0;game.hurt_hero(10)
 check(game.hp<hp and not game.blood_fx.particles.is_empty(),"real hero HP damage triggers blood feedback")
 var e=game.spawn_enemy()
 game.blood_fx.reset();game.hit_enemy(e,1)
 check(not game.blood_fx.bursts.is_empty(),"actual enemy hit dispatches blood feedback")
 game.blood_fx.reset();game.hit_enemy(e,100000)
 check(e["dead"] and not game.blood_fx.stains.is_empty(),"actual enemy death leaves a finite floor stain")
 game.profile.data["settings"]["blood_fx"]=false;game.blood_fx.reset()
 e=game.spawn_enemy();game.hit_enemy(e,1)
 check(game.blood_fx.bursts.is_empty() and game.blood_fx.particles.is_empty(),"disabled blood setting guards real combat hooks")
 game.profile.data["settings"].erase("blood_fx")
 check(game.blood_fx.enabled(),"old saves without the new preference load with blood enabled")
 game.show_settings()
 var toggle
 for child in game.controls.get_children():
  if child is Button and child.text.begins_with("BLUTEFFEKTE:"):toggle=child
 check(is_instance_valid(toggle) and toggle.size.y>=44,"blood preference has a readable touch control")
 toggle.pressed.emit()
 var restored=Profile.new();restored.load_game()
 check(not bool(restored.data["settings"].get("blood_fx",true)),"blood preference persists through versioned save reload")
 game.start_level(1);game._process(0.25)
 var age=game.deployment_age
 game.pause_game();game._process(0.2)
 check(game.deployment_age==age,"hero arrival freezes with pause")
 game.mode="play";game.build_hud();game._process(0.1)
 check(game.deployment_age>age,"HUD rebuild does not restart hero arrival")
 game.start_level(2)
 check(game.deployment_age==0,"new deployment restarts its own visual arrival timer")
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame
 print("HORROR INTEGRATION RESULT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
