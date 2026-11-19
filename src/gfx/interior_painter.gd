extends RefCounted
## Habillage des murs d'intérieur : pierre de cave appareillée, roche du hors-carte, et petits décors
## plaqués contre le mur (étagères, crochets, niches à bougie, tentures, fûts, boucliers, grilles,
## casseroles, appliques, plaques gravées). Posés par `src/world/interior_dress.gd`, jamais à la main.
## Densité : 24 pixels par unité monde, comme les textures de sol et de mur.

const PA = preload("res://src/gfx/pixel_art.gd")
const TP = preload("res://src/gfx/tile_painter.gd")
const T := 48

const TILES: Array[String] = ["cave_pierre", "cave_pierre_noire", "roche_fond"]

## Décors muraux : [variantes, largeur px, hauteur px, hauteur du bas au-dessus du sol (unités), lumière (couleur ou "")].
const DECOR := {
	"etagere": [4, 40, 40, 0.75, ""],
	"crochets": [3, 44, 36, 1.55, ""],
	"casseroles": [2, 44, 32, 1.45, ""],
	"niche": [2, 22, 32, 0.95, "#ffb45e"],
	"applique": [1, 10, 22, 1.5, "#ffb45e"],
	"tenture": [4, 30, 60, 0.85, ""],
	"tonneau": [2, 40, 40, 0.85, ""],
	"bouclier": [3, 32, 32, 1.4, ""],
	"grille": [2, 38, 20, 0.8, "#ff7a30"],
	"plaque": [2, 48, 16, 1.5, ""],
}

const WOOD := Color("#8a6038")
const WOOD_L := Color("#b08450")
const WOOD_D := Color("#523620")
const IRON := Color("#3a3844")
const IRON_L := Color("#6a6878")
const COPPER := Color("#b86a38")
const COPPER_L := Color("#e49a5a")


static func has_tile(kind: String) -> bool:
	return TILES.has(kind)


static func has_decor(kind: String) -> bool:
	return DECOR.has(kind)


static func paint_tile(kind: String) -> Image:
	match kind:
		"cave_pierre": return _cave_wall(false)
		"cave_pierre_noire": return _cave_wall(true)
		"roche_fond": return _rock_ground()
	return PA.new_image(T, T)


# ============================================================================ pierre

