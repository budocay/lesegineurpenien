extends Node
## POINT D'ACCÈS UNIQUE AUX SPRITES ET TEXTURES.
##
## Tout le jeu demande ses images ici. Pour chaque image, on cherche d'abord un
## fichier PNG dans res://assets/sprites/ ; s'il n'existe pas, on retombe sur la
## version peinte par code. Remplacer les sprites par un pack acheté revient donc
## à déposer des PNG au bon endroit, sans toucher au code.
## Le format attendu est documenté dans assets/sprites/README.md.

const PA = preload("res://src/gfx/pixel_art.gd")
const CharacterPainter = preload("res://src/gfx/character_painter.gd")
const PropPainter = preload("res://src/gfx/prop_painter.gd")
const TilePainter = preload("res://src/gfx/tile_painter.gd")
const MonsterPainter = preload("res://src/gfx/monster_painter.gd")
const FxPainter = preload("res://src/gfx/fx_painter.gd")
const IconPainter = preload("res://src/gfx/icon_painter.gd")
const SPRITE_SHADER = preload("res://src/gfx/shaders/sprite.gdshader")

const ASSET_DIR := "res://assets/sprites/"
const PPU := 24.0   # pixels par unité monde (décors)
const MONSTER_PPU := 28.0   # les monstres, un cran plus petits : les personnages sont à 40

var _cache: Dictionary = {}
var _materials: Dictionary = {}


# ------------------------------------------------------------------ fichiers

## Charge une image du dossier des assets si elle existe, sinon renvoie null.
func _load_override(relative: String) -> Image:
	var path := ASSET_DIR + relative
	if ResourceLoader.exists(path):
		var res: Resource = load(path)
		if res is Texture2D:
			var img := (res as Texture2D).get_image()
			if img != null:
				if img.is_compressed():
					img.decompress()
				img.convert(Image.FORMAT_RGBA8)
				return img
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) == OK:
			img.convert(Image.FORMAT_RGBA8)
			return img
	return null


func _load_meta(relative: String) -> Dictionary:
	var path := ASSET_DIR + relative
	if not FileAccess.file_exists(path):
		return {}
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) == OK and json.data is Dictionary:
		return json.data
	push_warning("Fichier de description de sprite illisible : " + path)
	return {}


# --------------------------------------------------------------- personnages

## Planche de sprites d'un personnage.
## Renvoie {texture, image, frame_w, frame_h, columns, row_count, rows, walk, idle, ppu, foot, fps}.
func character(id: String) -> Dictionary:
	var key := "char:" + id
	if _cache.has(key):
		return _cache[key]
	var sheet := {
		"columns": CharacterPainter.COLUMNS,
		"row_count": CharacterPainter.ROWS,
		"rows": {"down": 0, "left": 1, "right": 2, "up": 3},
		"walk": CharacterPainter.WALK,
		"idle": 0,
		"idle_seq": CharacterPainter.IDLE,
		"idle_fps": 4.0,
		"poses": CharacterPainter.POSES,
		"ppu": CharacterPainter.PPU,
		"foot": CharacterPainter.FOOT_MARGIN,
		"fps": 7.0,
	}
	var img := _load_override("characters/%s.png" % id)
	if img != null:
		var meta := _load_meta("characters/%s.json" % id)
		sheet["columns"] = int(meta.get("columns", 4))
		var rows: Variant = meta.get("rows", ["down", "left", "right", "up"])
		if rows is Array:
			var map := {}
			for i in (rows as Array).size():
				map[str(rows[i])] = i
			sheet["rows"] = map
			sheet["row_count"] = (rows as Array).size()
		sheet["walk"] = meta["walk"] if meta.get("walk") is Array else [1, 2, 3, 0]
		sheet["idle"] = int(meta.get("idle", 0))
		sheet["idle_seq"] = meta["idle_seq"] if meta.get("idle_seq") is Array else [sheet["idle"]]
		sheet["idle_fps"] = float(meta.get("idle_fps", 4.0))
		sheet["poses"] = meta["poses"] if meta.get("poses") is Dictionary else {}
		sheet["ppu"] = float(meta.get("pixels_per_unit", PPU))
		sheet["foot"] = int(meta.get("foot_margin", CharacterPainter.FOOT_MARGIN))
		sheet["fps"] = float(meta.get("fps", 7.0))
	else:
		var look: Variant = Database.get_character(id).get("look", {})
		img = _painted_sheet(look if look is Dictionary else {})
	sheet["image"] = img
	sheet["texture"] = PA.texture(img)
	sheet["frame_w"] = img.get_width() / int(sheet["columns"])
	sheet["frame_h"] = img.get_height() / int(sheet["row_count"])
	_cache[key] = sheet
	return sheet


