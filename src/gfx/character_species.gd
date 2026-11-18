extends "res://src/gfx/character_head.gd"
## Corps non humains de la planche : Morfales (brutes voûtées à défenses) et Nazes
## (spectres en manteau lacéré). Même résolution et même méthode que les humains.


# ------------------------------------------------------------------- Morfales

static func _morfale(look: Dictionary, view: int) -> void:
	var cx := 44.0
	var fat := str(look.get("outfit", "")) == "tablier"
	var bob := float(_p["bob"])
	var lean := float(_p["lean"])
	var arms := str(_p["arms"])
	var crouch := float(_p.get("crouch", 0.0))
	var foot := float(FRAME_H - 1 - FOOT_MARGIN)
	var hip := foot - 19.0 + crouch * 2.0
	var sh := hip - 38.0 + bob
	var half := 19.0 if fat else 16.5
	var skin: Array = _c["skin"]
	var top: Array = _c["top"]
	var belt: Array = _c["belt"]
	var bottom: Array = _c["bottom"]
	var boot: Array = _c["boot"]
	var gold: Array = _c["gold"]
	var tusk := _ramp(Color("#f0e6c8"))
	var maw := Color("#3a1420")
	var yellow := Color("#f2d24a")
	var side := view == 1
	var dx := -lean * 0.4 if side else 0.0
	_cx = cx
	_hcy = sh - 6.0

	# jambes courtes et arquées
	for s: int in [-1, 1]:
		var lift := float(_p["lf"]) if s < 0 else float(_p["ln"])
		var lx := cx + float(s) * 9.5
		var fx := lx
		if side:
			var near := s > 0
			lx = cx
			fx = cx - float(_p["fn"]) if near else cx - float(_p["ff"])
			lift = float(_p["ln"]) if near else float(_p["lf"])
		var ay := foot - 5.0 - lift
		var br: Array = boot if (not side or s > 0) else _dim(boot)
		var pr: Array = bottom if (not side or s > 0) else _dim(bottom)
		var spread := 0.0 if side else float(s) * 3.0
		_cap(lx, hip - 3.0, fx + spread, ay - 8.0, 7.2, 6.2, pr)
		_cap(fx + spread, ay - 9.0, fx + spread, ay, 7.2, 6.6, br)
		_rect(fx + spread - 7.0, ay - 9.0, 14.0, 1.5, br[3])
		_ell(fx + (-3.5 if side else float(s) * 3.5), ay + 1.6, 9.5 if not side else 11.0, 4.6, br)
		_rect(fx + (-3.5 if side else float(s) * 3.5) - 8.0, ay + 4.4, 16.0, 1.0, br[0])

	# bras éloigné (profil)
	if side:
		_morfale_arm(cx + 3.0 + dx, sh + 6.0, arms, 1, _dim(top), skin, true)

	# torse en poire, voûté
	var bw := half * (1.0 if not side else 0.78)
	_ell(cx + dx, sh + 17.0, bw + (4.0 if fat else 1.0), 20.0, top, 0.0)
	_trap(sh + 4.0, hip, cx + dx - bw, cx + dx + bw, cx + dx - bw - 3.0, cx + dx + bw + 3.0, top, 0.0,
		[Vector2(0.28, 0.2), Vector2(0.5, 0.0), Vector2(0.72, 0.1)])
	_trap(hip - 7.0, hip - 1.5, cx + dx - bw - 3.0, cx + dx + bw + 3.0, cx + dx - bw - 3.0, cx + dx + bw + 3.0, belt)
	_rect(cx + dx - bw - 3.0, hip - 7.0, (bw + 3.0) * 2.0, 1.0, belt[4])
	if view != 2:
		var bx := cx + dx - 3.5 - (7.0 if side else 0.0)
		_rect(bx, hip - 7.0, 7.0, 5.5, gold[2])
		_rect(bx, hip - 7.0, 7.0, 1.0, gold[4])
		_rect(bx + 2.0, hip - 5.0, 3.0, 2.0, gold[0])
	if view == 0:
		if fat:
			var ap: Array = _c["apron"]
			_trap(sh + 10.0, hip + 7.0, cx - 11.0, cx + 11.0, cx - 14.0, cx + 14.0, ap, 0.0, [Vector2(0.5, 0.4)], true)
			_put(int(cx) - 4, int(sh) + 22, Color("#a8846a"))
			_put(int(cx) + 4, int(sh) + 28, Color("#8a6a3a"))
			_put(int(cx) - 2, int(sh) + 30, Color("#a8846a"))
			_rect(cx - 6.0, sh + 17.0, 9.0, 7.0, ap[1])
		else:
			# plastron de cuir clouté
			_trap(sh + 6.0, sh + 22.0, cx - 11.0, cx + 11.0, cx - 9.0, cx + 9.0, belt, 0.0, [], true)
			for i in 3:
				_put(int(cx) - 7 + i * 6, int(sh) + 10, gold[4])
				_put(int(cx) - 5 + i * 6, int(sh) + 17, gold[3])
	# épaules massives
	_ell(cx + dx - bw + 1.0, sh + 6.0, 8.6, 7.4, top)
	_ell(cx + dx + bw - 1.0, sh + 6.0, 8.6, 7.4, top)

	# tête basse, entre les épaules
	var hx := cx + (dx - lean * 0.3 - 5.0 if side else 0.0)
	var hcy := sh - 6.0
	var hrx := 16.0 if not side else 14.5
	var hry := 14.0
	var shut := str(_p["eyes"]) == "closed" or str(_p["eyes"]) == "pain" or str(_p["eyes"]) == "ko"
	var hat := str(look.get("hat", "none"))
	if hat == "capuche":
		_hood_back(hx, hcy, hrx, hry, 1 if side else 0)
	# oreilles en pointe
	if not side:
		for s: int in [-1, 1]:
			_cap(hx + float(s) * (hrx - 2.0), hcy, hx + float(s) * (hrx + 8.0), hcy - 7.0, 3.8, 1.0, skin)
	else:
		_cap(hx + hrx - 5.0, hcy, hx + hrx + 5.0, hcy - 8.0, 3.8, 1.0, skin)
	_ell(hx, hcy, hrx, hry, skin)
	if view == 0:
		# arcade lourde, petits yeux jaunes, mâchoire carrée et défenses
		_rect(hx - hrx + 3.0, hcy - 4.0, (hrx - 3.0) * 2.0, 2.0, skin[0])
		for s: int in [-1, 1]:
			var ex := int(hx) + (-9 if s < 0 else 4)
			if shut:
				_rect(ex, hcy - 1.0, 5.0, 1.5, skin[0])
			else:
				_rect(ex, hcy - 2.0, 5.0, 4.0, yellow)
				_rect(ex + 2.0, hcy - 1.0, 2.0, 3.0, Color("#1b1425"))
				_put(ex, int(hcy) - 2, WHITE)
				_rect(ex, hcy - 3.0, 5.0, 1.0, skin[0])
		_rect(hx - 2.0, hcy + 3.0, 1.0, 2.0, skin[0])
		_rect(hx + 1.0, hcy + 3.0, 1.0, 2.0, skin[0])
		_rect(hx - 9.0, hcy + 7.0, 18.0, 5.0, maw)
		_rect(hx - 9.0, hcy + 7.0, 18.0, 1.0, skin[1])
		for s: int in [-1, 1]:
			var tx := hx + float(s) * 7.0
			_trap(hcy + 3.0, hcy + 12.0, tx - 1.8, tx + 1.8, tx - 1.0, tx + 1.0, tusk)
		if str(_p["mouth"]) == "open":
			_rect(hx - 5.0, hcy + 9.0, 10.0, 3.0, maw)
			_rect(hx - 3.0, hcy + 11.0, 6.0, 1.0, RED)
	elif view == 1:
		_rect(hx - hrx + 3.0, hcy - 4.0, 12.0, 2.0, skin[0])
		var ex := int(hx - hrx * 0.5) - 2
		if shut:
			_rect(ex, hcy - 1.0, 5.0, 1.5, skin[0])
		else:
			_rect(ex, hcy - 2.0, 5.0, 4.0, yellow)
			_rect(ex, hcy - 1.0, 2.0, 3.0, Color("#1b1425"))
		_ell(hx - hrx - 0.5, hcy + 5.0, 3.6, 3.2, skin)
		_rect(hx - hrx + 2.0, hcy + 7.0, 14.0, 5.0, maw)
		_trap(hcy + 3.0, hcy + 12.0, hx - hrx + 3.0, hx - hrx + 6.5, hx - hrx + 3.5, hx - hrx + 6.0, tusk)
	if hat != "none" and hat != "capuche":
		_hat(look, hx, hcy, hrx, hry, hat, 0 if view != 1 else 1)
	elif hat == "capuche":
		_hood_front(hx, hcy, hrx, hry, view)
	# bras proches (peints après la tête pour les poses levées)
	if side:
		_morfale_arm(cx - 1.0 + dx, sh + 6.0, arms, 1, top, skin, false)
	else:
		for s: int in [-1, 1]:
			_morfale_arm(cx + dx + float(s) * (bw + 1.0), sh + 6.0, arms, s, top, skin, false)


