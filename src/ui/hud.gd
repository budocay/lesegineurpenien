extends Control
## Éléments d'interface en jeu : invite d'interaction, titre de lieu, messages brefs.

const UI = preload("res://src/ui/ui_kit.gd")

const BANNER_TOP := 46.0

var _prompt: PanelContainer
var _prompt_label: Label
var _banner: Control          # voile + titre : tout le titre de lieu, qui s'estompe d'un bloc
var _banner_row: HBoxContainer
var _banner_title: Label
var _banner_sub: Label
var _toast: PanelContainer
var _toast_label: Label
var _banner_tween: Tween
var _toast_tween: Tween
var _soft: PanelContainer
var _soft_label: Label


func _ready() -> void:
	UI.full_rect(self)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# titre de lieu : voile sombre dégradé en haut, grand nom centré entre deux filets, sous-titre
	_banner = Control.new()
	_banner.anchor_right = 1.0
	_banner.offset_bottom = 190.0
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.modulate.a = 0.0
	add_child(_banner)
	var veil := UI.veil(true, 0.42)
	UI.full_rect(veil)
	_banner.add_child(veil)
	var margin := MarginContainer.new()   # le titre ne s'étale jamais jusqu'aux bords
	margin.anchor_right = 1.0
	margin.offset_top = BANNER_TOP
	margin.add_theme_constant_override("margin_left", 170)
	margin.add_theme_constant_override("margin_right", 170)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 2)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(col)
	_banner_row = HBoxContainer.new()
	_banner_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_banner_row.add_theme_constant_override("separation", 22)
	_banner_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(_banner_row)
	_banner_row.add_child(UI.rule(150.0, "in"))
	_banner_title = UI.label("", 54, UI.INK)
	_banner_title.add_theme_constant_override("shadow_offset_y", 2)
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_row.add_child(_banner_title)
	_banner_row.add_child(UI.rule(150.0, "out"))
	_banner_sub = UI.caps("", 17, UI.GOLD)
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_banner_sub)

	# invite d'interaction : une petite touche et son verbe
	_prompt = PanelContainer.new()
	var ps := UI.panel_style(Color(0.03, 0.035, 0.08, 0.86), UI.GOLD_LINE, 11, 1)
	ps.content_margin_left = 8
	ps.content_margin_right = 14
	ps.content_margin_top = 3
	ps.content_margin_bottom = 4
	_prompt.add_theme_stylebox_override("panel", ps)
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.visible = false
	add_child(_prompt)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.add_child(row)
	var cap := PanelContainer.new()
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(UI.GOLD, 0.16)
	cs.border_color = UI.GOLD
	cs.set_border_width_all(1)
	cs.set_corner_radius_all(3)
	cs.content_margin_left = 7
	cs.content_margin_right = 7
	cs.content_margin_top = 0
	cs.content_margin_bottom = 1
	cap.add_theme_stylebox_override("panel", cs)
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var cap_label := UI.label("E", 16, UI.GOLD, true)
	cap.add_child(cap_label)
	row.add_child(cap)
	var pad_cap := UI.pad_glyph("A", 16)
	pad_cap.visible = false
	row.add_child(pad_cap)
	var show_device := func(pad: bool) -> void:   # « E » au clavier, pastille A à la manette
		cap.visible = not pad
		pad_cap.visible = pad
	UI.follow_device(row, show_device)
	_prompt_label = UI.label("", 18)
	row.add_child(_prompt_label)

	# messages brefs (objet reçu, quête) : en haut à droite, filet doré à gauche
	_toast = PanelContainer.new()
	var ts := UI.soft_style(0.85, 22)
	_toast.add_theme_stylebox_override("panel", ts)
	_toast.position = Vector2(0, 14)
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	add_child(_toast)
	_toast_label = UI.label("", 19, UI.GOLD)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_toast.add_child(_toast_label)

	# témoin du Ramollissement, en haut à gauche, sur les cartes touchées
	_soft = PanelContainer.new()
	var ss := UI.panel_style(Color(0.03, 0.035, 0.08, 0.78), Color(0.85, 0.6, 0.6, 0.55), 10, 1)
	ss.content_margin_left = 12
	ss.content_margin_right = 14
	ss.content_margin_top = 2
	ss.content_margin_bottom = 3
	_soft.add_theme_stylebox_override("panel", ss)
	_soft.position = Vector2(28, 24)
	_soft.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_soft.visible = false
	add_child(_soft)
	_soft_label = UI.label("", 16, Color("#f0c4c4"))
	_soft.add_child(_soft_label)
	add_child(preload("res://src/ui/objective_tracker.gd").new())   # rappel de la quête en cours


