extends Control
## Écrans à liste du jeu : équipe et équipement, inventaire, journal de quêtes, boutiques.
## Tous partagent la même présentation : une liste à gauche, le détail de la ligne
## choisie à droite, les écus en haut. Une « page » est une liste d'entrées
##   {"text": "...", "detail": "...", "dim": bool, "action": Callable}
## (« markup » ou « markup_fn » à la place de « detail » : un détail déjà en BBCode, ou une fonction
## qui le construit au moment où la ligne est choisie.)
## et un retour (Callable) appelé par la touche Annuler ; sans retour, l'écran se ferme.

signal closed
signal talents_requested(who: String)   # la fiche d'un personnage demande l'écran de talents

const UI = preload("res://src/ui/ui_kit.gd")
const Rules = preload("res://src/battle/rules.gd")

var _title: Label
var _money: Label
var _list: VBoxContainer
var _detail: RichTextLabel
var _detail_scroll: ScrollContainer
var _message: Label
var _panel: PanelContainer
var _entries: Array = []
var _back: Callable = Callable()
var _opened_at := 0
var _shop: Dictionary = {}
var _focus_index := 0
var _cycle := false            # la page laisse changer de personnage avec gauche / droite (boutique)
var _shop_who := ""            # personnage pour lequel la boutique compare l'équipement


func _ready() -> void:
	UI.full_rect(self)
	visible = false
	var frame := UI.screen(self, "", Vector2(1040, 520), 0.62)
	_panel = frame["panel"]
	_title = frame["title"]
	_money = frame["right"]
	var body: VBoxContainer = frame["body"]

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 22)
	body.add_child(cols)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(450, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	cols.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 1)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	cols.add_child(UI.vline())
	_detail_scroll = ScrollContainer.new()
	_detail_scroll.custom_minimum_size = Vector2(480, 430)
	_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(_detail_scroll)
	_detail = UI.rich(18)
	_detail.fit_content = true
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_scroll.add_child(_detail)

	_message = UI.label("", 20, UI.GOLD, false, true)
	_message.custom_minimum_size = Vector2(0, 28)
	body.add_child(_message)
	(frame["foot"] as HBoxContainer).add_child(UI.hints(UI.KEYS_MENU))


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
	UI.pop(_panel)
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
	elif _cycle and (event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right")):
		get_viewport().set_input_as_handled()
		_cycle_shop_who(1 if event.is_action_pressed("ui_right") else -1)
	elif event.is_action_pressed("ui_page_down") or event.is_action_pressed("ui_page_up"):
		# détail trop long pour la page : on le fait défiler au clavier
		get_viewport().set_input_as_handled()
		_detail_scroll.scroll_vertical += 160 if event.is_action_pressed("ui_page_down") else -160


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
	_cycle = false
	_focus_index = clampi(focus, 0, maxi(0, entries.size() - 1))
	_message.text = ""
	_money.text = "%d %s" % [GameState.money, GameState.MONEY_NAME]
	for c in _list.get_children():
		_list.remove_child(c)
		c.queue_free()
	for i in entries.size():
		var e: Dictionary = entries[i]
		var b := UI.menu_button(str(e.get("text", "")), 21)
		b.custom_minimum_size = Vector2(430, 0)
		b.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		b.clip_text = true
		if e.get("icon") is Texture2D:
			# portrait du personnage devant sa ligne
			b.icon = e["icon"]
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 44)
			b.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			b.custom_minimum_size = Vector2(430, 52)
		if bool(e.get("dim", false)):
			b.add_theme_color_override("font_color", UI.INK_FAINT)
		b.focus_entered.connect(_on_focus.bind(i))
		b.pressed.connect(_on_pressed.bind(i))
		_list.add_child(b)
	_detail.text = ""
	if not entries.is_empty():
		var index := clampi(focus, 0, entries.size() - 1)
		_detail.text = _entry_markup(entries[index] as Dictionary)
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
		_focus_index = index
		_detail.text = _entry_markup(_entries[index] as Dictionary)
		_detail_scroll.scroll_vertical = 0


