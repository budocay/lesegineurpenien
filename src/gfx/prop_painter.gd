extends RefCounted
## Peint les sprites de décor : arbres, buissons, tonneaux, bittes d'amarrage, barques...

const PA = preload("res://src/gfx/pixel_art.gd")

const GREENS := ["#1d3d38", "#2c6644", "#4f9449", "#93c95c"]
const AUTUMN := ["#5a2a2e", "#a34c2c", "#d78a34", "#f3c654"]


static func paint(kind: String, variant: int = 0) -> Image:
	match kind:
		"tree": return tree(variant)
		"bush": return bush(variant)
		"flowers": return flowers(variant)
		"grass": return grass_tuft(variant)
		"wheat": return wheat(variant)
		"wilted": return wilted(variant)
		"barrel": return barrel()
		"sign": return sign_post()
		"rock": return rock(variant)
		"bollard": return bollard(1)
		"monument": return monument()
		"boat": return boat(variant)
		"shelf": return shelf()
		"window": return night_window()
		"blob_shadow": return blob_shadow()
		"dot": return soft_dot()
	var img := PA.new_image(16, 16)
	img.fill(Color.MAGENTA)
	return img


static func _palette(src: Array) -> Array[Color]:
	var out: Array[Color] = []
	for s: Variant in src:
		out.append(Color.from_string(str(s), Color.GRAY))
	return out


## Feuillage en grappes : sombre, puis moyen, puis clair, décalés vers la lumière (haut-gauche).
static func _foliage(img: Image, blobs: Array, pal: Array[Color], sd: int) -> void:
	for b: Array in blobs:
		PA.ellipse(img, b[0], b[1], b[2], b[2] * 0.9, pal[0])
	for b: Array in blobs:
		PA.ellipse(img, b[0] - 1.5, b[1] - 2.0, b[2] - 2.5, (b[2] - 2.5) * 0.9, pal[1])
	for b: Array in blobs:
		PA.ellipse(img, b[0] - 3.0, b[1] - 4.0, b[2] * 0.52, b[2] * 0.45, pal[2])
	for b: Array in blobs:
		PA.ellipse(img, b[0] - 4.5, b[1] - 6.0, b[2] * 0.2, b[2] * 0.16, pal[3])
	# grain de feuilles
	var w := img.get_width()
	var h := img.get_height()
	for i in int(w * h / 22.0):
		var x := int(PA.rnd(i, 1, sd) * w)
		var y := int(PA.rnd(i, 2, sd) * h)
		var c := img.get_pixel(x, y)
		if c.a < 0.5:
			continue
		if c.is_equal_approx(pal[1]):
			img.set_pixel(x, y, pal[2] if PA.rnd(i, 3, sd) < 0.5 else pal[0])
		elif c.is_equal_approx(pal[0]):
			img.set_pixel(x, y, pal[1])
		elif c.is_equal_approx(pal[2]) and PA.rnd(i, 4, sd) < 0.4:
			img.set_pixel(x, y, pal[1])


static func tree(v: int) -> Image:
	var img := PA.new_image(72, 100)
	var pal := _palette(AUTUMN if v % 4 == 3 else GREENS)
	var bark := Color("#5b3f2e")
	var bark_d := Color("#3b2820")
	var bark_l := Color("#7a573c")
	var cx := 36
	for y in range(54, 98):
		var half := 4
		if y > 90:
			half += (y - 90) / 2
		PA.rect(img, cx - half, y, half * 2, 1, bark)
		PA.rect(img, cx + half - 3, y, 3, 1, bark_d)
		PA.px(img, cx - half, y, bark_l)
		if y < 64:
			PA.rect(img, cx - half, y, half * 2, 1, bark_d)
	PA.rect(img, cx - 1, 72, 2, 3, bark_d)
	PA.rect(img, cx - 3, 82, 1, 5, bark_l)
	var blobs: Array = []
	var base := [[36, 40, 20], [22, 46, 14], [50, 46, 14], [27, 28, 14], [46, 27, 14], [36, 17, 12], [15, 37, 10], [58, 37, 10], [36, 54, 12]]
	for i in base.size():
		var b: Array = base[i]
		blobs.append([
			float(b[0]) + PA.rnd(i, 1, 200 + v) * 5.0 - 2.5,
			float(b[1]) + PA.rnd(i, 2, 200 + v) * 4.0 - 2.0,
			float(b[2]) + PA.rnd(i, 3, 200 + v) * 2.0 - 1.0,
		])
	_foliage(img, blobs, pal, 210 + v)
	PA.outline(img, Rect2i(0, 0, 72, 100))
	return img


