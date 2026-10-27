extends SceneTree
# Native GUI actions plus deterministic presentation checks; no combat dependency.
var checks=0
var failures=0
class StubProfile extends RefCounted:
 var data={"settings":{"reduced_motion":false}}
class StubGame extends Node:
 var profile=StubProfile.new()
 var quality=1
 var rng=RandomNumberGenerator.new()
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error("FAIL: "+message)
func click(at: Vector2) -> void:
 var event=InputEventMouseButton.new()
 event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;event.position=at
 root.push_input(event)
 event=event.duplicate();event.pressed=false;root.push_input(event)
func run() -> void:
 root.size=Vector2i(540,960)
 var game=StubGame.new();root.add_child(game);game.rng.seed=8173
 var original_rng=game.rng.state
 var page=Control.new();page.size=Vector2(540,960);root.add_child(page)
 var button=Button.new();button.text="STARTEN";button.position=Vector2(20,30);button.size=Vector2(240,64)
 var style=StyleBoxFlat.new();style.bg_color=Color("132739");style.border_color=Color.CYAN;style.set_border_width_all(2)
 style.set_corner_radius_all(24)
 style.content_margin_left=12;style.content_margin_right=12
 button.add_theme_stylebox_override("normal",style)
 page.add_child(button)
 var pressed_count=[0]
 button.pressed.connect(func():pressed_count[0]+=1)
 var original_rect=button.get_rect();var original_minimum=button.get_minimum_size()
 var surface: Variant=InterfaceMotion.bind_button(button,true,game)
 await process_frame;await process_frame
 surface.set_process(false)
 check(button.get_rect()==original_rect,"rounded styling preserves the native button rectangle")
 check(button.get_minimum_size()==original_minimum,"styling preserves native minimum content size")
 check(surface.mouse_filter==Control.MOUSE_FILTER_IGNORE and surface.show_behind_parent,"surface stays behind text and never intercepts touches")
 check(button.get_theme_stylebox("normal") is StyleBoxEmpty,"native button text draws over the transparent style")
 check(InterfaceMotion.bind_button(button,true,game)==surface and button.get_child_count()==1,"binding is idempotent without duplicate animation nodes")
 if DisplayServer.get_name()!="headless":
  await RenderingServer.frame_post_draw
  var image=root.get_texture().get_image()
  var fill=image.get_pixel(45,60)
  var corner=image.get_pixel(21,31);var outside=image.get_pixel(18,28)
  check(fill.r>0.7 and fill.r>fill.g+0.1,"real shader produces a warm coral button surface")
  check(absf(corner.r-outside.r)+absf(corner.g-outside.g)+absf(corner.b-outside.b)<0.08,"real rounded corner reveals the background instead of a square")
  var text_pixels=0
  for y in range(47,79):
   for x in range(90,190):
    var pixel=image.get_pixel(x,y)
    if pixel.r<0.25 and pixel.g<0.2 and pixel.b<0.3:text_pixels+=1
  check(text_pixels>50,"native button text remains visibly above the animated shader")
  image.save_png("/tmp/deadwave-interface-motion-proof.png")
  button.modulate.a=0.0
  await process_frame;await RenderingServer.frame_post_draw
  var hidden_image=root.get_texture().get_image()
  var hidden_fill=hidden_image.get_pixel(45,60)
  check(absf(hidden_fill.r-outside.r)+absf(hidden_fill.g-outside.g)+absf(hidden_fill.b-outside.b)<0.08,"parent alpha zero hides the real shader surface together with native text")
  button.modulate.a=0.5
  await process_frame;await RenderingServer.frame_post_draw
  var faded_image=root.get_texture().get_image()
  var faded_fill=faded_image.get_pixel(45,60)
  check(faded_fill.r>outside.r+0.08 and faded_fill.r<fill.r-0.08,"parent half alpha visibly fades the real shader surface")
  button.modulate.a=1.0
 click(Vector2(100,60));await process_frame
 check(pressed_count[0]==1,"native viewport click reaches the original button through its animated surface")
 button.button_down.emit()
 for i in range(8):surface._process(1.0/60.0)
 check(surface.visual_scale<0.99 and surface.visual_scale>=0.965,"press spring visibly compresses only the drawn surface")
 check(button.get_rect()==original_rect and button.scale==Vector2.ONE,"press spring cannot move or shrink the touch target")
 button.button_up.emit()
 for i in range(50):surface._process(1.0/60.0)
 check(absf(surface.visual_scale-1)<0.001,"release spring returns smoothly to its original size")
 check(surface.ripples.is_empty(),"expired press ripples are removed")
 for i in range(12):surface.begin_press()
 check(surface.ripples.size()==3,"high quality caps simultaneous ripples at three")
 game.quality=0
 for i in range(12):surface.begin_press()
 check(surface.ripples.size()==2,"low quality caps simultaneous ripples at two")
 button.disabled=true;surface._process(0.1)
 check(surface.ripples.is_empty() and not surface.pressed,"disabled buttons immediately clear press effects")
 click(Vector2(100,60));await process_frame
 check(pressed_count[0]==1,"disabled native button remains noninteractive")
 button.disabled=false
 game.profile.data["settings"]["reduced_motion"]=true
 surface.begin_press();surface._process(0.1)
 check(surface.ripples.is_empty() and surface.visual_scale==1.0,"reduced motion disables spring, ripple and light sweep")
 check(surface.effect.get_shader_parameter("sheen_phase")==-1.0,"reduced motion removes continuous shine")
 check(game.rng.state==original_rng,"all interface motion preserves gameplay random state")
 var label=Label.new();label.text="DEADWAVE";label.position=Vector2(20,120);page.add_child(label)
 var before_label=label.position
 InterfaceMotion.reveal(page,0,false)
 check(button.modulate.a==0 and label.modulate.a==0,"page entrance begins with a short fade")
 check(not button.disabled and button.mouse_filter==Control.MOUSE_FILTER_STOP,"entrance does not disable or delay input")
 click(Vector2(100,60));await process_frame
 check(pressed_count[0]==2,"native button accepts input during its entrance")
 for i in range(28):await process_frame
 check(button.modulate.a>0.99 and label.modulate.a>0.99,"staggered entrance completes within a short bounded interval")
 check(button.get_rect()==original_rect and label.position==before_label,"entrance never moves hit targets or text layout")
 InterfaceMotion.reveal(page,0,false)
 InterfaceMotion.cancel(page)
 check(button.modulate.a==1 and label.modulate.a==1 and not button.has_meta(InterfaceMotion.ENTRANCE_META),"navigation cancellation restores visibility and removes tween handles")
 for i in range(12):await process_frame
 check(button.modulate.a==1 and label.modulate.a==1,"cancelled old phase cannot fade a new phase")
 for i in range(20):
  InterfaceMotion.reveal(page,0,false)
  await process_frame
 check(get_processed_tweens().size()<=2,"rapid page replacement does not accumulate entrance tweens")
 InterfaceMotion.reveal(page,0,true)
 check(button.modulate.a==1 and label.modulate.a==1,"reduced-motion entrance is immediately readable")
 var surface_weak=weakref(surface)
 InterfaceMotion.cancel(page);page.queue_free();await process_frame;await process_frame
 check(not is_instance_valid(surface_weak.get_ref()),"freed page removes its animation surface with no orphan")
 game.queue_free();await process_frame
 print("INTERFACE MOTION RESULT: %d checks, %d failures"%[checks,failures])
 quit(0 if failures==0 else 1)