static var _painter_stamp := ""


## Planche peinte par code, avec cache disque (user://cache_persos/) : la peinture d'une planche
## prend environ une demi-seconde, le PNG en cache se relit en quelques millisecondes. La clé
## contient le texte des peintres et la description du personnage : toute retouche repeint.
func _painted_sheet(look: Dictionary) -> Image:
	if _painter_stamp == "":
		var src := ""
		for f in ["char_kit", "character_head", "character_painter", "character_species", "pixel_art"]:
			src += FileAccess.get_file_as_string("res://src/gfx/%s.gd" % f)
		_painter_stamp = src.md5_text()
	var path := "user://cache_persos/%s.png" % (_painter_stamp + JSON.stringify(look, "", true)).md5_text()
	if FileAccess.file_exists(path):
		var cached := Image.new()
		if cached.load(path) == OK and cached.get_width() == CharacterPainter.FRAME_W * CharacterPainter.COLUMNS:
			cached.convert(Image.FORMAT_RGBA8)
			return cached
	var img := CharacterPainter.paint_sheet(look)
	DirAccess.make_dir_recursive_absolute("user://cache_persos")
	img.save_png(path)
	return img


## Portrait pour la boîte de dialogue : le haut de la pose « face », agrandi.
func portrait(id: String) -> Texture2D:
	var key := "portrait:" + id
	if _cache.has(key):
		return _cache[key]
	var tex: Texture2D = null
	var img := _load_override("portraits/%s.png" % id)
	if img != null:
		tex = PA.texture(img)
	elif Database.characters.has(id) and _load_override("characters/%s.png" % id) == null:
		# portrait peint : la tête de face, agrandie deux fois et lissée
		var look: Variant = Database.get_character(id).get("look", {})
		tex = PA.texture(CharacterPainter.paint_portrait(look if look is Dictionary else {}))
	elif Database.characters.has(id):
		var sheet := character(id)
		var fw: int = sheet.frame_w
		var fh: int = sheet.frame_h
		var rows: Dictionary = sheet.rows
		var region := Rect2i(int(sheet.idle) * fw, int(rows.get("down", 0)) * fh, fw, fh)
		var sheet_img: Image = sheet.image
		var b := PA.opaque_bounds(sheet_img, region)
		var side := mini(26, fw)
		var x := clampi(b.position.x + b.size.x / 2 - side / 2, 0, fw - side)
		var y := clampi(b.position.y - 1, 0, fh - side)
		tex = PA.texture(sheet_img.get_region(Rect2i(region.position.x + x, region.position.y + y, side, side)))
	_cache[key] = tex
	return tex


## Planche d'un monstre : deux poses côte à côte, regard vers la droite.
## Renvoie {texture, image, frame_w, frame_h, columns, ppu, foot, fps}.
func monster(kind: String) -> Dictionary:
	var key := "monster:" + kind
	if _cache.has(key):
		return _cache[key]
	var sheet := {"columns": MonsterPainter.COLUMNS, "ppu": MONSTER_PPU, "foot": 1, "fps": 2.2,
		"idle": MonsterPainter.IDLE, "poses": MonsterPainter.POSES}
	var img := _load_override("monsters/%s.png" % kind)
	var overridden: Image = img
	if img != null:
		var meta := _load_meta("monsters/%s.json" % kind)
		sheet["columns"] = maxi(1, int(meta.get("columns", 2)))
		sheet["idle"] = meta["idle"] if meta.get("idle") is Array else range(int(sheet["columns"]))
		sheet["poses"] = meta["poses"] if meta.get("poses") is Dictionary else {}
		sheet["ppu"] = float(meta.get("pixels_per_unit", MONSTER_PPU))
		sheet["foot"] = int(meta.get("foot_margin", 1))
		sheet["fps"] = float(meta.get("fps", 2.2))
	else:
		img = MonsterPainter.paint(kind)
		PA.relief(img)
	sheet["image"] = img
	# la planche peinte par code est affichée repeinte plus fin (voir MonsterPainter.upscale) ;
	# image, frame_w et frame_h restent ceux du dessin d'origine (taille dans le monde, vignettes)
	sheet["texture"] = PA.texture(MonsterPainter.upscale(img, int(sheet["columns"])) if overridden == null else img)
	sheet["frame_w"] = img.get_width() / int(sheet["columns"])
	sheet["frame_h"] = img.get_height()
	_cache[key] = sheet
	return sheet


