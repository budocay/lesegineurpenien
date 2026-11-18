extends "res://src/gfx/character_items.gd"
## Têtes des personnages : visage, cheveux, barbes, chapeaux, capuches.
## Vues : 0 face, 1 profil (regard vers la gauche), 2 dos.
## Tout est en pixels réels de la planche (voir char_kit.gd).


# ------------------------------------------------------------------ face / dos

## Vrai si le personnage est âgé (cheveux ou barbe blancs) : sourcils fournis, paupières lourdes.
static func _elder(look: Dictionary) -> bool:
	var h := _col(look, "hair", "#6b4a2e")
	if str(look.get("beard", "none")) != "none":
		h = _col(look, "beard_color", "#d9d9e0")
	return h.get_luminance() > 0.5 and str(look.get("hair_style", "")) != "chignon"


static func _head_front(look: Dictionary, cx: float, back: bool, item: String) -> void:
	var hcy := _hcy
	var rx := _rx
	var ry := _ry
	var skin: Array = _c["skin"]
	var hat := str(look.get("hat", "none"))
	var hair_style := str(look.get("hair_style", "court"))
	_fk = str(look.get("face", ""))
	if hat == "capuche":
		_hood_back(cx, hcy, rx, ry, 0)
	if hair_style == "boucles" or hair_style == "chignon":
		_hair_volume(cx, hcy, rx, ry, hair_style, 0)
	# oreilles
	for s: int in [-1, 1]:
		var ex := cx + float(s) * (rx - 0.2)
		_ell(ex, hcy + 2.5, 2.7, 3.7, skin)
		if not back:
			_put(int(round(ex - 0.5)) + (1 if s < 0 else 0), int(hcy) + 2, skin[1])
			_put(int(round(ex - 0.5)) + (1 if s < 0 else 0), int(hcy) + 3, skin[1])
	_ell(cx, hcy, rx, ry, skin)
	# menton : un peu de mâchoire
	_ell(cx, hcy + ry - 3.0, rx * 0.66, 3.6, skin, -0.1)
	if not back:
		_face(look, cx, hcy)
	var beard := str(look.get("beard", "none"))
	if beard != "none":
		_beard_front(look, cx, hcy, rx, ry, back)
	if not back:
		_mouth(cx, hcy + 8.0, str(_p["mouth"]), beard == "moustache" or beard == "courte" or beard == "longue")
	_hair(cx, hcy, rx, ry, hair_style, 0 if not back else 2)
	if str(look.get("ears", "")) == "elfe":
		for s: int in [-1, 1]:
			_cap(cx + float(s) * (rx + 1.0), hcy + 2.5, cx + float(s) * (rx + 9.0), hcy - 6.0, 2.4, 0.6, skin)
			_cap(cx + float(s) * (rx + 2.0), hcy + 1.8, cx + float(s) * (rx + 7.0), hcy - 4.0, 0.8, 0.3, [skin[1], skin[1], skin[1], skin[1], skin[1]])
	if item == "pipe" and not back:
		var my := hcy + 9.5
		_cap(cx + 3.5, my + 0.5, cx + 11.0, my - 0.5, 1.3, 1.3, _c["wood"])
		_ell(cx + 12.5, my - 2.8, 3.5, 4.0, _c["wood"])
		_rect(cx + 10.5, my - 6.8, 4.0, 1.5, Color("#3a2410"))
		_put(int(cx) + 12, int(my) - 11, Color(0.85, 0.85, 0.9, 0.9))
		_put(int(cx) + 14, int(my) - 14, Color(0.8, 0.8, 0.88, 0.8))
	_hat(look, cx, hcy, rx, ry, hat, 0 if not back else 2)


static func _face(look: Dictionary, cx: float, hcy: float) -> void:
	var skin: Array = _c["skin"]
	var hr: Array = _c["hair"]
	var ey := int(hcy) + 1
	var mood := str(_p["eyes"])
	var fem := str(look.get("hair_style", "")) == "chignon" or str(look.get("outfit", "")) == "jupe"
	var old := _elder(look)
	var cxi := int(cx)
	var brow_col: Color = (_c["beard"] if old and str(look.get("beard", "none")) != "none" else hr)[1]
	var heavy := _fk in ["las", "hautain", "sournois", "renfrogne", "bourru"]
	for s: int in [-1, 1]:
		var x0 := cxi - 8 if s < 0 else cxi + 4
		_eye(x0, ey, mood, s, fem, old or heavy)
		if mood == "open" and _fk == "las":
			_put(x0 + 1, ey + 5, skin[1])
			_put(x0 + 2, ey + 5, skin[1])
		# sourcils
		var by := ey - 3
		var thick := 2 if (old or _fk == "bourru") else 1
		match mood:
			"angry":
				for i in 5:
					var inner := i if s < 0 else 4 - i
					_put(x0 - 1 + i, by + 1 + inner / 2, brow_col)
					if thick == 2:
						_put(x0 - 1 + i, by + 2 + inner / 2, brow_col)
			"pain":
				for i in 5:
					var inner := i if s < 0 else 4 - i
					_put(x0 - 1 + i, by + 2 - inner / 2, brow_col)
			"ko":
				pass
			_:
				for i in 5:
					var lift := 1 if (i == 0 or i == 4) else 0
					if mood == "closed":
						lift += 1
					elif mood == "open" and _fk != "":
						lift = _brow_dy(i if s < 0 else 4 - i, s)
					_put(x0 - 1 + i, by + lift, brow_col)
					if thick == 2:
						_put(x0 - 1 + i, by + lift + 1, brow_col)
		# joues
		var rose: Color = skin[2].lerp(Color("#e0607a"), 0.45)
		_put(x0 + (0 if s < 0 else 2), ey + 7, rose)
		_put(x0 + 1 + (0 if s < 0 else 2), ey + 7, rose)
		_put(x0 + (0 if s < 0 else 2), ey + 8, skin[3].lerp(rose, 0.4))
	# nez : un petit volume éclairé, avec ses narines
	var nose_w := 2.6 if old else 2.0
	_ell(cx, float(ey) + 5.0, nose_w, 2.6, skin, 0.0)
	_put(cxi - 1, ey + 3, skin[4])
	_put(cxi - 1, ey + 4, skin[3])
	_put(cxi - 1, ey + 7, skin[0])
	_put(cxi, ey + 7, skin[0])
	if old:
		_put(cxi - 2, ey + 6, skin[1])
		_put(cxi + 1, ey + 6, skin[1])


