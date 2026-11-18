extends RefCounted
## Style d'architecture « elfe » (champ `style: "elfe"` d'une carte ou d'une maison).
## Rien ici ne s'applique à une carte sans ce champ : les chapitres 1 et 2 sont intacts.
##
## Le constructeur de cartes (MapBuilder) délègue ici :
##  - `restyle(b)` : après le sol, retouche l'aspect de la carte (parois, eau, talus, murs
##    d'intérieur) et bâtit la vallée du fond ;
##  - `house(b, o)` : un pavillon à la place d'une maison de village ;
##  - `object(b, type, o)` : les objets propres au style (rampes, lanternes, cascades...).
## Documentation : docs/FORMAT_DONNEES.md, section « Styles d'architecture ».

const PA = preload("res://src/gfx/pixel_art.gd")
const MeshKit = preload("res://src/gfx/mesh_kit.gd")
const TilePainter = preload("res://src/gfx/tile_painter.gd")
const Elven = preload("res://src/gfx/elven_painter.gd")
const Atmosphere = preload("res://src/world/atmosphere.gd")
const WATER_SHADER = preload("res://src/gfx/shaders/water.gdshader")
const FALL_SHADER = preload("res://src/gfx/shaders/waterfall.gdshader")

## Types d'objets que `object()` sait construire.
const OBJECTS: Array[String] = ["elf_rail", "elf_lantern", "elf_column3d", "elf_arcade", "elf_gate", "elf_waterfall",
		"elf_counter", "elf_medallion", "elf_pool"]

const PALE := Color("#ece4cf")
const GOLD := Color("#d8b862")
const LANTERN_GLOW := Color("#bcd8ff")


static func style_of(b, o: Dictionary = {}) -> String:
	return str(o.get("style", b.map.get("style", "")))


static func is_elven(b) -> bool:
	return str(b.map.get("style", "")) == "elfe"


# ===================================================================== retouche

## Appelé par MapBuilder.build() une fois le sol, l'eau et le relief bâtis.
static func restyle(b) -> void:
	if bool(b.map.get("interior", false)):
		_restyle_interior(b)
	else:
		_restyle_exterior(b)


static func _node(b, node_name: String) -> MeshInstance3D:
	return b.world.get_node_or_null(node_name) as MeshInstance3D


static func _restyle_interior(b) -> void:
	var walls := _node(b, "Walls")
	if walls != null:
		var tile := str(b.map.get("wall_tile", "elf_wall"))
		var tex: Texture2D = Sprites.tile_texture(tile)
		var m := MeshKit.pixel_material(tex)
		m.emission_enabled = true
		m.emission = Color.WHITE
		m.emission_operator = BaseMaterial3D.EMISSION_OP_ADD
		m.emission_texture = tex
		m.emission_energy_multiplier = float(b.map.get("wall_glow", 0.3))
		walls.material_override = m
	var caps := _node(b, "WallCaps")
	if caps != null:
		caps.material_override = MeshKit.flat_material(Color(str(b.map.get("wall_cap", "#a9a493"))))


static func _restyle_exterior(b) -> void:
	var wl := _node(b, "ReliefWalls")
	if wl != null:
		wl.material_override = MeshKit.pixel_material(Sprites.tile_texture("elf_terrace"))
	var st := _node(b, "ReliefStairs")
	if st != null:
		st.material_override = MeshKit.pixel_material(Sprites.tile_texture("elf_steps"))
	var outer := _node(b, "Outskirts")
	if outer != null:
		outer.material_override = MeshKit.ground_material(Sprites.tile_texture("elf_lawn"))
	var water := _node(b, "Water")
	if water != null:
		var wm := water.material_override as ShaderMaterial
		if wm != null:
			var spec: Dictionary = b.map.get("water", {})
			wm.set_shader_parameter("deep", Color(str(spec.get("deep", "#1f6f86"))))
			wm.set_shader_parameter("shallow", Color(str(spec.get("shallow", "#5cc0c0"))))
			wm.set_shader_parameter("ripple", Color(str(spec.get("ripple", "#e6faf4"))))
			wm.set_shader_parameter("glint", Color(str(spec.get("glint", "#fff0c0"))))
	var cliffs := _node(b, "Cliffs")
	var spec_v: Variant = b.map.get("valley", {})
	var vspec: Dictionary = spec_v if spec_v is Dictionary else {}
	if bool(vspec.get("enabled", true)):
		if cliffs != null:
			cliffs.visible = false
		_valley(b, vspec)
	else:
		if cliffs != null:
			cliffs.material_override = MeshKit.ground_material(Sprites.tile_texture("elf_cliff"), 0.1)
	_side_forest(b, vspec)


