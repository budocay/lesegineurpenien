extends RefCounted
## Peint le lointain d'une arène de combat : un ciel dégradé et des silhouettes en plans
## successifs (collines, forêt, brume du marais, toits de la ville, caverne de la forge).
## L'image est posée sur un grand panneau loin derrière la paroi ; le flou de profondeur
## l'adoucit. Voir docs/FORMAT_DONNEES.md (champ « far » de « backdrop »).

const PA = preload("res://src/gfx/pixel_art.gd")
const W := 384
const H := 112


static func paint(kind: String, top: Color, bottom: Color, sd: int) -> Image:
	var img := PA.new_image(W, H)
	_sky(img, top, bottom)
	match kind:
		"hills":
			_hills(img, top, bottom, sd)
		"forest":
			_forest(img, top, bottom, sd)
		"marsh":
			_marsh(img, top, bottom, sd)
		"town":
			_town(img, top, bottom, sd)
		"cavern":
			_cavern(img, top, bottom, sd)
	return img


## Ciel : dégradé par bandes tramées (damier), plus fidèle au pixel art qu'un lissage.
static func _sky(img: Image, top: Color, bottom: Color) -> void:
	for y in H:
		var t := float(y) / float(H - 1)
		var band := t * 7.0
		var lo := floorf(band)
		var frac := band - lo
		for x in W:
			var dither := ((x + y) % 2 == 0) and frac > 0.25 and frac < 0.75
			var k := (lo + (1.0 if dither or frac >= 0.75 else 0.0)) / 7.0
			img.set_pixel(x, y, top.lerp(bottom, clampf(k, 0.0, 1.0)))


static func _mix(a: Color, b: Color, t: float) -> Color:
	return a.lerp(b, t)


## Remplit sous une crête : base = hauteur moyenne (en pixels depuis le haut).
static func _ridge(img: Image, base: float, amp: float, sd: int, col: Color, rim: Color) -> void:
	for x in W:
		var fx := float(x) / float(W) * TAU
		var y := base + sin(fx * 2.0 + float(sd)) * amp + sin(fx * 5.0 + float(sd) * 2.0) * amp * 0.45 \
				+ (PA.rnd(x / 3, 0, sd) - 0.5) * amp * 0.25
		var yi := int(y)
		for yy in range(yi, H):
			img.set_pixel(x, yy, col)
		PA.px(img, x, yi, rim)


static func _conifer(img: Image, cx: int, base: int, hgt: int, col: Color, light: Color) -> void:
	var tiers := maxi(3, hgt / 6)
	for i in tiers:
		var y0 := base - hgt + i * (hgt / tiers)
		var half := 2 + int(float(i + 1) / float(tiers) * float(hgt) * 0.28)
		for k in (hgt / tiers) + 2:
			var hw := maxi(1, int(float(half) * float(k + 1) / float((hgt / tiers) + 2)))
			PA.rect(img, cx - hw, y0 + k, hw * 2 + 1, 1, col)
		PA.px(img, cx - 1, y0 + 1, light)
	PA.rect(img, cx, base - 1, 1, 3, col)


static func _round_tree(img: Image, cx: int, base: int, r: int, col: Color, light: Color) -> void:
	PA.ellipse(img, float(cx), float(base - r), float(r), float(r) * 0.9, col)
	PA.ellipse(img, float(cx) - float(r) * 0.25, float(base - r) - float(r) * 0.3, float(r) * 0.5, float(r) * 0.4, light)
	PA.rect(img, cx, base - r, 1, r + 2, col)


static func _hills(img: Image, top: Color, bottom: Color, sd: int) -> void:
	var far := _mix(bottom, top, 0.35).darkened(0.18)
	var near := _mix(bottom, top, 0.2).darkened(0.38)
	_ridge(img, 70.0, 9.0, sd, far, far.lightened(0.12))
	_ridge(img, 84.0, 7.0, sd + 4, near, near.lightened(0.1))
	var tc := near.darkened(0.15)
	for i in 70:
		var x := int(PA.rnd(i, 1, sd) * W)
		_round_tree(img, x, 88 + int(PA.rnd(i, 2, sd) * 5.0), 3 + int(PA.rnd(i, 3, sd) * 3.0), tc, near)


static func _forest(img: Image, top: Color, bottom: Color, sd: int) -> void:
	var c1 := _mix(bottom, top, 0.35).darkened(0.12)
	var c2 := _mix(bottom, top, 0.2).darkened(0.3)
	var c3 := _mix(bottom, top, 0.1).darkened(0.5)
	_ridge(img, 62.0, 5.0, sd, c1, c1.lightened(0.1))
	for i in 46:
		_conifer(img, int(PA.rnd(i, 1, sd) * W), 76, 18 + int(PA.rnd(i, 2, sd) * 14.0), c1, c1.lightened(0.15))
	_ridge(img, 76.0, 4.0, sd + 2, c2, c2.lightened(0.08))
	for i in 60:
		var x := int(PA.rnd(i, 3, sd) * W)
		if i % 3 == 0:
			_round_tree(img, x, 92, 6 + int(PA.rnd(i, 4, sd) * 5.0), c2, c2.lightened(0.12))
		else:
			_conifer(img, x, 94, 22 + int(PA.rnd(i, 5, sd) * 16.0), c2, c2.lightened(0.12))
	_ridge(img, 98.0, 3.0, sd + 5, c3, c3.lightened(0.06))
	for i in 34:
		_conifer(img, int(PA.rnd(i, 6, sd) * W), 108, 28 + int(PA.rnd(i, 7, sd) * 20.0), c3, c3.lightened(0.08))


