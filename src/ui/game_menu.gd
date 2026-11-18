extends Control
## Écrans à liste du jeu : équipe et équipement, inventaire, journal de quêtes, boutiques.
## Tous partagent la même présentation : une liste à gauche, le détail de la ligne
## choisie à droite, les écus en haut. Une « page » est une liste d'entrées
##   {"text": "...", "detail": "...", "dim": bool, "action": Callable}
## et un retour (Callable) appelé par la touche Annuler ; sans retour, l'écran se ferme.

signal closed

const UI = preload("res://src/ui/ui_kit.gd")
const Rules = preload("res://src/battle/rules.gd")

var _title: Label
var _money: Label
var _list: VBoxContainer
var _detail: Label
var _message: Label
var _entries: Array = []
var _back: Callable = Callable()
var _opened_at := 0
var _shop: Dictionary = {}


func _ready() -> void:
	UI.full_rect(self)
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.06, 0.62)
	UI.full_rect(dim)
	add_child(dim)

	var center := CenterContainer.new()
	UI.full_rect(center)
	add_child(center)
	var panel := PanelContainer.new()
	var style := UI.panel_style()
	style.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var header := HBoxContainer.new()
	box.add_child(header)
	_title = UI.label("", 34, UI.GOLD, false, true)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	_money = UI.label("", 22, UI.GOLD)
	_money.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(_money)
	var rule := ColorRect.new()
	rule.color = UI.GOLD_DIM
	rule.custom_minimum_size = Vector2(0, 2)
	box.add_child(rule)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 22)
	box.add_child(body)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(440, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	body.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 2)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_detail = UI.label("", 19, UI.INK)
	_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail.custom_minimum_size = Vector2(470, 400)
	_detail.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	body.add_child(_detail)

	_message = UI.label("", 20, UI.GOLD, false, true)
	_message.custom_minimum_size = Vector2(0, 28)
	box.add_child(_message)
	var hint := UI.label("Entrée : choisir   ·   Retour arrière ou X : revenir", 16, UI.INK_DIM)
	box.add_child(hint)


# ------------------------------------------------------------------ ouverture

## Ouvre un écran du menu de pause : "team", "inventory" ou "quests".
func open(which: String) -> void:
	_show()
	match which:
		"team": _team()
		"inventory": _inventory()
		_: _journal()


func open_shop(shop_id: String) -> void:
	_shop = Database.get_shop(shop_id)
	_show()
	_shop_root()


func _show() -> void:
	visible = true
	_opened_at = Engine.get_process_frames()
	Sfx.play("confirm")


func close(silent: bool = false) -> void:
	if not visible:
		return
	visible = false
	_entries = []
	_back = Callable()
	if not silent:
		Sfx.play("cancel")
		closed.emit()


func _input(event: InputEvent) -> void:
	if not visible or Engine.get_process_frames() == _opened_at:
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu"):
		get_viewport().set_input_as_handled()
		go_back()


## Revient à la page précédente, ou ferme l'écran s'il n'y en a pas.
func go_back() -> void:
	if _back.is_valid():
		Sfx.play("cancel")
		_back.call()
	else:
		close()


# ----------------------------------------------------------------- une page

func _page(title: String, entries: Array, back: Callable = Callable(), focus: int = 0) -> void:
	_title.text = title
	_entries = entries
	_back = back
	_message.text = ""
	_money.text = "%d %s" % [GameState.money, GameState.MONEY_NAME]
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	for i in entries.size():
		var e: Dictionary = entries[i]
		var b := UI.menu_button(str(e.get("text", "")), 21)
		b.custom_minimum_size = Vector2(420, 0)
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.clip_text = true
		if bool(e.get("dim", false)):
			b.add_theme_color_override("font_color", UI.INK_DIM)
		b.focus_entered.connect(_on_focus.bind(i))
		b.pressed.connect(_on_pressed.bind(i))
		_list.add_child(b)
	_detail.text = ""
	if not entries.is_empty():
		var index := clampi(focus, 0, entries.size() - 1)
		_detail.text = str((entries[index] as Dictionary).get("detail", ""))
		_focus_row.call_deferred(index)


## Donne le curseur à une ligne (différé : la liste vient d'être reconstruite).
func _focus_row(index: int) -> void:
	if not visible or not is_inside_tree() or index >= _list.get_child_count():
		return
	var b := _list.get_child(index) as Button
	if b != null and b.is_inside_tree():
		b.grab_focus()


