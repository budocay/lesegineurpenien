extends Control
## Boîte de dialogue : nom du personnage, portrait, texte qui s'affiche lettre à lettre, choix.
## Elle interprète aussi le petit langage des dialogues (data/dialogues/*.json) :
##   {"who": "sam", "text": "..."}            réplique (sans "who" : narration)
##   {"if": "drapeau", "then": [...], "else": [...]}
##   {"set": "drapeau"}                       pose un drapeau dans GameState
##   {"choice": [{"text": "...", "then": [...]}, ...]}
##   {"action": "save"}                       demande une action au jeu ("save", "rest")
##   {"battle": "id"}                         lance un combat ; s'il est gagné, pose le drapeau combat_<id>
##   {"give": "objet", "count": 2}            ajoute des objets à l'inventaire
##   {"join": "personnage"}                   fait entrer un personnage dans l'équipe
##   {"take": "objet", "count": 1}            retire des objets de l'inventaire
##   {"money": 12}                            donne (ou reprend, si négatif) des écus
##   {"shop": "id"}                           ouvre une boutique ; le dialogue reprend à sa fermeture
## « if » accepte toute condition de GameState.check : drapeau, "item:x", "party:x", "a & b"...

signal finished
signal action_requested(action: String)
signal battle_requested(encounter_id: String)   # le dialogue attend resume() ou abort()
signal shop_requested(shop_id: String)          # idem
signal banner_requested(title: String, subtitle: String)   # grand titre à l'écran (fin de chapitre)
signal notice(text: String)                     # petit message à afficher (objet reçu, recrue)

const UI = preload("res://src/ui/ui_kit.gd")

const CHAR_DELAY := 0.02
const BOX_W := 940.0
const BOX_H := 172.0

var active := false
var waiting := false   # en pause pendant un combat lancé par le dialogue

var _stack: Array = []
var _panel: Panel
var _name_plate: PanelContainer
var _name_label: Label
var _portrait_frame: Panel
var _portrait: TextureRect
var _text: RichTextLabel
var _arrow: Polygon2D
var _choice_panel: PanelContainer
var _choice_list: VBoxContainer

var _typing := false
var _timer := 0.0
var _total := 0
var _parsed := ""
var _pending_choice: Array = []
var _choosing := false
var _time := 0.0


func _ready() -> void:
	UI.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_panel = Panel.new()
	_panel.add_theme_stylebox_override("panel", UI.panel_style())
	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 1.0
	_panel.anchor_bottom = 1.0
	_panel.offset_left = -BOX_W * 0.5
	_panel.offset_right = BOX_W * 0.5
	_panel.offset_top = -BOX_H - 26.0
	_panel.offset_bottom = -26.0
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	# liseré intérieur, façon cadre de vieux grimoire
	var inner := Panel.new()
	var inner_style := StyleBoxFlat.new()
	inner_style.bg_color = Color(0, 0, 0, 0)
	inner_style.border_color = Color(UI.GOLD.r, UI.GOLD.g, UI.GOLD.b, 0.28)
	inner_style.set_border_width_all(1)
	inner_style.set_corner_radius_all(3)
	inner.add_theme_stylebox_override("panel", inner_style)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 6)
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(inner)

	_portrait_frame = Panel.new()
	_portrait_frame.add_theme_stylebox_override("panel", UI.panel_style(Color(0.13, 0.12, 0.22, 1.0), UI.GOLD_DIM, 4, 2))
	_portrait_frame.position = Vector2(18, 18)
	_portrait_frame.size = Vector2(136, 136)
	_portrait_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_portrait_frame)
	_portrait = TextureRect.new()
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.position = Vector2(3, 3)
	_portrait.size = Vector2(130, 130)
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_frame.add_child(_portrait)

	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = false
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	_text.add_theme_font_override("normal_font", UI.font())
	_text.add_theme_font_override("italics_font", UI.font(false, true))
	_text.add_theme_font_override("bold_font", UI.font(true))
	_text.add_theme_font_override("bold_italics_font", UI.font(true, true))
	for key: String in ["normal_font_size", "italics_font_size", "bold_font_size", "bold_italics_font_size"]:
		_text.add_theme_font_size_override(key, 25)
	_text.add_theme_color_override("default_color", UI.INK)
	_text.add_theme_constant_override("line_separation", 5)
	_panel.add_child(_text)

	_name_plate = PanelContainer.new()
	var plate := UI.panel_style(Color(0.11, 0.1, 0.2, 1.0), UI.GOLD, 5, 2)
	plate.content_margin_left = 18
	plate.content_margin_right = 18
	plate.content_margin_top = 3
	plate.content_margin_bottom = 4
	_name_plate.add_theme_stylebox_override("panel", plate)
	_name_plate.position = Vector2(30, -24)
	_name_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(_name_plate)
	_name_label = UI.label("", 23, UI.GOLD, true)
	_name_plate.add_child(_name_label)

	_arrow = Polygon2D.new()
	_arrow.polygon = PackedVector2Array([Vector2(-8, -5), Vector2(8, -5), Vector2(0, 6)])
	_arrow.color = UI.GOLD
	_arrow.position = Vector2(BOX_W - 30.0, BOX_H - 22.0)
	_panel.add_child(_arrow)

	_choice_panel = PanelContainer.new()
	_choice_panel.add_theme_stylebox_override("panel", UI.panel_style())
	_choice_panel.visible = false
	_panel.add_child(_choice_panel)
	_choice_list = VBoxContainer.new()
	_choice_list.add_theme_constant_override("separation", 2)
	_choice_panel.add_child(_choice_list)


