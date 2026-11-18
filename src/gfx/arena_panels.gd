extends RefCounted
## Fonds peints des arènes par lieu : un grand panneau (24 pixels par unité) posé derrière
## la scène, avec ses ouvertures (les pixels transparents laissent voir le lointain).
## Chaque lieu a sa fonction : mur de la taverne, couloir de l'étage, cave à fromage, etc.
## Le panneau est cuit : la lumière du lieu (feu, lune, lanternes) est peinte dedans.
## Voir docs/FORMAT_DONNEES.md, champ `panels` de `backdrop`.

const PA = preload("res://src/gfx/pixel_art.gd")
const TP = preload("res://src/gfx/tile_painter.gd")
const PPU := 24.0

const KINDS: Array[String] = ["taverne", "etage", "ruelle", "cave", "ferme", "route", "col", "cite", "conseil", "archives", "quai"]

static var _cache: Dictionary = {}
static var _tiles: Dictionary = {}

const DIGITS := {
	"0": ["111", "101", "101", "101", "111"], "1": ["010", "110", "010", "010", "111"],
	"2": ["111", "001", "111", "100", "111"], "3": ["111", "001", "111", "001", "111"],
	"4": ["101", "101", "111", "001", "001"], "5": ["111", "100", "111", "001", "111"],
	"6": ["111", "100", "111", "101", "111"], "7": ["111", "001", "001", "001", "001"],
	"8": ["111", "101", "111", "101", "111"], "9": ["111", "101", "111", "001", "111"],
	".": ["000", "000", "000", "000", "010"], "(": ["010", "100", "100", "100", "010"],
	")": ["010", "001", "001", "001", "010"], "-": ["000", "000", "111", "000", "000"],
}


static func has_kind(kind: String) -> bool:
	return KINDS.has(kind)


## Peint (ou reprend en mémoire) le panneau d'un lieu : largeur et hauteur en unités monde.
static func panel(kind: String, w_units: float, h_units: float) -> Image:
	var key := "%s:%d:%d" % [kind, int(w_units * 10.0), int(h_units * 10.0)]
	if _cache.has(key):
		return _cache[key]
	var img := PA.new_image(int(w_units * PPU), int(h_units * PPU))
	match kind:
		"taverne": _taverne(img)
		"etage": _etage(img)
		"ruelle": _ruelle(img)
		"cave": _cave(img)
		"ferme": _ferme(img)
		"route": _route(img)
		"col": _col(img)
		"cite": _cite(img)
		"conseil": _conseil(img)
		"archives": _archives(img)
		"quai": _quai(img)
	_cache[key] = img
	return img


# ------------------------------------------------------------------- outils

static func _X(img: Image, x: float) -> int:
	return int(round((x + float(img.get_width()) * 0.5 / PPU) * PPU))


static func _Y(img: Image, y: float) -> int:
	return img.get_height() - int(round(y * PPU))


## Rectangle en coordonnées monde (x vers la droite, y vers le haut, 0 au sol).
static func _wr(img: Image, x0: float, y0: float, x1: float, y1: float, c: Color) -> void:
	var a := _X(img, x0)
	var t := _Y(img, y1)
	PA.rect(img, a, t, _X(img, x1) - a, _Y(img, y0) - t, c)


static func _tile(kind: String) -> Image:
	if not _tiles.has(kind):
		_tiles[kind] = TP.paint(kind)
	return _tiles[kind]


## Remplit un rectangle (pixels) avec une tuile répétée, multipliée par une teinte.
static func _fill_tile(img: Image, kind: String, x: int, y: int, w: int, h: int, mul: Color = Color.WHITE, off: Vector2i = Vector2i.ZERO) -> void:
	var t := _tile(kind)
	var tw := t.get_width()
	for yy in range(maxi(y, 0), mini(y + h, img.get_height())):
		for xx in range(maxi(x, 0), mini(x + w, img.get_width())):
			var c := t.get_pixel(posmod(xx - x + off.x, tw), posmod(yy - y + off.y, tw))
			if c.a < 0.5:
				continue
			img.set_pixel(xx, yy, Color(c.r * mul.r, c.g * mul.g, c.b * mul.b, 1.0))


static func _fill_tile_w(img: Image, kind: String, x0: float, y0: float, x1: float, y1: float, mul: Color = Color.WHITE) -> void:
	var a := _X(img, x0)
	var t := _Y(img, y1)
	_fill_tile(img, kind, a, t, _X(img, x1) - a, _Y(img, y0) - t, mul)


## Lumière additive (halo rond) sur ce qui est déjà peint.
static func _glow(img: Image, cx: float, cy: float, r: float, col: Color, k: float) -> void:
	var px := _X(img, cx)
	var py := _Y(img, cy)
	var rp := r * PPU
	for y in range(maxi(0, int(py - rp)), mini(img.get_height(), int(py + rp) + 1)):
		for x in range(maxi(0, int(px - rp)), mini(img.get_width(), int(px + rp) + 1)):
			var d := Vector2(float(x - px), float(y - py)).length() / rp
			if d >= 1.0:
				continue
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var a := (1.0 - d) * (1.0 - d) * k
			img.set_pixel(x, y, Color(minf(c.r + col.r * a, 1.0), minf(c.g + col.g * a, 1.0), minf(c.b + col.b * a, 1.0), c.a))


## Assombrit une bande horizontale (pixels y0 à y1) : plafond, pied de mur.
static func _band(img: Image, y0: int, y1: int, a0: float, a1: float, col: Color = Color(0.03, 0.02, 0.06)) -> void:
	for y in range(maxi(y0, 0), mini(y1, img.get_height())):
		var t := float(y - y0) / float(maxi(y1 - y0 - 1, 1))
		var a := lerpf(a0, a1, t)
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			img.set_pixel(x, y, c.lerp(Color(col.r, col.g, col.b, c.a), a))


## Voile de teinte sur tout le panneau (nuit bleue, humidité verte...).
static func _wash(img: Image, col: Color, a: float) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a < 0.5:
				continue
			img.set_pixel(x, y, c.lerp(Color(col.r, col.g, col.b, c.a), a))


static func _text(img: Image, x: int, y: int, s: String, col: Color) -> void:
	var cx := x
	for ch in s:
		if DIGITS.has(ch):
			var rows: Array = DIGITS[ch]
			for ry in 5:
				for rx in 3:
					if str(rows[ry])[rx] == "1":
						PA.px(img, cx + rx, y + ry, col)
		cx += 4


static func _post(img: Image, x: float, y0: float, y1: float, w: float, c: Color) -> void:
	_wr(img, x - w * 0.5, y0, x + w * 0.5, y1, c)
	_wr(img, x - w * 0.5, y0, x - w * 0.5 + 1.0 / PPU, y1, c.lightened(0.18))
	_wr(img, x + w * 0.5 - 2.0 / PPU, y0, x + w * 0.5, y1, c.darkened(0.25))


