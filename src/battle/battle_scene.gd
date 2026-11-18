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
const ArenaDecor = preload("res://src/battle/arena_decor.gd")
const ARENA_GROUND_SHADER = preload("res://src/gfx/shaders/arena_ground.gdshader")

## Zone de jeu : aucun décor (ni arbre, ni brin d'herbe, ni lanterne) n'y est posé. Elle
## couvre tout le sol devant z = STAGE_BACK, sur |x| < STAGE_SIDE : les combattants se
## tiennent sur un sol nu et rien ne coupe une silhouette. Le décor vit au fond et sur
## les côtés extrêmes, hors cadre utile.
const STAGE_BACK := -9.5
const STAGE_SIDE := 12.0

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
# Caméra façon Octopath : basse, de loin (téléobjectif étroit), légère plongée d'environ 14 degrés.
# Les héros mesurent à peu près un sixième de la hauteur de l'image, un gros monstre un tiers.
var _cam_home := Vector3(0.0, 4.7, 13.6)
var _cam_look := Vector3(0.0, 1.3, 0.0)
var _taken: Array[Vector3] = []     # places des combattants : aucun décor haut ne s'y adosse
var _decor: RefCounted             # paroi et lointain (arena_decor.gd)
var _shake := 0.0
var foreground_props: Array[Vector3] = []   # premier plan flou (hors zone de jeu, au bord bas de l'image)
var placed_props: Array[Vector3] = []   # décors posés (x, hauteur, z) : le test vérifie la zone de jeu


func setup(p_encounter: Dictionary, p_ui: Control, p_seed: int = -1) -> void:
	encounter = p_encounter
	ui = p_ui
	engine = Engine_.new()
	engine.setup(encounter, p_seed)
	var arena_id := str(encounter.get("arena", "pre"))
	var arena := Database.get_arena(arena_id)
	_rng.seed = hash(arena_id)
	_taken = _spots(engine.party, 1.0) + _spots(engine.enemies, -1.0)
	_build_arena(arena)
	_build_camera()
	_place(engine.party, 1.0)
	_place(engine.enemies, -1.0)
	_fit_steps()
	fx = BattleFx.new()
	fx.name = "Fx"
	add_child(fx)
	fx.setup(self)
	ui.open(self, engine)


# ---------------------------------------------------------------------- décor

func _build_arena(arena: Dictionary) -> void:
	var stage: Dictionary = arena.get("stage", {})
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(72.0, 44.0)
	ground.mesh = plane
	ground.material_override = _ground_material(str(arena.get("ground", "grass")), plane.size, stage)
	ground.position = Vector3(0.0, 0.0, -6.0)
	add_child(ground)

	# Fond : paroi de roche irrégulière, lointain peint, mares, façades (arena_decor.gd).
	_decor = ArenaDecor.new(hash(str(encounter.get("arena", "pre"))))
	_decor.build(self, arena)

	for p: Variant in arena.get("props", []):
		if p is Dictionary:
			_scatter(p)
	for l: Variant in arena.get("lights", []):
		if l is Dictionary:
			_light(l)
	_foreground(arena.get("foreground", []))
	_stage_light(stage)
	_stage_vignette(float(stage.get("vignette", 0.45)))
	var amb := _stage_ambiance(Database.get_ambiance(str(arena.get("ambiance", "crepuscule"))), arena)
	Atmosphere.build(self, amb, Rect2(-12.0, -11.0, 24.0, 9.0))


