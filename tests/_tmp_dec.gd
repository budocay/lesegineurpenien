extends SceneTree
var _done := false
func _process(_d: float) -> bool:
	if _done: return true
	_done = true
	var out := OS.get_cmdline_user_args()[0]
	var IP: GDScript = load("res://src/gfx/interior_painter.gd")
	var TP: GDScript = load("res://src/gfx/tile_painter.gd")
	var sheet := Image.create_empty(1500, 700, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("#5a5560"))
	var x := 4
	var y := 4
	for kind: String in IP.DECOR:
		var n: int = IP.DECOR[kind][0]
		for v in n:
			var d: Dictionary = IP.paint_decor(kind, v)
			var im: Image = d["albedo"]
			im = im.duplicate()
			im.resize(im.get_width() * 3, im.get_height() * 3, Image.INTERPOLATE_NEAREST)
			if x + im.get_width() > 1496:
				x = 4
				y += 190
			sheet.blend_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i(x, y))
			x += im.get_width() + 8
	sheet.save_png(out + "/decor.png")
	var t := Image.create_empty(600, 400, false, Image.FORMAT_RGBA8)
	var tiles := ["cave_pierre", "cave_pierre_noire", "roche_fond", "nain_roche_humide", "nain_dalle", "isen_mur"]
	var tx := 0
	for k in tiles:
		var im: Image = TP.paint(k).duplicate()
		for rx in 2:
			for ry in 2:
				t.blit_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i(tx + rx * im.get_width(), ry * im.get_height() if k != "cave_pierre" and false else ry * 72 if im.get_height() == 72 else ry * 48))
		tx += 96 + 4
	t = t.get_region(Rect2i(0,0,600,150))
	t.resize(1800, 450, Image.INTERPOLATE_NEAREST)
	t.save_png(out + "/tiles.png")
	print("OK")
	return true
