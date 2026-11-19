extends Node
## Conseils de jeu (autoload `Tutorial`) : explique chaque système UNE fois, au moment où il sert.
## Tout vient de data/tutorials.json (voir docs/FORMAT_DONNEES.md) : ajouter un conseil ne demande
## aucun code, seulement un appel `Tutorial.fire("evenement")` à l'endroit du jeu où il se produit
## (ou un événement déjà existant).
##
## Deux sortes de conseils :
##  - « note » (par défaut) : un encart en bas à droite, qui ne bloque rien, s'efface seul et
##    attend en coulisse tant qu'un dialogue, un menu ou un combat occupe l'écran ;
##  - « pause » (`"mode": "pause"`) : au cœur d'un combat ou d'une boutique, un encart au centre qui
##    suspend le jeu jusqu'à ce qu'on appuie sur une touche (`fire_wait`, à `await`).
## Les conseils vus sont rangés dans `GameState.tutorials_seen` (donc dans la sauvegarde).
## Réglage « Conseils de jeu » : désactivé, rien ne s'affiche (et rien n'est marqué comme vu).
## Les tests et les captures tournent sans conseils, sauf `force_on` (et `modal_in_tests`).

const TipPanel = preload("res://src/ui/tutorial_panel.gd")
const HelpScreen = preload("res://src/ui/help_screen.gd")
const UI = preload("res://src/ui/ui_kit.gd")
const BattleUI = preload("res://src/battle/battle_ui.gd")   # lecture seule : places libres de l'écran de combat
const FILE := "res://data/tutorials.json"
const NOTE_SECONDS := 8.0       # durée d'un conseil de passage (plus la lecture)
const NOTE_GAP := 0.8           # pause entre deux conseils de passage
const MODAL_GUARD := 0.4        # une touche tapée trop tôt ne ferme pas un conseil qui vient d'apparaître
const CTX_TERMS := ["elan", "shield", "ally_down", "boss"]   # termes de « when » fournis par le combat

var tips: Array = []                 # conseils, dans l'ordre du fichier
var by_id: Dictionary = {}
var problems: Array = []             # erreurs de lecture du fichier (vérifiées par les tests)
var host: Node = null                # main.gd, pour savoir si l'écran est libre
var help = null                      # page d'aide (pause)
var force_on := false                # tests : conseils actifs malgré tout
var modal_in_tests := false          # tests : les conseils « pause » s'affichent aussi
var pad: bool:                       # la dernière entrée venait de la manette (source : Controls)
	get:
		return Controls.pad
	set(value):
		Controls.set_pad(value)
var shown_log: Array = []            # identifiants affichés depuis le lancement (tests)
var current := ""                    # conseil de passage à l'écran

var _layer: CanvasLayer
var _veil: ColorRect
var _panel: PanelContainer
var _queue: Array = []
var _timer := 0.0
var _gap := 0.0
var _modal := false
var _guard := 0.0
var _tween: Tween
var _by_trigger: Dictionary = {}
var _pointer: Control               # surbrillance et flèche vers ce dont parle un conseil de combat
var _aim := Rect2()                 # rectangle visé (coordonnées d'écran), vide si le conseil ne vise rien
var _modal_view: Dictionary = {}    # contenu du conseil de combat affiché (pour le redimensionner)
var _modal_points := ""
var _spot_dirty := true
var _height_hint := 0.0   # hauteur réellement prise par l'encart une fois disposé (le minimum calculé d'avance peut être court)
var _pulse := 0.0

signal _closed


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_tips()
	_layer = CanvasLayer.new()
	_layer.layer = 5
	add_child(_layer)
	_veil = ColorRect.new()
	_veil.color = Color(0.0, 0.0, 0.03, 0.4)
	_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_veil.visible = false
	_layer.add_child(_veil)
	_pointer = Control.new()
	_pointer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pointer.visible = false
	_pointer.draw.connect(_draw_pointer)
	_layer.add_child(_pointer)
	_panel = TipPanel.new()
	_panel.visible = false
	_layer.add_child(_panel)


