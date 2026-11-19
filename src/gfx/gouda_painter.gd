extends RefCounted
## Peint par code la cité blanche du chapitre 6 : Minas Tartine et ses abords (style « gouda »),
## le Sentier des Insomniaques (style « veille »), Port-Salé (style « port ») et les champs du
## Pelle-à-Tarte (style « champ »). Pierre blanche à étages, ardoise, bannières du Poirier
## Blanc, lits de pierre des Éveillés, voiles de torchon noir, trébuchets.
## Accès : jamais directement, mais par `Sprites.prop(...)` et `Sprites.tile_image(...)`, qui
## s'adressent à PropPainter et TilePainter, lesquels renvoient ici pour les noms `gou_*`.
## Densité : 24 pixels par unité monde.

const PA = preload("res://src/gfx/pixel_art.gd")
const TP = preload("res://src/gfx/tile_painter.gd")
const PP = preload("res://src/gfx/prop_painter.gd")
const RP = preload("res://src/gfx/rider_painter.gd")
const T := 48

const INK := Color("#1d1a2b")
const STONE := Color("#f0e9d8")
const STONE_L := Color("#fffaf0")
const STONE_D := Color("#b8ae98")
const SLATE := Color("#3c4658")
const SLATE_L := Color("#5a6a82")
const NAVY := Color("#27365e")
const GOLD := Color("#e8c050")
const WOOD := Color("#8a6a3c")
const WOOD_D := Color("#5a4226")
const GHOST := Color("#8adcb4")
const SOOT := Color("#26232e")

const TILES: Array[String] = ["gou_pave", "gou_dalle", "gou_marbre", "gou_rempart", "gou_mur", "gou_herbe", "gou_boue",
		"gou_veille", "gou_mur_veille", "gou_quai", "gou_ardoise", "gou_marche", "gou_roche"]

## Décors-sprites : nom -> nombre de variantes.
const PROP_VARIANTS := {
	"gou_creneau": 1, "gou_banniere": 2, "gou_trebuchet": 1, "gou_poirier": 1, "gou_lit_pierre": 2, "gou_voile": 2,
	"gou_baril": 1, "gou_boulets": 1, "gou_fontaine": 1, "gou_statue": 1, "gou_echelle": 1, "gou_etal": 2,
	"gou_pieux": 1, "gou_tente": 2, "gou_brasier": 1, "gou_ancre": 1,
	# habillage des rues de Minas Tartine (objet `gou_deco`)
	"gou_charrette": 2, "gou_pots": 3, "gou_fromages": 1, "gou_caisses": 1, "gou_banc": 1, "gou_lunette": 1, "gou_panneau": 1,
	"gou_lampadaire": 1, "gou_tonneaux": 1, "gou_linge": 2, "gou_buisson": 1,
}


static func has_tile(kind: String) -> bool:
	return TILES.has(kind)


static func has_prop(kind: String) -> bool:
	return PROP_VARIANTS.has(kind)


static func paint_tile(kind: String) -> Image:
	match kind:
		"gou_pave": return TP._stones(["#ece3ce", "#e2d8c0", "#f2ebdb", "#dbd0b6"], Color("#a89e86"), 16, 12)
		"gou_dalle": return _slabs()
		"gou_marbre": return _marble()
		"gou_rempart": return _ashlar(false)
		"gou_mur": return _ashlar(true)
		"gou_herbe": return RP._noise(["#7e8a46", "#6e7a3c", "#8a9650", "#5e6a34"], 1601, 56, Color("#b0b86c"))
		"gou_boue": return _mud()
		"gou_veille": return _vigil_floor()
		"gou_mur_veille": return _vigil_wall()
		"gou_quai": return _quay()
		"gou_ardoise": return _slate()
		"gou_marche": return _steps()
		"gou_roche": return _spur()
	var img := PA.new_image(T, T)
	img.fill(Color.MAGENTA)
	return img


static func paint_prop(kind: String, v: int) -> Image:
	match kind:
		"gou_creneau": return _merlons()
		"gou_banniere": return _banner(v)
		"gou_trebuchet": return _trebuchet()
		"gou_poirier": return _pear_tree()
		"gou_lit_pierre": return _stone_bunk(v)
		"gou_voile": return _sail(v)
		"gou_baril": return _barrel()
		"gou_boulets": return _loaves()
		"gou_fontaine": return _fountain()
		"gou_statue": return _statue()
		"gou_echelle": return _ladder()
		"gou_etal": return _stall(v)
		"gou_pieux": return _stakes()
		"gou_tente": return _tent(v)
		"gou_brasier": return _brazier()
		"gou_ancre": return _anchor()
		"gou_charrette": return _cart(v)
		"gou_pots": return _pots(v)
		"gou_fromages": return _cheeses()
		"gou_caisses": return _crates()
		"gou_banc": return _bench()
		"gou_lunette": return _telescope()
		"gou_panneau": return _signpost()
		"gou_lampadaire": return _lamppost()
		"gou_tonneaux": return _barrels()
		"gou_linge": return _washing(v)
		"gou_buisson": return _topiary()
	var img := PA.new_image(16, 16)
	img.fill(Color.MAGENTA)
	return img


# ------------------------------------------------------------------- tuiles

