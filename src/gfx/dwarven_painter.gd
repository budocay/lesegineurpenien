extends RefCounted
## Peint par code l'architecture et les décors NAINS (style d'architecture « nain », champ
## `style: "nain"` d'une carte) : grandes salles carrées aux dalles sombres veinées, piliers
## colossaux, rails et wagonnets, cristaux, forges, et la matière même de la montagne, qui est
## un morbier (croûte, pâte jaune, raie de cendre au milieu, trous).
## Accès : jamais directement, mais par `Sprites.prop(...)` et `Sprites.tile_image(...)`,
## qui s'adressent à PropPainter et TilePainter, lesquels renvoient ici pour les noms `nain_*`.
## Densité : 24 pixels par unité monde, comme tout le reste.

const PA = preload("res://src/gfx/pixel_art.gd")
const TP = preload("res://src/gfx/tile_painter.gd")
const PP = preload("res://src/gfx/prop_painter.gd")
const T := 48

const INK := Color("#1d1a2b")
const ST_HI := Color("#9d9bb2")
const ST_L := Color("#7d7b92")
const ST := Color("#625f78")
const ST_S := Color("#4a475d")
const ST_D := Color("#34314a")
const IRON := Color("#4d4f5e")
const IRON_L := Color("#7a7d90")
const BRONZE := Color("#b88a3e")
const GOLD := Color("#e0b048")
const GOLD_D := Color("#9a722c")
const EMBER := Color("#ff9a3c")
const CH := Color("#e0cd8c")
const CH_L := Color("#f2e5ae")
const CH_S := Color("#c2a864")
const CH_D := Color("#8f7a40")
const RIND := Color("#a0763a")
const ASH := Color("#3b3836")
const SN := Color("#eaf1fb")
const SN_S := Color("#bccbe0")
const SN_D := Color("#8fa2c2")
const WOOD := Color("#7a5632")
const WOOD_L := Color("#a07848")
const WOOD_D := Color("#4e3620")

const TILES: Array[String] = ["nain_dalle", "nain_veine", "nain_voie", "nain_voie_v", "nain_pont", "nain_marbre", "nain_pate",
		"nain_abime", "nain_neige", "nain_sentier", "nain_roc", "nain_marches", "nain_mur", "nain_mur_morbier", "nain_mur_forge",
		"nain_pierre"]

## Décors-sprites : nom -> nombre de variantes.
const PROP_VARIANTS := {
	"nain_sapin": 2, "nain_cristal": 3, "nain_wagonnet": 2, "nain_meule": 2, "nain_tombe": 1, "nain_registre": 1,
	"nain_porte": 2, "nain_statue": 1, "nain_squelette": 2, "nain_panneau": 1, "nain_stele": 1, "nain_etabli": 2,
	"nain_gravats": 3, "nain_neige_tas": 2,
}


static func has_tile(kind: String) -> bool:
	return TILES.has(kind)


static func has_prop(kind: String) -> bool:
	return PROP_VARIANTS.has(kind)


static func paint_tile(kind: String) -> Image:
	match kind:
		"nain_dalle": return _slabs(["#4a475d", "#434054", "#524f66", "#3e3b50"], Color("#25233a"), 801, 24, 16, false)
		"nain_veine": return _veined()
		"nain_voie": return _rails()
		"nain_voie_v":
			var v := _rails()
			v.rotate_90(CLOCKWISE)
			return v
		"nain_pont": return _slabs(["#8c8798", "#81808f", "#9690a0", "#7c7a8a"], Color("#4e4a5c"), 802, 16, 12, true)
		"nain_marbre": return _marble()
		"nain_pate": return _cheese_floor()
		"nain_abime": return _abyss()
		"nain_neige": return _snow()
		"nain_sentier": return _trodden()
		"nain_roc": return TP._rock_strata(["#5a5870", "#4a485e", "#6a6880", "#3a384e", "#7a788e"], 811, 1)
		"nain_marches": return _steps()
		"nain_pierre": return TP._stones(["#6a6880", "#5f5d75", "#757389", "#625f78"], Color("#2c2a42"), 16, 12)
		"nain_mur": return _wall(0)
		"nain_mur_morbier": return _wall(1)
		"nain_mur_forge": return _wall(2)
	var img := PA.new_image(T, T)
	img.fill(Color.MAGENTA)
	return img


static func paint_prop(kind: String, v: int) -> Image:
	match kind:
		"nain_sapin": return _fir(v)
		"nain_cristal": return _crystal(v)
		"nain_wagonnet": return _cart(v)
		"nain_meule": return _wheel(v)
		"nain_tombe": return _tomb()
		"nain_registre": return _registry()
		"nain_porte": return _gate(v)
		"nain_statue": return _statue()
		"nain_squelette": return _bones(v)
		"nain_panneau": return _sign()
		"nain_stele": return _stele()
		"nain_etabli": return _bench(v)
		"nain_gravats": return _rubble(v)
		"nain_neige_tas": return _drift(v)
	var img := PA.new_image(16, 16)
	img.fill(Color.MAGENTA)
	return img


