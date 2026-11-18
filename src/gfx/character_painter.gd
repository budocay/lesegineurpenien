extends "res://src/gfx/character_head.gd"
## Peint la planche de sprites d'un personnage à partir d'une description (« look »).
##
## Format de la planche générée (voir assets/sprites/README.md) :
##   cases de 88 x 132 px, 11 colonnes, 4 lignes dans l'ordre : bas, gauche, droite, haut.
##   colonnes 0 à 2  : repos (normal, respiration, clignement)
##   colonnes 3 à 6  : marche (contact, passage, contact opposé, passage)
##   colonnes 7 à 10 : combat (attaque, sort, coup reçu, KO)
##
## « species » choisit le corps : grobitte/humain (par défaut), "morfale", "naze"
## (character_species.gd).
##
## Les constantes (FRAME_W, PPU...) et les primitives sont dans char_kit.gd, les têtes
## (visage, cheveux, barbes, chapeaux) dans character_head.gd. Ce fichier assemble le corps :
## jambes, torse et tenue, bras, objet tenu, cape, puis la tête.
## Proportions : environ trois têtes et demie pour les grands, trois pour les Grobittes.

const Species = preload("res://src/gfx/character_species.gd")

static var _portrait_hcy := 52.0


static func paint_sheet(look: Dictionary) -> Image:
	var sheet := PA.new_image(FRAME_W * COLUMNS, FRAME_H * ROWS)
	var c := _colors(look)
	for col in COLUMNS:
		for row in ROWS:
			sheet.blit_rect(_paint_cell(look, c, col, row), Rect2i(0, 0, FRAME_W, FRAME_H), Vector2i(col * FRAME_W, row * FRAME_H))
	_flip = -1
	_lx = -0.5
	return sheet


## Une case de la planche (colonne = pose, ligne = direction).
static func _paint_cell(look: Dictionary, c: Dictionary, col: int, row: int) -> Image:
	var species := str(look.get("species", ""))
	var cell := PA.new_image(FRAME_W, FRAME_H)
	var view := 0
	if row == 1 or row == 2:
		view = 1
	elif row == 3:
		view = 2
	_im = cell
	_c = c
	_p = _pose(col)
	_flip = FRAME_W - 1 if row == 2 else -1
	_lx = 0.5 if row == 2 else -0.5
	match species:
		"morfale":
			Species._morfale(look, view)
		"naze":
			Species._naze(view)
		_:
			match view:
				0:
					_front(look, false)
				1:
					_side(look)
				_:
					_front(look, true)
	_portrait_hcy = _hcy
	_outline()
	_flip = -1
	_lx = -0.5
	return cell


## Portrait 64 x 64 : tête et épaules de face, à la résolution de la planche (le chapeau
## entier, pas de lissage).
static func paint_portrait(look: Dictionary) -> Image:
	var bare := look.duplicate()
	bare["item"] = "none"          # pas de bâton ni de pipe en travers du portrait
	var cell := _paint_cell(bare, _colors(bare), 0, 0)
	var side := 64
	var b := PA.opaque_bounds(cell, Rect2i(0, 0, FRAME_W, FRAME_H))
	var x := (FRAME_W - side) / 2
	var y := clampi(mini(b.position.y - 2, int(_portrait_hcy) - 27), 0, FRAME_H - side)
	return cell.get_region(Rect2i(x, y, side, side))


# ------------------------------------------------------------------ couleurs

static func _colors(look: Dictionary) -> Dictionary:
	var skin := _col(look, "skin", "#e8b48a")
	var boots := str(look.get("feet", "nus")) == "bottes"
	var c := {
		"skin": _skin_ramp(skin),
		"hair": _ramp(_col(look, "hair", "#6b4a2e")),
		"top": _ramp(_col(look, "top", "#4f7d5a")),
		"bottom": _ramp(_col(look, "bottom", "#6b5238")),
		"boot": _ramp(_col(look, "boots", "#4a3426")),
		"hat": _ramp(_col(look, "hat_color", "#6f7390")),
		"beard": _ramp(_col(look, "beard_color", "#d9d9e0")),
		"belt": _ramp(_col(look, "belt", "#4a3426")),
		"band": _ramp(_col(look, "band", "#b0483c")),
		"wood": _ramp(Color("#8a5a34")),
		"apron": _ramp(Color("#efe6d2")),
		"gold": _ramp(Color("#e2b43c")),
		"iron": _ramp(Color("#8a8aa0")),
		"crystal": _ramp(Color("#6fd8ee")),
		"boots": boots,
		"iris": _ramp(_col(look, "eye", "#3a2848")),
		"skin_c": skin,
	}
	if look.has("cape"):
		c["cape"] = _ramp(_col(look, "cape", "#7a2a34"))
	return c


## Pose d'une colonne de la planche.
##   fn / ff : avancée du pied proche / éloigné (profil), ln / lf : hauteur de ce pied levé,
##   an / af : balancement du bras proche / éloigné, sway : la cape et les cheveux qui suivent.
static func _pose(col: int) -> Dictionary:
	var p := {"bob": 0.0, "fn": 2.0, "ff": -2.0, "ln": 0.0, "lf": 0.0, "an": 0.0, "af": 0.0,
		"arms": "down", "eyes": "open", "mouth": "smile", "lean": 0.0, "sway": 0.0}
	match col:
		1:
			p["bob"] = 1.0
			p["sway"] = 1.0
		2:
			p["eyes"] = "closed"
			p["bob"] = 0.5
		3:
			p["fn"] = 10.0
			p["ff"] = -9.0
			p["lf"] = 3.0
			p["an"] = -5.0
			p["af"] = 5.0
			p["bob"] = 1.6
			p["sway"] = 3.0
		4:
			p["fn"] = 0.0
			p["ff"] = 3.0
			p["lf"] = 6.0
			p["an"] = -1.0
			p["af"] = 1.0
			p["bob"] = 0.0
			p["sway"] = 1.0
		5:
			p["fn"] = -9.0
			p["ff"] = 10.0
			p["ln"] = 3.0
			p["an"] = 5.0
			p["af"] = -5.0
			p["bob"] = 1.6
			p["sway"] = -2.0
		6:
			p["fn"] = 3.0
			p["ff"] = 0.0
			p["ln"] = 6.0
			p["an"] = 1.0
			p["af"] = -1.0
			p["bob"] = 0.0
			p["sway"] = -1.0
		7:
			p["arms"] = "strike"
			p["lean"] = 7.0
			p["fn"] = 9.0
			p["ff"] = -7.0
			p["bob"] = 2.0
			p["mouth"] = "open"
			p["eyes"] = "angry"
			p["sway"] = -4.0
		8:
			p["arms"] = "up"
			p["bob"] = -1.0
			p["fn"] = 3.0
			p["ff"] = -3.0
			p["mouth"] = "open"
			p["eyes"] = "closed"
			p["sway"] = 3.0
		9:
			p["arms"] = "flail"
			p["lean"] = -7.0
			p["fn"] = -5.0
			p["ff"] = 5.0
			p["bob"] = 2.0
			p["mouth"] = "grit"
			p["eyes"] = "pain"
			p["sway"] = 5.0
		10:
			# KO : affaissé, jambes repliées, tête rentrée dans les épaules
			p["lean"] = -4.0
			p["mouth"] = "open"
			p["eyes"] = "ko"
			p["bob"] = 9.0
			p["crouch"] = 6.0
			p["fn"] = 5.0
			p["ff"] = -4.0
			p["arms"] = "slump"
			p["sway"] = 2.0
	return p