static func bush(v: int) -> Image:
	var img := PA.new_image(36, 26)
	var pal := _palette(GREENS)
	var blobs := [[18.0, 15.0, 10.0], [9.0, 18.0, 7.0], [27.0, 18.0, 7.0], [13.0, 10.0, 6.5], [23.0, 10.0, 6.5]]
	_foliage(img, blobs, pal, 230 + v)
	PA.rect(img, 0, 24, 36, 2, Color(0, 0, 0, 0))
	if v % 3 == 1:
		for i in 7:
			var x := 5 + int(PA.rnd(i, 1, 240) * 26.0)
			var y := 7 + int(PA.rnd(i, 2, 240) * 14.0)
			if img.get_pixel(x, y).a > 0.5:
				PA.px(img, x, y, Color("#d8475a"))
	PA.outline(img, Rect2i(0, 0, 36, 26))
	return img


static func flowers(v: int) -> Image:
	var img := PA.new_image(24, 14)
	var blooms := _palette(["#f4f0e2", "#f2d55c", "#e86a7a", "#b98ae0", "#7ab8e8"])
	for i in 5:
		var x := 2 + i * 4 + int(PA.rnd(i, 1, 250 + v) * 2.0)
		var n := 3 + int(PA.rnd(i, 2, 250 + v) * 6.0)
		PA.rect(img, x, 13 - n, 1, n, Color("#3f7d43"))
		var c: Color = blooms[(i + v) % blooms.size()]
		PA.rect(img, x - 1, 12 - n, 3, 2, c)
		PA.px(img, x, 12 - n, PA.shade(c, 0.4))
		PA.px(img, x + 1, 13 - n, PA.shade(c, -0.25))
	return img


static func grass_tuft(v: int) -> Image:
	var img := PA.new_image(16, 12)
	for i in 6:
		var x := 2 + i * 2 + int(PA.rnd(i, 1, 260 + v) * 2.0)
		var n := 4 + int(PA.rnd(i, 2, 260 + v) * 7.0)
		PA.rect(img, x, 12 - n, 1, n, Color("#3f8046"))
		PA.px(img, x, 12 - n, Color("#7fbb58"))
		if i % 2 == 0:
			PA.rect(img, x + 1, 12 - n + 2, 1, n - 2, Color("#2f6240"))
	return img


## Blé « ramolli » : les tiges retombent, l'épi pend vers le sol.
static func wheat(v: int) -> Image:
	var img := PA.new_image(26, 26)
	var stalk := Color("#b3923f")
	var gold := Color("#d9b84e")
	for i in 6:
		var x0 := 4 + i * 3 + int(PA.rnd(i, 1, 270 + v) * 2.0)
		var dir := 1 if PA.rnd(i, 2, 270 + v) < 0.5 else -1
		var up := 9 + int(PA.rnd(i, 3, 270 + v) * 6.0)
		PA.rect(img, x0, 26 - up, 1, up, stalk)
		var x := x0
		var y := 26 - up
		for k in 5:
			x += dir
			if k >= 2:
				y += 1
			PA.px(img, x, y, stalk)
		PA.rect(img, x, y + 1, 2, 4, gold)
		PA.px(img, x, y + 1, PA.shade(gold, 0.35))
		PA.px(img, x + 1, y + 4, PA.shade(gold, -0.3))
	return img


