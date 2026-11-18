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
const STONE := Color("#d8d4c8")
const STONE_L := Color("#efece2")
const STONE_D := Color("#9a968a")
const SLATE := Color("#3c4658")
const SLATE_L := Color("#5a6a82")
const NAVY := Color("#27365e")
const GOLD := Color("#e8c050")
const WOOD := Color("#8a6a3c")
const WOOD_D := Color("#5a4226")
const GHOST := Color("#8adcb4")
const SOOT := Color("#26232e")

const TILES: Array[String] = ["gou_pave", "gou_dalle", "gou_marbre", "gou_rempart", "gou_mur", "gou_herbe", "gou_boue",
		"gou_veille", "gou_mur_veille", "gou_quai", "gou_ardoise"]

## Décors-sprites : nom -> nombre de variantes.
const PROP_VARIANTS := {
	"gou_creneau": 1, "gou_banniere": 2, "gou_trebuchet": 1, "gou_poirier": 1, "gou_lit_pierre": 2, "gou_voile": 2,
	"gou_baril": 1, "gou_boulets": 1, "gou_fontaine": 1, "gou_statue": 1, "gou_echelle": 1, "gou_etal": 2,
	"gou_pieux": 1, "gou_tente": 2, "gou_brasier": 1, "gou_ancre": 1,
}


static func has_tile(kind: String) -> bool:
	return TILES.has(kind)


static func has_prop(kind: String) -> bool:
	return PROP_VARIANTS.has(kind)


static func paint_tile(kind: String) -> Image:
	match kind:
		"gou_pave": return TP._stones(["#d8d4c8", "#cfcabd", "#e2dfd4", "#c6c1b4"], Color("#8c887c"), 16, 12)
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
	var img := PA.new_image(16, 16)
	img.fill(Color.MAGENTA)
	return img


# ------------------------------------------------------------------- tuiles

static func _slabs() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#a8a498"))
	for r in 2:
		for c in 2:
			var off := 0 if r == 0 else 6
			var tone := PA.shade(Color("#e6e2d6"), (PA.rnd(c, r, 1611) - 0.5) * 0.08)
			var xs := posmod(c * 24 + off, T)
			PA.rect(img, xs + 1, r * 24 + 1, 22, 22, tone)
			PA.rect(img, xs + 1, r * 24 + 1, 22, 1, PA.shade(tone, 0.14))
			PA.rect(img, xs + 1, r * 24 + 22, 22, 1, PA.shade(tone, -0.14))
	RP._specks_in(img, 1612, 30, Color("#f6f3ea"))
	RP._specks_in(img, 1613, 14, Color("#b8b4a8"))
	return img


static func _marble() -> Image:
	var img := PA.new_image(T, T)
	for y in T:
		for x in T:
			var chk := ((x / 24) + (y / 24)) % 2
			img.set_pixel(x, y, Color("#ece8de") if chk == 0 else Color("#dcd8cc"))
	for i in 5:
		var x := int(PA.rnd(i, 3, 1621) * T)
		var y := int(PA.rnd(i, 4, 1621) * T)
		for k in 14:
			RP._wrap_px(img, x + k, y + int(k * 0.6 + sin(float(k + i)) * 1.5), Color("#b4b4bc"))
	PA.rect(img, 0, 0, T, 1, Color("#9a968a"))
	PA.rect(img, 0, 24, T, 1, Color("#b8b4a8"))
	PA.rect(img, 0, 0, 1, T, Color("#9a968a"))
	PA.rect(img, 24, 0, 1, T, Color("#b8b4a8"))
	return img


## Pierre de taille blanche. `wall` : paroi d'intérieur (frise bleue, filet d'or) ; sinon
## talus et paroi de relief (mousse au pied).
static func _ashlar(wall: bool) -> Image:
	var h := 72 if wall else T
	var img := PA.new_image(T, h)
	img.fill(Color("#8c887c"))
	var rows := 0
	for y in range(1, h - 2, 12):
		var off := 12 if rows % 2 == 1 else 0
		for x in range(-24, T + 24, 24):
			var tone := PA.shade(Color("#d6d2c6"), (PA.rnd(x + off, y, 1631) - 0.5) * 0.12)
			PA.rect(img, x + off + 1, y, 22, 11, tone)
			PA.rect(img, x + off + 1, y, 22, 1, PA.shade(tone, 0.16))
			PA.rect(img, x + off + 1, y + 10, 22, 1, PA.shade(tone, -0.18))
		rows += 1
	if wall:
		PA.rect(img, 0, 0, T, 7, NAVY)
		PA.rect(img, 0, 7, T, 1, GOLD)
		for x in range(4, T, 12):
			PA.rect(img, x, 2, 4, 3, PA.shade(NAVY, 0.3))
		PA.rect(img, 0, h - 8, T, 8, Color("#b8b4a8"))
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
	img.fill(Color("#8c887c"))
	var rows := 0
	for y in range(1, h - 2, 12):
		var off := 12 if rows % 2 == 1 else 0
		for x in range(-24, w + 24, 24):
			var tone := PA.shade(Color("#dedacd"), (PA.rnd(x + off, y, 1691) - 0.5) * 0.1)
			PA.rect(img, x + off + 1, y, 22, 11, tone)
			PA.rect(img, x + off + 1, y, 22, 1, PA.shade(tone, 0.16))
			PA.rect(img, x + off + 1, y + 10, 22, 1, PA.shade(tone, -0.16))
		rows += 1
	if h > 80:   # bandeau d'étage
		PA.rect(img, 0, h / 2 - 3, w, 4, Color("#b8b4a8"))
		PA.rect(img, 0, h / 2 - 3, w, 1, STONE_L)
	PA.rect(img, 0, h - 5, w, 5, Color("#a8a498"))
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