## Tonneau vu de face (bombé, deux cerclages de fer), pied posé en (x, y).
static func _barrel(img: Image, x: float, y: float, w: float, h: float, wood: Color = Color("#7e5232")) -> void:
	var cx := _X(img, x)
	var base := _Y(img, y)
	var hp := int(h * PPU)
	var wp := int(w * PPU * 0.5)
	for r in hp:
		var t := float(r) / float(hp)
		var half := wp - 2 + int(round(sin(t * PI) * 2.0))
		var yy := base - r - 1
		PA.rect(img, cx - half, yy, half * 2, 1, wood)
		PA.rect(img, cx - half, yy, 2, 1, wood.lightened(0.2))
		PA.rect(img, cx + half - 3, yy, 3, 1, wood.darkened(0.3))
		if r in [int(hp * 0.2), int(hp * 0.2) + 1, int(hp * 0.78), int(hp * 0.78) + 1]:
			PA.rect(img, cx - half, yy, half * 2, 1, Color("#37353f"))
		elif r % 6 == 0:
			PA.rect(img, cx - half + 4, yy, 1, 1, wood.darkened(0.2))
	PA.ellipse(img, float(cx), float(base - hp), float(wp - 2), 2.5, wood.lightened(0.1))


static func _bottle(img: Image, x: int, y: int, c: Color, h: int = 9) -> void:
	PA.rect(img, x, y - h, 3, h, c)
	PA.rect(img, x + 1, y - h - 3, 1, 3, c.darkened(0.2))
	PA.px(img, x, y - h + 1, c.lightened(0.45))


static func _lantern(img: Image, x: float, y: float, col: Color) -> void:
	var cx := _X(img, x)
	var cy := _Y(img, y)
	PA.rect(img, cx, cy - 12, 1, 12, Color("#1c1418"))
	PA.rect(img, cx - 4, cy, 9, 2, Color("#2a2024"))
	PA.rect(img, cx - 3, cy + 2, 7, 8, col)
	PA.rect(img, cx - 2, cy + 3, 5, 6, col.lightened(0.5))
	PA.rect(img, cx - 4, cy + 10, 9, 2, Color("#2a2024"))
	_glow(img, x, y - 0.4, 2.6, Color(col.r, col.g * 0.8, col.b * 0.5), 0.55)


## Fenêtre : cadre, vitre en dégradé, croisillons.
static func _window(img: Image, x0: float, y0: float, x1: float, y1: float, top: Color, bottom: Color, frame: Color, cols: int = 2, rows: int = 3) -> void:
	_wr(img, x0 - 0.1, y0 - 0.1, x1 + 0.1, y1 + 0.1, frame)
	var a := _X(img, x0)
	var b := _X(img, x1)
	var t := _Y(img, y1)
	var d := _Y(img, y0)
	for y in range(t, d):
		var k := float(y - t) / float(maxi(d - t - 1, 1))
		PA.rect(img, a, y, b - a, 1, top.lerp(bottom, k))
	for i in range(1, cols):
		PA.rect(img, a + (b - a) * i / cols, t, 2, d - t, frame)
	for j in range(1, rows):
		PA.rect(img, a, t + (d - t) * j / rows, b - a, 2, frame)


# ====================================================================== taverne

static func _taverne(img: Image) -> void:
	var beam := Color("#3b2717")
	_fill_tile(img, "plaster", 0, 0, img.get_width(), img.get_height(), Color(0.5, 0.38, 0.29))
	# poteaux et lisse haute : le colombage (la zone visible va d'environ -10,5 à 10,5)
	for px: float in [-16.6, -11.0, -4.4, 1.0, 8.6, 12.4, 16.2]:
		_post(img, px, 0.0, 5.2, 0.34, beam)
	_wr(img, -18.0, 4.9, 18.0, 5.35, beam.lightened(0.05))
	_wr(img, -18.0, 5.35, 18.0, 6.0, Color("#1b130f"))
	for px: float in [-16.6, -11.0, -4.4, 1.0, 8.6, 12.4]:   # écharpes en diagonale
		var x := _X(img, px)
		PA.line(img, x, _Y(img, 4.9), x + 30, _Y(img, 3.8), beam)
		PA.line(img, x, _Y(img, 4.9) + 1, x + 30, _Y(img, 3.8) + 1, beam)
	# soubassement de planches
	_fill_tile_w(img, "planks", -18.0, 0.0, 18.0, 1.15, Color(0.5, 0.38, 0.3))
	_wr(img, -18.0, 1.15, 18.0, 1.27, Color("#5e4028"))
	# le bar : façade de planches, dessus clair, étagères de bouteilles, chopes
	_fill_tile_w(img, "planks", -10.6, 0.0, -2.2, 1.25, Color(0.66, 0.5, 0.38))
	_wr(img, -10.8, 1.25, -2.0, 1.42, Color("#a47a48"))
	_wr(img, -10.8, 1.38, -2.0, 1.42, Color("#c89a5c"))
	for i in 6:
		var mx := _X(img, -10.0 + float(i) * 1.3)
		PA.rect(img, mx, _Y(img, 1.42) - 5, 4, 5, Color("#8c8c98"))
		PA.rect(img, mx, _Y(img, 1.42) - 5, 1, 5, Color("#b8b8c4"))
	_wr(img, -10.2, 3.0, -3.0, 3.12, Color("#4c3220"))   # étagères aux bouteilles
	_wr(img, -10.2, 4.1, -3.0, 4.22, Color("#4c3220"))
	for i in 17:
		var bx := _X(img, -10.0) + i * 10 + int(PA.rnd(i, 1, 31) * 3.0)
		_bottle(img, bx, _Y(img, 3.0), [Color("#356a3e"), Color("#94582a"), Color("#32508a"), Color("#6a2830")][i % 4] as Color)
		_bottle(img, bx + 3, _Y(img, 4.1), [Color("#94582a"), Color("#356a3e"), Color("#a89440")][i % 3] as Color, 8)
	# deux fûts rangés à gauche du bar, un robinet de cuivre
	for k in 2:
		var by := _Y(img, 0.65 + float(k) * 0.95)
		var bxx := _X(img, -13.6)
		PA.ellipse(img, float(bxx + 26), float(by), 26.0, 11.0, Color("#6e4628"))
		PA.rect(img, bxx + 10, by - 10, 3, 20, Color("#37353f"))
		PA.rect(img, bxx + 38, by - 10, 3, 20, Color("#37353f"))
		PA.ellipse(img, float(bxx + 5), float(by), 5.0, 10.0, Color("#946a42"))
		PA.rect(img, bxx + 4, by - 2, 3, 4, Color("#b89040"))
	# le tavernier, immobile derrière son bar, un dessus de plat gardé au chaud
	var tx := _X(img, -6.2)
	var ty := _Y(img, 1.42)
	PA.rect(img, tx - 8, ty - 26, 16, 26, Color("#c4bca8"))   # tablier
	PA.rect(img, tx - 8, ty - 26, 3, 26, Color("#98907c"))
	PA.rect(img, tx - 8, ty - 26, 16, 4, Color("#5a3a7a"))
	PA.ellipse(img, float(tx), float(ty - 33), 6.0, 6.5, Color("#d9a878"))
	PA.rect(img, tx - 7, ty - 40, 14, 4, Color("#5a3a22"))
	PA.rect(img, tx - 4, ty - 31, 8, 2, Color("#3a2416"))   # moustache
	PA.px(img, tx - 3, ty - 35, Color("#1c1418"))
	PA.px(img, tx + 2, ty - 35, Color("#1c1418"))
	PA.rect(img, tx - 14, ty - 20, 28, 3, Color("#d9a878"))   # les bras tendus
	PA.ellipse(img, float(tx), float(ty - 22), 9.0, 7.0, Color("#b8bccc"))   # la cloche d'argent
	PA.rect(img, tx - 9, ty - 22, 18, 3, Color("#8a90a0"))
	PA.ellipse(img, float(tx - 3), float(ty - 25), 3.0, 2.0, Color("#e0e8ff"))
	# fenêtre, nuit dehors
	var wx := -1.3
	_wr(img, wx - 0.05, 1.9, wx + 1.65, 4.15, Color("#4a3020"))
	_window(img, wx + 0.1, 2.05, wx + 1.5, 4.0, Color("#2e437e"), Color("#141c3c"), Color("#2a1a10"), 2, 3)
	_wr(img, wx - 0.4, 2.0, wx + 0.05, 4.1, Color("#7a2a2e"))   # rideaux
	_wr(img, wx + 1.55, 2.0, wx + 2.0, 4.1, Color("#7a2a2e"))
	# avis cloué : trois lignes et une croix
	var nx := _X(img, 0.4)
	var ny := _Y(img, 3.6) + 6
	PA.rect(img, nx - 40, ny, 20, 26, Color("#d6ccac"))
	for ln in 4:
		PA.rect(img, nx - 37, ny + 5 + ln * 4, 14 - (ln % 2) * 4, 1, Color("#7a705a"))
	PA.line(img, nx - 38, ny + 3, nx - 23, ny + 22, Color("#a03228"))
	PA.line(img, nx - 23, ny + 3, nx - 38, ny + 22, Color("#a03228"))
	# la cheminée et son feu
	_fill_tile_w(img, "stone", 3.0, 0.0, 8.6, 4.5, Color(0.58, 0.54, 0.52))
	_wr(img, 2.8, 4.5, 8.8, 4.85, Color("#625a50"))
	_wr(img, 4.1, 0.0, 7.5, 2.5, Color("#120a07"))
	var fx0 := _X(img, 4.1)
	var fy0 := _Y(img, 0.0)
	for i in 30:   # flammes : trois couches
		var fxx := fx0 + 4 + i * 2
		var fh := 12 + int(PA.rnd(i, 1, 33) * 26.0) - absi(i - 15) / 2
		PA.rect(img, fxx, fy0 - fh, 2, fh, Color("#c8421c"))
		PA.rect(img, fxx, fy0 - fh * 2 / 3, 2, fh * 2 / 3, Color("#f08a2a"))
		PA.rect(img, fxx, fy0 - fh / 3, 2, fh / 3, Color("#ffd860"))
	PA.rect(img, fx0 + 6, fy0 - 5, 70, 5, Color("#3a2416"))   # bûches
	PA.rect(img, fx0 + 10, fy0 - 8, 60, 3, Color("#5a3a22"))
	# bibelots sur le manteau : deux chandeliers et un fromage entier
	PA.rect(img, _X(img, 3.4), _Y(img, 4.85) - 8, 3, 8, Color("#c8a040"))
	PA.rect(img, _X(img, 8.0), _Y(img, 4.85) - 8, 3, 8, Color("#c8a040"))
	PA.ellipse(img, float(_X(img, 5.8)), float(_Y(img, 4.85) - 5), 8.0, 5.0, Color("#d6a232"))
	# lanternes et jambons pendus aux solives
	_lantern(img, -6.0, 4.5, Color("#ffc860"))
	_lantern(img, 10.4, 4.5, Color("#ffc860"))
	for hx: float in [9.3, 10.0, 12.6, 13.4]:
		var hxx := _X(img, hx)
		var hy := _Y(img, 4.85)
		PA.rect(img, hxx, hy, 1, 8, Color("#2a2024"))
		PA.ellipse(img, float(hxx), float(hy + 17), 5.0, 9.0, Color("#8a3e30"))
		PA.ellipse(img, float(hxx - 1), float(hy + 14), 2.0, 5.0, Color("#b8604a"))
	# seconde fenêtre à droite
	_wr(img, 14.2, 1.9, 15.95, 4.15, Color("#4a3020"))
	_window(img, 14.35, 2.05, 15.8, 4.0, Color("#2e437e"), Color("#141c3c"), Color("#2a1a10"), 2, 3)
	# lumière : le feu chauffe le mur, le plafond reste noir
	_glow(img, 5.8, 1.6, 9.0, Color(1.0, 0.5, 0.18), 0.55)
	_glow(img, -6.0, 2.6, 6.0, Color(1.0, 0.7, 0.3), 0.2)
	_band(img, 0, 26, 0.7, 0.0)
	_band(img, img.get_height() - 12, img.get_height(), 0.0, 0.45)


