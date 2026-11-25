extends Node
## Réglages du joueur : affichage, rendu, détails, son. Autoload `Settings`.
## Ils vivent dans `user://settings.cfg` (ConfigFile), à part des sauvegardes, et s'appliquent
## tout de suite. Les valeurs par défaut redonnent exactement le rendu d'origine du jeu.
## Format et clés : voir docs/FORMAT_DONNEES.md. Un fichier illisible ou une valeur inconnue
## n'est jamais une erreur : on retombe sur le défaut.
##
## Les scènes créées après coup (monde, arène) appellent `apply_environment`, `apply_camera`,
## `apply_light`, `apply_particles` et `apply_rays` : l'objet est réglé, puis retenu (sans le
## garder en vie) pour suivre les changements faits ensuite dans l'écran « Paramètres ».

const FILE := "user://settings.cfg"
const BUS_MUSIC := "Musique"
const BUS_EFFECTS := "Effets"

## Clé -> [rubrique du fichier, valeur par défaut]
const DEFAULTS: Dictionary = {
	"mode": ["affichage", "fenetre"],
	"taille": ["affichage", "1600x900"],
	"vsync": ["affichage", true],
	"fps_max": ["affichage", 0],
	"echelle": ["rendu", 100],
	"mise_echelle": ["rendu", "bilineaire"],
	"nettete": ["rendu", 9],
	"anticrenelage": ["rendu", "msaa2"],
	"qualite": ["details", "moyenne"],
	"ombres": ["details", 2],
	"flou": ["details", 2],
	"halo": ["details", true],
	"brume": ["details", 2],
	"occlusion": ["details", 2],
	"particules": ["details", 2],
	"rayons": ["details", true],
	"general": ["son", 100],
	"musique": ["son", 100],
	"effets": ["son", 100],
	"sons": ["son", "enregistres"],
	"compteur": ["divers", false],
	"conseils": ["divers", true],
	"repere": ["divers", true],
	"vibration": ["manette", true],
	"difficulte": ["jeu", "aventure"],
}

## Réglages fins pilotés par la « Qualité ». Moyenne = le rendu d'origine.
const PRESETS: Dictionary = {
	"basse": {"ombres": 1, "flou": 1, "halo": false, "brume": 1, "occlusion": 0, "particules": 1, "rayons": false},
	"moyenne": {"ombres": 2, "flou": 2, "halo": true, "brume": 2, "occlusion": 2, "particules": 2, "rayons": true},
	"haute": {"ombres": 3, "flou": 3, "halo": true, "brume": 3, "occlusion": 3, "particules": 2, "rayons": true},
}

const SIZES := ["1280x720", "1600x900", "1920x1080", "2560x1440"]
const FACTORS := [0.0, 0.4, 1.0]    # densité des particules : aucune, réduite, normale

