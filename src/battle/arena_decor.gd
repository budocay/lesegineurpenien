extends RefCounted
## Décor 3D d'une arène de combat : paroi de roche irrégulière (décrochements, hauteurs
## variées, lèvre de gazon au sommet, ombre au pied), lointain peint, mares, coulées de
## lave, façades de maisons. Piloté par data/arenas.json (voir docs/FORMAT_DONNEES.md).
## Rien ici ne touche aux combattants : tout est posé derrière z = -8 ou sur les bords.

const MeshKit = preload("res://src/gfx/mesh_kit.gd")
const PA = preload("res://src/gfx/pixel_art.gd")
const TilePainter = preload("res://src/gfx/tile_painter.gd")
const HorizonPainter = preload("res://src/gfx/horizon_painter.gd")
const ROCK_SHADER = preload("res://src/gfx/shaders/rock.gdshader")
const WATER_SHADER = preload("res://src/gfx/shaders/water.gdshader")
const LAVA_SHADER = preload("res://src/gfx/shaders/lava.gdshader")
const ARENA_GROUND_SHADER = preload("res://src/gfx/shaders/arena_ground.gdshader")

const HALF := 40.0     # demi-largeur de la paroi
const DEPTH := 15.0    # épaisseur des blocs (on ne voit jamais l'arrière)

var segments: Array[Dictionary] = []   # {x0, x1, zf, h} : un bloc de paroi
var _rng := RandomNumberGenerator.new()
var _shadow_tex: Texture2D
var _dim := 0.6          # le fond est repoussé : plus sombre,
var _desat := 0.35       # moins saturé
var _haze := 0.2         # et légèrement estompé par la brume
var _haze_color := Color("#3a3450")


func _init(seed_value: int = 1) -> void:
	_rng.seed = seed_value


## Hauteur de la paroi en ce point (0 devant elle) : les décors y sont posés.
func height_at(x: float, z: float) -> float:
	var y := 0.0
	for s: Dictionary in segments:
		if x >= float(s["x0"]) and x <= float(s["x1"]) and z < float(s["zf"]):
			y = maxf(y, float(s["h"]))
	return y


func build(parent: Node3D, arena: Dictionary) -> void:
	var back: Variant = arena.get("backdrop", {})
	if not (back is Dictionary) or (back as Dictionary).is_empty():
		return
	var bd: Dictionary = back
	_dim = float(bd.get("dim", 0.6))
	_desat = float(bd.get("desat", 0.35))
	_haze = float(bd.get("haze", 0.2))
	var sky: Array = bd.get("sky", ["#1c1a36", "#4a3f6e"])
	_haze_color = Color.from_string(str(sky[sky.size() - 1]), Color("#4a3f6e")).darkened(0.45)
	_horizon(parent, bd)
	_wall(parent, bd, str(arena.get("ground", "grass")))
	for f: Variant in arena.get("features", []):
		if f is Dictionary:
			_feature(parent, f)


# ------------------------------------------------------------------ lointain

func _horizon(parent: Node3D, bd: Dictionary) -> void:
	var far := str(bd.get("far", ""))
	if far == "":
		return
	var sky: Array = bd.get("sky", ["#1c1a36", "#4a3f6e"])
	var top := Color.from_string(str(sky[0]), Color("#1c1a36"))
	var bottom := Color.from_string(str(sky[1]), Color("#4a3f6e"))
	var img := HorizonPainter.paint(far, top, bottom, hash(far) & 0xffff)
	var tex := ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = Color(_dim, _dim, _dim)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	var q := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	var width := 110.0
	mesh.size = Vector2(width, width * float(HorizonPainter.H) / float(HorizonPainter.W))
	q.mesh = mesh
	q.material_override = m
	q.position = Vector3(0.0, mesh.size.y * 0.5 - 4.0, -38.0)
	q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	q.name = "Horizon"
	parent.add_child(q)


# --------------------------------------------------------------------- paroi

