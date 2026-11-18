extends RefCounted
## Peint par code l'architecture et les décors ELFIQUES (style d'architecture « elfe ») :
## dallages clairs, pierre ivoire, parquet pâle, toits bleu-gris, arcades en ogive,
## colonnes à nervures, arbres d'automne dorés, mobilier de la Chancellerie, etc.
## Accès : jamais directement, mais par `Sprites.prop(...)` et `Sprites.tile_image(...)`,
## qui s'adressent à PropPainter et TilePainter, lesquels renvoient ici pour les noms `elf_*`.
## Densité : 24 pixels par unité monde, comme tout le reste.

const PA = preload("res://src/gfx/pixel_art.gd")
const TP = preload("res://src/gfx/tile_painter.gd")
const PP = preload("res://src/gfx/prop_painter.gd")
const T := 48

const INK := Color("#3d4160")      # contour bleu-gris : plus doux que le violet sombre des décors rustiques
const IV_HI := Color("#fdf9ee")
const IV_L := Color("#f2ecda")
const IV := Color("#e3dbc5")
const IV_S := Color("#c9c0a9")
const IV_D := Color("#a8a08d")
const IV_B := Color("#8e94b0")     # ombre bleutée
const GOLD := Color("#dcbc66")
const GOLD_D := Color("#a98a3e")
const WOOD_L := Color("#e9d9b4")
const WOOD := Color("#d2bc90")
const WOOD_D := Color("#a58d62")
const LEAF_G := Color("#7a9a46")
const GLOW := Color("#c4e2ff")

const GOLD5 := ["#5a2e22", "#a8582a", "#d98a34", "#f0b848", "#fbe08a"]
const COPPER5 := ["#46202a", "#8a3a2a", "#bc552c", "#e07e36", "#f6b868"]
const BIRCH5 := ["#7a5a22", "#b8923a", "#dcb84e", "#efd877", "#fbf0b0"]
const MIX5 := ["#2c5532", "#5a8a3c", "#9cb04a", "#d6c458", "#f4e28c"]
const HEDGE5 := ["#1c3b2c", "#2d5b38", "#48813f", "#78a74f", "#b3ce72"]

const TILES: Array[String] = ["elf_flag", "elf_flag_dim", "elf_path", "elf_lawn", "elf_bridge", "elf_parquet", "elf_floor_dark",
		"elf_wall", "elf_wall_vista", "elf_wall_books", "elf_wall_vault", "elf_cliff", "elf_terrace", "elf_steps",
		"elf_wood", "elf_stone", "elf_column", "elf_roof", "elf_roof_vert", "elf_glow"]

## Décors-sprites : nom -> nombre de variantes.
const PROP_VARIANTS := {
	"elf_column": 2, "elf_arcade": 4, "elf_tree": 4, "elf_hedge": 4, "elf_bench": 1, "elf_statue": 2,
	"elf_fountain": 1, "elf_desk": 2, "elf_forms": 3, "elf_seat": 2, "elf_bookcase": 3, "elf_table": 2,
	"elf_flowers": 3, "elf_leaves": 3, "elf_gate": 2, "elf_banner": 2, "elf_urn": 2, "elf_pergola": 1,
	"elf_bridge_face": 1, "elf_ivy": 2, "elf_pine": 2, "elf_stamp": 1,
}


static func has_tile(kind: String) -> bool:
	return TILES.has(kind)


static func has_prop(kind: String) -> bool:
	return PROP_VARIANTS.has(kind)


static func paint_tile(kind: String) -> Image:
	match kind:
		"elf_flag": return _flagstones(["#e1d9c4", "#d8d0bb", "#e8e1ce", "#ddd5c0"], Color("#b2aa95"), 701, 24, 16)
		"elf_bridge": return _flagstones(["#e6dfcb", "#ddd5c0", "#ece6d3"], Color("#a8a08c"), 702, 16, 12)
		"elf_flag_dim": return _flagstones(["#7d8196", "#72768c", "#878ba0", "#777b90"], Color("#4a4d63"), 703, 24, 16)
		"elf_floor_dark": return _flagstones(["#555a72", "#4c5068", "#5e637b"], Color("#33364a"), 704, 24, 16)
		"elf_path": return _gravel()
		"elf_lawn": return _lawn()
		"elf_parquet": return TP._planks(Color("#e0cca4"), Color("#b79f76"), Color("#f0e1bd"))
		"elf_wood": return TP._planks(Color("#d6c196"), Color("#a58d62"), Color("#ebdcb8"))
		"elf_stone": return TP._stones(["#e6dfca", "#dcd4bf", "#ece6d3", "#e0d8c3"], Color("#b3ab96"), 16, 12)
		"elf_terrace": return _terrace()
		"elf_cliff": return TP._rock_strata(["#bdb7a8", "#a8a296", "#cdc8b8", "#8e8a84", "#dcd7c6"], 311, 1)
		"elf_steps": return _steps()
		"elf_column": return _column_tex()
		"elf_roof": return _scales(["#6f8c99", "#628391", "#7b98a4"], Color("#3e5864"), Color("#a6c1c8"))
		"elf_roof_vert": return _scales(["#6f9a8c", "#628c80", "#7ca898"], Color("#3b5c54"), Color("#a8cfc0"))
		"elf_wall": return _wall(0)
		"elf_wall_vista": return _wall(1)
		"elf_wall_books": return _wall(2)
		"elf_wall_vault": return _wall(3)
		"elf_glow": return _glow_tex()
	var img := PA.new_image(T, T)
	img.fill(Color.MAGENTA)
	return img


static func paint_prop(kind: String, v: int) -> Image:
	match kind:
		"elf_column": return _column(v)
		"elf_arcade": return _arcade(v)
		"elf_tree": return _tree(v)
		"elf_pine": return _pine(v)
		"elf_hedge": return _hedge(v)
		"elf_bench": return _bench()
		"elf_statue": return _statue(v)
		"elf_fountain": return _fountain()
		"elf_desk": return _desk(v)
		"elf_forms": return _forms(v)
		"elf_stamp": return _stamp()
		"elf_seat": return _seat(v)
		"elf_bookcase": return _bookcase(v)
		"elf_table": return _table(v)
		"elf_flowers": return _flowers(v)
		"elf_leaves": return _leaves(v)
		"elf_gate": return _gate(v)
		"elf_banner": return _banner(v)
		"elf_urn": return _urn(v)
		"elf_pergola": return _pergola()
		"elf_bridge_face": return _bridge_face()
		"elf_ivy": return _ivy_curtain(v)
	var img := PA.new_image(16, 16)
	img.fill(Color.MAGENTA)
	return img


# --------------------------------------------------------------- utilitaires

## Demi-largeur d'une ogive à la hauteur dy au-dessus de la naissance (a : demi-portée,
## r : rayon des arcs ; r > a donne un arc brisé élancé). Négative ou nulle au-delà de la clef.
static func _ogive_hw(a: float, r: float, dy: float) -> float:
	var v := r * r - dy * dy
	if v < 0.0:
		return -1.0
	return a - r + sqrt(v)


## Remplit une ogive : rectangle de la naissance jusqu'à y_bottom, puis l'arc brisé au-dessus.
static func _fill_ogive(img: Image, cx: float, y_spring: int, a: float, r: float, c: Color, y_bottom: int) -> void:
	var y := y_spring + int(a * 3.0)
	while y > y_spring - int(r * 1.2) - 4:
		var dy := float(y_spring - y)
		var hw := a if dy <= 0.0 else _ogive_hw(a, r, dy + 0.5)
		if y <= y_bottom and hw > 0.0:
			var x0 := int(round(cx - hw))
			var x1 := int(round(cx + hw))
			PA.rect(img, x0, y, x1 - x0, 1, c)
		y -= 1
	# la partie rectangulaire sous la naissance
	if y_bottom > y_spring:
		PA.rect(img, int(round(cx - a)), y_spring, int(round(a * 2.0)), y_bottom - y_spring + 1, c)


## Bloc de pierre éclairé d'en haut à gauche.
static func _stone_box(img: Image, x: int, y: int, w: int, h: int, base: Color = IV) -> void:
	PA.rect(img, x, y, w, h, base)
	PA.rect(img, x, y, w, 1, PA.shade(base, 0.14))
	PA.rect(img, x, y, 1, h, PA.shade(base, 0.08))
	PA.rect(img, x + w - 1, y, 1, h, PA.shade(base, -0.14))
	PA.rect(img, x, y + h - 1, w, 1, PA.shade(base, -0.2))


