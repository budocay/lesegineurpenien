extends RefCounted
## Styles d'architecture du chapitre 6 : « gouda » (Minas Tartine : pierre blanche, ardoise,
## sept étages), « veille » (Sentier des Insomniaques : galerie aux lits de pierre), « port »
## (Port-Salé : quais, voiles de torchon noir) et « champ » (champs du Pelle-à-Tarte). Un seul
## constructeur les sert tous ; chaque style choisit ses textures et son décor d'abords dans
## la table STYLES. Rien ici ne s'applique à une carte sans l'un de ces champs `style`.
##
## Le constructeur de cartes (MapBuilder) délègue ici :
##  - `restyle(b)` : après le sol, retouche l'aspect de la carte (parois, murs d'intérieur,
##    abords et décor lointain des cartes extérieures) ;
##  - `object(b, type, o)` : les objets propres aux styles (maison blanche, tour, rempart, porte).
## Documentation : docs/FORMAT_DONNEES.md, section « Styles du chapitre 6 ».

const PA = preload("res://src/gfx/pixel_art.gd")
const MeshKit = preload("res://src/gfx/mesh_kit.gd")
const Atmosphere = preload("res://src/world/atmosphere.gd")
const Gouda = preload("res://src/gfx/gouda_painter.gd")

const OBJECTS: Array[String] = ["gou_maison", "gou_tour", "gou_rempart", "gou_porte"]

## Par style : sol des abords, falaises, marches, parois entre deux niveaux, mur d'intérieur,
## arbres ou décors plantés autour de la carte.
const STYLES := {
	"gouda": {"outer": "gou_herbe", "cliff": "gou_rempart", "stairs": "gou_dalle", "relief": "gou_rempart",
			"wall": "gou_mur", "cap": "#c8c4b8", "glow": 0.1, "trees": ["elf_pine"], "tree_count": 56, "low": ["grass", "chu_pierre"]},
	"veille": {"outer": "gou_veille", "cliff": "gou_mur_veille", "stairs": "gou_veille", "relief": "gou_mur_veille",
			"wall": "gou_mur_veille", "cap": "#0c1211", "glow": 0.2, "trees": ["gou_lit_pierre"], "tree_count": 10, "low": ["chu_pierre"]},
	"port": {"outer": "gou_quai", "cliff": "gou_rempart", "stairs": "gou_quai", "relief": "gou_rempart",
			"wall": "gou_mur", "cap": "#3a3a44", "glow": 0.05, "trees": ["gou_voile"], "tree_count": 22, "low": ["gou_baril", "gou_ancre", "chu_pierre"]},
	"champ": {"outer": "gou_herbe", "cliff": "gou_boue", "stairs": "gou_boue", "relief": "gou_boue",
			"wall": "gou_mur", "cap": "#5a4226", "glow": 0.0, "trees": ["tree"], "tree_count": 40, "low": ["grass", "gou_pieux", "gou_boulets"]},
}


static func is_gouda(b) -> bool:
	return STYLES.has(str(b.map.get("style", "")))


static func _spec(b) -> Dictionary:
	return STYLES.get(str(b.map.get("style", "")), STYLES["gouda"])


static func _node(b, node_name: String) -> MeshInstance3D:
	return b.world.get_node_or_null(node_name) as MeshInstance3D


# ===================================================================== retouche

static func restyle(b) -> void:
	var sp := _spec(b)
	var st := _node(b, "ReliefStairs")
	if st != null:
		st.material_override = MeshKit.pixel_material(Sprites.tile_texture(str(sp["stairs"])))
	var rw := _node(b, "ReliefWalls")
	if rw != null:
		rw.material_override = MeshKit.pixel_material(Sprites.tile_texture(str(sp["relief"])))
	var water := _node(b, "Water")
	if water != null:
		var wm := water.material_override as ShaderMaterial
		if wm != null:
			var spec: Dictionary = b.map.get("water", {})
			wm.set_shader_parameter("deep", Color(str(spec.get("deep", "#1a3a5a"))))
			wm.set_shader_parameter("shallow", Color(str(spec.get("shallow", "#4a8aa0"))))
			wm.set_shader_parameter("ripple", Color(str(spec.get("ripple", "#d8f0f4"))))
			wm.set_shader_parameter("glint", Color(str(spec.get("glint", "#ffffff"))))
	if bool(b.map.get("interior", false)):
		_restyle_interior(b, sp)
	else:
		_restyle_exterior(b, sp)


