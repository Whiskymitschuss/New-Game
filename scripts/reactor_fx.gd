class_name ReactorFX
extends Node2D
# One bounded additive pass. Visual randomness never changes combat or ball paths.
var game: Node2D
var events: Array = []
var motes: Array = []
var gate_charge := PackedFloat32Array([0,0,0,0,0,0])
var collector_charge := 0.0
var nozzle_charge := 0.0
var glow: GradientTexture2D
var visual_rng := RandomNumberGenerator.new()

func _ready() -> void:
 z_index=19
 var material_add=CanvasItemMaterial.new()
 material_add.blend_mode=CanvasItemMaterial.BLEND_MODE_ADD
 material=material_add
 var ramp=Gradient.new()
 ramp.offsets=PackedFloat32Array([0,0.12,0.38,1])
 ramp.colors=PackedColorArray([Color(1,1,1,0.7),Color(1,1,1,0.28),Color(1,1,1,0.06),Color(1,1,1,0)])
 glow=GradientTexture2D.new()
 glow.gradient=ramp
 glow.width=64;glow.height=64
 glow.fill=GradientTexture2D.FILL_RADIAL
 glow.fill_from=Vector2(0.5,0.5);glow.fill_to=Vector2(1,0.5)
 visual_rng.seed=40963

func reset() -> void:
 events.clear();motes.clear()
 gate_charge.fill(0)
 collector_charge=0;nozzle_charge=0

func pulse(at: Vector2,color: Color,kind: String="impact",strength: float=1.0) -> void:
 if game.mode!="play":return
 if kind=="collect":collector_charge=minf(1.5,collector_charge+0.28)
 if kind=="inject":nozzle_charge=1.0
 # Merge bursts from neighbouring representatives to bound overdraw at x100.
 for event in events:
  if event["kind"]==kind and event["age"]<0.07 and event["at"].distance_to(at)<30:
   event["strength"]=minf(1.8,float(event["strength"])+0.12)
   return
 var limit=24 if game.quality==1 else 10
 if events.size()>=limit:events.pop_front()
 events.append({"at":at,"color":color,"kind":kind,"age":0.0,"strength":clampf(strength,0.5,1.8)})
 var count=5 if game.quality==1 else 2
 for i in range(count):
  if motes.size()>=(96 if game.quality==1 else 24):break
  var angle=visual_rng.randf_range(-PI,0)
  motes.append({"at":at,"vel":Vector2.from_angle(angle)*visual_rng.randf_range(30,115),"life":0.45,"color":color})

func gate_hit(at: Vector2,row: int,side: int,factor: int) -> void:
 gate_charge[row*2+side]=1.0
 if factor>1:pulse(at,FutureArt.MINT if factor>=3 else FutureArt.BLUE,"gate",1.0+minf(0.6,factor*0.03))

func _process(delta: float) -> void:
 visible=game.mode=="play"
 if not visible:return
 for i in range(6):gate_charge[i]=maxf(0,gate_charge[i]-delta*2.8)
 collector_charge=maxf(0,collector_charge-delta*2)
 nozzle_charge=maxf(0,nozzle_charge-delta*5)
 for i in range(events.size()-1,-1,-1):
  events[i]["age"]+=delta
  if events[i]["age"]>0.55:events.remove_at(i)
 for i in range(motes.size()-1,-1,-1):
  motes[i]["life"]-=delta
  motes[i]["at"]+=motes[i]["vel"]*delta
  motes[i]["vel"]*=maxf(0,1-delta*3)
  if motes[i]["life"]<=0:motes.remove_at(i)
 queue_redraw()

func halo(at: Vector2,size: Vector2,color: Color,alpha: float) -> void:
 draw_texture_rect(glow,Rect2(at-size*0.5,size),false,Color(color,alpha))

func _draw() -> void:
 if glow==null:return
 for event in events:
  var t=float(event["age"])/0.55
  var fade=pow(1-t,2)
  var at: Vector2=event["at"]
  var color: Color=event["color"]
  var strength=float(event["strength"])
  var radius=(12+t*36)*strength
  halo(at,Vector2(90,90)*strength,color,fade*0.65)
  draw_arc(at,radius,0,TAU,28,Color(color,fade*0.6),1.4,true)
  # Anamorphic light flare: short bright core, long horizontal falloff.
  halo(at,Vector2(150,13)*strength,color,fade*0.75)
  draw_line(at-Vector2(17,0)*strength,at+Vector2(17,0)*strength,Color(color,fade),1.5,true)
  draw_line(at-Vector2(0,9),at+Vector2(0,9),Color(color,fade*0.65),1,true)
  if event["kind"]=="collect" and t<0.8:
   var target=Vector2(74,388)
   # Trace the physical energy rail up the left side to the real ammo counter.
   var path=PackedVector2Array([at,Vector2(23,852),Vector2(23,388),target])
   var length=at.distance_to(path[1])+464+51
   var distance=t/0.8*length
   for segment in range(3):
    var a=path[segment];var b=path[segment+1];var span=a.distance_to(b)
    if distance<=span:
     var p=a.lerp(b,distance/maxf(1,span))
     halo(p,Vector2(24,38),color,fade)
     break
    distance-=span
 for mote in motes:
  draw_line(mote["at"]-mote["vel"]*0.035,mote["at"],Color(mote["color"],mote["life"]*1.7),1.5,true)
