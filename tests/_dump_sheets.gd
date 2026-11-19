extends SceneTree
## Outil : écrit les planches et portraits agrandis dans le dossier donné (contrôle visuel).
##   Godot --headless --path . -s tests/_dump_sheets.gd -- <dossier>
var _done := false

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	var out := OS.get_cmdline_user_args()[0]
	var db: Node = root.get_node("Database")
	var sprites: Node = root.get_node("Sprites")
	for id: String in db.characters:
		var img: Image = (sprites.character(id)["image"] as Image).duplicate()
		img.resize(img.get_width() * 4, img.get_height() * 4, Image.INTERPOLATE_NEAREST)
		img.save_png("%s/%s.png" % [out, id])
		var p: Image = sprites.portrait(id).get_image()
		p.resize(192, 192, Image.INTERPOLATE_NEAREST)
		p.save_png("%s/portrait_%s.png" % [out, id])
	var mp: GDScript = load("res://src/gfx/monster_painter.gd")
	for kind: String in mp.SIZES:
		# planche HD telle qu'affichée (texture), pas le dessin d'origine
		var m: Image = (sprites.monster(kind)["texture"] as Texture2D).get_image()
		m.save_png("%s/monstre_%s.png" % [out, kind])
	print("PLANCHES OK")
	return true
