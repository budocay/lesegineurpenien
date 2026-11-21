extends RefCounted
## Plans peints des arrière-plans à parallaxe (voir src/world/horizon.gd) : montagne, cité en
## étages, cité vue d'en haut, armée du siège, collines. Chaque plan est une image transparente
## de W x 360 pixels dont le bas se pose sur le sol lointain ; la brume est ajoutée à l'affichage
## (shader horizon_layer). Tout est tracé par colonnes et par rectangles, sans lissage : la
## peinture reste rapide (quelques dizaines de millisecondes par plan).
## La lumière vient de la droite, comme le soleil bas du ciel « matin ».

const PA = preload("res://src/gfx/pixel_art.gd")
static var W := 1200
static var H := 360
## Foyers des feux du dernier plan peint (pixels), pour les lueurs ajoutées par horizon.gd.
static var fires: Array = []

const LIT := Color("#fbf7ea")
const MID := Color("#e8e1d0")
const SHADE := Color("#c4bdb0")
const DEEP := Color("#a59e94")
const JOINT := Color("#b4ad9f")
const SLATE := Color("#54648c")
const SLATE_L := Color("#7083ac")
const SLATE_D := Color("#3e4a70")
const TEAL := Color("#6c9c8c")
const GOLD := Color("#ecc65c")
const GOLD_D := Color("#b8903a")
const WINDOW := Color("#ffd578")
const BLUE := Color("#27365e")
const LEAF := Color("#5c8a52")
const LEAF_L := Color("#7fae68")
const LEAF_D := Color("#3f6a40")


static func paint(kind: String, sd: int, opts: Dictionary = {}) -> Image:
	W = int(opts.get("w", 1200))
	H = 360
	fires = []
	var img := PA.new_image(W, H)
	img.fill(Color(Color(str(opts.get("haze", "#d6e2f0"))), 0.0))   # les pixels vides gardent la couleur de la brume (pas de liseré noir aux mip-maps)
	match kind:
		"city":
			_city(img, sd, int(opts.get("tiers", 4)), bool(opts.get("tower", true)), int(opts.get("off", 0)))
		"terraces":
			_terraces(img, sd, int(opts.get("tiers", 4)))
		"mountain":
			_mountain(img, sd, int(opts.get("off", 0)), float(opts.get("peak", 0.9)))
		"plain":
			_plain(img, sd, int(opts.get("fires", 14)), float(opts.get("scale", 1.0)))
		"hills":
			_hills(img, sd, float(opts.get("peak", 0.5)), int(opts.get("trees", 1)))
		"ridge":
			_ridge(img, sd, float(opts.get("peak", 0.4)))
		"massif":
			_massif(img, sd, int(opts.get("off", 0)), float(opts.get("peak", 0.6)), bool(opts.get("tower", true)))
		"horde":
			_horde(img, sd, int(opts.get("fires", 14)), float(opts.get("scale", 1.0)))
	return img


