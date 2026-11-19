extends Node3D
## Horizon d'une carte (champ `horizon`) : un vrai ciel (dégradé, nuages peints qui dérivent,
## lumière basse) posé comme fond de l'environnement, et des plans d'arrière-plan peints à
## des distances différentes (montagne, cité en étages, plaine de siège), brumés par couches.
## Les plans glissent moins vite que la caméra (parallaxe) ; rien n'est solide ni cliquable.
## Documentation : docs/FORMAT_DONNEES.md, section « Horizon et caméra par carte ».

const Layers = preload("res://src/gfx/horizon_layers.gd")
const SKY_SHADER = preload("res://src/gfx/shaders/sky_horizon.gdshader")
const LAYER_SHADER = preload("res://src/gfx/shaders/horizon_layer.gdshader")
const GROUND_SHADER = preload("res://src/gfx/shaders/horizon_ground.gdshader")

static var _cache: Dictionary = {}
## Cache disque des plans peints (user://cache_horizon/) : la clé est faite des paramètres du plan et de
## l'empreinte du peintre, donc retoucher le peintre invalide tout seul. La peinture écrit des variables
## statiques de horizon_layers.gd : un verrou la sérialise entre le fil de préparation et le fil principal.
const CACHE_DIR := "user://cache_horizon"
const CACHE_VERSION := 1
static var _paint_lock := Mutex.new()
static var _prep_thread: Thread = null
static var _prep_done: Array = []   # cartes déjà préparées (ou en cours) pendant cette session
static var _stamp := ""
static var _glow_mat: StandardMaterial3D = null

## Ciels : couleurs du zénith, du milieu, de la brume d'horizon, du sol lointain ; direction du
## soleil ; part de ciel couverte de nuages.
const SKIES := {
	"matin": {"top": "#4f8fe0", "mid": "#92c4f4", "low": "#f0f4f6", "below": "#e4eaef", "sun": [0.55, 0.16, 0.8],
			"sun_col": "#ffdca0", "clouds": 0.5, "cloud_lit": "#ffffff", "cloud_shade": "#b4c6e2", "speed": 0.006},
	"siege": {"top": "#46689c", "mid": "#8aa3c4", "low": "#e2d6c8", "below": "#cbbfb2", "sun": [0.5, 0.14, 0.8],
			"sun_col": "#ffc880", "clouds": 0.82, "cloud_lit": "#fbf0e0", "cloud_shade": "#7e86a2", "speed": 0.008},
	"col": {"top": "#5a98dc", "mid": "#a8d0f2", "low": "#f2f6f6", "below": "#e6eef0", "sun": [0.4, 0.2, 0.8],
			"sun_col": "#fff0c0", "clouds": 0.45, "cloud_lit": "#ffffff", "cloud_shade": "#b8cae6", "speed": 0.005},
}

