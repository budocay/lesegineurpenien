extends RefCounted
## Un participant à un combat, allié ou ennemi. Pur état : aucune image, aucun nœud.

const Rules = preload("res://src/battle/rules.gd")

var key: String = ""          # identifiant unique dans le combat (« limace_molle#2 »)
var source: String = ""       # identifiant dans characters.json ou enemies.json
var name: String = ""
var side: String = "party"    # "party" ou "enemy"
var level: int = 1
var base: Dictionary = {}     # hp, mp, atk, def, mag, res, spd
var hp: int = 1
var mp: int = 0
var skills: Array = []
var statuses: Dictionary = {} # id -> {"turns": int, "fresh": bool}
var weak: Array = []
var immune: Array = []
var shield: int = 0
var shield_max: int = 0
var defending: bool = false
var wait: float = 0.0         # temps restant avant son prochain tour
var element: String = "contondant"
var attack_name: String = "Attaque"
var attack_anim: String = ""  # animation de l'attaque de base (data/animations.json)
var ai: Array = []
var sprite: Dictionary = {}
var data: Dictionary = {}
var xp: int = 0
var money: int = 0
var drops: Array = []
var firm: bool = false      # un objet porté le rend insensible au Ramollissement
var passives: Dictionary = {} # effets permanents des talents (voir FORMAT_DONNEES.md)
var robbed: bool = false    # ses poches ont déjà été faites pendant ce combat


func max_hp() -> int:
	return maxi(1, int(base.get("hp", 1)))


func max_mp() -> int:
	return maxi(0, int(base.get("mp", 0)))


func alive() -> bool:
	return hp > 0


func has_status(id: String) -> bool:
	return statuses.has(id)


## Caractéristique effective, états compris.
func stat(stat_key: String) -> float:
	var v := float(base.get(stat_key, Rules.EXTRA_DEFAULTS.get(stat_key, 0)))
	for id: String in statuses:
		var mods: Variant = Database.get_status(id).get("mods")
		if mods is Dictionary:
			v *= float((mods as Dictionary).get(stat_key, 1.0))
	return v


func speed() -> float:
	return maxf(1.0, stat("spd"))


## Nom de l'état qui lui fait passer son tour, ou "" s'il peut agir.
func skipping_status() -> String:
	for id: String in statuses:
		if bool(Database.get_status(id).get("skip", false)):
			return id
	return ""


## Vrai si le Ramollissement n'a pas prise sur ses coups (objet porté ou état).
func is_firm() -> bool:
	if firm:
		return true
	for id: String in statuses:
		if bool(Database.get_status(id).get("firm", false)):
			return true
	return false


## Valeur d'un effet permanent de talent. Avec « sub », lit une entrée d'un effet à
## plusieurs valeurs : passive("element_boost", "feu").
func passive(passive_key: String, sub: String = "") -> float:
	var v: Variant = passives.get(passive_key)
	if v is Dictionary:
		return float((v as Dictionary).get(sub, 0.0))
	if sub != "" or v == null or v is Array:
		return 0.0
	return float(v)


## Plus forte valeur d'un réglage parmi ses états ("evade", "taunt"...) ; 0 si aucun.
func status_value(flag: String) -> float:
	var best := 0.0
	for id: String in statuses:
		var raw: Variant = Database.get_status(id).get(flag)
		if raw is bool:
			best = maxf(best, 1.0 if raw else 0.0)
		elif raw is float or raw is int:
			best = maxf(best, float(raw))
	return best


## Vrai s'il subit au moins un état négatif.
func afflicted() -> bool:
	for id: String in statuses:
		if bool(Database.get_status(id).get("negative", false)):
			return true
	return false


## Multiplicateur des dégâts reçus (Ébranlé, etc.).
func vulnerability() -> float:
	var v := 1.0
	for id: String in statuses:
		v *= float(Database.get_status(id).get("vulnerable", 1.0))
	return v
