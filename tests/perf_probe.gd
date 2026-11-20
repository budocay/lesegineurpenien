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
## Variables : GLAN_PERF_MAPS=a,b,c (cartes), GLAN_PERF_OUT=fichier.json (écrit les chiffres), GLAN_PERF_IDLE=s
## (attente avant les mesures, pour laisser les fils d'arrière-plan remplir les caches), GLAN_PERF_LOG=1.
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


func _paint_usec() -> int:
	var v: Variant = Sprites.get("paint_usec")   # absent sur une copie d'avant les mesures
	return 0 if v == null else int(v)


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
	var p0: int = _paint_usec()
	var t0 := Time.get_ticks_usec()
	main.change_map(id, "")
	while main.busy or main.world == null or main.world.map_id != id:
		await get_tree().process_frame
	var total := (Time.get_ticks_usec() - t0) / 1000.0
	var w: Node = main.world
	var got := [w.npcs.size(), w.warps.size(), w.get_child_count()]   # état au moment où le fondu s'est levé
	var pf: Dictionary = w.get("perf") if w.get("perf") != null else {}   # absent sur une copie d'avant les mesures
	var extra := {"builder": float(pf.get("builder", 0)), "horizon": float(pf.get("horizon", 0)),
		"rest": float(pf.get("rest", 0)), "paint": (_paint_usec() - p0) / 1000.0}
	await _wait(20)
	if OS.has_environment("GLAN_PERF_LOG") and Sprites.get("paint_log") != null:
		var items: Array = Sprites.paint_log.keys()
		items.sort_custom(func(a: String, b: String) -> bool: return Sprites.paint_log[a] > Sprites.paint_log[b])
		for k: String in items.slice(0, 8):
			print("      %7.0f ms  %s" % [Sprites.paint_log[k], k])
	if Sprites.get("paint_log") != null:
		Sprites.paint_log.clear()
	var res := _stats(from, total, extra)
	# complétude : la carte rendue au joueur doit égaler une construction synchrone de référence
	var ref: Node3D = preload("res://src/world/world.gd").new()
	add_child(ref)
	await ref.setup(id, "")
	var want := [ref.npcs.size(), ref.warps.size(), ref.get_child_count() - 1]   # sans le joueur
	ref.queue_free()
	var same: bool = got[0] == want[0] and got[1] == want[1] and absi(int(got[2]) - 1 - int(want[2])) <= 2
	res["complete"] = same
	print("   complétude %s : personnages %d/%d, passages %d/%d, nœuds %d/%d -> %s" % [id, got[0], want[0], got[1], want[1], got[2], want[2] + 1, "OK" if same else "INCOMPLETE"])
	return res


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


## Robustesse : changements de carte enchaînés, combat lancé pendant un chargement, chargement d'une sauvegarde.
## Aucune erreur ne doit apparaître dans le journal (le test automatique ne voit que les « SCRIPT ERROR »).
func _stress() -> void:
	main.auto_battles = true
	await _wait(10)
	var ok := true
	# 1. un deuxième changement de carte pendant le premier est ignoré (busy)
	main.change_map("brie", "")
	await _wait(3)
	main.change_map("fondue_combe", "")
	main._on_encounter("inconnue")
	while main.busy or main.world == null:
		await get_tree().process_frame
	ok = ok and main.world.map_id == "brie"
	print("robustesse : deux changements de carte enchaînés -> %s" % main.world.map_id)
	# 2. un combat lancé pendant le chargement d'une carte (fondu en cours)
	main.change_map("morbier_halle", "")
	await _wait(5)
	var res: String = await main.start_battle({"enemies": ["limace_molle"], "arena": "pre"})
	while main.busy:
		await get_tree().process_frame
	print("robustesse : combat pendant un chargement -> %s, carte %s" % [res, main.world.map_id if main.world != null else "aucune"])
	# 3. sauvegarde puis chargement pendant que le monde est en place
	GameState.map_id = main.world.map_id
	SaveManager.save_game("perf_stress")
	main.continue_game("perf_stress")
	while main.busy or main.world == null:
		await get_tree().process_frame
	print("robustesse : chargement de sauvegarde -> %s (joueur %s)" % [main.world.map_id, str(main.world.player != null)])
	ok = ok and main.world.player != null
	SaveManager.delete_slot("perf_stress")
	print("robustesse : %s" % ("OK" if ok else "ECHEC"))


func run(host: Node) -> Dictionary:
	host.add_child(self)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	SaveManager.save_path = "user://test_perf.json"
	SaveManager.delete_save()
	main = MAIN.instantiate()
	add_child(main)
	await _wait(2)
	while main.mode != 1 or main.busy:   # 1 = écran-titre prêt
		await get_tree().process_frame
	var launch_ms := Time.get_ticks_msec()
	print("Lancement : écran-titre prêt %d ms après le démarrage du processus" % launch_ms)
	await _wait(120)
	GameState.new_game()
	GameState.playing = true
	main.mode = 2
	main.title.close()
	await _wait(20)
	if OS.has_environment("GLAN_PERF_IDLE"):   # attend N secondes sous le titre : laisse les fils d'arrière-plan préparer les caches
		await get_tree().create_timer(float(OS.get_environment("GLAN_PERF_IDLE"))).timeout
	var maps: Array = DEFAULT_MAPS
	if OS.has_environment("GLAN_PERF_MAPS"):
		maps = Array(OS.get_environment("GLAN_PERF_MAPS").split(","))
	var out := {"launch_ms": launch_ms}
	var Prewarm = load("res://src/gfx/prewarm.gd") if ResourceLoader.exists("res://src/gfx/prewarm.gd") else null
	print("== Mesures de fluidité (ms) : première entrée (froid), seconde (chaud) ==")
	if Prewarm != null:
		print("Préchauffage des shaders au lancement : %.0f ms (%d shaders)" % [Prewarm.last_ms, Prewarm.covered.size()])
		out["prewarm_ms"] = Prewarm.last_ms
	for pass_name in ["froid", "chaud"]:
		for id: String in maps:
			if not Database.has_map(id):
				continue
			var r := await _measure_map(id)
			out["%s:%s" % [pass_name, id]] = r
			print(_line("%s %s" % [pass_name, id], r))
	if not OS.has_environment("GLAN_PERF_NOSTRESS"):
		await _stress()
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