static func _grain(img: Image, region: Rect2i, sd: int, count: int, c: Color) -> void:
	for i in count:
		var x := region.position.x + int(PA.rnd(i, 1, sd) * region.size.x)
		var y := region.position.y + int(PA.rnd(i, 2, sd) * region.size.y)
		if img.get_pixel(x, y).a > 0.5:
			img.set_pixel(x, y, c)


static func _leaf_px(img: Image, x: int, y: int, c: Color) -> void:
	PA.px(img, x, y, c)
	PA.px(img, x + 1, y, PA.shade(c, 0.12))
	PA.px(img, x, y + 1, PA.shade(c, -0.18))


# ------------------------------------------------------------------- textures

static func _flagstones(tones: Array, joint: Color, sd: int, sw: int, sh: int) -> Image:
	var img := PA.new_image(T, T)
	img.fill(joint)
	for r in T / sh:
		var off := sw / 2 if r % 2 == 1 else 0
		for c in T / sw:
			var tone := Color.from_string(str(tones[int(PA.rnd(c, r, sd) * tones.size()) % tones.size()]), Color.GRAY)
			var x0 := c * sw + off
			var y0 := r * sh
			for y in range(1, sh - 1):
				for x in range(1, sw - 1):
					var col := tone
					if y == 1 or x == 1:
						col = PA.shade(tone, 0.07)
					elif y == sh - 2 or x == sw - 2:
						col = PA.shade(tone, -0.07)
					var n := PA.rnd(x0 + x, y0 + y, sd + 5)
					if n < 0.06:
						col = PA.shade(col, -0.05)
					elif n > 0.95:
						col = PA.shade(col, 0.05)
					img.set_pixel(posmod(x0 + x, T), y0 + y, col)
	# feuilles d'automne tombées et un peu de mousse dans les joints
	for i in 4:
		var x := int(PA.rnd(i, 1, sd + 9) * (T - 3))
		var y := int(PA.rnd(i, 2, sd + 9) * (T - 3))
		_leaf_px(img, x, y, Color("#d9a03c") if i % 2 == 0 else Color("#bd6f2c"))
	for i in 10:
		var x := int(PA.rnd(i, 3, sd + 11) * T)
		var y := int(PA.rnd(i, 4, sd + 11) * T)
		if img.get_pixel(x, y).is_equal_approx(joint):
			img.set_pixel(x, y, Color("#8da05c"))
	return img


static func _lawn() -> Image:
	var img := PA.new_image(T, T)
	var base := Color("#74a04a")
	img.fill(base)
	TP._blotches(img, 211, 9, Color("#67953f"), 6.0, 13.0)
	TP._blotches(img, 212, 7, Color("#86b152"), 4.0, 8.0)
	TP._blotches(img, 213, 4, Color("#9dba58"), 3.0, 5.0)
	TP._specks(img, 214, 70, Color("#5e8c3e"))
	for i in 40:
		var x := int(PA.rnd(i, 1, 221) * T)
		var y := int(PA.rnd(i, 2, 221) * T)
		img.set_pixel(x, y, Color("#b4d06a"))
		img.set_pixel(x, (y + 1) % T, Color("#86b152"))
	for i in 18:
		var x := int(PA.rnd(i, 3, 222) * T)
		var y := int(PA.rnd(i, 4, 222) * T)
		img.set_pixel(x, y, Color("#b4d06a"))
		img.set_pixel((x + 1) % T, (y + 1) % T, Color("#86b152"))
		img.set_pixel(x, (y + 2) % T, Color("#4f7d36"))
	# feuilles dorées tombées et fleurs blanches
	for i in 6:
		var x := int(PA.rnd(i, 5, 223) * (T - 2))
		var y := int(PA.rnd(i, 6, 223) * (T - 2))
		var c := Color("#e8a93c") if i % 3 != 0 else Color("#c4672c")
		img.set_pixel(x, y, c)
		img.set_pixel(x + 1, y, PA.shade(c, 0.15))
	for i in 4:
		var x := int(PA.rnd(i, 7, 224) * (T - 2))
		var y := int(PA.rnd(i, 8, 224) * (T - 2))
		img.set_pixel(x, y, Color("#fbf8ec"))
		img.set_pixel(x + 1, y, Color("#e6e2cc"))
		img.set_pixel(x, y + 1, Color("#5a8a3c"))
	return img


static func _gravel() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#d3c8a8"))
	TP._blotches(img, 231, 12, Color("#c8bb99"), 4.0, 8.0)
	TP._blotches(img, 232, 10, Color("#dfd5b8"), 3.0, 6.0)
	TP._specks(img, 233, 70, Color("#bdb08e"))
	TP._specks(img, 234, 40, Color("#ebe3c8"))
	for i in 10:
		var x := int(PA.rnd(i, 1, 235) * (T - 3))
		var y := int(PA.rnd(i, 2, 235) * (T - 3))
		PA.rect(img, x, y, 2, 2, Color("#b9b3a4"))
		PA.px(img, x, y, Color("#dcd6c6"))
	for i in 5:
		var x := int(PA.rnd(i, 3, 236) * (T - 2))
		var y := int(PA.rnd(i, 4, 236) * (T - 2))
		var c := Color("#dca03a") if i % 2 == 0 else Color("#b8662a")
		img.set_pixel(x, y, c)
		img.set_pixel(x + 1, y, PA.shade(c, 0.15))
	return img


static func _terrace() -> Image:
	var img := TP._stones(["#ddd5c0", "#e6dfcb", "#d3cab4", "#e0d8c3"], Color("#a39b86"), 16, 12)
	# lierre qui retombe du haut du mur
	for i in 5:
		var x := int(PA.rnd(i, 1, 241) * T)
		var n := 4 + int(PA.rnd(i, 2, 241) * 12.0)
		for k in n:
			var c := Color("#5c8840") if (k + i) % 3 != 0 else Color("#7aa650")
			img.set_pixel((x + (k % 2)) % T, k, c)
			if k % 4 == 3:
				img.set_pixel((x + 2) % T, k, Color("#d9a03c") if i % 2 == 0 else Color("#7aa650"))
	return img


static func _steps() -> Image:
	var img := PA.new_image(T, T)
	for b in 4:
		var y0 := b * 12
		PA.rect(img, 0, y0, T, 12, Color("#ddd5c0"))
		PA.rect(img, 0, y0, T, 2, Color("#f6f1e2"))
		PA.rect(img, 0, y0 + 2, T, 1, Color("#ebe4d0"))
		PA.rect(img, 0, y0 + 9, T, 2, Color("#b9b19b"))
		PA.rect(img, 0, y0 + 11, T, 1, Color("#8f8975"))
		for x in range(0, T, 16):
			PA.rect(img, x + int(PA.rnd(x, b, 251) * 3.0), y0 + 3, 1, 6, Color("#cdc5ae"))
	TP._specks(img, 252, 40, Color("#d2cab4"))
	return img


static func _column_tex() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#e8e0ca"))
	for x in range(0, T, 8):
		PA.rect(img, x, 0, 1, T, Color("#fbf7ea"))
		PA.rect(img, x + 5, 0, 2, T, Color("#cbc2ab"))
		PA.rect(img, x + 7, 0, 1, T, Color("#b3ab95"))
	TP._specks(img, 261, 25, Color("#d6ceb7"))
	return img


## Toit en écailles (ardoise bleu-gris ou vert-de-gris) : les rangs du haut recouvrent ceux du bas.
static func _scales(tones: Array, edge: Color, light: Color) -> Image:
	var img := PA.new_image(T, T)
	img.fill(edge)
	var rows := T / 6
	for ri in rows:
		var r := rows - 1 - ri   # du bas vers le haut
		var off := 4 if r % 2 == 1 else 0
		for c in T / 8:
			var cx := float(c * 8 + off) + 4.0
			var cy := float(r * 6) + 2.0
			var tone := Color.from_string(str(tones[int(PA.rnd(c, r, 271) * tones.size()) % tones.size()]), Color.GRAY)
			TP._wrap_ellipse(img, cx, cy + 0.4, 4.4, 5.2, edge)
			TP._wrap_ellipse(img, cx, cy, 4.0, 4.6, tone)
			TP._wrap_ellipse(img, cx - 0.6, cy - 0.9, 3.0, 2.6, PA.shade(tone, 0.1))
			for k in 3:
				img.set_pixel(posmod(int(cx) - 2 + k, T), posmod(int(cy) - 2, T), light)
			img.set_pixel(posmod(int(cx) + 2, T), posmod(int(cy) + 3, T), PA.shade(tone, -0.18))
	return img


