extends RefCounted
## Peint les monstres par code. Chaque planche contient quatre poses côte à côte
## (repos, respiration, attaque, coup reçu), le monstre regardant vers la DROITE.
## Les deux premières sont dessinées à la main ; l'attaque et le coup reçu reprennent le
## repos avec un autre visage (FACES). Une passe de volume éclaire le haut gauche de chaque
## forme et assombrit le bas droit.
## Format documenté dans assets/sprites/README.md.

const PA = preload("res://src/gfx/pixel_art.gd")

const COLUMNS := 4
const IDLE := [0, 1]
const POSES := {"attack": 2, "hit": 3}

## Visage de chaque famille, en pixels dans la case : yeux [x, y, largeur, hauteur] et bouche.
const FACES := {
	"limace": {"eyes": [[26, 3, 3, 3], [31, 4, 3, 3]], "mouth": [30, 15, 4, 3]},
	"guepe": {"eyes": [[25, 13, 3, 3]], "mouth": [26, 17, 3, 2]},
	"champignon": {"eyes": [[12, 21, 3, 3], [17, 21, 3, 3]], "mouth": [14, 25, 4, 3]},
	"epouvantail": {"eyes": [[18, 12, 2, 2], [23, 12, 2, 2]], "mouth": [19, 16, 5, 2]},
	"sanglier": {"eyes": [[35, 15, 3, 2]], "mouth": [36, 21, 4, 2]},
	"grenouille": {"eyes": [[22, 6, 3, 3], [28, 7, 3, 3]], "mouth": [24, 14, 8, 3]},
	"follet": {"eyes": [[8, 16, 3, 3], [14, 16, 3, 3]], "mouth": [10, 21, 4, 3]},
	"rat": {"eyes": [[30, 12, 3, 3]], "mouth": [33, 18, 5, 2]},
	"coq": {"eyes": [[30, 8, 3, 3]], "mouth": [33, 12, 4, 2]},
	"chamois": {"eyes": [[34, 12, 3, 3]], "mouth": [37, 18, 4, 2]},
	"parchemin": {"eyes": [[9, 14, 3, 3], [16, 14, 3, 3]], "mouth": [11, 20, 6, 3]},
	"tampon": {"eyes": [[10, 9, 3, 3], [15, 9, 3, 3]], "mouth": [11, 14, 6, 2]},
}
const FAMILY := {"baveuse": "limace", "sangsue": "limace", "frelon": "guepe", "amanite": "champignon",
	"solitaire": "sanglier", "crapaud": "grenouille",
	"asticot": "limace", "vacherin": "limace", "mouche": "guepe", "moisi": "champignon"}

const SIZES := {
	"limace": Vector2i(38, 26),
	"baveuse": Vector2i(38, 26),
	"guepe": Vector2i(32, 30),
	"champignon": Vector2i(32, 34),
	"epouvantail": Vector2i(40, 56),
	"sangsue": Vector2i(38, 26),
	"frelon": Vector2i(32, 30),
	"amanite": Vector2i(32, 34),
	"sanglier": Vector2i(46, 32),
	"solitaire": Vector2i(46, 32),
	"grenouille": Vector2i(36, 28),
	"crapaud": Vector2i(36, 28),
	"follet": Vector2i(24, 32),
	"rat": Vector2i(40, 26),
	"coq": Vector2i(40, 40),
	"asticot": Vector2i(38, 26),
	"vacherin": Vector2i(38, 26),
	"mouche": Vector2i(32, 30),
	"moisi": Vector2i(32, 34),
	"chamois": Vector2i(44, 36),
	"parchemin": Vector2i(28, 36),
	"tampon": Vector2i(28, 34),
}

const WASP := ["#f2c23c", "#fbe38a", "#3a2420", "#cfe6f4", "#9cc0dc"]
const HORNET := ["#d8622c", "#f0a060", "#2a1a22", "#e0d0c0", "#b8a090"]
const MUSHROOM := ["#8a56a8", "#5c3878", "#b98ad0", "#f0dcf6"]
const AMANITA := ["#b8402e", "#7c2420", "#e07a56", "#fff2dc"]


static func has(kind: String) -> bool:
	return SIZES.has(kind)


