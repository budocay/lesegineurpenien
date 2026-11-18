extends RefCounted
## Style commun de l'interface : police à empattements, panneaux bleu nuit bordés d'or.

const GOLD := Color("#e2c27c")
const GOLD_DIM := Color("#a8905c")
const INK := Color("#f3ead6")
const INK_DIM := Color("#b9b2a6")
const NIGHT := Color(0.06, 0.055, 0.12, 0.93)

static var _fonts: Dictionary = {}


static func font(bold: bool = false, italic: bool = false) -> Font:
	var key := (1 if bold else 0) + (2 if italic else 0)
	if _fonts.has(key):
		return _fonts[key]
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Palatino", "Palatino Linotype", "Book Antiqua", "Georgia", "Times New Roman", "serif"])
	f.font_weight = 700 if bold else 400
	f.font_italic = italic
	_fonts[key] = f
	return f


static func panel_style(bg: Color = NIGHT, border: Color = GOLD, radius: int = 6, border_width: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0, 0, 0, 0.45)
	s.shadow_size = 8
	s.shadow_offset = Vector2(0, 3)
	s.set_content_margin_all(10)
	return s


static func label(text: String, size: int, color: Color = INK, bold: bool = false, italic: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(bold, italic))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.75))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


static func menu_button(text: String, size: int = 26) -> Button:
	var b := Button.new()
	b.text = text
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_focus_color", GOLD)
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_hover_pressed_color", GOLD)
	b.add_theme_color_override("font_disabled_color", Color(0.55, 0.53, 0.5, 0.6))
	var idle := StyleBoxFlat.new()
	idle.bg_color = Color(0, 0, 0, 0)
	idle.content_margin_left = 18
	idle.content_margin_right = 18
	idle.content_margin_top = 5
	idle.content_margin_bottom = 5
	var hot := idle.duplicate() as StyleBoxFlat
	hot.bg_color = Color(GOLD.r, GOLD.g, GOLD.b, 0.14)
	hot.border_color = GOLD
	hot.border_width_left = 3
	b.add_theme_stylebox_override("normal", idle)
	b.add_theme_stylebox_override("disabled", idle)
	b.add_theme_stylebox_override("hover", hot)
	b.add_theme_stylebox_override("focus", hot)
	b.add_theme_stylebox_override("pressed", hot)
	b.focus_entered.connect(func() -> void: Sfx.play("move"))
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			b.grab_focus())
	return b


static func full_rect(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
