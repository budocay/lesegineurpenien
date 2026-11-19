extends Node
## Captures des combats de boss, à lancer AVEC fenêtre :
##   Godot --path . res://tests/capture_boss.tscn -- /dossier/de/sortie [id_de_rencontre ...]
## Sans identifiant : toutes les rencontres de boss (flee false ou music boss). Chaque combat est joué avec une
## équipe de quatre, photographié, puis quitté par la fuite ; la taille du boss (en héros) est affichée.

const MAIN = preload("res://scenes/main.tscn")
var out_dir := "/tmp/glandoulf_boss"
var main: Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	SaveManager.save_path = "user://test_capture_boss.json"
	SaveManager.delete_save()
	main = MAIN.instantiate()
	add_child(main)
	for _i in 150:
		await get_tree().process_frame
	GameState.new_game()
	GameState.party = []
	for id: String in ["glandoulf", "sam", "froton", "pepin"]:
		GameState.add_to_party(id)
		GameState.member(id)["level"] = 20
	GameState.set_flag("chapitre_3_fini")
	GameState.map_id = "fondue_combe"
	GameState.heal_party()
	SaveManager.save_game()
	main.continue_game()
	for _n in 150:
		await get_tree().process_frame
	await _idle()
	var ids: Array = []
	if args.size() > 1:
		ids = args.slice(1)
	else:
		for id: String in Database.encounters:
			var e: Dictionary = Database.encounters[id]
			if e.get("flee", true) == false or str(e.get("music", "")) == "boss":
				ids.append(id)
	for id: String in ids:
		var enc: Dictionary = (Database.encounters[id] as Dictionary).duplicate(true)
		enc["flee"] = true   # pour pouvoir quitter le combat après la photo
		if not enc.has("boss"):
			enc["music"] = "boss"   # le combat se fuit pour la photo : « music boss » remplace « flee false » pour la détection du boss
		enc.erase("party")
		GameState.heal_party()
		main.start_battle(enc)
		await _until_menu()
		for _k in 50:
			await get_tree().process_frame
		var sc: Node3D = main.battle
		var ratio := 0.0
		if sc != null and sc.boss != null:
			ratio = (sc.actors[sc.boss.key] as Node3D).height / (sc.actors[sc.engine.party[0].key] as Node3D).height
		var info := ""
		if sc != null:
			var vs := get_viewport().get_visible_rect().size
			var hero_k_txt := "héros k=%.3f (libre %.3f, soit %.2f)" % [sc.hero_k, sc.hero_k_free, sc.hero_k / maxf(0.001, sc.hero_k_free)]
			var frac := 0.0
			if sc.boss != null:
				frac = sc.screen_rect(sc.boss).size.y / vs.y
			var xs := ""
			for h: RefCounted in sc.engine.party:
				var r: Rect2 = sc.screen_rect(h)
				xs += " [%d..%d, %d..%d]" % [r.position.x, r.end.x, r.position.y, r.end.y]
			info = " | %s, boss %.0f %% de la hauteur |%s" % [hero_k_txt, frac * 100.0, xs]
		print("BOSS %s : %.2f fois un héros%s" % [id, ratio, info])
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, id])
		if sc != null and sc.boss != null and OS.has_environment("BOSS_ANNONCE"):   # photo du coup annoncé : triangle rouge et bandeau
			sc.boss.next_skill = "attack"
			sc.ui.announce("%s prépare un grand coup !" % sc.boss.name, 5.0)
			await get_tree().create_timer(0.6).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/%s_annonce.png" % [out_dir, id])
			sc.boss.next_skill = ""
		if sc != null and sc.boss != null and OS.has_environment("BOSS_POSES"):   # poses « sort » puis « KO » du boss, dans le vrai combat
			var actor: Node3D = sc.actors[sc.boss.key]
			var hero_pos: Vector3 = (sc.actors[sc.engine.party[0].key] as Node3D).position
			actor.play_pose("cast", hero_pos, 0.9)
			await get_tree().create_timer(0.3).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/%s_cast.png" % [out_dir, id])
			await get_tree().create_timer(1.6).timeout
			actor.play_ko()
			await get_tree().create_timer(0.3).timeout
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("%s/%s_ko.png" % [out_dir, id])
			await get_tree().create_timer(1.2).timeout
			actor.play_revive()
		await _flee()
		main.battle_ui._on_end("ok")
		for _m in 100:
			await get_tree().process_frame
	SaveManager.delete_save()
	print("CAPTURES BOSS OK : ", out_dir)
	get_tree().quit()


func _idle() -> void:
	for _i in 3000:
		await get_tree().process_frame
		if main.battle != null or main.dialogue.waiting:
			continue
		if main.dialogue.active:
			if main.dialogue._typing:
				main.dialogue._finish_typing()
			elif not main.dialogue._choosing:
				main.dialogue._advance()
			else:
				var buttons: Array = main.dialogue._choice_list.get_children()
				(buttons[buttons.size() - 1] as Button).pressed.emit()
		elif not main.busy and main.world != null and main.world.input_enabled:
			return


func _until_menu() -> void:
	for _i in 4000:
		await get_tree().process_frame
		if main.battle != null and main.battle_ui._state == main.battle_ui.S.ROOT:
			return
		if main.battle == null and main.dialogue.active and not main.dialogue.waiting:
			if main.dialogue._typing:
				main.dialogue._finish_typing()
			else:
				main.dialogue._advance()
	print("  ATTENTION : le menu de combat n'est jamais apparu")


func _flee() -> void:
	for _i in 12000:
		if main.battle == null or main.battle_ui._end_layer.visible:
			return
		if main.battle_ui._state == main.battle_ui.S.ROOT:
			(main.battle_ui._root_list.get_child(4) as Button).pressed.emit()
			for _j in 10:
				await get_tree().process_frame
		await get_tree().process_frame