## Décalage vertical d'un point du sourcil selon l'expression du personnage.
## near : 0 (bout extérieur) à 4 (côté du nez) ; s : -1 œil gauche, 1 œil droit, 0 profil.
static func _brow_dy(near: int, s: int) -> int:
	match _fk:
		"las":
			return (1 if near < 2 else 0) - (1 if near == 4 else 0)   # coins tombants
		"bonhomme":
			return 0 if near == 0 or near == 4 else -1                # arqués, hauts
		"vif":
			return -1 if near == 0 else (-2 if near == 2 else -1)
		"renfrogne":
			return 1 + near / 2                                        # froncés, très bas côté nez
		"bourru":
			return 1 + near / 2
		"hautain":
			return (-1 if near != 2 else -2) if s >= 0 else near / 3  # un sourcil levé
		"sournois":
			return (-1 if near != 2 else -2) if s < 0 else 1 + near / 3
		"placide":
			return 0 if near > 0 and near < 4 else 1
	return 1 if (near == 0 or near == 4) else 0


static func _eye(x0: int, ey: int, mood: String, side: int, fem: bool, old: bool) -> void:
	var iris: Array = _c["iris"]
	var lash: Color = iris[0]
	var skin: Array = _c["skin"]
	match mood:
		"closed":
			_put(x0, ey + 2, lash)
			_put(x0 + 1, ey + 3, lash)
			_put(x0 + 2, ey + 3, lash)
			_put(x0 + 3, ey + 2, lash)
			_put(x0 + 1, ey + 4, skin[1])
			_put(x0 + 2, ey + 4, skin[1])
		"pain":
			var o := 0 if side < 0 else 3
			var q := 3 - o
			_put(x0 + o, ey, lash)
			_put(x0 + o + (1 if side < 0 else -1), ey + 1, lash)
			_put(x0 + q, ey + 2, lash)
			_put(x0 + o + (1 if side < 0 else -1), ey + 3, lash)
			_put(x0 + o, ey + 4, lash)
		"ko":
			for i in 4:
				_put(x0 + i, ey + 1 + i, lash)
				_put(x0 + 3 - i, ey + 1 + i, lash)
		_:
			var drop := 1 if mood == "angry" else 0
			# paupière haute
			for i in 4:
				var low := drop if ((side < 0 and i >= 2) or (side > 0 and i <= 1)) else 0
				_put(x0 + i, ey + low, lash)
			# blanc de l'œil, iris, pupille, reflet
			for yy in 3:
				var y := ey + 1 + yy
				_put(x0, y, SCLERA.darkened(0.12) if side < 0 else SCLERA)
				_put(x0 + 3, y, SCLERA if side < 0 else SCLERA.darkened(0.12))
				_put(x0 + 1, y, iris[2] if yy < 2 else iris[3])
				_put(x0 + 2, y, iris[2] if yy < 2 else iris[3])
			_put(x0 + 1, ey + 1, iris[0])
			_put(x0 + 2, ey + 1, iris[0])
			_put(x0 + 1, ey + 2, iris[1])
			_put(x0 + 2, ey + 2, iris[0])
			_put(x0 + 1, ey + 2, WHITE)
			_put(x0 + 2, ey + 3, iris[4])
			if old or mood == "angry":
				# paupière lourde : la moitié du blanc est recouverte
				_put(x0, ey + 1, skin[1])
				_put(x0 + 3, ey + 1, skin[1])
				_put(x0 + 1, ey + 1, skin[1].lerp(lash, 0.55))
				_put(x0 + 2, ey + 1, skin[1].lerp(lash, 0.55))
			if fem:
				var fx := x0 - 1 if side < 0 else x0 + 4
				_put(fx, ey, lash)
				_put(fx, ey - 1, lash)
			# poche sous l'œil
			_put(x0 + 1, ey + 4, skin[1])
			_put(x0 + 2, ey + 4, skin[1])


