extends RefCounted
## Construit une carte 3D complète à partir de sa description (data/maps/*.json).
## Le format des cartes est documenté dans docs/FORMAT_DONNEES.md.

const PA = preload("res://src/gfx/pixel_art.gd")
const MeshKit = preload("res://src/gfx/mesh_kit.gd")
const TilePainter = preload("res://src/gfx/tile_painter.gd")
const Atmosphere = preload("res://src/world/atmosphere.gd")
const Npc = preload("res://src/world/npc.gd")
const WATER_SHADER = preload("res://src/gfx/shaders/water.gdshader")

const PPU := 24
const WARM := Color("#ffb45e")

## Types de sol. hole = pas de sol dessiné ; solid = infranchissable ; hard = bord net.
const GROUND := {
	"grass": {}, "path": {}, "cobble": {}, "soil": {},
	"planks": {"hard": true}, "floor": {"hard": true},
	"water": {"hole": true, "solid": true},
	"void": {"hole": true, "solid": true, "hard": true},
}

## Accessoires affichés comme des sprites debout.
const PROPS := {
	"tree": {"variants": 4, "solid": 0.42, "sway": 0.05, "flip": true, "jitter": 0.18},
	"bush": {"variants": 3, "solid": 0.42, "sway": 0.015, "flip": true},
	"flowers": {"variants": 4, "sway": 0.02},
	"grass": {"variants": 4, "sway": 0.04},
	"wheat": {"variants": 3, "sway": 0.02},
	"wilted": {"variants": 2},
	"barrel": {"solid": 0.36},
	"sign": {"solid": 0.25},
	"rock": {"variants": 2, "solid": 0.4},
	"fern": {"variants": 3, "sway": 0.02},
	"bollard": {"solid": 0.3},
	"monument": {"solid": 1.1},
	"boat": {"variants": 2},
	"shelf": {},
	"window": {"glow": 0.9},
}

var world: Node3D
var map: Dictionary = {}
var w := 0
var h := 0
var cells: Array[String] = []
var rng := RandomNumberGenerator.new()
var keep_clear: Array[Vector2] = []
var wall_height := 3.0
var _north_gaps: Array[Vector2] = []
var _tree_spots: Array[Vector2] = []

## Talus d'arrière-plan, au nord des cartes d'extérieur : (z du bord, hauteur).
const TERRACES: Array[Vector2] = [Vector2(-2.4, 1.4), Vector2(-8.5, 2.9)]


func build(p_world: Node3D, p_map: Dictionary) -> void:
	world = p_world
	map = p_map
	var size: Array = map.get("size", [20, 15])
	w = int(size[0])
	h = int(size[1])
	wall_height = float(map.get("wall_height", 3.0))
	rng.seed = hash(str(map.get("id", "carte")))
	_build_cells()
	world.grid_w = w
	world.grid_h = h
	world.blocked = PackedByteArray()
	world.blocked.resize(w * h)
	var has_water := false
	for i in w * h:
		world.blocked[i] = 1 if _flag(cells[i], "solid") else 0
		if cells[i] == "water":
			has_water = true
	_build_ground()
	if has_water:
		_build_water()
	if bool(map.get("interior", false)):
		_build_interior_walls()
	else:
		_build_outskirts()

	var spawns: Dictionary = map.get("spawns", {})
	for key: String in spawns:
		var sp: Dictionary = spawns[key]
		var p: Array = sp.get("pos", [0, 0])
		keep_clear.append(Vector2(float(p[0]) + 0.5, float(p[1]) + 0.5))

	var objects: Array = map.get("objects", [])
	for o: Dictionary in objects:
		if str(o.get("type", "")) != "scatter":
			_object(o)
	for o: Dictionary in objects:
		if str(o.get("type", "")) == "scatter":
			_scatter(o)
	_undergrowth()

	var amb := Database.get_ambiance(str(map.get("ambiance", "crepuscule")))
	world.followers = Atmosphere.build(world, amb, Rect2(0.0, 0.0, w, h))


# ----------------------------------------------------------------------- sol

func _build_cells() -> void:
	var ground: Dictionary = map.get("ground", {})
	var def := str(ground.get("default", "grass"))
	cells.resize(w * h)
	cells.fill(def)
	for f: Dictionary in ground.get("fills", []):
		var r: Array = f.get("rect", [0, 0, 0, 0])
		var t := str(f.get("type", def))
		if not GROUND.has(t):
			push_warning("Type de sol inconnu : " + t)
			continue
		for ty in range(int(r[1]), int(r[1]) + int(r[3])):
			for tx in range(int(r[0]), int(r[0]) + int(r[2])):
				if tx >= 0 and ty >= 0 and tx < w and ty < h:
					cells[ty * w + tx] = t


func _cell(tx: int, ty: int) -> String:
	return cells[clampi(ty, 0, h - 1) * w + clampi(tx, 0, w - 1)]


func _flag(type: String, flag: String) -> bool:
	var d: Dictionary = GROUND.get(type, {})
	return bool(d.get(flag, false))


func _cell_at_pixel(gx: float, gy: float) -> String:
	return _cell(int(floor(gx / PPU)), int(floor(gy / PPU)))


