extends Control
## Générique de fin. Texte qui défile sur fond noir ; la touche d'interaction l'accélère (maintenue),
## retour ou menu le passe. Quand le texte est passé, les neuf petits anneaux roulent sur l'écran
## (scène d'après-générique), puis le signal `finished` rend la main à main.gd, qui retourne au titre.
## Tout se pilote à la manette (A accélère, B ou Start passe) : aucune touche en dur dans le texte.

signal finished

const SPEED := 54.0          # pixels par seconde
const FAST := 4.0            # facteur quand on maintient la touche d'interaction
const GOLD := Color("#e8c050")
const INK := Color("#f2ecdc")
const DIM := Color("#a89c8c")

var _lines: Array = []       # [texte, taille, couleur] ; "" = blanc
var _scroll_y := 0.0
var _phase := "off"          # off, scroll, rings, done
var _t := 0.0
var _total_h := 0.0
var _font: Font = null
var _opened := 0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 200


## Lignes du générique : [texte, taille, couleur]. Données dans `data/game.json` (champ `credits`) si présentes.
func play(lines: Array) -> void:
	_lines = lines
	_font = ThemeDB.fallback_font
	_total_h = 0.0
	for l: Variant in _lines:
		_total_h += float((l as Array)[1]) * 1.9
	_scroll_y = size.y + 40.0
	_phase = "scroll"
	_t = 0.0
	_opened = Time.get_ticks_msec()
	visible = true
	grab_focus()
	queue_redraw()


func is_playing() -> bool:
	return visible and _phase != "done"


func _finish() -> void:
	if _phase == "done":
		return
	_phase = "done"
	visible = false
	finished.emit()


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	var skip_ok := Time.get_ticks_msec() - _opened > 600
	if _phase == "scroll":
		var k := FAST if Input.is_action_pressed("interact") else 1.0
		_scroll_y -= SPEED * k * delta
		if _scroll_y + _total_h < -20.0:
			_phase = "rings"
			_t = 0.0
		if skip_ok and (Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("menu")):
			_phase = "rings"
			_t = 0.0
	elif _phase == "rings":
		if _t > 7.5 or (skip_ok and (Input.is_action_just_pressed("cancel") or Input.is_action_just_pressed("menu") or Input.is_action_just_pressed("interact"))):
			_finish()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color.BLACK)
	if _font == null:
		return
	if _phase == "scroll":
		var y := _scroll_y
		for l: Variant in _lines:
			var row: Array = l
			var fs := int(row[1])
			var text := str(row[0])
			if text != "" and y > -40.0 and y < size.y + 40.0:
				var w := _font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
				var c := Color(str(row[2]))
				var fade := clampf(minf(y / 90.0, (size.y - y) / 90.0), 0.0, 1.0)
				c.a = fade
				draw_string(_font, Vector2((size.x - w) * 0.5, y + float(fs)), text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, c)
			y += float(fs) * 1.9
	elif _phase == "rings":
		# neuf petits anneaux qui roulent, l'un derrière l'autre, de gauche à droite
		var base := size.y * 0.72
		draw_line(Vector2(0, base + 14.0), Vector2(size.x, base + 14.0), Color(0.2, 0.18, 0.16), 2.0)
		for i in 9:
			var x := -60.0 + (_t * 190.0) - float(i) * 74.0
			if x < -30.0 or x > size.x + 30.0:
				continue
			var a := x / 14.0
			draw_arc(Vector2(x, base), 13.0, 0.0, TAU, 24, GOLD, 4.0)
			draw_circle(Vector2(x + cos(a) * 13.0, base + sin(a) * 13.0), 2.2, INK)
		var msg := "Fin"
		var w2 := _font.get_string_size(msg, HORIZONTAL_ALIGNMENT_CENTER, -1, 44).x
		draw_string(_font, Vector2((size.x - w2) * 0.5, size.y * 0.42), msg, HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Color(GOLD, clampf(_t * 0.8, 0.0, 1.0)))
		var sub := "Les anneaux roulent encore."
		var w3 := _font.get_string_size(sub, HORIZONTAL_ALIGNMENT_CENTER, -1, 20).x
		draw_string(_font, Vector2((size.x - w3) * 0.5, size.y * 0.42 + 40.0), sub, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(DIM, clampf(_t - 1.0, 0.0, 1.0)))
