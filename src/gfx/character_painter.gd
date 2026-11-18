extends RefCounted
## Peint la planche de sprites d'un personnage à partir d'une description (« look »).
##
## Format de la planche générée (voir assets/sprites/README.md) :
##   cases de 32 x 48 px, 11 colonnes, 4 lignes dans l'ordre : bas, gauche, droite, haut.
##   colonnes 0 à 2  : repos (normal, respiration, clignement)
##   colonnes 3 à 6  : marche (appui gauche, passage, appui droit, passage)
##   colonnes 7 à 10 : combat (attaque, sort, coup reçu, KO)
##
## « species » choisit le corps : grobitte/humain (par défaut), "morfale", "naze".

const PA = preload("res://src/gfx/pixel_art.gd")

const FRAME_W := 32
const FRAME_H := 48
const COLUMNS := 11
const ROWS := 4
const FOOT_MARGIN := 2   # pixels vides sous les pieds dans chaque case
const IDLE := [0, 0, 1, 1, 0, 0, 1, 1, 0, 2, 1, 1]   # suite jouée au repos (4 images/s)
const WALK := [3, 4, 5, 6]
const POSES := {"attack": 7, "cast": 8, "hit": 9, "ko": 10}

const WHITE := Color("#ffffff")
const GOLD := Color("#f2c84a")
const GOLD_D := Color("#b8862a")
const RED := Color("#c8403a")


static func paint_sheet(look: Dictionary) -> Image:
	var img := PA.new_image(FRAME_W * COLUMNS, FRAME_H * ROWS)
	var c := _colors(look)
	var species := str(look.get("species", ""))
	for col in COLUMNS:
		var p := _pose(col)
		var ox := col * FRAME_W
		match species:
			"morfale":
				_morfale(img, ox, 0, look, c, p, 0)
				_morfale(img, ox, FRAME_H, look, c, p, 1)
				_morfale(img, ox, FRAME_H * 3, look, c, p, 2)
			"naze":
				_naze(img, ox, 0, c, p, 0)
				_naze(img, ox, FRAME_H, c, p, 1)
				_naze(img, ox, FRAME_H * 3, c, p, 2)
			_:
				_front(img, ox, 0, look, c, p, false)
				_side(img, ox, FRAME_H, look, c, p)
				_front(img, ox, FRAME_H * 3, look, c, p, true)
		for row: int in [0, 1, 3]:
			PA.outline(img, Rect2i(ox, row * FRAME_H, FRAME_W, FRAME_H))
		# La ligne « droite » est le miroir de la ligne « gauche ».
		var left := img.get_region(Rect2i(ox, FRAME_H, FRAME_W, FRAME_H))
		left.flip_x()
		img.blit_rect(left, Rect2i(0, 0, FRAME_W, FRAME_H), Vector2i(ox, FRAME_H * 2))
	return img


## Portrait 48 x 48 : la tête de face, agrandie deux fois avec lissage des diagonales.
static func paint_portrait(look: Dictionary) -> Image:
	var bare := look.duplicate()
	bare["item"] = "none"          # pas de bâton ni de pipe en travers du portrait
	var sheet := paint_sheet(bare)
	var b := PA.opaque_bounds(sheet, Rect2i(0, 0, FRAME_W, FRAME_H))
	var side := 24
	var x := (FRAME_W - side) / 2
	var y := clampi(b.position.y - 1, 0, FRAME_H - side)
	if str(look.get("species", "")) == "":
		# cadré sur le visage : un grand chapeau est coupé en haut plutôt que le menton en bas
		var head_y: int = _layout(look, _pose(0), 0, 0)["hy"]
		y = clampi(maxi(y, head_y - 8), 0, FRAME_H - side)
	return _scale2x(sheet.get_region(Rect2i(x, y, side, side)))


