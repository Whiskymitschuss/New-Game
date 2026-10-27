extends SceneTree
# Real shots with valid campaign progression; no damage formula replicas.
var game
var checks=0
var failures=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func target(at: float) -> Dictionary:
 var enemy=game.spawn_enemy()
 enemy["type"]=0;enemy["x"]=at;enemy["y"]=310.0
 enemy["hp"]=10000.0;enemy["max_hp"]=10000.0
 return enemy
func configure(id: int) -> void:
 game.profile.reset()
 game.profile.data["unlocked"]=100
 for level in range(1,101):game.profile.data["stars"][str(level)]=1
 game.profile.data["weapon"]=id
 game.start_level(int(Content.WEAPONS[id][7]))
 game.set_physics_process(false)
 game.stats["crit"]=0.0;game.stats["damage"]=1.0
 game.enemies.clear();game.ammo=100;game.magazine=10
func run() -> void:
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 for id in range(Content.WEAPONS.size()):
  configure(id)
  var first=target(180)
  var unreachable=target(900)
  var before=game.ammo
  game.shoot()
  check(first["hp"]<10000,"unlocked weapon fires a real damaging shot: "+Content.WEAPONS[id][0])
  check(game.ammo==before-1 and game.magazine==9,"each weapon consumes one reserve and magazine round")
  check(unreachable["hp"]==10000,"a secondary target beyond weapon range remains unharmed")
  game.enemies.clear()
  var outside=target(95+float(Content.WEAPONS[id][5])+1)
  before=game.ammo
  game.shoot()
  check(game.ammo==before and outside["hp"]==10000,"no primary target in range means no ammunition is wasted")
 configure(1)
 var primary=target(180)
 var neighbour=target(190)
 game.shoot()
 check(primary["hp"]<10000 and neighbour["hp"]==10000,"revolver prioritises one target instead of outperforming crowd weapons with free penetration")
 configure(6)
 primary=target(180);neighbour=target(190)
 game.shoot()
 check(primary["hp"]<10000 and neighbour["hp"]<10000,"sniper retains its distinctive penetration")
 configure(0)
 primary=target(180)
 primary["type"]=2
 game.shoot()
 check(is_equal_approx(10000.0-primary["hp"],7.8),"armoured target actually reduces pistol damage")
 configure(0)
 game.stats["splash"]=20.0
 primary=target(180)
 var neighbours=[]
 for i in range(8):neighbours.append(target(190+i))
 var outside_radius=target(350)
 var outside_lane=target(190);outside_lane["y"]=410.0
 game.shoot()
 var hit_count=0
 for enemy in neighbours:
  if enemy["hp"]<10000:hit_count+=1
 check(hit_count==5,"area damage affects at most five nearby secondary enemies")
 check(outside_radius["hp"]==10000 and outside_lane["hp"]==10000,"area damage respects horizontal and vertical distance")
 configure(0)
 primary=target(400)
 var distant=target(500)
 game.energy=100;game.special_attack()
 check(primary["hp"]<10000 and distant["hp"]==10000,"impulse timing matters because distant fresh spawns are outside its radius")
 for i in range(10):game.energy=100;game.special_attack()
 check(game.shield<=float(game.stats["max_hp"])*0.75,"repeated impulses cannot create an unlimited shield reserve")
 game.shield=140;game.energy=100;game.special_attack()
 check(game.shield==140,"an existing stronger upgrade shield is preserved")
 print("WEAPON BALANCE RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(0 if failures==0 else 1)
