extends RefCounted
## Peint la planche de sprites d'un personnage à partir d'une description (« look »).
##
## Format de la planche générée (voir assets/sprites/README.md) :
##   cases de 32 x 48 px, 4 colonnes (arrêt, pas 1, passage, pas 2),
##   4 lignes dans l'ordre : bas, gauche, droite, haut.

const PA = preload("res://src/gfx/pixel_art.gd")

const FRAME_W := 32
const FRAME_H := 48
const COLUMNS := 4
const ROWS := 4
const FOOT_MARGIN := 2   # pixels vides sous les pieds dans chaque case


static func paint_sheet(look: Dictionary) -> Image:
	var img := PA.new_image(FRAME_W * COLUMNS, FRAME_H * ROWS)
	var c := _colors(look)
	for phase in COLUMNS:
		var ox := phase * FRAME_W
		_front(img, ox, 0, look, c, phase, false)
		_side(img, ox, FRAME_H, look, c, phase)
		_front(img, ox, FRAME_H * 3, look, c, phase, true)
		for row: int in [0, 1, 3]:
			PA.outline(img, Rect2i(ox, row * FRAME_H, FRAME_W, FRAME_H))
		# La marche vers la droite est le miroir de la marche vers la gauche.
		var left := img.get_region(Rect2i(ox, FRAME_H, FRAME_W, FRAME_H))
		left.flip_x()
		img.blit_rect(left, Rect2i(0, 0, FRAME_W, FRAME_H), Vector2i(ox, FRAME_H * 2))
	return img


static func _col(look: Dictionary, key: String, fallback: String) -> Color:
	return Color.from_string(str(look.get(key, fallback)), Color.from_string(fallback, Color.GRAY))


static func _colors(look: Dictionary) -> Dictionary:
	var skin := _col(look, "skin", "#e8b48a")
	var hair := _col(look, "hair", "#6b4a2e")
	var top := _col(look, "top", "#4f7d5a")
	var bottom := _col(look, "bottom", "#6b5238")
	var hat := _col(look, "hat_color", "#6f7390")
	var beard := _col(look, "beard_color", "#d9d9e0")
	var feet := PA.shade(skin, -0.12)
	if str(look.get("feet", "nus")) == "bottes":
		feet = _col(look, "boots", "#4a3426")
	return {
		"skin": skin, "skin_d": PA.shade(skin, -0.2), "skin_dd": PA.shade(skin, -0.42),
		"blush": skin.lerp(Color("#e0705a"), 0.4),
		"hair": hair, "hair_d": PA.shade(hair, -0.28), "hair_l": PA.shade(hair, 0.25),
		"top": top, "top_d": PA.shade(top, -0.28), "top_l": PA.shade(top, 0.2),
		"bottom": bottom, "bottom_d": PA.shade(bottom, -0.28),
		"feet": feet, "feet_d": PA.shade(feet, -0.25),
		"hat": hat, "hat_d": PA.shade(hat, -0.28), "hat_l": PA.shade(hat, 0.22),
		"band": _col(look, "band", "#b0483c"),
		"beard": beard, "beard_d": PA.shade(beard, -0.22), "beard_l": PA.shade(beard, 0.3),
		"eye": Color("#2b1b2e"),
		"belt": _col(look, "belt", "#4a3426"),
		"wood": Color("#7a5230"), "wood_d": Color("#553621"),
		"apron": Color("#efe6d2"), "apron_d": Color("#c9bda6"),
	}


static func _layout(look: Dictionary, phase: int, oy: int) -> Dictionary:
	var head_h := 11
	var torso_h := 9
	var leg_h := 4
	match str(look.get("build", "petit")):
		"grand":
			head_h = 10
			torso_h = 12
			leg_h = 8
		"enfant":
			head_h = 10
			torso_h = 6
			leg_h = 3
	var bob := 1 if (phase == 1 or phase == 3) else 0
	var foot_y := oy + FRAME_H - 1 - FOOT_MARGIN
	var leg_top := foot_y - 1 - leg_h
	var neck_y := leg_top - torso_h - bob
	return {
		"foot_y": foot_y, "leg_top": leg_top, "neck_y": neck_y, "bob": bob,
		"head_top": neck_y - head_h, "head_h": head_h, "torso_h": torso_h,
	}