# ----------------------------------------------------------------------- données

func load_tips() -> void:
	tips = []
	by_id = {}
	problems = []
	_by_trigger = {}
	var f := FileAccess.open(FILE, FileAccess.READ)
	if f == null:
		problems.append("data/tutorials.json introuvable")
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if not (parsed is Dictionary) or not ((parsed as Dictionary).get("tips") is Array):
		problems.append("data/tutorials.json : « tips » manquant")
		return
	for t: Variant in (parsed as Dictionary)["tips"]:
		if not (t is Dictionary) or str((t as Dictionary).get("id", "")) == "" or by_id.has(str((t as Dictionary)["id"])):
			problems.append("conseil sans identifiant ou en double")
			continue
		var tip: Dictionary = t
		tips.append(tip)
		by_id[str(tip["id"])] = tip
		var trig := str(tip.get("trigger", ""))
		if not _by_trigger.has(trig):
			_by_trigger[trig] = []
		(_by_trigger[trig] as Array).append(str(tip["id"]))


## Branchement par main.gd : page d'aide dans le menu de pause, et accès à l'écran.
func install(main: Node, ui_layer: Node) -> void:
	host = main
	help = HelpScreen.new()
	ui_layer.add_child(help)
	var pause = main.pause
	pause.add_entry("Aide", func() -> void:
		pause.close(true)
		help.open())
	help.closed.connect(func() -> void:
		if bool(main.get("mode") == 2) and main.world != null and not main.busy:
			main._open_pause())


func help_open() -> bool:
	return is_instance_valid(help) and help.visible


# ------------------------------------------------------------------- conseils vus

func is_seen(id: String) -> bool:
	return GameState.tutorials_seen.has(id)


func mark_seen(id: String) -> void:
	GameState.tutorials_seen[id] = true


func seen_ids() -> Array:
	var out: Array = []
	for t: Dictionary in tips:
		if is_seen(str(t["id"])):
			out.append(str(t["id"]))
	return out


## « Revoir les conseils » : tous redeviennent inédits.
func reset_seen() -> void:
	GameState.tutorials_seen = {}
	_queue.clear()
	current = ""
	if _panel != null and not _modal:
		_panel.visible = false


## Anciennes sauvegardes : aucun conseil n'est rejoué sur une partie déjà avancée.
func all_seen() -> Dictionary:
	var out := {}
	for t: Dictionary in tips:
		out[str(t["id"])] = true
	return out


func enabled() -> bool:
	if Settings.testing and not force_on:
		return false
	return bool(Settings.get_value("conseils"))


func modal_ok() -> bool:
	return host != null and is_instance_valid(host) and (not Settings.testing or modal_in_tests)


# ------------------------------------------------------------------ déclenchement

## Conseil de passage : à appeler (une ligne) à l'endroit où l'événement se produit.
## Renvoie les identifiants mis en file. Les conseils « pause » sont ignorés ici.
func fire(event: String, ctx: Dictionary = {}) -> Array:
	var out: Array = []
	if not enabled() or not _by_trigger.has(event) and event != "item":
		return out
	if event == "item" and not GameState.slots_for(str(ctx.get("id", ""))).is_empty():
		return fire("equip_item", ctx)
	for id: String in _matching(event, ctx, false):
		mark_seen(id)
		_queue.append(id)
		out.append(id)
	return out


## Conseil qui suspend le jeu : à `await`. Un seul à la fois, les suivants attendront leur tour.
func fire_wait(event: String, ctx: Dictionary = {}) -> void:
	if not enabled() or not modal_ok() or not _by_trigger.has(event):
		return
	for id: String in _matching(event, ctx, true):
		var tip: Dictionary = by_id[id]
		mark_seen(id)
		if str(tip.get("mode", "note")) != "pause":
			_queue.append(id)
			continue
		await _show_modal(tip)
		return


