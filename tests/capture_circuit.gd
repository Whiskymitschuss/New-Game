extends SceneTree
# One normal native-input run earns the belt, armor and powers shown in the media.
var game
var held_until=-1
var held_at=Vector2.ZERO
var aimed_wave=0
var last_mode=""
var mode_tick=0
var live_seen=false
var power_seen=false
var gear_seen=false
var gear_tick=0
var picked_power=false
var large=false
var film=false
var pilot=false
func _initialize() -> void:call_deferred("run")
func pointer(at: Vector2,down: bool) -> void:
 var input=InputEventMouseButton.new()
 input.position=at;input.global_position=at;input.button_index=MOUSE_BUTTON_LEFT
 input.pressed=down;input.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
 root.push_input(input)
func tap(at: Vector2,tick: int) -> void:
 held_at=at;held_until=tick+2;pointer(at,true)
func shot(name: String) -> void:
 if film or pilot:return
 if large:
  root.content_scale_size=Vector2i(540,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
  root.size=Vector2i(2160,3840)
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/circuit-"+name+".png")
 print("CIRCUIT CAPTURE ",name," ",root.size)
 if large:root.size=Vector2i(540,960)
func run() -> void:
 var args=OS.get_cmdline_user_args()
 large="--4k" in args;film="--film" in args;pilot="--pilot" in args
 root.content_scale_size=Vector2i(540,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 root.size=Vector2i(540,960)
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.profile.reset();game.show_menu()
 for tick in range(9000):
  if tick==held_until:pointer(held_at,false)
  if last_mode!=game.mode:last_mode=game.mode;mode_tick=tick
  if game.mode=="menu" and tick==60:tap(Vector2(270,725),tick)
  if game.mode=="play":
   var booster=game.wave_booster
   if not booster.is_empty() and bool(booster.get("consumed",false)):picked_power=true
   if tick>held_until:
    if aimed_wave!=game.wave:
     var aim=140.0
     if not booster.is_empty() and float(booster["x"])<270:aim=185.0
     tap(Vector2(aim,520),tick);aimed_wave=game.wave
    elif game.ammo<80 and game.active_balls()==0 and game.pending_balls.is_empty() and game.attempts>0:
     tap(Vector2(179,915),tick)
    elif game.energy>=65 and game.enemies.size()>3:
     tap(Vector2(433,915),tick)
    elif game.wave==2 and not picked_power and not booster.is_empty() and game.active_balls()==0 and game.pending_balls.is_empty() and game.attempts>0 and game.ammo<int(game.stats["capacity"]):
     tap(Vector2(179,915),tick)
    elif game.wave>=3 and not gear_seen and game.active_balls()==0 and game.attempts>0 and game.ammo<int(game.stats["capacity"]):
     tap(Vector2(179,915),tick)
   if tick>held_until:
    var transit=false
    for ball in game.pool:
     if ball.live and ball.portal_used:transit=true;break
    if not live_seen and game.wave==1 and transit:
     await shot("live");live_seen=true
    if not power_seen and game.wave==2 and not booster.is_empty() and not bool(booster.get("consumed",false)) and game.active_balls()>3:
     await shot("power");power_seen=true
    var gear=HeroGear.gear_state(game)
    if not gear_seen and game.wave>=3 and int(gear["belt"])>0 and int(gear["armor"])>0 and game.active_balls()>3 and tick-mode_tick>45:
     await shot("gear");gear_seen=true;gear_tick=tick
  elif game.mode=="upgrade" and tick>held_until and tick-mode_tick>25:
   var wanted=23 if game.wave==1 else 13
   var index=game.cards.find(wanted)
   if index<0:
    push_error("FAIL: tutorial media requires its real gear card offer");quit(1);return
   tap(Vector2(102+index*168,650),tick)
  elif game.mode=="defeat":break
  if gear_seen and tick-gear_tick>60:break
  await process_frame
 var gear=HeroGear.gear_state(game)
 var okay=live_seen and power_seen and gear_seen and picked_power and int(gear["belt"])>0 and int(gear["armor"])>0 and game.run_kills>=Content.wave_enemy_count(1,1)+Content.wave_enemy_count(1,2)
 print("CIRCUIT MEDIA RESULT: valid=",okay," wave=",game.wave," kills=",game.run_kills," drops=",game.dropped," belt=",gear["belt"]," armor=",gear["armor"]," power_collected=",picked_power," frame=",Engine.get_process_frames())
 if not okay:push_error("FAIL: normal media run must earn both equipment cards and collect a power capsule")
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(0 if okay else 1)