static func _slabs() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#c4baa4"))
	for r in 2:
		for c in 2:
			var off := 0 if r == 0 else 6
			var tone := PA.shade(Color("#f6f0e2"), (PA.rnd(c, r, 1611) - 0.5) * 0.08)
			var xs := posmod(c * 24 + off, T)
			PA.rect(img, xs + 1, r * 24 + 1, 22, 22, tone)
			PA.rect(img, xs + 1, r * 24 + 1, 22, 1, PA.shade(tone, 0.14))
			PA.rect(img, xs + 1, r * 24 + 22, 22, 1, PA.shade(tone, -0.14))
	RP._specks_in(img, 1612, 30, Color("#f6f3ea"))
	RP._specks_in(img, 1613, 14, Color("#b8b4a8"))
	return img


## Marches de pierre claire : quatre contremarches par case, nez éclairé, ombre dessous.
static func _steps() -> Image:
	var img := PA.new_image(T, T)
	for r in 4:
		var y0 := r * 12
		var tone := PA.shade(Color("#f6f0e2"), (PA.rnd(r, 7, 1701) - 0.5) * 0.06)
		PA.rect(img, 0, y0, T, 12, tone)
		PA.rect(img, 0, y0, T, 2, Color("#fffcf2"))
		PA.rect(img, 0, y0 + 9, T, 3, Color("#c8bea8"))
		PA.rect(img, 0, y0 + 11, T, 1, Color("#a89e88"))
	RP._specks_in(img, 1702, 10, Color("#fffaf0"))
	return img


## Éperon de roche sous la tour blanche : strates beige gris et fissures.
static func _spur() -> Image:
	var img := RP._noise(["#8a8272", "#7c7464", "#968e7c", "#6e6656"], 1711, 52, Color("#b4ac98"))
	for i in 7:
		var y := 4 + i * 7
		for x in T:
			if int(PA.rnd(x / 5, i, 1712) * 5.0) != 0:
				RP._wrap_px(img, x, y + int(sin(float(x) * 0.3 + i) * 1.5), Color("#5e5646"))
	return img


static func _marble() -> Image:
	var img := PA.new_image(T, T)
	for y in T:
		for x in T:
			var chk := ((x / 24) + (y / 24)) % 2
			img.set_pixel(x, y, Color("#f8f3e8") if chk == 0 else Color("#eee7d8"))
	for i in 5:
		var x := int(PA.rnd(i, 3, 1621) * T)
		var y := int(PA.rnd(i, 4, 1621) * T)
		for k in 14:
			RP._wrap_px(img, x + k, y + int(k * 0.6 + sin(float(k + i)) * 1.5), Color("#c4c8d4"))
	PA.rect(img, 0, 0, T, 1, Color("#c4baa4"))
	PA.rect(img, 0, 24, T, 1, Color("#d8d0bc"))
	PA.rect(img, 0, 0, 1, T, Color("#c4baa4"))
	PA.rect(img, 24, 0, 1, T, Color("#d8d0bc"))
	return img


## Pierre de taille blanche. `wall` : paroi d'intérieur (frise bleue, filet d'or) ; sinon
## talus et paroi de relief (mousse au pied).
static func _ashlar(wall: bool) -> Image:
	var h := 72 if wall else T
	var img := PA.new_image(T, h)
	img.fill(Color("#aa9f88"))
	var rows := 0
	for y in range(1, h - 2, 12):
		var off := 12 if rows % 2 == 1 else 0
		for x in range(-24, T + 24, 24):
			var tone := PA.shade(Color("#eee6d2"), (PA.rnd(x + off, y, 1631) - 0.5) * 0.12)
			PA.rect(img, x + off + 1, y, 22, 11, tone)
			PA.rect(img, x + off + 1, y, 22, 1, PA.shade(tone, 0.16))
			PA.rect(img, x + off + 1, y + 10, 22, 1, PA.shade(tone, -0.18))
		rows += 1
	if wall:
		PA.rect(img, 0, 0, T, 7, NAVY)
		PA.rect(img, 0, 7, T, 1, GOLD)
		for x in range(4, T, 12):
			PA.rect(img, x, 2, 4, 3, PA.shade(NAVY, 0.3))
		PA.rect(img, 0, h - 8, T, 8, Color("#d8d0bc"))
		PA.rect(img, 0, h - 8, T, 1, STONE_L)
	else:
		for i in 14:   # mousse au pied
			var x := int(PA.rnd(i, 1, 1632) * T)
			PA.rect(img, x, T - 4 - int(PA.rnd(i, 2, 1632) * 3), 3 + i % 3, 5, Color("#6a8a58"))
	return img


static func _mud() -> Image:
	var img := RP._noise(["#5e4a34", "#6a5640", "#4e3c2a", "#76624a"], 1641, 50, Color("#8a7458"))
	for y in [10, 14, 34, 38]:
		for x in T:
			if (x + y) % 5 != 0:
				RP._wrap_px(img, x, y, Color("#3a2c1e"))
	return img


static func _vigil_floor() -> Image:
	var img := TP._stones(["#4a5a58", "#3e4e4c", "#566866", "#344240"], Color("#1c2624"), 16, 12)
	for i in 5:   # empreintes de pas pâles, usées par les veilles
		var x := 6 + (i * 11) % 40
		var y := 8 + (i * 17) % 36
		PA.ellipse(img, float(x), float(y), 2.0, 3.0, Color("#6a8a82"))
		PA.ellipse(img, float(x + 4), float(y + 4), 2.0, 3.0, Color("#6a8a82"))
	RP._specks_in(img, 1651, 10, Color("#8adcb4"))
	return img


