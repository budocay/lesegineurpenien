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
		"humus": return _humus()
		"plaster": return _plaster(Color("#e2cfa6"))
		"brick": return _stones(["#a85a44", "#9a4e3c", "#b56a50", "#a0604a"], Color("#6d5a50"), 12, 6)
		"stone": return _stones(["#85828e", "#928f9a", "#777482", "#8d8880"], Color("#45414c"), 16, 12)
		"iron": return _iron()
		"cliff": return _cliff()
		"cliff_lip": return _cliff_lip()
		"steps": return _steps()
		"interior_wall": return _interior_wall()
		"basalt": return _basalt()
		"rock_face": return _rock_strata(["#9d968f", "#8b857f", "#aaa398", "#7c7773", "#b6ae9f"], 301, 0)
		"rock_face_moss": return _rock_strata(["#8e9078", "#7b806a", "#9aa07e", "#6a7060", "#a8b088"], 302, 1)
		"rock_face_mud": return _rock_strata(["#8a7e6a", "#766b5c", "#988b73", "#645a50", "#a49680"], 303, 1)
		"rock_face_dark": return _rock_strata(["#4a4048", "#3b323c", "#58494d", "#2c252f", "#6a5254"], 304, 2)
		"rock_face_ashlar": return _ashlar()
	if kind.begins_with("roof_"):
		return _roof(kind.trim_prefix("roof_"))
	# styles d'architecture ajoutés (elfe) : chargés à l'usage pour éviter une référence circulaire
	var elven: GDScript = load("res://src/gfx/elven_painter.gd")
	if elven.has_tile(kind):
		return elven.paint_tile(kind)
	# sols des arènes de combat par lieu (parquet, pavés mouillés, neige...)
	var arena: GDScript = load("res://src/gfx/arena_painter.gd")
	if arena.has_tile(kind):
		return arena.paint_tile(kind)
	var dwarven: GDScript = load("res://src/gfx/dwarven_painter.gd")
	if dwarven.has_tile(kind):
		return dwarven.paint_tile(kind)
	var rider: GDScript = load("res://src/gfx/rider_painter.gd")
	if rider.has_tile(kind):
		return rider.paint_tile(kind)
	var gouda: GDScript = load("res://src/gfx/gouda_painter.gd")
	if gouda.has_tile(kind):
		return gouda.paint_tile(kind)
	var interior: GDScript = load("res://src/gfx/interior_painter.gd")
	if interior.has_tile(kind):
		return interior.paint_tile(kind)
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
	_blotches(img, 11, 9, dark.lerp(base, 0.35), 6.0, 13.0)
	_blotches(img, 14, 6, dark, 3.0, 5.0)
	_blotches(img, 12, 6, light, 4.0, 8.0)
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