func _paint_ground() -> ImageTexture:
	var img := PA.new_image(w * PPU, h * PPU)
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.055
	for ty in h:
		for tx in w:
			var t := cells[ty * w + tx]
			var uniform := true
			for dy: int in [-1, 0, 1]:
				for dx: int in [-1, 0, 1]:
					if _cell(tx + dx, ty + dy) != t:
						uniform = false
			if uniform:
				if not _flag(t, "hole"):
					img.blit_rect(Sprites.tile_image(t), Rect2i((tx % 2) * PPU, (ty % 2) * PPU, PPU, PPU), Vector2i(tx * PPU, ty * PPU))
				continue
			# tuile de bordure : frontière irrégulière entre les matières
			for py in PPU:
				for px in PPU:
					var gx := tx * PPU + px
					var gy := ty * PPU + py
					var wx := gx + noise.get_noise_2d(gx, gy) * 7.0
					var wy := gy + noise.get_noise_2d(gx + 300.0, gy + 170.0) * 7.0
					var use := _cell_at_pixel(wx, wy)
					if _flag(t, "hard") or _flag(use, "hard"):
						use = t
					if _flag(use, "hole"):
						continue
					var c := Sprites.tile_image(use).get_pixel(gx % 48, gy % 48)
					if not _flag(use, "hard"):
						if _cell_at_pixel(wx, wy + 3.0) == "water" or _cell_at_pixel(wx, wy - 3.0) == "water" \
								or _cell_at_pixel(wx + 3.0, wy) == "water" or _cell_at_pixel(wx - 3.0, wy) == "water":
							c = PA.shade(c, -0.35)
						elif use == "grass" and (_cell_at_pixel(wx, wy + 2.0) != "grass" or _cell_at_pixel(wx + 2.0, wy) != "grass"):
							c = PA.shade(c, -0.14)
					img.set_pixel(gx, gy, c)
	return PA.texture(img)


func _build_ground() -> void:
	var tex: Texture2D = Sprites.cached("ground:" + str(map.get("id", "")), _paint_ground)
	var mat := MeshKit.ground_material(tex)
	var st := MeshKit.begin()
	MeshKit.quad(st, Vector3(0, 0, 0), Vector3(w, 0, 0), Vector3(w, 0, h), Vector3(0, 0, h))
	var node := MeshKit.finish(st, mat, false)
	node.name = "Ground"
	world.add_child(node)


func _ground_quad(st: SurfaceTool, x0: float, z0: float, x1: float, z1: float, y: float = 0.0) -> void:
	MeshKit.quad(st, Vector3(x0, y, z0), Vector3(x1, y, z0), Vector3(x1, y, z1), Vector3(x0, y, z1),
			Vector2(x0, z0) / MeshKit.TEX_UNITS, Vector2(x1, z1) / MeshKit.TEX_UNITS)


## Prolonge l'herbe et la forêt au-delà de la carte pour que la caméra ne voie jamais le vide.
func _build_outskirts() -> void:
	var far := 70.0
	var river := -1
	for ty in h:
		if _cell(0, ty) == "water" and _cell(w - 1, ty) == "water":
			river = ty
			break
	var z_end := float(river) if river >= 0 else float(h) + far
	var grass_mat := MeshKit.ground_material(Sprites.tile_texture("grass"))
	var st := MeshKit.begin()
	_ground_quad(st, -far, -far, w + far, 0.0)
	_ground_quad(st, -far, 0.0, 0.0, z_end)
	_ground_quad(st, w, 0.0, w + far, z_end)
	if river < 0:
		_ground_quad(st, 0.0, h, w, h + far)
	# Relief d'arrière-plan : deux talus rocheux au nord, ouverts là où un chemin ou l'eau sort.
	_north_gaps.clear()
	var tx := 0
	while tx < w:
		if _cell(tx, 0) != "grass":
			var from := tx
			while tx < w and _cell(tx, 0) != "grass":
				tx += 1
			_north_gaps.append(Vector2(float(from) - 1.6, float(tx) + 1.6))
		else:
			tx += 1
	var cliffs := MeshKit.begin()
	var x := -far
	var spans: Array[Vector2] = []
	for g: Vector2 in _north_gaps:
		if g.x > x:
			spans.append(Vector2(x, g.x))
		x = maxf(x, g.y)
	if x < w + far:
		spans.append(Vector2(x, w + far))
	for s: Vector2 in spans:
		for t: Vector2 in TERRACES:
			var depth := far + t.x
			MeshKit.box(cliffs, Vector3((s.x + s.y) * 0.5, t.y * 0.5, t.x - depth * 0.5), Vector3(s.y - s.x, t.y, depth))
			_ground_quad(st, s.x, -far, s.y, t.x, t.y + 0.03)
	if not spans.is_empty():
		var rock := MeshKit.finish(cliffs, MeshKit.ground_material(Sprites.tile_texture("cliff"), 0.12), true)
		rock.name = "Cliffs"
		world.add_child(rock)
	var node := MeshKit.finish(st, grass_mat, false)
	node.name = "Outskirts"
	world.add_child(node)
	var side_z := z_end - 1.5
	for i in 120:
		var p := Vector3.ZERO
		if i < 76:
			p = Vector3(rng.randf_range(-18.0, w + 18.0), 0, rng.randf_range(-18.0, -0.8))
		elif i < 98:
			p = Vector3(rng.randf_range(-18.0, -0.9), 0, rng.randf_range(0.0, side_z))
		else:
			p = Vector3(rng.randf_range(w + 0.9, w + 18.0), 0, rng.randf_range(0.0, side_z))
		p.y = _terrace_height(p.x, p.z)
		_prop("tree", {"solid": 0.0}, p)
	# sous-bois des abords : buissons, fougères et touffes au pied de la forêt
	for i in 150:
		var p := Vector3(rng.randf_range(-12.0, w + 12.0), 0, rng.randf_range(-9.0, -0.4))
		if i >= 110:
			var left := i % 2 == 0
			p = Vector3(rng.randf_range(-9.0, -0.5) if left else rng.randf_range(w + 0.5, w + 9.0), 0, rng.randf_range(0.0, side_z))
		p.y = _terrace_height(p.x, p.z)
		var kinds: Array = ["grass", "fern", "grass", "bush", "fern", "flowers"]
		_prop(str(kinds[i % kinds.size()]), {"solid": 0.0, "shadow": false}, p)