func _on_focus(index: int) -> void:
	if index < _entries.size():
		_detail.text = str((_entries[index] as Dictionary).get("detail", ""))


func _on_pressed(index: int) -> void:
	if not visible or index >= _entries.size():
		return
	var action: Variant = (_entries[index] as Dictionary).get("action")
	if action is Callable and (action as Callable).is_valid():
		Sfx.play("confirm")
		(action as Callable).call()


## Choisit la ligne donnée, comme le ferait le joueur (sert aux tests).
func press(index: int) -> void:
	_on_pressed(index)


func entry_texts() -> Array:
	var out: Array = []
	for e: Dictionary in _entries:
		out.append(str(e.get("text", "")))
	return out


func _say(text: String, good: bool = true) -> void:
	_message.text = text
	if not good:
		Sfx.play("cancel")


# -------------------------------------------------------------------- textes

static func _item_name(id: String) -> String:
	return str(Database.get_item(id).get("name", id))


static func _mods_text(item: String) -> String:
	var parts: Array = []
	var mods: Variant = Database.get_item(item).get("mods", {})
	if mods is Dictionary:
		for key: String in Rules.STATS:
			if (mods as Dictionary).has(key):
				var v := int(mods[key])
				parts.append("%s %s%d" % [str(GameState.STAT_NAMES.get(key, key)), "+" if v >= 0 else "−", absi(v)])
	return ", ".join(parts)


## Description complète d'un objet : texte, genre, bonus, porteurs possibles.
static func item_detail(id: String) -> String:
	var def := Database.get_item(id)
	var lines: Array = [str(def.get("name", id)), "", str(def.get("desc", ""))]
	match Database.item_kind(id):
		"equipment":
			lines.append("")
			lines.append("%s   ·   %s" % [str(GameState.SLOT_NAMES.get(str(def.get("slot", "")), "Équipement")), _mods_text(id)])
			if bool(def.get("firm", false)):
				lines.append("Insensible au Ramollissement.")
			var only: Variant = def.get("for")
			if only is Array and not (only as Array).is_empty():
				var names: Array = []
				for who: Variant in only:
					names.append(Database.get_character_name(str(who)))
				lines.append("Réservé à : " + ", ".join(names))
			else:
				lines.append("Convient à tout le monde.")
		"key":
			lines.append("")
			lines.append("Objet de quête.")
		_:
			if not GameState.usable_outside(id):
				lines.append("")
				lines.append("Ne sert qu'en combat.")
	return "\n".join(lines)


static func _member_line(id: String) -> String:
	var m := GameState.member(id)
	var stats := GameState.member_stats(id)
	return "%s   PV %d/%d   PM %d/%d" % [Database.get_character_name(id), int(m["hp"]), int(stats["hp"]), int(m["mp"]), int(stats["mp"])]


static func _member_detail(id: String) -> String:
	var ch := Database.get_character(id)
	var m := GameState.member(id)
	var stats := GameState.member_stats(id)
	var bare := Rules.stats_at(id, int(m["level"]))
	var lines: Array = [str(ch.get("full_name", ch.get("name", id)))]
	lines.append("%s   ·   Niveau %d   ·   XP %d / %d" % [str(ch.get("role", "")).capitalize(), int(m["level"]), int(m["xp"]), Rules.xp_to_next(int(m["level"]))])
	lines.append("PV %d/%d      PM %d/%d" % [int(m["hp"]), int(stats["hp"]), int(m["mp"]), int(stats["mp"])])
	var spec := GameState.specialization_name(id)
	var points := GameState.talent_points(id)
	if spec != "" or points > 0:
		var bits: Array = []
		if spec != "":
			bits.append("Voie : %s" % spec)
		if points > 0:
			bits.append("%s de talent à dépenser" % _points(points))
		lines.append("   ·   ".join(bits))
	lines.append("")
	for key: String in ["atk", "def", "mag", "res", "spd"]:
		var bonus := int(stats[key]) - int(bare[key])
		var line := "%s  %d" % [str(GameState.STAT_NAMES[key]), int(stats[key])]
		if bonus != 0:
			line += "   (%s%d)" % ["+" if bonus > 0 else "−", absi(bonus)]
		lines.append(line)
	lines.append("")
	for slot: String in GameState.SLOTS:
		var worn := GameState.equipped(id, slot)
		lines.append("%s : %s" % [str(GameState.SLOT_NAMES[slot]), _item_name(worn) if worn != "" else "—"])
	var skills: Array = []
	for s: Variant in GameState.member_skills(id):
		skills.append(str(Database.get_skill(str(s)).get("name", s)))
	if not skills.is_empty():
		lines.append("")
		lines.append("Compétences : " + ", ".join(skills))
	return "\n".join(lines)