## Sol uni à grain fin, nappe de lumière au centre, bords assombris (arena_ground.gdshader).
## Champ « stage » de l'arène : voir docs/FORMAT_DONNEES.md.
func _ground_material(tile: String, size: Vector2, stage: Dictionary) -> ShaderMaterial:
	var img: Image = Sprites.tile_image(tile)
	var avg := Color(0, 0, 0)
	for i in 64:
		avg += img.get_pixel((i * 7) % img.get_width(), (i * 13) % img.get_height())
	avg = avg / 64.0
	var m := ShaderMaterial.new()
	m.shader = ARENA_GROUND_SHADER
	m.set_shader_parameter("tex", Sprites.tile_texture(tile))
	m.set_shader_parameter("uv_scale", size / MeshKit.TEX_UNITS)
	m.set_shader_parameter("base", Color(avg.r, avg.g, avg.b))
	m.set_shader_parameter("flatten", float(stage.get("flatten", 0.15)))
	m.set_shader_parameter("grain", float(stage.get("grain", 0.04)))
	m.set_shader_parameter("variation", float(stage.get("variation", 0.09)))
	m.set_shader_parameter("tint", Database.color(stage.get("tint", "#ffffff"), Color.WHITE))
	m.set_shader_parameter("pool_color", Database.color(stage.get("light", "#ffe9c8"), Color("#ffe9c8")))
	m.set_shader_parameter("pool_boost", float(stage.get("boost", 0.45)))
	m.set_shader_parameter("edge", float(stage.get("edge", 0.45)))
	var patches: Dictionary = stage.get("patches", {})
	if not patches.is_empty():
		m.set_shader_parameter("tex2", Sprites.tile_texture(str(patches.get("tile", "grass"))))
		m.set_shader_parameter("patch_amount", float(patches.get("amount", 0.3)))
		m.set_shader_parameter("patch_tint", Database.color(patches.get("tint", "#ffffff"), Color.WHITE))
	var puddles: Dictionary = stage.get("puddles", {})
	if not puddles.is_empty():
		m.set_shader_parameter("puddle_amount", float(puddles.get("amount", 0.15)))
		m.set_shader_parameter("puddle_color", Database.color(puddles.get("color", "#3d6466"), Color("#3d6466")))
	var fleck: Dictionary = stage.get("fleck", {})
	if not fleck.is_empty():
		m.set_shader_parameter("fleck_density", float(fleck.get("density", 0.04)))
		var cols: Array = fleck.get("colors", ["#f4f0e0", "#f2d24a"])
		m.set_shader_parameter("fleck_a", Database.color(cols[0], Color("#f4f0e0")))
		m.set_shader_parameter("fleck_b", Database.color(cols[cols.size() - 1], Color("#f2d24a")))
		m.set_shader_parameter("tuft_color", Database.color(fleck.get("tuft", "#73b150"), Color("#73b150")))
	m.set_shader_parameter("desat", float(stage.get("desat", 0.0)))
	var r: Array = stage.get("radius", [12.0, 7.5])
	m.set_shader_parameter("pool_radius", Vector2(float(r[0]), float(r[1])))
	var c: Array = stage.get("center", [0.0, -0.5])
	m.set_shader_parameter("pool_center", Vector2(float(c[0]), float(c[1])))
	return m


## Coins de l'image assombris par-dessus le monde, sous l'interface : l'œil va au centre.
func _stage_vignette(strength: float) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 0
	layer.name = "StageVignette"
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://src/gfx/shaders/vignette.gdshader")
	mat.set_shader_parameter("strength", strength)
	rect.material = mat
	layer.add_child(rect)
	add_child(layer)


## Lumière d'appoint, large et douce, au-dessus de la scène : elle détache les combattants
## du sol et du fond. Sans ombre, pour ne rien creuser sur le sol.
func _stage_light(stage: Dictionary) -> void:
	var l := Atmosphere.make_light(Database.color(stage.get("light", "#ffd9a0"), Color("#ffd9a0")),
			float(stage.get("key", 1.6)), 17.0, false)
	l.omni_attenuation = 0.9
	l.light_volumetric_fog_energy = 0.0
	l.position = Vector3(0.0, 6.0, 4.0)
	l.name = "StageLight"
	add_child(l)


## Ambiance de combat : on garde le ton du lieu mais on retire ce qui encombre la scène
## (lucioles et feuilles flottant devant les combattants, rayons obliques) et on allège
## la brume. Le champ « particles » de l'arène remplace la liste de l'ambiance.
func _stage_ambiance(amb: Dictionary, arena: Dictionary) -> Dictionary:
	var out: Dictionary = amb.duplicate(true)
	out.erase("rays")
	out["particles"] = arena.get("particles", [])
	if out.has("volumetric"):
		(out["volumetric"] as Dictionary)["density"] = float((out["volumetric"] as Dictionary).get("density", 0.01)) * 0.55
	return out


