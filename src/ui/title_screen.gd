extends Control
## Écran-titre, affiché par-dessus le village filmé en travelling.

signal new_game_requested
signal continue_requested
signal load_requested
signal quit_requested

const UI = preload("res://src/ui/ui_kit.gd")

var _new: Button
var _continue: Button
var _load: Button
var _save_info: Label


func _ready() -> void:
	UI.full_rect(self)
	visible = false

	# voile sombre à gauche pour la lisibilité
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	grad.colors = PackedColorArray([Color(0.03, 0.02, 0.08, 0.86), Color(0.03, 0.02, 0.08, 0.5), Color(0.03, 0.02, 0.08, 0.0)])
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.width = 256
	gtex.height = 4
	var veil := TextureRect.new()
	veil.texture = gtex
	veil.stretch_mode = TextureRect.STRETCH_SCALE
	veil.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	UI.full_rect(veil)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var box := VBoxContainer.new()
	box.anchor_top = 0.0
	box.anchor_bottom = 1.0
	box.offset_left = 90.0
	box.offset_right = 760.0
	box.offset_top = 70.0
	box.offset_bottom = -60.0
	box.add_theme_constant_override("separation", 0)
	add_child(box)

	var over := UI.label("UNE ÉPOPÉE DE LA TERRE DU MI-LIEU", 17, UI.GOLD_DIM)
	box.add_child(over)
	var title := UI.label("Glandoulf le Gris", 86, UI.GOLD, false, false)
	title.add_theme_constant_override("shadow_offset_y", 4)
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.12, 0.9))
	box.add_child(title)
	var sub := UI.label("et l'Anneau pénien de Sauron", 34, UI.INK, false, true)
	box.add_child(sub)
	var rule := ColorRect.new()
	rule.color = UI.GOLD
	rule.custom_minimum_size = Vector2(420, 2)
	rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var rule_gap := Control.new()
	rule_gap.custom_minimum_size = Vector2(0, 14)
	box.add_child(rule_gap)
	box.add_child(rule)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	_new = UI.menu_button("Nouvelle partie", 30)
	_new.pressed.connect(_on_new)
	_new.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(_new)
	_continue = UI.menu_button("Continuer", 30)
	_continue.pressed.connect(func() -> void:
		Sfx.play("confirm")
		continue_requested.emit())
	_continue.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(_continue)
	_save_info = UI.label("", 17, UI.INK_DIM, false, true)
	var info_row := MarginContainer.new()
	info_row.add_theme_constant_override("margin_left", 22)
	info_row.add_child(_save_info)
	box.add_child(info_row)
	_load = UI.menu_button("Charger", 30)
	_load.pressed.connect(func() -> void:
		Sfx.play("confirm")
		load_requested.emit())
	_load.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(_load)
	var quit := UI.menu_button("Quitter", 30)
	quit.pressed.connect(func() -> void: quit_requested.emit())
	quit.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(quit)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 34)
	box.add_child(gap)
	box.add_child(UI.label("Flèches ou ZQSD : se déplacer   ·   E ou Entrée : parler, valider   ·   Échap : menu   ·   F : plein écran", 16, UI.INK_DIM))


func open() -> void:
	visible = true
	var has_save := SaveManager.has_save()
	_continue.disabled = not has_save
	_continue.focus_mode = Control.FOCUS_ALL if has_save else Control.FOCUS_NONE
	_load.disabled = not has_save
	_load.focus_mode = Control.FOCUS_ALL if has_save else Control.FOCUS_NONE
	_save_info.text = SaveManager.summary() if has_save else "Aucune sauvegarde"
	if has_save:
		_continue.grab_focus()
	else:
		_new.grab_focus()


func close() -> void:
	visible = false


func _on_new() -> void:
	Sfx.play("confirm")
	new_game_requested.emit()