## Mur de cave : moellons clairs bien jointés, rangs décalés, humidité au pied, salpêtre qui
## coule des joints, quelques mousses. 48 x 72 px (2 x 3 unités), répétable en largeur.
static func _cave_wall(dark: bool) -> Image:
	var img := PA.new_image(T, 72)
	var tones: Array = ["#8c8678", "#7f796c", "#968f80", "#74705f", "#8a8272"]
	var joint := Color("#34302a")
	if dark:
		tones = ["#5c5a60", "#53525a", "#66646a", "#4a4950", "#5a5860"]
		joint = Color("#201e26")
	img.fill(joint)
	var rows := 6
	for r in rows:
		var y0 := r * 12
		var off := 12 if r % 2 == 1 else 0
		# largeurs de moellons inégales : 3 pierres par rang et par tuile (22, 14, 12 px décalés)
		var cuts: Array = [0, 22 + int(PA.rnd(r, 1, 911) * 6.0), 36 + int(PA.rnd(r, 2, 911) * 4.0), 48]
		for c in 3:
			var xa: int = int(cuts[c]) + off
			var xb: int = int(cuts[c + 1]) + off
			var base := Color(str(tones[int(PA.rnd(c, r, 912) * tones.size()) % tones.size()]))
			base = PA.shade(base, (PA.rnd(c + 7, r, 913) - 0.5) * 0.16)
			for y in range(1, 11):
				for x in range(xa + 1, xb):
					var col := base
					if y == 1:
						col = PA.shade(base, 0.14)
					elif y >= 10 or x == xb - 1:
						col = PA.shade(base, -0.2)
					elif x == xa + 1:
						col = PA.shade(base, 0.07)
					elif PA.rnd(x, y0 + y, 914) < 0.1:
						col = PA.shade(base, -0.08)
					elif PA.rnd(x, y0 + y, 915) > 0.95:
						col = PA.shade(base, 0.1)
					img.set_pixel(posmod(x, T), y0 + y, col)
	# humidité au pied : assombrie, mousse dans les joints
	for y in range(52, 72):
		var k := float(y - 52) / 20.0
		for x in T:
			var c := img.get_pixel(x, y)
			img.set_pixel(x, y, c.lerp(Color(0.1, 0.16, 0.14, 1.0), k * 0.32))
	for i in 10:
		var mx := int(PA.rnd(i, 1, 916) * T)
		var my := 56 + int(PA.rnd(i, 2, 916) * 15.0)
		for k in 2 + int(PA.rnd(i, 3, 916) * 4.0):
			PA.px(img, posmod(mx + k, T), my, Color("#4c6a3c") if k % 2 == 0 else Color("#6a8a4c"))
	# salpêtre : coulées blanchâtres sous les joints, de longueur inégale, et efflorescences
	for i in 9:
		var sx := int(PA.rnd(i, 1, 917) * T)
		var sy := 4 + int(PA.rnd(i, 2, 917) * 34.0)
		var ln := 5 + int(PA.rnd(i, 3, 917) * 16.0)
		for k in ln:
			var a := 1.0 - float(k) / float(ln)
			var c := img.get_pixel(posmod(sx, T), sy + k)
			img.set_pixel(posmod(sx, T), sy + k, c.lerp(Color("#dfe6dc"), 0.55 * a + 0.1))
			if k % 3 == 0 and a > 0.4:
				var c2 := img.get_pixel(posmod(sx + 1, T), sy + k)
				img.set_pixel(posmod(sx + 1, T), sy + k, c2.lerp(Color("#dfe6dc"), 0.32 * a))
	for i in 30:
		var ex := int(PA.rnd(i, 1, 918) * T)
		var ey := 2 + int(PA.rnd(i, 2, 918) * 60.0)
		var c := img.get_pixel(ex, ey)
		img.set_pixel(ex, ey, c.lerp(Color("#eef2e8"), 0.6))
	# corniche sombre en haut (le dessous de la poutre faîtière)
	PA.rect(img, 0, 0, T, 2, PA.shade(joint, -0.1))
	return img


## Roche du hors-carte vue d'en haut : grain fin sombre, quelques éclats ; aucun motif net, pour que la
## répétition (une tuile de 2 unités) ne se voie jamais sous la brume d'ombre du `surround`.
static func _rock_ground() -> Image:
	var img := PA.new_image(T, T)
	var base := Color("#4a4650")
	img.fill(base)
	TP._blotches(img, 931, 12, PA.shade(base, -0.035), 5.0, 10.0)
	TP._blotches(img, 932, 10, PA.shade(base, 0.03), 4.0, 9.0)
	for i in 120:
		var x := int(PA.rnd(i, 1, 933) * T)
		var y := int(PA.rnd(i, 2, 933) * T)
		img.set_pixel(x, y, PA.shade(base, (PA.rnd(i, 3, 933) - 0.5) * 0.3))
	return img


# ============================================================================ décors

## Renvoie {"albedo": Image, "emission": Image ou null}.
static func paint_decor(kind: String, v: int) -> Dictionary:
	var spec: Array = DECOR[kind]
	var img := PA.new_image(int(spec[1]), int(spec[2]))
	var emi := PA.new_image(int(spec[1]), int(spec[2]))
	match kind:
		"etagere": _shelf(img, v)
		"crochets": _hooks(img, v)
		"casseroles": _pans(img, v)
		"niche": _niche(img, emi, v)
		"applique": _sconce(img, emi)
		"tenture": _tapestry(img, v)
		"tonneau": _cask(img, v)
		"bouclier": _shield(img, v)
		"grille": _vent(img, emi, v)
		"plaque": _plaque(img, emi, v)
	return {"albedo": img, "emission": emi}


