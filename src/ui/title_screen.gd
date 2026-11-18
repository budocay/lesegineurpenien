extends Control
## Écran-titre, affiché par-dessus le village filmé en travelling.
## Le menu se construit depuis une liste : `add_entry` y ajoute une ligne (par exemple
## « Paramètres », plus tard) sans rien refaire.

signal new_game_requested
signal continue_requested
signal load_requested
signal quit_requested

const UI = preload("res://src/ui/ui_kit.gd")

var _menu: VBoxContainer
var _new: Button
var _continue: Button
var _load: Button
var _quit: Button
var _save_info: Label
var _remember: Button = null    # dernière ligne choisie : on y revient après un sous-écran


func _ready() -> void:
	UI.full_rect(self)
	visible = false

	# voile sombre à gauche pour la lisibilité, plus un léger assombrissement en bas
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	grad.colors = PackedColorArray([Color(0.02, 0.02, 0.06, 0.88), Color(0.02, 0.02, 0.06, 0.5), Color(0.02, 0.02, 0.06, 0.0)])
	var gtex := GradientTexture2D.new()
	gtex.gradient = grad
	gtex.width = 256
	gtex.height = 4
	var veil := TextureRect.new()
	veil.texture = gtex
	veil.stretch_mode = TextureRect.STRETCH_SCALE
	veil.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	veil.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	UI.full_rect(veil)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)
	var foot_veil := UI.veil(false, 0.6)
	foot_veil.anchor_right = 1.0
	foot_veil.anchor_top = 1.0
	foot_veil.anchor_bottom = 1.0
	foot_veil.offset_top = -140.0
	add_child(foot_veil)

	var box := VBoxContainer.new()
	box.anchor_top = 0.0
	box.anchor_bottom = 1.0
	box.offset_left = 96.0
	box.offset_right = 780.0
	box.offset_top = 76.0
	box.offset_bottom = -52.0
	box.add_theme_constant_override("separation", 0)
	add_child(box)

	box.add_child(UI.caps("Une épopée de la Terre du Mi-Lieu", 15, UI.GOLD_DIM))
	var title := UI.label("Glandoulf le Gris", 84, UI.GOLD)
	title.add_theme_constant_override("shadow_offset_y", 3)
	title.add_theme_constant_override("outline_size", 5)
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.1, 0.85))
	box.add_child(title)
	var sub := UI.label("et l'Anneau pénien de Sauron", 31, UI.INK, false, true)
	box.add_child(sub)
	var rule_gap := Control.new()
	rule_gap.custom_minimum_size = Vector2(0, 16)
	box.add_child(rule_gap)
	var rule := UI.rule(520.0, "out")
	rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(rule)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(spacer)

	_menu = VBoxContainer.new()
	_menu.add_theme_constant_override("separation", 2)
	box.add_child(_menu)
	_new = add_entry("Nouvelle partie", _on_new, false)
	_continue = add_entry("Continuer", func() -> void: continue_requested.emit(), false)
	_save_info = UI.label("", 16, UI.INK_DIM, false, true)
	var info_row := MarginContainer.new()
	info_row.add_theme_constant_override("margin_left", 32)
	info_row.add_theme_constant_override("margin_bottom", 4)
	info_row.add_child(_save_info)
	_menu.add_child(info_row)
	_load = add_entry("Charger", func() -> void: load_requested.emit(), false)
	_quit = add_entry("Quitter", func() -> void: quit_requested.emit(), false)

	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 30)
	box.add_child(gap)
	box.add_child(UI.hints([["Flèches ou ZQSD", "se déplacer"], ["E ou Entrée", "parler, valider"], ["Échap", "menu"], ["F", "plein écran"]], 15))


## Ajoute une ligne au menu (avant « Quitter » par défaut) et la renvoie.
func add_entry(text: String, action: Callable, before_quit: bool = true) -> Button:
	var b := UI.menu_button(text, 29)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.custom_minimum_size = Vector2(300, 0)
	b.pressed.connect(func() -> void:
		_remember = b
		Sfx.play("confirm")
		action.call())
	_menu.add_child(b)
	if before_quit and _quit != null:
		_menu.move_child(b, _quit.get_index())
	return b


func open() -> void:
	visible = true
	var has_save := SaveManager.has_save()
	_continue.disabled = not has_save
	_continue.focus_mode = Control.FOCUS_ALL if has_save else Control.FOCUS_NONE
	_load.disabled = not has_save
	_load.focus_mode = Control.FOCUS_ALL if has_save else Control.FOCUS_NONE
	_save_info.text = SaveManager.summary() if has_save else "Aucune sauvegarde"
	if _remember != null and is_instance_valid(_remember) and not _remember.disabled:
		_remember.grab_focus()
	elif has_save:
		_continue.grab_focus()
	else:
		_new.grab_focus()
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.3)


func close() -> void:
	visible = false


func _on_new() -> void:
	_remember = null
	new_game_requested.emit()
