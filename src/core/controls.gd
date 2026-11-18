extends Node
## Déclare toutes les commandes du jeu par code : rien à régler dans l'éditeur.
## Les touches de déplacement utilisent les touches PHYSIQUES W/A/S/D,
## ce qui donne Z/Q/S/D sur un clavier AZERTY.

const DEADZONE := 0.35

## Dernier périphérique utilisé : les rappels de touches de l'interface s'y adaptent.
var pad := false

signal device_changed(is_pad: bool)


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
	_action("delete", [KEY_DELETE], [], [JOY_BUTTON_X])   # effacer (écran des sauvegardes)
	# Navigation dans les menus : on complète les actions intégrées de Godot.
	_extend_physical("ui_up", KEY_W)
	_extend_physical("ui_down", KEY_S)
	_extend_physical("ui_left", KEY_A)
	_extend_physical("ui_right", KEY_D)
	_extend_physical("ui_accept", KEY_E)
	# gâchettes : changer de page / de personnage dans les écrans à onglets
	_extend_button("ui_page_up", JOY_BUTTON_LEFT_SHOULDER)
	_extend_button("ui_page_down", JOY_BUTTON_RIGHT_SHOULDER)


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5):
		set_pad(true)
	elif event is InputEventKey or event is InputEventMouseButton:
		set_pad(false)


## Change de périphérique actif (les tests s'en servent aussi).
func set_pad(on: bool) -> void:
	if on == pad:
		return
	pad = on
	device_changed.emit(on)


func _extend_button(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventJoypadButton.new()
	ev.button_index = button as JoyButton
	InputMap.action_add_event(action, ev)


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
		ev.button_index = b as JoyButton
		InputMap.action_add_event(action, ev)
	if axis >= 0:
		var ev := InputEventJoypadMotion.new()
		ev.axis = axis as JoyAxis
		ev.axis_value = axis_value
		InputMap.action_add_event(action, ev)


func _extend_physical(action: String, key: int) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventKey.new()
	ev.physical_keycode = key as Key
	InputMap.action_add_event(action, ev)