# ---------------------------------------------------------------- face / dos

static func _front(img: Image, ox: int, oy: int, look: Dictionary, c: Dictionary, phase: int, back: bool) -> void:
	var lay := _layout(look, phase, oy)
	var cx: int = ox + 16
	var foot_y: int = lay.foot_y
	var leg_top: int = lay.leg_top
	var bob: int = lay.bob
	var neck_y: int = lay.neck_y
	var hy: int = lay.head_top
	var hh: int = lay.head_h
	var th: int = lay.torso_h
	var outfit := str(look.get("outfit", "tunique"))
	var item := str(look.get("item", "none"))
	var view := 2 if back else 0
	var sl := 0
	var sr := 0
	if phase == 1:
		sl = -1
		sr = 1
	elif phase == 3:
		sl = 1
		sr = -1
	var top: Color = c.top
	var top_d: Color = c.top_d
	var top_l: Color = c.top_l
	var skin: Color = c.skin

	if outfit == "robe":
		var rows := foot_y - neck_y
		for i in rows:
			var y := neck_y + i
			var t := float(i) / float(rows - 1)
			var half := 5 + int(round(t * 2.0))
			var sway := 0
			if i >= rows - 5:
				sway = -1 if phase == 1 else (1 if phase == 3 else 0)
			PA.rect(img, cx - half + sway, y, half * 2, 1, top)
			PA.rect(img, cx + half - 2 + sway, y, 2, 1, top_d)
			PA.px(img, cx - half + sway, y, top_l)
			if i > 11:
				PA.px(img, cx - 2 + sway, y, top_d)
				PA.px(img, cx + 2 + sway, y, top_d)
			if i == rows - 1:
				PA.rect(img, cx - half + sway, y, half * 2, 1, top_d)
		PA.rect(img, cx - 5, neck_y + 9, 10, 1, c.belt)
		if not back:
			PA.rect(img, cx - 2, neck_y + 10, 1, 3, c.belt)
		if phase != 3:
			PA.rect(img, cx - 4, foot_y, 3, 1, c.feet)
		if phase != 1:
			PA.rect(img, cx + 1, foot_y, 3, 1, c.feet)
		# manches larges
		PA.rect(img, cx - 8, neck_y + 1 + sl, 3, 9, top)
		PA.rect(img, cx - 8, neck_y + 9 + sl, 3, 1, top_l)
		PA.rect(img, cx - 7, neck_y + 10 + sl, 2, 2, skin)
		PA.rect(img, cx + 5, neck_y + 1 + sr, 3, 9, top_d)
		PA.rect(img, cx + 5, neck_y + 9 + sr, 3, 1, top)
		PA.rect(img, cx + 5, neck_y + 10 + sr, 2, 2, skin)
	else:
		_leg_front(img, cx - 4, -1, leg_top - bob, foot_y, 2 if phase == 1 else 0, c)
		_leg_front(img, cx + 1, 1, leg_top - bob, foot_y, 2 if phase == 3 else 0, c)
		PA.rect(img, cx - 5, neck_y, 10, th, top)
		PA.rect(img, cx + 3, neck_y, 2, th, top_d)
		PA.rect(img, cx - 5, neck_y + th - 1, 10, 1, top_d)
		if th >= 8:
			PA.rect(img, cx - 5, neck_y + th - 3, 10, 1, c.belt)
		if outfit == "jupe":
			var sy := neck_y + th - 3
			var sh := foot_y - 2 - sy
			PA.rect(img, cx - 6, sy, 12, sh, c.bottom)
			PA.rect(img, cx + 4, sy, 2, sh, c.bottom_d)
			PA.rect(img, cx - 6, sy + sh - 1, 12, 1, c.bottom_d)
			PA.rect(img, cx - 6, sy, 12, 1, c.belt)
		if not back:
			PA.rect(img, cx - 2, neck_y, 4, 1, top_l)
			if outfit == "tablier":
				PA.rect(img, cx - 3, neck_y + 2, 6, th - 2, c.apron)
				PA.rect(img, cx + 2, neck_y + 2, 1, th - 2, c.apron_d)
				PA.px(img, cx - 3, neck_y + 1, c.apron)
				PA.px(img, cx + 2, neck_y + 1, c.apron)
		elif outfit == "tablier":
			PA.rect(img, cx - 5, neck_y + th - 4, 10, 1, c.apron)
			PA.rect(img, cx - 1, neck_y + th - 4, 2, 3, c.apron)
		var al := maxi(2, th - 3)
		PA.rect(img, cx - 7, neck_y + 1 + sl, 2, al, top)
		PA.rect(img, cx - 7, neck_y + 1 + sl + al, 2, 2, skin)
		PA.rect(img, cx + 5, neck_y + 1 + sr, 2, al, top_d)
		PA.rect(img, cx + 5, neck_y + 1 + sr + al, 2, 2, c.skin_d)

	if item == "baton":
		var sx := (cx + 8) if back else (cx - 10)
		var stop := hy - 5
		PA.rect(img, sx, stop, 2, foot_y - bob - stop + 1, c.wood)
		PA.rect(img, sx + 1, stop + 1, 1, foot_y - bob - stop, c.wood_d)
		PA.rect(img, sx - 1, stop - 2, 4, 3, c.wood)
		PA.px(img, sx + 2, stop - 3, c.wood)
		PA.px(img, sx + 2, stop, c.wood_d)
		PA.px(img, sx - 1, stop - 2, PA.shade(c.wood, 0.3))
		PA.rect(img, sx, neck_y + 10, 2, 2, skin)

	var hx := cx - 6
	var ey := hy + hh / 2
	_head(img, hx, hy, hh, c)
	PA.px(img, hx - 1, ey + 1, c.skin_d)
	PA.px(img, hx + 12, ey + 1, c.skin_d)
	_hair(img, hx, hy, hh, str(look.get("hair_style", "court")), c, view)
	if not back:
		PA.rect(img, cx - 3, ey, 1, 2, c.eye)
		PA.rect(img, cx + 2, ey, 1, 2, c.eye)
		PA.px(img, cx - 5, ey + 2, c.blush)
		PA.px(img, cx + 4, ey + 2, c.blush)
		PA.rect(img, cx - 1, ey + 3, 2, 1, c.skin_dd)
	_beard(img, hx, ey, hy, hh, str(look.get("beard", "none")), c, view)
	_hat(img, hx, hy, hh, str(look.get("hat", "none")), c, view)
	if item == "pipe" and not back:
		PA.rect(img, cx + 1, ey + 3, 2, 1, c.eye)
		PA.rect(img, cx + 3, ey + 2, 2, 2, c.wood)
		PA.px(img, cx + 3, ey + 2, PA.shade(c.wood, 0.3))


