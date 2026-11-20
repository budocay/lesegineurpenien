extends RefCounted
## Monstres du chapitre 7 : les Noyés du Bouillon, les Ologrills (et le Grand Ologrill), les
## Fileuses et l'Arachnée, les Convives Insatiables, les Marcheurs Infatigables, les Nazes du
## Service et le Grand Œil. Mêmes règles que gouda_monsters.gd (poses, regard vers la droite,
## rampes de cinq tons, lumière en haut à gauche) dont ce fichier réutilise les outils.
## Appelé depuis `MonsterPainter._render` par `MM.paint(kind, img, ox, f, col, size)`.
## Les bosses Bouche du Maître et Sauron en pleine Vigueur sont dans boss_painter.gd.

const PA = preload("res://src/gfx/pixel_art.gd")
const MP = preload("res://src/gfx/monster_painter.gd")
const GM = preload("res://src/gfx/gouda_monsters.gd")

const KINDS: Array[String] = ["noye", "ologrill", "grand_ologrill", "fileuse", "arachnee", "convive", "marcheur",
		"naze_service", "grand_oeil"]

const SIZES := {
	"noye": Vector2i(48, 64), "ologrill": Vector2i(56, 68), "grand_ologrill": Vector2i(96, 108),
	"fileuse": Vector2i(56, 40), "arachnee": Vector2i(112, 84), "convive": Vector2i(60, 68),
	"marcheur": Vector2i(48, 70), "naze_service": Vector2i(52, 68), "grand_oeil": Vector2i(92, 100),
}

const INK := Color("#1c1222")


