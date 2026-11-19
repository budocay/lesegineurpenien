extends RefCounted
## Peint par code l'architecture et les décors du chapitre 5 : le peuple des cavaliers
## (style « cavalier » : plaines dorées, château de bois doré), la forêt ancienne des arbres
## qui marchent (style « fongorn »), l'Isengarde-Manger (style « isengarde » : fonte, suie,
## fours et farine) et les chutes du Gratin (style « chutes »).
## Accès : jamais directement, mais par `Sprites.prop(...)` et `Sprites.tile_image(...)`, qui
## s'adressent à PropPainter et TilePainter, lesquels renvoient ici pour les noms
## `cav_*`, `ent_*`, `isen_*` et `chu_*`. Densité : 24 pixels par unité monde.

const PA = preload("res://src/gfx/pixel_art.gd")
const TP = preload("res://src/gfx/tile_painter.gd")
const PP = preload("res://src/gfx/prop_painter.gd")
const T := 48

const INK := Color("#1d1a2b")
const WOOD := Color("#a87a34")
const WOOD_L := Color("#d4a44c")
const WOOD_D := Color("#6a4a22")
const GOLD := Color("#e8c050")
const GOLD_D := Color("#a07a28")
const SOOT := Color("#26232e")
const IRON := Color("#4a4854")
const IRON_L := Color("#7c7a88")
const EMBER := Color("#ff8a30")

const TILES: Array[String] = ["cav_herbe", "cav_chemin", "cav_planches", "cav_mur", "cav_botte_sol",
		"ent_mousse", "ent_sentier", "ent_racines",
		"isen_dalle", "isen_fonte", "isen_farine", "isen_fosse", "isen_mur",
		"chu_roche", "chu_gravier", "chu_mur"]

## Décors-sprites : nom -> nombre de variantes.
const PROP_VARIANTS := {
	"cav_arbre": 2, "cav_botte": 1, "cav_etendard": 2, "cav_brebis": 2, "cav_enclos": 1, "cav_trone": 1,
	"cav_lit": 1, "cav_grange": 1,
	"ent_arbre": 3, "ent_panonceau": 1, "ent_souche": 1,
	"isen_four": 2, "isen_marmite": 1, "isen_cage": 1, "isen_sac": 2, "isen_cheminee": 1, "isen_pancarte": 1,
	"isen_tour": 1,
	"chu_pierre": 2, "chu_ecume": 1,
}


static func has_tile(kind: String) -> bool:
	return TILES.has(kind)


static func has_prop(kind: String) -> bool:
	return PROP_VARIANTS.has(kind)


static func paint_tile(kind: String) -> Image:
	match kind:
		"cav_herbe": return _noise(["#9a9c46", "#a8ae54", "#868c3c", "#b6b862"], 1101, 52, Color("#d4d880"))
		"cav_chemin": return _noise(["#b89a62", "#a88a54", "#c4a870", "#9a7c48"], 1102, 40, Color("#ddc690"))
		"cav_planches": return _planks()
		"cav_mur": return _wood_wall()
		"cav_botte_sol": return _noise(["#c8aa44", "#d4b858", "#b89a38"], 1103, 70, Color("#f0dc88"))
		"ent_mousse": return _noise(["#2e4a2a", "#385a30", "#264022", "#43683a"], 1111, 60, Color("#78a860"))
		"ent_sentier": return _noise(["#5a4a2c", "#6a5834", "#4c3e26", "#745f3a"], 1112, 50, Color("#8a7448"))
		"ent_racines": return _roots()
		"isen_dalle": return TP._stones(["#3a3844", "#33313d", "#42404e", "#2e2c38"], Color("#17151e"), 16, 12)
		"isen_fonte": return _cast_iron()
		"isen_farine": return _noise(["#cfc9bc", "#c0baae", "#dcd6ca", "#b0aa9e"], 1121, 70, Color("#f6f2e8"))
		"isen_fosse": return _pit()
		"isen_mur": return _tower_wall()
		"chu_roche": return TP._rock_strata(["#4a5a62", "#3c4a52", "#586a72", "#2e3c44", "#6a7c84"], 1131, 1)
		"chu_gravier": return _noise(["#7a8a8a", "#6a7a7c", "#8a9a98", "#5c6c6e"], 1132, 70, Color("#b8c8c4"))
		"chu_mur": return _wet_wall()
	var img := PA.new_image(T, T)
	img.fill(Color.MAGENTA)
	return img