## Préréglages : une liste de plans, du plus lointain au plus proche. `z` : où le plan se
## dresse (négatif : au nord de la carte) ; `y` : hauteur de son pied ; `height` : sa hauteur
## en mètres ; `k` : part du mouvement de la caméra qu'il suit (1 = collé au ciel, 0 = fixe) ;
## `haze` : brume en haut et en bas du plan ; `res` : réduction de la peinture (2 = cases deux
## fois plus grosses).
const PRESETS := {
	"cite": {"sky": "matin", "layers": [
		{"kind": "mountain", "w": 2400, "z": -260.0, "y": -40.0, "height": 130.0, "k": 0.97, "seed": 3, "off": 120, "peak": 0.95, "haze": "#bccae2", "haze_top": 0.0, "haze_bottom": 0.5},
		{"kind": "city", "z": -100.0, "y": -4.0, "height": 46.0, "k": 0.86, "seed": 5, "tiers": 4, "haze": "#dbe4f0", "haze_top": 0.0, "haze_bottom": 0.14},
	]},
	"belvedere": {"sky": "matin", "layers": [
			{"kind": "mountain", "w": 2400, "z": -330.0, "y": -45.0, "height": 140.0, "k": 0.97, "seed": 7, "off": -120, "peak": 0.95, "haze": "#bccae2", "haze_top": 0.0, "haze_bottom": 0.5},
			{"kind": "plain", "w": 2400, "z": -240.0, "y": -14.0, "height": 60.0, "k": 0.9, "seed": 21, "fires": 9, "haze": "#d8d0cc", "haze_top": 0.3, "haze_bottom": 0.5},
			{"kind": "city", "z": -120.0, "y": -6.0, "height": 50.0, "k": 0.86, "seed": 5, "tiers": 1, "tower": false, "haze": "#dbe4f0", "haze_top": 0.0, "haze_bottom": 0.14},
		], "ground": {"from": -26.0, "to": -250.0, "y": -13.6, "near": "#8c9862", "far": "#bcc0b0", "haze": "#d6dcea"}},
	"plaine": {"sky": "siege", "layers": [
		{"kind": "mountain", "w": 2400, "z": -330.0, "y": -14.0, "height": 55.0, "k": 0.97, "res": 2, "seed": 12, "off": -500, "peak": 0.6, "haze": "#cfc6c4", "haze_top": 0.35, "haze_bottom": 0.8},
		{"kind": "plain", "w": 2400, "z": -95.0, "y": 0.0, "height": 40.0, "k": 0.85, "res": 2, "seed": 21, "fires": 6, "haze": "#d6cdc4", "haze_top": 0.15, "haze_bottom": 0.3},
		{"kind": "plain", "w": 2400, "z": -170.0, "y": 0.0, "height": 70.0, "k": 0.9, "res": 2, "seed": 4, "fires": 12, "haze": "#d6cdc4", "haze_top": 0.3, "haze_bottom": 0.5},
	], "ground": {"from": -28.0, "to": -400.0, "y": 0.03}},
	"collines": {"sky": "col", "layers": [
		{"kind": "mountain", "w": 2400, "z": -300.0, "y": -20.0, "height": 70.0, "k": 0.97, "res": 2, "seed": 7, "peak": 0.8, "haze": "#d6e2f0", "haze_top": 0.15, "haze_bottom": 0.7},
		{"kind": "hills", "w": 2400, "z": -200.0, "y": -8.0, "height": 40.0, "k": 0.92, "res": 2, "seed": 2, "peak": 0.5, "haze": "#d6e2f0", "haze_top": 0.3, "haze_bottom": 0.7},
	]},
}

var _items: Array = []   # {node, k}
var _cx := 0.0


## Construit l'horizon d'une carte ; renvoie le nœud (ou null si la carte n'en a pas).
static func build(world: Node3D, map: Dictionary) -> Node3D:
	var spec: Variant = map.get("horizon")
	if not (spec is Dictionary) or bool(map.get("interior", false)):
		return null
	var cfg := _config(spec as Dictionary)
	var hz: Node3D = (load("res://src/world/horizon.gd") as GDScript).new()
	hz.name = "Horizon"
	world.add_child(hz)
	var w := float(map.get("size", [32, 32])[0])
	hz._cx = w * 0.5
	hz._make_sky(world, cfg)
	var t0 := Time.get_ticks_msec()
	var layers: Array = cfg.get("layers", [])
	for ld: Variant in layers:
		hz._make_layer(ld as Dictionary, w)
	var g: Variant = cfg.get("ground")
	if g is Dictionary:
		hz._make_ground(g as Dictionary, w, cfg)
	if OS.get_environment("GLAN_HZ_TIME") != "":
		print("HORIZON %s : %d ms" % [str(map.get("id", "?")), Time.get_ticks_msec() - t0])
	var prep: Variant = cfg.get("prepare")
	if prep is Array:
		prepare(prep as Array)
	return hz


func _exit_tree() -> void:
	if _prep_thread != null and not _prep_thread.is_alive():
		_prep_thread.wait_to_finish()
		_prep_thread = null


func follow(cam_x: float) -> void:
	for it: Dictionary in _items:
		var n: Node3D = it["node"]
		n.position.x = lerpf(_cx + float(it["off"]), cam_x, float(it["k"]))


func _sky_spec(cfg: Dictionary) -> Dictionary:
	var s: Variant = cfg.get("sky", "matin")
	var base: Dictionary = (SKIES["matin"] as Dictionary).duplicate()
	if s is String:
		base = (SKIES.get(s, SKIES["matin"]) as Dictionary).duplicate()
	elif s is Dictionary:
		base.merge(s as Dictionary, true)
	return base


