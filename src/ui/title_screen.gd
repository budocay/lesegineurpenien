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

	# L'Anneau, dessiné par code, à droite du titre ; il respire doucement.
	var ring := Control.new()
	ring.anchor_left = 1.0
	ring.anchor_right = 1.0
	ring.offset_left = -330.0
	ring.offset_right = -50.0
	ring.offset_top = 30.0
	ring.offset_bottom = 310.0
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ring.draw.connect(_draw_ring.bind(ring))
	add_child(ring)
	var breath := create_tween().set_loops()
	breath.tween_property(ring, "modulate:a", 0.78, 2.6).set_trans(Tween.TRANS_SINE)
	breath.tween_property(ring, "modulate:a", 1.0, 2.6).set_trans(Tween.TRANS_SINE)

	var box := VBoxContainer.new()
	box.anchor_top = 0.0
	box.anchor_bottom = 1.0
	box.anchor_right = 1.0
	box.offset_left = 96.0
	box.offset_right = -96.0
	box.offset_top = 56.0
	box.offset_bottom = -44.0
	box.add_theme_constant_override("separation", 0)
	add_child(box)

	box.add_child(UI.caps("Une épopée de la Terre du Mi-Lieu", 15, UI.GOLD_DIM))
	var tag_gap := Control.new()
	tag_gap.custom_minimum_size = Vector2(0, 8)
	box.add_child(tag_gap)
	# « Le Seigneur » petit, suivi d'un filet ; « des Anneaux Péniens » grand dessous
	var lord_row := HBoxContainer.new()
	lord_row.add_theme_constant_override("separation", 18)
	var lord := UI.label("Le Seigneur", 34, UI.GOLD_DIM, false, true)
	lord_row.add_child(lord)
	var lord_rule := UI.rule(0.0, "out", UI.GOLD_DIM)
	lord_rule.custom_minimum_size = Vector2(160, 9)
	lord_rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	lord_row.add_child(lord_rule)
	box.add_child(lord_row)
	var title := UI.label("des Anneaux Péniens", 88, UI.GOLD)
	title.add_theme_constant_override("shadow_offset_y", 4)
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("outline_size", 6)
	title.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.1, 0.85))
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	box.add_child(title)
	var sub_row := HBoxContainer.new()
	sub_row.add_theme_constant_override("separation", 16)
	var sub_rule := UI.rule(60.0, "in")
	sub_rule.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	sub_row.add_child(sub_rule)
	sub_row.add_child(UI.label("Glandoulf le Gris et la Communauté de l'Anneau", 28, UI.INK, false, true))
	box.add_child(sub_row)

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
	gap.custom_minimum_size = Vector2(0, 26)
	box.add_child(gap)
	box.add_child(UI.hints([["walk", "se déplacer"], ["talk", "parler, valider"], ["menu", "menu"], ["fullscreen", "plein écran"]], 15))


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


## Rend le curseur à la dernière ligne choisie, sans refaire l'apparition (retour d'une confirmation).
func refocus() -> void:
	if _remember != null and is_instance_valid(_remember) and not _remember.disabled:
		_remember.grab_focus()
	else:
		_new.grab_focus()


func close() -> void:
	visible = false


func _on_new() -> void:
	_remember = null
	new_game_requested.emit()


## L'Anneau : bande d'or épaisse, reflet, fines gravures, et un halo qui l'enveloppe.
func _draw_ring(c: Control) -> void:
	var ctr := c.size * 0.5
	var r := minf(c.size.x, c.size.y) * 0.30
	var w := r * 0.34
	for i in 16:
		c.draw_circle(ctr, r * (2.0 - 0.07 * float(i)), Color(1.0, 0.8, 0.42, 0.016))
	c.draw_arc(ctr + Vector2(0, 5), r, 0.0, TAU, 120, Color(0, 0, 0, 0.45), w + 8.0, true)    # ombre portée
	c.draw_arc(ctr, r, 0.0, TAU, 120, Color(0.2, 0.12, 0.04), w + 5.0, true)                  # liseré sombre
	c.draw_arc(ctr, r, 0.0, TAU, 120, Color(0.62, 0.45, 0.16), w, true)                       # or ombré
	c.draw_arc(ctr, r - w * 0.12, 0.0, TAU, 120, UI.GOLD_DIM, w * 0.62, true)
	c.draw_arc(ctr, r - w * 0.22, 0.0, TAU, 120, UI.GOLD, w * 0.30, true)
	c.draw_arc(ctr, r - w * 0.28, deg_to_rad(205.0), deg_to_rad(300.0), 40, Color(1.0, 0.97, 0.85, 0.9), w * 0.12, true)   # reflet
	c.draw_arc(ctr, r + w * 0.36, deg_to_rad(20.0), deg_to_rad(110.0), 40, Color(0.35, 0.22, 0.07, 0.8), w * 0.14, true)  # ombre basse
	for i in 36:       # gravures : de petits traits sur la bande
		var a := TAU * float(i) / 36.0 + 0.05
		var dir := Vector2(cos(a), sin(a))
		var len := w * (0.22 if i % 3 != 0 else 0.34)
		c.draw_line(ctr + dir * (r - len * 0.5), ctr + dir * (r + len * 0.5), Color(0.25, 0.15, 0.05, 0.55), 1.4, true)
	var sp := ctr + Vector2(cos(deg_to_rad(252.0)), sin(deg_to_rad(252.0))) * (r - w * 0.28)
	c.draw_line(sp - Vector2(10, 0), sp + Vector2(10, 0), Color(1, 1, 0.9, 0.85), 1.5, true)
	c.draw_line(sp - Vector2(0, 10), sp + Vector2(0, 10), Color(1, 1, 0.9, 0.85), 1.5, true)
