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
var _list: VBoxContainer
var _panel: PanelContainer
var _remember: Button = null   # ligne d'où l'on est parti vers un sous-écran : le focus y revient
var _opened_at := 0


func _ready() -> void:
	UI.full_rect(self)
	visible = false
	var frame := UI.screen(self, "Pause")
	_panel = frame["panel"]
	var body: VBoxContainer = frame["body"]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	body.add_child(row)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 0)
	_list.custom_minimum_size = Vector2(340, 0)
	row.add_child(_list)
	row.add_child(UI.vline())
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.add_theme_constant_override("separation", 8)
	row.add_child(side)
	side.add_child(UI.caps("En route", 14, UI.GOLD_DIM))
	_info = UI.label("", 17, UI.INK)
	_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_info.custom_minimum_size = Vector2(420, 0)
	side.add_child(_info)

	_first = add_entry("Reprendre", func() -> void: close(), false)
	add_entry("Équipe", func() -> void: screen_requested.emit("team"), false)
	_talents = add_entry("Talents", func() -> void: screen_requested.emit("talents"), false)
	add_entry("Inventaire", func() -> void: screen_requested.emit("inventory"), false)
	add_entry("Quêtes", func() -> void: screen_requested.emit("quests"), false)
	add_entry("Sauvegarder", func() -> void: save_requested.emit(), false)
	add_entry("Charger", func() -> void: load_requested.emit(), false)
	add_entry("Plein écran", func() -> void: toggle_fullscreen(), false)
	add_entry("Retour à l'écran-titre", func() -> void:
		_remember = null
		title_requested.emit(), false)
	add_entry("Quitter le jeu", func() -> void: quit_requested.emit(), false)

	_message = UI.label("", 18, UI.GOLD, false, true)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.custom_minimum_size = Vector2(0, 26)
	body.add_child(_message)
	(frame["foot"] as HBoxContainer).add_child(UI.hints(UI.KEYS_MENU))


## Ajoute une ligne au menu (avant « Retour à l'écran-titre » par défaut, pour accueillir
## plus tard un « Paramètres » sans rien refaire) et la renvoie.
func add_entry(text: String, action: Callable, before_exit: bool = true) -> Button:
	var b := UI.menu_button(text, 23)
	b.pressed.connect(func() -> void:
		_remember = b
		Sfx.play("confirm")
		action.call())
	_list.add_child(b)
	if before_exit and _list.get_child_count() > 2:
		_list.move_child(b, _list.get_child_count() - 3)
	return b


static func toggle_fullscreen() -> void:
	Settings.toggle_fullscreen()


func open(info: String) -> void:
	_info.text = info
	_message.text = ""
	var points := GameState.party_talent_points()
	_talents.text = "Talents" if points <= 0 else "Talents   ·   %d point%s à dépenser" % [points, "s" if points > 1 else ""]
	_talents.add_theme_color_override("font_color", UI.INK if points <= 0 else Color("#bfe8ff"))
	visible = true
	_opened_at = Engine.get_process_frames()
	if _remember != null and is_instance_valid(_remember) and _remember != _first:
		_remember.grab_focus()   # retour d'un sous-écran : le curseur retrouve sa place
	else:
		_first.grab_focus()
	UI.pop(_panel)
	Sfx.play("confirm")


func close(silent: bool = false) -> void:
	if not visible:
		return
	visible = false
	if not silent:
		_remember = null
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
