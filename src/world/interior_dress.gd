extends RefCounted
## Habillage des intérieurs (tous styles) : hors-carte qui se fond dans l'ombre (`surround`), murs du
## fond garnis d'étagères, de crochets, de niches à bougie, de tentures, de fûts, de boucliers (champ
## `wall_dress` de la carte), poutres, taches de lumière sous les fenêtres. Tout est décoratif : aucune
## collision, aucun passage touché. Documentation : docs/FORMAT_DONNEES.md, « Habillage des intérieurs ».
##
## MapBuilder appelle `dress(b)` à la fin de la construction (objets posés, styles appliqués).

const PA = preload("res://src/gfx/pixel_art.gd")
const MeshKit = preload("res://src/gfx/mesh_kit.gd")
const Atmosphere = preload("res://src/world/atmosphere.gd")
const InteriorPainter = preload("res://src/gfx/interior_painter.gd")
const SURROUND_SHADER = preload("res://src/gfx/shaders/surround.gdshader")

## Jeux de décors : `decor` = [type, poids] ; `beams` : poteaux et poutre de bois ; `cap` : dessus des murs ;
## `window_light` : couleur de la lumière que laissent entrer les fenêtres (objets `window`).
const SETS := {
	"cave": {"decor": [["etagere", 4], ["crochets", 3], ["niche", 2], ["tonneau", 3], ["tenture", 1]], "beams": true,
			"cap": "#4a4034", "window_light": ""},
	"garde": {"decor": [["casseroles", 3], ["crochets", 3], ["grille", 4], ["etagere", 1], ["applique", 2]], "beams": false,
			"cap": "#2a2630", "window_light": ""},
	"auberge": {"decor": [["tenture", 3], ["etagere", 3], ["applique", 2], ["niche", 1], ["crochets", 1]], "beams": false,
			"cap": "#2e241e", "window_light": "#9ab4ff"},
	"mine": {"decor": [["bouclier", 3], ["plaque", 2], ["niche", 2], ["tenture", 3], ["applique", 1]], "beams": false,
			"cap": "#2a2838", "window_light": ""},
}

## Types d'objets de carte devant lesquels on ne pose rien contre le mur (portes, fenêtres, meubles hauts).
const NO_DECOR_TYPES: Array[String] = ["encounter_zone", "trigger", "light", "monster", "scatter", "rug"]


static func dress(b) -> void:
	if not bool(b.map.get("interior", false)):
		return
	_surround(b)
	var name := str(b.map.get("wall_dress", ""))
	if name == "" or not SETS.has(name):
		return
	var spec: Dictionary = SETS[name]
	var caps := b.world.get_node_or_null("WallCaps") as MeshInstance3D
	if caps != null:
		caps.material_override = MeshKit.flat_material(Color(str(b.map.get("wall_cap", spec["cap"]))))
	var walls := b.world.get_node_or_null("Walls") as MeshInstance3D
	if walls != null and b.map.has("wall_tint"):
		var m := walls.material_override as StandardMaterial3D
		if m != null:
			m.albedo_color = Color(str(b.map["wall_tint"]))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(b.map.get("id", "")) + "habillage")
	var parent := Node3D.new()
	parent.name = "InteriorDress"
	b.world.add_child(parent)
	_north_walls(b, spec, rng, parent)
	if str(spec["window_light"]) != "":
		_windows(b, Color(str(spec["window_light"])), parent)


# ================================================================ hors-carte

static func _surround(b) -> void:
	var tile := str(b.map.get("surround_tile", ""))
	var ground: Dictionary = b.map.get("ground", {})
	var default_type := str(ground.get("default", ""))
	if tile == "":
		tile = "nain_abime" if default_type == "nain_abime" else "roche_fond"
	var has_water := false
	for c: String in b.cells:
		if c == "water":
			has_water = true
			break
	var depth := 40.0
	var y := -0.3 if has_water else -0.03
	var st := MeshKit.begin()
	MeshKit.quad(st, Vector3(-depth, y, -depth), Vector3(b.w + depth, y, -depth), Vector3(b.w + depth, y, b.h + depth), Vector3(-depth, y, b.h + depth))
	var mat := ShaderMaterial.new()
	mat.shader = SURROUND_SHADER
	mat.set_shader_parameter("tex", Sprites.tile_texture(tile))
	mat.set_shader_parameter("box", Vector4(0.0, 0.0, float(b.w), float(b.h)))
	mat.set_shader_parameter("tint", Color(str(b.map.get("surround_tint", "#ffffff"))))
	mat.set_shader_parameter("fade", float(b.map.get("surround_fade", 9.0)))
	var node := MeshKit.finish(st, mat, false)
	node.name = "Surround"
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.world.add_child(node)


