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
const ALLY_BLUE := Color("#9cc8f0")
const HP_GREEN := Color("#7ad06a")
const HP_LOW := Color("#e8785a")
const MP_BLUE := Color("#6aa0e8")
const TILE_BIG := 86.0     # vignette du combattant actif (frise des tours)
const TILE_SMALL := 42.0
const FRIEZE_LEN := 5      # vignettes par frise
const ROOT_HELP := {
	"Attaquer": "Frapper un ennemi avec l'arme.",
	"Compétences": "Techniques de combat, payées en PM.",
	"Objets": "Utiliser un objet de la besace.",
	"Défendre": "Se mettre en garde jusqu'au prochain tour.",
	"Fuir": "Tenter de quitter le combat.",
}

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

var _timeline: HBoxContainer      # frise des tours : actif, cinq suivants, « Ensuite », cinq autres
var _tl_gap: Label                # étiquette de la seconde frise
var _turn_tag: PanelContainer
var _turn_label: Label
var _top: VBoxContainer
var _ribbon: PanelContainer
var _ribbon_label: Label
var _ribbon_tween: Tween
var _hint: PanelContainer
var _hint_label: Label
var _party_panel: PanelContainer
var _party_rows: VBoxContainer
var _rows: Dictionary = {}   # clé -> {card, name, hp, hp_text, mp, mp_text, status, info}
var _menu_box: Control       # menus ancrés au personnage qui joue
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
var _keys: Control            # rappels de touches, en bas à gauche
var _end_layer: Control
var before_battle_slot := ""        # posé par main.gd : sauvegarde automatique juste avant ce combat
var save_screen: Control = null   # posé par main.gd : liste des sauvegardes (défaite)