static func _mouth(cx: float, my: float, mode: String, hidden: bool) -> void:
	var x := int(cx)
	var y := int(my)
	var skin: Array = _c["skin"]
	match mode:
		"open":
			_rect(x - 3.0, y - 1.0, 6.0, 4.0, MOUTH)
			_rect(x - 3.0, y - 1.0, 6.0, 1.0, SCLERA)
			_rect(x - 2.0, y + 2.0, 4.0, 1.0, RED)
			_put(x - 3, y - 1, MOUTH)
			_put(x + 2, y - 1, MOUTH)
		"grit":
			_rect(x - 3.0, y - 1.0, 6.0, 3.0, SCLERA)
			for i in 6:
				_put(x - 3 + i, y - 1, MOUTH if i % 2 == 0 else SCLERA)
				_put(x - 3 + i, y + 1, MOUTH)
			_put(x - 4, y, MOUTH)
			_put(x + 3, y, MOUTH)
		_:
			if not hidden and _fk in ["renfrogne", "bourru"]:
				# bouche tombante
				for i in 4:
					_put(x - 2 + i, y + 1, MOUTH)
				_put(x - 3, y + 2, MOUTH)
				_put(x + 2, y + 2, MOUTH)
				_put(x - 1, y + 2, skin[3])
			elif not hidden and _fk == "las":
				# bouche plate, un peu de travers
				for i in 5:
					_put(x - 2 + i, y + 1, MOUTH)
				_put(x + 3, y + 2, skin[1])
				_put(x - 1, y + 2, skin[3])
			elif not hidden and _fk == "bonhomme":
				# grand sourire, dents, joues
				_put(x - 4, y - 1, skin[1])
				_put(x + 3, y - 1, skin[1])
				_put(x - 3, y, MOUTH)
				_put(x + 2, y, MOUTH)
				for i in 4:
					_put(x - 2 + i, y, SCLERA)
					_put(x - 2 + i, y + 1, MOUTH)
				_put(x - 1, y + 2, skin[3])
				_put(x, y + 2, skin[3])
			elif not hidden and (_fk == "hautain" or _fk == "sournois"):
				# sourire en coin
				_put(x - 2, y + 1, MOUTH)
				_put(x - 1, y + 1, MOUTH)
				_put(x, y + 1, MOUTH)
				_put(x + 1, y, MOUTH)
				_put(x + 2, y, skin[1])
				_put(x - 3, y + 1, skin[1])
				_put(x, y + 2, skin[3])
			elif not hidden:
				_put(x - 3, y - 1, skin[1])
				_put(x - 2, y, MOUTH)
				_put(x - 1, y + 1, MOUTH)
				_put(x, y + 1, MOUTH)
				_put(x + 1, y, MOUTH)
				_put(x + 2, y - 1, skin[1])
				_put(x - 1, y + 2, skin[3])
				_put(x, y + 2, skin[3])
			else:
				_put(x - 1, y + 1, MOUTH)
				_put(x, y + 1, MOUTH)


# ---------------------------------------------------------------- cheveux

## Limite basse des cheveux (coordonnée y) à la distance dx du centre de la tête.
static func _fringe(style: String, dx: float, hcy: float, rx: float, ry: float, view: int) -> float:
	var base := hcy - ry * 0.32
	var adx := absf(dx)
	if view == 2:
		if style == "long":
			return hcy + ry + 16.0
		var u := adx / (rx + 2.4)
		return hcy + ry + 2.0 - u * u * ry * 1.6     # nuque arrondie, pas une barre
	if view == 1:
		if dx < -rx * 0.3:
			var jag := 1.5 if posmod(int(floor(dx / 3.0)), 2) == 0 and style == "court" else 0.0
			return base + 1.0 + jag + (1.0 if style == "chignon" else 0.0)
		if dx < rx * 0.5:
			# tempe : la ligne des cheveux descend jusqu'au-dessus de l'oreille, qui reste dégagée
			var t := clampf((dx + rx * 0.3) / (rx * 0.8), 0.0, 1.0)
			return lerpf(base + 1.5, hcy - 1.2, t)
		return hcy + ry + 16.0 if style == "long" else hcy + ry * 0.78
	if adx > rx * 0.84:
		return hcy + ry * 0.45
	match style:
		"court":
			return base + clampf(dx * 0.28, -2.5, 5.0) + (1.5 if posmod(int(floor(dx / 3.0)), 2) == 0 else 0.0) + 1.5
		"long":
			return base + adx * 0.32 + 1.0
		"boucles":
			return base - 1.0 + sin(dx * 0.55) * 1.8 + 1.5
		_:
			return base + dx * 0.15 + 1.5


static func _hair(hx: float, hcy: float, rx: float, ry: float, style: String, view: int) -> void:
	var hr: Array = _c["hair"]
	var skin: Array = _c["skin"]
	if style == "chauve":
		# couronne de cheveux sur les côtés du crâne, crâne luisant
		if view != 1:
			for s: int in [-1, 1]:
				_ell(hx + float(s) * (rx - 1.5), hcy - 1.0, 2.6, 5.0, hr)
		else:
			_ell(hx + rx - 3.0, hcy - 0.5, 3.4, 6.0, hr)
		_put(int(hx) - 6, int(hcy - ry) + 3, skin[4])
		_put(int(hx) - 5, int(hcy - ry) + 3, skin[4])
		_put(int(hx) - 6, int(hcy - ry) + 4, skin[3])
		return
	var erx := rx + 2.4
	var ery := ry + 2.2
	var ecy := hcy - 1.5
	if style == "boucles":
		erx += 1.4
		ery += 1.2
	for y in range(int(floor(ecy - ery)), int(ceil(ecy + ery)) + 1):
		for x in range(int(floor(hx - erx)), int(ceil(hx + erx)) + 1):
			var nx := (x + 0.5 - hx) / erx
			var ny := (y + 0.5 - ecy) / ery
			if nx * nx + ny * ny > 1.0:
				continue
			var dx := x + 0.5 - hx
			var lim := _fringe(style, dx, hcy, rx, ry, view)
			if y + 0.5 > lim:
				continue
			var tone := _tone(nx, ny * 0.9, 0.0)
			# mèches : bandes sombres et reflets en diagonale
			var q := fposmod(dx * 0.9 + (y - hcy) * 0.7, 6.5)
			if q < 1.0 and tone >= 2:
				tone -= 1
			elif q > 3.0 and q < 3.9 and tone == 2:
				tone = 3
			# bord de la frange : une ligne d'ombre
			if y + 1.5 > lim and view != 2:
				tone = mini(tone, 1)
			_put(x, y, hr[tone])
	# ombre de la frange sur le front
	if view != 2:
		for x in range(int(floor(hx - rx)), int(ceil(hx + rx))):
			var dx := x + 0.5 - hx
			var lim := _fringe(style, dx, hcy, rx, ry, view)
			var yy := int(ceil(lim))
			if absf(dx) < rx * 0.8:
				_shade_px(x, yy, -0.24)
				_shade_px(x, yy + 1, -0.1)
	if style == "long":
		_hair_hang(hx, hcy, rx, ry, view)