static func _quest_detail(id: String) -> String:
	var q := Database.get_quest(id)
	var done := GameState.quest_state(id) == "done"
	var lines: Array = [str(q.get("name", id))]
	var kind := "Quête annexe" if str(q.get("kind", "")) == "annexe" else "Quête principale"
	if str(q.get("giver", "")) != "":
		kind += "   ·   " + str(q["giver"])
	lines.append(kind)
	lines.append("")
	lines.append(str(q.get("desc", "")))
	lines.append("")
	# On ne montre les étapes que jusqu'à la première qui reste à faire.
	for step: Variant in q.get("steps", []):
		if not (step is Dictionary):
			continue
		var ok := done or GameState.check(str(step.get("done", "")))
		lines.append("%s  %s" % ["✓" if ok else "•", str(step.get("text", ""))])
		if not ok:
			break
	if done:
		lines.append("")
		lines.append("Terminée.")
		var r: Variant = q.get("reward")
		if r is Dictionary and GameState.reward_text(r) != "":
			lines.append("Récompense reçue : " + GameState.reward_text(r))
	return "\n".join(lines)


# ------------------------------------------------------------------- journal

func _journal() -> void:
	var entries: Array = []
	for state: String in ["active", "done"]:
		for id: String in Database.quests:
			if GameState.quest_state(id) != state:
				continue
			var label := str(Database.get_quest(id).get("name", id))
			entries.append({"text": ("✓  " + label) if state == "done" else label, "dim": state == "done", "detail": _quest_detail(id)})
	if entries.is_empty():
		entries.append({"text": "Aucune quête pour l'instant", "dim": true, "detail": "Parlez aux habitants : les ennuis ne manquent pas."})
	_page("Journal de quêtes", entries)


# ---------------------------------------------------------------- inventaire

static func _sorted_items() -> Array:
	var order := {"consumable": 0, "equipment": 1, "key": 2}
	var ids: Array = GameState.inventory.keys()
	ids.sort_custom(func(a: Variant, b: Variant) -> bool:
		var ka := int(order.get(Database.item_kind(str(a)), 3))
		var kb := int(order.get(Database.item_kind(str(b)), 3))
		if ka != kb:
			return ka < kb
		return _item_name(str(a)).naturalnocasecmp_to(_item_name(str(b))) < 0)
	return ids


func _inventory(focus: int = 0) -> void:
	var entries: Array = []
	for id: Variant in _sorted_items():
		var item := str(id)
		if Database.get_item(item).is_empty():
			continue
		entries.append({
			"text": "%s   ×%d" % [_item_name(item), GameState.item_count(item)],
			"detail": item_detail(item),
			"action": _item_chosen.bind(item, entries.size()),
		})
	if entries.is_empty():
		entries.append({"text": "Le sac est vide", "dim": true, "detail": "Pas même une miette de tabac."})
	_page("Inventaire", entries, Callable(), focus)


func _item_chosen(item: String, index: int) -> void:
	match Database.item_kind(item):
		"equipment":
			_equip_targets(item, index)
		"key":
			_say("Objet de quête : il servira le moment venu.")
		_:
			if GameState.usable_outside(item):
				_item_targets(item, index)
			else:
				_say("Cela ne sert qu'en combat.", false)


func _item_targets(item: String, from: int, focus: int = 0) -> void:
	var entries: Array = []
	for id: Variant in GameState.party:
		entries.append({
			"text": _member_line(str(id)),
			"detail": item_detail(item) + "\n\nDans le sac : %d" % GameState.item_count(item),
			"action": _use_on.bind(item, str(id), from, entries.size()),
		})
	_page("Pour qui ?", entries, _inventory.bind(from), focus)