## Événement de combat : prépare le contexte (tour, élan, bouclier...) puis `fire_wait`.
## Rien dans une scène jouée toute seule (tests, captures) ni dans le combat guidé du prologue.
func battle_event(event: String, scene: Node, actor: RefCounted = null) -> void:
	if not enabled() or not modal_ok() or scene == null or not _by_trigger.has(event):
		return
	if bool(scene.get("auto")) or bool(scene.get("fast")):
		return
	var eng: RefCounted = scene.get("engine")
	var enc: Dictionary = scene.get("encounter")
	if eng == null or bool(eng.get("guest")) or (enc.get("hints") is Array and not (enc["hints"] as Array).is_empty()):
		return
	var shield := false
	for e: RefCounted in eng.call("living", "enemy"):
		if int(e.get("shield_max")) > 0:
			shield = true
	await fire_wait(event, {
		"turn": int(eng.get("party_turns")),
		"elan": actor != null and int(actor.get("elan")) > 0,
		"shield": shield,
		"ally_down": not (eng.call("fallen", "party") as Array).is_empty(),
		"boss": not bool(eng.get("can_flee")),
	})


func _matching(event: String, ctx: Dictionary, with_modal: bool) -> Array:
	var out: Array = []
	for id: String in _by_trigger.get(event, []):
		var tip: Dictionary = by_id[id]
		if is_seen(id) or _queue.has(id):
			continue
		if not with_modal and str(tip.get("mode", "note")) == "pause":
			continue
		if not when_ok(str(tip.get("when", "")), ctx):
			continue
		out.append(id)
	return out


## Condition `when` : termes reliés par « & » ; « turn>=N », un terme du combat (elan, shield,
## ally_down, boss), ou une condition de GameState.check (drapeau, party:sam...).
func when_ok(when: String, ctx: Dictionary) -> bool:
	for part: String in when.split("&"):
		var term := part.strip_edges()
		if term == "":
			continue
		var negate := term.begins_with("!")
		if negate:
			term = term.substr(1).strip_edges()
		var ok := false
		if term.begins_with("turn>="):
			ok = int(ctx.get("turn", 0)) >= int(term.substr(6))
		elif CTX_TERMS.has(term):
			ok = bool(ctx.get(term, false))
		else:
			ok = GameState.check(term)
		if ok == negate:
			return false
	return true


# ----------------------------------------------------------------- affichage

## L'écran est libre pour un conseil de passage (ou pour le rappel de quête).
func explore_open() -> bool:
	if host == null or not is_instance_valid(host):
		return false
	var h: Node = host
	if int(h.get("mode")) != 2 or h.get("world") == null or h.get("battle") != null or bool(h.get("busy")):
		return false
	var d: Variant = h.get("dialogue")
	if d.active:
		return false
	for n: String in ["pause", "menus", "talents", "saves", "settings_screen"]:
		var screen: Variant = h.get(n)
		if screen.visible:
			return false
	return not help_open()


func _process(delta: float) -> void:
	_guard -= delta
	_gap -= delta
	if _modal:
		_place(true)
		_pulse += delta
		if _pointer.visible:
			_pointer.modulate.a = 0.72 + 0.28 * sin(_pulse * 4.5)
			_pointer.queue_redraw()
		return
	if current != "":
		if not explore_open():
			_panel.visible = false   # un dialogue, un menu ou un combat passe devant : on patiente
			return
		_panel.visible = true
		_place(false)
		_timer -= delta
		if _timer <= 0.0:
			current = ""
			_panel.visible = false
			_gap = NOTE_GAP
		return
	if not _queue.is_empty() and _gap <= 0.0 and explore_open():
		_show_note(str(_queue.pop_front()))


func _show_note(id: String) -> void:
	var tip: Dictionary = by_id[id]
	var view := resolve(tip)
	view["modal"] = false
	(_panel as TipPanel).build(view)
	current = id
	shown_log.append(id)
	_timer = NOTE_SECONDS + 0.04 * str(view["text"]).length()
	_fade_in()
	_place(false)


