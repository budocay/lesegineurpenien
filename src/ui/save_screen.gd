extends Control
## Écran des sauvegardes : liste des emplacements pour sauvegarder ou charger.
## Même style et mêmes commandes que les autres menus : flèches, Entrée/E, Échap pour revenir.
## Suppr (clavier) ou X (manette) efface l'emplacement visé, après confirmation.

signal finished(chosen: String)   # identifiant à charger, ou "" (annulé, ou sauvegarde faite)
signal saved(id: String)

const UI = preload("res://src/ui/ui_kit.gd")

const ROW_H := 62
const FACE := 44.0

var mode := "load"        # "save" ou "load"
var context := ""         # à qui rendre la main : "title", "pause" ou "defeat" (lu par main.gd)

var _title: Label
var _hint: HBoxContainer
var _note: Label
var _panel: PanelContainer
var _scroll: ScrollContainer
var _list: VBoxContainer
var _modal: Control
var _modal_text: Label
var _modal_yes: Button
var _modal_no: Button
var _modal_action: Callable
var _rows: Dictionary = {}     # id -> Button
var _entries: Dictionary = {}  # id -> entrée de SaveManager.list_slots()
var _opened_at := 0
var _last_focus: Control = null


func _ready() -> void:
	UI.full_rect(self)
	visible = false
	var frame := UI.screen(self, "Charger")
	_panel = frame["panel"]
	_title = frame["title"]
	var body: VBoxContainer = frame["body"]
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(0, 430)
	UI.style_scroll(_scroll)
	_scroll.follow_focus = true
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	_note = UI.label("", 17, UI.GOLD, false, true)
	_note.custom_minimum_size = Vector2(0, 24)
	body.add_child(_note)
	_hint = frame["foot"]

	# fenêtre de confirmation, par-dessus la liste
	_modal = Control.new()
	UI.full_rect(_modal)
	_modal.visible = false
	add_child(_modal)
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.03, 0.6)
	UI.full_rect(shade)
	_modal.add_child(shade)
	var mcenter := CenterContainer.new()
	UI.full_rect(mcenter)
	_modal.add_child(mcenter)
	var mpanel := PanelContainer.new()
	mpanel.add_theme_stylebox_override("panel", UI.soft_style(0.95, 34))
	mcenter.add_child(mpanel)
	var mbox := VBoxContainer.new()
	mbox.add_theme_constant_override("separation", 8)
	mbox.custom_minimum_size = Vector2(540, 0)
	mpanel.add_child(mbox)
	_modal_text = UI.label("", 22)
	_modal_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mbox.add_child(_modal_text)
	mbox.add_child(UI.rule())
	_modal_yes = UI.menu_button("Oui", 24)
	_modal_yes.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_yes.pressed.connect(_on_modal_yes)
	mbox.add_child(_modal_yes)
	_modal_no = UI.menu_button("Annuler", 24)
	_modal_no.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_modal_no.pressed.connect(func() -> void:
		Sfx.play("cancel")
		_close_modal())
	mbox.add_child(_modal_no)


## mode : "save" ou "load". context : voir plus haut.
func open(new_mode: String, new_context: String = "") -> void:
	mode = new_mode
	context = new_context
	_opened_at = Engine.get_process_frames()
	_modal.visible = false
	visible = true
	_rebuild("")
	UI.pop(_panel)
	Sfx.play("confirm")


func close(chosen: String = "", silent: bool = false) -> void:
	if not visible:
		return
	if not silent:
		UI.ghost_fade(self)
	visible = false
	_modal.visible = false
	if not silent:
		Sfx.play("cancel" if chosen == "" else "confirm")
	finished.emit(chosen)


func is_modal_open() -> bool:
	return _modal.visible


# ------------------------------------------------------------------ liste

