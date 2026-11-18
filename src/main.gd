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

enum Mode { BOOT, TITLE, PLAY }

var mode: Mode = Mode.BOOT
var world: Node3D = null
var busy := false
var battle: Node3D = null       # combat en cours, sinon null
var auto_battles := false       # tests : les combats se jouent tout seuls, sans attente
var _abort_flow := false        # une défaite a renvoyé à l'écran-titre : les scènes en cours s'arrêtent

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
var _fade: ColorRect
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

	var top := CanvasLayer.new()
	top.layer = 10
	add_child(top)
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(_fade)

	title.new_game_requested.connect(start_new_game)
	title.continue_requested.connect(func() -> void: continue_game())
	title.load_requested.connect(func() -> void: _open_saves("load", "title"))
	saves.finished.connect(_on_saves_finished)
	settings_screen.closed.connect(_on_settings_closed)
	title.add_entry("Paramètres", func() -> void: settings_screen.open("title"))
	pause.add_entry("Paramètres", func() -> void:
		pause.close(true)
		settings_screen.open("pause"))
	saves.saved.connect(_on_slot_saved)
	pause.load_requested.connect(func() -> void: _open_saves("load", "pause"))
	title.quit_requested.connect(func() -> void: get_tree().quit())
	pause.resumed.connect(_on_pause_closed)
	pause.save_requested.connect(_on_save_requested)
	pause.title_requested.connect(func() -> void:
		pause.close(true)
		show_title())
	pause.quit_requested.connect(func() -> void: get_tree().quit())
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
	SaveManager.before_save.connect(_sync_state)

	show_title()


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


func _load_world(map_id: String, spawn_id: String, pos: Array, facing: String, attract: bool) -> void:
	_free_world()
	world = World.new()
	world.name = "World"
	add_child(world)
	move_child(world, 0)
	world.setup(map_id, spawn_id, pos, facing, attract)
	Music.play(Music.default("title") if attract else Music.for_map(world.map))
	world.warp_requested.connect(change_map)
	world.interact_requested.connect(_on_interact)
	world.trigger_fired.connect(_on_trigger)
	world.encounter_requested.connect(_on_encounter)


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
	_load_world(str(Database.game.get("title_map", "bittebourg")), "", [], "", true)
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
	_load_world(map_id, GameState.spawn_id, pos, facing, false)
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
	_load_world(map_id, spawn_id, [], "", false)
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
	await dialogue.finished
	if _abort_flow:
		return
	if world == current and current != null and mode == Mode.PLAY and not busy:
		if current.needs_refresh():
			await _refresh_world()
		else:
			current.set_input(true)


## Reconstruit la carte sur place quand un drapeau a fait apparaître ou disparaître un objet.
func _refresh_world() -> void:
	busy = true
	await _fade_to(1.0, 0.25)
	_sync_state()
	_load_world(GameState.map_id, "", GameState.player_pos, GameState.player_facing, false)
	await get_tree().process_frame
	await _fade_to(0.0, 0.3)
	busy = false
	world.set_input(true)


# -------------------------------------------------------------------- combats

## Lance un combat et attend sa fin. Renvoie "victory", "fled" ou "title".
## La carte est mise de côté pendant le combat, puis remise en place.
func start_battle(encounter: Dictionary) -> String:
	var list: Variant = encounter.get("enemies", [])
	if not (list is Array) or (list as Array).is_empty():
		push_warning("Rencontre vide ou inconnue.")
		return "fled"
	busy = true
	hud.hide_prompt()
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
		battle = BattleScene.new()
		battle.name = "Battle"
		add_child(battle)
		move_child(battle, 0)
		battle.auto = auto_battles
		battle.fast = auto_battles
		battle.setup(encounter, battle_ui)
		battle.run()
		await _fade_to(0.0, 0.4)
		if str(battle.outcome) == "":
			await battle.finished
		outcome = str(battle.outcome)
		await _fade_to(1.0, 0.4)
		battle_ui.close()
		remove_child(battle)
		battle.queue_free()
		battle = null
	battle_ui.before_battle_slot = ""
	if outcome == "title" or outcome.begins_with("load:"):
		if field != null:
			field.queue_free()
			world = null
		busy = false
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
	if GameState.party_talent_points() > points_before:
		hud.toast("Points de talent à dépenser : Échap, puis « Talents »")
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
		"rest":
			GameState.heal_party()
			Sfx.play("heal")
			hud.toast("L'équipe est reposée")
		_:
			if action.begins_with("quitte:"):
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
	if mode == Mode.PLAY and world != null and battle == null and not busy and not dialogue.active and not pause.visible and not menus.visible and not talents.visible and not saves.visible and not settings_screen.visible and event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		_open_pause()


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
	_menus_from = "dialogue"
	menus.open_shop(shop_id)


func _on_menus_closed() -> void:
	var from := _menus_from
	_menus_from = ""
	if from == "dialogue":
		dialogue.resume()
	elif from == "pause" and mode == Mode.PLAY and world != null and not busy:
		_open_pause()


func _on_quest_started(id: String) -> void:
	hud.toast("Nouvelle quête : %s" % str(Database.get_quest(id).get("name", id)))


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
	if mode != Mode.PLAY or world == null or battle != null or dialogue.active or pause.visible or menus.visible or talents.visible or saves.visible or settings_screen.visible or world.focus.is_empty():
		hud.hide_prompt()
		return
	var it: Dictionary = world.focus
	var p: Vector3 = world.interactable_position(it) + Vector3(0.0, float(it.get("height", 1.3)) + 0.45, 0.0)
	hud.show_prompt(str(it.get("label", "Examiner")), world.screen_position(p))
