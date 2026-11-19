extends Node3D
## Une carte en cours de jeu : décor, joueur, PNJ, caméra HD-2D, collisions, interactions.
## Le monde ne connaît ni l'interface ni les dialogues : il émet des signaux, main.gd orchestre.

signal warp_requested(map_id: String, spawn_id: String)
signal interact_requested(target: Dictionary)
signal trigger_fired(dialogue_id: String)
signal encounter_requested(table_id: String)

const MapBuilder = preload("res://src/world/map_builder.gd")
const Player = preload("res://src/world/player.gd")

var map_id: String = ""
var map: Dictionary = {}

# Données de collision remplies par MapBuilder.
var grid_w := 0
var grid_h := 0
var blocked := PackedByteArray()
var circles: Array[Vector3] = []   # (x, z, rayon)
var rects: Array[Rect2] = []
var warps: Array = []
var triggers: Array = []
var interactables: Array = []
var npcs: Array = []
var followers: Array = []
var occluders: Array = []   # bâtiments qui s'estompent quand ils passent au premier plan
var encounter_zones: Array = []   # {rect, table} : zones de rencontres aléatoires
var flag_deps: Dictionary = {}    # drapeaux dont dépend le décor -> valeur lors de la construction

# Relief jouable (rempli par MapBuilder._build_relief ; vide sur une carte sans relief).
var has_relief := false
var cell_h := PackedFloat32Array()      # hauteur du sol de chaque case plate
var stair_idx := PackedInt32Array()     # case de rampe : indice dans `stairs`, sinon -1
var stairs: Array = []                  # {rect: Rect2, dir, from, to}
var edge_block := PackedByteArray()     # bits 1 nord, 2 est, 4 sud, 8 ouest : bord à dénivelé, infranchissable

var player: Node3D = null
var camera: Camera3D = null
var focus: Dictionary = {}
var input_enabled := false
var attract := false

var cam_distance := 24.0
# rapports de mise au point (voir _focus_on_player) : le héros reste toujours dans la zone nette
var _dof_near_k := 0.87
var _dof_far_k := 1.15
var cam_pitch := 32.0
var _cam_bounds := Rect2()
var _cam_target := Vector3.ZERO
var _warp_lock := true
var _inside: Dictionary = {}
var _cooldown := 0.0
var _time := 0.0
var _enc_left := -1.0
var _last_xz := Vector2.ZERO


## Vrai si un drapeau dont dépend le décor a changé (un objet doit apparaître ou disparaître).
## Rapproche la caméra de toutes les cartes : les personnages occupent plus de place à
## l'écran, comme dans les jeux HD-2D (1.0 = distance écrite dans la carte).
const ZOOM := 0.87


func needs_refresh() -> bool:
	for flag: String in flag_deps:
		if GameState.has_flag(flag) != bool(flag_deps[flag]):
			return true
	return false


func setup(p_map_id: String, spawn_id: String = "", pos: Array = [], facing: String = "", p_attract: bool = false) -> void:
	map_id = p_map_id
	map = Database.get_map(map_id)
	attract = p_attract
	var builder := MapBuilder.new()
	builder.build(self, map)
	_setup_camera()
	if not attract:
		player = Player.new()
		player.name = "Player"
		add_child(player)
		player.setup(self, GameState.leader())
		var spawn := spawn_info(spawn_id)
		var start: Vector3 = spawn["pos"]
		var face: String = spawn["facing"]
		if pos.size() == 2:
			start = Vector3(float(pos[0]), 0.0, float(pos[1]))
		if facing != "":
			face = facing
		if not is_free(Vector2(start.x, start.z), Player.RADIUS, player):
			start = nearest_free(start)
		start.y = ground_y(start.x, start.z)
		player.position = start
		player.set_facing(face)
	var lantern: Variant = Database.get_ambiance(str(map.get("ambiance", ""))).get("lantern")
	if lantern is Dictionary:
		for n: Node3D in npcs:
			n.sprite.add_lantern(lantern, false)
		if player != null:
			player.sprite.add_lantern(lantern, true)
	_cam_target = _desired_target()
	_apply_camera()


func spawn_info(spawn_id: String) -> Dictionary:
	var spawns: Dictionary = map.get("spawns", {})
	var sp: Dictionary = {}
	if spawns.has(spawn_id):
		sp = spawns[spawn_id]
	elif not spawns.is_empty():
		sp = spawns[spawns.keys()[0]]
	var p: Array = sp.get("pos", [grid_w / 2.0, grid_h / 2.0])
	return {"pos": Vector3(float(p[0]) + 0.5, 0.0, float(p[1]) + 0.5), "facing": str(sp.get("facing", "down"))}


