extends RefCounted
## Peint les monstres par code. Chaque planche contient quatre poses côte à côte
## (repos, respiration, attaque, coup reçu), le monstre regardant vers la DROITE.
## Les deux premières sont dessinées à la main ; l'attaque et le coup reçu reprennent le
## repos avec un autre visage (FACES). Une passe de volume éclaire le haut gauche de chaque
## forme et assombrit le bas droit.
## Format documenté dans assets/sprites/README.md.

const PA = preload("res://src/gfx/pixel_art.gd")

const COLUMNS := 4
const IDLE := [0, 1]
const POSES := {"attack": 2, "hit": 3}

## Visage de chaque famille, en pixels dans la case : yeux [x, y, largeur, hauteur] et bouche.
const FACES := {
	"limace": {"eyes": [[26, 3, 3, 3], [31, 4, 3, 3]], "mouth": [30, 15, 4, 3]},
	"guepe": {"eyes": [[25, 13, 3, 3]], "mouth": [26, 17, 3, 2]},
	"champignon": {"eyes": [[12, 21, 3, 3], [17, 21, 3, 3]], "mouth": [14, 25, 4, 3]},
	"epouvantail": {"eyes": [[18, 12, 2, 2], [23, 12, 2, 2]], "mouth": [19, 16, 5, 2]},
	"sanglier": {"eyes": [[35, 15, 3, 2]], "mouth": [36, 21, 4, 2]},
	"grenouille": {"eyes": [[22, 6, 3, 3], [28, 7, 3, 3]], "mouth": [24, 14, 8, 3]},
	"follet": {"eyes": [[8, 16, 3, 3], [14, 16, 3, 3]], "mouth": [10, 21, 4, 3]},
	"rat": {"eyes": [[30, 12, 3, 3]], "mouth": [33, 18, 5, 2]},
	"coq": {"eyes": [[30, 8, 3, 3]], "mouth": [33, 12, 4, 2]},
	"asticot": {"eyes": [[30, 10, 3, 3]], "mouth": [33, 14, 3, 2]},
	"vacherin": {"eyes": [[11, 12, 3, 3], [23, 12, 3, 3]], "mouth": [15, 16, 8, 3]},
	"mouche": {"eyes": [[25, 13, 3, 3]], "mouth": [26, 17, 3, 2]},
	"moisi": {"eyes": [[11, 21, 3, 3], [18, 21, 3, 3]], "mouth": [14, 26, 4, 2]},
	"chamois": {"eyes": [[34, 12, 3, 3]], "mouth": [37, 18, 4, 2]},
	"parchemin": {"eyes": [[9, 14, 3, 3], [16, 14, 3, 3]], "mouth": [11, 20, 6, 3]},
	"tampon": {"eyes": [[10, 9, 3, 3], [15, 9, 3, 3]], "mouth": [11, 14, 6, 2]},
}
const FAMILY := {"baveuse": "limace", "sangsue": "limace", "frelon": "guepe", "amanite": "champignon",
	"solitaire": "sanglier", "crapaud": "grenouille"}

## Espèces peintes en volumes (rampes de cinq tons, contour coloré). Les autres espèces
## passent par la vieille passe `_volume`.
const PAINTED := ["limace", "baveuse", "guepe", "champignon", "sangsue", "frelon", "amanite", "sanglier",
	"solitaire", "grenouille", "crapaud", "follet", "epouvantail", "rat", "coq", "asticot", "vacherin",
	"mouche", "moisi"]

const SIZES := {
	"limace": Vector2i(38, 26),
	"baveuse": Vector2i(38, 26),
	"guepe": Vector2i(32, 30),
	"champignon": Vector2i(32, 34),
	"epouvantail": Vector2i(40, 56),
	"sangsue": Vector2i(38, 26),
	"frelon": Vector2i(32, 30),
	"amanite": Vector2i(32, 34),
	"sanglier": Vector2i(46, 32),
	"solitaire": Vector2i(46, 32),
	"grenouille": Vector2i(36, 28),
	"crapaud": Vector2i(36, 28),
	"follet": Vector2i(24, 32),
	"rat": Vector2i(40, 26),
	"coq": Vector2i(40, 40),
	"asticot": Vector2i(38, 26),
	"vacherin": Vector2i(38, 26),
	"mouche": Vector2i(32, 30),
	"moisi": Vector2i(32, 34),
	"chamois": Vector2i(44, 36),
	"parchemin": Vector2i(28, 36),
	"tampon": Vector2i(28, 34),
}

const WASP := ["#f2c23c", "#fbe38a", "#3a2420", "#cfe6f4", "#9cc0dc"]
const HORNET := ["#d8622c", "#f0a060", "#2a1a22", "#e0d0c0", "#b8a090"]
const MUSHROOM := ["#8a56a8", "#5c3878", "#b98ad0", "#f0dcf6"]
const AMANITA := ["#b8402e", "#7c2420", "#e07a56", "#fff2dc"]


static func has(kind: String) -> bool:
	return SIZES.has(kind)


static func paint(kind: String) -> Image:
	var size: Vector2i = SIZES.get(kind, Vector2i(24, 24))
	var img := PA.new_image(size.x * COLUMNS, size.y)
	for col in COLUMNS:
		var f := col if col < 2 else 0
		var ox := col * size.x
		match kind:
			"limace": _slug(img, ox, f, ["#5f8a3c", "#8fb552", "#c3dc7c", "#e9f2b8"], "#d9732e")
			"baveuse": _slug(img, ox, f, ["#6a4f8a", "#9a78b8", "#c9a8dc", "#ecd8f4"], "#f0c040")
			"guepe": _wasp(img, ox, f, WASP)
			"champignon": _mushroom(img, ox, f, MUSHROOM)
			"sangsue": _slug(img, ox, f, ["#2e3a44", "#4f6470", "#8aa2a8", "#cfe0dc"], "#c8324a")
			"frelon": _wasp(img, ox, f, HORNET)
			"amanite": _mushroom(img, ox, f, AMANITA)
			"sanglier": _boar(img, ox, f, ["#5a4032", "#7c5a44", "#a07c5e", "#3a2820"])
			"solitaire": _boar(img, ox, f, ["#4a4a54", "#6c6c78", "#9a9aa6", "#2a2a32"])
			"grenouille": _frog(img, ox, f, ["#4c7a3c", "#74a850", "#c8dc8c", "#2c4a2c"], "#e0a030")
			"crapaud": _frog(img, ox, f, ["#6a5a34", "#94804a", "#d8c890", "#3c3220"], "#d84a30")
			"follet": _wisp(img, ox, f)
			"epouvantail": _scarecrow(img, ox, f)
			"rat": _rat(img, ox, f)
			"coq": _rooster(img, ox, f)
			"asticot": _maggot(img, ox, f)
			"vacherin": _cheese(img, ox, f)
			"mouche": _fly(img, ox, f)
			"moisi": _mold(img, ox, f)
			"chamois": _chamois(img, ox, f)
			"parchemin": _scroll(img, ox, f)
			"tampon": _stamp(img, ox, f)
			_:
				PA.rect(img, ox + 4, 4, size.x - 8, size.y - 8, Color.MAGENTA)
		if not PAINTED.has(kind):
			_volume(img, Rect2i(ox, 0, size.x, size.y))
		if col >= 2:
			_mood(img, ox, kind, col == 2)
		_outline(img, Rect2i(ox, 0, size.x, size.y))
	return img


