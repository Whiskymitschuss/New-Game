class_name FutureArt
extends RefCounted
# Resolution-independent UI drawing plus original high-resolution production art.
var g: Node2D
var city: Texture2D
var key_art: Texture2D
var display_font: Font
var surfaces: Dictionary = {}
var forge: Texture2D
var heroes: Texture2D
var enemies: Texture2D
var regions: Dictionary = {}
var title_font: Font
var mono_font: Font
var shade_top: GradientTexture2D
var shade_bottom: GradientTexture2D
var icons: Dictionary = {}
const BLUE = Color("90d6cf")
const MINT = Color("98c9b4")
const VIOLET = Color("b4b7ac")
const AMBER = Color("d9aa70")
const PAPER = Color("e3e4d4")
const QUIET = Color("99adaa")

func _init(game: Node2D) -> void:
 g=game
 city=load("res://assets/art/neon_city.png")
 if ResourceLoader.exists("res://assets/art/quarantine_terminal.png"):key_art=load("res://assets/art/quarantine_terminal.png")
 forge=load("res://assets/art/reactor_forge.png")
 heroes=load("res://assets/art/heroes.png")
 if ResourceLoader.exists("res://assets/art/enemies.png"):
  enemies=load("res://assets/art/enemies.png")
 if FileAccess.file_exists("res://assets/art/regions.json"):
  regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/regions.json"))
 title_font=load("res://assets/fonts/SpaceGrotesk.ttf")
 mono_font=load("res://assets/fonts/JetBrainsMono.ttf")
 var bold=FontVariation.new();bold.base_font=title_font;bold.variation_embolden=0.5
 display_font=bold
 shade_top=gradient(Color("070c18"),Color(0.025,0.04,0.08,0))
 shade_bottom=gradient(Color(0.025,0.04,0.08,0),Color("070c18"))
 for kind in ["damage","health","speed","shield","energy","drone","ammo","crit","poison","fire","economy","physics"]:
  icons[kind]=load("res://assets/ui/"+kind+".svg")

func gradient(a: Color,b: Color) -> GradientTexture2D:
 var result=GradientTexture2D.new()
 var ramp=Gradient.new()
 ramp.colors=PackedColorArray([a,b])
 result.gradient=ramp
 result.width=4
 result.height=256
 result.fill_from=Vector2(0,0)
 result.fill_to=Vector2(0,1)
 return result