## Poireau flétri : le fût se couche, les feuilles traînent par terre.
static func wilted(v: int) -> Image:
	var img := PA.new_image(22, 12)
	var pale := Color("#dfe6c8")
	var leaf := Color("#6f9a4a")
	var leaf_d := Color("#4d7240")
	var dir := 1 if v % 2 == 0 else -1
	var bx := 11
	PA.rect(img, bx, 7, 2, 5, pale)
	PA.px(img, bx + 1, 8, PA.shade(pale, -0.2))
	PA.line(img, bx, 7, bx + dir * 4, 5, leaf)
	PA.line(img, bx + dir * 4, 5, bx + dir * 9, 10, leaf)
	PA.line(img, bx + 1, 7, bx - dir * 3, 6, leaf_d)
	PA.line(img, bx - dir * 3, 6, bx - dir * 7, 11, leaf_d)
	PA.line(img, bx, 6, bx + dir * 2, 3, leaf)
	PA.line(img, bx + dir * 2, 3, bx + dir * 6, 8, leaf_d)
	return img


static func barrel() -> Image:
	var img := PA.new_image(22, 28)
	var wood := Color("#8a5c36")
	var wood_d := Color("#5f3c24")
	var wood_l := Color("#aa7848")
	var iron := Color("#3f3d4a")
	var cx := 11
	for y in range(3, 27):
		var t := float(y - 3) / 23.0
		var half := 8 + int(round(sin(t * PI) * 2.0))
		PA.rect(img, cx - half, y, half * 2, 1, wood)
		PA.rect(img, cx + half - 3, y, 3, 1, wood_d)
		PA.px(img, cx - half, y, wood_l)
		for sx: int in [-5, -1, 3]:
			PA.px(img, cx + sx, y, wood_d)
		if y == 8 or y == 9 or y == 21 or y == 22:
			PA.rect(img, cx - half, y, half * 2, 1, iron)
			PA.rect(img, cx - half, y, 3, 1, Color("#6a6878"))
	PA.ellipse(img, 11.0, 4.5, 8.0, 3.0, wood_d)
	PA.ellipse(img, 11.0, 4.2, 7.0, 2.2, wood_l)
	PA.outline(img, Rect2i(0, 0, 22, 28))
	return img


static func sign_post() -> Image:
	var img := PA.new_image(26, 30)
	var wood := Color("#7a5230")
	var wood_d := Color("#523521")
	var board := Color("#c29a62")
	PA.rect(img, 12, 12, 3, 17, wood)
	PA.rect(img, 14, 12, 1, 17, wood_d)
	PA.rect(img, 1, 2, 24, 13, board)
	PA.rect(img, 1, 2, 24, 1, PA.shade(board, 0.3))
	PA.rect(img, 1, 14, 24, 1, wood_d)
	PA.rect(img, 24, 3, 1, 12, PA.shade(board, -0.25))
	PA.rect(img, 1, 8, 24, 1, PA.shade(board, -0.12))
	var ink := Color("#3a2618")
	PA.rect(img, 4, 5, 17, 1, ink)
	PA.rect(img, 4, 10, 12, 1, ink)
	PA.rect(img, 4, 12, 15, 1, ink)
	PA.px(img, 2, 3, wood_d)
	PA.px(img, 23, 3, wood_d)
	PA.outline(img, Rect2i(0, 0, 26, 30))
	return img


static func rock(v: int) -> Image:
	var img := PA.new_image(26, 18)
	var g := Color("#807c88")
	PA.ellipse(img, 13.0, 11.0, 12.0, 6.5, PA.shade(g, -0.25))
	PA.ellipse(img, 12.0, 9.5, 10.0, 5.0, g)
	PA.ellipse(img, 9.5 + (v % 2) * 2.0, 7.5, 5.0, 2.2, PA.shade(g, 0.3))
	PA.line(img, 15, 8, 18, 13, PA.shade(g, -0.35))
	PA.rect(img, 0, 16, 26, 2, Color(0, 0, 0, 0))
	PA.outline(img, Rect2i(0, 0, 26, 18))
	return img