func _ready() -> void:
	UI.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	_overlay = Control.new()
	UI.full_rect(_overlay)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)

	# frise de l'ordre des tours, en haut à gauche, sur un filet fin
	_timeline = HBoxContainer.new()
	_timeline.position = Vector2(22, 14)
	_timeline.add_theme_constant_override("separation", 2)
	_timeline.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timeline.draw.connect(_draw_frieze)
	add_child(_timeline)
	_turn_tag = PanelContainer.new()
	var ts := UI.panel_style(Color(0.03, 0.035, 0.08, 0.8), UI.GOLD_LINE, 0, 1)
	ts.shadow_size = 0
	ts.content_margin_left = 16
	ts.content_margin_right = 16
	ts.content_margin_top = 1
	ts.content_margin_bottom = 2
	_turn_tag.add_theme_stylebox_override("panel", ts)
	_turn_tag.position = Vector2(26, 106)
	_turn_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_turn_label = UI.caps("Tour 1", 14, UI.INK)
	_turn_tag.add_child(_turn_label)
	add_child(_turn_tag)

	# cartouche du nom de l'action et conseils, en haut au centre
	_top = VBoxContainer.new()
	_top.anchor_left = 0.0
	_top.anchor_right = 1.0
	_top.offset_top = 92.0
	_top.add_theme_constant_override("separation", 10)
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_top)
	_ribbon = PanelContainer.new()
	var rs := UI.panel_style(Color(0.025, 0.03, 0.07, 0.86), Color(UI.GOLD, 0.4), 0, 1)
	rs.shadow_size = 0
	rs.content_margin_left = 26
	rs.content_margin_right = 26
	rs.content_margin_top = 5
	rs.content_margin_bottom = 7
	_ribbon.add_theme_stylebox_override("panel", rs)
	_ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ribbon.modulate.a = 0.0
	_top.add_child(_ribbon)
	_ribbon_label = UI.label("", 22, UI.INK)
	_ribbon.add_child(_ribbon_label)
	_hint = PanelContainer.new()
	_hint.add_theme_stylebox_override("panel", UI.soft_style(0.78, 18))
	_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.visible = false
	_top.add_child(_hint)
	var hint_row := HBoxContainer.new()
	hint_row.add_theme_constant_override("separation", 12)
	_hint.add_child(hint_row)
	var hint_tag := UI.caps("Conseil", 13, UI.GOLD)
	hint_tag.custom_minimum_size = Vector2(0, 24)
	hint_tag.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	hint_row.add_child(hint_tag)
	_hint_label = UI.label("", 18, UI.INK)
	_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint_label.custom_minimum_size = Vector2(520, 0)
	hint_row.add_child(_hint_label)

	# fiches de l'équipe, empilées en haut à droite, sans cadre
	_party_panel = PanelContainer.new()
	_party_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_party_panel.anchor_left = 1.0
	_party_panel.anchor_right = 1.0
	_party_panel.offset_left = -12.0
	_party_panel.offset_right = -12.0
	_party_panel.offset_top = 14.0
	_party_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_party_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_party_panel)
	_party_rows = VBoxContainer.new()
	_party_rows.add_theme_constant_override("separation", 3)
	_party_panel.add_child(_party_rows)

	# menus : posés à côté du personnage qui joue (voir _place_menu)
	_menu_box = Control.new()
	UI.full_rect(_menu_box)
	_menu_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_menu_box.visible = false
	add_child(_menu_box)
	_root_panel = PanelContainer.new()
	_root_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_menu_box.add_child(_root_panel)
	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 2)
	_root_panel.add_child(root_box)
	_root_title = UI.label("", 22, UI.GOLD)
	_root_title.visible = false
	root_box.add_child(_root_title)
	_root_list = VBoxContainer.new()
	_root_list.add_theme_constant_override("separation", 2)
	root_box.add_child(_root_list)
	_list_panel = PanelContainer.new()
	_list_panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	_list_panel.visible = false
	_menu_box.add_child(_list_panel)
	var list_box := VBoxContainer.new()
	list_box.add_theme_constant_override("separation", 2)
	_list_panel.add_child(list_box)
	_list_title = UI.caps("", 13, UI.GOLD)
	_list_title.visible = false
	list_box.add_child(_list_title)
	_list_items = VBoxContainer.new()
	_list_items.add_theme_constant_override("separation", 2)
	list_box.add_child(_list_items)
	_list_desc = UI.label("", 17, UI.INK_DIM, false, true)   # l'aide s'affiche sous l'entrée choisie
	_list_desc.visible = false
	list_box.add_child(_list_desc)

	# rappels de touches, discrets, en bas à gauche
	_keys = VBoxContainer.new()
	_keys.anchor_top = 1.0
	_keys.anchor_bottom = 1.0
	_keys.offset_left = 24.0
	_keys.offset_top = -40.0
	_keys.offset_bottom = -14.0
	_keys.modulate.a = 0.7
	_keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_keys.visible = false
	add_child(_keys)

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
		# curseur net : chevron doré cerné de sombre, pointé sur la cible
		var arrow := Polygon2D.new()
		arrow.polygon = PackedVector2Array([Vector2(-12, -16), Vector2(12, -16), Vector2(0, 2)])
		arrow.color = UI.GOLD
		var edge := Polygon2D.new()
		edge.polygon = PackedVector2Array([Vector2(-16, -21), Vector2(16, -21), Vector2(0, 8)])
		edge.color = Color(0.03, 0.025, 0.06, 0.95)
		edge.show_behind_parent = true
		arrow.add_child(edge)
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
	_keys.visible = false
	_hint.visible = false
	_ribbon.modulate.a = 0.0
	_end_layer.visible = false
	for c in _end_layer.get_children():
		c.queue_free()
	for c in _party_rows.get_children():
		c.queue_free()
	for c in _timeline.get_children():
		c.queue_free()
	_tl_gap = null
	for c in _overlay.get_children():
		c.queue_free()
	_rows = {}
	_plates = {}
	_cursors = []


# ------------------------------------------------------------------ éléments

func _bar(color: Color, height: float = 4.0) -> ProgressBar:
	var b := UI.gauge(color, 40.0, height)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return b


func _set_bar_color(bar: ProgressBar, color: Color) -> void:
	var fill := bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill != null and fill.bg_color != color:
		fill.bg_color = color


