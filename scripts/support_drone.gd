class_name SupportDrone
extends Node2D
# Presentation only. Combat decides every shot, target, damage and cooldown.
const STAGE := Rect2(0,121,540,229)
const ANCHOR := Vector2(132,192)
const MUZZLE := Vector2(28,6)
const ICE := Color("95eeed")
const STEEL := Color("7c9a9c")
const PALE := Color("d7e4dc")
class PaintLayer extends Node2D:
 var drone
 func _draw() -> void:drone.paint(self)
var game: Node2D
var clock := 0.0
var recoil := 0.0
var shot_left := 0.0
var aim_angle := 0.0
var target := Vector2.ZERO
var clipper: Control
var painter: PaintLayer
var glow: GradientTexture2D

func _ready() -> void:
 z_index=9
 var gradient=Gradient.new()
 gradient.offsets=PackedFloat32Array([0,0.24,0.65,1])
 gradient.colors=PackedColorArray([Color(1,1,1,0.8),Color(1,1,1,0.24),Color(1,1,1,0.04),Color(1,1,1,0)])
 glow=GradientTexture2D.new()
 glow.gradient=gradient;glow.width=48;glow.height=48
 glow.fill=GradientTexture2D.FILL_RADIAL
 glow.fill_from=Vector2(0.5,0.5);glow.fill_to=Vector2(1,0.5)
 clipper=Control.new()
 clipper.position=STAGE.position;clipper.size=STAGE.size
 clipper.clip_contents=true;clipper.mouse_filter=Control.MOUSE_FILTER_IGNORE
 add_child(clipper)
 painter=PaintLayer.new();painter.drone=self;painter.position=-STAGE.position
 clipper.add_child(painter)
 visible=running()

func supported() -> bool:
 if not is_instance_valid(game):return false
 var stats=game.get("stats")
 return stats is Dictionary and float(stats.get("drone",0))>0

func running() -> bool:
 return supported() and String(game.get("mode"))=="play"

func reduced_motion() -> bool:
 if not is_instance_valid(game):return false
 var profile=game.get("profile")
 return profile!=null and bool(profile.data.get("settings",{}).get("reduced_motion",false))

func quality() -> int:return 0 if is_instance_valid(game) and int(game.get("quality"))==0 else 1

func reset() -> void:
 clock=0;recoil=0;shot_left=0;aim_angle=0;target=Vector2.ZERO
 visible=running()
 if is_instance_valid(painter):painter.queue_redraw()

func position_for() -> Vector2:
 if reduced_motion():return ANCHOR
 return ANCHOR+Vector2(sin(clock*1.55)*1.15-recoil*1.65,sin(clock*2.2)*1.6)

func angle_for() -> float:
 if reduced_motion():return 0.0
 return clampf(aim_angle+sin(clock*1.55)*0.018-recoil*0.025,-0.07,0.13)

func muzzle_position() -> Vector2:
 return position_for()+MUZZLE.rotated(angle_for())

func on_shot(target_at: Vector2) -> void:
 if not running():return
 target=target_at
 aim_angle=clampf((target_at-position_for()).angle(),-0.045,0.115)
 recoil=0.0 if reduced_motion() else 1.0
 shot_left=0.16
 if is_instance_valid(painter):painter.queue_redraw()

func _process(delta: float) -> void:
 visible=running()
 if not running():return
 var elapsed=maxf(0,delta)
 clock+=elapsed
 recoil=maxf(0,recoil-elapsed*8)
 shot_left=maxf(0,shot_left-elapsed)
 # Aim slowly returns to a neutral patrol pose after the real shot.
 if shot_left<=0:aim_angle=move_toward(aim_angle,0,elapsed*0.22)
 if is_instance_valid(painter):painter.queue_redraw()

func ellipse(canvas: Node2D,at: Vector2,radii: Vector2,color: Color) -> void:
 var points=PackedVector2Array()
 for i in range(24):
  var angle=TAU*i/24.0
  points.append(at+Vector2(cos(angle)*radii.x,sin(angle)*radii.y))
 canvas.draw_colored_polygon(points,color)

func outline(canvas: Node2D,points: PackedVector2Array,color: Color,width: float=1.0) -> void:
 var closed=points.duplicate();closed.append(points[0])
 canvas.draw_polyline(closed,color,width,true)

func halo(canvas: Node2D,at: Vector2,size: Vector2,color: Color,alpha: float) -> void:
 if glow!=null:canvas.draw_texture_rect(glow,Rect2(at-size*0.5,size),false,Color(color,alpha))

