#!/usr/bin/env python3
"""Original RF Worlds arsenal glyphs. Deterministic vectors; no external assets."""
from pathlib import Path

OUT=Path(__file__).resolve().parent.parent/'assets/ui/weapons'
OUT.mkdir(parents=True,exist_ok=True)
STEEL='url(#steel)'; DARK='url(#dark)'; CYAN='#70edee'; LIGHT='#b8d0df'; INK='#091523'; MID='#607c90'

def p(points,fill=STEEL,stroke=INK,width=1.6):
 return f'<path d="{points}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linejoin="round"/>'
def line(x1,y1,x2,y2,c=CYAN,w=1.5):
 return f'<path d="M{x1} {y1}L{x2} {y2}" fill="none" stroke="{c}" stroke-width="{w}" stroke-linecap="round"/>'
def rect(x,y,w,h,fill=STEEL,r=1.5):
 return f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="{INK}" stroke-width="1.5"/>'
def circle(x,y,r,fill=STEEL):
 return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{INK}" stroke-width="1.5"/>'
def rivet(x,y):
 return circle(x,y,1.2,LIGHT)
def grip(x,y):
 return ''.join(line(x+i*2,y+i*4,x+9+i*2,y-2+i*4,MID,1.2) for i in range(3))
def vent(x,y,n=4):
 return ''.join(line(x+i*5,y,x+i*5+1,y+4,INK,1.6) for i in range(n))
def optic(x,y,w=20):
 return rect(x,y,w,5,DARK)+rect(x+3,y+5,3,4,DARK)+rect(x+w-6,y+5,3,4,DARK)+line(x+w-1,y+1,x+w-1,y+4,CYAN,2)

