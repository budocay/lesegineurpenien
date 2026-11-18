extends RefCounted
## Peint les textures répétables (sols, murs, toits) et les façades des maisons.
## Densité : 24 pixels par unité monde. Les textures répétables font 48 px (2 unités).

const PA = preload("res://src/gfx/pixel_art.gd")
const T := 48
const PPU := 24

const ROOFS := {
	"rouge": ["#a8523c", "#964634", "#b96247", "#5f2b28", "#cf7a56"],
	"vert": ["#5f7d4c", "#536f44", "#6d8c56", "#2f4232", "#86a468"],
	"ardoise": ["#5c6684", "#4f5874", "#6b7594", "#30364e", "#8690ad"],
	"chaume": ["#c2a25a", "#b3924c", "#cfb06a", "#7c6234", "#e2c884"],
}


static func paint(kind: String) -> Image:
	match kind:
		"grass": return _grass()
		"path": return _dirt()
		"cobble": return _stones(["#8d8794", "#9a94a0", "#7f7a88", "#a39a8f"], Color("#4c4650"), 12, 8)
		"planks": return _planks(Color("#8b6a48"), Color("#5e4631"), Color("#a5825a"))
		"floor": return _planks(Color("#9a6b3e"), Color("#6a4528"), Color("#b5834e"))
		"wood": return _planks(Color("#86562f"), Color("#5c3920"), Color("#a26d3d"))
		"soil": return _soil()
		"plaster": return _plaster(Color("#e2cfa6"))
		"brick": return _stones(["#a85a44", "#9a4e3c", "#b56a50", "#a0604a"], Color("#6d5a50"), 12, 6)
		"stone": return _stones(["#85828e", "#928f9a", "#777482", "#8d8880"], Color("#45414c"), 16, 12)
		"iron": return _iron()
		"cliff": return _cliff()
		"cliff_lip": return _cliff_lip()
		"steps": return _steps()
		"interior_wall": return _interior_wall()
	if kind.begins_with("roof_"):
		return _roof(kind.trim_prefix("roof_"))
	var img := PA.new_image(T, T)
	img.fill(Color.MAGENTA)
	return img


static func _wrap_ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(posmod(x, w), posmod(y, h), c)


static func _blotches(img: Image, sd: int, count: int, c: Color, rmin: float, rmax: float) -> void:
	for i in count:
		var cx := PA.rnd(i, 1, sd) * img.get_width()
		var cy := PA.rnd(i, 2, sd) * img.get_height()
		var r := lerpf(rmin, rmax, PA.rnd(i, 3, sd))
		_wrap_ellipse(img, cx, cy, r, r * 0.7, c)


static func _specks(img: Image, sd: int, count: int, c: Color) -> void:
	for i in count:
		var x := int(PA.rnd(i, 4, sd) * img.get_width())
		var y := int(PA.rnd(i, 5, sd) * img.get_height())
		img.set_pixel(x, y, c)


static func _grass() -> Image:
	var img := PA.new_image(T, T)
	var base := Color("#3f7d43")
	var dark := Color("#33683d")
	var light := Color("#4f9148")
	var tip := Color("#70ad52")
	img.fill(base)
	_blotches(img, 11, 14, dark, 4.0, 8.0)
	_blotches(img, 12, 12, light, 3.0, 6.0)
	_specks(img, 13, 70, dark)
	for i in 46:
		var x := int(PA.rnd(i, 1, 21) * T)
		var y := int(PA.rnd(i, 2, 21) * T)
		img.set_pixel(x, y, tip)
		img.set_pixel(x, (y + 1) % T, light)
	# brins dressés : pointe claire, pied sombre
	for i in 26:
		var x := int(PA.rnd(i, 3, 22) * T)
		var y := int(PA.rnd(i, 4, 22) * T)
		img.set_pixel(x, y, tip)
		img.set_pixel(x, (y + 1) % T, tip)
		img.set_pixel((x + 1) % T, (y + 1) % T, light)
		img.set_pixel(x, (y + 2) % T, dark)
		img.set_pixel((x + 1) % T, (y + 2) % T, Color("#2b5936"))
	# trèfles
	for i in 5:
		var x := int(PA.rnd(i, 5, 23) * T)
		var y := int(PA.rnd(i, 6, 23) * T)
		for d: Vector2i in [Vector2i(0, 0), Vector2i(2, 0), Vector2i(1, 1), Vector2i(1, -1)]:
			img.set_pixel(posmod(x + d.x, T), posmod(y + d.y, T), Color("#63a85a"))
		img.set_pixel((x + 1) % T, y, Color("#2f6238"))
	# pâquerettes et boutons d'or, rares
	for i in 4:
		var x := int(PA.rnd(i, 7, 24) * T)
		var y := int(PA.rnd(i, 8, 24) * T)
		var petal := Color("#f4f0e0") if i % 2 == 0 else Color("#f2d24a")
		img.set_pixel(x, y, petal)
		img.set_pixel((x + 1) % T, y, petal.darkened(0.12))
		img.set_pixel(x, (y + 1) % T, dark)
	return img


