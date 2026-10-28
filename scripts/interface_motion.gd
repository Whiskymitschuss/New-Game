class_name InterfaceMotion
extends RefCounted
# Presentation only: the native Button keeps its original rect, scale and input.
# A recessed console surface behind its text provides spring, ripple and a quiet scan sweep.
const PRIMARY := Color("90d6cf")
const IVORY := Color("e3e4d4")
const COOL := Color("76bdb7")
const ENTRANCE_META := "interface_motion_entrance"
const SURFACE_META := "interface_motion_surface"
static var cached_shader: Shader

const SURFACE_SHADER := """shader_type canvas_item;
render_mode unshaded;
uniform vec2 box_size = vec2(240.0, 60.0);
uniform float corner_radius = 9.0;
uniform float visual_scale = 1.0;
uniform vec4 fill_color : source_color = vec4(0.055, 0.09, 0.10, 1.0);
uniform vec4 edge_color : source_color = vec4(0.46, 0.74, 0.72, 0.35);
uniform vec4 glow_color : source_color = vec4(0.56, 0.84, 0.81, 1.0);
uniform float enabled_amount = 1.0;
uniform float primary_amount = 0.0;
uniform float glow_amount = 0.0;
uniform float focus_amount = 0.0;
uniform float sheen_phase = -1.0;
uniform vec4 ripple0 = vec4(0.0);
uniform vec4 ripple1 = vec4(0.0);
uniform vec4 ripple2 = vec4(0.0);

float ring(vec2 p, vec4 ripple) {
 float radius = ripple.z * length(box_size) * 0.8;
 float band = 1.0 - smoothstep(0.0, 8.0, abs(length(p - ripple.xy) - radius));
 return band * (1.0 - ripple.z) * ripple.w;
}
void fragment() {
 vec4 inherited_color = COLOR;
 vec2 local = (UV - vec2(0.5)) * box_size / max(visual_scale, 0.9);
 vec2 half_size = box_size * 0.5;
 float r = min(corner_radius, min(half_size.x, half_size.y));
 vec2 q = abs(local) - half_size + vec2(r);
 float distance_to_edge = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
 float aa = max(fwidth(distance_to_edge), 0.6);
 float mask = 1.0 - smoothstep(-aa, aa, distance_to_edge);
 float edge = 1.0 - smoothstep(0.2, 1.8 + focus_amount, abs(distance_to_edge + 1.0));
 vec3 base = fill_color.rgb;
 base += vec3(0.025, 0.033, 0.030) * pow(1.0 - UV.y, 3.0);
 float sheen = 1.0 - smoothstep(0.0, 0.09, abs(UV.x * 0.82 + UV.y * 0.18 - sheen_phase));
 base += glow_color.rgb * sheen * glow_amount * 0.045;
 vec2 pixel = local + half_size;
 float ripple = ring(pixel, ripple0) + ring(pixel, ripple1) + ring(pixel, ripple2);
 base += glow_color.rgb * min(ripple, 1.3) * 0.17;
 // Fine fixed raster lines stay local to the panel; no screen flicker or jitter.
 float raster = step(0.82, fract(pixel.y * 0.25));
 base -= vec3(raster * (0.012 + primary_amount * 0.008));
 base = mix(base, edge_color.rgb, edge * edge_color.a);
 // Restrained hardware marks: a powered left rail, upper-right contact and footer tick.
 float rail = (1.0 - smoothstep(0.55, 1.6, abs(pixel.x - 4.5)))
  * step(11.0, pixel.y) * step(pixel.y, box_size.y - 11.0);
 float contact = (1.0 - smoothstep(0.4, 1.2, abs(pixel.y - 5.0)))
  * step(box_size.x - 25.0, pixel.x) * step(pixel.x, box_size.x - 11.0);
 float footer = (1.0 - smoothstep(0.4, 1.2, abs(pixel.y - box_size.y + 5.0)))
  * step(13.0, pixel.x) * step(pixel.x, 22.0);
 float hardware = max(rail * 0.80, max(contact, footer) * 0.38) * enabled_amount;
 vec3 powered_color = mix(glow_color.rgb, vec3(0.12, 0.31, 0.30), primary_amount * 0.72);
 base = mix(base, powered_color, hardware);
 COLOR = vec4(base, fill_color.a * mask) * inherited_color;
}
"""

