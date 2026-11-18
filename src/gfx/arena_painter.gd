extends RefCounted
## Sols, accessoires de premier plan et fonds peints des arènes de combat par lieu :
## taverne, étage d'auberge, ruelle, cave à fromage, ferme, route, col, cité elfique, salle
## du Conseil, archives, quai. Les sols et accessoires se déclarent comme n'importe quelle
## tuile ou accessoire de `Sprites` (le sprite_library passe par TilePainter et PropPainter,
## qui reviennent ici pour les noms ci-dessous). Les fonds sont peints par arena_panels.gd.
## Voir docs/FORMAT_DONNEES.md, « Arènes par lieu ».

const PA = preload("res://src/gfx/pixel_art.gd")
const TP = preload("res://src/gfx/tile_painter.gd")

const TILES: Array[String] = ["plank_worn", "plank_dark", "plank_wet", "cobble_wet", "cellar_stone",
		"farmyard", "gravel_road", "snow_rock", "parquet_paper"]

## Accessoires-sprites : nom -> nombre de variantes.
const PROPS := {
	"tankard": 1, "chair_back": 1, "bucket": 1, "cheese_cut": 1, "paper_stack": 1, "quill_pot": 1,
	"milestone": 1, "thistle": 2, "candlestick": 1, "snow_rock": 2, "marker_pole": 1, "bedpost": 1,
	"coil_rope": 1, "life_buoy": 1,
}


static func has_tile(kind: String) -> bool:
	return TILES.has(kind)


static func has_prop(kind: String) -> bool:
	return PROPS.has(kind)


static func paint_tile(kind: String) -> Image:
	match kind:
		"plank_worn": return _plank_worn()
		"plank_dark": return _plank_dark()
		"plank_wet": return _plank_wet()
		"cobble_wet": return _cobble_wet()
		"cellar_stone": return _cellar_stone()
		"farmyard": return _farmyard()
		"gravel_road": return _gravel_road()
		"snow_rock": return _snow_rock()
		"parquet_paper": return _parquet_paper()
	var img := PA.new_image(TP.T, TP.T)
	img.fill(Color.MAGENTA)
	return img


# ------------------------------------------------------------------- outils

## Tache irrégulière qui se raccorde d'un bord à l'autre de la tuile (le motif se répète).
static func _blob(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color, a: float, sd: int) -> void:
	var t := img.get_width()
	for y in range(int(cy - ry) - 1, int(cy + ry) + 2):
		for x in range(int(cx - rx) - 1, int(cx + rx) + 2):
			var dx := (float(x) + 0.5 - cx) / rx
			var dy := (float(y) + 0.5 - cy) / ry
			var d := dx * dx + dy * dy + (PA.rnd(x, y, sd) - 0.5) * 0.45
			if d <= 1.0:
				var px := posmod(x, t)
				var py := posmod(y, t)
				img.set_pixel(px, py, img.get_pixel(px, py).lerp(c, a))


static func _scatter_px(img: Image, n: int, c: Color, sd: int, w: int = 1, h: int = 1) -> void:
	var t := img.get_width()
	for i in n:
		var x := int(PA.rnd(i, 1, sd) * float(t))
		var y := int(PA.rnd(i, 2, sd) * float(t))
		for dy in h:
			for dx in w:
				img.set_pixel(posmod(x + dx, t), posmod(y + dy, t), c)


# --------------------------------------------------------------------- sols

static func _plank_worn() -> Image:
	var img := TP._planks(Color("#8e6c47"), Color("#5a4230"), Color("#aa875f"))
	for i in 7:   # taches de bière et de pas : plaques sombres, ternes
		_blob(img, PA.rnd(i, 5, 811) * 48.0, PA.rnd(i, 6, 811) * 48.0, 3.0 + PA.rnd(i, 7, 811) * 4.0, 1.6 + PA.rnd(i, 8, 811) * 1.6, Color("#4b3626"), 0.4, 810 + i)
	_scatter_px(img, 26, Color("#c39f6e"), 812, 2, 1)   # éclats clairs de l'usure
	return img