func _rebuild(focus_id: String) -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_rows.clear()
	_entries.clear()
	_title.text = "Sauvegarder" if mode == "save" else "Charger"
	var entries := SaveManager.list_slots(mode == "load")
	var any_auto := false
	var first: Button = null
	var wanted: Button = null
	var previous: Button = null
	for e: Dictionary in entries:
		var id := str(e["id"])
		if str(e["kind"]) == "auto" and not any_auto:
			any_auto = true
			var sep := UI.caps("Sauvegardes automatiques", 14, UI.GOLD_DIM)
			sep.tooltip_text = "Changement de lieu, avant les combats sans fuite"
			var sep_box := VBoxContainer.new()
			var sep_gap := Control.new()
			sep_gap.custom_minimum_size = Vector2(0, 10)
			sep_box.add_child(sep_gap)
			sep_box.add_child(sep)
			sep_box.add_child(UI.rule(0.0, "out"))
			_list.add_child(sep_box)
		_entries[id] = e
		var row := _make_row(e)
		_list.add_child(row)
		_rows[id] = row
		var usable := mode == "save" or not bool(e["empty"])
		if usable and first == null:
			first = row
		if id == focus_id and usable:
			wanted = row
		previous = row
	if wanted == null:
		wanted = first
		if mode == "save" and SaveManager.current_slot != "" and _rows.has(SaveManager.current_slot):
			wanted = _rows[SaveManager.current_slot]
		elif mode == "load":
			var latest := SaveManager.latest_id()
			if _rows.has(latest):
				wanted = _rows[latest]
	if wanted != null:
		_focus.call_deferred(wanted)
	else:
		var none := UI.label("Aucune sauvegarde pour l'instant.", 20, UI.INK_DIM, false, true)
		_list.add_child(none)
	for c in _hint.get_children():
		_hint.remove_child(c)
		c.queue_free()
	_note.text = ""
	_hint.add_child(UI.hints([["nav", "choisir"], ["ok", "sauvegarder ici" if mode == "save" else "charger"], ["delete", "effacer"], ["back", "retour"]]))
	_last_focus = null
	previous = null


func _make_row(e: Dictionary) -> Button:
	var id := str(e["id"])
	var empty := bool(e["empty"])
	var row := UI.menu_button("", 20)
	row.custom_minimum_size = Vector2(0, 46 if empty else ROW_H)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var usable := mode == "save" or not empty
	row.disabled = not usable
	row.focus_mode = Control.FOCUS_ALL if usable else Control.FOCUS_NONE
	row.pressed.connect(_on_row.bind(id))

	var margin := MarginContainer.new()
	UI.full_rect(margin)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	row.add_child(margin)
	var line := HBoxContainer.new()
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_theme_constant_override("separation", 18)
	margin.add_child(line)

	# colonne 1 : le nom de l'emplacement (et d'où vient une sauvegarde automatique)
	var names := VBoxContainer.new()
	names.mouse_filter = Control.MOUSE_FILTER_IGNORE
	names.add_theme_constant_override("separation", 0)
	names.custom_minimum_size = Vector2(176, 0)
	names.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_child(names)
	names.add_child(UI.label(SaveManager.slot_label(id), 20, UI.GOLD if not empty else UI.INK_FAINT))
	if empty:
		line.add_child(UI.label("— vide —", 19, UI.INK_DIM, false, true))
		return row
	var kind_text := "Sauvegarde manuelle"
	if str(e["kind"]) == "auto":
		kind_text = "Avant un combat" if str(e["auto_reason"]) == "combat" else "Changement de lieu"
	names.add_child(UI.label(kind_text, 14, UI.INK_FAINT, false, true))

	# colonne 2 : les quatre combattants et le niveau moyen
	var faces := HBoxContainer.new()
	faces.mouse_filter = Control.MOUSE_FILTER_IGNORE
	faces.add_theme_constant_override("separation", 3)
	faces.custom_minimum_size = Vector2(4.0 * (FACE + 7.0) + 64.0, 0)
	faces.alignment = BoxContainer.ALIGNMENT_BEGIN
	var party_ids: Array = e.get("party", [])   # absent d'une très ancienne sauvegarde : pas de vignettes
	for who: Variant in party_ids:
		faces.add_child(_face(str(who)))
	if not party_ids.is_empty():
		var lv := UI.label("niv. %d" % int(e["level"]), 16, UI.INK_DIM)
		lv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(6, 0)
		faces.add_child(gap)
		faces.add_child(lv)
	line.add_child(faces)

	# colonne 3 : le lieu, puis le chapitre et la quête en cours
	var where := VBoxContainer.new()
	where.mouse_filter = Control.MOUSE_FILTER_IGNORE
	where.add_theme_constant_override("separation", 1)
	where.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	where.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_child(where)
	var place := UI.label(str(e["map_name"]), 21, UI.INK)
	place.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	where.add_child(place)
	var chapter_quest := str(e["chapter"])
	if str(e["quest"]) != "":
		chapter_quest += "  ·  " + str(e["quest"])
	var detail := UI.label(chapter_quest, 16, UI.INK_DIM)
	detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	where.add_child(detail)

	# colonne 4 : la date et le temps de jeu
	var when := VBoxContainer.new()
	when.mouse_filter = Control.MOUSE_FILTER_IGNORE
	when.add_theme_constant_override("separation", 1)
	when.custom_minimum_size = Vector2(146, 0)
	when.alignment = BoxContainer.ALIGNMENT_CENTER
	line.add_child(when)
	var date := UI.label(_date_text(str(e["saved_at"])), 17, UI.INK)
	date.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	when.add_child(date)
	var total := int(e["playtime"])
	var played := UI.label("%dh%02d de jeu" % [total / 3600, (total % 3600) / 60], 16, UI.INK_DIM)
	played.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	when.add_child(played)
	return row


