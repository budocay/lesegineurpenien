extends Node
## Mesure de fluidité, À LANCER AVEC FENÊTRE (le rendu doit tourner) :
##   GLAN_ONLY_PERF=1 Godot --path . res://tests/smoke_test.tscn
## Pour chaque carte et chaque combat de la liste, mesure à la première entrée (« froid » : textures
## et pipelines pas encore vus dans ce processus) puis à la seconde (« chaud ») :
##   total    : durée entre la demande et la fin de l'arrivée (fondus fixes de 0,8 s compris)
##   noir     : durée passée sous le fondu noir complet (le vrai coût de la construction)
##   pire     : pire image pendant tout le changement ; visible : pire image HORS fondu noir complet
##   script   : construction du décor par MapBuilder ; horiz : Horizon ; peint : temps de peinture
##              d'images par code (Sprites) ; reste : joueur, PNJ, caméra.
## Variables : GLAN_PERF_MAPS=a,b,c (cartes), GLAN_PERF_OUT=fichier.json (écrit les chiffres).
## Pour un vrai « froid », lancer avec un autre HOME (caches disque et de shaders vides) :
##   HOME=/tmp/perfhome GLAN_ONLY_PERF=1 Godot --path . res://tests/smoke_test.tscn

const MAIN = preload("res://scenes/main.tscn")
const DEFAULT_MAPS := ["bittebourg", "brie", "fondue_combe", "morbier_halle", "morbier_galeries", "minas_rues",
	"minas_croute", "minas_citadelle", "isengarde", "port_sale", "chutes_gratin", "poney_flagada"]

var main: Node
var _frames: Array = []   # [dt_ms, alpha]
var _last := 0


func _process(_d: float) -> void:
	var now := Time.get_ticks_usec()
	if _last != 0 and main != null:
		_frames.append([(now - _last) / 1000.0, (main._fade.color.a if main._fade != null else 0.0)])
	_last = now


func _wait(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _stats(from: int, total_ms: float, extra: Dictionary) -> Dictionary:
	var worst := 0.0
	var worst_vis := 0.0
	var black := 0.0
	for i in range(from, _frames.size()):
		var f: Array = _frames[i]
		worst = maxf(worst, f[0])
		if float(f[1]) < 0.99:
			worst_vis = maxf(worst_vis, f[0])
		else:
			black += f[0]
	var r := {"total": total_ms, "black": black, "worst": worst, "visible": worst_vis}
	r.merge(extra)
	return r


func _measure_map(id: String) -> Dictionary:
	await _wait(20)
	var from := _frames.size()
	var p0: int = Sprites.paint_usec
	var t0 := Time.get_ticks_usec()
	main.change_map(id, "")
	while main.busy or main.world == null or main.world.map_id != id:
		await get_tree().process_frame
	var total := (Time.get_ticks_usec() - t0) / 1000.0
	var w: Node = main.world
	var extra := {"builder": float(w.perf.get("builder", 0)), "horizon": float(w.perf.get("horizon", 0)),
		"rest": float(w.perf.get("rest", 0)), "paint": (Sprites.paint_usec - p0) / 1000.0}
	await _wait(20)
	if OS.has_environment("GLAN_PERF_LOG"):
		var items: Array = Sprites.paint_log.keys()
		items.sort_custom(func(a: String, b: String) -> bool: return Sprites.paint_log[a] > Sprites.paint_log[b])
		for k: String in items.slice(0, 8):
			print("      %7.0f ms  %s" % [Sprites.paint_log[k], k])
	Sprites.paint_log.clear()
	return _stats(from, total, extra)


func _measure_battle(enc: Dictionary) -> Dictionary:
	await _wait(20)
	var from := _frames.size()
	var t0 := Time.get_ticks_usec()
	await main.start_battle(enc.duplicate(true))
	var total := (Time.get_ticks_usec() - t0) / 1000.0
	await _wait(20)
	return _stats(from, total, {})


func _line(name: String, r: Dictionary) -> String:
	return "%-22s total %6.0f  noir %6.0f  pire %6.0f  visible %6.0f | builder %6.0f  horiz %6.0f  peint %6.0f  reste %5.0f" % [
		name, r.total, r.black, r.worst, r.visible, r.get("builder", 0.0), r.get("horizon", 0.0), r.get("paint", 0.0), r.get("rest", 0.0)]


func run(host: Node) -> Dictionary:
	host.add_child(self)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	SaveManager.save_path = "user://test_perf.json"
	SaveManager.delete_save()
	main = MAIN.instantiate()
	add_child(main)
	await _wait(120)
	GameState.new_game()
	GameState.playing = true
	main.mode = 2
	main.title.close()
	await _wait(20)
	var maps: Array = DEFAULT_MAPS
	if OS.has_environment("GLAN_PERF_MAPS"):
		maps = Array(OS.get_environment("GLAN_PERF_MAPS").split(","))
	var out := {}
	var Prewarm := preload("res://src/gfx/prewarm.gd")
	print("== Mesures de fluidité (ms) : première entrée (froid), seconde (chaud) ==")
	print("Préchauffage des shaders au lancement : %.0f ms (%d shaders)" % [Prewarm.last_ms, Prewarm.covered.size()])
	out["prewarm_ms"] = Prewarm.last_ms
	for pass_name in ["froid", "chaud"]:
		for id: String in maps:
			if not Database.has_map(id):
				continue
			var r := await _measure_map(id)
			out["%s:%s" % [pass_name, id]] = r
			print(_line("%s %s" % [pass_name, id], r))
	main.auto_battles = true
	var all: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/encounters.json")).get("encounters", {})
	var cases := {"normal": {"enemies": ["limace_molle"], "arena": "pre"}, "boss": all.get("chantecler", {}),
		"effets": all.get("vacherin", {})}
	for pass_name in ["froid", "chaud"]:
		for k: String in cases:
			var r := await _measure_battle(cases[k])
			out["%s:combat_%s" % [pass_name, k]] = r
			print(_line("%s combat %s" % [pass_name, k], r))
	if OS.has_environment("GLAN_PERF_OUT"):
		var f := FileAccess.open(OS.get_environment("GLAN_PERF_OUT"), FileAccess.WRITE)
		f.store_string(JSON.stringify(out, "  "))
	SaveManager.delete_save()
	queue_free()
	return out
