extends Node3D
## Un combattant à l'écran : son sprite (personnage ou monstre) et ses petites
## animations (pas en avant, assaut, clignotement quand il est touché, chute).

const CharacterSprite = preload("res://src/world/character_sprite.gd")

var combatant: RefCounted
var home := Vector3.ZERO
var height := 1.6          # hauteur du sprite, en unités monde
var fast := false          # tests : aucune animation
var down := false
var step := 0.7            # longueur du pas en avant quand il joue (la scène la réduit si un voisin gênerait)

var _dir := -1.0           # sens « vers l'adversaire » sur l'axe x
var _body: Node3D          # pivot du sprite (posé aux pieds)
var _quad: MeshInstance3D
var _char: Node3D = null   # CharacterSprite, pour un personnage
var _sheet: Dictionary = {}
var _hover := 0.0
var _time := 0.0
var _frame := -1
var _flash := 0.0
var charge := 0              # points d'élan engagés : le héros se charge (halo qui pulse)
var stunned := false         # bouclier brisé : l'ennemi vacille
var _aura_on := false
var _active := false
var _move: Tween
var _pose_tw: Tween
var _hit_tw: Tween
var _base_scale := Vector3.ONE


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
		_contact_shadow(1.0 * scale_k)
		var glow := float(sp.get("glow", 0.0))
		if glow > 0.0:
			var tex: Texture2D = Sprites.character(str(sp["character"]))["texture"]
			_quad.material_override = Sprites.sprite_material(tex, 0.0, glow, false)
	else:
		_sheet = Sprites.monster(str(sp.get("monster", "")))
		var ppu := float(_sheet["ppu"])
		var w := float(_sheet["frame_w"]) / ppu
		var h := float(_sheet["frame_h"]) / ppu
		_quad = MeshInstance3D.new()
		var mesh := QuadMesh.new()
		mesh.size = Vector2(w, h)
		_quad.mesh = mesh
		_quad.material_override = Sprites.sprite_material(_sheet["texture"], 0.0, float(sp.get("glow", 0.0)), false)
		_quad.position.y = h * 0.5 - float(_sheet["foot"]) / ppu
		_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		_body.add_child(_quad)
		height = h * scale_k
		_contact_shadow(w * 0.85 * scale_k)
		# un monstre placé du côté de l'équipe (jamais le cas pour l'instant) serait retourné
		if combatant.side == "party":
			_body.scale.x = -1.0
	_quad.set_instance_shader_parameter("rim", 0.7)   # liseré de contre-jour (voir sprite.gdshader)
	_body.scale *= scale_k
	_base_scale = _body.scale
	_body.position.y = _hover
	_animate(0.0)


static var _shadow_tex: Texture2D = null


## Ombre de contact franche sous les pieds : ovale sombre à bord net, au sol, sous chaque combattant.
func _contact_shadow(width: float) -> void:
	if _shadow_tex == null:
		var img := Image.create(32, 12, false, Image.FORMAT_RGBA8)
		for y in 12:
			for x in 32:
				var d := Vector2((x - 15.5) / 15.5, (y - 5.5) / 5.5).length()
				var a := 0.0
				if d < 0.62:
					a = 0.72
				elif d < 1.0:
					a = 0.34
				img.set_pixel(x, y, Color(0.02, 0.01, 0.03, a))
		_shadow_tex = ImageTexture.create_from_image(img)
	var blob := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(width, width * 0.38)
	blob.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _shadow_tex
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blob.material_override = mat
	blob.position = Vector3(0, 0.02, 0.06)
	blob.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(blob)


var _mpose := ""   # pose imposée à un monstre ("attack", "hit")


func _process(delta: float) -> void:
	_animate(delta)


func _animate(delta: float) -> void:
	_time += delta
	var aura := 0.0
	if charge > 0 and not down:
		aura = (0.1 + 0.06 * float(charge)) * (0.65 + 0.35 * sin(_time * 9.0))
	if _flash > 0.0 or aura > 0.0 or _aura_on:
		_flash = maxf(0.0, _flash - delta * 4.0)
		_quad.set_instance_shader_parameter("flash", maxf(_flash, aura))
		_aura_on = aura > 0.0
	if down:
		return
	_monster_frame()
	if stunned and not fast and not posing() and (_hit_tw == null or not _hit_tw.is_running()):
		_body.rotation.z = sin(_time * 2.6) * 0.07   # vacille, hébété
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


