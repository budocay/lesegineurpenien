extends RefCounted
## Peint par code le pays ennemi du chapitre 7 : les marais du Bouillon d'Onze Heures (style
## « marais »), le Passe-Plat et les Quatre Mille Marches (style « mordgras », basalte noir et
## braise), le col de l'Arachnée (style « toile »), la Tour de la Barbaque, cuisines et salle du
## banquet (style « festin »), et le Grand Four (style « mordgras », sol de braise).
## Accès : jamais directement, mais par `Sprites.prop(...)` et `Sprites.tile_image(...)`, qui
## s'adressent à PropPainter et TilePainter, lesquels renvoient ici pour les noms `mor_*`.
## Densité : 24 pixels par unité monde.

const PA = preload("res://src/gfx/pixel_art.gd")
const TP = preload("res://src/gfx/tile_painter.gd")
const PP = preload("res://src/gfx/prop_painter.gd")
const RP = preload("res://src/gfx/rider_painter.gd")
const T := 48

const INK := Color("#14101c")
const BASALT := Color("#2c2836")
const BASALT_L := Color("#4a4458")
const EMBER := Color("#ff7a30")
const EMBER_L := Color("#ffc860")
const IRON := Color("#4a4a58")
const WOOD := Color("#5a4630")
const WOOD_D := Color("#33281c")
const SILK := Color("#d8dce4")

const TILES: Array[String] = ["mor_planches", "mor_vase", "mor_cendre", "mor_fonte", "mor_toile", "mor_roche", "mor_carreau",
		"mor_parquet", "mor_marche", "mor_mur", "mor_mur_cuisine", "mor_braise"]

## Décors-sprites : nom -> nombre de variantes.
const PROP_VARIANTS := {
	"mor_roseau": 2, "mor_ecriteau": 3, "mor_toile": 2, "mor_fourneau": 1, "mor_marmite": 2, "mor_table": 1,
	"mor_chandelier": 1, "mor_cheminee": 1, "mor_lanterne": 1, "mor_os": 1, "mor_cocon": 2, "mor_pique": 1,
	"mor_broche": 1, "mor_garde_manger": 1,
}


static func has_tile(kind: String) -> bool:
	return TILES.has(kind)


static func has_prop(kind: String) -> bool:
	return PROP_VARIANTS.has(kind)


static func paint_tile(kind: String) -> Image:
	match kind:
		"mor_planches": return _boards()
		"mor_vase": return RP._noise(["#2c3a2a", "#222e22", "#3a4a32", "#1a241a"], 1801, 40, Color("#6a8a58"))
		"mor_cendre": return _ash()
		"mor_fonte": return _plates()
		"mor_toile": return _web_floor()
		"mor_roche": return RP._noise(["#2e2a34", "#262230", "#3a3642", "#1c1824"], 1821, 30, Color("#6a6478"))
		"mor_carreau": return _checker()
		"mor_parquet": return _parquet()
		"mor_marche": return _steps()
		"mor_mur": return _basalt_wall()
		"mor_mur_cuisine": return _kitchen_wall()
		"mor_braise": return _embers()
	var img := PA.new_image(T, T)
	img.fill(Color.MAGENTA)
	return img


static func paint_prop(kind: String, v: int) -> Image:
	match kind:
		"mor_roseau": return _reeds(v)
		"mor_ecriteau": return _sign(v)
		"mor_toile": return _web(v)
		"mor_fourneau": return _stove()
		"mor_marmite": return _pot(v)
		"mor_table": return _table()
		"mor_chandelier": return _chandelier()
		"mor_cheminee": return _chimney()
		"mor_lanterne": return _lantern()
		"mor_os": return _bones()
		"mor_cocon": return _cocoon(v)
		"mor_pique": return _spike()
		"mor_broche": return _spit()
		"mor_garde_manger": return _larder()
	var img := PA.new_image(16, 16)
	img.fill(Color.MAGENTA)
	return img


# ------------------------------------------------------------------- tuiles