## Paroi du Sentier : lits de pierre superposés, creusés dans le mur.
static func _vigil_wall() -> Image:
	var img := PA.new_image(T, 72)
	img.fill(Color("#2a3634"))
	for y in range(2, 62, 20):
		PA.rect(img, 3, y, 42, 17, Color("#141c1b"))        # alcôve
		PA.rect(img, 3, y, 42, 1, Color("#0c1211"))
		PA.rect(img, 5, y + 11, 38, 5, Color("#5a6a68"))    # dalle du lit
		PA.rect(img, 5, y + 11, 38, 1, Color("#8aa09c"))
		PA.rect(img, 7, y + 8, 12, 3, Color("#6a7c78"))      # oreiller de pierre
		PA.rect(img, 30, y + 6, 12, 5, Color("#3e4e4c"))     # couverture de pierre
	PA.rect(img, 0, 62, T, 10, Color("#1c2624"))
	PA.rect(img, 0, 62, T, 1, Color("#4a5a58"))
	RP._specks_in(img, 1661, 8, Color("#8adcb4"))
	return img


static func _quay() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#4a3c2c"))
	for r in 4:
		var y0 := r * 12
		var tone := PA.shade(Color("#7a6a58"), (PA.rnd(r, 1, 1671) - 0.5) * 0.16)
		PA.rect(img, 0, y0 + 1, T, 10, tone)
		PA.rect(img, 0, y0 + 1, T, 1, PA.shade(tone, 0.16))
		PA.rect(img, 4 + r * 9 % 30, y0 + 2, 1, 8, Color("#4a3c2c"))
		PA.px(img, 3, y0 + 5, Color("#2a2018"))
		PA.px(img, 44, y0 + 5, Color("#2a2018"))
	RP._specks_in(img, 1672, 40, Color("#f2f0e8"))   # croûte de sel
	RP._specks_in(img, 1673, 12, Color("#c8d4d8"))
	return img


static func _slate() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#2a3242"))
	for r in 4:
		var off := 6 if r % 2 == 1 else 0
		for c in range(-1, 4):
			var tone := PA.shade(SLATE, (PA.rnd(c, r, 1681) - 0.5) * 0.18)
			PA.rect(img, c * 12 + off + 1, r * 12 + 1, 11, 10, tone)
			PA.rect(img, c * 12 + off + 1, r * 12 + 1, 11, 1, PA.shade(tone, 0.2))
			PA.rect(img, c * 12 + off + 1, r * 12 + 10, 11, 1, PA.shade(tone, -0.25))
	return img


# ------------------------------------------------------------- façade de maison

## Façade peinte d'une maison blanche : pierre de taille, bandeau à chaque étage, fenêtres
## cintrées, porte. Renvoie {albedo, emission} (l'émission ne garde que les fenêtres allumées).
static func facade(wd: float, ht: float, door_x: float, windows: Array, lit: bool, open: bool) -> Dictionary:
	var w := maxi(24, int(round(wd * 24.0)))
	var h := maxi(24, int(round(ht * 24.0)))
	var img := PA.new_image(w, h)
	var emi := PA.new_image(w, h)
	img.fill(Color("#aa9f88"))
	var rows := 0
	for y in range(1, h - 2, 12):
		var off := 12 if rows % 2 == 1 else 0
		for x in range(-24, w + 24, 24):
			var tone := PA.shade(Color("#efe8d6"), (PA.rnd(x + off, y, 1691) - 0.5) * 0.1)
			PA.rect(img, x + off + 1, y, 22, 11, tone)
			PA.rect(img, x + off + 1, y, 22, 1, PA.shade(tone, 0.16))
			PA.rect(img, x + off + 1, y + 10, 22, 1, PA.shade(tone, -0.16))
		rows += 1
	if h > 80:   # bandeau d'étage
		PA.rect(img, 0, h / 2 - 3, w, 4, Color("#d8d0bc"))
		PA.rect(img, 0, h / 2 - 3, w, 1, STONE_L)
	PA.rect(img, 0, h - 5, w, 5, Color("#c8bea8"))
	PA.rect(img, 0, h - 5, w, 1, STONE_L)
	var sill := h - 40 if h < 90 else h - 40
	var upper := h / 2 - 34
	var spots: Array = []
	for wx: Variant in windows:
		spots.append([int(round(float(wx) * 24.0)), sill])
		if h > 90:
			spots.append([int(round(float(wx) * 24.0)), upper])
	for s: Array in spots:
		var x := int(s[0]) - 6
		var y := int(s[1])
		if y < 4:
			continue
		PA.rect(img, x - 1, y - 1, 14, 22, Color("#6a665a"))
		PA.rect(img, x, y, 12, 20, Color("#1c2234"))
		PA.ellipse(img, float(x + 6), float(y), 6.0, 5.0, Color("#1c2234"))
		PA.rect(img, x + 5, y - 4, 2, 24, Color("#6a665a"))
		PA.rect(img, x - 2, y + 20, 16, 2, Color("#c8c4b8"))
		if lit:
			PA.rect(img, x + 1, y + 2, 4, 17, Color("#f6d68a"))
			PA.rect(img, x + 7, y + 2, 4, 17, Color("#f6d68a"))
			PA.rect(emi, x + 1, y + 2, 4, 17, Color("#ffcf70"))
			PA.rect(emi, x + 7, y + 2, 4, 17, Color("#ffcf70"))
	if door_x >= 0.0:
		var dx := int(round(door_x * 24.0)) - 11
		PA.rect(img, dx - 2, h - 52, 26, 49, Color("#6a665a"))
		PA.rect(img, dx, h - 50, 22, 45, Color("#14101a") if open else Color("#3a3c58"))
		PA.ellipse(img, float(dx + 11), float(h - 50), 11.0, 7.0, Color("#14101a") if open else Color("#3a3c58"))
		if not open:
			PA.rect(img, dx + 10, h - 50, 2, 45, Color("#1c2234"))
			PA.rect(img, dx + 4, h - 28, 3, 3, GOLD)
			PA.rect(img, dx + 15, h - 28, 3, 3, GOLD)
	return {"albedo": img, "emission": emi}


