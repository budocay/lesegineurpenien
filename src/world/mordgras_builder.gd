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

const OBJECTS: Array[String] = ["mor_tour", "mor_porte", "mor_four", "mor_mur", "mor_banniere", "mor_pilier", "mor_lustre"]

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


## Porte Noire : deux pylônes à braseros, linteau crénelé, bannières, battants de fonte avec un guichet de
## braise. Champs : `pos`, `width` (4), `height` (5), `open` (faux : les battants sont fermés et bloquent le
## passage ; vrai : laisse passer), `pylon` (largeur des pylônes, 1,2 ; plus de 2 pour une porte monumentale).
static func _gate(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var wd := float(o.get("width", 4.0))
	var hgt := float(o.get("height", 5.0))
	var pw := float(o.get("pylon", 1.2))
	var parent := Node3D.new()
	parent.name = "MorPorte"
	b.world.add_child(parent)
	var stone := MeshKit.pixel_material(Sprites.tile_texture("mor_mur"))
	stone.uv1_scale = Vector3(pw / 2.0, hgt / 3.0, 1.0)
	var rim := MeshKit.flat_material(Color("#2a2030"))
	var dark := MeshKit.flat_material(Color("#14101a"))
	var depth := 1.6 + (pw - 1.2) * 0.8
	for sx: float in [-1.0, 1.0]:
		var cx := sx * (wd * 0.5 + pw * 0.5)
		_box_in(parent, p + Vector3(cx, hgt * 0.5, 0.0), Vector3(pw, hgt, depth), stone)
		if pw > 2.0:   # pylône monumental : corniche, pointes et brasero
			_box_in(parent, p + Vector3(cx, hgt + 0.3, 0.0), Vector3(pw + 0.8, 0.6, depth + 0.8), rim)
			for k in 3:
				var kx := cx + (float(k) - 1.0) * pw * 0.32
				_box_in(parent, p + Vector3(kx, hgt + 1.5 + float(k % 2) * 0.5, 0.0), Vector3(0.3, 1.8 + float(k % 2), 0.3), dark)
			var bowl := MeshKit.flat_material(Color("#ff7a20"))
			bowl.emission_enabled = true
			bowl.emission = Color("#ff7a20")
			bowl.emission_energy_multiplier = 2.4
			_box_in(parent, p + Vector3(cx, hgt * 0.55, depth * 0.5 + 0.7), Vector3(0.9, 0.3, 0.9), bowl)
			_box_in(parent, p + Vector3(cx, hgt * 0.55 - 0.7, depth * 0.5 + 0.7), Vector3(0.3, 1.4, 0.3), dark)
			var fire := Atmosphere.make_particles("fire")
			if fire != null:
				fire.position = p + Vector3(cx, hgt * 0.55 + 0.2, depth * 0.5 + 0.7)
				fire.scale = Vector3(2.2, 2.2, 2.2)
				b.world.add_child(fire)
			var bl := Atmosphere.make_light(Color("#ff7a30"), 2.4, 12.0, false, 0.35)
			bl.position = p + Vector3(cx, hgt * 0.55 + 1.0, depth * 0.5 + 1.6)
			b.world.add_child(bl)
			# bannière : une longue étoffe rouge à l'emblème noir
			var cloth := MeshKit.flat_material(Color("#7a1420"))
			_box_in(parent, p + Vector3(cx, hgt * 0.72, depth * 0.5 + 0.04), Vector3(pw * 0.5, hgt * 0.42, 0.06), cloth)
			_box_in(parent, p + Vector3(cx, hgt * 0.74, depth * 0.5 + 0.08), Vector3(pw * 0.2, hgt * 0.14, 0.04), dark)
	var lintel := MeshKit.pixel_material(Sprites.tile_texture("mor_mur"))
	lintel.uv1_scale = Vector3(wd / 2.0, 0.5 + (pw - 1.2) * 0.5, 1.0)
	var lh := 1.0 + (pw - 1.2) * 0.9
	_box_in(parent, p + Vector3(0.0, hgt + lh * 0.5, 0.0), Vector3(wd + pw * 2.0, lh, depth), lintel)
	if pw > 2.0:
		# créneaux sur le linteau et grand œil de braise au centre
		var mn := int((wd + pw * 2.0) / 1.4)
		for k in mn:
			if k % 2 == 0:
				_box_in(parent, p + Vector3(-(wd + pw * 2.0) * 0.5 + 0.7 + float(k) * 1.4, hgt + lh + 0.4, 0.0), Vector3(0.9, 0.8, depth), rim)
		var eye := MeshKit.flat_material(Color("#ff8a20"))
		eye.emission_enabled = true
		eye.emission = Color("#ff8a20")
		eye.emission_energy_multiplier = 3.0
		_box_in(parent, p + Vector3(0.0, hgt + lh * 0.5, depth * 0.5 + 0.03), Vector3(2.2, 0.5, 0.05), eye)
		_box_in(parent, p + Vector3(0.0, hgt + lh * 0.5, depth * 0.5 + 0.06), Vector3(0.3, 0.7, 0.05), dark)
		var gl := Atmosphere.make_light(Color("#ff6a28"), 3.0, 20.0, false, 0.3)
		gl.position = p + Vector3(0.0, hgt * 0.6, depth * 0.5 + 4.0)
		b.world.add_child(gl)
	var iron := MeshKit.flat_material(Color("#26222e"))
	if not bool(o.get("open", false)):
		_box_in(parent, p + Vector3(0.0, hgt * 0.5, 0.0), Vector3(wd, hgt, 0.3), iron)
		# traverses de fonte, clous et guichet de braise
		var ribs := int(hgt / 1.6)
		for k in ribs:
			_box_in(parent, p + Vector3(0.0, 0.8 + float(k) * 1.6, 0.2), Vector3(wd, 0.22, 0.1), rim)
		_box_in(parent, p + Vector3(0.0, hgt * 0.5, 0.2), Vector3(0.18, hgt, 0.1), rim)
		var glow := MeshKit.flat_material(Color("#ffb060"))
		glow.emission_enabled = true
		glow.emission = Color("#ff9a40")
		glow.emission_energy_multiplier = 1.6
		_box_in(parent, p + Vector3(0.0, hgt * 0.55, 0.27), Vector3(0.6 + (pw - 1.2) * 0.4, 0.4 + (pw - 1.2) * 0.3, 0.06), glow)   # le guichet
		b.world.rects.append(Rect2(p.x - wd * 0.5, p.z - 0.2, wd, 0.4))
	b.world.rects.append(Rect2(p.x - wd * 0.5 - pw, p.z - depth * 0.5, pw, depth))
	b.world.rects.append(Rect2(p.x + wd * 0.5, p.z - depth * 0.5, pw, depth))


## Rempart de basalte crénelé. Champs : `pos` (centre), `size` [longueur, épaisseur] (8, 2), `height` (7).
static func _rampart(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var sz: Array = o.get("size", [8.0, 2.0])
	var wd := float(sz[0])
	var dp := float(sz[1])
	var hgt := float(o.get("height", 7.0))
	var parent := Node3D.new()
	parent.name = "MorMur"
	b.world.add_child(parent)
	var wall := MeshKit.pixel_material(Sprites.tile_texture("mor_mur"))
	wall.uv1_scale = Vector3(wd / 2.0, hgt / 3.0, 1.0)
	_box_in(parent, p + Vector3(0.0, hgt * 0.5, 0.0), Vector3(wd, hgt, dp), wall)
	var rim := MeshKit.flat_material(Color("#2a2030"))
	_box_in(parent, p + Vector3(0.0, hgt + 0.25, 0.0), Vector3(wd + 0.4, 0.5, dp + 0.5), rim)
	var n := int(wd / 1.4)
	for k in n:
		if k % 2 == 0:
			_box_in(parent, p + Vector3(-wd * 0.5 + 0.7 + float(k) * wd / float(n), hgt + 0.9, dp * 0.35), Vector3(0.9, 0.8, 0.5), rim)
	# meurtrières de braise
	var slit := MeshKit.flat_material(Color("#ff8a30"))
	slit.emission_enabled = true
	slit.emission = Color("#ff8a30")
	slit.emission_energy_multiplier = 2.0
	var ns := int(wd / 5.0)
	for k in ns:
		_box_in(parent, p + Vector3(-wd * 0.5 + (float(k) + 0.5) * wd / float(ns), hgt * 0.62, dp * 0.5 + 0.03), Vector3(0.22, 1.1, 0.05), slit)
	b.world.rects.append(Rect2(p.x - wd * 0.5, p.z - dp * 0.5, wd, dp))


## Gueule du Grand Four : un fronton de fonte noire, une gueule à dents sur trois couches de braise (orange,
## jaune, blanc), deux cheminées qui fument, deux piliers à brasero, un bassin de lave au pied, des flammes,
## des braises et trois lumières qui vacillent. Champs : `pos`, `width` (8), `height` (6).
static func _furnace(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var wd := float(o.get("width", 8.0))
	var hgt := float(o.get("height", 6.0))
	var parent := Node3D.new()
	parent.name = "MorFour"
	b.world.add_child(parent)
	var wall := MeshKit.pixel_material(Sprites.tile_texture("mor_mur"))
	wall.uv1_scale = Vector3(wd / 2.0, hgt / 3.0, 1.0)
	_box_in(parent, p + Vector3(0.0, hgt * 0.5, 0.0), Vector3(wd, hgt, 3.0), wall)
	var dark := MeshKit.flat_material(Color("#14101a"))
	var rim := MeshKit.flat_material(Color("#2a2030"))
	# fronton et corniche
	_box_in(parent, p + Vector3(0.0, hgt + 0.35, 0.3), Vector3(wd + 1.2, 0.7, 3.8), rim)
	_box_in(parent, p + Vector3(0.0, hgt * 0.84, 1.55), Vector3(wd * 0.78, 0.5, 0.3), rim)
	# les trois couches de la gueule : orange, jaune, blanc
	var layers: Array = [[0.56, 0.58, "#ff5a14", 2.6], [0.44, 0.48, "#ffa530", 3.2], [0.26, 0.32, "#fff0b0", 3.0]]
	var z := 1.52
	for L: Array in layers:
		var m := MeshKit.flat_material(Color(str(L[2])))
		m.emission_enabled = true
		m.emission = Color(str(L[2]))
		m.emission_energy_multiplier = float(L[3])
		_box_in(parent, p + Vector3(0.0, hgt * (0.06 + float(L[1]) * 0.5), z), Vector3(wd * float(L[0]), hgt * float(L[1]), 0.06), m)
		z += 0.02
	# dents : en haut elles pendent, en bas elles montent
	var mw := wd * 0.56
	var tooth_n := int(mw / 0.9)
	for k in tooth_n:
		var tx := -mw * 0.5 + mw * (float(k) + 0.5) / float(tooth_n)
		var th := 1.2 + float(k % 3) * 0.35
		_box_in(parent, p + Vector3(tx, hgt * 0.64 - th * 0.5, 1.6), Vector3(0.42, th, 0.3), dark)
		_box_in(parent, p + Vector3(tx + 0.3, hgt * 0.06 + 0.35, 1.6), Vector3(0.36, 0.7 + float((k + 1) % 3) * 0.22, 0.3), dark)
	# piliers à brasero
	for sx: float in [-1.0, 1.0]:
		var px := wd * 0.5 * sx + sx * 1.2
		_box_in(parent, p + Vector3(px, hgt * 0.32, 1.6), Vector3(1.4, hgt * 0.64, 1.4), wall)
		_box_in(parent, p + Vector3(px, hgt * 0.64 + 0.25, 1.6), Vector3(1.9, 0.5, 1.9), rim)
		var bowl := MeshKit.flat_material(Color("#ff7a20"))
		bowl.emission_enabled = true
		bowl.emission = Color("#ff7a20")
		bowl.emission_energy_multiplier = 2.4
		_box_in(parent, p + Vector3(px, hgt * 0.64 + 0.62, 1.6), Vector3(1.3, 0.25, 1.3), bowl)
		var fire := Atmosphere.make_particles("fire")
		if fire != null:
			fire.position = p + Vector3(px, hgt * 0.64 + 0.7, 1.6)
			fire.scale = Vector3(2.4, 2.4, 2.4)
			b.world.add_child(fire)
		var bl := Atmosphere.make_light(Color("#ff7a30"), 2.2, 11.0, false, 0.35)
		bl.position = p + Vector3(px, hgt * 0.64 + 1.8, 2.4)
		b.world.add_child(bl)
	# cheminées
	for sx: float in [-1.0, 1.0]:
		var cxp := wd * 0.3 * sx
		_box_in(parent, p + Vector3(cxp, hgt + 1.9, -0.2), Vector3(2.2, 3.4, 2.2), wall)
		_box_in(parent, p + Vector3(cxp, hgt + 3.8, -0.2), Vector3(2.8, 0.5, 2.8), rim)
		var smoke := Atmosphere.make_particles("smoke")
		if smoke != null:
			smoke.position = p + Vector3(cxp, hgt + 4.2, -0.2)
			smoke.amount = 40
			smoke.lifetime = 9.0
			smoke.preprocess = 9.0
			smoke.scale = Vector3(5.0, 5.0, 5.0)
			smoke.initial_velocity_min = 1.2
			smoke.initial_velocity_max = 2.0
			b.world.add_child(smoke)
	# flammes de la gueule
	var nf := int(wd / 3.0)
	for k in nf:
		var fire := Atmosphere.make_particles("fire")
		if fire != null:
			fire.position = p + Vector3(-mw * 0.4 + mw * 0.8 * (float(k) + 0.5) / float(nf), hgt * 0.1, 1.5)
			fire.scale = Vector3(4.0, 4.0, 4.0)
			fire.amount = 34
			fire.initial_velocity_min = 1.4
			fire.initial_velocity_max = 2.8
			b.world.add_child(fire)
	var embers := Atmosphere.make_particles("embers")
	if embers != null:
		embers.position = p + Vector3(0.0, 1.0, 3.0)
		embers.amount = 90
		embers.lifetime = 5.0
		embers.preprocess = 5.0
		embers.emission_box_extents = Vector3(wd * 0.45, 0.2, 2.4)
		embers.initial_velocity_min = 0.8
		embers.initial_velocity_max = 2.4
		embers.scale = Vector3(1.8, 1.8, 1.8)
		b.world.add_child(embers)
	# bassin de lave au pied de la gueule
	var lava := MeshKit.flat_material(Color("#ff5a10"))
	lava.emission_enabled = true
	lava.emission = Color("#ff5a10")
	lava.emission_energy_multiplier = 1.8
	_box_in(parent, p + Vector3(0.0, 0.03, 3.1), Vector3(wd * 0.9, 0.05, 1.6), lava)
	# lumières : cœur, deux flancs
	var light := Atmosphere.make_light(Color("#ff6a28"), 5.0, 26.0, false, 0.3)
	light.position = p + Vector3(0.0, hgt * 0.3, 4.0)
	b.world.add_child(light)
	for sx: float in [-1.0, 1.0]:
		var sl := Atmosphere.make_light(Color("#ff8a40"), 2.6, 14.0, false, 0.25)
		sl.position = p + Vector3(wd * 0.36 * sx, 2.4, 5.0)
		b.world.add_child(sl)
	b.world.rects.append(Rect2(p.x - wd * 0.5, p.z - 1.5, wd, 3.0))


## Bannière plaquée au mur du nord : étoffe, galon noir, emblème de braise. Champs : `pos` (pied, contre le mur),
## `width` (1,6), `height` (4), `base` (hauteur du bas, 1,2), `color` (rouge sombre).
static func _banner(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var wd := float(o.get("width", 1.6))
	var hgt := float(o.get("height", 4.0))
	var base := float(o.get("base", 1.2))
	var parent := Node3D.new()
	parent.name = "MorBanniere"
	b.world.add_child(parent)
	var cloth := MeshKit.flat_material(Color(str(o.get("color", "#7a1420"))))
	var trim := MeshKit.flat_material(Color("#16101a"))
	_box_in(parent, p + Vector3(0.0, base + hgt * 0.5, 0.06), Vector3(wd, hgt, 0.08), cloth)
	_box_in(parent, p + Vector3(0.0, base + hgt + 0.08, 0.08), Vector3(wd + 0.3, 0.14, 0.12), trim)
	_box_in(parent, p + Vector3(0.0, base + 0.1, 0.08), Vector3(wd, 0.2, 0.1), trim)
	var ember := MeshKit.flat_material(Color("#ff9a30"))
	ember.emission_enabled = true
	ember.emission = Color("#ff9a30")
	ember.emission_energy_multiplier = 1.6
	_box_in(parent, p + Vector3(0.0, base + hgt * 0.58, 0.12), Vector3(wd * 0.34, hgt * 0.22, 0.04), ember)
	_box_in(parent, p + Vector3(0.0, base + hgt * 0.58, 0.15), Vector3(wd * 0.1, hgt * 0.26, 0.04), trim)


## Pilier de basalte à brasero. Champs : `pos`, `height` (6), `width` (1,4). Solide.
static func _pillar(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var wd := float(o.get("width", 1.4))
	var hgt := float(o.get("height", 6.0))
	var parent := Node3D.new()
	parent.name = "MorPilier"
	b.world.add_child(parent)
	var stone := MeshKit.pixel_material(Sprites.tile_texture("mor_mur"))
	stone.uv1_scale = Vector3(wd / 2.0, hgt / 3.0, 1.0)
	var rim := MeshKit.flat_material(Color("#2a2030"))
	_box_in(parent, p + Vector3(0.0, 0.3, 0.0), Vector3(wd + 0.5, 0.6, wd + 0.5), rim)
	_box_in(parent, p + Vector3(0.0, hgt * 0.5, 0.0), Vector3(wd, hgt, wd), stone)
	_box_in(parent, p + Vector3(0.0, hgt + 0.25, 0.0), Vector3(wd + 0.6, 0.5, wd + 0.6), rim)
	var bowl := MeshKit.flat_material(Color("#ff7a20"))
	bowl.emission_enabled = true
	bowl.emission = Color("#ff7a20")
	bowl.emission_energy_multiplier = 2.2
	_box_in(parent, p + Vector3(0.0, hgt * 0.6, wd * 0.5 + 0.35), Vector3(0.5, 0.2, 0.5), bowl)
	var fire := Atmosphere.make_particles("fire")
	if fire != null:
		fire.position = p + Vector3(0.0, hgt * 0.6 + 0.15, wd * 0.5 + 0.35)
		fire.scale = Vector3(1.6, 1.6, 1.6)
		b.world.add_child(fire)
	var l := Atmosphere.make_light(Color("#ff8a40"), 1.6, 9.0, false, 0.35)
	l.position = p + Vector3(0.0, hgt * 0.6 + 0.8, wd * 0.5 + 1.0)
	b.world.add_child(l)
	b.world.rects.append(Rect2(p.x - wd * 0.5, p.z - wd * 0.5, wd, wd))


## Lustre de fer : une couronne de bougies pendue à une chaîne, avec sa lumière vacillante. Champs : `pos`,
## `height` (hauteur de la couronne, 4,2), `radius` (1,3), `candles` (8).
static func _chandelier(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var hgt := float(o.get("height", 4.2))
	var rad := float(o.get("radius", 1.3))
	var n := int(o.get("candles", 8))
	var parent := Node3D.new()
	parent.name = "MorLustre"
	b.world.add_child(parent)
	var iron := MeshKit.flat_material(Color("#1a1620"))
	var top := float(b.wall_height)
	_box_in(parent, p + Vector3(0.0, (top + hgt) * 0.5, 0.0), Vector3(0.1, top - hgt, 0.1), iron)
	_box_in(parent, p + Vector3(0.0, hgt, 0.0), Vector3(rad * 2.0, 0.14, 0.14), iron)
	_box_in(parent, p + Vector3(0.0, hgt, 0.0), Vector3(0.14, 0.14, rad * 2.0), iron)
	_box_in(parent, p + Vector3(0.0, hgt - 0.12, 0.0), Vector3(rad * 1.5, 0.1, rad * 1.5), iron)
	var wax := MeshKit.flat_material(Color("#e8dcc0"))
	for k in n:
		var a := TAU * float(k) / float(n)
		var cp := p + Vector3(cos(a) * rad, hgt + 0.3, sin(a) * rad)
		_box_in(parent, cp, Vector3(0.12, 0.5, 0.12), wax)
		var fire := Atmosphere.make_particles("fire")
		if fire != null and k % 2 == 0:
			fire.position = cp + Vector3(0.0, 0.3, 0.0)
			fire.scale = Vector3(0.7, 0.7, 0.7)
			b.world.add_child(fire)
	var flame := MeshKit.flat_material(Color("#ffc060"))
	flame.emission_enabled = true
	flame.emission = Color("#ffb040")
	flame.emission_energy_multiplier = 2.4
	for k in n:
		var a2 := TAU * float(k) / float(n)
		_box_in(parent, p + Vector3(cos(a2) * rad, hgt + 0.62, sin(a2) * rad), Vector3(0.14, 0.2, 0.14), flame)
	var l := Atmosphere.make_light(Color("#ffb060"), 2.4, 13.0, false, 0.25)
	l.position = p + Vector3(0.0, hgt + 0.9, 0.0)
	b.world.add_child(l)