func set_input(enabled: bool) -> void:
	input_enabled = enabled
	if player != null:
		player.control = enabled
	if enabled:
		_cooldown = 0.25
	else:
		focus = {}


func player_xz() -> Array:
	if player == null:
		return []
	return [player.position.x, player.position.z]


# ---------------------------------------------------------------- relief

## Hauteur d'une rampe au point (x, z) : de `from` au bout bas à `to` au bout haut.
func stair_height(s: Dictionary, x: float, z: float) -> float:
	var r: Rect2 = s["rect"]
	var t := 0.0
	match str(s["dir"]):
		"up": t = (r.end.y - z) / r.size.y
		"down": t = (z - r.position.y) / r.size.y
		"left": t = (r.end.x - x) / r.size.x
		"right": t = (x - r.position.x) / r.size.x
	return lerpf(float(s["from"]), float(s["to"]), clampf(t, 0.0, 1.0))


## Hauteur du sol de la case (tx, ty) au point (x, z).
func cell_height_at(tx: int, ty: int, x: float, z: float) -> float:
	var i := ty * grid_w + tx
	var si := stair_idx[i]
	if si < 0:
		return cell_h[i]
	return stair_height(stairs[si], x, z)


## Hauteur du sol sous le point (x, z) ; 0 sur une carte sans relief.
func ground_y(x: float, z: float) -> float:
	if not has_relief:
		return 0.0
	return cell_height_at(clampi(int(floor(x)), 0, grid_w - 1), clampi(int(floor(z)), 0, grid_h - 1), x, z)


## Vrai si le disque (p, r) touche un bord de la case (tx, ty) qui sépare deux niveaux.
func _edge_hit(p: Vector2, r: float, tx: int, ty: int, bits: int) -> bool:
	var r2 := r * r
	var x0 := float(tx)
	var y0 := float(ty)
	if bits & 1 != 0 and Vector2(clampf(p.x, x0, x0 + 1.0), y0).distance_squared_to(p) < r2:
		return true
	if bits & 2 != 0 and Vector2(x0 + 1.0, clampf(p.y, y0, y0 + 1.0)).distance_squared_to(p) < r2:
		return true
	if bits & 4 != 0 and Vector2(clampf(p.x, x0, x0 + 1.0), y0 + 1.0).distance_squared_to(p) < r2:
		return true
	if bits & 8 != 0 and Vector2(x0, clampf(p.y, y0, y0 + 1.0)).distance_squared_to(p) < r2:
		return true
	return false


# ---------------------------------------------------------------- collisions

func is_free(p: Vector2, r: float, ignore: Node = null) -> bool:
	var x0 := int(floor(p.x - r))
	var x1 := int(floor(p.x + r))
	var y0 := int(floor(p.y - r))
	var y1 := int(floor(p.y + r))
	for ty in range(y0, y1 + 1):
		for tx in range(x0, x1 + 1):
			var solid := true
			if tx >= 0 and ty >= 0 and tx < grid_w and ty < grid_h:
				solid = blocked[ty * grid_w + tx] != 0
				if not solid and has_relief:
					var eb := edge_block[ty * grid_w + tx]
					if eb != 0 and _edge_hit(p, r, tx, ty, eb):
						return false
			if solid:
				var nx := clampf(p.x, tx, tx + 1.0)
				var ny := clampf(p.y, ty, ty + 1.0)
				if Vector2(nx, ny).distance_squared_to(p) < r * r:
					return false
	for rect in rects:
		var nx := clampf(p.x, rect.position.x, rect.end.x)
		var ny := clampf(p.y, rect.position.y, rect.end.y)
		if Vector2(nx, ny).distance_squared_to(p) < r * r:
			return false
	for c in circles:
		var rr := r + c.z
		if Vector2(c.x, c.y).distance_squared_to(p) < rr * rr:
			return false
	for n: Node3D in npcs:
		if n == ignore:
			continue
		var rr := r + 0.34
		if Vector2(n.position.x, n.position.z).distance_squared_to(p) < rr * rr:
			return false
	if player != null and player != ignore and ignore != null:
		var rr := r + 0.28
		if Vector2(player.position.x, player.position.z).distance_squared_to(p) < rr * rr:
			return false
	return true