# ---------------------------------------------------------------------- décors

static func _merlons() -> Image:
	var img := PA.new_image(52, 34)
	PA.rect(img, 2, 18, 48, 14, STONE)
	for i in 4:
		PA.rect(img, 3 + i * 12, 6, 8, 13, STONE)
		PA.rect(img, 3 + i * 12, 6, 8, 2, STONE_L)
	PA.rect(img, 2, 18, 48, 2, STONE_L)
	PA.rect(img, 2, 30, 48, 2, STONE_D)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 52, 34), INK)
	return img


static func _banner(v: int) -> Image:
	var img := PA.new_image(34, 84)
	PA.rect(img, 15, 4, 3, 78, WOOD_D)
	PA.rect(img, 15, 4, 1, 78, WOOD)
	PA.rect(img, 6, 6, 22, 2, GOLD)
	var cloth := NAVY if v == 0 else Color("#2a2a32")
	PP._poly(img, [Vector2(7, 8), Vector2(27, 8), Vector2(27, 52), Vector2(17, 60), Vector2(7, 52)], cloth)
	PP._poly(img, [Vector2(7, 8), Vector2(27, 8), Vector2(27, 12), Vector2(7, 12)], PA.shade(cloth, 0.2))
	PA.rect(img, 16, 34, 2, 12, Color("#f4f0e4"))   # le Poirier Blanc, tronc et couronne
	PA.ellipse(img, 17.0, 28.0, 6.0, 6.0, Color("#f4f0e4"))
	PA.ellipse(img, 13.0, 31.0, 3.0, 3.0, Color("#f4f0e4"))
	PA.ellipse(img, 21.0, 31.0, 3.0, 3.0, Color("#f4f0e4"))
	PA.rect(img, 4, 2, 26, 4, GOLD)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 34, 84), INK)
	return img


static func _trebuchet() -> Image:
	var img := PA.new_image(104, 96)
	PA.rect(img, 10, 84, 84, 8, WOOD_D)
	PP._poly(img, [Vector2(20, 84), Vector2(46, 28), Vector2(54, 28), Vector2(34, 84)], WOOD)
	PP._poly(img, [Vector2(84, 84), Vector2(58, 28), Vector2(50, 28), Vector2(70, 84)], WOOD)
	PA.line(img, 50, 30, 10, 12, WOOD_D)
	PA.line(img, 51, 30, 11, 12, WOOD_D)
	PA.line(img, 50, 30, 84, 62, WOOD_D)
	PA.line(img, 51, 30, 85, 62, WOOD_D)
	PA.rect(img, 78, 58, 14, 16, Color("#5a5a64"))   # contrepoids
	PA.rect(img, 78, 58, 14, 2, Color("#8a8a96"))
	PA.line(img, 10, 12, 4, 30, Color("#8a7a5a"))
	PA.ellipse(img, 5.0, 33.0, 5.0, 5.0, Color("#c89a54"))   # boulet de pain
	PA.ellipse(img, 4.0, 31.0, 2.0, 1.5, Color("#e8c47a"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 104, 96), INK)
	return img


static func _pear_tree() -> Image:
	var img := PA.new_image(116, 150)
	PP._poly(img, [Vector2(50, 148), Vector2(54, 80), Vector2(64, 80), Vector2(70, 148)], Color("#b8b0a0"))
	PP._poly(img, [Vector2(50, 148), Vector2(54, 80), Vector2(58, 80), Vector2(56, 148)], Color("#dcd6c8"))
	PA.line(img, 58, 84, 26, 56, Color("#a8a090"))
	PA.line(img, 59, 84, 27, 56, Color("#a8a090"))
	PA.line(img, 60, 80, 92, 50, Color("#a8a090"))
	PA.line(img, 61, 80, 93, 50, Color("#a8a090"))
	PA.line(img, 58, 80, 60, 34, Color("#a8a090"))
	for k in 34:   # fleurs blanches
		var a := PA.rnd(k, 1, 1701) * TAU
		var r := 10.0 + PA.rnd(k, 2, 1701) * 38.0
		var cx := 58.0 + cos(a) * r * 1.1
		var cy := 46.0 + sin(a) * r * 0.62
		PA.ellipse(img, cx, cy, 5.0, 4.0, Color("#f6f2ea") if k % 3 else Color("#fbd8e0"))
	for k in 10:   # poires pâles
		PA.ellipse(img, 22.0 + k * 8.0, 62.0 + (k % 3) * 8.0, 2.4, 3.2, Color("#e8e0a0"))
	PA.rect(img, 60, 120, 2, 28, Color("#7a5632"))   # le tuteur, un peu de travers
	PA.rect(img, 57, 118, 8, 3, Color("#7a5632"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 116, 150), INK)
	return img


static func _stone_bunk(v: int) -> Image:
	var img := PA.new_image(70, 34)
	PA.rect(img, 3, 14, 64, 16, Color("#5a6a68"))
	PA.rect(img, 3, 14, 64, 3, Color("#8aa09c"))
	PA.rect(img, 6, 8, 16, 7, Color("#6a7c78"))
	PA.rect(img, 30, 10, 34, 8, Color("#3e4e4c") if v == 0 else Color("#48585a"))
	PA.rect(img, 5, 29, 8, 4, Color("#2a3634"))
	PA.rect(img, 56, 29, 8, 4, Color("#2a3634"))
	for i in 3:
		PA.px(img, 36 + i * 8, 13, Color("#8adcb4"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 70, 34), INK)
	return img


