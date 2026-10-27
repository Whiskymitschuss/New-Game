class_name Content
extends RefCounted

const WORLDS = ["Verlassene Stadt", "Dunkler Wald", "Militärbasis", "Kanalisation", "Forschungslabor", "Verseuchte Wüste", "Gefrorenes Ödland", "Brennende Metropole", "Mutantenfestung", "Endzeit-Zone"]
const COLORS = ["273c51", "254739", "394b42", "244448", "344362", "70503a", "3d6077", "663b42", "4d3d66", "433c50"]
const BOSSES = ["Der Schrotthüter", "Dornenmutter", "General Rost", "Der Schlund", "Projekt NULL", "Sandbrecher", "Frostkönigin", "Aschekoloss", "Die Vielstimmige", "DEADWAVE PRIME"]
const BOSS_ATTACKS = ["SCHROTTSCHLAG", "DORNENBRUT", "SALVENFEUER", "MUNITIONSRAUB", "REKONSTRUKTION", "SANDSTURM", "KRYOWELLE", "ASCHEBRAND", "MUTANTENKLON", "EMP-KASKADE"]
const MULTIPLIERS = [2,3,4,5,10,15,20,25,35,50,100]
const CLASSES = [
 {"name":"Soldat", "desc":"Präzision · +25% Schaden", "hp":120.0, "damage":1.25, "regen":0.3, "ammo":45},
 {"name":"Techniker", "desc":"Drohne · Energie regeneriert schneller", "hp":105.0, "damage":1.0, "regen":0.5, "ammo":35},
 {"name":"Überlebender", "desc":"Vitalität · starke Regeneration", "hp":165.0, "damage":0.95, "regen":2.0, "ammo":30}]
# damage, interval, reload, magazine, range, effect, unlock level
const WEAPONS = [
 ["Pistole",12.0,0.52,1.0,12,310.0,"bullet",1],
 ["Revolver",30.0,0.85,1.4,6,480.0,"bullet",2],
 ["Maschinenpistole",9.0,0.18,1.5,28,350.0,"bullet",4],
 ["Sturmgewehr",16.0,0.25,1.6,24,480.0,"bullet",7],
 ["Schrotflinte",42.0,1.0,1.8,6,260.0,"spread",10],
 ["Maschinengewehr",13.0,0.12,2.6,60,450.0,"bullet",15],
 ["Scharfschützengewehr",95.0,1.7,2.0,5,600.0,"pierce",20],
 ["Flammenwerfer",9.0,0.16,2.0,35,200.0,"fire",30],
 ["Granatwerfer",65.0,1.2,2.1,5,450.0,"blast",40],
 ["Raketenwerfer",130.0,2.0,2.8,3,600.0,"blast",50],
 ["Lasergewehr",24.0,0.23,1.7,25,600.0,"laser",70],
 ["Plasmakanone",85.0,0.7,2.5,8,600.0,"plasma",90]]
const RARITIES = ["Gewöhnlich", "Ungewöhnlich", "Selten", "Episch", "Legendär", "Mythisch"]
# name, health, speed, contact damage, silhouette, reward
const ENEMIES = [
 ["Streuner",28.0,17.0,5.0,"walker",4], ["Sprinter",20.0,36.0,4.0,"runner",5],
 ["Panzer",70.0,12.0,8.0,"armor",8], ["Infizierter Soldat",45.0,21.0,7.0,"soldier",7],
 ["Seuchenhund",24.0,43.0,5.0,"dog",6], ["Giftträger",42.0,17.0,6.0,"poison",8],
 ["Splitterbauch",35.0,25.0,14.0,"exploder",8], ["Mutant",90.0,18.0,10.0,"mutant",12],
 ["Kriecher",22.0,24.0,4.0,"crawler",5], ["Riese",160.0,10.0,16.0,"giant",18],
 ["Eissplitter",80.0,18.0,9.0,"ice",12], ["Brandmutant",65.0,26.0,11.0,"fire",12],
 ["Schütze",40.0,15.0,6.0,"ranged",9], ["Wachdrohne",85.0,23.0,9.0,"robot",14],
 ["Elite",120.0,32.0,13.0,"elite",18]]