static func _leg_front(img: Image, x: int, side: int, top_y: int, foot_y: int, lift: int, c: Dictionary) -> void:
	var last := foot_y - 2 - lift
	var n := last - top_y + 1
	PA.rect(img, x, top_y, 3, n, c.bottom)
	PA.rect(img, x + 2, top_y, 1, n, c.bottom_d)
	var fx := (x - 1) if side < 0 else x
	PA.rect(img, fx, last + 1, 4, 2, c.feet)
	PA.rect(img, fx, last + 2, 4, 1, c.feet_d)


# -------------------------------------------------------------------- profil

static func _side(img: Image, ox: int, oy: int, look: Dictionary, c: Dictionary, phase: int) -> void:
	var lay := _layout(look, phase, oy)
	var cx: int = ox + 16
	var foot_y: int = lay.foot_y
	var leg_top: int = lay.leg_top
	var bob: int = lay.bob
	var neck_y: int = lay.neck_y
	var hy: int = lay.head_top
	var hh: int = lay.head_h
	var th: int = lay.torso_h
	var outfit := str(look.get("outfit", "tunique"))
	var item := str(look.get("item", "none"))
	var top: Color = c.top
	var top_d: Color = c.top_d
	var top_l: Color = c.top_l
	var swing := 0
	if phase == 1:
		swing = 2
	elif phase == 3:
		swing = -2
	var ax := cx - 1 + swing
	if item == "baton":
		ax = cx - 5

	if outfit == "robe":
		var rows := foot_y - neck_y
		for i in rows:
			var y := neck_y + i
			var t := float(i) / float(rows - 1)
			var sway := 0
			if i >= rows - 5:
				sway = -1 if phase == 1 else (1 if phase == 3 else 0)
			var x_front := cx - 4 - int(round(t * 1.0)) + sway
			var x_back := cx + 3 + int(round(t * 3.0)) + sway
			PA.rect(img, x_front, y, x_back - x_front + 1, 1, top)
			PA.rect(img, x_back - 1, y, 2, 1, top_d)
			if i > 11:
				PA.px(img, cx + sway, y, top_d)
			if i == rows - 1:
				PA.rect(img, x_front, y, x_back - x_front + 1, 1, top_d)
		PA.rect(img, cx - 4, neck_y + 9, 9, 1, c.belt)
		if phase == 3:
			PA.rect(img, cx - 1, foot_y, 4, 1, c.feet)
		else:
			PA.rect(img, cx - 6, foot_y, 4, 1, c.feet)
		PA.rect(img, ax - 1, neck_y + 1, 4, 9, top_l)
		PA.rect(img, ax + 2, neck_y + 2, 1, 8, top)
		PA.rect(img, ax - 1, neck_y + 9, 4, 1, top)
		PA.rect(img, ax - 1, neck_y + 10, 2, 2, c.skin)
	else:
		var lt := leg_top - bob
		if phase == 0 or phase == 2:
			PA.rect(img, cx - 2, lt, 4, foot_y - 1 - lt, c.bottom)
			PA.rect(img, cx + 1, lt, 1, foot_y - 1 - lt, c.bottom_d)
			PA.rect(img, cx - 4, foot_y - 1, 6, 2, c.feet)
			PA.rect(img, cx - 4, foot_y, 6, 1, c.feet_d)
		else:
			var near_forward := phase == 1
			var front_c: Color = c.bottom if near_forward else c.bottom_d
			var back_c: Color = c.bottom_d if near_forward else c.bottom
			var front_f: Color = c.feet if near_forward else c.feet_d
			var back_f: Color = c.feet_d if near_forward else c.feet
			PA.rect(img, cx + 1, lt, 3, foot_y - 2 - lt, back_c)
			PA.rect(img, cx + 1, foot_y - 2, 4, 2, back_f)
			PA.rect(img, cx - 4, lt, 3, foot_y - 1 - lt, front_c)
			PA.rect(img, cx - 6, foot_y - 1, 5, 2, front_f)
		PA.rect(img, cx - 4, neck_y, 8, th, top)
		PA.rect(img, cx + 2, neck_y, 2, th, top_d)
		PA.rect(img, cx - 4, neck_y + th - 1, 8, 1, top_d)
		if th >= 8:
			PA.rect(img, cx - 4, neck_y + th - 3, 8, 1, c.belt)
		if outfit == "jupe":
			var sy := neck_y + th - 3
			var sh := foot_y - 2 - sy
			PA.rect(img, cx - 5, sy, 10, sh, c.bottom)
			PA.rect(img, cx + 3, sy, 2, sh, c.bottom_d)
			PA.rect(img, cx - 5, sy + sh - 1, 10, 1, c.bottom_d)
			PA.rect(img, cx - 5, sy, 10, 1, c.belt)
		elif outfit == "tablier":
			PA.rect(img, cx - 5, neck_y + 2, 2, th - 2, c.apron)
		var al := maxi(2, th - 3)
		PA.rect(img, ax, neck_y + 1, 2, al, top_l)
		PA.rect(img, ax, neck_y + 1 + al, 2, 2, c.skin)

	if item == "baton":
		var sx := cx - 10
		var stop := hy - 5
		PA.rect(img, sx, stop, 2, foot_y - bob - stop + 1, c.wood)
		PA.rect(img, sx + 1, stop + 1, 1, foot_y - bob - stop, c.wood_d)
		PA.rect(img, sx - 1, stop - 2, 4, 3, c.wood)
		PA.px(img, sx + 2, stop - 3, c.wood)
		PA.px(img, sx - 1, stop - 2, PA.shade(c.wood, 0.3))
		PA.rect(img, sx, neck_y + 10, 2, 2, c.skin)

	var hx := cx - 7
	var ey := hy + hh / 2
	_head(img, hx, hy, hh, c)
	PA.px(img, hx - 1, ey + 1, c.skin)
	PA.px(img, hx + 7, ey + 1, c.skin_d)
	_hair(img, hx, hy, hh, str(look.get("hair_style", "court")), c, 1)
	PA.rect(img, hx + 2, ey, 1, 2, c.eye)
	PA.px(img, hx + 1, ey + 3, c.skin_dd)
	PA.px(img, hx + 3, ey + 2, c.blush)
	_beard(img, hx, ey, hy, hh, str(look.get("beard", "none")), c, 1)
	_hat(img, hx, hy, hh, str(look.get("hat", "none")), c, 1)
	if item == "pipe":
		PA.rect(img, hx - 2, ey + 3, 2, 1, c.eye)
		PA.rect(img, hx - 4, ey + 2, 2, 2, c.wood)


