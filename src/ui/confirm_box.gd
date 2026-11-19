extends Control
## Fenêtre de confirmation commune (quitter le jeu, revenir au titre) : une question, deux lignes.
## « Non » a le curseur d'emblée ; retour (Échap, B) répond « non ». Pilotable à la manette seule.
## Usage : `var yes: bool = await box.ask("Quitter le jeu ?", "Quitter")`.

signal answered(yes: bool)

const UI = preload("res://src/ui/ui_kit.gd")

var _text: Label
var _yes: Button
var _no: Button
var _panel: PanelContainer
var _opened_at := 0


func _ready() -> void:
	UI.full_rect(self)
	visible = false
	var shade := ColorRect.new()
	shade.color = Color(0.0, 0.0, 0.03, 0.62)
	UI.full_rect(shade)   # il bloque aussi la souris : rien de ce qui est dessous ne se clique
	add_child(shade)
	var center := CenterContainer.new()
	UI.full_rect(center)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UI.soft_style(0.96, 34))
	center.add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.custom_minimum_size = Vector2(520, 0)
	_panel.add_child(box)
	_text = UI.label("", 24)
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_text)
	box.add_child(UI.rule())
	_yes = UI.menu_button("Oui", 24)
	_no = UI.menu_button("Non", 24)
	for b: Button in [_yes, _no]:
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		box.add_child(b)
	_yes.pressed.connect(_answer.bind(true))
	_no.pressed.connect(_answer.bind(false))
	# le curseur ne peut pas s'échapper vers l'écran de dessous
	_yes.focus_neighbor_top = _yes.get_path()
	_yes.focus_neighbor_left = _yes.get_path()
	_yes.focus_neighbor_right = _yes.get_path()
	_yes.focus_neighbor_bottom = _no.get_path()
	_yes.focus_next = _no.get_path()
	_yes.focus_previous = _no.get_path()
	_no.focus_neighbor_bottom = _no.get_path()
	_no.focus_neighbor_left = _no.get_path()
	_no.focus_neighbor_right = _no.get_path()
	_no.focus_neighbor_top = _yes.get_path()
	_no.focus_next = _yes.get_path()
	_no.focus_previous = _yes.get_path()
	var foot := UI.hints(UI.KEYS_MENU)
	box.add_child(foot)
	foot.alignment = BoxContainer.ALIGNMENT_CENTER


## Pose la question et attend la réponse (vrai = « oui »).
func ask(question: String, yes_label: String = "Oui", no_label: String = "Non") -> bool:
	_text.text = question
	_yes.text = yes_label
	_no.text = no_label
	_opened_at = Engine.get_process_frames()
	visible = true
	_no.grab_focus()
	UI.pop(_panel)
	Sfx.play("cancel")
	var yes: bool = await answered
	return yes


func _answer(yes: bool) -> void:
	if not visible:
		return
	Sfx.play("confirm" if yes else "cancel")
	visible = false
	answered.emit(yes)


func _input(event: InputEvent) -> void:
	if not visible or Engine.get_process_frames() == _opened_at:
		return
	if event.is_action_pressed("menu") or event.is_action_pressed("cancel") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_answer(false)