## Mèches longues qui retombent devant les épaules.
static func _hair_hang(hx: float, hcy: float, rx: float, ry: float, view: int) -> void:
	var hr: Array = _c["hair"]
	if view == 0:
		for s: int in [-1, 1]:
			var x0 := hx + float(s) * (rx * 0.82 + 2.6)
			_trap(hcy + 1.0, hcy + ry + 14.0, x0 - 3.6, x0 + 3.6, x0 - 2.8, x0 + 2.8, hr, 0.0,
				[Vector2(0.4, 0.3), Vector2(0.75, 0.2)], true)
	elif view == 1:
		_trap(hcy + 2.0, hcy + ry + 15.0, hx + 1.0, hx + rx + 3.5, hx + 3.0, hx + rx + 4.5, hr, -0.1,
			[Vector2(0.3, 0.2), Vector2(0.6, 0.3), Vector2(0.85, 0.2)], true)


## Masse de cheveux longs derrière les épaules (peinte avant le torse).
static func _hair_back(hx: float, hcy: float, rx: float, ry: float, view: int, sway: float) -> void:
	var hr: Array = _c["hair"]
	if view == 1:
		_ell(hx + 3.0, hcy, rx + 3.0, ry + 2.5, hr, -0.3)
		_poly([Vector2(hx + 2.0, hcy - 2.0), Vector2(hx + rx + 5.0, hcy + 2.0), Vector2(hx + rx + 7.0 + sway, hcy + ry + 8.0),
			Vector2(hx + rx + 5.0 + sway, hcy + ry + 14.0), Vector2(hx + 4.0 + sway, hcy + ry + 15.0), Vector2(hx - 2.0, hcy + ry + 9.0)], hr, -0.3)
		# mèches effilées qui suivent le pas
		for k in 3:
			var lx := hx + 5.0 + float(k) * 4.4
			var ln := 22.0 - float(k % 2) * 4.0 + float(k) * 0.8
			_bend(Vector2(lx, hcy + ry + 10.0), Vector2(lx + 1.0 + sway * 0.4, hcy + ry + 10.0 + ln * 0.5),
				Vector2(lx + 0.5 + sway * 0.9, hcy + ry + 10.0 + ln), 2.6, 0.5, hr, -0.25, 8)
		for k in 4:
			var lx2 := hx + 6.0 + float(k) * 3.4
			_line(lx2, hcy + 4.0, lx2 + 1.0 + sway * 0.5, hcy + ry + 15.0, hr[1])
		_line(hx + rx + 1.0, hcy + 1.0, hx + rx + 4.0 + sway * 0.5, hcy + ry + 14.0, hr[3])
		return
	_ell(hx, hcy, rx + 3.0, ry + 2.5, hr, -0.3)
	_trap(hcy, hcy + ry + 14.0, hx - rx - 3.0, hx + rx + 3.0, hx - rx - 4.5, hx + rx + 4.5, hr, -0.3,
		[Vector2(0.28, 0.2), Vector2(0.5, 0.3), Vector2(0.74, 0.25)], false, sway)
	# mèches effilées de longueurs inégales, qui se chevauchent
	for k in 5:
		var lx := hx - rx - 1.5 + float(k) * (rx * 2.0 + 3.0) / 4.0
		var ln := 7.0 - float(k % 2) * 3.0 + (2.0 if k == 2 else 0.0)
		_bend(Vector2(lx, hcy + ry + 11.0), Vector2(lx + sway * 0.3, hcy + ry + 11.0 + ln * 0.5),
			Vector2(lx + sway * 0.8, hcy + ry + 11.0 + ln), 4.6, 0.8, hr, -0.3, 8)


## Volume derrière le crâne : boucles ou chignon.
static func _hair_volume(hx: float, hcy: float, rx: float, ry: float, style: String, view: int) -> void:
	var hr: Array = _c["hair"]
	if style == "chignon":
		var bx := hx + (5.0 if view == 1 else 0.0)
		_ell(bx, hcy - ry - 3.5, 8.0, 6.8, hr)
		_cap(bx - 6.0, hcy - ry - 2.0, bx + 6.0, hcy - ry - 2.0, 1.5, 1.5, _c["band"])
		_put(int(bx) - 3, int(hcy - ry) - 8, hr[4])
		_put(int(bx) - 2, int(hcy - ry) - 8, hr[4])
		return
	# boucles : couronne de petites touffes
	var n := 11
	for i in n:
		var ang := PI + float(i) / float(n - 1) * PI
		var px := hx + cos(ang) * (rx + 1.6)
		var py := hcy - 1.5 + sin(ang) * (ry + 1.2)
		_ell(px, py, 5.4, 5.2, hr)
	for s: int in [-1, 1]:
		_ell(hx + float(s) * (rx + 0.4), hcy + 3.0, 4.2, 5.2, hr)