## Voile de torchon noir : un grand torchon à carreaux sombres, tendu sur un mât.
static func _sail(v: int) -> Image:
	var img := PA.new_image(62, 120)
	PA.rect(img, 29, 2, 4, 114, WOOD_D)
	PA.rect(img, 29, 2, 1, 114, WOOD)
	PA.rect(img, 8, 14, 46, 3, WOOD)
	PP._poly(img, [Vector2(9, 18), Vector2(53, 18), Vector2(49, 72), Vector2(13, 76)], Color("#26262e"))
	for y in range(20, 74, 8):   # carreaux de torchon
		PA.rect(img, 11, y, 40, 2, Color("#3a3a4a"))
	for x in range(14, 50, 8):
		PA.rect(img, x, 19, 2, 54, Color("#3a3a4a"))
	if v == 1:
		PA.rect(img, 20, 30, 20, 14, Color("#e8e4d8"))     # pavillon : une assiette sur une serviette
		PA.ellipse(img, 30.0, 37.0, 6.0, 5.0, Color("#c8c4b8"))
	PA.rect(img, 12, 96, 38, 12, Color("#5a4226"))
	PA.rect(img, 12, 96, 38, 2, Color("#8a6a3c"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 62, 120), INK)
	return img


static func _barrel() -> Image:
	var img := PA.new_image(30, 36)
	PA.ellipse(img, 15.0, 20.0, 12.0, 14.0, WOOD)
	PA.rect(img, 3, 10, 24, 2, Color("#3a3a44"))
	PA.rect(img, 3, 26, 24, 2, Color("#3a3a44"))
	PA.ellipse(img, 15.0, 8.0, 10.0, 4.0, Color("#f2f0e8"))   # sel
	PA.ellipse(img, 13.0, 7.0, 4.0, 1.5, Color("#ffffff"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 30, 36), INK)
	return img


static func _loaves() -> Image:
	var img := PA.new_image(36, 28)
	for k in 6:
		var x := 8.0 + (k % 3) * 10.0 + (k / 3) * 5.0
		var y := 20.0 - (k / 3) * 9.0
		PA.ellipse(img, x, y, 6.5, 5.5, Color("#b8803c"))
		PA.ellipse(img, x - 1.5, y - 1.5, 3.5, 2.5, Color("#dca458"))
		PA.px(img, int(x) + 1, int(y) - 1, Color("#7a5226"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 36, 28), INK)
	return img


static func _fountain() -> Image:
	var img := PA.new_image(62, 56)
	PA.ellipse(img, 31.0, 44.0, 28.0, 10.0, STONE)
	PA.ellipse(img, 31.0, 42.0, 24.0, 8.0, Color("#5a98b0"))
	PA.ellipse(img, 29.0, 41.0, 10.0, 3.0, Color("#a8d8e8"))
	PA.rect(img, 27, 14, 8, 28, STONE)
	PA.rect(img, 27, 14, 2, 28, STONE_L)
	PA.ellipse(img, 31.0, 14.0, 12.0, 4.0, STONE)
	PA.ellipse(img, 31.0, 13.0, 8.0, 2.5, Color("#7ab8d0"))
	for k in 5:
		PA.px(img, 31 + (k - 2) * 2, 8 - k % 2, Color("#d8f0f8"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 62, 56), INK)
	return img


static func _statue() -> Image:
	var img := PA.new_image(40, 80)
	PA.rect(img, 6, 62, 28, 16, STONE_D)
	PA.rect(img, 6, 62, 28, 2, STONE)
	PP._poly(img, [Vector2(12, 62), Vector2(14, 28), Vector2(26, 28), Vector2(28, 62)], Color("#c8c4b8"))
	PA.ellipse(img, 20.0, 20.0, 6.0, 7.0, Color("#d8d4c8"))
	PA.rect(img, 14, 10, 12, 4, Color("#b8b4a8"))   # couronne
	PA.line(img, 28, 36, 34, 14, Color("#b8b4a8"))   # sceptre levé
	PA.ellipse(img, 34.0, 12.0, 3.0, 3.0, GOLD)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 40, 80), INK)
	return img


static func _ladder() -> Image:
	var img := PA.new_image(26, 68)
	PA.line(img, 4, 66, 8, 2, WOOD)
	PA.line(img, 18, 66, 22, 2, WOOD)
	for y in range(8, 64, 9):
		PA.rect(img, 5 + (64 - y) / 16, y, 15, 2, WOOD_D)
	PA.outline(img, Rect2i(0, 0, 26, 68), INK)
	return img


static func _stall(v: int) -> Image:
	var img := PA.new_image(64, 64)
	PA.rect(img, 6, 26, 3, 36, WOOD_D)
	PA.rect(img, 55, 26, 3, 36, WOOD_D)
	PA.rect(img, 6, 44, 52, 18, WOOD)
	PA.rect(img, 6, 44, 52, 2, Color("#b08a4c"))
	var a := NAVY if v == 0 else Color("#8a2a2a")
	for i in 8:   # auvent rayé
		PA.rect(img, 2 + i * 7, 12, 7, 18, a if i % 2 == 0 else Color("#f0ece0"))
	PA.rect(img, 2, 30, 56, 2, PA.shade(a, -0.3))
	for k in 5:   # marchandises : pains, fromages
		PA.ellipse(img, 14.0 + k * 9.0, 41.0, 4.0, 3.0, Color("#d8a858") if v == 0 else Color("#e8d070"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 64, 64), INK)
	return img


