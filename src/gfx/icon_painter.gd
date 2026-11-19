extends RefCounted
## Icônes de l'interface de combat, peintes par code : commandes du menu, éléments, genres d'arme,
## états, et quelques signes (main du curseur, écu, cœur, goutte, point d'interrogation).
## Chaque icône tient dans 12 x 12 pixels (la main : 17 x 12), cernée d'un pixel sombre ; l'interface
## les affiche à l'échelle entière (x2) pour garder des pixels nets. Accès : Sprites.icon(nom).
## Un PNG de assets/sprites/icons/<nom>.png remplace la version peinte (voir sprite_library.gd).

const PA = preload("res://src/gfx/pixel_art.gd")

const SIZE := 12
const HAND_W := 17
const HAND_H := 12

const COMMANDS := ["attack", "skills", "items", "defend", "flee", "elan"]
const ELEMENTS := ["contondant", "tranchant", "feu", "foudre", "plante", "torpeur"]
const WEAPONS := ["baton", "ustensile", "dague", "serpe", "rapiere", "epee", "arc", "hache"]
const STATUSES := ["poison", "sommeil", "sonne", "ramolli", "englue", "galvanise", "garde", "ebranle", "gronde",
		"provocation", "demoralise", "enfume"]
const SIGNS := ["hand", "coin", "heart", "mana", "unknown", "up"]

const W := Color("#f4f0e4")
const G := Color("#b4b0c0")
const D := Color("#76728a")
const K := Color("#17121f")
const YEL := Color("#f2c84a")
const YEL_D := Color("#b8862a")
const BRN := Color("#b0733a")
const BRN_D := Color("#7a4a24")
const RED := Color("#e0584a")
const ORG := Color("#ff8a2a")
const SKY := Color("#8fb4e8")
const SKY_L := Color("#c4dcf8")
const GRN := Color("#7ac85a")
const GRN_D := Color("#3f7a3a")
const PUR := Color("#b89cf0")
const PUR_D := Color("#6a4aa8")


static func kinds() -> Array:
	return COMMANDS + ELEMENTS + WEAPONS + STATUSES + SIGNS


static func paint(kind: String) -> Image:
	if kind == "hand":
		return _hand()
	var img := PA.new_image(SIZE, SIZE)
	match kind:
		"attack": _attack(img)
		"skills": _skills(img)
		"items": _items(img)
		"defend": _shield(img, SKY, SKY_L)
		"garde": _shield(img, SKY, SKY_L)
		"flee": _flee(img)
		"elan": _flame(img, ORG, Color("#ffe27a"))
		"feu": _flame(img, Color("#ff7a3a"), Color("#ffe27a"))
		"contondant": _mace(img)
		"tranchant": _slashes(img)
		"foudre": _bolt(img)
		"plante": _leaf(img)
		"torpeur": _moon(img)
		"baton": _staff(img)
		"ustensile": _ladle(img)
		"dague": _dagger(img)
		"serpe": _sickle(img)
		"rapiere": _rapier(img)
		"epee": _sword(img)
		"arc": _bow(img)
		"hache": _axe(img)
		"poison": _poison(img)
		"sommeil": _zzz(img)
		"sonne": _dizzy(img)
		"ramolli": _arrow(img, false, Color("#d89a9a"))
		"galvanise", "up": _arrow(img, true, YEL)
		"englue": _web(img)
		"ebranle": _cracked(img)
		"gronde": _arrow(img, true, Color("#e0823c"))   # le plafond gronde : la force monte, en orange
		"provocation": _bang(img)
		"demoralise": _cloud(img, Color("#9aa0c8"), true)
		"enfume": _cloud(img, Color("#c8c8d2"), false)
		"coin": _coin(img)
		"heart": _heart(img)
		"mana": _drop(img, Color("#6aa0e8"), Color("#bcd8ff"))
		_: _unknown(img)
	PA.outline(img, Rect2i(0, 0, SIZE, SIZE), K)
	return img


# ------------------------------------------------------------------ primitives

static func _poly(img: Image, pts: Array, c: Color) -> void:
	var poly := PackedVector2Array()
	for p: Variant in pts:
		poly.append(p as Vector2)
	for y in img.get_height():
		for x in img.get_width():
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), poly):
				img.set_pixel(x, y, c)


static func _ell(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	PA.ellipse(img, cx, cy, rx, ry, c)


static func _erase(img: Image, cx: float, cy: float, rx: float, ry: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))


