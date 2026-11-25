extends Node
## Chef d'orchestre : écran-titre, partie en cours, changements de carte, dialogues, pause.
## Toute la scène est construite ici par code.

const World = preload("res://src/world/world.gd")
const DialogueBox = preload("res://src/ui/dialogue_box.gd")
const TitleScreen = preload("res://src/ui/title_screen.gd")
const PauseMenu = preload("res://src/ui/pause_menu.gd")
const Hud = preload("res://src/ui/hud.gd")
const BattleScene = preload("res://src/battle/battle_scene.gd")
const BattleUI = preload("res://src/battle/battle_ui.gd")
const GameMenu = preload("res://src/ui/game_menu.gd")
const TalentScreen = preload("res://src/ui/talent_screen.gd")
const SaveScreen = preload("res://src/ui/save_screen.gd")
const SettingsScreen = preload("res://src/ui/settings_screen.gd")
const PadScreen = preload("res://src/ui/pad_screen.gd")
const CreditsScreen = preload("res://src/ui/credits_screen.gd")
const ConfirmBox = preload("res://src/ui/confirm_box.gd")
const ChapterScreen = preload("res://src/ui/chapter_screen.gd")
const ChapterStart = preload("res://src/core/chapter_start.gd")
const LoadingUI = preload("res://src/ui/ui_kit.gd")
const LoadingSpinner = preload("res://src/ui/loading_spinner.gd")
const Prewarm = preload("res://src/gfx/prewarm.gd")

enum Mode { BOOT, TITLE, PLAY }

var mode: Mode = Mode.BOOT
var world: Node3D = null
var busy := false
var battle: Node3D = null       # combat en cours, sinon null
var auto_battles := false       # tests : les combats se jouent tout seuls, sans attente
var _abort_flow := false        # une défaite a renvoyé à l'écran-titre : les scènes en cours s'arrêtent
var _jump: Array = []              # destination demandée par une action « va: » : [carte, arrivée], jouée à la fin du dialogue

var hud: Control
var dialogue: Control
var pause: Control
var title: Control
var battle_ui: Control
var menus: Control              # équipe, inventaire, journal de quêtes, boutiques
var _menus_from := ""           # "pause" ou "dialogue" : à qui rendre la main quand ils se ferment
var talents: Control            # écran de talents
var _talents_from := ""         # "pause" ou "team" : où revenir quand il se ferme
var saves: Control             # liste des sauvegardes (charger, sauvegarder)
var settings_screen: Control    # écran des paramètres
var pad_screen: Control         # diagnostic de la manette
var credits: Control            # générique de fin (chapitre 7)
var _credits_pending := false   # action « generique » : jouée à la fin du dialogue
var confirm: Control            # « Quitter le jeu ? », « Retour au titre ? » : Non par défaut
var chapters_screen: Control    # « Choisir un chapitre » (écran-titre)
var _fade: ColorRect
var _loading: Label
var _spinner: Control
var _pending_load := ""         # emplacement choisi depuis l'écran de défaite


