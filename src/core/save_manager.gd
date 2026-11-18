extends Node
## Sauvegarde et chargement : plusieurs emplacements JSON dans le dossier utilisateur.
## Le contenu vient entièrement de GameState. Format détaillé : docs/FORMAT_DONNEES.md.
##
## Tous les fichiers dérivent de `save_path` (user://sauvegarde.json par défaut) :
##   <dossier>/<nom>_m1.json ... _m8.json   emplacements manuels (identifiants « m1 »...)
##   <dossier>/<nom>_a1.json ... _a3.json   sauvegardes automatiques tournantes (« a1 » = la plus récente)
## Le fichier `save_path` lui-même est l'ancienne sauvegarde unique : il est migré tout seul
## vers un emplacement manuel. Changer `save_path` isole donc tous les fichiers (c'est ce que
## font les tests).

signal before_save   # laisse le monde recopier la position du joueur dans GameState
signal saved

const MANUAL_SLOTS := 8
const AUTO_SLOTS := 3

var save_path: String = "user://sauvegarde.json"
var current_slot: String = ""   # dernier emplacement manuel utilisé (sauvegarde rapide)


# ------------------------------------------------------------------ chemins

func manual_ids() -> Array:
	var out: Array = []
	for i in MANUAL_SLOTS:
		out.append("m%d" % (i + 1))
	return out


func auto_ids() -> Array:
	var out: Array = []
	for i in AUTO_SLOTS:
		out.append("a%d" % (i + 1))
	return out


func is_valid_id(id: String) -> bool:
	return id in manual_ids() or id in auto_ids()


func slot_path(id: String) -> String:
	return "%s/%s_%s.json" % [save_path.get_base_dir(), save_path.get_file().get_basename(), id]


func slot_label(id: String) -> String:
	if id.begins_with("m"):
		return "Emplacement %s" % id.substr(1)
	return "Automatique %s" % id.substr(1)


# ------------------------------------------------------------------ lecture

## Lit un fichier de sauvegarde ; vide s'il est absent, illisible ou d'une carte inconnue.
func _read_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	if not (json.data is Dictionary):
		return {}
	var d: Dictionary = json.data
	var map_id := str(d.get("map_id", ""))
	if map_id == "" or not Database.has_map(map_id):
		return {}
	return d


## Reprend l'ancienne sauvegarde unique (fichier `save_path`) dans un emplacement manuel libre.
func _migrate_legacy() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var d := _read_file(save_path)
	if d.is_empty():
		return   # illisible : laissé tel quel, ignoré
	for id: String in manual_ids():
		if not FileAccess.file_exists(slot_path(id)):
			if _write_file(slot_path(id), d):
				DirAccess.remove_absolute(save_path)
			return
	# plus de place : on garde le fichier d'origine pour ne rien perdre


func read_slot(id: String) -> Dictionary:
	if not is_valid_id(id):
		return {}
	_migrate_legacy()
	return _read_file(slot_path(id))


## Instant de la sauvegarde (secondes Unix), pour trier du plus récent au plus ancien.
func _stamp(d: Dictionary) -> float:
	if d.has("saved_unix"):
		return float(d["saved_unix"])
	var s := str(d.get("saved_at", ""))
	return float(Time.get_unix_time_from_datetime_string(s)) if s != "" else 0.0


## Tous les emplacements à afficher : les 8 manuels (vides compris), puis les automatiques
## existantes. Chaque entrée : id, kind ("manual"/"auto"), empty, et si occupé : data + champs
## de résumé (map_name, chapter, quest, level, playtime, saved_at).
func list_slots(include_auto: bool = true) -> Array:
	_migrate_legacy()
	var out: Array = []
	var ids: Array = manual_ids()
	if include_auto:
		ids.append_array(auto_ids())
	for id: String in ids:
		var kind := "manual" if id.begins_with("m") else "auto"
		var d := _read_file(slot_path(id))
		if d.is_empty():
			if kind == "manual":
				out.append({"id": id, "kind": kind, "empty": true})
			continue
		var e := describe(d)
		e["id"] = id
		e["kind"] = kind
		e["empty"] = false
		e["data"] = d
		out.append(e)
	return out


## Champs affichables d'une sauvegarde lue.
func describe(d: Dictionary) -> Dictionary:
	var map := Database.get_map(str(d.get("map_id", "")))
	var quest := ""
	var quests: Variant = d.get("quests", {})
	if quests is Dictionary:
		for id: String in Database.quests:
			if str((quests as Dictionary).get(id, "")) != "active":
				continue
			var q := Database.get_quest(id)
			if quest == "" or str(q.get("kind", "")) == "principale":
				quest = str(q.get("name", id))
				if str(q.get("kind", "")) == "principale":
					break
	var levels := 0
	var count := 0
	var roster: Variant = d.get("roster", {})
	var party: Variant = d.get("party", [])
	if party is Array and roster is Dictionary:
		for id: Variant in party:
			var m: Variant = (roster as Dictionary).get(str(id), {})
			if m is Dictionary:
				levels += int((m as Dictionary).get("level", 1))
				count += 1
	var chapter := str(d.get("chapter", "chapitre_1")).replace("_", " ")
	return {
		"map_name": str(map.get("name", "?")),
		"chapter": chapter.substr(0, 1).to_upper() + chapter.substr(1),
		"quest": quest,
		"level": int(round(float(levels) / float(count))) if count > 0 else 1,
		"playtime": int(float(d.get("playtime", 0.0))),
		"saved_at": str(d.get("saved_at", "")),
		"stamp": _stamp(d),
		"auto_reason": str(d.get("auto_reason", "")),
	}


