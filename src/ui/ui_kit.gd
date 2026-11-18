extends RefCounted
## Boîte à outils commune de l'interface. Tout le style vit ici : couleurs, polices,
## panneaux estompés, filets ornés, curseur de menu, jauges, rappels de touches, cadre
## d'écran. Direction : panneaux sombres translucides aux bords fondus, filets fins dorés,
## empattements élégants, beaucoup d'air. Chaque écran en hérite, rien n'est redéfini ailleurs.

const GOLD := Color("#e6c98a")
const GOLD_DIM := Color("#a8905c")
const GOLD_LINE := Color(0.9, 0.77, 0.48, 0.55)
const INK := Color("#f1e9d6")
const INK_DIM := Color("#b5ae9f")
const INK_FAINT := Color("#8a8478")
const SKY := Color("#bfe8ff")            # points, choses disponibles
const WARN := Color("#e8a08a")           # refus, manque
const GOOD := Color("#9fd69a")           # hausse d'une caractéristique
const NIGHT := Color(0.035, 0.04, 0.085, 0.82)
const SHADE := Color(0.015, 0.015, 0.04, 0.6)

## Rappels de touches : mêmes mots partout.
const KEYS_MENU := [["Flèches", "choisir"], ["Entrée", "valider"], ["Échap", "retour"]]

static var _fonts: Dictionary = {}
static var _cache: Dictionary = {}


# ------------------------------------------------------------------ polices

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


## Empattements aux lettres espacées, pour les petites capitales d'étiquette.
static func font_caps() -> Font:
	if _fonts.has("caps"):
		return _fonts["caps"]
	var v := FontVariation.new()
	v.base_font = font(false)
	v.spacing_glyph = 2
	_fonts["caps"] = v
	return v


static func label(text: String, size: int, color: Color = INK, bold: bool = false, italic: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(bold, italic))
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l


## Étiquette en petites capitales espacées (le texte passe en majuscules).
static func caps(text: String, size: int = 14, color: Color = GOLD_DIM) -> Label:
	var l := label(text.to_upper(), size, color)
	l.add_theme_font_override("font", font_caps())
	return l


# ------------------------------------------------------------------- dégradés

static func _grad(key: String, offsets: Array, colors: Array, vertical: bool = false, size: int = 128) -> GradientTexture2D:
	if _cache.has(key):
		return _cache[key]
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = 4 if vertical else size
	t.height = size if vertical else 4
	t.fill_from = Vector2(0, 0)
	t.fill_to = Vector2(0, 1) if vertical else Vector2(1, 0)
	_cache[key] = t
	return t


## Voile vertical : transparent en haut, sombre en bas (ou l'inverse), pour tenir un texte lisible.
static func veil(from_top: bool, alpha: float = 0.8) -> TextureRect:
	var dark := Color(0.02, 0.02, 0.05, alpha)
	var clear := Color(0.02, 0.02, 0.05, 0.0)
	var key := "veil%s%f" % [from_top, alpha]
	var tex := _grad(key, [0.0, 0.55, 1.0], [dark, Color(0.02, 0.02, 0.05, alpha * 0.55), clear] if from_top else [clear, Color(0.02, 0.02, 0.05, alpha * 0.55), dark], true, 64)
	var r := TextureRect.new()
	r.texture = tex
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Bande sombre qui s'estompe en haut et en bas (écrans de victoire et de défaite).
static func band(alpha: float = 0.82) -> TextureRect:
	var d := Color(0.02, 0.02, 0.05, alpha)
	var tex := _grad("band%f" % alpha, [0.0, 0.3, 0.7, 1.0], [Color(d, 0.0), d, d, Color(d, 0.0)], true, 64)
	var r := TextureRect.new()
	r.texture = tex
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## Même bande, sous forme de fond de panneau (marges verticales généreuses).
static func band_style(alpha: float = 0.82) -> StyleBoxTexture:
	var d := Color(0.02, 0.02, 0.05, alpha)
	var st := StyleBoxTexture.new()
	st.texture = _grad("band%f" % alpha, [0.0, 0.3, 0.7, 1.0], [Color(d, 0.0), d, d, Color(d, 0.0)], true, 64)
	st.content_margin_top = 64
	st.content_margin_bottom = 64
	st.content_margin_left = 40
	st.content_margin_right = 40
	return st


