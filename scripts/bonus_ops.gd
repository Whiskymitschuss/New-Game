class_name BonusOps
extends Node
# Voluntary, bounded side objectives. Uses its own random stream and real time.
const ARROWS=["→","↓","←","↑"]
var game: Node2D
var state="idle"
var wave_seen=0
var offered=0
var next_in=7.0
var remaining=0.0
var serial=0
var kind="swipe"
var sequence: Array[int]=[]
var progress=0
var feedback=""
var ui: Control
var heading: Label
var prompt: Label
var drag_origin=Vector2.ZERO
var dragging=false
var random=RandomNumberGenerator.new()
func reset() -> void:
 state="idle";wave_seen=0;offered=0;next_in=7;remaining=0;serial=0;progress=0;dragging=false
 sequence.clear()
func mount() -> void:
 if is_instance_valid(ui) and not ui.is_queued_for_deletion():ui.queue_free()
 ui=null
 if state=="idle":return
 ui=Control.new();ui.mouse_filter=Control.MOUSE_FILTER_IGNORE
 game.controls.add_child(ui)
 if state=="offer":
  var entry=make_button("BONUS: "+("WISCH-KOMBO" if kind=="swipe" else "ZAHLENCODE"),Rect2(300,178,216,46),open)
  entry.tooltip_text="Freiwillig. Der Kampf läuft weiter. Keine Strafe beim Auslassen."
  return
 var panel=Panel.new();panel.position=Vector2(194,177);panel.size=Vector2(322,164)
 var skin=StyleBoxFlat.new();skin.bg_color=Color(0.03,0.10,0.12,0.84);skin.border_color=Color("78cfc6");skin.set_border_width_all(1);skin.set_corner_radius_all(12)
 panel.add_theme_stylebox_override("panel",skin);ui.add_child(panel)
 heading=make_label("",Vector2(208,188),12,262)
 prompt=make_label("",Vector2(208,218),17,290)
 var close=make_button("×",Rect2(471,179,44,44),dismiss);close.add_theme_font_size_override("font_size",20)
 if state=="result":
  heading.text="BONUS-EINSATZ";prompt.text=feedback;return
 if kind=="code":
  for i in range(4):
   var digit=i+1
   make_button(str(digit),Rect2(208+i*74,269,66,58),func():submit(digit))
 else:
  var pad=Panel.new();pad.position=Vector2(208,259);pad.size=Vector2(292,68)
  var pad_skin=skin.duplicate();pad_skin.bg_color=Color("16383b");pad.add_theme_stylebox_override("panel",pad_skin)
  pad.gui_input.connect(swipe_input);ui.add_child(pad)
  var hint=make_label("HIER WISCHEN · TOUCH / MAUS",Vector2(219,281),11,275)
  hint.mouse_filter=Control.MOUSE_FILTER_IGNORE
 refresh()
func make_label(text: String,at: Vector2,size: int,width: int) -> Label:
 var item=Label.new();item.position=at;item.size=Vector2(width,28);item.text=text
 item.add_theme_font_override("font",game.font);item.add_theme_font_size_override("font_size",size)
 item.add_theme_color_override("font_color",Color("cde9df"));item.mouse_filter=Control.MOUSE_FILTER_IGNORE
 ui.add_child(item);return item
func make_button(text: String,rect: Rect2,action: Callable) -> Button:
 var button=game.button(text,rect,action)
 game.controls.remove_child(button);ui.add_child(button)
 button.add_theme_font_size_override("font_size",12);return button
func offer() -> void:
 if state!="idle" or offered>=2 or game.mode!="play":return
 serial+=1;offered+=1;kind="swipe" if serial%2==1 else "code"
 random.seed=73491+game.level*431+game.wave*71+serial*17
 sequence.clear();progress=0
 for i in range(3 if kind=="swipe" else 4):sequence.append(random.randi_range(0,3)+(1 if kind=="code" else 0))
 state="offer";remaining=10;mount()
func open() -> void:
 if game.mode!="play" or state!="offer":return
 state="active";remaining=7;progress=0;mount()
func dismiss() -> void:
 if game.mode!="play":return
 state="idle";next_in=12;dragging=false;mount()
func refresh() -> void:
 if state!="active" or not is_instance_valid(heading):return
 heading.text=("WISCHEN · +24 MUNITION" if kind=="swipe" else "CODE · +18 CREDITS")+" · %ds"%ceili(remaining)
 var parts=[]
 for i in range(sequence.size()):parts.append("✓" if i<progress else (ARROWS[sequence[i]] if kind=="swipe" else str(sequence[i])))
 prompt.text="  ".join(parts)
func swipe_input(event: InputEvent) -> void:
 if state!="active" or game.mode!="play":return
 if event is InputEventScreenTouch:
  if event.pressed:drag_origin=event.position;dragging=true
  elif dragging:dragging=false;swipe(event.position-drag_origin)
 elif event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
  if event.pressed:drag_origin=event.position;dragging=true
  elif dragging:dragging=false;swipe(event.position-drag_origin)
func swipe(offset: Vector2) -> void:
 if offset.length()<24:return
 var direction=(0 if offset.x>0 else 2) if absf(offset.x)>absf(offset.y) else (1 if offset.y>0 else 3)
 submit(direction)
func submit(value: int) -> void:
 if game.mode!="play" or state!="active" or remaining<=0:return
 if value!=sequence[progress]:progress=0;refresh();return
 progress+=1
 if progress<sequence.size():refresh();return
 # Close the transaction before changing resources, rejecting stale callbacks.
 state="result";remaining=2.2;dragging=false
 if kind=="swipe":
  var amount=mini(24,maxi(0,int(game.stats["capacity"])-game.ammo))
  game.ammo+=amount
  if amount>0:feedback="+%d MUNITION GESICHERT"%amount
  else:
   var energy=minf(12,100-game.energy);game.energy+=energy
   feedback="LAGER VOLL · +%d ENERGIE"%int(energy)
 else:
  var before=int(game.profile.data["coins"]);game.profile.data["coins"]=before+18
  if game.profile.save_game():
   feedback="+18 CREDITS GESPEICHERT";game.run_coins+=18
  else:game.profile.data["coins"]=before;feedback="SPEICHERN NICHT MÖGLICH"
 game.audio.play_effect("upgrade");mount()
func _process(delta: float) -> void:
 if not is_instance_valid(game) or game.mode!="play":return
 if wave_seen!=game.wave:
  wave_seen=game.wave;offered=0;state="idle";next_in=7;dragging=false;mount()
 if state=="idle":
  next_in-=delta
  if next_in<=0:offer()
 else:
  remaining=maxf(0,remaining-delta)
  if remaining<=0:dismiss()
  else:refresh()