## Étages boisés au nord, chacun avec sa paroi de roche claire, ses arbres d'automne et,
## là où `falls` le demande, ses cascades qui retombent d'étage en étage.
static func _valley(b, spec: Dictionary) -> void:
	var far := 60.0
	var ledges: Array = spec.get("ledges", [[-1.4, 2.4], [-6.4, 4.8], [-11.6, 7.4], [-17.0, 10.0]])
	var rock := MeshKit.begin()
	var tops := MeshKit.begin()
	for i in ledges.size():
		var z: float = float((ledges[i] as Array)[0])
		var top: float = float((ledges[i] as Array)[1])
		var z_back := -far
		if i + 1 < ledges.size():
			z_back = float((ledges[i + 1] as Array)[0])
		MeshKit.box(rock, Vector3(b.w * 0.5, top * 0.5, (z - far) * 0.5), Vector3(b.w + far * 2.0, top, z + far))
		var x0 := -far
		var x1: float = b.w + far
		MeshKit.quad(tops, Vector3(x0, top + 0.02, z_back), Vector3(x1, top + 0.02, z_back), Vector3(x1, top + 0.02, z), Vector3(x0, top + 0.02, z),
				Vector2(x0, z_back) / MeshKit.TEX_UNITS, Vector2(x1, z) / MeshKit.TEX_UNITS)
	var rock_node := MeshKit.finish(rock, MeshKit.ground_material(Sprites.tile_texture("elf_cliff"), 0.1), true)
	rock_node.name = "ValleyRock"
	b.world.add_child(rock_node)
	var top_node := MeshKit.finish(tops, MeshKit.ground_material(Sprites.tile_texture("elf_lawn")), false)
	top_node.name = "ValleyTops"
	b.world.add_child(top_node)
	# arbres : chaque étage plante sa rangée, les conifères sombres sur les plus hauts
	var rng: RandomNumberGenerator = b.rng
	var per := int(spec.get("trees", 20))
	for i in ledges.size():
		var z: float = float((ledges[i] as Array)[0])
		var top: float = float((ledges[i] as Array)[1])
		var z_back := z - 5.0
		if i + 1 < ledges.size():
			z_back = float((ledges[i + 1] as Array)[0])
		for k in per:
			var x := rng.randf_range(-14.0, b.w + 14.0)
			var zz := rng.randf_range(z_back + 1.3, z - 0.9)
			var kind := "elf_tree"
			var v := rng.randi() % 4
			if i >= 2 and rng.randf() < float(spec.get("pine_ratio", 0.45)):
				kind = "elf_pine"
				v = rng.randi() % 2
			b._prop(kind, {"variant": v, "solid": 0.0, "scale": 1.0 + 0.05 * i, "shadow": false}, Vector3(x, top, zz))
	# cascades
	for f: Variant in spec.get("falls", []):
		if f is Dictionary:
			var fx := float((f as Dictionary).get("x", 10.0))
			var hi := int((f as Dictionary).get("from", ledges.size() - 1))
			var lo := int((f as Dictionary).get("to", 0))
			for i in range(lo, hi + 1):
				var z: float = float((ledges[i] as Array)[0])
				var top: float = float((ledges[i] as Array)[1])
				var base := 0.0 if i == 0 else float((ledges[i - 1] as Array)[1])
				_waterfall(b, Vector3(fx, base, z + 0.04), top - base, 2.0, i > 0)


