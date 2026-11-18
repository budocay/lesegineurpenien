extends Control
## Rappel de quête en exploration : le nom de la quête principale en cours, son étape actuelle
## (une ligne, deux au plus si elle est longue) et la touche du journal, en haut à gauche sous le
## témoin du Ramollissement. Posé par hud.gd. Quand une quête principale commence, avance d'une
## étape ou s'achève, l'encart s'anime et le dit : « Nouvelle quête », « Quête mise à jour »,
## « Quête terminée ». Il s'efface tout seul pendant un dialogue, un menu, un combat ou un titre de lieu.
## Les étapes viennent de data/quests.json (champ `steps`, chacune avec sa condition `done`).

const UI = preload("res://src/ui/ui_kit.gd")
const TipPanel = preload("res://src/ui/tutorial_panel.gd")

const POLL := 0.2
const FLASH_SECONDS := 4.0
const WIDTH := 480.0

var tracked := ""                  # quête affichée
var step_text := ""                # étape affichée
var flash_text := ""               # « Nouvelle quête »... tant que l'animation dure

var _panel: PanelContainer
var _kicker: Label
var _name: Label
var _line: Label
var _keys: HBoxContainer
var _poll := 0.0
var _flash := 0.0
var _quests_ref: Variant = null
var _prev: Dictionary = {}         # quête principale -> [état, étape]
var _log: Array = []               # événements annoncés (tests) : [texte, identifiant]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameState.quest_started.connect(_on_started)
	GameState.quest_completed.connect(_on_completed)
	_panel = PanelContainer.new()
	var st := UI.panel_style(Color(0.03, 0.035, 0.08, 0.74), UI.GOLD_LINE, 6, 1)
	st.content_margin_left = 14
	st.content_margin_right = 16
	st.content_margin_top = 6
	st.content_margin_bottom = 8
	_panel.add_theme_stylebox_override("panel", st)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.custom_minimum_size = Vector2(WIDTH, 0)
	_panel.visible = false
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(box)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 10)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(head)
	_kicker = UI.caps("Quête", 13, UI.GOLD)
	head.add_child(_kicker)
	_name = UI.label("", 14, UI.INK_FAINT, false, true)
	_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name.clip_text = true
	_name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_name.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(_name)
	_keys = HBoxContainer.new()
	_keys.add_theme_constant_override("separation", 5)
	_keys.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(_keys)
	_line = UI.label("", 18, UI.INK)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.max_lines_visible = 2
	_line.custom_minimum_size = Vector2(WIDTH - 30.0, 0)
	_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_line)


# ------------------------------------------------------------------ quêtes

## Quêtes principales commencées, dans l'ordre du fichier.
static func principal_quests(state: String = "active") -> Array:
	var out: Array = []
	for id: String in Database.quests:
		if str(Database.get_quest(id).get("kind", "")) == "principale" and GameState.quest_state(id) == state:
			out.append(id)
	return out


## Indice de l'étape en cours : la première dont la condition `done` n'est pas encore remplie.
static func step_index(id: String) -> int:
	var steps: Array = Database.get_quest(id).get("steps", [])
	for i in steps.size():
		var done := str((steps[i] as Dictionary).get("done", ""))
		if done == "" or not GameState.check(done):
			return i
	return maxi(0, steps.size() - 1)


static func step_text_of(id: String) -> String:
	var steps: Array = Database.get_quest(id).get("steps", [])
	if steps.is_empty():
		return str(Database.get_quest(id).get("desc", ""))
	return str((steps[step_index(id)] as Dictionary).get("text", ""))


func _snapshot() -> Dictionary:
	var out := {}
	for state: String in ["active", "done"]:
		for id: String in principal_quests(state):
			out[id] = [state, step_index(id) if state == "active" else -1]
	return out