# --------------------------------------------------------------- utilitaires

static func _c(hex: String) -> Color:
	return Color.from_string(hex, Color.MAGENTA)


## Bloc de pierre éclairé par le haut gauche.
static func _block(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	PA.rect(img, x, y, w, h, c)
	PA.rect(img, x, y, w, 1, PA.shade(c, 0.16))
	PA.rect(img, x, y, 1, h, PA.shade(c, 0.1))
	PA.rect(img, x, y + h - 1, w, 1, PA.shade(c, -0.2))
	PA.rect(img, x + w - 1, y, 1, h, PA.shade(c, -0.14))


static func _wrap_px(img: Image, x: int, y: int, c: Color) -> void:
	img.set_pixel(posmod(x, img.get_width()), posmod(y, img.get_height()), c)


static func _specks_in(img: Image, sd: int, count: int, c: Color) -> void:
	for i in count:
		_wrap_px(img, int(PA.rnd(i, 1, sd) * img.get_width()), int(PA.rnd(i, 2, sd) * img.get_height()), c)


## Petit motif géométrique des Nains : un méandre carré (frise) de la largeur donnée.
static func _meander(img: Image, x0: int, y0: int, w: int, c: Color) -> void:
	var x := x0
	while x < x0 + w - 5:
		PA.rect(img, x, y0, 6, 1, c)
		PA.rect(img, x, y0, 1, 4, c)
		PA.rect(img, x, y0 + 3, 4, 1, c)
		PA.rect(img, x + 3, y0 + 3, 1, 3, c)
		PA.rect(img, x + 3, y0 + 5, 5, 1, c)
		x += 8


# ------------------------------------------------------------------- textures

## Grandes dalles carrées, jointoyées de noir. `warm` : pierre claire des ponts.
static func _slabs(tones: Array, joint: Color, sd: int, sw: int, sh: int, warm: bool) -> Image:
	var img := PA.new_image(T, T)
	img.fill(joint)
	for r in T / sh:
		var off := sw / 2 if r % 2 == 1 else 0
		for c in T / sw:
			var tone := _c(str(tones[int(PA.rnd(c, r, sd) * tones.size()) % tones.size()]))
			var x0 := c * sw + off
			var y0 := r * sh
			for y in range(1, sh - 1):
				for x in range(1, sw - 1):
					var col := tone
					if y == 1 or x == 1:
						col = PA.shade(tone, 0.08)
					elif y == sh - 2 or x == sw - 2:
						col = PA.shade(tone, -0.1)
					var n := PA.rnd(x0 + x, y0 + y, sd + 5)
					if n < 0.07:
						col = PA.shade(col, -0.06)
					elif n > 0.94:
						col = PA.shade(col, 0.06)
					img.set_pixel(posmod(x0 + x, T), y0 + y, col)
	if warm:
		for i in 4:
			_wrap_px(img, int(PA.rnd(i, 1, sd + 9) * T), int(PA.rnd(i, 2, sd + 9) * T), Color("#a8a2b0"))
	else:
		_specks_in(img, sd + 11, 14, Color("#5c5974"))
	return img


## Marbre sombre veiné de clair : des veines obliques qui bouclent d'une tuile à l'autre.
static func _veined() -> Image:
	var img := _slabs(["#3f3c55", "#38354d", "#46435d"], Color("#222036"), 803, 24, 24, false)
	for k in 3:
		var x := int(PA.rnd(k, 1, 804) * T)
		var y := int(PA.rnd(k, 2, 804) * T)
		var dir := 1 if k % 2 == 0 else -1
		for s in 30:
			x += dir if PA.rnd(s, k, 805) < 0.6 else 0
			y += 1 if PA.rnd(s, k, 806) < 0.8 else 0
			_wrap_px(img, x, y, Color("#8a88a8"))
			if s % 3 == 0:
				_wrap_px(img, x + 1, y, Color("#5e5c7c"))
	return img


## Voie de wagonnets : dalles, traverses de bois et deux rails de fer.
static func _rails() -> Image:
	var img := _slabs(["#4a475d", "#434054", "#524f66"], Color("#25233a"), 801, 24, 16, false)
	for x in range(2, T, 8):
		PA.rect(img, x, 9, 4, 28, WOOD)
		PA.rect(img, x, 9, 4, 1, WOOD_L)
		PA.rect(img, x, 36, 4, 1, WOOD_D)
	for y: int in [13, 31]:
		PA.rect(img, 0, y, T, 3, IRON)
		PA.rect(img, 0, y, T, 1, IRON_L)
		PA.rect(img, 0, y + 2, T, 1, ST_D)
		for x in range(3, T, 8):
			PA.px(img, x, y + 1, Color("#2a2a36"))
	return img


## Marbre pâle des grandes salles, incrusté de carrés d'or emboîtés.
static func _marble() -> Image:
	var img := _slabs(["#8a879c", "#807d94", "#928fa4"], Color("#4a475c"), 807, 24, 24, false)
	for r: int in [20, 14, 8]:
		var c := GOLD if r == 20 else (GOLD_D if r == 14 else Color("#c8c4d6"))
		var lo := 24 - r
		var hi := 24 + r
		for i in range(lo, hi + 1):
			PA.px(img, i, lo, c)
			PA.px(img, i, hi, c)
			PA.px(img, lo, i, c)
			PA.px(img, hi, i, c)
	return img


## Le sol d'un morbier : pâte jaune, trous, et la raie de cendre qui traverse tout.
static func _cheese_floor() -> Image:
	var img := PA.new_image(T, T)
	img.fill(CH)
	TP._blotches(img, 821, 9, CH_S, 5.0, 11.0)
	TP._blotches(img, 822, 7, CH_L, 4.0, 8.0)
	_specks_in(img, 823, 60, CH_S)
	# raie de cendre, irrégulière, en travers de la tuile
	for x in T:
		var yy := 22 + int(round(sin(float(x) * 0.35) * 1.5)) + (1 if PA.rnd(x, 1, 824) < 0.3 else 0)
		var th := 3 + (1 if PA.rnd(x, 2, 824) < 0.4 else 0)
		for k in th:
			_wrap_px(img, x, yy + k, ASH if k != 0 else Color("#5a5650"))
	for i in 5:
		var cx := PA.rnd(i, 1, 825) * T
		var cy := PA.rnd(i, 2, 825) * T
		TP._wrap_ellipse(img, cx, cy, 2.6 + PA.rnd(i, 3, 825) * 2.0, 1.8 + PA.rnd(i, 4, 825) * 1.4, CH_D)
		TP._wrap_ellipse(img, cx, cy + 0.6, 1.8, 1.0, Color("#6a5a30"))
	return img


## Le gouffre : presque noir, des strates à peine devinées et quelques braises au fond.
static func _abyss() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#0b0a14"))
	TP._blotches(img, 831, 10, Color("#14121f"), 6.0, 13.0)
	TP._blotches(img, 832, 5, Color("#06050c"), 5.0, 9.0)
	for i in 6:
		var y := int(PA.rnd(i, 1, 833) * T)
		for x in T:
			if PA.rnd(x, i, 834) < 0.55:
				_wrap_px(img, x, y, Color("#1c1a2c"))
	for i in 3:
		var x := int(PA.rnd(i, 1, 835) * T)
		var y := int(PA.rnd(i, 2, 835) * T)
		_wrap_px(img, x, y, Color("#d8602a"))
		_wrap_px(img, x + 1, y, Color("#7a2c18"))
	return img


static func _snow() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#e4ecf8"))
	TP._blotches(img, 841, 9, SN, 6.0, 12.0)
	TP._blotches(img, 842, 8, Color("#d2deef"), 5.0, 10.0)
	TP._blotches(img, 843, 4, SN_S, 3.0, 6.0)
	_specks_in(img, 844, 40, Color("#ffffff"))
	_specks_in(img, 845, 26, Color("#c0cfe6"))
	for i in 5:
		var x := int(PA.rnd(i, 1, 846) * T)
		var y := int(PA.rnd(i, 2, 846) * T)
		_wrap_px(img, x, y, Color("#a9b9d6"))
		_wrap_px(img, x + 1, y + 1, Color("#a9b9d6"))
	return img


static func _trodden() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#b4adab"))
	TP._blotches(img, 851, 12, Color("#a29b9b"), 4.0, 8.0)
	TP._blotches(img, 852, 9, Color("#c9c3c2"), 3.0, 7.0)
	TP._blotches(img, 853, 5, Color("#e2e8f2"), 3.0, 6.0)
	_specks_in(img, 854, 60, Color("#8a8386"))
	_specks_in(img, 855, 30, Color("#f0f4fa"))
	return img


static func _steps() -> Image:
	var img := PA.new_image(T, T)
	for b in 4:
		var y0 := b * 12
		PA.rect(img, 0, y0, T, 12, Color("#6f6d86"))
		PA.rect(img, 0, y0, T, 2, Color("#9a98b2"))
		PA.rect(img, 0, y0 + 2, T, 1, Color("#807e98"))
		PA.rect(img, 0, y0 + 9, T, 2, Color("#4a485f"))
		PA.rect(img, 0, y0 + 11, T, 1, Color("#2c2a42"))
		for x in range(0, T, 16):
			PA.rect(img, x + int(PA.rnd(x, b, 861) * 3.0), y0 + 3, 1, 6, Color("#5c5a72"))
	return img


## Mur 48 x 72 px. kind : 0 appareil de pierre à frise de méandres, 1 pâte du morbier à raie de
## cendre, 2 mur de forge noirci avec des reflets de braise.
static func _wall(kind: int) -> Image:
	var img := PA.new_image(T, 72)
	if kind == 1:
		return _morbier_wall(img)
	var base := Color("#4c495f") if kind == 0 else Color("#3a3744")
	img.fill(base)
	var joint := Color("#262439") if kind == 0 else Color("#1c1a24")
	var rows := 0
	for y in range(10, 62, 13):
		var off := 12 if rows % 2 == 1 else 0
		for x in range(-24, T + 24, 24):
			var tone := PA.shade(base, (PA.rnd(x + off, y, 871 + kind) - 0.5) * 0.18)
			_block(img, x + off, y, 23, 12, tone)
		PA.rect(img, 0, y + 12, T, 1, joint)
		rows += 1
	# corniche et frise
	PA.rect(img, 0, 0, T, 8, PA.shade(base, -0.25))
	PA.rect(img, 0, 8, T, 2, PA.shade(base, 0.14))
	PA.rect(img, 0, 10, T, 1, joint)
	_meander(img, 0, 2, T, GOLD_D if kind == 0 else Color("#6a4a2a"))
	# plinthe
	PA.rect(img, 0, 62, T, 10, PA.shade(base, -0.18))
	PA.rect(img, 0, 62, T, 1, PA.shade(base, 0.18))
	for x in range(0, T, 12):
		PA.rect(img, x, 64, 11, 7, PA.shade(base, -0.06))
		PA.rect(img, x, 64, 11, 1, PA.shade(base, 0.1))
	if kind == 2:
		for x in T:
			var a := 0.5 + 0.5 * sin(float(x) * 0.5)
			PA.px(img, x, 71, Color(1.0, 0.45 + 0.2 * a, 0.12))
			PA.px(img, x, 70, Color(0.8, 0.28, 0.1))
		for i in 18:
			_wrap_px(img, int(PA.rnd(i, 1, 872) * T), 14 + int(PA.rnd(i, 2, 872) * 46.0), Color("#12101a"))
	else:
		_specks_in(img, 873, 30, Color("#3a3850"))
	return img


## Le mur-morbier : croûte brune en haut et en bas, pâte jaune pâle, raie de cendre au milieu,
## trous piqués de coups de pioche. Le motif boucle sur 48 px.
static func _morbier_wall(img: Image) -> Image:
	img.fill(CH_S)
	TP._blotches(img, 881, 10, CH, 6.0, 12.0)
	TP._blotches(img, 882, 7, CH_D, 4.0, 8.0)
	_specks_in(img, 883, 70, CH_D)
	_specks_in(img, 884, 40, CH_L)
	# croûte du haut et plinthe de croûte
	PA.rect(img, 0, 0, T, 7, RIND)
	PA.rect(img, 0, 0, T, 2, Color("#6a4a22"))
	PA.rect(img, 0, 6, T, 1, Color("#7a5a2a"))
	PA.rect(img, 0, 64, T, 8, RIND)
	PA.rect(img, 0, 64, T, 1, Color("#c09258"))
	for x in T:
		if PA.rnd(x, 3, 885) < 0.35:
			PA.px(img, x, 7, Color("#7a5a2a"))
		if PA.rnd(x, 4, 885) < 0.4:
			PA.px(img, x, 63, CH_D)
	# raie de cendre
	for x in T:
		var yy := 32 + int(round(sin(float(x) * 0.28) * 2.0)) + (1 if PA.rnd(x, 1, 886) < 0.3 else 0)
		var th := 4 + (1 if PA.rnd(x, 2, 886) < 0.4 else 0)
		for k in th:
			PA.px(img, x, yy + k, ASH if k > 0 else Color("#5d5953"))
		if PA.rnd(x, 3, 886) < 0.2:
			PA.px(img, x, yy + th, Color("#8a8070"))
	# trous
	for i in 6:
		var cx := 4.0 + PA.rnd(i, 1, 887) * 40.0
		var cy := 12.0 + PA.rnd(i, 2, 887) * 46.0
		if absf(cy - 34.0) < 5.0:
			cy += 10.0
		var rx := 2.2 + PA.rnd(i, 3, 887) * 2.6
		var ry := 1.8 + PA.rnd(i, 4, 887) * 2.0
		TP._wrap_ellipse(img, cx, cy, rx + 0.8, ry + 0.8, CH_D)
		TP._wrap_ellipse(img, cx, cy + 0.4, rx, ry, Color("#4a3c20"))
		TP._wrap_ellipse(img, cx, cy + ry * 0.4, rx * 0.6, ry * 0.5, Color("#2a2214"))
	# coups de pioche
	for i in 8:
		var x := int(PA.rnd(i, 1, 888) * T)
		var y := 10 + int(PA.rnd(i, 2, 888) * 50.0)
		_wrap_px(img, x, y, CH_D)
		_wrap_px(img, x + 1, y + 1, CH_D)
		_wrap_px(img, x + 2, y + 2, CH_L)
	return img


# ------------------------------------------------------------------- décors

static func _fir(v: int) -> Image:
	var img := PA.new_image(44, 76)
	var dark := Color("#1f3a38")
	var mid := Color("#2c5048")
	var lite := Color("#3c6a58")
	PA.rect(img, 20, 62, 4, 12, WOOD_D)
	PA.rect(img, 20, 62, 1, 12, WOOD)
	var tiers := 5 if v == 0 else 4
	for t in tiers:
		var y := 62 - t * (50 / tiers) - 4
		var w := 20 - t * (14 / tiers)
		PP._poly(img, [Vector2(22, y - 12), Vector2(22 + w, y + 6), Vector2(22 - w, y + 6)], mid)
		PP._poly(img, [Vector2(22, y - 12), Vector2(22 - w, y + 6), Vector2(22 - w + 5, y + 6)], lite)
		PP._poly(img, [Vector2(22, y - 12), Vector2(22 + w, y + 6), Vector2(22 + w - 5, y + 6)], dark)
		# neige sur la branche
		PP._poly(img, [Vector2(22, y - 12), Vector2(22 + w * 0.5, y - 2), Vector2(22 - w * 0.5, y - 2)], SN)
		PA.rect(img, 22 - w + 2, y + 4, 2 * w - 4, 2, SN_S)
		for k in 3:
			PA.px(img, 22 - w + 3 + int(PA.rnd(k, t, 901 + v) * (2 * w - 6)), y + 6, SN)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 44, 76), INK)
	return img


