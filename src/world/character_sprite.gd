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
	_quad.material_override = Sprites.sprite_material(tex)
	_quad.position.y = h * 0.5 - float(sheet.foot) / ppu
	_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	add_child(_quad)

	# petite ombre de contact sous les pieds
	var blob := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(0.95, 0.42)
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
