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
		print("BOSS %s : %.2f fois un héros" % [id, ratio])
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, id])
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
