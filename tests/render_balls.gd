extends SceneTree
# Requires a real rendering backend (X11/Xvfb), not --headless.
var failures := 0
var checks := 0
var game
func check(condition: bool,message: String) -> void:
 checks+=1
 print(("PASS: " if condition else "FAIL: ")+message)
 if not condition:
  failures+=1
func frame_image() -> Image:
 await RenderingServer.frame_post_draw
 return root.get_texture().get_image()
func bright_pixels(image: Image,at: Vector2) -> int:
 var count:=0
 for y in range(-8,9):
  for x in range(-8,9):
   var px=clampi(roundi(at.x)+x,0,image.get_width()-1)
   var py=clampi(roundi(at.y)+y,0,image.get_height()-1)
   var c=image.get_pixel(px,py)
   if c.r>0.75 and c.g>0.8 and c.b>0.35:
    count+=1
 return count
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 game=load("res://main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 game.start_level(1)
 game.set_physics_process(false)
 game.emit_ball(Vector2(200,620),Vector2.ZERO)
 var ball: AmmoBall=game.pool[0]
 ball.freeze=true
 ball.visible=false # The renderer must be independent of pooled-body visibility.
 await process_frame
 var image: Image=await frame_image()
 check(bright_pixels(image,Vector2(200,620))>100,"actual white ball pixels cover a readable screen area")
 check(game.ball_visuals.z_index>game.z_index,"ball canvas explicitly draws above the maze")
 check(game.ball_visuals.rendered_count==1,"one pooled physics ball is rendered")
 game.clear_balls()
 image=await frame_image()
 check(bright_pixels(image,Vector2(200,620))<20,"deactivated pool slot leaves no phantom ball")
 game.emit_ball(Vector2(400,620),Vector2.ZERO,150)
 ball=game.pool[0]
 ball.freeze=true
 await process_frame
 image=await frame_image()
 check(bright_pixels(image,Vector2(400,620))>100,"virtual-quantity representative is visibly drawn")
 game.clear_balls()
 game.aim=410
 game.drop_ammo()
 check(game.pending_balls.size()==12 and game.active_balls()==0,"drop starts a bounded queued stream")
 var visible_frames:=0
 var all_emitted_at:=-1.0
 var run_time:=0.0
 for i in range(210):
  game.physics_balls(1.0/60.0)
  await physics_frame
  run_time+=1.0/60.0
  if game.pending_balls.is_empty() and all_emitted_at<0:
   all_emitted_at=run_time
  if i==24 or i==60:
   image=await frame_image()
   var matched:=0
   for active in game.pool:
    if active.live and active.position.y>505 and active.position.y<830:
     if bright_pixels(image,active.position)>35:
      matched+=1
   check(matched>0,"moving balls produce visible pixels at physics positions (frame %d)"%i)
   if i==60:
    image.save_png("res://builds/balls-v0.2.0.png")
  if game.active_balls()>0:
   visible_frames+=1
 check(all_emitted_at>=0.65,"twelve balls are staggered over at least 650 ms")
 check(visible_frames>=75,"visible physical stream lasts at least 1.25 seconds")
 check(game.collected>0,"visible stream reaches the ammunition collector")
 # Recycle the same server bodies several times; the original bug passed the first drop.
 for repeat in range(3):
  game.clear_balls()
  game.ammo=0
  game.attempts=2
  game.aim=400
  game.drop_ammo()
  for frame in range(65):
   game.physics_balls(1.0/60.0)
   await physics_frame
  image=await frame_image()
  var seen=0
  for recycled in game.pool:
   if recycled.live and recycled.position.y>505 and recycled.position.y<830 and bright_pixels(image,recycled.position)>35:
    seen+=1
  check(seen>0,"recycled drop %d still renders real moving balls"%(repeat+2))
 game.clear_balls()
 game.emit_ball(Vector2(200,520),Vector2.ZERO)
 game.pool[0].freeze=true
 image=await frame_image()
 check(bright_pixels(image,Vector2(200,520))>100,"pause regression starts with a visibly active ball")
 game.pause_game()
 image=await frame_image()
 check(not game.ball_visuals.visible,"ball foreground hides immediately when pausing")
 check(bright_pixels(image,Vector2(200,520))<20,"pause overlay contains no rendered ball pixels")
 print("RENDER RESULT: %d checks, %d failures"%[checks,failures])
 game.queue_free()
 await process_frame
 OS.delay_msec(150)
 await process_frame
 quit(0 if failures==0 else 1)