func engine(canvas: Node2D,at: Vector2,phase: float) -> void:
 # A visible circular turbine within a substantial metal duct, not a rotor bar.
 var lip=PackedVector2Array([at+Vector2(-7,-3),at+Vector2(-5,-6),at+Vector2(4,-6),at+Vector2(7,-3),at+Vector2(7,4),at+Vector2(4,7),at+Vector2(-4,7),at+Vector2(-7,4)])
 canvas.draw_colored_polygon(lip,Color("17282e"))
 outline(canvas,lip,Color("738e90"),1)
 ellipse(canvas,at+Vector2(0,-2),Vector2(5.4,3.8),Color("09171e"))
 var spin=0.0 if reduced_motion() else clock*7.0+phase
 for i in range(3 if quality()==1 else 2):
  var angle=spin+i*TAU/3
  var tip=Vector2(cos(angle)*4,sin(angle)*2.5)
  canvas.draw_line(at+Vector2(0,-2)-tip*0.3,at+Vector2(0,-2)+tip,Color("608c8d"),1.3,true)
 canvas.draw_circle(at+Vector2(0,-2),1.4,ICE)
 canvas.draw_line(at+Vector2(-4,3),at+Vector2(4,3),Color("9ab3ae"),0.8,true)
 var pulse=1.0 if reduced_motion() else 0.85+sin(clock*8+phase)*0.15
 halo(canvas,at+Vector2(0,8),Vector2(17,18),ICE,0.24*pulse)
 var plume=PackedVector2Array([at+Vector2(-2.8,6),at+Vector2(-2,11),at+Vector2(0,15+int(phase)%2),at+Vector2(2,11),at+Vector2(2.8,6)])
 canvas.draw_colored_polygon(plume,Color(ICE,0.17*pulse))
 canvas.draw_line(at+Vector2(-2,6),at+Vector2(2,6),Color(ICE,0.95),1.6,true)
 canvas.draw_line(at+Vector2(0,7),at+Vector2(0,11),Color("d6ffff"),0.9,true)

func paint(canvas: Node2D) -> void:
 if not running():return
 canvas.draw_set_transform(position_for(),angle_for())
 # Soft downwash and restrained rim light place the craft in the same scene.
 halo(canvas,Vector2(0,5),Vector2(63,37),ICE,0.1)
 engine(canvas,Vector2(-18,-1),0.0)
 engine(canvas,Vector2(18,-1),2.0)
 # Swept supports lead into one continuous, faceted armored hull.
 var strut=PackedVector2Array([Vector2(-22,-4),Vector2(-10,-7),Vector2(10,-7),Vector2(22,-4),Vector2(21,1),Vector2(10,-1),Vector2(-10,-1),Vector2(-21,1)])
 canvas.draw_colored_polygon(strut,Color("4d696d"))
 var hull=PackedVector2Array([Vector2(-15,-9),Vector2(-7,-12),Vector2(7,-11),Vector2(17,-6),Vector2(20,0),Vector2(14,6),Vector2(-7,7),Vector2(-16,2),Vector2(-18,-3)])
 canvas.draw_colored_polygon(hull,Color("263d46"))
 outline(canvas,hull,Color("9eb5ae"),1.1)
 canvas.draw_colored_polygon(PackedVector2Array([Vector2(-15,-8),Vector2(-7,-11),Vector2(6,-10),Vector2(13,-6),Vector2(-6,-5)]),Color("718d8d"))
 canvas.draw_colored_polygon(PackedVector2Array([Vector2(-16,-2),Vector2(-5,-4),Vector2(10,-3),Vector2(14,4),Vector2(-7,5)]),Color("3a5660"))
 canvas.draw_line(Vector2(-12,-7),Vector2(4,-8),Color("bfd1c5"),1,true)
 canvas.draw_line(Vector2(-8,5),Vector2(8,5),Color("0d1f28"),1.3,true)
 # Three intake slots and small fasteners keep the craft legible at phone scale.
 for i in range(3):canvas.draw_line(Vector2(-11+i*4,-2),Vector2(-10+i*4,1.5),Color("132930"),1.5,true)
 for at in [Vector2(-12,-5),Vector2(5,-8),Vector2(-7,3)]:canvas.draw_circle(at,0.7,PALE)
 canvas.draw_line(Vector2(-9,-12),Vector2(-12,-15),Color("536f76"),1.4,true)
 canvas.draw_circle(Vector2(-12,-15),0.9,Color("d8b580"))
 # A forward camera is recessed into a steel gimbal with an offset pupil/glint.
 ellipse(canvas,Vector2(14,-1),Vector2(6.1,5.3),Color("0c1d26"))
 canvas.draw_arc(Vector2(14,-1),4.6,-1.4,1.6,16,STEEL,1.5,true)
 halo(canvas,Vector2(15,-1),Vector2(17,17),ICE,0.34)
 canvas.draw_circle(Vector2(15,-1),3.2,Color("31666b"))
 canvas.draw_circle(Vector2(15.5,-1),2.15,ICE)
 canvas.draw_circle(Vector2(16.2,-2),0.85,Color("efffff"))
 canvas.draw_line(Vector2(7,8),Vector2(25,8),Color("0c202a"),4.4,true)
 canvas.draw_line(Vector2(9,6),Vector2(25,6),Color("829e9a"),2.5,true)
 canvas.draw_line(Vector2(15,6),Vector2(25,6),Color("c6d6ce"),0.8,true)
 canvas.draw_line(Vector2(26,4.5),Vector2(26,8.5),Color("14282d"),2.3,true)
 if shot_left>0:
  var fade=clampf(shot_left/0.16,0,1)
  halo(canvas,MUZZLE,Vector2(35,18),ICE,fade*0.72)
  canvas.draw_colored_polygon(PackedVector2Array([MUZZLE+Vector2(0,-2.7),MUZZLE+Vector2(10,0),MUZZLE+Vector2(0,2.7),MUZZLE+Vector2(2,0)]),Color(ICE,fade))
  canvas.draw_line(MUZZLE,MUZZLE+Vector2(8,0),Color(1,1,0.95,fade),1.8,true)
 canvas.draw_set_transform(Vector2.ZERO)