# ------------------------------------------------------------------ proportions

static func _layout(look: Dictionary) -> void:
	var lh := 27.0
	var th := 26.0
	_rx = 12.0
	_ry = 11.5
	_hs = 10.5
	_bulge = 3.0
	match str(look.get("build", "petit")):
		"grand":
			lh = 36.0
			th = 30.0
			_hs = 11.0
			_bulge = 1.0
		"enfant":
			lh = 19.0
			th = 19.0
			_hs = 8.0
			_bulge = 2.0
	lh = maxf(7.0, lh - float(_p.get("crouch", 0.0)) * 2.0)
	_th = th
	_lh = lh
	_foot = float(FRAME_H - 1 - FOOT_MARGIN)
	_hip = _foot - lh
	_ny = _hip - th + float(_p["bob"])
	_hcy = _ny - _ry + 3.0
	_cx = 44.0


## Longueur du bras (épaule au coude, coude au poignet).
static func _alen() -> float:
	return _th * 0.4


# ------------------------------------------------------------------ face / dos

static func _front(look: Dictionary, back: bool) -> void:
	_layout(look)
	var cx := _cx
	var hs := _hs
	var ny := _ny
	var th := _th
	var outfit := str(look.get("outfit", "tunique"))
	var item := str(look.get("item", "none"))
	var arms := str(_p["arms"])
	var bulge := _bulge
	var belt_y := ny + th * 0.8
	var top: Array = _c["top"]
	var bottom: Array = _c["bottom"]
	var belt: Array = _c["belt"]
	var skin: Array = _c["skin"]
	var hair_style := str(look.get("hair_style", "court"))
	var has_cape := _c.has("cape")
	var cape: Array = _c["cape"] if has_cape else top
	var sway := float(_p["sway"])
	var crouch := float(_p.get("crouch", 0.0))

	# cheveux longs : la masse passe derrière les épaules
	if hair_style == "long" and not back:
		_hair_back(cx, _hcy, _rx, _ry, 0, sway)
	if has_cape and not back:
		_trap(ny + 2.0, _foot - 4.0, cx - hs - 3.0, cx + hs + 3.0, cx - hs - 13.0, cx + hs + 13.0, cape, -0.2,
			[Vector2(0.18, 0.1), Vector2(0.4, 0.0), Vector2(0.62, 0.1), Vector2(0.82, 0.0)], true, sway * 1.5)

	# jambes et pieds
	for s: int in [-1, 1]:
		var lift := float(_p["lf"]) if s < 0 else float(_p["ln"])
		_leg_front(cx + float(s) * 5.6, s, _foot - 4.0 - lift, lift, outfit, back)

	# le haut du corps se déhanche d'un pixel du côté du pied d'appui
	cx += float(signi(int(_p["an"])))

	# cou
	_cap(cx, ny - 4.0, cx, ny + 2.0, 3.8, 3.8, skin)

	# torse
	match outfit:
		"tablier":
			_torso_tunic(cx, belt_y, bulge, top, belt, back, 5.0)
			if not back:
				var ap: Array = _c["apron"]
				var bottom_y := minf(_hip + _lh * 0.28, _foot - 9.0)
				_trap(ny + 8.0, bottom_y, cx - 7.0, cx + 7.0, cx - 10.0, cx + 10.0, ap, 0.0, [Vector2(0.5, 0.4)], true)
				_rect(cx - 5.5, belt_y + 3.0, 11.0, 7.0, ap[1])
				_rect(cx - 5.5, belt_y + 3.0, 11.0, 1.0, ap[3])
				_rect(cx - 5.5, belt_y + 9.0, 11.0, 1.0, ap[0])
				_rect(cx - 5.5, belt_y + 4.0, 1.0, 5.0, ap[3])
				_cap(cx - 6.4, ny + 3.0, cx - 5.2, ny + 8.5, 1.5, 1.5, ap)
				_cap(cx + 6.4, ny + 3.0, cx + 5.2, ny + 8.5, 1.5, 1.5, ap)
				# bavette et poche
				_trap(ny + 7.5, belt_y + 1.5, cx - 6.0, cx + 6.0, cx - 7.0, cx + 7.0, ap, 0.0, [Vector2(0.5, 0.6)])
			else:
				_cap(cx - 5.5, ny + 3.0, cx + 5.5, belt_y, 1.4, 1.4, _c["apron"])
				_cap(cx + 5.5, ny + 3.0, cx - 5.5, belt_y, 1.4, 1.4, _c["apron"])
				_ell(cx, belt_y + 2.5, 3.6, 2.8, _c["apron"])
				_trap(belt_y + 3.0, belt_y + 12.0, cx - 3.2, cx + 3.2, cx - 4.4, cx + 4.4, _c["apron"], -0.05, [], true)
		"jupe":
			_torso_blouse(cx, belt_y, top, back)
			var skirt_end := _foot - 5.0
			_trap(belt_y - 1.0, skirt_end, cx - hs - 1.0, cx + hs + 1.0, cx - hs - 11.5, cx + hs + 11.5, bottom, 0.0,
				[Vector2(0.16, 0.15), Vector2(0.3, 0.3), Vector2(0.44, 0.1), Vector2(0.58, 0.3), Vector2(0.72, 0.1), Vector2(0.86, 0.2)], true, sway * 0.6)
			_trap(belt_y - 1.0, belt_y + 3.0, cx - hs - 1.0, cx + hs + 1.0, cx - hs - 1.0, cx + hs + 1.0, belt)
			_rect(cx - hs - 1.0, belt_y - 1.0, (hs + 1.0) * 2.0, 1.0, belt[4])
			if not back:
				_ell(cx, belt_y + 1.0, 2.4, 2.0, _c["gold"])
		"robe":
			var hem := _foot - 6.0
			_trap(ny, hem, cx - hs + 1.0, cx + hs - 1.0, cx - hs - 10.0, cx + hs + 10.0, top, 0.0,
				[Vector2(0.14, 0.3), Vector2(0.3, 0.1), Vector2(0.46, 0.25), Vector2(0.62, 0.1), Vector2(0.78, 0.3), Vector2(0.9, 0.15)], true, sway * 0.7)
			# ourlet orné
			_trap(hem - 3.0, hem, cx - hs - 9.0 + sway * 0.45, cx + hs + 9.0 + sway * 0.45, cx - hs - 10.0 + sway * 0.5, cx + hs + 10.0 + sway * 0.5, belt, -0.1)
			_trap(belt_y - 2.0, belt_y + 2.5, cx - hs - bulge, cx + hs + bulge, cx - hs - bulge, cx + hs + bulge, belt)
			_rect(cx - hs - bulge, belt_y - 2.0, (hs + bulge) * 2.0, 1.0, belt[4])
			if not back:
				_rect(cx - 2.0, belt_y - 2.0, 5.0, 5.0, _c["gold"][2])
				_rect(cx - 2.0, belt_y - 2.0, 5.0, 1.0, _c["gold"][4])
				_rect(cx - 1.0, belt_y - 1.0, 3.0, 3.0, _c["gold"][0])
				_trap(belt_y + 2.5, belt_y + 19.0, cx + 2.0, cx + 5.5, cx + 2.6, cx + 7.0, belt, 0.0, [], true)
			else:
				_trap(belt_y + 2.5, belt_y + 16.0, cx - 2.5, cx + 2.5, cx - 3.0, cx + 3.0, belt, 0.0, [], true)
		_:
			_torso_tunic(cx, belt_y, bulge, top, belt, back, 5.0)
	# cape de dos : elle recouvre tout le dos
	if has_cape and back:
		_trap(ny + 1.0, _foot - 4.0, cx - hs - 1.5, cx + hs + 1.5, cx - hs - 13.0, cx + hs + 13.0, cape, 0.0,
			[Vector2(0.2, 0.0), Vector2(0.4, 0.2), Vector2(0.6, 0.0), Vector2(0.8, 0.2)], true, sway * 1.5)
	if back and hair_style == "long":
		_hair_back(cx, _hcy, _rx, _ry, 2, sway)
	# épaules arrondies (et col de la cape)
	var sh: Array = cape if has_cape else top
	var tilt := 1.0 if int(_p["an"]) == 0 and arms == "down" else 0.0   # repos : une épaule plus basse
	_ell(cx - hs + 0.5, ny + 4.2 + tilt, 5.6, 4.8, sh)
	_ell(cx + hs - 0.5, ny + 4.2, 5.6, 4.8, sh)
	if has_cape and not back:
		_ell(cx, ny + 1.5, hs - 1.0, 3.6, cape, 0.1)
		# agrafe dorée et chaîne
		_ell(cx, ny + 5.4, 3.5, 3.2, _c["gold"])
		_put(int(cx) - 1, int(ny) + 4, WHITE)
		_cap(cx - hs + 2.0, ny + 3.5, cx - 3.0, ny + 5.4, 0.7, 0.7, _c["gold"])
		_cap(cx + hs - 2.0, ny + 3.5, cx + 3.0, ny + 5.4, 0.7, 0.7, _c["gold"])
	elif not back and outfit != "tablier" and outfit != "jupe" and not has_cape:
		# encolure en V qui laisse voir la peau et le col de la chemise
		_trap(ny - 1.0, ny + 8.0, cx - 5.0, cx + 5.0, cx - 0.8, cx + 0.8, skin, -0.15)
		for i in 8:
			_put(int(cx) - 6 + int(float(i) * 0.75), int(ny) + i, top[3])
			_put(int(cx) + 5 - int(float(i) * 0.75), int(ny) + i, top[1])
		_put(int(cx) - 2, int(ny) + 8, top[0])
		_put(int(cx) + 1, int(ny) + 8, top[0])

	# ombre portée du menton sur le torse
	_cast(cx, _hcy + _ry + 0.5, _rx - 2.0, 4.6, -0.24)

	# bras
	var hand_r := Vector2(0, 0)
	var al := _alen()
	for s: int in [-1, 1]:
		var wide := outfit == "robe"
		var sx := cx + float(s) * (hs + 0.5)
		var sy := ny + 5.0 + (tilt if s < 0 else 0.0)
		var swing := float(_p["an"]) if s > 0 else float(_p["af"])
		var ex := sx + float(s) * 1.4
		var hx := cx + float(s) * (hs + 3.2)
		var hy := ny + th - 3.0 - swing * 0.9 + (tilt if s < 0 else 0.0)
		var ey := (sy + hy) * 0.5 + 1.0
		match arms:
			"strike":
				if s > 0:
					ex = cx + hs + 8.0
					ey = ny + 3.0
					hx = cx + hs + 10.0
					hy = ny - 14.0
				else:
					hx = cx - hs - 6.0
					hy = ny + th * 0.7
			"up":
				ex = cx + float(s) * (hs + 8.0)
				ey = ny + 2.0
				hx = cx + float(s) * (hs + 11.0)
				hy = ny - 17.0
			"flail":
				ex = cx + float(s) * (hs + 9.0)
				ey = ny + 8.0
				hx = cx + float(s) * (hs + 14.0)
				hy = ny - 4.0
			"slump":
				ex = cx + float(s) * (hs + 4.0)
				ey = ny + th * 0.5
				hx = cx + float(s) * (hs + 3.0)
				hy = ny + th + 3.0
		if s > 0 and item == "baton" and arms == "down":
			hx += 2.0
			ex += 1.0
		_arm(sx, sy, ex, ey, hx, hy, top, wide, al, 2 if (s > 0 and item == "baton") else 0, s)
		if s > 0:
			hand_r = Vector2(hx, hy)

	# objet tenu (main droite de l'écran)
	if item == "baton":
		_staff(hand_r.x, hand_r.y, arms, back)
	_head_front(look, cx, back, item)