static func _wood_rect(img: Image, x: int, y: int, w: int, h: int) -> void:
	PA.rect(img, x, y, w, h, WOOD)
	PA.rect(img, x, y, w, 1, WOOD_L)
	PA.rect(img, x, y + h - 1, w, 1, WOOD_D)
	for i in maxi(1, w / 7):
		PA.px(img, x + 2 + int(PA.rnd(i, y, 921) * float(maxi(1, w - 4))), y + h / 2, WOOD_D)


static func _jar(img: Image, x: int, y: int, body: Color, glass: Color) -> void:
	PA.rect(img, x, y + 3, 7, 9, glass)
	PA.rect(img, x + 1, y + 5, 5, 6, body)
	PA.rect(img, x + 1, y, 5, 3, WOOD_D)
	PA.rect(img, x + 1, y, 5, 1, WOOD)
	PA.px(img, x + 1, y + 4, Color(1, 1, 1, 0.85))
	PA.px(img, x + 1, y + 5, Color(1, 1, 1, 0.5))
	PA.rect(img, x, y + 11, 7, 1, PA.shade(glass, -0.3))


static func _bottle(img: Image, x: int, y: int, c: Color) -> void:
	PA.rect(img, x, y + 5, 5, 10, c)
	PA.rect(img, x + 1, y + 1, 3, 5, c)
	PA.rect(img, x + 1, y, 3, 1, Color("#c8a060"))
	PA.px(img, x + 1, y + 7, PA.shade(c, 0.4))
	PA.px(img, x + 1, y + 8, PA.shade(c, 0.3))
	PA.rect(img, x + 4, y + 6, 1, 9, PA.shade(c, -0.3))
	PA.rect(img, x, y + 14, 5, 1, PA.shade(c, -0.3))


static func _mug(img: Image, x: int, y: int) -> void:
	PA.rect(img, x, y + 1, 6, 7, Color("#8e8a96"))
	PA.rect(img, x, y + 1, 6, 1, Color("#cfcad6"))
	PA.rect(img, x + 4, y + 2, 1, 6, Color("#5e5a6a"))
	PA.rect(img, x + 6, y + 2, 2, 1, Color("#6e6a7a"))
	PA.rect(img, x + 7, y + 3, 1, 3, Color("#6e6a7a"))
	PA.rect(img, x + 6, y + 6, 2, 1, Color("#6e6a7a"))
	PA.rect(img, x, y + 7, 6, 1, Color("#e8e0c8"))
	PA.px(img, x + 1, y, Color("#f4f0e0"))
	PA.px(img, x + 3, y, Color("#f4f0e0"))


static func _cheese(img: Image, cx: int, by: int, rx: int, tall: int) -> void:
	# meule : dessus ovale, flanc doré, croûte plus sombre
	PA.rect(img, cx - rx, by - tall, rx * 2, tall, Color("#cfa23c"))
	PA.ellipse(img, float(cx), float(by), float(rx), 2.2, Color("#cfa23c"))
	PA.rect(img, cx - rx, by - tall, 1, tall, Color("#8a6420"))
	PA.rect(img, cx + rx - 1, by - tall, 1, tall, Color("#8a6420"))
	PA.ellipse(img, float(cx), float(by - tall), float(rx), 2.2, Color("#f0d070"))
	PA.ellipse(img, float(cx), float(by - tall), float(rx) - 1.2, 1.3, Color("#f8e48a"))
	PA.px(img, cx - 1, by - tall, Color("#b88a20"))
	PA.px(img, cx + 2, by - tall - 1, Color("#b88a20"))
	PA.rect(img, cx - rx, by + 1, rx * 2, 1, Color("#7a5a1c"))