func nearest_free(start: Vector3) -> Vector3:
	for ring in range(1, 40):
		var d := ring * 0.25
		for k in 16:
			var a := TAU * k / 16.0
			var p := Vector2(start.x + cos(a) * d, start.z + sin(a) * d)
			if is_free(p, 0.3, player):
				return Vector3(p.x, ground_y(p.x, p.y), p.y)
	return start


# -------------------------------------------------------------------- caméra

func _setup_camera() -> void:
	var cam: Dictionary = map.get("camera", {})
	cam_distance = float(cam.get("distance", 24.0)) * (1.0 if bool(map.get("interior", false)) else ZOOM)
	cam_pitch = float(cam.get("pitch", 32.0))
	camera = Camera3D.new()
	camera.fov = float(cam.get("fov", 24.0))
	camera.near = 0.5
	camera.far = 220.0
	camera.rotation_degrees = Vector3(-cam_pitch, 0.0, 0.0)
	# Flou de profondeur « maquette » : net à la distance du héros, flou devant et derrière.
	var attr := CameraAttributesPractical.new()
	attr.dof_blur_far_enabled = true
	attr.dof_blur_far_distance = cam_distance * float(cam.get("far_start", 1.15))
	attr.dof_blur_far_transition = cam_distance * 0.45
	attr.dof_blur_near_enabled = true
	attr.dof_blur_near_distance = cam_distance * float(cam.get("near_start", 0.87))
	attr.dof_blur_near_transition = cam_distance * 0.14
	attr.dof_blur_amount = float(cam.get("dof", 0.1))
	camera.attributes = attr
	_dof_near_k = float(cam.get("near_start", 0.87))
	_dof_far_k = float(cam.get("far_start", 1.15))
	Settings.apply_camera(attr)
	add_child(camera)
	camera.make_current()

	var mx := 9.0 * ZOOM
	var x0 := minf(mx, grid_w * 0.5)
	var x1 := maxf(grid_w - mx, grid_w * 0.5)
	var z0 := minf(9.0 * ZOOM, grid_h * 0.5)
	var z1 := maxf(grid_h - 7.0 * ZOOM, grid_h * 0.5)
	var b: Variant = cam.get("bounds")
	if b is Array and (b as Array).size() == 4:
		x0 = float(b[0])
		z0 = float(b[1])
		x1 = float(b[2])
		z1 = float(b[3])
	_cam_bounds = Rect2(x0, z0, x1 - x0, z1 - z0)


func _desired_target() -> Vector3:
	var b := _cam_bounds
	if player == null:
		# mode vitrine (écran-titre) : lent travelling latéral
		var k := 0.5 + 0.5 * sin(_time * 0.07 - 1.2)
		var fz := b.position.y + b.size.y * 0.5
		var focus_a: Variant = map.get("title_focus")
		if focus_a is Array and (focus_a as Array).size() == 2:
			fz = float(focus_a[1]) + 0.5
		return Vector3(lerpf(b.position.x, b.end.x, k), 0.0, fz)
	return Vector3(clampf(player.position.x, b.position.x, b.end.x), player.position.y, clampf(player.position.z, b.position.y, b.end.y))


## Mise au point : la zone nette suit la profondeur réelle du héros (quand la caméra bute sur le bord de la
## carte, il n'est plus à la distance nominale et sortait de la zone nette). Ni l'angle ni le zoom ne changent.
func _focus_on_player() -> void:
	var attr := camera.attributes as CameraAttributesPractical
	if attr == null:
		return
	var depth := (player.global_position + Vector3(0.0, 0.7, 0.0) - camera.global_position).dot(-camera.global_transform.basis.z)
	if depth < 1.0:
		return
	attr.dof_blur_near_distance = depth * _dof_near_k
	attr.dof_blur_far_distance = depth * _dof_far_k
	attr.dof_blur_near_transition = depth * 0.14
	attr.dof_blur_far_transition = depth * 0.45


func _apply_camera() -> void:
	var pitch := deg_to_rad(cam_pitch)
	camera.position = _cam_target + Vector3(0.0, 0.8, 0.0) + Vector3(0.0, sin(pitch), cos(pitch)) * cam_distance
	for f: Node3D in followers:
		f.position.x = _cam_target.x
		f.position.z = _cam_target.z