static func _marsh(img: Image, top: Color, bottom: Color, sd: int) -> void:
	var far := _mix(bottom, top, 0.3).darkened(0.1)
	var near := _mix(bottom, top, 0.1).darkened(0.35)
	_ridge(img, 86.0, 2.5, sd, far, far.lightened(0.1))
	# troncs morts et roseaux
	for i in 18:
		var x := int(PA.rnd(i, 1, sd) * W)
		var hh := 18 + int(PA.rnd(i, 2, sd) * 22.0)
		var base := 92
		PA.rect(img, x, base - hh, 2, hh, near)
		for b in 3:
			var by := base - hh + 3 + b * 6
			var dir := 1 if PA.rnd(i, 10 + b, sd) < 0.5 else -1
			PA.line(img, x, by, x + dir * (4 + b * 2), by - 4, near)
	_ridge(img, 98.0, 2.0, sd + 3, near.darkened(0.15), near)
	# brume : bandes claires translucides
	var mist := _mix(bottom, Color.WHITE, 0.4)
	for k in 5:
		var y := 70 + k * 7
		for x in W:
			var a := (0.10 + 0.07 * sin(float(x) * 0.03 + float(k) * 2.0)) * (1.0 if (x + k) % 3 != 0 else 0.6)
			for dy in 3:
				var c := img.get_pixel(x, y + dy)
				img.set_pixel(x, y + dy, c.lerp(mist, a))


static func _town(img: Image, top: Color, bottom: Color, sd: int) -> void:
	var far := _mix(bottom, top, 0.3).darkened(0.12)
	var near := _mix(bottom, top, 0.1).darkened(0.42)
	var win := Color("#ffcf7a")
	for layer in 2:
		var col := far if layer == 0 else near
		var base := 84 if layer == 0 else 104
		var x := -6
		var i := 0
		while x < W:
			var hw := 14 + int(PA.rnd(i, layer, sd) * 14.0)
			var hh := 10 + int(PA.rnd(i, 3 + layer, sd) * 12.0)
			PA.rect(img, x, base - hh, hw, hh + (H - base), col)
			# toit en pignon
			var rh := 6 + int(PA.rnd(i, 5, sd) * 6.0)
			for k in rh:
				var inset := int(float(k) * float(hw) * 0.5 / float(rh))
				PA.rect(img, x - 1 + inset, base - hh - rh + k, hw + 2 - inset * 2, 1, col.darkened(0.08))
			if PA.rnd(i, 6, sd) < 0.5:
				PA.rect(img, x + hw / 2 + 3, base - hh - rh - 3, 3, 6, col)
			if layer == 1:
				for wx in range(x + 4, x + hw - 3, 6):
					if PA.rnd(wx, i, sd) < 0.55:
						PA.rect(img, wx, base - hh + 5, 2, 3, win)
			x += hw + int(PA.rnd(i, 7, sd) * 3.0)
			i += 1
	# clocher au loin
	var cx := 90 + int(PA.rnd(1, 1, sd) * 200.0)
	PA.rect(img, cx, 36, 10, 52, far.darkened(0.05))
	for k in 14:
		PA.rect(img, cx + 5 - (14 - k) / 3, 22 + k, ((14 - k) / 3) * 2 + 1, 1, far.darkened(0.05))
	PA.rect(img, cx + 3, 44, 4, 6, win.darkened(0.2))


static func _cavern(img: Image, top: Color, bottom: Color, sd: int) -> void:
	var dark := top.darkened(0.55)
	# stalactites
	for x in W:
		var len := 6.0 + PA.rnd(x / 6, 0, sd) * 18.0 + sin(float(x) * 0.07) * 8.0
		var tip := len * (1.0 - absf(float(x % 6) - 3.0) / 4.0)
		PA.rect(img, x, 0, 1, int(maxf(tip, 3.0)), dark)
	# piliers et arches lointaines
	var pill := _mix(bottom, top, 0.4).darkened(0.35)
	for i in 8:
		var x := 20 + i * 48 + int(PA.rnd(i, 1, sd) * 14.0)
		var w := 8 + int(PA.rnd(i, 2, sd) * 6.0)
		PA.rect(img, x, 30, w, H - 30, pill)
		PA.rect(img, x, 30, 1, H - 30, pill.lightened(0.12))
		PA.rect(img, x - 2, 26, w + 4, 5, pill.lightened(0.05))
	# lueur de la lave au pied
	for y in range(72, H):
		var t := float(y - 72) / float(H - 72)
		for x in W:
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, c.lerp(Color("#ff7a2a"), t * t * 0.7))
	var rim := Color("#ffb347")
	for x in W:
		var y := 100 + int(sin(float(x) * 0.09) * 2.0 + PA.rnd(x / 2, 3, sd) * 2.0)
		for yy in range(y, H):
			img.set_pixel(x, yy, Color("#ff9a30").lerp(rim, PA.rnd(x, yy, sd)))