static func _shelf(img: Image, v: int) -> void:
	# deux planches sur équerres ; contenu selon la variante
	for row in 2:
		var by := 16 + row * 19
		_wood_rect(img, 0, by, 40, 3)
		PA.rect(img, 3, by + 3, 2, 5, WOOD_D)
		PA.rect(img, 35, by + 3, 2, 5, WOOD_D)
		PA.px(img, 5, by + 3, WOOD)
		var seed := v * 10 + row
		match (v + row) % 4:
			0:
				_cheese(img, 9, by, 7, 4)
				_cheese(img, 9, by - 4, 5, 3)
				_cheese(img, 25, by, 8, 5)
				# part entamée
				PA.rect(img, 33, by - 3, 5, 3, Color("#e8c050"))
				PA.px(img, 35, by - 2, Color("#b88a20"))
			1:
				var cols: Array = [Color("#c0382c"), Color("#d89a28"), Color("#5a8a3a"), Color("#8a3a6a"), Color("#c0382c")]
				for k in 5:
					_jar(img, 3 + k * 7 + (k / 3), by - 12, cols[(k + seed) % 5], Color("#7a9a98"))
			2:
				var bc: Array = [Color("#3a6a3c"), Color("#6a3c28"), Color("#3a6a3c"), Color("#4a5a30"), Color("#6a3c28"), Color("#3a6a3c")]
				for k in 6:
					_bottle(img, 2 + k * 6, by - 15, bc[(k + seed) % 6])
			3:
				for k in 4:
					_mug(img, 3 + k * 9, by - 8)
				PA.rect(img, 38, by - 5, 1, 5, Color("#d8d0b8"))
	PA.outline(img, Rect2i(0, 0, img.get_width(), img.get_height()), Color(0.1, 0.07, 0.06, 0.9))


static func _hooks(img: Image, v: int) -> void:
	# rail de fer à crochets, charcuterie et aulx pendus
	PA.rect(img, 0, 1, 44, 2, IRON)
	PA.rect(img, 0, 1, 44, 1, IRON_L)
	PA.rect(img, 0, 0, 2, 5, IRON)
	PA.rect(img, 42, 0, 2, 5, IRON)
	var xs: Array = [5, 14, 23, 32, 40]
	for k in xs.size():
		var x: int = xs[k]
		PA.px(img, x, 3, IRON_L)
		var kind := (k + v) % 5
		match kind:
			0:   # jambon
				PA.rect(img, x, 4, 1, 3, Color("#d8c8a0"))
				PA.ellipse(img, float(x) + 0.5, 12.0, 4.0, 6.0, Color("#b0524a"))
				PA.ellipse(img, float(x) + 0.5, 11.0, 2.4, 3.6, Color("#cc6a60"))
				PA.rect(img, x - 1, 17, 3, 3, Color("#e0c8a8"))
			1:   # saucisses en chapelet
				PA.rect(img, x, 4, 1, 4, Color("#d8c8a0"))
				for j in 4:
					PA.ellipse(img, float(x) + 0.5, 9.0 + float(j) * 5.0, 2.6, 2.8, Color("#9a3a30"))
					PA.px(img, x, 8 + j * 5, Color("#c0645a"))
					PA.rect(img, x, 11 + j * 5, 1, 1, Color("#d8c8a0"))
			2:   # tresse d'ail
				PA.rect(img, x, 4, 1, 2, Color("#d8c8a0"))
				for j in 5:
					var ox := (j % 2) * 2 - 1
					PA.ellipse(img, float(x) + 0.5 + float(ox), 8.0 + float(j) * 3.5, 2.2, 2.2, Color("#ece4cc"))
					PA.px(img, x + ox, 8 + j * 3, Color("#ffffff"))
			3:   # bouquet d'herbes tête en bas
				PA.rect(img, x, 4, 1, 4, Color("#d8c8a0"))
				for j in 7:
					var hx := x - 2 + int(PA.rnd(j, v, 922) * 5.0)
					PA.line(img, x, 8, hx, 18 + int(PA.rnd(j, 1, 922) * 4.0), Color("#5a7a38") if j % 2 == 0 else Color("#7a8a3c"))
			4:   # fromage pendu dans un filet
				PA.rect(img, x, 4, 1, 4, Color("#d8c8a0"))
				PA.ellipse(img, float(x) + 0.5, 12.0, 4.0, 4.0, Color("#e0b440"))
				for j in 4:
					PA.line(img, x - 3 + j * 2, 9, x - 3 + j * 2, 16, Color("#8a6a30"))
				PA.line(img, x - 4, 12, x + 5, 12, Color("#8a6a30"))
	PA.outline(img, Rect2i(0, 0, 44, 36), Color(0.1, 0.07, 0.06, 0.8))


