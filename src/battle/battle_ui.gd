extends Control
## Interface du combat : file des tours, menu d'actions, jauges de l'équipe,
## faiblesses et boucliers des ennemis, choix de la cible, chiffres qui s'envolent,
## écrans de victoire et de défaite.
## Elle ne décide de rien : elle renvoie le choix du joueur à la scène de combat.

signal action_chosen(action: Dictionary)
signal _closed(value: String)

const UI = preload("res://src/ui/ui_kit.gd")

enum S { IDLE, ROOT, LIST, TARGET, END }

const ENEMY_RED := Color("#d8665c")
const HP_GREEN := Color("#7ad06a")
const HP_LOW := Color("#e8785a")
const MP_BLUE := Color("#6aa0e8")

var scene: Node3D = null
var engine: RefCounted = null

var _state: S = S.IDLE
var _actor: RefCounted = null
var _active: RefCounted = null
var _pending: Dictionary = {}
var _cands: Array = []
var _index := 0
var _all := false
var _return: S = S.ROOT
var _list_kind := ""
var _last_root := 0
var _last_list := {}        # "skill"/"item" -> dernier identifiant choisi
var _last_enemy := ""
var _target_frame := -1
var _time := 0.0

var _timeline: HBoxContainer
var _top: VBoxContainer
var _ribbon: PanelContainer
var _ribbon_label: Label
var _ribbon_tween: Tween
var _hint: PanelContainer
var _hint_label: Label
var _party_panel: PanelContainer
var _party_rows: VBoxContainer
var _rows: Dictionary = {}   # clé -> {name, level, hp, hp_text, mp, mp_text, status}
var _menu_box: HBoxContainer
var _root_panel: PanelContainer
var _root_title: Label
var _root_list: VBoxContainer
var _list_panel: PanelContainer
var _list_title: Label
var _list_items: VBoxContainer
var _list_desc: Label
var _overlay: Control
var _plates: Dictionary = {}  # clé -> {root, chips, name, bar}
var _cursors: Array[Polygon2D] = []
var _end_layer: Control


