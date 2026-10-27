class_name ArsenalView
extends RefCounted
var g: Node2D
var selected := 0
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
  skin(card,FutureArt.MINT if chosen else FutureArt.BLUE,chosen)
  var portrait=TextureRect.new()
  portrait.set_meta("hero_portrait",true)
  portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
  var atlas=AtlasTexture.new();atlas.atlas=g.future.heroes
  atlas.region=g.future.frame_region("heroes",i,g.future.heroes,3,1)
  portrait.texture=atlas;portrait.position=Vector2(x+33,172);portrait.size=Vector2(86,86)
  portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  portrait.mouse_filter=Control.MOUSE_FILTER_IGNORE
  g.controls.add_child(portrait)
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
  skin(entry,FutureArt.MINT if equipped else (FutureArt.BLUE if open else FutureArt.QUIET),i==selected)
  icon("res://assets/ui/weapons/%d.svg"%i,Rect2(x+9,y+4,66,29),Color.WHITE if open else Color(0.48,0.56,0.68))
  if not open:icon("res://assets/ui/weapons/lock.svg",Rect2(x+124,y+6,18,18),FutureArt.QUIET)
  else:note("AKTIV" if equipped else ("NEU" if i in Progression.pending_unlocks(g.profile.data) else "+%d"%Progression.effective_rank(g.profile.data,i)),Vector2(x+94,y+10),9,FutureArt.MINT if equipped else g.CYAN,53)
  var name_size=12 if g.font.get_string_size(Content.WEAPONS[i][0],HORIZONTAL_ALIGNMENT_LEFT,-1,12).x<=135 else 10
  var name_label=note(Content.WEAPONS[i][0],Vector2(x+9,y+35),name_size,g.INK if open else g.MUTED,135,28)
  name_label.set_meta("weapon_name",true)
 var w=Content.WEAPONS[selected]
 var available=Progression.available(g.profile.data,selected)
 var rank=Progression.effective_rank(g.profile.data,selected)
 note(w[0].to_upper(),Vector2(34,681),19,g.INK,335,26)
 note("RANG %d / %d"%[rank,Progression.MAX_RANK] if available else "GESPERRT",Vector2(378,684),10,g.CYAN if available else FutureArt.AMBER,130)
 note(ROLES[selected],Vector2(35,709),11,g.MUTED,460)
 if available:
  var damage=float(w[1])*float(Content.CLASSES[int(g.profile.data["class"])]["damage"])*(1+rank*.1)
  note("%.1f SCHADEN  ·  %.1f SCHUSS/S  ·  %.1fs LADEN"%[damage,1.0/float(w[2]),w[3]],Vector2(35,735),11,g.CYAN,470)
  note("%d IM MAGAZIN  ·  1 MUNITION PRO SCHUSS"%int(w[4]),Vector2(35,758),10,g.MUTED,470)
 else:
  note(Progression.requirement_text(selected),Vector2(35,736),15,FutureArt.AMBER,470,29)
  note("BASIS %.0f SCHADEN  ·  %.1f SCHUSS/S"%[float(w[1]),1.0/float(w[2])],Vector2(35,771),11,g.MUTED,460)
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
 box.bg_color=Color("172f40") if selected else Color("101b2d")
 box.border_color=Color(color,0.9 if selected else 0.23)
 box.set_border_width_all(2 if selected else 1)
 box.set_corner_radius_all(9)
 box.shadow_color=Color(color,0.08 if selected else 0.0);box.shadow_size=5
 button.add_theme_stylebox_override("normal",box)
 var hover=box.duplicate();hover.bg_color=Color("23394c");hover.border_color=color
 button.add_theme_stylebox_override("hover",hover)
 button.add_theme_stylebox_override("pressed",hover)
