extends Control
## Page « Aide » du menu de pause : la liste des conseils de jeu déjà vus, à relire à volonté.
## À gauche les titres, à droite le texte et les touches du conseil survolé. Échap ou retour : revenir.

signal closed

const UI = preload("res://src/ui/ui_kit.gd")
const TipPanel = preload("res://src/ui/tutorial_panel.gd")

var _panel: PanelContainer
var _list: VBoxContainer
var _scroll: ScrollContainer
var _tag: Label
var _title: Label
var _text: Label
var _keys: VBoxContainer
var _count: Label
var _opened_at := 0
var _remember := ""


func _ready() -> void:
	UI.full_rect(self)
	visible = false
	var frame := UI.screen(self, "Aide")
	_panel = frame["panel"]
	var body: VBoxContainer = frame["body"]
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 26)
	body.add_child(row)
	_scroll = ScrollContainer.new()
	_scroll.custom_minimum_size = Vector2(380, 430)
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
	side.add_theme_constant_override("separation", 8)
	row.add_child(side)
	_tag = UI.caps("", 13, UI.GOLD_DIM)
	side.add_child(_tag)
	_title = UI.label("", 26, UI.GOLD, true)
	side.add_child(_title)
	side.add_child(UI.rule())
	_text = UI.label("", 18, UI.INK)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(460, 0)
	side.add_child(_text)
	_keys = VBoxContainer.new()
	_keys.add_theme_constant_override("separation", 6)
	side.add_child(_keys)
	_count = UI.label("", 16, UI.INK_DIM, false, true)
	body.add_child(_count)
	(frame["foot"] as HBoxContainer).add_child(UI.hints([["Haut / bas", "choisir"], ["Échap", "retour"]]))


func open() -> void:
	_opened_at = Engine.get_process_frames()
	visible = true
	_build()
	UI.pop(_panel)
	Sfx.play("confirm")


func close(silent: bool = false) -> void:
	if not visible:
		return
	var f := get_viewport().gui_get_focus_owner()
	_remember = str(f.get_meta("tip")) if f is Button and f.has_meta("tip") else ""
	visible = false
	if not silent:
		Sfx.play("cancel")
	closed.emit()


## Reconstruit la liste (les conseils vus changent d'une ouverture à l'autre).
func _build() -> void:
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	var seen: Array = Tutorial.seen_ids()
	var first: Button = null
	var wanted: Button = null
	for id: String in seen:
		var tip: Dictionary = Tutorial.by_id[id]
		var b := UI.menu_button(str(tip.get("title", id)), 21)
		b.set_meta("tip", id)
		b.focus_entered.connect(_show_tip.bind(id))
		_list.add_child(b)
		if first == null:
			first = b
		if id == _remember:
			wanted = b
	_count.text = "%d conseil%s vu%s sur %d. Les autres arrivent au moment où ils servent." % [seen.size(), "s" if seen.size() > 1 else "", "s" if seen.size() > 1 else "", Tutorial.tips.size()]
	if first == null:
		_tag.text = "Conseil"
		_title.text = "Rien à relire pour l'instant"
		_text.text = "Chaque conseil s'affiche une seule fois, au moment où il sert, puis vient s'ajouter ici. Déplacez-vous, parlez aux gens : cela viendra tout seul."
		_clear_keys()
		return
	if wanted == null:
		wanted = first
	wanted.grab_focus()
	_show_tip(str(wanted.get_meta("tip")))


func _clear_keys() -> void:
	for c in _keys.get_children():
		_keys.remove_child(c)
		c.queue_free()


func _show_tip(id: String) -> void:
	var view: Dictionary = Tutorial.resolve(Tutorial.by_id[id])
	_tag.text = str(view["tag"]).to_upper()
	_title.text = str(view["title"])
	_text.text = str(view["text"])
	_clear_keys()
	for r: Variant in view["rows"]:
		_keys.add_child(TipPanel.key_row((r as Dictionary)["caps"], str((r as Dictionary)["verb"])))


func _input(event: InputEvent) -> void:
	if not visible or Engine.get_process_frames() == _opened_at:
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