static func _glow_tex() -> Image:
	var img := PA.new_image(T, T)
	img.fill(Color("#fff2c8"))
	return img


## Mur intérieur 48 x 72 px (2 x 3 unités) : corniche à frise de feuilles, pilastres
## nervurés aux deux bords de la tuile, arcature en ogive, plinthe.
## kind : 0 arcature aveugle, 1 baie ouverte sur la vallée, 2 rayonnages, 3 casiers des Archives.
static func _wall(kind: int) -> Image:
	var img := PA.new_image(T, 72)
	var base := Color("#e6decb")
	var dark := kind == 3
	if dark:
		base = Color("#b9b8bd")
	img.fill(base)
	# assises de pierre très discrètes
	for y in range(8, 60, 9):
		PA.rect(img, 0, y, T, 1, PA.shade(base, -0.06))
	for i in range(0, 60):
		var x := int(PA.rnd(i, 1, 281) * T)
		var y := 8 + int(PA.rnd(i, 2, 281) * 52.0)
		img.set_pixel(x, y, PA.shade(base, 0.05 if i % 2 == 0 else -0.05))
	# corniche
	PA.rect(img, 0, 0, T, 5, PA.shade(base, 0.1))
	PA.rect(img, 0, 5, T, 1, PA.shade(base, -0.2))
	PA.rect(img, 0, 6, T, 1, GOLD)
	PA.rect(img, 0, 7, T, 1, GOLD_D)
	for x in range(2, T, 6):
		PA.px(img, x, 2, LEAF_G)
		PA.px(img, x + 1, 3, Color("#5c8840"))
	# plinthe
	PA.rect(img, 0, 62, T, 10, PA.shade(base, -0.1))
	PA.rect(img, 0, 62, T, 1, PA.shade(base, 0.1))
	PA.rect(img, 0, 66, T, 1, PA.shade(base, -0.2))
	# pilastres nervurés
	for px: int in [0, 45]:
		PA.rect(img, px, 8, 3, 54, PA.shade(base, 0.08))
		PA.rect(img, px + 1, 8, 1, 54, PA.shade(base, -0.08))
		PA.rect(img, px, 8, 3, 2, PA.shade(base, 0.2))
		PA.rect(img, px, 60, 3, 2, PA.shade(base, -0.15))
	# arcature
	var cx := 24.0
	var a := 10.0
	var rr := 17.0
	var spring := 34
	_fill_ogive(img, cx, spring, a + 2.0, rr + 2.0, PA.shade(base, 0.14), 61)
	var inner := PA.shade(base, -0.1)
	if kind == 1:
		inner = Color("#9fc2e4")
	elif kind == 2:
		inner = Color("#6e5a44")
	elif kind == 3:
		inner = Color("#7a7b86")
	_fill_ogive(img, cx, spring, a, rr, inner, 61)
	match kind:
		0:
			# relief : tige et feuilles sculptées dans la niche
			PA.rect(img, 23, 30, 2, 31, PA.shade(base, -0.2))
			for k in 6:
				var y := 34 + k * 5
				PA.rect(img, 19 + (k % 2) * 6 - 1, y, 5, 2, PA.shade(base, -0.17))
				PA.px(img, 19 + (k % 2) * 6 - 1, y, PA.shade(base, 0.1))
			PA.rect(img, int(cx) - 9, 56, 18, 5, PA.shade(base, -0.05))
		1:
			_vista(img, int(cx), spring, a, rr)
		2:
			_shelves(img, 14, 62, 20)
		3:
			_drawers(img, 14, 61, 20)
	# lumière : le bord gauche de la niche est éclairé, le bord droit à l'ombre
	for y in range(spring - 16, 60):
		var hw := a if y >= spring else _ogive_hw(a, rr, float(spring - y) + 0.5)
		if hw <= 0.0:
			continue
		var xl := int(round(cx - hw))
		var xr := int(round(cx + hw)) - 1
		PA.px(img, xl, y, PA.shade(inner, -0.25))
		PA.px(img, xl + 1, y, PA.shade(inner, -0.12))
		PA.px(img, xr, y, PA.shade(inner, 0.1))
	return img


## Paysage de la vallée dans une baie : ciel doré, montagnes bleues, forêt d'automne, cascade.
static func _vista(img: Image, cx: int, spring: int, a: float, rr: float) -> void:
	for y in range(10, 61):
		var k := float(y - 10) / 50.0
		var sky := Color("#86aede").lerp(Color("#fbe3ae"), clampf(k * 1.25, 0.0, 1.0))
		var dy := float(spring - y)
		var hw := a if dy <= 0.0 else _ogive_hw(a, rr, dy + 0.5)
		if hw <= 0.0:
			continue
		for x in range(int(round(cx - hw)), int(round(cx + hw))):
			var c := sky
			var mt := 34.0 + sin(float(x) * 0.5) * 3.0 + sin(float(x) * 1.3) * 1.2
			if float(y) > mt:
				c = Color("#8a9cc6")
			var hl := 42.0 + sin(float(x) * 0.35 + 1.0) * 3.5
			if float(y) > hl:
				c = Color("#6f8fa6")
			var fo := 49.0 + sin(float(x) * 0.8) * 2.0
			if float(y) > fo:
				c = Color("#c8903a") if PA.rnd(x, y, 291) < 0.6 else Color("#a8622c")
				if PA.rnd(x, y, 292) < 0.2:
					c = Color("#3f6a48")
			if float(y) > 55.0:
				c = Color("#e0a63e") if PA.rnd(x, y, 293) < 0.5 else Color("#b86a2a")
			if x == cx + 4 and y > 38 and y < 52:
				c = Color("#f7faff")   # la cascade
			img.set_pixel(x, y, c)


## Rayonnages : trois étagères de rouleaux et de dossiers serrés.
static func _shelves(img: Image, y0: int, y1: int, w: int) -> void:
	var x0 := 24 - w / 2
	var cols: Array[Color] = [Color("#6d86a8"), Color("#a8503c"), Color("#d8c690"), Color("#5c8a6a"), Color("#8a6aa0"), Color("#c89a48"), Color("#e8e0cc")]
	var rows := [Vector2i(36, 46), Vector2i(47, 56)]
	for r: Vector2i in rows:
		var x := x0
		while x < x0 + w:
			var wd := 1 + int(PA.rnd(x, r.x, 295) * 2.0)
			var hh := (r.y - r.x) - int(PA.rnd(x, r.y, 296) * 4.0)
			var c: Color = cols[int(PA.rnd(x, r.x, 297) * cols.size()) % cols.size()]
			PA.rect(img, x, r.y - hh, wd, hh, c)
			PA.px(img, x, r.y - hh, PA.shade(c, 0.2))
			x += wd
		PA.rect(img, x0, r.y, w, 1, WOOD_L)
	PA.rect(img, x0, 57, w, 4, Color("#8a7455"))
	PA.rect(img, x0, 57, w, 1, WOOD_L)


## Casiers : petits tiroirs à poignée de laiton, étiquette de parchemin.
static func _drawers(img: Image, y0: int, y1: int, w: int) -> void:
	var x0 := 24 - w / 2
	for r in 5:
		for c in 4:
			var x := x0 + c * 5
			var y := 38 + r * 4
			PA.rect(img, x, y, 4, 3, Color("#8d8e9a"))
			PA.rect(img, x, y, 4, 1, Color("#aeb0bc"))
			PA.px(img, x + 1, y + 1, GOLD)
			PA.px(img, x + 2, y + 1, Color("#f0e8d0"))
	PA.rect(img, x0, 58, w, 3, Color("#5a5b68"))


# --------------------------------------------------------------------- sprites

static func _column(v: int) -> Image:
	var img := PA.new_image(18, 90)
	# fût
	for y in range(12, 80):
		for x in range(5, 13):
			var u := float(x - 5) / 7.0
			var c := IV_L if u < 0.25 else (IV if u < 0.65 else IV_S)
			if (x - 5) % 3 == 1:
				c = PA.shade(c, -0.08)
			PA.px(img, x, y, c)
	# base : tore et plinthe
	_stone_box(img, 2, 82, 14, 7, IV)
	PA.rect(img, 3, 79, 12, 3, IV_L)
	PA.rect(img, 3, 81, 12, 1, IV_S)
	# chapiteau : feuilles recourbées
	PA.rect(img, 3, 8, 12, 5, IV_L)
	PA.rect(img, 3, 12, 12, 1, IV_S)
	for k in 4:
		var x := 3 + k * 3
		PA.rect(img, x, 5, 3, 4, IV)
		PA.px(img, x + 1, 4, IV_L)
		PA.px(img, x + 2, 5, IV_S)
	_stone_box(img, 1, 0, 16, 5, IV)
	PA.rect(img, 2, 5, 14, 1, IV_D)
	if v == 1:
		for k in 16:
			var y := 76 - k * 4
			var x := 6 + int(round(sin(float(k) * 0.9) * 3.0))
			_leaf_px(img, x, y, Color("#5f8c3e") if k % 3 != 0 else Color("#d9a03c"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 18, 90), INK)
	return img