## Rideau d'arbres de chaque côté et au sud de la carte : bouleaux, hêtres dorés, quelques pins.
static func _side_forest(b, spec: Dictionary) -> void:
	var rng: RandomNumberGenerator = b.rng
	var side_z := float(b.h) + 40.0
	for i in 110:
		var left := i % 2 == 0
		var x := rng.randf_range(-16.0, -0.9) if left else rng.randf_range(b.w + 0.9, b.w + 16.0)
		var z := rng.randf_range(-1.0, float(b.h) + 6.0)
		if z > side_z:
			continue
		var v := rng.randi() % 4
		b._prop("elf_tree", {"variant": v, "solid": 0.0, "shadow": false}, Vector3(x, 0.0, z))
	for i in 46:
		var x := rng.randf_range(-6.0, b.w + 6.0)
		var z := rng.randf_range(float(b.h) + 0.7, float(b.h) + 9.0)
		var v := rng.randi() % 4
		b._prop("elf_tree", {"variant": v, "solid": 0.0, "shadow": false}, Vector3(x, 0.0, z))
	for i in 70:
		var left := i % 2 == 0
		var x := rng.randf_range(-12.0, -0.5) if left else rng.randf_range(b.w + 0.5, b.w + 12.0)
		var z := rng.randf_range(0.0, float(b.h) + 6.0)
		var kinds: Array = ["elf_flowers", "fern", "elf_leaves", "bush"]
		b._prop(str(kinds[i % kinds.size()]), {"solid": 0.0, "shadow": false}, Vector3(x, 0.0, z))


# ====================================================================== cascade

## Cascade : quad vertical animé par shader, bassin d'écume au pied, embruns.
## `base` : point au pied de la chute (face de la paroi), `height` : hauteur de la chute.
static func _waterfall(b, base: Vector3, height: float, width: float, pool: bool) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = FALL_SHADER
	mat.set_shader_parameter("size", Vector2(width, height))
	var quad := QuadMesh.new()
	quad.size = Vector2(width, height)
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = base + Vector3(0.0, height * 0.5, 0.0)
	mi.name = "Waterfall"
	mi.set_meta("elven", "waterfall")
	b.world.add_child(mi)
	if pool:
		_pool(b, Rect2(base.x - width * 0.9, base.z, width * 1.8, 1.7), base.y + 0.04)
	var mist := Atmosphere.make_particles("embruns")
	if mist != null:
		mist.position = base + Vector3(0.0, 0.35, 0.5)
		b.world.add_child(mist)


## Bassin d'eau claire à une hauteur donnée.
static func _pool(b, r: Rect2, y: float) -> void:
	var st := MeshKit.begin()
	MeshKit.quad(st, Vector3(r.position.x, y, r.position.y), Vector3(r.end.x, y, r.position.y), Vector3(r.end.x, y, r.end.y), Vector3(r.position.x, y, r.end.y))
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	var spec: Dictionary = b.map.get("water", {})
	mat.set_shader_parameter("deep", Color(str(spec.get("deep", "#1f6f86"))))
	mat.set_shader_parameter("shallow", Color(str(spec.get("shallow", "#5cc0c0"))))
	mat.set_shader_parameter("ripple", Color(str(spec.get("ripple", "#e6faf4"))))
	var node := MeshKit.finish(st, mat, false)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.world.add_child(node)


# ======================================================================= pavillon