## Grappe de cristaux : 0 bleu glacier, 1 violet, 2 vert cuivre.
static func _crystal(v: int) -> Image:
	var img := PA.new_image(30, 36)
	var cols: Array = [["#2c5a9a", "#5aa0e0", "#b8e0ff"], ["#5a2c8a", "#9a5ad0", "#e0c0ff"], ["#1c6a58", "#3cc09a", "#b8ffe0"]]
	var cc: Array = cols[v % 3]
	var dk := _c(cc[0])
	var md := _c(cc[1])
	var lt := _c(cc[2])
	PA.ellipse(img, 15.0, 32.0, 12.0, 4.0, ST_S)
	PA.ellipse(img, 14.0, 31.0, 10.0, 3.0, ST)
	var spikes: Array = [[15, 30, 17, 4, 5], [8, 31, 8, 14, 4], [22, 31, 23, 12, 4], [12, 32, 4, 20, 3], [19, 32, 26, 18, 3]]
	for sp: Array in spikes:
		var bx: int = sp[0]
		var by: int = sp[1]
		var tx: int = sp[2]
		var ty: int = sp[3]
		var hw: int = sp[4]
		PP._poly(img, [Vector2(bx - hw, by), Vector2(tx, ty), Vector2(bx + hw, by)], md)
		PP._poly(img, [Vector2(bx - hw, by), Vector2(tx, ty), Vector2(bx - 1, by)], lt)
		PP._poly(img, [Vector2(bx + 1, by), Vector2(tx, ty), Vector2(bx + hw, by)], dk)
		PA.px(img, tx, ty, Color.WHITE)
	PA.outline(img, Rect2i(0, 0, 30, 36), INK)
	return img


