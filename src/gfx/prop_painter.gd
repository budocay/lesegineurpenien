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
		"boulder": return boulder(variant)
		"stump": return stump(variant)
		"log": return log_prop(variant)
		"mushrooms": return mushrooms(variant)
		"reeds": return reeds(variant)
		"haystack": return haystack(variant)
		"fence": return fence(variant)
		"pillar": return pillar(variant)
		"brazier": return brazier(variant)
		"anvil": return anvil(variant)
		"forge": return forge(variant)
		"deadtree": return deadtree(variant)
		"fern": return fern(variant)
		"bollard": return bollard(1)
		"monument": return monument()
		"boat": return boat(variant)
		"shelf": return shelf()
		"window": return night_window()
		"blob_shadow": return blob_shadow()
		"dot": return soft_dot()
	# styles d'architecture ajoutés (elfe) : chargés à l'usage pour éviter une référence circulaire
	var elven: GDScript = load("res://src/gfx/elven_painter.gd")
	if elven.has_prop(kind):
		return elven.paint_prop(kind, variant)
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


## Fougère : des frondes en arc qui retombent de part et d'autre (rousse une fois sur trois).
static func fern(v: int) -> Image:
	var img := PA.new_image(22, 13)
	var pal := _palette(["#245a3c", "#3f8a4a", "#86c45e"] if v % 3 != 2 else ["#6a3a28", "#b0662e", "#e0a048"])
	for i in 6:
		var dir := -1.0 + 2.0 * float(i) / 5.0 + (PA.rnd(i, 1, 270 + v) - 0.5) * 0.25
		var length := 7 + int(PA.rnd(i, 2, 270 + v) * 4.0)
		var rise := 8.0 + PA.rnd(i, 3, 270 + v) * 3.0
		for k in length:
			var t := float(k) / float(length)
			var x := int(round(11.0 + dir * t * 10.0))
			var y := int(round(12.0 - sin(t * PI * 0.62) * rise))
			if x < 0 or x > 21 or y < 0 or y > 12:
				continue
			if y + 1 <= 12:
				PA.px(img, x, y + 1, pal[0])
			PA.px(img, x, y, pal[2] if k >= length - 3 else pal[1])
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
## Une gerbe : un rang de tiges sombres derrière, un rang clair devant, des feuilles, et
## au bout de chaque tige un épi lourd, à grains, qui pend.
static func wheat(v: int) -> Image:
	var w := 36
	var h := 34
	var img := PA.new_image(w, h)
	var sd := 270 + v
	var stalk := Color("#b8963f")
	var stalk_d := Color("#86672c")
	var gold := Color("#e2bd4c")
	var gold_l := Color("#f6e08a")
	var gold_d := Color("#a87a2a")
	var leaf := Color("#93a044")
	var leaf_d := Color("#66762f")
	for layer in 2:
		var dim := -0.2 if layer == 0 else 0.0
		for i in 5:
			var n := layer * 5 + i
			var x0 := 8 + i * 4 + int(PA.rnd(n, 1, sd) * 3.0) + layer * 2
			var dir := 1 if PA.rnd(n, 2, sd) < 0.5 else -1
			var up := (16 if layer == 0 else 12) + int(PA.rnd(n, 3, sd) * 7.0)
			var x := x0
			var y := h - 1
			for k in up:
				y = h - 1 - k
				if k > up / 2 and k % 4 == 0:
					x += dir
				var body := stalk_d if (layer == 0 or k < 3) else stalk
				PA.px(img, x, y, body)
			# une feuille qui s'écarte de la tige
			var ly := h - 2 - up / 3
			var lc := leaf_d if layer == 0 else leaf
			PA.px(img, x0 - dir, ly, lc)
			PA.px(img, x0 - dir * 2, ly - 1, lc)
			PA.px(img, x0 - dir * 3, ly - 1, lc)
			PA.px(img, x0 - dir * 4, ly, leaf_d)
			# le col plie sous le poids
			for k in 3:
				x += dir
				if k >= 1:
					y += 1
				PA.px(img, x, y, stalk_d if layer == 0 else stalk)
			# l'épi : trois pixels de large, grains clairs à gauche, sombres à droite
			for g in 7:
				var wide := 1 if (g == 0 or g == 6) else 3
				for e in wide:
					var col := gold
					if wide == 3 and e == 0:
						col = gold_l
					elif wide == 3 and e == 2:
						col = gold_d
					elif g % 2 == 0 and wide == 3:
						col = gold_d.lerp(gold, 0.45)
					PA.px(img, x - wide / 2 + e, y + 1 + g, PA.shade(col, dim) if dim < 0.0 else col)
			# barbes au bout de l'épi
			PA.px(img, x - 2, y + 8, gold_d)
			PA.px(img, x + 2, y + 8, gold_d)
			PA.px(img, x, y + 8, gold_l if layer == 1 else gold)
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