## Planches posées sur la vase : bois noyé, gris-vert, joints noirs.
static func _boards() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#1a1a14"))
	for r in 4:
		var y0 := r * 12
		var tone := PA.shade(Color("#6a6248"), (PA.rnd(r, 3, 1811) - 0.5) * 0.22)
		PA.rect(img, 0, y0 + 1, T, 10, tone)
		PA.rect(img, 0, y0 + 1, T, 1, PA.shade(tone, 0.16))
		PA.rect(img, 0, y0 + 10, T, 1, PA.shade(tone, -0.2))
		var jx := 6 + (r * 17) % 36
		PA.rect(img, jx, y0 + 1, 1, 10, Color("#1a1a14"))
		PA.px(img, jx + 3, y0 + 4, Color("#2a2a20"))
		PA.px(img, jx - 4, y0 + 7, Color("#2a2a20"))
	RP._specks_in(img, 1812, 26, Color("#8aa070"))   # mousse
	RP._specks_in(img, 1813, 14, Color("#c8d8c0"))   # buée
	return img


static func _ash() -> Image:
	var img := RP._noise(["#3a3640", "#2e2a36", "#46424e", "#24202c"], 1831, 50, Color("#7a7684"))
	for i in 4:   # veines de braise
		var x := int(PA.rnd(i, 1, 1832) * 40.0) + 3
		var y := int(PA.rnd(i, 2, 1832) * 40.0) + 3
		PA.line(img, x, y, x + 5, y + 3 + i % 2, Color("#7a2a1a"))
		PA.line(img, x + 5, y + 3, x + 8, y + 2, Color("#c8501e"))
		PA.px(img, x + 6, y + 3, EMBER_L)
	return img


static func _plates() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#14121a"))
	for r in 2:
		for c in 2:
			var tone := PA.shade(Color("#34303e"), (PA.rnd(c, r, 1841) - 0.5) * 0.18)
			PA.rect(img, c * 24 + 1, r * 24 + 1, 22, 22, tone)
			PA.rect(img, c * 24 + 1, r * 24 + 1, 22, 1, PA.shade(tone, 0.2))
			PA.rect(img, c * 24 + 1, r * 24 + 22, 22, 1, PA.shade(tone, -0.25))
			for k in 4:
				PA.px(img, c * 24 + 3 + (k % 2) * 18, r * 24 + 3 + (k / 2) * 18, Color("#6a667a"))
	RP._specks_in(img, 1842, 14, Color("#5a566a"))
	return img


static func _web_floor() -> Image:
	# sol calme : roche grise à grain fin, quelques fils très peu contrastés (un quadrillage net fait un moiré
	# à distance sous la caméra inclinée) ; les fils ne touchent pas les bords : la tuile se raccorde sans couture
	var img := RP._noise(["#484c58", "#40444f", "#50545f", "#383c46"], 1851, 24, Color("#5c606c"))
	PA.line(img, 4, 10, 30, 22, Color("#585d6b"))
	PA.line(img, 30, 22, 43, 17, Color("#585d6b"))
	PA.line(img, 14, 40, 26, 30, Color("#555a68"))
	PA.line(img, 26, 30, 38, 42, Color("#555a68"))
	PA.px(img, 30, 22, Color("#70758a"))
	PA.px(img, 26, 30, Color("#70758a"))
	return img


static func _checker() -> Image:
	var img := PA.new_image(T, T)
	for r in 4:
		for c in 4:
			var light := (r + c) % 2 == 0
			var tone := PA.shade(Color("#d8cfb8") if light else Color("#6a4a3a"), (PA.rnd(c, r, 1861) - 0.5) * 0.08)
			PA.rect(img, c * 12, r * 12, 12, 12, tone)
			PA.rect(img, c * 12, r * 12, 12, 1, PA.shade(tone, 0.12))
			PA.rect(img, c * 12, r * 12 + 11, 12, 1, PA.shade(tone, -0.22))
			PA.rect(img, c * 12 + 11, r * 12, 1, 12, PA.shade(tone, -0.22))
	RP._specks_in(img, 1862, 28, Color("#e8c060"))   # gras
	RP._specks_in(img, 1863, 12, Color("#3a2a1a"))
	return img