## Sous-bois : terreau feuillu, mousse, feuilles mortes et aiguilles. Se lit comme un sol
## de forêt, pas comme un trou sombre.
static func _humus() -> Image:
	var img := PA.new_image(T, T)
	var base := Color("#4d4a2e")
	img.fill(base)
	_blotches(img, 71, 10, Color("#5c5a34"), 5.0, 11.0)
	_blotches(img, 72, 8, Color("#3e3a26"), 3.0, 7.0)
	_blotches(img, 73, 6, Color("#4a6a38"), 3.0, 6.0)   # mousse
	_specks(img, 74, 60, Color("#6a6238"))
	_specks(img, 75, 40, Color("#352f20"))
	var leaves := [Color("#b8642c"), Color("#d08a3a"), Color("#8a4a28"), Color("#c8a040"), Color("#a8502c")]
	for i in 16:
		var x := int(PA.rnd(i, 1, 76) * (T - 3))
		var y := int(PA.rnd(i, 2, 76) * (T - 3))
		var c: Color = leaves[i % leaves.size()]
		PA.rect(img, x, y, 3, 2, c)
		PA.px(img, x, y, PA.shade(c, 0.25))
		PA.rect(img, x + 1, y + 2, 2, 1, PA.shade(c, -0.35))
	for i in 12:
		var x := int(PA.rnd(i, 3, 77) * (T - 5))
		var y := int(PA.rnd(i, 4, 77) * (T - 3))
		for k in 4:
			PA.px(img, x + k, y + (k % 2), Color("#8a7a4a"))
	for i in 5:
		var x := int(PA.rnd(i, 5, 78) * (T - 2))
		var y := 1 + int(PA.rnd(i, 6, 78) * (T - 3))
		PA.px(img, x, y, Color("#7fae52"))
		PA.px(img, x + 1, y - 1, Color("#7fae52"))
		PA.px(img, x, y + 1, Color("#4f7a3a"))
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
	var ardoise := kind == "ardoise"
	for r in 6:
		var y0 := r * 8
		var off := 6 if r % 2 == 1 else 0
		for c in 5:
			var tone: Color = tones[int(PA.rnd(c, r, 93) * 3.0) % 3]
			# quelques tuiles plus vieilles ou plus claires, une moussue de temps en temps
			var age := PA.rnd(c, r, 94)
			if age < 0.15:
				tone = tone.darkened(0.12)
			elif age > 0.88:
				tone = tone.lightened(0.1)
			var x0 := c * 12 + off - 6
			for y in 8:
				for x in 12:
					var col := tone
					# bas arrondi : les coins du bas laissent voir l'ombre de la rangée dessous
					var rounded := y >= 6 and (x == 0 or x == 11 or (ardoise and (x == 1 or x == 10) and y == 7))
					if y == 0:
						col = tones[4].lerp(tone, 0.45)
					elif y == 1:
						col = tone.lerp(tones[4], 0.2)
					elif rounded:
						col = tones[3]
					elif y == 7 or x == 11:
						col = tones[3]
					elif y == 6:
						col = tone.lerp(tones[3], 0.45)
					elif x == 0:
						col = tone.lerp(tones[3], 0.3)
					elif x == 1 and y < 6:
						col = tone.lerp(tones[4], 0.18)
					elif PA.rnd(x0 + x, y0 + y, 95) < 0.07:
						col = tone.darkened(0.1)
					img.set_pixel(posmod(x0 + x, T), y0 + y, col)
			if age > 0.55 and age < 0.64:
				for k in 5:
					img.set_pixel(posmod(x0 + 2 + k * 2, T), y0 + 2 + (k % 2), Color("#6f9a50") if kind != "vert" else Color("#8ab05c"))
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
	# grain des poutres et des lambris, clous, coulures de crépi, plinthe moulurée
	for i in 14:
		var gx := int(PA.rnd(i, 1, 104) * T)
		PA.rect(img, gx, 2, 3, 1, Color("#4a3224"))
		PA.rect(img, (gx + 5) % T, 4, 2, 1, Color("#7a5639"))
	for b in 6:
		for k in 4:
			var yy := 50 + int(PA.rnd(b, k, 105) * 16.0)
			PA.px(img, b * 8 + 3 + int(PA.rnd(b, k, 106) * 3.0), yy, Color("#5a3a24"))
			PA.px(img, b * 8 + 4, yy + 1, Color("#8c623f"))
		PA.px(img, b * 8 + 3, 49, Color("#2f2c38"))
		PA.px(img, b * 8 + 3, 66, Color("#2f2c38"))
	for i in 5:
		var sx := 2 + int(PA.rnd(i, 2, 107) * 40.0)
		if sx > 20 and sx < 28:
			continue
		for k in 4 + int(PA.rnd(i, 3, 107) * 8.0):
			img.set_pixel(sx, 7 + k, img.get_pixel(sx, 7 + k).darkened(0.09))
	PA.rect(img, 22, 6, 1, 38, Color("#7a5639"))
	PA.rect(img, 25, 6, 1, 38, Color("#3d281c"))
	return img