## Vrai si ce point du sol est dans la zone de jeu (voir STAGE_BACK).
static func in_stage(x: float, z: float) -> bool:
	return z > STAGE_BACK and absf(x) < STAGE_SIDE


## Hauteur du sol de l'arène en ce point (paroi du fond).
func _step_height(x: float, z: float) -> float:
	return _decor.height_at(x, z) if _decor != null else 0.0


const FLAT_PROPS := ["grass", "flowers", "wheat", "fern", "wilted", "reeds", "mushrooms"]   # trop bas pour cacher qui que ce soit
const FORM_SPAN := 3.8    # largeur maximale (en x) d'une file de combattants
const FORM_X := 3.35       # écart au centre du milieu de la file : le vide entre les deux camps
const CAM_FOV := 28.0     # champ de vision vertical : étroit, comme un téléobjectif
const ENEMY_SPAN := 4.4   # les ennemis (jusqu'à cinq, souvent larges) ont une file plus étalée
const ENEMY_X := 3.5
const HALF_VIEW := 5.7    # demi-largeur visible de l'arène au niveau des combattants
const FORM_DEPTH := 0.85  # profondeur de la file, par rapport à sa largeur (la diagonale se voit)
const FOREGROUND_Z := [4.7, 5.5]   # profondeur du premier plan flou (arènes : champ « foreground »)


## Place des combattants d'un camp, en diagonale : chacun un peu plus bas (plus près de la
## caméra) et plus à l'extérieur que le précédent ; le premier est le plus haut et le plus
## proche du centre. L'écart tient compte de la taille de chacun, pour que personne ne soit caché.
## « scales » : la taille de chaque combattant ; renvoie une position par combattant
## (côté droit ; le camp d'en face prend l'opposé en x, la même profondeur : la file des
## ennemis descend donc vers la gauche, celle des héros vers la droite).
## « spread » élargit les écarts (les monstres sont plus larges que les personnages).
static func formation(scales: Array, spread: float = 1.0, span: float = FORM_SPAN, x0: float = FORM_X) -> Array[Vector3]:
	var n := scales.size()
	var offsets: Array[float] = [0.0]
	var total := 0.0
	for i in range(1, n):
		total += (0.5 + 0.45 * (float(scales[i - 1]) + float(scales[i]))) * spread
		offsets.append(total)
	var k := minf(1.0, span / total) if total > 0.0 else 1.0
	var out: Array[Vector3] = []
	for i in n:
		var along := (offsets[i] - total * 0.5) * k
		# l'écart en x fait l'écart à l'écran ; la profondeur, plus faible, ne sert qu'à
		# étager les rangs : une diagonale à 45 degrés ramène les voisins l'un sur l'autre
		out.append(Vector3(x0 + along + 0.55 * (float(scales[i]) - 1.0), 0.0, along * FORM_DEPTH))
	return out


