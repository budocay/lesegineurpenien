extends RefCounted
## Petits accessoires d'habillage, sans obstacle ou presque : mobilier de village (puits, banc,
## brouette, potager, linge, boîte aux lettres, butte) et d'écurie (râtelier, abreuvoir, cheval
## de bois, brasero). Posés par les cartes comme n'importe quel accessoire (`prop`, `scatter`).
## Appelé par prop_painter.gd ; la table des rayons d'obstacle est dans map_builder.gd (PROPS).

const PA = preload("res://src/gfx/pixel_art.gd")
const PP = preload("res://src/gfx/prop_painter.gd")

const WOOD := Color("#a87a34")
const WOOD_L := Color("#d4a44c")
const WOOD_D := Color("#6a4a22")
const STONE := Color("#9a968c")
const STONE_L := Color("#c0bcb0")
const STONE_D := Color("#6a665e")
const INK := Color("#1d1a2b")

const PROP_VARIANTS := {
	"vil_puits": 1, "vil_banc": 1, "vil_brouette": 1, "vil_potager": 3, "vil_linge": 2, "vil_boite": 1, "vil_butte": 2,
	"cav_ratelier": 1, "cav_abreuvoir": 1, "cav_cheval_bois": 1, "cav_brasero": 1,
}


static func has_prop(kind: String) -> bool:
	return PROP_VARIANTS.has(kind)


static func paint_prop(kind: String, v: int) -> Image:
	match kind:
		"vil_puits": return _well()
		"vil_banc": return _bench()
		"vil_brouette": return _barrow()
		"vil_potager": return _veg(v)
		"vil_linge": return _washing(v)
		"vil_boite": return _mailbox()
		"vil_butte": return _mound(v)
		"cav_ratelier": return _rack()
		"cav_abreuvoir": return _trough()
		"cav_cheval_bois": return _horse()
		"cav_brasero": return _brazier()
	var img := PA.new_image(16, 16)
	img.fill(Color.MAGENTA)
	return img


## Puits de pierre : margelle ronde, deux montants, petit toit et seau.
static func _well() -> Image:
	var img := PA.new_image(40, 58)
	PA.ellipse(img, 20.0, 46.0, 15.0, 8.0, STONE_D)
	PA.rect(img, 5, 34, 30, 12, STONE)
	PA.ellipse(img, 20.0, 34.0, 15.0, 7.0, STONE_L)
	PA.ellipse(img, 20.0, 34.0, 11.0, 4.5, Color("#1c2a3a"))
	PA.ellipse(img, 20.0, 35.0, 8.0, 2.5, Color("#3a6a8a"))
	for x in range(6, 34, 6):
		PA.rect(img, x, 36, 1, 9, STONE_D)
	PA.rect(img, 6, 14, 3, 25, WOOD_D)
	PA.rect(img, 31, 14, 3, 25, WOOD_D)
	PA.rect(img, 6, 14, 1, 25, WOOD)
	PP._poly(img, [Vector2(2, 15), Vector2(20, 3), Vector2(38, 15)], Color("#9a4a32"))
	PP._poly(img, [Vector2(6, 15), Vector2(20, 6), Vector2(34, 15)], Color("#b8603e"))
	PA.rect(img, 19, 15, 2, 12, Color("#e8d8b0"))
	PA.rect(img, 17, 27, 6, 5, WOOD)
	PA.rect(img, 17, 27, 6, 1, WOOD_L)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 40, 58), INK)
	return img


static func _bench() -> Image:
	var img := PA.new_image(44, 28)
	PA.rect(img, 4, 18, 3, 8, WOOD_D)
	PA.rect(img, 37, 18, 3, 8, WOOD_D)
	PA.rect(img, 2, 14, 40, 4, WOOD)
	PA.rect(img, 2, 14, 40, 1, WOOD_L)
	PA.rect(img, 2, 17, 40, 1, WOOD_D)
	PA.rect(img, 3, 5, 38, 3, WOOD)
	PA.rect(img, 3, 5, 38, 1, WOOD_L)
	PA.rect(img, 5, 8, 2, 7, WOOD_D)
	PA.rect(img, 37, 8, 2, 7, WOOD_D)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 44, 28), INK)
	return img


