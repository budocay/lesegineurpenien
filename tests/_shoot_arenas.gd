extends Node
## Outil : capture chaque arène de combat (avec fenêtre).
##   Godot --path . res://tests/_shoot_arenas.tscn -- <dossier> [arène ...]
const MAIN = preload("res://scenes/main.tscn")
var main: Node

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0]
	DirAccess.make_dir_recursive_absolute(out)
	var ids: Array = args.slice(1) if args.size() > 1 else ["pre", "grand_four", "bois", "marais", "place"]
	SaveManager.save_path = "user://test_shoot.json"
	SaveManager.delete_save()
	main = MAIN.instantiate()
	add_child(main)
	for _i in 60:
		await get_tree().process_frame
	main.title.close()
	GameState.new_game()
	for id: String in ["sam", "fripon", "pepine"]:
		GameState.add_to_party(id)
	main.mode = main.Mode.PLAY
	GameState.playing = true
	for id: String in ids:
		main.start_battle({"enemies": ["epouvantail_avachi", "limace_molle", "guepe_cidre"], "arena": id})
		for _i in 150:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("%s/arene_%s.png" % [out, id])
		main.battle.auto = true
		main.battle.fast = true
		for _i in 600:
			await get_tree().process_frame
			if main.battle == null or main.battle_ui._end_layer.visible:
				break
		if main.battle != null:
			main.battle_ui._on_end("ok")
		for _i in 60:
			await get_tree().process_frame
	print("ARENES OK")
	get_tree().quit()