static func _dirt() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#b58d5c"))
	_blotches(img, 31, 12, Color("#a37d50"), 4.0, 8.0)
	_blotches(img, 32, 10, Color("#c7a372"), 3.0, 6.0)
	_specks(img, 33, 60, Color("#96704a"))
	for i in 9:
		var x := int(PA.rnd(i, 1, 34) * (T - 3))
		var y := int(PA.rnd(i, 2, 34) * (T - 3))
		PA.rect(img, x, y, 2, 2, Color("#9a948a"))
		PA.px(img, x, y, Color("#bdb7ab"))
		PA.rect(img, x, y + 2, 2, 1, Color("#80603f"))
	# ornières légères et gravier
	for i in 7:
		var x := int(PA.rnd(i, 3, 35) * T)
		var y := int(PA.rnd(i, 4, 35) * T)
		var n := 5 + int(PA.rnd(i, 5, 35) * 7.0)
		for k in n:
			img.set_pixel((x + k) % T, y, Color("#9c7648"))
			img.set_pixel((x + k) % T, (y + 1) % T, Color("#c9a878"))
	for i in 22:
		var x := int(PA.rnd(i, 6, 36) * T)
		var y := int(PA.rnd(i, 7, 36) * T)
		img.set_pixel(x, y, Color("#d6c8ae"))
		img.set_pixel(x, (y + 1) % T, Color("#86643f"))
	# quelques brins d'herbe qui repoussent
	for i in 3:
		var x := int(PA.rnd(i, 8, 37) * T)
		var y := int(PA.rnd(i, 9, 37) * T)
		img.set_pixel(x, y, Color("#6fa052"))
		img.set_pixel((x + 1) % T, (y + 1) % T, Color("#4f8a48"))
		img.set_pixel(x, (y + 1) % T, Color("#4f8a48"))
	return img