## Fiche d'un allié : nom, niveau, états ; PV et PM en chiffres, une jauge fine sous chacun.
func _make_row(c: RefCounted) -> Dictionary:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 0)
	card.add_theme_stylebox_override("panel", _card_style(false))
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_party_rows.add_child(card)
	var info := {"on": false}
	card.draw.connect(func() -> void:
		if bool(info["on"]):
			card.draw_colored_polygon(UI.diamond_points(Vector2(11.0, 20.0), 4.5), UI.GOLD)
			card.draw_line(Vector2(card.size.x - 1.5, 3.0), Vector2(card.size.x - 1.5, card.size.y - 3.0), Color(UI.GOLD, 0.8), 2.0))
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	card.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	col.add_child(head)
	var name_label := UI.label(str(c.name), 18, UI.INK)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	head.add_child(name_label)
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 3)
	head.add_child(status)
	var level := UI.label("Nv %d" % int(c.level), 14, UI.INK_DIM)
	head.add_child(level)
	var hp_row := HBoxContainer.new()
	col.add_child(hp_row)
	var hp_tag := UI.caps("PV", 11, UI.GOLD_DIM)
	hp_tag.size_flags_vertical = Control.SIZE_SHRINK_END
	hp_row.add_child(hp_tag)
	var hp_text := UI.label("", 19, UI.INK)
	hp_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_row.add_child(hp_text)
	var hp := _bar(HP_GREEN, 4.0)
	col.add_child(hp)
	var mp_row := HBoxContainer.new()
	col.add_child(mp_row)
	var mp_tag := UI.caps("PM", 11, UI.GOLD_DIM)
	mp_tag.size_flags_vertical = Control.SIZE_SHRINK_END
	mp_row.add_child(mp_tag)
	var mp_text := UI.label("", 15, UI.INK)
	mp_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mp_row.add_child(mp_text)
	var mp := _bar(MP_BLUE, 3.0)
	col.add_child(mp)
	return {"card": card, "info": info, "name": name_label, "hp": hp, "hp_text": hp_text, "mp": mp, "mp_text": mp_text, "status": status}


func _card_style(active: bool) -> StyleBoxTexture:
	if active:
		return UI.fade_style(Color(0.2, 0.15, 0.05), 0.78)
	return UI.fade_style(Color(0.02, 0.025, 0.06), 0.6)


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


## Sous l'ennemi : états et faiblesses connues, son nom, et (en visant) sa jauge de PV.
func _make_plate(c: RefCounted) -> Dictionary:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 2)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(root)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 3)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(chips)
	var name_label := UI.label(str(c.name), 17, UI.INK, true)
	name_label.add_theme_constant_override("outline_size", 4)
	name_label.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.07, 0.9))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.modulate.a = 0.8
	root.add_child(name_label)
	var bar := UI.gauge(ENEMY_RED, 110.0, 4.0)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.visible = false
	root.add_child(bar)
	return {"root": root, "chips": chips, "name": name_label, "bar": bar, "sig": ""}


## Petites icônes d'états : carré sombre au liseré de la couleur de l'état, deux lettres.
func _status_chips(box: HBoxContainer, c: RefCounted) -> void:
	for id: String in c.statuses:
		var st: Dictionary = Database.get_status(id)
		var color := Database.color(st.get("color", "#ffffff"), UI.INK)
		var icon := PanelContainer.new()
		var s := StyleBoxFlat.new()
		s.bg_color = Color(0.04, 0.04, 0.09, 0.92)
		s.border_color = color
		s.set_border_width_all(1)
		s.set_corner_radius_all(2)
		s.content_margin_left = 3
		s.content_margin_right = 3
		s.content_margin_top = 0
		s.content_margin_bottom = 0
		icon.add_theme_stylebox_override("panel", s)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.add_child(UI.label(str(st.get("name", id)).left(2), 12, color, true))
		box.add_child(icon)


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
		var info: Dictionary = row["info"]
		var on: bool = c == _active and c.alive()
		if bool(info["on"]) != on:
			info["on"] = on
			(row["card"] as PanelContainer).add_theme_stylebox_override("panel", _card_style(on))
			(row["card"] as PanelContainer).queue_redraw()
		var status: HBoxContainer = row["status"]
		for n in status.get_children():
			status.remove_child(n)
			n.queue_free()
		if not c.alive():
			status.add_child(UI.label("À terre", 14, Color(0.75, 0.5, 0.5), true))
		else:
			_status_chips(status, c)
		(row["card"] as PanelContainer).modulate.a = 1.0 if c.alive() else 0.7
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
				chips.remove_child(n)
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