## Un pavillon elfique à la place de la maison de village : mêmes champs que `house`
## (rect, height, roof_height, door, windows, lit, to, dialogue, awning), plus :
## `roof` (`bleu`, par défaut, ou `vert-de-gris`), `door_open` (arche ouverte sur l'intérieur ;
## vrai par défaut quand la porte mène ailleurs), `tall` (baies descendant jusqu'à la balustrade),
## `columns` (colonnes du porche, vrai par défaut), `finial` (épi de faîtage, vrai par défaut).
static func house(b, o: Dictionary) -> void:
	var r: Array = o.get("rect", [0, 0, 8, 5])
	var x0 := float(r[0])
	var z0 := float(r[1])
	var hw := float(r[2])
	var hd := float(r[3])
	var x1 := x0 + hw
	var z1 := z0 + hd
	var wh := float(o.get("height", 3.4))
	var rh := float(o.get("roof_height", 1.5))
	var door_x := float(o.get("door", hw * 0.5))
	var windows: Array = o.get("windows", [])
	var lit := bool(o.get("lit", true))
	var enter: bool = o.get("to") is Dictionary
	var door_open := bool(o.get("door_open", enter))
	var tall := bool(o.get("tall", false))
	var roof_tile := "elf_roof_vert" if str(o.get("roof", "bleu")) == "vert-de-gris" else "elf_roof"
	var node := Node3D.new()
	node.name = "ElvenHouse"
	node.set_meta("elven", "house")   # le nom change si plusieurs pavillons : le test se fie à cette étiquette
	b.world.add_child(node)
	var parts: Array = []

	# volume : pierre ivoire ; la façade est un décalque peint par-dessus
	var stone: Texture2D = Sprites.tile_texture("elf_stone")
	var st := MeshKit.begin()
	MeshKit.box(st, Vector3((x0 + x1) * 0.5, wh * 0.5, (z0 + z1) * 0.5), Vector3(hw, wh, hd))
	var body := MeshKit.finish(st, MeshKit.pixel_material(stone))
	node.add_child(body)
	parts.append(body)
	var front: Dictionary = Sprites.cached("efront:%s:%s:%s" % [str(b.map.get("id", "")), str(r), str(door_open)], func() -> Dictionary:
		var f := Elven.facade(hw, wh, door_x, windows, lit, door_open, tall)
		return {"albedo": PA.texture(f["albedo"]), "emission": PA.texture(f["emission"])})
	st = MeshKit.begin()
	MeshKit.quad(st, Vector3(x0, wh, z1 + 0.02), Vector3(x1, wh, z1 + 0.02), Vector3(x1, 0, z1 + 0.02), Vector3(x0, 0, z1 + 0.02))
	var face := MeshKit.finish(st, MeshKit.pixel_material(front["albedo"], front["emission"], 2.0))
	node.add_child(face)
	parts.append(face)

	# toit en pavillon à faible pente
	var ov := 0.7
	var slope := rh / (minf(hw, hd) * 0.5)
	var ye := wh - slope * ov
	var top := wh + rh
	var xm := (x0 + x1) * 0.5
	var zm := (z0 + z1) * 0.5
	var half := maxf(0.0, (hw - hd) * 0.5)
	var xl := x0 - ov
	var xr := x1 + ov
	var zb := z1 + ov
	var zf := z0 - ov
	var rl := Vector3(xm - half, top, zm)
	var rr := Vector3(xm + half, top, zm)
	var u := (hw + 2.0 * ov) / 2.0
	var vlen := Vector2(hd * 0.5 + ov, rh + slope * ov).length() / 2.0
	var vlen_s := Vector2(hw * 0.5 + ov, rh + slope * ov).length() / 2.0
	st = MeshKit.begin()
	MeshKit.quad(st, rl, rr, Vector3(xr, ye, zb), Vector3(xl, ye, zb), Vector2.ZERO, Vector2(u, vlen))
	MeshKit.quad(st, rr, rl, Vector3(xl, ye, zf), Vector3(xr, ye, zf), Vector2.ZERO, Vector2(u, vlen))
	MeshKit.tri(st, Vector3(xl, ye, zf), rl, Vector3(xl, ye, zb), Vector2(0, vlen_s), Vector2(vlen_s * 0.5, 0), Vector2(vlen_s * 2.0, vlen_s))
	MeshKit.tri(st, Vector3(xr, ye, zb), rr, Vector3(xr, ye, zf), Vector2(0, vlen_s), Vector2(vlen_s * 0.5, 0), Vector2(vlen_s * 2.0, vlen_s))
	var roof_mat := MeshKit.pixel_material(Sprites.tile_texture(roof_tile))
	roof_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var roof := MeshKit.finish(st, roof_mat)
	node.add_child(roof)
	parts.append(roof)
	var gold := MeshKit.flat_material(GOLD)
	var trim := MeshKit.flat_material(Color("#d6cdb4"))
	parts.append(_box_in(node, Vector3(xm, ye - 0.04, zb - 0.03), Vector3(hw + 2.0 * ov, 0.12, 0.1), trim))
	parts.append(_box_in(node, Vector3(xm, ye - 0.01, zb - 0.03), Vector3(hw + 2.0 * ov, 0.03, 0.12), gold))
	if half > 0.1:
		parts.append(_box_in(node, Vector3(xm, top + 0.04, zm), Vector3(half * 2.0 + 0.3, 0.12, 0.16), gold))
	if bool(o.get("finial", true)):
		parts.append(_box_in(node, Vector3(xm, top + 0.1, zm), Vector3(0.22, 0.16, 0.22), gold))
		parts.append(_box_in(node, Vector3(xm, top + 0.6, zm), Vector3(0.07, 0.9, 0.07), gold))
		parts.append(_box_in(node, Vector3(xm, top + 1.12, zm), Vector3(0.14, 0.14, 0.14), MeshKit.flat_material(Color("#fff2c0"), 1.2)))

	# colonnes du porche, sous le débord du toit
	if bool(o.get("columns", true)) and wh > 2.2:
		var cx: Array = [x0 + 0.3, x1 - 0.3]
		for xc: float in cx:
			_column(b, node, Vector3(xc, 0.0, z1 + 0.5), ye - 0.05, parts)
	b.world.rects.append(Rect2(x0, z0, hw, hd))

	if lit:
		for wx: Variant in windows:
			b._add_light(Vector3(x0 + float(wx), 1.4, z1 + 0.7), Color("#ffe4ae"), 0.9, 3.6, false)
	if door_x >= 0.0:
		var xd := x0 + door_x
		for s: float in [-1.25, 1.25]:
			_lantern_at(b, Vector3(xd + s, 0.0, z1 + 0.45), 1.7, false, 0.9, 4.2)
		var door_pos := Vector3(xd, 0.0, z1 + 0.35)
		var to: Variant = o.get("to")
		if to is Dictionary:
			b.world.warps.append({"rect": Rect2(xd - 0.45, z1, 0.9, 0.52), "map": str((to as Dictionary).get("map", "")), "spawn": str((to as Dictionary).get("spawn", ""))})
			b.keep_clear.append(Vector2(xd, z1 + 0.6))
		elif o.has("dialogue"):
			b._interactable(door_pos, o, "Examiner", null, 1.6)
		else:
			b.keep_clear.append(Vector2(xd, z1 + 0.6))
	b.world.occluders.append({"rect": Rect2(x0, z0, hw, hd), "nodes": parts, "fade": 0.0})


