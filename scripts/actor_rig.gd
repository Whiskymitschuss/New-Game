class_name ActorRig
extends RefCounted
# A small textured cutout rig. Torso/weapon stay together; thighs, knees and feet
# deform independently below a shared hip seam. This never owns gameplay state.
const ENTRY_SECONDS := 0.68
const HIP := 0.57
const KNEE := 0.79
const ANKLE := 0.94

static func foot_cycle(phase: float,reach: float,lift: float) -> Vector2:
 var t=fposmod(phase,1.0)
 # A longer contact phase gives weight. During contact the foot moves backwards
 # relative to the moving body while remaining exactly on the ground plane.
 if t<0.62:return Vector2(lerpf(-reach,reach,t/0.62),0)
 var swing=(t-0.62)/0.38
 return Vector2(cos(swing*PI)*reach,-sin(swing*PI)*lift)

static func gait(kind: int,boss: bool=false) -> Dictionary:
 var result={"pace":1.20,"reach":0.042,"lift":0.027,"sway":0.012,"hip":HIP,"legs":2,"lean":0.0,"name":"shuffle"}
 if kind in [1,4]:
  result.merge({"pace":2.10,"reach":0.073,"lift":0.057,"sway":0.016,"lean":-0.025,"name":"run"},true)
 if kind in [2,3,9,14] or boss:
  result.merge({"pace":0.83,"reach":0.030,"lift":0.018,"sway":0.019,"lean":0.008,"name":"heavy"},true)
 if kind==4 and not boss:
  result.merge({"pace":2.6,"legs":4,"hip":0.53,"reach":0.060,"lift":0.046,"sway":0.012,"name":"quadruped"},true)
 elif kind==8 and not boss:
  result.merge({"pace":0.96,"reach":0.032,"lift":0.011,"hip":0.66,"lean":-0.020,"name":"crawl"},true)
 elif kind==13 and not boss:
  result.merge({"pace":1.5,"legs":0,"reach":0.0,"lift":0.0,"sway":0.016,"name":"hover"},true)
 return result

static func enemy_pose(kind: int,boss: bool,age: float,speed: float=17.0,reduced: bool=false) -> Dictionary:
 var preset=gait(kind,boss)
 var pace=float(preset["pace"])*clampf(speed/20.0,0.65,1.5)
 var phase=age*pace
 var feet:Array[Vector2]=[]
 var knees:Array[Vector2]=[]
 var offsets=[0.0,0.5] if int(preset["legs"])!=4 else [0.0,0.5,0.25,0.75]
 for i in range(int(preset["legs"])):
  var foot=Vector2.ZERO if reduced else foot_cycle(phase+offsets[i],float(preset["reach"]),float(preset["lift"]))
  feet.append(foot)
  knees.append(Vector2(foot.x*0.45,foot.y*0.48))
 var bob=0.0 if reduced else -absf(sin(phase*TAU))*float(preset["sway"])
 if int(preset["legs"])==0:bob=0.0 if reduced else sin(age*3.4)*float(preset["sway"])
 return {"feet":feet,"knees":knees,"torso":Vector2(0,bob),"lean":0.0 if reduced else float(preset["lean"])+sin(phase*TAU)*0.010,"entry":Vector2.ZERO,"hip":preset["hip"],"legs":preset["legs"],"kind":preset["name"]}

static func hero_pose(clock: float,entry_age: float,reduced: bool=false) -> Dictionary:
 var feet:Array[Vector2]=[Vector2.ZERO,Vector2.ZERO]
 var knees:Array[Vector2]=[Vector2.ZERO,Vector2.ZERO]
 var entry=Vector2.ZERO
 var torso=Vector2.ZERO
 var lean=0.0
 if not reduced:
  torso=Vector2(sin(clock*1.6)*0.002,-sin(clock*3.0)*0.003)
  # Only the short arrival has steps. Shooting stance keeps boots planted.
  if entry_age>=0 and entry_age<ENTRY_SECONDS:
   var blend=1-smoothstep(0.46,ENTRY_SECONDS,entry_age)
   var arrive=1-pow(1-clampf(entry_age/ENTRY_SECONDS,0,1),3)
   entry.x=-0.13*(1-arrive)
   for i in range(2):
    feet[i]=foot_cycle(entry_age*2.1+i*0.5,0.044,0.035)*blend
    knees[i]=feet[i]*Vector2(0.45,0.48)
   lean=sin(entry_age*TAU*2.1)*0.010*blend
 return {"feet":feet,"knees":knees,"torso":torso,"lean":lean,"entry":entry,"hip":HIP,"legs":2,"kind":"entry" if entry_age>=0 and entry_age<ENTRY_SECONDS and not reduced else "planted"}