func text(s: String,p: Vector2,size: int=16,color: Color=PAPER,mono: bool=false) -> void:
 g.draw_string(mono_font if mono else (display_font if size>=22 else title_font),p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func plate(rect: Rect2,color: Color=BLUE,fill: Color=Color("101b1e"),cut: float=9.0) -> void:
 # Glass console surfaces: warm steel, powered edges and a quiet scan texture.
 var radius=maxf(2,minf(cut,10))
 var steel=fill.lerp(Color("0a1416"),0.42)
 var key=color.to_html()+steel.to_html()+str(int(radius))
 if not surfaces.has(key):
  if surfaces.size()>=128:surfaces.clear()
  var box=StyleBoxFlat.new()
  box.bg_color=steel;box.set_corner_radius_all(int(radius));box.corner_detail=8
  box.border_color=Color(color,0.24);box.set_border_width_all(1)
  box.shadow_color=Color(0,0,0,0.4);box.shadow_size=7;box.shadow_offset=Vector2(0,3)
  surfaces[key]=box
 g.draw_style_box(surfaces[key],rect)
 if rect.size.x>100 and rect.size.y>24:
  var p=rect.position;var e=rect.end
  g.draw_line(p+Vector2(1,9),p+Vector2(1,minf(31,rect.size.y-8)),Color(color,0.8),2,true)
  g.draw_line(p+Vector2(10,5),p+Vector2(minf(54,rect.size.x-10),5),Color(color,0.13),1,true)
  g.draw_line(e-Vector2(24,6),e-Vector2(10,6),Color(color,0.32),1,true)
  for row in range(int((rect.size.y-14)/5)):
   var y=p.y+8+row*5
   g.draw_line(Vector2(p.x+8,y),Vector2(e.x-8,y),Color(color,0.018),1)

func rounded_texture(texture: Texture2D,rect: Rect2,radius: float,tint: Color=Color.WHITE) -> void:
 var points=PackedVector2Array()
 var uv=PackedVector2Array()
 var corners=[Vector2(rect.end.x-radius,rect.position.y+radius),rect.end-Vector2(radius,radius),Vector2(rect.position.x+radius,rect.end.y-radius),rect.position+Vector2(radius,radius)]
 for corner in range(4):
  for step in range(7):
   var angle=-PI/2+corner*PI/2+step*PI/12
   var p: Vector2=corners[corner]+Vector2.from_angle(angle)*radius
   points.append(p);uv.append((p-rect.position)/rect.size)
 g.draw_polygon(points,PackedColorArray([tint]),uv,texture)

func cover(texture: Texture2D,rect: Rect2,tint: Color=Color.WHITE) -> void:
 var source=Rect2(Vector2.ZERO,texture.get_size())
 var desired=rect.size.x/rect.size.y
 if source.size.x/source.size.y>desired:
  var width=source.size.y*desired
  source.position.x=(source.size.x-width)*0.5
  source.size.x=width
 else:
  var height=source.size.x/desired
  source.position.y=(source.size.y-height)*0.5
  source.size.y=height
 g.draw_texture_rect_region(texture,rect,source,tint)

func frame_region(key: String,index: int,texture: Texture2D,cols: int,rows: int) -> Rect2:
 if regions.has(key) and index<regions[key].size():
  var r=regions[key][index]
  return Rect2(r[0],r[1],r[2],r[3])
 var size=texture.get_size()/Vector2(cols,rows)
 return Rect2(Vector2(index%cols,index/cols)*size,size)

func sprite(texture: Texture2D,key: String,index: int,base: Vector2,height: float,tint: Color=Color.WHITE,angle: float=0.0,motion_scale: Vector2=Vector2.ONE) -> void:
 var source=frame_region(key,index,texture,3,1 if key=="heroes" else 2)
 var width=height*source.size.x/source.size.y
 g.draw_set_transform(base,angle,motion_scale)
 g.draw_texture_rect_region(texture,Rect2(-width*0.5,-height,width,height),source,tint)
 g.draw_set_transform(Vector2.ZERO)

func page_background() -> void:
 var texture=key_art if key_art!=null else city
 cover(texture,Rect2(0,0,540,960),Color(0.2,0.29,0.27,1))
 g.draw_rect(Rect2(0,0,540,960),Color(0.016,0.032,0.033,0.78))
 for i in range(14):
  var y=170+i*54
  g.draw_line(Vector2(18,y),Vector2(522,y),Color(BLUE,0.035),1)
 for x in [18,522]:
  g.draw_line(Vector2(x,169),Vector2(x,873),Color(BLUE,0.12),1,true)
 g.draw_texture_rect(shade_top,Rect2(0,0,540,250),false)
 g.draw_texture_rect(shade_bottom,Rect2(0,810,540,150),false)

func skyline(world: int,top: float,bottom: float) -> void:
 var tint=Color.WHITE
 if world in [1,3]:tint=Color(0.7,1,0.85)
 elif world in [5,7]:tint=Color(1,0.82,0.7)
 elif world==6:tint=Color(0.65,0.88,1)
 elif world>=8:tint=Color(0.9,0.72,1)
 # Fixed stage ratio preserves the ground plane; only distant holograms drift.
 g.draw_texture_rect(city,Rect2(0,top,540,bottom-top),false,tint*Color(0.69,0.8,0.77,1))
 g.draw_texture_rect(shade_top,Rect2(0,top,540,56),false)
 g.draw_texture_rect(shade_bottom,Rect2(0,bottom-28,540,28),false)
 for i in range(3):
  var p=Vector2(fmod(70+i*190+g.clock*(3+i),600)-30,top+48+i*24)
  g.draw_line(p,p+Vector2(13,-2),Color(BLUE,0.4),1.5,true)
 for i in range(5):
  var p=Vector2(fmod(i*119+g.clock*20,540),top+fmod(i*41+g.clock*24,bottom-top))
  g.draw_line(p,p+Vector2(-3,9),Color(BLUE,0.13),1,true)

func hero(at: Vector2,scale_value: float,pose: String) -> void:
 var motion=g.combat_motion.hero_pose()
 var offset: Vector2=motion["offset"]
 var outfit=int(g.profile.data["outfit"])
 var tint=[Color.WHITE,Color(0.72,0.9,1.12),Color(1.12,0.85,0.83)][outfit]
 if g.damage_flash>0:tint=Color(1.7,0.55,0.55)
 var tilt=0.0
 if pose=="defeat":tilt=-0.72
 elif g.damage_flash>0:tilt=-0.07
 g.draw_ellipse_shadow(at+Vector2(0,3),27*scale_value,6*scale_value)
 var source=frame_region("heroes",int(g.profile.data["class"]),heroes,3,1)
 var reduced=bool(g.profile.data["settings"].get("reduced_motion",false))
 ActorRig.draw_hero(g,heroes,source,at+Vector2(offset.x,0)*scale_value+g.combat_motion.camera_offset(),112*scale_value,tint,g.combat_motion.clock,g.deployment_age if g.mode in ["play","pause","upgrade"] else -1.0,reduced,g.quality,tilt+float(motion["angle"]),motion["scale"])
 HeroGear.draw(g,g,at,scale_value,motion,tilt)
 if not g.stats.is_empty():
  var integrity=clampf(g.hp/maxf(1,float(g.stats["max_hp"])),0,1)
  for i in range(5):
   g.draw_line(at+Vector2(-37,-74+i*6)*scale_value,at+Vector2(-31,-74+i*6)*scale_value,Color(BLUE if integrity>0.3 else g.CORAL,0.7 if (i+0.5)/5.0<integrity else 0.12),2,true)
 if g.shield>0 or pose=="special":
  g.draw_arc(at+Vector2(0,-52*scale_value),53*scale_value,-1.75,1.5,38,Color(BLUE,0.55),2,true)
 if g.shoot_flash>0:
  var muzzle=at+Vector2(44,-72)*scale_value
  for i in range(3):g.draw_circle(muzzle,(18-i*5)*scale_value,Color(AMBER,0.07+i*0.07))
  g.draw_line(muzzle-Vector2(6,0),muzzle+Vector2(15,0),PAPER,3,true)
  g.draw_line(muzzle-Vector2(0,8),muzzle+Vector2(0,8),AMBER,2,true)
 if pose=="victory":
  g.draw_arc(at+Vector2(0,-55*scale_value),65*scale_value,-g.clock,g.clock+1,30,Color(MINT,0.35),2,true)

func enemy(e: Dictionary) -> bool:
 if enemies==null:return false
 var kind=int(e["type"])
 var atlas=[0,1,2,2,3,4,4,4,0,4,4,4,2,5,2][kind]
 var height=[83,83,94,86,47,96,85,112,56,129,106,99,87,91,103][kind]
 var boss=bool(e["boss"])
 var identity=int(e.get("boss_id",0))
 if boss:
  height=160
  atlas=[2,4,2,4,5,2,4,4,4,5][identity]
 var tint=Color.WHITE
 if kind==10:tint=Color(0.65,1,1.3)
 elif kind==11:tint=Color(1.3,0.72,0.55)
 elif kind==14:tint=Color(1.15,0.8,1.3)
 if boss:tint=[Color(1,0.9,0.8),Color(0.8,1.1,0.8),Color(1,0.9,0.7),Color(0.7,1.1,0.95),Color(0.8,0.9,1.25),Color(1.2,0.9,0.6),Color(0.6,1.1,1.4),Color(1.3,0.7,0.5),Color(1.1,0.75,1.3),Color(1.2,0.8,1.2)][identity]
 if float(e["flash"])>0:tint=Color(1.5,1.5,1.5)
 var base=Vector2(e["x"],e["y"])
 var motion=g.combat_motion.enemy_pose(e)
 g.draw_ellipse_shadow(base,24 if not boss else 47,5 if not boss else 8)
 var source=frame_region("enemies",atlas,enemies,3,2)
 var reduced=bool(g.profile.data["settings"].get("reduced_motion",false))
 ActorRig.draw_enemy(g,enemies,source,base+Vector2(motion["offset"].x,0)+g.combat_motion.camera_offset(),height,tint,kind,boss,float(e["age"]),float(e.get("speed",17))*SpecialAmmo.speed_factor(e),reduced,g.quality,float(motion["angle"])*0.4,motion["scale"])
 if kind in [5,6,10,11,14] or boss:
  var accent=VIOLET if kind==14 else (AMBER if kind in [6,11] else MINT)
  if kind==10:accent=BLUE
  g.draw_arc(base+Vector2(0,-height*0.5),height*0.42,g.clock+identity,g.clock+identity+2.5,20,Color(accent,0.4),1.5,true)
 if boss:
  plate(Rect2(160,130,356,44),VIOLET,Color(0.04,0.06,0.12,0.94),6)
  text(Content.BOSSES[identity].to_upper()+"   /   PHASE %d"%int(e["phase"]),Vector2(171,147),11,VIOLET)
  g.bar(Rect2(171,157,332,5),float(e["hp"])/float(e["max_hp"]),g.CORAL)
 else:
  g.bar(Rect2(base.x-20,base.y-height-7,40,3),float(e["hp"])/float(e["max_hp"]),MINT)
 if float(e["telegraph"])>0:
  var p=Vector2(94,312)
  g.draw_arc(p,42+sin(g.clock*12)*4,0,TAU,40,g.CORAL,3,true)
  text("! IMPULS AKTIVIEREN",Vector2(170,209),15,g.CORAL)
 return true

func hud() -> void:
 var health=clampf(g.hp/maxf(1,float(g.stats["max_hp"])),0,1)
 var health_color=g.CORAL if health<0.3 else BLUE
 plate(Rect2(16,16,508,103),BLUE,Color("091517"),9)
 text("QUARANTÄNE / %02d"%g.level,Vector2(29,36),11,QUIET,true)
 text(Content.WORLDS[int(g.layout["world"])],Vector2(29,60),20,PAPER)
 text("WELLE %02d / %02d"%[g.wave,g.wave_count],Vector2(330,39),13,BLUE,true)
 for i in range(g.wave_count):
  g.draw_rect(Rect2(331+i*minf(18,118.0/g.wave_count),53,12 if g.wave_count<8 else 5,3),BLUE if i<g.wave else Color("243638"))
 text("%02d KONTAKTE"%(g.remaining+g.enemies.size()),Vector2(331,80),10,QUIET,true)
 text("CR %s"%g.compact(int(g.profile.data["coins"])),Vector2(353,104),13,AMBER,true)
 for i in range(12):
  var segment=Rect2(30+i*20,75,16,8)
  g.draw_rect(segment,Color(health_color,0.85) if (i+0.5)/12.0<=health else Color("203033"))
 text("ANZUG  %03d / %03d"%[maxi(0,int(g.hp)),int(g.stats["max_hp"])],Vector2(30,105),10,health_color,true)
 plate(Rect2(16,354,508,57),BLUE,Color("0b191b"),8)
 for x in [169,370]:g.draw_line(Vector2(x,365),Vector2(x,400),Color(BLUE,0.13),1,true)
 text("MUNITION / %s"%g.compact(int(g.stats["capacity"])),Vector2(29,370),9,QUIET,true)
 var ammo_tint=AMBER if g.ammo<=30 else BLUE
 text(g.compact(g.ammo),Vector2(29,396),27,ammo_tint,true)
 g.bar(Rect2(30,402,122,2),float(g.ammo)/maxf(1,float(g.stats["capacity"])),ammo_tint)
 text(g.weapon()[0].to_upper(),Vector2(183,369),11,PAPER)
 var cargo=g.get("ammo_cargo")
 var next_kind=String(cargo.peek()) if cargo!=null else "normal"
 for i in range(3):
  var ammo_kind=["fire","frost","emp"][i]
  var count=int(cargo.count(ammo_kind)) if cargo!=null else 0
  var color=SpecialAmmo.color(ammo_kind)
  var x=183+i*62
  var selected=next_kind==ammo_kind and count>0
  plate(Rect2(x,376,58,18),Color(color,1.0 if selected else 0.45),Color("17282b") if selected else Color("0b171a"),4)
  text(["BRAND","KRYO","EMP"][i]+" %02d"%count,Vector2(x+5,389),10,Color(color,1.0 if count>0 else 0.58),true)
  if selected:
   g.draw_line(Vector2(x+5,375),Vector2(x+53,375),Color(color,0.92),1.4,true)
   g.draw_line(Vector2(x+5,394),Vector2(x+53,394),Color(color,0.45),1,true)
 var magazine_state="NACHLADEN" if g.reload_timer>0 else "%02d IM MAGAZIN"%g.magazine
 if next_kind!="normal":magazine_state="› "+SpecialAmmo.display_name(next_kind)+" · "+magazine_state
 if g.overdrive_left>0:magazine_state+=" · BOOST %ds"%ceili(g.overdrive_left)
 var magazine_size=9
 if mono_font.get_string_size(magazine_state,HORIZONTAL_ALIGNMENT_LEFT,-1,magazine_size).x>181:magazine_size=8
 text(magazine_state,Vector2(184,406),magazine_size,AMBER if g.overdrive_left>0 else (SpecialAmmo.color(next_kind) if next_kind!="normal" else QUIET),true)
 # The orbit action owns this column; kinetic energy remains on IMPULS.

func wave_cue() -> void:
 if g.wave_banner<=0 or g.mode!="play":return
 var alpha=minf(1,g.wave_banner*2)
 plate(Rect2(173,132,226,36),MINT,Color(0.04,0.1,0.16,alpha*0.94),7)
 text("WELLE %02d  /  %d FEINDE"%[g.wave,Content.wave_enemy_count(g.level,g.wave)],Vector2(186,155),12,Color(MINT,alpha),true)

func circuit_orbit(at: Vector2,radii: Vector2,color: Color,width: float=1.0,from: float=0.0,to: float=TAU) -> void:
 var points=PackedVector2Array()
 var steps=32 if g.quality==1 else 20
 for i in range(steps+1):
  var angle=lerpf(from,to,float(i)/steps)
  points.append(at+Vector2(cos(angle)*radii.x,sin(angle)*radii.y))
 g.draw_polyline(points,color,width,true)

func circuit_disc(at: Vector2,radii: Vector2,color: Color) -> void:
 var points=PackedVector2Array()
 for i in range(32 if g.quality==1 else 20):
  var angle=TAU*i/(32.0 if g.quality==1 else 20.0)
  points.append(at+Vector2(cos(angle)*radii.x,sin(angle)*radii.y))
 g.draw_colored_polygon(points,color)

func imprint_glyph(kind: String,at: Vector2,size: float,color: Color,phase: float=0.0,alpha: float=1.0) -> void:
 if kind=="fire":
  var sway=sin(phase*4.1)*0.09
  var shape=PackedVector2Array([Vector2(-0.48,0.25),Vector2(-0.56,-0.12),Vector2(-0.27,-0.47),Vector2(-0.25,-0.12),Vector2(0.05+sway,-0.94),Vector2(0.27,-0.55),Vector2(0.28,-0.22),Vector2(0.45,-0.43),Vector2(0.55,-0.06),Vector2(0.4,0.27),Vector2(0,0.43)])
  for i in range(shape.size()):shape[i]=at+shape[i]*size
  g.draw_colored_polygon(shape,Color(color,alpha*0.92))
  var core=PackedVector2Array([at+Vector2(-0.22,0.22)*size,at+Vector2(-0.1,-0.12)*size,at+Vector2(0.04,-0.39)*size,at+Vector2(0.26,0.13)*size,at+Vector2(0.04,0.35)*size])
  g.draw_colored_polygon(core,Color("ffe3b0",alpha))
 elif kind=="frost":
  for axis in range(3):
   var ray=Vector2.from_angle(axis*PI/3)*size*0.68
   g.draw_line(at-ray,at+ray,Color(color,alpha),1.4,true)
   for side in [-1,1]:
    var tip=ray*side*0.64
    var branch=Vector2(-ray.y,ray.x)*0.24
    g.draw_line(at+tip-ray*side*0.24+branch,at+tip,Color(color,alpha*0.85),1.1,true)
    g.draw_line(at+tip-ray*side*0.24-branch,at+tip,Color(color,alpha*0.85),1.1,true)
  g.draw_circle(at,1.4,Color("e2f8ff",alpha))
 else:
  var bolt=PackedVector2Array([at+Vector2(0.12,-0.78)*size,at+Vector2(-0.4,0.04)*size,at+Vector2(0.03,0.01)*size,at+Vector2(-0.14,0.66)*size,at+Vector2(0.43,-0.15)*size,at+Vector2(0.02,-0.1)*size])
  g.draw_colored_polygon(bolt,Color(color,alpha))

func circuit_gate(x: float,y: float,width: float,factor: int,power: float,side: int,spin: float,imprint: String="normal") -> void:
 # The whole powered aperture is the true crossing span; open lanes have no gate.
 if factor<2:return
 var color=MINT if factor>=3 else BLUE
 if factor>=10:color=AMBER
 if imprint!="normal":color=SpecialAmmo.color(imprint)
 var at=Vector2(x+width*0.5,y)
 var radii=Vector2(maxf(12,width*0.5),17)
 circuit_disc(at+Vector2(0,3),radii+Vector2(3,3),Color(0,0,0,0.4))
 circuit_disc(at,radii,Color(0.035,0.11,0.12,0.23+power*0.17))
 circuit_orbit(at,radii,Color("35494a"),4)
 circuit_orbit(at,radii-Vector2(1,2),Color(color,0.4+power*0.5),1.6)
 circuit_orbit(at+Vector2(0,2),radii-Vector2(4,4),Color(color,0.7+power*0.3),2,0,PI)
 circuit_orbit(at,radii-Vector2(6,5),Color(color,0.18+power*0.28),1,PI,TAU)
 for end_x in [x,x+width]:
  g.draw_line(Vector2(end_x,y-5),Vector2(end_x,y+6),Color("687b79"),4,true)
  g.draw_circle(Vector2(end_x,y),1.4,Color(color,0.8))
 var caption="×%d"%factor
 var caption_width=display_font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,25).x
 var caption_x=x+11 if side==0 else x+width-caption_width-11
 # An engraved readout on the outer rim leaves the ball channel completely open.
 text(caption,Vector2(caption_x,y-22),25,color)
 g.draw_line(Vector2(caption_x,y-16),Vector2(caption_x+caption_width,y-16),Color(color,0.2+power*0.5),1,true)
 if imprint!="normal":
  # This badge belongs to the real aperture; the flare budget follows actual
  # crossing charge rather than suggesting a second hidden pickup field.
  var badge_x=x+11 if side==0 else x+width-67
  imprint_glyph(imprint,Vector2(badge_x+7,y-5),11,color,spin)
  text("BRAND" if imprint=="fire" else "KRYO",Vector2(badge_x+20,y+1),10,color,true)
  var charge=clampf(power,0,1)
  if charge>0.025:
   for i in range(3 if g.quality==1 else 2):
    var travel=fposmod(spin*0.36+i*0.37,1.0)
    var flare_at=Vector2(x+22+(width-44)*travel,y+10-sin(travel*PI)*3)
    if imprint=="fire":
     imprint_glyph("fire",flare_at,8+charge*9,color,spin+i,charge*0.7)
     g.draw_line(flare_at-Vector2(0,9+charge*10),flare_at-Vector2(0,12+charge*10),Color("ffe0a3",charge*0.7),1.3,true)
    else:
     var shard=PackedVector2Array([flare_at+Vector2(-3,1),flare_at+Vector2(0,-8-charge*9),flare_at+Vector2(3,0),flare_at+Vector2(0,3)])
     g.draw_colored_polygon(shard,Color(color,charge*0.65))
     g.draw_line(flare_at-Vector2(0,6),flare_at+Vector2(0,1),Color("e8faff",charge*0.82),1.2,true)
 for i in range(2 if g.quality==0 else 3):
  var phase=fposmod(spin*0.35+i*0.32,1.0)
  var px=x+12+(width-24)*phase
  var drop=sin(phase*PI)*7
  g.draw_line(Vector2(px,y-7-drop),Vector2(px,y-3-drop),Color(color,0.16+power*0.42),1,true)