## Hauteur du sol hors de la carte (talus du nord).
func _terrace_height(x: float, z: float) -> float:
	for g: Vector2 in _north_gaps:
		if x > g.x - 0.4 and x < g.y + 0.4:
			return 0.0
	var y := 0.0
	for t: Vector2 in TERRACES:
		if z < t.x - 0.3:
			y = t.y
		elif z < t.x + 0.5:
			return y   # trop près du bord : on reste en bas, devant la paroi
	return y


## Végétation basse au pied des arbres de la carte : une seconde couche, sans obstacle.
func _undergrowth() -> void:
	var kinds: Array = ["fern", "grass", "fern", "flowers", "grass"]
	for spot: Vector2 in _tree_spots:
		var n := 1 + (rng.randi() % 2)
		for k in n:
			var p := spot + Vector2(rng.randf_range(-0.7, 0.7), rng.randf_range(0.1, 0.45))
			if p.x < 0.2 or p.y < 0.2 or p.x > w - 0.2 or p.y > h - 0.2:
				continue
			var cell := _cell(int(p.x), int(p.y))
			if cell != "grass" and cell != "soil":
				continue
			_prop(str(kinds[rng.randi() % kinds.size()]), {"shadow": false}, Vector3(p.x, 0.0, p.y))


func _build_water() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	var st := MeshKit.begin()
	MeshKit.quad(st, Vector3(-80, 0, -10), Vector3(w + 80, 0, -10), Vector3(w + 80, 0, h + 80), Vector3(-80, 0, h + 80))
	var node := MeshKit.finish(st, mat, false)
	node.position.y = -0.22
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.name = "Water"
	world.add_child(node)


## Intérieurs : murs automatiques là où le plancher touche le vide (fond et côtés seulement,
## le mur côté caméra reste ouvert, comme dans une maison de poupée).
func _build_interior_walls() -> void:
	var st := MeshKit.begin()
	var cap := MeshKit.begin()
	var hgt := wall_height
	var v1 := hgt / 3.0
	var any := false
	for ty in h:
		for tx in w:
			if _flag(_cell(tx, ty), "hole"):
				continue
			var x0 := float(tx)
			var x1 := x0 + 1.0
			var z0 := float(ty)
			var z1 := z0 + 1.0
			if ty == 0 or _flag(cells[(ty - 1) * w + tx], "hole"):
				MeshKit.quad(st, Vector3(x0, hgt, z0), Vector3(x1, hgt, z0), Vector3(x1, 0, z0), Vector3(x0, 0, z0),
						Vector2(x0 / 2.0, 0.0), Vector2(x1 / 2.0, v1))
				MeshKit.quad(cap, Vector3(x0 - 0.4, hgt, z0 - 0.4), Vector3(x1 + 0.4, hgt, z0 - 0.4), Vector3(x1 + 0.4, hgt, z0), Vector3(x0 - 0.4, hgt, z0))
				any = true
			if (tx == 0 or _flag(cells[ty * w + tx - 1], "hole")) and not _juts_out(tx - 1, ty):
				MeshKit.quad(st, Vector3(x0, hgt, z1), Vector3(x0, hgt, z0), Vector3(x0, 0, z0), Vector3(x0, 0, z1),
						Vector2(z1 / 2.0, 0.0), Vector2(z0 / 2.0, v1))
				MeshKit.quad(cap, Vector3(x0 - 0.4, hgt, z0), Vector3(x0, hgt, z0), Vector3(x0, hgt, z1), Vector3(x0 - 0.4, hgt, z1))
				any = true
			if (tx == w - 1 or _flag(cells[ty * w + tx + 1], "hole")) and not _juts_out(tx + 1, ty):
				MeshKit.quad(st, Vector3(x1, hgt, z0), Vector3(x1, hgt, z1), Vector3(x1, 0, z1), Vector3(x1, 0, z0),
						Vector2(z0 / 2.0, 0.0), Vector2(z1 / 2.0, v1))
				MeshKit.quad(cap, Vector3(x1, hgt, z0), Vector3(x1 + 0.4, hgt, z0), Vector3(x1 + 0.4, hgt, z1), Vector3(x1, hgt, z1))
				any = true
	if not any:
		return
	var walls := MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture("interior_wall")))
	walls.name = "Walls"
	world.add_child(walls)
	var caps := MeshKit.finish(cap, MeshKit.flat_material(Color("#0d0a12")))
	caps.name = "WallCaps"
	world.add_child(caps)


## Vrai si un mur latéral posé contre la case vide (tx, ty) dépasserait de la pièce vers
## la caméra : c'est le cas des renfoncements de porte, dont le plancher avance au sud du
## mur du fond. On les laisse ouverts, sinon ils masquent l'entrée.
func _juts_out(tx: int, ty: int) -> bool:
	if tx < 0 or tx >= w or ty <= 0:
		return false
	return not _flag(cells[(ty - 1) * w + tx], "hole")