static func _pans(img: Image, v: int) -> void:
	PA.rect(img, 0, 1, 44, 2, IRON)
	PA.rect(img, 0, 1, 44, 1, IRON_L)
	var xs: Array = [4, 14, 26, 37]
	for k in xs.size():
		var x: int = xs[k]
		var kind := (k + v) % 3
		PA.rect(img, x, 3, 1, 4 + kind, IRON)
		if kind == 0:   # casserole ronde
			PA.ellipse(img, float(x) + 0.5, 17.0, 6.0, 6.5, COPPER)
			PA.ellipse(img, float(x) + 0.5, 16.0, 4.5, 4.5, PA.shade(COPPER, -0.25))
			PA.rect(img, x - 4, 11, 4, 1, COPPER_L)
			PA.px(img, x - 3, 14, COPPER_L)
		elif kind == 1:   # louche
			PA.rect(img, x, 6, 1, 14, IRON_L)
			PA.ellipse(img, float(x) + 0.5, 22.0, 3.4, 3.0, IRON)
			PA.px(img, x - 1, 21, IRON_L)
		else:   # poêle
			PA.rect(img, x, 7, 1, 11, WOOD_D)
			PA.ellipse(img, float(x) + 0.5, 22.0, 6.0, 6.0, IRON)
			PA.ellipse(img, float(x) + 0.5, 22.0, 4.6, 4.6, PA.shade(IRON, -0.3))
			PA.px(img, x - 3, 19, IRON_L)
	PA.outline(img, Rect2i(0, 0, 44, 32), Color(0.1, 0.07, 0.06, 0.8))


static func _niche(img: Image, emi: Image, v: int) -> void:
	var w := 22
	var h := 32
	var stone := Color("#8a8478") if v == 0 else Color("#6e6a80")
	# cadre en arc
	PA.rect(img, 0, 8, w, h - 8, stone)
	PA.ellipse(img, 11.0, 9.0, 11.0, 9.0, stone)
	PA.rect(img, 0, 8, 1, h - 8, PA.shade(stone, 0.12))
	PA.rect(img, w - 1, 8, 1, h - 8, PA.shade(stone, -0.22))
	# creux sombre
	PA.rect(img, 3, 10, w - 6, h - 15, Color("#161216"))
	PA.ellipse(img, 11.0, 10.0, 8.0, 7.0, Color("#161216"))
	PA.rect(img, 3, 10, 1, h - 15, Color("#0a080a"))
	# tablette
	PA.rect(img, 1, h - 6, w - 2, 3, PA.shade(stone, 0.1))
	PA.rect(img, 1, h - 3, w - 2, 1, PA.shade(stone, -0.3))
	# bougie (ou lampe à huile) et sa lueur peinte au fond du creux
	for r in 7:
		var a := 0.22 - float(r) * 0.03
		PA.ellipse(emi, 11.0, 17.0, 3.0 + float(r), 3.5 + float(r), Color(1.0, 0.6, 0.2, maxf(0.0, a)))
	PA.ellipse(img, 11.0, 18.0, 7.0, 7.0, Color("#3a2418"))
	if v == 0:
		PA.rect(img, 10, 19, 3, 6, Color("#e8dcc0"))
		PA.rect(img, 12, 19, 1, 6, Color("#b8a888"))
		PA.rect(img, 9, 25, 5, 1, Color("#8a6a40"))
		PA.rect(img, 11, 15, 1, 4, Color("#2a1a10"))
		PA.rect(img, 10, 13, 3, 3, Color("#ffd878"))
		PA.px(img, 11, 12, Color("#ffd878"))
		PA.px(img, 11, 14, Color("#fffbe0"))
		PA.rect(img, 10, 13, 3, 3, Color("#ffd878"))
		PA.rect(img, 10, 13, 3, 3, Color(1.0, 0.8, 0.3, 1.0))
		PA.rect(img, 11, 13, 1, 2, Color("#fffbe0"))
		PA.rect(emi, 10, 12, 3, 4, Color(1.0, 0.8, 0.35, 1.0))
		PA.rect(emi, 11, 13, 1, 2, Color(1.0, 1.0, 0.8, 1.0))
	else:
		# petite lampe : bol d'huile et mèche
		PA.ellipse(img, 11.0, 23.0, 5.0, 2.6, Color("#c89a44"))
		PA.rect(img, 6, 22, 10, 1, Color("#e8c060"))
		PA.rect(img, 15, 21, 3, 1, Color("#c89a44"))
		PA.rect(img, 10, 17, 3, 5, Color("#ffd070"))
		PA.rect(emi, 10, 16, 3, 5, Color(1.0, 0.75, 0.3, 1.0))
		PA.rect(emi, 11, 17, 1, 3, Color(1.0, 1.0, 0.8, 1.0))
	PA.outline(img, Rect2i(0, 0, w, h), Color(0.08, 0.06, 0.07, 0.9))