## Détail d'une ligne, en BBCode.
func _entry_markup(e: Dictionary) -> String:
	var fn: Variant = e.get("markup_fn")
	if fn is Callable and (fn as Callable).is_valid():
		return str((fn as Callable).call())
	if e.has("markup"):
		return str(e["markup"])
	return UI.detail_markup(str(e.get("detail", "")))


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

const STAT_ROWS := ["hp", "mp", "atk", "def", "mag", "res", "spd", "acc", "eva", "crit", "critdmg"]
const SHEET_ROWS := ["atk", "def", "mag", "res", "spd", "acc", "eva", "crit", "critdmg"]
const PERCENT_STATS := ["acc", "eva", "crit", "critdmg"]


static func _item_name(id: String) -> String:
	return str(Database.get_item(id).get("name", id))


## Valeur d'une caractéristique, avec son « % » pour les pourcentages.
static func _fmt(key: String, v: int, signed: bool = false) -> String:
	var sign_text := ""
	if signed:
		sign_text = "+" if v >= 0 else "−"
	var shown := absi(v) if signed else v
	return "%s%d%s" % [sign_text, shown, " %" if PERCENT_STATS.has(key) else ""]


static func _mods_text(item: String) -> String:
	var parts: Array = []
	var mods: Variant = Database.get_item(item).get("mods", {})
	if mods is Dictionary:
		for key: String in Rules.MOD_KEYS:
			if (mods as Dictionary).has(key) and int(mods[key]) != 0:
				parts.append("%s %s" % [str(GameState.STAT_NAMES.get(key, key)), _fmt(key, int(mods[key]), true)])
	return ", ".join(parts)


## Nom d'un genre d'arme ou de tenue (« baton » → « Bâton »).
static func type_name(type: String) -> String:
	var names: Variant = Database.game.get("item_types", {})
	if names is Dictionary:
		return str((names as Dictionary).get(type, type.capitalize()))
	return type.capitalize()


static func _pct(v: float) -> String:
	return "%d %%" % int(round(v * 100.0))


## Les effets permanents d'un objet (champ « passives »), une ligne chacun.
static func passive_lines(item: String) -> Array:
	var out: Array = []
	var p: Variant = Database.get_item(item).get("passives", {})
	if not (p is Dictionary):
		return out
	var d: Dictionary = p
	if d.has("resist"):
		for el: String in d["resist"]:
			out.append("Subit %s de dégâts %s en moins." % [_pct(float(d["resist"][el])), str(Database.elements.get(el, {}).get("name", el)).to_lower()])
	if d.has("status_resist"):
		for st: String in d["status_resist"]:
			var label := "tous les états négatifs" if st == "all" else "« %s »" % str(Database.get_status(st).get("name", st))
			out.append("Résiste à %s : %s de chances en moins." % [label, _pct(float(d["status_resist"][st]))])
	if d.has("immune"):
		var names: Array = []
		for st: Variant in d["immune"]:
			names.append(str(Database.get_status(str(st)).get("name", st)))
		out.append("Insensible à : %s." % ", ".join(names))
	if d.has("regen_hp"):
		out.append("Rend %s des PV maximum au début de chaque tour." % _pct(float(d["regen_hp"])))
	if d.has("regen_mp"):
		out.append("Rend %d PM au début de chaque tour." % int(d["regen_mp"]))
	if d.has("money_bonus"):
		out.append("Écus gagnés au combat : +%s." % _pct(float(d["money_bonus"])))
	if d.has("xp_bonus"):
		out.append("Expérience gagnée : +%s." % _pct(float(d["xp_bonus"])))
	if d.has("initiative"):
		out.append("Joue plus tôt en début de combat (+%s)." % _pct(float(d["initiative"])))
	return out


## Les membres de l'équipe qui peuvent porter cet objet.
static func wearers(item: String) -> Array:
	var out: Array = []
	for id: Variant in GameState.party:
		if GameState.can_equip(str(id), item):
			out.append(str(id))
	return out