func _vquad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, uv0: Vector2, uv1: Vector2, ca: Color, cb: Color, cc: Color, cd: Color) -> void:
	var n := (d - a).cross(b - a).normalized()
	var v: Array[Vector3] = [a, b, c, d]
	var uv: Array[Vector2] = [uv0, Vector2(uv1.x, uv0.y), uv1, Vector2(uv0.x, uv1.y)]
	var col: Array[Color] = [ca, cb, cc, cd]
	for i: int in [0, 1, 2, 0, 2, 3]:
		st.set_normal(n)
		st.set_uv(uv[i])
		st.set_color(col[i])
		st.add_vertex(v[i])


func _gradient_texture() -> Texture2D:
	if _shadow_tex == null:
		var img := PA.new_image(2, 32)
		for y in 32:
			var t := float(y) / 31.0
			var a := 0.62 * pow(1.0 - t, 1.6)
			for x in 2:
				img.set_pixel(x, y, Color(0.04, 0.02, 0.1, a))
		_shadow_tex = ImageTexture.create_from_image(img)
	return _shadow_tex


func _wall(parent: Node3D, bd: Dictionary, ground_tile: String) -> void:
	var face_tile := str(bd.get("tile", "rock_face"))
	var top_tile := str(bd.get("top", ground_tile))
	var steps: Array = bd.get("steps", [[-9.0, 1.5], [-13.0, 3.2]])
	var jitter := float(bd.get("jitter", 1.0))
	segments.clear()
	var faces := MeshKit.begin()
	var tops := MeshKit.begin()
	var lips := MeshKit.begin()
	var drips := MeshKit.begin()
	var shades := MeshKit.begin()
	var tu := float(Sprites.tile_image(face_tile).get_width()) / 24.0   # unités couvertes par la texture
	var top_img: Image = Sprites.tile_image(top_tile)
	var avg := Color(0, 0, 0)
	for i in 24:
		avg += top_img.get_pixel((i * 7) % top_img.get_width(), (i * 13) % top_img.get_height())
	avg = avg / 24.0
	var lip_col := avg.lightened(0.12)
	var layer_index := 0
	for s: Variant in steps:
		if not (s is Array) or (s as Array).size() < 2:
			continue
		var edge := float(s[0])
		var hgt := float(s[1])
		var x := -HALF
		var prev_h := hgt
		while x < HALF:
			var wd := _rng.randf_range(2.4, 6.2)
			var x1 := minf(x + wd, HALF)
			# hauteur par paliers : décrochements nets entre voisins
			var hh := snappedf(hgt * (1.0 + _rng.randf_range(-0.2, 0.18) * jitter), 0.1)
			if absf(hh - prev_h) < 0.15:
				hh = prev_h + (0.3 if _rng.randf() < 0.5 else -0.3) * jitter
			prev_h = hh
			var zf := edge + _rng.randf_range(-0.6, 0.9) * jitter
			segments.append({"x0": x, "x1": x1, "zf": zf, "h": hh, "layer": layer_index})
			var tone := 1.0 + _rng.randf_range(-0.07, 0.07)
			var top_c := Color(1.06, 1.04, 1.0) * tone
			var mid_c := Color(0.88, 0.86, 0.9) * tone
			var foot_c := Color(0.42, 0.38, 0.52) * tone
			var z0 := zf - DEPTH
			# face avant : v part du sommet, la texture se répète au mur
			_vquad(faces, Vector3(x, hh, zf), Vector3(x1, hh, zf), Vector3(x1, 0.0, zf), Vector3(x, 0.0, zf),
					Vector2(x / tu, 0.0), Vector2(x1 / tu, hh / tu), top_c, top_c, foot_c, foot_c)
			# milieu un peu plus clair : on rajoute un ton intermédiaire via les côtés
			# flancs (visibles aux décrochements)
			_vquad(faces, Vector3(x, hh, z0), Vector3(x, hh, zf), Vector3(x, 0.0, zf), Vector3(x, 0.0, z0),
					Vector2(0.0, 0.0), Vector2(DEPTH / tu, hh / tu), mid_c, mid_c, foot_c, foot_c)
			_vquad(faces, Vector3(x1, hh, zf), Vector3(x1, hh, z0), Vector3(x1, 0.0, z0), Vector3(x1, 0.0, zf),
					Vector2(0.0, 0.0), Vector2(DEPTH / tu, hh / tu), mid_c, mid_c, foot_c, foot_c)
			# dessus
			MeshKit.quad(tops, Vector3(x, hh, z0), Vector3(x1, hh, z0), Vector3(x1, hh, zf), Vector3(x, hh, zf),
					Vector2(x / 2.0, z0 / 2.0), Vector2(x1 / 2.0, zf / 2.0))
			# lèvre au sommet : touffes de gazon (ou liseré clair) qui débordent
			var lx := x
			while lx < x1 - 0.2:
				var lw := _rng.randf_range(0.35, 1.1)
				lw = minf(lw, x1 - lx)
				var ld := _rng.randf_range(0.14, 0.34)
				var lh := _rng.randf_range(0.1, 0.24)
				MeshKit.box(lips, Vector3(lx + lw * 0.5, hh - lh * 0.5 + 0.03, zf + ld * 0.5 - 0.02), Vector3(lw, lh, ld))
				if _rng.randf() < 0.6:
					MeshKit.box(drips, Vector3(lx + lw * 0.5, hh - lh - 0.07, zf + 0.03), Vector3(lw * 0.9, 0.14, 0.08))
				lx += lw + _rng.randf_range(0.0, 0.25)
			# ombre au pied, posée sur ce qui est devant (sol ou gradin inférieur)
			var below := 0.0
			for q: Dictionary in segments:
				if int(q["layer"]) < layer_index and float(q["x1"]) > x and float(q["x0"]) < x1:
					below = maxf(below, float(q["h"]))
			var sz := 2.4 if layer_index == 0 else 1.8
			_shadow_quad(shades, x - 0.2, x1 + 0.2, zf, sz, below + 0.03)
			x = x1
		layer_index += 1

	var wall_mat := ShaderMaterial.new()
	wall_mat.shader = ROCK_SHADER
	wall_mat.set_shader_parameter("tex", Sprites.tile_texture(face_tile))
	wall_mat.set_shader_parameter("dim", _dim)
	wall_mat.set_shader_parameter("desat", _desat)
	wall_mat.set_shader_parameter("haze", _haze)
	wall_mat.set_shader_parameter("haze_color", _haze_color)
	var wall := MeshKit.finish(faces, wall_mat, true)
	wall.name = "Backdrop"
	parent.add_child(wall)
	var top_mat := ShaderMaterial.new()
	top_mat.shader = ARENA_GROUND_SHADER
	top_mat.set_shader_parameter("tex", Sprites.tile_texture(top_tile))
	top_mat.set_shader_parameter("uv_scale", Vector2.ONE)
	top_mat.set_shader_parameter("base", avg)
	top_mat.set_shader_parameter("flatten", 0.5)
	top_mat.set_shader_parameter("edge", 1.0)
	top_mat.set_shader_parameter("pool_boost", 0.0)
	top_mat.set_shader_parameter("pool_color", Color.WHITE)
	top_mat.set_shader_parameter("dim", _dim)
	top_mat.set_shader_parameter("desat", _desat)
	var top := MeshKit.finish(tops, top_mat, true)
	top.name = "BackdropTop"
	parent.add_child(top)
	var lip := MeshKit.finish(lips, MeshKit.flat_material(lip_col.lerp(Color(lip_col.get_luminance(), lip_col.get_luminance(), lip_col.get_luminance()), _desat) * _dim), false)
	lip.name = "BackdropLip"
	parent.add_child(lip)
	var drip_col := Color.from_string(str(bd.get("shadow", "#3a3340")), Color("#3a3340"))
	parent.add_child(MeshKit.finish(drips, MeshKit.flat_material(drip_col), false))
	var sm := StandardMaterial3D.new()
	sm.albedo_texture = _gradient_texture()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.cull_mode = BaseMaterial3D.CULL_DISABLED
	var shade := MeshKit.finish(shades, sm, false)
	shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shade.name = "BackdropShade"
	parent.add_child(shade)