## Roche stratifiée : lits horizontaux ondulés d'épaisseur inégale, lèvre claire en haut de
## chaque lit, ombre en bas, fissures verticales, éclats et un peu de mousse sur les replats.
## Se raccorde à elle-même (les ondulations font un nombre entier de périodes).
static func _cliff() -> Image:
	var img := PA.new_image(T, T)
	var tones: Array[Color] = [Color("#9c948a"), Color("#aaa296"), Color("#8c847b"), Color("#b4aa9a"), Color("#a09484")]
	var bounds: Array[int] = [0, 9, 18, 30, 39]
	var n := bounds.size()
	for x in T:
		for y in T:
			var layer := n - 1
			for i in range(n - 1, -1, -1):
				if y >= _cliff_edge(bounds, i, x):
					layer = i
					break
			var top := _cliff_edge(bounds, layer, x)
			var nxt := (layer + 1) % n
			var bottom := _cliff_edge(bounds, nxt, x) + (T if nxt == 0 else 0) - 1
			var yy := y if y >= top else y + T
			var c := tones[layer % tones.size()]
			c = PA.shade(c, (PA.rnd(x, y, 61) - 0.5) * 0.12)
			if yy == top:
				c = PA.shade(c, 0.24)
			elif yy == top + 1:
				c = PA.shade(c, 0.1)
			elif yy == bottom:
				c = PA.shade(c, -0.34)
			elif yy == bottom - 1:
				c = PA.shade(c, -0.14)
			img.set_pixel(x, y, c)
	# fissures verticales, un peu décalées en descendant, qui s'arrêtent avant le bas du lit
	for layer in n:
		for j in 2:
			var cx := int(PA.rnd(layer, j, 62) * T)
			var top := bounds[layer]
			var height := bounds[(layer + 1) % n] + (T if layer == n - 1 else 0) - top
			var length := 3 + int(PA.rnd(layer, j, 63) * float(height - 3))
			for k in range(1, length):
				var px := posmod(cx + ((k + int(PA.rnd(layer, j, 64) * 3.0)) / 3) % 2, T)
				var py := posmod(top + k + 1, T)
				img.set_pixel(px, py, PA.shade(img.get_pixel(px, py), -0.38))
				var rx := posmod(px + 1, T)
				img.set_pixel(rx, py, PA.shade(img.get_pixel(rx, py), 0.1))
	# éclats, grains clairs et mousse
	for i in 26:
		var x := int(PA.rnd(i, 1, 65) * T)
		var y := int(PA.rnd(i, 2, 65) * T)
		img.set_pixel(x, y, PA.shade(img.get_pixel(x, y), -0.22 if i % 2 == 0 else 0.2))
	for i in 7:
		var layer := int(PA.rnd(i, 3, 65) * n) % n
		var mx := int(PA.rnd(i, 4, 65) * T)
		var my := posmod(_cliff_edge(bounds, layer, mx) + 1, T)
		for k in 2 + int(PA.rnd(i, 5, 65) * 3.0):
			img.set_pixel(posmod(mx + k, T), my, Color("#667f4e"))
	return img


static func _cliff_edge(bounds: Array[int], i: int, x: int) -> int:
	var a := sin(TAU * float(1 + i % 2) * float(x) / float(T) + float(i) * 1.7) * 1.7
	var b := sin(TAU * 3.0 * float(x) / float(T) + float(i) * 2.3) * 0.9
	return bounds[i] + roundi(a + b)


## Liseré d'herbe qui retombe sur le haut d'une falaise : 48 x 8 px, le bas est découpé.
static func _cliff_lip() -> Image:
	var img := PA.new_image(T, 8)
	for x in T:
		var ln := 3 + int(clampf(1.4 + 1.6 * sin(float(x) * 0.8) + PA.rnd(x, 0, 71) * 2.2, 0.0, 5.0))
		for y in mini(ln, 8):
			var c := Color("#4f9148")
			if y == 0:
				c = Color("#70ad52")
			elif y == ln - 1:
				c = Color("#2f6238")
			elif y >= ln - 3:
				c = Color("#33683d")
			elif PA.rnd(x, y, 72) < 0.18:
				c = Color("#5f9f4e")
			img.set_pixel(x, y, c)
	return img


## Marches d'une rampe : quatre marches de 12 px par motif (0,5 unité chacune).
## Nez clair, dessus, contremarche, ombre ; le sens de lecture est celui de la montée.
static func _steps() -> Image:
	var img := PA.new_image(T, T)
	for y in T:
		var r := y % 12
		var step := y / 12
		for x in T:
			var c := Color("#b8afa0")
			if r < 2:
				c = Color("#d6cdbb")
			elif r < 8:
				c = PA.shade(c, (PA.rnd(x, y, 81) - 0.5) * 0.1)
				if x == (step * 17 + 5) % T or x == (step * 29 + 31) % T:
					c = Color("#8f877c")
			elif r < 10:
				c = Color("#8f877c")
			else:
				c = Color("#615b57")
			img.set_pixel(x, y, c)
	return img