## Arcade d'ogives élancées. v = nombre d'arches - 1, sauf v = 3 : trois arches sur balustrade ajourée.
static func _arcade(v: int) -> Image:
	var n := (v if v < 3 else 2) + 1
	var mw := 72
	var w := n * mw + 10
	var h := 108
	var img := PA.new_image(w, h)
	# masse de pierre
	PA.rect(img, 0, 0, w, h, IV)
	var a := 27.0
	var rr := 46.0
	var spring := 56
	for i in n:
		var cx := 5.0 + float(i) * mw + mw * 0.5
		_fill_ogive(img, cx, spring, a + 3.0, rr + 3.0, IV_HI, h)    # claveaux
		_fill_ogive(img, cx, spring, a, rr, Color(0, 0, 0, 0), h)    # ouverture
	# corniche haute
	PA.rect(img, 0, 0, w, 6, IV_L)
	PA.rect(img, 0, 6, w, 1, IV_S)
	PA.rect(img, 0, 7, w, 1, GOLD)
	PA.rect(img, 0, 8, w, 1, GOLD_D)
	for x in range(2, w, 6):
		PA.px(img, x, 3, LEAF_G)
		PA.px(img, x + 1, 4, Color("#5c8840"))
	# remplage des écoinçons : cercle ajouré au-dessus de chaque pilier
	for i in range(n + 1):
		var px := 5.0 + float(i) * mw
		for k in 4:
			PA.rect(img, int(px) - 4, 24 + k * 8, 9, 1, IV_S)
		PA.ellipse(img, px, 28.0, 5.0, 5.0, IV_L)
		PA.ellipse(img, px, 28.0, 3.0, 3.0, IV_B)
		PA.px(img, int(px), 28, GOLD)
	# piliers : colonnettes nervurées
	for i in range(n + 1):
		var px := int(5.0 + float(i) * mw) - 4
		for y in range(spring - 4, h - 7):
			for x in range(px, px + 8):
				var u := float(x - px) / 7.0
				var c := IV_L if u < 0.25 else (IV if u < 0.65 else IV_S)
				if (x - px) % 3 == 1:
					c = PA.shade(c, -0.08)
				PA.px(img, x, y, c)
		PA.rect(img, px - 2, spring - 8, 12, 5, IV_L)        # chapiteau
		PA.rect(img, px - 2, spring - 4, 12, 1, IV_D)
		_stone_box(img, px - 3, h - 8, 14, 8, IV)            # base
		for k in 3:
			_leaf_px(img, px + 1 + k * 2, spring - 11 + (k % 2), Color("#e0a63e") if k % 2 == 0 else LEAF_G)
	# balustrade ajourée entre les piliers
	if v == 3:
		for i in n:
			var x0 := 5 + i * mw + 5
			PA.rect(img, x0, h - 30, mw - 10, 3, IV_L)
			PA.rect(img, x0, h - 27, mw - 10, 1, IV_D)
			for x in range(x0 + 1, x0 + mw - 11, 5):
				PA.rect(img, x, h - 24, 3, 16, IV)
				PA.rect(img, x, h - 24, 1, 16, IV_L)
				PA.rect(img, x + 2, h - 24, 1, 16, IV_S)
				PA.ellipse(img, float(x) + 1.5, float(h - 18), 2.5, 3.0, IV)
			PA.rect(img, x0, h - 9, mw - 10, 3, IV_L)
			PA.rect(img, x0, h - 6, mw - 10, 1, IV_D)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, w, h), INK)
	return img


static func _tree(v: int) -> Image:
	var img := PA.new_image(84, 120)
	var kind := v % 4
	var pal_src: Array = [GOLD5, COPPER5, BIRCH5, MIX5][kind]
	var pal := PP._palette(pal_src)
	var bark: Array[Color] = [Color("#6a6054"), Color("#9c917f"), Color("#c9bfaa")]
	var cx := 42
	var blobs: Array = []
	var base: Array = [[42, 46, 21], [23, 55, 14], [61, 55, 14], [29, 33, 14], [55, 33, 14], [42, 21, 13], [14, 47, 9], [70, 47, 9], [42, 63, 11]]
	if kind == 2:
		bark = [Color("#8a867b"), Color("#d9d4c6"), Color("#f7f3e8")]
		base = [[42, 42, 13], [33, 55, 10], [52, 54, 10], [36, 30, 10], [49, 28, 10], [42, 17, 8], [40, 66, 7]]
	for i in base.size():
		var b: Array = base[i]
		blobs.append([float(b[0]) + PA.rnd(i, 1, 300 + v) * 4.0 - 2.0, float(b[1]) + PA.rnd(i, 2, 300 + v) * 4.0 - 2.0, float(b[2]) + PA.rnd(i, 3, 300 + v) * 2.0 - 1.0])
	blobs.sort_custom(func(p: Array, q: Array) -> bool: return p[1] < q[1])
	var branch := bark[1]
	if kind == 2:
		PA.line(img, cx, 70, cx - 7, 52, branch)
		PA.line(img, cx + 1, 72, cx + 8, 54, branch)
		PP._trunk(img, cx, 62, 117, 2, 5, 310 + v, bark)
		for k in 9:
			var yy := 70 + int(PA.rnd(k, 1, 315) * 44.0)
			PA.rect(img, cx - 2 + int(PA.rnd(k, 2, 315) * 3.0), yy, 2, 1, Color("#2a2622"))
	else:
		PA.line(img, cx, 68, cx - 12, 50, branch)
		PA.line(img, cx + 1, 68, cx - 11, 50, branch)
		PA.line(img, cx, 70, cx + 13, 52, branch)
		PA.line(img, cx + 1, 70, cx + 14, 52, branch)
		PP._trunk(img, cx, 62, 117, 4, 9, 310 + v, bark)
	PP._canopy(img, blobs, pal, 310 + v, 5)
	PA.outline(img, Rect2i(0, 0, 84, 120), Color("#4a3a38"))
	return img


## Pin sombre de montagne, plus élancé que l'arbre rustique (col des Biscottes).
static func _pine(v: int) -> Image:
	var img := PA.new_image(56, 112)
	var pal := PP._palette(["#0f2a2c", "#1d4a3e", "#2c6b4c", "#4a9058", "#86c26c"])
	PA.rect(img, 26, 90, 4, 21, Color("#4a3426"))
	PA.rect(img, 26, 90, 1, 21, Color("#6d4d38"))
	var idx: Dictionary = {}
	var tiers: Array = [[28, 24, 8, 10], [28, 38, 12, 12], [28, 53, 16, 13], [28, 69, 20, 14], [28, 85, 24, 14]]
	for t: Array in tiers:
		PP._leaf_blob(img, idx, float(t[0]), float(t[1]) + 4.0, float(t[2]), float(t[3]), pal, 330 + v + int(t[1]), 0.0)
	PP._leaf_detail(img, idx, pal, 335 + v, 180)
	PA.outline(img, Rect2i(0, 0, 56, 112), Color("#17262c"))
	return img


static func _hedge(v: int) -> Image:
	var pal := PP._palette(HEDGE5)
	var idx: Dictionary = {}
	var img: Image
	match v % 4:
		0:   # topiaire en cône
			img = PA.new_image(34, 52)
			PA.rect(img, 15, 44, 4, 7, Color("#5b3f2e"))
			PP._leaf_blob(img, idx, 17.0, 36.0, 13.0, 9.0, pal, 341, 0.0)
			PP._leaf_blob(img, idx, 17.0, 24.0, 10.0, 8.0, pal, 342, 0.0)
			PP._leaf_blob(img, idx, 17.0, 13.0, 7.0, 7.0, pal, 343, 0.0)
			PP._leaf_blob(img, idx, 17.0, 5.0, 3.5, 4.0, pal, 344, 0.0)
			PP._leaf_detail(img, idx, pal, 345, 40)
		1:   # haie basse taillée au cordeau, longue
			img = PA.new_image(84, 34)
			_clipped(img, 1, 6, 82, 26, pal, 346)
			for i in 9:
				var x := 4 + int(PA.rnd(i, 1, 347) * 76.0)
				var y := 10 + int(PA.rnd(i, 2, 347) * 16.0)
				PA.px(img, x, y, Color("#fbf8ec"))
				PA.px(img, x + 1, y, Color("#e6e2cc"))
		2:   # boule sur tige
			img = PA.new_image(34, 46)
			PA.rect(img, 15, 30, 3, 15, Color("#5b3f2e"))
			PP._leaf_blob(img, idx, 17.0, 17.0, 14.0, 14.0, pal, 348, 0.0)
			PP._leaf_detail(img, idx, pal, 349, 50)
		_:   # arche de verdure : deux massifs reliés
			img = PA.new_image(60, 50)
			_clipped(img, 1, 14, 16, 35, pal, 350)
			_clipped(img, 43, 14, 16, 35, pal, 351)
			PP._leaf_blob(img, idx, 30.0, 13.0, 25.0, 10.0, pal, 352, 0.0)
			PP._leaf_detail(img, idx, pal, 353, 60)
	PA.outline(img, Rect2i(0, 0, img.get_width(), img.get_height()), Color("#1a3a30"))
	return img