static func _torso_tunic(cx: float, belt_y: float, bulge: float, top: Array, belt: Array, back: bool, flare: float) -> void:
	var hs := _hs
	var gold: Array = _c["gold"]
	_trap(_ny, belt_y, cx - hs + 1.0, cx + hs - 1.0, cx - hs - bulge, cx + hs + bulge, top, 0.0,
		[Vector2(0.24, 0.0), Vector2(0.7, 0.15)])
	_trap(belt_y, _hip + _lh * 0.2 + flare, cx - hs - bulge, cx + hs + bulge, cx - hs - bulge - 4.5, cx + hs + bulge + 4.5, top, -0.04,
		[Vector2(0.18, 0.0), Vector2(0.4, 0.0), Vector2(0.66, 0.2), Vector2(0.86, 0.0)], true, float(_p["sway"]) * 0.4)
	_trap(belt_y - 1.5, belt_y + 2.5, cx - hs - bulge, cx + hs + bulge, cx - hs - bulge, cx + hs + bulge, belt)
	_rect(cx - hs - bulge, belt_y - 1.5, (hs + bulge) * 2.0, 1.0, belt[4])
	if not back:
		# placket et boutons
		_line(cx, _ny + 8.0, cx, belt_y - 2.0, top[1])
		_put(int(cx) - 1, int(_ny) + 11, gold[3])
		_put(int(cx) - 1, int(_ny) + 16, gold[3])
		# boucle
		_rect(cx - 3.5, belt_y - 2.5, 7.0, 5.5, gold[2])
		_rect(cx - 3.5, belt_y - 2.5, 7.0, 1.0, gold[4])
		_rect(cx - 3.5, belt_y + 2.0, 7.0, 1.0, gold[0])
		_rect(cx - 1.5, belt_y - 0.5, 3.0, 2.0, gold[0])
		_put(int(cx) - 3, int(belt_y) - 2, WHITE)
		# bourse à la ceinture
		_ell(cx + hs + bulge - 3.0, belt_y + 6.0, 4.4, 4.0, belt, 0.05)
		_rect(cx + hs + bulge - 6.0, belt_y + 3.0, 6.0, 1.0, belt[0])
		_put(int(cx + hs + bulge) - 4, int(belt_y) + 6, gold[3])