static func paint(kind: String) -> Image:
	var size: Vector2i = SIZES.get(kind, Vector2i(24, 24))
	var img := PA.new_image(size.x * COLUMNS, size.y)
	for col in COLUMNS:
		var f := col if col < 2 else 0
		var ox := col * size.x
		match kind:
			"limace": _slug(img, ox, f, ["#5f8a3c", "#8fb552", "#c3dc7c", "#e9f2b8"], "#d9732e")
			"baveuse": _slug(img, ox, f, ["#6a4f8a", "#9a78b8", "#c9a8dc", "#ecd8f4"], "#f0c040")
			"guepe": _wasp(img, ox, f, WASP)
			"champignon": _mushroom(img, ox, f, MUSHROOM)
			"sangsue": _slug(img, ox, f, ["#2e3a44", "#4f6470", "#8aa2a8", "#cfe0dc"], "#c8324a")
			"frelon": _wasp(img, ox, f, HORNET)
			"amanite": _mushroom(img, ox, f, AMANITA)
			"sanglier": _boar(img, ox, f, ["#5a4032", "#7c5a44", "#a07c5e", "#3a2820"])
			"solitaire": _boar(img, ox, f, ["#4a4a54", "#6c6c78", "#9a9aa6", "#2a2a32"])
			"grenouille": _frog(img, ox, f, ["#4c7a3c", "#74a850", "#c8dc8c", "#2c4a2c"], "#e0a030")
			"crapaud": _frog(img, ox, f, ["#6a5a34", "#94804a", "#d8c890", "#3c3220"], "#d84a30")
			"follet": _wisp(img, ox, f)
			"epouvantail": _scarecrow(img, ox, f)
			"rat": _rat(img, ox, f)
			"coq": _rooster(img, ox, f)
			"asticot": _slug(img, ox, f, ["#b9a67a", "#e0d2a6", "#f4ecd0", "#fffaf0"], "#2b1b2e")
			"vacherin": _slug(img, ox, f, ["#c9a24a", "#e8cc7a", "#f6e6ac", "#fff6d8"], "#7a3030")
			"mouche": _wasp(img, ox, f, ["#4a5a3a", "#8aa05a", "#1e261a", "#dfeef4", "#a8c4d4"])
			"moisi": _mushroom(img, ox, f, ["#4a7a9a", "#2c4e6e", "#7cb0d0", "#e4f2f8"])
			"chamois": _chamois(img, ox, f)
			"parchemin": _scroll(img, ox, f)
			"tampon": _stamp(img, ox, f)
			_:
				PA.rect(img, ox + 4, 4, size.x - 8, size.y - 8, Color.MAGENTA)
		_volume(img, Rect2i(ox, 0, size.x, size.y))
		if col >= 2:
			_mood(img, ox, kind, col == 2)
		PA.outline(img, Rect2i(ox, 0, size.x, size.y))
	return img


## Donne du volume : lumière sur les bords tournés vers le haut gauche, ombre sur les
## bords tournés vers le bas droit.
static func _volume(img: Image, region: Rect2i) -> void:
	var src := img.get_region(region)
	var w := region.size.x
	var h := region.size.y
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var up := y == 0 or src.get_pixel(x, y - 1).a < 0.5
			var left := x == 0 or src.get_pixel(x - 1, y).a < 0.5
			var down := y == h - 1 or src.get_pixel(x, y + 1).a < 0.5
			var right := x == w - 1 or src.get_pixel(x + 1, y).a < 0.5
			if down or right:
				img.set_pixel(region.position.x + x, region.position.y + y, PA.shade(c, -0.22))
			elif up or left:
				img.set_pixel(region.position.x + x, region.position.y + y, PA.shade(c, 0.2))


## Visage d'attaque (yeux ouverts et furieux, gueule ouverte) ou de coup reçu (yeux
## plissés, bouche tordue).
static func _mood(img: Image, ox: int, kind: String, attack: bool) -> void:
	var face: Dictionary = FACES.get(str(FAMILY.get(kind, kind)), {})
	if face.is_empty():
		return
	var dark := _c("#2b1b2e")
	var maw := _c("#4a1424")
	for e: Array in face["eyes"]:
		var x := ox + int(e[0])
		var y := int(e[1])
		var w := int(e[2])
		var h := int(e[3])
		if attack:
			PA.rect(img, x, y, w, h, Color.WHITE)
			PA.rect(img, x, y, w, 1, dark)                 # paupière basse, regard noir
			PA.px(img, x + w - 1, y + h - 1, dark)
			PA.px(img, x + w - 1, y + 1, dark)
		else:
			# œil plissé : un trait fermé, relevé aux coins, par-dessus l'œil d'origine
			PA.rect(img, x, y + h / 2, w, 1, dark)
			if h >= 3:
				PA.px(img, x, y, dark)
				PA.px(img, x, y + h - 1, dark)
	var m: Array = face["mouth"]
	var mx := ox + int(m[0])
	var my := int(m[1])
	var mw := int(m[2])
	var mh := int(m[3])
	if attack:
		PA.rect(img, mx, my, mw, mh, maw)
		for i in range(0, mw, 2):
			PA.px(img, mx + i, my, Color.WHITE)
		if mh >= 3:
			PA.px(img, mx + mw / 2, my + mh - 1, _c("#d8506a"))
	else:
		for i in mw:
			PA.px(img, mx + i, my + 1 - (i % 2), dark)


