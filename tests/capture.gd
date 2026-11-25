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
	if args.size() > 1 and args[1] == "chap4":
		await _dwarven_only()
		return
	if args.size() > 1 and args[1] == "chap5":
		await _rider_only()
		return
	if args.size() > 1 and args[1] == "chap6":
		await _gouda_only(args.size() > 2 and args[2] == "arenes")
		return
	if args.size() > 1 and args[1] == "chap7":
		await _mordgras_only(args.size() > 2 and args[2] == "arenes")
		return
	if args.size() > 1 and args[1] == "vues":
		await _vues_only()
		return
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
	await _shot("5_pepin_invite")
	main._on_interact(main.world.focus)
	await _frames(140)
	await _shot("6_pepin_dialogue")
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
	GameState.add_to_party("pepin")
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
	await _arena_shots()
	await _elven_shots()
	await _dwarven_shots()
	main.change_map("roseliere", "ouest")
	await _frames(150)
	await _idle()

	# étape 4 : l'étal d'Ursule, le journal, l'équipe, l'inventaire, la boutique
	await _idle()
	for f: String in ["gedeon_vu", "cales_recues", "bitte_1", "sam_vu", "froton_vu", "froton_avoue", "ursule_vue"]:
		GameState.set_flag(f)
	GameState.money = 80
	GameState.add_item("cale", 3)
	GameState.add_item("baton_ferre")
	GameState.add_item("gilet_batelier")
	GameState.equip("glandoulf", "baton_ferre")
	main.change_map("bittebourg", "route_est")
	await _frames(60)
	await _idle()
	# Ursule est en (19,1 ; 22,2) : on se place deux cases plus bas, sur le ponton, pour la voir avec son étal
	await _goto(Vector3(20.4, 0.0, 26.2), "up")
	# on attend que le titre du lieu et les bandeaux de quête s'effacent : la vue ne montre que l'étal
	await get_tree().create_timer(8.0).timeout
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
	for id: String in ["sam", "froton"]:
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
	await get_tree().create_timer(6.0).timeout
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
	await _anim_shot("38_anim_coup_en_douce", "coup_en_douce", "froton", false, false)
	await _anim_shot("39_anim_banquet", "banquet", "sam", false, true)
	await _anim_shot("40_anim_purin_ortie", "purin_ortie", "pepin", false, false)
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


## Chapitre 3 : Fondue-Combe elfique (place, pont sur le torrent, salle du Conseil).
func _elven_shots() -> void:
	for f: String in ["fondue_vue", "archives_vues", "col_vu", "ouest_dit"]:
		GameState.set_flag(f)
	main.change_map("fondue_combe", "conseil_porte")
	await _frames(150)
	await _idle()
	await _goto(Vector3(31.0, 0.0, 12.0), "up")
	await _shot("54_fondue_combe_place")
	await _goto(Vector3(46.2, 0.0, 21.2), "left")
	await _shot("55_fondue_combe_pont")
	main.change_map("salle_conseil", "entree")
	await _frames(150)
	await _idle()
	await _goto(Vector3(15.0, 0.0, 11.0), "up")
	await _shot("56_salle_conseil")


## Combats dans les arenes choisies selon le lieu (taverne, ruelle, cave, col, cite elfique, archives).
func _arena_shots() -> void:
	var list := [["57_arene_taverne", "taverne"], ["58_arene_ruelle_nuit", "ruelle_nuit"], ["59_arene_cave_fromage", "cave_fromage"],
		["60_arene_col", "col"], ["61_arene_cite_elfique", "cite_elfique"], ["62_arene_archives", "archives"]]
	for entry: Array in list:
		GameState.heal_party()
		main.start_battle({"enemies": ["epouvantail_avachi", "limace_molle", "guepe_cidre"], "arena": entry[1]})
		await _until_menu()
		await _frames(50)
		await _shot(str(entry[0]))
		# sortie par la fuite : passer le combat en automatique au milieu d'un tour ne le relançait plus,
		# et toutes les captures suivantes montraient ce combat figé
		await _flee()
		await _frames(20)
		main.battle_ui._on_end("ok")
		await _frames(120)


