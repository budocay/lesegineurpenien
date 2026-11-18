extends Node
## Sauvegarde et chargement : un seul fichier JSON dans le dossier utilisateur.
## Le contenu vient entièrement de GameState.

signal before_save   # laisse le monde recopier la position du joueur dans GameState
signal saved

var save_path: String = "user://sauvegarde.json"


func has_save() -> bool:
	return not read_save().is_empty()


func save_game() -> bool:
	before_save.emit()
	var data := GameState.to_dict()
	data["saved_at"] = Time.get_datetime_string_from_system(false, true)
	var tmp := save_path + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if file == null:
		push_warning("Impossible d'écrire la sauvegarde : %s" % error_string(FileAccess.get_open_error()))
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	if DirAccess.rename_absolute(tmp, save_path) != OK:
		push_warning("Impossible de finaliser la sauvegarde.")
		return false
	saved.emit()
	return true


func read_save() -> Dictionary:
	if not FileAccess.file_exists(save_path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(save_path)) != OK:
		return {}
	if not (json.data is Dictionary):
		return {}
	var d: Dictionary = json.data
	if str(d.get("map_id", "")) == "" or not Database.has_map(str(d.get("map_id", ""))):
		return {}
	return d


func load_game() -> bool:
	var d := read_save()
	if d.is_empty():
		return false
	return GameState.from_dict(d)


func delete_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)


## Résumé affiché sur l'écran-titre à côté de « Continuer ».
func summary() -> String:
	var d := read_save()
	if d.is_empty():
		return ""
	var map := Database.get_map(str(d.get("map_id", "")))
	var total := int(float(d.get("playtime", 0.0)))
	return "%s  ·  %dh%02d" % [str(map.get("name", "?")), total / 3600, (total % 3600) / 60]