func circuit_portal(at: Vector2,exit: bool,spin: float) -> void:
 var color=SpecialAmmo.color("emp")
 var halo=Color(color,0.06)
 var direction=-1.0 if exit else 1.0
 # Dark throat and concentric depth are readable as a hole, not a flat ring icon.
 g.draw_circle(at+Vector2(0,3),26,Color(0,0,0,0.34))
 g.draw_circle(at,23,Color("263743"))
 g.draw_circle(at,19.5,Color("020609"))
 circuit_orbit(at,Vector2(23,21),Color("5a7184"),2.2)
 circuit_orbit(at,Vector2(20,18),Color(color,0.82),1.6)
 circuit_orbit(at,Vector2(16,14),Color(color,0.18),1.0)
 for ring in range(3):
  var angle=spin*direction*(1.2+ring*0.12)+ring*TAU/3
  circuit_orbit(at,Vector2(17-ring*3,15-ring*2),Color(color,0.25+ring*0.08),1.2,angle,angle+2.0)
 for i in range(4 if g.quality==1 else 2):
  var angle=spin*direction*1.1+i*TAU/4
  var p=at+Vector2(cos(angle)*24,sin(angle)*22)
  var tangent=Vector2(-sin(angle),cos(angle))*direction
  g.draw_line(p-tangent*3,p+tangent,Color(color,0.52),1.1,true)
 var marker=at+Vector2(0,27 if exit else -27)
 var points=PackedVector2Array([marker+Vector2(-4,-2),marker+Vector2(0,2),marker+Vector2(4,-2)])
 g.draw_polyline(points,Color(MINT if exit else color,0.8),1.7,true)
 # A tiny inner highlight gives the outgoing hole its unambiguous exit cue.
 if exit:g.draw_line(at+Vector2(-4,7),at+Vector2(4,7),Color(MINT,0.55),1.2,true)
 else:
  for i in range(3 if g.quality==1 else 2):
   var angle=spin*0.55+i*TAU/3
   var ray=Vector2.from_angle(angle)
   var tangent=Vector2(-ray.y,ray.x)
   var spoke=PackedVector2Array([at+ray*11,at+ray*17+tangent*2.5,at+ray*19-tangent*1.8,at+ray*24])
   g.draw_polyline(spoke,Color(color,0.5),1.1,true)
  imprint_glyph("emp",at+Vector2(-15,37),8,color)
  text("EMP",at+Vector2(-7,41),10,color,true)

