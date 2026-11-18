extends SceneTree
## Outil : écrit des planches agrandies des décors, des tuiles et des façades (contrôle visuel).
##   Godot --headless --path . -s tests/_dump_props.gd -- <dossier> [props|tiles|houses]
var _done := false


func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	var args := OS.get_cmdline_user_args()
	var out := args[0]
	var what: String = args[1] if args.size() > 1 else "all"
	var sprites: Node = root.get_node("Sprites")
	var mb: GDScript = load("res://src/world/map_builder.gd")
	var tp: GDScript = load("res://src/gfx/tile_painter.gd")
	if what == "all" or what == "props":
		_sheet(out + "/props.png", sprites, mb.PROPS, 4)
	if what == "all" or what == "tiles":
		var kinds := ["grass", "path", "cobble", "planks", "floor", "wood", "soil", "plaster", "brick", "stone", "iron", "rock_face", "rock_face_moss", "rock_face_mud", "rock_face_dark", "rock_face_ashlar", "interior_wall", "roof_rouge", "roof_vert", "roof_ardoise", "roof_chaume"]
		var cols := 5
		var cell := 48 * 2 * 3 + 6
		var img := Image.create_empty(cols * cell, ((kinds.size() + cols - 1) / cols) * cell, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.1, 0.1, 0.12))
		for i in kinds.size():
			var t: Image = sprites.tile_image(kinds[i])
			var big := Image.create_empty(t.get_width() * 2, t.get_height() * 2, false, Image.FORMAT_RGBA8)
			for oy in 2:
				for ox in 2:
					big.blit_rect(t, Rect2i(0, 0, t.get_width(), t.get_height()), Vector2i(ox * t.get_width(), oy * t.get_height()))
			big.resize(big.get_width() * 3, big.get_height() * 3, Image.INTERPOLATE_NEAREST)
			img.blit_rect(big, Rect2i(0, 0, big.get_width(), big.get_height()), Vector2i((i % cols) * cell, (i / cols) * cell))
		img.save_png(out + "/tiles.png")
	if what == "all" or what == "houses":
		var specs := [[5.0, 3.0, 2.5, [1.0, 4.0], "#3f7a52"], [8.0, 3.0, 4.0, [1.5, 2.5, 5.5, 6.5], "#8a3a3a"], [4.0, 3.0, -1.0, [2.0], "#3f7a52"]]
		var img2 := Image.create_empty(1700, 560, false, Image.FORMAT_RGBA8)
		img2.fill(Color(0.1, 0.1, 0.12))
		var x := 4
		for sp: Array in specs:
			var f: Dictionary = tp.house_front(sp[0], sp[1], sp[2], sp[3], Color.from_string(sp[4], Color.GRAY), true)
			var a: Image = f["albedo"]
			a.resize(a.get_width() * 4, a.get_height() * 4, Image.INTERPOLATE_NEAREST)
			img2.blit_rect(a, Rect2i(0, 0, a.get_width(), a.get_height()), Vector2i(x, 4))
			x += a.get_width() + 10
		img2.save_png(out + "/houses.png")
	print("PROPS OK")
	return true


func _sheet(path: String, sprites: Node, props: Dictionary, scale: int) -> void:
	var items: Array[Image] = []
	for kind: String in props:
		var n := int((props[kind] as Dictionary).get("variants", 1))
		for v in n:
			var im: Image = (sprites.prop(kind, v) as Texture2D).get_image().duplicate()
			items.append(im)
	var w := 0
	var h := 0
	var width := 1800
	var x := 4
	var y := 4
	var row_h := 0
	var placed: Array = []
	for im in items:
		var sw := im.get_width() * scale
		var sh := im.get_height() * scale
		if x + sw > width:
			x = 4
			y += row_h + 8
			row_h = 0
		placed.append([im, x, y])
		x += sw + 8
		row_h = maxi(row_h, sh)
	h = y + row_h + 8
	w = width
	var sheet := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	sheet.fill(Color(0.32, 0.4, 0.3))
	for p: Array in placed:
		var im: Image = p[0]
		im.resize(im.get_width() * scale, im.get_height() * scale, Image.INTERPOLATE_NEAREST)
		sheet.blend_rect(im, Rect2i(0, 0, im.get_width(), im.get_height()), Vector2i(p[1], p[2]))
	sheet.save_png(path)