static func _cart(v: int) -> Image:
	var img := PA.new_image(48, 36)
	PP._poly(img, [Vector2(4, 8), Vector2(44, 8), Vector2(40, 28), Vector2(8, 28)], IRON)
	PP._poly(img, [Vector2(4, 8), Vector2(10, 8), Vector2(12, 28), Vector2(8, 28)], IRON_L)
	PA.rect(img, 4, 7, 40, 2, IRON_L)
	for x in range(10, 40, 7):
		PA.rect(img, x, 11, 1, 15, ST_D)
	PA.rect(img, 6, 17, 36, 1, ST_D)
	if v == 1:
		# plein de croûtes de fromage et de minerai
		for i in 9:
			var x := 7 + int(PA.rnd(i, 1, 911) * 30.0)
			var y := 2 + int(PA.rnd(i, 2, 911) * 6.0)
			var c: Color = CH if i % 3 != 0 else Color("#6a7aa0")
			PA.ellipse(img, float(x) + 2.0, float(y) + 2.0, 3.5, 2.8, c)
			PA.px(img, x + 1, y + 1, CH_L if i % 3 != 0 else Color("#a8b8e0"))
		PA.ellipse(img, 24.0, 7.0, 14.0, 2.0, ASH)
	PA.ellipse(img, 13.0, 30.0, 5.0, 5.0, ST_D)
	PA.ellipse(img, 13.0, 30.0, 3.5, 3.5, IRON_L)
	PA.ellipse(img, 13.0, 30.0, 1.2, 1.2, ST_D)
	PA.ellipse(img, 35.0, 30.0, 5.0, 5.0, ST_D)
	PA.ellipse(img, 35.0, 30.0, 3.5, 3.5, IRON_L)
	PA.ellipse(img, 35.0, 30.0, 1.2, 1.2, ST_D)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 48, 36), INK)
	return img