static func _sconce(img: Image, emi: Image) -> void:
	# applique : plaque de fer ronde, bobèche, bougie courte et sa flamme
	PA.ellipse(img, 5.0, 14.0, 4.6, 4.6, IRON)
	PA.ellipse(img, 5.0, 14.0, 3.4, 3.4, Color("#524f60"))
	PA.px(img, 3, 12, IRON_L)
	PA.rect(img, 1, 17, 8, 2, IRON_L)
	PA.rect(img, 2, 19, 6, 1, IRON)
	PA.rect(img, 4, 20, 2, 2, IRON)
	PA.rect(img, 4, 10, 3, 7, Color("#d8cbb0"))
	PA.rect(img, 6, 10, 1, 7, Color("#a89878"))
	PA.rect(img, 4, 6, 2, 3, Color("#ffc860"))
	PA.px(img, 4, 7, Color("#fff4c0"))
	PA.rect(emi, 4, 5, 2, 4, Color(1.0, 0.8, 0.35, 1.0))
	for r in 4:
		PA.ellipse(emi, 5.0, 7.0, 2.0 + float(r) * 1.4, 2.5 + float(r) * 1.4, Color(1.0, 0.6, 0.2, 0.1))


static func _tapestry(img: Image, v: int) -> void:
	var cols: Array = [Color("#8a2e3a"), Color("#2e4a7a"), Color("#3a6a44"), Color("#6a3a7a")]
	var gold := Color("#d8aa48")
	var c: Color = cols[v % 4]
	# tringle et embouts
	PA.rect(img, 0, 0, 30, 3, WOOD_D)
	PA.rect(img, 0, 0, 30, 1, WOOD_L)
	PA.rect(img, 0, 0, 3, 5, gold)
	PA.rect(img, 27, 0, 3, 5, gold)
	# étoffe
	PA.rect(img, 3, 3, 24, 48, c)
	for x in range(3, 27):
		if (x - 3) % 6 == 3:
			PA.rect(img, x, 4, 1, 46, PA.shade(c, -0.14))
		if (x - 3) % 6 == 0:
			PA.rect(img, x, 4, 1, 46, PA.shade(c, 0.07))
	PA.rect(img, 3, 3, 24, 1, PA.shade(c, -0.25))
	# galon d'or sur les côtés et en bas
	PA.rect(img, 4, 4, 1, 46, gold)
	PA.rect(img, 25, 4, 1, 46, gold)
	PA.rect(img, 4, 48, 22, 2, gold)
	# frange
	for x in range(4, 26, 3):
		PA.rect(img, x, 51, 2, 5, gold)
		PA.px(img, x, 55, PA.shade(gold, -0.3))
	# motif central
	match v % 4:
		0:   # meule de fromage
			PA.ellipse(img, 15.0, 24.0, 7.0, 7.0, gold)
			PA.ellipse(img, 15.0, 24.0, 5.5, 5.5, Color("#f0d070"))
			PA.rect(img, 13, 22, 2, 2, c)
			PA.rect(img, 16, 26, 2, 2, c)
			PA.rect(img, 17, 21, 1, 1, c)
		1:   # blason à bande
			PA.rect(img, 8, 14, 14, 20, gold)
			PA.rect(img, 9, 15, 12, 18, c)
			PA.rect(img, 9, 22, 12, 4, gold)
			PA.rect(img, 13, 34, 4, 3, gold)
		2:   # losanges
			for k in 3:
				var cy := 14 + k * 11
				PA.line(img, 15, cy - 4, 20, cy, gold)
				PA.line(img, 20, cy, 15, cy + 4, gold)
				PA.line(img, 15, cy + 4, 10, cy, gold)
				PA.line(img, 10, cy, 15, cy - 4, gold)
		3:   # croissant et étoile
			PA.ellipse(img, 15.0, 22.0, 6.0, 6.0, gold)
			PA.ellipse(img, 17.0, 21.0, 5.0, 5.0, c)
			PA.px(img, 19, 31, gold)
			PA.rect(img, 18, 32, 3, 1, gold)
			PA.rect(img, 19, 30, 1, 3, gold)
	PA.rect(img, 3, 49, 24, 1, PA.shade(c, -0.3))
	PA.outline(img, Rect2i(0, 0, 30, 60), Color(0.08, 0.05, 0.06, 0.85))