const GREENS5 := ["#11282b", "#1d4b38", "#2c7140", "#4e9f4a", "#8ccb5e"]
const BIRCH5 := ["#1f3d2c", "#35703c", "#58a046", "#86c85a", "#c4e888"]
const PINE5 := ["#0f2529", "#1a463b", "#2c6b49", "#4c9455", "#86c26a"]
const AUTUMN5 := ["#4a1f2a", "#8c3a28", "#c8602a", "#eb9a36", "#f8d56a"]


## Remplit un polygone (centres de pixels, règle pair-impair).
static func _poly(img: Image, pts: Array, c: Color) -> void:
	var minx := 9999
	var maxx := -9999
	var miny := 9999
	var maxy := -9999
	for p: Vector2 in pts:
		minx = mini(minx, int(floor(p.x)))
		maxx = maxi(maxx, int(ceil(p.x)))
		miny = mini(miny, int(floor(p.y)))
		maxy = maxi(maxy, int(ceil(p.y)))
	for y in range(miny, maxy + 1):
		for x in range(minx, maxx + 1):
			var px := float(x) + 0.5
			var py := float(y) + 0.5
			var inside := false
			var j := pts.size() - 1
			for i in pts.size():
				var a: Vector2 = pts[i]
				var b: Vector2 = pts[j]
				if (a.y > py) != (b.y > py) and px < (b.x - a.x) * (py - a.y) / (b.y - a.y) + a.x:
					inside = not inside
				j = i
			if inside:
				PA.px(img, x, y, c)


## Un volume de feuillage : ellipse éclairée d'en haut à gauche, cinq tons selon l'angle
## de la surface, grain irrégulier. idx garde le ton de chaque pixel (pour les feuilles).
static func _leaf_blob(img: Image, idx: Dictionary, cx: float, cy: float, rx: float, ry: float, pal: Array[Color], sd: int, bias: float) -> void:
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			var d2 := nx * nx + ny * ny
			if d2 > 1.0:
				continue
			var l := -0.62 * nx - 0.8 * ny + bias
			# bord éclairé un peu plus clair, bord à l'ombre bien plus sombre
			l += (PA.rnd(x, y, sd) - 0.5) * 0.34
			if d2 > 0.8:
				l += 0.12 if (nx + ny) < 0.0 else -0.2
			var k := 0
			if l > 0.62:
				k = 4
			elif l > 0.24:
				k = 3
			elif l > -0.14:
				k = 2
			elif l > -0.5:
				k = 1
			PA.px(img, x, y, pal[k])
			idx[Vector2i(x, y)] = k


## Feuilles : petits paquets clairs sur les zones éclairées, creux sombres ailleurs.
static func _leaf_detail(img: Image, idx: Dictionary, pal: Array[Color], sd: int, count: int) -> void:
	var keys := idx.keys()
	if keys.is_empty():
		return
	for i in count:
		var p: Vector2i = keys[int(PA.rnd(i, 7, sd) * keys.size()) % keys.size()]
		var k: int = idx[p]
		if k >= 2 and k < 4 and PA.rnd(i, 8, sd) < 0.7:
			for dx in 3:
				if idx.has(Vector2i(p.x + dx, p.y)):
					PA.px(img, p.x + dx, p.y, pal[k + 1])
			if idx.has(Vector2i(p.x + 1, p.y + 1)):
				PA.px(img, p.x + 1, p.y + 1, pal[k - 1])
		elif k <= 2:
			for dx in 2:
				if idx.has(Vector2i(p.x + dx, p.y)):
					PA.px(img, p.x + dx, p.y, pal[maxi(0, k - 1)])


## Feuillage complet : gros volumes puis petites touffes sur leur contour (bord festonné).
static func _canopy(img: Image, blobs: Array, pal: Array[Color], sd: int, scallops: int) -> Dictionary:
	var idx: Dictionary = {}
	# du fond vers l'avant : les blobs sont rangés du plus haut au plus bas
	for i in blobs.size():
		var b: Array = blobs[i]
		_leaf_blob(img, idx, b[0], b[1], b[2], b[2] * 0.88, pal, sd + i, 0.0)
		for s in scallops:
			var a := PA.rnd(i, s + 40, sd) * TAU
			var r := float(b[2]) * (0.86 + PA.rnd(i, s + 60, sd) * 0.2)
			var sr := 2.4 + PA.rnd(i, s + 80, sd) * 2.2
			_leaf_blob(img, idx, float(b[0]) + cos(a) * r, float(b[1]) + sin(a) * r * 0.88, sr, sr * 0.9, pal, sd + 90 + s, -0.1 + (0.1 if sin(a) < 0.0 else 0.0))
	_leaf_detail(img, idx, pal, sd + 5, 260)
	return idx


