extends RefCounted
## Le « look » HD-2D : environnement (brouillard, glow, tonemap), soleil rasant, particules.
## Tous les réglages viennent de data/ambiances.json.

const Flicker = preload("res://src/world/light_flicker.gd")
const RAYS_SHADER = preload("res://src/gfx/shaders/rays.gdshader")
## Particules qu'une ambiance peut demander (le test automatique vérifie les données).
const PARTICLES: Array = ["fireflies", "pollen", "leaves", "dust", "fire", "embers", "smoke", "embruns", "feuilles_dorees", "lueurs"]


static func _c(d: Dictionary, key: String, fallback: String) -> Color:
	return Color.from_string(str(d.get(key, fallback)), Color.from_string(fallback, Color.WHITE))


static func _sub(d: Dictionary, key: String) -> Dictionary:
	var v: Variant = d.get(key, {})
	if v is Dictionary:
		return v
	return {}


## Construit l'ambiance dans le monde. Renvoie les nœuds qui doivent suivre la caméra.
## « area » : le rectangle au sol (x, z) où planter les rayons de lumière, s'il y en a.
static func build(world: Node3D, amb: Dictionary, area: Rect2 = Rect2()) -> Array:
	var rays := _sub(amb, "rays")
	if not rays.is_empty() and area.size.x > 0.0:
		make_rays(world, area, rays)
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = _c(amb, "background", "#14122a")

	var ambient := _sub(amb, "ambient")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = _c(ambient, "color", "#6a70b8")
	env.ambient_light_energy = float(ambient.get("energy", 0.5))

	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = float(amb.get("exposure", 1.0))
	env.tonemap_white = float(amb.get("white", 4.0))

	var glow := _sub(amb, "glow")
	env.glow_enabled = true
	env.glow_intensity = float(glow.get("intensity", 0.8))
	env.glow_strength = float(glow.get("strength", 1.0))
	env.glow_bloom = float(glow.get("bloom", 0.05))
	env.glow_hdr_threshold = float(glow.get("threshold", 1.0))
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN

	var fog := _sub(amb, "fog")
	if not fog.is_empty():
		env.fog_enabled = true
		env.fog_light_color = _c(fog, "color", "#3a3560")
		env.fog_density = float(fog.get("density", 0.008))
		env.fog_sun_scatter = float(fog.get("sun_scatter", 0.1))

	var vol := _sub(amb, "volumetric")
	if not vol.is_empty():
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = float(vol.get("density", 0.012))
		env.volumetric_fog_albedo = _c(vol, "albedo", "#c9b8e8")
		env.volumetric_fog_emission = _c(vol, "emission", "#2a2848")
		env.volumetric_fog_emission_energy = float(vol.get("emission_energy", 0.3))
		env.volumetric_fog_length = float(vol.get("length", 72.0))
		env.volumetric_fog_anisotropy = float(vol.get("anisotropy", 0.3))

	env.ssao_enabled = true
	env.ssao_radius = 0.7
	env.ssao_intensity = float(amb.get("ssao", 1.6))

	env.adjustment_enabled = true
	env.adjustment_saturation = float(amb.get("saturation", 1.1))
	env.adjustment_contrast = float(amb.get("contrast", 1.05))

	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	var sun := _sub(amb, "sun")
	if not sun.is_empty():
		var light := DirectionalLight3D.new()
		light.light_color = _c(sun, "color", "#ff9d66")
		light.light_energy = float(sun.get("energy", 0.8))
		light.light_volumetric_fog_energy = float(sun.get("fog_energy", 0.6))
		light.shadow_enabled = true
		light.shadow_blur = 1.3
		light.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
		light.directional_shadow_max_distance = 75.0
		world.add_child(light)
		var dir_a: Variant = sun.get("direction", [0.55, -0.45, -0.7])
		var dir := Vector3(0.55, -0.45, -0.7)
		if dir_a is Array and (dir_a as Array).size() == 3:
			dir = Vector3(float(dir_a[0]), float(dir_a[1]), float(dir_a[2]))
		light.look_at_from_position(Vector3.ZERO, dir.normalized(), Vector3.UP)

	var followers: Array = []
	var kinds: Variant = amb.get("particles", [])
	if kinds is Array:
		for kind: Variant in kinds:
			var p := make_particles(str(kind))
			if p != null:
				p.position.y = 1.3
				world.add_child(p)
				followers.append(p)
	return followers