static func _cask(img: Image, v: int) -> void:
	# fond de fût : disque de douelles cerclé de fer, bonde et robinet de laiton
	var c := Vector2(20.0, 20.0)
	PA.ellipse(img, c.x, c.y, 19.0, 19.0, WOOD_D)
	PA.ellipse(img, c.x, c.y, 18.0, 18.0, WOOD)
	for x in range(2, 38):
		var dx := float(x) + 0.5 - c.x
		var hh := sqrt(maxf(0.0, 17.5 * 17.5 - dx * dx))
		var tone := WOOD if ((x / 5) % 2 == 0) else PA.shade(WOOD, 0.08)
		for y in range(int(c.y - hh), int(c.y + hh)):
			PA.px(img, x, y, tone)
		if x % 5 == 0:
			for y in range(int(c.y - hh), int(c.y + hh)):
				PA.px(img, x, y, WOOD_D)
	# cerclages de fer
	for r in [17.5, 12.0]:
		for a in 90:
			var ang := float(a) / 90.0 * TAU
			PA.px(img, int(c.x + cos(ang) * r), int(c.y + sin(ang) * r), IRON)
			PA.px(img, int(c.x + cos(ang) * (r - 1.0)), int(c.y + sin(ang) * (r - 1.0)), IRON_L if sin(ang) < 0.0 else IRON)
	PA.ellipse(img, c.x, c.y + 1.0, 2.4, 2.4, WOOD_D)
	if v == 0:
		PA.rect(img, 19, 22, 3, 5, Color("#d8a840"))
		PA.rect(img, 17, 27, 7, 2, Color("#d8a840"))
		PA.px(img, 20, 29, Color("#cfa23c"))
	else:
		PA.rect(img, 30, 14, 5, 3, Color("#d8a840"))
		PA.px(img, 29, 15, Color("#8a6420"))
	PA.outline(img, Rect2i(0, 0, 40, 40), Color(0.08, 0.05, 0.05, 0.9))


static func _shield(img: Image, v: int) -> void:
	# haches croisées derrière un écu rond à bossage
	var gold := Color("#d8aa48")
	for s in [-1, 1]:
		PA.line(img, 16 + s * 11, 3, 16 - s * 11, 29, WOOD_D)
		PA.line(img, 17 + s * 11, 3, 17 - s * 11, 29, WOOD)
		PA.ellipse(img, 16.0 + float(s) * 11.0, 5.0, 4.5, 3.5, IRON_L)
		PA.ellipse(img, 16.0 + float(s) * 10.0, 6.5, 3.0, 2.0, IRON)
	var rim := gold if v != 1 else Color("#b8b8c8")
	PA.ellipse(img, 16.0, 17.0, 10.5, 10.5, PA.shade(rim, -0.35))
	PA.ellipse(img, 16.0, 17.0, 9.5, 9.5, rim)
	var field: Color = [Color("#7a2a30"), Color("#2c3e6a"), Color("#2a2a34")][v % 3]
	PA.ellipse(img, 16.0, 17.0, 7.5, 7.5, field)
	PA.ellipse(img, 16.0, 17.0, 3.0, 3.0, PA.shade(rim, 0.1))
	PA.px(img, 15, 16, Color("#fff4c8"))
	PA.rect(img, 15, 8, 2, 3, rim)
	PA.rect(img, 15, 23, 2, 3, rim)
	PA.rect(img, 7, 16, 3, 2, rim)
	PA.rect(img, 22, 16, 3, 2, rim)
	PA.outline(img, Rect2i(0, 0, 32, 32), Color(0.06, 0.05, 0.08, 0.9))