# ------------------------------------------------------------------- panneaux

## Panneau aux bords fondus : un cadre sombre translucide sans trait, qui s'efface vers l'extérieur.
static func soft_style(alpha: float = 0.86, margin: int = 30) -> StyleBoxTexture:
	var key := "soft%f" % alpha
	var s: StyleBoxTexture
	if _cache.has(key):
		s = (_cache[key] as StyleBoxTexture).duplicate()
	else:
		var n := 64
		var ramp := 22
		var img := Image.create(n, n, false, Image.FORMAT_RGBA8)
		for y in n:
			for x in n:
				var d := float(mini(mini(x, n - 1 - x), mini(y, n - 1 - y)))
				var t := clampf(d / ramp, 0.0, 1.0)
				t = t * t * (3.0 - 2.0 * t)
				img.set_pixel(x, y, Color(0.03, 0.035, 0.08, alpha * t))
		var base := StyleBoxTexture.new()
		base.texture = ImageTexture.create_from_image(img)
		base.set_texture_margin_all(ramp)
		_cache[key] = base
		s = base.duplicate()
	s.set_content_margin_all(margin)
	return s


## Cadre à filet fin, pour les petits éléments (plaques, bulles, puces).
static func panel_style(bg: Color = NIGHT, border: Color = GOLD_LINE, radius: int = 3, border_width: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_width)
	s.set_corner_radius_all(radius)
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_size = 6
	s.shadow_offset = Vector2(0, 2)
	s.set_content_margin_all(8)
	return s


## Filet fin à bout orné d'un losange.
## mode : "both" (s'estompe aux deux bouts, losange au centre), "in" (naît à gauche, losange
## à droite : à poser avant un titre), "out" (losange à gauche, s'estompe à droite : après un titre).
## width 0 : prend toute la largeur disponible.
static func rule(width: float = 0.0, mode: String = "both", color: Color = GOLD) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(width, 9)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if width <= 0.0:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fade_in := _grad("rin%s" % color.to_html(), [0.0, 1.0], [Color(color, 0.0), Color(color, 0.85)])
	var fade_out := _grad("rout%s" % color.to_html(), [0.0, 1.0], [Color(color, 0.85), Color(color, 0.0)])
	c.draw.connect(_draw_rule.bind(c, mode, color, fade_in, fade_out))
	return c


static func _draw_rule(c: Control, mode: String, color: Color, fade_in: Texture2D, fade_out: Texture2D) -> void:
	var w := c.size.x
	var y := floorf(c.size.y * 0.5)
	var gem := Color(color, 0.95)
	if mode == "in":
		c.draw_texture_rect(fade_in, Rect2(0, y, w - 8.0, 1), false)
		_diamond(c, Vector2(w - 3.0, y + 0.5), 3.0, gem)
	elif mode == "out":
		c.draw_texture_rect(fade_out, Rect2(8.0, y, w - 8.0, 1), false)
		_diamond(c, Vector2(3.0, y + 0.5), 3.0, gem)
	else:
		var half := w * 0.5
		c.draw_texture_rect(fade_in, Rect2(0, y, half - 9.0, 1), false)
		c.draw_texture_rect(fade_out, Rect2(half + 9.0, y, half - 9.0, 1), false)
		_diamond(c, Vector2(half, y + 0.5), 3.5, gem)


static func _diamond(c: Control, at: Vector2, r: float, color: Color) -> void:
	c.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r), at + Vector2(-r, 0)]), color)


## Filet vertical très discret, pour séparer deux colonnes.
static func vline() -> Control:
	var c := ColorRect.new()
	c.color = Color(GOLD, 0.22)
	c.custom_minimum_size = Vector2(1, 0)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


# --------------------------------------------------------------------- menus

