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
const IconPainter = preload("res://src/gfx/icon_painter.gd")
# Zones d'interface, que la mise en page de la scène (BattleScene.layout) connaît d'avance.
const CARD_W := 300.0      # fiche d'un héros
const CARD_PITCH := 71.0   # hauteur d'une fiche et de l'espace qui la sépare de la suivante
const CARDS_TOP := 14.0
const CARDS_RIGHT := 12.0
const TOP_BAND_H := 134.0  # frise des tours, étiquette du tour, cartouche d'action et conseil
const ELAN_COLOR := Color("#ffd24a")
const ELAN_HOT := Color("#ff8a3a")
const HP_MID := Color("#e8b04a")      # PV entre 30 % et 50 %
const HP_RED := Color("#e05a4a")      # PV sous 30 %
const BROKEN_COLOR := Color("#ff8a6a")
const WEAK_UNKNOWN := Color(0.6, 0.6, 0.66)   # case d'une faiblesse pas encore découverte
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
var _plate_links: Control        # trait de rappel entre une plaque écartée et les pieds de son ennemi
var _link_pairs: Array = []      # [[pied, plaque (haut, milieu)], ...] à tracer
const PLATE_MARGIN := 12.0       # une plaque ne s'approche jamais à moins de tant de pixels d'un bord de l'écran
var _plate_in_sig := 0           # signature des entrées du placement des plaques
var _plate_spots: Dictionary = {}   # dernières places trouvées
var _plate_sig := 0           # signature des places de plaques au dernier réglage du premier plan
var _menu_sig := 0           # signature de la scène au dernier placement des menus
var _root_pos := Vector2.ZERO
var _list_pos := Vector2.ZERO

var _timeline: HBoxContainer      # frise des tours : actif, cinq suivants, « Ensuite », cinq autres
var _frieze_bg: Texture2D            # fond de la frise des tours
var _tl_gap: Label                # étiquette de la seconde frise
const PLATE_NAME_MAX := 22   # un nom plus long perd son titre sur la plaque (plate_name)
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
var _warn: Dictionary = {}    # clé -> triangle rouge au-dessus d'un ennemi qui prépare un coup annoncé
var _plates: Dictionary = {}  # clé -> {root, chips, name, bar}
var _cursors: Array[Node2D] = []   # mains qui désignent les cibles
var _elan_commit := 0               # points d'élan engagés pour l'action en cours de choix
var _elan_bars: Array = []          # {pips, label} : une barre d'élan par panneau de menu
var _bar_pos: Array[Vector2] = [Vector2.ZERO, Vector2.ZERO]   # place libre trouvée pour chaque barre d'élan
var _elan_focus := ""               # compétence survolée dans la liste (pour l'effet affiché)
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
	var fg := Gradient.new()
	fg.offsets = PackedFloat32Array([0.0, 0.72, 1.0])
	fg.colors = PackedColorArray([Color(0.025, 0.03, 0.07, 0.8), Color(0.025, 0.03, 0.07, 0.7), Color(0.025, 0.03, 0.07, 0.0)])
	var fgt := GradientTexture2D.new()
	fgt.gradient = fg
	fgt.width = 128
	fgt.height = 4
	_frieze_bg = fgt
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
	_top.offset_left = RIBBON_LEFT   # (ni sur la vignette « Tour N » qui pend sous la frise)
	_top.anchor_right = 1.0
	_top.offset_right = -(CARD_W + CARDS_RIGHT + 14.0)   # (le bandeau se centre à gauche des fiches de l'équipe : jamais dessus)
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
	_menu_box.add_child(_make_elan_bar())   # les deux barres d'élan (menu, liste) se posent à part : voir _place_menu
	_menu_box.add_child(_make_elan_bar())
	(_elan_bars[1]["panel"] as Control).visible = false

	# rappels de touches, discrets, en bas à gauche
	_keys = VBoxContainer.new()
	_keys.anchor_top = 1.0
	_keys.anchor_bottom = 1.0
	_keys.offset_left = 24.0
	_keys.offset_top = -40.0
	_keys.offset_bottom = -14.0
	_keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_keys.draw.connect(func() -> void:   # bandeau discret sous les touches : lisibles sur le premier plan flou
		_keys.draw_texture_rect(_frieze_bg, Rect2(-24.0, -4.0, _keys.size.x + 90.0, _keys.size.y + 8.0), false))
	_keys.visible = false
	add_child(_keys)

	_end_layer = Control.new()
	UI.full_rect(_end_layer)
	_end_layer.visible = false
	add_child(_end_layer)


# ------------------------------------------------------------ ouverture / fermeture

## Place que prennent les fiches de n héros (coin haut droit de l'écran), avec une petite marge.
static func cards_zone(n: int, view: Vector2) -> Rect2:
	return Rect2(view.x - CARDS_RIGHT - CARD_W, CARDS_TOP, CARD_W, float(n) * CARD_PITCH - 3.0).grow(6.0)


## Bande du haut de l'écran réservée à la frise des tours et aux cartouches : aucun combattant n'y entre.
static func top_band(view: Vector2) -> Rect2:
	return Rect2(0.0, 0.0, view.x, TOP_BAND_H)