static func _box_in(parent: Node3D, center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat
	node.position = center
	parent.add_child(node)
	return node


static func _cyl_in(parent: Node3D, pos: Vector3, r_top: float, r_bot: float, hgt: float, mat: Material, segs: int = 10) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = r_top
	mesh.bottom_radius = r_bot
	mesh.height = hgt
	mesh.radial_segments = segs
	mesh.rings = 1
	node.mesh = mesh
	node.material_override = mat
	node.position = pos + Vector3(0.0, hgt * 0.5, 0.0)
	parent.add_child(node)
	return node


## Colonne fine à nervures : base, fût cannelé, chapiteau évasé. Bloque le passage.
static func _column(b, parent: Node3D, base: Vector3, hgt: float, parts: Array = []) -> void:
	var fluted := MeshKit.pixel_material(Sprites.tile_texture("elf_column"))
	fluted.uv1_scale = Vector3(1.0, hgt / 2.0, 1.0)
	var pale := MeshKit.pixel_material(Sprites.tile_texture("elf_stone"))
	parts.append(_cyl_in(parent, base, 0.27, 0.3, 0.16, pale))
	parts.append(_cyl_in(parent, base + Vector3(0, 0.16, 0), 0.13, 0.14, hgt - 0.42, fluted))
	parts.append(_cyl_in(parent, base + Vector3(0, hgt - 0.26, 0), 0.3, 0.14, 0.26, pale))
	parts.append(_box_in(parent, base + Vector3(0, hgt - 0.04, 0), Vector3(0.62, 0.1, 0.62), pale))
	b.world.circles.append(Vector3(base.x, base.z, 0.24))


# ========================================================================= objets

## Construit un objet propre au style ; renvoie faux si le type est inconnu.
static func object(b, type: String, o: Dictionary) -> bool:
	match type:
		"elf_rail": _rail(b, o)
		"elf_lantern":
			var p: Vector3 = b._p(o)
			_lantern_at(b, p, float(o.get("height", 2.2)), true, float(o.get("energy", 2.4)), float(o.get("range", 7.0)), bool(o.get("shadow", true)),
					Color(str(o.get("color", "#bcd8ff"))))
		"elf_column3d":
			var parent := Node3D.new()
			b.world.add_child(parent)
			var p: Vector3 = b._p(o)
			_column(b, parent, p, float(o.get("height", 3.4)))
		"elf_arcade": _arcade(b, o)
		"elf_gate": _gate(b, o)
		"elf_waterfall":
			var p: Vector3 = b._p(o)
			_waterfall(b, Vector3(p.x - 0.5 + 0.5, float(o.get("base", p.y)), p.z), float(o.get("height", 2.4)), float(o.get("width", 2.0)), bool(o.get("pool", true)))
		"elf_counter": _counter(b, o)
		"elf_medallion": _medallion(b, o)
		"elf_pool":
			var rr: Rect2 = b._rect2(o)
			_pool(b, rr, float(o.get("y", 0.02)))
		_: return false
	return true


## Balustrade ajourée le long d'une ligne brisée de segments horizontaux ou verticaux.
## Champs : `points` (cases), `height` (0,9 par défaut), `solid` (faux : décor traversable).
static func _rail(b, o: Dictionary) -> void:
	var pts: Array = o.get("points", [])
	var hgt := float(o.get("height", 0.95))
	var solid := bool(o.get("solid", true))
	var off := 0.0 if bool(o.get("exact", false)) else 0.5   # « exact » : coordonnées en unités, pas en cases
	var st := MeshKit.begin()
	for i in range(pts.size() - 1):
		var pa: Array = pts[i]
		var pb: Array = pts[i + 1]
		var a := Vector2(float(pa[0]) + off, float(pa[1]) + off)
		var c := Vector2(float(pb[0]) + off, float(pb[1]) + off)
		var length := a.distance_to(c)
		if length < 0.05:
			continue
		var horizontal := absf(c.x - a.x) >= absf(c.y - a.y)
		var n := maxi(1, int(round(length / 1.6)))
		for k in range(n + 1):
			var q := a.lerp(c, float(k) / float(n))
			var gy: float = b.world.ground_y(q.x, q.y)
			MeshKit.box(st, Vector3(q.x, gy + hgt * 0.5, q.y), Vector3(0.2, hgt, 0.2))
			MeshKit.box(st, Vector3(q.x, gy + hgt + 0.07, q.y), Vector3(0.3, 0.14, 0.3))
			MeshKit.box(st, Vector3(q.x, gy + hgt + 0.2, q.y), Vector3(0.14, 0.12, 0.14))
		var mid := (a + c) * 0.5
		var gm: float = b.world.ground_y(mid.x, mid.y)
		var size_x := length if horizontal else 0.09
		var size_z := 0.09 if horizontal else length
		MeshKit.box(st, Vector3(mid.x, gm + hgt - 0.04, mid.y), Vector3(size_x, 0.1, size_z))
		MeshKit.box(st, Vector3(mid.x, gm + 0.14, mid.y), Vector3(size_x, 0.1, size_z))
		var balusters := int(length / 0.26)
		for k in range(balusters + 1):
			var q := a.lerp(c, float(k) / float(maxi(1, balusters)))
			var gy: float = b.world.ground_y(q.x, q.y)
			MeshKit.box(st, Vector3(q.x, gy + hgt * 0.5 - 0.04, q.y), Vector3(0.06, hgt - 0.2, 0.06))
		if solid:
			var steps := int(ceil(length / 0.4))
			for k in range(steps + 1):
				var q := a.lerp(c, float(k) / float(steps))
				b.world.circles.append(Vector3(q.x, q.y, 0.2))
	var node := MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture("elf_stone")))
	node.name = "ElvenRail"
	b.world.add_child(node)