## Chapitre 4 : les Mines de Morbier (vues des huit cartes).
func _dwarven_shots() -> void:
	for f: String in ["chapitre_3_fini", "bromure_invite", "porte_vue", "galeries_vues", "halle_vue", "tombe_vue", "profondeurs_vues", "pont_vu", "portes_vues", "goulum_rencontre", "balourd_fait"]:
		GameState.set_flag(f)
	main.change_map("porte_morbier", "vallee")
	await _frames(150)
	await _idle()
	await _goto(Vector3(20.0, 0.0, 14.0), "up")
	await _shot("60_porte_morbier")
	GameState.set_flag("porte_ouverte")
	main.change_map("porte_morbier", "mines")
	await _frames(150)
	await _idle()
	await _shot("61_porte_ouverte")
	main.change_map("morbier_galeries", "porte")
	await _frames(150)
	await _idle()
	await _shot("62_galeries_entree")
	await _goto(Vector3(27.0, 0.0, 19.5), "right")
	await _shot("63_galeries_chambre")
	await _goto(Vector3(40.0, 0.0, 6.5), "left")
	await _shot("64_galeries_terrasse")
	main.change_map("morbier_halle", "ouest")
	await _frames(150)
	await _idle()
	await _goto(Vector3(21.0, 0.0, 15.0), "right")
	await _shot("65_halle_des_forges")
	await _goto(Vector3(29.0, 0.0, 12.6), "up")
	await _shot("66_halle_rondin")
	main.change_map("morbier_tombe", "entree")
	await _frames(150)
	await _idle()
	await _goto(Vector3(15.0, 0.0, 18.5), "up")
	await _shot("67_tombe_troll")
	GameState.set_flag("combat_gros_bleu")
	main.change_map("morbier_tombe", "entree")
	await _frames(150)
	await _idle()
	await _goto(Vector3(15.0, 0.0, 12.0), "up")
	await _shot("68_tombe_ballot")
	main.change_map("morbier_profondeurs", "haut")
	await _frames(150)
	await _idle()
	await _shot("69_profondeurs_haut")
	await _goto(Vector3(17.0, 0.0, 17.0), "right")
	await _shot("70_profondeurs_pont")
	await _goto(Vector3(40.0, 0.0, 13.0), "up")
	await _shot("71_profondeurs_est")
	main.change_map("morbier_antre", "entree")
	await _frames(150)
	await _idle()
	await _shot("72_antre_rive")
	await _goto(Vector3(24.0, 0.0, 18.0), "up")
	await _shot("73_antre_lac")
	main.change_map("morbier_pont", "ouest")
	await _frames(150)
	await _idle()
	await _shot("74_pont_depart")
	await _goto(Vector3(22.0, 0.0, 12.0), "right")
	await _shot("75_pont_milieu")
	main.change_map("portes_est", "pont")
	await _frames(150)
	await _idle()
	await _goto(Vector3(10.0, 0.0, 12.0), "right")
	await _shot("76_portes_est")


## Arènes du chapitre 4, puis les quatre grands ennemis (mode « chap4 » seul).
func _dwarven_arenas(bosses: bool) -> void:
	var cases := [["galerie_mine", ["gobe_lard", "gobe_pic", "chauve_molle"]], ["halle_piliers", ["gobe_gras", "gobe_pic"]],
		["bord_du_lac", ["tentacule_lac", "tentacule_lac"]], ["pont_abime", ["gobe_lard", "gobe_lard"]]]
	if bosses:
		cases = [["bord_du_lac", ["guetteur_lac", "tentacule_lac"]], ["halle_piliers", ["gros_bleu", "gobe_lard"]], ["bord_du_lac", ["goulum"]], ["pont_abime", ["balourd"]]]
	var n := 80 if not bosses else 84
	for c: Array in cases:
		main.start_battle({"enemies": c[1], "arena": c[0], "flee": true})
		await _until_menu()
		await _frames(50)
		await _shot("%d_arene_%s" % [n, str(c[0])])
		n += 1
		await _flee()
		main.battle_ui._on_end("ok")
		await _frames(120)