## Bitte d'amarrage en chêne taillé, fierté des Grobittes. s = facteur de taille entier.
static func bollard(s: int) -> Image:
	var w := 22 * s
	var h := 30 * s
	var img := PA.new_image(w, h)
	var wood := Color("#8a5a34")
	var wood_d := Color("#5c3922")
	var wood_l := Color("#b27c4a")
	var iron := Color("#3a3944")
	var rope := Color("#d8c08a")
	var rope_d := Color("#a0875a")
	var cx := w / 2.0
	for y in range(8 * s, 27 * s):
		var t := float(y - 8 * s) / float(19 * s)
		var half := 4.0 * s + t * t * 2.0 * s
		for x in range(int(cx - half), int(cx + half)):
			var u := (x + 0.5 - cx) / half
			var c := wood
			if u > 0.4:
				c = wood_d
			elif u < -0.55:
				c = wood_l
			if posmod(x, 3 * s) == 0 and PA.rnd(x, y / s, 300) < 0.55:
				c = PA.shade(c, -0.14)
			PA.px(img, x, y, c)
	PA.rect(img, int(cx) - 7 * s, 26 * s, 14 * s, 3 * s, wood_d)
	PA.rect(img, int(cx) - 7 * s, 26 * s, 14 * s, s, wood)
	PA.ellipse(img, cx, 6.0 * s, 8.5 * s, 5.0 * s, wood_d)
	PA.ellipse(img, cx - 0.5 * s, 5.2 * s, 7.5 * s, 4.0 * s, wood)
	PA.ellipse(img, cx - 2.0 * s, 4.0 * s, 4.0 * s, 1.6 * s, wood_l)
	PA.rect(img, int(cx) - 4 * s, 10 * s, 8 * s, s, iron)
	for y in range(15 * s, 19 * s):
		for x in range(int(cx) - 5 * s, int(cx) + 5 * s):
			var c2 := rope if ((x + y) / s) % 2 == 0 else rope_d
			if y >= 18 * s:
				c2 = rope_d
			PA.px(img, x, y, c2)
	PA.outline(img, Rect2i(0, 0, w, h))
	return img


## La Grande Bitte de la place : une bitte géante sur son socle, pavoisée pour la fête.
static func monument() -> Image:
	var img := PA.new_image(78, 104)
	var big := bollard(3)
	img.blit_rect(big, Rect2i(0, 0, 66, 90), Vector2i(6, 1))
	var stone := Color("#8d8894")
	PA.rect(img, 3, 87, 72, 15, stone)
	PA.rect(img, 3, 87, 72, 2, PA.shade(stone, 0.28))
	PA.rect(img, 3, 99, 72, 3, PA.shade(stone, -0.28))
	PA.rect(img, 66, 89, 9, 10, PA.shade(stone, -0.16))
	for x in range(3, 75, 12):
		PA.rect(img, x, 93, 1, 6, PA.shade(stone, -0.2))
	PA.rect(img, 30, 91, 18, 6, Color("#d9b04a"))
	PA.rect(img, 30, 91, 18, 1, Color("#fff0b0"))
	PA.rect(img, 33, 93, 12, 1, Color("#7a5a1c"))
	PA.rect(img, 33, 95, 9, 1, Color("#7a5a1c"))
	# guirlande de fanions
	var flags := _palette(["#e86a7a", "#f2d55c", "#7ab8e8", "#f4f0e2"])
	for i in 9:
		var x := 22 + i * 4
		var y := 58 + int(round(sin(float(i) / 8.0 * PI) * 5.0))
		PA.px(img, x, y, Color("#3a2618"))
		PA.px(img, x + 1, y, Color("#3a2618"))
		PA.px(img, x + 2, y, Color("#3a2618"))
		PA.px(img, x + 3, y, Color("#3a2618"))
		var c: Color = flags[i % flags.size()]
		PA.rect(img, x, y + 1, 3, 2, c)
		PA.px(img, x + 1, y + 3, c)
	PA.outline(img, Rect2i(0, 0, 78, 104))
	return img