static func quad(canvas: Node2D,texture: Texture2D,source: Rect2,width: float,height: float,uv_rect: Rect2,offsets: Array,tint: Color) -> void:
 var corners=[uv_rect.position,Vector2(uv_rect.end.x,uv_rect.position.y),uv_rect.end,Vector2(uv_rect.position.x,uv_rect.end.y)]
 var points=PackedVector2Array()
 var uvs=PackedVector2Array()
 var tex_size=texture.get_size()
 for i in range(4):
  points.append(Vector2((corners[i].x-0.5)*width,(corners[i].y-1)*height)+offsets[i])
  uvs.append((source.position+corners[i]*source.size)/tex_size)
 canvas.draw_polygon(points,PackedColorArray([tint]),uvs,texture)

static func draw_pose(canvas: Node2D,texture: Texture2D,source: Rect2,base: Vector2,height: float,tint: Color,pose: Dictionary,quality: int=1,angle: float=0.0,body_scale: Vector2=Vector2.ONE) -> void:
 if texture==null or source.size.x<=0 or source.size.y<=0:return
 var h=maxf(1,height)
 var width=h*source.size.x/source.size.y
 var torso: Vector2=pose["torso"]*h
 var hip=float(pose["hip"])
 canvas.draw_set_transform(base+pose["entry"]*h,angle,body_scale)
 var legs=int(pose["legs"])
 if legs==0:
  canvas.draw_texture_rect_region(texture,Rect2(Vector2(-width*0.5,-h)+torso,Vector2(width,h)),source,tint)
  canvas.draw_set_transform(Vector2.ZERO)
  return
 # All hip seam vertices coincide with the torso bottom; no torn rectangles.
 # Boots share one displacement with ankles, so they do not stretch in stance.
 var upper_sway=torso+Vector2(float(pose["lean"])*h,0)
 var shared_hip=torso*0.35
 for i in range(legs):
  var x0=float(i)/legs
  var x1=float(i+1)/legs
  var foot: Vector2=pose["feet"][i]*h
  var knee: Vector2=pose["knees"][i]*h
  var knee_row=maxf(hip+0.08,KNEE)
  if quality==0:
   quad(canvas,texture,source,width,h,Rect2(x0,hip,x1-x0,1-hip),[shared_hip,shared_hip,foot,foot],tint)
  else:
   quad(canvas,texture,source,width,h,Rect2(x0,hip,x1-x0,knee_row-hip),[shared_hip,shared_hip,knee,knee],tint)
   quad(canvas,texture,source,width,h,Rect2(x0,knee_row,x1-x0,ANKLE-knee_row),[knee,knee,foot,foot],tint)
   quad(canvas,texture,source,width,h,Rect2(x0,ANKLE,x1-x0,1-ANKLE),[foot,foot,foot,foot],tint)
 quad(canvas,texture,source,width,h,Rect2(0,0,1,hip),[upper_sway,upper_sway,shared_hip,shared_hip],tint)
 canvas.draw_set_transform(Vector2.ZERO)

static func draw_hero(canvas: Node2D,texture: Texture2D,source: Rect2,base: Vector2,height: float,tint: Color,clock: float,entry_age: float,reduced: bool=false,quality: int=1,angle: float=0.0,body_scale: Vector2=Vector2.ONE) -> void:
 draw_pose(canvas,texture,source,base,height,tint,hero_pose(clock,entry_age,reduced),quality,angle,body_scale)

static func draw_enemy(canvas: Node2D,texture: Texture2D,source: Rect2,base: Vector2,height: float,tint: Color,kind: int,boss: bool,age: float,speed: float=17.0,reduced: bool=false,quality: int=1,angle: float=0.0,body_scale: Vector2=Vector2.ONE) -> void:
 draw_pose(canvas,texture,source,base,height,tint,enemy_pose(kind,boss,age,speed,reduced),quality,angle,body_scale)