# -------------------------------------------------------------------- objets

func _p(o: Dictionary) -> Vector3:
	var p: Array = o.get("pos", [0, 0])
	return Vector3(float(p[0]) + 0.5, 0.0, float(p[1]) + 0.5)


func _object(o: Dictionary) -> void:
	var type := str(o.get("type", ""))
	if type != "trigger":
		# "unless" : l'objet disparaît quand le drapeau est posé ; "if" : il n'existe qu'ensuite.
		var unless := str(o.get("unless", ""))
		if unless != "":
			world.flag_deps[unless] = GameState.has_flag(unless)
			if GameState.has_flag(unless):
				return
		var only_if := str(o.get("if", ""))
		if only_if != "":
			world.flag_deps[only_if] = GameState.has_flag(only_if)
			if not GameState.has_flag(only_if):
				return
	match type:
		"monster": _monster(o)
		"encounter_zone": world.encounter_zones.append({"rect": _rect2(o), "table": str(o.get("table", ""))})
		"house": _house(o)
		"lantern": _lantern(o)
		"fence": _fence(o)
		"npc": _npc(o)
		"light": _light(o)
		"warp": _warp(o)
		"trigger": _trigger(o)
		"table": _table(o)
		"stool": _stool(o)
		"counter": _counter(o)
		"fireplace": _fireplace(o)
		"stove": _stove(o)
		"rug": _rug(o)
		"crate": _crate(o)
		_:
			if PROPS.has(type):
				_prop(type, o, _p(o))
			else:
				push_warning("Type d'objet inconnu dans la carte %s : %s" % [str(map.get("id", "")), type])


func _interactable(pos: Vector3, o: Dictionary, default_label: String, node: Node3D = null, height: float = 1.3) -> void:
	var it := {
		"pos": pos,
		"dialogue": str(o.get("dialogue", "")),
		"label": str(o.get("label", default_label)),
		"reach": float(o.get("reach", 1.5)),
		"height": float(o.get("prompt_height", height)),
		"gated": bool(o.get("gated", false)),   # inaccessible tant qu'un obstacle scénarisé est là
	}
	if node != null:
		it["node"] = node
	world.interactables.append(it)
	keep_clear.append(Vector2(pos.x, pos.z))


func _prop(kind: String, o: Dictionary, pos: Vector3) -> Node3D:
	var def: Dictionary = PROPS.get(kind, {})
	var variants := int(def.get("variants", 1))
	var variant := int(o.get("variant", rng.randi() % variants))
	var tex := Sprites.prop(kind, variant)
	var node := Sprites.make_sprite(tex, float(def.get("sway", 0.0)), float(o.get("glow", def.get("glow", 0.0))))
	node.position = pos + Vector3(0, float(o.get("height", 0.0)), 0)
	var s := float(o.get("scale", 1.0))
	if def.has("jitter"):
		s *= 1.0 + rng.randf_range(-1.0, 1.0) * float(def["jitter"])
	var flip := bool(def.get("flip", false)) and rng.randf() < 0.5
	node.scale = Vector3(-s if flip else s, s, s)
	node.rotation.z = deg_to_rad(float(o.get("lean", 0.0)))
	world.add_child(node)
	var quad := node.get_child(0) as MeshInstance3D
	quad.set_instance_shader_parameter("sway_phase", rng.randf() * TAU)
	if not bool(o.get("shadow", true)):
		quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var solid := float(o.get("solid", def.get("solid", 0.0)))
	if solid > 0.0:
		world.circles.append(Vector3(pos.x, pos.z, solid))
	if o.has("dialogue"):
		_interactable(pos, o, "Examiner", null, tex.get_height() / float(PPU) * s * 0.75)
	if kind == "boat":
		var tw := node.create_tween().set_loops()
		tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var y := node.position.y
		var period := rng.randf_range(1.6, 2.3)
		tw.tween_property(node, "position:y", y + 0.07, period)
		tw.tween_property(node, "position:y", y, period)
	return node


func _scatter(o: Dictionary) -> void:
	var kind := str(o.get("prop", "tree"))
	var r: Array = o.get("rect", [0, 0, w, h])
	var count := int(o.get("count", 10))
	var min_dist := float(o.get("min_dist", 1.0))
	var on: Array = o.get("on", ["grass"])
	rng.seed = int(o.get("seed", 1)) * 7919 + 13
	var def: Dictionary = PROPS.get(kind, {})
	var solid := float(def.get("solid", 0.0))
	var placed: Array[Vector2] = []
	var tries := 0
	while placed.size() < count and tries < count * 40:
		tries += 1
		var p := Vector2(rng.randf_range(float(r[0]), float(r[0]) + float(r[2])), rng.randf_range(float(r[1]), float(r[1]) + float(r[3])))
		if p.x < 0.3 or p.y < 0.3 or p.x > w - 0.3 or p.y > h - 0.3:
			continue
		if not on.has(_cell(int(p.x), int(p.y))):
			continue
		var ok := true
		for q in placed:
			if q.distance_to(p) < min_dist:
				ok = false
				break
		if not ok:
			continue
		if solid > 0.0:
			for k in keep_clear:
				if k.distance_to(p) < solid + 1.1:
					ok = false
					break
			if ok and not world.is_free(p, solid + 0.45):
				ok = false
			# un obstacle ne doit jamais mordre sur un chemin d'une case de large
			if ok:
				var m := solid + 0.4
				for d: Vector2 in [Vector2(m, 0), Vector2(-m, 0), Vector2(0, m), Vector2(0, -m)]:
					var c := p + d
					if not on.has(_cell(clampi(int(c.x), 0, w - 1), clampi(int(c.y), 0, h - 1))):
						ok = false
			if ok:
				for wp: Dictionary in world.warps:
					var wr: Rect2 = wp["rect"]
					if wr.grow(1.2).has_point(p):
						ok = false
		else:
			for rect: Rect2 in world.rects:
				if rect.grow(0.15).has_point(p):
					ok = false
		if ok:
			placed.append(p)
			_prop(kind, {}, Vector3(p.x, 0.0, p.y))
			if kind == "tree":
				_tree_spots.append(p)


