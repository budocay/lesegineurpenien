extends Control
## Écran de talents : un onglet par membre de l'équipe, ses deux voies côte à côte
## (quatre talents chacune, reliés de haut en bas), le détail du talent choisi à droite.
## Tout le contenu vient de data/talents.json ; les règles (points, ordre, oubli) sont
## dans GameState. L'écran ne fait qu'afficher et appeler learn_talent / reset_talents.

signal closed

const UI = preload("res://src/ui/ui_kit.gd")
const Rules = preload("res://src/battle/rules.gd")

const LEARNED := Color("#e6c98a")
const OPEN := Color("#bfe8ff")
const SHUT := Color(0.5, 0.48, 0.52, 0.7)

var who := ""                    # personnage affiché
var _points: Label
var _tabs: HBoxContainer
var _columns: HBoxContainer
var _detail: Label
var _status: Label                   # ce qu'on peut faire du talent sous le curseur
var _message: Label
var _forget: Button
var _panel: PanelContainer
var _tab_buttons: Dictionary = {}    # id de personnage -> Button
var _nodes: Dictionary = {}          # id de talent -> Button
var _focused := ""                   # id du talent sous le curseur ("" : aucun)
var _opened_at := 0


func _ready() -> void:
	UI.full_rect(self)
	visible = false
	var frame := UI.screen(self, "Talents")
	_panel = frame["panel"]
	_points = frame["right"]
	_points.add_theme_color_override("font_color", OPEN)
	var box: VBoxContainer = frame["body"]

	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 8)
	box.add_child(_tabs)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 14)
	box.add_child(body)
	_columns = HBoxContainer.new()
	_columns.add_theme_constant_override("separation", 12)
	body.add_child(_columns)
	var side := PanelContainer.new()
	var side_style := UI.panel_style(Color(0.05, 0.06, 0.12, 0.5), Color(UI.GOLD_DIM, 0.3), 3, 1)
	side_style.shadow_size = 0
	side_style.set_content_margin_all(16)
	side.add_theme_stylebox_override("panel", side_style)
	body.add_child(side)
	_detail = UI.label("", 18, UI.INK)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(330, 250)
	_detail.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_detail.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var side_box := VBoxContainer.new()
	side_box.add_theme_constant_override("separation", 10)
	side.add_child(side_box)
	side_box.add_child(_detail)
	_status = UI.label("", 18, OPEN, true)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(330, 56)
	side_box.add_child(_status)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 18)
	box.add_child(footer)
	footer.custom_minimum_size = Vector2(0, 40)
	_forget = UI.menu_button("Tout oublier (rend les points)", 19)
	_forget.pressed.connect(forget)
	_forget.focus_entered.connect(func() -> void:
		_focused = ""
		_status.text = ""
		_detail.text = "Tout oublier\n\nOublie tous les talents de %s et rend les points dépensés.\n\nC'est gratuit et on peut le refaire autant de fois qu'on veut : aucun choix n'est définitif." % Database.get_character_name(who))
	footer.add_child(_forget)
	_message = UI.label("", 19, UI.GOLD, false, true)
	_message.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_message.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(_message)
	(frame["foot"] as HBoxContainer).add_child(UI.hints([["nav", "se déplacer"], ["ok", "apprendre"], ["pages", "changer de personnage"], ["back", "retour"]]))


# ------------------------------------------------------------------ ouverture

## Ouvre l'écran sur un membre de l'équipe (le premier qui a des points, à défaut le meneur).
func open(member_id: String = "") -> void:
	visible = true
	_opened_at = Engine.get_process_frames()
	UI.pop(_panel)
	Sfx.play("confirm")
	_message.text = ""
	if member_id == "" or not GameState.party.has(member_id):
		member_id = str(GameState.leader())
		for id: Variant in GameState.party:
			if GameState.talent_points(str(id)) > 0:
				member_id = str(id)
				break
	_build_tabs()
	who = ""
	select(member_id)
	_focus_first.call_deferred()


func close(silent: bool = false) -> void:
	if not visible:
		return
	if not silent:
		UI.ghost_fade(self)
	visible = false
	if not silent:
		Sfx.play("cancel")
		closed.emit()


func _input(event: InputEvent) -> void:
	if not visible or Engine.get_process_frames() == _opened_at:
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		close()
		return
	var step := 0
	if event.is_action_pressed("ui_page_up"):
		step = -1
	elif event.is_action_pressed("ui_page_down"):
		step = 1
	if step != 0 and _tab_buttons.size() > 1:
		get_viewport().set_input_as_handled()
		var ids: Array = _tab_buttons.keys()
		select(str(ids[posmod(ids.find(who) + step, ids.size())]))
		_focus_first.call_deferred()


# -------------------------------------------------------------------- onglets

