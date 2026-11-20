extends RefCounted
## Styles du chapitre 7, le pays ennemi : « marais » (Bouillon d'Onze Heures, planches sur la vase),
## « mordgras » (Passe-Plat, Quatre Mille Marches, Grand Four : basalte noir et braise), « toile »
## (col de l'Arachnée) et « festin » (cuisines et salle du banquet de la Tour de la Barbaque).
## Un seul constructeur les sert tous ; chaque style choisit ses textures et son décor d'abords
## dans la table STYLES. Rien ici ne s'applique à une carte sans l'un de ces champs `style`.
##
## Le constructeur de cartes (MapBuilder) délègue ici :
##  - `restyle(b)` : après le sol, retouche l'aspect de la carte (parois, murs d'intérieur, abords) ;
##  - `object(b, type, o)` : les objets propres aux styles (tour, porte, four).
## Documentation : docs/FORMAT_DONNEES.md, section « Styles du chapitre 7 ».

const PA = preload("res://src/gfx/pixel_art.gd")
const MeshKit = preload("res://src/gfx/mesh_kit.gd")
const Atmosphere = preload("res://src/world/atmosphere.gd")

const OBJECTS: Array[String] = ["mor_tour", "mor_porte", "mor_four"]

const STYLES := {
	"marais": {"outer": "mor_vase", "cliff": "mor_roche", "stairs": "mor_planches", "relief": "mor_roche",
			"wall": "mor_mur", "cap": "#0c0a10", "glow": 0.0, "trees": ["deadtree"], "tree_count": 60, "low": ["mor_roseau", "reeds", "mor_roseau"]},
	"mordgras": {"outer": "mor_cendre", "cliff": "mor_roche", "stairs": "mor_marche", "relief": "mor_roche",
			"wall": "mor_mur", "cap": "#0c0a10", "glow": 0.1, "trees": ["mor_pique", "mor_lanterne"], "tree_count": 26, "low": ["rock", "mor_os"]},
	"toile": {"outer": "mor_roche", "cliff": "mor_roche", "stairs": "mor_roche", "relief": "mor_roche",
			"wall": "mor_mur", "cap": "#0a0a10", "glow": 0.0, "trees": ["deadtree", "mor_cocon"], "tree_count": 50, "low": ["rock", "mor_os", "mushrooms"]},
	"festin": {"outer": "mor_roche", "cliff": "mor_roche", "stairs": "mor_marche", "relief": "mor_roche",
			"wall": "mor_mur_cuisine", "cap": "#2a2018", "glow": 0.2, "trees": ["mor_cheminee"], "tree_count": 16, "low": ["mor_marmite", "mor_os"]},
}


static func is_mordgras(b) -> bool:
	return STYLES.has(str(b.map.get("style", "")))


static func _spec(b) -> Dictionary:
	return STYLES.get(str(b.map.get("style", "")), STYLES["mordgras"])


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
			wm.set_shader_parameter("deep", Color(str(spec.get("deep", "#14221c"))))
			wm.set_shader_parameter("shallow", Color(str(spec.get("shallow", "#3a5a40"))))
			wm.set_shader_parameter("ripple", Color(str(spec.get("ripple", "#a8c0a0"))))
			wm.set_shader_parameter("glint", Color(str(spec.get("glint", "#e8f0d8"))))
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


## Arbres morts, piques ou cocons plantés autour de la carte, puis un décor bas.
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
		"mor_tour": _tower(b, o)
		"mor_porte": _gate(b, o)
		"mor_four": _furnace(b, o)
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