static func _torso_blouse(cx: float, belt_y: float, top: Array, back: bool) -> void:
	var hs := _hs
	_trap(_ny, belt_y + 1.5, cx - hs + 1.0, cx + hs - 1.0, cx - hs - 1.0, cx + hs + 1.0, top, 0.0,
		[Vector2(0.3, 0.0), Vector2(0.7, 0.0)])
	if not back:
		# col lacé
		_rect(cx - 2.0, _ny + 1.0, 4.0, 9.0, _c["skin"][1])
		_rect(cx - 0.5, _ny + 1.0, 1.0, 9.0, _c["belt"][2])
		for i in 3:
			_put(int(cx) - 2, int(_ny) + 3 + i * 3, _c["belt"][3])
			_put(int(cx) + 1, int(_ny) + 4 + i * 3, _c["belt"][3])


static func _leg_front(lx: float, s: int, ay: float, lift: float, outfit: String, back: bool = false) -> void:
	var bottom: Array = _c["bottom"]
	var boot: Array = _c["boot"]
	var skin: Array = _c["skin"]
	var fx := lx + float(s) * 0.8
	if bool(_c["boots"]):
		_cap(lx, _hip - 2.0, lx, ay - 9.0, 4.5, 4.1, bottom)
		_cap(lx, ay - 10.0, lx, ay, 4.9, 4.5, boot)
		_rect(lx - 4.9, ay - 10.0, 9.8, 1.5, boot[3])
		_rect(lx - 4.9, ay - 9.0, 9.8, 1.0, boot[0])
		if back:
			# talon : arrondi, sans bout, avec la semelle qui dépasse
			_ell(lx, ay + 1.8, 5.5, 3.5, boot)
			_rect(lx - 4.5, ay + 3.0, 9.0, 1.0, boot[1])
			_rect(lx - 4.5, ay + 4.0, 9.0, 1.0, boot[0])
			_put(int(lx) - 2, int(ay) + 1, boot[3])
		else:
			_ell(fx, ay + 1.6, 6.4, 3.8, boot)
			# bout renforcé : couture, reflet, semelle
			_line(fx - 4.5, ay + 1.0, fx + 4.5, ay + 1.0, boot[1])
			_rect(fx - 3.0, ay + 2.0, 6.0, 1.0, boot[3])
			_rect(fx - 5.0, ay + 4.2, 10.0, 1.0, boot[0])
			_put(int(fx) - 3, int(ay) + 1, boot[4])
			_put(int(fx) - 2, int(ay) + 1, boot[3])
		# boucle ou couture de la botte
		_put(int(lx), int(ay) - 4, boot[1])
		_put(int(lx), int(ay) - 3, boot[1])
	else:
		_cap(lx, _hip - 2.0, lx, ay - 2.0, 4.5, 4.0, bottom)
		var hr: Array = _c["hair"]
		if back:
			_ell(lx, ay + 1.8, 5.2, 3.4, skin)
			_rect(lx - 3.0, ay + 3.0, 6.0, 1.0, skin[1])
			_put(int(round(lx)) - 2, int(ay), skin[3])
		else:
			_ell(fx, ay + 1.6, 6.6, 3.6, skin)
			# touffe de poils de Grobitte et orteils
			for i in 5:
				_put(int(round(lx)) - 3 + i, int(ay) - 1 - (i % 2), hr[1 + (i % 3)])
			_put(int(round(lx)) - 2, int(ay) - 3, hr[2])
			_put(int(round(lx)) + 1, int(ay) - 3, hr[3])
			for i in 5:
				_put(int(round(fx)) - 5 + i * 2, int(ay) + 3, skin[1])
				_put(int(round(fx)) - 5 + i * 2, int(ay) + 4, skin[0] if i % 2 == 0 else skin[2])
			_put(int(round(fx)) - 4, int(ay) + 1, skin[3])


