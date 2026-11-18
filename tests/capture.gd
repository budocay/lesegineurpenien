extends Node
## Outil de contrôle visuel, à lancer AVEC fenêtre :
##   Godot --path . res://tests/capture.tscn -- /chemin/de/sortie
## Joue le début du jeu tout seul et enregistre des captures d'écran, avec
## quelques mesures (luminosité, netteté par bande) pour juger du rendu.

const MAIN = preload("res://scenes/main.tscn")

var out_dir := "/tmp/glandoulf_captures"
var main: Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	SaveManager.save_path = "user://test_capture.json"
	SaveManager.delete_save()
	main = MAIN.instantiate()
	add_child(main)
	await _frames(150)
	await _shot("1_titre")

	main.start_new_game()
	for _i in 600:
		await get_tree().process_frame
		if main.dialogue.active:
			break
	await _frames(100)
	await _shot("2_prologue_dialogue")
	# le prologue : on avance jusqu'au combat, joué en partie à la main
	await _until_menu()
	await _frames(40)
	await _shot("12_combat_prologue_menu")
	(main.battle_ui._root_list.get_child(1) as Button).pressed.emit()
	await _frames(30)
	await _shot("13_combat_competences")
	for b: Button in main.battle_ui._list_items.get_children():
		if not b.disabled:
			b.pressed.emit()
			break
	await _frames(30)
	await _shot("14_combat_cible")
	main.battle_ui._confirm_target()
	await _frames(45)
	await _shot("15_combat_sort")
	await _until_menu()
	(main.battle_ui._root_list.get_child(0) as Button).pressed.emit()
	await _frames(10)
	main.battle_ui._confirm_target()
	await _frames(22)
	await _shot("16_combat_assaut")
	main.battle.auto = true
	await _until_end()
	await _frames(40)
	await _shot("17_prologue_victoire")
	main.battle_ui._on_end("ok")
	await _idle()
	await _frames(60)
	await _shot("3_arrivee")

	await _goto(Vector3(22.5, 0.0, 16.2), "up")
	await _shot("4_place")
	await _goto(Vector3(8.2, 0.0, 11.5), "left")
	print("  cible : ", main.world.focus.get("dialogue", "(aucune)"), "  commandes : ", main.world.input_enabled,
			"  joueur : ", main.world.player.position, "  invite visible : ", main.hud._prompt.visible, " à ", main.hud._prompt.position)
	await _shot("5_pepine_invite")
	main._on_interact(main.world.focus)
	await _frames(140)
	await _shot("6_pepine_dialogue")
	await _idle()
	await _goto(Vector3(23.0, 0.0, 24.6), "down")
	await _shot("7_quai")
	await _goto(Vector3(35.0, 0.0, 14.0), "up")
	await _shot("8_est")

	main.change_map("auberge", "entree")
	await _frames(120)
	await _shot("9_auberge_entree")
	await _idle()
	await _goto(Vector3(9.0, 0.0, 6.0), "up")
	await _shot("10_auberge")
	main.pause.open("")
	await _frames(30)
	await _shot("11_pause")
	main.pause.close()
	await _frames(20)

	# le Pré Couché et un combat de rencontre, à deux
	GameState.add_to_party("pepine")
	GameState.heal_party()
	main.change_map("pre_couche", "ouest")
	await _frames(60)
	await _idle()
	await _goto(Vector3(9.0, 0.0, 10.8), "right")
	await _shot("18_pre_couche")
	await _goto(Vector3(31.5, 0.0, 9.6), "up")
	await _shot("19_grande_baveuse")
	main.start_battle({"enemies": ["epouvantail_avachi", "limace_molle", "guepe_cidre"], "arena": "pre"})
	await _until_menu()
	await _frames(50)
	await _shot("20_combat_pre_menu")
	(main.battle_ui._root_list.get_child(1) as Button).pressed.emit()
	await _frames(10)
	for b: Button in main.battle_ui._list_items.get_children():
		if not b.disabled:
			b.pressed.emit()
			break
	await _frames(10)
	main.battle_ui._confirm_target()
	await _frames(50)
	await _shot("21_combat_pre_sort")
	main.battle.auto = true
	await _frames(170)
	await _shot("22_combat_pre_milieu")
	await _until_end()
	await _frames(40)
	await _shot("23_combat_pre_victoire")
	main.battle_ui._on_end("ok")
	await _frames(120)

	# le Bois Penché et la Roselière, vus depuis leur entrée
	await _idle()
	GameState.set_flag("bois_vu")
	GameState.set_flag("roseliere_vue")
	main.change_map("bois_penche", "sud")
	await _frames(150)
	await _idle()
	await _shot("43_bois_penche")
	main.change_map("roseliere", "ouest")
	await _frames(150)
	await _idle()
	await _shot("44_roseliere")

	# étape 4 : l'étal d'Ursule, le journal, l'équipe, l'inventaire, la boutique
	await _idle()
	for f: String in ["gedeon_vu", "cales_recues", "bitte_1", "sam_vu", "fripon_vu", "fripon_avoue", "ursule_vue"]:
		GameState.set_flag(f)
	GameState.money = 80
	GameState.add_item("cale", 3)
	GameState.add_item("baton_ferre")
	GameState.add_item("gilet_batelier")
	GameState.equip("glandoulf", "baton_ferre")
	main.change_map("bittebourg", "route_est")
	await _frames(60)
	await _idle()
	await _goto(Vector3(20.4, 0.0, 24.3), "up")
	await _shot("24_etal_ursule")
	main._open_pause()
	await _frames(20)
	await _shot("25_pause")
	var shots := {"quests": "26_journal", "team": "27_equipe", "inventory": "28_inventaire"}
	for which: String in shots:
		main._on_pause_screen(which)
		await _frames(30)
		if which == "quests":
			main.menus._focus_row(2)
			await _frames(10)
		await _shot(str(shots[which]))
		main.menus.close()
		await _frames(10)
	# étape 3 : l'écran de talents, à quatre, avec des points dépensés et d'autres à dépenser
	main.pause.close(true)
	for id: String in ["sam", "fripon"]:
		GameState.add_to_party(id)
	for id: Variant in GameState.party:
		GameState.member(str(id))["level"] = 5
	GameState.learn_talent("glandoulf", "meche_courte")
	GameState.learn_talent("glandoulf", "petarade_t")
	GameState.learn_talent("glandoulf", "sommeil_reparateur")
	GameState.learn_talent("sam", "cuir_epais")
	main._open_pause()
	await _frames(20)
	await _shot("30_pause_talents")
	main._on_pause_screen("talents")
	await _frames(30)
	await _shot("31_talents")
	main.talents.focus_talent("poudre_seche")
	await _frames(15)
	await _shot("32_talents_detail")
	main.talents.select("sam")
	await _frames(5)
	main.talents.focus_talent("viens_y_voir_t")
	main.talents.press("viens_y_voir_t")
	await _frames(20)
	await _shot("33_talents_sam")
	main.talents.close(true)
	await _frames(10)
	main.menus.open_shop("etal_ursule")
	await _frames(10)
	main.menus.press(0)
	await _frames(30)
	await _shot("29_boutique")
	main.menus.close(true)
	await _frames(10)

	# animations de combat : quelques-unes figées au moment de l'impact
	GameState.heal_party()
	main.start_battle({"enemies": ["sanglier_flapi", "limace_molle", "champignon_dormeur"], "arena": "pre"})
	await _until_menu()
	await _frames(40)
	await _anim_shot("34_anim_coup_de_poele", "coup_de_poele", "sam", false, false)
	await _anim_shot("35_anim_bouquet_final", "bouquet_final", "glandoulf", false, false)
	await _anim_shot("36_anim_sieste_collective", "sieste_collective", "glandoulf", false, false)
	await _anim_shot("37_anim_tonnerre", "tonnerre", "glandoulf", false, false)
	await _anim_shot("38_anim_coup_en_douce", "coup_en_douce", "fripon", false, false)
	await _anim_shot("39_anim_banquet", "banquet", "sam", false, true)
	await _anim_shot("40_anim_purin_ortie", "purin_ortie", "pepine", false, false)
	await _anim_shot("41_anim_charge_ennemie", "charge_molle", "", true, true)
	await _anim_shot("42_anim_cri_strident", "cri_strident", "", true, true)
	await _save_shots()
	SaveManager.delete_save()
	print("CAPTURES OK : ", out_dir)
	get_tree().quit()