## Lignes de description d'un objet d'équipement (sans titre) : genre, bonus, effets, porteurs.
static func equipment_lines(id: String) -> Array:
	var def := Database.get_item(id)
	var lines: Array = []
	var head := str(GameState.SLOT_NAMES.get(str(def.get("slot", "")), "Équipement"))
	if str(def.get("slot", "")) == "trinket":
		head = "Babiole"
	if str(def.get("type", "")) != "":
		head += "   ·   " + type_name(str(def["type"]))
	lines.append(head)
	if _mods_text(id) != "":
		lines.append(_mods_text(id))
	lines.append_array(passive_lines(id))
	if bool(def.get("firm", false)):
		lines.append("Insensible au Ramollissement.")
	var names: Array = []
	for who: String in wearers(id):
		names.append(Database.get_character_name(who))
	var only: Variant = def.get("for")
	var reserved := only is Array and not (only as Array).is_empty()
	if names.is_empty():
		lines.append("Personne dans l'équipe ne peut le porter." if reserved or str(def.get("type", "")) != "" else "")
	else:
		lines.append(("Réservé à : " if reserved else "Peuvent le porter : ") + ", ".join(names))
	for w: Dictionary in GameState.worn_by(id):
		lines.append("Porté par %s." % Database.get_character_name(str(w["who"])))
	return lines


## Description complète d'un objet : texte, genre, bonus, porteurs possibles.
static func item_detail(id: String) -> String:
	var def := Database.get_item(id)
	var lines: Array = [str(def.get("name", id)), "", str(def.get("desc", ""))]
	match Database.item_kind(id):
		"equipment":
			lines.append("")
			lines.append_array(equipment_lines(id))
		"key":
			lines.append("")
			lines.append("Objet de quête.")
		_:
			if not GameState.usable_outside(id):
				lines.append("")
				lines.append("Ne sert qu'en combat.")
	return "\n".join(lines)


## Tableau de caractéristiques, deux par rangée. Avec `after`, chaque case montre « avant → après »,
## en vert si ça monte, en rouge si ça baisse. Avec `bare`, la valeur est suivie de ce que l'équipement ajoute.
static func stats_table(keys: Array, before: Dictionary, after: Dictionary = {}, bare: Dictionary = {}) -> String:
	var out := "[font_size=17][table=4]"
	for r in int(ceil(keys.size() / 2.0)):
		for c in 2:
			var i := r * 2 + c
			if i >= keys.size():
				out += "[cell][/cell][cell][/cell]"
				continue
			var key: String = keys[i]
			var a := int(before.get(key, 0))
			var cell := ""
			if not after.is_empty():
				var b := int(after.get(key, 0))
				if b == a:
					cell = UI.tint(_fmt(key, a), UI.INK_FAINT)
				else:
					var color: Color = UI.GOOD if b > a else UI.WARN
					# « » » et « (+3) » : des signes de la police du jeu (→ et ▲ venaient d'une autre police et décalaient la ligne)
					cell = "%s » %s" % [_fmt(key, a), UI.tint("%s (%s)" % [_fmt(key, b), _fmt(key, b - a, true)], color)]
			else:
				cell = _fmt(key, a)
				if not bare.is_empty() and int(bare.get(key, a)) != a:
					var bonus := a - int(bare.get(key, a))
					cell += " " + UI.tint("(%s)" % _fmt(key, bonus, true), UI.GOOD if bonus > 0 else UI.WARN)
			out += "[cell padding=0,0,10,0]%s[/cell][cell padding=0,0,26,0]%s[/cell]" % [UI.tint(str(GameState.STAT_NAMES.get(key, key)), UI.INK_DIM), cell]
	return out + "[/table][/font_size]"


## Détail d'un objet en BBCode, suivi au besoin d'un bloc déjà mis en forme.
static func item_markup(id: String, extra: String = "") -> String:
	var lines: Array = item_detail(id).split("\n")
	var name_line: String = lines.pop_front()
	return UI.title_markup(name_line, UI.escape_bb("\n".join(lines)) + ("\n" + extra if extra != "" else ""))


## Ce que changerait cet objet pour ce personnage : l'objet remplacé et le tableau avant / après.
static func compare_block(who: String, item: String, slot: String = "") -> String:
	var target := GameState.slot_for(who, item, slot)
	var worn := GameState.equipped(who, target)
	var head := "Pour %s : %s" % [Database.get_character_name(who), str(GameState.SLOT_NAMES.get(target, target)).to_lower()]
	head += "  (remplace : %s)" % _item_name(worn) if worn != "" else "  (emplacement libre)"
	return "[color=#%s]%s[/color]\n%s" % [UI.GOLD_DIM.to_html(false), UI.escape_bb(head), stats_table(STAT_ROWS, GameState.member_stats(who), GameState.stats_with(who, item, slot))]


