extends Node
## Outil : affiche la part visible de chaque combattant pour 1 à 6 alliés (sans fenêtre).
##   Godot --headless --path . res://tests/_visibility.tscn
const BattleScene = preload("res://src/battle/battle_scene.gd")
const BattleUI = preload("res://src/battle/battle_ui.gd")
const Vis = preload("res://tests/_visibility.gd")


func _ready() -> void:
	get_window().size = Vector2i(1600, 900)
	await get_tree().process_frame
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui: Control = BattleUI.new()
	layer.add_child(ui)
	await get_tree().process_frame
	var ids: Array = ["glandoulf", "pepine", "sam", "fripon", "aragrogne", "legolasse", "gimlette"]
	var foes_sets := [["limace_molle"], ["limace_molle", "guepe_cidre"], ["epouvantail_avachi", "limace_molle", "guepe_cidre"], ["epouvantail_avachi", "limace_molle", "guepe_cidre", "sanglier_flapi"], ["epouvantail_avachi", "limace_molle", "guepe_cidre", "sanglier_flapi", "champignon_dormeur"]]
	for n in range(2, 7):
		var party: Array = []
		for i in n:
			party.append({"id": str(ids[i]), "level": 5})
		for foes: Array in foes_sets:
			var s: Node3D = BattleScene.new()
			add_child(s)
			s.setup({"enemies": foes, "arena": "pre", "party": party}, ui, 3)
			await get_tree().process_frame
			await get_tree().process_frame
			var f := Vis.fractions(s)
			var worst := 1.0
			var worst_key := ""
			for k: Variant in f:
				if float(f[k]) < worst:
					worst = float(f[k])
					worst_key = str(k)
			if foes.size() == 3 and n == 6:
				print("   ", f)
				for kk: Variant in s.actors:
					var aa: Node3D = s.actors[kk]
					print("   pos ", kk, " ", aa.position, " ", s.camera.unproject_position(aa.anchor("feet")), " ", aa.height)
			print("%d allies, %d ennemis : pire visibilité %.2f (%s)" % [n, foes.size(), worst, worst_key])
			ui.close()
			remove_child(s)
			s.queue_free()
			await get_tree().process_frame
	print("VISIBILITE OK")
	get_tree().quit()
