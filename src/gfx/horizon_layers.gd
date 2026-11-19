extends RefCounted
## Plans peints des arrière-plans à parallaxe (voir src/world/horizon.gd) : montagne, cité en
## étages, plaine de siège, collines. Chaque plan est une image transparente de W x H cases
## dont le bas se pose sur le sol lointain ; la brume est ajoutée à l'affichage (shader
## horizon_layer). Tout est tracé par colonnes, au pixel, sans lissage.

const PA = preload("res://src/gfx/pixel_art.gd")
static var W := 1200
static var H := 360

const LIT := Color("#f4f0e4")
const MID := Color("#e3ddcd")
const SHADE := Color("#c9c3b6")
const JOINT := Color("#b9b3a6")
const SLATE := Color("#56658a")
const SLATE_LIT := Color("#6f7fa6")
const GOLD := Color("#e8c25a")
const WINDOW := Color("#ffd070")
const BLUE := Color("#27365e")


static func paint(kind: String, sd: int, opts: Dictionary = {}) -> Image:
	W = int(opts.get("w", 1200))
	H = 360
	var img := PA.new_image(W, H)
	match kind:
		"city":
			_city(img, sd, int(opts.get("tiers", 4)), bool(opts.get("tower", true)), int(opts.get("off", 0)))
		"mountain":
			_mountain(img, sd, int(opts.get("off", 0)), float(opts.get("peak", 0.9)))
		"plain":
			_plain(img, sd, int(opts.get("fires", 14)))
		"hills":
			_hills(img, sd, float(opts.get("peak", 0.5)))
		"ridge":
			_ridge(img, sd, float(opts.get("peak", 0.4)))
	return img


static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	if w > 0 and h > 0:
		img.fill_rect(Rect2i(x, y, w, h), c)


static func _n(x: int, y: int, sd: int) -> float:
	return PA.rnd(x, y, sd)


# ===================================================================== la cité

## Cité en étages vue de face : chaque étage est un mur crénelé en arc, des maisons à toit
## d'ardoise au-dessus ; au sommet la Tour Blanche, son étendard, et l'éperon de roche qui
## fend la ville d'un trait. L'étage le plus haut est dessiné d'abord, le plus bas en dernier.
static func _city(img: Image, sd: int, tiers: int, tower: bool, off: int) -> void:
	var cx := W / 2 + off
	var wall_h := 22
	var pitch_y := 38
	var base_top := H - 60
	# la citadelle du sommet et la tour
	var top_y := base_top - tiers * pitch_y
	if tower:
		_citadel(img, cx, top_y, sd)
	for k in range(tiers - 1, -1, -1):
		var t := float(k) / float(maxi(tiers - 1, 1))
		var hw := int(lerpf(575.0, 150.0, t))
		var ty := base_top - k * pitch_y
		_houses(img, cx, hw, ty, k, sd)
		_wall(img, cx, hw, ty, wall_h, k, sd)
	if tower:
		_spur(img, cx, top_y + 44, sd)


static func _sag(d: float, k: int) -> int:
	return int(pow(absf(d), 3.0) * (30.0 - float(k) * 2.0))


static func _wall(img: Image, cx: int, hw: int, ty: int, wall_h: int, k: int, sd: int) -> void:
	for x in range(maxi(cx - hw, 0), mini(cx + hw, W)):
		var d := float(x - cx) / float(hw)
		var top := ty + _sag(d, k)
		var lit := 0.5 + 0.5 * clampf(d, -1.0, 1.0) * 0.6
		var face := MID.lerp(LIT, lit) if d > -0.2 else MID.lerp(SHADE, 0.25)
		_r(img, x, top, 1, H - top, face)
		# créneaux
		if (x / 5) % 2 == 0:
			_r(img, x, top, 1, 4, LIT.lerp(face, 0.3))
		else:
			_r(img, x, top + 4, 1, 1, SHADE)
		_r(img, x, top + 5, 1, 2, SHADE.lerp(face, 0.3))
		# joints des pierres
		var y := top + 8
		var row := 0
		while y < H:
			_r(img, x, y, 1, 1, JOINT)
			var shift := (row % 2) * 6
			if ((x + shift) % 12) == 0:
				_r(img, x, y + 1, 1, 5, JOINT)
			y += 6
			row += 1
		# lierre et ombres sous le mur : quelques pixels sombres
		if _n(x / 3, k, sd) < 0.18:
			_r(img, x, top + 12 + int(_n(x, k, sd + 1) * 6.0), 1, 2, Color("#9aa78a"))
	# bannières du Poirier le long du mur
	var bx := cx - hw + 40 + k * 17
	while bx < cx + hw - 20:
		var d2 := float(bx - cx) / float(hw)
		var by := ty + _sag(d2, k) + 6
		_r(img, bx, by, 6, 22, BLUE)
		_r(img, bx + 2, by + 4, 2, 7, LIT)
		_r(img, bx, by + 22, 2, 2, BLUE)
		_r(img, bx + 4, by + 22, 2, 2, BLUE)
		bx += 96