static func _morfale_arm(sx: float, sy: float, arms: String, s: int, sleeve: Array, skin: Array, far: bool) -> void:
	var swing := float(_p["an"]) * float(s) if s > 0 else float(_p["af"])
	var hx := sx + float(s) * 5.0
	var hy := sy + 31.0 - swing * 1.0
	var ex := sx + float(s) * 6.5
	var ey := sy + 14.0
	match arms:
		"strike":
			if s > 0:
				hx = sx + float(s) * 8.0
				hy = sy - 14.0
				ex = sx + float(s) * 11.0
				ey = sy + 2.0
		"up":
			hx = sx + float(s) * 11.0
			hy = sy - 18.0
			ex = sx + float(s) * 14.0
			ey = sy - 2.0
		"flail":
			hx = sx + float(s) * 15.0
			hy = sy - 6.0
			ex = sx + float(s) * 14.0
			ey = sy + 7.0
		"slump":
			hy = sy + 33.0
	hx = clampf(hx, 9.0, 79.0)
	var sl: Array = sleeve
	_cap(sx, sy, ex, ey, 7.6, 6.8, sl)
	_cap(ex, ey, hx, hy - 3.0, 6.8, 6.4, skin)
	_ell(hx, hy, 6.6, 6.2, skin)
	# jointures
	_put(int(round(hx)) - 2, int(round(hy)) + 3, skin[0])
	_put(int(round(hx)) + 1, int(round(hy)) + 3, skin[0])
	_put(int(round(hx)) - 3, int(round(hy)) - 2, skin[4])