func _show_modal(tip: Dictionary) -> void:
	var view := resolve(tip)
	view["modal"] = true
	_modal_view = view
	_modal_points = str(tip.get("points", ""))
	_spot_dirty = true
	_height_hint = 0.0
	(_panel as TipPanel).build(view)
	_veil.visible = true
	_modal = true
	_guard = MODAL_GUARD
	shown_log.append(str(tip["id"]))
	_panel.visible = true
	_fade_in()
	_place(true)
	for _pass in 2:   # une fois disposé, l'encart peut être plus haut que prévu : on le replace avec sa vraie hauteur
		await get_tree().process_frame
		if not _modal:
			break
		if _panel.size.y > _panel.get_combined_minimum_size().y + 1.0 and _panel.size.y > _height_hint + 1.0:
			_height_hint = _panel.size.y
			_spot_dirty = true
			_place(true)
	await _closed
	_modal = false
	_panel.visible = false
	_pointer.visible = false
	_aim = Rect2()
	_veil.visible = false
	Sfx.play("confirm")


func _fade_in() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_panel.modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.3)


## Rectangle (à l'écran) occupé par l'encart, ou rien s'il est caché.
func panel_rect() -> Rect2:
	return Rect2(_panel.position, _panel.size) if _panel != null and _panel.visible else Rect2()


func _place(modal: bool) -> void:
	var view := get_viewport().get_visible_rect().size
	_panel.size = _panel.get_combined_minimum_size()
	if modal:
		if _spot_dirty or _panel.position == Vector2.ZERO:
			_spot_dirty = false
			_panel.position = _battle_spot(view)
			_pointer.visible = _aim.size != Vector2.ZERO
			_pointer.queue_redraw()
	else:
		_panel.position = (view - _panel.size - Vector2(26.0, 26.0)).round()


## Place d'un conseil de combat : une place qui ne couvre ni combattant, ni plaque, ni fiche d'équipe,
## ni frise, ni ce que le conseil désigne, la plus proche du haut de l'écran sous la frise (et de ce qu'il
## désigne). On essaie d'abord de laisser libre aussi le menu de combat, puis une version plus étroite de
## l'encart ; BattleUI.free_spot ne sert qu'en dernier recours. Hors combat (boutique) : sous la frise, au centre.
func _battle_spot(view: Vector2) -> Vector2:
	_aim = Rect2()
	var prefer := Vector2((view.x - _panel.size.x) * 0.5, BattleUI.TOP_BAND_H + 4.0)
	var ui: Variant = host.get("battle_ui") if host != null and is_instance_valid(host) else null
	if host == null or host.get("battle") == null or ui == null or not (ui as Object).has_method("_obstacles"):
		return Vector2(prefer.x, view.y * 0.19).round()
	var obstacles: Array[Rect2] = []
	for o: Rect2 in (ui as Object).call("_obstacles", view):
		if not (o.position == Vector2.ZERO and o.size.x >= view.x - 1.0):   # les bandes pleine largeur (haut, bas) : remplacées ci-dessous
			obstacles.append(o)
	obstacles.append(BattleUI.top_band(view))
	_aim = target_rect(_modal_points)
	if _aim.size != Vector2.ZERO:
		obstacles.append(_aim.grow(14.0))
	var with_menu: Array[Rect2] = obstacles.duplicate()
	for n: String in ["_root_panel", "_list_panel"]:
		var menu: Variant = (ui as Object).get(n)
		if menu is Control and (menu as Control).is_visible_in_tree():
			with_menu.append((menu as Control).get_global_rect().grow(6.0))
	for width: float in [TipPanel.WIDTH_MODAL, 560.0, 470.0]:
		if int(_panel.custom_minimum_size.x) != int(width):
			_modal_view["width"] = width
			(_panel as TipPanel).build(_modal_view)
			_panel.size = _panel.get_combined_minimum_size()
		for obs: Array[Rect2] in [with_menu, obstacles]:
			var spot: Variant = _clear_spot(Vector2(_panel.size.x, maxf(_panel.size.y, _height_hint)), prefer, obs, _aim, view)
			if spot != null:
				return (spot as Vector2).round()
	# dernier recours avant le repli : on accepte de couvrir un combattant, jamais une plaque, la fiche d'équipe,
	# la frise, l'indication de touches ni ce que le conseil désigne
	var essential: Array[Rect2] = [BattleUI.top_band(view)]
	if _aim.size != Vector2.ZERO:
		essential.append(_aim.grow(14.0))
	var plates: Variant = (ui as Object).get("_plates")
	if plates is Dictionary:
		for key: Variant in plates:
			var root: Control = (plates[key] as Dictionary)["root"]
			if root.visible:
				essential.append(Rect2(root.position, root.size).grow(8.0))
	var party: Variant = (ui as Object).get("_party_panel")
	if party is Control:
		essential.append((party as Control).get_global_rect().grow(8.0))
	for n: String in ["_root_panel", "_list_panel"]:
		var menu: Variant = (ui as Object).get(n)
		if menu is Control and (menu as Control).is_visible_in_tree():
			essential.append((menu as Control).get_global_rect().grow(6.0))
	var hint: Variant = (ui as Object).get("_hint")
	if hint is Control and (hint as Control).visible:
		essential.append((hint as Control).get_global_rect().grow(6.0))
	for width: float in [_modal_view.get("width", TipPanel.WIDTH_MODAL), 560.0, 470.0]:
		if int(_panel.custom_minimum_size.x) != int(width):
			_modal_view["width"] = width
			(_panel as TipPanel).build(_modal_view)
			_panel.size = _panel.get_combined_minimum_size()
		var spot2: Variant = _clear_spot(Vector2(_panel.size.x, maxf(_panel.size.y, _height_hint)), prefer, essential, _aim, view)
		if spot2 != null:
			return (spot2 as Vector2).round()
	return BattleUI.free_spot(_panel.size, prefer, obstacles, view).round()