## Bouton de liste : fond transparent, et sous le curseur une bande dorée qui s'estompe
## vers la droite, précédée d'un petit losange. Même rendu dans tous les menus.
static func menu_button(text: String, size: int = 24) -> Button:
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
	b.add_theme_color_override("font_disabled_color", Color(0.55, 0.53, 0.5, 0.55))
	var idle := StyleBoxEmpty.new()
	idle.content_margin_left = 32
	idle.content_margin_right = 18
	idle.content_margin_top = 5
	idle.content_margin_bottom = 5
	var hot := StyleBoxTexture.new()
	hot.texture = _grad("hot", [0.0, 0.55, 1.0], [Color(GOLD, 0.30), Color(GOLD, 0.11), Color(GOLD, 0.0)], false, 128)
	hot.content_margin_left = 32
	hot.content_margin_right = 18
	hot.content_margin_top = 5
	hot.content_margin_bottom = 5
	b.add_theme_stylebox_override("normal", idle)
	b.add_theme_stylebox_override("disabled", idle)
	b.add_theme_stylebox_override("hover", hot)
	b.add_theme_stylebox_override("focus", hot)
	b.add_theme_stylebox_override("pressed", hot)
	b.draw.connect(func() -> void:
		if b.has_focus() and not b.disabled:
			var h := floorf(b.size.y * 0.5)
			_diamond(b, Vector2(14.0, h), 4.0, GOLD)
			b.draw_line(Vector2(5, b.size.y - 1.0), Vector2(b.size.x * 0.7, b.size.y - 1.0), Color(GOLD, 0.35), 1.0))
	b.focus_entered.connect(func() -> void:
		Sfx.play("move")
		b.queue_redraw())
	b.focus_exited.connect(b.queue_redraw)
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			b.grab_focus())
	return b


## Ligne de rappels de touches : [["Entrée", "valider"], ...] sous forme de petites touches.
static func hints(pairs: Array, size: int = 15) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for p: Array in pairs:
		var item := HBoxContainer.new()
		item.add_theme_constant_override("separation", 8)
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var cap := PanelContainer.new()
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color(1, 1, 1, 0.05)
		cs.border_color = Color(INK_FAINT, 0.8)
		cs.set_border_width_all(1)
		cs.set_corner_radius_all(3)
		cs.content_margin_left = 8
		cs.content_margin_right = 8
		cs.content_margin_top = 3
		cs.content_margin_bottom = 3
		cap.add_theme_stylebox_override("panel", cs)
		cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cap.add_child(label(str(p[0]), size - 2, GOLD))
		item.add_child(cap)
		item.add_child(label(str(p[1]), size, INK_DIM))
		row.add_child(item)
	return row


## Jauge fine (PV, PM, vie d'ennemi).
static func gauge(color: Color, width: float, height: float = 6.0) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(width, height)
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.55)
	bg.border_color = Color(1, 1, 1, 0.16)
	bg.set_border_width_all(1)
	bg.set_corner_radius_all(1)
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.set_corner_radius_all(1)
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	return bar


## Plaque fine pour un nom (locuteur, fiche).
static func plate(text: String, size: int = 22) -> PanelContainer:
	var p := PanelContainer.new()
	var s := panel_style(Color(0.03, 0.035, 0.08, 0.92), GOLD_LINE, 2, 1)
	s.content_margin_left = 18
	s.content_margin_right = 18
	s.content_margin_top = 2
	s.content_margin_bottom = 4
	p.add_theme_stylebox_override("panel", s)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(label(text, size, GOLD, true))
	return p


# --------------------------------------------------------------- cadre d'écran

## Squelette commun des écrans plein cadre (équipe, inventaire, talents, sauvegardes...) :
## voile, panneau fondu centré, titre + mention à droite, filet orné, corps, rappels de touches.
## Renvoie {"panel", "title", "right", "body", "foot"}.
static func screen(root: Control, title: String, min_size: Vector2, shade_alpha: float = 0.6) -> Dictionary:
	var shade := ColorRect.new()
	shade.color = Color(SHADE, shade_alpha)
	full_rect(shade)
	root.add_child(shade)
	var center := CenterContainer.new()
	full_rect(center)
	root.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", soft_style(0.95, 26))
	panel.custom_minimum_size = min_size
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var t := label(title, 34, GOLD)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(t)
	var right := label("", 21, GOLD)
	right.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(right)
	box.add_child(rule())
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(body)
	var foot := HBoxContainer.new()
	box.add_child(foot)
	return {"panel": panel, "title": t, "right": right, "body": body, "foot": foot}