static func _restyle_interior(b, sp: Dictionary) -> void:
	var walls := _node(b, "Walls")
	if walls != null:
		var tex: Texture2D = Sprites.tile_texture(str(b.map.get("wall_tile", sp["wall"])))
		var m := MeshKit.pixel_material(tex)
		m.emission_enabled = true
		m.emission = Color.WHITE
		m.emission_operator = BaseMaterial3D.EMISSION_OP_ADD
		m.emission_texture = tex
		m.emission_energy_multiplier = float(b.map.get("wall_glow", sp["glow"]))
		walls.material_override = m
	var caps := _node(b, "WallCaps")
	if caps != null:
		caps.material_override = MeshKit.flat_material(Color(str(b.map.get("wall_cap", sp["cap"]))))


static func _restyle_exterior(b, sp: Dictionary) -> void:
	var outer := _node(b, "Outskirts")
	if outer != null:
		outer.material_override = MeshKit.ground_material(Sprites.tile_texture(str(sp["outer"])))
	var cliffs := _node(b, "Cliffs")
	if cliffs != null:
		cliffs.material_override = MeshKit.ground_material(Sprites.tile_texture(str(sp["cliff"])), 0.1)
	_surround(b, sp)


## Arbres ou décors plantés autour de la carte, puis un sous-bois bas.
static func _surround(b, sp: Dictionary) -> void:
	var rng: RandomNumberGenerator = b.rng
	var trees: Array = sp["trees"]
	var n := int(sp["tree_count"])
	for i in n:
		var p := Vector3.ZERO
		match i % 4:
			0: p = Vector3(rng.randf_range(-16.0, -0.9), 0.0, rng.randf_range(-1.0, float(b.h) + 6.0))
			1: p = Vector3(rng.randf_range(b.w + 0.9, b.w + 16.0), 0.0, rng.randf_range(-1.0, float(b.h) + 6.0))
			2: p = Vector3(rng.randf_range(-6.0, b.w + 6.0), 0.0, rng.randf_range(float(b.h) + 0.7, float(b.h) + 9.0))
			_: p = Vector3(rng.randf_range(-12.0, b.w + 12.0), 0.0, rng.randf_range(-12.0, -0.8))
		p.y = b._terrace_height(p.x, p.z)
		b._prop(str(trees[i % trees.size()]), {"solid": 0.0, "shadow": false, "scale": rng.randf_range(0.9, 1.25)}, p)
	var low: Array = sp["low"]
	for i in n:
		var p := Vector3(rng.randf_range(-12.0, b.w + 12.0), 0.0, rng.randf_range(-9.0, float(b.h) + 6.0))
		if p.x > 0.0 and p.x < b.w and p.z > 0.0 and p.z < b.h:
			continue
		p.y = b._terrace_height(p.x, p.z)
		b._prop(str(low[i % low.size()]), {"solid": 0.0, "shadow": false}, p)


# ========================================================================= objets

static func object(b, type: String, o: Dictionary) -> bool:
	match type:
		"gou_maison": _house(b, o)
		"gou_tour": _tower(b, o)
		"gou_rempart": _wall(b, o)
		"gou_porte": _gate(b, o)
		_: return false
	return true