static func _c(hex: String) -> Color:
	return Color.from_string(hex, Color.MAGENTA)


## Limace : corps bas et luisant, deux yeux au bout de leurs tiges, mine abattue.
static func _slug(img: Image, ox: int, f: int, pal: Array, eye_hex: String) -> void:
	var dark := _c(pal[0])
	var mid := _c(pal[1])
	var light := _c(pal[2])
	var shine := _c(pal[3])
	var squash := f   # la seconde pose s'étale un peu
	var by := 17.5 + squash * 0.5
	# traînée de bave derrière elle
	PA.rect(img, ox + 2, 23, 7, 1, shine)
	PA.px(img, ox + 1, 23, light)
	# queue effilée, corps, tête dressée
	PA.ellipse(img, ox + 9.0, by + 2.5, 6.0, 2.6, mid)
	PA.ellipse(img, ox + 17.0 - squash * 0.5, by, 11.0 + squash, 5.6 - squash * 0.6, mid)
	PA.ellipse(img, ox + 28.0 + squash, by - 3.0 + squash, 5.2, 6.2 - squash * 0.5, mid)
	# ventre clair, dos sombre
	PA.ellipse(img, ox + 17.0, by + 4.0, 12.0 + squash, 1.7, light)
	PA.ellipse(img, ox + 14.0, by - 2.6, 6.5, 1.6, dark)
	PA.ellipse(img, ox + 13.0, by - 3.2, 3.5, 0.9, light)
	PA.px(img, ox + 11, int(by) - 4, shine)
	PA.px(img, ox + 12, int(by) - 4, shine)
	# taches
	for p: Vector2i in [Vector2i(8, 0), Vector2i(19, 1), Vector2i(23, -1)]:
		PA.px(img, ox + p.x, int(by) + p.y, dark)
		PA.px(img, ox + p.x + 1, int(by) + p.y, dark)
	# tiges et yeux
	var hy := int(by) - 8 + squash
	PA.line(img, ox + 27 + squash, hy + 1, ox + 27 + squash, hy - 4, dark)
	PA.line(img, ox + 31 + squash, hy + 1, ox + 32 + squash, hy - 3, dark)
	PA.rect(img, ox + 26 + squash, hy - 6, 3, 3, Color.WHITE)
	PA.rect(img, ox + 31 + squash, hy - 5, 3, 3, Color.WHITE)
	PA.px(img, ox + 28 + squash, hy - 5, _c(eye_hex))
	PA.px(img, ox + 33 + squash, hy - 4, _c(eye_hex))
	# bouche tombante
	PA.px(img, ox + 30 + squash, int(by) - 1 + squash, dark)
	PA.px(img, ox + 31 + squash, int(by) - 2 + squash, dark)
	PA.px(img, ox + 32 + squash, int(by) - 1 + squash, dark)


## Guêpe à cidre : ventre rayé, ailes qui battent, dard généreux.
static func _wasp(img: Image, ox: int, f: int, pal: Array) -> void:
	var yellow := _c(pal[0])
	var yellow_l := _c(pal[1])
	var brown := _c(pal[2])
	var wing := _c(pal[3])
	var wing_d := _c(pal[4])
	var dy := f
	# ailes (derrière)
	if f == 0:
		PA.ellipse(img, ox + 15.0, 7.0 + dy, 6.5, 4.0, wing)
		PA.ellipse(img, ox + 9.0, 9.0 + dy, 4.5, 2.6, wing_d)
	else:
		PA.ellipse(img, ox + 15.0, 11.0 + dy, 7.5, 2.0, wing)
		PA.ellipse(img, ox + 9.0, 12.0 + dy, 5.0, 1.5, wing_d)
	# abdomen rayé
	var cx := ox + 10.0
	var cy := 18.0 + dy
	PA.ellipse(img, cx, cy, 7.0, 5.0, yellow)
	for y in range(int(cy) - 6, int(cy) + 7):
		for x in range(ox + 2, ox + 18):
			var ddx := (x + 0.5 - cx) / 7.0
			var ddy := (y + 0.5 - cy) / 5.0
			if ddx * ddx + ddy * ddy > 1.0:
				continue
			if (x - ox) % 5 < 2:
				PA.px(img, x, y, brown)
			elif ddy < -0.45:
				PA.px(img, x, y, yellow_l)
	# dard
	PA.line(img, ox + 3, int(cy) + 1, ox + 0, int(cy) + 3, brown)
	PA.px(img, ox + 1, int(cy) + 3, brown)
	# thorax et tête
	PA.ellipse(img, ox + 19.0, 16.0 + dy, 4.2, 4.2, brown)
	PA.ellipse(img, ox + 24.5, 15.0 + dy, 4.0, 4.0, yellow)
	PA.rect(img, ox + 25, 13 + dy, 3, 3, brown)
	PA.px(img, ox + 26, 13 + dy, Color.WHITE)
	PA.px(img, ox + 28, 17 + dy, brown)
	# antennes et pattes
	PA.line(img, ox + 25, 11 + dy, ox + 28, 8 + dy, brown)
	PA.line(img, ox + 23, 11 + dy, ox + 24, 7 + dy, brown)
	PA.line(img, ox + 17, 20 + dy, ox + 16, 23 + dy, brown)
	PA.line(img, ox + 20, 20 + dy, ox + 21, 23 + dy, brown)


