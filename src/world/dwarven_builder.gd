extends RefCounted
## Style d'architecture « nain » (champ `style: "nain"` d'une carte).
## Rien ici ne s'applique à une carte sans ce champ : les chapitres 1 à 3 sont intacts.
##
## Le constructeur de cartes (MapBuilder) délègue ici :
##  - `restyle(b)` : après le sol, retouche l'aspect de la carte (parois, murs d'intérieur,
##    neige et massif des cartes extérieures, couleur de l'eau) ;
##  - `object(b, type, o)` : les objets propres au style (piliers, braseros, torches, parapets).
## Un intérieur nain peut avoir du relief (`heights`, `stairs`), ce que les autres intérieurs
## ignorent. Documentation : docs/FORMAT_DONNEES.md, section « Styles d'architecture ».

const PA = preload("res://src/gfx/pixel_art.gd")
const MeshKit = preload("res://src/gfx/mesh_kit.gd")
const Atmosphere = preload("res://src/world/atmosphere.gd")

## Types d'objets que `object()` sait construire.
const OBJECTS: Array[String] = ["nain_pilier", "nain_brasero", "nain_torche", "nain_parapet", "nain_dais", "nain_forge_murale"]

const FIRE := Color("#ff9a3c")


static func is_dwarven(b) -> bool:
	return str(b.map.get("style", "")) == "nain"


static func _node(b, node_name: String) -> MeshInstance3D:
	return b.world.get_node_or_null(node_name) as MeshInstance3D


# ===================================================================== retouche

## Appelé par MapBuilder.build() une fois le sol, l'eau et le relief bâtis.
static func restyle(b) -> void:
	var st := _node(b, "ReliefStairs")
	if st != null:
		st.material_override = MeshKit.pixel_material(Sprites.tile_texture("nain_marches"))
	var rw := _node(b, "ReliefWalls")
	if rw != null:
		rw.material_override = MeshKit.pixel_material(Sprites.tile_texture("nain_pierre"))
	var water := _node(b, "Water")
	if water != null:
		var wm := water.material_override as ShaderMaterial
		if wm != null:
			var spec: Dictionary = b.map.get("water", {})
			wm.set_shader_parameter("deep", Color(str(spec.get("deep", "#0c2a4a"))))
			wm.set_shader_parameter("shallow", Color(str(spec.get("shallow", "#2a6a8a"))))
			wm.set_shader_parameter("ripple", Color(str(spec.get("ripple", "#a8d8f0"))))
			wm.set_shader_parameter("glint", Color(str(spec.get("glint", "#e8f4ff"))))
	if bool(b.map.get("interior", false)):
		_restyle_interior(b)
	else:
		_restyle_exterior(b)


static func _restyle_interior(b) -> void:
	var walls := _node(b, "Walls")
	if walls != null:
		var tile := str(b.map.get("wall_tile", "nain_mur"))
		var tex: Texture2D = Sprites.tile_texture(tile)
		var m := MeshKit.pixel_material(tex)
		m.emission_enabled = true
		m.emission = Color.WHITE
		m.emission_operator = BaseMaterial3D.EMISSION_OP_ADD
		m.emission_texture = tex
		m.emission_energy_multiplier = float(b.map.get("wall_glow", 0.22))
		walls.material_override = m
	var caps := _node(b, "WallCaps")
	if caps != null:
		caps.material_override = MeshKit.flat_material(Color(str(b.map.get("wall_cap", "#15131f"))))


static func _restyle_exterior(b) -> void:
	var outer := _node(b, "Outskirts")
	if outer != null:
		outer.material_override = MeshKit.ground_material(Sprites.tile_texture("nain_neige"))
	var cliffs := _node(b, "Cliffs")
	if cliffs != null:
		cliffs.material_override = MeshKit.ground_material(Sprites.tile_texture("nain_roc"), 0.1)
	_massif(b)
	_forest(b)


