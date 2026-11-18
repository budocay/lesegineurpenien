extends Node3D
## Animations de combat décrites dans data/animations.json.
##
## Une animation = une pose du lanceur + une liste d'étapes (« steps ») datées : sprites
## d'effets lancés, tombés, brandis, éparpillés, plus éclairs d'écran, secousses, sons.
## Ce script ne connaît aucune compétence : il lit les données et les joue. Ajouter une
## compétence avec son animation ne demande donc aucun code (voir FORMAT_DONNEES.md).

const FxPainter = preload("res://src/gfx/fx_painter.gd")

const POSES := ["none", "strike", "charge", "sneak", "stomp", "spin", "cast", "throw", "shoot",
	"sleep", "eat", "guard", "shout"]
const KINDS := ["projectile", "drop", "swing", "burst", "rise", "rain", "cloud", "ring", "light",
	"flash", "shake", "sound"]
const ON := ["targets", "caster", "center"]
const WHERE := ["center", "top", "feet"]
const PIXEL := 16.0 / 24.0   # côté d'un sprite d'effet, en unités monde

var scene: Node3D
var _mesh: QuadMesh
var _layer: CanvasLayer
var _flash: ColorRect
var _rng := RandomNumberGenerator.new()


func setup(p_scene: Node3D) -> void:
	scene = p_scene
	_mesh = QuadMesh.new()
	_mesh.size = Vector2(PIXEL, PIXEL)
	_layer = CanvasLayer.new()
	_layer.layer = 0
	add_child(_layer)
	_flash = ColorRect.new()
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash.color = Color(1, 1, 1, 0)
	_layer.add_child(_flash)


# ------------------------------------------------------------------ données

## Animation réellement jouée pour un identifiant : la sienne si elle existe, sinon celle
## de l'élément (« attaque_feu »...), sinon « defaut ».
func resolve(id: String, element: String = "") -> String:
	if Database.animations.has(id):
		return id
	if element != "" and Database.animations.has("attaque_" + element):
		return "attaque_" + element
	return "defaut"


## Identifiant d'animation d'une compétence ou d'un objet : son champ « anim », sinon son
## propre identifiant.
func anim_of(def_id: String, def: Dictionary) -> String:
	var a := str(def.get("anim", ""))
	return a if a != "" else def_id


func _color(v: Variant, element_color: Color) -> Color:
	var s := str(v)
	if s == "" or s == "<null>":
		return Color.WHITE
	if s == "element":
		return element_color
	return Database.color(s, Color.WHITE)