## Identifiant de l'emplacement le plus récent, ou "" s'il n'y en a aucun.
func latest_id() -> String:
	var best := ""
	var best_stamp := -1.0
	for e: Dictionary in list_slots():
		if bool(e.get("empty", false)):
			continue
		var s := float(e["stamp"])
		if s > best_stamp:
			best_stamp = s
			best = str(e["id"])
	return best


func has_save() -> bool:
	return latest_id() != ""


## Sauvegarde la plus récente (ou celle de l'emplacement `id`).
func read_save(id: String = "") -> Dictionary:
	if id == "":
		id = latest_id()
	return read_slot(id) if id != "" else {}


func load_game(id: String = "") -> bool:
	if id == "":
		id = latest_id()
	var d := read_slot(id) if id != "" else {}
	if d.is_empty():
		return false
	if not GameState.from_dict(d):
		return false
	if id.begins_with("m"):
		current_slot = id
	return true


# ------------------------------------------------------------------ écriture

func _write_file(path: String, data: Dictionary) -> bool:
	var tmp := path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_warning("Impossible d'écrire la sauvegarde : %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	if DirAccess.rename_absolute(tmp, path) != OK:
		push_warning("Impossible de finaliser la sauvegarde.")
		DirAccess.remove_absolute(tmp)
		return false
	return true


func _snapshot() -> Dictionary:
	before_save.emit()
	var data := GameState.to_dict()
	data["saved_at"] = Time.get_datetime_string_from_system(false, true)
	data["saved_unix"] = Time.get_unix_time_from_system()
	return data


## Sauvegarde manuelle dans l'emplacement `id` (« m1 »...). Sans identifiant : l'emplacement
## courant, sinon le premier libre, sinon le plus ancien (sauvegarde rapide des auberges).
func save_game(id: String = "") -> bool:
	_migrate_legacy()
	if id == "":
		id = _quick_slot()
	if not (id in manual_ids()):
		return false
	if not _write_file(slot_path(id), _snapshot()):
		return false
	current_slot = id
	saved.emit()
	return true


func _quick_slot() -> String:
	if current_slot in manual_ids():
		return current_slot
	var oldest := "m1"
	var oldest_stamp := INF
	for e: Dictionary in list_slots(false):
		if bool(e["empty"]):
			return str(e["id"])
		if float(e["stamp"]) < oldest_stamp:
			oldest_stamp = float(e["stamp"])
			oldest = str(e["id"])
	return oldest


## Sauvegarde automatique : décale les précédentes (a1 -> a2 -> a3, la plus vieille disparaît)
## puis écrit la nouvelle dans a1. `reason` : "lieu" ou "combat". `token` identifie un combat
## pour le retrouver ensuite (« Revenir avant le combat »). Renvoie l'identifiant écrit, ou "".
func autosave(reason: String, token: String = "") -> String:
	_migrate_legacy()
	var data := _snapshot()
	data["auto_reason"] = reason
	if token != "":
		data["battle_token"] = token
	var ids := auto_ids()
	var tmp := slot_path("a1") + ".new"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_warning("Impossible d'écrire la sauvegarde automatique.")
		return ""
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	for i in range(ids.size() - 1, 0, -1):
		var older: String = slot_path(ids[i])
		var newer: String = slot_path(ids[i - 1])
		if FileAccess.file_exists(newer):
			if FileAccess.file_exists(older):
				DirAccess.remove_absolute(older)
			DirAccess.rename_absolute(newer, older)
	if FileAccess.file_exists(slot_path("a1")):
		DirAccess.remove_absolute(slot_path("a1"))
	if DirAccess.rename_absolute(tmp, slot_path("a1")) != OK:
		DirAccess.remove_absolute(tmp)
		return ""
	saved.emit()
	return "a1"


## Emplacement automatique fait juste avant le combat `token`, ou "".
func find_battle_slot(token: String) -> String:
	if token == "":
		return ""
	for id: String in auto_ids():
		if str(read_slot(id).get("battle_token", "")) == token:
			return id
	return ""


# -------------------------------------------------------------- suppression

func delete_slot(id: String) -> void:
	if not is_valid_id(id):
		return
	for p: String in [slot_path(id), slot_path(id) + ".tmp", slot_path(id) + ".new"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	if current_slot == id:
		current_slot = ""


## Efface tous les emplacements (et l'ancien fichier unique). Sert surtout aux tests.
func delete_save() -> void:
	for id: String in manual_ids() + auto_ids():
		delete_slot(id)
	for p: String in [save_path, save_path + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)
	current_slot = ""


## Résumé affiché sur l'écran-titre à côté de « Continuer » (sauvegarde la plus récente).
func summary() -> String:
	var d := read_save()
	if d.is_empty():
		return ""
	var e := describe(d)
	var total := int(e["playtime"])
	return "%s  ·  %dh%02d" % [str(e["map_name"]), total / 3600, (total % 3600) / 60]