## Donne du volume : lumière sur les bords tournés vers le haut gauche, ombre sur les
## bords tournés vers le bas droit.
static func _volume(img: Image, region: Rect2i) -> void:
	var src := img.get_region(region)
	var w := region.size.x
	var h := region.size.y
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var up := y == 0 or src.get_pixel(x, y - 1).a < 0.5
			var left := x == 0 or src.get_pixel(x - 1, y).a < 0.5
			var down := y == h - 1 or src.get_pixel(x, y + 1).a < 0.5
			var right := x == w - 1 or src.get_pixel(x + 1, y).a < 0.5
			if down or right:
				img.set_pixel(region.position.x + x, region.position.y + y, PA.shade(c, -0.22))
			elif up or left:
				img.set_pixel(region.position.x + x, region.position.y + y, PA.shade(c, 0.2))


## Visage d'attaque (yeux ouverts et furieux, gueule ouverte) ou de coup reçu (yeux
## plissés, bouche tordue).
static func _mood(img: Image, ox: int, kind: String, attack: bool) -> void:
	var face: Dictionary = FACES.get(str(FAMILY.get(kind, kind)), {})
	if face.is_empty():
		return
	var dark := _c("#2b1b2e")
	var maw := _c("#4a1424")
	for e: Array in face["eyes"]:
		var x := ox + int(e[0])
		var y := int(e[1])
		var w := int(e[2])
		var h := int(e[3])
		if attack:
			PA.rect(img, x, y, w, h, Color.WHITE)
			PA.rect(img, x, y, w, 1, dark)                 # paupière basse, regard noir
			PA.px(img, x + w - 1, y + h - 1, dark)
			PA.px(img, x + w - 1, y + 1, dark)
		else:
			# œil plissé : un trait fermé, relevé aux coins, par-dessus l'œil d'origine
			PA.rect(img, x, y + h / 2, w, 1, dark)
			if h >= 3:
				PA.px(img, x, y, dark)
				PA.px(img, x, y + h - 1, dark)
	var m: Array = face["mouth"]
	var mx := ox + int(m[0])
	var my := int(m[1])
	var mw := int(m[2])
	var mh := int(m[3])
	if attack:
		PA.rect(img, mx, my, mw, mh, maw)
		for i in range(0, mw, 2):
			PA.px(img, mx + i, my, Color.WHITE)
		if mh >= 3:
			PA.px(img, mx + mw / 2, my + mh - 1, _c("#d8506a"))
	else:
		for i in mw:
			PA.px(img, mx + i, my + 1 - (i % 2), dark)


static func _c(hex: String) -> Color:
	return Color.from_string(hex, Color.MAGENTA)


# ------------------------------------------------------------------ outils de volume
# Même méthode que character_painter.gd : chaque forme est un volume éclairé par le haut
# gauche, peint avec une rampe de cinq tons (ombres violacées, lumières chaudes), puis un
# contour de la couleur de la forme voisine, assombrie.

static func _ramp(hex: String) -> Array:
	var c := _c(hex)
	return [PA.shade(c, -0.5), PA.shade(c, -0.26), c, PA.shade(c, 0.17), PA.shade(c, 0.36)]


## Une rampe en retrait : pièce à l'arrière-plan (pattes de derrière).
static func _dim(ramp: Array) -> Array:
	return [ramp[0], ramp[0], ramp[1], ramp[2], ramp[3]]


static func _tone(nx: float, ny: float, bias: float = 0.0) -> int:
	var nz := sqrt(maxf(0.0, 1.0 - nx * nx - ny * ny))
	var l := -0.5 * nx - ny * 0.5 + nz * 0.7 + bias
	if l < -0.25:
		return 0
	if l < 0.28:
		return 1
	if l < 0.78:
		return 2
	if l < 0.94:
		return 3
	return 4


## Ellipsoïde éclairé. ymax / ymin coupent la forme.
static func _ell(img: Image, cx: float, cy: float, rx: float, ry: float, ramp: Array, bias: float = 0.0,
		ymax: float = 1000.0, ymin: float = -1000.0) -> void:
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		if y + 0.5 > ymax or y + 0.5 < ymin:
			continue
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			if nx * nx + ny * ny > 1.0:
				continue
			PA.px(img, x, y, ramp[_tone(nx, ny, bias)])