static func boat(v: int) -> Image:
	var img := PA.new_image(84, 30)
	var hull := Color("#8a5636")
	var hull_d := Color("#5a3624")
	var rim := Color("#c59762")
	var stripe := Color("#3f6ea0") if v % 2 == 0 else Color("#a8483c")
	for x in 84:
		var t := absf(float(x) / 83.0 - 0.5) * 2.0
		var top := 11 - int(round(pow(t, 3.0) * 5.0))
		var bottom := 27 - int(round(pow(t, 2.5) * 13.0))
		if bottom <= top:
			continue
		for y in range(top, bottom + 1):
			var c := hull
			if y - top < 2:
				c = rim
			elif y - top == 4 or y - top == 5:
				c = stripe
			elif (y - top) % 5 == 3:
				c = hull_d
			if y >= bottom - 1:
				c = hull_d
			PA.px(img, x, y, c)
	PA.rect(img, 24, 8, 5, 3, rim)
	PA.rect(img, 54, 8, 5, 3, rim)
	PA.rect(img, 40, 2, 2, 9, hull_d)
	PA.rect(img, 38, 1, 6, 2, Color("#d8c08a"))
	PA.outline(img, Rect2i(0, 0, 84, 30))
	return img


static func shelf() -> Image:
	var img := PA.new_image(44, 36)
	var wood := Color("#6a472e")
	var bottles := _palette(["#5a8a5a", "#a8483c", "#3f6ea0", "#d9b04a", "#8a5ca8"])
	for row in 2:
		var y := 15 + row * 17
		PA.rect(img, 0, y, 44, 3, wood)
		PA.rect(img, 0, y, 44, 1, PA.shade(wood, 0.3))
		PA.rect(img, 3, y + 3, 2, 2, PA.shade(wood, -0.3))
		PA.rect(img, 39, y + 3, 2, 2, PA.shade(wood, -0.3))
		for i in 6:
			var x := 3 + i * 7
			var c: Color = bottles[(i + row * 2) % bottles.size()]
			if (i + row) % 3 == 2:
				PA.rect(img, x, y - 5, 5, 5, Color("#c9a26a"))
				PA.rect(img, x, y - 5, 5, 1, Color("#efe6d2"))
				PA.px(img, x + 5, y - 3, Color("#c9a26a"))
			else:
				PA.rect(img, x, y - 8, 4, 8, c)
				PA.rect(img, x + 1, y - 11, 2, 3, c)
				PA.px(img, x, y - 7, PA.shade(c, 0.5))
				PA.rect(img, x + 3, y - 8, 1, 8, PA.shade(c, -0.3))
	PA.outline(img, Rect2i(0, 0, 44, 36))
	return img


## Fenêtre d'intérieur donnant sur le crépuscule.
static func night_window() -> Image:
	var img := PA.new_image(30, 32)
	var wood := Color("#5a3d2b")
	PA.rect(img, 1, 1, 28, 27, wood)
	for y in range(3, 26):
		var t := float(y - 3) / 22.0
		var c := Color("#34407e").lerp(Color("#b06a8a"), t * t)
		PA.rect(img, 3, y, 24, 1, c)
	PA.px(img, 7, 6, Color("#f4f0e2"))
	PA.px(img, 21, 9, Color("#f4f0e2"))
	PA.px(img, 12, 12, Color("#c8c8ee"))
	PA.rect(img, 14, 3, 2, 23, wood)
	PA.rect(img, 3, 13, 24, 2, wood)
	PA.rect(img, 0, 28, 30, 3, PA.shade(wood, 0.2))
	PA.rect(img, 1, 1, 28, 1, PA.shade(wood, 0.25))
	PA.outline(img, Rect2i(0, 0, 30, 32))
	return img


static func blob_shadow() -> Image:
	var img := PA.new_image(32, 14)
	PA.ellipse(img, 16.0, 7.0, 15.0, 6.5, Color(0, 0, 0, 0.16))
	PA.ellipse(img, 16.0, 7.0, 12.0, 5.0, Color(0, 0, 0, 0.3))
	return img


static func soft_dot() -> Image:
	var img := PA.new_image(8, 8)
	for y in 8:
		for x in 8:
			var d := Vector2(x - 3.5, y - 3.5).length() / 4.0
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0)))
	return img
