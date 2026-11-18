extends Node3D
## Un combattant à l'écran : son sprite (personnage ou monstre) et ses petites
## animations (pas en avant, assaut, clignotement quand il est touché, chute).

const CharacterSprite = preload("res://src/world/character_sprite.gd")

var combatant: RefCounted
var home := Vector3.ZERO
var height := 1.6          # hauteur du sprite, en unités monde
var fast := false          # tests : aucune animation
var down := false

var _dir := -1.0           # sens « vers l'adversaire » sur l'axe x
var _body: Node3D          # pivot du sprite (posé aux pieds)
var _quad: MeshInstance3D
var _char: Node3D = null   # CharacterSprite, pour un personnage
var _sheet: Dictionary = {}
var _hover := 0.0
var _time := 0.0
var _frame := -1
var _flash := 0.0
var _active := false
var _move: Tween


func setup(p_combatant: RefCounted, p_home: Vector3) -> void:
	combatant = p_combatant
	home = p_home
	position = home
	_dir = -1.0 if combatant.side == "party" else 1.0
	_time = randf() * 3.0
	var sp: Dictionary = combatant.sprite
	var scale_k := float(sp.get("scale", 1.0))
	_hover = float(sp.get("hover", 0.0))
	_body = Node3D.new()
	add_child(_body)
	if sp.has("character"):
		_char = CharacterSprite.new()
		_body.add_child(_char)
		_char.setup(Sprites.character(str(sp["character"])))
		_char.facing = "left" if combatant.side == "party" else "right"
		_quad = _char._quad
		height = float(_char.height) * scale_k
		var glow := float(sp.get("glow", 0.0))
		if glow > 0.0:
			var tex: Texture2D = Sprites.character(str(sp["character"]))["texture"]
			_quad.material_override = Sprites.sprite_material(tex, 0.0, glow)
	else:
		_sheet = Sprites.monster(str(sp.get("monster", "")))
		var ppu := float(_sheet["ppu"])
		var w := float(_sheet["frame_w"]) / ppu
		var h := float(_sheet["frame_h"]) / ppu
		_quad = MeshInstance3D.new()
		var mesh := QuadMesh.new()
		mesh.size = Vector2(w, h)
		_quad.mesh = mesh
		_quad.material_override = Sprites.sprite_material(_sheet["texture"], 0.0, float(sp.get("glow", 0.0)))
		_quad.position.y = h * 0.5 - float(_sheet["foot"]) / ppu
		_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		_body.add_child(_quad)
		height = h * scale_k
		var blob := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2(w * 0.8, 0.45) * scale_k
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
		# un monstre placé du côté de l'équipe (jamais le cas pour l'instant) serait retourné
		if combatant.side == "party":
			_body.scale.x = -1.0
	_body.scale *= scale_k
	_body.position.y = _hover
	_animate(0.0)


func _process(delta: float) -> void:
	_animate(delta)


func _animate(delta: float) -> void:
	_time += delta
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 4.0)
		_quad.set_instance_shader_parameter("flash", _flash)
	if down:
		return
	if _char == null and not _sheet.is_empty():
		var cols := int(_sheet["columns"])
		var f := int(_time * float(_sheet["fps"])) % cols
		if f != _frame:
			_frame = f
			_quad.set_instance_shader_parameter("frame_rect", Vector4(float(f) / cols, 0.0, 1.0 / cols, 1.0))
	if _hover > 0.0:
		_body.position.y = _hover + sin(_time * 3.2) * 0.09


## Point visé par les effets et les chiffres : "top", "center" ou "feet".
func anchor(where: String = "center") -> Vector3:
	var p := global_position
	match where:
		"top": p.y += _hover + height * 0.78
		"center": p.y += _hover + height * 0.55
	return p


func _tween() -> Tween:
	if _move != null and _move.is_valid():
		_move.kill()
	_move = create_tween()
	return _move


## Celui qui joue fait un pas vers l'adversaire.
func set_active(active: bool) -> void:
	if _active == active or down:
		return
	_active = active
	var target := home + Vector3(_dir * 0.35, 0.0, 0.0) if active else home
	if fast:
		position = target
		return
	if _char != null:
		_char.moving = true
	var tw := _tween()
	tw.tween_property(self, "position", target, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		if _char != null:
			_char.moving = false)


## Assaut : bond vers la cible puis retour à sa place.
func play_attack(toward: Vector3) -> void:
	if fast or down:
		return
	var from := position
	var to := from.lerp(Vector3(toward.x - _dir * 1.3, 0.0, toward.z), 0.72)
	var tw := _tween()
	tw.tween_property(self, "position", to, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_interval(0.1)
	tw.tween_property(self, "position", from, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(0.16).timeout


## Incantation : petit saut sur place.
func play_cast() -> void:
	if fast or down:
		return
	var y := _body.position.y
	var tw := create_tween()
	tw.tween_property(_body, "position:y", y + 0.3, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_body, "position:y", y, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await get_tree().create_timer(0.24).timeout


func play_hit() -> void:
	_flash = 1.0
	_quad.set_instance_shader_parameter("flash", 1.0)
	if fast or down:
		return
	var x := _body.position.x
	var tw := create_tween()
	tw.tween_property(_body, "position:x", x - _dir * 0.16, 0.04)
	tw.tween_property(_body, "position:x", x + _dir * 0.1, 0.06)
	tw.tween_property(_body, "position:x", x, 0.06)


## Un allié s'effondre sur place ; un ennemi se dissipe.
func play_ko() -> void:
	down = true
	_active = false
	if _move != null and _move.is_valid():
		_move.kill()
	position = home
	if combatant.side == "party":
		if fast:
			_body.rotation.z = -PI * 0.5
			_body.position = Vector3(-0.4, 0.15, 0.0)
			return
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_body, "rotation:z", -PI * 0.5, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_property(_body, "position", Vector3(-0.4, 0.15, 0.0), 0.3)
		await tw.finished
	else:
		if fast:
			visible = false
			return
		_flash = 1.0
		_quad.set_instance_shader_parameter("flash", 1.0)
		var s := _body.scale
		var tw := create_tween().set_parallel(true)
		tw.tween_property(_body, "scale", Vector3(s.x * 1.25, s.y * 0.04, s.z), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw.finished
		visible = false


func play_revive() -> void:
	down = false
	_body.rotation.z = 0.0
	_body.position = Vector3(0.0, _hover, 0.0)
	visible = true
	_flash = 1.0