# ------------------------------------------------------------------- parties

## Tête de 12 px de large dont le coin haut-gauche est (hx, hy).
static func _head(img: Image, hx: int, hy: int, hh: int, c: Dictionary) -> void:
	PA.rect(img, hx, hy + 1, 12, hh - 2, c.skin)
	PA.rect(img, hx + 1, hy, 10, 1, c.skin)
	PA.rect(img, hx + 1, hy + hh - 1, 10, 1, c.skin_d)
	PA.rect(img, hx + 11, hy + 2, 1, hh - 4, c.skin_d)


## view : 0 = face, 1 = profil gauche, 2 = dos.
static func _hair(img: Image, hx: int, hy: int, hh: int, style: String, c: Dictionary, view: int) -> void:
	var hair: Color = c.hair
	var hair_d: Color = c.hair_d
	if style == "chauve":
		match view:
			0:
				PA.rect(img, hx, hy + 3, 1, 3, hair)
				PA.rect(img, hx + 11, hy + 3, 1, 3, hair)
			1:
				PA.rect(img, hx + 7, hy + 3, 5, 3, hair)
			2:
				PA.rect(img, hx, hy + hh - 6, 12, 3, hair)
		return
	PA.rect(img, hx + 1, hy - 1, 10, 1, hair)
	PA.rect(img, hx, hy, 12, 3, hair)
	PA.rect(img, hx + 3, hy, 5, 1, c.hair_l)
	match view:
		0:
			PA.rect(img, hx, hy + 3, 1, 3, hair)
			PA.rect(img, hx + 11, hy + 3, 1, 3, hair_d)
			PA.rect(img, hx + 1, hy + 3, 2, 1, hair)
			PA.rect(img, hx + 9, hy + 3, 2, 1, hair)
		1:
			PA.rect(img, hx + 7, hy + 3, 5, hh - 6, hair)
			PA.rect(img, hx + 10, hy + 3, 2, hh - 6, hair_d)
			PA.rect(img, hx + 1, hy + 3, 2, 1, hair)
		2:
			PA.rect(img, hx, hy + 3, 12, hh - 5, hair)
			PA.rect(img, hx + 9, hy + 3, 3, hh - 5, hair_d)
	match style:
		"long":
			match view:
				0:
					PA.rect(img, hx - 1, hy + 2, 2, hh + 1, hair)
					PA.rect(img, hx + 11, hy + 2, 2, hh + 1, hair_d)
				1:
					PA.rect(img, hx + 7, hy + 3, 6, hh + 1, hair)
					PA.rect(img, hx + 11, hy + 3, 2, hh + 1, hair_d)
				2:
					PA.rect(img, hx - 1, hy + 2, 14, hh + 2, hair)
					PA.rect(img, hx + 10, hy + 3, 3, hh + 1, hair_d)
		"boucles":
			for k in 6:
				PA.px(img, hx + k * 2, hy - 2, hair)
			PA.px(img, hx - 1, hy + 1, hair)
			PA.px(img, hx - 1, hy + 3, hair)
			PA.px(img, hx + 12, hy + 1, hair_d)
			PA.px(img, hx + 12, hy + 3, hair_d)
		"chignon":
			var bx := hx + 6.0
			var by := hy - 2.0
			if view == 1:
				bx = hx + 11.0
				by = hy + 1.0
			PA.ellipse(img, bx, by, 3.0, 3.0, hair)
			PA.px(img, int(bx) - 1, int(by) - 2, c.hair_l)