static func reduced(game: Node) -> bool:
 if not is_instance_valid(game):return false
 var profile=game.get("profile")
 if profile==null:return false
 var data=profile.get("data")
 if not data is Dictionary:return false
 var settings=data.get("settings",{})
 return settings is Dictionary and bool(settings.get("reduced_motion",false))

static func shared_shader() -> Shader:
 if cached_shader==null:
  cached_shader=Shader.new()
  cached_shader.code=SURFACE_SHADER
 return cached_shader

static func bind_button(button: Button,accent: bool=false,game: Node=null) -> Control:
 if button.has_meta(SURFACE_META):
  var previous=button.get_meta(SURFACE_META)
  if previous is WeakRef and is_instance_valid(previous.get_ref()):return previous.get_ref()
 var surface=ButtonSurface.new()
 surface.accent=accent
 surface.game=game
 surface.name="ConsoleMotionSurface"
 surface.mouse_filter=Control.MOUSE_FILTER_IGNORE
 surface.focus_mode=Control.FOCUS_NONE
 surface.show_behind_parent=true
 button.add_child(surface)
 button.set_meta(SURFACE_META,weakref(surface))
 return surface

static func nodes_from(value: Variant) -> Array:
 if value is Array:return value
 if value is Node:return value.get_children()
 return []

static func cancel(value: Variant) -> void:
 for item in nodes_from(value):
  if not is_instance_valid(item) or not item is Control:continue
  if item.has_meta(ENTRANCE_META):
   var tween=item.get_meta(ENTRANCE_META)
   if tween is Tween and tween.is_valid():tween.kill()
   item.remove_meta(ENTRANCE_META)
  item.modulate.a=1.0

static func reveal(value: Variant,top: float=0.0,reduced_motion: bool=false) -> void:
 var nodes=nodes_from(value)
 cancel(nodes)
 if reduced_motion:return
 var rank=0
 for item in nodes:
  if not is_instance_valid(item) or not item is Control or item.position.y<top:continue
  # Stagger by horizontal grouping, so all labels on one card arrive together.
  var delay=minf(0.10,rank*0.014)
  item.modulate.a=0.0
  var tween=item.create_tween()
  tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
  tween.tween_property(item,"modulate:a",1.0,0.24).set_delay(delay)
  item.set_meta(ENTRANCE_META,tween)
  rank+=1

