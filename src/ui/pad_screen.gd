extends Control
## Écran « Manette » : ce que le jeu voit de la manette, en direct. Ouvert depuis l'écran-titre et
## depuis Paramètres. Les boutons et axes reçus sont lus sur les événements bruts (pas sur les
## commandes du jeu) ; chaque commande s'allume quand elle est pressée. Le même contenu s'écrit
## dans user://manette.txt, et « Copier le diagnostic » le met dans le presse-papiers.

signal closed

const UI = preload("res://src/ui/ui_kit.gd")

var context := ""
var _panel: PanelContainer
var _verdict: Label
var _live: Label
var _info: Label
var _status: Label
var _chips: Dictionary = {}     # commande -> [PanelContainer, Label]
var _copy: Button
var _back: Button
var _opened_at := 0
var _style_on: StyleBoxFlat
var _style_off: StyleBoxFlat


func _ready() -> void:
	UI.full_rect(self)
	visible = false
	var frame := UI.screen(self, "Manette", UI.SCREEN_SIZE, 0.94)
	_panel = frame["panel"]
	_panel.add_theme_stylebox_override("panel", UI.soft_style(0.97, 26))
	var body: VBoxContainer = frame["body"]
	_verdict = UI.label("", 21, UI.GOLD, false, true)
	_verdict.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_verdict.custom_minimum_size = Vector2(0, 58)
	body.add_child(_verdict)
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 28)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(cols)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 8)
	cols.add_child(left)
	left.add_child(UI.caps("Manettes vues par le jeu", 14, UI.GOLD_DIM))
	_info = UI.label("", 16, UI.INK_DIM)
	_info.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_info.custom_minimum_size = Vector2(500, 0)
	left.add_child(_info)
	left.add_child(UI.caps("Reçu en direct", 14, UI.GOLD_DIM))
	_live = UI.label("", 18, UI.INK)
	_live.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(_live)
	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(380, 0)
	right.add_theme_constant_override("separation", 8)
	cols.add_child(right)
	right.add_child(UI.caps("Commandes du jeu (allumées quand pressées)", 14, UI.GOLD_DIM))
	_style_off = UI.panel_style(Color(1, 1, 1, 0.04), Color(UI.INK_FAINT, 0.6))
	_style_on = UI.panel_style(Color(UI.GOLD, 0.85), UI.GOLD)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	right.add_child(grid)
	var names := {"move_left": "gauche", "move_right": "droite", "move_up": "haut", "move_down": "bas", "interact": "valider", "cancel": "annuler", "menu": "menu", "journal": "journal", "delete": "effacer", "ui_accept": "ui valider", "ui_cancel": "ui annuler", "ui_up": "ui haut", "ui_down": "ui bas", "ui_left": "ui gauche", "ui_right": "ui droite"}
	for a: String in Controls.WATCHED:
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(118, 0)
		chip.add_theme_stylebox_override("panel", _style_off)
		var l := UI.label(str(names.get(a, a)), 15, UI.INK_DIM)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		chip.add_child(l)
		grid.add_child(chip)
		_chips[a] = [chip, l]
	var row := VBoxContainer.new()   # l'un sous l'autre : la croix passe de « Copier » à « Retour »
	row.add_theme_constant_override("separation", 2)
	body.add_child(row)
	_copy = UI.menu_button("Copier le diagnostic", 20)
	_copy.custom_minimum_size = Vector2(300, 0)
	_copy.pressed.connect(_on_copy)
	row.add_child(_copy)
	_back = UI.menu_button("Retour", 20)
	_back.custom_minimum_size = Vector2(200, 0)
	_back.pressed.connect(func() -> void: close())
	row.add_child(_back)
	_status = UI.label("", 16, UI.INK_DIM, false, true)
	_status.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	_status.custom_minimum_size = Vector2(0, 44)
	body.add_child(_status)
	(frame["foot"] as HBoxContainer).add_child(UI.hints(UI.KEYS_MENU))


func open(new_context: String = "") -> void:
	context = new_context
	_opened_at = Engine.get_process_frames()
	visible = true
	_status.text = Tutorial.expand("Ce diagnostic est aussi écrit dans :  %s\nSi la manette reste muette : choisir « Copier » avec {interact}, puis coller le texte dans un message." % Controls.report_location())
	_refresh()
	Controls.write_report()
	_copy.grab_focus()
	UI.pop(_panel)
	Sfx.play("confirm")


func close(silent: bool = false) -> void:
	if not visible:
		return
	if not silent:
		UI.ghost_fade(self)
	visible = false
	Controls.write_report()
	if not silent:
		Sfx.play("cancel")
	closed.emit()


func _on_copy() -> void:
	DisplayServer.clipboard_set(Controls.report_text())
	Sfx.play("confirm")
	_status.text = "Diagnostic copié : il n'y a plus qu'à le coller dans un message.\nFichier : %s" % Controls.report_location()


func _process(_delta: float) -> void:
	if not visible:
		return
	_refresh()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	Controls.note_event(event)
	if Engine.get_process_frames() == _opened_at:
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _refresh() -> void:
	_verdict.text = Controls.verdict()
	var lines: Array = []
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		lines.append("(aucune)")
	for d: int in pads:
		lines.append("%d : %s\nGUID %s\nconnue de Godot : %s%s" % [d, Input.get_joy_name(d), Input.get_joy_guid(d), "oui" if Input.is_joy_known(d) else "non", " (mapping de repli posé)" if Controls.generic_mapped.has(d) else ""])
	_info.text = "\n".join(lines)
	var b: Dictionary = Controls.last_button
	var a: Dictionary = Controls.last_axis
	var text := "Dernier bouton : %s\n" % ("aucun" if b.is_empty() else "%s (manette %d, %s)" % [Controls.button_name(int(b["index"])), int(b["device"]), "appuyé" if bool(b["pressed"]) else "relâché"])
	text += "Dernier axe : %s\n" % ("aucun" if a.is_empty() else "%s = %.2f" % [Controls.axis_name(int(a["axis"])), float(a["value"])])
	text += "Événements reçus : %d    Sondage direct : %s" % [Controls.raw_count, "bouton vu" if Controls.polled_press else "rien"]
	_live.text = text
	for act: String in _chips:
		var on := Input.is_action_pressed(act)
		var pair: Array = _chips[act]
		(pair[0] as PanelContainer).add_theme_stylebox_override("panel", _style_on if on else _style_off)
		(pair[1] as Label).add_theme_color_override("font_color", Color(0.1, 0.07, 0.03) if on else UI.INK_DIM)