## Place (au pas de 8 px) qui ne recoupe aucun obstacle ; la plus proche de « prefer » et de la cible.
## Renvoie null s'il n'y en a pas.
static func _clear_spot(size: Vector2, prefer: Vector2, obstacles: Array[Rect2], aim: Rect2, view: Vector2) -> Variant:
	var best: Variant = null
	var best_score := INF
	var y := 8.0
	while y <= view.y - size.y - 8.0:
		var x := 8.0
		while x <= view.x - size.x - 8.0:
			var r := Rect2(x, y, size.x, size.y)
			var free := true
			for o: Rect2 in obstacles:
				if r.intersects(o):
					free = false
					break
			if free:
				var score := Vector2(x, y).distance_to(prefer)
				if aim.size != Vector2.ZERO:
					score += r.get_center().distance_to(aim.get_center()) * 0.6
				if score < best_score:
					best_score = score
					best = Vector2(x, y)
			x += 8.0
		y += 8.0
	return best


## Rectangle d'écran de ce qu'un conseil désigne : « frise » (ordre des tours), « elan » (pastilles
## dorées), « bouclier » (le bouclier d'un ennemi), « allie » (la fiche d'un allié à terre). Vide sinon.
func target_rect(kind: String) -> Rect2:
	var ui: Variant = host.get("battle_ui") if host != null and is_instance_valid(host) else null
	if ui == null or kind == "" or (ui as Object).get("engine") == null:
		return Rect2()
	var eng: RefCounted = (ui as Object).get("engine")
	match kind:
		"frise":
			var tl: Control = (ui as Object).get("_timeline")
			var tag: Control = (ui as Object).get("_turn_tag")
			return tl.get_global_rect().merge(tag.get_global_rect()).grow(6.0)
		"elan":
			for b: Variant in (ui as Object).get("_elan_bars"):
				var panel: Control = (b as Dictionary)["panel"]
				if panel.is_visible_in_tree():
					return panel.get_global_rect().grow(4.0)
			var actor: Variant = (ui as Object).get("_actor")
			var rows: Dictionary = (ui as Object).get("_rows")
			if actor != null and rows.has((actor as Object).get("key")):
				return ((rows[(actor as Object).get("key")] as Dictionary)["pips"] as Control).get_global_rect().grow(4.0)
		"bouclier":
			var plates: Dictionary = (ui as Object).get("_plates")
			var pick: RefCounted = null
			for e: RefCounted in eng.call("living", "enemy"):
				if int(e.get("shield_max")) > 0 and plates.has(e.get("key")):
					if pick == null or (int(e.get("shield")) == 0 and int(pick.get("shield")) > 0):
						pick = e
			if pick != null:
				var chips: Control = (plates[pick.get("key")] as Dictionary)["chips"]
				return chips.get_global_rect().grow(5.0)
		"allie":
			var rows2: Dictionary = (ui as Object).get("_rows")
			for c: RefCounted in eng.call("fallen", "party"):
				if rows2.has(c.get("key")):
					return ((rows2[c.get("key")] as Dictionary)["card"] as Control).get_global_rect().grow(3.0)
	return Rect2()