## Champignon dormeur : gros chapeau violet, paupières closes, petits pieds.
static func _mushroom(img: Image, ox: int, f: int, pal: Array) -> void:
	var cap := _c(pal[0])
	var cap_d := _c(pal[1])
	var cap_l := _c(pal[2])
	var dot := _c(pal[3])
	var stem := _c("#eadfc6")
	var stem_d := _c("#c2b294")
	var dark := _c("#2b1b2e")
	var dy := f
	# pieds
	PA.ellipse(img, ox + 12.0, 30.5, 3.0, 1.6, stem_d)
	PA.ellipse(img, ox + 20.0, 30.5, 3.0, 1.6, stem_d)
	# pied du champignon
	PA.rect(img, ox + 11, 18 + dy, 10, 12 - dy, stem)
	PA.rect(img, ox + 18, 18 + dy, 3, 12 - dy, stem_d)
	PA.ellipse(img, ox + 16.0, 29.0, 5.6, 2.0, stem)
	# chapeau : demi-ellipse à bord plat
	var cy := 15.0 + dy
	for y in range(2, int(cy) + 4):
		for x in range(ox + 1, ox + 31):
			var ddx := (x + 0.5 - (ox + 16.0)) / 13.5
			var ddy := (y + 0.5 - cy) / (10.5 - dy)
			if ddx * ddx + ddy * ddy <= 1.0 and y <= int(cy) + 2:
				var c := cap
				if ddx > 0.45 or y >= int(cy) + 1:
					c = cap_d
				elif ddy < -0.6 and ddx < 0.1:
					c = cap_l
				PA.px(img, x, y, c)
	PA.ellipse(img, ox + 9.5, cy - 4.0, 2.4, 2.0, dot)
	PA.ellipse(img, ox + 18.0, cy - 7.0, 2.8, 2.2, dot)
	PA.ellipse(img, ox + 24.0, cy - 2.5, 1.8, 1.5, dot)
	# paupières closes et bouche ronde
	PA.rect(img, ox + 12, 22 + dy, 3, 1, dark)
	PA.rect(img, ox + 17, 22 + dy, 3, 1, dark)
	PA.px(img, ox + 15, 25 + dy, dark)
	PA.px(img, ox + 16, 25 + dy, dark)
	if f == 1:
		PA.px(img, ox + 16, 26, dark)