func circuit_obstacle(ob: Dictionary,spin: float) -> void:
 var p: Vector2=ob["pos"]
 var kind=String(ob["kind"])
 var variant=int(ob["variant"])
 if ob["body"]!=null:
  var body=ob["body"]
  if kind=="peg":
   var radius=10+variant*3
   g.draw_circle(p+Vector2(1,3),radius+2,Color(0,0,0,0.38))
   g.draw_circle(p,radius,Color("394b50"))
   g.draw_arc(p,radius-1.0,0,TAU,24,Color("8eaaa8"),1.4,true)
   g.draw_circle(p,radius-4,Color("16282c"))
   for i in range(3):
    var bolt=p+Vector2.from_angle(i*TAU/3-PI/2)*(radius-3)
    g.draw_circle(bolt,1,Color("c0cac0"))
   g.draw_circle(p,2.4,Color(AMBER,0.8))
  else:
   g.draw_set_transform(p,body.rotation)
   var width=65+variant*12
   g.panel(Rect2(-width/2.0-1,0,width+2,7),Color(0,0,0,0.4),2)
   g.panel(Rect2(-width/2.0,-4.5,width,9),Color("425557") if kind!="breakable" else Color("69504a"),2)
   g.draw_line(Vector2(-width/2.0+3,-3),Vector2(width/2.0-3,-3),Color("b4c4bb"),1.2,true)
   g.draw_line(Vector2(-width/2.0+3,3),Vector2(width/2.0-3,3),Color("16292b"),1.6,true)
   for end_x in [-width/2.0+5,width/2.0-5]:g.draw_circle(Vector2(end_x,0),1.2,Color("d5d7c6"))
   if kind!="switch":
    for n in range(3):
     var x=-12+n*10
     g.draw_line(Vector2(x,-2),Vector2(x-4,2),Color(AMBER,0.65),1.8,true)
   if kind=="switch":
    var routing=g.get("reactor_switch")
    var ready=routing!=null and routing.can_toggle()
    var moving=routing!=null and bool(routing.turning)
    var lamp=AMBER if moving else (BLUE if ready else Color("647d7d"))
    var direction=1 if body.rotation>=0 else -1
    g.draw_line(Vector2(-19,0),Vector2(19,0),Color(lamp,0.85),1.6,true)
    g.draw_polyline(PackedVector2Array([Vector2(direction*10,-2.5),Vector2(direction*17,0),Vector2(direction*10,2.5)]),PAPER if ready else lamp,1.4,true)
    g.draw_circle(Vector2.ZERO,3.8,Color("10282c"))
    g.draw_circle(Vector2.ZERO,1.8,lamp)
    for end_x in [-width/2.0+2,width/2.0-2]:
     g.draw_line(Vector2(end_x,-2.5),Vector2(end_x,2.5),Color(lamp,0.9 if ready else 0.35),2,true)
   elif kind in ["rotor","trapdoor"]:
    g.draw_circle(Vector2.ZERO,4,Color("142528"))
    g.draw_circle(Vector2.ZERO,2,AMBER)
    g.draw_arc(Vector2.ZERO,10,0.4,2.6,12,Color(AMBER,0.25),1,true)
   elif kind=="breakable":
    g.draw_polyline(PackedVector2Array([Vector2(-7,-4),Vector2(-2,0),Vector2(-5,3),Vector2(4,1),Vector2(8,4)]),Color("192327"),1.2,true)
   elif kind=="reverse":
    var sign_value=1 if variant%2==0 else -1
    g.draw_polyline(PackedVector2Array([Vector2(-7*sign_value,-2),Vector2(0,0),Vector2(-7*sign_value,2)]),BLUE,1.1,true)
   g.draw_set_transform(Vector2.ZERO)
   if kind=="switch":
    var routing=g.get("reactor_switch")
    var ready=routing!=null and routing.can_toggle()
    text("WEICHE",p+Vector2(-18,-15),8,BLUE if ready else QUIET,true)
 elif kind=="portal":
  var destination=Vector2(540-p.x,p.y+35)
  for i in range(1,9):
   var t=float(i)/9
   var point=p.lerp(destination,t)+Vector2(0,-sin(t*PI)*14)
   g.draw_circle(point,0.7,Color("9baef5",0.13))
  circuit_portal(p,false,spin)
  circuit_portal(destination,true,spin)
 elif kind=="boost":
  for n in range(3):
   g.draw_polyline(PackedVector2Array([p+Vector2(-10,-9+n*8),p+Vector2(0,-2+n*8),p+Vector2(10,-9+n*8)]),BLUE,2,true)
 elif kind=="bonus":
  g.draw_circle(p,18,Color("1b2d2b"))
  circuit_orbit(p,Vector2(18,18),Color(AMBER,0.65),1.4)
  text("+%d"%(5*(variant+1)),p+Vector2(-12,5),13,AMBER)

