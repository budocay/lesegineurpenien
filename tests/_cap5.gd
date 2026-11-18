extends Node
## TEMPORAIRE (chantier décors 5) : args = dossier puis « carte|spawn|x,z|x,z ... »
const MAIN = preload("res://scenes/main.tscn")
var main: Node
func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0]
	DirAccess.make_dir_recursive_absolute(out)
	SaveManager.save_path = "user://test_cap5.json"
	SaveManager.delete_save()
	main = MAIN.instantiate()
	add_child(main)
	await _frames(100)
	GameState.new_game()
	GameState.party = []
	for id: String in ["sam", "froton", "pepin", "merri"]:
		GameState.add_to_party(id)
		GameState.member(id)["level"] = 18
	for f in ["chapitre_4_fini", "bois_vu", "roseliere_vue"]:
		GameState.set_flag(f)
	GameState.map_id = "brie"
	GameState.heal_party()
	SaveManager.save_game()
	main.continue_game()
	await _frames(120)
	await _idle()
	for i in range(1, args.size()):
		var parts := args[i].split("|")
		main.busy = false
		for e: Variant in Database.get_map(parts[0]).get("on_enter", []):
			if e is Dictionary and str(e.get("unless", "")) != "":
				GameState.set_flag(str(e["unless"]))
		main.change_map(parts[0], parts[1])
		await _frames(110)
		await _idle()
		main.world.encounter_zones.clear()
		main.hud.visible = false
		await _frames(60)
		await _shot("%s/%s_0" % [out, parts[0]])
		for k in range(2, parts.size()):
			var xz := parts[k].split(",")
			main.world.player.position = Vector3(float(xz[0]), 0.0, float(xz[1]))
			main.world.player.position.y = main.world.ground_y(float(xz[0]), float(xz[1]))
			await _frames(70)
			await _shot("%s/%s_%d" % [out, parts[0], k - 1])
	SaveManager.delete_save()
	get_tree().quit()
func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame
func _idle() -> void:
	for _i in 3000:
		await get_tree().process_frame
		if main.battle != null or main.dialogue.waiting:
			continue
		if main.dialogue.active:
			if main.dialogue._typing:
				main.dialogue._finish_typing()
			elif not main.dialogue._choosing:
				main.dialogue._advance()
			else:
				var b: Array = main.dialogue._choice_list.get_children()
				(b[b.size() - 1] as Button).pressed.emit()
		elif not main.busy and main.world != null and main.world.input_enabled:
			return
func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path + ".png")