func open(p_scene: Node3D, p_engine: RefCounted) -> void:
	close()
	scene = p_scene
	engine = p_engine
	_plate_sig = 0
	visible = true
	for c: RefCounted in engine.party:
		_rows[c.key] = _make_row(c)
	_plate_links = Control.new()   # (derrière les plaques : le trait qui relie une plaque écartée à son ennemi)
	_plate_links.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_plate_links.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_plate_links.draw.connect(_draw_plate_links)
	_overlay.add_child(_plate_links)
	_link_pairs = []
	for c: RefCounted in engine.enemies:
		_plates[c.key] = _make_plate(c)
	for _i in 8:
		# curseur : une main gantée qui désigne la cible d'en haut (voir _process pour le va-et-vient)
		var hand := Sprite2D.new()
		hand.texture = Sprites.icon("hand")
		hand.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hand.offset = Vector2(-8.5, 0.0)   # le bout du doigt est à l'origine
		hand.rotation = PI * 0.5
		hand.scale = Vector2(3.0, 3.0)   # 17 x 12 px peints : 51 x 36 à l'écran
		hand.visible = false
		_overlay.add_child(hand)
		_cursors.append(hand)
	_intro_slide()
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
	_warn = {}
	_cursors = []
	_elan_commit = 0


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
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 6)
	card.add_child(line)
	var face := TextureRect.new()   # petit portrait, dans un cadre sombre
	face.texture = Sprites.battler_icon(c.sprite)
	face.custom_minimum_size = Vector2(42, 42)
	face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	face.draw.connect(func() -> void:
		face.draw_rect(Rect2(Vector2.ZERO, face.size), Color(UI.GOLD, 0.35), false, 1.0))
	line.add_child(face)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(col)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 8)
	col.add_child(head)
	var name_label := UI.label(str(c.name), 17, UI.INK)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.clip_text = true
	head.add_child(name_label)
	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 3)
	head.add_child(status)
	var level := UI.label("Nv %d" % int(c.level), 13, UI.INK_DIM)
	head.add_child(level)
	var hp_row := HBoxContainer.new()
	col.add_child(hp_row)
	var hp_tag := UI.caps("PV", 11, UI.GOLD_DIM)
	hp_tag.size_flags_vertical = Control.SIZE_SHRINK_END
	hp_row.add_child(hp_tag)
	var hp_text := UI.label("", 17, UI.INK)
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
	var pips := Control.new()   # l'élan : cinq losanges (voir _draw_pips)
	pips.custom_minimum_size = Vector2(86, 16)
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pips.draw.connect(_draw_pips.bind(pips, 7.0))
	mp_row.add_child(pips)
	var mp_text := UI.label("", 14, UI.INK)
	mp_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	mp_row.add_child(mp_text)
	var mp := _bar(MP_BLUE, 3.0)
	col.add_child(mp)
	return {"card": card, "info": info, "name": name_label, "hp": hp, "hp_text": hp_text, "mp": mp, "mp_text": mp_text, "status": status, "pips": pips}


func _card_style(active: bool) -> StyleBoxTexture:
	var st := UI.fade_style(Color(0.2, 0.15, 0.05), 0.78) if active else UI.fade_style(Color(0.02, 0.025, 0.06), 0.6)
	st.content_margin_top = 3   # fiche compacte : la place du haut de l'écran est comptée (voir CARD_PITCH)
	st.content_margin_bottom = 4
	return st


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
## Nom sur la plaque d'un ennemi : sans titre (« Saumure, capitaine des Boucaniers » -> « Saumure »), en gardant
## la lettre qui distingue des jumeaux (« Gros Gobelardon, contremaître du camp B » -> « Gros Gobelardon B ») : les
## plaques restent compactes, donc alignées proprement sous leur ennemi.
static func plate_name(full: String) -> String:
	if full.length() <= PLATE_NAME_MAX or not full.contains(","):
		return full
	var head := full.get_slice(",", 0).strip_edges()
	var tail := full.get_slice(" ", full.get_slice_count(" ") - 1)
	if tail.length() == 1 and tail == tail.to_upper() and tail != head.get_slice(" ", head.get_slice_count(" ") - 1):
		return head + " " + tail
	return head


func _make_plate(c: RefCounted) -> Dictionary:
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 2)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_overlay.add_child(root)
	var chips := HBoxContainer.new()
	chips.add_theme_constant_override("separation", 3)
	chips.alignment = BoxContainer.ALIGNMENT_CENTER
	root.add_child(chips)
	var shown := plate_name(str(c.name))
	var name_label := UI.label(shown, 17 if shown.length() <= 18 else 14, UI.INK, true)
	name_label.add_theme_constant_override("outline_size", 4)
	name_label.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.07, 0.9))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.modulate.a = 0.8
	root.add_child(name_label)
	var bar := UI.gauge(ENEMY_RED, 110.0, 4.0)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	bar.visible = false
	root.add_child(bar)
	return {"root": root, "chips": chips, "name": name_label, "bar": bar, "sig": "", "known": [], "seen": false}


## Petites icônes d'états : l'icône peinte de l'état dans un carré sombre au liseré de sa couleur
## (deux lettres si l'état n'a pas d'icône).
func _status_chips(box: HBoxContainer, c: RefCounted) -> void:
	for id: String in c.statuses:
		var st: Dictionary = Database.get_status(id)
		var color := Database.color(st.get("color", "#ffffff"), UI.INK)
		box.add_child(_icon_slot(id, color, str(st.get("name", id)).left(2)))


## Carré sombre au liseré « color » portant l'icône « kind » (agrandie deux fois), ou « fallback ».
func _icon_slot(kind: String, color: Color, fallback: String = "") -> PanelContainer:
	var slot := PanelContainer.new()
	var s := StyleBoxFlat.new()
	s.bg_color = Color(0.04, 0.04, 0.09, 0.92)
	s.border_color = color
	s.set_border_width_all(1)
	s.set_corner_radius_all(2)
	s.set_content_margin_all(1)
	slot.add_theme_stylebox_override("panel", s)
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if IconPainter.kinds().has(kind):
		var tex := TextureRect.new()
		tex.texture = Sprites.icon(kind)
		tex.custom_minimum_size = Vector2(20, 20)
		tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(tex)
	else:
		slot.add_child(UI.label(fallback, 12, color, true))
	return slot