static func _beard(img: Image, hx: int, ey: int, hy: int, hh: int, style: String, c: Dictionary, view: int) -> void:
	if view == 2 or style == "none":
		return
	var beard: Color = c.beard
	var beard_d: Color = c.beard_d
	match style:
		"longue":
			for i in 10:
				var y := ey + 2 + i
				if view == 0:
					var half := 6 - int(i * 0.56)
					PA.rect(img, hx + 6 - half, y, half * 2, 1, beard)
					PA.px(img, hx + 6 + half - 1, y, beard_d)
				else:
					var wd := 8 - int(i * 0.7)
					var x0 := hx - 1 + i / 4
					PA.rect(img, x0, y, wd, 1, beard)
					PA.px(img, x0 + wd - 1, y, beard_d)
			if view == 0:
				PA.rect(img, hx + 3, ey + 2, 6, 1, c.beard_l)
				PA.rect(img, hx + 2, ey - 1, 3, 1, beard)
				PA.rect(img, hx + 7, ey - 1, 3, 1, beard)
			else:
				PA.rect(img, hx - 1, ey + 2, 4, 1, c.beard_l)
				PA.rect(img, hx + 1, ey - 1, 3, 1, beard)
		"moustache":
			if view == 0:
				PA.rect(img, hx + 3, ey + 2, 6, 1, beard)
				PA.px(img, hx + 2, ey + 3, beard)
				PA.px(img, hx + 9, ey + 3, beard)
			else:
				PA.rect(img, hx - 1, ey + 2, 4, 1, beard)
				PA.px(img, hx - 1, ey + 3, beard)
		"courte":
			var n := hy + hh - (ey + 3)
			if view == 0:
				PA.rect(img, hx + 1, ey + 3, 10, n, beard)
				PA.rect(img, hx + 9, ey + 3, 2, n, beard_d)
				PA.rect(img, hx + 5, ey + 3, 2, 1, c.skin_dd)
			else:
				PA.rect(img, hx, ey + 3, 6, n, beard)