# ----------------------------------------------------------------------- barbe

static func _beard_front(look: Dictionary, cx: float, hcy: float, rx: float, ry: float, back: bool) -> void:
	if back:
		return
	var kind := str(look.get("beard", "none"))
	var br: Array = _c["beard"]
	var ey := int(hcy) + 1
	if kind == "moustache" or kind == "courte" or kind == "longue":
		# moustache : deux touffes tombantes sous le nez
		for s: int in [-1, 1]:
			_cap(cx + float(s) * 1.4, float(ey) + 7.6, cx + float(s) * 7.2, float(ey) + 9.4, 2.4, 1.5, br)
			_cap(cx + float(s) * 6.6, float(ey) + 9.0, cx + float(s) * 8.0, float(ey) + 11.2, 1.2, 0.7, br)
	if kind == "courte" or kind == "longue":
		for y in range(int(hcy) + 5, int(ceil(hcy + ry + 2.5))):
			for x in range(int(floor(cx - rx - 1.0)), int(ceil(cx + rx + 1.0))):
				var dx := x + 0.5 - cx
				var nx := dx / (rx + 0.9)
				var ny := (y + 0.5 - (hcy + 1.0)) / (ry + 2.0)
				if nx * nx + ny * ny > 1.0:
					continue
				if y + 0.5 < hcy + 8.0 and absf(dx) < rx * 0.8:
					continue
				# bouche dégagée
				if absf(dx) < 3.8 and y + 0.5 > hcy + 8.6 and y + 0.5 < hcy + 12.0 and kind == "courte":
					continue
				var tone := _tone(nx, ny, -0.05)
				if posmod(x + y * 2, 5) == 0:
					tone = maxi(tone - 1, 0)
				_put(x, y, br[tone])
		# bouche entourée de barbe
		if kind == "longue":
			_put(int(cx) - 2, int(hcy) + 10, MOUTH)
			_put(int(cx) - 1, int(hcy) + 10, MOUTH)
			_put(int(cx), int(hcy) + 10, MOUTH)
			_put(int(cx) + 1, int(hcy) + 10, MOUTH)
	if kind == "longue":
		# la barbe tombe sur la poitrine, en mèches qui se séparent en pointe
		var y0 := hcy + ry - 4.0
		var len_b := _th * 0.78
		_poly([Vector2(cx - rx + 2.5, y0), Vector2(cx + rx - 2.5, y0), Vector2(cx + rx - 1.5, y0 + 9.0),
			Vector2(cx + 4.0, y0 + len_b - 4.0), Vector2(cx, y0 + len_b), Vector2(cx - 4.0, y0 + len_b - 4.0),
			Vector2(cx - rx + 1.5, y0 + 9.0)], br, 0.0)
		for k in 4:
			var lx := cx - 7.0 + float(k) * 4.7
			_line(lx, y0 + 5.0, lx * 0.7 + cx * 0.3, y0 + len_b * (0.65 + 0.07 * float(k % 2)) - 2.0, br[1])
		_line(cx - 6.0, y0 + 4.0, cx - 3.0, y0 + len_b * 0.6, br[4])
		# reflet sur la moustache, bouche dégagée par la moustache
		for s: int in [-1, 1]:
			_cap(cx + float(s) * 1.4, float(ey) + 7.6, cx + float(s) * 7.2, float(ey) + 9.4, 2.4, 1.5, br)


static func _beard_side(look: Dictionary, hx: float, hcy: float, rx: float, ry: float) -> void:
	var kind := str(look.get("beard", "none"))
	var br: Array = _c["beard"]
	_cap(hx - rx + 2.5, hcy + 9.0, hx - rx + 9.0, hcy + 10.0, 2.4, 1.6, br)
	if kind == "moustache":
		return
	for y in range(int(hcy) + 5, int(ceil(hcy + ry + 2.5))):
		for x in range(int(floor(hx - rx - 1.0)), int(ceil(hx + rx * 0.2))):
			var nx := (x + 0.5 - hx) / (rx + 0.9)
			var ny := (y + 0.5 - (hcy + 1.0)) / (ry + 2.0)
			if nx * nx + ny * ny > 1.0:
				continue
			if y + 0.5 < hcy + 8.0 and x + 0.5 < hx - rx * 0.1:
				continue
			if kind == "courte" and x + 0.5 < hx - rx + 7.0 and y + 0.5 > hcy + 8.6 and y + 0.5 < hcy + 12.0:
				continue
			var tone := _tone(nx, ny, -0.05)
			if posmod(x + y * 2, 5) == 0:
				tone = maxi(tone - 1, 0)
			_put(x, y, br[tone])
	if kind == "longue":
		# la barbe s'avance sous le menton, s'étire sur la poitrine et finit en pointe
		var y0 := hcy + ry - 3.5
		var len_b := _th * 0.78
		_poly([Vector2(hx - rx * 0.95, y0 - 1.0), Vector2(hx + rx * 0.12, y0 - 3.0), Vector2(hx + rx * 0.38, y0 + 8.0),
			Vector2(hx + 1.5, y0 + len_b * 0.72), Vector2(hx - rx * 0.28, y0 + len_b), Vector2(hx - rx * 0.78, y0 + len_b * 0.6),
			Vector2(hx - rx * 1.08, y0 + 5.5)], br, 0.0)
		for k in 4:
			var lx := hx - rx * 0.72 + float(k) * 3.6
			_line(lx, y0 + 4.0, lerpf(lx, hx - rx * 0.28, 0.6), y0 + len_b * (0.7 + 0.06 * float(k % 2)), br[1])
		_line(hx - rx * 1.0, y0 + 5.5, hx - rx * 0.76, y0 + len_b * 0.55, br[4])
		_cap(hx - rx * 0.28, y0 + len_b - 4.0, hx - rx * 0.22, y0 + len_b + 1.5, 1.6, 0.5, br)