static func _arm(sx: float, sy: float, ex: float, ey: float, hx: float, hy: float, sleeve: Array, wide: bool, al: float,
		hand: int = 0, hs: int = 1) -> void:
	var dir := Vector2(hx - ex, hy - ey)
	if dir.length() < 0.1:
		dir = Vector2(0, 1)
	dir = dir.normalized()
	var wx := hx - dir.x * 3.6
	var wy := hy - dir.y * 3.6
	var skin: Array = _c["skin"]
	_cap(sx, sy, ex, ey, 4.5, 4.1, sleeve)
	_cap(ex, ey, wx, wy, 4.1, 5.6 if wide else 3.6, sleeve)
	# poignet : manchette plus claire
	_cap(wx - dir.x * 1.2, wy - dir.y * 1.2, wx + dir.x * 1.0, wy + dir.y * 1.0, 5.4 if wide else 4.5, 5.4 if wide else 4.5, sleeve, 0.22)
	_hand(hx, hy, hand, hs)


## Main. mode 0 : pendante (face, dos), pouce côté corps (hs : côté de l'écran du bras) ;
## mode 1 : poing de profil, doigts vers l'avant ; mode 2 : poing fermé sur un manche.
static func _hand(hx: float, hy: float, mode: int, hs: int) -> void:
	var skin: Array = _c["skin"]
	var x := int(round(hx))
	var y := int(round(hy))
	match mode:
		1:
			_ell(hx - 0.3, hy + 0.3, 3.7, 3.5, skin)
			_put(x - 3, y - 1, skin[1])
			_put(x - 2, y - 1, skin[1])
			_put(x - 3, y + 1, skin[1])
			_put(x - 2, y + 1, skin[1])
			_put(x - 3, y + 2, skin[0])
			_cap(hx - 2.6, hy - 2.7, hx - 0.6, hy - 3.0, 1.1, 1.1, skin, 0.25)
			_put(x + 1, y + 2, skin[1])
		2:
			_ell(hx, hy, 3.7, 3.4, skin)
			for i in 7:
				_put(x - 3 + i, y, skin[1])
				_put(x - 3 + i, y + 2, skin[0] if i % 2 == 0 else skin[1])
			_put(x - 1, y - 1, skin[4])
			_put(x + 1, y - 1, skin[3])
			_cap(hx - 0.8, hy - 3.2, hx + 0.8, hy - 1.0, 1.2, 1.1, skin, 0.25)
		_:
			_ell(hx, hy + 0.6, 3.3, 4.0, skin)
			_cap(hx - float(hs) * 2.5, hy - 1.8, hx - float(hs) * 2.1, hy + 1.4, 1.2, 1.0, skin, 0.25)
			_put(x - 1, y + 1, skin[1])
			_put(x - 1, y + 2, skin[1])
			_put(x + 1, y + 1, skin[1])
			_put(x + 1, y + 2, skin[1])
			_put(x - 2, y + 3, skin[1])
			_put(x, y + 3, skin[1])
			_put(x + 2, y + 3, skin[1])
			_put(x, y - 2, skin[4])


static func _staff(hx: float, hy: float, arms: String, back: bool) -> void:
	var wood: Array = _c["wood"]
	var top := hy - 46.0
	var bot := minf(_foot - 1.0, hy + 36.0)
	var tilt := 0.0
	match arms:
		"strike":
			top = hy - 26.0
			bot = hy + 12.0
			tilt = 4.0
		"up":
			top = hy - 26.0
			bot = hy + 12.0
		"flail":
			top = hy - 22.0
			bot = hy + 22.0
			tilt = 8.0
		"slump":
			top = hy - 30.0
			bot = hy + 6.0
			tilt = -10.0
	top = maxf(top, 14.0)
	_cap(hx - tilt, top, hx + tilt, bot, 2.0, 2.0, wood)
	# nœuds du bois et sillon
	var tx := hx - tilt
	for k in 3:
		var t := 0.25 + 0.2 * float(k)
		var q := Vector2(lerpf(hx - tilt, hx + tilt, t), lerpf(top, bot, t))
		_put(int(q.x) - 1, int(q.y), wood[0])
		_put(int(q.x), int(q.y) + 1, wood[1])
	_ell(tx, top, 4.4, 3.8, wood)
	# griffes qui tiennent le cristal
	_cap(tx - 4.2, top + 1.5, tx - 3.6, top - 8.0, 1.2, 0.9, wood)
	_cap(tx + 4.2, top + 1.5, tx + 3.6, top - 8.0, 1.2, 0.9, wood)
	_ell(tx, top - 4.4, 3.4, 4.6, _c["crystal"], 0.1)
	_put(int(round(tx - 1.0)), int(round(top - 6.0)), WHITE)
	_put(int(round(tx - 1.0)), int(round(top - 5.0)), _c["crystal"][4])
	_put(int(round(tx + 1.0)), int(round(top - 2.0)), _c["crystal"][1])
	if arms == "up" or arms == "strike":
		_put(int(round(tx)) - 8, int(round(top)) - 7, WHITE)
		_put(int(round(tx)) + 8, int(round(top)) - 10, Color("#a8f4ff"))
		_put(int(round(tx)) + 7, int(round(top)) - 2, WHITE)
		_put(int(round(tx)) - 5, int(round(top)) - 12, Color("#a8f4ff"))
	_hand(hx, hy, 2, 1)


# ----------------------------------------------------------------------- profil

