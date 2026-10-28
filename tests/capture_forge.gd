extends SceneTree
# A fresh profile earns the credits, buys real permanent modules, then deploys.
# All gameplay/menu actions use native pointer input; no currency or wins injected.
var game
var held_until=-1
var held_at=Vector2.ZERO
var last_mode=""
var mode_tick=0
var phase=0
var aimed_wave=0
var switched_drops=0
var special_seen=false
var live_seen=false
var bought_belt=false
var bought_armor=false
var deployed=false
var film=false
var pilot=false
var large=false
func _initialize() -> void:call_deferred("run")
func pointer(at: Vector2,down: bool) -> void:
 var event=InputEventMouseButton.new()
 event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT
 event.pressed=down;event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
 root.push_input(event)
func tap(at: Vector2,tick: int) -> void:
 held_at=at;held_until=tick+2;pointer(at,true)
func shot(name: String) -> void:
 if film or pilot:return
 RenderingServer.set_render_loop_enabled(true)
 if large:root.size=Vector2i(2160,3840)
 for i in range(4):await process_frame
 await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://builds/forge-"+name+"-v0.2.8.png")
 print("FORGE CAPTURE ",name," ",root.size)
 if large:root.size=Vector2i(540,960)
 RenderingServer.set_render_loop_enabled(false)
func card_choice() -> int:
 var wanted=23 if game.wave==1 else 13
 var preferred=game.cards.find(wanted)
 if game.wave<=2 and preferred>=0:return preferred
 var best=-1;var choice=0
 for i in range(game.cards.size()):
  var key=String(Content.UPGRADES[game.cards[i]][2])
  var score=3 if key in ["damage","speed","pierce","multishot","splash"] else 0
  if game.ammo<80 and key in ["ammo","collection","drop","attempt"]:score=4
  if score>best:best=score;choice=i
 return choice
func run() -> void:
 var args=OS.get_cmdline_user_args()
 film="--film" in args;pilot="--pilot" in args;large="--4k" in args
 root.content_scale_size=Vector2i(540,960);root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 root.size=Vector2i(540,960)
 if not film and not pilot:RenderingServer.set_render_loop_enabled(false)
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.profile.reset();game.show_menu()
 for tick in range(18000):
  if tick==held_until:pointer(held_at,false)
  if last_mode!=game.mode:last_mode=game.mode;mode_tick=tick;print("FORGE NATIVE mode=",last_mode," phase=",phase," tick=",tick," credits=",game.profile.data["coins"])
  if tick>held_until:
   if game.mode=="menu":
    if phase==0 and tick>45:tap(Vector2(270,725),tick);phase=1
    elif phase==2 and tick-mode_tick>20:tap(Vector2(270,875),tick);phase=3
    elif phase==4 and tick-mode_tick>20:tap(Vector2(270,725),tick);phase=5;aimed_wave=0
   elif game.mode=="play":
    if game.ammo_cargo.total()>0:special_seen=true
    if phase==5 and not deployed:
     deployed=true
     var valid=Workshop.rank(game.profile.data,"belt")==1 and Workshop.rank(game.profile.data,"armor")==1 and game.stats["capacity"]==Content.ammo_capacity(2)+40 and game.stats["armor"]==1
     if not valid:push_error("FAIL: earned workshop modules must apply on the next real deployment");break
    if aimed_wave!=game.wave:
     tap(Vector2(140,520),tick);aimed_wave=game.wave
    elif game.reactor_switch.can_toggle() and game.active_balls()>3:
     tap(Vector2(324,915),tick);switched_drops+=1
    elif game.ammo<80 and game.active_balls()==0 and game.pending_balls.is_empty() and game.attempts>0:
     tap(Vector2(138,915),tick)
    elif game.energy>=65 and game.enemies.size()>3:tap(Vector2(456,915),tick)
    if not live_seen and game.active_balls()>5 and game.reactor_switch.spent and special_seen:
     await shot("gameplay");live_seen=true
    if phase==5 and tick-mode_tick>210:break
   elif game.mode=="upgrade" and tick-mode_tick>25:
    tap(Vector2(102+card_choice()*168,650),tick)
   elif game.mode=="victory" and phase==1 and tick-mode_tick>35:
    tap(Vector2(394,841),tick);phase=2
   elif game.mode=="workshop" and tick-mode_tick>25:
    if not bought_belt:
     tap(Vector2(426,453),tick);bought_belt=true
    elif not bought_armor and Workshop.rank(game.profile.data,"belt")==1:
     tap(Vector2(426,607),tick);bought_armor=true
    elif bought_armor and Workshop.rank(game.profile.data,"armor")==1 and tick-mode_tick>100:
     await shot("workshop");tap(Vector2(270,912),tick);phase=4
   elif game.mode=="defeat":break
  await process_frame
 var valid=phase==5 and deployed and live_seen and special_seen and switched_drops>0 and Workshop.rank(game.profile.data,"belt")==1 and Workshop.rank(game.profile.data,"armor")==1 and int(game.profile.data["stars"].get("1",0))>0
 print("FORGE MEDIA RESULT: valid=",valid," phase=",phase," sector=",game.level," switches=",switched_drops," special=",special_seen," credits=",game.profile.data["coins"]," belt=",Workshop.rank(game.profile.data,"belt")," armor=",Workshop.rank(game.profile.data,"armor")," frame=",Engine.get_process_frames())
 if not valid:push_error("FAIL: native media must earn victory, buy two modules and redeploy with their actual bonuses")
 game.queue_free();await process_frame;OS.delay_msec(150);await process_frame;quit(0 if valid else 1)