# --------------------------------------------------------------------- chapeaux

static func _hood_back(hx: float, hcy: float, rx: float, ry: float, view: int) -> void:
	var h: Array = _c["hat"]
	var ox := 2.5 if view == 1 else 0.0
	_ell(hx + ox, hcy - 1.0, rx + 5.5, ry + 5.5, h)
	_trap(hcy + ry - 5.0, hcy + ry + 11.0, hx + ox - rx - 5.0, hx + ox + rx + 5.0, hx + ox - rx - 11.0, hx + ox + rx + 11.0, h, -0.1,
		[Vector2(0.25, 0.0), Vector2(0.5, 0.2), Vector2(0.75, 0.0)], true)
	# pointe de la capuche
	_cap(hx + ox, hcy - ry - 3.0, hx + ox + 4.0, hcy - ry - 10.0, 4.4, 1.2, h)


static func _hood_front(hx: float, hcy: float, rx: float, ry: float, view: int) -> void:
	var h: Array = _c["hat"]
	if view == 2:
		_ell(hx, hcy - 1.0, rx + 4.5, ry + 4.2, h, 0.0)
		_rect(hx - 0.5, hcy - ry - 3.0, 1.0, ry * 2.0 + 4.0, h[1])
		_line(hx - 6.0, hcy - 6.0, hx - 4.0, hcy + 8.0, h[1])
		_line(hx + 6.0, hcy - 6.0, hx + 4.0, hcy + 8.0, h[1])
		return
	var ox := -6.0 if view == 1 else 0.0
	var ocx := hx + (2.5 if view == 1 else 0.0)
	var orx := rx + 4.6
	var ory := ry + 4.2
	var icx := hx + ox
	var irx := rx * 0.8 if view == 1 else rx - 1.0
	var iry := ry * 0.86
	for y in range(int(floor(hcy - 1.4 - ory)), int(ceil(hcy - 1.4 + ory)) + 1):
		for x in range(int(floor(ocx - orx)), int(ceil(ocx + orx)) + 1):
			var nx := (x + 0.5 - ocx) / orx
			var ny := (y + 0.5 - (hcy - 1.4)) / ory
			if nx * nx + ny * ny > 1.0:
				continue
			var ix := (x + 0.5 - icx) / irx
			var iy := (y + 0.5 - (hcy + 2.2)) / iry
			var d := ix * ix + iy * iy
			if d <= 1.0:
				continue
			var tone := _tone(nx, ny, 0.0)
			if d < 1.4:
				tone = mini(tone, 1)
			if d < 1.14:
				tone = 0
			_put(x, y, h[tone])
	# plis du tissu
	_line(ocx - orx * 0.55, hcy - ory * 0.5, ocx - orx * 0.72, hcy + ory * 0.3, h[1])
	_line(ocx + orx * 0.5, hcy - ory * 0.6, ocx + orx * 0.7, hcy + ory * 0.2, h[1])