## Écran « Paramètres » : ordre des lignes (section = titre de rubrique).
const ROWS: Array = [
	{"section": "Affichage"},
	{"id": "mode", "label": "Mode d'affichage"},
	{"id": "taille", "label": "Taille de la fenêtre"},
	{"id": "vsync", "label": "Synchronisation verticale"},
	{"id": "fps_max", "label": "Limite d'images par seconde"},
	{"section": "Rendu"},
	{"id": "echelle", "label": "Échelle de rendu 3D", "gauge": true},
	{"id": "mise_echelle", "label": "Méthode de mise à l'échelle"},
	{"info": "DLSS", "text": "indisponible sur ce matériel"},
	{"id": "nettete", "label": "Netteté (FSR 1)"},
	{"id": "anticrenelage", "label": "Anticrénelage (bords lissés)"},
	{"section": "Détails"},
	{"id": "qualite", "label": "Qualité"},
	{"id": "ombres", "label": "Ombres"},
	{"id": "flou", "label": "Flou de profondeur"},
	{"id": "halo", "label": "Halo lumineux"},
	{"id": "brume", "label": "Brume"},
	{"id": "occlusion", "label": "Occlusion ambiante"},
	{"id": "particules", "label": "Particules (lucioles, feuilles...)"},
	{"id": "rayons", "label": "Rayons de lumière"},
	{"section": "Son"},
	{"id": "general", "label": "Volume général", "gauge": true},
	{"id": "musique", "label": "Musique", "gauge": true},
	{"id": "effets", "label": "Effets sonores", "gauge": true},
	{"id": "sons", "label": "Sons de l'interface et des coups"},
	{"section": "Divers"},
	{"id": "compteur", "label": "Compteur d'images par seconde"},
	{"section": "Jeu"},
	{"id": "difficulte", "label": "Difficulté"},
	{"section": "Aide au jeu"},
	{"id": "conseils", "label": "Conseils de jeu"},
	{"id": "repere", "label": "Repère de quête"},
	{"action": "revoir", "label": "Revoir les conseils"},
	{"section": "Manette"},
	{"id": "vibration", "label": "Vibration de la manette"},
	{"action": "manette", "label": "Diagnostic de la manette"},
]

const HELP: Dictionary = {
	"mode": "Fenêtre, plein écran, ou fenêtre sans bord qui couvre tout l'écran. La touche F bascule aussi.",
	"taille": "La taille de la fenêtre. Sans effet en plein écran.",
	"vsync": "Cale l'image sur l'écran : plus de déchirures, un peu plus de délai.",
	"fps_max": "Plafonne le nombre d'images par seconde : plus bas, c'est plus sobre pour l'ordinateur.",
	"echelle": "Dessine le monde en 3D à une taille réduite puis l'étire : moins net, mais bien plus rapide. Les menus restent nets.",
	"mise_echelle": "Comment l'image réduite est étirée. « Au plus proche » garde les pixels bien carrés ; FSR et MetalFX reconstruisent plus de détails.",
	"nettete": "Renforce la netteté de l'image étirée. Ne joue qu'avec FSR 1 et une échelle sous 100 %.",
	"anticrenelage": "Adoucit les escaliers sur les bords. Aucun garde les pixels les plus francs ; TAA et MSAA x4 sont plus doux.",
	"qualite": "Règle d'un coup les détails ci-dessous. Les changer à la main passe en Personnalisée.",
	"ombres": "Ombres du soleil et des lampes : finesse et nombre de zones calculées.",
	"flou": "Le flou « maquette » devant et derrière le héros. Le couper rend l'image plus nette et plus rapide.",
	"halo": "Le halo doux autour des lumières vives (lanternes, feu, magie).",
	"brume": "Le brouillard : léger, normal, ou fin avec rayons dans la brume.",
	"occlusion": "Les coins et les creux s'assombrissent un peu, ce qui donne du relief.",
	"particules": "Lucioles, feuilles, poussières, flammèches : leur nombre.",
	"rayons": "Les rayons de soleil obliques dans les sous-bois.",
	"general": "Le volume de tout le jeu.",
	"musique": "Le volume de la musique.",
	"effets": "Le volume des bruitages.",
	"sons": "Enregistrés : de vrais bruitages pour les menus, les coups et les portes. Synthétisés : les sons fabriqués par le jeu lui-même, comme avant. La magie, les soins, le feu et les cris restent synthétisés dans les deux cas.",
	"compteur": "Affiche discrètement le nombre d'images par seconde dans un coin.",
	"repere": "Une petite marque dorée au-dessus de ce que vise l'étape de quête en cours, et le sens à prendre quand c'est dans une autre carte.",
	"vibration": "Une légère vibration de la manette quand un coup est reçu, sur un coup critique et à la victoire. Sans effet sans manette.",
	"difficulte": "Se change à tout moment, et vaut dès le prochain combat.",
	"conseils": "Explique chaque système une seule fois, au moment où il sert. Les conseils déjà vus restent relisibles dans Pause, « Aide ».",
}

