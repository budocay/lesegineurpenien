extends Node
## Outil : captures ciblées (avec fenêtre).
##   Godot --path . res://tests/_retouche_cap.tscn -- <dossier> <spec> [spec ...]
## spec carte    : m:carte:spawn:x:z:direction:nom
## spec combat   : b:arène:allié,allié:ennemi,ennemi:nom
## spec anim     : a:animation:lanceur:nom   (dans le combat en cours)
## spec ui       : u:nom  (écran Équipe)
const MAIN = preload("res://scenes/main.tscn")
var main: Node


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0]
	DirAccess.make_dir_recursive_absolute(out)
	SaveManager.save_path = "user://test_shoot.json"
	SaveManager.delete_save()
	main = MAIN.instantiate()
	add_child(main)
	for _i in 60:
		await get_tree().process_frame
	main.title.close()
	GameState.new_game()
	main.mode = main.Mode.PLAY
	GameState.playing = true
	for s: String in args.slice(1):
		var p := s.split(":")
		match p[0]:
			"m":
				for id: String in ["pepine", "sam", "fripon"]:
					GameState.add_to_party(id)
				for f: String in ["bois_vu", "roseliere_vue"]:
					GameState.set_flag(f)
				if main.world == null or main.world.player == null:
					GameState.map_id = p[1]
					GameState.spawn_id = p[2]
					main._begin_play([], "")
					await _frames(30)
				else:
					main.change_map(p[1], p[2])
				await _frames(150)
				await _idle()
				if p[3] != "-":
					main.world.player.position = Vector3(float(p[3]), 0.0, float(p[4]))
					main.world.player.set_facing(p[5])
					await _frames(150)
				await _shot(out, p[6])
			"b":
				if main.battle != null:
					main.battle_ui._on_end("ok")
					await _frames(10)
					await _idle()
					await _frames(60)
				for id: String in ["glandoulf", "sam", "fripon", "pepine", "aragrogne", "legolasse", "gimlette"]:
					GameState.party.erase(id)
				var allies: PackedStringArray = p[2].split(",")
				for id: String in allies:
					GameState.add_to_party(id)
				GameState.heal_party()
				main.start_battle({"enemies": Array(p[3].split(",")), "arena": p[1]})
				await get_tree().create_timer(4.0).timeout
				await _until_menu()
				await _frames(50)
				await _shot(out, p[4])
			"a":
				await _anim(out, p[1], p[2], p[3])
	print("RETOUCHE OK")
	get_tree().quit()


func _anim(out: String, anim: String, who: String, nm: String) -> void:
	var b: Node3D = main.battle
	var caster: Node3D = null
	var allies: Array = []
	var foes: Array = []
	for c: RefCounted in b.engine.party:
		allies.append(b.actor_of(c))
		if str(c.source) == who:
			caster = b.actor_of(c)
	for c: RefCounted in b.engine.enemies:
		foes.append(b.actor_of(c))
	if caster == null:
		caster = allies[0]
	var on_party := anim in ["sieste_collective", "banquet"]
	var targets: Array = allies if on_party else foes
	b.fx.play(anim, caster, targets, "")
	var impact := float(Database.get_animation(anim).get("impact", 0.4))
	await get_tree().create_timer(impact + 0.09).timeout
	await _shot(out, nm)
	await get_tree().create_timer(1.8).timeout


func _frames(n: int) -> void:
	for _i in n:
		await get_tree().process_frame


func _until_menu() -> void:
	for _i in 4000:
		await get_tree().process_frame
		if main.battle != null and main.battle_ui._state == main.battle_ui.S.ROOT:
			return


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
				var buttons: Array = main.dialogue._choice_list.get_children()
				(buttons[buttons.size() - 1] as Button).pressed.emit()
		elif not main.busy and main.world != null and main.world.input_enabled:
			return


func _shot(out: String, nm: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, nm])