func _ready() -> void:
	UI.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_overlay = Control.new()
	UI.full_rect(_overlay)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# file des tours, en haut à gauche
	_timeline = HBoxContainer.new()
	_timeline.position = Vector2(24, 18)
	_timeline.add_theme_constant_override("separation", 6)
	_timeline.alignment = BoxContainer.ALIGNMENT_BEGIN
	_timeline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_timeline)

	# bandeau d'annonce et conseils, en haut au centre
	_top = VBoxContainer.new()
	_top.anchor_left = 0.0
	_top.anchor_right = 1.0
	_top.offset_top = 84.0
	_top.add_theme_constant_override("separation", 10)
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top)
	_ribbon = PanelContainer.new()
	var rs := UI.panel_style(UI.NIGHT, UI.GOLD, 4, 1)
	rs.content_margin_left = 30
	rs.content_margin_right = 30
	rs.content_margin_top = 5
	rs.content_margin_bottom = 6
	_ribbon.add_theme_stylebox_override("panel", rs)
	_ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ribbon.modulate.a = 0.0
	_top.add_child(_ribbon)
	_ribbon_label = UI.label("", 24, UI.INK, false, true)
	_ribbon.add_child(_ribbon_label)
	_hint = PanelContainer.new()
	var hs := UI.panel_style(Color(0.09, 0.08, 0.17, 0.95), UI.GOLD_DIM, 6, 1)
	hs.content_margin_left = 18
	hs.content_margin_right = 18
	_hint.add_theme_stylebox_override("panel", hs)
	_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.visible = false
	_top.add_child(_hint)
	var hint_row := HBoxContainer.new()
	hint_row.add_theme_constant_override("separation", 12)
	_hint.add_child(hint_row)
	var hint_tag := UI.label("Conseil", 18, UI.GOLD, true)
	hint_tag.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hint_row.add_child(hint_tag)
	_hint_label = UI.label("", 19, UI.INK)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.custom_minimum_size = Vector2(620, 0)
	hint_row.add_child(_hint_label)

	# équipe, en bas à droite
	_party_panel = PanelContainer.new()
	_party_panel.add_theme_stylebox_override("panel", UI.panel_style())
	_party_panel.anchor_left = 1.0
	_party_panel.anchor_right = 1.0
	_party_panel.anchor_top = 1.0
	_party_panel.anchor_bottom = 1.0
	_party_panel.offset_left = -24.0
	_party_panel.offset_right = -24.0
	_party_panel.offset_top = -20.0
	_party_panel.offset_bottom = -20.0
	_party_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_party_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_party_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_party_panel)
	_party_rows = VBoxContainer.new()
	_party_rows.add_theme_constant_override("separation", 6)
	_party_panel.add_child(_party_rows)

	# menus, en bas à gauche
	_menu_box = HBoxContainer.new()
	_menu_box.anchor_top = 1.0
	_menu_box.anchor_bottom = 1.0
	_menu_box.offset_left = 24.0
	_menu_box.offset_top = -20.0
	_menu_box.offset_bottom = -20.0
	_menu_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_menu_box.add_theme_constant_override("separation", 10)
	_menu_box.visible = false
	add_child(_menu_box)
	_root_panel = PanelContainer.new()
	_root_panel.add_theme_stylebox_override("panel", UI.panel_style())
	_root_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	_menu_box.add_child(_root_panel)
	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 0)
	_root_panel.add_child(root_box)
	_root_title = UI.label("", 20, UI.GOLD, true)
	root_box.add_child(_root_title)
	_root_list = VBoxContainer.new()
	_root_list.add_theme_constant_override("separation", 0)
	root_box.add_child(_root_list)
	_list_panel = PanelContainer.new()
	_list_panel.add_theme_stylebox_override("panel", UI.panel_style())
	_list_panel.size_flags_vertical = Control.SIZE_SHRINK_END
	_list_panel.visible = false
	_menu_box.add_child(_list_panel)
	var list_box := VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 2)
	_list_panel.add_child(list_box)
	_list_title = UI.label("", 18, UI.GOLD_DIM, true)
	list_box.add_child(_list_title)
	_list_items = VBoxContainer.new()
	_list_items.add_theme_constant_override("separation", 0)
	list_box.add_child(_list_items)
	_list_desc = UI.label("", 17, UI.INK_DIM, false, true)
	_list_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_list_desc.custom_minimum_size = Vector2(350, 46)
	list_box.add_child(_list_desc)

	_end_layer = Control.new()
	UI.full_rect(_end_layer)
	_end_layer.visible = false
	add_child(_end_layer)


# ------------------------------------------------------------ ouverture / fermeture

func open(p_scene: Node3D, p_engine: RefCounted) -> void:
	close()
	scene = p_scene
	engine = p_engine
	visible = true
	for c: RefCounted in engine.party:
		_rows[c.key] = _make_row(c)
	for c: RefCounted in engine.enemies:
		_plates[c.key] = _make_plate(c)
	for _i in 8:
		var arrow := Polygon2D.new()
		arrow.polygon = PackedVector2Array([Vector2(-11, -14), Vector2(11, -14), Vector2(0, 2)])
		arrow.color = UI.GOLD
		arrow.visible = false
		_overlay.add_child(arrow)
		_cursors.append(arrow)
	refresh()


func close() -> void:
	_state = S.IDLE
	scene = null
	engine = null
	_actor = null
	_active = null
	visible = false
	_menu_box.visible = false
	_hint.visible = false
	_ribbon.modulate.a = 0.0
	_end_layer.visible = false
	for c in _end_layer.get_children():
		c.queue_free()
	for c in _party_rows.get_children():
		c.queue_free()
	for c in _timeline.get_children():
		c.queue_free()
	for c in _overlay.get_children():
		c.queue_free()
	_rows = {}
	_plates = {}
	_cursors = []


# ------------------------------------------------------------------ éléments