static func _stakes() -> Image:
	var img := PA.new_image(48, 36)
	for k in 6:
		var x := 4 + k * 7
		var top := 6 + (k % 2) * 4
		PP._poly(img, [Vector2(x, 34), Vector2(x + 2, top), Vector2(x + 4, 34)], WOOD)
		PA.px(img, x + 2, top, Color("#d8c89a"))
	PA.rect(img, 2, 26, 44, 2, WOOD_D)
	PA.outline(img, Rect2i(0, 0, 48, 36), INK)
	return img


static func _tent(v: int) -> Image:
	var img := PA.new_image(70, 52)
	var cloth := Color("#c8c0a8") if v == 0 else Color("#8a9a6a")
	PP._poly(img, [Vector2(4, 48), Vector2(35, 6), Vector2(66, 48)], cloth)
	PP._poly(img, [Vector2(4, 48), Vector2(35, 6), Vector2(36, 48)], PA.shade(cloth, 0.14))
	PP._poly(img, [Vector2(28, 48), Vector2(35, 26), Vector2(42, 48)], Color("#2a2a32"))
	PA.rect(img, 34, 0, 2, 8, WOOD_D)
	PA.rect(img, 36, 0, 8, 4, NAVY)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 70, 52), INK)
	return img


static func _brazier() -> Image:
	var img := PA.new_image(32, 46)
	PA.line(img, 7, 44, 12, 22, Color("#3a3a44"))
	PA.line(img, 25, 44, 20, 22, Color("#3a3a44"))
	PP._poly(img, [Vector2(5, 20), Vector2(27, 20), Vector2(22, 28), Vector2(10, 28)], Color("#4a4a56"))
	PP._poly(img, [Vector2(9, 20), Vector2(16, 4), Vector2(23, 20)], Color("#ff8a30"))
	PP._poly(img, [Vector2(12, 20), Vector2(16, 10), Vector2(20, 20)], Color("#ffd870"))
	PA.outline(img, Rect2i(0, 0, 32, 46), INK)
	return img


static func _anchor() -> Image:
	var img := PA.new_image(34, 44)
	PA.rect(img, 15, 4, 4, 32, Color("#4a4a56"))
	PA.rect(img, 8, 10, 18, 3, Color("#4a4a56"))
	PA.ellipse(img, 17.0, 5.0, 4.0, 4.0, Color("#4a4a56"))
	PA.ellipse(img, 17.0, 5.0, 2.0, 2.0, Color(0, 0, 0, 0))
	PP._poly(img, [Vector2(4, 28), Vector2(17, 42), Vector2(30, 28), Vector2(26, 28), Vector2(17, 36), Vector2(8, 28)], Color("#4a4a56"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 34, 44), INK)
	return img


## Étendard de la Tour Blanche : toile bleu nuit, bordure d'or, le champignon blanc du Poirier,
## deux queues en bas ; le bord gauche touche le mât. 128 x 80 pixels.
static func paint_standard() -> Image:
	var w := 128
	var h := 80
	var img := PA.new_image(w, h)
	for x in w:
		var tail := 0
		if x > w - 34:
			tail = int(float(x - (w - 34)) * 0.5)
		for y in h:
			var tri_cut := false
			if x > w - 34 and y > h - 6 - tail * 1:
				tri_cut = true
			if x > w - 34 and absf(float(y) - float(h) * 0.5) < float(x - (w - 34)) * 0.6 and y > h / 2:
				tri_cut = true
			if tri_cut:
				continue
			var c := NAVY.lerp(Color("#3c4f82"), 0.2 + 0.2 * sin(float(x) * 0.11 + float(y) * 0.05))
			if y < 5 or y > h - 6 or x < 4:
				c = GOLD if (y < 3 or y > h - 4 or x < 2) else Color("#b8903a")
			img.set_pixel(x, y, c)
	var cx := 52
	PA.ellipse(img, float(cx), 36.0, 26.0, 20.0, Color("#f4f0e4"))
	PA.rect(img, cx - 27, 36, 55, 3, Color("#d8d2c0"))
	PA.rect(img, cx - 8, 40, 17, 26, Color("#f4f0e4"))
	PA.rect(img, cx + 4, 40, 5, 26, Color("#d8d2c0"))
	PA.ellipse(img, float(cx - 9), 30.0, 5.0, 3.0, Color("#ffffff"))
	for k in 3:
		PA.px(img, cx + 12 + k * 3, 26 + k * 2, Color("#d8d2c0"))
	return img


# ------------------------------------------------- habillage des rues de Minas Tartine