## Épouvantail avachi : traverse de travers, manches qui pendent, tête qui tombe.
static func _scarecrow(img: Image, ox: int, f: int) -> void:
	var wood := _c("#7a5230")
	var wood_d := _c("#553621")
	var shirt := _c("#a8683c")
	var shirt_d := _c("#7a4630")
	var patch := _c("#5f8a52")
	var sack := _c("#d9c08a")
	var sack_d := _c("#b09a66")
	var straw := _c("#f0d060")
	var hat := _c("#5a4630")
	var hat_d := _c("#3c2e20")
	var dark := _c("#2b1b2e")
	var sx := f   # la seconde pose penche d'un pixel de plus
	# piquet
	PA.rect(img, ox + 19, 30, 2, 24, wood)
	PA.rect(img, ox + 20, 30, 1, 24, wood_d)
	PA.rect(img, ox + 16, 53, 8, 1, wood_d)
	# traverse de travers
	for t in 2:
		PA.line(img, ox + 4 + sx, 22 + t, ox + 35 + sx, 27 + t, wood if t == 0 else wood_d)
	# chemise en toile, rapiécée
	PA.rect(img, ox + 12 + sx, 21, 15, 17, shirt)
	PA.rect(img, ox + 23 + sx, 21, 4, 17, shirt_d)
	PA.rect(img, ox + 14 + sx, 29, 4, 4, patch)
	PA.px(img, ox + 19 + sx, 25, dark)
	PA.px(img, ox + 19 + sx, 28, dark)
	# paille qui dépasse sous la chemise
	for i in 7:
		PA.rect(img, ox + 12 + sx + i * 2, 38, 1, 2 + (i % 2), straw)
	# manches pendantes et mains de paille
	PA.rect(img, ox + 4 + sx, 23, 5, 11, shirt)
	PA.rect(img, ox + 7 + sx, 23, 2, 11, shirt_d)
	PA.rect(img, ox + 30 + sx, 27, 5, 11, shirt)
	PA.rect(img, ox + 33 + sx, 27, 2, 11, shirt_d)
	for i in 3:
		PA.rect(img, ox + 4 + sx + i * 2, 34, 1, 3, straw)
		PA.rect(img, ox + 30 + sx + i * 2, 38, 1, 3, straw)
	# tête en sac, qui tombe sur l'épaule
	var hx := ox + 21.0 + sx * 1.5
	var hy := 14.0 + sx
	PA.ellipse(img, hx, hy, 6.5, 6.5, sack)
	PA.ellipse(img, hx + 3.0, hy + 1.0, 3.0, 4.5, sack_d)
	PA.rect(img, int(hx) - 4, int(hy) + 5, 8, 2, sack_d)
	# yeux cousus en croix, bouche en zigzag
	for e: int in [-3, 2]:
		PA.px(img, int(hx) + e, int(hy) - 2, dark)
		PA.px(img, int(hx) + e + 1, int(hy) - 1, dark)
		PA.px(img, int(hx) + e + 1, int(hy) - 2, sack_d)
		PA.px(img, int(hx) + e, int(hy) - 1, dark)
	for i in 5:
		PA.px(img, int(hx) - 3 + i, int(hy) + 2 + (i % 2), dark)
	# chapeau cabossé
	PA.rect(img, int(hx) - 9, int(hy) - 6, 18, 2, hat)
	PA.rect(img, int(hx) - 9, int(hy) - 5, 18, 1, hat_d)
	PA.rect(img, int(hx) - 5, int(hy) - 11, 9, 5, hat)
	PA.rect(img, int(hx) + 2, int(hy) - 11, 2, 5, hat_d)
	PA.px(img, int(hx) - 5, int(hy) - 11, Color(0, 0, 0, 0))
	PA.rect(img, int(hx) - 5, int(hy) - 7, 9, 1, _c("#b0483c"))


## Sanglier flapi : gros dos rond, hure basse, défenses, pattes courtes. Il traîne la patte.
static func _boar(img: Image, ox: int, f: int, pal: Array) -> void:
	var dark := _c(pal[0])
	var mid := _c(pal[1])
	var light := _c(pal[2])
	var deep := _c(pal[3])
	var dy := f   # la seconde pose s'affaisse d'un pixel
	# pattes (derrière le corps)
	for x: int in [9, 15, 26, 31]:
		PA.rect(img, ox + x, 23 + dy, 3, 8 - dy, deep)
		PA.rect(img, ox + x, 30, 3, 1, _c("#1c1418"))
	# corps, garrot, hure
	PA.ellipse(img, ox + 19.0, 16.0 + dy, 14.0, 8.5, mid)
	PA.ellipse(img, ox + 24.0, 13.0 + dy, 8.0, 6.0, mid)
	PA.ellipse(img, ox + 35.0, 18.0 + dy, 7.0, 6.0, mid)
	# ventre clair, dos sombre et soies hérissées
	PA.ellipse(img, ox + 18.0, 21.5 + dy, 11.0, 2.4, light)
	PA.ellipse(img, ox + 19.0, 10.5 + dy, 11.0, 2.6, dark)
	for i in 7:
		PA.px(img, ox + 9 + i * 3, 7 + dy + (i % 2), deep)
	# queue en tire-bouchon, détendue
	PA.px(img, ox + 4, 14 + dy, dark)
	PA.px(img, ox + 3, 15 + dy, dark)
	PA.px(img, ox + 3, 16 + dy, dark)
	PA.px(img, ox + 4, 17 + dy, dark)
	# oreille tombante
	PA.rect(img, ox + 30, 11 + dy, 3, 4, dark)
	PA.px(img, ox + 31, 15 + dy, dark)
	# groin, défenses, œil mi-clos
	PA.rect(img, ox + 40, 18 + dy, 4, 5, light)
	PA.px(img, ox + 43, 20 + dy, deep)
	PA.px(img, ox + 43, 22 + dy, deep)
	PA.px(img, ox + 39, 23 + dy, Color.WHITE)
	PA.px(img, ox + 40, 24 + dy, Color.WHITE)
	PA.px(img, ox + 40, 23 + dy, Color.WHITE)
	PA.rect(img, ox + 35, 15 + dy, 3, 1, deep)
	PA.px(img, ox + 36, 16 + dy, Color.WHITE)


