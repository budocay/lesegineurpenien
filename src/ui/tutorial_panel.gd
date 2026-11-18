extends PanelContainer
## Encart d'un conseil de jeu : étiquette (qui parle), titre, quelques lignes, touches à presser.
## Construit par code au style de ui_kit.gd. Posé par l'autoload `Tutorial`, qui lui donne son
## contenu (voir `Tutorial.resolve`) et le range soit en bas à droite (conseil de passage), soit
## au centre (conseil de combat, qui attend une touche).

const UI = preload("res://src/ui/ui_kit.gd")

const WIDTH_NOTE := 430.0
const WIDTH_MODAL := 620.0


## `view` : {"title", "text", "tag", "rows": [{"caps": [..], "verb": ".."}], "modal": bool, "dismiss": [caps]}
func build(view: Dictionary) -> void:
	var modal := bool(view.get("modal", false))
	for c in get_children():
		remove_child(c)
		c.queue_free()
	var st := UI.panel_style(Color(0.03, 0.035, 0.08, 0.92), UI.GOLD_LINE, 8, 1)
	st.content_margin_left = 20
	st.content_margin_right = 20
	st.content_margin_top = 14
	st.content_margin_bottom = 14
	st.shadow_size = 12
	add_theme_stylebox_override("panel", st)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(WIDTH_MODAL if modal else WIDTH_NOTE, 0)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)
	box.add_child(UI.caps(str(view.get("tag", "Conseil")), 13, UI.GOLD_DIM))
	var title := UI.label(str(view.get("title", "")), 26 if modal else 24, UI.GOLD, true)
	box.add_child(title)
	box.add_child(UI.rule())
	var body := UI.label(str(view.get("text", "")), 18, UI.INK)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.custom_minimum_size = Vector2((WIDTH_MODAL if modal else WIDTH_NOTE) - 40.0, 0)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(body)
	var rows: Array = view.get("rows", [])
	if not rows.is_empty():
		var gap := Control.new()
		gap.custom_minimum_size = Vector2(0, 2)
		box.add_child(gap)
		var holder: Container = HFlowContainer.new() if modal else VBoxContainer.new()   # en combat : sur une ligne, pour rester bas
		holder.add_theme_constant_override("h_separation", 24)
		holder.add_theme_constant_override("v_separation", 6)
		holder.add_theme_constant_override("separation", 6)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(holder)
		for r: Variant in rows:
			holder.add_child(key_row((r as Dictionary).get("caps", []), str((r as Dictionary).get("verb", ""))))
	if modal:
		var foot := HBoxContainer.new()
		foot.alignment = BoxContainer.ALIGNMENT_END
		foot.add_theme_constant_override("separation", 8)
		foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		for c: Control in caps_nodes(view.get("dismiss", []), 15):
			foot.add_child(c)
		foot.add_child(UI.label("pour continuer", 15, UI.INK_FAINT, false, true))
		box.add_child(foot)
	reset_size()


## Une ligne « [touche] verbe ».
static func key_row(caps: Array, verb: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for c: Control in caps_nodes(caps, 16):
		row.add_child(c)
	var v := UI.label(verb, 16, UI.INK_DIM)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pad := Control.new()
	pad.custom_minimum_size = Vector2(4, 0)
	row.add_child(pad)
	row.add_child(v)
	return row


## Pictogrammes de touches ; le mot « ou » reste du texte simple.
static func caps_nodes(caps: Array, size: int) -> Array[Control]:
	var out: Array[Control] = []
	for k: Variant in caps:
		var text := str(k)
		if text == "ou":
			var l := UI.label("ou", size - 2, UI.INK_FAINT, false, true)
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			out.append(l)
			continue
		var cap := PanelContainer.new()
		var cs := StyleBoxFlat.new()
		cs.bg_color = Color(UI.GOLD, 0.14)
		cs.border_color = UI.GOLD
		cs.set_border_width_all(1)
		cs.set_corner_radius_all(4)
		cs.content_margin_left = 8
		cs.content_margin_right = 8
		cs.content_margin_top = 1
		cs.content_margin_bottom = 2
		cap.add_theme_stylebox_override("panel", cs)
		cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var l := UI.label(text, size, UI.GOLD, true)
		l.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cap.add_child(l)
		out.append(cap)
	return out
