extends RefCounted
## Boîte à outils de dessin pixel par pixel, partagée par tous les « peintres ».

const OUTLINE := Color("#1b1425")


static func new_image(w: int, h: int) -> Image:
	return Image.create_empty(w, h, false, Image.FORMAT_RGBA8)


static func px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		img.set_pixel(x, y, c)


static func rect(img: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	if w <= 0 or h <= 0:
		return
	img.fill_rect(Rect2i(x, y, w, h), c)


## Ellipse pleine. Le centre est donné en coordonnées continues (le pixel x couvre [x, x+1]).
static func ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	if rx <= 0.0 or ry <= 0.0:
		return
	for y in range(int(floor(cy - ry)), int(ceil(cy + ry)) + 1):
		for x in range(int(floor(cx - rx)), int(ceil(cx + rx)) + 1):
			var dx := (x + 0.5 - cx) / rx
			var dy := (y + 0.5 - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				px(img, x, y, c)


static func line(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var dx := absi(x1 - x0)
	var dy := -absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx + dy
	var x := x0
	var y := y0
	for _i in 4096:
		px(img, x, y, c)
		if x == x1 and y == y1:
			break
		var e2 := 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy


## Ajoute un contour d'un pixel autour de tout ce qui est opaque dans la zone.
static func outline(img: Image, region: Rect2i, c: Color = OUTLINE) -> void:
	var src := img.get_region(region)
	var w := region.size.x
	var h := region.size.y
	for y in h:
		for x in w:
			if src.get_pixel(x, y).a >= 0.5:
				continue
			var touch := false
			if x > 0 and src.get_pixel(x - 1, y).a >= 0.5:
				touch = true
			elif x < w - 1 and src.get_pixel(x + 1, y).a >= 0.5:
				touch = true
			elif y > 0 and src.get_pixel(x, y - 1).a >= 0.5:
				touch = true
			elif y < h - 1 and src.get_pixel(x, y + 1).a >= 0.5:
				touch = true
			if touch:
				img.set_pixel(region.position.x + x, region.position.y + y, c)


## k < 0 : plus sombre et plus froid (ombres violacées) ; k > 0 : plus clair et plus chaud.
static func shade(c: Color, k: float) -> Color:
	var out: Color
	if k < 0.0:
		out = c.darkened(-k).lerp(Color(0.17, 0.12, 0.34), -k * 0.35)
	else:
		out = c.lightened(k * 0.75).lerp(Color(1.0, 0.94, 0.72), k * 0.3)
	out.a = c.a
	return out


## Pseudo-aléatoire déterministe dans [0, 1[.
static func rnd(x: int, y: int, s: int) -> float:
	var n: int = (x * 73856093) ^ (y * 19349663) ^ (s * 83492791)
	n = n & 0x7fffffff
	n = (n ^ (n >> 13)) * 1274126177
	n = n & 0x7fffffff
	n = n ^ (n >> 16)
	return float(n & 0xffff) / 65536.0


static func pick(colors: Array, x: int, y: int, s: int) -> Color:
	return colors[int(rnd(x, y, s) * colors.size()) % colors.size()]


static func texture(img: Image) -> ImageTexture:
	return ImageTexture.create_from_image(img)


## Boîte englobante des pixels opaques d'une zone (en coordonnées de la zone).
static func opaque_bounds(img: Image, region: Rect2i) -> Rect2i:
	var min_x := region.size.x
	var min_y := region.size.y
	var max_x := -1
	var max_y := -1
	for y in region.size.y:
		for x in region.size.x:
			if img.get_pixel(region.position.x + x, region.position.y + y).a >= 0.5:
				min_x = mini(min_x, x)
				min_y = mini(min_y, y)
				max_x = maxi(max_x, x)
				max_y = maxi(max_y, y)
	if max_x < 0:
		return Rect2i(0, 0, region.size.x, region.size.y)
	return Rect2i(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