## Vérifie tout le fichier d'animations et que chaque compétence, objet utilisable,
## attaque de base, élément et état a bien la sienne. Renvoie la liste des problèmes.
func validate() -> Array:
	var errors: Array = []
	for id: String in Database.animations:
		var def := Database.get_animation(id)
		if not POSES.has(str(def.get("pose", "none"))):
			errors.append("animation %s : pose inconnue « %s »" % [id, str(def.get("pose"))])
		if def.has("sound") and not Sfx.has(str(def["sound"])):
			errors.append("animation %s : son inconnu « %s »" % [id, str(def["sound"])])
		var steps: Variant = def.get("steps", [])
		if not (steps is Array) or (steps as Array).is_empty():
			errors.append("animation %s : aucune étape" % id)
			continue
		for s: Variant in steps:
			if not (s is Dictionary):
				errors.append("animation %s : étape mal formée" % id)
				continue
			var kind := str(s.get("fx", ""))
			if not KINDS.has(kind):
				errors.append("animation %s : effet inconnu « %s »" % [id, kind])
			if s.has("sprite") and not FxPainter.has(str(s["sprite"])):
				errors.append("animation %s : sprite inconnu « %s »" % [id, str(s["sprite"])])
			if s.has("sound") and not Sfx.has(str(s["sound"])):
				errors.append("animation %s : son inconnu « %s »" % [id, str(s["sound"])])
			if not ON.has(str(s.get("on", "targets"))):
				errors.append("animation %s : « on » inconnu « %s »" % [id, str(s.get("on"))])
			if not WHERE.has(str(s.get("where", "center"))):
				errors.append("animation %s : « where » inconnu « %s »" % [id, str(s.get("where"))])
			if kind == "sound" and not s.has("sound"):
				errors.append("animation %s : étape « sound » sans son" % id)
	for id: String in Database.skills:
		if not Database.animations.has(anim_of(id, Database.get_skill(id))):
			errors.append("compétence %s : pas d'animation" % id)
	for id: String in Database.items:
		var item := Database.get_item(id)
		if item.has("effects") and not Database.animations.has(anim_of(id, item)):
			errors.append("objet %s : pas d'animation" % id)
	for id: String in Database.characters:
		var ch := Database.get_character(id)
		if ch.has("battle") and not Database.animations.has(str((ch["battle"] as Dictionary).get("attack_anim", ""))):
			errors.append("personnage %s : pas d'animation d'attaque (attack_anim)" % id)
	for id: String in Database.enemies:
		if not Database.animations.has(str(Database.get_enemy(id).get("attack_anim", ""))):
			errors.append("ennemi %s : pas d'animation d'attaque (attack_anim)" % id)
	for id: String in Database.elements:
		var el := Database.get_element(id)
		if not FxPainter.has(str(el.get("fx", ""))):
			errors.append("élément %s : sprite d'impact « fx » absent ou inconnu" % id)
		if not Sfx.has(str(el.get("sound", ""))):
			errors.append("élément %s : son d'impact « sound » absent ou inconnu" % id)
		if not Database.animations.has("attaque_" + id):
			errors.append("élément %s : pas d'animation de repli attaque_%s" % [id, id])
	for id: String in Database.statuses:
		if not FxPainter.has(str(Database.get_status(id).get("fx", ""))):
			errors.append("état %s : sprite « fx » absent ou inconnu" % id)
	if not Database.animations.has("defaut"):
		errors.append("animation « defaut » absente")
	return errors


## Nombre d'effets encore à l'écran (les tests vérifient qu'il retombe à zéro).
func live_count() -> int:
	var n := 0
	for c: Node in get_children():
		if c is MeshInstance3D or c is OmniLight3D:
			n += 1
	return n


# --------------------------------------------------------------------- jouer

## Joue une animation et rend la main au moment de l'impact (les chiffres de dégâts
## s'affichent alors) ; les effets finissent seuls.
func play(id: String, caster: Node3D, targets: Array, element: String = "") -> void:
	var def := Database.get_animation(resolve(id, element))
	if scene == null or scene.fast or def.is_empty() or caster == null:
		return
	var impact := maxf(0.05, float(def.get("impact", 0.4)))
	var el_color := Database.color(Database.get_element(element).get("color", "#ffffff"), Color.WHITE)
	if def.has("sound"):
		Sfx.play(str(def["sound"]), float(def.get("pitch", 1.0)))
	var toward: Vector3 = caster.home
	if not targets.is_empty():
		toward = (targets[0] as Node3D).home
	caster.play_pose(str(def.get("pose", "none")), toward, impact)
	for s: Variant in def.get("steps", []):
		if s is Dictionary:
			_schedule(s, caster, targets, el_color)
	await get_tree().create_timer(impact).timeout


func _schedule(s: Dictionary, caster: Node3D, targets: Array, el_color: Color) -> void:
	var at := float(s.get("at", 0.0))
	var kind := str(s.get("fx", ""))
	var where := str(s.get("where", "center"))
	var origin: Vector3 = caster.anchor("center")
	var points: Array = []
	match str(s.get("on", "targets")):
		"caster":
			points = [caster.anchor(where)]
		"center":
			var sum := Vector3.ZERO
			for t: Node3D in targets:
				sum += t.anchor(where)
			points = [sum / float(maxi(1, targets.size()))] if not targets.is_empty() else [caster.anchor(where)]
		_:
			for t: Node3D in targets:
				points.append(t.anchor(where))
	if kind in ["flash", "shake", "sound"]:
		points = [origin]
	var each := float(s.get("each", 0.0))
	for i in points.size():
		var tw := create_tween()
		tw.tween_interval(maxf(0.01, at + each * i))
		tw.tween_callback(_emit.bind(s, origin, points[i], el_color, i == 0))


