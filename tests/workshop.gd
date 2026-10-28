extends SceneTree
# Permanent currency transactions and ordinary new deployments, with a disposable
# user profile selected by the runner. No player save is reset by this suite.
var checks=0
var failures=0
class FailedProfile extends Profile:
 func save_game() -> bool:return false
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func proof(data: Dictionary,sector: int) -> void:data["stars"][str(sector)]=1
func purchase_button(game: Node,key: String) -> Button:
 for child in game.controls.get_children():
  if child is Button and child.get_meta("workshop_track","")==key:return child
 return null
func native_click(at: Vector2) -> void:
 for down in [true,false]:
  var event=InputEventMouseButton.new()
  event.position=at;event.global_position=at;event.button_index=MOUSE_BUTTON_LEFT
  event.pressed=down;event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
  root.push_input(event)
  await process_frame
func render_workshop(game: Node) -> void:
 # Explicit bench fixture, never presented as an earned gameplay recording.
 root.size=Vector2i(540,960);root.content_scale_size=Vector2i(540,960)
 root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 game.profile=Profile.new();game.profile.data["coins"]=10000
 game.profile.data["settings"]["reduced_motion"]=true
 for sector in [1,5,10]:proof(game.profile.data,sector)
 var view=WorkshopView.new(game);view.build()
 for frame in range(4):await process_frame
 await RenderingServer.frame_post_draw
 var before=root.get_texture().get_image()
 check(before.get_size()==Vector2i(540,960),"workshop renders at the native portrait viewport")
 for child in game.controls.get_children():
  if not child is Control:continue
  var bounds=child.get_global_rect()
  check(bounds.position.x>=0 and bounds.position.y>=0 and bounds.end.x<=540.1 and bounds.end.y<=960.1,"visible workshop control stays inside the portrait viewport: %s"%child.name)
  if child is Button:
   check(child.size.x>=44 and child.size.y>=44,"workshop buttons retain a usable native touch target")
 for key in Workshop.KEYS:
  for rank in range(3):
   var button=purchase_button(game,key)
   check(is_instance_valid(button) and not button.disabled,"earned bench fixture stage is available through its actual UI")
   if not is_instance_valid(button) or button.disabled:continue
   await native_click(button.get_global_rect().get_center())
   check(Workshop.rank(game.profile.data,key)==rank+1,"native pointer purchase updates the displayed permanent stage")
 for frame in range(4):await process_frame
 await RenderingServer.frame_post_draw
 var after=root.get_texture().get_image()
 var changed=0;var outside=0
 for y in range(960):
  for x in range(540):
   var a=before.get_pixel(x,y);var b=after.get_pixel(x,y)
   if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)<0.1:continue
   if x>=60 and x<230 and y>=190 and y<345:changed+=1
   if y>=350 and y<367:outside+=1
 check(changed>80,"actual suit preview visibly gains body-mounted permanent equipment")
 check(outside==0,"equipment changes stay within the preview and leave its lower separator clear")
 check(game.profile.data["coins"]==4600,"all nine native bench purchases pay their exact credit cost")
 after.save_png("res://builds/workshop-render-proof.png")
