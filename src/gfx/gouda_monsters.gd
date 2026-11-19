extends RefCounted
## Monstres du chapitre 6 : les Éveillés du Sentier, les Boucaniers d'Ombrine, les armées du
## Pelle-à-Tarte (Cassoulétains, Mammous, Dindon de la Farce, Naze Suprême), Gothmoque et la
## Grondine. Mêmes règles que monster_painter.gd (quatre poses, regard vers la droite, rampes de
## cinq tons, lumière en haut à gauche, contour coloré) ; ce fichier réutilise ses outils de
## volume. Appelé depuis `MonsterPainter.paint` par `GM.paint(kind, img, ox, f, col, size)` :
## f = pose de respiration (0 ou 1), col = colonne (2 attaque, 3 coup reçu).
## Toutes les coordonnées sont « logiques » (celles de la petite case) : les outils de
## `monster_painter.gd` les multiplient par `MP.K` ; ne jamais appeler `PA.rect` & co. directement
## (ils ne connaissent pas K : le visage resterait un point dans un coin de la planche).

const PA = preload("res://src/gfx/pixel_art.gd")
const MP = preload("res://src/gfx/monster_painter.gd")

const KINDS: Array[String] = ["eveille", "eveille_veilleur", "roi_eveille", "boucanier", "saumure", "cassouletain",
		"gothmoque", "naze_supreme", "mammou", "dindon_farce", "grondine"]

const SIZES := {
	"eveille": Vector2i(48, 64), "eveille_veilleur": Vector2i(56, 72), "roi_eveille": Vector2i(84, 100),
	"boucanier": Vector2i(52, 64), "saumure": Vector2i(76, 92), "cassouletain": Vector2i(56, 68),
	"gothmoque": Vector2i(96, 108), "naze_supreme": Vector2i(76, 100), "mammou": Vector2i(100, 76),
	"dindon_farce": Vector2i(88, 88), "grondine": Vector2i(100, 66),
}

const INK := Color("#1c1222")