func _mesh_box(center: Vector3, size: Vector3, material: Material, shadow: bool = true) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	node.position = center
	if not shadow:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(node)
	return node


func _add_light(pos: Vector3, color: Color, energy: float, light_range: float, shadow: bool, flicker: float = 0.0) -> OmniLight3D:
	var l := Atmosphere.make_light(color, energy, light_range, shadow, flicker)
	l.position = pos
	world.add_child(l)
	return l


func _house(o: Dictionary) -> void:
	var r: Array = o.get("rect", [0, 0, 5, 4])
	var x0 := float(r[0])
	var z0 := float(r[1])
	var hw := float(r[2])
	var hd := float(r[3])
	var x1 := x0 + hw
	var z1 := z0 + hd
	var wh := float(o.get("height", 2.5))
	var rh := float(o.get("roof_height", 1.7))
	var door_x := float(o.get("door", hw * 0.5))
	var windows: Array = o.get("windows", [])
	var door_color := Database.color(o.get("door_color", "#3f7a52"), Color("#3f7a52"))
	var lit := bool(o.get("lit", true))
	var roof := str(o.get("roof", "rouge"))
	var house := Node3D.new()
	house.name = "House"
	world.add_child(house)
	var first_child := world.get_child_count()

	var front: Dictionary = Sprites.cached("house:%s:%s" % [str(map.get("id", "")), str(r)], func() -> Dictionary:
		var f := TilePainter.house_front(hw, wh, door_x, windows, door_color, lit)
		return {"albedo": PA.texture(f["albedo"]), "emission": PA.texture(f["emission"])})
	var st := MeshKit.begin()
	MeshKit.quad(st, Vector3(x0, wh, z1), Vector3(x1, wh, z1), Vector3(x1, 0, z1), Vector3(x0, 0, z1))
	house.add_child(MeshKit.finish(st, MeshKit.pixel_material(front["albedo"], front["emission"], 2.6)))

	var side_tex: Texture2D = Sprites.cached("house_side:%.2f:%.2f" % [hd, wh], func() -> Texture2D:
		return PA.texture(TilePainter.house_side(hd, wh)))
	st = MeshKit.begin()
	MeshKit.quad(st, Vector3(x0, wh, z0), Vector3(x0, wh, z1), Vector3(x0, 0, z1), Vector3(x0, 0, z0))
	MeshKit.quad(st, Vector3(x1, wh, z1), Vector3(x1, wh, z0), Vector3(x1, 0, z0), Vector3(x1, 0, z1))
	house.add_child(MeshKit.finish(st, MeshKit.pixel_material(side_tex)))

	var zm := (z0 + z1) * 0.5
	var top := wh + rh
	st = MeshKit.begin()
	MeshKit.tri(st, Vector3(x0, wh, z0), Vector3(x0, top, zm), Vector3(x0, wh, z1), Vector2(0, rh / 2.0), Vector2(hd / 4.0, 0), Vector2(hd / 2.0, rh / 2.0))
	MeshKit.tri(st, Vector3(x1, wh, z1), Vector3(x1, top, zm), Vector3(x1, wh, z0), Vector2(0, rh / 2.0), Vector2(hd / 4.0, 0), Vector2(hd / 2.0, rh / 2.0))
	MeshKit.quad(st, Vector3(x1, wh, z0), Vector3(x0, wh, z0), Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector2.ZERO, Vector2(hw / 2.0, wh / 2.0))
	house.add_child(MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture("plaster"))))

	# toit à deux pans, faîtage parallèle à l'écran
	var ov := 0.4
	var os := 0.3
	var slope := rh / (hd * 0.5)
	var ye := wh - slope * ov
	var slen := Vector2(hd * 0.5 + ov, rh + slope * ov).length()
	var uv1 := Vector2((hw + 2.0 * os) / 2.0, slen / 2.0)
	st = MeshKit.begin()
	MeshKit.quad(st, Vector3(x0 - os, top, zm), Vector3(x1 + os, top, zm), Vector3(x1 + os, ye, z1 + ov), Vector3(x0 - os, ye, z1 + ov), Vector2.ZERO, uv1)
	MeshKit.quad(st, Vector3(x1 + os, top, zm), Vector3(x0 - os, top, zm), Vector3(x0 - os, ye, z0 - ov), Vector3(x1 + os, ye, z0 - ov), Vector2.ZERO, uv1)
	house.add_child(MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture("roof_" + roof))))
	var pal: Array = TilePainter.ROOFS.get(roof, TilePainter.ROOFS["rouge"])
	var dark := MeshKit.flat_material(Color.from_string(str(pal[3]), Color.BLACK))
	_mesh_box(Vector3((x0 + x1) * 0.5, top + 0.02, zm), Vector3(hw + 2.0 * os + 0.1, 0.14, 0.22), dark)
	_mesh_box(Vector3((x0 + x1) * 0.5, ye - 0.03, z1 + ov - 0.03), Vector3(hw + 2.0 * os, 0.1, 0.08), MeshKit.flat_material(Color("#3c281c")))

	if bool(o.get("chimney", true)):
		var cpos := Vector3(x0 + hw * 0.74, top - 0.25, zm - hd * 0.16)
		st = MeshKit.begin()
		MeshKit.box(st, cpos, Vector3(0.55, 1.3, 0.55))
		house.add_child(MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture("brick"))))
		_mesh_box(cpos + Vector3(0, 0.68, 0), Vector3(0.68, 0.1, 0.68), MeshKit.flat_material(Color("#4a3a36")))
		if lit:
			var smoke := Atmosphere.make_particles("smoke")
			smoke.position = cpos + Vector3(0, 0.8, 0)
			world.add_child(smoke)

	if lit:
		for wx: Variant in windows:
			_add_light(Vector3(x0 + float(wx), 1.25, z1 + 0.6), WARM, 1.1, 3.8, false)
	world.rects.append(Rect2(x0, z0, hw, hd))
	# tout ce qui compose la maison peut s'estomper quand elle passe devant la caméra
	var parts: Array = []
	for n: Node in house.get_children():
		if n is GeometryInstance3D:
			parts.append(n)
	for i in range(first_child, world.get_child_count()):
		var n := world.get_child(i)
		if n is GeometryInstance3D:
			parts.append(n)
	world.occluders.append({"rect": Rect2(x0, z0, hw, hd), "nodes": parts, "fade": 0.0})

	if door_x >= 0.0:
		var xd := x0 + door_x
		_mesh_box(Vector3(xd, wh - 0.5, z1 + 0.1), Vector3(0.2, 0.26, 0.16), MeshKit.flat_material(Color("#ffd28a"), 4.0), false)
		_mesh_box(Vector3(xd, wh - 0.34, z1 + 0.1), Vector3(0.28, 0.06, 0.24), MeshKit.flat_material(Color("#2f2c38")), false)
		_add_light(Vector3(xd, wh - 0.6, z1 + 0.55), WARM, 1.6, 4.6, true, 0.08)
		var door_pos := Vector3(xd, 0.0, z1 + 0.35)
		var to: Variant = o.get("to")
		if to is Dictionary:
			world.warps.append({"rect": Rect2(xd - 0.45, z1, 0.9, 0.52), "map": str(to.get("map", "")), "spawn": str(to.get("spawn", ""))})
			keep_clear.append(Vector2(xd, z1 + 0.6))
		elif o.has("dialogue"):
			_interactable(door_pos, o, "Examiner", null, 1.6)
		else:
			keep_clear.append(Vector2(xd, z1 + 0.6))