static func _plank_dark() -> Image:
	var img := TP._planks(Color("#5b4636"), Color("#33281f"), Color("#7a604a"))
	_scatter_px(img, 20, Color("#84694f"), 821, 3, 1)
	_scatter_px(img, 16, Color("#2a2019"), 822, 2, 1)
	return img


static func _plank_wet() -> Image:
	var img := TP._planks(Color("#6a655c"), Color("#3e3c3f"), Color("#8a867c"))
	for i in 5:   # reflets mouillés : traînées claires bleutées dans le sens des planches
		var y := 2 + int(PA.rnd(i, 1, 831) * 44.0)
		var x := int(PA.rnd(i, 2, 831) * 48.0)
		for k in 8 + int(PA.rnd(i, 3, 831) * 8.0):
			img.set_pixel((x + k) % 48, y, Color("#a9bccb"))
	_blob(img, 12.0, 30.0, 6.0, 2.0, Color("#2c3544"), 0.5, 832)
	_blob(img, 36.0, 10.0, 5.0, 1.6, Color("#2c3544"), 0.5, 833)
	return img


static func _cobble_wet() -> Image:
	var img := TP._stones(["#5e6374", "#6b7082", "#565b6c", "#767a8c"], Color("#2e3240"), 12, 8)
	for i in 6:   # flaques : ciel bleu nuit entre les pavés
		_blob(img, PA.rnd(i, 1, 841) * 48.0, PA.rnd(i, 2, 841) * 48.0, 3.0 + PA.rnd(i, 3, 841) * 3.0, 1.4 + PA.rnd(i, 4, 841), Color("#35476c"), 0.55, 840 + i)
	for i in 14:   # reflets de lanterne sur le dessus des pavés
		var x := int(PA.rnd(i, 5, 842) * 48.0)
		var y := int(PA.rnd(i, 6, 842) * 48.0)
		img.set_pixel(x, y, Color("#f0cf8c"))
		img.set_pixel((x + 1) % 48, y, Color("#d8b070"))
	_scatter_px(img, 18, Color("#9fb0cc"), 843, 1, 1)
	return img


static func _cellar_stone() -> Image:
	var img := TP._stones(["#7b857d", "#87918a", "#6e7770", "#838b80"], Color("#353d37"), 16, 12)
	for i in 8:   # humidité : dalles plus sombres, mousse
		_blob(img, PA.rnd(i, 1, 851) * 48.0, PA.rnd(i, 2, 851) * 48.0, 4.0 + PA.rnd(i, 3, 851) * 4.0, 2.5 + PA.rnd(i, 4, 851) * 2.0, Color("#2c3a36"), 0.4, 850 + i)
	for i in 5:
		_blob(img, PA.rnd(i, 5, 852) * 48.0, PA.rnd(i, 6, 852) * 48.0, 2.2, 1.4, Color("#5f7c52"), 0.7, 860 + i)
	for i in 4:   # moisissure bleue qui luit
		_blob(img, PA.rnd(i, 7, 853) * 48.0, PA.rnd(i, 8, 853) * 48.0, 1.6, 1.1, Color("#6cb2dc"), 0.85, 870 + i)
	return img


static func _farmyard() -> Image:
	var img := PA.new_image(48, 48)
	var base := Color("#8b6c47")
	for y in 48:
		for x in 48:
			var c := base
			var r := PA.rnd(x, y, 881)
			if r < 0.18:
				c = base.darkened(0.16)
			elif r > 0.9:
				c = base.lightened(0.14)
			img.set_pixel(x, y, c)
	for i in 5:
		_blob(img, PA.rnd(i, 1, 882) * 48.0, PA.rnd(i, 2, 882) * 48.0, 4.0 + PA.rnd(i, 3, 882) * 3.0, 2.2, Color("#5b4430"), 0.7, 883 + i)   # boue
	for i in 40:   # brins de paille
		var x := int(PA.rnd(i, 4, 884) * 48.0)
		var y := int(PA.rnd(i, 5, 884) * 48.0)
		var n := 3 + int(PA.rnd(i, 6, 884) * 4.0)
		var rise := -1 if PA.rnd(i, 7, 884) < 0.5 else 1
		var col := Color("#dcb64a") if i % 3 != 0 else Color("#f0d57c")
		for k in n:
			img.set_pixel(posmod(x + k, 48), posmod(y + (k * rise) / 3, 48), col)
	_scatter_px(img, 3, Color("#f4f1e8"), 885, 2, 1)   # quelques plumes
	return img