static func _stones(tones: Array, mortar: Color, sw: int, sh: int) -> Image:
	var img := PA.new_image(T, T)
	img.fill(mortar)
	var rows := T / sh
	var cols := T / sw
	for r in rows:
		var off := (sw / 2) if r % 2 == 1 else 0
		for c in cols:
			var base := Color.from_string(str(tones[int(PA.rnd(c, r, 41) * tones.size()) % tones.size()]), Color.GRAY)
			var x0 := c * sw + off
			var y0 := r * sh
			for y in range(1, sh):
				for x in range(1, sw):
					var corner := (x == 1 or x == sw - 1) and (y == 1 or y == sh - 1)
					if corner:
						continue
					var col := base
					if y == 1:
						col = PA.shade(base, 0.18)
					elif y == sh - 1 or x == sw - 1:
						col = PA.shade(base, -0.2)
					elif PA.rnd(x0 + x, y0 + y, 42) < 0.08:
						col = PA.shade(base, -0.1)
					img.set_pixel(posmod(x0 + x, T), y0 + y, col)
			# reflet en coin et fêlure sur une pierre sur trois
			img.set_pixel(posmod(x0 + 2, T), y0 + 2, PA.shade(base, 0.3))
			if PA.rnd(c, r, 43) < 0.34 and sw > 6 and sh > 5:
				var fx := 3 + int(PA.rnd(c, r, 44) * float(sw - 6))
				for k in mini(4, sh - 3):
					img.set_pixel(posmod(x0 + fx + (k / 2), T), y0 + 2 + k, PA.shade(base, -0.3))
	# mousse dans les joints
	for i in 9:
		var mx := int(PA.rnd(i, 1, 45) * cols) * sw
		var my := int(PA.rnd(i, 2, 45) * rows) * sh
		var moss := Color("#5f7d4c").lerp(mortar, 0.35)
		for k in 3 + int(PA.rnd(i, 3, 45) * 4.0):
			img.set_pixel(posmod(mx + k, T), posmod(my, T), moss)
		img.set_pixel(posmod(mx + 1, T), posmod(my, T), Color("#7c9a5c").lerp(mortar, 0.3))
	return img


static func _planks(base: Color, dark: Color, light: Color) -> Image:
	var img := PA.new_image(T, T)
	for r in 6:
		var y0 := r * 8
		var tone := base.lerp(dark, PA.rnd(r, 0, 51) * 0.3)
		PA.rect(img, 0, y0, T, 8, tone)
		PA.rect(img, 0, y0, T, 1, tone.lerp(light, 0.5))
		PA.rect(img, 0, y0 + 7, T, 1, dark)
		for i in 5:
			var x := int(PA.rnd(i, r, 52) * T)
			var y := y0 + 2 + int(PA.rnd(i, r, 53) * 4.0)
			var n := 3 + int(PA.rnd(i, r, 54) * 5.0)
			var c := tone.lerp(dark, 0.45) if i % 2 == 0 else tone.lerp(light, 0.35)
			for k in n:
				img.set_pixel((x + k) % T, y, c)
		var jx := (r * 19 + 7) % T
		PA.rect(img, jx, y0, 1, 7, dark)
		PA.px(img, (jx + 2) % T, y0 + 2, dark)
		PA.px(img, (jx + T - 2) % T, y0 + 5, dark)
		# clous de part et d'autre du joint, nœud du bois une planche sur deux
		PA.px(img, (jx + 3) % T, y0 + 4, light)
		PA.px(img, (jx + T - 3) % T, y0 + 3, light)
		if r % 2 == 0:
			var kx := 1 + (jx + 17 + r * 5) % (T - 6)
			PA.rect(img, kx, y0 + 3, 4, 2, tone.lerp(dark, 0.55))
			PA.rect(img, kx + 1, y0 + 3, 2, 1, dark)
			PA.px(img, kx - 1, y0 + 4, tone.lerp(light, 0.4))
			PA.px(img, kx + 4, y0 + 3, tone.lerp(light, 0.4))
	return img