static func _box_in(parent: Node3D, center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat
	node.position = center
	parent.add_child(node)
	return node


static func _stone_mat(wd: float, hgt: float) -> StandardMaterial3D:
	var m := MeshKit.pixel_material(Sprites.tile_texture("gou_rempart"))
	m.uv1_scale = Vector3(wd / 2.0, hgt / 2.0, 1.0)
	return m


## Maison blanche à toit d'ardoise. Champs : `rect` [x, z, largeur, profondeur] (pieds), `height`
## (4,2 : deux étages à partir de 5), `door` (abscisse de la porte dans la façade, -1 : sans),
## `windows` (abscisses des fenêtres), `lit` (vrai), `to` {map, spawn} (la porte mène à un intérieur)
## ou `dialogue` (la porte se lit), `chimney` (vrai). Bloque le passage.
static func _house(b, o: Dictionary) -> void:
	var r: Array = o.get("rect", [0, 0, 6, 4])
	var x0 := float(r[0])
	var z0 := float(r[1])
	var hw := float(r[2])
	var hd := float(r[3])
	var x1 := x0 + hw
	var z1 := z0 + hd
	var wh := float(o.get("height", 4.2))
	var door_x := float(o.get("door", hw * 0.5))
	var windows: Array = o.get("windows", [hw * 0.2, hw * 0.8])
	var lit := bool(o.get("lit", true))
	var enter: bool = o.get("to") is Dictionary
	var parent := Node3D.new()
	parent.name = "GoudaMaison"
	b.world.add_child(parent)
	var parts: Array = []
	var st := MeshKit.begin()
	MeshKit.box(st, Vector3((x0 + x1) * 0.5, wh * 0.5, (z0 + z1) * 0.5), Vector3(hw, wh, hd))
	var body := MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture("gou_rempart")))
	parent.add_child(body)
	parts.append(body)
	var front: Dictionary = Sprites.cached("gfront:%s:%s:%s" % [str(b.map.get("id", "")), str(r), str(enter)], func() -> Dictionary:
		var f := Gouda.facade(hw, wh, door_x, windows, lit, enter)
		return {"albedo": PA.texture(f["albedo"]), "emission": PA.texture(f["emission"])})
	st = MeshKit.begin()
	MeshKit.quad(st, Vector3(x0, wh, z1 + 0.02), Vector3(x1, wh, z1 + 0.02), Vector3(x1, 0, z1 + 0.02), Vector3(x0, 0, z1 + 0.02))
	var face := MeshKit.finish(st, MeshKit.pixel_material(front["albedo"], front["emission"], 2.0))
	parent.add_child(face)
	parts.append(face)
	# toit d'ardoise à deux pentes, faîtage le long de la façade
	var ov := 0.5
	var rh := minf(hd * 0.5 + ov, 2.6)
	var top := wh + rh
	var xl := x0 - ov
	var xr := x1 + ov
	var zf := z0 - ov
	var zb := z1 + ov
	var zm := (z0 + z1) * 0.5
	var ye := wh - 0.2
	var slope := Vector2(zb - zm, rh + 0.2).length() / 2.0
	st = MeshKit.begin()
	MeshKit.quad(st, Vector3(xl, top, zm), Vector3(xr, top, zm), Vector3(xr, ye, zb), Vector3(xl, ye, zb), Vector2.ZERO, Vector2((xr - xl) / 2.0, slope))
	MeshKit.quad(st, Vector3(xr, top, zm), Vector3(xl, top, zm), Vector3(xl, ye, zf), Vector3(xr, ye, zf), Vector2.ZERO, Vector2((xr - xl) / 2.0, slope))
	MeshKit.tri(st, Vector3(xl, ye, zf), Vector3(xl, top, zm), Vector3(xl, ye, zb), Vector2(0, slope), Vector2(slope * 0.5, 0), Vector2(slope * 2.0, slope))
	MeshKit.tri(st, Vector3(xr, ye, zb), Vector3(xr, top, zm), Vector3(xr, ye, zf), Vector2(0, slope), Vector2(slope * 0.5, 0), Vector2(slope * 2.0, slope))
	var roof_mat := MeshKit.pixel_material(Sprites.tile_texture("gou_ardoise"))
	roof_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var roof := MeshKit.finish(st, roof_mat)
	parent.add_child(roof)
	parts.append(roof)
	parts.append(_box_in(parent, Vector3((xl + xr) * 0.5, top + 0.05, zm), Vector3(xr - xl, 0.14, 0.18), MeshKit.flat_material(Color("#d8d4c8"))))
	if bool(o.get("chimney", true)):
		parts.append(_box_in(parent, Vector3(x0 + hw * 0.78, top + 0.1, zm - 0.3), Vector3(0.5, 1.2, 0.5), _stone_mat(0.5, 1.2)))
	b.world.rects.append(Rect2(x0, z0, hw, hd))
	if lit:
		for wx: Variant in windows:
			b._add_light(Vector3(x0 + float(wx), 1.4, z1 + 0.7), Color("#ffe4ae"), 0.8, 3.4, false)
	if door_x >= 0.0:
		var xd := x0 + door_x
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


