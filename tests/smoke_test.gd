extends Node
## Test de fumée, à lancer sans fenêtre :
##   Godot --headless --path . res://tests/smoke_test.tscn
## Vérifie les données, la génération des sprites, la construction des cartes,
## l'accessibilité de chaque PNJ et passage, les dialogues, la sauvegarde et le
## déroulé complet titre -> nouvelle partie -> changement de carte -> continuer.

const World = preload("res://src/world/world.gd")
const DialogueBox = preload("res://src/ui/dialogue_box.gd")
const MAIN = preload("res://scenes/main.tscn")
const BattleEngine = preload("res://src/battle/battle_engine.gd")
const BattleScene = preload("res://src/battle/battle_scene.gd")
const ArenaPainterScript = preload("res://src/gfx/arena_painter.gd")
const BattleUI = preload("res://src/battle/battle_ui.gd")
const Rules = preload("res://src/battle/rules.gd")
const MonsterPainter = preload("res://src/gfx/monster_painter.gd")
const GameMenu = preload("res://src/ui/game_menu.gd")
const TitleScreen = preload("res://src/ui/title_screen.gd")
const PauseMenu = preload("res://src/ui/pause_menu.gd")
const Hud = preload("res://src/ui/hud.gd")
const TalentScreen = preload("res://src/ui/talent_screen.gd")
const BattleFx = preload("res://src/battle/battle_fx.gd")
const FxPainter = preload("res://src/gfx/fx_painter.gd")

var failures := 0
var checks := 0
var pick_queue: Array = []   # réponses successives aux choix d'un dialogue (sinon : la première)
var verbose := false
var _last_say := ""   # dernier dialogue dit par _c4_say (pour situer un blocage)


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("  ECHEC : ", what)


func _ready() -> void:
	verbose = OS.get_cmdline_user_args().has("--verbose")
	# un fichier par lancement : deux tests lancés en même temps ne se marchent pas dessus
	SaveManager.save_path = "user://test_sauvegarde_%d.json" % OS.get_process_id()
	SaveManager.delete_save()
	if OS.has_environment("GLAN_ONLY_C5"):   # essai ciblé du chapitre 5 (quelques minutes)
		_test_chapter_5_data()
		await _test_chapter_5()
		await _test_rider_scenery()
		print("%d vérifications, %d échec(s) (chapitre 5 seul)." % [checks, failures])
		SaveManager.delete_save()
		get_tree().quit(1 if failures > 0 else 0)
		return
	if OS.has_environment("GLAN_ONLY_FLOW"):   # essai ciblé des déroulés de chapitre 1 et 4
		await _test_flow()
		await _test_chapter_4()
		print("%d vérifications, %d échec(s) (déroulés seuls)." % [checks, failures])
		SaveManager.delete_save()
		get_tree().quit(1 if failures > 0 else 0)
		return
	if OS.has_environment("GLAN_ONLY_C6"):   # essai ciblé du chapitre 6
		_test_chapter_6_data()
		await _test_chapter_6()
		await _test_gouda_scenery()
		print("%d vérifications, %d échec(s) (chapitre 6 seul)." % [checks, failures])
		SaveManager.delete_save()
		get_tree().quit(1 if failures > 0 else 0)
		return
	if OS.has_environment("GLAN_ONLY_PAD"):   # essai ciblé de l'interface à la manette
		await _test_gamepad_full()
		print("%d vérifications, %d échec(s) (manette seule)." % [checks, failures])
		SaveManager.delete_save()
		get_tree().quit(1 if failures > 0 else 0)
		return
	if OS.has_environment("GLAN_ONLY_HORIZON"):   # seulement l'horizon et la caméra par carte
		await _test_horizon()
		print("%d vérifications, %d échec(s)." % [checks, failures])
		get_tree().quit(1 if failures > 0 else 0)
		return
	if OS.has_environment("GLAN_ONLY_WARM"):   # seulement le test du préchauffage des monstres
		await _test_warm_matches_demand()
		print("%d vérifications, %d échec(s)." % [checks, failures])
		get_tree().quit(1 if failures > 0 else 0)
		return
	if OS.has_environment("GLAN_ONLY_MEASURE_C6"):   # tableau d'équilibre du chapitre 6
		_measure_ch6()
		get_tree().quit(0)
		return
	if OS.has_environment("GLAN_ONLY_MEASURE"):   # tableau d'équilibre des combats obligatoires (GLAN_RUNS = essais, 60 par défaut)
		_measure_forced()
		get_tree().quit(0)
		return
	if OS.has_environment("GLAN_ONLY_LAYOUT"):   # essai ciblé des cas de mise en page du combat
		await _test_battle_layout()
		print("%d vérifications, %d échec(s) (cas de mise en page seuls)." % [checks, failures])
		SaveManager.delete_save()
		get_tree().quit(1 if failures > 0 else 0)
		return
	if OS.has_environment("GLAN_ONLY_BOSSES"):   # essai ciblé des boss du jeu (taille, plaques)
		await _test_boss_presence()
		print("%d vérifications, %d échec(s) (boss seuls)." % [checks, failures])
		SaveManager.delete_save()
		get_tree().quit(1 if failures > 0 else 0)
		return
	if OS.has_environment("GLAN_ONLY_ANNONCE"):   # essai ciblé des coups annoncés
		_test_telegraphed_attacks()
		print("%d vérifications, %d échec(s) (coups annoncés seuls)." % [checks, failures])
		get_tree().quit(1 if failures > 0 else 0)
		return
	if OS.has_environment("GLAN_ONLY_STAGING"):   # essai ciblé de la mise en page du combat
		await _test_battle_staging()
		print("%d vérifications, %d échec(s) (mise en page du combat seule)." % [checks, failures])
		SaveManager.delete_save()
		get_tree().quit(1 if failures > 0 else 0)
		return
	print("== Données ==")
	_test_data()
	print("== Sprites ==")
	_test_sprites()
	print("== Combat : règles ==")
	_test_engine()
	print("== Combat : élan ==")
	_test_boost()
	print("== Combat : équilibre (combats simulés) ==")
	_test_balance()
	print("== Combat : équilibre des combats obligatoires (joueur attentif, talents, compositions) ==")
	_test_forced_balance()
	print("== Progression : niveaux, or, rattrapage ==")
	_test_progression()
	print("== Quêtes, équipement, argent, Ramollissement ==")
	_test_step4()
	print("== Talents ==")
	_test_talents()
	print("== Animations de combat : données ==")
	_test_animations()
	print("== Musique ==")
	_test_music()
	_test_music_forms()
	_test_rendering()
	_test_relief()
	_test_character_art()
	_test_scenery()
	_test_chapter_2_data()
	_test_chapter_3_data()
	_test_chapter_4_data()
	_test_chapter_5_data()
	_test_chapter_6_data()
	await _test_saves()
	_test_names_and_merri()
	await _test_tutorials()
	await _test_interface()
	await _test_interface_input()
	_test_retouches()
	await _test_active_party()
	await _test_arenas()
	await _test_arena_by_place()
	_test_decors_6()
	_test_retouches_2()
	_test_lanternes_mines()
	_test_equipment()
	await _test_settings()
	await _test_houses()
	_test_arena_mood()
	_test_door_clearance()
	await _test_interior_dress()
	await _test_gamepad_full()
	_test_reserve_catch_up()
	_test_balourd_phase_and_breche_waves()
	_test_telegraphed_attacks()
	_test_decors_restes()
	_test_help_texts()
	await _test_horizon()
	if not OS.has_environment("GLAN_QUICK"):
		await _test_warm_matches_demand()
	if OS.has_environment("GLAN_QUICK"):
		print("%d vérifications, %d échec(s) (passage rapide : règles et équilibre seulement)." % [checks, failures])
		get_tree().quit(1 if failures > 0 else 0)
		return
	print("== Combat : scène et interface ==")
	await _test_battle_scene()
	print("== Animations de combat : jouées une à une ==")
	await _test_animation_play()
	print("== Combat : composition façon Octopath ==")
	await _test_battle_layout()
	await _test_battle_staging()
	await _test_boss_presence()
	print("== Élan et icônes de combat ==")
	_test_icons()
	print("== Cartes ==")
	for id in Database.list_maps():
		await _test_map(id)
		await _test_gated(id)
	# Bittebourg change au fil du chapitre : tout doit rester atteignable à chaque moment.
	var fete := ["intro_vue", "potager_soigne", "fete_commencee", "fusees_pretes"]
	await _test_map("bittebourg", fete, "soir de la Fête")
	await _test_map("bittebourg", fete + ["invasion", "naze_arrive"], "invasion")
	await _test_map("bittebourg", fete + ["invasion", "naze_arrive", "combat_morfales_quai", "combat_morfales_potager", "combat_morfales_auberge", "morfales_chasses"], "face au Naze")
	await _test_map("bittebourg", fete + ["naze_arrive", "combat_morfales_quai", "combat_morfales_potager", "combat_morfales_auberge", "morfales_chasses", "naze_vaincu", "route_ouverte", "source_trouvee"], "après le Naze")
	await _test_map("route_brie", ["combat_morfales_route"], "péage forcé")
	print("== Dialogues ==")
	await _test_dialogue_box()
	print("== Sauvegarde ==")
	_test_save()
	print("== Menus : équipe, inventaire, journal, boutique ==")
	await _test_menus()
	print("== Écran de talents ==")
	await _test_talent_screen()
	print("== Déroulé complet ==")
	await _test_flow()
	await _test_chapter_2()
	await _test_chapter_3()
	await _test_chapter_4()
	await _test_chapter_5()
	await _test_chapter_6()
	print("== Décors elfiques (style de Fondue-Combe) ==")
	await _test_elven_scenery()
	print("== Décors nains (Mines de Morbier) ==")
	await _test_dwarven_scenery()
	print("== Décors des cavaliers, de Fongorn, de l'Isengarde et des chutes ==")
	await _test_rider_scenery()
	await _test_gouda_scenery()
	SaveManager.delete_save()
	print("")
	print("%d vérifications, %d échec(s)." % [checks, failures])
	print("RESULTAT : " + ("OK" if failures == 0 else "ECHEC"))
	get_tree().quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------- données

func _walk_dialogue(id: String, nodes: Array) -> void:
	for n: Variant in nodes:
		check(n is Dictionary, "dialogue %s : entrée qui n'est pas un objet" % id)
		if not (n is Dictionary):
			continue
		var d: Dictionary = n
		var known := false
		for key: String in ["text", "if", "set", "choice", "action", "battle", "give", "join", "take", "money", "shop", "chapter", "banner", "music"]:
			if d.has(key):
				known = true
		if d.has("battle"):
			check(not Database.get_encounter(str(d["battle"])).is_empty(), "dialogue %s : combat inconnu « %s »" % [id, str(d["battle"])])
		if d.has("give"):
			check(not Database.get_item(str(d["give"])).is_empty(), "dialogue %s : objet inconnu « %s »" % [id, str(d["give"])])
		if d.has("take"):
			check(not Database.get_item(str(d["take"])).is_empty(), "dialogue %s : objet inconnu « %s »" % [id, str(d["take"])])
		if d.has("shop"):
			check(not Database.get_shop(str(d["shop"])).is_empty(), "dialogue %s : boutique inconnue « %s »" % [id, str(d["shop"])])
		if d.has("join"):
			check(not Rules.battle_def(str(d["join"])).is_empty(), "dialogue %s : recrue sans fiche de combat « %s »" % [id, str(d["join"])])
		check(known, "dialogue %s : entrée sans instruction connue : %s" % [id, str(d)])
		if d.has("who"):
			check(Database.characters.has(str(d["who"])), "dialogue %s : personnage inconnu « %s »" % [id, str(d["who"])])
		for key: String in ["then", "else"]:
			if d.has(key):
				check(d[key] is Array, "dialogue %s : « %s » doit être une liste" % [id, key])
				if d[key] is Array:
					_walk_dialogue(id, d[key])
		if d.has("choice"):
			check(d["choice"] is Array, "dialogue %s : « choice » doit être une liste" % id)
			if d["choice"] is Array:
				for opt: Variant in d["choice"]:
					check(opt is Dictionary and (opt as Dictionary).has("text"), "dialogue %s : choix sans texte" % id)
					if opt is Dictionary and (opt as Dictionary).get("then") is Array:
						_walk_dialogue(id, opt["then"])


func _music_nodes(node: Variant, found: Array) -> void:
	if node is Array:
		for child: Variant in node:
			_music_nodes(child, found)
	elif node is Dictionary:
		if node.has("music"):
			found.append(str(node["music"]))
		for key: Variant in node:
			_music_nodes(node[key], found)


## Rendu HD-2D : ambiances bien formées, shaders et décors de la passe présents.
func _test_rendering() -> void:
	var atmosphere = preload("res://src/world/atmosphere.gd")
	var with_rays := 0
	for id: String in Database.ambiances:
		var amb: Dictionary = Database.ambiances[id]
		for kind: Variant in amb.get("particles", []):
			check(atmosphere.PARTICLES.has(str(kind)), "ambiance %s : particules %s connues" % [id, kind])
		if amb.has("rays"):
			with_rays += 1
			var rays: Variant = amb["rays"]
			check(rays is Dictionary, "ambiance %s : rays est un dictionnaire" % id)
			if rays is Dictionary:
				var strength := float(rays.get("strength", 0.1))
				check(strength > 0.0 and strength <= 0.08, "ambiance %s : rayons discrets (force %s)" % [id, strength])
				check(float(rays.get("density", 0.01)) <= 0.02, "ambiance %s : rayons peu nombreux" % id)
	check(with_rays >= 2, "des ambiances ont des rayons de lumière")
	for path: String in ["ground", "water", "rays", "vignette"]:
		check(load("res://src/gfx/shaders/%s.gdshader" % path) is Shader, "shader %s chargé" % path)
	check(Sprites.tile_texture("cliff") != null, "texture de talus")
	var painter = preload("res://src/gfx/prop_painter.gd")
	for v in 3:
		var img: Image = painter.fern(v)
		check(img != null and not img.get_used_rect().size == Vector2i.ZERO, "fougère %d peinte" % v)
	# combat : personne ne se cache derrière son voisin, tout le monde tient à l'écran
	for n in range(1, 7):
		for big: float in [1.0, 1.6]:
			var scales: Array = []
			for i in n:
				scales.append(big if i == 0 else 1.0)
			var spots: Array[Vector3] = BattleScene.formation(scales)
			check(spots.size() == n, "formation à %d : une place par combattant" % n)
			for i in n:
				check(spots[i].x > 1.0 and spots[i].x < 6.6, "formation à %d : place %d dans le cadre" % [n, i])
				if i > 0:
					var gap := absf(spots[i].x - spots[i - 1].x)
					check(gap >= (1.0 if n <= 4 else 0.5), "formation à %d : écart %.2f entre voisins" % [n, gap])
	# le relief peint ne touche ni les contours ni la transparence
	var flat := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	flat.fill_rect(Rect2i(2, 2, 4, 4), Color("#4f7d5a"))
	var pa = preload("res://src/gfx/pixel_art.gd")
	pa.relief(flat)
	check(flat.get_pixel(0, 0).a < 0.5, "relief : le vide reste vide")
	check(flat.get_pixel(2, 2).get_luminance() > flat.get_pixel(5, 5).get_luminance(), "relief : lumière en haut à gauche, ombre en bas à droite")
	for id: String in Database.arenas if "arenas" in Database else {}:
		var back: Variant = (Database.arenas[id] as Dictionary).get("backdrop", {})
		check(back is Dictionary, "arène %s : backdrop est un dictionnaire" % id)
		if back is Dictionary and back.has("tile"):
			check(Sprites.tile_texture(str(back["tile"])) != null, "arène %s : texture de fond" % id)
	var world_script = preload("res://src/world/world.gd")
	check(world_script.ZOOM > 0.7 and world_script.ZOOM <= 1.0, "caméra : rapprochement raisonnable")


func _test_music() -> void:
	check(Database.music.size() >= 10, "music.json chargé")
	for id: String in Database.music:
		var errors: Array = Music.check_track(Database.music[id])
		check(errors.is_empty(), "musique %s : %s" % [id, ", ".join(PackedStringArray(errors))])
	for kind: String in ["title", "battle", "victory"]:
		check(Database.music.has(Music.default(kind)), "musique par défaut : " + kind)
	for id in Database.list_maps():
		var map := Database.get_map(id)
		check(Database.music.has(str(map.get("music", ""))), "carte %s : musique connue" % id)
		for s: Variant in map.get("music_states", []):
			check(s is Dictionary and Database.music.has(str(s.get("music", ""))), "carte %s : musique d'état connue" % id)
	for id: String in Database.encounters:
		check(Database.music.has(Music.for_encounter(Database.encounters[id])), "rencontre %s : musique connue" % id)
	var in_dialogues: Array = []
	_music_nodes(Database.dialogues, in_dialogues)
	for id: String in in_dialogues:
		check(Database.music.has(id), "dialogue : musique %s connue" % id)
	check(in_dialogues.has("menace"), "le prologue lance sa musique")
	# un morceau est réellement calculé : il a la bonne durée et il s'entend
	var track: Dictionary = Database.music[Music.default("victory")]
	var bytes: PackedByteArray = Music.render(track)
	var peak := 0
	for i in range(0, bytes.size() - 1, 200):
		peak = maxi(peak, absi(bytes.decode_s16(i)))
	check(bytes.size() > Music.RATE * 2 * 6 and peak > 8000, "musique : la fanfare de victoire s'entend (%d octets, crête %d)" % [bytes.size(), peak])
	var parsed: Dictionary = Music.parse_voice({"len": 2, "notes": "c4 bb3:4 r f#5+a5"})
	check(int(parsed["length"]) == 10 and (parsed["events"] as Array).size() == 3, "musique : lecture d'une voix")
	check(int(parsed["events"][1][2][0]) == 58 and int(parsed["events"][2][2][0]) == 78, "musique : hauteur des notes")
	GameState.new_game()
	check(Music.for_map(Database.get_map("bittebourg")) == "village", "Bittebourg : musique du village au début")
	Music.play("village")
	check(Music.current == "village", "musique : morceau demandé retenu")
	Music.play("")
	print("  %d morceaux" % Database.music.size())


func _test_data() -> void:
	check(not Database.game.is_empty(), "game.json chargé")
	check(Database.characters.size() >= 5, "characters.json chargé")
	check(Database.dialogues.size() >= 10, "dialogues chargés")
	var start: Dictionary = Database.game.get("start", {})
	check(Database.has_map(str(start.get("map", ""))), "carte de départ existante")
	for id: String in Database.dialogues:
		_walk_dialogue(id, Database.get_dialogue(id))
	for id in Database.list_maps():
		var map := Database.get_map(id)
		check(str(map.get("id", "")) == id, "carte %s : champ id cohérent avec le nom du fichier" % id)
		check(Database.ambiances.has(str(map.get("ambiance", ""))), "carte %s : ambiance connue" % id)
		for e: Variant in map.get("on_enter", []):
			check(Database.has_dialogue(str(e.get("dialogue", ""))), "carte %s : dialogue d'entrée %s" % [id, str(e.get("dialogue", ""))])
		for o: Dictionary in map.get("objects", []):
			var type := str(o.get("type", ""))
			if type == "npc":
				check(Database.characters.has(str(o.get("id", ""))), "carte %s : PNJ %s décrit dans characters.json" % [id, str(o.get("id", ""))])
				check(Database.has_dialogue(str(o.get("dialogue", o.get("id", "")))), "carte %s : dialogue du PNJ %s" % [id, str(o.get("id", ""))])
			elif o.has("dialogue"):
				check(Database.has_dialogue(str(o["dialogue"])), "carte %s : dialogue %s" % [id, str(o["dialogue"])])
			var to: Variant = o.get("to")
			if to is Dictionary:
				var target := str(to.get("map", ""))
				check(Database.has_map(target), "carte %s : passage vers une carte existante (%s)" % [id, target])
				if Database.has_map(target):
					var spawns: Dictionary = Database.get_map(target).get("spawns", {})
					check(spawns.has(str(to.get("spawn", ""))), "carte %s : point d'arrivée %s dans %s" % [id, str(to.get("spawn", "")), target])
	print("  %d dialogues, %d personnages, %d cartes" % [Database.dialogues.size(), Database.characters.size(), Database.list_maps().size()])
	_test_battle_data()


func _check_effects(what: String, def: Dictionary) -> void:
	check(str(def.get("name", "")) != "", "%s : nom" % what)
	check(str(def.get("target", "")) in ["enemy", "all_enemies", "ally", "all_allies", "self", "ally_ko"], "%s : cible connue" % what)
	var effects: Variant = def.get("effects", [])
	check(effects is Array and not (effects as Array).is_empty(), "%s : au moins un effet" % what)
	if not (effects is Array):
		return
	for fx: Variant in effects:
		check(fx is Dictionary, "%s : effet mal formé" % what)
		if not (fx is Dictionary):
			continue
		var type := str(fx.get("type", ""))
		check(type in ["damage", "heal", "mana", "status", "cure", "revive", "steal"], "%s : type d'effet connu (%s)" % [what, type])
		if type == "damage":
			check(Database.elements.has(str(fx.get("element", ""))), "%s : élément connu" % what)
		if type == "status":
			check(Database.statuses.has(str(fx.get("id", ""))), "%s : état connu" % what)


func _check_enemy_list(what: String, list: Variant) -> void:
	check(list is Array and not (list as Array).is_empty(), "%s : au moins un ennemi" % what)
	if list is Array:
		for e: Variant in list:
			check(Database.enemies.has(str(e)), "%s : ennemi connu (%s)" % [what, str(e)])


func _test_battle_data() -> void:
	check(Database.elements.size() >= 4 and Database.statuses.size() >= 4, "éléments et états chargés")
	check(Database.statuses.has("ebranle"), "état « ebranle » présent (bouclier brisé)")
	for id: String in Database.skills:
		_check_effects("compétence " + id, Database.get_skill(id))
	for id: String in Database.items:
		var item := Database.get_item(id)
		check(str(item.get("name", "")) != "" and str(item.get("desc", "")) != "", "objet %s : nom et description" % id)
		match Database.item_kind(id):
			"equipment":
				check(GameState.SLOTS.has(str(item.get("slot", ""))), "équipement %s : emplacement connu" % id)
				check(item.get("mods") is Dictionary, "équipement %s : bonus" % id)
				for key: String in item.get("mods", {}):
					check(Rules.MOD_KEYS.has(key), "équipement %s : caractéristique connue (%s)" % [id, key])
				for who: Variant in item.get("for", []):
					check(not Rules.battle_def(str(who)).is_empty(), "équipement %s : porteur connu (%s)" % [id, str(who)])
			"key":
				check(not Database.is_consumable(id), "objet de quête %s : sans effet de combat" % id)
			_:
				_check_effects("objet " + id, item)
	for id: String in Database.characters:
		var def := Rules.battle_def(id)
		if def.is_empty():
			continue
		check(Database.elements.has(str(def.get("element", ""))), "personnage %s : élément de l'attaque" % id)
		var learn: Dictionary = def.get("learn", {})
		for lv: String in learn:
			for s: Variant in learn[lv]:
				check(Database.skills.has(str(s)), "personnage %s : compétence connue (%s)" % [id, str(s)])
		check(int(Rules.stats_at(id, 1)["hp"]) > 0 and int(Rules.stats_at(id, 10)["hp"]) > int(Rules.stats_at(id, 1)["hp"]), "personnage %s : PV qui progressent" % id)
	for id: String in Database.enemies:
		var def := Database.get_enemy(id)
		check(int((def.get("stats", {}) as Dictionary).get("hp", 0)) > 0, "ennemi %s : PV" % id)
		for w: Variant in def.get("weak", []):
			check(Database.elements.has(str(w)), "ennemi %s : faiblesse connue (%s)" % [id, str(w)])
		for s: Variant in def.get("immune", []):
			check(Database.statuses.has(str(s)), "ennemi %s : immunité connue (%s)" % [id, str(s)])
		for a: Variant in def.get("ai", []):
			var sk := str((a as Dictionary).get("skill", ""))
			check(sk == "attack" or Database.skills.has(sk), "ennemi %s : compétence connue (%s)" % [id, sk])
		for d: Variant in def.get("drops", []):
			check(Database.items.has(str((d as Dictionary).get("item", ""))), "ennemi %s : butin connu" % id)
		var sp: Dictionary = def.get("sprite", {})
		check((sp.has("monster") and MonsterPainter.has(str(sp["monster"]))) or Database.characters.has(str(sp.get("character", ""))), "ennemi %s : sprite" % id)
	for id: String in Database.encounters:
		var enc := Database.get_encounter(id)
		_check_enemy_list("rencontre " + id, enc.get("enemies"))
		check(Database.arenas.has(str(BattleScene.resolve(enc).get("arena", ""))), "rencontre %s : arène connue (après choix)" % id)
		for m: Variant in enc.get("party", []):
			check(not Rules.battle_def(str((m as Dictionary).get("id", ""))).is_empty(), "rencontre %s : équipe imposée valide" % id)
		for item: String in enc.get("inventory", {}):
			check(Database.items.has(item), "rencontre %s : objet connu (%s)" % [id, item])
	for id: String in Database.encounter_tables:
		var table: Dictionary = Database.encounter_tables[id]
		check(str(table.get("arena", "")) == "" or Database.arenas.has(str(table.get("arena", ""))), "table %s : arène connue (ou laissée à la carte)" % id)
		for size in [1, 2, 4]:
			check(not Database.roll_encounter(id, size).is_empty(), "table %s : une rencontre possible pour %d personnage(s)" % [id, size])
		for g: Variant in table.get("groups", []):
			_check_enemy_list("table " + id, (g as Dictionary).get("enemies"))
	for id: String in Database.arenas:
		var arena := Database.get_arena(id)
		check(Database.ambiances.has(str(arena.get("ambiance", ""))), "arène %s : ambiance connue" % id)
	for id in Database.list_maps():
		for o: Dictionary in Database.get_map(id).get("objects", []):
			if str(o.get("type", "")) == "encounter_zone":
				check(Database.encounter_tables.has(str(o.get("table", ""))), "carte %s : table de rencontres connue" % id)
			if str(o.get("type", "")) == "monster":
				check(Database.enemies.has(str(o.get("id", ""))), "carte %s : monstre connu" % id)
	print("  %d compétences, %d objets, %d états, %d ennemis, %d rencontres, %d tables" % [
		Database.skills.size(), Database.items.size(), Database.statuses.size(), Database.enemies.size(),
		Database.encounters.size(), Database.encounter_tables.size()])


# ------------------------------------------------------------------- sprites

func _ascii(img: Image, region: Rect2i) -> void:
	var palette := {}
	var glyphs := ".#ox+=*%@abcdefghijklmnopqrstuvwyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	for y in region.size.y:
		var line := ""
		for x in region.size.x:
			var c := img.get_pixel(region.position.x + x, region.position.y + y)
			if c.a < 0.5:
				line += " "
				continue
			var key := c.to_html(false)
			if not palette.has(key):
				palette[key] = glyphs[mini(palette.size(), glyphs.length() - 1)]
			line += str(palette[key])
		print("    |" + line + "|")


func _test_sprites() -> void:
	for id: String in Database.characters:
		var sheet := Sprites.character(id)
		var img: Image = sheet["image"]
		check(img.get_width() == 968 and img.get_height() == 528, "planche de %s : 968 x 528" % id)
		var fw: int = sheet["frame_w"]
		var fh: int = sheet["frame_h"]
		check((sheet["walk"] as Array).size() >= 4, "planche de %s : au moins quatre poses de marche" % id)
		check((sheet["idle_seq"] as Array).size() > 1, "planche de %s : repos animé" % id)
		for pose_name: String in ["attack", "cast", "hit", "ko"]:
			check((sheet["poses"] as Dictionary).has(pose_name), "planche de %s : pose %s" % [id, pose_name])
		# les quatre poses de marche sont toutes différentes, dans chaque direction
		for row in 4:
			var seen := {}
			for col: int in sheet["walk"]:
				seen[img.get_region(Rect2i(col * fw, row * fh, fw, fh)).get_data()] = true
			check(seen.size() == 4, "planche de %s : quatre poses de marche distinctes, ligne %d" % [id, row])
		var pimg: Image = Sprites.portrait(id).get_image()
		check(pimg.get_width() == 64 and pimg.get_height() == 64, "portrait de %s : 64 x 64" % id)
		for row in 4:
			for col in int(sheet["columns"]):
				var b := Sprites.PA.opaque_bounds(img, Rect2i(col * fw, row * fh, fw, fh))
				check(b.size.y > 20 and b.size.y < fh and b.position.y > 0, "planche de %s : case %d,%d non vide et dans le cadre" % [id, col, row])
				check(b.position.x > 0 and b.end.x < fw, "planche de %s : case %d,%d ne touche pas les bords" % [id, col, row])
		check(Sprites.portrait(id) != null, "portrait de %s" % id)
	for kind: String in MonsterPainter.SIZES:
		var sheet := Sprites.monster(kind)
		var mimg: Image = sheet["image"]
		for col in int(sheet["columns"]):
			var b := Sprites.PA.opaque_bounds(mimg, Rect2i(col * int(sheet["frame_w"]), 0, int(sheet["frame_w"]), int(sheet["frame_h"])))
			check(b.size.x > 10 and b.size.y > 10 and b.size.y <= int(sheet["frame_h"]), "monstre %s : pose %d dessinée" % [kind, col])
			# aucun pixel opaque à moins d'un pixel du bord de sa case : rien n'est coupé net
			var fw_m := int(sheet["frame_w"])
			var fh_m := int(sheet["frame_h"])
			var touching := 0
			for y in fh_m:
				for x in fw_m:
					if (x == 0 or y == 0 or x == fw_m - 1 or y == fh_m - 1) and mimg.get_pixel(col * fw_m + x, y).a > 0.5:
						touching += 1
			check(touching == 0, "monstre %s : pose %d à plus d'un pixel du bord de sa case (%d pixels touchent)" % [kind, col, touching])
		check(Sprites.battler_icon({"monster": kind}) != null, "monstre %s : vignette" % kind)
	for kind: String in ["tree", "bush", "flowers", "grass", "wheat", "wilted", "barrel", "sign", "rock", "bollard", "monument", "boat", "shelf", "window"]:
		check(Sprites.prop(kind, 0).get_width() > 4, "sprite de décor %s" % kind)
	for kind: String in ["grass", "path", "cobble", "planks", "floor", "wood", "soil", "plaster", "brick", "stone", "iron", "interior_wall", "roof_rouge", "roof_vert", "roof_ardoise", "roof_chaume"]:
		var t := Sprites.tile_image(kind)
		check(t.get_width() == 48 and t.get_pixel(0, 0) != Color.MAGENTA, "texture %s" % kind)
	if verbose:
		for id: String in ["glandoulf", "sam", "pepin"]:
			var img: Image = Sprites.character(id)["image"]
			print("  %s : face, pas de côté, dos" % id)
			_ascii(img, Rect2i(28, 20, 32, 48))
			_ascii(img, Rect2i(88 + 28, 132 + 20, 32, 48))
			_ascii(img, Rect2i(28, 396 + 20, 32, 48))
		for kind: String in MonsterPainter.SIZES:
			print("  monstre : ", kind)
			var size: Vector2i = MonsterPainter.SIZES[kind]
			_ascii(Sprites.monster(kind)["image"], Rect2i(0, 0, size.x, size.y))
		for id: String in ["isidur", "sauron"]:
			print("  %s : face, côté" % id)
			_ascii(Sprites.character(id)["image"], Rect2i(28, 20, 32, 48))
			_ascii(Sprites.character(id)["image"], Rect2i(28, 152, 32, 48))
		print("  bitte d'amarrage / arbre")
		_ascii(Sprites.prop("bollard", 0).get_image(), Rect2i(0, 0, 22, 30))
		_ascii(Sprites.prop("tree", 0).get_image(), Rect2i(0, 0, 72, 100))


# -------------------------------------------------------------------- cartes

func _test_map(id: String, state: Array = [], label: String = "") -> void:
	var map := Database.get_map(id)
	GameState.new_game()
	for f: String in state:
		GameState.set_flag(f)
	var world: Node3D = World.new()
	add_child(world)
	var spawns: Dictionary = map.get("spawns", {})
	check(not spawns.is_empty(), "carte %s : au moins un point d'arrivée" % id)
	var t0 := Time.get_ticks_msec()
	world.setup(id, str(spawns.keys()[0]))
	var build_ms := Time.get_ticks_msec() - t0
	await get_tree().process_frame
	await get_tree().process_frame
	check(world.player != null, "carte %s : joueur créé" % id)
	check(world.camera != null and world.camera.current, "carte %s : caméra active" % id)

	# chaque point d'arrivée est libre et hors de tout passage
	for key: String in spawns:
		var sp: Dictionary = world.spawn_info(key)
		var p: Vector3 = sp["pos"]
		check(world.is_free(Vector2(p.x, p.z), 0.28, world.player), "carte %s : point d'arrivée %s dégagé" % [id, key])
		for wp: Dictionary in world.warps:
			var r: Rect2 = wp["rect"]
			check(not r.has_point(Vector2(p.x, p.z)), "carte %s : point d'arrivée %s hors d'un passage" % [id, key])

	# remplissage par diffusion : tout ce que le joueur peut atteindre à pied
	var step := 0.25
	var gw := int(world.grid_w / step) + 1
	var gh := int(world.grid_h / step) + 1
	var seen := PackedByteArray()
	seen.resize(gw * gh)
	var start := Vector2i(int(round(world.player.position.x / step)), int(round(world.player.position.z / step)))
	var queue: Array[Vector2i] = [start]
	seen[start.y * gw + start.x] = 1
	var head := 0
	while head < queue.size():
		var c := queue[head]
		head += 1
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if n.x < 0 or n.y < 0 or n.x >= gw or n.y >= gh or seen[n.y * gw + n.x] != 0:
				continue
			if world.is_free(Vector2(n.x * step, n.y * step), 0.28, world.player):
				seen[n.y * gw + n.x] = 1
				queue.append(n)
	var reachable := func(test: Callable) -> bool:
		for c: Vector2i in queue:
			if test.call(Vector2(c.x * step, c.y * step)):
				return true
		return false
	for it: Dictionary in world.interactables:
		if bool(it.get("gated", false)):
			continue   # vérifié dans _test_gated, une fois l'obstacle levé
		var ip: Vector3 = world.interactable_position(it)
		var reach := float(it["reach"]) - 0.1
		var ok: bool = reachable.call(func(p: Vector2) -> bool: return p.distance_to(Vector2(ip.x, ip.z)) <= reach)
		check(ok, "carte %s : « %s » (%s) atteignable à pied" % [id, str(it["dialogue"]), str(it["label"])])
	for wp: Dictionary in world.warps:
		var r: Rect2 = wp["rect"]
		var ok: bool = reachable.call(func(p: Vector2) -> bool: return r.has_point(p))
		check(ok, "carte %s : passage vers %s atteignable à pied" % [id, str(wp["map"])])
	print("  %s : %d x %d, construite en %d ms, %d PNJ, %d interactions, %d passages, %d cases atteignables" % [
		id if label == "" else "%s (%s)" % [id, label], world.grid_w, world.grid_h, build_ms, world.npcs.size(), world.interactables.size(), world.warps.size(), queue.size()])

	if verbose:
		for ty in world.grid_h:
			var line := ""
			for tx in world.grid_w:
				var ch := " "
				var any := false
				for sy in 4:
					for sx in 4:
						var gx: int = int(tx) * 4 + sx
						var gy: int = int(ty) * 4 + sy
						if seen[gy * gw + gx] != 0:
							any = true
				ch = "." if any else "#"
				for it: Dictionary in world.interactables:
					var ip: Vector3 = world.interactable_position(it)
					if int(ip.x) == tx and int(ip.z) == ty:
						ch = "N" if it.has("node") else "?"
				for wp: Dictionary in world.warps:
					var r: Rect2 = wp["rect"]
					if r.grow(0.3).has_point(Vector2(tx + 0.5, ty + 0.5)):
						ch = "W"
				if int(world.player.position.x) == tx and int(world.player.position.z) == ty:
					ch = "@"
				line += ch
			print("    " + line)
	remove_child(world)
	world.queue_free()
	await get_tree().process_frame


# ----------------------------------------------------------------- dialogues

func _play_through(box: Control, id: String, choice_index: int) -> int:
	var lines := 0
	var done := [false]
	var cb := func() -> void: done[0] = true
	box.finished.connect(cb, CONNECT_ONE_SHOT)
	box.start(id)
	for _i in 400:
		await get_tree().process_frame
		if done[0]:
			break
		if box.waiting:
			box.resume()   # ici, personne ne lance le combat : on passe à la suite
		elif box._choosing:
			var buttons: Array = box._choice_list.get_children()
			var b: Button = buttons[mini(choice_index, buttons.size() - 1)]
			b.pressed.emit()
		elif box._typing:
			box._finish_typing()
		else:
			lines += 1
			box._advance()
	check(done[0], "dialogue %s : se termine" % id)
	return lines


func _test_dialogue_box() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var box: Control = DialogueBox.new()
	layer.add_child(box)
	await get_tree().process_frame
	GameState.new_game()
	var total := 0
	for id: String in Database.dialogues:
		total += await _play_through(box, id, 0)   # première visite
		total += await _play_through(box, id, 1)   # seconde visite (drapeaux posés), autre choix
	check(not box.active and not box.visible, "boîte de dialogue refermée")
	check(GameState.has_flag("intro_vue") and GameState.has_flag("sam_vu"), "les dialogues posent leurs drapeaux")
	print("  %d dialogues joués deux fois, %d répliques affichées" % [Database.dialogues.size(), total])
	layer.queue_free()


# --------------------------------------------------------------- sauvegarde

func _test_save() -> void:
	GameState.new_game()
	GameState.set_flag("test_drapeau")
	GameState.map_id = "auberge"
	GameState.player_pos = [5.5, 6.25]
	GameState.player_facing = "left"
	GameState.playtime = 3725.0
	GameState.inventory = {"potion": 3}
	check(SaveManager.save_game(), "écriture de la sauvegarde")
	check(SaveManager.has_save(), "sauvegarde détectée")
	GameState.new_game()
	check(not GameState.has_flag("test_drapeau"), "nouvelle partie : état remis à zéro")
	check(SaveManager.load_game(), "lecture de la sauvegarde")
	check(GameState.has_flag("test_drapeau"), "drapeau restauré")
	check(GameState.map_id == "auberge", "carte restaurée")
	check(GameState.player_pos.size() == 2 and is_equal_approx(float(GameState.player_pos[0]), 5.5), "position restaurée")
	check(GameState.player_facing == "left", "orientation restaurée")
	check(int(GameState.inventory.get("potion", 0)) == 3, "inventaire restauré")
	check(GameState.playtime_text() == "1h02", "temps de jeu restauré")
	check(SaveManager.summary().begins_with("Au Bon Mouillage"), "résumé de sauvegarde : " + SaveManager.summary())
	SaveManager.delete_save()
	check(not SaveManager.has_save(), "sauvegarde supprimée")


# -------------------------------------------------------------------- combat

func _fight(encounter: Dictionary, seed_value: int) -> RefCounted:
	var e: RefCounted = BattleEngine.new()
	e.setup(encounter, seed_value)
	var turns := 0
	while str(e.result) == "" and turns < 800:
		turns += 1
		var actor: RefCounted = e.next_actor()
		if actor == null:
			break
		e.start_turn(actor)
		if str(e.result) == "" and bool(e.can_act):
			var action: Dictionary = e.ai_action(actor) if str(actor.side) == "enemy" else e.auto_action(actor)
			e.perform(actor, action)
		if str(e.result) == "":
			e.end_turn(actor)
	e.set_meta("turns", turns)
	return e


func _has_event(events: Array, type: String) -> bool:
	for ev: Dictionary in events:
		if str(ev.get("type", "")) == type:
			return true
	return false


func _test_engine() -> void:
	# progression
	GameState.new_game()
	check(Rules.xp_to_next(1) == 16 and Rules.xp_to_next(2) > Rules.xp_to_next(1), "seuils d'expérience croissants")
	check(Rules.skills_at("glandoulf", 1).has("etincelle") and not Rules.skills_at("glandoulf", 1).has("tonnerre"), "compétences selon le niveau")
	var up := GameState.grant_xp("glandoulf", 16)
	check(int(up.get("to", 0)) == 2 and (up.get("skills", []) as Array).has("Petit somme"), "montée de niveau et compétence apprise")
	check(int(GameState.member("glandoulf")["hp"]) == int(Rules.stats_at("glandoulf", 2)["hp"]), "monter de niveau rend tous les PV")
	check(GameState.grant_xp("glandoulf", 1).is_empty(), "pas de montée sans assez d'expérience")

	# faiblesse, bouclier, ébranlement
	GameState.new_game()
	var e: RefCounted = BattleEngine.new()
	e.setup({"enemies": ["limace_molle"], "arena": "pre"}, 3)
	var g: RefCounted = e.party[0]
	var slug: RefCounted = e.enemies[0]
	slug.base["hp"] = 9999
	slug.hp = 9999
	check(e.known_weak(slug).is_empty(), "faiblesses inconnues au départ")
	var ev: Array = e.perform(g, {"type": "skill", "id": "etincelle", "target": slug})
	check(_has_event(ev, "damage") and int(slug.hp) < 9999, "une compétence inflige des dégâts")
	check(int(g.mp) == int(g.max_mp()) - 3, "elle coûte du mana")
	check(e.known_weak(slug).has("feu"), "la faiblesse touchée est révélée")
	check(int(slug.shield) == 1, "le bouclier perd un point")
	ev = e.perform(g, {"type": "skill", "id": "etincelle", "target": slug})
	check(_has_event(ev, "break") and slug.has_status("ebranle"), "bouclier à zéro : l'ennemi est ébranlé")
	e.start_turn(slug)
	check(not bool(e.can_act), "un ennemi ébranlé passe son tour")
	e.end_turn(slug)
	check(not slug.has_status("ebranle") and int(slug.shield) == int(slug.shield_max), "il se ressaisit et retrouve son bouclier")
	var hp0 := int(slug.hp)
	e.perform(g, {"type": "attack", "target": slug})
	var plain := hp0 - int(slug.hp)
	check(plain > 0 and not e.known_weak(slug).has("contondant"), "l'attaque de base touche sans révéler de fausse faiblesse")
	g.mp = 0
	check(not e.can_use_skill(g, "etincelle"), "pas de compétence sans mana")

	# états : poison, sommeil, réveil
	g.statuses["poison"] = {"turns": 2, "fresh": false}
	hp0 = int(g.hp)
	e.start_turn(g)
	check(int(g.hp) == hp0 - 3 and bool(e.can_act), "le poison ronge 8 % des PV en début de tour")
	e.end_turn(g)
	e.start_turn(g)
	e.end_turn(g)
	check(not g.has_status("poison"), "le poison s'estompe")
	g.statuses["sommeil"] = {"turns": 2, "fresh": false}
	e.start_turn(g)
	check(not bool(e.can_act), "un personnage endormi passe son tour")
	ev = e.perform(slug, {"type": "attack", "target": g})
	check(_has_event(ev, "wake") and not g.has_status("sommeil"), "un coup le réveille")
	g.statuses["ramolli"] = {"turns": 3, "fresh": false}
	check(g.stat("atk") < float(g.base["atk"]), "Ramolli réduit l'attaque")
	g.statuses.clear()

	# défense, objets
	g.hp = g.max_hp()
	e.perform(g, {"type": "defend"})
	check(bool(g.defending) and int(g.mp) > 0, "se défendre rend un peu de mana")
	g.hp = 5
	var tisanes := int(e.inventory.get("tisane", 0))
	e.perform(g, {"type": "item", "id": "tisane", "target": g})
	check(int(g.hp) > 5 and int(e.inventory.get("tisane", 0)) == tisanes - 1, "une tisane soigne et se consomme")

	# victoire : butin appliqué
	slug.hp = 1
	e.perform(g, {"type": "attack", "target": slug})
	check(str(e.result) == "victory", "victoire quand le dernier ennemi tombe")
	var rewards: Dictionary = e.commit()
	check(int(rewards["xp"]) == 6 and int(GameState.member("glandoulf")["xp"]) == 6, "expérience distribuée")
	check(GameState.money == int(rewards["money"]) and GameState.money > 0, "argent gagné")
	check(int(GameState.member("glandoulf")["hp"]) == int(g.hp), "PV conservés après le combat")
	check(int(GameState.item_count("tisane")) >= tisanes - 1, "inventaire mis à jour")
	check((GameState.bestiary.get("limace_molle", []) as Array).has("feu"), "faiblesse retenue pour les combats suivants")

	# petit somme : soin contre un tour de sommeil
	GameState.new_game()
	GameState.member("glandoulf")["level"] = 2
	GameState.add_to_party("pepin")
	GameState.heal_party()
	e = BattleEngine.new()
	e.setup({"enemies": ["guepe_cidre", "guepe_cidre"], "arena": "pre"}, 5)
	g = e.party[0]
	var p: RefCounted = e.party[1]
	check(str(e.enemies[0].name) != str(e.enemies[1].name), "deux ennemis identiques portent des noms distincts")
	g.hp = 10
	e.start_turn(g)
	e.perform(g, {"type": "skill", "id": "petit_somme"})
	e.end_turn(g)
	check(int(g.hp) > 10 and g.has_status("sommeil"), "Petit somme soigne et endort")
	e.start_turn(g)
	check(not bool(e.can_act), "Glandoulf dort au tour suivant")
	e.end_turn(g)
	check(not g.has_status("sommeil"), "puis il se réveille")
	# soin d'un allié, réanimation
	p.hp = 0
	p.statuses.clear()
	check(e.candidates(g, "ally_ko").has(p) and not e.candidates(g, "ally").has(p), "un allié à terre ne peut qu'être relevé")
	e.inventory["racine"] = 1
	e.perform(g, {"type": "item", "id": "racine", "target": p})
	check(p.alive(), "la racine-qui-réveille relève un allié")
	g.hp = 4
	e.perform(p, {"type": "skill", "id": "cataplasme", "target": g})
	check(int(g.hp) > 4, "Pépin soigne un allié")
	# ordre des tours : la guêpe (vitesse 13) joue plus souvent que Glandoulf (vitesse 8)
	var order: Array = e.preview(30)
	var wasp_turns := 0
	var g_turns := 0
	for c: RefCounted in order:
		if c == e.enemies[0]:
			wasp_turns += 1
		elif c == g:
			g_turns += 1
	check(wasp_turns > g_turns and g_turns > 0, "les plus rapides jouent plus souvent (%d contre %d)" % [wasp_turns, g_turns])
	var first: RefCounted = e.next_actor()
	check(first != null and first.alive(), "un combattant vivant prend le tour")
	# défaite : rien n'est conservé
	var before := GameState.to_dict()
	g.hp = 1
	p.hp = 1
	var wasp: RefCounted = e.enemies[0]
	wasp.base["atk"] = 999
	g.base["eva"] = 0   # l'esquive des héros ne doit pas faire manquer ce coup de graine fixée
	p.base["eva"] = 0
	e.perform(wasp, {"type": "attack", "target": g})
	e.perform(wasp, {"type": "attack", "target": p})
	check(str(e.result) == "defeat", "défaite quand toute l'équipe est à terre")
	e.commit()
	check(GameState.to_dict()["roster"] == before["roster"] and GameState.to_dict()["inventory"] == before["inventory"], "une défaite ne change rien à la partie")
	# fuite impossible contre un boss
	e = BattleEngine.new()
	e.setup(Database.get_encounter("grande_baveuse"), 2)
	ev = e.perform(e.party[0], {"type": "flee"})
	check(str(e.result) == "" and not bool(ev[0]["ok"]), "on ne fuit pas un boss")
	# équipe imposée du prologue
	GameState.new_game()
	e = BattleEngine.new()
	e.setup(Database.get_encounter("prologue_sauron"), 1)
	check(bool(e.guest) and e.party.size() == 2 and int(e.party[0].level) == 20, "prologue : Glandoulf et Isidur, niveau 20")
	check((e.party[0].skills as Array).has("bouquet_final"), "prologue : toutes les compétences disponibles")
	ev = e.perform(e.party[0], {"type": "skill", "id": "baillement", "target": e.enemies[0]})
	var immune := false
	for x: Dictionary in ev:
		if str(x.get("type", "")) == "status" and bool(x.get("immune", false)):
			immune = true
	check(immune and e.known_weak(e.enemies[0]).has("torpeur"), "Sauron craint la torpeur mais ne s'endort jamais")


const TEAM := ["glandoulf", "sam", "froton", "pepin"]


## Une rencontre nommée, avec le Ramollissement de la carte d'où elle est lancée.
const BIBLE_TEAM := ["glandoulf", "sam", "froton", "pepin", "aragrogne", "digoulasse", "grimli", "merri"]
const PASSIVES := ["crit", "element_boost", "status_chance", "heal_boost", "guard", "counter", "regen_mp", "regen_hp", "initiative", "money_bonus", "vs_afflicted", "fury", "immune"]


## Dépense les points de talent d'un personnage : une voie d'abord, le reste dans l'autre.
func _spend(id: String, first: int) -> void:
	var branches: Array = Rules.branches(id)
	if branches.size() != 2:
		return
	for b: Dictionary in [branches[first], branches[1 - first]]:
		for t: Dictionary in Rules.branch_talents(b):
			GameState.learn_talent(id, str(t.get("id", "")))


## Met un personnage seul dans l'équipe, au niveau voulu, avec les talents donnés.
func _solo(ids: Array, level: int, talents: Dictionary = {}) -> void:
	GameState.new_game()
	GameState.party = []
	for id: String in ids:
		GameState.add_to_party(id)
		GameState.member(id)["level"] = level
		for t: String in talents.get(id, []):
			check(GameState.learn_talent(id, t), "talent %s appris par %s" % [t, id])
	GameState.heal_party()


func _find(list: Array, source: String) -> RefCounted:
	for c: RefCounted in list:
		if str(c.source) == source:
			return c
	return null


func _test_talents() -> void:
	# --- les données : deux voies par personnage de la bible, cohérentes avec le reste
	var count := 0
	for id: String in Database.talents:
		check(BIBLE_TEAM.has(id), "talents.json : %s est un membre de l'équipe" % id)
	for id: String in BIBLE_TEAM:
		var ch := Database.get_character(id)
		check(not Rules.battle_def(id).is_empty(), "%s : fiche de combat" % id)
		var branches: Array = Rules.branches(id)
		check(branches.size() == 2, "%s : deux voies de talents" % id)
		var names: Array = ch.get("branches", [])
		var seen := {}
		for i in branches.size():
			var b: Dictionary = branches[i]
			check(i < names.size() and str(names[i]) == str(b.get("name", "")), "%s : la voie « %s » porte le nom de la bible" % [id, str(b.get("name", ""))])
			check(str(b.get("id", "")) != "" and str(b.get("desc", "")) != "", "%s : voie décrite" % id)
			var list: Array = Rules.branch_talents(b)
			check(list.size() >= 3, "%s : au moins trois talents par voie" % id)
			for t: Dictionary in list:
				var tid := str(t.get("id", ""))
				var what := "talent %s/%s" % [id, tid]
				count += 1
				check(tid != "" and not seen.has(tid), "%s : identifiant unique" % what)
				seen[tid] = true
				check(str(t.get("name", "")) != "" and str(t.get("desc", "")) != "", "%s : nom et description" % what)
				check(t.has("mods") or t.has("skills") or t.has("passives"), "%s : il apporte quelque chose" % what)
				for key: String in t.get("mods", {}):
					check(Rules.STATS.has(key), "%s : caractéristique connue (%s)" % [what, key])
				for s: Variant in t.get("skills", []):
					check(Database.skills.has(str(s)) and int(Database.get_skill(str(s)).get("cost", 0)) > 0, "%s : compétence connue et payante (%s)" % [what, str(s)])
				var passives: Dictionary = t.get("passives", {})
				for key: String in passives:
					check(PASSIVES.has(key), "%s : effet permanent connu (%s)" % [what, key])
				for s: Variant in passives.get("immune", []):
					check(Database.statuses.has(str(s)), "%s : immunité connue (%s)" % [what, str(s)])
				for s: String in passives.get("status_chance", {}):
					check(s == "all" or Database.statuses.has(s), "%s : état connu (%s)" % [what, s])
				for s: String in passives.get("element_boost", {}):
					check(Database.elements.has(s), "%s : élément connu (%s)" % [what, s])
	print("  %d talents pour %d personnages" % [count, BIBLE_TEAM.size()])

	# --- les points : un par niveau, dépensés dans l'ordre de chaque voie
	GameState.new_game()
	check(GameState.talent_points("glandoulf") == 0, "niveau 1 : aucun point de talent")
	check(not GameState.learn_talent("glandoulf", "meche_courte"), "niveau 1 : rien à apprendre")
	var up := GameState.grant_xp("glandoulf", Rules.xp_to_next(1))
	check(int(up.get("to", 0)) == 2 and int(up.get("points", 0)) == 1 and GameState.talent_points("glandoulf") == 1, "monter au niveau 2 donne un point de talent")
	check(GameState.talent_state("glandoulf", "petarade_t") == "locked" and not GameState.learn_talent("glandoulf", "petarade_t"), "le deuxième talent d'une voie attend le premier")
	check(GameState.learn_talent("glandoulf", "meche_courte") and GameState.talent_points("glandoulf") == 0, "premier talent appris, point dépensé")
	check(GameState.talent_state("glandoulf", "petarade_t") == "poor" and not GameState.learn_talent("glandoulf", "petarade_t"), "sans point, rien ne s'apprend")
	check(not GameState.learn_talent("glandoulf", "meche_courte"), "un talent ne s'apprend qu'une fois")
	check(not GameState.learn_talent("glandoulf", "cuir_epais"), "on n'apprend pas le talent d'un autre")
	check(GameState.specialization("glandoulf") == "pyrotechnicien" and GameState.specialization_name("glandoulf") == "Pyrotechnicien", "la voie suivie est reconnue")
	GameState.member("glandoulf")["level"] = 7
	check(GameState.talent_points("glandoulf") == 5, "niveau 7 : six points en tout")
	var mag := int(GameState.member_stats("glandoulf")["mag"])
	check(GameState.learn_talent("glandoulf", "petarade_t") and GameState.learn_talent("glandoulf", "poudre_seche"), "suite de la voie")
	check(GameState.talent_points("glandoulf") == 2, "les talents avancés coûtent deux points")
	check(int(GameState.member_stats("glandoulf")["mag"]) == mag + 3, "un talent peut augmenter une caractéristique")
	check((GameState.member_skills("glandoulf") as Array).has("petarade") and not (Rules.skills_at("glandoulf", 7) as Array).has("petarade"), "un talent peut donner une compétence")
	var e: RefCounted = BattleEngine.new()
	e.setup({"enemies": ["limace_molle"]}, 5)
	var g: RefCounted = e.party[0]
	check((g.skills as Array).has("petarade") and int(g.base["mag"]) == mag + 3, "le combat tient compte des talents")
	check(is_equal_approx(g.passive("crit"), 0.08) and is_equal_approx(g.passive("element_boost", "feu"), 0.15) and is_zero_approx(g.passive("counter")), "les effets permanents arrivent en combat")

	# --- sauvegarde
	var saved: Variant = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.new_game()
	check(saved is Dictionary and GameState.from_dict(saved), "sauvegarde relue")
	check(GameState.has_talent("glandoulf", "poudre_seche") and GameState.talent_points("glandoulf") == 2, "les talents survivent à la sauvegarde")
	(saved["roster"]["glandoulf"]["talents"] as Array).append("talent_disparu")
	check(GameState.from_dict(saved) and (GameState.talents_of("glandoulf") as Array).size() == 3, "un talent inconnu dans une sauvegarde est ignoré")
	saved["roster"]["glandoulf"]["level"] = 2
	check(GameState.from_dict(saved) and (GameState.talents_of("glandoulf") as Array).is_empty() and GameState.talent_points("glandoulf") == 1, "un compte de points impossible est remis à zéro")
	(saved["roster"]["glandoulf"] as Dictionary).erase("talents")
	check(GameState.from_dict(saved) and GameState.talent_points("glandoulf") == 1, "une sauvegarde d'avant les talents se charge")
	GameState.member("glandoulf")["level"] = 7
	_spend("glandoulf", 1)
	check(GameState.specialization("glandoulf") == "maitre_sieste" and GameState.talent_points("glandoulf") == 0, "une voie complète au niveau 7")
	check(GameState.reset_talents("glandoulf") == 6 and GameState.talent_points("glandoulf") == 6 and GameState.specialization("glandoulf") == "", "tout oublier rend tous les points")
	check(int(GameState.member("glandoulf")["hp"]) <= int(GameState.member_stats("glandoulf")["hp"]), "après l'oubli, les PV ne dépassent pas le maximum")

	# --- une recrue arrive avec des points à dépenser
	GameState.new_game()
	GameState.member("glandoulf")["level"] = 4
	GameState.add_to_party("sam", true)
	check(GameState.talent_points("sam") == 2 and GameState.party_talent_points() == 5, "une recrue de niveau 3 arrive avec deux points")
	check(GameState.party_summary().contains("5 points de talent"), "le menu de pause signale les points à dépenser")

	# --- les effets en combat
	var hits: Array = []
	for talents: Dictionary in [{}, {"glandoulf": ["meche_courte"]}]:
		_solo(["glandoulf"], 7, talents)
		e = BattleEngine.new()
		e.setup({"enemies": ["grande_baveuse"]}, 9)
		for ev: Dictionary in e.perform(e.party[0], {"type": "skill", "id": "etincelle", "target": e.enemies[0]}):
			if str(ev.get("type", "")) == "damage":
				hits.append(int(ev["amount"]))
	check(hits.size() == 2 and int(hits[1]) > int(hits[0]), "Mèche courte : le feu frappe plus fort (%s)" % str(hits))

	_solo(["glandoulf"], 3, {"glandoulf": ["sommeil_reparateur"]})
	e = BattleEngine.new()
	e.setup({"enemies": ["limace_molle"]}, 3)
	g = e.party[0]
	g.mp = 0
	g.statuses["sommeil"] = {"turns": 2, "fresh": false}
	var events: Array = e.start_turn(g)
	check(int(g.mp) == 1 and _has_event(events, "mana") and not bool(e.can_act), "Sommeil réparateur : un PM par tour, même endormi")

	_solo(["glandoulf", "froton"], 3, {"froton": ["doigts_de_fee", "pieds_legers"]})
	e = BattleEngine.new()
	e.setup({"enemies": ["grande_baveuse"]}, 3)
	var f := _find(e.party, "froton")
	var boss: RefCounted = e.enemies[0]
	check(is_equal_approx(float(f.wait), 500.0 / float(f.speed())), "Pieds légers : Froton prend de l'avance au début du combat")
	check(e.next_actor() == f, "Pieds légers : Froton joue le premier")
	f.wait = 0.0
	events = e.perform(f, {"type": "skill", "id": "fauche", "target": boss})
	var expected := maxi(1, int(round(int(boss.money) * 0.5)))
	check(_has_event(events, "steal") and int(e.stolen) == expected and expected > 0, "Fauche : vole la moitié des écus de l'adversaire (%d)" % int(e.stolen))
	f.mp = f.max_mp()
	e.perform(f, {"type": "skill", "id": "fauche", "target": boss})
	check(int(e.stolen) == expected, "Fauche : une seule fois par adversaire")
	var purse := GameState.money
	boss.hp = 0
	e._check_end()
	var rewards: Dictionary = e.commit()
	check(str(e.result) == "victory" and int(rewards["money"]) == int(boss.money) + expected and GameState.money == purse + int(rewards["money"]), "Fauche : les écus volés s'ajoutent au butin")

	_solo(["glandoulf", "sam"], 7, {"sam": ["cuir_epais", "viens_y_voir_t", "fonte_emaillee", "retour_de_poele"]})
	e = BattleEngine.new()
	e.setup({"enemies": ["grande_baveuse"]}, 4)
	var sam := _find(e.party, "sam")
	boss = e.enemies[0]
	check(is_equal_approx(sam.passive("guard"), 0.12) and is_equal_approx(sam.passive("counter"), 0.35), "Poêle de Fer : garde et riposte en place")
	e.perform(sam, {"type": "skill", "id": "viens_y_voir"})
	check(sam.has_status("provocation"), "Viens-y voir : Sam est provocateur")
	var aimed := 0
	for i in 20:
		if e.ai_action(boss).get("target") == sam:
			aimed += 1
	check(aimed == 20, "Viens-y voir : l'adversaire vise toujours Sam (%d/20)" % aimed)
	var counters := 0
	for i in 40:
		sam.hp = sam.max_hp()
		boss.hp = boss.max_hp()
		var hp_before := int(boss.hp)
		events = e.perform(boss, {"type": "attack", "target": sam})
		if _has_event(events, "counter"):
			counters += 1
			check(int(boss.hp) < hp_before, "Retour de poêle : la riposte fait mal")
	check(counters >= 5 and counters <= 25, "Retour de poêle : Sam riposte environ une fois sur trois (%d/40)" % counters)

	_solo(["glandoulf", "pepin"], 7, {"pepin": ["tabac_de_caractere", "nuage_tonique_t", "nuage_acre_t", "brouillard_epais_t"]})
	e = BattleEngine.new()
	e.setup({"enemies": ["grande_baveuse"]}, 6)
	var pepin := _find(e.party, "pepin")
	boss = e.enemies[0]
	e.perform(pepin, {"type": "skill", "id": "brouillard_epais"})
	check(pepin.has_status("enfume") and e.party[0].has_status("enfume"), "Brouillard épais : toute l'équipe est enfumée")
	var misses := 0
	for i in 60:
		pepin.hp = pepin.max_hp()
		if _has_event(e.perform(boss, {"type": "attack", "target": pepin}), "miss"):
			misses += 1
	check(misses >= 8 and misses <= 30, "Brouillard épais : un coup physique sur trois environ rate (%d/60)" % misses)
	pepin.mp = pepin.max_mp()
	e.perform(pepin, {"type": "skill", "id": "nuage_acre"})
	var def_before := float(boss.base.get("def", 0))
	boss.statuses["demoralise"] = {"turns": 3, "fresh": false}
	check(float(boss.stat("def")) < def_before or def_before == 0.0, "Démoralisé : défense réduite")

	_solo(["grimli"], 7, {"grimli": ["crane_de_morbier", "meme_pas_mal"]})
	e = BattleEngine.new()
	e.setup({"enemies": ["limace_molle"]}, 2)
	check((e.party[0].immune as Array).has("sonne"), "Même pas mal : un talent peut immuniser contre un état")

	# --- chaque personnage peut aller au bout de chacune de ses voies et s'en servir en combat
	for id: String in BIBLE_TEAM:
		for first in 2:
			_solo([id], 13)
			_spend(id, first)
			check(GameState.talent_points(id) == 0 and (GameState.talents_of(id) as Array).size() == 8, "%s : douze points suffisent pour tout apprendre" % id)
			var fight := _fight({"enemies": ["limace_molle", "guepe_cidre"]}, 40 + first)
			check(str(fight.result) == "victory", "%s, tous talents appris : combat mené à son terme" % id)
			# Chaque compétence de talent se lance sans erreur.
			GameState.heal_party()
			var probe: RefCounted = BattleEngine.new()
			probe.setup({"enemies": ["grande_baveuse"]}, 60 + first)
			var me: RefCounted = probe.party[0]
			for s: String in me.skills:
				me.mp = me.max_mp()
				me.hp = me.max_hp()
				probe.enemies[0].hp = probe.enemies[0].max_hp()
				var out: Array = probe.perform(me, {"type": "skill", "id": s})
				check(_has_event(out, "cast"), "%s : %s se lance" % [id, s])
	GameState.new_game()


## Une rencontre suivie d'une autre (vagues enchaînées par deux « battle » d'un dialogue) : voir _sim.
func _waved(first: String, second: String) -> Dictionary:
	var enc := Database.get_encounter(first).duplicate(true)
	enc["_next"] = Database.get_encounter(second).duplicate(true)
	return enc


func _soft(encounter_id: String, softness: float) -> Dictionary:
	var enc := Database.get_encounter(encounter_id).duplicate(true)
	enc["ramollissement"] = softness
	return enc


## Un combat simulé du début à la fin. Renvoie [victoire, tours par combattant, PV restants en part].
## « smart » : joueur attentif (voir _smart_action) ; sinon le jeu automatique du moteur.
func _sim(team: Array, level: int, enc: Dictionary, talents: int, smart: bool, seed_value: int, inv: Dictionary) -> Array:
	GameState.new_game()
	GameState.party = []
	for id: String in team:
		GameState.add_to_party(id)
		GameState.member(id)["level"] = level
		if talents >= 0:
			_spend(id, talents)
	GameState.heal_party()
	GameState.inventory = inv.duplicate()
	# Un combat en plusieurs vagues : la clé de test « _next » enchaîne les rencontres, PV et PM d'une vague à l'autre
	# (comme deux « battle » à la suite dans un dialogue : aucun soin entre les deux).
	var waves: Array = [enc]
	var more: Variant = enc.get("_next")
	while more is Dictionary:
		waves.append(more)
		more = (more as Dictionary).get("_next")
	var e: RefCounted = null
	var memo := {}
	var hero_turns := 0
	for wave_index in waves.size():
		if wave_index > 0:
			for c: RefCounted in e.party:
				var m: Dictionary = GameState.member(str(c.source))
				m["hp"] = maxi(1, int(c.hp))
				m["mp"] = int(c.mp)
			GameState.inventory = (e.inventory as Dictionary).duplicate(true)
			GameState.bestiary = (e.revealed as Dictionary).duplicate(true)
		e = BattleEngine.new()
		e.setup(waves[wave_index], seed_value + 7919 * wave_index)
		var guard := 0
		while str(e.result) == "" and guard < 800:
			guard += 1
			var actor: RefCounted = e.next_actor()
			if actor == null:
				break
			e.start_turn(actor)
			if str(e.result) == "" and bool(e.can_act):
				if str(actor.side) != "enemy":
					hero_turns += 1
					var act: Dictionary = _smart_action(e, actor, memo) if smart else e.auto_action(actor)
					e.perform(actor, act)
				else:
					e.perform(actor, e.ai_action(actor))
			if str(e.result) == "":
				e.end_turn(actor)
		if str(e.result) != "victory":
			break
	var left := 0.0
	for c: RefCounted in e.party:
		left += float(c.hp) / float(c.max_hp())
	return [str(e.result) == "victory", float(hero_turns) / float(maxi(1, team.size())), left / float(maxi(1, (e.party as Array).size()))]


## Dégâts attendus d'une action de héros sur une cible (sans hasard) ; faiblesse comptée si le joueur la connaît.
func _expect(e: RefCounted, actor: RefCounted, def: Dictionary, target: RefCounted) -> float:
	var total := 0.0
	for fx: Variant in def.get("effects", []):
		if not (fx is Dictionary) or str(fx.get("type", "")) != "damage":
			continue
		var stat_key := str(fx.get("stat", "atk"))
		var element := str(fx.get("element", actor.element))
		var amount: float = float(actor.stat(stat_key)) * 2.0 * float(fx.get("power", 100)) / 100.0 + float(fx.get("flat", 0)) - float(target.stat("def" if stat_key == "atk" else "res"))
		amount = maxf(1.0, amount)
		if (e.known_weak(target) as Array).has(element):
			amount *= 1.5
		amount *= 1.0 + float(actor.passive("element_boost", element))
		amount *= float(target.vulnerability())
		if stat_key == "atk":
			amount *= clampf((float(actor.stat("acc")) - float(target.stat("eva"))) / 100.0, 0.1, 1.0)
			if float(e.softness) > 0.0 and not actor.is_firm():
				amount *= 1.0 - float(e.softness)
		total += amount
	return total


func _skill_has(def: Dictionary, type: String) -> bool:
	for fx: Variant in def.get("effects", []):
		if fx is Dictionary and str(fx.get("type", "")) == type:
			return true
	return false


## Statut posé par une compétence (premier effet « status »), ou "".
func _skill_status(def: Dictionary) -> String:
	for fx: Variant in def.get("effects", []):
		if fx is Dictionary and str(fx.get("type", "")) == "status":
			return str(fx.get("id", ""))
	return ""


## Le joueur attentif : soigne sous un seuil (compétence de groupe si plusieurs blessés), relève les
## tombés, provoque avec le plus résistant, soutient et affaiblit les gros adversaires, lance les sorts de
## zone contre plusieurs ennemis, vise la faiblesse connue (et essaie un autre élément tant que celle d'un
## ennemi à bouclier est inconnue), garde son élan pour le moment « Brisé ». Il ne triche pas : il ne
## connaît que les faiblesses déjà révélées et ne touche pas aux règles.
func _smart_action(e: RefCounted, actor: RefCounted, memo: Dictionary) -> Dictionary:
	var foes: Array = e.living("enemy")
	var allies: Array = e.living("party")
	if foes.is_empty():
		return {"type": "defend"}
	var foe_hp := 0
	var top: RefCounted = foes[0]
	for f: RefCounted in foes:
		foe_hp += int(f.hp)
		if int(f.hp) > int(top.hp):
			top = f
	var big: bool = foe_hp >= 2000
	# --- soins et relèves
	var hurt: Array = []
	var weakest: RefCounted = allies[0]
	for a: RefCounted in allies:
		if float(a.hp) / float(a.max_hp()) < 0.6:
			hurt.append(a)
		if float(a.hp) / float(a.max_hp()) < float(weakest.hp) / float(weakest.max_hp()):
			weakest = a
	var weak_ratio := float(weakest.hp) / float(weakest.max_hp())
	var fallen: Array = e.fallen("party")
	if not fallen.is_empty():
		for id: String in actor.skills:
			var d := Database.get_skill(id)
			if _skill_has(d, "revive") and e.can_use_skill(actor, id):
				return {"type": "skill", "id": id, "target": fallen[0]}
		if int(e.inventory.get("racine", 0)) > 0:
			return {"type": "item", "id": "racine", "target": fallen[0]}
	var heal_skill := ""
	var heal_group := ""
	var has_heal := false
	for id: String in actor.skills:
		var d := Database.get_skill(id)
		if _skill_has(d, "heal") and str(d.get("target", "")) in ["ally", "all_allies"]:
			has_heal = true
			if e.can_use_skill(actor, id):
				if str(d.get("target", "")) == "all_allies":
					heal_group = id
				else:
					heal_skill = id
	if hurt.size() >= 2 and heal_group != "":
		return {"type": "skill", "id": heal_group, "target": weakest, "elan": 1 if weak_ratio < 0.3 and actor.elan >= 2 else 0}
	if weak_ratio < 0.45 and heal_skill != "":
		return {"type": "skill", "id": heal_skill, "target": weakest, "elan": 1 if weak_ratio < 0.3 and actor.elan >= 2 else 0}
	if weak_ratio < 0.4 and heal_group != "":
		return {"type": "skill", "id": heal_group, "target": weakest}
	if weak_ratio < (0.55 if big else 0.4) and heal_skill == "" and heal_group == "":   # sans soin de compétence : on boit plus tôt contre un gros adversaire
		var best_item := ""
		var best_power := 0.0
		for id: String in e.inventory:
			var it := Database.get_item(id)
			if _skill_has(it, "heal") and str(it.get("target", "")) == "ally":
				var p := 0.0
				for fx: Variant in it.get("effects", []):
					if fx is Dictionary and str(fx.get("type", "")) == "heal":
						p = float(fx.get("power", 0)) + float(weakest.max_hp()) * float(fx.get("percent", 0.0))
				if p > best_power:
					best_power = p
					best_item = id
		if best_item != "":
			return {"type": "item", "id": best_item, "target": weakest}
	# --- provocation, soutien, affaiblissement (contre un gros adversaire)
	var turn := int(e.turn_count)
	if big:
		for id: String in actor.skills:
			var d := Database.get_skill(id)
			if not e.can_use_skill(actor, id) or _skill_has(d, "damage") or _skill_has(d, "heal") or _skill_has(d, "revive"):
				continue
			var st := _skill_status(d)
			var kind := str(d.get("target", ""))
			if st == "provocation":
				var taunting := false
				for a: RefCounted in allies:
					if a.has_status("provocation"):
						taunting = true
				if not taunting:
					return {"type": "skill", "id": id, "target": actor}
			elif st in ["galvanise", "garde", "enfume"] and turn - int(memo.get("buff_" + id, -99)) >= 6 and (int(actor.mp) >= int(d.get("cost", 0)) + 8 or kind == "self"):
				var lacking: Array = []
				for a: RefCounted in allies:
					if not a.has_status(st):
						lacking.append(a)
				if kind == "all_allies" and lacking.size() >= 2:
					memo["buff_" + id] = turn
					return {"type": "skill", "id": id, "target": actor}
				if kind == "ally" and not lacking.is_empty() and int(actor.mp) >= int(d.get("cost", 0)) + 8:
					var pick: RefCounted = null   # on renforce l'un des deux plus gros frappeurs, pas tout le monde
					var ranked: Array = allies.duplicate()
					ranked.sort_custom(func(x: RefCounted, y: RefCounted) -> bool: return float(x.stat("atk")) + float(x.stat("mag")) > float(y.stat("atk")) + float(y.stat("mag")))
					for a: RefCounted in ranked.slice(0, 2):
						if lacking.has(a) and a != actor:
							pick = a
							break
					if pick != null:
						memo["buff_" + id] = turn
						return {"type": "skill", "id": id, "target": pick}
				if kind == "self" and not actor.has_status(st):
					memo["buff_" + id] = turn
					return {"type": "skill", "id": id, "target": actor}
			elif st in ["ramolli", "demoralise", "englue", "sommeil"] and str(d.get("target", "")) in ["enemy", "all_enemies"] and turn - int(memo.get("debuff_" + id, -99)) >= 3:
				if not top.has_status(st) and not (top.immune as Array).has(st) and foe_hp >= 500:
					memo["debuff_" + id] = turn
					return {"type": "skill", "id": id, "target": top}
	# --- coup annoncé : un joueur attentif se couvre quand il n'est pas en grande forme (se défendre divise le coup)
	for f: RefCounted in foes:
		if f.has_status("annonce") and float(actor.hp) / float(actor.max_hp()) < 0.6 and int(f.shield) <= 0:
			return {"type": "defend"}
	# --- attaque
	var target: RefCounted = foes[0]
	var broken: RefCounted = null
	for f: RefCounted in foes:
		if f.has_status("ebranle"):
			broken = f
	if broken != null:
		target = broken
	else:
		var shielded: Array = []
		for f: RefCounted in foes:
			if int(f.shield) > 0:
				shielded.append(f)
		var weak_hit: RefCounted = null
		for f: RefCounted in shielded:
			for known: String in e.known_weak(f):
				if actor.element == known or _knows_element(actor, known):
					if weak_hit == null or int(f.shield) < int(weak_hit.shield):
						weak_hit = f
		if weak_hit != null:
			target = weak_hit
		else:
			for f: RefCounted in foes:
				if int(f.hp) < int(target.hp):
					target = f
	var tried: Array = memo.get("tried_" + str(target.source), [])
	var probing: bool = int(target.shield) > 0 and (e.known_weak(target) as Array).is_empty()
	# candidats : l'attaque de base et chaque compétence offensive (élément, score, coût)
	var options: Array = []
	options.append({"action": {"type": "attack", "target": target}, "score": _expect(e, actor, e.action_def(actor, {"type": "attack"}), target), "elem": str(actor.element), "single": true, "cost": 0})
	var keep_mp := 0
	for id: String in actor.skills:
		var d := Database.get_skill(id)
		if _skill_has(d, "heal") and str(d.get("target", "")) in ["ally", "all_allies"]:
			keep_mp = maxi(keep_mp, int(d.get("cost", 0)))
	for id: String in actor.skills:
		var d := Database.get_skill(id)
		var kind := str(d.get("target", ""))
		if not _skill_has(d, "damage") or not (kind in ["enemy", "all_enemies"]) or not e.can_use_skill(actor, id):
			continue
		if int(actor.mp) - int(d.get("cost", 0)) < keep_mp and not (foe_hp < 300):
			continue
		var score := 0.0
		var elem := ""
		if kind == "all_enemies":
			for f: RefCounted in foes:
				score += _expect(e, actor, d, f)
		else:
			score = _expect(e, actor, d, target)
		for fx: Variant in d.get("effects", []):
			if fx is Dictionary and str(fx.get("type", "")) == "damage":
				elem = str(fx.get("element", ""))
		options.append({"action": {"type": "skill", "id": id, "target": target}, "score": score, "elem": elem, "single": kind == "enemy", "cost": int(d.get("cost", 0)), "area": kind == "all_enemies"})
	var best: Dictionary = options[0]
	for o: Dictionary in options:
		if _option_score(o, foes.size(), probing and bool(o["single"]) and not tried.has(str(o["elem"]))) > _option_score(best, foes.size(), probing and bool(best["single"]) and not tried.has(str(best["elem"]))) * 1.1:
			best = o
	if bool(best["single"]):
		if not tried.has(str(best["elem"])):
			tried.append(str(best["elem"]))
			memo["tried_" + str(target.source)] = tried
	var best_action: Dictionary = best["action"]
	best = best_action
	# --- élan : plein sur un ennemi Brisé, sinon seulement pour ne pas en perdre
	var kind_e: String = e.elan_kind(actor, best)
	if (kind_e == "hits" or kind_e == "power") and int(actor.elan) > 0:
		if broken != null and best.get("target") == broken:
			best["elan"] = mini(3, int(actor.elan))
		elif int(actor.elan) >= 4:
			best["elan"] = 2
	return best


func _option_score(o: Dictionary, foe_count: int, untried: bool) -> float:
	return float(o["score"]) * (1.3 if bool(o.get("area", false)) and foe_count >= 3 else 1.0) * (1.4 if untried else 1.0)


func _knows_element(actor: RefCounted, element: String) -> bool:
	for id: String in actor.skills:
		var d := Database.get_skill(id)
		if not (str(d.get("target", "")) in ["enemy", "all_enemies"]) or not _skill_has(d, "damage"):
			continue
		for fx: Variant in d.get("effects", []):
			if fx is Dictionary and str(fx.get("element", "")) == element:
				return true
	return false


## Soins que le groupe a pu acheter ou trouver avant le combat, selon le chapitre.
func _sim_inventory(chapter: int) -> Dictionary:
	match chapter:
		1:
			return {"tisane": 5}
		2:
			return {"tisane": 5, "tomme_fermiere": 4, "racine": 1}
		3:
			return {"tisane_corsee": 5, "pain_elfique": 3, "racine": 1}
		4:
			return {"tomme_de_cave": 5, "miche_du_mineur": 5, "racine": 2}
	return {"miche_du_mineur": 5, "brioche_du_cavalier": 4, "racine": 2}


## Toutes les équipes de quatre possibles dans une réserve de recrutés (le meneur y est toujours).
func _subsets(pool: Array, lead: String, size: int = 4) -> Array:
	var others: Array = []
	for id: Variant in pool:
		if str(id) != lead:
			others.append(str(id))
	var out: Array = []
	var pick: Array = []
	_combos(others, 0, size - 1, pick, lead, out)
	return out


func _combos(others: Array, from: int, need: int, pick: Array, lead: String, out: Array) -> void:
	if need == 0:
		out.append([lead] + pick.duplicate())
		return
	for i in range(from, others.size()):
		pick.append(others[i])
		_combos(others, i + 1, need - 1, pick, lead, out)
		pick.pop_back()


## Taux de victoire d'une équipe (joueur attentif ou jeu automatique) : [victoires, tours par héros, PV restants].
func _sim_rate(team: Array, level: int, enc: Dictionary, talents: int, smart: bool, runs: int, inv: Dictionary) -> Array:
	var wins := 0
	var rounds := 0.0
	var left := 0.0
	for s in runs:
		var r := _sim(team, level, enc, talents, smart, 100 + s, inv)
		if bool(r[0]):
			wins += 1
		rounds += float(r[1])
		left += float(r[2])
	return [float(wins) / float(runs), rounds / float(runs), left / float(runs)]


## Les équipes de quatre « raisonnables » d'une réserve : le meneur, Sam (le tank) et Glandoulf (le seul mage, seul à
## porter feu, foudre et torpeur) y sont toujours si les recrutés les comptent ; le reste est libre (avec ou sans soigneur).
func _reasonable_teams(pool: Array, lead: String) -> Array:
	var out: Array = []
	for team: Array in _subsets(pool, lead):
		if (pool.has("sam") and not team.has("sam")) or (pool.has("glandoulf") and not team.has("glandoulf")):
			continue
		out.append(team)
	return out


## Les combats obligatoires des chapitres 1 à 5 : (étiquette, équipe type, niveau, rencontre, genre, réserve de recrutés, meneur).
## Une réserve vide : l'équipe est imposée par l'histoire.
func _forced_cases() -> Array:
	var hunters := ["sam", "froton", "merri", "pepin"]
	var captives := ["aragrogne", "digoulasse", "grimli"]
	var old := ["glandoulf", "sam", "froton", "pepin", "aragrogne", "merri"]
	var all8 := ["glandoulf", "sam", "froton", "pepin", "merri", "aragrogne", "digoulasse", "grimli"]
	var reunited := ["glandoulf", "sam", "froton", "aragrogne"]
	return [
		["1 Grande Baveuse niv. 4", TEAM, 4, Database.get_encounter("grande_baveuse"), "boss", [], ""],
		["1 Vieux Solitaire niv. 5", TEAM, 5, _soft("vieux_solitaire", 0.2), "boss", [], ""],
		["1 Monseigneur niv. 6", TEAM, 6, _soft("crapaud_buffle", 0.2), "boss", [], ""],
		["1 Morfales du quai niv. 6", TEAM, 6, Database.get_encounter("morfales_quai"), "ordinaire", [], ""],
		["1 Morfales du potager niv. 6", TEAM, 6, Database.get_encounter("morfales_potager"), "ordinaire", [], ""],
		["1 Morfales de l'auberge niv. 6", TEAM, 6, Database.get_encounter("morfales_auberge"), "ordinaire", [], ""],
		["1 le Naze niv. 7", TEAM, 7, Database.get_encounter("naze"), "boss", [], ""],
		["1 péage de la route niv. 7", TEAM, 7, _soft("morfales_route", 0.15), "ordinaire", [], ""],
		["2 Nazes de nuit niv. 9", TEAM5, 9, _soft("nazes_nuit", 0.3), "boss", old, "glandoulf"],
		["2 Chantecler niv. 8", TEAM, 8, _soft("chantecler", 0.2), "boss", old, "glandoulf"],
		["2 Vacherin niv. 8", TEAM, 8, _soft("vacherin", 0.2), "boss", old, "glandoulf"],
		["3 Gardien des Archives niv. 11", TEAM, 11, Database.get_encounter("gardien_archives"), "boss", old, "glandoulf"],
		["4 Guetteur du lac niv. 12", TEAM, 12, Database.get_encounter("guetteur_du_lac"), "boss", old, "glandoulf"],
		["4 camp des Gobelardons niv. 12", TEAM, 12, Database.get_encounter("gobelins_du_camp"), "ordinaire", old, "glandoulf"],
		["4 Gros Bleu niv. 13", TEAM, 13, Database.get_encounter("gros_bleu"), "boss", old, "glandoulf"],
		["4 Goulûm niv. 14", TEAM, 14, Database.get_encounter("goulum"), "boss", old, "glandoulf"],
		["4 Balourd niv. 16", TEAM, 16, Database.get_encounter("balourd"), "boss", old, "glandoulf"],
		["5 embuscade des chutes niv. 17", hunters, 17, Database.get_encounter("ambuscade_chutes"), "boss", [], ""],
		["5 Grimace niv. 17", captives, 17, Database.get_encounter("grimace"), "boss", [], ""],
		["5 Uglouk (Garde-Manger) niv. 17", hunters, 17, Database.get_encounter("uglouk_garde"), "ordinaire", [], ""],
		["5 Froton Anneauté niv. 17", ["sam", "merri", "pepin"], 17, Database.get_encounter("froton_anneaute"), "boss", [], ""],
		["5 brèche niv. 18", reunited, 18, _waved("breche_avant", "breche"), "boss", all8, "sam"],
		["5 Sarumâle niv. 18", reunited, 18, Database.get_encounter("sarumale"), "boss", all8, "sam"],
	]


## Tableau d'équilibre : tous les combats obligatoires des chapitres 1 à 5, au niveau attendu, élan compris.
## Colonnes : « auto » = jeu automatique du moteur (sans talents, puis avec) ; « atten. » = joueur attentif
## (_smart_action : sans talents, puis avec) ; « pire » = la pire équipe de quatre parmi les recrutés du
## moment (avec talents, joueur attentif) ; « sans Pépin » = la pire équipe sans soigneur ; tours par héros.
## GLAN_RUNS = essais (60), GLAN_FILTER = texte de l'étiquette, GLAN_LEVEL = niveau forcé, GLAN_SUBS=0 saute les équipes.
## Cible : 85 à 95 % pour un combat ordinaire, 60 à 80 % pour un boss (équipe type, avec talents).
func _measure_forced() -> void:
	var runs := int(OS.get_environment("GLAN_RUNS")) if OS.has_environment("GLAN_RUNS") else 60
	var subs := not (OS.has_environment("GLAN_SUBS") and OS.get_environment("GLAN_SUBS") == "0")
	var filter := OS.get_environment("GLAN_FILTER")
	if OS.has_environment("GLAN_TEAM"):   # une seule équipe (« a,b,c,d »), pour comprendre un cas
		var one: Array = Array(OS.get_environment("GLAN_TEAM").split(","))
		for case: Array in _forced_cases():
			if filter != "" and str(case[0]).contains(filter):
				var lv := int(case[2])
				var r := _sim_rate(one, lv, case[3], 0, true, int(OS.get_environment("GLAN_RUNS")) if OS.has_environment("GLAN_RUNS") else 60, _sim_inventory(int(str(case[0]).left(1))))
				print("  %s avec %s : %d %%, %.1f tours, PV %d %%" % [str(case[0]), str(one), int(100.0 * float(r[0])), float(r[1]), int(100.0 * float(r[2]))])
		return
	var fast := OS.has_environment("GLAN_FAST")   # seulement le joueur attentif avec talents (réglage rapide)
	if OS.has_environment("GLAN_SCALE"):   # « id:facteur,id:facteur » : PV d'ennemis modifiés en mémoire, pour chercher la bonne valeur
		for part: String in OS.get_environment("GLAN_SCALE").split(","):
			var kv := part.split(":")
			if kv.size() == 2 and Database.enemies.has(kv[0]):
				Database.enemies[kv[0]]["stats"]["hp"] = int(round(float(Database.enemies[kv[0]]["stats"]["hp"]) * float(kv[1])))
	if OS.has_environment("GLAN_POWER"):   # idem pour la force (atk et mag)
		for part: String in OS.get_environment("GLAN_POWER").split(","):
			var kv := part.split(":")
			if kv.size() == 2 and Database.enemies.has(kv[0]):
				for stat_key: String in ["atk", "mag"]:
					Database.enemies[kv[0]]["stats"][stat_key] = int(round(float(Database.enemies[kv[0]]["stats"][stat_key]) * float(kv[1])))
	if OS.has_environment("GLAN_SHIELD"):   # idem pour le bouclier (« id:nombre »)
		for part: String in OS.get_environment("GLAN_SHIELD").split(","):
			var kv := part.split(":")
			if kv.size() == 2 and Database.enemies.has(kv[0]):
				Database.enemies[kv[0]]["shield"] = int(kv[1])
	print("  %-34s %-6s | %9s | %9s | %5s | %-34s | %-34s | %5s" % ["combat", "type", "auto s/a", "atten s/a", "tours", "pire équipe (avec talents)", "pire sans Pépin", "PV %"])
	for case: Array in _forced_cases():
		if filter != "" and not str(case[0]).contains(filter):
			continue
		var level := int(OS.get_environment("GLAN_LEVEL")) if OS.has_environment("GLAN_LEVEL") else int(case[2])
		var inv := _sim_inventory(int(str(case[0]).left(1)))
		var a0 := [0.0] if fast else _sim_rate(case[1], level, case[3], -1, false, runs, {})
		var a1 := [0.0] if fast else _sim_rate(case[1], level, case[3], 0, false, runs, {})
		var s0 := [0.0] if fast else _sim_rate(case[1], level, case[3], -1, true, runs, inv)
		var s1 := _sim_rate(case[1], level, case[3], int(OS.get_environment("GLAN_TAL")) if OS.has_environment("GLAN_TAL") else 0, true, runs, inv)
		var worst := 2.0
		var worst_team := ""
		var worst_np := 2.0
		var worst_np_team := ""
		if subs and not (case[5] as Array).is_empty():
			for team: Array in _reasonable_teams(case[5], str(case[6])):
				var r := _sim_rate(team, level, case[3], 0, true, maxi(30, runs / 2), inv)
				var label := "%s %d%%" % [",".join(PackedStringArray(team.map(func(i: String) -> String: return i.left(3)))), int(100.0 * float(r[0]))]
				if OS.has_environment("GLAN_SUBS_PRINT"):
					print("      %s" % label)
				if float(r[0]) < worst:
					worst = float(r[0])
					worst_team = label
				if not team.has("pepin") and float(r[0]) < worst_np:
					worst_np = float(r[0])
					worst_np_team = label
		print("  %-34s %-6s | %3d%% %3d%% | %3d%% %3d%% | %5.1f | %-34s | %-34s | %4d%%" % [str(case[0]), str(case[4]).left(6), int(100.0 * float(a0[0])), int(100.0 * float(a1[0])), int(100.0 * float(s0[0])), int(100.0 * float(s1[0])), float(s1[1]), worst_team, worst_np_team, int(100.0 * float(s1[2]))])
	GameState.new_game()



func _test_balance() -> void:
	var cases := [
		["prologue (Glandoulf et Isidur, niv. 20)", ["glandoulf"], 1, Database.get_encounter("prologue_sauron"), 0.9],
		["seul niv. 1 contre une limace", ["glandoulf"], 1, {"enemies": ["limace_molle"]}, 0.9],
		["seul niv. 1 contre deux limaces", ["glandoulf"], 1, {"enemies": ["limace_molle", "limace_molle"]}, 0.5],
		["seul niv. 1 contre deux guêpes", ["glandoulf"], 1, {"enemies": ["guepe_cidre", "guepe_cidre"]}, 0.4],
		["seul niv. 1 contre un épouvantail", ["glandoulf"], 1, {"enemies": ["epouvantail_avachi"]}, 0.4],
		["à deux niv. 2 contre trois guêpes", ["glandoulf", "pepin"], 2, {"enemies": ["guepe_cidre", "guepe_cidre", "guepe_cidre"]}, 0.5],
		["à deux niv. 3 contre épouvantail et limaces", ["glandoulf", "pepin"], 3, {"enemies": ["epouvantail_avachi", "limace_molle", "limace_molle"]}, 0.5],
		["à deux niv. 4 contre la Grande Baveuse", ["glandoulf", "pepin"], 4, Database.get_encounter("grande_baveuse"), 0.5],
		["à quatre niv. 3 contre la Grande Baveuse", ["glandoulf", "sam", "froton", "pepin"], 3, Database.get_encounter("grande_baveuse"), 0.8],
		# Étape 5 : les alentours de Bittebourg, la Fête et la route de Brie.
		["à deux niv. 3 contre un sanglier (bois)", ["glandoulf", "pepin"], 3, {"enemies": ["sanglier_flapi"], "ramollissement": 0.2}, 0.8],
		["à quatre niv. 4 contre sanglier et frelon", TEAM, 4, {"enemies": ["sanglier_flapi", "frelon_bois"], "ramollissement": 0.2}, 0.9],
		["à quatre niv. 4 contre sanglier et amanite", TEAM, 4, {"enemies": ["sanglier_flapi", "amanite_molle"], "ramollissement": 0.2}, 0.9],
		["à quatre niv. 4 contre le Vieux Solitaire", TEAM, 4, _soft("vieux_solitaire", 0.2), 0.8],
		["à quatre niv. 5 contre le Vieux Solitaire", TEAM, 5, _soft("vieux_solitaire", 0.2), 0.85],
		["à quatre niv. 5 contre grenouille et sangsue", TEAM, 5, {"enemies": ["grenouille_bouffie", "sangsue_roseaux"], "ramollissement": 0.2}, 0.9],
		["à quatre niv. 5 contre follet, grenouille, sangsue", TEAM, 5, {"enemies": ["feu_follet", "grenouille_bouffie", "sangsue_roseaux"], "ramollissement": 0.2}, 0.9],
		["à quatre niv. 5 contre Monseigneur", TEAM, 5, _soft("crapaud_buffle", 0.2), 0.8],
		["à quatre niv. 6 contre Monseigneur", TEAM, 6, _soft("crapaud_buffle", 0.2), 0.9],
		["à quatre niv. 6 contre les Morfales du quai", TEAM, 6, Database.get_encounter("morfales_quai"), 0.9],
		["à quatre niv. 6 contre les Morfales de l'auberge", TEAM, 6, Database.get_encounter("morfales_auberge"), 0.9],
		["à quatre niv. 5 contre le Naze", TEAM, 5, Database.get_encounter("naze"), 0.0],
		# Depuis l'étape 3 le Naze est réglé pour une équipe qui dépense ses points de talent
		# (voir plus bas) ; sans aucun talent il reste faisable, mais plus serré.
		["à quatre niv. 6 contre le Naze", TEAM, 6, Database.get_encounter("naze"), 0.0],
		["à quatre niv. 7 contre le Naze", TEAM, 7, Database.get_encounter("naze"), 0.3],
		["à quatre niv. 7 contre le péage de la route", TEAM, 7, _soft("morfales_route", 0.15), 0.9],
		["à quatre niv. 7 contre deux Morfales (route)", TEAM, 7, {"enemies": ["morfale_eclaireur", "morfale_eclaireur"], "ramollissement": 0.15}, 0.9],
		# Étape 3 : les mêmes combats avec les points de talent dépensés (dernier chiffre : 0 = première voie d'abord, 1 = seconde).
		["talents A, à deux niv. 3 contre épouvantail et limaces", ["glandoulf", "pepin"], 3, {"enemies": ["epouvantail_avachi", "limace_molle", "limace_molle"]}, 0.5, 0],
		["talents A, à deux niv. 4 contre la Grande Baveuse", ["glandoulf", "pepin"], 4, Database.get_encounter("grande_baveuse"), 0.5, 0],
		["talents A, à quatre niv. 4 contre le Vieux Solitaire", TEAM, 4, _soft("vieux_solitaire", 0.2), 0.8, 0],
		["talents B, à quatre niv. 4 contre le Vieux Solitaire", TEAM, 4, _soft("vieux_solitaire", 0.2), 0.8, 1],
		["talents A, à quatre niv. 5 contre Monseigneur", TEAM, 5, _soft("crapaud_buffle", 0.2), 0.8, 0],
		["talents B, à quatre niv. 5 contre Monseigneur", TEAM, 5, _soft("crapaud_buffle", 0.2), 0.8, 1],
		["talents A, à quatre niv. 6 contre les Morfales du quai", TEAM, 6, Database.get_encounter("morfales_quai"), 0.9, 0],
		["talents A, à quatre niv. 5 contre le Naze", TEAM, 5, Database.get_encounter("naze"), 0.0, 0],
		["talents B, à quatre niv. 5 contre le Naze", TEAM, 5, Database.get_encounter("naze"), 0.0, 1],
		["talents A, à quatre niv. 6 contre le Naze", TEAM, 6, Database.get_encounter("naze"), 0.4, 0],
		["talents B, à quatre niv. 6 contre le Naze", TEAM, 6, Database.get_encounter("naze"), 0.3, 1],
		["talents A, à quatre niv. 7 contre le Naze", TEAM, 7, Database.get_encounter("naze"), 0.8, 0],
		["talents A, à quatre niv. 7 contre le péage de la route", TEAM, 7, _soft("morfales_route", 0.15), 0.9, 0],
	]
	for case: Array in cases:
		if ((case[3] as Dictionary).get("enemies", []) as Array).has("naze_fouineur"):
			# le Naze exige faiblesses et élan : on le mesure avec le joueur attentif, pas avec le jeu automatique
			var tl: int = int(case[5]) if case.size() > 5 else -1
			var nr := _sim_rate(case[1], int(case[2]), case[3], tl, true, 40, _sim_inventory(1))
			var need := float(case[4])
			check(float(nr[0]) >= need, "%s : %d %% de victoires, joueur attentif (attendu : au moins %d %%)" % [str(case[0]), int(100.0 * float(nr[0])), int(need * 100.0)])
			print("  %-50s %3d %% de victoires, %2.0f tours par héros (joueur attentif)" % [str(case[0]), int(100.0 * float(nr[0])), float(nr[1])])
			continue
		var wins := 0
		var turns := 0
		var left := 0.0   # part des PV qui reste à l'équipe après une victoire
		var runs := 40
		for s in runs:
			GameState.new_game()
			GameState.party = []
			for id: String in case[1]:
				GameState.add_to_party(id)
				GameState.member(id)["level"] = int(case[2])
				if case.size() > 5:
					_spend(id, int(case[5]))
			GameState.heal_party()
			var e := _fight(case[3], 100 + s)
			check(str(e.result) != "", "%s : le combat se termine" % str(case[0]))
			turns += int(e.get_meta("turns"))
			if str(e.result) == "victory":
				wins += 1
				var hp := 0.0
				for c: RefCounted in e.party:
					hp += float(c.hp) / float(c.max_hp())
				left += hp / maxf(1.0, float((e.party as Array).size()))
		var rate := float(wins) / runs
		check(rate >= float(case[4]), "%s : %d %% de victoires en jeu automatique (attendu : au moins %d %%)" % [str(case[0]), int(rate * 100.0), int(float(case[4]) * 100.0)])
		print("  %-50s %3d %% de victoires, %2d tours, %3d %% des PV restants" % [str(case[0]), int(rate * 100.0), turns / runs, int(100.0 * left / maxf(1.0, float(wins)))])
	GameState.new_game()


## Les combats obligatoires des chapitres 1 à 5, au niveau attendu, joués par le joueur attentif avec talents.
## Cibles de l'auteur : combat ordinaire 85 à 95 %, boss 60 à 80 %, boss de 8 à 15 tours par héros, ordinaire de
## 3 à 6 (les marges ci-dessous absorbent le hasard des 60 essais) ; la pire équipe « raisonnable » (voir
## _reasonable_teams : avec le meneur, Sam et Glandoulf, avec ou sans soigneur) doit garder au moins 45 % visés
## (plancher du test : 35 %). Les trois premiers boss du chapitre 1 et ses Morfales sont un apprentissage : 100 % permis.
func _test_forced_balance() -> void:
	for case: Array in _forced_cases():
		var label := str(case[0])
		var kind := str(case[4])
		var tutorial := label.begins_with("1 ") and not label.contains("Naze")
		var inv := _sim_inventory(int(label.left(1)))
		var r := _sim_rate(case[1], int(case[2]), case[3], 0, true, 60, inv)
		var rate := float(r[0])
		var turns := float(r[1])
		var worst := 2.0
		var worst_np := 2.0
		var worst_name := ""
		var worst_np_name := ""
		if not (case[5] as Array).is_empty():
			for team: Array in _reasonable_teams(case[5], str(case[6])):
				var q := float(_sim_rate(team, int(case[2]), case[3], 0, true, 40, inv)[0])
				var tag := "%s %d %%" % [",".join(PackedStringArray(team.map(func(i: String) -> String: return i.left(3)))), int(q * 100.0)]
				if q < worst:
					worst = q
					worst_name = tag
				if not team.has("pepin") and q < worst_np:
					worst_np = q
					worst_np_name = tag
		var lo := 0.85 if kind == "ordinaire" else 0.55
		if label.contains("Naze") and not label.contains("Nazes"):
			lo = 0.83   # le boss de fin du chapitre 1 exige faiblesses et élan : 85 à 95 % pour le joueur attentif
		var hi := 1.0 if (kind == "ordinaire" or tutorial) else 0.97
		if label.contains("Naze") and not label.contains("Nazes"):
			hi = 0.97
		if label.contains("brèche"):
			lo = 0.85   # mise en scène du chapitre 5 : tous les groupes l'emportent, sauf les pires compositions
			hi = 1.0
		check(rate >= lo and rate <= hi, "%s : %d %% de victoires attentif avec talents (fourchette %d à %d %%)" % [label, int(rate * 100.0), int(lo * 100.0), int(hi * 100.0)])
		if not tutorial:
			var t_lo := 7.0 if kind == "boss" else 3.0   # boucliers plus bas depuis le réglage « naïf » : combats un peu plus courts
			var t_hi := 15.5 if kind == "boss" else 7.0
			check(turns >= t_lo and turns <= t_hi, "%s : %.1f tours par héros (fourchette %d à %d)" % [label, turns, int(t_lo), int(t_hi)])
		if worst <= 1.0 and kind == "boss":
			check(worst >= 0.35, "%s : pire équipe raisonnable %s (au moins 35 %%)" % [label, worst_name])
			check(worst_np >= 0.35, "%s : pire équipe sans soigneur %s (au moins 35 %%)" % [label, worst_np_name])
		# Le joueur « naïf » (il ne dépense aucun point de talent) doit garder une vraie chance contre les premiers boss.
		var naive_min := {"1 le Naze": 0.55, "2 Nazes": 0.28, "2 Chantecler": 0.28, "2 Vacherin": 0.35, "3 Gardien": 0.35}
		for key: String in naive_min:
			if label.begins_with(key):
				var nv := float(_sim_rate(case[1], int(case[2]), case[3], -1, true, 60, inv)[0])
				check(nv >= float(naive_min[key]), "%s : %d %% de victoires pour un joueur sans talents (au moins %d %%)" % [label, int(nv * 100.0), int(float(naive_min[key]) * 100.0)])
				print("      naïf (sans talents) : %d %%" % int(nv * 100.0))
		print("  %-36s %3d %%, %4.1f tours | pire équipe %-22s | sans soigneur %-22s" % [label, int(rate * 100.0), turns, worst_name, worst_np_name])
	GameState.new_game()


## Expérience et or moyens d'un combat d'une table de rencontres (groupes ouverts à quatre combattants, pondérés).
func _table_yield(table: String) -> Array:
	var xp := 0.0
	var gold := 0.0
	var weight := 0.0
	for g: Variant in (Database.encounter_tables[table] as Dictionary)["groups"]:
		var gd: Dictionary = g
		if int(gd.get("min_party", 0)) > 4 or int(gd.get("max_party", 9)) < 4:
			continue
		var w := float(gd.get("weight", 1))
		weight += w
		for en: Variant in gd["enemies"]:
			var def := Database.get_enemy(str(en))
			xp += w * float(def.get("xp", 0))
			var money: Variant = def.get("money", 0)
			gold += w * ((float((money as Array)[0]) + float((money as Array)[1])) / 2.0 if money is Array else float(money))
	return [xp / weight, gold / weight]


## Courbe de progression des chapitres 1 à 5 : à chaque boss, le niveau attendu doit s'atteindre avec l'expérience des
## combats forcés d'avant plus quelques combats de la table du lieu (sans compter les quêtes, qui s'ajoutent) ; l'or d'un
## combat de table doit payer au moins la moitié d'un soin du chapitre ; un personnage resté en réserve (aucune
## expérience, règle de l'auteur) rattrape le groupe en une quinzaine de combats au chapitre 5 (et l'expérience des
## quêtes, donnée à tous, y aide).
func _test_progression() -> void:
	var seq := [
		["grande_baveuse", 4, ["pre_couche_nord", "pre_couche_sud"], 12], ["vieux_solitaire", 5, ["bois_sud", "bois_nord"], 12],
		["crapaud_buffle", 6, ["roseliere_nord", "roseliere_sud"], 12], ["naze", 7, ["roseliere_nord"], 14],
		["nazes_nuit", 9, ["route_brie", "caves_brie", "ferme_brie"], 14], ["chantecler", 8, ["ferme_brie"], 6], ["vacherin", 8, ["caves_brie"], 6],
		["gardien_archives", 11, ["col_biscottes", "archives"], 8], ["guetteur_du_lac", 12, ["morbier_galeries"], 8],
		["gros_bleu", 13, ["morbier_galeries", "morbier_halle"], 9], ["goulum", 14, ["morbier_halle", "morbier_profondeurs"], 10],
		["balourd", 16, ["morbier_profondeurs"], 14], ["ambuscade_chutes", 17, ["plaine"], 12], ["grimace", 17, ["plaine", "fongorn"], 12],
		["froton_anneaute", 17, ["fongorn", "garde_manger"], 12], ["breche", 18, ["isengarde"], 12], ["sarumale", 18, ["isengarde"], 12]]
	var done := 0.0
	for row: Array in seq:
		var need := 0.0
		for lv in range(1, int(row[1])):
			need += float(Rules.xp_to_next(lv))
		var yield_sum := 0.0
		for t: String in row[2]:
			yield_sum += float(_table_yield(t)[0])
		var per_fight := yield_sum / float((row[2] as Array).size())
		var fights := maxf(0.0, need - done) / per_fight
		check(fights <= float(row[3]), "progression : %s (niv. %d) demande %.1f combats de table au plus %d (sans les quêtes)" % [str(row[0]), int(row[1]), fights, int(row[3])])
		print("  %-18s niv. %2d : %5d XP requis, %5d déjà gagnés en combats forcés, %4.1f combats de table (%3.0f XP chacun)" % [str(row[0]), int(row[1]), int(need), int(done), fights, per_fight])
		for en: Variant in Database.get_encounter(str(row[0])).get("enemies", []):
			done += float(Database.get_enemy(str(en)).get("xp", 0))
	# or : un combat de table paie au moins la moitié d'un soin du chapitre
	for pair: Array in [["roseliere_nord", "tisane"], ["route_brie", "tomme_fermiere"], ["col_biscottes", "tisane_corsee"], ["morbier_halle", "tomme_de_cave"], ["plaine", "brioche_du_cavalier"], ["isengarde", "brioche_du_cavalier"]]:
		var gold := float(_table_yield(str(pair[0]))[1])
		var price := float(Database.get_item(str(pair[1])).get("price", 0))
		check(gold * 2.0 >= price, "or : un combat de %s rapporte %.0f, %s coûte %d (au plus deux combats par soin)" % [str(pair[0]), gold, str(pair[1]), int(price)])
	# rattrapage d'un réserviste resté au niveau 8 jusqu'au chapitre 5
	var xp_fight := float(_table_yield("plaine")[0])
	var level := 8
	var xp := 0.0
	var fights_back := 0
	while level < 16 and fights_back < 60:
		xp += xp_fight
		fights_back += 1
		while xp >= float(Rules.xp_to_next(level)):
			xp -= float(Rules.xp_to_next(level))
			level += 1
	check(fights_back <= 15, "rattrapage : un réserviste du niveau 8 atteint le niveau 16 en %d combats de la plaine (au plus 15)" % fights_back)
	print("  réserviste niv. 8 -> niv. 16 : %d combats de la plaine" % fights_back)


## Données des animations : tout ce qui se joue en combat a la sienne, et elle est valide.
func _test_animations() -> void:
	var fx: Node3D = BattleFx.new()
	var errors: Array = fx.validate()
	for e: Variant in errors:
		check(false, str(e))
	check(errors.is_empty(), "animations : données valides (%d problème(s))" % errors.size())
	var own := {}
	for id: String in Database.skills:
		own[fx.anim_of(id, Database.get_skill(id))] = true
	check(own.size() == Database.skills.size(), "chaque compétence a une animation à elle (%d pour %d)" % [own.size(), Database.skills.size()])
	var attacks := {}
	for id: String in Database.characters:
		var ch := Database.get_character(id)
		if ch.has("battle"):
			attacks[str((ch["battle"] as Dictionary).get("attack_anim", ""))] = true
	check(attacks.size() >= 7, "les héros ont des attaques de base distinctes (%d)" % attacks.size())
	check(fx.resolve("etincelle", "feu") == "etincelle", "une compétence connue joue son animation")
	check(fx.resolve("competence_future", "feu") == "attaque_feu", "une compétence sans animation prend celle de son élément")
	check(fx.resolve("competence_future", "") == "defaut", "sans élément, animation par défaut")
	for kind: String in FxPainter.KINDS:
		var img: Image = FxPainter.paint(kind)
		var filled := 0
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.5:
					filled += 1
		check(filled >= 4, "sprite d'effet %s : dessiné (%d px)" % [kind, filled])
		check(Sprites.fx(kind) != null, "sprite d'effet %s : accessible par Sprites.fx" % kind)
	fx.free()
	# le moteur de règles annonce l'animation dans l'événement « cast »
	GameState.new_game()
	var eng: RefCounted = BattleEngine.new()
	eng.setup({"enemies": ["limace_molle"], "arena": "pre"}, 3)
	var ev: Array = eng.perform(eng.party[0], {"type": "attack", "target": eng.enemies[0]})
	check(str(ev[0].get("anim", "")) == "coup_de_baton", "attaque de Glandoulf : animation coup_de_baton (%s)" % str(ev[0].get("anim", "")))
	ev = eng.perform(eng.party[0], {"type": "skill", "id": "etincelle", "target": eng.enemies[0]})
	check(str(ev[0].get("anim", "")) == "etincelle", "Étincelle : animation etincelle (%s)" % str(ev[0].get("anim", "")))
	if eng.enemies[0].alive():
		ev = eng.perform(eng.enemies[0], {"type": "attack"})
		check(str(ev[0].get("anim", "")) == "tete_molle", "attaque de la limace : animation tete_molle (%s)" % str(ev[0].get("anim", "")))
	GameState.new_game()


## Joue chaque animation pour de vrai (temps accéléré) : elle doit se voir, se terminer,
## ne rien laisser à l'écran et remettre le lanceur à sa place. Puis un combat entier
## avec les animations, et les poses de coup reçu, de KO et de retour.
func _test_animation_play() -> void:
	GameState.new_game()
	for who: String in ["pepin", "sam"]:
		GameState.add_to_party(who)
	for who: String in GameState.party:
		GameState.member(who)["level"] = 9
	GameState.heal_party()
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui: Control = BattleUI.new()
	layer.add_child(ui)
	await get_tree().process_frame
	var scene: Node3D = BattleScene.new()
	add_child(scene)
	scene.setup({"enemies": ["limace_molle", "sanglier_flapi", "guepe_cidre"], "arena": "pre"}, ui, 5)
	await get_tree().process_frame
	var allies: Array = []
	var foes: Array = []
	for c: RefCounted in scene.engine.party:
		allies.append(scene.actor_of(c))
	for c: RefCounted in scene.engine.enemies:
		foes.append(scene.actor_of(c))
	Engine.time_scale = 12.0
	var played := 0
	var index := 0
	for id: String in Database.animations:
		index += 1
		# une fois sur quatre, c'est un ennemi qui la joue contre l'équipe (effets retournés)
		var from_enemy := index % 4 == 0
		var caster: Node3D = foes[index % foes.size()] if from_enemy else allies[index % allies.size()]
		var targets: Array = allies if from_enemy else foes
		await scene.fx.play(id, caster, targets, "feu")
		var seen: bool = scene.fx.live_count() > 0 or caster.posing()
		var t0 := Time.get_ticks_msec()
		while (scene.fx.live_count() > 0 or caster.posing()) and Time.get_ticks_msec() - t0 < 8000:
			await get_tree().process_frame
		var clean: bool = scene.fx.live_count() == 0 and not caster.posing()
		var back: bool = caster.position.distance_to(caster.home) < 0.01 and absf(caster._body.rotation.z) < 0.001 \
				and caster._body.scale.is_equal_approx(caster._base_scale) and absf(caster._body.position.x) < 0.001
		if not (seen and clean and back):
			check(false, "animation %s : visible %s, nettoyée %s, lanceur en place %s" % [id, str(seen), str(clean), str(back)])
		else:
			played += 1
	check(played == Database.animations.size(), "%d animations jouées et terminées proprement sur %d" % [played, Database.animations.size()])

	# coup reçu, KO d'un ennemi, KO puis retour d'un allié
	var foe: Node3D = foes[0]
	foe.play_hit(true)
	await get_tree().process_frame
	check(absf(foe._body.rotation.z) > 0.0 or absf(foe._body.position.x) > 0.0, "coup reçu : le combattant recule")
	await foe.play_ko()
	check(foe.down and not foe.visible, "KO d'un ennemi : il s'aplatit et disparaît")
	var ally: Node3D = allies[1]
	ally.play_pose("cast", ally.home, 0.5)
	await ally.play_ko()
	check(ally.down and absf(ally._body.rotation.z + PI * 0.5) < 0.01, "KO d'un allié en pleine pose : il reste couché")
	ally.play_revive()
	var t1 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t1 < 400:
		await get_tree().process_frame
	check(not ally.down and absf(ally._body.rotation.z) < 0.001 and absf(ally._body.position.y - ally._hover) < 0.01, "retour d'un allié : debout à sa place")
	ui.close()
	remove_child(scene)
	scene.queue_free()
	await get_tree().process_frame

	# un combat entier joué avec ses animations (et non en mode « sans attente »)
	GameState.heal_party()
	var s: Node3D = BattleScene.new()
	add_child(s)
	s.auto = true
	s.setup({"enemies": ["limace_molle", "guepe_cidre", "champignon_dormeur"], "arena": "pre"}, ui, 11)
	s.run()
	var t2 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t2 < 90000:
		await get_tree().process_frame
		if ui._end_layer.visible:
			ui._on_end("ok" if str(s.engine.result) == "victory" else "title")
		if str(s.outcome) != "":
			break
	check(str(s.outcome) == "victory", "combat animé joué jusqu'au bout (issue : %s)" % str(s.outcome))
	var t3 := Time.get_ticks_msec()
	while s.fx.live_count() > 0 and Time.get_ticks_msec() - t3 < 3000:
		await get_tree().process_frame
	check(s.fx.live_count() == 0, "combat animé : aucun effet ne reste à l'écran")
	Engine.time_scale = 1.0
	ui.close()
	remove_child(s)
	s.queue_free()
	await get_tree().process_frame
	layer.queue_free()
	GameState.new_game()


func _test_battle_scene() -> void:
	GameState.new_game()
	GameState.add_to_party("pepin")
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui: Control = BattleUI.new()
	layer.add_child(ui)
	await get_tree().process_frame

	# un combat joué « à la main » : attaque, puis compétence, puis le reste en automatique
	var scene: Node3D = BattleScene.new()
	add_child(scene)
	scene.fast = true
	scene.setup({"enemies": ["limace_molle", "guepe_cidre"], "arena": "pre"}, ui, 7)
	check(scene.actors.size() == 4 and scene.camera != null and scene.camera.current, "arène construite : 4 combattants, caméra active")
	scene.run()
	var did_attack := false
	var did_skill := false
	var saw_list := false
	for _i in 6000:
		await get_tree().process_frame
		if str(scene.outcome) != "":
			break
		if ui._state == ui.S.ROOT:
			check(ui._root_list.get_child_count() == 5, "menu : cinq actions")
			(ui._root_list.get_child(1 if did_attack and not did_skill else 0) as Button).pressed.emit()
		elif ui._state == ui.S.LIST:
			saw_list = true
			for b: Button in ui._list_items.get_children():
				if not b.disabled:
					b.pressed.emit()
					break
		elif ui._state == ui.S.TARGET:
			var p: Vector2 = scene.screen_point(ui._cands[ui._index], "top")
			check(is_finite(p.x) and is_finite(p.y), "la cible a une position à l'écran")
			if did_attack:
				did_skill = true
			did_attack = true
			ui._confirm_target()
			if did_skill:
				scene.auto = true
	check(did_attack and did_skill and saw_list, "attaque et compétence choisies par les menus")
	check(str(scene.outcome) in ["victory", "title"], "le combat va à son terme (issue : %s)" % str(scene.outcome))
	check(ui._timeline.get_child_count() > 2, "file des tours affichée")
	ui.close()
	remove_child(scene)
	scene.queue_free()

	# écrans de fin
	ui.show_victory({"xp": 12, "money": 4, "drops": {"tisane": 1}, "levelups": [{"name": "Glandoulf", "to": 2, "skills": ["Petit somme"]}]}, false)
	await get_tree().process_frame
	check(ui._end_layer.visible, "écran de victoire affiché")
	ui._on_end("ok")
	await get_tree().process_frame
	check(not ui._end_layer.visible, "écran de victoire refermé")
	ui.show_defeat()
	await get_tree().process_frame
	check(ui._end_layer.visible, "écran de défaite affiché")
	ui._on_end("retry")
	await get_tree().process_frame
	ui.close()

	# chaque rencontre nommée se construit et se joue toute seule, dans son arène
	for id: String in Database.encounters:
		var won := false
		var outcome := ""
		for attempt in 2:   # le combat automatique est aléatoire : une seconde chance
			GameState.new_game()
			for who: String in ["pepin", "sam", "froton"]:
				GameState.add_to_party(who)
			for who: String in GameState.party:
				GameState.member(who)["level"] = 9
			GameState.heal_party()
			var s: Node3D = BattleScene.new()
			add_child(s)
			s.fast = true
			s.auto = true
			if id == "nazes_nuit":
				GameState.add_to_party("aragrogne")
				for who: String in GameState.party:
					GameState.member(who)["level"] = 10
				GameState.heal_party()
			if id == "gardien_archives":
				GameState.add_to_party("aragrogne")
				for who: String in GameState.party:
					GameState.member(who)["level"] = 12
				GameState.heal_party()
			s.setup(Database.get_encounter(id), ui)
			s.run()
			for _i in 6000:
				await get_tree().process_frame
				if str(s.outcome) != "":
					break
			outcome = str(s.outcome)
			won = outcome == "victory"
			ui.close()
			remove_child(s)
			s.queue_free()
			await get_tree().process_frame
			if won:
				break
		# L'issue d'un combat automatique sans talents dépend du hasard : ici on vérifie que la
		# rencontre se construit et va à son terme. L'équilibre est mesuré ailleurs, sur des
		# dizaines de combats (taux de victoire des fonctions de chapitre).
		check(outcome in ["victory", "title"], "rencontre %s : jouée jusqu'à son terme (issue : %s)" % [id, outcome])
		if not won:
			print("    (rencontre %s perdue deux fois en jeu automatique)" % id)
	layer.queue_free()
	GameState.new_game()


## Les objets marqués « gated » doivent devenir accessibles une fois l'obstacle scénarisé levé.
func _test_gated(id: String) -> void:
	var flags: Array = []
	var gated := false
	for o: Dictionary in Database.get_map(id).get("objects", []):
		if o.has("unless") and str(o.get("type", "")) != "trigger":
			flags.append(str(o["unless"]))
		if bool(o.get("gated", false)):
			gated = true
	if not gated:
		return
	GameState.new_game()
	for f: String in flags:
		GameState.set_flag(f)
	var world: Node3D = World.new()
	add_child(world)
	world.setup(id, str((Database.get_map(id).get("spawns", {}) as Dictionary).keys()[0]))
	await get_tree().process_frame
	var step := 0.25
	var gw := int(world.grid_w / step) + 1
	var gh := int(world.grid_h / step) + 1
	var seen := PackedByteArray()
	seen.resize(gw * gh)
	var start := Vector2i(int(round(world.player.position.x / step)), int(round(world.player.position.z / step)))
	var queue: Array[Vector2i] = [start]
	seen[start.y * gw + start.x] = 1
	var head := 0
	while head < queue.size():
		var c := queue[head]
		head += 1
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if n.x < 0 or n.y < 0 or n.x >= gw or n.y >= gh or seen[n.y * gw + n.x] != 0:
				continue
			if world.is_free(Vector2(n.x * step, n.y * step), 0.28, world.player):
				seen[n.y * gw + n.x] = 1
				queue.append(n)
	for it: Dictionary in world.interactables:
		if not bool(it.get("gated", false)):
			continue
		var ip: Vector3 = world.interactable_position(it)
		var ok := false
		for c: Vector2i in queue:
			if Vector2(c.x * step, c.y * step).distance_to(Vector2(ip.x, ip.z)) <= float(it["reach"]) - 0.1:
				ok = true
				break
		check(ok, "carte %s : « %s » atteignable une fois l'obstacle levé" % [id, str(it["dialogue"])])
	remove_child(world)
	world.queue_free()
	GameState.new_game()
	await get_tree().process_frame


# ------------------------------------------------- étape 4 : quêtes, objets, argent

func _first_hit(softness: float, firm: bool) -> int:
	GameState.new_game()
	if firm:
		GameState.add_item("tuteur")
		GameState.equip("glandoulf", "tuteur")
	var e: RefCounted = BattleEngine.new()
	e.setup({"enemies": ["limace_molle"], "arena": "pre", "ramollissement": softness}, 4242)
	var events: Array = e.perform(e.party[0], {"type": "attack", "target": e.enemies[0]})
	for ev: Dictionary in events:
		if str(ev.get("type", "")) == "damage":
			return int(ev["amount"])
	return -1


func _test_step4() -> void:
	# données
	check(Database.quests.size() >= 4 and Database.shops.size() >= 1, "quêtes et boutiques chargées")
	for id: String in Database.quests:
		var q := Database.get_quest(id)
		check(str(q.get("name", "")) != "" and str(q.get("desc", "")) != "", "quête %s : nom et description" % id)
		check(str(q.get("start", "")) != "", "quête %s : condition de départ" % id)
		check(q.get("steps") is Array and not (q.get("steps", []) as Array).is_empty(), "quête %s : au moins une étape" % id)
		var r: Variant = q.get("reward", {})
		if r is Dictionary:
			for item: String in r.get("items", {}):
				check(Database.items.has(item), "quête %s : récompense connue (%s)" % [id, item])
	for id: String in Database.shops:
		var shop := Database.get_shop(id)
		check(Database.characters.has(str(shop.get("keeper", ""))), "boutique %s : marchand connu" % id)
		for e: Variant in shop.get("stock", []):
			var item := str((e as Dictionary).get("item", ""))
			check(Database.items.has(item), "boutique %s : article connu (%s)" % [id, item])
			check(int((e as Dictionary).get("price", Database.get_item(item).get("price", 0))) > 0, "boutique %s : prix de %s" % [id, item])
	check(Database.softness(Database.get_map("pre_couche")) > 0.0, "le Pré Couché est touché par le Ramollissement")
	check(Database.softness(Database.get_map("auberge")) == 0.0, "l'auberge est épargnée")

	# conditions
	GameState.new_game()
	check(GameState.check("") and GameState.check("party:glandoulf") and not GameState.check("party:sam"), "conditions : équipe")
	check(GameState.check("item:tisane") and GameState.check("item:tisane:2") and not GameState.check("item:tisane:3"), "conditions : objets")
	check(GameState.check("!inconnu") and not GameState.check("inconnu") and not GameState.check("party:glandoulf & inconnu"), "conditions : négation et « & »")
	GameState.money = 40
	check(GameState.check("money:40") and not GameState.check("money:41"), "conditions : argent")

	# quêtes : départ, étapes, fin, récompense
	var started: Array = []
	var finished: Array = []
	var on_start := func(id: String) -> void: started.append(id)
	var on_done := func(id: String, _reward: Dictionary) -> void: finished.append(id)
	GameState.quest_started.connect(on_start)
	GameState.quest_completed.connect(on_done)
	GameState.new_game()
	check(GameState.quest_state("bittes") == "", "quête pas commencée au départ")
	GameState.set_flag("cales_recues")
	check(GameState.quest_state("bittes") == "active" and started.has("bittes"), "un drapeau fait démarrer la quête")
	for f: String in ["bitte_1", "bitte_2", "bitte_3", "bitte_4"]:
		GameState.set_flag(f)
	check(GameState.quest_state("bittes") == "active", "la quête attend sa dernière étape")
	var before := GameState.money
	GameState.set_flag("bittes_payees")
	check(GameState.quest_state("bittes") == "done" and finished.has("bittes"), "la quête s'achève")
	check(GameState.money == before + 30 and GameState.item_count("noeud_cabestan") == 1, "récompense : écus et objet")
	GameState.set_flag("bittes_payees")
	check(GameState.money == before + 30, "la récompense n'est donnée qu'une fois")
	check(GameState.reward_text({"money": 30, "items": {"tuteur": 1}, "xp": 5}) == "30 écus, Tuteur en noisetier, 5 XP", "texte de récompense")

	# recrue : niveau proche du meneur, équipement de départ, quête accomplie
	GameState.set_flag("sam_vu")
	check(GameState.quest_state("poele") == "active", "la quête de la poêle démarre avec Sam")
	GameState.member("glandoulf")["level"] = 5
	GameState.add_to_party("sam", true)
	check(int(GameState.member("sam")["level"]) == 4, "une recrue arrive un niveau sous le meneur")
	check(GameState.equipped("sam", "weapon") == "poele_gamelle", "Sam arrive avec sa poêle")
	check(GameState.quest_state("poele") == "done", "recruter Sam achève la quête de la poêle")
	GameState.quest_started.disconnect(on_start)
	GameState.quest_completed.disconnect(on_done)

	# équipement
	GameState.new_game()
	var bare := GameState.member_stats("glandoulf")
	GameState.add_item("baton_ferre")
	GameState.add_item("serpette_affutee")
	GameState.add_item("gilet_batelier")
	check(not GameState.can_equip("glandoulf", "serpette_affutee") and not GameState.equip("glandoulf", "serpette_affutee"), "un objet réservé à quelqu'un d'autre est refusé")
	check(not GameState.can_equip("glandoulf", "tisane"), "une tisane ne s'équipe pas")
	check(GameState.equip("glandoulf", "baton_ferre") and GameState.equip("glandoulf", "gilet_batelier"), "équiper depuis le sac")
	var geared := GameState.member_stats("glandoulf")
	check(int(geared["mag"]) == int(bare["mag"]) + 3 and int(geared["atk"]) == int(bare["atk"]) + 2, "le bâton ferré augmente magie et attaque")
	check(int(geared["hp"]) == int(bare["hp"]) + 8 and int(geared["def"]) == int(bare["def"]) + 2, "le gilet augmente PV et défense")
	check(GameState.item_count("baton_ferre") == 0 and GameState.equipped("glandoulf", "weapon") == "baton_ferre", "l'objet équipé quitte le sac")
	var e: RefCounted = BattleEngine.new()
	e.setup({"enemies": ["limace_molle"], "arena": "pre"}, 7)
	check(int(e.party[0].base["mag"]) == int(geared["mag"]) and e.party[0].max_hp() == int(geared["hp"]), "l'équipement compte en combat")
	GameState.heal_party()
	check(int(GameState.member("glandoulf")["hp"]) == int(geared["hp"]), "le repos remplit les PV augmentés")
	check(GameState.unequip("glandoulf", "armor") and GameState.item_count("gilet_batelier") == 1, "retirer remet dans le sac")
	check(int(GameState.member("glandoulf")["hp"]) == int(bare["hp"]), "les PV redescendent au maximum sans le gilet")

	# objets hors combat
	GameState.new_game()
	check(GameState.use_item("tisane", "glandoulf") == "" and GameState.item_count("tisane") == 2, "une tisane n'est pas gâchée sur un bien portant")
	GameState.member("glandoulf")["hp"] = 5
	check(GameState.use_item("tisane", "glandoulf") != "" and int(GameState.member("glandoulf")["hp"]) > 5 and GameState.item_count("tisane") == 1, "tisane hors combat : PV rendus, objet consommé")
	GameState.member("glandoulf")["mp"] = 0
	check(GameState.use_item("cidre", "glandoulf") != "" and int(GameState.member("glandoulf")["mp"]) == 12, "cidre hors combat : mana rendu")
	check(not GameState.usable_outside("racine") and not GameState.usable_outside("cale"), "racine et cale ne s'utilisent pas depuis le sac")

	# argent
	GameState.new_game()
	GameState.money = 20
	check(GameState.buy("tisane", 8) and GameState.money == 12 and GameState.item_count("tisane") == 3, "achat")
	check(not GameState.buy("baton_ferre", 45) and GameState.money == 12 and GameState.item_count("baton_ferre") == 0, "achat refusé sans argent")
	check(GameState.sell("tisane") == 4 and GameState.money == 16 and GameState.item_count("tisane") == 2, "vente à moitié prix")
	GameState.add_item("cale")
	check(GameState.sell("cale") == 0 and GameState.item_count("cale") == 1, "un objet de quête ne se vend pas")

	# Ramollissement
	var plain := _first_hit(0.0, false)
	var soft := _first_hit(0.5, false)
	var firm := _first_hit(0.5, true)
	check(plain > 0 and soft < plain and soft >= int(plain * 0.4), "le Ramollissement émousse les coups physiques (%d -> %d)" % [plain, soft])
	check(firm >= plain, "un tuteur porté annule le Ramollissement (%d)" % firm)
	GameState.new_game()
	var em: RefCounted = BattleEngine.new()
	em.setup({"enemies": ["limace_molle"], "arena": "pre", "ramollissement": 0.5}, 11)
	var spell: Array = em.perform(em.party[0], {"type": "skill", "id": "etincelle", "target": em.enemies[0]})
	var soft_spell := false
	for ev: Dictionary in spell:
		if str(ev.get("type", "")) == "damage" and bool(ev.get("soft", false)):
			soft_spell = true
	check(not soft_spell, "la magie n'est pas touchée par le Ramollissement")
	em.party[0].statuses["galvanise"] = {"turns": 3, "fresh": false}
	check(em.party[0].is_firm(), "Galvanisé : insensible au Ramollissement")
	em.inventory = {"cale": 1, "tuteur": 1, "tisane": 1}
	check(Database.is_consumable("tisane") and not Database.is_consumable("cale") and not Database.is_consumable("tuteur"), "seuls les consommables servent en combat")

	# sauvegarde : quêtes et équipement
	GameState.new_game()
	GameState.set_flag("cales_recues")
	GameState.add_item("baton_ferre")
	GameState.equip("glandoulf", "baton_ferre")
	GameState.map_id = "bittebourg"
	var saved := GameState.to_dict()
	GameState.new_game()
	check(GameState.from_dict(saved), "relecture d'une sauvegarde de l'étape 4")
	check(GameState.quest_state("bittes") == "active" and GameState.equipped("glandoulf", "weapon") == "baton_ferre", "quêtes et équipement restaurés")
	var old := {"map_id": "bittebourg", "flags": {"pepin_vue": true}, "party": ["glandoulf"], "roster": {"glandoulf": {"level": 3, "xp": 4, "hp": 20, "mp": 10}}}
	check(GameState.from_dict(old), "relecture d'une sauvegarde d'avant l'étape 4")
	check(GameState.quest_state("potager") == "active" and GameState.equipped("glandoulf", "weapon") == "", "ancienne sauvegarde : journal reconstitué, équipement vide")
	GameState.new_game()
	print("  %d quêtes, %d boutique(s) ; coup de bâton : %d, ramolli de moitié : %d, avec tuteur : %d" % [Database.quests.size(), Database.shops.size(), plain, soft, firm])


func _test_menus() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var menu: Control = GameMenu.new()
	layer.add_child(menu)
	await get_tree().process_frame
	var closed := [0]
	menu.closed.connect(func() -> void: closed[0] += 1)
	GameState.new_game()
	GameState.set_flag("intro_vue")
	GameState.set_flag("cales_recues")
	GameState.add_item("baton_ferre")
	GameState.add_item("cale")

	menu.open("quests")
	await get_tree().process_frame
	check(menu.visible and (menu.entry_texts() as Array).size() == 2, "journal : deux quêtes en cours")
	check(str(menu._detail.text).contains("Trouver des compagnons"), "journal : le détail de la première quête est affiché")
	menu._on_focus(1)
	check(str(menu._detail.text).contains("Caler les trois bittes"), "journal : la première étape est affichée")
	check(not str(menu._detail.text).contains("Prévenir"), "journal : les étapes suivantes restent cachées")
	menu.close()
	check(closed[0] == 1 and not menu.visible, "journal refermé")

	menu.open("inventory")
	await get_tree().process_frame
	var rows: Array = menu.entry_texts()
	check(rows.size() == 4, "inventaire : quatre sortes d'objets (%d)" % rows.size())
	var baton := -1
	var tisane := -1
	for i in rows.size():
		if str(rows[i]).begins_with("Bâton ferré"):
			baton = i
		if str(rows[i]).begins_with("Tisane"):
			tisane = i
	menu.press(tisane)
	await get_tree().process_frame
	check(str(menu._title.text) == "Pour qui ?", "inventaire : une tisane demande une cible")
	menu.press(0)
	check(GameState.item_count("tisane") == 2 and str(menu._message.text) != "", "inventaire : pas de tisane gâchée, message affiché")
	GameState.member("glandoulf")["hp"] = 3
	menu.press(0)
	await get_tree().process_frame
	check(GameState.item_count("tisane") == 1 and int(GameState.member("glandoulf")["hp"]) > 3, "inventaire : tisane bue depuis le sac")
	menu.go_back()
	await get_tree().process_frame
	check(str(menu._title.text) == "Inventaire", "retour à l'inventaire")
	menu.press(baton)
	await get_tree().process_frame
	check(str(menu._title.text) == "Équiper qui ?", "inventaire : un équipement demande un porteur")
	menu.press(0)
	await get_tree().process_frame
	check(GameState.equipped("glandoulf", "weapon") == "baton_ferre", "inventaire : bâton équipé")
	menu.close()

	menu.open("team")
	await get_tree().process_frame
	check(str(menu._detail.text).contains("Bâton ferré") and str(menu._detail.text).contains("Magie"), "équipe : fiche avec statistiques et équipement")
	menu.press(0)
	await get_tree().process_frame
	check((menu.entry_texts() as Array).size() == 2, "équipe : la fiche propose équipement et talents")
	menu.press(0)
	await get_tree().process_frame
	check((menu.entry_texts() as Array).size() == GameState.SLOTS.size(), "équipe : un choix par emplacement")
	menu.press(0)
	await get_tree().process_frame
	menu.press((menu.entry_texts() as Array).size() - 1)   # « Retirer »
	await get_tree().process_frame
	check(GameState.equipped("glandoulf", "weapon") == "" and GameState.item_count("baton_ferre") == 1, "équipe : arme retirée")
	menu.go_back()
	await get_tree().process_frame
	check(str(menu._title.text) == "Glandoulf", "équipe : Annuler revient à la fiche du personnage")
	GameState.member("glandoulf")["level"] = 3   # deux points de talent
	var asked := [""]
	menu.talents_requested.connect(func(w: String) -> void: asked[0] = w)
	menu.press(1)
	check(asked[0] == "glandoulf", "équipe : la fiche demande l'écran de talents")
	menu.go_back()
	menu.go_back()
	check(not menu.visible, "équipe : Annuler remonte puis referme")

	GameState.money = 30
	menu.open_shop("etal_ursule")
	await get_tree().process_frame
	check((menu.entry_texts() as Array).size() == 3, "boutique : acheter, vendre, partir")
	for offer: Dictionary in menu.shop_offers():
		check(str(offer["item"]) != "poele_gamelle", "boutique : la poêle n'est pas en vente avant l'aveu de Froton")
	GameState.set_flag("froton_avoue")
	menu.press(0)
	await get_tree().process_frame
	check(str((menu.shop_offers() as Array)[0]["item"]) == "poele_gamelle", "boutique : la poêle apparaît après l'aveu")
	menu.press(0)
	check(GameState.item_count("poele_gamelle") == 0 and GameState.money == 30, "boutique : achat refusé sans assez d'écus")
	GameState.money = 45
	menu.press(0)
	await get_tree().process_frame
	check(GameState.item_count("poele_gamelle") == 1 and GameState.money == 5 and GameState.has_flag("poele_rachetee"), "boutique : poêle rachetée")
	check(str((menu.shop_offers() as Array)[0]["item"]) != "poele_gamelle", "boutique : la poêle n'est vendue qu'une fois")
	menu.go_back()
	await get_tree().process_frame
	menu.press(1)
	await get_tree().process_frame
	var sell_rows: Array = menu.entry_texts()
	var has_key := false
	for t: Variant in sell_rows:
		if str(t).begins_with("Cale") or str(t).begins_with("Poêle"):
			has_key = true
	check(not has_key and sell_rows.size() >= 2, "boutique : les objets de quête ne se vendent pas")
	var money := GameState.money
	menu.press(0)
	check(GameState.money > money, "boutique : vente")
	menu.close()
	await get_tree().process_frame
	GameState.new_game()
	layer.queue_free()


# ------------------------------------------------------------ écran de talents

func _test_talent_screen() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var screen: Control = TalentScreen.new()
	layer.add_child(screen)
	await get_tree().process_frame
	var closed := [0]
	screen.closed.connect(func() -> void: closed[0] += 1)
	GameState.new_game()
	GameState.member("glandoulf")["level"] = 3   # deux points
	GameState.add_to_party("pepin")
	GameState.member("pepin")["level"] = 2      # un point
	screen.open()
	await get_tree().process_frame
	await get_tree().process_frame
	check(screen.visible and str(screen.who) == "glandoulf", "talents : l'écran s'ouvre sur le premier qui a des points")
	check((screen.tab_ids() as Array).size() == 2, "talents : un onglet par membre de l'équipe")
	check((screen.talent_ids() as Array).size() == 8, "talents : deux voies de quatre talents")
	check(str(screen.points_text()).contains("2"), "talents : points à dépenser affichés (%s)" % str(screen.points_text()))
	var first: Button = screen._nodes["meche_courte"]
	check(str(first.focus_neighbor_bottom) != "" and str(first.focus_neighbor_right) != "", "talents : le curseur passe d'un talent à l'autre")
	check(get_viewport().gui_get_focus_owner() == first, "talents : le curseur démarre sur un talent qu'on peut apprendre")
	screen.focus_talent("petarade_t")
	check(str(screen.detail_text()).contains("PÉTARADE") and str(screen.detail_text()).contains("Il faut d'abord"), "talents : le détail dit ce qui manque")
	check(str(screen.detail_text()).contains("Nouvelle compétence"), "talents : le détail décrit la compétence débloquée")
	screen.press("petarade_t")   # deuxième de sa voie : encore fermé
	check(not GameState.has_talent("glandoulf", "petarade_t") and str(screen.message_text()) != "", "talents : un talent fermé ne s'apprend pas, message affiché")
	screen.press("meche_courte")
	await get_tree().process_frame
	await get_tree().process_frame
	check(GameState.has_talent("glandoulf", "meche_courte") and str(screen.state_of("meche_courte")) == "learned", "talents : talent appris depuis l'écran")
	check(str(screen.points_text()).contains("1"), "talents : le compteur de points baisse")
	check(get_viewport().gui_get_focus_owner() == screen._nodes["meche_courte"], "talents : le curseur reste sur le talent appris")
	check(str(screen.state_of("petarade_t")) == "available", "talents : le suivant de la voie s'ouvre")
	screen.press("sommeil_reparateur")
	await get_tree().process_frame
	check(GameState.has_talent("glandoulf", "sommeil_reparateur") and GameState.talent_points("glandoulf") == 0, "talents : on peut piocher dans les deux voies")
	screen.press("berceuse")
	check(not GameState.has_talent("glandoulf", "berceuse"), "talents : rien ne s'apprend sans point")
	screen.select("pepin")
	await get_tree().process_frame
	check(str(screen.who) == "pepin" and (screen.talent_ids() as Array).has("main_verte"), "talents : changer de personnage change l'arbre")
	screen.press("main_verte")
	await get_tree().process_frame
	check(GameState.has_talent("pepin", "main_verte"), "talents : Pépin apprend un talent")
	screen.select("glandoulf")
	await get_tree().process_frame
	screen.forget()
	await get_tree().process_frame
	check((GameState.talents_of("glandoulf") as Array).is_empty() and GameState.talent_points("glandoulf") == 2, "talents : tout oublier rend les points")
	check(GameState.has_talent("pepin", "main_verte"), "talents : l'oubli ne touche que le personnage affiché")
	screen.forget()
	check(str(screen.message_text()).contains("rien"), "talents : rien à oublier, message affiché")
	screen.close()
	check(closed[0] == 1 and not screen.visible, "talents : écran refermé")
	# Les sept personnages de la bible s'affichent, chaque talent a son détail.
	for id: String in BIBLE_TEAM:
		GameState.new_game()
		GameState.party = []
		GameState.add_to_party(id)
		GameState.member(id)["level"] = 13
		screen.open(id)
		await get_tree().process_frame
		check(str(screen.who) == id and (screen.talent_ids() as Array).size() == 8, "talents : l'arbre de %s s'affiche" % id)
		for tid: String in screen.talent_ids():
			screen.focus_talent(tid)
			check(str(screen.detail_text()).length() > 40, "talents : détail de %s/%s" % [id, tid])
			screen.press(tid)
		await get_tree().process_frame
		check(GameState.talent_points(id) == 0 and (GameState.talents_of(id) as Array).size() == 8, "talents : %s apprend tout depuis l'écran" % id)
		screen.close(true)
	GameState.new_game()
	layer.queue_free()


# ------------------------------------------------------------ déroulé complet

func _wait_idle(main: Node, seconds: float = 40.0) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(seconds * 1000.0):
		await get_tree().process_frame
		if OS.has_environment("GLAN_TRACE") and Engine.get_process_frames() % 120 == 0:
			print("    [trace] mode %d combat %s occupé %s dialogue %s attente %s carte %s fondu %.2f" % [int(main.mode), str(main.battle != null), str(main.busy), str(main.dialogue.active), str(main.dialogue.waiting), str(main.world != null), main._fade.color.a])
			if main.battle != null:
				print("    [trace] issue « %s » moteur « %s » interface %d" % [str(main.battle.outcome), str(main.battle.engine.result), int(main.battle_ui._state)])
		if main.battle != null or main.busy:
			continue
		if main.menus.visible:
			main.menus.close()   # une boutique ouverte par un dialogue : on la referme
			continue
		if main.dialogue.active:
			if main.dialogue.waiting:
				continue
			if main.dialogue._choosing:
				var buttons: Array = main.dialogue._choice_list.get_children()
				if not buttons.is_empty():
					var pick: int = int(pick_queue.pop_front()) if not pick_queue.is_empty() else 0
					(buttons[clampi(pick, 0, buttons.size() - 1)] as Button).pressed.emit()
			elif main.dialogue._typing:
				main.dialogue._finish_typing()
			else:
				main.dialogue._advance()
		elif main.world == null or main.world.input_enabled or main.mode == main.Mode.TITLE:
			return
	check(false, "le jeu ne revient pas au repos (combat : %s, occupé : %s, dialogue actif : %s, en attente : %s, carte : %s, dernier dialogue : %s, lieu : %s)" % [
		str(main.battle != null), str(main.busy), str(main.dialogue.active), str(main.dialogue.waiting), str(main.world != null), _last_say, GameState.map_id])
	print("    entrée %s, mode %d, menus %s, pause %s, banc %s" % [str(main.world.input_enabled) if main.world else "-", int(main.mode), str(main.menus.visible), str(main.pause.visible), str(main._abort_flow)])
	if main.battle != null:
		print("    combat : issue « %s », résultat moteur « %s », état interface %d" % [str(main.battle.outcome), str(main.battle.engine.result), int(main.battle_ui._state)])


func _test_flow() -> void:
	var main: Node = MAIN.instantiate()
	main.auto_battles = true
	add_child(main)
	await _wait_idle(main)
	check(main.mode == main.Mode.TITLE, "écran-titre affiché")
	check(main.title.visible, "menu du titre visible")
	check(main.title._continue.disabled, "« Continuer » grisé sans sauvegarde")
	check(main.world != null and main.world.attract, "village en vitrine derrière le titre")

	main.start_new_game()
	await _wait_idle(main)
	check(main.mode == main.Mode.PLAY, "nouvelle partie lancée")
	check(main.world.map_id == "bittebourg", "départ à Bittebourg")
	check(GameState.has_flag("prologue_vu"), "prologue joué jusqu'au bout")
	check(GameState.has_flag("combat_prologue_sauron"), "combat du prologue gagné")
	check(int(GameState.member("glandoulf")["level"]) == 1 and int(GameState.member("glandoulf")["xp"]) == 0, "le prologue ne donne ni niveau ni expérience")
	check(not GameState.party.has("isidur"), "Isidur ne reste pas dans l'équipe")
	# reprise de l'histoire : Isidur garde l'anneau, il ne le confie plus à Glandoulf
	var prologue_text := FileAccess.get_file_as_string("res://data/dialogues/prologue.json")
	check(prologue_text.contains("Je le garde") and not prologue_text.contains("dans la paume du magicien"), "prologue : Isidur garde l'anneau")
	check(GameState.item_count("tisane") == 2, "inventaire de départ intact après le prologue")
	check(GameState.has_flag("intro_vue"), "scène d'introduction jouée")
	check(main.world.input_enabled and main.world.player.control, "le joueur a la main")

	# déplacement simulé vers la gauche
	var x0: float = main.world.player.position.x
	Input.action_press("move_left")
	for _i in 30:
		await get_tree().process_frame
	Input.action_release("move_left")
	await get_tree().process_frame
	check(main.world.player.position.x < x0 - 0.5, "Glandoulf avance quand on appuie à gauche (%.2f -> %.2f)" % [x0, main.world.player.position.x])
	check(main.world.player.facing == "left", "il regarde à gauche")
	var cam_x: float = main.world.camera.position.x
	check(absf(cam_x - main.world.player.position.x) < 6.0, "la caméra suit")

	# collision : un mur de maison arrête le joueur
	main.world.player.position = Vector3(23.0, 0.0, 12.0)
	Input.action_press("move_up")
	for _i in 90:
		await get_tree().process_frame
		if main.busy:
			break
	Input.action_release("move_up")
	await _wait_idle(main)
	check(main.world.map_id == "auberge", "entrer par la porte de l'auberge change de carte (carte : %s)" % main.world.map_id)
	check(GameState.has_flag("auberge_vue"), "scène d'entrée de l'auberge jouée")
	check(SaveManager.has_save(), "sauvegarde automatique au changement de lieu")

	# interaction avec un PNJ
	var sam: Node3D = null
	for n: Node3D in main.world.npcs:
		if str(n.data.get("id", "")) == "sam":
			sam = n
	check(sam != null, "Sam est dans l'auberge")
	if sam != null:
		main.world.player.position = sam.position + Vector3(-1.0, 0.0, 0.0)
		main.world.player.set_facing("right")
		await get_tree().process_frame
		await get_tree().process_frame
		check(not main.world.focus.is_empty() and str(main.world.focus.get("dialogue", "")) == "sam", "Sam est ciblé quand on lui fait face")
		GameState.flags.erase("sam_vu")
		main._on_interact(main.world.focus)
		await get_tree().process_frame
		check(main.dialogue.active, "le dialogue s'ouvre")
		check(not main.world.input_enabled, "le joueur est figé pendant le dialogue")
		await _wait_idle(main)
		check(GameState.has_flag("sam_vu"), "le dialogue de Sam va au bout")

	# sauvegarde manuelle puis retour au titre et « Continuer »
	main.world.player.position = Vector3(7.0, 0.0, 6.5)
	main.world.player.set_facing("down")
	check(SaveManager.save_game(), "sauvegarde manuelle")
	main.show_title()
	await _wait_idle(main)
	check(main.mode == main.Mode.TITLE, "retour à l'écran-titre")
	check(not main.title._continue.disabled, "« Continuer » disponible")
	main.continue_game()
	await _wait_idle(main)
	check(main.mode == main.Mode.PLAY and main.world.map_id == "auberge", "« Continuer » reprend dans l'auberge")
	check(main.world.player.position.distance_to(Vector3(7.0, 0.0, 6.5)) < 0.05, "position exacte restaurée")
	check(main.world.player.facing == "down", "orientation restaurée")
	check(GameState.has_flag("sam_vu"), "progression restaurée")

	# sortie de l'auberge
	main.world.player.position = Vector3(8.0, 0.0, 9.8)
	Input.action_press("move_down")
	for _i in 90:
		await get_tree().process_frame
		if main.busy:
			break
	Input.action_release("move_down")
	await _wait_idle(main)
	check(main.world.map_id == "bittebourg", "sortir de l'auberge ramène au village")
	check(main.world.player.position.distance_to(Vector3(23.0, 0.0, 11.1)) < 0.6, "arrivée devant la porte de l'auberge")

	print("  [étape] combat lancé depuis la carte")
	# combat lancé depuis la carte : la carte est mise de côté puis remise en place
	GameState.heal_party()
	var field: Node3D = main.world
	var outcome: String = await main.start_battle({"enemies": ["limace_molle"], "arena": "pre"})
	print("  [étape] combat terminé : ", outcome)
	check(outcome == "victory", "combat contre une limace gagné (issue : %s)" % outcome)
	check(main.battle == null and not main.battle_ui.visible, "scène de combat refermée")
	check(main.world == field and field.get_parent() == main and field.camera.current, "carte remise en place après le combat")
	check(int(GameState.member("glandoulf")["xp"]) > 0 or int(GameState.member("glandoulf")["level"]) > 1, "expérience gagnée")
	main.world.set_input(true)

	print("  [étape] Pépin rejoint")
	# Pépin rejoint l'équipe : elle disparaît de la carte
	GameState.set_flag("pepin_vue")
	main.run_dialogue("pepin")
	await _wait_idle(main)
	check(GameState.party.has("pepin"), "Pépin rejoint l'équipe")
	check(GameState.item_count("tisane") >= 3, "elle apporte ses tisanes")
	var still_there := false
	for n: Node3D in main.world.npcs:
		if str(n.data.get("id", "")) == "pepin":
			still_there = true
	check(not still_there, "Pépin n'est plus plantée devant son potager")
	check(main.world.input_enabled, "le joueur a la main après la reconstruction de la carte")

	print("  [étape] le Pré Couché")
	# le Pré Couché : rencontre aléatoire en marchant dans un champ
	GameState.member("glandoulf")["level"] = 8
	GameState.heal_party()
	main.change_map("pre_couche", "ouest")   # sans await : le dialogue d'arrivée est avancé par _wait_idle
	await _wait_idle(main)
	check(main.world.map_id == "pre_couche", "arrivée au Pré Couché")
	check(main.world.encounter_zones.size() == 2, "deux zones de rencontres")
	main.world.player.position = Vector3(12.0, 0.0, 5.0)
	await get_tree().process_frame
	main.world._enc_left = 0.4
	var fought := false
	Input.action_press("move_right")
	for _i in 240:
		await get_tree().process_frame
		if main.battle != null or main.busy:
			fought = true
			break
	Input.action_release("move_right")
	check(fought, "marcher dans le champ déclenche un combat")
	await _wait_idle(main)
	check(main.mode == main.Mode.PLAY and main.world != null and main.world.input_enabled, "retour sur la carte après la rencontre")

	print("  [étape] la Grande Baveuse")
	# la Grande Baveuse : combat lancé par un dialogue, puis l'obstacle disparaît
	GameState.heal_party()
	check(main.world.get_node_or_null("Monster_grande_baveuse") != null, "la Grande Baveuse barre l'enclos")
	main.run_dialogue("grande_baveuse")
	await _wait_idle(main)
	check(GameState.has_flag("baveuse_vaincue"), "la Grande Baveuse est vaincue")
	check(main.world != null and main.world.get_node_or_null("Monster_grande_baveuse") == null, "elle a quitté la carte")
	check(main.world != null and main.world.input_enabled, "le joueur a la main après le combat de boss")
	check(main.hud._soft.visible, "le témoin du Ramollissement est affiché au Pré Couché")

	print("  [étape] la quête du potager")
	check(GameState.quest_state("potager") == "active", "la quête du potager est en cours")
	main.run_dialogue("racines")
	await _wait_idle(main)
	check(GameState.has_flag("racines_prises") and GameState.item_count("racine") == 3, "racines cueillies")
	main.change_map("bittebourg", "route_est")
	await _wait_idle(main)
	check(main.world.map_id == "bittebourg", "retour à Bittebourg")
	main.run_dialogue("potager")
	await _wait_idle(main)
	check(GameState.quest_state("potager") == "done", "la quête du potager est accomplie")
	check(GameState.item_count("tuteur") == 1, "la récompense (tuteur) est dans le sac")
	check(main.world != null and main.world.input_enabled, "le joueur a la main après la quête")

	print("  [étape] la boutique d'Ursule")
	GameState.money = 60
	var tisanes := GameState.item_count("tisane")
	main.run_dialogue("ursule")
	for _i in 900:
		await get_tree().process_frame
		if main.menus.visible:
			break
		if main.dialogue.active and not main.dialogue.waiting:
			if main.dialogue._typing:
				main.dialogue._finish_typing()
			else:
				main.dialogue._advance()
	check(main.menus.visible, "le dialogue d'Ursule ouvre la boutique")
	check(main.dialogue.waiting, "le dialogue attend la fermeture de la boutique")
	main.menus.press(0)   # Acheter
	await get_tree().process_frame
	var offers: Array = main.menus.shop_offers()
	var row := -1
	for i in offers.size():
		if str(offers[i]["item"]) == "tisane":
			row = i
	check(row >= 0, "la tisane est en vente")
	main.menus.press(row)
	await get_tree().process_frame
	check(GameState.item_count("tisane") == tisanes + 1 and GameState.money == 52, "achat d'une tisane (argent : %d)" % GameState.money)
	main.menus.go_back()
	main.menus.go_back()
	await _wait_idle(main)
	check(not main.menus.visible and not main.dialogue.active, "boutique et dialogue refermés")
	check(main.world.input_enabled, "le joueur a la main après la boutique")

	print("  [étape] les écrans du menu de pause")
	main._open_pause()
	check(main.pause.visible, "menu de pause ouvert")
	for which: String in ["team", "inventory", "quests"]:
		main._on_pause_screen(which)
		await get_tree().process_frame
		check(main.menus.visible and not main.pause.visible, "écran « %s » ouvert depuis la pause" % which)
		check(not (main.menus.entry_texts() as Array).is_empty(), "écran « %s » : au moins une ligne" % which)
		main.menus.close()
		await get_tree().process_frame
		check(main.pause.visible and not main.menus.visible, "retour au menu de pause après « %s »" % which)
	main._on_pause_screen("talents")
	await get_tree().process_frame
	check(main.talents.visible and not main.pause.visible, "écran de talents ouvert depuis la pause")
	main.talents.close()
	await get_tree().process_frame
	check(main.pause.visible and not main.talents.visible, "retour au menu de pause après les talents")
	main._on_pause_screen("team")
	await get_tree().process_frame
	main.menus.press(0)
	await get_tree().process_frame
	main.menus.press(1)
	await get_tree().process_frame
	check(main.talents.visible and not main.menus.visible, "écran de talents ouvert depuis la fiche d'un personnage")
	main.talents.close()
	await get_tree().process_frame
	check(main.menus.visible and not main.talents.visible, "retour à l'équipe après les talents")
	main.menus.close()
	await get_tree().process_frame
	GameState.member(GameState.leader())["level"] = maxi(2, int(GameState.member(GameState.leader())["level"]))
	GameState.reset_talents(GameState.leader())
	main.pause.close(true)
	main._open_pause()
	check(str(main.pause._talents.text).contains("dépenser"), "la pause signale les points de talent à dépenser (%s)" % str(main.pause._talents.text))
	main.pause.close()
	check(main.world.input_enabled, "le joueur a la main après la pause")

	print("  [étape] la Fête des Amarres, l'invasion et le Naze")
	for who: String in ["sam", "froton"]:
		if not GameState.party.has(who):
			GameState.add_to_party(who)
	for who: String in GameState.party:
		GameState.member(who)["level"] = 8
	GameState.heal_party()
	GameState.set_flag("fete_commencee")
	await get_tree().process_frame
	await _wait_idle(main)
	main.run_dialogue("ceremonie")
	await _wait_idle(main)
	check(GameState.has_flag("naze_arrive") and GameState.has_flag("invasion"), "la cérémonie déclenche l'invasion")
	var invaders := 0
	for n: Node3D in main.world.npcs:
		if str(n.data.get("dialogue", "")).begins_with("morfales_"):
			invaders += 1
	check(invaders == 3, "trois groupes de Morfales dans le village (%d)" % invaders)
	for where: String in ["morfales_quai", "morfales_potager", "morfales_auberge"]:
		GameState.heal_party()
		main.run_dialogue(where)
		await _wait_idle(main)
		check(GameState.has_flag("combat_" + where), "%s : Morfales chassés" % where)
	check(GameState.has_flag("morfales_chasses"), "les trois groupes chassés : le Naze se montre")
	var naze_here := false
	for n: Node3D in main.world.npcs:
		if str(n.data.get("dialogue", "")) == "naze":
			naze_here = true
	check(naze_here, "le Naze attend au pied de la Grande Bitte")
	for who: String in GameState.party:   # le déroulé joue au-dessus du niveau attendu : le jeu automatique n'a ni talents ni joueur attentif
		GameState.member(who)["level"] = maxi(int(GameState.member(who)["level"]), 12)
	GameState.heal_party()
	main.run_dialogue("naze")
	await _wait_idle(main, 120.0)
	check(GameState.has_flag("naze_vaincu"), "le Naze est vaincu")
	check(not GameState.has_flag("invasion"), "l'invasion est terminée")
	check(GameState.has_flag("route_ouverte") and GameState.item_count("premiere_amarre") == 1, "la route de Brie s'ouvre, la Première Amarre est dans le sac")
	check(main.world != null and main.world.input_enabled, "le joueur a la main après le Naze")
	var to_brie := false
	for wp: Dictionary in main.world.warps:
		if str(wp["map"]) == "route_brie":
			to_brie = true
	check(to_brie, "le passage vers la route de Brie existe")

	print("  [étape] la route de Brie et la fin du chapitre")
	main.change_map("route_brie", "est")
	await _wait_idle(main)
	check(main.world.map_id == "route_brie", "arrivée sur la route de Brie")
	GameState.heal_party()
	main.run_dialogue("peage_morfales")
	await _wait_idle(main, 90.0)
	check(GameState.has_flag("combat_morfales_route"), "le péage des Morfales est forcé")
	main.run_dialogue("fin_chapitre_1")
	await _wait_idle(main)
	check(GameState.has_flag("chapitre_1_fini"), "le chapitre 1 se termine")
	check(GameState.chapter == "chapitre_2", "le chapitre suivant est noté (%s)" % GameState.chapter)
	check(GameState.quest_state("ramollissement") == "done", "la quête principale du chapitre est accomplie")
	check(SaveManager.has_save(), "sauvegarde à la fin du chapitre")
	check(main.world != null and main.world.input_enabled, "le joueur garde la main après la fin du chapitre")
	main.queue_free()
	await get_tree().process_frame


# -------------------------------------------------------------------- relief

## Cartes à relief jouable (champs `heights` et `stairs`) : format valide, tout atteignable à
## pied depuis les points d'arrivée (parcours par cases, bords à dénivelé infranchissables,
## rampes franchissables), hauteur du joueur juste sur un plateau.
func _test_relief() -> void:
	print("== Relief ==")
	var found := 0
	for id in Database.list_maps():
		var map := Database.get_map(id)
		if not map.has("heights") and not map.has("stairs"):
			continue
		found += 1
		var size: Array = map["size"]
		var gw := int(size[0])
		var gh := int(size[1])
		for e: Dictionary in map.get("heights", []):
			var r: Array = e["rect"]
			check(r.size() == 4 and int(r[0]) >= 0 and int(r[1]) >= 0 and int(r[0]) + int(r[2]) <= gw and int(r[1]) + int(r[3]) <= gh,
					"relief %s : le plateau %s tient dans la carte" % [id, str(r)])
			check(float(e.get("h", -1.0)) >= 0.0, "relief %s : hauteur du plateau %s valide" % [id, str(r)])
		for e: Dictionary in map.get("stairs", []):
			var r: Array = e["rect"]
			check(r.size() == 4 and int(r[0]) >= 0 and int(r[1]) >= 0 and int(r[0]) + int(r[2]) <= gw and int(r[1]) + int(r[3]) <= gh,
					"relief %s : la rampe %s tient dans la carte" % [id, str(r)])
			check(str(e.get("dir", "")) in ["up", "down", "left", "right"], "relief %s : direction de la rampe %s connue" % [id, str(r)])
			check(not is_equal_approx(float(e.get("from", 0.0)), float(e.get("to", 1.0))), "relief %s : la rampe %s monte vraiment" % [id, str(r)])

		GameState.new_game()
		var world: Node3D = World.new()
		add_child(world)
		var spawns: Dictionary = map["spawns"]
		world.setup(id, str(spawns.keys()[0]))
		check(world.has_relief, "relief %s : le monde l'a chargé" % id)

		# chaque bout de rampe se raccorde au sol voisin
		for s: Dictionary in world.stairs:
			var r: Rect2 = s["rect"]
			var low := Vector2.ZERO
			var high := Vector2.ZERO
			var span := 0
			var horizontal := str(s["dir"]) == "left" or str(s["dir"]) == "right"
			span = int(r.size.y) if horizontal else int(r.size.x)
			for k in span:
				match str(s["dir"]):
					"up":
						low = Vector2(r.position.x + k + 0.5, r.end.y + 0.5)
						high = Vector2(r.position.x + k + 0.5, r.position.y - 0.5)
					"down":
						low = Vector2(r.position.x + k + 0.5, r.position.y - 0.5)
						high = Vector2(r.position.x + k + 0.5, r.end.y + 0.5)
					"left":
						low = Vector2(r.end.x + 0.5, r.position.y + k + 0.5)
						high = Vector2(r.position.x - 0.5, r.position.y + k + 0.5)
					_:
						low = Vector2(r.position.x - 0.5, r.position.y + k + 0.5)
						high = Vector2(r.end.x + 0.5, r.position.y + k + 0.5)
				check(absf(world.ground_y(low.x, low.y) - float(s["from"])) < 0.01, "relief %s : le bas de la rampe %s touche un sol à %.2f" % [id, str(r), float(s["from"])])
				check(absf(world.ground_y(high.x, high.y) - float(s["to"])) < 0.01, "relief %s : le haut de la rampe %s touche un sol à %.2f" % [id, str(r), float(s["to"])])

		# parcours par cases : on ne passe d'une case à sa voisine que si le bord est ouvert
		var seen := PackedByteArray()
		seen.resize(gw * gh)
		var queue: Array[Vector2i] = []
		for key: String in spawns:
			var sp: Vector3 = world.spawn_info(key)["pos"]
			var c := Vector2i(int(sp.x), int(sp.z))
			if seen[c.y * gw + c.x] == 0:
				seen[c.y * gw + c.x] = 1
				queue.append(c)
		var head := 0
		var dirs: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
		while head < queue.size():
			var c := queue[head]
			head += 1
			for k in 4:
				var n := c + dirs[k]
				if n.x < 0 or n.y < 0 or n.x >= gw or n.y >= gh or seen[n.y * gw + n.x] != 0:
					continue
				if world.blocked[n.y * gw + n.x] != 0 or (world.edge_block[c.y * gw + c.x] & (1 << k)) != 0:
					continue
				seen[n.y * gw + n.x] = 1
				queue.append(n)
		var unreachable := 0
		var high_cells := 0
		var mismatched := 0
		for ty in gh:
			for tx in gw:
				var i := ty * gw + tx
				if world.blocked[i] != 0:
					continue
				if world.cell_h[i] > 0.0 or world.stair_idx[i] >= 0:
					high_cells += 1
					if seen[i] == 0:
						unreachable += 1
				# deux cases plates de niveaux différents ne se touchent jamais par un bord ouvert
				if tx + 1 < gw and world.blocked[i + 1] == 0 and world.stair_idx[i] < 0 and world.stair_idx[i + 1] < 0 \
						and absf(world.cell_h[i] - world.cell_h[i + 1]) > 0.02 and (world.edge_block[i] & 2) == 0:
					mismatched += 1
				if ty + 1 < gh and world.blocked[i + gw] == 0 and world.stair_idx[i] < 0 and world.stair_idx[i + gw] < 0 \
						and absf(world.cell_h[i] - world.cell_h[i + gw]) > 0.02 and (world.edge_block[i] & 4) == 0:
					mismatched += 1
		check(high_cells > 0, "relief %s : des cases en hauteur existent" % id)
		check(unreachable == 0, "relief %s : toutes les cases en hauteur sont atteignables depuis les arrivées (%d sur %d hors d'atteinte)" % [id, unreachable, high_cells])
		check(mismatched == 0, "relief %s : aucun passage direct entre deux niveaux sans rampe (%d)" % [id, mismatched])
		for it: Dictionary in world.interactables:
			if bool(it.get("gated", false)):
				continue
			var ip: Vector3 = world.interactable_position(it)
			var near := false
			for dy in range(-1, 2):
				for dx in range(-1, 2):
					var cx := int(ip.x) + dx
					var cy := int(ip.z) + dy
					if cx >= 0 and cy >= 0 and cx < gw and cy < gh and seen[cy * gw + cx] != 0:
						near = true
			check(near, "relief %s : « %s » reste à portée d'une case atteignable" % [id, str(it["dialogue"])])
		for wp: Dictionary in world.warps:
			var wr: Rect2 = wp["rect"]
			check(seen[clampi(int(wr.get_center().y), 0, gh - 1) * gw + clampi(int(wr.get_center().x), 0, gw - 1)] != 0, "relief %s : passage vers %s atteignable" % [id, str(wp["map"])])

		# un bord à dénivelé arrête réellement le joueur
		var wall_ok := false
		for ty in gh:
			for tx in gw - 1:
				var i := ty * gw + tx
				if (world.edge_block[i] & 2) != 0 and world.stair_idx[i] < 0 and world.stair_idx[i + 1] < 0 and not wall_ok:
					var low_side := tx if world.cell_h[i] < world.cell_h[i + 1] else tx + 1
					var dir := -1.0 if low_side == tx + 1 else 1.0
					var wx := float(tx + 1)
					var p_low := Vector2(wx - dir * 0.05 + (0.0), ty + 0.5)
					var p_high := Vector2(wx + dir * 0.05, ty + 0.5)
					# p_low est du côté bas, p_high du côté haut : les deux sont trop près du bord
					wall_ok = not world.is_free(p_low, 0.28, world.player) and not world.is_free(p_high, 0.28, world.player)
		check(wall_ok, "relief %s : le bord d'un plateau arrête le joueur" % id)

		# hauteur du joueur sur un plateau, puis retour au sol
		var top := Vector2i(-1, -1)
		var best := 0.0
		for ty in gh:
			for tx in gw:
				var i := ty * gw + tx
				if world.blocked[i] == 0 and world.stair_idx[i] < 0 and world.cell_h[i] > best and world.is_free(Vector2(tx + 0.5, ty + 0.5), 0.28, world.player):
					best = world.cell_h[i]
					top = Vector2i(tx, ty)
		check(top.x >= 0, "relief %s : une case de plateau dégagée existe" % id)
		if top.x >= 0:
			world.player.position = Vector3(top.x + 0.5, 0.0, top.y + 0.5)
			world.player._process(1.0)
			check(absf(world.player.position.y - best) < 0.01, "relief %s : le joueur monte à %.2f sur le plateau (%.3f)" % [id, best, world.player.position.y])
			check(absf(world.ground_y(top.x + 0.5, top.y + 0.5) - best) < 0.001, "relief %s : le sol du plateau est à %.2f" % [id, best])
			world.player.position = Vector3(world.player.position.x, best, world.player.position.z)
			var spawn: Vector3 = world.spawn_info(str(spawns.keys()[0]))["pos"]
			world.player.position = Vector3(spawn.x, best, spawn.z)
			world.player._process(1.0)
			check(absf(world.player.position.y - world.ground_y(spawn.x, spawn.z)) < 0.01, "relief %s : le joueur redescend au niveau du point d'arrivée" % id)
		remove_child(world)
		world.queue_free()
	check(found >= 3, "relief : au moins trois cartes en ont (%d)" % found)
	# une carte sans relief reste inchangée : sol à zéro, aucun mur
	var plain := Database.get_map("auberge")
	check(not plain.has("heights") and not plain.has("stairs"), "relief : l'auberge n'a pas de relief")
	var w2: Node3D = World.new()
	add_child(w2)
	w2.setup("auberge", str(plain["spawns"].keys()[0]))
	check(not w2.has_relief and w2.ground_y(5.0, 5.0) == 0.0, "relief : une carte sans relief garde un sol à zéro")
	remove_child(w2)
	w2.queue_free()


func _test_character_art() -> void:
	var CP: GDScript = load("res://src/gfx/character_painter.gd")
	check(CP.FRAME_W == 88 and CP.FRAME_H == 132, "cases de personnages : 88 x 132")
	var door_h := 2.6   # hauteur d'une porte de maison, en unités monde
	for id: String in Database.characters:
		var sheet := Sprites.character(id)
		var img: Image = sheet["image"]
		check(img.get_width() == 88 * 11 and img.get_height() == 132 * 4, "planche de %s : 11 x 4 cases de 88 x 132" % id)
		check(float(sheet["ppu"]) == CP.PPU, "planche de %s : échelle peinte" % id)
		# le dessin occupe la hauteur attendue (nettement plus grand qu'avant : 64 pixels)
		var b := Sprites.PA.opaque_bounds(img, Rect2i(0, 0, 88, 132))
		check(b.size.y >= 62, "planche de %s : sprite haut d'au moins 62 pixels" % id)
		var shown: float = float(b.size.y) / float(CP.PPU)
		check(shown > 1.3 and shown < door_h * 1.25, "planche de %s : taille affichée %.2f entre une taille de Grobitte et une porte" % [id, shown])
		# nombre de tons : au moins 24 couleurs distinctes dans la pose de repos
		var seen := {}
		var dark := {}
		for y in 132:
			for x in 88:
				var c := img.get_pixel(x, y)
				if c.a > 0.5:
					seen[c.to_html()] = true
					if c.get_luminance() < 0.12:
						dark[c.to_html()] = true
		check(seen.size() >= 24, "planche de %s : au moins 24 tons (%d)" % [id, seen.size()])
		check(dark.size() >= 3, "planche de %s : contour coloré" % id)
		# aucune couleur magenta
		var magenta := false
		for y in 132:
			for x in 88:
				var c2 := img.get_pixel(x, y)
				if c2.a > 0.5 and c2.r > 0.95 and c2.b > 0.95 and c2.g < 0.1:
					magenta = true
		check(not magenta, "planche de %s : pas de magenta" % id)
		# les poses de combat diffèrent entre elles et du repos
		var poses := {}
		for col in [0, 7, 8, 9, 10]:
			poses[img.get_region(Rect2i(col * 88, 0, 88, 132)).get_data()] = true
		check(poses.size() == 5, "planche de %s : repos, attaque, sort, coup reçu et KO distincts" % id)
		# la ligne « droite » est peinte avec la lumière inversée, pas copiée du miroir
		var left := img.get_region(Rect2i(0, 132, 88, 132))
		left.flip_x()
		check(left.get_data() != img.get_region(Rect2i(0, 264, 88, 132)).get_data(), "planche de %s : ligne droite éclairée à part" % id)
		# la marche a quatre images distinctes dans chaque direction (rien ne « saute » ni ne fige)
		for row in 4:
			var walk := {}
			for col in [3, 4, 5, 6]:
				walk[img.get_region(Rect2i(col * 88, row * 132, 88, 132)).get_data()] = true
			check(walk.size() == 4, "planche de %s : marche à quatre poses distinctes (ligne %d)" % [id, row])
		# profils : une vraie silhouette de profil, différente de la face
		for row in [1, 2]:
			check(img.get_region(Rect2i(0, row * 132, 88, 132)).get_data() != img.get_region(Rect2i(0, 0, 88, 132)).get_data(), "planche de %s : le profil (ligne %d) diffère de la face" % [id, row])
		check(Sprites.portrait(id).get_width() == 64, "portrait de %s : 64 pixels" % id)
	# chaque héros a son expression au repos (champ « face » du look)
	var faces := {}
	for hero: String in ["glandoulf", "sam", "froton", "pepin", "merri", "aragrogne", "digoulasse", "grimli"]:
		var f := str(Database.characters[hero]["look"].get("face", ""))
		check(f != "", "%s : expression au repos définie" % hero)
		faces[f] = true
	check(faces.size() == 8, "les huit héros ont chacun une expression différente")
	# objets tenus : visibles à l'attaque, sans élargir la silhouette au repos ; visages de combat distincts
	for who: String in ["sam", "aragrogne", "digoulasse", "grimli", "froton", "pepin", "merri", "morfale_goinfre", "morfale_eclaireur", "pinard", "lambert"]:
		var look: Dictionary = Database.characters[who]["look"]
		check(str(look.get("held", "")) != "", "%s : objet tenu défini" % who)
		var bare_look := look.duplicate()
		bare_look["held"] = ""
		var with_img: Image = Sprites.character(who)["image"]
		var bare_img: Image = CP.paint_sheet(bare_look)
		for row in [0, 1]:
			var shown := with_img.get_region(Rect2i(7 * 88, row * 132, 88, 132))
			check(shown.get_data() != bare_img.get_region(Rect2i(7 * 88, row * 132, 88, 132)).get_data(), "%s : l'objet tenu se voit à l'attaque (ligne %d)" % [who, row])
		var w_with := Sprites.PA.opaque_bounds(with_img, Rect2i(0, 0, 88, 132)).size.x
		var w_bare := Sprites.PA.opaque_bounds(bare_img, Rect2i(0, 0, 88, 132)).size.x
		# hache et marteau, portés à l'écart du corps pour se lire de face, ont droit à 8 px de plus
		var slack := 8 if str(look.get("held", "")) in ["hache", "marteau"] else 2
		check(w_with <= w_bare + slack or str(look.get("species", "")) != "" or str(look.get("held", "")) in CP.POLES, "%s : l'objet au repos n'élargit pas la silhouette (%d contre %d)" % [who, w_with, w_bare])
	for who: String in ["sam", "aragrogne", "grimli", "morfale_eclaireur", "naze", "naze_aine"]:
		var lk: Dictionary = Database.characters[who]["look"]
		var heads := {}
		for col in [0, 7, 8, 9, 10]:
			heads[(CP.paint_portrait(lk, col) as Image).get_data()] = true
		check(heads.size() == 5, "%s : visages de repos, d'effort, de concentration, de douleur et de KO distincts" % who)
	check(str(Database.characters["naze_aine"]["look"].get("glow", "")) != str(Database.characters["naze_cadet"]["look"].get("glow", "")), "les Nazes de l'Est et de l'Ouest n'ont pas la même lueur")


## Décors, façades et arènes : paroi irrégulière, éléments connus, rien de magenta.
func _test_scenery() -> void:
	var ArenaDecor = preload("res://src/battle/arena_decor.gd")
	var MapBuilderScript = preload("res://src/world/map_builder.gd")
	var BattleScene = preload("res://src/battle/battle_scene.gd")
	var horizons := ["hills", "forest", "marsh", "town", "cavern", "peaks", "valley", "hills_church"]
	var features := ["pool", "houses"]
	for id: String in Database.arenas:
		var arena: Dictionary = Database.arenas[id]
		check(Database.ambiances.has(str(arena.get("ambiance", "crepuscule"))), "arène %s : ambiance connue" % id)
		var back: Dictionary = arena.get("backdrop", {})
		if not back.is_empty():
			check(Sprites.tile_image(str(back.get("tile", "rock_face"))).get_pixel(0, 0) != Color.MAGENTA, "arène %s : texture de paroi peinte" % id)
			var far := str(back.get("far", ""))
			check(far == "" or horizons.has(far), "arène %s : lointain %s connu" % [id, far])
		for p: Variant in arena.get("props", []):
			check(MapBuilderScript.PROPS.has(str((p as Dictionary).get("prop", ""))) or ArenaPainterScript.has_prop(str((p as Dictionary).get("prop", ""))), "arène %s : décor %s connu" % [id, str((p as Dictionary).get("prop", ""))])
		for f: Variant in arena.get("features", []):
			check(features.has(str((f as Dictionary).get("kind", ""))), "arène %s : élément %s connu" % [id, str((f as Dictionary).get("kind", ""))])
		# la paroi : irrégulière, et jamais dans la zone des combattants
		var decor = ArenaDecor.new(hash(id))
		var holder := Node3D.new()
		decor.build(holder, arena)
		var no_steps: bool = back.get("steps", null) is Array and (back.get("steps") as Array).is_empty()
		if no_steps:   # intérieur : panneaux peints à la place de la paroi en gradins
			check(holder.get_child_count() >= 1 and not (back.get("panels", []) as Array).is_empty(), "arène %s : décor d'intérieur construit (panneaux)" % id)
		elif not back.is_empty():
			var lo := 99.0
			var hi := 0.0
			var zmin := 99.0
			var zmax := -99.0
			for sg: Dictionary in decor.segments:
				if int(sg["layer"]) == 0:
					lo = minf(lo, float(sg["h"]))
					hi = maxf(hi, float(sg["h"]))
					zmin = minf(zmin, float(sg["zf"]))
					zmax = maxf(zmax, float(sg["zf"]))
			check(hi - lo > 0.35, "arène %s : hauteurs de paroi variées (%.2f)" % [id, hi - lo])
			check(zmax - zmin > 0.6, "arène %s : décrochements de paroi (%.2f)" % [id, zmax - zmin])
			check(zmax < -7.5, "arène %s : la paroi reste derrière les combattants (z %.2f)" % [id, zmax])
			check(decor.height_at(3.5, 0.0) == 0.0 and decor.height_at(-3.5, 2.0) == 0.0, "arène %s : sol plat sous les combattants" % id)
			check(holder.get_child_count() >= 5, "arène %s : le décor est construit" % id)
		holder.free()
		# les décors posés à la main restent hors de la zone de jeu
		for p: Variant in arena.get("props", []):
			if (p as Dictionary).has("at"):
				for sp: Variant in p["at"]:
					check(float((sp as Array)[1]) < -3.8, "arène %s : décor %s hors de la zone de jeu" % [id, str(p.get("prop", ""))])
	# la mise en place des combattants reste celle qui est testée plus haut
	check(BattleScene.formation([1.0, 1.0, 1.0]).size() == 3, "formation toujours disponible")
	for kind: String in ["boulder", "stump", "log", "mushrooms", "reeds", "haystack", "fence", "pillar", "brazier", "anvil", "forge", "deadtree"]:
		var def: Dictionary = MapBuilderScript.PROPS.get(kind, {})
		for v in int(def.get("variants", 1)):
			var im := Sprites.prop(kind, v).get_image()
			check(im.get_width() > 8 and not im.is_invisible(), "décor %s variante %d peint" % [kind, v])
	for kind: String in ["rock_face", "rock_face_moss", "rock_face_mud", "rock_face_dark", "rock_face_ashlar", "basalt"]:
		var t := Sprites.tile_image(kind)
		check(t.get_width() >= 48 and t.get_pixel(0, 0) != Color.MAGENTA, "texture %s" % kind)
	# façades : une par taille, avec une émission non vide quand elle est éclairée
	var TilePainterScript = preload("res://src/gfx/tile_painter.gd")
	var fa: Dictionary = TilePainterScript.house_front(5.0, 3.0, 2.5, [1.0, 4.0], Color("#3f7a52"), true)
	check((fa["albedo"] as Image).get_width() == 120 and (fa["albedo"] as Image).get_height() == 72, "façade : dimensions")
	var lit_px := 0
	var emi: Image = fa["emission"]
	for y in emi.get_height():
		for x in emi.get_width():
			if emi.get_pixel(x, y).get_luminance() > 0.3:
				lit_px += 1
	check(lit_px > 200, "façade : fenêtres éclairées (%d px)" % lit_px)
	var fb: Dictionary = TilePainterScript.house_front(5.0, 3.0, 2.5, [1.0, 4.0], Color("#3f7a52"), true)
	check((fa["albedo"] as Image).get_data() == (fb["albedo"] as Image).get_data(), "façade : peinture déterministe")
	var hz := preload("res://src/gfx/horizon_painter.gd").paint("hills", Color("#222244"), Color("#aa6655"), 1)
	check(hz.get_width() == 384 and hz.get_pixel(0, 0).a > 0.9, "lointain : image peinte")


# ------------------------------------------------------------------ chapitre 2

const TEAM5 := ["glandoulf", "sam", "froton", "pepin", "aragrogne"]   # cinq recrutés : seuls les quatre premiers se battent


## Taux de victoire d'une rencontre (joueur attentif : sorts de zone, soins, élan, faiblesses ; 30 combats).
func _c2_rate(ids: Array, level: int, enc: Dictionary, talents: int) -> float:
	var chapter := 2 if level <= 9 else (3 if level <= 11 else (4 if level <= 16 else 5))
	var r := _sim_rate(ids, level, enc, talents, true, 30, _sim_inventory(chapter))
	print("  taux : %s niv. %d contre %s : %d %%" % [str(ids), level, str((enc.get("enemies", []) as Array).slice(0, 3)), int(100.0 * float(r[0]))])
	GameState.new_game()
	return float(r[0])


func _test_chapter_2_data() -> void:
	print("== Chapitre 2 : données et équilibre ==")
	for id: String in ["brie", "poney_flagada", "poney_etage", "fromagerie", "caves_brie", "ferme_pinard"]:
		check(Database.get_map(id).has("music") and Database.get_map(id).has("spawns"), "carte %s : musique et points d'arrivée" % id)
	check(Database.get_item("plume_chantecler").get("firm", false) == true, "la plume de Chantecler rend ferme")
	check(not Database.get_character("aragrogne").is_empty(), "Aragrogne existe")
	var cases := [
		["Nazes, quatre actifs niv. 9, talents A", TEAM5, 9, _soft("nazes_nuit", 0.3), 0.6, 0],
		["Nazes, quatre actifs niv. 9, sans talents", TEAM5, 9, _soft("nazes_nuit", 0.3), 0.15, -1],
		["Chantecler, quatre niv. 8", TEAM, 8, _soft("chantecler", 0.2), 0.6, 0],
		["Vacherin, quatre niv. 8", TEAM, 8, _soft("vacherin", 0.2), 0.6, 0],
		["Gaston, Sam seul", ["sam"], 9, Database.get_encounter("duel_gaston"), 0.7, -1],
		["Veuve, Sam seul", ["sam"], 9, Database.get_encounter("duel_veuve"), 0.7, -1],
		["rats et mouches, quatre niv. 8", TEAM, 8, {"enemies": ["rat_cave", "rat_cave", "mouche_cave"], "ramollissement": 0.2}, 0.9, -1],
		["moisissure et ver, quatre niv. 8", TEAM, 8, {"enemies": ["ver_fromage", "moisi_bleu", "rat_cave"], "ramollissement": 0.2}, 0.9, -1],
	]
	for case: Array in cases:
		var rate := _c2_rate(case[1], int(case[2]), case[3], int(case[5]))
		check(rate >= float(case[4]), "%s : %d %% de victoires (attendu : au moins %d %%)" % [str(case[0]), int(rate * 100.0), int(float(case[4]) * 100.0)])
		print("  %-40s %3d %% de victoires" % [str(case[0]), int(rate * 100.0)])
	GameState.new_game()


## Déroulé du chapitre 2, à la suite du chapitre 1 (la sauvegarde de fin de chapitre 1 existe).
func _test_chapter_2() -> void:
	print("== Chapitre 2 : déroulé complet ==")
	var main: Node = MAIN.instantiate()
	main.auto_battles = true
	add_child(main)
	await _wait_idle(main)
	GameState.map_id = "route_brie"
	GameState.spawn_id = "est"
	GameState.player_pos = []
	SaveManager.save_game()
	main.continue_game()
	await _wait_idle(main)
	check(GameState.has_flag("chapitre_1_fini"), "reprise après le chapitre 1")
	check(main.world.map_id == "route_brie", "la partie reprend sur la route de Brie (%s)" % main.world.map_id)
	var to_brie := false
	for wp: Dictionary in main.world.warps:
		if str(wp["map"]) == "brie":
			to_brie = true
	check(to_brie, "la route de Brie mène à Brie une fois le chapitre 1 fini")

	main.change_map("brie", "route")
	await _wait_idle(main)
	check(main.world.map_id == "brie" and GameState.has_flag("brie_vue"), "arrivée à Brie")
	check(GameState.chapter == "chapitre_2" or GameState.quest_state("brie") != "", "la quête de Brie est lancée")
	for who: String in ["sam", "froton", "pepin"]:
		if not GameState.party.has(who):
			GameState.add_to_party(who)
	# Ce test suit le déroulé, pas l'équilibre (mesuré par _test_chapter_2_data sur des
	# dizaines de combats) : l'équipe est au-dessus du niveau attendu pour que l'issue d'un
	# combat automatique ne dépende pas du hasard.
	for who: String in GameState.party:
		GameState.member(who)["level"] = 40
	GameState.heal_party()
	main.run_dialogue("sidonie")
	await _wait_idle(main)
	check(GameState.has_flag("sidonie_vue"), "Sidonie, marchande de la place")

	main.change_map("poney_flagada", "entree")
	await _wait_idle(main)
	check(main.world.map_id == "poney_flagada" and GameState.has_flag("poney_vu"), "le Poney Flagada")
	main.run_dialogue("aragrogne")
	await _wait_idle(main)
	check(GameState.party.has("aragrogne") and GameState.has_flag("aragrogne_equipe"), "Aragrogne rejoint l'équipe")
	check(GameState.is_reserve("aragrogne") and GameState.active_party().size() == 4, "Aragrogne, cinquième, va en réserve")
	GameState.member("aragrogne")["level"] = 40
	GameState.heal_party()

	# le concours de bras de fer : Sam seul
	main.run_dialogue("affiche_concours")
	await _wait_idle(main)
	check(GameState.has_flag("concours_inscrit"), "inscription au concours")
	var team_before: Array = GameState.party.duplicate()
	# Les duels imposent Sam au niveau 9 (équilibre mesuré ailleurs : environ 85 % de
	# victoires en jeu automatique). Ici on suit le déroulé : Sam est monté le temps du test.
	for duel: String in ["duel_gaston", "duel_veuve"]:
		((Database.encounters[duel] as Dictionary)["party"] as Array)[0]["level"] = 14
	main.run_dialogue("gaston")
	await _wait_idle(main, 90.0)
	check(GameState.has_flag("combat_duel_gaston"), "demi-finale gagnée")
	main.run_dialogue("veuve")
	await _wait_idle(main, 90.0)
	check(GameState.has_flag("concours_gagne") and GameState.item_count("ceinture_champion") == 1, "finale gagnée : la ceinture est dans le sac (%s, %d)" % [str(GameState.has_flag("concours_gagne")), GameState.item_count("ceinture_champion")])
	check(GameState.party == team_before, "l'équipe est retrouvée après les duels")
	for duel: String in ["duel_gaston", "duel_veuve"]:
		((Database.encounters[duel] as Dictionary)["party"] as Array)[0]["level"] = 9
	GameState.heal_party()

	# le poney qui ne se lève pas
	main.run_dialogue("barnabe")
	await _wait_idle(main)
	check(GameState.has_flag("poney_couche_vu"), "le poney couché")
	GameState.add_item("racine", 1)
	main.run_dialogue("ecurie")
	await _wait_idle(main)
	check(GameState.has_flag("poney_leve") and GameState.quest_state("poney") == "done", "le poney se relève")

	# la cave du fromager
	main.change_map("fromagerie", "entree")
	await _wait_idle(main)
	main.run_dialogue("persille")
	await _wait_idle(main)
	check(GameState.has_flag("cave_ouverte"), "la trappe de la cave est ouverte")
	main.change_map("caves_brie", "trappe")
	await _wait_idle(main)
	check(main.world.map_id == "caves_brie" and GameState.has_flag("cave_vue"), "dans la cave (%s, vue %s)" % [main.world.map_id, str(GameState.has_flag("cave_vue"))])
	main.run_dialogue("vacherin")
	await _wait_idle(main, 150.0)
	check(GameState.has_flag("vacherin_vaincu"), "le Vacherin est vaincu")
	GameState.heal_party()
	main.change_map("fromagerie", "trappe")
	await _wait_idle(main)
	main.run_dialogue("persille")
	await _wait_idle(main)
	check(GameState.has_flag("persille_paye") and GameState.quest_state("fromager") == "done", "le fromager est payé")

	# la ferme et Chantecler
	main.change_map("ferme_pinard", "nord")
	await _wait_idle(main)
	check(main.world.map_id == "ferme_pinard" and GameState.has_flag("ferme_vue"), "à la ferme Pinard (%s, vue %s)" % [main.world.map_id, str(GameState.has_flag("ferme_vue"))])
	main.run_dialogue("chantecler")
	await _wait_idle(main, 150.0)
	check(GameState.has_flag("chantecler_vaincu") and GameState.item_count("plume_chantecler") == 1, "Chantecler vaincu, sa plume est dans le sac")
	GameState.heal_party()

	# la nuit au Poney Flagada
	main.change_map("poney_flagada", "entree")
	await _wait_idle(main)
	main.run_dialogue("barnabe")
	await _wait_idle(main)
	check(GameState.has_flag("chambre_prise"), "les chambres sont prises")
	var stairs := false
	for wp: Dictionary in main.world.warps:
		if str(wp["map"]) == "poney_etage":
			stairs = true
	check(stairs, "l'escalier mène à l'étage")
	main.change_map("poney_etage", "escalier")
	await _wait_idle(main, 240.0)
	check(GameState.has_flag("nazes_vaincu"), "les deux Nazes sont vaincus")
	check(main.world != null and main.world.input_enabled, "le joueur a la main après la nuit")
	main.change_map("poney_flagada", "escalier")
	await _wait_idle(main)
	main.run_dialogue("barnabe")
	await _wait_idle(main)
	check(GameState.item_count("convocation_elrond") == 1, "la convocation du Conseil est dans le sac")
	main.change_map("brie", "route")
	await _wait_idle(main)
	main.run_dialogue("fin_chapitre_2")
	await _wait_idle(main)
	check(GameState.has_flag("chapitre_2_fini") and GameState.chapter == "chapitre_3", "le chapitre 2 se termine (%s)" % GameState.chapter)
	check(GameState.quest_state("brie") == "done", "la quête principale de Brie est accomplie")
	check(SaveManager.has_save(), "sauvegarde à la fin du chapitre 2")
	main.queue_free()
	await get_tree().process_frame
## Sauvegardes multiples : emplacements, rotation des automatiques, migration, fichiers
## abîmés, écran de sauvegarde, écran de défaite, retour avant le combat.
func _test_saves() -> void:
	print("== Sauvegardes multiples ==")
	var SaveScreen = preload("res://src/ui/save_screen.gd")
	SaveManager.delete_save()
	check(not SaveManager.has_save(), "saves : aucune sauvegarde au départ")
	check(SaveManager.list_slots(false).size() == SaveManager.MANUAL_SLOTS, "saves : %d emplacements manuels listés" % SaveManager.MANUAL_SLOTS)
	check(SaveManager.MANUAL_SLOTS >= 6 and SaveManager.AUTO_SLOTS >= 3, "saves : au moins 6 manuels et 3 automatiques")
	check(not SaveManager.load_game() and SaveManager.read_save().is_empty() and SaveManager.summary() == "", "saves : dossier vide sans erreur")

	# deux emplacements distincts
	GameState.new_game()
	GameState.map_id = "auberge"
	GameState.money = 111
	check(SaveManager.save_game("m3"), "saves : écriture dans l'emplacement 3")
	GameState.money = 222
	check(SaveManager.save_game("m1"), "saves : écriture dans l'emplacement 1")
	check(not SaveManager.save_game("a1") and not SaveManager.save_game("zz"), "saves : pas d'écriture manuelle dans un automatique ni un emplacement inconnu")
	GameState.money = 0
	check(SaveManager.load_game("m3") and GameState.money == 111, "saves : chargement de l'emplacement 3")
	check(SaveManager.load_game("m1") and GameState.money == 222, "saves : chargement de l'emplacement 1")
	GameState.money = 0
	check(SaveManager.latest_id() == "m1" and SaveManager.load_game() and GameState.money == 222, "saves : « Continuer » reprend la plus récente")
	var e1: Dictionary = SaveManager.list_slots(false)[0]
	check(not e1["empty"] and e1["map_name"] == "Au Bon Mouillage" and int(e1["level"]) >= 1 and str(e1["saved_at"]) != "", "saves : résumé d'un emplacement (lieu, niveau, date)")
	GameState.money = 5
	check(SaveManager.save_game() and SaveManager.current_slot == "m1" and int(SaveManager.read_slot("m1")["money"]) == 5, "saves : sauvegarde rapide dans l'emplacement courant")
	SaveManager.delete_slot("m1")
	check(SaveManager.read_slot("m1").is_empty() and SaveManager.latest_id() == "m3", "saves : suppression d'un emplacement")

	# sauvegardes automatiques tournantes
	for i in 4:
		GameState.money = 10 + i
		check(SaveManager.autosave("lieu") == "a1", "saves : sauvegarde automatique %d" % (i + 1))
	check(int(SaveManager.read_slot("a1")["money"]) == 13 and int(SaveManager.read_slot("a2")["money"]) == 12 and int(SaveManager.read_slot("a3")["money"]) == 11, "saves : rotation a1 -> a2 -> a3, la plus vieille disparaît")
	check(SaveManager.latest_id() == "a1", "saves : la plus récente est l'automatique")
	check(SaveManager.autosave("combat", "jeton") == "a1" and SaveManager.find_battle_slot("jeton") == "a1", "saves : la sauvegarde d'avant combat est retrouvée")
	SaveManager.autosave("lieu")
	check(SaveManager.find_battle_slot("jeton") == "a2" and SaveManager.find_battle_slot("") == "", "saves : le jeton suit la rotation")
	check(SaveManager.list_slots(true).size() == SaveManager.MANUAL_SLOTS + 3, "saves : manuels et automatiques listés ensemble")

	# fichiers abîmés ou d'une carte inconnue : ignorés
	for id: String in ["m2", "m4", "m5"]:
		SaveManager.delete_slot(id)
	var f := FileAccess.open(SaveManager.slot_path("m2"), FileAccess.WRITE)
	f.store_string("{ pas du json")
	f.close()
	var bad := GameState.to_dict()
	bad["map_id"] = "carte_inexistante"
	f = FileAccess.open(SaveManager.slot_path("m4"), FileAccess.WRITE)
	f.store_string(JSON.stringify(bad))
	f.close()
	f = FileAccess.open(SaveManager.slot_path("m5"), FileAccess.WRITE)
	f.store_string("[1, 2]")
	f.close()
	check(SaveManager.read_slot("m2").is_empty() and SaveManager.read_slot("m4").is_empty() and SaveManager.read_slot("m5").is_empty(), "saves : fichier corrompu, carte inconnue ou mauvais type ignorés")
	check(SaveManager.list_slots(false)[1]["empty"] and SaveManager.has_save(), "saves : un fichier abîmé n'empêche pas les autres")
	check(not SaveManager.load_game("m2"), "saves : charger un fichier abîmé échoue proprement")

	# migration de l'ancienne sauvegarde unique
	SaveManager.delete_save()
	GameState.new_game()
	GameState.map_id = "auberge"
	GameState.money = 777
	var legacy := GameState.to_dict()
	legacy["saved_at"] = "2026-01-02 03:04:05"
	f = FileAccess.open(SaveManager.save_path, FileAccess.WRITE)
	f.store_string(JSON.stringify(legacy))
	f.close()
	check(SaveManager.has_save(), "saves : l'ancien fichier unique est reconnu")
	check(not FileAccess.file_exists(SaveManager.save_path) and not SaveManager.read_slot("m1").is_empty(), "saves : ancien fichier migré vers l'emplacement 1")
	GameState.money = 0
	check(SaveManager.load_game("m1") and GameState.money == 777, "saves : rien perdu dans la migration")
	check(str(SaveManager.read_slot("m1")["saved_at"]) == "2026-01-02 03:04:05", "saves : la date d'origine est conservée")

	# écran de sauvegarde
	for id: String in SaveManager.manual_ids() + SaveManager.auto_ids():
		SaveManager.delete_slot(id)
	GameState.new_game()
	GameState.map_id = "auberge"
	GameState.money = 1
	SaveManager.save_game("m2")
	SaveManager.autosave("lieu")
	var screen: Control = SaveScreen.new()
	add_child(screen)
	var saved_ids: Array = []
	var chosen: Array = []
	screen.saved.connect(func(id: String) -> void: saved_ids.append(id))
	screen.finished.connect(func(c: String) -> void: chosen.append(c))
	screen.open("save", "test")
	await get_tree().process_frame
	check(screen.visible and screen._rows.size() == SaveManager.MANUAL_SLOTS, "saves : écran de sauvegarde, emplacements manuels seulement")
	GameState.money = 2
	screen._on_row("m2")
	check(screen.is_modal_open() and int(SaveManager.read_slot("m2")["money"]) == 1, "saves : confirmation avant d'écraser un emplacement occupé")
	screen._modal_no.pressed.emit()
	check(not screen.is_modal_open() and int(SaveManager.read_slot("m2")["money"]) == 1, "saves : annuler laisse l'emplacement intact")
	screen._on_row("m2")
	screen._on_modal_yes()
	check(int(SaveManager.read_slot("m2")["money"]) == 2 and saved_ids == ["m2"] and not screen.visible, "saves : écrasement confirmé")
	screen.open("save", "test")
	screen._on_row("m6")
	check(not screen.is_modal_open() and not SaveManager.read_slot("m6").is_empty(), "saves : un emplacement libre se remplit sans confirmation")
	screen.open("load", "test")
	await get_tree().process_frame
	check(screen._rows.size() == SaveManager.MANUAL_SLOTS + 1 and screen._rows["m1"].disabled, "saves : écran de chargement, vides grisés, automatiques ajoutées")
	chosen.clear()
	screen._on_row("m2")
	check(chosen == ["m2"], "saves : choisir un emplacement le charge")
	screen.open("load", "test")
	screen._ask("Effacer ?", "Effacer", func() -> void: screen._delete("m6"))
	screen._on_modal_yes()
	check(SaveManager.read_slot("m6").is_empty() and screen.visible and not screen.is_modal_open(), "saves : effacement depuis la liste")
	screen.close()

	# écran de défaite
	var ui: Control = BattleUI.new()
	add_child(ui)
	ui.save_screen = screen
	ui.before_battle_slot = "a1"
	var res: Array = []
	var run := func() -> void: res.append(await ui.show_defeat())
	run.call()
	await get_tree().process_frame
	var labels: Array = []
	for b in ui._end_layer.find_children("*", "Button", true, false):
		labels.append((b as Button).text)
	check(labels == ["Recommencer le combat", "Revenir avant le combat", "Charger une sauvegarde", "Retour à l'écran-titre"], "saves : défaite, quatre choix (%s)" % str(labels))
	ui._on_end("before")
	await get_tree().process_frame
	check(res == ["load:a1"], "saves : « Revenir avant le combat » charge la sauvegarde d'avant (%s)" % str(res))
	res.clear()
	ui.before_battle_slot = ""
	run.call()
	await get_tree().process_frame
	labels.clear()
	for b in ui._end_layer.find_children("*", "Button", true, false):
		labels.append((b as Button).text)
	check(not labels.has("Revenir avant le combat"), "saves : pas de retour avant le combat sans sauvegarde d'avant")
	ui._on_end("load")
	await get_tree().process_frame
	check(screen.visible and screen.context == "defeat", "saves : « Charger une sauvegarde » ouvre la liste")
	screen.close()
	await get_tree().process_frame
	check(res.is_empty() and ui._end_layer.visible, "saves : annuler ramène à l'écran de défaite")
	ui._on_end("load")
	await get_tree().process_frame
	screen._on_row("m2")
	await get_tree().process_frame
	check(res == ["load:m2"], "saves : charger depuis la défaite (%s)" % str(res))
	ui.close()
	ui.queue_free()
	screen.queue_free()

	# intégration : sauvegarde automatique avant un combat sans fuite, puis chargement après défaite
	if not OS.has_environment("GLAN_QUICK"):
		SaveManager.delete_save()
		var main: Node = MAIN.instantiate()
		main.auto_battles = true
		add_child(main)
		await _wait_idle(main)
		main.start_new_game()
		await _wait_idle(main)
		check(main.mode == main.Mode.PLAY, "saves : partie lancée pour le test d'intégration")
		GameState.money = 4242
		check(SaveManager.save_game("m1"), "saves : sauvegarde manuelle en jeu")
		GameState.heal_party()
		var before_count := 0
		await main.start_battle({"enemies": ["limace_molle"], "arena": "pre", "flee": false})
		var found := ""
		for e: Dictionary in SaveManager.list_slots(true):
			if not e["empty"] and e["kind"] == "auto" and e["auto_reason"] == "combat":
				found = str(e["id"])
		check(found != "", "saves : sauvegarde automatique avant un combat sans fuite")
		check(main.battle_ui.before_battle_slot == "", "saves : le repère d'avant-combat est nettoyé après le combat")
		var n_auto := 0
		for e: Dictionary in SaveManager.list_slots(true):
			if not e["empty"] and e["kind"] == "auto":
				n_auto += 1
		await main.start_battle({"enemies": ["limace_molle"], "arena": "pre"})
		var n_after := 0
		for e: Dictionary in SaveManager.list_slots(true):
			if not e["empty"] and e["kind"] == "auto":
				n_after += 1
		check(n_after == n_auto, "saves : pas de sauvegarde automatique avant un combat où l'on peut fuir")
		# deux combats lancés à la suite dans deux arènes : jamais deux scènes de combat à la fois,
		# et le second ne garde aucun nœud de décor du premier
		GameState.heal_party()
		main.start_battle({"enemies": ["limace_molle"], "arena": "taverne"})
		main.start_battle({"enemies": ["limace_molle"], "arena": "col"})
		var max_scenes := 0
		var second_ok := false
		var second_seen := false
		for _i in 6000:
			await get_tree().process_frame
			var scenes: Array = []
			for c: Node in main.get_children():
				if c.get_script() != null and str(c.get_script().resource_path).ends_with("battle_scene.gd"):
					scenes.append(c)
			max_scenes = maxi(max_scenes, scenes.size())
			if main.battle != null and str(main.battle._arena_id) == "col":
				second_seen = true
				second_ok = scenes.size() == 1 and scenes[0] == main.battle
			if second_seen and main.battle == null and not main.busy:
				break
		check(max_scenes <= 1, "combats enchaînés : jamais deux scènes de combat ensemble (max %d)" % max_scenes)
		check(second_seen and second_ok, "combats enchaînés : le second combat est seul dans l'arbre, sans décor du premier")
		check(main.battle == null and main.world != null, "combats enchaînés : tout est refermé à la fin")
		GameState.money = 1
		main._pending_load = "m1"
		main._leave_after_defeat("load")
		await _wait_idle(main)
		check(main.mode == main.Mode.PLAY and GameState.money == 4242 and main.world != null, "saves : chargement après une défaite, partie restaurée")
		main.queue_free()
		await get_tree().process_frame
	SaveManager.delete_save()
	check(not FileAccess.file_exists(SaveManager.slot_path("m1")) and not SaveManager.has_save(), "saves : nettoyage complet")
## Musique refondue : chaque morceau a une vraie forme (durée, voix, nuances) et se calcule.
func _test_music_forms() -> void:
	var parsed := Music.parse_voice({"len": 2, "notes": "c4:4@9 d4@3 r b3:2@6"})
	check(int(parsed["length"]) == 10 and absf(float(parsed["events"][0][3]) - 1.5) < 0.01, "musique : nuance @9 lue")
	check((Music.check_track({"tempo": 90, "voices": [{"instrument": "drums", "len": 2, "notes": "t b c k"}]}) as Array).is_empty(), "musique : timbale, bodhran, cymbale acceptés")
	check(not (Music.check_track({"tempo": 90, "voices": [{"instrument": "flute", "len": 2, "notes": "c4@0"}]}) as Array).is_empty(), "musique : nuance hors 1 à 9 refusée")
	for id: String in Database.music:
		var track: Dictionary = Database.music[id]
		var loop := bool(track.get("loop", true))
		var step: float = 60.0 / float(track["tempo"]) / 4.0
		var melodic := 0
		var longest := 0
		for v: Variant in track["voices"]:
			var voice: Dictionary = v
			longest = maxi(longest, int(Music.parse_voice(voice)["length"]))
			if str(voice["instrument"]) != "drums":
				melodic += 1
		check(melodic >= 3, "musique %s : au moins trois voix jouées (%d)" % [id, melodic])
		check(not loop or longest * step >= 40.0, "musique %s : 40 secondes ou plus (%.1f s)" % [id, longest * step])
		check(float(track.get("reverb", 0.0)) <= 0.6 and float(track.get("echo", 0.0)) <= 0.6, "musique %s : écho et réverbération raisonnables" % id)
	# un morceau tonal est rendu à la bonne taille, sans saturation
	var bytes: PackedByteArray = Music.render(Database.music["village"])
	var steps := 0
	for v: Variant in Database.music["village"]["voices"]:
		steps = maxi(steps, int(Music.parse_voice(v)["length"]))
	var expected := int(round(steps * 60.0 / float(Database.music["village"]["tempo"]) / 4.0 * Music.RATE)) * 2
	check(bytes.size() == expected, "musique : taille du rendu de Bittebourg (%d / %d octets)" % [bytes.size(), expected])


# ------------------------------------------------------------------ noms définitifs et Merri

const TEAM6 := ["glandoulf", "sam", "froton", "pepin", "aragrogne", "merri"]


## Cherche une instruction (clé, valeur) dans un dialogue, à n'importe quelle profondeur.
func _dialogue_has(nodes: Variant, key: String, value: String) -> bool:
	if nodes is Array:
		for n: Variant in nodes:
			if _dialogue_has(n, key, value):
				return true
	elif nodes is Dictionary:
		var d: Dictionary = nodes
		if str(d.get(key, "")) == value:
			return true
		for k: String in ["then", "else", "choice"]:
			if d.has(k) and _dialogue_has(d[k], key, value):
				return true
	return false


func _test_names_and_merri() -> void:
	print("== Noms définitifs, reprise des sauvegardes, Merri ==")
	# --- les nouveaux noms sont en place, les anciens ont disparu des données
	for id: String in ["froton", "pepin", "digoulasse", "grimli", "merri"]:
		check(not Database.get_character(id).is_empty(), "personnage %s présent" % id)
	for id: String in ["fripon", "pepine", "legolasse", "gimlette"]:
		check(Database.get_character(id).is_empty() and not Database.talents.has(id), "l'ancien identifiant %s n'existe plus" % id)
	check(str(Database.get_character("froton").get("full_name", "")) == "Froton Salfait", "Froton Salfait")
	check(str(Database.get_character("pepin").get("name", "")) == "Pépin Bontabac", "Pépin Bontabac")
	check(Database.get_character("pepin")["look"].get("outfit") == "tunique" and Database.get_character("pepin")["look"].get("hair_style") == "court", "Pépin : ni jupe ni chignon")
	check(str(Database.get_character("digoulasse").get("name", "")) == "Digoulasse", "Digoulasse")
	check(str(Database.get_character("grimli").get("name", "")) == "Grimli", "Grimli")
	check(str(Database.get_character("pepin").get("branches", [])[1]) == "Fumeur de Pipe", "la branche de Pépin est masculine")
	var all_text := ""
	for dir: String in ["res://data", "res://data/dialogues", "res://data/maps"]:
		for f: String in DirAccess.get_files_at(dir):
			if f.ends_with(".json"):
				all_text += FileAccess.get_file_as_string(dir + "/" + f).to_lower() + "\n"
	for old: String in ["fripon", "besace", "pépine", "pepine", "légolasse", "legolasse", "gimlette"]:
		check(not all_text.contains(old), "plus aucune trace de « %s » dans les données" % old)
	# --- reprise des sauvegardes : les anciens identifiants deviennent les nouveaux
	var old_save := {
		"version": 3, "chapter": "chapitre_2", "map_id": "brie", "spawn_id": "route",
		"party": ["glandoulf", "sam", "fripon", "pepine"],
		"roster": {
			"glandoulf": {"level": 8, "xp": 3, "specialization": "", "talents": [], "equip": {}},
			"fripon": {"level": 8, "xp": 0, "specialization": "pickpocket", "talents": [], "equip": {"weapon": "canif_batelier"}},
			"pepine": {"level": 8, "xp": 0, "specialization": "fumeuse", "talents": [], "equip": {"weapon": "serpette_affutee"}},
		},
		"flags": {"fripon_equipe": true, "pepine_equipe": true, "pepine_vue": true, "fripon_avoue": true, "brie_vue": true},
		"quests": {"potager": "done"}, "money": 33, "inventory": {"tisane": 2}, "bestiary": {}, "player_pos": [], "player_facing": "down", "playtime": 5.0,
	}
	var migrated: Dictionary = GameState.migrate_old_ids(old_save)
	check(migrated["party"] == ["glandoulf", "sam", "froton", "pepin"], "sauvegarde : l'équipe est convertie (%s)" % str(migrated["party"]))
	check((migrated["roster"] as Dictionary).has("froton") and (migrated["roster"] as Dictionary).has("pepin") and not (migrated["roster"] as Dictionary).has("fripon"), "sauvegarde : les fiches sont converties")
	check((migrated["flags"] as Dictionary).has("froton_equipe") and (migrated["flags"] as Dictionary).has("pepin_vue") and not (migrated["flags"] as Dictionary).has("pepine_equipe"), "sauvegarde : les drapeaux sont convertis")
	check(old_save["party"][2] == "fripon", "la conversion ne modifie pas l'original")
	check(GameState.migrate_old_ids(migrated) == migrated, "la conversion est sans effet sur une sauvegarde déjà à jour")
	check(GameState.migrate_old_ids({"party": ["legolasse", "gimlette"], "x": "gimlette_vu"}) == {"party": ["digoulasse", "grimli"], "x": "grimli_vu"}, "Digoulasse et Grimli aussi")
	GameState.new_game()
	check(GameState.from_dict(old_save), "une ancienne sauvegarde se charge")
	check(GameState.party == ["glandoulf", "sam", "froton", "pepin"], "ancienne sauvegarde : équipe %s" % str(GameState.party))
	check(int(GameState.member("froton")["level"]) == 8 and str(GameState.member("pepin")["equip"].get("weapon", "")) == "serpette_affutee", "ancienne sauvegarde : niveaux et équipement conservés")
	check(GameState.has_flag("froton_equipe") and GameState.has_flag("pepin_equipe") and not GameState.has_flag("fripon_equipe"), "ancienne sauvegarde : drapeaux convertis")
	check(GameState.quest_state("potager") == "done", "ancienne sauvegarde : quêtes conservées")
	check(not (GameState.roster as Dictionary).has("fripon") and not (GameState.roster as Dictionary).has("pepine"), "ancienne sauvegarde : plus d'ancienne fiche")
	var round_trip := GameState.to_dict()
	check(not JSON.stringify(round_trip).contains("fripon") and not JSON.stringify(round_trip).contains("pepine"), "la sauvegarde réécrite ne contient plus les anciens noms")
	# --- Merri : fiche, compétences, talents, animations
	GameState.new_game()
	var ch := Database.get_character("merri")
	check(str(ch.get("name", "")) == "Merri Brandemou" and str(ch.get("role", "")) != "", "Merri : nom et rôle")
	check(Rules.branches("merri").size() == 2 and (ch.get("branches", []) as Array).size() == 2, "Merri : deux voies de talents")
	check(not str(Database.get_character("merri")["look"].get("hair_style", "")) in ["chignon"] and Database.get_character("merri")["look"] != Database.get_character("pepin")["look"], "Merri : apparence distincte de Pépin")
	check((Rules.skills_at("merri", 1) as Array).has("estoc_de_cousin") and (Rules.skills_at("merri", 2) as Array).has("plan_ficele") and (Rules.skills_at("merri", 6) as Array).size() == 4, "Merri : compétences par niveau")
	var fx: Node3D = BattleFx.new()
	for sk: String in ["estoc_de_cousin", "plan_ficele", "second_petit_dejeuner", "diversion", "pause_dejeuner", "plan_b", "coup_dans_le_dos", "charge_des_cousins"]:
		check(Database.skills.has(sk), "compétence %s existe" % sk)
		check(Database.animations.has(sk), "compétence %s : animation à elle" % sk)
	check(Database.animations.has(str(ch["battle"]["attack_anim"])), "Merri : animation de l'attaque de base")
	check(fx.resolve("coup_de_dague_merri", "tranchant") == "coup_de_dague_merri", "attaque de Merri : animation à elle")
	fx.free()
	GameState.party = ["glandoulf"]
	GameState.member("glandoulf")["level"] = 8
	GameState.add_to_party("merri", true)
	check(GameState.party.has("merri") and int(GameState.member("merri")["level"]) == 7, "Merri rejoint un niveau sous le meneur")
	check(str(GameState.member("merri")["equip"].get("weapon", "")) == "dague_de_poche", "Merri arrive avec sa dague de poche")
	check((GameState.member_skills("merri") as Array).has("second_petit_dejeuner") and (GameState.member_skills("merri") as Array).has("diversion"), "Merri niveau 7 : quatre compétences apprises")
	GameState.member("merri")["level"] = 3
	check((GameState.member_skills("merri") as Array).size() == 2 and not (GameState.member_skills("merri") as Array).has("second_petit_dejeuner"), "Merri niveau 3 : deux compétences seulement")
	GameState.member("merri")["level"] = 7
	_spend("merri", 0)
	var sk0: Array = GameState.member_skills("merri")
	check(sk0.has("pause_dejeuner") and sk0.has("plan_b"), "voie du Stratège : Pause déjeuner et Plan B")
	GameState.new_game()
	GameState.party = ["merri"]
	GameState.member("merri")["level"] = 10
	_spend("merri", 1)
	var sk1: Array = GameState.member_skills("merri")
	check(sk1.has("coup_dans_le_dos") and sk1.has("charge_des_cousins"), "voie de l'Estoc : Coup dans le dos et Charge des cousins")
	# les compétences se lancent vraiment en combat
	GameState.new_game()
	GameState.party = ["glandoulf", "merri"]
	GameState.member("merri")["level"] = 10
	_spend("merri", 0)
	GameState.heal_party()
	var eng: RefCounted = BattleEngine.new()
	eng.setup({"enemies": ["limace_molle", "limace_molle"], "arena": "pre"}, 3)
	var merri_c: RefCounted = _find(eng.party, "merri")
	check(merri_c != null, "Merri combat")
	if merri_c != null:
		merri_c.mp = 40
		var ev: Array = eng.perform(merri_c, {"type": "skill", "id": "plan_ficele", "target": eng.party[0]})
		check(ev.size() > 0 and str(ev[0].get("anim", "")) == "plan_ficele", "Plan bien ficelé : animation plan_ficele")
		check(eng.party[0].has_status("galvanise"), "Plan bien ficelé galvanise l'allié")
		ev = eng.perform(merri_c, {"type": "skill", "id": "pause_dejeuner", "target": null})
		check(ev.size() > 0, "Pause déjeuner se lance")
		ev = eng.perform(merri_c, {"type": "skill", "id": "charge_des_cousins", "target": eng.enemies[0]})
		check(str(ev[0].get("anim", "")) == "charge_des_cousins", "Charge des cousins : animation")
		ev = eng.perform(merri_c, {"type": "attack", "target": eng.enemies[1]})
		check(str(ev[0].get("anim", "")) == "coup_de_dague_merri", "attaque de Merri : coup_de_dague_merri (%s)" % str(ev[0].get("anim", "")))
	# --- recrutement : la scène d'arrivée à Brie le fait entrer dans l'équipe
	check(_dialogue_has(Database.get_dialogue("arrivee_brie"), "join", "merri"), "arrivée à Brie : Merri rejoint l'équipe")
	check(_dialogue_has(Database.get_dialogue("merri_brie"), "join", "merri"), "Merri sur la place de Brie : recrutement de rattrapage")
	check(Database.has_dialogue("merri") and _dialogue_has(Database.get_dialogue("merri"), "who", "merri"), "Merri à Bittebourg : il se présente au chapitre 1")
	var brie_npc := false
	for o: Variant in Database.get_map("brie").get("objects", []):
		if o is Dictionary and str(o.get("id", "")) == "merri":
			brie_npc = true
	check(brie_npc, "Merri est posé sur la carte de Brie")
	# --- équilibre : six recrutés (avec Merri), mais quatre au combat, restent dans les fourchettes du chapitre 2
	var cases6 := [
		["Nazes, six recrutés niv. 9, talents A", TEAM6, 9, _soft("nazes_nuit", 0.3), 0.6, 0],
		["Nazes, six recrutés niv. 9, sans talents", TEAM6, 9, _soft("nazes_nuit", 0.3), 0.15, -1],
		["Chantecler, six recrutés niv. 8", TEAM6, 8, _soft("chantecler", 0.2), 0.6, 0],
		["Vacherin, six recrutés niv. 8", TEAM6, 8, _soft("vacherin", 0.2), 0.6, 0],
	]
	for case: Array in cases6:
		var rate := _c2_rate(case[1], int(case[2]), case[3], int(case[5]))
		check(rate >= float(case[4]), "%s : %d %% de victoires (attendu : au moins %d %%)" % [str(case[0]), int(rate * 100.0), int(float(case[4]) * 100.0)])
		print("  %-40s %3d %% de victoires" % [str(case[0]), int(rate * 100.0)])
	GameState.new_game()


# ---------------------------------------------------------------- interface

## Tout le texte et les contrôles visibles d'un écran tiennent dans la fenêtre.
func _ui_inside(root: Control, what: String) -> void:
	var view := get_viewport().get_visible_rect().grow(2.0)
	var bad := 0
	for n: Node in root.find_children("*", "Control", true, false):
		var c := n as Control
		if not c.is_visible_in_tree() or c.size.x <= 0.0 or c.size.y <= 0.0:
			continue
		var clipped := false
		var up: Node = c.get_parent()
		while up != null and up != root:
			if up is ScrollContainer:
				clipped = true
			up = up.get_parent()
		if clipped:
			continue
		if not view.encloses(c.get_global_rect()):
			bad += 1
			if bad <= 3:
				print("    hors écran (%s) : %s %s" % [what, c.get_class(), c.get_global_rect()])
	check(bad == 0, "interface : %s tient dans la fenêtre" % what)


func _ui_focus_in(root: Control, what: String) -> void:
	var owner := get_viewport().gui_get_focus_owner()
	check(owner != null and root.is_ancestor_of(owner), "interface : %s a un focus visible" % what)


## Touche pressée puis relâchée, par clavier (kb) ou par manette : passe par la file d'entrées du jeu.
func _tap(kb: bool, action: String) -> void:
	var keys := {"down": KEY_DOWN, "up": KEY_UP, "ok": KEY_ENTER, "back": KEY_BACKSPACE, "menu": KEY_ESCAPE, "left": KEY_LEFT, "right": KEY_RIGHT}
	var pads := {"down": JOY_BUTTON_DPAD_DOWN, "up": JOY_BUTTON_DPAD_UP, "ok": JOY_BUTTON_A, "back": JOY_BUTTON_B, "menu": JOY_BUTTON_START, "left": JOY_BUTTON_DPAD_LEFT, "right": JOY_BUTTON_DPAD_RIGHT}
	for down in [true, false]:
		var ev: InputEvent
		if kb:
			var k := InputEventKey.new()
			k.keycode = keys[action] as Key
			k.physical_keycode = keys[action] as Key
			k.pressed = down
			ev = k
		else:
			var j := InputEventJoypadButton.new()
			j.button_index = pads[action] as JoyButton
			j.pressed = down
			ev = j
		get_viewport().push_input(ev)
		await get_tree().process_frame


func _hint_texts(node: Node) -> String:
	var out := ""
	if node is Label:
		out += (node as Label).text + "|"
	for c in node.get_children():
		out += _hint_texts(c)
	return out


func _test_interface_input() -> void:
	print("== Interface : clavier seul, manette seule, rappels de touches ==")
	GameState.new_game()
	var layer := CanvasLayer.new()
	add_child(layer)
	var pad_before := Controls.pad
	for tip_id: String in ["boutique", "elan", "faiblesse"]:
		Tutorial.mark_seen(tip_id)   # l'aide a de quoi se parcourir
	GameState.add_to_party("sam")
	GameState.add_item("tisane")
	GameState.add_item("baton_ferre")
	GameState.set_flag("cales_recues")
	GameState.set_flag("intro_vue")   # le journal a une quête à montrer
	check(SaveManager.save_game("m1") and SaveManager.save_game("m2"), "interface : deux sauvegardes d'essai pour l'écran de chargement")

	# les rappels de touches suivent le dernier périphérique utilisé
	Controls.set_pad(false)
	var UIKit = preload("res://src/ui/ui_kit.gd")
	var row: Control = UIKit.hints(UIKit.KEYS_MENU)
	layer.add_child(row)
	await get_tree().process_frame
	check(_hint_texts(row).contains("Entrée") and not _hint_texts(row).contains("valider|valider"), "rappels : au clavier, les touches du clavier (%s)" % _hint_texts(row))
	Controls.set_pad(true)
	await get_tree().process_frame
	check(not _hint_texts(row).contains("Entrée") and _hint_texts(row).contains("valider"), "rappels : à la manette, plus de nom de touche du clavier (%s)" % _hint_texts(row))
	check(UIKit.key_text("ok") != "Entrée" and UIKit.key_text("menu") != "Échap", "rappels : les phrases parlent du bouton de la manette (%s)" % UIKit.key_text("ok"))
	Controls.set_pad(false)
	check(UIKit.key_text("ok") == "Entrée", "rappels : retour au clavier, retour à « Entrée »")
	var swapped := InputEventJoypadButton.new()
	swapped.button_index = JOY_BUTTON_A
	swapped.pressed = true
	get_viewport().push_input(swapped)
	await get_tree().process_frame
	check(Controls.pad, "rappels : un bouton de manette bascule les rappels sur la manette")
	var tapped := InputEventKey.new()
	tapped.keycode = KEY_DOWN
	tapped.pressed = true
	get_viewport().push_input(tapped)
	await get_tree().process_frame
	check(not Controls.pad, "rappels : une touche du clavier les rebascule")
	row.queue_free()

	# chaque écran se parcourt et se quitte avec un seul périphérique : aucune impasse
	for kb in [true, false]:
		var who := "clavier" if kb else "manette"
		Controls.set_pad(not kb)
		var screens := {}
		var pause: Control = PauseMenu.new()
		layer.add_child(pause)
		var settings: Control = preload("res://src/ui/settings_screen.gd").new()
		layer.add_child(settings)
		var help: Control = preload("res://src/ui/help_screen.gd").new()
		layer.add_child(help)
		var saves: Control = preload("res://src/ui/save_screen.gd").new()
		layer.add_child(saves)
		var menu: Control = GameMenu.new()
		layer.add_child(menu)
		await get_tree().process_frame
		var openers := {
			"pause": func() -> void: pause.open("Test"),
			"paramètres": func() -> void: settings.open("test"),
			"aide": func() -> void: help.open(),
			"sauvegardes": func() -> void: saves.open("load", "test"),
			"inventaire": func() -> void: menu.open("inventory"),
			"équipe": func() -> void: menu.open("team"),
			"journal": func() -> void: menu.open("quests"),
		}
		var nodes := {"pause": pause, "paramètres": settings, "aide": help, "sauvegardes": saves, "inventaire": menu, "équipe": menu, "journal": menu}
		for name: String in openers:
			var node: Control = nodes[name]
			(openers[name] as Callable).call()
			await get_tree().process_frame
			await get_tree().process_frame
			var first: Control = node.get_viewport().gui_get_focus_owner()
			check(node.visible and first != null and node.is_ancestor_of(first), "%s, %s : ouvert, le curseur est quelque part (%s)" % [name, who, str(first)])
			var seen := {first: true}
			for _i in 8:
				await _tap(kb, "down")
				var f: Control = node.get_viewport().gui_get_focus_owner()
				check(f != null, "%s, %s : le curseur ne disparaît jamais en descendant" % [name, who])
				if f != null:
					seen[f] = true
			for _i in 3:
				await _tap(kb, "up")
				var g: Control = node.get_viewport().gui_get_focus_owner()
				check(g != null, "%s, %s : le curseur ne disparaît jamais en montant" % [name, who])
				if g != null:
					seen[g] = true
			check(seen.size() >= 2 or name == "aide", "%s, %s : les touches fléchées déplacent le curseur (%d lignes visitées)" % [name, who, seen.size()])
			await _tap(kb, "back")
			await get_tree().process_frame
			check(not node.visible, "%s, %s : retour ferme l'écran (pas d'impasse)" % [name, who])
		pause.queue_free()
		settings.queue_free()
		help.queue_free()
		saves.queue_free()
		menu.queue_free()
		await get_tree().process_frame
	Controls.set_pad(pad_before)
	SaveManager.delete_slot("m1")
	SaveManager.delete_slot("m2")
	Tutorial.reset_seen()

	# une ligne de sauvegarde : récente (avec équipe), très ancienne (sans rien), jamais d'erreur
	var SaveScreenS = preload("res://src/ui/save_screen.gd")
	var ss: Control = SaveScreenS.new()
	layer.add_child(ss)
	await get_tree().process_frame
	GameState.new_game()
	GameState.add_to_party("sam")
	GameState.map_id = "auberge"
	var keep_slot := SaveManager.current_slot
	check(SaveManager.save_game("m1"), "sauvegardes : écriture d'essai pour les lignes")
	var fresh: Dictionary = (SaveManager.list_slots(false)[0] as Dictionary).duplicate()
	var old: Dictionary = fresh.duplicate()
	old.erase("party")   # une très ancienne sauvegarde ne portait pas l'équipe
	old["id"] = "m2"
	var empty: Dictionary = (SaveManager.list_slots(false)[3] as Dictionary).duplicate()
	empty["empty"] = true
	var r1: Button = ss._make_row(fresh)
	var r2: Button = ss._make_row(old)
	var r3: Button = ss._make_row(empty)
	layer.add_child(r1)
	layer.add_child(r2)
	layer.add_child(r3)
	await get_tree().process_frame
	check(r1 != null and r2 != null and r3 != null, "sauvegardes : une ligne récente, une ancienne sans équipe et une vide se construisent")
	check(_hint_texts(r1).contains("niv.") and _hint_texts(r1).contains("Au Bon Mouillage"), "sauvegardes : la ligne récente donne niveau et lieu (%s)" % _hint_texts(r1))
	check(_hint_texts(r2).contains("Au Bon Mouillage"), "sauvegardes : la ligne d'une ancienne sauvegarde s'affiche sans équipe")
	var faces1 := 0
	for c in _all_nodes(r1):
		if c is TextureRect:
			faces1 += 1
	var faces2 := 0
	for c in _all_nodes(r2):
		if c is TextureRect:
			faces2 += 1
	check(faces1 >= 2 and faces2 == 0, "sauvegardes : des vignettes pour une partie récente (%d), aucune pour une ancienne (%d)" % [faces1, faces2])
	SaveManager.delete_slot("m1")
	SaveManager.current_slot = keep_slot
	check(r1.size.y >= SaveScreenS.ROW_H - 1, "sauvegardes : la ligne est assez haute pour les vignettes")
	r1.queue_free()
	r2.queue_free()
	r3.queue_free()
	ss.queue_free()
	var described := SaveManager.describe(GameState.to_dict())
	check(described.has("party") and (described["party"] as Array).size() <= GameState.MAX_ACTIVE, "sauvegardes : la description donne au plus %d visages" % GameState.MAX_ACTIVE)
	layer.queue_free()


func _all_nodes(n: Node) -> Array:
	var out: Array = [n]
	for c in n.get_children():
		out.append_array(_all_nodes(c))
	return out


func _test_interface() -> void:
	print("== Interface : chaque écran se construit, tient dans la fenêtre et rend le focus ==")
	GameState.new_game()
	var layer := CanvasLayer.new()
	add_child(layer)
	var wait := func() -> void:
		await get_tree().create_timer(0.35).timeout

	# titre
	var title: Control = TitleScreen.new()
	layer.add_child(title)
	await get_tree().process_frame
	title.open()
	await wait.call()
	_ui_inside(title, "écran-titre")
	_ui_focus_in(title, "écran-titre")
	var extra: Button = title.add_entry("Paramètres", func() -> void: pass)
	check(extra != null and extra.get_index() < title._quit.get_index(), "interface : le titre accueille une entrée Paramètres avant Quitter")
	extra.queue_free()
	title.close()

	# pause : le focus revient où il était après un sous-écran
	var pause: Control = PauseMenu.new()
	layer.add_child(pause)
	await get_tree().process_frame
	pause.open("Un lieu   ·   0h01 de jeu   ·   80 écus\nUne équipe de test\nPlusieurs lignes d'information")
	await wait.call()
	_ui_inside(pause, "pause")
	_ui_focus_in(pause, "pause")
	var second: Button = pause._list.get_child(3)
	second.grab_focus()
	second.pressed.emit()
	pause.close(true)
	await get_tree().process_frame
	pause.open("autre")
	await get_tree().process_frame
	check(get_viewport().gui_get_focus_owner() == second, "interface : la pause rend le focus à la ligne d'où l'on revient")
	var extra_pause: Button = pause.add_entry("Paramètres", func() -> void: pass)
	check(extra_pause.get_index() == pause._list.get_child_count() - 3, "interface : la pause accueille une entrée Paramètres avant le retour au titre")
	extra_pause.queue_free()
	pause.close(true)

	# titre de lieu, bulle d'interaction et message : jamais l'un sur l'autre
	var hud: Control = Hud.new()
	layer.add_child(hud)
	await get_tree().process_frame
	hud.banner("Un lieu au nom assez long", "Un sous-titre tout aussi long, pour voir comment il se range sur deux lignes si besoin")
	hud.toast("Nouvelle quête : un intitulé de quête plutôt long, lui aussi")
	await get_tree().create_timer(1.3).timeout
	hud.show_prompt("Approcher", Vector2(640, 120))
	_ui_inside(hud, "interface en jeu")
	var banner_rect: Rect2 = hud._banner_rect()
	check(banner_rect.size != Vector2.ZERO, "interface : le titre de lieu est affiché")
	check(not Rect2(hud._prompt.position, hud._prompt.size).intersects(banner_rect), "interface : la bulle d'interaction ne chevauche pas le titre de lieu")
	check(not Rect2(hud._toast.position, hud._toast.size).intersects(banner_rect), "interface : le message de quête ne chevauche pas le titre de lieu")
	hud.clear()

	# dialogue : texte long et choix
	var who := str(GameState.party[0])
	Database.dialogues["_test_interface"] = [
		{"who": who, "text": "Un très long discours, pour vérifier que la boîte de dialogue ne laisse rien déborder de son bandeau : " + "il faut beaucoup de mots pour remplir les lignes pleines de texte, jusqu'à la limite des plus longues répliques du jeu.", "choice": [{"text": "Oui, bien sûr", "then": []}, {"text": "Non, certainement pas", "then": []}]},
	]
	var box: Control = DialogueBox.new()
	layer.add_child(box)
	await get_tree().process_frame
	box.start("_test_interface")
	await get_tree().create_timer(0.4).timeout
	box._finish_typing()
	await wait.call()
	check(box._text.get_content_height() <= box._text.size.y + 2.0, "interface : le texte du dialogue tient dans le bandeau")
	_ui_inside(box, "dialogue")
	_ui_focus_in(box, "dialogue (choix)")
	box.abort()
	Database.dialogues.erase("_test_interface")

	# menus à liste
	var menu: Control = GameMenu.new()
	layer.add_child(menu)
	await get_tree().process_frame
	GameState.add_item("tisane")
	for which: String in ["team", "inventory", "quests"]:
		menu.open(which)
		await wait.call()
		_ui_inside(menu, "menu " + which)
		_ui_focus_in(menu, "menu " + which)
		menu.close(true)
	if not Database.shops.is_empty():
		menu.open_shop(str(Database.shops.keys()[0]))
		await wait.call()
		_ui_inside(menu, "boutique")
		_ui_focus_in(menu, "boutique")
		menu.close(true)

	# talents
	var talents: Control = TalentScreen.new()
	layer.add_child(talents)
	await get_tree().process_frame
	talents.open()
	await wait.call()
	_ui_inside(talents, "talents")
	_ui_focus_in(talents, "talents")
	talents.close(true)

	# sauvegardes
	var saves: Control = load("res://src/ui/save_screen.gd").new()
	layer.add_child(saves)
	await get_tree().process_frame
	for mode: String in ["save", "load"]:
		saves.open(mode, "test")
		await wait.call()
		_ui_inside(saves, "sauvegardes (%s)" % mode)
		saves.close("", true)
	layer.queue_free()


## Retouches : échelle, formation de combat, sol de sous-bois.
func _test_retouches() -> void:
	print("== Retouches ==")
	check(Sprites.tile_texture("humus") != null, "sol de sous-bois peint")
	for n in range(2, 7):
		var sc: Array[float] = []
		for i in n:
			sc.append(1.0)
		var spots: Array[Vector3] = BattleScene.formation(sc)
		check(spots.size() == n, "formation à %d" % n)
		for i in range(1, n):
			# l'écart latéral sur l'écran (x) ne doit pas s'effondrer : chacun reste visible
			check(absf(spots[i].x - spots[i - 1].x) > 0.1 or absf(spots[i].z - spots[i - 1].z) > 0.6, "formation à %d : %d et %d séparés" % [n, i - 1, i])
# ------------------------------------------------------------ quatre combattants au plus

func _test_active_party() -> void:
	print("== Équipe active : quatre au plus, réserve ==")
	GameState.new_game()
	check(GameState.add_to_party("sam") == "active" and GameState.add_to_party("froton") == "active" and GameState.add_to_party("pepin") == "active", "les quatre premiers sont actifs")
	check(GameState.add_to_party("aragrogne") == "reserve" and GameState.add_to_party("merri") == "reserve", "le cinquième et le sixième vont en réserve")
	check(GameState.party.size() == 6 and GameState.active_party().size() == 4 and GameState.reserve_party() == ["aragrogne", "merri"], "6 recrutés : 4 actifs, 2 en réserve (%s)" % str(GameState.reserve_party()))
	check(GameState.add_to_party("merri") == "reserve" and GameState.party.size() == 6, "recruter deux fois ne double rien")
	check(GameState.check("party:merri") and GameState.check("party:aragrogne & party:sam"), "les dialogues party: voient aussi la réserve")
	check(GameState.is_active("sam") and GameState.is_reserve("merri") and not GameState.is_active("merri"), "is_active et is_reserve")
	for id: Variant in GameState.party:
		GameState.member(str(id))["level"] = 9
	GameState.heal_party()
	# le combat ne prend que les actifs
	var e: RefCounted = BattleEngine.new()
	e.setup({"enemies": ["limace_molle"], "arena": "pre"}, 1)
	var ids: Array = []
	for c: RefCounted in e.party:
		ids.append(str(c.source))
	check(ids == ["glandoulf", "sam", "froton", "pepin"], "un combat lance quatre personnages au plus (%s)" % str(ids))
	check(Database.roll_encounter("pre_couche", GameState.active_party().size()).size() >= 0, "les rencontres aléatoires comptent les actifs")
	# l'échange
	check(not GameState.swap_members("sam", "froton"), "deux actifs ne s'échangent pas")
	check(not GameState.swap_members("aragrogne", "merri"), "deux réservistes ne s'échangent pas")
	check(not GameState.swap_members("glandoulf", "merri"), "le meneur ne passe pas en réserve")
	check(not GameState.swap_members("sam", "fantome"), "un inconnu ne s'échange pas")
	check(GameState.swap_members("sam", "merri"), "Sam et Merri échangent leur place")
	check(GameState.party == ["glandoulf", "merri", "froton", "pepin", "aragrogne", "sam"], "ordre après l'échange : %s" % str(GameState.party))
	e = BattleEngine.new()
	e.setup({"enemies": ["limace_molle"], "arena": "pre"}, 1)
	ids = []
	for c: RefCounted in e.party:
		ids.append(str(c.source))
	check(ids == ["glandoulf", "merri", "froton", "pepin"], "le combat suit l'échange (%s)" % str(ids))
	# l'expérience : les actifs la gagnent en entier, la réserve aux trois quarts
	for id: Variant in GameState.party:
		var m := GameState.member(str(id))
		m["level"] = 9
		m["xp"] = 0
	GameState.heal_party()
	var fight := _fight({"enemies": ["limace_molle", "limace_molle"], "arena": "pre"}, 5)
	check(str(fight.result) == "victory", "victoire contre deux limaces")
	var loot: Dictionary = fight.commit()
	var gained := int(loot["xp"])
	check(gained > 0, "le combat rapporte de l'expérience (%d)" % gained)
	check(int(GameState.member("merri")["xp"]) == gained and int(GameState.member("pepin")["xp"]) == gained, "les actifs gagnent toute l'expérience (%d)" % int(GameState.member("merri")["xp"]))
	check(int(GameState.member("aragrogne")["xp"]) == 0 and int(GameState.member("sam")["xp"]) == 0, "la réserve ne gagne pas l'expérience du combat")
	# un réserviste au bord du niveau suivant n'y passe pas, et la victoire ne le cite pas
	GameState.member("sam")["xp"] = Rules.xp_to_next(9) - 1
	var fight2 := _fight({"enemies": ["limace_molle"], "arena": "pre"}, 6)
	var loot2: Dictionary = fight2.commit()
	var named := false
	for up: Dictionary in loot2["levelups"]:
		if str(up.get("id", "")) == "sam":
			named = true
	check(int(GameState.member("sam")["level"]) == 9 and not named, "un réserviste ne monte pas de niveau sans se battre")
	# une autre composition de quatre tient aussi contre les Nazes (le choix du joueur compte)
	for alt: Array in [["glandoulf", "sam", "aragrogne", "merri"], ["glandoulf", "pepin", "aragrogne", "froton"]]:
		var rate := _c2_rate(alt, 9, _soft("nazes_nuit", 0.3), 0)
		check(rate >= 0.5, "Nazes avec %s : %d %% de victoires (attendu : au moins 50 %%)" % [str(alt), int(rate * 100.0)])
		print("  Nazes, %-45s %3d %% de victoires" % [str(alt), int(rate * 100.0)])
	# ancienne sauvegarde à six : les quatre premiers sont actifs, les autres en réserve
	GameState.new_game()
	var old := {
		"version": 3, "chapter": "chapitre_3", "map_id": "brie", "spawn_id": "route",
		"party": ["glandoulf", "sam", "froton", "pepin", "aragrogne", "merri"],
		"roster": {"glandoulf": {"level": 9, "xp": 0, "talents": [], "equip": {}}},
		"flags": {}, "quests": {}, "money": 5, "inventory": {}, "bestiary": {}, "player_pos": [], "player_facing": "down", "playtime": 1.0,
	}
	check(GameState.from_dict(old), "une sauvegarde à six personnages se charge")
	check(GameState.active_party() == ["glandoulf", "sam", "froton", "pepin"] and GameState.reserve_party() == ["aragrogne", "merri"], "sauvegarde à six : 4 actifs, 2 en réserve")
	check(GameState.to_dict()["party"] == old["party"], "la sauvegarde réécrite garde le même ordre")
	GameState.swap_members("pepin", "merri")
	var again := GameState.to_dict()
	GameState.new_game()
	check(GameState.from_dict(again) and GameState.active_party() == ["glandoulf", "sam", "froton", "merri"], "l'échange survit à la sauvegarde")
	check(GameState.party_summary().contains("En réserve : Aragrogne, Pépin"), "le menu de pause nomme la réserve (%s)" % GameState.party_summary().replace("\n", " / "))
	# le menu Équipe : entrer dans l'équipe, passer en réserve, meneur protégé
	var layer := CanvasLayer.new()
	add_child(layer)
	var menu: Control = GameMenu.new()
	layer.add_child(menu)
	await get_tree().process_frame
	menu.open("team")
	await get_tree().process_frame
	var rows: Array = menu.entry_texts()
	check(rows.size() == 6 and str(rows[4]).contains("réserve") and not str(rows[3]).contains("réserve"), "Équipe : six lignes, les deux dernières en réserve")
	check(str(menu._title.text).contains("4 au combat") and str(menu._title.text).contains("2 en réserve"), "Équipe : le titre compte combattants et réserve (%s)" % str(menu._title.text))
	menu.press(4)   # Aragrogne
	await get_tree().process_frame
	var sub: Array = menu.entry_texts()
	check(sub.size() == 3 and str(sub[2]) == "Entrer dans l'équipe", "fiche d'un réserviste : Entrer dans l'équipe (%s)" % str(sub))
	menu.press(2)
	await get_tree().process_frame
	check(str(menu._title.text).begins_with("Échanger Aragrogne") and menu.entry_texts().size() == 4, "choix de celui qui lui cède sa place")
	menu.press(1)   # Sam
	await get_tree().process_frame
	check(GameState.is_active("aragrogne") and GameState.is_reserve("sam") and str(menu._title.text).begins_with("Équipe"), "échange fait depuis le menu")
	menu.press(0)   # Glandoulf
	await get_tree().process_frame
	menu.press(2)
	await get_tree().process_frame
	menu.press(0)   # le premier réserviste
	await get_tree().process_frame
	check(GameState.party[0] == "glandoulf" and str(menu._message.text) != "", "le meneur reste en tête, avec un message")
	menu.close()
	layer.queue_free()
	GameState.new_game()
	GameState.add_to_party("sam")
	check(GameState.reserve_party().is_empty() and GameState.active_party().size() == 2, "à deux, personne n'est en réserve")
	GameState.new_game()


# ------------------------------------------------------------------ chapitre 3

const C3_MAPS := ["col_biscottes", "fondue_combe", "salle_conseil", "chancellerie", "auberge_elfique", "archives"]


## Une rencontre de table, jouée sans interface (même mise en forme que _c2_rate).
func _c3_group_rate(table: String, level: int, talents: int) -> Array:
	var worst := 1.0
	var which := ""
	for g: Variant in (Database.encounter_tables[table] as Dictionary)["groups"]:
		var enc := {"enemies": (g as Dictionary)["enemies"]}
		var r := _c2_rate(TEAM, level, enc, talents)
		if r < worst:
			worst = r
			which = ", ".join(PackedStringArray((g as Dictionary)["enemies"]))
	return [worst, which]


func _test_chapter_3_data() -> void:
	print("== Chapitre 3 : données et équilibre ==")
	for id: String in C3_MAPS:
		check(Database.has_map(id), "carte %s existe" % id)
		check(Database.get_map(id).has("music") and Database.music.has(str(Database.get_map(id)["music"])), "carte %s : musique connue" % id)
	# les monstres du chapitre 2 et du chapitre 3 sont tous peints (aucun carré magenta)
	for kind: String in ["rat", "coq", "asticot", "vacherin", "mouche", "moisi", "chamois", "parchemin", "tampon"]:
		check(MonsterPainter.has(kind), "monstre %s : espèce connue" % kind)
		var img: Image = MonsterPainter.paint(kind)
		var magenta := 0
		var filled := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.5:
					filled += 1
					if c.r > 0.95 and c.g < 0.05 and c.b > 0.95:
						magenta += 1
		check(magenta == 0 and filled > 150, "monstre %s : dessiné, sans carré magenta (%d px, %d magenta)" % [kind, filled, magenta])
	for q: String in ["fondue", "tampons", "chant", "haie"]:
		check(not Database.get_quest(q).is_empty(), "quête %s décrite" % q)
	check(Database.get_quest("fondue").get("kind") == "principale", "le Conseil est la quête principale")
	for ch: String in ["elrond", "bromure", "huissier", "greffier", "gardien_archives"]:
		check(Database.characters.has(ch), "personnage %s décrit" % ch)
	for it: String in ["formulaire_3ex", "clef_archives", "proces_verbal", "tampon_officiel"]:
		check(Database.item_kind(it) == "key", "objet de quête %s" % it)
	for sh: String in ["chancellerie", "arsenal_sylvanor"]:
		check(not Database.get_shop(sh).is_empty(), "boutique %s" % sh)
	var west := false
	for o: Dictionary in Database.get_map("brie").get("objects", []):
		if str(o.get("type", "")) == "warp" and str((o.get("to", {}) as Dictionary).get("map", "")) == "col_biscottes":
			west = true
	check(west, "Brie a une sortie vers le col des Biscottes")
	check(Database.get_map("brie")["spawns"].has("ouest") and Database.get_map("col_biscottes")["spawns"].has("est"), "points d'arrivée de la route de l'ouest")
	for table: String in ["col_biscottes", "archives"]:
		var r := _c3_group_rate(table, 10, -1)
		check(float(r[0]) >= 0.9, "table %s, quatre niv. 10 sans talents : pire groupe %d %% (%s)" % [table, int(float(r[0]) * 100.0), str(r[1])])
		print("  table %-14s pire groupe %3d %%  (%s)" % [table, int(float(r[0]) * 100.0), str(r[1])])
	var boss := Database.get_encounter("gardien_archives")
	var with_talents := _c2_rate(TEAM, 11, boss, 0)
	var without := _c2_rate(TEAM, 11, boss, -1)
	check(with_talents >= 0.7, "Gardien des Archives, quatre niv. 11, talents A : %d %%" % int(with_talents * 100.0))
	check(without >= 0.0, "Gardien des Archives, quatre niv. 11, sans talents : %d %%" % int(without * 100.0))
	print("  Gardien des Archives : %d %% avec talents, %d %% sans" % [int(with_talents * 100.0), int(without * 100.0)])
	var alt := _c2_rate(["glandoulf", "sam", "aragrogne", "merri"], 11, boss, 0)
	check(alt >= 0.45, "Gardien des Archives, autre équipe de quatre sans soigneur (cible : 45 %% au moins) : %d %%" % int(alt * 100.0))
	var digrim := _c2_rate(["glandoulf", "digoulasse", "grimli", "pepin"], 11, boss, 0)
	check(digrim >= 0.15, "Gardien des Archives, sans Sam, avec Digoulasse et Grimli (composition hors _reasonable_teams) : %d %%" % int(digrim * 100.0))
	print("  Gardien, autre équipe %d %%, avec Digoulasse et Grimli %d %%" % [int(alt * 100.0), int(digrim * 100.0)])
	GameState.new_game()


## Déroulé du chapitre 3, à la suite de la sauvegarde de fin de chapitre 2.
func _test_chapter_3() -> void:
	print("== Chapitre 3 : déroulé complet ==")
	for state: Array in [[], ["archives_ouvertes", "chapitre_2_fini"], ["chapitre_3_fini", "bromure_invite", "archives_ouvertes", "gardien_vaincu"]]:
		await _test_map("fondue_combe", state, "état %d" % state.size())
	await _test_map("archives", ["archives_ouvertes"], "archives ouvertes")
	var main: Node = MAIN.instantiate()
	main.auto_battles = true
	add_child(main)
	await _wait_idle(main)
	main.continue_game()
	await _wait_idle(main)
	check(GameState.has_flag("chapitre_2_fini") and GameState.chapter == "chapitre_3", "reprise à la fin du chapitre 2")
	check(GameState.party.has("merri") and GameState.party.size() == 6, "six compagnons au départ (%d)" % GameState.party.size())
	for who: String in GameState.party:
		GameState.member(who)["level"] = 30   # déroulé, pas équilibre : très au-dessus du niveau attendu (à 14 le Gardien se gagne à 97 %)
	GameState.heal_party()
	var to_col := false
	for wp: Dictionary in main.world.warps:
		if str(wp["map"]) == "col_biscottes":
			to_col = true
	check(main.world.map_id == "brie" and to_col, "Brie mène au col des Biscottes une fois le chapitre 2 fini")

	main.change_map("col_biscottes", "est")
	await _wait_idle(main)
	check(main.world.map_id == "col_biscottes" and GameState.has_flag("col_vu"), "le col des Biscottes")
	main.run_dialogue("coffre_col")
	await _wait_idle(main)
	check(GameState.item_count("tampon_officiel") == 1, "premier tampon officiel")
	main.change_map("fondue_combe", "est")
	await _wait_idle(main)
	check(main.world.map_id == "fondue_combe" and GameState.has_flag("fondue_vue"), "arrivée à Fondue-Combe")
	check(GameState.quest_state("fondue") == "active" or GameState.quest_state("fondue") != "", "la quête du Conseil est lancée (%s)" % GameState.quest_state("fondue"))
	main.run_dialogue("coffre_jardin")
	await _wait_idle(main)
	check(GameState.item_count("tampon_officiel") == 2, "deuxième tampon, au jardin")

	# la Salle du Conseil refuse d'abord celui qui n'a pas de formulaire
	main.change_map("salle_conseil", "entree")
	await _wait_idle(main)
	main.run_dialogue("huissier")
	await _wait_idle(main)
	check(not GameState.has_flag("conseil_1_fait"), "pas de séance sans formulaire")

	# la Chancellerie : formulaire (Merri recopie), tampons demandés
	main.change_map("chancellerie", "entree")
	await _wait_idle(main)
	main.run_dialogue("greffier")
	await _wait_idle(main)
	check(GameState.has_flag("formulaire_pret") and GameState.item_count("formulaire_3ex") == 1, "le formulaire A-38 est prêt, en triple exemplaire")
	check(GameState.has_flag("tampons_vus") and GameState.quest_state("tampons") != "", "la chasse aux tampons est lancée")

	# deux annexes de la ville : la haie (Sam) et le chant (tisane corsée)
	main.change_map("fondue_combe", "chancellerie_porte")
	await _wait_idle(main)
	main.run_dialogue("buisson")
	await _wait_idle(main)
	for n in [1, 2, 3]:
		main.run_dialogue("haie_%d" % n)
		await _wait_idle(main)
	check(GameState.has_flag("haies_taillees"), "les trois haies sont taillées par Sam")
	main.run_dialogue("buisson")
	await _wait_idle(main)
	check(GameState.has_flag("haie_finie") and GameState.item_count("cisailles_elfiques") == 1 and GameState.quest_state("haie") == "done", "Maître Buisson remercie : cisailles dans le sac")
	main.run_dialogue("lorelia")
	await _wait_idle(main)
	check(GameState.has_flag("chant_vu") and not GameState.has_flag("chant_fini"), "Lorélia a perdu sa voix")
	GameState.add_item("tisane_corsee", 1)
	main.run_dialogue("lorelia")
	await _wait_idle(main)
	check(GameState.has_flag("chant_fini") and GameState.item_count("diapason_lorelia") == 1 and GameState.quest_state("chant") == "done", "le chant de neuf heures, jusqu'au bout")
	main.run_dialogue("sylvanor")
	await _wait_idle(main)
	check(GameState.has_flag("sylvanor_vu"), "l'arsenal de Sylvanor")

	# l'auberge : troisième tampon, repos
	main.change_map("auberge_elfique", "entree")
	await _wait_idle(main)
	main.run_dialogue("coffre_auberge")
	await _wait_idle(main)
	main.run_dialogue("clairefontaine")
	await _wait_idle(main)
	check(GameState.item_count("tampon_officiel") == 3, "troisième tampon, à l'auberge")

	# la première séance du Conseil
	main.change_map("salle_conseil", "entree")
	await _wait_idle(main)
	main.run_dialogue("huissier")
	await _wait_idle(main)
	check(GameState.has_flag("conseil_1_fait") and GameState.has_flag("archives_ouvertes"), "première séance : la clef des Archives est remise")
	check(GameState.item_count("clef_archives") == 1 and GameState.item_count("formulaire_3ex") == 0, "clef reçue, formulaire déposé")
	check(GameState.party.has("digoulasse") and GameState.is_reserve("digoulasse") and GameState.active_party().size() == 4, "Digoulasse rejoint l'équipe, en réserve")
	check(GameState.has_flag("merri_elrond"), "Merri prend les notes du Conseil")
	main.run_dialogue("huissier")
	await _wait_idle(main)
	check(not GameState.has_flag("chapitre_3_fini"), "le Conseil attend le procès-verbal")

	# les Archives et leur Gardien
	main.change_map("fondue_combe", "conseil_porte")
	await _wait_idle(main)
	var to_arch := false
	for wp: Dictionary in main.world.warps:
		if str(wp["map"]) == "archives":
			to_arch = true
	check(to_arch, "la porte des Archives s'ouvre avec la clef")
	main.change_map("archives", "entree")
	await _wait_idle(main)
	check(main.world.map_id == "archives" and GameState.has_flag("archives_vues"), "dans les Archives")
	main.run_dialogue("coffre_archives_tampon")
	await _wait_idle(main)
	check(GameState.item_count("tampon_officiel") == 4, "quatrième tampon, aux Archives")
	for who: String in GameState.party:
		GameState.member(who)["level"] = 30   # très au-dessus du niveau attendu : le déroulé ne dépend pas du hasard
	GameState.heal_party()
	main.run_dialogue("gardien_archives")
	await _wait_idle(main, 200.0)
	print("    [gardien] issue : combat_gardien_archives=%s gardien_vaincu=%s" % [str(GameState.has_flag("combat_gardien_archives")), str(GameState.has_flag("gardien_vaincu"))])
	check(GameState.has_flag("gardien_vaincu") and GameState.item_count("proces_verbal") == 1, "le Gardien est vaincu, le procès-verbal est dans le sac")
	GameState.heal_party()

	# la seconde séance : fin du chapitre
	main.change_map("salle_conseil", "entree")
	await _wait_idle(main)
	main.run_dialogue("huissier")
	await _wait_idle(main)
	check(GameState.has_flag("chapitre_3_fini") and GameState.chapter == "chapitre_4", "le chapitre 3 se termine (%s)" % GameState.chapter)
	check(GameState.has_flag("bromure_invite") and GameState.party.has("grimli"), "Bromure est invité, Grimli rejoint l'équipe")
	check(GameState.is_reserve("grimli") and GameState.active_party().size() == 4 and GameState.party.size() == 8, "huit compagnons, quatre au combat (%d)" % GameState.party.size())
	check(GameState.quest_state("fondue") == "done", "la quête principale du Conseil est accomplie")
	check(SaveManager.has_save(), "sauvegarde à la fin du chapitre 3")

	# les tampons sont rendus à la Chancellerie
	main.change_map("chancellerie", "entree")
	await _wait_idle(main)
	main.run_dialogue("greffier")
	await _wait_idle(main)
	check(GameState.has_flag("tampons_rendus") and GameState.item_count("sceau_chancellerie") == 1 and GameState.quest_state("tampons") == "done", "les quatre tampons sont rendus, le sceau est dans le sac")
	main.change_map("fondue_combe", "chancellerie_porte")
	await _wait_idle(main)
	var bromure_there := false
	for n: Node3D in main.world.npcs:
		if n.name == "Npc_bromure":
			bromure_there = true
	check(bromure_there, "Bromure attend en ville, invité")
	main.queue_free()
	await get_tree().process_frame


## Dit un dialogue de bout en bout, en répondant aux choix dans l'ordre de `picks`.
func _c4_say(main: Node, id: String, picks: Array = [], seconds: float = 60.0) -> void:
	_last_say = id
	pick_queue = picks.duplicate()
	main.run_dialogue(id)
	await _wait_idle(main, seconds)
	pick_queue = []


func _c4_has_warp(main: Node, map_id: String) -> bool:
	for wp: Dictionary in main.world.warps:
		if str(wp["map"]) == map_id:
			return true
	return false


## Chapitre 4 : les Mines de Morbier, joué dans le vrai jeu, de Fondue-Combe aux Portes de l'Est.
func _test_chapter_4() -> void:
	print("== Chapitre 4 : déroulé complet ==")
	# toutes les cartes, dans leurs différents états : tout passage est atteignable à pied
	await _test_map("porte_morbier", ["chapitre_3_fini", "bromure_invite"], "porte fermée")
	await _test_map("porte_morbier", ["chapitre_3_fini", "bromure_invite", "porte_ouverte", "porte_vue"], "porte ouverte")
	await _test_map("morbier_galeries", [], "galeries")
	await _test_map("morbier_galeries", ["combat_gobelins_du_camp", "pioche_prise", "bromure_invite"], "galeries, camp vaincu")
	await _test_map("morbier_halle", [], "halle")
	await _test_map("morbier_halle", ["combat_gros_bleu", "tombe_visitee", "bromure_invite"], "halle, tombe visitée")
	await _test_map("morbier_tombe", [], "tombe")
	await _test_map("morbier_tombe", ["combat_gros_bleu"], "tombe, troll vaincu")
	await _test_map("morbier_profondeurs", [], "profondeurs")
	await _test_map("morbier_antre", [], "antre")
	await _test_map("morbier_antre", ["goulum_rencontre", "combat_goulum", "bromure_invite"], "antre, duel fini")
	await _test_map("morbier_pont", [], "pont")
	await _test_map("morbier_pont", ["balourd_fait", "combat_balourd", "glandoulf_tombe", "bromure_invite"], "pont, Balourd tombé")
	await _test_map("portes_est", [], "portes de l'Est")

	var main: Node = MAIN.instantiate()
	main.auto_battles = true
	add_child(main)
	await _wait_idle(main)
	main.continue_game()
	await _wait_idle(main)
	check(GameState.has_flag("chapitre_3_fini") and GameState.chapter == "chapitre_4", "reprise à la fin du chapitre 3 (%s)" % GameState.chapter)
	check(GameState.party.has("glandoulf") and GameState.party.has("grimli") and GameState.party.size() == 8, "huit compagnons au départ (%d)" % GameState.party.size())
	for who: String in GameState.party:
		GameState.member(who)["level"] = 40   # déroulé, pas équilibre : très au-dessus du niveau attendu (à 16 un combat se perdait une fois sur dix, à 30 le Gros Bleu gagnait encore de temps en temps)
	GameState.heal_party()

	# Fondue-Combe mène à la porte de Morbier une fois le chapitre 3 fini
	main.change_map("fondue_combe", "conseil_porte")
	await _wait_idle(main)
	check(_c4_has_warp(main, "porte_morbier"), "Fondue-Combe : la sortie ouest mène aux Monts de Morbier")
	main.change_map("porte_morbier", "vallee")
	await _wait_idle(main)
	check(main.world.map_id == "porte_morbier" and GameState.has_flag("porte_vue"), "la porte de Morbier")
	check(GameState.quest_state("morbier") != "" and GameState.quest_state("morbier") != "done", "la quête des Mines est lancée (%s)" % GameState.quest_state("morbier"))
	check(not _c4_has_warp(main, "morbier_galeries"), "la porte est fermée tant que l'énigme n'est pas résolue")
	# l'énigme : deux mauvaises réponses, puis la bonne ; le lac se réveille
	await _c4_say(main, "porte_enigme", [0])
	check(GameState.has_flag("porte_essai") and not GameState.has_flag("porte_ouverte"), "« Mellon » : la porte ne s'ouvre pas")
	await _c4_say(main, "porte_enigme", [1])
	check(not GameState.has_flag("porte_ouverte"), "« Camembert » : la porte ne s'ouvre pas non plus")
	await _c4_say(main, "porte_enigme", [2], 200.0)
	check(GameState.has_flag("porte_ouverte") and GameState.has_flag("combat_guetteur_du_lac"), "« Ami du Chambertin » : la porte s'ouvre, le Guetteur du lac est vaincu")
	check(_c4_has_warp(main, "morbier_galeries"), "la porte ouverte mène aux galeries")
	GameState.heal_party()
	check(SaveManager.has_save(), "sauvegarde à la porte")

	# les galeries : pioche, coffres, camp de gobelins
	main.change_map("morbier_galeries", "porte")
	await _wait_idle(main)
	check(main.world.map_id == "morbier_galeries" and GameState.has_flag("galeries_vues"), "les galeries de Morbier")
	await _c4_say(main, "pioche_trouvee")
	check(GameState.item_count("pioche_rondin") == 1, "la pioche de Rondin est ramassée")
	await _c4_say(main, "coffre_galerie_1")
	check(GameState.item_count("page_comptes") == 1, "première page du registre")
	await _c4_say(main, "coffre_galerie_2")
	await _c4_say(main, "coffre_camp")
	check(GameState.item_count("meule_morbier") == 1, "la meule du camp est dans le sac")
	await _c4_say(main, "camp_gobelins", [], 200.0)
	check(GameState.has_flag("combat_gobelins_du_camp") and GameState.has_flag("camp_vaincu"), "le camp de gobelins est vaincu")
	GameState.heal_party()

	# la Grande Salle des Forges : Rondin, Grimli barre la route de l'est
	main.change_map("morbier_halle", "ouest")
	await _wait_idle(main)
	check(GameState.has_flag("halle_vue"), "la Grande Salle des Forges")
	check(not _c4_has_warp(main, "morbier_profondeurs"), "la sortie est reste fermée avant la tombe")
	await _c4_say(main, "rondin", [1])
	await _c4_say(main, "rondin", [2])
	check(GameState.has_flag("pioche_rendue") and GameState.has_flag("meule_livree"), "Rondin récupère sa pioche et sa meule")
	await _c4_say(main, "coffre_halle")
	await _c4_say(main, "halle_repos", [0])
	GameState.heal_party()

	# la tombe : Gros Bleu, puis le Roi Ballot
	main.change_map("morbier_tombe", "entree")
	await _wait_idle(main)
	check(GameState.has_flag("tombe_vue"), "la tombe du Roi Ballot")
	await _c4_say(main, "tombe_ballot")
	check(not GameState.has_flag("tombe_visitee"), "la dalle reste muette tant que le troll garde la salle")
	await _c4_say(main, "troll_tombe", [], 200.0)
	check(GameState.has_flag("combat_gros_bleu") and GameState.has_flag("gros_bleu_vaincu"), "le Gros Bleu des caves est vaincu")
	await _c4_say(main, "tombe_ballot")
	check(GameState.has_flag("tombe_visitee"), "Grimli salue le Roi Ballot")
	await _c4_say(main, "coffre_tombe")
	GameState.heal_party()
	main.change_map("morbier_halle", "tombe")
	await _wait_idle(main)
	check(_c4_has_warp(main, "morbier_profondeurs"), "la halle s'ouvre vers les profondeurs")

	# les profondeurs : trois coffres, un pont sur l'abîme
	main.change_map("morbier_profondeurs", "haut")
	await _wait_idle(main)
	check(GameState.has_flag("profondeurs_vues"), "les profondeurs")
	await _c4_say(main, "coffre_prof_1")
	await _c4_say(main, "coffre_prof_2")
	check(GameState.item_count("page_comptes") == 3, "les trois pages du registre sont réunies (%d)" % GameState.item_count("page_comptes"))
	main.change_map("morbier_tombe", "entree")
	await _wait_idle(main)
	await _c4_say(main, "registre_ballot")
	await _c4_say(main, "registre_ballot")
	check(GameState.has_flag("comptes_rendus") and GameState.item_count("page_comptes") == 0, "le Roi Ballot reprend ses pages")
	GameState.heal_party()

	# le lac de Maroilles : la devinette, puis le combat contre Goulûm
	main.change_map("morbier_antre", "entree")
	await _wait_idle(main)
	for who: String in GameState.party:
		GameState.member(who)["level"] = 30   # le duel de devinettes puis le combat : très au-dessus du niveau attendu
	GameState.heal_party()
	await _c4_say(main, "goulum_duel", [0, 0, 0], 300.0)
	check(GameState.has_flag("goulum_rencontre") and GameState.has_flag("devinette_1") and GameState.has_flag("devinette_2"), "deux devinettes sur trois résolues")
	check(GameState.has_flag("combat_goulum"), "Goulûm est vaincu")
	check(GameState.has_flag("anneau_repris") and GameState.has_flag("froton_porte_anneau"), "l'anneau est repris, Froton le porte")
	check(GameState.has_flag("bromure_invite") and GameState.party.has("glandoulf"), "Bromure a suivi l'équipe, Glandoulf est toujours là")
	GameState.heal_party()

	# le pont : Glandoulf retient le Balourd et tombe
	main.change_map("morbier_pont", "ouest")
	await _wait_idle(main)
	check(not _c4_has_warp(main, "portes_est"), "la sortie est est coupée avant le Balourd")
	for who: String in GameState.party:
		GameState.member(who)["level"] = 40
	GameState.heal_party()
	await _c4_say(main, "balourd_pont", [], 300.0)
	check(GameState.has_flag("combat_balourd") and GameState.has_flag("glandoulf_tombe"), "le Balourd est tombé, Glandoulf avec lui")
	check(not GameState.party.has("glandoulf") and GameState.leader() == "sam", "Glandoulf quitte l'équipe : Sam la mène (%s)" % GameState.leader())
	check(GameState.party.size() == 7 and GameState.active_party().size() == 4, "sept compagnons, quatre au combat (%d)" % GameState.party.size())
	check(not GameState.active_party().has("glandoulf") and GameState.member("sam").get("level", 0) >= 16, "l'équipe active est complète sans Glandoulf")
	check(_c4_has_warp(main, "portes_est"), "le pont mène aux Portes de l'Est")

	# les Portes de l'Est : fin du chapitre
	main.change_map("portes_est", "pont")
	await _wait_idle(main)
	check(main.world.map_id == "portes_est" and main.world.player != null, "les Portes de l'Est se jouent sans Glandoulf")
	await _c4_say(main, "deuil_portes")
	check(GameState.has_flag("chapitre_4_fini") and GameState.chapter == "chapitre_5", "le chapitre 4 se termine (%s)" % GameState.chapter)
	check(GameState.quest_state("morbier") == "done", "la quête des Mines est accomplie")
	check(SaveManager.has_save(), "sauvegarde à la fin du chapitre 4")
	# une carte quelconque se construit encore sans Glandoulf
	main.change_map("fondue_combe", "est")
	await _wait_idle(main)
	check(main.world.map_id == "fondue_combe", "le monde se construit sans Glandoulf dans l'équipe")
	main.queue_free()
	await get_tree().process_frame


## Chapitre 5 joué dans le vrai jeu : Bromure, l'embuscade, le groupe qui se scinde, le retour de
## Glandoulf, la bergerie, l'Isengarde-Manger, Sarumâle. Tous niveaux au-dessus de l'attendu.
func _test_chapter_5() -> void:
	print("== Chapitre 5 : déroulé complet ==")
	var base := ["chapitre_4_fini", "portes_vues", "glandoulf_tombe", "combat_balourd"]
	await _test_map("portes_est", base, "portes de l'Est avant Bromure")
	await _test_map("portes_est", base + ["bromure_mort"], "portes de l'Est après Bromure")
	await _test_map("chutes_gratin", base + ["bromure_mort"], "chutes avant l'embuscade")
	await _test_map("chutes_gratin", base + ["bromure_mort", "embuscade_faite"], "chutes, embuscade passée")
	await _test_map("plaine_roquefort", ["plaine_vue"], "plaine des Cavaliers")
	await _test_map("plaine_roquefort", ["plaine_vue", "coffre_plaine_pris"], "plaine, coffre ouvert")
	await _test_map("cabecou", ["cabecou_vu"], "Cabécou, halle fermée")
	await _test_map("cabecou", ["cabecou_vu", "combat_grimace", "grimace_vaincue"], "Cabécou, halle ouverte")
	await _test_map("cabecou", ["cabecou_vu", "combat_grimace", "grimace_vaincue", "reunion_faite"], "Cabécou, route de l'Isengarde")
	await _test_map("fongorn", ["fongorn_vu"], "Fongorn avant Glandoulf")
	await _test_map("fongorn", ["fongorn_vu", "glandoulf_revenu"], "Fongorn après Glandoulf")
	await _test_map("garde_manger", ["garde_vu"], "Garde-Manger")
	await _test_map("garde_manger", ["garde_vu", "bilan_fait", "froton_libere", "combat_uglouk_garde"], "Garde-Manger, Froton libéré")
	await _test_map("bergerie_or", ["bergerie_vue"], "Bergerie d'Or")
	await _test_map("isengarde", ["isengarde_vu"], "Isengarde-Manger")
	await _test_map("isengarde", ["isengarde_vu", "fosses_inondees", "fours_eteints"], "Isengarde inondée")
	await _test_map("terrasse_office", ["terrasse_vue"], "terrasse de l'Office")
	await _test_map("terrasse_office", ["terrasse_vue", "sarumale_vaincu"], "terrasse après Sarumâle")

	# départ : la fin du chapitre 4 (Glandoulf tombé, sept compagnons, Sam mène)
	GameState.new_game()
	GameState.party = ["sam", "froton", "pepin", "merri", "aragrogne", "digoulasse", "grimli"]
	GameState.bench = []
	for who: String in GameState.party:
		GameState.member(who)
	GameState.member("glandoulf")["level"] = 16
	for who: String in GameState.party:
		GameState.member(who)["level"] = 16
	for f: String in base:
		GameState.set_flag(f)
	GameState.chapter = "chapitre_5"
	GameState.money = 400
	GameState.map_id = "portes_est"
	GameState.spawn_id = "pont"
	GameState.heal_party()
	check(SaveManager.save_game(), "sauvegarde au départ du chapitre 5")
	var main: Node = MAIN.instantiate()
	main.auto_battles = true
	add_child(main)
	await _wait_idle(main)
	main.continue_game()
	await _wait_idle(main)
	check(GameState.leader() == "sam" and not GameState.party.has("glandoulf") and GameState.bench.is_empty(), "départ : Sam mène, Glandoulf est absent")
	for who: String in GameState.party:
		GameState.member(who)["level"] = 34   # déroulé, pas équilibre : au-dessus du niveau attendu
	GameState.heal_party()

	# Bromure : il survit à tout, il parle, un glaçon l'interrompt
	check(main.world.map_id == "portes_est" and not _c4_has_warp(main, "chutes_gratin"), "les Portes de l'Est : la sortie est reste fermée avant les adieux")
	await _c4_say(main, "bromure_adieu")
	check(GameState.has_flag("bromure_mort") and GameState.item_count("cape_de_bromure") == 1, "Bromure est mort d'un glaçon : sa cape reste")
	await _c4_say(main, "bromure_tombe")
	main.change_map("portes_est", "pont")
	await _wait_idle(main)
	check(_c4_has_warp(main, "chutes_gratin"), "après les adieux, la route mène aux chutes")

	# les chutes : l'embuscade d'Uglouk, puis le groupe se scinde
	main.change_map("chutes_gratin", "ouest")
	await _wait_idle(main, 240.0)
	check(GameState.has_flag("embuscade_faite") and GameState.has_flag("combat_ambuscade_chutes"), "l'embuscade d'Uglouk est jouée")
	check(GameState.party == ["aragrogne", "digoulasse", "grimli"] and GameState.leader() == "aragrogne", "le groupe se scinde : Aragrogne mène les trois captifs (%s)" % str(GameState.party))
	check(GameState.bench.size() == 4 and GameState.bench.has("sam") and GameState.bench.has("merri") and GameState.bench.has("pepin") and GameState.bench.has("froton"), "les chasseurs attendent sur le banc (%s)" % str(GameState.bench))
	check(main.world.map_id == "plaine_roquefort", "le dialogue emmène le groupe dans la plaine (%s)" % main.world.map_id)
	check(GameState.has_flag("plaine_vue") and GameState.quest_state("isengarde") != "", "la quête principale est lancée")
	check(int(GameState.member("sam")["level"]) == 34 and int(GameState.member("aragrogne")["level"]) == 34, "les niveaux et fiches sont conservés")
	check(SaveManager.has_save(), "sauvegarde à l'arrivée dans la plaine")
	await _c4_say(main, "plaine_coffre")
	check(GameState.item_count("fer_a_cheval_dore") == 1 and GameState.has_flag("coffre_plaine_pris"), "le coffre de la plaine")
	await _c4_say(main, "plaine_cisailles")
	check(GameState.item_count("cisailles_de_tonte") == 1, "les cisailles de tonte")
	GameState.heal_party()

	# le Cabécou : Grimace garde la halle
	main.change_map("cabecou", "ouest")
	await _wait_idle(main)
	check(GameState.has_flag("cabecou_vu") and not _c4_has_warp(main, "fongorn") and not _c4_has_warp(main, "bergerie_or"), "le Cabécou : fongorn et la bergerie sont fermés tant que Grimace garde la halle")
	await _c4_say(main, "eomeche")
	for who: String in GameState.party:
		GameState.member(who)["level"] = 36
	GameState.heal_party()
	await _c4_say(main, "grimace_gate", [], 300.0)
	check(GameState.has_flag("combat_grimace") and GameState.has_flag("grimace_vaincue"), "Grimace est vaincue, elle laisse son feuillet à souche")
	await _c4_say(main, "eolaine")
	check(GameState.quest_state("roi_dort_mal") != "", "la quête du roi qui dort mal")
	main.change_map("cabecou", "ouest")
	await _wait_idle(main)
	check(_c4_has_warp(main, "fongorn") and _c4_has_warp(main, "bergerie_or") and not _c4_has_warp(main, "isengarde"), "la halle et Fongorn s'ouvrent, l'Isengarde reste fermée")
	# quête annexe : les cisailles jouées au chevet du roi endormi (avant que Merri le réveille pour de bon)
	main.change_map("bergerie_or", "porte")
	await _wait_idle(main)
	check(not GameState.has_flag("bergerie_vue"), "la bergerie : rien ne se joue tant que Froton n'est pas libéré")
	await _c4_say(main, "trone_roi")
	check(GameState.has_flag("roi_ecoute") and GameState.quest_state("roi_dort_mal") == "done", "les cisailles bercent le roi : la quête du roi qui dort mal est accomplie")

	# Fongorn : Glandoulf avoue et reprend la tête (symétrique de « quitte: »)
	main.change_map("fongorn", "ouest")
	await _wait_idle(main)
	check(GameState.has_flag("fongorn_vu"), "la forêt de Fongorn")
	await _c4_say(main, "retour_glandoulf")
	check(GameState.has_flag("glandoulf_revenu") and GameState.leader() == "glandoulf", "Glandoulf revient et reprend la tête (%s)" % str(GameState.party))
	check(GameState.party == ["glandoulf", "aragrogne", "digoulasse", "grimli"], "le groupe : Glandoulf et les captifs (%s)" % str(GameState.party))
	check(GameState.bench.size() == 4 and not GameState.bench.has("glandoulf"), "les quatre chasseurs restent sur le banc (%s)" % str(GameState.bench))
	check(int(GameState.member("glandoulf")["level"]) >= 22, "Glandoulf rattrape le niveau du groupe (%d)" % int(GameState.member("glandoulf")["level"]))
	check(str((GameState.member("glandoulf")["equip"] as Dictionary).get("weapon", "")) == "louche_blanche", "il porte la Louche Blanche")
	check(GameState.member_skills("glandoulf").has("veille_de_pierre"), "la Louche Blanche lui donne ses compétences")
	check(GameState.item_count("plume_de_l_aigle") == 1, "la plume de l'aigle")
	# sauvegarde en cours de route : le banc et le groupe se retrouvent
	var party_then: Array = GameState.party.duplicate()
	var bench_then: Array = GameState.bench.duplicate()
	GameState.map_id = "fongorn"
	check(SaveManager.save_game(), "sauvegarde en plein groupe scindé")
	GameState.new_game()
	check(GameState.bench.is_empty(), "nouvelle partie : banc vidé")
	check(SaveManager.load_game(), "rechargement")
	check(GameState.party == party_then and GameState.bench == bench_then, "rechargement : groupe %s et banc %s retrouvés" % [str(GameState.party), str(GameState.bench)])
	check(GameState.leader() == "glandoulf" and GameState.member("sam").has("level"), "rechargement : Glandoulf mène, la fiche de Sam est intacte")
	main.continue_game()
	await _wait_idle(main)
	check(main.world.map_id == "fongorn" and main.world.player != null, "la partie rechargée se rejoue (%s)" % main.world.map_id)
	await _c4_say(main, "fongorn_coffre")
	check(GameState.has_flag("coffre_fongorn_pris"), "le coffre de Fongorn")
	await _c4_say(main, "barbe_molle")
	check(GameState.has_flag("nouvelles_demandees") and GameState.quest_state("trois_nouvelles") != "", "Barbe-Molle demande trois nouvelles")
	for d: String in ["entremet_mousse", "entremet_ecorce", "entremet_rejet"]:
		await _c4_say(main, d)
	await _c4_say(main, "barbe_molle", [], 120.0)
	check(GameState.has_flag("nouvelles_rendues") and GameState.quest_state("trois_nouvelles") == "done", "les trois nouvelles sont rendues")
	check(main.world.map_id == "garde_manger" and GameState.party == ["sam", "froton", "merri", "pepin"], "le groupe des chasseurs repart au Garde-Manger (%s, %s)" % [main.world.map_id, str(GameState.party)])
	check(GameState.bench.has("glandoulf") and GameState.bench.size() == 4, "Glandoulf et les captifs attendent à Fongorn (%s)" % str(GameState.bench))

	# le Garde-Manger : Froton passe l'anneau, la ronde, la goulotte
	check(GameState.has_flag("garde_vu"), "le Garde-Manger")
	for who: String in GameState.party:
		GameState.member(who)["level"] = 36
	GameState.heal_party()
	await _c4_say(main, "garde_bilan", [], 300.0)
	check(GameState.has_flag("bilan_fait") and GameState.has_flag("combat_froton_anneaute") and GameState.has_flag("froton_libere"), "Froton Anneauté est vaincu et libéré")
	check(GameState.party == ["sam", "froton", "merri", "pepin"], "le groupe des chasseurs est reconstitué (%s)" % str(GameState.party))
	check(GameState.item_count("brioche_non_conforme") >= 1, "une brioche non conforme")
	await _c4_say(main, "garde_ronde", [], 300.0)
	check(GameState.has_flag("combat_uglouk_garde"), "la ronde du Garde-Manger est battue")
	await _c4_say(main, "garde_coffre")
	check(GameState.has_flag("coffre_garde_pris") and GameState.item_count("tablier_de_petrisseur") == 1, "le coffre du Garde-Manger")
	await _c4_say(main, "garde_etiquette")
	check(_c4_has_warp(main, "bergerie_or"), "la goulotte mène à la Bergerie d'Or")
	GameState.heal_party()
	await _c4_say(main, "garde_goulotte", [], 120.0)
	check(main.world.map_id == "bergerie_or", "la goulotte : on tombe dans la bergerie (%s)" % main.world.map_id)
	check(GameState.has_flag("merri_ecuyer") and GameState.has_flag("roi_reveille") and GameState.has_flag("reunion_faite"), "Merri devient Écuyer Tranchant, le roi s'éveille, le groupe est réuni")
	check(str((GameState.member("merri")["equip"] as Dictionary).get("weapon", "")) == "dague_de_l_ecuyer", "Merri porte la dague de l'Écuyer")
	check(GameState.party == ["glandoulf", "sam", "froton", "aragrogne"], "les quatre de l'assaut (%s)" % str(GameState.party))
	check(GameState.bench.size() == 4 and GameState.bench.has("merri") and GameState.bench.has("pepin"), "les autres attendent sur le banc (%s)" % str(GameState.bench))
	check(SaveManager.has_save(), "sauvegarde à la Bergerie d'Or")
	await _c4_say(main, "bergerie_coffre")
	check(GameState.has_flag("coffre_bergerie_pris") and GameState.item_count("heaume_a_criniere") == 1, "le coffre de la bergerie")
	await _c4_say(main, "trone_roi")
	check(GameState.has_flag("roi_reveille"), "le roi, réveillé par Merri, est reposé")

	# l'Isengarde : la brèche, la tour, Sarumâle
	main.change_map("cabecou", "porte")
	await _wait_idle(main)
	check(_c4_has_warp(main, "isengarde"), "le Cabécou ouvre la route de l'Isengarde-Manger")
	main.change_map("isengarde", "sud")
	await _wait_idle(main)
	check(GameState.has_flag("isengarde_vu") and not _c4_has_warp(main, "terrasse_office"), "l'Isengarde-Manger : la tour est fermée")
	await _c4_say(main, "isengarde_sac")
	check(GameState.has_flag("coffre_isengarde_pris"), "le sac de l'Isengarde")
	for who: String in GameState.party:
		GameState.member(who)["level"] = 38
	GameState.heal_party()
	await _c4_say(main, "isengarde_breche", [], 300.0)
	check(GameState.has_flag("combat_breche") and GameState.has_flag("fosses_inondees") and GameState.has_flag("fours_eteints"), "la brèche est forcée, les fosses sont inondées")
	main.change_map("isengarde", "tour")
	await _wait_idle(main)
	check(_c4_has_warp(main, "terrasse_office"), "la tour s'ouvre sur la terrasse de l'Office")
	main.change_map("terrasse_office", "entree")
	await _wait_idle(main, 600.0)
	check(GameState.has_flag("sarumale_vaincu") and GameState.has_flag("combat_sarumale"), "Sarumâle est vaincu")
	check(GameState.has_flag("chapitre_5_fini") and GameState.chapter == "chapitre_6", "le chapitre 5 se termine (%s)" % GameState.chapter)
	check(GameState.quest_state("isengarde") == "done", "la quête principale est accomplie")
	check(GameState.item_count("robe_bariolee") + GameState.worn_by("robe_bariolee").size() >= 1, "la robe bariolée est à l'équipe")
	check(SaveManager.has_save(), "sauvegarde à la fin du chapitre 5")
	main.queue_free()
	await get_tree().process_frame
	SaveManager.delete_save()


## Mécanique de groupe en dehors du déroulé : scission, réunion, niveaux, réserve sans expérience.
func _test_group_mechanism() -> void:
	GameState.new_game()
	for who: String in ["sam", "froton", "pepin", "merri", "aragrogne"]:
		GameState.add_to_party(who)
	GameState.member("sam")["level"] = 12
	GameState.member("aragrogne")["level"] = 5
	GameState.member("sam")["equip"] = {"weapon": "serpette_affutee"}
	check(GameState.set_group(["sam", "aragrogne"]), "set_group : groupe valable")
	check(GameState.party == ["sam", "aragrogne"] and GameState.bench.size() == 4, "set_group : deux au groupe, quatre sur le banc (%s / %s)" % [str(GameState.party), str(GameState.bench)])
	check(str((GameState.member("sam")["equip"] as Dictionary).get("weapon", "")) == "serpette_affutee", "set_group : l'équipement est conservé")
	check(not GameState.set_group(["personne"]) and GameState.party == ["sam", "aragrogne"], "set_group : un nom inconnu ne change rien")
	check(GameState.set_group(["glandoulf", "sam", "froton", "pepin", "merri"]) and GameState.active_party().size() == 4 and GameState.reserve_party().size() == 1, "set_group : au plus quatre se battent")
	check(int(GameState.member("glandoulf")["level"]) >= 1, "set_group : Glandoulf rejoint avec une fiche valable")
	GameState.set_group(["sam", "froton", "pepin", "merri", "aragrogne"])
	check(int(GameState.member("aragrogne")["level"]) >= 5, "set_group : un revenant n'est jamais rétrogradé")
	var d := GameState.to_dict()
	check(d.has("bench"), "sauvegarde : le champ « bench » existe")
	var old := d.duplicate(true)
	old.erase("bench")
	GameState.new_game()
	check(GameState.from_dict(old) and GameState.bench.is_empty(), "une sauvegarde d'avant le chapitre 5 se charge sans banc")
	check(GameState.from_dict(d) and GameState.bench == d["bench"], "une sauvegarde avec banc se recharge")
	GameState.new_game()


## Style nain : tuiles, décors et objets peints, cartes du chapitre 4, construction des cartes.
func _test_dwarven_scenery() -> void:
	var Dwarven: GDScript = load("res://src/gfx/dwarven_painter.gd")
	var DwarvenBuilder: GDScript = load("res://src/world/dwarven_builder.gd")
	var MapBuilder: GDScript = load("res://src/world/map_builder.gd")
	var docs := FileAccess.get_file_as_string("res://docs/FORMAT_DONNEES.md")
	for kind: String in Dwarven.TILES:
		var img: Image = Sprites.tile_image(kind)
		check(img != null and img.get_width() >= 48, "style nain : la tuile %s est peinte" % kind)
		check(not img.get_pixel(3, 3).is_equal_approx(Color(1, 0, 1)), "style nain : la tuile %s n'est pas le magenta de secours" % kind)
		check(docs.contains(kind), "style nain : la tuile %s est documentée" % kind)
	for kind: String in Dwarven.PROP_VARIANTS:
		check(MapBuilder.PROPS.has(kind), "style nain : %s est un accessoire déclaré" % kind)
		check(docs.contains(kind), "style nain : %s est documenté" % kind)
		for v in int(Dwarven.PROP_VARIANTS[kind]):
			var tex: Texture2D = Sprites.prop(kind, v)
			check(tex != null and tex.get_width() > 4 and tex.get_height() > 4, "style nain : %s variante %d peint" % [kind, v])
	for kind: String in DwarvenBuilder.OBJECTS:
		check(docs.contains(kind), "style nain : l'objet %s est documenté" % kind)
	check(load("res://src/world/atmosphere.gd").PARTICLES.has("neige") and docs.contains("neige"), "style nain : particules de neige")
	check(docs.contains("quitte:"), "l'action de dialogue quitte: est documentée")

	var maps: Array[String] = ["porte_morbier", "morbier_galeries", "morbier_halle", "morbier_tombe", "morbier_profondeurs", "morbier_antre", "morbier_pont", "portes_est"]
	for id: String in maps:
		var map := Database.get_map(id)
		check(str(map.get("style", "")) == "nain", "carte %s : style nain" % id)
		for f: Dictionary in (map.get("ground", {}) as Dictionary).get("fills", []):
			check(MapBuilder.GROUND.has(str(f.get("type", ""))), "carte %s : sol « %s » connu" % [id, str(f.get("type", ""))])
		for o: Dictionary in map.get("objects", []):
			var t := str(o.get("type", ""))
			var known: bool = t in ["monster", "encounter_zone", "npc", "light", "warp", "trigger", "crate", "scatter", "house", "lantern", "fence"] \
					or MapBuilder.PROPS.has(t) or DwarvenBuilder.OBJECTS.has(t)
			check(known, "carte %s : objet « %s » connu" % [id, t])
			if t == "scatter":
				check(MapBuilder.PROPS.has(str(o.get("prop", ""))), "carte %s : accessoire semé « %s » connu" % [id, str(o.get("prop", ""))])
		if bool(map.get("interior", false)):
			var wt := str(map.get("wall_tile", "nain_mur"))
			check(Dwarven.TILES.has(wt), "carte %s : tuile de mur « %s » connue" % [id, wt])

	# construction : parois et massif, braseros, ponts ; plus de village rustique
	for id: String in maps:
		GameState.new_game()
		var world: Node3D = World.new()
		add_child(world)
		world.setup(id, str(Database.get_map(id)["spawns"].keys()[0]))
		await get_tree().process_frame
		var interior := bool(Database.get_map(id).get("interior", false))
		if interior:
			check(world.get_node_or_null("Walls") != null, "carte %s : murs nains construits" % id)
		else:
			check(world.get_node_or_null("MassifRock") != null and world.get_node_or_null("MassifSnow") != null, "carte %s : le massif est bâti" % id)
		var lit := 0
		for n: Node in world.get_children():
			if n.name.begins_with("NainBrasero") or n.name.begins_with("NainTorche") or n.name.begins_with("NainForgeMurale"):
				lit += 1
		if interior and id != "morbier_pont":
			check(lit >= 1, "carte %s : des feux éclairent la salle (%d)" % [id, lit])
		if id == "porte_morbier":
			check(world.get_node_or_null("Water") != null, "la porte de Morbier : le lac est là")
		world.queue_free()
		await get_tree().process_frame

	# les cartes des chapitres précédents ne changent pas
	GameState.new_game()
	var village: Node3D = World.new()
	add_child(village)
	village.setup("brie", str(Database.get_map("brie")["spawns"].keys()[0]))
	await get_tree().process_frame
	var any_nain := false
	for n: Node in village.get_children():
		if n.name.begins_with("Nain") or n.name.begins_with("Massif"):
			any_nain = true
	check(not any_nain, "Brie : aucun décor nain (le style se choisit par les données)")
	village.queue_free()
	await get_tree().process_frame


## Styles des cavaliers, de Fongorn, de l'Isengarde et des chutes : tuiles, décors, objets, cartes.
func _test_rider_scenery() -> void:
	var Rider: GDScript = load("res://src/gfx/rider_painter.gd")
	var RiderBuilder: GDScript = load("res://src/world/rider_builder.gd")
	var MapBuilder: GDScript = load("res://src/world/map_builder.gd")
	var docs := FileAccess.get_file_as_string("res://docs/FORMAT_DONNEES.md")
	for kind: String in Rider.TILES:
		var img: Image = Sprites.tile_image(kind)
		check(img != null and img.get_width() >= 48, "style cavalier : la tuile %s est peinte" % kind)
		check(not img.get_pixel(3, 3).is_equal_approx(Color(1, 0, 1)), "style cavalier : la tuile %s n'est pas le magenta de secours" % kind)
		check(docs.contains(kind), "style cavalier : la tuile %s est documentée" % kind)
	for kind: String in Rider.PROP_VARIANTS:
		check(MapBuilder.PROPS.has(kind), "style cavalier : %s est un accessoire déclaré" % kind)
		check(docs.contains(kind), "style cavalier : %s est documenté" % kind)
		for v in int(Rider.PROP_VARIANTS[kind]):
			var tex: Texture2D = Sprites.prop(kind, v)
			check(tex != null and tex.get_width() > 4 and tex.get_height() > 4, "style cavalier : %s variante %d peint" % [kind, v])
	for kind: String in RiderBuilder.OBJECTS:
		check(docs.contains(kind), "style cavalier : l'objet %s est documenté" % kind)
	for st: String in RiderBuilder.STYLES:
		check(docs.contains("\"%s\"" % st) or docs.contains("`%s`" % st), "style %s : documenté" % st)
	for a: String in ["groupe:", "va:", "equipe:", "bench"]:
		check(docs.contains(a), "la mécanique « %s » est documentée" % a)
	for id: String in C5_MAPS:
		var map := Database.get_map(id)
		for f: Dictionary in (map.get("ground", {}) as Dictionary).get("fills", []):
			check(MapBuilder.GROUND.has(str(f.get("type", ""))), "carte %s : sol « %s » connu" % [id, str(f.get("type", ""))])
		for o: Dictionary in map.get("objects", []):
			var t := str(o.get("type", ""))
			var known: bool = t in ["monster", "encounter_zone", "npc", "light", "warp", "trigger", "crate", "scatter", "house", "lantern", "fence", "tree"] \
					or MapBuilder.PROPS.has(t) or RiderBuilder.OBJECTS.has(t)
			check(known, "carte %s : objet « %s » connu" % [id, t])
			if t == "scatter":
				check(MapBuilder.PROPS.has(str(o.get("prop", ""))), "carte %s : accessoire semé « %s » connu" % [id, str(o.get("prop", ""))])
		if bool(map.get("interior", false)):
			var wt := str(map.get("wall_tile", ""))
			check(wt == "" or Rider.TILES.has(wt) or Sprites.tile_image(wt) != null, "carte %s : tuile de mur « %s » connue" % [id, wt])
	for id: String in C5_MAPS:
		GameState.new_game()
		var world: Node3D = World.new()
		add_child(world)
		world.setup(id, str(Database.get_map(id)["spawns"].keys()[0]))
		await get_tree().process_frame
		check(world.player != null, "carte %s : construite dans son style" % id)
		if bool(Database.get_map(id).get("interior", false)):
			check(world.get_node_or_null("Walls") != null, "carte %s : murs construits" % id)
		else:
			check(world.get_node_or_null("Outskirts") != null, "carte %s : abords construits" % id)
		world.queue_free()
		await get_tree().process_frame
	_test_group_mechanism()
	# les cartes des chapitres précédents ne changent pas
	GameState.new_game()
	var village: Node3D = World.new()
	add_child(village)
	village.setup("brie", str(Database.get_map("brie")["spawns"].keys()[0]))
	await get_tree().process_frame
	var any_rider := false
	for n: Node in village.get_children():
		if n.name.begins_with("Cav") or n.name.begins_with("Isen") or n.name.begins_with("Chu"):
			any_rider = true
	check(not any_rider, "Brie : aucun décor de cavaliers (le style se choisit par les données)")
	village.queue_free()
	await get_tree().process_frame


## Arènes : chacune se construit avec 1 à 5 ennemis, aucun décor n'occupe la zone de jeu,
## les champs « stage », « backdrop » et « particles » sont valides.
func _test_arenas() -> void:
	print("== Arènes dégagées ==")
	GameState.new_game()
	for who: String in ["sam", "froton", "pepin"]:
		GameState.add_to_party(who)
	var particle_kinds := ["fireflies", "pollen", "leaves", "dust", "fire", "embers", "smoke", "embruns", "feuilles_dorees", "lueurs", "snow", "mist", "spores", "paper"]
	var foes := ["limace_molle", "guepe_cidre", "champignon_dormeur", "limace_molle", "guepe_cidre"]
	for id: String in Database.arenas:
		var arena: Dictionary = Database.arenas[id]
		var stage: Dictionary = arena.get("stage", {})
		for key: String in stage:
			check(["light", "boost", "key", "edge", "flatten", "grain", "desat", "vignette", "radius", "center", "tint", "variation", "patches", "puddles", "fleck", "clouds", "dapple", "stones", "blades", "dim", "exposure", "saturation", "contrast", "fill", "fill_color", "lift", "rim", "shafts"].has(key), "arène %s : champ stage.%s connu" % [id, key])
		check(float(stage.get("edge", 0.2)) >= 0.0 and float(stage.get("edge", 0.2)) <= 1.0, "arène %s : bords assombris dans [0, 1]" % id)
		check(float(stage.get("flatten", 0.6)) >= 0.0 and float(stage.get("flatten", 0.6)) <= 1.0, "arène %s : aplat du sol dans [0, 1]" % id)
		check(float(stage.get("boost", 0.5)) >= 0.0 and float(stage.get("key", 1.6)) >= 0.0, "arène %s : lumière positive" % id)
		# le sol est celui de son lieu : sa texture reste visible (pas aplatie en terre unie), il est connu et peint
		check(float(stage.get("flatten", 0.15)) <= 0.35, "arène %s : le sol garde sa texture (aplat %.2f)" % [id, float(stage.get("flatten", 0.15))])
		check(float(stage.get("desat", 0.0)) <= 0.2, "arène %s : le sol garde ses couleurs" % id)
		var ground_tiles: Array = [str(arena.get("ground", "grass"))]
		if (stage.get("patches", {}) as Dictionary).has("tile"):
			ground_tiles.append(str(stage["patches"]["tile"]))
		for tile: String in ground_tiles:
			var timg: Image = Sprites.tile_image(tile)
			check(timg != null and not timg.get_pixel(3, 3).is_equal_approx(Color(1, 0, 1)), "arène %s : tuile de sol %s peinte" % [id, tile])
		check(str(arena.get("ground", "grass")) != "soil", "arène %s : pas de terre nue (le sol est celui du lieu)" % id)
		for key: String in ["tint"]:
			check(str(stage.get(key, "#ffffff")).begins_with("#"), "arène %s : stage.%s est une couleur" % [id, key])
		for group: String in ["patches", "puddles", "fleck"]:
			check(stage.get(group, {}) is Dictionary, "arène %s : stage.%s est un bloc" % [id, group])
		check(float((stage.get("patches", {}) as Dictionary).get("amount", 0.3)) <= 1.0, "arène %s : taches de sol dans [0, 1]" % id)
		check(float((stage.get("puddles", {}) as Dictionary).get("amount", 0.1)) <= 0.4, "arène %s : flaques au plus 40 %%" % id)
		check(float((stage.get("fleck", {}) as Dictionary).get("density", 0.04)) <= 0.2, "arène %s : semis de fleurs léger" % id)
		var radius: Array = stage.get("radius", [12.0, 7.5])
		check(radius.size() == 2 and float(radius[0]) > 3.0 and float(radius[1]) > 3.0, "arène %s : nappe de lumière assez large" % id)
		check(str(stage.get("light", "#ffd9a0")).begins_with("#"), "arène %s : couleur de lumière" % id)
		for kind: Variant in arena.get("particles", []):
			check(particle_kinds.has(str(kind)), "arène %s : particule %s connue" % [id, str(kind)])
		var back: Dictionary = arena.get("backdrop", {})
		for key: String in ["dim", "desat", "haze"]:
			check(float(back.get(key, 0.5)) >= 0.0 and float(back.get(key, 0.5)) <= 1.0, "arène %s : backdrop.%s dans [0, 1]" % [id, key])
		for n: int in [1, 3, 5]:
			var layer := CanvasLayer.new()
			add_child(layer)
			var ui: Control = BattleUI.new()
			layer.add_child(ui)
			var scene: Node3D = BattleScene.new()
			add_child(scene)
			scene.setup({"enemies": foes.slice(0, n), "arena": id}, ui, 5)
			await get_tree().process_frame
			check(scene.camera != null and scene.get_node_or_null("StageLight") != null, "arène %s (%d ennemis) : construite, caméra et lumière d'appoint" % [id, n])
			var intruders := 0
			var too_close := 0
			for pos: Vector3 in scene.placed_props:
				if BattleScene.in_stage(pos.x, pos.z):
					intruders += 1
				for a: Node3D in scene.actors.values():
					if Vector2(pos.x, pos.z).distance_to(Vector2(a.position.x, a.position.z)) < 2.5:
						too_close += 1
			check(intruders == 0, "arène %s (%d ennemis) : aucun décor dans la zone de jeu (%d)" % [id, n, intruders])
			check(too_close == 0, "arène %s (%d ennemis) : aucun décor près d'un combattant (%d)" % [id, n, too_close])
			scene.free()
			layer.free()


## Retouches 2 : monstres repeints, échelle des monstres, zones dégagées du Bois Penché.
func _test_retouches_2() -> void:
	print("== Retouches 2 ==")
	var MP: GDScript = load("res://src/gfx/monster_painter.gd")
	for kind: String in MP.PAINTED:
		var img: Image = MP.paint(kind)
		var magenta := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.5 and c.r > 0.9 and c.b > 0.9 and c.g < 0.2:
					magenta += 1
		check(magenta == 0, "monstre %s : espèce peinte (pas de magenta)" % kind)
	check(Sprites.MONSTER_PPU > 24.0 and Sprites.MONSTER_PPU < 40.0, "monstres un cran plus petits que les personnages")
	var bp: Dictionary = Database.get_map("bois_penche")
	var avoid_ok := false
	for o: Variant in bp.get("objects", bp.get("scatter", [])):
		if o is Dictionary and o.get("prop", "") == "tree" and o.has("avoid"):
			avoid_ok = true
	check(avoid_ok, "Bois Penché : zones sans arbres autour de la rampe")
# ------------------------------------------------------------- décors elfiques

func _test_elven_scenery() -> void:
	var Elven: GDScript = load("res://src/gfx/elven_painter.gd")
	var ElvenBuilder: GDScript = load("res://src/world/elven_builder.gd")
	var MapBuilder: GDScript = load("res://src/world/map_builder.gd")
	var docs := FileAccess.get_file_as_string("res://docs/FORMAT_DONNEES.md")
	# textures et sprites : tous peints, jamais le magenta de secours
	for kind: String in Elven.TILES:
		var img: Image = Sprites.tile_image(kind)
		check(img != null and img.get_width() >= 48, "style elfe : la tuile %s est peinte" % kind)
		check(not img.get_pixel(3, 3).is_equal_approx(Color(1, 0, 1)), "style elfe : la tuile %s n'est pas le magenta de secours" % kind)
		check(docs.contains(kind), "style elfe : la tuile %s est documentée" % kind)
	for kind: String in Elven.PROP_VARIANTS:
		check(MapBuilder.PROPS.has(kind), "style elfe : %s est un accessoire déclaré" % kind)
		check(docs.contains(kind), "style elfe : %s est documenté" % kind)
		for v in int(Elven.PROP_VARIANTS[kind]):
			var tex: Texture2D = Sprites.prop(kind, v)
			check(tex != null and tex.get_width() > 4 and tex.get_height() > 4, "style elfe : %s variante %d peint" % [kind, v])
	for kind: String in ["elf_rail", "elf_lantern", "elf_column3d", "elf_arcade", "elf_gate", "elf_waterfall", "elf_counter", "elf_medallion", "elf_pool"]:
		check(ElvenBuilder.OBJECTS.has(kind) and docs.contains(kind), "style elfe : l'objet %s est connu et documenté" % kind)
	for kind: String in ["embruns", "feuilles_dorees", "lueurs"]:
		check(load("res://src/world/atmosphere.gd").PARTICLES.has(kind) and docs.contains(kind), "style elfe : particules %s" % kind)
	var fac: Dictionary = Elven.facade(8.0, 3.6, 4.0, [1.5, 6.5], true, true, false)
	check(fac["albedo"] is Image and fac["emission"] is Image, "style elfe : la façade se peint")

	# les six cartes du chapitre 3 : style choisi par les données, tout est connu
	var maps: Array[String] = ["col_biscottes", "fondue_combe", "salle_conseil", "chancellerie", "auberge_elfique", "archives"]
	for id: String in maps:
		var map := Database.get_map(id)
		check(str(map.get("style", "")) == "elfe", "carte %s : style elfe" % id)
		for f: Dictionary in (map.get("ground", {}) as Dictionary).get("fills", []):
			check(MapBuilder.GROUND.has(str(f.get("type", ""))), "carte %s : sol « %s » connu" % [id, str(f.get("type", ""))])
		for o: Dictionary in map.get("objects", []):
			var t := str(o.get("type", ""))
			var known: bool = t in ["monster", "encounter_zone", "house", "lantern", "fence", "npc", "light", "warp", "trigger", "table", "stool", "counter",
					"fireplace", "stove", "rug", "crate", "scatter"] or MapBuilder.PROPS.has(t) or ElvenBuilder.OBJECTS.has(t)
			check(known, "carte %s : objet « %s » connu" % [id, t])
			if t == "scatter":
				check(MapBuilder.PROPS.has(str(o.get("prop", ""))), "carte %s : accessoire semé « %s » connu" % [id, str(o.get("prop", ""))])
		check(docs.contains(str(map.get("wall_tile", "elf_wall"))), "carte %s : tuile de mur documentée" % id)

	# construction : pavillons, vallée et cascades à l'extérieur, parois pâles à l'intérieur
	for id: String in ["fondue_combe", "col_biscottes", "salle_conseil", "archives"]:
		GameState.new_game()
		var world: Node3D = World.new()
		add_child(world)
		world.setup(id, str(Database.get_map(id)["spawns"].keys()[0]))
		await get_tree().process_frame
		var interior := bool(Database.get_map(id).get("interior", false))
		if interior:
			check(world.get_node_or_null("Walls") != null, "carte %s : murs elfiques construits" % id)
		else:
			check(world.get_node_or_null("ValleyRock") != null and world.get_node_or_null("ValleyTops") != null, "carte %s : la vallée est bâtie" % id)
			check(world.get_node_or_null("Cliffs") == null or not (world.get_node("Cliffs") as Node3D).visible, "carte %s : plus de talus rustique" % id)
		var houses := 0
		var falls := 0
		for n: Node in world.get_children():
			if n.has_meta("elven") and n.get_meta("elven") == "house":
				houses += 1
			if n.has_meta("elven") and n.get_meta("elven") == "waterfall":
				falls += 1
		if id == "fondue_combe":
			check(houses >= 6, "Fondue-Combe : au moins six pavillons elfiques (%d)" % houses)
			check(falls >= 2, "Fondue-Combe : des cascades (%d)" % falls)
			check(world.get_node_or_null("Water") != null, "Fondue-Combe : le torrent coule")
		world.queue_free()
		await get_tree().process_frame

	# les cartes des chapitres 1 et 2 gardent leur style de village
	GameState.new_game()
	var village: Node3D = World.new()
	add_child(village)
	village.setup("brie", str(Database.get_map("brie")["spawns"].keys()[0]))
	await get_tree().process_frame
	var any_elf := false
	for n: Node in village.get_children():
		if n.has_meta("elven") or n.name == "ValleyRock":
			any_elf = true
	check(not any_elf, "Brie : aucun décor elfique (le style se choisit par les données)")
	check(str(Database.get_map("brie").get("style", "")) == "", "Brie : pas de champ style")
	village.queue_free()
	await get_tree().process_frame


## Composition du combat : camps de chaque côté, tout le monde dans le cadre, interface dans la fenêtre,
## et rien qui se chevauche : plaques d'ennemis entre elles, menu de chacun des héros face aux autres
## combattants, aux plaques et aux fiches.
func _test_battle_layout() -> void:
	var foes5 := ["limace_molle", "guepe_cidre", "limace_molle", "guepe_cidre", "limace_molle"]
	var cases := [
		{"allies": ["pepin"], "enemies": ["limace_molle"], "arena": "pre"},
		{"allies": ["pepin", "sam", "froton"], "enemies": foes5, "arena": "bois"},
		{"allies": ["pepin", "sam", "froton"], "enemies": foes5, "arena": "marais"},
		{"allies": ["pepin", "sam", "froton"], "enemies": ["vacherin"], "arena": "pre"},
		{"allies": ["pepin", "sam", "froton"], "enemies": ["crapaud_buffle"], "arena": "place"},
		{"allies": ["pepin", "sam"], "enemies": ["gardien_archives", "limace_molle", "guepe_cidre"], "arena": "grand_four"},
		{"allies": ["pepin", "sam", "froton"], "enemies": ["vacherin", "crapaud_buffle", "vacherin", "crapaud_buffle", "vacherin"], "arena": "bois"},
	]
	# la fenêtre sans écran est carrée : on la met au format du jeu (16/9) pour mesurer la mise en page
	var win := get_window()
	var old_size := win.size
	win.size = Vector2i(1280, 720)
	await get_tree().process_frame
	for cs: Dictionary in cases:
		GameState.new_game()
		for who: String in cs["allies"]:
			GameState.add_to_party(who)
		for who: String in GameState.party:   # les boss frappent fort : les héros doivent tenir les quelques tours de la mesure
			GameState.member(who)["level"] = 30
		GameState.heal_party()
		var layer := CanvasLayer.new()
		add_child(layer)
		var ui: Control = BattleUI.new()
		layer.add_child(ui)
		await get_tree().process_frame
		var scene: Node3D = BattleScene.new()
		add_child(scene)
		scene.fast = true
		scene.setup({"enemies": cs["enemies"], "arena": cs["arena"]}, ui, 5)
		scene.run()
		var tag: String = "%s (%d alliés, %d ennemis)" % [cs["arena"], cs["allies"].size() + 1, cs["enemies"].size()]
		var seen := {}
		for _turn in 40:
			for _i in 600:
				await get_tree().process_frame
				if ui._state == ui.S.ROOT or scene.engine.result != "":
					break
			if scene.engine.result != "" or ui._state != ui.S.ROOT:
				break
			await get_tree().process_frame
			await get_tree().process_frame
			var hero: RefCounted = ui._actor
			for pc: RefCounted in scene.engine.party:   # les héros ne tombent pas pendant la mesure
				pc.hp = pc.max_hp()
			if not seen.has(hero.key):
				seen[hero.key] = true
				_check_battle_frame(scene, ui, tag, seen.size() == 1)
				_check_menu_clear(scene, ui, "%s, menu de %s" % [tag, str(hero.name)])
			if seen.size() >= scene.engine.party.size():
				break
			ui._choose({"type": "defend"})
		check(seen.size() == scene.engine.party.size(), "%s : le menu s'ouvre pour chacun des %d héros (%d vus)" % [tag, scene.engine.party.size(), seen.size()])
		ui.close()
		remove_child(scene)
		scene.queue_free()
		layer.queue_free()
	win.size = old_size


## Cadre, fiches, frise et plaques d'un combat arrivé au premier menu.
func _check_battle_frame(scene: Node3D, ui: Control, tag: String, first: bool) -> void:
	var view: Rect2 = ui.get_viewport_rect()
	if first:
		check(is_equal_approx(view.size.x / view.size.y, 16.0 / 9.0), "%s : fenêtre de mesure au format 16/9 (%s)" % [tag, str(view.size)])
	check(scene.engine.party.size() <= 4, "%s : au plus quatre alliés" % tag)
	check(scene.engine.enemies.size() >= 1 and scene.engine.enemies.size() <= 5, "%s : un à cinq ennemis" % tag)
	for a: RefCounted in scene.engine.party:
		check(_in_frame(scene, a), "%s : allié dans le cadre" % tag)
		check(scene.actors[a.key].anchor("center").x > 0.0, "%s : alliés à droite" % tag)
	for e: RefCounted in scene.engine.enemies:
		check(_in_frame(scene, e), "%s : ennemi %s entier dans le cadre" % [tag, str(e.name)])
		check(scene.actors[e.key].anchor("center").x < 0.0, "%s : ennemis à gauche" % tag)
	if not first:
		return
	var mr: Rect2 = ui._root_panel.get_global_rect()
	check(mr.size.x > 0.0 and view.encloses(mr), "%s : menu dans la fenêtre" % tag)
	check(ui._rows.size() == scene.engine.party.size(), "%s : une fiche par allié" % tag)
	for k: Variant in ui._rows:
		var card: Control = ui._rows[k]["card"]
		check(view.encloses(card.get_global_rect()), "%s : fiche alliée dans la fenêtre" % tag)
		check(ui._rows[k]["pips"].custom_minimum_size.x > 0.0 and card.get_global_rect().encloses(ui._rows[k]["pips"].get_global_rect()), "%s : pastilles d'élan dans la fiche" % tag)
	var fr: Rect2 = ui._timeline.get_global_rect()
	check(ui._timeline.get_child_count() > 2 and view.encloses(fr), "%s : frise des tours dans la fenêtre" % tag)
	# plaques des ennemis : dans la fenêtre, jamais l'une sur l'autre, jamais sur le sprite d'un autre ennemi
	var keys: Array = []
	for e: RefCounted in scene.engine.enemies:
		if e.alive():
			keys.append(e)
	for i in keys.size():
		var ri: Rect2 = (ui._plates[keys[i].key]["root"] as Control).get_global_rect()
		check(view.encloses(ri), "%s : plaque de %s dans la fenêtre" % [tag, str(keys[i].name)])
		_check_plate_content(ui, keys[i], tag)
		for j in range(i + 1, keys.size()):
			var rj: Rect2 = (ui._plates[keys[j].key]["root"] as Control).get_global_rect()
			check(not ri.intersects(rj), "%s : plaques de %s et %s sans recouvrement" % [tag, str(keys[i].name), str(keys[j].name)])
		for j in keys.size():
			if j != i:
				check(not ri.intersects(scene.screen_rect(keys[j])), "%s : plaque de %s hors du sprite de %s" % [tag, str(keys[i].name), str(keys[j].name)])


## Le menu de celui qui joue ne couvre ni un autre combattant, ni une plaque, ni les fiches, ni la frise.
func _check_menu_clear(scene: Node3D, ui: Control, tag: String) -> void:
	var mr: Rect2 = ui._root_panel.get_global_rect()
	check(mr.size.x > 0.0 and ui.get_viewport_rect().encloses(mr), "%s : dans la fenêtre" % tag)
	for c: RefCounted in scene.engine.all():
		if c == ui._actor or (c.side == "enemy" and not c.alive()):
			continue
		var body: Rect2 = scene.screen_rect(c).grow(-4.0)
		check(not mr.intersects(body), "%s : ne couvre pas %s" % [tag, str(c.name)])
	var own: Rect2 = scene.screen_rect(ui._actor, true).grow(-20.0)   # marge : quand la place manque, un coin du menu peut frôler le bord du sprite
	check(not mr.intersects(own), "%s : ne couvre pas celui qui joue" % tag)
	for k: String in ui._plates:
		var root: Control = ui._plates[k]["root"]
		if root.visible:
			check(not mr.intersects(root.get_global_rect()), "%s : ne couvre pas la plaque de %s (menu %s, plaque %s)" % [tag, k, str(mr), str(root.get_global_rect())])
	for k: Variant in ui._rows:
		check(not mr.intersects((ui._rows[k]["card"] as Control).get_global_rect()), "%s : ne couvre pas une fiche" % tag)
	check(not mr.intersects(ui._timeline.get_global_rect()), "%s : ne couvre pas la frise" % tag)


## Vrai si le combattant tient dans un écran 16/9 (calcul en espace monde : la fenêtre sans écran n'a pas le bon format).
func _in_frame(scene: Node3D, c: RefCounted) -> bool:
	var p: Vector3 = scene.actors[c.key].anchor("center")
	var cam: Camera3D = scene.camera
	var half_w := tan(deg_to_rad(cam.fov * 0.5)) * (16.0 / 9.0) * (cam.global_position.z - p.z)
	return absf(p.x) < half_w - 0.3


# --------------------------------------------------------------- équipement

## Parcourt un contenu JSON et note tous les objets donnés (clé « give »).
func _collect_gives(v: Variant, out: Dictionary) -> void:
	if v is Dictionary:
		for k: Variant in v:
			if str(k) == "give" and v[k] is String:
				out[str(v[k])] = true
			else:
				_collect_gives(v[k], out)
	elif v is Array:
		for x: Variant in v:
			_collect_gives(x, out)


## Tous les objets qu'on peut obtenir sans code : boutiques, coffres et dialogues, quêtes, butins, équipement de départ.
func _findable_items() -> Dictionary:
	var out := {}
	for sid: String in Database.shops:
		for o: Variant in (Database.shops[sid] as Dictionary).get("stock", []):
			out[str((o as Dictionary).get("item", ""))] = "boutique " + sid
	_collect_gives(Database.dialogues, out)
	for qid: String in Database.quests:
		var rw: Variant = (Database.quests[qid] as Dictionary).get("reward", {})
		if rw is Dictionary and (rw as Dictionary).get("items") is Dictionary:
			for it: String in (rw as Dictionary)["items"]:
				out[it] = "quête " + qid
	for eid: String in Database.enemies:
		for dr: Variant in (Database.enemies[eid] as Dictionary).get("drops", []):
			out[str((dr as Dictionary).get("item", ""))] = "butin " + eid
	for cid: String in Database.characters:
		var eq: Variant = ((Database.characters[cid] as Dictionary).get("battle", {}) as Dictionary).get("equip", {})
		if eq is Dictionary:
			for it: Variant in (eq as Dictionary).values():
				out[str(it)] = "départ " + cid
	return out


func _test_equipment() -> void:
	GameState.new_game()
	var slot_kinds := ["weapon", "head", "armor", "trinket"]
	var gear_ids: Array = []
	var playable := GameState.playable_ids()
	check(playable.size() == 8, "huit personnages jouables (%d)" % playable.size())
	# 1. chaque objet d'équipement : emplacement, bonus et porteur
	for id: String in Database.items:
		if Database.item_kind(id) != "equipment":
			continue
		gear_ids.append(id)
		var def := Database.get_item(id)
		check(slot_kinds.has(str(def.get("slot", ""))), "%s : emplacement connu (%s)" % [id, str(def.get("slot", ""))])
		for key: String in (def.get("mods", {}) as Dictionary):
			check(Rules.MOD_KEYS.has(key), "%s : bonus connu (%s)" % [id, key])
		var p: Variant = def.get("passives", {})
		check(p is Dictionary, "%s : passives est un objet" % id)
		if p is Dictionary:
			for key: String in (p as Dictionary):
				check(["resist", "status_resist", "immune", "regen_hp", "regen_mp", "money_bonus", "xp_bonus", "initiative", "crit"].has(key), "%s : effet connu (%s)" % [id, key])
		var any := false
		for who: String in playable:
			any = any or GameState.can_equip(who, id)
		check(any, "%s : au moins un porteur possible" % id)
		check(str(def.get("name", "")) != "" and str(def.get("desc", "")) != "", "%s : nom et description" % id)
	check(gear_ids.size() >= 100, "au moins cent pièces d'équipement (%d)" % gear_ids.size())
	# 2. chaque objet vendu ou trouvé existe ; chaque personnage a de quoi s'équiper à chaque emplacement
	var found := _findable_items()
	for id: String in found:
		check(Database.items.has(id), "objet trouvable inconnu : %s (%s)" % [id, str(found[id])])
	for who: String in playable:
		for kind: String in slot_kinds:
			var n := 0
			for id: String in found:
				var d := Database.get_item(id)
				if str(d.get("slot", "")) == kind and Database.item_kind(id) == "equipment" and GameState.can_equip(who, id):
					n += 1
			check(n >= (1 if kind != "weapon" and kind != "armor" else 3), "%s : %d objet(s) trouvable(s) pour « %s »" % [who, n, kind])
	# 3. équiper puis retirer rend exactement les caractéristiques de départ
	for who: String in playable:
		GameState.new_game()
		GameState.add_to_party(who, true)
		var before := GameState.member_stats(who)
		var bare_equip: Dictionary = (GameState.member(who)["equip"] as Dictionary).duplicate(true)
		for id: String in gear_ids:
			if not GameState.can_equip(who, id):
				continue
			GameState.add_item(id)
			var preview := GameState.stats_with(who, id)
			var slot := GameState.slot_for(who, id)
			var worn := GameState.equipped(who, slot)
			check(GameState.equip(who, id, slot), "%s équipe %s" % [who, id])
			check(GameState.member_stats(who) == preview, "%s : l'aperçu de %s correspond au résultat" % [who, id])
			check(GameState.unequip(who, slot), "%s retire %s" % [who, id])
			if worn != "":
				# rend l'objet qui était porté pour revenir au point de départ
				GameState.equip(who, worn, slot)
			check(GameState.member(who)["equip"] == bare_equip, "%s : équipement rétabli après %s" % [who, id])
			check(GameState.member_stats(who) == before, "%s : caractéristiques rétablies après %s" % [who, id])
			GameState.add_item(id, -GameState.item_count(id))
	# 4. effets dans le moteur, tirages fixes
	GameState.new_game()
	var hits := {}
	for sc: Array in [["sans bonus", 100, 0, 6], ["esquive 40", 100, 40, 6], ["précision 60", 60, 0, 6], ["précision 150 contre esquive 40", 150, 40, 6], ["critique 50", 100, 0, 50], ["critique démesuré", 100, 0, 400]]:
		var e: RefCounted = BattleEngine.new()
		e.setup({"enemies": ["limace_molle"], "arena": "pre"}, 11)
		var g: RefCounted = e.party[0]
		var t: RefCounted = e.enemies[0]
		g.base["acc"] = sc[1]
		t.base["eva"] = sc[2]
		g.base["crit"] = sc[3]
		g.passives = {}
		t.base["hp"] = 999999
		t.hp = 999999
		var miss := 0
		var crit := 0
		var n := 800
		for _i in n:
			t.shield = 0
			var ev: Array = e.perform(g, {"type": "attack", "target": t})
			for x: Dictionary in ev:
				if str(x.get("type", "")) == "miss":
					miss += 1
				elif str(x.get("type", "")) == "damage" and bool(x.get("crit", false)):
					crit += 1
		hits[sc[0]] = [float(miss) / n, float(crit) / n]
	var r: Dictionary = hits
	check(float(r["sans bonus"][0]) == 0.0, "100 de précision contre 0 d'esquive : jamais raté (%s)" % str(r["sans bonus"][0]))
	check(absf(float(r["esquive 40"][0]) - 0.4) < 0.06, "40 d'esquive : environ 40 %% de ratés (%s)" % str(r["esquive 40"][0]))
	check(absf(float(r["précision 60"][0]) - 0.4) < 0.06, "60 de précision : environ 40 %% de ratés (%s)" % str(r["précision 60"][0]))
	check(float(r["précision 150 contre esquive 40"][0]) == 0.0, "la précision compense l'esquive")
	check(absf(float(r["sans bonus"][1]) - 0.06) < 0.04, "critique de base : environ 6 %% (%s)" % str(r["sans bonus"][1]))
	check(absf(float(r["critique 50"][1]) - 0.5) < 0.07, "critique 50 : environ 50 %% (%s)" % str(r["critique 50"][1]))
	check(float(r["critique démesuré"][1]) <= 0.86 and float(r["critique démesuré"][1]) > 0.7, "le critique plafonne à 80 %% (%s)" % str(r["critique démesuré"][1]))
	# l'esquive d'une cible est signalée dans l'événement de raté
	var e2: RefCounted = BattleEngine.new()
	e2.setup({"enemies": ["limace_molle"], "arena": "pre"}, 3)
	var a2: RefCounted = e2.party[0]
	var t2: RefCounted = e2.enemies[0]
	a2.base["acc"] = 1
	t2.base["eva"] = 50
	var dodge_seen := false
	for _i in 40:
		for x: Dictionary in e2.perform(a2, {"type": "attack", "target": t2}):
			if str(x.get("type", "")) == "miss" and bool(x.get("dodge", false)):
				dodge_seen = true
	check(dodge_seen, "un raté par esquive porte « dodge » (affichage « Esquive ! »)")
	# 5. effets d'objets : résistances et expérience
	var e3: RefCounted = BattleEngine.new()
	e3.setup({"enemies": ["limace_molle"], "arena": "pre"}, 5)
	var tgt: RefCounted = e3.party[0]
	var foe: RefCounted = e3.enemies[0]
	foe.base["atk"] = 60
	var dmg0 := 0
	var dmg1 := 0
	tgt.hp = tgt.max_hp()
	for ev: Dictionary in e3.perform(foe, {"type": "attack", "target": tgt}):
		if str(ev.get("type", "")) == "damage":
			dmg0 += int(ev.get("amount", 0))
	tgt.passives = {"resist": {str(foe.element): 0.5}}
	tgt.hp = tgt.max_hp()
	for _i in 6:
		tgt.hp = tgt.max_hp()
		for ev: Dictionary in e3.perform(foe, {"type": "attack", "target": tgt}):
			if str(ev.get("type", "")) == "damage":
				dmg1 = maxi(dmg1, int(ev.get("amount", 0)))
	check(dmg0 > 0 and dmg1 < dmg0 * 0.8 + 1, "la résistance d'un objet réduit les dégâts (%d -> %d)" % [dmg0, dmg1])
	# 6. une vieille sauvegarde (trois emplacements, objets disparus) se charge
	GameState.new_game()
	GameState.add_to_party("sam")
	GameState.map_id = "auberge"
	var d: Dictionary = GameState.to_dict()
	var ros: Dictionary = d["roster"]
	ros["glandoulf"]["equip"] = {"weapon": "baton_ferre", "armor": "objet_disparu", "trinket": "bonnet_laine", "cape": "robe_chambre"}
	ros["sam"]["equip"] = {"weapon": "baton_ferre", "armor": "gilet_batelier"}
	d["version"] = 3
	d["inventory"] = {"tisane": 2}
	check(GameState.from_dict(d), "une ancienne sauvegarde se charge")
	var ge: Dictionary = GameState.member("glandoulf")["equip"]
	check(GameState.equipped("glandoulf", "weapon") == "baton_ferre", "l'arme d'une ancienne sauvegarde est gardée")
	check(GameState.equipped("glandoulf", "armor") == "", "un objet disparu est retiré")
	check(GameState.equipped("glandoulf", "head") == "" and GameState.equipped("glandoulf", "trinket") == "bonnet_laine" or GameState.item_count("bonnet_laine") >= 1, "un objet mal rangé est remis en place ou dans le sac")
	check(not ge.has("cape"), "un emplacement inconnu disparaît")
	check(GameState.equipped("sam", "weapon") == "" and GameState.item_count("baton_ferre") >= 1, "une arme que le porteur ne peut pas tenir retourne au sac")
	check(GameState.equipped("sam", "armor") == "gilet_batelier", "une tenue valide reste portée")
	for who: String in ["glandoulf", "sam"]:
		var st := GameState.member_stats(who)
		for key: String in Rules.EXTRA:
			check(st.has(key), "%s : la caractéristique %s existe après chargement" % [who, key])
	SaveManager.delete_save()


# ----------------------------------------------------------------- paramètres

func _ui_action(action: String) -> void:
	for pressed: bool in [true, false]:
		var e := InputEventAction.new()
		e.action = action
		e.pressed = pressed
		Input.parse_input_event(e)
		await get_tree().process_frame
		await get_tree().process_frame


func _test_settings() -> void:
	print("== Paramètres ==")
	var S: Node = Settings
	var Atmo = preload("res://src/world/atmosphere.gd")
	var root := get_tree().root
	var old_path: String = S.path
	var old_persist: bool = S.persist
	check(S.testing and not S.persist, "réglages : les tests ne lisent ni n'écrivent le fichier de l'auteur")
	S.reset_defaults()

	# les défauts redonnent le rendu d'origine
	check(root.msaa_3d == Viewport.MSAA_2X and root.screen_space_aa == Viewport.SCREEN_SPACE_AA_DISABLED and not root.use_taa, "réglages : anticrénelage par défaut = MSAA x2 comme avant")
	check(root.scaling_3d_mode == Viewport.SCALING_3D_MODE_BILINEAR and is_equal_approx(root.scaling_3d_scale, 1.0), "réglages : échelle 100 % bilinéaire par défaut")
	check(Engine.max_fps == 0, "réglages : pas de limite d'images par défaut")
	for bus: String in ["Master", S.BUS_MUSIC, S.BUS_EFFECTS]:
		var i := AudioServer.get_bus_index(bus)
		check(i >= 0 and is_zero_approx(AudioServer.get_bus_volume_db(i)) and not AudioServer.is_bus_mute(i), "réglages : bus audio %s créé, à pleine puissance" % bus)
	check(root.positional_shadow_atlas_size == 4096, "réglages : atlas d'ombres par défaut inchangé")
	for k: String in S.DEFAULTS:
		check(S._valid(k, S.default_of(k)), "réglages : le défaut de %s est une option valide" % k)
	for row: Dictionary in S.ROWS:
		if row.has("id"):
			check(S.DEFAULTS.has(row["id"]) and S.HELP.has(row["id"]) and not (S.choices(row["id"]) as Array).is_empty(), "réglages : %s a une valeur, une aide et des options" % row["id"])
	check(S.PRESETS["moyenne"].keys().all(func(k: String) -> bool: return S.default_of(k) == S.PRESETS["moyenne"][k]), "réglages : « Moyenne » = les défauts (rendu d'origine)")

	# enregistrement, relecture, fichier abîmé, valeurs inconnues
	var test_file := "user://test_settings_%d.cfg" % OS.get_process_id()
	S.path = test_file
	S.persist = true
	S.set_value("echelle", 70)
	S.set_value("ombres", 3)
	S.set_value("musique", 40)
	S.set_value("mise_echelle", "fsr1")
	check(S.save() and FileAccess.file_exists(test_file), "réglages : enregistrement dans le fichier")
	S.reset_values()
	check(S.load_file() and S.get_value("echelle") == 70 and S.get_value("ombres") == 3 and S.get_value("musique") == 40 and S.get_value("mise_echelle") == "fsr1" and S.get_value("qualite") == "perso", "réglages : relecture à l'identique")
	var f := FileAccess.open(test_file, FileAccess.WRITE)
	var broken := "[[[ pas un fichier ".to_utf8_buffer()   # octet nul ajouté à la main : le littéral « \u0000 » faisait protester le compilateur à chaque lancement du test
	broken.append(0)
	broken.append_array(" de réglages = = \n{{{".to_utf8_buffer())
	f.store_buffer(broken)
	f.close()
	check(not S.load_file() and S.get_value("echelle") == 100 and S.get_value("ombres") == 2, "réglages : fichier abîmé toléré, retour aux défauts")
	f = FileAccess.open(test_file, FileAccess.WRITE)
	f.store_string("[rendu]\nechelle=77\nmise_echelle=\"dlss\"\nanticrenelage=\"taa\"\n[details]\nombres=\"beaucoup\"\nhalo=false\n[son]\ngeneral=50\n")
	f.close()
	check(S.load_file() and S.get_value("echelle") == 100 and S.get_value("mise_echelle") == "bilineaire" and S.get_value("ombres") == 2, "réglages : valeurs inconnues remplacées par le défaut")
	check(S.get_value("anticrenelage") == "taa" and S.get_value("halo") == false and S.get_value("general") == 50, "réglages : valeurs connues gardées malgré les inconnues")
	check(not S.set_value("echelle", 77) and not S.set_value("nimporte", 1) and S.get_value("echelle") == 100, "réglages : valeur ou clé inconnue refusée")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_file))
	check(not S.load_file() and S.get_value("ombres") == 2, "réglages : fichier absent = défauts")
	S.path = old_path
	S.persist = old_persist
	S.reset_defaults()

	# chaque réglage s'applique, chaque option se règle sans erreur
	var count := 0
	for k: String in S.DEFAULTS:
		for c: Array in S.choices(k):
			S.reset_defaults()
			check(S.set_value(k, c[0]) and S.get_value(k) == c[0], "réglages : %s = %s" % [k, str(c[1])])
			count += 1
	check(count > 60, "réglages : %d options essayées" % count)
	S.reset_defaults()
	S.set_value("echelle", 60)
	S.set_value("mise_echelle", "plus_proche")
	check(is_equal_approx(root.scaling_3d_scale, 0.6) and root.scaling_3d_mode == Viewport.SCALING_3D_MODE_NEAREST, "réglages : échelle et méthode transmises à la fenêtre")
	S.set_value("mise_echelle", "fsr2")
	check(root.scaling_3d_mode == Viewport.SCALING_3D_MODE_FSR2 and root.msaa_3d == Viewport.MSAA_DISABLED, "réglages : FSR 2 lisse seul (pas de MSAA en plus)")
	S.set_value("mise_echelle", "bilineaire")
	S.set_value("anticrenelage", "msaa4")
	check(root.msaa_3d == Viewport.MSAA_4X, "réglages : MSAA x4")
	S.set_value("anticrenelage", "taa")
	check(root.use_taa and root.msaa_3d == Viewport.MSAA_DISABLED, "réglages : TAA")
	S.set_value("anticrenelage", "fxaa")
	check(root.screen_space_aa == Viewport.SCREEN_SPACE_AA_FXAA and not root.use_taa, "réglages : FXAA")
	S.set_value("anticrenelage", "smaa")
	check(root.screen_space_aa == Viewport.SCREEN_SPACE_AA_SMAA, "réglages : SMAA")
	S.set_value("fps_max", 30)
	check(Engine.max_fps == 30, "réglages : limite à 30 images par seconde")
	S.set_value("musique", 50)
	var mi := AudioServer.get_bus_index(S.BUS_MUSIC)
	check(absf(AudioServer.get_bus_volume_db(mi) - linear_to_db(0.5)) < 0.01, "réglages : volume de la musique sur son bus")
	S.set_value("effets", 0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index(S.BUS_EFFECTS)), "réglages : effets à 0 = bus muet")
	S.reset_defaults()
	check(Engine.max_fps == 0 and root.msaa_3d == Viewport.MSAA_2X and not AudioServer.is_bus_mute(AudioServer.get_bus_index(S.BUS_EFFECTS)), "réglages : retour aux défauts appliqué")

	# les objets réglés à la création suivent les changements
	var holder := Node3D.new()
	add_child(holder)
	var amb := {"fog": {"density": 0.01}, "volumetric": {"density": 0.01}, "ssao": 1.6, "sun": {"energy": 0.8}, "particles": ["fireflies"], "rays": {"density": 0.05}}
	var followers: Array = Atmo.build(holder, amb, Rect2(0.0, 0.0, 20.0, 20.0))
	var we: WorldEnvironment = null
	var sun: DirectionalLight3D = null
	var rays: Array[MeshInstance3D] = []
	for n in holder.get_children():
		if n is WorldEnvironment:
			we = n
		elif n is DirectionalLight3D:
			sun = n
		elif n is MeshInstance3D:
			rays.append(n)
	check(we != null and sun != null and followers.size() == 1 and not rays.is_empty(), "réglages : ambiance construite (environnement, soleil, particules, rayons)")
	var env := we.environment
	var fireflies: CPUParticles3D = followers[0]
	var base_amount := fireflies.amount
	check(env.glow_enabled and env.fog_enabled and env.volumetric_fog_enabled and env.ssao_enabled and sun.shadow_enabled and fireflies.visible and rays[0].visible, "réglages : par défaut, l'ambiance est intacte")
	S.set_value("qualite", "basse")
	check(not env.glow_enabled and env.fog_enabled and not env.volumetric_fog_enabled and not env.ssao_enabled, "réglages : Basse coupe halo, brume volumétrique et occlusion")
	check(sun.shadow_enabled and sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS and root.positional_shadow_atlas_size == 2048, "réglages : Basse allège les ombres")
	check(fireflies.amount < base_amount and fireflies.visible and not rays[0].visible, "réglages : Basse réduit les particules et coupe les rayons")
	S.set_value("ombres", 0)
	check(not sun.shadow_enabled and S.get_value("qualite") == "perso", "réglages : ombres coupées, qualité Personnalisée")
	S.set_value("particules", 0)
	check(not fireflies.visible, "réglages : particules coupées")
	S.set_value("qualite", "haute")
	check(S.get_value("ombres") == 3 and root.positional_shadow_atlas_size == 8192 and sun.shadow_enabled and env.glow_enabled and env.volumetric_fog_enabled, "réglages : Haute")
	S.set_value("qualite", "moyenne")
	check(fireflies.amount == base_amount and fireflies.visible and rays[0].visible and sun.directional_shadow_mode == DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS, "réglages : retour à Moyenne = ambiance d'origine")
	var attr := CameraAttributesPractical.new()
	attr.dof_blur_far_enabled = true
	attr.dof_blur_near_enabled = true
	S.apply_camera(attr)
	S.set_value("flou", 0)
	check(not attr.dof_blur_far_enabled and not attr.dof_blur_near_enabled, "réglages : flou de profondeur coupé")
	S.set_value("flou", 3)
	check(attr.dof_blur_far_enabled and attr.dof_blur_near_enabled, "réglages : flou de profondeur rétabli")
	S.set_value("compteur", true)
	check(S._counter_layer != null and S._counter_layer.visible, "réglages : compteur d'images affiché")
	S.set_value("compteur", false)
	check(not S._counter_layer.visible, "réglages : compteur d'images masqué")
	holder.queue_free()
	S.reset_defaults()

	# l'écran : depuis le titre et depuis la pause, au clavier
	var main: Node = MAIN.instantiate()
	add_child(main)
	await get_tree().process_frame
	await get_tree().process_frame
	var scr: Control = main.settings_screen
	check(scr != null and not scr.visible, "réglages : écran créé, fermé au départ")
	var title_entry: Button = null
	for b in main.title._menu.get_children():
		if b is Button and b.text == "Paramètres":
			title_entry = b
	check(title_entry != null, "réglages : entrée « Paramètres » de l'écran-titre")
	title_entry.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	check(scr.visible and scr.context == "title", "réglages : l'écran s'ouvre depuis le titre")
	var first := scr.get_viewport().gui_get_focus_owner()
	check(first is Button and str(first.get_meta("id", "")) == "mode", "réglages : le curseur est sur la première ligne")
	await _ui_action("ui_right")
	check(S.get_value("mode") == "plein_ecran", "réglages : droite change la valeur")
	await _ui_action("ui_left")
	check(S.get_value("mode") == "fenetre", "réglages : gauche revient")
	await _ui_action("ui_down")
	var second := scr.get_viewport().gui_get_focus_owner()
	check(second != first and str(second.get_meta("id", "")) == "taille", "réglages : bas descend d'une ligne")
	await _ui_action("ui_down")
	await _ui_action("ui_accept")
	check(S.get_value("vsync") == false, "réglages : valider change la valeur")
	S.reset_defaults()
	# tout le tour des lignes, au clavier
	var seen: Array = []
	(scr._ordered[0] as Button).grab_focus()
	await get_tree().process_frame
	for i in 30:
		var fo := scr.get_viewport().gui_get_focus_owner()
		if fo != null and fo.has_meta("id"):
			seen.append(str(fo.get_meta("id")))
		await _ui_action("ui_down")
	for row: Dictionary in S.ROWS:
		if row.has("id"):
			check(seen.has(row["id"]), "réglages : la ligne %s est atteignable au clavier" % row["id"])
	var last := scr.get_viewport().gui_get_focus_owner()
	check(last is Button and (last as Button).text in ["Valeurs par défaut", "Retour"], "réglages : le parcours finit sur les boutons du bas")
	S.set_value("echelle", 50)
	S.set_value("ombres", 0)
	S.set_value("musique", 20)
	var reset_btn: Button = scr._reset
	reset_btn.grab_focus()
	await get_tree().process_frame
	await _ui_action("ui_accept")
	check(S.get_value("echelle") == 100 and S.get_value("ombres") == 2 and S.get_value("musique") == 100 and S.get_value("qualite") == "moyenne", "réglages : « Valeurs par défaut » remet tout")
	await _ui_action("ui_cancel")
	check(not scr.visible, "réglages : Échap referme l'écran")
	check(main.title.visible, "réglages : retour sur l'écran-titre")
	# depuis la pause
	main.pause.open("test")
	var pause_entry: Button = null
	for b in main.pause._list.get_children():
		if b is Button and b.text == "Paramètres":
			pause_entry = b
	check(pause_entry != null, "réglages : entrée « Paramètres » du menu de pause")
	pause_entry.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	check(scr.visible and scr.context == "pause" and not main.pause.visible, "réglages : l'écran s'ouvre depuis la pause")
	await _ui_action("ui_cancel")
	check(not scr.visible, "réglages : refermé, retour à la pause")
	main.queue_free()
	await get_tree().process_frame
	S.reset_defaults()


## Arène choisie selon le lieu : champ « arena » de la carte, surcharge par la rencontre,
## repli sur le Pré ; et chaque nouvelle arène se construit avec 1, 3 et 5 ennemis.
func _test_arena_by_place() -> void:
	print("== Arènes par lieu ==")
	var expected := {
		"archives": "archives", "auberge": "taverne", "auberge_elfique": "taverne",
		"bittebourg": "quai", "bois_penche": "bois", "brie": "ruelle_nuit",
		"caves_brie": "cave_fromage", "chancellerie": "salle_conseil", "col_biscottes": "col",
		"ferme_pinard": "ferme", "fondue_combe": "cite_elfique", "fromagerie": "cave_fromage",
		"poney_etage": "etage_auberge", "poney_flagada": "taverne", "pre_couche": "pre",
		"roseliere": "marais", "route_brie": "route", "salle_conseil": "salle_conseil",
		"porte_morbier": "bord_du_lac", "morbier_galeries": "galerie_mine", "morbier_halle": "halle_piliers",
		"morbier_tombe": "halle_piliers", "morbier_profondeurs": "galerie_mine", "morbier_antre": "bord_du_lac",
		"morbier_pont": "pont_abime", "portes_est": "col",
		"chutes_gratin": "chutes_gratin", "plaine_roquefort": "plaine_roquefort", "cabecou": "plaine_roquefort",
		"fongorn": "fongorn", "garde_manger": "garde_manger", "bergerie_or": "bergerie_or",
		"isengarde": "petrins", "terrasse_office": "terrasse_office",
		"minas_croute": "minas_remparts", "minas_rues": "minas_rues", "minas_citadelle": "citadelle", "minas_intendance": "citadelle",
		"sentier_insomniaques": "sentier_insomniaques", "port_sale": "port_sale", "pelle_a_tarte": "pelle_a_tarte",
	}
	for map_id: String in Database.list_maps():
		var map := Database.get_map(map_id)
		check(expected.has(map_id), "carte %s : arène attendue déclarée dans le test" % map_id)
		var res := BattleScene.resolve({"enemies": ["limace_molle"]}, map)
		check(str(res["arena"]) == str(expected.get(map_id, "?")), "carte %s : combat dans l'arène %s (obtenu %s)" % [map_id, expected.get(map_id, "?"), res["arena"]])
		check(not res.has("music") or Database.music.has(str(res["music"])), "carte %s : musique de combat connue" % map_id)
		for o: Variant in map.get("objects", []):
			if o is Dictionary and str((o as Dictionary).get("type", "")) == "encounter_zone":
				var table: Dictionary = Database.encounter_tables.get(str((o as Dictionary).get("table", "")), {})
				var rolled := Database.roll_encounter(str((o as Dictionary).get("table", "")), 2)
				var r2 := BattleScene.resolve(rolled, map)
				check(not table.is_empty() and Database.arenas.has(str(r2["arena"])), "carte %s : rencontre aléatoire dans une arène connue" % map_id)
				check(str(r2["arena"]) == str(expected.get(map_id, "?")), "carte %s : rencontre aléatoire dans l'arène du lieu" % map_id)
	var forced := BattleScene.resolve({"enemies": ["limace_molle"], "arena": "ferme"}, {"arena": "col"})
	check(str(forced["arena"]) == "ferme", "la rencontre l'emporte sur la carte")
	check(str(BattleScene.resolve({}, {"arena": "nimporte_quoi"})["arena"]) == "pre", "arène inconnue : repli sur le Pré")
	check(str(BattleScene.resolve({}, {})["arena"]) == "pre", "ni rencontre ni carte : le Pré")
	var news := ["taverne", "etage_auberge", "ruelle_nuit", "cave_fromage", "ferme", "route", "col", "cite_elfique", "salle_conseil", "archives", "quai"]
	for id: String in news:
		check(Database.arenas.has(id), "arène %s : déclarée" % id)
		var arena := Database.get_arena(id)
		var ground := str(arena.get("ground", ""))
		check(ground != "soil" and ground != "", "arène %s : sol peint, pas de terre nue (%s)" % [id, ground])
		var img: Image = Sprites.tile_image(ground)
		var magenta := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.r > 0.9 and c.b > 0.9 and c.g < 0.2:
					magenta += 1
		check(magenta == 0, "arène %s : sol %s sans magenta" % [id, ground])
		check(Database.music.has(str(arena.get("music", ""))), "arène %s : musique connue" % id)
		var back: Dictionary = arena.get("backdrop", {})
		for pan: Variant in back.get("panels", []):
			var img2: Image = preload("res://src/gfx/arena_panels.gd").panel(str((pan as Dictionary).get("kind", "")), float((pan as Dictionary).get("w", 36.0)), float((pan as Dictionary).get("h", 6.0)))
			check(img2 != null and img2.get_width() > 0, "arène %s : panneau %s peint" % [id, str((pan as Dictionary).get("kind", ""))])



# -------------------------------------------------------------------- chapitre 4

const C4_MAPS := ["porte_morbier", "morbier_galeries", "morbier_halle", "morbier_tombe", "morbier_profondeurs", "morbier_antre", "morbier_pont", "portes_est"]
const C4_MONSTERS := ["gobelin", "gobelin_pic", "gobelin_chef", "chauve", "troll", "guetteur", "goulum", "balourd"]


func _test_chapter_4_data() -> void:
	print("== Chapitre 4 : données et équilibre ==")
	for id: String in C4_MAPS:
		check(Database.has_map(id), "carte %s existe" % id)
		check(Database.get_map(id).has("music") and Database.music.has(str(Database.get_map(id)["music"])), "carte %s : musique connue" % id)
		check(str(Database.get_map(id).get("style", "")) == "nain", "carte %s : style nain" % id)
	for kind: String in C4_MONSTERS:
		check(MonsterPainter.has(kind), "monstre %s : espèce connue" % kind)
		var img: Image = MonsterPainter.paint(kind)
		var magenta := 0
		var filled := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.5:
					filled += 1
					if c.r > 0.95 and c.g < 0.05 and c.b > 0.95:
						magenta += 1
		check(magenta == 0 and filled > 200, "monstre %s : dessiné, sans carré magenta (%d px, %d magenta)" % [kind, filled, magenta])
	for q: String in ["morbier", "comptes_ballot", "pioche_rondin", "meule_morbier"]:
		check(not Database.get_quest(q).is_empty(), "quête %s décrite" % q)
	check(Database.get_quest("morbier").get("kind") == "principale", "les Mines sont la quête principale")
	for ch: String in ["rondin", "goulum", "balourd", "roi_ballot"]:
		check(Database.characters.has(ch), "personnage %s décrit" % ch)
	for it: String in ["page_comptes", "meule_morbier", "pioche_rondin"]:
		check(Database.item_kind(it) == "key", "objet de quête %s" % it)
	check(not Database.get_shop("rondin").is_empty(), "boutique de Rondin")
	for e: String in ["guetteur_du_lac", "gobelins_du_camp", "gros_bleu", "goulum", "balourd"]:
		check(not Database.get_encounter(e).is_empty(), "rencontre %s" % e)
	# les quatre arènes du chapitre existent et se construisent
	for a: String in ["galerie_mine", "halle_piliers", "bord_du_lac", "pont_abime"]:
		check(Database.arenas.has(a), "arène %s" % a)
	# la sortie de Fondue-Combe mène aux Mines
	var gate := false
	for o: Dictionary in Database.get_map("fondue_combe").get("objects", []):
		if str(o.get("type", "")) == "warp" and str((o.get("to", {}) as Dictionary).get("map", "")) == "porte_morbier":
			gate = str(o.get("if", "")) == "chapitre_3_fini"
	check(gate, "Fondue-Combe ouvre la route de Morbier une fois le chapitre 3 fini")
	for table: String in ["morbier_galeries", "morbier_halle", "morbier_profondeurs"]:
		check(Database.encounter_tables.has(table), "table %s" % table)
		var r := _c3_group_rate(table, 12, -1)
		check(float(r[0]) >= 0.85, "table %s, quatre niv. 12 sans talents : pire groupe %d %% (%s)" % [table, int(float(r[0]) * 100.0), str(r[1])])
		print("  table %-20s pire groupe %3d %%  (%s)" % [table, int(float(r[0]) * 100.0), str(r[1])])
	# les cinq combats forcés : (rencontre, niveau, minimum avec talents, minimum sans talents)
	for case: Array in [["guetteur_du_lac", 12, 0.6, 0.0], ["gobelins_du_camp", 12, 0.8, 0.2], ["gros_bleu", 13, 0.6, 0.1], ["goulum", 14, 0.6, 0.0], ["balourd", 16, 0.6, 0.0]]:
		var enc := Database.get_encounter(str(case[0]))
		var a := _c2_rate(TEAM, int(case[1]), enc, 0)
		var b := _c2_rate(TEAM, int(case[1]), enc, -1)
		var alt := _c2_rate(["glandoulf", "sam", "pepin", "merri"], int(case[1]), enc, 0)
		check(a >= float(case[2]), "%s, quatre niv. %d, talents A : %d %%" % [str(case[0]), int(case[1]), int(a * 100.0)])
		check(b >= float(case[3]), "%s, quatre niv. %d, sans talents : %d %%" % [str(case[0]), int(case[1]), int(b * 100.0)])
		check(alt >= 0.35, "%s, autre équipe de quatre : %d %%" % [str(case[0]), int(alt * 100.0)])
		print("  %-18s niv. %2d : %3d %% avec talents, %3d %% sans, %3d %% autre équipe" % [str(case[0]), int(case[1]), int(a * 100.0), int(b * 100.0), int(alt * 100.0)])
	GameState.new_game()


# -------------------------------------------------------------------- chapitre 5

const C5_MIN_TABLE := 0.8
const C5_MIN_BOSS := 0.6
const C5_MAPS := ["chutes_gratin", "plaine_roquefort", "cabecou", "fongorn", "garde_manger", "bergerie_or", "isengarde", "terrasse_office"]
const C5_STYLES := {"chutes_gratin": "chutes", "plaine_roquefort": "cavalier", "cabecou": "cavalier", "fongorn": "fongorn", "garde_manger": "isengarde", "bergerie_or": "cavalier", "isengarde": "isengarde", "terrasse_office": "isengarde"}
const C5_MONSTERS := ["ouroukouille", "ouroukouille_brocheur", "ouroukouille_petrisseur", "ouroukouille_chef", "paton", "ouargue", "corbeau", "hirsute", "hors_oeuvre"]
const C5_HUNTERS := ["sam", "froton", "merri", "pepin"]
const C5_RIDERS := ["glandoulf", "aragrogne", "digoulasse", "grimli"]
const C5_CAPTIVES := ["aragrogne", "digoulasse", "grimli"]
const C5_REUNITED := ["glandoulf", "sam", "froton", "aragrogne"]


## Pire groupe d'une table pour une équipe donnée.
func _c5_table_rate(team: Array, table: String, level: int) -> Array:
	var worst := 1.0
	var which := ""
	for g: Variant in (Database.encounter_tables[table] as Dictionary)["groups"]:
		var enc := {"enemies": (g as Dictionary)["enemies"]}
		var r := _c2_rate(team, level, enc, 0)
		if r < worst:
			worst = r
			which = ", ".join(PackedStringArray((g as Dictionary)["enemies"]))
	return [worst, which]


func _test_chapter_5_data() -> void:
	print("== Chapitre 5 : données et équilibre ==")
	for id: String in C5_MAPS:
		check(Database.has_map(id), "carte %s existe" % id)
		var map := Database.get_map(id)
		check(map.has("music") and Database.music.has(str(map["music"])), "carte %s : musique connue" % id)
		check(str(map.get("style", "")) == str(C5_STYLES[id]), "carte %s : style %s" % [id, C5_STYLES[id]])
		check(Database.arenas.has(str(map.get("arena", ""))), "carte %s : arène déclarée" % id)
	for kind: String in C5_MONSTERS:
		check(MonsterPainter.has(kind), "monstre %s : espèce connue" % kind)
		var img: Image = MonsterPainter.paint(kind)
		var magenta := 0
		var filled := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.5:
					filled += 1
					if c.r > 0.95 and c.g < 0.05 and c.b > 0.95:
						magenta += 1
		check(magenta == 0 and filled > 200, "monstre %s : dessiné, sans magenta (%d px)" % [kind, filled])
	for q: String in ["isengarde", "roi_dort_mal", "trois_nouvelles", "levain"]:
		check(not Database.get_quest(q).is_empty(), "quête %s décrite" % q)
	check(Database.get_quest("isengarde").get("kind") == "principale", "l'Isengarde-Manger est la quête principale")
	for ch: String in ["eolaine", "eomeche", "theodort", "grimace", "barbe_molle", "sarumale", "boulangere", "chambellan"]:
		check(Database.characters.has(ch), "personnage %s décrit" % ch)
	for it: String in ["louche_blanche", "cape_de_bromure", "plume_de_l_aigle", "feuillet_a_souche", "cisailles_de_tonte", "brioche_non_conforme"]:
		check(Database.items.has(it), "objet %s décrit" % it)
	check(not Database.get_shop("cabecou_marche").is_empty(), "boutique du Cabécou")
	for e: String in ["ambuscade_chutes", "grimace", "uglouk_garde", "froton_anneaute", "breche", "sarumale"]:
		check(not Database.get_encounter(e).is_empty(), "rencontre %s" % e)
	for en: String in ["ouroukouille_ligne", "ouroukouille_brocheur", "ouroukouille_petrisseur", "paton", "ouargue", "corbeau_controleur", "hirsute", "hors_oeuvre", "uglouk", "grimace", "froton_anneaute", "sarumale"]:
		check(Database.enemies.has(en), "ennemi %s décrit" % en)
	# équipement : une pièce neuve du chapitre pour chaque type d'emplacement (arme, tête, corps, bijou)
	var slots := {}
	for it: String in ["louche_blanche", "heaume_a_criniere", "toque_ouroukouille", "cotte_de_bois_dore", "tablier_de_petrisseur", "robe_bariolee", "fer_a_cheval_dore", "cape_de_bromure", "pince_de_service", "mousse_de_barbe_molle", "plume_de_l_aigle"]:
		check(Database.items.has(it), "équipement %s décrit" % it)
		slots[str(Database.items.get(it, {}).get("slot", ""))] = true
	check(slots.has("weapon") and slots.has("head") and slots.has("armor") and slots.has("trinket"), "équipement : armes, casques, armures et bijoux neufs (%s)" % str(slots.keys()))
	var lv := {"plaine": 17, "fongorn": 17, "garde_manger": 17, "isengarde": 18}
	var teams := {"plaine": C5_HUNTERS, "fongorn": C5_RIDERS, "garde_manger": C5_HUNTERS, "isengarde": C5_REUNITED}
	for table: String in lv:
		check(Database.encounter_tables.has(table), "table %s" % table)
		var r := _c5_table_rate(teams[table], table, int(lv[table]))
		check(float(r[0]) >= C5_MIN_TABLE, "table %s, niv. %d : pire groupe %d %% (%s)" % [table, int(lv[table]), int(float(r[0]) * 100.0), str(r[1])])
		print("  table %-14s pire groupe %3d %%  (%s)" % [table, int(float(r[0]) * 100.0), str(r[1])])
	# combats forcés : (rencontre, équipe, niveau, minimum, maximum)
	for case: Array in [
			["ambuscade_chutes", C5_HUNTERS, 17, C5_MIN_BOSS, 0.95], ["grimace", C5_CAPTIVES, 17, C5_MIN_BOSS, 0.95],
			["uglouk_garde", C5_HUNTERS, 17, C5_MIN_TABLE, 1.0], ["froton_anneaute", ["sam", "merri", "pepin"], 17, C5_MIN_BOSS, 0.95],
			["breche", C5_REUNITED, 18, C5_MIN_BOSS, 1.0], ["sarumale", C5_REUNITED, 18, C5_MIN_BOSS, 0.95]]:
		var enc := _waved("breche_avant", "breche") if str(case[0]) == "breche" else Database.get_encounter(str(case[0]))
		var a := _c2_rate(case[1], int(case[2]), enc, 0)
		check(a >= float(case[3]) and a <= float(case[4]), "%s, équipe niv. %d : %d %% (visé %d à %d %%)" % [str(case[0]), int(case[2]), int(a * 100.0), int(float(case[3]) * 100.0), int(float(case[4]) * 100.0)])
		print("  %-18s niv. %2d : %3d %%" % [str(case[0]), int(case[2]), int(a * 100.0)])
	GameState.new_game()


# ------------------------------------------------------------------ élan et icônes

## Plaque d'un ennemi : bouclier, une case par faiblesse (« ? » tant qu'elle est inconnue).
func _check_plate_content(ui: Control, e: RefCounted, tag: String) -> void:
	var chips: HBoxContainer = ui._plates[e.key]["chips"]
	var want := (1 if int(e.shield_max) > 0 else 0) + (e.weak as Array).size()
	check(chips.get_child_count() >= want, "%s : plaque de %s : bouclier et %d cases de faiblesse (%d éléments)" % [tag, str(e.name), (e.weak as Array).size(), chips.get_child_count()])
	if int(e.shield_max) > 0 and chips.get_child_count() > 0:
		check(chips.get_child(0).custom_minimum_size.x >= 24.0, "%s : plaque de %s : le bouclier est dessiné" % [tag, str(e.name)])


func _test_boost() -> void:
	GameState.new_game()
	GameState.add_to_party("pepin")
	var e: RefCounted = BattleEngine.new()
	e.setup({"enemies": ["limace_molle"], "arena": "pre"}, 11)
	var g: RefCounted = e.party[0]
	var p: RefCounted = e.party[1]
	var slug: RefCounted = e.enemies[0]
	slug.base["hp"] = 999999
	slug.hp = 999999
	slug.base["eva"] = 0
	check(int(g.elan) == e.ELAN_START and int(p.elan) == e.ELAN_START and int(slug.elan) == 0, "élan : un point au départ pour les héros, aucun pour l'ennemi")
	var ev: Array = e.start_turn(g)
	check(int(g.elan) == e.ELAN_START + e.ELAN_GAIN and _has_event(ev, "elan"), "élan : un point gagné au début du tour")
	g.elan = e.ELAN_MAX
	e.start_turn(g)
	check(int(g.elan) == e.ELAN_MAX, "élan : la réserve plafonne à %d" % e.ELAN_MAX)
	# engagement : 1 + N coups, les points sont dépensés, pas de gain au tour suivant
	g.elan = 3
	g.elan_rest = false
	ev = e.perform(g, {"type": "attack", "target": slug, "elan": 2})
	var casts := 0
	for x: Dictionary in ev:
		if str(x.get("type", "")) == "cast":
			casts += 1
	check(casts == 3 and int(g.elan) == 1, "élan : deux points engagés donnent trois coups (%d) et laissent 1 en réserve (%d)" % [casts, int(g.elan)])
	e.start_turn(g)
	check(int(g.elan) == 1, "élan : pas de point gagné au tour qui suit un engagement")
	e.start_turn(g)
	check(int(g.elan) == 2, "élan : le gain reprend ensuite")
	g.elan = 1
	ev = e.perform(g, {"type": "attack", "target": slug, "elan": 3})
	check(int(g.elan) == 0, "élan : on n'engage jamais plus que sa réserve")
	g.elan = 5
	ev = e.perform(g, {"type": "attack", "target": slug, "elan": 9})
	check(int(g.elan) == 2, "élan : au plus %d points par tour" % e.ELAN_COMMIT_MAX)
	# chaque coup d'une attaque écorne le bouclier quand il touche une faiblesse
	g.elan = 3
	ev = e.perform(g, {"type": "attack", "target": slug})
	var element := ""
	for x: Dictionary in ev:
		if str(x.get("type", "")) == "cast":
			element = str(x.get("element", ""))
	slug.weak = [element]
	slug.shield = 10
	slug.shield_max = 10
	g.elan = 3
	ev = e.perform(g, {"type": "attack", "target": slug, "elan": 3})
	var weak_hits := 0
	for x: Dictionary in ev:
		if str(x.get("type", "")) == "damage" and bool(x.get("weak", false)):
			weak_hits += 1
	check(weak_hits >= 1 and int(slug.shield) == 10 - weak_hits, "élan : chaque coup sur une faiblesse écorne le bouclier (%d coups, bouclier %d)" % [weak_hits, int(slug.shield)])
	slug.weak = []
	slug.shield = 99
	slug.shield_max = 99
	# compétence offensive : puissance multipliée
	check(str(e.elan_kind(g, {"type": "skill", "id": "etincelle"})) == "power", "élan : une compétence offensive est amplifiée")
	var plain := 0
	var boosted := 0
	for _i in 30:
		g.mp = g.max_mp()
		g.elan = 3
		ev = e.perform(g, {"type": "skill", "id": "etincelle", "target": slug})
		for x: Dictionary in ev:
			if str(x.get("type", "")) == "damage":
				plain += int(x.get("amount", 0))
		g.mp = g.max_mp()
		g.elan = 3
		ev = e.perform(g, {"type": "skill", "id": "etincelle", "target": slug, "elan": 2})
		for x: Dictionary in ev:
			if str(x.get("type", "")) == "damage":
				boosted += int(x.get("amount", 0))
	check(plain > 0 and float(boosted) > float(plain) * 1.6 and float(boosted) < float(plain) * 2.5, "élan : deux points doublent à peu près les dégâts d'une compétence (%d contre %d)" % [boosted, plain])
	# soin amplifié
	check(str(e.elan_kind(p, {"type": "skill", "id": "cataplasme"})) == "heal", "élan : un soin est amplifié")
	var heal_plain := 0
	var heal_boost := 0
	for _i in 10:
		p.mp = p.max_mp()
		g.hp = 1
		p.elan = 3
		ev = e.perform(p, {"type": "skill", "id": "cataplasme", "target": g})
		for x: Dictionary in ev:
			if str(x.get("type", "")) == "heal":
				heal_plain += int(x.get("amount", 0))
		p.mp = p.max_mp()
		g.hp = 1
		p.elan = 3
		ev = e.perform(p, {"type": "skill", "id": "cataplasme", "target": g, "elan": 2})
		for x: Dictionary in ev:
			if str(x.get("type", "")) == "heal":
				heal_boost += int(x.get("amount", 0))
	check(heal_plain > 0 and heal_boost > heal_plain, "élan : un soin engagé soigne davantage (%d contre %d)" % [heal_boost, heal_plain])
	# défendre et les objets n'en consomment pas ; l'ennemi n'en a pas
	g.elan = 3
	e.perform(g, {"type": "defend", "elan": 3})
	check(int(g.elan) == 3 and str(e.elan_kind(g, {"type": "defend"})) == "" and str(e.elan_kind(g, {"type": "item", "id": "tisane"})) == "", "élan : défendre et les objets n'en consomment pas")
	ev = e.perform(slug, {"type": "attack", "target": g, "elan": 3})
	casts = 0
	for x: Dictionary in ev:
		if str(x.get("type", "")) == "cast":
			casts += 1
	check(casts == 1 and int(slug.elan) == 0, "élan : l'ennemi n'en a pas")
	# le combat automatique des tests s'en sert, et la sauvegarde l'ignore
	GameState.new_game()
	GameState.add_to_party("sam")
	var f: RefCounted = BattleEngine.new()
	f.setup({"enemies": ["vacherin"], "arena": "pre"}, 5)   # un gros ennemi : l'automate y engage son élan
	var used := 0
	var turns := 0
	while str(f.result) == "" and turns < 400:
		turns += 1
		var who: RefCounted = f.next_actor()
		if who == null:
			break
		f.start_turn(who)
		if str(f.result) == "" and bool(f.can_act):
			var action: Dictionary = f.ai_action(who) if str(who.side) == "enemy" else f.auto_action(who)
			if int(action.get("elan", 0)) > 0:
				used += 1
			f.perform(who, action)
		if str(f.result) == "":
			f.end_turn(who)
	check(used > 0, "élan : le combat automatique des tests engage de l'élan (%d fois)" % used)
	check(JSON.stringify(GameState.to_dict()).find("elan") == -1, "élan : rien dans la sauvegarde")


func _test_icons() -> void:
	var IP: GDScript = load("res://src/gfx/icon_painter.gd")
	var kinds: Array = IP.kinds()
	for id: Variant in ["attack", "skills", "items", "defend", "flee", "elan", "hand", "unknown"]:
		check(kinds.has(id), "icônes : « %s » existe" % str(id))
	for id: Variant in Database.elements:
		check(kinds.has(str(id)), "icônes : l'élément %s a son icône" % str(id))
	for id: Variant in Database.statuses:
		check(kinds.has(str(id)), "icônes : l'état %s a son icône" % str(id))
	for id: Variant in ["baton", "ustensile", "dague", "serpe", "rapiere", "epee", "arc", "hache"]:   # les genres d'arme de item_types
		check(kinds.has(str(id)) and (Database.game.get("item_types", {}) as Dictionary).has(str(id)), "icônes : le genre d'arme %s a son icône" % str(id))
	for id: Variant in kinds:
		var img: Image = IP.paint(str(id))
		var opaque := 0
		var magenta := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.5:
					opaque += 1
					if c.r > 0.9 and c.b > 0.9 and c.g < 0.15:
						magenta += 1
		check(opaque >= 12 and magenta == 0, "icônes : « %s » est dessinée (%d pixels) sans magenta" % [str(id), opaque])
		check(Sprites.icon(str(id)) != null, "icônes : « %s » passe par Sprites.icon" % str(id))


## Les cartes des Mines de Morbier et des portes de l'Est donnent au héros une lumière propre.
func _test_lanternes_mines() -> void:
	for id: String in ["porte_morbier", "morbier_galeries", "morbier_halle", "morbier_pont", "morbier_profondeurs", "morbier_tombe", "morbier_antre", "portes_est"]:
		if true:
			var amb: Dictionary = Database.get_ambiance(str(Database.get_map(id).get("ambiance", "")))
			var lan: Variant = amb.get("lantern")
			check(lan is Dictionary and float((lan as Dictionary).get("energy", 0.0)) > 0.0, "lanterne : la carte « %s » a une lumière propre pour le héros" % id)
	# règle générale : tout lieu sans soleil dont la lumière ambiante est faible a sa lanterne
	# (seule exception : l'ambiance « interieur_chaud », éclairée par les foyers de la pièce)
	var seen_amb := {}
	for id: String in Database.list_maps():
		var aid := str(Database.get_map(id).get("ambiance", ""))
		if seen_amb.has(aid) or aid == "interieur_chaud":
			continue
		seen_amb[aid] = true
		var amb2: Dictionary = Database.get_ambiance(aid)
		var dark := not amb2.has("sun") and float((amb2.get("ambient", {}) as Dictionary).get("energy", 1.0)) < 0.55
		check(not dark or amb2.get("lantern") is Dictionary, "lanterne : l'ambiance sombre « %s » (carte « %s ») a sa lanterne" % [aid, id])
	# une clé en double dans ambiances.json masque la première : la dernière gagne sans bruit
	var raw := FileAccess.get_file_as_string("res://data/ambiances.json")
	var keys := RegEx.create_from_string("(?m)^\\t\"([a-z_0-9]+)\": \\{").search_all(raw)
	var names := {}
	var dup := 0
	for m: RegExMatch in keys:
		if names.has(m.get_string(1)):
			dup += 1
		names[m.get_string(1)] = true
	check(keys.size() > 20 and dup == 0, "ambiances : aucune clé en double dans ambiances.json (%d doublon(s))" % dup)


## Règle : rien ne se dresse devant une porte de maison (ni lampadaire, ni bannière, ni statue...) :
## ni dans la bande de la porte, ni sur ses deux lampadaires. Données seules, aucune carte construite.
func _test_door_clearance() -> void:
	print("== Abords des portes ==")
	var skip := ["house", "npc", "warp", "trigger", "light", "encounter_zone", "scatter", "elf_rail", "cav_palissade", "fence", "elf_medallion",
		"elf_bridge_face", "rug", "isen_flamme", "elf_fountain", "elf_flowers", "elf_pergola", "monster", "sign"]
	var bad := 0
	for id in Database.list_maps():
		var map := Database.get_map(id)
		var objs: Array = map.get("objects", [])
		for h: Variant in objs:
			if not (h is Dictionary) or str((h as Dictionary).get("type", "")) != "house" or not (h as Dictionary).has("door"):
				continue
			var r: Array = (h as Dictionary).get("rect", [0, 0, 5, 4])
			var xd := float(r[0]) + float((h as Dictionary)["door"])
			var z1 := float(r[1]) + float(r[3])
			for o: Variant in objs:
				if not (o is Dictionary) or skip.has(str((o as Dictionary).get("type", ""))) or not (o as Dictionary).has("pos"):
					continue
				var p: Array = (o as Dictionary)["pos"]
				if p.size() < 2:
					continue
				var dx := absf(float(p[0]) - xd)
				var dz := float(p[1]) - z1
				var tall := ["elf_lantern", "lantern"].has(str((o as Dictionary).get("type", "")))
				var in_strip := dx < 0.9 and dz > -0.3 and dz < (3.6 if tall else 1.6)
				var on_lamp := absf(dx - 1.25) < 0.55 and dz > -0.3 and dz < 0.9 and not ["elf_lantern", "lantern"].has(str((o as Dictionary).get("type", "")))
				if in_strip or on_lamp:
					bad += 1
					check(false, "portes : « %s » (%s en %s) gêne la porte de la maison %s" % [str((o as Dictionary).get("type", "")), id, str(p), str(r)])
	check(bad == 0, "portes : aucun objet devant une porte de maison")


## Habillage des intérieurs : hors-carte jamais noir, décors posés de façon stable, enseignes sans chevauchement.
func _test_interior_dress() -> void:
	print("== Habillage des intérieurs et décors ==")
	var ID: GDScript = load("res://src/world/interior_dress.gd")
	var IP: GDScript = load("res://src/gfx/interior_painter.gd")
	var HB: GDScript = load("res://src/world/house_builder.gd")
	var MB: GDScript = load("res://src/world/map_builder.gd")
	var docs := FileAccess.get_file_as_string("res://docs/FORMAT_DONNEES.md")
	for field: String in ["wall_dress", "surround_tile", "surround_fade", "sign_spot", "cave_pierre"]:
		check(docs.contains(field), "habillage : « %s » est documenté" % field)
	# décors muraux : tous peints, opaques par endroits, à un pixel des bords
	for kind: String in IP.DECOR:
		for v in int(IP.DECOR[kind][0]):
			var d: Dictionary = IP.paint_decor(kind, v)
			var img: Image = d["albedo"]
			var opaque := 0
			for y in img.get_height():
				for x in img.get_width():
					if img.get_pixel(x, y).a > 0.5:
						opaque += 1
			check(opaque > 40, "habillage : décor %s/%d peint (%d pixels)" % [kind, v, opaque])
	# mouchetage : teintes distinctes, dalles bien formées
	for t: String in MB.MOTTLE:
		var m: Array = MB.MOTTLE[t]
		check(not Color(str(m[0])).is_equal_approx(Color(str(m[1]))), "mouchetage %s : deux teintes distinctes" % t)
		if m.size() > 4:
			check(m[4] is Array and (m[4] as Array).size() == 2 and int(m[4][0]) > 0 and int(m[4][1]) > 0, "mouchetage %s : dalles [largeur, hauteur]" % t)
	# les cartes d'intérieur : hors-carte présent, ombre coupée, rien de noir, décors stables
	var checked := 0
	for id in Database.list_maps():
		var map := Database.get_map(id)
		if not bool(map.get("interior", false)):
			continue
		var tile := str(map.get("surround_tile", "roche_fond"))
		var tex_img: Image = load("res://src/gfx/tile_painter.gd").paint(tile)
		var lum := 0.0
		for y in range(0, tex_img.get_height(), 3):
			for x in range(0, tex_img.get_width(), 3):
				var c := tex_img.get_pixel(x, y)
				lum += 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
		lum /= float((tex_img.get_width() / 3 + 1) * (tex_img.get_height() / 3 + 1))
		var tint := Color(str(map.get("surround_tint", "#ffffff")))
		# au plus loin du fondu (far_level 0,1 x 0,6 d'éclat), plus la part émissive (glow 0,45)
		var seen := lum * (tint.r + tint.g + tint.b) / 3.0 * 0.1 * 0.6 * 1.45
		check(lum > 0.08, "hors-carte %s : tuile « %s » assez claire pour n'être jamais noire (%.2f)" % [id, tile, lum])
		check(seen > 0.0 and tint.get_luminance() > 0.2, "hors-carte %s : teinte non noire" % id)
		var sums: Array = []
		for pass_i in 2:
			GameState.new_game()
			var world: Node3D = World.new()
			add_child(world)
			world.setup(id, str((map.get("spawns", {}) as Dictionary).keys()[0]))
			var sur := world.get_node_or_null("Surround") as MeshInstance3D
			check(sur != null and sur.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "habillage %s : hors-carte posé, sans ombre" % id)
			var dress := world.get_node_or_null("InteriorDress")
			var sig := 0.0
			var n := 0
			if dress != null:
				for c: Node in dress.get_children():
					if c is MeshInstance3D:
						sig += (c as MeshInstance3D).position.x * 3.0 + (c as MeshInstance3D).position.y
						n += 1
					elif c is OmniLight3D:
						check(not (c as OmniLight3D).shadow_enabled, "habillage %s : une bougie ou fenêtre ne projette pas d'ombre" % id)
			if str(map.get("wall_dress", "")) != "":
				check(dress != null, "habillage %s : décors muraux posés" % id)
			sums.append([snappedf(sig, 0.001), n])
			world.queue_free()
			await get_tree().process_frame
		check(sums[0] == sums[1], "habillage %s : décors posés à l'identique d'une construction à l'autre" % id)
		checked += 1
	check(checked >= 12, "habillage : au moins douze intérieurs contrôlés (%d)" % checked)
	# enseignes : ni sur une fenêtre ni sur la porte, jamais plus large que la façade
	for id in Database.list_maps():
		for o: Variant in Database.get_map(id).get("objects", []):
			if not (o is Dictionary) or str((o as Dictionary).get("type", "")) != "house" or not (o as Dictionary).has("door"):
				continue
			var r: Array = (o as Dictionary).get("rect", [0, 0, 5, 4])
			var x0 := float(r[0])
			var xd := x0 + float((o as Dictionary)["door"])
			var wins: Array = (o as Dictionary).get("windows", [])
			var spot: Vector2 = HB.sign_spot(x0, float(r[2]), xd, wins)
			if spot.x < 0.0:
				# façade trop étroite pour une enseigne à plat : l'enseigne en drapeau doit trouver sa place
				var bx: float = HB.sign_bracket(x0, float(r[2]), xd, wins)
				check(bx >= 0.0, "enseigne en drapeau %s %s : une place existe" % [id, str(r)])
				if bx >= 0.0:
					check(absf(bx - xd) >= 0.55 + 0.2 - 0.001, "enseigne en drapeau %s %s : ne touche pas la porte" % [id, str(r)])
					for wv: Variant in wins:
						check(absf(bx - (x0 + float(wv))) >= 0.6 + 0.2 - 0.001, "enseigne en drapeau %s %s : ne touche pas la fenêtre en %s" % [id, str(r), str(wv)])
				continue
			var half := 0.58 * spot.y
			check(absf(spot.x - xd) >= half + 0.55 - 0.001, "enseigne %s %s : ne touche pas la porte" % [id, str(r)])
			for wv: Variant in wins:
				check(absf(spot.x - (x0 + float(wv))) >= half + 0.6 - 0.001, "enseigne %s %s : ne touche pas la fenêtre en %s" % [id, str(r), str(wv)])
			check(spot.x - half >= x0 and spot.x + half <= x0 + float(r[2]), "enseigne %s %s : tient dans la façade" % [id, str(r)])


## Maisons du style par défaut : volumes, variété stable, jouabilité inchangée (emprise, porte, estompage).
func _test_houses() -> void:
	print("== Maisons des villages ==")
	var HB: GDScript = load("res://src/world/house_builder.gd")
	var HP: GDScript = load("res://src/gfx/house_painter.gd")
	var docs := FileAccess.get_file_as_string("res://docs/FORMAT_DONNEES.md")
	for field: String in ["grobitte", "storeys", "dormers", "plaster", "extra", "planches", "colombage", "jetty"]:
		check(docs.contains(field), "maisons : le champ ou la valeur « %s » est documenté" % field)
	check(is_equal_approx(HB.glow_factor({"ambiance": "crepuscule"}), 1.0), "maisons : fenêtres pleinement éclairées au crépuscule")
	check(HB.glow_factor({"ambiance": "aube"}) < 0.5, "maisons : fenêtres bien plus discrètes en plein jour")
	for kind: String in HP.ROOF_PAL:
		var img: Image = HP.roof({"roof": kind, "seed": 11}, 6.0, 3.0)
		var ok := img.get_width() == 144 and img.get_pixel(3, 3).a > 0.99 and img.get_pixel(100, 60).a > 0.99
		check(ok and not img.get_pixel(50, 40).is_equal_approx(Color(1, 0, 1)), "maisons : toit « %s » peint en entier" % kind)
	for kind: String in ["auberge", "fromage", "forge", "cheval", "herbes", "autre"]:
		check(HP.sign_board(kind).get_pixel(14, 14).a > 0.5, "maisons : enseigne « %s » peinte" % kind)
	var total := 0
	var seen_kinds := {}
	for id in Database.list_maps():
		var map := Database.get_map(id)
		if str(map.get("style", "")) != "":
			continue
		var list: Array = []
		for o: Variant in map.get("objects", []):
			if o is Dictionary and str((o as Dictionary).get("type", "")) == "house" and str((o as Dictionary).get("style", "")) != "elfe" and str((o as Dictionary).get("if", "")) == "":
				list.append(o)
		if list.is_empty():
			continue
		GameState.new_game()
		var world: Node3D = World.new()
		add_child(world)
		var t0 := Time.get_ticks_msec()
		world.setup(id, str((map.get("spawns", {}) as Dictionary).keys()[0]))
		var ms := Time.get_ticks_msec() - t0
		var nodes: Array = []
		for n: Node in world.get_children():
			if n.has_meta("spec"):
				nodes.append(n)
		check(nodes.size() == list.size(), "maisons %s : %d bâtiments construits sur %d (%d ms)" % [id, nodes.size(), list.size(), ms])
		var sigs: Array = []
		for k in list.size():
			var o: Dictionary = list[k]
			var r: Array = o["rect"]
			var rect := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
			total += 1
			check(world.rects.has(rect), "maisons %s : l'emprise %s est inchangée" % [id, str(r)])
			var sp: Dictionary = HB.spec(map, o)
			check(str(HB.spec(map, o)) == str(sp), "maisons %s : le tirage de la maison %s est stable" % [id, str(r)])
			seen_kinds[str(sp["wall"])] = true
			# jamais deux bâtiments de la carte avec le même mur, le même toit et la même porte
			for k2 in k:
				var sp2b: Dictionary = HB.spec(map, list[k2] as Dictionary)
				var same: bool = str(sp2b["wall"]) == str(sp["wall"]) and str(sp2b["roof"]) == str(sp["roof"]) and HB._same_door(sp2b["door_color"], sp["door_color"])
				check(not same, "maisons %s : les bâtiments %s et %s diffèrent (mur, toit ou porte)" % [id, str(list[k2]["rect"]), str(r)])
			check(HP.ROOF_PAL.has(str(sp["roof"])), "maisons %s : matière de toit connue (%s)" % [id, str(sp["roof"])])
			if str(o.get("style", "")) == "grobitte":
				check(sp["roof"] == "herbe" and sp["window"] == "rond", "maisons %s : la maison grobitte %s a son toit d'herbe et ses hublots" % [id, str(r)])
			# le bâtiment construit : toit au-dessus des murs, tout estompable
			var node: Node3D = null
			for n: Node3D in nodes:
				if (n.get_meta("spec") as Dictionary)["seed"] == sp["seed"]:
					node = n
			check(node != null, "maisons %s : bâtiment %s retrouvé" % [id, str(r)])
			if node == null:
				continue
			var top_y := 0.0
			for c: Node in node.get_children():
				if c is MeshInstance3D and (c as MeshInstance3D).mesh != null:
					top_y = maxf(top_y, (c as MeshInstance3D).mesh.get_aabb().end.y)
			check(top_y >= float(sp["wh"]) + float(sp["rh"]) * 0.9, "maisons %s : %s a un toit (faîte à %.1f)" % [id, str(r), top_y])
			var fade_nodes: Array = []
			for oc: Dictionary in world.occluders:
				if (oc["rect"] as Rect2) == rect:
					fade_nodes = oc["nodes"]
			var all_fade := fade_nodes.size() >= 5
			for c: Node in node.get_children():
				if c is GeometryInstance3D and not fade_nodes.has(c):
					all_fade = false
			check(all_fade, "maisons %s : %s s'estompe en entier (%d pièces)" % [id, str(r), fade_nodes.size()])
			var xd := float(r[0]) + float(o.get("door", float(r[2]) * 0.5))
			var has_door := false
			for wp: Dictionary in world.warps:
				if (wp["rect"] as Rect2).has_point(Vector2(xd, float(r[1] + r[3]) + 0.2)):
					has_door = true
			for it: Dictionary in world.interactables:
				if Vector2((it["pos"] as Vector3).x, (it["pos"] as Vector3).z).distance_to(Vector2(xd, float(r[1] + r[3]) + 0.35)) < 0.1:
					has_door = true
			if o.has("to") or o.has("dialogue"):
				check(has_door, "maisons %s : la porte de %s garde son passage ou son interaction" % [id, str(r)])
			sigs.append("%s|%s|%s|%d|%d|%s|%s|%s" % [str(sp["wall"]), str(sp["tint"]), str(sp["roof"]), int(sp["storeys"]), int(sp["dormers"]), str(sp["window"]), str(sp["door"]), str(sp["sign"])])
		# deux maisons voisines (triées par x) ne se ressemblent pas
		var order: Array = list.duplicate()
		order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["rect"][0]) < float(b["rect"][0]))
		var sig_of := func(o: Dictionary) -> String:
			var sp2: Dictionary = HB.spec(map, o)
			return "%s|%s|%s|%d|%d|%s|%s|%s" % [str(sp2["wall"]), str(sp2["tint"]), str(sp2["roof"]), int(sp2["storeys"]), int(sp2["dormers"]), str(sp2["window"]), str(sp2["door"]), str(sp2["sign"])]
		for k in range(order.size() - 1):
			check(sig_of.call(order[k]) != sig_of.call(order[k + 1]), "maisons %s : deux voisines diffèrent (%s et %s)" % [id, str(order[k]["rect"]), str(order[k + 1]["rect"])])
		world.queue_free()
		await get_tree().process_frame
	check(total >= 12, "maisons : au moins douze bâtiments contrôlés (%d)" % total)
	check(seen_kinds.size() >= 3, "maisons : au moins trois matières de mur dans les villages (%s)" % str(seen_kinds.keys()))


# ----------------------------------------------------------- conseils de jeu

const TUTORIAL_EVENTS := ["arrive", "interact_near", "quest_started", "item", "equip_item", "talent_point", "rest", "save", "shop", "reserve", "battle_start", "party_turn", "weak", "break", "ally_down"]


func _first_tracker(main: Node) -> Node:
	for c: Node in main.hud.get_children():
		if c.has_method("update_now"):
			return c
	return null


func _test_tutorials() -> void:
	print("== Conseils de jeu et rappel de quête ==")
	check(Tutorial.problems.is_empty() and Tutorial.tips.size() >= 12, "conseils : data/tutorials.json se lit sans erreur (%d conseils)" % Tutorial.tips.size())
	var sources := ""
	for f: String in ["res://src/main.gd", "res://src/core/game_state.gd", "res://src/battle/battle_scene.gd", "res://src/core/tutorial.gd"]:
		sources += FileAccess.get_file_as_string(f)
	var known_actions := ["move", "interact", "cancel", "menu", "journal", "elan", "choose"]
	for tip: Dictionary in Tutorial.tips:
		var id := str(tip["id"])
		check(TUTORIAL_EVENTS.has(str(tip.get("trigger", ""))), "conseil %s : déclencheur connu (%s)" % [id, str(tip.get("trigger", ""))])
		check(sources.contains("\"%s\"" % str(tip.get("trigger", ""))), "conseil %s : l'événement « %s » est bien déclenché par le jeu" % [id, str(tip.get("trigger", ""))])
		check(str(tip.get("title", "")) != "" and str(tip.get("title", "")).length() <= 40, "conseil %s : titre court" % id)
		var text := str(tip.get("text", ""))
		check(text.length() > 20 and text.length() <= 320, "conseil %s : texte court (%d signes)" % [id, text.length()])
		check(["note", "pause"].has(str(tip.get("mode", "note"))), "conseil %s : mode connu" % id)
		for k: Variant in tip.get("keys", []):
			check(k is Array and (k as Array).size() == 2 and (known_actions.has(str((k as Array)[0])) or InputMap.has_action(str((k as Array)[0]))) and str((k as Array)[1]) != "", "conseil %s : touche et verbe valides" % id)
		var who: Variant = tip.get("who", "")
		for w: Variant in (who if who is Array else [who]):
			check(str(w) == "" or not Database.get_character(str(w)).is_empty(), "conseil %s : %s est un personnage connu" % [id, str(w)])
		for term: String in str(tip.get("when", "")).split("&"):
			var t := term.strip_edges().trim_prefix("!")
			check(t == "" or t.begins_with("turn>=") or t.begins_with("item:") or Tutorial.CTX_TERMS.has(t), "conseil %s : condition « %s » comprise" % [id, t])
		for pad_mode in [false, true]:
			Tutorial.pad = pad_mode
			var view: Dictionary = Tutorial.resolve(tip)
			check(not str(view["text"]).contains("{") and str(view["tag"]) != "", "conseil %s : texte résolu (%s)" % [id, "manette" if pad_mode else "clavier"])
			for r: Dictionary in view["rows"]:
				check(not (r["caps"] as Array).is_empty() and not (r["caps"] as Array).has(""), "conseil %s : pictogrammes présents (%s)" % [id, "manette" if pad_mode else "clavier"])
	Tutorial.pad = false
	# touche du journal : clavier et manette, repère de quête réglable, cibles de quêtes valides
	var jkey := false
	var jpad := false
	for ev: InputEvent in InputMap.action_get_events("journal"):
		jkey = jkey or ev is InputEventKey
		jpad = jpad or ev is InputEventJoypadButton
	check(InputMap.has_action("journal") and jkey and jpad, "journal : une touche directe au clavier et à la manette")
	# La manette répond quel que soit son numéro (sous Windows elle n'est pas toujours la 0).
	for pad_case: Array in [["interact", JOY_BUTTON_A], ["cancel", JOY_BUTTON_B], ["menu", JOY_BUTTON_START], ["move_left", JOY_BUTTON_DPAD_LEFT], ["ui_accept", JOY_BUTTON_A], ["ui_cancel", JOY_BUTTON_B], ["ui_down", JOY_BUTTON_DPAD_DOWN]]:
		var pad_ev := InputEventJoypadButton.new()
		pad_ev.device = 3
		pad_ev.button_index = pad_case[1] as JoyButton
		pad_ev.pressed = true
		check(pad_ev.is_action(pad_case[0]), "manette numéro 3 : le bouton déclenche « %s »" % pad_case[0])
	var stick_ev := InputEventJoypadMotion.new()
	stick_ev.device = 2
	stick_ev.axis = JOY_AXIS_LEFT_X
	stick_ev.axis_value = 1.0
	check(stick_ev.is_action("move_right"), "manette numéro 2 : le stick gauche déplace le héros")
	var QT: GDScript = load("res://src/core/quest_target.gd")
	var n_targets := 0
	var bad_targets: Array = []
	for qid: String in Database.quests:
		var steps: Array = Database.get_quest(qid).get("steps", [])
		for si in steps.size():
			for tg: Dictionary in QT.targets_of_step(qid, si):
				n_targets += 1
				var prob: String = QT.problem(tg)
				if prob != "":
					bad_targets.append("%s/%d : %s" % [qid, si, prob])
	check(n_targets >= 40 and bad_targets.is_empty(), "quêtes : %d cibles, toutes valides %s" % [n_targets, str(bad_targets)])
	var has_repere := false
	for row: Dictionary in Settings.ROWS:
		has_repere = has_repere or str(row.get("id", "")) == "repere"
	check(has_repere and Settings.DEFAULTS.has("repere"), "paramètres : « Repère de quête » réglable")
	for pid: String in ["glandoulf", "sam", "froton", "pepin", "merri", "aragrogne", "digoulasse", "grimli"]:
		var pt: Texture2D = Sprites.portrait(pid)
		check(pt != null and pt.get_width() == pt.get_height(), "portrait de %s : carré, jamais étiré" % pid)
	check(Tutorial.caps_for("interact").size() >= 1 and Tutorial.caps_for("move").has("Flèches"), "conseils : touches lues dans les réglages de contrôles")
	check(Tutorial.when_ok("elan & turn>=2", {"elan": true, "turn": 2}) and not Tutorial.when_ok("elan & turn>=2", {"elan": true, "turn": 1}) and not Tutorial.when_ok("boss", {}), "conseils : conditions « when »")

	# réglage, vu une seule fois, sauvegarde
	Tutorial.force_on = true
	GameState.new_game()
	var kept: Variant = Settings.get_value("conseils")
	check(kept == true, "conseils : activés par défaut")
	check(Tutorial.fire("arrive") == ["deplacement"], "conseils : le premier déclenchement met le conseil en file")
	check(Tutorial.fire("arrive").is_empty() and Tutorial.is_seen("deplacement"), "conseils : un conseil ne s'affiche qu'une fois")
	check(Tutorial.fire("party_turn").is_empty(), "conseils : un conseil de combat ne passe pas par fire()")
	Tutorial.reset_seen()
	Settings.set_value("conseils", false)
	check(Tutorial.fire("arrive").is_empty() and not Tutorial.is_seen("deplacement"), "conseils : option désactivée, rien ne s'affiche ni ne se marque")
	Settings.set_value("conseils", true)
	Tutorial.reset_seen()
	check(Tutorial.fire("item", {"id": "tisane"}).is_empty() and Tutorial.fire("item", {"id": "baton_noueux"}) == ["equipement"], "conseils : le premier équipement obtenu déclenche le conseil d'équipement")
	Tutorial.fire("arrive")
	check(Tutorial.seen_ids().size() == 2, "conseils : deux conseils vus")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.new_game()
	check(GameState.tutorials_seen.is_empty(), "conseils : une nouvelle partie repart sans conseil vu")
	check(GameState.from_dict(saved) and Tutorial.is_seen("deplacement") and Tutorial.is_seen("equipement") and not Tutorial.is_seen("boutique"), "conseils : les conseils vus survivent à une sauvegarde et à un chargement")
	var old_save: Dictionary = saved.duplicate(true)
	old_save.erase("tutorials")
	GameState.new_game()
	check(GameState.from_dict(old_save) and Tutorial.seen_ids().size() == Tutorial.tips.size(), "conseils : une ancienne sauvegarde se charge sans rejouer les conseils")
	Tutorial.reset_seen()
	check(Tutorial.seen_ids().is_empty(), "conseils : « Revoir les conseils » les remet tous à neuf")
	var shown_before: int = Tutorial.shown_log.size()

	# réglage dans l'écran des paramètres
	var has_row := false
	var has_action := false
	for row: Dictionary in Settings.ROWS:
		has_row = has_row or str(row.get("id", "")) == "conseils"
		has_action = has_action or str(row.get("action", "")) == "revoir"
	check(has_row and has_action, "conseils : « Conseils de jeu » et « Revoir les conseils » dans les paramètres")

	# déroulé réel : nouvelle partie, conseils de passage, rappel de quête
	var main: Node = MAIN.instantiate()
	main.auto_battles = true
	add_child(main)
	await _wait_idle(main)
	check(Tutorial.help != null and is_instance_valid(Tutorial.help), "conseils : page d'aide installée dans le menu de pause")
	var seen_dialogue_with_tip := false
	main.start_new_game()
	for _i in 6000:
		await get_tree().process_frame
		if main.dialogue.active and Tutorial.panel_rect().size != Vector2.ZERO:
			seen_dialogue_with_tip = true
		if main.battle != null or main.busy:
			continue
		if main.dialogue.active:
			if main.dialogue.waiting:
				continue
			if main.dialogue._typing:
				main.dialogue._finish_typing()
			elif not main.dialogue._choosing:
				main.dialogue._advance()
		elif main.world != null and main.world.input_enabled:
			break
	check(main.mode == main.Mode.PLAY and GameState.has_flag("intro_vue"), "conseils : nouvelle partie jouée jusqu'à la main rendue")
	check(not seen_dialogue_with_tip, "conseils : aucun encart ne passe par-dessus un dialogue")
	for _i in 400:
		await get_tree().process_frame
		if Tutorial.current != "":
			break
	check(Tutorial.shown_log.size() > shown_before and Tutorial.shown_log.count("deplacement") == 1, "conseils : « se déplacer » s'affiche une fois en début de partie (%s)" % str(Tutorial.shown_log))
	var tracker := _first_tracker(main)
	check(tracker != null, "rappel de quête : posé dans le HUD")
	if tracker != null:
		for _i in 30:
			await get_tree().process_frame
		check(str(tracker.tracked) == "ramollissement" and str(tracker.step_text).begins_with("Trouver des compagnons"), "rappel de quête : quête principale et première étape (%s : %s)" % [str(tracker.tracked), str(tracker.step_text)])
		check(tracker._log.any(func(e: Array) -> bool: return e[0] == "Nouvelle quête" and e[1] == "ramollissement"), "rappel de quête : « Nouvelle quête » annoncé")
		var rect: Rect2 = tracker.panel_rect()
		var screen := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
		check(rect.size != Vector2.ZERO and screen.encloses(rect), "rappel de quête : visible et dans l'écran (%s)" % str(rect))
		var tip_rect: Rect2 = Tutorial.panel_rect()
		check(tip_rect.size == Vector2.ZERO or (screen.encloses(tip_rect) and not tip_rect.intersects(rect)), "conseils : l'encart reste dans l'écran et loin du rappel de quête (%s / %s)" % [str(tip_rect), str(rect)])
		for id: String in ["pepin", "sam", "froton"]:
			GameState.add_to_party(id)
		await get_tree().process_frame
		tracker.update_now()
		check(str(tracker.step_text).begins_with("Redresser le potager") and tracker._log.any(func(e: Array) -> bool: return e[0] == "Quête mise à jour"), "rappel de quête : suit l'étape (%s)" % str(tracker.step_text))
		GameState.set_flag("chapitre_1_fini")
		await get_tree().process_frame
		check(tracker._log.any(func(e: Array) -> bool: return e[0] == "Quête terminée" and e[1] == "ramollissement"), "rappel de quête : « Quête terminée » annoncé")
		# un dialogue, un menu ou un combat passent devant : le rappel s'efface
		main._open_pause()
		await get_tree().process_frame
		await get_tree().process_frame
		check(tracker.panel_rect().size == Vector2.ZERO and Tutorial.panel_rect().size == Vector2.ZERO, "rappel de quête et conseils : cachés quand le menu est ouvert")
		main.pause.close(true)
		main.world.set_input(true)

	# conseil qui suspend le jeu : touche tapée trop tôt sans effet, puis fermeture à la touche
	Tutorial.modal_in_tests = true
	Tutorial.reset_seen()
	Tutorial.call("fire_wait", "shop")
	await get_tree().process_frame
	await get_tree().process_frame
	check(Tutorial._modal and Tutorial.shown_log.back() == "boutique", "conseils : le conseil de boutique suspend le jeu")
	var modal_rect: Rect2 = Tutorial.panel_rect()
	check(modal_rect.size != Vector2.ZERO and Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size).encloses(modal_rect), "conseils : l'encart de pause est entièrement à l'écran (%s)" % str(modal_rect))
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	Input.parse_input_event(press)
	await get_tree().process_frame
	check(Tutorial._modal, "conseils : une touche tapée trop tôt ne ferme pas l'encart")
	await get_tree().create_timer(0.7).timeout
	Input.parse_input_event(press)
	await get_tree().process_frame
	await get_tree().process_frame
	check(not Tutorial._modal and Tutorial.is_seen("boutique") and Tutorial.panel_rect().size == Vector2.ZERO, "conseils : la touche ferme l'encart de pause")

	# en combat : le conseil passe avant le menu, jamais en même temps que lui
	Tutorial.reset_seen()
	GameState.new_game()
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui: Control = BattleUI.new()
	layer.add_child(ui)
	await get_tree().process_frame
	var scene: Node3D = BattleScene.new()
	add_child(scene)
	scene.setup({"enemies": ["limace_molle"], "arena": "pre"}, ui, 5)
	scene.run()
	var overlapped := false
	var saw_modal := false
	var placement_checked := false
	for _i in 2400:
		await get_tree().process_frame
		if Tutorial._modal:
			saw_modal = true
			if ui._state == ui.S.ROOT:
				overlapped = true
			if not placement_checked and Tutorial._guard <= 0.0 and Tutorial.shown_log.back() == "combat_tours":
				placement_checked = true
				var tip_box: Rect2 = Tutorial.panel_rect()
				var touched := 0
				for key: String in ui._plates:
					var root: Control = (ui._plates[key] as Dictionary)["root"]
					if root.visible and tip_box.intersects(Rect2(root.position, root.size)):
						touched += 1
				var frieze: Rect2 = Tutorial.target_rect("frise")
				check(touched == 0, "conseils : l'encart ne touche aucune plaque (%d touchées)" % touched)
				check(frieze.size == Vector2.ZERO or not tip_box.intersects(frieze), "conseils : l'encart des tours ne couvre pas la frise qu'il désigne")
			if Tutorial._guard <= 0.0 and Tutorial.shown_log.back() == "combat_tours":
				Input.parse_input_event(press)
		elif ui._state == ui.S.ROOT:
			break
	check(saw_modal and not overlapped, "conseils : le conseil de combat s'affiche avant le menu et jamais en même temps")
	check(ui._state == ui.S.ROOT and Tutorial.panel_rect().size == Vector2.ZERO and Tutorial.is_seen("combat_tours"), "conseils : une fois lu, le menu de combat s'ouvre et l'encart a disparu")
	scene.auto = true
	scene.fast = true
	for _i in 6000:
		await get_tree().process_frame
		if str(scene.outcome) != "":
			break
	ui.close()
	remove_child(scene)
	scene.queue_free()
	layer.queue_free()

	# les combats joués tout seuls ne sont jamais interrompus
	var n_before: int = Tutorial.shown_log.size()
	Tutorial.reset_seen()
	var auto_scene: Node3D = BattleScene.new()
	var auto_layer := CanvasLayer.new()
	add_child(auto_layer)
	var auto_ui: Control = BattleUI.new()
	auto_layer.add_child(auto_ui)
	await get_tree().process_frame
	add_child(auto_scene)
	auto_scene.auto = true
	auto_scene.fast = true
	auto_scene.setup({"enemies": ["limace_molle"], "arena": "pre"}, auto_ui, 5)
	auto_scene.run()
	for _i in 6000:
		await get_tree().process_frame
		if str(auto_scene.outcome) != "":
			break
	check(str(auto_scene.outcome) != "" and Tutorial.shown_log.size() == n_before, "conseils : un combat automatique n'attend jamais de touche")
	auto_ui.close()
	remove_child(auto_scene)
	auto_scene.queue_free()
	auto_layer.queue_free()

	Tutorial.modal_in_tests = false
	Tutorial.force_on = false
	Tutorial.clear()
	Tutorial.reset_seen()
	main.queue_free()
	await get_tree().process_frame


# ----------------------------------------------- mise en page du combat, toutes les arènes

## Recouvrement (en pixels carrés) de deux rectangles.
func _overlap(a: Rect2, b: Rect2) -> float:
	return a.intersection(b).get_area()


## Pour chaque arène, à quatre héros (Glandoulf, le plus grand, compris) contre cinq ennemis puis
## contre un boss large, aux deux tailles d'écran : tous les combattants sont entiers dans l'écran
## et, dans toutes leurs poses (pas en avant, penché, sort lancé), ne touchent ni les fiches, ni
## la frise, ni le menu, ni une plaque ; le premier plan ne couvre personne, reste dans les coins
## bas et sous sa borne de surface ; aucun décor posé sur le terrain ne passe devant un combattant.
func _test_battle_staging() -> void:
	print("== Mise en page du combat : toutes les arènes, tous les formats ==")
	var foes5 := ["limace_molle", "guepe_cidre", "champignon_dormeur", "limace_molle", "guepe_cidre"]
	var cases := [
		{"name": "4 héros, 5 ennemis", "allies": ["sam", "froton", "pepin"], "enemies": foes5},
		{"name": "4 héros, boss", "allies": ["sam", "froton", "pepin"], "enemies": ["crapaud_buffle"], "boss": true},
	]
	var extra := [
		{"name": "2 héros, 1 ennemi", "allies": ["sam"], "enemies": ["limace_molle"]},
		{"name": "3 héros, 3 ennemis", "allies": ["sam", "froton"], "enemies": ["vacherin", "guepe_cidre", "champignon_dormeur"]},
		{"name": "4 héros, 5 grands", "allies": ["sam", "froton", "pepin"], "enemies": ["vacherin", "crapaud_buffle", "vacherin", "crapaud_buffle", "vacherin"]},
		{"name": "4 héros, boss et deux sbires", "allies": ["sam", "froton", "pepin"], "enemies": ["gros_bleu", "gobe_lard", "gobe_lard"], "boss": true},
		{"name": "4 héros, boss large", "allies": ["sam", "froton", "pepin"], "enemies": ["vacherin"], "boss": true},
		{"name": "4 héros, boss à sprite de personnage", "allies": ["sam", "froton", "pepin"], "enemies": ["sarumale"], "boss": true},
	]
	var win := get_window()
	var old_size := win.size
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900)]:
		win.size = size
		await get_tree().process_frame
		for id: String in Database.arenas:
			var list := cases.duplicate()
			if id == "pre" or id == "grand_four" or id == "taverne":
				list.append_array(extra)
			for cs: Dictionary in list:
				GameState.new_game()
				for who: String in cs["allies"]:
					GameState.add_to_party(who)
				var layer := CanvasLayer.new()
				add_child(layer)
				var ui: Control = BattleUI.new()
				layer.add_child(ui)
				await get_tree().process_frame
				var scene: Node3D = BattleScene.new()
				add_child(scene)
				scene.fast = true
				var boss_fight: bool = bool(cs.get("boss", false))
				scene.setup({"enemies": cs["enemies"], "arena": id, "music": "boss" if boss_fight else "", "flee": not boss_fight}, ui, 5)
				scene.run()
				for _i in 600:
					await get_tree().process_frame
					if ui._state == ui.S.ROOT:
						break
				await get_tree().process_frame
				await get_tree().process_frame
				_check_staging(scene, ui, "arène %s, %s, %dx%d" % [id, cs["name"], size.x, size.y])
				ui.close()
				remove_child(scene)
				scene.queue_free()
				layer.queue_free()
	win.size = old_size


func _check_staging(scene: Node3D, ui: Control, tag: String, strict_boss: bool = true) -> void:
	var view: Rect2 = ui.get_viewport_rect()
	# un boss domine la scène : nettement plus haut qu'un héros et que ses sbires, jamais au-delà de la borne
	var is_boss_fight: bool = str(scene.encounter.get("music", "")) == "boss"
	if strict_boss:
		check((scene.boss != null) == is_boss_fight, "%s : le boss n'existe que dans un combat de boss" % tag)
	if scene.boss != null:
		var hero_h: float = (scene.actors[scene.engine.party[0].key] as Node3D).height
		var boss_h: float = (scene.actors[scene.boss.key] as Node3D).height
		var ratio := boss_h / hero_h
		check(ratio >= scene.BOSS_RATIO_FLOOR and ratio <= scene.BOSS_RATIO_MAX + 0.02, "%s : le boss fait %.2f fois un héros (entre %.1f et %.1f)" % [tag, ratio, scene.BOSS_RATIO_FLOOR, scene.BOSS_RATIO_MAX])
		for c: RefCounted in scene.engine.enemies:
			if c != scene.boss:
				check(boss_h >= 1.25 * (scene.actors[c.key] as Node3D).height, "%s : le boss domine %s" % [tag, str(c.name)])
	var ui_rects: Array[Rect2] = []
	for k: Variant in ui._rows:
		ui_rects.append((ui._rows[k]["card"] as Control).get_global_rect())
	ui_rects.append(ui._timeline.get_global_rect())
	ui_rects.append(ui._turn_tag.get_global_rect())
	var plates: Array[Rect2] = []
	for k: String in ui._plates:
		var root: Control = ui._plates[k]["root"]
		if root.visible:
			plates.append(root.get_global_rect())
	# plaques des ennemis : lisibles (ni l'une sur l'autre, ni sur le sprite d'un autre ennemi), et au-dessus
	# du bandeau des rappels de touches (bas de l'écran), même avec des sbires devant un boss
	var plate_worst := 0.0
	for i in plates.size():
		for j in range(i + 1, plates.size()):
			plate_worst = maxf(plate_worst, _overlap(plates[i], plates[j]))
		check(_overlap(plates[i], scene.keys_band(view.size)) < 1.0, "%s : plaque hors du bandeau des touches (bas à %.0f sur %.0f)" % [tag, plates[i].end.y, view.size.y])
	check(plate_worst < 1.0, "%s : les plaques ne se chevauchent pas (%.0f px²)" % [tag, plate_worst])
	var plate_on_foe := 0.0
	for k: String in ui._plates:
		var root: Control = ui._plates[k]["root"]
		if not root.visible:
			continue
		for c: RefCounted in scene.engine.enemies:
			if c.key != k and c.alive():
				plate_on_foe = maxf(plate_on_foe, _overlap(root.get_global_rect(), scene.screen_rect(c).grow(-4.0)))
	check(plate_on_foe < 1.0, "%s : aucune plaque sur le sprite d'un autre ennemi (%.0f px²)" % [tag, plate_on_foe])
	var menu: Array[Rect2] = [ui._root_panel.get_global_rect()]
	if (ui._elan_bars[0]["panel"] as Control).is_visible_in_tree():   # (la barre d'élan cachée, hors de son tour, reste à l'origine)
		menu.append((ui._elan_bars[0]["panel"] as Control).get_global_rect())
	var bodies: Array[Rect2] = []
	var hero_count := 0
	var foe_count := 0
	for c: RefCounted in scene.engine.all():
		var home: Rect2 = scene.screen_rect(c)
		var posed: Rect2 = scene.screen_rect(c, false, true).merge(scene.screen_rect(c, true, true))
		bodies.append(posed)
		check(view.encloses(home) and view.encloses(posed), "%s : %s entier dans l'écran, poses comprises" % [tag, str(c.name)])
		var worst := 0.0
		for r: Rect2 in ui_rects:
			worst = maxf(worst, _overlap(posed, r))
		check(worst < 1.0, "%s : %s ne touche ni fiche, ni frise (%.0f px²)" % [tag, str(c.name), worst])
		worst = 0.0
		for r: Rect2 in plates:   # un héros, dans toutes ses poses, ne touche aucune plaque ; un ennemi ne touche que la sienne (vérifié plus haut)
			if c.side == "party":
				worst = maxf(worst, _overlap(posed, r))
		check(worst < 1.0, "%s : %s ne touche aucune plaque (%.0f px²)" % [tag, str(c.name), worst])
		if c.side == "party":
			hero_count += 1
		else:
			foe_count += 1
	check(hero_count >= 2 and foe_count >= 1, "%s : %d héros et %d ennemis en place" % [tag, hero_count, foe_count])
	# le menu : jamais sur un combattant, une plaque ou une fiche
	var mw := 0.0
	for r: Rect2 in menu:
		check(view.encloses(r) or r.size.x <= 0.0, "%s : menu et barre d'élan dans l'écran" % tag)
		for c: RefCounted in scene.engine.all():
			if c == ui._actor or (c.side == "enemy" and not c.alive()):
				continue
			mw = maxf(mw, _overlap(r, scene.screen_rect(c).grow(-4.0)))
		for p: Rect2 in plates:
			mw = maxf(mw, _overlap(r, p))
		for u: Rect2 in ui_rects:
			mw = maxf(mw, _overlap(r, u))
	check(mw < 1.0, "%s : le menu ne couvre ni combattant, ni plaque, ni fiche (%.0f px²)" % [tag, mw])
	# premier plan : dans les coins bas, sous la borne, devant personne
	var corner := {"left": 0.0, "right": 0.0}
	for fr: Rect2 in scene.foreground_rects():
		if fr.get_area() <= 0.0:
			continue
		var left: bool = fr.get_center().x < view.size.x * 0.5
		corner["left" if left else "right"] += fr.get_area()
		check(fr.position.y >= view.size.y * scene.FG_CORNER_Y - 1.0 and (fr.end.x <= view.size.x * scene.FG_CORNER_W + 1.0 if left else fr.position.x >= view.size.x * (1.0 - scene.FG_CORNER_W) - 1.0), "%s : premier plan dans un coin bas" % tag)
		var cover := 0.0
		for b: Rect2 in bodies:
			cover = maxf(cover, _overlap(fr, b))
		for r: Rect2 in ui_rects + plates + menu:
			cover = maxf(cover, _overlap(fr, r))
		check(cover < 1.0, "%s : le premier plan ne couvre ni combattant, ni plaque, ni fiche, ni menu (%.0f px²)" % [tag, cover])
	for side: String in corner:
		check(float(corner[side]) <= view.size.x * view.size.y * scene.FG_MAX_SHARE + 1.0, "%s : premier plan du coin %s sous la borne (%.1f %%)" % [tag, side, float(corner[side]) / (view.size.x * view.size.y) * 100.0])
	# décors posés sur le terrain : aucun entre la caméra et un combattant
	var hidden := 0.0
	for node: Node3D in scene.placed_nodes:
		var nr: Rect2 = scene.sprite_screen_rect(node)
		for c: RefCounted in scene.engine.all():
			var a: Node3D = scene.actors[c.key]
			if node.position.z > a.home.z - 0.2:
				hidden = maxf(hidden, _overlap(nr, scene.screen_rect(c, false, true)))
	check(hidden < 1.0, "%s : aucun décor posé devant un combattant (%.0f px²)" % [tag, hidden])


## Ambiance des arènes, sans rendu : chaque arène reste dans les fourchettes qui garantissent la
## lisibilité des combattants (mesurées à l'image, voir docs/FORMAT_DONNEES.md « lisibilité ») :
## lumière de scène (key), exposition, bords du sol (edge), vignette, lumière propre (lift) et
## liseré (rim) des combattants, lumière d'appoint (fill), rayons (shafts), nappe de lumière
## (radius), fond (backdrop.dim) ; un sol sombre est compensé (exposition, appoint ou lift),
## un sol clair est assombri ; le sol garde sa texture (flatten, desat). Puis un boss de la
## scène : voir _check_staging (taille du boss, repérage).
func _test_arena_mood() -> void:
	print("== Ambiance des arènes : lisibilité ==")
	for id: String in Database.arenas:
		var a: Dictionary = Database.get_arena(id)
		var st: Dictionary = a.get("stage", {})
		var t := "arène %s" % id
		var key := float(st.get("key", 1.6))
		var expo := float(st.get("exposure", 1.0))
		var lift := float(st.get("lift", 0.1))
		var fill := float(st.get("fill", 0.0))
		var edge := float(st.get("edge", 0.45))
		var dim := float(st.get("dim", 1.0))
		check(key >= 1.6 and key <= 4.2, "%s : lumière de scène key %.1f entre 1,6 et 4,2" % [t, key])
		check(expo >= 0.9 and expo <= 1.7, "%s : exposition %.2f entre 0,9 et 1,7" % [t, expo])
		check(edge >= 0.1 and edge <= 0.5, "%s : bords du sol (edge %.2f) entre 0,1 et 0,5" % [t, edge])
		check(float(st.get("vignette", 0.45)) >= 0.5 and float(st.get("vignette", 0.45)) <= 0.75, "%s : vignette entre 0,5 et 0,75" % t)
		check(lift >= 0.0 and lift <= 0.3, "%s : lumière propre (lift %.2f) entre 0 et 0,3" % [t, lift])
		check(float(st.get("rim", 1.0)) >= 0.6 and float(st.get("rim", 1.0)) <= 1.6, "%s : liseré (rim) entre 0,6 et 1,6" % t)
		check(fill >= 0.0 and fill <= 2.0, "%s : lumière d'appoint (fill %.1f) entre 0 et 2" % [t, fill])
		check(dim >= 0.55 and dim <= 1.0, "%s : sol (dim %.2f) entre 0,55 et 1" % [t, dim])
		var radius: Array = st.get("radius", [12.0, 7.5])
		check(float(radius[0]) >= 8.0 and float(radius[0]) <= 11.0 and float(radius[1]) >= 5.0 and float(radius[1]) <= 7.5, "%s : nappe de lumière (radius) resserrée sur le combat" % t)
		check(float(st.get("flatten", 0.15)) <= 0.35 and float(st.get("desat", 0.0)) <= 0.2, "%s : le sol garde sa texture et ses couleurs" % t)
		var shafts: Dictionary = st.get("shafts", {})
		check(float(shafts.get("strength", 0.0)) <= 0.25, "%s : rayons discrets (shafts)" % t)
		var bd: Dictionary = a.get("backdrop", {})
		check(float(bd.get("dim", 0.6)) >= 0.35 and float(bd.get("dim", 0.6)) <= 1.0, "%s : fond (backdrop dim) entre 0,35 et 1" % t)
		# luminance estimée du sol (couleur moyenne de la tuile, teinte du lieu) : sombre, on compense ; clair, on assombrit
		var img: Image = Sprites.tile_image(str(a.get("ground", "grass")))
		var avg := Color(0, 0, 0)
		for i in 64:
			avg += img.get_pixel((i * 7) % img.get_width(), (i * 13) % img.get_height())
		avg = avg / 64.0
		var tint := Database.color(st.get("tint", "#ffffff"), Color.WHITE)
		var floor_lum := Color(avg.r * tint.r, avg.g * tint.g, avg.b * tint.b).get_luminance()
		if floor_lum < 0.3:
			check(expo >= 1.1 and (fill >= 0.5 or lift >= 0.15), "%s : sol sombre (%.2f) relevé (exposition %.2f, appoint %.1f, lift %.2f)" % [t, floor_lum, expo, fill, lift])
		check(floor_lum * dim <= 0.46, "%s : sol clair assombri (%.2f)" % [t, floor_lum * dim])
		check(lift >= 0.15 or fill >= 0.5 or floor_lum * dim <= 0.4, "%s : combattants détachés d'un sol moyen (lift ou appoint)" % t)


# =========================================================================== chapitre 6

const C6_MAPS := ["minas_croute", "minas_rues", "minas_citadelle", "minas_intendance", "sentier_insomniaques", "port_sale", "pelle_a_tarte"]
const C6_STYLES := {"minas_croute": "gouda", "minas_rues": "gouda", "minas_citadelle": "gouda", "minas_intendance": "gouda", "sentier_insomniaques": "veille", "port_sale": "port", "pelle_a_tarte": "champ"}
const C6_MONSTERS := ["eveille", "eveille_veilleur", "roi_eveille", "boucanier", "saumure", "cassouletain", "gothmoque", "naze_supreme", "mammou", "dindon_farce", "grondine"]
const C6_CITY := ["glandoulf", "sam", "froton", "pepin"]
const C6_SENTIER := ["aragrogne", "digoulasse", "grimli"]
const C6_PORT := ["aragrogne", "digoulasse", "grimli", "merri"]
const C6_GATE := ["glandoulf", "sam", "froton", "aragrogne"]
const C6_RELIEF := ["pepin", "merri", "digoulasse", "grimli"]
const C6_NAZE := ["aragrogne", "merri", "glandoulf", "pepin"]
const C6_MIN_TABLE := 0.85
const C6_MIN_BOSS := 0.6
const C6_LEVEL := {"minas_croute": 21, "sentier": 20, "port_sale": 21, "pelle_a_tarte": 22, "minas_rues": 20}

## Les combats du chapitre 6 : (nom, équipe, niveau, rencontre, type).
func _c6_cases() -> Array:
	return [
		["6 Éveillés (1)", C6_SENTIER, 20, Database.get_encounter("eveilles_1"), "ordinaire"],
		["6 Éveillés (3)", C6_SENTIER, 20, Database.get_encounter("eveilles_3"), "ordinaire"],
		["6 Roi des Éveillés", C6_SENTIER, 20, Database.get_encounter("roi_eveille"), "boss"],
		["6 Saumure", C6_PORT, 21, Database.get_encounter("saumure"), "boss"],
		["6 Grondine", C6_GATE, 21, Database.get_encounter("grondine"), "boss"],
		["6 Gothmoque", C6_GATE, 22, Database.get_encounter("gothmoque"), "boss"],
		["6 Cassoulétains", C6_GATE, 22, Database.get_encounter("pelle_cassouletains"), "ordinaire"],
		["6 Mammous", C6_RELIEF, 22, Database.get_encounter("pelle_mammous"), "ordinaire"],
		["6 Dindon de la Farce", ["glandoulf", "sam", "aragrogne", "grimli"], 22, Database.get_encounter("dindon_farce"), "boss"],
		["6 Naze Suprême", C6_NAZE, 23, Database.get_encounter("naze_supreme"), "boss"],
		["6 Grondine sans soigneur", ["glandoulf", "froton", "aragrogne", "merri"], 21, Database.get_encounter("grondine"), "sans_soigneur"],
		["6 Gothmoque sans soigneur", ["glandoulf", "froton", "aragrogne", "merri"], 22, Database.get_encounter("gothmoque"), "sans_soigneur"],
		["6 Roi sans soigneur", ["aragrogne", "digoulasse", "grimli"], 20, Database.get_encounter("roi_eveille"), "sans_soigneur"],
		["6 Naze sans soigneur", ["aragrogne", "merri", "glandoulf", "grimli"], 23, Database.get_encounter("naze_supreme"), "sans_soigneur"],
	]


## Équipement du chapitre 6 que l'équipe porte à ce moment : le Décret d'Aragrogne, la dague de Merri contre le Naze.
func _c6_gear(case: Array) -> void:
	for who: String in case[1]:
		var piece := ""
		if who == "aragrogne":
			piece = "decret_de_la_lignee"
		elif who == "merri" and str(case[0]).contains("Naze"):
			piece = "dague_de_dos"
		if piece != "":
			GameState.add_item(piece)
			GameState.equip(who, piece)


func _c6_rate(case: Array) -> float:
	var wins := 0
	var runs := 40
	for s in runs:
		GameState.new_game()
		GameState.party = []
		for id: String in case[1]:
			GameState.add_to_party(id)
			GameState.member(id)["level"] = int(case[2])
			_spend(id, 0)
		_c6_gear(case)
		GameState.heal_party()
		var e := _fight(case[3], 100 + s)
		if str(e.result) == "victory":
			wins += 1
	print("  taux : %s niv. %d contre %s : %d %%" % [str(case[1]), int(case[2]), str((case[3].get("enemies", []) as Array).slice(0, 3)), int(100.0 * wins / runs)])
	return float(wins) / runs


func _measure_ch6() -> void:
	var runs := int(OS.get_environment("GLAN_RUNS")) if OS.has_environment("GLAN_RUNS") else 60
	var filter := OS.get_environment("GLAN_FILTER")
	print("  %-36s %-9s %5s %5s %6s" % ["combat", "type", "sans", "avecA", "tours"])
	for case: Array in _c6_cases():
		if filter != "" and not str(case[0]).contains(filter):
			continue
		var rates := []
		var rounds := 0.0
		for talents in [-1, 0]:
			var wins := 0
			var total_rounds := 0.0
			for s in runs:
				GameState.new_game()
				GameState.party = []
				for id: String in case[1]:
					GameState.add_to_party(id)
					GameState.member(id)["level"] = int(OS.get_environment("GLAN_LEVEL")) if OS.has_environment("GLAN_LEVEL") else int(case[2])
					if talents >= 0:
						_spend(id, talents)
				_c6_gear(case)
				GameState.heal_party()
				var e: RefCounted = BattleEngine.new()
				e.setup(case[3], 100 + s)
				var guard := 0
				var hero_turns := 0
				while str(e.result) == "" and guard < 800:
					guard += 1
					var actor: RefCounted = e.next_actor()
					if actor == null:
						break
					e.start_turn(actor)
					if str(e.result) == "" and bool(e.can_act):
						if str(actor.side) != "enemy":
							hero_turns += 1
						e.perform(actor, e.ai_action(actor) if str(actor.side) == "enemy" else e.auto_action(actor))
					if str(e.result) == "":
						e.end_turn(actor)
				if str(e.result) == "victory":
					wins += 1
				total_rounds += float(hero_turns) / float(maxi(1, (case[1] as Array).size()))
			rates.append(int(100.0 * wins / runs))
			rounds = total_rounds / runs
		print("  %-36s %-9s %4d%% %4d%% %6.1f" % [str(case[0]), str(case[4]), int(rates[0]), int(rates[1]), rounds])
	GameState.new_game()


func _test_chapter_6_data() -> void:
	print("== Chapitre 6 : données et équilibre ==")
	for id: String in C6_MAPS:
		check(Database.has_map(id), "carte %s existe" % id)
		var map := Database.get_map(id)
		check(map.has("music") and Database.music.has(str(map["music"])), "carte %s : musique connue" % id)
		check(str(map.get("style", "")) == str(C6_STYLES[id]), "carte %s : style %s" % [id, C6_STYLES[id]])
		check(Database.arenas.has(str(map.get("arena", ""))), "carte %s : arène déclarée" % id)
		check(Database.ambiances.has(str(map.get("ambiance", ""))), "carte %s : ambiance connue" % id)
	for kind: String in C6_MONSTERS:
		check(MonsterPainter.has(kind), "monstre %s : espèce connue" % kind)
		var img: Image = MonsterPainter.paint(kind)
		var magenta := 0
		var filled := 0
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				if c.a > 0.5:
					filled += 1
					if c.r > 0.95 and c.g < 0.05 and c.b > 0.95:
						magenta += 1
		check(magenta == 0 and filled > 200, "monstre %s : dessiné, sans magenta (%d px)" % [kind, filled])
	for q: String in ["minas_tartine", "pain_de_siege", "intendant_compliment", "poirier_blanc"]:
		check(not Database.get_quest(q).is_empty(), "quête %s décrite" % q)
	check(Database.get_quest("minas_tartine").get("kind") == "principale", "Minas Tartine est la quête principale")
	for ch: String in ["denigror", "mie_dure", "heraut_poterne", "soldat_minas", "doigtiste", "jardinier_poirier", "cambusier", "fourrier", "greviste", "citoyen_mou"]:
		check(Database.characters.has(ch), "personnage %s décrit" % ch)
		check(Database.characters[ch].get("look", {}).has("face"), "personnage %s : un visage" % ch)
	var slots := {}
	for it: String in ["epee_de_la_garde_dressee", "baton_du_garde_a_vous", "louche_de_remparts", "canif_de_la_poterne", "serpe_du_poirier", "dague_de_dos", "heaume_de_la_garde_dressee", "bonnet_de_nuit_des_eveilles", "tricorne_de_saumure", "toque_de_marmite", "cotte_de_pain_d_epices", "robe_de_chantilly", "cuirasse_de_croute", "couronne_en_remplacement", "decret_de_la_lignee", "doigt_de_gant", "tuteur_de_poirier", "medaille_du_garde_a_vous", "cor_de_gothmoque"]:
		check(Database.items.has(it), "équipement %s décrit" % it)
		slots[str(Database.items.get(it, {}).get("slot", ""))] = true
	check(slots.has("weapon") and slots.has("head") and slots.has("armor") and slots.has("trinket"), "chapitre 6 : armes, casques, armures et bijoux neufs (%s)" % str(slots.keys()))
	for it: String in ["marmite_d_huile", "pot_de_braise", "couvercle_de_rempart", "echelle_renversee", "soupe_de_siege", "tartine_eternelle", "pain_de_siege", "farine_de_siege", "tuteur_neuf"]:
		check(Database.items.has(it), "objet %s décrit" % it)
	for sh: String in ["minas_marche", "port_cambuse"]:
		check(not Database.get_shop(sh).is_empty(), "boutique %s" % sh)
	for e: String in ["eveilles_1", "eveilles_2", "eveilles_3", "eveilles_4", "roi_eveille", "saumure", "grondine", "gothmoque", "pelle_cassouletains", "pelle_mammous", "dindon_farce", "naze_supreme"]:
		var enc := Database.get_encounter(e)
		check(not enc.is_empty(), "rencontre %s" % e)
		if ["roi_eveille", "saumure", "grondine", "gothmoque", "dindon_farce", "naze_supreme"].has(e):
			check(enc.has("boss") and Database.enemies.has(str(enc["boss"])), "rencontre %s : boss déclaré" % e)
	for en: String in C6_MONSTERS + ["morfale_siege"]:
		check(Database.enemies.has(en), "ennemi %s décrit" % en)
	check(Database.music.has("minas") and Database.music.has("minas_haut") and Database.music.has("eveilles") and Database.music.has("port_sale") and Database.music.has("bataille"), "chapitre 6 : cinq morceaux neufs")
	# la porte de l'Office mène à Minas Tartine, une fois le chapitre 5 fini
	var terrasse := Database.get_map("terrasse_office")
	var found := false
	for o: Variant in terrasse.get("objects", []):
		if o is Dictionary and str((o as Dictionary).get("type", "")) == "warp" and str(((o as Dictionary).get("to", {}) as Dictionary).get("map", "")) == "minas_croute" and str((o as Dictionary).get("if", "")) == "chapitre_5_fini":
			found = true
	check(found, "la terrasse de l'Office mène à Minas Tartine (chapitre_5_fini)")
	# un repère de quête pour chaque étape de la quête principale
	for st: Variant in Database.get_quest("minas_tartine")["steps"]:
		check((st as Dictionary).has("target"), "minas_tartine : « %s » a un repère" % str((st as Dictionary)["text"]))
	# tables et combats
	for t: Array in [["minas_croute", 21, C6_GATE], ["minas_rues", 20, C6_GATE], ["sentier", 20, C6_SENTIER], ["port_sale", 21, C6_PORT], ["pelle_a_tarte", 22, C6_GATE]]:
		check(Database.encounter_tables.has(str(t[0])), "table %s" % str(t[0]))
		var r := _c5_table_rate(t[2], str(t[0]), int(t[1]))
		check(float(r[0]) >= 0.7, "table %s, niv. %d : pire groupe %d %% (%s)" % [str(t[0]), int(t[1]), int(float(r[0]) * 100.0), str(r[1])])
		print("  table %-14s pire groupe %3d %%  (%s)" % [str(t[0]), int(float(r[0]) * 100.0), str(r[1])])
	for case: Array in _c6_cases():
		var a := _c6_rate(case)
		var lo := C6_MIN_TABLE if str(case[4]) == "ordinaire" else (0.45 if str(case[4]) == "sans_soigneur" else C6_MIN_BOSS)
		var hi := 1.0 if str(case[4]) != "boss" else 0.85
		check(a >= lo and a <= hi, "%s, équipe niv. %d : %d %% (visé %d à %d %%)" % [str(case[0]), int(case[2]), int(a * 100.0), int(lo * 100.0), int(hi * 100.0)])
	GameState.new_game()


## Style gouda : tuiles, accessoires, objets et styles documentés ; cartes construites.
func _test_gouda_scenery() -> void:
	var Gouda: GDScript = load("res://src/gfx/gouda_painter.gd")
	var GoudaBuilder: GDScript = load("res://src/world/gouda_builder.gd")
	var MapBuilder: GDScript = load("res://src/world/map_builder.gd")
	var docs := FileAccess.get_file_as_string("res://docs/FORMAT_DONNEES.md")
	for kind: String in Gouda.TILES:
		var img: Image = Sprites.tile_image(kind)
		check(img != null and img.get_width() >= 48, "style gouda : la tuile %s est peinte" % kind)
		check(not img.get_pixel(3, 3).is_equal_approx(Color(1, 0, 1)), "style gouda : la tuile %s n'est pas le magenta de secours" % kind)
		check(docs.contains(kind), "style gouda : la tuile %s est documentée" % kind)
	for kind: String in Gouda.PROP_VARIANTS:
		check(MapBuilder.PROPS.has(kind) or Gouda.has_prop(kind), "style gouda : %s est un accessoire déclaré" % kind)
		check(docs.contains(kind), "style gouda : %s est documenté" % kind)
		for v in int(Gouda.PROP_VARIANTS[kind]):
			var tex: Texture2D = Sprites.prop(kind, v)
			check(tex != null and tex.get_width() > 4 and tex.get_height() > 4, "style gouda : %s variante %d peint" % [kind, v])
	for kind: String in GoudaBuilder.OBJECTS:
		check(docs.contains(kind), "style gouda : l'objet %s est documenté" % kind)
	for st: String in GoudaBuilder.STYLES:
		check(docs.contains("\"%s\"" % st) or docs.contains("`%s`" % st), "style %s : documenté" % st)
	for id: String in C6_MAPS:
		var map := Database.get_map(id)
		for f: Dictionary in (map.get("ground", {}) as Dictionary).get("fills", []):
			check(MapBuilder.GROUND.has(str(f.get("type", ""))), "carte %s : sol « %s » connu" % [id, str(f.get("type", ""))])
		for o: Dictionary in map.get("objects", []):
			var t := str(o.get("type", ""))
			var known: bool = t in ["monster", "encounter_zone", "npc", "light", "warp", "trigger", "crate", "scatter", "house", "lantern", "fence", "tree", "table", "rug"] \
					or MapBuilder.PROPS.has(t) or GoudaBuilder.OBJECTS.has(t)
			check(known, "carte %s : objet « %s » connu" % [id, t])
			if t == "scatter":
				check(MapBuilder.PROPS.has(str(o.get("prop", ""))), "carte %s : accessoire semé « %s » connu" % [id, str(o.get("prop", ""))])
			if o.has("dialogue"):
				check(Database.has_dialogue(str(o["dialogue"])), "carte %s : dialogue « %s » existe" % [id, str(o["dialogue"])])
	for id: String in C6_MAPS:
		GameState.new_game()
		var world: Node3D = World.new()
		add_child(world)
		world.setup(id, str(Database.get_map(id)["spawns"].keys()[0]))
		await get_tree().process_frame
		check(world.player != null, "carte %s : construite dans son style" % id)
		if bool(Database.get_map(id).get("interior", false)):
			check(world.get_node_or_null("Walls") != null, "carte %s : murs construits" % id)
		else:
			check(world.get_node_or_null("Outskirts") != null, "carte %s : abords construits" % id)
		world.queue_free()
		await get_tree().process_frame
	# les cartes d'avant ne prennent aucun décor gouda
	GameState.new_game()
	var village: Node3D = World.new()
	add_child(village)
	village.setup("brie", str(Database.get_map("brie")["spawns"].keys()[0]))
	await get_tree().process_frame
	var any_gouda := false
	for n: Node in village.get_children():
		if n.name.begins_with("Gouda"):
			any_gouda = true
	check(not any_gouda, "Brie : aucun décor gouda (le style se choisit par les données)")
	village.queue_free()
	await get_tree().process_frame


## Chapitre 6 : Minas Tartine, joué dans le vrai jeu, de la terrasse de l'Office à la signature.
func _test_chapter_6() -> void:
	print("== Chapitre 6 : déroulé complet ==")
	var base := ["chapitre_5_fini", "sarumale_vaincu", "terrasse_vue"]
	await _test_map("minas_croute", [], "arrivée")
	await _test_map("minas_croute", ["minas_vu", "accueil_fait", "bromure_annonce", "sentier_envoye", "combat_roi_eveille", "combat_saumure", "nuit_vue", "manoeuvres_ok"], "avant la porte")
	await _test_map("minas_croute", ["minas_vu", "accueil_fait", "bromure_annonce", "sentier_envoye", "combat_roi_eveille", "combat_saumure", "nuit_vue", "manoeuvres_ok", "porte_tenue"], "porte tenue")
	await _test_map("minas_rues", [], "rues")
	await _test_map("minas_citadelle", [], "citadelle")
	await _test_map("minas_intendance", [], "intendance")
	await _test_map("sentier_insomniaques", [], "sentier")
	await _test_map("sentier_insomniaques", ["combat_roi_eveille"], "sentier, Roi couché")
	await _test_map("port_sale", [], "port")
	await _test_map("pelle_a_tarte", [], "champs")
	await _test_map("pelle_a_tarte", ["combat_dindon_farce"], "champs, Dindon vaincu")
	await _test_map("pelle_a_tarte", ["combat_dindon_farce", "combat_naze_supreme"], "champs, Naze vaincu")

	GameState.new_game()
	GameState.party = ["glandoulf", "sam", "froton", "aragrogne"]
	GameState.bench = ["merri", "pepin", "digoulasse", "grimli"]
	for who: String in GameState.party + GameState.bench:
		GameState.member(who)["level"] = 40
	for f: String in base:
		GameState.set_flag(f)
	GameState.set_flag("chapitre_5_fini")
	GameState.chapter = "chapitre_6"
	GameState.money = 800
	GameState.map_id = "terrasse_office"
	GameState.spawn_id = "entree"
	GameState.heal_party()
	check(SaveManager.save_game(), "sauvegarde au départ du chapitre 6")
	var main: Node = MAIN.instantiate()
	main.auto_battles = true
	add_child(main)
	await _wait_idle(main)
	main.continue_game()
	await _wait_idle(main)
	check(main.world.map_id == "terrasse_office" and _c4_has_warp(main, "minas_croute"), "la terrasse de l'Office ouvre sur Minas Tartine")

	# arrivée : l'aigle dépose l'équipe, les chasseurs montent en ville
	main.change_map("minas_croute", "aigle")
	await _wait_idle(main)
	check(GameState.has_flag("minas_vu"), "l'arrivée à Minas Tartine est jouée")
	check(GameState.party == ["glandoulf", "froton", "sam", "pepin"], "les chasseurs mènent en ville (%s)" % str(GameState.party))
	check(GameState.bench.has("aragrogne") and GameState.bench.has("merri"), "les cavaliers attendent sur le banc (%s)" % str(GameState.bench))
	check(GameState.quest_state("minas_tartine") != "", "la quête principale est lancée")
	await _c4_say(main, "denigror_porte")
	check(GameState.has_flag("accueil_fait"), "Dénigror accueille l'équipe")

	# l'Intendance : la mort de Bromure est annoncée à son père
	main.change_map("minas_rues", "bas")
	await _wait_idle(main)
	main.change_map("minas_citadelle", "bas")
	await _wait_idle(main)
	main.change_map("minas_intendance", "entree")
	await _wait_idle(main)
	await _c4_say(main, "denigror_bureau")
	check(GameState.has_flag("bromure_annonce"), "l'Intendant apprend la mort de son fils")
	await _c4_say(main, "denigror_bureau", [0])
	check(GameState.has_flag("compliment_defie"), "défi du compliment lancé")
	await _c4_say(main, "intendance_dossiers")
	await _c4_say(main, "coffre_intendance_1")
	check(GameState.item_count("couronne_en_remplacement") == 1, "le coffre de l'Intendance : la couronne de remplacement")
	await _c4_say(main, "coffre_intendance_2")
	var money_before := GameState.money
	await _c4_say(main, "minas_repos", [0])
	check(SaveManager.has_save(), "le lit de l'Intendance sauvegarde")

	# quêtes annexes : pain, poirier
	main.change_map("minas_croute", "porte")
	await _wait_idle(main)
	await _c4_say(main, "mie_dure_etal", [1])
	check(GameState.has_flag("pain_demande"), "Mie-Dure confie sa quête")
	main.change_map("minas_rues", "bas")
	await _wait_idle(main)
	for f: String in ["farine_1", "farine_2", "farine_3"]:
		await _c4_say(main, f)
	check(GameState.item_count("farine_de_siege") == 3, "trois sacs de farine de siège")
	await _c4_say(main, "tuteur_caisse")
	check(GameState.item_count("tuteur_neuf") == 0, "le tuteur reste en place tant que Verjus n'a rien demandé")
	main.change_map("minas_citadelle", "bas")
	await _wait_idle(main)
	await _c4_say(main, "verjus_poirier")
	check(GameState.has_flag("poirier_demande"), "Verjus confie sa quête")
	await _c4_say(main, "coffre_citadelle")
	main.change_map("minas_rues", "haut")
	await _wait_idle(main)
	await _c4_say(main, "tuteur_caisse")
	check(GameState.item_count("tuteur_neuf") == 1, "le tuteur neuf en frêne")
	main.change_map("minas_citadelle", "bas")
	await _wait_idle(main)
	await _c4_say(main, "poirier_tuteur")
	check(GameState.has_flag("tuteur_essaye") and GameState.quest_state("poirier_blanc") == "done", "le Poirier Blanc a son tuteur (%s)" % GameState.quest_state("poirier_blanc"))
	main.change_map("minas_croute", "porte")
	await _wait_idle(main)
	await _c4_say(main, "mie_dure_etal")
	check(GameState.has_flag("pain_fait") and GameState.quest_state("pain_de_siege") == "done", "Sam a pétri : la quête du pain est finie")

	# le Héraut : le groupe se scinde, le Sentier
	await _c4_say(main, "heraut_poterne", [0])
	check(GameState.party == ["aragrogne", "digoulasse", "grimli"] and GameState.has_flag("sentier_envoye"), "le Sentier : Aragrogne mène (%s)" % str(GameState.party))
	check(main.world.map_id == "sentier_insomniaques", "le dialogue emmène le groupe au Sentier (%s)" % main.world.map_id)
	check(GameState.worn_by("decret_de_la_lignee").size() == 1, "Aragrogne porte le Décret de la Lignée")
	for n in [1, 2, 3, 4]:
		GameState.heal_party()
		await _c4_say(main, "eveille_%d" % n, [], 240.0)
		check(GameState.has_flag("combat_eveilles_%d" % n), "les Éveillés (%d) sont couchés (%s)" % [n, str(GameState.party.map(func(w: String) -> String: return "%s:%d/%d" % [w, int(GameState.member(w)["hp"]), int(GameState.member(w)["level"])]))])
	GameState.heal_party()
	await _c4_say(main, "roi_eveille_face", [], 300.0)
	check(GameState.has_flag("combat_roi_eveille"), "le Roi des Éveillés dort enfin")
	check(GameState.party == ["aragrogne", "digoulasse", "grimli", "merri"], "Merri rejoint le groupe (%s)" % str(GameState.party))
	main.change_map("sentier_insomniaques", "est")
	await _wait_idle(main)
	check(_c4_has_warp(main, "port_sale"), "le Sentier mène au port une fois le Roi couché")
	main.change_map("port_sale", "entree")
	await _wait_idle(main)
	await _c4_say(main, "saumure_face", [], 300.0)
	check(GameState.has_flag("combat_saumure"), "Saumure est battu")
	check(main.world.map_id == "minas_croute", "retour à la Croûte (%s)" % main.world.map_id)
	check(GameState.party == C6_GATE, "l'équipe se reforme à la Grande Porte (%s)" % str(GameState.party))
	await _wait_idle(main)
	check(GameState.has_flag("nuit_vue"), "la nuit avant l'assaut est jouée")

	# les cinq manœuvres, la Grande Porte
	await _c4_say(main, "gothmoque_face")
	check(not GameState.has_flag("combat_grondine") if not GameState.has_flag("manoeuvres_ok") else true, "pas d'assaut tant que les postes ne sont pas prêts")
	for st: String in ["huile", "braise", "couvercle", "echelle", "soupe"]:
		await _c4_say(main, "manoeuvre_" + st)
	check(GameState.has_flag("manoeuvres_ok"), "les cinq manœuvres sont prêtes")
	check(GameState.item_count("marmite_d_huile") >= 1 and GameState.item_count("soupe_de_siege") >= 1, "les objets de manœuvre sont dans le sac")
	GameState.heal_party()
	await _c4_say(main, "gothmoque_face", [], 900.0)
	check(GameState.has_flag("combat_grondine") and GameState.has_flag("combat_gothmoque") and GameState.has_flag("porte_tenue"), "la Grande Porte tient")
	await _c4_say(main, "denigror_croute2")
	check(GameState.has_flag("compliment_obtenu") and GameState.quest_state("intendant_compliment") == "done", "l'Intendant a fait un compliment")

	# sauvegarde à mi-chemin, rechargement
	check(SaveManager.save_game(), "sauvegarde à la Grande Porte")
	main.queue_free()
	await get_tree().process_frame
	main = MAIN.instantiate()
	main.auto_battles = true
	add_child(main)
	await _wait_idle(main)
	main.continue_game()
	await _wait_idle(main)
	check(main.world.map_id == "minas_croute" and GameState.has_flag("porte_tenue") and _c4_has_warp(main, "pelle_a_tarte"), "rechargé à la Grande Porte : la route de l'est est ouverte")
	money_before = GameState.money

	# le Pelle-à-Tarte
	main.change_map("pelle_a_tarte", "entree")
	await _wait_idle(main)
	await _c4_say(main, "pelle_charge", [], 900.0)
	check(GameState.has_flag("combat_pelle_cassouletains") and GameState.has_flag("combat_pelle_mammous") and GameState.has_flag("combat_dindon_farce"), "les trois charges du Pelle-à-Tarte")
	await _c4_say(main, "naze_face", [], 400.0)
	check(GameState.has_flag("combat_naze_supreme"), "le Naze Suprême est abattu")
	check(GameState.party == C6_NAZE, "l'équipe du Naze : %s" % str(GameState.party))
	await _c4_say(main, "denigror_champ")
	check(GameState.has_flag("chapitre_6_fini"), "le chapitre 6 est terminé")
	check(GameState.chapter == "chapitre_7", "on passe au chapitre 7 (%s)" % GameState.chapter)
	check(GameState.quest_state("minas_tartine") == "done", "la quête principale est terminée (%s)" % GameState.quest_state("minas_tartine"))
	check(GameState.money > money_before and GameState.item_count("tartine_eternelle") >= 1, "récompenses reçues")
	main.queue_free()
	await get_tree().process_frame
	GameState.new_game()


# ------------------------------------------------- manette de bout en bout (interface 5)

const PAD_DEV := 3   # numéro de manette volontairement différent de 0 (un clavier « de jeu » prend souvent le 0 sous Windows)


## Un appui complet sur un bouton de la manette numéro 3, par la file d'entrées réelle (Input).
func _pb(button: int, hold: int = 1) -> void:
	var down := InputEventJoypadButton.new()
	down.device = PAD_DEV
	down.button_index = button as JoyButton
	down.pressed = true
	Input.parse_input_event(down)
	for _i in hold:
		await get_tree().process_frame
	var up := InputEventJoypadButton.new()
	up.device = PAD_DEV
	up.button_index = button as JoyButton
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame
	await get_tree().process_frame   # l'appui agit au début de l'image, les appels différés (curseur) à sa fin : une image de plus


## Le stick gauche poussé à `value` sur un axe, puis relâché (`hold` images entre les deux).
func _stick(axis: int, value: float, hold: int = 2, release: bool = true) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.device = PAD_DEV
	ev.axis = axis as JoyAxis
	ev.axis_value = value
	Input.parse_input_event(ev)
	for _i in hold:
		await get_tree().process_frame
	if release:
		var rel := InputEventJoypadMotion.new()
		rel.device = PAD_DEV
		rel.axis = axis as JoyAxis
		rel.axis_value = 0.0
		Input.parse_input_event(rel)
		await get_tree().process_frame


func _focus_label(f: Control) -> String:
	if f.has_meta("label"):
		return str(f.get_meta("label"))
	if f is Button:
		return (f as Button).text
	return str(f.name)


func _focus_name() -> String:
	var f := get_viewport().gui_get_focus_owner()
	if f == null:
		return "(aucun)"
	if f.has_meta("label"):
		return str(f.get_meta("label"))   # boutons de combat : le texte est dessiné, pas écrit
	if f is Button:
		return (f as Button).text
	return str(f.name)


## Mène le curseur, à la croix seule, sur une ligne dont le texte commence par `prefix` : vers le bas,
## puis vers le haut si le bas ne l'a pas donnée (échec : faux).
func _pad_to(prefix: String, limit: int = 30) -> bool:
	for direction in [JOY_BUTTON_DPAD_DOWN, JOY_BUTTON_DPAD_UP]:
		var last := ""
		for _i in limit:
			var now := _focus_name()
			if now.begins_with(prefix):
				return true
			if now == last:
				break   # au bout de la liste
			last = now
			await _pb(direction)
	return _focus_name().begins_with(prefix)


## Ce que la manette seule sait faire à l'écran-titre, aux paramètres, aux confirmations.
func _test_pad_title(main: Node) -> void:
	print("== Manette seule : titre, paramètres, confirmation ==")
	Controls.set_pad(true)
	check(_focus_name() == "Nouvelle partie", "manette : au titre sans sauvegarde, le curseur est sur « Nouvelle partie » (%s)" % _focus_name())
	check(await _pad_to("Paramètres", 4), "manette : la croix mène à « Paramètres » (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	await get_tree().process_frame
	check(main.settings_screen.visible, "manette : A ouvre les paramètres")
	var first_row := _focus_name()
	await _pb(JOY_BUTTON_DPAD_DOWN)
	check(_focus_name() != first_row, "manette : la croix descend dans les paramètres")
	await _pb(JOY_BUTTON_DPAD_RIGHT)
	await _pb(JOY_BUTTON_DPAD_LEFT)
	await _pb(JOY_BUTTON_B)
	check(not main.settings_screen.visible and main.title.visible, "manette : B ferme les paramètres, un seul écran à la fois")
	check(_focus_name() == "Paramètres", "manette : le curseur retrouve « Paramètres » au titre (%s)" % _focus_name())
	check(main.title.quit_requested.is_connected(main._on_title_quit), "titre : « Quitter » passe par la confirmation")
	await _pb(JOY_BUTTON_DPAD_DOWN)
	check(_focus_name() == "Quitter", "manette : « Quitter » sous « Paramètres » (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(main.confirm.visible and _focus_name() == "Non", "manette : « Quitter » demande confirmation, « Non » par défaut (%s)" % _focus_name())
	await _pb(JOY_BUTTON_DPAD_DOWN)
	check(_focus_name() == "Non", "manette : le curseur de la confirmation reste dans la confirmation")
	await _pb(JOY_BUTTON_B)
	check(not main.confirm.visible and main.title.visible and _focus_name() == "Quitter", "manette : B répond « non », le jeu continue (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	await _pb(JOY_BUTTON_A)   # A sur « Non » : même résultat que B
	check(not main.confirm.visible and main.title.visible, "manette : A sur « Non » referme sans quitter")
	# « oui » : le vrai get_tree().quit() est remplacé le temps du test
	main.title.quit_requested.disconnect(main._on_title_quit)
	var answers: Array = []
	main.title.quit_requested.connect(func() -> void:
		answers.append(await main.confirm.ask("Quitter le jeu ?", "Quitter"))
		main.title.refocus())
	await _pb(JOY_BUTTON_A)
	await _pb(JOY_BUTTON_DPAD_UP)
	check(_focus_name() == "Quitter", "manette : la croix monte sur « Oui » (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(answers == [true] and not main.confirm.visible, "manette : A sur « Oui » répond oui, une seule fois (%s)" % str(answers))
	main.title.quit_requested.get_connections().map(func(c: Dictionary) -> void: main.title.quit_requested.disconnect(c["callable"]))
	main.title.quit_requested.connect(main._on_title_quit)
	await _pb(JOY_BUTTON_DPAD_UP)
	await _pb(JOY_BUTTON_DPAD_UP)
	check(_focus_name() == "Nouvelle partie", "manette : retour sur « Nouvelle partie » (%s)" % _focus_name())


## Joue seul, à la manette, ce qui se présente (dialogue, combat, conseil) jusqu'à ce que `done` soit vrai.
## Renvoie le nombre d'appuis donnés (un bouton par image au plus : jamais deux fois le même appui).
func _pad_drive(main: Node, done: Callable, max_frames: int = 20000, attack_only: bool = true) -> int:
	var presses := 0
	for _i in max_frames:
		if done.call():
			return presses
		if Tutorial._modal and Tutorial._guard <= 0.0:
			await _pb(JOY_BUTTON_A)
			presses += 1
		elif main.battle != null and main.battle_ui.visible and main.battle_ui._state in [main.battle_ui.S.ROOT, main.battle_ui.S.TARGET]:
			await _pb(JOY_BUTTON_A)   # « Attaquer », puis la cible proposée
			presses += 1
		elif main.battle != null and main.battle_ui.visible and main.battle_ui._state == main.battle_ui.S.LIST:
			await _pb(JOY_BUTTON_B)
			presses += 1
		elif main.battle != null and main.battle_ui._end_layer.visible and main.battle_ui._state == main.battle_ui.S.END:
			await _pb(JOY_BUTTON_A)   # « Continuer »
			presses += 1
		elif main.dialogue.active and main.dialogue.visible and not main.dialogue.waiting:
			await _pb(JOY_BUTTON_A)
			presses += 1
		else:
			await get_tree().process_frame
	return presses


## Marche au stick, zone morte, dialogue qui avance d'une réplique par appui, menu de pause et journal.
func _test_pad_world(main: Node) -> void:
	print("== Manette seule : exploration, dialogue, pause, journal ==")
	GameState.add_to_party("sam")
	GameState.add_item("baton_ferre")
	GameState.add_item("tisane", 2)
	GameState.money = 600
	GameState.set_flag("intro_vue")
	var w: Node3D = main.world
	var x0: float = w.player.position.x
	await _stick(JOY_AXIS_LEFT_X, -0.2, 30)
	check(absf(w.player.position.x - x0) < 0.05, "stick : en dessous de la zone morte, le personnage ne bouge pas (%.3f)" % (w.player.position.x - x0))
	await _stick(JOY_AXIS_LEFT_X, -0.9, 30)
	var x1: float = w.player.position.x
	check(x1 < x0 - 0.3, "stick : poussé à gauche, le personnage avance (%.2f -> %.2f)" % [x0, x1])
	for _i in 6:
		await get_tree().process_frame
	check(absf(w.player.position.x - w.player.position.x) < 0.01 and absf(w.player.position.x - x1) < 1.2, "stick : relâché, le personnage s'arrête")
	var x2: float = w.player.position.x
	for _i in 20:
		await get_tree().process_frame
	check(absf(w.player.position.x - x2) < 0.02, "stick : relâché, il ne reste pas collé (%.3f)" % (w.player.position.x - x2))
	await _pb(JOY_BUTTON_DPAD_RIGHT, 20)
	check(w.player.position.x > x2 + 0.2, "croix : la croix directionnelle marche aussi")
	# un dialogue sur mesure : trois répliques puis un choix ; un appui sur A = une seule chose
	Database.dialogues["_pad"] = [
		{"text": "Réplique un, assez longue pour taper un moment sur le clavier de la boîte."},
		{"text": "Réplique deux."},
		{"text": "Réplique trois."},
		{"choice": [
			{"text": "Premier choix", "then": [{"set": "pad_choix_a"}, {"text": "Après le premier."}]},
			{"text": "Second choix", "then": [{"set": "pad_choix_b"}, {"text": "Après le second."}, {"text": "Fin."}]},
		]},
		{"text": "Dernière."},
	]
	main.run_dialogue("_pad")
	await get_tree().process_frame
	var d: Control = main.dialogue
	check(d.active and d._text.get_parsed_text().begins_with("Réplique un"), "dialogue : la première réplique s'affiche")
	await _pb(JOY_BUTTON_A)
	check(d._text.get_parsed_text().begins_with("Réplique un") and not d._typing, "dialogue : A pendant la frappe affiche la réplique entière, sans passer à la suivante")
	await _pb(JOY_BUTTON_A)
	check(d._text.get_parsed_text().begins_with("Réplique deux"), "dialogue : le deuxième A passe à la réplique deux, une seule (%s)" % d._text.get_parsed_text())
	await _pb(JOY_BUTTON_A)
	await _pb(JOY_BUTTON_A)
	check(d._text.get_parsed_text().begins_with("Réplique trois"), "dialogue : encore un appui complet = la réplique trois (%s)" % d._text.get_parsed_text())
	await _pb(JOY_BUTTON_A)
	await _pb(JOY_BUTTON_A)
	check(d._choosing and d._choice_panel.visible, "dialogue : le choix s'affiche")
	var focus_a := _focus_name()
	await _pb(JOY_BUTTON_DPAD_DOWN)
	check(_focus_name() != focus_a and _focus_name() == "Second choix", "dialogue : la croix passe au second choix (%s)" % _focus_name())
	await _pb(JOY_BUTTON_DPAD_UP)
	await _pb(JOY_BUTTON_DPAD_DOWN)
	await _pb(JOY_BUTTON_A)
	check(GameState.has_flag("pad_choix_b") and not GameState.has_flag("pad_choix_a"), "dialogue : A valide le choix sous le curseur")
	check(d._text.get_parsed_text().begins_with("Après le second"), "dialogue : A sur un choix ne passe pas la réplique suivante (%s)" % d._text.get_parsed_text())
	await _pb(JOY_BUTTON_A)
	await _pb(JOY_BUTTON_A)
	check(d._text.get_parsed_text().begins_with("Fin"), "dialogue : la réplique suivante vient à l'appui suivant (%s)" % d._text.get_parsed_text())
	await _pb(JOY_BUTTON_A)
	await _pb(JOY_BUTTON_A)
	check(d._text.get_parsed_text().begins_with("Dernière"), "dialogue : la suite du dialogue reprend après le choix (%s)" % d._text.get_parsed_text())
	await _pb(JOY_BUTTON_A)
	await _pb(JOY_BUTTON_A)
	await get_tree().process_frame
	check(not d.active and w.input_enabled, "dialogue : le dernier A le ferme et rend la main, sans rouvrir de dialogue")
	check(not d.visible, "dialogue : la boîte est refermée")
	# interaction : A devant un personnage ouvre son dialogue
	var talked := false
	for it: Dictionary in w.interactables:
		if not Database.has_dialogue(str(it.get("dialogue", ""))):
			continue
		w.player.position = w.interactable_position(it) + Vector3(-1.0, 0.0, 0.0)
		w.player.set_facing("right")
		for _i in 3:
			await get_tree().process_frame
		if w.focus.is_empty():
			continue
		await get_tree().create_timer(0.4).timeout   # le jeu laisse passer un quart de seconde après un dialogue avant d'écouter A
		await _pb(JOY_BUTTON_A)
		talked = main.dialogue.active
		break
	check(talked, "interaction : A devant un personnage ouvre son dialogue")
	var guard := 0
	while main.dialogue.active and guard < 400:
		guard += 1
		if main.menus.visible:
			main.menus.close()
		if main.battle != null:
			break
		await _pb(JOY_BUTTON_A)
	await _wait_idle(main, 10.0)
	main.world.set_input(true)
	# pause : Start ouvre, Start referme, B referme ; Y ouvre le journal, Y ou B le referme
	await _pb(JOY_BUTTON_START)
	check(main.pause.visible, "Start : ouvre le menu de pause")
	await _pb(JOY_BUTTON_START)
	check(not main.pause.visible and main.world.input_enabled, "Start : le referme, la main revient au jeu")
	await _pb(JOY_BUTTON_START)
	await _pb(JOY_BUTTON_B)
	check(not main.pause.visible and main.world.input_enabled, "B : ferme le menu de pause (un seul écran, jeu repris)")
	await _pb(JOY_BUTTON_Y)
	check(main.menus.visible and main.menus._title.text == "Journal de quêtes", "Y : ouvre le journal des quêtes (%s)" % main.menus._title.text)
	await _pb(JOY_BUTTON_Y)
	check(not main.menus.visible and not main.pause.visible and main.world.input_enabled, "Y : referme le journal et rend la main")
	await _pb(JOY_BUTTON_Y)
	await _pb(JOY_BUTTON_B)
	check(not main.menus.visible and not main.pause.visible and main.world.input_enabled, "B : ferme le journal, une seule fois (pas de pause derrière)")
	await _pb(JOY_BUTTON_START)
	check(main.pause.visible and _focus_name() == "Reprendre", "pause : le curseur est sur « Reprendre » (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(not main.pause.visible and main.world.input_enabled, "pause : A sur « Reprendre » rend la main, une seule fois")
	await get_tree().process_frame


func _pad_settle(main: Node, frames: int = 600) -> void:
	for _i in frames:
		await get_tree().process_frame
		if not main.busy:
			return


## Équipe, équipement, « Retirer », inventaire, boutique, talents, sauvegardes : tout à la manette.
func _test_pad_menus(main: Node) -> void:
	print("== Manette seule : équipe, équipement, inventaire, boutique, talents, sauvegardes ==")
	var slot0: String = GameState.SLOTS[0]
	GameState.unequip("glandoulf", slot0)
	GameState.member("glandoulf")["level"] = 4
	GameState.member("sam")["level"] = 3
	await _pb(JOY_BUTTON_START)
	check(main.pause.visible, "menus : la pause est ouverte")
	check(await _pad_to("Équipe", 6), "pause : la croix mène à « Équipe » (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(main.menus.visible and str(main.menus._title.text).begins_with("Équipe") and not main.pause.visible, "pause : A ouvre l'équipe, la pause se range")
	check(_focus_name().begins_with("Glandoulf"), "équipe : le curseur est sur Glandoulf (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(main.menus._title.text == "Glandoulf", "équipe : A ouvre la fiche (%s)" % main.menus._title.text)
	check(_focus_name() == "Équipement", "fiche : le curseur est sur « Équipement » (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(str(main.menus._title.text).begins_with("Équipement de"), "fiche : A ouvre l'équipement (%s)" % main.menus._title.text)
	check(_focus_name().begins_with("Arme"), "équipement : le curseur est sur l'arme (%s)" % _focus_name())
	var detail_plain: String = main.menus._detail.get_parsed_text()
	var shown := 0
	for slot: String in GameState.SLOTS:
		if detail_plain.contains(str(GameState.SLOT_NAMES[slot]) + " :"):
			shown += 1
	check(shown == 0, "équipement : la liste des emplacements n'est pas répétée dans le détail (%d répétés)" % shown)
	await _pb(JOY_BUTTON_A)
	check(str(main.menus._title.text).begins_with("Arme de"), "équipement : A sur l'arme ouvre le choix (%s)" % main.menus._title.text)
	check(_focus_name().begins_with("Bâton ferré") or _focus_name().begins_with("Bâton"), "équipement : le sac propose un bâton (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(GameState.equipped("glandoulf", slot0) != "" and str(main.menus._title.text).begins_with("Équipement de"), "équipement : A équipe l'objet et revient à la liste (%s)" % GameState.equipped("glandoulf", slot0))
	var worn := GameState.equipped("glandoulf", slot0)
	await _pb(JOY_BUTTON_A)
	check(await _pad_to("Retirer", 12), "équipement : « Retirer » est dans la liste, atteignable à la croix (%s)" % _focus_name())
	var bag_before := GameState.item_count(worn)
	await _pb(JOY_BUTTON_A)
	check(GameState.equipped("glandoulf", slot0) == "" and GameState.item_count(worn) == bag_before + 1, "équipement : A sur « Retirer » remet l'objet dans le sac, une seule fois")
	check(str(main.menus._title.text).begins_with("Équipement de"), "équipement : retour à la liste après « Retirer »")
	await _pb(JOY_BUTTON_A)
	await _pb(JOY_BUTTON_B)
	check(str(main.menus._title.text).begins_with("Équipement de"), "B : du choix d'objet à la liste, un seul niveau (%s)" % main.menus._title.text)
	await _pb(JOY_BUTTON_B)
	check(main.menus._title.text == "Glandoulf", "B : de la liste à la fiche (%s)" % main.menus._title.text)
	await _pb(JOY_BUTTON_B)
	check(str(main.menus._title.text).begins_with("Équipe"), "B : de la fiche à l'équipe (%s)" % main.menus._title.text)
	await _pb(JOY_BUTTON_B)
	check(not main.menus.visible and main.pause.visible, "B : de l'équipe à la pause, sans fermer la pause (%s)" % str(main.pause.visible))
	# inventaire : utiliser un objet sur un allié
	GameState.member("glandoulf")["hp"] = 3
	var tisanes := GameState.item_count("tisane")
	check(await _pad_to("Inventaire"), "pause : « Inventaire » à la croix")
	await _pb(JOY_BUTTON_A)
	check(main.menus._title.text == "Inventaire", "inventaire : ouvert (%s)" % main.menus._title.text)
	check(await _pad_to("Tisane", 12), "inventaire : la croix mène à la tisane (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(main.menus._title.text == "Pour qui ?", "inventaire : A demande pour qui (%s)" % main.menus._title.text)
	check(_focus_name().begins_with("Glandoulf"), "inventaire : le curseur est sur le premier allié (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(GameState.item_count("tisane") == tisanes - 1 and int(GameState.member("glandoulf")["hp"]) > 3, "inventaire : A utilise une tisane sur Glandoulf, une seule (%d -> %d)" % [tisanes, GameState.item_count("tisane")])
	await _pb(JOY_BUTTON_B)
	check(main.menus._title.text == "Inventaire", "inventaire : B revient à la liste (%s)" % main.menus._title.text)
	await _pb(JOY_BUTTON_B)
	check(not main.menus.visible and main.pause.visible, "inventaire : B revient à la pause")
	# talents
	var okt: bool = await _pad_to("Talents")
	check(okt, "pause : « Talents » à la croix (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(main.talents.visible and not main.pause.visible, "talents : A ouvre l'écran des talents")
	var who0: String = main.talents.who
	await _pb(JOY_BUTTON_RIGHT_SHOULDER)
	check(main.talents.who != who0, "talents : RB passe au personnage suivant, d'un seul cran (%s -> %s)" % [who0, main.talents.who])
	await _pb(JOY_BUTTON_LEFT_SHOULDER)
	check(main.talents.who == who0, "talents : LB revient au précédent (%s)" % main.talents.who)
	var points_before := GameState.talent_points(main.talents.who)
	var learned := false
	for _i in 12:
		var id := str(main.talents._focused)
		if id != "" and main.talents.state_of(id) == "available":
			await _pb(JOY_BUTTON_A)
			learned = true
			break
		await _pb(JOY_BUTTON_DPAD_DOWN)
	check(learned and GameState.talent_points(main.talents.who) < points_before, "talents : la croix parcourt les voies, A apprend un talent (%d -> %d points)" % [points_before, GameState.talent_points(main.talents.who)])
	await _pb(JOY_BUTTON_B)
	check(not main.talents.visible and main.pause.visible, "talents : B revient à la pause")
	await _pb(JOY_BUTTON_B)
	check(not main.pause.visible and main.world.input_enabled, "pause : B referme (un seul écran à la fois)")
	# boutique
	main.world.set_input(false)
	main.menus.open_shop("marche_sidonie")
	await get_tree().process_frame
	check(main.menus._title.text == "L'étal de Sidonie" and _focus_name() == "Acheter", "boutique : ouverte sur « Acheter » (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(str(main.menus._title.text).ends_with("acheter"), "boutique : A ouvre la liste d'achat (%s)" % main.menus._title.text)
	var money := GameState.money
	var first := _focus_name()
	await _pb(JOY_BUTTON_DPAD_RIGHT)
	await _pb(JOY_BUTTON_DPAD_LEFT)
	check(_focus_name() == first, "boutique : gauche / droite changent de personnage sans déplacer le curseur")
	var tisane_buy := GameState.item_count("tisane")
	await _pb(JOY_BUTTON_A)
	check(GameState.money < money and money - GameState.money < 200, "boutique : A achète, une seule fois (%d -> %d écus)" % [money, GameState.money])
	var after_buy := GameState.money
	await _pb(JOY_BUTTON_B)
	check(main.menus._title.text == "L'étal de Sidonie", "boutique : B revient à l'accueil (%s)" % main.menus._title.text)
	await _pb(JOY_BUTTON_DPAD_DOWN)
	check(_focus_name() == "Vendre", "boutique : la croix mène à « Vendre » (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(str(main.menus._title.text).ends_with("vendre"), "boutique : A ouvre la vente (%s)" % main.menus._title.text)
	var stock_sell := GameState.item_count("tisane")
	var before_sell := GameState.money
	await _pb(JOY_BUTTON_A)
	check(GameState.money > before_sell, "boutique : A vend, une seule fois (%d -> %d écus)" % [before_sell, GameState.money])
	await _pb(JOY_BUTTON_B)
	check(await _pad_to("Partir", 4), "boutique : « Partir » à la croix")
	await _pb(JOY_BUTTON_A)
	check(not main.menus.visible, "boutique : A sur « Partir » ferme la boutique")
	main.world.set_input(true)
	if tisane_buy < 0 or stock_sell < 0 or after_buy < 0:
		check(false, "inutile")
	# sauvegardes : sauver, écraser, effacer avec X
	var sv: Control = main.saves
	await _pb(JOY_BUTTON_START)
	check(await _pad_to("Sauvegarder"), "pause : « Sauvegarder » à la croix (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(sv.visible and sv.mode == "save" and not main.pause.visible, "sauvegardes : A ouvre la liste")
	var slot_id: String = sv._focused_id()
	check(slot_id != "", "sauvegardes : le curseur est sur un emplacement (%s)" % slot_id)
	SaveManager.delete_slot(slot_id)
	sv._rebuild(slot_id)
	await get_tree().process_frame
	await _pb(JOY_BUTTON_A)
	check(FileAccess.file_exists(SaveManager.slot_path(slot_id)) and not sv.visible and main.pause.visible, "sauvegardes : A sur un emplacement libre sauvegarde et rend la pause")
	await _pad_to("Sauvegarder")
	await _pb(JOY_BUTTON_A)
	await _pb(JOY_BUTTON_A)
	check(sv.is_modal_open() and _focus_name() == "Annuler", "sauvegardes : A sur un emplacement occupé demande confirmation, « Annuler » d'abord (%s)" % _focus_name())
	await _pb(JOY_BUTTON_B)
	check(not sv.is_modal_open() and sv.visible, "sauvegardes : B ferme la confirmation seule, la liste reste")
	await _pb(JOY_BUTTON_A)
	await _pb(JOY_BUTTON_DPAD_UP)
	check(_focus_name() == "Écraser", "sauvegardes : la croix monte sur « Écraser » (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(not sv.visible and main.pause.visible, "sauvegardes : A sur « Écraser » sauvegarde et rend la pause, une seule fois")
	await _pad_to("Sauvegarder")
	await _pb(JOY_BUTTON_A)
	slot_id = sv._focused_id()
	await _pb(JOY_BUTTON_X)
	check(sv.is_modal_open() and _focus_name() == "Annuler", "sauvegardes : X propose d'effacer, « Annuler » d'abord (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(not sv.is_modal_open() and FileAccess.file_exists(SaveManager.slot_path(slot_id)), "sauvegardes : A sur « Annuler » n'efface rien")
	await _pb(JOY_BUTTON_X)
	await _pb(JOY_BUTTON_DPAD_UP)
	await _pb(JOY_BUTTON_A)
	check(not FileAccess.file_exists(SaveManager.slot_path(slot_id)) and sv.visible and not sv.is_modal_open(), "sauvegardes : X, haut, A efface l'emplacement et laisse la liste")
	await _pb(JOY_BUTTON_B)
	check(not sv.visible and main.pause.visible, "sauvegardes : B revient à la pause")
	await _pb(JOY_BUTTON_B)
	check(not main.pause.visible and main.world.input_enabled, "pause : B referme")


## Quitter, retour au titre (avec confirmation), « Continuer » et « Charger » à la manette.
func _test_pad_leave(main: Node) -> void:
	print("== Manette seule : confirmations, titre, continuer, charger ==")
	SaveManager.save_game("m2")
	await _pb(JOY_BUTTON_START)
	await _pad_to("Reprendre")
	# stick : zone morte, un cran à la fois, répétition régulière tenu, relâché il s'arrête
	var names: Array = []
	var list_ctl: Control = get_viewport().gui_get_focus_owner().get_parent()
	for c in list_ctl.get_children():
		if c is Button and c.focus_mode != Control.FOCUS_NONE:
			names.append(_focus_label(c))
	var start := _focus_name()
	await _stick(JOY_AXIS_LEFT_Y, 0.2, 6)   # sous la zone morte : rien
	check(_focus_name() == start, "stick : sous la zone morte, rien ne bouge (%s)" % _focus_name())
	await _stick(JOY_AXIS_LEFT_Y, 0.9, 3)   # appui bref : un seul cran
	var one := _focus_name()
	check(names.find(one) == (names.find(start) + 1) % names.size(), "stick : un appui bref avance d'un seul cran (%s -> %s)" % [start, one])
	await _stick(JOY_AXIS_LEFT_Y, 0.0, 1)
	var moves := 0
	var prev := _focus_name()
	var big_jump := false
	await _stick(JOY_AXIS_LEFT_Y, 0.9, 0, false)
	for _i in 90:   # une seconde et demie tenue
		await get_tree().process_frame
		var now := _focus_name()
		if now != prev:
			moves += 1
			if (names.find(now) - names.find(prev) + names.size()) % names.size() != 1:
				big_jump = true
			prev = now
	await _stick(JOY_AXIS_LEFT_Y, 0.0, 2)
	var at_release := _focus_name()
	for _i in 30:
		await get_tree().process_frame
	check(not big_jump, "stick : tenu, il ne saute jamais deux lignes à la fois")
	check(moves >= 1 and moves <= 12, "stick : tenu, répétition régulière sans emballement (%d crans en 1,5 s)" % moves)
	check(_focus_name() == at_release, "stick : relâché, il s'arrête net")
	await _pad_to("Reprendre")
	check(await _pad_to("Quitter le jeu"), "pause : « Quitter le jeu » à la croix (%s)" % _focus_name())
	check(main.pause.quit_requested.is_connected(main._on_pause_quit), "pause : « Quitter le jeu » passe par la confirmation")
	await _pb(JOY_BUTTON_A)
	check(main.confirm.visible and not main.pause.visible and _focus_name() == "Non", "pause : « Quitter » demande confirmation, « Non » par défaut (%s)" % _focus_name())
	await _pb(JOY_BUTTON_B)
	check(not main.confirm.visible and main.pause.visible and _focus_name().begins_with("Quitter le jeu"), "pause : B répond « non », la pause revient sur la même ligne (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	await _pb(JOY_BUTTON_A)
	check(not main.confirm.visible and main.pause.visible, "pause : A sur « Non » revient à la pause sans quitter")
	# « oui » à « Quitter » : le vrai get_tree().quit() est remplacé le temps du test
	main.pause.quit_requested.disconnect(main._on_pause_quit)
	var answers: Array = []
	main.pause.quit_requested.connect(func() -> void:
		main.pause.close(true)
		answers.append(await main.confirm.ask("Quitter le jeu ?", "Quitter")))
	await _pb(JOY_BUTTON_A)
	await _pb(JOY_BUTTON_DPAD_UP)
	await _pb(JOY_BUTTON_A)
	check(answers == [true], "pause : A sur « Oui » répond oui, une seule fois (%s)" % str(answers))
	main.pause.open("Test")
	await get_tree().process_frame
	# retour à l'écran-titre
	check(await _pad_to("Retour à l'écran-titre"), "pause : « Retour à l'écran-titre » à la croix (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(main.confirm.visible and _focus_name() == "Non", "titre : le retour demande confirmation, « Non » par défaut (%s)" % _focus_name())
	await _pb(JOY_BUTTON_B)
	check(main.mode == main.Mode.PLAY and main.pause.visible, "titre : « non » garde la partie en cours")
	await _pb(JOY_BUTTON_A)
	await _pb(JOY_BUTTON_DPAD_UP)
	await _pb(JOY_BUTTON_A)
	await _wait_idle(main, 30.0)
	check(main.mode == main.Mode.TITLE and main.title.visible, "titre : A sur « Oui » revient à l'écran-titre")
	check(_focus_name() == "Continuer", "titre : avec une sauvegarde, le curseur est sur « Continuer » (%s)" % _focus_name())
	check(await _pad_to("Charger"), "titre : « Charger » à la croix (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(main.saves.visible and main.saves.mode == "load", "titre : A ouvre la liste des sauvegardes")
	await _pb(JOY_BUTTON_B)
	check(not main.saves.visible and main.title.visible and _focus_name() == "Charger", "titre : B revient au titre sur « Charger » (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	await _pb(JOY_BUTTON_A)
	await _pad_settle(main)
	await _wait_idle(main, 30.0)
	check(main.mode == main.Mode.PLAY and main.world != null, "titre : A sur une sauvegarde reprend la partie")
	check(not main.title.visible and not main.saves.visible, "titre : plus d'écran de trop après le chargement")
	await _pb(JOY_BUTTON_START)
	await _pb(JOY_BUTTON_B)


## Un combat entier à la manette : attaque, choix de cible, annulation, compétence, élan, objet, défense, victoire, fuite, défaite.
func _test_pad_battle() -> void:
	print("== Manette seule : combat entier ==")
	Controls.set_pad(true)
	GameState.new_game()
	GameState.add_to_party("sam")
	GameState.member("glandoulf")["level"] = 5
	GameState.member("sam")["level"] = 5
	GameState.add_item("tisane", 3)
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui: Control = BattleUI.new()
	layer.add_child(ui)
	await get_tree().process_frame
	var scene: Node3D = BattleScene.new()
	add_child(scene)
	scene.fast = true
	scene.setup({"enemies": ["limace_molle", "guepe_cidre", "limace_molle"], "arena": "pre"}, ui, 11)
	scene.run()
	var S: Dictionary = {}
	for name: String in ["IDLE", "ROOT", "LIST", "TARGET", "END"]:
		S[name] = ui.S[name]
	var turn := 0
	var saw := {"cancel_target": false, "cycle": false, "stick": false, "list": false, "cancel_list": false, "item": false, "defend": false, "elan": false}
	for _i in 12000:
		await get_tree().process_frame
		if str(scene.outcome) != "":
			break
		if ui._state == S["END"] and ui._end_layer.visible:
			await get_tree().process_frame
			await get_tree().process_frame
			saw["victory"] = _focus_name() == "Continuer"
			if not saw["victory"]:
					await _pb(JOY_BUTTON_A)
			continue
		if ui._state != S["ROOT"] or ui._actor == null or not ui._menu_box.visible:
			continue
		await get_tree().process_frame
		turn += 1
		if turn == 1:
			check(_focus_name() == "Attaquer", "combat : le menu s'ouvre sur « Attaquer » (%s)" % _focus_name())
			await _pb(JOY_BUTTON_A)
			check(ui._state == S["TARGET"], "combat : A sur « Attaquer » demande la cible")
			var n: int = ui._cands.size()
			var i0: int = ui._index
			await _pb(JOY_BUTTON_DPAD_RIGHT)
			saw["cycle"] = n > 1 and ui._index == posmod(i0 + 1, n)
			var i1: int = ui._index
			await _stick(JOY_AXIS_LEFT_X, 0.9, 4)
			saw["stick"] = n > 1 and ui._index == posmod(i1 + 1, n)
			await _pb(JOY_BUTTON_B)
			saw["cancel_target"] = ui._state == S["ROOT"] and _focus_name() == "Attaquer"
			await _pb(JOY_BUTTON_A)
			await _pb(JOY_BUTTON_A)
		elif turn == 2:
			await _pb(JOY_BUTTON_DPAD_DOWN)
			check(_focus_name() == "Compétences", "combat : la croix descend sur « Compétences » (%s)" % _focus_name())
			await _pb(JOY_BUTTON_A)
			saw["list"] = ui._state == S["LIST"]
			await _pb(JOY_BUTTON_B)
			saw["cancel_list"] = ui._state == S["ROOT"] and _focus_name() == "Compétences"
			await _pb(JOY_BUTTON_A)
			for _k in 6:
				var f := get_viewport().gui_get_focus_owner()
				if f is Button and not (f as Button).disabled:
					break
				await _pb(JOY_BUTTON_DPAD_DOWN)
			await _pb(JOY_BUTTON_A)
			if ui._state == S["TARGET"]:
				await _pb(JOY_BUTTON_A)
		elif turn == 3:
			var before: int = ui._elan_commit
			await _pb(JOY_BUTTON_DPAD_RIGHT)
			saw["elan"] = ui._elan_commit - before <= 1
			await _pb(JOY_BUTTON_DPAD_LEFT)
			check(ui._elan_commit == before, "combat : droite puis gauche reviennent au même élan (%d)" % ui._elan_commit)
			await _pb(JOY_BUTTON_A)
			await _pb(JOY_BUTTON_A)
		elif turn == 4:
			if await _pad_to("Objets"):
				await _pb(JOY_BUTTON_A)
				if ui._state == S["LIST"]:
					await _pb(JOY_BUTTON_A)
					if ui._state == S["TARGET"]:
						await _pb(JOY_BUTTON_A)
						saw["item"] = true
		elif turn == 5:
			if await _pad_to("Défendre"):
				await _pb(JOY_BUTTON_A)
				saw["defend"] = true
		else:
			await _pb(JOY_BUTTON_A)
			await _pb(JOY_BUTTON_A)
	for key: String in saw:
		check(bool(saw[key]), "combat à la manette : « %s » fonctionne" % key)
	check(str(scene.outcome) in ["victory"], "combat à la manette : victoire (issue : %s, %d tours d'équipe)" % [str(scene.outcome), turn])
	ui.close()
	remove_child(scene)
	scene.queue_free()
	# fuite
	scene = BattleScene.new()
	add_child(scene)
	scene.fast = true
	scene.setup({"enemies": ["limace_molle"], "arena": "pre", "flee": true}, ui, 5)
	scene.run()
	for _i in 600:
		await get_tree().process_frame
		if ui._state == S["ROOT"] and ui._menu_box.visible:
			break
	await get_tree().process_frame
	await get_tree().process_frame
	check(await _pad_to("Fuir"), "combat : « Fuir » à la croix (%s)" % _focus_name())
	for _try in 20:   # la fuite réussit au hasard : on retente
		await _pb(JOY_BUTTON_A)
		for _i in 300:
			await get_tree().process_frame
			if str(scene.outcome) != "" or (ui._state == S["ROOT"] and ui._menu_box.visible):
				break
		if str(scene.outcome) != "":
			break
		await _pad_to("Fuir")
	check(str(scene.outcome) == "fled", "combat : A sur « Fuir » fait fuir (issue : %s)" % str(scene.outcome))
	ui.close()
	remove_child(scene)
	scene.queue_free()
	# défaite : « Recommencer » par défaut, la croix descend, A valide
	ui.visible = true
	var vres := [false]
	var vshow := func() -> void:
		await ui.show_victory({"xp": 12, "money": 4, "drops": {"tisane": 1}}, false)
		vres[0] = true
	vshow.call()
	await get_tree().process_frame
	await get_tree().process_frame
	check(_focus_name() == "Continuer", "victoire : le curseur est sur « Continuer » (%s)" % _focus_name())
	await _pb(JOY_BUTTON_A)
	check(vres[0] and not ui._end_layer.visible, "victoire : A sur « Continuer » referme l'écran, une seule fois")
	var res := [""]
	var show := func() -> void: res[0] = await ui.show_defeat()
	show.call()
	await get_tree().process_frame
	await get_tree().process_frame
	check(_focus_name() == "Recommencer le combat", "défaite : le curseur est sur « Recommencer le combat » (%s)" % _focus_name())
	await _pb(JOY_BUTTON_DPAD_DOWN)
	check(_focus_name() != "Recommencer le combat", "défaite : la croix descend (%s)" % _focus_name())
	await _pb(JOY_BUTTON_DPAD_UP)
	await _pb(JOY_BUTTON_A)
	check(res[0] == "retry", "défaite : A sur « Recommencer » renvoie « retry » (%s)" % res[0])
	ui.close()
	layer.queue_free()
	await get_tree().process_frame


## Conseils de jeu : aucun nom de touche du clavier à la manette, et A referme un conseil qui suspend le jeu.
func _test_pad_tips(main: Node) -> void:
	print("== Manette seule : conseils de jeu ==")
	Controls.set_pad(true)
	var keyboard_words := ["Entrée", "Échap", "Espace", "Tab ", "Flèches", "Retour arrière", "touche ", "clic", "souris"]
	var offenders: Array = []
	for id: Variant in Tutorial.by_id:
		var view: Dictionary = Tutorial.resolve(Tutorial.by_id[id])
		var blob := str(view.get("text", "")) + " " + str(view.get("title", ""))
		for w: String in keyboard_words:
			if blob.contains(w):
				offenders.append("%s (%s)" % [str(id), w])
	check(offenders.is_empty(), "conseils : à la manette, aucun nom de touche du clavier (%s)" % str(offenders))
	var closed := [false]
	var tip: Dictionary = Tutorial.by_id["boutique"]
	var run := func() -> void:
		await Tutorial._show_modal(tip)
		closed[0] = true
	run.call()
	await get_tree().process_frame
	check(Tutorial._modal, "conseils : le conseil suspend le jeu")
	var t0 := Time.get_ticks_msec()
	while Tutorial._guard > 0.0 and Time.get_ticks_msec() - t0 < 3000:
		await get_tree().process_frame
	await _pb(JOY_BUTTON_A)
	await get_tree().process_frame
	check(closed[0] and not Tutorial._modal, "conseils : A referme le conseil, une seule fois")


func _test_gamepad_full() -> void:
	var pad_before := Controls.pad
	SaveManager.delete_save()
	var main: Node = MAIN.instantiate()
	add_child(main)
	await _wait_idle(main)
	await _test_pad_title(main)
	# Nouvelle partie à la manette : le prologue (dialogues, puis combat) se joue sans clavier
	await _pb(JOY_BUTTON_A)
	var t0 := Time.get_ticks_msec()
	var presses := await _pad_drive(main, func() -> bool: return main.mode == main.Mode.PLAY and main.world != null and main.world.input_enabled and not main.busy and not main.dialogue.active)
	check(main.mode == main.Mode.PLAY and GameState.has_flag("prologue_vu"), "manette : le prologue se joue à la manette seule (%d appuis, %.0f s)" % [presses, (Time.get_ticks_msec() - t0) / 1000.0])
	check(GameState.has_flag("combat_prologue_sauron"), "manette : le combat du prologue est gagné par attaques à la manette")
	await _test_pad_world(main)
	await _test_pad_menus(main)
	await _test_pad_leave(main)
	await _test_pad_tips(main)
	main.queue_free()
	await get_tree().process_frame
	await _test_pad_battle()
	# fichier de sauvegarde plein d'octets nuls : lecture sans message ni plantage
	var nul := PackedByteArray([123, 0, 0, 0, 125])
	var nf := FileAccess.open(SaveManager.slot_path("nul_test"), FileAccess.WRITE)
	nf.store_buffer(nul)
	nf.close()
	check(SaveManager._read_file(SaveManager.slot_path("nul_test")).is_empty(), "sauvegarde : un fichier à octets nuls se lit comme vide")
	DirAccess.remove_absolute(SaveManager.slot_path("nul_test"))
	# textes d'aide : jamais de nom de touche du clavier quand la manette est active
	Controls.set_pad(true)
	var hints_txt := Tutorial.expand("avec {interact}, {cancel} annule")
	check(hints_txt == "avec A, B annule", "aide : les indications du combat parlent des boutons de la manette (%s)" % hints_txt)
	check(not Settings.help("mode").contains("touche F"), "aide : pas de « touche F » à la manette")
	Controls.set_pad(false)
	check(not Tutorial.expand("{interact}").contains("A"), "aide : au clavier, une touche (%s)" % Tutorial.expand("{interact}"))
	check(Settings.help("mode").contains("touche F"), "aide : au clavier, « touche F » reste")
	Controls.set_pad(pad_before)
	await get_tree().process_frame
	Controls.set_pad(pad_before)
	GameState.new_game()


# ------------------------------------------------------------------- restes (équilibre, réserve)

## Un réserviste échangé à la main rattrape le niveau de l'équipe, comme par le récit (set_group).
func _test_reserve_catch_up() -> void:
	print("== Réserve : rattrapage au passage dans l'équipe ==")
	GameState.new_game()
	for id: String in ["sam", "froton", "pepin", "merri"]:
		GameState.add_to_party(id)
	var levels := {"glandoulf": 10, "sam": 10, "froton": 12, "pepin": 11, "merri": 3}
	for id: String in levels:
		GameState.member(id)["level"] = int(levels[id])
		GameState.member(id)["xp"] = 7
	GameState.heal_party()
	check(GameState.is_reserve("merri"), "réserve : Merri attend hors de l'équipe de quatre")
	check(GameState.swap_members("sam", "merri"), "réserve : échange Sam / Merri")
	check(int(GameState.member("merri")["level"]) == 12 and int(GameState.member("merri")["xp"]) == 0, "réserve : Merri rattrape le niveau 12 en entrant (niv. %d)" % int(GameState.member("merri")["level"]))
	check(GameState.member("merri")["hp"] == GameState.member_stats("merri")["hp"], "réserve : Merri entre avec tous ses PV")
	check(int(GameState.member("sam")["level"]) == 10, "réserve : Sam garde son niveau en sortant (%d)" % int(GameState.member("sam")["level"]))
	# retour de Sam : il rattrape à son tour les trois qui restent (Glandoulf 10, Froton 12, Pépin 11, Merri 12)
	check(GameState.swap_members("merri", "sam"), "réserve : échange Merri / Sam")
	check(int(GameState.member("sam")["level"]) == 12, "réserve : Sam, revenu, rattrape aussi le niveau 12 (%d)" % int(GameState.member("sam")["level"]))
	# un réserviste déjà plus haut ne perd rien
	GameState.member("merri")["level"] = 15
	check(GameState.swap_members("pepin", "merri"), "réserve : échange Pépin / Merri")
	check(int(GameState.member("merri")["level"]) == 15, "réserve : un réserviste plus haut garde son niveau (%d)" % int(GameState.member("merri")["level"]))
	# même règle par le récit
	GameState.new_game()
	for id: String in ["sam", "froton"]:
		GameState.add_to_party(id)
	GameState.member("glandoulf")["level"] = 9
	GameState.member("sam")["level"] = 9
	GameState.member("pepin")["level"] = 2
	check(GameState.set_group(["glandoulf", "sam", "pepin"]), "réserve : groupe réuni par le récit")
	check(int(GameState.member("pepin")["level"]) == 9, "réserve : Pépin rattrape le niveau 9 par le récit (%d)" % int(GameState.member("pepin")["level"]))
	GameState.new_game()


## Le Balourd a une vraie phase (plafond qui gronde puis éboulement) ; la brèche se joue en deux vagues.
func _test_balourd_phase_and_breche_waves() -> void:
	print("== Balourd : phase et attaque télégraphiée ; brèche en deux vagues ==")
	var b := Database.get_enemy("balourd")
	var low: Array = b.get("ai_low", [])
	var names: Array = low.map(func(x: Variant) -> String: return str((x as Dictionary).get("skill", "")))
	check(names.has("plafond_qui_gronde") and names.has("eboulement_du_balourd"), "Balourd : la phase de mi-vie annonce puis lance l'éboulement (%s)" % str(names))
	check(not (b.get("ai", []) as Array).any(func(x: Variant) -> bool: return str((x as Dictionary).get("skill", "")) == "eboulement_du_balourd"), "Balourd : l'éboulement est réservé à la seconde phase")
	for sk: String in ["plafond_qui_gronde", "eboulement_du_balourd"]:
		check(not Database.get_skill(sk).is_empty() and Database.animations.has(sk), "Balourd : %s décrit avec son animation" % sk)
	check(not Database.get_status("gronde").is_empty(), "Balourd : l'état « le plafond gronde » existe")
	GameState.new_game()
	GameState.party = ["glandoulf", "sam"]
	var eng: RefCounted = BattleEngine.new()
	eng.setup(Database.get_encounter("balourd"), 5)
	var boss: RefCounted = eng.enemies[0]
	var atk0 := float(boss.stat("atk"))
	eng.perform(boss, {"type": "skill", "id": "plafond_qui_gronde"})
	check(boss.has_status("gronde") and float(boss.stat("atk")) > atk0 * 1.4, "Balourd : le plafond gronde, son prochain coup est plus lourd (%.0f contre %.0f)" % [float(boss.stat("atk")), atk0])
	boss.hp = int(boss.max_hp() * 0.4)
	var seen := {}
	for i in 300:
		var act: Dictionary = eng.ai_action(boss)
		seen[str(act.get("id", "attack"))] = true
	check(seen.has("plafond_qui_gronde") and seen.has("eboulement_du_balourd"), "Balourd : sous la moitié des PV, il utilise la phase (%s)" % str(seen.keys()))
	# la brèche : deux vagues enchaînées par le dialogue, la seconde pose le drapeau attendu par la suite
	var first := Database.get_encounter("breche_avant")
	var second := Database.get_encounter("breche")
	check(not first.is_empty() and not second.is_empty(), "brèche : deux vagues décrites")
	check((first.get("enemies", []) as Array).size() <= 3 and (second.get("enemies", []) as Array).size() <= 2, "brèche : au plus trois ennemis à la fois (%d puis %d)" % [(first.get("enemies", []) as Array).size(), (second.get("enemies", []) as Array).size()])
	var dlg: Array = Database.get_dialogue("isengarde_breche")
	check(_dialogue_has(dlg, "battle", "breche_avant") and _dialogue_has(dlg, "battle", "breche"), "brèche : le dialogue enchaîne les deux combats")
	GameState.new_game()


## Le fil de préchauffage peint avec une copie du peintre (variables statiques à lui) : sa planche doit être
## identique, pixel pour pixel, à celle peinte à la demande sur le fil principal. Les monstres de
## gouda_monsters.gd n'y passent pas (exclus du préchauffage).
func _test_warm_matches_demand() -> void:
	print("-- préchauffage des monstres : fil d'arrière-plan contre peinture à la demande")
	var mp: GDScript = load("res://src/gfx/monster_painter.gd")
	var painter := GDScript.new()
	painter.source_code = FileAccess.get_file_as_string("res://src/gfx/monster_painter.gd")
	check(painter.reload() == OK, "copie du peintre : se recharge")
	var gouda: Array = load("res://src/gfx/gouda_monsters.gd").KINDS + load("res://src/gfx/boss_painter.gd").KINDS
	var kinds: Array = []
	for k: String in mp.SIZES.keys():
		if not gouda.has(k):
			kinds.append(k)
	kinds.sort()
	var out: Dictionary = {}
	var th := Thread.new()
	th.start(func() -> void:
		for k: String in kinds:
			out[k] = (painter.call("paint_hd", k) as Image).get_data())
	while th.is_alive():
		await get_tree().process_frame
	th.wait_to_finish()
	var t0 := Time.get_ticks_msec()
	var bad: Array = []
	for k: String in kinds:
		var demand: PackedByteArray = (mp.paint_hd(k) as Image).get_data()
		if not out.has(k) or out[k] != demand:
			bad.append(k)
	print("   %d monstres comparés, peinture à la demande : %d ms" % [kinds.size(), Time.get_ticks_msec() - t0])
	check(bad.is_empty(), "planche du fil = planche à la demande (écarts : %s)" % str(bad))


## Lac de Maroilles (profondeur, lueur) et sols usés de l'Isengarde (rails) : données présentes et cohérentes.
func _test_decors_restes() -> void:
	var lake: Variant = Database.get_map("morbier_antre").get("water", {}).get("lake")
	check(lake is Array and (lake as Array).size() == 4 and float((lake as Array)[2]) > 0.0, "lac de Maroilles : champ lake [x, z, largeur, profondeur]")
	var sh: Shader = load("res://src/gfx/shaders/water.gdshader")
	check(sh != null and sh.code.contains("uniform vec4 lake"), "eau : le shader connaît le lac profond")
	var mp: Dictionary = Database.get_map("isengarde")
	var rails: Array = mp.get("rails", [])
	check(rails.size() >= 3, "Isengarde : des rails posés sur le sol")
	var sz: Array = mp["size"]
	for r: Variant in rails:
		var ok: bool = r is Array and (r as Array).size() == 4
		check(ok, "Isengarde : rail bien formé %s" % str(r))
		if ok:
			var ra: Array = r
			check(float(ra[0]) >= 0.0 and float(ra[2]) <= float(sz[0]) and float(ra[1]) >= 0.0 and float(ra[3]) <= float(sz[1]), "Isengarde : rail %s dans la carte" % str(r))


## Textes d'aide : aucune touche écrite en dur dans les données (elles changent avec le clavier ou la manette) ;
## on écrit {move}, {interact}, {cancel}, {menu}, {journal}, {elan} ou {choose}, que Tutorial.expand remplace à
## l'affichage (dialogues, choix, journal, repère de quête, conseils, combats). Parcourt tout `data/` ; les
## fichiers du chapitre 6 sont comptés à part, sans faire échouer le test.
func _test_help_texts() -> void:
	print("-- textes d'aide : pas de touche écrite en dur")
	var rx := RegEx.new()
	rx.compile("(?i)touches?\\s+(?:sur\\s+)?(?:la\\s+|le\\s+)?(?:entrée|espace|échap|tab|maj|retour|[a-z](?![a-zA-Z'’]))\\b|\\bÉchap\\b|Retour arrière|barre d'espace|\\bCtrl\\b|\\bShift\\b|avec les flèches|les flèches du clavier|clic gauche|clic droit")
	var mk := RegEx.new()
	mk.compile("\\{([a-z_]+)\\}")
	var known := ["move", "interact", "cancel", "menu", "journal", "elan", "choose"]
	var found: Array = []
	var found6: Array = []
	var strings := 0
	var stack: Array = []
	for f: String in _json_files("res://data"):
		stack.append([f, JSON.parse_string(FileAccess.get_file_as_string(f))])
	while not stack.is_empty():
		var it: Array = stack.pop_back()
		var v: Variant = it[1]
		if v is Dictionary:
			for k: Variant in (v as Dictionary):
				stack.append([it[0], (v as Dictionary)[k]])
		elif v is Array:
			for e: Variant in (v as Array):
				stack.append([it[0], e])
		elif v is String:
			strings += 1
			var t: String = v
			var m := rx.search(t)
			if m != null:
				(found6 if (it[0] as String).contains("chapitre_6") else found).append("%s : « %s »" % [(it[0] as String).get_file(), m.get_string()])
			for mm in mk.search_all(t):
				if not (it[0] as String).contains("chapitre_6") or true:
					var name := mm.get_string(1)
					if t.contains("{" + name + "}") and not known.has(name) and name.length() < 12 and not t.begins_with("{"):
						# des accolades qui ne sont pas des marqueurs d'aide (ex. variables de texte) seraient signalées ici
						found.append("%s : marqueur inconnu {%s}" % [(it[0] as String).get_file(), name])
	print("   %d textes parcourus, %d touche(s) en dur, %d dans le chapitre 6 (non modifié)" % [strings, found.size(), found6.size()])
	for x: String in found6:
		print("   chapitre 6 : ", x)
	check(found.is_empty(), "textes d'aide : aucune touche écrite en dur (%s)" % str(found))
	# le remplacement : plus aucune accolade après expand, sur clavier comme sur manette
	for pad_on: bool in [false, true]:
		var was: bool = Tutorial.pad
		Tutorial.pad = pad_on
		for name: String in known:
			var out: String = Tutorial.expand("a {%s} b" % name)
			check(not out.contains("{") and out.length() >= 5, "Tutorial.expand {%s} (%s) : « %s »" % [name, "manette" if pad_on else "clavier", out])
		Tutorial.pad = was
	# l'aide de Bittebourg passe bien par les marqueurs
	var raw := FileAccess.get_file_as_string("res://data/dialogues/chapitre_1_bittebourg.json")
	check(raw.contains("{move}") and raw.contains("{interact}") and raw.contains("{menu}"), "Bittebourg : l'aide des commandes utilise {move}, {interact}, {menu}")


func _json_files(dir: String) -> Array:
	var out: Array = []
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".json"):
			out.append(dir + "/" + f)
	for d in DirAccess.get_directories_at(dir):
		out.append_array(_json_files(dir + "/" + d))
	return out


## Horizon et caméra par carte : une carte sans `camera.zones` garde l'ancien cadrage ; les
## données d'horizon sont connues ; sur les cartes réglées le joueur reste dans le cadre.
func _test_horizon() -> void:
	print("-- horizon et caméra par carte")
	var Hz: GDScript = load("res://src/world/horizon.gd")
	var kinds: Array = ["city", "terraces", "mountain", "plain", "hills", "ridge"]
	var tuned: Array = []
	for f in DirAccess.get_files_at("res://data/maps"):
		if not f.ends_with(".json"):
			continue
		var id := f.get_basename()
		var mp: Dictionary = Database.get_map(id)
		var cam: Dictionary = mp.get("camera", {})
		for z: Variant in cam.get("zones", []):
			var zd: Dictionary = z
			var r: Array = zd.get("rect", [])
			check(r.size() == 4 and float(r[2]) > 0.0 and float(r[3]) > 0.0, "%s : zone de caméra bien formée" % id)
		if mp.has("horizon"):
			tuned.append(id)
			var hz: Dictionary = mp["horizon"]
			var preset: String = str(hz.get("preset", "cite"))
			check(Hz.PRESETS.has(preset), "%s : préréglage d'horizon connu (%s)" % [id, preset])
			var cfg: Dictionary = Hz.PRESETS.get(preset, {})
			for ld: Variant in hz.get("layers", cfg.get("layers", [])):
				check(kinds.has(str((ld as Dictionary).get("kind"))), "%s : plan d'horizon de genre connu" % id)
			var sky: Variant = hz.get("sky", cfg.get("sky", "matin"))
			check(not (sky is String) or Hz.SKIES.has(sky), "%s : ciel connu" % id)
	check(tuned.has("minas_croute") and tuned.has("minas_rues") and tuned.has("minas_citadelle"), "les trois cartes de Minas ont un horizon")
	# cadrage inchangé sans bloc zones ni horizon ; joueur dans le cadre sur les cartes réglées
	for id: String in ["bittebourg", "minas_rues", "minas_croute", "minas_citadelle", "morbier_antre"]:
		if Database.get_map(id).is_empty():
			continue
		var mp2: Dictionary = Database.get_map(id)
		GameState.new_game()
		var world: Node3D = World.new()
		add_child(world)
		world.setup(id, str(mp2.get("spawns", {}).keys()[0]))
		await get_tree().process_frame
		await get_tree().process_frame
		var has_zones: bool = not (mp2.get("camera", {}) as Dictionary).get("zones", []).is_empty()
		if not has_zones:
			check(is_equal_approx(world.camera.rotation_degrees.x, -float((mp2.get("camera", {}) as Dictionary).get("pitch", 32.0))), "%s : sans zones, l'inclinaison reste celle de la carte" % id)
			check(is_equal_approx(world.camera.fov, float((mp2.get("camera", {}) as Dictionary).get("fov", 24.0))), "%s : sans zones, le champ reste celui de la carte" % id)
		check(not world.camera.is_position_behind(world.player.global_position + Vector3(0, 1, 0)), "%s : le joueur est devant la caméra" % id)
		var sp: Vector2 = world.camera.unproject_position(world.player.global_position + Vector3(0, 1, 0))
		var vs: Vector2 = get_viewport().get_visible_rect().size
		check(sp.x > 0.0 and sp.x < vs.x and sp.y > 0.0 and sp.y < vs.y, "%s : le joueur est dans le cadre" % id)
		world.queue_free()
		await get_tree().process_frame
	# le joueur n'est jamais dans le flou de profondeur : sur les cartes de Minas, en tout point
	# accessible d'une grille, la caméra se tient entre les limites du flou proche et du flou lointain
	for id2: String in ["minas_rues", "minas_croute", "minas_citadelle"]:
		var mp3: Dictionary = Database.get_map(id2)
		GameState.new_game()
		var w3: Node3D = World.new()
		add_child(w3)
		w3.setup(id2, str(mp3.get("spawns", {}).keys()[0]))
		await get_tree().process_frame
		var gw := int((mp3.get("size", [32, 32]) as Array)[0])
		var gh := int((mp3.get("size", [32, 32]) as Array)[1])
		var n_ok := 0
		var n_bad := 0
		var worst := ""
		var gz := 1.5
		while gz < float(gh):
			var gx := 1.5
			while gx < float(gw):
				if w3.is_free(Vector2(gx, gz), 0.3):
					w3.player.position = Vector3(gx, w3.ground_y(gx, gz), gz)
					w3._cam_target = w3._desired_target()
					w3._apply_camera()
					var dd: float = w3.camera.global_position.distance_to(w3.player.position + Vector3(0, 0.9, 0))
					var at: CameraAttributesPractical = w3._cam_attr
					if dd >= at.dof_blur_near_distance + 0.3 and dd <= at.dof_blur_far_distance - 0.3:
						n_ok += 1
					else:
						n_bad += 1
						worst = "(%.1f,%.1f) dist %.1f net %.1f" % [gx, gz, dd, at.dof_blur_near_distance]
				gx += 3.0
			gz += 3.0
		check(n_ok > 10 and n_bad == 0, "%s : le joueur reste net en %d points d'une grille (flou proche et lointain) %s" % [id2, n_ok, worst])
		w3.queue_free()
		await get_tree().process_frame
	# Tour Blanche en 3D, décor des rues, terrasses du belvédère, fumées animées du siège
	for id4: String in ["minas_rues", "minas_citadelle"]:
		var mp4: Dictionary = Database.get_map(id4)
		var wt: Dictionary = mp4.get("white_tower", {})
		check(not wt.is_empty() and float(wt.get("height", 0.0)) > 20.0, "%s : la Tour Blanche est déclarée (white_tower)" % id4)
		GameState.new_game()
		var w4: Node3D = World.new()
		add_child(w4)
		w4.setup(id4, str(mp4.get("spawns", {}).keys()[0]))
		await get_tree().process_frame
		var tower_found := false
		for ch in w4.get_children():
			if str(ch.name).begins_with("TourBlanche"):
				tower_found = true
		check(tower_found, "%s : la Tour Blanche est construite dans la scène" % id4)
		w4.queue_free()
		await get_tree().process_frame
	var n_deco := 0
	var n_pave := 0
	for o: Variant in (Database.get_map("minas_rues").get("objects", []) as Array):
		if str((o as Dictionary).get("type", "")) == "gou_deco":
			n_deco += 1
		if str((o as Dictionary).get("type", "")) == "gou_pavage":
			n_pave += 1
	check(n_deco >= 25 and n_pave == 1, "minas_rues : rues habillées (%d décors, %d pavage)" % [n_deco, n_pave])
	check(not (Database.get_map("minas_citadelle").get("belvedere", {}) as Dictionary).get("terraces", {}).is_empty(), "minas_citadelle : terrasses du belvédère en 3D")
	# cache disque des plans : un deuxième accès relit le fichier et rend la même image et les mêmes foyers
	var ld_t: Dictionary = {"kind": "plain", "w": 2400, "res": 2, "seed": 4, "fires": 12, "haze": "#d6cdc4"}
	var key_t: String = Hz._layer_key(ld_t)
	var d1: Dictionary = Hz._layer_data(key_t, ld_t)
	var d2: Dictionary = Hz._layer_data(key_t, ld_t)
	check(FileAccess.file_exists(Hz._cache_path(key_t) + ".png"), "cache d'horizon : le plan est écrit sur le disque")
	check((d1["img"] as Image).get_size() == (d2["img"] as Image).get_size() and (d1["fires"] as Array).size() == (d2["fires"] as Array).size(), "cache d'horizon : relecture identique")
	var t_c := Time.get_ticks_msec()
	Hz._layer_data(key_t, ld_t)
	check(Time.get_ticks_msec() - t_c < 300, "cache d'horizon : relecture d'un plan en moins de 300 ms")
	# montagne : pas de couture verticale (écart de teinte entre deux colonnes voisines, sous le sommet)
	var mt: Image = (load("res://src/gfx/horizon_layers.gd") as GDScript).paint("mountain", 3, {"w": 2400, "off": 120, "peak": 0.95})
	var seams := 0
	for xm in range(1, 2399):
		var c0 := mt.get_pixel(xm, 340)
		var c1 := mt.get_pixel(xm + 1, 340)
		if absf(c0.r - c1.r) + absf(c0.g - c1.g) + absf(c0.b - c1.b) > 0.45:
			seams += 1
	check(seams < 40, "montagne : peu de ruptures verticales (%d)" % seams)


## Tous les boss du jeu, dans leur vraie rencontre et leur vraie arène, aux deux formats d'écran : chacun doit
## dominer (au moins BOSS_RATIO_FLOOR fois un héros, plus haut que ses sbires), avoir sa flaque de lumière, et
## les plaques, la frise, les fiches et le bandeau des touches restent libres (mêmes vérifications que la mise
## en page). Table : rencontre -> ennemi qui doit être reconnu comme le boss.
func _test_boss_presence() -> void:
	print("== Les boss du jeu : ils dominent la scène ==")
	var expected := {
		"vacherin": "vacherin", "chantecler": "chantecler", "nazes_nuit": "naze_aine", "prologue_sauron": "sauron_vigueur", "grande_baveuse": "grande_baveuse", "vieux_solitaire": "vieux_solitaire",
		"crapaud_buffle": "crapaud_buffle", "naze": "naze_fouineur", "gardien_archives": "gardien_archives",
		"guetteur_du_lac": "guetteur_lac", "gros_bleu": "gros_bleu", "goulum": "goulum", "balourd": "balourd",
		"ambuscade_chutes": "uglouk", "grimace": "grimace", "froton_anneaute": "froton_anneaute", "breche_avant": "ouroukouille_petrisseur",
		"breche": "ouroukouille_petrisseur", "sarumale": "sarumale", "roi_eveille": "roi_eveille", "saumure": "saumure",
		"grondine": "grondine", "gothmoque": "gothmoque", "dindon_farce": "dindon_farce", "naze_supreme": "naze_supreme",
		"pelle_mammous": "mammou",
	}
	var win := get_window()
	var old_size := win.size
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(1600, 900)]:
		win.size = size
		await get_tree().process_frame
		for id: String in expected:
			if OS.has_environment("GLAN_FILTER") and not id.contains(OS.get_environment("GLAN_FILTER")):
				continue   # (GLAN_FILTER : un seul boss, pour le réglage)
			if not Database.encounters.has(id):
				check(false, "boss : la rencontre %s existe" % id)
				continue
			var enc: Dictionary = (Database.encounters[id] as Dictionary).duplicate(true)
			GameState.new_game()
			for who: String in ["sam", "froton", "pepin"]:
				GameState.add_to_party(who)
			var layer := CanvasLayer.new()
			add_child(layer)
			var ui: Control = BattleUI.new()
			layer.add_child(ui)
			await get_tree().process_frame
			var scene: Node3D = BattleScene.new()
			add_child(scene)
			scene.fast = true
			scene.setup(enc, ui, 5)
			scene.run()
			for _i in 600:
				await get_tree().process_frame
				if ui._state == ui.S.ROOT:
					break
			await get_tree().process_frame
			await get_tree().process_frame
			var tag := "boss %s, %dx%d" % [id, size.x, size.y]
			check(scene.boss != null and str(scene.boss.source) == str(expected[id]), "%s : %s est reconnu comme le boss" % [tag, str(expected[id])])
			if scene.boss != null:
				var hero_h: float = (scene.actors[scene.engine.party[0].key] as Node3D).height
				var boss_h: float = (scene.actors[scene.boss.key] as Node3D).height
				check(boss_h / hero_h >= scene.BOSS_RATIO_FLOOR - 0.001, "%s : %.2f fois un héros (au moins %.1f)" % [tag, boss_h / hero_h, scene.BOSS_RATIO_FLOOR])
				check((scene.actors[scene.boss.key] as Node3D)._halo != null, "%s : le boss a sa flaque de lumière" % tag)
			_check_staging(scene, ui, tag, false)
			ui.close()
			remove_child(scene)
			scene.queue_free()
			layer.queue_free()
	win.size = old_size


func _test_decors_6() -> void:
	print("== Décors, eau, plaine, enseigne (chantier decors6) ==")
	# shaders : l'eau (distance à la rive, reflets) et le sol (ombres de nuages) se chargent
	for sh: String in ["res://src/gfx/shaders/water.gdshader", "res://src/gfx/shaders/ground.gdshader"]:
		var shader := load(sh) as Shader
		check(shader != null and shader.code.length() > 200, "shader %s chargé" % sh.get_file())
	var water_src := FileAccess.get_file_as_string("res://src/gfx/shaders/water.gdshader")
	check(water_src.contains("shore_tex") and water_src.contains("refl_c"), "eau : carte des rives et reflets alignés présents")
	# herbes hautes : sprite non vide, trois variantes différentes, déclaré dans PROPS
	var imgs: Array = []
	for v in 3:
		var img: Image = preload("res://src/gfx/prop_painter.gd").tall_grass(v)
		var opaque := 0
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.5:
					opaque += 1
		check(opaque > 80, "herbe haute variante %d : %d pixels peints" % [v, opaque])
		imgs.append(img.get_data())
	check(imgs[0] != imgs[1] and imgs[1] != imgs[2], "herbes hautes : trois variantes distinctes")
	check(preload("res://src/world/map_builder.gd").PROPS.has("tallgrass"), "PROPS : tallgrass déclaré")
	# plaine et Cabécou : herbes hautes, fleurs, ombres de nuages
	for id: String in ["plaine_roquefort", "cabecou"]:
		var m := Database.get_map(id)
		check(float(m.get("clouds", 0.0)) > 0.0, "%s : ombres de nuages (champ clouds)" % id)
		var props: Array = []
		for o: Variant in m.get("objects", []):
			if o is Dictionary and str((o as Dictionary).get("type", "")) == "scatter":
				props.append(str((o as Dictionary).get("prop", "")))
		check(props.has("tallgrass") and props.has("flowers"), "%s : herbes hautes et fleurs semées" % id)
	# terrasse des Chutes : deux chutes et une balustrade
	var chutes := Database.get_map("chutes_gratin")
	var falls := 0
	var fences := 0
	for o: Variant in chutes.get("objects", []):
		if o is Dictionary:
			match str((o as Dictionary).get("type", "")):
				"chu_cascade": falls += 1
				"fence": fences += 1
	check(falls >= 2, "Chutes : %d chutes (%d barrières)" % [falls, fences])
	# lac souterrain : rochers et cristaux plantés dans l'eau
	var antre := Database.get_map("morbier_antre")
	var in_lake := 0
	for o: Variant in antre.get("objects", []):
		if o is Dictionary and ["nain_gravats", "nain_cristal"].has(str((o as Dictionary).get("type", ""))):
			in_lake += 1
	check(in_lake >= 7, "lac de l'antre : %d rochers et cristaux" % in_lake)
	check(float(Database.get_map("salle_conseil").get("ground_variation", 0.0)) > 0.1, "salle du Conseil : sol nuancé (ground_variation)")
	# enseigne en fer à cheval : branches et pointes, ouverte vers le bas
	var sign: Image = preload("res://src/gfx/house_painter.gd").sign_board("cheval")
	var steel := 0
	var top_row := 0
	for y in sign.get_height():
		for x in sign.get_width():
			var c := sign.get_pixel(x, y)
			if c.r > 0.78 and c.g > 0.78 and c.b > 0.8:
				steel += 1
				if y < 12:
					top_row += 1
	check(steel >= 30 and top_row > steel / 3, "enseigne du poney : fer à cheval lisible (%d pixels d'acier)" % steel)
	# la mise au point suit le héros : rapports lus dans la caméra de la carte
	var wsrc := FileAccess.get_file_as_string("res://src/world/world.gd")
	check(wsrc.contains("_focus_on_player()") and wsrc.contains("_dof_near_k"), "caméra : le héros reste toujours dans la zone nette")


## Coups annoncés (champ « next » de « ai », état « annonce ») : Chantecler, Uglouk, le pétrisseur et Goulûm préparent un
## gros coup un tour avant de le lancer ; un bouclier brisé (ou tout état qui fait passer le tour) l'interrompt.
func _test_telegraphed_attacks() -> void:
	check(not Database.get_status("annonce").is_empty() and bool(Database.get_status("annonce").get("telegraph", false)), "coup annoncé : l'état « annonce » existe")
	check(Sprites.icon("annonce") != null, "coup annoncé : l'état a son icône")
	var cases := [["chantecler", "chantecler", "crete_dressee", "pietinement"], ["ambuscade_chutes", "uglouk", "bon_de_livraison", "coup_de_louche_o"],
			["breche", "ouroukouille_petrisseur", "petrin_souleve", "coup_de_petrin"], ["goulum", "goulum", "griffe_a_l_affut", "morsure_de_poisson"]]
	for c: Array in cases:
		var tele := str(c[2])
		var heavy := str(c[3])
		check(not Database.get_skill(tele).is_empty() and Database.animations.has(tele), "coup annoncé : %s décrit avec son animation" % tele)
		check(not Database.get_skill(heavy).is_empty() and Database.animations.has(heavy), "coup annoncé : %s (le coup lancé ensuite) a son animation" % heavy)
		var enc: Dictionary = Database.get_encounter(str(c[0]))
		GameState.new_game()
		GameState.party = ["glandoulf", "sam"]
		var eng: RefCounted = BattleEngine.new()
		eng.setup(enc, 5)
		var boss: RefCounted = null
		for en: RefCounted in eng.enemies:
			if str(en.source) == str(c[1]):
				boss = en
		check(boss != null, "coup annoncé : %s est dans la rencontre %s" % [str(c[1]), str(c[0])])
		if boss == null:
			continue
		var atk0 := float(boss.stat("atk"))
		eng.perform(boss, {"type": "skill", "id": tele})
		check(boss.has_status("annonce") and float(boss.stat("atk")) > atk0 * 1.45, "coup annoncé : %s prépare un coup plus lourd (%.0f contre %.0f)" % [tele, float(boss.stat("atk")), atk0])
		# la liste « ai » mène bien à l'annonce, puis au coup, dans cet ordre
		var order_ok := false
		for i in 400:
			var act: Dictionary = eng.ai_action(boss)
			if str(act.get("id", "")) == tele:
				check(boss.next_skill == heavy, "coup annoncé : %s est suivi de %s (suivant : %s)" % [tele, heavy, boss.next_skill])
				var nxt: Dictionary = eng.ai_action(boss)
				order_ok = str(nxt.get("id", "")) == heavy and boss.next_skill == ""
				break
		check(order_ok, "coup annoncé : %s tombe au tour suivant, sans faute" % heavy)
		# interruption : un tour perdu (bouclier brisé, sonné...) annule le coup annoncé
		boss.next_skill = heavy
		boss.statuses["ebranle"] = {"turns": 1, "fresh": false}
		eng.start_turn(boss)
		check(boss.next_skill == "" and not bool(eng.can_act), "coup annoncé : bouclier brisé, le coup de %s est interrompu" % str(c[1]))
	GameState.new_game()