## Frise des tours. order[0] est celui qui joue (grande vignette) ; les cinq suivants forment
## la première frise, les cinq d'après la seconde (« Ensuite »). Le moteur n'a pas de manches
## : les deux frises sont l'ordre prévu des actions, calculé par engine.preview.
func set_timeline(order: Array) -> void:
	for n in _timeline.get_children():
		_timeline.remove_child(n)
		n.queue_free()
	_tl_gap = null
	if order.is_empty():
		return
	_timeline.add_child(_tile(order[0], TILE_BIG, true))
	for i in range(1, mini(order.size(), 1 + FRIEZE_LEN)):
		_timeline.add_child(_tile(order[i], TILE_SMALL, false))
	if order.size() > 1 + FRIEZE_LEN:
		_tl_gap = UI.caps("Ensuite", 12, UI.INK_DIM)
		_tl_gap.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_tl_gap.custom_minimum_size = Vector2(86, 0)
		_tl_gap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_timeline.add_child(_tl_gap)
		for i in range(1 + FRIEZE_LEN, mini(order.size(), 1 + 2 * FRIEZE_LEN)):
			_timeline.add_child(_tile(order[i], TILE_SMALL, false))
	_timeline.queue_redraw()
	var living := 0
	if engine != null:
		for c: RefCounted in engine.all():
			if c.alive():
				living += 1
		_turn_label.text = "TOUR %d" % (int(engine.turn_count) / maxi(1, living) + 1)


## Vignette en losange d'un combattant (portrait rogné dans le losange).
func _tile(c: RefCounted, side: float, active: bool) -> Control:
	var t := Control.new()
	t.custom_minimum_size = Vector2(side, side)
	t.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var letter := ""
	if c.side == "enemy" and str(c.name) != str((c.data as Dictionary).get("name", "")):
		letter = str(c.name).right(1)
	t.draw.connect(_draw_tile.bind(t, Sprites.battler_icon(c.sprite), ALLY_BLUE if c.side == "party" else ENEMY_RED, active, letter))
	return t


func _draw_tile(t: Control, tex: Texture2D, tint: Color, active: bool, letter: String) -> void:
	var s := t.size.x
	var h := s * 0.5
	var edge := UI.diamond_points(Vector2(h, h), h - 1.0)
	var inner := UI.diamond_points(Vector2(h, h), h - (6.0 if active else 2.5))
	t.draw_colored_polygon(inner, Color(0.04, 0.04, 0.09, 0.92))
	if tex != null:
		var uv := PackedVector2Array()
		var white := PackedColorArray()
		for p: Vector2 in inner:
			uv.append(Vector2(0.06, 0.04) + p / s * Vector2(0.88, 0.88))
			white.append(Color.WHITE if active else Color(1, 1, 1, 0.88))
		t.draw_polygon(inner, white, uv, tex)
	var line := PackedVector2Array(inner)
	line.append(inner[0])
	t.draw_polyline(line, UI.GOLD if active else Color(tint, 0.9), 2.0 if active else 1.5, true)
	if active:
		var ring := PackedVector2Array(edge)
		ring.append(edge[0])
		t.draw_polyline(ring, Color(tint, 0.65), 1.5, true)
	if letter != "":
		t.draw_string_outline(UI.font(true), Vector2(s * 0.56, s * 0.8), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.9))
		t.draw_string(UI.font(true), Vector2(s * 0.56, s * 0.8), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)


## Filet fin sous la frise, interrompu par l'étiquette « Ensuite ».
func _draw_frieze() -> void:
	var kids := _timeline.get_children()
	if kids.size() < 2:
		return
	var first: Control = kids[0]
	var last: Control = kids[kids.size() - 1]
	var y := floorf(_timeline.size.y * 0.5) + 0.5
	var x0 := first.position.x + first.size.x - 8.0
	var x1 := last.position.x + last.size.x + 36.0
	var col := Color(UI.GOLD, 0.5)
	if _tl_gap != null and _tl_gap.get_parent() == _timeline:
		_timeline.draw_line(Vector2(x0, y), Vector2(_tl_gap.position.x + 4.0, y), col, 1.0)
		_timeline.draw_line(Vector2(_tl_gap.position.x + _tl_gap.size.x - 4.0, y), Vector2(x1, y), col, 1.0)
	else:
		_timeline.draw_line(Vector2(x0, y), Vector2(x1, y), col, 1.0)
	_timeline.draw_colored_polygon(UI.diamond_points(Vector2(x1 + 3.0, y), 3.0), col)


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
	l.add_theme_constant_override("outline_size", 8)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.035, 0.09))
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