func _dwarven_only() -> void:
	GameState.new_game()
	GameState.party = []
	for id: String in ["glandoulf", "sam", "froton", "pepin", "merri", "aragrogne", "digoulasse", "grimli"]:
		GameState.add_to_party(id)
		GameState.member(id)["level"] = 14
	GameState.set_flag("chapitre_3_fini")
	GameState.map_id = "fondue_combe"
	GameState.heal_party()
	SaveManager.save_game()
	main.continue_game()
	await _frames(150)
	await _idle()
	await _dwarven_shots()
	await _dwarven_arenas(false)
	await _dwarven_arenas(true)
	SaveManager.delete_save()
	print("CAPTURES CHAP4 OK : ", out_dir)
	get_tree().quit()


## Chapitre 5 : les huit cartes, les sept arènes et les grands ennemis (mode « chap5 » seul).
func _rider_shots() -> void:
	for f: String in ["chapitre_4_fini", "portes_vues", "bromure_invite", "embuscade_faite", "plaine_vue", "cabecou_vu", "fongorn_vu", "garde_vu", "bergerie_vue", "isengarde_vu", "bilan_fait", "glandoulf_revenu", "bromure_revenu", "bromure_mort"]:
		GameState.set_flag(f)
	main.change_map("portes_est", "pont")
	await _frames(150)
	await _idle()
	await _goto(Vector3(12.0, 0.0, 12.4), "right")
	await _shot("90_portes_tombe")
	main.change_map("chutes_gratin", "ouest")
	await _frames(150)
	await _idle()
	await _shot("91_chutes_arrivee")
	await _goto(Vector3(24.0, 0.0, 9.2), "up")
	await _shot("92_chutes_cascade")
	await _goto(Vector3(32.5, 0.0, 6.0), "left")
	await _shot("93_chutes_terrasse")
	main.change_map("plaine_roquefort", "ouest")
	await _frames(150)
	await _idle()
	await _shot("94_plaine_arrivee")
	await _goto(Vector3(29.0, 0.0, 7.0), "down")
	await _shot("95_plaine_colline")
	await _goto(Vector3(44.0, 0.0, 19.0), "right")
	await _shot("96_plaine_enclos")
	main.change_map("cabecou", "ouest")
	await _frames(150)
	await _idle()
	await _shot("97_cabecou_arrivee")
	await _goto(Vector3(30.0, 0.0, 14.5), "up")
	await _shot("98_cabecou_halle")
	await _goto(Vector3(50.0, 0.0, 7.5), "left")
	await _shot("99_cabecou_terrasse")
	main.change_map("fongorn", "ouest")
	await _frames(150)
	await _idle()
	await _shot("100_fongorn_arrivee")
	await _goto(Vector3(40.0, 0.0, 10.0), "up")
	await _shot("101_fongorn_barbe_molle")
	GameState.set_flag("grimace_vaincue")
	main.change_map("bergerie_or", "porte")
	await _frames(150)
	await _idle()
	await _shot("102_bergerie_entree")
	await _goto(Vector3(20.0, 0.0, 8.0), "up")
	await _shot("103_bergerie_trone")
	main.change_map("garde_manger", "cellules")
	await _frames(150)
	await _idle()
	await _shot("104_garde_cellules")
	await _goto(Vector3(29.0, 0.0, 13.0), "right")
	await _shot("105_garde_salle")
	main.change_map("isengarde", "sud")
	await _frames(150)
	await _idle()
	await _shot("106_isengarde_arrivee")
	await _goto(Vector3(32.0, 0.0, 14.0), "up")
	await _shot("107_isengarde_chaussee")
	GameState.set_flag("fosses_inondees")
	GameState.set_flag("fours_eteints")
	main.change_map("isengarde", "tour")
	await _frames(150)
	await _idle()
	await _shot("108_isengarde_inondee")
	GameState.set_flag("sarumale_vaincu")
	main.change_map("terrasse_office", "entree")
	await _frames(150)
	await _idle()
	await _goto(Vector3(13.0, 0.0, 9.0), "right")
	await _shot("109_terrasse_office")
	# l'écurie de Brie et son enseigne en fer à cheval
	main.change_map("brie", "route")
	await _frames(150)
	await _idle()
	await _goto(Vector3(54.0, 0.0, 15.6), "up")
	await _shot("110_brie_ecurie")


