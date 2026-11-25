extends Control
## « Choisir un chapitre » (écran-titre) : la liste des débuts de chapitre de data/chapter_starts.json.
## À gauche les chapitres, à droite le lieu, le résumé « où on en est », l'équipe et son niveau.
## Valider un chapitre émet `chosen` (main.gd demande confirmation puis fabrique la partie) ;
## retour (Échap, B) émet `closed`. Entièrement pilotable à la manette.

signal chosen(id: String)
signal closed

const UI = preload("res://src/ui/ui_kit.gd")
const ChapterStart = preload("res://src/core/chapter_start.gd")

const FACE := 44.0

var _panel: PanelContainer
var _scroll: ScrollContainer
var _list: VBoxContainer
var _tag: Label
var _title: Label
var _summary: Label
var _faces: HBoxContainer
var _level: Label
var _others: Label
var _quest: Label
var _note: Label
var _opened_at := 0
var _remember := ""
var _rows: Dictionary = {}   # id -> Button


func _ready() -> void:
	UI.full_rect(self)
	visible = false
	var frame := UI.screen(self, "Choisir un chapitre")
	_panel = frame["panel"]
	var body: VBoxContainer = frame["body"]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	body.add_child(row)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(330, 400)
	UI.style_scroll(_scroll)
	_scroll.follow_focus = true
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 0)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)
	row.add_child(UI.vline())
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.custom_minimum_size = Vector2(560, 0)
	side.add_theme_constant_override("separation", 7)
	row.add_child(side)
	_tag = UI.caps("", 13, UI.GOLD_DIM)
	side.add_child(_tag)
	_title = UI.label("", 26, UI.GOLD, true, false, true)
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_title)
	side.add_child(UI.rule())
	_summary = UI.label("", 18, UI.INK, false, false, true)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_summary.custom_minimum_size = Vector2(540, 96)
	side.add_child(_summary)
	side.add_child(UI.caps("L'équipe", 13, UI.GOLD_DIM))
	var team := HBoxContainer.new()
	team.add_theme_constant_override("separation", 10)
	side.add_child(team)
	_faces = HBoxContainer.new()
	_faces.add_theme_constant_override("separation", 4)
	team.add_child(_faces)
	_level = UI.label("", 18, UI.INK_DIM)
	_level.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	team.add_child(_level)
	_others = UI.label("", 16, UI.INK_DIM, false, true)
	_others.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_others.custom_minimum_size = Vector2(540, 22)
	side.add_child(_others)
	_quest = UI.label("", 17, UI.SKY)
	_quest.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(_quest)
	_note = UI.label("Une partie neuve, fabriquée pour l'occasion : vos sauvegardes ne sont pas touchées.", 15, UI.INK_FAINT, false, true)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_child(_note)
	(frame["foot"] as HBoxContainer).add_child(UI.hints([["ud", "choisir"], ["ok", "commencer ici"], ["back", "retour"]]))


func open() -> void:
	_opened_at = Engine.get_process_frames()
	visible = true
	_build()
	UI.pop(_panel)
	Sfx.play("confirm")


## Referme l'écran. `silent` : sans bruit ni fondu (un chapitre vient d'être choisi).
func close(silent: bool = false) -> void:
	if not visible:
		return
	_remember = _focused_id()
	if not silent:
		UI.ghost_fade(self)
		Sfx.play("cancel")
	visible = false
	closed.emit()


## Rend le curseur au chapitre visé (retour d'une confirmation refusée).
func refocus() -> void:
	var b: Button = _rows.get(_remember) as Button
	if b != null and is_instance_valid(b) and b.is_visible_in_tree():
		b.grab_focus()


func _build() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	_rows.clear()
	var wanted: Button = null
	var first: Button = null
	for e: Dictionary in ChapterStart.entries():
		var id := str(e.get("id", ""))
		var b := UI.menu_button(str(e.get("title", id)), 21)
		b.set_meta("chapter", id)
		b.focus_entered.connect(_show.bind(id))
		b.pressed.connect(_on_pressed.bind(id))
		_list.add_child(b)
		_rows[id] = b
		if first == null:
			first = b
		if id == _remember:
			wanted = b
	if wanted == null:
		wanted = first
	if wanted != null:
		wanted.grab_focus()
		_show(str(wanted.get_meta("chapter")))


func _focused_id() -> String:
	var f := get_viewport().gui_get_focus_owner()
	if f is Button and f.has_meta("chapter"):
		return str(f.get_meta("chapter"))
	return _remember


func _on_pressed(id: String) -> void:
	_remember = id
	chosen.emit(id)


func _show(id: String) -> void:
	var e := ChapterStart.entry(id)
	if e.is_empty():
		return
	_tag.text = str(e.get("place", "")).to_upper()
	_title.text = str(e.get("title", id))
	_summary.text = str(e.get("summary", ""))
	for c in _faces.get_children():
		_faces.remove_child(c)
		c.queue_free()
	var party: Array = e.get("party", [])
	var active: Array = party.slice(0, 4)
	if bool(e.get("new_game", false)):
		active = [str(Database.game.get("player", "glandoulf"))]
	for who: Variant in active:
		_faces.add_child(_face(str(who)))
	var level := int(e.get("level", 1))
	_level.text = "niveau %d" % level
	var rest: Array = []
	if party.size() > 4:
		var names: Array = []
		for who: Variant in party.slice(4):
			names.append(Database.get_character_name(str(who)))
		rest.append("En réserve : " + ", ".join(names))
	if not (e.get("bench", []) as Array).is_empty():
		var names2: Array = []
		for who: Variant in e["bench"]:
			names2.append(Database.get_character_name(str(who)))
		rest.append("Partis de leur côté : " + ", ".join(names2))
	if not (e.get("away", []) as Array).is_empty():
		var names3: Array = []
		for who: Variant in e["away"]:
			names3.append(Database.get_character_name(str(who)))
		rest.append("Absent : " + ", ".join(names3))
	_others.text = "  ·  ".join(rest)
	_others.visible = not rest.is_empty()
	var q := str(e.get("main_quest", ""))
	_quest.text = ("Quête : " + str(Database.get_quest(q).get("name", q))) if q != "" else "Quête : le début de l'aventure, prologue compris."
	_quest.visible = true


func _face(who: String) -> Control:
	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
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


func _input(event: InputEvent) -> void:
	if not visible or Engine.get_process_frames() == _opened_at:
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
