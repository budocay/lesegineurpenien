extends Control
## Indicateur de chargement : un arc doré qui tourne. L'angle dépend de l'horloge (pas du temps écoulé
## entre deux images) : après une image longue, le tour reprend là où il doit être, sans à-coup de calcul.

const COLOR := Color("#c9a24a")


func _init() -> void:
	custom_minimum_size = Vector2(44, 44)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5 - 4.0
	draw_arc(c, r, 0.0, TAU, 40, Color(COLOR, 0.18), 3.0, true)
	var a0 := fmod(t * 4.2, TAU)
	draw_arc(c, r, a0, a0 + TAU * 0.28, 24, COLOR, 4.0, true)