static func _soil() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#5a4032"))
	for r in 6:
		var y0 := r * 8
		PA.rect(img, 0, y0 + 1, T, 2, Color("#6f5140"))
		PA.rect(img, 0, y0 + 3, T, 1, Color("#614636"))
		PA.rect(img, 0, y0 + 6, T, 1, Color("#463024"))
	_specks(img, 61, 70, Color("#7b5b47"))
	_specks(img, 62, 60, Color("#402b21"))
	# mottes, cailloux et jeunes pousses
	for i in 10:
		var x := int(PA.rnd(i, 1, 63) * (T - 3))
		var y := int(PA.rnd(i, 2, 63) * (T - 3))
		PA.rect(img, x, y, 3, 2, Color("#7d5c46"))
		PA.px(img, x, y, Color("#94705a"))
		PA.rect(img, x, y + 2, 3, 1, Color("#3a261c"))
	for i in 4:
		var x := int(PA.rnd(i, 3, 64) * (T - 2))
		var y := 1 + int(PA.rnd(i, 4, 64) * (T - 3))
		PA.px(img, x, y, Color("#8fbf5a"))
		PA.px(img, x + 1, y - 1, Color("#8fbf5a"))
		PA.px(img, x, y + 1, Color("#5f8a3c"))
	return img


static func _plaster(base: Color) -> Image:
	var img := PA.new_image(T, T)
	img.fill(base)
	_blotches(img, 71, 9, PA.shade(base, -0.07), 4.0, 9.0)
	_blotches(img, 72, 8, PA.shade(base, 0.12), 3.0, 7.0)
	_specks(img, 73, 40, PA.shade(base, -0.14))
	# fines lézardes et grain de l'enduit
	for i in 3:
		var x := int(PA.rnd(i, 1, 74) * T)
		var y := int(PA.rnd(i, 2, 74) * T)
		for k in 6 + int(PA.rnd(i, 3, 74) * 6.0):
			img.set_pixel(posmod(x, T), posmod(y + k, T), PA.shade(base, -0.24))
			if PA.rnd(i, k, 75) < 0.4:
				x += 1 if PA.rnd(k, i, 76) < 0.5 else -1
	_specks(img, 77, 30, PA.shade(base, 0.16))
	return img


static func _iron() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#3b3a47"))
	_blotches(img, 81, 8, Color("#33323e"), 4.0, 8.0)
	for y in range(4, T, 12):
		for x in range(4, T, 12):
			PA.px(img, x, y, Color("#5b5a6b"))
			PA.px(img, x, y + 1, Color("#25242e"))
	return img


static func _roof(kind: String) -> Image:
	var pal: Array = ROOFS.get(kind, ROOFS["rouge"])
	var tones: Array[Color] = []
	for s: Variant in pal:
		tones.append(Color.from_string(str(s), Color.GRAY))
	var img := PA.new_image(T, T)
	if kind == "chaume":
		img.fill(tones[0])
		for x in T:
			var y := 0
			while y < T:
				var n := 3 + int(PA.rnd(x, y, 91) * 7.0)
				var c: Color = tones[int(PA.rnd(x, y, 92) * 3.0) % 3]
				for k in n:
					if y + k < T:
						img.set_pixel(x, y + k, c)
				y += n
		for y in range(11, T, 12):
			PA.rect(img, 0, y, T, 1, tones[3])
			PA.rect(img, 0, (y + 1) % T, T, 1, tones[4])
		return img
	for r in 6:
		var y0 := r * 8
		var off := 6 if r % 2 == 1 else 0
		for c in 4:
			var tone: Color = tones[int(PA.rnd(c, r, 93) * 3.0) % 3]
			var x0 := c * 12 + off
			for y in 8:
				for x in 12:
					var col := tone
					if y == 0:
						col = tones[4].lerp(tone, 0.4)
					elif y == 7 or x == 11:
						col = tones[3]
					elif y == 6 and (x == 0 or x == 10):
						col = tones[3]
					img.set_pixel(posmod(x0 + x, T), y0 + y, col)
	return img


