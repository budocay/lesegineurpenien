extends RefCounted
## Peint les textures des maisons de village : façades, pignons, toits, lucarnes, enseignes.
## Chaque maison a sa propre « variante » (voir house_builder.gd : spec) ; ici on ne fait que dessiner.
## Densité : 24 pixels par unité monde. Lumière d'en haut à gauche, contours foncés colorés.

const PA = preload("res://src/gfx/pixel_art.gd")
const TP = preload("res://src/gfx/tile_painter.gd")
const PPU := 24

const WOOD := Color("#4a3122")
const WOOD_L := Color("#7a5639")
const WOOD_D := Color("#2c1c14")
const IRON := Color("#2f2c38")

## Palettes de toit : 5 tons (clair, moyen, foncé, ombre, éclat).
const ROOF_PAL := {
	"rouge": ["#a8523c", "#964634", "#b96247", "#5f2b28", "#cf7a56"],
	"vert": ["#5f7d4c", "#536f44", "#6d8c56", "#2f4232", "#86a468"],
	"ardoise": ["#5c6684", "#4f5874", "#6b7594", "#30364e", "#8690ad"],
	"chaume": ["#c2a25a", "#b3924c", "#cfb06a", "#7c6234", "#e2c884"],
	"herbe": ["#62c234", "#4cae2e", "#8ce04e", "#1f6a30", "#d0f478"],
}


# ------------------------------------------------------------------ outils

## Bruit de valeur lissé dans [0, 1[ : taches douces qui cassent la répétition des motifs.
static func vnoise(x: float, y: float, s: int, cell: float) -> float:
	var gx := x / cell
	var gy := y / cell
	var ix := int(floor(gx))
	var iy := int(floor(gy))
	var fx := gx - float(ix)
	var fy := gy - float(iy)
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a := PA.rnd(ix, iy, s)
	var b := PA.rnd(ix + 1, iy, s)
	var c := PA.rnd(ix, iy + 1, s)
	var d := PA.rnd(ix + 1, iy + 1, s)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


## Même bruit pour toute une image d'un coup (grille calculée une fois, interpolée ensuite) : bien plus rapide.
static func noise_map(w: int, h: int, s: int, cell: float) -> PackedFloat32Array:
	var gw := int(ceil(float(w) / cell)) + 2
	var gh := int(ceil(float(h) / cell)) + 2
	var grid := PackedFloat32Array()
	grid.resize(gw * gh)
	for gy in gh:
		for gx in gw:
			grid[gy * gw + gx] = PA.rnd(gx, gy, s)
	var out := PackedFloat32Array()
	out.resize(w * h)
	var inv := 1.0 / cell
	for y in h:
		var gyf := float(y) * inv
		var iy := int(gyf)
		var fy := gyf - float(iy)
		fy = fy * fy * (3.0 - 2.0 * fy)
		var row0 := iy * gw
		var row1 := row0 + gw
		for x in w:
			var gxf := float(x) * inv
			var ix := int(gxf)
			var fx := gxf - float(ix)
			fx = fx * fx * (3.0 - 2.0 * fx)
			var a := lerpf(grid[row0 + ix], grid[row0 + ix + 1], fx)
			var b := lerpf(grid[row1 + ix], grid[row1 + ix + 1], fx)
			out[y * w + x] = lerpf(a, b, fy)
	return out


static func col(hex: Variant) -> Color:
	return Color.from_string(str(hex), Color.GRAY)


## Poutre de bois : arête claire en haut à gauche, ombre en bas à droite, quelques fibres.
static func timber(img: Image, x: int, y: int, w: int, h: int, sd: int) -> void:
	PA.rect(img, x, y, w, h, WOOD)
	if w >= h:
		PA.rect(img, x, y, w, 1, WOOD_L)
		PA.rect(img, x, y + h - 1, w, 1, WOOD_D)
		for i in range(x + 2, x + w - 2, 5):
			if PA.rnd(i, y, sd) < 0.5:
				PA.px(img, i, y + h / 2, WOOD_D)
	else:
		PA.rect(img, x, y, 1, h, WOOD_L)
		PA.rect(img, x + w - 1, y, 1, h, WOOD_D)
		for j in range(y + 2, y + h - 2, 5):
			if PA.rnd(x, j, sd) < 0.5:
				PA.px(img, x + w / 2, j, WOOD_D)


# ------------------------------------------------------------------ murs