static func paint(kind: String, img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	match kind:
		"noye": GM._ghost(img, ox, f, col, size, {"skin": "#7ea090", "gown": "#46685a", "eye": "#e8e8a0", "cap": "#2e5a46", "light": false})
		"ologrill": GM._man(img, ox, f, col, size, {"skin": "#8a9a5e", "cloth": "#e8e4d8", "trim": "#8a2a2a", "pants": "#4a3a2a",
				"head": "marmite", "weapon": "massue", "head_c": "#8a8a98", "big": true, "scar": true})
		"grand_ologrill": GM._man(img, ox, f, col, size, {"skin": "#7a8a4e", "cloth": "#f2eee4", "trim": "#a82a2a", "pants": "#3a2a22",
				"head": "marmite", "weapon": "massue", "head_c": "#a8a8b8", "big": true, "scar": true, "beard": "#3a2a1e"})
		"fileuse": _spider(img, ox, f, col, size, {"body": "#4a4658", "mark": "#c8c4d8", "eye": "#ff5a4a", "scale": 0.5})
		"arachnee": _spider(img, ox, f, col, size, {"body": "#2e2a3a", "mark": "#e8c050", "eye": "#ffd070", "scale": 1.0, "crown": true})
		"convive": GM._man(img, ox, f, col, size, {"skin": "#d8a888", "cloth": "#7a2a3a", "trim": "#f2eee4", "pants": "#2a2230",
				"head": "bandana", "weapon": "lance", "head_c": "#f2eee4", "big": true, "stripe": false})
		"marcheur": GM._man(img, ox, f, col, size, {"skin": "#a8a098", "cloth": "#5a5a66", "trim": "#c8c4b8", "pants": "#3a3a46",
				"head": "bandana", "weapon": "lance", "head_c": "#7a7a88", "patch": false})
		"naze_service": GM._man(img, ox, f, col, size, {"skin": "#2a2634", "cloth": "#1c1a26", "trim": "#e8e4d8", "pants": "#0c0a10",
				"head": "marmite", "weapon": "sabre", "head_c": "#ece8dc", "coat": true})
		"grand_oeil": _eyeball(img, ox, f, col, size)
		_: MP._rect(img, ox + 4, 4, size.x - 8, size.y - 8, Color.MAGENTA)


## Araignée vue de profil, regard à droite : abdomen rond à marque dorée, tête, huit pattes
## articulées (quatre derrière, plus sombres), crochets. `scale` rapetisse la Fileuse ; `crown` pose
## sur l'Arachnée sa couronne de toque à plis.
static func _spider(img: Image, ox: int, f: int, col: int, size: Vector2i, p: Dictionary) -> void:
	var w := float(size.x)
	var h := float(size.y)
	var dy := float(f) * 0.9
	var body := MP._ramp(str(p["body"]))
	var dark := MP._dim(body)
	var mark := MP._ramp(str(p["mark"]))
	var lunge := w * 0.06 if col == 2 else (-w * 0.03 if col == 3 else 0.0)
	var cy := h * 0.46 + dy
	# pattes : quatre de chaque côté, la moitié arrière dans l'ombre
	for side in 2:
		var near := side == 1
		var r: Array = body if near else dark
		for i in 4:
			var bx := ox + w * (0.4 + float(i) * 0.07) + lunge * 0.5
			var by := cy + h * 0.02
			var spread := (float(i) - 1.5) * w * 0.12 + (w * 0.03 if near else -w * 0.02)
			var kx := bx + spread * 1.3
			var ky := cy - h * (0.3 + float(i % 2) * 0.06) - (0.0 if near else h * 0.04)
			var fx := bx + spread * 2.2
			var fy := h * 0.93 - (0.0 if near else h * 0.04)
			GM._cp(img, bx, by, kx, ky, w * 0.016, w * 0.013, r)
			GM._cp(img, kx, ky, fx, fy, w * 0.013, w * 0.006, r)
	# abdomen
	GM._o(img, ox + w * 0.3 + lunge * 0.4, cy, w * 0.26, h * 0.3, body, 0.0)
	for k in 5:
		var a := float(k) * 0.5 - 1.0
		GM._o(img, ox + w * 0.3 + lunge * 0.4 + a * w * 0.1, cy - h * 0.05 + absf(a) * h * 0.06, w * 0.035, h * 0.05, mark, 0.1)
	GM._o(img, ox + w * 0.3 + lunge * 0.4, cy + h * 0.05, w * 0.05, h * 0.1, mark, 0.1)
	# céphalothorax et tête
	var hx := ox + w * 0.64 + lunge
	GM._o(img, hx, cy + h * 0.02, w * 0.17, h * 0.2, body, 0.1)
	for e in 4:
		var ex := hx + w * (0.04 + float(e % 2) * 0.05)
		var ey := cy - h * (0.07 - float(e / 2) * 0.07)
		var er := w * (0.028 if e < 2 else 0.018)
		if col == 3:
			MP._cap(img, ex - er, ey, ex + er, ey, 0.3, 0.3, GM._flat(INK))
		else:
			MP._ellipse(img, ex, ey, er + 0.4, er + 0.4, INK)
			MP._ellipse(img, ex, ey, er, er, Color(str(p["eye"])))
			MP._ellipse(img, ex - er * 0.3, ey - er * 0.3, er * 0.35, er * 0.35, Color.WHITE)
	# crochets
	var open := 0.0 if col != 2 else h * 0.07
	for s in 2:
		var fx2 := hx + w * (0.15 + float(s) * 0.02)
		GM._cp(img, fx2 - w * 0.02, cy + h * 0.1, fx2 + w * 0.02, cy + h * 0.2 + open * (1.0 + float(s)), w * 0.022, w * 0.006, MP._ramp("#e8e0d0"))
	if col == 2:
		MP._ellipse(img, hx + w * 0.15, cy + h * 0.12, w * 0.03, h * 0.025, Color("#5a1426"))
	if bool(p.get("crown", false)):
		var gold := MP._ramp("#e8c050")
		GM._tp(img, cy - h * 0.2, cy - h * 0.12, hx - w * 0.07, hx + w * 0.07, hx - w * 0.09, hx + w * 0.09, gold)
		for k in 3:
			var tx := hx - w * 0.07 + float(k) * w * 0.07
			GM._tri(img, Vector2(tx - w * 0.025, cy - h * 0.2), Vector2(tx + w * 0.025, cy - h * 0.2), Vector2(tx, cy - h * 0.29), gold[3])
		GM._disc(img, hx, cy - h * 0.17, w * 0.012, Color("#d8322a"))


## Le Grand Œil : un globe de braise dans un cerclage de fer hérissé de piques, paupière de fonte,
## pupille en fente. À l'attaque, grand ouvert, un rayon sort vers la droite ; au coup reçu, paupière close.
static func _eyeball(img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	var w := float(size.x)
	var h := float(size.y)
	var dy := float(f) * 0.9
	var cx := ox + w * 0.46
	var cy := h * 0.44 + dy
	var iron := MP._ramp("#4a4658")
	# support : colonne de basalte, piques
	GM._tp(img, h * 0.7, h * 0.97, cx - w * 0.12, cx + w * 0.12, cx - w * 0.22, cx + w * 0.22, MP._ramp("#2e2a38"))
	for k in 9:
		var a := -PI + float(k) * PI / 8.0 - 0.0
		var bx := cx + cos(a) * w * 0.34
		var by := cy + sin(a) * h * 0.34
		GM._tri(img, Vector2(bx - 2.0, by), Vector2(bx + 2.0, by), Vector2(cx + cos(a) * w * 0.47, cy + sin(a) * h * 0.47), iron[3])
	GM._o(img, cx, cy, w * 0.36, h * 0.34, iron, 0.0)
	var open := 1.0
	if col == 3:
		open = 0.12
	elif col == 2:
		open = 1.15
	GM._o(img, cx, cy, w * 0.3, h * 0.27 * open + 1.0, MP._ramp("#ffcf60"), 0.3)
	GM._o(img, cx + w * 0.04, cy, w * 0.2, h * 0.24 * open + 0.5, MP._ramp("#ff7a30"), 0.2)
	if col != 3:
		GM._o(img, cx + w * 0.06, cy, w * 0.045, h * 0.2 * open, MP._ramp("#14080a"), 0.0)
		GM._disc(img, cx - w * 0.06, cy - h * 0.08 * open, w * 0.02, Color("#fff6d0"))
	# paupières de fonte
	var lid := MP._ramp("#2a2634")
	GM._tp(img, cy - h * 0.34, cy - h * 0.27 * open, cx - w * 0.35, cx + w * 0.35, cx - w * 0.3, cx + w * 0.3, lid)
	GM._tp(img, cy + h * 0.27 * open, cy + h * 0.33, cx - w * 0.3, cx + w * 0.3, cx - w * 0.34, cx + w * 0.34, lid)
	if col == 2:   # rayon
		GM._tri(img, Vector2(cx + w * 0.1, cy - h * 0.05), Vector2(cx + w * 0.1, cy + h * 0.05), Vector2(cx + w * 0.62, cy), Color("#ffd070"))
		GM._tri(img, Vector2(cx + w * 0.1, cy - h * 0.02), Vector2(cx + w * 0.1, cy + h * 0.02), Vector2(cx + w * 0.55, cy), Color("#fff6d0"))
