extends Node3D
## Affiche et anime un personnage à partir d'une planche fournie par Sprites.character().

const MeshKit = preload("res://src/gfx/mesh_kit.gd")

var sheet: Dictionary = {}
var facing: String = "down"
var moving: bool = false
var height: float = 2.0
## Pose imposée ("attack", "cast", "hit", "ko") ; vide = marche ou repos.
var pose: String = ""

var _quad: MeshInstance3D
var _time := 0.0
var _shown := -1
var _was_moving := false
var _idle := randf() * 12.0


func setup(p_sheet: Dictionary) -> void:
	sheet = p_sheet
	var ppu: float = sheet.ppu
	var w: float = float(sheet.frame_w) / ppu
	var h: float = float(sheet.frame_h) / ppu
	height = h
	var tex: Texture2D = sheet.texture
	_quad = MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(w, h)
	_quad.mesh = mesh
	_quad.material_override = Sprites.sprite_material(tex, 0.0, 0.0, false)
	_quad.position.y = h * 0.5 - float(sheet.foot) / ppu
	_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	add_child(_quad)

	# petite ombre de contact sous les pieds
	var blob := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(1.1, 0.5)
	blob.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = Sprites.prop("blob_shadow")
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blob.material_override = mat
	blob.position = Vector3(0, 0.02, 0.04)
	blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(blob)
	_apply()


func _process(delta: float) -> void:
	if moving:
		if not _was_moving:
			_time = 0.0
		_time += delta * float(sheet.get("fps", 7.0))
	_was_moving = moving
	_idle += delta * float(sheet.get("idle_fps", 4.0))
	_apply()


func _apply() -> void:
	if _quad == null:
		return
	var col: int = int(sheet.idle)
	var poses: Dictionary = sheet.get("poses", {})
	if pose != "" and poses.has(pose):
		col = int(poses[pose])
	elif moving:
		var walk: Array = sheet.walk
		col = int(walk[int(_time) % walk.size()])
	else:
		var seq: Array = sheet.get("idle_seq", [])
		if not seq.is_empty():
			col = int(seq[int(_idle) % seq.size()])
	var rows: Dictionary = sheet.rows
	var flip := false
	var row := 0
	if rows.has(facing):
		row = int(rows[facing])
	elif facing == "right" and rows.has("left"):
		row = int(rows["left"])
		flip = true
	elif facing == "left" and rows.has("right"):
		row = int(rows["right"])
		flip = true
	var key := row * 1000 + col * 2 + (1 if flip else 0)
	if key == _shown:
		return
	_shown = key
	var cw := 1.0 / float(sheet.columns)
	var rh := 1.0 / float(sheet.row_count)
	var rect := Vector4(col * cw, row * rh, cw, rh)
	if flip:
		rect = Vector4((col + 1) * cw, row * rh, -cw, rh)
	_quad.set_instance_shader_parameter("frame_rect", rect)


## Lumière propre du personnage (ambiances sombres, champ « lantern » de data/ambiances.json) :
## halo doux au sol, liseré clair sur la silhouette et, si « strong », lanterne qui éclaire les alentours.
func add_lantern(spec: Dictionary, strong: bool) -> void:
	var col := Color.from_string(str(spec.get("color", "#ffd9a0")), Color(1.0, 0.85, 0.63))
	var k := 1.0 if strong else 0.55
	var halo := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	var r := float(spec.get("halo", 3.2)) * (1.0 if strong else 0.7)
	plane.size = Vector2(r, r)
	halo.mesh = plane
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 1))
	grad.set_color(1, Color(1, 1, 1, 0))
	grad.set_offset(1, 1.0)
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.albedo_color = Color(col.r, col.g, col.b, float(spec.get("halo_alpha", 0.3)) * k)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	halo.material_override = mat
	halo.position = Vector3(0.0, 0.05, 0.1)
	halo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(halo)
	if strong:
		var l := OmniLight3D.new()
		l.light_color = col
		l.light_energy = float(spec.get("energy", 1.3))
		l.omni_range = float(spec.get("range", 7.0))
		l.omni_attenuation = 1.2
		l.shadow_enabled = false
		l.light_volumetric_fog_energy = 0.6
		l.position = Vector3(0.0, height * 0.75, 0.9)
		add_child(l)
	if _quad != null:
		_quad.set_instance_shader_parameter("rim", float(spec.get("rim", 0.7)) * k)