## Remplit toute l'image avec la matière du mur (crepi, colombage, pierre, planches).
static func wall(img: Image, kind: String, tint: Color, sd: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	if kind == "pierre":
		_rubble(img, sd)
		return
	if kind == "planches":
		_boards(img, sd)
		return
	# rampe de teintes précalculée : de -0,40 à +0,20 par pas de 0,01 (évite un calcul de couleur par pixel)
	var ramp: Array[Color] = []
	for i in 61:
		ramp.append(PA.shade(tint, -0.4 + 0.01 * float(i)))
	var nm := noise_map(w, h, sd, 11.0)
	for y in h:
		var low := maxf(0.0, (float(y) - float(h) * 0.62) / (float(h) * 0.38))
		for x in w:
			var n := nm[y * w + x] - 0.5
			var k := n * 0.14 + 0.035 * (1.0 - float(x) / float(w)) - low * 0.09   # l'humidité fonce le bas
			var r := PA.rnd(x, y, sd + 3)
			if r > 0.987:
				k -= 0.1
			elif r < 0.006:
				k += 0.08
			img.set_pixel(x, y, ramp[clampi(int(round((k + 0.4) * 100.0)), 0, 60)])
	# enduit écaillé : de petites plaques laissent voir la brique
	var chips := 2 + sd % 3
	for i in chips:
		var cx := int(PA.rnd(i, 1, sd) * float(w - 12)) + 4
		var cy := int(PA.rnd(i, 2, sd) * float(h - 28)) + 6
		var cw := 4 + int(PA.rnd(i, 3, sd) * 5.0)
		var ch := 3 + int(PA.rnd(i, 4, sd) * 3.0)
		PA.rect(img, cx, cy, cw, ch, PA.shade(tint, -0.22))
		PA.rect(img, cx + 1, cy + 1, cw - 2, ch - 1, Color("#b0785a"))
		PA.rect(img, cx + 1, cy + 1, cw - 2, 1, Color("#c98c68"))
		for k in range(cx + 1, cx + cw - 1, 2):
			PA.px(img, k, cy + 1 + (k % 2), Color("#8e5a44"))


static func _rubble(img: Image, sd: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var tones := ["#8d8780", "#9a938a", "#7f7a74", "#a39a8c", "#8a8478", "#947f70"]
	img.fill(Color("#4f4944"))
	var y := 0
	var row := 0
	while y < h:
		var rh := 6 + int(PA.rnd(row, 1, sd) * 4.0)
		var x := -int(PA.rnd(row, 2, sd) * 9.0)
		while x < w:
			var sw := 10 + int(PA.rnd(x + 40, row, sd) * 11.0)
			var base := col(tones[int(PA.rnd(x + 40, row, sd + 1) * 6.0) % 6])
			base = PA.shade(base, (vnoise(float(x), float(y), sd, 18.0) - 0.5) * 0.18)
			for yy in range(y, mini(y + rh - 1, h)):
				for xx in range(maxi(x, 0), mini(x + sw - 1, w)):
					var c := base
					if yy == y or xx == x:
						c = PA.shade(base, 0.16)
					elif yy >= y + rh - 2 or xx >= x + sw - 2:
						c = PA.shade(base, -0.2)
					elif PA.rnd(xx, yy, sd + 7) < 0.08:
						c = PA.shade(base, -0.08)
					img.set_pixel(xx, yy, c)
			# coins arrondis : le mortier mord dans les angles
			PA.px(img, x, y, Color("#4f4944"))
			PA.px(img, x + sw - 2, y + rh - 2, Color("#4f4944"))
			x += sw
		y += rh
		row += 1


static func _boards(img: Image, sd: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var tones := ["#8b6a48", "#7a5d40", "#9b7a54", "#a08c70", "#6f5438"]
	var y := 0
	var row := 0
	while y < h:
		var bh := 5
		var x := -int(PA.rnd(row, 5, sd) * 14.0)
		while x < w:
			var bw := 16 + int(PA.rnd(x + 70, row, sd) * 26.0)
			var base := col(tones[int(PA.rnd(x + 70, row, sd + 2) * 5.0) % 5])
			base = PA.shade(base, (vnoise(float(x), float(y), sd + 9, 20.0) - 0.5) * 0.16)
			for yy in range(y, mini(y + bh, h)):
				for xx in range(maxi(x, 0), mini(x + bw, w)):
					var c := base
					if yy == y:
						c = PA.shade(base, 0.14)
					elif yy == y + bh - 1:
						c = PA.shade(base, -0.34)
					elif xx == x + bw - 1:
						c = PA.shade(base, -0.3)
					elif PA.rnd(xx, yy, sd + 11) < 0.07:
						c = PA.shade(base, -0.12)
					img.set_pixel(xx, yy, c)
			PA.px(img, x + 2, y + 2, Color("#3a2a20"))   # clou
			PA.px(img, x + bw - 4, y + 2, Color("#3a2a20"))
			x += bw
		y += bh
		row += 1


## Ombre portée de l'avant-toit : le haut du mur s'assombrit franchement sur une dizaine de pixels.
static func eave_shadow(img: Image, from_y: int, depth: int, strength: float) -> void:
	var w := img.get_width()
	for i in depth:
		var t := 1.0 - float(i) / float(depth)
		var k := -strength * t * t
		for x in w:
			var y := from_y + i
			if y >= 0 and y < img.get_height():
				img.set_pixel(x, y, PA.shade(img.get_pixel(x, y), k))


## Soubassement de pierre, angles harpés et coulures, selon la variante.
static func wall_trim(img: Image, kind: String, sd: int, base_h: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	if kind == "pierre":
		PA.rect(img, 0, h - 3, w, 3, Color("#5a544e"))
		PA.rect(img, 0, h - 3, w, 1, Color("#7a736c"))
		return
	if kind == "planches":
		PA.rect(img, 0, h - 5, w, 5, Color("#6a645e"))
		PA.rect(img, 0, h - 5, w, 1, Color("#8f8982"))
		for x in range(2, w - 2, 9):
			PA.rect(img, x, h - 4, 7, 3, col(["#7d7770", "#6e6862", "#8a847c"][int(PA.rnd(x, 1, sd) * 3.0) % 3]))
		return
	TP._stone_base(img, base_h)
	if sd % 2 == 0:
		TP._quoins(img, true, h - 34)
		TP._quoins(img, false, h - 34)


# ------------------------------------------------------------------ ouvertures

static func _glass(img: Image, emi: Image, x: int, y: int, w: int, h: int, lit: bool, round_top: bool) -> void:
	for yy in h:
		for xx in w:
			if round_top and yy < w / 2:
				var dx := float(xx) + 0.5 - float(w) * 0.5
				var dy := float(yy) - float(w) * 0.5 + 0.5
				if dx * dx + dy * dy > float(w * w) * 0.25:
					continue
			var t := float(yy) / float(maxi(h - 1, 1))
			var c: Color
			if lit:
				c = Color("#fff0b8").lerp(Color("#f4a850"), t)
				if xx == 0 or yy == 0:
					c = c.lerp(Color("#e8923c"), 0.45)   # ombre de l'embrasure
				PA.px(emi, x + xx, y + yy, c)
			else:
				c = Color("#3d4a6c").lerp(Color("#2c3552"), t)
				if xx + yy < w * 3 / 4 and xx > 0 and yy > 0:
					c = Color("#6a7ca4")   # reflet du ciel
			PA.px(img, x + xx, y + yy, c)


## Fenêtre rectangulaire à croisillons, volets, linteau, appui et jardinière.
## kind : "croisillons" (4 carreaux), "arche" (haut cintré), "etroite" (2 carreaux hauts).
static func window(img: Image, emi: Image, cx: int, cy: int, lit: bool, shutter: Color, kind: String, left_ok: bool, right_ok: bool, flowers: bool, sd: int) -> void:
	var gw := 12 if kind != "etroite" else 8
	var gh := 16 if kind != "etroite" else 18
	var x0 := cx - gw / 2
	var y0 := cy - gh / 2
	# volets
	for side in 2:
		if (side == 0 and not left_ok) or (side == 1 and not right_ok):
			continue
		var sx := x0 - 6 if side == 0 else x0 + gw + 1
		PA.rect(img, sx, y0 - 2, 5, gh + 4, PA.shade(shutter, -0.38))
		PA.rect(img, sx + 1, y0 - 1, 3, gh + 2, shutter)
		PA.rect(img, sx + 1, y0 - 1, 1, gh + 2, PA.shade(shutter, 0.2))
		for k in range(y0 + 1, y0 + gh, 3):
			PA.px(img, sx + 2, k, PA.shade(shutter, -0.3))
	# cadre
	PA.rect(img, x0 - 2, y0 - 2, gw + 4, gh + 4, WOOD_D)
	PA.rect(img, x0 - 1, y0 - 1, gw + 2, gh + 2, WOOD_L)
	_glass(img, emi, x0, y0, gw, gh, lit, kind == "arche")
	# plombs
	var mid_x := x0 + gw / 2
	PA.rect(img, mid_x, y0, 1, gh, WOOD)
	PA.rect(emi, mid_x, y0, 1, gh, Color.BLACK)
	if kind != "etroite":
		PA.rect(img, x0, y0 + gh / 2, gw, 1, WOOD)
		PA.rect(emi, x0, y0 + gh / 2, gw, 1, Color.BLACK)
	else:
		for k in 2:
			PA.rect(img, x0, y0 + 6 + k * 6, gw, 1, WOOD)
			PA.rect(emi, x0, y0 + 6 + k * 6, gw, 1, Color.BLACK)
	# linteau de pierre
	PA.rect(img, x0 - 3, y0 - 5, gw + 6, 3, Color("#9a948c"))
	PA.rect(img, x0 - 3, y0 - 5, gw + 6, 1, Color("#c4beb4"))
	PA.rect(img, x0 - 3, y0 - 3, gw + 6, 1, Color("#6e6860"))
	# appui
	PA.rect(img, x0 - 3, y0 + gh + 2, gw + 6, 2, Color("#a8a39c"))
	PA.rect(img, x0 - 3, y0 + gh + 2, gw + 6, 1, Color("#cdc7bd"))
	if flowers:
		PA.rect(img, x0 - 2, y0 + gh + 4, gw + 4, 3, Color("#6e4c33"))
		PA.rect(img, x0 - 2, y0 + gh + 4, gw + 4, 1, Color("#8c6644"))
		var blooms := [Color("#e86a7a"), Color("#f2d55c"), Color("#f4f0e2"), Color("#b98ae0")]
		for k in range(0, gw + 4, 2):
			var c: Color = blooms[(k / 2 + sd) % 4]
			PA.px(img, x0 - 2 + k, y0 + gh + 3, Color("#4f9148"))
			PA.px(img, x0 - 2 + k, y0 + gh + 2, c)


## Porte à planches, ferrures et clous, sous un linteau de pierre ; arrondie en haut (« cintre ») ou plate.
static func door(img: Image, dx: int, color: Color, h: int, kind: String, sd: int) -> void:
	var dw := 28
	var dh := mini(46, h - 9)
	var x0 := dx - dw / 2
	var y0 := h - 4 - dh
	# encadrement de pierre
	PA.rect(img, x0 - 4, y0 - 5, dw + 8, dh + 9, Color("#6e6860"))
	PA.rect(img, x0 - 4, y0 - 5, dw + 8, 1, Color("#c4beb4"))
	PA.rect(img, x0 - 4, y0 - 5, 1, dh + 9, Color("#a8a39c"))
	for k in range(y0 + 2, y0 + dh, 7):
		PA.rect(img, x0 - 4, k, 4, 1, Color("#8e8880"))
		PA.rect(img, x0 + dw, k + 3, 4, 1, Color("#8e8880"))
	# marches
	PA.rect(img, x0 - 7, h - 2, dw + 14, 2, Color("#8a8590"))
	PA.rect(img, x0 - 5, h - 4, dw + 10, 2, Color("#a8a3ac"))
	PA.rect(img, x0 - 5, h - 4, dw + 10, 1, Color("#cdc7d0"))
	for yy in dh:
		for xx in dw:
			if kind == "cintre" and yy < dw / 2:
				var ddx := float(xx) + 0.5 - float(dw) * 0.5
				var ddy := float(yy) - float(dw) * 0.5 + 0.5
				if ddx * ddx + ddy * ddy > float(dw * dw) * 0.25:
					# l'angle perdu montre la pierre de l'arc
					PA.px(img, x0 + xx, y0 + yy, Color("#8e8880"))
					continue
			var c := color
			var m := posmod(xx, 7)
			if m == 0:
				c = PA.shade(color, -0.3)
			elif m == 1:
				c = PA.shade(color, 0.12)
			elif xx > dw - 6:
				c = PA.shade(color, -0.14)
			if PA.rnd(xx, yy, sd + 13) < 0.05:
				c = PA.shade(c, -0.1)
			PA.px(img, x0 + xx, y0 + yy, c)
	# ferrures, clous, anneau
	PA.rect(img, x0, y0 + dh / 4 + 2, dw - 6, 2, IRON)
	PA.rect(img, x0, y0 + dh * 3 / 4 - 2, dw - 6, 2, IRON)
	for k in range(x0 + 3, x0 + dw - 3, 7):
		PA.px(img, k, y0 + dh / 4 + 2, Color("#8a8898"))
		PA.px(img, k, y0 + dh * 3 / 4 - 2, Color("#8a8898"))
	PA.ellipse(img, float(x0 + dw - 6), float(y0 + dh / 2 + 2), 2.4, 2.4, Color("#d9b04a"))
	PA.ellipse(img, float(x0 + dw - 6), float(y0 + dh / 2 + 2), 1.2, 1.2, color.darkened(0.5))


# ------------------------------------------------------------------ façade

## Façade avant. spec : voir HouseBuilder.spec. Renvoie {"albedo", "emission"}.
static func front(spec: Dictionary, w_units: float, h_units: float, door_x: float, windows: Array, door_color: Color, lit: bool) -> Dictionary:
	var w := int(round(w_units * PPU))
	var h := int(round(h_units * PPU))
	var sd := int(spec["seed"])
	var wall_kind := str(spec["wall"])
	var img := PA.new_image(w, h)
	var emi := PA.new_image(w, h)
	emi.fill(Color.BLACK)
	wall(img, wall_kind, spec["tint"], sd)
	var storeys := int(spec["storeys"])
	var floor_y := h - 56   # ligne de plancher : au-dessus du linteau des portes
	if storeys < 2:
		floor_y = -1
	# poteaux entre les ouvertures
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
	eave_shadow(img, 0, 14 if str(spec["style"]) == "grobitte" else 11, 0.5 if str(spec["style"]) == "grobitte" else 0.34)
	if floor_y > 0:
		eave_shadow(img, floor_y + 4, 10, 0.3)   # dessous de l'encorbellement
	wall_trim(img, wall_kind, sd, 9)
	if wall_kind == "colombage":
		_timber_frame(img, posts, floor_y, sd, w >= 96)
	elif wall_kind == "crepi":
		TP._weather(img, sd)
	if floor_y > 0 and wall_kind != "colombage":
		timber(img, 0, floor_y, w, 4, sd)
	var shutter: Color = spec["shutter"]
	var round_style := str(spec["window"]) == "rond"
	var ground_cy := h - 36
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
		if round_style:
			TP._window(img, emi, wx, float(ground_cy), lit, shutter, left_ok, right_ok, sd)
		else:
			window(img, emi, int(wx), ground_cy - 3, lit, shutter, str(spec["window"]), left_ok, right_ok, false, sd)   # jardinières : en volume (HouseBuilder)
		if floor_y > 0:
			var ucy := floor_y / 2 + 1
			window(img, emi, int(wx), ucy, lit, shutter, "croisillons", left_ok, right_ok, false, sd + 5)
	if floor_y > 0 and door_x >= 0.0 and not bool(spec["awning"]):
		# fenêtre haute au-dessus de la porte, plus étroite
		window(img, emi, int(door_x * PPU), floor_y / 2 + 1, lit and PA.rnd(3, 3, sd) < 0.7, shutter, "etroite", false, false, false, sd + 8)
	if door_x >= 0.0:
		if round_style:
			TP._door(img, door_x * PPU, door_color, h)
		else:
			door(img, int(door_x * PPU), door_color, h, str(spec["door"]), sd)
	return {"albedo": img, "emission": emi}   # lierre : en volume (HouseBuilder), plus peint à plat


static func _timber_frame(img: Image, posts: Array[int], floor_y: int, sd: int, braces: bool) -> void:
	var w := img.get_width()
	var h := img.get_height()
	# sablières, poteaux d'angle
	timber(img, 0, 0, w, 4, sd)
	if floor_y > 0:
		timber(img, 0, floor_y, w, 4, sd)
	timber(img, 0, h - 14, w, 3, sd)
	timber(img, 0, 0, 4, h - 9, sd + 1)
	timber(img, w - 4, 0, 4, h - 9, sd + 2)
	for px_x in posts:
		timber(img, px_x - 2, 0, 4, h - 9, sd + 3)
	# croix de Saint-André entre les poteaux de l'étage
	if braces:
		var xs: Array[int] = [0]
		xs.append_array(posts)
		xs.append(w - 1)
		for k in range(xs.size() - 1):
			var xa := xs[k] + 4
			var xb := xs[k + 1] - 3
			if xb - xa < 24:
				continue
			var ya := 4
			var yb := (floor_y if floor_y > 0 else h - 14) - 1
			if (k + sd) % 2 == 0:
				PA.line(img, xa, ya + 1, xb, yb, WOOD)
				PA.line(img, xa + 1, ya + 1, xb, yb - 1, WOOD)
				PA.line(img, xa, ya, xb - 1, yb - 1, WOOD_L)
			else:
				PA.line(img, xb, ya + 1, xa, yb, WOOD)
				PA.line(img, xb - 1, ya + 1, xa, yb - 1, WOOD)
				PA.line(img, xb, ya, xa + 1, yb - 1, WOOD_L)


## Pignon : toute la paroi latérale (mur puis triangle), `rh_units` = hauteur du faîte au-dessus du mur.
static func side(spec: Dictionary, d_units: float, wh_units: float, rh_units: float, lit: bool) -> Dictionary:
	var w := int(round(d_units * PPU))
	var wh := int(round(wh_units * PPU))
	var h := wh + int(round(rh_units * PPU))
	var sd := int(spec["seed"]) + 31
	var kind := str(spec["wall"])
	var img := PA.new_image(w, h)
	var emi := PA.new_image(w, h)
	emi.fill(Color.BLACK)
	wall(img, kind, spec["tint"], sd)
	eave_shadow(img, h - wh, 9, 0.28)
	# la paroi basse ressemble à la façade : soubassement, poteaux
	var low := img.get_region(Rect2i(0, h - wh, w, wh))
	wall_trim(low, kind, sd, 9)
	img.blit_rect(low, Rect2i(0, 0, w, wh), Vector2i(0, h - wh))
	if kind == "colombage":
		# poteaux et jambes de force du pignon
		timber(img, 0, h - wh, 4, wh - 9, sd)
		timber(img, w - 4, h - wh, 4, wh - 9, sd)
		timber(img, w / 2 - 2, 0, 4, h - 9, sd)
		timber(img, 0, h - wh - 2, w, 4, sd)
		PA.line(img, 3, h - wh - 3, w / 2 - 3, h / 5, WOOD)
		PA.line(img, w - 4, h - wh - 3, w / 2 + 3, h / 5, WOOD)
	elif kind == "crepi":
		TP._weather(img, sd)
	if w > 70 and wh > 40:
		# une fenêtre au milieu de la paroi, plus rarement un oculus dans le pignon
		var ok := PA.rnd(5, 5, sd) < 0.8
		if ok:
			window(img, emi, w / 2 + (14 if kind == "colombage" else 0), h - 36 - 3, lit and PA.rnd(6, 6, sd) < 0.6, spec["shutter"], "croisillons", true, true, false, sd)
	if rh_units >= 1.3 and w > 60:
		var oy := h - wh - int(rh_units * PPU * 0.38)
		PA.ellipse(img, float(w) * 0.5, float(oy), 6.0, 6.0, WOOD_D)
		PA.ellipse(img, float(w) * 0.5, float(oy), 5.0, 5.0, WOOD_L)
		_glass(img, emi, w / 2 - 4, oy - 4, 8, 8, lit and PA.rnd(7, 7, sd) < 0.5, false)
	return {"albedo": img, "emission": emi}


# ------------------------------------------------------------------ toits

## Texture d'un pan de toit (peinte à la taille exacte : aucun motif ne se répète).
## u : de gauche à droite ; v : du faîtage (haut) à l'avant-toit (bas).
static func roof(spec: Dictionary, w_units: float, len_units: float) -> Image:
	var w := clampi(int(round(w_units * PPU)), 24, 512)
	var h := clampi(int(round(len_units * PPU)), 24, 400)
	var kind := str(spec["roof"])
	var sd := int(spec["seed"]) + 77
	var pal: Array = ROOF_PAL.get(kind, ROOF_PAL["rouge"])
	var tones: Array[Color] = []
	for s: Variant in pal:
		tones.append(col(s))
	# teinte propre à la maison : même matière, pas tout à fait la même couleur
	var shift := (PA.rnd(1, 9, sd) - 0.5) * 0.12
	for i in tones.size():
		tones[i] = PA.shade(tones[i], shift)
	var img := PA.new_image(w, h)
	match kind:
		"chaume":
			_thatch(img, tones, sd)
		"herbe":
			_turf(img, tones, sd)
		_:
			_tiles(img, tones, kind == "ardoise", sd)
	if kind == "herbe":
		_turf_curve(img)
	else:
		_weather(img, spec, w_units, sd)
	# ombre franche sous l'avant-toit (bas) et éclat du faîtage (haut)
	for i in 5:
		for x in w:
			img.set_pixel(x, h - 1 - i, PA.shade(img.get_pixel(x, h - 1 - i), -0.2 + 0.035 * float(i)))
	for x in w:
		img.set_pixel(x, 0, PA.shade(img.get_pixel(x, 0), 0.12))
	return img


## Toit en tonneau des Grobittes : l'herbe s'éclaircit nettement vers la crête (le milieu de la
## texture), s'assombrit vers les avant-toits (haut et bas), des raies de gazon suivent la courbe, et
## un liseré de gazon plus sombre, ourlé d'un fil clair, borde les pignons : le toit se détache du sol.
static func _turf_curve(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		var v := float(y) / float(maxi(h - 1, 1))
		var k := 1.0 - absf(v - 0.5) * 2.0          # 0 aux avant-toits, 1 à la crête
		var d := -0.36 + 0.9 * k * k + 0.3 * k   # courbe franche : sombre aux avant-toits, claire à la crête
		for x in w:
			var c := PA.shade(img.get_pixel(x, y), d)
			if k > 0.55:
				c = c.lerp(Color("#f0f89a"), 0.34 * (k - 0.55) / 0.45)   # la crête, dorée par le soleil
			elif k < 0.3:
				c = c.lerp(Color("#1e4a34"), 0.4 * (0.3 - k) / 0.3)    # le dessous, vert profond
			img.set_pixel(x, y, c)
	# raies de gazon, plus serrées près des bords (la courbe fuit)
	for i in range(1, 9):
		var y := int(round(float(h - 1) * (0.5 - 0.5 * cos(PI * float(i) / 9.0))))
		for x in w:
			img.set_pixel(x, y, PA.shade(img.get_pixel(x, y), -0.2))
			if y + 1 < h:
				img.set_pixel(x, y + 1, PA.shade(img.get_pixel(x, y + 1), 0.1))
	# liseré des rives : deux colonnes sombres, un fil clair à l'intérieur
	for y in h:
		for i in 2:
			for x: int in [i, w - 1 - i]:
				img.set_pixel(x, y, PA.shade(img.get_pixel(x, y), -0.34 + 0.1 * float(i)))
		img.set_pixel(2, y, PA.shade(img.get_pixel(2, y), 0.14))
		img.set_pixel(w - 3, y, PA.shade(img.get_pixel(w - 3, y), 0.14))
	# frange d'herbe pendante le long des deux avant-toits
	for x in w:
		if PA.rnd(x, 3, 71) < 0.55:
			var c := PA.shade(img.get_pixel(x, 3), -0.1)
			img.set_pixel(x, 1, c)
			img.set_pixel(x, h - 2, PA.shade(img.get_pixel(x, h - 3), -0.1))
		if PA.rnd(x, 4, 71) < 0.3:
			img.set_pixel(x, 0, PA.shade(img.get_pixel(x, 2), -0.25))
			img.set_pixel(x, h - 1, PA.shade(img.get_pixel(x, h - 3), -0.3))


## Vieillissement d'un toit de tuiles, d'ardoises ou de chaume vu de face : la teinte dérive d'une
## assise à l'autre, de la mousse s'installe vers l'avant-toit, quelques tuiles manquent, et les
## lucarnes jettent leur ombre sur le pan.
static func _weather(img: Image, spec: Dictionary, w_units: float, sd: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	# 1. dérive de teinte et de clarté par assise
	var band := 7
	for y in h:
		var b := y / band
		var dh := (PA.rnd(b, 1, sd + 40) - 0.5) * 0.045
		var dv := (PA.rnd(b, 2, sd + 40) - 0.5) * 0.12
		for x in w:
			var c := img.get_pixel(x, y)
			c.h = fposmod(c.h + dh, 1.0)
			img.set_pixel(x, y, PA.shade(c, dv))
	# 2. mousse : petites touffes posées sur le bord bas des assises, plus nombreuses dans des zones
	# lentes et vers le faîtage (le nord du pan, à l'abri du soleil) ; jamais de grande tache
	var kind := str(spec["roof"])
	var course := 14 if kind == "chaume" else (6 if kind == "ardoise" else 7)
	var base_moss := Color("#5e8a3c") if kind != "chaume" else Color("#7a8a3a")
	var r := 0
	while (r + 1) * course <= h + course:
		var yb := mini((r + 1) * course - 1, h - 6)
		var vy := float(yb) / float(h)
		var n_try := maxi(2, w / 9)
		for k in n_try:
			var cx := int(PA.rnd(k, r, sd + 52) * float(w))
			var zone := vnoise(float(cx), float(yb), sd + 50, 40.0)
			var p := 0.04 + 0.5 * maxf(0.0, zone - 0.58) + (0.14 if vy < 0.3 else 0.0)
			if PA.rnd(k, r, sd + 53) >= p:
				continue
			var cw := 3 + int(PA.rnd(k, r, sd + 54) * 3.0)
			for i in cw:
				var hgt := 1 + (1 if (i > 0 and i < cw - 1) else 0) + (1 if (PA.rnd(i, k + r * 31, sd + 55) < 0.3) else 0)
				for j in hgt:
					var c := base_moss.lerp(Color("#8fb25a"), PA.rnd(cx + i, yb - j, sd + 56) * 0.8)
					if j == hgt - 1:
						c = PA.shade(c, 0.16)
					PA.px(img, cx + i, yb - j, c)
				PA.px(img, cx + i, yb + 1, PA.shade(base_moss, -0.5))
		r += 1
	# 4. ombre des lucarnes (lumière venue du haut et de la gauche : l'ombre tombe en bas à droite)
	var dn := int(spec.get("dormers", 0))
	if dn > 0:
		var hw := w_units - 0.6
		for i in dn:
			var frac := 0.5 if dn == 1 else (0.27 if i == 0 else 0.73)
			if dn == 1:
				frac = 0.3 if not bool(spec.get("chimney_left", false)) else 0.7
				frac = 1.0 - frac if hw < 7.0 else frac
			var cx := (hw * frac + 0.3) / w_units * float(w)
			var cy := float(h) * 0.5
			for y in range(int(cy) - 4, int(cy) + 24):
				for x in range(int(cx) - 12, int(cx) + 26):
					var dx := (float(x) - (cx + 7.0)) / 17.0
					var dy := (float(y) - (cy + 10.0)) / 15.0
					if dx * dx + dy * dy < 1.0 and x >= 0 and x < w and y >= 0 and y < h:
						img.set_pixel(x, y, PA.shade(img.get_pixel(x, y), -0.2))


static func _tiles(img: Image, tones: Array[Color], slate: bool, sd: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var rh := 6 if slate else 7
	var tw := 9 if slate else 11
	var r := 0
	var y0 := 0
	while y0 < h + rh:
		var off := (tw / 2 if r % 2 == 1 else 0) + int(PA.rnd(r, 1, sd) * 3.0)
		var x0 := -tw + off
		var c_i := 0
		while x0 < w:
			var tw_i := tw + (int(PA.rnd(c_i, r, sd + 1) * 3.0) - 1 if slate else 0)
			var tone: Color = tones[int(PA.rnd(c_i, r, sd + 2) * 3.0) % 3]
			var age := PA.rnd(c_i, r, sd + 3)
			if age < 0.12:
				tone = tone.darkened(0.14)
			elif age > 0.9:
				tone = tone.lightened(0.12)
			# taches de patine lentes, dégradé du faîtage (clair) à l'avant-toit (sombre)
			var cx := x0 + tw_i / 2
			var wear := vnoise(float(cx), float(y0), sd, 26.0) - 0.5
			tone = PA.shade(tone, wear * 0.2 + 0.05 - 0.1 * float(y0) / float(h))
			for y in rh:
				var yy := y0 + y
				if yy >= h:
					break
				for x in tw_i:
					var xx := x0 + x
					if xx < 0 or xx >= w:
						continue
					var c := tone
					var rounded := y >= rh - 2 and (x == 0 or x == tw_i - 1)
					if y == 0:
						c = tones[4].lerp(tone, 0.5)
					elif y == 1:
						c = tone.lerp(tones[4], 0.2)
					elif rounded:
						c = tones[3]
					elif y == rh - 1 or x == tw_i - 1:
						c = tones[3]
					elif y == rh - 2:
						c = tone.lerp(tones[3], 0.45)
					elif x == 0:
						c = tone.lerp(tones[3], 0.3)
					elif x == 1 and y < rh - 2:
						c = tone.lerp(tones[4], 0.18)
					elif PA.rnd(xx, yy, sd + 4) < 0.06:
						c = tone.darkened(0.1)
					img.set_pixel(xx, yy, c)
			if age > 0.62 and age < 0.637 and y0 >= rh and y0 < h - 2 * rh:
				_lath(img, x0, y0, tw_i, rh, sd + r * 7 + c_i)
			if age > 0.52 and age < 0.6:
				for k in 5:
					PA.px(img, x0 + 2 + k * 2, y0 + 2 + (k % 2), Color("#6f9a50"))
			x0 += tw_i
			c_i += 1
		y0 += rh
		r += 1


## Tuile manquante : on voit la volige brune et un lattis, sous l'ombre fine de l'assise du dessus
## (jamais un trou noir : le brun reste proche des tons du toit).
static func _lath(img: Image, x0: int, y0: int, tw: int, rh: int, sd: int) -> void:
	var board := Color("#7a5636")
	for y in rh:
		for x in tw:
			var c := board
			if y == 0:
				c = Color("#3c281c")          # ombre portée de l'assise du dessus
			elif y == 1:
				c = board.darkened(0.35)
			elif y == rh - 2 and rh > 5:
				c = Color("#4a3322")          # jeu entre deux planches
			elif y == rh - 1:
				c = board.lightened(0.12)     # chant du lattis
			else:
				c = board.lerp(Color("#9a6e44"), PA.rnd(x, y, sd) * 0.35)
			if x == 0 or x == tw - 1:
				c = c.darkened(0.25)          # tuiles voisines : ombre latérale
			PA.px(img, x0 + x, y0 + y, c)
	# un clou et une fibre de bois
	PA.px(img, x0 + 2 + int(PA.rnd(1, 1, sd) * float(tw - 4)), y0 + 2, Color("#2a1c14"))
	PA.px(img, x0 + 1 + int(PA.rnd(2, 1, sd) * float(tw - 3)), y0 + 3, Color("#5a3e28"))


static func _thatch(img: Image, tones: Array[Color], sd: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	img.fill(tones[0])
	var course := 14
	for x in w:
		var y := 0
		while y < h:
			var n := 3 + int(PA.rnd(x, y, sd) * 8.0)
			var c: Color = tones[int(PA.rnd(x, y, sd + 1) * 3.0) % 3]
			var wear := vnoise(float(x), float(y), sd, 22.0) - 0.5
			c = PA.shade(c, wear * 0.22)
			for k in n:
				if y + k < h:
					img.set_pixel(x, y + k, c)
			y += n
	# bottes superposées : chaque assise s'assombrit vers son bord bas, liens de brins
	for y in h:
		var yc := y % course
		if yc >= course - 4:
			for x in w:
				img.set_pixel(x, y, PA.shade(img.get_pixel(x, y), -0.05 * float(yc - course + 5)))
		if yc == course - 1:
			for x in w:
				img.set_pixel(x, y, tones[3])
		elif yc == 0 and y > 0:
			for x in w:
				if PA.rnd(x, y, sd + 5) < 0.6:
					img.set_pixel(x, y, tones[4])
	for rrow in range(course / 2, h, course):
		for x in range(int(PA.rnd(rrow, 1, sd) * 10.0), w, 12):
			PA.px(img, x, rrow, tones[3])
			PA.px(img, x + 1, rrow, tones[3])


static func _turf(img: Image, tones: Array[Color], sd: int) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var c_mid := tones[1].lightened(0.07)
	var c_hi := tones[1].lerp(tones[2], 0.55)
	var c_lo := tones[1].lerp(tones[3], 0.28)
	var c_dk := tones[1].lerp(tones[3], 0.5)
	var nm := noise_map(w, h, sd, 4.0)
	var nm2 := noise_map(w, h, sd + 9, 13.0)
	for y in h:
		for x in w:
			var n := nm[y * w + x] * 0.7 + nm2[y * w + x] * 0.3
			var c := c_mid
			if n > 0.62:
				c = c_mid.lerp(c_hi, 0.7)
			elif n < 0.38:
				c = c_mid.lerp(c_lo, 0.7)
			if PA.rnd(x, y, sd) < 0.012:
				c = c_dk
			img.set_pixel(x, y, c)
	# touffes d'herbe : traits clairs verticaux, plus hauts
	for i in int(w * h / 48):
		var x := int(PA.rnd(i, 1, sd + 3) * float(w))
		var y := int(PA.rnd(i, 2, sd + 3) * float(h))
		var hh := 2 + int(PA.rnd(i, 3, sd + 3) * 4.0)
		for k in hh:
			PA.px(img, x, y - k, tones[4] if k == hh - 1 else tones[2])
			if hh >= 4 and k == hh - 2:
				PA.px(img, x + 1, y - k - 1, tones[4])
	# fleurs des champs : petites corolles en croix et points, regroupées en bouquets
	var blooms := [Color("#f4f0e2"), Color("#f2d55c"), Color("#e86a7a"), Color("#b98ae0"), Color("#ff9a3c")]
	for i in 26 + int(w * h / 300):
		var x := int(PA.rnd(i, 4, sd + 4) * float(w - 6)) + 3
		var y := int(PA.rnd(i, 5, sd + 4) * float(h - 6)) + 3
		var bc: Color = blooms[int(PA.rnd(i, 6, sd + 4) * 5.0) % 5]
		var cross := PA.rnd(i, 7, sd + 4) < 0.45
		for j in (3 if cross else 2):
			var bx := x + int(PA.rnd(i, 10 + j, sd + 4) * 5.0) - 2
			var by := y + int(PA.rnd(i, 20 + j, sd + 4) * 3.0) - 1
			PA.px(img, bx, by, bc)
			if cross:
				PA.px(img, bx - 1, by, bc)
				PA.px(img, bx + 1, by, bc)
				PA.px(img, bx, by - 1, bc)
				PA.px(img, bx, by + 1, bc)
				PA.px(img, bx, by, Color("#f2d55c") if bc != blooms[1] else Color("#d9822a"))
			else:
				PA.px(img, bx + 1, by + 1, bc.darkened(0.3))
	# ombre vers l'avant-toit
	for y in range(h - 5, h):
		for x in w:
			img.set_pixel(x, y, PA.shade(img.get_pixel(x, y), -0.06 * float(y - h + 6)))


# ------------------------------------------------------------------ lucarne

## Face d'une lucarne : 24 x 30 px. Haut (0..9) = fronton triangulaire, bas = mur et fenêtre.
static func dormer(spec: Dictionary, lit: bool) -> Dictionary:
	var sd := int(spec["seed"]) + 5
	var img := PA.new_image(24, 30)
	var emi := PA.new_image(24, 30)
	emi.fill(Color.BLACK)
	wall(img, "crepi" if str(spec["wall"]) != "pierre" else "pierre", spec["tint"], sd)
	timber(img, 0, 8, 24, 3, sd)
	timber(img, 0, 8, 3, 22, sd)
	timber(img, 21, 8, 3, 22, sd)
	timber(img, 10, 0, 4, 9, sd)
	_glass(img, emi, 6, 13, 12, 14, lit, false)
	PA.rect(img, 11, 13, 1, 14, WOOD)
	PA.rect(img, 6, 19, 12, 1, WOOD)
	PA.rect(emi, 11, 13, 1, 14, Color.BLACK)
	PA.rect(emi, 6, 19, 12, 1, Color.BLACK)
	PA.rect(img, 4, 27, 16, 2, Color("#a8a39c"))
	return {"albedo": img, "emission": emi}


# ------------------------------------------------------------------ lierre

## Carte de lierre (grimpant sur un angle de mur) : `couche` 0 = base collée au mur, dense ; 1 = feuilles
## qui dépassent, plus claires ; 2 = rameaux pendants. Peinte à plat avec transparence franche
## (le constructeur les pose en couches successives, légèrement décollées du mur, pour donner du volume).
static func ivy_card(w: int, h: int, layer: int, sd: int) -> Image:
	var img := PA.new_image(w, h)
	var greens := [Color("#2f5a34"), Color("#3f7d43"), Color("#4f9148"), Color("#6aac58")]
	if layer == 1:
		greens = [Color("#3f7d43"), Color("#4f9148"), Color("#6aac58"), Color("#88c46a")]
	var vx := float(w) * (0.3 if layer == 0 else 0.45)
	var n := int(float(w * h) / (11.0 if layer == 0 else 22.0))
	for i in n:
		# la tige monte en serpentant ; les feuilles s'écartent d'elle, moins nombreuses vers le haut
		var t := PA.rnd(i, 1, sd)                       # 0 = bas, 1 = haut
		var y := int((1.0 - t * t) * float(h - 4)) + 1
		if layer == 2:
			y = int(PA.rnd(i, 2, sd) * float(h * 3 / 4))
		var spread := float(w) * (0.5 - 0.22 * t) if layer != 2 else float(w) * 0.3
		var cx := vx + sin(float(y) * 0.21 + float(sd)) * 2.0 + (PA.rnd(i, 3, sd) - 0.5) * 2.0 * spread
		var lx := int(clampf(cx, 1.0, float(w) - 4.0))
		var lc: Color = greens[int(PA.rnd(i, 4, sd) * 4.0) % 4]
		# feuille : losange de 3 x 3 à 4 x 3 pixels, un reflet, une ombre
		var lw := 3 + (1 if PA.rnd(i, 5, sd) < 0.4 else 0)
		for yy in 3:
			for xx in lw:
				if (yy == 0 or yy == 2) and (xx == 0 or xx == lw - 1) and PA.rnd(xx, yy + i, sd) < 0.8:
					continue
				PA.px(img, lx + xx, y + yy, PA.shade(lc, -0.35) if yy == 2 else lc)
		PA.px(img, lx + 1, y, PA.shade(lc, 0.3))
		if PA.rnd(i, 6, sd) < 0.05 and layer == 1:
			PA.px(img, lx + 2, y + 1, Color("#f4f0e2"))   # une petite fleur
	# tige sombre, visible entre les feuilles
	var x := vx
	for y in range(h - 1, 0, -1):
		x = vx + sin(float(y) * 0.21 + float(sd)) * 2.0
		if layer != 2 and PA.rnd(y, 7, sd) < 0.85:
			PA.px(img, int(x), y, Color("#243f28"))
	return img


# ------------------------------------------------------------------ enseigne

## Panneau suspendu 28 x 24 px : planche, cadre et emblème selon le commerce.
static func sign_board(kind: String) -> Image:
	var img := PA.new_image(28, 24)
	var board := Color("#8a6038")
	PA.rect(img, 2, 5, 24, 18, WOOD_D)
	PA.rect(img, 3, 6, 22, 16, board)
	PA.rect(img, 3, 6, 22, 1, PA.shade(board, 0.2))
	PA.rect(img, 3, 21, 22, 1, PA.shade(board, -0.3))
	# chaînes
	PA.line(img, 5, 0, 5, 5, IRON)
	PA.line(img, 22, 0, 22, 5, IRON)
	PA.px(img, 5, 1, Color("#8a8898"))
	PA.px(img, 22, 2, Color("#8a8898"))
	match kind:
		"auberge":   # chope mousseuse
			PA.rect(img, 9, 11, 9, 9, Color("#d9a23a"))
			PA.rect(img, 9, 11, 2, 9, Color("#f0c860"))
			PA.rect(img, 9, 19, 9, 1, Color("#8a5a20"))
			PA.rect(img, 18, 13, 3, 5, Color("#d9a23a"))
			PA.rect(img, 19, 14, 1, 3, board)
			PA.rect(img, 8, 9, 11, 3, Color("#f4f0e2"))
			PA.px(img, 10, 8, Color("#f4f0e2"))
			PA.px(img, 14, 8, Color("#f4f0e2"))
			PA.px(img, 17, 8, Color("#f4f0e2"))
		"fromage":   # part de fromage trouée
			for x in 15:
				var hgt := 2 + x * 8 / 14
				PA.rect(img, 7 + x, 20 - hgt, 1, hgt, Color("#f0c64a"))
			PA.rect(img, 7, 12, 15, 1, Color("#fadc78"))
			PA.rect(img, 7, 19, 15, 2, Color("#c8962a"))
			PA.rect(img, 13, 17, 2, 2, Color("#c8962a"))
			PA.rect(img, 18, 18, 2, 1, Color("#c8962a"))
			PA.px(img, 16, 16, Color("#c8962a"))
		"forge":   # enclume
			PA.rect(img, 7, 10, 15, 3, Color("#8a8898"))
			PA.rect(img, 7, 10, 15, 1, Color("#b4b2c0"))
			PA.rect(img, 20, 11, 4, 2, Color("#8a8898"))
			PA.rect(img, 11, 13, 7, 3, Color("#5a586a"))
			PA.rect(img, 9, 16, 11, 4, Color("#4a485a"))
			PA.px(img, 24, 8, Color("#ffb040"))
			PA.px(img, 22, 7, Color("#ffd878"))
		"cheval":   # fer à cheval
			for a in range(30, 331, 12):
				var rad := deg_to_rad(float(a))
				PA.rect(img, 14 + int(cos(rad) * 6.0), 14 - int(sin(rad) * 6.0) + 1, 3, 3, Color("#c4c2d0"))
			PA.rect(img, 8, 19, 3, 2, Color("#c4c2d0"))
			PA.rect(img, 19, 19, 3, 2, Color("#c4c2d0"))
		"horloge":   # cadran de la mairie
			PA.ellipse(img, 14.0, 14.0, 7.0, 7.0, Color("#d8b44a"))
			PA.ellipse(img, 14.0, 14.0, 5.5, 5.5, Color("#f4f0e2"))
			PA.line(img, 14, 14, 14, 10, Color("#2f2c38"))
			PA.line(img, 14, 14, 17, 15, Color("#2f2c38"))
			for t in [Vector2i(14, 8), Vector2i(14, 20), Vector2i(8, 14), Vector2i(20, 14)]:
				PA.px(img, t.x, t.y, Color("#8a5a20"))
		"blason":   # écu parti rouge et or
			PA.rect(img, 8, 8, 12, 8, Color("#b43a3a"))
			PA.rect(img, 14, 8, 6, 8, Color("#e0b048"))
			for k in 5:
				PA.rect(img, 8 + k, 16 + k, 12 - 2 * k, 1, Color("#b43a3a") if k < 3 else Color("#e0b048"))
			PA.rect(img, 8, 8, 12, 1, Color("#2f2c38"))
		"herbes":   # feuille
			PA.ellipse(img, 14.0, 14.0, 6.0, 4.0, Color("#4f9148"))
			PA.ellipse(img, 13.0, 13.0, 3.0, 2.0, Color("#78bc5c"))
			PA.line(img, 8, 19, 20, 11, Color("#2f5a34"))
		_:
			PA.rect(img, 8, 10, 12, 1, PA.shade(board, -0.3))
			PA.rect(img, 8, 14, 12, 1, PA.shade(board, -0.3))
			PA.rect(img, 8, 18, 8, 1, PA.shade(board, -0.3))
	PA.outline(img, Rect2i(0, 0, 28, 24), WOOD_D)
	return img
