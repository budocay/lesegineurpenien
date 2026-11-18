extends Node
## TEMPORAIRE : captures ciblées (à supprimer avant de terminer).
const MAIN = preload("res://scenes/main.tscn")
var main: Node
var out := ""

func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame

func _full(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])

func _crop(name: String, r: Rect2, k: int = 2) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var rr := r.intersection(Rect2(Vector2.ZERO, Vector2(img.get_size())))
	var c := img.get_region(Rect2i(rr))
	c.resize(c.get_width() * k, c.get_height() * k, Image.INTERPOLATE_BILINEAR)
	c.save_png("%s/%s.png" % [out, name])

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	out = a[0]
	DirAccess.make_dir_recursive_absolute(out)
	SaveManager.save_path = "user://test_shoot.json"
	SaveManager.delete_save()
	main = MAIN.instantiate()
	add_child(main)
	await _frames(60)
	main.title.close()
	GameState.new_game()
	main.mode = main.Mode.PLAY
	GameState.playing = true
	match a[1]:
		"battle": await _battle(a)
		"explore": await _explore(a)
		"boss": await _boss(a)
	print("OK ", a[1])
	get_tree().quit()

func _start(allies: Array, enemies: Array, arena: String, boss: bool) -> void:
	for id: String in allies:
		GameState.add_to_party(id)
	GameState.party = GameState.party.filter(func(x: String) -> bool: return allies.has(x))
	main.start_battle({"enemies": enemies, "arena": arena, "music": "boss" if boss else "", "flee": not boss})
	for _i in 3000:
		await get_tree().process_frame
		if main.battle != null and main.battle_ui._state == main.battle_ui.S.ROOT:
			break
	await _frames(40)

## battle <out> battle allies enemies arena poses(csv: strike,shoot,cast,hit,ko)
func _battle(a: Array) -> void:
	await _start(a[2].split(","), a[3].split(","), a[4], false)
	var sc: Node3D = main.battle
	await _full("battle_idle")
	var foe: RefCounted = sc.engine.enemies[0]
	var toward: Vector3 = sc.actors[foe.key].home
	for c: RefCounted in sc.engine.party:
		var act: Node3D = sc.actors[c.key]
		for pose: String in a[5].split(","):
			var times := [0.1, 0.2, 0.32]
			if pose == "shoot":
				times = [0.12, 0.25, 0.38]
			if pose == "hit":
				times = [0.05, 0.12]
			if pose == "ko":
				times = [0.12, 0.5, 0.9]
			var elapsed := 0.0
			match pose:
				"hit": act.play_hit(true)
				"ko": act.play_ko()
				_: act.play_pose(pose, toward, 0.35)
			for t: float in times:
				await get_tree().create_timer(t - elapsed).timeout
				elapsed = t
				var cam: Camera3D = sc.camera
				var foot := cam.unproject_position(act.global_position)
				var topp := cam.unproject_position(act.global_position + Vector3(0, act.height, 0))
				var ph: float = absf(foot.y - topp.y)
				var r := Rect2(foot.x - ph * 0.9, topp.y - ph * 0.25, ph * 1.8, ph * 1.55)
				await _crop("%s_%s_%d" % [c.key, pose, int(t * 100)], r)
			if pose == "ko":
				act.play_revive()
			await get_tree().create_timer(1.0).timeout

func _explore(a: Array) -> void:
	# explore out explore ids facing walk
	for id: String in ["sam", "froton", "pepin"]:
		GameState.add_to_party(id)
	GameState.map_id = "pre_couche"
	main._load_world("pre_couche", "ouest", [], "", false)
	await _frames(20)
	await main._fade_to(0.0, 0.1)
	await _frames(60)
	var CS: GDScript = load("res://src/world/character_sprite.gd")
	var p: Node3D = main.world.player
	p.position = Vector3(12.0, 0.0, 10.8)
	var ids: Array = a[2].split(",")
	var made: Array = []
	for i in ids.size():
		var s: Node3D = CS.new()
		s.setup(Sprites.character(ids[i]))
		main.world.add_child(s)
		s.position = p.position + Vector3((float(i) - ids.size() * 0.5 + 0.5) * 1.9, 0.0, 1.0)
		made.append(s)
	p.visible = false
	var cam: Camera3D = get_viewport().get_camera_3d()
	for fac: String in a[3].split(","):
		for walk: int in [0, 1, 2]:
			for i in made.size():
				made[i].facing = fac
				made[i].moving = walk > 0
				made[i]._time = float(walk - 1) * 2.0
			await _frames(30 if walk < 2 else 7)
			if walk == 1:
				for i in made.size():
					made[i].moving = false
				await _frames(2)
				for i in made.size():
					made[i].moving = true
					made[i]._time = 0.0
			await _frames(2)
			for i in made.size():
				var pt: Vector2 = cam.unproject_position(made[i].position)
				await _crop("%s_%s_%d" % [ids[i], fac, walk], Rect2(pt.x - 100, pt.y - 210, 200, 260), 3)

func _boss(a: Array) -> void:
	await _start(a[2].split(","), a[3].split(","), a[4], true)
	await _full("boss_%s_%s" % [a[3].replace(",", "_"), a[4]])
