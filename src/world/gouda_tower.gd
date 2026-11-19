extends RefCounted
## La Tour Blanche de Minas Tartine (champ `white_tower` d'une carte) : un vrai objet en trois
## dimensions, pas un détail peint. Un éperon de roche, un fût octogonal en cinq étages qui
## rétrécissent (corniches, encorbellements, meurtrières allumées, porte), une lanterne à arcades,
## une flèche d'ardoise bleue, un mât doré et un grand étendard qui flotte ; quelques oiseaux
## tournent autour. Éclairée par le soleil de la carte : face sud et est claires, ombre bleutée
## de l'autre côté. Rien n'est solide. Documentation : docs/FORMAT_DONNEES.md.

const MeshKit = preload("res://src/gfx/mesh_kit.gd")
const Gouda = preload("res://src/gfx/gouda_painter.gd")
const STANDARD_SHADER = preload("res://src/gfx/shaders/tour_etendard.gdshader")
const BIRD_SHADER = preload("res://src/gfx/shaders/tour_oiseau.gdshader")

static var _std_tex: ImageTexture = null
static var _bird_tex: ImageTexture = null


## Champs : `x`, `z` (centre), `base` (hauteur du pied de l'éperon, négative : sous le niveau de la
## carte), `height` (hauteur de la pointe au-dessus du niveau 0), `scale` (1), `flag` (1 : étendard),
## `birds` (nombre d'oiseaux, 6).
static func build(parent: Node3D, tex_stone: Texture2D, tex_slate: Texture2D, tex_rock: Texture2D, o: Dictionary) -> Node3D:
	var root := Node3D.new()
	root.name = "TourBlanche"
	root.position = Vector3(float(o.get("x", 18.0)), 0.0, float(o.get("z", -12.0)))
	parent.add_child(root)
	var sc := float(o.get("scale", 1.0))
	var base := float(o.get("base", -4.0))
	var top := float(o.get("height", 40.0))
	var walls := MeshKit.begin()
	var trims := MeshKit.begin()
	var roofs := MeshKit.begin()
	var rock := MeshKit.begin()
	var glass := MeshKit.begin()
	var dark := MeshKit.begin()
	var gold := MeshKit.begin()
	# proportions : l'éperon porte le fût, la lanterne et la flèche (fractions de la hauteur utile)
	var span := top - base
	var spur_h := span * 0.26
	var shaft_h := span * 0.46
	var lantern_h := span * 0.065
	var spire_h := span * 0.2
	var y := base
	var r0 := 4.2 * sc
	_spur(rock, y, y + spur_h, r0 * 2.4, r0 * 1.15)
	y += spur_h
	# le fût : cinq étages qui rétrécissent
	var radii := [r0, r0 * 0.9, r0 * 0.8, r0 * 0.71, r0 * 0.63]
	var shares := [0.27, 0.23, 0.2, 0.17, 0.13]
	for s in 5:
		var rb: float = radii[s]
		var rt: float = radii[s] * 0.97
		var h: float = shaft_h * float(shares[s])
		_prism(walls, 0.0, 0.0, rb, rt, y, y + h, 8, 22.5, 3.0)
		# corniche saillante au sommet de l'étage, et pied plus large
		_prism(trims, 0.0, 0.0, rt + 0.3 * sc, rt + 0.3 * sc, y + h - 0.2 * sc, y + h + 0.16 * sc, 8, 22.5, 1.0)
		_prism(trims, 0.0, 0.0, rb + 0.16 * sc, rb + 0.16 * sc, y, y + 0.34 * sc, 8, 22.5, 1.0)
		# encorbellements sur trois faces, un étage sur deux : dalle, consoles, garde-corps
		var ap := rt * 0.924
		if s % 2 == 1 or s == 0:
			for fi in [0, 1, 3]:
				var dirv := Vector3(cos(deg_to_rad(90.0 * fi)), 0.0, sin(deg_to_rad(90.0 * fi)))
				var by := y + h * 0.42
				_slab(trims, dirv, ap + 0.55 * sc, by, 1.9 * sc, 1.1 * sc, 0.26 * sc)
				_slab(trims, dirv, ap + 0.12 * sc, by - 0.45 * sc, 0.5 * sc, 0.3 * sc, 0.6 * sc)
				_slab(walls, dirv, ap + 1.05 * sc, by + 0.4 * sc, 1.9 * sc, 0.12 * sc, 0.55 * sc)
				_slab(dark, dirv, ap + 0.06 * sc, by + 1.15 * sc, 0.5 * sc, 0.06 * sc, 1.2 * sc)
		# meurtrières : fente sombre, lueur chaude dedans, sur les quatre faces cardinales
		for fi in 4:
			var dirv := Vector3(cos(deg_to_rad(90.0 * fi)), 0.0, sin(deg_to_rad(90.0 * fi)))
			var n := 2 if fi == 2 or s < 2 else 1
			for k in n:
				var off := (float(k) - float(n - 1) * 0.5) * 1.5 * sc
				var wy := y + h * 0.7
				_slab(dark, dirv, ap + 0.03 * sc, wy, 0.46 * sc, 0.05 * sc, 1.5 * sc, off)
				_slab(glass, dirv, ap + 0.06 * sc, wy - 0.15 * sc, 0.26 * sc, 0.04 * sc, 0.9 * sc, off)
		y += h
	# porte au pied du fût (face sud) : arc sombre
	_slab(dark, Vector3(0, 0, 1), r0 * 0.924 + 0.05, spur_h * 0.0 + base + spur_h + 1.2 * sc, 1.5 * sc, 0.06 * sc, 2.4 * sc)
	# lanterne à arcades : fût étroit, quatre grandes ouvertures, balustrade
	var rl: float = float(radii[4]) * 0.82
	_prism(trims, 0.0, 0.0, rl + 0.5 * sc, rl + 0.5 * sc, y, y + 0.3 * sc, 8, 22.5, 1.0)
	_prism(walls, 0.0, 0.0, rl, rl, y + 0.3 * sc, y + lantern_h, 8, 22.5, 3.0)
	for fi in 4:
		var dirv := Vector3(cos(deg_to_rad(90.0 * fi)), 0.0, sin(deg_to_rad(90.0 * fi)))
		_slab(dark, dirv, rl * 0.924 + 0.04, y + lantern_h * 0.58, 1.3 * sc, 0.05 * sc, lantern_h * 0.55)
		_slab(glass, dirv, rl * 0.924 + 0.07, y + lantern_h * 0.5, 0.7 * sc, 0.04 * sc, lantern_h * 0.3)
	y += lantern_h
	_prism(trims, 0.0, 0.0, rl + 0.45 * sc, rl + 0.45 * sc, y - 0.1 * sc, y + 0.28 * sc, 8, 22.5, 1.0)
	# la flèche : une base évasée peu pentue, puis la pointe, en ardoise
	var rs: float = rl + 0.45 * sc
	var knee := y + spire_h * 0.18
	_cone(roofs, rs + 0.5 * sc, rs * 0.86, y + 0.22 * sc, knee, 8, 22.5)
	var apex := y + spire_h
	_cone(roofs, rs * 0.86, 0.0, knee, apex, 8, 22.5)
	# mât doré, boule, étendard
	var mast_h := span * 0.09
	_prism(gold, 0.0, 0.0, 0.1 * sc, 0.08 * sc, apex - 0.4 * sc, apex + mast_h, 4, 45.0, 1.0)
	_prism(gold, 0.0, 0.0, 0.34 * sc, 0.34 * sc, apex - 0.1 * sc, apex + 0.5 * sc, 8, 22.5, 1.0)
	var stone := MeshKit.pixel_material(tex_stone)
	stone.albedo_color = Color(1.22, 1.18, 1.1)   # pierre plus blanche que le fond de la ville : la Tour doit se détacher
	var slate := MeshKit.pixel_material(tex_slate)
	slate.cull_mode = BaseMaterial3D.CULL_DISABLED
	var rockm := MeshKit.pixel_material(tex_rock)
	var lit := MeshKit.flat_material(Color("#f6d68a"), 1.5)
	var inky := MeshKit.flat_material(Color("#1c2234"))
	var goldm := MeshKit.flat_material(Color("#e8c050"), 0.25)
	for pair: Array in [[walls, stone], [trims, stone], [roofs, slate], [rock, rockm], [glass, lit], [dark, inky], [gold, goldm]]:
		var node := MeshKit.finish(pair[0], pair[1], false)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(node)
	if int(o.get("flag", 1)) > 0:
		_flag(root, Vector3(0.0, apex + mast_h * 0.95, 0.0), span * 0.12)
	_birds(root, int(o.get("birds", 6)), Vector3(0.0, base + span * 0.7, 0.0), span)
	return root