func _use_on(item: String, who: String, from: int, index: int) -> void:
	var result := GameState.use_item(item, who)
	if result == "":
		_say("%s n'en a pas besoin." % Database.get_character_name(who), false)
		return
	Sfx.play("heal")
	if GameState.item_count(item) > 0:
		_item_targets(item, from, index)
	else:
		_inventory(from)
	_say(result)


func _equip_targets(item: String, from: int) -> void:
	var slot := str(Database.get_item(item).get("slot", ""))
	var entries: Array = []
	for id: Variant in GameState.party:
		var who := str(id)
		if not GameState.can_equip(who, item):
			continue
		var worn := GameState.equipped(who, slot)
		entries.append({
			"text": "%s   (%s)" % [Database.get_character_name(who), _item_name(worn) if worn != "" else "rien"],
			"detail": item_detail(item) + "\n\n" + _member_detail(who),
			"action": _equip_from_bag.bind(who, item, from),
		})
	if entries.is_empty():
		_say("Personne dans l'équipe ne peut s'en servir.", false)
		return
	_page("Équiper qui ?", entries, _inventory.bind(from))


func _equip_from_bag(who: String, item: String, from: int) -> void:
	if GameState.equip(who, item):
		_inventory(from)
		_say("%s s'équipe : %s." % [Database.get_character_name(who), _item_name(item)])


# -------------------------------------------------------------------- équipe

func _team(focus: int = 0) -> void:
	var entries: Array = []
	for id: Variant in GameState.party:
		var who := str(id)
		var text := "%s   Nv %d" % [Database.get_character_name(who), int(GameState.member(who)["level"])]
		var points := GameState.talent_points(who)
		if points > 0:
			text += "   ·   %s de talent" % _points(points)
		entries.append({
			"text": text,
			"detail": _member_detail(who),
			"action": _member.bind(who, entries.size(), 0),
		})
	_page("Équipe", entries, Callable(), focus)


## Fiche d'un personnage : de là, on règle son équipement ou ses talents.
func _member(who: String, from: int, focus: int = 0) -> void:
	var points := GameState.talent_points(who)
	var entries: Array = [
		{"text": "Équipement", "detail": _member_detail(who), "action": _gear.bind(who, from, 0)},
		{
			"text": "Talents" + ("   ·   %s à dépenser" % _points(points) if points > 0 else ""),
			"detail": _talents_summary(who),
			"action": _talents.bind(who, from, 0),
		},
	]
	_page(Database.get_character_name(who), entries, _team.bind(from), focus)


# ------------------------------------------------------------------- talents

static func _points(n: int) -> String:
	return "%d point%s" % [n, "s" if n > 1 else ""]


## Ce qu'apporte un talent, en clair : bonus chiffrés et compétences débloquées.
static func _talent_effects(def: Dictionary) -> String:
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


## Résumé des deux branches d'un personnage et de ce qu'il y a déjà appris.
static func _talents_summary(who: String) -> String:
	var lines: Array = []
	var points := GameState.talent_points(who)
	lines.append("%s de talent à dépenser." % _points(points) if points > 0 else "Aucun point de talent à dépenser pour l'instant.")
	lines.append("On gagne un point à chaque niveau.")
	for b: Dictionary in Rules.branches(who):
		var known: Array = []
		for t: Dictionary in Rules.branch_talents(b):
			if GameState.has_talent(who, str(t.get("id", ""))):
				known.append(str(t.get("name", "")))
		lines.append("")
		lines.append("%s (%d/%d)" % [str(b.get("name", "")), known.size(), Rules.branch_talents(b).size()])
		lines.append(str(b.get("desc", "")))
		if not known.is_empty():
			lines.append("Appris : " + ", ".join(known))
	return "\n".join(lines)


static func _talent_detail(who: String, branch: Dictionary, def: Dictionary, state: String) -> String:
	var cost := Rules.talent_cost(def)
	var lines: Array = [str(def.get("name", ""))]
	lines.append("Voie : %s   ·   Coût : %s" % [str(branch.get("name", "")), _points(cost)])
	lines.append("")
	lines.append(str(def.get("desc", "")))
	var effects := _talent_effects(def)
	if effects != "":
		lines.append("")
		lines.append(effects)
	lines.append("")
	match state:
		"learned":
			lines.append("Déjà appris.")
		"available":
			lines.append("Entrée : apprendre ce talent.")
		"locked":
			var need := Rules.talent_def(who, Rules.talent_requirement(who, str(def.get("id", ""))))
			lines.append("Il faut d'abord apprendre : %s." % str(need.get("name", "")))
		_:
			lines.append("Pas assez de points : il en faut %d. On en gagne un à chaque niveau." % cost)
	return "\n".join(lines)