static func paint_prop(kind: String, v: int) -> Image:
	match kind:
		"cav_arbre": return _birch(v)
		"cav_botte": return _bale()
		"cav_etendard": return _standard(v)
		"cav_brebis": return _sheep(v)
		"cav_enclos": return _fence()
		"cav_trone": return _throne()
		"cav_lit": return _bed()
		"cav_grange": return _barn()
		"ent_arbre": return _ent(v)
		"ent_panonceau": return _board()
		"ent_souche": return _stump()
		"isen_four": return _oven(v)
		"isen_marmite": return _pot()
		"isen_cage": return _cage()
		"isen_sac": return _sack(v)
		"isen_cheminee": return _stack()
		"isen_pancarte": return _plate()
		"isen_tour": return _tower()
		"chu_pierre": return _wet_rock(v)
		"chu_ecume": return _foam()
	var img := PA.new_image(16, 16)
	img.fill(Color.MAGENTA)
	return img


# --------------------------------------------------------------- utilitaires

static func _c(hex: String) -> Color:
	return Color.from_string(hex, Color.MAGENTA)


static func _wrap_px(img: Image, x: int, y: int, c: Color) -> void:
	img.set_pixel(posmod(x, img.get_width()), posmod(y, img.get_height()), c)


static func _specks_in(img: Image, sd: int, count: int, c: Color) -> void:
	for i in count:
		_wrap_px(img, int(PA.rnd(i, 1, sd) * img.get_width()), int(PA.rnd(i, 2, sd) * img.get_height()), c)


## Volume arrondi : ombre, ton moyen décalé vers la lumière, éclat.
static func _blob(img: Image, cx: float, cy: float, rx: float, ry: float, dark: Color, mid: Color, light: Color) -> void:
	PA.ellipse(img, cx, cy, rx, ry, dark)
	PA.ellipse(img, cx - rx * 0.12, cy - ry * 0.12, rx * 0.86, ry * 0.86, mid)
	PA.ellipse(img, cx - rx * 0.3, cy - ry * 0.34, rx * 0.4, ry * 0.36, light)


## Texture de sol : fond nuancé de taches, brins clairs et poussière, qui boucle.
static func _noise(tones: Array, sd: int, specks: int, hi: Color) -> Image:
	var img := PA.new_image(T, T)
	img.fill(_c(str(tones[0])))
	for k in range(1, tones.size()):
		TP._blotches(img, sd + k, 9, _c(str(tones[k])), 4.0, 10.0)
	_specks_in(img, sd + 7, specks, hi)
	_specks_in(img, sd + 8, specks / 2, PA.shade(_c(str(tones[0])), -0.2))
	return img


static func _planks() -> Image:
	var img := PA.new_image(T, T)
	img.fill(WOOD_D)
	for r in 4:
		var y0 := r * 12
		var tone := PA.shade(WOOD, (PA.rnd(r, 1, 1141) - 0.5) * 0.2)
		PA.rect(img, 0, y0 + 1, T, 10, tone)
		PA.rect(img, 0, y0 + 1, T, 1, PA.shade(tone, 0.16))
		PA.rect(img, 0, y0 + 10, T, 1, PA.shade(tone, -0.18))
		var jx := int(PA.rnd(r, 2, 1141) * 40.0) + 4
		PA.rect(img, jx, y0 + 1, 1, 10, WOOD_D)
		for g in 5:
			_wrap_px(img, int(PA.rnd(g, r, 1142) * T), y0 + 3 + int(PA.rnd(g, r, 1143) * 5.0), PA.shade(tone, -0.12))
	return img


