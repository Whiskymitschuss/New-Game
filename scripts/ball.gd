class_name AmmoBall
extends RigidBody2D
var weight: int = 1
var gates: int = 0
var age: float = 0.0
var previous := Vector2.ZERO
var live := false
var portal_used := false
var glow := 0.0

func _ready() -> void:
 var shape := CircleShape2D.new()
 shape.radius=5
 var collider := CollisionShape2D.new()
 collider.shape=shape
 add_child(collider)
 collision_layer=2
 collision_mask=1
 var material := PhysicsMaterial.new()
 material.bounce=0.65
 material.friction=0.18
 physics_material_override=material
 continuous_cd=RigidBody2D.CCD_MODE_CAST_SHAPE
 deactivate()

func activate(at: Vector2,velocity: Vector2,amount: int=1,mask: int=0) -> void:
 position=at
 previous=at
 weight=amount
 gates=mask
 age=0
 portal_used=false
 live=true
 visible=true
 freeze=false
 sleeping=false
 linear_velocity=velocity
 angular_velocity=0
 collision_layer=2
 collision_mask=1
 queue_redraw()

func deactivate() -> void:
 live=false
 visible=false
 freeze=true
 collision_layer=0
 collision_mask=0
 linear_velocity=Vector2.ZERO
 position=Vector2(-200,-200)

func _draw() -> void:
 draw_circle(Vector2(1,2),6,Color(0.01,0.03,0.05,0.5))
 draw_circle(Vector2.ZERO,5,Color("d5fc84") if weight>1 else Color("e9f5ff"))
 draw_circle(Vector2(-1.5,-1.5),1.8,Color.WHITE)
