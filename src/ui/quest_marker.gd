extends Control
## Marque flottante du repère de quête : un petit losange doré, qui se balance au-dessus de la cible
## de l'étape en cours (voir src/core/quest_target.gd). Hors de l'écran, il devient une pointe collée
## au bord, dans la direction à suivre. Quand la cible est dans une autre carte, il désigne le passage
## à prendre. Posé par objective_tracker.gd ; coupé par le réglage « Repère de quête ».

const QuestTarget = preload("res://src/core/quest_target.gd")
const UI = preload("res://src/ui/ui_kit.gd")

const EDGE := 44.0          # distance au bord de l'écran d'une pointe
const HIDE_NEAR := 2.2      # on est arrivé : la bulle d'interaction prend le relais

var quest := ""             # quête suivie (renseignée par l'encart)
var step := 0               # étape suivie
var shown := 0              # nombre de marques dessinées à cette image (tests)

var _marks: Array = []      # [{"at": Vector2 (écran), "edge": bool, "dir": Vector2}]
var _time := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	UI.full_rect(self)
	z_index = -1


## Cibles à marquer, en positions monde : [Vector3]. Vide si le repère est coupé, l'écran occupé ou
## la cible hors de cette carte (alors, le passage à prendre).
func world_targets() -> Array:
	var out: Array = []
	var world: Node3D = _world()
	if world == null or quest == "" or not bool(Settings.get_value("repere")) or not Tutorial.explore_open():
		return out
	var player: Node3D = world.get("player")
	if player == null:
		return out
	var here := str(world.get("map_id"))
	for t: Dictionary in QuestTarget.targets_of_step(quest, step):
		if str(t.get("map", "")) == here:
			var p: Variant = QuestTarget.world_position(world, t)
			if p != null:
				out.append(p)
		else:
			var hop := QuestTarget.route(here, str(t.get("map", "")))
			if not hop.is_empty():
				var at: Vector2 = hop["pos"]
				out.append(Vector3(at.x, world.ground_y(at.x, at.y) + 1.6, at.y))
	return out


func _world() -> Node3D:
	var host: Variant = Tutorial.host
	if host == null or not is_instance_valid(host):
		return null
	return (host as Node).get("world")


func _process(delta: float) -> void:
	_time += delta
	_marks = []
	var world := _world()
	if world != null:
		var player: Node3D = world.get("player")
		var cam: Camera3D = world.get("camera")
		var view := get_viewport_rect().size
		for p: Vector3 in world_targets():
			if player != null and Vector2(player.position.x, player.position.z).distance_to(Vector2(p.x, p.z)) < HIDE_NEAR:
				continue
			var s: Vector2 = cam.unproject_position(p)
			var behind := cam.is_position_behind(p)
			var inside := not behind and Rect2(Vector2(30.0, 90.0), view - Vector2(60.0, 130.0)).has_point(s)
			if inside:
				_marks.append({"at": s, "edge": false, "dir": Vector2.ZERO})
			else:
				var dir := (s - view * 0.5).normalized()
				if behind:
					dir = -dir
				if dir.length() < 0.1:
					dir = Vector2.UP
				# point d'intersection de la demi-droite centre -> dir avec le cadre de l'écran, replié de EDGE
				var half := view * 0.5 - Vector2(EDGE, EDGE)
				var k := minf(half.x / maxf(absf(dir.x), 0.0001), half.y / maxf(absf(dir.y), 0.0001))
				_marks.append({"at": view * 0.5 + dir * k, "edge": true, "dir": dir})
	shown = _marks.size()
	queue_redraw()


func _draw() -> void:
	for m: Dictionary in _marks:
		var at: Vector2 = m["at"]
		var pulse := 0.5 + 0.5 * sin(_time * 3.2)
		if bool(m["edge"]):
			var dir: Vector2 = m["dir"]
			var side := Vector2(-dir.y, dir.x)
			var tip := at + dir * 20.0
			var pts := PackedVector2Array([tip, at - dir * 8.0 + side * 13.0, at - dir * 8.0 - side * 13.0])
			draw_colored_polygon(pts, Color(UI.GOLD, 0.45 + 0.35 * pulse))
			draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color(UI.GOLD, 0.9), 1.5, true)
			continue
		var bob := sin(_time * 2.6) * 3.0
		var c := at + Vector2(0.0, bob)
		draw_circle(c, 22.0 + 4.0 * pulse, Color(UI.GOLD, 0.10 + 0.07 * pulse))
		draw_circle(c, 13.0, Color(UI.GOLD, 0.14))
		draw_colored_polygon(UI.diamond_points(c, 13.0), Color(0.04, 0.04, 0.09, 0.88))
		draw_colored_polygon(UI.diamond_points(c, 10.5), Color(UI.GOLD, 0.97))
		draw_colored_polygon(UI.diamond_points(c, 4.5), Color(1.0, 0.97, 0.85, 0.97))
		# petite pointe vers le bas, qui désigne la cible
		draw_colored_polygon(PackedVector2Array([c + Vector2(-6.0, 18.0), c + Vector2(6.0, 18.0), c + Vector2(0.0, 26.0)]), Color(UI.GOLD, 0.92))