## Rappels de touches (bas gauche) selon l'étape du menu.
func _update_keys() -> void:
	for n in _keys.get_children():
		_keys.remove_child(n)
		n.queue_free()
	if _state == S.ROOT:
		_keys.add_child(UI.hints([["Flèches", "choisir"], ["Entrée", "valider"]], 14))
	elif _state == S.LIST or _state == S.TARGET:
		_keys.add_child(UI.hints(UI.KEYS_MENU, 14))
	_keys.visible = _state in [S.ROOT, S.LIST, S.TARGET]


# ------------------------------------------------------------------- menus

## Demande son action au joueur. Renvoie {"type", "id", "target"}.
func ask_action(actor: RefCounted) -> Dictionary:
	_actor = actor
	_last_root = 0
	_show_root()
	var action: Dictionary = await action_chosen
	_state = S.IDLE
	_menu_box.visible = false
	_update_keys()
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


## Le menu s'ouvre à côté du personnage qui joue, sans sortir de l'image ; la liste
## (compétences, objets) se décale en cascade vers le bas et la gauche.
func _place_menu() -> void:
	if not _menu_box.visible or _actor == null or scene == null:
		return
	var view := size if size.x > 0.0 else Vector2(1280, 720)
	_root_panel.reset_size()
	_list_panel.reset_size()
	var c: Vector2 = scene.screen_point(_actor, "center")
	var rw := _root_panel.size.x
	var rh := _root_panel.size.y
	var top := clampf(c.y - 96.0, 120.0, view.y - rh - 18.0)
	var edge := c.x - 64.0
	for o: RefCounted in engine.party:
		if o != _actor and o.alive():
			var q: Vector2 = scene.screen_point(o, "center")
			if q.x < c.x and q.y > top - 60.0 and q.y < top + rh + 20.0:
				edge = minf(edge, q.x - 56.0)   # le menu se range à gauche des alliés qu'il couvrirait...
	var min_left := 10.0
	for e: RefCounted in engine.enemies:
		if e.alive():
			min_left = maxf(min_left, (scene.screen_point(e, "center") as Vector2).x + 70.0)   # ...sans jamais couvrir un ennemi
	var x := minf(maxf(edge - rw, min_left), c.x - 40.0 - rw)
	var root_pos := Vector2(clampf(x, 10.0, view.x - rw - 10.0), top)
	_root_panel.position = root_pos
	if _list_panel.visible:
		var lw := _list_panel.size.x
		var lh := _list_panel.size.y
		_list_panel.position = Vector2(clampf(root_pos.x - 40.0, 10.0, view.x - lw - 10.0), clampf(root_pos.y + 44.0, 120.0, view.y - lh - 18.0))