static func _parquet() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#120c0e"))
	for r in 6:
		for c in 3:
			var off := 0 if r % 2 == 0 else 8
			var x0 := posmod(c * 16 + off, T)
			var tone := PA.shade(Color("#3a2224"), (PA.rnd(c, r, 1871) - 0.5) * 0.3)
			PA.rect(img, x0, r * 8, 15, 7, tone)
			PA.rect(img, x0, r * 8, 15, 1, PA.shade(tone, 0.22))
			PA.rect(img, x0, r * 8 + 6, 15, 1, PA.shade(tone, -0.25))
			PA.rect(img, x0 + 4, r * 8 + 3, 6, 1, PA.shade(tone, 0.1))
	RP._specks_in(img, 1872, 12, Color("#8a5a4a"))
	return img


static func _steps() -> Image:
	var img := PA.new_image(T, T)
	for r in 4:
		var y0 := r * 12
		var tone := PA.shade(Color("#5a5668"), (PA.rnd(r, 7, 1881) - 0.5) * 0.1)
		PA.rect(img, 0, y0, T, 12, tone)
		PA.rect(img, 0, y0, T, 2, Color("#8a869a"))
		PA.rect(img, 0, y0 + 9, T, 3, Color("#2a2634"))
		PA.rect(img, 14 + r * 7, y0 + 3, 12, 1, Color("#3e3a4a"))   # creux d'usure
	RP._specks_in(img, 1882, 18, Color("#a8a4b8"))
	return img


static func _basalt_wall() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#14101c"))
	for r in 3:
		for c in 3:
			var off := 0 if r % 2 == 0 else 8
			var x0 := posmod(c * 16 + off, T)
			var tone := PA.shade(Color("#3a3646"), (PA.rnd(c, r, 1891) - 0.5) * 0.22)
			PA.rect(img, x0, r * 16, 15, 15, tone)
			PA.rect(img, x0, r * 16, 15, 1, PA.shade(tone, 0.2))
			PA.rect(img, x0 + 14, r * 16, 1, 15, PA.shade(tone, -0.25))
	RP._specks_in(img, 1892, 14, Color("#7a748a"))
	return img


static func _kitchen_wall() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#8a8070"))
	for r in 4:
		for c in 4:
			var tone := PA.shade(Color("#e8e0cc"), (PA.rnd(c, r, 1901) - 0.5) * 0.07)
			PA.rect(img, c * 12 + 1, r * 12 + 1, 10, 10, tone)
			PA.rect(img, c * 12 + 1, r * 12 + 1, 10, 1, Color("#fffaf0"))
			PA.rect(img, c * 12 + 1, r * 12 + 10, 10, 1, Color("#b8ae98"))
	RP._specks_in(img, 1902, 30, Color("#b88a3a"))   # éclaboussures de sauce
	RP._specks_in(img, 1903, 12, Color("#7a2a1e"))
	return img


static func _embers() -> Image:
	var img := RP._noise(["#2a1418", "#1e0e12", "#38181a", "#140a0e"], 1911, 20, Color("#7a3a2a"))
	for i in 6:
		var x := int(PA.rnd(i, 1, 1912) * 38.0) + 4
		var y := int(PA.rnd(i, 2, 1912) * 38.0) + 4
		PA.line(img, x, y, x + 7, y + 2 + i % 3, Color("#b8321a"))
		PA.line(img, x + 7, y + 2 + i % 3, x + 11, y + 1, EMBER)
		PA.px(img, x + 3, y + 1, EMBER_L)
	return img


# ------------------------------------------------------------------- accessoires