# ================================================================= étage d'auberge

static func _etage(img: Image) -> void:
	var beam := Color("#241a1c")
	_fill_tile(img, "plaster", 0, 0, img.get_width(), img.get_height(), Color(0.4, 0.42, 0.56))
	_wr(img, -18.0, 5.2, 18.0, 6.0, Color("#0e0c14"))
	_wr(img, -18.0, 4.95, 18.0, 5.25, beam)
	for px: float in [-17.2, -12.9, -8.2, -3.0, 5.0, 9.8, 15.0, 17.2]:
		_post(img, px, 0.0, 4.95, 0.3, beam)
	_fill_tile_w(img, "planks", -18.0, 0.0, 18.0, 1.0, Color(0.34, 0.3, 0.34))
	_wr(img, -18.0, 1.0, 18.0, 1.1, Color("#4a3c44"))
	# les portes numérotées, deux sur trois ouvertes sur le noir
	var n := 1
	for dx: float in [-15.0, -10.5, -5.7, 7.4, 12.4]:
		var open := (n % 2 == 0)
		_wr(img, dx - 0.95, 0.0, dx + 0.95, 3.5, beam.lightened(0.1))
		if open:
			_wr(img, dx - 0.8, 0.0, dx + 0.8, 3.35, Color("#06050a"))
			_wr(img, dx - 0.8, 0.0, dx - 0.65, 3.35, Color("#2a3558"))   # un filet de lune au chambranle
			_wr(img, dx + 0.45, 0.1, dx + 0.8, 3.0, Color("#241a1c"))     # le battant entrouvert
		else:
			_fill_tile_w(img, "wood", dx - 0.8, 0.0, dx + 0.8, 3.35, Color(0.62, 0.5, 0.46))
			_wr(img, dx - 0.3, 1.5, dx - 0.2, 1.62, Color("#c8a840"))
		var nxp := _X(img, dx) - 5
		PA.rect(img, nxp, _Y(img, 3.1), 11, 8, Color("#b8923a"))
		_text(img, nxp + 4, _Y(img, 3.1) + 1, str(n), Color("#3a2a10"))
		# l'affichette « prière de ne pas déranger »
		var ax := _X(img, dx) - 4
		var ay := _Y(img, 2.5)
		PA.rect(img, ax, ay, 9, 12, Color("#e6dcbc"))
		PA.rect(img, ax + 1, ay + 3, 7, 1, Color("#8a7a5a"))
		PA.rect(img, ax + 1, ay + 6, 5, 1, Color("#8a7a5a"))
		PA.rect(img, ax + 1, ay + 9, 7, 1, Color("#8a7a5a"))
		n += 1
	# la fenêtre du bout : lune, étoiles, et un morceau de rampe qui a quitté le bâtiment
	var cx := 0.8
	_wr(img, cx - 2.0, 1.2, cx + 2.0, 4.6, Color("#241a1c"))
	_window(img, cx - 1.85, 1.35, cx + 1.85, 4.45, Color("#1a2a5c"), Color("#0a1030"), Color("#241a1c"), 2, 3)
	var mx := _X(img, cx + 0.5)
	var my := _Y(img, 3.5)
	PA.ellipse(img, float(mx), float(my), 11.0, 11.0, Color("#e8ecff"))
	PA.ellipse(img, float(mx - 3), float(my - 3), 5.0, 4.0, Color("#ffffff"))
	PA.ellipse(img, float(mx + 4), float(my + 3), 3.0, 2.0, Color("#c4c8e6"))
	for i in 12:
		PA.px(img, _X(img, cx - 1.6) + int(PA.rnd(i, 1, 41) * 80.0), _Y(img, 1.5) - int(PA.rnd(i, 2, 41) * 60.0), Color("#c8d0ff"))
	var rx := _X(img, cx - 1.6)
	var ry := _Y(img, 1.6)
	PA.line(img, rx, ry, rx + 70, ry - 40, Color("#7a5434"))   # la rampe dans le vide
	PA.line(img, rx, ry + 1, rx + 70, ry - 39, Color("#7a5434"))
	PA.line(img, rx, ry + 2, rx + 70, ry - 38, Color("#4a3020"))
	for k in 6:
		PA.rect(img, rx + 6 + k * 11, ry - 3 - k * 6, 2, 14, Color("#5a3d26"))
	_glow(img, cx, 3.2, 8.0, Color(0.35, 0.5, 0.95), 0.5)
	# bougies : les flammes penchent toutes du côté des Nazes
	for sx: float in [-12.8, -8.0, 5.2, 10.2, 15.2]:
		var scx := _X(img, sx)
		var scy := _Y(img, 3.9)
		PA.rect(img, scx - 2, scy, 5, 7, Color("#2a2024"))
		PA.rect(img, scx - 1, scy - 8, 3, 8, Color("#efe6c8"))
		PA.ellipse(img, float(scx + 2), float(scy - 11), 2.4, 4.0, Color("#ffcf5a"))
		PA.ellipse(img, float(scx + 3), float(scy - 11), 1.2, 2.2, Color("#fff0b0"))
		_glow(img, sx + 0.1, 3.9, 2.4, Color(1.0, 0.7, 0.3), 0.4)
	_band(img, 0, 24, 0.7, 0.0)
	_band(img, img.get_height() - 10, img.get_height(), 0.0, 0.4)
	_wash(img, Color(0.12, 0.16, 0.34), 0.18)