## Brouette : bac de bois chargé de terre, roue pleine, deux bras.
static func _barrow() -> Image:
	var img := PA.new_image(46, 30)
	PP._poly(img, [Vector2(10, 7), Vector2(38, 7), Vector2(34, 19), Vector2(14, 19)], WOOD)
	PA.rect(img, 10, 7, 28, 2, WOOD_L)
	PA.ellipse(img, 24.0, 7.0, 12.0, 2.5, Color("#5a3e26"))
	PA.ellipse(img, 21.0, 6.0, 5.0, 1.8, Color("#7a5a38"))
	PA.rect(img, 2, 17, 14, 2, WOOD_D)
	PA.rect(img, 34, 19, 9, 2, WOOD_D)
	PA.ellipse(img, 37.0, 22.0, 6.0, 6.0, Color("#3a2e26"))
	PA.ellipse(img, 37.0, 22.0, 2.5, 2.5, Color("#8a7a66"))
	PA.rect(img, 12, 19, 2, 8, WOOD_D)
	PA.rect(img, 4, 20, 2, 7, WOOD_D)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 46, 30), INK)
	return img


## Carré de potager : planche de terre bordée de bois, rangs de légumes (3 variantes).
static func _veg(v: int) -> Image:
	var img := PA.new_image(52, 30)
	PA.rect(img, 1, 8, 50, 20, Color("#5a3e26"))
	for y in [11, 16, 21]:
		PA.rect(img, 2, y, 48, 2, Color("#46301c"))
	PA.rect(img, 1, 6, 50, 3, WOOD)
	PA.rect(img, 1, 6, 50, 1, WOOD_L)
	PA.rect(img, 1, 26, 50, 2, WOOD_D)
	var leaf: Array[Color] = [Color("#4a9a46"), Color("#7ac05a"), Color("#8ab84a")]
	var top: Array[Color] = [Color("#e8883a"), Color("#d84a4a"), Color("#f0d84a")]
	for row in 3:
		var y := 8 + row * 5
		for i in 7:
			var x := 4 + i * 7 + int(PA.rnd(i, row, 311 + v) * 2.0)
			var big := 3 + int(PA.rnd(i, row, 312 + v) * 2.0)
			PA.ellipse(img, float(x), float(y + 1), float(big), 2.4, leaf[(row + v) % 3])
			PA.rect(img, x - 1, y - 3, 2, 3, leaf[(i + v) % 3].lightened(0.15))
			if (i + row + v) % 3 == 0:
				PA.ellipse(img, float(x), float(y + 2), 1.8, 1.4, top[(row + v) % 3])
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 52, 30), INK)
	return img


## Corde à linge entre deux piquets : draps et chemises (2 variantes de couleurs).
static func _washing(v: int) -> Image:
	var img := PA.new_image(64, 50)
	PA.rect(img, 3, 6, 3, 42, WOOD_D)
	PA.rect(img, 58, 6, 3, 42, WOOD_D)
	PA.rect(img, 3, 6, 1, 42, WOOD)
	PA.rect(img, 58, 6, 1, 42, WOOD)
	for x in range(6, 58):
		var sag := int(2.0 * sin(float(x - 6) / 52.0 * PI))
		PA.px(img, x, 9 + sag, Color("#e0d0a8"))
	var cols: Array = [[Color("#f4f0e6"), Color("#d84a4a"), Color("#4a7ac8")], [Color("#f4e6c8"), Color("#4a9a6a"), Color("#e8c04a")]][v % 2]
	var spans := [[9, 16, 20], [27, 12, 14], [42, 12, 18]]
	for k in 3:
		var sx: int = spans[k][0]
		var wd: int = spans[k][1]
		var hg: int = spans[k][2]
		var c: Color = cols[k]
		var sag := int(2.0 * sin(float(sx + wd / 2 - 6) / 52.0 * PI))
		PA.rect(img, sx, 10 + sag, wd, hg, c)
		PA.rect(img, sx, 10 + sag, wd, 1, c.lightened(0.25))
		PA.rect(img, sx + wd - 2, 11 + sag, 2, hg - 1, PA.shade(c, -0.18))
		for fy in range(14, hg, 5):
			PA.rect(img, sx + 3, 10 + sag + fy, wd - 7, 1, PA.shade(c, -0.1))
		PA.rect(img, sx + 2, 9 + sag, 2, 3, WOOD_D)
		PA.rect(img, sx + wd - 4, 9 + sag, 2, 3, WOOD_D)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 64, 50), INK)
	return img