## Grenouille bouffie : accroupie, gros yeux, gorge qui se gonfle à la seconde pose.
static func _frog(img: Image, ox: int, f: int, pal: Array, eye_hex: String) -> void:
	var dark := _c(pal[0])
	var mid := _c(pal[1])
	var light := _c(pal[2])
	var deep := _c(pal[3])
	# cuisse repliée et pied arrière
	PA.ellipse(img, ox + 9.0, 20.0, 7.0, 5.0, dark)
	PA.rect(img, ox + 4, 25, 10, 2, dark)
	PA.px(img, ox + 3, 26, dark)
	# corps et tête
	PA.ellipse(img, ox + 16.0, 17.0, 11.0, 7.5, mid)
	PA.ellipse(img, ox + 25.0, 13.0, 8.0, 6.5, mid)
	# dos sombre et verrues
	PA.ellipse(img, ox + 14.0, 11.5, 7.0, 2.2, dark)
	for p: Vector2i in [Vector2i(10, 15), Vector2i(15, 13), Vector2i(19, 16), Vector2i(13, 19)]:
		PA.px(img, ox + p.x, p.y, deep)
	# ventre et gorge (gonflée en respirant)
	PA.ellipse(img, ox + 17.0, 22.5, 8.5, 2.6, light)
	PA.ellipse(img, ox + 27.0, 19.0 + f * 0.5, 4.5 + f * 1.5, 3.0 + f * 1.5, light)
	# patte avant
	PA.rect(img, ox + 21, 22, 3, 4, mid)
	PA.rect(img, ox + 20, 26, 6, 1, dark)
	# yeux globuleux
	PA.ellipse(img, ox + 23.0, 7.0, 3.0, 3.0, mid)
	PA.ellipse(img, ox + 29.0, 8.0, 3.0, 3.0, mid)
	PA.rect(img, ox + 22, 6, 3, 3, _c(eye_hex))
	PA.rect(img, ox + 28, 7, 3, 3, _c(eye_hex))
	PA.px(img, ox + 24, 7, deep)
	PA.px(img, ox + 30, 8, deep)
	# bouche large et lasse
	PA.line(img, ox + 22, 15, ox + 32, 14, deep)
	PA.px(img, ox + 21, 16, deep)


## Feu follet : flamme pâle qui flotte, deux yeux fatigués. Il éclaire à peine.
static func _wisp(img: Image, ox: int, f: int) -> void:
	var outer := _c("#3fa8a0")
	var mid := _c("#7fe0c8")
	var core := _c("#e8fff0")
	var dark := _c("#1c4a50")
	var sway := f
	# pointe de la flamme, qui danse
	PA.ellipse(img, ox + 12.0 + sway, 6.0, 2.5, 4.5, outer)
	PA.ellipse(img, ox + 12.0 + sway * 0.5, 9.0, 4.0, 5.0, outer)
	PA.px(img, ox + 12 + sway * 2, 1, mid)
	# corps
	PA.ellipse(img, ox + 12.0, 18.0, 8.5, 9.0, outer)
	PA.ellipse(img, ox + 12.0, 19.0, 6.0, 7.0, mid)
	PA.ellipse(img, ox + 12.0, 21.0, 3.5, 4.0, core)
	PA.ellipse(img, ox + 12.0 + sway * 0.5, 11.0, 2.0, 3.0, mid)
	# étincelles qui retombent
	PA.px(img, ox + 3, 27 + sway, mid)
	PA.px(img, ox + 20, 29 - sway, mid)
	# yeux mi-clos, bouche tombante
	PA.rect(img, ox + 8, 17, 3, 1, dark)
	PA.rect(img, ox + 14, 17, 3, 1, dark)
	PA.px(img, ox + 9, 18, dark)
	PA.px(img, ox + 15, 18, dark)
	PA.px(img, ox + 11, 22, dark)
	PA.px(img, ox + 12, 21, dark)
	PA.px(img, ox + 13, 22, dark)