func _ready() -> void:
	# Vignette : coins de l'image assombris, au-dessus du monde et sous l'interface.
	var grade := CanvasLayer.new()
	grade.layer = 0
	add_child(grade)
	var vignette := ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vignette_mat := ShaderMaterial.new()
	vignette_mat.shader = preload("res://src/gfx/shaders/vignette.gdshader")
	vignette.material = vignette_mat
	grade.add_child(vignette)

	var ui := CanvasLayer.new()
	ui.name = "UI"
	add_child(ui)
	hud = Hud.new()
	ui.add_child(hud)
	battle_ui = BattleUI.new()
	ui.add_child(battle_ui)
	dialogue = DialogueBox.new()
	ui.add_child(dialogue)
	title = TitleScreen.new()
	ui.add_child(title)
	pause = PauseMenu.new()
	ui.add_child(pause)
	menus = GameMenu.new()
	ui.add_child(menus)
	talents = TalentScreen.new()
	ui.add_child(talents)
	saves = SaveScreen.new()
	ui.add_child(saves)
	battle_ui.save_screen = saves
	settings_screen = SettingsScreen.new()
	ui.add_child(settings_screen)
	pad_screen = PadScreen.new()
	ui.add_child(pad_screen)
	credits = CreditsScreen.new()
	ui.add_child(credits)
	confirm = ConfirmBox.new()
	ui.add_child(confirm)
	chapters_screen = ChapterScreen.new()
	ui.add_child(chapters_screen)
	ui.move_child(chapters_screen, confirm.get_index())   # la confirmation passe par-dessus la liste

	var top := CanvasLayer.new()
	top.layer = 10
	add_child(top)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_fade)
	_loading = Label.new()   # « Chargement » : visible pendant la construction d'une carte, sur le fondu noir
	_loading.text = "Chargement…"
	_loading.add_theme_font_override("font", LoadingUI.font(false, true))
	_loading.add_theme_font_size_override("font_size", 26)
	_loading.add_theme_color_override("font_color", LoadingUI.GOLD_DIM)
	_loading.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)   # centré, dans le tiers bas de l'écran
	_loading.anchor_top = 0.8
	_loading.anchor_bottom = 0.8
	_loading.offset_left = -200.0
	_loading.offset_right = 200.0
	_loading.offset_top = -20.0
	_loading.offset_bottom = 20.0
	_loading.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_loading.visible = false
	top.add_child(_loading)
	_spinner = LoadingSpinner.new()   # un arc qui tourne au-dessus du mot : preuve que le jeu n'est pas figé
	_spinner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_spinner.anchor_top = 0.8
	_spinner.anchor_bottom = 0.8
	_spinner.offset_left = -22.0
	_spinner.offset_right = 22.0
	_spinner.offset_top = -78.0
	_spinner.offset_bottom = -34.0
	_spinner.visible = false
	top.add_child(_spinner)

	title.new_game_requested.connect(start_new_game)
	title.continue_requested.connect(func() -> void: continue_game())
	title.load_requested.connect(func() -> void: _open_saves("load", "title"))
	saves.finished.connect(_on_saves_finished)
	settings_screen.closed.connect(_on_settings_closed)
	title.add_entry("Choisir un chapitre", func() -> void: chapters_screen.open())
	chapters_screen.chosen.connect(_on_chapter_chosen)
	chapters_screen.closed.connect(_on_chapters_closed)
	title.add_entry("Manette", func() -> void: pad_screen.open("title"))
	title.add_entry("Paramètres", func() -> void: settings_screen.open("title"))
	pad_screen.closed.connect(_on_pad_closed)
	settings_screen.pad_requested.connect(func() -> void:
		settings_screen.visible = false   # le diagnostic se place au-dessus ; Paramètres revient à sa fermeture
		pad_screen.open("settings_" + settings_screen.context))
	Controls.notice.connect(hud.toast)
	for text: Variant in Controls.take_pending():
		hud.toast(str(text))
	pause.add_entry("Paramètres", func() -> void:
		pause.close(true)
		settings_screen.open("pause"))
	saves.saved.connect(_on_slot_saved)
	pause.load_requested.connect(func() -> void: _open_saves("load", "pause"))
	title.quit_requested.connect(_on_title_quit)
	pause.resumed.connect(_on_pause_closed)
	pause.save_requested.connect(_on_save_requested)
	pause.title_requested.connect(_on_pause_title)
	pause.quit_requested.connect(_on_pause_quit)
	dialogue.action_requested.connect(_on_dialogue_action)
	dialogue.battle_requested.connect(_on_dialogue_battle)
	dialogue.notice.connect(func(text: String) -> void: hud.toast(text))
	dialogue.shop_requested.connect(_on_dialogue_shop)
	dialogue.banner_requested.connect(func(text: String, sub: String) -> void: hud.banner(text, sub))
	pause.screen_requested.connect(_on_pause_screen)
	menus.closed.connect(_on_menus_closed)
	menus.talents_requested.connect(_on_team_talents)
	talents.closed.connect(_on_talents_closed)
	GameState.quest_started.connect(_on_quest_started)
	GameState.quest_completed.connect(_on_quest_completed)
	Tutorial.install(self, ui)   # conseils de jeu : page « Aide » du menu de pause
	SaveManager.before_save.connect(_sync_state)

	# Préchauffage des shaders sous l'écran noir de lancement (voir docs/PERFORMANCE.md) : ensuite aucun
	# à-coup de compilation pendant le jeu.
	if not Prewarm.done and DisplayServer.get_name() != "headless" and not OS.has_environment("GLAN_NO_PREWARM"):
		_set_loading(true)
		await Prewarm.run(self)
		_set_loading(false)
	await show_title()
	Sprites.start_background()   # caches de personnages et de monstres remplis en arrière-plan, titre affiché