## Mur 48 x 72 : rondins verticaux dorés, bandeau de cuivre, plinthe de pierre.
static func _wood_wall() -> Image:
	var img := PA.new_image(T, 72)
	img.fill(WOOD_D)
	for x in range(0, T, 8):
		var tone := PA.shade(WOOD, (PA.rnd(x, 1, 1151) - 0.5) * 0.22)
		PA.rect(img, x + 1, 8, 6, 54, tone)
		PA.rect(img, x + 1, 8, 1, 54, PA.shade(tone, 0.18))
		PA.rect(img, x + 6, 8, 1, 54, PA.shade(tone, -0.2))
		for k in 3:
			PA.px(img, x + 3 + (k % 2), 14 + int(PA.rnd(x, k, 1152) * 44.0), PA.shade(tone, -0.15))
	PA.rect(img, 0, 0, T, 8, PA.shade(WOOD_D, -0.2))
	PA.rect(img, 0, 8, T, 2, GOLD)
	PA.rect(img, 0, 10, T, 1, GOLD_D)
	for x in range(2, T, 12):   # frise : têtes de chevaux stylisées
		PA.rect(img, x, 2, 5, 4, GOLD_D)
		PA.rect(img, x + 4, 1, 2, 2, GOLD_D)
	PA.rect(img, 0, 62, T, 10, Color("#7a7468"))
	PA.rect(img, 0, 62, T, 1, Color("#a8a294"))
	for x in range(0, T, 12):
		PA.rect(img, x, 64, 11, 7, Color("#6a6458"))
		PA.rect(img, x, 64, 11, 1, Color("#8a8476"))
	return img


static func _roots() -> Image:
	var img := _noise(["#2e4a2a", "#264022", "#385a30"], 1161, 30, Color("#78a860"))
	for k in 4:
		var x := PA.rnd(k, 1, 1162) * T
		var y := PA.rnd(k, 2, 1162) * T
		for s in 26:
			x += 1.0 if PA.rnd(s, k, 1163) < 0.7 else 0.0
			y += (PA.rnd(s, k, 1164) - 0.5) * 1.6
			_wrap_px(img, int(x), int(y), Color("#4c3a22"))
			_wrap_px(img, int(x), int(y) + 1, Color("#2c2214"))
			_wrap_px(img, int(x), int(y) - 1, Color("#6a5232"))
	return img


static func _cast_iron() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#1b1a22"))
	for r in 2:
		for c in 2:
			var x0 := c * 24 + 1
			var y0 := r * 24 + 1
			var tone := PA.shade(Color("#3c3a46"), (PA.rnd(c, r, 1171) - 0.5) * 0.14)
			PA.rect(img, x0, y0, 22, 22, tone)
			PA.rect(img, x0, y0, 22, 1, PA.shade(tone, 0.18))
			PA.rect(img, x0, y0, 1, 22, PA.shade(tone, 0.1))
			PA.rect(img, x0, y0 + 21, 22, 1, PA.shade(tone, -0.2))
			for p: Vector2i in [Vector2i(2, 2), Vector2i(19, 2), Vector2i(2, 19), Vector2i(19, 19)]:
				PA.px(img, x0 + p.x, y0 + p.y, IRON_L)
				PA.px(img, x0 + p.x + 1, y0 + p.y + 1, SOOT)
	_specks_in(img, 1172, 20, Color("#5a5864"))
	return img


## Fosse de l'Isengarde : fond noir, braises et lueur rouge qui monte du bas.
static func _pit() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#120d10"))
	TP._blotches(img, 1181, 10, Color("#241418"), 6.0, 12.0)
	TP._blotches(img, 1182, 6, Color("#5a1c10"), 4.0, 8.0)
	for i in 14:
		_wrap_px(img, int(PA.rnd(i, 1, 1183) * T), int(PA.rnd(i, 2, 1183) * T), EMBER if i % 3 == 0 else Color("#b83c18"))
	return img