## Lanterne elfique : fût fin de pierre claire, volutes, verre qui luit d'un bleu pâle ou argenté.
static func _lantern_at(b, p: Vector3, hgt: float, block: bool, energy: float, light_range: float, shadow: bool = false, color: Color = LANTERN_GLOW) -> void:
	var parent := Node3D.new()
	parent.name = "ElvenLantern"
	b.world.add_child(parent)
	var gy: float = b.world.ground_y(p.x, p.z)
	var base := Vector3(p.x, gy, p.z)
	var pale := MeshKit.pixel_material(Sprites.tile_texture("elf_stone"))
	var bronze := MeshKit.flat_material(Color("#c9b78a"))
	_cyl_in(parent, base, 0.12, 0.17, 0.14, pale, 8)
	_cyl_in(parent, base + Vector3(0, 0.14, 0), 0.045, 0.06, hgt - 0.5, bronze, 6)
	_box_in(parent, base + Vector3(0, hgt - 0.34, 0), Vector3(0.2, 0.05, 0.2), bronze)
	var glass := MeshKit.flat_material(color, 1.6)
	_box_in(parent, base + Vector3(0, hgt - 0.14, 0), Vector3(0.18, 0.3, 0.18), glass).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cyl_in(parent, base + Vector3(0, hgt + 0.02, 0), 0.0, 0.17, 0.16, bronze, 6)
	_box_in(parent, base + Vector3(0, hgt + 0.22, 0), Vector3(0.04, 0.12, 0.04), bronze)
	var light := Atmosphere.make_light(color, energy, light_range, shadow, 0.04)
	light.position = base + Vector3(0, hgt - 0.1, 0.05)
	parent.add_child(light)
	if block:
		b.world.circles.append(Vector3(p.x, p.z, 0.18))
		b.keep_clear.append(Vector2(p.x, p.z))