## Capsule éclairée d'un point à un autre (pattes, tiges, antennes).
static func _cap(img: Image, x0: float, y0: float, x1: float, y1: float, r0: float, r1: float, ramp: Array,
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
			PA.px(img, x, y, ramp[_tone(off.x / r, off.y / r, bias)])


## Trapèze lisse comme un tube : étoffes, corps.
static func _trap(img: Image, y0: int, y1: int, xl0: float, xr0: float, xl1: float, xr1: float, ramp: Array,
		bias: float = 0.0) -> void:
	var h := float(y1 - y0)
	if h <= 0.0:
		return
	for y in range(y0, y1):
		var t := (y + 0.5 - y0) / h
		var xl := lerpf(xl0, xl1, t)
		var xr := lerpf(xr0, xr1, t)
		var w := xr - xl
		if w <= 0.01:
			continue
		for x in range(int(round(xl)), maxi(int(round(xr)), int(round(xl)) + 1)):
			var u := clampf(((x + 0.5 - xl) / w) * 2.0 - 1.0, -0.99, 0.99)
			PA.px(img, x, y, ramp[_tone(u, (t * 2.0 - 1.0) * 0.35, bias)])


## Œil : blanc, regard sombre en bas à droite, un éclat en haut à gauche.
static func _eye(img: Image, x: int, y: int, w: int, h: int, iris: Color = Color("#2b1b2e")) -> void:
	PA.rect(img, x, y, w, h, Color.WHITE)
	PA.px(img, x + w - 1, y + h - 1, iris)
	if h >= 3:
		PA.px(img, x + w - 1, y + h - 2, iris)
	if w >= 3:
		PA.px(img, x + w - 2, y + h - 1, iris)


## Contour de la couleur de la pièce voisine, assombrie et un peu violette.
static func _outline(img: Image, region: Rect2i) -> void:
	var src := img.get_region(region)
	var w := region.size.x
	var h := region.size.y
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a >= 0.5:
				continue
			var sum := Color(0, 0, 0, 0)
			var n := 0
			for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx := x + d.x
				var ny := y + d.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				var nc := src.get_pixel(nx, ny)
				if nc.a >= 0.5:
					sum += nc
					n += 1
			if n == 0:
				continue
			var out := (sum / float(n)).darkened(0.7).lerp(PA.OUTLINE, 0.4)
			out.a = 1.0
			img.set_pixel(region.position.x + x, region.position.y + y, out)


## Limace : corps bas et luisant, pied clair, manteau sombre, deux yeux au bout de leurs tiges.
static func _slug(img: Image, ox: int, f: int, pal: Array, eye_hex: String) -> void:
	var back := _ramp(pal[0])
	var mid := _ramp(pal[1])
	var belly := _ramp(pal[2])
	var shine := _c(pal[3])
	var dark := _c("#2b1b2e")
	var sq := f   # la seconde pose s'étale un peu
	var by := 17.0 + sq * 0.5
	# traînée de bave derrière elle
	PA.rect(img, ox + 2, 23, 8, 1, belly[3])
	PA.px(img, ox + 1, 23, belly[2])
	PA.rect(img, ox + 5, 24, 3, 1, belly[3])
	# queue effilée, corps, tête dressée, pied clair
	_ell(img, ox + 8.0, by + 2.2, 6.5, 3.0, mid)
	_ell(img, ox + 17.0 - sq * 0.5, by, 11.5 + sq, 5.8 - sq * 0.6, mid)
	_ell(img, ox + 28.0 + sq, by - 2.5 + sq, 5.4, 6.0 - sq * 0.5, mid)
	_ell(img, ox + 17.5, by + 4.4, 13.5 + sq, 2.0, belly, 0.1)
	# manteau sombre sur le dos, taches
	_ell(img, ox + 14.0, by - 2.6, 7.5, 3.4, back, -0.05)
	for p: Vector2i in [Vector2i(10, -2), Vector2i(15, -3), Vector2i(18, -1), Vector2i(12, 0)]:
		PA.px(img, ox + p.x, int(by) + p.y, back[0])
		PA.px(img, ox + p.x + 1, int(by) + p.y, back[0])
	# éclats de bave luisante
	PA.rect(img, ox + 10, int(by) - 5, 3, 1, shine)
	PA.px(img, ox + 9, int(by) - 4, shine)
	PA.px(img, ox + 25 + sq, int(by) - 4 + sq, shine)
	# tiges et yeux
	var hy := int(by) - 8 + sq
	_cap(img, ox + 27.5 + sq, hy + 3.0, ox + 27.5 + sq, hy - 2.0, 0.9, 0.8, mid)
	_cap(img, ox + 32.0 + sq, hy + 3.0, ox + 32.5 + sq, hy - 1.0, 0.9, 0.8, mid)
	_eye(img, ox + 26 + sq, hy - 6, 3, 3, _c(eye_hex))
	_eye(img, ox + 31 + sq, hy - 5, 3, 3, _c(eye_hex))
	# bouche tombante
	PA.px(img, ox + 30 + sq, int(by) - 1 + sq, dark)
	PA.px(img, ox + 31 + sq, int(by) - 2 + sq, dark)
	PA.px(img, ox + 32 + sq, int(by) - 1 + sq, dark)


## Guêpe à cidre : ventre rayé, ailes qui battent, dard généreux.
static func _wasp(img: Image, ox: int, f: int, pal: Array) -> void:
	var yellow := _ramp(pal[0])
	var brown := _ramp(pal[2])
	var wing := _ramp(pal[3])
	var wing_d := _ramp(pal[4])
	var dy := f
	# ailes (derrière)
	if f == 0:
		_ell(img, ox + 15.0, 7.0 + dy, 6.5, 4.0, wing)
		_ell(img, ox + 9.0, 9.0 + dy, 4.5, 2.6, wing_d)
	else:
		_ell(img, ox + 15.0, 11.0 + dy, 7.5, 2.0, wing)
		_ell(img, ox + 9.0, 12.0 + dy, 5.0, 1.5, wing_d)
	# dard
	_cap(img, ox + 4.0, 20.0 + dy, ox + 0.8, 23.0 + dy, 1.2, 0.5, brown)
	# abdomen rayé
	var cx := ox + 10.0
	var cy := 18.0 + dy
	for y in range(int(cy) - 6, int(cy) + 7):
		for x in range(ox + 2, ox + 18):
			var ddx := (x + 0.5 - cx) / 7.0
			var ddy := (y + 0.5 - cy) / 5.0
			if ddx * ddx + ddy * ddy > 1.0:
				continue
			var t := _tone(ddx, ddy)
			if (x - ox) % 5 < 2:
				PA.px(img, x, y, brown[t])
			else:
				PA.px(img, x, y, yellow[t])
	# pattes
	_cap(img, ox + 17.0, 21.0 + dy, ox + 15.5, 25.0 + dy, 0.7, 0.5, brown)
	_cap(img, ox + 20.0, 21.0 + dy, ox + 21.5, 25.0 + dy, 0.7, 0.5, brown)
	# thorax velu et tête
	_ell(img, ox + 19.0, 16.0 + dy, 4.4, 4.4, brown, 0.05)
	_ell(img, ox + 24.5, 15.0 + dy, 4.3, 4.3, yellow)
	_ell(img, ox + 26.5, 14.5 + dy, 1.9, 2.0, brown, -0.2)
	PA.px(img, ox + 25, 13 + dy, Color.WHITE)
	PA.px(img, ox + 28, 17 + dy, brown[0])
	PA.px(img, ox + 28, 18 + dy, brown[0])
	# antennes
	_cap(img, ox + 25.0, 11.0 + dy, ox + 28.0, 7.5 + dy, 0.6, 0.6, brown)
	_cap(img, ox + 23.0, 11.0 + dy, ox + 24.0, 7.0 + dy, 0.6, 0.6, brown)


## Mouche de cave : noire, luisante, gros yeux rouges, ailes qui vibrent.
static func _fly(img: Image, ox: int, f: int) -> void:
	var body := _ramp("#34414f")
	var sheen := _ramp("#3f7a6c")
	var red := _ramp("#c8302c")
	var wing := _ramp("#d6e6f2")
	var wing_d := _ramp("#a8c0d6")
	var dy := f
	if f == 0:
		_ell(img, ox + 16.0, 7.0 + dy, 7.0, 3.8, wing)
		_ell(img, ox + 9.0, 9.5 + dy, 5.0, 2.4, wing_d)
	else:
		_ell(img, ox + 16.0, 11.0 + dy, 8.0, 2.0, wing)
		_ell(img, ox + 9.0, 12.5 + dy, 5.5, 1.5, wing_d)
	for x: int in [14, 18, 21]:
		_cap(img, ox + x, 20.0 + dy, ox + x + 1.5, 25.0 + dy, 0.7, 0.5, body)
	_ell(img, ox + 10.0, 18.0 + dy, 7.2, 5.0, body)
	_ell(img, ox + 8.0, 19.5 + dy, 3.0, 2.0, sheen, 0.1)
	_ell(img, ox + 19.0, 16.0 + dy, 4.6, 4.6, body, 0.05)
	_ell(img, ox + 24.5, 15.5 + dy, 4.2, 4.2, body)
	_ell(img, ox + 26.0, 14.5 + dy, 2.7, 2.9, red)
	PA.px(img, ox + 25, 13 + dy, Color.WHITE)
	_cap(img, ox + 27.0, 18.0 + dy, ox + 30.0, 20.0 + dy, 0.8, 0.5, body)
	_cap(img, ox + 25.0, 11.5 + dy, ox + 27.0, 8.5 + dy, 0.5, 0.5, body)


## Champignon dormeur : gros chapeau, paupières closes, petits pieds.
static func _mushroom(img: Image, ox: int, f: int, pal: Array) -> void:
	var cap := _ramp(pal[0])
	var spot := _ramp(pal[3])
	var stem := _ramp("#eadfc6")
	var dark := _c("#2b1b2e")
	var dy := f
	# pieds, pied du champignon
	_ell(img, ox + 12.0, 30.4, 3.2, 1.8, stem, -0.1)
	_ell(img, ox + 20.0, 30.4, 3.2, 1.8, stem, -0.1)
	_ell(img, ox + 16.0, 24.5 + dy * 0.5, 5.6, 6.6 - dy * 0.5, stem, 0.05)
	# chapeau : demi-ellipsoïde à bord plat, lamelles sombres dessous
	var cy := 15.0 + dy
	_ell(img, ox + 16.0, cy, 14.0, 11.0 - dy, cap, 0.0, cy + 2.5)
	for y in range(int(cy) + 1, int(cy) + 3):
		for x in range(ox, ox + 32):
			if img.get_pixel(x, y).a >= 0.5:
				PA.px(img, x, y, cap[0] if y == int(cy) + 1 else cap[1])
	_ell(img, ox + 9.5, cy - 4.0, 2.6, 2.2, spot)
	_ell(img, ox + 18.0, cy - 7.0, 3.0, 2.4, spot)
	_ell(img, ox + 24.0, cy - 2.5, 2.0, 1.6, spot)
	# paupières closes, joues, bouche ronde
	PA.rect(img, ox + 12, 22 + dy, 3, 1, dark)
	PA.rect(img, ox + 17, 22 + dy, 3, 1, dark)
	PA.px(img, ox + 11, 24 + dy, _c("#e4a2a6"))
	PA.px(img, ox + 20, 24 + dy, _c("#e4a2a6"))
	PA.px(img, ox + 15, 25 + dy, dark)
	PA.px(img, ox + 16, 25 + dy, dark)
	if f == 1:
		PA.px(img, ox + 16, 26, dark)


## Moisissure bleue : tas duveteux, givré de blanc, qui coule de partout.
static func _mold(img: Image, ox: int, f: int) -> void:
	var blue := _ramp("#4a6ec0")
	var frost := _ramp("#bcd8f0")
	var deep := _ramp("#2c3c82")
	var dark := _c("#2b1b2e")
	var dy := f
	for x: int in [9, 15, 21]:
		_ell(img, ox + x + 1.0, 30.0, 3.0, 1.8, deep)
	_ell(img, ox + 16.0, 23.0 + dy, 11.5, 8.0 - dy, blue)
	_ell(img, ox + 10.0, 17.5 + dy, 6.5, 6.0, blue, 0.05)
	_ell(img, ox + 22.0, 17.0 + dy, 6.5, 6.5, blue, 0.0)
	_ell(img, ox + 16.0, 12.0 + dy, 7.5, 5.5, blue, 0.1)
	# givre et duvet
	_ell(img, ox + 14.0, 10.0 + dy, 4.5, 2.6, frost)
	_ell(img, ox + 24.0, 14.0 + dy, 2.8, 2.0, frost)
	_ell(img, ox + 8.0, 21.0 + dy, 2.2, 1.6, frost)
	for i in 26:
		var fx := 4 + int(PA.rnd(i, 3, 11) * 24.0)
		var fy := 6 + int(PA.rnd(i, 7, 5) * 20.0) + dy
		if img.get_pixel(ox + fx, fy).a >= 0.5:
			PA.px(img, ox + fx, fy, frost[2] if (i % 3) != 0 else frost[3])
	# yeux en bille et bouche tombante
	_eye(img, ox + 11, 21 + dy, 3, 3, _c("#2a7a3a"))
	_eye(img, ox + 18, 21 + dy, 3, 3, _c("#2a7a3a"))
	PA.px(img, ox + 14, 26 + dy, dark)
	PA.px(img, ox + 15, 27 + dy, dark)
	PA.px(img, ox + 16, 27 + dy, dark)
	PA.px(img, ox + 17, 26 + dy, dark)


## Épouvantail avachi : traverse de travers, manches qui pendent, tête qui tombe.
static func _scarecrow(img: Image, ox: int, f: int) -> void:
	var wood := _ramp("#7a5230")
	var shirt := _ramp("#a8683c")
	var patch := _ramp("#5f8a52")
	var sack := _ramp("#d9c08a")
	var straw := _ramp("#f0d060")
	var hat := _ramp("#5a4630")
	var band := _ramp("#b0483c")
	var dark := _c("#2b1b2e")
	var sx := f   # la seconde pose penche d'un pixel de plus
	# piquet et pied
	_cap(img, ox + 20.0, 30.0, ox + 20.0, 53.5, 1.4, 1.4, wood)
	_ell(img, ox + 20.0, 53.0, 4.5, 1.3, wood, -0.1)
	# traverse de travers
	_cap(img, ox + 4.5 + sx, 22.5, ox + 35.5 + sx, 28.0, 1.3, 1.3, wood)
	# chemise en toile, rapiécée
	_trap(img, 21, 38, ox + 12.5 + sx, ox + 27.5 + sx, ox + 11.0 + sx, ox + 28.5 + sx, shirt)
	_ell(img, ox + 16.0 + sx, 31.0, 2.6, 2.4, patch)
	PA.px(img, ox + 13 + sx, 31, dark)
	PA.px(img, ox + 19 + sx, 31, dark)
	PA.px(img, ox + 19 + sx, 25, dark)
	PA.px(img, ox + 19 + sx, 28, dark)
	# paille qui dépasse sous la chemise
	for i in 8:
		PA.rect(img, ox + 12 + sx + i * 2, 38, 1, 2 + (i % 2), straw[2 + (i % 2)])
	# manches pendantes et mains de paille
	_cap(img, ox + 6.5 + sx, 23.5, ox + 6.0 + sx, 33.0, 2.6, 2.3, shirt)
	_cap(img, ox + 32.5 + sx, 27.5, ox + 33.0 + sx, 37.0, 2.6, 2.3, shirt)
	for i in 3:
		PA.rect(img, ox + 4 + sx + i * 2, 34, 1, 3, straw[2 + (i % 2)])
		PA.rect(img, ox + 31 + sx + i * 2, 38, 1, 3, straw[2 + (i % 2)])
	# tête en sac, qui tombe sur l'épaule
	var hx := ox + 21.0 + sx * 1.5
	var hy := 14.0 + sx
	_ell(img, hx, hy, 6.6, 6.8, sack)
	_trap(img, int(hy) + 5, int(hy) + 8, hx - 4.5, hx + 4.5, hx - 3.5, hx + 3.5, sack, -0.35)
	# yeux cousus en croix, bouche en zigzag
	for e: int in [-3, 2]:
		PA.px(img, int(hx) + e, int(hy) - 2, dark)
		PA.px(img, int(hx) + e + 1, int(hy) - 1, dark)
		PA.px(img, int(hx) + e + 1, int(hy) - 2, sack[1])
		PA.px(img, int(hx) + e, int(hy) - 1, dark)
	for i in 5:
		PA.px(img, int(hx) - 3 + i, int(hy) + 2 + (i % 2), dark)
	# chapeau cabossé
	_trap(img, int(hy) - 12, int(hy) - 6, hx - 4.0, hx + 4.5, hx - 5.5, hx + 6.0, hat, 0.05)
	_ell(img, hx, hy - 5.5, 10.0, 2.4, hat, 0.1)
	_trap(img, int(hy) - 8, int(hy) - 6, hx - 5.0, hx + 5.5, hx - 5.5, hx + 6.0, band)


## Sanglier flapi : gros dos rond, hure basse, défenses, pattes courtes. Il traîne la patte.
static func _boar(img: Image, ox: int, f: int, pal: Array) -> void:
	var dark := _ramp(pal[0])
	var mid := _ramp(pal[1])
	var light := _ramp(pal[2])
	var deep := _ramp(pal[3])
	var dy := f   # la seconde pose s'affaisse d'un pixel
	# pattes (celles de derrière dans l'ombre)
	for x: int in [9, 15, 26, 31]:
		var r := _dim(deep) if x < 20 else deep
		_cap(img, ox + x + 1.5, 22.0 + dy, ox + x + 1.5, 29.5, 1.9, 1.6, r)
		PA.rect(img, ox + x, 30, 3, 1, _c("#1c1418"))
	# queue en tire-bouchon, détendue
	for p: Vector2i in [Vector2i(4, 14), Vector2i(3, 15), Vector2i(3, 16), Vector2i(4, 17), Vector2i(5, 17)]:
		PA.px(img, ox + p.x, p.y + dy, dark[1])
	# corps, garrot, hure
	_ell(img, ox + 19.0, 16.0 + dy, 14.5, 8.8, mid)
	_ell(img, ox + 25.0, 13.0 + dy, 8.0, 6.5, mid, 0.05)
	_ell(img, ox + 34.5, 18.0 + dy, 7.9, 6.9, dark, -0.2)
	_ell(img, ox + 35.0, 18.0 + dy, 7.0, 6.0, mid, 0.05)
	# ventre clair, dos sombre et soies hérissées
	_ell(img, ox + 18.0, 21.5 + dy, 11.0, 2.4, light, 0.0)
	_ell(img, ox + 17.0, 9.5 + dy, 10.0, 2.6, dark, -0.1)
	for i in 8:
		var bx := ox + 8 + i * 3
		var top := 6 + dy + (i % 2)
		PA.rect(img, bx, top, 1, 3, deep[1])
		PA.px(img, bx, top, deep[0])
	# oreille tombante
	_cap(img, ox + 31.5, 11.0 + dy, ox + 32.5, 15.0 + dy, 1.8, 1.0, dark)
	# groin, défenses, œil mi-clos
	_ell(img, ox + 41.0, 20.5 + dy, 3.4, 3.2, light, 0.1)
	PA.px(img, ox + 43, 20 + dy, deep[0])
	PA.px(img, ox + 43, 22 + dy, deep[0])
	PA.px(img, ox + 39, 23 + dy, Color.WHITE)
	PA.px(img, ox + 40, 24 + dy, Color.WHITE)
	PA.px(img, ox + 40, 23 + dy, Color.WHITE)
	PA.rect(img, ox + 35, 15 + dy, 3, 1, deep[0])
	PA.px(img, ox + 35, 16 + dy, Color.WHITE)
	PA.px(img, ox + 36, 16 + dy, Color.WHITE)
	PA.px(img, ox + 37, 16 + dy, _c("#2b1b2e"))


## Grenouille bouffie : accroupie, gros yeux, gorge qui se gonfle à la seconde pose.
static func _frog(img: Image, ox: int, f: int, pal: Array, eye_hex: String) -> void:
	var dark := _ramp(pal[0])
	var mid := _ramp(pal[1])
	var light := _ramp(pal[2])
	var deep := _ramp(pal[3])
	# cuisse repliée et pied arrière
	_ell(img, ox + 9.0, 20.0, 7.0, 5.0, dark, 0.1)
	_cap(img, ox + 4.0, 25.5, ox + 13.0, 25.5, 1.3, 1.1, dark)
	# corps et tête
	_ell(img, ox + 16.0, 17.0, 11.0, 7.5, mid)
	_ell(img, ox + 25.0, 13.0, 8.0, 6.5, mid, 0.05)
	# dos sombre et verrues
	_ell(img, ox + 14.0, 11.5, 7.0, 2.2, dark, -0.05)
	for p: Vector2i in [Vector2i(10, 15), Vector2i(15, 13), Vector2i(19, 16), Vector2i(13, 19)]:
		_ell(img, ox + p.x + 0.5, p.y + 0.5, 1.4, 1.2, dark, 0.15)
	# ventre et gorge (gonflée en respirant)
	_ell(img, ox + 17.0, 22.5, 8.5, 2.6, light)
	_ell(img, ox + 27.0, 19.0 + f * 0.5, 4.5 + f * 1.5, 3.0 + f * 1.5, light, 0.05)
	# patte avant
	_cap(img, ox + 22.5, 21.0, ox + 22.5, 25.0, 1.6, 1.4, mid)
	_cap(img, ox + 20.5, 26.0, ox + 25.5, 26.0, 1.0, 1.0, dark)
	# yeux globuleux
	_ell(img, ox + 23.5, 7.5, 3.4, 3.4, mid)
	_ell(img, ox + 29.5, 8.5, 3.4, 3.4, mid)
	PA.rect(img, ox + 22, 6, 3, 3, _c(eye_hex))
	PA.rect(img, ox + 28, 7, 3, 3, _c(eye_hex))
	PA.px(img, ox + 24, 7, deep[0])
	PA.px(img, ox + 24, 8, deep[0])
	PA.px(img, ox + 30, 8, deep[0])
	PA.px(img, ox + 30, 9, deep[0])
	PA.px(img, ox + 22, 6, Color.WHITE)
	PA.px(img, ox + 28, 7, Color.WHITE)
	# bouche large et lasse
	PA.line(img, ox + 22, 15, ox + 32, 14, deep[0])
	PA.px(img, ox + 21, 16, deep[0])


## Feu follet : flamme pâle qui flotte, deux yeux fatigués. Il éclaire à peine.
static func _wisp(img: Image, ox: int, f: int) -> void:
	var outer := _ramp("#3fa8a0")
	var mid := _ramp("#7fe0c8")
	var core := _ramp("#e8fff0")
	var dark := _c("#1c4a50")
	var sway := f
	# pointe de la flamme, qui danse
	_ell(img, ox + 12.0 + sway, 6.0, 2.5, 4.5, outer, 0.1)
	_ell(img, ox + 12.0 + sway * 0.5, 9.0, 4.0, 5.0, outer, 0.1)
	PA.px(img, ox + 12 + sway * 2, 1, mid[2])
	# corps
	_ell(img, ox + 12.0, 18.0, 8.5, 9.0, outer, 0.1)
	_ell(img, ox + 12.0, 19.0, 6.0, 7.0, mid, 0.15)
	_ell(img, ox + 12.0, 21.0, 3.5, 4.0, core, 0.2)
	_ell(img, ox + 12.0 + sway * 0.5, 11.0, 2.0, 3.0, mid, 0.1)
	# étincelles qui retombent
	PA.px(img, ox + 3, 27 + sway, mid[2])
	PA.px(img, ox + 20, 29 - sway, mid[2])
	# yeux mi-clos, bouche tombante
	PA.rect(img, ox + 8, 17, 3, 1, dark)
	PA.rect(img, ox + 14, 17, 3, 1, dark)
	PA.px(img, ox + 9, 18, dark)
	PA.px(img, ox + 15, 18, dark)
	PA.px(img, ox + 11, 22, dark)
	PA.px(img, ox + 12, 21, dark)
	PA.px(img, ox + 13, 22, dark)


## Ver de fromage : gras, segmenté, mandibules en avant. Il se tortille en tas.
static func _maggot(img: Image, ox: int, f: int) -> void:
	var body := _ramp("#e6d9a4")
	var head := _ramp("#d2a85a")
	var rind := _ramp("#e8a63c")
	var dark := _c("#3a2418")
	var lift := f   # la seconde pose se redresse d'un pixel
	for i in 7:
		var t := float(i) / 6.0
		var cx := ox + 5.0 + t * 22.0
		var cy := 20.5 - 8.5 * pow(t, 1.5) - lift * t
		var r := 3.2 + 2.2 * t
		_ell(img, cx, cy, r * 0.95, r, body, 0.05)
		PA.px(img, int(cx), int(cy + r * 0.45), dark)
	# miettes de croûte collées sur le dos
	for p: Vector2i in [Vector2i(10, 15), Vector2i(17, 14), Vector2i(23, 10)]:
		PA.rect(img, ox + p.x, p.y, 2, 1, rind[3])
		PA.px(img, ox + p.x, p.y + 1, rind[1])
	_ell(img, ox + 31.0, 12.0 - lift, 5.0, 4.8, head)
	_eye(img, ox + 30, 10 - lift, 3, 3, _c("#3a2418"))
	PA.px(img, ox + 36, 13 - lift, dark)
	PA.px(img, ox + 36, 14 - lift, dark)
	PA.px(img, ox + 35, 15 - lift, dark)
	PA.px(img, ox + 33, 15 - lift, dark)


## Le Vacherin : meule de fromage coulant, ceinturée d'épicéa, qui déborde de partout.
static func _cheese(img: Image, ox: int, f: int) -> void:
	var rind := _ramp("#e6bc58")
	var cream := _ramp("#fff0b4")
	var band := _ramp("#7a4a22")
	var dark := _c("#2b1b2e")
	var sag := f   # la seconde pose s'affaisse
	# flanc, tranche de la meule
	_ell(img, ox + 19.0, 16.0 + sag, 15.0, 8.0 - sag * 0.5, rind, 0.12, 99.0, 8.0)
	# ceinture d'épicéa
	for y in range(19 + sag, 21 + sag):
		for x in range(ox, ox + 38):
			if img.get_pixel(x, y).a >= 0.5:
				var u := clampf((float(x - ox) - 19.0) / 15.0, -0.99, 0.99)
				PA.px(img, x, y, band[_tone(u, 0.2)])
	# dessus coulant
	_ell(img, ox + 19.0, 6.8 + sag, 15.0, 4.6, cream, 0.1)
	_ell(img, ox + 14.0, 5.2 + sag, 5.0, 1.4, cream, 0.5)
	# coulures qui descendent le long du flanc
	_cap(img, ox + 6.5, 9.0 + sag, ox + 6.5, 15.0, 1.6, 1.4, cream, 0.1)
	_cap(img, ox + 30.0, 9.0 + sag, ox + 30.0, 14.0, 1.7, 1.5, cream, 0.1)
	_cap(img, ox + 19.0, 9.0 + sag, ox + 19.5, 11.0 + sag * 0.5, 1.2, 1.1, cream, 0.1)
	# trous
	for p: Vector2i in [Vector2i(12, 5), Vector2i(24, 6), Vector2i(4, 17), Vector2i(31, 17)]:
		PA.rect(img, ox + p.x, p.y + sag, 2, 2, rind[0] if p.y > 12 else cream[1])
		PA.px(img, ox + p.x + 1, p.y + sag + 1, rind[3] if p.y > 12 else cream[3])
	# visage : yeux ronds, bouche en fer à cheval renversé
	_eye(img, ox + 11, 12 + sag, 3, 3)
	_eye(img, ox + 23, 12 + sag, 3, 3)
	PA.rect(img, ox + 11, 11 + sag, 3, 1, rind[0])
	PA.rect(img, ox + 23, 11 + sag, 3, 1, rind[0])
	PA.line(img, ox + 15, 17 + sag, ox + 17, 16 + sag, dark)
	PA.rect(img, ox + 17, 16 + sag, 4, 1, dark)
	PA.line(img, ox + 21, 16 + sag, ox + 23, 17 + sag, dark)


## Rat de cave : long, gris, les dents en avant, la queue qui traîne.
static func _rat(img: Image, ox: int, f: int) -> void:
	var mid := _ramp("#7c7886")
	var light := _ramp("#aaa6b4")
	var pink := _ramp("#e0a0a8")
	var dark := _ramp("#4a4650")
	var dy := f
	# queue en point d'interrogation
	_cap(img, ox + 8.0, 17.5 + dy, ox + 3.5, 18.5 + dy, 0.8, 0.7, pink)
	_cap(img, ox + 3.5, 18.5 + dy, ox + 1.8, 14.0 + dy, 0.7, 0.6, pink)
	# pattes
	for x: int in [12, 15, 23, 26]:
		var r := _dim(dark) if x < 20 else dark
		_cap(img, ox + x + 1.0, 21.0 + dy, ox + x + 1.0, 24.0, 1.0, 1.0, r)
		PA.px(img, ox + x + 2, 24, pink[2])
	# corps, croupe, ventre clair, tête, museau
	_ell(img, ox + 18.0, 16.0 + dy, 11.0, 6.0, mid)
	_ell(img, ox + 12.0, 16.5 + dy, 6.0, 5.2, mid, 0.1)
	_ell(img, ox + 18.0, 19.8 + dy, 8.0, 2.4, light)
	_ell(img, ox + 29.0, 15.0 + dy, 6.0, 5.0, mid, 0.05)
	_ell(img, ox + 35.0, 16.5 + dy, 3.8, 2.7, light, 0.05)
	# oreille ronde, œil, nez, dents
	_ell(img, ox + 26.5, 9.5 + dy, 3.2, 3.2, mid, 0.1)
	_ell(img, ox + 26.5, 9.8 + dy, 1.7, 1.7, pink)
	_eye(img, ox + 30, 12 + dy, 3, 3)
	PA.px(img, ox + 38, 16 + dy, pink[1])
	PA.px(img, ox + 38, 17 + dy, pink[1])
	PA.rect(img, ox + 35, 19 + dy, 2, 2, Color.WHITE)
	PA.px(img, ox + 36, 20 + dy, light[1])
	# moustaches
	PA.line(img, ox + 36, 17 + dy, ox + 39, 15 + dy, light[3])
	PA.line(img, ox + 36, 18 + dy, ox + 39, 19 + dy, light[3])


## Coq : droit comme un i, crête haute, queue en panache. Rien ne le ramollit.
static func _rooster(img: Image, ox: int, f: int) -> void:
	var rust := _ramp("#b4562c")
	var rust_l := _ramp("#e08a48")
	var gold := _ramp("#e8b84a")
	var red := _ramp("#d8302c")
	var green := _ramp("#2e8a6a")
	var blue := _ramp("#2a5aa0")
	var beak := _ramp("#f0c040")
	var wing := _ramp("#8a3a20")
	var dark := _c("#2b1b2e")
	var puff := f   # la poitrine se gonfle à la seconde pose
	# queue en panache, derrière le corps
	_cap(img, ox + 9.0, 24.0, ox + 3.0, 8.0, 1.6, 0.8, green)
	_cap(img, ox + 10.0, 23.0, ox + 6.0, 6.0, 1.6, 0.8, blue)
	_cap(img, ox + 11.0, 24.0, ox + 10.0, 5.0, 1.5, 0.8, green)
	_cap(img, ox + 8.0, 26.0, ox + 2.0, 14.0, 1.6, 0.8, blue)
	# pattes et éperons
	_cap(img, ox + 16.0, 32.0, ox + 16.0, 37.0, 1.0, 1.0, beak)
	_cap(img, ox + 23.0, 32.0, ox + 23.0, 37.0, 1.0, 1.0, beak)
	PA.rect(img, ox + 13, 37, 5, 1, beak[3])
	PA.rect(img, ox + 20, 37, 5, 1, beak[3])
	# corps, poitrine, aile
	_ell(img, ox + 17.0, 25.0, 11.0, 8.5, rust)
	_ell(img, ox + 24.0, 25.0, 7.0 + puff, 7.0 + puff, rust_l, 0.1)
	_ell(img, ox + 15.0, 25.0, 7.0, 4.5, wing, 0.1)
	# cou et collerette dorée, tête
	_ell(img, ox + 26.0, 16.0, 4.5, 7.0, gold)
	_ell(img, ox + 29.0, 10.0, 4.5, 4.5, rust_l, 0.1)
	# crête, barbillon, bec
	_ell(img, ox + 27.0, 4.5, 1.8, 2.2, red, 0.1)
	_ell(img, ox + 29.5, 4.0, 1.8, 2.4, red, 0.1)
	_ell(img, ox + 32.0, 5.0, 1.6, 2.0, red, 0.1)
	_ell(img, ox + 33.0, 14.5, 1.4, 2.6, red, 0.1)
	_ell(img, ox + 35.0, 10.0, 2.9, 1.3, beak, 0.2)
	PA.px(img, ox + 37, 10, beak[2])
	PA.rect(img, ox + 33, 11, 4, 1, beak[1])
	# œil rond et sourcil sévère
	_eye(img, ox + 30, 8, 3, 3)
	PA.rect(img, ox + 30, 7, 4, 1, dark)


## Chamois : sabots sûrs, cornes en crochet, regard de celui qui a déjà tout vu de là-haut.
static func _chamois(img: Image, ox: int, f: int) -> void:
	var dark := _c("#3a2c24")
	var mid := _c("#8a6a48")
	var light := _c("#c9a77a")
	var cream := _c("#efe2c4")
	var dy := f
	for x: int in [10, 13, 26, 29]:
		PA.rect(img, ox + x, 25 + dy, 2, 9 - dy, dark)
	PA.ellipse(img, ox + 20.0, 20.0 + dy, 12.0, 6.5, mid)
	PA.ellipse(img, ox + 20.0, 24.0 + dy, 9.0, 2.4, light)
	PA.ellipse(img, ox + 31.0, 15.0 + dy, 4.5, 6.5, mid)
	PA.ellipse(img, ox + 33.5, 14.0 + dy, 5.0, 4.5, mid)
	PA.ellipse(img, ox + 38.0, 17.0 + dy, 3.2, 2.6, cream)
	PA.rect(img, ox + 4, 16 + dy, 3, 3, dark)
	PA.line(img, ox + 31, 10 + dy, ox + 30, 4 + dy, dark)
	PA.line(img, ox + 30, 4 + dy, ox + 34, 2 + dy, dark)
	PA.line(img, ox + 34, 10 + dy, ox + 36, 4 + dy, dark)
	PA.line(img, ox + 36, 4 + dy, ox + 39, 4 + dy, dark)
	PA.ellipse(img, ox + 29.0, 9.5 + dy, 2.0, 1.4, light)
	PA.rect(img, ox + 34, 12 + dy, 3, 3, Color.WHITE)
	PA.rect(img, ox + 34, 12 + dy, 3, 1, dark)
	PA.px(img, ox + 36, 14 + dy, dark)
	PA.px(img, ox + 41, 17 + dy, dark)


## Parchemin vivant : un rouleau debout, couvert de petites lignes, le coin retroussé.
static func _scroll(img: Image, ox: int, f: int) -> void:
	var paper := _c("#e8d8a8")
	var shade := _c("#c2ae78")
	var ink := _c("#4a3a2c")
	var roll := _c("#b89a5c")
	var dy := f
	PA.rect(img, ox + 6, 6 + dy, 16, 22 - dy, paper)
	PA.rect(img, ox + 19, 6 + dy, 3, 22 - dy, shade)
	PA.ellipse(img, ox + 14.0, 6.0 + dy, 9.0, 3.2, roll)
	PA.ellipse(img, ox + 14.0, 6.0 + dy, 5.0, 1.4, shade)
	PA.ellipse(img, ox + 14.0, 28.0, 9.0, 3.2, roll)
	PA.ellipse(img, ox + 14.0, 28.0, 5.0, 1.4, shade)
	for y: int in [10, 12, 23, 25]:
		PA.rect(img, ox + 8, y + dy, 8 + (y % 3) * 2, 1, ink)
	PA.rect(img, ox + 4, 30, 4, 3, shade)
	PA.rect(img, ox + 20, 30, 4, 3, shade)
	PA.line(img, ox + 22, 14 + dy, ox + 25, 11 + dy, shade)
	PA.line(img, ox + 6, 14 + dy, ox + 3, 17 + dy, shade)


## Tampon zélé : bois, caoutchouc rouge, mine de celui qui valide tout ce qui passe.
static func _stamp(img: Image, ox: int, f: int) -> void:
	var wood := _c("#9a6a3c")
	var wood_d := _c("#5e3e22")
	var wood_l := _c("#c8945c")
	var rub := _c("#b83a3a")
	var rub_l := _c("#e06a5a")
	var dy := f
	PA.ellipse(img, ox + 14.0, 3.5 + dy, 3.5, 2.0, wood_l)
	PA.rect(img, ox + 9, 6 + dy, 10, 12 - dy, wood)
	PA.rect(img, ox + 16, 6 + dy, 3, 12 - dy, wood_d)
	PA.rect(img, ox + 4, 18, 20, 6, wood_d)
	PA.rect(img, ox + 4, 18, 20, 1, wood_l)
	PA.rect(img, ox + 3, 24, 22, 5, rub)
	PA.rect(img, ox + 3, 24, 22, 1, rub_l)
	PA.rect(img, ox + 6, 29, 5, 3, wood_d)
	PA.rect(img, ox + 17, 29, 5, 3, wood_d)