## Bloc de verdure taillé : dessus clair, flanc gauche éclairé, flanc droit sombre.
static func _clipped(img: Image, x: int, y: int, w: int, h: int, pal: Array[Color], sd: int) -> void:
	for yy in range(y, y + h):
		for xx in range(x, x + w):
			var k := 2
			if yy < y + 4:
				k = 3
			elif xx < x + 2:
				k = 3
			elif xx > x + w - 4 or yy > y + h - 4:
				k = 1
			var n := PA.rnd(xx, yy, sd)
			if n < 0.14:
				k = maxi(0, k - 1)
			elif n > 0.9:
				k = mini(4, k + 1)
			PA.px(img, xx, yy, pal[k])
	PA.rect(img, x, y, w, 1, pal[4])


static func _bench() -> Image:
	var img := PA.new_image(60, 32)
	_stone_box(img, 4, 8, 52, 7, IV_L)           # assise
	PA.rect(img, 4, 15, 52, 2, IV_S)
	for x: int in [7, 47]:
		_stone_box(img, x, 17, 6, 13, IV)        # pieds en volute
		PA.rect(img, x - 2, 28, 10, 3, IV)
		PA.px(img, x - 2, 28, IV_L)
	_stone_box(img, 2, 5, 6, 5, IV_L)
	_stone_box(img, 52, 5, 6, 5, IV_L)
	for i in 3:
		_leaf_px(img, 20 + i * 8, 7, Color("#e0a63e") if i != 1 else Color("#bd6f2c"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 60, 32), INK)
	return img


static func _statue(v: int) -> Image:
	var img := PA.new_image(30, 84)
	_stone_box(img, 4, 68, 22, 16, IV)
	PA.rect(img, 6, 70, 18, 1, IV_D)
	_stone_box(img, 2, 64, 26, 5, IV_L)
	# robe et manteau
	PP._poly(img, [Vector2(8, 66), Vector2(22, 66), Vector2(19, 36), Vector2(11, 36)], IV_L)
	PP._poly(img, [Vector2(16, 66), Vector2(22, 66), Vector2(20, 36), Vector2(16, 36)], IV_S)
	PP._poly(img, [Vector2(6, 64), Vector2(11, 38), Vector2(10, 62)], IV)
	for k in 5:
		PA.rect(img, 11 + k * 2, 44 + k, 1, 20, IV_D)
	PA.rect(img, 11, 50, 9, 2, GOLD_D)     # ceinture
	# tête, longs cheveux, oreille pointue
	PA.ellipse(img, 15.0, 29.0, 4.5, 5.0, IV_HI)
	PP._poly(img, [Vector2(10, 27), Vector2(20, 27), Vector2(22, 44), Vector2(9, 44)], IV_S)
	PA.ellipse(img, 15.0, 29.0, 4.0, 4.6, IV_HI)
	PA.px(img, 19, 28, IV_L)
	PA.px(img, 20, 27, IV_L)
	# bras levé et lanterne d'argent
	PA.line(img, 19, 38, 23, 24, IV_L)
	PA.line(img, 20, 38, 24, 24, IV)
	PA.ellipse(img, 24.0, 20.0, 4.0, 4.0, Color("#c9e6ff") if v == 0 else Color("#fbe9b0"))
	PA.ellipse(img, 23.0, 19.0, 2.0, 2.0, Color("#ffffff"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 30, 84), INK)
	return img


static func _fountain() -> Image:
	var img := PA.new_image(76, 72)
	var water := Color("#8cc9d8")
	# vasque basse
	PA.ellipse(img, 38.0, 56.0, 36.0, 15.0, IV_S)
	PA.ellipse(img, 38.0, 53.0, 36.0, 15.0, IV_L)
	PA.ellipse(img, 38.0, 54.0, 31.0, 12.0, water)
	PA.ellipse(img, 36.0, 52.0, 24.0, 8.0, Color("#a8dce6"))
	for i in 14:
		var x := 14 + int(PA.rnd(i, 1, 361) * 48.0)
		var y := 50 + int(PA.rnd(i, 2, 361) * 9.0)
		PA.rect(img, x, y, 3, 1, Color("#e8f8ff"))
	# fût et coupe haute
	_stone_box(img, 34, 30, 8, 22, IV)
	PA.ellipse(img, 38.0, 32.0, 14.0, 5.0, IV_L)
	PA.ellipse(img, 38.0, 32.0, 11.0, 3.5, water)
	PA.ellipse(img, 38.0, 24.0, 6.0, 3.0, IV_L)
	PA.rect(img, 37, 6, 2, 20, IV_L)
	# jets
	for k in 6:
		var y := 8 + k * 3
		var dx := int(sin(float(k) * 0.9) * (1 + k / 2))
		PA.px(img, 38 - dx - 3, y + 6, Color("#e8f8ff"))
		PA.px(img, 38 + dx + 3, y + 6, Color("#cfeefa"))
	PA.ellipse(img, 38.0, 5.0, 2.0, 2.0, Color("#ffffff"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 76, 72), INK)
	return img


## Pupitre : plan incliné de bois pâle, feuillet, plume. v = 1 : pupitre double.
static func _desk(v: int) -> Image:
	var w := 40 if v == 0 else 66
	var img := PA.new_image(w, 52)
	var legs: Array = [5, w - 9] if v == 0 else [4, 30, w - 8]
	for x: int in legs:
		PA.rect(img, x, 30, 4, 21, WOOD)
		PA.rect(img, x, 30, 1, 21, WOOD_L)
		PA.rect(img, x + 3, 30, 1, 21, WOOD_D)
	PA.rect(img, 3, 46, w - 6, 3, WOOD_D)
	PP._poly(img, [Vector2(1, 30), Vector2(w - 1, 30), Vector2(w - 4, 14), Vector2(4, 14)], WOOD_L)
	PA.rect(img, 1, 30, w - 2, 3, WOOD)
	PA.rect(img, 1, 32, w - 2, 1, WOOD_D)
	var sheets := 1 if v == 0 else 3
	for s in sheets:
		var x0 := 8 + s * 20
		PP._poly(img, [Vector2(x0, 27), Vector2(x0 + 14, 27), Vector2(x0 + 12, 17), Vector2(x0 + 2, 17)], Color("#fbf6e4"))
		for k in 3:
			PA.rect(img, x0 + 3, 19 + k * 3, 7 - k, 1, Color("#9aa0b8"))
	PA.line(img, w - 9, 14, w - 3, 4, Color("#f4f1e6"))        # plume
	PA.line(img, w - 8, 14, w - 2, 4, Color("#d6d0c0"))
	PA.px(img, w - 9, 15, Color("#2a2a40"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, w, 52), Color("#5a4c38"))
	return img


## Pile de formulaires : feuillets décalés, ruban, cachet de cire. v = 0 petite pile, 1 haute, 2 pile et tampon.
static func _forms(v: int) -> Image:
	var img := PA.new_image(30, 34)
	var n := 5 + v * 3
	var top := 31
	for k in n:
		var y := 30 - k * 2 if v < 2 else 30 - k * 2
		var dx := int((PA.rnd(k, 1, 371) - 0.5) * 4.0)
		var c := Color("#fbf6e4") if k % 2 == 0 else Color("#efe8d2")
		PA.rect(img, 4 + dx, y, 20, 3, c)
		PA.rect(img, 4 + dx, y + 2, 20, 1, Color("#b9b3a0"))
		PA.px(img, 4 + dx, y, Color("#ffffff"))
		top = y
	PA.rect(img, 13, top, 3, 31 - top + 1, Color("#7a8fbf"))     # ruban
	PA.ellipse(img, 14.0, float(top), 3.0, 2.0, Color("#b8453c"))
	PA.px(img, 13, top - 1, Color("#e0786a"))
	if v == 2:
		PA.rect(img, 21, top - 6, 5, 3, Color("#7a4a2e"))      # le tampon
		PA.rect(img, 22, top - 3, 3, 5, Color("#4a2e1c"))
		PA.rect(img, 22, top + 1, 3, 1, Color("#b8453c"))
	PA.outline(img, Rect2i(0, 0, 30, 34), Color("#5a5b78"))
	return img