const SCALE_MODES: Dictionary = {
	"bilineaire": 0, "fsr1": 1, "fsr2": 2, "metalfx_spatial": 3, "metalfx_temporel": 4, "plus_proche": 5,
}

var values: Dictionary = {}          # clé -> valeur courante
var path := FILE
var persist := true                  # faux pour les tests et les captures : rien n'est lu ni écrit
var testing := false

var _reg: Array = []                 # WeakRef des objets déjà réglés
var _applied_size := "1600x900"      # dernière taille de fenêtre demandée
var _applied_mode := "fenetre"
var _counter_layer: CanvasLayer = null
var _counter: Label = null
var _counter_time := 0.0
var _headless := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_headless = DisplayServer.get_name() == "headless"
	for arg: String in OS.get_cmdline_args():
		if arg.contains("tests/"):
			testing = true
	# Les tests et les captures tournent toujours avec les valeurs par défaut, sans lire
	# ni écrire le fichier de l'auteur.
	if testing:
		persist = false
	reset_values()
	if persist:
		load_file()
	_ensure_buses()
	apply_all()


func _process(delta: float) -> void:
	if _counter == null or not _counter_layer.visible:
		return
	_counter_time += delta
	if _counter_time >= 0.5:
		_counter_time = 0.0
		_counter.text = "%d i/s" % int(Engine.get_frames_per_second())


# ---------------------------------------------------------------- valeurs

func reset_values() -> void:
	values = {}
	for k: String in DEFAULTS:
		values[k] = (DEFAULTS[k] as Array)[1]


func default_of(id: String) -> Variant:
	return (DEFAULTS[id] as Array)[1] if DEFAULTS.has(id) else null


func get_value(id: String) -> Variant:
	return values.get(id, default_of(id))


## Remet tous les réglages à leur défaut (et les applique).
func reset_defaults() -> void:
	reset_values()
	apply_all()


## Change un réglage et l'applique. Une valeur inconnue est refusée (renvoie faux).
func set_value(id: String, value: Variant, apply: bool = true) -> bool:
	if not DEFAULTS.has(id) or not _valid(id, value):
		return false
	values[id] = value
	if PRESETS["moyenne"].has(id):
		values["qualite"] = _matching_preset()
	if id == "qualite" and PRESETS.has(value):
		for k: String in (PRESETS[value] as Dictionary):
			values[k] = (PRESETS[value] as Dictionary)[k]
	if apply:
		apply_all()
	return true


func _matching_preset() -> String:
	for name: String in PRESETS:
		var same := true
		for k: String in (PRESETS[name] as Dictionary):
			if values.get(k) != (PRESETS[name] as Dictionary)[k]:
				same = false
				break
		if same:
			return name
	return "perso"


