extends Node
## Déclare toutes les commandes du jeu par code : rien à régler dans l'éditeur.
## Les touches de déplacement utilisent les touches PHYSIQUES W/A/S/D,
## ce qui donne Z/Q/S/D sur un clavier AZERTY.

const DEADZONE := 0.35


func _ready() -> void:
	_action("move_left", [KEY_LEFT], [KEY_A], [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_action("move_right", [KEY_RIGHT], [KEY_D], [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_action("move_up", [KEY_UP], [KEY_W], [JOY_BUTTON_DPAD_UP], JOY_AXIS_LEFT_Y, -1.0)
	_action("move_down", [KEY_DOWN], [KEY_S], [JOY_BUTTON_DPAD_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_action("interact", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE], [KEY_E], [JOY_BUTTON_A])
	_action("cancel", [KEY_BACKSPACE], [KEY_X], [JOY_BUTTON_B])
	_action("menu", [KEY_ESCAPE, KEY_TAB, KEY_M], [], [JOY_BUTTON_START])
	_action("journal", [KEY_J], [], [JOY_BUTTON_Y])   # ouvre le journal de quêtes d'un geste
	_action("fullscreen", [KEY_F11, KEY_F], [], [])
	# Navigation dans les menus : on complète les actions intégrées de Godot.
	_extend_physical("ui_up", KEY_W)
	_extend_physical("ui_down", KEY_S)
	_extend_physical("ui_left", KEY_A)
	_extend_physical("ui_right", KEY_D)
	_extend_physical("ui_accept", KEY_E)
	# Manette dans les menus : A valide, B annule, croix et stick gauche déplacent le curseur,
	# quel que soit le numéro de la manette.
	_extend_pad("ui_accept", JOY_BUTTON_A)
	_extend_pad("ui_cancel", JOY_BUTTON_B)
	_extend_pad("ui_up", JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0)
	_extend_pad("ui_down", JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0)
	_extend_pad("ui_left", JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_extend_pad("ui_right", JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_extend_pad("ui_page_up", JOY_BUTTON_LEFT_SHOULDER)
	_extend_pad("ui_page_down", JOY_BUTTON_RIGHT_SHOULDER)


func _action(action: String, keys: Array, physical_keys: Array, buttons: Array, axis: int = -1, axis_value: float = 0.0) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, DEADZONE)
	for k: int in keys:
		var ev := InputEventKey.new()
		ev.keycode = k as Key
		InputMap.action_add_event(action, ev)
	for k: int in physical_keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k as Key
		InputMap.action_add_event(action, ev)
	for b: int in buttons:
		var ev := InputEventJoypadButton.new()
		# -1 : n'importe quelle manette. Sous Windows, un clavier ou une souris « de jeu »
		# prend souvent le numéro 0 et la vraie manette le numéro 1 : elle restait muette.
		ev.device = -1
		ev.button_index = b as JoyButton
		InputMap.action_add_event(action, ev)
	if axis >= 0:
		var ev := InputEventJoypadMotion.new()
		ev.device = -1
		ev.axis = axis as JoyAxis
		ev.axis_value = axis_value
		InputMap.action_add_event(action, ev)


func _extend_pad(action: String, button: int, axis: int = -1, axis_value: float = 0.0) -> void:
	if not InputMap.has_action(action):
		return
	# on retire d'abord les entrées de manette déjà présentes, pour ne rien doubler
	for old: InputEvent in InputMap.action_get_events(action):
		if old is InputEventJoypadButton or old is InputEventJoypadMotion:
			InputMap.action_erase_event(action, old)
	var ev := InputEventJoypadButton.new()
	ev.device = -1
	ev.button_index = button as JoyButton
	InputMap.action_add_event(action, ev)
	if axis >= 0:
		var motion := InputEventJoypadMotion.new()
		motion.device = -1
		motion.axis = axis as JoyAxis
		motion.axis_value = axis_value
		InputMap.action_add_event(action, motion)


func _extend_physical(action: String, key: int) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventKey.new()
	ev.physical_keycode = key as Key
	InputMap.action_add_event(action, ev)