## Rat de cave : long, gris, les dents en avant, la queue qui traîne.
static func _rat(img: Image, ox: int, f: int) -> void:
	var dark := _c("#4a4650")
	var mid := _c("#7c7886")
	var light := _c("#aaa6b4")
	var pink := _c("#e0a0a8")
	var dy := f
	# pattes
	for x: int in [12, 15, 23, 26]:
		PA.rect(img, ox + x, 20 + dy, 2, 5 - dy, dark)
	# queue en point d'interrogation
	PA.line(img, ox + 8, 17 + dy, ox + 3, 18 + dy, pink)
	PA.line(img, ox + 3, 18 + dy, ox + 1, 14 + dy, pink)
	PA.px(img, ox + 1, 13 + dy, pink)
	# corps, ventre clair, tête, museau
	PA.ellipse(img, ox + 18.0, 16.0 + dy, 11.0, 6.0, mid)
	PA.ellipse(img, ox + 18.0, 19.5 + dy, 8.0, 2.4, light)
	PA.ellipse(img, ox + 29.0, 15.0 + dy, 6.0, 5.0, mid)
	PA.ellipse(img, ox + 35.0, 16.5 + dy, 3.5, 2.5, light)
	# oreille ronde, œil, nez, dents
	PA.ellipse(img, ox + 26.5, 9.5 + dy, 3.0, 3.0, mid)
	PA.ellipse(img, ox + 26.5, 9.5 + dy, 1.6, 1.6, pink)
	PA.rect(img, ox + 30, 12 + dy, 3, 3, Color.WHITE)
	PA.px(img, ox + 32, 13 + dy, dark)
	PA.px(img, ox + 38, 16 + dy, pink)
	PA.rect(img, ox + 35, 19 + dy, 2, 2, Color.WHITE)
	# moustaches
	PA.line(img, ox + 36, 17 + dy, ox + 39, 15 + dy, light)
	PA.line(img, ox + 36, 18 + dy, ox + 39, 19 + dy, light)


## Coq : droit comme un i, crête haute, queue en panache. Rien ne le ramollit.
static func _rooster(img: Image, ox: int, f: int) -> void:
	var rust := _c("#b4562c")
	var rust_l := _c("#e08a48")
	var gold := _c("#e8b84a")
	var red := _c("#d8302c")
	var green := _c("#2e8a6a")
	var blue := _c("#2a5aa0")
	var beak := _c("#f0c040")
	var dark := _c("#2b1b2e")
	var puff := f   # la poitrine se gonfle à la seconde pose
	# queue en panache, derrière le corps
	PA.line(img, ox + 9, 24, ox + 2, 8, green)
	PA.line(img, ox + 10, 23, ox + 5, 6, blue)
	PA.line(img, ox + 11, 24, ox + 9, 5, green)
	PA.line(img, ox + 8, 26, ox + 1, 14, blue)
	PA.line(img, ox + 3, 8, ox + 5, 7, green)
	# pattes et éperons
	PA.rect(img, ox + 15, 32, 2, 6, beak)
	PA.rect(img, ox + 22, 32, 2, 6, beak)
	PA.rect(img, ox + 13, 37, 5, 1, beak)
	PA.rect(img, ox + 20, 37, 5, 1, beak)
	# corps, poitrine, aile
	PA.ellipse(img, ox + 17.0, 25.0, 11.0, 8.5, rust)
	PA.ellipse(img, ox + 24.0, 25.0, 7.0 + puff, 7.0 + puff, rust_l)
	PA.ellipse(img, ox + 15.0, 25.0, 7.0, 4.5, _c("#8a3a20"))
	# cou et collerette dorée, tête
	PA.ellipse(img, ox + 26.0, 16.0, 4.5, 7.0, gold)
	PA.ellipse(img, ox + 29.0, 10.0, 4.5, 4.5, rust_l)
	# crête, barbillon, bec
	PA.ellipse(img, ox + 27.0, 4.5, 1.8, 2.2, red)
	PA.ellipse(img, ox + 29.5, 4.0, 1.8, 2.4, red)
	PA.ellipse(img, ox + 32.0, 5.0, 1.6, 2.0, red)
	PA.ellipse(img, ox + 33.0, 14.5, 1.4, 2.6, red)
	PA.rect(img, ox + 33, 9, 5, 2, beak)
	PA.px(img, ox + 37, 10, beak)
	PA.rect(img, ox + 33, 11, 4, 1, _c("#c89a2c"))
	# œil rond et sourcil sévère
	PA.rect(img, ox + 30, 8, 3, 3, Color.WHITE)
	PA.px(img, ox + 31, 9, dark)
	PA.rect(img, ox + 30, 7, 4, 1, dark)