func _emit(s: Dictionary, origin: Vector3, point: Vector3, el_color: Color, first: bool) -> void:
	if first and s.has("sound"):
		Sfx.play(str(s["sound"]), float(s.get("pitch", 1.0)) * _rng.randf_range(0.96, 1.04))
	var kind := str(s.get("fx", ""))
	var color := _color(s.get("color", ""), el_color)
	var sprite := str(s.get("sprite", "pix"))
	var size := float(s.get("scale", 1.0))
	var count := int(s.get("count", 1))
	var dur := float(s.get("duration", 0.0))
	var spread := float(s.get("spread", 0.6))
	var add := bool(s.get("add", false))
	var side := -1.0 if point.x < origin.x else 1.0   # sens du coup sur l'axe x
	match kind:
		"shake":
			scene.shake(float(s.get("power", 0.6)))
		"flash":
			screen_flash(color, float(s.get("power", 0.35)), dur if dur > 0.0 else 0.25)
		"light":
			_light(point, color, float(s.get("power", 4.0)), dur if dur > 0.0 else 0.4)
		"projectile":
			var from := origin
			if str(s.get("from", "")) == "sky":
				from = point + Vector3(-side * 2.5, 6.0, 0.0)
			var q := _sprite(sprite, from, size, color, add)
			q.scale.x *= side
			_fly(q, 0.0, point, dur if dur > 0.0 else 0.28, 1.0, 1.0, float(s.get("spin", 0.0)) * side, float(s.get("arc", 0.0)))
		"drop":
			var q := _sprite(sprite, point + Vector3(0.0, float(s.get("height", 5.0)), 0.0), size, color, add)
			q.scale.x *= side
			_fly(q, 0.0, point, dur if dur > 0.0 else 0.2, 1.0, 1.0, float(s.get("spin", 0.0)) * side, 0.0, float(s.get("stay", 0.1)))
		"swing":
			var q := _sprite(sprite, point + Vector3(-side * 0.45, 0.15, 0.0), size, color, add)
			q.scale.x *= side
			var a := float(s.get("angle", 1.9)) * 0.5
			q.rotation.z = a * side
			var d := dur if dur > 0.0 else 0.16
			var tw := create_tween()
			tw.tween_property(q, "rotation:z", -a * side, d).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			tw.parallel().tween_property(q, "position:x", point.x + side * 0.1, d)
			tw.tween_interval(0.08)
			tw.tween_callback(q.queue_free)
		"burst":
			var radius := float(s.get("radius", 0.9))
			var phase := _rng.randf() * TAU
			for k in count:
				var ang := phase + TAU * float(k) / float(count)
				var q := _sprite(sprite, point, size, color, add)
				_fly(q, 0.0, point + Vector3(cos(ang), sin(ang), 0.0) * radius * _rng.randf_range(0.7, 1.1),
						dur if dur > 0.0 else 0.4, 0.4, float(s.get("grow", 1.0)), float(s.get("spin", 0.0)))
		"rise":
			for k in count:
				var p := point + Vector3(_rng.randf_range(-spread, spread) * 0.5, _rng.randf_range(-0.1, 0.1), 0.0)
				var q := _sprite(sprite, p, size, color, add)
				_fly(q, 0.09 * k, p + Vector3(_rng.randf_range(-0.2, 0.2), float(s.get("height", 1.1)), 0.0),
						dur if dur > 0.0 else 0.8, 0.55, float(s.get("grow", 1.0)), float(s.get("spin", 0.0)))
		"rain":
			var h := float(s.get("height", 5.0))
			for k in count:
				var p := point + Vector3(_rng.randf_range(-spread, spread), _rng.randf_range(-0.3, 0.3), 0.0)
				var q := _sprite(sprite, p + Vector3(side * -1.2, h, 0.0), size, color, add)
				q.scale.x *= side
				_fly(q, 0.05 * k, p, dur if dur > 0.0 else 0.22, 1.0, 1.0, float(s.get("spin", 0.0)) * side, 0.0, float(s.get("stay", 0.15)))
		"cloud":
			for k in count:
				var p := point + Vector3(_rng.randf_range(-spread, spread), _rng.randf_range(-0.35, 0.35), 0.0)
				var q := _sprite(sprite, p, size * 0.4, color, add)
				_fly(q, 0.05 * k, p + Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0.1, 0.5), 0.0),
						dur if dur > 0.0 else 0.9, 0.45, 2.5, float(s.get("spin", 0.0)))
		"ring":
			var q := _sprite(str(s.get("sprite", "ring")), point, size * 0.3, color, add)
			_fly(q, 0.0, point, dur if dur > 0.0 else 0.4, 1.0, float(s.get("grow", 9.0)), 0.0)