## Tronc : flèche d'écorce striée, liseré clair à gauche, ombre à droite, pied évasé.
static func _trunk(img: Image, cx: int, y0: int, y1: int, half_top: int, half_bot: int, sd: int, bark: Array[Color]) -> void:
	for y in range(y0, y1 + 1):
		var t := float(y - y0) / float(maxi(1, y1 - y0))
		var half := half_top + int(round(float(half_bot - half_top) * pow(t, 3.0)))
		for x in range(cx - half, cx + half):
			var u := float(x - (cx - half)) / float(half * 2)
			var c := bark[1]
			if u < 0.22:
				c = bark[2]
			elif u > 0.68:
				c = bark[0]
			var streak := PA.rnd(x, y / 5, sd)
			if streak < 0.2:
				c = PA.shade(c, -0.12)
			elif streak > 0.88:
				c = PA.shade(c, 0.08)
			PA.px(img, x, y, c)
		if y < y0 + 8:
			PA.rect(img, cx - half, y, half * 2, 1, PA.shade(bark[0], -0.1 * float(8 - (y - y0)) / 8.0))
	# nœud et mousse
	PA.px(img, cx - 1, y0 + (y1 - y0) / 2, bark[0])
	PA.px(img, cx, y0 + (y1 - y0) / 2, bark[0])
	for k in 5:
		PA.px(img, cx - half_top + 1, y1 - 14 + k * 2, Color("#5c8a45"))
	# racines
	PA.line(img, cx - half_bot, y1, cx - half_bot - 3, y1, bark[0])
	PA.line(img, cx + half_bot - 1, y1, cx + half_bot + 2, y1, bark[0])


static func tree(v: int) -> Image:
	var img := PA.new_image(72, 100)
	var kind := v % 4
	var pal := _palette(GREENS5 if kind == 0 else (BIRCH5 if kind == 1 else (PINE5 if kind == 2 else AUTUMN5)))
	if kind == 2:
		return _pine(img, pal, v)
	var bark: Array[Color] = [Color("#3a2820"), Color("#5b3f2e"), Color("#86614a")]
	if kind == 1:
		bark = [Color("#8a867e"), Color("#cfc9bc"), Color("#f0ebdd")]
	var cx := 36
	# branches en fourche, cachées en haut par le feuillage
	var branch := bark[1]
	PA.line(img, cx, 62, cx - 11, 46, branch)
	PA.line(img, cx + 1, 62, cx - 10, 46, branch)
	PA.line(img, cx, 64, cx + 12, 48, branch)
	PA.line(img, cx + 1, 64, cx + 13, 48, branch)
	_trunk(img, cx, 58, 97, 4, 8, 210 + v, bark)
	if kind == 1:
		for k in 7:
			var yy := 64 + int(PA.rnd(k, 1, 215) * 28.0)
			PA.rect(img, cx - 3 + int(PA.rnd(k, 2, 215) * 4.0), yy, 2, 1, Color("#2a2622"))
	var blobs: Array = []
	var base := [[36, 38, 17], [21, 45, 12], [51, 45, 12], [26, 28, 12], [46, 28, 12], [36, 19, 11], [14, 38, 8], [58, 38, 8], [36, 52, 10]]
	for i in base.size():
		var b: Array = base[i]
		blobs.append([
			float(b[0]) + PA.rnd(i, 1, 200 + v) * 4.0 - 2.0,
			float(b[1]) + PA.rnd(i, 2, 200 + v) * 4.0 - 2.0,
			float(b[2]) + PA.rnd(i, 3, 200 + v) * 2.0 - 1.0,
		])
	# du haut vers le bas pour que les volumes inférieurs recouvrent les supérieurs
	blobs.sort_custom(func(a: Array, b: Array) -> bool: return a[1] < b[1])
	_canopy(img, blobs, pal, 210 + v, 5)
	# ombre portée du feuillage sur le haut du tronc
	for x in range(cx - 4, cx + 5):
		for y in range(60, 66):
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and c.is_equal_approx(bark[1]):
				img.set_pixel(x, y, bark[0])
	PA.outline(img, Rect2i(0, 0, 72, 100))
	return img