## Tour carrée à créneaux et chapeau d'ardoise. Champs : `pos` (centre du pied), `size` (3),
## `height` (7), `cap` (vrai : toit pointu ; faux : terrasse crénelée). Bloque le passage.
static func _tower(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var sz := float(o.get("size", 3.0))
	var hgt := float(o.get("height", 7.0))
	var parent := Node3D.new()
	parent.name = "GoudaTour"
	b.world.add_child(parent)
	var parts: Array = []
	parts.append(_box_in(parent, p + Vector3(0.0, hgt * 0.5, 0.0), Vector3(sz, hgt, sz), _stone_mat(sz, hgt)))
	parts.append(_box_in(parent, p + Vector3(0.0, hgt + 0.1, 0.0), Vector3(sz + 0.5, 0.25, sz + 0.5), MeshKit.flat_material(Color("#b8b4a8"))))
	var dark := MeshKit.flat_material(Color("#1c2234"))
	for k in 3:   # meurtrières allumées
		parts.append(_box_in(parent, p + Vector3(0.0, 1.8 + k * 1.9, sz * 0.5 + 0.02), Vector3(0.28, 0.9, 0.06), dark))
	if bool(o.get("cap", true)):
		var st := MeshKit.begin()
		var a := Vector3(p.x, p.y + hgt + 2.6, p.z)
		var h2 := sz * 0.5 + 0.35
		var y0 := p.y + hgt + 0.25
		MeshKit.tri(st, Vector3(p.x - h2, y0, p.z + h2), a, Vector3(p.x + h2, y0, p.z + h2), Vector2(0, 2), Vector2(1, 0), Vector2(2, 2))
		MeshKit.tri(st, Vector3(p.x + h2, y0, p.z - h2), a, Vector3(p.x - h2, y0, p.z - h2), Vector2(0, 2), Vector2(1, 0), Vector2(2, 2))
		MeshKit.tri(st, Vector3(p.x - h2, y0, p.z - h2), a, Vector3(p.x - h2, y0, p.z + h2), Vector2(0, 2), Vector2(1, 0), Vector2(2, 2))
		MeshKit.tri(st, Vector3(p.x + h2, y0, p.z + h2), a, Vector3(p.x + h2, y0, p.z - h2), Vector2(0, 2), Vector2(1, 0), Vector2(2, 2))
		var mat := MeshKit.pixel_material(Sprites.tile_texture("gou_ardoise"))
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var cap := MeshKit.finish(st, mat)
		parent.add_child(cap)
		parts.append(cap)
		parts.append(_box_in(parent, a + Vector3(0.0, 0.5, 0.0), Vector3(0.06, 1.0, 0.06), MeshKit.flat_material(Color("#e8c050"))))
	else:
		var m := _stone_mat(0.6, 0.6)
		for ix in 3:
			for iz in 3:
				if ix == 1 and iz == 1:
					continue
				parts.append(_box_in(parent, p + Vector3((ix - 1) * (sz * 0.5 - 0.1), hgt + 0.55, (iz - 1) * (sz * 0.5 - 0.1)), Vector3(0.5, 0.6, 0.5), m))
	b.world.rects.append(Rect2(p.x - sz * 0.5, p.z - sz * 0.5, sz, sz))
	b.world.occluders.append({"rect": Rect2(p.x - sz * 0.5, p.z - sz * 0.5, sz, sz), "nodes": parts, "fade": 0.0})


## Rempart crénelé le long d'une ligne brisée de segments horizontaux ou verticaux. Champs :
## `points`, `height` (2,4), `thick` (0,9). Bloque le passage.
static func _wall(b, o: Dictionary) -> void:
	var pts: Array = o.get("points", [])
	var hgt := float(o.get("height", 2.4))
	var th := float(o.get("thick", 0.9))
	var st := MeshKit.begin()
	for i in range(pts.size() - 1):
		var pa: Array = pts[i]
		var pc: Array = pts[i + 1]
		var a := Vector2(float(pa[0]), float(pa[1]))
		var c := Vector2(float(pc[0]), float(pc[1]))
		var lo := Vector2(minf(a.x, c.x), minf(a.y, c.y))
		var hi := Vector2(maxf(a.x, c.x), maxf(a.y, c.y))
		var base: float = b.world.ground_y((a.x + c.x) * 0.5, (a.y + c.y) * 0.5)
		var size := Vector3(maxf(hi.x - lo.x, th), hgt, maxf(hi.y - lo.y, th))
		var center := Vector3((lo.x + hi.x) * 0.5, base + hgt * 0.5, (lo.y + hi.y) * 0.5)
		MeshKit.box(st, center, size)
		var length := maxf(size.x, size.z)
		var n := int(length / 1.3)
		for k in range(n + 1):
			var t := float(k) / float(maxi(1, n))
			var q := Vector2(lerpf(lo.x, hi.x, t), lerpf(lo.y, hi.y, t))
			MeshKit.box(st, Vector3(q.x, base + hgt + 0.25, q.y), Vector3(0.62, 0.5, 0.62))
		b.world.rects.append(Rect2(center.x - size.x * 0.5, center.z - size.z * 0.5, size.x, size.z))
	var node := MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture("gou_rempart")))
	node.name = "GoudaRempart"
	b.world.add_child(node)