## Premier plan flou : rochers, herbes, souches posés tout en bas de l'image, entre la
## caméra et la zone de jeu. Ils encadrent la scène sans rien cacher (champ « foreground »
## de l'arène : [{"prop", "count", "scale", "x": [min, max]}]).
func _foreground(list: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("fg" + str(encounter.get("arena", "pre")))
	for entry: Variant in list:
		if not (entry is Dictionary):
			continue
		var kind := str(entry.get("prop", "rock"))
		var def: Dictionary = MapBuilder.PROPS.get(kind, {})
		var variants := int(def.get("variants", 1))
		var xr: Array = entry.get("x", [-10.0, 10.0])
		var count := int(entry.get("count", 3))
		for i in count:
			var s := float(entry.get("scale", 1.5)) * rng.randf_range(0.8, 1.25)
			var node := Sprites.make_sprite(Sprites.prop(kind, rng.randi() % variants), float(def.get("sway", 0.0)) * 0.5, float(def.get("glow", 0.0)))
			var flip := rng.randf() < 0.5
			node.scale = Vector3(-s if flip else s, s, s)
			var t := (float(i) + rng.randf_range(0.15, 0.85)) / float(count)
			var z: float = rng.randf_range(float(FOREGROUND_Z[0]), float(FOREGROUND_Z[1]))
			node.position = Vector3(lerpf(float(xr[0]), float(xr[1]), t), 0.0, z)
			foreground_props.append(node.position)
			add_child(node)
			(node.get_child(0) as MeshInstance3D).set_instance_shader_parameter("sway_phase", rng.randf() * TAU)


func _zone_point(zone: String) -> Vector2:
	match zone:
		"back":
			return Vector2(_rng.randf_range(-15.0, 15.0), _rng.randf_range(-15.5, -3.6))
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
	var spots: Array = []
	if p.has("at"):
		for sp: Variant in p["at"]:
			if not in_stage(float(sp[0]), float(sp[1])):   # jamais de décor dans la zone de jeu
				spots.append(sp)
		count = spots.size()
		min_dist = 0.0
	while placed.size() < count and tries < count * 30:
		tries += 1
		var pt := _zone_point(str(p.get("zone", "mid")))
		if p.has("area"):
			var ar: Array = p["area"]
			pt = Vector2(_rng.randf_range(float(ar[0]), float(ar[2])), _rng.randf_range(float(ar[1]), float(ar[3])))
		elif p.has("at"):
			var sp: Array = spots[placed.size() % spots.size()]
			pt = Vector2(float(sp[0]), float(sp[1]))
		var ok := not in_stage(pt.x, pt.y)
		for q in placed:
			if q.distance_to(pt) < min_dist:
				ok = false
				break
		if not ok:
			continue
		placed.append(pt)
		var node := Sprites.make_sprite(Sprites.prop(kind, _rng.randi() % variants), float(def.get("sway", 0.0)), float(def.get("glow", 0.0)))
		var s := float(p.get("scale", 1.0)) * (1.0 + _rng.randf_range(-0.15, 0.15))
		var flip := bool(def.get("flip", false)) and _rng.randf() < 0.5
		node.scale = Vector3(-s if flip else s, s, s)
		node.position = Vector3(pt.x, _step_height(pt.x, pt.y), pt.y)
		placed_props.append(node.position)
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
	if bool(l.get("lantern", false)) and not in_stage(pos.x, pos.z - 0.25):
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
	camera.fov = CAM_FOV
	camera.near = 0.5
	camera.far = 200.0
	add_child(camera)
	camera.look_at_from_position(_cam_home, _cam_look, Vector3.UP)
	var dist := _cam_home.distance_to(_cam_look)
	var attr := CameraAttributesPractical.new()
	attr.dof_blur_far_enabled = true
	attr.dof_blur_far_distance = dist + 2.6
	attr.dof_blur_far_transition = 11.0
	attr.dof_blur_near_enabled = true
	attr.dof_blur_near_distance = dist - 2.5
	attr.dof_blur_near_transition = 2.5
	attr.dof_blur_amount = 0.095
	camera.attributes = attr
	Settings.apply_camera(attr)
	camera.make_current()


## Places (monde) des combattants d'un camp.
func _spots(list: Array, side: float) -> Array[Vector3]:
	var scales: Array = []
	for c: RefCounted in list:
		scales.append(float((c.sprite as Dictionary).get("scale", 1.0)))
	var out: Array[Vector3] = []
	var i := 0
	for sp: Vector3 in (formation(scales, 1.3, ENEMY_SPAN, ENEMY_X) if side < 0.0 else formation(scales)):
		# un grand monstre ne doit pas déborder de l'écran : on ramène son centre vers le milieu
		var limit := maxf(1.5, tan(deg_to_rad(CAM_FOV * 0.5)) * (16.0 / 9.0) * (_cam_home.z - sp.z) - 0.15 - _half_width(list[i]))
		out.append(Vector3(clampf(sp.x * side, -limit, limit), 0.0, sp.z))
		i += 1
	return out


## Demi-largeur (en x) occupée à l'écran par un combattant.
func _half_width(c: RefCounted) -> float:
	var sp: Dictionary = c.sprite
	var s := float(sp.get("scale", 1.0))
	if sp.has("monster"):
		var sheet := Sprites.monster(str(sp["monster"]))
		return float(sheet["frame_w"]) / float(sheet["ppu"]) * s * 0.45
	return 0.4 * s


func _place(list: Array, side: float) -> void:
	var spots := _spots(list, side)
	for i in list.size():
		var c: RefCounted = list[i]
		var actor := Actor.new()
		actor.name = "Actor_" + str(c.key).replace("#", "_")
		add_child(actor)
		actor.setup(c, spots[i])
		actors[c.key] = actor


func actor_of(c: RefCounted) -> Node3D:
	return actors.get(c.key)


## Rectangle (pixels) que le sprite d'un combattant couvre à l'écran. Avec « stepped », à la
## place qu'il prend quand il joue (un pas en avant) ; sinon à sa place de départ.
func screen_rect(c: RefCounted, stepped: bool = false) -> Rect2:
	var a: Node3D = actors.get(c.key)
	if a == null or camera == null:
		return Rect2()
	var at: Vector3 = a.stepped_home() if stepped else a.home
	var hw: float = a.half_width()
	var tall: float = a.height
	if a.down:   # un combattant à terre est couché : plus large que haut
		hw *= 1.5
		tall *= 0.4
	var bottom := camera.unproject_position(at + Vector3(-hw, a._hover, 0.0))
	var top := camera.unproject_position(at + Vector3(hw, tall + a._hover, 0.0))
	return Rect2(bottom.x, top.y, top.x - bottom.x, bottom.y - top.y).abs()


## Longueur du pas en avant d'un combattant : le pas normal, réduit au besoin pour qu'il ne
## recouvre aucun voisin (calcul sur les rectangles d'écran, pas de valeur au cas par cas).
## Refait au début de chaque tour : un voisin tombé ne se trouve pas au même endroit qu'un voisin debout.
func _fit_step(c: RefCounted) -> void:
	var a: Node3D = actors[c.key]
	var best := 0.7
	var best_area := INF
	var s := 0.7
	while s >= -0.001:
		a.step = s
		var r := screen_rect(c, true).grow_individual(-6.0, 0.0, -6.0, 0.0)
		var area := 0.0
		for o: RefCounted in engine.all():
			if o != c and (o.alive() or o.side == "party"):
				area += r.intersection(screen_rect(o).grow_individual(-6.0, 0.0, -6.0, 0.0)).get_area()
		if area < best_area - 1.0:
			best_area = area
			best = s
		if area <= 0.0:
			break
		s -= 0.05
	a.step = best


func _fit_steps() -> void:
	for c: RefCounted in engine.all():
		_fit_step(c)


## Position à l'écran d'un combattant ("top", "center" ou "feet").
func screen_point(c: RefCounted, where: String = "center") -> Vector2:
	var a: Node3D = actors.get(c.key)
	if a == null or camera == null:
		return Vector2.ZERO
	var p := camera.unproject_position(a.anchor(where))
	if where == "top":
		p.y = maxf(p.y, 132.0)   # jamais par-dessus la file des tours
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
		ui.set_timeline([actor] + engine.preview(10, actor))
		ui.set_active(actor)
		await _play(engine.start_turn(actor))
		if engine.result == "" and engine.can_act:
			_fit_step(actor)
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
			Music.play(Music.default("victory"), 0.3)
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
					ui.popup(screen_point(target, "top"), "Faiblesse !", Color("#ffd27a"), 22, 52.0)
				elif bool(e.get("crit", false)):
					ui.popup(screen_point(target, "top"), "Critique !", Color("#ffb060"), 22, 52.0)
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
					ui.popup(screen_point(target, "top"), "+%d PM" % int(e["amount"]), Color("#8ab8ff"), 24, 28.0)
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
				ui.popup(screen_point(target, "top"), "Se réveille", Color("#d8c8ff"), 22, 30.0)
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
				ui.popup(screen_point(target, "top"), "Esquive !" if e.get("dodge", false) else "Raté !", Color("#b9b2a6"), 26)
				await _wait(0.4)
			"counter":
				var riposter: RefCounted = e["actor"]
				ui.announce("%s rend le coup !" % str(riposter.name), 1.2)
				await _wait(0.35)
			"steal":
				if int(e.get("amount", 0)) > 0:
					Sfx.play("coin")
					ui.popup(screen_point(target, "top"), "+%d écus" % int(e["amount"]), Color("#ffd27a"), 24, 30.0)
				else:
					ui.popup(screen_point(target, "top"), "Poches vides", Color("#b9b2a6"), 22, 30.0)
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
