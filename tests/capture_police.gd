extends Node
## Outil de contrôle visuel de la police : photographie tous les écrans de texte du jeu.
##   Godot --path . res://tests/capture_police.tscn -- <dossier> <taille, ex. 1600x900>
## À lancer AVEC fenêtre, sans toucher au clavier. Rien n'est enregistré dans les réglages de l'auteur.

const MAIN = preload("res://scenes/main.tscn")

var out_dir := "/tmp/glandoulf_police"
var main: Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	Settings.persist = false
	if args.size() > 1:
		Settings.set_value("taille", args[1])
	SaveManager.save_path = "user://test_capture.json"
	SaveManager.delete_save()
	Tutorial.reset_seen()
	main = MAIN.instantiate()
	add_child(main)
	await _frames(150)
	await _shot("01_titre")
	main.settings_screen.open("title")
	await _frames(30)
	await _shot("02_parametres_haut")
	for _i in 30:
		get_viewport().push_input(_key(KEY_DOWN))
		await _frames(2)
	await _frames(20)
	await _shot("03_parametres_bas")
	main.settings_screen.close(true)
	main.pad_screen.open("title")
	await _frames(30)
	await _shot("04_manette")
	main.pad_screen.close()
	await _frames(10)

	main.start_new_game()
	for _i in 600:
		await get_tree().process_frame
		if main.dialogue.active:
			break
	await _frames(100)
	await _shot("05_dialogue_prologue")
	await _until_menu()
	await _frames(40)
	await _shot("06_combat_menu")
	(main.battle_ui._root_list.get_child(1) as Button).pressed.emit()
	await _frames(30)
	await _shot("07_combat_competences")
	for b: Button in main.battle_ui._list_items.get_children():
		if not b.disabled:
			b.pressed.emit()
			break
	await _frames(30)
	await _shot("08_combat_cible")
	main.battle_ui._confirm_target()
	await _frames(45)
	await _shot("09_combat_annonce")
	await _until_menu()
	(main.battle_ui._root_list.get_child(2) as Button).pressed.emit()   # objets
	await _frames(30)
	await _shot("10_combat_objets")
	var back := InputEventAction.new()
	back.action = "cancel"
	back.pressed = true
	Input.parse_input_event(back)
	await _frames(20)
	(main.battle_ui._root_list.get_child(0) as Button).pressed.emit()
	await _frames(10)
	main.battle_ui._confirm_target()
	await _frames(22)
	main.battle.auto = true
	await _until_end()
	await _frames(60)
	await _shot("11_victoire")
	main.battle_ui._on_end("ok")
	await _idle()
	await _frames(40)
	main.hud.banner("Bittebourg", "Le Comté")
	await _frames(100)
	await _shot("12_bandeau_lieu")
	await _frames(300)
	main.hud.toast("Points de talent à dépenser : Talents, dans le menu. Et une phrase un peu longue pour voir.")
	await _frames(40)
	await _shot("13_toast")
	await _frames(300)

	# dialogue à choix, avec Pépin
	GameState.set_flag("pepin_vue")
	main.dialogue.start("pepin")
	for _i in 2000:
		await get_tree().process_frame
		if main.dialogue._choosing:
			break
		if main.dialogue._typing:
			main.dialogue._finish_typing()
		elif main.dialogue.active and not main.dialogue.waiting:
			main.dialogue._advance()
	await _frames(40)
	await _shot("14_dialogue_choix")
	await _idle()

	# équipe de quatre, pause, menus
	for id: String in ["sam", "froton", "pepin"]:
		GameState.add_to_party(id)
	for id: Variant in GameState.party:
		GameState.member(str(id))["level"] = 5
	GameState.learn_talent("glandoulf", "meche_courte")
	GameState.add_item("tisane", 3)
	GameState.add_item("baton_ferre")
	await get_tree().create_timer(8.0).timeout
	main._open_pause()
	await _frames(25)
	await _shot("15_pause")
	for which: String in ["team", "inventory", "quests"]:
		main._on_pause_screen(which)
		await _frames(30)
		await _shot("16_menu_" + which)
		if which == "team":
			main.menus._focus_row(1)
			await _frames(10)
			await _shot("16_menu_team_2")
		main.menus.close()
		await _frames(10)
	main.pause.close(true)
	main._open_pause()
	await _frames(20)
	main._on_pause_screen("talents")
	await _frames(30)
	await _shot("17_talents")
	main.talents.focus_talent("poudre_seche")
	await _frames(15)
	await _shot("18_talents_detail")
	main.talents.close(true)
	main.pause.close(true)
	await _frames(10)
	main.menus.open_shop("etal_ursule")
	await _frames(10)
	main.menus.press(0)
	await _frames(30)
	await _shot("19_boutique")
	main.menus.close(true)
	await _frames(10)
	main._open_pause()
	await _frames(20)
	main.saves.open("load", "test")
	SaveManager.save_game("m1")
	main.saves.close()
	main.saves.open("save", "test")
	await _frames(40)
	await _shot("20_sauvegardes")
	main.saves.close()
	SaveManager.delete_slot("m1")
	await _clean()
	main._open_pause()
	await _frames(10)
	main.settings_screen.open("pause")
	await _frames(20)
	await _shot("21_parametres_pause")
	await _clean()
	# conseil bloquant (Tutorial) puis page d'aide
	Tutorial._show_modal(Tutorial.by_id["boutique"])
	await _frames(120)
	await _shot("22_conseil_bloquant")
	Tutorial.clear()
	await _clean()
	Tutorial.help.open()
	await _frames(40)
	await _shot("23_aide")
	get_tree().quit()


func _clean() -> void:
	for _i in 3:
		main.pause.close(true)
		main.menus.close(true)
		main.talents.close(true)
		main.settings_screen.close(true)
		main.saves.close()
		await _frames(15)


func _key(code: Key) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = code
	e.pressed = true
	return e


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


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


func _until_end() -> void:
	for _i in 9000:
		await get_tree().process_frame
		if main.battle == null or main.battle_ui._end_layer.visible:
			return


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


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out_dir, shot_name])
