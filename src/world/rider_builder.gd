extends RefCounted
## Styles d'architecture du chapitre 5 : « cavalier » (plaines et château de bois doré),
## « fongorn » (forêt ancienne), « isengarde » (tour noire, fours, fosses) et « chutes »
## (cascades et gorges). Un seul constructeur les sert tous ; chaque style choisit ses textures
## et son décor d'abords dans la table STYLES.
## Rien ici ne s'applique à une carte sans l'un de ces champs `style`.
##
## Le constructeur de cartes (MapBuilder) délègue ici :
##  - `restyle(b)` : après le sol, retouche l'aspect de la carte (parois, murs d'intérieur,
##    abords et décor lointain des cartes extérieures) ;
##  - `object(b, type, o)` : les objets propres aux styles (halle, palissade, flamme, cascade).
## Documentation : docs/FORMAT_DONNEES.md, section « Styles du chapitre 5 ».

const PA = preload("res://src/gfx/pixel_art.gd")
const MeshKit = preload("res://src/gfx/mesh_kit.gd")
const Atmosphere = preload("res://src/world/atmosphere.gd")
const ElvenBuilder = preload("res://src/world/elven_builder.gd")
const FOAM_SHADER = preload("res://src/gfx/shaders/waterfall_foam.gdshader")

const OBJECTS: Array[String] = ["cav_halle", "cav_palissade", "isen_flamme", "chu_cascade"]

## Par style : sol des abords, falaises, marches, parois entre deux niveaux, mur d'intérieur,
## arbres ou décors plantés autour de la carte.
const STYLES := {
	"cavalier": {"outer": "cav_herbe", "cliff": "cav_chemin", "stairs": "cav_planches", "relief": "cav_chemin",
			"wall": "cav_mur", "cap": "#3a2810", "glow": 0.12, "trees": ["cav_arbre"], "tree_count": 70, "low": ["grass", "flowers", "wheat"]},
	"fongorn": {"outer": "ent_mousse", "cliff": "ent_racines", "stairs": "ent_sentier", "relief": "ent_racines",
			"wall": "ent_racines", "cap": "#10180c", "glow": 0.0, "trees": ["ent_arbre"], "tree_count": 120, "low": ["fern", "mushrooms", "fern"]},
	"isengarde": {"outer": "isen_dalle", "cliff": "isen_dalle", "stairs": "isen_fonte", "relief": "isen_dalle",
			"wall": "isen_mur", "cap": "#0c0a12", "glow": 0.2, "trees": ["isen_cheminee"], "tree_count": 26, "low": ["isen_sac", "isen_marmite"]},
	"chutes": {"outer": "chu_gravier", "cliff": "chu_roche", "stairs": "chu_roche", "relief": "chu_roche",
			"wall": "chu_mur", "cap": "#0c1418", "glow": 0.05, "trees": ["elf_pine"], "tree_count": 70, "low": ["fern", "chu_pierre", "reeds"]},
}


static func is_rider(b) -> bool:
	return STYLES.has(str(b.map.get("style", "")))


static func _spec(b) -> Dictionary:
	return STYLES.get(str(b.map.get("style", "")), STYLES["cavalier"])


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
			wm.set_shader_parameter("deep", Color(str(spec.get("deep", "#1a4a5a"))))
			wm.set_shader_parameter("shallow", Color(str(spec.get("shallow", "#4a9aa0"))))
			wm.set_shader_parameter("ripple", Color(str(spec.get("ripple", "#d8f4f0"))))
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


## Arbres (ou cheminées de fours, pins) plantés autour de la carte, puis un sous-bois bas.
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
		var kind := str(trees[i % trees.size()])
		b._prop(kind, {"solid": 0.0, "shadow": false, "scale": rng.randf_range(0.9, 1.25)}, p)
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
		"cav_halle": _hall(b, o)
		"cav_palissade": _palisade(b, o)
		"isen_flamme": _flame(b, o)
		"chu_cascade": _cascade(b, o)
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