static func _gravel_road() -> Image:
	var img := PA.new_image(48, 48)
	var base := Color("#9c917d")
	for y in 48:
		for x in 48:
			var c := base
			var r := PA.rnd(x, y, 891)
			if r < 0.25:
				c = base.darkened(0.12)
			elif r > 0.85:
				c = base.lightened(0.12)
			img.set_pixel(x, y, c)
	for rut_y: int in [12, 33]:   # deux ornières creusées dans le sens du chemin
		for x in 48:
			var wob := int(round(sin(float(x) * 0.25 + float(rut_y)) * 1.0))
			for k in 4:
				var c := img.get_pixel(x, rut_y + wob + k)
				img.set_pixel(x, rut_y + wob + k, c.darkened(0.2))
	_scatter_px(img, 70, Color("#cdc2aa"), 892, 1, 1)
	_scatter_px(img, 60, Color("#6a604f"), 893, 1, 1)
	_scatter_px(img, 14, Color("#d9d0ba"), 894, 2, 1)
	return img


static func _snow_rock() -> Image:
	var img := PA.new_image(48, 48)
	var snow := [Color("#e7eff7"), Color("#d6e2ee"), Color("#bccde0"), Color("#9fb4cc")]
	for y in 48:
		for x in 48:
			var n := PA.rnd(x / 3, y / 3, 901) * 0.55 + PA.rnd(x / 6, y / 6, 902) * 0.45
			img.set_pixel(x, y, snow[clampi(int(n * 3.2), 0, 3)] as Color)
	for i in 4:   # plaques de roche qui percent la neige
		var cx := PA.rnd(i, 1, 903) * 48.0
		var cy := PA.rnd(i, 2, 903) * 48.0
		_blob(img, cx, cy, 4.5 + PA.rnd(i, 3, 903) * 3.0, 2.6 + PA.rnd(i, 4, 903) * 1.6, Color("#707a89"), 0.95, 904 + i)
		_blob(img, cx - 1.0, cy - 1.0, 2.6, 1.2, Color("#929caa"), 0.8, 910 + i)
	for i in 6:   # glace : traits bleu vif
		var x := int(PA.rnd(i, 5, 905) * 48.0)
		var y := int(PA.rnd(i, 6, 905) * 48.0)
		for k in 4:
			img.set_pixel(posmod(x + k, 48), y, Color("#8fd0f0"))
	_scatter_px(img, 24, Color("#ffffff"), 906, 1, 1)
	return img


static func _parquet_paper() -> Image:
	var img := TP._planks(Color("#b89b69"), Color("#7e6540"), Color("#d0b583"))
	for i in 4:   # feuillets tombés : rectangle clair, ombre, lignes de texte
		var x := 2 + int(PA.rnd(i, 1, 921) * 36.0)
		var y := 2 + int(PA.rnd(i, 2, 921) * 38.0)
		PA.rect(img, x + 1, y + 1, 9, 6, Color("#6b5636"))
		PA.rect(img, x, y, 9, 6, Color("#efe9d6"))
		for ln in 3:
			PA.rect(img, x + 1, y + 1 + ln * 2, 7 - (ln % 2) * 2, 1, Color("#9a927c"))
	return img


# ------------------------------------------------------------------ accessoires