class ButtonSurface extends Control:
 var accent=false
 var game: Node
 var button: Button
 var effect: ShaderMaterial
 var ripples: Array = []
 var visual_scale=1.0
 var spring_velocity=0.0
 var hover_blend=0.0
 var pressed=false
 var hovered=false
 var elapsed=0.0
 var highlight=Color("76bdb7")
 var selected=false
 var ready_style=false

 func _ready() -> void:
  button=get_parent() as Button
  if button==null:queue_free();return
  effect=ShaderMaterial.new();effect.shader=InterfaceMotion.shared_shader()
  material=effect
  button.resized.connect(sync_size)
  button.mouse_entered.connect(func():hovered=true)
  button.mouse_exited.connect(func():hovered=false)
  button.button_down.connect(begin_press)
  button.button_up.connect(func():pressed=false)
  button.gui_input.connect(pointer_input)
  sync_size()
  # The caller can apply a card/selection style after creating its Button.
  refresh_style.call_deferred()

 func sync_size() -> void:
  if not is_instance_valid(button):return
  position=Vector2.ZERO
  size=button.size
  if effect:
   effect.set_shader_parameter("box_size",size.max(Vector2.ONE))
   effect.set_shader_parameter("corner_radius",minf(10.0,size.y*0.2))

 func refresh_style() -> void:
  if not is_instance_valid(button) or not is_inside_tree():return
  var source=button.get_theme_stylebox("normal")
  if source is StyleBoxFlat:
   var stroke: Color=source.border_color
   selected=source.border_width_left>=2 or stroke.a>=0.55
   if selected:highlight=stroke
  if accent:highlight=InterfaceMotion.PRIMARY
  var transparent=StyleBoxEmpty.new()
  transparent.content_margin_left=maxf(0,source.get_margin(SIDE_LEFT))
  transparent.content_margin_right=maxf(0,source.get_margin(SIDE_RIGHT))
  transparent.content_margin_top=maxf(0,source.get_margin(SIDE_TOP))
  transparent.content_margin_bottom=maxf(0,source.get_margin(SIDE_BOTTOM))
  for state in ["normal","hover","pressed","hover_pressed","disabled","focus"]:
   button.add_theme_stylebox_override(state,transparent)
  button.add_theme_color_override("font_color",Color("071d20") if accent else InterfaceMotion.IVORY)
  button.add_theme_color_override("font_hover_color",Color("071d20") if accent else InterfaceMotion.IVORY)
  button.add_theme_color_override("font_pressed_color",Color("071d20") if accent else InterfaceMotion.IVORY)
  button.add_theme_color_override("font_focus_color",Color("071d20") if accent else InterfaceMotion.IVORY)
  button.add_theme_color_override("font_disabled_color",Color("778782"))
  ready_style=true
  update_uniforms()
  queue_redraw()

 func begin_press() -> void:
  if not is_instance_valid(button) or button.disabled:return
  pressed=true
  if InterfaceMotion.reduced(game):return
  var cap=3
  if is_instance_valid(game) and game.get("quality")==0:cap=2
  while ripples.size()>=cap:ripples.pop_front()
  ripples.append({"point":size*0.5,"age":0.0})

 func pointer_input(event: InputEvent) -> void:
  if ripples.is_empty():return
  if event is InputEventMouseButton and event.pressed:
   ripples[-1]["point"]=event.position.clamp(Vector2.ZERO,size)
  elif event is InputEventScreenTouch and event.pressed:
   ripples[-1]["point"]=event.position.clamp(Vector2.ZERO,size)

 func _process(delta: float) -> void:
  if not is_instance_valid(button) or not ready_style:return
  var less=InterfaceMotion.reduced(game)
  if button.disabled:
   pressed=false
   ripples.clear()
  if less:
   visual_scale=1.0;spring_velocity=0.0
   hover_blend=1.0 if hovered and not button.disabled else 0.0
   ripples.clear()
  else:
   elapsed+=delta
   var step=minf(delta,0.033)
   var target=0.972 if pressed else 1.0
   spring_velocity+=((target-visual_scale)*360.0-spring_velocity*28.0)*step
   visual_scale=clampf(visual_scale+spring_velocity*step,0.965,1.012)
   hover_blend=move_toward(hover_blend,1.0 if hovered and not button.disabled else 0.0,delta*9)
   for i in range(ripples.size()-1,-1,-1):
    ripples[i]["age"]+=delta
    if ripples[i]["age"]>=0.52:ripples.remove_at(i)
  update_uniforms()
  queue_redraw()

 func update_uniforms() -> void:
  if not effect or not is_instance_valid(button):return
  var disabled=button.disabled
  var fill=InterfaceMotion.PRIMARY if accent else Color("111d20")
  if not accent and selected:fill=Color("183638")
  fill=fill.lerp(Color("b5e6dd") if accent else Color("233d3e"),hover_blend*0.7)
  if disabled:fill=Color("0e1518")
  var edge=highlight
  edge.a=0.10 if disabled else (0.75 if selected else 0.33+hover_blend*0.2)
  if button.has_focus():edge=Color(InterfaceMotion.IVORY,0.86)
  effect.set_shader_parameter("enabled_amount",0.0 if disabled else 1.0)
  effect.set_shader_parameter("primary_amount",1.0 if accent else 0.0)
  effect.set_shader_parameter("fill_color",fill)
  effect.set_shader_parameter("edge_color",edge)
  effect.set_shader_parameter("glow_color",InterfaceMotion.COOL if accent else highlight)
  effect.set_shader_parameter("glow_amount",0.0 if disabled else (1.0 if accent else hover_blend))
  effect.set_shader_parameter("focus_amount",1.0 if button.has_focus() else 0.0)
  effect.set_shader_parameter("visual_scale",visual_scale)
  effect.set_shader_parameter("sheen_phase",-1.0 if InterfaceMotion.reduced(game) or disabled else fmod(elapsed*0.18,1.8)-0.4)
  for i in range(3):
   var value=Vector4.ZERO
   if i<ripples.size():
    var ripple=ripples[i]
    value=Vector4(ripple["point"].x,ripple["point"].y,minf(1,ripple["age"]/0.52),1)
   effect.set_shader_parameter("ripple%d"%i,value)

 func _draw() -> void:
  if ready_style:draw_rect(Rect2(Vector2.ZERO,size),Color.WHITE)

 func _exit_tree() -> void:
  ripples.clear()