static func _stamp() -> Image:
	var img := PA.new_image(18, 20)
	PA.rect(img, 6, 2, 6, 8, Color("#7a4a2e"))
	PA.rect(img, 6, 2, 1, 8, Color("#a8704a"))
	PA.rect(img, 3, 10, 12, 5, Color("#4a2e1c"))
	PA.rect(img, 3, 14, 12, 2, Color("#b8453c"))
	PA.outline(img, Rect2i(0, 0, 18, 20), Color("#3a2a20"))
	return img


## Siège du Conseil : haut dossier en ogive sculpté de feuilles, coussin de velours. v = 1 : siège d'Elrond, plus haut, doré.
static func _seat(v: int) -> Image:
	var h := 56 if v == 0 else 68
	var img := PA.new_image(34, h)
	var wood := WOOD_L if v == 0 else Color("#f4e6bc")
	_fill_ogive(img, 17.0, h - 32, 12.0, 19.0, wood, h - 20)
	_fill_ogive(img, 17.0, h - 32, 9.0, 15.0, Color("#6a86b0") if v == 0 else Color("#8a4a5a"), h - 22)
	# nervures dorées
	PA.rect(img, 16, 6, 2, h - 28, GOLD)
	for k in 3:
		PA.rect(img, 13, h - 40 + k * 5, 8, 1, GOLD_D)
	# assise, coussin, pieds
	PA.rect(img, 3, h - 20, 28, 5, wood)
	PA.rect(img, 3, h - 20, 28, 1, IV_HI)
	PA.rect(img, 5, h - 24, 24, 5, Color("#7a96c0") if v == 0 else Color("#a85a6a"))
	PA.rect(img, 5, h - 24, 24, 1, Color("#b4c8e4") if v == 0 else Color("#d88a98"))
	PA.rect(img, 4, h - 15, 3, 14, WOOD_D)
	PA.rect(img, 27, h - 15, 3, 14, WOOD_D)
	PA.rect(img, 4, h - 15, 1, 14, wood)
	PA.rect(img, 3, h - 16, 28, 2, GOLD_D)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 34, h), Color("#5a4c38"))
	return img


static func _bookcase(v: int) -> Image:
	var img := PA.new_image(58, 92)
	_fill_ogive(img, 29.0, 36, 26.0, 40.0, WOOD, 91)
	_fill_ogive(img, 29.0, 36, 23.0, 35.0, Color("#5a4a38"), 88)
	var cols: Array[Color] = [Color("#6d86a8"), Color("#a8503c"), Color("#d8c690"), Color("#5c8a6a"), Color("#8a6aa0"), Color("#c89a48"), Color("#e8e0cc")]
	var shelf_y: Array[int] = [30, 46, 62, 78]
	for r in 4:
		var yb := shelf_y[r] + 12
		var x := 8
		while x < 50:
			var wd := 1 + int(PA.rnd(x, r, 381 + v) * 3.0)
			var hh := 9 - int(PA.rnd(x, r + 9, 382 + v) * 5.0)
			var c: Color = cols[int(PA.rnd(x, r + 3, 383 + v) * cols.size()) % cols.size()]
			if v == 2 and r == 1:
				c = Color("#e8e0cc")   # un rang de rouleaux
			PA.rect(img, x, yb - hh, wd, hh, c)
			PA.px(img, x, yb - hh, PA.shade(c, 0.2))
			x += wd
		PA.rect(img, 6, yb, 46, 2, WOOD_L)
		PA.rect(img, 6, yb + 1, 46, 1, WOOD_D)
	PA.rect(img, 4, 0, 1, 1, WOOD)
	_leaf_px(img, 28, 10, GOLD)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 58, 92), Color("#5a4c38"))
	return img


## Table de bois pâle. v = 0 ronde (service à thé), v = 1 longue (piles de papiers).
static func _table(v: int) -> Image:
	var w := 52 if v == 0 else 84
	var img := PA.new_image(w, 40)
	for x: int in ([10, w - 14] if v == 0 else [6, 30, 52, w - 10]):
		PA.rect(img, x, 20, 4, 19, WOOD_D)
		PA.rect(img, x, 20, 1, 19, WOOD)
	PA.ellipse(img, float(w) * 0.5, 17.0, float(w) * 0.5 - 1.0, 12.0, WOOD_D)
	PA.ellipse(img, float(w) * 0.5, 15.0, float(w) * 0.5 - 1.0, 12.0, WOOD_L)
	PA.ellipse(img, float(w) * 0.5 - 2.0, 14.0, float(w) * 0.5 - 6.0, 8.0, Color("#f3e6c4"))
	if v == 0:
		PA.rect(img, 20, 8, 8, 6, Color("#fbf8ee"))     # théière
		PA.rect(img, 28, 9, 3, 2, Color("#fbf8ee"))
		PA.rect(img, 21, 6, 6, 2, Color("#c9a24a"))
		PA.rect(img, 31, 13, 5, 3, Color("#fbf8ee"))
	else:
		for k in 3:
			PA.rect(img, 14 + k * 22, 7, 14, 4, Color("#fbf6e4"))
			PA.rect(img, 14 + k * 22, 10, 14, 1, Color("#b9b3a0"))
			PA.px(img, 20 + k * 22, 6, Color("#b8453c"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, w, 40), Color("#5a4c38"))
	return img


static func _flowers(v: int) -> Image:
	var img := PA.new_image(36, 26)
	PA.ellipse(img, 18.0, 20.0, 16.0, 5.0, Color("#4a7a3a"))
	for i in 11:
		var x := 4 + int(PA.rnd(i, 1, 391 + v) * 28.0)
		var y := 6 + int(PA.rnd(i, 2, 391 + v) * 12.0)
		PA.rect(img, x, y + 2, 1, 14 - (y - 6), Color("#4f8a3e"))
		var petal := Color("#fbf8ee") if v != 2 or i % 2 == 0 else Color("#c8d8f4")
		if v == 1 and i % 3 == 0:
			petal = Color("#f6e6a0")
		PA.rect(img, x - 1, y, 3, 3, petal)
		PA.px(img, x, y + 1, GOLD)
		PA.px(img, x - 1, y, IV_HI)
	PA.outline(img, Rect2i(0, 0, 36, 26), Color("#2f5030"))
	return img


static func _leaves(v: int) -> Image:
	var img := PA.new_image(38, 14)
	for i in 22:
		var x := 2 + int(PA.rnd(i, 1, 401 + v) * 32.0)
		var y := 2 + int(PA.rnd(i, 2, 401 + v) * 8.0)
		var c: Color = [Color("#e0a63e"), Color("#c4672c"), Color("#f2c85a"), Color("#a8522a")][i % 4]
		PA.rect(img, x, y, 3, 2, c)
		PA.px(img, x, y, PA.shade(c, 0.2))
		PA.px(img, x + 2, y + 1, PA.shade(c, -0.25))
	return img


