extends Control
## Écran « Paramètres », ouvert depuis l'écran-titre et le menu de pause.
## Haut / bas : changer de ligne. Gauche / droite : changer la valeur. Entrée : valeur suivante.
## Échap ou retour : revenir (les réglages sont alors enregistrés). Tout s'applique tout de suite.

signal closed

const UI = preload("res://src/ui/ui_kit.gd")

var context := ""           # « title » ou « pause » : lu par main.gd pour savoir où revenir

var _panel: PanelContainer
var _scroll: ScrollContainer
var _list: VBoxContainer
var _help: Label
var _rows: Dictionary = {}   # identifiant du réglage -> Button
var _ordered: Array = []     # lignes focalisables, dans l'ordre
var _reset: Button
var _back: Button
var _opened_at := 0
var _remember: Control = null


func _ready() -> void:
	UI.full_rect(self)
	visible = false
	var frame := UI.screen(self, "Paramètres", Vector2(980, 0), 0.82)
	_panel = frame["panel"]
	var body: VBoxContainer = frame["body"]
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(920, 380)
	_scroll.follow_focus = true
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 0)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	_help = UI.label("", 17, UI.INK_DIM, false, true)
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help.custom_minimum_size = Vector2(920, 48)
	body.add_child(_help)
	(frame["foot"] as HBoxContainer).add_child(UI.hints([["Haut / bas", "ligne"], ["Gauche / droite", "valeur"], ["Entrée", "changer"], ["Échap", "retour"]]))
	_build()


func _build() -> void:
	for row: Dictionary in Settings.ROWS:
		if row.has("section"):
			var gap := Control.new()
			gap.custom_minimum_size = Vector2(0, 8)
			_list.add_child(gap)
			var head := UI.caps(str(row["section"]), 14, UI.GOLD_DIM)
			head.add_theme_constant_override("line_spacing", 0)
			var m := MarginContainer.new()
			m.add_theme_constant_override("margin_left", 32)
			m.add_child(head)
			_list.add_child(m)
		elif row.has("info"):
			var b := UI.menu_button(str(row["info"]), 21)
			b.disabled = true
			b.focus_mode = Control.FOCUS_NONE
			b.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var note := str(row["text"])
			b.draw.connect(func() -> void:
				var f := UI.font(false, true)
				var w := f.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
				b.draw_string(f, Vector2(b.size.x - w - 24.0, b.size.y * 0.5 + 4.0), note, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UI.INK_FAINT))
			_list.add_child(b)
		elif row.has("action"):   # ligne qui déclenche quelque chose au lieu de régler une valeur
			var b := UI.menu_button(str(row["label"]), 21)
			b.pressed.connect(_on_action.bind(str(row["action"])))
			b.focus_entered.connect(func() -> void: _help.text = "Tous les conseils de jeu reviendront, un par un, au moment où ils servent.")
			_list.add_child(b)
			_ordered.append(b)
		else:
			var id := str(row["id"])
			var b := UI.menu_button(str(row["label"]), 21)
			b.set_meta("id", id)
			b.set_meta("gauge", bool(row.get("gauge", false)))
			b.draw.connect(_draw_value.bind(b))
			b.focus_entered.connect(_show_help.bind(id))
			b.pressed.connect(func() -> void: _step(id, 1))
			_list.add_child(b)
			_rows[id] = b
			_ordered.append(b)
	var gap2 := Control.new()
	gap2.custom_minimum_size = Vector2(0, 10)
	_list.add_child(gap2)
	_reset = UI.menu_button("Valeurs par défaut", 21)
	_reset.pressed.connect(_on_reset)
	_reset.focus_entered.connect(func() -> void: _help.text = "Remet tous les réglages comme au premier lancement du jeu.")
	_list.add_child(_reset)
	_back = UI.menu_button("Retour", 21)
	_back.pressed.connect(func() -> void: close())
	_back.focus_entered.connect(func() -> void: _help.text = "Enregistre les réglages et revient.")
	_list.add_child(_back)
	_ordered.append(_reset)
	_ordered.append(_back)


