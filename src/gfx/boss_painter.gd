extends RefCounted
## Boss à taille humaine, peints EN GRAND pour le combat (sinon la planche de personnage, faite pour
## l'exploration, serait agrandie quatre fois : molle, pixelisée). Même principe que les monstres haute
## définition : grille fine (K = 6), volumes éclairés d'en haut à gauche, plis d'étoffe, visage expressif,
## mains, accessoires, contour coloré. Chaque boss garde le costume et les couleurs de son personnage
## (data/characters.json) ; le personnage garde sa planche pour l'exploration.
## Quatre poses par planche : repos, respiration, attaque (bras levé, bouche ouverte), coup reçu.
## Appelé depuis `MonsterPainter._render` par `BP.paint(kind, img, ox, f, col, size)` ; comme
## gouda_monsters.gd, passe par l'état statique du peintre d'origine (exclu du préchauffage).
## Coordonnées « logiques » (celles de la petite case) : les outils de monster_painter.gd les
## multiplient par `MP.K`.

const PA = preload("res://src/gfx/pixel_art.gd")
const MP = preload("res://src/gfx/monster_painter.gd")
const GM = preload("res://src/gfx/gouda_monsters.gd")

const KINDS: Array[String] = ["boss_sarumale", "boss_froton", "boss_grimace", "boss_gardien", "boss_sauron",
		"boss_naze", "boss_naze_est", "boss_naze_ouest", "boss_goulum", "boss_uglouk", "boss_bouche", "boss_sauron_vigueur"]

const SIZES := {
	"boss_sarumale": Vector2i(72, 112), "boss_froton": Vector2i(64, 92), "boss_grimace": Vector2i(72, 104),
	"boss_gardien": Vector2i(72, 108), "boss_sauron": Vector2i(84, 112), "boss_naze": Vector2i(72, 108),
	"boss_naze_est": Vector2i(72, 108), "boss_naze_ouest": Vector2i(72, 108), "boss_goulum": Vector2i(64, 76),
	"boss_uglouk": Vector2i(92, 108), "boss_bouche": Vector2i(72, 110), "boss_sauron_vigueur": Vector2i(96, 120),
}

const INK := Color("#1c1222")