static func _r(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	if w <= 0 or h <= 0:
		return
	var x0 := maxi(x, 0)
	var y0 := maxi(y, 0)
	var x1 := mini(x + w, W)
	var y1 := mini(y + h, H)
	if x1 > x0 and y1 > y0:
		img.fill_rect(Rect2i(x0, y0, x1 - x0, y1 - y0), c)


static func _n(x: int, y: int, sd: int) -> float:
	return PA.rnd(x, y, sd)


## Disque plein, par lignes.
static func _disc(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for dy in range(-r, r + 1):
		var hw := int(sqrt(maxf(0.0, float(r * r - dy * dy))))
		_r(img, cx - hw, cy + dy, hw * 2 + 1, 1, c)


## Disque ombré : sombre, puis une calotte claire côté soleil (droite et haut).
static func _puff(img: Image, cx: int, cy: int, r: int, dark: Color, light: Color) -> void:
	_disc(img, cx, cy, r, dark)
	var r2 := maxi(r * 2 / 3, 1)
	_disc(img, cx + r / 4, cy - r / 4, r2, dark.lerp(light, 0.55))
	var r3 := maxi(r / 3, 1)
	_disc(img, cx + r / 3, cy - r / 3, r3, light)


# ===================================================================== la cité

## Cité en étages vue d'en bas, de face : chaque étage est un mur crénelé en arc (bastions, bannières,
## poternes) sous un semis de maisons à toits d'ardoise, de jardins et de dômes ; au sommet, le palais, la
## Tour Blanche et son étendard ; l'éperon de roche fend la ville d'un trait. L'étage le plus haut
## est peint d'abord, le plus bas en dernier.
static func _city(img: Image, sd: int, tiers: int, tower: bool, off: int) -> void:
	var cx := W / 2 + off
	var ring_h := 28
	var pitch := 42
	var top0 := H - 34
	var top_y := top0 - (tiers - 1) * pitch
	if tower:
		_citadel(img, cx, top_y - 12, sd)
	for k in range(tiers - 1, -1, -1):
		var t := float(k) / float(maxi(tiers - 1, 1))
		var hw := int(lerpf(float(W) * 0.49, float(W) * 0.15, t))
		var ty := top0 - k * pitch
		_houses(img, cx, hw, ty, k, sd)
		_wall(img, cx, hw, ty, ring_h, k, sd)
	if tower:
		_spur(img, cx, top_y + 14, sd)


static func _sag(d: float, k: int) -> int:
	return int(pow(absf(d), 2.4) * (27.0 - float(k) * 3.0))


static func _wall(img: Image, cx: int, hw: int, ty: int, wall_h: int, k: int, sd: int) -> void:
	var courses := 5
	for x in range(maxi(cx - hw, 0), mini(cx + hw, W)):
		var d := float(x - cx) / float(hw)
		var top := ty + _sag(d, k)
		var lit := clampf(0.4 + 0.5 * d, 0.0, 1.0)
		var face := SHADE.lerp(MID, 0.45 + lit * 0.55)
		if (x / 6) % 2 == 0:   # merlon
			_r(img, x, top, 1, 5, LIT.lerp(face, 0.25))
			_r(img, x, top + 5, 1, 2, SHADE)
		else:   # entre deux merlons : le chemin de ronde
			_r(img, x, top + 4, 1, 3, DEEP.lerp(face, 0.3))
		_r(img, x, top + 7, 1, H - top - 7, face)
		_r(img, x, top + 7, 1, 2, LIT.lerp(face, 0.5))
		# assises
		var shift := 0
		for r in courses:
			var y := top + 11 + r * 7
			if y >= H:
				break
			img.set_pixel(x, y, JOINT)
			shift = (r % 2) * 7
			if (x + shift) % 14 == 0 and y + 6 < H:
				_r(img, x, y + 1, 1, 6, JOINT)
		# mousse
		if _n(x / 3, k, sd) < 0.2:
			_r(img, x, top + 8 + int(_n(x, k, sd + 1) * 12.0), 1, 2, Color("#9fae8c"))
		# pied de mur dans l'ombre portée
		_r(img, x, mini(top + wall_h + 14, H - 1), 1, 2, DEEP.lerp(face, 0.5))
	# bastions (tours rondes) et bannières
	var bx := cx - hw + 46 + k * 23
	var bi := 0
	while bx < cx + hw - 30:
		var d2 := float(bx - cx) / float(hw)
		var by := ty + _sag(d2, k) - 12
		if bi % 3 != 1:
			_bastion(img, bx, by, 8 + (k % 2) * 2, wall_h + 18, sd + bi)
		else:
			var yb := ty + _sag(d2, k) + 9
			_r(img, bx - 3, yb, 7, 22, BLUE)
			_r(img, bx - 3, yb + 22, 3, 3, BLUE)
			_r(img, bx + 1, yb + 22, 3, 3, BLUE)
			_r(img, bx, yb + 5, 1, 9, LIT)
			_r(img, bx - 2, yb + 7, 5, 2, LIT)
		bx += 84 + int(_n(bi, k, sd) * 30.0)
		bi += 1
	# poternes
	var px := cx - hw / 2 + k * 31
	for q in 3:
		var d3 := float(px - cx) / float(hw)
		if absf(d3) < 0.95:
			var py := ty + _sag(d3, k) + 22
			_r(img, px - 4, py, 9, 14, SLATE_D)
			_r(img, px - 3, py - 2, 7, 2, SLATE_D)
			_r(img, px - 2, py - 3, 5, 1, SLATE_D)
		px += hw * 2 / 3 + 40


## Tour ronde de rempart : fût ombré en cylindre, créneaux, petit toit d'ardoise.
static func _bastion(img: Image, bx: int, top: int, rad: int, hgt: int, sd: int) -> void:
	for dx in range(-rad, rad + 1):
		var u := float(dx) / float(rad)
		var c := SHADE.lerp(LIT, clampf(0.5 + u * 0.6, 0.0, 1.0))
		_r(img, bx + dx, top + 6, 1, hgt, c)
		if (dx + rad) % 4 < 2:
			_r(img, bx + dx, top, 1, 6, LIT.lerp(c, 0.3))
		else:
			_r(img, bx + dx, top + 4, 1, 2, SHADE)
	_r(img, bx - 1, top + 14, 2, 6, SLATE_D)
	_r(img, bx + rad - 3, top + 12, 2, 5, WINDOW)
	if _n(bx, top, sd) < 0.5:
		var rh := rad + 5
		for r in rh:
			var inset := int(float(rh - r) * float(rad + 2) / float(rh))
			_r(img, bx - rad - 1 + inset, top - rh + r + 2, (rad + 1 - inset) * 2 + 1, 1, SLATE_L if r < rh / 3 else SLATE)
		_r(img, bx, top - rh - 4, 1, 5, GOLD)


static func _houses(img: Image, cx: int, hw: int, ty: int, k: int, sd: int) -> void:
	var x := cx - hw + 6
	var i := 0
	while x < cx + hw - 26:
		var mid := x + 16
		var d := clampf(float(mid - cx) / float(hw), -1.0, 1.0)
		var base := ty + _sag(d, k) + 4
		var roll := _n(i, k + 31, sd)
		if roll < 0.12:   # jardin : arbre et buisson
			var r := 6 + int(_n(i, k + 2, sd) * 4.0)
			_r(img, x + 8, base - r - 4, 2, r + 4, Color("#6a523a"))
			_disc(img, x + 9, base - r * 2 + 1, r, LEAF_D)
			_disc(img, x + 10, base - r * 2 - 1, r * 3 / 4, LEAF)
			_disc(img, x + 12, base - r * 2 - 2, maxi(r / 3, 2), LEAF_L)
			x += r * 2 + 8
			i += 1
			continue
		var w := 20 + int(_n(i, k, sd) * 20.0)
		var bh := 12 + int(_n(i, k + 9, sd) * 15.0)
		var tone := 0.45 + 0.4 * d
		var wall_c := MID.lerp(LIT, tone)
		_r(img, x, base - bh, w, bh, wall_c)
		_r(img, x, base - bh, 3, bh, SHADE)
		_r(img, x + w - 3, base - bh, 3, bh, LIT)
		_r(img, x, base - 2, w, 2, SHADE)
		var rk := _n(i, k + 5, sd)
		if rk < 0.5:   # pignon sur rue
			var rh := int(float(w) * 0.5) + 2
			var rc := SLATE if _n(i, k + 6, sd) < 0.8 else TEAL
			for r in rh:
				var half := int(float(r + 1) * float(w + 4) * 0.5 / float(rh))
				_r(img, x + w / 2 - half, base - bh - rh + r, half, 1, rc.lerp(SLATE_D, 0.25))
				_r(img, x + w / 2, base - bh - rh + r, half, 1, rc.lerp(SLATE_L, 0.35))
			_r(img, x + w / 2, base - bh - rh, 1, rh, SLATE_L.lerp(LIT, 0.35))
		elif rk < 0.88:   # long pan
			var rh := 9 + int(_n(i, k + 8, sd) * 6.0)
			var rc2 := SLATE if _n(i, k + 6, sd) < 0.85 else TEAL
			for r in rh:
				var inset := int(float(rh - r) * 0.7)
				_r(img, x - 2 + inset, base - bh - rh + r, w + 4 - inset * 2, 1, rc2.lerp(SLATE_L, 0.4 if r < rh / 3 else 0.0))
			_r(img, x + 3 + int(_n(i, k + 4, sd) * float(w - 9)), base - bh - rh - 5, 3, 7, SHADE)
		else:   # dôme doré sur tambour
			var r := w / 2 - 1
			for q in r:
				var hh := int(sqrt(maxf(0.0, float(r * r - q * q))))
				_r(img, x + w / 2 - hh, base - bh - q, hh * 2, 1, GOLD.lerp(Color("#fff2b8"), 0.3 if q > r / 2 else 0.0))
			_r(img, x + w / 2, base - bh - r - 4, 1, 4, GOLD_D)
		# fenêtres
		var wx := x + 4
		while wx < x + w - 6:
			if _n(wx, i + k * 31, sd + 2) < 0.6:
				_r(img, wx, base - bh + 4, 3, 5, WINDOW)
				_r(img, wx + 1, base - bh + 3, 1, 1, WINDOW)
			wx += 8
		if bh > 20:
			_r(img, x + w / 2 - 2, base - 8, 4, 8, SLATE_D)
		x += w + int(_n(i, k + 7, sd) * 8.0) + 2
		i += 1


## Le palais, ses dômes, ses tourelles, la Tour Blanche et l'étendard du Poirier.
static func _citadel(img: Image, cx: int, ty: int, sd: int) -> void:
	# tourelles de part et d'autre
	for s in [-1, 1]:
		var tx: int = cx + s * 112
		for dx in range(-14, 15):
			var u := float(dx) / 14.0
			_r(img, tx + dx, ty - 38, 1, 74, SHADE.lerp(LIT, clampf(0.5 + u * 0.6, 0.0, 1.0)))
		_r(img, tx - 16, ty - 42, 33, 5, LIT)
		for q in 7:
			_r(img, tx - 14 + q * 5, ty - 47, 3, 5, LIT)
		for r in 26:
			var hw2 := int(float(r) * 0.6)
			_r(img, tx - hw2, ty - 74 + r, hw2 * 2 + 1, 1, SLATE_L if r < 8 else SLATE)
		_r(img, tx, ty - 88, 1, 15, GOLD)
		_r(img, tx - 2, ty - 26, 4, 9, WINDOW)
		_r(img, tx - 2, ty - 6, 4, 9, WINDOW)
	# palais bas, arcades
	_r(img, cx - 130, ty - 10, 260, 46, MID)
	_r(img, cx - 130, ty - 10, 260, 4, LIT)
	_r(img, cx + 90, ty - 10, 40, 46, LIT.lerp(MID, 0.3))
	for q in 14:
		_r(img, cx - 130 + q * 19, ty - 15, 11, 5, LIT)
	for q in 11:
		var ax := cx - 118 + q * 23
		_r(img, ax, ty + 8, 8, 14, SLATE_D)
		_r(img, ax + 1, ty + 6, 6, 2, SLATE_D)
		_r(img, ax + 2, ty + 12, 4, 6, WINDOW)
	for q in 3:   # dômes dorés
		var dx2 := cx - 86 + q * 86
		if q == 1:
			continue
		for r in 12:
			var hw3 := int(sqrt(maxf(0.0, 144.0 - float(r * r))))
			_r(img, dx2 - hw3, ty - 12 - r, hw3 * 2, 1, GOLD.lerp(Color("#fff2b8"), 0.35 if r > 7 else 0.0))
		_r(img, dx2, ty - 28, 1, 5, GOLD_D)
	# la Tour Blanche : quatre fûts qui rétrécissent
	var y := ty - 10
	var widths := [60, 50, 42, 34]
	var heights := [34, 28, 24, 20]
	for q in 4:
		var w: int = widths[q]
		var h: int = heights[q]
		for dx in range(-w / 2, w / 2 + 1):
			var u := float(dx) / float(w / 2)
			_r(img, cx + dx, y - h, 1, h, SHADE.lerp(LIT, clampf(0.45 + u * 0.55, 0.0, 1.0)))
		_r(img, cx - w / 2 - 3, y - h - 4, w + 7, 5, LIT)
		_r(img, cx - w / 2 - 3, y - h + 1, w + 7, 1, SHADE)
		for q2 in (w + 7) / 7:
			_r(img, cx - w / 2 - 3 + q2 * 7, y - h - 8, 4, 4, LIT)
		var by := y - h + 7
		while by < y - 9:
			_r(img, cx - w / 4 - 1, by, 3, 9, WINDOW)
			_r(img, cx + w / 4 - 1, by, 3, 9, WINDOW)
			_r(img, cx - 1, by + 2, 3, 6, SLATE_D)
			by += 16
		y -= h + 4
	# pyramide d'ardoise
	var spire := 44
	var half := 20
	for r in spire:
		var hw4 := int(float(r) * float(half) / float(spire)) + 1
		_r(img, cx - hw4, y - spire + r, hw4, 1, SLATE_D.lerp(SLATE, 0.5))
		_r(img, cx, y - spire + r, hw4, 1, SLATE_L if r % 9 != 0 else SLATE)
	_r(img, cx, y - spire - 24, 2, 25, GOLD)
	_r(img, cx - 1, y - spire - 26, 4, 3, GOLD)
	# étendard bleu nuit au Poirier blanc, à deux queues, qui flotte
	var fy := y - spire - 24
	for fx in 40:
		var wave := int(sin(float(fx) * 0.32) * 2.6)
		var tail := 16 - int(maxf(0.0, float(fx - 28)) * 1.0)
		_r(img, cx + 2 + fx, fy + wave, 1, tail, BLUE.lerp(Color("#3c4f82"), 0.5 if fx % 9 < 3 else 0.0))
	_r(img, cx + 16, fy + 4, 3, 8, LIT)
	_r(img, cx + 13, fy + 3, 9, 3, LIT)
	_r(img, cx + 12, fy + 5, 3, 3, LIT)
	_r(img, cx + 20, fy + 5, 3, 3, LIT)


## L'éperon de roche : un coin dont la pointe regarde la plaine, de la citadelle jusqu'au pied.
static func _spur(img: Image, cx: int, top: int, sd: int) -> void:
	var rock_l := Color("#cdc4b6")
	var rock_m := Color("#9b9284")
	var rock_d := Color("#6c6468")
	for y in range(top, H):
		var t := float(y - top) / float(H - top)
		var half := int(lerpf(5.0, 44.0, pow(t, 0.85))) + int((_n(y / 3, 1, sd) - 0.5) * 5.0)
		for x in range(cx - half, cx + half, 1):
			var u := float(x - cx) / float(half)
			var c := rock_d if u < -0.1 else (rock_l if u > 0.35 else rock_m)
			if _n(x / 2, y / 4, sd) < 0.14:
				c = c.darkened(0.16)
			elif (y / 7 + x / 9) % 5 == 0:
				c = c.lightened(0.07)
			img.set_pixel(clampi(x, 0, W - 1), y, c)
		img.set_pixel(clampi(cx, 0, W - 1), y, Color("#efe8da"))
		img.set_pixel(clampi(cx + 1, 0, W - 1), y, Color("#dcd3c4"))


## La cité vue d'en haut, depuis le belvédère : les étages descendent vers la plaine, du plus
## proche (en bas de l'image, grand) au plus lointain (en haut, petit). Chaque étage montre
## son mur, ses toits d'ardoise vus de dessus, ses jardins.
static func _terraces(img: Image, sd: int, tiers: int) -> void:
	for k in range(tiers - 1, -1, -1):   # le plus lointain d'abord
		var t := float(k) / float(maxi(tiers - 1, 1))   # 0 = proche
		var band := int(lerpf(96.0, 44.0, t))
		var yb := H - 6
		for j in k:
			yb -= int(lerpf(96.0, 44.0, float(j) / float(maxi(tiers - 1, 1)))) + 4
		var ytop := yb - band
		var wall_h := int(lerpf(30.0, 14.0, t))
		var sc := lerpf(1.0, 0.55, t)
		var hw := W / 2 - 4
		for x in range(W / 2 - hw, W / 2 + hw):
			var d := float(x - W / 2) / float(hw)
			var curve := int(pow(absf(d), 2.2) * (16.0 + float(k) * 3.0))
			var top := ytop + curve
			var bottom := yb + curve
			# toits vus de dessus : bandes d'ardoise et de pierre
			_r(img, x, top, 1, bottom - top - wall_h, SLATE.lerp(SLATE_L, 0.3 + 0.3 * d))
			if _n(x / int(maxf(5.0 * sc, 2.0)), k * 7, sd) < 0.18:
				_r(img, x, top, 1, bottom - top - wall_h, LIT.lerp(MID, 0.5))
			elif (x / int(maxf(7.0 * sc, 3.0))) % 2 == 0:
				_r(img, x, top + int(float(band) * 0.4), 1, 2, SLATE_D)
			# faîtages et jardins
			var hn := _n(x / int(maxf(9.0 * sc, 3.0)), k * 5 + 1, sd)
			if hn < 0.07:
				_r(img, x, top + 2, 1, int(float(band - wall_h) * 0.55), LEAF.lerp(LEAF_D, 0.3))
			elif hn > 0.9:
				_r(img, x, top + int(float(band) * 0.2), 1, 2, WINDOW)
			# mur de soutènement
			var wy := bottom - wall_h
			_r(img, x, wy, 1, wall_h, SHADE.lerp(MID, 0.45 + 0.5 * clampf(0.4 + 0.5 * d, 0.0, 1.0)))
			_r(img, x, wy, 1, 2, LIT)
			if (x / maxi(int(6.0 * sc), 2)) % 2 == 0:
				_r(img, x, wy - 3, 1, 3, LIT.lerp(MID, 0.3))
			if (wy + 6) < bottom:
				img.set_pixel(x, mini(wy + int(float(wall_h) * 0.5), H - 1), JOINT)
			_r(img, x, bottom - 2, 1, 3, DEEP)
	# bannières le long du premier mur
	var bx := 40
	while bx < W - 30:
		var d2 := float(bx - W / 2) / float(W / 2 - 4)
		var by := H - 6 - 30 + int(pow(absf(d2), 2.2) * 16.0)
		_r(img, bx, by - 20, 7, 20, BLUE)
		_r(img, bx + 3, by - 16, 1, 9, LIT)
		_r(img, bx + 1, by - 13, 5, 2, LIT)
		bx += 110


# ================================================================= la montagne

static func _ridge_h(x: int, sd: int, cx: int, peak: float) -> float:
	var f := float(x - cx)
	var mass := exp(-pow(f / 380.0, 2.0)) * (0.82 + 0.18 * absf(sin(float(x) * 0.013 + float(sd))))
	var side := 0.62 * exp(-pow((f - 560.0) / 190.0, 2.0)) + 0.55 * exp(-pow((f + 600.0) / 210.0, 2.0)) + 0.3 * exp(-pow((f - 1000.0) / 160.0, 2.0)) + 0.34 * exp(-pow((f + 1010.0) / 170.0, 2.0))
	var jag := sin(float(x) * 0.043 + float(sd)) * 9.0 + sin(float(x) * 0.117 + float(sd) * 2.0) * 5.0
	return float(H) * (0.2 + peak * 0.74 * maxf(mass, side * peak)) + jag * (0.35 + mass)


## Bruit de valeur lissé (continu en x) : pas de couture entre deux cases de bruit.
static func _vn(fx: float, y: int, sd: int) -> float:
	var i := int(floorf(fx))
	var t := smoothstep(0.0, 1.0, fx - floorf(fx))
	return lerpf(_n(i, y, sd), _n(i + 1, y, sd), t)


## Un massif enneigé, éclairé par la droite : crêtes et ravins obliques à arêtes franches (cinq tons de roche,
## cinq de neige), calotte de neige qui descend en langues dans les ravins, pied noyé dans l'ombre bleutée.
## Pas de bandes verticales : l'éclairage vient de la pente lissée, puis des facettes qui suivent la crête.
static func _mountain(img: Image, sd: int, off: int, peak: float) -> void:
	var cx := W / 2 + off
	var rock: Array[Color] = []
	var snow: Array[Color] = []
	for i in 5:
		var k := float(i) / 4.0
		rock.append(Color("#3f4b6c").lerp(Color("#93a4c8"), k))
		snow.append(Color("#a4b6de").lerp(Color("#fbfdff"), k))
	var valley := Color("#586a96")
	var snow_line := int(float(H) * 0.5)
	for x in W:
		var h := _ridge_h(x, sd, cx, peak)
		var top := H - int(h)
		var slope := (_ridge_h(x + 36, sd, cx, peak) - _ridge_h(x - 36, sd, cx, peak)) * 0.5   # < 0 : descend vers la droite = face au soleil
		var l0 := clampf(0.5 - slope * 0.012, 0.1, 0.9)
		# longueur d'onde des facettes : change par tronçon de crête
		var per := 50.0
		var tongue := _vn(float(x) / 14.0, 3, sd) * 30.0 + _vn(float(x) / 40.0, 4, sd) * 34.0
		var snow_to := top
		if top < snow_line:
			snow_to = mini(H, top + int((float(snow_line) - float(top)) * 0.85 + tongue - 16.0))
		for y in range(maxi(top, 0), H):
			var d := y - top
			var u := float(x) + float(d) * 1.35
			var f := fposmod(u / per + _vn(u / 160.0, 11, sd) * 1.6 + _vn(float(d) / 60.0, 12, sd) * 0.5, 1.0)
			var tri := 1.0 - absf(f * 2.0 - 1.0)   # 0..1 : flanc éclairé puis flanc à l'ombre
			var facet := 0.26 if f < 0.5 else -0.26
			facet *= clampf(0.35 + tri, 0.0, 1.0)
			var lit := clampf(l0 + facet, 0.0, 1.0)
			var q := int(floorf(lit * 4.0 + 0.5))
			var c: Color = rock[q]
			if y < snow_to:
				c = snow[q]
				if y >= snow_to - 2:
					c = c.darkened(0.1)
			# pied : ombre bleutée de la vallée, de plus en plus marquée vers le bas
			var foot := clampf(float(y - (H - 120)) / 120.0, 0.0, 1.0)
			c = c.lerp(valley, 0.1 + foot * 0.35)
			img.set_pixel(x, y, c)
		# arête éclairée
		if top >= 0 and top < H:
			img.set_pixel(x, top, snow[4] if top < snow_line else rock[4])


## Rang de collines : champs, bosquets sombres, toits de hameau, pente éclairée à droite.
static func _hills(img: Image, sd: int, peak: float, trees: int) -> void:
	var tones: Array = [Color("#6f86a8"), Color("#5f7c88"), Color("#57764f")]
	for layer in 3:
		var base_y := float(H) * (1.0 - peak * (0.42 + 0.3 * float(layer)))
		var col: Color = tones[layer]
		for x in W:
			var fx := float(x)
			var hh := sin(fx * 0.0075 + float(sd + layer * 5)) * 26.0 + sin(fx * 0.019 + float(layer) * 3.0) * 13.0 + sin(fx * 0.047 + float(sd)) * 4.0 + (_n(x / 6, layer, sd) - 0.5) * 5.0
			var top := int(base_y + hh)
			var slope := cos(fx * 0.0075 + float(sd + layer * 5))
			var c := col.lerp(Color("#cfe0c0"), clampf(0.12 + slope * 0.1, 0.0, 0.3))
			_r(img, x, top, 1, H - top, c)
			_r(img, x, top, 1, 2, c.lightened(0.2))
			# champs : bandes plus claires
			if (x / 38 + layer) % 3 == 0 and layer > 0:
				_r(img, x, top + 10 + layer * 5, 1, 14, c.lightened(0.1))
			# bosquets
			if trees > 0 and _n(x / 3, layer + 40, sd) < 0.22 and layer > 0:
				var tr := 2 + int(_n(x, layer, sd) * 3.0)
				_disc(img, x, top + 4 + int(_n(x, 9, sd) * 16.0), tr, c.darkened(0.3))
			if layer == 2 and _n(x / 24, 77, sd) < 0.05:
				_r(img, x, top + 14, 4, 3, Color("#d9d0c0"))
				_r(img, x - 1, top + 11, 6, 3, SLATE)


static func _ridge(img: Image, sd: int, peak: float) -> void:
	var col := Color("#8393b2")
	for x in W:
		var fx := float(x)
		var h := (sin(fx * 0.006 + float(sd)) * 0.5 + 0.5) * 60.0 + sin(fx * 0.017 + 2.0) * 16.0 + (_n(x / 4, 2, sd) - 0.5) * 8.0
		var top := int(float(H) * (1.0 - peak) - h * 0.8)
		_r(img, x, top, 1, H - top, col)
		_r(img, x, top, 1, 1, col.lightened(0.16))


# ================================================================ la plaine du siège

## L'armée du siège vue de loin : crêtes, rangées de tentes éclairées, forêt de piques, étendards,
## trébuchets, tours de siège, feux qui luisent, colonnes de fumée qui penchent.
static func _plain(img: Image, sd: int, nfires: int, scale: float) -> void:
	var ground := H - 10
	var ridge := Color("#5c5260")
	for x in W:
		var top := ground - int(54.0 * scale) - int(sin(float(x) * 0.007 + float(sd)) * 14.0 + sin(float(x) * 0.023) * 6.0 + _n(x / 5, 4, sd) * 5.0)
		_r(img, x, top, 1, ground - top, ridge)
		_r(img, x, top, 1, 1, ridge.lightened(0.14))
	var tent_cols := [Color("#b4784c"), Color("#8e92a2"), Color("#c0503c"), Color("#7a8a5a"), Color("#d2bc8e")]
	var fire_pos: Array = []
	var rows := 5
	for rr in rows:
		var row := rows - 1 - rr   # du fond vers le devant : les rangs proches recouvrent les lointains
		var sc := (1.0 - float(row) * 0.14) * scale
		var base := ground - 2 - row * int(12.0 * scale)
		var x := int(_n(row, 0, sd) * 30.0)
		var i := 0
		while x < W:
			var w := int((15.0 + _n(i, row, sd) * 15.0) * sc)
			var hh := int(float(w) * 0.8)
			var tc: Color = tent_cols[int(_n(i, row + 3, sd) * 5.0) % 5]
			tc = tc.darkened(float(row) * 0.06)
			for r in hh:
				var hw2 := int(float(w) * 0.5 * float(r + 1) / float(hh))
				_r(img, x + w / 2 - hw2, base - hh + r, hw2 * 2 + 1, 1, tc)
			_r(img, x + w / 2 + 1, base - hh, 1, hh, tc.darkened(0.22))
			_r(img, x + w / 2 - 1, base - hh, 1, hh, tc.lightened(0.14))
			_r(img, x + w / 2, base - hh - 5, 1, 5, Color("#3a2e2a"))
			_r(img, x + w / 2 + 1, base - hh - 5, 5, 3, BLUE if _n(i, row, sd + 9) < 0.5 else Color("#8a2236"))
			_r(img, x + w / 2 - 1, base - 4, 3, 4, Color("#2a1e1c"))   # entrée de la tente
			var roll := _n(i, row + 20, sd)
			if roll < 0.12 and row < 4:
				fire_pos.append(Vector2i(x + w + 3, base))
			elif roll < 0.18:
				_trebuchet(img, x + w + 8, base, sc)
			elif roll < 0.22 and row < 3:
				_siege_tower(img, x + w + 8, base, sc)
			elif roll < 0.27:
				_ram(img, x + w + 8, base, sc)
			elif roll < 0.50:
				_ranks(img, x + w + 3, base, sc, sd + i)
			x += w + int((6.0 + _n(i, row + 40, sd) * 22.0) * sc)
			i += 1
	_r(img, 0, ground, W, H - ground, Color("#43362f"))
	var shown := 0
	for fp: Vector2i in fire_pos:
		if shown >= nfires:
			break
		shown += 1
		_fire(img, fp.x, fp.y, sd + shown, scale)
		fires.append(Vector2(fp.x + 1, fp.y - 4))


## Une troupe en rangs serrés : colonnes de soldats alignés (casque, corps, pique), étendard haut au milieu.
static func _ranks(img: Image, x: int, y: int, sc: float, sd: int) -> void:
	var cols := 6 + int(_n(x, y, sd) * 5.0)
	var step := maxi(3, int(4.0 * sc))
	var hs := maxi(5, int(8.0 * sc))
	for rw in 3:
		var shade := Color("#2c2530").lightened(0.07 * float(2 - rw))
		var ry := y - rw * maxi(2, int(3.0 * sc))
		for q in cols:
			var qx := x + q * step
			_r(img, qx, ry - hs, 2, hs, shade)   # corps
			_r(img, qx, ry - hs - 2, 2, 2, Color("#8a8484") if rw == 0 else shade.lightened(0.2))   # casque
			if rw == 0 or q % 2 == 0:
				var ph := int((16.0 + _n(q, x + rw, sd) * 8.0) * sc)
				_r(img, qx + 1, ry - hs - ph, 1, ph, shade)   # pique
				_r(img, qx + 1, ry - hs - ph - 2, 1, 2, Color("#d8d0c8"))
	var px := x + (cols / 2) * step
	var ph2 := int(40.0 * sc)
	_r(img, px, y - ph2, 1, ph2 + 2, Color("#3a2e2a"))   # hampe de l'étendard
	var fw := maxi(8, int(12.0 * sc))
	var fh := maxi(5, int(8.0 * sc))
	_r(img, px + 1, y - ph2, fw, fh, Color("#a82a3c"))
	_r(img, px + 1, y - ph2, fw, 1, Color("#d4506a"))
	_r(img, px + 1 + fw / 2 - 1, y - ph2 + fh / 2 - 1, 2, 2, Color("#f4efe4"))
	_r(img, px + 1 + fw, y - ph2 + 1, 2, fh - 2, Color("#a82a3c"))   # pointe flottante
	_r(img, px - 1, y - ph2 - 2, 3, 2, GOLD)


## Un feu de camp et sa colonne de fumée, en gros pixels ombrés (pas de points épars).
static func _fire(img: Image, x: int, y: int, sd: int, scale: float) -> void:
	var hgt := int((110.0 + _n(x, y, sd) * 110.0) * scale)
	var k := 6
	while k < hgt:
		var t := float(k) / float(hgt)
		var r := 3 + int(t * 13.0 * scale)
		var cxk := x + int(t * t * 50.0 + sin(t * 8.0 + float(sd)) * 3.0)
		# fumée fondue : plus on monte, plus elle est large, claire et transparente (pas de boules)
		var a := 0.55 * pow(1.0 - t, 1.3)
		var tone := Color("#3e383c").lerp(Color("#9a9498"), t)
		var cy := y - 6 - k
		for yy in range(maxi(cy - r, 0), mini(cy + r + 1, H)):
			for xx in range(maxi(cxk - r, 0), mini(cxk + r + 1, W)):
				var dx := float(xx - cxk)
				var dy := float(yy - cy)
				var f := 1.0 - sqrt(dx * dx + dy * dy) / float(r)
				if f <= 0.0:
					continue
				var al := a * minf(f * 2.2, 1.0) * 0.8
				var o := img.get_pixel(xx, yy)
				img.set_pixel(xx, yy, Color(o.r + (tone.r - o.r) * al, o.g + (tone.g - o.g) * al, o.b + (tone.b - o.b) * al, maxf(o.a, al)))
		k += maxi(r / 3, 2)
	_r(img, x - 2, y - 3, 6, 3, Color("#ff6a14"))
	_r(img, x - 1, y - 6, 4, 4, Color("#ffd24a"))
	_r(img, x, y - 8, 2, 3, Color("#fff2a0"))


## Trait épais (t pixels) : les machines de siège sont des silhouettes sombres, nettes, au liseré clair côté soleil.
static func _tl(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color, t: int, horizontal: bool = false) -> void:
	for o in t:
		if horizontal:
			PA.line(img, x0, y0 + o, x1, y1 + o, c)
		else:
			PA.line(img, x0 + o, y0, x1 + o, y1, c)


static func _wheel(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	_disc(img, cx, cy, r, c)
	_disc(img, cx, cy, maxi(1, r - 2), c.lightened(0.18))
	_disc(img, cx, cy, 1, c)


## Trébuchet armé : portique en A, bras long qui plonge à gauche avec sa fronde, contrepoids qui pend à droite.
static func _trebuchet(img: Image, x: int, y: int, sc: float) -> void:
	var c := Color("#2a2026")
	var e := Color("#8a7060")
	var h := int(46.0 * sc)
	var bw := int(34.0 * sc)
	var ax := x + bw / 2
	_tl(img, x, y - 4, ax - 1, y - h, c, 3)
	_tl(img, x + bw, y - 4, ax + 1, y - h, c, 3)
	_tl(img, x + bw + 3, y - 4, ax + 3, y - h, e, 1)
	_r(img, x - 5, y - 5, bw + 12, 5, c)
	_r(img, x + bw / 4, y - h / 2, bw / 2 + 2, 3, c)
	var ex := ax - int(40.0 * sc)
	var ey := y - h + int(24.0 * sc)
	var sx := ax + int(15.0 * sc)
	var sy := y - h - int(10.0 * sc)
	_tl(img, ex, ey, sx, sy, c, 3, true)
	_tl(img, ex, ey - 1, sx, sy - 1, e, 1, true)
	var cw := maxi(8, int(11.0 * sc))
	_r(img, sx - cw / 2, sy, cw, int(13.0 * sc), c)
	_r(img, sx + cw / 2 - 2, sy, 2, int(13.0 * sc), e)
	_r(img, ex, ey, 1, int(8.0 * sc), c)
	_disc(img, ex, ey + int(10.0 * sc), maxi(3, int(4.0 * sc)), c)
	_wheel(img, x + 3, y - 3, maxi(3, int(4.0 * sc)), c)
	_wheel(img, x + bw - 1, y - 3, maxi(3, int(4.0 * sc)), c)


## Tour d'assaut : grande caisse de bois sur roues, étages à meurtrières, créneaux, fanion.
static func _siege_tower(img: Image, x: int, y: int, sc: float) -> void:
	var c := Color("#33282c")
	var e := Color("#7a6a60")
	var w := int(28.0 * sc)
	var h := int(74.0 * sc)
	_r(img, x, y - h, w, h - 4, c)
	_r(img, x + w - 3, y - h, 3, h - 4, e)
	_r(img, x, y - h, 2, h - 4, c.darkened(0.3))
	for q in 3:
		var fy := y - h + int(float(q + 1) * float(h) * 0.24)
		_r(img, x + 4, fy, w - 8, 3, Color("#120c10"))
		_r(img, x, fy + 6, w, 2, c.lightened(0.12))
	PA.line(img, x + 2, y - 6, x + w - 3, y - h + 8, c.darkened(0.35))
	PA.line(img, x + w - 3, y - 6, x + 2, y - h + 8, c.darkened(0.35))
	_r(img, x - 3, y - h - 5, w + 6, 5, c.lightened(0.08))
	for q in (w + 6) / 6:
		_r(img, x - 3 + q * 6, y - h - 9, 3, 4, c.lightened(0.08))
	_r(img, x + w / 2, y - h - 22, 1, 14, Color("#3a2e2a"))
	_r(img, x + w / 2 + 1, y - h - 22, 9, 6, Color("#a82a3c"))
	_r(img, x - 12, y - h + 8, 10, 3, c)   # pont-levis relevé
	_wheel(img, x + 5, y - 3, maxi(3, int(5.0 * sc)), c)
	_wheel(img, x + w - 5, y - 3, maxi(3, int(5.0 * sc)), c)


## Bélier : toit en pente sur roues, tronc ferré qui dépasse devant.
static func _ram(img: Image, x: int, y: int, sc: float) -> void:
	var c := Color("#33282c")
	var e := Color("#8a7a6e")
	var w := int(44.0 * sc)
	var h := int(22.0 * sc)
	for r in h:
		var inset := int(float(h - r) * 0.5)
		_r(img, x + inset, y - 6 - h + r, w - inset * 2, 1, c)
	_r(img, x + w / 2, y - 6 - h, w / 2 - int(float(h) * 0.5), 1, e)
	for q in 4:
		_r(img, x + int(float(w) * 0.12) + q * (w / 5), y - 6 - h / 2, 2, h / 2, c.darkened(0.3))
	_r(img, x - int(16.0 * sc), y - 6 - h / 3, w + int(24.0 * sc), maxi(3, int(5.0 * sc)), Color("#51402f"))
	_r(img, x - int(20.0 * sc), y - 7 - h / 3, int(6.0 * sc), maxi(4, int(7.0 * sc)), Color("#6a6a74"))
	_wheel(img, x + 6, y - 3, maxi(3, int(5.0 * sc)), c)
	_wheel(img, x + w - 6, y - 3, maxi(3, int(5.0 * sc)), c)


# ============================================================== le pays ennemi

## Massif de basalte noir et rouge (Montagne du Festin) : facettes éclairées par la droite, coulées de braise
## qui descendent de la crête (pixels vifs : le shader les fait briller) et, au sommet, la Tour de la Barbaque,
## son Œil fendu, ses fenêtres et son panache de fumée.
static func _massif(img: Image, sd: int, off: int, peak: float, tower: bool) -> void:
	var cx := W / 2 + off
	var rock: Array[Color] = []
	for i in 5:
		rock.append(Color("#170a10").lerp(Color("#7c3c3c"), float(i) / 4.0))
	var valley := Color("#3a1418")
	var tops: Array[int] = []
	for x in W:
		var h := _ridge_h(x, sd, cx, peak)
		var top := H - int(h)
		tops.append(top)
		var slope := (_ridge_h(x + 36, sd, cx, peak) - _ridge_h(x - 36, sd, cx, peak)) * 0.5
		var l0 := clampf(0.42 - slope * 0.012, 0.05, 0.85)
		var per := 46.0
		for y in range(maxi(top, 0), H):
			var d := y - top
			var u := float(x) + float(d) * 1.35
			var f := fposmod(u / per + _vn(u / 150.0, 11, sd) * 1.6 + _vn(float(d) / 60.0, 12, sd) * 0.5, 1.0)
			var tri := 1.0 - absf(f * 2.0 - 1.0)
			var facet := 0.24 if f < 0.5 else -0.24
			facet *= clampf(0.35 + tri, 0.0, 1.0)
			var q := int(floorf(clampf(l0 + facet, 0.0, 1.0) * 4.0 + 0.5))
			var c: Color = rock[q]
			var foot := clampf(float(y - (H - 110)) / 110.0, 0.0, 1.0)
			img.set_pixel(x, y, c.lerp(valley, 0.1 + foot * 0.4))
		if top >= 0 and top < H:
			img.set_pixel(x, top, rock[4].lightened(0.1))
	# coulées de braise : des fils sinueux qui partent de la crête
	for k in 9:
		var x0 := cx + int((float(k) - 4.0) * 70.0 + (_n(k, 3, sd) - 0.5) * 50.0)
		var ph := _n(k, 5, sd) * 6.0
		var y0 := H - int(_ridge_h(clampi(x0, 0, W - 1), sd, cx, peak)) + 6
		var len := 70 + int(_n(k, 7, sd) * 120.0)
		for j in len:
			var y := y0 + j
			var px := x0 + int(sin(float(j) * 0.09 + ph) * 8.0) + j / 5
			if px < 1 or px >= W - 1 or y >= H or y < 0 or y < tops[px]:
				continue
			var hot := Color("#ff9a30") if j % 7 < 5 else Color("#ffd060")
			var wd := 2 if j % 11 < 7 else 1
			_r(img, px, y, wd, 1, hot)
	if tower:
		var low := 0
		for xx in range(cx - 30, cx + 31):
			low = maxi(low, tops[clampi(xx, 0, W - 1)])
		for r in 40:   # socle de roche : la tour pousse sur l'arête, pas dans le vide
			var hw := 40 + r
			_r(img, cx - hw, low + 8 - 6 + r, hw * 2, 1, rock[1 + (r / 14) % 2])
		_barbaque(img, cx, low + 8, sd)


## La Tour de la Barbaque : trois étages de basalte, créneaux, fenêtres de braise, l'Œil fendu tout en haut.
static func _barbaque(img: Image, cx: int, base: int, sd: int) -> void:
	var dark := Color("#0c060a")
	var lit := Color("#3c1c26")
	var edge := Color("#5a2a30")
	var tiers: Array = [[46, 30], [34, 28], [24, 24], [14, 18]]   # [largeur, hauteur]
	var y := base
	for ti: Array in tiers:
		var wd: int = ti[0]
		var hg: int = ti[1]
		_r(img, cx - wd / 2, y - hg, wd, hg, dark)
		_r(img, cx + wd / 2 - 5, y - hg, 5, hg, lit)
		_r(img, cx - wd / 2 - 2, y - hg - 3, wd + 4, 3, edge)
		for m in range(cx - wd / 2 - 2, cx + wd / 2 + 2, 6):
			_r(img, m, y - hg - 7, 3, 4, dark)
		# fenêtres de braise
		for fx in range(cx - wd / 2 + 5, cx + wd / 2 - 7, 11):
			var fy := y - hg + 8 + int(_n(fx, y, sd) * 10.0)
			_r(img, fx, fy, 3, 5, Color("#ff9a30"))
			_r(img, fx + 1, fy + 1, 1, 3, Color("#ffd878"))
		y -= hg + 3
	# pointes
	for sx: int in [-6, -2, 2, 6]:
		_r(img, cx + sx, y - 10 - abs(sx), 2, 10 + abs(sx), dark)
	# l'Œil : une amande de feu fendue d'une pupille noire
	var ey := y + 26
	for dx in range(-9, 10):
		var hh := int(sqrt(maxf(0.0, 1.0 - pow(float(dx) / 9.5, 2.0))) * 6.0)
		_r(img, cx + dx, ey - hh, 1, hh * 2 + 1, Color("#ff7a1a") if absi(dx) > 4 else Color("#ffc040"))
	_r(img, cx - 1, ey - 5, 3, 11, Color("#140608"))
	# panache de fumée qui dérive vers la gauche
	for i in 9:
		var px := cx - 4 - i * 14
		var py := y + 6 + int(sin(float(i) * 0.8) * 5.0) + i * 2
		_puff(img, px, py, 7 + i, Color("#2a1618"), Color("#6a4038"))


## Armée du pays ennemi, de loin : rangs de lances, tentes noires, feux de camp et fanions rouges.
static func _horde(img: Image, sd: int, nfires: int, scale: float) -> void:
	var ground := H - 38
	_r(img, 0, ground, W, H - ground, Color("#2a1210"))
	for i in 150:
		var x := int(_n(i, 1, sd) * float(W))
		var hg := 10 + int(_n(i, 2, sd) * 14.0 * scale)
		var wd := 8 + int(_n(i, 3, sd) * 12.0)
		var c := Color("#1a0a0e").lerp(Color("#3c1a20"), _n(i, 4, sd))
		var gy := ground - int(_n(i, 5, sd) * 22.0)
		for r in hg:   # tente en pointe
			var hw := int(float(wd) * 0.5 * (1.0 - float(r) / float(hg)))
			_r(img, x - hw, gy - r, hw * 2 + 1, 1, c)
		if _n(i, 6, sd) < 0.3:
			_r(img, x, gy - hg - 12, 1, 12, Color("#1a0a0e"))
			_r(img, x + 1, gy - hg - 12, 6, 4, Color("#a01a1a"))
	for i in nfires:
		var fx := int(_n(i, 9, sd) * float(W - 20)) + 10
		var fy := ground - 4 - int(_n(i, 10, sd) * 24.0)
		_r(img, fx - 3, fy - 3, 7, 3, Color("#ff7a14"))
		_r(img, fx - 1, fy - 7, 4, 5, Color("#ffd24a"))
		fires.append(Vector2(fx, fy - 4))