## Options d'un réglage : [[valeur, libellé], ...]
func choices(id: String) -> Array:
	match id:
		"mode":
			return [["fenetre", "Fenêtre"], ["plein_ecran", "Plein écran"], ["sans_bord", "Fenêtre sans bord"]]
		"taille":
			return SIZES.map(func(s: String) -> Array: return [s, s.replace("x", " × ")])
		"vsync", "halo", "rayons", "compteur", "conseils", "repere", "vibration":
			return [[false, "Non"], [true, "Oui"]]
		"fps_max":
			return [[30, "30"], [60, "60"], [120, "120"], [0, "Sans limite"]]
		"echelle":
			return [[50, "50 %"], [60, "60 %"], [70, "70 %"], [80, "80 %"], [90, "90 %"], [100, "100 %"]]
		"mise_echelle":
			var out: Array = [["bilineaire", "Bilinéaire"], ["plus_proche", "Au plus proche (pixels francs)"],
					["fsr1", "FSR 1"], ["fsr2", "FSR 2"]]
			if metalfx_spatial_available():
				out.append(["metalfx_spatial", "MetalFX spatial"])
			if metalfx_temporal_available():
				out.append(["metalfx_temporel", "MetalFX temporel"])
			return out
		"nettete":
			return range(0, 11).map(func(i: int) -> Array: return [i, "%d / 10" % i])
		"anticrenelage":
			return [["aucun", "Aucun"], ["fxaa", "FXAA"], ["smaa", "SMAA"], ["taa", "TAA"], ["msaa2", "MSAA x2"], ["msaa4", "MSAA x4"]]
		"qualite":
			return [["basse", "Basse"], ["moyenne", "Moyenne"], ["haute", "Haute"], ["perso", "Personnalisée"]]
		"ombres":
			return [[0, "Aucune"], [1, "Basses"], [2, "Moyennes"], [3, "Hautes"]]
		"flou":
			return [[0, "Aucun"], [1, "Basse qualité"], [2, "Moyenne"], [3, "Haute qualité"]]
		"brume":
			return [[0, "Aucune"], [1, "Légère"], [2, "Normale"], [3, "Fine"]]
		"occlusion":
			return [[0, "Aucune"], [1, "Basse"], [2, "Moyenne"], [3, "Haute"]]
		"particules":
			return [[0, "Aucune"], [1, "Réduites"], [2, "Normales"]]
		"difficulte":
			return [["promenade", "Promenade"], ["aventure", "Aventure"], ["epreuve", "Épreuve"]]
		"sons":
			return [["enregistres", "Enregistrés"], ["synthetises", "Synthétisés"]]
		"general", "musique", "effets":
			return range(0, 11).map(func(i: int) -> Array: return [i * 10, "%d %%" % (i * 10)])
	return []


func _valid(id: String, value: Variant) -> bool:
	for c: Array in choices(id):
		if typeof(c[0]) == typeof(value) and c[0] == value:
			return true
	return false


func value_label(id: String) -> String:
	var v: Variant = get_value(id)
	for c: Array in choices(id):
		if typeof(c[0]) == typeof(v) and c[0] == v:
			return str(c[1])
	return str(v)


func help(id: String) -> String:
	var text := str(HELP.get(id, ""))
	if id == "difficulte":   # le texte vient des données (data/carnet.json), un niveau après l'autre
		for lvl: String in ["promenade", "aventure", "epreuve"]:
			var d: Dictionary = (Database.carnet.get("difficulties", {}) as Dictionary).get(lvl, {})
			text += "\n%s : %s" % [str(d.get("name", lvl)), str(d.get("desc", ""))]
		return Tutorial.expand(text)
	if Controls.pad:
		text = text.replace(" La touche F bascule aussi.", "")   # une touche du clavier ne dit rien à la manette
	var note := _note(id)
	return text if note == "" else text + "  (" + note + ")"


func _note(id: String) -> String:
	var mode := str(get_value("mise_echelle"))
	match id:
		"nettete":
			if mode != "fsr1":
				return "inactif : choisissez FSR 1"
		"anticrenelage":
			if mode in ["fsr2", "metalfx_temporel"]:
				return "inactif : cette méthode lisse déjà l'image"
		"taille":
			if str(get_value("mode")) != "fenetre":
				return "inactif hors du mode fenêtre"
		"mise_echelle":
			if int(get_value("echelle")) >= 100 and mode != "bilineaire":
				return "sans effet à 100 %"
	return ""


## Vrai si la ligne n'a aucun effet pour l'instant (affichée en grisé).
func is_inert(id: String) -> bool:
	return _note(id) != "" and id != "mise_echelle"


func metalfx_spatial_available() -> bool:
	var rd := RenderingServer.get_rendering_device()
	return rd != null and OS.get_name() == "macOS" and rd.has_feature(RenderingDevice.SUPPORTS_METALFX_SPATIAL)