func _rider_arenas(bosses: bool) -> void:
	var cases := [["chutes_gratin", ["ouroukouille_ligne", "ouroukouille_brocheur", "ouroukouille_petrisseur"]], ["plaine_roquefort", ["ouargue", "hirsute", "corbeau_controleur"]],
		["fongorn", ["hors_oeuvre", "hors_oeuvre", "hors_oeuvre"]], ["bergerie_or", ["paton", "ouroukouille_ligne"]],
		["garde_manger", ["ouroukouille_ligne", "paton", "paton"]], ["petrins", ["ouroukouille_ligne", "ouroukouille_petrisseur", "ouroukouille_brocheur", "paton"]],
		["terrasse_office", ["ouroukouille_ligne", "ouroukouille_brocheur"]]]
	if bosses:
		cases = [["chutes_gratin", ["uglouk", "ouroukouille_ligne", "ouroukouille_brocheur"]], ["plaine_roquefort", ["grimace", "corbeau_controleur", "corbeau_controleur"]],
			["garde_manger", ["froton_anneaute"]], ["terrasse_office", ["sarumale"]]]
	var n := 110 if not bosses else 118
	for c: Array in cases:
		main.start_battle({"enemies": c[1], "arena": c[0], "flee": true})
		await _until_menu()
		await _frames(50)
		await _shot("%d_arene_%s" % [n, str(c[0])])
		n += 1
		await _flee()
		main.battle_ui._on_end("ok")
		await _frames(120)


func _rider_only() -> void:
	GameState.new_game()
	GameState.party = []
	for id: String in ["sam", "froton", "pepin", "merri", "aragrogne", "digoulasse", "grimli", "glandoulf"]:
		GameState.add_to_party(id)
		GameState.member(id)["level"] = 18
	GameState.set_flag("chapitre_4_fini")
	GameState.map_id = "portes_est"
	GameState.heal_party()
	SaveManager.save_game()
	main.continue_game()
	await _frames(150)
	await _idle()
	await _rider_shots()
	await _rider_arenas(false)
	await _rider_arenas(true)
	SaveManager.delete_save()
	print("CAPTURES CHAP5 OK : ", out_dir)
	get_tree().quit()


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


## Quitte le combat par la fuite. Elle réussit trois fois sur quatre : à chaque échec le menu revient
## (c'était la cause des « ATTENTION : le combat ne s'est pas terminé » : le script attendait sans rien rejouer).
func _flee() -> void:
	for _i in 12000:
		if main.battle == null or main.battle_ui._end_layer.visible:
			return
		if main.battle_ui._state == main.battle_ui.S.ROOT:
			(main.battle_ui._root_list.get_child(4) as Button).pressed.emit()
			await _frames(10)
		await get_tree().process_frame
	print("  ATTENTION : la fuite n'a pas abouti")


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
	main.world.encounter_zones = []   # pas de rencontre au milieu d'une prise de vue
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