## Chaîne de montagne au nord : de grands gradins de roche sombre coiffés de neige, très au-delà
## de la carte, pour que la caméra ne voie jamais le vide.
static func _massif(b) -> void:
	var far := 60.0
	var rock := MeshKit.begin()
	var tops := MeshKit.begin()
	var ledges: Array = b.map.get("massif", [[-6.0, 5.0], [-13.0, 9.0], [-21.0, 14.0]])
	for i in ledges.size():
		var z: float = float((ledges[i] as Array)[0])
		var top: float = float((ledges[i] as Array)[1])
		var z_back := -far
		if i + 1 < ledges.size():
			z_back = float((ledges[i + 1] as Array)[0])
		MeshKit.box(rock, Vector3(b.w * 0.5, top * 0.5, (z - far) * 0.5), Vector3(b.w + far * 2.0, top, z + far))
		MeshKit.quad(tops, Vector3(-far, top + 0.02, z_back), Vector3(b.w + far, top + 0.02, z_back), Vector3(b.w + far, top + 0.02, z), Vector3(-far, top + 0.02, z),
				Vector2(-far, z_back) / MeshKit.TEX_UNITS, Vector2(b.w + far, z) / MeshKit.TEX_UNITS)
	var rock_node := MeshKit.finish(rock, MeshKit.ground_material(Sprites.tile_texture("nain_roc"), 0.1), true)
	rock_node.name = "MassifRock"
	b.world.add_child(rock_node)
	var top_node := MeshKit.finish(tops, MeshKit.ground_material(Sprites.tile_texture("nain_neige")), false)
	top_node.name = "MassifSnow"
	b.world.add_child(top_node)


## Sapins enneigés de chaque côté et au sud de la carte.
static func _forest(b) -> void:
	var rng: RandomNumberGenerator = b.rng
	for i in 90:
		var left := i % 2 == 0
		var x := rng.randf_range(-16.0, -0.9) if left else rng.randf_range(b.w + 0.9, b.w + 16.0)
		var z := rng.randf_range(-1.0, float(b.h) + 6.0)
		b._prop("nain_sapin", {"variant": rng.randi() % 2, "solid": 0.0, "shadow": false}, Vector3(x, 0.0, z))
	for i in 40:
		var x := rng.randf_range(-6.0, b.w + 6.0)
		var z := rng.randf_range(float(b.h) + 0.7, float(b.h) + 9.0)
		b._prop("nain_sapin", {"variant": rng.randi() % 2, "solid": 0.0, "shadow": false}, Vector3(x, 0.0, z))
	for i in 24:
		var x := rng.randf_range(-12.0, b.w + 12.0)
		var z := rng.randf_range(-5.0, -0.8)
		b._prop("nain_sapin", {"variant": rng.randi() % 2, "solid": 0.0, "shadow": false}, Vector3(x, 5.0, z))


# ========================================================================= objets

## Construit un objet propre au style ; renvoie faux si le type est inconnu.
static func object(b, type: String, o: Dictionary) -> bool:
	match type:
		"nain_pilier": _pillar(b, o)
		"nain_brasero": _brazier(b, o)
		"nain_torche": _torch(b, o)
		"nain_parapet": _parapet(b, o)
		"nain_dais": _dais(b, o)
		"nain_forge_murale": _wall_forge(b, o)
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


