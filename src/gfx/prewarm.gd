extends RefCounted
## PRÉCHAUFFAGE DES SHADERS ET DES PIPELINES (voir docs/PERFORMANCE.md).
##
## Godot compile un pipeline graphique la première fois qu'une combinaison matériau / maillage /
## passe de rendu est dessinée. Fait sur le fil du rendu pendant le jeu, cela donne un à-coup. Ici,
## au lancement (sous un écran noir « Chargement… » animé), on dessine une fois, hors champ, dans un
## SubViewport : chaque shader du dossier src/gfx/shaders (sol, eau, roche, sprites, horizon...) sur
## un maillage éclairé qui projette une ombre, puis les ambiances types (soleil à ombres,
## brouillard, glow, rayons, particules). Le SubViewport est ensuite retiré.
##
## La liste des shaders N'EST PAS écrite à la main : elle est lue dans le dossier. Un nouveau shader
## est donc préchauffé sans rien faire (et le test automatique le vérifie).

const Atmosphere = preload("res://src/world/atmosphere.gd")
const SHADER_DIR := "res://src/gfx/shaders/"
## Ambiances dessinées pour chauffer environnement, lumières, brouillard, rayons et particules.
const AMBIANCES := ["crepuscule", "mines", "chutes", "col_neige", "grand_four", "marais"]

static var covered: PackedStringArray = PackedStringArray()   # shaders effectivement dessinés
static var last_ms := 0.0
static var done := false


## Chemins de tous les shaders du jeu. `ResourceLoader.list_directory` (et non DirAccess) : dans un jeu
## exporté, DirAccess sur res:// ne voit pas les fichiers sous leur nom d'origine (ils sont remappés).
static func shader_paths() -> PackedStringArray:
	var out := PackedStringArray()
	var names := ResourceLoader.list_directory(SHADER_DIR)
	if names.is_empty():
		names = DirAccess.get_files_at(SHADER_DIR)
	for n in names:
		var f := n.trim_suffix(".remap")
		if f.ends_with(".gdshader"):
			out.append(SHADER_DIR + f)
	out.sort()
	return out


## Dessine tout une fois. `host` : un nœud dans l'arbre. `force` : même sans rendu (tests).
static func run(host: Node, force: bool = false) -> void:
	if done and not force:
		return
	if DisplayServer.get_name() == "headless" and not force:
		return
	var t0 := Time.get_ticks_usec()
	var tree := host.get_tree()
	var vp := SubViewport.new()
	vp.size = Vector2i(320, 180)
	vp.own_world_3d = true
	vp.msaa_3d = host.get_viewport().msaa_3d
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	host.add_child(vp)
	covered = PackedStringArray()

	# 1. chaque shader, dans une grille devant la caméra
	var stage := Node3D.new()
	vp.add_child(stage)
	var cam := Camera3D.new()
	cam.position = Vector3(0.0, 0.0, 9.0)
	cam.fov = 40.0
	stage.add_child(cam)
	var sun := DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.rotation_degrees = Vector3(-40.0, 30.0, 0.0)
	stage.add_child(sun)
	var omni := OmniLight3D.new()
	omni.position = Vector3(0.0, 2.0, 5.0)
	omni.omni_range = 12.0
	omni.shadow_enabled = true
	stage.add_child(omni)
	var paths := shader_paths()
	var i := 0
	for path in paths:
		var shader := load(path) as Shader
		if shader == null:
			continue
		var mat := ShaderMaterial.new()
		mat.shader = shader
		match shader.get_mode():
			Shader.MODE_SPATIAL:
				var mi := MeshInstance3D.new()
				var q := QuadMesh.new()
				q.size = Vector2(1.6, 1.6)
				mi.mesh = q
				mi.material_override = mat
				mi.position = Vector3(float(i % 5) * 1.8 - 3.6, float(i / 5) * 1.8 - 2.4, 0.0)
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
				stage.add_child(mi)
				# la même chose sur un plan large : autre format de sommets (cartes : sols, falaises)
				var pl := MeshInstance3D.new()
				pl.mesh = PlaneMesh.new()
				pl.material_override = mat
				pl.position = Vector3(float(i % 5) * 1.8 - 3.6, float(i / 5) * 1.8 - 2.4, -3.0)
				pl.rotation_degrees = Vector3(90.0, 0.0, 0.0)
				stage.add_child(pl)
			Shader.MODE_CANVAS_ITEM:
				var cr := ColorRect.new()
				cr.size = Vector2(60.0, 60.0)
				cr.position = Vector2(float(i % 5) * 62.0, float(i / 5) * 62.0)
				cr.material = mat
				vp.add_child(cr)
			Shader.MODE_SKY:
				var env := Environment.new()
				env.background_mode = Environment.BG_SKY
				var sky := Sky.new()
				sky.sky_material = mat
				env.sky = sky
				var we := WorldEnvironment.new()
				we.environment = env
				stage.add_child(we)
			_:
				pass
		covered.append(path)
		i += 1
	for _k in 3:
		await tree.process_frame
	stage.queue_free()
	await tree.process_frame

	# 2. les ambiances types : environnement, ombres, brouillard, rayons, particules
	for id: String in AMBIANCES:
		if not Database.ambiances.has(id):
			continue
		var s2 := Node3D.new()
		vp.add_child(s2)
		var c2 := Camera3D.new()
		c2.position = Vector3(4.0, 3.0, 9.0)
		c2.fov = 30.0
		s2.add_child(c2)
		c2.look_at(Vector3(4.0, 0.0, 4.0))
		var floor_mesh := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(8.0, 8.0)
		floor_mesh.mesh = pm
		floor_mesh.position = Vector3(4.0, 0.0, 4.0)
		s2.add_child(floor_mesh)
		Atmosphere.build(s2, Database.get_ambiance(id), Rect2(0.0, 0.0, 8.0, 8.0))
		for _k in 2:
			await tree.process_frame
		s2.queue_free()
		await tree.process_frame

	vp.queue_free()
	await tree.process_frame
	last_ms = (Time.get_ticks_usec() - t0) / 1000.0
	done = true
