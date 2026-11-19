extends RefCounted
## Boîte à outils de peinture des personnages : format de la planche, état de la case en
## cours de peinture, primitives éclairées (ellipsoïde, capsule, trapèze, polygone).
## Les autres fichiers (character_head.gd, character_painter.gd, character_species.gd) en
## héritent : tout est en pixels réels de la planche, rien n'est agrandi après coup.
##
## Chaque pièce est un petit volume éclairé : la normale de la forme en chaque pixel choisit
## un ton dans une rampe de cinq (PA.shade : ombres vers le violet, lumières vers le chaud).
## La lumière vient d'en haut à gauche dans les quatre vues (la ligne « droite » est peinte
## retournée avec la lumière inversée). Le contour prend la teinte sombre de la pièce voisine.

const PA = preload("res://src/gfx/pixel_art.gd")

const FRAME_W := 88
const FRAME_H := 132
const COLUMNS := 11
const ROWS := 4
const FOOT_MARGIN := 4   # pixels vides sous les pieds dans chaque case
const PPU := 42.0        # pixels par unité monde pour les planches peintes par code
const IDLE := [0, 0, 1, 1, 0, 0, 1, 1, 0, 2, 1, 1]   # suite jouée au repos (4 images/s)
const WALK := [3, 4, 5, 6]
const POSES := {"attack": 7, "cast": 8, "hit": 9, "ko": 10}

const WHITE := Color("#ffffff")
const GOLD := Color("#f2c84a")
const RED := Color("#c8403a")
const MOUTH := Color("#6a2f3a")
const SCLERA := Color("#f6f1ea")

# état de la case en cours de peinture (une case à la fois, sans partage)
static var _im: Image
static var _c: Dictionary
static var _p: Dictionary
static var _lx := -0.5       # composante x de la lumière, dans le repère du dessin
static var _flip := -1       # >= 0 : le dessin est retourné (ligne « droite »)
static var _cx := 44.0
static var _foot := 127.0
static var _hip := 0.0
static var _ny := 0.0        # ligne des épaules
static var _hcy := 0.0       # centre de la tête
static var _rx := 12.0
static var _ry := 11.5
static var _th := 30.0       # hauteur du torse
static var _lh := 36.0       # longueur de jambe
static var _hs := 11.0       # demi-largeur d'épaules
static var _bulge := 1.0     # ventre
static var _fk := ""         # expression au repos (champ « face » du look)


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


## Même rampe, un cran plus sombre (membre ou pièce à l'arrière-plan).
static func _dim(ramp: Array) -> Array:
	return [ramp[0], ramp[0], ramp[1], ramp[2], ramp[3]]


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


## Segment de pixels, un pixel d'épaisseur.
static func _line(x0: float, y0: float, x1: float, y1: float, col: Color) -> void:
	var n := int(maxf(absf(x1 - x0), absf(y1 - y0))) + 1
	for i in n + 1:
		var t := float(i) / float(maxi(n, 1))
		_put(int(round(lerpf(x0, x1, t))), int(round(lerpf(y0, y1, t))), col)


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


## Ellipsoïde éclairé. y_min / y_max coupent la forme.
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


## Capsule éclairée d'un point à un autre (membres, mèches, manches, bâtons).
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


## Courbe (quadratique) faite de capsules : cônes tordus, mèches, bâtons, queues de cape.
static func _bend(p0: Vector2, p1: Vector2, p2: Vector2, r0: float, r1: float, ramp: Array,
		bias: float = 0.0, steps: int = 14) -> void:
	var prev := p0
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var q := p0.lerp(p1, t).lerp(p1.lerp(p2, t), t)
		var t0 := float(i - 1) / float(steps)
		_cap(prev.x, prev.y, q.x, q.y, lerpf(r0, r1, t0), lerpf(r0, r1, t), ramp, bias)
		prev = q


## Trapèze lisse comme un tube : étoffes, corps, cônes. « folds » : Vector2(position 0..1 sur
## la largeur, départ 0..1 sur la hauteur) = plis ; hem : ourlet sombre sur la dernière ligne.
## « sway » décale le bas (cape ou robe qui suit le mouvement).
static func _trap(y0: float, y1: float, xl0: float, xr0: float, xl1: float, xr1: float, ramp: Array,
		bias: float = 0.0, folds: Array = [], hem: bool = false, sway: float = 0.0) -> void:
	var h := y1 - y0
	if h <= 0.0:
		return
	var last := int(round(y1)) - 1
	for y in range(int(round(y0)), int(round(y1))):
		var t := clampf((y + 0.5 - y0) / h, 0.0, 1.0)
		var off := sway * t * t
		var xl := lerpf(xl0, xl1, t) + off
		var xr := lerpf(xr0, xr1, t) + off
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
					elif x == fx + 1 and tone >= 3:
						tone = 2
			if hem and y == last:
				tone = mini(tone, 1)
			_put(x, y, ramp[tone])