## Mur noir de la tour : appareil de basalte, bandeaux de cuivre, soupiraux de four.
static func _tower_wall() -> Image:
	var img := PA.new_image(T, 72)
	img.fill(Color("#2a2832"))
	var rows := 0
	for y in range(10, 62, 13):
		var off := 12 if rows % 2 == 1 else 0
		for x in range(-24, T + 24, 24):
			var tone := PA.shade(Color("#34323e"), (PA.rnd(x + off, y, 1191) - 0.5) * 0.2)
			PA.rect(img, x + off, y, 23, 12, tone)
			PA.rect(img, x + off, y, 23, 1, PA.shade(tone, 0.14))
			PA.rect(img, x + off, y + 11, 23, 1, PA.shade(tone, -0.2))
		rows += 1
	PA.rect(img, 0, 0, T, 9, Color("#1c1a24"))
	PA.rect(img, 0, 9, T, 2, Color("#8a5a28"))
	for x in range(3, T, 12):
		PA.rect(img, x, 3, 6, 3, Color("#6a4420"))
	PA.rect(img, 0, 62, T, 10, Color("#1e1c26"))
	PA.rect(img, 0, 62, T, 1, Color("#4a4858"))
	for i in 3:   # lueur de four entre les pierres
		var x := 6 + i * 16
		PA.rect(img, x, 40, 6, 3, Color("#a83c18"))
		PA.rect(img, x + 1, 41, 4, 1, EMBER)
	return img


static func _wet_wall() -> Image:
	var img := _noise(["#3c4a52", "#2e3c44", "#4a5a62"], 1201, 20, Color("#7a9098"))
	var wall := PA.new_image(T, 72)
	for y in 72:
		for x in T:
			wall.set_pixel(x, y, img.get_pixel(x, y % T))
	PA.rect(wall, 0, 0, T, 6, Color("#1c262c"))
	for x in range(2, T, 9):
		PA.rect(wall, x, 6, 1, 40 + int(PA.rnd(x, 1, 1202) * 24.0), Color("#8ab0b8"))
	PA.rect(wall, 0, 66, T, 6, Color("#222e34"))
	return wall


# ------------------------------------------------------------------- décors

static func _birch(v: int) -> Image:
	var img := PA.new_image(44, 76)
	PA.rect(img, 20, 40, 4, 34, Color("#d8d0b8"))
	PA.rect(img, 20, 40, 1, 34, Color("#f0eadc"))
	for k in 6:
		PA.rect(img, 20 + (k % 2), 44 + k * 5, 2, 1, Color("#3a3226"))
	var c1 := Color("#c89a2c") if v == 0 else Color("#b8a038")
	_blob(img, 22.0, 26.0, 18.0, 20.0, PA.shade(c1, -0.25), c1, PA.shade(c1, 0.3))
	_blob(img, 12.0, 32.0, 9.0, 10.0, PA.shade(c1, -0.2), PA.shade(c1, -0.04), PA.shade(c1, 0.2))
	_blob(img, 33.0, 30.0, 9.0, 10.0, PA.shade(c1, -0.3), PA.shade(c1, -0.08), PA.shade(c1, 0.15))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 44, 76), INK)
	return img


static func _bale() -> Image:
	var img := PA.new_image(40, 32)
	PA.rect(img, 3, 8, 34, 20, Color("#c8a83c"))
	PA.rect(img, 3, 8, 34, 3, Color("#e8d070"))
	for x in range(5, 36, 3):
		PA.rect(img, x, 11 + int(PA.rnd(x, 1, 1211) * 4.0), 1, 12, Color("#a8882c"))
	PA.rect(img, 12, 8, 2, 20, Color("#7a5a22"))
	PA.rect(img, 26, 8, 2, 20, Color("#7a5a22"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 40, 32), INK)
	return img