## Rayons de lumière obliques, plantés au hasard dans la zone (toujours les mêmes pour un lieu).
static func make_rays(world: Node3D, area: Rect2, spec: Dictionary) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = RAYS_SHADER
	var tint := _c(spec, "color", "#ffd9a0")
	mat.set_shader_parameter("tint", Vector3(tint.r, tint.g, tint.b))
	mat.set_shader_parameter("strength", float(spec.get("strength", 0.1)))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(area.size.x * 31.0 + area.size.y * 17.0) + 5
	var count := clampi(int(area.get_area() * float(spec.get("density", 0.01))), 3, 40)
	var tilt := float(spec.get("tilt", 0.5))
	for i in count:
		var height := float(spec.get("height", 9.0)) * rng.randf_range(0.8, 1.2)
		var quad := QuadMesh.new()
		quad.size = Vector2(rng.randf_range(2.0, 4.2), height)
		var ray := MeshInstance3D.new()
		ray.mesh = quad
		ray.material_override = mat
		ray.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var foot := Vector2(rng.randf_range(area.position.x, area.end.x), rng.randf_range(area.position.y, area.end.y))
		ray.rotation.z = tilt
		ray.position = Vector3(foot.x - sin(tilt) * height * 0.5, cos(tilt) * height * 0.5 - 0.3, foot.y)
		world.add_child(ray)
		ray.set_instance_shader_parameter("phase", rng.randf() * TAU)


static func _gradient(colors: Array, offsets: Array) -> Gradient:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(offsets)
	g.colors = PackedColorArray(colors)
	return g