## Chapitre 6 : Minas Tartine, le Sentier, Port-Salé et le Pelle-à-Tarte (mode « chap6 » seul ; « arenes » en
## troisième argument : les arènes et les grands ennemis).
func _gouda_only(arenas_only: bool) -> void:
	GameState.new_game()
	GameState.party = []
	for id: String in ["glandoulf", "sam", "froton", "aragrogne", "pepin", "merri", "digoulasse", "grimli"]:
		GameState.add_to_party(id)
		GameState.member(id)["level"] = 24
	GameState.set_flag("chapitre_5_fini")
	GameState.set_flag("minas_vu")
	GameState.map_id = "minas_croute"
	GameState.spawn_id = "aigle"
	GameState.heal_party()
	SaveManager.save_game()
	main.continue_game()
	await _frames(150)
	await _idle()
	if arenas_only:
		await _gouda_arenas()
	else:
		await _gouda_shots()
	SaveManager.delete_save()
	print("CAPTURES CHAP6 OK : ", out_dir)
	get_tree().quit()


func _gouda_shots() -> void:
	await _shot("200_croute_arrivee")
	await _goto(Vector3(24.0, 0.0, 16.0), "right")
	await _shot("201_croute_place")
	await _goto(Vector3(41.0, 0.0, 16.5), "right")
	await _shot("202_croute_porte")
	await _goto(Vector3(56.0, 0.0, 16.5), "left")
	await _shot("203_croute_siege")
	await _goto(Vector3(14.0, 0.0, 8.0), "up")
	await _shot("204_croute_poterne")
	main.change_map("minas_rues", "bas")
	await _frames(150)
	await _idle()
	await _shot("205_rues_bas")
	await _goto(Vector3(17.0, 1.4, 28.5), "up")
	await _shot("206_rues_confiture")
	await _goto(Vector3(17.0, 2.8, 18.5), "up")
	await _shot("207_rues_miel")
	await _goto(Vector3(18.0, 4.2, 8.5), "up")
	await _shot("208_rues_mie")
	main.change_map("minas_citadelle", "bas")
	await _frames(150)
	await _idle()
	await _shot("209_citadelle")
	await _goto(Vector3(18.0, 0.0, 12.0), "up")
	await _shot("210_citadelle_poirier")
	main.change_map("minas_intendance", "entree")
	await _frames(150)
	await _idle()
	await _shot("211_intendance")
	await _goto(Vector3(14.0, 0.0, 8.0), "up")
	await _shot("212_intendance_bureau")
	main.change_map("sentier_insomniaques", "entree")
	await _frames(150)
	await _idle()
	await _shot("213_sentier_entree")
	await _goto(Vector3(26.0, 0.0, 10.0), "right")
	await _shot("214_sentier_milieu")
	await _goto(Vector3(44.0, 0.0, 10.5), "right")
	await _shot("215_sentier_roi")
	main.change_map("port_sale", "entree")
	await _frames(150)
	await _idle()
	await _shot("216_port_arrivee")
	await _goto(Vector3(26.0, 0.0, 14.5), "right")
	await _shot("217_port_quai")
	await _goto(Vector3(35.0, 0.0, 15.5), "right")
	await _shot("218_port_saumure")
	GameState.set_flag("combat_dindon_farce")
	main.change_map("pelle_a_tarte", "entree")
	await _frames(150)
	await _idle()
	await _shot("219_pelle_arrivee")
	await _goto(Vector3(30.0, 0.0, 14.0), "right")
	await _shot("220_pelle_champ")
	await _goto(Vector3(48.0, 0.0, 16.0), "right")
	await _shot("221_pelle_naze")