## Prisme (ou tronc de pyramide) à `sides` faces, face centrée sur chaque direction cardinale quand
## `rot` vaut 22,5° pour huit faces. `tile` : répétitions de la texture par unité de largeur.
static func _prism(st: SurfaceTool, cx: float, cz: float, rb: float, rt: float, y0: float, y1: float, sides: int, rot: float, _tile: float) -> void:
	var step := TAU / float(sides)
	var h := y1 - y0
	for i in sides:
		var am := deg_to_rad(rot) + step * float(i) - step * 0.5
		var al := am + step   # côté gauche vu de l'extérieur : angle plus grand
		var ar := am
		var tl := Vector3(cx + cos(al) * rt, y1, cz + sin(al) * rt)
		var tr := Vector3(cx + cos(ar) * rt, y1, cz + sin(ar) * rt)
		var br := Vector3(cx + cos(ar) * rb, y0, cz + sin(ar) * rb)
		var bl := Vector3(cx + cos(al) * rb, y0, cz + sin(al) * rb)
		var wdt := tl.distance_to(tr)
		MeshKit.quad(st, tl, tr, br, bl, Vector2.ZERO, Vector2(wdt / MeshKit.TEX_UNITS, h / MeshKit.TEX_UNITS))
	# dessus (pour les corniches et les dalles)
	if absf(h) < 0.6:
		for i in sides:
			var a0 := deg_to_rad(rot) + step * float(i) - step * 0.5
			var a1 := a0 + step
			var c := Vector3(cx, y1, cz)
			var p0 := Vector3(cx + cos(a0) * rt, y1, cz + sin(a0) * rt)
			var p1 := Vector3(cx + cos(a1) * rt, y1, cz + sin(a1) * rt)
			MeshKit.tri(st, c, p1, p0, Vector2(0.5, 0.5), Vector2(1, 0), Vector2(0, 0))