func circuit_power(booster: Dictionary,spin: float) -> void:
 if booster.is_empty() or bool(booster.get("consumed",false)):return
 var kind=String(booster.get("kind","energy"))
 var p=Vector2(float(booster.get("x",270)),float(booster.get("y",620)))
 var color=AMBER if kind=="overdrive" else (MINT if kind=="shield" else BLUE)
 var pulse=0.5+0.5*sin(spin*2.0)
 g.draw_circle(p,30,Color(color,0.025+pulse*0.025))
 circuit_orbit(p,Vector2(30,30),Color(color,0.12),1)
 var shell=PackedVector2Array()
 for i in range(6):shell.append(p+Vector2.from_angle(i*TAU/6+PI/6)*19)
 g.draw_colored_polygon(shell,Color("13262a"))
 var outline=shell.duplicate();outline.append(shell[0])
 g.draw_polyline(outline,Color(color,0.75),1.6,true)
 var icon=icons["speed" if kind=="overdrive" else ("shield" if kind=="shield" else "energy")]
 g.draw_texture_rect(icon,Rect2(p-Vector2(12,12),Vector2(24,24)),false,Color(color,0.9))
 for side in [-1,1]:
  g.draw_line(p+Vector2(side*22,-6),p+Vector2(side*22,6),Color(color,0.4+pulse*0.3),2,true)
 var caption="OVERDRIVE" if kind=="overdrive" else ("SCHILD" if kind=="shield" else "ENERGIE")
 var caption_width=mono_font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,8).x
 text(caption,p+Vector2(-caption_width*0.5,-35),8,color,true)