static func _pine(img: Image, pal: Array[Color], v: int) -> Image:
	var bark: Array[Color] = [Color("#33241c"), Color("#52392a"), Color("#7a553c")]
	var cx := 36
	_trunk(img, cx, 70, 97, 3, 6, 220 + v, bark)
	var idx: Dictionary = {}
	var tiers := 6
	for i in tiers:
		var t := float(i) / float(tiers - 1)
		var yb := 22 + i * 11
		var half := 7.0 + t * 20.0
		var hgt := 20.0
		# triangle à base frangée
		for y in range(int(float(yb) - hgt), yb + 1):
			var k := float(y - (yb - hgt)) / hgt
			var hw := half * k
			var x0 := int(floor(float(cx) - hw))
			var x1 := int(ceil(float(cx) + hw))
			for x in range(x0, x1):
				var nx := (float(x) + 0.5 - float(cx)) / maxf(hw, 1.0)
				var l := -0.55 * nx - 0.45 * (k - 0.4) + (PA.rnd(x, y, 230 + v) - 0.5) * 0.4
				if k > 0.88:
					l -= 0.2
				var q := 0
				if l > 0.5:
					q = 4
				elif l > 0.2:
					q = 3
				elif l > -0.15:
					q = 2
				elif l > -0.45:
					q = 1
				# base dentelée
				if k > 0.9 and posmod(x, 5) < 2:
					continue
				PA.px(img, x, y, pal[q])
				idx[Vector2i(x, y)] = q
	_leaf_detail(img, idx, pal, 240 + v, 120)
	PA.outline(img, Rect2i(0, 0, 72, 100))
	return img


static func bush(v: int) -> Image:
	var img := PA.new_image(36, 26)
	var pal := _palette(GREENS5 if v % 3 != 2 else BIRCH5)
	var blobs: Array = [[12.0, 11.0, 6.5], [24.0, 11.5, 6.5], [18.0, 8.0, 7.0], [8.0, 17.0, 6.5], [28.0, 17.0, 6.5], [18.0, 16.0, 8.5]]
	_canopy(img, blobs, pal, 230 + v, 3)
	PA.rect(img, 0, 24, 36, 2, Color(0, 0, 0, 0))
	if v % 3 == 1:
		for i in 9:
			var x := 5 + int(PA.rnd(i, 1, 240) * 26.0)
			var y := 7 + int(PA.rnd(i, 2, 240) * 14.0)
			if img.get_pixel(x, y).a > 0.5:
				PA.rect(img, x, y, 2, 2, Color("#d8475a"))
				PA.px(img, x, y, Color("#ff9aa0"))
	elif v % 3 == 2:
		for i in 7:
			var x := 5 + int(PA.rnd(i, 3, 241) * 26.0)
			var y := 6 + int(PA.rnd(i, 4, 241) * 14.0)
			if img.get_pixel(x, y).a > 0.5:
				PA.px(img, x, y, Color("#f6f0e0"))
				PA.px(img, x + 1, y, Color("#f2d55c"))
	PA.outline(img, Rect2i(0, 0, 36, 26))
	return img


## Roche anguleuse : un contour irrégulier découpé en facettes (dessus clair, face
## gauche moyenne, face droite sombre), arêtes marquées, éclats, mousse selon la variante.
static func rock(v: int) -> Image:
	return _rock_shape(26, 18, v, 1.0)


static func boulder(v: int) -> Image:
	return _rock_shape(52, 38, v + 2, 2.0)


