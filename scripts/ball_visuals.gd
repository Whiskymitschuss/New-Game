class_name BallVisuals
extends Node2D
# Render the bounded physics pool in one explicit foreground canvas item.
# Visuals depend on live state and position, never pooled-body visibility/redraw state.
var balls: Array[AmmoBall] = []
var rendered_count := 0

func _ready() -> void:
 z_index=20

func _process(_delta: float) -> void:
 queue_redraw()

func _draw() -> void:
 rendered_count=0
 for ball in balls:
  if not ball.live:
   continue
  var at=ball.position
  var tint=Color("d5fc84") if ball.weight>1 else Color("f3fcff")
  var trail=ball.linear_velocity.limit_length(420)*0.035
  draw_line(at-trail,at,Color(tint,0.24),6,true)
  draw_circle(at,11,Color(tint,0.12))
  draw_circle(at+Vector2(1,2),8,Color(0.01,0.03,0.05,0.7))
  draw_circle(at,7.5,tint)
  draw_arc(at,7.5,0,TAU,20,Color("5a8692"),1,true)
  draw_circle(at-Vector2(2,2.5),2.4,Color.WHITE)
  rendered_count+=1