func _shadow_quad(st: SurfaceTool, x0: float, x1: float, zf: float, size: float, y: float) -> void:
	MeshKit.quad(st, Vector3(x0, y, zf), Vector3(x1, y, zf), Vector3(x1, y, zf + size), Vector3(x0, y, zf + size))


# ----------------------------------------------------------- éléments au sol

func _feature(parent: Node3D, f: Dictionary) -> void:
	match str(f.get("kind", "")):
		"pool":
			_pool(parent, f)
		"houses":
			_houses(parent, f)


## Mare, étang ou coulée de lave : un contour irrégulier rempli par un shader.
func _pool(parent: Node3D, f: Dictionary) -> void:
	var c: Array = f.get("pos", [0.0, -6.0])
	var size: Array = f.get("size", [4.0, 2.0])
	var cx := float(c[0])
	var cz := float(c[1])
	var rx := float(size[0]) * 0.5
	var rz := float(size[1]) * 0.5
	var material := str(f.get("material", "water"))
	var n := 28
	var ring: Array[Vector2] = []
	var phase := _rng.randf() * TAU
	for i in n:
		var a := float(i) / float(n) * TAU
		var k := 1.0 + 0.16 * sin(a * 3.0 + phase) + 0.09 * sin(a * 5.0 + phase * 2.0) + _rng.randf_range(-0.04, 0.04)
		ring.append(Vector2(cx + cos(a) * rx * k, cz + sin(a) * rz * k))
	# berge : anneau plus large, sombre
	var bank_col := Color.from_string(str(f.get("bank", "#2a2420")), Color("#2a2420"))
	if bank_col.a > 0.0:
		var bank := MeshKit.begin()
		for i in n:
			var p0 := ring[i]
			var p1 := ring[(i + 1) % n]
			var o0 := Vector2(cx, cz) + (p0 - Vector2(cx, cz)) * 1.22
			var o1 := Vector2(cx, cz) + (p1 - Vector2(cx, cz)) * 1.22
			MeshKit.tri(bank, Vector3(cx, 0.015, cz), Vector3(o0.x, 0.015, o0.y), Vector3(o1.x, 0.015, o1.y), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
		var bn := MeshKit.finish(bank, MeshKit.flat_material(bank_col), false)
		bn.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(bn)
	var st := MeshKit.begin()
	for i in n:
		var p0 := ring[i]
		var p1 := ring[(i + 1) % n]
		MeshKit.tri(st, Vector3(cx, 0.03, cz), Vector3(p0.x, 0.03, p0.y), Vector3(p1.x, 0.03, p1.y), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
	var mat := ShaderMaterial.new()
	if material == "lava":
		mat.shader = LAVA_SHADER
		mat.set_shader_parameter("energy", float(f.get("energy", 1.3)))
	else:
		mat.shader = WATER_SHADER
		if material == "swamp":
			mat.set_shader_parameter("deep", Color("#1d3a3a"))
			mat.set_shader_parameter("shallow", Color("#43705f"))
			mat.set_shader_parameter("ripple", Color("#a4cdb0"))
			mat.set_shader_parameter("glint", Color("#ffe6b0"))
		elif material == "mud":
			mat.set_shader_parameter("deep", Color("#2a2418"))
			mat.set_shader_parameter("shallow", Color("#4a4230"))
			mat.set_shader_parameter("ripple", Color("#7a7050"))
	var node := MeshKit.finish(st, mat, false)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.name = "Pool"
	parent.add_child(node)
	if material == "lava" and bool(f.get("light", true)):
		var l := OmniLight3D.new()
		l.light_color = Color("#ff7a30")
		l.light_energy = float(f.get("light_energy", 1.8))
		l.omni_range = maxf(rx, rz) * 3.0 + 3.0
		l.position = Vector3(cx, 0.6, cz + 0.5)
		parent.add_child(l)


## Façades de maisons derrière la paroi (arène de la place).
func _houses(parent: Node3D, f: Dictionary) -> void:
	for h: Variant in f.get("list", []):
		if not (h is Dictionary):
			continue
		var x := float((h as Dictionary).get("x", 0.0))
		var z := float((h as Dictionary).get("z", -16.0))
		var hw := float(h.get("w", 6.0))
		var hd := float(h.get("d", 5.0))
		var wh := float(h.get("height", 3.0))
		var rh := float(h.get("roof_height", 2.0))
		var roof := str(h.get("roof", "rouge"))
		var base := height_at(x + hw * 0.5, z + hd)
		var x0 := x
		var x1 := x + hw
		var z0 := z
		var z1 := z + hd
		var node := Node3D.new()
		node.position.y = base
		parent.add_child(node)
		var windows: Array = h.get("windows", [hw * 0.25, hw * 0.75])
		var door := float(h.get("door", -1.0))
		var door_col := Color.from_string(str(h.get("door_color", "#8a4a3a")), Color("#8a4a3a"))
		var fr: Dictionary = TilePainter.house_front(hw, wh, door, windows, door_col, true)
		var st := MeshKit.begin()
		MeshKit.quad(st, Vector3(x0, wh, z1), Vector3(x1, wh, z1), Vector3(x1, 0, z1), Vector3(x0, 0, z1))
		node.add_child(MeshKit.finish(st, _far_material(PA.texture(fr["albedo"]), PA.texture(fr["emission"]), 2.2)))
		var side_tex := PA.texture(TilePainter.house_side(hd, wh))
		st = MeshKit.begin()
		MeshKit.quad(st, Vector3(x0, wh, z0), Vector3(x0, wh, z1), Vector3(x0, 0, z1), Vector3(x0, 0, z0))
		MeshKit.quad(st, Vector3(x1, wh, z1), Vector3(x1, wh, z0), Vector3(x1, 0, z0), Vector3(x1, 0, z1))
		node.add_child(MeshKit.finish(st, _far_material(side_tex)))
		var zm := (z0 + z1) * 0.5
		var top := wh + rh
		st = MeshKit.begin()
		MeshKit.tri(st, Vector3(x0, wh, z0), Vector3(x0, top, zm), Vector3(x0, wh, z1), Vector2(0, rh / 2.0), Vector2(hd / 4.0, 0), Vector2(hd / 2.0, rh / 2.0))
		MeshKit.tri(st, Vector3(x1, wh, z1), Vector3(x1, top, zm), Vector3(x1, wh, z0), Vector2(0, rh / 2.0), Vector2(hd / 4.0, 0), Vector2(hd / 2.0, rh / 2.0))
		node.add_child(MeshKit.finish(st, _far_material(Sprites.tile_texture("plaster"))))
		var ov := 0.4
		var os := 0.3
		var slope := rh / (hd * 0.5)
		var ye := wh - slope * ov
		var slen := Vector2(hd * 0.5 + ov, rh + slope * ov).length()
		var uv1 := Vector2((hw + 2.0 * os) / 2.0, slen / 2.0)
		st = MeshKit.begin()
		MeshKit.quad(st, Vector3(x0 - os, top, zm), Vector3(x1 + os, top, zm), Vector3(x1 + os, ye, z1 + ov), Vector3(x0 - os, ye, z1 + ov), Vector2.ZERO, uv1)
		MeshKit.quad(st, Vector3(x1 + os, top, zm), Vector3(x0 - os, top, zm), Vector3(x0 - os, ye, z0 - ov), Vector3(x1 + os, ye, z0 - ov), Vector2.ZERO, uv1)
		node.add_child(MeshKit.finish(st, _far_material(Sprites.tile_texture("roof_" + roof))))
		# cheminée
		if bool(h.get("chimney", true)):
			st = MeshKit.begin()
			MeshKit.box(st, Vector3(x0 + hw * 0.72, top - 0.2, zm - 0.3), Vector3(0.6, 1.4, 0.6))
			node.add_child(MeshKit.finish(st, _far_material(Sprites.tile_texture("brick"))))


## Matériau d'un décor lointain (façades) : assombri comme la paroi.
func _far_material(tex: Texture2D, emission_tex: Texture2D = null, emission_energy: float = 2.0) -> StandardMaterial3D:
	var m := MeshKit.pixel_material(tex, emission_tex, emission_energy)
	var k := lerpf(1.0, _dim, 0.9)
	m.albedo_color = Color(k, k, k)
	return m