func _make_sky(world: Node3D, cfg: Dictionary) -> void:
	var we: WorldEnvironment = null
	for c in world.get_children():
		if c is WorldEnvironment:
			we = c
	if we == null:
		return
	var sp := _sky_spec(cfg)
	var mat := ShaderMaterial.new()
	mat.shader = SKY_SHADER
	mat.set_shader_parameter("top_col", Color(str(sp["top"])))
	mat.set_shader_parameter("mid_col", Color(str(sp["mid"])))
	mat.set_shader_parameter("low_col", Color(str(sp["low"])))
	mat.set_shader_parameter("below_col", Color(str(sp["below"])))
	var sd: Array = sp["sun"]
	mat.set_shader_parameter("sun_dir", Vector3(float(sd[0]), float(sd[1]), float(sd[2])))
	mat.set_shader_parameter("sun_col", Color(str(sp["sun_col"])))
	mat.set_shader_parameter("cloud_amount", float(sp["clouds"]))
	mat.set_shader_parameter("cloud_lit", Color(str(sp["cloud_lit"])))
	mat.set_shader_parameter("cloud_shade", Color(str(sp["cloud_shade"])))
	mat.set_shader_parameter("cloud_speed", float(sp["speed"]))
	var sky := Sky.new()
	sky.sky_material = mat
	var env := we.environment
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.fog_sky_affect = 0.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED


func _make_layer(ld: Dictionary, map_w: float) -> void:
	var kind := str(ld.get("kind", "mountain"))
	var res := maxi(1, int(ld.get("res", 1)))
	var cw := int(ld.get("w", 1200))
	var key := _layer_key(ld)
	var entry: Dictionary = _cache.get(key, {})
	if entry.is_empty():
		var data := _layer_data(key, ld)
		var img: Image = data["img"]
		img.generate_mipmaps()
		entry = {"tex": ImageTexture.create_from_image(img), "fires": data["fires"]}
		_cache[key] = entry
	var tex: ImageTexture = entry["tex"]
	var h := float(ld.get("height", 60.0))
	var w := h * float(cw) / 360.0
	var q := QuadMesh.new()
	q.size = Vector2(w, h)
	var mat := ShaderMaterial.new()
	mat.shader = LAYER_SHADER
	mat.set_shader_parameter("tex", tex)
	mat.set_shader_parameter("haze_col", Color(str(ld.get("haze", "#d6e2f0"))))
	mat.set_shader_parameter("haze_top", float(ld.get("haze_top", 0.15)))
	mat.set_shader_parameter("haze_bottom", float(ld.get("haze_bottom", 0.6)))
	mat.set_shader_parameter("light", float(ld.get("light", 1.0)))
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(_cx, float(ld.get("y", 0.0)) + h * 0.5, float(ld.get("z", -150.0)))
	add_child(mi)
	# lueur des feux : un halo additif posé sur chaque foyer du plan
	var glow_n := int(ld.get("glow", 1))
	for fp: Variant in entry["fires"]:
		if glow_n <= 0:
			break
		var g := MeshInstance3D.new()
		var gq := QuadMesh.new()
		gq.size = Vector2(h * 0.17, h * 0.17)
		g.mesh = gq
		g.material_override = _glow_material()
		g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		g.position = Vector3(((fp as Vector2).x / float(cw) - 0.5) * w, (0.5 - (fp as Vector2).y / 360.0) * h, 0.4)
		mi.add_child(g)
	_items.append({"node": mi, "k": float(ld.get("k", 0.9)), "off": float(ld.get("x", 0.0))})
	follow(_cx)


static func _glow_material() -> StandardMaterial3D:
	if _glow_mat != null:
		return _glow_mat
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(1.0, 0.55, 0.15, 0.85), Color(1.0, 0.35, 0.05, 0.28), Color(1.0, 0.25, 0.0, 0.0)])
	grad.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = tex
	m.disable_fog = true
	m.no_depth_test = false
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glow_mat = m
	return m


## Sol lointain : prolonge le sol de la carte (plaine boueuse du siège) jusqu'à l'horizon.
func _make_ground(g: Dictionary, map_w: float, cfg: Dictionary) -> void:
	var z0 := float(g.get("from", -28.0))
	var z1 := float(g.get("to", -400.0))
	var q := PlaneMesh.new()
	q.size = Vector2(map_w + 900.0, absf(z1 - z0))
	var mat := ShaderMaterial.new()
	mat.shader = GROUND_SHADER
	mat.set_shader_parameter("near_col", Color(str(g.get("near", "#4d3d30"))))
	mat.set_shader_parameter("far_col", Color(str(g.get("far", "#85766a"))))
	var hz := "#d6cdc4"
	var layers: Array = cfg.get("layers", [])
	if not layers.is_empty():
		hz = str((layers[layers.size() - 1] as Dictionary).get("haze", hz))
	mat.set_shader_parameter("haze_col", Color(str(g.get("haze", hz))))
	var mi := MeshInstance3D.new()
	mi.mesh = q
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(map_w * 0.5, float(g.get("y", 0.05)), (z0 + z1) * 0.5)
	add_child(mi)


# ================================================================ cache disque et préparation