static func _rock_shape(w: int, h: int, v: int, k: float) -> Image:
	var img := PA.new_image(w, h)
	var sd := 300 + v
	var warm := v % 3 == 2
	var g := Color("#8a8691") if not warm else Color("#948577")
	var jit := func(i: int) -> Vector2:
		return Vector2((PA.rnd(i, 1, sd) - 0.5) * 2.0 * k, (PA.rnd(i, 2, sd) - 0.5) * 1.6 * k)
	var P: Array[Vector2] = []
	var raw := [Vector2(1, 13), Vector2(3, 7), Vector2(8, 2.5), Vector2(15, 1.5), Vector2(21, 5), Vector2(25, 11), Vector2(21, 16.5), Vector2(7, 16.5)]
	for i in raw.size():
		var p: Vector2 = raw[i] * k + jit.call(i)
		P.append(Vector2(clampf(p.x, 1.0, float(w) - 1.0), clampf(p.y, 1.0, float(h) - 1.0)))
	var T: Vector2 = Vector2(12.0, 6.0) * k + jit.call(10)
	var L: Vector2 = Vector2(7.0, 10.0) * k + jit.call(11)
	var R: Vector2 = Vector2(18.0, 10.5) * k + jit.call(12)
	var M: Vector2 = Vector2(12.5, 12.0) * k + jit.call(13)
	_poly(img, [P[1], P[2], P[3], T, L], PA.shade(g, 0.28))
	_poly(img, [P[3], P[4], P[5], R, T], PA.shade(g, 0.1))
	_poly(img, [L, T, R, M], g)
	_poly(img, [P[0], P[1], L, M, P[7]], PA.shade(g, -0.2))
	_poly(img, [M, R, P[5], P[6], P[7]], PA.shade(g, -0.38))
	# arêtes : traits sombres entre facettes, trait clair sur le haut
	var edge := PA.shade(g, -0.5)
	for pair: Array in [[L, T], [T, R], [R, M], [M, L], [L, P[1]], [R, P[5]], [M, P[7]]]:
		var a: Vector2 = pair[0]
		var b: Vector2 = pair[1]
		PA.line(img, int(a.x), int(a.y), int(b.x), int(b.y), edge)
	var lite := PA.shade(g, 0.5)
	for i in 3:
		var a: Vector2 = P[i + 1]
		var b: Vector2 = P[i + 2]
		PA.line(img, int(a.x), int(a.y) + 1, int(b.x), int(b.y) + 1, lite)
	# grain et fissure
	for i in int(w * h / 14.0):
		var x := int(PA.rnd(i, 3, sd) * w)
		var y := int(PA.rnd(i, 4, sd) * h)
		var c := img.get_pixel(x, y)
		if c.a > 0.5:
			img.set_pixel(x, y, PA.shade(c, -0.1 if PA.rnd(i, 5, sd) < 0.6 else 0.1))
	PA.line(img, int(T.x + 1.0 * k), int(T.y + 1.0 * k), int(T.x + 3.0 * k), int(T.y + 5.0 * k), edge)
	if v % 3 == 1:
		# mousse sur le dessus
		for i in int(14.0 * k * k):
			var x := int(P[2].x - 3.0 * k + PA.rnd(i, 6, sd) * 12.0 * k)
			var y := int(P[2].y + PA.rnd(i, 7, sd) * 5.0 * k)
			var c := img.get_pixel(x, y)
			if c.a > 0.5 and y < int(L.y):
				img.set_pixel(x, y, Color("#6f9a4c") if PA.rnd(i, 8, sd) < 0.7 else Color("#93bf5e"))
	PA.outline(img, Rect2i(0, 0, w, h))
	return img


## Souche : dessus clair à cernes, flanc d'écorce strié, pied évasé.
static func stump(v: int) -> Image:
	var img := PA.new_image(30, 22)
	var bark: Array[Color] = [Color("#3a2820"), Color("#5b3f2e"), Color("#86614a")]
	_trunk(img, 15, 9, 20, 10, 12, 320 + v, bark)
	PA.ellipse(img, 15.0, 8.5, 11.0, 4.6, Color("#5b3f2e"))
	PA.ellipse(img, 15.0, 8.0, 10.0, 4.0, Color("#c8a06a"))
	PA.ellipse(img, 15.0, 8.0, 7.0, 2.8, Color("#b78c56"))
	PA.ellipse(img, 15.0, 8.0, 4.0, 1.6, Color("#c8a06a"))
	PA.px(img, 15, 8, Color("#8a6238"))
	PA.line(img, 8, 6, 12, 5, Color("#e2c48c"))
	if v % 2 == 1:
		PA.ellipse(img, 22.0, 6.5, 3.0, 1.3, Color("#5c8a45"))
		PA.px(img, 21, 6, Color("#8cba5c"))
	PA.outline(img, Rect2i(0, 0, 30, 22))
	return img


## Tronc couché : écorce striée, bout scié à cernes, moignon de branche, mousse.
static func log_prop(v: int) -> Image:
	var img := PA.new_image(46, 20)
	var bark := [Color("#3a2820"), Color("#5b3f2e"), Color("#86614a")]
	for y in range(4, 17):
		var t := float(y - 4) / 12.0
		var c: Color = bark[2] if t < 0.2 else (bark[1] if t < 0.7 else bark[0])
		PA.rect(img, 6, y, 36, 1, c)
		for x in range(6, 42):
			if PA.rnd(x / 3, y, 330 + v) < 0.12:
				PA.px(img, x, y, PA.shade(c, -0.12))
	PA.ellipse(img, 7.0, 10.0, 5.0, 6.8, Color("#c8a06a"))
	PA.ellipse(img, 7.0, 10.0, 3.4, 4.8, Color("#b78c56"))
	PA.ellipse(img, 7.0, 10.0, 1.6, 2.2, Color("#c8a06a"))
	PA.px(img, 7, 10, Color("#8a6238"))
	PA.rect(img, 22, 1, 4, 4, bark[1])
	PA.rect(img, 22, 1, 1, 4, bark[2])
	PA.rect(img, 24, 1, 2, 4, bark[0])
	for i in 9:
		PA.px(img, 12 + i * 3 + (i % 2), 4 + (i % 3), Color("#6f9a4c"))
		PA.px(img, 13 + i * 3, 5, Color("#4d7a3a"))
	PA.outline(img, Rect2i(0, 0, 46, 20))
	return img