## Étendard du peuple des cavaliers : une hampe, un fanion vert et une tête de cheval d'or.
static func _standard(v: int) -> Image:
	var img := PA.new_image(34, 76)
	PA.rect(img, 6, 6, 3, 68, WOOD_D)
	PA.rect(img, 6, 6, 1, 68, WOOD)
	var cloth := Color("#3a7a4a") if v == 0 else Color("#8a2a2a")
	PP._poly(img, [Vector2(9, 8), Vector2(31, 12), Vector2(26, 20), Vector2(31, 28), Vector2(9, 32)], cloth)
	PP._poly(img, [Vector2(9, 8), Vector2(31, 12), Vector2(29, 14), Vector2(9, 12)], PA.shade(cloth, 0.2))
	PA.ellipse(img, 19.0, 20.0, 4.0, 5.0, GOLD)
	PA.rect(img, 21, 14, 3, 4, GOLD)
	PA.rect(img, 22, 13, 1, 2, GOLD)
	PA.rect(img, 4, 2, 7, 5, GOLD)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 34, 76), INK)
	return img


static func _sheep(v: int) -> Image:
	var img := PA.new_image(40, 30)
	var wool := Color("#ece6d6") if v == 0 else Color("#d4ccb8")
	_blob(img, 21.0, 15.0, 14.0, 10.0, PA.shade(wool, -0.22), wool, Color("#ffffff"))
	for k in 4:
		PA.ellipse(img, 10.0 + k * 7.0, 8.0 + (k % 2) * 2.0, 4.0, 3.5, PA.shade(wool, 0.04))
	PA.ellipse(img, 7.0, 16.0, 5.0, 4.5, Color("#3a3036"))
	PA.px(img, 5, 14, Color.WHITE)
	PA.px(img, 6, 14, INK)
	PA.rect(img, 12, 23, 2, 5, Color("#3a3036"))
	PA.rect(img, 28, 23, 2, 5, Color("#3a3036"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 40, 30), INK)
	return img


static func _fence() -> Image:
	var img := PA.new_image(48, 30)
	for x in [3, 23, 43]:
		PA.rect(img, x, 6, 3, 22, WOOD)
		PA.rect(img, x, 6, 1, 22, WOOD_L)
	for y in [10, 18]:
		PA.rect(img, 2, y, 44, 3, WOOD)
		PA.rect(img, 2, y, 44, 1, WOOD_L)
		PA.rect(img, 2, y + 2, 44, 1, WOOD_D)
	PA.outline(img, Rect2i(0, 0, 48, 30), INK)
	return img


static func _throne() -> Image:
	var img := PA.new_image(48, 64)
	PA.rect(img, 12, 6, 24, 40, WOOD)
	PP._poly(img, [Vector2(12, 6), Vector2(24, 0), Vector2(36, 6)], GOLD_D)
	PA.rect(img, 12, 6, 24, 3, GOLD)
	PA.rect(img, 6, 30, 36, 8, WOOD_L)
	PA.rect(img, 6, 38, 36, 20, WOOD)
	PA.rect(img, 10, 56, 6, 6, WOOD_D)
	PA.rect(img, 32, 56, 6, 6, WOOD_D)
	PA.rect(img, 17, 14, 14, 14, Color("#3a7a4a"))   # coussin vert
	PA.ellipse(img, 24.0, 20.0, 3.5, 4.5, GOLD)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 48, 64), INK)
	return img


static func _bed() -> Image:
	var img := PA.new_image(64, 56)
	PA.rect(img, 4, 4, 56, 14, WOOD)
	PA.rect(img, 4, 4, 56, 3, GOLD)
	PA.rect(img, 6, 22, 52, 28, Color("#e8e0cc"))
	PA.rect(img, 6, 22, 52, 4, Color("#fff8e8"))
	PA.rect(img, 10, 26, 18, 10, Color("#d8d0bc"))
	PA.rect(img, 6, 36, 52, 14, Color("#3a7a4a"))
	PA.rect(img, 6, 36, 52, 2, Color("#5a9a62"))
	PA.rect(img, 4, 18, 4, 36, WOOD_D)
	PA.rect(img, 56, 18, 4, 36, WOOD_D)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 64, 56), INK)
	return img


