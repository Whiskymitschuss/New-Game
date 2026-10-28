class_name ReactorSwitch
extends RefCounted
# The control moves one existing physical ramp. It never creates ammunition,
# changes a collision mask or advances the gameplay random stream.
const ANGLE := 0.4
const TURN_SECONDS := 0.18
var game: Node
var body: Node2D
var variant := 0
var direction := 1
var spent := false
var armed := false
var turning := false
var turn_elapsed := 0.0
var from_angle := ANGLE
var target_angle := ANGLE

func reset() -> void:
 body=null
 variant=0;direction=1;spent=false;armed=false;turning=false
 turn_elapsed=0;from_angle=ANGLE;target_angle=ANGLE

func attach_body(node: Node2D,shape_variant: int=0) -> void:
 reset()
 body=node;variant=clampi(shape_variant,0,2)
 if is_instance_valid(body):body.rotation=ANGLE

func begin_drop() -> void:
 # Only the caller accepting an actual drop may open a fresh control charge.
 armed=true;spent=false

func end_drop() -> void:
 armed=false

func can_toggle() -> bool:
 if not is_instance_valid(game) or not is_instance_valid(body):return false
 if not armed or spent or String(game.get("mode"))!="play" or not bool(game.get("drop_running")):return false
 var pending=game.get("pending_balls")
 return int(game.call("active_balls"))>0 or (pending is Array and not pending.is_empty())

func toggle() -> bool:
 if not can_toggle():return false
 spent=true;direction=-direction
 from_angle=body.rotation;target_angle=ANGLE*direction
 turn_elapsed=0;turning=true
 return true

func update(delta: float) -> void:
 if not is_instance_valid(body) or not turning:return
 if not is_instance_valid(game) or String(game.get("mode"))!="play":return
 turn_elapsed=minf(TURN_SECONDS,turn_elapsed+maxf(0,delta))
 var t=turn_elapsed/TURN_SECONDS
 # Smooth endpoints reduce the abrupt impulse of an instantaneous collider jump.
 var blend=t*t*(3.0-2.0*t)
 body.rotation=lerpf(from_angle,target_angle,blend)
 if turn_elapsed>=TURN_SECONDS:
  body.rotation=target_angle;turning=false

func caption() -> String:
 var arrow="←" if direction>0 else "→"
 if can_toggle():return "WEICHE %s\n1× PRO ABWURF"%arrow
 if spent:return "WEICHE %s\nGESTELLT"%("→" if direction>0 else "←")
 return "WEICHE\nBEIM ABWURF"