## Joue une animation de combat et la photographie juste après l'impact.
## who : héros qui la joue (ou le premier ennemi si from_enemy) ; on_party : vise l'équipe.
func _anim_shot(shot_name: String, anim: String, who: String, from_enemy: bool, on_party: bool) -> void:
	var b: Node3D = main.battle
	var allies: Array = []
	var foes: Array = []
	var caster: Node3D = null
	for c: RefCounted in b.engine.party:
		allies.append(b.actor_of(c))
		if str(c.source) == who:
			caster = b.actor_of(c)
	for c: RefCounted in b.engine.enemies:
		foes.append(b.actor_of(c))
	if from_enemy:
		caster = foes[0]
	if caster == null:
		caster = allies[0]
	var targets: Array = allies if on_party else foes
	if anim in ["coup_de_poele", "coup_en_douce", "purin_ortie", "tonnerre", "charge_molle"]:
		targets = [targets[0]]
	main.battle_ui.announce(str(Database.get_skill(anim).get("name", anim)), 1.4)
	b.fx.play(anim, caster, targets, "")
	var impact := float(Database.get_animation(anim).get("impact", 0.4))
	# en temps réel et non en images : l'écran peut tourner à 120 images par seconde
	await get_tree().create_timer(impact + 0.09).timeout
	await _shot(shot_name)
	await get_tree().create_timer(1.8).timeout