## Touffe de champignons : chapeau rouge à pois blancs ou brun, pied pâle.
static func mushrooms(v: int) -> Image:
	var img := PA.new_image(22, 16)
	var cap := Color("#d44a3c") if v % 2 == 0 else Color("#a8744a")
	var spots := Color("#f6f0e0")
	var items := [[6, 13, 4, 3], [14, 12, 5, 4], [10, 15, 3, 2]]
	for it: Array in items:
		var cx: int = it[0]
		var by: int = it[1]
		var r: int = it[2]
		var sh: int = it[3]
		PA.rect(img, cx - 1, by - sh, 2, sh + 1, Color("#e8dcc0"))
		PA.px(img, cx, by - sh, Color("#bfb092"))
		PA.ellipse(img, float(cx), float(by - sh - 1), float(r) + 0.5, float(r) * 0.62, PA.shade(cap, -0.25))
		PA.ellipse(img, float(cx) - 0.5, float(by - sh - 1.5), float(r) - 0.3, float(r) * 0.5, cap)
		PA.px(img, cx - r / 2, by - sh - 3, PA.shade(cap, 0.35))
		if v % 2 == 0:
			PA.px(img, cx - 1, by - sh - 2, spots)
			PA.px(img, cx + 1, by - sh - 3, spots)
	PA.outline(img, Rect2i(0, 0, 22, 16))
	return img


## Roseaux et massettes : lames qui retombent, épis bruns.
static func reeds(v: int) -> Image:
	var img := PA.new_image(30, 46)
	var pal := _palette(["#2a5a3a", "#4a8a48", "#8cc060"])
	for i in 9:
		var x := 4 + i * 3 + int(PA.rnd(i, 1, 340 + v) * 2.0)
		var hgt := 22 + int(PA.rnd(i, 2, 340 + v) * 20.0)
		var lean := (PA.rnd(i, 3, 340 + v) - 0.5) * 6.0
		var c: Color = pal[1] if i % 2 == 0 else pal[0]
		for k in hgt:
			var t := float(k) / float(hgt)
			var xx := int(round(float(x) + lean * t * t))
			PA.px(img, xx, 45 - k, c)
			if k > hgt / 2:
				PA.px(img, xx + 1, 45 - k, pal[2] if i % 2 == 0 else c)
		if i % 3 == 1:
			var tx := int(round(float(x) + lean))
			PA.rect(img, tx, 45 - hgt - 1, 2, 6, Color("#6a4528"))
			PA.px(img, tx, 45 - hgt - 1, Color("#8a6238"))
			PA.px(img, tx, 45 - hgt - 5, Color("#3a2618"))
	# longues feuilles qui retombent
	for i in 3:
		var x0 := 6 + i * 8
		for k in 12:
			PA.px(img, x0 + k / 2 * (1 if i % 2 == 0 else -1), 30 - k + (k * k) / 14, pal[2])
	PA.outline(img, Rect2i(0, 0, 30, 46))
	return img


## Meule de foin : dôme de paille, brins horizontaux, lien de corde.
static func haystack(v: int) -> Image:
	var img := PA.new_image(40, 34)
	var straw := [Color("#e2c060"), Color("#c9a248"), Color("#a67f34"), Color("#f2dc8c")]
	for y in range(3, 33):
		var t := float(y - 3) / 29.0
		var half := 7.0 + 12.0 * sqrt(clampf(t * 1.1, 0.0, 1.0)) if t < 0.9 else 19.0
		for x in range(int(20.0 - half), int(20.0 + half)):
			var u := (float(x) - (20.0 - half)) / (half * 2.0)
			var c: Color = straw[0]
			if u < 0.3:
				c = straw[3]
			elif u > 0.66:
				c = straw[2]
			elif PA.rnd(x, y, 350 + v) < 0.3:
				c = straw[1]
			PA.px(img, x, y, c)
	for i in 36:
		var x := 5 + int(PA.rnd(i, 1, 351) * 30.0)
		var y := 6 + int(PA.rnd(i, 2, 351) * 25.0)
		if img.get_pixel(x, y).a > 0.5:
			PA.rect(img, x, y, 3, 1, straw[1] if PA.rnd(i, 3, 351) < 0.5 else straw[3])
	PA.rect(img, 3, 22, 34, 2, Color("#7a5a34"))
	PA.rect(img, 3, 22, 34, 1, Color("#a07a48"))
	PA.rect(img, 19, 1, 2, 3, straw[1])
	PA.px(img, 18, 2, straw[3])
	PA.px(img, 21, 1, straw[3])
	PA.outline(img, Rect2i(0, 0, 40, 34))
	return img


