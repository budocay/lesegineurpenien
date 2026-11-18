extends RefCounted
## Peint la planche de sprites d'un personnage à partir d'une description (« look »).
##
## Format de la planche générée (voir assets/sprites/README.md) :
##   cases de 48 x 72 px, 11 colonnes, 4 lignes dans l'ordre : bas, gauche, droite, haut.
##   colonnes 0 à 2  : repos (normal, respiration, clignement)
##   colonnes 3 à 6  : marche (appui gauche, passage, appui droit, passage)
##   colonnes 7 à 10 : combat (attaque, sort, coup reçu, KO)
##
## « species » choisit le corps : grobitte/humain (par défaut), "morfale", "naze".
##
## Méthode (refonte « façon Octopath ») : chaque pièce (tête, torse, jambe, manche, chapeau...)
## est un petit volume éclairé : on calcule la normale de la forme en chaque pixel et on
## choisit parmi une rampe de cinq tons dont les ombres glissent vers le violet et les
## lumières vers le chaud (PA.shade). La lumière vient d'en haut à gauche, dans les quatre
## vues (la ligne « droite » est peinte en miroir avec la lumière inversée, pas copiée).
## Le contour n'est pas noir : il prend la teinte sombre de la pièce qu'il borde.

const PA = preload("res://src/gfx/pixel_art.gd")

const FRAME_W := 48
const FRAME_H := 72
const COLUMNS := 11
const ROWS := 4
const FOOT_MARGIN := 3   # pixels vides sous les pieds dans chaque case
const PPU := 32.0        # pixels par unité monde pour les planches peintes par code
const IDLE := [0, 0, 1, 1, 0, 0, 1, 1, 0, 2, 1, 1]   # suite jouée au repos (4 images/s)
const WALK := [3, 4, 5, 6]
const POSES := {"attack": 7, "cast": 8, "hit": 9, "ko": 10}

const WHITE := Color("#ffffff")
const GOLD := Color("#f2c84a")
const RED := Color("#c8403a")
const MOUTH := Color("#6a2f3a")

# état de la case en cours de peinture (peindre une case à la fois, sans partage)
static var _im: Image
static var _c: Dictionary
static var _p: Dictionary
static var _lx := -0.5       # composante x de la lumière, dans le repère du dessin
static var _flip := -1       # >= 0 : le dessin est retourné (ligne « droite »)
static var _cx := 24.0
static var _foot := 68.0
static var _hip := 0.0
static var _ny := 0.0
static var _hcy := 0.0
static var _rx := 11.0
static var _ry := 10.0
static var _th := 15.0
static var _half := 7.0


static func paint_sheet(look: Dictionary) -> Image:
	var sheet := PA.new_image(FRAME_W * COLUMNS, FRAME_H * ROWS)
	var c := _colors(look)
	var species := str(look.get("species", ""))
	for col in COLUMNS:
		var p := _pose(col)
		for row in ROWS:
			var cell := PA.new_image(FRAME_W, FRAME_H)
			var view := 0
			if row == 1 or row == 2:
				view = 1
			elif row == 3:
				view = 2
			_im = cell
			_c = c
			_p = p
			_flip = FRAME_W - 1 if row == 2 else -1
			_lx = 0.5 if row == 2 else -0.5
			match species:
				"morfale":
					_morfale(look, view)
				"naze":
					_naze(view)
				_:
					match view:
						0:
							_front(look, false)
						1:
							_side(look)
						_:
							_front(look, true)
			_outline()
			sheet.blit_rect(cell, Rect2i(0, 0, FRAME_W, FRAME_H), Vector2i(col * FRAME_W, row * FRAME_H))
	_flip = -1
	_lx = -0.5
	return sheet


## Portrait 48 x 48 : le visage de face, agrandi deux fois avec lissage des diagonales.
static func paint_portrait(look: Dictionary) -> Image:
	var bare := look.duplicate()
	bare["item"] = "none"          # pas de bâton ni de pipe en travers du portrait
	var sheet := paint_sheet(bare)
	var side := 24
	var x := (FRAME_W - side) / 2
	var y := 0
	if str(look.get("species", "")) == "":
		_p = _pose(0)
		_layout(look)
		y = clampi(int(_hcy - _ry) - 2, 0, FRAME_H - side)
	else:
		var b := PA.opaque_bounds(sheet, Rect2i(0, 0, FRAME_W, FRAME_H))
		y = clampi(b.position.y - 1, 0, FRAME_H - side)
	return _scale2x(sheet.get_region(Rect2i(x, y, side, side)))