# ====================================================================== ruelle

static func _ruelle(img: Image) -> void:
	var timber := Color("#1b1620")
	var plaster := Color("#3b4160")
	var brick := Color("#4a2e36")
	# deux rangées de façades à colombages qui se penchent, un mur de brique au fond
	_fill_tile_w(img, "brick", -4.6, 0.0, 4.6, 4.0, Color(0.55, 0.4, 0.42))
	_wr(img, -4.6, 4.0, 4.6, 4.25, Color("#2a2028"))
	for side: int in [-1, 1]:
		var x_in := 4.6 if side > 0 else -4.6
		var x_out := 18.0 if side > 0 else -18.0
		var lo := minf(x_in, x_out)
		var hi := maxf(x_in, x_out)
		_wr(img, lo, 0.0, hi, 6.4, plaster)
		_wr(img, lo, 2.9, hi, 3.1, timber)
		var step := 3.3
		var x := lo
		while x <= hi:
			_post(img, x, 0.0, 6.4, 0.3, timber)
			x += step
		# étage en encorbellement : bande sombre + fenêtres
		for k in 4:
			var wx: float = lo + 1.5 + float(k) * step * (1.0 if hi - lo > 10.0 else 3.0)
			if wx > hi - 1.0:
				continue
			var lit := ((k + (1 if side > 0 else 0)) % 2 == 0)
			_window(img, wx - 0.5, 3.6, wx + 0.5, 5.0, Color("#f0c070") if lit else Color("#1e2640"), Color("#c88a3c") if lit else Color("#10162a"), timber, 2, 2)
			_wr(img, wx - 0.95, 3.6, wx - 0.55, 5.0, Color("#27424a"))   # volets
			_wr(img, wx + 0.55, 3.6, wx + 0.95, 5.0, Color("#27424a"))
			if lit:
				_glow(img, wx, 4.3, 2.6, Color(1.0, 0.65, 0.25), 0.55)
			_window(img, wx - 0.5, 0.9, wx + 0.5, 2.2, Color("#18203a"), Color("#0e1428"), timber, 2, 2)
			_wr(img, wx - 0.95, 0.9, wx - 0.55, 2.2, Color("#27424a"))
			_wr(img, wx + 0.55, 0.9, wx + 0.95, 2.2, Color("#27424a"))
	# la porte d'une fromagerie à droite et son enseigne : un camembert qui s'est écoulé
	_wr(img, 7.0, 0.0, 8.6, 2.5, Color("#2a1c22"))
	_wr(img, 7.15, 0.0, 8.45, 2.35, Color("#4a2e2a"))
	var sx := _X(img, 10.4)
	var sy := _Y(img, 3.2)
	PA.rect(img, _X(img, 9.0), sy - 3, sx - _X(img, 9.0), 3, Color("#15101a"))
	PA.rect(img, sx - 1, sy, 2, 6, Color("#15101a"))
	PA.ellipse(img, float(sx), float(sy + 17), 13.0, 11.0, Color("#e8c24e"))
	PA.ellipse(img, float(sx - 4), float(sy + 13), 5.0, 3.0, Color("#f6e08a"))
	PA.rect(img, sx - 9, sy + 22, 6, 12, Color("#e8c24e"))   # le fromage s'écoule
	PA.rect(img, sx - 8, sy + 31, 4, 4, Color("#e8c24e"))
	PA.rect(img, sx + 4, sy + 24, 5, 8, Color("#e8c24e"))
	PA.rect(img, sx - 12, sy + 36, 12, 2, Color("#c8a43a"))   # la flaque dessous
	# l'autre enseigne : une botte de poireaux
	var px := _X(img, -10.6)
	var py := _Y(img, 3.4)
	PA.rect(img, px - 14, py - 3, 14, 3, Color("#15101a"))
	PA.rect(img, px - 1, py, 2, 5, Color("#15101a"))
	PA.rect(img, px - 6, py + 5, 12, 14, Color("#7aa850"))
	PA.rect(img, px - 6, py + 15, 12, 6, Color("#e0e4d0"))
	# lanternes jaunes en haut des murs
	_lantern(img, -5.4, 4.4, Color("#ffc860"))
	_lantern(img, 5.4, 4.4, Color("#ffc860"))
	_lantern(img, 0.0, 3.6, Color("#ffc860"))
	_band(img, 0, 30, 0.55, 0.0)
	_wash(img, Color(0.08, 0.1, 0.28), 0.22)


# ==================================================================== cave à fromage