# ----------------------------------------------------------------- transitions

func _fade_to(alpha: float, duration: float = 0.4) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, duration)
	await tw.finished


func _free_world() -> void:
	if world != null:
		if world.get_parent() == self:
			remove_child(world)
		world.queue_free()
		world = null


## Affiche « Chargement… » et laisse une image se dessiner avant la construction d'une carte (qui fige l'écran).
func _loading_on() -> void:
	_set_loading(true)
	await get_tree().process_frame


func _set_loading(on: bool) -> void:
	_loading.visible = on
	_spinner.visible = on


func _load_world(map_id: String, spawn_id: String, pos: Array, facing: String, attract: bool) -> void:
	Sprites.bg_pause = true   # pendant la construction, les fils d'arrière-plan laissent le processeur au chargement
	_free_world()
	world = World.new()
	world.name = "World"
	world.process_mode = Node.PROCESS_MODE_DISABLED   # le monde ne tourne pas tant qu'il n'est pas construit
	add_child(world)
	move_child(world, 0)
	# étalé sur plusieurs images sous le fondu ; la carte du titre (décor du menu) se construit d'un seul tenant
	await world.setup(map_id, spawn_id, pos, facing, attract, not attract)
	world.process_mode = Node.PROCESS_MODE_INHERIT
	Sprites.bg_pause = false
	Music.play(Music.default("title") if attract else Music.for_map(world.map))
	world.warp_requested.connect(change_map)
	world.interact_requested.connect(_on_interact)
	world.trigger_fired.connect(_on_trigger)
	world.encounter_requested.connect(_on_encounter)
	_set_loading(false)


func show_title() -> void:
	if busy:
		return
	busy = true
	_abort_flow = false
	_menus_from = ""
	menus.close(true)
	_talents_from = ""
	talents.close(true)
	if mode != Mode.BOOT:
		await _fade_to(1.0)
	GameState.playing = false
	mode = Mode.TITLE
	hud.clear()
	await _load_world(str(Database.game.get("title_map", "bittebourg")), "", [], "", true)
	title.open()
	await _fade_to(0.0, 0.8)
	busy = false


func start_new_game() -> void:
	if busy:
		return
	busy = true
	await _fade_to(1.0)
	title.close()
	GameState.new_game()
	# Prologue : un dialogue (et son combat) joué sur fond noir avant la première carte.
	var prologue := str((Database.game.get("start", {}) as Dictionary).get("prologue", ""))
	if prologue != "" and Database.has_dialogue(prologue):
		_free_world()
		mode = Mode.PLAY
		GameState.playing = true
		hud.clear()
		await _fade_to(0.0, 0.3)
		busy = false
		await run_dialogue(prologue)
		if _abort_flow:
			return
		busy = true
		await _fade_to(1.0, 0.8)
	await _begin_play([], "")


## « Choisir un chapitre » : une partie neuve au début du chapitre `id` (voir src/core/chapter_start.gd).
## Le chapitre 1 est la nouvelle partie ordinaire, prologue compris. Aucune sauvegarde n'est touchée.
func start_chapter(id: String) -> void:
	if busy:
		return
	if ChapterStart.is_new_game(id):
		await start_new_game()
		return
	busy = true
	await _fade_to(1.0)
	title.close()
	if not ChapterStart.apply(GameState, id):
		push_error("Début de chapitre inconnu : " + id)
		GameState.new_game()
	SaveManager.start_unsaved()   # la partie n'a pas d'emplacement : rien ne s'écrase sans que le joueur le choisisse
	await _begin_play([], "")
	var opening := str(ChapterStart.entry(id).get("opening", ""))   # scène d'ouverture qui n'est pas à l'arrivée sur la carte
	if opening != "" and mode == Mode.PLAY and not busy:
		await run_dialogue(opening)