func metalfx_temporal_available() -> bool:
	var rd := RenderingServer.get_rendering_device()
	return rd != null and OS.get_name() == "macOS" and rd.has_feature(RenderingDevice.SUPPORTS_METALFX_TEMPORAL)


# ------------------------------------------------------------ fichier

## Lit le fichier. Renvoie vrai s'il a été lu ; sinon, ou si une valeur est inconnue,
## les défauts restent en place pour ce qui manque.
func load_file() -> bool:
	reset_values()
	if not _looks_like_cfg(path):
		return false   # absent ou abîmé : on ne le donne pas à ConfigFile, qui s'en plaindrait dans la console
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return false
	for k: String in DEFAULTS:
		var section := str((DEFAULTS[k] as Array)[0])
		if cfg.has_section_key(section, k):
			var v: Variant = cfg.get_value(section, k, null)
			if _valid(k, v):
				values[k] = v
	# la qualité inscrite doit rester cohérente avec les réglages fins
	if not _valid("qualite", values["qualite"]):
		values["qualite"] = _matching_preset()
	elif values["qualite"] != "perso" and PRESETS.has(values["qualite"]):
		if _matching_preset() != values["qualite"]:
			values["qualite"] = _matching_preset()
	return true


## Le fichier a-t-il la forme d'un fichier de réglages (lignes « [section] » ou « clé=valeur » ) ?
func _looks_like_cfg(file: String) -> bool:
	if not FileAccess.file_exists(file):
		return false
	var bytes := FileAccess.get_file_as_bytes(file)
	if bytes.has(0):
		return false
	var text := bytes.get_string_from_utf8()
	var line_re := RegEx.new()
	line_re.compile("^(\\[[A-Za-z0-9_./ -]+\\]|[A-Za-z0-9_./-]+ *=.*)$")
	for line: String in text.split("\n"):
		var l := line.strip_edges()
		if l == "" or l.begins_with(";"):
			continue
		if line_re.search(l) == null:
			return false
	return true


func save() -> bool:
	if not persist:
		return false
	var cfg := ConfigFile.new()
	for k: String in DEFAULTS:
		cfg.set_value(str((DEFAULTS[k] as Array)[0]), k, get_value(k))
	return cfg.save(path) == OK


# ------------------------------------------------------------ application

func apply_all() -> void:
	_apply_display()
	_apply_render()
	_apply_global_details()
	_apply_audio()
	_apply_counter()
	var alive: Array = []
	for r: WeakRef in _reg:
		var o: Variant = r.get_ref()
		if o != null:
			_apply_object(o)
			alive.append(r)
	_reg = alive


func toggle_fullscreen() -> void:
	values["mode"] = "fenetre" if str(get_value("mode")) != "fenetre" else "plein_ecran"
	apply_all()
	save()


func _apply_display() -> void:
	Engine.max_fps = int(get_value("fps_max"))
	if not _headless:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(get_value("vsync")) else DisplayServer.VSYNC_DISABLED)
	else:
		return
	var mode := str(get_value("mode"))
	var size_text := str(get_value("taille"))
	if mode == _applied_mode and size_text == _applied_size:
		return   # rien à changer côté fenêtre
	match mode:
		"plein_ecran":
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"sans_bord":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			var screen := DisplayServer.window_get_current_screen()
			DisplayServer.window_set_size(DisplayServer.screen_get_size(screen))
			DisplayServer.window_set_position(DisplayServer.screen_get_position(screen))
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			if size_text != _applied_size or _applied_mode != "fenetre":
				# macOS finit d'abord sa transition (plein écran, bord) : on dimensionne juste après
				get_tree().create_timer(0.4).timeout.connect(_resize_window)
	_applied_mode = mode
	_applied_size = size_text