## Grande arche d'entrée : deux faisceaux de colonnettes, ogive élancée, clef feuillue, lierre.
## v = 0 monumentale (col des Biscottes, vallée) ; v = 1 portail plus modeste.
static func _gate(v: int) -> Image:
	var w := 176 if v == 0 else 128
	var h := 138 if v == 0 else 112
	var img := PA.new_image(w, h)
	var pier := 26 if v == 0 else 20
	var a := float(w) * 0.5 - float(pier)
	var rr := a * 1.75
	var spring := int(float(h) * 0.5)
	PA.rect(img, 0, 0, w, h, IV)
	var cx := float(w) * 0.5
	_fill_ogive(img, cx, spring, a + 4.0, rr + 4.0, IV_HI, h)
	_fill_ogive(img, cx, spring, a, rr, Color(0, 0, 0, 0), h)
	# piles : faisceau de trois colonnettes nervurées
	for side in 2:
		var x0 := 0 if side == 0 else w - pier
		_stone_box(img, x0, h - 12, pier, 12, IV)
		for k in 3:
			var cxk := x0 + 4 + k * (pier - 8) / 2
			for y in range(spring - 6, h - 12):
				for x in range(cxk - 3, cxk + 4):
					var u := float(x - (cxk - 3)) / 6.0
					var c := IV_L if u < 0.3 else (IV if u < 0.7 else IV_S)
					if (x - cxk) % 3 == 0:
						c = PA.shade(c, -0.08)
					PA.px(img, x, y, c)
			PA.rect(img, cxk - 4, spring - 10, 9, 5, IV_L)
			PA.rect(img, cxk - 4, spring - 6, 9, 1, IV_D)
	# frise et corniche
	PA.rect(img, 0, 0, w, 7, IV_L)
	PA.rect(img, 0, 7, w, 1, IV_S)
	PA.rect(img, 0, 8, w, 2, GOLD)
	PA.rect(img, 0, 10, w, 1, GOLD_D)
	for x in range(3, w, 7):
		PA.px(img, x, 3, LEAF_G)
		PA.px(img, x + 1, 4, Color("#5c8840"))
	# clef : feuille dorée au sommet de l'ogive
	var ky := spring - int(sqrt(rr * rr - (rr - a) * (rr - a))) - 2
	PP._poly(img, [Vector2(cx, float(ky) - 9), Vector2(cx + 5, float(ky) + 1), Vector2(cx, float(ky) + 6), Vector2(cx - 5, float(ky) + 1)], GOLD)
	PA.line(img, int(cx), ky - 7, int(cx), ky + 4, GOLD_D)
	# lierre qui retombe de la corniche
	for i in 9:
		var x := 6 + int(PA.rnd(i, 1, 411 + v) * float(w - 12))
		var n := 8 + int(PA.rnd(i, 2, 411 + v) * 26.0)
		for k in n:
			var xx := x + int(round(sin(float(k) * 0.7) * 1.5))
			var c := Color("#5f8c3e") if k % 4 != 0 else Color("#d9a03c")
			if img.get_pixel(clampi(xx, 0, w - 1), 11 + k).a > 0.5:
				PA.px(img, xx, 11 + k, c)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, w, h), INK)
	return img


static func _banner(v: int) -> Image:
	var img := PA.new_image(20, 64)
	var cloth := Color("#e9e2cc") if v == 0 else Color("#7f9ec0")
	PA.rect(img, 1, 1, 18, 2, GOLD_D)
	PA.rect(img, 0, 0, 2, 3, GOLD)
	PA.rect(img, 18, 0, 2, 3, GOLD)
	PP._poly(img, [Vector2(3, 3), Vector2(17, 3), Vector2(17, 56), Vector2(10, 62), Vector2(3, 56)], cloth)
	PP._poly(img, [Vector2(3, 3), Vector2(6, 3), Vector2(6, 58), Vector2(3, 56)], PA.shade(cloth, 0.12))
	PP._poly(img, [Vector2(14, 3), Vector2(17, 3), Vector2(17, 56), Vector2(14, 58)], PA.shade(cloth, -0.14))
	# feuille brodée
	PP._poly(img, [Vector2(10, 14), Vector2(15, 26), Vector2(10, 38), Vector2(5, 26)], GOLD)
	PA.line(img, 10, 16, 10, 38, GOLD_D)
	PA.line(img, 10, 26, 14, 24, GOLD_D)
	PA.line(img, 10, 30, 6, 28, GOLD_D)
	PA.outline(img, Rect2i(0, 0, 20, 64), Color("#5a4c38"))
	return img


static func _urn(v: int) -> Image:
	var img := PA.new_image(24, 40)
	PP._poly(img, [Vector2(7, 38), Vector2(17, 38), Vector2(20, 24), Vector2(17, 16), Vector2(7, 16), Vector2(4, 24)], IV_L)
	PP._poly(img, [Vector2(14, 38), Vector2(17, 38), Vector2(20, 24), Vector2(17, 16), Vector2(14, 16)], IV_S)
	PA.rect(img, 6, 14, 12, 3, IV)
	PA.rect(img, 5, 37, 14, 3, IV_S)
	PA.rect(img, 9, 24, 6, 1, GOLD)
	# feuillage et fleurs
	for i in 9:
		var x := 6 + int(PA.rnd(i, 1, 421 + v) * 12.0)
		var y := 2 + int(PA.rnd(i, 2, 421 + v) * 11.0)
		PA.rect(img, x, y, 2, 2, Color("#4f8a3e") if i % 2 == 0 else Color("#7aa650"))
		if i % 3 == 0:
			PA.rect(img, x, y - 2, 3, 3, Color("#fbf8ee") if v == 0 else Color("#e8a93c"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 24, 40), INK)
	return img


## Pergola : deux piliers et un treillis chargé de glycine ; on passe dessous.
static func _pergola() -> Image:
	var img := PA.new_image(120, 104)
	for x: int in [4, 104]:
		for y in range(14, 102):
			PA.rect(img, x, y, 10, 1, IV if (y / 6) % 2 == 0 else IV_L)
		PA.rect(img, x, 14, 1, 88, IV_L)
		PA.rect(img, x + 9, 14, 1, 88, IV_S)
		_stone_box(img, x - 2, 96, 14, 8, IV)
	for x in range(0, 120, 12):
		PA.rect(img, x, 6, 4, 14, WOOD)
		PA.rect(img, x, 6, 1, 14, WOOD_L)
	PA.rect(img, 0, 10, 120, 5, WOOD_L)
	PA.rect(img, 0, 15, 120, 1, WOOD_D)
	for i in 60:
		var x := int(PA.rnd(i, 1, 431) * 118.0)
		var y := 4 + int(PA.rnd(i, 2, 431) * 24.0)
		var c := Color("#5f8c3e") if i % 3 != 0 else (Color("#e0a63e") if i % 3 == 1 else Color("#f2ede0"))
		PA.rect(img, x, y, 2, 2, c)
		if i % 4 == 0:
			for k in 6 + int(PA.rnd(i, 3, 431) * 10.0):
				PA.px(img, clampi(x + (k % 2), 0, 119), y + k, Color("#5f8c3e") if k % 3 != 0 else Color("#fbf8ee"))
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, 120, 104), INK)
	return img


## Face d'un pont à une arche, vue de la berge : parapet bas, arche brisée qui laisse passer l'eau.
static func _bridge_face() -> Image:
	var w := 96
	var h := 44
	var img := PA.new_image(w, h)
	_stone_box(img, 0, 0, w, 8, IV_L)                 # parapet
	for x in range(6, w - 4, 10):
		PA.rect(img, x, 1, 1, 7, IV_S)
	PA.rect(img, 0, 8, w, h - 8, IV)
	for y in range(10, h, 6):
		PA.rect(img, 0, y, w, 1, IV_S)
		for x in range(4 + (y / 6 % 2) * 6, w, 12):
			PA.rect(img, x, y, 1, 6, IV_S)
	var a := 23.0
	_fill_ogive(img, float(w) * 0.5, 30, a + 3.0, 40.0, IV_HI, h)
	_fill_ogive(img, float(w) * 0.5, 30, a, 37.0, Color(0, 0, 0, 0), h)
	PA.relief(img)
	PA.outline(img, Rect2i(0, 0, w, h), INK)
	return img


## Rideau de lierre et de glycine, à poser contre un mur ou une falaise.
static func _ivy_curtain(v: int) -> Image:
	var img := PA.new_image(40, 72)
	for i in 6:
		var x := 3 + int(PA.rnd(i, 1, 441 + v) * 34.0)
		var n := 20 + int(PA.rnd(i, 2, 441 + v) * 50.0)
		for k in n:
			var xx := x + int(round(sin(float(k) * 0.5 + float(i)) * 2.0))
			PA.px(img, xx, k, Color("#4f7a38"))
			if k % 3 == 0:
				var c := Color("#6f9a46") if (k + i) % 4 != 0 else (Color("#e0a63e") if v == 0 else Color("#f2ede0"))
				PA.rect(img, xx - 1, k, 3, 2, c)
	PA.outline(img, Rect2i(0, 0, 40, 72), Color("#2a4a2c"))
	return img


# ---------------------------------------------------------------- façades 2D