static func _hat(img: Image, hx: int, hy: int, hh: int, kind: String, c: Dictionary, view: int) -> void:
	var hat: Color = c.hat
	var hat_d: Color = c.hat_d
	var hat_l: Color = c.hat_l
	var mid := hx + 6
	match kind:
		"magicien":
			var by := hy + 1
			var dir := -1 if view == 2 else 1
			for i in 12:
				var y := by - 1 - i
				var half := maxi(1, 5 - int(i * 0.42))
				var bend := 0
				if i >= 6:
					bend = int((i - 5) * 0.6) * dir
				PA.rect(img, mid - half + bend, y, half * 2, 1, hat)
				PA.px(img, mid + half - 1 + bend, y, hat_d)
				if half > 2:
					PA.px(img, mid - half + bend, y, hat_l)
			PA.rect(img, mid - 5, by - 2, 10, 2, hat_d)
			PA.rect(img, mid - 9, by, 18, 2, hat)
			PA.rect(img, mid - 9, by + 1, 18, 1, hat_d)
			PA.rect(img, mid - 6, by, 8, 1, hat_l)
		"toque":
			PA.rect(img, mid - 5, hy - 6, 10, 7, hat)
			PA.ellipse(img, float(mid), hy - 6.5, 6.5, 3.5, hat)
			PA.rect(img, mid + 3, hy - 6, 2, 7, hat_d)
			PA.rect(img, mid - 5, hy, 10, 1, hat_d)
			PA.px(img, mid - 3, hy - 8, hat_l)
			PA.px(img, mid - 2, hy - 8, hat_l)
			PA.rect(img, mid - 1, hy - 5, 1, 4, hat_d)
		"casquette":
			PA.rect(img, hx + 2, hy - 2, 8, 1, hat)
			PA.rect(img, hx, hy - 1, 12, 3, hat)
			PA.rect(img, hx + 9, hy - 1, 3, 3, hat_d)
			PA.rect(img, hx + 3, hy - 1, 4, 1, hat_l)
			match view:
				0: PA.rect(img, hx + 1, hy + 2, 10, 1, hat_d)
				1: PA.rect(img, hx - 3, hy + 1, 5, 1, hat_d)
				2: PA.rect(img, hx, hy + 2, 12, 1, hat)
		"capuche":
			PA.rect(img, hx + 2, hy - 2, 8, 1, hat)
			PA.rect(img, hx - 1, hy - 1, 14, 3, hat)
			PA.rect(img, hx + 3, hy - 1, 4, 1, hat_l)
			match view:
				0:
					PA.rect(img, hx - 1, hy + 2, 2, hh - 1, hat)
					PA.rect(img, hx + 11, hy + 2, 2, hh - 1, hat_d)
				1:
					PA.rect(img, hx + 6, hy + 2, 7, hh - 1, hat)
					PA.rect(img, hx + 11, hy + 2, 2, hh - 1, hat_d)
				2:
					PA.rect(img, hx - 1, hy + 2, 14, hh - 1, hat)
					PA.rect(img, hx + 10, hy + 2, 3, hh - 1, hat_d)
		"chapeau_paille":
			PA.rect(img, mid - 5, hy - 3, 10, 4, hat)
			PA.rect(img, mid + 3, hy - 3, 2, 4, hat_d)
			PA.rect(img, mid - 5, hy, 10, 1, c.band)
			PA.rect(img, mid - 9, hy + 1, 18, 1, hat)
			PA.rect(img, mid - 8, hy + 2, 16, 1, hat_d)
			PA.rect(img, mid - 4, hy - 3, 4, 1, hat_l)
		"couronne":
			PA.rect(img, hx + 1, hy - 1, 10, 2, hat)
			PA.rect(img, hx + 1, hy, 10, 1, hat_d)
			for i in 4:
				PA.rect(img, hx + 1 + i * 3, hy - 3, 1, 2, hat)
				PA.px(img, hx + 1 + i * 3, hy - 4, hat_l)
			PA.px(img, hx + 4, hy - 1, c.band)
			PA.px(img, hx + 7, hy - 1, c.band)
		"heaume":
			PA.rect(img, hx, hy - 2, 12, 5, hat)
			PA.rect(img, hx + 9, hy - 2, 3, 5, hat_d)
			PA.rect(img, hx + 2, hy - 2, 4, 1, hat_l)
			for i in 3:
				var extra := 3 if i == 1 else 0
				PA.rect(img, hx + 1 + i * 5, hy - 6 - extra, 1, 4 + extra, hat)
				PA.px(img, hx + 1 + i * 5, hy - 7 - extra, hat_l)
			if view == 0:
				PA.rect(img, hx + 5, hy + 3, 2, 4, hat_d)
				PA.rect(img, hx, hy + 3, 1, 5, hat)
				PA.rect(img, hx + 11, hy + 3, 1, 5, hat_d)
		"foulard":
			PA.rect(img, hx + 1, hy - 1, 10, 1, hat)
			PA.rect(img, hx, hy, 12, 4, hat)
			PA.rect(img, hx + 3, hy, 4, 1, hat_l)
			match view:
				0:
					PA.rect(img, hx, hy + 4, 1, hh - 5, hat)
					PA.rect(img, hx + 11, hy + 4, 1, hh - 5, hat_d)
					PA.rect(img, hx + 5, hy + hh - 1, 2, 2, hat_d)
				1:
					PA.rect(img, hx + 7, hy + 4, 5, hh - 5, hat)
					PA.rect(img, hx + 10, hy + 4, 2, hh - 5, hat_d)
				2:
					PA.rect(img, hx, hy + 4, 12, hh - 5, hat)
					PA.rect(img, hx + 9, hy + 4, 3, hh - 5, hat_d)
					PA.rect(img, hx + 4, hy + hh - 1, 4, 2, hat_d)
