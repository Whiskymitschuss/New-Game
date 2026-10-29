class_name ArsenalView
extends RefCounted
var g: Node2D
var selected := 0
const STEEL=Color("102025")
const GLASS=Color("08161c")
const FROST=Color("a7e3e6")
const WARNING=Color("d8ad72")
const ROLES=["Präziser Allrounder","Starker Einzelschuss","Schnelle Salven","Flexible Feuerkraft","Kurze Distanz · Streuung","Dauerfeuer","Reichweite · Durchschlag","Nahbereich · Brand","Explosion · Gruppen","Schwere Explosion","Laser · Durchschlag","Plasma · Flächenschaden"]
func _init(game: Node2D) -> void:g=game
func note(text: String,at: Vector2,size: int,color: Color,width: float,height: float=20) -> Label:
 var item=g.label(text,at,size,color,width,true)
 item.size=Vector2(width,height)
 return item
func icon(path: String,rect: Rect2,tint: Color=Color.WHITE) -> void:
 var item=TextureRect.new()
 item.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 item.texture=load(path)
 item.position=rect.position;item.size=rect.size
 item.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 item.modulate=tint
 item.mouse_filter=Control.MOUSE_FILTER_IGNORE
 g.controls.add_child(item)
func rail(rect: Rect2,color: Color) -> void:
 var line=ColorRect.new()
 line.position=rect.position;line.size=rect.size;line.color=color
 line.mouse_filter=Control.MOUSE_FILTER_IGNORE
 g.controls.add_child(line)
func detail_surface(rect: Rect2) -> void:
 var panel=Panel.new()
 panel.position=rect.position;panel.size=rect.size
 panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var box=StyleBoxFlat.new()
 box.bg_color=Color(GLASS,0.9)
 box.border_color=Color(FROST,0.16)
 box.set_border_width_all(1);box.set_corner_radius_all(9)
 box.shadow_color=Color(0,0,0,0.4);box.shadow_size=6
 panel.add_theme_stylebox_override("panel",box)
 g.controls.add_child(panel)
 rail(Rect2(rect.position+Vector2(0,18),Vector2(2,rect.size.y-36)),Color(FROST,0.7))