## Pilier colossal : un fût carré de pierre sombre, sa base et son chapiteau à bandeau d'or.
## Champs : `pos`, `height` (hauteur des murs de la carte par défaut), `size` (1,3).
static func _pillar(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var hgt := float(o.get("height", b.wall_height))
	var s := float(o.get("size", 1.3))
	var parent := Node3D.new()
	parent.name = "NainPilier"
	b.world.add_child(parent)
	var shaft_mat := MeshKit.pixel_material(Sprites.tile_texture("nain_pierre"))
	shaft_mat.uv1_scale = Vector3(s / 2.0, hgt / 2.0, 1.0)
	var dark := MeshKit.pixel_material(Sprites.tile_texture("nain_dalle"))
	var gold := MeshKit.flat_material(Color("#c9a040"), 0.25)
	_box_in(parent, p + Vector3(0, hgt * 0.5, 0), Vector3(s, hgt, s), shaft_mat)
	_box_in(parent, p + Vector3(0, 0.16, 0), Vector3(s + 0.4, 0.32, s + 0.4), dark)
	_box_in(parent, p + Vector3(0, 0.36, 0), Vector3(s + 0.2, 0.08, s + 0.2), gold)
	_box_in(parent, p + Vector3(0, hgt - 0.2, 0), Vector3(s + 0.4, 0.4, s + 0.4), dark)
	_box_in(parent, p + Vector3(0, hgt - 0.46, 0), Vector3(s + 0.2, 0.08, s + 0.2), gold)
	# bandeau gravé à mi-hauteur : quatre carrés d'or, un par face
	for k in 3:
		var y := hgt * (0.3 + 0.2 * float(k))
		_box_in(parent, p + Vector3(0, y, s * 0.5 + 0.01), Vector3(s * 0.4, 0.3, 0.02), gold)
		_box_in(parent, p + Vector3(s * 0.5 + 0.01, y, 0), Vector3(0.02, 0.3, s * 0.4), gold)
	b.world.rects.append(Rect2(p.x - s * 0.5 - 0.05, p.z - s * 0.5 - 0.05, s + 0.1, s + 0.1))
	b.keep_clear.append(Vector2(p.x, p.z))


## Brasero de fer sur trois pieds : braises, flammes, lumière orange qui vacille.
static func _brazier(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var parent := Node3D.new()
	parent.name = "NainBrasero"
	b.world.add_child(parent)
	var iron := MeshKit.flat_material(Color("#2c2b38"))
	for k in 3:
		var a := float(k) / 3.0 * TAU
		_box_in(parent, p + Vector3(cos(a) * 0.2, 0.3, sin(a) * 0.2), Vector3(0.07, 0.6, 0.07), iron)
	_box_in(parent, p + Vector3(0, 0.62, 0), Vector3(0.62, 0.16, 0.62), iron)
	_box_in(parent, p + Vector3(0, 0.74, 0), Vector3(0.5, 0.08, 0.5), MeshKit.flat_material(Color("#ff7a2a"), 2.0))
	var fire := Atmosphere.make_particles("fire")
	if fire != null:
		fire.position = p + Vector3(0, 0.82, 0)
		b.world.add_child(fire)
	var embers := Atmosphere.make_particles("embers")
	if embers != null:
		embers.position = p + Vector3(0, 0.9, 0)
		b.world.add_child(embers)
	var light := Atmosphere.make_light(Color(str(o.get("color", "#ff9a48"))), float(o.get("energy", 2.6)), float(o.get("range", 8.0)), bool(o.get("shadow", false)), 0.22)
	light.position = p + Vector3(0, 1.1, 0)
	parent.add_child(light)
	b.world.circles.append(Vector3(p.x, p.z, 0.34))
	b.keep_clear.append(Vector2(p.x, p.z))


## Torche de mur : un support de fer, une flamme, une lumière. Se pose contre une paroi.
static func _torch(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var hgt := float(o.get("height", 1.9))
	var parent := Node3D.new()
	parent.name = "NainTorche"
	b.world.add_child(parent)
	var iron := MeshKit.flat_material(Color("#2c2b38"))
	_box_in(parent, p + Vector3(0, hgt - 0.3, 0), Vector3(0.07, 0.6, 0.07), iron)
	_box_in(parent, p + Vector3(0, hgt, 0), Vector3(0.2, 0.1, 0.2), iron)
	_box_in(parent, p + Vector3(0, hgt + 0.06, 0), Vector3(0.12, 0.05, 0.12), MeshKit.flat_material(Color("#ff7a2a"), 2.0))
	var fire := Atmosphere.make_particles("fire")
	if fire != null:
		fire.position = p + Vector3(0, hgt + 0.1, 0)
		b.world.add_child(fire)
	var light := Atmosphere.make_light(Color(str(o.get("color", "#ffa850"))), float(o.get("energy", 2.0)), float(o.get("range", 6.5)), false, 0.2)
	light.position = p + Vector3(0, hgt + 0.3, 0.1)
	parent.add_child(light)


## Parapet de pierre bas le long d'une ligne brisée (ponts, bords de gouffre).
## Champs : `points` (en unités, comme `exact` des rampes elfes), `height` (0,55).
static func _parapet(b, o: Dictionary) -> void:
	var pts: Array = o.get("points", [])
	var hgt := float(o.get("height", 0.55))
	var st := MeshKit.begin()
	for i in range(pts.size() - 1):
		var pa: Array = pts[i]
		var pb: Array = pts[i + 1]
		var a := Vector2(float(pa[0]), float(pa[1]))
		var c := Vector2(float(pb[0]), float(pb[1]))
		var length := a.distance_to(c)
		if length < 0.05:
			continue
		var mid := (a + c) * 0.5
		var gy: float = b.world.ground_y(mid.x, mid.y)
		var horizontal := absf(c.x - a.x) >= absf(c.y - a.y)
		MeshKit.box(st, Vector3(mid.x, gy + hgt * 0.5, mid.y), Vector3(length if horizontal else 0.26, hgt, 0.26 if horizontal else length))
		var n := maxi(1, int(round(length / 1.4)))
		for k in range(n + 1):
			var q := a.lerp(c, float(k) / float(n))
			var qy: float = b.world.ground_y(q.x, q.y)
			MeshKit.box(st, Vector3(q.x, qy + hgt * 0.5 + 0.1, q.y), Vector3(0.4, hgt + 0.2, 0.4))
		var steps := int(ceil(length / 0.4))
		for k in range(steps + 1):
			var q2 := a.lerp(c, float(k) / float(steps))
			b.world.circles.append(Vector3(q2.x, q2.y, 0.2))
	var node := MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture("nain_pierre")))
	node.name = "NainParapet"
	b.world.add_child(node)


## Estrade carrée de pierre (pas de relief) : un bloc plat qui porte un trône, une tombe, un
## autel. Champs : `rect`, `height` (0,25). Décor seulement, traversable par le dessus.
static func _dais(b, o: Dictionary) -> void:
	var r: Rect2 = b._rect2(o)
	var hgt := float(o.get("height", 0.25))
	var st := MeshKit.begin()
	MeshKit.box(st, Vector3(r.position.x + r.size.x * 0.5, hgt * 0.5, r.position.y + r.size.y * 0.5), Vector3(r.size.x, hgt, r.size.y))
	var node := MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture("nain_marbre")))
	node.name = "NainDais"
	b.world.add_child(node)


