extends RefCounted
## Monstres du chapitre 6 : les Éveillés du Sentier, les Boucaniers d'Ombrine, les armées du
## Pelle-à-Tarte (Cassoulétains, Mammous, Dindon de la Farce, Naze Suprême), Gothmoque et la
## Grondine. Mêmes règles que monster_painter.gd (quatre poses, regard vers la droite, rampes de
## cinq tons) ; ce fichier réutilise ses outils de volume. Appelé depuis `MonsterPainter.paint`
## par `GM.paint(kind, img, ox, f, col, size)` : f = pose de respiration (0 ou 1), col = colonne
## (2 attaque, 3 coup reçu).

const PA = preload("res://src/gfx/pixel_art.gd")
const MP = preload("res://src/gfx/monster_painter.gd")

const KINDS: Array[String] = ["eveille", "eveille_veilleur", "roi_eveille", "boucanier", "saumure", "cassouletain",
		"gothmoque", "naze_supreme", "mammou", "dindon_farce", "grondine"]

## Tailles de case : plus fines que les monstres d'avant, pour des boss qui tiennent l'écran.
const SIZES := {
	"eveille": Vector2i(48, 64), "eveille_veilleur": Vector2i(56, 72), "roi_eveille": Vector2i(84, 100),
	"boucanier": Vector2i(52, 64), "saumure": Vector2i(76, 92), "cassouletain": Vector2i(56, 68),
	"gothmoque": Vector2i(96, 108), "naze_supreme": Vector2i(76, 100), "mammou": Vector2i(100, 76),
	"dindon_farce": Vector2i(88, 88), "grondine": Vector2i(100, 66),
}