## Grande Porte : deux tours, un linteau et un porche sombre où l'on passe (herse relevée).
## Champs : `pos` (centre du pied), `gap` (largeur du passage, 3), `height` (6). Seuls les
## deux piliers bloquent le passage.
static func _gate(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var gap := float(o.get("gap", 3.0))
	var hgt := float(o.get("height", 6.0))
	var tw := 3.0
	var parent := Node3D.new()
	parent.name = "GoudaPorte"
	b.world.add_child(parent)
	for s: float in [-1.0, 1.0]:
		var cx := p.x + s * (gap * 0.5 + tw * 0.5)
		_box_in(parent, Vector3(cx, p.y + hgt * 0.5, p.z), Vector3(tw, hgt, 2.4), _stone_mat(tw, hgt))
		_box_in(parent, Vector3(cx, p.y + hgt + 0.15, p.z), Vector3(tw + 0.5, 0.3, 2.9), MeshKit.flat_material(Color("#b8b4a8")))
		for k in 3:
			_box_in(parent, Vector3(cx + (k - 1) * 1.0, p.y + hgt + 0.55, p.z + 1.2), Vector3(0.6, 0.6, 0.5), _stone_mat(0.6, 0.6))
		b.world.rects.append(Rect2(cx - tw * 0.5, p.z - 1.2, tw, 2.4))
	_box_in(parent, Vector3(p.x, p.y + hgt - 0.7, p.z), Vector3(gap + 0.2, 1.4, 2.4), _stone_mat(gap, 1.4))
	_box_in(parent, Vector3(p.x, p.y + hgt + 0.15, p.z), Vector3(gap + 0.4, 0.3, 2.9), MeshKit.flat_material(Color("#b8b4a8")))
	var wood := MeshKit.flat_material(Color("#3a2a1c"))
	for k in 5:   # herse relevée sous le linteau
		_box_in(parent, Vector3(p.x - gap * 0.4 + k * gap * 0.2, p.y + hgt - 1.6, p.z + 0.4), Vector3(0.1, 0.8, 0.1), wood)
	var banner := MeshKit.flat_material(Color("#27365e"))
	_box_in(parent, Vector3(p.x, p.y + hgt - 2.6, p.z + 1.25), Vector3(1.0, 1.6, 0.05), banner)
	_box_in(parent, Vector3(p.x, p.y + hgt - 2.4, p.z + 1.29), Vector3(0.12, 0.5, 0.03), MeshKit.flat_material(Color("#f4f0e4")))
	_box_in(parent, Vector3(p.x, p.y + hgt - 2.0, p.z + 1.29), Vector3(0.5, 0.4, 0.03), MeshKit.flat_material(Color("#f4f0e4")))
	for s: float in [-1.0, 1.0]:
		var torch := Atmosphere.make_light(Color("#ffc870"), 1.6, 5.5, false, 0.2)
		torch.position = Vector3(p.x + s * (gap * 0.5 + 0.4), p.y + 2.2, p.z + 1.6)
		parent.add_child(torch)