static func _cave(img: Image) -> void:
	var stone := Color(0.52, 0.58, 0.54)
	_fill_tile(img, "stone", 0, 0, img.get_width(), img.get_height(), stone)
	# la voûte : arcs brisés entre piliers, au-dessus un plafond noir
	var pillars: Array[float] = [-17.4, -10.2, -3.0, 4.2, 11.4, 17.4]
	for i in range(pillars.size() - 1):
		var x0: float = pillars[i]
		var x1: float = pillars[i + 1]
		var mid := (x0 + x1) * 0.5
		# niche aux rayonnages : fond plus sombre
		_fill_tile_w(img, "stone", x0 + 0.5, 0.0, x1 - 0.5, 3.8, Color(0.32, 0.36, 0.35))
		# rayonnages : quatre clayettes de meules
		for row in 4:
			var yy := 0.55 + float(row) * 0.95
			_wr(img, x0 + 0.5, yy - 0.12, x1 - 0.5, yy, Color("#6e4c2c"))
			var n := int((x1 - x0 - 1.0) / 1.05)
			for c in n:
				var wx := x0 + 0.95 + float(c) * 1.05 + (0.25 if row % 2 == 1 else 0.0)
				if wx > x1 - 1.0:
					continue
				var cx := _X(img, wx)
				var cy := _Y(img, yy)
				var kind := int(PA.rnd(i * 10 + c, row, 51) * 4.0)
				var rind := [Color("#e0b04a"), Color("#d9d2b6"), Color("#c8873a"), Color("#e6cf7a")][kind] as Color
				PA.rect(img, cx - 11, cy - 14, 22, 14, rind.darkened(0.12))
				PA.rect(img, cx - 11, cy - 14, 3, 14, rind.lightened(0.1))
				PA.ellipse(img, float(cx), float(cy - 14), 11.0, 4.0, rind.lightened(0.18))
				if kind == 1 or PA.rnd(c, row, 52) < 0.3:
					PA.rect(img, cx - 5, cy - 16, 3, 2, Color("#4a8aa8"))   # persillé
					PA.rect(img, cx + 3, cy - 12, 2, 2, Color("#4a8aa8"))
				# l'étiquette « affinage à l'ancienne, très lent »
				PA.rect(img, cx - 4, cy + 1, 8, 4, Color("#ece4cc"))
				PA.rect(img, cx - 3, cy + 3, 6, 1, Color("#7a705a"))
		# tonneaux de saumure au pied de chaque niche
		_barrel(img, mid - 1.8, 0.0, 1.1, 1.0, Color("#6e4a2c"))
		_barrel(img, mid + 1.8, 0.0, 1.1, 1.0, Color("#6e4a2c"))
		# arc brisé au-dessus
		var ax0 := _X(img, x0)
		var ax1 := _X(img, x1)
		var ytop := _Y(img, 3.8)
		for xx in range(ax0, ax1):
			var t := (float(xx - ax0) / float(ax1 - ax0)) * 2.0 - 1.0
			var rise := int((1.0 - absf(t)) * 1.1 * PPU)
			for yy in range(ytop - 16 - rise, ytop - rise):
				if yy >= 0 and yy < img.get_height():
					img.set_pixel(xx, yy, Color(0.56, 0.6, 0.55).darkened(0.12 + float(yy % 6 == 0) * 0.1))
			for yy in range(0, ytop - 16 - rise):
				img.set_pixel(xx, yy, Color("#0e1210"))
	for px: float in pillars:
		_post(img, px, 0.0, 5.0, 0.85, Color("#6a736a"))
	# lanternes verdâtres au bout de chaînes
	for lx: float in [-6.6, 7.8]:
		_lantern(img, lx, 4.5, Color("#c8f0a0"))
	# taches de moisissure bleue qui luisent
	for i in 9:
		var mx := -16.0 + PA.rnd(i, 1, 53) * 32.0
		var my := 0.6 + PA.rnd(i, 2, 53) * 3.0
		_glow(img, mx, my, 0.9, Color(0.2, 0.55, 0.8), 0.6)
	_band(img, 0, 22, 0.55, 0.0)
	_wash(img, Color(0.1, 0.24, 0.2), 0.2)


# ======================================================================== ferme

static func _ferme(img: Image) -> void:
	# la grange à gauche : planches rouges délavées, grande porte à croix, lucarne à foin
	var barn := Color(0.68, 0.34, 0.28)
	_fill_tile_w(img, "planks", -17.0, 0.0, -4.0, 4.4, barn)
	for vx in range(-17, -4):
		_wr(img, float(vx), 0.0, float(vx) + 0.05, 4.4, Color("#5a2a22"))
	# toit
	var roof_l := _X(img, -17.8)
	var roof_r := _X(img, -3.2)
	for k in 36:
		var inset := int(float(k) * 0.9)
		PA.rect(img, roof_l + inset, _Y(img, 4.4) - k, (roof_r - roof_l) - inset * 2, 1, Color("#4a342c").lerp(Color("#6e4a3a"), float(k) / 36.0))
	# grande porte à croix
	_wr(img, -13.2, 0.0, -7.8, 3.4, Color("#3a1c18"))
	_fill_tile_w(img, "planks", -13.0, 0.0, -8.0, 3.2, Color(0.55, 0.3, 0.25))
	var d0 := _X(img, -13.0)
	var d1 := _X(img, -8.0)
	PA.line(img, d0, _Y(img, 3.2), d1, _Y(img, 0.0), Color("#2a1210"))
	PA.line(img, d1, _Y(img, 3.2), d0, _Y(img, 0.0), Color("#2a1210"))
	PA.rect(img, (d0 + d1) / 2, _Y(img, 3.2), 2, _Y(img, 0.0) - _Y(img, 3.2), Color("#2a1210"))
	# lucarne : une botte de foin qui dépasse
	_wr(img, -11.2, 3.5, -9.8, 4.3, Color("#1c0e0c"))
	PA.rect(img, _X(img, -11.0), _Y(img, 3.8), 24, 8, Color("#d8b04a"))
	# la girouette : un coq qui regarde du mauvais côté
	var gx := _X(img, -10.5)
	var gy := _Y(img, 4.4) - 36
	PA.rect(img, gx, gy - 12, 2, 48, Color("#2a2024"))
	PA.ellipse(img, float(gx + 1), float(gy - 12), 7.0, 4.0, Color("#3a3a46"))
	PA.rect(img, gx + 5, gy - 18, 4, 5, Color("#3a3a46"))
	PA.rect(img, gx + 8, gy - 17, 3, 1, Color("#3a3a46"))
	PA.rect(img, gx - 9, gy - 18, 8, 3, Color("#3a3a46"))
	PA.rect(img, gx - 1, gy - 6, 3, 12, Color("#8a7a5a"))
	# la meule de foin au centre-droit
	var hx := _X(img, 4.5)
	var hy := _Y(img, 0.0)
	for k in 70:
		var t := float(k) / 70.0
		var half := int(sqrt(maxf(1.0 - t * t, 0.0)) * 62.0)
		var shade := Color("#d6aa44").darkened(t * 0.18)
		PA.rect(img, hx - half, hy - k, half * 2, 1, shade)
		if k % 5 == 0:
			PA.rect(img, hx - half / 2, hy - k, half, 1, shade.lightened(0.12))
	for i in 28:
		PA.px(img, hx - 50 + int(PA.rnd(i, 1, 61) * 100.0), hy - 3 - int(PA.rnd(i, 2, 61) * 60.0), Color("#f0d57c"))
	# abreuvoir et poulailler
	_fill_tile_w(img, "wood", -2.4, 0.0, 0.2, 0.7, Color(0.7, 0.55, 0.42))
	_wr(img, -2.3, 0.55, 0.1, 0.62, Color("#4a7c9a"))
	var cxp := 12.5
	_fill_tile_w(img, "planks", cxp - 1.6, 0.0, cxp + 1.6, 1.8, Color(0.74, 0.6, 0.45))
	var c0 := _X(img, cxp - 2.0)
	var c1 := _X(img, cxp + 2.0)
	for k in 14:
		PA.rect(img, c0 + k, _Y(img, 1.8) - k, (c1 - c0) - k * 2, 1, Color("#7a5a3c").lerp(Color("#9a7a52"), float(k) / 14.0))
	PA.rect(img, _X(img, cxp - 0.3), _Y(img, 1.1), 14, 20, Color("#1c0e0c"))
	# clôture le long du bas
	for fx in range(-18, 18):
		if fx > -4 and fx < 3:
			continue
		_wr(img, float(fx) + 0.3, 0.0, float(fx) + 0.45, 1.05, Color("#7a5a3a"))
	_wr(img, -18.0, 0.7, -4.0, 0.82, Color("#8a6a46"))
	_wr(img, 3.0, 0.7, 18.0, 0.82, Color("#8a6a46"))
	_glow(img, 6.0, 3.0, 12.0, Color(1.0, 0.8, 0.45), 0.2)
	_band(img, img.get_height() - 8, img.get_height(), 0.0, 0.3)