static func paint(kind: String, img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	match kind:
		"eveille": _ghost(img, ox, f, col, size, {"skin": "#aebcc8", "gown": "#cfd8e0", "eye": "#d8503e", "cap": "#6a7ab8", "light": false})
		"eveille_veilleur": _ghost(img, ox, f, col, size, {"skin": "#98a8b8", "gown": "#8fa0b8", "eye": "#e89a3a", "cap": "#b87a4a", "light": true})
		"roi_eveille": _king(img, ox, f, col, size)
		"boucanier": _man(img, ox, f, col, size, {"skin": "#d0a078", "cloth": "#8a2a2a", "trim": "#e8e4d8", "pants": "#3a3a4e", "head": "bandana",
				"weapon": "sabre", "head_c": "#2a2a38", "stripe": true, "patch": true})
		"saumure": _man(img, ox, f, col, size, {"skin": "#c89468", "cloth": "#2a3a58", "trim": "#e8c050", "pants": "#1e2438", "head": "tricorne",
				"weapon": "sabre", "head_c": "#1c1c28", "big": true, "beard": "#e8e4d8", "coat": true})
		"cassouletain": _man(img, ox, f, col, size, {"skin": "#a8744a", "cloth": "#b8602a", "trim": "#e8d8a0", "pants": "#5a3a2a", "head": "marmite",
				"weapon": "lance", "head_c": "#5a4a3a", "shield": true})
		"gothmoque": _man(img, ox, f, col, size, {"skin": "#8a7a68", "cloth": "#4a4a56", "trim": "#c8c4b8", "pants": "#2e2e38", "head": "cornes",
				"weapon": "massue", "head_c": "#3a3a46", "big": true, "fur": true, "scar": true})
		"naze_supreme": _wraith(img, ox, f, col, size)
		"mammou": _mammoth(img, ox, f, col, size)
		"dindon_farce": _turkey(img, ox, f, col, size)
		"grondine": _ram(img, ox, f, col, size)
		_: MP._rect(img, ox + 4, 4, size.x - 8, size.y - 8, Color.MAGENTA)


# ------------------------------------------------------------------ petits outils

## Rectangle aux coordonnées flottantes (logiques), non arrondi.
static func _b(img: Image, x: float, y: float, w: float, h: float, c: Color) -> void:
	var k := MP.K
	PA.rect(img, roundi(x * k), roundi(y * k), maxi(1, roundi(w * k)), maxi(1, roundi(h * k)), c)


static func _disc(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	MP._ellipse(img, cx, cy, r, r, c)


static func _flat(c: Color) -> Array:
	return [c, c, c, c, c]


## Ellipsoïde éclairé cerclé d'un liseré sombre de sa propre couleur : sépare les pièces entre elles.
static func _o(img: Image, cx: float, cy: float, rx: float, ry: float, ramp: Array, bias: float = 0.0) -> void:
	MP._ellipse(img, cx, cy, rx + 0.5, ry + 0.5, (ramp[0] as Color).darkened(0.35))
	MP._ell(img, cx, cy, rx, ry, ramp, bias)


## Capsule éclairée avec liseré.
static func _cp(img: Image, x0: float, y0: float, x1: float, y1: float, r0: float, r1: float, ramp: Array, bias: float = 0.0) -> void:
	MP._cap(img, x0, y0, x1, y1, r0 + 0.5, r1 + 0.5, _flat((ramp[0] as Color).darkened(0.35)))
	MP._cap(img, x0, y0, x1, y1, r0, r1, ramp, bias)


## Trapèze avec liseré.
static func _tp(img: Image, y0: float, y1: float, xl0: float, xr0: float, xl1: float, xr1: float, ramp: Array, bias: float = 0.0) -> void:
	var rim: Color = (ramp[0] as Color).darkened(0.35)
	MP._trap(img, int(round(y0)) - 1, int(round(y1)) + 1, xl0 - 0.5, xr0 + 0.5, xl1 - 0.5, xr1 + 0.5, _flat(rim))
	MP._trap(img, int(round(y0)), int(round(y1)), xl0, xr0, xl1, xr1, ramp, bias)


static func _tri(img: Image, a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	MP._tri(img, a, b, c, col)


## Plis d'étoffe : traits verticaux plus sombres, un peu courbes.
static func _folds(img: Image, xs: Array, y0: float, y1: float, ramp: Array, sway: float = 0.0) -> void:
	for i in xs.size():
		var x: float = xs[i]
		MP._cap(img, x, y0, x + sway * 0.5, y1, 0.45, 0.9, _flat(ramp[1]))
		MP._cap(img, x + 0.9, y0 + 1.0, x + 0.9 + sway * 0.5, y1 - 1.0, 0.3, 0.45, _flat(ramp[3]))


## Bas de chemise de fantôme : le tissu se resserre puis se défait en trois volutes courbes.
static func _tail(img: Image, cx: float, y0: float, y1: float, hw: float, sway: float, ramp: Array) -> void:
	var dr := MP._dim(ramp)
	var ym := y0 + (y1 - y0) * 0.35
	MP._trap(img, int(round(y0 - 0.5)), int(round(ym)), cx - hw, cx + hw, cx - hw * 0.7, cx + hw * 0.7, dr)   # sans liseré : il traçait une ligne sous le ventre
	for i in 3:
		var u := float(i) - 1.0
		var bx := cx + u * hw * 0.5
		var mx := bx + u * hw * 0.15 + sway * 0.6
		var tx := bx + u * hw * 0.3 + sway * (1.0 + u * 0.4)
		var ty := y1 - absf(u) * (y1 - ym) * 0.18
		_cp(img, bx, ym - 1.0, mx, (ym + ty) * 0.5, hw * 0.42, hw * 0.3, dr)
		_cp(img, mx, (ym + ty) * 0.5, tx, ty, hw * 0.3, 0.4, dr)
	_folds(img, [cx - hw * 0.4, cx + hw * 0.3], y0, ym, dr)


## Œil à la définition HD : globe cerclé, iris, pupille, reflet. mode : 0 ouvert, 1 plissé (coup
## reçu), 2 furieux (sourcil rabattu vers `inner`, +1 si le côté du nez est à droite).
static func _eye(img: Image, cx: float, cy: float, rx: float, ry: float, iris: Color, mode: int = 0, inner: int = 1) -> void:
	if mode == 1:
		MP._cap(img, cx - rx, cy + ry * 0.2, cx + rx, cy + ry * 0.2, 0.35, 0.35, _flat(INK))
		MP._cap(img, cx - rx * 0.8, cy - ry * 0.5, cx + rx * 0.8, cy - ry * 0.3, 0.3, 0.3, _flat(INK))
		return
	MP._ellipse(img, cx, cy, rx + 0.4, ry + 0.4, iris.darkened(0.75))
	MP._ellipse(img, cx, cy, rx, ry, Color("#f6f1ec"))
	MP._ellipse(img, cx, cy - ry * 0.55, rx * 0.95, ry * 0.45, Color("#e0d8dc"))
	var ir := minf(rx, ry) * 0.9
	MP._ellipse(img, cx + rx * 0.2, cy + ry * 0.1, ir, ir, iris.darkened(0.25))
	MP._ellipse(img, cx + rx * 0.2, cy + ry * 0.15, ir * 0.78, ir * 0.78, iris)
	MP._ellipse(img, cx + rx * 0.25, cy + ry * 0.15, ir * 0.4, ir * 0.4, INK)
	MP._ellipse(img, cx - rx * 0.1, cy - ry * 0.3, maxf(0.35, ir * 0.22), maxf(0.35, ir * 0.22), Color.WHITE)
	if mode == 2:
		var s := float(inner)
		_tri(img, Vector2(cx - s * (rx + 0.8), cy - ry - 1.1), Vector2(cx + s * (rx + 0.8), cy - ry * 0.5),
				Vector2(cx + s * (rx + 0.8), cy - ry - 0.2), INK)
		_tri(img, Vector2(cx - s * (rx + 0.8), cy - ry - 1.1), Vector2(cx + s * (rx + 0.8), cy - ry - 0.2),
				Vector2(cx - s * (rx + 0.8), cy - ry * 0.3), INK)


## Bouche : ligne (repos), gueule ouverte (attaque), grimace (coup reçu).
static func _mouth(img: Image, cx: float, cy: float, w: float, col: int) -> void:
	if col == 2:
		MP._ellipse(img, cx, cy + 0.3, w * 0.5 + 0.4, w * 0.3 + 0.4, INK)
		MP._ellipse(img, cx, cy + 0.3, w * 0.5, w * 0.3, Color("#5a1426"))
		MP._ellipse(img, cx, cy + w * 0.3, w * 0.3, w * 0.12, Color("#d8506a"))
		_b(img, cx - w * 0.4, cy - w * 0.1, w * 0.8, 0.7, Color("#f4ecdc"))
	elif col == 3:
		MP._cap(img, cx - w * 0.5, cy + 0.5, cx - w * 0.15, cy - 0.3, 0.3, 0.3, _flat(INK))
		MP._cap(img, cx - w * 0.15, cy - 0.3, cx + w * 0.15, cy + 0.5, 0.3, 0.3, _flat(INK))
		MP._cap(img, cx + w * 0.15, cy + 0.5, cx + w * 0.5, cy - 0.3, 0.3, 0.3, _flat(INK))
	else:
		MP._cap(img, cx - w * 0.5, cy, cx + w * 0.5, cy - 0.2, 0.3, 0.3, _flat(INK))


# ------------------------------------------------------------------ Éveillés

## Un Éveillé : somnambule en chemise de nuit qui s'effile en volutes, cernes violets, grands yeux
## injectés, bonnet de nuit à pompon. Sans bougie : une tasse de café. Avec : la lanterne du veilleur.
static func _ghost(img: Image, ox: int, f: int, col: int, size: Vector2i, p: Dictionary) -> void:
	var cx := ox + 22.0 - (1.5 if col == 3 else 0.0)
	var dy := float(f) * 0.8
	var sway := float(f) * 1.6
	var skin := MP._ramp(str(p["skin"]))
	var gown := MP._ramp(str(p["gown"]))
	var cap := MP._ramp(str(p["cap"]))
	var h := float(size.y)
	var s := h / 64.0
	_tail(img, cx + 0.5, h * 0.7, h * 0.98, 11.0 * s, sway, gown)
	# chemise
	_tp(img, h * 0.38 + dy, h * 0.72, cx - 7.5 * s, cx + 8.0 * s, cx - 12.0 * s, cx + 13.0 * s, gown)
	_o(img, cx - 6.5 * s, h * 0.42 + dy, 4.0 * s, 2.6 * s, gown, 0.1)   # épaules rondes
	_o(img, cx + 7.0 * s, h * 0.42 + dy, 4.0 * s, 2.6 * s, gown, 0.1)
	_folds(img, [cx - 6.0 * s, cx - 1.0 * s, cx + 4.0 * s, cx + 9.0 * s], h * 0.5 + dy, h * 0.7, gown, sway * 0.4)
	for i in 3:   # boutons
		_disc(img, cx + 2.0 * s, h * 0.45 + dy + float(i) * 3.2 * s, 0.7, gown[0])
	_o(img, cx + 0.5, h * 0.4 + dy, 7.0 * s, 2.2 * s, gown, 0.1)   # col
	# bras arrière, pendant
	_cp(img, cx - 6.0 * s, h * 0.45 + dy, cx - 10.0 * s, h * 0.6, 2.4 * s, 2.0 * s, MP._dim(gown))
	_o(img, cx - 10.5 * s, h * 0.62, 2.0 * s, 2.0 * s, MP._dim(skin))
	# bras avant, tendu vers l'avant ; levé à l'attaque, jeté en arrière au coup reçu
	var hx := cx + 17.0 * s
	var hy := h * 0.47 + dy
	if col == 2:
		hx = cx + 15.0 * s
		hy = h * 0.22
	elif col == 3:
		hx = cx + 6.0 * s
		hy = h * 0.34
	_cp(img, cx + 6.0 * s, h * 0.43 + dy, hx - 1.5, hy, 2.6 * s, 2.2 * s, gown)
	_o(img, hx, hy, 2.3 * s, 2.0 * s, skin, 0.05)
	if bool(p["light"]):   # la lanterne du veilleur
		var lx := hx + 0.5
		var ly := hy + 1.0
		MP._cap(img, lx, ly - 1.0, lx, ly - 5.0 * s, 0.35, 0.35, _flat(Color("#4a3a2a")))
		_b(img, lx - 3.0 * s, ly - 1.0, 6.0 * s, 1.0, Color("#3a2a20"))
		_o(img, lx, ly + 3.4 * s, 3.2 * s, 3.6 * s, MP._ramp("#ffd870"), 0.4)
		_o(img, lx, ly + 3.4 * s, 1.5 * s, 2.2 * s, MP._ramp("#fff6c0"), 0.6)
		_b(img, lx - 3.4 * s, ly + 0.6, 6.8 * s, 0.7, Color("#4a3a2a"))
		_b(img, lx - 3.4 * s, ly + 6.2 * s, 6.8 * s, 0.7, Color("#4a3a2a"))
	else:   # la tasse de café, vide depuis longtemps
		var mx := hx + 1.5
		var my := hy - 1.5
		_o(img, mx + 3.4 * s, my + 1.2, 1.6 * s, 1.8 * s, MP._ramp("#e8e0d0"))
		_o(img, mx, my, 3.0 * s, 3.4 * s, MP._ramp("#e8e0d0"))
		_b(img, mx - 2.2 * s, my - 2.4 * s, 4.4 * s, 1.0, Color("#4a2a1a"))
	# tête : ovale, nez, oreille
	var hcx := cx + 1.0
	var hcy := h * 0.24 + dy
	_o(img, hcx, hcy, 8.6 * s, 9.0 * s, skin, 0.05)
	_o(img, hcx - 8.0 * s, hcy + 1.0, 1.6 * s, 2.4 * s, MP._dim(skin))
	_o(img, hcx + 7.6 * s, hcy + 2.0, 1.8 * s, 1.5 * s, skin, 0.1)   # nez
	var mode := 0
	if col == 3:
		mode = 1
	elif col == 2:
		mode = 2
	for e in 2:
		var ex := hcx - 3.0 * s + float(e) * 6.2 * s
		var ey := hcy - 0.5 * s
		MP._ellipse(img, ex, ey + 3.0 * s, 3.4 * s, 1.5 * s, Color("#6a5a86"))   # cernes
		_eye(img, ex, ey, 2.6 * s, 2.9 * s, Color(str(p["eye"])), mode, 1 if e == 0 else -1)
	_mouth(img, hcx + 2.0 * s, hcy + 6.2 * s, 4.0 * s, col)
	# bonnet de nuit : tube qui retombe sur le côté, bord rayé, pompon
	_cp(img, hcx - 1.0, hcy - 7.0 * s, hcx - 9.0 * s, hcy - 2.0 * s + sway, 5.0 * s, 1.4 * s, cap)
	_tp(img, hcy - 8.5 * s, hcy - 5.4 * s, hcx - 7.0 * s, hcx + 7.0 * s, hcx - 8.0 * s, hcx + 8.0 * s, MP._ramp("#f0ead8"))
	for i in 5:
		_b(img, hcx - 6.5 * s + float(i) * 3.0 * s, hcy - 8.0 * s, 1.3, 2.2 * s, (cap[1] as Color))
	_o(img, hcx - 10.0 * s, hcy - 1.0 * s + sway, 2.1 * s, 2.1 * s, MP._ramp("#f4efe0"), 0.15)


## Roi des Éveillés : fantôme couronné, cape de veille bordée d'hermine, bassinoire en guise de sceptre.
static func _king(img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	var w := float(size.x)
	var h := float(size.y)
	var lean := -2.0 if col == 3 else 0.0
	var cx := ox + w * 0.44 + lean
	var dy := float(f) * 1.0
	var sway := float(f) * 2.0
	var skin := MP._ramp("#a8b8c4")
	var robe := MP._ramp("#3a4a78")
	var cape := MP._ramp("#5a2a4a")
	var fur := MP._ramp("#ece8dc")
	var gold := MP._ramp("#e8c050")
	var copper := MP._ramp("#c87a3a")
	# cape derrière : large, déchirée en bas
	_tp(img, h * 0.3 + dy, h * 0.86, cx - 17.0, cx + 14.0, cx - 31.0, cx + 20.0, cape)
	_folds(img, [cx - 24.0, cx - 17.0, cx - 10.0], h * 0.5, h * 0.84, cape, sway * 0.5)
	for i in 7:
		var tx := cx - 31.0 + float(i) * 7.2
		_tri(img, Vector2(tx, h * 0.84), Vector2(tx + 7.0, h * 0.84), Vector2(tx + 3.2 + sway * 0.4, h * 0.97), cape[1])
	# robe : volutes de fantôme en bas
	_tp(img, h * 0.34 + dy, h * 0.76, cx - 12.0, cx + 13.0, cx - 17.0, cx + 18.0, robe)
	_tail(img, cx + 0.5, h * 0.74, h * 0.99, 20.0, sway, robe)   # (après la robe : son liseré du bas ne traverse plus le tissu)
	MP._ell(img, cx + 0.5, h * 0.55 + dy, 17.0, h * 0.2, robe, 0.05)   # ventre rond, sans liseré (il traçait une ligne sous le ventre)
	_o(img, cx - 11.0, h * 0.38 + dy, 7.0, 5.0, robe, 0.1)   # épaules rondes
	_o(img, cx + 12.0, h * 0.38 + dy, 7.0, 5.0, robe, 0.1)
	_folds(img, [cx - 14.0, cx - 7.0, cx + 3.0, cx + 10.0, cx + 16.0], h * 0.5 + dy, h * 0.74, robe, sway * 0.3)
	for i in 6:   # lunes et étoiles brodées
		var mx := cx - 12.0 + float(i % 3) * 11.0 + float(i / 3) * 4.0
		var my := h * 0.5 + float(i / 3) * 14.0 + dy
		_disc(img, mx, my, 1.7, gold[2])
		_disc(img, mx + 0.8, my - 0.5, 1.4, robe[2])
	# ceinture dorée
	_tp(img, h * 0.6 + dy, h * 0.635 + dy, cx - 16.0, cx + 17.0, cx - 16.5, cx + 17.5, gold)
	_o(img, cx + 1.0, h * 0.62 + dy, 2.6, 2.2, gold, 0.1)
	# collet d'hermine avec mouchetures
	_o(img, cx + 0.5, h * 0.385 + dy, 17.0, h * 0.075, fur, 0.1)
	for i in 6:
		_tri(img, Vector2(cx - 12.0 + float(i) * 5.0, h * 0.42 + dy), Vector2(cx - 12.0 + float(i) * 5.0 + 1.2, h * 0.42 + dy + 3.0), Vector2(cx - 12.0 + float(i) * 5.0 + 2.4, h * 0.42 + dy), Color("#2a2a34"))
	# bras arrière : tient un oreiller
	_cp(img, cx - 14.0, h * 0.44 + dy, cx - 20.0, h * 0.6, 4.0, 3.4, MP._dim(robe))
	_o(img, cx - 21.0, h * 0.62, 3.2, 3.0, MP._dim(skin))
	_o(img, cx - 25.0, h * 0.66, 6.2, 4.4, MP._ramp("#e8e4f0"), 0.05)
	_b(img, cx - 29.0, h * 0.655, 8.0, 0.7, Color("#a8a0c0"))
	# bras avant : la bassinoire
	var hx := cx + 25.0
	var hy := h * 0.5 + dy
	if col == 2:
		hx = cx + 20.0
		hy = h * 0.34
	elif col == 3:
		hx = cx + 17.0
		hy = h * 0.55
	_cp(img, cx + 13.0, h * 0.44 + dy, hx - 2.0, hy, 4.4, 3.6, robe)
	_o(img, hx, hy, 3.2, 3.0, skin, 0.05)
	var reach := 25.0 if col != 2 else 17.0   # levée à l'attaque, la bassinoire reste dans la case
	_cp(img, hx, hy + 6.0, hx + 2.0, hy - reach, 1.1, 1.1, MP._ramp("#7a5632"))   # long manche
	_o(img, hx + 2.6, hy - reach - 4.0, 8.4, 8.0, copper, 0.1)
	_o(img, hx + 2.6, hy - reach - 4.0, 6.0, 5.6, MP._ramp("#a8602a"), 0.0)
	for i in 8:   # couvercle percé
		var a := float(i) * TAU / 8.0
		_disc(img, hx + 2.6 + cos(a) * 3.8, hy - reach - 4.0 + sin(a) * 3.4, 0.7, Color("#3a1e12"))
	_disc(img, hx + 2.6, hy - reach - 4.0, 1.4, copper[4])
	# tête
	var hcx := cx + 2.0
	var hcy := h * 0.25 + dy
	_o(img, hcx, hcy, 11.5, 12.0, skin, 0.05)
	_o(img, hcx + 10.5, hcy + 2.5, 2.4, 2.0, skin, 0.1)   # nez
	var mode := 0
	if col == 3:
		mode = 1
	elif col == 2:
		mode = 2
	for e in 2:
		var ex := hcx - 3.8 + float(e) * 8.0
		var ey := hcy - 1.0
		MP._ellipse(img, ex, ey + 4.2, 4.6, 2.0, Color("#5a4a78"))
		_eye(img, ex, ey, 3.4, 3.8, Color("#e8402e"), mode, 1 if e == 0 else -1)
	# moustache et barbe de veille
	_mouth(img, hcx + 2.5, hcy + 8.0, 5.5, col)
	_o(img, hcx - 1.5, hcy + 6.2, 5.0, 1.8, MP._ramp("#e8e4d8"), 0.1)   # moustache en deux moitiés
	_o(img, hcx + 6.5, hcy + 6.2, 5.0, 1.8, MP._ramp("#e8e4d8"), 0.1)
	_o(img, hcx + 1.5, hcy + 12.0, 7.2, 5.4, MP._ramp("#e8e4d8"), 0.1)   # barbe en nuage, plus d'entonnoir
	_o(img, hcx + 1.0, hcy + 17.5, 5.0, 4.4, MP._ramp("#e8e4d8"), 0.05)
	_o(img, hcx + 1.0, hcy + 21.5, 2.8, 2.6, MP._ramp("#e8e4d8"), 0.0)
	_mouth(img, hcx + 2.5, hcy + 8.0, 5.5, col)
	# cheveux blancs qui dépassent de la couronne
	for i in 4:
		_cp(img, hcx - 10.0, hcy - 5.0 + float(i) * 3.0, hcx - 15.0 - float(i % 2) * 2.0 + sway * 0.4, hcy - 1.0 + float(i) * 4.5, 2.0, 0.7, MP._ramp("#ece8dc"))
	# couronne : bandeau, cinq pointes, joyaux
	_tp(img, hcy - 13.0, hcy - 8.2, hcx - 10.5, hcx + 12.0, hcx - 11.5, hcx + 13.0, gold)
	for i in 5:
		var tx := hcx - 10.5 + float(i) * 5.5
		_tri(img, Vector2(tx - 0.6, hcy - 12.6), Vector2(tx + 5.2, hcy - 12.6), Vector2(tx + 2.3, hcy - 20.0), gold[3])
		_disc(img, tx + 2.3, hcy - 19.2, 1.1, Color("#f0e8d0"))
	_disc(img, hcx - 5.0, hcy - 10.4, 1.3, Color("#d8322a"))
	_disc(img, hcx + 2.0, hcy - 10.4, 1.3, Color("#3a8ad8"))
	_disc(img, hcx + 8.0, hcy - 10.4, 1.3, Color("#3ab868"))


# ------------------------------------------------------------------ hommes de guerre

## Humanoïde de guerre. p : skin, cloth, trim, pants, head (bandana, tricorne, marmite, cornes),
## weapon (sabre, lance, massue), head_c, big (carrure), stripe (marinière), beard, coat (longue
## redingote), shield (écu), fur (cape de fourrure), patch (cache-œil), scar (balafre).
static func _man(img: Image, ox: int, f: int, col: int, size: Vector2i, p: Dictionary) -> void:
	var w := float(size.x)
	var h := float(size.y)
	var lean := -w * 0.04 if col == 3 else 0.0
	var cx := ox + w * 0.44
	var dy := float(f) * 0.9
	var big := bool(p.get("big", false))
	var skin := MP._ramp(str(p["skin"]))
	var cloth := MP._ramp(str(p["cloth"]))
	var trim := MP._ramp(str(p["trim"]))
	var pants := MP._ramp(str(p["pants"]))
	var boots := MP._ramp("#4a3226")
	var wide := 0.25 if not big else 0.3
	var gold := MP._ramp("#d8aa44")
	var steel := MP._ramp("#b8c0d0")
	var wood := MP._ramp("#7a5632")
	# jambes et bottes
	_cp(img, cx - w * 0.1, h * 0.68 + dy, cx - w * 0.12, h * 0.93, w * 0.075, w * 0.065, MP._dim(pants))
	_cp(img, cx + w * 0.1, h * 0.68 + dy, cx + w * 0.12, h * 0.93, w * 0.075, w * 0.065, pants)
	_o(img, cx - w * 0.11, h * 0.95, w * 0.1, h * 0.04, MP._dim(boots))
	_o(img, cx + w * 0.15, h * 0.955, w * 0.13, h * 0.042, boots)
	# bras arrière (et écu pour les Cassoulétains) : dessiné avant le torse
	var back_hand := Vector2(cx - w * (wide + 0.06), h * 0.62)
	_cp(img, cx - w * (wide - 0.04), h * 0.43 + dy, back_hand.x, back_hand.y, w * 0.06, w * 0.052, MP._dim(cloth))
	_o(img, back_hand.x, back_hand.y + 1.0, w * 0.052, w * 0.052, MP._dim(skin))
	# torse
	var t0 := h * 0.36 + dy
	var t1 := h * 0.7 + dy
	var xl0 := cx - w * wide
	var xr0 := cx + w * wide
	var xl1 := cx - w * (wide - 0.1)   # taille marquée : un torse en V, plus un bloc
	var xr1 := cx + w * (wide - 0.1)
	if bool(p.get("coat", false)):   # redingote jusqu'aux genoux
		_tp(img, h * 0.66 + dy, h * 0.86, xl1 - 1.0, xr1 + 1.0, cx - w * 0.3, cx + w * 0.3, cloth)
		_tp(img, h * 0.66 + dy, h * 0.86, cx - 0.4, cx + 0.4, cx - 0.8, cx + 0.8, _flat(cloth[0]))
		_b(img, cx - w * 0.3, h * 0.855, w * 0.6, 1.0, trim[2])
	_tp(img, t0 + (t1 - t0) * 0.4, t1, xl0 + w * 0.03, xr0 - w * 0.03, xl1, xr1, cloth)
	_o(img, cx, t0 + (t1 - t0) * 0.36, w * (wide - 0.01), (t1 - t0) * 0.46, cloth, 0.05)   # poitrail arrondi
	_o(img, cx, t1 - (t1 - t0) * 0.08, w * (wide - 0.09), (t1 - t0) * 0.14, cloth, 0.0)   # hanches arrondies (le bas du torse n'est plus une arête)
	_folds(img, [cx - w * 0.14, cx + w * 0.12], t0 + 6.0, t1 - 2.0, cloth)
	if bool(p.get("stripe", false)):
		var y := t0 + 3.0
		while y < t1 - 3.0:
			var t := (y - t0) / (t1 - t0)
			MP._trap(img, int(y), int(y + 2.0), lerpf(xl0, xl1, t) + 0.4, lerpf(xr0, xr1, t) - 0.4, lerpf(xl0, xl1, t) + 0.4, lerpf(xr0, xr1, t) - 0.4, trim)
			y += 5.0
	if bool(p.get("fur", false)):   # cape de fourrure : épaules hérissées
		_o(img, cx - w * 0.2, t0 + 3.0, w * 0.13, h * 0.055, MP._ramp("#6a5a48"), 0.0)
		_o(img, cx + w * 0.2, t0 + 3.0, w * 0.13, h * 0.055, MP._ramp("#6a5a48"), 0.1)
		for i in 9:
			var fx := cx - w * 0.34 + float(i) * w * 0.085
			_tri(img, Vector2(fx, t0 + h * 0.06), Vector2(fx + w * 0.08, t0 + h * 0.06), Vector2(fx + w * 0.04 - 1.0, t0 + h * 0.13), (MP._ramp("#6a5a48")[1] as Color))
	_o(img, xl0 + w * 0.01, t0 + 3.0, w * 0.07, h * 0.05, cloth, 0.1)   # épaules rondes
	_o(img, xr0 - w * 0.01, t0 + 3.0, w * 0.07, h * 0.05, cloth, 0.1)
	# ceinture et boucle
	var by := h * 0.64 + dy
	_tp(img, by, by + h * 0.04, xl1 - 0.4, xr1 + 0.4, xl1 - 0.6, xr1 + 0.6, MP._ramp("#4a3226"))
	_o(img, cx + 1.0, by + h * 0.02, w * 0.04, h * 0.028, gold, 0.15)
	if big and not bool(p.get("fur", false)):   # épaulières
		_o(img, cx - w * 0.27, t0 + 2.0, w * 0.09, h * 0.055, trim)
		_o(img, cx + w * 0.27, t0 + 2.0, w * 0.09, h * 0.055, trim)
	if bool(p.get("coat", false)):   # boutons d'or
		for i in 4:
			_disc(img, cx + w * 0.03, t0 + 5.0 + float(i) * (t1 - t0 - 8.0) / 3.0, 0.9, gold[3])
	# bras armé
	var wy := h * 0.57
	var wx := cx + w * 0.33
	if col == 2:
		wy = h * 0.27
		wx = cx + w * 0.3
	elif col == 3:
		wy = h * 0.62
		wx = cx + w * 0.22
	_cp(img, cx + w * (wide - 0.04), t0 + 3.0, wx, wy, w * 0.065, w * 0.055, cloth)
	_o(img, wx, wy, w * 0.058, w * 0.058, skin, 0.05)
	# arme
	match str(p["weapon"]):
		"sabre":
			var tip := Vector2(wx + w * 0.16, maxf(wy - h * 0.3, h * 0.07))
			if col == 3:
				tip = Vector2(wx + w * 0.12, wy - h * 0.18)
			MP._cap(img, wx, wy, tip.x, tip.y, w * 0.022, w * 0.012, steel)
			MP._cap(img, wx + 0.4, wy - 1.0, tip.x - 0.2, tip.y + 1.0, 0.25, 0.2, _flat(steel[4]))
			_o(img, wx, wy - h * 0.025, w * 0.07, h * 0.012, gold, 0.1)
			_o(img, wx - 0.5, wy + h * 0.03, w * 0.022, h * 0.03, MP._ramp("#5a3a24"))
		"lance":
			var tip2 := Vector2(wx + w * 0.07, maxf(wy - h * 0.5, h * 0.17))
			if col == 3:
				tip2 = Vector2(wx + w * 0.05, wy - h * 0.34)
			MP._cap(img, wx - 1.0, wy + h * 0.16, tip2.x, tip2.y, w * 0.022, w * 0.018, wood)
			_tri(img, Vector2(tip2.x - w * 0.035, tip2.y + h * 0.015), Vector2(tip2.x + w * 0.035, tip2.y + h * 0.015), Vector2(tip2.x, tip2.y - h * 0.1), steel[3])
			_tri(img, Vector2(tip2.x - w * 0.035, tip2.y + h * 0.015), Vector2(tip2.x, tip2.y + h * 0.015), Vector2(tip2.x, tip2.y - h * 0.1), steel[1])
			_b(img, tip2.x - w * 0.05, tip2.y + h * 0.03, w * 0.1, 1.0, Color("#b8321a"))   # fanion
		"massue":
			var head := Vector2(wx + w * 0.07, maxf(wy - h * 0.27, h * 0.16))
			if col == 3:
				head = Vector2(wx + w * 0.05, wy - h * 0.12)
			MP._cap(img, wx, wy + h * 0.06, head.x, head.y, w * 0.026, w * 0.022, wood)
			_o(img, head.x, head.y, w * 0.095, h * 0.085, MP._ramp("#5a5a66"), 0.0)
			for i in 8:   # clous de la massue
				var a := float(i) * TAU / 8.0
				_tri(img, Vector2(head.x + cos(a - 0.25) * w * 0.09, head.y + sin(a - 0.25) * h * 0.08),
						Vector2(head.x + cos(a + 0.25) * w * 0.09, head.y + sin(a + 0.25) * h * 0.08),
						Vector2(head.x + cos(a) * w * 0.15, head.y + sin(a) * h * 0.13), steel[3])
	if bool(p.get("shield", false)):   # écu rond, couvert de haricots blancs
		var sx := cx - w * 0.2
		var sy := h * 0.55
		_o(img, sx, sy, w * 0.16, w * 0.16, MP._ramp("#c8b070"), 0.0)
		_o(img, sx, sy, w * 0.11, w * 0.11, MP._ramp("#e8dcb0"), 0.1)
		for i in 7:
			var a := float(i) * 0.9
			var rr := w * 0.06 * (0.4 + float(i % 3) * 0.3)
			MP._ellipse(img, sx + cos(a) * rr, sy + sin(a) * rr, 1.1, 0.7, Color("#fbf4e0"))
		_disc(img, sx, sy, 1.3, gold[3])
	# tête
	var hcx := cx + lean + w * 0.04
	var hcy := h * (0.29 if str(p["head"]) in ["tricorne", "marmite"] else 0.262) + dy   # plume du tricorne et sommets dégagés du bord
	var hr := w * 0.135
	var hv := h * 0.105
	_cp(img, hcx - hr * 0.3, hcy + hv * 0.6, cx + lean * 0.5, t0 + 3.0, w * 0.045, w * 0.055, MP._dim(skin))
	_o(img, hcx, hcy, hr, hv, skin, 0.05)
	_o(img, hcx + hr * 0.95, hcy + hv * 0.15, w * 0.03, h * 0.03, skin, 0.1)   # nez
	_o(img, hcx - hr * 0.95, hcy + hv * 0.1, w * 0.025, h * 0.03, MP._dim(skin))   # oreille
	var mode := 0
	if col == 3:
		mode = 1
	elif col == 2:
		mode = 2
	var erx := w * 0.034
	var ery := h * 0.026
	for e in 2:
		var ex := hcx - hr * 0.2 + float(e) * hr * 0.75
		var ey := hcy - hv * 0.12
		if bool(p.get("patch", false)) and e == 0 and col != 3:
			MP._cap(img, hcx - hr * 0.7, hcy - hv * 0.8, hcx + hr * 0.5, hcy - hv * 0.1, 0.35, 0.35, _flat(INK))
			_o(img, ex, ey, erx * 1.2, ery * 1.4, MP._ramp("#1e1a22"))
			continue
		_eye(img, ex, ey, erx, ery, Color("#3a2418"), mode, 1 if e == 0 else -1)
	if not bool(p.get("beard", "") != ""):
		_mouth(img, hcx + hr * 0.4, hcy + hv * 0.58, w * 0.085, col)
	if bool(p.get("scar", false)):
		MP._cap(img, hcx - hr * 0.3, hcy - hv * 0.8, hcx + hr * 0.1, hcy + hv * 0.4, 0.3, 0.3, _flat(Color("#d8b0a0")))
	if p.has("beard"):
		_o(img, hcx + hr * 0.3, hcy + hv * 0.85, hr * 0.85, hv * 0.55, MP._ramp(str(p["beard"])), 0.0)
		_mouth(img, hcx + hr * 0.45, hcy + hv * 0.5, w * 0.08, col)
	else:   # barbe de trois jours
		for i in 5:
			_disc(img, hcx - hr * 0.2 + float(i) * hr * 0.25, hcy + hv * 0.9, 0.55, (skin[1] as Color))
	var hc := MP._ramp(str(p["head_c"]))
	match str(p["head"]):
		"bandana":
			_tp(img, hcy - hv * 1.05, hcy - hv * 0.4, hcx - hr * 1.0, hcx + hr * 1.0, hcx - hr * 1.02, hcx + hr * 1.04, MP._ramp("#c8322a"))
			for i in 4:
				_disc(img, hcx - hr * 0.7 + float(i) * hr * 0.5, hcy - hv * 0.72, 0.6, Color("#f4ecdc"))
			_cp(img, hcx - hr * 0.9, hcy - hv * 0.7, hcx - hr * 1.7, hcy - hv * 0.1 + float(f), w * 0.03, w * 0.012, MP._ramp("#c8322a"))
			_o(img, hcx + hr * 0.8, hcy - hv * 0.2, 1.2, 1.7, gold, 0.2)   # anneau d'oreille : en toute innocence
		"tricorne":
			_o(img, hcx, hcy - hv * 1.0, hr * 1.5, h * 0.025, hc)
			_tp(img, hcy - hv * 1.9, hcy - hv * 0.95, hcx - hr * 0.9, hcx + hr * 0.95, hcx - hr * 1.2, hcx + hr * 1.3, hc)
			_tri(img, Vector2(hcx - hr * 1.7, hcy - hv * 1.0), Vector2(hcx - hr * 0.6, hcy - hv * 1.95), Vector2(hcx - hr * 0.6, hcy - hv * 0.95), hc[3])
			_tri(img, Vector2(hcx + hr * 1.8, hcy - hv * 1.0), Vector2(hcx + hr * 0.6, hcy - hv * 1.95), Vector2(hcx + hr * 0.6, hcy - hv * 0.95), hc[2])
			_b(img, hcx - hr * 1.2, hcy - hv * 1.15, hr * 2.5, 1.2, trim[2])
			_o(img, hcx + hr * 0.1, hcy - hv * 2.15, w * 0.07, h * 0.025, MP._ramp("#c8d4d8"), 0.1)   # le poisson sur le chapeau
			_tri(img, Vector2(hcx - hr * 0.5, hcy - hv * 2.15), Vector2(hcx - hr * 0.1, hcy - hv * 2.5), Vector2(hcx - hr * 0.1, hcy - hv * 1.8), Color("#9ab0b8"))
			_disc(img, hcx + hr * 0.45, hcy - hv * 2.2, 0.55, INK)
		"marmite":   # une cassole en guise de casque
			_o(img, hcx, hcy - hv * 1.2, hr * 1.1, hv * 0.8, hc, 0.0)
			_tp(img, hcy - hv * 0.75, hcy - hv * 0.55, hcx - hr * 1.2, hcx + hr * 1.2, hcx - hr * 1.2, hcx + hr * 1.2, MP._ramp("#2a2018"))
			_o(img, hcx - hr * 1.25, hcy - hv * 0.95, 1.5, 2.8, MP._ramp("#3a2a20"))
			_o(img, hcx + hr * 1.25, hcy - hv * 0.95, 1.5, 2.8, MP._ramp("#3a2a20"))
			_o(img, hcx, hcy - hv * 2.0, hr * 0.3, hv * 0.28, MP._ramp("#3a2a20"))   # poignée du couvercle
		"cornes":
			_o(img, hcx, hcy - hv * 0.95, hr * 1.1, hv * 0.62, hc, 0.0)
			_tp(img, hcy - hv * 0.95, hcy - hv * 0.5, hcx - hr * 1.05, hcx + hr * 1.05, hcx - hr * 1.05, hcx + hr * 1.08, MP._ramp("#8a8a96"))
			_cp(img, hcx - hr * 0.9, hcy - hv * 1.1, hcx - hr * 1.8, hcy - hv * 1.9, w * 0.035, w * 0.008, MP._ramp("#f0eadc"))
			_cp(img, hcx + hr * 1.0, hcy - hv * 1.1, hcx + hr * 1.9, hcy - hv * 1.9, w * 0.035, w * 0.008, MP._ramp("#f0eadc"))


# ------------------------------------------------------------------ Naze Suprême

## Naze Suprême : un manteau noir sans personne dedans, deux lueurs sous le capuchon, une couronne
## de clous, une lame ; au doigt, un tout petit anneau qui brille.
static func _wraith(img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	var w := float(size.x)
	var h := float(size.y)
	var lean := -2.5 if col == 3 else 0.0
	var cx := ox + w * 0.44 + lean
	var dy := float(f) * 1.0
	var sway := float(f) * 2.4
	var cloak := MP._ramp("#2c2c3e")
	var inner := MP._ramp("#14141c")
	var iron := MP._ramp("#8a8a9c")
	# grande cape cramoisie qui flotte derrière, ourlée de lueur : la silhouette se détache du fond
	var cape := MP._ramp("#7a1a2a")
	_tp(img, h * 0.27 + dy, h * 0.93, cx - w * 0.2, cx + w * 0.2, cx - w * 0.42 + sway, cx + w * 0.38 - sway * 0.5, MP._dim(cape))
	for i in 5:
		var ty2 := h * 0.93
		var tx4 := cx - w * 0.42 + sway + float(i) * w * 0.16
		_tri(img, Vector2(tx4, ty2 - 1.0), Vector2(tx4 + w * 0.15, ty2 - 1.0), Vector2(tx4 + w * 0.07 - float(i % 2) * 2.0, ty2 + 4.0), cape[1])
	# traîne du manteau, déchirée, soulevée par un vent qui n'existe pas
	_tp(img, h * 0.3 + dy, h * 0.88, cx - w * 0.22, cx + w * 0.22, cx - w * 0.34 + sway, cx + w * 0.3, MP._dim(cloak))
	# manteau de face
	_tp(img, h * 0.3 + dy, h * 0.9, cx - w * 0.17, cx + w * 0.19, cx - w * 0.3 + sway * 0.4, cx + w * 0.3 - sway * 0.3, cloak)
	_folds(img, [cx - w * 0.2, cx - w * 0.1, cx + w * 0.02, cx + w * 0.13, cx + w * 0.22], h * 0.45 + dy, h * 0.88, cloak, sway * 0.3)
	for i in 7:   # lisière en dents régulières, deux hauteurs alternées
		var tx2 := cx - w * 0.3 + sway * 0.4 + float(i) * w * 0.0857
		_tri(img, Vector2(tx2, h * 0.89), Vector2(tx2 + w * 0.0857, h * 0.89), Vector2(tx2 + w * 0.043, h * 0.975 - float(i % 2) * 3.0), cloak[1])
	# runes qui couvent sur le manteau
	var rune := Color("#ff6a4a") if col != 3 else Color("#8a3a30")
	for i in 5:
		var rx2 := cx - w * 0.13 + float(i) * w * 0.065
		var ry2 := h * 0.55 + dy + float((i * 3) % 4) * h * 0.06
		MP._ellipse(img, rx2, ry2, 0.9, 1.7, rune.darkened(0.3))
		MP._ellipse(img, rx2, ry2, 0.5, 1.2, rune.lightened(0.35))
	# braises qui montent
	for i in 6:
		var bx := cx - w * 0.3 + float((i * 37) % 60) * w * 0.01 - sway * 0.2
		var by2 := h * (0.2 + float((i * 53) % 70) * 0.01)
		MP._ellipse(img, bx, by2, 0.7, 0.7, Color("#ff9a4a"))
	# fermoir : une griffe de fer
	_o(img, cx + w * 0.02, h * 0.37 + dy, 2.4, 2.4, iron, 0.1)
	# épaulières de fer
	_o(img, cx - w * 0.18, h * 0.34 + dy, w * 0.09, h * 0.05, iron, 0.0)
	_o(img, cx + w * 0.2, h * 0.34 + dy, w * 0.09, h * 0.05, iron, 0.1)
	_tri(img, Vector2(cx - w * 0.24, h * 0.32 + dy), Vector2(cx - w * 0.14, h * 0.32 + dy), Vector2(cx - w * 0.22, h * 0.24 + dy), iron[3])
	_tri(img, Vector2(cx + w * 0.14, h * 0.32 + dy), Vector2(cx + w * 0.26, h * 0.32 + dy), Vector2(cx + w * 0.24, h * 0.24 + dy), iron[2])
	# bras arrière
	_cp(img, cx - w * 0.17, h * 0.4 + dy, cx - w * 0.28, h * 0.6, w * 0.06, w * 0.05, MP._dim(cloak))
	_o(img, cx - w * 0.29, h * 0.62, w * 0.045, w * 0.045, MP._dim(iron))
	# bras armé : gantelet, anneau, lame
	var hx := cx + w * 0.36
	var hy := h * 0.56
	if col == 2:
		hy = h * 0.4
		hx = cx + w * 0.34
	elif col == 3:
		hx = cx + w * 0.25
		hy = h * 0.58
	_cp(img, cx + w * 0.2, h * 0.4 + dy, hx, hy, w * 0.065, w * 0.055, cloak)
	_o(img, hx, hy, w * 0.055, w * 0.055, iron, 0.05)
	MP._ellipse(img, hx + 1.2, hy + 1.4, 1.5, 1.5, Color("#fff0a0"))   # le petit anneau, bien en vue
	MP._ellipse(img, hx + 1.2, hy + 1.4, 0.9, 0.9, Color("#ffd070"))
	var tip := Vector2(hx + w * 0.07, hy - h * 0.44)
	if col == 2:
		tip = Vector2(hx + w * 0.07, hy - h * 0.34)
	elif col == 3:
		tip = Vector2(hx + w * 0.07, hy - h * 0.26)
	MP._cap(img, hx, hy - 1.0, tip.x, tip.y, w * 0.026, w * 0.008, MP._ramp("#c8d0e0"))
	MP._cap(img, hx + 0.4, hy - 3.0, tip.x - 0.3, tip.y + 2.0, 0.3, 0.2, _flat(Color("#ffffff")))
	_o(img, hx, hy - 2.5, w * 0.075, 1.3, iron, 0.1)
	# capuchon : un vide, deux lueurs
	var hcx := cx + w * 0.02
	var hcy := h * 0.25 + dy
	_o(img, hcx, hcy + 1.0, w * 0.16, h * 0.14, cloak, 0.0)
	_o(img, hcx + 2.0, hcy + 2.0, w * 0.11, h * 0.1, inner, -0.2)
	var glow := Color("#ff5a4a") if col != 3 else Color("#8a2a28")
	for e in 2:
		var ex := hcx + 1.0 + float(e) * w * 0.085
		MP._ellipse(img, ex, hcy + 1.0, 2.3, 1.7, glow.darkened(0.4))
		MP._ellipse(img, ex, hcy + 1.0, 1.7, 1.2, glow)
		MP._ellipse(img, ex - 0.2, hcy + 0.8, 0.8, 0.5, Color("#ffe0b0"))
	if col == 2:   # cri : un trou de plus dans le vide
		MP._ellipse(img, hcx + w * 0.06, hcy + h * 0.07, w * 0.035, h * 0.022, Color("#3a1418"))
	# couronne de clous
	_tp(img, hcy - h * 0.115, hcy - h * 0.075, hcx - w * 0.14, hcx + w * 0.16, hcx - w * 0.15, hcx + w * 0.17, iron)
	for i in 7:
		var tx3 := hcx - w * 0.14 + float(i) * w * 0.045
		_tri(img, Vector2(tx3, hcy - h * 0.11), Vector2(tx3 + w * 0.045, hcy - h * 0.11), Vector2(tx3 + w * 0.022, hcy - h * 0.2 + float(i % 2) * 3.0), Color("#e8c25a") if i % 2 == 0 else iron[3])


# ------------------------------------------------------------------ Mammou

## Mammou : éléphant de guerre laineux à défenses recourbées, palanquin et bannière dans le dos.
static func _mammoth(img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	var w := float(size.x)
	var h := float(size.y)
	var lean := -2.0 if col == 3 else 0.0
	var dy := float(f) * 0.9
	var hide := MP._ramp("#7a6552")
	var fur := MP._ramp("#8a5a38")
	var ivory := MP._ramp("#f2ecd8")
	# pattes : piliers poilus à ongles
	for i in 4:
		var lx: float = ox + w * float([0.24, 0.36, 0.58, 0.7][i])
		var back := i % 2 == 0
		var r := hide
		if back:
			r = MP._dim(hide)
		_cp(img, lx, h * 0.52 + dy, lx + (1.0 if back else -1.0), h * 0.9, w * 0.065, w * 0.06, r)
		_tp(img, h * 0.82, h * 0.9, lx - w * 0.07, lx + w * 0.07, lx - w * 0.08, lx + w * 0.08, MP._dim(fur) if back else fur)
		for k in 3:
			_o(img, lx - w * 0.04 + float(k) * w * 0.04, h * 0.935, w * 0.018, h * 0.018, ivory)
	# corps laineux
	_o(img, ox + w * 0.45, h * 0.42 + dy, w * 0.3, h * 0.26, hide)
	_o(img, ox + w * 0.4, h * 0.34 + dy, w * 0.26, h * 0.2, fur, 0.1)
	for i in 14:   # mèches pendantes sur le flanc et le ventre
		var mx := ox + w * 0.2 + float(i) * w * 0.036
		var top := h * 0.55 + dy + sin(float(i) * 1.7) * 2.0
		_tri(img, Vector2(mx, top), Vector2(mx + w * 0.045, top), Vector2(mx + w * 0.02, top + h * 0.11 + float(i % 3) * 3.0), (fur[1] if i % 2 == 0 else fur[2]))
	# harnais : sangle cloutée et couverture rouge
	_tp(img, h * 0.2 + dy, h * 0.3 + dy, ox + w * 0.26, ox + w * 0.62, ox + w * 0.25, ox + w * 0.65, MP._ramp("#8a2a2a"))
	_b(img, ox + w * 0.25, h * 0.3 + dy, w * 0.4, 1.0, Color("#d8aa44"))
	for i in 6:
		_disc(img, ox + w * 0.29 + float(i) * w * 0.06, h * 0.25 + dy, 0.8, Color("#e8c060"))
	# palanquin : plate-forme, deux montants, un mât à bannière (une serviette)
	_tp(img, h * 0.14 + dy, h * 0.2 + dy, ox + w * 0.3, ox + w * 0.6, ox + w * 0.29, ox + w * 0.62, MP._ramp("#8a5a2a"))
	_b(img, ox + w * 0.31, h * 0.06 + dy, 1.6, h * 0.09, Color("#5a3a1e"))
	_b(img, ox + w * 0.58, h * 0.06 + dy, 1.6, h * 0.09, Color("#5a3a1e"))
	_tp(img, h * 0.05 + dy, h * 0.09 + dy, ox + w * 0.29, ox + w * 0.61, ox + w * 0.3, ox + w * 0.6, MP._ramp("#c9a24a"))
	_cp(img, ox + w * 0.45, h * 0.05 + dy, ox + w * 0.45, 3.0, 0.6, 0.6, MP._ramp("#5a4226"))
	_tri(img, Vector2(ox + w * 0.45, 2.5), Vector2(ox + w * 0.62, 5.5 + float(f)), Vector2(ox + w * 0.45, 10.0), Color("#ece8dc"))
	_b(img, ox + w * 0.46, 4.0, w * 0.1, 0.8, Color("#b8322a"))
	_b(img, ox + w * 0.46, 6.2, w * 0.12, 0.8, Color("#b8322a"))
	# queue
	_cp(img, ox + w * 0.16, h * 0.42 + dy, ox + w * 0.13, h * 0.56, w * 0.022, w * 0.012, hide)
	_o(img, ox + w * 0.125, h * 0.58, w * 0.022, h * 0.04, fur)
	# tête : front bombé, oreille, œil, peinture de guerre
	var hx := ox + w * 0.65 + lean
	var hy := h * 0.36 + dy
	_o(img, hx, hy, w * 0.15, h * 0.22, hide, 0.05)
	_o(img, hx - w * 0.01, hy - h * 0.14, w * 0.13, h * 0.1, fur, 0.1)   # houppe
	_o(img, hx - w * 0.1, hy + h * 0.02, w * 0.075, h * 0.19, MP._ramp("#6a5444"), 0.0)   # oreille
	_o(img, hx - w * 0.095, hy + h * 0.03, w * 0.04, h * 0.14, MP._ramp("#a8786a"), 0.1)
	var mode := 0
	if col == 3:
		mode = 1
	elif col == 2:
		mode = 2
	_eye(img, hx + w * 0.05, hy - h * 0.03, w * 0.03, h * 0.04, Color("#3a2418"), mode, -1)
	_b(img, hx + w * 0.02, hy + h * 0.03, w * 0.07, 1.0, Color("#c8322a"))   # peinture de guerre
	_b(img, hx + w * 0.03, hy + h * 0.06, w * 0.06, 1.0, Color("#c8322a"))
	# trompe : pendante, levée au barrissement
	var tipx := hx + w * 0.16
	var tipy := h * 0.8
	if col == 2:
		tipx = hx + w * 0.2
		tipy = h * 0.16
	elif col == 3:
		tipx = hx + w * 0.06
		tipy = h * 0.74
	var midx := hx + w * 0.16
	var midy := hy + h * 0.2
	_cp(img, hx + w * 0.08, hy + h * 0.1, midx, midy, w * 0.06, w * 0.045, hide)
	_cp(img, midx, midy, tipx, tipy, w * 0.045, w * 0.025, hide)
	_o(img, tipx, tipy, w * 0.03, h * 0.025, hide)
	for k in 4:   # rides de la trompe
		var t := 0.2 + float(k) * 0.2
		MP._cap(img, lerpf(midx, tipx, t) - w * 0.03, lerpf(midy, tipy, t), lerpf(midx, tipx, t) + w * 0.03, lerpf(midy, tipy, t), 0.25, 0.25, _flat(hide[1]))
	# défense recourbée
	var d0 := Vector2(hx + w * 0.07, hy + h * 0.1)
	var d1 := Vector2(hx + w * 0.18, hy + h * 0.22)
	var d2 := Vector2(hx + w * 0.26, hy + h * 0.14)
	var d3 := Vector2(hx + w * 0.28, hy + h * 0.0)
	_cp(img, d0.x, d0.y, d1.x, d1.y, w * 0.032, w * 0.026, ivory)
	_cp(img, d1.x, d1.y, d2.x, d2.y, w * 0.026, w * 0.018, ivory)
	_cp(img, d2.x, d2.y, d3.x, d3.y, w * 0.018, w * 0.006, ivory)


# ------------------------------------------------------------------ Dindon de la Farce

## Dindon de la Farce : un dindon géant, tête bleue, jabot rouge, queue en éventail à ocelles, selle.
static func _turkey(img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	var w := float(size.x)
	var h := float(size.y)
	var lean := -2.0 if col == 3 else 0.0
	var dy := float(f) * 0.9
	var plume := MP._ramp("#7a5232")
	var plume2 := MP._ramp("#a8743a")
	var gold := MP._ramp("#d8a838")
	# éventail : onze plumes, rubans bruns à ocelles dorés et bleus
	for k in 11:
		var a := -3.0 + float(k) * 0.22
		var r := w * (0.34 if k % 2 == 0 else 0.29)
		var bx := ox + w * 0.4
		var by := h * 0.5 + dy
		var ex := bx + cos(a) * r
		var ey := by + sin(a) * r * 0.95
		_cp(img, bx, by, ex, ey, w * 0.028, w * 0.05, plume2 if k % 2 == 0 else MP._dim(plume2))
		_o(img, ex, ey, w * 0.032, w * 0.032, MP._ramp("#c8902a"), 0.1)
		MP._ellipse(img, ex, ey, w * 0.018, w * 0.018, Color("#2a5a9a"))
		MP._ellipse(img, ex - 0.3, ey - 0.3, w * 0.007, w * 0.007, Color("#8ac8f0"))
	# pattes : tarse écailleux, éperon, trois doigts
	for side in 2:
		var lx := ox + w * (0.38 if side == 0 else 0.54)
		var r2 := MP._dim(gold) if side == 0 else gold
		_cp(img, lx, h * 0.68 + dy, lx - 1.0, h * 0.92, w * 0.04, w * 0.028, r2)
		for k in 3:
			var ang := -0.5 + float(k) * 0.55
			MP._cap(img, lx - 1.0, h * 0.92, lx - 1.0 + cos(ang) * w * 0.09, h * 0.955 + sin(ang) * h * 0.02, 0.9, 0.4, r2)
		_b(img, lx - 2.2, h * 0.8, 1.8, 0.7, (r2[0] as Color))
		_b(img, lx - 2.0, h * 0.85, 1.8, 0.7, (r2[0] as Color))
	# corps : plumes en écailles
	_o(img, ox + w * 0.45, h * 0.55 + dy, w * 0.22, h * 0.22, plume)
	for row in 5:
		for c in 7:
			var sx := ox + w * 0.29 + float(c) * w * 0.045 + float(row % 2) * w * 0.022
			var sy := h * 0.4 + float(row) * h * 0.075 + dy
			var qx := (sx - (ox + w * 0.45)) / (w * 0.22)
			var qy := (sy - (h * 0.55 + dy)) / (h * 0.22)
			if qx * qx + qy * qy < 0.8:
				MP._ellipse(img, sx, sy, w * 0.026, h * 0.024, plume[3] if (row + c) % 3 != 0 else plume[1])
				MP._ellipse(img, sx, sy - 0.2, w * 0.02, h * 0.018, plume[2])
	# selle noire et sangle (le dindon est déjà prêt)
	_o(img, ox + w * 0.44, h * 0.43 + dy, w * 0.14, h * 0.07, MP._ramp("#2a2a34"))
	_b(img, ox + w * 0.43, h * 0.45 + dy, 1.6, h * 0.2, Color("#3a2a20"))
	_o(img, ox + w * 0.44, h * 0.43 + dy, w * 0.035, h * 0.035, gold, 0.1)
	for k in 3:   # garniture : du persil
		_disc(img, ox + w * 0.36 + float(k) * w * 0.05, h * 0.385 + dy + float(k % 2) * 0.8, 1.5, Color("#4a8a3a"))
	# aile repliée
	_cp(img, ox + w * 0.38, h * 0.52 + dy, ox + w * 0.25, h * 0.66, w * 0.07, w * 0.04, MP._dim(plume2))
	# cou, tête bleue, caroncules
	var hx := ox + w * 0.68 + lean
	var hy := h * 0.2 + dy
	_cp(img, ox + w * 0.56, h * 0.5 + dy, hx - 2.0, hy + 4.0, w * 0.055, w * 0.04, MP._ramp("#7a98c0"))
	_o(img, ox + w * 0.62, h * 0.4 + dy, w * 0.035, h * 0.07, MP._ramp("#d8322a"))   # jabot rouge
	_o(img, hx, hy, w * 0.075, h * 0.075, MP._ramp("#7a98c0"), 0.05)
	_o(img, hx - w * 0.01, hy + h * 0.075, w * 0.03, h * 0.075, MP._ramp("#d8322a"))   # caroncule
	var mode := 0
	if col == 3:
		mode = 1
	elif col == 2:
		mode = 2
	_eye(img, hx + w * 0.02, hy - h * 0.01, w * 0.02, h * 0.022, Color("#e8a020"), mode, -1)
	# bec
	_tri(img, Vector2(hx + w * 0.05, hy - h * 0.02), Vector2(hx + w * 0.17, hy + h * 0.02), Vector2(hx + w * 0.05, hy + h * 0.045), gold[3])
	if col == 2:
		_tri(img, Vector2(hx + w * 0.05, hy + h * 0.07), Vector2(hx + w * 0.16, hy + h * 0.1), Vector2(hx + w * 0.05, hy + h * 0.04), gold[1])
		_tri(img, Vector2(hx + w * 0.05, hy + h * 0.045), Vector2(hx + w * 0.15, hy + h * 0.045), Vector2(hx + w * 0.05, hy + h * 0.07), Color("#5a1426"))
	else:
		_tri(img, Vector2(hx + w * 0.05, hy + h * 0.045), Vector2(hx + w * 0.15, hy + h * 0.03), Vector2(hx + w * 0.05, hy + h * 0.065), gold[1])


# ------------------------------------------------------------------ Grondine

## Grondine : un tronc cerclé de fer à tête de bélier cornue, sur un affût à roues.
static func _ram(img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	var w := float(size.x)
	var h := float(size.y)
	var dy := float(f) * 0.8
	var wood := MP._ramp("#8a5e38")
	var iron := MP._ramp("#6e6e80")
	var push := 0.0
	if col == 2:
		push = w * 0.07
	elif col == 3:
		push = -w * 0.02
	# affût : deux flasques de bois et deux roues cerclées de fer
	_tp(img, h * 0.66, h * 0.74, ox + w * 0.14, ox + w * 0.68, ox + w * 0.14, ox + w * 0.68, MP._ramp("#5a4226"))
	for wx in [0.24, 0.58]:
		var rcx := ox + w * float(wx)
		_o(img, rcx, h * 0.8, h * 0.16, h * 0.16, MP._ramp("#6a4a2a"))
		MP._ellipse(img, rcx, h * 0.8, h * 0.125, h * 0.125, MP._ramp("#4a3220")[1])
		for k in 8:
			var a := float(k) * TAU / 8.0
			MP._cap(img, rcx, h * 0.8, rcx + cos(a) * h * 0.13, h * 0.8 + sin(a) * h * 0.13, 0.6, 0.6, MP._ramp("#7a5632"))
		_o(img, rcx, h * 0.8, h * 0.045, h * 0.045, iron)
		_disc(img, rcx - 0.4, h * 0.8 - 0.4, 0.6, iron[4])
	# cordes de suspension
	for k in 2:
		var rx := ox + w * (0.3 + float(k) * 0.28) + push
		MP._cap(img, ox + w * (0.28 + float(k) * 0.3), h * 0.68, rx, h * 0.44 + dy, 0.4, 0.4, _flat(Color("#c8b080")))
	# tronc : écorce, cernes de coupe, trois frettes de fer
	_cp(img, ox + w * 0.15 + push, h * 0.44 + dy, ox + w * 0.64 + push, h * 0.44 + dy, h * 0.14, h * 0.14, wood)
	_o(img, ox + w * 0.145 + push, h * 0.44 + dy, h * 0.045, h * 0.12, MP._ramp("#d8b078"), 0.1)   # bout scié
	_o(img, ox + w * 0.145 + push, h * 0.44 + dy, h * 0.025, h * 0.07, MP._ramp("#b88a50"), 0.1)
	for k in 5:   # écorce
		var kx := ox + w * (0.2 + float(k) * 0.09) + push
		MP._cap(img, kx, h * 0.36 + dy, kx + 3.0, h * 0.5 + dy, 0.4, 0.4, _flat(wood[0]))
	for k in 3:
		var bx := ox + w * (0.23 + float(k) * 0.14) + push
		_tp(img, h * 0.3 + dy, h * 0.58 + dy, bx, bx + w * 0.045, bx, bx + w * 0.045, iron)
		for j in 3:
			_disc(img, bx + w * 0.022, h * 0.34 + dy + float(j) * h * 0.09, 0.7, iron[4])
	# tête de bélier en fonte : crâne, museau, cornes spiralées
	var hx := ox + w * 0.7 + push
	var hy := h * 0.44 + dy
	_o(img, hx, hy, w * 0.14, h * 0.2, iron, 0.0)
	_o(img, hx + w * 0.1, hy + h * 0.07, w * 0.08, h * 0.1, iron, 0.1)   # museau
	# cornes enroulées : l'une devant (claire), l'autre derrière (dans l'ombre)
	for side in 2:
		var near := side == 1
		var r := MP._ramp("#eee6d2") if near else MP._dim(MP._ramp("#eee6d2"))
		var oy := 0.0 if near else -h * 0.05
		var ox2 := 0.0 if near else w * 0.03
		var prev := Vector2.ZERO
		for i in 13:
			var t := float(i) / 12.0
			var ang := lerpf(-1.9, -5.3, t)
			var rr := lerpf(0.22, 0.09, t)
			var q := Vector2(hx - w * 0.06 + ox2 + cos(ang) * h * rr * 1.1, hy - h * 0.0 + oy + sin(ang) * h * rr * 1.25)
			if i > 0:
				_cp(img, prev.x, prev.y, q.x, q.y, w * lerpf(0.05, 0.01, t), w * lerpf(0.05, 0.01, t + 0.08), r)
			prev = q
	_o(img, hx - w * 0.04, hy - h * 0.2, w * 0.035, h * 0.06, MP._dim(iron), 0.0)   # oreille
	_o(img, hx + w * 0.02, hy + h * 0.1, w * 0.1, h * 0.06, MP._dim(iron), 0.1)   # mâchoire
	_o(img, hx - w * 0.01, hy - h * 0.15, w * 0.1, h * 0.06, MP._ramp("#eee6d2"), 0.1)   # toison du front
	for k in 4:
		_disc(img, hx - w * 0.06 + float(k) * w * 0.035, hy - h * 0.17 + float(k % 2) * 1.5, 1.1, Color("#d8cfb8"))
	_cp(img, hx + w * 0.03, hy - h * 0.1, hx + w * 0.15, hy + h * 0.0, w * 0.03, w * 0.04, iron)   # chanfrein
	var mode := 0
	if col == 3:
		mode = 1
	elif col == 2:
		mode = 2
	if mode == 1:
		_eye(img, hx + w * 0.05, hy - h * 0.04, w * 0.03, h * 0.04, INK, 1)
	else:
		MP._ellipse(img, hx + w * 0.05, hy - h * 0.04, w * 0.035, h * 0.045, Color("#4a1a10"))
		MP._ellipse(img, hx + w * 0.05, hy - h * 0.04, w * 0.027, h * 0.035, Color("#ff7a3a"))
		MP._ellipse(img, hx + w * 0.048, hy - h * 0.05, w * 0.012, h * 0.016, Color("#fff0a0"))
		_tri(img, Vector2(hx + w * 0.0, hy - h * 0.1), Vector2(hx + w * 0.09, hy - h * 0.03), Vector2(hx + w * 0.09, hy - h * 0.1), INK)
	# naseaux et gueule de fonte
	MP._ellipse(img, hx + w * 0.15, hy + h * 0.03, 1.0, 0.8, INK)
	var mouth_h := 0.9 if col != 2 else 3.4
	MP._cap(img, hx + w * 0.04, hy + h * 0.12, hx + w * 0.17, hy + h * 0.1 + mouth_h * 0.3, mouth_h * 0.5, mouth_h * 0.5, _flat(Color("#2a1418")))
	for k in 3:
		_tri(img, Vector2(hx + w * 0.06 + float(k) * w * 0.035, hy + h * 0.1), Vector2(hx + w * 0.085 + float(k) * w * 0.035, hy + h * 0.1), Vector2(hx + w * 0.0725 + float(k) * w * 0.035, hy + h * 0.1 + 1.6), Color("#f4ecdc"))