static func _barn() -> Image:
	var img := PA.new_image(96, 80)
	PA.rect(img, 8, 30, 80, 46, WOOD)
	for x in range(10, 86, 6):
		PA.rect(img, x, 30, 1, 46, WOOD_D)
	PP._poly(img, [Vector2(2, 32), Vector2(48, 4), Vector2(94, 32)], Color("#8a5a28"))
	PP._poly(img, [Vector2(2, 32), Vector2(48, 4), Vector2(48, 10), Vector2(10, 32)], Color("#a87838"))
	PA.rect(img, 34, 46, 28, 30, WOOD_D)
	PA.rect(img, 48, 46, 1, 30, GOLD_D)
	PA.rect(img, 40, 32, 16, 8, Color("#c8a83c"))   # foin au grenier
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 96, 80), INK)
	return img


## Arbre-qui-marche : un tronc colossal à visage dans l'écorce, des bras de branches, une
## barbe de mousse. Variantes : 0 vieux, 1 mousseux, 2 endormi (yeux clos).
static func _ent(v: int) -> Image:
	var img := PA.new_image(64, 104)
	var bark := Color("#5a4a34") if v != 1 else Color("#4e5a38")
	var bark_l := PA.shade(bark, 0.2)
	var bark_d := PA.shade(bark, -0.25)
	PP._poly(img, [Vector2(18, 100), Vector2(22, 44), Vector2(42, 44), Vector2(48, 100)], bark)
	PP._poly(img, [Vector2(18, 100), Vector2(22, 44), Vector2(28, 44), Vector2(26, 100)], bark_l)
	PP._poly(img, [Vector2(40, 100), Vector2(38, 44), Vector2(42, 44), Vector2(48, 100)], bark_d)
	for k in 7:
		PA.rect(img, 24 + int(PA.rnd(k, 1, 1221) * 18.0), 48 + int(PA.rnd(k, 2, 1221) * 46.0), 1, 6, bark_d)
	var leaf := Color("#4a7a34") if v != 1 else Color("#6a8a3a")
	_blob(img, 32.0, 28.0, 26.0, 24.0, PA.shade(leaf, -0.3), leaf, PA.shade(leaf, 0.25))
	_blob(img, 14.0, 34.0, 11.0, 12.0, PA.shade(leaf, -0.32), PA.shade(leaf, -0.06), PA.shade(leaf, 0.18))
	_blob(img, 50.0, 34.0, 11.0, 12.0, PA.shade(leaf, -0.34), PA.shade(leaf, -0.1), PA.shade(leaf, 0.14))
	# visage
	PA.ellipse(img, 27.0, 56.0, 3.5, 2.5, Color("#1c1610"))
	PA.ellipse(img, 38.0, 56.0, 3.5, 2.5, Color("#1c1610"))
	if v == 2:
		PA.rect(img, 24, 56, 7, 1, Color("#0c0804"))
		PA.rect(img, 35, 56, 7, 1, Color("#0c0804"))
	else:
		PA.px(img, 27, 56, Color("#e8c050"))
		PA.px(img, 38, 56, Color("#e8c050"))
	PA.rect(img, 31, 58, 3, 6, bark_d)
	PA.rect(img, 27, 68, 12, 2, Color("#1c1610"))
	for k in 6:   # barbe de mousse
		PA.rect(img, 26 + k * 2, 70, 2, 6 + (k % 3) * 3, Color("#7aa04a"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 64, 104), INK)
	return img


static func _board() -> Image:
	var img := PA.new_image(44, 52)
	PA.rect(img, 20, 24, 4, 26, WOOD_D)
	PA.rect(img, 4, 4, 36, 22, WOOD)
	PA.rect(img, 4, 4, 36, 2, WOOD_L)
	PA.rect(img, 4, 24, 36, 2, WOOD_D)
	for y in [9, 13, 17, 21]:
		PA.rect(img, 8, y, 28 - (y % 3) * 4, 1, Color("#2c2218"))
	PA.outline(img, Rect2i(0, 0, 44, 52), INK)
	return img


