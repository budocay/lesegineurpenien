extends Node3D
## Scène de combat HD-2D : une petite arène en 3D (sol, décor flou au premier et à
## l'arrière-plan, lanternes), les combattants en pixel art, et le déroulé du combat.
## Les règles sont dans battle_engine.gd ; ici on met seulement en scène ses événements.

signal finished(outcome: String)   # "victory", "fled", "retry" ou "title"

const Engine_ = preload("res://src/battle/battle_engine.gd")
const Actor = preload("res://src/battle/battle_actor.gd")
const BattleFx = preload("res://src/battle/battle_fx.gd")
const Atmosphere = preload("res://src/world/atmosphere.gd")
const MapBuilder = preload("res://src/world/map_builder.gd")
const MeshKit = preload("res://src/gfx/mesh_kit.gd")

var engine: RefCounted
var ui: Control
var camera: Camera3D
var actors: Dictionary = {}   # clé du combattant -> Actor
var encounter: Dictionary = {}
var auto := false             # l'équipe joue toute seule (tests, captures)
var fast := false             # aucune attente ni animation (tests)
var outcome := ""
var fx: Node3D                # animations de combat (data/animations.json)

var _rng := RandomNumberGenerator.new()
var _cam_home := Vector3(0.0, 3.3, 12.4)
var _cam_look := Vector3(0.0, 0.8, 0.0)
var _shake := 0.0


func setup(p_encounter: Dictionary, p_ui: Control, p_seed: int = -1) -> void:
	encounter = p_encounter
	ui = p_ui
	engine = Engine_.new()
	engine.setup(encounter, p_seed)
	var arena_id := str(encounter.get("arena", "pre"))
	var arena := Database.get_arena(arena_id)
	_rng.seed = hash(arena_id)
	_build_arena(arena)
	_build_camera()
	_place(engine.party, 1.0)
	_place(engine.enemies, -1.0)
	fx = BattleFx.new()
	fx.name = "Fx"
	add_child(fx)
	fx.setup(self)
	ui.open(self, engine)


# ---------------------------------------------------------------------- décor

func _build_arena(arena: Dictionary) -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(72.0, 44.0)
	ground.mesh = plane
	var mat := MeshKit.pixel_material(Sprites.tile_texture(str(arena.get("ground", "grass"))))
	mat.uv1_scale = Vector3(plane.size.x / MeshKit.TEX_UNITS, plane.size.y / MeshKit.TEX_UNITS, 1.0)
	ground.material_override = mat
	ground.position = Vector3(0.0, 0.0, -6.0)
	add_child(ground)

	for p: Variant in arena.get("props", []):
		if p is Dictionary:
			_scatter(p)
	for l: Variant in arena.get("lights", []):
		if l is Dictionary:
			_light(l)
	var amb := Database.get_ambiance(str(arena.get("ambiance", "crepuscule")))
	Atmosphere.build(self, amb)


func _zone_point(zone: String) -> Vector2:
	match zone:
		"back":
			return Vector2(_rng.randf_range(-14.0, 14.0), _rng.randf_range(-12.0, -3.6))
		"front":
			var x := _rng.randf_range(5.4, 10.5) * (1.0 if _rng.randf() < 0.5 else -1.0)
			return Vector2(x, _rng.randf_range(3.6, 6.2))
	return Vector2(_rng.randf_range(-9.5, 9.5), _rng.randf_range(-3.2, 3.2))


