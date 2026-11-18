extends SceneTree
var _done := false
func _process(_d: float) -> bool:
	if _done:
		return true
	_done = true
	var sprites: Node = root.get_node("Sprites")
	var mp: GDScript = load("res://src/gfx/monster_painter.gd")
	var total := 0
	var rows := []
	for kind: String in mp.SIZES:
		var t := Time.get_ticks_msec()
		sprites.monster(kind)
		var d := Time.get_ticks_msec() - t
		total += d
		rows.append([d, kind])
	rows.sort()
	rows.reverse()
	print("TOTAL ms: ", total)
	for r in rows.slice(0, 12):
		print("  ", r)
	return true
