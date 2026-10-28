class_name AmmoBall
extends RigidBody2D
var weight: int = 1
var ammo_kind := "normal"
var gates: int = 0
var age: float = 0.0
var previous := Vector2.ZERO
var live := false
var portal_used := false
var glow := 0.0
var impact_cooldown := 0.0
var reset_pending := false
var reset_at := Vector2.ZERO
var reset_velocity := Vector2.ZERO

func set_physics_pose(at: Vector2,velocity: Vector2) -> void:
 reset_at=at
 reset_velocity=velocity
 reset_pending=true
 # Node2D.position alone can be replaced by the previous server snapshot on reuse.
 var pose=Transform2D(0,at)
 transform=pose
 PhysicsServer2D.body_set_state(get_rid(),PhysicsServer2D.BODY_STATE_TRANSFORM,pose)
 PhysicsServer2D.body_set_state(get_rid(),PhysicsServer2D.BODY_STATE_LINEAR_VELOCITY,velocity)
 PhysicsServer2D.body_set_state(get_rid(),PhysicsServer2D.BODY_STATE_ANGULAR_VELOCITY,0.0)
 reset_physics_interpolation()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
 if reset_pending:
  state.transform=Transform2D(0,reset_at)
  state.linear_velocity=reset_velocity
  state.angular_velocity=0
  state.sleeping=false
  reset_pending=false

func teleport_to(at: Vector2,velocity: Vector2) -> void:
 previous=at
 set_physics_pose(at,velocity)

func _ready() -> void:
 var shape := CircleShape2D.new()
 shape.radius=6
 var collider := CollisionShape2D.new()
 collider.shape=shape
 add_child(collider)
 collision_layer=2
 collision_mask=1
 gravity_scale=0.42
 var material := PhysicsMaterial.new()
 material.bounce=0.65
 material.friction=0.18
 physics_material_override=material
 continuous_cd=RigidBody2D.CCD_MODE_CAST_SHAPE
 contact_monitor=true
 max_contacts_reported=2
 deactivate()

func activate(at: Vector2,velocity: Vector2,amount: int=1,mask: int=0) -> void:
 previous=at
 weight=amount
 ammo_kind="normal"
 gates=mask
 age=0
 glow=0.0
 impact_cooldown=0.0
 portal_used=false
 live=true
 visible=true
 freeze=false
 sleeping=false
 set_physics_pose(at,velocity)
 angular_velocity=0
 collision_layer=2
 collision_mask=1
 queue_redraw()

func deactivate() -> void:
 live=false
 reset_pending=false
 visible=false
 freeze=true
 collision_layer=0
 collision_mask=0
 linear_velocity=Vector2.ZERO
 position=Vector2(-200,-200)