# ======================================================================== route

static func _route(img: Image) -> void:
	# talus et haie de part et d'autre de la route : haies fleuries, peupliers, barrière brisée
	var leaf_d := Color("#2f5530")
	var leaf := Color("#4a7a3c")
	var leaf_l := Color("#7aa84e")
	for i in 90:
		var hx := -18.0 + float(i) * 0.4
		var hh := 1.1 + PA.rnd(i, 1, 71) * 0.7
		var cx := _X(img, hx)
		var cy := _Y(img, 0.5)
		PA.ellipse(img, float(cx), float(cy - 14), 10.0 + PA.rnd(i, 3, 71) * 6.0, hh * 14.0, leaf_d)
	for i in 90:
		var hx := -18.0 + float(i) * 0.4 + 0.15
		var cx := _X(img, hx)
		var cy := _Y(img, 0.5)
		PA.ellipse(img, float(cx), float(cy - 16), 8.0 + PA.rnd(i, 4, 71) * 4.0, 10.0 + PA.rnd(i, 5, 71) * 5.0, leaf)
		PA.ellipse(img, float(cx - 3), float(cy - 22), 4.0, 3.0, leaf_l)
		if PA.rnd(i, 6, 71) < 0.35:   # fleurs d'aubépine
			PA.px(img, cx + 2, cy - 20 + int(PA.rnd(i, 7, 71) * 8.0), Color("#f4efe6"))
			PA.px(img, cx - 4, cy - 16, Color("#f4efe6"))
	# peupliers qui dépassent
	for tx: float in [-14.0, -7.4, 6.8, 13.6]:
		var cx := _X(img, tx)
		var base := _Y(img, 1.0)
		var hgt := 80 + int(PA.rnd(int(tx), 1, 72) * 30.0)
		for k in hgt:
			var half := int(sin(float(k) / float(hgt) * PI) * 7.0) + 1
			PA.rect(img, cx - half, base - k, half * 2, 1, leaf_d if k % 7 != 0 else leaf)
		PA.rect(img, cx - 1, base, 3, 8, Color("#4a3a2a"))
	# une barrière brisée : deux montants, une barre pendante
	var bx := _X(img, -9.0)
	var by := _Y(img, 0.0)
	PA.rect(img, bx, by - 34, 4, 34, Color("#7a5a3a"))
	PA.rect(img, bx + 70, by - 30, 4, 30, Color("#7a5a3a"))
	PA.rect(img, bx, by - 30, 40, 3, Color("#8a6a46"))
	PA.line(img, bx + 40, by - 30, bx + 62, by - 8, Color("#8a6a46"))
	PA.line(img, bx + 40, by - 29, bx + 62, by - 7, Color("#6a4a2a"))
	_band(img, img.get_height() - 8, img.get_height(), 0.0, 0.3)
	_glow(img, 0.0, 2.0, 10.0, Color(1.0, 0.8, 0.4), 0.12)


# ========================================================================== col

static func _col(img: Image) -> void:
	# une lisière de sapins noirs saupoudrés de neige, de part et d'autre d'un passage dégagé
	var fir := Color("#1f3a38")
	var fir_l := Color("#365a52")
	var snow := Color("#e6eef6")
	var trees: Array = [[-17.0, 5.2], [-14.6, 4.0], [-12.2, 5.6], [-9.8, 3.6], [-7.2, 4.6], [-4.8, 3.0], [5.0, 3.2], [7.6, 4.8], [10.4, 3.8], [13.0, 5.6], [15.4, 4.2], [17.4, 5.0]]
	for t: Array in trees:
		var cx := _X(img, float(t[0]))
		var base := _Y(img, 0.2)
		var hgt := int(float(t[1]) * PPU)
		var tiers := 7
		for k in hgt:
			var tier := (k * tiers) / hgt
			var inner := (k * tiers) % hgt
			var half := int((1.0 - float(k) / float(hgt)) * 17.0 * float(hgt) / 110.0) + 2 + (tiers - tier) * 0 + (inner % maxi(hgt / tiers, 1)) / 4
			half = mini(half, int(float(hgt) * 0.16) + 3)
			PA.rect(img, cx - half, base - k, half * 2, 1, fir_l if (k % 5 == 0) else fir)
			if k % (hgt / tiers) < 3:   # la neige s'accroche au bord de chaque étage
				PA.rect(img, cx - half, base - k, half + 1, 1, snow)
		PA.rect(img, cx - 1, base, 3, 6, Color("#2a1e18"))
	_band(img, img.get_height() - 8, img.get_height(), 0.0, 0.3, Color(0.1, 0.12, 0.2))
	_wash(img, Color(0.5, 0.62, 0.8), 0.1)


# ======================================================================== cité