# =============================================================== murs du fond

## Plages de mur nord : (z, x0, x1) pour chaque suite de cases dont le côté nord est un mur.
static func _runs(b) -> Array:
	var runs: Array = []
	for ty in b.h:
		var tx := 0
		while tx < b.w:
			var wall: bool = not b._flag(b._cell(tx, ty), "hole") and (ty == 0 or b._wall_gap((ty - 1) * b.w + tx))
			if not wall:
				tx += 1
				continue
			var from := tx
			while tx < b.w and not b._flag(b._cell(tx, ty), "hole") and (ty == 0 or b._wall_gap((ty - 1) * b.w + tx)):
				tx += 1
			runs.append([ty, from, tx])
	return runs


## Intervalles en x occupés devant le mur de la rangée `ty` (portes, meubles, personnages) : on n'y pose rien.
static func _blockers(b, ty: int) -> Array:
	var out: Array = []
	for o: Dictionary in b.map.get("objects", []):
		var type := str(o.get("type", ""))
		if NO_DECOR_TYPES.has(type):
			continue
		if type == "warp":
			var r: Array = o.get("rect", [0, 0, 1, 1])
			if float(r[1]) <= float(ty) + 2.0 and float(r[1]) + float(r[3]) >= float(ty) - 1.0:
				out.append(Vector2(float(r[0]) - 0.3, float(r[0]) + float(r[2]) + 0.3))
			continue
		if not o.has("pos"):
			continue
		var p: Array = o["pos"]
		var oz := float(p[1]) + 0.5
		if oz < float(ty) - 0.6 or oz > float(ty) + 2.2:
			continue
		var half := 1.0
		if type == "window":
			half = 1.15
		elif type in ["shelf", "fireplace", "counter", "stove", "isen_four", "isen_cheminee", "isen_cage", "table"]:
			half = 1.5
		elif type in ["barrel", "crate", "sign", "bollard", "stool", "isen_sac", "isen_marmite"]:
			half = 0.75
		out.append(Vector2(float(p[0]) + 0.5 - half, float(p[0]) + 0.5 + half))
	return out


static func _free(blockers: Array, x0: float, x1: float) -> float:
	## Renvoie -1 si [x0, x1] est libre, sinon la fin du premier obstacle rencontré.
	for r: Vector2 in blockers:
		if x1 > r.x and x0 < r.y:
			return r.y
	return -1.0


static func _north_walls(b, spec: Dictionary, rng: RandomNumberGenerator, parent: Node3D) -> void:
	var pool: Array[String] = []
	for e: Array in spec["decor"]:
		for k in int(e[1]):
			pool.append(str(e[0]))
	var hgt: float = b.wall_height
	for run: Array in _runs(b):
		var ty: int = run[0]
		var x0 := float(run[1])
		var x1 := float(run[2])
		if x1 - x0 < 2.0:
			continue
		var blockers := _blockers(b, ty)
		var z := float(ty) + 0.03
		var gy: float = b.world.ground_y((x0 + x1) * 0.5, float(ty) + 0.5)
		var room := hgt - gy   # hauteur de mur visible au-dessus du sol (un sol surélevé en raccourcit la vue)
		if room < 2.2:
			continue
		if bool(spec["beams"]):
			_beams(b, parent, x0, x1, float(ty), gy, room, blockers, rng)
		var cursor := x0 + 0.4 + rng.randf() * 0.9
		var last := ""
		var guard := 0
		while cursor < x1 - 0.8 and guard < 80:
			guard += 1
			var kind := pool[rng.randi() % pool.size()]
			if kind == last and pool.size() > 1:
				kind = pool[rng.randi() % pool.size()]
			var d: Array = InteriorPainter.DECOR[kind]
			var wu := float(d[1]) / 24.0
			var hu := float(d[2]) / 24.0
			if cursor + wu > x1 - 0.3:
				break
			if float(d[3]) + hu > room - 0.35:
				cursor += 0.6
				continue
			var hit := _free(blockers, cursor - 0.2, cursor + wu + 0.2)
			if hit >= 0.0:
				cursor = hit + 0.2
				continue
			var v := rng.randi() % int(d[0])
			_place(b, parent, kind, v, cursor + wu * 0.5, z, gy + float(d[3]), wu, hu)
			last = kind
			cursor += wu + 0.45 + rng.randf() * 1.3