## Agrandissement x2 qui adoucit les escaliers (algorithme Scale2x).
static func _scale2x(src: Image) -> Image:
	var w := src.get_width()
	var h := src.get_height()
	var out := Image.create(w * 2, h * 2, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var e := src.get_pixel(x, y)
			var b := src.get_pixel(x, maxi(0, y - 1))
			var d := src.get_pixel(maxi(0, x - 1), y)
			var f := src.get_pixel(mini(w - 1, x + 1), y)
			var hh := src.get_pixel(x, mini(h - 1, y + 1))
			var e0 := e
			var e1 := e
			var e2 := e
			var e3 := e
			if not b.is_equal_approx(hh) and not d.is_equal_approx(f):
				if d.is_equal_approx(b):
					e0 = d
				if b.is_equal_approx(f):
					e1 = f
				if d.is_equal_approx(hh):
					e2 = d
				if hh.is_equal_approx(f):
					e3 = f
			out.set_pixel(x * 2, y * 2, e0)
			out.set_pixel(x * 2 + 1, y * 2, e1)
			out.set_pixel(x * 2, y * 2 + 1, e2)
			out.set_pixel(x * 2 + 1, y * 2 + 1, e3)
	return out


## Trait d'un pixel d'épaisseur.
static func _line(img: Image, x0: int, y0: int, x1: int, y1: int, color: Color) -> void:
	var steps := maxi(absi(x1 - x0), absi(y1 - y0))
	if steps == 0:
		PA.px(img, x0, y0, color)
		return
	for i in steps + 1:
		var t := float(i) / float(steps)
		PA.px(img, int(round(lerpf(float(x0), float(x1), t))), int(round(lerpf(float(y0), float(y1), t))), color)


static func _col(look: Dictionary, key: String, fallback: String) -> Color:
	return Color.from_string(str(look.get(key, fallback)), Color.from_string(fallback, Color.GRAY))


static func _colors(look: Dictionary) -> Dictionary:
	var skin := _col(look, "skin", "#e8b48a")
	var hair := _col(look, "hair", "#6b4a2e")
	var top := _col(look, "top", "#4f7d5a")
	var bottom := _col(look, "bottom", "#6b5238")
	var hat := _col(look, "hat_color", "#6f7390")
	var beard := _col(look, "beard_color", "#d9d9e0")
	var boots := str(look.get("feet", "nus")) == "bottes"
	var feet := _col(look, "boots", "#4a3426") if boots else skin
	return {
		"skin": skin, "skin_d": PA.shade(skin, -0.2), "skin_dd": PA.shade(skin, -0.45),
		"skin_l": PA.shade(skin, 0.22), "blush": skin.lerp(Color("#e0705a"), 0.45),
		"hair": hair, "hair_d": PA.shade(hair, -0.3), "hair_l": PA.shade(hair, 0.28),
		"top": top, "top_d": PA.shade(top, -0.28), "top_l": PA.shade(top, 0.22),
		"bottom": bottom, "bottom_d": PA.shade(bottom, -0.28), "bottom_l": PA.shade(bottom, 0.2),
		"feet": feet, "feet_d": PA.shade(feet, -0.28), "feet_l": PA.shade(feet, 0.2), "boots": boots,
		"hat": hat, "hat_d": PA.shade(hat, -0.3), "hat_l": PA.shade(hat, 0.25),
		"band": _col(look, "band", "#b0483c"),
		"beard": beard, "beard_d": PA.shade(beard, -0.22), "beard_l": PA.shade(beard, 0.3),
		"eye": Color("#2b1b2e"),
		"belt": _col(look, "belt", "#4a3426"),
		"wood": Color("#8a5a34"), "wood_d": Color("#553621"), "wood_l": Color("#b07a48"),
		"apron": Color("#efe6d2"), "apron_d": Color("#c9bda6"),
	}


## Pose d'une colonne de la planche.
static func _pose(col: int) -> Dictionary:
	var p := {"bob": 0, "lift_l": 0, "lift_r": 0, "stride": 0, "pass": 0, "arm": 0, "arms": "down",
		"eyes": "open", "mouth": "smile", "lean": 0}
	match col:
		1:
			p["bob"] = 1
		2:
			p["eyes"] = "closed"
		3:
			p["lift_r"] = 3
			p["stride"] = 4
			p["arm"] = 2
			p["bob"] = 1
		4:
			p["lift_r"] = 1
			p["pass"] = 1
		5:
			p["lift_l"] = 3
			p["stride"] = -4
			p["arm"] = -2
			p["bob"] = 1
		6:
			p["lift_l"] = 1
			p["pass"] = -1
		7:
			p["arms"] = "strike"
			p["lean"] = 3
			p["stride"] = 3
			p["mouth"] = "open"
			p["eyes"] = "angry"
		8:
			p["arms"] = "up"
			p["bob"] = -1
			p["mouth"] = "open"
			p["eyes"] = "closed"
		9:
			p["arms"] = "flail"
			p["lean"] = -3
			p["stride"] = -2
			p["mouth"] = "grit"
			p["eyes"] = "pain"
		10:
			# KO : affaissé, jambes repliées, tête rentrée dans les épaules
			p["lean"] = -2
			p["mouth"] = "open"
			p["eyes"] = "pain"
			p["bob"] = 3
			p["crouch"] = 3
	return p


static func _layout(look: Dictionary, p: Dictionary, ox: int, oy: int) -> Dictionary:
	var head_h := 11
	var head_w := 14
	var torso_h := 9
	var leg_h := 5
	var half := 5          # demi-largeur du torse
	match str(look.get("build", "petit")):
		"grand":
			head_h = 11
			head_w = 12
			torso_h = 12
			leg_h = 8
		"enfant":
			head_h = 10
			head_w = 12
			torso_h = 6
			leg_h = 3
			half = 4
	var bob := int(p["bob"])
	leg_h = maxi(2, leg_h - int(p.get("crouch", 0)))
	var foot_y := oy + FRAME_H - 1 - FOOT_MARGIN
	var hip_y := foot_y - leg_h
	var neck_y := hip_y - torso_h + bob
	return {
		"cx": ox + FRAME_W / 2, "foot_y": foot_y, "hip_y": hip_y, "neck_y": neck_y,
		"hy": neck_y - head_h, "hh": head_h, "hw": head_w, "torso_h": torso_h, "half": half,
		"leg_h": leg_h,
	}


# ---------------------------------------------------------------- face / dos

static func _front(img: Image, ox: int, oy: int, look: Dictionary, c: Dictionary, p: Dictionary, back: bool) -> void:
	var L := _layout(look, p, ox, oy)
	var cx: int = L["cx"]
	var foot_y: int = L["foot_y"]
	var hip_y: int = L["hip_y"]
	var neck_y: int = L["neck_y"]
	var hy: int = L["hy"]
	var hh: int = L["hh"]
	var hw: int = L["hw"]
	var th: int = L["torso_h"]
	var half: int = L["half"]
	var outfit := str(look.get("outfit", "tunique"))
	var item := str(look.get("item", "none"))
	var hair_style := str(look.get("hair_style", "court"))
	var arms := str(p["arms"])
	var view := 2 if back else 0

	# cheveux longs : la masse passe derrière les épaules
	if hair_style == "long" and not back:
		PA.rect(img, cx - hw / 2 - 1, hy + 3, hw + 2, hh + 2, c["hair_d"])

	# jambes et pieds
	for s: int in [-1, 1]:
		var lift := int(p["lift_l"]) if s < 0 else int(p["lift_r"])
		var lx := cx - 4 if s < 0 else cx + 1
		_leg_front(img, lx, s, hip_y, foot_y - lift, c)

	# le haut du corps se déhanche d'un pixel du côté du pied d'appui
	cx += signi(int(p["arm"]))

	# torse
	PA.rect(img, cx - half, neck_y, half * 2, th, c["top"])
	if str(look.get("build", "petit")) == "petit":
		PA.rect(img, cx - half - 1, neck_y + 3, half * 2 + 2, th - 5, c["top"])   # petit ventre
	PA.rect(img, cx - half, neck_y, 1, th, c["top_l"])
	PA.rect(img, cx + half - 2, neck_y + 1, 2, th - 1, c["top_d"])
	PA.rect(img, cx - half, neck_y + th - 1, half * 2, 1, c["top_d"])
	match outfit:
		"tunique":
			if not back:
				PA.px(img, cx - 1, neck_y, c["skin_d"])
				PA.px(img, cx, neck_y, c["skin_d"])
				PA.px(img, cx - 1, neck_y + 1, c["top_d"])
				PA.px(img, cx, neck_y + 2, c["top_d"])
			PA.rect(img, cx - half, neck_y + th - 3, half * 2, 1, c["belt"])
			if not back:
				PA.px(img, cx - 1, neck_y + th - 3, GOLD)
		"tablier":
			PA.rect(img, cx - half, neck_y + th - 3, half * 2, 1, c["belt"])
			if not back:
				var ah := mini(th + 1, foot_y - neck_y - 3)   # le tablier ne dépasse pas les pieds
				PA.rect(img, cx - 3, neck_y + 2, 6, ah, c["apron"])
				PA.rect(img, cx + 2, neck_y + 3, 1, ah - 1, c["apron_d"])
				PA.rect(img, cx - 3, neck_y + 1 + ah, 6, 1, c["apron_d"])
				PA.px(img, cx - 3, neck_y + 1, c["apron"])
				PA.px(img, cx + 2, neck_y + 1, c["apron"])
				PA.rect(img, cx - 1, neck_y + 6, 3, 1, c["apron_d"])
			else:
				PA.px(img, cx - 1, neck_y + th - 3, c["apron"])
				PA.px(img, cx, neck_y + th - 3, c["apron"])
				PA.px(img, cx - 1, neck_y + th - 2, c["apron"])
		"jupe":
			var top_y := neck_y + th - 3
			var rows := foot_y - 2 - top_y
			for i in rows:
				var w := half + 1 + (i + 1) / 2
				PA.rect(img, cx - w, top_y + i, w * 2, 1, c["bottom"])
				PA.px(img, cx + w - 1, top_y + i, c["bottom_d"])
				PA.px(img, cx - w, top_y + i, c["bottom_l"])
				PA.px(img, cx - 2, top_y + i, c["bottom_d"])
				PA.px(img, cx + 2, top_y + i, c["bottom_d"])
			PA.rect(img, cx - half - 1 - rows / 2, top_y + rows - 1, (half + 1 + rows / 2) * 2, 1, c["bottom_l"])
			PA.rect(img, cx - half, top_y, half * 2, 1, c["belt"])
		"robe":
			var top_y := neck_y + th - 1
			var rows := foot_y - 1 - top_y
			for i in rows:
				var w := half + (i + 2) / 3
				PA.rect(img, cx - w, top_y + i, w * 2, 1, c["top"])
				PA.px(img, cx + w - 1, top_y + i, c["top_d"])
				PA.px(img, cx + w - 2, top_y + i, c["top_d"])
				PA.px(img, cx - w, top_y + i, c["top_l"])
				if i > 1:
					PA.px(img, cx - 2, top_y + i, c["top_d"])
					PA.px(img, cx + 1, top_y + i, c["top_d"])
			PA.rect(img, cx - half - rows / 3, top_y + rows - 1, (half + rows / 3) * 2, 1, c["top_d"])
			PA.rect(img, cx - half, neck_y + th - 3, half * 2, 1, c["belt"])
			if not back:
				PA.rect(img, cx - 2, neck_y + th - 2, 1, 3, c["belt"])

	# bras
	for s: int in [-1, 1]:
		var ax := cx - half - 2 if s < 0 else cx + half
		var swing := int(p["arm"]) * s
		var mode := arms
		if arms == "strike" and s < 0:
			mode = "down"
		_arm_front(img, ax, s, neck_y + 1, th - 2 + swing, mode, c)

	# objet tenu (dans la main droite de l'écran)
	if item == "baton":
		var bx := cx + half + 2
		var top := hy + 1 if arms != "up" else hy - 5
		PA.rect(img, bx, top, 2, foot_y - top + 1, c["wood"])
		PA.rect(img, bx + 1, top, 1, foot_y - top + 1, c["wood_d"])
		PA.rect(img, bx - 1, top - 2, 4, 3, c["wood"])
		PA.px(img, bx, top - 2, c["wood_l"])
		if arms == "up":
			PA.px(img, bx, top - 3, GOLD)
			PA.px(img, bx + 1, top - 4, WHITE)
		if not back:
			PA.rect(img, bx - 1, neck_y + th - 3, 3, 2, c["skin"])

	# tête
	_head_front(img, cx, hy, hw, hh, look, c, p, back)
	if item == "pipe" and not back:
		var my := hy + hh / 2 + 4
		PA.rect(img, cx + 1, my, 3, 1, c["wood_d"])
		PA.rect(img, cx + 4, my - 1, 2, 2, c["wood"])
	if view == 0 and str(look.get("hat", "none")) == "capuche":
		PA.rect(img, cx - half, neck_y, half * 2, 1, c["hat_d"])


static func _leg_front(img: Image, x: int, side: int, top_y: int, foot_y: int, c: Dictionary) -> void:
	PA.rect(img, x, top_y, 3, foot_y - top_y, c["bottom"])
	PA.rect(img, x + 2, top_y, 1, foot_y - top_y, c["bottom_d"])
	var fx := x - 1 if side < 0 else x
	if bool(c["boots"]):
		PA.rect(img, x, foot_y - 3, 3, 3, c["feet"])
		PA.rect(img, x, foot_y - 3, 3, 1, c["feet_l"])
		PA.rect(img, fx, foot_y - 1, 4, 2, c["feet"])
		PA.rect(img, fx, foot_y, 4, 1, c["feet_d"])
	else:
		# grands pieds nus de Grobitte, avec leur touffe de poils
		PA.rect(img, fx, foot_y - 1, 4, 2, c["feet"])
		PA.rect(img, fx, foot_y, 4, 1, c["skin_d"])
		PA.px(img, x + 1, foot_y - 1, c["hair"])


static func _arm_front(img: Image, x: int, side: int, top_y: int, length: int, mode: String, c: Dictionary) -> void:
	match mode:
		"up":
			var ux := x + side
			PA.rect(img, ux, top_y - 5, 2, 7, c["top"])
			PA.rect(img, ux + (1 if side > 0 else 0), top_y - 5, 1, 7, c["top_d"])
			PA.rect(img, ux, top_y - 7, 2, 2, c["skin"])
		"strike":
			PA.rect(img, x, top_y - 1, 2, 3, c["top"])
			PA.rect(img, x + side, top_y - 4, 2, 4, c["top"])
			PA.rect(img, x + side, top_y - 6, 2, 2, c["skin"])
		"flail":
			# bras jetés en l'air, coude plié, reliés à l'épaule
			PA.rect(img, x, top_y, 2, 3, c["top"])
			PA.rect(img, x + side, top_y - 3, 2, 4, c["top"])
			PA.px(img, x + side, top_y, c["top_d"])
			PA.rect(img, x + side * 2, top_y - 5, 2, 2, c["skin"])
		_:
			PA.rect(img, x, top_y, 2, length, c["top"])
			PA.rect(img, x + (1 if side > 0 else 0), top_y + 1, 1, length - 1, c["top_d"])
			PA.rect(img, x, top_y + length - 2, 2, 2, c["skin"])
			PA.px(img, x + (1 if side > 0 else 0), top_y + length - 1, c["skin_d"])


static func _head_front(img: Image, cx: int, hy: int, hw: int, hh: int, look: Dictionary, c: Dictionary, p: Dictionary, back: bool) -> void:
	var x0 := cx - hw / 2
	var ey := hy + hh / 2
	var my := ey + 4
	var view := 2 if back else 0
	PA.rect(img, x0 + 1, hy, hw - 2, hh, c["skin"])
	PA.rect(img, x0, hy + 2, hw, hh - 4, c["skin"])
	PA.rect(img, x0 + hw - 1, hy + 2, 1, hh - 4, c["skin_d"])
	PA.rect(img, x0 + 2, hy + hh - 1, hw - 4, 1, c["skin_d"])
	PA.rect(img, x0 + 2, hy + 1, 3, 1, c["skin_l"])
	# oreilles un peu pointues
	PA.rect(img, x0 - 1, ey, 1, 2, c["skin"])
	PA.px(img, x0 - 1, ey - 1, c["skin_d"])
	PA.rect(img, x0 + hw, ey, 1, 2, c["skin_d"])
	PA.px(img, x0 + hw, ey - 1, c["skin_d"])
	if not back:
		var ex := 4 if hw >= 14 else 3
		_eye(img, cx - ex, ey, str(p["eyes"]), -1, c)
		_eye(img, cx + ex - 2, ey, str(p["eyes"]), 1, c)
		if str(look.get("build", "petit")) != "enfant":
			var down := 1 if str(p["eyes"]) == "angry" else 0
			PA.rect(img, cx - ex, ey - 2 + down, 2, 1, c["hair_d"])
			PA.rect(img, cx + ex - 2, ey - 2 + down, 2, 1, c["hair_d"])
			if down == 1:
				PA.px(img, cx - ex - 1, ey - 2, c["hair_d"])
				PA.px(img, cx + ex, ey - 2, c["hair_d"])
		PA.px(img, cx - 1, ey + 2, c["skin_d"])
		PA.px(img, cx - ex - 1, ey + 3, c["blush"])
		PA.px(img, cx - ex, ey + 3, c["blush"])
		PA.px(img, cx + ex - 1, ey + 3, c["blush"])
		PA.px(img, cx + ex, ey + 3, c["blush"])
	_hair(img, x0, hw, hy, hh, str(look.get("hair_style", "court")), c, view)
	if not back:
		_beard(img, x0, hw, ey, hy, hh, str(look.get("beard", "none")), c, 0)
		_mouth(img, cx - 1, my, str(p["mouth"]), c, str(look.get("beard", "none")) == "moustache")
	_hat(img, x0, hw, hy, hh, str(look.get("hat", "none")), c, view)


static func _eye(img: Image, x: int, ey: int, mode: String, side: int, c: Dictionary) -> void:
	match mode:
		"closed":
			PA.rect(img, x, ey + 1, 2, 1, c["eye"])
		"pain":
			# yeux en chevrons : > <
			var a := x if side < 0 else x + 1
			var b := x + 1 if side < 0 else x
			PA.px(img, a, ey, c["eye"])
			PA.px(img, b, ey + 1, c["eye"])
			PA.px(img, a, ey + 2, c["eye"])
		_:
			PA.rect(img, x, ey, 2, 3, c["eye"])
			PA.px(img, x, ey, WHITE)


static func _mouth(img: Image, x: int, my: int, mode: String, c: Dictionary, hidden: bool) -> void:
	match mode:
		"open":
			PA.rect(img, x, my, 2, 2, c["eye"])
			PA.px(img, x, my + 1, RED)
		"grit":
			PA.rect(img, x - 1, my, 4, 1, WHITE)
			PA.px(img, x - 1, my, c["skin_dd"])
			PA.px(img, x + 2, my, c["skin_dd"])
		_:
			if not hidden:
				PA.rect(img, x, my, 2, 1, c["skin_dd"])


# ------------------------------------------------------------------- profil

## Profil tourné vers la gauche.
static func _side(img: Image, ox: int, oy: int, look: Dictionary, c: Dictionary, p: Dictionary) -> void:
	var L := _layout(look, p, ox, oy)
	var cx: int = L["cx"]
	var foot_y: int = L["foot_y"]
	var hip_y: int = L["hip_y"]
	var neck_y: int = L["neck_y"]
	var hy: int = L["hy"]
	var hh: int = L["hh"]
	var hw: int = L["hw"]
	var th: int = L["torso_h"]
	var outfit := str(look.get("outfit", "tunique"))
	var item := str(look.get("item", "none"))
	var arms := str(p["arms"])
	var lean := int(p["lean"])
	var tdx := -lean / 2      # le haut du corps penche vers l'avant (la gauche)
	var hdx := -lean
	var stride := int(p["stride"])
	var pass_k := int(p["pass"])
	var petit := str(look.get("build", "petit")) == "petit"
	var w := hw - 2
	var x0 := cx - w / 2 - 1 + hdx
	var hair_style := str(look.get("hair_style", "court"))

	if hair_style == "long":
		PA.rect(img, x0 + w - 4, hy + 3, 5, hh + 3, c["hair_d"])

	# bras du fond
	var sx := cx + tdx
	var al := th - 2
	if arms == "down":
		_arm_side(img, sx, neck_y + 2, sx - int(p["arm"]) * 2, neck_y + al, c["top_d"], c["skin_d"])

	# jambes : celle du fond d'abord
	var far_dx := stride
	var near_dx := -stride
	var far_lift := 2 if pass_k == 1 else 0
	var near_lift := 2 if pass_k == -1 else 0
	if pass_k == 1:
		far_dx = -1
	elif pass_k == -1:
		near_dx = -1
	_leg_side(img, cx - 1 + far_dx, hip_y, foot_y - far_lift, c, true)
	_leg_side(img, cx - 2 + near_dx, hip_y, foot_y - near_lift, c, false)

	# torse
	PA.rect(img, cx - 3 + tdx, neck_y, 7, th, c["top"])
	if petit:
		PA.rect(img, cx - 4 + tdx, neck_y + 3, 1, th - 5, c["top"])
	PA.rect(img, cx + 2 + tdx, neck_y + 1, 2, th - 1, c["top_d"])
	PA.rect(img, cx - 3 + tdx, neck_y + th - 1, 7, 1, c["top_d"])
	match outfit:
		"tunique":
			PA.rect(img, cx - 3 + tdx, neck_y + th - 3, 7, 1, c["belt"])
			if petit:
				PA.px(img, cx - 4 + tdx, neck_y + th - 3, c["belt"])
		"tablier":
			PA.rect(img, cx - 3 + tdx, neck_y + th - 3, 7, 1, c["belt"])
			var ah := mini(th + 1, foot_y - neck_y - 3)
			PA.rect(img, cx - 4 + tdx, neck_y + 2, 2, ah, c["apron"])
			PA.rect(img, cx - 4 + tdx, neck_y + 1 + ah, 2, 1, c["apron_d"])
			PA.px(img, cx + 3 + tdx, neck_y + th - 3, c["apron"])
		"jupe":
			var top_y := neck_y + th - 3
			var rows := foot_y - 2 - top_y
			for i in rows:
				var half := 4 + (i + 1) / 2
				PA.rect(img, cx - half, top_y + i, half * 2, 1, c["bottom"])
				PA.px(img, cx + half - 1, top_y + i, c["bottom_d"])
				PA.px(img, cx, top_y + i, c["bottom_d"])
			PA.rect(img, cx - 4 - rows / 2, top_y + rows - 1, (4 + rows / 2) * 2, 1, c["bottom_l"])
			PA.rect(img, cx - 3, top_y, 7, 1, c["belt"])
		"robe":
			var top_y := neck_y + th - 1
			var rows := foot_y - 1 - top_y
			for i in rows:
				var half := 4 + (i + 2) / 3
				PA.rect(img, cx - half + tdx / 2, top_y + i, half * 2, 1, c["top"])
				PA.px(img, cx + half - 1 + tdx / 2, top_y + i, c["top_d"])
				PA.px(img, cx + half - 2 + tdx / 2, top_y + i, c["top_d"])
				if i > 1:
					PA.px(img, cx - 1 + tdx / 2, top_y + i, c["top_d"])
			PA.rect(img, cx - 4 - rows / 3, top_y + rows - 1, (4 + rows / 3) * 2, 1, c["top_d"])
			PA.rect(img, cx - 3 + tdx, neck_y + th - 3, 7, 1, c["belt"])

	# tête
	_head_side(img, x0, w, hy, hh, look, c, p)

	# bras du premier plan et objet
	var hand := Vector2i(sx + int(p["arm"]) * 2, neck_y + al)
	if item == "baton" and arms == "down":
		hand = Vector2i(cx - 8, neck_y + al - 2)   # la main tient le bâton, devant lui
	match arms:
		"up":
			# bras tendus devant soi, sous le menton : le visage reste dégagé
			hand = Vector2i(sx - 9, neck_y + 1)
			_arm_side(img, sx + 1, neck_y + 3, sx - 6, neck_y + 4, c["top_d"], c["skin_d"])
		"strike":
			hand = Vector2i(sx - 7, neck_y + 3)
		"flail":
			hand = Vector2i(sx + 6, neck_y - 2)
			_arm_side(img, sx - 1, neck_y + 2, sx - 6, neck_y + 5, c["top_d"], c["skin_d"])
	_arm_side(img, sx, neck_y + 2, hand.x, hand.y, c["top"], c["skin"])
	if item == "baton":
		match arms:
			"strike":
				_line(img, hand.x + 3, hand.y + 4, hand.x - 4, hand.y - 12, c["wood"])
				_line(img, hand.x + 4, hand.y + 4, hand.x - 3, hand.y - 12, c["wood_d"])
				PA.rect(img, hand.x - 5, hand.y - 14, 3, 3, c["wood"])
			"up":
				PA.rect(img, hand.x, hand.y - 9, 2, 20, c["wood"])
				PA.rect(img, hand.x + 1, hand.y - 9, 1, 20, c["wood_d"])
				PA.rect(img, hand.x - 1, hand.y - 11, 4, 3, c["wood"])
				PA.px(img, hand.x, hand.y - 12, GOLD)
				PA.px(img, hand.x - 1, hand.y - 13, WHITE)
			"flail":
				_line(img, hand.x, hand.y + 6, hand.x + 5, hand.y - 10, c["wood"])
			_:
				var bx := cx - 9
				PA.rect(img, bx, hy + 1, 2, foot_y - hy, c["wood"])
				PA.rect(img, bx + 1, hy + 1, 1, foot_y - hy, c["wood_d"])
				PA.rect(img, bx - 1, hy - 1, 4, 3, c["wood"])
				PA.px(img, bx, hy - 1, c["wood_l"])
				PA.rect(img, bx, neck_y + al - 1, 2, 2, c["skin"])
		if arms != "down":
			PA.rect(img, hand.x, hand.y, 2, 2, c["skin"])
	elif item == "pipe":
		var my := hy + hh / 2 + 4
		PA.rect(img, x0 - 2, my, 2, 1, c["wood_d"])
		PA.rect(img, x0 - 4, my - 1, 2, 2, c["wood"])


static func _leg_side(img: Image, x: int, top_y: int, foot_y: int, c: Dictionary, far: bool) -> void:
	var col: Color = c["bottom_d"] if far else c["bottom"]
	PA.rect(img, x, top_y, 3, foot_y - top_y, col)
	if not far:
		PA.rect(img, x + 2, top_y, 1, foot_y - top_y, c["bottom_d"])
	var feet: Color = c["feet_d"] if far else c["feet"]
	if bool(c["boots"]):
		PA.rect(img, x, foot_y - 3, 3, 3, feet)
		PA.rect(img, x - 2, foot_y - 1, 5, 2, feet)
		PA.rect(img, x - 2, foot_y, 5, 1, c["feet_d"])
	else:
		PA.rect(img, x - 2, foot_y - 1, 5, 2, feet)
		PA.rect(img, x - 2, foot_y, 5, 1, c["skin_d"])
		if not far:
			PA.px(img, x, foot_y - 1, c["hair"])


## Bras de profil : un trait épais de l'épaule à la main.
static func _arm_side(img: Image, x0: int, y0: int, x1: int, y1: int, sleeve: Color, skin: Color) -> void:
	_line(img, x0, y0, x1, y1, sleeve)
	_line(img, x0 + 1, y0, x1 + 1, y1, sleeve)
	PA.rect(img, x1, y1, 2, 2, skin)


static func _head_side(img: Image, x0: int, w: int, hy: int, hh: int, look: Dictionary, c: Dictionary, p: Dictionary) -> void:
	var ey := hy + hh / 2
	var my := ey + 4
	PA.rect(img, x0 + 1, hy, w - 2, hh, c["skin"])
	PA.rect(img, x0, hy + 2, w, hh - 4, c["skin"])
	PA.rect(img, x0 + w - 2, hy + 2, 2, hh - 4, c["skin_d"])
	PA.rect(img, x0 + 2, hy + hh - 1, w - 4, 1, c["skin_d"])
	PA.px(img, x0 - 1, ey + 2, c["skin"])          # nez
	PA.px(img, x0 - 1, ey + 3, c["skin_d"])
	PA.rect(img, x0 + w - 5, ey, 2, 2, c["skin_d"])   # oreille
	PA.px(img, x0 + w - 4, ey - 1, c["skin_d"])
	_eye(img, x0 + 2, ey, str(p["eyes"]), 1, c)
	if str(look.get("build", "petit")) != "enfant":
		var down := 1 if str(p["eyes"]) == "angry" else 0
		PA.rect(img, x0 + 1, ey - 2 + down, 3, 1, c["hair_d"])
	PA.px(img, x0 + 4, ey + 3, c["blush"])
	PA.px(img, x0 + 5, ey + 3, c["blush"])
	_hair(img, x0, w, hy, hh, str(look.get("hair_style", "court")), c, 1)
	_beard(img, x0, w, ey, hy, hh, str(look.get("beard", "none")), c, 1)
	match str(p["mouth"]):
		"open":
			PA.rect(img, x0, my, 2, 2, c["eye"])
			PA.px(img, x0 + 1, my + 1, RED)
		"grit":
			PA.rect(img, x0, my, 3, 1, WHITE)
		_:
			if str(look.get("beard", "none")) != "moustache":
				PA.rect(img, x0 + 1, my, 2, 1, c["skin_dd"])
	_hat(img, x0, w, hy, hh, str(look.get("hat", "none")), c, 1)


# ------------------------------------------------- cheveux, barbes, chapeaux
# view : 0 face, 1 profil gauche, 2 dos. x0 : bord gauche de la tête, w : sa largeur.

static func _hair(img: Image, x0: int, w: int, hy: int, hh: int, style: String, c: Dictionary, view: int) -> void:
	if style == "chauve":
		PA.rect(img, x0 + 3, hy + 1, 2, 1, c["skin_l"])
		return
	if view == 2:
		# de dos : toute la tête est couverte
		PA.rect(img, x0 + 1, hy - 1, w - 2, hh - 1, c["hair"])
		PA.rect(img, x0, hy + 1, w, hh - 4, c["hair"])
		PA.rect(img, x0 + w - 2, hy + 2, 2, hh - 5, c["hair_d"])
		PA.rect(img, x0 + 2, hy, 3, 1, c["hair_l"])
		for i in 3:
			PA.rect(img, x0 + 3 + i * 3, hy + 3, 1, hh - 6, c["hair_d"])
		match style:
			"long":
				PA.rect(img, x0, hy + hh - 4, w, 8, c["hair"])
				PA.rect(img, x0 + w - 2, hy + hh - 4, 2, 8, c["hair_d"])
				PA.rect(img, x0 + 1, hy + hh + 3, w - 2, 1, c["hair_d"])
				for i in 3:
					PA.rect(img, x0 + 3 + i * 3, hy + hh - 4, 1, 7, c["hair_d"])
			"chignon":
				PA.ellipse(img, x0 + w * 0.5, hy + 3.0, 3.0, 3.0, c["hair_d"])
				PA.ellipse(img, x0 + w * 0.5 - 0.5, hy + 2.5, 1.6, 1.6, c["hair"])
			"boucles":
				for i in 5:
					PA.ellipse(img, x0 + 1.5 + i * (w - 3) / 4.0, hy - 0.5, 2.0, 2.0, c["hair"])
					PA.px(img, x0 + 1 + i * (w - 3) / 4, hy - 1, c["hair_l"])
				PA.ellipse(img, x0 + 0.5, hy + 5.0, 1.8, 2.5, c["hair"])
				PA.ellipse(img, x0 + w - 0.5, hy + 5.0, 1.8, 2.5, c["hair_d"])
		return
	if view == 0:
		PA.rect(img, x0 + 1, hy - 1, w - 2, 3, c["hair"])
		PA.rect(img, x0, hy + 1, w, 2, c["hair"])
		PA.rect(img, x0, hy + 3, 1, 3, c["hair"])
		PA.rect(img, x0 + w - 1, hy + 3, 1, 3, c["hair_d"])
		PA.px(img, x0 + 3, hy + 3, c["hair"])
		PA.px(img, x0 + w - 5, hy + 3, c["hair"])
		PA.rect(img, x0 + 3, hy, 3, 1, c["hair_l"])
		PA.rect(img, x0 + w - 3, hy, 2, 3, c["hair_d"])
		match style:
			"long":
				PA.rect(img, x0 - 1, hy + 2, 2, hh + 1, c["hair"])
				PA.rect(img, x0 + w - 1, hy + 2, 2, hh + 1, c["hair_d"])
			"boucles":
				for i in 5:
					PA.ellipse(img, x0 + 1.5 + i * (w - 3) / 4.0, hy - 0.5, 2.0, 2.0, c["hair"])
					PA.px(img, x0 + 1 + i * (w - 3) / 4, hy - 1, c["hair_l"])
				PA.ellipse(img, x0 + 0.0, hy + 4.0, 1.6, 2.4, c["hair"])
				PA.ellipse(img, x0 + w + 0.0, hy + 4.0, 1.6, 2.4, c["hair_d"])
			"chignon":
				PA.ellipse(img, x0 + w * 0.5, hy - 2.5, 3.0, 2.5, c["hair"])
				PA.px(img, x0 + w / 2 - 1, hy - 4, c["hair_l"])
				PA.rect(img, x0 + w / 2 - 2, hy - 1, 4, 1, c["hair_d"])
		return
	# profil gauche : la frange devant, la masse derrière
	PA.rect(img, x0 + 1, hy - 1, w - 2, 3, c["hair"])
	PA.rect(img, x0, hy + 1, 3, 2, c["hair"])
	PA.rect(img, x0 + w - 5, hy + 1, 5, 3, c["hair"])
	PA.rect(img, x0 + w - 3, hy + 4, 3, hh - 7, c["hair"])
	PA.rect(img, x0 + w - 1, hy + 2, 1, hh - 5, c["hair_d"])
	PA.rect(img, x0 + 3, hy, 3, 1, c["hair_l"])
	match style:
		"long":
			PA.rect(img, x0 + w - 4, hy + 4, 5, hh, c["hair"])
			PA.rect(img, x0 + w, hy + 4, 1, hh, c["hair_d"])
		"boucles":
			for i in 4:
				PA.ellipse(img, x0 + 2.0 + i * (w - 3) / 3.0, hy - 0.5, 2.0, 2.0, c["hair"])
			PA.ellipse(img, x0 + w - 0.5, hy + 4.5, 2.0, 2.8, c["hair"])
			PA.px(img, x0 + 2, hy - 1, c["hair_l"])
		"chignon":
			PA.ellipse(img, x0 + w + 0.5, hy + 1.0, 2.6, 2.6, c["hair"])
			PA.px(img, x0 + w, hy, c["hair_l"])
			PA.px(img, x0 + w - 1, hy + 2, c["hair_d"])


static func _beard(img: Image, x0: int, w: int, ey: int, hy: int, hh: int, style: String, c: Dictionary, view: int) -> void:
	var cx := x0 + w / 2
	var jaw := ey + 3
	var bottom := hy + hh
	if view == 0:
		match style:
			"moustache":
				PA.rect(img, cx - 3, jaw, 6, 1, c["beard"])
				PA.px(img, cx - 4, jaw + 1, c["beard"])
				PA.px(img, cx + 3, jaw + 1, c["beard_d"])
			"courte":
				PA.rect(img, x0 + 1, jaw, w - 2, bottom - jaw, c["beard"])
				PA.rect(img, x0, jaw - 2, 1, 3, c["beard"])
				PA.rect(img, x0 + w - 1, jaw - 2, 1, 3, c["beard_d"])
				PA.rect(img, x0 + 2, bottom - 1, w - 4, 1, c["beard_d"])
				PA.rect(img, cx - 2, jaw, 4, 1, c["beard_l"])
			"longue":
				PA.rect(img, x0, jaw - 2, 1, 3, c["beard"])
				PA.rect(img, x0 + w - 1, jaw - 2, 1, 3, c["beard_d"])
				for i in 11:
					var bw := maxi(2, w - 2 - i)
					PA.rect(img, cx - bw / 2, jaw + i, bw, 1, c["beard"])
					PA.px(img, cx - bw / 2 + bw - 1, jaw + i, c["beard_d"])
					if i % 3 == 1 and bw > 4:
						PA.px(img, cx - 1, jaw + i, c["beard_d"])
				PA.rect(img, cx - 3, jaw, 3, 1, c["beard_l"])
				PA.rect(img, cx - 2, jaw + 3, 1, 4, c["beard_l"])
		return
	if view == 1:
		match style:
			"moustache":
				PA.rect(img, x0 - 1, jaw, 4, 1, c["beard"])
				PA.px(img, x0 - 1, jaw + 1, c["beard"])
			"courte":
				PA.rect(img, x0, jaw, w - 5, bottom - jaw, c["beard"])
				PA.rect(img, x0 + w - 6, jaw - 2, 2, 3, c["beard"])
				PA.rect(img, x0 + 1, bottom - 1, w - 6, 1, c["beard_d"])
			"longue":
				PA.rect(img, x0 + w - 6, jaw - 2, 2, 3, c["beard"])
				for i in 11:
					var bw := maxi(2, w - 5 - i / 2)
					PA.rect(img, x0 - 1 + i / 4, jaw + i, bw, 1, c["beard"])
					PA.px(img, x0 - 1 + i / 4 + bw - 1, jaw + i, c["beard_d"])
				PA.rect(img, x0, jaw, 2, 1, c["beard_l"])
				PA.rect(img, x0, jaw + 3, 1, 4, c["beard_l"])


static func _hat(img: Image, x0: int, w: int, hy: int, hh: int, kind: String, c: Dictionary, view: int) -> void:
	var cx := x0 + w / 2
	match kind:
		"magicien":
			# grand cône dont la pointe retombe, large bord
			for i in 11:
				var cw := maxi(2, w - 2 - i)
				var shift := 0
				if i > 6:
					shift = (i - 6) / 2 + 1
				if view == 1:
					shift = shift * 2
				var lx := cx - cw / 2 + shift
				PA.rect(img, lx, hy - 1 - i, cw, 1, c["hat"])
				PA.px(img, lx, hy - 1 - i, c["hat_l"])
				PA.px(img, lx + cw - 1, hy - 1 - i, c["hat_d"])
			PA.rect(img, x0 + 1, hy - 2, w - 2, 2, c["band"])
			if view != 2:
				PA.rect(img, cx - 1, hy - 2, 2, 2, GOLD)
			PA.rect(img, x0 - 3, hy, w + 6, 2, c["hat"])
			PA.rect(img, x0 - 3, hy + 1, w + 6, 1, c["hat_d"])
			PA.rect(img, x0 - 2, hy, 3, 1, c["hat_l"])
		"toque":
			PA.ellipse(img, cx + 0.0, hy - 5.0, w * 0.5 + 1.0, 4.0, c["apron"])
			PA.ellipse(img, cx - 2.0, hy - 6.0, 2.0, 1.5, WHITE)
			PA.rect(img, x0 + 1, hy - 3, w - 2, 4, c["apron"])
			PA.rect(img, x0 + 1, hy, w - 2, 1, c["apron_d"])
			for i in 3:
				PA.rect(img, x0 + 3 + i * 3, hy - 3, 1, 3, c["apron_d"])
			PA.rect(img, x0 + w - 2, hy - 6, 1, 4, c["apron_d"])
		"casquette":
			PA.rect(img, x0 + 1, hy - 2, w - 2, 1, c["hat"])
			PA.rect(img, x0, hy - 1, w, 3, c["hat"])
			PA.rect(img, x0 + 2, hy - 2, 3, 1, c["hat_l"])
			PA.rect(img, x0 + w - 2, hy - 1, 2, 3, c["hat_d"])
			PA.px(img, cx, hy - 3, c["hat_d"])
			if view == 0:
				PA.rect(img, x0 + 1, hy + 2, w - 2, 1, c["hat_d"])
			elif view == 1:
				PA.rect(img, x0 - 3, hy + 1, 5, 1, c["hat_d"])
				PA.rect(img, x0 - 2, hy + 2, 3, 1, c["hat_d"])
		"capuche":
			if view == 2:
				PA.rect(img, x0, hy - 2, w, hh + 3, c["hat"])
				PA.rect(img, x0 - 1, hy, w + 2, hh, c["hat"])
				PA.rect(img, x0 + w - 1, hy, 2, hh, c["hat_d"])
				PA.rect(img, cx, hy - 1, 1, hh + 1, c["hat_d"])
				PA.rect(img, x0 + 2, hy - 1, 3, 1, c["hat_l"])
				PA.px(img, cx, hy - 3, c["hat"])
			elif view == 0:
				PA.rect(img, x0, hy - 2, w, 4, c["hat"])
				PA.rect(img, x0 - 1, hy, 2, hh + 1, c["hat"])
				PA.rect(img, x0 + w - 1, hy, 2, hh + 1, c["hat_d"])
				PA.rect(img, x0 + 1, hy + 2, w - 2, 1, c["hat_d"])
				PA.rect(img, x0 + 2, hy - 1, 3, 1, c["hat_l"])
				PA.px(img, cx, hy - 3, c["hat"])
				PA.rect(img, x0, hy + hh, w, 1, c["hat"])
			else:
				PA.rect(img, x0 + 1, hy - 2, w, 4, c["hat"])
				PA.rect(img, x0 + w - 5, hy + 2, 7, hh - 1, c["hat"])
				PA.rect(img, x0 + w, hy + 1, 2, hh - 1, c["hat_d"])
				PA.rect(img, x0 + 2, hy + 2, w - 7, 1, c["hat_d"])
				PA.px(img, x0 + w + 2, hy, c["hat"])
				PA.rect(img, x0 + 3, hy - 1, 3, 1, c["hat_l"])
				PA.rect(img, x0 + 1, hy + hh, w - 1, 1, c["hat"])
		"chapeau_paille":
			PA.rect(img, x0 + 2, hy - 4, w - 4, 1, c["hat"])
			PA.rect(img, x0 + 1, hy - 3, w - 2, 4, c["hat"])
			PA.rect(img, x0 + 1, hy, w - 2, 1, c["band"])
			PA.rect(img, x0 - 3, hy + 1, w + 6, 2, c["hat"])
			PA.rect(img, x0 - 3, hy + 2, w + 6, 1, c["hat_d"])
			for i in (w + 4) / 2:
				PA.px(img, x0 - 2 + i * 2, hy + 1, c["hat_l"])
			PA.rect(img, x0 + 3, hy - 3, 2, 2, c["hat_l"])
			PA.rect(img, x0 + w - 3, hy - 3, 2, 3, c["hat_d"])
		"couronne":
			PA.rect(img, x0 + 1, hy - 1, w - 2, 3, GOLD)
			PA.rect(img, x0 + 1, hy + 1, w - 2, 1, GOLD_D)
			for i in 4:
				var px_x := x0 + 1 + i * (w - 3) / 3
				PA.rect(img, px_x, hy - 3, 1, 2, GOLD)
				PA.px(img, px_x, hy - 4, WHITE)
			PA.px(img, cx - 2, hy, RED)
			PA.px(img, cx + 1, hy, Color("#4a8ad8"))
		"heaume":
			PA.rect(img, x0 + 2, hy - 3, w - 4, 1, c["hat"])
			PA.rect(img, x0 + 1, hy - 2, w - 2, 1, c["hat"])
			PA.rect(img, x0, hy - 1, w, 4, c["hat"])
			PA.rect(img, x0 + 2, hy - 2, 3, 1, c["hat_l"])
			PA.rect(img, x0 + w - 2, hy - 1, 2, 4, c["hat_d"])
			PA.rect(img, x0, hy + 2, w, 1, c["hat_d"])
			PA.rect(img, cx - 1, hy - 6, 2, 3, c["band"])
			PA.px(img, cx, hy - 7, c["band"])
			if view == 0:
				PA.rect(img, x0, hy + 3, 2, hh - 5, c["hat"])
				PA.rect(img, x0 + w - 2, hy + 3, 2, hh - 5, c["hat_d"])
				PA.rect(img, cx - 1, hy + 3, 1, 4, c["hat_d"])
			elif view == 1:
				PA.rect(img, x0 + w - 5, hy + 3, 5, hh - 4, c["hat"])
				PA.rect(img, x0 + w - 1, hy + 3, 1, hh - 4, c["hat_d"])
				PA.rect(img, x0, hy + 3, 1, 4, c["hat_d"])
			else:
				PA.rect(img, x0, hy + 3, w, hh - 4, c["hat"])
				PA.rect(img, x0 + w - 2, hy + 3, 2, hh - 4, c["hat_d"])
				PA.rect(img, x0, hy + hh - 2, w, 1, c["hat_d"])
		"foulard":
			PA.rect(img, x0 + 1, hy - 2, w - 2, 1, c["hat"])
			PA.rect(img, x0, hy - 1, w, 4, c["hat"])
			PA.rect(img, x0 + w - 2, hy - 1, 2, 4, c["hat_d"])
			for i in 3:
				PA.px(img, x0 + 2 + i * 4, hy, c["hat_l"])
				PA.px(img, x0 + 4 + i * 4, hy + 2, c["hat_l"])
			if view == 0:
				PA.rect(img, cx - 1, hy + hh - 1, 2, 2, c["hat"])
			elif view == 1:
				PA.rect(img, x0 + w - 2, hy + 3, 3, 5, c["hat"])
				PA.px(img, x0 + w, hy + 8, c["hat_d"])
			else:
				PA.rect(img, x0, hy + 3, w, hh - 6, c["hat"])
				PA.rect(img, cx - 2, hy + hh - 3, 4, 4, c["hat"])
				PA.rect(img, cx + 1, hy + hh - 3, 1, 4, c["hat_d"])


# ------------------------------------------------------------------ Morfales
# Brutes voûtées : petite tête enfoncée, mâchoire qui avance, défenses, ventre, bras
# qui pendent jusqu'aux genoux. « outfit » tablier = le goinfre (plus gros, toque).

static func _morfale(img: Image, ox: int, oy: int, look: Dictionary, c: Dictionary, p: Dictionary, view: int) -> void:
	var cx := ox + FRAME_W / 2
	var foot_y := oy + FRAME_H - 1 - FOOT_MARGIN
	var fat := str(look.get("outfit", "")) == "tablier"
	var bob := int(p["bob"])
	var lean := int(p["lean"])
	var arms := str(p["arms"])
	var half := 8 if fat else 7
	var hip_y := foot_y - 6
	var top_y := hip_y - 15 + bob        # épaules
	var dx := 0 if view != 1 else -lean / 2
	var skin: Color = c["skin"]
	var skin_d: Color = c["skin_d"]
	var skin_dd: Color = c["skin_dd"]
	var cloth: Color = c["top"]
	var cloth_d: Color = c["top_d"]
	var tusk := Color("#f0e6c8")
	var maw := Color("#3a1420")
	var yellow := Color("#f2d24a")
	var pupil := Color("#1b1425")

	# jambes courtes et arquées
	var stride := int(p["stride"])
	for s: int in [-1, 1]:
		var lift := int(p["lift_l"]) if s < 0 else int(p["lift_r"])
		var lx := cx + (-6 if s < 0 else 2)
		var fw := 5
		var fx := lx - (1 if s < 0 else 0)
		if view == 1:
			lx = cx - 2 + (-stride if s < 0 else stride) + (0 if s < 0 else 1)
			lift = 2 if (int(p["pass"]) == s) else 0
			fw = 6
			fx = lx - 2
		var fy := foot_y - maxi(0, lift)
		var leg_col: Color = c["bottom"] if s < 0 else c["bottom_d"]
		PA.rect(img, lx, hip_y, 4, fy - hip_y, leg_col)
		PA.rect(img, fx, fy - 2, fw, 3, c["feet"])
		PA.rect(img, fx, fy, fw, 1, c["feet_d"])

	# torse en poire, voûté
	var body_w := half * 2 if view != 1 else half * 2 - 3
	for i in 16:
		var k := float(i) / 15.0
		var wv := int(round(lerpf(float(body_w) - 3.0, float(body_w) + (3.0 if fat else 1.0), sin(k * PI * 0.75))))
		var bx := cx - wv / 2 + dx
		PA.rect(img, bx, top_y + i, wv, 1, cloth)
		PA.rect(img, bx + wv - 2, top_y + i, 2, 1, cloth_d)
		PA.px(img, bx, top_y + i, c["top_l"])
	PA.rect(img, cx - body_w / 2 + dx, hip_y - 3, body_w, 2, c["belt"])
	if view != 2:
		PA.rect(img, cx - 1 + dx - (3 if view == 1 else 0), hip_y - 3, 2, 2, GOLD)
	if fat and view == 0:
		PA.rect(img, cx - 4, top_y + 4, 8, 12, c["apron_d"])
		PA.rect(img, cx - 4, top_y + 4, 6, 11, c["apron"])
		PA.px(img, cx - 2, top_y + 8, Color("#a8846a"))
		PA.px(img, cx + 1, top_y + 11, Color("#8a6a3a"))
	elif view == 0:
		# plastron de cuir clouté
		PA.rect(img, cx - 4, top_y + 3, 8, 6, c["belt"])
		PA.px(img, cx - 3, top_y + 4, GOLD)
		PA.px(img, cx + 2, top_y + 4, GOLD)
		PA.px(img, cx - 3, top_y + 7, GOLD)
		PA.px(img, cx + 2, top_y + 7, GOLD)

	# tête basse, entre les épaules
	var hw := 12
	var hh := 9
	var hx := cx - hw / 2 + (0 if view != 1 else -lean - 3)
	var hy := top_y - 5
	var shut := str(p["eyes"]) == "closed" or str(p["eyes"]) == "pain"
	PA.rect(img, hx + 1, hy, hw - 2, hh, skin)
	PA.rect(img, hx, hy + 2, hw, hh - 3, skin)
	PA.rect(img, hx + hw - 2, hy + 2, 2, hh - 3, skin_d)
	PA.rect(img, hx + 2, hy + 1, 3, 1, c["skin_l"])
	# oreilles en pointe
	if view != 1:
		PA.rect(img, hx - 2, hy + 2, 2, 2, skin)
		PA.px(img, hx - 3, hy + 1, skin_d)
		PA.rect(img, hx + hw, hy + 2, 2, 2, skin_d)
		PA.px(img, hx + hw + 2, hy + 1, skin_d)
	else:
		PA.rect(img, hx + hw - 4, hy + 2, 3, 2, skin_d)
		PA.px(img, hx + hw - 1, hy + 1, skin_d)
	if view == 0:
		# arcade lourde, petits yeux jaunes, mâchoire carrée et défenses
		PA.rect(img, hx + 1, hy + 2, hw - 2, 1, skin_dd)
		for ex: int in [hx + 2, hx + hw - 4]:
			if shut:
				PA.rect(img, ex, hy + 4, 2, 1, skin_dd)
			else:
				PA.rect(img, ex, hy + 3, 2, 2, yellow)
				PA.px(img, ex + (1 if ex < cx else 0), hy + 4, pupil)
		PA.rect(img, cx - 1, hy + 4, 2, 2, skin_d)
		PA.rect(img, hx, hy + 6, hw, 3, skin_d)
		PA.rect(img, hx + 1, hy + 9, hw - 2, 1, skin_dd)
		var open := str(p["mouth"]) != "smile"
		PA.rect(img, hx + 2, hy + 7, hw - 4, 2 if open else 1, maw)
		if open:
			PA.rect(img, hx + 4, hy + 7, hw - 8, 1, tusk)
		PA.rect(img, hx + 2, hy + 5, 1, 3, tusk)
		PA.rect(img, hx + hw - 3, hy + 5, 1, 3, tusk)
	elif view == 1:
		PA.rect(img, hx, hy + 2, hw - 4, 1, skin_dd)
		if shut:
			PA.rect(img, hx + 2, hy + 4, 2, 1, skin_dd)
		else:
			PA.rect(img, hx + 2, hy + 3, 2, 2, yellow)
			PA.px(img, hx + 2, hy + 4, pupil)
		PA.rect(img, hx - 2, hy + 4, 3, 2, skin)          # groin
		PA.px(img, hx - 2, hy + 4, skin_dd)
		PA.rect(img, hx - 1, hy + 6, hw - 4, 3, skin_d)   # mâchoire qui avance
		PA.rect(img, hx - 1, hy + 7, hw - 6, 1, maw)
		PA.rect(img, hx, hy + 5, 1, 3, tusk)
		if str(p["mouth"]) != "smile":
			PA.rect(img, hx - 1, hy + 8, hw - 6, 1, maw)
			PA.rect(img, hx + 2, hy + 7, 3, 1, tusk)
	else:
		PA.rect(img, hx + 2, hy + 3, hw - 4, 1, skin_d)
		PA.rect(img, hx + 3, hy + 6, hw - 6, 1, skin_d)
	# coiffe
	var hat := str(look.get("hat", "none"))
	if hat == "toque":
		PA.ellipse(img, hx + hw * 0.5, hy - 3.0, 5.0, 3.0, c["apron"])
		PA.rect(img, hx + 2, hy - 2, hw - 4, 3, c["apron"])
		PA.rect(img, hx + 2, hy, hw - 4, 1, c["apron_d"])
	elif hat == "capuche":
		PA.rect(img, hx + 1, hy - 2, hw - 2, 3, c["hat"])
		PA.rect(img, hx, hy - 1, hw, 2, c["hat"])
		PA.rect(img, hx + hw - 3, hy - 1, 3, 2, c["hat_d"])
		PA.px(img, hx + hw / 2, hy - 3, c["hat"])
		if view == 2:
			PA.rect(img, hx, hy - 1, hw, hh, c["hat"])
			PA.rect(img, hx + hw / 2, hy, 1, hh - 2, c["hat_d"])
	elif view == 2:
		PA.rect(img, hx + 3, hy, 2, 2, c["skin_l"])

	# bras énormes qui pendent
	for s: int in [-1, 1]:
		var ax := cx + (-half - 3 if s < 0 else half) + dx
		var ay := top_y + 2
		var swing := int(p["arm"]) * s
		var col: Color = skin if s < 0 else skin_d
		if view == 1:
			if s > 0:
				continue
			ax = cx - 1 + dx - swing * 2
			col = skin_d
		match arms:
			"up":
				PA.rect(img, ax, ay - 8, 3, 10, col)
				PA.rect(img, ax - 1, ay - 11, 5, 4, col)
			"strike":
				if view == 1:
					PA.rect(img, ax - 9, ay + 1, 10, 3, col)
					PA.rect(img, ax - 12, ay, 4, 5, col)
				elif s > 0:
					PA.rect(img, ax, ay - 8, 3, 10, col)
					PA.rect(img, ax - 1, ay - 11, 5, 4, col)
				else:
					PA.rect(img, ax, ay, 3, 12, col)
					PA.rect(img, ax - 1, ay + 11, 5, 4, col)
			"flail":
				if view == 1:
					PA.rect(img, ax + 1, ay - 4, 8, 3, col)
					PA.rect(img, ax + 8, ay - 6, 4, 5, col)
				else:
					PA.rect(img, ax + (-3 if s < 0 else 1), ay - 1, 5, 3, col)
					PA.rect(img, ax + (-3 if s < 0 else 2), ay - 3, 4, 4, col)
			_:
				var length := 12 + swing
				PA.rect(img, ax, ay, 3, length, col)
				PA.rect(img, ax + 2, ay + 1, 1, length - 1, skin_dd)
				if view == 1:
					PA.rect(img, ax - 1, ay + 1, 1, length - 2, skin_dd)   # détache le bras du torse
				PA.rect(img, ax - 1, ay + length - 1, 5, 4, col)      # gros poing
				PA.rect(img, ax - 1, ay + length + 2, 5, 1, skin_dd)
		PA.rect(img, ax - 1, ay - 2, 5, 3, cloth_d)                    # épaulière


# -------------------------------------------------------------------- le Naze
# Spectre sans jambes : grande cape en lambeaux qui flotte, capuche vide où brillent
# deux yeux, couronne de fer, longues mains pâles, lame pâle.

static func _naze(img: Image, ox: int, oy: int, c: Dictionary, p: Dictionary, view: int) -> void:
	var cx := ox + FRAME_W / 2
	var foot_y := oy + FRAME_H - 1 - FOOT_MARGIN
	var bob := int(p["bob"])
	var lean := int(p["lean"]) if view == 1 else 0
	var arms := str(p["arms"])
	var robe: Color = c["top"]
	var robe_d: Color = PA.shade(robe, -0.35)
	var robe_l: Color = PA.shade(robe, 0.45)
	var glow := Color("#b8f0ff")
	var iron := Color("#8a8aa0")
	var void_c := Color("#07060c")
	var clear := Color(0, 0, 0, 0)
	var top_y := foot_y - 34 + bob
	var sway := int(p["stride"]) / 2 + int(p["pass"])
	# cape : s'évase vers le bas
	for i in 31 - bob:
		var k := float(i) / 30.0
		var half := int(round(5.0 + k * 6.0))
		var dx := -lean * maxi(0, 30 - i) / 30 + int(round(sin(k * 3.0 + float(sway)) * k * 1.5))
		var y := top_y + 4 + i
		PA.rect(img, cx - half + dx, y, half * 2, 1, robe)
		PA.rect(img, cx + half - 3 + dx, y, 3, 1, robe_d)
		PA.px(img, cx - half + dx, y, robe_l)
		if i > 6 and i % 2 == 0:
			PA.px(img, cx - half / 2 + dx, y, robe_d)
			PA.px(img, cx + half / 3 + dx, y, robe_d)
	# lambeaux : on creuse le bas de la cape
	for t in 6:
		var tx := cx - 11 + t * 4 + (sway if t % 2 == 0 else 0)
		var depth := 3 + (t * 5 + bob * 2) % 4
		for yy in depth + 1:
			for xx in 2:
				img.set_pixel(clampi(tx + xx, ox, ox + FRAME_W - 1), foot_y - yy, clear)
	# ceinture de fer
	PA.rect(img, cx - 7 - lean / 2, top_y + 18, 14, 1, iron)
	if view != 2:
		PA.px(img, cx - 1 - lean / 2, top_y + 18, glow)
	# capuche
	var hx := cx - 6 - lean + (-2 if view == 1 else 0)
	var hy := top_y - 2
	PA.rect(img, hx + 1, hy, 10, 11, robe)
	PA.rect(img, hx, hy + 2, 12, 8, robe)
	PA.rect(img, hx + 10, hy + 2, 2, 8, robe_d)
	PA.rect(img, hx + 2, hy + 1, 3, 1, robe_l)
	if view == 0:
		PA.rect(img, hx + 2, hy + 3, 8, 6, void_c)
		if str(p["eyes"]) == "closed":
			PA.rect(img, hx + 3, hy + 6, 2, 1, glow)
			PA.rect(img, hx + 7, hy + 6, 2, 1, glow)
		else:
			PA.rect(img, hx + 3, hy + 5, 2, 2, glow)
			PA.rect(img, hx + 7, hy + 5, 2, 2, glow)
			PA.px(img, hx + 3, hy + 5, WHITE)
			PA.px(img, hx + 7, hy + 5, WHITE)
		if str(p["mouth"]) != "smile":
			PA.rect(img, hx + 4, hy + 8, 4, 1, glow)
	elif view == 1:
		PA.rect(img, hx, hy + 3, 6, 6, void_c)
		PA.rect(img, hx + 1, hy + 5, 2, 2 if str(p["eyes"]) != "closed" else 1, glow)
		if str(p["mouth"]) != "smile":
			PA.rect(img, hx, hy + 8, 3, 1, glow)
	else:
		PA.rect(img, hx + 5, hy + 2, 1, 8, robe_d)
	# couronne de fer, pointes inégales
	PA.rect(img, hx + 1, hy - 1, 10, 2, iron)
	PA.rect(img, hx + 1, hy, 10, 1, PA.shade(iron, -0.3))
	for i in 4:
		PA.rect(img, hx + 1 + i * 3, hy - 3 - (i % 2), 1, 2 + (i % 2), iron)
	PA.px(img, hx + 4, hy - 1, glow)
	# bras et lame
	var sx := cx - lean
	var hand := Color("#c8c8dc")
	if view == 1:
		var hx1 := sx - 8
		var hy1 := top_y + 12
		match arms:
			"up":
				hx1 = sx - 6
				hy1 = top_y + 4
			"strike":
				hx1 = sx - 6
				hy1 = top_y + 9
			"flail":
				hx1 = sx + 7
				hy1 = top_y + 4
		_line(img, sx, top_y + 7, hx1, hy1, robe_d)
		_line(img, sx + 1, top_y + 7, hx1 + 1, hy1, robe_d)
		_line(img, sx, top_y + 8, hx1, hy1 + 1, robe_d)
		PA.rect(img, hx1 - 1, hy1, 3, 2, hand)
		PA.px(img, hx1 - 2, hy1 + 1, hand)
		var bx := hx1 - 1
		if arms == "strike" or arms == "down":
			_line(img, bx, hy1, bx - 3, hy1 + 13, glow)
			_line(img, bx + 1, hy1, bx - 2, hy1 + 13, iron)
		else:
			var bl := 14 if arms == "down" else 10
			_line(img, bx, hy1 + 1, bx - 2, hy1 - bl, glow)
			_line(img, bx + 1, hy1 + 1, bx - 1, hy1 - bl, iron)
		PA.rect(img, bx - 2, hy1 + 1, 5, 1, iron)
	else:
		var raised := arms == "up" or arms == "strike"
		for s: int in [-1, 1]:
			var ax := cx + (-9 if s < 0 else 7)
			var ay := top_y + 7
			var col: Color = robe_l if s < 0 else robe_d
			if arms == "up" or arms == "flail" or (arms == "strike" and s > 0):
				PA.rect(img, ax, ay - 8, 3, 9, col)
				PA.rect(img, ax, ay - 10, 3, 2, hand)
				PA.px(img, ax + 1, ay - 11, hand)
			elif arms == "flail":
				PA.rect(img, ax + (-1 if s < 0 else -2), ay, 5, 3, col)
				PA.rect(img, ax + (-3 if s < 0 else 3), ay, 2, 3, hand)
			else:
				var length := 10 + int(p["arm"]) * s
				PA.rect(img, ax, ay, 3, length, col)
				PA.rect(img, ax, ay + length, 3, 2, hand)
				PA.px(img, ax + 1, ay + length + 2, hand)
		if view == 0:
			var bx := cx + 8
			if raised:
				PA.rect(img, bx, top_y - 8, 1, 10, glow)
				PA.rect(img, bx + 1, top_y - 8, 1, 10, iron)
			else:
				PA.rect(img, bx, top_y + 20, 1, 14, glow)
				PA.rect(img, bx + 1, top_y + 20, 1, 14, iron)
				PA.rect(img, bx - 1, top_y + 19, 4, 1, iron)