static func _houses(img: Image, cx: int, hw: int, ty: int, k: int, sd: int) -> void:
	var x := cx - hw + 8
	var i := 0
	while x < cx + hw - 30:
		var w := 16 + int(_n(i, k, sd) * 20.0)
		var hh := 12 + int(_n(i, k + 9, sd) * 16.0)
		var mid := x + w / 2
		var d := float(mid - cx) / float(hw)
		var base := ty + _sag(d, k) + 2
		var wall_c := MID.lerp(LIT, 0.5 + 0.4 * d)
		_r(img, x, base - hh, w, hh, wall_c)
		_r(img, x + w - 4, base - hh, 4, hh, SHADE)
		# toit à deux pentes
		var rh := 8 + int(_n(i, k + 3, sd) * 8.0)
		var rc := SLATE if _n(i, k + 5, sd) < 0.7 else Color("#6f9a8a")
		for r in rh:
			var inset := int(float(rh - r) * float(w) * 0.5 / float(rh))
			_r(img, x - 2 + inset, base - hh - rh + r, w + 4 - inset * 2, 1, rc.lerp(SLATE_LIT, 0.35 if r < rh / 3 else 0.0))
		# fenêtres allumées
		var wx := x + 3
		while wx < x + w - 6:
			if _n(wx, i + k * 31, sd + 2) < 0.5:
				_r(img, wx, base - hh + 4, 2, 4, WINDOW)
			wx += 7
		x += w + int(_n(i, k + 7, sd) * 9.0) + 2
		i += 1


## La citadelle et la Tour Blanche : trois fûts qui rétrécissent, flèche d'ardoise, étendard.
static func _citadel(img: Image, cx: int, ty: int, sd: int) -> void:
	# le palais bas, ses dômes dorés
	_r(img, cx - 100, ty + 40, 200, 60, MID)
	_r(img, cx - 100, ty + 40, 200, 4, LIT)
	for q in 10:
		_r(img, cx - 100 + q * 20, ty + 36, 10, 5, LIT)
	for q in 3:
		var dx := cx - 70 + q * 70
		for r in 11:
			var hw2 := int(sqrt(maxf(0.0, 121.0 - float(r * r))))
			_r(img, dx - hw2, ty + 30 + (11 - r) - 11, hw2 * 2, 1, GOLD.lerp(Color("#fff0b0"), 0.2 if r > 7 else 0.0))
	# la tour
	var y := ty + 40
	var widths := [46, 38, 30]
	var heights := [44, 36, 30]
	for q in 3:
		var w: int = widths[q]
		var h: int = heights[q]
		_r(img, cx - w / 2, y - h, w, h, LIT)
		_r(img, cx + w / 2 - 10, y - h, 10, h, SHADE)
		_r(img, cx - w / 2, y - h, 2, h, Color("#ffffff"))
		_r(img, cx - w / 2 - 3, y - h - 4, w + 6, 5, LIT)
		_r(img, cx - w / 2 - 3, y - h + 1, w + 6, 1, SHADE)
		var by := y - h + 8
		while by < y - 8:
			_r(img, cx - w / 2 + 6, by, 4, 10, WINDOW)
			_r(img, cx + 3, by, 4, 10, WINDOW)
			by += 17
		y -= h + 4
	var spire := 42
	for r in spire:
		var hw3 := int(float(r) * 0.42)
		_r(img, cx - hw3 - 1, y - spire + r, hw3 * 2 + 3, 1, SLATE_LIT if r < 8 else SLATE)
	_r(img, cx, y - spire - 20, 2, 20, GOLD)
	# étendard bleu nuit, Poirier blanc
	_r(img, cx + 2, y - spire - 20, 30, 14, BLUE)
	_r(img, cx + 14, y - spire - 17, 5, 8, LIT)
	_r(img, cx + 10, y - spire - 18, 13, 3, LIT)
	_r(img, cx + 30, y - spire - 18, 3, 4, BLUE)