## Donne à la fenêtre la taille choisie (mode fenêtre seulement), centrée sur l'écran.
func _resize_window() -> void:
	if str(get_value("mode")) != "fenetre" or DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)   # macOS peut avoir « agrandi » la fenêtre
	var parts := str(get_value("taille")).split("x")
	var want := Vector2i(int(parts[0]), int(parts[1]))
	var screen := DisplayServer.window_get_current_screen()
	var area := DisplayServer.screen_get_usable_rect(screen)
	want = Vector2i(mini(want.x, area.size.x), mini(want.y, area.size.y))
	DisplayServer.window_set_size(want)
	DisplayServer.window_set_position(area.position + (area.size - want) / 2)


func _apply_render() -> void:
	var vp := get_tree().root
	var mode := str(get_value("mise_echelle"))
	var scale := float(int(get_value("echelle"))) / 100.0
	vp.scaling_3d_mode = int(SCALE_MODES.get(mode, 0)) as Viewport.Scaling3DMode
	vp.scaling_3d_scale = scale
	vp.fsr_sharpness = 2.0 * float(10 - int(get_value("nettete"))) / 10.0
	vp.msaa_3d = Viewport.MSAA_DISABLED
	vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	vp.use_taa = false
	if mode in ["fsr2", "metalfx_temporel"]:
		return   # ces méthodes lissent elles-mêmes l'image
	match str(get_value("anticrenelage")):
		"fxaa": vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		"smaa": vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_SMAA
		"taa": vp.use_taa = true
		"msaa2": vp.msaa_3d = Viewport.MSAA_2X
		"msaa4": vp.msaa_3d = Viewport.MSAA_4X


## Réglages qui valent pour tout le rendu (pas pour un objet en particulier).
func _apply_global_details() -> void:
	var shadows := int(get_value("ombres"))
	var atlas: int = [2048, 2048, 4096, 8192][shadows]
	var filter: int = [RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM, RenderingServer.SHADOW_QUALITY_SOFT_LOW,
			RenderingServer.SHADOW_QUALITY_SOFT_MEDIUM, RenderingServer.SHADOW_QUALITY_SOFT_HIGH][shadows]
	RenderingServer.directional_shadow_atlas_set_size(atlas, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(filter as RenderingServer.ShadowQuality)
	RenderingServer.positional_soft_shadow_filter_set_quality(filter as RenderingServer.ShadowQuality)
	get_tree().root.positional_shadow_atlas_size = atlas
	var blur := clampi(int(get_value("flou")), 1, 3)
	RenderingServer.camera_attributes_set_dof_blur_quality(blur as RenderingServer.DOFBlurQuality, false)
	var fog := int(get_value("brume"))
	var fog_size: int = [64, 64, 64, 128][fog]
	var fog_depth: int = [64, 64, 64, 96][fog]
	RenderingServer.environment_set_volumetric_fog_volume_size(fog_size, fog_depth)
	var ao := int(get_value("occlusion"))
	var ao_quality: int = [RenderingServer.ENV_SSAO_QUALITY_MEDIUM, RenderingServer.ENV_SSAO_QUALITY_LOW,
			RenderingServer.ENV_SSAO_QUALITY_MEDIUM, RenderingServer.ENV_SSAO_QUALITY_HIGH][ao]
	RenderingServer.environment_set_ssao_quality(ao_quality as RenderingServer.EnvironmentSSAOQuality, ao != 3, 0.5, 2, 50.0, 300.0)


func _ensure_buses() -> void:
	for bus_name: String in [BUS_MUSIC, BUS_EFFECTS]:
		if AudioServer.get_bus_index(bus_name) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus_name)
			AudioServer.set_bus_send(i, "Master")


func _apply_audio() -> void:
	_ensure_buses()
	_set_bus("Master", int(get_value("general")))
	_set_bus(BUS_MUSIC, int(get_value("musique")))
	_set_bus(BUS_EFFECTS, int(get_value("effets")))