## Petit bouclier de l'ennemi : ses points restants au milieu ; brisé, l'icône de l'état Ébranlé.
func _shield_widget(c: RefCounted) -> Control:
	var w := Control.new()
	w.custom_minimum_size = Vector2(26, 26)
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.draw.connect(func() -> void:
		var broken: bool = c.has_status("ebranle")
		var col := BROKEN_COLOR if broken else Color("#e8ecf4")
		var pts := PackedVector2Array([Vector2(2, 1), Vector2(24, 1), Vector2(24, 14), Vector2(13, 25), Vector2(2, 14)])
		w.draw_colored_polygon(pts, Color(0.06, 0.07, 0.14, 0.95))
		var ring := PackedVector2Array(pts)
		ring.append(pts[0])
		w.draw_polyline(ring, col, 2.0, true)
		if broken:
			w.draw_texture_rect(Sprites.icon("ebranle"), Rect2(2, 2, 22, 22), false)
		else:
			var txt := str(int(c.shield))
			var fs := 15
			var tw := UI.font(true).get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
			w.draw_string(UI.font(true), Vector2(13.0 - tw * 0.5, 17.0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col))
	return w


## Les cinq pastilles d'élan d'une fiche d'allié (méta « reserve » et « commit » posées par refresh).
func _draw_pips(c: Control, r: float) -> void:
	var reserve := int(c.get_meta("reserve", 0))
	var commit := int(c.get_meta("commit", 0))
	var step := 2.0 * r + 3.0
	for i in 5:
		var at := Vector2(r + 1.0 + float(i) * step, c.size.y * 0.5)
		_draw_pip(c, at, r, i < reserve, i < reserve and i >= reserve - commit)


func _draw_pip(c: Control, at: Vector2, r: float, full: bool, engaged: bool) -> void:
	var pts := UI.diamond_points(at, r)
	var ring := PackedVector2Array(pts)
	ring.append(pts[0])
	if full:
		c.draw_colored_polygon(pts, ELAN_HOT if engaged else ELAN_COLOR)
		c.draw_polyline(ring, Color.WHITE if engaged else Color(0.25, 0.17, 0.04), 1.5 if engaged else 1.0, true)
	else:
		c.draw_polyline(ring, Color(ELAN_COLOR, 0.35), 1.0, true)


## Pastilles du menu : plus grandes, entre deux flèches qui disent qu'on peut en engager.
func _draw_bar_pips(c: Control) -> void:
	var reserve := int(c.get_meta("reserve", 0))
	var commit := int(c.get_meta("commit", 0))
	var can := int(c.get_meta("top", 0)) > 0
	var y := c.size.y * 0.5
	var tri := Color(ELAN_COLOR, 0.9 if can else 0.25)
	c.draw_colored_polygon(PackedVector2Array([Vector2(6, y - 5), Vector2(6, y + 5), Vector2(0, y)]), tri)
	for i in 5:
		_draw_pip(c, Vector2(14.0 + float(i) * 14.0, y), 6.0, i < reserve, i < reserve and i >= reserve - commit)
	var x := 14.0 + 4.0 * 14.0 + 10.0
	c.draw_colored_polygon(PackedVector2Array([Vector2(x, y - 5), Vector2(x, y + 5), Vector2(x + 6, y)]), tri)


func _make_elan_bar() -> Control:
	var panel := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.03, 0.035, 0.07, 0.86)
	st.border_color = Color(ELAN_COLOR, 0.6)
	st.border_width_left = 3
	st.content_margin_left = 10
	st.content_margin_right = 12
	st.content_margin_top = 1
	st.content_margin_bottom = 2
	panel.add_theme_stylebox_override("panel", st)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 0)
	panel.add_child(col)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	col.add_child(row)
	var ic := TextureRect.new()
	ic.texture = Sprites.icon("elan")
	ic.custom_minimum_size = Vector2(20, 20)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(ic)
	var pips := Control.new()
	pips.custom_minimum_size = Vector2(94, 20)
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pips.draw.connect(_draw_bar_pips.bind(pips))
	row.add_child(pips)
	var label := UI.label("", 14, ELAN_COLOR)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	_elan_bars.append({"pips": pips, "label": label, "panel": panel})
	return panel


## Effet de l'élan engagé sur l'action en cours de choix (attaque de base, ou compétence survolée).
func _elan_text() -> String:
	if _actor == null or engine == null:
		return ""
	var n := _elan_commit
	var action: Dictionary = {"type": "attack"}
	if _state == S.LIST:
		if _list_kind != "skill":
			return "Aucun effet"
		action = {"type": "skill", "id": _elan_focus}
	var kind: String = engine.elan_kind(_actor, action)
	if kind == "":
		return "Aucun effet" if _state == S.LIST else ""
	if n == 0:
		if int(_actor.elan) == 0:
			return "Réserve vide"
		return "Engager"
	var def: Dictionary = Database.get_skill(_elan_focus) if _state == S.LIST else {}
	match kind:
		"hits":
			return "%d coups" % (n + 1)
		"power":
			return "Puissance ×%s" % _fmt(engine.elan_mult(def, n))
		"heal":
			return "Soin ×%s" % _fmt(engine.elan_mult(def, n, true))
	return "+%d tour%s" % [n, "s" if n > 1 else ""]


func _fmt(v: float) -> String:
	var t := ("%.1f" % v).replace(".", ",")
	return t.trim_suffix(",0")


func _update_elan_bars() -> void:
	if _actor == null or engine == null:
		return
	var top := mini(int(_actor.elan), int(engine.ELAN_COMMIT_MAX))
	for b: Dictionary in _elan_bars:
		var pips: Control = b["pips"]
		pips.set_meta("reserve", int(_actor.elan))
		pips.set_meta("commit", _elan_commit)
		pips.set_meta("top", top)
		pips.queue_redraw()
		(b["label"] as Label).text = _elan_text()
	refresh()


func _set_commit(v: int) -> void:
	var top := mini(int(_actor.elan), int(engine.ELAN_COMMIT_MAX))
	v = clampi(v, 0, top)
	if v == _elan_commit:
		return
	Sfx.play("elan" if v > _elan_commit else "elan_off", 1.0 + 0.14 * float(v))
	_elan_commit = v
	if scene != null:
		scene.elan_preview(_actor, v)
	_update_elan_bars()


func _on_list_focus(id: String) -> void:
	_elan_focus = id
	_update_elan_bars()


## Icône du genre d'arme porté par un allié (null s'il n'en porte pas, ou pour un ennemi).
func _weapon_icon(c: RefCounted) -> Texture2D:
	if c.side != "party":
		return null
	var m: Dictionary = GameState.member(str(c.source))
	var eq: Variant = m.get("equip", {})
	if not (eq is Dictionary):
		return null
	var w := str((eq as Dictionary).get("weapon", ""))
	var t := str(Database.get_item(w).get("type", "")) if w != "" else ""
	return Sprites.icon(t) if IconPainter.kinds().has(t) else null