## L'arbre de talents d'un personnage : ses deux branches l'une sous l'autre.
func _talents(who: String, from: int, focus: int = 0) -> void:
	var branches := Rules.branches(who)
	if branches.is_empty():
		_say("%s n'a pas de talents à apprendre." % Database.get_character_name(who), false)
		return
	var entries: Array = []
	var points := GameState.talent_points(who)
	for b: Dictionary in branches:
		entries.append({
			"text": "— %s —" % str(b.get("name", "")),
			"detail": "%s\n\n%s\n\nLes talents d'une voie s'apprennent dans l'ordre. Rien n'empêche de piocher dans les deux." % [str(b.get("name", "")), str(b.get("desc", ""))],
		})
		for t: Dictionary in Rules.branch_talents(b):
			var tid := str(t.get("id", ""))
			var state := GameState.talent_state(who, tid)
			var text := "   [%s] %s" % ["x" if state == "learned" else "  ", str(t.get("name", ""))]
			if state != "learned":
				text += "   (%s)" % _points(Rules.talent_cost(t))
			entries.append({
				"text": text,
				"detail": _talent_detail(who, b, t, state),
				"dim": state in ["locked", "poor"],
				"action": _learn.bind(who, tid, from, entries.size()),
			})
	var spent := GameState.talent_points_spent(who)
	entries.append({
		"text": "Tout oublier",
		"detail": "Oublie tous les talents de %s et rend les points dépensés (%d).\n\nC'est gratuit et on peut le refaire autant de fois qu'on veut : aucun choix n'est définitif." % [Database.get_character_name(who), spent],
		"dim": spent == 0,
		"action": _forget.bind(who, from, entries.size()),
	})
	_page("Talents de %s   ·   %s" % [Database.get_character_name(who), _points(points)], entries, _member.bind(who, from, 1), focus)


func _learn(who: String, talent: String, from: int, index: int) -> void:
	var def := Rules.talent_def(who, talent)
	match GameState.talent_state(who, talent):
		"learned":
			_say("%s connaît déjà ce talent." % Database.get_character_name(who), false)
		"locked":
			var need := Rules.talent_def(who, Rules.talent_requirement(who, talent))
			_say("Il faut d'abord apprendre : %s." % str(need.get("name", "")), false)
		"available":
			if GameState.learn_talent(who, talent):
				_talents(who, from, index)
				_say("%s apprend : %s." % [Database.get_character_name(who), str(def.get("name", talent))])
		_:
			_say("Pas assez de points de talent.", false)


func _forget(who: String, from: int, index: int) -> void:
	var back := GameState.reset_talents(who)
	if back <= 0:
		_say("Il n'y a rien à oublier.", false)
		return
	_talents(who, from, index)
	_say("%s oublie tout : %s rendu%s." % [Database.get_character_name(who), _points(back), "s" if back > 1 else ""])


func _gear(who: String, from: int, focus: int = 0) -> void:
	var entries: Array = []
	for slot: String in GameState.SLOTS:
		var worn := GameState.equipped(who, slot)
		entries.append({
			"text": "%s : %s" % [str(GameState.SLOT_NAMES[slot]), _item_name(worn) if worn != "" else "—"],
			"detail": (item_detail(worn) if worn != "" else "Rien d'équipé.") + "\n\n" + _member_detail(who),
			"action": _slot_choices.bind(who, slot, from, entries.size()),
		})
	_page("Équipement de %s" % Database.get_character_name(who), entries, _member.bind(who, from, 0), focus)


func _slot_choices(who: String, slot: String, from: int, slot_index: int) -> void:
	var entries: Array = []
	for id: Variant in _sorted_items():
		var item := str(id)
		if str(Database.get_item(item).get("slot", "")) != slot or not GameState.can_equip(who, item):
			continue
		entries.append({
			"text": "%s   ×%d" % [_item_name(item), GameState.item_count(item)],
			"detail": item_detail(item),
			"action": _equip_slot.bind(who, item, from, slot_index),
		})
	if GameState.equipped(who, slot) != "":
		entries.append({
			"text": "Retirer : %s" % _item_name(GameState.equipped(who, slot)),
			"detail": "Remet l'objet dans le sac.",
			"action": _unequip_slot.bind(who, slot, from, slot_index),
		})
	if entries.is_empty():
		_say("Rien dans le sac ne convient.", false)
		return
	_page("%s de %s" % [str(GameState.SLOT_NAMES[slot]), Database.get_character_name(who)], entries, _gear.bind(who, from, slot_index))