func _set_bus(bus_name: String, percent: int) -> void:
	var i := AudioServer.get_bus_index(bus_name)
	if i == -1:
		return
	AudioServer.set_bus_mute(i, percent <= 0)
	AudioServer.set_bus_volume_db(i, linear_to_db(maxf(0.0001, float(percent) / 100.0)))


func _apply_counter() -> void:
	if _counter_layer == null:
		if not bool(get_value("compteur")):
			return
		_counter_layer = CanvasLayer.new()
		_counter_layer.layer = 100
		add_child(_counter_layer)
		_counter = Label.new()
		_counter.add_theme_font_size_override("font_size", 15)
		_counter.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
		_counter.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		_counter.add_theme_constant_override("outline_size", 4)
		_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_counter.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT, Control.PRESET_MODE_MINSIZE, 12)
		_counter.grow_horizontal = Control.GROW_DIRECTION_BEGIN
		_counter.text = "-- i/s"
		_counter_layer.add_child(_counter)
	_counter_layer.visible = bool(get_value("compteur"))


# -------------------------------------------- objets réglés à leur création

func apply_environment(env: Environment) -> void:
	_track(env)


func apply_camera(attr: CameraAttributes) -> void:
	_track(attr)


func apply_light(light: Light3D) -> void:
	_track(light)


func apply_particles(p: CPUParticles3D) -> void:
	_track(p)


func apply_rays(node: Node3D) -> void:
	_track(node)


func _track(o: Object) -> void:
	_apply_object(o)
	for r: WeakRef in _reg:
		if r.get_ref() == o:
			return
	_reg.append(weakref(o))


func _apply_object(o: Object) -> void:
	if o is Environment:
		var env := o as Environment
		if not env.has_meta("base"):
			env.set_meta("base", {"glow": env.glow_enabled, "fog": env.fog_enabled,
					"vol": env.volumetric_fog_enabled, "ssao": env.ssao_enabled})
		var base: Dictionary = env.get_meta("base")
		env.glow_enabled = bool(base["glow"]) and bool(get_value("halo"))
		env.fog_enabled = bool(base["fog"]) and int(get_value("brume")) >= 1
		env.volumetric_fog_enabled = bool(base["vol"]) and int(get_value("brume")) >= 2
		env.ssao_enabled = bool(base["ssao"]) and int(get_value("occlusion")) > 0
	elif o is CameraAttributesPractical:
		var attr := o as CameraAttributesPractical
		if not attr.has_meta("base"):
			attr.set_meta("base", {"far": attr.dof_blur_far_enabled, "near": attr.dof_blur_near_enabled})
		var base: Dictionary = attr.get_meta("base")
		var on := int(get_value("flou")) > 0
		attr.dof_blur_far_enabled = bool(base["far"]) and on
		attr.dof_blur_near_enabled = bool(base["near"]) and on
	elif o is Light3D:
		var light := o as Light3D
		if not light.has_meta("base"):
			var mode := (light as DirectionalLight3D).directional_shadow_mode if light is DirectionalLight3D else 0
			light.set_meta("base", {"shadow": light.shadow_enabled, "mode": mode})
		var base: Dictionary = light.get_meta("base")
		var level := int(get_value("ombres"))
		light.shadow_enabled = bool(base["shadow"]) and level > 0
		if light is DirectionalLight3D:
			(light as DirectionalLight3D).directional_shadow_mode = (DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS if level == 1 \
					else int(base["mode"])) as DirectionalLight3D.ShadowMode
	elif o is CPUParticles3D:
		var p := o as CPUParticles3D
		if not p.has_meta("base_amount"):
			p.set_meta("base_amount", p.amount)
		var factor: float = FACTORS[clampi(int(get_value("particules")), 0, 2)]
		var amount := maxi(1, int(round(float(p.get_meta("base_amount")) * factor)))
		if p.amount != amount:
			p.amount = amount
		p.visible = factor > 0.0
	elif o is Node3D:
		(o as Node3D).visible = bool(get_value("rayons"))
