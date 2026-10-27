class_name FutureArt
extends RefCounted
# Resolution-independent UI drawing plus original high-resolution production art.
var g: Node2D
var city: Texture2D
var forge: Texture2D
var heroes: Texture2D
var enemies: Texture2D
var regions: Dictionary = {}
var title_font: Font
var mono_font: Font
var shade_top: GradientTexture2D
var shade_bottom: GradientTexture2D
var icons: Dictionary = {}
const BLUE = Color("55d8ff")
const MINT = Color("5af5c5")
const VIOLET = Color("ad8cff")
const AMBER = Color("ffc880")
const PAPER = Color("eff5ff")
const QUIET = Color("8a9dbb")

func _init(game: Node2D) -> void:
 g=game
 city=load("res://assets/art/neon_city.png")
 forge=load("res://assets/art/reactor_forge.png")
 heroes=load("res://assets/art/heroes.png")
 if ResourceLoader.exists("res://assets/art/enemies.png"):
  enemies=load("res://assets/art/enemies.png")
 if FileAccess.file_exists("res://assets/art/regions.json"):
  regions=JSON.parse_string(FileAccess.get_file_as_string("res://assets/art/regions.json"))
 title_font=load("res://assets/fonts/SpaceGrotesk.ttf")
 mono_font=load("res://assets/fonts/JetBrainsMono.ttf")
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
 g.draw_string(mono_font if mono else title_font,p,s,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)

func plate(rect: Rect2,color: Color=BLUE,fill: Color=Color("0f192b"),cut: float=9.0) -> void:
 var p=rect.position;var e=rect.end
 var shape=PackedVector2Array([p+Vector2(cut,0),Vector2(e.x-cut,p.y),Vector2(e.x,p.y+cut),e-Vector2(0,cut),e-Vector2(cut,0),Vector2(p.x+cut,e.y),Vector2(p.x,e.y-cut),p+Vector2(0,cut)])
 g.draw_colored_polygon(shape,fill)
 var edge=shape.duplicate();edge.append(shape[0])
 g.draw_polyline(edge,Color(color,0.25),1,true)
 g.draw_line(p+Vector2(cut,0),p+Vector2(minf(52,rect.size.x-cut),0),Color(color,0.9),2,true)
 g.draw_line(e-Vector2(minf(30,rect.size.x-cut),0),e-Vector2(cut,0),Color(color,0.7),2,true)

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

func sprite(texture: Texture2D,key: String,index: int,base: Vector2,height: float,tint: Color=Color.WHITE,angle: float=0.0) -> void:
 var source=frame_region(key,index,texture,3,1 if key=="heroes" else 2)
 var width=height*source.size.x/source.size.y
 g.draw_set_transform(base,angle)
 g.draw_texture_rect_region(texture,Rect2(-width*0.5,-height,width,height),source,tint)
 g.draw_set_transform(Vector2.ZERO)

func page_background() -> void:
 cover(city,Rect2(0,0,540,960),Color(0.18,0.25,0.39,1))
 g.draw_rect(Rect2(0,0,540,960),Color(0.018,0.03,0.065,0.55))
 for i in range(7):
  var x=30+i*82
  g.draw_line(Vector2(x,150),Vector2(x-140,960),Color(BLUE,0.035),1,true)
 g.draw_texture_rect(shade_top,Rect2(0,0,540,330),false)
 g.draw_texture_rect(shade_bottom,Rect2(0,650,540,310),false)