func _gouda_arenas() -> void:
	var cases := [["minas_remparts", ["cassouletain", "morfale_siege", "cassouletain"]], ["minas_rues", ["boucanier", "eveille"]], ["citadelle", ["eveille_veilleur", "eveille"]],
		["sentier_insomniaques", ["eveille", "eveille_veilleur", "eveille"]], ["port_sale", ["boucanier", "boucanier", "boucanier"]], ["pelle_a_tarte", ["mammou", "cassouletain"]],
		["sentier_insomniaques", ["roi_eveille"]], ["port_sale", ["saumure", "boucanier", "boucanier"]], ["minas_remparts", ["grondine", "morfale_siege"]],
		["minas_remparts", ["gothmoque", "morfale_siege", "morfale_siege"]], ["pelle_a_tarte", ["dindon_farce", "cassouletain"]], ["pelle_a_tarte", ["naze_supreme"]]]
	var n := 230
	for c: Array in cases:
		main.start_battle({"enemies": c[1], "arena": c[0], "flee": true})
		await _until_menu()
		await _frames(50)
		await _shot("%d_arene_%s_%s" % [n, str(c[0]), str(c[1][0])])
		n += 1
		await _flee()
		main.battle_ui._on_end("ok")
		await _frames(120)


## Chapitre 7 : le pays ennemi, de l'épilogue aux arènes (mode « chap7 » seul ; « arenes » en troisième argument :
## les arènes et les grands ennemis).
func _mordgras_only(arenas_only: bool) -> void:
	GameState.new_game()
	GameState.party = []
	for id: String in ["froton", "sam", "merri", "glandoulf"]:
		GameState.add_to_party(id)
		GameState.member(id)["level"] = 27
	for f: String in ["chapitre_5_fini", "chapitre_6_fini", "chapitre_7_debut", "marais_vu", "passe_vu", "col_vu", "cuisines_vu", "banquet_vu", "marches_vue", "epilogue_vu", "goulum_guide", "louche_trouvee"]:
		GameState.set_flag(f)
	GameState.map_id = "marais_bouillon"
	GameState.spawn_id = "ouest"
	GameState.heal_party()
	SaveManager.save_game()
	main.continue_game()
	await _frames(150)
	await _idle()
	if arenas_only:
		await _mordgras_arenas()
	else:
		await _mordgras_shots()
	SaveManager.delete_save()
	print("CAPTURES CHAP7 OK : ", out_dir)
	get_tree().quit()


func _mordgras_shots() -> void:
	await _shot("300_marais_arrivee")
	await _goto(Vector3(20.0, 0.0, 11.5), "right")
	await _shot("301_marais_planches")
	await _goto(Vector3(36.0, 0.0, 11.5), "right")
	await _shot("302_marais_milieu")
	await _goto(Vector3(47.0, 0.0, 11.5), "right")
	await _shot("303_marais_noyes")
	GameState.set_flag("combat_bouche_du_maitre")
	main.change_map("passe_plat", "sud")
	await _frames(150)
	await _idle()
	await _shot("304_passe_arrivee")
	await _goto(Vector3(24.0, 0.0, 17.0), "up")
	await _shot("305_passe_milieu")
	await _goto(Vector3(24.0, 0.0, 10.0), "up")
	await _shot("306_passe_porte")
	GameState.set_flag("goulum_trahi")
	main.change_map("col_arachnee", "ouest")
	await _frames(150)
	await _idle()
	await _shot("307_col_arrivee")
	await _goto(Vector3(26.0, 0.0, 13.0), "right")
	await _shot("308_col_toile")
	await _goto(Vector3(43.0, 0.0, 13.0), "right")
	await _shot("309_col_arachnee")
	GameState.set_flag("goulum_parti")
	main.change_map("mordgras_cuisines", "soupirail")
	await _frames(150)
	await _idle()
	await _shot("310_cuisines_arrivee")
	await _goto(Vector3(21.0, 0.0, 12.0), "up")
	await _shot("311_cuisines_marmite")
	await _goto(Vector3(36.0, 0.0, 20.0), "right")
	await _shot("312_cuisines_froid")
	GameState.set_flag("banquet_servi")
	main.change_map("mordgras_banquet", "ouest")
	await _frames(150)
	await _idle()
	await _shot("313_banquet_arrivee")
	await _goto(Vector3(28.0, 0.0, 14.0), "right")
	await _shot("314_banquet_tables")
	await _goto(Vector3(47.0, 0.0, 15.0), "right")
	await _shot("315_banquet_dessert")
	main.change_map("quatre_mille_marches", "bas")
	await _frames(150)
	await _idle()
	await _shot("316_marches_bas")
	await _goto(Vector3(12.0, 0.0, 34.0), "up")
	await _shot("317_marches_milieu")
	await _goto(Vector3(12.0, 0.0, 8.0), "up")
	await _shot("318_marches_haut")
	main.change_map("grand_four", "bas")
	await _frames(150)
	await _idle()
	await _shot("319_four_arrivee")
	await _goto(Vector3(22.0, 0.0, 17.0), "up")
	await _shot("320_four_sauron")
	GameState.set_flag("sauron_endormi")
	main.change_map("grand_four", "bas")
	await _frames(150)
	await _idle()
	await _goto(Vector3(22.0, 0.0, 14.0), "up")
	await _shot("321_four_sauron_endormi")
	# comme dans le jeu : les marqueurs de quête sont posés et le groupe se réduit à Glandoulf AVANT le changement de carte
	for f: String in ["marais_traverse", "passe_tenu", "arachnee_endormie", "goulum_parti", "banquet_servi", "marches_finies", "sauron_endormi", "anneau_jete", "chapitre_7_fini"]:
		GameState.set_flag(f)
	GameState.set_group(["glandoulf"])
	main.change_map("bittebourg_epilogue", "arrivee")
	await _frames(150)
	await _idle()
	await _shot("322_epilogue_arrivee")
	await _goto(Vector3(20.0, 0.0, 17.0), "right")
	await _shot("323_epilogue_place")
	# le générique à trois moments (début, milieu, anneaux)
	main.credits.play(Database.game.get("credits", []))
	await _secs(3.0)
	await _shot("324_generique_debut")
	await _secs(22.0)
	await _shot("325_generique_milieu")
	await _secs(26.0)
	await _shot("326_generique_fin_du_texte")
	main.credits._phase = "rings"
	main.credits._t = 0.0
	await _secs(3.5)
	await _shot("327_generique_anneaux")
	main.credits._finish()