func _build_tabs() -> void:
	for c in _tabs.get_children():
		_tabs.remove_child(c)
		c.queue_free()
	_tab_buttons.clear()
	for id: Variant in GameState.party:
		var member_id := str(id)
		if Rules.branches(member_id).is_empty():
			continue
		var b := UI.menu_button("", 19)
		b.custom_minimum_size = Vector2(0, 58)
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.icon = Sprites.portrait(member_id)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", 44)
		b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		b.focus_entered.connect(select.bind(member_id))
		b.pressed.connect(func() -> void:
			select(member_id)
			_focus_first())
		_tabs.add_child(b)
		_tab_buttons[member_id] = b
	_refresh_tabs()


func _refresh_tabs() -> void:
	for member_id: String in _tab_buttons:
		var b: Button = _tab_buttons[member_id]
		var points := GameState.talent_points(member_id)
		var text := "%s\nNv %d" % [Database.get_character_name(member_id).get_slice(" ", 0), int(GameState.member(member_id)["level"])]
		if points > 0:
			text += "  ·  %d pt%s" % [points, "s" if points > 1 else ""]
		b.text = text
		var chosen := member_id == who
		var style := StyleBoxFlat.new()
		style.bg_color = Color(UI.GOLD, 0.12) if chosen else Color(0, 0, 0, 0.0)
		style.border_color = UI.GOLD if chosen else Color(UI.INK_FAINT, 0.35)
		style.border_width_bottom = 2 if chosen else 1
		style.content_margin_left = 12
		style.content_margin_right = 10
		style.content_margin_top = 4
		style.content_margin_bottom = 5
		b.add_theme_font_override("font", UI.font(chosen))
		b.add_theme_color_override("font_color", UI.INK if chosen else UI.INK_DIM)
		b.add_theme_stylebox_override("normal", style)


## Affiche les talents d'un membre de l'équipe.
func select(member_id: String) -> void:
	if member_id == who or not _tab_buttons.has(member_id):
		return
	who = member_id
	_focused = ""
	_message.text = ""
	_rebuild()


# --------------------------------------------------------------------- arbre

static func _pts(n: int) -> String:
	return "%d point%s" % [n, "s" if n > 1 else ""]


func _node_style(state: String, hot: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.set_corner_radius_all(3)
	s.content_margin_left = 16
	s.content_margin_right = 12
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	s.set_border_width_all(1)
	match state:
		"learned":
			s.bg_color = Color(LEARNED, 0.2)
			s.border_color = Color(LEARNED, 0.9)
		"available":
			s.bg_color = Color(OPEN, 0.1)
			s.border_color = Color(OPEN, 0.85)
		"poor":   # le précédent est appris, mais les points manquent
			s.bg_color = Color(OPEN, 0.04)
			s.border_color = Color(OPEN, 0.4)
		_:
			s.bg_color = Color(1, 1, 1, 0.02)
			s.border_color = Color(SHUT, 0.45)
	if hot:
		s.bg_color = Color(s.bg_color, 0.0).lerp(Color(UI.GOLD, 0.26), 1.0)
		s.border_color = UI.GOLD
		s.set_border_width_all(2)
		s.content_margin_left = 15
	return s


func _rebuild() -> void:
	for c in _columns.get_children():
		_columns.remove_child(c)
		c.queue_free()
	_nodes.clear()
	var points := GameState.talent_points(who)
	_points.text = "Points à dépenser : %d" % points
	_points.add_theme_color_override("font_color", OPEN if points > 0 else UI.INK_DIM)
	_refresh_tabs()
	_forget.add_theme_color_override("font_color", UI.INK if GameState.talent_points_spent(who) > 0 else UI.INK_DIM)
	var spec := GameState.specialization(who)
	var grid: Array = []   # une liste de boutons par voie, pour régler le curseur
	for b: Dictionary in Rules.branches(who):
		var column := PanelContainer.new()
		var cs := UI.panel_style(Color(0.05, 0.06, 0.12, 0.5), UI.GOLD_LINE if str(b.get("id", "")) == spec else Color(UI.GOLD_DIM, 0.3), 3, 1)
		cs.shadow_size = 0
		cs.set_content_margin_all(14)
		column.add_theme_stylebox_override("panel", cs)
		_columns.add_child(column)
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 0)
		column.add_child(v)
		var talents := Rules.branch_talents(b)
		var known := 0
		for t: Dictionary in talents:
			if GameState.has_talent(who, str(t.get("id", ""))):
				known += 1
		var head := HBoxContainer.new()
		v.add_child(head)
		var name_label := UI.label(str(b.get("name", "")), 23, UI.GOLD)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		head.add_child(name_label)
		head.add_child(UI.label("%d / %d" % [known, talents.size()], 18, UI.GOLD if known > 0 else UI.INK_DIM))
		var desc := UI.label(str(b.get("desc", "")), 15, UI.INK_DIM, false, true)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(286, 70)
		desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		v.add_child(desc)
		var buttons: Array = []
		var previous_known := true
		for t: Dictionary in talents:
			var tid := str(t.get("id", ""))
			var state := GameState.talent_state(who, tid)
			if not buttons.is_empty():   # trait qui relie ce talent au précédent
				var link := ColorRect.new()
				link.color = Color(LEARNED if state == "learned" else (OPEN if state == "available" else SHUT), 0.8)
				link.custom_minimum_size = Vector2(2, 14)
				link.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				v.add_child(link)
			previous_known = state == "learned"
			var node := Button.new()
			node.text = str(t.get("name", ""))
			node.alignment = HORIZONTAL_ALIGNMENT_LEFT
			node.focus_mode = Control.FOCUS_ALL
			node.custom_minimum_size = Vector2(286, 0)
			node.add_theme_font_override("font", UI.font(state == "learned"))
			node.add_theme_font_size_override("font_size", 20)
			var ink := UI.INK if state in ["learned", "available"] else UI.INK_DIM
			for c: String in ["font_color", "font_hover_color", "font_focus_color", "font_pressed_color", "font_hover_pressed_color"]:
				node.add_theme_color_override(c, ink)
			node.add_theme_stylebox_override("normal", _node_style(state, false))
			for sb: String in ["hover", "focus", "pressed"]:
				node.add_theme_stylebox_override(sb, _node_style(state, true))
			var tag := UI.label("", 17, LEARNED if state == "learned" else (OPEN if state == "available" else UI.INK_DIM))
			tag.text = "appris" if state == "learned" else _pts(Rules.talent_cost(t))
			tag.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			tag.offset_right = -12
			tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			tag.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
			node.add_child(tag)
			node.focus_entered.connect(_on_node_focus.bind(tid))
			node.mouse_entered.connect(node.grab_focus)
			node.pressed.connect(press.bind(tid))
			v.add_child(node)
			buttons.append(node)
			_nodes[tid] = node
		grid.append(buttons)
	_wire_focus.call_deferred(grid)
	_detail.text = _summary()
	_status.text = ""


