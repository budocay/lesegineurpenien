extends Node
## Charge tout le CONTENU du jeu depuis res://data (fichiers JSON).
## Le moteur ne contient aucun texte ni aucune carte : ajouter un chapitre,
## c'est ajouter des fichiers dans data/.

const DATA_DIR := "res://data/"

var game: Dictionary = {}
var characters: Dictionary = {}
var ambiances: Dictionary = {}
var dialogues: Dictionary = {}
var elements: Dictionary = {}
var statuses: Dictionary = {}
var skills: Dictionary = {}
var items: Dictionary = {}
var enemies: Dictionary = {}
var encounters: Dictionary = {}
var encounter_tables: Dictionary = {}
var arenas: Dictionary = {}
var quests: Dictionary = {}
var shops: Dictionary = {}
var talents: Dictionary = {}
var animations: Dictionary = {}
var _maps: Dictionary = {}


func _ready() -> void:
	reload()


func reload() -> void:
	game = load_json(DATA_DIR + "game.json")
	characters = load_json(DATA_DIR + "characters.json")
	ambiances = load_json(DATA_DIR + "ambiances.json")
	elements = load_json(DATA_DIR + "elements.json")
	statuses = load_json(DATA_DIR + "statuses.json")
	skills = load_json(DATA_DIR + "skills.json")
	items = load_json(DATA_DIR + "items.json")
	enemies = load_json(DATA_DIR + "enemies.json")
	arenas = load_json(DATA_DIR + "arenas.json")
	quests = load_json(DATA_DIR + "quests.json")
	shops = load_json(DATA_DIR + "shops.json")
	talents = load_json(DATA_DIR + "talents.json")
	animations = load_json(DATA_DIR + "animations.json")
	var enc := load_json(DATA_DIR + "encounters.json")
	encounters = _section(enc, "encounters")
	encounter_tables = _section(enc, "tables")
	dialogues = {}
	_maps = {}
	for file in list_files(DATA_DIR + "dialogues"):
		var chunk := load_json(DATA_DIR + "dialogues/" + file)
		for key: String in chunk:
			if dialogues.has(key):
				push_warning("Dialogue en double : %s (%s)" % [key, file])
			dialogues[key] = chunk[key]


func list_files(dir_path: String, extension: String = "json") -> Array[String]:
	var out: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return out
	for f in dir.get_files():
		if f.get_extension() == extension:
			out.append(f)
	out.sort()
	return out


func list_maps() -> Array[String]:
	var out: Array[String] = []
	for f in list_files(DATA_DIR + "maps"):
		out.append(f.get_basename())
	return out


func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("Fichier de données introuvable : " + path)
		return {}
	var text := FileAccess.get_file_as_string(path)
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("JSON invalide dans %s, ligne %d : %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	if not (json.data is Dictionary):
		push_error("Le fichier %s doit contenir un objet JSON." % path)
		return {}
	return json.data


func has_map(id: String) -> bool:
	return FileAccess.file_exists(DATA_DIR + "maps/" + id + ".json")


func get_map(id: String) -> Dictionary:
	if not _maps.has(id):
		_maps[id] = load_json(DATA_DIR + "maps/" + id + ".json")
	return _maps[id]


func get_character(id: String) -> Dictionary:
	var c: Variant = characters.get(id, {})
	if c is Dictionary:
		return c
	return {}


func get_character_name(id: String) -> String:
	return str(get_character(id).get("name", id))


func get_ambiance(id: String) -> Dictionary:
	var a: Variant = ambiances.get(id, {})
	if a is Dictionary:
		return a
	push_warning("Ambiance inconnue : " + id)
	return {}


func has_dialogue(id: String) -> bool:
	return dialogues.has(id)


func get_dialogue(id: String) -> Array:
	var d: Variant = dialogues.get(id, [])
	if d is Array:
		return d
	return []


static func _section(d: Dictionary, key: String) -> Dictionary:
	var v: Variant = d.get(key, {})
	if v is Dictionary:
		return v
	return {}


func _entry(table: Dictionary, id: String) -> Dictionary:
	var v: Variant = table.get(id, {})
	if v is Dictionary:
		return v
	return {}


func get_element(id: String) -> Dictionary:
	return _entry(elements, id)


func get_status(id: String) -> Dictionary:
	return _entry(statuses, id)


## Animation de combat (data/animations.json), vide si elle n'existe pas.
func get_animation(id: String) -> Dictionary:
	return _entry(animations, id)


func get_skill(id: String) -> Dictionary:
	return _entry(skills, id)


func get_item(id: String) -> Dictionary:
	return _entry(items, id)


func get_quest(id: String) -> Dictionary:
	return _entry(quests, id)


func get_shop(id: String) -> Dictionary:
	return _entry(shops, id)


## Arbre de talents d'un personnage : {"branches": [...]} ({} s'il n'en a pas).
func get_talents(character_id: String) -> Dictionary:
	return _entry(talents, character_id)


## Genre d'un objet : "consumable" (par défaut), "equipment" ou "key" (objet de quête).
func item_kind(id: String) -> String:
	return str(get_item(id).get("kind", "consumable"))


## Vrai pour un objet utilisable en combat (il a des effets).
func is_consumable(id: String) -> bool:
	var fx: Variant = get_item(id).get("effects")
	return fx is Array and not (fx as Array).is_empty()


## Force du Ramollissement sur une carte : part des dégâts physiques perdue (0 = aucun).
func softness(map: Dictionary) -> float:
	return clampf(float(map.get("ramollissement", 0.0)), 0.0, 0.9)


func get_enemy(id: String) -> Dictionary:
	return _entry(enemies, id)


func get_encounter(id: String) -> Dictionary:
	return _entry(encounters, id)


func get_arena(id: String) -> Dictionary:
	return _entry(arenas, id)


## Tire une rencontre dans une table, selon les poids et la taille de l'équipe.
func roll_encounter(table_id: String, party_size: int) -> Dictionary:
	var table := _entry(encounter_tables, table_id)
	var groups: Array = []
	var total := 0.0
	for g: Variant in table.get("groups", []):
		if not (g is Dictionary):
			continue
		if party_size < int(g.get("min_party", 1)) or party_size > int(g.get("max_party", 99)):
			continue
		groups.append(g)
		total += float(g.get("weight", 1))
	if groups.is_empty():
		return {}
	var roll := randf() * total
	var pick: Dictionary = groups[0]
	for g: Dictionary in groups:
		roll -= float(g.get("weight", 1))
		if roll <= 0.0:
			pick = g
			break
	var out := pick.duplicate(true)
	if not out.has("arena"):
		out["arena"] = str(table.get("arena", ""))
	return out


static func color(value: Variant, fallback: Color = Color.WHITE) -> Color:
	if value is String:
		return Color.from_string(value, fallback)
	return fallback