func _scatter(p: Dictionary) -> void:
	var kind := str(p.get("prop", "grass"))
	var def: Dictionary = MapBuilder.PROPS.get(kind, {})
	var variants := int(def.get("variants", 1))
	var min_dist := float(p.get("min_dist", 1.0))
	var placed: Array[Vector2] = []
	var tries := 0
	var count := int(p.get("count", 4))
	while placed.size() < count and tries < count * 30:
		tries += 1
		var pt := _zone_point(str(p.get("zone", "mid")))
		var ok := true
		for q in placed:
			if q.distance_to(pt) < min_dist:
				ok = false
				break
		if not ok:
			continue
		placed.append(pt)
		var node := Sprites.make_sprite(Sprites.prop(kind, _rng.randi() % variants), float(def.get("sway", 0.0)), 0.0)
		var s := float(p.get("scale", 1.0)) * (1.0 + _rng.randf_range(-0.15, 0.15))
		var flip := bool(def.get("flip", false)) and _rng.randf() < 0.5
		node.scale = Vector3(-s if flip else s, s, s)
		node.position = Vector3(pt.x, 0.0, pt.y)
		add_child(node)
		(node.get_child(0) as MeshInstance3D).set_instance_shader_parameter("sway_phase", _rng.randf() * TAU)


func _light(l: Dictionary) -> void:
	var a: Array = l.get("pos", [0, 2, 0])
	var pos := Vector3(float(a[0]), float(a[1]), float(a[2]))
	var color := Database.color(l.get("color", "#ffb45e"), Color("#ffb45e"))
	var light := Atmosphere.make_light(color, float(l.get("energy", 2.0)), float(l.get("range", 8.0)),
			bool(l.get("shadow", false)), float(l.get("flicker", 0.12 if bool(l.get("lantern", false)) else 0.0)))
	light.position = pos
	add_child(light)
	if bool(l.get("lantern", false)):
		var post := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.14, pos.y - 0.25, 0.14)
		post.mesh = box
		post.material_override = MeshKit.flat_material(Color("#3a2a22"))
		post.position = Vector3(pos.x, box.size.y * 0.5, pos.z - 0.25)
		add_child(post)
		var lamp := MeshInstance3D.new()
		var lamp_box := BoxMesh.new()
		lamp_box.size = Vector3(0.3, 0.36, 0.3)
		lamp.mesh = lamp_box
		lamp.material_override = MeshKit.flat_material(color, 3.0)
		lamp.position = Vector3(pos.x, pos.y - 0.2, pos.z - 0.25)
		lamp.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(lamp)


func _build_camera() -> void:
	camera = Camera3D.new()
	camera.fov = 30.0
	camera.near = 0.5
	camera.far = 200.0
	add_child(camera)
	camera.look_at_from_position(_cam_home, _cam_look, Vector3.UP)
	var dist := _cam_home.distance_to(_cam_look)
	var attr := CameraAttributesPractical.new()
	attr.dof_blur_far_enabled = true
	attr.dof_blur_far_distance = dist + 2.6
	attr.dof_blur_far_transition = 7.0
	attr.dof_blur_near_enabled = true
	attr.dof_blur_near_distance = dist - 3.0
	attr.dof_blur_near_transition = 3.0
	attr.dof_blur_amount = 0.11
	camera.attributes = attr
	camera.make_current()


func _place(list: Array, side: float) -> void:
	var n := list.size()
	# en diagonale : celui du premier plan est le plus près du centre, ce qui évite que
	# les sprites se cachent les uns les autres et dégage le coin du menu
	var step := 0.0 if n <= 1 else minf(1.6, 3.0 / float(n - 1))
	for i in n:
		var c: RefCounted = list[i]
		var scale_k := float((c.sprite as Dictionary).get("scale", 1.0))
		var z := (float(i) - float(n - 1) * 0.5) * step
		var x := 3.6 - 0.7 * z + 0.55 * (scale_k - 1.0)
		var actor := Actor.new()
		actor.name = "Actor_" + str(c.key).replace("#", "_")
		add_child(actor)
		actor.setup(c, Vector3(x * side, 0.0, z))
		actors[c.key] = actor


func actor_of(c: RefCounted) -> Node3D:
	return actors.get(c.key)


## Position à l'écran d'un combattant ("top", "center" ou "feet").
func screen_point(c: RefCounted, where: String = "center") -> Vector2:
	var a: Node3D = actors.get(c.key)
	if a == null or camera == null:
		return Vector2.ZERO
	var p := camera.unproject_position(a.anchor(where))
	if where == "top":
		p.y = maxf(p.y, 150.0)   # jamais par-dessus la file des tours
	return p