func _on_chapter_chosen(id: String) -> void:
	var e := ChapterStart.entry(id)
	var ask := "Commencer ici ?\n%s\n%s" % [str(e.get("title", id)), str(e.get("place", ""))]
	if await confirm.ask(ask, "Commencer"):
		chapters_screen.close(true)
		start_chapter(id)
	else:
		chapters_screen.refocus()


func _on_chapters_closed() -> void:
	if mode == Mode.TITLE and not busy:
		title.refocus()


## Reprend une partie : la plus récente, ou l'emplacement `slot` ("m1", "a2"...).
func continue_game(slot: String = "") -> void:
	if busy:
		return
	if not SaveManager.load_game(slot):
		if mode == Mode.TITLE:
			title.open()
		else:
			hud.toast("Cette sauvegarde est illisible.")
		return
	busy = true
	pause.close(true)
	await _fade_to(1.0)
	title.close()
	await _begin_play(GameState.player_pos, GameState.player_facing)


func _begin_play(pos: Array, facing: String) -> void:
	var map_id := GameState.map_id
	if not Database.has_map(map_id):
		push_error("Carte introuvable : %s. Retour au point de départ." % map_id)
		GameState.new_game()
		map_id = GameState.map_id
		pos = []
	mode = Mode.PLAY
	GameState.playing = true
	await _loading_on()
	await _load_world(map_id, GameState.spawn_id, pos, facing, false)
	await _arrive()


func change_map(map_id: String, spawn_id: String) -> void:
	if busy or mode != Mode.PLAY:
		return
	if not Database.has_map(map_id):
		push_error("Passage vers une carte inconnue : " + map_id)
		return
	busy = true
	world.set_input(false)
	hud.hide_prompt()
	Sfx.play("door")
	await _fade_to(1.0, 0.3)
	GameState.map_id = map_id
	GameState.spawn_id = spawn_id
	GameState.player_pos = []
	await _loading_on()
	await _load_world(map_id, spawn_id, [], "", false)
	SaveManager.autosave("lieu")   # sauvegarde automatique à chaque changement de lieu
	await _arrive()


## Fin commune de toute arrivée sur une carte : fondu, bandeau, scènes d'entrée, puis main au joueur.
func _arrive() -> void:
	var entered := world
	await get_tree().process_frame
	await _fade_to(0.0, 0.5)
	if world != entered:
		return
	hud.banner(str(world.map.get("name", "")), str(world.map.get("region", "")))
	hud.set_softness(Database.softness(world.map))
	busy = false
	Tutorial.fire("arrive")
	for e: Variant in world.map.get("on_enter", []):
		if not (e is Dictionary):
			continue
		var unless := str(e.get("unless", ""))
		if unless != "" and GameState.has_flag(unless):
			continue
		await run_dialogue(str(e.get("dialogue", "")))
		if _abort_flow or world != entered:
			return
	world.set_input(true)


# ------------------------------------------------------------------ dialogues

func run_dialogue(dialogue_id: String) -> void:
	var current := world
	if current != null:
		current.set_input(false)
	hud.hide_prompt()
	dialogue.start(dialogue_id)
	# Un dialogue dont toutes les branches sont muettes (condition fausse, `set` seuls) se termine
	# dans `start` même : le signal est déjà parti, l'attendre bloquerait pour toujours.
	if dialogue.active or Database.get_dialogue(dialogue_id).is_empty():
		await dialogue.finished
	if _abort_flow:
		return
	if _credits_pending:
		_credits_pending = false
		await play_credits()
		return
	if _jump.size() == 2:
		# action `va:<carte>:<arrivée>` : changement de lieu demandé par un dialogue (chapitre 5)
		var to: Array = _jump
		_jump = []
		if world == current and mode == Mode.PLAY and not busy:
			await change_map(str(to[0]), str(to[1]))
			return
	if world == current and current != null and mode == Mode.PLAY and not busy:
		if current.needs_refresh():
			await _refresh_world()
		else:
			current.set_input(true)