static func _member_line(id: String) -> String:
	var m := GameState.member(id)
	var stats := GameState.member_stats(id)
	return "%s%s   PV %d/%d   PM %d/%d" % [Database.get_character_name(id), " (réserve)" if GameState.is_reserve(id) else "", int(m["hp"]), int(stats["hp"]), int(m["mp"]), int(stats["mp"])]


## Fiche d'un personnage en BBCode : niveau, PV, caractéristiques (équipement compris), emplacements, compétences.
static func _member_detail(id: String) -> String:
	var ch := Database.get_character(id)
	var m := GameState.member(id)
	var stats := GameState.member_stats(id)
	var bare := Rules.stats_at(id, int(m["level"]))
	var lines: Array = []
	lines.append("%s   ·   Niveau %d   ·   XP %d / %d" % [str(ch.get("role", "")).capitalize(), int(m["level"]), int(m["xp"]), Rules.xp_to_next(int(m["level"]))])
	if GameState.is_reserve(id):
		lines.append("En réserve : ne se bat pas et ne gagne pas l'expérience des combats.")
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
	var body := UI.escape_bb("\n".join(lines)) + "\n" + stats_table(SHEET_ROWS, stats, {}, bare) + "\n"
	var slots: Array = []
	for slot: String in GameState.SLOTS:
		var worn := GameState.equipped(id, slot)
		slots.append("%s : %s" % [str(GameState.SLOT_NAMES[slot]), _item_name(worn) if worn != "" else "—"])
	var skills: Array = []
	for s: Variant in GameState.member_skills(id):
		skills.append(str(Database.get_skill(str(s)).get("name", s)))
	var tail := "\n".join(slots)
	if not skills.is_empty():
		tail += "\n\nCompétences : " + ", ".join(skills)
	return UI.title_markup(str(ch.get("full_name", ch.get("name", id))), body + UI.escape_bb(tail))


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
			"icon": Sprites.portrait(str(id)),
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
		var worn := GameState.equipped(who, GameState.slot_for(who, item))
		entries.append({
			"text": "%s   (%s)" % [Database.get_character_name(who), _item_name(worn) if worn != "" else "rien"],
			"markup_fn": _equip_markup.bind(who, item, ""),
			"action": _equip_from_bag.bind(who, item, from),
		})
	if entries.is_empty():
		_say("Personne dans l'équipe ne peut s'en servir.", false)
		return
	_page("Équiper qui ?", entries, _inventory.bind(from))


## Détail d'un objet d'équipement pour un personnage : description, puis comparaison avant / après.
func _equip_markup(who: String, item: String, slot: String) -> String:
	return item_markup(item, "\n" + compare_block(who, item, slot))


func _equip_from_bag(who: String, item: String, from: int) -> void:
	if GameState.equip(who, item):
		_inventory(from)
		_say("%s s'équipe : %s." % [Database.get_character_name(who), _item_name(item)])


# -------------------------------------------------------------------- équipe

func _team(focus: int = 0) -> void:
	var entries: Array = []
	for id: Variant in GameState.party:
		var who := str(id)
		var reserve := GameState.is_reserve(who)
		var text := "%s   %s" % [Database.get_character_name(who), "réserve" if reserve else "Nv %d" % int(GameState.member(who)["level"])]
		var points := GameState.talent_points(who)
		if points > 0:
			text += "  ·  %d pt%s" % [points, "s" if points > 1 else ""]
		entries.append({
			"text": text,
			"icon": Sprites.portrait(who),
			"dim": reserve,
			"markup_fn": _member_detail.bind(who),
			"action": _member.bind(who, entries.size(), 0),
		})
	var title := "Équipe"
	if not GameState.reserve_party().is_empty():
		title = "Équipe   ·   %d au combat, %d en réserve" % [GameState.active_party().size(), GameState.reserve_party().size()]
	_page(title, entries, Callable(), focus)


