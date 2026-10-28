extends SceneTree
# Gait phase/ground contact tests and optional actual renderer proof.
var checks=0
var failures=0
class Painter extends Node2D:
 var rig=preload("res://scripts/actor_rig.gd")
 var heroes: Texture2D=load("res://assets/art/heroes.png")
 var enemies: Texture2D=load("res://assets/art/enemies.png")
 var phase=0.0
 func _draw() -> void:
  draw_rect(Rect2(0,0,540,960),Color("071418"))
  rig.draw_hero(self,heroes,Rect2(52,11,603,697),Vector2(92,175),142,Color.WHITE,phase,0.3+phase)
  rig.draw_enemy(self,enemies,Rect2(529,10,495,502),Vector2(294,175),130,Color.WHITE,1,false,phase,24)
  rig.draw_enemy(self,enemies,Rect2(17,570,495,402),Vector2(440,175),83,Color.WHITE,4,false,phase,28)
  draw_line(Vector2(18,175),Vector2(520,175),Color("67cfce"),1)
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func run() -> void:
 var rig=preload("res://scripts/actor_rig.gd")
 var stance=rig.foot_cycle(0.20,0.05,0.03)
 var swing=rig.foot_cycle(0.81,0.05,0.03)
 check(stance.y==0 and swing.y<-0.029,"stance foot stays grounded while swing foot lifts")
 check(rig.foot_cycle(0.1,0.05,0.03).x<rig.foot_cycle(0.5,0.05,0.03).x,"contact foot moves backwards relative to left-moving enemy")
 check(rig.foot_cycle(0.1,0.05,0.03).is_equal_approx(rig.foot_cycle(1.1,0.05,0.03)),"gait wraps reproducibly after a full cycle")
 var same=rig.enemy_pose(1,false,0.31,24)
 check(same==rig.enemy_pose(1,false,0.31,24),"poses are deterministic without gameplay random state")
 check(same["feet"][0]!=same["feet"][1],"left/right legs have independently phased strides")
 check(rig.gait(1)["pace"]>rig.gait(2)["pace"] and rig.gait(1)["lift"]>rig.gait(2)["lift"],"runner lifts higher and cycles faster than armored heavy")
 check(rig.enemy_pose(4,false,0.31,28)["feet"].size()==4,"dog uses four separately phased leg strips")
 check(rig.gait(8)["hip"]>rig.gait(0)["hip"] and rig.gait(8)["lift"]<rig.gait(0)["lift"],"crawler uses a lower drag cycle")
 check(rig.enemy_pose(13,false,0.5,20)["feet"].is_empty(),"flying robot does not receive fictitious human legs")
 check(rig.gait(1,true)["name"]=="heavy" and rig.gait(4,true)["legs"]==2 and rig.gait(8,true)["name"]=="heavy","boss retains a deliberate heavy gait")
 var entry=rig.hero_pose(0.2,0.2)
 var idle=rig.hero_pose(5,4)
 check(entry["kind"]=="entry" and entry["entry"].x<0,"hero makes a short visual arrival step")
 check(idle["kind"]=="planted" and idle["entry"]==Vector2.ZERO and idle["feet"]==[Vector2.ZERO,Vector2.ZERO],"automatic shooting stance keeps both boots planted after entry")
 check(rig.hero_pose(0,0.68)["entry"]==Vector2.ZERO and rig.hero_pose(0,0.68)["feet"]==[Vector2.ZERO,Vector2.ZERO],"arrival completes without continuing to run in place")
 var max_lift=0.0
 var finite=true
 for kind in range(15):
  for tick in range(120):
   var pose=rig.enemy_pose(kind,false,tick/60.0,12+kind*2)
   for foot in pose["feet"]:
    finite=finite and foot.is_finite() and absf(foot.x)<0.08 and foot.y<=0.00001
    max_lift=maxf(max_lift,-foot.y)
 check(finite and max_lift>0.05,"all fifteen enemies retain finite bounded strides above the ground")
 for kind in [0,1,4,8,13]:
  var pose=rig.enemy_pose(kind,false,0.81,28,true)
  var quiet=pose["torso"]==Vector2.ZERO and pose["entry"]==Vector2.ZERO and pose["lean"]==0
  for foot in pose["feet"]:quiet=quiet and foot==Vector2.ZERO
  check(quiet,"reduced motion keeps all gait parts still")
 check(rig.hero_pose(10,0.1,true)["feet"]==[Vector2.ZERO,Vector2.ZERO] and rig.hero_pose(10,0.1,true)["entry"]==Vector2.ZERO,"reduced motion suppresses hero entry displacement")
 if "--render" in OS.get_cmdline_user_args():
  root.size=Vector2i(540,960)
  var painter=Painter.new();root.add_child(painter)
  await process_frame;await RenderingServer.frame_post_draw
  var before=root.get_texture().get_image()
  painter.phase=0.25;painter.queue_redraw()
  await process_frame;await RenderingServer.frame_post_draw
  var after=root.get_texture().get_image()
  var changed=0;var visible=0
  for y in range(110,174):
   for x in range(225,370):
    var a=before.get_pixel(x,y);var b=after.get_pixel(x,y)
    if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.15:changed+=1
    if b.r+b.g+b.b>0.35:visible+=1
  check(visible>500,"actual renderer shows the textured articulated actor")
  check(changed>150,"actual lower limb pixels move between gait phases")
  after.save_png("res://builds/actor-rig-proof.png")
  painter.queue_free();await process_frame
 print("ACTOR RIG RESULT: %d checks, %d failures"%[checks,failures])
 quit(1 if failures else 0)