static func _cite(img: Image) -> void:
	# une colonnade d'arcs brisés ivoire et or : on voit la vallée et ses cascades par les arcs
	var ivory := Color("#e6dcc2")
	var ivory_d := Color("#bfb497")
	var gold := Color("#e0b04a")
	var roof := Color("#5f7f8c")
	_wr(img, -18.0, 4.95, 18.0, 6.0, roof)
	for i in 36:   # tuiles en écailles
		PA.px(img, i * 24 + 6, _Y(img, 5.4), roof.lightened(0.25))
	_wr(img, -18.0, 4.7, 18.0, 4.95, gold)
	_wr(img, -18.0, 4.5, 18.0, 4.7, ivory_d)
	var cols: Array[float] = [-17.0, -11.0, -5.0, 1.0, 7.0, 13.0, 18.9]
	for i in range(cols.size() - 1):
		var x0: float = cols[i]
		var x1: float = cols[i + 1]
		var ax0 := _X(img, x0 + 0.5)
		var ax1 := mini(_X(img, x1 - 0.5), img.get_width())
		var base_y := _Y(img, 3.2)
		# remplit le tympan au-dessus de l'arc (hors de l'ouverture), laisse l'arc ouvert
		for xx in range(ax0, ax1):
			var t := (float(xx - ax0) / float(maxi(ax1 - ax0, 1))) * 2.0 - 1.0
			var rise := int((1.0 - absf(t) * absf(t) * 0.25 - absf(t) * 0.45) * 1.6 * PPU)
			var arc_top := base_y - rise
			for yy in range(_Y(img, 4.5), arc_top):
				img.set_pixel(xx, yy, ivory)
			if arc_top >= 0 and arc_top < img.get_height():
				PA.px(img, xx, arc_top, gold)
				PA.px(img, xx, arc_top + 1, gold.darkened(0.2))
	for px in cols:
		if px > 18.0:
			continue
		_post(img, px, 0.0, 4.5, 0.62, ivory)
		_wr(img, px - 0.4, 0.0, px + 0.4, 0.3, ivory_d)
		_wr(img, px - 0.4, 3.2, px + 0.4, 3.45, gold)
		_wr(img, px - 0.05, 0.4, px + 0.0, 3.1, ivory_d)   # cannelures
		_wr(img, px - 0.2, 0.4, px - 0.17, 3.1, ivory_d)
		_wr(img, px + 0.15, 0.4, px + 0.18, 3.1, ivory_d)
	# balustrade basse entre les colonnes
	for i in range(cols.size() - 1):
		var x0: float = cols[i] + 0.4
		var x1: float = cols[i + 1] - 0.4
		_wr(img, x0, 0.9, x1, 1.0, ivory)
		var n := int((x1 - x0) / 0.35)
		for k in n:
			_wr(img, x0 + 0.1 + float(k) * 0.35, 0.3, x0 + 0.2 + float(k) * 0.35, 0.9, ivory)
	# la plaque de la fontaine, vissée à une colonne : « prière de ne pas se presser »
	var px := _X(img, -5.0) - 7
	var py := _Y(img, 2.0)
	PA.rect(img, px, py, 14, 9, gold)
	PA.rect(img, px + 1, py + 1, 12, 7, Color("#3a2c18"))
	for k in 3:
		PA.rect(img, px + 3, py + 2 + k * 2, 8 - (k % 2) * 2, 1, Color("#e8d8a0"))
	# lueurs dorées : le soleil du matin entre par les arcs
	_glow(img, -1.0, 2.5, 9.0, Color(1.0, 0.85, 0.5), 0.2)
	_band(img, img.get_height() - 8, img.get_height(), 0.0, 0.18, Color(0.2, 0.25, 0.4))


# ====================================================================== conseil

static func _conseil(img: Image) -> void:
	_fill_tile(img, "elf_wall_vista", 0, 0, img.get_width(), img.get_height(), Color(0.85, 0.85, 0.9))
	_wr(img, -18.0, 5.3, 18.0, 6.0, Color("#6a6a78"))
	_wr(img, -18.0, 5.15, 18.0, 5.3, Color("#e0b04a"))
	_wr(img, -18.0, 0.0, 18.0, 0.35, Color("#9a9aa6"))
	# trois vitraux en ogive, fond de lierre, rais de lumière
	for vx: float in [-10.0, 0.0, 10.0]:
		var x0 := _X(img, vx - 1.1)
		var x1 := _X(img, vx + 1.1)
		var yb := _Y(img, 1.4)
		var ytop := _Y(img, 4.2)
		for xx in range(x0 - 2, x1 + 2):
			var t := (float(xx - x0) / float(maxi(x1 - x0, 1))) * 2.0 - 1.0
			var rise := int((1.0 - absf(t) * 0.9) * 28.0)
			for yy in range(ytop - rise - 2, yb):
				var inside := xx >= x0 and xx < x1 and yy >= ytop - rise
				if inside:
					var gk := (xx / 5 + yy / 5) % 3
					var gc := [Color("#4f8a4a"), Color("#6fae5c"), Color("#d6c458")][gk] as Color
					if (xx - x0) % 8 == 0 or (yy - ytop) % 9 == 0:
						gc = Color("#2a3a2a")
					img.set_pixel(xx, yy, gc)
				else:
					img.set_pixel(xx, yy, Color("#8a8a98"))
		_glow(img, vx, 2.8, 4.5, Color(0.95, 0.95, 0.7), 0.4)
	# la longue table d'orme, vide : plateau, pieds, dossiers de fauteuils derrière
	for i in 12:
		var sx := _X(img, -13.5 + float(i) * 2.45)
		var sy := _Y(img, 1.2)
		PA.rect(img, sx - 11, sy - 30, 22, 30, Color("#7a5a3a"))
		PA.rect(img, sx - 11, sy - 30, 22, 3, Color("#9a7a52"))
		PA.rect(img, sx - 8, sy - 26, 16, 22, Color("#5a7a4a"))   # coussin vert
	_wr(img, -14.8, 0.0, 14.8, 1.2, Color("#9a6a3a"))
	_wr(img, -14.8, 1.15, 14.8, 1.35, Color("#c89a58"))
	_wr(img, -14.8, 1.2, 14.8, 1.25, Color("#e8c07a"))
	for i in 6:
		_wr(img, -14.0 + float(i) * 5.6, 0.0, -13.7 + float(i) * 5.6, 1.15, Color("#6a4a2a"))
	# l'ordre du jour cloué au mur : « 8. (voir 6.) »
	var ax := _X(img, 5.0)
	var ay := _Y(img, 4.6)
	PA.rect(img, ax + 1, ay + 1, 40, 50, Color("#6a6a78"))
	PA.rect(img, ax, ay, 40, 50, Color("#f0e9d2"))
	for k in 5:
		_text(img, ax + 5, ay + 5 + k * 7, ["1.", "2.", "6.", "7.", "8.(6)"][k], Color("#5a5a6a"))
	PA.rect(img, ax + 18, ay - 3, 4, 4, Color("#b03a30"))   # la punaise
	# le huissier pétrifié, qui note encore
	var hx := _X(img, 13.0)
	var hy := _Y(img, 0.0)
	PA.rect(img, hx - 9, hy - 40, 18, 40, Color("#8a8c9a"))
	PA.rect(img, hx - 9, hy - 40, 3, 40, Color("#b0b2c0"))
	PA.ellipse(img, float(hx), float(hy - 47), 7.0, 7.0, Color("#9a9caa"))
	PA.rect(img, hx + 7, hy - 36, 10, 14, Color("#d8d4c0"))   # son carnet
	PA.line(img, hx + 4, hy - 30, hx + 14, hy - 38, Color("#6a6a78"))
	# bannières de lierre
	for bx: float in [-14.5, 14.5]:
		var px := _X(img, bx)
		PA.rect(img, px - 9, _Y(img, 4.4), 18, 60, Color("#3f6a3c"))
		PA.rect(img, px - 9, _Y(img, 4.4), 2, 60, Color("#6fae5c"))
		PA.rect(img, px - 1, _Y(img, 4.4) + 6, 3, 46, Color("#e0b04a"))
	_glow(img, 0.0, 3.0, 12.0, Color(1.0, 0.95, 0.75), 0.18)
	_band(img, 0, 18, 0.5, 0.0)


# ===================================================================== archives