## Barrière de champ : deux lisses sur trois piquets ; la variante 1 a un piquet qui penche.
static func fence(v: int) -> Image:
	var img := PA.new_image(46, 26)
	var wood := Color("#8a6a48")
	var wood_l := Color("#b08a5c")
	var wood_d := Color("#5a4230")
	for px: int in [3, 22, 41]:
		var lean := 0 if not (v == 1 and px == 22) else 2
		for y in range(3, 25):
			var xo := px + (lean * (24 - y)) / 22
			PA.rect(img, xo, y, 4, 1, wood)
			PA.px(img, xo, y, wood_l)
			PA.px(img, xo + 3, y, wood_d)
			if PA.rnd(xo, y, 360) < 0.1:
				PA.px(img, xo + 1, y, wood_d)
		PA.rect(img, px - (0 if lean == 0 else -lean), 2, 4, 1, wood_l)
	for ry: int in [8, 17]:
		if v == 1 and ry == 17:
			PA.rect(img, 3, ry, 18, 3, wood)
			PA.rect(img, 3, ry, 18, 1, wood_l)
			PA.rect(img, 3, ry + 2, 18, 1, wood_d)
			continue
		PA.rect(img, 1, ry, 44, 3, wood)
		PA.rect(img, 1, ry, 44, 1, wood_l)
		PA.rect(img, 1, ry + 2, 44, 1, wood_d)
		for i in 5:
			PA.px(img, 5 + i * 9, ry + 1, wood_d)
	PA.outline(img, Rect2i(0, 0, 46, 26))
	return img


## Pilier de pierre : fût cannelé, chapiteau et base, fissures, braise sur le flanc.
static func pillar(v: int) -> Image:
	var img := PA.new_image(28, 78)
	var s := [Color("#6a5a5e"), Color("#4a3e46"), Color("#8a767a"), Color("#2f262e")]
	PA.rect(img, 2, 66, 24, 10, s[1])
	PA.rect(img, 2, 66, 24, 2, s[2])
	PA.rect(img, 0, 72, 28, 6, s[3])
	PA.rect(img, 0, 72, 28, 1, s[1])
	for y in range(10, 66):
		for x in range(5, 23):
			var u := float(x - 5) / 18.0
			var c: Color = s[0]
			if u < 0.18:
				c = s[2]
			elif u > 0.7:
				c = s[1]
			if (x - 5) % 4 == 0:
				c = PA.shade(c, -0.12)
			if PA.rnd(x, y, 370 + v) < 0.07:
				c = PA.shade(c, -0.15)
			PA.px(img, x, y, c)
	PA.rect(img, 1, 3, 26, 8, s[1])
	PA.rect(img, 1, 3, 26, 2, s[2])
	PA.rect(img, 3, 11, 22, 2, s[3])
	PA.rect(img, 0, 0, 28, 4, s[0])
	PA.rect(img, 0, 0, 28, 1, s[2])
	for k in 12:
		PA.px(img, 13 + int(sin(float(k)) * 2.0), 26 + k, s[3])
	for y in range(40, 62):
		if PA.rnd(y, 1, 371) < 0.4:
			PA.px(img, 22, y, Color("#d8602a"))
	PA.outline(img, Rect2i(0, 0, 28, 78))
	return img


## Brasero : cuvette de fer sur trépied, flammes à trois tons (lueur ajoutée à l'affichage).
static func brazier(v: int) -> Image:
	var img := PA.new_image(24, 38)
	var iron := [Color("#3a3640"), Color("#26232c"), Color("#5a5662")]
	for leg: Array in [[7, 36, 11, 26], [17, 36, 13, 26], [12, 37, 12, 26]]:
		PA.line(img, leg[0], leg[1], leg[2], leg[3], iron[0])
	PA.ellipse(img, 12.0, 24.0, 10.0, 3.6, iron[1])
	PA.rect(img, 2, 22, 20, 4, iron[0])
	PA.rect(img, 2, 22, 20, 1, iron[2])
	PA.ellipse(img, 12.0, 22.0, 9.0, 2.6, Color("#c8501c"))
	for i in 3:
		var fx := 12.0 + float(i - 1) * 4.5
		var fh := 11.0 - float(absi(i - 1)) * 3.0 + PA.rnd(i, 1, 380 + v) * 3.0
		PA.ellipse(img, fx, 21.0 - fh * 0.5, 4.2 - float(absi(i - 1)) * 0.6, fh * 0.55, Color("#e8501c"))
		PA.ellipse(img, fx, 21.0 - fh * 0.42, 2.8, fh * 0.42, Color("#ff9a2a"))
		PA.ellipse(img, fx, 20.0 - fh * 0.25, 1.4, fh * 0.26, Color("#ffe27a"))
		PA.px(img, int(fx), int(21.0 - fh - 0.5), Color("#e8501c"))
	PA.outline(img, Rect2i(0, 0, 24, 38), Color("#3a1408"))
	return img