func factory() -> void:
 # A pinball-like physical circuit, with open lanes between powered apertures.
 plate(Rect2(16,473,508,401),BLUE,Color("080f16"),12)
 rounded_texture(forge,Rect2(28,486,484,379),8,Color(0.49,0.63,0.61,1))
 var busy=g.active_balls()>0 or not g.pending_balls.is_empty()
 var reduced=bool(g.profile.data["settings"].get("reduced_motion",false))
 var spin=0.0 if reduced else float(g.clock)
 # Quiet wall guides leave the obstacles and falling balls as the main action.
 for x in [22,518]:
  g.draw_line(Vector2(x,490),Vector2(x,857),Color("253b41"),7,true)
  g.draw_line(Vector2(x,490),Vector2(x,857),Color(BLUE,0.15),1,true)
  for i in range(5):
   var y=507+i*70
   g.draw_line(Vector2(x,y),Vector2(x,y+12),Color(MINT,0.32),2.5,true)
 if not busy:
  for i in range(5):g.draw_circle(Vector2(g.aim,510+i*7),1.0,Color(BLUE,0.18+i*0.05))
 for row in range(3):
  var gate=g.layout["gates"][row]
  var y=float(gate["y"])
  var split=g.gate_split(row)
  for side in range(2):
   var x=35.0 if side==0 else split+7
   var width=split-42 if side==0 else 505-split-7
   var factor=int(gate["left"] if side==0 else gate["right"])
   var imprint=("fire" if side==0 else "frost") if row==1 else "normal"
   circuit_gate(x,y,width,factor,float(g.reactor_fx.gate_charge[row*2+side]),side,spin,imprint)
 for ob in g.obstacles:
  if not ob["broken"]:circuit_obstacle(ob,spin)
 var booster=g.get("wave_booster")
 if booster is Dictionary:circuit_power(booster,spin)
 # Articulated magnetic injector: the actual emission point remains y498.
 var at=Vector2(g.aim,480)
 var recoil=g.reactor_fx.nozzle_charge
 g.draw_line(at-Vector2(0,19),at+Vector2(0,7),Color("3b5358"),9,true)
 g.panel(Rect2(at-Vector2(27,8),Vector2(54,24)),Color("293e43"),5)
 for offset in [-21,21]:
  g.draw_line(at+Vector2(offset,2),at+Vector2(offset*0.65,18+recoil*3),Color("8ca6a4"),4,true)
 g.draw_line(at+Vector2(-14,-3),at+Vector2(14,-3),MINT,2,true)
 g.draw_line(at+Vector2(-9,14),at+Vector2(9,14),Color(BLUE,0.65+recoil*0.35),2.5,true)
 # Slim collection rail: the old status cards obscured the lowest physical obstacle.
 var units=0
 for ball in g.pool:
  if ball.live:units+=ball.weight
 var charge=minf(1,g.reactor_fx.collector_charge)
 var mouth=PackedVector2Array([Vector2(34,838),Vector2(506,838),Vector2(487,868),Vector2(53,868)])
 g.draw_colored_polygon(mouth,Color("0d2228"))
 var edge=mouth.duplicate();edge.append(mouth[0])
 g.draw_polyline(edge,Color(BLUE,0.3),1,true)
 g.draw_line(Vector2(42,840),Vector2(498,840),Color(MINT,0.16+charge*0.24),5,true)
 g.draw_line(Vector2(42,840),Vector2(498,840),Color(MINT,0.48+charge*0.52),1.5,true)
 text("IM FLUSS %s"%g.compact(units) if busy else "%d STARTKUGELN"%int(g.stats["drop"]),Vector2(42,861),9,QUIET,true)
 text("SAMMLER +%s"%g.compact(g.drop_credited),Vector2(213,861),10,MINT,true)
 text("FREI %s"%g.compact(maxi(0,int(g.stats["capacity"])-g.ammo)),Vector2(415,861),9,QUIET,true)