## L'éperon de roche : un coin sombre dont la pointe regarde la plaine, du palais jusqu'au pied.
static func _spur(img: Image, cx: int, top: int, sd: int) -> void:
	var rock_l := Color("#a39a8e")
	var rock_d := Color("#6f665e")
	for y in range(top, H):
		var t := float(y - top) / float(H - top)
		var half := int(lerpf(4.0, 34.0, pow(t, 0.8)))
		for x in range(cx - half, cx + half):
			var c := rock_l if x < cx else rock_d
			if _n(x / 2, y / 3, sd) < 0.12:
				c = c.darkened(0.12)
			PA.px(img, x, y, c)
		PA.px(img, cx - 1, y, Color("#d9d2c6"))
		PA.px(img, cx, y, Color("#d9d2c6"))


# ================================================================= la montagne

static func _ridge_h(x: int, sd: int, cx: int, peak: float) -> float:
	var f := float(x - cx)
	var mass := exp(-pow(f / 330.0, 2.0)) * (0.8 + 0.2 * absf(sin(float(x) * 0.013 + float(sd))))
	var side := 0.52 * exp(-pow((f - 470.0) / 170.0, 2.0)) + 0.44 * exp(-pow((f + 520.0) / 190.0, 2.0))
	var jag := (_n(x / 5, 0, sd) - 0.5) * 22.0 + (_n(x / 17, 1, sd) - 0.5) * 36.0
	return float(H) * (0.22 + peak * 0.7 * maxf(mass, side * peak)) + jag * (0.4 + mass)


## Un massif enneigé, éclairé par la droite : la montagne qui monte derrière la cité.
static func _mountain(img: Image, sd: int, off: int, peak: float) -> void:
	var cx := W / 2 + off
	var rock_l := Color("#8a96b2")
	var rock_d := Color("#586584")
	var snow_l := Color("#f4f7fc")
	var snow_d := Color("#b6c6e2")
	var prev := 0.0
	for x in W:
		var h := _ridge_h(x, sd, cx, peak)
		var top := H - int(h)
		var facing_lit := h <= prev + 0.5 if x > 0 else true
		# ici h plus petit à droite du pic (pente qui descend vers la droite) = face tournée vers la droite = éclairée
		var lit := _ridge_h(x + 3, sd, cx, peak) < _ridge_h(x - 3, sd, cx, peak)
		prev = h
		var snow_line := H - int(H * 0.52)
		var base := rock_l if lit else rock_d
		for y in range(top, H):
			var c := base
			var rel := float(y - top)
			var snow_depth := (float(snow_line) - float(top)) * 0.8 + _n(x / 4, y / 6, sd + 4) * 18.0 - 8.0
			if rel < snow_depth and top < snow_line:
				c = snow_l if lit else snow_d
			elif _n(x / 3, y / 9, sd) < 0.14:
				c = base.darkened(0.14)
			elif ((x * 7 + y * 3) / 16) % 11 == 0:
				c = base.lightened(0.07)
			PA.px(img, x, y, c)
		PA.px(img, x, top, snow_l if top < snow_line else base.lightened(0.15))


## Rang de collines bleutées, pour la profondeur.
static func _hills(img: Image, sd: int, peak: float) -> void:
	var c1 := Color("#7a88a8")
	var c2 := Color("#6a7898")
	for layer in 2:
		var base := float(H) * (1.0 - peak * (0.55 + 0.45 * float(layer)))
		var col := c1 if layer == 0 else c2
		for x in W:
			var fx := float(x)
			var h := sin(fx * 0.008 + float(sd + layer * 5)) * 22.0 + sin(fx * 0.021 + float(layer) * 3.0) * 11.0 + (_n(x / 6, layer, sd) - 0.5) * 6.0
			var top := int(base + h)
			_r(img, x, top, 1, H - top, col)
			PA.px(img, x, top, col.lightened(0.14))
			if layer == 1 and _n(x / 2, 7, sd) < 0.2:
				PA.px(img, x, top + 3 + int(_n(x, 3, sd) * 9.0), col.darkened(0.14))


static func _ridge(img: Image, sd: int, peak: float) -> void:
	var col := Color("#8393b2")
	for x in W:
		var fx := float(x)
		var h := (sin(fx * 0.006 + float(sd)) * 0.5 + 0.5) * 60.0 + sin(fx * 0.017 + 2.0) * 16.0 + (_n(x / 4, 2, sd) - 0.5) * 8.0
		var top := int(float(H) * (1.0 - peak) - h * 0.8)
		_r(img, x, top, 1, H - top, col)
		PA.px(img, x, top, col.lightened(0.16))


# ================================================================ la plaine du siège

