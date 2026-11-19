extends Node
## Déclare toutes les commandes du jeu par code : rien à régler dans l'éditeur.
## Les touches de déplacement utilisent les touches PHYSIQUES W/A/S/D,
## ce qui donne Z/Q/S/D sur un clavier AZERTY.

const DEADZONE := 0.35

## Dernier périphérique utilisé : les rappels de touches de l'interface s'y adaptent.
var pad := false

signal device_changed(is_pad: bool)
## Message à montrer à l'écran (connexion, débranchement) : main.gd le relaie au bandeau de notifications.
signal notice(text: String)
signal pads_changed

const NAV := ["ui_up", "ui_down", "ui_left", "ui_right"]
const REPEAT_FIRST := 0.4     # secondes avant la première répétition
const REPEAT_EVERY := 0.12    # puis un pas toutes les ...
const REPORT_FILE := "user://manette.txt"
const BUTTON_NAMES := ["A", "B", "X", "Y", "Retour (View)", "Guide", "Start (Menu)", "Stick gauche (clic)", "Stick droit (clic)", "LB", "RB", "Croix haut", "Croix bas", "Croix gauche", "Croix droite"]
const AXIS_NAMES := ["Stick gauche horizontal", "Stick gauche vertical", "Stick droit horizontal", "Stick droit vertical", "Gâchette gauche (LT)", "Gâchette droite (RT)"]
## Disposition « Xbox » la plus répandue, en format SDL : sert de repli pour une manette que Godot ne connaît pas.
const GENERIC_MAPPING := "a:b0,b:b1,x:b2,y:b3,back:b6,start:b7,leftstick:b8,rightstick:b9,leftshoulder:b4,rightshoulder:b5,leftx:a0,lefty:a1,rightx:a2,righty:a3,lefttrigger:a4,righttrigger:a5,dpup:h0.1,dpright:h0.2,dpdown:h0.4,dpleft:h0.8"
const WATCHED := ["move_left", "move_right", "move_up", "move_down", "interact", "cancel", "menu", "journal", "delete", "ui_accept", "ui_cancel", "ui_up", "ui_down", "ui_left", "ui_right"]

var report_path := REPORT_FILE
var raw_count := 0               ## événements bruts de manette vus (boutons, et axes au-delà du bruit)
var last_button: Dictionary = {}  ## {"device", "index", "pressed"}
var last_axis: Dictionary = {}    ## {"device", "axis", "value"}
var polled_press := false         ## un bouton vu par sondage direct (Input.is_joy_button_pressed)
var generic_mapped: Array = []    ## numéros de manettes auxquelles on a posé le mapping de repli
var _pending: Array = []          ## messages émis avant que l'écran puisse les montrer
var _noted: InputEvent = null
var _held: Dictionary = {}
var _known_before: Dictionary = {}