## Vignette carrée d'un combattant pour la file des tours.
func battler_icon(sprite: Dictionary) -> Texture2D:
	if sprite.has("character"):
		return portrait(str(sprite["character"]))
	var kind := str(sprite.get("monster", ""))
	var key := "icon:" + kind
	if _cache.has(key):
		return _cache[key]
	var sheet := monster(kind)
	var fw: int = sheet.frame_w
	var fh: int = sheet.frame_h
	var src: Image = sheet.image
	var b := PA.opaque_bounds(src, Rect2i(0, 0, fw, fh))
	var side := mini(mini(fw, fh), 24)
	var x := clampi(b.end.x - side, 0, fw - side)
	var y := clampi(b.position.y, 0, fh - side)
	var tex := PA.texture(src.get_region(Rect2i(x, y, side, side)))
	_cache[key] = tex
	return tex


# -------------------------------------------------------------------- décors

func prop(kind: String, variant: int = 0) -> Texture2D:
	var key := "prop:%s:%d" % [kind, variant]
	if _cache.has(key):
		return _cache[key]
	var img := _load_override("props/%s_%d.png" % [kind, variant])
	if img == null:
		img = _load_override("props/%s.png" % kind)
	if img == null:
		img = PropPainter.paint(kind, variant)
	var tex := PA.texture(img)
	_cache[key] = tex
	return tex


## Petit sprite d'effet de combat (projectile, arme, symbole) : assets/sprites/fx/<nom>.png
## s'il existe, sinon la version peinte par code.
func fx(kind: String) -> Texture2D:
	var key := "fx:" + kind
	if _cache.has(key):
		return _cache[key]
	var img := _load_override("fx/%s.png" % kind)
	if img == null:
		img = FxPainter.paint(kind)
	var tex := PA.texture(img)
	_cache[key] = tex
	return tex


## Icône d'interface (commande, élément, genre d'arme, état, signe) : assets/sprites/icons/<nom>.png
## s'il existe, sinon la version peinte par code (12 x 12 pixels, voir icon_painter.gd).
func icon(kind: String) -> Texture2D:
	var key := "icon:" + kind
	if _cache.has(key):
		return _cache[key]
	var img := _load_override("icons/%s.png" % kind)
	if img == null:
		img = IconPainter.paint(kind)
	var tex := PA.texture(img)
	_cache[key] = tex
	return tex


## Image répétable d'un type de sol ou de mur (48 x 48 px pour 2 unités).
func tile_image(kind: String) -> Image:
	var key := "tileimg:" + kind
	if _cache.has(key):
		return _cache[key]
	var img := _load_override("tiles/%s.png" % kind)
	if img == null:
		img = TilePainter.paint(kind)
	_cache[key] = img
	return img


func tile_texture(kind: String) -> Texture2D:
	var key := "tiletex:" + kind
	if _cache.has(key):
		return _cache[key]
	var tex := PA.texture(tile_image(kind))
	_cache[key] = tex
	return tex


## Mémorise une texture coûteuse à peindre (sol complet d'une carte, façade...).
func cached(key: String, builder: Callable) -> Variant:
	if not _cache.has(key):
		_cache[key] = builder.call()
	return _cache[key]


# ----------------------------------------------------------------- matériaux

## « see_through » : le sprite s'ajoure quand il passe devant le héros. Vrai pour les décors,
## faux pour les personnages et les combattants (un personnage n'est jamais tramé).
func sprite_material(tex: Texture2D, sway: float = 0.0, glow: float = 0.0, see_through: bool = true) -> ShaderMaterial:
	var key := "%d:%.3f:%.2f:%s" % [tex.get_instance_id(), sway, glow, see_through]
	if _materials.has(key):
		return _materials[key]
	var m := ShaderMaterial.new()
	m.shader = SPRITE_SHADER
	m.set_shader_parameter("sheet", tex)
	m.set_shader_parameter("sway", sway)
	m.set_shader_parameter("glow", glow)
	m.set_shader_parameter("see_through", 1.0 if see_through else 0.0)
	_materials[key] = m
	return m


## Sprite debout posé au sol. Renvoie un pivot placé au pied du sprite (pour pencher ou retourner).
func make_sprite(tex: Texture2D, sway: float = 0.0, glow: float = 0.0, ppu: float = PPU) -> Node3D:
	var pivot := Node3D.new()
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(tex.get_width() / ppu, tex.get_height() / ppu)
	quad.mesh = mesh
	quad.material_override = sprite_material(tex, sway, glow)
	quad.position.y = mesh.size.y * 0.5
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	quad.name = "Quad"
	pivot.add_child(quad)
	return pivot