static func _hat(look: Dictionary, hx: float, hcy: float, rx: float, ry: float, kind: String, view: int) -> void:
	if kind == "none":
		return
	var h: Array = _c["hat"]
	var top_y := hcy - ry
	var band: Array = _c["band"]
	var g: Array = _c["gold"]
	var ix := int(hx)
	match kind:
		"magicien":
			_wizard_hat(hx, top_y, rx, view)
		"toque":
			# bonnet de cuisinier : trois bouffants, bandeau plissé
			_ell(hx - 9.0, top_y - 8.0, 10.5, 10.0, h)
			_ell(hx + 9.0, top_y - 9.0, 10.5, 10.0, h)
			_ell(hx, top_y - 14.0, 13.0, 11.5, h)
			_trap(top_y - 3.0, top_y + 6.5, hx - rx - 0.5, hx + rx + 0.5, hx - rx - 1.2, hx + rx + 1.2, h, 0.05,
				[Vector2(0.2, 0.0), Vector2(0.4, 0.0), Vector2(0.6, 0.0), Vector2(0.8, 0.0)])
			_rect(hx - rx - 1.2, top_y + 5.0, (rx + 1.2) * 2.0, 1.5, h[1])
			for i in 5:
				_put(ix - 12 + i * 6, int(top_y) - 4 - (i % 2) * 2, h[1])
				_put(ix - 12 + i * 6, int(top_y) - 5 - (i % 2) * 2, h[1])
			_put(ix - 9, int(top_y) - 18, h[4])
			_put(ix - 8, int(top_y) - 18, h[4])
		"casquette":
			_ell(hx, top_y + 3.5, rx + 1.8, 10.0, h, 0.05, top_y + 5.0)
			_put(ix, int(top_y) - 2, h[4])
			_put(ix - 1, int(top_y) - 2, h[3])
			_line(hx, top_y - 1.0, hx - 1.0, top_y + 8.0, h[1])
			_rect(hx - rx - 1.5, top_y + 5.0, (rx + 1.5) * 2.0, 1.5, h[0])
			_ell(hx, top_y + 4.0, 2.0, 1.6, band, 0.2)
			if view == 0:
				_cast(hx, top_y + 10.0, rx - 1.0, 3.0, -0.26)
				_ell(hx, top_y + 7.0, rx - 0.5, 3.4, h, -0.12)
				_rect(hx - rx + 1.0, top_y + 9.5, (rx - 1.0) * 2.0, 1.5, h[0])
			elif view == 1:
				_cast(hx - rx, top_y + 9.5, 9.0, 3.0, -0.24)
				_ell(hx - rx - 2.5, top_y + 7.0, 10.0, 3.2, h, -0.12)
				_rect(hx - rx - 12.5, top_y + 9.0, 19.0, 1.5, h[0])
			else:
				_rect(hx - 5.0, top_y + 5.0, 10.0, 1.5, h[1])
		"capuche":
			_hood_front(hx, hcy, rx, ry, view)
		"chapeau_paille":
			_cast(hx, top_y + 10.0, rx + 2.0, 3.4, -0.26)
			var brim_cy := top_y + 3.5
			var brx := rx + 15.0
			for y in range(int(floor(brim_cy - 6.4)), int(ceil(brim_cy + 6.4)) + 1):
				for x in range(int(floor(hx - brx)), int(ceil(hx + brx)) + 1):
					var nx := (x + 0.5 - hx) / brx
					var ny := (y + 0.5 - brim_cy) / 6.4
					if nx * nx + ny * ny > 1.0:
						continue
					var tone := 2 if ny < 0.3 else 1
					if ny > 0.78:
						tone = 0
					elif nx < -0.4 and ny < 0.0:
						tone = 3
					# tressage de la paille
					if posmod(x + y * 2, 5) == 0 and tone > 0:
						tone = maxi(tone - 1, 1)
					elif posmod(x * 2 + y, 7) == 0 and tone >= 2:
						tone = 3
					_put(x, y, h[tone])
			# calotte
			for y in range(int(floor(top_y - 12.0)), int(ceil(top_y + 4.5))):
				for x in range(int(floor(hx - rx - 1.0)), int(ceil(hx + rx + 1.0))):
					var nx := (x + 0.5 - hx) / (rx - 0.8)
					var ny := (y + 0.5 - (top_y + 3.0)) / 15.0
					if nx * nx + ny * ny > 1.0:
						continue
					var is_band := y + 0.5 >= top_y - 0.5
					var rr: Array = band if is_band else h
					var tone := _tone(nx, ny * 0.6, 0.0)
					if not is_band and posmod(x + y, 4) == 0 and tone > 1:
						tone -= 1
					_put(x, y, rr[tone])
			# nœud du ruban
			_ell(hx + rx - 4.0, top_y + 1.0, 3.8, 3.4, band, 0.1)
			_cap(hx + rx - 3.5, top_y + 2.5, hx + rx + 0.5, top_y + 8.0, 1.6, 1.1, band)
		"couronne":
			_trap(top_y - 1.0, top_y + 6.0, hx - rx * 0.8, hx + rx * 0.8, hx - rx * 0.88, hx + rx * 0.88, g)
			var n := 5
			for i in n:
				var px := hx - rx * 0.78 + float(i) * (rx * 1.56 / float(n - 1))
				var hgt := 9.0 if i % 2 == 0 else 5.5
				_trap(top_y - 1.0 - hgt, top_y - 0.6, px - 0.7, px + 0.7, px - 3.2, px + 3.2, g)
				_put(int(round(px)), int(round(top_y - 2.0 - hgt)), g[4])
				_put(int(round(px)) - 1, int(round(top_y - 2.0 - hgt)) + 1, WHITE)
			var gem: Array = _c["band"]
			_rect(hx - 2.0, top_y + 1.0, 4.0, 4.0, gem[2])
			_rect(hx - 2.0, top_y + 1.0, 2.0, 2.0, gem[4])
			_rect(hx, top_y + 3.0, 2.0, 2.0, gem[1])
			_put(ix - 9, int(top_y) + 2, WHITE)
			_put(ix + 8, int(top_y) + 3, gem[4])
			_line(hx - rx * 0.8, top_y + 5.0, hx + rx * 0.8, top_y + 5.0, g[0])
		"heaume":
			var dome_top := top_y - 2.5
			_ell(hx, hcy - 2.5, rx + 2.2, ry + 1.8, h, 0.0, hcy - 1.5)
			_rect(hx - rx - 2.0, hcy - 3.5, (rx + 2.0) * 2.0, 3.5, h[1])
			_rect(hx - rx - 2.0, hcy - 3.5, (rx + 2.0) * 2.0, 1.0, h[4])
			_rect(hx - rx - 2.0, hcy - 0.5, (rx + 2.0) * 2.0, 1.0, h[0])
			if view == 0:
				_trap(hcy - 2.0, hcy + 12.0, hx - 2.4, hx + 2.4, hx - 2.2, hx + 2.2, h, 0.1)
				for s: int in [-1, 1]:
					var bx := hx + float(s) * (rx - 2.5)
					_trap(hcy - 2.0, hcy + ry - 5.0, bx - 2.0, bx + 2.0, bx - 2.0, bx + 2.0, h, -0.1)
				_put(ix - 10, int(hcy) - 8, WHITE)
				_put(ix + 9, int(hcy) - 8, h[4])
			elif view == 1:
				_trap(hcy - 2.0, hcy + 10.0, hx - rx + 1.0, hx - rx + 4.5, hx - rx + 1.5, hx - rx + 4.5, h, 0.1)
				_trap(hcy - 2.0, hcy + ry - 2.0, hx + 2.0, hx + 10.0, hx + 2.0, hx + 10.0, h, -0.1)
			if str(look.get("crest", "")) == "cornes":
				for s: int in [-1, 1]:
					_cap(hx + float(s) * (rx - 2.0), dome_top + 7.0, hx + float(s) * (rx + 8.0), dome_top - 8.0, 4.4, 1.4, h)
					_cap(hx + float(s) * (rx + 8.0), dome_top - 8.0, hx + float(s) * (rx + 4.0), dome_top - 17.0, 1.6, 0.8, h, 0.1)
			else:
				_trap(dome_top - 5.0, dome_top + 2.5, hx - 1.4, hx + 1.4, hx - 3.8, hx + 3.8, band)
		"foulard":
			_cast(hx, top_y + 14.0, rx, 3.0, -0.2)
			_ell(hx, top_y + 9.0, rx + 1.8, 11.0, h, 0.0, top_y + 11.5)
			_rect(hx - rx - 1.8, top_y + 10.0, (rx + 1.8) * 2.0, 1.5, h[1])
			for i in 5:
				_put(ix - 14 + i * 7 + (i % 2) * 3, int(top_y) + 3 + (i % 2) * 4, h[4])
				_put(ix - 13 + i * 7 + (i % 2) * 3, int(top_y) + 3 + (i % 2) * 4, h[3])
			var kx := hx + rx - 1.0 if view != 1 else hx + rx + 1.0
			_ell(kx, top_y + 11.0, 5.2, 4.6, h)
			_trap(top_y + 12.5, top_y + 24.0, kx - 4.0, kx + 1.5, kx - 1.5, kx + 5.5, h, 0.0, [], true)
			_trap(top_y + 12.5, top_y + 20.0, kx - 5.0, kx - 1.0, kx - 7.0, kx - 2.5, h, -0.1, [], true)