## Meule de morbier : la roue, vue de trois quarts, sa raie de cendre bien visible.
static func _wheel(v: int) -> Image:
	var h := 30 if v == 0 else 44
	var img := PA.new_image(52, h)
	var layers := 1 if v == 0 else 2
	for l in layers:
		var y0 := h - 8 - l * 14
		PA.ellipse(img, 26.0, float(y0) + 8.0, 24.0, 8.5, RIND)
		PA.rect(img, 2, y0 - 6, 48, 14, RIND)
		PA.rect(img, 2, y0 - 6, 48, 1, Color("#b88a50"))
		PA.rect(img, 4, y0 - 1, 44, 4, ASH)
		PA.ellipse(img, 26.0, float(y0) - 6.0, 24.0, 8.5, CH)
		PA.ellipse(img, 26.0, float(y0) - 6.0, 21.0, 6.5, CH_L)
		PA.ellipse(img, 26.0, float(y0) - 6.0, 24.0, 8.5, RIND)
		PA.ellipse(img, 26.0, float(y0) - 6.0, 22.0, 7.2, CH)
		# raie de cendre sur la face du dessus
		PA.line(img, 6, y0 - 6, 46, y0 - 6, ASH)
		PA.line(img, 6, y0 - 5, 46, y0 - 5, Color("#5a5650"))
		for i in 4:
			PA.ellipse(img, 10.0 + float(i) * 9.0 + float(l) * 3.0, float(y0) - 8.0 + float(i % 2) * 4.0, 1.8, 1.2, CH_D)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 52, h), INK)
	return img