func _ready() -> void:
	# Le jeu lancé depuis un terminal ou un .bat n'a pas toujours le focus : on ne coupe jamais la manette pour ça.
	Input.set_ignore_joypad_on_unfocused_application(false)
	Input.joy_connection_changed.connect(handle_connection)
	_action("move_left", [KEY_LEFT], [KEY_A], [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_action("move_right", [KEY_RIGHT], [KEY_D], [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_action("move_up", [KEY_UP], [KEY_W], [JOY_BUTTON_DPAD_UP], JOY_AXIS_LEFT_Y, -1.0)
	_action("move_down", [KEY_DOWN], [KEY_S], [JOY_BUTTON_DPAD_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_action("interact", [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE], [KEY_E], [JOY_BUTTON_A])
	_action("cancel", [KEY_BACKSPACE], [KEY_X], [JOY_BUTTON_B])
	_action("menu", [KEY_ESCAPE, KEY_TAB, KEY_M], [], [JOY_BUTTON_START])
	_action("journal", [KEY_J], [], [JOY_BUTTON_Y])   # ouvre le journal de quêtes d'un geste
	_action("fullscreen", [KEY_F11, KEY_F], [], [])
	_action("delete", [KEY_DELETE], [], [JOY_BUTTON_X])   # effacer (écran des sauvegardes)
	# Navigation dans les menus : on complète les actions intégrées de Godot.
	_extend_physical("ui_up", KEY_W)
	_extend_physical("ui_down", KEY_S)
	_extend_physical("ui_left", KEY_A)
	_extend_physical("ui_right", KEY_D)
	_extend_physical("ui_accept", KEY_E)
	# Manette dans les menus : A valide, B annule, croix et stick gauche déplacent le curseur,
	# quel que soit le numéro de la manette.
	_extend_pad("ui_accept", JOY_BUTTON_A)
	_extend_pad("ui_cancel", JOY_BUTTON_B)
	_extend_pad("ui_up", JOY_BUTTON_DPAD_UP, JOY_AXIS_LEFT_Y, -1.0)
	_extend_pad("ui_down", JOY_BUTTON_DPAD_DOWN, JOY_AXIS_LEFT_Y, 1.0)
	_extend_pad("ui_left", JOY_BUTTON_DPAD_LEFT, JOY_AXIS_LEFT_X, -1.0)
	_extend_pad("ui_right", JOY_BUTTON_DPAD_RIGHT, JOY_AXIS_LEFT_X, 1.0)
	_extend_pad("ui_page_up", JOY_BUTTON_LEFT_SHOULDER)
	_extend_pad("ui_page_down", JOY_BUTTON_RIGHT_SHOULDER)
	# Back / View ouvre le journal, comme Y.
	var back := InputEventJoypadButton.new()
	back.device = -1
	back.button_index = JOY_BUTTON_BACK
	InputMap.action_add_event("journal", back)
	# Manettes déjà branchées au lancement : Godot les signale parfois avant que nous écoutions.
	for d: int in Input.get_connected_joypads():
		_register(d, true)
	print_boot_info()
	call_deferred("write_report")


## Une ligne de journal au lancement : version, système, manettes. jouer.bat peut l'afficher.
func print_boot_info() -> void:
	var ver: Dictionary = Engine.get_version_info()
	print("[manette] Godot %s, %s %s, vidéo %s" % [str(ver.get("string", "?")), OS.get_name(), OS.get_version(), DisplayServer.get_name()])
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		print("[manette] aucune manette vue au lancement")
	for d: int in pads:
		print("[manette] %d : %s, GUID %s, connue : %s" % [d, Input.get_joy_name(d), Input.get_joy_guid(d), "oui" if Input.is_joy_known(d) else "non"])


## Connexion ou débranchement (signal de Godot ; les tests l'appellent directement).
func handle_connection(device: int, connected: bool) -> void:
	var name := _pad_label(device) if connected else str(_known_before.get(device, "Manette"))
	_register(device, connected)
	if connected:
		print("[manette] connectée : %d, %s" % [device, name])
		_say("Manette détectée : %s" % name)
		set_pad(true)
	else:
		print("[manette] débranchée : %d, %s" % [device, name])
		_say("Manette débranchée")
		if Input.get_connected_joypads().is_empty():
			set_pad(false)
	pads_changed.emit()
	write_report()


func _register(device: int, connected: bool) -> void:
	if not connected:
		generic_mapped.erase(device)
		return
	_known_before[device] = _pad_label(device)
	# Manette inconnue de la base : on lui pose le mapping « Xbox » générique (format SDL, avec son GUID),
	# comme le recommande la documentation de Godot pour une manette mal reconnue.
	if not Input.is_joy_known(device):
		var guid := Input.get_joy_guid(device)
		if guid != "":
			var platform := {"Windows": "Windows", "macOS": "Mac OS X", "Linux": "Linux"}.get(OS.get_name(), "Windows") as String
			Input.add_joy_mapping("%s,%s,%s,platform:%s" % [guid, Input.get_joy_name(device), GENERIC_MAPPING, platform], true)
			generic_mapped.append(device)


func _pad_label(device: int) -> String:
	var n := Input.get_joy_name(device)
	return n if n != "" else "manette %d" % device


func _say(text: String) -> void:
	_pending.append(text)
	notice.emit(text)


## Messages arrivés avant que l'écran existe (manette branchée au lancement) : donnés une seule fois.
func take_pending() -> Array:
	var out := _pending.duplicate()
	_pending.clear()
	return out


## Vibration légère : « hit » coup reçu, « crit » coup critique, « victory » victoire. Sans effet sans manette.
func rumble(kind: String) -> void:
	if not bool(Settings.get_value("vibration")):
		return
	var weak := 0.3
	var strong := 0.4
	var time := 0.18
	match kind:
		"crit":
			weak = 0.6
			strong = 0.8
			time = 0.3
		"victory":
			weak = 0.4
			strong = 0.25
			time = 0.5
	for d: int in Input.get_connected_joypads():
		Input.start_joy_vibration(d, weak, strong, time)


func note_event(event: InputEvent) -> void:
	if event == _noted:
		return
	if event is InputEventJoypadButton:
		_noted = event
		raw_count += 1
		var b := event as InputEventJoypadButton
		last_button = {"device": b.device, "index": int(b.button_index), "pressed": b.pressed}
	elif event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.2:
		_noted = event
		raw_count += 1
		var m := event as InputEventJoypadMotion
		last_axis = {"device": m.device, "axis": int(m.axis), "value": m.axis_value}


func _process(delta: float) -> void:
	for d: int in Input.get_connected_joypads():
		for b in 15:
			if Input.is_joy_button_pressed(d, b as JoyButton):
				polled_press = true
	_repeat_navigation(delta)


## Godot ne répète pas les directions de la manette dans les menus (le clavier répète par le système) :
## stick ou croix tenus, le curseur démarre après un court délai puis avance d'un pas à intervalle régulier.
func _repeat_navigation(delta: float) -> void:
	for a: String in NAV:
		if not (pad and Input.is_action_pressed(a)):
			_held.erase(a)
			continue
		var before: float = _held.get(a, 0.0)
		var now := before + delta
		_held[a] = now
		if now < REPEAT_FIRST:
			continue
		var n_now := floori((now - REPEAT_FIRST) / REPEAT_EVERY)
		if before < REPEAT_FIRST or floori((before - REPEAT_FIRST) / REPEAT_EVERY) != n_now:
			var ev := InputEventAction.new()
			ev.action = a
			ev.pressed = true
			ev.strength = 1.0
			get_viewport().push_input(ev)


## Le verdict en une phrase, pour l'écran de diagnostic et le fichier.
func verdict() -> String:
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return "Aucune manette vue par le jeu : si Windows la voit, fermer Steam et relancer."
	if raw_count == 0 and not polled_press:
		return "Manette vue mais aucun bouton reçu : cliquer dans la fenêtre du jeu, puis appuyer sur A."
	return "Manette vue, boutons reçus : tout va bien."


func button_name(index: int) -> String:
	return str(BUTTON_NAMES[index]) if index >= 0 and index < BUTTON_NAMES.size() else "bouton brut %d" % index


func axis_name(index: int) -> String:
	return str(AXIS_NAMES[index]) if index >= 0 and index < AXIS_NAMES.size() else "axe brut %d" % index


func report_text() -> String:
	var ver: Dictionary = Engine.get_version_info()
	var out: Array = ["Diagnostic de la manette (%s)" % Time.get_datetime_string_from_system()]
	out.append("Godot %s, %s %s, vidéo %s" % [str(ver.get("string", "?")), OS.get_name(), OS.get_version(), DisplayServer.get_name()])
	var focus := get_window().has_focus() if get_window() != null else false
	out.append("Fenêtre du jeu active : %s ; manette ignorée hors focus : %s" % ["oui" if focus else "non", "oui" if Input.is_ignoring_joypad_on_unfocused_application() else "non"])
	var pads := Input.get_connected_joypads()
	out.append("Manettes vues par le jeu : %d" % pads.size())
	for d: int in pads:
		out.append("  [%d] %s | GUID %s | connue de Godot : %s%s | vibration : %s" % [d, Input.get_joy_name(d), Input.get_joy_guid(d), "oui" if Input.is_joy_known(d) else "non", " (mapping de repli posé)" if generic_mapped.has(d) else "", "oui" if Input.has_joy_vibration(d) else "non"])
		out.append("      infos : %s" % str(Input.get_joy_info(d)))
	out.append("Événements bruts reçus : %d ; bouton vu en sondage : %s" % [raw_count, "oui" if polled_press else "non"])
	out.append("Dernier bouton : %s" % ("aucun" if last_button.is_empty() else "%s (manette %d, %s)" % [button_name(int(last_button["index"])), int(last_button["device"]), "appuyé" if bool(last_button["pressed"]) else "relâché"]))
	out.append("Dernier axe : %s" % ("aucun" if last_axis.is_empty() else "%s = %.2f (manette %d)" % [axis_name(int(last_axis["axis"])), float(last_axis["value"]), int(last_axis["device"])]))
	out.append("Périphérique actif pour l'aide des touches : %s" % ("manette" if pad else "clavier"))
	out.append("Commandes : " + ", ".join(WATCHED.map(func(a: String) -> String: return "%s=%s" % [a, "oui" if Input.is_action_pressed(a) else "non"])))
	out.append("Verdict : " + verdict())
	out.append("Ce fichier : " + ProjectSettings.globalize_path(report_path))
	return "\n".join(out) + "\n"


## Écrit le diagnostic dans user://manette.txt (rien n'est écrit pendant les tests, sauf chemin dédié).
func write_report() -> bool:
	if not Settings.persist:
		return false
	var f := FileAccess.open(report_path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(report_text())
	f.close()
	return true


func report_location() -> String:
	return OS.get_user_data_dir().path_join(report_path.get_file())


func _input(event: InputEvent) -> void:
	note_event(event)
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5):
		set_pad(true)
	elif event is InputEventKey or event is InputEventMouseButton:
		set_pad(false)


## Change de périphérique actif (les tests s'en servent aussi).
func set_pad(on: bool) -> void:
	if on == pad:
		return
	pad = on
	device_changed.emit(on)



func _action(action: String, keys: Array, physical_keys: Array, buttons: Array, axis: int = -1, axis_value: float = 0.0) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action, DEADZONE)
	for k: int in keys:
		var ev := InputEventKey.new()
		ev.keycode = k as Key
		InputMap.action_add_event(action, ev)
	for k: int in physical_keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k as Key
		InputMap.action_add_event(action, ev)
	for b: int in buttons:
		var ev := InputEventJoypadButton.new()
		# -1 : n'importe quelle manette. Sous Windows, un clavier ou une souris « de jeu »
		# prend souvent le numéro 0 et la vraie manette le numéro 1 : elle restait muette.
		ev.device = -1
		ev.button_index = b as JoyButton
		InputMap.action_add_event(action, ev)
	if axis >= 0:
		var ev := InputEventJoypadMotion.new()
		ev.device = -1
		ev.axis = axis as JoyAxis
		ev.axis_value = axis_value
		InputMap.action_add_event(action, ev)


func _extend_pad(action: String, button: int, axis: int = -1, axis_value: float = 0.0) -> void:
	if not InputMap.has_action(action):
		return
	# on retire d'abord les entrées de manette déjà présentes, pour ne rien doubler
	for old: InputEvent in InputMap.action_get_events(action):
		if old is InputEventJoypadButton or old is InputEventJoypadMotion:
			InputMap.action_erase_event(action, old)
	var ev := InputEventJoypadButton.new()
	ev.device = -1
	ev.button_index = button as JoyButton
	InputMap.action_add_event(action, ev)
	if axis >= 0:
		var motion := InputEventJoypadMotion.new()
		motion.device = -1
		motion.axis = axis as JoyAxis
		motion.axis_value = axis_value
		InputMap.action_add_event(action, motion)


func _extend_physical(action: String, key: int) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventKey.new()
	ev.physical_keycode = key as Key
	InputMap.action_add_event(action, ev)