static func _mailbox() -> Image:
	var img := PA.new_image(18, 44)
	PA.rect(img, 8, 16, 3, 26, WOOD_D)
	PA.rect(img, 8, 16, 1, 26, WOOD)
	PA.rect(img, 2, 6, 14, 10, Color("#b8503a"))
	PA.rect(img, 2, 6, 14, 2, Color("#d8705a"))
	PA.ellipse(img, 9.0, 6.0, 7.0, 3.0, Color("#b8503a"))
	PA.rect(img, 5, 10, 8, 1, Color("#3a1a14"))
	PA.rect(img, 14, 2, 2, 6, Color("#e8d040"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 18, 44), INK)
	return img


## Petite butte herbue, quelques fleurs ou un pierrier (2 variantes).
static func _mound(v: int) -> Image:
	var img := PA.new_image(56, 24)
	PA.ellipse(img, 28.0, 17.0, 26.0, 7.0, Color("#3e6e36"))
	PA.ellipse(img, 27.0, 14.0, 22.0, 9.0, Color("#5a9a48"))
	PA.ellipse(img, 22.0, 11.0, 12.0, 5.0, Color("#78b85c"))
	for i in 22:
		var x := 6 + int(PA.rnd(i, 1, 331 + v) * 44.0)
		var y := 8 + int(PA.rnd(i, 2, 331 + v) * 10.0)
		if img.get_pixel(x, y).a > 0.5:
			PA.rect(img, x, y - 1, 1, 2, Color("#8acc66") if PA.rnd(i, 3, 331) < 0.5 else Color("#3e7a3a"))
	var cols: Array = [Color("#f4f0e2"), Color("#f2d55c"), Color("#e86a7a")] if v == 0 else [Color("#9a968c"), Color("#c0bcb0"), Color("#7a766e")]
	for i in 7:
		var x := 10 + int(PA.rnd(i, 4, 332 + v) * 36.0)
		var y := 10 + int(PA.rnd(i, 5, 332 + v) * 8.0)
		if v == 0:
			PA.rect(img, x, y, 2, 2, cols[i % 3])
		else:
			PA.ellipse(img, float(x), float(y), 2.5, 1.8, cols[i % 3])
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 56, 24), INK)
	return img


## Râtelier de bois : deux montants, barre d'attache, foin dans le casier.
static func _rack() -> Image:
	var img := PA.new_image(56, 40)
	for x in [4, 49]:
		PA.rect(img, x, 8, 3, 30, WOOD_D)
		PA.rect(img, x, 8, 1, 30, WOOD)
	PA.rect(img, 3, 14, 50, 3, WOOD)
	PA.rect(img, 3, 14, 50, 1, WOOD_L)
	PA.rect(img, 5, 22, 46, 10, Color("#c8a83c"))
	PA.rect(img, 5, 22, 46, 2, Color("#e8d070"))
	for x in range(7, 50, 3):
		PA.rect(img, x, 24 + int(PA.rnd(x, 1, 341) * 3.0), 1, 7, Color("#a8882c"))
	for x in range(8, 48, 6):
		PA.rect(img, x, 20, 2, 14, WOOD_D)
	PA.rect(img, 5, 32, 46, 3, WOOD)
	PA.rect(img, 5, 32, 46, 1, WOOD_L)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 56, 40), INK)
	return img