# ------------------------------------------------------------------------ Naze

static func _naze(view: int) -> void:
	var cx := 44.0
	var bob := float(_p["bob"])
	var lean := float(_p["lean"]) if view == 1 else 0.0
	var arms := str(_p["arms"])
	var robe: Array = _c["top"]
	var iron: Array = _c["iron"]
	var glow := Color("#b8f0ff")
	var void_c := Color("#07060c")
	var foot := float(FRAME_H - 1 - FOOT_MARGIN)
	var top_y := foot - 94.0 + bob
	var sway := float(_p["sway"]) + float(_p["fn"]) * 0.2
	_cx = cx
	_hcy = top_y + 10.0
	# manteau : s'évase vers le bas, plis profonds
	var rows := int(88.0 - bob)
	for i in rows:
		var k := float(i) / 87.0
		var half := 14.0 + k * 17.0
		var dxs := -lean * maxf(0.0, 76.0 - float(i)) / 76.0 + sin(k * 3.0 + sway) * k * 4.0
		var y := top_y + 15.0 + float(i)
		var xl := cx - half + dxs
		var xr := cx + half + dxs
		for x in range(int(round(xl)), int(round(xr))):
			var u := ((float(x) + 0.5 - xl) / (xr - xl)) * 2.0 - 1.0
			var tone := _tone(clampf(u, -0.99, 0.99), -0.1)
			var f := (x + i / 6) % 9
			if i > 12 and f == 0:
				tone = mini(tone, 1)
			elif i > 12 and f == 1 and tone <= 2:
				tone = 3
			_put(x, int(y), robe[tone])
	# lambeaux : encoches triangulaires dans le bas
	for t in 10:
		var tx := int(cx) - 29 + t * 6 + (int(sway) if t % 2 == 0 else 0)
		var depth := 5 + (t * 5 + int(bob) * 2) % 8
		for yy in depth:
			var w := int(round(3.0 * (1.0 - float(yy) / float(depth))))
			for xx in range(-w, w + 1):
				var px := tx + 1 + xx
				if px >= 1 and px < FRAME_W - 1:
					var yb := int(foot) + 1 - yy
					if _flip >= 0:
						_im.set_pixel(_flip - px, yb, Color(0, 0, 0, 0))
					else:
						_im.set_pixel(px, yb, Color(0, 0, 0, 0))
	# ceinture de fer
	_trap(top_y + 50.0, top_y + 54.0, cx - 15.0 - lean * 0.5, cx + 15.0 - lean * 0.5, cx - 16.0 - lean * 0.5, cx + 16.0 - lean * 0.5, iron)
	_rect(cx - 15.0 - lean * 0.5, top_y + 50.0, 30.0, 1.0, iron[4])
	if view != 2:
		_rect(cx - 2.0 - lean * 0.5, top_y + 50.0, 4.0, 4.0, glow)
		_put(int(cx - lean * 0.5) - 1, int(top_y) + 50, WHITE)
	# capuche
	var hx := cx - lean - (5.0 if view == 1 else 0.0)
	var hcy := top_y + 10.0
	_ell(hx, hcy, 16.0, 19.0, robe)
	_trap(hcy + 12.0, hcy + 24.0, hx - 16.0, hx + 16.0, hx - 20.0, hx + 20.0, robe, -0.05,
		[Vector2(0.3, 0.0), Vector2(0.7, 0.0)])
	if view == 0:
		_ell(hx, hcy + 2.0, 11.0, 13.0, [void_c, void_c, void_c, void_c, void_c])
		var shut := str(_p["eyes"]) == "closed" or str(_p["eyes"]) == "ko"
		for s: int in [-1, 1]:
			var ex := int(hx) + (-8 if s < 0 else 3)
			if shut:
				_rect(ex, hcy, 5.0, 1.5, glow)
			else:
				_rect(ex, hcy - 2.0, 5.0, 5.0, glow)
				_put(ex, int(hcy) - 2, WHITE)
				_put(ex + 1, int(hcy) - 2, WHITE)
		if str(_p["mouth"]) != "smile":
			_rect(hx - 4.0, hcy + 8.0, 8.0, 1.5, glow)
	elif view == 1:
		_ell(hx - 5.0, hcy + 2.0, 8.5, 12.0, [void_c, void_c, void_c, void_c, void_c])
		var shut := str(_p["eyes"]) == "closed" or str(_p["eyes"]) == "ko"
		_rect(hx - 11.0, hcy - 1.0, 5.0, 1.5 if shut else 5.0, glow)
		_put(int(hx) - 11, int(hcy) - 1, WHITE)
		if str(_p["mouth"]) != "smile":
			_rect(hx - 11.0, hcy + 8.0, 5.0, 1.5, glow)
	else:
		_rect(hx - 0.5, hcy - 16.0, 1.0, 32.0, robe[1])
		_line(hx - 8.0, hcy - 10.0, hx - 6.0, hcy + 14.0, robe[1])
		_line(hx + 8.0, hcy - 10.0, hx + 6.0, hcy + 14.0, robe[1])
	# couronne de fer, pointes inégales
	_trap(hcy - 17.0, hcy - 11.0, hx - 14.0, hx + 14.0, hx - 15.5, hx + 15.5, iron)
	_rect(hx - 14.0, hcy - 17.0, 28.0, 1.0, iron[4])
	for i in 5:
		var px := hx - 11.0 + float(i) * 5.5
		var hgt := 9.0 + float(i % 2) * 4.0
		_trap(hcy - 17.0 - hgt, hcy - 16.0, px - 0.7, px + 0.7, px - 2.6, px + 2.6, iron)
		_put(int(px), int(hcy - 18.0 - hgt), iron[4])
	_put(int(hx) - 5, int(hcy) - 15, glow)
	# bras et lame
	var hand := _ramp(Color("#c8c8dc"))
	var sx := cx - lean
	if view == 1:
		var hx1 := sx - 15.0
		var hy1 := top_y + 50.0
		match arms:
			"up":
				hx1 = sx - 13.0
				hy1 = top_y + 24.0
			"strike":
				hx1 = sx - 15.0
				hy1 = top_y + 34.0
			"flail":
				hx1 = sx + 14.0
				hy1 = top_y + 24.0
		_cap(sx, top_y + 28.0, hx1 + 3.0, hy1 - 3.0, 6.4, 5.6, robe, -0.1)
		_ell(hx1, hy1, 4.8, 4.8, hand)
		_blade(hx1, hy1, arms, glow, iron)
	else:
		for s: int in [-1, 1]:
			var ax := cx + float(s) * 17.0
			var ay := top_y + 28.0
			var hx2 := ax + float(s) * 3.0
			var hy2 := ay + 24.0 + (float(_p["an"]) if s > 0 else float(_p["af"]))
			if arms == "up" or arms == "flail" or (arms == "strike" and s > 0):
				hx2 = ax + float(s) * 6.0
				hy2 = ay - 21.0
			if _p.has("crouch"):
				hy2 = ay + 26.0
			_cap(ax, ay, hx2, hy2 - 3.0, 6.6, 5.8, robe if s < 0 else _dim(robe))
			_ell(hx2, hy2, 4.6, 4.6, hand)
			if s > 0 and view == 0:
				_blade(hx2, hy2, arms, glow, iron)


static func _blade(hx: float, hy: float, arms: String, glow: Color, iron: Array) -> void:
	var down := arms == "down" or arms == "strike"
	if down:
		_cap(hx - 1.5, hy, hx - 5.0, hy + 40.0, 2.4, 1.0, iron)
		_cap(hx - 2.5, hy + 2.0, hx - 5.8, hy + 38.0, 0.9, 0.4, [glow, glow, glow, glow, WHITE])
		_rect(hx - 6.0, hy + 1.0, 9.0, 2.0, iron[3])
	else:
		_cap(hx, hy, hx - 3.5, hy - 32.0, 2.4, 1.0, iron)
		_cap(hx - 1.0, hy - 2.0, hx - 4.0, hy - 30.0, 0.9, 0.4, [glow, glow, glow, glow, WHITE])
		_rect(hx - 4.5, hy - 2.0, 9.0, 2.0, iron[3])