static func _tomb() -> Image:
	var img := PA.new_image(70, 56)
	_block(img, 4, 30, 62, 22, ST)
	_block(img, 2, 22, 66, 10, ST_L)
	PA.rect(img, 6, 24, 58, 1, ST_HI)
	# gisant : un nain couché, la barbe sur la poitrine
	PA.ellipse(img, 35.0, 18.0, 26.0, 7.0, ST_L)
	PA.ellipse(img, 35.0, 16.0, 24.0, 5.5, ST_HI)
	PA.ellipse(img, 14.0, 14.0, 5.0, 4.5, Color("#c8b6a0"))
	PP._poly(img, [Vector2(10, 17), Vector2(20, 17), Vector2(24, 26), Vector2(14, 28)], Color("#8a8aa0"))
	PA.rect(img, 6, 8, 16, 4, GOLD)
	PA.rect(img, 6, 6, 3, 3, GOLD)
	PA.rect(img, 12, 5, 3, 4, GOLD)
	PA.rect(img, 19, 6, 3, 3, GOLD)
	PA.line(img, 26, 15, 56, 15, ST_S)
	PA.line(img, 50, 10, 58, 18, IRON_L)
	# frise de méandres
	_meander(img, 8, 36, 54, GOLD_D)
	PA.rect(img, 8, 46, 54, 1, ST_D)
	# bougies
	for x: int in [0, 66]:
		PA.rect(img, x, 40, 4, 12, Color("#efe6d2"))
		PA.rect(img, x + 1, 36, 2, 4, EMBER)
		PA.px(img, x + 1, 34, Color("#ffe8a0"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 70, 56), INK)
	return img


static func _registry() -> Image:
	var img := PA.new_image(40, 60)
	_block(img, 12, 34, 16, 24, ST)
	_block(img, 6, 54, 28, 6, ST_S)
	PP._poly(img, [Vector2(2, 28), Vector2(38, 28), Vector2(34, 12), Vector2(6, 12)], Color("#d8c89a"))
	PP._poly(img, [Vector2(2, 28), Vector2(20, 28), Vector2(20, 12), Vector2(6, 12)], Color("#e8dcb4"))
	PA.line(img, 20, 12, 20, 28, WOOD_D)
	PA.rect(img, 1, 28, 38, 3, WOOD)
	PA.rect(img, 1, 28, 38, 1, WOOD_L)
	for k in 5:
		PA.rect(img, 8, 15 + k * 2, 9 - (k % 2) * 2, 1, Color("#6a5a3c"))
		PA.rect(img, 23, 15 + k * 2, 10 - (k % 3) * 2, 1, Color("#6a5a3c"))
	PA.rect(img, 3, 8, 3, 8, Color("#8a3030"))     # signet
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 40, 60), INK)
	return img