## Cape ou robe vue de dos : comme _trap, mais l'ourlet est une ligne ondulée, plus haute du côté
## du pied levé (lift_l côté gauche de l'écran, lift_r côté droit), avec une fente au milieu
## qui s'ouvre quand on marche (slit_w) : les jambes et les talons, peints avant, apparaissent.
## y1 est le point le plus bas de l'ourlet, hem_h l'amplitude de l'ondulation.
static func _drape(y0: float, y1: float, xl0: float, xr0: float, xl1: float, xr1: float, ramp: Array,
		bias: float, folds: Array, sway: float, hem_h: float, slit_w: float, lift_l: float, lift_r: float,
		phase: float) -> void:
	var h := y1 - y0
	if h <= 0.0:
		return
	var mid := (xl0 + xr0) * 0.5 + sway * 0.8
	for y in range(int(round(y0)), int(ceil(y1)) + 1):
		var t := clampf((y + 0.5 - y0) / h, 0.0, 1.0)
		var off := sway * t * t
		var xl := lerpf(xl0, xl1, t) + off
		var xr := lerpf(xr0, xr1, t) + off
		var w := xr - xl
		if w <= 0.01:
			continue
		for x in range(int(round(xl)), maxi(int(round(xr)), int(round(xl)) + 1)):
			var hem_y := y1 - hem_h * 0.5 * (1.0 + sin(float(x) * 0.62 + phase)) - (lift_l if float(x) < mid else lift_r) * 0.85
			if y + 0.5 > hem_y:
				continue
			var gap := absf(float(x) + 0.5 - mid)
			var in_slit := slit_w > 0.5 and gap < slit_w * 0.5 and y + 0.5 > y1 - 24.0
			if in_slit:
				continue
			var u := clampf(((x + 0.5 - xl) / w) * 2.0 - 1.0, -0.99, 0.99)
			var tone := _tone(u, (t * 2.0 - 1.0) * 0.35, bias)
			for f: Vector2 in folds:
				if t >= f.y:
					var fx := int(floor(xl + f.x * w))
					if x == fx:
						tone = mini(tone, 1)
					elif x == fx - 1 and tone <= 2:
						tone = 3
					elif x == fx + 1 and tone >= 3:
						tone = 2
			if y + 1.5 > hem_y:
				tone = mini(tone, 1)
			if slit_w > 0.5 and gap < slit_w * 0.5 + 1.2 and y + 0.5 > y1 - 24.0:
				tone = mini(tone, 1)
			_put(x, y, ramp[tone])


## Polygone rempli (convexe ou presque), éclairé comme un trapèze : cape, mèche, pan de robe.
static func _poly(pts: Array, ramp: Array, bias: float = 0.0, hem: bool = false) -> void:
	var y_min := 1000.0
	var y_max := -1000.0
	for p: Vector2 in pts:
		y_min = minf(y_min, p.y)
		y_max = maxf(y_max, p.y)
	var n := pts.size()
	var last := int(floor(y_max - 0.5))
	for y in range(int(ceil(y_min - 0.5)), last + 1):
		var yc := y + 0.5
		var xl := 1000.0
		var xr := -1000.0
		for i in n:
			var a: Vector2 = pts[i]
			var b: Vector2 = pts[(i + 1) % n]
			if (a.y <= yc and b.y > yc) or (b.y <= yc and a.y > yc):
				var x := a.x + (yc - a.y) / (b.y - a.y) * (b.x - a.x)
				xl = minf(xl, x)
				xr = maxf(xr, x)
		if xr <= xl:
			continue
		var w := xr - xl
		var t := clampf((yc - y_min) / maxf(y_max - y_min, 0.1), 0.0, 1.0)
		for x in range(int(round(xl)), maxi(int(round(xr)), int(round(xl)) + 1)):
			var u := clampf(((x + 0.5 - xl) / w) * 2.0 - 1.0, -0.99, 0.99)
			var tone := _tone(u, (t * 2.0 - 1.0) * 0.35, bias)
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