## Paroi de roche stratifiée, répétable (96 x 96 px = 4 x 4 unités) : bancs d'épaisseurs
## inégales dont la limite fait des décrochements, blocs séparés par des joints, lèvre
## claire au sommet de chaque banc et ombre dessous, fissures, éclats.
## extra : 0 rien, 1 mousse sur les lèvres, 2 fissures rougeoyantes (forge).
static func _rock_strata(pal_src: Array, sd: int, extra: int) -> Image:
	var size := 96
	var pal: Array[Color] = []
	for q: Variant in pal_src:
		pal.append(Color.from_string(str(q), Color.GRAY))
	var img := PA.new_image(size, size)
	var thick: Array[int] = [11, 7, 15, 9, 6, 13, 8, 12, 15]
	var starts: Array[int] = []
	var acc := 0
	for t in thick:
		starts.append(acc)
		acc += t
	# par banc : ton, décalages de la limite haute (en paliers), joints verticaux
	var layer_tone: Array[Color] = []
	var jogs: Array = []     # [x, dy] : à partir de x, la limite haute descend de dy
	var joints: Array = []
	for i in thick.size():
		layer_tone.append(pal[int(PA.rnd(i, 5, sd) * 3.0) % 3])
		var jl: Array = []
		var x0 := int(PA.rnd(i, 20, sd) * 30.0)
		for k in 3:
			jl.append([x0 + k * 32 + int(PA.rnd(i, 21 + k, sd) * 10.0), int(PA.rnd(i, 30 + k, sd) * 3.0) - 1])
		jogs.append(jl)
		var js: Array[int] = []
		var n := 3 + int(PA.rnd(i, 6, sd) * 2.0)
		for j in n:
			js.append(int((float(j) + PA.rnd(i, j + 10, sd) * 0.6) * float(size) / float(n)))
		joints.append(js)
	for x in size:
		var tops: Array[int] = []
		for i in thick.size():
			var off := 0
			for jg: Array in jogs[i]:
				if x >= int(jg[0]):
					off = int(jg[1])
			tops.append(starts[i] + off)
		for y in size:
			var li := thick.size() - 1
			for i in thick.size():
				if tops[i] <= y:
					li = i
			var rel := y - tops[li]
			if rel < 0:
				rel += size
			var nxt := tops[(li + 1) % thick.size()]
			var th := nxt - tops[li]
			if th <= 0:
				th += size
			var c: Color = layer_tone[li]
			var block := 0
			for jx: int in joints[li]:
				if x >= jx:
					block += 1
			c = c.lerp(pal[(li * 2 + block) % 3], 0.55)
			if rel == 0:
				c = pal[4]
				if extra == 1 and PA.rnd(x, li, sd + 3) < 0.6:
					c = Color("#7fa05a") if sd == 302 else Color("#8a9a5a")
			elif rel == 1:
				c = c.lerp(pal[4], 0.35)
			elif rel >= th - 2:
				c = pal[3] if rel == th - 1 else c.lerp(pal[3], 0.55)
			var g := PA.rnd(x, y, sd)
			if g < 0.1:
				c = PA.shade(c, -0.09)
			elif g > 0.94:
				c = PA.shade(c, 0.1)
			img.set_pixel(x, y, c)
	for li in thick.size():
		for jx: int in joints[li]:
			for k in range(2, thick[li] - 2):
				var y := posmod(starts[li] + k, size)
				img.set_pixel(jx, y, pal[3])
				img.set_pixel((jx + 1) % size, y, PA.shade(layer_tone[li], 0.1))
	for i in 9:
		var cx := int(PA.rnd(i, 70, sd) * size)
		var cy := int(PA.rnd(i, 71, sd) * size)
		var len := 5 + int(PA.rnd(i, 72, sd) * 9.0)
		for k in len:
			var x := posmod(cx + int(sin(float(k) * 1.1 + float(i)) * 1.6), size)
			var y := posmod(cy + k, size)
			img.set_pixel(x, y, Color("#e0702c") if extra == 2 and k % 3 != 2 else PA.shade(pal[3], -0.2))
	return img


## Dalles de basalte sombre fendues de veines de braise (sol de la forge).
static func _basalt() -> Image:
	var img := _stones(["#3f3a44", "#4a444e", "#35303a", "#524a50"], Color("#17121a"), 24, 16)
	for i in 14:
		var x := int(PA.rnd(i, 1, 410) * T)
		var y := int(PA.rnd(i, 2, 410) * T)
		for k in 3 + int(PA.rnd(i, 3, 410) * 4.0):
			PA.px(img, (x + k) % T, (y + (k % 2)) % T, Color("#d8602a") if k % 3 != 2 else Color("#8a2e1c"))
	return img


## Mur d'appareil : grandes pierres taillées bien jointes (arène de la place).
static func _ashlar() -> Image:
	var img := _stones(["#a39a8e", "#b0a698", "#948c82", "#bab0a0"], Color("#5a5148"), 24, 12)
	for x in T:
		PA.px(img, x, 0, Color("#d0c6b4"))
	return img