static func _vent(img: Image, emi: Image, v: int) -> void:
	# bouche de four : cadre de fer et fentes rougeoyantes
	PA.rect(img, 0, 0, 38, 20, IRON)
	PA.rect(img, 0, 0, 38, 1, IRON_L)
	PA.rect(img, 0, 19, 38, 1, Color("#1c1a24"))
	for k in 5:
		var x := 3 + k * 7
		PA.rect(img, x, 3, 5, 14, Color("#a83c18"))
		PA.rect(img, x + 1, 4, 3, 12, Color("#ff7a30"))
		PA.rect(img, x + 2, 6, 1, 8, Color("#ffd070"))
		PA.rect(emi, x, 3, 5, 14, Color(1.0, 0.4, 0.12, 1.0))
		PA.rect(emi, x + 2, 6, 1, 8, Color(1.0, 0.85, 0.4, 1.0))
	for x in [1, 36]:
		PA.px(img, x, 2, IRON_L)
		PA.px(img, x, 17, IRON_L)
	PA.outline(img, Rect2i(0, 0, 38, 20), Color(0.05, 0.04, 0.06, 0.9))


static func _plaque(img: Image, emi: Image, v: int) -> void:
	# plaque de pierre gravée de runes dorées (nains) : frise de losanges et de traits
	var stone := Color("#5a586c")
	var gold := Color("#d8aa48")
	PA.rect(img, 0, 0, 48, 16, stone)
	PA.rect(img, 0, 0, 48, 1, PA.shade(stone, 0.2))
	PA.rect(img, 0, 15, 48, 1, PA.shade(stone, -0.3))
	PA.rect(img, 1, 1, 46, 14, PA.shade(stone, -0.12))
	var x := 3
	var i := 0
	while x < 44:
		var kind := int(PA.rnd(i + v * 9, 1, 941) * 4.0)
		match kind:
			0:
				PA.rect(img, x, 4, 1, 8, gold)
				PA.rect(img, x + 1, 4, 2, 1, gold)
				PA.rect(img, x + 1, 7, 2, 1, gold)
			1:
				PA.line(img, x, 4, x + 3, 11, gold)
				PA.line(img, x + 3, 4, x, 11, gold)
			2:
				PA.rect(img, x, 4, 4, 1, gold)
				PA.rect(img, x + 1, 5, 1, 7, gold)
			3:
				PA.rect(img, x, 11, 4, 1, gold)
				PA.rect(img, x, 4, 1, 8, gold)
				PA.rect(img, x + 3, 6, 1, 6, gold)
		x += 6
		i += 1
	PA.outline(img, Rect2i(0, 0, 48, 16), Color(0.05, 0.05, 0.08, 0.9))


## Tache de lumière posée au sol devant une fenêtre : parallélogramme de carreaux (meneaux sombres)
## qui s'efface en s'éloignant du mur. Image blanche à alpha : la couleur vient du matériau. 32 x 56 px.
## Le haut de l'image est contre le mur.
static func paint_light_patch() -> Image:
	var img := PA.new_image(40, 56)
	for y in 56:
		var t := float(y) / 55.0
		var shift := int(round(t * 8.0))
		for x in range(2, 30):
			var px_x := x + shift
			var mull_v := (x - 2) % 14 >= 12
			var mull_h := (y % 18) >= 16
			if mull_v or mull_h:
				continue
			var edge := minf(minf(float(x - 2), float(29 - x)), 6.0) / 6.0
			var a := (0.55 - 0.38 * t) * (0.5 + 0.5 * edge)
			PA.px(img, px_x, y, Color(1.0, 1.0, 1.0, maxf(0.0, a)))
	return img