## Fin du jeu : la partie est marquée terminée et sauvegardée, le générique défile, puis retour à l'écran-titre.
func play_credits() -> void:
	GameState.set_flag("partie_terminee")
	GameState.chapter = "partie_terminee"
	SaveManager.save_game()
	busy = true
	await _fade_to(1.0, 1.2)
	if world != null:
		world.set_input(false)
	Music.play(str(Database.game.get("credits_music", "village")))
	var lines: Array = Database.game.get("credits", [])
	credits.play(lines)
	await _fade_to(0.0, 0.8)   # le fond noir du générique est opaque : on lève le voile pour le laisser apparaître
	await credits.finished
	busy = false
	await show_title()


## Reconstruit la carte sur place quand un drapeau a fait apparaître ou disparaître un objet.
func _refresh_world() -> void:
	busy = true
	await _fade_to(1.0, 0.25)
	_sync_state()
	await _loading_on()
	await _load_world(GameState.map_id, "", GameState.player_pos, GameState.player_facing, false)
	await get_tree().process_frame
	await _fade_to(0.0, 0.3)
	busy = false
	world.set_input(true)


# -------------------------------------------------------------------- combats

var _battle_running := false   # un combat est en cours de lancement, de jeu ou de retrait


## Lance un combat et attend sa fin. Renvoie "victory", "fled" ou "title".
## La carte est mise de côté pendant le combat, puis remise en place.
func start_battle(encounter: Dictionary) -> String:
	var list: Variant = encounter.get("enemies", [])
	if not (list is Array) or (list as Array).is_empty():
		push_warning("Rencontre vide ou inconnue.")
		return "fled"
	# Un seul combat à la fois : si le précédent finit encore de se retirer (fondu), on l'attend.
	# Sans cela les deux coroutines se partageaient la variable `battle` et le décor du premier
	# combat restait dans l'arbre sous le second.
	while _battle_running:
		await get_tree().process_frame
	_battle_running = true
	busy = true
	hud.hide_prompt()
	hud.hide_banner()   # le nom du lieu ne reste pas affiché pendant un combat
	var points_before := GameState.party_talent_points()
	var field := world
	encounter = BattleScene.resolve(encounter, field.map if field != null else {})   # arène : rencontre, sinon carte
	if field != null:
		field.set_input(false)
		# Le Ramollissement du lieu pèse sur le combat (sauf combat scénarisé qui fixe le sien).
		if not encounter.has("ramollissement") and not encounter.has("party"):
			encounter = encounter.duplicate()
			encounter["ramollissement"] = Database.softness(field.map)
	hud.set_softness(0.0)
	# Combat sans fuite (boss, scène) : sauvegarde automatique juste avant, pour pouvoir revenir.
	var token := ""
	battle_ui.before_battle_slot = ""
	if field != null and not bool(encounter.get("flee", true)):
		token = str(Time.get_ticks_msec())
		if SaveManager.autosave("combat", token) != "":
			battle_ui.before_battle_slot = SaveManager.find_battle_slot(token)
	Sfx.play("encounter")
	var music_before := Music.current
	await _fade_to(1.0, 0.35)
	if field != null and field.get_parent() == self:
		remove_child(field)
	var outcome := "retry"
	while outcome == "retry":
		RenderingServer.global_shader_parameter_set("focus_world", Vector3(0.0, 0.0, 100000.0)); Music.play(Music.for_encounter(encounter), 0.4)
		_set_loading(true)
		Sprites.bg_pause = true
		await get_tree().process_frame
		var scene := BattleScene.new()
		battle = scene
		scene.name = "Battle"
		add_child(scene)
		move_child(scene, 0)
		scene.auto = auto_battles
		scene.fast = auto_battles
		scene.setup(encounter, battle_ui)
		scene.run()
		Sprites.bg_pause = false
		_set_loading(false)
		await _fade_to(0.0, 0.4)
		if str(scene.outcome) == "":
			await scene.finished
		outcome = str(scene.outcome)
		await _fade_to(1.0, 0.4)
		battle_ui.close()
		remove_child(scene)
		scene.queue_free()
		battle = null
	battle_ui.before_battle_slot = ""
	if outcome == "title" or outcome.begins_with("load:"):
		if field != null:
			field.queue_free()
			world = null
		busy = false
		_battle_running = false
		if outcome.begins_with("load:"):
			_pending_load = outcome.substr(5)
			outcome = "load"
		return outcome
	Music.play(music_before)
	if field != null:
		add_child(field)
		move_child(field, 0)
		field.camera.make_current()
		hud.set_softness(Database.softness(field.map))
	await _fade_to(0.0, 0.4)
	busy = false
	_battle_running = false
	if GameState.party_talent_points() > points_before:
		hud.toast("Points de talent à dépenser : %s, puis « Talents »" % str(Tutorial.caps_for("menu")[0]))
		Tutorial.fire("talent_point")
	return outcome