## Écrans de sauvegarde : liste, confirmation d'écrasement, écran de défaite et sa liste.
func _save_shots() -> void:
	SaveManager.delete_save()
	GameState.new_game()
	GameState.add_to_party("sam")
	GameState.member("sam")["level"] = 5
	for i in 3:
		GameState.map_id = ["auberge", "bittebourg", "route_brie"][i]
		GameState.playtime = 3725.0 * (i + 1)
		SaveManager.save_game(["m1", "m2", "m5"][i])
	SaveManager.autosave("lieu")
	SaveManager.autosave("combat", "capture")
	main.saves.open("load", "test")
	await _frames(40)
	await _shot("50_sauvegardes_charger")
	main.saves.close()
	main.saves.open("save", "test")
	main.saves._on_row("m2")
	await _frames(40)
	await _shot("51_sauvegardes_ecraser")
	main.saves.close()
	main.battle_ui.before_battle_slot = "a1"
	main.battle_ui.show_defeat()
	await _frames(60)
	await _shot("52_defaite_choix")
	main.battle_ui._on_end("load")
	await _frames(40)
	await _shot("53_defaite_sauvegardes")
	main.saves.close()


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


## Avance les dialogues jusqu'à ce que le menu de combat attende un choix.
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


## Attend l'écran de fin de combat (victoire ou défaite).
func _until_end() -> void:
	for _i in 9000:
		await get_tree().process_frame
		if main.battle == null or main.battle_ui._end_layer.visible:
			return
	print("  ATTENTION : le combat ne s'est pas terminé")


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


func _goto(p: Vector3, facing: String) -> void:
	main.world.player.position = p
	main.world.player.set_facing(facing)
	await _frames(150)


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, shot_name])
	# mesures : luminosité moyenne et netteté (contraste local) par bande horizontale
	var small := img.duplicate() as Image
	small.resize(320, 180, Image.INTERPOLATE_BILINEAR)
	var bands := [0.0, 0.0, 0.0]
	var lum := [0.0, 0.0, 0.0]
	var full := img
	var fw := full.get_width()
	var fh := full.get_height()
	for b in 3:
		var y0 := int(fh * (0.08 + 0.3 * b))
		var y1 := int(fh * (0.08 + 0.3 * (b + 1)))
		var n := 0
		var y := y0
		while y < y1:
			var x := 2
			while x < fw - 2:
				var c := full.get_pixel(x, y).get_luminance()
				var d := absf(c - full.get_pixel(x + 1, y).get_luminance()) + absf(c - full.get_pixel(x, mini(y + 1, fh - 1)).get_luminance())
				bands[b] += d
				lum[b] += c
				n += 1
				x += 3
			y += 3
		bands[b] /= float(n)
		lum[b] /= float(n)
	print("%s  %dx%d  luminosité haut/milieu/bas : %.3f %.3f %.3f   netteté haut/milieu/bas : %.4f %.4f %.4f" % [
		shot_name, fw, fh, lum[0], lum[1], lum[2], bands[0], bands[1], bands[2]])