func build(id: int) -> void:
 selected=clampi(id,0,11)
 if Progression.available(g.profile.data,selected) and selected in Progression.pending_unlocks(g.profile.data):
  Progression.mark_seen(g.profile.data,selected);g.profile.save_game()
 g.mode="armory"
 g.page_header("DEIN ARSENAL","HELD LV %d    /    EINSATZ %02d    /    %s CR"%[g.profile.data["level"],g.profile.data["unlocked"],g.compact(g.profile.data["coins"])])
 for i in range(3):
  var x=30+i*164
  var chosen=int(g.profile.data["class"])==i
  var card=g.button("",Rect2(x,167,152,145),func(): g.profile.data["class"]=i;g.profile.save_game();g.show_armory(selected))
  skin(card,FROST if chosen else FutureArt.BLUE,chosen)
  rail(Rect2(x+15,304,122,2),Color(FROST,0.8) if chosen else Color(FROST,0.08))
  var portrait=TextureRect.new()
  portrait.set_meta("hero_portrait",true)
  portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  var atlas=AtlasTexture.new();atlas.atlas=g.future.heroes
  atlas.region=g.future.frame_region("heroes",i,g.future.heroes,3,1)
  portrait.texture=atlas;portrait.position=Vector2(x+33,172);portrait.size=Vector2(86,86)
  portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
  g.controls.add_child(portrait)
  if chosen and not bool(g.profile.data["settings"].get("reduced_motion",false)):
   var breath=portrait.create_tween().set_loops()
   breath.tween_property(portrait,"position:y",170.5,1.3).set_trans(Tween.TRANS_SINE)
   breath.tween_property(portrait,"position:y",172.0,1.3).set_trans(Tween.TRANS_SINE)
  var title=note(Content.CLASSES[i]["name"],Vector2(x+7,261),14,g.INK,138)
  title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
  var state=note("AKTIV" if chosen else ["SCHADEN +25%","DROHNEN-SUPPORT","REGENERATION"][i],Vector2(x+7,286),9,FutureArt.MINT if chosen else g.MUTED,138)
  state.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
 note("WAFFENSAMMLUNG   %02d / 12"%Progression.unlocked_ids(g.profile.data).size(),Vector2(31,329),11,g.CYAN,320)
 var attr=g.button("WERTE →",Rect2(379,324,131,33),g.show_character)
 attr.add_theme_font_size_override("font_size",12)
 for i in range(12):
  var x=30+(i%3)*164;var y=369+(i/3)*74
  var open=Progression.available(g.profile.data,i)
  var equipped=int(g.profile.data["weapon"])==i
  var entry=g.button("",Rect2(x,y,152,67),func(): g.show_armory(i))
  entry.set_meta("weapon_id",i)
  skin(entry,FROST if open else WARNING,i==selected)
  rail(Rect2(x+3,y+10,2,47),Color(FutureArt.MINT,0.9) if equipped else (Color(FROST,0.8) if i==selected and open else Color(WARNING,0.5) if i==selected else Color(FROST,0.05)))
  icon("res://assets/ui/weapons/%d.svg"%i,Rect2(x+9,y+4,66,29),Color.WHITE if open else Color(0.48,0.56,0.68))
  if not open:icon("res://assets/ui/weapons/lock.svg",Rect2(x+124,y+6,18,18),Color(WARNING,0.8))
  else:note("AKTIV" if equipped else ("NEU" if i in Progression.pending_unlocks(g.profile.data) else "+%d"%Progression.effective_rank(g.profile.data,i)),Vector2(x+94,y+10),9,FutureArt.MINT if equipped else g.CYAN,53)
  var name_size=12 if g.font.get_string_size(Content.WEAPONS[i][0],HORIZONTAL_ALIGNMENT_LEFT,-1,12).x<=135 else 10
  var name_label=note(Content.WEAPONS[i][0],Vector2(x+9,y+35),name_size,g.INK if open else g.MUTED,135,28)
  name_label.set_meta("weapon_name",true)
 detail_surface(Rect2(30,674,480,127))
 var w=Content.WEAPONS[selected]
 var available=Progression.available(g.profile.data,selected)
 var rank=Progression.effective_rank(g.profile.data,selected)
 note(w[0].to_upper(),Vector2(42,681),19,g.INK,335,26)
 note("RANG %d / %d"%[rank,Progression.MAX_RANK] if available else "GESPERRT",Vector2(378,684),10,g.CYAN if available else WARNING,130)
 note(ROLES[selected],Vector2(43,709),11,g.MUTED,458)
 if available:
  var damage=float(w[1])*float(Content.CLASSES[int(g.profile.data["class"])]["damage"])*(1+rank*.1)*(1+0.05*Workshop.rank(g.profile.data,"weapon"))
  note("%.1f SCHADEN  ·  %.1f SCHUSS/S  ·  %.1fs LADEN"%[damage,g.COMBAT_PACE/float(w[2]),float(w[3])/g.COMBAT_PACE],Vector2(43,735),11,g.CYAN,458)
  note("%d IM MAGAZIN  ·  1 MUNITION PRO SCHUSS"%int(w[4]),Vector2(43,758),10,g.MUTED,458)
 else:
  note(Progression.requirement_text(selected),Vector2(43,736),15,WARNING,458,29)
  note("BASIS %.0f SCHADEN  ·  %.1f SCHUSS/S"%[float(w[1]),1.0/float(w[2])],Vector2(43,771),11,g.MUTED,458)
 var equipped=int(g.profile.data["weapon"])==selected
 var equip=g.button("AUSGERÜSTET" if equipped else ("AUSRÜSTEN" if available else "NOCH GESPERRT"),Rect2(30,814,232,49),func():
  if Progression.equip(g.profile.data,selected):g.profile.save_game();g.show_armory(selected),true)
 equip.disabled=not available or equipped
 equip.set_meta("equip_weapon",selected)
 var price=Progression.upgrade_cost(g.profile.data,selected)
 var buy=g.button("UPGRADE GESPERRT" if not available else ("MAXIMALRANG" if rank>=Progression.MAX_RANK else "+10%% · %s CR"%g.compact(price)),Rect2(278,814,232,49),func():
  if Progression.upgrade_weapon(g.profile.data,selected):
   g.profile.save_game();g.audio.play_effect("upgrade");g.show_armory(selected))
 buy.disabled=not available or rank>=Progression.MAX_RANK or int(g.profile.data["coins"])<price
 buy.set_meta("upgrade_weapon",selected)
 if available and rank<Progression.MAX_RANK and int(g.profile.data["coins"])<price:
  note("NOCH %s CR"%g.compact(price-int(g.profile.data["coins"])),Vector2(338,864),9,g.MUTED,172)
func skin(button: Button,color: Color,selected: bool) -> void:
 var box=StyleBoxFlat.new()
 box.bg_color=Color("162d32") if selected else STEEL
 box.border_color=Color(color,0.7 if selected else 0.16)
 box.set_border_width_all(1)
 box.set_corner_radius_all(9)
 box.shadow_color=Color(0,0,0,0.45);box.shadow_size=5
 box.shadow_offset=Vector2(0,3)
 button.add_theme_stylebox_override("normal",box)
 var hover=box.duplicate();hover.bg_color=Color("1b363b");hover.border_color=Color(color,0.85)
 button.add_theme_stylebox_override("hover",hover)
 button.add_theme_stylebox_override("pressed",hover)