## Demi-largeur (unités monde) de son sprite, d'après le dessin lui-même.
func half_width() -> float:
	if _quad != null and _quad.mesh is QuadMesh:
		return (_quad.mesh as QuadMesh).size.x * absf(_body.scale.x) * 0.5 * 0.7   # le dessin visible tient dans la case, avec une marge transparente
	return 0.4


## Où il se tient quand il joue : un pas vers l'adversaire.
func stepped_home() -> Vector3:
	return home + Vector3(_dir * step, 0.0, 0.0)


## Celui qui joue fait un pas vers l'adversaire.
func set_active(active: bool) -> void:
	if _active == active or down:
		return
	_active = active
	var target := stepped_home() if active else home
	if fast:
		position = target
		return
	if not active and posing():
		# une pose est en cours : on rentre à sa place quand elle est finie
		_pose_tw.finished.connect(_go_home, CONNECT_ONE_SHOT)
		return
	if _char != null:
		_char.moving = true
	var tw := _tween()
	tw.tween_property(self, "position", target, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		if _char != null:
			_char.moving = false)


func _go_home() -> void:
	if _active or down:
		return
	var tw := _tween()
	tw.tween_property(self, "position", home, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


## Dessin de pose du personnage (sans effet sur un monstre).
func _set_pose(p: String) -> void:
	if _char != null:
		_char.pose = p
		return
	_mpose = p
	if p == "ko":
		_mpose = "hit"
	elif p == "cast":
		_mpose = "attack"
	_monster_frame()


## Image d'un monstre : sa pose imposée si la planche l'a, sinon la boucle de repos.
func _monster_frame() -> void:
	if _char != null or _sheet.is_empty() or _quad == null:
		return
	var cols := int(_sheet["columns"])
	var idle: Array = _sheet.get("idle", [0])
	var f := int(idle[int(_time * float(_sheet["fps"])) % idle.size()])
	var poses: Dictionary = _sheet.get("poses", {})
	if poses.has(_mpose):
		f = int(poses[_mpose])
	if f != _frame:
		_frame = f
		_quad.set_instance_shader_parameter("frame_rect", Vector4(float(f) / cols, 0.0, 1.0 / cols, 1.0))


func _reset_body() -> void:
	_set_pose("")
	if _pose_tw != null and _pose_tw.is_valid():
		_pose_tw.kill()
	if _hit_tw != null and _hit_tw.is_valid():
		_hit_tw.kill()
	_body.rotation.z = 0.0
	_body.scale = _base_scale
	_body.position = Vector3(0.0, _hover, 0.0)


## Vrai tant qu'une pose est en cours (les tests attendent qu'elle se termine).
func posing() -> bool:
	return _pose_tw != null and _pose_tw.is_valid() and _pose_tw.is_running()


## Pose du lanceur pendant une animation (voir data/animations.json, champ « pose »).
## impact : moment où le coup porte, en secondes. La pose se joue seule et se défait seule.
##   strike  élan, bond vers la cible et coup        charge  course tête baissée
##   sneak   disparaît, frappe dans le dos           stomp   saut et retombée lourde
##   spin    tour sur soi au contact                 cast    s'élève, bras tendus
##   throw   bras en arrière puis lancer             shoot   vise, puis recul du tir
##   sleep   bascule en arrière, assoupi             eat     hoche, la bouche pleine
##   guard   se ramasse derrière sa garde            shout   prend son souffle et crie
func play_pose(pose: String, toward: Vector3, impact: float) -> void:
	if fast or down or pose == "none" or pose == "":
		return
	_reset_body()
	if _move != null and _move.is_valid():
		_move.kill()
	if _char != null:
		_char.moving = false
	var lean := -_dir   # signe d'une rotation qui penche vers l'adversaire
	var s := _base_scale
	var by := _hover
	var from := position
	var near := from.lerp(Vector3(toward.x - _dir * 1.15, 0.0, toward.z), 0.92)   # au contact
	var tw := create_tween()
	_pose_tw = tw
	var drawn := "attack"
	if pose == "cast" or pose == "shout":
		drawn = "cast"
	elif pose == "sleep" or pose == "eat" or pose == "guard":
		drawn = ""
	_set_pose(drawn)
	tw.finished.connect(_set_pose.bind(""))
	match pose:
		"strike":
			var wind := maxf(0.06, impact - 0.1)
			tw.tween_property(_body, "rotation:z", -lean * 0.24, wind * 0.6)
			tw.parallel().tween_property(self, "position", near, wind).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_property(_body, "rotation:z", lean * 0.3, 0.08)
			tw.tween_interval(0.16)
			tw.tween_property(_body, "rotation:z", 0.0, 0.14)
			tw.parallel().tween_property(self, "position", from, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		"charge":
			var run := maxf(0.08, impact - 0.04)
			var far := Vector3(toward.x - _dir * 0.8, 0.0, toward.z)
			tw.tween_property(_body, "rotation:z", lean * 0.32, 0.08)
			tw.parallel().tween_property(self, "position", far, run).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_interval(0.1)
			tw.tween_property(self, "position", far - Vector3(_dir * 0.3, 0.0, 0.0), 0.1)
			tw.parallel().tween_property(_body, "rotation:z", -lean * 0.15, 0.1)
			tw.tween_property(self, "position", from, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(_body, "rotation:z", 0.0, 0.2)
		"sneak":
			var behind := Vector3(toward.x + _dir * 1.0, 0.0, toward.z)
			var hide := maxf(0.05, (impact - 0.12) * 0.5)
			tw.tween_property(_body, "scale:x", 0.0, hide)
			tw.tween_callback(func() -> void: position = behind)
			tw.tween_property(_body, "scale:x", -s.x, hide)
			tw.tween_property(_body, "rotation:z", -lean * 0.4, 0.07)
			tw.tween_interval(0.16)
			tw.tween_property(_body, "scale:x", 0.0, 0.08)
			tw.tween_callback(func() -> void:
				position = from
				_body.rotation.z = 0.0)
			tw.tween_property(_body, "scale:x", s.x, 0.1)
		"stomp":
			var up := maxf(0.08, impact - 0.1)
			tw.tween_property(self, "position", near, up)
			tw.parallel().tween_property(_body, "position:y", by + 1.3, up).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(_body, "position:y", by, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.tween_property(_body, "scale", Vector3(s.x * 1.2, s.y * 0.72, s.z), 0.05)
			tw.tween_property(_body, "scale", s, 0.14)
			tw.tween_property(self, "position", from, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		"spin":
			var go := maxf(0.08, impact - 0.2)
			tw.tween_property(self, "position", near, go).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			for k in 2:
				tw.tween_property(_body, "scale:x", -s.x, 0.09)
				tw.tween_property(_body, "scale:x", s.x, 0.09)
			tw.tween_property(self, "position", from, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		"cast":
			tw.tween_property(_body, "position:y", by + 0.3, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.parallel().tween_property(_body, "scale", Vector3(s.x * 0.92, s.y * 1.1, s.z), 0.16)
			tw.tween_interval(maxf(0.02, impact - 0.24))
			tw.tween_property(_body, "rotation:z", lean * 0.18, 0.06)
			tw.parallel().tween_property(_body, "position:y", by, 0.08)
			tw.tween_property(_body, "scale", s, 0.14)
			tw.parallel().tween_property(_body, "rotation:z", 0.0, 0.18)
		"throw":
			tw.tween_property(_body, "rotation:z", -lean * 0.32, 0.1)
			tw.tween_property(_body, "rotation:z", lean * 0.36, 0.06)
			tw.parallel().tween_property(_body, "position:x", _dir * 0.2, 0.06)
			tw.tween_interval(maxf(0.02, impact - 0.2))
			tw.tween_property(_body, "rotation:z", 0.0, 0.16)
			tw.parallel().tween_property(_body, "position:x", 0.0, 0.16)
		"shoot":
			var draw := maxf(0.06, minf(0.24, impact * 0.5))
			tw.tween_property(_body, "rotation:z", -lean * 0.14, draw)
			tw.parallel().tween_property(_body, "scale", Vector3(s.x * 1.05, s.y * 0.96, s.z), draw)
			tw.tween_property(_body, "position:x", -_dir * 0.2, 0.04)
			tw.parallel().tween_property(_body, "scale", s, 0.04)
			tw.tween_property(_body, "position:x", 0.0, 0.2)
			tw.parallel().tween_property(_body, "rotation:z", 0.0, 0.2)
		"sleep":
			tw.tween_property(_body, "rotation:z", -lean * 0.6, 0.3).set_trans(Tween.TRANS_SINE)
			tw.parallel().tween_property(_body, "scale", Vector3(s.x * 1.05, s.y * 0.92, s.z), 0.3)
			tw.tween_property(_body, "scale", Vector3(s.x * 1.0, s.y * 0.98, s.z), 0.3)
			tw.tween_interval(maxf(0.02, impact - 0.5))
			tw.tween_property(_body, "rotation:z", 0.0, 0.2)
			tw.parallel().tween_property(_body, "scale", s, 0.2)
		"eat":
			for k in 3:
				tw.tween_property(_body, "scale", Vector3(s.x * 1.08, s.y * 0.9, s.z), 0.09)
				tw.tween_property(_body, "scale", Vector3(s.x * 0.96, s.y * 1.06, s.z), 0.09)
			tw.tween_property(_body, "scale", s, 0.1)
		"guard":
			tw.tween_property(_body, "scale", Vector3(s.x * 1.14, s.y * 0.84, s.z), 0.1)
			tw.parallel().tween_property(_body, "rotation:z", lean * 0.1, 0.1)
			tw.tween_interval(maxf(0.05, impact))
			tw.tween_property(_body, "scale", s, 0.16)
			tw.parallel().tween_property(_body, "rotation:z", 0.0, 0.16)
		"shout":
			tw.tween_property(_body, "rotation:z", -lean * 0.16, 0.14)
			tw.parallel().tween_property(_body, "scale", Vector3(s.x * 1.06, s.y * 0.94, s.z), 0.14)
			tw.tween_property(_body, "rotation:z", lean * 0.26, 0.07)
			tw.parallel().tween_property(_body, "scale", Vector3(s.x * 0.94, s.y * 1.12, s.z), 0.07)
			var shakes := maxi(2, int(maxf(0.1, impact - 0.2) / 0.08))
			for k in shakes:
				tw.tween_property(_body, "position:x", 0.06 if k % 2 == 0 else -0.06, 0.04)
				tw.tween_property(_body, "position:x", 0.0, 0.04)
			tw.tween_property(_body, "rotation:z", 0.0, 0.16)
			tw.parallel().tween_property(_body, "scale", s, 0.16)
		_:
			tw.tween_interval(0.01)


## Bouclier brisé : il vacille jusqu'à ce qu'il se ressaisisse.
func set_stunned(on: bool) -> void:
	stunned = on
	if not on and _body != null:
		_body.rotation.z = 0.0


## Coup reçu : éclair blanc, recul et bascule en arrière (plus marqués si le coup est fort).
func play_hit(strong: bool = false) -> void:
	_flash = 1.0
	_quad.set_instance_shader_parameter("flash", 1.0)
	if fast or down or posing():
		return
	if _hit_tw != null and _hit_tw.is_valid():
		_hit_tw.kill()
	var k := 1.9 if strong else 1.0
	_body.position.x = 0.0
	_body.rotation.z = 0.0
	var tw := create_tween()
	_hit_tw = tw
	tw.tween_property(_body, "position:x", -_dir * 0.18 * k, 0.04)
	tw.parallel().tween_property(_body, "rotation:z", _dir * 0.16 * k, 0.04)
	tw.tween_property(_body, "position:x", _dir * 0.08, 0.07)
	tw.tween_property(_body, "position:x", 0.0, 0.07)
	tw.parallel().tween_property(_body, "rotation:z", 0.0, 0.12)
	_set_pose("hit")
	tw.tween_interval(0.12)
	tw.tween_callback(_set_pose.bind(""))


## Un allié s'effondre sur place ; un ennemi se dissipe.
func play_ko() -> void:
	down = true
	_active = false
	if _move != null and _move.is_valid():
		_move.kill()
	_reset_body()
	_set_pose("ko")
	position = home
	if combatant.side == "party":
		if fast:
			_body.rotation.z = -PI * 0.5
			_body.position = Vector3(-0.4, 0.15, 0.0)
			return
		# chancelle, puis s'effondre
		_flash = 1.0
		_quad.set_instance_shader_parameter("flash", 1.0)
		var tw := create_tween()
		tw.tween_property(_body, "rotation:z", 0.2, 0.1)
		tw.tween_property(_body, "rotation:z", -0.25, 0.14)
		tw.tween_property(_body, "rotation:z", -PI * 0.5, 0.3).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(_body, "position", Vector3(-0.4, 0.15, 0.0), 0.3)
		await tw.finished
	else:
		if fast:
			visible = false
			return
		_flash = 1.0
		_quad.set_instance_shader_parameter("flash", 1.0)
		# sursaut, puis s'aplatit
		var s := _body.scale
		var tw := create_tween()
		tw.tween_property(_body, "scale", Vector3(s.x * 0.85, s.y * 1.18, s.z), 0.09)
		tw.tween_property(_body, "scale", Vector3(s.x * 1.3, s.y * 0.04, s.z), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tw.finished
		visible = false


func play_revive() -> void:
	down = false
	_reset_body()
	visible = true
	_flash = 1.0
	if fast:
		return
	# se relève d'un bond
	var tw := create_tween()
	_hit_tw = tw
	tw.tween_property(_body, "position:y", _hover + 0.5, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(_body, "position:y", _hover, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