static func _reeds(v: int) -> Image:
	var img := PA.new_image(28, 44)
	for k in 7:
		var x := 4 + k * 3 + (v * 2) % 3
		var top := 4 + int(PA.rnd(k, v, 1921) * 14.0)
		PA.line(img, x, 43, x + (k % 3) - 1, top, Color("#4a6a3a") if k % 2 == 0 else Color("#6a8a4a"))
	for k in 3:
		var x2 := 8 + k * 6
		PA.rect(img, x2, 2 + k * 3, 3, 9, Color("#5a3a22"))
		PA.rect(img, x2, 2 + k * 3, 1, 9, Color("#8a5a32"))
	PA.outline(img, Rect2i(0, 0, 28, 44), INK)
	return img


## Écriteau planté dans la vase ou contre un mur : trois variantes (flèche, avis, menu).
static func _sign(v: int) -> Image:
	var img := PA.new_image(40, 58)
	PA.rect(img, 18, 8, 4, 48, WOOD_D)
	PA.rect(img, 18, 8, 1, 48, WOOD)
	var board := Color("#d8c89a") if v != 1 else Color("#e8e0d0")
	PA.rect(img, 4, 6, 32, 22, WOOD_D)
	PA.rect(img, 5, 7, 30, 20, board)
	PA.rect(img, 5, 7, 30, 1, Color("#fffaf0"))
	for k in 4:   # lignes de texte
		PA.rect(img, 8, 10 + k * 4, 24 - (k * 5 + v * 3) % 9, 1, Color("#3a2a1e"))
	if v == 0:
		PP._poly(img, [Vector2(26, 22), Vector2(33, 22), Vector2(33, 19), Vector2(38, 23), Vector2(33, 27), Vector2(33, 25), Vector2(26, 25)], Color("#a8322a"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 40, 58), INK)
	return img


static func _web(v: int) -> Image:
	var img := PA.new_image(56, 56)
	var c := Vector2(28, 28)
	for k in 8:
		var a := float(k) * TAU / 8.0 + float(v) * 0.2
		PA.line(img, 28, 28, 28 + int(cos(a) * 26.0), 28 + int(sin(a) * 26.0), SILK)
	for ring in [8, 15, 22]:
		for k in 8:
			var a0 := float(k) * TAU / 8.0 + float(v) * 0.2
			var a1 := a0 + TAU / 8.0
			var r := float(ring)
			PA.line(img, 28 + int(cos(a0) * r), 28 + int(sin(a0) * r + 2.0 * float(ring) / 22.0), 28 + int(cos(a1) * r), 28 + int(sin(a1) * r), Color("#b4bac8"))
	PA.px(img, int(c.x), int(c.y), Color.WHITE)
	return img


static func _stove() -> Image:
	var img := PA.new_image(64, 60)
	PA.rect(img, 2, 18, 60, 38, Color("#2e2a34"))
	PA.rect(img, 2, 18, 60, 3, Color("#5a566a"))
	PA.rect(img, 10, 30, 20, 18, Color("#120c10"))
	PA.rect(img, 12, 40, 16, 6, Color("#ff7a30"))
	PA.rect(img, 15, 42, 10, 3, Color("#ffd070"))
	PA.rect(img, 36, 30, 20, 18, Color("#120c10"))
	PA.rect(img, 38, 40, 16, 6, Color("#ff7a30"))
	for k in 4:
		PA.rect(img, 6 + k * 14, 14, 10, 4, Color("#4a4658"))   # plaques
		PA.px(img, 11 + k * 14, 15, Color("#8a869a"))
	PA.ellipse(img, 20.0, 10.0, 9.0, 7.0, Color("#8a8a98"))   # grosse casserole
	PA.rect(img, 11, 8, 18, 4, Color("#6a6a78"))
	PA.rect(img, 6, 52, 8, 6, Color("#14101c"))
	PA.rect(img, 50, 52, 8, 6, Color("#14101c"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 64, 60), INK)
	return img