## Chapeau pointu de magicien : calotte tordue qui s'avachit, bord large et mou, bande, étoiles.
static func _wizard_hat(hx: float, top_y: float, rx: float, view: int) -> void:
	var h: Array = _c["hat"]
	var band: Array = _c["band"]
	var g: Array = _c["gold"]
	var xs := 3.0 if view == 1 else 0.0
	var bx := hx + xs
	# ombre du bord sur le front et le visage
	_cast(hx, top_y + 10.0, rx, 4.4, -0.27)
	_cast(hx, top_y + 14.0, rx - 2.0, 2.2, -0.14)
	# bord large, légèrement ondulé, plus sombre en dessous
	var brim_cy := top_y + 4.0
	var brx := rx + 14.0
	var bry := 5.2
	for y in range(int(floor(brim_cy - bry)), int(ceil(brim_cy + bry)) + 1):
		for x in range(int(floor(bx - brx)), int(ceil(bx + brx)) + 1):
			var nx := (x + 0.5 - bx) / brx
			var wave := sin(nx * 5.0) * 0.9
			var ny := (y + 0.5 - brim_cy - wave) / bry
			if nx * nx + ny * ny > 1.0:
				continue
			var tone := _tone(nx * 0.6, ny * 0.7, 0.12)
			if ny > 0.52:
				tone = mini(tone, 1)
			if ny > 0.82:
				tone = 0
			_put(x, y, h[tone])
	# calotte : cône qui monte, puis la pointe retombe vers l'arrière
	var dirx := 1.0
	var base := Vector2(bx, top_y - 8.0)
	var mid := Vector2(bx - 2.0, top_y - 34.0)
	var tip := Vector2(bx + 20.0 * dirx, top_y - 25.0)
	_trap(top_y - 8.0, top_y + 5.0, bx - rx - 0.6, bx + rx + 0.6, bx - rx - 0.9, bx + rx + 0.9, h, 0.16,
		[Vector2(0.3, 0.0), Vector2(0.62, 0.2)])
	_bend(base, mid, tip, rx + 0.6, 0.9, h, 0.16, 26)
	# plis de la calotte
	for k in 3:
		var t := 0.18 + 0.2 * float(k)
		var q := base.lerp(mid, t).lerp(mid.lerp(tip, t), t)
		_line(q.x - 2.0 + float(k), q.y + 3.0, q.x - 4.0 + float(k), q.y + 10.0, h[1])
	# pli où la pointe s'affaisse
	var kink := base.lerp(mid, 0.62).lerp(mid.lerp(tip, 0.62), 0.62)
	_line(kink.x - 4.0, kink.y + 1.0, kink.x + 3.0, kink.y - 1.0, h[1])
	_line(kink.x - 3.0, kink.y + 2.0, kink.x + 3.0, kink.y, h[0])
	# bande et boucle
	_trap(top_y - 0.5, top_y + 5.0, bx - rx - 0.6, bx + rx + 0.6, bx - rx - 1.0, bx + rx + 1.0, band, 0.0, [], true)
	_rect(bx - 3.0, top_y - 1.5, 6.0, 7.0, g[2])
	_rect(bx - 3.0, top_y - 1.5, 6.0, 1.0, g[4])
	_rect(bx - 3.0, top_y + 4.5, 6.0, 1.0, g[0])
	_rect(bx - 1.0, top_y + 0.5, 2.0, 3.0, g[0])
	_put(int(bx) - 2, int(top_y) - 1, g[4])
	# étoiles dorées sur la calotte
	for st: Vector3 in [Vector3(-6.0, -9.0, 0.0), Vector3(5.0, -16.0, 1.0), Vector3(-2.0, -24.0, 0.0), Vector3(6.0, -30.0, 1.0)]:
		var sx := int(bx + st.x)
		var sy := int(top_y + st.y)
		_put(sx, sy, g[4])
		_put(sx - 1, sy, g[3])
		_put(sx + 1, sy, g[3])
		_put(sx, sy - 1, g[3])
		_put(sx, sy + 1, g[2])
	_put(int(tip.x) + 1, int(tip.y) + 1, g[3])