## Après une défaite : retour à l'écran-titre, ou chargement de la sauvegarde choisie.
func _leave_after_defeat(outcome: String) -> void:
	if outcome == "load" and _pending_load != "":
		var slot := _pending_load
		_pending_load = ""
		_abort_flow = false
		continue_game(slot)
	else:
		show_title()


func _on_dialogue_battle(encounter_id: String) -> void:
	var outcome := "victory"
	var enc := Database.get_encounter(encounter_id)
	if enc.is_empty():
		push_warning("Rencontre inconnue : " + encounter_id)
	else:
		outcome = await start_battle(enc)
	if outcome == "title" or outcome == "load":
		_abort_flow = true
		dialogue.abort()
		_leave_after_defeat(outcome)
		return
	if outcome == "victory":
		GameState.set_flag("combat_" + encounter_id)
	dialogue.resume()


func _on_encounter(table_id: String) -> void:
	if busy or dialogue.active or mode != Mode.PLAY or battle != null:
		return
	var enc := Database.roll_encounter(table_id, GameState.active_party().size())
	if enc.is_empty():
		return
	var outcome: String = await start_battle(enc)
	if outcome == "title" or outcome == "load":
		_leave_after_defeat(outcome)
	elif world != null and not dialogue.active:
		world.set_input(true)


func _on_interact(target: Dictionary) -> void:
	if busy or dialogue.active or mode != Mode.PLAY:
		return
	var id := str(target.get("dialogue", ""))
	if not Database.has_dialogue(id):
		push_warning("Aucun dialogue pour : " + id)
		return
	var node: Variant = target.get("node")
	if node is Node3D and (node as Node3D).has_method("face_towards"):
		node.face_towards(world.player.position)
	Sfx.play("confirm")
	run_dialogue(id)


func _on_trigger(dialogue_id: String) -> void:
	if busy or dialogue.active or mode != Mode.PLAY:
		return
	run_dialogue(dialogue_id)