func _draw_value(b: Button) -> void:
	var id := str(b.get_meta("id"))
	var focused := b.has_focus()
	var inert := Settings.is_inert(id)
	var col := UI.GOLD if focused else UI.INK_DIM
	if inert:
		col = Color(col, 0.45)
	var text := Settings.value_label(id)
	var font := UI.font()
	var size := 20
	var right := b.size.x - 36.0
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	var y := b.size.y * 0.5 + 5.0
	if focused:
		b.draw_string(font, Vector2(right - w - 22.0, y), "‹", HORIZONTAL_ALIGNMENT_LEFT, -1, size, UI.GOLD)
		b.draw_string(font, Vector2(right + 10.0, y), "›", HORIZONTAL_ALIGNMENT_LEFT, -1, size, UI.GOLD)
	b.draw_string(font, Vector2(right - w, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)
	if bool(b.get_meta("gauge")):
		var bar_w := 120.0
		var x0 := right - 150.0 - 90.0
		var frac := clampf(float(int(Settings.get_value(id))) / 100.0 if id != "echelle" else (float(int(Settings.get_value(id))) - 50.0) / 50.0, 0.0, 1.0)
		b.draw_rect(Rect2(x0, b.size.y * 0.5 - 2.0, bar_w, 4.0), Color(1, 1, 1, 0.10))
		b.draw_rect(Rect2(x0, b.size.y * 0.5 - 2.0, bar_w * frac, 4.0), Color(UI.GOLD, 0.85 if focused else 0.5))


func _show_help(id: String) -> void:
	_help.text = Settings.help(id)


func _refresh() -> void:
	for id: String in _rows:
		(_rows[id] as Button).queue_redraw()
	var f := get_viewport().gui_get_focus_owner()
	if f is Button and f.has_meta("id"):
		_show_help(str(f.get_meta("id")))


## Passe à la valeur suivante (dir = 1) ou précédente (-1) ; les listes bouclent.
func _step(id: String, dir: int) -> void:
	var opts: Array = Settings.choices(id)
	if opts.is_empty():
		return
	var cur: Variant = Settings.get_value(id)
	var i := 0
	for k in opts.size():
		if typeof((opts[k] as Array)[0]) == typeof(cur) and (opts[k] as Array)[0] == cur:
			i = k
	var j := i + dir
	if j < 0 or j >= opts.size():
		if bool((_rows[id] as Button).get_meta("gauge")):
			return   # les curseurs s'arrêtent aux bouts
		j = posmod(j, opts.size())
	if j == i:
		return
	Settings.set_value(id, (opts[j] as Array)[0])
	Sfx.play("blip")
	_refresh()


func _on_action(action: String) -> void:
	if action == "revoir":
		Tutorial.reset_seen()
		Sfx.play("confirm")
		_help.text = "Les conseils de jeu reviendront, un par un, au moment où ils servent."


func _on_reset() -> void:
	Settings.reset_defaults()
	Sfx.play("confirm")
	_refresh()
	_help.text = "Réglages remis comme au premier lancement."


func open(new_context: String = "") -> void:
	context = new_context
	_opened_at = Engine.get_process_frames()
	visible = true
	_refresh()
	var first: Control = _ordered[0]
	if _remember != null and is_instance_valid(_remember):
		first = _remember
	first.grab_focus()
	UI.pop(_panel)
	Sfx.play("confirm")


func close(silent: bool = false) -> void:
	if not visible:
		return
	var f := get_viewport().gui_get_focus_owner()
	_remember = f if f is Button and _ordered.has(f) else null
	visible = false
	Settings.save()
	if not silent:
		Sfx.play("cancel")
	closed.emit()


func _input(event: InputEvent) -> void:
	if not visible or Engine.get_process_frames() == _opened_at:
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
		return
	var f := get_viewport().gui_get_focus_owner()
	if f is Button and f.has_meta("id"):
		if event.is_action_pressed("ui_left", true):
			get_viewport().set_input_as_handled()
			_step(str(f.get_meta("id")), -1)
		elif event.is_action_pressed("ui_right", true):
			get_viewport().set_input_as_handled()
			_step(str(f.get_meta("id")), 1)