## Vignette d'un personnage : son portrait dans un petit cadre doré.
func _face(who: String) -> Control:
	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fs := UI.panel_style(Color(0.02, 0.02, 0.05, 0.7), UI.GOLD_LINE, 2, 1)
	fs.set_content_margin_all(2.0)
	frame.add_theme_stylebox_override("panel", fs)
	var pic := TextureRect.new()
	pic.texture = Sprites.portrait(who)
	pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.custom_minimum_size = Vector2(FACE, FACE)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(pic)
	return frame


## « 2026-11-18 14:30:05 » -> « 18/11/2026 14:30 »
func _date_text(s: String) -> String:
	if s.length() < 16:
		return s
	return "%s/%s/%s %s" % [s.substr(8, 2), s.substr(5, 2), s.substr(0, 4), s.substr(11, 5)]


# ------------------------------------------------------------------ actions

func _focus(c: Control) -> void:
	if is_instance_valid(c) and c.is_inside_tree() and c.is_visible_in_tree() and c.focus_mode != Control.FOCUS_NONE:
		c.grab_focus()


func _focused_id() -> String:
	var f := get_viewport().gui_get_focus_owner()
	for id: String in _rows:
		if _rows[id] == f:
			return id
	return ""


func _on_row(id: String) -> void:
	if _modal.visible:
		return
	var e: Dictionary = _entries.get(id, {})
	if e.is_empty():
		return
	if mode == "save":
		if bool(e["empty"]):
			_do_save(id)
		else:
			_ask("%s est déjà occupé :\n%s, %s.\nL'écraser par la partie en cours ?" % [
				SaveManager.slot_label(id), str(e["map_name"]), _date_text(str(e["saved_at"]))], "Écraser", func() -> void: _do_save(id))
	else:
		close(id)


func _do_save(id: String) -> void:
	_close_modal()
	if SaveManager.save_game(id):
		Sfx.play("save")
		saved.emit(id)
		close("", true)
	else:
		Sfx.play("cancel")
		_note.text = "Échec de la sauvegarde."


func _ask(text: String, yes_label: String, action: Callable) -> void:
	_last_focus = get_viewport().gui_get_focus_owner()
	_modal_text.text = text
	_modal_yes.text = yes_label
	_modal_action = action
	for id: String in _rows:
		(_rows[id] as Button).focus_mode = Control.FOCUS_NONE
	_modal.visible = true
	Sfx.play("cancel")
	_focus.call_deferred(_modal_no)


func _close_modal() -> void:
	if not _modal.visible:
		return
	_modal.visible = false
	for id: String in _rows:
		var e: Dictionary = _entries[id]
		var usable := mode == "save" or not bool(e["empty"])
		(_rows[id] as Button).focus_mode = Control.FOCUS_ALL if usable else Control.FOCUS_NONE
	if _last_focus != null and is_instance_valid(_last_focus) and (_last_focus as Control).focus_mode == Control.FOCUS_ALL:
		_focus.call_deferred(_last_focus)


func _on_modal_yes() -> void:
	Sfx.play("confirm")
	var action := _modal_action
	_modal_action = Callable()
	if action.is_valid():
		action.call()
	else:
		_close_modal()


func _delete(id: String) -> void:
	SaveManager.delete_slot(id)
	Sfx.play("cancel")
	_modal.visible = false
	_rebuild(id)


func _input(event: InputEvent) -> void:
	if not visible or Engine.get_process_frames() == _opened_at:
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if _modal.visible:
			Sfx.play("cancel")
			_close_modal()
		else:
			close()
		return
	if _modal.visible:
		return
	if event.is_action_pressed("delete"):
		var id := _focused_id()
		if id == "" or bool((_entries[id] as Dictionary)["empty"]):
			return
		get_viewport().set_input_as_handled()
		_ask("Effacer définitivement %s ?\n%s" % [SaveManager.slot_label(id), str((_entries[id] as Dictionary)["map_name"])],
			"Effacer", func() -> void: _delete(id))