func _lantern(o: Dictionary) -> void:
	var p := _p(o)
	var wood := MeshKit.flat_material(Color("#4a3426"))
	_mesh_box(p + Vector3(0, 0.95, 0), Vector3(0.12, 1.9, 0.12), wood)
	_mesh_box(p + Vector3(0, 0.06, 0), Vector3(0.3, 0.12, 0.3), wood)
	_mesh_box(p + Vector3(0, 2.07, 0), Vector3(0.32, 0.36, 0.32), MeshKit.flat_material(Color("#ffcf82"), 4.5), false)
	_mesh_box(p + Vector3(0, 2.29, 0), Vector3(0.46, 0.08, 0.46), MeshKit.flat_material(Color("#2f2c38")), false)
	_mesh_box(p + Vector3(0, 2.37, 0), Vector3(0.2, 0.08, 0.2), MeshKit.flat_material(Color("#2f2c38")), false)
	var color := Database.color(o.get("color", "#ffb45e"), WARM)
	_add_light(p + Vector3(0, 2.0, 0.05), color, float(o.get("energy", 3.2)), float(o.get("range", 7.5)), bool(o.get("shadow", true)), 0.1)
	world.circles.append(Vector3(p.x, p.z, 0.2))
	keep_clear.append(Vector2(p.x, p.z))


func _fence(o: Dictionary) -> void:
	var pts: Array = o.get("points", [])
	var wood := MeshKit.flat_material(Color("#6b4a30"))
	var wood_l := MeshKit.flat_material(Color("#86603e"))
	var lean := float(o.get("lean", 0.0))
	for i in range(pts.size() - 1):
		var pa: Array = pts[i]
		var pb: Array = pts[i + 1]
		var a := Vector2(float(pa[0]) + 0.5, float(pa[1]) + 0.5)
		var b := Vector2(float(pb[0]) + 0.5, float(pb[1]) + 0.5)
		var length := a.distance_to(b)
		if length < 0.05:
			continue
		var n := maxi(1, int(round(length)))
		for k in range(n + 1):
			var q := a.lerp(b, float(k) / float(n))
			var post := _mesh_box(Vector3(q.x, 0.4, q.y), Vector3(0.13, 0.8, 0.13), wood)
			post.rotation.z = deg_to_rad(rng.randf_range(-lean, lean))
		var mid := (a + b) * 0.5
		var angle := -atan2(b.y - a.y, b.x - a.x)
		for y: float in [0.3, 0.6]:
			var rail := _mesh_box(Vector3(mid.x, y, mid.y), Vector3(length, 0.07, 0.05), wood_l)
			rail.rotation.y = angle
			rail.rotation.z = deg_to_rad(rng.randf_range(-lean, lean) * 0.3)
		var steps := int(ceil(length / 0.35))
		for k in range(steps + 1):
			var q := a.lerp(b, float(k) / float(steps))
			world.circles.append(Vector3(q.x, q.y, 0.17))


