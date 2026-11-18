extends RefCounted
## Construction de géométrie 3D simple par code (murs, toits, meubles).
## Convention : les faces avant sont dans le sens horaire, comme dans Godot.

const TEX_UNITS := 2.0   # une texture répétable de 48 px couvre 2 unités monde
const GROUND_SHADER = preload("res://src/gfx/shaders/ground.gdshader")


## Matériau de sol : texture nette, nuancée par grandes plaques pour casser la répétition.
static func ground_material(tex: Texture2D, variation: float = 0.07) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = GROUND_SHADER
	m.set_shader_parameter("tex", tex)
	m.set_shader_parameter("variation", variation)
	return m


## a = haut-gauche, b = haut-droite, c = bas-droite, d = bas-gauche, vus de face.
static func quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, uv0: Vector2 = Vector2.ZERO, uv1: Vector2 = Vector2.ONE) -> void:
	var n := (d - a).cross(b - a).normalized()
	var v: Array[Vector3] = [a, b, c, d]
	var uv: Array[Vector2] = [uv0, Vector2(uv1.x, uv0.y), uv1, Vector2(uv0.x, uv1.y)]
	for i: int in [0, 1, 2, 0, 2, 3]:
		st.set_normal(n)
		st.set_uv(uv[i])
		st.add_vertex(v[i])


## Triangle a, b, c dans le sens horaire vu de face.
static func tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, uva: Vector2, uvb: Vector2, uvc: Vector2) -> void:
	var n := (c - a).cross(b - a).normalized()
	st.set_normal(n)
	st.set_uv(uva)
	st.add_vertex(a)
	st.set_normal(n)
	st.set_uv(uvb)
	st.add_vertex(b)
	st.set_normal(n)
	st.set_uv(uvc)
	st.add_vertex(c)


## Boîte (sans dessous) dont les UV suivent les dimensions réelles : densité de pixels constante.
static func box(st: SurfaceTool, center: Vector3, size: Vector3) -> void:
	var x0 := center.x - size.x * 0.5
	var x1 := center.x + size.x * 0.5
	var y0 := center.y - size.y * 0.5
	var y1 := center.y + size.y * 0.5
	var z0 := center.z - size.z * 0.5
	var z1 := center.z + size.z * 0.5
	var u := size.x / TEX_UNITS
	var v := size.y / TEX_UNITS
	var w := size.z / TEX_UNITS
	# dessus
	quad(st, Vector3(x0, y1, z0), Vector3(x1, y1, z0), Vector3(x1, y1, z1), Vector3(x0, y1, z1), Vector2.ZERO, Vector2(u, w))
	# avant (+Z)
	quad(st, Vector3(x0, y1, z1), Vector3(x1, y1, z1), Vector3(x1, y0, z1), Vector3(x0, y0, z1), Vector2.ZERO, Vector2(u, v))
	# arrière (-Z)
	quad(st, Vector3(x1, y1, z0), Vector3(x0, y1, z0), Vector3(x0, y0, z0), Vector3(x1, y0, z0), Vector2.ZERO, Vector2(u, v))
	# droite (+X)
	quad(st, Vector3(x1, y1, z1), Vector3(x1, y1, z0), Vector3(x1, y0, z0), Vector3(x1, y0, z1), Vector2.ZERO, Vector2(w, v))
	# gauche (-X)
	quad(st, Vector3(x0, y1, z0), Vector3(x0, y1, z1), Vector3(x0, y0, z1), Vector3(x0, y0, z0), Vector2.ZERO, Vector2(w, v))


static func begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st


static func finish(st: SurfaceTool, material: Material, double_shadow: bool = true) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = st.commit()
	node.material_override = material
	if double_shadow:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	return node


## Matériau « pixel art » : texture nette (nearest), mat, sans reflet.
static func pixel_material(tex: Texture2D, emission_tex: Texture2D = null, emission_energy: float = 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.roughness = 1.0
	m.metallic_specular = 0.0
	if emission_tex != null:
		m.emission_enabled = true
		m.emission = Color.WHITE
		m.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
		m.emission_texture = emission_tex
		m.emission_energy_multiplier = emission_energy
	return m


static func flat_material(color: Color, emission_energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 1.0
	m.metallic_specular = 0.0
	if emission_energy > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission_energy
	return m
