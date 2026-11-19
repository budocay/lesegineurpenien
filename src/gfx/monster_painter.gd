extends RefCounted
## Peint les monstres par code. Chaque planche contient quatre poses côte à côte
## (repos, respiration, attaque, coup reçu), le monstre regardant vers la DROITE.
## Les deux premières sont dessinées à la main ; l'attaque et le coup reçu reprennent le
## repos avec un autre visage (FACES). Une passe de volume éclaire le haut gauche de chaque
## forme et assombrit le bas droit.
## Format documenté dans assets/sprites/README.md.

const PA = preload("res://src/gfx/pixel_art.gd")

const COLUMNS := 4
const PAD := 2   # marge vide, en pixels logiques, autour de chaque pose de la planche
const IDLE := [0, 1]
const POSES := {"attack": 2, "hit": 3}
## Les boss et les vedettes ont six poses : repos, respiration, attaque, coup reçu, sort (lévitation, bras levés,
## étincelles) et KO (effondré). Voir columns_of et poses_of.
const POSES6 := {"attack": 2, "hit": 3, "cast": 4, "ko": 5}
## Étincelles du sort, par espèce (la couleur de leur magie) ; « défaut » pour les autres.
const CAST_TINT := {"boss_sarumale": "#fff0a0", "boss_gardien": "#c8c8ff", "boss_grimace": "#c8a0ff", "boss_sauron": "#ff8a4a",
	"boss_naze": "#c8d0ff", "boss_naze_est": "#ff8a5a", "boss_naze_ouest": "#9aff8a", "boss_froton": "#fff0a0", "boss_goulum": "#9ad8f0",
	"naze_supreme": "#c8a0ff", "balourd": "#ff8a3a", "boss_uglouk": "#ffd070", "guetteur": "#9ad8f0", "gothmoque": "#ffb070"}

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
	"asticot": {"eyes": [[30, 10, 3, 3]], "mouth": [33, 14, 3, 2]},
	"vacherin": {"eyes": [[11, 12, 3, 3], [23, 12, 3, 3]], "mouth": [15, 16, 8, 3]},
	"mouche": {"eyes": [[25, 13, 3, 3]], "mouth": [26, 17, 3, 2]},
	"moisi": {"eyes": [[11, 21, 3, 3], [18, 21, 3, 3]], "mouth": [14, 26, 4, 2]},
	"chamois": {"eyes": [[34, 12, 3, 3]], "mouth": [37, 18, 4, 2]},
	"parchemin": {"eyes": [[9, 14, 3, 3], [16, 14, 3, 3]], "mouth": [11, 20, 6, 3]},
	"tampon": {"eyes": [[10, 9, 3, 3], [15, 9, 3, 3]], "mouth": [11, 14, 6, 2]},
}
const FAMILY := {"baveuse": "limace", "sangsue": "limace", "frelon": "guepe", "amanite": "champignon",
	"solitaire": "sanglier", "crapaud": "grenouille"}

## Espèces peintes en volumes (rampes de cinq tons, contour coloré). Les autres espèces
## passent par la vieille passe `_volume`.
const PAINTED := ["limace", "baveuse", "guepe", "champignon", "sangsue", "frelon", "amanite", "sanglier",
	"solitaire", "grenouille", "crapaud", "follet", "epouvantail", "rat", "coq", "asticot", "vacherin",
	"mouche", "moisi", "gobelin", "gobelin_pic", "gobelin_chef", "chauve", "troll", "guetteur", "goulum", "balourd",
	"ouroukouille", "ouroukouille_brocheur", "ouroukouille_petrisseur", "ouroukouille_chef", "paton", "ouargue",
	"corbeau", "hirsute", "hors_oeuvre",
	# chapitre 6 : peints dans gouda_monsters.gd
	"eveille", "eveille_veilleur", "roi_eveille", "boucanier", "saumure", "cassouletain", "gothmoque", "naze_supreme",
	"mammou", "dindon_farce", "grondine",
	# boss à taille humaine, peints en grand : boss_painter.gd
	"boss_sarumale", "boss_froton", "boss_grimace", "boss_gardien", "boss_sauron", "boss_naze", "boss_naze_est", "boss_naze_ouest", "boss_goulum"]

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
	"gobelin": Vector2i(34, 38),
	"gobelin_pic": Vector2i(34, 38),
	"gobelin_chef": Vector2i(40, 44),
	"chauve": Vector2i(56, 32),
	"troll": Vector2i(60, 66),
	"guetteur": Vector2i(58, 52),
	"goulum": Vector2i(38, 46),
	"balourd": Vector2i(68, 76),
	"ouroukouille": Vector2i(42, 50),
	"ouroukouille_brocheur": Vector2i(44, 50),
	"ouroukouille_petrisseur": Vector2i(46, 50),
	"ouroukouille_chef": Vector2i(50, 58),
	"paton": Vector2i(38, 36),
	"ouargue": Vector2i(52, 36),
	"corbeau": Vector2i(40, 36),
	"hirsute": Vector2i(42, 50),
	"hors_oeuvre": Vector2i(32, 36),
	"eveille": Vector2i(48, 64),
	"eveille_veilleur": Vector2i(56, 72),
	"roi_eveille": Vector2i(84, 100),
	"boucanier": Vector2i(52, 64),
	"saumure": Vector2i(76, 92),
	"cassouletain": Vector2i(56, 68),
	"gothmoque": Vector2i(96, 108),
	"naze_supreme": Vector2i(76, 100),
	"mammou": Vector2i(100, 76),
	"dindon_farce": Vector2i(104, 88),
	"grondine": Vector2i(100, 66),
	"boss_sarumale": Vector2i(72, 112),
	"boss_froton": Vector2i(64, 92),
	"boss_grimace": Vector2i(72, 104),
	"boss_gardien": Vector2i(72, 108),
	"boss_sauron": Vector2i(84, 112), "boss_goulum": Vector2i(64, 76),
	"boss_naze": Vector2i(72, 108),
	"boss_naze_est": Vector2i(72, 108),
	"boss_naze_ouest": Vector2i(72, 108),
	"boss_uglouk": Vector2i(92, 108),
}

const WASP := ["#f2c23c", "#fbe38a", "#3a2420", "#cfe6f4", "#9cc0dc"]
const HORNET := ["#d8622c", "#f0a060", "#2a1a22", "#e0d0c0", "#b8a090"]
const MUSHROOM := ["#8a56a8", "#5c3878", "#b98ad0", "#f0dcf6"]
const AMANITA := ["#b8402e", "#7c2420", "#e07a56", "#fff2dc"]


static func has(kind: String) -> bool:
	return SIZES.has(kind)


static func paint(kind: String) -> Image:
	return _render(kind, 1)


## Nombre de poses de la planche d'une espèce : six pour un boss ou une vedette (celles de HD_K à 6), quatre sinon.
static func columns_of(kind: String) -> int:
	return 6 if HD_K.get(kind, 0) == 6 else COLUMNS


static func poses_of(kind: String) -> Dictionary:
	return POSES6 if columns_of(kind) > COLUMNS else POSES


## Même peinture à la définition des héros : les formes sont dessinées directement sur une
## grille HD fois plus fine (volumes lissés, grain de peau, reflets, contour épais), puis
## relief et contour sont repris à cette définition. Taille dans le monde inchangée : la
## planche fait HD fois la planche de `paint`.
static func paint_hd(kind: String) -> Image:
	return _render(kind, HD_K.get(kind, HD))


## Marge ajoutée de chaque côté de la case (le peintre dessine décalé de cette valeur) : le dessin d'origine débordait.
const SHIFTX := {"chauve": 6, "dindon_farce": 8}
## Marge de travail (pixels logiques, de chaque côté) pour les dessins d'origine qui débordaient de leur case : ils
## sont peints dans une case plus large puis ramenés à la taille de la case (le monstre y est un peu plus petit, la
## case et donc les plaques gardent leur largeur), si bien que rien n'est coupé.
const EXTRA := {"limace": 4, "baveuse": 4, "sangsue": 4, "guepe": 4, "frelon": 4, "coq": 4, "asticot": 4}

static func _render(kind: String, k: int) -> Image:
	var size: Vector2i = SIZES.get(kind, Vector2i(24, 24))
	var shx: int = SHIFTX.get(kind, 0)
	var ex: int = EXTRA.get(kind, 0)
	var ws := size.x + 2 * ex   # largeur de la case de travail
	K = k
	var gr: Array = GRAIN.get(kind, GRAIN_DEFAULT)
	_ga = float(gr[0]) if k > 1 else 0.0
	_gs = float(gr[1]) * k / 4.0
	_gseed = kind.hash() & 0xffff
	var ncols := columns_of(kind)
	var img := PA.new_image(ws * k * ncols, size.y * k)
	for col in ncols:
		var pc := 2 if col == 4 else (3 if col == 5 else col)   # le sort se peint comme l'attaque (bras levés), le KO comme le coup reçu
		var f := pc if pc < 2 else 0
		var ox := col * ws + shx + ex
		var inner := Vector2i(size.x - 2 * shx, size.y)
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
			"asticot": _maggot(img, ox, f)
			"vacherin": _cheese(img, ox, f)
			"mouche": _fly(img, ox, f)
			"moisi": _mold(img, ox, f)
			"chamois": _chamois(img, ox, f)
			"parchemin": _scroll(img, ox, f)
			"tampon": _stamp(img, ox, f)
			"gobelin": _goblin(img, ox, f, pc, 0)
			"gobelin_pic": _goblin(img, ox, f, pc, 1)
			"gobelin_chef": _goblin(img, ox, f, pc, 2)
			"chauve": _bat(img, ox, f, pc)
			"troll": _troll(img, ox, f, pc)
			"guetteur": _watcher(img, ox, f, pc)
			"goulum": _gollum(img, ox, f, pc)
			"balourd": _balrog(img, ox, f, pc)
			"ouroukouille": _orc(img, ox, f, pc, 0)
			"ouroukouille_brocheur": _orc(img, ox, f, pc, 1)
			"ouroukouille_petrisseur": _orc(img, ox, f, pc, 2)
			"ouroukouille_chef": _orc(img, ox, f, pc, 3)
			"paton": _dough(img, ox, f, pc)
			"ouargue": _warg(img, ox, f, pc)
			"corbeau": _crow(img, ox, f, pc)
			"hirsute": _hillman(img, ox, f, pc)
			"hors_oeuvre": _canape(img, ox, f, pc)
			"eveille", "eveille_veilleur", "roi_eveille", "boucanier", "saumure", "cassouletain", "gothmoque", "naze_supreme", "mammou", "dindon_farce", "grondine":
				load("res://src/gfx/gouda_monsters.gd").paint(kind, img, ox, f, pc, inner)
			"boss_sarumale", "boss_froton", "boss_grimace", "boss_gardien", "boss_sauron", "boss_naze", "boss_naze_est", "boss_naze_ouest", "boss_goulum", "boss_uglouk":
				load("res://src/gfx/boss_painter.gd").paint(kind, img, ox, f, pc, inner)
			_:
				_rect(img, ox + 4, 4, size.x - 8, size.y - 8, Color.MAGENTA)
		if col == 4:
			_cast_fx(img, Rect2i((ox - shx - ex) * k, 0, ws * k, size.y * k), kind)
		elif col == 5:
			_slump(img, Rect2i((ox - shx - ex) * k, 0, ws * k, size.y * k))
		if not PAINTED.has(kind):
			_volume(img, Rect2i((ox - shx - ex) * k, 0, ws * k, size.y * k))
		if pc >= 2:
			_mood(img, ox, kind, pc == 2)
		if k > 1:
			_marks(img, Rect2i(ox * k, 0, inner.x * k, inner.y * k), kind)
			_finish_hd(img, Rect2i((ox - shx - ex) * k, 0, ws * k, size.y * k), kind, pc)
	# marge de PAD pixels logiques autour de chaque pose, puis le contour : un dessin qui touche le bord de sa
	# case n'est plus coupé net (et aucun pixel opaque ne reste à moins d'un pixel du bord : voir le test)
	var pad := PAD * k
	var fw := (size.x + 2 * PAD) * k
	var out := PA.new_image(fw * ncols, (size.y + 2 * PAD) * k)
	for col in ncols:
		var cell := img.get_region(Rect2i(col * ws * k, 0, ws * k, size.y * k))
		var at := Vector2i(col * fw + pad, pad)
		if ex > 0:   # case de travail trop large : on la ramène à la largeur de la case (même rapport), les pieds en bas
			var nh := int(round(float(size.y * k) * float(size.x) / float(ws)))
			cell = _shrink(cell, size.x * k, nh, k)
			at.y += size.y * k - nh
		out.blit_rect(cell, Rect2i(0, 0, cell.get_width(), cell.get_height()), at)
		_outline(out, Rect2i(col * fw, 0, fw, out.get_height()))
	K = 1
	_ga = 0.0
	return out


## Pose de sort : le dessin d'attaque (bras levés) soulevé du sol, entouré d'étincelles de la couleur de la magie de
## l'espèce (CAST_TINT). Tout reste à trois pixels logiques du bord de la case.
static func _cast_fx(img: Image, region: Rect2i, kind: String) -> void:
	var src := img.get_region(region)
	var b := PA.opaque_bounds(src, Rect2i(0, 0, region.size.x, region.size.y))
	var lift := clampi(int(round(float(region.size.y) * 0.035)), 0, maxi(0, b.position.y - 3 * K))
	for y in region.size.y:
		for x in region.size.x:
			img.set_pixel(region.position.x + x, region.position.y + y, Color(0, 0, 0, 0))
	img.blit_rect(src, Rect2i(0, 0, region.size.x, region.size.y), Vector2i(region.position.x, region.position.y - lift))
	var tint := _c(str(CAST_TINT.get(kind, "#d8c8ff")))
	var lw := float(region.size.x) / float(K)
	var lh := float(region.size.y) / float(K)
	var o := Vector2(float(region.position.x) / float(K), 0.0)
	var bx0 := float(b.position.x) / float(K)
	var bx1 := float(b.end.x) / float(K)
	var by0 := float(b.position.y - lift) / float(K)
	var by1 := float(b.end.y - lift) / float(K)
	var bw := bx1 - bx0
	var bh := by1 - by0
	var spots := [[bx0 - 0.02 * bw, by0 + 0.22 * bh, 4.2], [bx1 + 0.02 * bw, by0 + 0.12 * bh, 5.0], [bx0 + 0.1 * bw, by0 + 0.02 * bh, 3.0],
		[bx1 - 0.05 * bw, by0 + 0.46 * bh, 3.4], [bx0 + 0.02 * bw, by0 + 0.56 * bh, 2.8], [bx0 + 0.5 * bw, by0 - 0.01 * bh, 3.6]]
	for sp: Array in spots:
		var cx := clampf(float(sp[0]), 4.0, lw - 4.0)
		var cy := clampf(float(sp[1]), 4.0, lh - 4.0)
		var r := float(sp[2])
		var at := o + Vector2(cx, cy)
		_tri(img, at + Vector2(-r * 0.3, 0), at + Vector2(r * 0.3, 0), at + Vector2(0, -r), tint)
		_tri(img, at + Vector2(-r * 0.3, 0), at + Vector2(r * 0.3, 0), at + Vector2(0, r), tint)
		_tri(img, at + Vector2(0, -r * 0.3), at + Vector2(0, r * 0.3), at + Vector2(-r, 0), tint)
		_tri(img, at + Vector2(0, -r * 0.3), at + Vector2(0, r * 0.3), at + Vector2(r, 0), tint)
		_ellipse(img, at.x, at.y, r * 0.22, r * 0.22, Color.WHITE)
	for i in 5:   # petits points qui montent
		var px := o.x + lerpf(bx0, bx1, _hash(i * 3 + 1, 41)) 
		var py := lerpf(by0 + 0.1 * bh, by1 - 0.2 * bh, _hash(i * 5 + 2, 43))
		_ellipse(img, clampf(px, o.x + 4.0, o.x + lw - 4.0), clampf(py, 4.0, lh - 4.0), 0.7, 0.7, tint.lightened(0.3))


## Pose de KO : le dessin de coup reçu, tassé puis basculé en arrière (vers la gauche : le monstre regarde à droite),
## pieds au sol, ramené à la taille de la case, un peu assombri. Rotation autour des pieds, échantillonnage au plus proche
## (pixel art) ou lissé (HD) sur l'alpha.
const KO_ANGLE := 1.25   # radians (54 degrés)
const KO_SQUASH := 0.8