## Charrette à bras : plateau, deux roues, ridelles, chargement de sacs de farine (0) ou de pains (1).
static func _cart(v: int) -> Image:
	var img := PA.new_image(72, 52)
	PA.rect(img, 6, 30, 52, 4, WOOD)   # plateau
	PA.rect(img, 6, 30, 52, 1, Color("#b08a4c"))
	PA.rect(img, 6, 22, 2, 9, WOOD_D)
	PA.rect(img, 56, 22, 2, 9, WOOD_D)
	PA.rect(img, 6, 22, 52, 2, WOOD)
	PA.line(img, 58, 31, 70, 38, WOOD_D)   # brancards
	PA.line(img, 58, 33, 70, 40, WOOD_D)
	if v == 0:
		for k in 4:   # sacs de farine
			var x := 12.0 + float(k) * 11.0
			PA.ellipse(img, x, 20.0 - float(k % 2) * 2.0, 6.0, 7.0, Color("#e8e0cc"))
			PA.rect(img, int(x) - 3, 12 - (k % 2) * 2, 6, 2, Color("#c8b890"))
			PA.px(img, int(x) + 2, 17, Color("#fffaf0"))
	else:
		for k in 5:   # miches
			var x2 := 11.0 + float(k) * 9.0
			PA.ellipse(img, x2, 22.0 - float(k % 2) * 3.0, 5.5, 4.5, Color("#c8903c"))
			PA.ellipse(img, x2 - 1.0, 21.0 - float(k % 2) * 3.0, 3.0, 2.0, Color("#e8b862"))
	for wx in [16, 46]:   # roues
		PA.ellipse(img, float(wx), 38.0, 10.0, 10.0, WOOD_D)
		PA.ellipse(img, float(wx), 38.0, 7.0, 7.0, Color(0, 0, 0, 0))
		PA.ellipse(img, float(wx), 38.0, 6.0, 6.0, Color("#a88450"))
		PA.ellipse(img, float(wx), 38.0, 2.0, 2.0, WOOD_D)
		PA.line(img, wx - 6, 38, wx + 6, 38, WOOD_D)
		PA.line(img, wx, 32, wx, 44, WOOD_D)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 72, 52), INK)
	return img


## Pots de terre cuite fleuris : géraniums rouges (0), lavande (1), pensées jaunes (2).
static func _pots(v: int) -> Image:
	var img := PA.new_image(44, 34)
	var bloom: Array = [Color("#d84a4a"), Color("#9a7ad0"), Color("#f0c84a")]
	for k in 3:
		var x := 8 + k * 13
		var hgt := 12 - (k % 2) * 3
		PP._poly(img, [Vector2(x - 5, 33 - hgt), Vector2(x + 5, 33 - hgt), Vector2(x + 4, 33), Vector2(x - 4, 33)], Color("#b8603a"))
		PA.rect(img, x - 6, 31 - hgt, 12, 3, Color("#d07a4a"))
		PA.ellipse(img, float(x), float(28 - hgt), 7.0, 5.0, Color("#4f8a42"))
		for j in 5:
			PA.px(img, x - 4 + j * 2, 25 - hgt - (j % 2) * 2, bloom[v])
			PA.px(img, x - 3 + j * 2, 26 - hgt - (j % 2), PA.shade(bloom[v], 0.2))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 44, 34), INK)
	return img


## Pile de meules de fromage : croûte dorée, entaille pâle, une meule entamée.
static func _cheeses() -> Image:
	var img := PA.new_image(40, 38)
	for lvl in 3:
		var n := 3 - lvl
		for k in n:
			var x := 20.0 + (float(k) - float(n - 1) * 0.5) * 15.0
			var y := 31.0 - float(lvl) * 10.0
			PA.ellipse(img, x, y, 9.0, 5.0, Color("#c8963c"))
			PA.rect(img, int(x) - 9, int(y) - 2, 18, 6, Color("#d8a84c"))
			PA.ellipse(img, x, y - 3.0, 9.0, 4.0, Color("#f0cc6a"))
			PA.px(img, int(x) - 3, int(y) - 4, Color("#fff0a8"))
			PA.px(img, int(x) + 3, int(y) - 3, Color("#b88a30"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 40, 38), INK)
	return img


## Piles de caisses de poires et de pommes vertes.
static func _crates() -> Image:
	var img := PA.new_image(44, 42)
	for b in [[2, 22, 22, 18], [22, 22, 20, 18], [10, 6, 22, 16]]:
		PA.rect(img, b[0], b[1], b[2], b[3], WOOD)
		PA.rect(img, b[0], b[1], b[2], 2, Color("#b08a4c"))
		PA.rect(img, b[0], b[1] + b[3] / 2, b[2], 1, WOOD_D)
		PA.rect(img, b[0] + 2, b[1] - 3, b[2] - 4, 4, Color("#8ab84a"))
		for j in 4:
			PA.ellipse(img, float(b[0] + 5 + j * 4), float(b[1] - 3), 2.5, 2.2, Color("#a8d060") if j % 2 == 0 else Color("#e8d868"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 44, 42), INK)
	return img


## Banc de pierre blanche à pieds pleins.
static func _bench() -> Image:
	var img := PA.new_image(52, 28)
	PA.rect(img, 4, 8, 44, 6, STONE)
	PA.rect(img, 4, 8, 44, 2, STONE_L)
	PA.rect(img, 6, 14, 7, 12, STONE_D)
	PA.rect(img, 39, 14, 7, 12, STONE_D)
	PA.rect(img, 6, 14, 2, 12, STONE)
	PA.rect(img, 39, 14, 2, 12, STONE)
	PA.rect(img, 4, 6, 44, 2, Color("#6a7a52"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 52, 28), INK)
	return img


## Lunette d'observation en laiton sur trépied, braquée vers la plaine.
static func _telescope() -> Image:
	var img := PA.new_image(34, 48)
	PA.line(img, 17, 22, 7, 46, WOOD_D)
	PA.line(img, 17, 22, 27, 46, WOOD_D)
	PA.line(img, 17, 22, 17, 46, WOOD)
	PP._poly(img, [Vector2(6, 22), Vector2(10, 16), Vector2(27, 6), Vector2(30, 10), Vector2(12, 24)], Color("#c8a040"))
	PP._poly(img, [Vector2(10, 16), Vector2(27, 6), Vector2(28, 8), Vector2(11, 18)], Color("#f0d070"))
	PA.rect(img, 27, 4, 5, 7, Color("#8a6a28"))
	PA.ellipse(img, 8.0, 21.0, 4.0, 4.0, Color("#3a3a44"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 34, 48), INK)
	return img