static func paint_prop(kind: String, variant: int) -> Image:
	match kind:
		"tankard": return _tankard()
		"chair_back": return _chair_back()
		"bucket": return _bucket()
		"cheese_cut": return _cheese_cut()
		"paper_stack": return _paper_stack()
		"quill_pot": return _quill_pot()
		"milestone": return _milestone()
		"thistle": return _thistle(variant)
		"candlestick": return _candlestick()
		"snow_rock": return _snow_rock_prop(variant)
		"marker_pole": return _marker_pole()
		"bedpost": return _bedpost()
		"coil_rope": return _coil_rope()
		"life_buoy": return _life_buoy()
	var img := PA.new_image(16, 16)
	img.fill(Color.MAGENTA)
	return img


static func _tankard() -> Image:
	var img := PA.new_image(30, 34)
	PA.rect(img, 4, 8, 18, 24, Color("#a8762f"))
	PA.rect(img, 4, 8, 3, 24, Color("#d49a46"))
	PA.rect(img, 19, 8, 3, 24, Color("#6e4a1e"))
	for y: int in [13, 26]:
		PA.rect(img, 4, y, 18, 2, Color("#4a3a2a"))
	PA.ellipse(img, 13.0, 8.0, 10.0, 4.0, Color("#f6f1de"))   # mousse
	PA.ellipse(img, 8.0, 6.0, 4.0, 3.0, Color("#ffffff"))
	PA.ellipse(img, 17.0, 5.0, 4.0, 3.0, Color("#f6f1de"))
	PA.rect(img, 22, 12, 5, 3, Color("#8a5f26"))   # anse
	PA.rect(img, 25, 12, 3, 14, Color("#8a5f26"))
	PA.rect(img, 22, 24, 5, 3, Color("#8a5f26"))
	PA.outline(img, Rect2i(0, 0, 30, 34))
	return img


static func _chair_back() -> Image:
	var img := PA.new_image(26, 40)
	var wood := Color("#6e4a2c")
	PA.rect(img, 3, 2, 3, 36, wood)
	PA.rect(img, 20, 2, 3, 36, wood)
	PA.rect(img, 3, 2, 20, 3, Color("#8a6038"))
	for x: int in [8, 12, 16]:
		PA.rect(img, x, 6, 2, 16, wood.darkened(0.1))
	PA.rect(img, 3, 24, 20, 4, Color("#8a6038"))
	PA.rect(img, 3, 24, 20, 1, Color("#a87c4c"))
	PA.outline(img, Rect2i(0, 0, 26, 40))
	return img


static func _bucket() -> Image:
	var img := PA.new_image(26, 26)
	for y in range(5, 24):
		var half := 8 + (y - 5) / 9
		PA.rect(img, 13 - half, y, half * 2, 1, Color("#8a6038"))
		PA.rect(img, 13 - half, y, 2, 1, Color("#b08050"))
		PA.rect(img, 13 + half - 2, y, 2, 1, Color("#5e3f24"))
	PA.rect(img, 5, 9, 16, 1, Color("#3f3d4a"))
	PA.rect(img, 5, 19, 16, 1, Color("#3f3d4a"))
	PA.ellipse(img, 13.0, 5.5, 8.0, 2.6, Color("#4a7c8a"))
	PA.line(img, 5, 5, 8, 1, Color("#3f3d4a"))
	PA.line(img, 8, 1, 18, 1, Color("#3f3d4a"))
	PA.line(img, 18, 1, 21, 5, Color("#3f3d4a"))
	PA.outline(img, Rect2i(0, 0, 26, 26))
	return img