## Tour de basalte surmontée de piques et d'une fenêtre rougeoyante (l'Œil, de loin, ou une cuisine).
## Champs : `pos`, `size` [largeur, profondeur] (4, 4), `height` (9). Bloque le passage.
static func _tower(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var sz: Array = o.get("size", [4.0, 4.0])
	var wd := float(sz[0])
	var dp := float(sz[1])
	var hgt := float(o.get("height", 9.0))
	var parent := Node3D.new()
	parent.name = "MorTour"
	b.world.add_child(parent)
	var wall := MeshKit.pixel_material(Sprites.tile_texture("mor_mur"))
	wall.uv1_scale = Vector3(wd / 2.0, hgt / 3.0, 1.0)
	_box_in(parent, p + Vector3(0.0, hgt * 0.5, 0.0), Vector3(wd, hgt, dp), wall)
	var top := MeshKit.flat_material(Color("#1a1620"))
	_box_in(parent, p + Vector3(0.0, hgt + 0.3, 0.0), Vector3(wd + 0.8, 0.6, dp + 0.8), top)
	for k in 4:
		var sx := -wd * 0.5 + wd * float(k) / 3.0
		_box_in(parent, p + Vector3(sx, hgt + 1.2, 0.0), Vector3(0.18, 1.2, 0.18), MeshKit.flat_material(Color("#3a3646")))
	var glow := MeshKit.flat_material(Color("#ff7a30"))
	glow.emission_enabled = true
	glow.emission = Color("#ff7a30")
	glow.emission_energy_multiplier = 2.0
	_box_in(parent, p + Vector3(0.0, hgt * 0.72, dp * 0.5 + 0.03), Vector3(0.7, 1.4, 0.06), glow)
	var light := Atmosphere.make_light(Color("#ff7a30"), 1.6, 8.0, false, 0.2)
	light.position = p + Vector3(0.0, hgt * 0.72, dp * 0.5 + 1.0)
	parent.add_child(light)
	b.world.rects.append(Rect2(p.x - wd * 0.5, p.z - dp * 0.5, wd, dp))


## Porte Noire : deux piliers, linteau, battants de fonte avec un guichet. Champs : `pos`, `width` (4),
## `height` (5), `open` (faux : les battants sont fermés et bloquent le passage ; vrai : laisse passer).
static func _gate(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var wd := float(o.get("width", 4.0))
	var hgt := float(o.get("height", 5.0))
	var parent := Node3D.new()
	parent.name = "MorPorte"
	b.world.add_child(parent)
	var stone := MeshKit.pixel_material(Sprites.tile_texture("mor_mur"))
	stone.uv1_scale = Vector3(1.0, hgt / 3.0, 1.0)
	_box_in(parent, p + Vector3(-wd * 0.5 - 0.6, hgt * 0.5, 0.0), Vector3(1.2, hgt, 1.6), stone)
	_box_in(parent, p + Vector3(wd * 0.5 + 0.6, hgt * 0.5, 0.0), Vector3(1.2, hgt, 1.6), stone)
	var lintel := MeshKit.pixel_material(Sprites.tile_texture("mor_mur"))
	lintel.uv1_scale = Vector3(wd / 2.0, 0.5, 1.0)
	_box_in(parent, p + Vector3(0.0, hgt + 0.5, 0.0), Vector3(wd + 2.4, 1.0, 1.6), lintel)
	var iron := MeshKit.flat_material(Color("#26222e"))
	if not bool(o.get("open", false)):
		_box_in(parent, p + Vector3(0.0, hgt * 0.5, 0.0), Vector3(wd, hgt, 0.3), iron)
		var glow := MeshKit.flat_material(Color("#ffb060"))
		glow.emission_enabled = true
		glow.emission = Color("#ff9a40")
		glow.emission_energy_multiplier = 1.6
		_box_in(parent, p + Vector3(0.0, hgt * 0.55, 0.17), Vector3(0.6, 0.4, 0.06), glow)   # le guichet
		b.world.rects.append(Rect2(p.x - wd * 0.5, p.z - 0.2, wd, 0.4))
	b.world.rects.append(Rect2(p.x - wd * 0.5 - 1.2, p.z - 0.8, 1.2, 1.6))
	b.world.rects.append(Rect2(p.x + wd * 0.5, p.z - 0.8, 1.2, 1.6))


## Gueule du Grand Four : bloc de fonte noir, bouche rougeoyante, flammes et braises. Champs : `pos`,
## `width` (8), `height` (6).
static func _furnace(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var wd := float(o.get("width", 8.0))
	var hgt := float(o.get("height", 6.0))
	var parent := Node3D.new()
	parent.name = "MorFour"
	b.world.add_child(parent)
	var wall := MeshKit.pixel_material(Sprites.tile_texture("mor_mur"))
	wall.uv1_scale = Vector3(wd / 2.0, hgt / 3.0, 1.0)
	_box_in(parent, p + Vector3(0.0, hgt * 0.5, 0.0), Vector3(wd, hgt, 2.0), wall)
	var mouth := MeshKit.flat_material(Color("#ff6a20"))
	mouth.emission_enabled = true
	mouth.emission = Color("#ff6a20")
	mouth.emission_energy_multiplier = 2.4
	_box_in(parent, p + Vector3(0.0, hgt * 0.3, 1.02), Vector3(wd * 0.5, hgt * 0.45, 0.06), mouth)
	for k in 2:
		var fire := Atmosphere.make_particles("fire")
		if fire != null:
			fire.position = p + Vector3(float(k * 2 - 1) * wd * 0.15, 0.4, 1.4)
			b.world.add_child(fire)
	var embers := Atmosphere.make_particles("embers")
	if embers != null:
		embers.position = p + Vector3(0.0, 1.0, 1.6)
		b.world.add_child(embers)
	var light := Atmosphere.make_light(Color("#ff6a28"), 3.4, 14.0, false, 0.3)
	light.position = p + Vector3(0.0, 2.0, 2.4)
	b.world.add_child(light)
	b.world.rects.append(Rect2(p.x - wd * 0.5, p.z - 1.0, wd, 2.0))