## Panneau de bois sur poteau : planche peinte du champignon, deux flèches.
static func _signpost() -> Image:
	var img := PA.new_image(36, 58)
	PA.rect(img, 16, 6, 4, 50, WOOD_D)
	PA.rect(img, 4, 8, 28, 16, WOOD)
	PA.rect(img, 4, 8, 28, 2, Color("#b08a4c"))
	PA.ellipse(img, 18.0, 15.0, 6.0, 4.0, Color("#f4f0e4"))
	PA.rect(img, 16, 17, 4, 5, Color("#f4f0e4"))
	PP._poly(img, [Vector2(6, 30), Vector2(26, 30), Vector2(32, 34), Vector2(26, 38), Vector2(6, 38)], Color("#a88450"))
	for k in 4:
		PA.rect(img, 9 + k * 5, 33, 3, 1, WOOD_D)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 36, 58), INK)
	return img


## Lampadaire de fer forgé : lanterne de verre allumée, console ouvragée.
static func _lamppost() -> Image:
	var img := PA.new_image(24, 70)
	PA.rect(img, 10, 22, 3, 46, Color("#2e2e3a"))
	PA.rect(img, 6, 64, 11, 4, Color("#3a3a46"))
	PA.rect(img, 8, 58, 7, 6, Color("#34343f"))
	PA.line(img, 11, 26, 4, 22, Color("#2e2e3a"))
	PA.line(img, 11, 26, 18, 22, Color("#2e2e3a"))
	PP._poly(img, [Vector2(6, 4), Vector2(17, 4), Vector2(19, 10), Vector2(4, 10)], Color("#2e2e3a"))
	PA.rect(img, 6, 10, 11, 13, Color("#ffe29a"))
	PA.rect(img, 8, 12, 7, 9, Color("#fff6c8"))
	PA.rect(img, 5, 22, 13, 2, Color("#2e2e3a"))
	PA.rect(img, 11, 0, 1, 5, Color("#2e2e3a"))
	PA.outline(img, Rect2i(0, 0, 24, 70), INK)
	return img


## Trois tonneaux cerclés de fer : deux debout, un couché.
static func _barrels() -> Image:
	var img := PA.new_image(52, 40)
	for pos in [[14, 24], [34, 24]]:
		PA.ellipse(img, float(pos[0]), float(pos[1]), 10.0, 13.0, WOOD)
		PA.rect(img, pos[0] - 10, pos[1] - 7, 20, 2, Color("#3a3a44"))
		PA.rect(img, pos[0] - 10, pos[1] + 5, 20, 2, Color("#3a3a44"))
		PA.ellipse(img, float(pos[0]), float(pos[1]) - 11.0, 8.0, 3.0, Color("#a88450"))
	PA.ellipse(img, 26.0, 12.0, 11.0, 7.0, Color("#8a5a32"))
	PA.rect(img, 15, 9, 22, 2, Color("#3a3a44"))
	PA.ellipse(img, 26.0, 9.0, 8.0, 2.5, Color("#c09a5a"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 52, 40), INK)
	return img


## Linge qui sèche sur une corde tendue : draps blancs, chemises bleues (0) ou torchons rayés (1).
static func _washing(v: int) -> Image:
	var img := PA.new_image(84, 46)
	PA.rect(img, 2, 2, 2, 44, WOOD_D)
	PA.rect(img, 80, 2, 2, 44, WOOD_D)
	PA.line(img, 3, 4, 81, 7, Color("#4a3a24"))
	var cols: Array = [Color("#f4f0e4"), Color("#7a9ad0"), Color("#e8c8c0"), Color("#f4f0e4")] if v == 0 else [Color("#c85a5a"), Color("#f4f0e4"), Color("#5a7ab0"), Color("#f4f0e4")]
	for k in 4:
		var x := 8 + k * 18
		var y0 := 5 + int(float(k) * 0.9)
		var ln := 22 + (k * 5) % 9
		PA.rect(img, x, y0, 13, ln, cols[k])
		PA.rect(img, x, y0, 13, 2, PA.shade(cols[k], -0.15))
		PA.rect(img, x + 10, y0 + 2, 3, ln - 2, PA.shade(cols[k], -0.1))
		PA.px(img, x + 2, y0 + ln - 1, Color(0, 0, 0, 0))
		PA.px(img, x + 7, y0 + ln - 2, Color(0, 0, 0, 0))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 84, 46), INK)
	return img


## Buisson taillé en boule dans un bac de pierre.
static func _topiary() -> Image:
	var img := PA.new_image(36, 50)
	PA.rect(img, 6, 36, 24, 12, STONE)
	PA.rect(img, 4, 34, 28, 4, STONE_L)
	PA.rect(img, 6, 44, 24, 4, STONE_D)
	PA.rect(img, 16, 28, 4, 8, WOOD_D)
	PA.ellipse(img, 18.0, 18.0, 14.0, 14.0, Color("#3f7a40"))
	PA.ellipse(img, 20.0, 15.0, 10.0, 10.0, Color("#5c9a52"))
	PA.ellipse(img, 22.0, 11.0, 5.0, 4.0, Color("#86bc6a"))
	for j in 6:
		PA.px(img, 8 + j * 4, 12 + (j * 5) % 14, Color("#f4d85a") if j % 2 == 0 else Color("#e8887a"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 36, 50), INK)
	return img