## Grande forge encastrée dans un mur : un four de brique noire, la gueule rougeoyante et
## la cheminée. Champs : `pos`, `width` (3). Bloque le passage.
static func _wall_forge(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var width := float(o.get("width", 3.0))
	var parent := Node3D.new()
	parent.name = "NainForgeMurale"
	b.world.add_child(parent)
	var body := MeshKit.pixel_material(Sprites.tile_texture("nain_mur_forge"))
	_box_in(parent, p + Vector3(0, 1.1, 0), Vector3(width, 2.2, 1.0), body)
	_box_in(parent, p + Vector3(0, 0.75, 0.52), Vector3(width * 0.6, 0.7, 0.04), MeshKit.flat_material(Color("#ff6a20"), 3.0))
	_box_in(parent, p + Vector3(0, 0.75, 0.56), Vector3(width * 0.6, 0.12, 0.04), MeshKit.flat_material(Color("#ffd870"), 3.5))
	var fire := Atmosphere.make_particles("fire")
	if fire != null:
		fire.position = p + Vector3(0, 0.6, 0.45)
		b.world.add_child(fire)
	var light := Atmosphere.make_light(Color("#ff7a30"), float(o.get("energy", 3.2)), float(o.get("range", 9.0)), false, 0.25)
	light.position = p + Vector3(0, 0.9, 1.2)
	parent.add_child(light)
	b.world.rects.append(Rect2(p.x - width * 0.5, p.z - 0.5, width, 1.1))
	b.keep_clear.append(Vector2(p.x, p.z + 1.0))