## Façade avant d'un pavillon : pierre ivoire, pilastres, baies en ogive, porte en ogive.
## door_open : arche ouverte sur un intérieur éclairé ; sinon, doubles portes de bois pâle.
## Renvoie {"albedo": Image, "emission": Image}.
static func facade(w_units: float, h_units: float, door_x: float, windows: Array, lit: bool, door_open: bool, tall: bool) -> Dictionary:
	var w := int(round(w_units * 24.0))
	var h := int(round(h_units * 24.0))
	var img := PA.new_image(w, h)
	var emi := PA.new_image(w, h)
	emi.fill(Color.BLACK)
	TP._fill_tiled(img, paint_tile("elf_stone"))
	# assises : un ton légèrement plus clair vers le haut
	for y in h:
		if y % 17 == 0:
			PA.rect(img, 0, y, w, 1, PA.shade(IV, -0.08))
	# plinthe moulurée
	PA.rect(img, 0, h - 9, w, 9, IV_S)
	PA.rect(img, 0, h - 9, w, 1, IV_L)
	PA.rect(img, 0, h - 4, w, 1, IV_D)
	# corniche et frise
	PA.rect(img, 0, 0, w, 6, IV_L)
	PA.rect(img, 0, 6, w, 1, IV_S)
	PA.rect(img, 0, 7, w, 1, GOLD)
	PA.rect(img, 0, 8, w, 1, GOLD_D)
	for x in range(2, w, 6):
		PA.px(img, x, 3, LEAF_G)
		PA.px(img, x + 1, 4, Color("#5c8840"))
	var spots: Array[float] = []
	for wx: Variant in windows:
		spots.append(float(wx) * 24.0)
	if door_x >= 0.0:
		spots.append(door_x * 24.0)
	spots.sort()
	# pilastres aux angles et entre les ouvertures
	var posts: Array[int] = [0, w - 6]
	for k in range(spots.size() - 1):
		if spots[k + 1] - spots[k] >= 40.0:
			posts.append(int((spots[k] + spots[k + 1]) * 0.5) - 3)
	for px: int in posts:
		_pilaster(img, px, 9, h - 18)
	for wx: Variant in windows:
		_window(img, emi, float(wx) * 24.0, h, lit, tall)
	if door_x >= 0.0:
		_door(img, emi, door_x * 24.0, h, door_open, lit)
	return {"albedo": img, "emission": emi}


static func _pilaster(img: Image, x: int, y0: int, hh: int) -> void:
	for y in range(y0, y0 + hh):
		for xx in range(x, x + 6):
			var u := xx - x
			var c := IV_HI if u == 0 else (IV_L if u < 3 else (IV_S if u < 5 else IV_D))
			PA.px(img, xx, y, c)
	PA.rect(img, x - 1, y0, 8, 3, IV_L)
	PA.rect(img, x - 1, y0 + 3, 8, 1, IV_D)
	PA.rect(img, x - 1, y0 + hh - 3, 8, 3, IV_L)
	PA.rect(img, x - 1, y0 + hh - 1, 8, 1, IV_D)


## Baie en ogive : moulure claire, vitrail d'un bleu pâle (ou doré quand c'est allumé), meneau, oculus.
static func _window(img: Image, emi: Image, cx: float, h: int, lit: bool, tall: bool) -> void:
	var a := 9.0
	var rr := 15.0
	var sill := h - 22 if not tall else h - 12
	var spring := sill - (24 if not tall else 34)
	_fill_ogive(img, cx, spring, a + 2.0, rr + 2.0, IV_HI, sill + 2)
	_fill_ogive(img, cx, spring, a, rr, Color("#7a96ba"), sill)
	if lit:
		_fill_ogive(emi, cx, spring, a - 1.0, rr - 1.0, Color("#b89a58") if not tall else Color("#c4a864"), sill - 1)
	# reflets et meneau
	for y in range(spring - 8, sill):
		PA.px(img, int(cx) - 5, y, Color("#a8c2e0"))
	PA.rect(img, int(cx), spring - 12, 1, sill - spring + 12, IV_L)
	PA.rect(img, int(cx) - int(a), spring + 7, int(a) * 2, 1, IV_L)
	PA.ellipse(img, cx, float(spring) - 2.0, 2.5, 2.5, IV_L)
	PA.px(img, int(cx), spring - 2, GOLD)
	# appui de pierre et balustrade basse pour les baies hautes
	PA.rect(img, int(cx) - 12, sill, 24, 3, IV_L)
	PA.rect(img, int(cx) - 12, sill + 3, 24, 1, IV_D)
	if tall:
		for x in range(int(cx) - 10, int(cx) + 10, 4):
			PA.rect(img, x, sill - 8, 2, 8, IV)
			PA.px(img, x, sill - 8, IV_HI)
		PA.rect(img, int(cx) - 11, sill - 9, 22, 2, IV_L)


static func _door(img: Image, emi: Image, cx: float, h: int, open: bool, lit: bool) -> void:
	var hd := mini(int(float(h) * 0.82), 84)
	var a := 14.0
	var rr := 23.0
	var rise := int(sqrt(rr * rr - (rr - a) * (rr - a)))
	var spring := h - 6 - (hd - rise)
	var x0 := int(cx) - int(a) - 3
	# marches
	PA.rect(img, x0 - 3, h - 6, int(a) * 2 + 12, 3, IV_L)
	PA.rect(img, x0 - 5, h - 3, int(a) * 2 + 16, 3, IV)
	_fill_ogive(img, cx, spring, a + 3.0, rr + 3.0, IV_HI, h - 6)
	if open:
		# arche ouverte : on devine une salle claire, avec un dallage et des arcatures au fond
		_fill_ogive(img, cx, spring, a, rr, Color("#4f5372"), h - 6)
		for y in range(spring - rise, h - 6):
			var k := clampf(float(y - (spring - rise)) / float(hd), 0.0, 1.0)
			var c := Color("#5a5f84").lerp(Color("#d8b878"), k * k)
			var dy := float(spring - y)
			var hw := a if dy <= 0.0 else _ogive_hw(a, rr, dy + 0.5)
			if hw <= 0.0:
				continue
			PA.rect(img, int(round(cx - hw)), y, int(round(hw * 2.0)), 1, c)
		_fill_ogive(img, cx, spring + 14, 6.0, 12.0, Color("#2e3150"), h - 14)
		if lit:
			_fill_ogive(emi, cx, spring, a - 2.0, rr - 2.0, Color("#a8864a"), h - 7)
	else:
		_fill_ogive(img, cx, spring, a, rr, Color("#d6c196"), h - 6)
		_fill_ogive(img, cx, spring, a - 2.0, rr - 2.0, Color("#e4d2a8"), h - 6)
		PA.rect(img, int(cx), spring - rise, 1, hd, WOOD_D)           # jonction des vantaux
		for k in 4:
			var yy := spring + k * 11
			for s: int in [-1, 1]:
				_leaf_px(img, int(cx) + s * 6 - 1, yy, LEAF_G if k % 2 == 0 else GOLD_D)
		PA.rect(img, int(cx) - 2, spring + 22, 1, 3, GOLD)
		PA.rect(img, int(cx) + 2, spring + 22, 1, 3, GOLD)
	PA.rect(img, int(cx) - int(a) - 4, h - 6 - hd + rise - 6, 1, 1, GOLD)
	# lumière d'entrée : le bord gauche de l'ogive est à l'ombre
	for y in range(spring, h - 6):
		PA.px(img, int(round(cx - a)), y, PA.shade(IV, -0.3))
		PA.px(img, int(round(cx - a)) + 1, y, PA.shade(IV, -0.18))


## Médaillon de dallage (décalque au sol) : anneaux d'or et étoile de feuilles. Hors disque : transparent.
static func medallion(radius_units: float) -> Image:
	var px := int(radius_units * 24.0)
	var img := PA.new_image(px * 2, px * 2)
	for y in px * 2:
		for x in px * 2:
			var dx := float(x) + 0.5 - float(px)
			var dy := float(y) + 0.5 - float(px)
			var r := sqrt(dx * dx + dy * dy) / float(px)
			if r > 1.0:
				continue
			var th := atan2(dy, dx)
			var c := Color("#dcd6c4")
			if r > 0.9:
				c = Color("#c9c1ab")
			elif r > 0.82:
				c = GOLD
			elif r > 0.74:
				c = Color("#e9e3d0")
			elif r > 0.66:
				c = GOLD_D
			else:
				var petals := absf(sin(th * 4.0))
				var leaf := r < 0.15 + 0.5 * pow(petals, 2.0)
				c = Color("#9fb4d6") if leaf else Color("#ece6d4")
				if r < 0.1:
					c = GOLD
				elif leaf and absf(sin(th * 8.0)) < 0.08:
					c = Color("#7f96bc")
			if PA.rnd(x, y, 451) < 0.05:
				c = PA.shade(c, -0.05)
			img.set_pixel(x, y, c)
	return img