func _on_dialogue_action(action: String) -> void:
	match action:
		"save":
			if SaveManager.save_game():
				Sfx.play("save")
				hud.toast("Partie sauvegardée (%s)" % SaveManager.slot_label(SaveManager.current_slot).to_lower())
				Tutorial.fire("save")
			elif SaveManager.unchosen:
				hud.toast("Pas d'emplacement libre : sauvegardez par la pause, en choisissant celui à remplacer.")
		"rest":
			GameState.heal_party()
			Sfx.play("heal")
			hud.toast("L'équipe est reposée")
			Tutorial.fire("rest")
		"generique":
			_credits_pending = true   # joué à la fin du dialogue : voir `play_credits`
		_:
			if action.begins_with("va:"):
				var dest := action.substr(3).split(":")
				if dest.size() == 2 and Database.has_map(dest[0]):
					_jump = [dest[0], dest[1]]
				else:
					push_warning("Action de déplacement inconnue : " + action)
			elif action.begins_with("groupe:"):
				# `groupe:a,b,c,d` : l'équipe se scinde ou se réunit (chapitre 5). Le premier nom
				# mène ; les autres recrutés attendent sur le banc, fiche conservée.
				# `groupe:tous` rappelle le banc derrière l'équipe actuelle.
				var spec := action.substr(7)
				var ids: Array = []
				if spec == "tous":
					ids = GameState.party + GameState.bench
				else:
					ids = Array(spec.split(","))
				if not GameState.set_group(ids):
					push_warning("Action de groupe sans personnage valable : " + action)
			elif action.begins_with("equipe:"):
				# `equipe:<id>:<objet>` : le personnage équipe l'objet pris dans le sac (chapitre 5 :
				# la Louche Blanche de Glandoulf, la dague de Merri).
				var eq := action.substr(7).split(":")
				if eq.size() < 2 or not GameState.equip(eq[0], eq[1]):
					push_warning("Équipement impossible : " + action)
			elif action.begins_with("quitte:"):
				# un compagnon quitte définitivement l'équipe (chapitre 4 : la chute de Glandoulf) ;
				# la carte reconstruite à la fin du dialogue prend le nouveau meneur.
				# `quitte:<id>` ou `quitte:<id>:<meneur>` : le second nom prend la tête de l'équipe.
				var parts := action.substr(7).split(":")
				GameState.party.erase(parts[0])
				if parts.size() > 1 and GameState.party.has(parts[1]):
					GameState.party.erase(parts[1])
					GameState.party.insert(0, parts[1])
				GameState.refresh_quests()
			else:
				push_warning("Action de dialogue inconnue : " + action)


# ---------------------------------------------------------------------- pause

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		PauseMenu.toggle_fullscreen()
		return
	if mode == Mode.PLAY and world != null and battle == null and not busy and not dialogue.active and not pause.visible and not menus.visible and not talents.visible and not saves.visible and not settings_screen.visible and not Tutorial.help_open() and event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		_open_pause()
	elif mode == Mode.PLAY and world != null and battle == null and not busy and not dialogue.active and not pause.visible and not menus.visible and not talents.visible and not saves.visible and not settings_screen.visible and not Tutorial.help_open() and event.is_action_pressed("journal"):
		get_viewport().set_input_as_handled()
		_open_journal()


## Touche « journal » : le journal de quêtes s'ouvre directement, et rend la main au jeu en se fermant.
func _open_journal() -> void:
	world.set_input(false)
	hud.hide_prompt()
	_menus_from = "journal"
	menus.open("quests")


func _open_pause() -> void:
	world.set_input(false)
	hud.hide_prompt()
	pause.open("%s   ·   %s de jeu   ·   %d écus\n%s" % [str(world.map.get("name", "")), GameState.playtime_text(), GameState.money, GameState.party_summary()])


# ------------------------------------------- équipe, inventaire, quêtes, boutiques

func _on_pause_screen(which: String) -> void:
	pause.close(true)
	if which == "talents":
		_talents_from = "pause"
		talents.open()
		return
	_menus_from = "pause"
	menus.open(which)


## La fiche d'un personnage (écran d'équipe) demande ses talents.
func _on_team_talents(who: String) -> void:
	menus.close(true)
	_talents_from = "team"
	talents.open(who)


func _on_talents_closed() -> void:
	var from := _talents_from
	_talents_from = ""
	if mode != Mode.PLAY or world == null or busy:
		return
	if from == "team":
		_menus_from = "pause"
		menus.open("team")
	else:
		_open_pause()


func _on_dialogue_shop(shop_id: String) -> void:
	if Database.get_shop(shop_id).is_empty():
		push_warning("Boutique inconnue : " + shop_id)
		dialogue.resume()
		return
	await Tutorial.fire_wait("shop")
	_menus_from = "dialogue"
	menus.open_shop(shop_id)