## Règle les voisins du curseur : haut/bas dans une voie, gauche/droite d'une voie à l'autre.
func _wire_focus(grid: Array) -> void:
	var tab: Button = _tab_buttons.get(who)
	for col in grid.size():
		var buttons: Array = grid[col]
		for row in buttons.size():
			var node: Button = buttons[row]
			if not is_instance_valid(node) or not node.is_inside_tree():
				return
			var up: Control = buttons[row - 1] if row > 0 else tab
			var down: Control = buttons[row + 1] if row + 1 < buttons.size() else _forget
			node.focus_neighbor_top = node.get_path_to(up)
			node.focus_neighbor_bottom = node.get_path_to(down)
			var other: Array = grid[(col + 1) % grid.size()]
			var across: Control = other[mini(row, other.size() - 1)]
			node.focus_neighbor_left = node.get_path_to(across)
			node.focus_neighbor_right = node.get_path_to(across)
	if grid.is_empty() or (grid[0] as Array).is_empty():
		return
	var first: Button = grid[0][0]
	var last: Button = (grid[0] as Array).back()
	_forget.focus_neighbor_top = _forget.get_path_to(last)
	_forget.focus_neighbor_bottom = _forget.get_path_to(_forget)
	for member_id: String in _tab_buttons:
		var b: Button = _tab_buttons[member_id]
		b.focus_neighbor_bottom = b.get_path_to(first)
		b.focus_neighbor_top = b.get_path_to(b)


func _focus_first() -> void:
	if not visible or not is_inside_tree():
		return
	for b: Dictionary in Rules.branches(who):
		for t: Dictionary in Rules.branch_talents(b):
			if GameState.talent_state(who, str(t.get("id", ""))) == "available":
				focus_talent(str(t.get("id", "")))
				return
	for tid: String in _nodes:
		focus_talent(tid)
		return


## Pose le curseur sur un talent.
func focus_talent(talent: String) -> void:
	var node: Button = _nodes.get(talent)
	if node != null and node.is_inside_tree():
		node.grab_focus()
	_on_node_focus(talent)


func _on_node_focus(talent: String) -> void:
	_focused = talent
	_detail.text = _talent_detail(talent)
	_show_status(talent)
	Sfx.play("move")


# --------------------------------------------------------------------- textes

## Ce qu'apporte un talent, en clair : bonus chiffrés et compétences débloquées.
static func effects_text(def: Dictionary) -> String:
	var lines: Array = []
	var mods: Variant = def.get("mods", {})
	if mods is Dictionary and not (mods as Dictionary).is_empty():
		var bits: Array = []
		for key: String in mods:
			bits.append("%s +%d" % [str(GameState.STAT_NAMES.get(key, key)), int(mods[key])])
		lines.append(", ".join(bits))
	var skills: Variant = def.get("skills", [])
	if skills is Array:
		for s: Variant in skills:
			var sk := Database.get_skill(str(s))
			lines.append("Nouvelle compétence : %s (%d PM)\n%s" % [str(sk.get("name", s)), int(sk.get("cost", 0)), str(sk.get("desc", ""))])
	return "\n".join(lines)