static func _slump(img: Image, region: Rect2i) -> void:
	var w := region.size.x
	var h := region.size.y
	var src := img.get_region(Rect2i(region.position.x, region.position.y, w, h))
	var b := PA.opaque_bounds(src, Rect2i(0, 0, w, h))
	var pivot := Vector2(float(b.position.x + b.end.x) * 0.5, float(b.end.y))
	var angle := KO_ANGLE if float(b.size.x) < float(b.size.y) * 1.2 else 0.45   # une bête plus large que haute (limace) bascule à peine : couchée à la verticale elle ne serait plus qu'une tranche
	var ca := cos(angle)
	var sa := sin(angle)
	# les coins du dessin, tassé puis tourné, donnent la place qu'il prend : on le réduit pour qu'il tienne dans la case
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for corner: Vector2 in [Vector2(b.position), Vector2(b.end.x, b.position.y), Vector2(b.position.x, b.end.y), Vector2(b.end)]:
		var d := corner - pivot
		d.y *= KO_SQUASH
		var q := Vector2(d.x * ca + d.y * sa, -d.x * sa + d.y * ca)   # rotation vers la gauche (anti-horaire à l'écran)
		lo = Vector2(minf(lo.x, q.x), minf(lo.y, q.y))
		hi = Vector2(maxf(hi.x, q.x), maxf(hi.y, q.y))
	var margin := float(3 * K)
	var fit := minf(1.0, minf((float(w) - 2.0 * margin) / (hi.x - lo.x), (float(h) - 2.0 * margin) / (hi.y - lo.y)))
	# destination : le corps couché, pieds au bas de la case (même ligne de sol), centré
	var dest_base := Vector2(float(w) * 0.5 - (lo.x + hi.x) * 0.5 * fit, float(h) - margin - hi.y * fit)
	for y in h:
		for x in w:
			var d := (Vector2(x, y) - dest_base) / fit
			var sx := d.x * ca - d.y * sa   # rotation inverse
			var sy := d.x * sa + d.y * ca
			sy /= KO_SQUASH
			var p := pivot + Vector2(sx, sy)
			var c := Color(0, 0, 0, 0)
			if p.x >= 0.0 and p.y >= 0.0 and p.x < float(w) and p.y < float(h):
				c = src.get_pixel(int(p.x), int(p.y))
			if c.a >= 0.5:
				c = PA.shade(Color(c.r, c.g, c.b, 1.0), -0.12)
			else:
				c = Color(0, 0, 0, 0)
			img.set_pixel(region.position.x + x, region.position.y + y, c)
	# le plus bas pixel réel (et non le coin du cadre tourné) pose sur la ligne de sol : le corps couché ne flotte pas
	var laid := img.get_region(Rect2i(region.position.x, region.position.y, w, h))
	var lb := PA.opaque_bounds(laid, Rect2i(0, 0, w, h))
	var drop := (h - int(margin)) - lb.end.y
	if lb.size.x > 0 and drop > 0:
		var clear := Image.create(w, h, false, Image.FORMAT_RGBA8)
		img.blit_rect(clear, Rect2i(0, 0, w, h), region.position)
		img.blit_rect(laid, Rect2i(0, 0, w, h - drop), region.position + Vector2i(0, drop))


## Réduit une pose (couleur étalée sous la transparence voisine avant, pour qu'aucun liseré sombre ne naisse au bord).
static func _shrink(src: Image, w: int, h: int, k: int) -> Image:
	var tmp := src.duplicate() as Image
	if k <= 1:
		tmp.resize(w, h, Image.INTERPOLATE_NEAREST)
		return tmp
	var fw := tmp.get_width()
	var fh := tmp.get_height()
	for _pass in 3:   # étale la couleur des bords sous les pixels transparents voisins
		var prev := tmp.duplicate() as Image
		for y in fh:
			for x in fw:
				if prev.get_pixel(x, y).a >= 0.5:
					continue
				var best := Color(0, 0, 0, 0)
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx := x + d.x
					var ny := y + d.y
					if nx >= 0 and ny >= 0 and nx < fw and ny < fh and prev.get_pixel(nx, ny).a >= 0.5:
						best = prev.get_pixel(nx, ny)
						break
				if best.a > 0.0:
					tmp.set_pixel(x, y, Color(best.r, best.g, best.b, 0.0))
	tmp.resize(w, h, Image.INTERPOLATE_LANCZOS)
	return tmp


## Version agrandie d'une planche de monstre (chaque pose séparément, pour qu'aucune ne
## déborde sur sa voisine) : les héros sont dessinés en cases de 88 x 132 px, les monstres sur
## de petites cases agrandies bien plus fort à l'écran (un boss : dix pixels d'écran par pixel
## dessiné). On les repeint donc plus fin : couleurs lissées, contour de la silhouette arrondi
## (les marches d'escalier des diagonales disparaissent), sans toucher à la planche d'origine ni
## à la taille du monstre dans le monde (la texture change de définition, pas de dimensions).
## Les couleurs sont d'abord étalées sous la transparence voisine : pas de liseré sombre au bord.
const UPSCALE := 3

## Définition de la peinture HD : chaque pixel logique de `paint` devient HD x HD pixels.
const HD := 4
## Les gros monstres (boss, vedettes) sont affichés très agrandis : finesse supérieure.
const HD_K := {"vacherin": 6, "baveuse": 6, "goulum": 6, "troll": 6, "guetteur": 6, "balourd": 6, "crapaud": 6,
	"solitaire": 6, "coq": 6, "ouroukouille_chef": 6, "ouroukouille_petrisseur": 6, "gobelin_chef": 6, "hirsute": 6, "ouargue": 6,
	# chapitre 6 (gouda_monsters.gd)
	"eveille": 6, "eveille_veilleur": 6, "roi_eveille": 6, "boucanier": 6, "saumure": 6, "cassouletain": 6,
	"gothmoque": 6, "naze_supreme": 6, "mammou": 6, "dindon_farce": 6, "grondine": 6,
	"boss_sarumale": 6, "boss_froton": 6, "boss_grimace": 6, "boss_gardien": 6, "boss_sauron": 6, "boss_naze": 6,
	"boss_naze_est": 6, "boss_naze_ouest": 6, "boss_goulum": 6, "boss_uglouk": 6}
static var K := 1                # facteur de la peinture en cours
static var _ga := 0.0            # amplitude du grain de matière (0 : aucun)
static var _gs := 3.0            # taille du grain, en pixels de la grille fine
static var _gseed := 0
## Grain [amplitude, taille] par espèce ; les peaux lisses grainent peu, poils et croûtes beaucoup.
const GRAIN_DEFAULT := [0.16, 3.0]
const GRAIN := {"limace": [0.1, 5.0], "baveuse": [0.1, 5.0], "sangsue": [0.1, 5.0], "asticot": [0.1, 5.0],
	"vacherin": [0.2, 4.0], "grenouille": [0.2, 3.0], "crapaud": [0.26, 3.0], "rat": [0.2, 2.0],
	"sanglier": [0.22, 2.0], "solitaire": [0.22, 2.0], "ouargue": [0.22, 2.0], "hirsute": [0.22, 2.0],
	"troll": [0.24, 4.0], "balourd": [0.24, 4.0], "paton": [0.14, 5.0],
	"boss_sarumale": [0.05, 6.0], "boss_froton": [0.1, 5.0], "boss_grimace": [0.08, 5.0], "boss_gardien": [0.07, 6.0],
	"boss_sauron": [0.12, 5.0], "boss_uglouk": [0.14, 4.0], "boss_naze": [0.08, 5.0], "boss_naze_est": [0.08, 5.0], "boss_naze_ouest": [0.08, 5.0], "boss_goulum": [0.1, 5.0]}
## Espèces luisantes : petits reflets mouillés dans les tons clairs.
const SHINY := ["limace", "baveuse", "sangsue", "grenouille", "crapaud", "asticot", "vacherin", "paton", "moisi"]


static func upscale(img: Image, columns: int, k: int = UPSCALE) -> Image:
	var fw := img.get_width() / columns
	var fh := img.get_height()
	var out := PA.new_image(fw * k * columns, fh * k)
	for col in columns:
		var cell := img.get_region(Rect2i(col * fw, 0, fw, fh))
		var src := cell.duplicate() as Image
		for _pass in 2:   # étale la couleur des bords sous les pixels transparents voisins
			var prev := src.duplicate() as Image
			for y in fh:
				for x in fw:
					if prev.get_pixel(x, y).a >= 0.5:
						continue
					var sum := Color(0, 0, 0, 0)
					var n := 0
					for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						var nx := x + d.x
						var ny := y + d.y
						if nx >= 0 and ny >= 0 and nx < fw and ny < fh:
							var c := prev.get_pixel(nx, ny)
							if c.a >= 0.5:
								sum += c
								n += 1
					if n > 0:
						src.set_pixel(x, y, Color(sum.r / n, sum.g / n, sum.b / n, 0.0))
		src.resize(fw * k, fh * k, Image.INTERPOLATE_BILINEAR)
		out.blit_rect(src, Rect2i(0, 0, fw * k, fh * k), Vector2i(col * fw * k, 0))
	return out


## Donne du volume : lumière sur les bords tournés vers le haut gauche, ombre sur les
## bords tournés vers le bas droit.
static func _volume(img: Image, region: Rect2i) -> void:
	var src := img.get_region(region)
	var w := region.size.x
	var h := region.size.y
	var e := maxi(1, K / 2) if K > 1 else 1
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var up := y < e or src.get_pixel(x, y - e).a < 0.5
			var left := x < e or src.get_pixel(x - e, y).a < 0.5
			var down := y >= h - e or src.get_pixel(x, y + e).a < 0.5
			var right := x >= w - e or src.get_pixel(x + e, y).a < 0.5
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
	if K > 1 and attack:
		_mood_hd(img, ox, face)
		return
	for e: Array in face["eyes"]:
		var x := ox + int(e[0])
		var y := int(e[1])
		var w := int(e[2])
		var h := int(e[3])
		if K > 1 and not attack:
			# coup reçu, en définition fine : l'œil se ferme en un arc plissé, sous un petit froncement
			_ellipse(img, x + w * 0.5, y + h * 0.5, w * 0.5 + 0.2, h * 0.5 + 0.2, _cellpx(img, x + w / 2, y - 1))
			_curve(img, Vector2(x - 0.1, y + h * 0.35), Vector2(x + w * 0.5, y + h * 1.25), Vector2(x + w + 0.1, y + h * 0.35), dark, 0.42)
			continue
		if attack:
			_rect(img, x, y, w, h, Color.WHITE)
			_rect(img, x, y, w, 1, dark)                 # paupière basse, regard noir
			_px(img, x + w - 1, y + h - 1, dark)
			_px(img, x + w - 1, y + 1, dark)
		else:
			# œil plissé : un trait fermé, relevé aux coins, par-dessus l'œil d'origine
			_rect(img, x, y + h / 2, w, 1, dark)
			if h >= 3:
				_px(img, x, y, dark)
				_px(img, x, y + h - 1, dark)
	var m: Array = face["mouth"]
	var mx := ox + int(m[0])
	var my := int(m[1])
	var mw := int(m[2])
	var mh := int(m[3])
	if attack:
		_rect(img, mx, my, mw, mh, maw)
		for i in range(0, mw, 2):
			_px(img, mx + i, my, Color.WHITE)
		if mh >= 3:
			_px(img, mx + mw / 2, my + mh - 1, _c("#d8506a"))
	elif K > 1:
		# bouche tordue : une vague serrée
		_curve(img, Vector2(mx, my + mh * 0.5), Vector2(mx + mw * 0.3, my - mh * 0.2), Vector2(mx + mw * 0.5, my + mh * 0.5), dark, 0.4)
		_curve(img, Vector2(mx + mw * 0.5, my + mh * 0.5), Vector2(mx + mw * 0.75, my + mh * 1.2), Vector2(mx + mw, my + mh * 0.4), dark, 0.4)
	else:
		for i in mw:
			_px(img, mx + i, my + 1 - (i % 2), dark)


## Visage d'attaque à la définition HD : yeux injectés cernés d'un sourcil furieux, gueule
## ouverte (palais, dents du haut et du bas, langue).
static func _mood_hd(img: Image, ox: int, face: Dictionary) -> void:
	var dark := _c("#2b1b2e")
	var eyes: Array = face["eyes"]
	for i in eyes.size():
		var e: Array = eyes[i]
		var x := ox + int(e[0])
		var y := int(e[1])
		var w := int(e[2])
		var h := int(e[3])
		_eye(img, x, y, w, h, _c("#b82a2e"))
		var left := (i == 0 and eyes.size() > 1) or eyes.size() == 1
		var inner_x := x + w + 0.4 if left else x - 0.4
		var outer_x := x - 0.4 if left else x + w + 0.4
		_tri(img, Vector2(outer_x, y - 0.5), Vector2(inner_x, y - 0.5), Vector2(inner_x, y + h * 0.55), dark)
	var m: Array = face["mouth"]
	var mx := ox + int(m[0])
	var my := int(m[1])
	var mw := int(m[2])
	var mh := int(m[3])
	var cx := mx + mw * 0.5
	var cy := my + mh * 0.5
	_ellipse(img, cx, cy, mw * 0.5 + 0.3, mh * 0.5 + 0.35, dark)
	_ellipse(img, cx, cy, mw * 0.5, mh * 0.5, _c("#5a1426"))
	_ellipse(img, cx, cy + mh * 0.25, mw * 0.3, mh * 0.24, _c("#d8506a"))
	var n := maxi(2, mw / 2)
	for i in n:
		var tx := mx + (i + 0.5) * mw / float(n)
		_tri(img, Vector2(tx - 0.55, my + 0.1), Vector2(tx + 0.55, my + 0.1), Vector2(tx, my + 0.1 + mh * 0.42), Color.WHITE)
		if i % 2 == 1 and mh >= 3:
			_tri(img, Vector2(tx - 0.45, my + mh - 0.1), Vector2(tx + 0.45, my + mh - 0.1), Vector2(tx, my + mh - mh * 0.34), Color("#f0e8d8"))


static func _c(hex: String) -> Color:
	return Color.from_string(hex, Color.MAGENTA)


# ------------------------------------------------------------------ outils de volume
# Même méthode que character_painter.gd : chaque forme est un volume éclairé par le haut
# gauche, peint avec une rampe de cinq tons (ombres violacées, lumières chaudes), puis un
# contour de la couleur de la forme voisine, assombrie.

static func _ramp(hex: String) -> Array:
	var c := _c(hex)
	return [PA.shade(c, -0.5), PA.shade(c, -0.26), c, PA.shade(c, 0.17), PA.shade(c, 0.36)]


## Une rampe en retrait : pièce à l'arrière-plan (pattes de derrière).
static func _dim(ramp: Array) -> Array:
	return [ramp[0], ramp[0], ramp[1], ramp[2], ramp[3]]


static func _tone(nx: float, ny: float, bias: float = 0.0) -> int:
	var nz := sqrt(maxf(0.0, 1.0 - nx * nx - ny * ny))
	var l := -0.5 * nx - ny * 0.5 + nz * 0.7 + bias
	if l < -0.25:
		return 0
	if l < 0.28:
		return 1
	if l < 0.78:
		return 2
	if l < 0.94:
		return 3
	return 4


# ---- grille à deux définitions : tout est dessiné en coordonnées « logiques » (celles de la
# petite planche) et les primitives les multiplient par K (1 pour `paint`, HD pour `paint_hd`).

static func _hash(x: int, y: int) -> float:
	var h: int = (x * 374761393 + y * 668265263 + _gseed * 2246822519) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float((h ^ (h >> 16)) & 0xffff) / 65535.0


## Grain de matière (bruit de valeurs à deux échelles) : déplace les frontières entre tons,
## ce qui donne une peau granuleuse, une croûte, un poil, plutôt que des bandes lisses.
static func _grain(x: int, y: int) -> float:
	if _ga <= 0.0:
		return 0.0
	var fx := float(x) / _gs
	var fy := float(y) / _gs
	var ix := int(floor(fx))
	var iy := int(floor(fy))
	var tx := fx - ix
	var ty := fy - iy
	tx = tx * tx * (3.0 - 2.0 * tx)
	ty = ty * ty * (3.0 - 2.0 * ty)
	var v := lerpf(lerpf(_hash(ix, iy), _hash(ix + 1, iy), tx), lerpf(_hash(ix, iy + 1), _hash(ix + 1, iy + 1), tx), ty)
	return (v - 0.5) * 2.0 * _ga + (_hash(x, y) - 0.5) * _ga * 0.5


static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if K == 1:
		PA.px(img, x, y, c)
	else:
		_rect(img, x, y, 1, 1, c)


## Rectangle en pixels logiques. En HD, les petits détails (dents, éclats, reflets : moins de trois
## pixels logiques de large ou de haut) ont les coins arrondis ; les grands aplats restent carrés.
static func _rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	if w <= 0 or h <= 0:
		return
	var gx := x * K
	var gy := y * K
	var gw := w * K
	var gh := h * K
	if K == 1 or (w > 3 and h > 3):
		PA.rect(img, gx, gy, gw, gh, c)
		return
	var r := minf(K * 0.45, minf(gw, gh) * 0.5)
	var ri := int(round(r))
	PA.rect(img, gx + ri, gy, gw - 2 * ri, gh, c)
	PA.rect(img, gx, gy + ri, gw, gh - 2 * ri, c)
	for dy in ri:
		for dx in ri:
			var ex := ri - dx - 0.5
			var ey := ri - dy - 0.5
			if ex * ex + ey * ey <= r * r:
				PA.px(img, gx + dx, gy + dy, c)
				PA.px(img, gx + gw - 1 - dx, gy + dy, c)
				PA.px(img, gx + dx, gy + gh - 1 - dy, c)
				PA.px(img, gx + gw - 1 - dx, gy + gh - 1 - dy, c)


