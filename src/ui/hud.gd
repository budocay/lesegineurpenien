extends Control
## Éléments d'interface en jeu : invite d'interaction, bandeau de lieu, messages brefs.

const UI = preload("res://src/ui/ui_kit.gd")

var _prompt: PanelContainer
var _prompt_label: Label
var _banner: VBoxContainer
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

	_prompt = PanelContainer.new()
	var ps := UI.panel_style(UI.NIGHT, UI.GOLD, 12, 1)
	ps.content_margin_left = 12
	ps.content_margin_right = 14
	ps.content_margin_top = 3
	ps.content_margin_bottom = 4
	_prompt.add_theme_stylebox_override("panel", ps)
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prompt.visible = false
	add_child(_prompt)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	_prompt.add_child(row)
	row.add_child(UI.label("E", 18, UI.GOLD, true))
	_prompt_label = UI.label("", 18)
	row.add_child(_prompt_label)

	_banner = VBoxContainer.new()
	_banner.anchor_left = 0.0
	_banner.anchor_right = 1.0
	_banner.offset_top = 46.0
	_banner.alignment = BoxContainer.ALIGNMENT_CENTER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.modulate.a = 0.0
	add_child(_banner)
	_banner_title = UI.label("", 46, UI.INK, false, true)
	_banner_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_title)
	var rule := ColorRect.new()
	rule.color = UI.GOLD
	rule.custom_minimum_size = Vector2(260, 2)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.add_child(rule)
	_banner_sub = UI.label("", 20, UI.GOLD)
	_banner_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_child(_banner_sub)

	_toast = PanelContainer.new()
	_toast.add_theme_stylebox_override("panel", UI.panel_style())
	_toast.anchor_left = 1.0
	_toast.anchor_right = 1.0
	_toast.offset_top = 24.0
	_toast.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_toast.offset_right = -24.0
	_toast.offset_left = -24.0
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.modulate.a = 0.0
	add_child(_toast)
	_toast_label = UI.label("", 19, UI.GOLD)
	_toast.add_child(_toast_label)

	# Témoin du Ramollissement, en haut à gauche, sur les cartes touchées.
	_soft = PanelContainer.new()
	var ss := UI.panel_style(UI.NIGHT, Color("#d89a9a"), 12, 1)
	ss.content_margin_left = 12
	ss.content_margin_right = 14
	ss.content_margin_top = 3
	ss.content_margin_bottom = 4
	_soft.add_theme_stylebox_override("panel", ss)
	_soft.position = Vector2(24, 24)
	_soft.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_soft.visible = false
	add_child(_soft)
	_soft_label = UI.label("", 17, Color("#f0c4c4"))
	_soft.add_child(_soft_label)


func show_prompt(text: String, screen_pos: Vector2) -> void:
	if _prompt_label.text != text:
		_prompt_label.text = text
		_prompt.reset_size()
	_prompt.visible = true
	_prompt.position = (screen_pos - Vector2(_prompt.size.x * 0.5, _prompt.size.y)).round()


func hide_prompt() -> void:
	_prompt.visible = false


func banner(title: String, subtitle: String = "") -> void:
	_banner_title.text = title
	_banner_sub.text = subtitle
	_banner_sub.visible = subtitle != ""
	if _banner_tween != null and _banner_tween.is_valid():
		_banner_tween.kill()
	_banner.modulate.a = 0.0
	_banner_tween = create_tween()
	_banner_tween.tween_interval(0.3)
	_banner_tween.tween_property(_banner, "modulate:a", 1.0, 0.7)
	_banner_tween.tween_interval(2.2)
	_banner_tween.tween_property(_banner, "modulate:a", 0.0, 1.0)


func toast(text: String) -> void:
	if _toast.modulate.a > 0.5 and _toast_label.text != "" and _toast_label.text != text:
		text = _toast_label.text + "\n" + text   # deux messages coup sur coup : on les empile
	_toast_label.text = text
	_toast.reset_size()
	if _toast_tween != null and _toast_tween.is_valid():
		_toast_tween.kill()
	_toast_tween = create_tween()
	_toast_tween.tween_property(_toast, "modulate:a", 1.0, 0.2)
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


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