static func _stump() -> Image:
	var img := PA.new_image(40, 30)
	PA.ellipse(img, 20.0, 20.0, 15.0, 8.0, Color("#4a3a26"))
	PA.rect(img, 5, 12, 30, 9, Color("#5a4630"))
	PA.ellipse(img, 20.0, 12.0, 15.0, 6.0, Color("#b8945a"))
	PA.ellipse(img, 20.0, 12.0, 9.0, 3.5, Color("#a07c44"))
	PA.ellipse(img, 20.0, 12.0, 4.0, 1.8, Color("#c8a468"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 40, 30), INK)
	return img


## Four de l'Isengarde : brique noire, gueule rougeoyante. 1 : porte entrouverte, fumante.
static func _oven(v: int) -> Image:
	var img := PA.new_image(56, 64)
	PA.rect(img, 4, 14, 48, 46, Color("#3a3844"))
	PP._poly(img, [Vector2(2, 16), Vector2(28, 2), Vector2(54, 16)], Color("#2a2832"))
	for y in range(18, 58, 8):
		PA.rect(img, 4, y, 48, 1, Color("#1c1a24"))
		for x in range(6 + (y % 16) / 2, 52, 12):
			PA.rect(img, x, y, 1, 8, Color("#1c1a24"))
	PA.rect(img, 14, 28, 28, 26, Color("#14121a"))
	PA.rect(img, 16, 36, 24, 16, Color("#c0481c"))
	PA.rect(img, 19, 42, 18, 8, EMBER)
	PA.rect(img, 22, 46, 12, 3, Color("#ffd870"))
	PA.rect(img, 12, 26, 32, 3, Color("#8a5a28"))
	if v == 1:
		PA.rect(img, 12, 28, 6, 26, IRON)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 56, 64), INK)
	return img


static func _pot() -> Image:
	var img := PA.new_image(48, 44)
	_blob(img, 24.0, 26.0, 18.0, 14.0, Color("#1c1a22"), Color("#3a3844"), Color("#7c7a88"))
	PA.ellipse(img, 24.0, 14.0, 17.0, 5.0, Color("#26232e"))
	PA.ellipse(img, 24.0, 14.0, 14.0, 3.5, Color("#c8a040"))   # soupe
	PA.ellipse(img, 20.0, 13.0, 4.0, 1.5, Color("#e8c878"))
	PA.rect(img, 10, 38, 4, 5, IRON)
	PA.rect(img, 34, 38, 4, 5, IRON)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 48, 44), INK)
	return img


static func _cage() -> Image:
	var img := PA.new_image(44, 56)
	PA.rect(img, 3, 4, 38, 3, IRON_L)
	PA.rect(img, 3, 48, 38, 4, IRON)
	for x in range(5, 40, 6):
		PA.rect(img, x, 7, 2, 41, IRON)
		PA.rect(img, x, 7, 1, 41, IRON_L)
	PA.rect(img, 3, 26, 38, 2, IRON)
	PA.rect(img, 16, 0, 12, 4, IRON)
	var tag := Color("#e8dcb8")
	PA.rect(img, 14, 30, 16, 12, tag)
	PA.rect(img, 16, 33, 12, 1, Color("#3a2a20"))
	PA.rect(img, 16, 36, 9, 1, Color("#3a2a20"))
	PA.rect(img, 16, 39, 11, 1, Color("#3a2a20"))
	PA.outline(img, Rect2i(0, 0, 44, 56), INK)
	return img


static func _sack(v: int) -> Image:
	var img := PA.new_image(36, 40)
	var cloth := Color("#d8d0b8") if v == 0 else Color("#c8bca0")
	_blob(img, 18.0, 24.0, 13.0, 14.0, PA.shade(cloth, -0.25), cloth, Color("#fffaf0"))
	PA.rect(img, 12, 6, 12, 5, PA.shade(cloth, -0.1))
	PA.rect(img, 11, 10, 14, 2, Color("#7a5a30"))
	PA.rect(img, 14, 20, 8, 6, Color("#a8402a"))   # tampon « farine T65 »
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 36, 40), INK)
	return img