## Agrandissement x2 qui adoucit les escaliers (algorithme Scale2x).
static func _scale2x(src: Image) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var out := Image.create(w * 2, h * 2, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var e := src.get_pixel(x, y)
			var b := src.get_pixel(x, maxi(0, y - 1))
			var d := src.get_pixel(maxi(0, x - 1), y)
			var f := src.get_pixel(mini(w - 1, x + 1), y)
			var hh := src.get_pixel(x, mini(h - 1, y + 1))
			var e0 := e
			var e1 := e
			var e2 := e
			var e3 := e
			if not b.is_equal_approx(hh) and not d.is_equal_approx(f):
				if d.is_equal_approx(b):
					e0 = d
				if b.is_equal_approx(f):
					e1 = f
				if d.is_equal_approx(hh):
					e2 = d
				if hh.is_equal_approx(f):
					e3 = f
			out.set_pixel(x * 2, y * 2, e0)
			out.set_pixel(x * 2 + 1, y * 2, e1)
			out.set_pixel(x * 2, y * 2 + 1, e2)
			out.set_pixel(x * 2 + 1, y * 2 + 1, e3)
	return out


# ------------------------------------------------------------------ couleurs

static func _col(look: Dictionary, key: String, fallback: String) -> Color:
	return Color.from_string(str(look.get(key, fallback)), Color.from_string(fallback, Color.GRAY))


## Rampe de cinq tons : ombre profonde, ombre, ton de base, lumière, éclat.
static func _ramp(c: Color) -> Array:
	return [PA.shade(c, -0.5), PA.shade(c, -0.26), c, PA.shade(c, 0.17), PA.shade(c, 0.36)]


## Rampe de peau : les ombres tirent vers le rose, pas vers le gris.
static func _skin_ramp(c: Color) -> Array:
	var rose := Color("#a8486e")
	return [PA.shade(c, -0.5).lerp(rose, 0.12), PA.shade(c, -0.22).lerp(rose, 0.14), c,
		PA.shade(c, 0.13), PA.shade(c, 0.28)]


static func _colors(look: Dictionary) -> Dictionary:
	var skin := _col(look, "skin", "#e8b48a")
	var boots := str(look.get("feet", "nus")) == "bottes"
	var c := {
		"skin": _skin_ramp(skin),
		"hair": _ramp(_col(look, "hair", "#6b4a2e")),
		"top": _ramp(_col(look, "top", "#4f7d5a")),
		"bottom": _ramp(_col(look, "bottom", "#6b5238")),
		"boot": _ramp(_col(look, "boots", "#4a3426")),
		"hat": _ramp(_col(look, "hat_color", "#6f7390")),
		"beard": _ramp(_col(look, "beard_color", "#d9d9e0")),
		"belt": _ramp(_col(look, "belt", "#4a3426")),
		"band": _ramp(_col(look, "band", "#b0483c")),
		"wood": _ramp(Color("#8a5a34")),
		"apron": _ramp(Color("#efe6d2")),
		"gold": _ramp(Color("#e2b43c")),
		"iron": _ramp(Color("#8a8aa0")),
		"crystal": _ramp(Color("#6fd8ee")),
		"boots": boots,
		"iris": _ramp(_col(look, "eye", "#3a2848")),
		"skin_c": skin,
	}
	if look.has("cape"):
		c["cape"] = _ramp(_col(look, "cape", "#7a2a34"))
	return c


## Pose d'une colonne de la planche.
static func _pose(col: int) -> Dictionary:
	var p := {"bob": 0, "lift_l": 0, "lift_r": 0, "stride": 0, "pass": 0, "arm": 0, "arms": "down",
		"eyes": "open", "mouth": "smile", "lean": 0}
	match col:
		1:
			p["bob"] = 1
		2:
			p["eyes"] = "closed"
		3:
			p["lift_r"] = 4
			p["stride"] = 5
			p["arm"] = 2
			p["bob"] = 1
		4:
			p["lift_r"] = 2
			p["pass"] = 1
		5:
			p["lift_l"] = 4
			p["stride"] = -5
			p["arm"] = -2
			p["bob"] = 1
		6:
			p["lift_l"] = 2
			p["pass"] = -1
		7:
			p["arms"] = "strike"
			p["lean"] = 4
			p["stride"] = 3
			p["mouth"] = "open"
			p["eyes"] = "angry"
		8:
			p["arms"] = "up"
			p["bob"] = -1
			p["mouth"] = "open"
			p["eyes"] = "closed"
		9:
			p["arms"] = "flail"
			p["lean"] = -4
			p["stride"] = -2
			p["mouth"] = "grit"
			p["eyes"] = "pain"
		10:
			# KO : affaissé, jambes repliées, tête rentrée dans les épaules
			p["lean"] = -2
			p["mouth"] = "open"
			p["eyes"] = "ko"
			p["bob"] = 4
			p["crouch"] = 3
	return p


# --------------------------------------------------------- primitives de dessin

static func _put(x: int, y: int, col: Color) -> void:
	if _flip >= 0:
		x = _flip - x
	if x >= 0 and y >= 0 and x < FRAME_W and y < FRAME_H:
		_im.set_pixel(x, y, col)


static func _pget(x: int, y: int) -> Color:
	if _flip >= 0:
		x = _flip - x
	if x >= 0 and y >= 0 and x < FRAME_W and y < FRAME_H:
		return _im.get_pixel(x, y)
	return Color(0, 0, 0, 0)


static func _rect(x: float, y: float, w: float, h: float, col: Color) -> void:
	var x0 := int(round(x))
	var y0 := int(round(y))
	for yy in range(y0, int(round(y + h))):
		for xx in range(x0, int(round(x + w))):
			_put(xx, yy, col)


static func _tone(nx: float, ny: float, bias: float = 0.0) -> int:
	var nz := sqrt(maxf(0.0, 1.0 - nx * nx - ny * ny))
	var l := nx * _lx - ny * 0.5 + nz * 0.7 + bias
	if l < -0.25:
		return 0
	if l < 0.28:
		return 1
	if l < 0.78:
		return 2
	if l < 0.94:
		return 3
	return 4


## Ellipsoïde éclairé. y_min / y_max coupent la forme (on garde y_min <= y <= y_max).
static func _ell(cx: float, cy: float, rx: float, ry: float, ramp: Array, bias: float = 0.0,
		y_max: float = 1000.0, y_min: float = -1000.0) -> void:
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		if y + 0.5 > y_max or y + 0.5 < y_min:
			continue
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			if nx * nx + ny * ny > 1.0:
				continue
			_put(x, y, ramp[_tone(nx, ny, bias)])


## Capsule éclairée d'un point à un autre (membres, mèches, manches).
static func _cap(x0: float, y0: float, x1: float, y1: float, r0: float, r1: float, ramp: Array,
		bias: float = 0.0) -> void:
	var a := Vector2(x0, y0)
	var d := Vector2(x1 - x0, y1 - y0)
	var l2 := maxf(d.length_squared(), 0.0001)
	var rm := maxf(r0, r1)
	for y in range(int(floor(minf(y0, y1) - rm)), int(ceil(maxf(y0, y1) + rm)) + 1):
		for x in range(int(floor(minf(x0, x1) - rm)), int(ceil(maxf(x0, x1) + rm)) + 1):
			var pnt := Vector2(x + 0.5, y + 0.5)
			var t := clampf((pnt - a).dot(d) / l2, 0.0, 1.0)
			var r := lerpf(r0, r1, t)
			var off := pnt - (a + d * t)
			if off.length() > r:
				continue
			_put(x, y, ramp[_tone(off.x / r, off.y / r, bias)])


## Trapèze lisse comme un tube : étoffes, corps, cônes. « folds » : Vector2(position 0..1 sur
## la largeur, départ 0..1 sur la hauteur) = plis ; hem : ourlet sombre sur la dernière ligne.
static func _trap(y0: float, y1: float, xl0: float, xr0: float, xl1: float, xr1: float, ramp: Array,
		bias: float = 0.0, folds: Array = [], hem: bool = false) -> void:
	var h := y1 - y0
	if h <= 0.0:
		return
	var last := int(round(y1)) - 1
	for y in range(int(round(y0)), int(round(y1))):
		var t := clampf((y + 0.5 - y0) / h, 0.0, 1.0)
		var xl := lerpf(xl0, xl1, t)
		var xr := lerpf(xr0, xr1, t)
		var w := xr - xl
		if w <= 0.01:
			continue
		for x in range(int(round(xl)), maxi(int(round(xr)), int(round(xl)) + 1)):
			var u := clampf(((x + 0.5 - xl) / w) * 2.0 - 1.0, -0.99, 0.99)
			var tone := _tone(u, (t * 2.0 - 1.0) * 0.35, bias)
			for f: Vector2 in folds:
				if t >= f.y:
					var fx := int(floor(xl + f.x * w))
					if x == fx:
						tone = mini(tone, 1)
					elif x == fx - 1 and tone <= 2:
						tone = 3
			if hem and y == last:
				tone = mini(tone, 1)
			_put(x, y, ramp[tone])


## Assombrit (k < 0) ou éclaircit les pixels déjà peints dans l'ellipse : ombre portée.
static func _cast(cx: float, cy: float, rx: float, ry: float, k: float) -> void:
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			if nx * nx + ny * ny > 1.0:
				continue
			var col := _pget(x, y)
			if col.a >= 0.5:
				_put(x, y, PA.shade(col, k))


static func _shade_px(x: int, y: int, k: float) -> void:
	var col := _pget(x, y)
	if col.a >= 0.5:
		_put(x, y, PA.shade(col, k))


## Même rampe, un cran plus sombre (membre ou pièce à l'arrière-plan).
static func _dim(ramp: Array) -> Array:
	return [ramp[0], ramp[0], ramp[1], ramp[2], ramp[3]]


## Contour de la couleur de la pièce voisine, assombrie et un peu violette.
static func _outline() -> void:
	var src := _im.duplicate() as Image
	for y in FRAME_H:
		for x in FRAME_W:
			if src.get_pixel(x, y).a >= 0.5:
				continue
			var sum := Color(0, 0, 0, 0)
			var n := 0
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + d.x
				var ny := y + d.y
				if nx < 0 or ny < 0 or nx >= FRAME_W or ny >= FRAME_H:
					continue
				var nc := src.get_pixel(nx, ny)
				if nc.a >= 0.5:
					sum += nc
					n += 1
			if n == 0:
				continue
			var avg := sum / float(n)
			var out := avg.darkened(0.7).lerp(Color("#1b1425"), 0.4)
			out.a = 1.0
			_im.set_pixel(x, y, out)


static func _layout(look: Dictionary) -> void:
	var lh := 11.0
	var th := 15.0
	_rx = 11.0
	_ry = 10.0
	_half = 7.0
	match str(look.get("build", "petit")):
		"grand":
			lh = 15.0
			th = 20.0
			_rx = 10.0
			_ry = 9.5
		"enfant":
			lh = 7.0
			th = 10.0
			_rx = 10.0
			_ry = 9.5
			_half = 5.5
	lh = maxf(3.0, lh - float(_p.get("crouch", 0)) * 1.5)
	_th = th
	_foot = float(FRAME_H - 1 - FOOT_MARGIN)
	_hip = _foot - lh + 1.0
	_ny = _hip - th + float(_p["bob"])
	_hcy = _ny - _ry + 3.0
	_cx = 24.0


# ------------------------------------------------------------------ face / dos

static func _front(look: Dictionary, back: bool) -> void:
	_layout(look)
	var cx := _cx
	var half := _half
	var ny := _ny
	var th := _th
	var outfit := str(look.get("outfit", "tunique"))
	var item := str(look.get("item", "none"))
	var arms := str(_p["arms"])
	var petit := str(look.get("build", "petit")) == "petit"
	var bulge := 1.6 if petit else 0.5
	var belt_y := ny + th - 4.5
	var top: Array = _c["top"]
	var bottom: Array = _c["bottom"]
	var belt: Array = _c["belt"]
	var skin: Array = _c["skin"]
	var hair_style := str(look.get("hair_style", "court"))
	var has_cape := _c.has("cape")
	var cape: Array = _c["cape"] if has_cape else top

	# cheveux longs : la masse passe derrière les épaules
	if hair_style == "long" and not back:
		_ell(cx, _hcy, _rx + 2.0, _ry + 1.5, _c["hair"], -0.3)
		_trap(_hcy, _hcy + _ry + 9.0, cx - _rx - 2.0, cx + _rx + 2.0, cx - _rx - 3.0, cx + _rx + 3.0, _c["hair"], -0.3, [Vector2(0.3, 0.2), Vector2(0.7, 0.3)], true)
	if has_cape and not back:
		_trap(ny + 1.0, _foot - 3.0, cx - half - 2.0, cx + half + 2.0, cx - half - 7.0, cx + half + 7.0, cape, -0.2,
			[Vector2(0.22, 0.1), Vector2(0.5, 0.0), Vector2(0.78, 0.1)], true)

	# jambes et pieds
	for s: int in [-1, 1]:
		var lift := float(_p["lift_l"]) if s < 0 else float(_p["lift_r"])
		_leg_front(cx + float(s) * 3.4, s, _foot - 3.0 - lift, lift)

	# le haut du corps se déhanche d'un pixel du côté du pied d'appui
	cx += float(signi(int(_p["arm"])))

	# cou
	_cap(cx, ny - 3.0, cx, ny + 1.0, 2.6, 2.6, skin)

	# torse
	match outfit:
		"tablier":
			_torso_tunic(cx, belt_y, bulge, top, belt, [Vector2(0.28, 0.0), Vector2(0.74, 0.12)], back, 2.0)
			if not back:
				var bottom_y := minf(_hip + 4.0, _foot - 6.0)
				var ap: Array = _c["apron"]
				_trap(ny + 4.0, bottom_y, cx - 4.0, cx + 4.0, cx - 6.0, cx + 6.0, ap, 0.0, [Vector2(0.5, 0.35)], true)
				_rect(cx - 3.0, belt_y + 3.0, 6.0, 4.0, ap[1])
				_rect(cx - 3.0, belt_y + 3.0, 6.0, 1.0, ap[3])
				_rect(cx - 3.0, belt_y + 6.0, 6.0, 1.0, ap[0])
				_cap(cx - 3.8, ny + 1.5, cx - 3.0, ny + 4.5, 0.9, 0.9, ap)
				_cap(cx + 3.8, ny + 1.5, cx + 3.0, ny + 4.5, 0.9, 0.9, ap)
			else:
				_cap(cx - 3.0, ny + 2.0, cx + 3.0, belt_y, 0.8, 0.8, _c["apron"])
				_cap(cx + 3.0, ny + 2.0, cx - 3.0, belt_y, 0.8, 0.8, _c["apron"])
				_ell(cx, belt_y + 1.5, 2.0, 1.6, _c["apron"])
				_trap(belt_y + 2.0, belt_y + 7.0, cx - 1.8, cx + 1.8, cx - 2.6, cx + 2.6, _c["apron"], -0.05, [], true)
		"jupe":
			_torso_blouse(cx, belt_y, top, back)
			var skirt_end := _foot - 3.0
			_trap(belt_y - 0.5, skirt_end, cx - half - 0.5, cx + half + 0.5, cx - half - 6.5, cx + half + 6.5, bottom, 0.0,
				[Vector2(0.2, 0.15), Vector2(0.36, 0.3), Vector2(0.52, 0.1), Vector2(0.68, 0.3), Vector2(0.84, 0.15)], true)
			_trap(belt_y - 0.5, belt_y + 2.0, cx - half - 0.5, cx + half + 0.5, cx - half - 0.5, cx + half + 0.5, belt)
		"robe":
			_trap(ny, _foot - 4.5, cx - half + 0.5, cx + half - 0.5, cx - half - 5.5, cx + half + 5.5, top, 0.0,
				[Vector2(0.18, 0.3), Vector2(0.38, 0.1), Vector2(0.6, 0.2), Vector2(0.8, 0.35)], true)
			_rect(cx - half - 5.5, _foot - 5.5, (half + 5.5) * 2.0, 1.0, belt[2])
			_trap(belt_y - 1.0, belt_y + 2.0, cx - half - 0.5, cx + half + 0.5, cx - half - 0.5, cx + half + 0.5, belt)
			if not back:
				_rect(cx - 1.0, belt_y - 0.5, 3.0, 3.0, _c["gold"][2])
				_put(int(cx) - 1, int(belt_y), _c["gold"][4])
				_trap(belt_y + 2.0, belt_y + 11.0, cx + 1.5, cx + 4.0, cx + 1.8, cx + 5.0, belt, 0.0, [], true)
		_:
			_torso_tunic(cx, belt_y, bulge, top, belt, [Vector2(0.28, 0.0), Vector2(0.74, 0.12)], back, 3.0)
	# cape de dos : elle recouvre tout le dos
	if has_cape and back:
		_trap(ny + 1.0, _foot - 3.0, cx - half - 1.0, cx + half + 1.0, cx - half - 7.0, cx + half + 7.0, cape, 0.0,
			[Vector2(0.2, 0.0), Vector2(0.5, 0.0), Vector2(0.8, 0.0)], true)
	# épaules arrondies (et col de la cape)
	var sh: Array = cape if has_cape else top
	_ell(cx - half + 0.5, ny + 2.4, 3.6, 3.0, sh)
	_ell(cx + half - 0.5, ny + 2.4, 3.6, 3.0, sh)
	if has_cape and not back:
		_ell(cx, ny + 1.0, half - 1.0, 2.2, cape, 0.1)
		_ell(cx, ny + 3.2, 2.3, 2.0, _c["gold"])
	elif not back and outfit != "tablier" and not has_cape:
		# encolure en V qui laisse voir la peau
		_trap(ny - 0.5, ny + 4.5, cx - 3.0, cx + 3.0, cx - 0.5, cx + 0.5, skin, -0.15)
		for i in 5:
			_put(int(cx) - 4 + int(float(i) * 0.8), int(ny) + i, top[3])
			_put(int(cx) + 3 - int(float(i) * 0.8), int(ny) + i, top[1])

	# ombre portée du menton sur le torse
	_cast(cx, _hcy + _ry + 0.5, _rx - 2.0, 3.2, -0.22)

	# bras
	var hand_r := Vector2(0, 0)
	for s: int in [-1, 1]:
		var sl := top if not has_cape else top
		var wide := outfit == "robe"
		var sx := cx + float(s) * (half + 0.5)
		var sy := ny + 2.8
		var swing := float(_p["arm"]) * float(s)
		var ex := sx + float(s)
		var hy := ny + th - 1.0 + swing * 1.2
		var hx := cx + float(s) * (half + 1.7)
		var ey := (sy + hy) * 0.5
		match arms:
			"strike":
				if s > 0:
					ex = cx + half + 5.0
					ey = ny + 1.5
					hx = cx + half + 6.0
					hy = ny - 8.0
			"up":
				ex = cx + float(s) * (half + 5.0)
				ey = ny + 1.5
				hx = cx + float(s) * (half + 7.0)
				hy = ny - 9.0
			"flail":
				ex = cx + float(s) * (half + 5.0)
				ey = ny + 4.5
				hx = cx + float(s) * (half + 8.5)
				hy = ny - 2.0
		if _p.has("crouch"):
			hy = ny + th + 1.0
		if s > 0 and item == "baton" and arms == "down":
			hx += 2.0
			ex += 1.0
		_arm(sx, sy, ex, ey, hx, hy, sl, wide)
		if s > 0:
			hand_r = Vector2(hx, hy)

	# objet tenu (main droite de l'écran)
	if item == "baton":
		_staff(hand_r.x, hand_r.y, arms, back)
	_head_front(look, cx, back, item)
	if str(look.get("hat", "none")) == "capuche" and not back:
		pass


static func _torso_tunic(cx: float, belt_y: float, bulge: float, top: Array, belt: Array, folds: Array, back: bool, flare: float) -> void:
	var half := _half
	_trap(_ny, belt_y, cx - half + 0.5, cx + half - 0.5, cx - half - bulge, cx + half + bulge, top, 0.0, folds)
	_trap(belt_y, _hip + flare, cx - half - bulge, cx + half + bulge, cx - half - bulge - 2.4, cx + half + bulge + 2.4, top, -0.04,
		[Vector2(0.3, 0.0), Vector2(0.7, 0.2)], true)
	_trap(belt_y - 1.0, belt_y + 1.5, cx - half - bulge, cx + half + bulge, cx - half - bulge, cx + half + bulge, belt)
	if not back:
		_rect(cx - 2.0, belt_y - 1.5, 4.0, 3.0, _c["gold"][2])
		_rect(cx - 2.0, belt_y - 1.5, 4.0, 1.0, _c["gold"][4])
		_rect(cx - 1.0, belt_y - 0.5, 2.0, 1.0, _c["gold"][0])
		# bourse à la ceinture
		_ell(cx + half + bulge - 1.5, belt_y + 3.5, 2.6, 2.4, belt, 0.05)


static func _torso_blouse(cx: float, belt_y: float, top: Array, back: bool) -> void:
	var half := _half
	_trap(_ny, belt_y + 0.5, cx - half + 0.5, cx + half - 0.5, cx - half - 0.5, cx + half + 0.5, top, 0.0, [Vector2(0.35, 0.0), Vector2(0.7, 0.0)])
	if not back:
		# col, petit lacet
		_rect(cx - 1.0, _ny + 1.0, 2.0, 5.0, _c["skin"][1])
		_rect(cx - 0.0, _ny + 1.0, 1.0, 5.0, _c["belt"][2])


static func _leg_front(lx: float, s: int, ay: float, lift: float) -> void:
	var bottom: Array = _c["bottom"]
	var boot: Array = _c["boot"]
	var skin: Array = _c["skin"]
	var fx := lx + float(s) * 0.6
	if bool(_c["boots"]):
		_cap(lx, _hip - 1.0, lx, ay - 5.0, 3.0, 2.8, bottom)
		_cap(lx, ay - 6.0, lx, ay, 3.4, 3.1, boot)
		_rect(lx - 3.0, ay - 6.0, 6.0, 1.0, boot[3])
		_ell(fx, ay + 0.8, 4.5, 2.7, boot)
		_rect(fx - 3.0, ay + 3.0, 7.0, 1.0, boot[0])
	else:
		_cap(lx, _hip - 1.0, lx, ay - 1.0, 3.0, 2.7, bottom)
		_ell(fx, ay + 0.8, 4.7, 2.6, skin)
		# touffe de poils de Grobitte et orteils
		var hr: Array = _c["hair"]
		_put(int(round(lx)) - 1, int(ay) - 1, hr[2])
		_put(int(round(lx)), int(ay) - 2, hr[1])
		_put(int(round(lx)) + 1, int(ay) - 1, hr[3])
		_put(int(round(fx)) - 1, int(ay) + 2, skin[1])
		_put(int(round(fx)) + 1, int(ay) + 2, skin[1])


static func _arm(sx: float, sy: float, ex: float, ey: float, hx: float, hy: float, sleeve: Array, wide: bool) -> void:
	var dir := Vector2(hx - ex, hy - ey)
	if dir.length() < 0.1:
		dir = Vector2(0, 1)
	dir = dir.normalized()
	var wx := hx - dir.x * 2.3
	var wy := hy - dir.y * 2.3
	var skin: Array = _c["skin"]
	_cap(sx, sy, ex, ey, 3.0, 2.7, sleeve)
	_cap(ex, ey, wx, wy, 2.7, 3.7 if wide else 2.4, sleeve)
	_cap(wx - dir.x * 1.0, wy - dir.y * 1.0, wx + dir.x * 0.6, wy + dir.y * 0.6, 3.2 if wide else 2.9, 3.2 if wide else 2.9, sleeve, 0.22)
	_ell(hx, hy, 2.4, 2.5, skin)
	_put(int(round(hx - 2.0)), int(round(hy + 0.5)), skin[1])


static func _staff(hx: float, hy: float, arms: String, back: bool) -> void:
	var wood: Array = _c["wood"]
	var top := hy - 36.0
	var bot := minf(_foot - 1.0, hy + 24.0)
	var tilt := 0.0
	match arms:
		"strike":
			top = hy - 16.0
			bot = hy + 7.0
			tilt = 2.0
		"up":
			top = hy - 17.0
			bot = hy + 8.0
		"flail":
			top = hy - 14.0
			bot = hy + 14.0
			tilt = 5.0
	top = maxf(top, 9.0)
	_cap(hx - tilt, top, hx + tilt, bot, 1.5, 1.5, wood)
	var tx := hx - tilt
	_ell(tx, top, 2.8, 2.4, wood)
	_cap(tx - 2.6, top + 1.0, tx - 2.4, top - 4.5, 0.8, 0.8, wood)
	_cap(tx + 2.6, top + 1.0, tx + 2.4, top - 4.5, 0.8, 0.8, wood)
	_ell(tx, top - 2.5, 2.2, 2.8, _c["crystal"], 0.1)
	_put(int(round(tx - 1.0)), int(round(top - 3.5)), WHITE)
	if arms == "up":
		_put(int(round(tx)) - 5, int(round(top)) - 4, WHITE)
		_put(int(round(tx)) + 5, int(round(top)) - 6, Color("#a8f4ff"))
		_put(int(round(tx)) + 4, int(round(top)) - 1, WHITE)
	var skin: Array = _c["skin"]
	_ell(hx, hy, 2.4, 2.5, skin)
	_put(int(round(hx)), int(round(hy)) - 1, skin[1])


# ------------------------------------------------------------------------ tête

static func _head_front(look: Dictionary, cx: float, back: bool, item: String) -> void:
	var hcy := _hcy
	var rx := _rx
	var ry := _ry
	var skin: Array = _c["skin"]
	var hat := str(look.get("hat", "none"))
	var hair_style := str(look.get("hair_style", "court"))
	if hat == "capuche":
		_hood_back(cx, hcy, rx, ry, 0)
	if hair_style == "boucles" or hair_style == "chignon":
		_hair_volume(cx, hcy, rx, ry, hair_style, 0, back)
	# oreilles un peu pointues
	for s: int in [-1, 1]:
		_ell(cx + float(s) * (rx - 0.2), hcy + 1.5, 2.3, 3.0, skin)
		_put(int(round(cx + float(s) * (rx + 1.4) - 0.5)), int(hcy) - 2, skin[2])
		_put(int(round(cx + float(s) * (rx + 0.6) - 0.5)), int(hcy) - 1, skin[2])
		_put(int(round(cx + float(s) * (rx - 0.2) - 0.5)), int(hcy) + 2, skin[1])
	_ell(cx, hcy, rx, ry, skin)
	if not back:
		_face(look, cx, hcy, rx, ry)
	if str(look.get("beard", "none")) != "none":
		_beard_front(look, cx, hcy, rx, ry, back)
	if not back and str(look.get("beard", "none")) != "moustache":
		_mouth(cx, hcy + 7.0, str(_p["mouth"]), false)
	elif not back:
		_mouth(cx, hcy + 7.0, str(_p["mouth"]), true)
	_hair(cx, hcy, rx, ry, hair_style, 0 if not back else 2)
	if str(look.get("ears", "")) == "elfe":
		for s: int in [-1, 1]:
			_cap(cx + float(s) * (rx + 1.0), hcy + 2.0, cx + float(s) * (rx + 6.0), hcy - 4.0, 1.8, 0.5, skin)
	if item == "pipe" and not back:
		var my := hcy + 8.0
		_cap(cx + 2.5, my + 0.5, cx + 7.0, my - 0.5, 0.9, 0.9, _c["wood"])
		_ell(cx + 8.0, my - 1.8, 2.3, 2.6, _c["wood"])
		_rect(cx + 6.8, my - 4.4, 2.5, 1.0, Color("#3a2410"))
		_put(int(cx) + 8, int(my) - 7, Color(0.85, 0.85, 0.9, 0.9))
		_put(int(cx) + 9, int(my) - 9, Color(0.8, 0.8, 0.88, 0.8))
	_hat(look, cx, hcy, rx, ry, hat, 0 if not back else 2)


static func _face(look: Dictionary, cx: float, hcy: float, rx: float, ry: float) -> void:
	var skin: Array = _c["skin"]
	var hr: Array = _c["hair"]
	var ey := int(hcy) + 1
	var mood := str(_p["eyes"])
	var fem := str(look.get("hair_style", "")) == "chignon" or str(look.get("outfit", "")) == "jupe"
	var cxi := int(cx)
	for s: int in [-1, 1]:
		var x0 := cxi - 7 if s < 0 else cxi + 4
		_eye(x0, ey, mood, s, fem)
		# sourcils
		var by := ey - 3
		match mood:
			"angry":
				for i in 4:
					var yy := by + 1 - i / 2 if s < 0 else by + 1 - (3 - i) / 2
					# l'extrémité intérieure est plus basse
					var inner := i if s < 0 else 3 - i
					_put(x0 - 1 + i, by - 1 + inner / 2 + (1 if inner > 2 else 0) + 0 * yy, hr[1])
			"pain":
				for i in 4:
					_put(x0 - 1 + i, by + (i if s > 0 else 3 - i) / 2 - 0, hr[1])
			"ko":
				pass
			_:
				for i in 4:
					var lift := 1 if (i == 0 or i == 3) else 0
					_put(x0 - 1 + i, by + lift, hr[1])
		# joues
		var rose: Color = skin[2].lerp(Color("#e0607a"), 0.5)
		_put(x0 + (0 if s < 0 else 1), ey + 5, rose)
		_put(x0 + 1 + (0 if s < 0 else 1), ey + 5, rose)
	# nez
	_put(cxi, ey + 4, skin[1])
	_put(cxi - 1, ey + 3, skin[3])
	_put(cxi, ey + 3, skin[2])


static func _eye(x0: int, ey: int, mood: String, side: int, fem: bool) -> void:
	var iris: Array = _c["iris"]
	var lash: Color = iris[0]
	match mood:
		"closed":
			_put(x0, ey + 2, lash)
			_put(x0 + 1, ey + 3, lash)
			_put(x0 + 2, ey + 2, lash)
		"pain":
			var a := x0 if side < 0 else x0 + 2
			var b := x0 + 2 if side < 0 else x0
			_put(a, ey, lash)
			_put(a + (1 if side < 0 else -1), ey + 1, lash)
			_put(b, ey + 2, lash)
			_put(a + (1 if side < 0 else -1), ey + 3, lash)
			_put(a, ey + 4, lash)
		"ko":
			for i in 3:
				_put(x0 + i, ey + 1 + i, lash)
				_put(x0 + 2 - i, ey + 1 + i, lash)
		_:
			var drop := 1 if mood == "angry" else 0
			for i in 3:
				_put(x0 + i, ey + (drop if (side < 0 and i == 2) or (side > 0 and i == 0) else 0), lash)
			_put(x0, ey + 1, iris[2])
			_put(x0 + 1, ey + 1, iris[2])
			_put(x0 + 2, ey + 1, iris[2])
			for i in 3:
				_put(x0 + i, ey + 2, iris[1] if i == 2 else iris[2])
				_put(x0 + i, ey + 3, iris[3])
			_put(x0, ey + 1, WHITE)
			_put(x0 + 2, ey + 3, iris[4])
			if fem:
				var fx := x0 - 1 if side < 0 else x0 + 3
				_put(fx, ey, lash)
				_put(fx, ey - 1, lash)
			# paupière marquée
			_put(x0 - 1 if side < 0 else x0 + 3, ey + 1, lash if mood == "angry" else _c["skin"][1])


static func _mouth(cx: float, my: float, mode: String, hidden: bool) -> void:
	var x := int(cx)
	var y := int(my)
	match mode:
		"open":
			_rect(x - 2.0, y - 1.0, 4.0, 3.0, MOUTH)
			_rect(x - 2.0, y - 1.0, 4.0, 1.0, WHITE)
			_put(x - 1, y + 1, RED)
			_put(x, y + 1, RED)
			_put(x - 2, y - 1, MOUTH)
			_put(x + 1, y - 1, MOUTH)
		"grit":
			_rect(x - 2.0, y - 1.0, 4.0, 2.0, WHITE)
			for i in 4:
				_put(x - 2 + i, y - 1, MOUTH if i % 2 == 0 else WHITE)
			_put(x - 3, y, MOUTH)
			_put(x + 2, y, MOUTH)
			_rect(x - 2.0, y + 1.0, 4.0, 1.0, MOUTH)
		_:
			if not hidden:
				_put(x - 2, y - 1, _c["skin"][1])
				_put(x - 1, y, MOUTH)
				_put(x, y, MOUTH)
				_put(x + 1, y - 1, _c["skin"][1])


# ---------------------------------------------------------------- cheveux

## Limite basse des cheveux (coordonnée y) à la distance dx du centre de la tête.
static func _fringe(style: String, dx: float, hcy: float, rx: float, ry: float, view: int) -> float:
	var base := hcy - ry * 0.30
	var adx := absf(dx)
	if view == 2:
		return hcy + ry + 8.0 if style == "long" else hcy + ry * 0.55
	if view == 1:
		if dx < -rx * 0.30:
			var jag := 1.0 if posmod(int(floor(dx)), 3) == 0 and style == "court" else 0.0
			return base + jag + (0.5 if style == "chignon" else 0.0)
		return hcy + ry + 8.0 if style == "long" else hcy + ry * 0.55
	if adx > rx * 0.80:
		return hcy + ry * 0.35
	match style:
		"court":
			return base + clampf(dx * 0.22, -1.5, 3.5) + (1.0 if posmod(int(floor(dx)), 3) == 0 else 0.0) + 1.0
		"long":
			return base + adx * 0.30 + 0.5
		"boucles":
			return base - 0.5 + sin(dx * 0.9) * 1.1 + 1.0
		_:
			return base + dx * 0.12 + 1.0


static func _hair(hx: float, hcy: float, rx: float, ry: float, style: String, view: int) -> void:
	var hr: Array = _c["hair"]
	var skin: Array = _c["skin"]
	if style == "chauve":
		# quelques mèches sur les côtés du crâne
		if view != 1:
			for s: int in [-1, 1]:
				_ell(hx + float(s) * (rx - 1.0), hcy - 1.0, 1.8, 3.2, hr)
		else:
			_ell(hx + rx - 2.0, hcy - 0.5, 2.2, 4.0, hr)
		_put(int(hx) - 4, int(hcy - ry) + 2, skin[4])
		_put(int(hx) - 3, int(hcy - ry) + 2, skin[3])
		return
	var erx := rx + 1.6
	var ery := ry + 1.4
	var ecy := hcy - 1.0
	if style == "boucles":
		erx += 0.8
		ery += 0.8
	for y in range(int(floor(ecy - ery)), int(ceil(ecy + ery)) + 1):
		for x in range(int(floor(hx - erx)), int(ceil(hx + erx)) + 1):
			var nx := (x + 0.5 - hx) / erx
			var ny := (y + 0.5 - ecy) / ery
			if nx * nx + ny * ny > 1.0:
				continue
			var dx := x + 0.5 - hx
			var lim := _fringe(style, dx, hcy, rx, ry, view)
			if y + 0.5 > lim:
				continue
			if view == 2 and style != "long" and y + 0.5 > hcy + ry * 0.55:
				continue
			var tone := _tone(nx, ny * 0.9, 0.0)
			# mèches : bandes sombres en diagonale
			var q := fposmod(dx + (y - hcy) * 0.5, 5.5)
			if q < 0.8 and tone >= 2:
				tone -= 1
			# bord de la frange : une ligne d'ombre
			if y + 1.5 > lim and view != 2:
				tone = mini(tone, 1)
			_put(x, y, hr[tone])
	# ombre de la frange sur le front
	if view != 2:
		for x in range(int(floor(hx - rx)), int(ceil(hx + rx))):
			var dx := x + 0.5 - hx
			var lim := _fringe(style, dx, hcy, rx, ry, view)
			var yy := int(ceil(lim))
			if absf(dx) < rx * 0.78:
				_shade_px(x, yy, -0.2)
	if style == "long":
		_hair_hang(hx, hcy, rx, ry, view)
	if style == "boucles" and view != 2:
		pass


## Mèches longues qui retombent devant les épaules.
static func _hair_hang(hx: float, hcy: float, rx: float, ry: float, view: int) -> void:
	var hr: Array = _c["hair"]
	if view == 0:
		for s: int in [-1, 1]:
			var x0 := hx + float(s) * (rx * 0.80 + 1.4)
			_trap(hcy + 1.0, hcy + ry + 7.0, x0 - 2.4, x0 + 2.4, x0 - 2.0, x0 + 2.0, hr, 0.0, [Vector2(0.5, 0.3)], true)
	elif view == 1:
		_trap(hcy + 2.0, hcy + ry + 8.0, hx + 1.0, hx + rx + 2.0, hx + 3.0, hx + rx + 3.0, hr, -0.1, [Vector2(0.4, 0.2), Vector2(0.75, 0.3)], true)


## Volume derrière le crâne : boucles ou chignon.
static func _hair_volume(hx: float, hcy: float, rx: float, ry: float, style: String, view: int, back: bool) -> void:
	var hr: Array = _c["hair"]
	if style == "chignon":
		var bx := hx + (3.0 if view == 1 else 0.0)
		_ell(bx, hcy - ry - 2.0, 5.0, 4.3, hr)
		_cap(bx - 3.5, hcy - ry - 1.0, bx + 3.5, hcy - ry - 1.0, 1.0, 1.0, _c["band"])
		return
	# boucles : couronne de petites touffes
	var n := 9
	for i in n:
		var a := PI * (1.08 + float(i) / float(n - 1) * 0.84) + PI
		var ang := PI + float(i) / float(n - 1) * PI
		var px := hx + cos(ang) * (rx + 1.0)
		var py := hcy - 1.0 + sin(ang) * (ry + 0.6)
		_ell(px, py, 3.5, 3.4, hr)
		if a < 0.0:
			pass
	for s: int in [-1, 1]:
		_ell(hx + float(s) * (rx + 0.2), hcy + 2.0, 2.8, 3.4, hr)


# ----------------------------------------------------------------------- barbe

static func _beard_front(look: Dictionary, cx: float, hcy: float, rx: float, ry: float, back: bool) -> void:
	if back:
		return
	var kind := str(look.get("beard", "none"))
	var br: Array = _c["beard"]
	var ey := int(hcy) + 1
	if kind == "moustache" or kind == "courte" or kind == "longue":
		# moustache : deux touffes tombantes sous le nez
		for s: int in [-1, 1]:
			_cap(cx + float(s) * 1.0, float(ey) + 5.2, cx + float(s) * 4.6, float(ey) + 6.4, 1.6, 1.1, br)
	if kind == "courte" or kind == "longue":
		for y in range(int(hcy) + 3, int(ceil(hcy + ry + 1.5))):
			for x in range(int(floor(cx - rx - 0.5)), int(ceil(cx + rx + 0.5))):
				var dx := x + 0.5 - cx
				var nx := dx / (rx + 0.5)
				var ny := (y + 0.5 - (hcy + 0.6)) / (ry + 1.2)
				if nx * nx + ny * ny > 1.0:
					continue
				var ycut := hcy + 8.0 - clampf((absf(dx) - 3.5) * 1.1, 0.0, 5.5)
				if y + 0.5 < ycut - 2.5:
					continue
				# bouche dégagée
				if absf(dx) < 3.0 and y + 0.5 > hcy + 6.5 and y + 0.5 < hcy + 9.2 and kind == "courte":
					continue
				if y + 0.5 < hcy + 6.0 and absf(dx) < 6.5:
					continue
				var tone := _tone(nx, ny, -0.05)
				if posmod(x + y, 4) == 0:
					tone = maxi(tone - 1, 0)
				_put(x, y, br[tone])
	if kind == "longue":
		# la barbe tombe sur la poitrine : peinte après coup sur le torse
		_trap(hcy + ry - 2.5, hcy + ry + 15.0, cx - rx + 2.0, cx + rx - 2.0, cx - 1.0, cx + 1.0, br, 0.0,
			[Vector2(0.3, 0.2), Vector2(0.5, 0.0), Vector2(0.7, 0.25)], false)
		_trap(hcy + ry - 6.0, hcy + ry + 0.5, cx - rx + 1.0, cx + rx - 1.0, cx - rx + 1.0, cx + rx - 1.0, br, 0.0, [], false)
		# retaille la zone de la bouche pour la dégager
		_put(int(cx) - 1, int(hcy) + 8, MOUTH)


# --------------------------------------------------------------------- chapeaux

static func _hood_back(hx: float, hcy: float, rx: float, ry: float, view: int) -> void:
	var h: Array = _c["hat"]
	var ox := 1.5 if view == 1 else 0.0
	_ell(hx + ox, hcy - 0.5, rx + 3.2, ry + 3.2, h)
	_trap(hcy + ry - 3.0, hcy + ry + 6.0, hx + ox - rx - 3.0, hx + ox + rx + 3.0, hx + ox - rx - 6.5, hx + ox + rx + 6.5, h, -0.1,
		[Vector2(0.25, 0.0), Vector2(0.75, 0.0)], true)
	# pointe de la capuche
	_cap(hx + ox, hcy - ry - 2.0, hx + ox + 2.0, hcy - ry - 5.5, 2.6, 0.8, h)


static func _hat(look: Dictionary, hx: float, hcy: float, rx: float, ry: float, kind: String, view: int) -> void:
	if kind == "none":
		return
	var h: Array = _c["hat"]
	var top_y := hcy - ry
	var skin: Array = _c["skin"]
	var band: Array = _c["band"]
	var ix := int(hx)
	match kind:
		"magicien":
			_cast(hx, top_y + 7.0, rx + 0.5, 2.4, -0.25)
			_ell(hx, top_y + 3.6, rx + 7.5, 3.1, h, 0.1)
			var xs := 1.0 if view == 1 else 0.0
			_trap(top_y - 4.0, top_y + 3.5, hx - rx + 1.5 + xs, hx + rx - 1.5 + xs, hx - rx - 0.5 + xs, hx + rx + 0.5 + xs, h, 0.0,
				[Vector2(0.35, 0.0), Vector2(0.72, 0.1)])
			_trap(top_y - 10.0, top_y - 4.0, hx - rx * 0.45 + 2.0 + xs, hx + rx * 0.45 + 2.0 + xs, hx - rx + 1.5 + xs, hx + rx - 1.5 + xs, h)
			_trap(top_y - 15.0, top_y - 10.0, hx + 5.0 + xs, hx + 5.5 + xs, hx - rx * 0.45 + 2.0 + xs, hx + rx * 0.45 + 2.0 + xs, h, -0.05)
			_trap(top_y + 0.8, top_y + 3.5, hx - rx - 0.3 + xs, hx + rx + 0.3 + xs, hx - rx - 0.6 + xs, hx + rx + 0.6 + xs, band)
			_rect(hx - 1.5 + xs, top_y + 0.5, 3.0, 3.2, _c["gold"][2])
			_rect(hx - 1.5 + xs, top_y + 0.5, 3.0, 1.0, _c["gold"][4])
			_put(ix + 1, int(top_y) - 6, _c["gold"][4])
			_put(ix - 3, int(top_y) - 3, _c["gold"][3])
			_put(ix + 4, int(top_y) - 1, _c["gold"][4])
		"toque":
			var br := hx
			_ell(br - 5.5, top_y - 4.5, 6.2, 5.8, h)
			_ell(br + 5.5, top_y - 5.0, 6.2, 5.8, h)
			_ell(br, top_y - 8.0, 7.6, 6.8, h)
			for i in 4:
				_put(ix - 7 + i * 4, int(top_y) - 1 - (i % 2), h[1])
				_put(ix - 7 + i * 4, int(top_y) - 2 - (i % 2), h[1])
			_trap(top_y - 2.0, top_y + 3.2, hx - rx - 0.3, hx + rx + 0.3, hx - rx - 0.6, hx + rx + 0.6, h, 0.05, [Vector2(0.3, 0.0), Vector2(0.55, 0.0), Vector2(0.8, 0.0)])
			_rect(hx - rx - 0.6, top_y + 2.4, (rx + 0.6) * 2.0, 1.0, h[1])
		"casquette":
			var sx := -1.0 if view == 1 else 0.0
			_ell(hx + sx * 0.0, top_y + 4.5, rx + 1.0, 6.6, h, 0.05, top_y + 5.6)
			_put(ix, int(top_y) - 2, h[4])
			_rect(hx - rx - 0.8, top_y + 5.0, (rx + 0.8) * 2.0, 1.0, h[0])
			if view == 0:
				_cast(hx, top_y + 8.0, rx - 1.0, 1.8, -0.22)
				_ell(hx, top_y + 6.4, rx - 0.5, 2.3, h, -0.12)
				_rect(hx - rx + 1.0, top_y + 7.9, (rx - 1.0) * 2.0, 1.0, h[0])
			elif view == 1:
				_cast(hx - rx, top_y + 7.5, 6.0, 1.8, -0.2)
				_ell(hx - rx - 1.5, top_y + 6.2, 6.0, 2.0, h, -0.12)
				_rect(hx - rx - 7.0, top_y + 7.5, 11.0, 1.0, h[0])
			else:
				_rect(hx - 3.0, top_y + 3.0, 6.0, 1.0, h[1])
		"capuche":
			_hood_front(hx, hcy, rx, ry, view)
		"chapeau_paille":
			_cast(hx, top_y + 8.5, rx + 1.0, 2.2, -0.26)
			var brim_cy := top_y + 4.6
			for y in range(int(floor(brim_cy - 3.8)), int(ceil(brim_cy + 3.8)) + 1):
				for x in range(int(floor(hx - rx - 8.8)), int(ceil(hx + rx + 8.8)) + 1):
					var nx := (x + 0.5 - hx) / (rx + 8.8)
					var ny := (y + 0.5 - brim_cy) / 3.8
					if nx * nx + ny * ny > 1.0:
						continue
					var tone := 2 if ny < 0.35 else 1
					if ny > 0.8:
						tone = 0
					elif nx < -0.45 and ny < 0.0:
						tone = 3
					if posmod(x + y * 2, 4) == 0 and tone > 0:
						tone = maxi(tone - 1, 1)
					_put(x, y, h[tone])
			# calotte
			for y in range(int(floor(top_y - 5.0)), int(ceil(top_y + 4.6))):
				for x in range(int(floor(hx - rx)), int(ceil(hx + rx))):
					var nx := (x + 0.5 - hx) / (rx - 0.6)
					var ny := (y + 0.5 - (top_y + 4.0)) / 8.6
					if nx * nx + ny * ny > 1.0:
						continue
					var is_band := y + 0.5 >= top_y + 1.8
					var rr: Array = band if is_band else h
					var tone := _tone(nx, ny * 0.6, 0.0)
					if not is_band and posmod(x + y, 3) == 0 and tone > 1:
						tone -= 1
					_put(x, y, rr[tone])
			_ell(hx + rx - 2.5, top_y + 2.6, 2.2, 2.0, band, 0.1)
			_cap(hx + rx - 2.0, top_y + 3.5, hx + rx, top_y + 6.5, 0.9, 0.7, band)
		"couronne":
			_trap(top_y - 0.5, top_y + 3.5, hx - rx * 0.78, hx + rx * 0.78, hx - rx * 0.86, hx + rx * 0.86, _c["gold"])
			var g: Array = _c["gold"]
			var n := 5
			for i in n:
				var px := hx - rx * 0.75 + float(i) * (rx * 1.5 / float(n - 1))
				var hgt := 5.0 if i % 2 == 0 else 3.0
				_trap(top_y - 0.5 - hgt, top_y - 0.4, px - 0.4, px + 0.4, px - 1.8, px + 1.8, g)
				_put(int(round(px)), int(round(top_y - 1.0 - hgt)), g[4])
			var gem: Array = _c["band"]
			_put(ix - 1, int(top_y) + 1, gem[3])
			_put(ix, int(top_y) + 1, gem[2])
			_put(ix - 1, int(top_y) + 2, gem[2])
			_put(ix, int(top_y) + 2, gem[1])
			_put(ix - 5, int(top_y) + 1, WHITE)
			_put(ix + 4, int(top_y) + 2, gem[4])
		"heaume":
			var dome_top := top_y - 1.5
			_ell(hx, hcy - 1.5, rx + 1.2, ry + 1.0, h, 0.0, hcy - 1.0)
			_rect(hx - rx - 1.0, hcy - 2.0, (rx + 1.0) * 2.0, 2.0, h[1])
			_rect(hx - rx - 1.0, hcy - 2.0, (rx + 1.0) * 2.0, 1.0, h[3])
			if view == 0:
				_trap(hcy - 1.0, hcy + 7.0, hx - 1.4, hx + 1.4, hx - 1.2, hx + 1.2, h, 0.1)
				for s: int in [-1, 1]:
					_trap(hcy - 1.0, hcy + ry - 3.0, hx + float(s) * (rx - 1.5) - 1.0, hx + float(s) * (rx - 1.5) + 1.0, hx + float(s) * (rx - 1.8) - 1.0, hx + float(s) * (rx - 1.8) + 1.0, h, -0.1)
				_put(ix - 6, int(hcy) - 4, WHITE)
				_put(ix + 5, int(hcy) - 4, h[4])
			elif view == 1:
				_trap(hcy - 1.0, hcy + 6.0, hx - rx + 0.5, hx - rx + 2.5, hx - rx + 1.0, hx - rx + 2.8, h, 0.1)
				_trap(hcy - 1.0, hcy + ry - 1.0, hx + 1.0, hx + 5.5, hx + 1.0, hx + 5.5, h, -0.1)
			if str(look.get("crest", "")) == "cornes":
				for s: int in [-1, 1]:
					_cap(hx + float(s) * (rx - 1.0), dome_top + 4.0, hx + float(s) * (rx + 4.0), dome_top - 4.0, 2.4, 0.8, h)
					_cap(hx + float(s) * (rx + 4.0), dome_top - 4.0, hx + float(s) * (rx + 2.0), dome_top - 9.0, 0.9, 0.5, h, 0.1)
			else:
				_trap(dome_top - 3.0, dome_top + 1.5, hx - 0.8, hx + 0.8, hx - 2.2, hx + 2.2, band)
		"foulard":
			_cast(hx, top_y + 8.0, rx, 1.8, -0.18)
			_ell(hx, top_y + 5.0, rx + 0.9, 6.6, h, 0.0, top_y + 6.5)
			_rect(hx - rx - 0.8, top_y + 5.8, (rx + 0.8) * 2.0, 1.0, h[1])
			for i in 5:
				_put(ix - 8 + i * 4 + (i % 2) * 2, int(top_y) + 2 + (i % 2) * 2, h[4])
			var kx := hx + rx - 0.5 if view != 1 else hx + rx + 0.5
			_ell(kx, top_y + 6.0, 3.0, 2.6, h)
			_trap(top_y + 7.0, top_y + 13.0, kx - 2.2, kx + 0.8, kx - 1.0, kx + 3.2, h, 0.0, [], true)
			_trap(top_y + 7.0, top_y + 11.0, kx - 2.8, kx - 0.5, kx - 3.8, kx - 1.5, h, -0.1, [], true)


static func _hood_front(hx: float, hcy: float, rx: float, ry: float, view: int) -> void:
	var h: Array = _c["hat"]
	if view == 2:
		_ell(hx, hcy - 0.5, rx + 2.6, ry + 2.4, h, 0.0)
		_rect(hx - 0.5, hcy - ry - 2.0, 1.0, ry * 2.0 + 2.0, h[1])
		return
	var ox := -3.5 if view == 1 else 0.0
	var ocx := hx + (1.5 if view == 1 else 0.0)
	var orx := rx + 2.6
	var ory := ry + 2.4
	var icx := hx + ox
	var irx := rx * 0.8 if view == 1 else rx - 0.6
	var iry := ry * 0.86
	for y in range(int(floor(hcy - 0.8 - ory)), int(ceil(hcy - 0.8 + ory)) + 1):
		for x in range(int(floor(ocx - orx)), int(ceil(ocx + orx)) + 1):
			var nx := (x + 0.5 - ocx) / orx
			var ny := (y + 0.5 - (hcy - 0.8)) / ory
			if nx * nx + ny * ny > 1.0:
				continue
			var ix := (x + 0.5 - icx) / irx
			var iy := (y + 0.5 - (hcy + 1.3)) / iry
			var d := ix * ix + iy * iy
			if d <= 1.0:
				continue
			var tone := _tone(nx, ny, 0.0)
			if d < 1.35:
				tone = mini(tone, 1)
			if d < 1.12:
				tone = 0
			_put(x, y, h[tone])


# ----------------------------------------------------------------------- profil

## Profil tourné vers la gauche.
static func _side(look: Dictionary) -> void:
	_layout(look)
	var cx := _cx
	var ny := _ny
	var th := _th
	var outfit := str(look.get("outfit", "tunique"))
	var item := str(look.get("item", "none"))
	var arms := str(_p["arms"])
	var lean := float(_p["lean"])
	var hs := _half - 1.5
	var tx := cx - lean * 0.5
	var petit := str(look.get("build", "petit")) == "petit"
	var belt_y := ny + th - 4.5
	var top: Array = _c["top"]
	var skin: Array = _c["skin"]
	var has_cape := _c.has("cape")
	var stride := float(_p["stride"])
	var pas := float(_p["pass"])

	if str(look.get("hair_style", "")) == "long":
		_ell(tx + 3.0, _hcy, _rx + 1.0, _ry + 1.5, _c["hair"], -0.3)
	if has_cape:
		_trap(ny + 1.0, _foot - 3.0, tx + 1.0, tx + hs + 3.0, tx + 3.0, tx + hs + 11.0, _c["cape"], -0.1, [Vector2(0.4, 0.1), Vector2(0.75, 0.2)], true)

	# bras éloigné, caché par le torse
	var swing := float(_p["arm"]) * 2.0
	var far_hand := Vector2(tx - swing, ny + th - 1.0)
	var far_el := Vector2(tx - swing * 0.5 + 1.0, ny + th * 0.5 + 1.0)
	match arms:
		"strike":
			far_hand = Vector2(tx + 4.0, ny + th - 2.0)
			far_el = Vector2(tx + 3.0, ny + th * 0.5)
		"up":
			far_hand = Vector2(tx - 2.0, ny - 9.0)
			far_el = Vector2(tx - 1.0, ny + 0.0)
		"flail":
			far_hand = Vector2(tx - 9.0, ny + 2.0)
			far_el = Vector2(tx - 6.0, ny + 4.0)
	if _p.has("crouch"):
		far_hand = Vector2(tx, ny + th + 1.0)
	_arm(tx + 1.0, ny + 2.8, far_el.x, far_el.y, far_hand.x, far_hand.y, _dim(top), outfit == "robe")

	# jambes : la jambe proche est celle de droite dans les poses de marche
	for near: bool in [false, true]:
		var lift := float(_p["lift_r"]) if near else float(_p["lift_l"])
		var fxx := cx - stride - pas * 1.0 if near else cx + stride + pas * 1.0
		_leg_side(cx + 0.5, fxx, _foot - 3.0 - lift, near)

	_cap(tx, ny - 3.0, tx, ny + 1.0, 2.6, 2.6, skin)
	# torse
	var belly := 1.8 if petit else 0.5
	match outfit:
		"robe":
			_trap(ny, _foot - 4.5, tx - hs + 0.5, tx + hs - 0.5, tx - hs - 3.0, tx + hs + 5.0, top, 0.0, [Vector2(0.35, 0.3), Vector2(0.6, 0.15), Vector2(0.82, 0.3)], true)
			_rect(tx - hs - 3.0, _foot - 5.5, hs * 2.0 + 8.0, 1.0, _c["belt"][2])
			_trap(belt_y - 1.0, belt_y + 2.0, tx - hs - belly, tx + hs, tx - hs - belly, tx + hs, _c["belt"])
			_trap(belt_y + 2.0, belt_y + 11.0, tx + hs - 3.0, tx + hs - 0.5, tx + hs - 2.0, tx + hs + 1.5, _c["belt"], 0.0, [], true)
		"jupe":
			_trap(ny, belt_y + 0.5, tx - hs + 0.5, tx + hs - 0.5, tx - hs - belly, tx + hs, top, 0.0, [Vector2(0.5, 0.2)])
			_trap(belt_y - 0.5, _foot - 3.0, tx - hs - 0.5, tx + hs, tx - hs - 5.5, tx + hs + 5.0, _c["bottom"], 0.0, [Vector2(0.3, 0.2), Vector2(0.55, 0.1), Vector2(0.8, 0.3)], true)
			_trap(belt_y - 0.5, belt_y + 2.0, tx - hs - belly, tx + hs, tx - hs - belly, tx + hs, _c["belt"])
		_:
			_trap(ny, belt_y, tx - hs + 0.5, tx + hs - 0.5, tx - hs - belly, tx + hs, top, 0.0, [Vector2(0.55, 0.2)])
			_trap(belt_y, _hip + 3.0, tx - hs - belly, tx + hs, tx - hs - belly - 1.8, tx + hs + 2.0, top, -0.04, [Vector2(0.4, 0.0), Vector2(0.75, 0.2)], true)
			_trap(belt_y - 1.0, belt_y + 1.5, tx - hs - belly, tx + hs, tx - hs - belly, tx + hs, _c["belt"])
			_rect(tx - hs - belly - 0.5, belt_y - 1.5, 3.0, 3.0, _c["gold"][2])
			_rect(tx - hs - belly - 0.5, belt_y - 1.5, 3.0, 1.0, _c["gold"][4])
			if outfit == "tablier":
				var ap: Array = _c["apron"]
				_trap(ny + 4.0, minf(_hip + 4.0, _foot - 6.0), tx - hs - belly - 1.0, tx - hs + 2.0, tx - hs - belly - 2.5, tx - hs + 2.5, ap, 0.0, [], true)
	_ell(tx - 0.5, ny + 2.6, 3.6, 3.0, top if not has_cape else _c["cape"])
	_cast(tx - 1.0, _hcy + _ry + 0.5, _rx - 2.0, 3.2, -0.22)

	# bras proche
	var nh := Vector2(tx + swing, ny + th - 1.0)
	var ne := Vector2(tx + swing * 0.5 + 1.0, ny + th * 0.5 + 1.0)
	match arms:
		"strike":
			ne = Vector2(tx - 5.0, ny + 3.0)
			nh = Vector2(tx - 11.0, ny - 5.0)
		"up":
			ne = Vector2(tx - 4.0, ny - 1.0)
			nh = Vector2(tx - 5.0, ny - 10.0)
		"flail":
			ne = Vector2(tx + 5.0, ny + 3.0)
			nh = Vector2(tx + 10.0, ny - 4.0)
	if _p.has("crouch"):
		nh = Vector2(tx + 1.0, ny + th + 2.0)
	_arm(tx - 0.5, ny + 2.8, ne.x, ne.y, nh.x, nh.y, top, outfit == "robe")
	if item == "baton":
		_staff(nh.x, nh.y, arms, false)
	_head_side(look, tx - 1.0, item)


static func _leg_side(hx: float, fx: float, ay: float, near: bool) -> void:
	var bottom: Array = _c["bottom"] if near else _dim(_c["bottom"])
	var boot: Array = _c["boot"] if near else _dim(_c["boot"])
	var skin: Array = _c["skin"] if near else _dim(_c["skin"])
	if bool(_c["boots"]):
		_cap(hx, _hip - 1.0, fx, ay - 5.0, 3.2, 2.9, bottom)
		_cap(fx, ay - 6.0, fx, ay, 3.4, 3.2, boot)
		_rect(fx - 3.0, ay - 6.0, 6.0, 1.0, boot[3])
		_ell(fx - 1.8, ay + 0.9, 5.6, 2.7, boot)
		_rect(fx - 6.0, ay + 3.0, 8.0, 1.0, boot[0])
	else:
		_cap(hx, _hip - 1.0, fx, ay - 1.0, 3.2, 2.8, bottom)
		_ell(fx - 1.8, ay + 0.9, 5.6, 2.6, skin)
		var hr: Array = _c["hair"]
		_put(int(round(fx)) - 1, int(ay) - 1, hr[2])
		_put(int(round(fx)), int(ay) - 2, hr[1])
		_put(int(round(fx)) - 5, int(ay) + 2, skin[1])
		_put(int(round(fx)) - 3, int(ay) + 2, skin[1])


static func _head_side(look: Dictionary, hx: float, item: String) -> void:
	var hcy := _hcy
	var rx := _rx * 0.92
	var ry := _ry
	var skin: Array = _c["skin"]
	var hat := str(look.get("hat", "none"))
	var hair_style := str(look.get("hair_style", "court"))
	var mood := str(_p["eyes"])
	if hat == "capuche":
		_hood_back(hx, hcy, rx, ry, 1)
	if hair_style == "boucles" or hair_style == "chignon":
		_hair_volume(hx, hcy, rx, ry, hair_style, 1, false)
	_ell(hx, hcy, rx, ry, skin)
	# nez
	_ell(hx - rx - 0.3, hcy + 3.0, 2.0, 2.0, skin)
	_put(int(round(hx - rx)) - 2, int(hcy) + 4, skin[1])
	# oreille
	_ell(hx + rx * 0.22, hcy + 1.8, 2.2, 3.1, skin)
	_put(int(round(hx + rx * 0.22 + 1.0)), int(hcy) - 2, skin[2])
	_put(int(round(hx + rx * 0.22)), int(hcy) + 2, skin[1])
	# œil
	var ex := int(round(hx - rx * 0.52)) - 1
	var ey := int(hcy) + 1
	var iris: Array = _c["iris"]
	var hr: Array = _c["hair"]
	var fem := hair_style == "chignon" or str(look.get("outfit", "")) == "jupe"
	match mood:
		"closed":
			_put(ex, ey + 2, iris[0])
			_put(ex + 1, ey + 3, iris[0])
			_put(ex + 2, ey + 2, iris[0])
		"pain":
			_put(ex + 2, ey, iris[0])
			_put(ex + 1, ey + 1, iris[0])
			_put(ex, ey + 2, iris[0])
			_put(ex + 1, ey + 3, iris[0])
			_put(ex + 2, ey + 4, iris[0])
		"ko":
			for i in 3:
				_put(ex + i, ey + 1 + i, iris[0])
				_put(ex + 2 - i, ey + 1 + i, iris[0])
		_:
			_put(ex, ey, iris[0])
			_put(ex + 1, ey, iris[0])
			_put(ex + 2, ey + (1 if mood == "angry" else 0), iris[0])
			for yy in 3:
				_put(ex, ey + 1 + yy, iris[2] if yy < 2 else iris[3])
				_put(ex + 1, ey + 1 + yy, iris[2] if yy < 2 else iris[3])
			_put(ex, ey + 1, WHITE)
			if fem:
				_put(ex + 3, ey, iris[0])
				_put(ex + 3, ey - 1, iris[0])
	for i in 3:
		_put(ex - 1 + i, ey - 3 + (1 if mood == "angry" and i == 2 else 0) + (0 if i > 0 else 1), hr[1])
	_put(ex + 1, ey + 5, skin[2].lerp(Color("#e0607a"), 0.5))
	_put(ex + 2, ey + 5, skin[2].lerp(Color("#e0607a"), 0.5))
	# bouche
	var mx := int(round(hx - rx)) + 2
	var my := int(hcy) + 8
	var hidden := str(look.get("beard", "none")) == "moustache"
	match str(_p["mouth"]):
		"open":
			_rect(mx - 1.0, my - 1.0, 3.0, 3.0, MOUTH)
			_put(mx - 1, my - 1, WHITE)
			_put(mx, my - 1, WHITE)
			_put(mx, my + 1, RED)
		"grit":
			_rect(mx - 1.0, my - 1.0, 3.0, 2.0, WHITE)
			_put(mx - 2, my, MOUTH)
			_rect(mx - 1.0, my + 1.0, 3.0, 1.0, MOUTH)
		_:
			if not hidden:
				_put(mx - 1, my, MOUTH)
				_put(mx, my, MOUTH)
				_put(mx + 1, my - 1, skin[1])
	if str(look.get("beard", "none")) != "none":
		_beard_side(look, hx, hcy, rx, ry)
	_hair(hx, hcy, rx, ry, hair_style, 1)
	if item == "pipe":
		_cap(hx - rx - 1.0, my + 0.5, hx - rx - 5.5, my - 0.5, 0.9, 0.9, _c["wood"])
		_ell(hx - rx - 6.5, my - 1.8, 2.3, 2.6, _c["wood"])
		_put(int(hx - rx) - 7, int(my) - 6, Color(0.85, 0.85, 0.9, 0.9))
		_put(int(hx - rx) - 6, int(my) - 8, Color(0.8, 0.8, 0.88, 0.8))
	_hat(look, hx, hcy, rx, ry, hat, 1)


static func _beard_side(look: Dictionary, hx: float, hcy: float, rx: float, ry: float) -> void:
	var kind := str(look.get("beard", "none"))
	var br: Array = _c["beard"]
	_cap(hx - rx + 1.5, hcy + 6.2, hx - rx + 5.5, hcy + 7.0, 1.5, 1.1, br)
	if kind == "moustache":
		return
	for y in range(int(hcy) + 3, int(ceil(hcy + ry + 1.5))):
		for x in range(int(floor(hx - rx - 0.5)), int(ceil(hx + rx * 0.2))):
			var nx := (x + 0.5 - hx) / (rx + 0.5)
			var ny := (y + 0.5 - (hcy + 0.6)) / (ry + 1.2)
			if nx * nx + ny * ny > 1.0:
				continue
			if (y + 0.5 < hcy + 6.0 and x + 0.5 < hx - rx * 0.1):
				continue
			if kind == "courte" and x + 0.5 < hx - rx + 4.5 and y + 0.5 > hcy + 6.5 and y + 0.5 < hcy + 9.2:
				continue
			var tone := _tone(nx, ny, -0.05)
			if posmod(x + y, 4) == 0:
				tone = maxi(tone - 1, 0)
			_put(x, y, br[tone])
	if kind == "longue":
		_trap(hcy + ry - 2.0, hcy + ry + 15.0, hx - rx + 1.0, hx + 1.0, hx - rx + 5.0, hx - 3.0, br, 0.0, [Vector2(0.35, 0.2), Vector2(0.65, 0.3)])


# ------------------------------------------------------------------- Morfales

static func _morfale(look: Dictionary, view: int) -> void:
	var cx := 24.0
	var fat := str(look.get("outfit", "")) == "tablier"
	var bob := float(_p["bob"])
	var lean := float(_p["lean"])
	var arms := str(_p["arms"])
	var crouch := float(_p.get("crouch", 0))
	var foot := float(FRAME_H - 1 - FOOT_MARGIN)
	var hip := foot - 9.0 + crouch
	var shoulder_y := hip - 20.0 + bob
	var half := 10.5 if fat else 9.0
	var skin: Array = _c["skin"]
	var top: Array = _c["top"]
	var belt: Array = _c["belt"]
	var bottom: Array = _c["bottom"]
	var boot: Array = _c["boot"]
	var tusk := _ramp(Color("#f0e6c8"))
	var maw := Color("#3a1420")
	var yellow := Color("#f2d24a")
	var stride := float(_p["stride"])
	var side := view == 1
	var dx := -lean * 0.4 if side else 0.0

	# jambes courtes et arquées
	for s: int in [-1, 1]:
		var lift := float(_p["lift_l"]) if s < 0 else float(_p["lift_r"])
		var lx := cx + float(s) * 5.0
		var fx := lx
		if side:
			var near := s > 0
			lx = cx
			fx = cx - stride if near else cx + stride
			if not near:
				lift = float(_p["lift_l"])
		var ay := foot - 3.0 - lift
		var br: Array = boot if (not side or s > 0) else _dim(boot)
		var pr: Array = bottom if (not side or s > 0) else _dim(bottom)
		_cap(lx, hip - 2.0, fx + (float(s) * 0.0 if side else float(s) * 1.5), ay - 4.0, 3.8, 3.2, pr)
		_cap(fx + (0.0 if side else float(s) * 1.5), ay - 5.0, fx + (0.0 if side else float(s) * 1.5), ay, 3.8, 3.5, br)
		_ell(fx + (-2.0 if side else float(s) * 2.0), ay + 0.8, 5.2 if not side else 6.0, 2.8, br)

	# bras éloigné (profil)
	if side:
		_morfale_arm(cx + 2.0 + dx, shoulder_y + 3.0, arms, 1, false, _dim(top), skin)

	# torse en poire, voûté
	var bw := half * (1.0 if not side else 0.78)
	_ell(cx + dx, shoulder_y + 9.0, bw + (2.5 if fat else 0.5), 11.0, top, 0.0)
	_trap(shoulder_y + 2.0, hip, cx + dx - bw, cx + dx + bw, cx + dx - bw - 1.5, cx + dx + bw + 1.5, top, 0.0, [Vector2(0.3, 0.2), Vector2(0.72, 0.1)])
	_trap(hip - 4.0, hip - 1.0, cx + dx - bw - 1.5, cx + dx + bw + 1.5, cx + dx - bw - 1.5, cx + dx + bw + 1.5, belt)
	if view != 2:
		_rect(cx + dx - 2.0 - (4.0 if side else 0.0), hip - 4.0, 4.0, 3.0, _c["gold"][2])
		_rect(cx + dx - 2.0 - (4.0 if side else 0.0), hip - 4.0, 4.0, 1.0, _c["gold"][4])
	if view == 0:
		if fat:
			var ap: Array = _c["apron"]
			_trap(shoulder_y + 5.0, hip + 4.0, cx - 6.0, cx + 6.0, cx - 7.5, cx + 7.5, ap, 0.0, [Vector2(0.5, 0.4)], true)
			_put(int(cx) - 2, int(shoulder_y) + 12, Color("#a8846a"))
			_put(int(cx) + 2, int(shoulder_y) + 15, Color("#8a6a3a"))
			_rect(cx - 3.0, shoulder_y + 9.0, 5.0, 4.0, ap[1])
		else:
			# plastron de cuir clouté
			_trap(shoulder_y + 3.0, shoulder_y + 12.0, cx - 6.0, cx + 6.0, cx - 5.0, cx + 5.0, belt, 0.0, [], true)
			for i in 3:
				_put(int(cx) - 4 + i * 3, int(shoulder_y) + 5, _c["gold"][4])
				_put(int(cx) - 3 + i * 3, int(shoulder_y) + 9, _c["gold"][3])
	# épaules massives
	_ell(cx + dx - bw + 0.5, shoulder_y + 3.0, 4.6, 4.0, top)
	_ell(cx + dx + bw - 0.5, shoulder_y + 3.0, 4.6, 4.0, top)

	# tête basse, entre les épaules
	var hx := cx + (dx - lean * 0.3 - 3.0 if side else 0.0)
	var hcy := shoulder_y - 3.0
	var hrx := 9.5 if not side else 8.6
	var hry := 8.0
	var shut := str(_p["eyes"]) == "closed" or str(_p["eyes"]) == "pain" or str(_p["eyes"]) == "ko"
	var hat := str(look.get("hat", "none"))
	if hat == "capuche":
		_hood_back(hx, hcy, hrx, hry, 1 if side else 0)
	# oreilles en pointe
	if not side:
		for s: int in [-1, 1]:
			_cap(hx + float(s) * (hrx - 1.0), hcy, hx + float(s) * (hrx + 4.0), hcy - 3.5, 2.2, 0.7, skin)
	else:
		_cap(hx + hrx - 3.0, hcy + 0.0, hx + hrx + 2.5, hcy - 4.0, 2.2, 0.7, skin)
	_ell(hx, hcy, hrx, hry, skin)
	if view == 0:
		# arcade lourde, petits yeux jaunes, mâchoire carrée et défenses
		_rect(hx - hrx + 2.0, hcy - 2.0, (hrx - 2.0) * 2.0, 1.0, skin[0])
		for s: int in [-1, 1]:
			var ex := int(hx) + (-5 if s < 0 else 2)
			if shut:
				_rect(ex, hcy - 0.5, 3.0, 1.0, skin[0])
			else:
				_rect(ex, hcy - 1.0, 3.0, 3.0, yellow)
				_put(ex + 1, int(hcy), Color("#1b1425"))
				_put(ex + 1, int(hcy) + 1, Color("#1b1425"))
				_put(ex, int(hcy) - 1, WHITE)
		_put(int(hx) - 1, int(hcy) + 2, skin[0])
		_put(int(hx), int(hcy) + 2, skin[0])
		_rect(hx - 5.0, hcy + 4.0, 10.0, 3.0, maw)
		_rect(hx - 5.0, hcy + 4.0, 10.0, 1.0, skin[1])
		for s: int in [-1, 1]:
			var tx := hx + float(s) * 4.0
			_trap(hcy + 1.5, hcy + 7.0, tx - 1.0, tx + 1.0, tx - 0.6, tx + 0.6, tusk)
		if str(_p["mouth"]) == "open":
			_rect(hx - 3.0, hcy + 5.0, 6.0, 2.0, maw)
			_rect(hx - 1.5, hcy + 6.0, 3.0, 1.0, RED)
	elif view == 1:
		_rect(hx - hrx + 2.0, hcy - 2.0, 7.0, 1.0, skin[0])
		var ex := int(hx - hrx * 0.5) - 1
		if shut:
			_rect(ex, hcy - 0.5, 3.0, 1.0, skin[0])
		else:
			_rect(ex, hcy - 1.0, 3.0, 3.0, yellow)
			_put(ex, int(hcy), Color("#1b1425"))
			_put(ex, int(hcy) + 1, Color("#1b1425"))
		_ell(hx - hrx - 0.5, hcy + 3.0, 2.2, 2.0, skin)
		_rect(hx - hrx + 1.0, hcy + 4.0, 8.0, 3.0, maw)
		_trap(hcy + 1.5, hcy + 7.0, hx - hrx + 2.0, hx - hrx + 4.0, hx - hrx + 2.4, hx - hrx + 3.8, tusk)
	if hat != "none" and hat != "capuche":
		_hat(look, hx, hcy, hrx, hry, hat, 0 if view != 1 else 1)
	elif hat == "capuche":
		_hood_front(hx, hcy, hrx, hry, view)
	# bras proches (peints après la tête pour les poses levées)
	if side:
		_morfale_arm(cx - 1.0 + dx, shoulder_y + 3.0, arms, 1, true, top, skin)
	else:
		for s: int in [-1, 1]:
			_morfale_arm(cx + dx + float(s) * (bw + 0.5), shoulder_y + 3.0, arms, s, true, top, skin)


static func _morfale_arm(sx: float, sy: float, arms: String, s: int, near: bool, sleeve: Array, skin: Array) -> void:
	var swing := float(_p["arm"]) * float(s)
	var hx := sx + float(s) * 3.0
	var hy := sy + 17.0 + swing * 1.2
	var ex := sx + float(s) * 3.5
	var ey := sy + 8.0
	match arms:
		"strike":
			if s > 0:
				hx = sx + float(s) * 5.0 - (6.0 if _is_side_arm(s) else 0.0)
				hy = sy - 8.0
				ex = sx + float(s) * 6.0
				ey = sy + 1.0
		"up":
			hx = sx + float(s) * 6.0
			hy = sy - 10.0
			ex = sx + float(s) * 7.5
			ey = sy - 1.0
		"flail":
			hx = sx + float(s) * 8.0
			hy = sy - 3.0
			ex = sx + float(s) * 7.5
			ey = sy + 4.0
	if _p.has("crouch"):
		hy = sy + 18.0
	hx = clampf(hx, 8.0, 40.0)
	_cap(sx, sy, ex, ey, 4.2, 3.8, sleeve)
	_cap(ex, ey, hx, hy - 2.0, 3.8, 3.6, skin)
	_ell(hx, hy, 3.6, 3.4, skin)
	# jointures
	_put(int(round(hx)) - 1, int(round(hy)) + 2, skin[0])
	_put(int(round(hx)) + 1, int(round(hy)) + 2, skin[0])


static func _is_side_arm(_s: int) -> bool:
	return false


# ------------------------------------------------------------------------ Naze

static func _naze(view: int) -> void:
	var cx := 24.0
	var bob := float(_p["bob"])
	var lean := float(_p["lean"]) if view == 1 else 0.0
	var arms := str(_p["arms"])
	var robe: Array = _c["top"]
	var iron: Array = _c["iron"]
	var glow := Color("#b8f0ff")
	var void_c := Color("#07060c")
	var foot := float(FRAME_H - 1 - FOOT_MARGIN)
	var top_y := foot - 50.0 + bob
	var sway := float(int(_p["stride"]) / 2 + int(_p["pass"]))
	# manteau : s'évase vers le bas
	for i in int(48.0 - bob):
		var k := float(i) / 47.0
		var half := 7.5 + k * 9.0
		var dxs := -lean * maxf(0.0, 40.0 - float(i)) / 40.0 + sin(k * 3.0 + sway) * k * 2.0
		var y := top_y + 8.0 + float(i)
		var xl := cx - half + dxs
		var xr := cx + half + dxs
		for x in range(int(round(xl)), int(round(xr))):
			var u := ((float(x) + 0.5 - xl) / (xr - xl)) * 2.0 - 1.0
			var tone := _tone(clampf(u, -0.99, 0.99), -0.1)
			if i > 8 and (x + i / 5) % 6 == 0:
				tone = mini(tone, 1)
			_put(x, int(y), robe[tone])
	# lambeaux : encoches triangulaires dans le bas
	for t in 8:
		var tx := int(cx) - 16 + t * 4 + (int(sway) if t % 2 == 0 else 0)
		var depth := 3 + (t * 5 + int(bob) * 2) % 5
		for yy in depth:
			var w := int(round(2.0 * (1.0 - float(yy) / float(depth))))
			for xx in range(-w, w + 1):
				var px := tx + 1 + xx
				if px >= 1 and px < FRAME_W - 1:
					var yb := int(foot) + 1 - yy
					if _flip >= 0:
						_im.set_pixel(_flip - px, yb, Color(0, 0, 0, 0))
					else:
						_im.set_pixel(px, yb, Color(0, 0, 0, 0))
	# ceinture de fer
	_trap(top_y + 27.0, top_y + 29.0, cx - 8.0 - lean * 0.5, cx + 8.0 - lean * 0.5, cx - 8.5 - lean * 0.5, cx + 8.5 - lean * 0.5, iron)
	if view != 2:
		_put(int(cx - lean * 0.5) - 1, int(top_y) + 28, glow)
	# capuche
	var hx := cx - lean - (3.0 if view == 1 else 0.0)
	var hcy := top_y + 5.0
	_ell(hx, hcy, 9.0, 10.5, robe)
	_trap(hcy + 6.0, hcy + 12.0, hx - 9.0, hx + 9.0, hx - 11.0, hx + 11.0, robe, -0.05)
	if view == 0:
		_ell(hx, hcy + 1.0, 6.2, 7.0, [void_c, void_c, void_c, void_c, void_c])
		var shut := str(_p["eyes"]) == "closed" or str(_p["eyes"]) == "ko"
		for s: int in [-1, 1]:
			var ex := int(hx) + (-4 if s < 0 else 2)
			if shut:
				_rect(ex, hcy, 3.0, 1.0, glow)
			else:
				_rect(ex, hcy - 1.0, 3.0, 3.0, glow)
				_put(ex, int(hcy) - 1, WHITE)
		if str(_p["mouth"]) != "smile":
			_rect(hx - 2.0, hcy + 4.0, 4.0, 1.0, glow)
	elif view == 1:
		_ell(hx - 3.0, hcy + 1.0, 4.8, 6.5, [void_c, void_c, void_c, void_c, void_c])
		var shut := str(_p["eyes"]) == "closed" or str(_p["eyes"]) == "ko"
		_rect(hx - 6.0, hcy - 0.5, 3.0, 1.0 if shut else 3.0, glow)
		_put(int(hx) - 6, int(hcy) - 1 + (0 if shut else 0), WHITE)
		if str(_p["mouth"]) != "smile":
			_rect(hx - 6.0, hcy + 4.0, 3.0, 1.0, glow)
	else:
		_rect(hx - 0.5, hcy - 8.0, 1.0, 17.0, robe[1])
	# couronne de fer, pointes inégales
	_trap(hcy - 9.0, hcy - 6.0, hx - 7.5, hx + 7.5, hx - 8.5, hx + 8.5, iron)
	for i in 5:
		var px := hx - 6.0 + float(i) * 3.0
		var hgt := 5.0 + float(i % 2) * 2.0
		_trap(hcy - 9.0 - hgt, hcy - 8.5, px - 0.4, px + 0.4, px - 1.3, px + 1.3, iron)
	_put(int(hx) - 3, int(hcy) - 8, glow)
	# bras et lame
	var hand := _ramp(Color("#c8c8dc"))
	var sx := cx - lean
	if view == 1:
		var hx1 := sx - 9.0
		var hy1 := top_y + 26.0
		match arms:
			"up":
				hx1 = sx - 7.0
				hy1 = top_y + 12.0
			"strike":
				hx1 = sx - 8.0
				hy1 = top_y + 18.0
			"flail":
				hx1 = sx + 8.0
				hy1 = top_y + 12.0
		_cap(sx, top_y + 15.0, hx1 + 2.0, hy1 - 2.0, 3.4, 3.0, robe, -0.1)
		_ell(hx1, hy1, 2.6, 2.6, hand)
		_blade(hx1, hy1, arms, glow, iron)
	else:
		for s: int in [-1, 1]:
			var ax := cx + float(s) * 9.5
			var ay := top_y + 15.0
			var hx2 := ax + float(s) * 1.5
			var hy2 := ay + 12.0 + float(_p["arm"]) * float(s)
			if arms == "up" or arms == "flail" or (arms == "strike" and s > 0):
				hx2 = ax + float(s) * 3.0
				hy2 = ay - 11.0
			if _p.has("crouch"):
				hy2 = ay + 14.0
			_cap(ax, ay, hx2, hy2 - 2.0, 3.6, 3.2, robe if s < 0 else _dim(robe))
			_ell(hx2, hy2, 2.5, 2.5, hand)
			if s > 0 and view == 0:
				_blade(hx2, hy2, arms, glow, iron)


static func _blade(hx: float, hy: float, arms: String, glow: Color, iron: Array) -> void:
	var down := arms == "down" or arms == "strike"
	if down:
		_cap(hx - 1.0, hy, hx - 3.0, hy + 22.0, 1.3, 0.6, iron)
		_cap(hx - 1.5, hy + 1.0, hx - 3.4, hy + 21.0, 0.5, 0.2, [glow, glow, glow, glow, WHITE])
	else:
		_cap(hx, hy, hx - 2.0, hy - 17.0, 1.3, 0.6, iron)
		_cap(hx - 0.5, hy - 1.0, hx - 2.2, hy - 16.0, 0.5, 0.2, [glow, glow, glow, glow, WHITE])
	_cap(hx - 3.5, hy + 0.5, hx + 2.5, hy + 0.5, 0.9, 0.9, iron)