static func _ring(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var d := Vector2(x + 0.5 - cx, y + 0.5 - cy).length()
			if absf(d - r) <= 0.55:
				img.set_pixel(x, y, c)


static func _l(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	PA.line(img, x0, y0, x1, y1, c)


static func _p(img: Image, x: int, y: int, c: Color) -> void:
	PA.px(img, x, y, c)


static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	PA.rect(img, x, y, w, h, c)


static func _star4(img: Image, cx: int, cy: int, c: Color) -> void:
	_p(img, cx, cy, c)
	_p(img, cx - 1, cy, c)
	_p(img, cx + 1, cy, c)
	_p(img, cx, cy - 1, c)
	_p(img, cx, cy + 1, c)


# --------------------------------------------------------------------- commandes

static func _attack(img: Image) -> void:
	_l(img, 9, 2, 4, 7, W)
	_l(img, 10, 2, 5, 7, G)
	_p(img, 10, 1, W)
	_l(img, 3, 5, 7, 9, YEL)
	_l(img, 4, 8, 2, 10, BRN)


static func _skills(img: Image) -> void:
	_r(img, 5, 2, 2, 8, W)
	_r(img, 2, 5, 8, 2, W)
	_r(img, 5, 5, 2, 2, YEL)
	for p: Vector2i in [Vector2i(5, 1), Vector2i(6, 1), Vector2i(5, 10), Vector2i(6, 10), Vector2i(1, 5), Vector2i(1, 6), Vector2i(10, 5), Vector2i(10, 6)]:
		_p(img, p.x, p.y, YEL)
	_p(img, 3, 3, G)
	_p(img, 8, 3, G)
	_p(img, 3, 8, G)
	_p(img, 8, 8, G)


static func _items(img: Image) -> void:
	_ell(img, 6.0, 7.2, 4.4, 3.8, BRN)
	_ell(img, 5.0, 6.4, 2.0, 1.6, Color("#d89a5a"))
	_r(img, 4, 2, 4, 3, BRN)
	_r(img, 4, 4, 4, 1, YEL)
	_p(img, 3, 2, BRN)
	_p(img, 8, 2, BRN)


static func _shield(img: Image, body: Color, light: Color) -> void:
	_poly(img, [Vector2(1.2, 1.2), Vector2(10.8, 1.2), Vector2(10.8, 5.6), Vector2(9.2, 8.6), Vector2(6, 10.9), Vector2(2.8, 8.6), Vector2(1.2, 5.6)], light)
	_poly(img, [Vector2(2.4, 2.4), Vector2(9.6, 2.4), Vector2(9.6, 5.2), Vector2(8.6, 7.4), Vector2(6, 9.5), Vector2(3.4, 7.4), Vector2(2.4, 5.2)], body)
	_r(img, 3, 3, 3, 3, light)
	_p(img, 3, 3, W)


static func _flee(img: Image) -> void:
	_poly(img, [Vector2(6.2, 1.6), Vector2(10.9, 6), Vector2(6.2, 10.4)], W)
	_r(img, 1, 5, 6, 2, W)
	_r(img, 1, 6, 6, 1, G)
	_l(img, 1, 3, 3, 3, G)
	_l(img, 1, 9, 3, 9, G)


static func _flame(img: Image, outer: Color, inner: Color) -> void:
	_poly(img, [Vector2(6, 1.0), Vector2(8.4, 4.0), Vector2(10.4, 7.0), Vector2(9.2, 10.0), Vector2(6, 10.9),
			Vector2(2.8, 10.0), Vector2(1.6, 7.0), Vector2(3.8, 4.6), Vector2(4.6, 6.0), Vector2(5.0, 3.0)], outer)
	_poly(img, [Vector2(6, 5.6), Vector2(8.0, 8.4), Vector2(6, 10.4), Vector2(4.0, 8.4)], inner)


# ---------------------------------------------------------------------- éléments

static func _mace(img: Image) -> void:
	_l(img, 2, 10, 7, 5, BRN)
	_l(img, 3, 10, 8, 5, BRN_D)
	_ell(img, 8.0, 4.0, 2.9, 2.9, Color("#d9b98a"))
	_p(img, 7, 3, W)
	_p(img, 9, 5, BRN_D)
	_p(img, 6, 1, Color("#d9b98a"))
	_p(img, 10, 1, Color("#d9b98a"))
	_p(img, 10, 6, Color("#d9b98a"))


static func _slashes(img: Image) -> void:
	_l(img, 2, 9, 7, 2, W)
	_l(img, 3, 9, 8, 2, G)
	_l(img, 5, 10, 10, 3, W)
	_l(img, 6, 10, 10, 4, G)


static func _bolt(img: Image) -> void:
	_poly(img, [Vector2(7.6, 1.0), Vector2(3.0, 6.6), Vector2(5.6, 6.6), Vector2(4.4, 10.9), Vector2(9.4, 5.0), Vector2(6.6, 5.0), Vector2(8.8, 1.0)], YEL)
	_l(img, 7, 2, 4, 6, Color("#fff4b0"))


static func _leaf(img: Image) -> void:
	_poly(img, [Vector2(1.6, 10.0), Vector2(2.2, 5.4), Vector2(5.4, 2.0), Vector2(10.4, 1.4), Vector2(10.0, 6.4), Vector2(6.6, 9.8)], GRN)
	_l(img, 2, 10, 9, 3, GRN_D)
	_p(img, 4, 5, Color("#a8e080"))
	_p(img, 6, 3, Color("#a8e080"))


static func _moon(img: Image) -> void:
	_ell(img, 5.8, 6.2, 4.6, 4.6, PUR)
	_erase(img, 8.0, 4.6, 3.8, 3.8)
	_p(img, 9, 8, W)
	_p(img, 8, 2, W)
	_p(img, 10, 5, PUR)


# -------------------------------------------------------------------- genres d'arme

static func _staff(img: Image) -> void:
	_l(img, 2, 10, 8, 4, BRN)
	_l(img, 3, 10, 9, 4, BRN_D)
	_ell(img, 9.0, 3.0, 1.8, 1.8, PUR)
	_p(img, 8, 2, W)


static func _ladle(img: Image) -> void:
	_l(img, 2, 10, 7, 5, G)
	_l(img, 3, 10, 8, 5, D)
	_ell(img, 8.4, 3.6, 2.6, 2.4, G)
	_p(img, 7, 2, W)


static func _dagger(img: Image) -> void:
	_l(img, 9, 2, 6, 5, W)
	_l(img, 10, 2, 7, 5, G)
	_p(img, 10, 1, W)
	_l(img, 4, 5, 7, 8, YEL)
	_l(img, 5, 8, 3, 10, BRN)


static func _sickle(img: Image) -> void:
	_ell(img, 6.6, 5.0, 4.4, 4.2, G)
	_erase(img, 7.6, 6.2, 3.0, 3.0)
	_l(img, 5, 8, 2, 10, BRN)
	_p(img, 10, 4, W)
	_p(img, 9, 2, W)


static func _rapier(img: Image) -> void:
	_l(img, 10, 1, 4, 7, W)
	_l(img, 4, 5, 7, 8, YEL)
	_ell(img, 4.6, 7.4, 1.6, 1.6, YEL_D)
	_l(img, 4, 8, 2, 10, BRN)


static func _sword(img: Image) -> void:
	_poly(img, [Vector2(6, 1.0), Vector2(8.2, 3.0), Vector2(8.2, 7.4), Vector2(3.8, 7.4), Vector2(3.8, 3.0)], W)
	_r(img, 6, 2, 2, 5, G)
	_r(img, 2, 8, 8, 1, YEL)
	_r(img, 5, 9, 2, 2, BRN)


static func _bow(img: Image) -> void:
	_ell(img, 6.0, 5.8, 4.2, 5.0, BRN)
	_erase(img, 7.4, 5.8, 3.8, 4.4)
	_l(img, 8, 1, 8, 10, W)
	_l(img, 3, 6, 10, 6, G)
	_p(img, 10, 6, W)


static func _axe(img: Image) -> void:
	_l(img, 3, 10, 8, 3, BRN)
	_l(img, 4, 10, 9, 3, BRN_D)
	_poly(img, [Vector2(5.6, 1.4), Vector2(10.6, 1.8), Vector2(10.4, 6.6), Vector2(7.6, 5.6)], G)
	_l(img, 6, 2, 10, 2, W)


# ------------------------------------------------------------------------- états

static func _drop(img: Image, body: Color, light: Color) -> void:
	_poly(img, [Vector2(6, 1.0), Vector2(9.6, 6.4), Vector2(8.6, 9.6), Vector2(6, 10.9), Vector2(3.4, 9.6), Vector2(2.4, 6.4)], body)
	_p(img, 4, 7, light)
	_p(img, 4, 8, light)


static func _poison(img: Image) -> void:
	_drop(img, Color("#a6d85a"), Color("#e0f8a8"))
	_p(img, 5, 6, K)
	_p(img, 7, 6, K)
	_p(img, 6, 8, K)


static func _zzz(img: Image) -> void:
	_r(img, 2, 2, 7, 1, PUR)
	_l(img, 8, 3, 3, 8, PUR)
	_r(img, 2, 9, 8, 1, PUR)
	_r(img, 2, 3, 1, 1, PUR_D)
	_p(img, 10, 1, W)
	_p(img, 10, 4, W)


static func _dizzy(img: Image) -> void:
	_star4(img, 3, 3, YEL)
	_star4(img, 8, 3, Color("#ffe27a"))
	_star4(img, 6, 8, YEL)
	_p(img, 10, 8, W)
	_p(img, 1, 8, W)


static func _arrow(img: Image, up: bool, c: Color) -> void:
	var pts: Array = [Vector2(4.4, 10.6), Vector2(7.6, 10.6), Vector2(7.6, 6.0), Vector2(10.4, 6.0), Vector2(6, 1.2), Vector2(1.6, 6.0), Vector2(4.4, 6.0)]
	if not up:
		pts = []
		for p: Vector2 in [Vector2(4.4, 10.6), Vector2(7.6, 10.6), Vector2(7.6, 6.0), Vector2(10.4, 6.0), Vector2(6, 1.2), Vector2(1.6, 6.0), Vector2(4.4, 6.0)]:
			pts.append(Vector2(p.x, 11.8 - p.y))
	_poly(img, pts, c)


static func _web(img: Image) -> void:
	var c := Color("#9ec4b0")
	_l(img, 6, 1, 6, 10, c)
	_l(img, 1, 6, 10, 6, c)
	_l(img, 2, 2, 9, 9, c)
	_l(img, 9, 2, 2, 9, c)
	_ring(img, 6.0, 6.0, 2.4, W)
	_ring(img, 6.0, 6.0, 4.4, c)


static func _cracked(img: Image) -> void:
	_shield(img, Color("#d84a3a"), Color("#f09a88"))
	_l(img, 7, 1, 5, 4, K)
	_l(img, 5, 4, 7, 6, K)
	_l(img, 7, 6, 5, 9, K)
	_p(img, 6, 4, Color("#ffe0d0"))


static func _bang(img: Image) -> void:
	_poly(img, [Vector2(4.4, 1.2), Vector2(7.6, 1.2), Vector2(6.9, 7.0), Vector2(5.1, 7.0)], ORG)
	_r(img, 5, 8, 2, 2, ORG)


static func _cloud(img: Image, c: Color, rain: bool) -> void:
	var top := 1.0 if not rain else 0.0
	_ell(img, 4.4, 4.6 + top, 2.8, 2.6, c)
	_ell(img, 7.6, 4.0 + top, 3.0, 3.0, c)
	_ell(img, 6.0, 6.2 + top, 4.6, 2.2, c)
	if rain:
		_p(img, 3, 9, Color("#8ab8ff"))
		_p(img, 6, 9, Color("#8ab8ff"))
		_p(img, 9, 9, Color("#8ab8ff"))
		_p(img, 4, 10, Color("#8ab8ff"))
		_p(img, 7, 10, Color("#8ab8ff"))
	else:
		_p(img, 4, 4, W)
		_p(img, 8, 3, W)


# ------------------------------------------------------------------------ signes

static func _coin(img: Image) -> void:
	_ell(img, 6.0, 6.0, 4.6, 4.8, YEL)
	_ell(img, 6.0, 6.0, 3.0, 3.2, YEL_D)
	_ell(img, 6.0, 6.0, 2.0, 2.2, YEL)
	_p(img, 3, 3, W)


static func _heart(img: Image) -> void:
	_ell(img, 3.8, 4.0, 2.7, 2.6, RED)
	_ell(img, 8.2, 4.0, 2.7, 2.6, RED)
	_poly(img, [Vector2(1.1, 5.0), Vector2(10.9, 5.0), Vector2(6, 10.8)], RED)
	_p(img, 3, 3, Color("#ffb0a0"))


static func _unknown(img: Image) -> void:
	var rows := ["..xxxx..", ".xx..xx.", ".....xx.", "....xx..", "...xx...", "...xx...", "........", "...xx..."]
	for y in rows.size():
		for x in 8:
			if (rows[y] as String)[x] == "x":
				_p(img, x + 2, y + 2, G)


## Gant pointé vers la droite (17 x 12 px, affiché à l'échelle x2) : manchette dorée à gauche,
## pouce levé, index tendu, autres doigts repliés. Le bout de l'index touche le bord droit.
static func _hand() -> Image:
	var img := PA.new_image(HAND_W, HAND_H)
	var rows := [
		"....www........",
		"....wwg........",
		"yyywwwwwwwwwwww",
		"ydywwwwwwwwwwwg",
		"ydywwwwwgggggg.",
		"ydywwwwwwwwwwg.",
		"ydywwwwwwwwggg.",
		"ydywwwwwwwwwg..",
		"ydywwwgggggg...",
		"yyygggggg......"]
	var pal := {"w": W, "g": G, "y": YEL, "d": YEL_D}
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			if pal.has(row[x]):
				_p(img, x + 1, y + 1, pal[row[x]])
	PA.outline(img, Rect2i(0, 0, HAND_W, HAND_H), K)
	return img