func _bar(color: Color, width: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(width, 11)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.border_color = Color(1, 1, 1, 0.18)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


func _set_bar_color(bar: ProgressBar, color: Color) -> void:
	var fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill != null and fill.bg_color != color:
		fill.bg_color = color


func _make_row(c: RefCounted) -> Dictionary:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_party_rows.add_child(row)
	var name_label := UI.label(str(c.name), 20, UI.INK, true)
	name_label.custom_minimum_size = Vector2(178, 0)
	row.add_child(name_label)
	var level := UI.label("Nv %d" % int(c.level), 16, UI.INK_DIM)
	level.custom_minimum_size = Vector2(48, 0)
	row.add_child(level)
	row.add_child(UI.label("PV", 15, UI.GOLD_DIM, true))
	var hp := _bar(HP_GREEN, 110)
	row.add_child(hp)
	var hp_text := UI.label("", 17, UI.INK)
	hp_text.custom_minimum_size = Vector2(78, 0)
	row.add_child(hp_text)
	row.add_child(UI.label("PM", 15, UI.GOLD_DIM, true))
	var mp := _bar(MP_BLUE, 70)
	row.add_child(mp)
	var mp_text := UI.label("", 17, UI.INK)
	mp_text.custom_minimum_size = Vector2(62, 0)
	row.add_child(mp_text)
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 6)
	status.custom_minimum_size = Vector2(96, 0)
	row.add_child(status)
	return {"name": name_label, "hp": hp, "hp_text": hp_text, "mp": mp, "mp_text": mp_text, "status": status}


func _chip(text: String, color: Color, size: int = 14) -> PanelContainer:
	var chip := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.05, 0.045, 0.1, 0.9)
	s.border_color = color
	s.set_border_width_all(1)
	s.set_corner_radius_all(3)
	s.content_margin_left = 5
	s.content_margin_right = 5
	s.content_margin_top = 0
	s.content_margin_bottom = 1
	chip.add_theme_stylebox_override("panel", s)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(UI.label(text, size, color, true))
	return chip


func _make_plate(c: RefCounted) -> Dictionary:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 3)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(root)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 3)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(chips)
	var name_label := UI.label(str(c.name), 18, UI.INK, true)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.visible = false
	root.add_child(name_label)
	var bar := _bar(ENEMY_RED, 120)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.visible = false
	root.add_child(bar)
	return {"root": root, "chips": chips, "name": name_label, "bar": bar, "sig": ""}


func _status_chips(box: HBoxContainer, c: RefCounted) -> void:
	for id: String in c.statuses:
		var st: Dictionary = Database.get_status(id)
		var chip := UI.label(str(st.get("name", id)), 15, Database.color(st.get("color", "#ffffff"), UI.INK), true)
		box.add_child(chip)