func start(dialogue_id: String) -> void:
	var nodes := Database.get_dialogue(dialogue_id)
	if nodes.is_empty():
		push_warning("Dialogue introuvable ou vide : " + dialogue_id)
		finished.emit.call_deferred()
		return
	_stack = [{"nodes": nodes, "i": 0}]
	active = true
	_advance()


func _open_box() -> void:
	if visible:
		return
	visible = true
	modulate.a = 0.0
	_panel.offset_top = -BOX_H - 10.0
	_panel.offset_bottom = -10.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.16)
	tw.tween_property(_panel, "offset_top", -BOX_H - 26.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel, "offset_bottom", -26.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _advance() -> void:
	while not _stack.is_empty():
		var top: Dictionary = _stack.back()
		var nodes: Array = top["nodes"]
		var i: int = top["i"]
		if i >= nodes.size():
			_stack.pop_back()
			continue
		top["i"] = i + 1
		if not (nodes[i] is Dictionary):
			continue
		var n: Dictionary = nodes[i]
		if n.has("if"):
			var branch: Variant = n.get("then" if GameState.check(str(n["if"])) else "else", [])
			if branch is Array and not (branch as Array).is_empty():
				_stack.append({"nodes": branch, "i": 0})
			continue
		if n.has("set"):
			GameState.set_flag(str(n["set"]), n.get("value", true))
			continue
		if n.has("action"):
			action_requested.emit(str(n["action"]))
			continue
		if n.has("give"):
			var item := str(n["give"])
			var count := int(n.get("count", 1))
			GameState.add_item(item, count)
			notice.emit("Obtenu : %s ×%d" % [str(Database.get_item(item).get("name", item)), count])
			continue
		if n.has("join"):
			var recruit := str(n["join"])
			if not GameState.party.has(recruit):
				GameState.add_to_party(recruit, true)
				notice.emit("%s rejoint l'équipe" % Database.get_character_name(recruit))
			continue
		if n.has("take"):
			var taken := str(n["take"])
			GameState.add_item(taken, -maxi(1, int(n.get("count", 1))))
			continue
		if n.has("money"):
			var sum := int(n["money"])
			GameState.add_money(sum)
			notice.emit("%s%d écus" % ["+" if sum >= 0 else "−", absi(sum)])
			continue
		if n.has("music"):
			Music.play(str(n["music"]))
			continue
		if n.has("chapter"):
			GameState.chapter = str(n["chapter"])
			continue
		if n.has("banner"):
			banner_requested.emit(str(n["banner"]), str(n.get("sub", "")))
			continue
		if n.has("shop"):
			waiting = true
			visible = false
			shop_requested.emit(str(n["shop"]))
			return
		if n.has("battle"):
			waiting = true
			visible = false
			battle_requested.emit(str(n["battle"]))
			return
		if n.has("text"):
			_show_line(n)
			return
		if n.has("choice"):
			_pending_choice = n["choice"]
			_show_choices()
			return
	_close()


func _show_line(n: Dictionary) -> void:
	_open_box()
	var who := str(n.get("who", ""))
	var body := str(n.get("text", ""))
	var portrait: Texture2D = null
	var speaker := ""
	if who != "":
		speaker = str(n.get("name", Database.get_character_name(who)))
		portrait = Sprites.portrait(who)
	elif n.has("name"):
		speaker = str(n["name"])
	_name_plate.visible = speaker != ""
	_name_label.text = speaker
	_name_plate.reset_size()
	_portrait_frame.visible = portrait != null
	_portrait.texture = portrait
	var left := 176.0 if portrait != null else 34.0
	_text.position = Vector2(left, 24.0)
	_text.size = Vector2(BOX_W - left - 44.0, BOX_H - 44.0)
	if speaker == "":
		body = "[color=#cfc6e8][i]%s[/i][/color]" % body
	_text.text = body
	_text.visible_characters = 0
	_parsed = _text.get_parsed_text()
	_total = _text.get_total_character_count()
	_typing = true
	_timer = 0.0
	_arrow.visible = false
	_pending_choice = []
	var ch: Variant = n.get("choice")
	if ch is Array:
		_pending_choice = ch


func _finish_typing() -> void:
	_typing = false
	_text.visible_characters = -1
	if _pending_choice.is_empty():
		_arrow.visible = true
	else:
		_show_choices()


func _show_choices() -> void:
	_open_box()
	_choosing = true
	_arrow.visible = false
	for c in _choice_list.get_children():
		c.queue_free()
	var first: Button = null
	for opt: Variant in _pending_choice:
		if not (opt is Dictionary):
			continue
		var d: Dictionary = opt
		var b := UI.menu_button(str(d.get("text", "...")), 23)
		b.pressed.connect(_on_choice.bind(d))
		_choice_list.add_child(b)
		if first == null:
			first = b
	_choice_panel.visible = true
	_choice_panel.reset_size()
	await get_tree().process_frame
	_choice_panel.position = Vector2(BOX_W - _choice_panel.size.x - 20.0, -_choice_panel.size.y - 10.0)
	if first != null:
		first.grab_focus()


func _on_choice(d: Dictionary) -> void:
	if not _choosing:
		return
	_choosing = false
	_choice_panel.visible = false
	_pending_choice = []
	Sfx.play("confirm")
	var branch: Variant = d.get("then", [])
	if branch is Array and not (branch as Array).is_empty():
		_stack.append({"nodes": branch, "i": 0})
	_advance()


## Reprend après un combat lancé par {"battle": ...}.
func resume() -> void:
	if not waiting:
		return
	waiting = false
	_advance()


## Abandonne le dialogue en cours (retour à l'écran-titre après une défaite).
func abort() -> void:
	if not active:
		return
	waiting = false
	_stack = []
	_close()


func _close() -> void:
	active = false
	waiting = false
	_typing = false
	_choosing = false
	_choice_panel.visible = false
	visible = false
	finished.emit()


func _process(delta: float) -> void:
	if not active:
		return
	_time += delta
	_arrow.position.y = BOX_H - 22.0 + sin(_time * 6.0) * 2.5
	if not _typing:
		return
	_timer -= delta
	while _timer <= 0.0 and _typing:
		var shown := _text.visible_characters + 1
		_text.visible_characters = shown
		var ch := ""
		if shown - 1 < _parsed.length():
			ch = _parsed[shown - 1]
		var wait := CHAR_DELAY
		if ch in [".", "!", "?", "…"]:
			wait = 0.2
		elif ch in [",", ";", ":"]:
			wait = 0.09
		elif ch != " " and shown % 3 == 0:
			Sfx.play("blip", randf_range(0.92, 1.08))
		_timer += wait
		if shown >= _total:
			_finish_typing()


func _input(event: InputEvent) -> void:
	if not active or _choosing or waiting:
		return
	var pressed := event.is_action_pressed("interact") or event.is_action_pressed("cancel") or event.is_action_pressed("ui_accept")
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		pressed = pressed or (mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT)
	if not pressed:
		return
	get_viewport().set_input_as_handled()
	if _typing:
		_finish_typing()
	else:
		_advance()