## Halle de bois doré : corps de rondins, toit en gradins, porte sombre, cornes de faîte en
## croix. Champs : `pos` (centre du pied), `size` [largeur, profondeur], `height` (3), `door`
## (vrai par défaut). Bloque le passage.
static func _hall(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var sz: Array = o.get("size", [6.0, 4.0])
	var wd := float(sz[0])
	var dp := float(sz[1])
	var hgt := float(o.get("height", 3.0))
	var parent := Node3D.new()
	parent.name = "CavHalle"
	b.world.add_child(parent)
	var wall := MeshKit.pixel_material(Sprites.tile_texture("cav_mur"))
	wall.uv1_scale = Vector3(wd / 2.0, hgt / 3.0, 1.0)
	var side := MeshKit.pixel_material(Sprites.tile_texture("cav_mur"))
	side.uv1_scale = Vector3(dp / 2.0, hgt / 3.0, 1.0)
	_box_in(parent, p + Vector3(0.0, hgt * 0.5, 0.0), Vector3(wd, hgt, dp), wall)
	var gold := MeshKit.flat_material(Color("#d4a43c"), 0.1)
	var roof := MeshKit.flat_material(Color("#8a5a22"))
	for k in 3:
		var f := 1.0 - float(k) * 0.28
		_box_in(parent, p + Vector3(0.0, hgt + 0.22 + float(k) * 0.36, 0.0), Vector3((wd + 0.8) * f, 0.36, (dp + 0.8) * f), roof if k < 2 else gold)
	_box_in(parent, p + Vector3(0.0, hgt + 1.4, 0.0), Vector3(0.12, 0.9, 0.12), gold)
	_box_in(parent, p + Vector3(-0.3, hgt + 1.62, 0.0), Vector3(0.7, 0.1, 0.1), gold)
	if bool(o.get("door", true)):
		_box_in(parent, p + Vector3(0.0, 0.9, dp * 0.5 + 0.02), Vector3(1.4, 1.8, 0.06), MeshKit.flat_material(Color("#2a1a0c")))
		_box_in(parent, p + Vector3(0.0, 1.86, dp * 0.5 + 0.03), Vector3(1.6, 0.12, 0.08), gold)
		var torch := Atmosphere.make_light(Color("#ffc870"), 1.8, 5.5, false, 0.2)
		torch.position = p + Vector3(0.0, 1.8, dp * 0.5 + 0.8)
		parent.add_child(torch)
	b.world.rects.append(Rect2(p.x - wd * 0.5, p.z - dp * 0.5, wd, dp))
	b.keep_clear.append(Vector2(p.x, p.z + dp * 0.5 + 0.8))


## Palissade de pieux le long d'une ligne brisée. Champs : `points`, `height` (1,5).
static func _palisade(b, o: Dictionary) -> void:
	var pts: Array = o.get("points", [])
	var hgt := float(o.get("height", 1.5))
	var st := MeshKit.begin()
	for i in range(pts.size() - 1):
		var pa: Array = pts[i]
		var pc: Array = pts[i + 1]
		var a := Vector2(float(pa[0]), float(pa[1]))
		var c := Vector2(float(pc[0]), float(pc[1]))
		var length := a.distance_to(c)
		if length < 0.05:
			continue
		var n := maxi(1, int(round(length / 0.34)))
		for k in range(n + 1):
			var q := a.lerp(c, float(k) / float(n))
			var qy: float = b.world.ground_y(q.x, q.y)
			var tall := hgt * (0.85 + 0.15 * PA.rnd(k, i, 1301))
			MeshKit.box(st, Vector3(q.x, qy + tall * 0.5, q.y), Vector3(0.26, tall, 0.26))
		var steps := int(ceil(length / 0.4))
		for k in range(steps + 1):
			var q2 := a.lerp(c, float(k) / float(steps))
			b.world.circles.append(Vector3(q2.x, q2.y, 0.22))
	var node := MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture("cav_planches")))
	node.name = "CavPalissade"
	b.world.add_child(node)


## Flamme de fosse de l'Isengarde : feu, braises et lueur rouge, sans obstacle (la fosse est
## déjà infranchissable par son sol). Champs : `pos`, `energy`, `range`.
static func _flame(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var fire := Atmosphere.make_particles("fire")
	if fire != null:
		fire.position = p + Vector3(0.0, 0.1, 0.0)
		b.world.add_child(fire)
	var embers := Atmosphere.make_particles("embers")
	if embers != null:
		embers.position = p + Vector3(0.0, 0.3, 0.0)
		b.world.add_child(embers)
	var light := Atmosphere.make_light(Color(str(o.get("color", "#ff6a28"))), float(o.get("energy", 3.0)), float(o.get("range", 9.0)), false, 0.3)
	light.position = p + Vector3(0.0, 1.0, 0.0)
	b.world.add_child(light)


## Cascade contre la paroi nord : `pos` (pied), `height` (4), `width` (2,4), `pool` (vrai).
## Elle prend la teinte du liquide de la carte (champ `water`), s'adosse à une paroi de roche
## sombre qui la détache du fond, et pose à son pied une nappe d'écume et un reflet qui miroite.
static func _cascade(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var hgt := float(o.get("height", 4.0))
	var wd := float(o.get("width", 2.4))
	var spec: Dictionary = b.map.get("water", {})
	var colors := {}
	if spec.has("shallow"):
		colors["body"] = Color(str(spec["shallow"])).lightened(0.25)
		colors["deep"] = Color(str(spec.get("deep", spec["shallow"]))).lerp(Color(str(spec["shallow"])), 0.45)
		colors["foam"] = Color(str(spec.get("glint", "#ffffff"))).lerp(Color.WHITE, 0.4)
	# la cascade qui tombe dans l'eau de la carte n'a pas besoin de bassin posé : l'eau est déjà là
	var in_water: bool = b._cell_at_pixel(p.x * b.PPU, (p.z + 0.6) * b.PPU) == "water"
	ElvenBuilder._waterfall(b, p, hgt, wd, bool(o.get("pool", true)) and not in_water, colors)
	var parent := Node3D.new()
	parent.name = "CascadeDecor"
	b.world.add_child(parent)
	# paroi de roche derrière l'eau, plus large et plus haute qu'elle
	var rock := MeshKit.pixel_material(Sprites.tile_texture("chu_roche"))
	rock.uv1_scale = Vector3((wd + 4.0) / 2.0, (hgt + 1.0) / 2.0, 1.0)
	rock.albedo_color = Color(0.36, 0.4, 0.5)   # roche mouillée, sombre : elle détache l'eau claire
	_box_in(parent, p + Vector3(0.0, (hgt + 1.0) * 0.5, -0.32), Vector3(wd + 4.0, hgt + 1.0, 0.5), rock)
	# nappe d'écume et reflet au pied de la chute
	var foam := ShaderMaterial.new()
	foam.shader = FOAM_SHADER
	foam.set_shader_parameter("tint", Color(colors.get("foam", Color.WHITE)))
	foam.set_shader_parameter("size", Vector2(wd * 1.3, 2.0))
	var quad := QuadMesh.new()
	quad.size = Vector2(wd * 1.3, 2.0)
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = foam
	mi.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	mi.position = p + Vector3(0.0, 0.07, 1.0)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