static func _cheese_cut() -> Image:
	var img := PA.new_image(40, 26)
	PA.ellipse(img, 20.0, 18.0, 17.0, 6.0, Color("#b87a22"))
	PA.rect(img, 3, 10, 34, 8, Color("#e6a834"))
	PA.rect(img, 3, 10, 34, 2, Color("#f4cc66"))
	PA.ellipse(img, 20.0, 10.0, 17.0, 6.0, Color("#f6d66e"))
	for h: Array in [[12.0, 11.0], [22.0, 9.0], [28.0, 12.0], [18.0, 14.0]]:
		PA.ellipse(img, float(h[0]), float(h[1]), 2.0, 1.4, Color("#c98a2a"))
	PA.rect(img, 20, 8, 17, 8, Color("#00000000"))   # le quartier manquant
	PA.ellipse(img, 20.0, 10.0, 17.0, 6.0, Color("#00000000"))
	PA.ellipse(img, 20.0, 9.0, 14.0, 5.0, Color("#f6d66e"))
	PA.rect(img, 20, 9, 17, 9, Color("#00000000"))
	PA.rect(img, 20, 10, 2, 8, Color("#d99a30"))
	PA.outline(img, Rect2i(0, 0, 40, 26))
	return img


static func _paper_stack() -> Image:
	var img := PA.new_image(34, 24)
	for i in 6:
		var x := 2 + (i * 3) % 7
		PA.rect(img, x, 16 - i * 2, 24, 5, Color("#efe9d6") if i % 2 == 0 else Color("#e2dac2"))
		PA.rect(img, x, 20 - i * 2, 24, 1, Color("#9a927c"))
	PA.rect(img, 6, 6, 18, 1, Color("#8d8878"))
	PA.rect(img, 6, 9, 14, 1, Color("#8d8878"))
	PA.rect(img, 22, 2, 8, 8, Color("#b04a3a"))   # un tampon rouge
	PA.rect(img, 24, 0, 4, 3, Color("#6e3a2a"))
	PA.outline(img, Rect2i(0, 0, 34, 24))
	return img


static func _quill_pot() -> Image:
	var img := PA.new_image(24, 38)
	PA.rect(img, 6, 24, 14, 12, Color("#2c3050"))
	PA.rect(img, 6, 24, 3, 12, Color("#4a5080"))
	PA.rect(img, 8, 22, 10, 3, Color("#1a1c30"))
	PA.line(img, 14, 22, 19, 2, Color("#f2efe6"))
	PA.line(img, 15, 22, 20, 3, Color("#d8d4c4"))
	for k in 8:
		PA.rect(img, 15 + k / 2, 2 + k, 5 - k / 3, 1, Color("#f8f6ee"))
	PA.outline(img, Rect2i(0, 0, 24, 38))
	return img


static func _milestone() -> Image:
	var img := PA.new_image(28, 34)
	for y in range(6, 33):
		PA.rect(img, 5, y, 18, 1, Color("#9a968c"))
		PA.rect(img, 5, y, 3, 1, Color("#bcb8aa"))
		PA.rect(img, 20, y, 3, 1, Color("#6e6a62"))
	PA.ellipse(img, 14.0, 7.0, 9.0, 6.0, Color("#a8a498"))
	PA.ellipse(img, 12.0, 5.0, 5.0, 3.0, Color("#c4c0b2"))
	PA.rect(img, 9, 14, 10, 2, Color("#4a463e"))   # gravure
	PA.rect(img, 9, 18, 7, 2, Color("#4a463e"))
	PA.rect(img, 9, 22, 10, 2, Color("#4a463e"))
	PA.rect(img, 6, 30, 16, 2, Color("#6a8a4a"))   # mousse au pied
	PA.outline(img, Rect2i(0, 0, 28, 34))
	return img


static func _thistle(variant: int) -> Image:
	var img := PA.new_image(24, 30)
	var leaf := Color("#4f7a3c") if variant == 0 else Color("#5f8a44")
	for k in 3:
		PA.line(img, 12, 29, 4 + k * 8, 12 - k, leaf)
		PA.line(img, 13, 29, 5 + k * 8, 12 - k, leaf.darkened(0.2))
	PA.line(img, 12, 29, 12, 12, leaf)
	PA.ellipse(img, 12.0, 8.0, 5.0, 4.0, Color("#b64a9a"))
	PA.rect(img, 9, 3, 6, 2, Color("#d070b8"))
	PA.ellipse(img, 12.0, 12.0, 4.0, 2.0, leaf.darkened(0.1))
	PA.outline(img, Rect2i(0, 0, 24, 30))
	return img