## Un bâtiment situé entre la caméra et le point regardé masquerait le bas de l'écran :
## plus il est au premier plan, plus on le rend transparent.
func _fade_occluders(delta: float) -> void:
	for oc: Dictionary in occluders:
		var r: Rect2 = oc["rect"]
		var target := clampf((r.position.y - _cam_target.z - 0.5) / 2.5, 0.0, 1.0) * 0.88
		var fade := move_toward(float(oc["fade"]), target, delta * 2.5)
		if is_equal_approx(fade, float(oc["fade"])):
			continue
		oc["fade"] = fade
		for n: GeometryInstance3D in oc["nodes"]:
			if is_instance_valid(n):
				n.transparency = fade


func screen_position(world_pos: Vector3) -> Vector2:
	return camera.unproject_position(world_pos)


# ------------------------------------------------------------------- boucle

func _process(delta: float) -> void:
	_time += delta
	_cooldown = maxf(0.0, _cooldown - delta)
	_cam_target = _cam_target.lerp(_desired_target(), 1.0 - exp(-5.0 * delta))
	_apply_camera()
	_fade_occluders(delta)
	if player == null:
		return
	# les décors placés devant le héros s'ajourent autour de lui (voir sprite.gdshader)
	RenderingServer.global_shader_parameter_set("focus_world", player.global_position + Vector3(0.0, 0.75, 0.0))
	_focus_on_player()
	_update_focus()
	if input_enabled:
		_check_warps()
		_check_triggers()
		_check_encounters()


## Rencontres aléatoires : dans une zone, chaque pas rapproche du prochain combat.
func _check_encounters() -> void:
	var pp := Vector2(player.position.x, player.position.z)
	var moved := minf(pp.distance_to(_last_xz), 0.5)
	_last_xz = pp
	if moved <= 0.0001:
		return
	for z: Dictionary in encounter_zones:
		var r: Rect2 = z["rect"]
		if not r.has_point(pp):
			continue
		if _enc_left < 0.0:
			var table: Dictionary = {}
			var t: Variant = Database.encounter_tables.get(str(z["table"]), {})
			if t is Dictionary:
				table = t
			_enc_left = randf_range(float(table.get("min_distance", 7.0)), float(table.get("max_distance", 15.0)))
		_enc_left -= moved
		if _enc_left <= 0.0:
			_enc_left = -1.0
			encounter_requested.emit(str(z["table"]))
		return


func _unhandled_input(event: InputEvent) -> void:
	if not input_enabled or player == null or _cooldown > 0.0:
		return
	if event.is_action_pressed("interact") and not focus.is_empty():
		get_viewport().set_input_as_handled()
		interact_requested.emit(focus)


func interactable_position(it: Dictionary) -> Vector3:
	var node: Variant = it.get("node")
	if node is Node3D and is_instance_valid(node):
		return (node as Node3D).position
	return it["pos"]


func _update_focus() -> void:
	focus = {}
	if not input_enabled:
		return
	var pp := Vector2(player.position.x, player.position.z)
	var fv: Vector2 = player.facing_vector()
	var best := 1e9
	for it: Dictionary in interactables:
		var ip := interactable_position(it)
		var d := Vector2(ip.x, ip.z) - pp
		var dist := d.length()
		if dist > float(it.get("reach", 1.5)):
			continue
		var facing_dot := 1.0
		if dist > 0.3:
			facing_dot = d.normalized().dot(fv)
		if facing_dot < -0.15:
			continue
		var score := dist - facing_dot * 0.5
		if score < best:
			best = score
			focus = it


func _check_warps() -> void:
	var pp := Vector2(player.position.x, player.position.z)
	var hit: Dictionary = {}
	for wp: Dictionary in warps:
		var r: Rect2 = wp["rect"]
		if r.has_point(pp):
			hit = wp
			break
	if hit.is_empty():
		_warp_lock = false
	elif not _warp_lock:
		_warp_lock = true
		warp_requested.emit(str(hit["map"]), str(hit["spawn"]))


func _check_triggers() -> void:
	var pp := Vector2(player.position.x, player.position.z)
	for i in triggers.size():
		var tr: Dictionary = triggers[i]
		var r: Rect2 = tr["rect"]
		var inside := r.has_point(pp)
		var was: bool = _inside.get(i, false)
		_inside[i] = inside
		if inside and not was:
			var unless := str(tr["unless"])
			if unless != "" and GameState.has_flag(unless):
				continue
			trigger_fired.emit(str(tr["dialogue"]))
			return