static func _fill_tiled(img: Image, tile: Image) -> void:
	var tw := tile.get_width()
	var th := tile.get_height()
	for y in img.get_height():
		for x in img.get_width():
			img.set_pixel(x, y, tile.get_pixel(x % tw, y % th))


const PLASTERS := ["#e2cfa6", "#dccaa0", "#e7d4b2", "#d8c8a2"]


## Soubassement de pierres inégales, mousse au pied.
static func _stone_base(img: Image, rows: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var tones := [Color("#8a8690"), Color("#7a7682"), Color("#98939c"), Color("#9a9486")]
	PA.rect(img, 0, h - rows, w, rows, Color("#4a4652"))
	var x0 := 0
	var i := 0
	while x0 < w:
		var bw := 6 + int(PA.rnd(i, 0, 111) * 6.0)
		var tone: Color = tones[int(PA.rnd(i, 1, 111) * 4.0) % 4]
		bw = mini(bw, w - x0)
		var split := rows > 6 and PA.rnd(i, 2, 111) < 0.4
		var bh := rows - 1 if not split else (rows - 1) / 2
		PA.rect(img, x0 + 1, h - rows + 1, bw - 1, bh, tone)
		PA.rect(img, x0 + 1, h - rows + 1, bw - 1, 1, PA.shade(tone, 0.2))
		PA.rect(img, x0 + bw - 1, h - rows + 1, 1, bh, PA.shade(tone, -0.2))
		if split:
			var t2: Color = tones[int(PA.rnd(i, 3, 111) * 4.0) % 4]
			PA.rect(img, x0 + 1, h - rows + bh + 2, bw - 1, rows - bh - 3, t2)
			PA.rect(img, x0 + 1, h - rows + bh + 2, bw - 1, 1, PA.shade(t2, 0.2))
		PA.rect(img, x0 + 1, h - 1, bw - 1, 1, PA.shade(tone, -0.3))
		if PA.rnd(i, 4, 111) < 0.3:
			PA.px(img, x0 + 2 + int(PA.rnd(i, 5, 111) * 3.0), h - rows + 2, Color("#6f9a50"))
		x0 += bw
		i += 1


## Chaînage d'angle : pierres de taille alternées sur toute la hauteur donnée.
static func _quoins(img: Image, left: bool, top: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var y := h - 9
	var k := 0
	while y > top:
		var bh := 7 if k % 2 == 0 else 6
		var bw := 9 if k % 2 == 0 else 6
		var x0 := 0 if left else w - bw
		var tone := Color("#a8a29a") if k % 2 == 0 else Color("#968f88")
		PA.rect(img, x0, y - bh + 1, bw, bh, Color("#4e4a48"))
		PA.rect(img, x0 + 1, y - bh + 2, bw - 2, bh - 2, tone)
		PA.rect(img, x0 + 1, y - bh + 2, bw - 2, 1, PA.shade(tone, 0.22))
		PA.rect(img, x0 + 1, y, bw - 2, 0, tone)
		PA.px(img, x0 + (bw - 2 if left else 1), y - bh + 3, PA.shade(tone, -0.2))
		y -= bh
		k += 1


static func _timber_frame(img: Image, braces: bool, xs: Array, sd: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var wood := Color("#5d3f2c")
	var wood_l := Color("#7d5a3d")
	var wood_d := Color("#3c281c")
	if braces:
		for k in 2:
			PA.line(img, 3 + k, h - 10, 13 + k, 6, wood)
			PA.line(img, w - 4 - k, h - 10, w - 14 - k, 6, wood)
			PA.px(img, 3 + k, h - 10, wood_l)
	# poteaux intermédiaires (entre les ouvertures)
	for sx: Variant in xs:
		var x0 := int(sx) - 1
		PA.rect(img, x0, 4, 3, h - 13, wood)
		PA.rect(img, x0, 4, 1, h - 13, wood_l)
		PA.rect(img, x0 + 2, 4, 1, h - 13, wood_d)
		for k in 3:
			PA.px(img, x0 + 1, 8 + k * 14, wood_d)
	# sablière : poutre haute, tête de chevrons qui dépassent, grain du bois
	PA.rect(img, 0, 0, w, 5, wood)
	PA.rect(img, 0, 0, w, 1, wood_l)
	PA.rect(img, 0, 4, w, 1, wood_d)
	for x in range(2, w - 2, 9):
		PA.rect(img, x, 1, 5, 2, wood_l if PA.rnd(x, 1, sd) < 0.5 else wood)
		PA.px(img, x + 4, 2, wood_d)
	for x0: int in [0, w - 3]:
		PA.rect(img, x0, 0, 3, h - 7, wood)
		PA.rect(img, x0, 0, 1, h - 7, wood_l)
		PA.rect(img, x0 + 2, 4, 1, h - 11, wood_d)


static func _weather(img: Image, sd: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	# coulures sous la sablière
	for i in w / 7:
		var x := 4 + int(PA.rnd(i, 1, sd) * float(w - 8))
		var n := 4 + int(PA.rnd(i, 2, sd) * 10.0)
		for k in n:
			var c := img.get_pixel(x, 6 + k)
			img.set_pixel(x, 6 + k, c.darkened(0.1 * (1.0 - float(k) / float(n))))
	# ombre portée du toit : le haut du mur s'assombrit
	for y in range(5, 14):
		var a := 0.22 * (1.0 - float(y - 5) / 9.0)
		for x in w:
			img.set_pixel(x, y, img.get_pixel(x, y).darkened(a))


## Ouverture ronde. side_l / side_r : place pour des volets de ce côté.
static func _window(img: Image, emi: Image, wx: float, wy: float, lit: bool, shutter: Color, side_l: bool, side_r: bool, sd: int) -> void:
	var frame := Color("#4a3122")
	var ix := int(wx)
	var iy := int(wy)
	# volets : planches verticales, ferrure, fentes
	for side in 2:
		if (side == 0 and not side_l) or (side == 1 and not side_r):
			continue
		var x0 := ix - 15 if side == 0 else ix + 10
		PA.rect(img, x0, iy - 9, 5, 19, PA.shade(shutter, -0.35))
		PA.rect(img, x0 + 1, iy - 8, 3, 17, shutter)
		PA.rect(img, x0 + 1, iy - 8, 1, 17, PA.shade(shutter, 0.2))
		for k in 4:
			PA.px(img, x0 + 2, iy - 6 + k * 4, PA.shade(shutter, -0.3))
		PA.rect(img, x0 if side == 0 else x0 + 3, iy - 6, 2, 1, Color("#2f2c38"))
		PA.rect(img, x0 if side == 0 else x0 + 3, iy + 5, 2, 1, Color("#2f2c38"))
	PA.ellipse(img, wx, wy, 10.5, 10.5, frame)
	PA.ellipse(img, wx, wy, 9.5, 9.5, Color("#7a5639"))
	for y in range(iy - 9, iy + 9):
		for x in range(ix - 9, ix + 9):
			var dx := x + 0.5 - wx
			var dy := y + 0.5 - wy
			var dist := sqrt(dx * dx + dy * dy)
			if dist > 7.8:
				continue
			var c := Color("#3a4666")
			if lit:
				c = Color("#ffe6a0").lerp(Color("#f0a44a"), clampf(dist / 7.8, 0.0, 1.0))
				if dy < -2.0:
					c = c.lerp(Color("#e88f3e"), 0.25)
				PA.px(emi, x, y, c)
			elif dx + dy < -4.0:
				c = Color("#6a7aa0")   # reflet du ciel sur la vitre éteinte
			PA.px(img, x, y, c)
	PA.rect(img, ix - 8, iy, 16, 1, frame)
	PA.rect(img, ix, iy - 8, 1, 16, frame)
	PA.rect(emi, ix - 8, iy, 16, 1, Color.BLACK)
	PA.rect(emi, ix, iy - 8, 1, 16, Color.BLACK)
	# appui de pierre, jardinière fleurie
	PA.rect(img, ix - 11, iy + 10, 22, 2, Color("#a8a39c"))
	PA.rect(img, ix - 11, iy + 10, 22, 1, Color("#cdc7bd"))
	PA.rect(img, ix - 9, iy + 12, 18, 4, Color("#6e4c33"))
	PA.rect(img, ix - 9, iy + 12, 18, 1, Color("#8c6644"))
	PA.rect(img, ix - 9, iy + 15, 18, 1, frame)
	for k in 5:
		PA.px(img, ix - 7 + k * 4, iy + 13, frame)
	var blooms := [Color("#e86a7a"), Color("#f2d55c"), Color("#f4f0e2"), Color("#b98ae0")]
	for k in 7:
		var bx := ix - 8 + k * 2 + int(PA.rnd(k, 1, sd) * 1.5)
		PA.px(img, bx, iy + 11, Color("#3f7d43"))
		PA.px(img, bx, iy + 10, Color("#4f9148"))
		var c: Color = blooms[(k + sd) % 4]
		PA.px(img, bx, iy + 9, c)
		if k % 2 == 0:
			PA.px(img, bx + 1, iy + 10, PA.shade(c, -0.2))
	# retombées de feuilles
	PA.px(img, ix - 9, iy + 16, Color("#4f9148"))
	PA.px(img, ix + 8, iy + 16, Color("#4f9148"))


static func _door(img: Image, dx0: float, door_color: Color, h: int) -> void:
	# porte et arc à l'échelle des personnages (planches de 72 px à 40 px par unité) :
	# rayon 24 px, soit une porte de près de deux unités sous son arc
	var frame := Color("#4a3122")
	var rr := 24.0
	var dy0 := float(h) - 21.0
	# marches
	PA.rect(img, int(dx0) - 23, h - 2, 46, 2, Color("#8a8590"))
	PA.rect(img, int(dx0) - 21, h - 4, 42, 2, Color("#a8a3ac"))
	PA.rect(img, int(dx0) - 21, h - 4, 42, 1, Color("#cdc7d0"))
	# arc de pierre : claveaux
	for y in range(int(dy0) - 30, h - 3):
		for x in range(int(dx0) - 30, int(dx0) + 30):
			var ddx := x + 0.5 - dx0
			var ddy := y + 0.5 - dy0
			var r := sqrt(ddx * ddx + ddy * ddy)
			if r > rr and r < rr + 5.0 and ddy < 8.0:
				var ang := atan2(ddy, ddx)
				var seg := int(floor(ang / (PI / 14.0)))
				var tone := Color("#a29c94") if seg % 2 == 0 else Color("#8e8880")
				if r < rr + 1.0:
					tone = PA.shade(tone, -0.25)
				PA.px(img, x, y, tone)
	PA.ellipse(img, dx0, dy0, rr, rr, frame)
	PA.ellipse(img, dx0, dy0, rr - 1.0, rr - 1.0, Color("#7d5a3d"))
	for y in range(int(dy0 - rr), h - 4):
		for x in range(int(dx0 - rr), int(dx0 + rr)):
			var ddx := x + 0.5 - dx0
			var ddy := y + 0.5 - dy0
			if ddx * ddx + ddy * ddy > (rr - 3.0) * (rr - 3.0):
				continue
			var c := door_color
			if posmod(x - int(dx0), 7) == 0:
				c = PA.shade(door_color, -0.28)
			elif posmod(x - int(dx0), 7) == 1:
				c = PA.shade(door_color, 0.1)
			elif ddx > 11.0:
				c = PA.shade(door_color, -0.14)
			elif ddx < -12.0 and ddy < 0.0:
				c = PA.shade(door_color, 0.16)
			PA.px(img, x, y, c)
	var idx := int(dx0)
	var idy := int(dy0)
	# ferrures, serrure, heurtoir
	PA.rect(img, idx - 21, idy - 9, 15, 2, Color("#2f2c38"))
	PA.rect(img, idx - 21, idy + 8, 15, 2, Color("#2f2c38"))
	PA.px(img, idx - 21, idy - 9, Color("#6a6878"))
	PA.rect(img, idx + 6, idy + 1, 3, 4, Color("#2f2c38"))
	PA.rect(img, idx + 6, idy + 1, 3, 1, Color("#d9b04a"))
	PA.ellipse(img, float(idx) - 1.0, float(idy) - 3.0, 2.6, 2.6, Color("#d9b04a"))
	PA.ellipse(img, float(idx) - 1.0, float(idy) - 3.0, 1.4, 1.4, Color("#5a3d22"))
	PA.px(img, idx - 3, idy - 5, Color("#fff0b0"))


## Lierre : une vigne qui monte depuis le pied d'un angle, feuilles à deux tons.
static func _ivy(img: Image, left: bool, sd: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var x := 3.0 if left else float(w - 4)
	var y := float(h - 6)
	var dir := 1.0 if left else -1.0
	var top := float(h) * (0.25 + PA.rnd(1, 1, sd) * 0.3)
	var i := 0
	while y > top:
		x += dir * (PA.rnd(i, 3, sd) * 1.6 - 0.5)
		x = clampf(x, 2.0, float(w) - 3.0)
		y -= 1.0 + PA.rnd(i, 4, sd) * 0.6
		PA.px(img, int(x), int(y), Color("#2f5a34"))
		if i % 2 == 0:
			var lx := int(x) + (1 if PA.rnd(i, 5, sd) < 0.5 else -2)
			var c := Color("#3f7d43") if PA.rnd(i, 6, sd) < 0.5 else Color("#5f9a4c")
			PA.rect(img, lx, int(y), 3, 2, c)
			PA.px(img, lx, int(y), PA.shade(c, 0.25))
			PA.px(img, lx + 2, int(y) + 1, PA.shade(c, -0.3))
		i += 1


## Façade avant d'une maison. Renvoie {"albedo": Image, "emission": Image}.
## door_x et windows sont en unités depuis le bord gauche ; door_x < 0 = pas de porte.
## Chaque façade a son crépi, ses volets, son lierre (tirés de ses dimensions).
static func house_front(w_units: float, h_units: float, door_x: float, windows: Array, door_color: Color, lit: bool = true) -> Dictionary:
	var w := int(round(w_units * PPU))
	var h := int(round(h_units * PPU))
	var sd := int(w_units * 131.0 + h_units * 17.0 + door_x * 29.0 + float(windows.size()) * 7.0 + 500.0)
	var img := PA.new_image(w, h)
	var emi := PA.new_image(w, h)
	emi.fill(Color.BLACK)
	_fill_tiled(img, _plaster(Color.from_string(PLASTERS[sd % 4], Color("#e2cfa6"))))
	# ouvertures : x en pixels, triées (fenêtres et porte), pour placer les poteaux entre
	var spots: Array[float] = []
	for wx_v: Variant in windows:
		spots.append(float(wx_v) * PPU)
	if door_x >= 0.0:
		spots.append(door_x * PPU)
	spots.sort()
	var posts: Array[int] = []
	for k in range(spots.size() - 1):
		if spots[k + 1] - spots[k] >= 44.0:
			posts.append(int((spots[k] + spots[k + 1]) * 0.5))
	_weather(img, sd)
	_stone_base(img, 9)
	_timber_frame(img, w >= 96, posts, sd)
	_quoins(img, true, h - 34)
	_quoins(img, false, h - 34)
	var shutter := PA.shade(door_color, 0.0).lerp(Color("#3f6a8a"), 0.35)
	for wx_v: Variant in windows:
		var wx := float(wx_v) * PPU
		var left_ok := true
		var right_ok := true
		for s in spots:
			if s != wx and absf(s - wx) < 32.0:
				if s < wx:
					left_ok = false
				else:
					right_ok = false
		if wx < 20.0:
			left_ok = false
		if wx > float(w) - 20.0:
			right_ok = false
		_window(img, emi, wx, float(h) - 35.0, lit, shutter, left_ok, right_ok, sd)
	if door_x >= 0.0:
		_door(img, door_x * PPU, door_color, h)
	if sd % 3 == 0:
		_ivy(img, sd % 2 == 0, sd)
	return {"albedo": img, "emission": emi}


## Mur latéral ou arrière : crépi, soubassement de pierre, colombage, coulures.
static func house_side(w_units: float, h_units: float) -> Image:
	var img := PA.new_image(int(round(w_units * PPU)), int(round(h_units * PPU)))
	var sd := int(w_units * 97.0 + h_units * 13.0)
	_fill_tiled(img, _plaster(Color.from_string(PLASTERS[sd % 4], Color("#e2cfa6"))))
	_weather(img, sd)
	_stone_base(img, 9)
	_timber_frame(img, false, [int(img.get_width() / 2)] if img.get_width() > 90 else [], sd)
	_quoins(img, true, img.get_height() - 30)
	_quoins(img, false, img.get_height() - 30)
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
