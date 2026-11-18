extends RefCounted
## Règles de progression communes au combat et à l'état de la partie :
## caractéristiques selon le niveau, seuils d'expérience, compétences apprises.
## Tout est lu dans data/characters.json (bloc « battle ») et data/game.json.

const STATS := ["hp", "mp", "atk", "def", "mag", "res", "spd"]
const MAX_LEVEL := 50


## Fiche de combat d'un personnage jouable ({} s'il n'en a pas).
static func battle_def(character_id: String) -> Dictionary:
	var b: Variant = Database.get_character(character_id).get("battle", {})
	if b is Dictionary:
		return b
	return {}


## Caractéristiques d'un personnage à un niveau donné.
static func stats_at(character_id: String, level: int) -> Dictionary:
	var def := battle_def(character_id)
	var base: Dictionary = def.get("base", {})
	var growth: Dictionary = def.get("growth", {})
	var out := {}
	for key: String in STATS:
		out[key] = int(round(float(base.get(key, 1)) + float(growth.get(key, 0)) * float(level - 1)))
	out["hp"] = maxi(1, int(out["hp"]))
	out["spd"] = maxi(1, int(out["spd"]))
	return out


## Expérience nécessaire pour passer du niveau donné au suivant.
static func xp_to_next(level: int) -> int:
	var prog: Dictionary = Database.game.get("progression", {})
	var base := float(prog.get("xp_base", 16.0))
	var power := float(prog.get("xp_power", 1.5))
	return maxi(1, int(round(base * pow(float(level), power))))


## Compétences connues à un niveau donné, dans l'ordre d'apprentissage.
static func skills_at(character_id: String, level: int) -> Array:
	var learn: Dictionary = battle_def(character_id).get("learn", {})
	var levels: Array = []
	for key: String in learn:
		levels.append(int(key))
	levels.sort()
	var out: Array = []
	for lv: int in levels:
		if lv > level:
			break
		var list: Variant = learn.get(str(lv), [])
		if list is Array:
			for s: Variant in list:
				if not out.has(str(s)):
					out.append(str(s))
	return out


## Compétences apprises exactement en atteignant ce niveau.
static func skills_learned_at(character_id: String, level: int) -> Array:
	var learn: Dictionary = battle_def(character_id).get("learn", {})
	var list: Variant = learn.get(str(level), [])
	var out: Array = []
	if list is Array:
		for s: Variant in list:
			out.append(str(s))
	return out


# ------------------------------------------------------------------- talents
# Tout est lu dans data/talents.json : deux branches par personnage, chacune une
# suite de talents à apprendre dans l'ordre.

## Points de talent gagnés en tout à un niveau donné (aucun au niveau 1).
static func talent_points_at(level: int) -> int:
	var prog: Dictionary = Database.game.get("progression", {})
	return maxi(0, level - 1) * maxi(0, int(prog.get("talent_points_per_level", 1)))


## Les branches de talents d'un personnage (liste de dictionnaires).
static func branches(character_id: String) -> Array:
	var out: Array = []
	var list: Variant = Database.get_talents(character_id).get("branches", [])
	if list is Array:
		for b: Variant in list:
			if b is Dictionary:
				out.append(b)
	return out


## Les talents d'une branche, dans l'ordre où ils s'apprennent.
static func branch_talents(branch: Dictionary) -> Array:
	var out: Array = []
	var list: Variant = branch.get("talents", [])
	if list is Array:
		for t: Variant in list:
			if t is Dictionary:
				out.append(t)
	return out


## Fiche d'un talent ({} s'il n'existe pas pour ce personnage).
static func talent_def(character_id: String, talent_id: String) -> Dictionary:
	for b: Dictionary in branches(character_id):
		for t: Dictionary in branch_talents(b):
			if str(t.get("id", "")) == talent_id:
				return t
	return {}


## Talent qu'il faut connaître avant celui-ci (le précédent de sa branche), ou "".
static func talent_requirement(character_id: String, talent_id: String) -> String:
	for b: Dictionary in branches(character_id):
		var previous := ""
		for t: Dictionary in branch_talents(b):
			if str(t.get("id", "")) == talent_id:
				return previous
			previous = str(t.get("id", ""))
	return ""


static func talent_cost(def: Dictionary) -> int:
	return maxi(1, int(def.get("cost", 1)))