## Zone occupée par le titre de lieu (vide s'il est effacé).
func _banner_rect() -> Rect2:
	if _banner.modulate.a < 0.05:
		return Rect2()
	# zone réellement occupée : du premier filet au dernier, et le sous-titre
	var first := _banner_row.get_child(0) as Control
	var last := _banner_row.get_child(_banner_row.get_child_count() - 1) as Control
	var r := first.get_global_rect().merge(last.get_global_rect())
	if _banner_sub.visible:
		r = r.merge(_banner_sub.get_global_rect())
	return r.grow(10.0)


func show_prompt(text: String, screen_pos: Vector2) -> void:
	if _prompt_label.text != text:
		_prompt_label.text = text
		_prompt.reset_size()
	_prompt.visible = true
	var pos := (screen_pos - Vector2(_prompt.size.x * 0.5, _prompt.size.y)).round()
	# la bulle ne chevauche jamais le titre de lieu : elle passe dessous
	var occupied := _banner_rect()
	if occupied.size != Vector2.ZERO and Rect2(pos, _prompt.size).intersects(occupied):
		pos.y = occupied.end.y + 4.0
	_prompt.position = pos


func hide_prompt() -> void:
	_prompt.visible = false


func banner(title: String, subtitle: String = "") -> void:
	_banner_title.text = title
	# un nom long rapetisse plutôt que de déborder
	var avail := maxf(size.x, 1280.0) - 340.0 - 300.0 - 44.0
	var fs := 54
	while fs > 30 and UI.font().get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > avail:
		fs -= 2
	_banner_title.add_theme_font_size_override("font_size", fs)
	_banner_sub.text = subtitle.to_upper()
	_banner_sub.visible = subtitle != ""
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_interval(0.3)
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.8)
	_banner_tween.tween_interval(2.4)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 1.0)


func toast(text: String) -> void:
	if _toast.modulate.a > 0.5 and _toast_label.text != "" and _toast_label.text != text:
		text = _toast_label.text + "\n" + text   # deux messages coup sur coup : on les empile
	_toast_label.text = text
	_toast.reset_size()
	_place_toast()
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.25)
	_toast_tween.tween_interval(2.2)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


## Toujours calé contre le bord droit, et jamais sur le titre de lieu.
func _place_toast() -> void:
	var pos := Vector2(size.x - _toast.size.x - 6.0, 10.0)
	var occupied := _banner_rect()
	if occupied.size != Vector2.ZERO and Rect2(pos, _toast.size).intersects(occupied):
		pos.y = occupied.end.y + 4.0
	_toast.position = pos


func _process(_delta: float) -> void:
	if _toast.modulate.a > 0.01:
		_place_toast()


## Affiche (ou cache, à 0) la force du Ramollissement du lieu.
func set_softness(level: float) -> void:
	_soft.visible = level > 0.0
	if level <= 0.0:
		return
	var word := "léger"
	if level >= 0.35:
		word = "profond"
	elif level >= 0.2:
		word = "marqué"
	_soft_label.text = "Ramollissement %s  ·  coups physiques −%d %%" % [word, int(round(level * 100.0))]
	_soft.reset_size()


func clear() -> void:
	hide_prompt()
	_soft.visible = false
	_banner.modulate.a = 0.0
	_toast.modulate.a = 0.0