## Poteaux de bois tous les cinq à sept unités, et une poutre qui les relie sous le plafond.
static func _beams(b, parent: Node3D, x0: float, x1: float, zrow: float, gy: float, hgt: float, blockers: Array, rng: RandomNumberGenerator) -> void:
	var st := MeshKit.begin()
	var x := x0 + 2.5 + rng.randf() * 2.0
	var posts: Array[float] = []
	while x < x1 - 1.2:
		if _free(blockers, x - 0.4, x + 0.4) < 0.0:
			posts.append(x)
			blockers.append(Vector2(x - 0.45, x + 0.45))
			MeshKit.box(st, Vector3(x, gy + hgt * 0.5, zrow + 0.09), Vector3(0.34, hgt, 0.18))
			MeshKit.box(st, Vector3(x, gy + 0.2, zrow + 0.1), Vector3(0.46, 0.4, 0.22))
		x += 5.0 + rng.randf() * 2.5
	MeshKit.box(st, Vector3((x0 + x1) * 0.5, gy + hgt - 0.4, zrow + 0.07), Vector3(x1 - x0, 0.3, 0.14))
	var mat := MeshKit.pixel_material(Sprites.tile_texture("wood"))
	var node := MeshKit.finish(st, mat, false)
	node.name = "Poutres"
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)


static func _decor_textures(kind: String, v: int) -> Dictionary:
	return Sprites.cached("walldecor:%s:%d" % [kind, v], func() -> Dictionary:
		var d: Dictionary = InteriorPainter.paint_decor(kind, v)
		var e: Image = d["emission"]
		var lit := false
		for y in e.get_height():
			for x in e.get_width():
				var c := e.get_pixel(x, y)
				if c.a > 0.0:
					lit = true
					e.set_pixel(x, y, Color(c.r * c.a, c.g * c.a, c.b * c.a, 1.0))
		return {"albedo": PA.texture(d["albedo"]), "emission": PA.texture(e) if lit else null})


static func _material(kind: String, v: int) -> StandardMaterial3D:
	return Sprites.cached("walldecor_mat:%s:%d" % [kind, v], func() -> StandardMaterial3D:
		var t := _decor_textures(kind, v)
		var m := StandardMaterial3D.new()
		m.albedo_texture = t["albedo"]
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
		m.roughness = 1.0
		m.metallic_specular = 0.0
		if t["emission"] != null:
			m.emission_enabled = true
			m.emission = Color.WHITE
			m.emission_operator = BaseMaterial3D.EMISSION_OP_ADD
			m.emission_texture = t["emission"]
			m.emission_energy_multiplier = 0.9
		return m)


static func _place(b, parent: Node3D, kind: String, v: int, cx: float, z: float, y: float, wu: float, hu: float) -> void:
	var quad := QuadMesh.new()
	quad.size = Vector2(wu, hu)
	var mi := MeshInstance3D.new()
	mi.mesh = quad
	mi.material_override = _material(kind, v)
	mi.position = Vector3(cx, y + hu * 0.5, z)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	var glow := str(InteriorPainter.DECOR[kind][4])
	if glow != "":
		var light := Atmosphere.make_light(Color(glow), 0.7, 4.2, false, 0.16)
		light.position = Vector3(cx, y + hu * 0.55, z + 1.4)
		parent.add_child(light)


# ================================================================= fenêtres

## Une tache de lumière au sol et une lueur douce, sans ombre, devant chaque fenêtre (objet `window`).
static func _windows(b, color: Color, parent: Node3D) -> void:
	var tex: Texture2D = Sprites.cached("walldecor:patch", func() -> Texture2D:
		return PA.texture(InteriorPainter.paint_light_patch()))
	for o: Dictionary in b.map.get("objects", []):
		if str(o.get("type", "")) != "window":
			continue
		var p: Array = o.get("pos", [0, 0])
		var wx := float(p[0]) + 0.5
		var wz := float(p[1]) + 0.5
		var quad := QuadMesh.new()
		quad.size = Vector2(40.0 / 24.0 * 1.15, 56.0 / 24.0 * 1.15)
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_texture = tex
		m.albedo_color = color
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.material_override = m
		mi.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
		mi.position = Vector3(wx + 0.25, 0.04, wz + 1.35)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		var light := Atmosphere.make_light(color, 0.8, 4.2, false, 0.0)
		light.position = Vector3(wx, 1.7, wz + 0.9)
		parent.add_child(light)