## Rangée d'arches : le sprite et un obstacle à chaque pilier. `pos` est le milieu du pied.
static func _arcade(b, o: Dictionary) -> void:
	var v := int(o.get("variant", 1))
	var p: Vector3 = b._p(o)
	b._prop("elf_arcade", {"variant": v, "solid": 0.0}, p)
	var n := (v if v < 3 else 2) + 1
	var width := (float(n) * 72.0 + 10.0) / 24.0
	for i in range(n + 1):
		b.world.circles.append(Vector3(p.x - width * 0.5 + (5.0 + float(i) * 72.0) / 24.0, p.z, 0.3))


## Grande arche d'entrée : le sprite et un obstacle à chaque pile.
static func _gate(b, o: Dictionary) -> void:
	var v := int(o.get("variant", 0))
	var p: Vector3 = b._p(o)
	b._prop("elf_gate", {"variant": v, "solid": 0.0}, p)
	var width := (176.0 if v == 0 else 128.0) / 24.0
	var pier := (26.0 if v == 0 else 20.0) / 24.0
	for s: float in [-1.0, 1.0]:
		b.world.circles.append(Vector3(p.x + s * (width * 0.5 - pier * 0.5), p.z, pier * 0.5))
		b.world.circles.append(Vector3(p.x + s * (width * 0.5 - pier * 0.5), p.z - 0.2, pier * 0.5))


## Guichet / comptoir de bois pâle, avec une grille de laiton dressée derrière.
## Champs : `rect`, `height` (1,0), `grille` (vrai par défaut).
static func _counter(b, o: Dictionary) -> void:
	var r: Rect2 = b._rect2(o)
	var hgt := float(o.get("height", 1.0))
	var c := Vector3(r.position.x + r.size.x * 0.5, 0.0, r.position.y + r.size.y * 0.5)
	var st := MeshKit.begin()
	MeshKit.box(st, c + Vector3(0, hgt * 0.5, 0), Vector3(r.size.x, hgt, r.size.y))
	var node := MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture("elf_wood")))
	b.world.add_child(node)
	var parent := Node3D.new()
	b.world.add_child(parent)
	_box_in(parent, c + Vector3(0, hgt + 0.04, 0), Vector3(r.size.x + 0.14, 0.08, r.size.y + 0.14), MeshKit.pixel_material(Sprites.tile_texture("elf_stone")))
	_box_in(parent, c + Vector3(0, hgt * 0.5, r.size.y * 0.5 + 0.01), Vector3(r.size.x - 0.3, hgt - 0.3, 0.03), MeshKit.flat_material(Color("#8a7455")))
	if bool(o.get("grille", true)):
		var bars := MeshKit.flat_material(Color("#d8c27a"))
		var z := c.z - r.size.y * 0.5 + 0.05
		var n := int(r.size.x / 0.2)
		for k in range(n + 1):
			var x := r.position.x + 0.1 + float(k) * (r.size.x - 0.2) / float(maxi(1, n))
			_box_in(parent, Vector3(x, hgt + 0.5, z), Vector3(0.025, 0.9, 0.025), bars)
		_box_in(parent, Vector3(c.x, hgt + 0.96, z), Vector3(r.size.x, 0.06, 0.06), bars)
		_box_in(parent, Vector3(c.x, hgt + 0.1, z), Vector3(r.size.x, 0.05, 0.06), bars)
	b.world.rects.append(r)


## Médaillon de dallage : disque d'or et de feuilles posé au sol. Champs : `pos`, `radius` (2).
static func _medallion(b, o: Dictionary) -> void:
	var radius := float(o.get("radius", 2.0))
	var p: Vector3 = b._p(o)
	var tex: Texture2D = Sprites.cached("medal:%.1f" % radius, func() -> Texture2D:
		return PA.texture(Elven.medallion(radius)))
	var st := MeshKit.begin()
	MeshKit.quad(st, Vector3(p.x - radius, 0, p.z - radius), Vector3(p.x + radius, 0, p.z - radius), Vector3(p.x + radius, 0, p.z + radius), Vector3(p.x - radius, 0, p.z + radius))
	var m := MeshKit.pixel_material(tex)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	var node := MeshKit.finish(st, m, false)
	node.position.y = p.y + 0.012
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.world.add_child(node)