static func _candlestick() -> Image:
	var img := PA.new_image(16, 36)
	PA.rect(img, 7, 12, 4, 18, Color("#efe6c8"))
	PA.rect(img, 7, 12, 1, 18, Color("#ffffff"))
	PA.rect(img, 3, 30, 12, 3, Color("#a8864a"))
	PA.rect(img, 6, 10, 6, 2, Color("#a8864a"))
	PA.ellipse(img, 9.5, 6.0, 2.6, 4.2, Color("#ffcf5a"))   # la flamme penche
	PA.ellipse(img, 10.0, 6.5, 1.4, 2.4, Color("#fff0b0"))
	PA.outline(img, Rect2i(0, 0, 16, 36))
	return img


static func _snow_rock_prop(variant: int) -> Image:
	var img := PA.new_image(36, 26)
	var w := 14 + variant * 2
	PA.ellipse(img, 18.0, 17.0, float(w), 9.0, Color("#6e7684"))
	PA.ellipse(img, 15.0, 14.0, float(w) - 5.0, 6.0, Color("#8c95a4"))
	PA.ellipse(img, 18.0, 10.0, float(w) - 2.0, 5.5, Color("#eef4fa"))   # chapeau de givre
	PA.ellipse(img, 14.0, 8.5, float(w) - 7.0, 3.0, Color("#ffffff"))
	PA.rect(img, 6, 20, 24, 3, Color("#566070"))
	PA.outline(img, Rect2i(0, 0, 36, 26))
	return img


static func _marker_pole() -> Image:
	var img := PA.new_image(18, 44)
	for y in range(2, 43):
		var stripe := (y / 5) % 2 == 0
		PA.rect(img, 7, y, 4, 1, Color("#c4412e") if stripe else Color("#f0ece0"))
	PA.rect(img, 3, 2, 12, 5, Color("#c4412e"))
	PA.rect(img, 3, 2, 12, 1, Color("#e8604a"))
	PA.rect(img, 5, 40, 8, 3, Color("#707a89"))
	PA.outline(img, Rect2i(0, 0, 18, 44))
	return img


static func _bedpost() -> Image:
	var img := PA.new_image(20, 46)
	PA.rect(img, 7, 8, 6, 36, Color("#5a3b26"))
	PA.rect(img, 7, 8, 2, 36, Color("#7e5636"))
	PA.ellipse(img, 10.0, 6.0, 5.0, 5.0, Color("#7e5636"))
	PA.ellipse(img, 8.5, 4.5, 2.0, 2.0, Color("#a87c4c"))
	PA.rect(img, 4, 40, 12, 4, Color("#4a3020"))
	PA.rect(img, 12, 20, 8, 16, Color("#8a5a6a"))   # un coin de couverture
	PA.outline(img, Rect2i(0, 0, 20, 46))
	return img


static func _coil_rope() -> Image:
	var img := PA.new_image(30, 20)
	for k in 4:
		PA.ellipse(img, 15.0, 13.0 - float(k) * 2.0, 12.0 - float(k), 5.0 - float(k) * 0.4, Color("#b8975a") if k % 2 == 0 else Color("#8a6c3c"))
	PA.ellipse(img, 15.0, 7.0, 4.0, 1.6, Color("#3a2c1c"))
	PA.outline(img, Rect2i(0, 0, 30, 20))
	return img


static func _life_buoy() -> Image:
	var img := PA.new_image(28, 28)
	PA.ellipse(img, 14.0, 14.0, 12.0, 12.0, Color("#f0ece0"))
	for i in 4:   # quatre quartiers rouges
		var a := float(i) * PI * 0.5 + 0.4
		PA.ellipse(img, 14.0 + cos(a) * 9.0, 14.0 + sin(a) * 9.0, 3.6, 3.6, Color("#c4412e"))
	PA.ellipse(img, 14.0, 14.0, 5.0, 5.0, Color("#00000000"))
	PA.outline(img, Rect2i(0, 0, 28, 28))
	return img