func _branch_of(talent: String) -> Dictionary:
	for b: Dictionary in Rules.branches(who):
		for t: Dictionary in Rules.branch_talents(b):
			if str(t.get("id", "")) == talent:
				return b
	return {}


func _talent_detail(talent: String) -> String:
	var def := Rules.talent_def(who, talent)
	if def.is_empty():
		return _summary()
	var cost := Rules.talent_cost(def)
	var lines: Array = [str(def.get("name", "")).to_upper()]
	lines.append("%s   ·   coût : %s" % [str(_branch_of(talent).get("name", "")), _pts(cost)])
	lines.append("")
	lines.append(str(def.get("desc", "")))
	var effects := effects_text(def)
	if effects != "":
		lines.append("")
		lines.append(effects)
	return "\n".join(lines)


## Ligne colorée sous le détail : appris, à apprendre, fermé, ou trop cher.
func _show_status(talent: String) -> void:
	var def := Rules.talent_def(who, talent)
	var text := ""
	var color := UI.INK_DIM
	match GameState.talent_state(who, talent):
		"learned":
			text = "Déjà appris."
			color = LEARNED
		"available":
			text = "%s : apprendre ce talent." % UI.key_text("ok")
			color = OPEN
		"locked":
			var need := Rules.talent_def(who, Rules.talent_requirement(who, talent))
			text = "Fermé. Il faut d'abord apprendre : %s." % str(need.get("name", ""))
			color = Color("#e8a08a")
		"poor":
			text = "Pas assez de points : il en faut %d. On en gagne un à chaque niveau." % Rules.talent_cost(def)
			color = Color("#e8a08a")
	_status.text = text
	_status.add_theme_color_override("font_color", color)


func _summary() -> String:
	var ch := Database.get_character(who)
	var lines: Array = [str(ch.get("full_name", ch.get("name", who)))]
	lines.append("%s   ·   niveau %d" % [str(ch.get("role", "")).capitalize(), int(GameState.member(who)["level"])])
	lines.append("")
	lines.append("On gagne un point de talent à chaque niveau.")
	lines.append("Dans une voie, les talents s'apprennent de haut en bas. Rien n'empêche de piocher dans les deux voies.")
	lines.append("Une voie entière coûte six points.")
	var skills: Array = []
	for s: Variant in GameState.member_skills(who):
		skills.append(str(Database.get_skill(str(s)).get("name", s)))
	if not skills.is_empty():
		lines.append("")
		lines.append("Compétences : " + ", ".join(skills))
	return "\n".join(lines)


# -------------------------------------------------------------------- actions

## Tente d'apprendre un talent, comme le ferait le joueur en validant dessus.
func press(talent: String) -> void:
	if not visible:
		return
	var def := Rules.talent_def(who, talent)
	var good := false
	match GameState.talent_state(who, talent):
		"learned":
			_message.text = "%s connaît déjà ce talent." % Database.get_character_name(who)
		"locked":
			var need := Rules.talent_def(who, Rules.talent_requirement(who, talent))
			_message.text = "Il faut d'abord apprendre : %s." % str(need.get("name", ""))
		"available":
			if GameState.learn_talent(who, talent):
				good = true
				_rebuild()
				_message.text = "%s apprend : %s." % [Database.get_character_name(who), str(def.get("name", talent))]
				_refocus.call_deferred(talent)
		_:
			_message.text = "Pas assez de points de talent."
	Sfx.play("save" if good else "cancel")


func forget() -> void:
	if not visible:
		return
	var back := GameState.reset_talents(who)
	if back <= 0:
		_message.text = "Il n'y a rien à oublier."
		Sfx.play("cancel")
		return
	_rebuild()
	_message.text = "%s oublie tout : %s rendu%s." % [Database.get_character_name(who), _pts(back), "s" if back > 1 else ""]
	Sfx.play("confirm")
	_forget.grab_focus.call_deferred()


func _refocus(talent: String) -> void:
	if visible and is_inside_tree():
		focus_talent(talent)


# ------------------------------------------------------- lecture pour les tests

func state_of(talent: String) -> String:
	return GameState.talent_state(who, talent)


func talent_ids() -> Array:
	return _nodes.keys()


func tab_ids() -> Array:
	return _tab_buttons.keys()


func detail_text() -> String:
	return _detail.text + "\n" + _status.text


func message_text() -> String:
	return _message.text


func points_text() -> String:
	return _points.text