## Secousse de caméra (0 à 1).
func shake(power: float) -> void:
	if not fast:
		_shake = maxf(_shake, power)


func _process(delta: float) -> void:
	if camera == null:
		return
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 3.0)
		var k := _shake * _shake * 0.22
		camera.position = _cam_home + Vector3(randf_range(-k, k), randf_range(-k, k), 0.0)
	else:
		camera.position = _cam_home


# -------------------------------------------------------------------- déroulé

func _wait(seconds: float) -> void:
	if fast:
		await get_tree().process_frame
	else:
		await get_tree().create_timer(seconds).timeout


func run() -> void:
	for a: Node3D in actors.values():
		a.fast = fast
	await get_tree().process_frame
	ui.refresh()
	var intro := str(encounter.get("intro", ""))
	if intro == "":
		var names: Array = []
		for e: RefCounted in engine.enemies:
			names.append(e.name)
		intro = "%s vous barre la route !" % names[0] if names.size() == 1 else "Des créatures ramollies vous barrent la route !"
	ui.announce(intro, 2.2)
	if not fast:
		# léger travelling avant en ouverture
		var from := _cam_home + Vector3(0.0, 0.6, 2.4)
		var target := _cam_home
		_cam_home = from
		var tw := create_tween()
		tw.tween_property(self, "_cam_home", target, 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await _wait(1.3)
	if float(engine.softness) > 0.0:
		ui.announce("Ramollissement : les coups physiques portent %d %% moins fort." % int(round(float(engine.softness) * 100.0)), 2.4)
		await _wait(2.0)

	var guard := 0
	while engine.result == "" and guard < 2000:
		guard += 1
		var actor: RefCounted = engine.next_actor()
		if actor == null:
			break
		var a: Node3D = actors[actor.key]
		for o: Node3D in actors.values():
			o.fast = fast
		ui.set_timeline([actor] + engine.preview(7, actor))
		ui.set_active(actor)
		await _play(engine.start_turn(actor))
		if engine.result == "" and engine.can_act:
			a.set_active(true)
			var action: Dictionary
			if actor.side == "enemy":
				await _wait(0.45)
				action = engine.ai_action(actor)
			elif auto:
				await _wait(0.3)
				action = engine.auto_action(actor)
			else:
				var hints: Array = encounter.get("hints", [])
				if engine.party_turns - 1 < hints.size():
					ui.show_hint(str(hints[engine.party_turns - 1]))
				action = await ui.ask_action(actor)
				ui.show_hint("")
			await _play(engine.perform(actor, action))
			a.set_active(false)
		if engine.result == "":
			await _play(engine.end_turn(actor))
		ui.refresh()
	ui.set_active(null)
	ui.show_hint("")
	await _finish()


func _finish() -> void:
	match str(engine.result):
		"victory":
			await _wait(0.5)
			Sfx.play("victory")
			var rewards: Dictionary = engine.commit()
			if fast:
				await _wait(0.2)
			else:
				await ui.show_victory(rewards, engine.guest)
			outcome = "victory"
		"fled":
			engine.commit()
			await _wait(0.6)
			outcome = "fled"
		_:
			await _wait(0.8)
			if fast:
				outcome = "title"
			else:
				outcome = await ui.show_defeat()
	finished.emit(outcome)


# ---------------------------------------------------- mise en scène des événements

func _element_color(element: String) -> Color:
	return Database.color(Database.get_element(element).get("color", "#ffffff"), Color.WHITE)


func _play(events: Array) -> void:
	for ev: Variant in events:
		if not (ev is Dictionary):
			continue
		var e: Dictionary = ev
		var target: RefCounted = e.get("target")
		var ta: Node3D = actors.get(target.key) if target != null else null
		match str(e.get("type", "")):
			"cast":
				var caster: RefCounted = e["actor"]
				var ca: Node3D = actors[caster.key]
				ui.announce(str(e.get("name", "")), 1.4)
				var aimed: Array = []
				for t: RefCounted in e.get("targets", []):
					aimed.append(actors[t.key])
				# l'animation vient des données ; elle rend la main au moment de l'impact
				await fx.play(str(e.get("anim", "")), ca, aimed, str(e.get("element", "")))
				if str(e.get("kind", "")) != "attack":
					await _wait(0.05)
			"fizzle":
				ui.popup(screen_point(e["actor"], "top"), "Dans le vide...", Color("#b9b2a6"))
				await _wait(0.5)
			"damage":
				var weak := bool(e.get("weak", false))
				var color := Color.WHITE
				if e.has("status"):
					color = Database.color(Database.get_status(str(e["status"])).get("color", "#a6d85a"), Color.WHITE)
				elif target.side == "party":
					color = Color("#ff9a8a")
				var strong := weak or bool(e.get("crit", false))
				ta.play_hit(strong)
				if e.has("element"):
					var el := Database.get_element(str(e["element"]))
					_burst(ta.anchor("center"), _element_color(str(e["element"])), 1.5 if weak else 1.0)
					fx.puff(str(el.get("fx", "")), ta, "burst", 6 if strong else 3)
					Sfx.play(str(el.get("sound", "hit")), randf_range(0.92, 1.08))
				elif e.has("status"):
					fx.puff(str(Database.get_status(str(e["status"])).get("fx", "")), ta, "rise", 2)
				Sfx.play("weak" if weak else "hit", randf_range(0.92, 1.08))
				shake(0.7 if strong else 0.35)
				if strong:
					fx.screen_flash(Color.WHITE, 0.18, 0.15)
				ui.popup(screen_point(target, "top"), str(int(e.get("amount", 0))), color, 40 if (weak or bool(e.get("crit", false))) else 32)
				if weak:
					ui.popup(screen_point(target, "top") + Vector2(0, -34), "Faiblesse !", Color("#ffd27a"), 22)
				elif bool(e.get("crit", false)):
					ui.popup(screen_point(target, "top") + Vector2(0, -34), "Critique !", Color("#ffb060"), 22)
				ui.refresh()
				await _wait(0.42)
			"break":
				Sfx.play("break")
				shake(1.0)
				_burst(ta.anchor("center"), Color("#ff7a6a"), 2.2)
				fx.puff("bang", ta, "burst", 5)
				fx.puff("ring", ta, "ring", 1, Color("#ff7a6a"), 1.0)
				fx.screen_flash(Color("#ff7a6a"), 0.3, 0.3)
				ui.popup(screen_point(target, "center"), "ÉBRANLÉ !", Color("#ff8a6a"), 38)
				ui.refresh()
				await _wait(0.7)
			"recover":
				ui.popup(screen_point(target, "top"), "Se ressaisit", Color("#cfd8ea"), 22)
				ui.refresh()
				await _wait(0.4)
			"heal":
				Sfx.play("heal")
				_burst(ta.anchor("center"), Color("#8af0a0"), 1.2)
				fx.puff("plus", ta, "rise", 3)
				ui.popup(screen_point(target, "top"), "+%d" % int(e.get("amount", 0)), Color("#8af0a0"), 32)
				ui.refresh()
				await _wait(0.42)
			"mana":
				if int(e.get("amount", 0)) > 0:
					fx.puff("drop", ta, "rise", 3)
					ui.popup(screen_point(target, "top") + Vector2(0, -28), "+%d PM" % int(e["amount"]), Color("#8ab8ff"), 24)
					ui.refresh()
					await _wait(0.3)
			"status":
				var st := Database.get_status(str(e.get("id", "")))
				if bool(e.get("applied", false)):
					Sfx.play("status")
					fx.puff(str(st.get("fx", "")), ta, "rise", 2, Color.WHITE, 1.0)
					ui.popup(screen_point(target, "top"), str(st.get("name", "")), Database.color(st.get("color", "#ffffff"), Color.WHITE), 26)
				elif bool(e.get("immune", false)):
					ui.popup(screen_point(target, "top"), "Insensible", Color("#b9b2a6"), 24)
				else:
					ui.popup(screen_point(target, "top"), "Résiste", Color("#b9b2a6"), 22)
				ui.refresh()
				await _wait(0.45)
			"cure":
				Sfx.play("heal")
				fx.puff("bubble", ta, "rise", 3, Color("#bfe8ff"))
				ui.popup(screen_point(target, "top"), "Guéri" if not (e.get("ids", []) as Array).is_empty() else "Sans effet", Color("#bfe8ff"), 24)
				ui.refresh()
				await _wait(0.4)
			"wake":
				ui.popup(screen_point(target, "top") + Vector2(0, -30), "Se réveille", Color("#d8c8ff"), 22)
				ui.refresh()
			"status_end":
				ui.refresh()
			"skip":
				ui.announce("%s %s." % [target.name, str(e.get("status", "passe son tour"))], 1.3)
				fx.puff("dizzy", ta, "rise", 1)
				ui.popup(screen_point(target, "top"), "...", Color("#d8c8ff"), 28)
				await _wait(0.9)
			"defend":
				ui.announce("%s se met en garde." % target.name, 1.2)
				Sfx.play("guard")
				ta.play_pose("guard", ta.home, 0.3)
				fx.puff("shield", ta, "rise", 1, Color.WHITE, 1.2)
				ui.popup(screen_point(target, "top"), "Défense", Color("#8ab4e8"), 26)
				ui.refresh()
				await _wait(0.5)
			"ko":
				Sfx.play("ko")
				if target.side == "party":
					fx.puff("dizzy", ta, "rise", 2)
				else:
					fx.puff("dust", ta, "burst", 5)
					Sfx.play("poof")
				ui.refresh()
				await ta.play_ko()
				await _wait(0.25)
			"revive":
				Sfx.play("heal")
				ta.play_revive()
				fx.puff("feather", ta, "rise", 3)
				ui.popup(screen_point(target, "top"), "Debout !", Color("#8af0a0"), 28)
				ui.refresh()
				await _wait(0.5)
			"miss":
				Sfx.play("swoosh", 1.3)
				fx.puff("dust", ta, "burst", 3)
				ui.popup(screen_point(target, "top"), "Raté !", Color("#b9b2a6"), 26)
				await _wait(0.4)
			"counter":
				var riposter: RefCounted = e["actor"]
				ui.announce("%s rend le coup !" % str(riposter.name), 1.2)
				await _wait(0.35)
			"steal":
				if int(e.get("amount", 0)) > 0:
					Sfx.play("coin")
					ui.popup(screen_point(target, "top") + Vector2(0, -30), "+%d écus" % int(e["amount"]), Color("#ffd27a"), 24)
				else:
					ui.popup(screen_point(target, "top") + Vector2(0, -30), "Poches vides", Color("#b9b2a6"), 22)
				await _wait(0.4)
			"flee":
				if bool(e.get("ok", false)):
					ui.announce("L'équipe prend la fuite. Dignement.", 1.6)
				else:
					ui.announce("Impossible de fuir !", 1.3)
				await _wait(0.8)


## Éclat lumineux coloré à l'endroit d'un coup ou d'un sort.
func _burst(at: Vector3, color: Color, size: float) -> void:
	if fast:
		return
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(1.0, 1.0)
	quad.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = Sprites.prop("dot")
	mat.albedo_color = Color(color.r * 2.4, color.g * 2.4, color.b * 2.4, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	quad.material_override = mat
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	quad.position = at + Vector3(0.0, 0.0, 0.3)
	quad.scale = Vector3.ONE * 0.4 * size
	add_child(quad)
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = 5.0 * size
	light.omni_range = 5.0
	light.position = at + Vector3(0.0, 0.3, 0.8)
	add_child(light)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(quad, "scale", Vector3.ONE * 2.4 * size, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(mat, "albedo_color:a", 0.0, 0.32)
	tw.tween_property(light, "light_energy", 0.0, 0.36)
	tw.chain().tween_callback(func() -> void:
		quad.queue_free()
		light.queue_free())