func _draw_pointer() -> void:
	if _aim.size == Vector2.ZERO or not _panel.visible:
		return
	var box := StyleBoxFlat.new()
	box.bg_color = Color(UI.GOLD, 0.08)
	box.border_color = UI.GOLD
	box.set_border_width_all(2)
	box.set_corner_radius_all(7)
	_pointer.draw_style_box(box, _aim)
	# flèche : du bord de l'encart le plus proche jusqu'au bord de la cible
	var panel := Rect2(_panel.position, _panel.size)
	var from := Vector2(clampf(_aim.get_center().x, panel.position.x + 12.0, panel.end.x - 12.0), clampf(_aim.get_center().y, panel.position.y, panel.end.y))
	if panel.has_point(from):
		from.y = panel.position.y if _aim.get_center().y < panel.get_center().y else panel.end.y
	var to := Vector2(clampf(from.x, _aim.position.x, _aim.end.x), clampf(from.y, _aim.position.y, _aim.end.y))
	var dir := (to - from)
	if dir.length() < 6.0:
		return
	dir = dir.normalized()
	var tip := to - dir * 2.0
	var side := Vector2(-dir.y, dir.x)
	_pointer.draw_line(from, tip - dir * 8.0, Color(UI.GOLD, 0.9), 2.0, true)
	_pointer.draw_colored_polygon(PackedVector2Array([tip, tip - dir * 14.0 + side * 7.0, tip - dir * 14.0 - side * 7.0]), UI.GOLD)


func _input(event: InputEvent) -> void:
	if not _modal or _guard > 0.0:
		return
	var press := event.is_pressed() and not event.is_echo()
	if press and (event.is_action("interact") or event.is_action("cancel") or event.is_action("menu") or event.is_action("ui_accept") or event is InputEventMouseButton):
		get_viewport().set_input_as_handled()
		_closed.emit()


## Ferme tout de suite l'encart de passage (changement de partie, tests).
func clear() -> void:
	_queue.clear()
	current = ""
	if _panel != null:
		_panel.visible = false
	if _modal:
		_closed.emit()


# ---------------------------------------------------------- texte et touches

## Contenu affichable d'un conseil : qui parle, texte avec ses touches, lignes de touches.
func resolve(tip: Dictionary) -> Dictionary:
	var rows: Array = []
	for k: Variant in tip.get("keys", []):
		rows.append({"caps": caps_for(str((k as Array)[0])), "verb": str((k as Array)[1])})
	return {
		"id": str(tip.get("id", "")),
		"title": str(tip.get("title", "")),
		"text": expand(str(tip.get("text", ""))),
		"tag": speaker_tag(tip.get("who", "")),
		"rows": rows,
		"dismiss": caps_for("interact"),
	}