guns=[]
# 00 / Pistol: square-slide service sidearm with a swept backstrap.
guns.append([
 p('M40 31L62 31 69 39 64 44 59 42 55 55 40 52 45 35',DARK),
 p('M31 21L86 21 95 25 94 32 72 33 66 36 37 33 31 29'),
 p('M33 20L82 20 88 24 38 24',LIGHT),
 rect(88,25,10,7,DARK),line(94,26,94,30,CYAN,2),
 p('M60 33L72 34 71 42 62 43 58 40 60 37',DARK),
 p('M63 34L63 39 68 39 69 35',MID),
 p('M40 34L54 35 50 49 42 48',MID),grip(42,38),
 rect(34,25,7,4,CYAN),rect(62,20,11,3,MID),line(43,28,82,28,LIGHT,1),
 line(36,18,40,18,LIGHT,2),line(82,19,85,19,LIGHT,2),rivet(55,30)
])
# 01 / Revolver: visible six-shot cylinder, broad hammer, precision muzzle.
guns.append([
 p('M35 31L49 32 56 41 51 43 46 55 31 51 36 36',DARK),
 p('M35 21L57 21 64 26 58 37 40 38 32 30'),
 rect(56,22,42,8),p('M98 22L106 25 106 29 98 30',DARK),
 circle(49,29,10),circle(49,29,7,DARK),
 p('M46 22L51 22 55 28 52 35 46 35 43 29',MID),
 line(47,24,47,32,LIGHT),line(52,25,53,29,LIGHT,1.1),
 p('M31 24L26 19 28 15 33 18 36 23',MID),
 p('M54 36L64 36 65 43 56 45 51 41',DARK),line(58,37,57,40,MID,2),
 p('M34 38L43 38 39 50 34 48',MID),grip(33,40),
 line(62,25,96,25,CYAN,1.8),rect(88,20,4,3,MID),rivet(38,30),rivet(49,29)
])
# 02 / SMG: compact folding stock and a long straight magazine.
guns.append([
 p('M8 26L31 22 35 27 34 35 25 36 11 42 8 38 22 31 9 31',DARK),
 p('M29 23L75 22 87 26 87 34 72 38 34 36'),
 p('M34 21L72 21 77 24 35 26',LIGHT),
 rect(83,25,25,7,DARK),rect(105,24,10,9),line(112,26,112,31,CYAN,2),
 p('M58 37L71 36 74 55 62 57',MID),line(66,40,69,52,LIGHT,1.4),
 p('M40 35L53 36 49 49 38 47',DARK),grip(40,38),
 p('M51 36L60 37 59 45 51 45 49 41',DARK),
 rect(37,17,8,5,DARK),rect(67,17,6,5,DARK),
 line(40,28,70,28,CYAN,2.2),vent(70,30,3),rivet(34,30)
])
# 03 / Assault rifle: long forend, optic, angled box magazine, full stock.
guns.append([
 p('M7 25L30 22 34 27 31 35 20 35 9 43 6 39 12 32',DARK),
 p('M29 23L66 22 70 25 99 25 102 30 96 35 63 36 54 40 31 36'),
 p('M32 21L66 21 68 24 34 26',LIGHT),
 rect(97,27,19,5,DARK),rect(115,25,7,9,MID),
 p('M58 36L70 36 75 51 72 56 61 53',MID),
 line(65,40,68,51,LIGHT,1.6),line(70,40,73,49,INK,1),
 p('M39 36L51 37 46 50 36 46',DARK),grip(39,39),
 optic(45,13,23),vent(75,27,4),
 line(74,33,94,33,CYAN,2),line(34,29,57,29,CYAN,1.5),rivet(34,33)
])
# 04 / Shotgun: paired long tubes, ribbed sliding pump, traditional solid stock.
guns.append([
 p('M5 29L28 25 38 30 35 38 23 38 9 48 5 43 13 35',DARK),
 p('M30 25L62 24 67 28 64 37 36 38'),
 rect(61,25,57,7,MID),rect(58,33,52,5,DARK),
 rect(76,29,24,13),vent(80,32,4),line(80,40,98,40,CYAN,1.6),
 p('M42 38L53 37 55 43 47 47 40 43',DARK),line(47,39,47,43,LIGHT,1.1),
 rect(111,24,8,9,DARK),line(116,26,116,31,LIGHT,1.3),
 line(37,28,56,28,CYAN,2),line(68,24,108,24,LIGHT,1),rivet(37,33)
])
# 05 / Machine gun: thick ventilated jacket, ammunition box and bipod.
guns.append([
 p('M5 26L25 24 31 28 28 37 16 37 6 43',DARK),
 p('M27 23L70 22 77 26 74 39 31 39'),
 rect(72,25,42,11),rect(110,25,12,11,DARK),
 p('M42 38L69 38 70 55 46 55 41 49',MID),
 p('M46 42L63 42 65 51 49 51',DARK),line(48,45,62,45,CYAN,1.6),
 p('M30 39L41 39 38 49 29 47',DARK),
 p('M69 35L76 37 75 41 68 41',MID),
 line(95,36,88,53,MID,2.2),line(96,36,106,52,MID,2.2),
 optic(40,14,20),vent(79,27,6),line(30,28,64,28,CYAN,2),
 rect(29,19,6,4,DARK),rivet(36,34),rivet(67,32)
])
# 06 / Sniper: extremely long fluted barrel and a large long-range optic.
guns.append([
 p('M5 26L31 24 36 28 31 36 19 36 8 45 4 40 13 32',DARK),
 p('M30 25L70 24 74 29 69 35 36 37'),
 p('M35 24L70 24 68 27 36 29',LIGHT),
 rect(70,27,40,4,MID),rect(109,24,15,9,DARK),vent(114,26,2),
 p('M43 36L53 36 51 47 42 47',MID),
 p('M32 36L41 37 38 47 29 45',DARK),
 optic(37,14,38),rect(33,12,10,9),rect(72,12,10,9),
 line(78,14,78,19,CYAN,2),line(43,17,69,17,LIGHT,1),
 line(88,32,83,47,MID,1.8),line(88,32,97,47,MID,1.8),
 line(40,30,62,30,CYAN,1.6),rivet(35,32)
])
# 07 / Flamethrower: large fuel cylinder, conduit and a protected nozzle cage.
guns.append([
 p('M8 28L28 24 35 29 30 39 15 41 8 36',DARK),
 p('M28 23L69 23 79 30 73 40 31 39'),
 rect(70,27,30,9,MID),
 p('M96 24L116 25 121 31 117 38 97 39 101 33',DARK),
 line(103,27,115,28,LIGHT,1.2),line(105,35,115,35,LIGHT,1.2),
 p('M42 38L49 40 46 50 37 48',DARK),
 rect(51,38,18,19,DARK,7),rect(55,41,10,12,'#9d7553',3),
 line(58,43,58,49,'#ffc880',2),
 '<path d="M61 38C64 50 83 52 87 37" fill="none" stroke="#536c7d" stroke-width="4"/>',
 line(36,28,64,28,CYAN,2),vent(77,29,3),rivet(34,33),rect(66,19,6,4,DARK)
])
# 08 / Grenade launcher: wide drum and stubby reinforced barrel.
guns.append([
 p('M7 25L29 22 34 28 30 38 16 39 7 46 5 40 13 33',DARK),
 p('M28 23L76 23 86 28 80 37 32 38'),
 rect(77,23,35,15),rect(108,21,13,19,DARK),
 line(116,25,116,36,CYAN,2),
 circle(62,40,15,DARK),circle(62,40,10,MID),circle(62,40,4,DARK),
 line(54,35,57,32,LIGHT,1.3),line(68,33,71,37,LIGHT,1.3),line(57,49,62,50,CYAN,1.6),
 p('M33 37L43 38 38 50 28 47',DARK),grip(31,40),
 optic(39,15,20),line(35,28,70,28,CYAN,2),vent(85,26,4),rivet(33,33)
])
# 09 / Rocket launcher: shoulder tube, massive muzzle and sighted firing grip.
guns.append([
 p('M8 20L20 17 111 17 120 23 120 36 111 41 20 41 8 36',DARK),
 p('M19 21L105 21 113 25 113 34 105 37 19 37'),
 p('M25 21L103 21 107 24 25 25',LIGHT),
 rect(7,19,15,21,MID),rect(108,16,12,27,DARK),
 line(113,21,113,37,CYAN,2.5),
 p('M47 39L60 39 56 55 45 52',DARK),grip(48,42),
 p('M63 40L73 40 73 48 64 48 61 44',MID),
 rect(67,10,17,8,DARK),rect(78,5,7,11,MID),
 line(81,7,81,11,CYAN,2),
 line(31,29,84,29,CYAN,2),vent(91,26,3),rivet(26,34),rivet(102,33)
])
# 10 / Laser: slender accelerator rail, exposed focusing lenses and energy cell.
guns.append([
 p('M7 25L28 22 34 27 31 36 17 38 7 44',DARK),
 p('M29 23L66 21 74 25 70 38 34 39'),
 p('M69 24L111 24 119 28 119 32 111 36 69 36',DARK),
 line(73,28,115,28,CYAN,2.5),line(73,33,111,33,LIGHT,1.1),
 rect(80,22,4,16,MID),rect(96,22,4,16,MID),
 circle(115,30,5,CYAN),circle(115,30,2,LIGHT),
 p('M48 37L61 37 63 53 52 55 47 49',MID),
 line(54,41,57,49,CYAN,2.3),
 p('M34 38L44 39 40 50 30 46',DARK),
 optic(42,14,23),line(34,27,64,25,CYAN,2),rivet(35,33)
])
# 11 / Plasma: bulbous containment chamber, heavy emitter fork and ion bottle.
guns.append([
 p('M8 27L27 22 35 26 32 39 16 40 9 45 6 39 15 32',DARK),
 p('M28 23L68 20 80 25 82 36 69 42 33 39'),
 p('M65 24L88 24 96 28 96 35 85 40 65 38',DARK),
 circle(77,31,11,MID),circle(77,31,7,'#9f8af6'),circle(77,31,3,LIGHT),
 p('M94 24L114 21 121 25 117 29 104 29 104 34 117 34 121 38 114 42 94 38'),
 line(103,25,115,24,CYAN,2),line(104,38,115,39,CYAN,2),
 p('M45 39L57 40 54 54 42 51',DARK),grip(45,42),
 rect(60,42,10,13,DARK,3),line(65,45,65,51,CYAN,2),
 optic(39,14,23),line(34,28,58,26,CYAN,2),rivet(34,34),
 '<path d="M83 22A12 12 0 0 1 88 39" fill="none" stroke="#70edee" stroke-width="1.7"/>'
])