static func anvil(v: int) -> Image:
	var img := PA.new_image(30, 22)
	var m := [Color("#4a4652"), Color("#2a2730"), Color("#7a7684")]
	PA.rect(img, 9, 14, 12, 6, m[1])
	PA.rect(img, 7, 19, 16, 2, m[0])
	PA.rect(img, 11, 10, 8, 5, m[0])
	PA.rect(img, 2, 5, 26, 6, m[0])
	PA.rect(img, 2, 5, 26, 1, m[2])
	PA.line(img, 2, 6, 0, 6, m[0])
	PA.rect(img, 22, 7, 6, 3, m[1])
	PA.rect(img, 5, 6, 8, 1, Color("#a8a4b4"))
	PA.px(img, 14, 5, Color("#ffd27a"))
	PA.px(img, 15, 4, Color("#ff9a2a"))
	PA.outline(img, Rect2i(0, 0, 30, 22))
	return img


## Forge : four de pierre à bouche voûtée incandescente, cheminée de brique.
static func forge(v: int) -> Image:
	var img := PA.new_image(72, 64)
	var s := [Color("#5a4c52"), Color("#3a3038"), Color("#7a6a70"), Color("#241e26")]
	PA.rect(img, 26, 0, 20, 22, s[1])
	PA.rect(img, 26, 0, 3, 22, s[2])
	for y in range(0, 22, 4):
		PA.rect(img, 26, y, 20, 1, s[3])
	for y in range(18, 62):
		var t := float(y - 18) / 44.0
		var half := 18 + int(t * 16.0)
		for x in range(36 - half, 36 + half):
			var u := float(x - (36 - half)) / float(half * 2)
			var c: Color = s[0]
			if u < 0.15:
				c = s[2]
			elif u > 0.8:
				c = s[1]
			if PA.rnd(x / 3, y / 3, 390) < 0.25:
				c = PA.shade(c, -0.1)
			if y % 7 == 0:
				c = s[3]
			PA.px(img, x, y, c)
	# bouche voûtée
	for y in range(36, 62):
		var half := 12 if y > 46 else int(sqrt(maxf(0.0, 144.0 - float((46 - y) * (46 - y)))))
		for x in range(36 - half, 36 + half):
			var t := float(y - 36) / 26.0
			PA.px(img, x, y, Color("#ffe27a").lerp(Color("#e8501c"), clampf(absf(float(x - 36)) / 12.0 * 0.7 + (1.0 - t) * 0.4, 0.0, 1.0)))
	PA.rect(img, 22, 60, 28, 4, s[3])
	PA.outline(img, Rect2i(0, 0, 72, 64), Color("#2a0e0c"))
	return img


## Arbre mort : tronc tordu, branches nues en fourches.
static func deadtree(v: int) -> Image:
	var img := PA.new_image(52, 84)
	var bark: Array[Color] = [Color("#2a2228"), Color("#4a3c40"), Color("#6e5c5c")]
	_trunk(img, 26, 30, 82, 3, 8, 400 + v, bark)
	var br := bark[1]
	for b: Array in [[26, 40, 8, 22], [26, 44, 44, 26], [26, 56, 6, 46], [26, 34, 36, 10], [14, 30, 6, 16], [36, 18, 46, 8], [8, 22, 2, 10]]:
		PA.line(img, b[0], b[1], b[2], b[3], br)
		PA.line(img, b[0] + 1, b[1], b[2] + 1, b[3], bark[0])
	PA.outline(img, Rect2i(0, 0, 52, 84))
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
	PA.ellipse(img, 16.0, 7.0, 15.0, 6.5, Color(0, 0, 0, 0.2))
	PA.ellipse(img, 16.0, 7.0, 12.0, 5.0, Color(0, 0, 0, 0.42))
	return img


static func soft_dot() -> Image:
	var img := PA.new_image(8, 8)
	for y in 8:
		for x in 8:
			var d := Vector2(x - 3.5, y - 3.5).length() / 4.0
			img.set_pixel(x, y, Color(1, 1, 1, clampf(1.0 - d, 0.0, 1.0)))
	return img