## Profil tourné vers la gauche.
static func _side(look: Dictionary) -> void:
	_layout(look)
	var cx := _cx
	var ny := _ny
	var th := _th
	var outfit := str(look.get("outfit", "tunique"))
	var item := str(look.get("item", "none"))
	var arms := str(_p["arms"])
	var lean := float(_p["lean"])
	var hs := _hs - 2.5
	var tx := cx - lean * 0.5
	var petit := str(look.get("build", "petit")) == "petit"
	var belt_y := ny + th * 0.8
	var top: Array = _c["top"]
	var skin: Array = _c["skin"]
	var has_cape := _c.has("cape")
	var sway := float(_p["sway"])
	var al := _alen()

	if str(look.get("hair_style", "")) == "long":
		_hair_back(tx, _hcy, _rx, _ry, 1, sway)
	if has_cape:
		_cape_side(tx, hs, sway)

	# bras éloigné, caché par le torse
	var swing_f := float(_p["af"]) * 1.4
	var far_hand := Vector2(tx - swing_f, ny + th - 3.0)
	var far_el := Vector2(tx - swing_f * 0.5 + 1.0, ny + th * 0.5 + 1.0)
	match arms:
		"strike":
			far_hand = Vector2(tx + 8.0, ny + th - 4.0)
			far_el = Vector2(tx + 5.0, ny + th * 0.5)
		"up":
			far_hand = Vector2(tx - 3.0, ny - 17.0)
			far_el = Vector2(tx - 1.0, ny + 1.0)
		"flail":
			far_hand = Vector2(tx - 16.0, ny + 4.0)
			far_el = Vector2(tx - 9.0, ny + 8.0)
		"slump":
			far_hand = Vector2(tx, ny + th + 3.0)
			far_el = Vector2(tx, ny + th * 0.5)
	_arm(tx + 1.0, ny + 5.0, far_el.x, far_el.y, far_hand.x, far_hand.y, _dim(top), outfit == "robe", al, 1)

	# jambes : la jambe proche est celle de droite dans les poses de marche
	for near: bool in [false, true]:
		var lift := float(_p["ln"]) if near else float(_p["lf"])
		var fwd := float(_p["fn"]) if near else float(_p["ff"])
		_leg_side(cx + 1.0, cx - fwd, _foot - 4.0 - lift, near)

	_cap(tx, ny - 4.0, tx, ny + 2.0, 3.8, 3.8, skin)
	# torse
	var belly := 2.8 if petit else 0.8
	match outfit:
		"robe":
			var hem := _foot - 6.0
			_trap(ny, hem, tx - hs + 1.0, tx + hs - 1.0, tx - hs - 6.0, tx + hs + 9.0, top, 0.0,
				[Vector2(0.3, 0.3), Vector2(0.55, 0.15), Vector2(0.78, 0.3), Vector2(0.92, 0.1)], true, sway * 0.7)
			_trap(hem - 3.0, hem, tx - hs - 5.4, tx + hs + 8.4, tx - hs - 6.0, tx + hs + 9.0, _c["belt"], -0.1)
			_trap(belt_y - 2.0, belt_y + 2.5, tx - hs - belly, tx + hs, tx - hs - belly, tx + hs, _c["belt"])
			_trap(belt_y + 2.5, belt_y + 17.0, tx + hs - 5.0, tx + hs - 1.0, tx + hs - 4.0, tx + hs + 2.5, _c["belt"], 0.0, [], true)
		"jupe":
			_trap(ny, belt_y + 1.0, tx - hs + 1.0, tx + hs - 1.0, tx - hs - belly, tx + hs, top, 0.0, [Vector2(0.5, 0.2)])
			_trap(belt_y - 1.0, _foot - 5.0, tx - hs - 1.0, tx + hs, tx - hs - 10.0, tx + hs + 9.0, _c["bottom"], 0.0,
				[Vector2(0.25, 0.2), Vector2(0.5, 0.1), Vector2(0.75, 0.3)], true, sway * 0.6)
			_trap(belt_y - 1.0, belt_y + 3.0, tx - hs - belly, tx + hs, tx - hs - belly, tx + hs, _c["belt"])
		_:
			_trap(ny, belt_y, tx - hs + 1.0, tx + hs - 1.0, tx - hs - belly, tx + hs, top, 0.0, [Vector2(0.55, 0.2)])
			_trap(belt_y, _hip + _lh * 0.2 + 5.0, tx - hs - belly, tx + hs, tx - hs - belly - 3.5, tx + hs + 3.5, top, -0.04,
				[Vector2(0.4, 0.0), Vector2(0.75, 0.2)], true, sway * 0.4)
			_trap(belt_y - 1.5, belt_y + 2.5, tx - hs - belly, tx + hs, tx - hs - belly, tx + hs, _c["belt"])
			_rect(tx - hs - belly - 1.0, belt_y - 2.5, 5.0, 5.5, _c["gold"][2])
			_rect(tx - hs - belly - 1.0, belt_y - 2.5, 5.0, 1.0, _c["gold"][4])
			if outfit == "tablier":
				var ap: Array = _c["apron"]
				var by2 := minf(_hip + _lh * 0.28, _foot - 9.0)
				var fxa := tx - hs - belly
				_poly([Vector2(fxa + 0.5, ny + 6.0), Vector2(fxa - 1.2, belt_y), Vector2(fxa - 4.5, by2 - 2.0), Vector2(fxa - 3.8, by2),
					Vector2(fxa + 4.5, by2), Vector2(fxa + 5.0, belt_y), Vector2(fxa + 3.0, ny + 7.0)], ap, 0.0, true)
				_line(fxa - 3.0, belt_y + 5.0, fxa + 4.0, belt_y + 5.0, ap[1])
				_line(fxa - 1.0, belt_y + 5.0, fxa - 1.0, belt_y + 11.0, ap[1])
				_cap(tx - 0.5, ny + 2.5, fxa + 1.5, ny + 7.5, 1.4, 1.2, ap)
	_ell(tx - 0.5, ny + 4.6, 5.4, 4.6, top if not has_cape else _c["cape"])
	_cast(tx - 1.0, _hcy + _ry + 0.5, _rx - 2.0, 4.6, -0.24)

	# bras proche
	var swing_n := float(_p["an"]) * 1.4
	var nh := Vector2(tx + swing_n, ny + th - 3.0)
	var ne := Vector2(tx + swing_n * 0.5 + 1.0, ny + th * 0.5 + 1.0)
	match arms:
		"strike":
			ne = Vector2(tx - 9.0, ny + 5.0)
			nh = Vector2(tx - 19.0, ny - 8.0)
		"up":
			ne = Vector2(tx - 7.0, ny - 2.0)
			nh = Vector2(tx - 9.0, ny - 17.0)
		"flail":
			ne = Vector2(tx + 9.0, ny + 6.0)
			nh = Vector2(tx + 18.0, ny - 6.0)
		"slump":
			ne = Vector2(tx + 2.0, ny + th * 0.5)
			nh = Vector2(tx + 2.0, ny + th + 4.0)
	_arm(tx - 0.5, ny + 5.0, ne.x, ne.y, nh.x, nh.y, top, outfit == "robe", al, 2 if item == "baton" else 1)
	if item == "baton":
		_staff(nh.x, nh.y, arms, false)
	_head_side(look, tx - 1.0, item)