def document(parts):
 return '''<svg xmlns="http://www.w3.org/2000/svg" width="128" height="64" viewBox="0 0 128 64">
<defs><linearGradient id="steel" x1="0" y1="0" x2="0.18" y2="1"><stop stop-color="#abc3d3"/><stop offset="0.42" stop-color="#536f87"/><stop offset="1" stop-color="#2b435b"/></linearGradient><linearGradient id="dark" x1="0" y1="0" x2="0" y2="1"><stop stop-color="#33485c"/><stop offset="1" stop-color="#13283b"/></linearGradient></defs>
'''+''.join(parts)+'</svg>\n'

for i,parts in enumerate(guns):
 (OUT/f'{i}.svg').write_text(document(parts))
lock=[
 '<path d="M51 29V20C51 3 77 3 77 20V29" fill="none" stroke="#172b40" stroke-width="10"/>',
 '<path d="M51 28V20C51 3 77 3 77 20V28" fill="none" stroke="#91a6ba" stroke-width="5"/>',
 p('M46 26L82 26 87 31 87 52 82 57 46 57 41 52 41 31',DARK),
 line(48,29,79,29,LIGHT,1),circle(64,40,4,'#ffc880'),
 p('M62 42L66 42 67 49 61 49','#ffc880'),rivet(47,51),rivet(81,51)
]
(OUT/'lock.svg').write_text(document(lock))
print(f'Generated {len(guns)} original weapon icons and lock at {OUT}')