## Remet à jour jauges, états, boucliers et faiblesses.
func refresh() -> void:
	if engine == null:
		return
	for c: RefCounted in engine.party:
		var row: Dictionary = _rows.get(c.key, {})
		if row.is_empty():
			continue
		var hp: ProgressBar = row["hp"]
		hp.max_value = c.max_hp()
		hp.value = c.hp
		_set_bar_color(hp, HP_LOW if float(c.hp) / c.max_hp() < 0.3 else HP_GREEN)
		(row["hp_text"] as Label).text = "%d/%d" % [int(c.hp), c.max_hp()]
		var mp: ProgressBar = row["mp"]
		mp.max_value = maxi(1, c.max_mp())
		mp.value = c.mp
		(row["mp_text"] as Label).text = "%d/%d" % [int(c.mp), c.max_mp()]
		var name_label: Label = row["name"]
		var color := UI.INK
		if not c.alive():
			color = Color(0.6, 0.45, 0.45)
		elif c == _active:
			color = UI.GOLD
		name_label.add_theme_color_override("font_color", color)
		var status: HBoxContainer = row["status"]
		for n in status.get_children():
			n.queue_free()
		if not c.alive():
			status.add_child(UI.label("À terre", 15, Color(0.75, 0.5, 0.5), true))
		else:
			_status_chips(status, c)
	for c: RefCounted in engine.enemies:
		var plate: Dictionary = _plates.get(c.key, {})
		if plate.is_empty():
			continue
		var root: Control = plate["root"]
		root.visible = c.alive()
		if not c.alive():
			continue
		var known: Array = engine.known_weak(c)
		var sig := "%d|%s|%s" % [int(c.shield), str(known), str(c.statuses.keys())]
		if sig != str(plate["sig"]):
			plate["sig"] = sig
			var chips: HBoxContainer = plate["chips"]
			for n in chips.get_children():
				n.queue_free()
			if c.has_status("ebranle"):
				chips.add_child(_chip("Ébranlé", Color("#ff8a6a")))
			elif int(c.shield_max) > 0:
				chips.add_child(_chip(str(int(c.shield)), Color("#e8ecf4"), 15))
			for w: String in c.weak:
				if known.has(w):
					var el: Dictionary = Database.get_element(w)
					chips.add_child(_chip(str(el.get("short", w)), Database.color(el.get("color", "#ffffff"), UI.INK)))
				else:
					chips.add_child(_chip("?", Color(0.6, 0.6, 0.66)))
			for id: String in c.statuses:
				if id != "ebranle":
					var st: Dictionary = Database.get_status(id)
					chips.add_child(_chip(str(st.get("name", id)), Database.color(st.get("color", "#ffffff"), UI.INK)))
			root.reset_size()
		var bar: ProgressBar = plate["bar"]
		bar.max_value = c.max_hp()
		bar.value = c.hp


func set_active(c: RefCounted) -> void:
	_active = c
	refresh()


## File des tours : le premier est celui qui joue.
func set_timeline(order: Array) -> void:
	for n in _timeline.get_children():
		n.queue_free()
	var tag := UI.label("Tours", 15, UI.GOLD_DIM, true)
	tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_timeline.add_child(tag)
	for i in order.size():
		var c: RefCounted = order[i]
		var side := 54.0 if i == 0 else 40.0
		var frame := Panel.new()
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.07, 0.06, 0.13, 0.92)
		s.border_color = UI.GOLD if c.side == "party" else ENEMY_RED
		s.set_border_width_all(3 if i == 0 else 2)
		s.set_corner_radius_all(4)
		frame.add_theme_stylebox_override("panel", s)
		frame.custom_minimum_size = Vector2(side, side)
		frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.clip_contents = true
		_timeline.add_child(frame)
		var icon := TextureRect.new()
		icon.texture = Sprites.battler_icon(c.sprite)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.position = Vector2(3, 3)
		icon.size = Vector2(side - 6, side - 6)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(icon)
		if c.side == "enemy" and str(c.name) != str((c.data as Dictionary).get("name", "")):
			var letter := UI.label(str(c.name).right(1), 15, Color.WHITE, true)
			letter.position = Vector2(side - 15, side - 22)
			frame.add_child(letter)


func announce(text: String, duration: float = 1.4) -> void:
	_ribbon_label.text = text
	_ribbon.reset_size()
	if _ribbon_tween != null and _ribbon_tween.is_valid():
		_ribbon_tween.kill()
	_ribbon.modulate.a = 1.0
	_ribbon_tween = create_tween()
	_ribbon_tween.tween_interval(duration)
	_ribbon_tween.tween_property(_ribbon, "modulate:a", 0.0, 0.35)


func show_hint(text: String) -> void:
	_hint.visible = text != ""
	_hint_label.text = text
	_hint.reset_size()


## Texte qui s'envole au-dessus d'un combattant (dégâts, soins, états).
func popup(at: Vector2, text: String, color: Color = Color.WHITE, size: int = 30) -> void:
	if scene == null or scene.fast:
		return
	var l := UI.label(text, size, color, true)
	l.add_theme_constant_override("outline_size", 7)
	l.add_theme_color_override("font_outline_color", Color(0.06, 0.04, 0.1))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(l)
	l.reset_size()
	var jitter := Vector2(randf_range(-28.0, 28.0), randf_range(-12.0, 8.0))
	var start := at + jitter - Vector2(l.size.x * 0.5, l.size.y)
	l.position = start + Vector2(0, 14)
	l.pivot_offset = l.size * 0.5
	l.scale = Vector2(0.5, 0.5)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "position", start, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.chain().tween_interval(0.5)
	tw.chain().tween_property(l, "position", start + Vector2(0, -26), 0.4)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(l.queue_free)