## Camp du siège vu de loin : tentes, brasiers, trébuchets, tours de siège, fumées qui penchent.
static func _plain(img: Image, sd: int, fires: int) -> void:
	var ground := H - 8
	# crêtes sombres derrière le camp
	var ridge := Color("#6a5f6a")
	for x in W:
		var top := ground - 46 - int(sin(float(x) * 0.007 + float(sd)) * 14.0 + sin(float(x) * 0.023) * 6.0 + _n(x / 5, 4, sd) * 5.0)
		_r(img, x, top, 1, ground - top, ridge)
		PA.px(img, x, top, ridge.lightened(0.12))
	var tent_cols := [Color("#a8734a"), Color("#8b8f9a"), Color("#b5483a"), Color("#6f7a55"), Color("#c9b48a")]
	var fire_pos: Array = []
	for row in 4:
		var scale := 1.0 - float(row) * 0.2
		var base := ground - 2 - row * 11
		var x := int(_n(row, 0, sd) * 30.0)
		var i := 0
		while x < W:
			var w := int((16.0 + _n(i, row, sd) * 16.0) * scale)
			var hh := int(float(w) * 0.8)
			var tc: Color = tent_cols[int(_n(i, row + 3, sd) * 5.0) % 5]
			tc = tc.darkened(float(row) * 0.04)
			for r in hh:
				var hw2 := int(float(w) * 0.5 * float(r + 1) / float(hh))
				_r(img, x + w / 2 - hw2, base - hh + r, hw2 * 2 + 1, 1, tc)
			_r(img, x + w / 2 + 1, base - hh, 1, hh, tc.darkened(0.2))
			_r(img, x + w / 2, base - hh - 5, 1, 5, Color("#3a2e2a"))
			_r(img, x + w / 2 + 1, base - hh - 5, 5, 3, BLUE if _n(i, row, sd + 9) < 0.5 else Color("#7a2030"))
			var roll := _n(i, row + 20, sd)
			if roll < 0.13 and row < 3:
				fire_pos.append(Vector2i(x + w + 3, base))
			elif roll < 0.18:
				_trebuchet(img, x + w + 8, base, scale)
			elif roll < 0.21 and row < 2:
				_siege_tower(img, x + w + 8, base, scale)
			x += w + int((8.0 + _n(i, row + 40, sd) * 26.0) * scale)
			i += 1
	_r(img, 0, ground, W, H - ground, Color("#4a3c34"))
	# les feux et leurs fumées
	var shown := 0
	for fp: Vector2i in fire_pos:
		if shown >= fires:
			break
		shown += 1
		_fire(img, fp.x, fp.y, sd + shown)


static func _fire(img: Image, x: int, y: int, sd: int) -> void:
	var smoke := Color("#4b4446")
	var hgt := 120 + int(_n(x, y, sd) * 110.0)
	for k in hgt:
		var t := float(k) / float(hgt)
		var wv := 3.0 + t * 16.0
		var cxk := x + int(t * t * 46.0 + sin(t * 9.0 + float(sd)) * 3.0)
		var half := int(wv * 0.5)
		for dx in range(-half, half + 1):
			var keep := _n(cxk + dx, y - k, sd) > t * 0.85
			if keep and (dx * dx) <= half * half:
				PA.px(img, cxk + dx, y - 6 - k, smoke.lerp(Color("#6b6466"), t * 0.8 if (dx + k) % 3 == 0 else 0.0))
	_r(img, x - 1, y - 3, 4, 3, Color("#ff7a1c"))
	_r(img, x, y - 5, 2, 3, Color("#ffd24a"))


static func _trebuchet(img: Image, x: int, y: int, sc: float) -> void:
	var c := Color("#3a2e2a")
	var h := int(34.0 * sc)
	for k in h:
		var inset := int(float(k) * 0.22)
		PA.px(img, x + inset, y - k, c)
		PA.px(img, x + 14 - inset, y - k, c)
	PA.line(img, x + 2, y - h, x + 30, y - h + 10, c)
	PA.line(img, x + 2, y - h - 1, x + 30, y - h + 9, c)
	_r(img, x - 6, y - h - 6, 8, 8, c)
	_r(img, x - 2, y - 3, 22, 3, c)


static func _siege_tower(img: Image, x: int, y: int, sc: float) -> void:
	var c := Color("#4a3b32")
	var w := int(20.0 * sc)
	var h := int(52.0 * sc)
	_r(img, x, y - h, w, h, c)
	_r(img, x + 2, y - h + 4, w - 4, 3, Color("#2a201c"))
	_r(img, x + 2, y - h / 2, w - 4, 3, Color("#2a201c"))
	_r(img, x - 2, y - h - 3, w + 4, 4, Color("#5a4a3f"))
	_r(img, x + 1, y - 4, 4, 4, Color("#2a201c"))
	_r(img, x + w - 5, y - 4, 4, 4, Color("#2a201c"))