## Remplace {interact}, {menu}... par le nom de la touche (clavier ou manette).
func expand(text: String) -> String:
	var out := text
	for name: String in ["move", "interact", "cancel", "menu", "journal", "elan", "choose"]:
		if out.contains("{" + name + "}"):
			var caps := caps_for(name)
			out = out.replace("{" + name + "}", str(caps[0]) if not caps.is_empty() else name)
	return out


## « Glandoulf, à contrecœur » : le premier de la liste `who` qui est dans l'équipe, sinon le dernier.
func speaker_tag(who: Variant) -> String:
	var list: Array = who if who is Array else ([who] if str(who) != "" else [])
	if list.is_empty():
		return "Conseil"
	var pick := str(list[list.size() - 1])
	for w: Variant in list:
		if GameState.party.has(str(w)):
			pick = str(w)
			break
	var name := Database.get_character_name(pick)
	return "%s explique%s" % [name, ", à contrecœur" if pick == "glandoulf" else ""]


## Touches d'une commande, dans l'ordre d'affichage, avec « ou » entre deux possibilités.
func caps_for(action: String) -> Array:
	match action:
		"elan":
			return ["dpad_lr"] if pad else ["Gauche", "Droite"]
		"choose":
			return ["dpad_ud"] if pad else ["Haut", "Bas"]
		"move":
			if pad:
				return ["Stick gauche", "ou", "Croix"]
			return ["Flèches", "ou", " ".join([_phys_name(KEY_W), _phys_name(KEY_A), _phys_name(KEY_S), _phys_name(KEY_D)])]
	if not InputMap.has_action(action):
		return [action]
	var names: Array = []
	var phys_name := ""
	for ev: InputEvent in InputMap.action_get_events(action):
		if pad and ev is InputEventJoypadButton:
			names.append(_pad_name((ev as InputEventJoypadButton).button_index))
		elif not pad and ev is InputEventKey:
			var k := ev as InputEventKey
			if k.keycode != 0:
				names.append(_key_name(k.keycode))
			elif phys_name == "":
				phys_name = _phys_name(k.physical_keycode)
	var first := ""
	var second := ""
	if not names.is_empty():
		first = str(names[0])
	if pad:
		return [first] if first != "" else [action]
	second = phys_name if phys_name != "" else (str(names[names.size() - 1]) if names.size() > 1 else "")
	if first == "":
		return [second] if second != "" else [action]
	if second != "" and second != first:
		return [first, "ou", second]
	return [first]


static func _key_name(code: int) -> String:
	match code:
		KEY_ENTER, KEY_KP_ENTER:
			return "Entrée"
		KEY_SPACE:
			return "Espace"
		KEY_ESCAPE:
			return "Échap"
		KEY_TAB:
			return "Tab"
		KEY_BACKSPACE:
			return "Retour"
		KEY_LEFT:
			return "Gauche"
		KEY_RIGHT:
			return "Droite"
		KEY_UP:
			return "Haut"
		KEY_DOWN:
			return "Bas"
	return OS.get_keycode_string(code as Key)


## Nom d'une touche physique tel que le clavier de l'auteur l'affiche (W devient Z en AZERTY).
static func _phys_name(code: int) -> String:
	var label: Key = code as Key
	if DisplayServer.get_name() != "headless":   # sans fenêtre, pas de clavier à interroger
		label = DisplayServer.keyboard_get_label_from_physical(code as Key)
		if (label as int) == 0:
			label = code as Key
	return _key_name(label as int)


static func _pad_name(button: int) -> String:
	match button:
		JOY_BUTTON_A:
			return "A"
		JOY_BUTTON_B:
			return "B"
		JOY_BUTTON_X:
			return "X"
		JOY_BUTTON_Y:
			return "Y"
		JOY_BUTTON_START:
			return "Start"
		JOY_BUTTON_DPAD_LEFT, JOY_BUTTON_DPAD_RIGHT, JOY_BUTTON_DPAD_UP, JOY_BUTTON_DPAD_DOWN:
			return "Croix"
	return "Bouton %d" % button