static func _stack() -> Image:
	var img := PA.new_image(40, 96)
	PA.rect(img, 8, 10, 24, 84, Color("#3a3844"))
	PA.rect(img, 8, 10, 3, 84, Color("#55536a"))
	PA.rect(img, 28, 10, 4, 84, Color("#24222c"))
	for y in range(16, 90, 9):
		PA.rect(img, 8, y, 24, 1, Color("#1c1a24"))
	PA.rect(img, 4, 4, 32, 8, Color("#2a2832"))
	PA.rect(img, 4, 4, 32, 2, Color("#8a5a28"))
	PA.rect(img, 12, 76, 16, 10, Color("#14121a"))
	PA.rect(img, 15, 80, 10, 5, EMBER)
	PA.outline(img, Rect2i(0, 0, 40, 96), INK)
	return img


static func _plate() -> Image:
	var img := PA.new_image(48, 56)
	PA.rect(img, 6, 28, 4, 26, WOOD_D)
	PA.rect(img, 38, 28, 4, 26, WOOD_D)
	PA.rect(img, 2, 4, 44, 28, Color("#2a2832"))
	PA.rect(img, 2, 4, 44, 2, Color("#8a5a28"))
	PA.rect(img, 2, 30, 44, 2, Color("#8a5a28"))
	for y in [10, 15, 20, 25]:
		PA.rect(img, 6, y, 36 - (y % 7) * 3, 1, Color("#d8d0b8"))
	PA.rect(img, 30, 22, 12, 2, Color("#c0481c"))
	PA.outline(img, Rect2i(0, 0, 48, 56), INK)
	return img


## La tour d'Orthanc-Manger, vue de loin : un fût noir, des soupiraux de four et un panache de fumée.
static func _tower() -> Image:
	var img := PA.new_image(88, 192)
	PP._poly(img, [Vector2(22, 190), Vector2(30, 40), Vector2(58, 40), Vector2(66, 190)], Color("#2a2832"))
	PP._poly(img, [Vector2(22, 190), Vector2(30, 40), Vector2(38, 40), Vector2(34, 190)], Color("#44424f"))
	PP._poly(img, [Vector2(58, 40), Vector2(66, 190), Vector2(54, 190), Vector2(52, 40)], Color("#1c1a24"))
	for y in range(52, 186, 14):
		PA.rect(img, 28 - (y - 52) / 22, y, 32 + (y - 52) / 11, 1, Color("#14121a"))
	for y in [70, 110, 150]:
		PA.rect(img, 38, y, 12, 8, Color("#14121a"))
		PA.rect(img, 40, y + 3, 8, 4, EMBER)
	PP._poly(img, [Vector2(24, 40), Vector2(44, 8), Vector2(64, 40)], Color("#1c1a24"))
	PA.rect(img, 42, 0, 4, 12, Color("#8a5a28"))
	for k in 5:
		_blob(img, 44.0 + sin(float(k)) * 8.0, 14.0 - k * 2.0 + 4.0, 5.0 + k, 4.0 + k * 0.6, Color("#4a4852"), Color("#6a6874"), Color("#9a98a4"))
	PA.outline(img, Rect2i(0, 0, 88, 192), INK)
	return img


static func _wet_rock(v: int) -> Image:
	var img := PA.new_image(48, 36)
	var base := Color("#4a5a62") if v == 0 else Color("#586a72")
	_blob(img, 24.0, 22.0, 20.0, 13.0, PA.shade(base, -0.3), base, PA.shade(base, 0.3))
	_blob(img, 36.0, 24.0, 9.0, 8.0, PA.shade(base, -0.3), PA.shade(base, -0.08), PA.shade(base, 0.16))
	for k in 4:
		PA.px(img, 12 + k * 7, 28 + (k % 2), Color("#a8d0d8"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 48, 36), INK)
	return img


static func _foam() -> Image:
	var img := PA.new_image(48, 20)
	for k in 7:
		var cx := 6.0 + k * 6.0
		PA.ellipse(img, cx, 11.0 + (k % 2) * 2.0, 6.0, 4.0, Color("#e8f4f8"))
		PA.ellipse(img, cx - 1.0, 9.0, 3.0, 2.0, Color.WHITE)
	return img