func _sprite(kind: String, at: Vector3, size: float, color: Color, additive: bool) -> MeshInstance3D:
	var quad := MeshInstance3D.new()
	quad.mesh = _mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = Sprites.fx(kind)
	# Découpe franche et écriture de profondeur, comme les personnages : un sprite
	# translucide serait flouté avec l'arrière-plan par le flou de profondeur. Les effets
	# « add » sont simplement surexposés, ce qui les fait rayonner (halo de l'image).
	var k := 1.4 if additive else 1.0
	mat.albedo_color = Color(color.r * k, color.g * k, color.b * k, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	quad.material_override = mat
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	quad.position = at + Vector3(0.0, 0.0, 0.35)
	quad.scale = Vector3.ONE * size
	add_child(quad)
	return quad


## Fait voyager un sprite d'effet puis le supprime. fade_from : part du trajet à partir de
## laquelle il s'efface (1 = jamais) ; grow : facteur de taille à l'arrivée ; arc : hauteur
## de la cloche ; stay : temps passé à l'arrivée avant de disparaître.
func _fly(q: MeshInstance3D, delay: float, to: Vector3, dur: float, fade_from: float = 1.0,
		grow: float = 1.0, spin: float = 0.0, arc: float = 0.0, stay: float = 0.0) -> void:
	var from := q.position
	var dest := Vector3(to.x, to.y, from.z)
	var tw := create_tween()
	if delay > 0.0:
		q.visible = false
		tw.tween_interval(delay)
		tw.tween_callback(q.show)
	if arc != 0.0:
		tw.tween_method(func(t: float) -> void:
			q.position = from.lerp(dest, t) + Vector3(0.0, sin(t * PI) * arc, 0.0), 0.0, 1.0, dur)
	else:
		tw.tween_property(q, "position", dest, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT if fade_from < 1.0 else Tween.EASE_IN)
	if grow != 1.0:
		tw.parallel().tween_property(q, "scale", q.scale * grow, dur * minf(fade_from, 1.0))
	if spin != 0.0:
		tw.parallel().tween_property(q, "rotation:z", spin * TAU, dur)
	if fade_from < 1.0:
		# pas de fondu (découpe franche) : le sprite rétrécit jusqu'à disparaître
		tw.parallel().tween_property(q, "scale", Vector3.ONE * 0.01, dur * (1.0 - fade_from)).set_delay(dur * fade_from)
	if stay > 0.0:
		tw.tween_interval(stay)
	tw.tween_callback(q.queue_free)


func _light(at: Vector3, color: Color, energy: float, dur: float) -> void:
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 6.0
	light.position = at + Vector3(0.0, 0.3, 0.9)
	add_child(light)
	var tw := create_tween()
	tw.tween_property(light, "light_energy", 0.0, dur)
	tw.tween_callback(light.queue_free)


func screen_flash(color: Color, power: float, dur: float) -> void:
	if scene == null or scene.fast:
		return
	_flash.color = Color(color.r, color.g, color.b, clampf(power, 0.0, 0.8))
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.0, dur)


# ------------------------------------------------- réactions (coups, états, soins)

## Petite gerbe de sprites autour d'un combattant : impact d'un élément, symbole d'un état.
func puff(sprite: String, actor: Node3D, mode: String = "burst", count: int = 4, color: Color = Color.WHITE, size: float = 0.8) -> void:
	if scene == null or scene.fast or actor == null or not FxPainter.has(sprite):
		return
	var s := {"fx": mode, "sprite": sprite, "count": count, "scale": size, "color": "#" + color.to_html(false)}
	var where := "top" if mode == "rise" else "center"
	_emit(s, actor.anchor("center"), actor.anchor(where), color, false)