func _npc(o: Dictionary) -> void:
	var id := str(o.get("id", ""))
	if not Database.characters.has(id):
		push_warning("PNJ sans fiche dans characters.json : " + id)
	var pos := _p(o)
	var node := Npc.new()
	node.name = "Npc_" + id
	world.add_child(node)
	node.setup(world, o, pos)
	world.npcs.append(node)
	var data := o.duplicate()
	if not data.has("dialogue"):
		data["dialogue"] = id
	_interactable(pos, data, "Parler", node, float(node.sprite.height) * 0.72)


## Monstre visible sur la carte (gardien, boss) : première pose de sa planche, qui respire.
func _monster(o: Dictionary) -> void:
	var def := Database.get_enemy(str(o.get("id", "")))
	var sp: Dictionary = {}
	var spv: Variant = def.get("sprite", {})
	if spv is Dictionary:
		sp = spv
	var sheet := Sprites.monster(str(sp.get("monster", "")))
	var ppu := float(sheet["ppu"])
	var s := float(o.get("scale", sp.get("scale", 1.0)))
	var pos := _p(o)
	var node := Node3D.new()
	node.name = "Monster_" + str(o.get("id", ""))
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(float(sheet["frame_w"]) / ppu, float(sheet["frame_h"]) / ppu)
	quad.mesh = mesh
	var tex: Texture2D = sheet["texture"]
	quad.material_override = Sprites.sprite_material(tex)
	quad.position.y = mesh.size.y * 0.5 - float(sheet["foot"]) / ppu
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	node.add_child(quad)
	node.position = pos
	node.scale = Vector3(-s if bool(o.get("flip", false)) else s, s, s)
	world.add_child(node)
	quad.set_instance_shader_parameter("frame_rect", Vector4(0.0, 0.0, 1.0 / float(int(sheet["columns"])), 1.0))
	var tw := node.create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "scale:y", s * 1.05, 1.5)
	tw.tween_property(node, "scale:y", s, 1.5)
	world.circles.append(Vector3(pos.x, pos.z, float(o.get("solid", 0.45 * s))))
	if o.has("dialogue"):
		_interactable(pos, o, "Approcher", null, mesh.size.y * s * 0.8)


func _light(o: Dictionary) -> void:
	var p := _p(o)
	p.y = float(o.get("height", 2.4))
	_add_light(p, Database.color(o.get("color", "#ffb45e"), WARM), float(o.get("energy", 1.5)), float(o.get("range", 6.0)),
			bool(o.get("shadow", false)), float(o.get("flicker", 0.0)))


func _rect2(o: Dictionary) -> Rect2:
	var r: Array = o.get("rect", [0, 0, 1, 1])
	return Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))


func _warp(o: Dictionary) -> void:
	var to: Dictionary = o.get("to", {})
	world.warps.append({"rect": _rect2(o), "map": str(to.get("map", "")), "spawn": str(to.get("spawn", ""))})


func _trigger(o: Dictionary) -> void:
	world.triggers.append({
		"rect": _rect2(o),
		"dialogue": str(o.get("dialogue", "")),
		"unless": str(o.get("unless", "")),
	})


# ----------------------------------------------------------------- mobilier

func _textured(st: SurfaceTool, tile: String) -> MeshInstance3D:
	var node := MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture(tile)))
	world.add_child(node)
	return node


func _candle(pos: Vector3) -> void:
	_mesh_box(pos + Vector3(0, 0.08, 0), Vector3(0.07, 0.16, 0.07), MeshKit.flat_material(Color("#efe6d2")), false)
	_mesh_box(pos + Vector3(0, 0.21, 0), Vector3(0.05, 0.09, 0.05), MeshKit.flat_material(Color("#ffc46a"), 6.0), false)
	_add_light(pos + Vector3(0, 0.35, 0), WARM, 0.9, 3.4, false, 0.14)


func _table(o: Dictionary) -> void:
	var p := _p(o)
	var size: Array = o.get("size", [1.4, 0.9])
	var sx := float(size[0])
	var sz := float(size[1])
	var st := MeshKit.begin()
	MeshKit.box(st, p + Vector3(0, 0.56, 0), Vector3(sx, 0.1, sz))
	for dx: float in [-1.0, 1.0]:
		for dz: float in [-1.0, 1.0]:
			MeshKit.box(st, p + Vector3(dx * (sx * 0.5 - 0.1), 0.255, dz * (sz * 0.5 - 0.1)), Vector3(0.1, 0.51, 0.1))
	_textured(st, "wood")
	world.rects.append(Rect2(p.x - sx * 0.5, p.z - sz * 0.5, sx, sz))
	if bool(o.get("candle", false)):
		_candle(p + Vector3(0, 0.61, 0))
	if o.has("dialogue"):
		_interactable(p, o, "Examiner", null, 1.0)


func _stool(o: Dictionary) -> void:
	var p := _p(o)
	var st := MeshKit.begin()
	MeshKit.box(st, p + Vector3(0, 0.3, 0), Vector3(0.42, 0.08, 0.42))
	MeshKit.box(st, p + Vector3(0, 0.13, 0), Vector3(0.26, 0.26, 0.26))
	_textured(st, "wood")
	world.circles.append(Vector3(p.x, p.z, 0.22))