static func _layer_key(ld: Dictionary) -> String:
	var kind := str(ld.get("kind", "mountain"))
	var res := maxi(1, int(ld.get("res", 1)))
	var cw := int(ld.get("w", 1200))
	return "%s|%s|%d|%s|%s|%s|%s|%d|%s|%s|%s|%s" % [kind, str(ld.get("seed", 1)), res, str(ld.get("off", 0)), str(ld.get("tiers", 5)), str(ld.get("peak", 0.9)), str(ld.get("fires", 12)), cw, str(ld.get("haze", "")), str(ld.get("scale", 1.0)), str(ld.get("trees", 1)), str(ld.get("tower", true))]


## Empreinte du peintre : le code source quand il est disponible (développement), sinon la version.
static func _painter_stamp() -> String:
	if _stamp == "":
		var src := (Layers as GDScript).source_code
		_stamp = "%d_%d" % [CACHE_VERSION, hash(src) if src != "" else 0]
	return _stamp


static func _cache_path(key: String) -> String:
	return "%s/%s_%s" % [CACHE_DIR, str(hash(key)), _painter_stamp()]


## Image (déjà réduite) et foyers d'un plan : lus sur le disque s'ils y sont, sinon peints puis écrits.
## Sûr à appeler depuis un fil : n'utilise que le verrou et les statiques du peintre sous ce verrou.
static func _layer_data(key: String, ld: Dictionary) -> Dictionary:
	var path := _cache_path(key)
	if FileAccess.file_exists(path + ".png") and FileAccess.file_exists(path + ".json"):
		var img := Image.load_from_file(path + ".png")
		var f := FileAccess.open(path + ".json", FileAccess.READ)
		if img != null and not img.is_empty() and f != null:
			var parsed: Variant = JSON.parse_string(f.get_as_text())
			if parsed is Array:
				var fires: Array = []
				for e: Variant in parsed:
					fires.append(Vector2(float((e as Array)[0]), float((e as Array)[1])))
				return {"img": img, "fires": fires}
	var res := maxi(1, int(ld.get("res", 1)))
	var cw := int(ld.get("w", 1200))
	_paint_lock.lock()
	var painted := Layers.paint(str(ld.get("kind", "mountain")), int(ld.get("seed", 1)), ld)
	var fl: Array = Layers.fires.duplicate()
	_paint_lock.unlock()
	if res > 1:
		painted.resize(cw / res, 360 / res, Image.INTERPOLATE_BILINEAR)
	DirAccess.make_dir_recursive_absolute(CACHE_DIR)
	painted.save_png(path + ".png")
	var out: Array = []
	for v: Vector2 in fl:
		out.append([v.x, v.y])
	var wf := FileAccess.open(path + ".json", FileAccess.WRITE)
	if wf != null:
		wf.store_string(JSON.stringify(out))
	return {"img": painted, "fires": fl}


## Prépare en arrière-plan le cache disque des plans des cartes données (identifiants), pour que leur
## entrée ne paie aucune peinture. Ne touche ni à la scène ni aux textures : seulement des fichiers.
static func prepare(map_ids: Array) -> void:
	var todo: Array = []
	for id: Variant in map_ids:
		if not _prep_done.has(id):
			_prep_done.append(id)
			todo.append(str(id))
	if todo.is_empty() or (_prep_thread != null and _prep_thread.is_alive()):
		return
	if _prep_thread != null:
		_prep_thread.wait_to_finish()
	_prep_thread = Thread.new()
	_prep_thread.start(_prepare_job.bind(todo))


static func _prepare_job(ids: Array) -> void:
	for id: Variant in ids:
		var f := FileAccess.open("res://data/maps/%s.json" % str(id), FileAccess.READ)
		if f == null:
			continue
		var map: Variant = JSON.parse_string(f.get_as_text())
		if not (map is Dictionary) or not ((map as Dictionary).get("horizon") is Dictionary):
			continue
		var cfg := _config((map as Dictionary)["horizon"] as Dictionary)
		for ld: Variant in cfg.get("layers", []):
			_layer_data(_layer_key(ld as Dictionary), ld as Dictionary)


static func _config(spec: Dictionary) -> Dictionary:
	var cfg: Dictionary = (PRESETS.get(str(spec.get("preset", "cite")), PRESETS["cite"]) as Dictionary).duplicate(true)
	for key: String in spec:
		cfg[key] = spec[key]
	return cfg


## Attend la fin de la préparation (utile aux tests et à la fermeture).
static func finish_prepare() -> void:
	if _prep_thread != null:
		_prep_thread.wait_to_finish()
		_prep_thread = null