## Mur intérieur : 48 x 72 px, soit 2 unités de large sur 3 de haut.
static func _interior_wall() -> Image:
	var img := PA.new_image(T, 72)
	var plaster := Color("#d6c095")
	img.fill(plaster)
	_blotches(img, 101, 8, PA.shade(plaster, -0.08), 4.0, 8.0)
	_blotches(img, 102, 6, PA.shade(plaster, 0.1), 3.0, 6.0)
	# poutre haute
	PA.rect(img, 0, 0, T, 6, Color("#5a3d2b"))
	PA.rect(img, 0, 0, T, 1, Color("#7a5639"))
	PA.rect(img, 0, 5, T, 1, Color("#3d281c"))
	# colombage vertical
	PA.rect(img, 22, 6, 4, 38, Color("#5a3d2b"))
	PA.rect(img, 22, 6, 1, 38, Color("#7a5639"))
	# lambris
	PA.rect(img, 0, 44, T, 3, Color("#6a472e"))
	PA.rect(img, 0, 44, T, 1, Color("#8c623f"))
	for b in 6:
		var x0 := b * 8
		var tone := Color("#7a5335").lerp(Color("#63412a"), PA.rnd(b, 0, 103) * 0.5)
		PA.rect(img, x0, 47, 8, 25, tone)
		PA.rect(img, x0, 47, 1, 25, Color("#94683f"))
		PA.rect(img, x0 + 7, 47, 1, 25, Color("#4a301f"))
	PA.rect(img, 0, 68, T, 4, Color("#4a301f"))
	PA.rect(img, 0, 68, T, 1, Color("#6a472e"))
	return img


static func _fill_tiled(img: Image, tile: Image) -> void:
	var tw := tile.get_width()
	var th := tile.get_height()
	for y in img.get_height():
		for x in img.get_width():
			img.set_pixel(x, y, tile.get_pixel(x % tw, y % th))