## Cape de profil : elle part de la nuque, tombe derrière le dos et s'évase en plis, l'ourlet suit le pas.
static func _cape_side(tx: float, hs: float, sway: float) -> void:
	var cp: Array = _c["cape"]
	var ny := _ny
	var cs := sway * 0.9
	_poly([Vector2(tx + 0.5, ny + 1.5), Vector2(tx + hs + 3.5, ny + 2.5), Vector2(tx + hs + 6.5 + cs * 0.3, ny + _th * 0.7),
		Vector2(tx + hs + 11.0 + cs * 0.7, ny + _th * 1.4), Vector2(tx + hs + 15.0 + cs, _foot - 6.5),
		Vector2(tx + hs + 10.0 + cs, _foot - 3.0), Vector2(tx + hs + 5.0 + cs, _foot - 5.0),
		Vector2(tx + hs - 0.5 + cs * 0.6, _foot - 3.5), Vector2(tx - 1.5, _foot - 6.0)], cp, -0.12, true)
	var top_x := tx + hs + 1.5
	for k in 3:
		var fx := top_x + float(k) * 3.4
		_line(fx, ny + 9.0, fx + 1.5 + cs * (0.5 + 0.2 * float(k)), _foot - 7.0 - float(k % 2) * 2.0, cp[1])
		_line(fx + 1.0, ny + 12.0, fx + 2.5 + cs * (0.5 + 0.2 * float(k)), _foot - 12.0, cp[3])
	# pan de la cape qui retombe sur l'épaule
	_ell(tx + 1.0, ny + 4.0, 4.6, 3.6, cp, 0.1)


static func _leg_side(hx: float, fx: float, ay: float, near: bool) -> void:
	var bottom: Array = _c["bottom"] if near else _dim(_c["bottom"])
	var boot: Array = _c["boot"] if near else _dim(_c["boot"])
	var skin: Array = _c["skin"] if near else _dim(_c["skin"])
	if bool(_c["boots"]):
		_cap(hx, _hip - 2.0, fx, ay - 9.0, 4.7, 4.2, bottom)
		_cap(fx, ay - 10.0, fx, ay, 4.9, 4.6, boot)
		_rect(fx - 4.9, ay - 10.0, 9.8, 1.5, boot[3])
		_foot_side(fx, ay, boot, true)
	else:
		_cap(hx, _hip - 2.0, fx, ay - 2.0, 4.7, 4.2, bottom)
		var hr: Array = _c["hair"]
		_foot_side(fx, ay, skin, false)
		for i in 4:
			_put(int(round(fx)) - 2 + i, int(ay) - 1 - (i % 2), hr[1 + (i % 3)])


## Pied de profil (vers la gauche) : talon, voûte, bout arrondi, semelle ou orteils.
static func _foot_side(fx: float, ay: float, col: Array, boot: bool) -> void:
	_poly([Vector2(fx + 4.6, ay - 3.0), Vector2(fx + 5.6, ay + 1.5), Vector2(fx + 4.6, ay + 4.8), Vector2(fx - 8.5, ay + 4.8),
		Vector2(fx - 11.6, ay + 3.2), Vector2(fx - 11.8, ay + 1.4), Vector2(fx - 9.0, ay - 0.6), Vector2(fx - 4.0, ay - 2.4),
		Vector2(fx - 3.0, ay - 3.6)], col, 0.05)
	if boot:
		_rect(fx - 10.0, ay + 4.0, 15.0, 1.0, col[0])
		_rect(fx + 1.5, ay + 2.0, 3.5, 2.0, col[1])
		_line(fx - 5.0, ay - 1.0, fx - 5.0, ay + 3.0, col[1])
		_put(int(fx) - 9, int(ay) + 1, col[4])
		_put(int(fx) - 8, int(ay), col[3])
		_put(int(fx) - 7, int(ay), col[3])
	else:
		_put(int(fx) - 11, int(ay) + 4, col[1])
		_line(fx - 9.0, ay + 2.0, fx - 9.0, ay + 4.0, col[1])
		_line(fx - 6.0, ay + 2.5, fx - 6.0, ay + 4.0, col[1])
		_put(int(fx) - 10, int(ay) + 1, col[3])
		_put(int(fx) + 4, int(ay) + 2, col[1])
		_put(int(fx) + 1, int(ay) - 2, col[4])