func run() -> void:
 var profile=Profile.new()
 for key in Workshop.KEYS:
  check(Workshop.rank(profile.data,key)==0,"fresh suit begins with no permanent %s module"%key)
  check(Workshop.next_cost(profile.data,key)==180,"first permanent module has a real credit price")
 var original=profile.data.duplicate(true)
 Workshop.rank(profile.data,"belt");Workshop.next_cost(profile.data,"armor")
 check(profile.data==original,"reading workshop information never edits the profile")
 profile.data["coins"]=10000;profile.data["unlocked"]=100;profile.add_xp(100000)
 original=profile.data.duplicate(true)
 check(not Workshop.buy(profile.data,"belt") and profile.data==original,"hero XP and sector reach cannot bypass actual completion proof")
 proof(profile.data,1)
 profile.data["coins"]=179;original=profile.data.duplicate(true)
 check(not Workshop.buy(profile.data,"belt") and profile.data==original,"insufficient funds preserve credits and equipment")
 profile.data["coins"]=10000
 var spent=0
 for key in Workshop.KEYS:
  for current in range(3):
   var price=Workshop.next_cost(profile.data,key)
   check(price==[180,540,1080][current],"module prices rise across three meaningful stages")
   if current>0:
    var sector=[1,5,10][current]
    # A prior purchased track may already have unlocked this proof. Remove it
    # temporarily, so each track independently exercises the real guard.
    profile.data["stars"].erase(str(sector))
    proof(profile.data,sector-1)
    original=profile.data.duplicate(true)
    check(not Workshop.buy(profile.data,key,current) and profile.data==original,"entering the next area is not the required win proof")
    proof(profile.data,sector)
   check(Workshop.buy(profile.data,key,current),"ordinary valid purchase raises exactly one module")
   spent+=price
   check(Workshop.rank(profile.data,key)==current+1,"rank and paid stage stay aligned")
   original=profile.data.duplicate(true)
   check(not Workshop.buy(profile.data,key,current) and profile.data==original,"stale expected rank cannot purchase a second stage")
  original=profile.data.duplicate(true)
  check(Workshop.next_cost(profile.data,key)==0 and not Workshop.buy(profile.data,key) and profile.data==original,"maximum rank has no further paid transaction")
 check(profile.data["coins"]==10000-spent and spent==5400,"all nine module purchases deduct their exact combined price")
 original=profile.data.duplicate(true)
 check(not Workshop.buy(profile.data,"unknown") and Workshop.rank(profile.data,"unknown")==0 and profile.data==original,"unknown module requests cannot alter credits or rank")
 var full=profile.data.duplicate(true)
 var stats={"capacity":248.0,"armor":0.0,"damage":1.25,"speed":1.0}
 Workshop.apply_stats(full,stats)
 check(stats["capacity"]==368 and stats["armor"]==3 and is_equal_approx(stats["damage"],1.4375),"permanent modules add bounded capacity/armor and multiply class damage")
 check(stats["speed"]==1 and profile.data==full,"applying equipment does not invent a speed buff or mutate the profile")
 var corrupt=Profile.new().data
 corrupt["equipment"]={"legacy_holster":{"skin":"rust"},"workshop":{"belt":99,"armor":-8,"weapon":"3","future_module":"preserve"}}
 Workshop.sanitize(corrupt)
 check(Workshop.rank(corrupt,"belt")==3 and Workshop.rank(corrupt,"armor")==0 and Workshop.rank(corrupt,"weapon")==0,"malformed saved module ranks are bounded or default safely")
 check(corrupt["equipment"]["legacy_holster"]["skin"]=="rust" and corrupt["equipment"]["workshop"]["future_module"]=="preserve","migration preserves unknown equipment and module fields")
 corrupt["equipment"]["workshop"]["belt"]=NAN
 corrupt["equipment"]["workshop"]["armor"]=INF
 Workshop.sanitize(corrupt)
 check(Workshop.rank(corrupt,"belt")==0 and Workshop.rank(corrupt,"armor")==0,"non-finite ranks never become purchased equipment")
 profile.reset()
 profile.data["coins"]=934;profile.data["equipment"]={"legacy_holster":{"skin":"rust"}}
 proof(profile.data,1);profile.data["settings"]["music"]=0.15
 profile.data["seeds"]={"2":812345};profile.data["abilities"]=[13]
 check(profile.save_game(),"an old v1 profile without workshop modules still saves")
 var restored=Profile.new()
 check(restored.load_game(),"old v1 save loads through workshop migration")
 check(restored.data["version"]==1 and Workshop.rank(restored.data,"belt")==0 and restored.data["coins"]==934,"migration keeps save version, credits and zero unearned ranks")
 check(restored.data["equipment"]["legacy_holster"]["skin"]=="rust" and int(restored.data["seeds"]["2"])==812345 and int(restored.data["stars"]["1"])==1,"equipment, level seeds and stars survive migration")
 check(is_equal_approx(restored.data["settings"]["music"],0.15) and int(restored.data["abilities"][0])==13,"settings and learned abilities survive migration")
 check(Workshop.buy(restored.data,"belt",0) and restored.save_game(),"a legitimate permanent purchase is written to the existing save")
 var reload=Profile.new();reload.load_game()
 check(Workshop.rank(reload.data,"belt")==1 and reload.data["coins"]==754,"paid module and its exact cost survive an app restart")
 if not "--model-only" in OS.get_cmdline_user_args():
  var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
  game.set_process(false);game.set_physics_process(false)
  game.profile.data=full.duplicate(true);game.start_level(1)
  check(game.stats["capacity"]==Content.ammo_capacity(1)+120 and game.stats["armor"]==3,"a real deployment receives the permanent modules")
  check(is_equal_approx(game.stats["damage"],float(Content.CLASSES[0]["damage"])*1.15),"actual combat damage uses the permanent weapon module")
  var gear=HeroGear.gear_state(game)
  check(gear["belt"]==3 and gear["armor"]==3 and gear["weapon"]==3,"all three permanent stages are visibly reflected by the real hero")
  game.apply_upgrade(13)
  check(game.stats["armor"]==6,"run armor adds to the permanent suit instead of replacing it")
  game.start_level(2)
  check(game.stats["armor"]==3 and game.stats["capacity"]==Content.ammo_capacity(2)+120,"the next deployment removes run bonuses and applies permanent modules exactly once")
  game.profile.reset();game.profile.data["coins"]=1000;proof(game.profile.data,1)
  var before_preview=game.profile.data.duplicate(true)
  var before_run=game.stats.duplicate(true)
  var view=WorkshopView.new(game);view.build();await process_frame
  check(game.profile.data==before_preview and game.stats==before_run,"workshop preview does not mutate the profile or previous combat stats")
  var belt=purchase_button(game,"belt")
  check(is_instance_valid(belt) and belt.size.y>=44 and not belt.disabled,"workshop exposes an eligible module through a proper native touch control")
  if is_instance_valid(belt):
   belt.pressed.emit()
   check(Workshop.rank(game.profile.data,"belt")==1 and game.profile.data["coins"]==820,"native workshop button makes a real saved purchase")
   var spent_once=game.profile.data["coins"]
   if is_instance_valid(belt):belt.pressed.emit()
   check(game.profile.data["coins"]==spent_once,"stale UI callback cannot spend currency twice")
   await process_frame
   var saved=Profile.new();saved.load_game()
   check(Workshop.rank(saved.data,"belt")==1 and saved.data["coins"]==820,"native UI purchase persists immediately")
  var failure_profile=FailedProfile.new();failure_profile.data=before_preview.duplicate(true)
  game.profile=failure_profile;view.build();await process_frame
  var failed_button=purchase_button(game,"belt")
  if is_instance_valid(failed_button):failed_button.pressed.emit();await process_frame
  check(game.profile.data==before_preview,"a failed disk save rolls back both rank and credits")
  var feedback=false
  for child in game.controls.get_children():
   if child is Label and child.get_meta("workshop_feedback",false) and child.text.to_lower().contains("fehlgeschlagen"):feedback=true
  check(feedback,"failed persistence gives visible feedback instead of a false upgrade confirmation")
  if "--render" in OS.get_cmdline_user_args():await render_workshop(game)
  game.queue_free();await process_frame;OS.delay_msec(150);await process_frame
 print("WORKSHOP RESULT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