# ------------------------------------------------------------------- menus

## Demande son action au joueur. Renvoie {"type", "id", "target"}.
func ask_action(actor: RefCounted) -> Dictionary:
	_actor = actor
	_last_root = 0
	_show_root()
	var action: Dictionary = await action_chosen
	_state = S.IDLE
	_menu_box.visible = false
	_hide_cursors()
	return action


func _clear(box: Control) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()


func _has_usable_item() -> bool:
	for id: String in engine.inventory:
		if Database.is_consumable(id):
			return true
	return false


func _show_root() -> void:
	_state = S.ROOT
	_hide_cursors()
	_menu_box.visible = true
	_menu_box.modulate.a = 1.0
	_root_panel.visible = true
	_list_panel.visible = false
	_root_title.text = str(_actor.name)
	_clear(_root_list)
	var entries := [
		["Attaquer", true],
		["Compétences", not (_actor.skills as Array).is_empty()],
		["Objets", _has_usable_item()],
		["Défendre", true],
		["Fuir", bool(engine.can_flee)],
	]
	for i in entries.size():
		var e: Array = entries[i]
		var b := UI.menu_button(str(e[0]), 23)
		b.custom_minimum_size = Vector2(190, 0)
		b.disabled = not bool(e[1])
		b.pressed.connect(_on_root.bind(i))
		_root_list.add_child(b)
	_focus(_root_list, _last_root)


func _on_root(index: int) -> void:
	if _state != S.ROOT:
		return
	_last_root = index
	Sfx.play("confirm")
	match index:
		0: _begin_target({"type": "attack"}, "enemy", S.ROOT)
		1: _show_list("skill")
		2: _show_list("item")
		3: _choose({"type": "defend"})
		4: _choose({"type": "flee"})


func _focus(box: Control, index: int) -> void:
	var n := box.get_child_count()
	if n == 0:
		return
	var b := box.get_child(clampi(index, 0, n - 1)) as Button
	if b != null:
		b.grab_focus.call_deferred()


func _show_list(kind: String) -> void:
	_state = S.LIST
	_list_kind = kind
	_hide_cursors()
	_menu_box.modulate.a = 1.0
	_root_panel.visible = false   # la liste prend la place du menu : rien ne déborde sur l'équipe
	_list_panel.visible = true
	_list_title.text = "Compétences" if kind == "skill" else "Objets"
	_list_desc.text = ""
	_clear(_list_items)
	var ids: Array = []
	if kind == "skill":
		ids = _actor.skills
	else:
		for id: String in engine.inventory:
			if Database.is_consumable(id):   # ni équipement ni objet de quête en plein combat
				ids.append(id)
	var focus_index := 0
	for i in ids.size():
		var id := str(ids[i])
		var def: Dictionary = Database.get_skill(id) if kind == "skill" else Database.get_item(id)
		var text := str(def.get("name", id))
		var usable := true
		if kind == "skill":
			text = "%s   ·   %d PM" % [text, int(def.get("cost", 0))]
			usable = engine.can_use_skill(_actor, id)
		else:
			text = "%s   ×%d" % [text, int(engine.inventory.get(id, 0))]
		if (engine.candidates(_actor, str(def.get("target", "enemy"))) as Array).is_empty():
			usable = false
		var b := UI.menu_button(text, 21)
		b.custom_minimum_size = Vector2(350, 0)
		b.disabled = not usable
		var desc := str(def.get("desc", ""))
		b.focus_entered.connect(_on_list_focus.bind(desc))
		b.pressed.connect(_on_list.bind(kind, id, str(def.get("target", "enemy"))))
		_list_items.add_child(b)
		if str(_last_list.get(kind, "")) == id:
			focus_index = i
	_focus(_list_items, focus_index)