## Compare la situation à la précédente : annonce un changement d'étape. `silent` : chargement d'une
## partie. Le début et la fin d'une quête arrivent par les signaux de GameState (voir _ready).
func update_now(silent: bool = false) -> void:
	var now := _snapshot()
	if not silent:
		for id: String in now:
			var after: Array = now[id]
			var before: Variant = _prev.get(id)
			if before != null and (before as Array)[0] == "active" and after[0] == "active" and (before as Array)[1] != after[1]:
				_announce("Quête mise à jour", id)
	_prev = now
	var lost := tracked != "" and GameState.quest_state(tracked) != "active" and _flash <= 0.0
	if tracked == "" or lost or not now.has(tracked):
		var list := principal_quests()
		tracked = str(list[0]) if not list.is_empty() else ""
	if tracked != "":
		step_text = step_text_of(tracked)
	else:
		step_text = ""


func _on_started(id: String) -> void:
	if str(Database.get_quest(id).get("kind", "")) != "principale":
		return
	_quests_ref = GameState.quests
	_prev[id] = ["active", step_index(id)]
	_announce("Nouvelle quête", id)
	update_now(true)


func _on_completed(id: String, _reward: Dictionary) -> void:
	if str(Database.get_quest(id).get("kind", "")) != "principale":
		return
	_quests_ref = GameState.quests
	_prev[id] = ["done", -1]
	_announce("Quête terminée", id)
	update_now(true)


func _announce(text: String, id: String) -> void:
	tracked = id
	flash_text = text
	_flash = FLASH_SECONDS
	_log.append([text, id])
	if _panel.visible:
		UI.pop(_panel, 0.35)
	if text != "Quête terminée":
		Sfx.play("confirm")


# ------------------------------------------------------------------ affichage

func _process(delta: float) -> void:
	if _flash > 0.0:
		if Tutorial.explore_open():
			_flash -= delta
		if _flash <= 0.0:
			flash_text = ""
			update_now(true)   # la quête terminée cède la place à la suivante
	if not is_same(_quests_ref, GameState.quests):   # nouvelle partie ou chargement : on repart à zéro, sans fanfare
		_quests_ref = GameState.quests
		_prev = {}
		tracked = ""
		flash_text = ""
		_flash = 0.0
		update_now(true)
	_poll -= delta
	if _poll <= 0.0:
		_poll = POLL
		update_now(false)
	var open: bool = Tutorial.explore_open() and tracked != ""
	var banner_up := false
	var hud := get_parent()
	if hud != null and hud.get("_banner") != null:
		banner_up = (hud.get("_banner") as Control).modulate.a > 0.05
	if not open:
		_panel.visible = false
		return
	_panel.visible = true
	_panel.modulate.a = 0.0 if banner_up else 1.0
	var q := Database.get_quest(tracked)
	_kicker.text = flash_text if flash_text != "" else "Quête"
	_kicker.add_theme_color_override("font_color", UI.GOLD if flash_text != "" else UI.GOLD_DIM)
	var shown_name := "·  " + str(q.get("name", tracked))
	var shown_line := step_text if GameState.quest_state(tracked) == "active" else "Terminée. Bien joué, dans l'ensemble."
	if shown_name != _name.text or shown_line != _line.text:
		_name.text = shown_name
		_line.text = shown_line
		_panel.reset_size()
	_fill_keys()
	var y := 24.0
	var soft: Variant = hud.get("_soft") if hud != null else null
	if soft != null and (soft as Control).visible:
		y += (soft as Control).size.y + 8.0
	_panel.position = Vector2(28.0, y)


var _keys_shown := ""


func _fill_keys() -> void:
	var caps: Array = Tutorial.caps_for("menu")
	var sig := ",".join(caps) + str(Tutorial.pad)
	if sig == _keys_shown:
		return
	_keys_shown = sig
	for c in _keys.get_children():
		_keys.remove_child(c)
		c.queue_free()
	for c: Control in TipPanel.caps_nodes([caps[0]], 12):
		_keys.add_child(c)
	_keys.add_child(UI.label("journal", 13, UI.INK_FAINT))


## Rectangle (à l'écran) du rappel, ou rien s'il est caché.
func panel_rect() -> Rect2:
	return Rect2(_panel.position, _panel.size) if _panel.visible else Rect2()