## La grande porte des Nains. 0 fermée (battants lisses, un cercle d'argent et des runes
## qui luisent), 1 ouverte sur le noir, le feu d'une forge au loin.
static func _gate(v: int) -> Image:
	var w := 176
	var h := 138
	var img := PA.new_image(w, h)
	for y in range(0, h, 12):
		var off := 12 if (y / 12) % 2 == 1 else 0
		for x in range(-24, w + 24, 24):
			_block(img, x + off, y, 23, 11, PA.shade(ST, (PA.rnd(x, y, 921) - 0.5) * 0.16))
	# pilastres carrés de chaque côté, motif de losanges
	for side in 2:
		var x0 := 0 if side == 0 else w - 26
		_block(img, x0, 0, 26, h, ST_S)
		for y in range(8, h - 10, 14):
			PP._poly(img, [Vector2(x0 + 13, y), Vector2(x0 + 21, y + 6), Vector2(x0 + 13, y + 12), Vector2(x0 + 5, y + 6)], ST_L)
			PP._poly(img, [Vector2(x0 + 13, y + 3), Vector2(x0 + 17, y + 6), Vector2(x0 + 13, y + 9), Vector2(x0 + 9, y + 6)], GOLD_D)
	# linteau à frise et arc d'inscription
	_block(img, 26, 0, w - 52, 26, ST_L)
	_meander(img, 32, 4, w - 64, GOLD_D)
	_meander(img, 32, 17, w - 64, GOLD_D)
	PA.rect(img, 26, 26, w - 52, 2, ST_D)
	# baie
	var dx := 44
	var dw := w - 88
	PA.rect(img, dx - 3, 28, dw + 6, h - 28, ST_D)
	if v == 0:
		for leaf in 2:
			var lx := dx + leaf * (dw / 2)
			PA.rect(img, lx, 30, dw / 2 - 1, h - 30, Color("#3c3a4e"))
			for y in range(32, h - 4, 10):
				PA.rect(img, lx + 1, y, dw / 2 - 3, 9, Color("#46445a"))
				PA.rect(img, lx + 1, y, dw / 2 - 3, 1, Color("#5a5870"))
			PA.rect(img, lx, 30, 1, h - 30, ST_D)
		PA.rect(img, dx + dw / 2 - 1, 30, 2, h - 30, Color("#1a182a"))
		# cercle d'argent et runes
		var cx := float(dx + dw / 2)
		var cy := 66.0
		for a in 120:
			var ang := float(a) / 120.0 * TAU
			PA.px(img, int(cx + cos(ang) * 17.0), int(cy + sin(ang) * 17.0), Color("#d8e4ff"))
			if a % 2 == 0:
				PA.px(img, int(cx + cos(ang) * 16.0), int(cy + sin(ang) * 16.0), Color("#8aa8e0"))
		for k in 6:
			var ang2 := float(k) / 6.0 * TAU + 0.4
			PA.rect(img, int(cx + cos(ang2) * 10.0), int(cy + sin(ang2) * 10.0), 2, 4, Color("#b8d0ff"))
		PA.line(img, int(cx) - 8, int(cy), int(cx) + 8, int(cy), Color("#d8e4ff"))
		PA.rect(img, int(cx) - 1, int(cy) - 8, 2, 16, Color("#d8e4ff"))
	else:
		PA.rect(img, dx, 30, dw, h - 30, Color("#07060d"))
		for y in range(30, h):
			var t := float(y - 30) / float(h - 30)
			var c := Color(0.55 * t, 0.22 * t, 0.06 * t)
			PA.rect(img, dx + dw / 2 - 20, y, 40, 1, c)
		PA.rect(img, dx, 30, 6, h - 30, ST_D)
		PA.rect(img, dx + dw - 6, 30, 6, h - 30, ST_D)
	# seuil
	_block(img, dx - 6, h - 6, dw + 12, 6, ST_L)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, w, h), INK)
	return img


static func _statue() -> Image:
	var img := PA.new_image(36, 90)
	_block(img, 4, 74, 28, 16, ST)
	_block(img, 2, 68, 32, 7, ST_L)
	# corps trapu, cotte de mailles, hache
	PP._poly(img, [Vector2(9, 70), Vector2(27, 70), Vector2(25, 38), Vector2(11, 38)], ST_L)
	PP._poly(img, [Vector2(20, 70), Vector2(27, 70), Vector2(25, 38), Vector2(20, 38)], ST)
	PA.rect(img, 9, 52, 18, 3, GOLD_D)
	# barbe tressée
	PP._poly(img, [Vector2(12, 34), Vector2(24, 34), Vector2(22, 56), Vector2(18, 62), Vector2(14, 56)], ST_HI)
	for k in 5:
		PA.rect(img, 14 + k * 2, 38, 1, 18, ST_S)
	PA.ellipse(img, 18.0, 28.0, 6.5, 6.5, Color("#a8a6bc"))
	# heaume à cornes
	PA.rect(img, 11, 18, 14, 8, IRON_L)
	PA.rect(img, 11, 18, 14, 2, ST_HI)
	PP._poly(img, [Vector2(11, 20), Vector2(5, 12), Vector2(9, 24)], ST_HI)
	PP._poly(img, [Vector2(25, 20), Vector2(31, 12), Vector2(27, 24)], ST_HI)
	PA.rect(img, 14, 28, 2, 2, ST_D)
	PA.rect(img, 20, 28, 2, 2, ST_D)
	# hache dressée
	PA.rect(img, 31, 20, 2, 50, WOOD)
	PP._poly(img, [Vector2(33, 22), Vector2(36, 18), Vector2(36, 34), Vector2(33, 30)], ST_HI)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 36, 90), INK)
	return img


static func _bones(v: int) -> Image:
	var img := PA.new_image(34, 18)
	var bone := Color("#d8d0b8")
	var bone_d := Color("#a8a088")
	PA.ellipse(img, 17.0, 14.0, 15.0, 3.0, Color("#2a2838"))
	for k in 5:
		PA.line(img, 8 + k * 3, 12, 12 + k * 3, 8 - (k % 2), bone)
	PA.line(img, 4, 14, 26, 14, bone_d)
	PA.ellipse(img, 27.0, 11.0, 4.0, 4.0, bone)
	PA.px(img, 26, 10, ST_D)
	PA.px(img, 29, 10, ST_D)
	PA.rect(img, 25, 6, 6, 2, IRON_L if v == 0 else Color("#8a5a3a"))   # heaume cabossé ou cabas de cuir
	PA.line(img, 3, 12, 14, 16, bone)
	if v == 1:
		PA.line(img, 14, 3, 30, 14, WOOD_L)
		PA.px(img, 14, 3, Color("#c8c8d8"))
	PA.outline(img, Rect2i(0, 0, 34, 18), INK)
	return img