## Fiche d'un personnage : de là, on règle son équipement ou ses talents, ou on l'échange.
func _member(who: String, from: int, focus: int = 0) -> void:
	var points := GameState.talent_points(who)
	var entries: Array = [
		{"text": "Équipement", "markup_fn": _member_detail.bind(who), "action": _gear.bind(who, from, 0)},
		{
			"text": "Talents" + ("   ·   %s à dépenser" % _points(points) if points > 0 else ""),
			"detail": _talents_summary(who),
			"action": func() -> void: talents_requested.emit(who),
		},
	]
	if not GameState.reserve_party().is_empty():
		var reserve := GameState.is_reserve(who)
		entries.append({
			"text": "Entrer dans l'équipe" if reserve else "Passer en réserve",
			"detail": ("Prend la place d'un des quatre qui se battent." if reserve else "Cède sa place à un personnage de la réserve.") + "\n\nQuatre personnages au plus se battent en même temps.",
			"action": _swap_targets.bind(who, from),
		})
	_page(Database.get_character_name(who), entries, _team.bind(from), focus)


## Choix de celui qui prend la place de `who` (un réserviste pour un combattant, et inversement).
func _swap_targets(who: String, from: int) -> void:
	var entries: Array = []
	var ids: Array = GameState.active_party() if GameState.is_reserve(who) else GameState.reserve_party()
	for id: Variant in ids:
		var other := str(id)
		entries.append({
			"text": "%s   Nv %d" % [Database.get_character_name(other), int(GameState.member(other)["level"])],
			"icon": Sprites.portrait(other),
			"markup_fn": _member_detail.bind(other),
			"action": _do_swap.bind(who, other),
		})
	_page("Échanger %s avec…" % Database.get_character_name(who), entries, _member.bind(who, from, 2))


func _do_swap(who: String, other: String) -> void:
	if not GameState.swap_members(who, other):
		_say("%s ne peut pas quitter la tête de l'équipe." % Database.get_character_name(who if GameState.party.find(who) == 0 else other), false)
		return
	var focus := GameState.party.find(who)
	_team(focus)
	_say("%s et %s échangent leur place." % [Database.get_character_name(who), Database.get_character_name(other)])


# ------------------------------------------------------------------- talents

static func _points(n: int) -> String:
	return "%d point%s" % [n, "s" if n > 1 else ""]


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


func _gear(who: String, from: int, focus: int = 0) -> void:
	var entries: Array = []
	for slot: String in GameState.SLOTS:
		var worn := GameState.equipped(who, slot)
		entries.append({
			"text": "%s : %s" % [str(GameState.SLOT_NAMES[slot]), _item_name(worn) if worn != "" else "—"],
			"markup_fn": _slot_markup.bind(who, slot),
			"action": _slot_choices.bind(who, slot, from, entries.size()),
		})
	_page("Équipement de %s" % Database.get_character_name(who), entries, _member.bind(who, from, 0), focus)


## Détail d'un emplacement : l'objet porté, puis les caractéristiques du personnage.
func _slot_markup(who: String, slot: String) -> String:
	var worn := GameState.equipped(who, slot)
	var sheet := _member_detail(who)
	var cut := sheet.find("\n")
	var sheet_body := sheet.substr(cut + 1)
	if worn == "":
		return UI.title_markup(str(GameState.SLOT_NAMES[slot]), "Rien d'équipé.\n \n" + sheet_body)
	return item_markup(worn, "\n" + sheet_body)