func skyline(world: int,top: float,bottom: float) -> void:
 var tint=Color.WHITE
 if world in [1,3]:tint=Color(0.7,1,0.85)
 elif world in [5,7]:tint=Color(1,0.82,0.7)
 elif world==6:tint=Color(0.65,0.88,1)
 elif world>=8:tint=Color(0.9,0.72,1)
 # Fixed stage ratio preserves the ground plane; only distant holograms drift.
 g.draw_texture_rect(city,Rect2(0,top,540,bottom-top),false,tint)
 g.draw_texture_rect(shade_top,Rect2(0,top,540,56),false)
 g.draw_texture_rect(shade_bottom,Rect2(0,bottom-28,540,28),false)
 for i in range(3):
  var p=Vector2(fmod(70+i*190+g.clock*(3+i),600)-30,top+48+i*24)
  g.draw_line(p,p+Vector2(13,-2),Color(BLUE,0.4),1.5,true)
 for i in range(5):
  var p=Vector2(fmod(i*119+g.clock*20,540),top+fmod(i*41+g.clock*24,bottom-top))
  g.draw_line(p,p+Vector2(-3,9),Color(BLUE,0.13),1,true)

func hero(at: Vector2,scale_value: float,pose: String) -> void:
 var bob=sin(g.clock*3)*1.0
 var recoil=-3.5 if g.shoot_flash>0 else 0.0
 var outfit=int(g.profile.data["outfit"])
 var tint=[Color.WHITE,Color(0.72,0.9,1.12),Color(1.12,0.85,0.83)][outfit]
 if g.damage_flash>0:tint=Color(1.7,0.55,0.55)
 var tilt=0.0
 if pose=="defeat":tilt=-0.72
 elif g.damage_flash>0:tilt=-0.07
 g.draw_ellipse_shadow(at+Vector2(0,3),27*scale_value,6*scale_value)
 sprite(heroes,"heroes",int(g.profile.data["class"]),at+Vector2(recoil,bob),112*scale_value,tint,tilt)
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
 var bob=sin(float(e["age"])*7)*2
 g.draw_ellipse_shadow(base,24 if not boss else 47,5 if not boss else 8)
 sprite(enemies,"enemies",atlas,base+Vector2(0,bob),height,tint,sin(float(e["age"])*7)*0.025)
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
 plate(Rect2(16,16,508,103),BLUE,Color("0c1527"),10)
 text("RF / DEADWAVE",Vector2(30,37),11,BLUE,true)
 text("SEKTOR %02d"%g.level,Vector2(29,63),24,PAPER)
 text(Content.WORLDS[int(g.layout["world"])].to_upper(),Vector2(30,81),10,QUIET,true)
 text("%02d FEINDE"%(g.remaining+g.enemies.size()),Vector2(331,80),9,QUIET,true)
 var title="WELLE %02d"%g.wave
 text(title,Vector2(330,41),15,PAPER)
 text("/ %02d"%g.wave_count,Vector2(419,41),11,QUIET,true)
 for i in range(g.wave_count):
  g.draw_rect(Rect2(331+i*minf(18,118.0/g.wave_count),56,12 if g.wave_count<8 else 5,3),MINT if i<g.wave else Color("28344d"))
 g.bar(Rect2(30,96,252,5),g.hp/maxf(1,float(g.stats["max_hp"])),g.CORAL)
 text("%03d / %03d HP"%[maxi(0,int(g.hp)),int(g.stats["max_hp"])],Vector2(30,113),9,QUIET,true)
 text("CR  %s"%g.compact(int(g.profile.data["coins"])),Vector2(355,105),15,AMBER,true)
 plate(Rect2(16,354,508,57),BLUE,Color("101c30"),8)
 g.draw_line(Vector2(169,366),Vector2(169,400),Color(BLUE,0.16),1,true)
 g.draw_line(Vector2(370,366),Vector2(370,400),Color(BLUE,0.16),1,true)
 text("MUNITION / %s"%g.compact(int(g.stats["capacity"])),Vector2(29,370),9,QUIET,true)
 var ammo_tint=AMBER if g.ammo<=30 else MINT
 text(g.compact(g.ammo),Vector2(29,395),25,ammo_tint)
 g.bar(Rect2(30,402,122,3),float(g.ammo)/maxf(1,float(g.stats["capacity"])),ammo_tint)
 text(g.weapon()[0].to_upper(),Vector2(183,375),12,PAPER)
 var state="NACHLADEN" if g.reload_timer>0 else "%02d IM MAGAZIN"%g.magazine
 text(state,Vector2(184,397),9,QUIET,true)
 text("IMPULS",Vector2(385,370),9,QUIET,true)
 text("BEREIT" if g.energy>=50 else "%02d / 50"%int(g.energy),Vector2(385,391),15,BLUE,true)
 g.bar(Rect2(385,398,121,4),g.energy/100.0,BLUE)

