extends Control
## Menu de pause : reprendre, équipe, inventaire, quêtes, sauvegarder, plein écran, titre, quitter.

signal resumed
signal save_requested
signal load_requested
signal title_requested
signal quit_requested
signal screen_requested(which: String)   # "team", "talents", "inventory" ou "quests"

const UI = preload("res://src/ui/ui_kit.gd")

var _info: Label
var _message: Label
var _first: Button
var _talents: Button
var _opened_at := 0


func _ready() -> void:
	UI.full_rect(self)
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.06, 0.55)
	UI.full_rect(dim)
	add_child(dim)

	var center := CenterContainer.new()
	UI.full_rect(center)
	add_child(center)
	var panel := PanelContainer.new()
	var style := UI.panel_style()
	style.set_content_margin_all(26)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = Vector2(380, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	panel.add_child(box)

	var title := UI.label("Pause", 38, UI.GOLD, false, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_info = UI.label("", 18, UI.INK_DIM)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_info)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 12)
	box.add_child(gap)

	_first = _button(box, "Reprendre", func() -> void: close())
	_button(box, "Équipe", func() -> void: screen_requested.emit("team"))
	_talents = _button(box, "Talents", func() -> void: screen_requested.emit("talents"))
	_button(box, "Inventaire", func() -> void: screen_requested.emit("inventory"))
	_button(box, "Quêtes", func() -> void: screen_requested.emit("quests"))
	_button(box, "Sauvegarder", func() -> void: save_requested.emit())
	_button(box, "Charger", func() -> void: load_requested.emit())
	_button(box, "Plein écran", func() -> void: toggle_fullscreen())
	_button(box, "Retour à l'écran-titre", func() -> void: title_requested.emit())
	_button(box, "Quitter le jeu", func() -> void: quit_requested.emit())

	_message = UI.label("", 18, UI.GOLD, false, true)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.custom_minimum_size = Vector2(0, 30)
	box.add_child(_message)


func _button(parent: Control, text: String, action: Callable) -> Button:
	var b := UI.menu_button(text, 24)
	b.pressed.connect(func() -> void:
		Sfx.play("confirm")
		action.call())
	parent.add_child(b)
	return b


static func toggle_fullscreen() -> void:
	var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)


func open(info: String) -> void:
	_info.text = info
	_message.text = ""
	var points := GameState.party_talent_points()
	_talents.text = "Talents" if points <= 0 else "Talents   ·   %d point%s à dépenser" % [points, "s" if points > 1 else ""]
	_talents.add_theme_color_override("font_color", UI.INK if points <= 0 else Color("#bfe8ff"))
	visible = true
	_opened_at = Engine.get_process_frames()
	_first.grab_focus()
	Sfx.play("confirm")


func close(silent: bool = false) -> void:
	if not visible:
		return
	visible = false
	if not silent:
		Sfx.play("cancel")
		resumed.emit()


func notify(text: String) -> void:
	_message.text = text


func _input(event: InputEvent) -> void:
	if not visible or Engine.get_process_frames() == _opened_at:
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