static func paint(kind: String, img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	match kind:
		"boss_sarumale":
			_robed(img, ox, f, col, size, {"robe": "#ebe6dc", "lining": "#8f9ab4", "trim": "#c9a24a", "skin": "#e0b898",
					"hair": "#e8e8ee", "beard": "#f2f0ea", "beard_len": 0.17, "eye": "#6a8aa8", "hat": "wizard",
					"hat_c": "#eeeaf0", "band": "#c8322a", "item": "staff", "boots": "#3a2a20", "cracks": true})
		"boss_gardien":
			_robed(img, ox, f, col, size, {"robe": "#6a6a8e", "lining": "#2e2e48", "trim": "#c9a24a", "skin": "#f0d6bc",
					"hair": "#dcdce8", "eye": "#b8b8ff", "hat": "hood", "hat_c": "#4a4a66", "item": "book",
					"boots": "#4a3a2a", "ears": true, "glow": "#c8c8ff"})
		"boss_grimace":
			_robed(img, ox, f, col, size, {"robe": "#6c5a82", "lining": "#2a1e3a", "trim": "#e0b84a", "skin": "#d8b8a0",
					"hair": "#7a7088", "eye": "#c8a8ff", "hat": "toque", "hat_c": "#4a3a5e", "item": "scroll", "glow": "#c8a0ff",
					"boots": "#3a2a20", "fat": 1.18, "mustache": "#8a8a90", "wooden": true})
		"boss_sauron":
			_robed(img, ox, f, col, size, {"robe": "#4a4266", "lining": "#1e1a2c", "trim": "#c9a24a", "skin": "#b8b0c8",
					"hair": "#17131c", "eye": "#ff7a3a", "hat": "helm", "hat_c": "#4a4458", "item": "mace",
					"boots": "#17131c", "fat": 1.1, "glow": "#ff7a3a"})
		"boss_naze":
			_robed(img, ox, f, col, size, {"robe": "#1c1a26", "lining": "#08060c", "trim": "#8a8aa0", "skin": "#2a2634",
					"hair": "#121018", "eye": "#c8d0ff", "hat": "void", "hat_c": "#15131c", "item": "sword",
					"boots": "#0c0a10", "glow": "#c8d0ff", "tatters": true})
		"boss_naze_est":
			_robed(img, ox, f, col, size, {"robe": "#2a1c26", "lining": "#0a0608", "trim": "#a08a8a", "skin": "#2a2634",
					"hair": "#121018", "eye": "#ff8a5a", "hat": "void", "hat_c": "#1c1218", "item": "sword",
					"boots": "#0c0a10", "glow": "#ff8a5a", "tatters": true, "crown": true})
		"boss_naze_ouest":
			_robed(img, ox, f, col, size, {"robe": "#1c2430", "lining": "#060a10", "trim": "#8a9ab0", "skin": "#2a2634",
					"hair": "#121018", "eye": "#9aff8a", "hat": "void", "hat_c": "#121a24", "item": "orb",
					"boots": "#0c0a10", "glow": "#9aff8a", "tatters": true, "crown": true})
		"boss_bouche":
			_robed(img, ox, f, col, size, {"robe": "#1c1822", "lining": "#08060c", "trim": "#a82a2a", "skin": "#c8b8b0",
					"hair": "#0c0a10", "eye": "#ff5a3a", "hat": "helm", "hat_c": "#2a2630", "item": "scroll",
					"boots": "#0c0a10", "glow": "#ff5a3a", "mustache": "#14101a"})
		"boss_sauron_vigueur":
			_robed(img, ox, f, col, size, {"robe": "#2a1a2a", "lining": "#0e060c", "trim": "#ffb040", "skin": "#c89a8a",
					"hair": "#17101a", "eye": "#ffd060", "hat": "helm", "hat_c": "#3a2a3e", "item": "mace",
					"boots": "#120a10", "fat": 1.22, "glow": "#ff8a3a", "crown": true})
		"boss_froton":
			_thief(img, ox, f, col, size)
		"boss_goulum":
			_goulum(img, ox, f, col, size)
		"boss_uglouk":
			_uglouk(img, ox, f, col, size)
		_:
			MP._rect(img, ox + 4, 4, size.x - 8, size.y - 8, Color.MAGENTA)


## Un trait courbe de couleur unie (plis fins, mèches, fils de barbe), épaisseur en pixels logiques.
static func _stroke(img: Image, a: Vector2, c: Vector2, b: Vector2, col: Color, r: float = 0.4) -> void:
	MP._curve(img, a, c, b, col, r)


## Étincelle à quatre branches (éclat de magie, reflet).
static func _star(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	GM._tri(img, Vector2(cx - r * 0.28, cy), Vector2(cx + r * 0.28, cy), Vector2(cx, cy - r), c)
	GM._tri(img, Vector2(cx - r * 0.28, cy), Vector2(cx + r * 0.28, cy), Vector2(cx, cy + r), c)
	GM._tri(img, Vector2(cx, cy - r * 0.28), Vector2(cx, cy + r * 0.28), Vector2(cx - r, cy), c)
	GM._tri(img, Vector2(cx, cy - r * 0.28), Vector2(cx, cy + r * 0.28), Vector2(cx + r, cy), c)


# ------------------------------------------------------------------ figures en robe

static func _robed(img: Image, ox: int, f: int, col: int, size: Vector2i, p: Dictionary) -> void:
	var w := float(size.x)
	var h := float(size.y)
	var fat := float(p.get("fat", 1.0))
	var lean := -w * 0.04 if col == 3 else 0.0
	var cx := ox + w * 0.45 + lean * 0.5
	var dy := float(f) * 0.9
	var robe := MP._ramp(str(p["robe"]))
	var lin := MP._ramp(str(p["lining"]))
	var trim := MP._ramp(str(p["trim"]))
	var skin := MP._ramp(str(p["skin"]))
	var hair := MP._ramp(str(p["hair"]))
	var gold := MP._ramp("#d8aa44")
	var boots := MP._ramp(str(p["boots"]))
	var hat := str(p["hat"])
	var item := str(p["item"])
	var y0 := h * 0.31 + dy   # épaules
	var y1 := h * 0.95        # ourlet
	var sw := w * 0.15 * fat
	var hw := w * 0.29 * fat
	var tatters := bool(p.get("tatters", false))
	# chevelure longue, derrière tout
	var hcx := cx + w * 0.05 + lean
	var hcy := h * 0.245 + dy
	var hr := w * 0.112 * (1.0 + (fat - 1.0) * 0.5)
	var hv := h * 0.076
	if hat != "void" and hat != "helm" and p.has("hair") and (hat == "wizard" or hat == "hood"):
		GM._cp(img, hcx - hr * 0.5, hcy - hv * 0.3, hcx - hr * 1.15 + lean, y0 + h * 0.2, hr * 0.85, hr * 0.5, MP._dim(hair))
	# dos de la robe, plus sombre : donne de l'épaisseur
	GM._tp(img, y0 + 2.0, y1, cx - sw * 1.1 + lean, cx + sw * 0.5, cx - hw * 1.08, cx + hw * 0.6, MP._dim(robe))
	# pieds
	GM._o(img, cx - w * 0.1, y1 + h * 0.012, w * 0.085, h * 0.026, MP._dim(boots))
	GM._o(img, cx + w * 0.17, y1 + h * 0.014, w * 0.11, h * 0.028, boots)
	# robe de face
	var wy := h * 0.55 + dy
	GM._tp(img, wy - 2.0, y1, cx - sw * 0.94 + lean * 0.3, cx + sw * 0.94, cx - hw, cx + hw, robe)
	GM._tp(img, y0, wy, cx - sw + lean, cx + sw + lean * 0.5, cx - sw * 0.94 + lean * 0.3, cx + sw * 0.94, robe)
	# bas de robe déchiré (les Nazes) ou ourlet brodé
	if tatters:
		for i in 7:
			var tx := cx - hw + float(i) * (hw * 2.0) / 6.0
			var ty := y1 + h * (0.012 + 0.02 * float(i % 3))
			GM._tri(img, Vector2(tx - w * 0.04, y1 - 1.0), Vector2(tx + w * 0.04, y1 - 1.0), Vector2(tx + w * 0.005 * float(i % 2), ty), robe[1])
	else:
		GM._tp(img, y1 - h * 0.04, y1, cx - hw * 0.96, cx + hw * 0.96, cx - hw, cx + hw, trim)
		for i in 9:
			GM._disc(img, cx - hw * 0.9 + float(i) * hw * 0.225, y1 - h * 0.02, 0.8, gold[3])
	# ouverture de la robe, doublure sombre
	GM._tp(img, y0 + h * 0.1, y1 - (0.0 if tatters else h * 0.04), cx + w * 0.045 - 1.0, cx + w * 0.045 + 1.0, cx + w * 0.075 - 3.0, cx + w * 0.075 + 3.0, lin)
	for u: float in [-0.8, -0.45, 0.5, 0.82]:
		MP._cap(img, cx + u * sw * 0.9, y0 + h * 0.12, cx + u * hw * 0.93, y1 - h * 0.045, 0.35, 0.8, GM._flat(robe[1]))
		MP._cap(img, cx + u * sw * 0.9 + 0.9, y0 + h * 0.14, cx + u * hw * 0.93 + 1.2, y1 - h * 0.06, 0.2, 0.4, GM._flat(robe[3]))
	# fissures du « Blanc-Cassé »
	if bool(p.get("cracks", false)):
		_stroke(img, Vector2(cx - w * 0.12, y0 + h * 0.18), Vector2(cx - w * 0.08, y0 + h * 0.26), Vector2(cx - w * 0.13, y0 + h * 0.34), robe[0], 0.3)
		_stroke(img, Vector2(cx + w * 0.18, y0 + h * 0.4), Vector2(cx + w * 0.22, y0 + h * 0.46), Vector2(cx + w * 0.19, y0 + h * 0.55), robe[0], 0.3)
		_stroke(img, Vector2(cx - w * 0.2, y1 - h * 0.12), Vector2(cx - w * 0.17, y1 - h * 0.18), Vector2(cx - w * 0.22, y1 - h * 0.25), robe[0], 0.3)
	# ceinture et pan qui pend
	var by := h * 0.55 + dy
	GM._tp(img, by, by + h * 0.032, cx - sw * 1.18 + lean * 0.3, cx + sw * 1.2, cx - sw * 1.24, cx + sw * 1.26, trim)
	GM._o(img, cx + w * 0.02, by + h * 0.016, w * 0.04, h * 0.026, gold, 0.15)
	GM._cp(img, cx + w * 0.02, by + h * 0.03, cx + w * 0.04, by + h * 0.21, w * 0.022, w * 0.03, trim)
	# épaules et col
	GM._o(img, cx - sw + lean * 0.5, y0 + 2.5, w * 0.075 * fat, h * 0.046, robe, 0.1)
	GM._o(img, cx + sw + lean * 0.5, y0 + 2.5, w * 0.075 * fat, h * 0.046, robe, 0.1)
	GM._o(img, cx + w * 0.015 + lean * 0.6, y0 - 0.5, w * 0.115 * fat, h * 0.034, lin)
	# bras arrière
	var bh := Vector2(cx - w * 0.22 + lean, h * 0.6 + dy * 0.5)
	if item == "book" or item == "scroll":
		bh = Vector2(cx - w * 0.02, h * 0.58 + dy * 0.5)
	_arm(img, Vector2(cx - sw * 0.95 + lean * 0.5, y0 + 4.0), Vector2(cx - sw - w * 0.075 + lean, y0 + h * 0.2), bh, w, MP._dim(robe))
	GM._o(img, bh.x, bh.y + h * 0.02, w * 0.048, w * 0.048, MP._dim(skin))
	# bras avant et son accessoire
	var hand := Vector2(cx + w * 0.3, h * 0.56)
	if col == 2:
		hand = Vector2(cx + w * 0.27, h * 0.3)
	elif col == 3:
		hand = Vector2(cx + w * 0.2, h * 0.6)
	var sh := Vector2(cx + sw * 0.95 + lean * 0.5, y0 + 4.0)
	_item_back(img, item, hand, w, h, col, p)
	var elbow := Vector2(cx + sw + w * 0.1, y0 + h * 0.21)
	if col == 2:
		elbow = Vector2(cx + sw + w * 0.13, y0 + h * 0.02)
	elif col == 3:
		elbow = Vector2(cx + sw + w * 0.02, y0 + h * 0.2)
	_arm(img, sh, elbow, hand, w, robe)
	GM._o(img, hand.x, hand.y, w * 0.073, w * 0.052, trim)   # manchette
	GM._o(img, hand.x + w * 0.01, hand.y + h * 0.012, w * 0.05, w * 0.05, skin, 0.05)
	_item_front(img, item, hand, w, h, col, p)
	# tête
	_head(img, hcx, hcy, hr, hv, w, h, col, f, p, skin, hair, trim, gold, lean, y0)


## Pièce de l'accessoire qui passe DERRIÈRE la main (le manche).
static func _item_back(img: Image, item: String, hand: Vector2, w: float, h: float, col: int, p: Dictionary) -> void:
	var wood := MP._ramp("#7a5632")
	var steel := MP._ramp("#b8c0d0")
	var gold := MP._ramp("#d8aa44")
	match item:
		"staff":
			var top := Vector2(hand.x + w * 0.01, h * 0.1)
			var foot := Vector2(hand.x - w * 0.01, h * 0.965)
			if col == 2:
				top = Vector2(hand.x + w * 0.12, hand.y - h * 0.15)
				foot = Vector2(hand.x - w * 0.08, hand.y + h * 0.28)
			elif col == 3:
				top = Vector2(hand.x + w * 0.06, h * 0.22)
			GM._cp(img, foot.x, foot.y, top.x, top.y, w * 0.026, w * 0.02, wood)
			GM._cp(img, top.x - w * 0.004, top.y + h * 0.02, top.x + w * 0.004, top.y - h * 0.02, w * 0.034, w * 0.034, gold)
			# plume d'oie : la plume géante au bout du bâton (le stylo de la direction)
			GM._tri(img, Vector2(top.x - w * 0.05, top.y - h * 0.01), Vector2(top.x + w * 0.05, top.y - h * 0.01), Vector2(top.x + w * 0.005, top.y - h * 0.085), gold[3])
			GM._tri(img, Vector2(top.x - w * 0.05, top.y - h * 0.01), Vector2(top.x, top.y - h * 0.01), Vector2(top.x + w * 0.005, top.y - h * 0.085), gold[1])
			MP._cap(img, top.x + w * 0.005, top.y - h * 0.075, top.x + w * 0.005, top.y - h * 0.03, 0.3, 0.3, GM._flat(GM.INK))
			GM._disc(img, top.x + w * 0.005, top.y - h * 0.03, 0.8, GM.INK)
			if col == 2:
				_star(img, top.x + w * 0.01, top.y - h * 0.095, w * 0.075, Color("#fff4b0"))
				_star(img, top.x - w * 0.09, top.y - h * 0.03, w * 0.04, Color("#fffbe0"))
		"mace":
			var head := Vector2(hand.x + w * 0.06, hand.y - h * 0.24)
			if col == 2:
				head = Vector2(hand.x + w * 0.09, hand.y - h * 0.1)
			elif col == 3:
				head = Vector2(hand.x + w * 0.05, hand.y - h * 0.14)
			GM._cp(img, hand.x - w * 0.02, hand.y + h * 0.1, head.x, head.y, w * 0.03, w * 0.024, wood)
			GM._o(img, head.x, head.y, w * 0.11, h * 0.082, MP._ramp("#5a5a66"), 0.0)
			GM._o(img, head.x - w * 0.02, head.y - h * 0.01, w * 0.06, h * 0.045, MP._ramp("#7a7a88"), 0.1)
			for i in 9:
				var a := float(i) * TAU / 9.0
				GM._tri(img, Vector2(head.x + cos(a - 0.22) * w * 0.1, head.y + sin(a - 0.22) * h * 0.075),
						Vector2(head.x + cos(a + 0.22) * w * 0.1, head.y + sin(a + 0.22) * h * 0.075),
						Vector2(head.x + cos(a) * w * 0.17, head.y + sin(a) * h * 0.125), steel[3])
		"sword":
			var tip := Vector2(hand.x + w * 0.1, hand.y - h * 0.34)
			if col == 2:
				tip = Vector2(hand.x + w * 0.17, hand.y - h * 0.18)
			elif col == 3:
				tip = Vector2(hand.x + w * 0.08, hand.y - h * 0.2)
			var gl := MP._ramp(str(p["glow"]))
			GM._cp(img, hand.x, hand.y, tip.x, tip.y, w * 0.026, w * 0.008, MP._ramp("#6a6a7a"))
			MP._cap(img, hand.x + 0.6, hand.y - 1.0, tip.x - 0.2, tip.y + 1.5, 0.28, 0.12, GM._flat(gl[3]))   # fil de la lame
			GM._o(img, hand.x, hand.y - h * 0.03, w * 0.075, h * 0.012, MP._ramp("#4a4a5a"), 0.1)
			GM._o(img, hand.x - 0.5, hand.y + h * 0.035, w * 0.022, h * 0.034, MP._ramp("#2a2228"))
		"orb":
			var ctr := Vector2(hand.x + w * 0.02, hand.y - h * 0.1)
			if col == 2:
				ctr = Vector2(hand.x + w * 0.08, hand.y - h * 0.16)
			var gl2 := MP._ramp(str(p["glow"]))
			GM._o(img, ctr.x, ctr.y, w * 0.095, w * 0.095, gl2, 0.35)
			GM._disc(img, ctr.x - w * 0.025, ctr.y - w * 0.03, w * 0.03, Color("#f4fff0"))
			_star(img, ctr.x + w * 0.02, ctr.y, w * 0.12 if col == 2 else w * 0.1, Color(gl2[4]))


## Pièce de l'accessoire qui passe DEVANT la main (livre, rouleau).
static func _item_front(img: Image, item: String, hand: Vector2, w: float, h: float, col: int, p: Dictionary) -> void:
	var gold := MP._ramp("#d8aa44")
	match item:
		"book":
			var bc := Vector2(hand.x - w * 0.02, hand.y - h * 0.03)
			if col == 2:
				bc = Vector2(hand.x + w * 0.02, hand.y - h * 0.08)
			var cover := MP._ramp("#5a3e72")
			GM._tp(img, bc.y - h * 0.1, bc.y + h * 0.1, bc.x - w * 0.12, bc.x + w * 0.1, bc.x - w * 0.125, bc.x + w * 0.105, cover)
			GM._tp(img, bc.y - h * 0.085, bc.y + h * 0.085, bc.x + w * 0.09, bc.x + w * 0.115, bc.x + w * 0.09, bc.x + w * 0.115, MP._ramp("#efe4c8"))
			GM._tp(img, bc.y - h * 0.07, bc.y + h * 0.07, bc.x - w * 0.09, bc.x + w * 0.065, bc.x - w * 0.09, bc.x + w * 0.065, MP._ramp("#7a5896"))
			GM._o(img, bc.x - w * 0.012, bc.y, w * 0.035, w * 0.035, gold, 0.2)
			_star(img, bc.x - w * 0.012, bc.y, w * 0.04, gold[4])
			GM._o(img, hand.x + w * 0.012, hand.y + h * 0.012, w * 0.042, w * 0.045, MP._ramp(str(p["skin"])), 0.05)
			if col == 2:   # le registre s'ouvre : lueur des pages
				_star(img, bc.x + w * 0.06, bc.y - h * 0.14, w * 0.1, Color(MP._ramp(str(p["glow"]))[4]))
		"scroll":
			var sc := Vector2(hand.x - w * 0.01, hand.y)
			var roll_len := h * (0.2 if col != 2 else 0.12)
			var parch := MP._ramp("#e8dcb0")
			GM._tp(img, sc.y, sc.y + roll_len, sc.x - w * 0.055, sc.x + w * 0.055, sc.x - w * 0.05, sc.x + w * 0.06, parch)
			GM._o(img, sc.x, sc.y, w * 0.062, h * 0.013, MP._ramp("#c8b070"), 0.1)
			GM._o(img, sc.x + 0.3, sc.y + roll_len, w * 0.065, h * 0.014, MP._ramp("#c8b070"), 0.0)
			for i in 4:   # lignes d'écriture, et un petit sceau rouge
				MP._cap(img, sc.x - w * 0.035, sc.y + roll_len * (0.2 + 0.2 * float(i)), sc.x + w * 0.04 - float(i % 2) * w * 0.02, sc.y + roll_len * (0.2 + 0.2 * float(i)), 0.25, 0.25, GM._flat(Color("#6a5638")))
			GM._disc(img, sc.x + w * 0.02, sc.y + roll_len * 0.85, w * 0.018, Color("#b8321a"))
			GM._o(img, hand.x + w * 0.012, hand.y + h * 0.006, w * 0.046, w * 0.046, MP._ramp(str(p["skin"])), 0.05)


## Bras en deux pièces (épaule, coude, main) : manche qui s'évase vers le poignet.
static func _arm(img: Image, s: Vector2, e: Vector2, hnd: Vector2, w: float, ramp: Array) -> void:
	GM._cp(img, s.x, s.y, e.x, e.y, w * 0.058, w * 0.07, ramp)
	GM._o(img, e.x, e.y, w * 0.072, w * 0.07, ramp, 0.05)
	GM._cp(img, e.x, e.y, hnd.x, hnd.y, w * 0.07, w * 0.09, ramp)


# ------------------------------------------------------------------ tête


static func _head(img: Image, hcx: float, hcy: float, hr: float, hv: float, w: float, h: float, col: int, f: int,
		p: Dictionary, skin: Array, hair: Array, trim: Array, gold: Array, lean: float, y0: float) -> void:
	var hat := str(p["hat"])
	var robe := MP._ramp(str(p["robe"]))
	var lin := MP._ramp(str(p["lining"]))
	var hc := MP._ramp(str(p["hat_c"]))
	var mode := 0
	if col == 3:
		mode = 1
	elif col == 2:
		mode = 2
	var iris := Color(str(p["eye"]))
	var gl := Color(str(p["glow"])) if p.has("glow") else Color.WHITE
	# cou
	if hat != "void":
		GM._cp(img, hcx - hr * 0.3, hcy + hv * 0.5, hcx - hr * 0.5, y0 + 3.0, w * 0.04, w * 0.05, MP._dim(skin))
	match hat:
		"hood":   # capuche : fond, puis visage, puis rebord
			GM._o(img, hcx - hr * 0.5, hcy - hv * 0.1, hr * 1.5, hv * 1.55, hc)
			GM._o(img, hcx + hr * 0.1, hcy + hv * 0.05, hr * 1.12, hv * 1.2, MP._ramp(str(p["lining"])))
			_face(img, hcx, hcy, hr * 0.95, hv * 0.98, w, h, p, skin)
		"void":   # un Naze : la capuche et rien dedans
			GM._o(img, hcx - hr * 0.3, hcy - hv * 0.1, hr * 1.4, hv * 1.5, hc, 0.0)
			GM._o(img, hcx + hr * 0.3, hcy + hv * 0.1, hr * 0.92, hv * 1.08, MP._ramp("#060408"), -0.3)
			GM._tri(img, Vector2(hcx - hr * 0.6, hcy - hv * 1.3), Vector2(hcx + hr * 0.2, hcy - hv * 1.9), Vector2(hcx + hr * 0.9, hcy - hv * 1.0), hc[3])   # pointe de la capuche
		"helm":
			GM._o(img, hcx, hcy, hr * 1.18, hv * 1.22, hc, 0.0)
			GM._o(img, hcx + hr * 0.2, hcy + hv * 0.05, hr * 0.8, hv * 0.62, MP._ramp("#0a0810"), -0.3)   # fente du heaume
			GM._tp(img, hcy - hv * 0.75, hcy - hv * 0.5, hcx - hr * 1.1, hcx + hr * 1.1, hcx - hr * 1.12, hcx + hr * 1.14, MP._ramp("#8a7a52"))
			for s in 2:
				var sg := -1.0 + 2.0 * float(s)
				GM._cp(img, hcx + sg * hr * 0.9, hcy - hv * 0.85, hcx + sg * hr * 1.9 + hr * 0.2, hcy - hv * 1.55, w * 0.04, w * 0.006, MP._ramp("#e8e0c8"))
				GM._cp(img, hcx + sg * hr * 1.9 + hr * 0.2, hcy - hv * 1.55, hcx + sg * hr * 1.7 + hr * 0.2, hcy - hv * 2.5, w * 0.03, w * 0.004, MP._ramp("#e8e0c8"))
		_:
			_face(img, hcx, hcy, hr, hv, w, h, p, skin)
	# yeux
	var erx := w * 0.03
	var ery := h * 0.023
	if hat == "void":
		for e in 2:
			var ex := hcx + hr * (0.05 + 0.65 * float(e))
			var ey := hcy + hv * 0.02
			var gr := erx * (1.0 if col != 2 else 1.5)
			if mode == 1:
				MP._cap(img, ex - erx, ey, ex + erx, ey, 0.3, 0.3, GM._flat(gl.darkened(0.2)))
			else:
				GM._o(img, ex, ey, gr, ery * 0.75, MP._ramp(str(p["glow"])), 0.5)
				MP._ellipse(img, ex, ey, gr * 0.55, ery * 0.4, Color.WHITE)
	elif hat == "helm":
		for e in 2:
			var ex2 := hcx + hr * (0.0 + 0.65 * float(e))
			MP._cap(img, ex2 - erx, hcy + hv * 0.0, ex2 + erx, hcy + hv * (0.0 if mode != 2 else -0.15), 0.5, 0.35, GM._flat(gl))
	else:
		for e in 2:
			var ex3 := hcx - hr * 0.2 + float(e) * hr * 0.75
			var ey3 := hcy - hv * 0.12
			GM._eye(img, ex3, ey3, erx, ery, iris, mode, 1 if e == 0 else -1)
			var lift := 0.0 if mode != 2 else 0.9
			var hb := MP._dim(hair) if str(p["hair"]) != "" else MP._dim(skin)
			MP._cap(img, ex3 - erx * 1.4, ey3 - ery * 2.0 - lift * float(1 - e) * 0.0, ex3 + erx * 1.4, ey3 - ery * (2.2 if e == 1 else 1.5) - lift * float(e), 0.7, 0.5, hb)
	# bouche, barbe, moustache
	var beard := str(p.get("beard", ""))
	if beard != "":
		var br := MP._ramp(beard)
		var blen := h * float(p.get("beard_len", 0.15))
		var cy0 := hcy + hv * 0.38
		GM._o(img, hcx + hr * 0.1, hcy + hv * 0.55, hr * 1.08, hv * 0.7, br, 0.0)
		GM._o(img, hcx + hr * 0.2, cy0 + blen * 0.45, hr * 1.0, blen * 0.62, br, 0.05)
		for i in 3:   # pointe de barbe en mèches
			var bx := hcx - hr * 0.5 + float(i) * hr * 0.62
			GM._tri(img, Vector2(bx - hr * 0.4, cy0 + blen * 0.8), Vector2(bx + hr * 0.4, cy0 + blen * 0.8), Vector2(bx + hr * 0.05, cy0 + blen * 1.08 + float(i % 2) * h * 0.012), br[2])
		for i in 5:
			var sx := hcx - hr * 0.7 + float(i) * hr * 0.42
			_stroke(img, Vector2(sx, cy0 + h * 0.02), Vector2(sx + hr * 0.12 * (float(i) - 2.0) * 0.5, cy0 + blen * 0.5), Vector2(hcx + hr * 0.15 + float(i - 2) * hr * 0.32, cy0 + blen * 1.0), br[1], 0.3)
		MP._cap(img, hcx + hr * 0.95, hcy + hv * 0.42, hcx + hr * 0.1, hcy + hv * 0.5, 0.9, 0.6, br)   # moustache
		if col != 0 or f == 1:
			GM._mouth(img, hcx + hr * 0.5, hcy + hv * 0.66, w * 0.07, col)
	elif hat != "void" and hat != "helm":
		var mc := MP._ramp(str(p.get("mustache", "")) if p.has("mustache") else "#8a6a5a")
		if p.has("mustache"):
			GM._o(img, hcx + hr * 0.62, hcy + hv * 0.42, hr * 0.42, hv * 0.2, mc, 0.1)
			GM._o(img, hcx + hr * 0.1, hcy + hv * 0.45, hr * 0.42, hv * 0.2, mc, 0.05)
			GM._tri(img, Vector2(hcx + hr * 0.95, hcy + hv * 0.3), Vector2(hcx + hr * 0.75, hcy + hv * 0.55), Vector2(hcx + hr * 1.5, hcy + hv * 0.8), mc[2])
		if col == 2 and bool(p.get("wooden", false)):   # langue de bois : brune, striée de nervures
			GM._mouth(img, hcx + hr * 0.5, hcy + hv * 0.68, w * 0.09, col)
			GM._cp(img, hcx + hr * 0.42, hcy + hv * 0.78, hcx + hr * 0.62, hcy + hv * 1.5, w * 0.03, w * 0.038, MP._ramp("#9a6a3a"))
			MP._cap(img, hcx + hr * 0.5, hcy + hv * 0.95, hcx + hr * 0.56, hcy + hv * 1.35, 0.25, 0.25, GM._flat(Color("#5a3a20")))
		else:
			GM._mouth(img, hcx + hr * 0.5, hcy + hv * 0.66, w * 0.08, col)
	# aura de regard (Gardien, Sauron) : les yeux brillent même au repos
	if hat == "hood" and mode != 1:
		for e in 2:
			var gx := hcx - hr * 0.2 + float(e) * hr * 0.75
			MP._ellipse(img, gx, hcy - hv * 0.12, erx * 0.5, ery * 0.5, gl)
	# couvre-chef
	match hat:
		"wizard":
			var base := Vector2(hcx - hr * 0.05, hcy - hv * 0.82)
			GM._o(img, base.x, base.y, hr * 2.2, h * 0.026, hc, 0.05)   # le large bord
			var tipy := h * 0.03
			var seg := 2
			var yy := int(base.y)
			while yy > int(tipy):
				var t0 := (base.y - float(yy)) / (base.y - tipy)
				var t1 := (base.y - float(yy - seg)) / (base.y - tipy)
				var c0 := base.x - hr * 1.7 * t0 * t0 + hr * 0.1 * t0
				var c1 := base.x - hr * 1.7 * t1 * t1 + hr * 0.1 * t1
				var w0 := hr * (1.1 * (1.0 - t0) + 0.12)
				var w1 := hr * (1.1 * (1.0 - t1) + 0.12)
				MP._trap(img, yy - seg, yy, c1 - w1, c1 + w1, c0 - w0, c0 + w0, hc, 0.0)
				yy -= seg
			var mid := Vector2(base.x - hr * 0.4, base.y - (base.y - tipy) * 0.45)
			var band := MP._ramp(str(p.get("band", "#c8322a")))
			GM._tp(img, base.y - h * 0.034, base.y - h * 0.004, base.x - hr * 1.28, base.x + hr * 1.3, base.x - hr * 1.34, base.x + hr * 1.38, band)
			GM._o(img, base.x + hr * 0.05, base.y - h * 0.019, hr * 0.42, h * 0.022, gold, 0.2)
			GM._o(img, base.x + hr * 0.05, base.y - h * 0.019, hr * 0.22, h * 0.011, MP._ramp("#2a2018"))
			for s in [Vector2(-0.4, -0.12), Vector2(0.3, -0.2), Vector2(-0.1, -0.04)]:   # étoiles brodées
				_star(img, mid.x + s.x * hr * 2.0, mid.y + s.y * h * 1.3, hr * 0.2, gold[3])
		"toque":
			var tb := hcy - hv * 0.75
			GM._tp(img, tb - h * 0.11, tb, hcx - hr * 1.05, hcx + hr * 1.0, hcx - hr * 0.88, hcx + hr * 0.92, hc)
			GM._o(img, hcx - hr * 0.02, tb - h * 0.11, hr * 1.22, h * 0.045, hc, 0.1)
			GM._folds(img, [hcx - hr * 0.55, hcx - hr * 0.1, hcx + hr * 0.4], tb - h * 0.1, tb - 1.0, hc, 0.0)
			GM._tp(img, tb - h * 0.025, tb + h * 0.01, hcx - hr * 0.98, hcx + hr * 0.96, hcx - hr * 1.0, hcx + hr * 0.98, MP._ramp("#c9a24a"))
		"crown":
			pass
		"hood":
			# rebord de la capuche par-dessus le front
			GM._cp(img, hcx - hr * 1.3, hcy + hv * 0.5, hcx - hr * 0.7, hcy - hv * 1.25, hr * 0.28, hr * 0.32, hc)
			GM._cp(img, hcx - hr * 0.7, hcy - hv * 1.25, hcx + hr * 0.9, hcy - hv * 0.95, hr * 0.32, hr * 0.2, hc)
			GM._tri(img, Vector2(hcx - hr * 0.8, hcy - hv * 1.4), Vector2(hcx + hr * 0.1, hcy - hv * 1.1), Vector2(hcx - hr * 0.3, hcy - hv * 2.15), hc[3])
			GM._o(img, hcx + hr * 0.0, hcy - hv * 1.1, w * 0.016, w * 0.016, gold, 0.2)   # fermoir
			GM._o(img, hcx + hr * 0.15, hcy - hv * 1.25, hr * 0.28, hv * 0.2, gold, 0.2)   # gemme du front
	if bool(p.get("crown", false)):   # couronne rouillée : un roi d'autrefois
		var cb := hcy - hv * 1.0
		GM._tp(img, cb - h * 0.012, cb + h * 0.012, hcx - hr * 0.95, hcx + hr * 0.95, hcx - hr * 1.0, hcx + hr * 1.0, MP._ramp("#9a8a6a"))
		for i in 5:
			var kx := hcx - hr * 0.85 + float(i) * hr * 0.42
			GM._tri(img, Vector2(kx - hr * 0.16, cb - h * 0.01), Vector2(kx + hr * 0.16, cb - h * 0.01), Vector2(kx, cb - h * (0.04 + 0.012 * float(i % 2))), MP._ramp("#b8a67a")[3])


## Visage : crâne ovale, nez, oreille (pointue chez les elfes).
static func _face(img: Image, hcx: float, hcy: float, hr: float, hv: float, w: float, h: float, p: Dictionary, skin: Array) -> void:
	GM._o(img, hcx, hcy, hr, hv, skin, 0.05)
	GM._o(img, hcx + hr * 0.96, hcy + hv * 0.18, w * 0.028, h * 0.03, skin, 0.1)   # nez
	if bool(p.get("ears", false)):   # oreille d'elfe, pointue
		GM._tri(img, Vector2(hcx - hr * 0.85, hcy - hv * 0.1), Vector2(hcx - hr * 0.95, hcy + hv * 0.5), Vector2(hcx - hr * 2.0, hcy - hv * 0.8), (skin[1] as Color))
	else:
		GM._o(img, hcx - hr * 0.95, hcy + hv * 0.1, w * 0.024, h * 0.03, MP._dim(skin))


# ------------------------------------------------------------------ Froton Anneauté

## Froton, rongé par l'anneau : petit, tapi dans sa cape à capuche, yeux rouges, rictus, dague dans une
## main et, à l'autre doigt, l'anneau qui brille. Même costume que son personnage (cape violette,
## tunique bleu-gris, cheveux courts bruns).
static func _thief(img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	var w := float(size.x)
	var h := float(size.y)
	var lean := -w * 0.06 if col == 3 else (w * 0.04 if col == 2 else 0.0)
	var cx := ox + w * 0.44 + lean * 0.5
	var dy := float(f) * 0.8
	var cloak := MP._ramp("#5a4a6a")
	var tunic := MP._ramp("#4a5a7a")
	var pants := MP._ramp("#3d3a48")
	var skin := MP._ramp("#e2ad84")
	var hair := MP._ramp("#3a2c2a")
	var boots := MP._ramp("#3a2a20")
	var gold := MP._ramp("#d8aa44")
	var steel := MP._ramp("#b8c0d0")
	var red := Color("#ff3a2a")
	var y0 := h * 0.4 + dy
	# jambes pliées, bottes
	GM._cp(img, cx - w * 0.1, h * 0.72 + dy, cx - w * 0.13, h * 0.93, w * 0.07, w * 0.06, MP._dim(pants))
	GM._cp(img, cx + w * 0.1, h * 0.72 + dy, cx + w * 0.15, h * 0.93, w * 0.075, w * 0.065, pants)
	GM._o(img, cx - w * 0.12, h * 0.95, w * 0.1, h * 0.032, MP._dim(boots))
	GM._o(img, cx + w * 0.18, h * 0.953, w * 0.125, h * 0.034, boots)
	# cape : large, dans le dos, qui traîne
	GM._tp(img, y0 + 2.0, h * 0.9, cx - w * 0.2 + lean, cx + w * 0.05, cx - w * 0.36, cx + w * 0.14, MP._dim(cloak))
	for i in 3:
		var tx := cx - w * 0.33 + float(i) * w * 0.13
		GM._tri(img, Vector2(tx, h * 0.89), Vector2(tx + w * 0.13, h * 0.89), Vector2(tx + w * 0.055, h * 0.95), MP._dim(cloak)[1])
	# tunique et ceinture
	GM._tp(img, y0, h * 0.74 + dy, cx - w * 0.19, cx + w * 0.2, cx - w * 0.17, cx + w * 0.2, tunic)
	GM._o(img, cx + w * 0.01, y0 + h * 0.06, w * 0.19, h * 0.07, tunic, 0.05)
	GM._folds(img, [cx - w * 0.08, cx + w * 0.1], y0 + h * 0.08, h * 0.72 + dy, tunic, 0.0)
	GM._tp(img, h * 0.66 + dy, h * 0.7 + dy, cx - w * 0.19, cx + w * 0.2, cx - w * 0.19, cx + w * 0.2, MP._ramp("#4a3226"))
	GM._o(img, cx + w * 0.03, h * 0.68 + dy, w * 0.04, h * 0.022, gold, 0.15)
	# épaulière de la cape
	GM._o(img, cx - w * 0.15, y0 + 1.0, w * 0.1, h * 0.05, cloak, 0.1)
	GM._o(img, cx + w * 0.17, y0 + 1.0, w * 0.09, h * 0.045, cloak, 0.1)
	# bras de derrière : tient la bourse volée (ou se tend à l'attaque)
	var bh := Vector2(cx - w * 0.24, h * 0.66 + dy * 0.5)
	if col == 2:
		bh = Vector2(cx - w * 0.28, h * 0.5)
	GM._cp(img, cx - w * 0.15, y0 + 3.0, bh.x, bh.y, w * 0.05, w * 0.044, MP._dim(cloak))
	GM._o(img, bh.x, bh.y + 1.0, w * 0.045, w * 0.045, MP._dim(skin))
	# bras armé et dague
	var hd := Vector2(cx + w * 0.33, h * 0.58)
	var tip := Vector2(hd.x + w * 0.16, hd.y - h * 0.18)
	if col == 2:
		hd = Vector2(cx + w * 0.29, h * 0.4)
		tip = Vector2(hd.x + w * 0.16, hd.y - h * 0.04)
	elif col == 3:
		hd = Vector2(cx + w * 0.24, h * 0.64)
		tip = Vector2(hd.x + w * 0.1, hd.y - h * 0.12)
	GM._cp(img, hd.x, hd.y, tip.x, tip.y, w * 0.032, w * 0.007, steel)
	MP._cap(img, hd.x + 0.5, hd.y - 1.0, tip.x - 0.3, tip.y + 1.2, 0.22, 0.1, GM._flat(steel[4]))
	GM._cp(img, cx + w * 0.17, y0 + 3.0, hd.x, hd.y, w * 0.052, w * 0.046, cloak)
	GM._o(img, hd.x, hd.y - h * 0.02, w * 0.07, h * 0.012, gold, 0.1)
	GM._o(img, hd.x - 0.3, hd.y, w * 0.056, w * 0.056, skin, 0.05)
	# l'anneau, au doigt : un point d'or qui brille
	GM._o(img, hd.x + w * 0.03, hd.y + h * 0.012, w * 0.022, w * 0.022, gold, 0.3)
	_star(img, hd.x + w * 0.03, hd.y + h * 0.012, w * (0.1 if col == 2 else 0.065), Color("#fff0a0"))
	# tête : grosse, enfoncée dans la capuche
	var hcx := cx + w * 0.07 + lean
	var hcy := h * 0.27 + dy
	var hr := w * 0.17
	var hv := h * 0.125
	GM._o(img, hcx - hr * 0.4, hcy - hv * 0.1, hr * 1.4, hv * 1.4, cloak, 0.0)   # capuche (fond)
	GM._cp(img, hcx - hr * 0.3, hcy + hv * 0.7, cx, y0 + 2.0, w * 0.05, w * 0.06, MP._dim(skin))
	GM._o(img, hcx, hcy, hr, hv, skin, 0.05)
	GM._tri(img, Vector2(hcx - hr * 0.9, hcy - hv * 0.2), Vector2(hcx - hr * 0.95, hcy + hv * 0.4), Vector2(hcx - hr * 1.65, hcy - hv * 0.6), (skin[1] as Color))   # oreille pointue
	GM._o(img, hcx + hr * 0.97, hcy + hv * 0.2, w * 0.034, h * 0.032, skin, 0.1)   # nez
	# mèches sous la capuche
	for i in 4:
		var mx := hcx - hr * 0.55 + float(i) * hr * 0.42
		GM._tri(img, Vector2(mx - hr * 0.2, hcy - hv * 0.85), Vector2(mx + hr * 0.22, hcy - hv * 0.85), Vector2(mx + hr * 0.05 * float(i - 1), hcy - hv * (0.2 + 0.08 * float(i % 2))), hair[2])
	var mode := 0
	if col == 3:
		mode = 1
	elif col == 2:
		mode = 2
	for e in 2:
		var ex := hcx - hr * 0.1 + float(e) * hr * 0.66
		var ey := hcy - hv * 0.05
		GM._eye(img, ex, ey, w * 0.036, h * 0.03, red, mode, 1 if e == 0 else -1)
		if mode != 1:
			MP._ellipse(img, ex + w * 0.004, ey + h * 0.003, w * 0.012, h * 0.01, Color("#fff0c0"))
			MP._cap(img, ex - w * 0.05, ey - h * 0.04, ex + w * 0.05, ey - h * (0.055 if e == 1 else 0.03), 0.6, 0.45, MP._dim(hair))
	# rictus : un sourire de travers, dents de rat
	if col == 3:
		GM._mouth(img, hcx + hr * 0.35, hcy + hv * 0.62, w * 0.1, col)
	elif col == 2:
		GM._mouth(img, hcx + hr * 0.35, hcy + hv * 0.62, w * 0.14, col)
	else:
		MP._curve(img, Vector2(hcx - hr * 0.1, hcy + hv * 0.52), Vector2(hcx + hr * 0.4, hcy + hv * 0.95), Vector2(hcx + hr * 0.85, hcy + hv * 0.45), GM.INK, 0.4)
		GM._tri(img, Vector2(hcx + hr * 0.3, hcy + hv * 0.7), Vector2(hcx + hr * 0.45, hcy + hv * 0.72), Vector2(hcx + hr * 0.38, hcy + hv * 0.95), Color("#f6f1ec"))
	# capuche : rebord par-dessus le front, pointe qui retombe
	GM._cp(img, hcx - hr * 1.3, hcy + hv * 0.7, hcx - hr * 0.8, hcy - hv * 1.0, hr * 0.17, hr * 0.2, cloak)
	GM._cp(img, hcx - hr * 0.8, hcy - hv * 1.0, hcx + hr * 0.8, hcy - hv * 0.9, hr * 0.2, hr * 0.1, cloak)
	GM._tri(img, Vector2(hcx - hr * 1.1, hcy - hv * 1.05), Vector2(hcx - hr * 0.1, hcy - hv * 1.0), Vector2(hcx - hr * 1.5, hcy - hv * 1.75), cloak[3])


## Goulûm, dit Trempette : maigre, voûté, pâle comme une endive, des yeux énormes, un poisson cru dans une main,
## et contre la poitrine, l'objet de toutes ses attentions. Quatre poses : repos, respiration, attaque, coup reçu.
static func _goulum(img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	var w := float(size.x)
	var h := float(size.y)
	var cx := ox + w * 0.42 + (-w * 0.03 if col == 3 else 0.0)
	var dy := float(f) * 0.9
	var skin := MP._ramp("#b9c3a6")
	var shade := MP._ramp("#8e9c8c")
	var rag := MP._ramp("#6e5a44")
	var gold := MP._ramp("#d8aa44")
	var dark := Color("#2b1b2e")
	var eye_c := Color("#d8f0f4")
	# jambes de grenouille, genoux hauts, longs pieds plats aux orteils écartés
	GM._cp(img, cx - w * 0.06, h * 0.66 + dy, cx - w * 0.2, h * 0.74, w * 0.05, w * 0.04, MP._dim(skin))
	GM._cp(img, cx - w * 0.2, h * 0.74, cx - w * 0.15, h * 0.93, w * 0.04, w * 0.032, MP._dim(skin))
	GM._cp(img, cx + w * 0.05, h * 0.66 + dy, cx + w * 0.2, h * 0.73, w * 0.052, w * 0.042, skin)
	GM._cp(img, cx + w * 0.2, h * 0.73, cx + w * 0.22, h * 0.93, w * 0.042, w * 0.034, skin)
	GM._o(img, cx - w * 0.17, h * 0.955, w * 0.11, h * 0.028, MP._dim(skin), 0.1)
	GM._o(img, cx + w * 0.27, h * 0.955, w * 0.12, h * 0.03, skin, 0.1)
	for t in 3:
		GM._o(img, cx + w * (0.35 + float(t) * 0.035), h * (0.945 + float(t) * 0.01), w * 0.03, h * 0.016, skin, 0.2)
		GM._o(img, cx - w * (0.05 + float(t) * 0.035), h * (0.945 + float(t) * 0.01), w * 0.03, h * 0.016, MP._dim(skin), 0.2)
	# bras de derrière : traîne jusqu'au sol, longue main à griffes
	GM._cp(img, cx - w * 0.1, h * 0.42 + dy, cx - w * 0.24, h * 0.62, w * 0.04, w * 0.032, MP._dim(skin))
	GM._cp(img, cx - w * 0.24, h * 0.62, cx - w * 0.22, h * 0.8, w * 0.032, w * 0.026, MP._dim(skin))
	GM._o(img, cx - w * 0.22, h * 0.82, w * 0.05, h * 0.026, MP._dim(skin), 0.1)
	# tronc voûté : l'épine saille, les côtes se comptent, le ventre est creux
	GM._o(img, cx, h * 0.52 + dy, w * 0.17, h * 0.19, skin, -0.1)
	GM._o(img, cx + w * 0.05, h * 0.57 + dy, w * 0.1, h * 0.085, skin, 0.3)
	for i in 5:
		var by := h * (0.3 + float(i) * 0.075) + dy
		GM._tri(img, Vector2(cx - w * 0.15, by - h * 0.022), Vector2(cx - w * 0.15, by + h * 0.022), Vector2(cx - w * (0.2 - float(i % 2) * 0.012), by), shade[1])
	for i in 4:
		var ry := h * (0.42 + float(i) * 0.04) + dy
		_stroke(img, Vector2(cx - w * 0.02, ry), Vector2(cx + w * 0.07, ry + h * 0.012), Vector2(cx + w * 0.13, ry - h * 0.004), shade[0], 0.34)
	# pagne de chiffon
	GM._tp(img, h * 0.64 + dy, h * 0.77 + dy, cx - w * 0.14, cx + w * 0.15, cx - w * 0.15, cx + w * 0.12, rag)
	GM._tri(img, Vector2(cx - w * 0.15, h * 0.77 + dy), Vector2(cx - w * 0.07, h * 0.77 + dy), Vector2(cx - w * 0.11, h * 0.83 + dy), rag[1])
	GM._tri(img, Vector2(cx + w * 0.02, h * 0.77 + dy), Vector2(cx + w * 0.12, h * 0.77 + dy), Vector2(cx + w * 0.08, h * 0.82 + dy), rag[2])
	# tête : trop grosse pour le cou, quelques cheveux, deux grandes oreilles
	var hx := cx + w * 0.12
	var hy := h * 0.24 + dy
	var rx := w * 0.17
	var ry2 := h * 0.125
	GM._cp(img, cx + w * 0.02, h * 0.38 + dy, hx - w * 0.02, hy + ry2 * 0.6, w * 0.045, w * 0.05, skin)
	GM._tri(img, Vector2(hx - rx * 0.7, hy - ry2 * 0.1), Vector2(hx - rx * 0.6, hy + ry2 * 0.55), Vector2(hx - rx * 1.9, hy - ry2 * 0.75), shade[2])
	GM._tri(img, Vector2(hx - rx * 0.55, hy - ry2 * 0.05), Vector2(hx - rx * 0.5, hy + ry2 * 0.4), Vector2(hx - rx * 1.45, hy - ry2 * 0.5), skin[2])
	GM._o(img, hx, hy, rx, ry2, skin, 0.05)
	GM._o(img, hx + rx * 0.8, hy + ry2 * 0.28, w * 0.05, h * 0.045, skin, 0.15)   # nez en pointe
	for i in 4:
		var hxx := hx - rx * 0.5 + float(i) * rx * 0.3
		_stroke(img, Vector2(hxx, hy - ry2 * 0.88), Vector2(hxx - w * 0.015, hy - ry2 * 1.35), Vector2(hxx - w * 0.04, hy - ry2 * 1.55 + float(i % 2) * 2.0), Color("#4a4034"), 0.3)
	var look := 0.0
	if col == 3:
		# coup reçu : yeux fermés, grimace
		for e in 2:
			var ex := hx - rx * 0.1 + float(e) * rx * 0.62
			_stroke(img, Vector2(ex - w * 0.045, hy - ry2 * 0.2), Vector2(ex, hy + ry2 * 0.15), Vector2(ex + w * 0.045, hy - ry2 * 0.2), dark, 0.45)
		_stroke(img, Vector2(hx + rx * 0.1, hy + ry2 * 0.62), Vector2(hx + rx * 0.45, hy + ry2 * 0.4), Vector2(hx + rx * 0.8, hy + ry2 * 0.66), dark, 0.45)
	else:
		for e in 2:
			var ex := hx - rx * 0.1 + float(e) * rx * 0.62
			var er := w * (0.062 if e == 0 else 0.056)
			GM._o(img, ex, hy - ry2 * 0.05, er, er * 1.08, MP._ramp("#e6f4f6"), 0.0)
			MP._ellipse(img, ex + er * 0.28 + look, hy - ry2 * 0.02, er * 0.5, er * 0.56, Color("#7fc8e0") if col != 2 else Color("#ffd870"))
			MP._ellipse(img, ex + er * 0.34 + look, hy - ry2 * 0.02, er * 0.22, er * 0.46, dark)
			MP._ellipse(img, ex + er * 0.05, hy - ry2 * 0.28, er * 0.2, er * 0.16, Color.WHITE)
		_stroke(img, Vector2(hx - rx * 0.4, hy - ry2 * 0.62), Vector2(hx + rx * 0.1, hy - ry2 * 0.5), Vector2(hx + rx * 0.45, hy - ry2 * (0.62 if col != 2 else 0.4)), dark, 0.38)
		if col == 2:
			# bouche grande ouverte : palais sombre, crocs
			GM._o(img, hx + rx * 0.42, hy + ry2 * 0.6, rx * 0.34, ry2 * 0.3, MP._ramp("#4a1424"), 0.0)
			for k in 4:
				var tx := hx + rx * (0.18 + float(k) * 0.14)
				GM._tri(img, Vector2(tx - 0.8, hy + ry2 * 0.44), Vector2(tx + 0.8, hy + ry2 * 0.44), Vector2(tx, hy + ry2 * 0.72), Color.WHITE)
		else:
			_stroke(img, Vector2(hx + rx * 0.1, hy + ry2 * 0.6), Vector2(hx + rx * 0.45, hy + ry2 * 0.8), Vector2(hx + rx * 0.8, hy + ry2 * 0.6), dark, 0.4)
			GM._tri(img, Vector2(hx + rx * 0.35, hy + ry2 * 0.64), Vector2(hx + rx * 0.45, hy + ry2 * 0.64), Vector2(hx + rx * 0.4, hy + ry2 * 0.84), Color("#f0ead8"))
	# bras de devant : serre le poisson ; à l'attaque, la griffe jaillit
	var sh := Vector2(cx + w * 0.1, h * 0.4 + dy)
	var fh := Vector2(cx + w * 0.3, h * 0.54 + dy * 0.5)
	if col == 2:
		fh = Vector2(cx + w * 0.27, h * 0.42)
	elif col == 3:
		fh = Vector2(cx + w * 0.22, h * 0.58)
	var el := Vector2((sh.x + fh.x) * 0.5 + w * 0.01, (sh.y + fh.y) * 0.5 + h * 0.06)
	GM._cp(img, sh.x, sh.y, el.x, el.y, w * 0.04, w * 0.034, skin)
	GM._cp(img, el.x, el.y, fh.x, fh.y, w * 0.034, w * 0.028, skin)
	# poisson cru, argenté, qui frétille
	var fish := Vector2(fh.x + w * 0.04, fh.y - h * (0.02 if col != 2 else -0.02) - dy * 0.4)
	GM._o(img, fish.x, fish.y, w * 0.13, h * 0.05, MP._ramp("#c8d4e0"), 0.1)
	GM._tri(img, Vector2(fish.x + w * 0.11, fish.y), Vector2(fish.x + w * 0.2, fish.y - h * 0.045), Vector2(fish.x + w * 0.2, fish.y + h * 0.045), Color("#9aa8b8"))
	GM._o(img, fish.x - w * 0.07, fish.y - h * 0.008, w * 0.014, h * 0.012, MP._ramp("#2b1b2e"), 0.0)
	_stroke(img, Vector2(fish.x - w * 0.02, fish.y - h * 0.035), Vector2(fish.x + w * 0.03, fish.y - h * 0.045), Vector2(fish.x + w * 0.08, fish.y - h * 0.03), Color("#f0f4f8"), 0.3)
	GM._o(img, fh.x, fh.y, w * 0.045, w * 0.04, skin, 0.1)
	for g in 3:
		GM._tri(img, Vector2(fh.x + float(g) * 1.2 - 1.0, fh.y + h * 0.02), Vector2(fh.x + float(g) * 1.2 + 0.2, fh.y + h * 0.02), Vector2(fh.x + float(g) * 1.2 + 0.4, fh.y + h * 0.065), skin[3])
	# l'anneau, à son cou : un petit éclat d'or contre la poitrine
	GM._o(img, cx + w * 0.1, h * 0.44 + dy, w * 0.022, w * 0.022, gold, 0.3)
	_star(img, cx + w * 0.1, h * 0.44 + dy, w * 0.07, Color("#fff0a0"))


## Uglouk, chef de brigade : un ouroukouille massif en toque de cuisinier de travers, tablier crème taché de ragoût,
## jambon de bras, deux défenses, une louche de guerre grande comme lui et, sous le bras, le bon de livraison
## (qu'il ne lâche jamais). Galons de brigadier en chevrons sur l'épaule, gamelle à la ceinture. Poses : repos,
## respiration, attaque (louche brandie, gueule ouverte), coup reçu ; le sort et le KO sont tirés de ces dessins.
static func _uglouk(img: Image, ox: int, f: int, col: int, size: Vector2i) -> void:
	var w := float(size.x)
	var h := float(size.y)
	var lean := -w * 0.05 if col == 3 else (w * 0.03 if col == 2 else 0.0)
	var cx := ox + w * 0.43 + lean * 0.5
	var dy := float(f) * 0.9
	var skin := MP._ramp("#7d9558")
	var leather := MP._ramp("#6a4a34")
	var apron := MP._ramp("#ece2c4")
	var pants := MP._ramp("#54483c")
	var boots := MP._ramp("#2e2420")
	var iron := MP._ramp("#a4aebc")
	var wood := MP._ramp("#8e6234")
	var gold := MP._ramp("#d8aa44")
	var stew := Color("#8a4a2a")
	var tusk := Color("#f2e8cc")
	var y0 := h * 0.36 + dy
	# jambes épaisses, bottes ferrées
	GM._cp(img, cx - w * 0.12, h * 0.66, cx - w * 0.15, h * 0.92, w * 0.09, w * 0.075, MP._dim(pants))
	GM._cp(img, cx + w * 0.12, h * 0.66, cx + w * 0.16, h * 0.92, w * 0.095, w * 0.08, pants)
	GM._o(img, cx - w * 0.16, h * 0.955, w * 0.12, h * 0.034, MP._dim(boots))
	GM._o(img, cx + w * 0.22, h * 0.958, w * 0.14, h * 0.036, boots)
	GM._tp(img, h * 0.9, h * 0.935, cx - w * 0.24, cx - w * 0.07, cx - w * 0.25, cx - w * 0.06, MP._dim(leather))
	GM._tp(img, h * 0.9, h * 0.935, cx + w * 0.07, cx + w * 0.24, cx + w * 0.06, cx + w * 0.26, leather)
	# bras de derrière : serre le bon de livraison contre la hanche
	var bh := Vector2(cx - w * 0.3, h * 0.62 + dy * 0.5)
	if col == 2:
		bh = Vector2(cx - w * 0.33, h * 0.52)
	GM._cp(img, cx - w * 0.2, y0 + h * 0.04, cx - w * 0.33, h * 0.5 + dy * 0.5, w * 0.075, w * 0.065, MP._dim(skin))
	GM._cp(img, cx - w * 0.33, h * 0.5 + dy * 0.5, bh.x, bh.y, w * 0.065, w * 0.055, MP._dim(skin))
	GM._tp(img, bh.y - h * 0.09, bh.y + h * 0.07, bh.x - w * 0.075, bh.x + w * 0.07, bh.x - w * 0.08, bh.x + w * 0.075, MP._ramp("#e8dcb8"))   # le bon, replié
	for i in 4:
		MP._cap(img, bh.x - w * 0.05, bh.y - h * 0.065 + h * 0.03 * float(i), bh.x + w * (0.05 - 0.012 * float(i % 2)), bh.y - h * 0.065 + h * 0.03 * float(i), 0.22, 0.22, GM._flat(Color("#6a5638")))
	GM._disc(img, bh.x + w * 0.035, bh.y + h * 0.045, w * 0.016, Color("#b8321a"))
	GM._o(img, bh.x - w * 0.01, bh.y + h * 0.02, w * 0.05, w * 0.05, MP._dim(skin))
	# tronc : gros, voûté, ventre en avant (cuir de brigadier)
	GM._o(img, cx, h * 0.5 + dy, w * 0.26, h * 0.2, leather, -0.05)
	GM._o(img, cx + w * 0.02, h * 0.62 + dy * 0.7, w * 0.275, h * 0.15, leather, 0.05)
	# tablier crème, taché
	GM._tp(img, y0 + h * 0.1, h * 0.84, cx - w * 0.17, cx + w * 0.2, cx - w * 0.23, cx + w * 0.26, apron)
	GM._folds(img, [cx - w * 0.07, cx + w * 0.1], y0 + h * 0.14, h * 0.82, apron, 0.0)
	GM._disc(img, cx - w * 0.08, h * 0.7, w * 0.04, stew)
	GM._disc(img, cx + w * 0.12, h * 0.77, w * 0.03, stew)
	GM._o(img, cx + w * 0.03, h * 0.62, w * 0.05, h * 0.02, MP._ramp("#b87a46"), 0.1)
	MP._cap(img, cx - w * 0.2, h * 0.74, cx - w * 0.04, h * 0.745, 0.3, 0.3, GM._flat(apron[1]))
	GM._tp(img, h * 0.835, h * 0.855, cx - w * 0.23, cx + w * 0.26, cx - w * 0.235, cx + w * 0.265, MP._ramp("#b8a878"))
	# bretelles du tablier et baudrier
	MP._cap(img, cx - w * 0.12, y0 + h * 0.05, cx - w * 0.08, y0 + h * 0.14, 0.9, 0.9, GM._flat(apron[1]))
	MP._cap(img, cx + w * 0.14, y0 + h * 0.05, cx + w * 0.12, y0 + h * 0.14, 0.9, 0.9, GM._flat(apron[1]))
	# ceinture, gamelle et trousseau
	GM._tp(img, h * 0.675, h * 0.715, cx - w * 0.26, cx + w * 0.28, cx - w * 0.265, cx + w * 0.285, MP._ramp("#3a2a20"))
	GM._o(img, cx + w * 0.03, h * 0.695, w * 0.045, h * 0.024, gold, 0.15)
	GM._o(img, cx - w * 0.18, h * 0.76, w * 0.055, h * 0.04, iron, 0.1)   # la gamelle
	GM._tp(img, h * 0.725, h * 0.735, cx - w * 0.225, cx - w * 0.135, cx - w * 0.225, cx - w * 0.135, iron)
	MP._curve(img, Vector2(cx - w * 0.2, h * 0.72), Vector2(cx - w * 0.18, h * 0.69), Vector2(cx - w * 0.15, h * 0.72), GM.INK, 0.3)
	# épaules : épaulières de cuir, galons en chevrons
	GM._o(img, cx - w * 0.25, y0 + h * 0.03, w * 0.11, h * 0.07, leather, 0.1)
	GM._o(img, cx + w * 0.26, y0 + h * 0.03, w * 0.115, h * 0.07, leather, 0.1)
	for i in 3:
		var gy := y0 + h * (0.0 + 0.026 * float(i))
		GM._tri(img, Vector2(cx - w * 0.31, gy + h * 0.03), Vector2(cx - w * 0.25, gy), Vector2(cx - w * 0.19, gy + h * 0.03), gold[3])
		GM._tri(img, Vector2(cx - w * 0.31, gy + h * 0.042), Vector2(cx - w * 0.25, gy + h * 0.012), Vector2(cx - w * 0.19, gy + h * 0.042), gold[1])
	# tête : mâchoire carrée, front bas, défenses
	var hcx := cx + w * 0.06 + lean
	var hcy := h * 0.245 + dy
	var hr := w * 0.15
	var hv := h * 0.1
	GM._cp(img, cx + w * 0.02, y0 + h * 0.03, hcx - w * 0.02, hcy + hv * 0.7, w * 0.09, w * 0.08, MP._dim(skin))
	GM._tri(img, Vector2(hcx - hr * 0.8, hcy - hv * 0.2), Vector2(hcx - hr * 0.8, hcy + hv * 0.5), Vector2(hcx - hr * 1.9, hcy - hv * 0.7), skin[2])   # oreille pointue
	GM._tri(img, Vector2(hcx - hr * 0.8, hcy - hv * 0.05), Vector2(hcx - hr * 0.8, hcy + hv * 0.4), Vector2(hcx - hr * 1.5, hcy - hv * 0.45), skin[1])
	GM._o(img, hcx, hcy, hr, hv, skin, 0.05)
	GM._o(img, hcx + hr * 0.12, hcy + hv * 0.52, hr * 0.98, hv * 0.62, skin, -0.05)   # la mâchoire
	GM._o(img, hcx + hr * 0.92, hcy + hv * 0.12, w * 0.05, h * 0.04, skin, 0.15)   # groin
	GM._disc(img, hcx + hr * 1.08, hcy + hv * 0.16, w * 0.009, GM.INK)
	# yeux : petits, rouges, sous un sourcil en bloc
	for e in 2:
		var ex := hcx - hr * 0.05 + float(e) * hr * 0.62
		var ey := hcy - hv * 0.12
		if col == 3:
			MP._cap(img, ex - w * 0.03, ey + 0.2, ex + w * 0.03, ey + 0.2, 0.4, 0.4, GM._flat(GM.INK))
		else:
			GM._eye(img, ex, ey, w * 0.026, h * 0.022, Color("#ff4a2a"), 2 if col == 2 else 0, 1 if e == 0 else -1)
	MP._cap(img, hcx - hr * 0.35, hcy - hv * 0.45, hcx + hr * 0.95, hcy - hv * (0.6 if col != 2 else 0.4), 1.0, 0.8, GM._flat(Color("#33422a")))
	# bouche et défenses
	if col == 2:
		GM._o(img, hcx + hr * 0.5, hcy + hv * 0.7, hr * 0.45, hv * 0.3, MP._ramp("#4a1424"), 0.0)
		for t in 4:
			var tx := hcx + hr * (0.15 + 0.22 * float(t))
			GM._tri(img, Vector2(tx - 0.8, hcy + hv * 0.52), Vector2(tx + 0.8, hcy + hv * 0.52), Vector2(tx, hcy + hv * 0.8), tusk)
	else:
		MP._curve(img, Vector2(hcx - hr * 0.1, hcy + hv * 0.72), Vector2(hcx + hr * 0.45, hcy + hv * (0.8 if col != 3 else 0.62)), Vector2(hcx + hr * 0.9, hcy + hv * 0.7), GM.INK, 0.4)
	GM._tri(img, Vector2(hcx + hr * 0.1, hcy + hv * 0.76), Vector2(hcx + hr * 0.3, hcy + hv * 0.76), Vector2(hcx + hr * 0.18, hcy + hv * 0.2), tusk)
	GM._tri(img, Vector2(hcx + hr * 0.62, hcy + hv * 0.76), Vector2(hcx + hr * 0.84, hcy + hv * 0.74), Vector2(hcx + hr * 0.76, hcy + hv * 0.22), tusk)
	# toque : haute, bouffante, de travers, tachée de ragoût
	var tx0 := hcx - hr * 0.1
	GM._tp(img, hcy - hv * 1.15, hcy - hv * 0.7, tx0 - hr * 0.95, tx0 + hr * 1.0, tx0 - hr * 1.0, tx0 + hr * 1.05, MP._ramp("#d8cfb4"))   # bandeau
	GM._o(img, tx0 - hr * 0.7, hcy - hv * 1.85, hr * 0.55, hv * 0.8, apron, 0.1)
	GM._o(img, tx0 + hr * 0.65, hcy - hv * 1.8, hr * 0.55, hv * 0.8, apron, 0.1)
	GM._o(img, tx0 - hr * 0.05, hcy - hv * 2.35, hr * 0.8, hv * 0.95, apron, 0.15)
	GM._o(img, tx0 + hr * 0.3, hcy - hv * 2.55, hr * 0.28, hv * 0.3, MP._ramp("#fffaf0"), 0.2)
	GM._disc(img, tx0 + hr * 0.45, hcy - hv * 1.5, w * 0.022, stew)
	GM._disc(img, tx0 - hr * 0.4, hcy - hv * 2.0, w * 0.016, MP._ramp("#c8bc98")[2])
	# bras armé : la louche de guerre
	var hand := Vector2(cx + w * 0.34, h * 0.6)
	var bowl := Vector2(hand.x + w * 0.1, hand.y - h * 0.5)
	if col == 2:
		hand = Vector2(cx + w * 0.22, h * 0.3)
		bowl = Vector2(hand.x + w * 0.14, hand.y - h * 0.13)
	elif col == 3:
		hand = Vector2(cx + w * 0.26, h * 0.66)
		bowl = Vector2(hand.x + w * 0.08, hand.y - h * 0.4)
	var sh := Vector2(cx + w * 0.26, y0 + h * 0.05)
	var elbow := Vector2(cx + w * 0.4, y0 + h * 0.22) if col != 2 else Vector2(cx + w * 0.4, y0 - h * 0.01)
	if col == 3:
		elbow = Vector2(cx + w * 0.33, y0 + h * 0.26)
	GM._cp(img, hand.x - w * 0.02, hand.y + h * 0.16, bowl.x, bowl.y, w * 0.026, w * 0.02, wood)   # manche de la louche
	GM._cp(img, sh.x, sh.y, elbow.x, elbow.y, w * 0.085, w * 0.08, skin)
	GM._o(img, elbow.x, elbow.y, w * 0.085, w * 0.08, skin, 0.05)
	GM._cp(img, elbow.x, elbow.y, hand.x, hand.y, w * 0.08, w * 0.06, skin)
	GM._o(img, hand.x, hand.y, w * 0.07, w * 0.062, skin, 0.1)
	for g in 3:   # phalanges
		GM._disc(img, hand.x - w * 0.02 + float(g) * w * 0.028, hand.y - w * 0.04, w * 0.012, skin[3])
	# le bol de la louche : fer cabossé, creux sombre, reflet
	var tilt := 0.0 if col != 2 else 0.35
	GM._o(img, bowl.x, bowl.y, w * 0.12, h * 0.062, iron, 0.0)
	GM._o(img, bowl.x + w * 0.012, bowl.y - h * 0.005, w * 0.095, h * 0.045, MP._ramp("#3a4250"), -0.2)
	GM._o(img, bowl.x + w * 0.025, bowl.y + h * 0.008 + tilt, w * 0.06, h * 0.02, MP._ramp("#9a5a32"), 0.1)   # le fond de sauce
	MP._cap(img, bowl.x - w * 0.1, bowl.y - h * 0.02, bowl.x - w * 0.02, bowl.y - h * 0.055, 0.35, 0.3, GM._flat(iron[4]))
	GM._o(img, bowl.x - w * 0.115, bowl.y + h * 0.018, w * 0.018, h * 0.016, iron, 0.2)   # bec verseur
	if col == 2:   # éclaboussure de sauce au coup
		GM._disc(img, bowl.x + w * 0.14, bowl.y - h * 0.04, w * 0.018, stew)
		GM._disc(img, bowl.x + w * 0.19, bowl.y + h * 0.02, w * 0.012, stew)
		GM._disc(img, bowl.x + w * 0.12, bowl.y + h * 0.06, w * 0.014, stew)