static func _head_side(look: Dictionary, hx: float, item: String) -> void:
	var hcy := _hcy
	var rx := _rx * 0.94
	var ry := _ry
	var skin: Array = _c["skin"]
	var hat := str(look.get("hat", "none"))
	var hair_style := str(look.get("hair_style", "court"))
	var mood := str(_p["eyes"])
	var old := _elder(look)
	_fk = str(look.get("face", ""))
	var heavy := _fk in ["las", "hautain", "sournois", "renfrogne", "bourru"]
	if hat == "capuche":
		_hood_back(hx, hcy, rx, ry, 1)
	if hair_style == "boucles" or hair_style == "chignon":
		_hair_volume(hx, hcy, rx, ry, hair_style, 1)
	_ell(hx, hcy, rx, ry, skin)
	_ell(hx + 1.0, hcy + ry - 3.4, rx * 0.6, 3.4, skin, -0.1)
	_ell(hx - rx * 0.4, hcy + ry - 2.6, rx * 0.5, 3.5, skin, -0.05)          # menton qui avance
	_put(int(round(hx - rx * 0.4)) - 2, int(hcy + ry) + 1, skin[4])
	# nez
	var nlen := 3.6 if old else 3.0
	_ell(hx - rx - 0.8, hcy + 4.4, nlen, 3.0, skin)
	_put(int(round(hx - rx)) - 3, int(hcy) + 6, skin[1])
	_put(int(round(hx - rx)) - 2, int(hcy) + 7, skin[0])
	# oreille
	_ell(hx + rx * 0.22, hcy + 2.6, 2.8, 3.8, skin)
	_put(int(round(hx + rx * 0.22)), int(hcy) + 2, skin[1])
	_put(int(round(hx + rx * 0.22)), int(hcy) + 3, skin[1])
	# œil
	var ex := int(round(hx - rx * 0.56)) - 2
	var ey := int(hcy) + 1
	var iris: Array = _c["iris"]
	var hr: Array = _c["hair"]
	var fem := hair_style == "chignon" or str(look.get("outfit", "")) == "jupe"
	match mood:
		"closed":
			_put(ex, ey + 2, iris[0])
			_put(ex + 1, ey + 3, iris[0])
			_put(ex + 2, ey + 3, iris[0])
			_put(ex + 3, ey + 2, iris[0])
		"pain":
			_put(ex + 3, ey, iris[0])
			_put(ex + 2, ey + 1, iris[0])
			_put(ex, ey + 2, iris[0])
			_put(ex + 2, ey + 3, iris[0])
			_put(ex + 3, ey + 4, iris[0])
		"ko":
			for i in 4:
				_put(ex + i, ey + 1 + i, iris[0])
				_put(ex + 3 - i, ey + 1 + i, iris[0])
		_:
			for i in 4:
				_put(ex + i, ey + (1 if (mood == "angry" and i == 3) else 0), iris[0])
			for yy in 3:
				_put(ex, ey + 1 + yy, SCLERA.darkened(0.1))
				_put(ex + 1, ey + 1 + yy, iris[2] if yy < 2 else iris[3])
				_put(ex + 2, ey + 1 + yy, iris[2] if yy < 2 else iris[3])
				_put(ex + 3, ey + 1 + yy, skin[2])
			_put(ex + 1, ey + 1, iris[0])
			_put(ex + 2, ey + 1, iris[0])
			_put(ex + 1, ey + 2, WHITE)
			_put(ex + 1, ey + 4, skin[1])
			_put(ex + 2, ey + 4, skin[1])
			if old or heavy or mood == "angry":
				_put(ex, ey + 1, skin[1])
				_put(ex + 1, ey + 1, skin[1].lerp(iris[0], 0.55))
				_put(ex + 2, ey + 1, skin[1].lerp(iris[0], 0.55))
			if fem:
				_put(ex + 4, ey, iris[0])
				_put(ex + 4, ey - 1, iris[0])
	var brow_col: Color = (_c["beard"] if old and str(look.get("beard", "none")) != "none" else hr)[1]
	for i in 5:
		var yy := ey - 3 + (1 if mood == "angry" and i < 2 else 0) + (1 if i == 0 else 0)
		if mood == "open" and _fk != "":
			yy = ey - 3 + _brow_dy(4 - i, 0)
		_put(ex - 1 + i, yy, brow_col)
		if old or _fk == "bourru":
			_put(ex - 1 + i, yy + 1, brow_col)
	_put(ex + 2, ey + 7, skin[2].lerp(Color("#e0607a"), 0.45))
	_put(ex + 3, ey + 7, skin[2].lerp(Color("#e0607a"), 0.45))
	# bouche
	var mx := int(round(hx - rx)) + 3
	var my := int(hcy) + 9
	var hidden := str(look.get("beard", "none")) != "none"
	match str(_p["mouth"]):
		"open":
			_rect(mx - 2.0, my - 1.0, 5.0, 4.0, MOUTH)
			_put(mx - 2, my - 1, SCLERA)
			_put(mx - 1, my - 1, SCLERA)
			_put(mx, my - 1, SCLERA)
			_put(mx, my + 2, RED)
			_put(mx - 1, my + 2, RED)
		"grit":
			_rect(mx - 2.0, my - 1.0, 5.0, 3.0, SCLERA)
			_put(mx - 3, my, MOUTH)
			_rect(mx - 2.0, my + 2.0, 5.0, 1.0, MOUTH)
			_put(mx, my - 1, MOUTH)
			_put(mx + 2, my - 1, MOUTH)
		_:
			if not hidden and _fk in ["renfrogne", "bourru", "las"]:
				_put(mx - 2, my + 1, MOUTH)
				_put(mx - 1, my + 1, MOUTH)
				_put(mx, my + 1, MOUTH)
				_put(mx + 1, my + (2 if _fk != "las" else 1), skin[1])
				_put(mx - 1, my + 2, skin[3])
			elif not hidden and _fk == "bonhomme":
				_put(mx - 3, my - 1, skin[1])
				_put(mx - 2, my, SCLERA)
				_put(mx - 1, my, SCLERA)
				_put(mx - 2, my + 1, MOUTH)
				_put(mx - 1, my + 1, MOUTH)
				_put(mx, my, MOUTH)
				_put(mx + 1, my - 1, skin[1])
				_put(mx - 1, my + 2, skin[3])
			elif not hidden and (_fk == "hautain" or _fk == "sournois"):
				_put(mx - 2, my + 1, MOUTH)
				_put(mx - 1, my + 1, MOUTH)
				_put(mx, my, MOUTH)
				_put(mx + 1, my - 1, MOUTH)
				_put(mx - 1, my + 2, skin[3])
			elif not hidden:
				_put(mx - 2, my, MOUTH)
				_put(mx - 1, my + 1, MOUTH)
				_put(mx, my + 1, MOUTH)
				_put(mx + 1, my, skin[1])
				_put(mx - 1, my + 2, skin[3])
	if str(look.get("beard", "none")) != "none":
		_beard_side(look, hx, hcy, rx, ry)
	_hair(hx, hcy, rx, ry, hair_style, 1)
	if str(look.get("ears", "")) == "elfe":
		_cap(hx + rx * 0.3, hcy + 2.0, hx + rx * 0.3 + 10.0, hcy - 7.0, 2.4, 0.6, skin)
	if item == "pipe":
		_cap(hx - rx - 1.5, my + 0.5, hx - rx - 9.0, my - 0.5, 1.3, 1.3, _c["wood"])
		_ell(hx - rx - 10.5, my - 2.8, 3.5, 4.0, _c["wood"])
		_put(int(hx - rx) - 11, int(my) - 10, Color(0.85, 0.85, 0.9, 0.9))
		_put(int(hx - rx) - 9, int(my) - 13, Color(0.8, 0.8, 0.88, 0.8))
	_hat(look, hx, hcy, rx, ry, hat, 1)