# All cards mutate stats consumed by combat / collection / progression.
const UPGRADES = [
 ["Panzerherz","+50% Maximalleben","max_hp",0.5], ["Schnellfeuer","+20% Feuerrate","speed",0.2],
 ["Großkaliber","+30% Schaden","damage",0.3], ["Adlerauge","+15% kritische Chance","crit",0.15],
 ["Durchschlag","Ein weiteres Ziel","pierce",1.0], ["Doppellauf","Ein Zusatzprojektil","multishot",1.0],
 ["Toxin","Gift pro Sekunde","poison",4.0], ["Brandmunition","Brennende Treffer","burn",5.0],
 ["Drohnenruf","Autonome Unterstützung","drone",1.0], ["Erste Hilfe","Heilt 45 Leben","heal",45.0],
 ["Nachschub","+90 Munition","ammo",90.0], ["Energieschild","+35 Schildpunkte","shield",35.0],
 ["Kryomunition","Verlangsamt Gegner","slow",0.15], ["Stahlhaut","+3 Rüstung","armor",3.0],
 ["Ausweichrolle","+8% Ausweichen","dodge",0.08], ["Zelltherapie","+1 Regeneration/s","regen",1.0],
 ["Batterie","+20 Spezialenergie","energy",20.0], ["Rückgewinnung","20% Munitionsrückgabe","recycle",0.2],
 ["Splitterladung","+20 Flächenschaden","splash",20.0], ["Vampirgeschoss","+2 Heilung pro Abschuss","leech",2.0],
 ["Kopfgeld","+25% Münzbelohnung","bounty",0.25], ["Lernkurve","+25% Erfahrung","wisdom",0.25],
 ["Vorratstasche","+250 Munitionskapazität","capacity",250.0], ["Großer Abwurf","+4 Startkugeln","drop",4.0],
 ["Reservekanister","Ein weiterer Abwurf","attempt",1.0], ["Sammelmagnet","+25% gesammelte Munition","collection",0.25],
 ["Schnellwechsel","20% kürzeres Nachladen","reload",0.2], ["Großes Magazin","+6 Magazingröße","magazine",6.0],
 ["Hohlspitz","+50% kritischer Schaden","crit_damage",0.5], ["Notfallpanzer","+60 Schildpunkte","shield",60.0],
 ["Überladung","+50% Spezialschaden","special",0.5], ["Solarmodul","+2 Energie/s","energy_regen",2.0],
 ["Langlauf","+90 Reichweite","range",90.0], ["Dornenrüstung","+8 Kontaktschaden","thorns",8.0],
 ["Störsignal","+5% Verlangsamung","slow",0.05], ["Feldration","+25 Leben und Heilung","vitality",25.0],
 ["Scharfe Kanten","+15% Schaden","damage",0.15], ["Servoarm","+10% Feuerrate","speed",0.1],
 ["Kühlkörper","10% kürzeres Nachladen","reload",0.1], ["Bergung","+35 Munition und Münzen","salvage",35.0],
 ["Präzisionsoptik","+7% kritische Chance","crit",0.07], ["Schutzfeld","+15 Schild und Regeneration","field",15.0],
 ["Soldat: Feuerdisziplin","+35% Feuerrate","speed",0.35,0],
 ["Soldat: Panzerbrecher","Zwei weitere Ziele","pierce",2.0,0],
 ["Techniker: Schwarm","Zwei weitere Drohnen","drone",2.0,1],
 ["Techniker: Reaktor","+4 Energie pro Sekunde","energy_regen",4.0,1],
 ["Überlebender: Genesung","+3 Regeneration pro Sekunde","regen",3.0,2],
 ["Überlebender: Zweite Haut","+6 Rüstung","armor",6.0,2]]
# Thirty actual combinations: each type has three geometry/strength variants.
static func modules() -> Array:
 var result: Array = []
 for kind in ["ramp", "peg", "rotor", "wall", "portal", "boost", "bonus", "trapdoor", "reverse", "breakable"]:
  for variant in range(3):
   result.append({"kind":kind,"variant":variant,"id":result.size()})
 return result

static func level_data(number: int) -> Dictionary:
 var rng := RandomNumberGenerator.new()
 var seed_value := 734219 + number * 104729
 rng.seed = seed_value
 var world := clampi((number-1)/10,0,9)
 var gates: Array = []
 for row in range(3):
  var left := 2 + rng.randi_range(0,mini(3+world,10))
  var right := 2 + rng.randi_range(0,mini(3+world,10))
  gates.append({"y":560+row*105,"left":MULTIPLIERS[mini(left-2,10)],"right":MULTIPLIERS[mini(right-2,10)],"moving":number>=12 and row==1})
 if number<=3:
  gates = [{"y":560,"left":2,"right":3,"moving":false},{"y":665,"left":2,"right":2,"moving":false},{"y":770,"left":2,"right":3,"moving":false}]
 var pieces: Array = []
 var catalog := modules()
 for i in range(3 if number<50 else 5):
  var pick := rng.randi_range(0,mini(29,5+number))
  var item: Dictionary = catalog[pick].duplicate()
  item["x"] = rng.randf_range(100,440)
  item["y"] = 605 + (i%3)*98 + rng.randf_range(-12,12)
  pieces.append(item)
 return {"number":number,"seed":seed_value,"world":world,"waves":clampi(5+(number-1)/10,5,15),"gates":gates,"pieces":pieces,"boss":number%10==0}

static func wave_enemy_count(number: int,wave: int) -> int:
 return clampi(12+wave*3+(number-1)/3,15,90)

static func ammo_capacity(number: int) -> int:
 return 240+clampi(number,1,100)*8

static func wave_gates(number: int,wave: int,original: Array) -> Array:
 var result=original.duplicate(true)
 var plans=[[[2,1],[1,3],[2,2]],[[1,3],[3,1],[2,2]],[[3,1],[2,2],[1,3]],[[2,2],[1,3],[3,1]],[[1,2],[2,1],[3,3]]]
 var phase=posmod(wave-1+(number-1)%3,plans.size())
 var plan=plans[phase]
 for row in range(result.size()):
  result[row]["left"]=plan[row][0]
  result[row]["right"]=plan[row][1]
 # Later worlds introduce larger single gates, balanced by neutral downstream lanes.
 if number>=10:
  var strongest=MULTIPLIERS[mini(10,1+(number-1)/10)]
  var selected=(wave+number)%3
  var side="left" if wave%2==0 else "right"
  for row in range(result.size()):
   result[row][side]=strongest if row==selected else 1
 return result