static func _pot(v: int) -> Image:
	var img := PA.new_image(40, 40)
	var body := Color("#8a8a98") if v == 0 else Color("#8a4a30")
	PA.ellipse(img, 20.0, 24.0, 15.0, 13.0, body.darkened(0.3))
	PA.ellipse(img, 19.0, 23.0, 13.0, 11.0, body)
	PA.ellipse(img, 15.0, 18.0, 6.0, 4.0, body.lightened(0.3))
	PA.rect(img, 4, 12, 32, 3, body.darkened(0.2))
	PA.ellipse(img, 20.0, 13.0, 14.0, 3.0, Color("#6a8a3a") if v == 0 else Color("#c8801e"))   # le contenu
	PA.rect(img, 1, 18, 4, 3, IRON)
	PA.rect(img, 35, 18, 4, 3, IRON)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 40, 40), INK)
	return img


static func _table() -> Image:
	var img := PA.new_image(88, 52)
	PA.rect(img, 4, 20, 80, 8, Color("#2a1a1c"))
	PA.rect(img, 4, 20, 80, 1, Color("#6a4a4e"))
	PA.rect(img, 0, 22, 88, 8, Color("#e8e0d0"))   # nappe
	PA.rect(img, 0, 22, 88, 1, Color.WHITE)
	for k in 7:
		PA.rect(img, 4 + k * 12, 30, 5, 10 + (k % 2) * 3, Color("#d0c8b8"))
	PA.rect(img, 8, 40, 6, 10, Color("#2a1a1c"))
	PA.rect(img, 74, 40, 6, 10, Color("#2a1a1c"))
	PA.ellipse(img, 20.0, 18.0, 8.0, 4.0, Color("#c8c8d0"))   # plat
	PA.ellipse(img, 20.0, 15.0, 6.0, 4.0, Color("#b8742a"))   # rôti
	PA.rect(img, 38, 10, 3, 10, Color("#8a2a3a"))   # carafe
	PA.rect(img, 37, 8, 5, 3, Color("#8a2a3a"))
	PA.ellipse(img, 58.0, 17.0, 7.0, 3.0, Color("#c8c8d0"))
	PA.ellipse(img, 58.0, 14.0, 5.0, 3.0, Color("#e8d070"))
	PA.rect(img, 72, 12, 2, 9, Color("#d8c8a0"))   # bougie
	PA.px(img, 72, 10, EMBER_L)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 88, 52), INK)
	return img


static func _chandelier() -> Image:
	var img := PA.new_image(56, 50)
	PA.rect(img, 27, 0, 2, 14, IRON)
	PA.rect(img, 8, 14, 40, 3, Color("#8a6a2a"))
	PA.rect(img, 8, 14, 40, 1, Color("#d8aa44"))
	for k in 5:
		var x := 9 + k * 9
		PA.rect(img, x, 8, 3, 7, Color("#e8dcc0"))
		PP._poly(img, [Vector2(x - 1, 8), Vector2(x + 4, 8), Vector2(x + 1.5, 2)], EMBER_L)
		PA.rect(img, x, 17, 2, 6, Color("#8a6a2a"))
	PA.outline(img, Rect2i(0, 0, 56, 50), INK)
	return img


static func _chimney() -> Image:
	var img := PA.new_image(44, 80)
	PA.rect(img, 6, 20, 32, 60, Color("#2e2a36"))
	PA.rect(img, 6, 20, 4, 60, Color("#4a4658"))
	PA.rect(img, 2, 10, 40, 12, Color("#3a3646"))
	PA.rect(img, 2, 10, 40, 2, Color("#6a667a"))
	PA.rect(img, 12, 2, 20, 10, Color("#1e1a26"))
	PA.rect(img, 14, 0, 16, 3, Color("#8a869a"))
	PA.rect(img, 14, 48, 16, 26, Color("#120c10"))
	PA.rect(img, 16, 66, 12, 6, EMBER)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 44, 80), INK)
	return img