## Cône (ou tronc) à `sides` faces pour la flèche.
static func _cone(st: SurfaceTool, rb: float, rt: float, y0: float, y1: float, sides: int, rot: float) -> void:
	var step := TAU / float(sides)
	for i in sides:
		var ar := deg_to_rad(rot) + step * float(i) - step * 0.5
		var al := ar + step
		var bl := Vector3(cos(al) * rb, y0, sin(al) * rb)
		var br := Vector3(cos(ar) * rb, y0, sin(ar) * rb)
		var tl := Vector3(cos(al) * rt, y1, sin(al) * rt)
		var tr := Vector3(cos(ar) * rt, y1, sin(ar) * rt)
		var u := bl.distance_to(br) / MeshKit.TEX_UNITS
		var v := (y1 - y0) / MeshKit.TEX_UNITS * 1.6
		if rt <= 0.001:
			MeshKit.tri(st, Vector3(0, y1, 0), br, bl, Vector2(u * 0.5, 0), Vector2(u, v), Vector2(0, v))
		else:
			MeshKit.quad(st, tl, tr, br, bl, Vector2.ZERO, Vector2(u, v))


## Dalle (boîte plate) collée à une face : `dirv` la direction cardinale, `dist` la distance de son
## centre à l'axe, `y` sa hauteur, `wide` sa largeur le long de la face, `deep` sa saillie, `tall` sa hauteur.
static func _slab(st: SurfaceTool, dirv: Vector3, dist: float, y: float, wide: float, deep: float, tall: float, along: float = 0.0) -> void:
	var tang := Vector3(-dirv.z, 0.0, dirv.x)
	var c := dirv * dist + tang * along + Vector3(0.0, y, 0.0)
	# boîte alignée sur les axes : les largeurs x et z se permutent selon la face
	var sx := deep if absf(dirv.x) > 0.5 else wide
	var sz := deep if absf(dirv.z) > 0.5 else wide
	MeshKit.box(st, c, Vector3(sx, tall, sz))