## Abreuvoir : auge de planches pleine d'eau, deux pieds.
static func _trough() -> Image:
	var img := PA.new_image(56, 30)
	PA.rect(img, 4, 22, 4, 6, WOOD_D)
	PA.rect(img, 48, 22, 4, 6, WOOD_D)
	PA.rect(img, 2, 10, 52, 14, WOOD)
	PA.rect(img, 2, 10, 52, 2, WOOD_L)
	PA.rect(img, 2, 22, 52, 2, WOOD_D)
	for x in [14, 28, 42]:
		PA.rect(img, x, 12, 1, 11, WOOD_D)
	PA.rect(img, 4, 7, 48, 5, Color("#2f6a8a"))
	PA.rect(img, 6, 8, 20, 1, Color("#8ad0e8"))
	PA.rect(img, 34, 9, 10, 1, Color("#5aa8c8"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 56, 30), INK)
	return img


## Cheval de bois (jeu d'enfants ou lice d'entraînement) : tête sculptée, crinière, quatre pieds.
static func _horse() -> Image:
	var img := PA.new_image(48, 56)
	PA.rect(img, 10, 38, 3, 16, WOOD_D)
	PA.rect(img, 34, 38, 3, 16, WOOD_D)
	PA.rect(img, 15, 40, 3, 13, WOOD_D)
	PA.rect(img, 29, 40, 3, 13, WOOD_D)
	PA.rect(img, 8, 26, 32, 14, WOOD)
	PA.rect(img, 8, 26, 32, 2, WOOD_L)
	PA.rect(img, 8, 38, 32, 2, WOOD_D)
	PP._poly(img, [Vector2(30, 28), Vector2(34, 8), Vector2(42, 6), Vector2(46, 16), Vector2(40, 18), Vector2(38, 28)], WOOD)
	PP._poly(img, [Vector2(34, 8), Vector2(38, 3), Vector2(40, 7)], WOOD_L)
	PA.rect(img, 31, 8, 4, 20, Color("#7a3a22"))
	PA.rect(img, 41, 10, 2, 2, INK)
	PA.rect(img, 5, 26, 4, 10, Color("#7a3a22"))
	PA.rect(img, 16, 30, 14, 4, Color("#8a2a2a"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 48, 56), INK)
	return img


## Brasero sur pied : cuvette de fer, braises et flamme (la lumière se pose avec un objet `light`).
static func _brazier() -> Image:
	var img := PA.new_image(32, 56)
	PA.rect(img, 15, 26, 3, 26, Color("#3a3844"))
	PA.rect(img, 7, 50, 19, 3, Color("#3a3844"))
	PP._poly(img, [Vector2(16, 40), Vector2(8, 52), Vector2(10, 52)], Color("#3a3844"))
	PP._poly(img, [Vector2(16, 40), Vector2(24, 52), Vector2(22, 52)], Color("#3a3844"))
	PP._poly(img, [Vector2(3, 22), Vector2(30, 22), Vector2(25, 32), Vector2(8, 32)], Color("#4a4854"))
	PA.rect(img, 3, 21, 27, 3, Color("#7c7a88"))
	PA.ellipse(img, 16.0, 21.0, 12.0, 3.0, Color("#ff8a30"))
	PP._poly(img, [Vector2(8, 21), Vector2(12, 8), Vector2(15, 14), Vector2(17, 3), Vector2(21, 13), Vector2(24, 21)], Color("#ff8a30"))
	PP._poly(img, [Vector2(12, 21), Vector2(15, 12), Vector2(17, 8), Vector2(20, 21)], Color("#ffd060"))
	PA.rect(img, 15, 15, 2, 6, Color("#fff4b0"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 32, 56), INK)
	return img