static func _stone_base(img: Image, rows: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var tones := [Color("#8a8690"), Color("#7a7682"), Color("#98939c")]
	PA.rect(img, 0, h - rows, w, rows, Color("#4a4652"))
	for x0 in range(0, w, 8):
		var tone: Color = tones[int(PA.rnd(x0, 0, 111) * 3.0) % 3]
		PA.rect(img, x0 + 1, h - rows + 1, 7, rows - 1, tone)
		PA.rect(img, x0 + 1, h - rows + 1, 7, 1, PA.shade(tone, 0.18))
		PA.rect(img, x0 + 1, h - 1, 7, 1, PA.shade(tone, -0.2))


static func _timber_frame(img: Image, braces: bool) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var wood := Color("#5d3f2c")
	var wood_l := Color("#7d5a3d")
	var wood_d := Color("#3c281c")
	if braces:
		for k in 2:
			PA.line(img, 3 + k, h - 10, 13 + k, 5, wood)
			PA.line(img, w - 4 - k, h - 10, w - 14 - k, 5, wood)
	PA.rect(img, 0, 0, w, 4, wood)
	PA.rect(img, 0, 0, w, 1, wood_l)
	PA.rect(img, 0, 3, w, 1, wood_d)
	for x0: int in [0, w - 3]:
		PA.rect(img, x0, 0, 3, h - 7, wood)
		PA.rect(img, x0, 0, 1, h - 7, wood_l)
		PA.rect(img, x0 + 2, 4, 1, h - 11, wood_d)


## Façade avant d'une maison. Renvoie {"albedo": Image, "emission": Image}.
## door_x et windows sont en unités depuis le bord gauche ; door_x < 0 = pas de porte.
static func house_front(w_units: float, h_units: float, door_x: float, windows: Array, door_color: Color, lit: bool = true) -> Dictionary:
	var w := int(round(w_units * PPU))
	var h := int(round(h_units * PPU))
	var img := PA.new_image(w, h)
	var emi := PA.new_image(w, h)
	emi.fill(Color.BLACK)
	_fill_tiled(img, paint("plaster"))
	_stone_base(img, 8)
	_timber_frame(img, w >= 96)
	var frame := Color("#4a3122")
	# fenêtres rondes
	for wx_v: Variant in windows:
		var wx := float(wx_v) * PPU
		var wy := float(h) - 35.0
		PA.ellipse(img, wx, wy, 10.0, 10.0, frame)
		PA.ellipse(img, wx, wy, 9.0, 9.0, Color("#6e4c33"))
		for y in range(int(wy) - 9, int(wy) + 9):
			for x in range(int(wx) - 9, int(wx) + 9):
				var dx := x + 0.5 - wx
				var dy := y + 0.5 - wy
				var dist := sqrt(dx * dx + dy * dy)
				if dist > 7.5:
					continue
				var c := Color("#3a4666")
				if lit:
					c = Color("#ffe6a0").lerp(Color("#f0a44a"), clampf(dist / 7.5, 0.0, 1.0))
					if dy < -2.0:
						c = c.lerp(Color("#e88f3e"), 0.25)
					PA.px(emi, x, y, c)
				PA.px(img, x, y, c)
		var ix := int(wx)
		var iy := int(wy)
		PA.rect(img, ix - 8, iy, 16, 1, frame)
		PA.rect(img, ix, iy - 8, 1, 16, frame)
		PA.rect(emi, ix - 8, iy, 16, 1, Color.BLACK)
		PA.rect(emi, ix, iy - 8, 1, 16, Color.BLACK)
		# jardinière
		PA.rect(img, ix - 9, iy + 11, 18, 3, Color("#6e4c33"))
		PA.rect(img, ix - 9, iy + 13, 18, 1, frame)
		var blooms := [Color("#e86a7a"), Color("#f2d55c"), Color("#f4f0e2"), Color("#b98ae0")]
		for k in 6:
			PA.px(img, ix - 8 + k * 3, iy + 10, blooms[(k + int(wx)) % 4])
			PA.px(img, ix - 7 + k * 3, iy + 10, Color("#4f9148"))
	# porte ronde
	if door_x >= 0.0:
		var dx0 := door_x * PPU
		var dy0 := float(h) - 15.0
		PA.rect(img, int(dx0) - 14, h - 3, 28, 3, Color("#a8a3ac"))
		PA.rect(img, int(dx0) - 14, h - 3, 28, 1, Color("#c4bfc6"))
		PA.ellipse(img, dx0, dy0, 18.0, 18.0, frame)
		PA.ellipse(img, dx0, dy0, 17.0, 17.0, Color("#7d5a3d"))
		for y in range(int(dy0) - 16, h - 3):
			for x in range(int(dx0) - 16, int(dx0) + 16):
				var ddx := x + 0.5 - dx0
				var ddy := y + 0.5 - dy0
				if ddx * ddx + ddy * ddy > 15.0 * 15.0:
					continue
				var c := door_color
				if posmod(x - int(dx0), 6) == 0:
					c = PA.shade(door_color, -0.28)
				elif ddx > 8.0:
					c = PA.shade(door_color, -0.14)
				elif ddx < -9.0 and ddy < 0.0:
					c = PA.shade(door_color, 0.16)
				PA.px(img, x, y, c)
		# ferrures et poignée centrale
		var idx := int(dx0)
		var idy := int(dy0)
		PA.rect(img, idx - 13, idy - 7, 9, 2, Color("#2f2c38"))
		PA.rect(img, idx - 13, idy + 5, 9, 2, Color("#2f2c38"))
		PA.rect(img, idx - 1, idy - 1, 3, 3, Color("#d9b04a"))
		PA.px(img, idx - 1, idy - 1, Color("#fff0b0"))
		PA.px(img, idx + 1, idy + 1, Color("#8e6a22"))
	return {"albedo": img, "emission": emi}


## Mur latéral ou arrière : crépi, soubassement de pierre, colombage.
static func house_side(w_units: float, h_units: float) -> Image:
	var img := PA.new_image(int(round(w_units * PPU)), int(round(h_units * PPU)))
	_fill_tiled(img, paint("plaster"))
	_stone_base(img, 8)
	_timber_frame(img, false)
	return img


## Tapis à bordure, peint à la taille demandée.
static func rug(w_units: float, d_units: float, main: Color, border: Color) -> Image:
	var w := int(round(w_units * PPU))
	var h := int(round(d_units * PPU))
	var img := PA.new_image(w, h)
	img.fill(border)
	PA.rect(img, 2, 2, w - 4, h - 4, PA.shade(border, 0.25))
	PA.rect(img, 4, 4, w - 8, h - 8, main)
	for y in range(6, h - 6):
		for x in range(6, w - 6):
			if (x + y) % 8 == 0 or (x - y + 800) % 8 == 0:
				img.set_pixel(x, y, PA.shade(main, -0.18))
	for x in range(1, w - 1, 3):
		PA.px(img, x, 0, PA.shade(border, 0.4))
		PA.px(img, x, h - 1, PA.shade(border, 0.4))
	return img