## Éperon de roche : des anneaux irréguliers superposés, du large pied au col étroit.
static func _spur(st: SurfaceTool, y0: float, y1: float, rb: float, rt: float) -> void:
	var rings := 6
	var sides := 9
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var prev: Array = []
	for r in rings + 1:
		var t := float(r) / float(rings)
		var rad := lerpf(rb, rt, pow(t, 0.7))
		var y := lerpf(y0, y1, t)
		var ring: Array = []
		for i in sides:
			var a := TAU * float(i) / float(sides) + (0.2 if r % 2 == 0 else -0.1)
			var jr := rad * (1.0 + rng.randf_range(-0.14, 0.14)) if r > 0 and r < rings else rad
			ring.append(Vector3(cos(a) * jr, y + rng.randf_range(-0.5, 0.5) * (1.0 if r < rings else 0.0), sin(a) * jr))
		if r > 0:
			for i in sides:
				var j := (i + 1) % sides
				var bl: Vector3 = prev[i]
				var br: Vector3 = prev[j]
				var tl: Vector3 = ring[i]
				var tr: Vector3 = ring[j]
				# vu de l'extérieur, i est à droite de j (angle croissant = vers la gauche)
				MeshKit.quad(st, tr, tl, bl, br, Vector2(float(i) * 0.9, (1.0 - t) * 4.0), Vector2(float(i) * 0.9 + 0.9, (1.0 - t) * 4.0 + 1.0))
		prev = ring
	# dessus plein sous le fût
	var c := Vector3(0, y1, 0)
	for i in sides:
		var j := (i + 1) % sides
		MeshKit.tri(st, c, prev[j], prev[i], Vector2(0.5, 0.5), Vector2(1, 0), Vector2(0, 0))


static func _standard_texture() -> ImageTexture:
	if _std_tex == null:
		_std_tex = ImageTexture.create_from_image(Gouda.paint_standard())
	return _std_tex


static func _flag(root: Node3D, at: Vector3, size: float) -> void:
	var w := size * 1.7
	var segs := 16
	var st := MeshKit.begin()
	for i in segs:
		var u0 := float(i) / float(segs)
		var u1 := float(i + 1) / float(segs)
		MeshKit.quad(st, Vector3(w * u0, size * 0.5, 0), Vector3(w * u1, size * 0.5, 0), Vector3(w * u1, -size * 0.5, 0), Vector3(w * u0, -size * 0.5, 0), Vector2(u0, 0), Vector2(u1, 1))
	var mat := ShaderMaterial.new()
	mat.shader = STANDARD_SHADER
	mat.set_shader_parameter("tex", _standard_texture())
	mat.set_shader_parameter("amp", size * 0.14)
	var node := MeshKit.finish(st, mat, false)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.position = at + Vector3(0.12, -size * 0.55, 0.0)
	node.name = "Etendard"
	root.add_child(node)


static func _bird_texture() -> ImageTexture:
	if _bird_tex == null:
		var img := Image.create(16, 6, false, Image.FORMAT_RGBA8)
		img.fill(Color(0, 0, 0, 0))
		var ink := Color("#3a3f52")
		for x in 16:
			var d := absf(float(x) - 7.5)
			var y := 2 - int(d * 0.3) + (1 if d > 4.0 else 0)
			if d < 1.6:
				y = 3
			img.set_pixel(x, clampi(y, 0, 5), ink)
			if d < 5.0:
				img.set_pixel(x, clampi(y + 1, 0, 5), ink)
		_bird_tex = ImageTexture.create_from_image(img)
	return _bird_tex


static func _birds(root: Node3D, n: int, around: Vector3, span: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var holder := Node3D.new()
	holder.name = "Oiseaux"
	holder.position = around
	root.add_child(holder)
	for i in n:
		var q := QuadMesh.new()
		var sz := span * 0.028
		q.size = Vector2(sz, sz * 0.375)
		q.subdivide_width = 6
		var mat := ShaderMaterial.new()
		mat.shader = BIRD_SHADER
		mat.set_shader_parameter("tex", _bird_texture())
		mat.set_shader_parameter("radius", span * rng.randf_range(0.25, 0.5))
		mat.set_shader_parameter("rate", rng.randf_range(0.12, 0.3))
		mat.set_shader_parameter("phase", rng.randf_range(0.0, TAU))
		mat.set_shader_parameter("flap", rng.randf_range(5.0, 9.0))
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = Vector3(rng.randf_range(-span * 0.1, span * 0.1), rng.randf_range(-span * 0.18, span * 0.2), span * 0.2 + rng.randf_range(0.0, span * 0.2))
		holder.add_child(mi)