func _set_root_live(live: bool) -> void:
	_root_panel.modulate.a = 1.0 if live else 0.3
	for b in _root_list.get_children():
		(b as Button).focus_mode = Control.FOCUS_ALL if live else Control.FOCUS_NONE
		(b as Button).mouse_filter = Control.MOUSE_FILTER_STOP if live else Control.MOUSE_FILTER_IGNORE


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
		var b := UI.band_button(str(e[0]), 22, str(ROOT_HELP.get(str(e[0]), "")), "", 224)
		b.disabled = not bool(e[1])
		b.pressed.connect(_on_root.bind(i))
		_root_list.add_child(b)
	_set_root_live(true)
	_focus(_root_list, _last_root)
	_update_keys()
	_place_menu()


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
	_root_panel.visible = true    # le menu reste visible, estompé, sous la liste en cascade
	_set_root_live(false)
	_list_panel.visible = true
	_list_title.text = "COMPÉTENCES" if kind == "skill" else "OBJETS"
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
		var right := ""
		var usable := true
		if kind == "skill":
			right = "%d PM" % int(def.get("cost", 0))
			usable = engine.can_use_skill(_actor, id)
		else:
			right = "×%d" % int(engine.inventory.get(id, 0))
		if (engine.candidates(_actor, str(def.get("target", "enemy"))) as Array).is_empty():
			usable = false
		var b := UI.band_button(text, 21, str(def.get("desc", "")), right, 380)
		b.disabled = not usable
		b.pressed.connect(_on_list.bind(kind, id, str(def.get("target", "enemy"))))
		_list_items.add_child(b)
		if str(_last_list.get(kind, "")) == id:
			focus_index = i
	_focus(_list_items, focus_index)
	_update_keys()
	_place_menu()


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
	_menu_box.visible = false   # pendant le choix de la cible, la scène reste dégagée
	get_viewport().gui_release_focus()
	_update_cursors()
	_update_keys()


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
		(plate["name"] as Control).modulate.a = 0.8
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
			(plate["name"] as Control).modulate.a = 1.0
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
			_cursors[i].position = p + Vector2(0.0, -34.0 + sin(_time * 7.0) * 4.0)
	_place_menu()



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
	_keys.visible = false
	_hide_cursors()
	for c in _end_layer.get_children():
		c.queue_free()
	_end_layer.visible = true
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.06, 0.45)
	UI.full_rect(shade)
	_end_layer.add_child(shade)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	UI.full_rect(column)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end_layer.add_child(column)
	# bande sombre qui s'estompe en haut et en bas, titre et filets ornés au milieu
	var holder := PanelContainer.new()
	holder.add_theme_stylebox_override("panel", UI.band_style(0.86))
	holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(holder)
	var inner := VBoxContainer.new()
	inner.alignment = BoxContainer.ALIGNMENT_CENTER
	holder.add_child(inner)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size = Vector2(520, 0)
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	inner.add_child(box)
	var head_row := HBoxContainer.new()
	head_row.alignment = BoxContainer.ALIGNMENT_CENTER
	head_row.add_theme_constant_override("separation", 24)
	box.add_child(head_row)
	head_row.add_child(UI.rule(130.0, "in", color))
	var head := UI.label(title, 58, color)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head_row.add_child(head)
	head_row.add_child(UI.rule(130.0, "out", color))
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	box.add_child(gap)
	_end_layer.modulate.a = 0.0
	create_tween().tween_property(_end_layer, "modulate:a", 1.0, 0.35)
	return box


func _end_button(box: Control, text: String, value: String) -> Button:
	var b := UI.menu_button(text, 24)
	b.alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.custom_minimum_size = Vector2(340, 0)
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
				_line(box, "+%d point%s de talent (menu de pause, Talents)" % [points, "s" if points > 1 else ""], Color("#bfe8ff"), 20)
	var b := _end_button(box, "Continuer", "ok")
	b.grab_focus.call_deferred()
	await _closed
	_end_layer.visible = false


## Renvoie "retry", "title" ou "load:<emplacement>" (« Charger une sauvegarde », ou
## « Revenir avant le combat » si before_slot / before_battle_slot désigne la sauvegarde
## automatique faite juste avant ce combat ; "" s'il n'y en a pas).
func show_defeat(before_slot: String = "") -> String:
	if before_slot == "":
		before_slot = before_battle_slot
	var box := _end_panel("Défaite", Color("#e8847a"))
	_line(box, "Toute l'équipe est à terre.")
	_line(box, "Glandoulf jurera plus tard qu'il se reposait les yeux.", UI.INK_DIM, 19)
	var retry := _end_button(box, "Recommencer le combat", "retry")
	if before_slot != "":
		_end_button(box, "Revenir avant le combat", "before")
	var load_btn := _end_button(box, "Charger une sauvegarde", "load")
	load_btn.disabled = not SaveManager.has_save() or save_screen == null
	_end_button(box, "Retour à l'écran-titre", "title")
	retry.grab_focus.call_deferred()
	var value := ""
	while true:
		value = await _closed
		if value == "before":
			value = "load:" + before_slot
			break
		if value != "load":
			break
		# la liste des sauvegardes passe par-dessus ; Échap ramène ici
		save_screen.open("load", "defeat")
		var chosen: String = await save_screen.finished
		if chosen != "":
			value = "load:" + chosen
			break
		load_btn.grab_focus.call_deferred()
	_end_layer.visible = false
	return value