## Apparition courte d'un panneau : fondu et léger grossissement (centré sur lui-même).
static func pop(c: Control, duration: float = 0.16) -> void:
	if not c.is_inside_tree():
		return
	c.pivot_offset = c.size * 0.5
	c.modulate.a = 0.0
	c.scale = Vector2(0.985, 0.985)
	var tw := c.create_tween().set_parallel(true)
	tw.tween_property(c, "modulate:a", 1.0, duration)
	tw.tween_property(c, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Texte riche pour un détail : première ligne en titre doré quand il y en a plusieurs.
static func rich(size: int = 19) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.scroll_active = false
	r.fit_content = false
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.add_theme_font_override("normal_font", font())
	r.add_theme_font_override("bold_font", font(true))
	r.add_theme_font_override("italics_font", font(false, true))
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("italics_font_size", size)
	r.add_theme_color_override("default_color", INK)
	r.add_theme_constant_override("line_separation", 3)
	return r


## Met en forme un texte à lignes : le premier retour à la ligne sépare titre et corps.
static func detail_markup(text: String, title_size: int = 27) -> String:
	var safe := text.replace("[", "[lb]")
	var cut := safe.find("\n")
	if cut < 0:
		return safe
	# la ligne vide finale évite qu'un texte court soit rogné d'un demi-interligne
	return "[font_size=%d][color=#%s]%s[/color][/font_size]%s\n \n " % [title_size, GOLD.to_html(false), safe.substr(0, cut), safe.substr(cut)]


static func full_rect(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


# ---------------------------------------------------- bandeaux de combat (ajouts)

## Fond d'une fiche : dégradé horizontal, transparent d'un côté, teinté de l'autre.
## to_right : vrai = sombre à droite (fiches collées au bord droit de l'écran).
static func fade_style(color: Color, alpha: float, to_right: bool = true, margin: int = 10) -> StyleBoxTexture:
	var d := Color(color, alpha)
	var tex := _grad("fade%s%f%s" % [color.to_html(), alpha, to_right], [0.0, 0.45, 1.0],
			[Color(d, 0.0), Color(d, alpha * 0.8), d] if to_right else [d, Color(d, alpha * 0.8), Color(d, 0.0)], false, 128)
	var st := StyleBoxTexture.new()
	st.texture = tex
	st.content_margin_left = margin + 14
	st.content_margin_right = margin
	st.content_margin_top = 5
	st.content_margin_bottom = 6
	return st


## Entrée de menu en bandeau sombre translucide (menus de combat). Au curseur : bandeau
## éclairci, liseré doré à gauche, losange, et la ligne d'aide « help » s'ouvre sous le texte.
## « right » : texte aligné à droite (coût, quantité).
static func band_button(text: String, size: int = 22, help: String = "", right: String = "", width: int = 240) -> Button:
	var b := Button.new()
	b.text = ""   # le texte est dessiné ici (en haut du bandeau, l'aide s'ouvre dessous)
	b.set_meta("label", text)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_focus_color", GOLD)
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_hover_pressed_color", GOLD)
	b.add_theme_color_override("font_disabled_color", Color(0.6, 0.58, 0.55, 0.5))
	var help_h := 0
	if help != "":
		help_h = int(ceilf(font(false, true).get_multiline_string_size(help, HORIZONTAL_ALIGNMENT_LEFT, width - 42.0, 15).y)) + 4
	var idle := StyleBoxFlat.new()
	idle.bg_color = Color(0.03, 0.035, 0.07, 0.86)
	idle.border_color = Color(1, 1, 1, 0.07)
	idle.border_width_bottom = 1
	idle.content_margin_left = 26
	idle.content_margin_right = 16
	idle.content_margin_top = 6
	idle.content_margin_bottom = 6
	var hot := idle.duplicate() as StyleBoxFlat
	hot.bg_color = Color(0.17, 0.15, 0.13, 0.9)
	hot.border_color = GOLD
	hot.border_width_left = 3
	hot.border_width_bottom = 0
	hot.content_margin_bottom = 6 + help_h
	b.add_theme_stylebox_override("normal", idle)
	b.add_theme_stylebox_override("disabled", idle)
	b.add_theme_stylebox_override("hover", hot)
	b.add_theme_stylebox_override("focus", hot)
	b.add_theme_stylebox_override("pressed", hot)
	# la hauteur de base est fixée ici (un bouton calcule son minimum sur son style « normal »)
	var base_h := font().get_height(size) + 12.0
	b.custom_minimum_size = Vector2(width, base_h)
	b.draw.connect(func() -> void:
		var focused := b.has_focus() and not b.disabled
		var ink := GOLD if focused else (INK if not b.disabled else Color(0.6, 0.58, 0.55, 0.5))
		b.draw_string(font(), Vector2(26.0, 6.0 + font().get_ascent(size)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ink)
		if focused:
			_diamond(b, Vector2(13.0, 6.0 + size * 0.55), 4.0, GOLD)
			if help != "":
				b.draw_multiline_string(font(false, true), Vector2(26.0, b.size.y - help_h - 1.0 + 15.0), help, HORIZONTAL_ALIGNMENT_LEFT, width - 42.0, 15, -1, INK_DIM)
		if right != "":
			var col := GOLD if focused else (INK_DIM if not b.disabled else Color(0.6, 0.58, 0.55, 0.5))
			var w := font().get_string_size(right, HORIZONTAL_ALIGNMENT_LEFT, -1, size - 3).x
			b.draw_string(font(), Vector2(b.size.x - w - 16.0, 6.0 + size * 0.95), right, HORIZONTAL_ALIGNMENT_LEFT, -1, size - 3, col))
	b.focus_entered.connect(func() -> void:
		Sfx.play("move")
		b.custom_minimum_size.y = base_h + help_h
		b.queue_redraw())
	b.focus_exited.connect(func() -> void:
		b.custom_minimum_size.y = base_h
		b.queue_redraw())
	b.mouse_entered.connect(func() -> void:
		if not b.disabled and b.focus_mode != Control.FOCUS_NONE:
			b.grab_focus())
	return b


## Comme band_button, avec une icône devant le texte, une icône facultative à droite (genre d'arme),
## une main qui désigne l'entrée choisie ; « warn » colore l'indication de droite (coût trop élevé).
static func icon_band_button(text: String, size: int = 22, help: String = "", right: String = "", width: int = 240, icon: Texture2D = null, right_icon: Texture2D = null, warn: bool = false) -> Button:
	var b := Button.new()
	b.text = ""   # le texte est dessiné ici (en haut du bandeau, l'aide s'ouvre dessous)
	b.set_meta("label", text)
	b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tx := 40.0 + (32.0 if icon != null else 0.0)   # le texte laisse la place à l'icône
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", font())
	b.add_theme_font_size_override("font_size", size)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_focus_color", GOLD)
	b.add_theme_color_override("font_pressed_color", GOLD)
	b.add_theme_color_override("font_hover_pressed_color", GOLD)
	b.add_theme_color_override("font_disabled_color", Color(0.6, 0.58, 0.55, 0.5))
	var help_h := 0
	if help != "":
		help_h = int(ceilf(font(false, true).get_multiline_string_size(help, HORIZONTAL_ALIGNMENT_LEFT, width - tx - 16.0, 15).y)) + 4
	var idle := StyleBoxFlat.new()
	idle.bg_color = Color(0.03, 0.035, 0.07, 0.86)
	idle.border_color = Color(1, 1, 1, 0.07)
	idle.border_width_bottom = 1
	idle.content_margin_left = 26
	idle.content_margin_right = 16
	idle.content_margin_top = 3
	idle.content_margin_bottom = 3
	var hot := idle.duplicate() as StyleBoxFlat
	hot.bg_color = Color(0.17, 0.15, 0.13, 0.9)
	hot.border_color = GOLD
	hot.border_width_left = 3
	hot.border_width_bottom = 0
	hot.content_margin_bottom = 3 + help_h
	b.add_theme_stylebox_override("normal", idle)
	b.add_theme_stylebox_override("disabled", idle)
	b.add_theme_stylebox_override("hover", hot)
	b.add_theme_stylebox_override("focus", hot)
	b.add_theme_stylebox_override("pressed", hot)
	# la hauteur de base est fixée ici (un bouton calcule son minimum sur son style « normal »)
	var base_h := font().get_height(size) + 6.0
	b.custom_minimum_size = Vector2(width, base_h)
	b.draw.connect(func() -> void:
		var focused := b.has_focus() and not b.disabled
		var ink := GOLD if focused else (INK if not b.disabled else Color(0.6, 0.58, 0.55, 0.5))
		var tint := Color.WHITE if not b.disabled else Color(1, 1, 1, 0.4)
		if icon != null:
			var ih := font().get_height(size)
			b.draw_texture_rect(icon, Rect2(40.0, floorf(3.0 + (ih - 24.0) * 0.5), 24.0, 24.0), false, tint)
		b.draw_string(font(), Vector2(tx, 3.0 + font().get_ascent(size)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ink)
		if focused:
			# la main qui désigne l'entrée, d'un léger va-et-vient
			var hand := Sprites.icon("hand")
			var bob := roundf(sin(float(Time.get_ticks_msec()) * 0.009) * 2.0)
			b.draw_texture_rect(hand, Rect2(2.0 + bob, floorf(3.0 + (font().get_height(size) - 24.0) * 0.5), 34.0, 24.0), false)
			if help != "":
				b.draw_multiline_string(font(false, true), Vector2(tx, b.size.y - help_h - 1.0 + 15.0), help, HORIZONTAL_ALIGNMENT_LEFT, width - tx - 16.0, 15, -1, INK_DIM)
		var rx := b.size.x - 16.0
		if right_icon != null:
			rx -= 24.0
			b.draw_texture_rect(right_icon, Rect2(rx, floorf(3.0 + (font().get_height(size) - 24.0) * 0.5), 24.0, 24.0), false, tint)
			rx -= 6.0
		if right != "":
			var col := GOLD if focused else (INK_DIM if not b.disabled else Color(0.6, 0.58, 0.55, 0.5))
			if warn and not focused:
				col = Color("#e8785a") if not b.disabled else Color(0.7, 0.4, 0.34, 0.55)
			var w := font().get_string_size(right, HORIZONTAL_ALIGNMENT_LEFT, -1, size - 3).x
			b.draw_string(font(), Vector2(rx - w, 3.0 + size * 0.95), right, HORIZONTAL_ALIGNMENT_LEFT, -1, size - 3, col))
	b.focus_entered.connect(func() -> void:
		Sfx.play("move")
		b.custom_minimum_size.y = base_h + help_h
		b.queue_redraw())
	b.focus_exited.connect(func() -> void:
		b.custom_minimum_size.y = base_h
		b.queue_redraw())
	b.mouse_entered.connect(func() -> void:
		if not b.disabled and b.focus_mode != Control.FOCUS_NONE:
			b.grab_focus())
	return b


## Losange public (vignettes, curseurs) : points d'un losange de centre c et de rayon r.
static func diamond_points(c: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(0, -r), c + Vector2(r, 0), c + Vector2(0, r), c + Vector2(-r, 0)])


## Texte de détail déjà en BBCode (les « [ » ne sont pas protégés : à réserver à du texte construit
## par le code). Titre doré, puis le corps.
static func title_markup(text: String, body: String, title_size: int = 27) -> String:
	return "[font_size=%d][color=#%s]%s[/color][/font_size]\n%s" % [title_size, GOLD.to_html(false), escape_bb(text), body]


## Protège les crochets d'un texte qui va dans un BBCode.
static func escape_bb(text: String) -> String:
	return text.replace("[", "[lb]")


## Balise de couleur BBCode.
static func tint(text: String, color: Color) -> String:
	return "[color=#%s]%s[/color]" % [color.to_html(false), text]