func _on_list_focus(desc: String) -> void:
	_list_desc.text = desc


func _on_list(kind: String, id: String, target_kind: String) -> void:
	if _state != S.LIST:
		return
	_last_list[kind] = id
	Sfx.play("confirm")
	_begin_target({"type": kind, "id": id}, target_kind, S.LIST)


func _choose(action: Dictionary) -> void:
	if _state == S.IDLE or _state == S.END:
		return
	_state = S.IDLE
	action_chosen.emit(action)


func _begin_target(action: Dictionary, kind: String, from: S) -> void:
	var pool: Array = engine.candidates(_actor, kind)
	if pool.is_empty():
		Sfx.play("cancel")
		return
	_pending = action
	_cands = pool
	_all = engine.is_group(kind)
	_return = from
	_index = 0
	if kind == "enemy":
		for i in pool.size():
			if str(pool[i].key) == _last_enemy:
				_index = i
	elif kind == "ally":
		_index = maxi(0, pool.find(_actor))
	_state = S.TARGET
	_target_frame = Engine.get_process_frames()
	_menu_box.modulate.a = 0.55
	get_viewport().gui_release_focus()
	_update_cursors()


func _confirm_target() -> void:
	var action := _pending.duplicate()
	if not _all:
		var target: RefCounted = _cands[_index]
		action["target"] = target
		if target.side == "enemy":
			_last_enemy = str(target.key)
	Sfx.play("confirm")
	_choose(action)


func _cancel_target() -> void:
	Sfx.play("cancel")
	_hide_cursors()
	if _return == S.LIST:
		_show_list(_list_kind)
	else:
		_show_root()


func _hide_cursors() -> void:
	for a in _cursors:
		a.visible = false
	for key: String in _plates:
		var plate: Dictionary = _plates[key]
		(plate["name"] as Control).visible = false
		(plate["bar"] as Control).visible = false


func _update_cursors() -> void:
	_hide_cursors()
	if _state != S.TARGET:
		return
	for i in _cands.size():
		if not _all and i != _index:
			continue
		var c: RefCounted = _cands[i]
		if i < _cursors.size():
			_cursors[i].visible = true
		var plate: Dictionary = _plates.get(c.key, {})
		if not plate.is_empty():
			(plate["name"] as Control).visible = true
			(plate["bar"] as Control).visible = true
			(plate["root"] as Control).reset_size()


func _process(delta: float) -> void:
	if scene == null or engine == null:
		return
	_time += delta
	for c: RefCounted in engine.enemies:
		var plate: Dictionary = _plates.get(c.key, {})
		if plate.is_empty():
			continue
		var root: Control = plate["root"]
		if root.visible:
			var p: Vector2 = scene.screen_point(c, "feet")
			root.position = (p + Vector2(-root.size.x * 0.5, 8.0)).round()
	if _state == S.TARGET:
		for i in _cands.size():
			if i >= _cursors.size() or not _cursors[i].visible:
				continue
			var p: Vector2 = scene.screen_point(_cands[i], "top")
			_cursors[i].position = p + Vector2(0.0, -6.0 + sin(_time * 7.0) * 4.0)


func _input(event: InputEvent) -> void:
	if not visible or scene == null:
		return
	if _state == S.LIST and event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		Sfx.play("cancel")
		_show_root()
		return
	if _state != S.TARGET:
		return
	if event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_cancel_target()
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			get_viewport().set_input_as_handled()
			_cancel_target()
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			var best := -1
			var best_d := 110.0
			for i in _cands.size():
				var d: float = (scene.screen_point(_cands[i], "center") as Vector2).distance_to(mb.position)
				if d < best_d:
					best_d = d
					best = i
			if best >= 0:
				get_viewport().set_input_as_handled()
				_index = best
				_update_cursors()
				_confirm_target()
		return
	var step := 0
	if event.is_action_pressed("move_left") or event.is_action_pressed("move_up") or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_up"):
		step = -1
	elif event.is_action_pressed("move_right") or event.is_action_pressed("move_down") or event.is_action_pressed("ui_right") or event.is_action_pressed("ui_down"):
		step = 1
	if step != 0:
		get_viewport().set_input_as_handled()
		if not _all and _cands.size() > 1:
			_index = posmod(_index + step, _cands.size())
			Sfx.play("move")
			_update_cursors()
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		if Engine.get_process_frames() != _target_frame:
			_confirm_target()