## Chamois : sabots sûrs, cornes en crochet, regard de celui qui a déjà tout vu de là-haut.
static func _chamois(img: Image, ox: int, f: int) -> void:
	var dark := _c("#3a2c24")
	var mid := _c("#8a6a48")
	var light := _c("#c9a77a")
	var cream := _c("#efe2c4")
	var dy := f
	for x: int in [10, 13, 26, 29]:
		PA.rect(img, ox + x, 25 + dy, 2, 9 - dy, dark)
	PA.ellipse(img, ox + 20.0, 20.0 + dy, 12.0, 6.5, mid)
	PA.ellipse(img, ox + 20.0, 24.0 + dy, 9.0, 2.4, light)
	PA.ellipse(img, ox + 31.0, 15.0 + dy, 4.5, 6.5, mid)
	PA.ellipse(img, ox + 33.5, 14.0 + dy, 5.0, 4.5, mid)
	PA.ellipse(img, ox + 38.0, 17.0 + dy, 3.2, 2.6, cream)
	PA.rect(img, ox + 4, 16 + dy, 3, 3, dark)
	PA.line(img, ox + 31, 10 + dy, ox + 30, 4 + dy, dark)
	PA.line(img, ox + 30, 4 + dy, ox + 34, 2 + dy, dark)
	PA.line(img, ox + 34, 10 + dy, ox + 36, 4 + dy, dark)
	PA.line(img, ox + 36, 4 + dy, ox + 39, 4 + dy, dark)
	PA.ellipse(img, ox + 29.0, 9.5 + dy, 2.0, 1.4, light)
	PA.rect(img, ox + 34, 12 + dy, 3, 3, Color.WHITE)
	PA.rect(img, ox + 34, 12 + dy, 3, 1, dark)
	PA.px(img, ox + 36, 14 + dy, dark)
	PA.px(img, ox + 41, 17 + dy, dark)


## Parchemin vivant : un rouleau debout, couvert de petites lignes, le coin retroussé.
static func _scroll(img: Image, ox: int, f: int) -> void:
	var paper := _c("#e8d8a8")
	var shade := _c("#c2ae78")
	var ink := _c("#4a3a2c")
	var roll := _c("#b89a5c")
	var dy := f
	PA.rect(img, ox + 6, 6 + dy, 16, 22 - dy, paper)
	PA.rect(img, ox + 19, 6 + dy, 3, 22 - dy, shade)
	PA.ellipse(img, ox + 14.0, 6.0 + dy, 9.0, 3.2, roll)
	PA.ellipse(img, ox + 14.0, 6.0 + dy, 5.0, 1.4, shade)
	PA.ellipse(img, ox + 14.0, 28.0, 9.0, 3.2, roll)
	PA.ellipse(img, ox + 14.0, 28.0, 5.0, 1.4, shade)
	for y: int in [10, 12, 23, 25]:
		PA.rect(img, ox + 8, y + dy, 8 + (y % 3) * 2, 1, ink)
	PA.rect(img, ox + 4, 30, 4, 3, shade)
	PA.rect(img, ox + 20, 30, 4, 3, shade)
	PA.line(img, ox + 22, 14 + dy, ox + 25, 11 + dy, shade)
	PA.line(img, ox + 6, 14 + dy, ox + 3, 17 + dy, shade)


## Tampon zélé : bois, caoutchouc rouge, mine de celui qui valide tout ce qui passe.
static func _stamp(img: Image, ox: int, f: int) -> void:
	var wood := _c("#9a6a3c")
	var wood_d := _c("#5e3e22")
	var wood_l := _c("#c8945c")
	var rub := _c("#b83a3a")
	var rub_l := _c("#e06a5a")
	var dy := f
	PA.ellipse(img, ox + 14.0, 3.5 + dy, 3.5, 2.0, wood_l)
	PA.rect(img, ox + 9, 6 + dy, 10, 12 - dy, wood)
	PA.rect(img, ox + 16, 6 + dy, 3, 12 - dy, wood_d)
	PA.rect(img, ox + 4, 18, 20, 6, wood_d)
	PA.rect(img, ox + 4, 18, 20, 1, wood_l)
	PA.rect(img, ox + 3, 24, 22, 5, rub)
	PA.rect(img, ox + 3, 24, 22, 1, rub_l)
	PA.rect(img, ox + 6, 29, 5, 3, wood_d)
	PA.rect(img, ox + 17, 29, 5, 3, wood_d)