## Remet à jour jauges, états, boucliers et faiblesses.
func refresh() -> void:
	if engine == null:
		return
	for t in _timeline.get_children():   # la marque « brisé » des vignettes suit l'état
		t.queue_redraw()
	for c: RefCounted in engine.party:
		var row: Dictionary = _rows.get(c.key, {})
		if row.is_empty():
			continue
		var hp: ProgressBar = row["hp"]
		hp.max_value = c.max_hp()
		hp.value = c.hp
		var pct: float = float(c.hp) / float(c.max_hp())
		_set_bar_color(hp, HP_GREEN if pct > 0.5 else (HP_MID if pct >= 0.3 else HP_RED))
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
		var pips: Control = row["pips"]
		pips.set_meta("reserve", int(c.elan) if c.alive() else 0)
		pips.set_meta("commit", _elan_commit if (c == _active and _state in [S.ROOT, S.LIST, S.TARGET]) else 0)
		pips.queue_redraw()
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
			if int(c.shield_max) > 0:
				chips.add_child(_shield_widget(c))
			var fresh: Array = []
			for w: String in c.weak:
				if known.has(w):
					var el: Dictionary = Database.get_element(w)
					var slot := _icon_slot(w, Database.color(el.get("color", "#ffffff"), UI.INK), str(el.get("short", w)))
					chips.add_child(slot)
					if bool(plate["seen"]) and not (plate["known"] as Array).has(w):
						fresh.append(slot)
				else:
					chips.add_child(_icon_slot("unknown", WEAK_UNKNOWN, "?"))
			plate["known"] = known.duplicate()
			plate["seen"] = true
			for id: String in c.statuses:
				if id != "ebranle":
					var st: Dictionary = Database.get_status(id)
					chips.add_child(_icon_slot(id, Database.color(st.get("color", "#ffffff"), UI.INK), str(st.get("name", id)).left(2)))
			if c.has_status("ebranle"):
				chips.add_child(_chip("Brisé", BROKEN_COLOR))
			root.reset_size()
			for slot: Control in fresh:   # une faiblesse qui vient d'être découverte : éclat, puis la case se pose
				slot.pivot_offset = Vector2(11, 11)
				slot.scale = Vector2(1.9, 1.9)
				slot.modulate = Color(3.0, 3.0, 3.0)
				var tw := slot.create_tween()
				tw.set_parallel(true)
				tw.tween_property(slot, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.tween_property(slot, "modulate", Color.WHITE, 0.5)
		var bar: ProgressBar = plate["bar"]
		bar.max_value = c.max_hp()
		bar.value = c.hp


func set_active(c: RefCounted) -> void:
	_active = c
	_elan_commit = 0
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
	t.set_meta("c", c)
	t.draw.connect(_draw_tile.bind(t, Sprites.battler_icon(c.sprite), ALLY_BLUE if c.side == "party" else ENEMY_RED, active, letter))
	return t


func _draw_tile(t: Control, tex: Texture2D, tint: Color, active: bool, letter: String) -> void:
	t.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var s := t.size.x
	var h := s * 0.5
	var edge := UI.diamond_points(Vector2(h, h), h - 1.0)
	var inner := UI.diamond_points(Vector2(h, h), h - (6.0 if active else 2.5))
	t.draw_colored_polygon(inner, Color(0.05, 0.09, 0.2, 0.94) if tint == ALLY_BLUE else Color(0.22, 0.05, 0.07, 0.94))
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
	var who: Variant = t.get_meta("c", null)
	if who != null and (who as RefCounted).has_status("ebranle"):   # brisé : il ne jouera pas ce tour
		t.draw_texture_rect(Sprites.icon("ebranle"), Rect2(s * 0.5 - 12.0, s - 26.0, 24.0, 24.0), false)
	if letter != "":
		t.draw_string_outline(UI.font(true), Vector2(s * 0.56, s * 0.8), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, Color(0, 0, 0, 0.9))
		t.draw_string(UI.font(true), Vector2(s * 0.56, s * 0.8), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)


## Filet fin sous la frise, interrompu par l'étiquette « Ensuite ».
func _draw_frieze() -> void:
	var kids := _timeline.get_children()
	if kids.size() > 0:
		# fond sombre estompé vers la droite : la frise reste lisible sur une arène claire
		var last_k: Control = kids[kids.size() - 1]
		var wide := last_k.position.x + last_k.size.x + 70.0
		_timeline.draw_texture_rect(_frieze_bg, Rect2(-22.0, -12.0, wide + 22.0, _timeline.size.y + 24.0), false)
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


## Arrivée des deux camps : les fiches glissent depuis la droite, les plaques des ennemis se fondent.
func _intro_slide() -> void:
	if scene == null or bool(scene.fast):
		return
	_party_panel.offset_left = 330.0
	_party_panel.offset_right = 330.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_party_panel, "offset_left", -12.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(_party_panel, "offset_right", -12.0, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	var i := 0
	for key: String in _plates:
		var root: Control = (_plates[key] as Dictionary)["root"]
		root.modulate.a = 0.0
		tw.tween_property(root, "modulate:a", 1.0, 0.5).set_delay(0.25 + 0.12 * float(i))
		i += 1


## Bouclier en éclats : des éclats clairs partent du point « at » (écran) et retombent.
func shatter(at: Vector2) -> void:
	if scene == null or bool(scene.fast):
		return
	for i in 16:
		var shard := Polygon2D.new()
		var r := randf_range(4.0, 9.0)
		shard.polygon = PackedVector2Array([Vector2(-r, -r * 0.5), Vector2(r, 0.0), Vector2(-r * 0.3, r)])
		shard.color = Color("#dfeaff") if i % 3 else Color("#ffb59a")
		shard.position = at
		shard.rotation = randf() * TAU
		_overlay.add_child(shard)
		var dest := at + Vector2.from_angle(randf() * TAU) * randf_range(50.0, 170.0) + Vector2(0.0, 50.0)
		var tw := shard.create_tween()
		tw.set_parallel(true)
		tw.tween_property(shard, "position", dest, 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(shard, "rotation", shard.rotation + randf_range(-6.0, 6.0), 0.7)
		tw.tween_property(shard, "modulate:a", 0.0, 0.7).set_delay(0.2)
		tw.chain().tween_callback(shard.queue_free)


const RIBBON_LEFT := 128.0   # le bandeau d'annonce commence à droite de la vignette « Tour N »
const RIBBON_SIZES := [22, 20, 18]   # tailles essayées pour le bandeau d'annonce : deux lignes au plus
const RIBBON_LINES := 2


## Largeur laissée au bandeau d'annonce : de la marge gauche aux fiches de l'équipe.
static func ribbon_room(view_w: float) -> float:
	return view_w - (CARD_W + CARDS_RIGHT + 14.0) - RIBBON_LEFT - 24.0 - 52.0


## Taille de police du bandeau pour que « text » tienne sur RIBBON_LINES lignes dans « room » (la plus petite
## si aucune ne convient : voir le test des textes d'ouverture) et le nombre de lignes obtenu.
static func ribbon_fit(text: String, room: float) -> Array:
	var font := UI.font()
	var fs := int(RIBBON_SIZES[RIBBON_SIZES.size() - 1])
	var lines := 99
	for size_try: int in RIBBON_SIZES:
		fs = size_try
		lines = int(round(font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, room, fs).y / float(font.get_height(fs))))
		if lines <= RIBBON_LINES:
			break
	return [fs, lines]


## Triangle rouge qui palpite au-dessus de tout ennemi dont le gros coup tombe à son prochain tour
## (`next_skill` ou état « annonce »).
func _update_warn() -> void:
	for c: RefCounted in engine.enemies:
		var on: bool = c.alive() and (str(c.next_skill) != "" or c.has_status("annonce")) and not scene.fast
		var icon: TextureRect = _warn.get(c.key)
		if icon == null or not is_instance_valid(icon):
			if not on:
				continue
			icon = TextureRect.new()
			icon.texture = Sprites.icon("annonce")
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_SCALE
			icon.custom_minimum_size = Vector2(48.0, 48.0)
			icon.size = Vector2(48.0, 48.0)
			icon.pivot_offset = Vector2(24.0, 40.0)
			_overlay.add_child(icon)
			_warn[c.key] = icon
		icon.visible = on
		if on:
			var top: Vector2 = scene.screen_point(c, "top")
			var pulse := 1.0 + 0.14 * sin(_time * 7.0)
			icon.scale = Vector2(pulse, pulse)
			icon.position = Vector2(top.x - 24.0, maxf(top.y - 60.0, 178.0))


func announce(text: String, duration: float = 1.4) -> void:
	_ribbon_label.text = text
	# un texte long passe à la ligne (deux lignes au plus, quitte à réduire un peu la police) plutôt que de
	# déborder sous les fiches de l'équipe
	var view := size if size.x > 0.0 else Vector2(1280, 720)
	var room := ribbon_room(view.x)
	var fit := ribbon_fit(text, room)
	_ribbon_label.add_theme_font_size_override("font_size", int(fit[0]))
	_ribbon_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_ribbon_label.custom_minimum_size = Vector2.ZERO
	var natural := _ribbon_label.get_minimum_size().x
	if natural > room:
		_ribbon_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_ribbon_label.custom_minimum_size = Vector2(room, 0.0)
	_ribbon.reset_size()
	if _ribbon_tween != null and _ribbon_tween.is_valid():
		_ribbon_tween.kill()
	_ribbon.modulate.a = 1.0
	_ribbon_tween = create_tween()
	_ribbon_tween.tween_interval(duration)
	_ribbon_tween.tween_property(_ribbon, "modulate:a", 0.0, 0.35)


func show_hint(text: String) -> void:
	_hint.visible = text != ""
	_hint_label.text = Tutorial.expand(text)   # {interact}, {cancel} : touches du clavier ou de la manette
	_hint.reset_size()


## Texte qui s'envole au-dessus d'un combattant (dégâts, soins, états).
## « lift » : de combien le texte est remonté au-dessus de « at » (chiffre, puis « Faiblesse ! » au-dessus).
## Un texte qui retomberait sur les fiches de l'équipe est descendu d'un même décalage pour toute sa pile.
func popup(at: Vector2, text: String, color: Color = Color.WHITE, size: int = 30, lift: float = 0.0) -> void:
	if scene == null or scene.fast:
		return
	at.y -= lift
	var panel := _party_panel.get_global_rect()
	if panel.size.x > 0.0 and at.x > panel.position.x - 40.0 and at.x < panel.end.x + 40.0:
		var stack_top := at.y + lift - 110.0   # le haut de la plus haute ligne d'une pile
		at.y += maxf(0.0, panel.end.y + 6.0 - stack_top)
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
		_keys.add_child(UI.hints([["ud", "choisir"], ["lr", "élan"], ["ok", "valider"]], 14))
	elif _state == S.LIST or _state == S.TARGET:
		_keys.add_child(UI.hints(UI.KEYS_MENU, 14))
	_keys.visible = _state in [S.ROOT, S.LIST, S.TARGET]


# ------------------------------------------------------------------- menus

## Demande son action au joueur. Renvoie {"type", "id", "target"}.
func ask_action(actor: RefCounted) -> Dictionary:
	_actor = actor
	_last_root = 0
	_elan_commit = 0
	_elan_focus = ""
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


## Rectangles d'écran que les menus ne doivent couvrir : combattants (celui qui joue à la place
## où il se tient), plaques des ennemis, fiches de l'équipe, bandeau du haut (frise, cartouche,
## conseil) et rappels de touches.
func _obstacles(view: Vector2) -> Array[Rect2]:
	var out: Array[Rect2] = []
	for c: RefCounted in engine.all():
		if c.side == "enemy" and not c.alive():
			continue
		out.append(scene.screen_rect(c, c == _actor).grow_individual(8.0, 8.0, 8.0, 14.0))   # marge : les chapeaux et les bras dépassent du cadre calculé
	for key: String in _plates:
		var root: Control = (_plates[key] as Dictionary)["root"]
		if root.visible:
			out.append(Rect2(root.position, root.size).grow(4.0))
	out.append(_party_panel.get_global_rect().grow(6.0))
	for r: Rect2 in scene.foreground_rects():   # le premier plan flou est dans les coins : le menu l'évite aussi
		out.append(r.grow(6.0))
	out.append(Rect2(0.0, 0.0, view.x, 172.0))
	if _hint.visible:
		out.append(_hint.get_global_rect().grow(6.0))
	out.append(Rect2(0.0, view.y - 56.0, 460.0, 56.0))
	out.append(Rect2(view.x * 0.5 - 260.0, view.y - 6.0, 520.0, 6.0))   # rien tout en bas au centre (le menu peut descendre jusque-là)
	return out


## Meilleure place pour un rectangle de cette taille : la plus proche de « prefer » parmi celles
## qui ne couvrent aucun obstacle ; s'il n'y en a pas, celle qui en couvre le moins.
static func free_spot(size: Vector2, prefer: Vector2, obstacles: Array[Rect2], view: Vector2) -> Vector2:
	var x_max := maxf(10.0, view.x - size.x - 10.0)
	var y_max := maxf(10.0, view.y - size.y - 14.0)
	var best := Vector2(clampf(prefer.x, 10.0, x_max), clampf(prefer.y, 10.0, y_max))
	var best_score := INF
	var coarse := 28.0
	var passes := 3
	var span_x := Vector2(10.0, x_max)
	var span_y := Vector2(10.0, y_max)
	var step := coarse
	for _p in passes:
		var y := span_y.x
		while y <= span_y.y + 0.01:
			var x := span_x.x
			while x <= span_x.y + 0.01:
				var r := Rect2(x, y, size.x, size.y)
				var area := 0.0
				for o: Rect2 in obstacles:
					if r.intersects(o):
						area += r.intersection(o).get_area()
				var score := area * 30.0 + Vector2(x, y).distance_to(prefer)
				if score < best_score:
					best_score = score
					best = Vector2(x, y)
				x = span_x.y if (x < span_x.y and x + step > span_x.y + 0.01) else x + step   # la dernière colonne et la dernière ligne comptent aussi
			y = span_y.y if (y < span_y.y and y + step > span_y.y + 0.01) else y + step
		# seconde passe : affinage autour du meilleur point
		span_x = Vector2(maxf(10.0, best.x - maxf(step, 7.0)), minf(x_max, best.x + maxf(step, 7.0)))
		span_y = Vector2(maxf(10.0, best.y - maxf(step, 7.0)), minf(y_max, best.y + maxf(step, 7.0)))
		step = 7.0 if step > 7.0 else 2.0
	return best


## Le menu s'ouvre près du personnage qui joue, mais jamais sur un autre combattant, une plaque,
## une fiche ou la frise : on cherche la place libre la plus proche (voir free_spot). La liste
## (compétences, objets) se range de même, de préférence en cascade sous le menu.
func _place_menu() -> void:
	if not _menu_box.visible or _actor == null or scene == null:
		return
	var view := size if size.x > 0.0 else Vector2(1280, 720)
	_root_panel.reset_size()
	_list_panel.reset_size()
	var obstacles := _obstacles(view)
	var sig := hash([_state, _list_panel.visible, Vector2i(_root_panel.size), Vector2i(_list_panel.size), Vector2i(view)])
	for o: Rect2 in obstacles:
		sig = hash([sig, int(o.position.x), int(o.position.y), int(o.size.x), int(o.size.y)])
	if sig != _menu_sig:
		_menu_sig = sig
		var c: Vector2 = scene.screen_point(_actor, "center")
		var rw := _root_panel.size.x
		var rh := _root_panel.size.y + 14.0   # marge : la ligne choisie s'ouvre sous son nom (une ou deux lignes d'aide)
		var stepped: Rect2 = scene.screen_rect(_actor, true)
		var bar0: Control = _elan_bars[0]["panel"]
		bar0.reset_size()
		var bar1: Control = _elan_bars[1]["panel"]
		bar1.reset_size()
		_root_pos = free_spot(Vector2(rw, rh), Vector2(stepped.position.x - 24.0 - rw, c.y - 96.0), obstacles, view)
		_bar_pos[0] = _bar_beside(bar0.size, Rect2(_root_pos, _root_panel.size), obstacles, view)
		if _list_panel.visible:
			var lw := _list_panel.size.x
			var lh := _list_panel.size.y
			_list_pos = free_spot(Vector2(lw, lh), Vector2(_root_pos.x - 40.0, _root_pos.y + 44.0), obstacles, view)
			_bar_pos[1] = _bar_beside(bar1.size, Rect2(_list_pos, _list_panel.size), obstacles, view)
	_root_panel.position = _root_pos
	if _list_panel.visible:
		_list_panel.position = _list_pos
	(_elan_bars[1 if _list_panel.visible else 0]["panel"] as Control).position = _bar_pos[1 if _list_panel.visible else 0]


## Place de la barre d'élan : collée au panneau qu'elle sert (dessous, puis dessus), à condition de ne
## rien couvrir ; sinon la place libre la plus proche (voir free_spot).
static func _bar_beside(size: Vector2, panel: Rect2, obstacles: Array[Rect2], view: Vector2) -> Vector2:
	obstacles = obstacles.slice(0, obstacles.size() - 2)   # la barre peut se glisser dans les réserves du bas (touches, centre)
	var below := Vector2(panel.position.x, panel.end.y + 4.0)
	var above := Vector2(panel.position.x, panel.position.y - size.y - 4.0)
	for spot: Vector2 in [below, above]:
		var r := Rect2(spot, size)
		if r.position.x < 6.0 or r.position.y < 6.0 or r.end.x > view.x - 6.0 or r.end.y > view.y - 1.0:
			continue
		var clear := true
		for o: Rect2 in obstacles:
			if r.intersects(o):
				clear = false
				break
		if clear:
			return spot
	var obs2: Array[Rect2] = []
	obs2.append_array(obstacles)
	obs2.append(panel.grow(2.0))
	return free_spot(size, below, obs2, view)


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
	(_elan_bars[0]["panel"] as Control).visible = true
	(_elan_bars[1]["panel"] as Control).visible = false
	_root_title.text = str(_actor.name)
	_clear(_root_list)
	var entries := [
		["Attaquer", true],
		["Compétences", not (_actor.skills as Array).is_empty()],
		["Objets", _has_usable_item()],
		["Défendre", true],
		["Fuir", bool(engine.can_flee)],
	]
	var kinds := ["attack", "skills", "items", "defend", "flee"]
	for i in entries.size():
		var e: Array = entries[i]
		var b := UI.icon_band_button(str(e[0]), 21, str(ROOT_HELP.get(str(e[0]), "")), "", 244, Sprites.icon(str(kinds[i])), _weapon_icon(_actor) if i == 0 else null)
		b.disabled = not bool(e[1])
		b.pressed.connect(_on_root.bind(i))
		_root_list.add_child(b)
	_set_root_live(true)
	_focus(_root_list, _last_root)
	_update_keys()
	_update_elan_bars()
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
	(_elan_bars[0]["panel"] as Control).visible = false   # la liste a sa propre barre d'élan
	(_elan_bars[1]["panel"] as Control).visible = true
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
		var warn := false
		var icon_kind := "items"
		if kind == "skill":
			right = "%d PM" % int(def.get("cost", 0))
			usable = engine.can_use_skill(_actor, id)
			warn = int(def.get("cost", 0)) > int(_actor.mp)   # trop cher : le coût vire à l'orange, la ligne est grisée
			var el := str(def.get("element", ""))
			icon_kind = el if IconPainter.kinds().has(el) else "skills"
		else:
			right = "×%d" % int(engine.inventory.get(id, 0))
		if (engine.candidates(_actor, str(def.get("target", "enemy"))) as Array).is_empty():
			usable = false
		var b := UI.icon_band_button(text, 21, str(def.get("desc", "")), right, 400, Sprites.icon(icon_kind), null, warn)
		b.disabled = not usable
		b.focus_entered.connect(_on_list_focus.bind(id))
		b.pressed.connect(_on_list.bind(kind, id, str(def.get("target", "enemy"))))
		_list_items.add_child(b)
		if str(_last_list.get(kind, "")) == id:
			focus_index = i
	_elan_focus = str(ids[focus_index]) if not ids.is_empty() else ""
	_focus(_list_items, focus_index)
	_update_keys()
	_update_elan_bars()
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
	if _elan_commit > 0 and str(action.get("type", "")) in ["attack", "skill"]:
		action["elan"] = _elan_commit
	_elan_commit = 0
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
	_layout_plates()
	_update_warn()
	if _state == S.ROOT or _state == S.LIST:   # la main du menu va et vient : on redessine l'entrée choisie
		for box: Control in [_root_list, _list_items]:
			for b in box.get_children():
				if (b as Button).has_focus():
					(b as Button).queue_redraw()
	if _state == S.TARGET:
		var panel := _party_panel.get_global_rect()
		for i in _cands.size():
			if i >= _cursors.size() or not _cursors[i].visible:
				continue
			var p: Vector2 = scene.screen_point(_cands[i], "top") + Vector2(0.0, -34.0)
			# le curseur ne se cache jamais derrière les fiches : il descend sous elles
			if p.x > panel.position.x - 20.0 and p.y - 22.0 < panel.end.y + 4.0:
				p.y = panel.end.y + 28.0
			_cursors[i].position = p + Vector2(0.0, sin(_time * 7.0) * 4.0 + 6.0)
	_place_menu()


## Plaques des ennemis : chacune sous les pieds de son ennemi, puis écartées jusqu'à ne plus se
## toucher ni toucher un autre ennemi (on pousse sur l'axe où le recouvrement est le plus faible).
func _layout_plates() -> void:
	var view := size if size.x > 0.0 else Vector2(1280, 720)
	var keys: Array = []
	var rects: Dictionary = {}
	var own: Dictionary = {}
	for c: RefCounted in engine.enemies:
		var plate: Dictionary = _plates.get(c.key, {})
		if plate.is_empty() or not (plate["root"] as Control).visible:
			continue
		var root: Control = plate["root"]
		var body: Rect2 = scene.screen_rect(c)   # sous le sprite visible (un volant a sa plaque sous lui, pas sous son ombre)
		rects[c.key] = Rect2((Vector2(body.get_center().x - root.size.x * 0.5, body.end.y + 8.0)).round(), root.size)
		own[c.key] = body
		keys.append(c.key)
	# les ennemis les plus proches de la caméra choisissent d'abord ; chaque plaque prend la place libre la plus
	# proche de son point d'attache (sous les pieds) : ni sur une plaque déjà posée, ni sur un sprite, ni sous le
	# bandeau des rappels de touches (recherche refaite seulement quand les entrées changent)
	var isig := hash([keys, rects.values(), own.values(), view])
	if isig != _plate_in_sig:
		_plate_in_sig = isig
		_plate_spots = _spread_plates(keys, rects, own, view)
	for k: String in keys:
		if _plate_spots.has(k):
			rects[k] = _plate_spots[k]
	var placed: Array[Rect2] = []
	var pairs: Array = []
	for k: String in keys:
		((_plates[k] as Dictionary)["root"] as Control).position = (rects[k] as Rect2).position.round()
		var pr := Rect2((rects[k] as Rect2).position.round(), (rects[k] as Rect2).size)
		placed.append(pr)
		var body: Rect2 = own[k]
		var foot := Vector2(body.get_center().x, body.end.y + 2.0)
		if absf(pr.get_center().x - foot.x) > 40.0 or pr.position.y - foot.y > 26.0:   # plaque écartée : un trait la relie à son ennemi
			pairs.append([foot, Vector2(clampf(foot.x, pr.position.x + 10.0, pr.end.x - 10.0), pr.position.y + 1.0)])
	if pairs != _link_pairs:
		_link_pairs = pairs
		if _plate_links != null:
			_plate_links.queue_redraw()
	# le premier plan flou se range autour des plaques, jamais dessus (refait quand elles bougent)
	var sig := hash(placed.map(func(r: Rect2) -> Vector2i: return Vector2i(r.position)))
	if sig != _plate_sig:
		_plate_sig = sig
		scene.refit_foreground(placed)


## Trait fin entre les pieds d'un ennemi et sa plaque quand elle n'est pas juste dessous.
func _draw_plate_links() -> void:
	for pair: Array in _link_pairs:
		var a: Vector2 = pair[0]
		var b: Vector2 = pair[1]
		_plate_links.draw_line(a, b, Color(0.04, 0.03, 0.07, 0.8), 4.0, true)
		_plate_links.draw_line(a, b, Color(0.92, 0.88, 0.78, 0.85), 1.5, true)
		_plate_links.draw_circle(a, 3.0, Color(0.92, 0.88, 0.78, 0.9))


## Plaques en rangée : sans boss, les plaques de tous les ennemis se posent sur une même ligne sous le plus bas des
## pieds, dans l'ordre de gauche à droite de leurs ennemis (au plus près de chacun, jamais à moins de PLATE_MARGIN d'un
## bord). Renvoie {} si la rangée ne tient pas (trop large, trop basse, sur une pose d'un héros) : on cherche alors
## plaque par plaque (_spread_plates).
func _plates_in_row(keys: Array, rects: Dictionary, own: Dictionary, view: Vector2) -> Dictionary:
	var order: Array = keys.duplicate()
	order.sort_custom(func(a: String, b: String) -> bool: return (own[a] as Rect2).get_center().x < (own[b] as Rect2).get_center().x)
	var y := 0.0
	var y_min := INF
	var h := 0.0
	for k: String in order:
		y = maxf(y, (own[k] as Rect2).end.y + 8.0)
		y_min = minf(y_min, (own[k] as Rect2).end.y + 8.0)
		h = maxf(h, (rects[k] as Rect2).size.y)
	if y - y_min > 60.0:
		return {}   # des ennemis étagés en profondeur : une rangée ferait des traits de rappel longs et obliques
	if y + h > view.y - PLATE_MARGIN:
		return {}
	var gap := 16.0
	var xs: Array[float] = []
	var prev_end := PLATE_MARGIN - gap
	for k: String in order:
		var r: Rect2 = rects[k]
		var x := maxf((own[k] as Rect2).get_center().x - r.size.x * 0.5, prev_end + gap)
		xs.append(x)
		prev_end = x + r.size.x
	var next_x := view.x - PLATE_MARGIN + gap   # (passe arrière : ce qui dépasse à droite se décale vers la gauche)
	for i in range(order.size() - 1, -1, -1):
		var w: float = (rects[order[i]] as Rect2).size.x
		xs[i] = minf(xs[i], next_x - gap - w)
		next_x = xs[i]
	if xs[0] < PLATE_MARGIN - 0.5:
		return {}
	var out: Dictionary = {}
	var zone: Rect2 = scene.keys_band(view)
	for i in order.size():
		var r := Rect2(Vector2(xs[i], y), (rects[order[i]] as Rect2).size)
		if r.intersects(zone):
			return {}
		for hh: RefCounted in engine.party:
			if r.intersects(scene._play_rect(hh)):
				return {}
		out[order[i]] = r
	return out


## Place les plaques des ennemis (voir _layout_plates) : recherche sur une grille de la place libre la plus proche.
func _spread_plates(keys: Array, rects: Dictionary, own: Dictionary, view: Vector2) -> Dictionary:
	if scene.boss == null and keys.size() >= 2 and keys.size() <= 4:
		var row := _plates_in_row(keys, rects, own, view)
		if not row.is_empty():
			return row
	var order: Array = keys.duplicate()
	order.sort_custom(func(a: String, b: String) -> bool: return (own[a] as Rect2).end.y > (own[b] as Rect2).end.y)
	var heroes: Array[Rect2] = []
	for h: RefCounted in engine.party:
		heroes.append(scene.screen_rect(h))
	var keys_zone: Rect2 = scene.keys_band(view)
	var out: Dictionary = {}
	var taken: Array[Rect2] = []
	for k: String in order:
		var base: Rect2 = rects[k]
		var best := base
		var best_cost := INF
		for dy in range(-30, 170, 6):
			for dx in range(-380, 381, 10):
				var r := Rect2(base.position + Vector2(dx, dy), base.size)
				var cost := float(dx * dx) * 0.6 + float(dy * dy) * (0.5 if dy < 0 else 1.0)
				if cost >= best_cost:
					continue
				if r.position.x < PLATE_MARGIN or r.end.x > view.x - PLATE_MARGIN or r.position.y < PLATE_MARGIN or r.end.y > view.y - PLATE_MARGIN or r.intersects(keys_zone):
					continue
				var bad := false
				for t: Rect2 in taken:
					if r.grow(10.0).intersects(t):   # le contour du nom ajoute 2 px de chaque côté : deux noms jumeaux ne se touchent jamais
						bad = true
						break
				if bad:
					continue
				for o: String in keys:
					var orect: Rect2 = own[o]
					if minf(orect.size.x, orect.size.y) > 8.0:
						orect = orect.grow(-4.0)   # (un sprite minuscule garde sa taille : pas de rectangle négatif)
					if o != k and r.intersects(orect):
						bad = true
						break
				if bad:
					continue
				for hr: Rect2 in heroes:
					if r.intersects(hr):
						bad = true
						break
				if bad:
					continue
				best = r
				best_cost = cost
		best.position.x = clampf(best.position.x, PLATE_MARGIN, maxf(PLATE_MARGIN, view.x - best.size.x - PLATE_MARGIN))
		best.position.y = clampf(best.position.y, PLATE_MARGIN, maxf(PLATE_MARGIN, view.y - best.size.y - PLATE_MARGIN))
		out[k] = best
		taken.append(best)
	return out


func _input(event: InputEvent) -> void:
	if not visible or scene == null:
		return
	if (_state == S.ROOT or _state == S.LIST) and _actor != null and engine != null:
		var d := 0
		if event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
			d = -1
		elif event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
			d = 1
		if d != 0:
			get_viewport().set_input_as_handled()
			_set_commit(_elan_commit + d)
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
	for k: String in _plates:   # les plaques des ennemis ne transparaissent pas sous l'écran de fin
		((_plates[k] as Dictionary)["root"] as Control).visible = false
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


## Une ligne de récompense : icône peinte, puis texte.
func _reward_line(box: Control, kind: String, text: String, color: Color = UI.INK, size: int = 24) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var ic := TextureRect.new()
	ic.texture = Sprites.icon(kind)
	ic.custom_minimum_size = Vector2(24, 24)
	ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(ic)
	row.add_child(UI.label(text, size, color))
	box.add_child(row)


func show_victory(rewards: Dictionary, guest: bool) -> void:
	var box := _end_panel("Victoire", UI.GOLD)
	if guest:
		_line(box, "L'ennemi est à terre.")
	else:
		var totals := HBoxContainer.new()   # le butin d'un coup d'oeil : expérience et écus côte à côte
		totals.alignment = BoxContainer.ALIGNMENT_CENTER
		totals.add_theme_constant_override("separation", 40)
		box.add_child(totals)
		_reward_line(totals, "up", "Expérience +%d" % int(rewards.get("xp", 0)), UI.GOLD, 26)
		if int(rewards.get("money", 0)) > 0:
			_reward_line(totals, "coin", "Écus +%d" % int(rewards["money"]), Color("#ffd27a"), 26)
		var drops: Dictionary = rewards.get("drops", {})
		for id: String in drops:
			_reward_line(box, "items", "Trouvé : %s ×%d" % [str(Database.get_item(id).get("name", id)), int(drops[id])], Color("#bfe8ff"), 21)
		var ups: Array = rewards.get("levelups", [])
		var by_id: Dictionary = {}
		for up: Dictionary in ups:
			by_id[str(up.get("id", ""))] = up
		var gains: Dictionary = rewards.get("gains", {})
		if engine != null and not gains.is_empty():   # une ligne par héros : portrait, expérience, niveau gagné
			for c: RefCounted in engine.party:
				var gain := int(gains.get(str(c.source), 0))
				var row := HBoxContainer.new()
				row.alignment = BoxContainer.ALIGNMENT_CENTER
				row.add_theme_constant_override("separation", 12)
				row.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
				var face := TextureRect.new()
				face.texture = Sprites.battler_icon(c.sprite)
				face.custom_minimum_size = Vector2(40, 40)
				face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				row.add_child(face)
				var who := UI.label(str(c.name), 20, UI.INK)
				who.custom_minimum_size = Vector2(170, 0)
				row.add_child(who)
				var xp_label := UI.label("+%d XP" % gain, 20, Color("#ffd27a"))
				xp_label.custom_minimum_size = Vector2(110, 0)
				row.add_child(xp_label)
				if by_id.has(str(c.source)):
					var up: Dictionary = by_id[str(c.source)]
					row.add_child(UI.label("Niveau %d" % int(up.get("to", 1)), 20, UI.GOLD))
				box.add_child(row)
		if not ups.is_empty():
			Sfx.play("level")
		for up: Dictionary in ups:
			if engine == null or gains.is_empty():
				_reward_line(box, "up", "%s passe au niveau %d !" % [str(up.get("name", "")), int(up.get("to", 1))], UI.GOLD, 24)
			var bits: Array = []
			for sk: Variant in up.get("skills", []):
				bits.append("apprend %s" % str(sk))
			var points := int(up.get("points", 0))
			if points > 0:
				bits.append("+%d point%s de talent" % [points, "s" if points > 1 else ""])
			if not bits.is_empty():
				_line(box, "%s %s" % [str(up.get("name", "")), " · ".join(bits)], Color("#ffd27a"), 19)
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
	if load_btn.disabled:
		load_btn.focus_mode = Control.FOCUS_NONE   # une ligne grisée ne reçoit pas le curseur
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
		(load_btn if load_btn.focus_mode != Control.FOCUS_NONE else retry).grab_focus.call_deferred()
	_end_layer.visible = false
	return value