# ------------------------------------------------------------- fin du combat

func _end_panel(title: String, color: Color) -> VBoxContainer:
	_state = S.END
	_menu_box.visible = false
	_hide_cursors()
	for c in _end_layer.get_children():
		c.queue_free()
	_end_layer.visible = true
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.06, 0.55)
	UI.full_rect(shade)
	_end_layer.add_child(shade)
	var center := CenterContainer.new()
	UI.full_rect(center)
	_end_layer.add_child(center)
	var panel := PanelContainer.new()
	var style := UI.panel_style()
	style.set_content_margin_all(26)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size = Vector2(460, 0)
	panel.add_child(box)
	var head := UI.label(title, 44, color, false, true)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(head)
	var rule := ColorRect.new()
	rule.color = UI.GOLD
	rule.custom_minimum_size = Vector2(240, 2)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.add_child(rule)
	_end_layer.modulate.a = 0.0
	create_tween().tween_property(_end_layer, "modulate:a", 1.0, 0.3)
	return box


func _end_button(box: Control, text: String, value: String) -> Button:
	var b := UI.menu_button(text, 24)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.pressed.connect(_on_end.bind(value))
	box.add_child(b)
	return b


func _on_end(value: String) -> void:
	Sfx.play("confirm")
	_closed.emit(value)


func _line(box: Control, text: String, color: Color = UI.INK, size: int = 22) -> void:
	var l := UI.label(text, size, color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(l)


func show_victory(rewards: Dictionary, guest: bool) -> void:
	var box := _end_panel("Victoire", UI.GOLD)
	if guest:
		_line(box, "L'ennemi est à terre.")
	else:
		_line(box, "Expérience : +%d" % int(rewards.get("xp", 0)))
		if int(rewards.get("money", 0)) > 0:
			_line(box, "Écus : +%d" % int(rewards["money"]))
		var drops: Dictionary = rewards.get("drops", {})
		for id: String in drops:
			_line(box, "Trouvé : %s ×%d" % [str(Database.get_item(id).get("name", id)), int(drops[id])], Color("#bfe8ff"))
		var ups: Array = rewards.get("levelups", [])
		if not ups.is_empty():
			Sfx.play("level")
		for up: Dictionary in ups:
			_line(box, "%s passe au niveau %d !" % [str(up.get("name", "")), int(up.get("to", 1))], UI.GOLD, 24)
			for s: Variant in up.get("skills", []):
				_line(box, "Nouvelle compétence : %s" % str(s), Color("#ffd27a"), 20)
			var points := int(up.get("points", 0))
			if points > 0:
				_line(box, "+%d point%s de talent (menu de pause, Équipe)" % [points, "s" if points > 1 else ""], Color("#bfe8ff"), 20)
	var b := _end_button(box, "Continuer", "ok")
	b.grab_focus.call_deferred()
	await _closed
	_end_layer.visible = false


## Renvoie "retry" ou "title".
func show_defeat() -> String:
	var box := _end_panel("Défaite", Color("#e8847a"))
	_line(box, "Toute l'équipe est à terre.")
	_line(box, "Glandoulf jurera plus tard qu'il se reposait les yeux.", UI.INK_DIM, 19)
	var retry := _end_button(box, "Recommencer le combat", "retry")
	_end_button(box, "Retour à l'écran-titre", "title")
	retry.grab_focus.call_deferred()
	var value: String = await _closed
	_end_layer.visible = false
	return value