static func _particle_material(color: Color, additive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if additive:
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = Sprites.prop("dot")
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.albedo_color = color
	return m


static func _curve(a: float, b: float) -> Curve:
	var c := Curve.new()
	c.add_point(Vector2(0.0, a))
	c.add_point(Vector2(1.0, b))
	return c


## Fabrique un émetteur de particules d'ambiance.
static func make_particles(kind: String) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	var quad := QuadMesh.new()
	p.local_coords = false
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	var fade_in_out := _gradient([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)], [0.0, 0.2, 0.75, 1.0])
	match kind:
		"fireflies":
			quad.size = Vector2(0.13, 0.13)
			quad.material = _particle_material(Color(2.6, 2.4, 0.9), true)
			p.amount = 46
			p.lifetime = 6.0
			p.preprocess = 6.0
			p.emission_box_extents = Vector3(13.0, 0.9, 9.0)
			p.direction = Vector3(0, 1, 0)
			p.spread = 180.0
			p.gravity = Vector3(0, 0.02, 0)
			p.initial_velocity_min = 0.1
			p.initial_velocity_max = 0.4
			p.scale_amount_min = 0.5
			p.scale_amount_max = 1.2
			p.color_ramp = fade_in_out
		"pollen":
			quad.size = Vector2(0.06, 0.06)
			quad.material = _particle_material(Color(1.4, 1.2, 1.0), true)
			p.amount = 60
			p.lifetime = 9.0
			p.preprocess = 9.0
			p.emission_box_extents = Vector3(14.0, 2.2, 10.0)
			p.direction = Vector3(1, 0.1, 0.2)
			p.spread = 25.0
			p.gravity = Vector3(0, -0.01, 0)
			p.initial_velocity_min = 0.15
			p.initial_velocity_max = 0.5
			p.scale_amount_min = 0.6
			p.scale_amount_max = 1.4
			p.color_ramp = fade_in_out
		"leaves":
			quad.size = Vector2(0.1, 0.1)
			quad.material = _particle_material(Color(0.95, 0.55, 0.2), false)
			p.amount = 26
			p.lifetime = 8.0
			p.preprocess = 8.0
			p.emission_box_extents = Vector3(14.0, 2.6, 9.0)
			p.direction = Vector3(1, -0.6, 0.1)
			p.spread = 30.0
			p.gravity = Vector3(0.12, -0.22, 0)
			p.initial_velocity_min = 0.2
			p.initial_velocity_max = 0.6
			p.scale_amount_min = 0.6
			p.scale_amount_max = 1.3
			p.color_ramp = fade_in_out
		"dust":
			quad.size = Vector2(0.05, 0.05)
			quad.material = _particle_material(Color(1.6, 1.2, 0.8), true)
			p.amount = 46
			p.lifetime = 8.0
			p.preprocess = 8.0
			p.emission_box_extents = Vector3(8.0, 1.3, 5.0)
			p.direction = Vector3(0.3, 1, 0)
			p.spread = 60.0
			p.gravity = Vector3.ZERO
			p.initial_velocity_min = 0.03
			p.initial_velocity_max = 0.14
			p.scale_amount_min = 0.6
			p.scale_amount_max = 1.3
			p.color_ramp = fade_in_out
		"fire":
			quad.size = Vector2(0.2, 0.2)
			quad.material = _particle_material(Color(2.6, 2.0, 1.3), true)
			p.amount = 30
			p.lifetime = 0.75
			p.preprocess = 1.0
			p.emission_box_extents = Vector3(0.28, 0.04, 0.08)
			p.direction = Vector3(0, 1, 0)
			p.spread = 10.0
			p.gravity = Vector3(0, 1.4, 0)
			p.initial_velocity_min = 0.6
			p.initial_velocity_max = 1.3
			p.scale_amount_min = 1.0
			p.scale_amount_max = 2.0
			p.scale_amount_curve = _curve(1.0, 0.15)
			p.color_ramp = _gradient([Color(1, 0.95, 0.6, 1), Color(1, 0.55, 0.15, 0.9), Color(0.8, 0.15, 0.05, 0)], [0.0, 0.45, 1.0])
		"embers":
			quad.size = Vector2(0.05, 0.05)
			quad.material = _particle_material(Color(3.0, 1.6, 0.6), true)
			p.amount = 10
			p.lifetime = 2.2
			p.emission_box_extents = Vector3(0.3, 0.05, 0.1)
			p.direction = Vector3(0, 1, 0.25)
			p.spread = 25.0
			p.gravity = Vector3(0, 0.3, 0)
			p.initial_velocity_min = 0.4
			p.initial_velocity_max = 0.9
			p.color_ramp = fade_in_out
		"smoke":
			quad.size = Vector2(0.3, 0.3)
			quad.material = _particle_material(Color(0.62, 0.6, 0.72), false)
			p.amount = 14
			p.lifetime = 4.5
			p.preprocess = 4.5
			p.emission_box_extents = Vector3(0.1, 0.02, 0.1)
			p.direction = Vector3(0.25, 1, 0)
			p.spread = 8.0
			p.gravity = Vector3(0.08, 0.05, 0)
			p.initial_velocity_min = 0.35
			p.initial_velocity_max = 0.6
			p.scale_amount_min = 1.0
			p.scale_amount_max = 1.6
			p.scale_amount_curve = _curve(0.5, 2.2)
			p.color_ramp = _gradient([Color(1, 1, 1, 0), Color(1, 1, 1, 0.4), Color(1, 1, 1, 0)], [0.0, 0.2, 1.0])
		"embruns":
			quad.size = Vector2(0.16, 0.16)
			quad.material = _particle_material(Color(0.85, 0.95, 1.1), false)
			p.amount = 22
			p.lifetime = 2.6
			p.preprocess = 2.6
			p.emission_box_extents = Vector3(0.9, 0.1, 0.3)
			p.direction = Vector3(0, 1, 0.5)
			p.spread = 30.0
			p.gravity = Vector3(0, 0.1, 0)
			p.initial_velocity_min = 0.2
			p.initial_velocity_max = 0.5
			p.scale_amount_min = 0.6
			p.scale_amount_max = 1.6
			p.scale_amount_curve = _curve(0.6, 1.8)
			p.color_ramp = _gradient([Color(1, 1, 1, 0), Color(1, 1, 1, 0.35), Color(1, 1, 1, 0)], [0.0, 0.25, 1.0])
		"feuilles_dorees":
			quad.size = Vector2(0.12, 0.09)
			quad.material = _particle_material(Color(1.5, 1.05, 0.35), false)
			p.amount = 38
			p.lifetime = 9.0
			p.preprocess = 9.0
			p.emission_box_extents = Vector3(14.0, 2.8, 9.0)
			p.direction = Vector3(1, -0.5, 0.2)
			p.spread = 35.0
			p.gravity = Vector3(0.1, -0.2, 0)
			p.initial_velocity_min = 0.2
			p.initial_velocity_max = 0.55
			p.angle_max = 360.0
			p.angular_velocity_min = -90.0
			p.angular_velocity_max = 90.0
			p.scale_amount_min = 0.6
			p.scale_amount_max = 1.4
			p.color_ramp = fade_in_out
		"lueurs":
			quad.size = Vector2(0.1, 0.1)
			quad.material = _particle_material(Color(0.8, 1.3, 2.2), true)
			p.amount = 40
			p.lifetime = 7.0
			p.preprocess = 7.0
			p.emission_box_extents = Vector3(13.0, 1.2, 9.0)
			p.direction = Vector3(0, 1, 0)
			p.spread = 180.0
			p.gravity = Vector3(0, 0.02, 0)
			p.initial_velocity_min = 0.05
			p.initial_velocity_max = 0.25
			p.scale_amount_min = 0.5
			p.scale_amount_max = 1.2
			p.color_ramp = fade_in_out
		_:
			return null
	p.mesh = quad
	return p


## Lumière ponctuelle chaude, vacillante si demandé.
static func make_light(color: Color, energy: float, light_range: float, shadow: bool, flicker: float = 0.0) -> OmniLight3D:
	var l := OmniLight3D.new()
	if flicker > 0.0:
		l.set_script(Flicker)
		l.set("amount", flicker)
	l.light_color = color
	l.light_energy = energy
	l.omni_range = light_range
	l.omni_attenuation = 1.4
	l.shadow_enabled = shadow
	l.shadow_blur = 1.5
	l.light_volumetric_fog_energy = 1.4
	return l