## Attente en secondes réelles (l'affichage tourne bien plus vite que 120 images par seconde).
func _secs(t: float) -> void:
	var until := Time.get_ticks_msec() + int(t * 1000.0)
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame


func _mordgras_arenas() -> void:
	var cases := [["marais_bouillon", ["noye", "noye", "noye"]], ["passe_plat", ["bouche_du_maitre", "ologrill", "ologrill"]], ["gorgonzola", ["grand_ologrill", "ologrill"]],
		["col_arachnee", ["fileuse", "fileuse", "fileuse"]], ["col_arachnee", ["arachnee", "fileuse"]], ["cuisines_mor", ["naze_service", "naze_service", "naze_service"]],
		["banquet_mor", ["convive", "convive", "naze_service"]], ["banquet_mor", ["maitre_de_salle", "naze_service", "naze_service"]], ["marches_mor", ["marcheur", "marcheur", "naze_service"]],
		["arena_oeil", ["grand_oeil"]], ["arena_oeil", ["sauron_final"]]]
	var n := 330
	for c: Array in cases:
		main.start_battle({"enemies": c[1], "arena": c[0], "flee": true})
		await _until_menu()
		await _frames(50)
		await _shot("%d_arene_%s_%s" % [n, str(c[0]), str(c[1][0])])
		n += 1
		await _flee()
		main.battle_ui._on_end("ok")
		await _frames(120)


## Prise de vue libre : ni rencontre ni déclencheur pendant la pause, et on attend quelques secondes (en temps réel,
## l'affichage peut tourner bien plus vite que 120 images par seconde) que le bandeau du lieu s'efface.
func _view_goto(p: Vector3, facing: String) -> void:
	main.world.input_enabled = false
	main.hud.visible = false
	print("VUE carte ", main.world.map.get("id"), "  combat : ", main.battle != null, "  dialogue : ", main.dialogue.active)
	main.world.player.position = p
	main.world.player.set_facing(facing)
	var until := Time.get_ticks_msec() + 5200
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame


## Mode « vues » : prises de vue libres, pour régler une carte. Variable GLAN_VUES :
## « carte@arrivée:x,y,hauteur,direction;... » (une prise par morceau, « carte@arrivée »
## change de carte), et GLAN_ARENES : « arène:ennemi,ennemi;... » pour des combats.
func _vues_only() -> void:
	GameState.new_game()
	GameState.party = []
	for id: String in ["glandoulf", "sam", "froton", "aragrogne"]:
		GameState.add_to_party(id)
		GameState.member(id)["level"] = 24
	GameState.set_flag("chapitre_5_fini")
	GameState.set_flag("minas_vu")
	GameState.set_flag("combat_dindon_farce")
	# les scènes d'arrivée et les déclencheurs d'histoire sont déjà joués : on veut voir les cartes, pas les combats
	for map_id: String in Database.list_maps():
		var md: Dictionary = Database.get_map(map_id)
		for e: Variant in md.get("on_enter", []):
			if e is Dictionary and not (e as Dictionary).has("if") and (e as Dictionary).has("unless"):
				GameState.set_flag(str((e as Dictionary)["unless"]))
		for o: Variant in md.get("objects", []):
			if o is Dictionary and str((o as Dictionary).get("type", "")) == "trigger" and (o as Dictionary).has("unless") and not (o as Dictionary).has("if"):
				GameState.set_flag(str((o as Dictionary)["unless"]))
	GameState.map_id = "minas_croute"
	GameState.spawn_id = "aigle"
	GameState.heal_party()
	SaveManager.save_game()
	main.continue_game()
	await _frames(150)
	await _idle()
	var n := 0
	for part: String in OS.get_environment("GLAN_VUES").split(";", false):
		if part == "!":
			# prise de vue à l'endroit d'arrivée, sans déplacer le héros
			main.world.input_enabled = false
			main.hud.visible = false
			var t_end := Time.get_ticks_msec() + 3000
			while Time.get_ticks_msec() < t_end:
				await get_tree().process_frame
			await _shot("v%02d_%s_arrivee" % [n, str(main.world.map.get("id"))])
			n += 1
		elif part.contains(":"):
			var q := part.split(":")
			var c := q[1].split(",")
			await _view_goto(Vector3(float(c[0]), float(c[2]), float(c[1])), c[3])
			await _shot("v%02d_%s" % [n, q[0].replace("@", "_")])
			n += 1
		else:
			var q := part.split("@")
			if OS.get_environment("GLAN_FPS") != "":
				Engine.max_fps = 0
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)   # sinon l'image est bornée à 120 par seconde
			main.change_map(q[0], q[1])
			await _frames(150)
			await _idle()
			if OS.get_environment("GLAN_FPS") != "":
				# temps d'image moyen sur trois secondes
				var f0 := Engine.get_frames_drawn()
				var tm0 := Time.get_ticks_msec()
				while Time.get_ticks_msec() - tm0 < 3000:
					await get_tree().process_frame
				print("IMAGE ", q[0], " : ", snappedf(3000.0 / float(Engine.get_frames_drawn() - f0), 0.01), " ms")
			# une scène d'arrivée peut lancer un combat : on le joue tout seul, puis on rend la main
			for _k in 3:
				if main.battle == null:
					break
				await _until_menu()
				main.battle.auto = true
				await _until_end()
				await _frames(40)
				main.battle_ui._on_end("ok")
				await _frames(120)
				await _idle()
	for part: String in OS.get_environment("GLAN_ARENES").split(";", false):
		var q := part.split(":")
		main.start_battle({"enemies": q[1].split(","), "arena": q[0], "flee": true})
		await _until_menu()
		await _frames(50)
		await _shot("a%02d_%s" % [n, q[0]])
		n += 1
		await _flee()
		main.battle_ui._on_end("ok")
		await _frames(120)
	SaveManager.delete_save()
	get_tree().quit()