func _on_menus_closed() -> void:
	var from := _menus_from
	_menus_from = ""
	if from == "dialogue":
		dialogue.resume()
	elif from == "pause" and mode == Mode.PLAY and world != null and not busy:
		_open_pause()
	elif from == "journal" and mode == Mode.PLAY and world != null and not busy and not dialogue.active:
		world.set_input(true)


func _on_quest_started(id: String) -> void:
	hud.toast("Nouvelle quête : %s" % str(Database.get_quest(id).get("name", id)))
	Tutorial.fire("quest_started")


func _on_quest_completed(id: String, reward: Dictionary) -> void:
	Sfx.play("save")
	var text := "Quête accomplie : %s" % str(Database.get_quest(id).get("name", id))
	var gain := GameState.reward_text(reward)
	if gain != "":
		text += "\nRécompense : " + gain
	hud.toast(text)


func _on_pause_closed() -> void:
	if mode == Mode.PLAY and world != null and not busy and not dialogue.active:
		world.set_input(true)


## Ouvre la liste des sauvegardes. `from` : "title" ou "pause" (où revenir si on annule).
func _open_saves(which: String, from: String) -> void:
	if from == "pause":
		pause.close(true)
	saves.open(which, from)


## Écran-titre, « Quitter » : on confirme (Non par défaut), le titre garde la main si on renonce.
func _on_title_quit() -> void:
	if await confirm.ask("Quitter le jeu ?", "Quitter"):
		get_tree().quit()
	elif mode == Mode.TITLE:
		title.refocus()


## Pause, « Retour à l'écran-titre » : la partie non sauvegardée serait perdue, donc on demande.
func _on_pause_title() -> void:
	pause.close(true)
	if await confirm.ask("Revenir à l'écran-titre ?\nCe qui n'a pas été sauvegardé sera perdu.", "Revenir au titre"):
		pause.forget()
		show_title()
	elif mode == Mode.PLAY and world != null and not busy:
		_open_pause()


## Pause, « Quitter le jeu ».
func _on_pause_quit() -> void:
	pause.close(true)
	if await confirm.ask("Quitter le jeu ?\nCe qui n'a pas été sauvegardé sera perdu.", "Quitter"):
		get_tree().quit()
	elif mode == Mode.PLAY and world != null and not busy:
		_open_pause()


func _on_pad_closed() -> void:
	if pad_screen.context.begins_with("settings_"):
		settings_screen.open(pad_screen.context.trim_prefix("settings_"))
	elif mode == Mode.TITLE:
		title.open()


func _on_settings_closed() -> void:
	if settings_screen.context == "title":
		if mode == Mode.TITLE:
			title.open()
	elif mode == Mode.PLAY and world != null and not busy:
		_open_pause()


func _on_saves_finished(chosen: String) -> void:
	match saves.context:
		"defeat":
			return   # l'écran de défaite attend lui-même la réponse
		"title":
			if chosen != "":
				continue_game(chosen)
			elif mode == Mode.TITLE:
				title.open()
		"pause":
			if chosen != "":
				continue_game(chosen)
			elif mode == Mode.PLAY and world != null and not busy:
				_open_pause()


func _on_slot_saved(id: String) -> void:
	Sfx.play("save")
	hud.toast("Partie sauvegardée (%s)" % SaveManager.slot_label(id).to_lower())


func _on_save_requested() -> void:
	_open_saves("save", "pause")


func _sync_state() -> void:
	if mode == Mode.PLAY and world != null and world.player != null:
		GameState.map_id = world.map_id
		GameState.player_pos = world.player_xz()
		GameState.player_facing = world.player.facing


func _process(_delta: float) -> void:
	if mode != Mode.PLAY or world == null or battle != null or dialogue.active or pause.visible or menus.visible or talents.visible or saves.visible or settings_screen.visible or Tutorial.help_open() or world.focus.is_empty():
		hud.hide_prompt()
		return
	var it: Dictionary = world.focus
	var p: Vector3 = world.interactable_position(it) + Vector3(0.0, float(it.get("height", 1.3)) + 0.45, 0.0)
	hud.show_prompt(str(it.get("label", "Examiner")), world.screen_position(p))
	Tutorial.fire("interact_near")