func wave_cue() -> void:
 if g.wave_banner<=0 or g.mode!="play":return
 var alpha=minf(1,g.wave_banner*2)
 plate(Rect2(173,132,226,36),MINT,Color(0.04,0.1,0.16,alpha*0.94),7)
 text("WELLE %02d  /  %d FEINDE"%[g.wave,Content.wave_enemy_count(g.level,g.wave)],Vector2(186,155),12,Color(MINT,alpha),true)

func factory() -> void:
 # Active reactor forge: recessed circular engine, powered rails and three gates.
 plate(Rect2(16,473,508,401),BLUE,Color("080f1d"),12)
 g.draw_texture_rect(forge,Rect2(28,486,484,379),false,Color(0.85,0.94,1,1))
 var center=Vector2(270,668)
 # Slow induction arcs belong to the back plate; impacts supply the bright action.
 for radius in [116,159]:
  g.draw_arc(center,radius,g.clock*0.12+radius,g.clock*0.12+radius+0.8,28,Color(BLUE,0.07),1,true)
 var busy=g.active_balls()>0 or not g.pending_balls.is_empty()
 for x in [22,518]:
  g.draw_line(Vector2(x,490),Vector2(x,857),Color("192b43"),8,true)
  g.draw_line(Vector2(x,490),Vector2(x,857),Color(BLUE,0.18),1,true)
  for i in range(10):
   var y=503+i*34
   var alpha=0.22+(0.55*maxf(0,sin(g.clock*5-i*0.7)) if busy else 0.0)
   g.draw_line(Vector2(x,y),Vector2(x,y+16),Color(MINT,alpha),3,true)
 # Subtle aim guide is honest about the first gate, never a promised trajectory.
 if not busy:
  var first_y=float(g.layout["gates"][0]["y"])-23
  for i in range(5):
   var y=510+i*7
   if y<first_y:g.draw_circle(Vector2(g.aim,y),1.1,Color(BLUE,0.25+i*0.08))
 for row in range(3):
  var gate=g.layout["gates"][row];var y=float(gate["y"]);var split=g.gate_split(row)
  for side in range(2):
   var x=35.0 if side==0 else split+7
   var width=split-42 if side==0 else 505-split-7
   var factor=int(gate["left"] if side==0 else gate["right"])
   var tint=MINT if factor>=3 else BLUE
   if factor==1:tint=QUIET
   var power=g.reactor_fx.gate_charge[row*2+side]
   g.draw_rect(Rect2(x,y-16,width,32),Color(tint,0.025+power*0.09))
   # Segmented laser field, glass badge and illuminated electrode endcaps.
   for offset in [-8,8]:
    g.draw_line(Vector2(x,y+offset),Vector2(x+width,y+offset),Color(tint,0.12+power*0.3),1,true)
   g.draw_line(Vector2(x,y),Vector2(x+width,y),Color(tint,0.3+power*0.5),1.3,true)
   for electrode_x in [x,x+width]:
    plate(Rect2(electrode_x-3,y-20,6,40),tint,Color("24354a"),2)
    g.draw_line(Vector2(electrode_x,y-13),Vector2(electrode_x,y+13),Color(tint,0.8),2,true)
   var badge_x=x+width*0.5
   plate(Rect2(badge_x-36,y-23,72,46),tint,Color("101e31"),9)
   g.draw_line(Vector2(badge_x-25,y+19),Vector2(badge_x+25,y+19),Color(tint,0.12+power*0.7),2,true)
   text("×%d"%factor,Vector2(badge_x-25 if factor<10 else badge_x-30,y+10),28,tint)
   # Bright traveling energy flecks, accelerated only while balls are in flight.
   if factor>1:
    var travel=fmod(g.clock*(65 if busy else 17)+row*43+side*20,maxf(1,width))
    g.draw_line(Vector2(x+travel,y),Vector2(x+minf(width,travel+9),y),Color(tint,0.5),2,true)
  g.draw_circle(Vector2(split,y),4,Color("24364e"))
  g.draw_arc(Vector2(split,y),7,g.clock*2,g.clock*2+4.8,16,Color(BLUE,0.6),1,true)
 for ob in g.obstacles:
  if ob["broken"]:continue
  var p: Vector2=ob["pos"];var kind=String(ob["kind"]);var variant=int(ob["variant"])
  if ob["body"]!=null:
   var body=ob["body"]
   if kind=="peg":
    g.draw_circle(p,13+variant*3,Color("234157"))
    g.draw_arc(p,10+variant*3,0,TAU,24,BLUE,2,true)
    g.draw_circle(p,4,PAPER)
   else:
    g.draw_set_transform(p,body.rotation)
    var width=66+variant*12
    g.panel(Rect2(-width/2,-6,width,12),Color("1b2b42") if kind!="breakable" else Color("553b39"),3)
    g.draw_line(Vector2(-width/2+3,-4),Vector2(width/2-3,-4),Color("a4becb"),2,true)
    g.draw_line(Vector2(-width/2+3,4),Vector2(width/2-3,4),Color(BLUE,0.45),1.2,true)
    for n in range(3):g.draw_line(Vector2(-14+n*12,-3),Vector2(-18+n*12,3),Color(AMBER,0.55),2,true)
    if kind in ["rotor","trapdoor"]:
     g.draw_circle(Vector2.ZERO,9,Color("1d293b"))
     g.draw_arc(Vector2.ZERO,6,0,TAU,20,g.CORAL,2,true)
     g.draw_circle(Vector2.ZERO,2,PAPER)
    g.draw_set_transform(Vector2.ZERO)
  elif kind=="portal":
   for pos in [p,Vector2(540-p.x,p.y+35)]:
    g.draw_arc(pos,19,g.clock*2,g.clock*2+5.4,28,VIOLET,3,true)
    g.draw_arc(pos,24,-g.clock,-g.clock+3.8,24,Color(BLUE,0.4),1,true)
  elif kind=="boost":
   for n in range(3):g.draw_polyline(PackedVector2Array([p+Vector2(-10,-10+n*9),p+Vector2(0,-3+n*9),p+Vector2(10,-10+n*9)]),BLUE,2.5,true)
  elif kind=="bonus":
   g.draw_circle(p,23,Color(AMBER,0.07))
   g.draw_arc(p,18,0,TAU,24,Color(AMBER,0.7),1.5,true)
   text("+%d"%(5*(variant+1)),p+Vector2(-12,5),14,AMBER)
 # Twin-clamp magnetic injector. Its light follows each real emitted ball.
 var at=Vector2(g.aim,480)
 var recoil=g.reactor_fx.nozzle_charge
 g.draw_line(at-Vector2(0,19),at+Vector2(0,7),Color("3b536c"),10,true)
 plate(Rect2(at-Vector2(31,12),Vector2(62,29)),BLUE,Color("24364d"),7)
 for offset in [-21,21]:
  g.draw_line(at+Vector2(offset,4),at+Vector2(offset*0.7,18+recoil*3),Color("547087"),5,true)
 g.draw_line(at+Vector2(-15,-6),at+Vector2(15,-6),MINT,2.5,true)
 g.draw_line(at+Vector2(-10,14),at+Vector2(10,14),Color(BLUE,0.65+recoil*0.35),3,true)
 # Real virtual mass, rather than the capped number of representative bodies.
 var units=0
 for ball in g.pool:
  if ball.live:units+=ball.weight
 if busy:
  plate(Rect2(35,786,116,41),BLUE,Color(0.035,0.07,0.12,0.92),5)
  plate(Rect2(339,786,164,41),MINT,Color(0.035,0.07,0.12,0.92),5)
  text("IM FLUSS",Vector2(40,801),9,QUIET,true)
  text(g.compact(units),Vector2(40,821),18,MINT,true)
  text("GUTGESCHRIEBEN",Vector2(346,801),9,QUIET,true)
  text("+"+g.compact(g.drop_credited),Vector2(415,821),18,MINT,true)
 else:
  plate(Rect2(35,786,256,41),BLUE,Color(0.035,0.07,0.12,0.92),5)
  plate(Rect2(339,786,164,41),MINT,Color(0.035,0.07,0.12,0.92),5)
  text("%d KUGELN · GERADE ROUTE ×%d"%[int(g.stats["drop"]),g.route_factor()],Vector2(42,801),10,BLUE)
  text("ABPRALLER ÄNDERN DEN WEG",Vector2(42,818),9,QUIET,true)
  text("LAGER FREI",Vector2(347,801),9,QUIET,true)
  text(g.compact(maxi(0,int(g.stats["capacity"])-g.ammo)),Vector2(430,820),18,MINT,true)
 # Magnetic collection mouth. Rotor light responds to actual incoming units.
 var charge=minf(1,g.reactor_fx.collector_charge)
 g.draw_colored_polygon(PackedVector2Array([Vector2(34,831),Vector2(506,831),Vector2(477,869),Vector2(63,869)]),Color(0.045,0.09,0.16,0.6))
 g.draw_polyline(PackedVector2Array([Vector2(34,831),Vector2(63,869),Vector2(477,869),Vector2(506,831)]),Color(BLUE,0.3),1,true)
 g.draw_line(Vector2(47,836),Vector2(493,836),Color(MINT,0.1+charge*0.22),9,true)
 g.draw_line(Vector2(47,836),Vector2(493,836),Color(MINT,0.5+charge*0.5),2,true)
 for x in [85,455]:
  var p=Vector2(x,852)
  g.draw_circle(p,13,Color("091421"))
  g.draw_arc(p,12,0,TAU,28,Color(BLUE,0.3),1,true)
  for blade in range(3):
   var angle=g.clock*(5 if busy else 1.5)+blade*TAU/3
   g.draw_arc(p,8,angle,angle+1.1,8,Color(MINT,0.4+charge*0.6),2,true)
  g.draw_circle(p,2,PAPER)
 for n in range(5):
  var x=133+n*66
  var offset=fmod(g.clock*(25 if busy else 10)+n*5,17)
  var alpha=0.15+charge*0.5
  g.draw_polyline(PackedVector2Array([Vector2(x-6,838+offset),Vector2(x,843+offset),Vector2(x+6,838+offset)]),Color(MINT,alpha),1.5,true)
 plate(Rect2(185,845,170,21),MINT,Color("0d202e"),4)
 text("MUNITIONSSCHMIEDE",Vector2(202,860),10,MINT,true)

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
 page_background()
 g.draw_texture_rect(city,Rect2(0,230,540,370),false)
 g.draw_texture_rect(shade_top,Rect2(0,230,540,95),false)
 g.draw_texture_rect(shade_bottom,Rect2(0,465,540,150),false)
 for radius in [83,98,116]:
  g.draw_arc(Vector2(275,471),radius,-g.clock*0.1,g.clock*0.05+4.1,60,Color(BLUE,0.15),1,true)
 hero(Vector2(266,587),2.38,"idle")
 plate(Rect2(30,268,145,26),BLUE,Color("0d2032"),5)
 text("DIE WELT NACH NULL",Vector2(40,285),9,BLUE,true)
 plate(Rect2(30,596,480,36),BLUE,Color("0d2032"),6)
 plate(Rect2(353,547,157,35),MINT,Color("0d2032"),6)
 text("OFFLINE / BEREIT",Vector2(366,569),10,MINT,true)

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