static func _lantern() -> Image:
	var img := PA.new_image(28, 60)
	PA.rect(img, 12, 14, 4, 44, WOOD_D)
	PA.rect(img, 6, 6, 16, 3, IRON)
	PA.rect(img, 8, 9, 12, 14, Color("#ffd870"))
	PA.rect(img, 11, 12, 6, 8, Color("#fff6c0"))
	PA.rect(img, 8, 9, 12, 1, IRON)
	PA.rect(img, 8, 22, 12, 1, IRON)
	PP._poly(img, [Vector2(6, 6), Vector2(22, 6), Vector2(14, 0)], IRON)
	PA.outline(img, Rect2i(0, 0, 28, 60), INK)
	return img


static func _bones() -> Image:
	var img := PA.new_image(36, 24)
	PA.ellipse(img, 10.0, 14.0, 7.0, 6.0, Color("#e0d8c4"))
	PA.rect(img, 7, 14, 2, 2, INK)
	PA.rect(img, 12, 14, 2, 2, INK)
	PA.rect(img, 8, 18, 5, 2, Color("#c8bea8"))
	PA.line(img, 18, 18, 33, 12, Color("#e0d8c4"))
	PA.line(img, 18, 20, 33, 18, Color("#d0c8b4"))
	PA.line(img, 20, 14, 30, 20, Color("#e0d8c4"))
	PA.outline(img, Rect2i(0, 0, 36, 24), INK)
	return img


static func _cocoon(v: int) -> Image:
	var img := PA.new_image(30, 56)
	PA.line(img, 15, 0, 15, 8, SILK)
	PA.ellipse(img, 15.0, 32.0, 11.0, 22.0, Color("#a8aeba"))
	PA.ellipse(img, 13.0, 30.0, 9.0, 19.0, Color("#c8ccd6"))
	PA.ellipse(img, 10.0, 22.0, 3.0, 8.0, Color("#eef0f6"))
	for k in 5:
		PA.line(img, 5, 16 + k * 7, 25, 20 + k * 7 - v * 2, Color("#9aa0ae"))
	if v == 1:   # une botte dépasse
		PA.rect(img, 11, 50, 8, 5, Color("#4a3226"))
	PA.outline(img, Rect2i(0, 0, 30, 56), INK)
	return img


static func _spike() -> Image:
	var img := PA.new_image(24, 64)
	PA.rect(img, 10, 10, 4, 52, WOOD_D)
	PP._poly(img, [Vector2(8, 12), Vector2(16, 12), Vector2(12, 0)], Color("#8a8a98"))
	PA.rect(img, 5, 20, 14, 8, Color("#c8c8d4"))   # hachoir piqué en travers
	PA.rect(img, 5, 20, 14, 1, Color.WHITE)
	PA.outline(img, Rect2i(0, 0, 24, 64), INK)
	return img


static func _spit() -> Image:
	var img := PA.new_image(72, 44)
	PA.rect(img, 4, 18, 64, 3, IRON)
	PA.rect(img, 2, 8, 4, 34, IRON)
	PA.rect(img, 66, 8, 4, 34, IRON)
	PA.ellipse(img, 36.0, 19.0, 20.0, 9.0, Color("#8a4a1e"))
	PA.ellipse(img, 32.0, 16.0, 14.0, 5.0, Color("#c8782e"))
	PA.rect(img, 0, 38, 72, 4, Color("#6a1a10"))
	PA.rect(img, 6, 38, 60, 2, EMBER)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 72, 44), INK)
	return img


static func _larder() -> Image:
	var img := PA.new_image(56, 64)
	PA.rect(img, 2, 4, 52, 58, WOOD_D)
	PA.rect(img, 5, 7, 46, 52, Color("#1a1218"))
	for k in 3:
		PA.rect(img, 5, 20 + k * 14, 46, 2, WOOD)
		PA.rect(img, 9 + k * 4, 10 + k * 14, 8, 8, Color("#e0c060"))   # fromages
		PA.rect(img, 28, 11 + k * 14, 6, 7, Color("#8a3a2a"))   # bocaux
		PA.rect(img, 38, 12 + k * 14, 8, 6, Color("#b8a888"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 56, 64), INK)
	return img