static func _sign() -> Image:
	var img := PA.new_image(26, 44)
	PA.rect(img, 11, 18, 4, 24, WOOD)
	PA.rect(img, 11, 18, 1, 24, WOOD_L)
	_block(img, 2, 2, 22, 20, ST_L)
	PA.rect(img, 4, 4, 18, 1, ST_HI)
	for k in 3:
		PA.rect(img, 6, 8 + k * 4, 14 - (k % 2) * 4, 1, GOLD_D)
		PA.px(img, 6 + 3 * k, 7 + k * 4, GOLD)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 26, 44), INK)
	return img


static func _stele() -> Image:
	var img := PA.new_image(26, 62)
	_block(img, 2, 6, 22, 56, ST)
	PP._poly(img, [Vector2(2, 6), Vector2(13, 0), Vector2(24, 6)], ST_L)
	for k in 6:
		var y := 12 + k * 8
		PA.rect(img, 6, y, 14, 1, GOLD_D)
		PA.rect(img, 6 + (k % 3) * 3, y + 2, 2, 4, GOLD_D)
		PA.rect(img, 14 - (k % 2) * 3, y + 3, 4, 1, GOLD)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 26, 62), INK)
	return img


static func _bench(v: int) -> Image:
	var img := PA.new_image(48, 40)
	if v == 0:
		# établi de forgeron : plateau épais, pinces, marteaux
		PA.rect(img, 4, 14, 40, 6, WOOD_L)
		PA.rect(img, 4, 14, 40, 1, Color("#c8a068"))
		PA.rect(img, 4, 20, 40, 2, WOOD_D)
		for x: int in [6, 38]:
			PA.rect(img, x, 22, 4, 16, WOOD)
			PA.rect(img, x, 22, 1, 16, WOOD_L)
		PA.rect(img, 8, 32, 32, 2, WOOD_D)
		PA.line(img, 10, 13, 18, 6, WOOD_L)
		PA.rect(img, 16, 3, 7, 4, IRON_L)
		PA.line(img, 28, 13, 34, 8, IRON_L)
		PA.line(img, 30, 13, 37, 9, IRON)
		PA.rect(img, 38, 10, 4, 4, Color("#d8602a"))
	else:
		# meule à aiguiser : disque de grès sur son bâti, étincelles
		PA.rect(img, 6, 30, 36, 5, WOOD_D)
		for x: int in [10, 34]:
			PA.rect(img, x, 14, 4, 18, WOOD)
		PA.ellipse(img, 24.0, 20.0, 12.0, 12.0, Color("#a89a86"))
		PA.ellipse(img, 24.0, 20.0, 9.0, 9.0, Color("#b8aa96"))
		PA.ellipse(img, 24.0, 20.0, 2.0, 2.0, ST_D)
		for k in 5:
			PA.px(img, 38 + k, 10 - k * 2 + (k % 2), Color("#ffd870"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 48, 40), INK)
	return img


static func _rubble(v: int) -> Image:
	var img := PA.new_image(26, 16)
	for i in 8 + v * 2:
		var x := 3.0 + PA.rnd(i, 1, 931 + v) * 19.0
		var y := 7.0 + PA.rnd(i, 2, 931 + v) * 5.0
		var r := 1.6 + PA.rnd(i, 3, 931 + v) * 2.6
		var c := ST_L if i % 3 == 0 else (ST if i % 3 == 1 else ST_S)
		if v == 2 and i % 4 == 0:
			c = CH_S
		PA.ellipse(img, x, y, r, r * 0.75, c)
		PA.px(img, int(x) - 1, int(y) - 1, PA.shade(c, 0.25))
	PA.outline(img, Rect2i(0, 0, 26, 16), INK)
	return img


static func _drift(v: int) -> Image:
	var img := PA.new_image(40, 22)
	PA.ellipse(img, 20.0, 15.0, 18.0, 6.0, SN_D)
	PA.ellipse(img, 20.0, 13.0, 17.0, 6.5, SN_S)
	PA.ellipse(img, 18.0, 11.0, 13.0, 5.0, SN)
	PA.ellipse(img, 14.0, 9.0, 6.0, 2.5, Color.WHITE)
	if v == 1:
		PA.ellipse(img, 26.0, 8.0, 5.0, 4.0, ST_S)
		PA.ellipse(img, 25.0, 6.0, 4.0, 2.0, ST_L)
		PA.ellipse(img, 25.0, 4.0, 4.0, 1.4, SN)
	PA.outline(img, Rect2i(0, 0, 40, 22), Color("#5a6a8a"))
	return img