static func _ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	PA.ellipse(img, cx * K, cy * K, rx * K, ry * K, c)


static func _line(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	if K == 1:
		PA.line(img, x0, y0, x1, y1, c)
		return
	var a := Vector2(x0 + 0.5, y0 + 0.5) * K
	var d := Vector2(x1 - x0, y1 - y0) * K
	var l2 := maxf(d.length_squared(), 0.0001)
	var r := 0.5 * K
	for y in range(int(minf(a.y, a.y + d.y) - r), int(maxf(a.y, a.y + d.y) + r) + 1):
		for x in range(int(minf(a.x, a.x + d.x) - r), int(maxf(a.x, a.x + d.x) + r) + 1):
			var p := Vector2(x + 0.5, y + 0.5)
			var t := clampf((p - a).dot(d) / l2, 0.0, 1.0)
			if (p - (a + d * t)).length() <= r:
				PA.px(img, x, y, c)


## Courbe douce (quadratique a -> b, point de contrôle c) tracée au point rond : bouches, plis, coutures,
## sourcils. Trait de `r` pixels logiques de rayon ; en petite définition, un pixel par point.
static func _curve(img: Image, a: Vector2, c: Vector2, b: Vector2, col: Color, r: float = 0.55) -> void:
	var n := int((a.distance_to(c) + c.distance_to(b)) * 2.0) + 2
	for i in n + 1:
		var t := float(i) / float(n)
		var p := a * (1.0 - t) * (1.0 - t) + c * 2.0 * t * (1.0 - t) + b * t * t
		if K == 1:
			PA.px(img, int(floor(p.x)), int(floor(p.y)), col)
		else:
			PA.ellipse(img, p.x * K, p.y * K, r * K, r * K, col)


## Œil rancunier des brutes (gobelins, orques, troll) : amande jaune, pupille fendue, sourcil lourd
## penché vers le nez (les brutes regardent à droite). Fermé (coup reçu) : un arc plissé.
static func _grudge_eye(img: Image, cx: float, cy: float, rx: float, ry: float, closed: bool = false) -> void:
	var dark := _c("#1c1418")
	if closed:
		_curve(img, Vector2(cx - rx, cy - 0.2), Vector2(cx, cy + ry * 1.5), Vector2(cx + rx, cy - 0.2), dark, 0.5)
		return
	_ellipse(img, cx, cy, rx + 0.35, ry + 0.35, dark)
	_ellipse(img, cx, cy, rx, ry, Color("#f0dc50"))
	_ellipse(img, cx + rx * 0.35, cy + 0.1, maxf(0.45, rx * 0.3), ry * 0.9, dark)
	_ellipse(img, cx - rx * 0.4, cy - ry * 0.35, 0.4, 0.4, Color("#fffbe0"))
	_curve(img, Vector2(cx - rx - 0.8, cy - ry - 1.0), Vector2(cx, cy - ry - 0.9), Vector2(cx + rx + 0.7, cy - ry + 0.7), dark, 0.55)


## Bouche des brutes : fermée, une moue basse flanquée de deux défenses ; ouverte (attaque), une gueule
## sombre au palais de sang, crocs en haut et en bas.
static func _brute_mouth(img: Image, mx: float, my: float, w: float, open: bool) -> void:
	var dark := _c("#1c1418")
	if open:
		_ellipse(img, mx + w * 0.5, my + 1.8, w * 0.5 + 0.4, 2.5, dark)
		_ellipse(img, mx + w * 0.5, my + 1.9, w * 0.5 - 0.1, 2.0, Color("#4a1424"))
		_ellipse(img, mx + w * 0.5, my + 2.7, w * 0.28, 0.8, Color("#c8506a"))
		for t: float in [0.28, 0.72]:
			_tri(img, Vector2(mx + w * t - 0.7, my - 0.1), Vector2(mx + w * t + 0.7, my - 0.1), Vector2(mx + w * t, my + 1.8), Color.WHITE)
		return
	_curve(img, Vector2(mx, my + 0.9), Vector2(mx + w * 0.5, my - 0.9), Vector2(mx + w, my + 0.7), dark, 0.5)
	for t: float in [0.12, 0.88]:
		_tri(img, Vector2(mx + w * t - 0.7, my + 0.6), Vector2(mx + w * t + 0.7, my + 0.6), Vector2(mx + w * t, my - 1.2), Color("#f4ecd8"))


## Opacité de la case logique (x, y) : lit le centre du bloc.
static func _cellpx(img: Image, x: int, y: int) -> Color:
	var gx := clampi(x * K + K / 2, 0, img.get_width() - 1)
	var gy := clampi(y * K + K / 2, 0, img.get_height() - 1)
	return img.get_pixel(gx, gy)


## Ellipsoïde éclairé. ymax / ymin coupent la forme.
static func _ell(img: Image, cx: float, cy: float, rx: float, ry: float, ramp: Array, bias: float = 0.0,
		ymax: float = 1000.0, ymin: float = -1000.0) -> void:
	cx *= K
	cy *= K
	rx *= K
	ry *= K
	ymax *= K
	ymin *= K
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		if y + 0.5 > ymax or y + 0.5 < ymin:
			continue
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var nx := (x + 0.5 - cx) / rx
			var ny := (y + 0.5 - cy) / ry
			if nx * nx + ny * ny > 1.0:
				continue
			PA.px(img, x, y, ramp[_tone(nx, ny, bias + _grain(x, y))])


## Ellipsoïde rayé (guêpes) : même éclairage que `_ell`, mais bandes courbes de la rampe `b`
## (largeur `pw`, période `period`, en pixels logiques depuis `x0`), calculées pixel HD par pixel HD.
static func _ell_stripes(img: Image, cx: float, cy: float, rx: float, ry: float, a: Array, b: Array,
		x0: float, period: float, pw: float) -> void:
	var gcx := cx * K
	var gcy := cy * K
	var grx := rx * K
	var gry := ry * K
	for y in range(int(floor(gcy - gry)), int(ceil(gcy + gry)) + 1):
		for x in range(int(floor(gcx - grx)), int(ceil(gcx + grx)) + 1):
			var nx := (x + 0.5 - gcx) / grx
			var ny := (y + 0.5 - gcy) / gry
			if nx * nx + ny * ny > 1.0:
				continue
			var xs := (x + 0.5) / K - x0 + ny * ny * 1.2
			var ramp: Array = b if fposmod(xs, period) < pw else a
			PA.px(img, x, y, ramp[_tone(nx, ny, _grain(x, y))])


## Capsule éclairée d'un point à un autre (pattes, tiges, antennes).
static func _cap(img: Image, x0: float, y0: float, x1: float, y1: float, r0: float, r1: float, ramp: Array,
		bias: float = 0.0) -> void:
	x0 *= K
	y0 *= K
	x1 *= K
	y1 *= K
	r0 *= K
	r1 *= K
	var a := Vector2(x0, y0)
	var d := Vector2(x1 - x0, y1 - y0)
	var l2 := maxf(d.length_squared(), 0.0001)
	var rm := maxf(r0, r1)
	for y in range(int(floor(minf(y0, y1) - rm)), int(ceil(maxf(y0, y1) + rm)) + 1):
		for x in range(int(floor(minf(x0, x1) - rm)), int(ceil(maxf(x0, x1) + rm)) + 1):
			var pnt := Vector2(x + 0.5, y + 0.5)
			var t := clampf((pnt - a).dot(d) / l2, 0.0, 1.0)
			var r := lerpf(r0, r1, t)
			var off := pnt - (a + d * t)
			if off.length() > r:
				continue
			PA.px(img, x, y, ramp[_tone(off.x / r, off.y / r, bias + _grain(x, y))])


## Trapèze lisse comme un tube : étoffes, corps.
static func _trap(img: Image, y0: int, y1: int, xl0: float, xr0: float, xl1: float, xr1: float, ramp: Array,
		bias: float = 0.0) -> void:
	var h := float(y1 - y0)
	if h <= 0.0:
		return
	var ya := y0 * K
	var yb := y1 * K
	var hh := float(yb - ya)
	for y in range(ya, yb):
		var t := (y + 0.5 - ya) / hh
		var xl := lerpf(xl0, xl1, t) * K
		var xr := lerpf(xr0, xr1, t) * K
		var w := xr - xl
		if w <= 0.01:
			continue
		for x in range(int(round(xl)), maxi(int(round(xr)), int(round(xl)) + 1)):
			var u := clampf(((x + 0.5 - xl) / w) * 2.0 - 1.0, -0.99, 0.99)
			PA.px(img, x, y, ramp[_tone(u, (t * 2.0 - 1.0) * 0.35, bias + _grain(x, y))])


## Œil : blanc, regard sombre en bas à droite, un éclat en haut à gauche. En HD : globe
## cerclé de sombre, iris, pupille et reflet.
static func _eye(img: Image, x: int, y: int, w: int, h: int, iris: Color = Color("#2b1b2e")) -> void:
	if K == 1:
		PA.rect(img, x, y, w, h, Color.WHITE)
		PA.px(img, x + w - 1, y + h - 1, iris)
		if h >= 3:
			PA.px(img, x + w - 1, y + h - 2, iris)
		if w >= 3:
			PA.px(img, x + w - 2, y + h - 1, iris)
		return
	var cx := (x + w * 0.5) * K
	var cy := (y + h * 0.5) * K
	var rx := w * 0.5 * K
	var ry := h * 0.5 * K
	var rim := iris.darkened(0.7)
	PA.ellipse(img, cx, cy, rx + 1.0, ry + 1.0, rim)
	PA.ellipse(img, cx, cy, rx, ry, Color("#f6f1ec"))
	PA.ellipse(img, cx + rx * 0.05, cy - ry * 0.55, rx * 0.95, ry * 0.45, Color("#e0d8dc"))   # ombre de la paupière
	var ir := minf(rx, ry) * 0.92
	PA.ellipse(img, cx + rx * 0.2, cy + ry * 0.12, ir, ir, iris.darkened(0.25))
	PA.ellipse(img, cx + rx * 0.2, cy + ry * 0.2, ir * 0.78, ir * 0.78, iris)
	PA.ellipse(img, cx + rx * 0.25, cy + ry * 0.2, ir * 0.42, ir * 0.42, Color("#1c1222"))
	PA.ellipse(img, cx - rx * 0.12, cy - ry * 0.3, maxf(1.0, ir * 0.25), maxf(1.0, ir * 0.25), Color.WHITE)


## Contour de la couleur de la pièce voisine, assombrie et un peu violette ; plus épais en HD.
static func _outline(img: Image, region: Rect2i) -> void:
	var w := region.size.x
	var h := region.size.y
	var rings := 1 if K == 1 else maxi(1, K / 2)
	for ring in rings:
		var src := img.get_region(region)
		for y in h:
			for x in w:
				if src.get_pixel(x, y).a >= 0.5:
					continue
				var sum := Color(0, 0, 0, 0)
				var n := 0
				for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var nx := x + d.x
					var ny := y + d.y
					if nx < 0 or ny < 0 or nx >= w or ny >= h:
						continue
					var nc := src.get_pixel(nx, ny)
					if nc.a >= 0.5:
						sum += nc
						n += 1
				if n == 0:
					continue
				var out := sum / float(n)
				if ring == 0:
					out = out.darkened(0.7).lerp(PA.OUTLINE, 0.4)
				out.a = 1.0
				img.set_pixel(region.position.x + x, region.position.y + y, out)


## Passe finale en HD : lumière de bord en haut à gauche, ombre de contact en bas à droite,
## et petits reflets mouillés sur les tons les plus clairs des espèces luisantes.
static func _finish_hd(img: Image, region: Rect2i, kind: String, _col: int) -> void:
	var src := img.get_region(region)
	var w := region.size.x
	var h := region.size.y
	var a := maxi(2, K / 2)
	var b := K
	var shiny: bool = SHINY.has(kind)
	for y in h:
		for x in w:
			var c := src.get_pixel(x, y)
			if c.a < 0.5:
				continue
			var lum := c.get_luminance()
			if lum < 0.1 or lum > 0.9:
				continue
			var k := 0.0
			if _clear(src, x - a, y) or _clear(src, x, y - a):
				k += 0.17
			elif _clear(src, x - b, y) or _clear(src, x, y - b):
				k += 0.08
			if _clear(src, x + a, y) or _clear(src, x, y + a):
				k -= 0.2
			elif _clear(src, x + b, y) or _clear(src, x, y + b):
				k -= 0.1
			if shiny and k == 0.0 and lum > 0.55 and _hash(x / 3, y / 3) > 0.93:
				k = 0.22
			if absf(k) > 0.01:
				img.set_pixel(region.position.x + x, region.position.y + y, PA.shade(c, clampf(k, -0.3, 0.26)))


## Marques de matière semées sur la silhouette en HD : [type, densité pour 10 000 pixels, taille]
## (verrues, pores, poils, points de grain, fissures, braises). Couleurs prises sur le pixel
## voisin : elles suivent la palette de l'espèce.
const MARKS := {
	"crapaud": [["wart", 16, 2.6], ["fleck", 30, 1.0], ["wart", 6, 1.6]],
	"grenouille": [["wart", 7, 2.2], ["fleck", 18, 1.0]],
	"limace": [["wart", 4, 1.6], ["fleck", 10, 1.0]],
	"baveuse": [["wart", 4, 1.6], ["fleck", 10, 1.0]],
	"sangsue": [["wart", 4, 1.6], ["fleck", 10, 1.0]],
	"asticot": [["wart", 3, 1.4], ["fleck", 8, 1.0]],
	"vacherin": [["pore", 9, 3.2], ["pore", 7, 2.0], ["fleck", 14, 1.0]],
	"paton": [["pore", 6, 3.0], ["fleck", 14, 1.0]],
	"champignon": [["fleck", 12, 1.0]],
	"amanite": [["fleck", 14, 1.0]],
	"moisi": [["wart", 8, 1.8], ["fleck", 14, 1.0]],
	"sanglier": [["hair", 70, 8.0], ["fleck", 10, 1.0]],
	"solitaire": [["hair", 70, 8.0], ["fleck", 10, 1.0]],
	"ouargue": [["hair", 80, 8.0]],
	"rat": [["hair", 90, 6.0]],
	"chamois": [["hair", 70, 7.0]],
	"hirsute": [["hair", 60, 7.0], ["fleck", 10, 1.0]],
	"chauve": [["hair", 40, 5.0]],
	"coq": [["hair", 40, 6.0]],
	"corbeau": [["hair", 50, 6.0]],
	"epouvantail": [["hair", 50, 7.0], ["fleck", 10, 1.0]],
	"troll": [["wart", 8, 3.2], ["wart", 6, 1.8], ["crack", 3, 5.0], ["fleck", 14, 1.0]],
	"balourd": [["crack", 8, 7.0], ["ember", 16, 1.0], ["fleck", 8, 1.0]],
	"goulum": [["wart", 8, 1.6], ["fleck", 12, 1.0]],
	"guetteur": [["wart", 6, 2.0], ["fleck", 12, 1.0]],
	"gobelin": [["wart", 7, 1.8], ["crack", 2, 4.0], ["fleck", 10, 1.0]],
	"gobelin_pic": [["wart", 7, 1.8], ["crack", 2, 4.0], ["fleck", 10, 1.0]],
	"gobelin_chef": [["wart", 8, 2.2], ["crack", 2, 4.0], ["fleck", 10, 1.0]],
	"ouroukouille": [["wart", 6, 2.0], ["crack", 3, 4.0], ["fleck", 12, 1.0]],
	"ouroukouille_brocheur": [["wart", 6, 2.0], ["crack", 3, 4.0], ["fleck", 12, 1.0]],
	"ouroukouille_petrisseur": [["wart", 6, 2.0], ["crack", 3, 4.0], ["fleck", 12, 1.0]],
	"ouroukouille_chef": [["wart", 7, 2.2], ["crack", 3, 4.0], ["fleck", 12, 1.0]],
	# chapitre 6
	"eveille": [["fleck", 8, 1.0]], "eveille_veilleur": [["fleck", 8, 1.0]], "roi_eveille": [["fleck", 8, 1.0]],
	"boucanier": [["crack", 2, 3.0], ["fleck", 10, 1.0]], "saumure": [["crack", 2, 3.0], ["fleck", 10, 1.0]],
	"cassouletain": [["fleck", 10, 1.0]], "gothmoque": [["crack", 4, 5.0], ["wart", 3, 1.8], ["fleck", 12, 1.0]],
	"naze_supreme": [["fleck", 6, 1.0]], "mammou": [["hair", 40, 5.0], ["fleck", 10, 1.0]],
	"dindon_farce": [["hair", 40, 5.0], ["fleck", 8, 1.0]], "grondine": [["crack", 5, 6.0], ["fleck", 12, 1.0]],
	"boss_sarumale": [["fleck", 5, 1.0]], "boss_froton": [["fleck", 6, 1.0]], "boss_grimace": [["fleck", 6, 1.0]],
	"boss_gardien": [["fleck", 6, 1.0]], "boss_sauron": [["crack", 2, 4.0], ["fleck", 6, 1.0]],
	"boss_uglouk": [["wart", 5, 1.8], ["fleck", 8, 1.0]],
}


static func _marks(img: Image, region: Rect2i, kind: String) -> void:
	var spec: Array = MARKS.get(kind, [])
	if spec.is_empty():
		return
	var src := img.get_region(region)
	var w := region.size.x
	var h := region.size.y
	var area := 0
	for y in range(0, h, 2):
		for x in range(0, w, 2):
			if src.get_pixel(x, y).a >= 0.5:
				area += 4
	var sc := K / 4.0
	for idx in spec.size():
		var m: Array = spec[idx]
		var type := str(m[0])
		var n := int(area * float(m[1]) / 10000.0)
		var r := float(m[2]) * sc
		for i in n:
			var px := int(_hash(i * 7 + 1, idx * 13 + 5) * w)
			var py := int(_hash(i * 11 + 3, idx * 17 + 9) * h)
			var c := src.get_pixel(px, py)
			if c.a < 0.5:
				continue
			var lum := c.get_luminance()
			if lum < 0.1 or (lum > 0.97 and type != "ember"):
				continue
			var ri := int(ceil(r)) + 2
			if _clear(src, px - ri, py) or _clear(src, px + ri, py) or _clear(src, px, py - ri) or _clear(src, px, py + ri):
				continue
			var ox := region.position.x
			match type:
				"wart":
					for dy in range(-ri, ri + 1):
						for dx in range(-ri, ri + 1):
							var d2 := float(dx * dx + dy * dy)
							if d2 > r * r:
								continue
							var k := -0.06
							if dx + dy < -r * 0.5:
								k = 0.2
							elif d2 > (r - 1.0) * (r - 1.0) and dx + dy > 0:
								k = -0.28
							PA.px(img, ox + px + dx, py + dy, PA.shade(c, k))
				"pore":
					for dy in range(-ri, ri + 1):
						for dx in range(-ri * 2, ri * 2 + 1):
							var ex := dx / 1.3
							var ey := dy / 0.8
							if ex * ex + ey * ey > r * r:
								continue
							var k := -0.4 if dy < r * 0.45 else 0.14
							PA.px(img, ox + px + dx, py + dy, PA.shade(c, k))
				"hair":
					var dir := Vector2(0.45 + (_hash(i, 77) - 0.5) * 0.5, 0.9).normalized()
					for t in int(r):
						var qx := px + int(dir.x * t)
						var qy := py + int(dir.y * t)
						if _clear(src, qx, qy):
							break
						PA.px(img, ox + qx, qy, PA.shade(c, 0.2 if (i % 2) == 0 else -0.22))
				"fleck":
					var lit := (i % 3) != 0
					PA.ellipse(img, ox + px + 0.5, py + 0.5, maxf(1.0, sc * 1.1), maxf(1.0, sc * 1.1), PA.shade(c, 0.22 if lit else -0.2))
				"crack":
					var qx := px
					var qy := py
					for t in int(r):
						if _clear(src, qx, qy):
							break
						PA.px(img, ox + qx, qy, PA.shade(c, -0.34))
						qx += int(round((_hash(i, t + 20) - 0.35) * 2.2))
						qy += int(round((_hash(t + 40, i) - 0.2) * 2.4))
				"ember":
					PA.ellipse(img, ox + px + 0.5, py + 0.5, maxf(1.0, sc * 1.1), maxf(1.0, sc * 1.1), Color("#ffb040") if (i % 2) == 0 else Color("#f06a2a"))


static func _clear(src: Image, x: int, y: int) -> bool:
	return x < 0 or y < 0 or x >= src.get_width() or y >= src.get_height() or src.get_pixel(x, y).a < 0.5


## Limace : corps bas et luisant, pied clair, manteau sombre, deux yeux au bout de leurs tiges.
static func _slug(img: Image, ox: int, f: int, pal: Array, eye_hex: String) -> void:
	var back := _ramp(pal[0])
	var mid := _ramp(pal[1])
	var belly := _ramp(pal[2])
	var shine := _c(pal[3])
	var dark := _c("#2b1b2e")
	var sq := f   # la seconde pose s'étale un peu
	var by := 17.0 + sq * 0.5
	# traînée de bave derrière elle
	_rect(img, ox + 2, 23, 8, 1, belly[3])
	_px(img, ox + 1, 23, belly[2])
	_rect(img, ox + 5, 24, 3, 1, belly[3])
	# queue effilée, corps, tête dressée, pied clair
	_ell(img, ox + 8.0, by + 2.2, 6.5, 3.0, mid)
	_ell(img, ox + 17.0 - sq * 0.5, by, 11.5 + sq, 5.8 - sq * 0.6, mid)
	_ell(img, ox + 28.0 + sq, by - 2.5 + sq, 5.4, 6.0 - sq * 0.5, mid)
	_ell(img, ox + 17.5, by + 4.4, 13.5 + sq, 2.0, belly, 0.1)
	# manteau sombre sur le dos, taches
	_ell(img, ox + 14.0, by - 2.6, 7.5, 3.4, back, -0.05)
	# taches rondes de la coquille, tons du manteau, plus claires au bord
	for sp: Array in [[10.0, -2.6, 1.7, 1.2], [15.0, -3.6, 1.3, 1.0], [18.5, -1.4, 1.5, 1.1], [12.5, -0.1, 1.0, 0.8]]:
		_ell(img, ox + float(sp[0]), by + float(sp[1]), float(sp[2]), float(sp[3]), _dim(back), -0.1)
		_ellipse(img, ox + float(sp[0]) - 0.4, by + float(sp[1]) - 0.4, float(sp[2]) * 0.35, float(sp[3]) * 0.3, back[3])
	# éclats de bave luisante
	_rect(img, ox + 10, int(by) - 5, 3, 1, shine)
	_px(img, ox + 9, int(by) - 4, shine)
	_px(img, ox + 25 + sq, int(by) - 4 + sq, shine)
	# tiges et yeux
	var hy := int(by) - 8 + sq
	_cap(img, ox + 27.5 + sq, hy + 3.0, ox + 27.5 + sq, hy - 2.0, 0.9, 0.8, mid)
	_cap(img, ox + 32.0 + sq, hy + 3.0, ox + 32.5 + sq, hy - 1.0, 0.9, 0.8, mid)
	_eye(img, ox + 26 + sq, hy - 6, 3, 3, _c(eye_hex))
	_eye(img, ox + 31 + sq, hy - 5, 3, 3, _c(eye_hex))
	# bouche tombante
	_px(img, ox + 30 + sq, int(by) - 1 + sq, dark)
	_px(img, ox + 31 + sq, int(by) - 2 + sq, dark)
	_px(img, ox + 32 + sq, int(by) - 1 + sq, dark)


## Guêpe à cidre : ventre rayé, ailes qui battent, dard généreux.
static func _wasp(img: Image, ox: int, f: int, pal: Array) -> void:
	var yellow := _ramp(pal[0])
	var brown := _ramp(pal[2])
	var wing := _ramp(pal[3])
	var wing_d := _ramp(pal[4])
	var dy := f
	# ailes (derrière)
	if f == 0:
		_ell(img, ox + 15.0, 7.0 + dy, 6.5, 4.0, wing)
		_ell(img, ox + 9.0, 9.0 + dy, 4.5, 2.6, wing_d)
	else:
		_ell(img, ox + 15.0, 11.0 + dy, 7.5, 2.0, wing)
		_ell(img, ox + 9.0, 12.0 + dy, 5.0, 1.5, wing_d)
	# dard
	_cap(img, ox + 4.0, 20.0 + dy, ox + 0.8, 23.0 + dy, 1.2, 0.5, brown)
	# abdomen rayé (bandes courbes, dessinées à la définition fine)
	_ell_stripes(img, ox + 10.0, 18.0 + dy, 7.0, 5.0, yellow, brown, float(ox) + 0.0, 5.0, 2.0)
	# pattes
	_cap(img, ox + 17.0, 21.0 + dy, ox + 15.5, 25.0 + dy, 0.7, 0.5, brown)
	_cap(img, ox + 20.0, 21.0 + dy, ox + 21.5, 25.0 + dy, 0.7, 0.5, brown)
	# thorax velu et tête
	_ell(img, ox + 19.0, 16.0 + dy, 4.4, 4.4, brown, 0.05)
	_ell(img, ox + 24.5, 15.0 + dy, 4.3, 4.3, yellow)
	_ell(img, ox + 26.5, 14.5 + dy, 1.9, 2.0, brown, -0.2)
	_px(img, ox + 25, 13 + dy, Color.WHITE)
	_px(img, ox + 28, 17 + dy, brown[0])
	_px(img, ox + 28, 18 + dy, brown[0])
	# antennes
	_cap(img, ox + 25.0, 11.0 + dy, ox + 28.0, 7.5 + dy, 0.6, 0.6, brown)
	_cap(img, ox + 23.0, 11.0 + dy, ox + 24.0, 7.0 + dy, 0.6, 0.6, brown)


## Mouche de cave : noire, luisante, gros yeux rouges, ailes qui vibrent.
static func _fly(img: Image, ox: int, f: int) -> void:
	var body := _ramp("#34414f")
	var sheen := _ramp("#3f7a6c")
	var red := _ramp("#c8302c")
	var wing := _ramp("#d6e6f2")
	var wing_d := _ramp("#a8c0d6")
	var dy := f
	if f == 0:
		_ell(img, ox + 16.0, 7.0 + dy, 7.0, 3.8, wing)
		_ell(img, ox + 9.0, 9.5 + dy, 5.0, 2.4, wing_d)
	else:
		_ell(img, ox + 16.0, 11.0 + dy, 8.0, 2.0, wing)
		_ell(img, ox + 9.0, 12.5 + dy, 5.5, 1.5, wing_d)
	for x: int in [14, 18, 21]:
		_cap(img, ox + x, 20.0 + dy, ox + x + 1.5, 25.0 + dy, 0.7, 0.5, body)
	_ell(img, ox + 10.0, 18.0 + dy, 7.2, 5.0, body)
	_ell(img, ox + 8.0, 19.5 + dy, 3.0, 2.0, sheen, 0.1)
	_ell(img, ox + 19.0, 16.0 + dy, 4.6, 4.6, body, 0.05)
	_ell(img, ox + 24.5, 15.5 + dy, 4.2, 4.2, body)
	_ell(img, ox + 26.0, 14.5 + dy, 2.7, 2.9, red)
	_px(img, ox + 25, 13 + dy, Color.WHITE)
	_cap(img, ox + 27.0, 18.0 + dy, ox + 30.0, 20.0 + dy, 0.8, 0.5, body)
	_cap(img, ox + 25.0, 11.5 + dy, ox + 27.0, 8.5 + dy, 0.5, 0.5, body)


## Champignon dormeur : gros chapeau, paupières closes, petits pieds.
static func _mushroom(img: Image, ox: int, f: int, pal: Array) -> void:
	var cap := _ramp(pal[0])
	var spot := _ramp(pal[3])
	var stem := _ramp("#eadfc6")
	var dark := _c("#2b1b2e")
	var dy := f
	# pieds, pied du champignon
	_ell(img, ox + 12.0, 30.4, 3.2, 1.8, stem, -0.1)
	_ell(img, ox + 20.0, 30.4, 3.2, 1.8, stem, -0.1)
	_ell(img, ox + 16.0, 24.5 + dy * 0.5, 5.6, 6.6 - dy * 0.5, stem, 0.05)
	# chapeau : demi-ellipsoïde à bord plat, lamelles sombres dessous
	var cy := 15.0 + dy
	_ell(img, ox + 16.0, cy, 14.0, 11.0 - dy, cap, 0.0, cy + 2.5)
	for y in range((int(cy) + 1) * K, (int(cy) + 3) * K):
		for x in range(ox * K, (ox + 32) * K):
			if img.get_pixel(x, y).a >= 0.5:
				PA.px(img, x, y, cap[0] if y < (int(cy) + 2) * K else cap[1])
	_ell(img, ox + 9.5, cy - 4.0, 2.6, 2.2, spot)
	_ell(img, ox + 18.0, cy - 7.0, 3.0, 2.4, spot)
	_ell(img, ox + 24.0, cy - 2.5, 2.0, 1.6, spot)
	# paupières closes, joues, bouche ronde
	_rect(img, ox + 12, 22 + dy, 3, 1, dark)
	_rect(img, ox + 17, 22 + dy, 3, 1, dark)
	_px(img, ox + 11, 24 + dy, _c("#e4a2a6"))
	_px(img, ox + 20, 24 + dy, _c("#e4a2a6"))
	_px(img, ox + 15, 25 + dy, dark)
	_px(img, ox + 16, 25 + dy, dark)
	if f == 1:
		_px(img, ox + 16, 26, dark)


## Moisissure bleue : tas duveteux, givré de blanc, qui coule de partout.
static func _mold(img: Image, ox: int, f: int) -> void:
	var blue := _ramp("#4a6ec0")
	var frost := _ramp("#bcd8f0")
	var deep := _ramp("#2c3c82")
	var dark := _c("#2b1b2e")
	var dy := f
	for x: int in [9, 15, 21]:
		_ell(img, ox + x + 1.0, 30.0, 3.0, 1.8, deep)
	_ell(img, ox + 16.0, 23.0 + dy, 11.5, 8.0 - dy, blue)
	_ell(img, ox + 10.0, 17.5 + dy, 6.5, 6.0, blue, 0.05)
	_ell(img, ox + 22.0, 17.0 + dy, 6.5, 6.5, blue, 0.0)
	_ell(img, ox + 16.0, 12.0 + dy, 7.5, 5.5, blue, 0.1)
	# givre et duvet
	_ell(img, ox + 14.0, 10.0 + dy, 4.5, 2.6, frost)
	_ell(img, ox + 24.0, 14.0 + dy, 2.8, 2.0, frost)
	_ell(img, ox + 8.0, 21.0 + dy, 2.2, 1.6, frost)
	for i in 26:
		var fx := 4 + int(PA.rnd(i, 3, 11) * 24.0)
		var fy := 6 + int(PA.rnd(i, 7, 5) * 20.0) + dy
		if _cellpx(img, ox + fx, fy).a >= 0.5:
			_px(img, ox + fx, fy, frost[2] if (i % 3) != 0 else frost[3])
	# yeux en bille et bouche tombante
	_eye(img, ox + 11, 21 + dy, 3, 3, _c("#2a7a3a"))
	_eye(img, ox + 18, 21 + dy, 3, 3, _c("#2a7a3a"))
	_px(img, ox + 14, 26 + dy, dark)
	_px(img, ox + 15, 27 + dy, dark)
	_px(img, ox + 16, 27 + dy, dark)
	_px(img, ox + 17, 26 + dy, dark)


## Épouvantail avachi : traverse de travers, manches qui pendent, tête qui tombe.
static func _scarecrow(img: Image, ox: int, f: int) -> void:
	var wood := _ramp("#7a5230")
	var shirt := _ramp("#a8683c")
	var patch := _ramp("#5f8a52")
	var sack := _ramp("#d9c08a")
	var straw := _ramp("#f0d060")
	var hat := _ramp("#5a4630")
	var band := _ramp("#b0483c")
	var dark := _c("#2b1b2e")
	var sx := f   # la seconde pose penche d'un pixel de plus
	# piquet et pied
	_cap(img, ox + 20.0, 30.0, ox + 20.0, 53.5, 1.4, 1.4, wood)
	_ell(img, ox + 20.0, 53.0, 4.5, 1.3, wood, -0.1)
	# traverse de travers
	_cap(img, ox + 4.5 + sx, 22.5, ox + 35.5 + sx, 28.0, 1.3, 1.3, wood)
	# chemise en toile, rapiécée
	_trap(img, 21, 38, ox + 12.5 + sx, ox + 27.5 + sx, ox + 11.0 + sx, ox + 28.5 + sx, shirt)
	_ell(img, ox + 16.0 + sx, 31.0, 2.6, 2.4, patch)
	_px(img, ox + 13 + sx, 31, dark)
	_px(img, ox + 19 + sx, 31, dark)
	_px(img, ox + 19 + sx, 25, dark)
	_px(img, ox + 19 + sx, 28, dark)
	# paille qui dépasse sous la chemise
	for i in 8:
		_rect(img, ox + 12 + sx + i * 2, 38, 1, 2 + (i % 2), straw[2 + (i % 2)])
	# manches pendantes et mains de paille
	_cap(img, ox + 6.5 + sx, 23.5, ox + 6.0 + sx, 33.0, 2.6, 2.3, shirt)
	_cap(img, ox + 32.5 + sx, 27.5, ox + 33.0 + sx, 37.0, 2.6, 2.3, shirt)
	for i in 3:
		_rect(img, ox + 4 + sx + i * 2, 34, 1, 3, straw[2 + (i % 2)])
		_rect(img, ox + 31 + sx + i * 2, 38, 1, 3, straw[2 + (i % 2)])
	# tête en sac, qui tombe sur l'épaule
	var hx := ox + 21.0 + sx * 1.5
	var hy := 14.0 + sx
	_ell(img, hx, hy, 6.6, 6.8, sack)
	_trap(img, int(hy) + 5, int(hy) + 8, hx - 4.5, hx + 4.5, hx - 3.5, hx + 3.5, sack, -0.35)
	# yeux cousus en croix, bouche en zigzag
	for e: int in [-3, 2]:
		var ex := float(int(hx) + e)
		_curve(img, Vector2(ex, hy - 2.5), Vector2(ex + 0.9, hy - 1.6), Vector2(ex + 1.8, hy - 0.7), dark, 0.42)
		_curve(img, Vector2(ex + 1.8, hy - 2.5), Vector2(ex + 0.9, hy - 1.6), Vector2(ex, hy - 0.7), dark, 0.42)
	# bouche cousue : un sourire tordu retenu par de petits points de fil
	_curve(img, Vector2(hx - 3.6, hy + 2.0), Vector2(hx, hy + 4.4), Vector2(hx + 3.8, hy + 1.6), dark, 0.42)
	for i in 4:
		var u := (float(i) + 0.5) / 4.0
		var sx2 := lerpf(hx - 3.2, hx + 3.4, u)
		var sy2 := lerpf(hy + 2.4, hy + 3.0, 1.0 - absf(u - 0.5) * 2.0) + 0.3
		_curve(img, Vector2(sx2, sy2 - 1.1), Vector2(sx2, sy2), Vector2(sx2 + 0.2, sy2 + 1.0), sack[1], 0.3)
	# chapeau cabossé
	_trap(img, int(hy) - 12, int(hy) - 6, hx - 4.0, hx + 4.5, hx - 5.5, hx + 6.0, hat, 0.05)
	_ell(img, hx, hy - 5.5, 10.0, 2.4, hat, 0.1)
	_trap(img, int(hy) - 8, int(hy) - 6, hx - 5.0, hx + 5.5, hx - 5.5, hx + 6.0, band)


## Sanglier flapi : gros dos rond, hure basse, défenses, pattes courtes. Il traîne la patte.
static func _boar(img: Image, ox: int, f: int, pal: Array) -> void:
	var dark := _ramp(pal[0])
	var mid := _ramp(pal[1])
	var light := _ramp(pal[2])
	var deep := _ramp(pal[3])
	var dy := f   # la seconde pose s'affaisse d'un pixel
	# pattes (celles de derrière dans l'ombre)
	for x: int in [9, 15, 26, 31]:
		var r := _dim(deep) if x < 20 else deep
		_cap(img, ox + x + 1.5, 22.0 + dy, ox + x + 1.5, 29.5, 1.9, 1.6, r)
		_rect(img, ox + x, 30, 3, 1, _c("#1c1418"))
	# queue en tire-bouchon, détendue
	for p: Vector2i in [Vector2i(4, 14), Vector2i(3, 15), Vector2i(3, 16), Vector2i(4, 17), Vector2i(5, 17)]:
		_px(img, ox + p.x, p.y + dy, dark[1])
	# corps, garrot, hure
	_ell(img, ox + 19.0, 16.0 + dy, 14.5, 8.8, mid)
	_ell(img, ox + 25.0, 13.0 + dy, 8.0, 6.5, mid, 0.05)
	_ell(img, ox + 34.5, 18.0 + dy, 7.9, 6.9, dark, -0.2)
	_ell(img, ox + 35.0, 18.0 + dy, 7.0, 6.0, mid, 0.05)
	# ventre clair, dos sombre et soies hérissées
	_ell(img, ox + 18.0, 21.5 + dy, 11.0, 2.4, light, 0.0)
	_ell(img, ox + 17.0, 9.5 + dy, 10.0, 2.6, dark, -0.1)
	for i in 8:
		var bx := ox + 8 + i * 3
		var top := 6 + dy + (i % 2)
		_rect(img, bx, top, 1, 3, deep[1])
		_px(img, bx, top, deep[0])
	# oreille tombante
	_cap(img, ox + 31.5, 11.0 + dy, ox + 32.5, 15.0 + dy, 1.8, 1.0, dark)
	# groin, défenses, œil mi-clos
	_ell(img, ox + 41.0, 20.5 + dy, 3.4, 3.2, light, 0.1)
	_px(img, ox + 43, 20 + dy, deep[0])
	_px(img, ox + 43, 22 + dy, deep[0])
	var ivory := _ramp("#efe4c4")
	_cap(img, ox + 38.6, 22.4 + dy, ox + 40.4, 25.8 + dy, 0.85, 0.35, ivory)   # défense recourbée
	_cap(img, ox + 41.2, 22.8 + dy, ox + 42.0, 25.0 + dy, 0.6, 0.3, ivory)
	_ellipse(img, ox + 36.2, 16.2 + dy, 1.7, 1.2, Color("#f0ead8"))
	_ellipse(img, ox + 36.9, 16.4 + dy, 0.85, 0.85, _c("#2b1b2e"))
	_cap(img, ox + 34.2, 14.9 + dy, ox + 37.8, 15.8 + dy, 0.55, 0.55, deep)   # paupière lourde


## Grenouille bouffie : accroupie, gros yeux, gorge qui se gonfle à la seconde pose.
static func _frog(img: Image, ox: int, f: int, pal: Array, eye_hex: String) -> void:
	var dark := _ramp(pal[0])
	var mid := _ramp(pal[1])
	var light := _ramp(pal[2])
	var deep := _ramp(pal[3])
	# cuisse repliée et pied arrière
	_ell(img, ox + 9.0, 20.0, 7.0, 5.0, dark, 0.1)
	_cap(img, ox + 4.0, 25.5, ox + 13.0, 25.5, 1.3, 1.1, dark)
	# corps et tête
	_ell(img, ox + 16.0, 17.0, 11.0, 7.5, mid)
	_ell(img, ox + 25.0, 13.0, 8.0, 6.5, mid, 0.05)
	# dos sombre et verrues
	_ell(img, ox + 14.0, 11.5, 7.0, 2.2, dark, -0.05)
	for p: Vector2i in [Vector2i(10, 15), Vector2i(15, 13), Vector2i(19, 16), Vector2i(13, 19)]:
		_ell(img, ox + p.x + 0.5, p.y + 0.5, 1.4, 1.2, dark, 0.15)
	# ventre et gorge (gonflée en respirant)
	_ell(img, ox + 17.0, 22.5, 8.5, 2.6, light)
	_ell(img, ox + 27.0, 19.0 + f * 0.5, 4.5 + f * 1.5, 3.0 + f * 1.5, light, 0.05)
	# patte avant
	_cap(img, ox + 22.5, 21.0, ox + 22.5, 25.0, 1.6, 1.4, mid)
	_cap(img, ox + 20.5, 26.0, ox + 25.5, 26.0, 1.0, 1.0, dark)
	# yeux globuleux
	_ell(img, ox + 23.5, 7.5, 3.4, 3.4, mid)
	_ell(img, ox + 29.5, 8.5, 3.4, 3.4, mid)
	if K > 1:
		for e: Vector2i in [Vector2i(22, 6), Vector2i(28, 7)]:
			_ellipse(img, ox + e.x + 1.5, e.y + 1.5, 1.7, 1.7, deep[0])
			_ellipse(img, ox + e.x + 1.5, e.y + 1.5, 1.4, 1.4, _c(eye_hex))
			_ellipse(img, ox + e.x + 1.9, e.y + 1.6, 0.34, 0.95, Color("#1c1222"))   # pupille fendue
			_ellipse(img, ox + e.x + 0.9, e.y + 0.8, 0.3, 0.3, Color.WHITE)
	else:
		_rect(img, ox + 22, 6, 3, 3, _c(eye_hex))
		_rect(img, ox + 28, 7, 3, 3, _c(eye_hex))
		_px(img, ox + 24, 7, deep[0])
		_px(img, ox + 24, 8, deep[0])
		_px(img, ox + 30, 8, deep[0])
		_px(img, ox + 30, 9, deep[0])
		_px(img, ox + 22, 6, Color.WHITE)
		_px(img, ox + 28, 7, Color.WHITE)
	# bouche large et lasse
	_curve(img, Vector2(ox + 22.0, 15.2), Vector2(ox + 27.0, 17.4), Vector2(ox + 32.5, 14.2), deep[0], 0.5)
	_curve(img, Vector2(ox + 22.0, 15.2), Vector2(ox + 21.6, 15.8), Vector2(ox + 21.2, 16.6), deep[0], 0.5)


## Feu follet : flamme pâle qui flotte, deux yeux fatigués. Il éclaire à peine.
static func _wisp(img: Image, ox: int, f: int) -> void:
	var outer := _ramp("#3fa8a0")
	var mid := _ramp("#7fe0c8")
	var core := _ramp("#e8fff0")
	var dark := _c("#1c4a50")
	var sway := f
	# pointe de la flamme, qui danse
	_ell(img, ox + 12.0 + sway, 7.0, 2.5, 4.5, outer, 0.1)
	_ell(img, ox + 12.0 + sway * 0.5, 9.0, 4.0, 5.0, outer, 0.1)
	_px(img, ox + 12 + sway * 2, 2, mid[2])
	# corps
	_ell(img, ox + 12.0, 18.0, 8.5, 9.0, outer, 0.1)
	_ell(img, ox + 12.0, 19.0, 6.0, 7.0, mid, 0.15)
	_ell(img, ox + 12.0, 21.0, 3.5, 4.0, core, 0.2)
	_ell(img, ox + 12.0 + sway * 0.5, 11.0, 2.0, 3.0, mid, 0.1)
	# étincelles qui retombent
	_px(img, ox + 3, 27 + sway, mid[2])
	_px(img, ox + 20, 29 - sway, mid[2])
	# yeux mi-clos, bouche tombante
	_rect(img, ox + 8, 17, 3, 1, dark)
	_rect(img, ox + 14, 17, 3, 1, dark)
	_px(img, ox + 9, 18, dark)
	_px(img, ox + 15, 18, dark)
	_px(img, ox + 11, 22, dark)
	_px(img, ox + 12, 21, dark)
	_px(img, ox + 13, 22, dark)


## Ver de fromage : gras, segmenté, mandibules en avant. Il se tortille en tas.
static func _maggot(img: Image, ox: int, f: int) -> void:
	var body := _ramp("#e6d9a4")
	var head := _ramp("#d2a85a")
	var rind := _ramp("#e8a63c")
	var dark := _c("#3a2418")
	var lift := f   # la seconde pose se redresse d'un pixel
	for i in 7:
		var t := float(i) / 6.0
		var cx := ox + 5.0 + t * 22.0
		var cy := 20.5 - 8.5 * pow(t, 1.5) - lift * t
		var r := 3.2 + 2.2 * t
		_ell(img, cx, cy, r * 0.95, r, body, 0.05)
		_px(img, int(cx), int(cy + r * 0.45), dark)
	# miettes de croûte collées sur le dos
	for p: Vector2i in [Vector2i(10, 15), Vector2i(17, 14), Vector2i(23, 10)]:
		_rect(img, ox + p.x, p.y, 2, 1, rind[3])
		_px(img, ox + p.x, p.y + 1, rind[1])
	_ell(img, ox + 31.0, 12.0 - lift, 5.0, 4.8, head)
	_eye(img, ox + 30, 10 - lift, 3, 3, _c("#3a2418"))
	_px(img, ox + 36, 13 - lift, dark)
	_px(img, ox + 36, 14 - lift, dark)
	_px(img, ox + 35, 15 - lift, dark)
	_px(img, ox + 33, 15 - lift, dark)


## Le Vacherin : meule de fromage coulant, ceinturée d'épicéa, qui déborde de partout.
static func _cheese(img: Image, ox: int, f: int) -> void:
	var rind := _ramp("#e6bc58")
	var cream := _ramp("#fff0b4")
	var band := _ramp("#7a4a22")
	var dark := _c("#2b1b2e")
	var sag := f   # la seconde pose s'affaisse
	# flanc, tranche de la meule
	_ell(img, ox + 19.0, 16.0 + sag, 15.0, 8.0 - sag * 0.5, rind, 0.12, 99.0, 8.0)
	# ceinture d'épicéa
	for y in range((19 + sag) * K, (21 + sag) * K):
		for x in range(ox * K, (ox + 38) * K):
			if img.get_pixel(x, y).a >= 0.5:
				var u := clampf((float(x) / K - ox - 19.0) / 15.0, -0.99, 0.99)
				PA.px(img, x, y, band[_tone(u, 0.2 + _grain(x, y))])
	# dessus coulant
	_ell(img, ox + 19.0, 6.8 + sag, 15.0, 4.6, cream, 0.1)
	_ell(img, ox + 14.0, 5.2 + sag, 5.0, 1.4, cream, 0.5)
	# coulures qui descendent le long du flanc
	_cap(img, ox + 6.5, 9.0 + sag, ox + 6.5, 15.0, 1.6, 1.4, cream, 0.1)
	_cap(img, ox + 30.0, 9.0 + sag, ox + 30.0, 14.0, 1.7, 1.5, cream, 0.1)
	_cap(img, ox + 19.0, 9.0 + sag, ox + 19.5, 11.0 + sag * 0.5, 1.2, 1.1, cream, 0.1)
	# trous
	for p: Vector2i in [Vector2i(12, 5), Vector2i(24, 6), Vector2i(4, 17), Vector2i(31, 17)]:
		_rect(img, ox + p.x, p.y + sag, 2, 2, rind[0] if p.y > 12 else cream[1])
		_px(img, ox + p.x + 1, p.y + sag + 1, rind[3] if p.y > 12 else cream[3])
	# visage : yeux ronds, bouche en fer à cheval renversé
	_eye(img, ox + 11, 12 + sag, 3, 3)
	_eye(img, ox + 23, 12 + sag, 3, 3)
	_rect(img, ox + 11, 11 + sag, 3, 1, rind[0])
	_rect(img, ox + 23, 11 + sag, 3, 1, rind[0])
	_line(img, ox + 15, 17 + sag, ox + 17, 16 + sag, dark)
	_rect(img, ox + 17, 16 + sag, 4, 1, dark)
	_line(img, ox + 21, 16 + sag, ox + 23, 17 + sag, dark)


## Rat de cave : long, gris, les dents en avant, la queue qui traîne.
static func _rat(img: Image, ox: int, f: int) -> void:
	var mid := _ramp("#7c7886")
	var light := _ramp("#aaa6b4")
	var pink := _ramp("#e0a0a8")
	var dark := _ramp("#4a4650")
	var dy := f
	# queue en point d'interrogation
	_cap(img, ox + 8.0, 17.5 + dy, ox + 3.5, 18.5 + dy, 0.8, 0.7, pink)
	_cap(img, ox + 3.5, 18.5 + dy, ox + 2.8, 14.0 + dy, 0.7, 0.6, pink)
	# pattes
	for x: int in [12, 15, 23, 26]:
		var r := _dim(dark) if x < 20 else dark
		_cap(img, ox + x + 1.0, 21.0 + dy, ox + x + 1.0, 24.0, 1.0, 1.0, r)
		_px(img, ox + x + 2, 24, pink[2])
	# corps, croupe, ventre clair, tête, museau
	_ell(img, ox + 18.0, 16.0 + dy, 11.0, 6.0, mid)
	_ell(img, ox + 12.0, 16.5 + dy, 6.0, 5.2, mid, 0.1)
	_ell(img, ox + 18.0, 19.8 + dy, 8.0, 2.4, light)
	_ell(img, ox + 29.0, 15.0 + dy, 6.0, 5.0, mid, 0.05)
	_ell(img, ox + 34.0, 16.5 + dy, 3.8, 2.7, light, 0.05)
	# oreille ronde, œil, nez, dents
	_ell(img, ox + 26.5, 9.5 + dy, 3.2, 3.2, mid, 0.1)
	_ell(img, ox + 26.5, 9.8 + dy, 1.7, 1.7, pink)
	_eye(img, ox + 30, 12 + dy, 3, 3)
	_px(img, ox + 37, 16 + dy, pink[1])
	_px(img, ox + 37, 17 + dy, pink[1])
	_curve(img, Vector2(ox + 33.6, 18.6 + dy), Vector2(ox + 35.4, 19.9 + dy), Vector2(ox + 37.2, 18.4 + dy), dark[0], 0.4)
	if K == 1:
		_rect(img, ox + 35, 19 + dy, 2, 2, Color.WHITE)
		_px(img, ox + 36, 20 + dy, light[1])
	else:
		_ellipse(img, ox + 35.9, 20.2 + dy, 1.0, 1.35, Color("#f4ecd8"))
		_curve(img, Vector2(ox + 35.9, 19.2 + dy), Vector2(ox + 35.9, 20.2 + dy), Vector2(ox + 35.9, 21.0 + dy), light[1], 0.18)
	# moustaches
	_line(img, ox + 35, 17 + dy, ox + 37, 15 + dy, light[3])
	_line(img, ox + 35, 18 + dy, ox + 37, 19 + dy, light[3])


## Coq : droit comme un i, crête haute, queue en panache. Rien ne le ramollit.
static func _rooster(img: Image, ox: int, f: int) -> void:
	var rust := _ramp("#b4562c")
	var rust_l := _ramp("#e08a48")
	var gold := _ramp("#e8b84a")
	var red := _ramp("#d8302c")
	var green := _ramp("#2e8a6a")
	var blue := _ramp("#2a5aa0")
	var beak := _ramp("#f0c040")
	var wing := _ramp("#8a3a20")
	var dark := _c("#2b1b2e")
	var puff := f   # la poitrine se gonfle à la seconde pose
	# queue en panache, derrière le corps
	_cap(img, ox + 9.0, 24.0, ox + 3.0, 8.0, 1.6, 0.8, green)
	_cap(img, ox + 10.0, 23.0, ox + 6.0, 6.0, 1.6, 0.8, blue)
	_cap(img, ox + 11.0, 24.0, ox + 10.0, 5.0, 1.5, 0.8, green)
	_cap(img, ox + 8.0, 26.0, ox + 2.0, 14.0, 1.6, 0.8, blue)
	# pattes et éperons
	_cap(img, ox + 16.0, 32.0, ox + 16.0, 37.0, 1.0, 1.0, beak)
	_cap(img, ox + 23.0, 32.0, ox + 23.0, 37.0, 1.0, 1.0, beak)
	_rect(img, ox + 13, 37, 5, 1, beak[3])
	_rect(img, ox + 20, 37, 5, 1, beak[3])
	# corps, poitrine, aile
	_ell(img, ox + 17.0, 25.0, 11.0, 8.5, rust)
	_ell(img, ox + 24.0, 25.0, 7.0 + puff, 7.0 + puff, rust_l, 0.1)
	_ell(img, ox + 15.0, 25.0, 7.0, 4.5, wing, 0.1)
	# cou et collerette dorée, tête
	_ell(img, ox + 26.0, 16.0, 4.5, 7.0, gold)
	_ell(img, ox + 29.0, 10.0, 4.5, 4.5, rust_l, 0.1)
	# crête, barbillon, bec
	_ell(img, ox + 27.0, 4.5, 1.8, 2.2, red, 0.1)
	_ell(img, ox + 29.5, 4.0, 1.8, 2.4, red, 0.1)
	_ell(img, ox + 32.0, 5.0, 1.6, 2.0, red, 0.1)
	_ell(img, ox + 33.0, 14.5, 1.4, 2.6, red, 0.1)
	_ell(img, ox + 35.0, 10.0, 2.9, 1.3, beak, 0.2)
	_px(img, ox + 37, 10, beak[2])
	_rect(img, ox + 33, 11, 4, 1, beak[1])
	# œil rond et sourcil sévère
	_eye(img, ox + 30, 8, 3, 3)
	_rect(img, ox + 30, 7, 4, 1, dark)


## Chamois : sabots sûrs, cornes en crochet, regard de celui qui a déjà tout vu de là-haut.
static func _chamois(img: Image, ox: int, f: int) -> void:
	var dark := _c("#3a2c24")
	var mid := _c("#8a6a48")
	var light := _c("#c9a77a")
	var cream := _c("#efe2c4")
	var dy := f
	for x: int in [10, 13, 26, 29]:
		_rect(img, ox + x, 25 + dy, 2, 9 - dy, dark)
	_ellipse(img, ox + 20.0, 20.0 + dy, 12.0, 6.5, mid)
	_ellipse(img, ox + 20.0, 24.0 + dy, 9.0, 2.4, light)
	_ellipse(img, ox + 31.0, 15.0 + dy, 4.5, 6.5, mid)
	_ellipse(img, ox + 33.5, 14.0 + dy, 5.0, 4.5, mid)
	_ellipse(img, ox + 38.0, 17.0 + dy, 3.2, 2.6, cream)
	_rect(img, ox + 4, 16 + dy, 3, 3, dark)
	_line(img, ox + 31, 10 + dy, ox + 30, 4 + dy, dark)
	_line(img, ox + 30, 4 + dy, ox + 34, 2 + dy, dark)
	_line(img, ox + 34, 10 + dy, ox + 36, 4 + dy, dark)
	_line(img, ox + 36, 4 + dy, ox + 39, 4 + dy, dark)
	_ellipse(img, ox + 29.0, 9.5 + dy, 2.0, 1.4, light)
	_ellipse(img, ox + 35.5, 13.6 + dy, 1.9, 1.5, Color.WHITE)
	_ellipse(img, ox + 36.2, 13.9 + dy, 0.85, 0.85, dark)
	_ellipse(img, ox + 35.4, 12.5 + dy, 2.0, 0.55, dark)
	_px(img, ox + 41, 17 + dy, dark)


## Parchemin vivant : un rouleau debout, couvert de petites lignes, le coin retroussé.
static func _scroll(img: Image, ox: int, f: int) -> void:
	var paper := _c("#e8d8a8")
	var shade := _c("#c2ae78")
	var ink := _c("#4a3a2c")
	var roll := _c("#b89a5c")
	var dy := f
	_rect(img, ox + 6, 6 + dy, 16, 22 - dy, paper)
	_rect(img, ox + 19, 6 + dy, 3, 22 - dy, shade)
	_ellipse(img, ox + 14.0, 6.0 + dy, 9.0, 3.2, roll)
	_ellipse(img, ox + 14.0, 6.0 + dy, 5.0, 1.4, shade)
	_ellipse(img, ox + 14.0, 28.0, 9.0, 3.2, roll)
	_ellipse(img, ox + 14.0, 28.0, 5.0, 1.4, shade)
	for y: int in [10, 12, 23, 25]:
		_rect(img, ox + 8, y + dy, 8 + (y % 3) * 2, 1, ink)
	_rect(img, ox + 4, 30, 4, 3, shade)
	_rect(img, ox + 20, 30, 4, 3, shade)
	_line(img, ox + 22, 14 + dy, ox + 25, 11 + dy, shade)
	_line(img, ox + 6, 14 + dy, ox + 3, 17 + dy, shade)


## Tampon zélé : bois, caoutchouc rouge, mine de celui qui valide tout ce qui passe.
static func _stamp(img: Image, ox: int, f: int) -> void:
	var wood := _c("#9a6a3c")
	var wood_d := _c("#5e3e22")
	var wood_l := _c("#c8945c")
	var rub := _c("#b83a3a")
	var rub_l := _c("#e06a5a")
	var dy := f
	_ellipse(img, ox + 14.0, 3.5 + dy, 3.5, 2.0, wood_l)
	_rect(img, ox + 9, 6 + dy, 10, 12 - dy, wood)
	_rect(img, ox + 16, 6 + dy, 3, 12 - dy, wood_d)
	_rect(img, ox + 4, 18, 20, 6, wood_d)
	_rect(img, ox + 4, 18, 20, 1, wood_l)
	_rect(img, ox + 3, 24, 22, 5, rub)
	_rect(img, ox + 3, 24, 22, 1, rub_l)
	_rect(img, ox + 6, 29, 5, 3, wood_d)
	_rect(img, ox + 17, 29, 5, 3, wood_d)


# ------------------------------------------------------------ monstres des Mines (chapitre 4)

## Remplit un triangle (pour les ailes, les flammes, les cornes).
static func _tri(img: Image, a: Vector2, b: Vector2, c: Vector2, col: Color) -> void:
	a *= K
	b *= K
	c *= K
	var minx := int(floor(minf(a.x, minf(b.x, c.x))))
	var maxx := int(ceil(maxf(a.x, maxf(b.x, c.x))))
	var miny := int(floor(minf(a.y, minf(b.y, c.y))))
	var maxy := int(ceil(maxf(a.y, maxf(b.y, c.y))))
	var d := (b.y - c.y) * (a.x - c.x) + (c.x - b.x) * (a.y - c.y)
	if absf(d) < 0.0001:
		return
	for y in range(miny, maxy + 1):
		for x in range(minx, maxx + 1):
			var px := x + 0.5
			var py := y + 0.5
			var l1 := ((b.y - c.y) * (px - c.x) + (c.x - b.x) * (py - c.y)) / d
			var l2 := ((c.y - a.y) * (px - c.x) + (a.x - c.x) * (py - c.y)) / d
			var l3 := 1.0 - l1 - l2
			if l1 >= 0.0 and l2 >= 0.0 and l3 >= 0.0:
				PA.px(img, x, y, col)


## Gobelin des Mines. kind 0 Gobe-Lard (couperet), 1 Gobe-Pic (pioche volée), 2 Gobe-Gras (chef,
## ventre énorme, casque en croûte de fromage). col : 2 attaque, 3 coup reçu.
static func _goblin(img: Image, ox: int, f: int, col: int, kind: int) -> void:
	var skin := _ramp("#6f9a3a" if kind != 1 else "#8a9a3c")
	var cloth := _ramp("#6a4a32" if kind != 2 else "#8a3a2a")
	var metal := _ramp("#8a8ea0")
	var rind := _ramp("#a0763a")
	var dy := f
	var fat := 3.0 if kind == 2 else 0.0
	var cx := 19.0 if kind != 2 else 21.0
	var base := 1 if kind == 2 else 0
	# jambes et pieds
	_cap(img, ox + cx - 4.0, 30.0 + dy + base, ox + cx - 5.0, 38.0 + base, 2.2, 2.0, _dim(skin))
	_cap(img, ox + cx + 4.0, 30.0 + dy + base, ox + cx + 5.0, 38.0 + base, 2.2, 2.0, skin)
	_rect(img, ox + int(cx) - 8, 38 + base, 5, 2, skin[1])
	_rect(img, ox + int(cx) + 3, 38 + base, 5, 2, skin[2])
	# torse en voûte, gros ventre de lard
	_ell(img, ox + cx - 1.0, 24.0 + dy + base, 7.5 + fat, 8.5 + fat * 0.6, cloth)
	_ell(img, ox + cx + 1.5, 27.0 + dy + base, 5.5 + fat, 5.0 + fat * 0.6, skin, 0.1)
	_rect(img, ox + int(cx) - 6, 28 + dy + base, 12, 1, Color("#c9a24a"))
	# tête : grande, oreille pointue en arrière
	var hx := cx + 3.0
	var hy := 12.0 + dy + base
	_cap(img, ox + hx - 5.0, hy - 1.0, ox + hx - 13.0, hy - 6.0, 2.2, 0.8, skin)
	_ell(img, ox + hx, hy, 7.5, 6.5, skin, 0.05)
	_ell(img, ox + hx + 6.0, hy + 2.0, 3.0, 2.2, skin, 0.15)
	# œil jaune de rancune, sourcil
	var eye_y := int(hy) - 2
	_grudge_eye(img, ox + int(hx) + 3.0, eye_y + 1.5, 2.3, 1.6, col == 3)
	# bouche à crocs
	_brute_mouth(img, ox + int(hx) + 1.5, int(hy) + 3.6, 6.5, col == 2)
	# casque en croûte de fromage pour le chef, bandeau sale sinon
	if kind == 2:
		_ell(img, ox + hx, hy - 5.0, 8.0, 3.8, rind)
		_rect(img, ox + int(hx) - 7, int(hy) - 4, 15, 2, rind[1])
		_px(img, ox + int(hx) - 2, int(hy) - 7, rind[4])
		_px(img, ox + int(hx) + 2, int(hy) - 6, rind[0])
	else:
		_rect(img, ox + int(hx) - 6, int(hy) - 5, 12, 2, Color("#8a3a2a"))
	# bras et arme
	var arm_up := col == 2
	var hand_x := cx + 8.0
	var hand_y := 20.0 + dy + base if not arm_up else 14.0
	_cap(img, ox + cx + 5.0, 20.0 + dy + base, ox + hand_x, hand_y, 2.0, 1.8, skin)
	if kind == 1:
		_line(img, ox + int(hand_x), int(hand_y) + 6, ox + int(hand_x) + 1, int(hand_y) - 8, Color("#7a5632"))
		_cap(img, ox + hand_x - 5.0, hand_y - 8.0, ox + hand_x + 4.0, hand_y - 7.0, 1.2, 1.0, metal)
	else:
		_line(img, ox + int(hand_x), int(hand_y) + 4, ox + int(hand_x), int(hand_y) - 3, Color("#7a5632"))
		_ell(img, ox + hand_x + 1.0, hand_y - 6.0, 4.2 if kind == 0 else 5.0, 4.0, metal)
		_px(img, ox + int(hand_x) + 1, int(hand_y) - 8, metal[4])
	_cap(img, ox + cx - 6.0, 21.0 + dy + base, ox + cx - 9.0, 29.0 + dy + base, 2.0, 1.8, _dim(skin))


## Chauve-souris Pâte-Molle : pâle comme une tomme, ailes en membrane.
static func _bat(img: Image, ox: int, f: int, col: int) -> void:
	var body := _ramp("#bfae88")
	var wing := _ramp("#8a7a66")
	var dark := _c("#2b1b2e")
	var up := f == 0
	var wy := 6.0 if up else 14.0
	# ailes : deux triangles à doigts
	for side in 2:
		var sx := -1.0 if side == 0 else 1.0
		var r := wing if side == 1 else _dim(wing)
		var tip := Vector2(float(ox) + 22.0 + sx * 19.0, wy)
		_tri(img, Vector2(float(ox) + 22.0, 14.0), tip, Vector2(float(ox) + 22.0 + sx * 15.0, 24.0), r[2])
		_tri(img, Vector2(float(ox) + 22.0, 14.0), tip, Vector2(float(ox) + 22.0 + sx * 8.0, 10.0), r[3])
		for k in 3:
			var ex := 22.0 + sx * (8.0 + 6.0 * float(k))
			var ey := 22.0 + 1.5 * float(k)
			_line(img, ox + 22, 14, ox + int(ex), int(ey), r[0])
		_line(img, ox + 22, 14, int(tip.x), int(tip.y), r[1])
	# corps rond et pâle, tête, grandes oreilles
	_ell(img, ox + 22.0, 17.0, 5.5, 6.5, body)
	_ell(img, ox + 22.0, 19.5, 3.5, 3.5, _ramp("#e8dcb4"), 0.1)
	_ell(img, ox + 22.0, 9.0, 4.5, 4.0, body, 0.05)
	_tri(img, Vector2(ox + 18.0, 8.0), Vector2(ox + 16.0, 3.0), Vector2(ox + 21.0, 6.0), body[2])
	_tri(img, Vector2(ox + 26.0, 8.0), Vector2(ox + 28.0, 3.0), Vector2(ox + 23.0, 6.0), body[2])
	if col == 3:
		_rect(img, ox + 19, 9, 2, 1, dark)
		_rect(img, ox + 24, 9, 2, 1, dark)
	else:
		_rect(img, ox + 19, 8, 2, 2, Color("#f06060"))
		_rect(img, ox + 24, 8, 2, 2, Color("#f06060"))
	if col == 2:
		_rect(img, ox + 20, 11, 5, 2, Color("#4a1424"))
		_px(img, ox + 20, 11, Color.WHITE)
		_px(img, ox + 24, 11, Color.WHITE)
	else:
		_px(img, ox + 22, 12, dark)


## Troll des cavernes, « Gros Bleu » : peau bleutée veinée de moisissure, massue en coin de cantal.
static func _troll(img: Image, ox: int, f: int, col: int) -> void:
	var skin := _ramp("#6a86a8")
	var mold := _ramp("#5a9a8a")
	var cloth := _ramp("#8a5a3a")
	var cheese := _ramp("#e8a83c")
	var dark := _c("#2b1b2e")
	var dy := f
	# jambes de piliers
	_cap(img, ox + 21.0, 44.0 + dy, ox + 19.0, 62.0, 6.0, 5.0, _dim(skin))
	_cap(img, ox + 36.0, 44.0 + dy, ox + 38.0, 62.0, 6.0, 5.0, skin)
	_rect(img, ox + 13, 62, 12, 3, skin[1])
	_rect(img, ox + 33, 62, 13, 3, skin[2])
	# torse énorme, ventre, pagne en croûte
	_ell(img, ox + 29.0, 34.0 + dy, 15.0, 15.0, skin)
	_ell(img, ox + 31.0, 40.0 + dy, 11.0, 9.0, skin, 0.15)
	_trap(img, 46 + dy, 54 + dy, ox + 18.0, ox + 42.0, ox + 17.0, ox + 43.0, cloth)
	# veines de moisissure
	for i in 9:
		var mx := ox + 16 + int(PA.rnd(i, 1, 941) * 26.0)
		var my := 24 + int(PA.rnd(i, 2, 941) * 22.0) + dy
		_rect(img, mx, my, 2, 2, mold[2])
		_px(img, mx + 1, my + 1, mold[3])
	# bras gauche pendant, bras droit levé avec la massue
	_cap(img, ox + 16.0, 26.0 + dy, ox + 10.0, 46.0 + dy, 4.5, 4.0, _dim(skin))
	var raise := col == 2
	var hx := 47.0 if not raise else 48.0
	var hy := 28.0 + dy if not raise else 25.0
	_cap(img, ox + 43.0, 26.0 + dy, ox + hx, hy, 4.5, 3.8, skin)
	_ell(img, ox + hx, hy, 4.2, 4.2, skin, 0.1)
	# massue : un coin de cantal troué
	_line(img, ox + int(hx), int(hy), ox + int(hx) + 1, int(hy) - 14, Color("#7a5632"))
	_line(img, ox + int(hx) + 1, int(hy), ox + int(hx) + 2, int(hy) - 14, Color("#5e3e22"))
	_tri(img, Vector2(ox + hx - 7.0, hy - 6.0), Vector2(ox + hx + 9.0, hy - 6.0), Vector2(ox + hx + 1.0, hy - 22.0), cheese[2])
	_tri(img, Vector2(ox + hx - 7.0, hy - 6.0), Vector2(ox + hx + 1.0, hy - 6.0), Vector2(ox + hx + 1.0, hy - 22.0), cheese[3])
	_rect(img, ox + int(hx) - 7, int(hy) - 7, 17, 2, cheese[0])
	_px(img, ox + int(hx) - 1, int(hy) - 12, cheese[0])
	_px(img, ox + int(hx) + 3, int(hy) - 16, cheese[0])
	_px(img, ox + int(hx) + 1, int(hy) - 9, cheese[0])
	# petite tête, mâchoire en avant, défenses
	_ell(img, ox + 33.0, 15.0 + dy, 8.5, 7.5, skin, 0.05)
	_ell(img, ox + 38.0, 19.0 + dy, 5.0, 3.5, skin, 0.15)
	_tri(img, Vector2(ox + 38.4, 21.4 + dy), Vector2(ox + 40.8, 21.4 + dy), Vector2(ox + 39.8, 15.8 + dy), Color("#f0e8d0"))
	_tri(img, Vector2(ox + 34.6, 21.0 + dy), Vector2(ox + 36.4, 21.0 + dy), Vector2(ox + 35.6, 16.8 + dy), Color("#f0e8d0"))
	_grudge_eye(img, ox + 35.0, 12.4 + dy, 2.7, 1.8, col == 3)
	if col == 2:
		_brute_mouth(img, ox + 35.5, 18.6 + dy, 6.0, true)
	_ell(img, ox + 27.0, 11.0 + dy, 2.5, 2.5, mold)
	_ell(img, ox + 28.0, 8.0 + dy, 2.5, 2.0, mold)


## Le Guetteur du lac : une grappe de tentacules et un oeil unique qui dépasse de l'eau.
static func _watcher(img: Image, ox: int, f: int, col: int) -> void:
	var flesh := _ramp("#3a6a5a")
	var belly := _ramp("#8ab89a")
	var water := _ramp("#2a5a7a")
	var dark := _c("#2b1b2e")
	var sway := float(f) * 1.5
	# eau
	_ell(img, ox + 29.0, 45.0, 26.0, 5.0, water)
	_ell(img, ox + 29.0, 44.0, 20.0, 3.0, _ramp("#4a8aaa"))
	# tentacules
	var tips: Array = [[6.0, 14.0], [13.0, 7.0], [47.0, 10.0], [52.0, 18.0], [38.0, 7.0]]
	for i in tips.size():
		var t: Array = tips[i]
		var tx: float = float(t[0]) + (sway if i % 2 == 0 else -sway)
		var ty: float = float(t[1])
		if col == 2 and i >= 2:
			ty -= 2.0
		var bx := 29.0 + (float(i) - 2.0) * 6.0
		_cap(img, ox + bx, 44.0, ox + (bx + tx) * 0.5, (44.0 + ty) * 0.5 + 4.0, 3.2, 2.4, flesh if i % 2 == 0 else _dim(flesh))
		_cap(img, ox + (bx + tx) * 0.5, (44.0 + ty) * 0.5 + 4.0, ox + tx, ty, 2.4, 1.0, flesh if i % 2 == 0 else _dim(flesh))
		_px(img, ox + int(tx), int(ty) + 3, belly[3])
		_px(img, ox + int((bx + tx) * 0.5), int((44.0 + ty) * 0.5) + 6, belly[3])
	# corps bulbeux et grand oeil
	_ell(img, ox + 29.0, 32.0 + sway * 0.5, 13.0, 12.0, flesh)
	_ell(img, ox + 29.0, 34.0 + sway * 0.5, 9.0, 7.0, belly, 0.1)
	_ellipse(img, ox + 29.0, 30.0, 9.0, 7.0, Color("#f4f0d8") if col != 3 else Color("#c8c4a8"))
	if col == 3:
		# œil clos : paupière pleine, un pli sombre au bord
		_ellipse(img, ox + 29.0, 30.6, 9.4, 7.6, dark)
		_ell(img, ox + 29.0, 29.6, 9.0, 7.0, flesh, 0.05)
	else:
		_ellipse(img, ox + 31.0, 30.0, 4.5, 5.0, Color("#e8c820"))
		_ellipse(img, ox + 31.0, 30.0, 1.5, 4.2, dark)
		_px(img, ox + 28, 27, Color.WHITE)
		# paupière lourde : calotte de chair qui retombe en arc sur le haut du globe
		_ellipse(img, ox + 29.0, 23.2, 9.9, 5.6, dark)
		_ell(img, ox + 29.0, 22.2, 9.8, 5.4, flesh, 0.05)
	if col == 2:
		var cxm := ox + 29.5
		_ellipse(img, cxm, 40.0, 9.6, 3.4, dark)
		_ellipse(img, cxm, 40.0, 9.0, 2.8, Color("#5a1426"))
		_ellipse(img, cxm, 41.2, 5.0, 1.4, Color("#d8506a"))
		for k in 7:
			var tx := cxm - 7.5 + float(k) * 2.5
			_tri(img, Vector2(tx - 0.7, 37.4), Vector2(tx + 0.7, 37.4), Vector2(tx, 39.2), Color.WHITE)


## Goulûm (Trempette, pêcheur de Bittebourg) : maigre, pâle, de grands yeux, un poisson cru.
static func _gollum(img: Image, ox: int, f: int, col: int) -> void:
	var skin := _ramp("#b4bca4")
	var rag := _ramp("#6a5a46")
	var dark := _c("#2b1b2e")
	var dy := f
	# jambes pliées, pieds longs
	_cap(img, ox + 14.0, 34.0 + dy, ox + 10.0, 43.0, 2.4, 1.8, _dim(skin))
	_cap(img, ox + 22.0, 34.0 + dy, ox + 26.0, 43.0, 2.4, 1.8, skin)
	_rect(img, ox + 6, 43, 7, 2, skin[1])
	_rect(img, ox + 24, 43, 8, 2, skin[2])
	# dos voûté, côtes
	_ell(img, ox + 17.0, 27.0 + dy, 8.5, 9.0, skin)
	_trap(img, 32 + dy, 38 + dy, ox + 10.0, ox + 25.0, ox + 11.0, ox + 24.0, rag)
	for k in 3:
		_rect(img, ox + 12, 22 + k * 3 + dy, 6, 1, skin[0])
	# bras maigres, l'un tend le poisson
	_cap(img, ox + 11.0, 24.0 + dy, ox + 5.0, 36.0, 1.8, 1.6, _dim(skin))
	var reach := col == 2
	var hx := 29.0 if not reach else 30.0
	var hy := 28.0 if not reach else 25.0
	_cap(img, ox + 22.0, 24.0 + dy, ox + hx, hy, 1.8, 1.6, skin)
	_rect(img, ox + int(hx) - 1, int(hy) - 1, 3, 3, skin[3])
	# poisson cru, argenté, qui frétille
	_ellipse(img, ox + hx + 1.0, hy - 5.0 + float(f), 4.5, 2.2, Color("#c8d4e0"))
	_px(img, ox + int(hx) + 4, int(hy) - 5 + f, Color("#f0f4f8"))
	_px(img, ox + int(hx) - 3, int(hy) - 6 + f, Color("#8a98a8"))
	# grosse tête, grandes oreilles
	_cap(img, ox + 12.0, 12.0 + dy, ox + 7.0, 8.0, 1.8, 0.8, skin)
	_ell(img, ox + 18.0, 14.0 + dy, 8.0, 7.5, skin, 0.05)
	_ell(img, ox + 23.0, 17.0 + dy, 3.5, 2.8, skin, 0.15)
	_rect(img, ox + 14, 5 + dy, 3, 2, skin[0])
	_rect(img, ox + 19, 4 + dy, 2, 3, skin[0])
	# yeux énormes qui luisent
	if col == 3:
		_rect(img, ox + 16, 12 + dy, 4, 1, dark)
		_rect(img, ox + 22, 12 + dy, 3, 1, dark)
	else:
		_eye(img, ox + 14, 8 + dy, 7, 7, _c("#9ad8e8"))
		_eye(img, ox + 21, 9 + dy, 6, 6, _c("#9ad8e8"))
	if col == 2:
		_ellipse(img, ox + 24.0, 20.5 + dy, 3.6, 2.4, dark)
		_ellipse(img, ox + 24.0, 20.7 + dy, 3.0, 1.9, Color("#4a1424"))
		_tri(img, Vector2(ox + 22.0, 19.2 + dy), Vector2(ox + 23.4, 19.2 + dy), Vector2(ox + 22.7, 20.8 + dy), Color.WHITE)
		_tri(img, Vector2(ox + 24.8, 19.2 + dy), Vector2(ox + 26.2, 19.2 + dy), Vector2(ox + 25.5, 20.8 + dy), Color.WHITE)
	else:
		_curve(img, Vector2(ox + 21.0, 19.8 + dy), Vector2(ox + 23.5, 20.8 + dy), Vector2(ox + 26.0, 19.4 + dy), dark, 0.5)


## Le Balourd : un démon des profondeurs, lourd, noir de suie, crinière de flammes, fouet de braise.
static func _balrog(img: Image, ox: int, f: int, col: int) -> void:
	var body := _ramp("#3a1a2c")
	var horn := _ramp("#c8b89a")
	var dark := _c("#1a0a14")
	var dy := f
	# jambes énormes
	_cap(img, ox + 24.0, 54.0 + dy, ox + 22.0, 72.0, 7.5, 6.5, _dim(body))
	_cap(img, ox + 42.0, 54.0 + dy, ox + 44.0, 72.0, 7.5, 6.5, body)
	_rect(img, ox + 14, 72, 14, 3, body[1])
	_rect(img, ox + 38, 72, 15, 3, body[2])
	# torse, ventre, ligne de cendre en travers (l'âge de la bête)
	_ell(img, ox + 33.0, 44.0 + dy, 18.0, 17.0, body)
	_ell(img, ox + 35.0, 50.0 + dy, 12.0, 10.0, _ramp("#5a2a3a"), 0.1)
	_curve(img, Vector2(ox + 23.0, 47.0 + dy), Vector2(ox + 33.0, 53.5 + dy), Vector2(ox + 44.0, 46.5 + dy), Color("#14101a"), 0.75)
	_curve(img, Vector2(ox + 26.0, 49.5 + dy), Vector2(ox + 33.0, 54.0 + dy), Vector2(ox + 41.0, 49.0 + dy), body[3], 0.4)
	# flammes qui courent le long du dos
	for i in 7:
		var fx := 14.0 + float(i) * 3.5
		var fy := 32.0 + dy - float(i % 3) * 3.0 + (2.0 if f == 1 else 0.0)
		_tri(img, Vector2(ox + fx - 3.0, fy + 6.0), Vector2(ox + fx, fy - 8.0 - float(i % 2) * 4.0), Vector2(ox + fx + 3.0, fy + 6.0), Color("#e8501c") if i % 2 == 0 else Color("#ffa030"))
		_tri(img, Vector2(ox + fx - 1.5, fy + 6.0), Vector2(ox + fx, fy - 2.0), Vector2(ox + fx + 1.5, fy + 6.0), Color("#ffe070"))
	# bras de gorille, l'un traîne, l'autre brandit le fouet
	_cap(img, ox + 18.0, 34.0 + dy, ox + 10.0, 58.0 + dy, 6.0, 5.0, _dim(body))
	var raise := col == 2
	var hx := 56.0 if not raise else 57.0
	var hy := 52.0 + dy if not raise else 34.0
	_cap(img, ox + 50.0, 36.0 + dy, ox + hx, hy, 6.0, 4.8, body)
	_ell(img, ox + hx, hy, 5.0, 5.0, body, 0.1)
	var whip := Color("#ff8a30")
	for k in 14:
		var t := float(k) / 13.0
		var wx := hx + 2.0 + t * 4.0
		var wy := hy - 4.0 - t * 22.0 + sin(t * 6.0) * 4.0
		_rect(img, ox + int(wx), int(wy), 2, 2, whip if k % 3 != 0 else Color("#ffe070"))
	# tête, cornes de bélier, yeux de braise
	_ell(img, ox + 33.0, 22.0 + dy, 11.0, 10.0, body, 0.05)
	_cap(img, ox + 24.0, 16.0 + dy, ox + 15.0, 12.0 + dy, 3.4, 2.0, horn)
	_cap(img, ox + 15.0, 12.0 + dy, ox + 14.0, 4.0 + dy, 2.0, 0.8, horn)
	_cap(img, ox + 42.0, 16.0 + dy, ox + 51.0, 12.0 + dy, 3.4, 2.0, horn)
	_cap(img, ox + 51.0, 12.0 + dy, ox + 52.0, 4.0 + dy, 2.0, 0.8, horn)
	if col == 3:
		_curve(img, Vector2(ox + 26.5, 20.4 + dy), Vector2(ox + 29.0, 21.6 + dy), Vector2(ox + 31.5, 20.0 + dy), dark, 0.6)
		_curve(img, Vector2(ox + 36.5, 20.0 + dy), Vector2(ox + 39.0, 21.6 + dy), Vector2(ox + 41.5, 20.4 + dy), dark, 0.6)
	else:
		for ex: float in [29.5, 38.5]:
			_ellipse(img, ox + ex, 20.5 + dy, 3.0, 2.0, Color("#ffb030"))
			_ellipse(img, ox + ex + 0.2, 20.6 + dy, 1.5, 1.3, Color("#fff0a0"))
			_ellipse(img, ox + ex + 0.4, 20.6 + dy, 0.4, 1.2, dark)
		# sourcils lourds, baissés vers le nez
		_curve(img, Vector2(ox + 25.5, 16.2 + dy), Vector2(ox + 28.5, 16.6 + dy), Vector2(ox + 32.5, 18.6 + dy), dark, 0.7)
		_curve(img, Vector2(ox + 42.0, 16.2 + dy), Vector2(ox + 39.0, 16.6 + dy), Vector2(ox + 35.0, 18.6 + dy), dark, 0.7)
	if col == 2:
		# gueule grande ouverte : palais de braise, crocs en haut et en bas
		_ellipse(img, ox + 33.5, 30.0 + dy, 6.6, 3.8, dark)
		_ellipse(img, ox + 33.5, 30.2 + dy, 5.8, 3.1, Color("#ff5a20"))
		_ellipse(img, ox + 33.5, 31.2 + dy, 3.4, 1.4, Color("#ffb030"))
		for k in 4:
			var tx := 29.6 + float(k) * 2.6
			_tri(img, Vector2(ox + tx - 0.8, 27.6 + dy), Vector2(ox + tx + 0.8, 27.6 + dy), Vector2(ox + tx, 29.6 + dy), Color.WHITE)
		for k in 3:
			var tx2 := 30.9 + float(k) * 2.6
			_tri(img, Vector2(ox + tx2 - 0.7, 32.8 + dy), Vector2(ox + tx2 + 0.7, 32.8 + dy), Vector2(ox + tx2, 31.0 + dy), Color("#f0e8d8"))
	else:
		# bouche basse, en moue, et deux petites défenses qui remontent
		_curve(img, Vector2(ox + 27.5, 30.6 + dy), Vector2(ox + 33.5, 27.0 + dy), Vector2(ox + 39.5, 30.6 + dy), dark, 0.75)
		_tri(img, Vector2(ox + 28.2, 30.4 + dy), Vector2(ox + 29.8, 29.4 + dy), Vector2(ox + 28.6, 27.6 + dy), horn[3])
		_tri(img, Vector2(ox + 38.8, 30.4 + dy), Vector2(ox + 37.2, 29.4 + dy), Vector2(ox + 38.4, 27.6 + dy), horn[3])



# ---------------------------------------------------------- chapitre 5

## Ouroukouille, grand orque de l'Isengarde-Manger. kind : 0 de ligne (casque de marmite, couvercle
## en bouclier), 1 brocheur (brochette de deux mètres), 2 pétrisseur (tablier de farine, rouleau),
## 3 chef de cuisine (toque noircie, louche).
static func _orc(img: Image, ox: int, f: int, col: int, kind: int) -> void:
	var skin := _ramp("#4a4a46" if kind != 3 else "#3c4440")
	var cloth := _ramp(["#6a4a32", "#5a3a2a", "#d8d2c0", "#2a2a30"][kind])
	var metal := _ramp("#8a8ea0")
	var fat := 3.0 if kind == 2 else 0.0
	var dy := f
	var base := 7 if kind == 3 else 0   # (le chef : toque et louche restent dans la case)
	var cx := 21.0 + (2.0 if kind == 3 else 0.0)
	_cap(img, ox + cx - 5.0, 33.0 + dy + base, ox + cx - 6.0, 44.0 + base, 3.0, 2.6, _dim(skin))
	_cap(img, ox + cx + 5.0, 33.0 + dy + base, ox + cx + 6.0, 44.0 + base, 3.0, 2.6, skin)
	_rect(img, ox + int(cx) - 10, 44 + base, 7, 3, skin[1])
	_rect(img, ox + int(cx) + 3, 44 + base, 7, 3, skin[2])
	_ell(img, ox + cx, 26.0 + dy + base, 10.0 + fat, 10.5 + fat * 0.6, cloth)
	if kind == 2:
		# tablier de farine : un plastron qui s'évase, plis et traces de doigts, bretelles
		var apron := _ramp("#e8e2d2")
		_trap(img, 21 + dy + base, 37 + dy + base, ox + cx - 5.0, ox + cx + 5.0, ox + cx - 8.0, ox + cx + 8.0, apron)
		_rect(img, ox + int(cx) - 5, 21 + dy + base, 10, 1, apron[4])
		_line(img, ox + int(cx) - 4, 22 + dy + base, ox + int(cx) - 6, 17 + dy + base, apron[1])
		_line(img, ox + int(cx) + 4, 22 + dy + base, ox + int(cx) + 6, 17 + dy + base, apron[1])
		for k in 3:
			_line(img, ox + int(cx) - 5 + k * 4, 25 + dy + base, ox + int(cx) - 6 + k * 5, 35 + dy + base, apron[1])
		for k in 4:
			_px(img, ox + int(cx) - 4 + k * 3, 29 + dy + base + (k % 2) * 3, Color("#b8b09a"))
		_rect(img, ox + int(cx) - 7, 33 + dy + base, 14, 1, apron[2])
	else:
		_rect(img, ox + int(cx) - 8, 32 + dy + base, 17, 2, Color("#c9a24a"))
	var hx := cx + 3.0
	var hy := 12.0 + dy + base
	_ell(img, ox + hx, hy, 8.0, 7.5, skin, 0.05)
	_ell(img, ox + hx + 7.0, hy + 3.0, 3.6, 2.8, skin, 0.15)
	_cap(img, ox + hx - 6.0, hy - 2.0, ox + hx - 12.0, hy - 6.0, 2.0, 0.8, skin)
	var ey := int(hy) - 2
	_grudge_eye(img, ox + int(hx) + 3.5, ey + 1.5, 2.6, 1.7, col == 3)
	_brute_mouth(img, ox + int(hx) + 1.5, int(hy) + 4.6, 8.0, col == 2)
	match kind:
		0:   # casque de marmite
			_ell(img, ox + hx, hy - 5.0, 8.0, 4.4, metal, 0.0, hy - 1.0)
			_rect(img, ox + int(hx) - 8, int(hy) - 3, 17, 2, metal[1])
		1:
			_rect(img, ox + int(hx) - 7, int(hy) - 6, 14, 3, Color("#8a3a2a"))
		2:
			_rect(img, ox + int(hx) - 6, int(hy) - 9, 12, 5, Color("#f4f0e4"))
			_rect(img, ox + int(hx) - 6, int(hy) - 5, 12, 1, Color("#c8c2b0"))
		3:
			_rect(img, ox + int(hx) - 5, int(hy) - 14, 11, 9, Color("#4a4640"))
			_ell(img, ox + hx, hy - 14.0, 7.0, 3.5, _ramp("#5a564e"))
	var hand_x := cx + 13.0
	var hand_y := 24.0 + dy + base if col != 2 else 16.0 + float(base)
	_cap(img, ox + cx + 7.0, 22.0 + dy + base, ox + hand_x, hand_y, 2.6, 2.2, skin)
	match kind:
		0:
			_line(img, ox + int(hand_x), int(hand_y) + 8, ox + int(hand_x), int(hand_y) - 8, Color("#7a5632"))
			_ell(img, ox + hand_x, hand_y - 10.0, 5.0, 4.0, metal)
			_ell(img, ox + cx - 9.0, 28.0 + dy + base, 5.0, 7.0, _ramp("#a8aab8"))   # couvercle
			_px(img, ox + int(cx) - 10, 27 + dy + base, Color.WHITE)
		1:
			_line(img, ox + int(hand_x) - 10, int(hand_y) + 6, ox + int(hand_x) + 3, int(hand_y) - 14, Color("#9a9aa6"))
			for k in 3:
				_ell(img, ox + hand_x - 3.0 - k * 1.4, hand_y - 4.0 - k * 4.0, 2.2, 2.0, _ramp("#b8803c" if k % 2 == 0 else "#a83c2a"))
		2:
			_cap(img, ox + hand_x - 6.0, hand_y + 1.0, ox + hand_x + 6.0, hand_y - 3.0, 1.8, 1.8, _ramp("#c8a064"))
		3:
			_line(img, ox + int(hand_x), int(hand_y) + 8, ox + int(hand_x), int(hand_y) - 10, Color("#7a5632"))
			_ell(img, ox + hand_x, hand_y - 12.0, 5.5, 4.5, metal)
			_ell(img, ox + hand_x, hand_y - 12.0, 3.5, 2.6, _ramp("#2a2a30"))
	if kind == 2:   # pétrisseur : foulard rouge, boule de pâte dans la main libre, nuage de farine
		_rect(img, ox + int(hx) - 6, int(hy) + 6, 12, 3, Color("#b8382a"))
		_rect(img, ox + int(hx) - 6, int(hy) + 6, 12, 1, Color("#d85a40"))
		_ell(img, ox + cx - 10.0, 31.0 + dy, 4.2, 3.6, _ramp("#f0e2b8"))
		_px(img, ox + int(cx) - 11, 29 + int(dy), Color.WHITE)
		_cap(img, ox + cx - 6.0, 24.0 + dy, ox + cx - 10.0, 30.0 + dy, 2.4, 2.0, skin)
		for k in 7:
			_px(img, ox + int(cx) - 14 + (k * 7) % 28, 14 + (k * 5) % 22, Color("#f4f0e4") if k % 2 == 0 else Color("#d8d2c0"))


## Pâton : une boule de pâte qui lève, deux yeux d'olive et une bouche de fournil.
static func _dough(img: Image, ox: int, f: int, col: int) -> void:
	var d := _ramp("#e8d8b0")
	var rise := 2.0 if f == 1 else 0.0
	_ell(img, ox + 19.0, 24.0 - rise * 0.5, 14.0, 10.0 + rise, d)
	_ell(img, ox + 12.0, 28.0, 7.0, 5.0, d)
	_ell(img, ox + 27.0, 28.0, 7.0, 5.0, d)
	for k in 4:
		_px(img, ox + 10 + k * 5, 18 + (k % 2) * 3, Color("#f8f0d8"))
	var ey := 20 if col != 3 else 22
	for ex: float in [15.5, 23.5]:
		_ellipse(img, ox + ex, ey + 1.5, 1.9, 1.9, Color("#4a5a2a"))
		_ellipse(img, ox + ex - 0.6, ey + 0.8, 0.7, 0.7, Color("#e8f0b0"))
	if col == 2:
		_ellipse(img, ox + 20.0, 29.0, 5.4, 2.4, Color("#5a2a1c"))
		_ellipse(img, ox + 20.0, 30.0, 3.0, 1.0, Color("#c0506a"))
	else:
		_ellipse(img, ox + 19.5, 28.5, 3.2, 0.55, Color("#5a2a1c"))


## Ouargue-Garou : loup maigre à collier de moine, gueule ouverte, regard sur les restes.
static func _warg(img: Image, ox: int, f: int, col: int) -> void:
	var fur := _ramp("#5a5448")
	var dy := f
	_cap(img, ox + 14.0, 22.0 + dy, ox + 11.0, 32.0, 2.4, 1.8, _dim(fur))
	_cap(img, ox + 36.0, 22.0 + dy, ox + 39.0, 32.0, 2.4, 1.8, _dim(fur))
	_ell(img, ox + 25.0, 21.0 + dy, 15.0, 8.5, fur)
	_cap(img, ox + 18.0, 24.0 + dy, ox + 17.0, 33.0, 2.6, 2.0, fur)
	_cap(img, ox + 32.0, 24.0 + dy, ox + 33.0, 33.0, 2.6, 2.0, fur)
	_cap(img, ox + 10.0, 18.0 + dy, ox + 3.0, 12.0 - dy, 2.4, 0.8, fur)
	var hx := 39.0
	var hy := 14.0 + dy
	_ell(img, ox + hx, hy, 6.5, 5.5, fur, 0.05)
	_ell(img, ox + hx + 6.0, hy + 2.0, 4.0, 2.6, _ramp("#6a6458"))
	_tri(img, Vector2(ox + hx - 4.0, hy - 4.0), Vector2(ox + hx - 2.0, hy - 10.0), Vector2(ox + hx + 1.0, hy - 4.0), fur[2])
	_grudge_eye(img, ox + hx + 2.5, hy - 0.3, 1.9, 1.3, col == 3)
	if col == 2:
		_brute_mouth(img, ox + hx + 3.2, hy + 1.6, 7.0, true)
	else:
		_curve(img, Vector2(ox + hx + 4.0, hy + 3.4), Vector2(ox + hx + 7.0, hy + 4.4), Vector2(ox + hx + 10.0, hy + 3.2), _c("#1c1418"), 0.5)
		_tri(img, Vector2(ox + hx + 5.6, hy + 3.7), Vector2(ox + hx + 6.8, hy + 3.9), Vector2(ox + hx + 6.2, hy + 5.4), Color("#f4ecd8"))
	_rect(img, ox + int(hx) - 5, int(hy) + 4, 9, 2, Color("#d8d0b8"))   # collier de moine


## Corbeau contrôleur : un oiseau noir à lunettes, un carnet sous l'aile.
static func _crow(img: Image, ox: int, f: int, col: int) -> void:
	var fe := _ramp("#2a2a38")
	var dy := f
	_cap(img, ox + 17.0, 30.0, ox + 16.0, 34.0, 1.0, 0.8, _ramp("#c89a3c"))
	_cap(img, ox + 24.0, 30.0, ox + 25.0, 34.0, 1.0, 0.8, _ramp("#c89a3c"))
	_ell(img, ox + 20.0, 22.0 + dy, 10.0, 9.0, fe)
	_cap(img, ox + 11.0, 24.0 + dy, ox + 3.0, 31.0, 3.0, 1.0, fe)
	var wing_y := 18.0 if col != 2 else 8.0
	_cap(img, ox + 15.0, 20.0 + dy, ox + 7.0, wing_y, 3.5, 1.4, _ramp("#3a3a4c"))
	_ell(img, ox + 29.0, 13.0 + dy, 5.5, 5.0, fe, 0.05)
	_tri(img, Vector2(ox + 33.0, 11.0 + dy), Vector2(ox + 38.0, 14.0 + dy), Vector2(ox + 33.0, 16.0 + dy), Color("#e8a830"))
	_ellipse(img, ox + 30.5, 12.0 + dy, 3.1, 2.6, Color("#6a5a40"))   # lunettes cerclées
	_ellipse(img, ox + 30.5, 12.0 + dy, 2.5, 2.0, Color("#e8e0c8"))
	_ellipse(img, ox + 31.0, 12.2 + dy, 1.0, 1.0, Color("#1c1418") if col != 3 else Color("#8a3a3a"))
	_rect(img, ox + 23, 24 + int(dy), 6, 5, Color("#d8d0b0"))   # carnet
	_rect(img, ox + 24, 26 + int(dy), 4, 1, Color("#6a5a40"))


## Hirsute de Dunlande : un bûcheron de colline, barbe en broussaille, gourdin noueux.
static func _hillman(img: Image, ox: int, f: int, col: int) -> void:
	var skin := _ramp("#c8906a")
	var cloth := _ramp("#6a5030")
	var dy := f
	_cap(img, ox + 16.0, 34.0 + dy, ox + 15.0, 45.0, 3.0, 2.6, _dim(cloth))
	_cap(img, ox + 26.0, 34.0 + dy, ox + 27.0, 45.0, 3.0, 2.6, cloth)
	_rect(img, ox + 11, 45, 8, 3, Color("#3a2a20"))
	_rect(img, ox + 24, 45, 8, 3, Color("#3a2a20"))
	_ell(img, ox + 21.0, 27.0 + dy, 11.0, 10.0, cloth)
	_rect(img, ox + 12, 24 + dy, 18, 3, Color("#a83a2a"))   # chemise à carreaux
	_rect(img, ox + 12, 30 + dy, 18, 3, Color("#a83a2a"))
	_ell(img, ox + 21.0, 14.0 + dy, 7.5, 7.0, skin)
	_ell(img, ox + 21.0, 20.0 + dy, 8.0, 5.0, _ramp("#7a4a2a"))   # barbe
	for ex: float in [19.0, 24.0]:
		var exx := ox + ex   # (les arcs oubliaient « ox » : yeux fermés et sourcils tombaient dans la première pose)
		if col == 3:   # yeux plissés, bien visibles
			_curve(img, Vector2(exx - 1.9, 12.0 + dy), Vector2(exx, 14.4 + dy), Vector2(exx + 1.9, 12.0 + dy), Color("#1c1418"), 0.6)
		else:
			_ellipse(img, exx, 12.8 + dy, 1.7, 1.8, Color("#f0e8e0"))
			_ellipse(img, exx + 0.2, 13.0 + dy, 1.05, 1.15, Color("#1c1418"))
			_ellipse(img, exx - 0.1, 12.5 + dy, 0.35, 0.35, Color("#ffffff"))
			_curve(img, Vector2(exx - 2.2, 10.9 + dy), Vector2(exx, 10.3 + dy), Vector2(exx + 2.2, 11.3 + dy), _c("#4a2c18"), 0.55)
	_rect(img, ox + 13, 8 + int(dy), 16, 3, Color("#8a8a90"))   # bonnet de laine
	var hand_y := 28.0 + dy if col != 2 else 22.0
	_cap(img, ox + 31.0, 24.0 + dy, ox + 35.0, hand_y, 2.6, 2.2, skin)
	_line(img, ox + 35, int(hand_y) + 8, ox + 36, int(hand_y) - 12, Color("#7a5632"))
	_ell(img, ox + 36.0, hand_y - 14.0, 4.0, 5.0, _ramp("#8a6a42"))


## Hors-d'œuvre : un canapé sur pattes de brindille, olive en guise de tête.
static func _canape(img: Image, ox: int, f: int, col: int) -> void:
	var dy := f
	_cap(img, ox + 11.0, 26.0, ox + 9.0, 33.0, 1.0, 1.0, _ramp("#7a5632"))
	_cap(img, ox + 21.0, 26.0, ox + 23.0, 33.0, 1.0, 1.0, _ramp("#7a5632"))
	_rect(img, ox + 6, 21 + dy, 20, 6, Color("#d8b068"))   # pain
	_rect(img, ox + 6, 21 + dy, 20, 1, Color("#f0d090"))
	_ell(img, ox + 16.0, 19.0 + dy, 8.0, 3.5, _ramp("#e8d878"))   # fromage
	_ell(img, ox + 16.0, 14.0 + dy, 4.5, 4.0, _ramp("#6a8a3a"))   # olive
	_rect(img, ox + 14, 13 + int(dy), 2, 2, Color("#f0f0e0") if col != 3 else Color("#1c1418"))
	_rect(img, ox + 18, 13 + int(dy), 2, 2, Color("#f0f0e0") if col != 3 else Color("#1c1418"))
	_px(img, ox + 15, 14 + int(dy), Color("#1c1418"))
	_px(img, ox + 19, 14 + int(dy), Color("#1c1418"))
	_rect(img, ox + 15, 17 + int(dy), 3, 1, Color("#3a2a1c"))
	_px(img, ox + 16, 7 + int(dy), Color("#a83a2a"))   # piment sur la tête
	_rect(img, ox + 16, 8 + int(dy), 1, 2, Color("#a83a2a"))
	var arm_y := 20.0 if col != 2 else 11.0
	_cap(img, ox + 24.0, 22.0, ox + 29.0, arm_y, 1.0, 1.0, _ramp("#7a5632"))