static func paint(kind: String, img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	match kind:
		"eveille": _ghost(img, ox, f, col, size, {"skin": "#aebcc8", "gown": "#cfd8e0", "eye": "#ff5a4a", "cap": "#6a7ab8", "light": false})
		"eveille_veilleur": _ghost(img, ox, f, col, size, {"skin": "#98a8b8", "gown": "#8fa0b8", "eye": "#ffb04a", "cap": "#b87a4a", "light": true})
		"roi_eveille": _king(img, ox, f, col, size)
		"boucanier": _man(img, ox, f, col, size, {"skin": "#d0a078", "cloth": "#8a2a2a", "trim": "#e8e4d8", "head": "bandana", "weapon": "sabre", "head_c": "#2a2a38", "stripe": true})
		"saumure": _man(img, ox, f, col, size, {"skin": "#c89468", "cloth": "#2a3a58", "trim": "#e8c050", "head": "tricorne", "weapon": "sabre", "head_c": "#1c1c28", "big": true, "beard": "#e8e4d8"})
		"cassouletain": _man(img, ox, f, col, size, {"skin": "#a8744a", "cloth": "#b8602a", "trim": "#e8d8a0", "head": "marmite", "weapon": "lance", "head_c": "#5a4a3a"})
		"gothmoque": _man(img, ox, f, col, size, {"skin": "#8a7a68", "cloth": "#4a4a56", "trim": "#c8c4b8", "head": "cornes", "weapon": "massue", "head_c": "#3a3a46", "big": true})
		"naze_supreme": _wraith(img, ox, f, col, size)
		"mammou": _mammoth(img, ox, f, col, size)
		"dindon_farce": _turkey(img, ox, f, col, size)
		"grondine": _ram(img, ox, f, col, size)
		_: PA.rect(img, ox + 4, 4, size.x - 8, size.y - 8, Color.MAGENTA)


## Silhouette de fantôme : chemise de nuit qui s'effile, yeux écarquillés cernés de rouge.
static func _ghost(img: Image, ox: int, f: int, col: int, size: Vector2i, p: Dictionary) -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.46
	var dy := float(f)
	var skin := MP._ramp(str(p["skin"]))
	var gown := MP._ramp(str(p["gown"]))
	var sway := float(f) * 1.5
	# chemise de nuit : large en haut, effilée en volutes
	MP._trap(img, int(h * 0.36 + dy), int(h * 0.66), ox + cx - w * 0.2, ox + cx + w * 0.2, ox + cx - w * 0.24, ox + cx + w * 0.24, gown)
	MP._trap(img, int(h * 0.66), int(h * 0.88), ox + cx - w * 0.24, ox + cx + w * 0.24, ox + cx - w * 0.06 + sway, ox + cx + w * 0.1 + sway, MP._dim(gown))
	for k in 3:
		MP._cap(img, ox + cx - w * 0.14 + k * w * 0.14, h * 0.82, ox + cx - w * 0.18 + k * w * 0.16 + sway, h * 0.96, 1.6, 0.5, MP._dim(gown))
	# bras tendus (ou levés à l'attaque)
	var hand_y := h * 0.5 if col != 2 else h * 0.24
	MP._cap(img, ox + cx + w * 0.16, h * 0.44 + dy, ox + cx + w * 0.34, hand_y, 2.6, 2.0, skin)
	MP._cap(img, ox + cx - w * 0.17, h * 0.45 + dy, ox + cx - w * 0.3, h * 0.56, 2.4, 1.8, MP._dim(skin))
	if bool(p["light"]):   # bougie du veilleur
		PA.rect(img, ox + int(cx + w * 0.34) - 1, int(hand_y) - 8, 3, 7, Color("#f4efe0"))
		MP._ell(img, ox + cx + w * 0.34 + 0.5, hand_y - 10.0, 2.2, 3.2, MP._ramp("#ffd870"))
	# tête, grands yeux cernés, bonnet de nuit retombant
	var hy := h * 0.24 + dy
	MP._ell(img, ox + cx + 1.0, hy, w * 0.19, h * 0.15, skin)
	var ex := int(cx + w * 0.02)
	var ey := int(hy) - 2
	if col == 3:
		PA.rect(img, ox + ex - 1, ey + 1, 5, 1, Color("#1c1418"))
		PA.rect(img, ox + ex + 7, ey + 1, 5, 1, Color("#1c1418"))
	else:
		PA.rect(img, ox + ex - 2, ey - 1, 6, 5, Color("#5a4a68"))     # cernes
		PA.rect(img, ox + ex + 6, ey - 1, 6, 5, Color("#5a4a68"))
		PA.rect(img, ox + ex - 1, ey, 4, 3, Color("#f8f8f0"))
		PA.rect(img, ox + ex + 7, ey, 4, 3, Color("#f8f8f0"))
		PA.rect(img, ox + ex, ey + 1, 2, 2, Color(str(p["eye"])))
		PA.rect(img, ox + ex + 8, ey + 1, 2, 2, Color(str(p["eye"])))
	if col == 2:
		PA.rect(img, ox + ex + 1, int(hy) + 4, 9, 4, Color("#2a1418"))
	else:
		PA.rect(img, ox + ex + 2, int(hy) + 5, 7, 1, Color("#2a1c28"))
	var cap := MP._ramp(str(p["cap"]))
	MP._trap(img, int(hy - h * 0.14), int(hy - h * 0.04), ox + cx - w * 0.1, ox + cx + w * 0.16, ox + cx - w * 0.2, ox + cx + w * 0.22, cap)
	MP._cap(img, ox + cx - w * 0.04, hy - h * 0.12, ox + cx - w * 0.3, hy + h * 0.06 + sway, 2.6, 1.4, cap)
	PA.rect(img, ox + int(cx - w * 0.32), int(hy + h * 0.06 + sway) - 1, 3, 3, Color("#f4efe0"))   # pompon


## Roi des Éveillés : fantôme couronné, cape de veille, bassinoire en guise de sceptre.
static func _king(img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.46
	var dy := float(f)
	var skin := MP._ramp("#a8b8c4")
	var robe := MP._ramp("#3a4a78")
	var fur := MP._ramp("#e8e4d8")
	var sway := float(f) * 2.0
	MP._trap(img, int(h * 0.34 + dy), int(h * 0.7), ox + cx - w * 0.2, ox + cx + w * 0.22, ox + cx - w * 0.3, ox + cx + w * 0.32, robe)
	MP._trap(img, int(h * 0.7), int(h * 0.94), ox + cx - w * 0.3, ox + cx + w * 0.32, ox + cx - w * 0.1 + sway, ox + cx + w * 0.12 + sway, MP._dim(robe))
	for k in 4:
		MP._cap(img, ox + cx - w * 0.2 + k * w * 0.14, h * 0.86, ox + cx - w * 0.24 + k * w * 0.15 + sway, h * 0.99, 2.0, 0.6, MP._dim(robe))
	MP._trap(img, int(h * 0.34 + dy), int(h * 0.42 + dy), ox + cx - w * 0.22, ox + cx + w * 0.24, ox + cx - w * 0.24, ox + cx + w * 0.26, fur)   # collet
	var hy := h * 0.22 + dy
	MP._ell(img, ox + cx + 1.0, hy, w * 0.14, h * 0.12, skin)
	var ex := int(cx + w * 0.0)
	var ey := int(hy) - 2
	if col == 3:
		PA.rect(img, ox + ex, ey + 1, 6, 1, Color("#1c1418"))
		PA.rect(img, ox + ex + 9, ey + 1, 6, 1, Color("#1c1418"))
	else:
		PA.rect(img, ox + ex - 1, ey - 1, 8, 6, Color("#4a3a68"))
		PA.rect(img, ox + ex + 8, ey - 1, 8, 6, Color("#4a3a68"))
		PA.rect(img, ox + ex, ey, 6, 4, Color("#fffff0"))
		PA.rect(img, ox + ex + 9, ey, 6, 4, Color("#fffff0"))
		PA.rect(img, ox + ex + 2, ey + 1, 3, 3, Color("#ff4a3a"))
		PA.rect(img, ox + ex + 11, ey + 1, 3, 3, Color("#ff4a3a"))
	PA.rect(img, ox + ex + 2, int(hy) + 6, 12, 1 if col != 2 else 4, Color("#2a1418"))
	MP._trap(img, int(hy - h * 0.16), int(hy - h * 0.08), ox + cx - w * 0.1, ox + cx + w * 0.14, ox + cx - w * 0.13, ox + cx + w * 0.17, MP._ramp("#e8c050"))   # couronne
	for k in 4:
		MP._tri(img, Vector2(ox + cx - w * 0.12 + k * w * 0.075, hy - h * 0.16), Vector2(ox + cx - w * 0.09 + k * w * 0.075, hy - h * 0.23), Vector2(ox + cx - w * 0.06 + k * w * 0.075, hy - h * 0.16), Color("#e8c050"))
	# bassinoire : un long manche, un couvercle de cuivre percé
	var hand_y := h * 0.56 if col != 2 else h * 0.2
	MP._cap(img, ox + cx + w * 0.22, h * 0.46 + dy, ox + cx + w * 0.38, hand_y, 3.0, 2.4, skin)
	PA.line(img, ox + int(cx + w * 0.38), int(hand_y), ox + int(cx + w * 0.38), int(hand_y) - 22, Color("#7a5632"))
	MP._ell(img, ox + cx + w * 0.38, hand_y - 28.0, 8.0, 8.0, MP._ramp("#c87a3a"))
	for k in 5:
		PA.px(img, ox + int(cx + w * 0.38) - 4 + k * 2, int(hand_y) - 28 + (k % 2) * 3, Color("#4a2a18"))
	MP._cap(img, ox + cx - w * 0.2, h * 0.46 + dy, ox + cx - w * 0.3, h * 0.6, 3.0, 2.2, MP._dim(skin))


## Humanoïde de guerre. p : skin, cloth, trim, head (bandana, tricorne, marmite, cornes), weapon
## (sabre, lance, massue), head_c, big (carrure), stripe (marinière), beard.
static func _man(img: Image, ox: int, f: int, col: int, size: Vector2i, p: Dictionary) -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.46
	var dy := float(f)
	var big := bool(p.get("big", false))
	var skin := MP._ramp(str(p["skin"]))
	var cloth := MP._ramp(str(p["cloth"]))
	var trim := MP._ramp(str(p["trim"]))
	var wide := 0.22 if not big else 0.27
	# jambes et bottes
	MP._cap(img, ox + cx - w * 0.1, h * 0.7 + dy, ox + cx - w * 0.11, h * 0.94, w * 0.05, w * 0.045, MP._dim(cloth))
	MP._cap(img, ox + cx + w * 0.1, h * 0.7 + dy, ox + cx + w * 0.11, h * 0.94, w * 0.05, w * 0.045, cloth)
	PA.rect(img, ox + int(cx - w * 0.2), int(h * 0.94), int(w * 0.14), 3, Color("#2a2018"))
	PA.rect(img, ox + int(cx + w * 0.02), int(h * 0.94), int(w * 0.16), 3, Color("#2a2018"))
	# torse et ceinture
	MP._trap(img, int(h * 0.38 + dy), int(h * 0.72 + dy), ox + cx - w * wide, ox + cx + w * wide, ox + cx - w * (wide - 0.04), ox + cx + w * (wide - 0.04), cloth)
	if bool(p.get("stripe", false)):
		for yy in range(int(h * 0.42), int(h * 0.7), 5):
			PA.rect(img, ox + int(cx - w * (wide - 0.02)), yy + int(dy), int(w * (wide - 0.02) * 2.0), 2, Color(str(p["trim"])))
	PA.rect(img, ox + int(cx - w * (wide - 0.02)), int(h * 0.66 + dy), int(w * (wide - 0.02) * 2.0), 3, Color("#c9a24a"))
	if big:   # épaulières
		MP._ell(img, ox + cx - w * 0.27, h * 0.42 + dy, w * 0.08, h * 0.06, trim)
		MP._ell(img, ox + cx + w * 0.27, h * 0.42 + dy, w * 0.08, h * 0.06, trim)
	# tête
	var hy := h * 0.25 + dy
	MP._ell(img, ox + cx + 1.0, hy, w * 0.13, h * 0.1, skin, 0.05)
	var ex := int(cx + w * 0.03)
	var ey := int(hy) - 1
	if col == 3:
		PA.rect(img, ox + ex, ey + 1, 4, 1, Color("#1c1418"))
		PA.rect(img, ox + ex + 6, ey + 1, 4, 1, Color("#1c1418"))
	else:
		PA.rect(img, ox + ex, ey, 3, 3, Color("#f4f0e8"))
		PA.rect(img, ox + ex + 6, ey, 3, 3, Color("#f4f0e8"))
		PA.rect(img, ox + ex + 1, ey + 1, 2, 2, Color("#1c1418"))
		PA.rect(img, ox + ex + 7, ey + 1, 2, 2, Color("#1c1418"))
		PA.rect(img, ox + ex - 1, ey - 2, 5, 1, Color("#2a2018"))
		PA.rect(img, ox + ex + 5, ey - 2, 5, 1, Color("#2a2018"))
	PA.rect(img, ox + ex + 1, int(hy) + 4, 7, 3 if col == 2 else 1, Color("#4a1424") if col == 2 else Color("#2a1418"))
	if p.has("beard"):
		MP._ell(img, ox + cx + 2.0, hy + h * 0.09, w * 0.11, h * 0.06, MP._ramp(str(p["beard"])))
	var hc := MP._ramp(str(p["head_c"]))
	match str(p["head"]):
		"bandana":
			PA.rect(img, ox + int(cx - w * 0.12), int(hy - h * 0.1), int(w * 0.28), 4, Color("#c8322a"))
			MP._cap(img, ox + cx - w * 0.1, hy - h * 0.08, ox + cx - w * 0.22, hy - h * 0.02 + float(f), 1.8, 1.0, MP._ramp("#c8322a"))
		"tricorne":
			MP._trap(img, int(hy - h * 0.14), int(hy - h * 0.07), ox + cx - w * 0.1, ox + cx + w * 0.14, ox + cx - w * 0.2, ox + cx + w * 0.24, hc)
			PA.rect(img, ox + int(cx - w * 0.2), int(hy - h * 0.08), int(w * 0.44), 2, Color(str(p["trim"])))
			MP._ell(img, ox + cx + w * 0.02, hy - h * 0.12, 4.0, 2.4, MP._ramp("#c8d4d8"))   # un poisson sur le chapeau
		"marmite":
			MP._ell(img, ox + cx + 1.0, hy - h * 0.1, w * 0.15, h * 0.06, hc)
			PA.rect(img, ox + int(cx - w * 0.14), int(hy - h * 0.07), int(w * 0.3), 2, Color("#2a2018"))
			PA.rect(img, ox + int(cx - w * 0.18), int(hy - h * 0.03), 4, 5, Color("#3a2a20"))   # anse de la cassole
			PA.rect(img, ox + int(cx + w * 0.18), int(hy - h * 0.03), 4, 5, Color("#3a2a20"))
		"cornes":
			MP._ell(img, ox + cx + 1.0, hy - h * 0.09, w * 0.14, h * 0.05, hc)
			MP._tri(img, Vector2(ox + cx - w * 0.12, hy - h * 0.08), Vector2(ox + cx - w * 0.26, hy - h * 0.2), Vector2(ox + cx - w * 0.06, hy - h * 0.12), Color("#e8e4d8"))
			MP._tri(img, Vector2(ox + cx + w * 0.16, hy - h * 0.08), Vector2(ox + cx + w * 0.3, hy - h * 0.2), Vector2(ox + cx + w * 0.1, hy - h * 0.12), Color("#e8e4d8"))
	# bras arrière, bras armé
	MP._cap(img, ox + cx - w * (wide - 0.03), h * 0.44 + dy, ox + cx - w * (wide + 0.04), h * 0.62, w * 0.04, w * 0.035, MP._dim(skin))
	var hx := cx + w * 0.33
	var hand_y := h * 0.58 if col != 2 else h * 0.2
	MP._cap(img, ox + cx + w * (wide - 0.02), h * 0.44 + dy, ox + hx, hand_y, w * 0.045, w * 0.04, skin)
	var steel := MP._ramp("#b8c0d0")
	var wood := MP._ramp("#7a5632")
	match str(p["weapon"]):
		"sabre":
			PA.line(img, ox + int(hx), int(hand_y), ox + int(hx) + int(w * 0.1), int(hand_y) - int(h * 0.3), steel[3])
			PA.line(img, ox + int(hx) + 1, int(hand_y), ox + int(hx) + 1 + int(w * 0.1), int(hand_y) - int(h * 0.3), steel[2])
			PA.rect(img, ox + int(hx) - 3, int(hand_y) - 1, 7, 2, Color("#c9a24a"))
		"lance":
			PA.line(img, ox + int(hx), int(hand_y) + 10, ox + int(hx) + 2, int(hand_y) - int(h * 0.36), wood[2])
			MP._tri(img, Vector2(ox + hx, hand_y - h * 0.36), Vector2(ox + hx + 3.0, hand_y - h * 0.36), Vector2(ox + hx + 1.5, hand_y - h * 0.46), steel[3])
		"massue":
			PA.line(img, ox + int(hx), int(hand_y) + 6, ox + int(hx) + 3, int(hand_y) - int(h * 0.28), wood[1])
			MP._ell(img, ox + hx + 3.0, hand_y - h * 0.32, w * 0.07, h * 0.08, MP._ramp("#5a5a66"))
			for k in 4:
				PA.px(img, ox + int(hx) + 3 + (k - 2) * 4, int(hand_y - h * 0.32) + (k % 2) * 6 - 3, steel[4])


## Naze Suprême : un manteau noir sans personne dedans, deux lueurs sous le capuchon, une couronne
## de clous, une lame ; au doigt, un tout petit anneau qui brille.
static func _wraith(img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	var w := size.x
	var h := size.y
	var cx := w * 0.46
	var dy := float(f)
	var cloak := MP._ramp("#262634")
	var sway := float(f) * 2.0
	MP._trap(img, int(h * 0.3 + dy), int(h * 0.66), ox + cx - w * 0.17, ox + cx + w * 0.19, ox + cx - w * 0.3, ox + cx + w * 0.32, cloak)
	MP._trap(img, int(h * 0.66), int(h * 0.95), ox + cx - w * 0.3, ox + cx + w * 0.32, ox + cx - w * 0.34 + sway, ox + cx + w * 0.3 - sway, MP._dim(cloak))
	for k in 5:   # franges déchirées
		MP._tri(img, Vector2(ox + cx - w * 0.34 + k * w * 0.14 + sway, h * 0.93), Vector2(ox + cx - w * 0.28 + k * w * 0.14 + sway, h * 0.99), Vector2(ox + cx - w * 0.22 + k * w * 0.14 + sway, h * 0.93), MP._dim(cloak)[1])
	MP._ell(img, ox + cx + 1.0, h * 0.22 + dy, w * 0.15, h * 0.13, MP._ramp("#14141c"))   # capuchon : un vide
	var ey := int(h * 0.22 + dy) - 1
	var glow := Color("#ff5a4a") if col != 3 else Color("#8a2a28")
	PA.rect(img, ox + int(cx) + 2, ey, 4, 2, glow)
	PA.rect(img, ox + int(cx) + 9, ey, 4, 2, glow)
	PA.px(img, ox + int(cx) + 3, ey, Color("#ffd0a0"))
	PA.px(img, ox + int(cx) + 10, ey, Color("#ffd0a0"))
	MP._trap(img, int(h * 0.075 + dy), int(h * 0.12 + dy), ox + cx - w * 0.1, ox + cx + w * 0.13, ox + cx - w * 0.12, ox + cx + w * 0.15, MP._ramp("#9a9aa8"))   # couronne
	for k in 5:
		MP._tri(img, Vector2(ox + cx - w * 0.1 + k * w * 0.05, h * 0.075 + dy), Vector2(ox + cx - w * 0.075 + k * w * 0.05, h * 0.02 + dy), Vector2(ox + cx - w * 0.05 + k * w * 0.05, h * 0.075 + dy), Color("#9a9aa8"))
	var hx := cx + w * 0.34
	var hand_y := h * 0.56 if col != 2 else h * 0.2
	MP._cap(img, ox + cx + w * 0.18, h * 0.4 + dy, ox + hx, hand_y, w * 0.05, w * 0.04, cloak)
	PA.px(img, ox + int(hx), int(hand_y) + 1, Color("#ffd070"))   # le petit anneau
	PA.px(img, ox + int(hx) + 1, int(hand_y) + 1, Color("#fff0a0"))
	PA.line(img, ox + int(hx), int(hand_y), ox + int(hx) + 4, int(hand_y) - int(h * 0.42), Color("#c8d0e0"))
	PA.line(img, ox + int(hx) + 1, int(hand_y), ox + int(hx) + 5, int(hand_y) - int(h * 0.42), Color("#7a8498"))
	PA.rect(img, ox + int(hx) - 4, int(hand_y) - 2, 9, 2, Color("#6a6a78"))
	MP._cap(img, ox + cx - w * 0.17, h * 0.4 + dy, ox + cx - w * 0.28, h * 0.58, w * 0.05, w * 0.04, MP._dim(cloak))


## Mammou : éléphant de guerre à défenses recourbées, bannière dans le dos.
static func _mammoth(img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	var w := size.x
	var h := size.y
	var dy := float(f)
	var hide := MP._ramp("#7a6a5c")
	var legs := [0.28, 0.4, 0.6, 0.72]
	for i in 4:
		var lx: float = w * float(legs[i])
		MP._cap(img, ox + lx, h * 0.55 + dy, ox + lx + (1.0 if i % 2 == 0 else -1.0), h * 0.93, w * 0.06, w * 0.055, MP._dim(hide) if i % 2 == 0 else hide)
		PA.rect(img, ox + int(lx) - 5, int(h * 0.92), 11, 3, Color("#d8d0c0"))
	MP._ell(img, ox + w * 0.46, h * 0.44 + dy, w * 0.3, h * 0.26, hide)
	MP._ell(img, ox + w * 0.68, h * 0.3 + dy, w * 0.14, h * 0.2, hide, 0.05)   # tête
	MP._ell(img, ox + w * 0.58, h * 0.3 + dy, w * 0.09, h * 0.17, MP._ramp("#6a5a4c"))   # oreille
	var trunk_y := h * 0.78 if col != 2 else h * 0.42
	MP._cap(img, ox + w * 0.78, h * 0.36 + dy, ox + w * 0.9, trunk_y, w * 0.045, w * 0.03, hide)
	MP._cap(img, ox + w * 0.76, h * 0.42 + dy, ox + w * 0.97, h * 0.5, w * 0.025, w * 0.008, MP._ramp("#f0ead8"))   # défense
	var ex := int(w * 0.72)
	if col == 3:
		PA.rect(img, ox + ex, int(h * 0.26 + dy), 4, 1, Color("#1c1418"))
	else:
		PA.rect(img, ox + ex, int(h * 0.25 + dy), 3, 3, Color("#f8f4e8"))
		PA.px(img, ox + ex + 2, int(h * 0.26 + dy), Color("#1c1418"))
	# palanquin et bannière : un mât, une serviette en guise de drapeau
	PA.rect(img, ox + int(w * 0.34), int(h * 0.18 + dy), int(w * 0.24), 4, Color("#8a3a2a"))
	PA.rect(img, ox + int(w * 0.34), int(h * 0.14 + dy), int(w * 0.24), 4, Color("#c9a24a"))
	PA.line(img, ox + int(w * 0.46), int(h * 0.14 + dy), ox + int(w * 0.46), int(h * 0.0), Color("#5a4226"))
	MP._tri(img, Vector2(ox + w * 0.46, 1.0), Vector2(ox + w * 0.62, 5.0 + dy), Vector2(ox + w * 0.46, 10.0), Color("#e8e4d8"))
	MP._cap(img, ox + w * 0.2, h * 0.5 + dy, ox + w * 0.1, h * 0.6, w * 0.03, w * 0.012, hide)   # queue


## Dindon de la Farce : un dindon géant, jabot rouge, queue en éventail, selle noire.
static func _turkey(img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	var w := size.x
	var h := size.y
	var dy := float(f)
	var plume := MP._ramp("#6a4a2e")
	# éventail de plumes derrière
	for k in 9:
		var a := -2.6 + k * 0.32
		MP._cap(img, ox + w * 0.28, h * 0.52 + dy, ox + w * 0.28 + cos(a) * w * 0.28, h * 0.52 + sin(a) * h * 0.46, w * 0.03, w * 0.045, MP._ramp("#a8743a") if k % 2 == 0 else MP._ramp("#7a5a30"))
	MP._cap(img, ox + w * 0.4, h * 0.7 + dy, ox + w * 0.38, h * 0.95, w * 0.035, w * 0.025, MP._ramp("#d8a838"))
	MP._cap(img, ox + w * 0.54, h * 0.7 + dy, ox + w * 0.56, h * 0.95, w * 0.035, w * 0.025, MP._ramp("#d8a838"))
	PA.rect(img, ox + int(w * 0.34), int(h * 0.94), int(w * 0.14), 3, Color("#d8a838"))
	PA.rect(img, ox + int(w * 0.52), int(h * 0.94), int(w * 0.14), 3, Color("#d8a838"))
	MP._ell(img, ox + w * 0.46, h * 0.56 + dy, w * 0.2, h * 0.22, plume)
	MP._ell(img, ox + w * 0.46, h * 0.5 + dy, w * 0.14, h * 0.1, MP._ramp("#1c1c24"))   # selle
	MP._cap(img, ox + w * 0.6, h * 0.46 + dy, ox + w * 0.66, h * 0.22 + dy, w * 0.045, w * 0.04, plume)   # cou
	MP._ell(img, ox + w * 0.68, h * 0.2 + dy, w * 0.07, h * 0.075, MP._ramp("#c87a68"), 0.05)
	MP._ell(img, ox + w * 0.64, h * 0.34 + dy, w * 0.045, h * 0.085, MP._ramp("#d8322a"))   # caroncule
	var beak_open := col == 2
	MP._tri(img, Vector2(ox + w * 0.73, h * 0.17 + dy), Vector2(ox + w * 0.88, h * 0.22 + dy), Vector2(ox + w * 0.73, h * 0.25 + dy), Color("#e8a830"))
	if beak_open:
		MP._tri(img, Vector2(ox + w * 0.73, h * 0.23 + dy), Vector2(ox + w * 0.86, h * 0.3 + dy), Vector2(ox + w * 0.73, h * 0.28 + dy), Color("#e8a830"))
		PA.rect(img, ox + int(w * 0.73), int(h * 0.245 + dy), int(w * 0.1), 2, Color("#4a1424"))
	var ex := int(w * 0.68)
	if col == 3:
		PA.rect(img, ox + ex, int(h * 0.18 + dy), 4, 1, Color("#1c1418"))
	else:
		PA.rect(img, ox + ex, int(h * 0.17 + dy), 3, 3, Color("#f8e068"))
		PA.px(img, ox + ex + 1, int(h * 0.18 + dy), Color("#1c1418"))
	MP._cap(img, ox + w * 0.36, h * 0.56 + dy, ox + w * 0.22, h * 0.66, w * 0.05, w * 0.03, MP._dim(plume))   # aile


## Grondine : un tronc cerclé de fer à tête de bélier cornue, sur un affût à roues.
static func _ram(img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	var w := size.x
	var h := size.y
	var dy := float(f)
	var wood := MP._ramp("#7a5632")
	var iron := MP._ramp("#6a6a78")
	for wx in [0.26, 0.62]:
		MP._ell(img, ox + w * float(wx), h * 0.82, h * 0.15, h * 0.15, MP._ramp("#5a4226"))
		MP._ell(img, ox + w * float(wx), h * 0.82, h * 0.05, h * 0.05, iron)
	var push := 0.0 if col != 2 else w * 0.08
	MP._cap(img, ox + w * 0.1 + push, h * 0.5 + dy, ox + w * 0.7 + push, h * 0.5 + dy, h * 0.14, h * 0.14, wood)
	for k in 4:
		PA.rect(img, ox + int(w * 0.2 + k * w * 0.14 + push), int(h * 0.36 + dy), 3, int(h * 0.28), iron[2])
	MP._ell(img, ox + w * 0.76 + push, h * 0.5 + dy, w * 0.12, h * 0.17, iron)   # tête de bélier
	MP._cap(img, ox + w * 0.74 + push, h * 0.36 + dy, ox + w * 0.64 + push, h * 0.2 + dy, w * 0.04, w * 0.02, MP._ramp("#e8e4d8"))   # corne
	MP._cap(img, ox + w * 0.74 + push, h * 0.64 + dy, ox + w * 0.64 + push, h * 0.78 + dy, w * 0.04, w * 0.02, MP._ramp("#e8e4d8"))
	var ex := int(w * 0.8 + push)
	if col == 3:
		PA.rect(img, ox + ex, int(h * 0.46 + dy), 4, 1, Color("#1c1418"))
	else:
		PA.rect(img, ox + ex, int(h * 0.44 + dy), 4, 3, Color("#ff7a3a"))
		PA.px(img, ox + ex + 1, int(h * 0.45 + dy), Color("#fff0a0"))
	PA.rect(img, ox + int(w * 0.82 + push), int(h * 0.56 + dy), int(w * 0.12), 3 if col != 2 else 6, Color("#2a1418"))
	for k in 3:   # crocs
		PA.px(img, ox + int(w * 0.84 + push) + k * 4, int(h * 0.57 + dy), Color.WHITE)
	MP._ell(img, ox + w * 0.12, h * 0.5 + dy, w * 0.05, h * 0.1, MP._ramp("#4a3a30"))   # queue : une botte de corde