static func _archives(img: Image) -> void:
	_fill_tile(img, "elf_wall_books", 0, 0, img.get_width(), img.get_height(), Color(0.4, 0.36, 0.3))
	var wood := Color("#5a3d26")
	var bays: Array[float] = [-18.0, -11.4, -4.8, 1.8, 8.4, 15.0, 21.6]
	for i in range(bays.size() - 1):
		var x0: float = bays[i] + 0.3
		var x1: float = bays[i + 1] - 0.3
		_wr(img, x0, 0.0, x1, 5.4, Color("#241a14"))
		for row in 6:   # rayons : tranches de reliures serrées
			var yy := 0.15 + float(row) * 0.88
			_wr(img, x0, yy, x1, yy + 0.1, wood)
			var bx := _X(img, x0) + 2
			var limit := _X(img, x1) - 3
			var sd := 100 + i * 10 + row
			while bx < limit:
				var bw := 3 + int(PA.rnd(bx, row, sd) * 4.0)
				var bh := 14 + int(PA.rnd(bx, row + 9, sd) * 6.0)
				var hue := PA.rnd(bx, row + 3, sd)
				var col: Color
				if row == 0:
					col = Color("#6a3a2a")   # grands registres reliés de cuir
					bw += 4
					bh = 20
				elif hue < 0.3:
					col = Color("#7a3030")
				elif hue < 0.5:
					col = Color("#2f5a46")
				elif hue < 0.7:
					col = Color("#3a4a7a")
				elif hue < 0.85:
					col = Color("#8a6a3a")
				else:
					col = Color("#d6ccb0")
				var yb := _Y(img, yy + 0.1)
				if bx + bw < limit:
					PA.rect(img, bx, yb - bh, bw, bh, col)
					PA.rect(img, bx, yb - bh, 1, bh, col.lightened(0.18))
					PA.rect(img, bx, yb - bh + 3, bw, 1, Color("#e0b04a"))
				bx += bw + (1 if PA.rnd(bx, row, sd + 1) < 0.7 else 3)
		# l'ogive : le sommet des rayonnages
		var ax0 := maxi(_X(img, x0), 0)
		var ax1 := mini(_X(img, x1), img.get_width())
		for xx in range(ax0, ax1):
			var t := (float(xx - ax0) / float(maxi(ax1 - ax0, 1))) * 2.0 - 1.0
			var rise := int((1.0 - absf(t)) * 1.0 * PPU)
			for yy in range(0, _Y(img, 5.0) - rise + 2):
				img.set_pixel(xx, yy, Color("#171110") if yy < _Y(img, 5.0) - rise - 1 else Color("#7a6a50"))
	for px: float in bays:
		if px > 18.0:
			continue
		_post(img, px, 0.0, 5.6, 0.6, Color("#cfc7b0").darkened(0.35))
	# l'échelle à roulettes
	var ex := _X(img, -7.8)
	var ey := _Y(img, 0.0)
	PA.line(img, ex, ey, ex + 26, ey - 130, Color("#8a6a3c"))
	PA.line(img, ex + 1, ey, ex + 27, ey - 130, Color("#8a6a3c"))
	PA.line(img, ex + 14, ey, ex + 40, ey - 130, Color("#8a6a3c"))
	PA.line(img, ex + 15, ey, ex + 41, ey - 130, Color("#6a4a2c"))
	for k in 9:
		PA.rect(img, ex + 2 + k * 3, ey - 10 - k * 14, 14, 2, Color("#a8844c"))
	# pancarte « silence, ordre, respect » et un lecteur très penché dessous
	var sx := _X(img, 3.0)
	var sy := _Y(img, 4.9)
	PA.rect(img, sx - 22, sy - 2, 2, 8, Color("#241a14"))
	PA.rect(img, sx + 20, sy - 2, 2, 8, Color("#241a14"))
	PA.rect(img, sx - 24, sy + 5, 48, 22, Color("#d8cfb4"))
	PA.rect(img, sx - 24, sy + 5, 48, 2, Color("#e8e0c8"))
	PA.rect(img, sx - 22, sy + 9, 44, 1, Color("#8a7a5a"))
	PA.rect(img, sx - 18, sy + 13, 36, 1, Color("#8a7a5a"))
	PA.ellipse(img, float(sx), float(sy + 21), 5.0, 4.0, Color("#b03a30"))   # un livre barré
	PA.line(img, sx - 5, sy + 17, sx + 5, sy + 25, Color("#d8cfb4"))
	var rx := _X(img, 3.0)
	var ry := _Y(img, 0.0)
	PA.rect(img, rx - 12, ry - 44, 26, 44, Color("#3a3a5a"))   # le lecteur, penché de côté
	PA.ellipse(img, float(rx + 4), float(ry - 52), 6.0, 6.0, Color("#d9a878"))
	PA.rect(img, rx - 2, ry - 33, 20, 12, Color("#c8bfa0"))   # son livre
	PA.rect(img, rx, ry - 33, 1, 12, Color("#8a7a5a"))
	# lampes à huile : halos chauds
	for lx: float in [-13.0, -1.0, 9.6, 16.0]:
		_lantern(img, lx, 4.6, Color("#ffc060"))
	_band(img, 0, 22, 0.6, 0.0)
	_wash(img, Color(0.2, 0.14, 0.08), 0.12)


# ======================================================================== quai

static func _quai(img: Image) -> void:
	# l'entrepôt du quai : planches mouillées, filets pendus, tonneaux, une barque tirée au sec
	_fill_tile_w(img, "planks", -18.0, 0.0, -2.0, 3.8, Color(0.5, 0.45, 0.42))
	for vx in range(-18, -2, 2):
		_wr(img, float(vx), 0.0, float(vx) + 0.08, 3.8, Color("#2f2a2e"))
	var roof_l := _X(img, -18.0)
	var roof_r := _X(img, -1.4)
	for k in 26:
		PA.rect(img, roof_l, _Y(img, 3.8) - k, (roof_r - roof_l) - int(float(k) * 0.4), 1, Color("#3a3a4a").lerp(Color("#5f6a7a"), float(k) / 26.0))
	_wr(img, -9.0, 0.0, -6.8, 2.6, Color("#241c1c"))   # la porte de l'entrepôt
	_window(img, -15.0, 1.9, -13.6, 3.0, Color("#f0c070"), Color("#c88a3c"), Color("#2f2a2e"), 2, 2)
	_glow(img, -14.3, 2.4, 3.0, Color(1.0, 0.65, 0.25), 0.5)
	# filets pendus au pignon
	var nx := _X(img, -5.0)
	for k in 14:
		PA.line(img, nx + k * 3, _Y(img, 3.6), nx + k * 3 - 6, _Y(img, 1.2), Color("#7a6a4a"))
	for k in 8:
		PA.line(img, nx - 6, _Y(img, 3.4) + k * 8, nx + 40, _Y(img, 3.4) + k * 8 + 4, Color("#7a6a4a"))
	# la Grande Bitte et ses sœurs, toutes penchées du même côté
	for i in 6:
		var bx := _X(img, 2.0 + float(i) * 2.6)
		var by := _Y(img, 0.0)
		var lean := 10 + (i % 3)
		var big := (i == 2)
		var w := 11 if big else 7
		var h := 52 if big else 30
		for k in h:
			var off := (k * lean) / h
			PA.rect(img, bx - w / 2 + off, by - k, w, 1, Color("#4a4e5a") if k % 4 != 0 else Color("#5e626e"))
		PA.ellipse(img, float(bx + lean), float(by - h), float(w) * 0.7, 3.0, Color("#6a6e7c"))
		if big:   # sa plaque : « fierté du village »
			PA.rect(img, bx + 2, by - 24, 14, 8, Color("#c8a040"))
			PA.rect(img, bx + 4, by - 22, 10, 1, Color("#3a2c10"))
			PA.rect(img, bx + 4, by - 20, 7, 1, Color("#3a2c10"))
	_barrel(img, -1.1, 0.0, 1.0, 1.0, Color("#5a4a3a"))
	_barrel(img, 0.3, 0.0, 1.0, 1.0, Color("#5a4a3a"))
	_glow(img, 6.0, 2.5, 12.0, Color(1.0, 0.6, 0.3), 0.18)
	_band(img, img.get_height() - 8, img.get_height(), 0.0, 0.3)