func _equip_slot(who: String, item: String, from: int, slot_index: int) -> void:
	if GameState.equip(who, item):
		_gear(who, from, slot_index)
		_say("%s s'équipe : %s." % [Database.get_character_name(who), _item_name(item)])


func _unequip_slot(who: String, slot: String, from: int, slot_index: int) -> void:
	var worn := GameState.equipped(who, slot)
	if GameState.unequip(who, slot):
		_gear(who, from, slot_index)
		_say("%s retire : %s." % [Database.get_character_name(who), _item_name(worn)])


# ------------------------------------------------------------------ boutique

func _shop_name() -> String:
	return str(_shop.get("name", "Boutique"))


func _shop_root(focus: int = 0) -> void:
	var greeting := str(_shop.get("greeting", ""))
	_page(_shop_name(), [
		{"text": "Acheter", "detail": greeting, "action": _shop_buy.bind(0)},
		{"text": "Vendre", "detail": greeting, "action": _shop_sell.bind(0)},
		{"text": "Partir", "detail": greeting, "action": close.bind(false)},
	], Callable(), focus)


## Articles en vente en ce moment : [{"item", "price", "once"}].
func shop_offers() -> Array:
	var out: Array = []
	for e: Variant in _shop.get("stock", []):
		if not (e is Dictionary):
			continue
		var item := str(e.get("item", ""))
		if Database.get_item(item).is_empty():
			continue
		if not GameState.check(str(e.get("if", ""))):
			continue
		var once := str(e.get("once", ""))
		if once != "" and GameState.has_flag(once):
			continue
		out.append({"item": item, "price": int(e.get("price", Database.get_item(item).get("price", 0))), "once": once})
	return out


func _shop_buy(focus: int = 0) -> void:
	var entries: Array = []
	for offer: Dictionary in shop_offers():
		var item := str(offer["item"])
		var price := int(offer["price"])
		entries.append({
			"text": "%s   ·   %d %s" % [_item_name(item), price, GameState.MONEY_NAME],
			"dim": GameState.money < price,
			"detail": item_detail(item) + "\n\nDans le sac : %d" % GameState.item_count(item),
			"action": _buy.bind(offer, entries.size()),
		})
	if entries.is_empty():
		entries.append({"text": "Plus rien à vendre", "dim": true, "detail": ""})
	_page(_shop_name() + " : acheter", entries, _shop_root.bind(0), focus)


func _buy(offer: Dictionary, index: int) -> void:
	var item := str(offer["item"])
	if not GameState.buy(item, int(offer["price"])):
		_say("Pas assez d'écus.", false)
		return
	if str(offer["once"]) != "":
		GameState.set_flag(str(offer["once"]))
	_shop_buy(index)
	_say("Acheté : %s." % _item_name(item))


func _shop_sell(focus: int = 0) -> void:
	var ratio := float(_shop.get("sell_ratio", 0.5))
	var entries: Array = []
	for id: Variant in _sorted_items():
		var item := str(id)
		var gain := GameState.sell_price(item, ratio)
		if gain <= 0:
			continue
		entries.append({
			"text": "%s  ×%d   ·   %d %s" % [_item_name(item), GameState.item_count(item), gain, GameState.MONEY_NAME],
			"detail": item_detail(item),
			"action": _sell.bind(item, ratio, entries.size()),
		})
	if entries.is_empty():
		entries.append({"text": "Rien à vendre", "dim": true, "detail": "Ce que vous portez sur vous ne se vend pas : il faut d'abord le retirer."})
	_page(_shop_name() + " : vendre", entries, _shop_root.bind(1), focus)


func _sell(item: String, ratio: float, index: int) -> void:
	var gain := GameState.sell(item, ratio)
	if gain <= 0:
		return
	_shop_sell(index)
	_say("Vendu : %s (+%d %s)." % [_item_name(item), gain, GameState.MONEY_NAME])