func icon_key(id: int) -> String:
 var stat=String(Content.UPGRADES[id][2])
 if stat in ["max_hp","heal","regen","vitality","leech"]:return "health"
 if stat in ["speed","reload","dodge","slow"]:return "speed"
 if stat in ["shield","armor","thorns","field"]:return "shield"
 if stat in ["energy","energy_regen","special"]:return "energy"
 if stat=="drone":return "drone"
 if stat in ["ammo","magazine","capacity","recycle"]:return "ammo"
 if stat in ["crit","crit_damage","range"]:return "crit"
 if stat=="poison":return "poison"
 if stat=="burn":return "fire"
 if stat in ["bounty","wisdom","salvage"]:return "economy"
 if stat in ["drop","collection","attempt"]:return "physics"
 return "damage"

func menu() -> void:
 var reduced=bool(g.profile.data["settings"].get("reduced_motion",false))
 var settle=0.0 if reduced else pow(maxf(0,1-g.screen_age/1.1),3)
 var drift=0.0 if reduced else sin(g.clock*0.15)*2
 if key_art!=null:cover(key_art,Rect2(-8-settle*8+drift,-8-settle*10,556+settle*16,980+settle*20),Color(0.78,0.88,0.83,1))
 else:page_background()
 g.draw_texture_rect(shade_top,Rect2(0,0,540,335),false)
 g.draw_texture_rect(shade_bottom,Rect2(0,495,540,465),false)
 g.draw_rect(Rect2(0,0,540,960),Color(0.01,0.04,0.035,0.14))
 # Low intensity dust, no rapid flicker or fullscreen strobe.
 for i in range(8 if g.quality==0 else 18):
  var x=fposmod(i*91.7+(0 if reduced else g.clock*(1+i%3)),540)
  var y=290+fposmod(i*47.3-(0 if reduced else g.clock*7),345)
  g.draw_circle(Vector2(x,y),0.7,Color(BLUE,0.18))
 plate(Rect2(30,611,480,57),BLUE,Color(0.025,0.07,0.075,0.94),8)
 for x in [19,521]:
  g.draw_line(Vector2(x,28),Vector2(x,580),Color(BLUE,0.1),1,true)
  for i in range(5):g.draw_line(Vector2(x,48+i*113),Vector2(x+(5 if x<100 else -5),48+i*113),Color(BLUE,0.38),1,true)
 g.draw_line(Vector2(32,263),Vector2(158,263),Color(BLUE,0.6),1,true)
 text("LOKALES TERMINAL  /  SYSTEM BEREIT",Vector2(32,282),9,BLUE,true)
 g.draw_circle(Vector2(47,40),2,BLUE)

func style_slider(slider: HSlider) -> void:
 var rail=StyleBoxFlat.new()
 rail.bg_color=Color("14243c")
 rail.set_corner_radius_all(3)
 rail.content_margin_top=2
 rail.content_margin_bottom=2
 slider.add_theme_stylebox_override("slider",rail)
 var fill=rail.duplicate()
 fill.bg_color=Color("3c8296")
 slider.add_theme_stylebox_override("grabber_area",fill)
 slider.add_theme_stylebox_override("grabber_area_highlight",fill)
 var thumb=load("res://assets/ui/slider_thumb.svg")
 slider.add_theme_icon_override("grabber",thumb)
 slider.add_theme_icon_override("grabber_highlight",thumb)