## Objets qui peuvent aller dans cet emplacement pour ce personnage : ceux du sac, puis ceux que
## d'autres membres de l'équipe portent (les lui prendre les laisse les mains vides), puis « Retirer ».
func _slot_choices(who: String, slot: String, from: int, slot_index: int) -> void:
	var entries: Array = []
	for id: Variant in _sorted_items():
		var item := str(id)
		if not GameState.slots_for(item).has(slot) or not GameState.can_equip(who, item):
			continue
		entries.append({
			"text": "%s   ×%d" % [_item_name(item), GameState.item_count(item)],
			"markup_fn": _equip_markup.bind(who, item, slot),
			"action": _equip_slot.bind(who, item, slot, from, slot_index),
		})
	var seen := {}
	for other: Variant in GameState.party:
		if str(other) == who:
			continue
		for slot2: String in GameState.SLOTS:
			var item2 := GameState.equipped(str(other), slot2)
			if item2 == "" or seen.has(item2 + str(other)) or not GameState.slots_for(item2).has(slot) or not GameState.can_equip(who, item2):
				continue
			seen[item2 + str(other)] = true
			entries.append({
				"text": "%s   (porté par %s)" % [_item_name(item2), Database.get_character_name(str(other))],
				"dim": true,
				"markup_fn": _equip_markup.bind(who, item2, slot),
				"action": _take_from.bind(who, str(other), slot2, slot, from, slot_index),
			})
	if GameState.equipped(who, slot) != "":
		entries.append({
			"text": "Retirer : %s" % _item_name(GameState.equipped(who, slot)),
			"markup_fn": _remove_markup.bind(who, slot),
			"action": _unequip_slot.bind(who, slot, from, slot_index),
		})
	if entries.is_empty():
		_say("Rien dans le sac ne convient.", false)
		return
	_page("%s de %s" % [str(GameState.SLOT_NAMES[slot]), Database.get_character_name(who)], entries, _gear.bind(who, from, slot_index))


func _remove_markup(who: String, slot: String) -> String:
	var worn := GameState.equipped(who, slot)
	var block := "[color=#%s]Pour %s : retirer cet objet[/color]\n%s" % [UI.GOLD_DIM.to_html(false), UI.escape_bb(Database.get_character_name(who)), stats_table(STAT_ROWS, GameState.member_stats(who), GameState.stats_with(who, "", slot))]
	return item_markup(worn, "\nRemet l'objet dans le sac.\n" + block)


func _equip_slot(who: String, item: String, slot: String, from: int, slot_index: int) -> void:
	if GameState.equip(who, item, slot):
		_gear(who, from, slot_index)
		_say("%s s'équipe : %s." % [Database.get_character_name(who), _item_name(item)])


## Prend un objet porté par un autre membre de l'équipe : il retourne au sac, puis est équipé.
func _take_from(who: String, holder: String, holder_slot: String, slot: String, from: int, slot_index: int) -> void:
	var item := GameState.equipped(holder, holder_slot)
	if item == "" or not GameState.unequip(holder, holder_slot):
		return
	if GameState.equip(who, item, slot):
		_gear(who, from, slot_index)
		_say("%s prend %s à %s." % [Database.get_character_name(who), _item_name(item), Database.get_character_name(holder)])
	else:
		GameState.equip(holder, item, holder_slot)


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
			"markup_fn": _shop_markup.bind(item),
			"action": _buy.bind(offer, entries.size()),
		})
	if entries.is_empty():
		entries.append({"text": "Plus rien à vendre", "dim": true, "detail": ""})
	_page(_shop_name() + " : acheter", entries, _shop_root.bind(0), focus)
	_cycle = true


## Détail d'un article : description, comparaison pour le personnage choisi (gauche / droite en change).
func _shop_markup(item: String) -> String:
	var owned := GameState.item_count(item)
	var tail := "\n \nDans le sac : %d" % owned
	if Database.item_kind(item) != "equipment":
		return item_markup(item, tail)
	var able := wearers(item)
	if able.is_empty():
		return item_markup(item, tail)
	if not able.has(_shop_who):
		_shop_who = str(able[0])
	var extra := "\n" + compare_block(_shop_who, item) + tail
	if able.size() > 1:
		extra += "\n" + UI.tint("◄ ►  pour comparer avec un autre personnage", UI.INK_FAINT)
	return item_markup(item, extra)


## Gauche / droite en boutique : passe au personnage suivant qui peut porter l'article choisi.
func _cycle_shop_who(step: int) -> void:
	var offers := shop_offers()
	if _focus_index >= offers.size():
		return
	var item := str((offers[_focus_index] as Dictionary)["item"])
	var able := wearers(item)
	if able.size() < 2:
		return
	var at := able.find(_shop_who)
	_shop_who = str(able[posmod(at + step, able.size())])
	Sfx.play("move")
	_detail.text = _shop_markup(item)


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