func _counter(o: Dictionary) -> void:
	var r := _rect2(o)
	var hgt := float(o.get("height", 0.8))
	var c := Vector3(r.position.x + r.size.x * 0.5, 0.0, r.position.y + r.size.y * 0.5)
	var st := MeshKit.begin()
	MeshKit.box(st, c + Vector3(0, hgt * 0.5, 0), Vector3(r.size.x, hgt, r.size.y))
	_textured(st, "wood")
	_mesh_box(c + Vector3(0, hgt + 0.035, 0), Vector3(r.size.x + 0.12, 0.07, r.size.y + 0.12), MeshKit.flat_material(Color("#b5834e")))
	world.rects.append(r)


func _fireplace(o: Dictionary) -> void:
	var p: Array = o.get("pos", [0, 0])
	var x := float(p[0]) + 0.5
	var z := float(p[1])
	var st := MeshKit.begin()
	MeshKit.box(st, Vector3(x - 0.8, 0.7, z + 0.3), Vector3(0.36, 1.4, 0.6))
	MeshKit.box(st, Vector3(x + 0.8, 0.7, z + 0.3), Vector3(0.36, 1.4, 0.6))
	MeshKit.box(st, Vector3(x, 1.56, z + 0.32), Vector3(2.0, 0.34, 0.68))
	MeshKit.box(st, Vector3(x, 1.73 + (wall_height - 1.73) * 0.5, z + 0.2), Vector3(1.3, wall_height - 1.73, 0.4))
	MeshKit.box(st, Vector3(x, 0.04, z + 0.5), Vector3(1.7, 0.08, 1.0))
	_textured(st, "stone")
	_mesh_box(Vector3(x, 0.7, z + 0.05), Vector3(1.3, 1.4, 0.1), MeshKit.flat_material(Color("#0d0a12")), false)
	var log_mat := MeshKit.flat_material(Color("#3c281c"))
	var l1 := _mesh_box(Vector3(x, 0.16, z + 0.36), Vector3(0.75, 0.13, 0.15), log_mat, false)
	l1.rotation.y = 0.3
	var l2 := _mesh_box(Vector3(x, 0.24, z + 0.36), Vector3(0.7, 0.12, 0.14), log_mat, false)
	l2.rotation.y = -0.35
	for kind: String in ["fire", "embers"]:
		var fx := Atmosphere.make_particles(kind)
		fx.position = Vector3(x, 0.26, z + 0.38)
		world.add_child(fx)
	_add_light(Vector3(x, 0.75, z + 1.0), Color("#ff9a4a"), float(o.get("energy", 5.0)), 9.5, true, 0.2)
	world.rects.append(Rect2(x - 1.0, z, 2.0, 0.65))
	if o.has("dialogue"):
		_interactable(Vector3(x, 0, z + 0.7), o, "Examiner", null, 1.9)


func _stove(o: Dictionary) -> void:
	var p: Array = o.get("pos", [0, 0])
	var x := float(p[0]) + 0.5
	var z := float(p[1])
	var st := MeshKit.begin()
	MeshKit.box(st, Vector3(x, 0.42, z + 0.36), Vector3(1.3, 0.84, 0.72))
	MeshKit.box(st, Vector3(x + 0.4, 0.84 + (wall_height - 0.84) * 0.5, z + 0.18), Vector3(0.24, wall_height - 0.84, 0.24))
	MeshKit.box(st, Vector3(x - 0.25, 0.97, z + 0.38), Vector3(0.42, 0.26, 0.42))
	_textured(st, "iron")
	_mesh_box(Vector3(x - 0.1, 0.36, z + 0.73), Vector3(0.44, 0.24, 0.03), MeshKit.flat_material(Color("#ff8a3c"), 5.0), false)
	_add_light(Vector3(x - 0.1, 0.5, z + 1.1), Color("#ff8a3c"), 1.8, 3.6, false, 0.18)
	world.rects.append(Rect2(x - 0.65, z, 1.3, 0.72))
	if o.has("dialogue"):
		_interactable(Vector3(x, 0, z + 0.8), o, "Examiner", null, 1.5)


func _rug(o: Dictionary) -> void:
	var r := _rect2(o)
	var main := Database.color(o.get("color", "#8a3040"), Color("#8a3040"))
	var border := Database.color(o.get("border", "#c9a24a"), Color("#c9a24a"))
	var tex: Texture2D = Sprites.cached("rug:%s:%s" % [str(r), main.to_html()], func() -> Texture2D:
		return PA.texture(TilePainter.rug(r.size.x, r.size.y, main, border)))
	var st := MeshKit.begin()
	MeshKit.quad(st, Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, 0, r.position.y), Vector3(r.end.x, 0, r.end.y), Vector3(r.position.x, 0, r.end.y))
	var node := MeshKit.finish(st, MeshKit.pixel_material(tex), false)
	node.position.y = 0.012
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(node)


func _crate(o: Dictionary) -> void:
	var p := _p(o)
	var s := float(o.get("size", 0.7))
	var st := MeshKit.begin()
	MeshKit.box(st, p + Vector3(0, s * 0.5, 0), Vector3(s, s, s))
	var node := _textured(st, "wood")
	node.rotation.y = deg_to_rad(float(o.get("turn", 0.0)))
	world.circles.append(Vector3(p.x, p.z, s * 0.6))
	if o.has("dialogue"):
		_interactable(p, o, "Ouvrir", null, s + 0.25)
