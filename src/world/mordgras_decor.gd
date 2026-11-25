extends RefCounted
## Garniture du chapitre 7 (styles `marais`, `mordgras`, `toile`, `festin`) : sol fissuré et coulées de braise,
## ustensiles géants, chaînes, braseros, passerelles, reflets de lanternes, feux follets.
## Appelé par MordgrasBuilder.object ; documentation : docs/FORMAT_DONNEES.md, section « Garniture du chapitre 7 ».

const MeshKit = preload("res://src/gfx/mesh_kit.gd")
const Atmosphere = preload("res://src/world/atmosphere.gd")
const PA = preload("res://src/gfx/pixel_art.gd")

const OBJECTS: Array[String] = ["mor_sol", "mor_ustensile", "mor_chaine", "mor_brasero", "mor_passerelle", "mor_reflet", "mor_feu_follet"]

const PX_PER_M := 12.0


static func object(b, type: String, o: Dictionary) -> bool:
	match type:
		"mor_sol": _floor(b, o)
		"mor_ustensile": _utensil(b, o)
		"mor_chaine": _chain(b, o)
		"mor_brasero": _brazier(b, o)
		"mor_passerelle": _walkway(b, o)
		"mor_reflet": _reflection(b, o)
		"mor_feu_follet": _wisp(b, o)
		_: return false
	return true


static func _box_in(parent: Node3D, center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = mat
	node.position = center
	parent.add_child(node)
	return node


static func _glow_mat(color: Color, energy: float) -> StandardMaterial3D:
	var m := MeshKit.flat_material(color)
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


# ================================================================== sol fissuré, coulées de braise

## Trait d'épaisseur `t` ; `mul` vrai : le pixel est multiplié par `c` (assombrir), sinon remplacé par `c`.
static func _line(img: Image, x0: float, y0: float, x1: float, y1: float, c: Color, t: int, mul: bool = false) -> void:
	var n := int(maxf(absf(x1 - x0), absf(y1 - y0))) + 1
	for i in n + 1:
		var f := float(i) / float(n)
		var x := int(lerpf(x0, x1, f))
		var y := int(lerpf(y0, y1, f))
		for dx in t:
			for dy in t:
				_px(img, x + dx, y + dy, c, mul)


static func _px(img: Image, px: int, py: int, c: Color, mul: bool) -> void:
	if px < 0 or py < 0 or px >= img.get_width() or py >= img.get_height():
		return
	if mul:
		var o := img.get_pixel(px, py)
		img.set_pixel(px, py, Color(o.r * c.r, o.g * c.g, o.b * c.b, 1.0))
	else:
		img.set_pixel(px, py, c)


static func _layer_material(img: Image, additive: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD if additive else BaseMaterial3D.BLEND_MODE_MUL
	m.disable_fog = true
	return m


## Calque de sol sur un rectangle : fissures (qui rougeoient si `glow`), taches de suie, coulées de braise
## (`rivers` : liste de [x0, z0, x1, z1, largeur] en mètres, tracées en ondulant). Deux calques : un qui assombrit
## (fissures, suie, croûte des coulées), un qui s'ajoute (braise). Champs : `rect` [x, z, l, p], `seed`, `cracks` (24),
## `glow` (part des fissures qui rougeoient, 0,6), `soot` (14), `rivers`, `y` (0,02), `energy` (1,0), `embers` (vrai :
## braises qui montent le long des coulées).
static func _floor(b, o: Dictionary) -> void:
	var r: Array = o.get("rect", [0, 0, 8, 8])
	var rx := float(r[0])
	var rz := float(r[1])
	var rw := float(r[2])
	var rd := float(r[3])
	var iw := int(rw * PX_PER_M)
	var ih := int(rd * PX_PER_M)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(o.get("seed", 7))
	var dark := Image.create(iw, ih, false, Image.FORMAT_RGBA8)
	var heat := Image.create(iw, ih, false, Image.FORMAT_RGBA8)
	dark.fill(Color(1, 1, 1, 1))
	heat.fill(Color(0, 0, 0, 1))
	var gl := float(o.get("glow", 0.6))
	var soot_n := int(o.get("soot", 14))
	for i in soot_n:
		var cx := rng.randf() * iw
		var cy := rng.randf() * ih
		var rr := rng.randf_range(0.8, 2.6) * PX_PER_M
		for yy in range(int(cy - rr), int(cy + rr)):
			for xx in range(int(cx - rr * 1.4), int(cx + rr * 1.4)):
				var d := Vector2((xx - cx) / 1.4, yy - cy).length() / rr
				if d < 1.0 and rng.randf() < (1.0 - d) * 0.9:
					var k := 1.0 - 0.5 * (1.0 - d)
					_px(dark, xx, yy, Color(k, k, k, 1.0), true)
	var crack_n := int(o.get("cracks", 24))
	var crack_dark := Color(0.3, 0.26, 0.26, 1.0)
	for i in crack_n:
		var x := rng.randf() * iw
		var y := rng.randf() * ih
		var ang := rng.randf() * TAU
		var segs := rng.randi_range(8, 22)
		var hot := rng.randf() < gl
		for s in segs:
			var step := rng.randf_range(0.25, 0.7) * PX_PER_M
			ang += rng.randf_range(-0.7, 0.7)
			var nx := x + cos(ang) * step
			var ny := y + sin(ang) * step * 0.9
			_line(dark, x, y, nx, ny, crack_dark, 2, true)
			if hot:
				_line(heat, x, y, nx, ny, Color(0.95, 0.3 + rng.randf() * 0.2, 0.04, 1.0), 1)
			if rng.randf() < 0.14:
				var a2 := ang + (1.0 if rng.randf() < 0.5 else -1.0) * rng.randf_range(0.5, 1.1)
				var bx := nx + cos(a2) * step * 1.4
				var by := ny + sin(a2) * step * 1.2
				_line(dark, nx, ny, bx, by, Color(0.3, 0.26, 0.26, 1.0), 1, true)
				if hot:
					_line(heat, nx, ny, bx, by, Color(0.5, 0.13, 0.02, 1.0), 1)
			x = nx
			y = ny
			if x < 0 or y < 0 or x >= iw or y >= ih:
				break
	var rivers: Array = o.get("rivers", [])
	for rv: Variant in rivers:
		var a: Array = rv
		var x0 := (float(a[0]) - rx) * PX_PER_M
		var z0 := (float(a[1]) - rz) * PX_PER_M
		var x1 := (float(a[2]) - rx) * PX_PER_M
		var z1 := (float(a[3]) - rz) * PX_PER_M
		var wd := float(a[4]) * PX_PER_M
		var len := Vector2(x1 - x0, z1 - z0).length()
		var n := int(len / 2.0) + 1
		var ph := rng.randf() * TAU
		var nrm := Vector2(-(z1 - z0), x1 - x0).normalized()
		for i in n + 1:
			var f := float(i) / float(n)
			var wob := sin(f * 9.0 + ph) * wd * 0.35 + sin(f * 23.0 + ph * 2.0) * wd * 0.08
			var cx2 := lerpf(x0, x1, f) + nrm.x * wob
			var cz2 := lerpf(z0, z1, f) + nrm.y * wob
			var half := wd * (0.5 + 0.12 * sin(f * 13.0 + ph))
			for dy in range(int(-half * 1.6), int(half * 1.6) + 1):
				for dx in range(int(-half * 1.6), int(half * 1.6) + 1):
					var d := Vector2(dx, dy).length() / half
					var xx := int(cx2) + dx
					var yy := int(cz2) + dy
					if d < 1.6 and d >= 1.0:
						_px(dark, xx, yy, Color(0.5, 0.45, 0.45, 1.0), true)   # croûte refroidie
					elif d < 1.0:
						_px(dark, xx, yy, Color(0.1, 0.1, 0.1, 1.0), true)
						var core := clampf(1.0 - d * 1.2, 0.0, 1.0)
						_px(heat, xx, yy, Color(0.75, 0.16 + core * 0.4, 0.02 + core * 0.18, 1.0), false)
	var cx3 := rx + rw * 0.5
	var cz3 := rz + rd * 0.5
	var gy: float = b.world.ground_y(cx3, cz3) + float(o.get("y", 0.02))
	var plane := PlaneMesh.new()
	plane.size = Vector2(rw, rd)
	var n_dark := MeshInstance3D.new()
	n_dark.name = "MorSolSuie"
	n_dark.mesh = plane
	n_dark.material_override = _layer_material(dark, false)
	n_dark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n_dark.position = Vector3(cx3, gy, cz3)
	b.world.add_child(n_dark)
	var n_heat := MeshInstance3D.new()
	n_heat.name = "MorSolBraise"
	n_heat.mesh = plane
	var hm := _layer_material(heat, true)
	hm.albedo_color = Color(1, 1, 1, 1) * float(o.get("energy", 1.0))
	n_heat.material_override = hm
	n_heat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	n_heat.position = Vector3(cx3, gy + 0.005, cz3)
	b.world.add_child(n_heat)
	if bool(o.get("embers", false)):
		for rv: Variant in rivers:
			var a3: Array = rv
			var ps := Atmosphere.make_particles("embers")
			if ps != null:
				ps.position = Vector3((float(a3[0]) + float(a3[2])) * 0.5, 0.3, (float(a3[1]) + float(a3[3])) * 0.5)
				b.world.add_child(ps)


# ========================================================================= ustensiles géants

## Ustensile de cuisine géant planté dans le sol. Champs : `pos`, `kind` (`louche`, `fourchette`, `couperet`,
## `entonnoir`, `marmite`), `scale` (1), `yaw` (degrés), `lean` (inclinaison en degrés). Solide (disque de 0,7 × `scale`).
static func _utensil(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var s := float(o.get("scale", 1.0))
	var kind := str(o.get("kind", "louche"))
	var parent := Node3D.new()
	parent.name = "MorUstensile"
	parent.position = p
	parent.rotation_degrees = Vector3(0.0, float(o.get("yaw", 0.0)), 0.0)
	b.world.add_child(parent)
	var iron := MeshKit.flat_material(Color("#2c2832"))
	iron.metallic = 0.25
	iron.roughness = 0.7
	var steel := MeshKit.flat_material(Color("#5a5666"))
	steel.roughness = 0.6
	var wood := MeshKit.flat_material(Color("#3a2418"))
	var tilt := Node3D.new()
	tilt.rotation_degrees = Vector3(0.0, 0.0, float(o.get("lean", 0.0)))
	parent.add_child(tilt)
	match kind:
		"louche":
			_box_in(tilt, Vector3(0.0, 2.6 * s, 0.0), Vector3(0.22 * s, 5.2 * s, 0.22 * s), wood)
			_box_in(tilt, Vector3(0.0, 5.3 * s, 0.0), Vector3(0.34 * s, 0.4 * s, 0.34 * s), iron)
			var bowl := MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radius = 1.0 * s
			sph.height = 1.2 * s
			bowl.mesh = sph
			bowl.material_override = steel
			bowl.position = Vector3(0.0, 5.9 * s, 0.0)
			bowl.rotation_degrees = Vector3(30.0, 0.0, 0.0)
			tilt.add_child(bowl)
			_box_in(tilt, Vector3(0.0, 5.9 * s, 0.0), Vector3(1.6 * s, 0.05 * s, 1.6 * s), _glow_mat(Color("#ff6a20"), 1.1))
		"fourchette":
			_box_in(tilt, Vector3(0.0, 2.8 * s, 0.0), Vector3(0.26 * s, 5.6 * s, 0.14 * s), steel)
			_box_in(tilt, Vector3(0.0, 5.7 * s, 0.0), Vector3(1.5 * s, 0.26 * s, 0.14 * s), steel)
			for k in 4:
				_box_in(tilt, Vector3((-0.6 + 0.4 * float(k)) * s, 6.6 * s, 0.0), Vector3(0.14 * s, 1.6 * s, 0.12 * s), steel)
		"couperet":
			_box_in(tilt, Vector3(0.0, 1.6 * s, 0.0), Vector3(3.0 * s, 2.5 * s, 0.14 * s), steel)
			_box_in(tilt, Vector3(0.0, 0.35 * s, 0.0), Vector3(3.0 * s, 0.1 * s, 0.1 * s), _glow_mat(Color("#d8d4e0"), 0.5))
			_box_in(tilt, Vector3(1.9 * s, 2.5 * s, 0.0), Vector3(1.3 * s, 0.3 * s, 0.3 * s), wood)
			for k in 3:
				_box_in(tilt, Vector3((1.0 + 0.35 * float(k)) * s, 2.5 * s, 0.17 * s), Vector3(0.08 * s, 0.34 * s, 0.06 * s), iron)
		"entonnoir":
			var cone := MeshInstance3D.new()
			var cyl := CylinderMesh.new()
			cyl.top_radius = 1.4 * s
			cyl.bottom_radius = 0.18 * s
			cyl.height = 2.2 * s
			cone.mesh = cyl
			cone.material_override = steel
			cone.position = Vector3(0.0, 2.6 * s, 0.0)
			tilt.add_child(cone)
			_box_in(tilt, Vector3(0.0, 0.8 * s, 0.0), Vector3(0.24 * s, 1.6 * s, 0.24 * s), iron)
			_box_in(tilt, Vector3(0.0, 3.68 * s, 0.0), Vector3(2.4 * s, 0.05 * s, 2.4 * s), _glow_mat(Color("#ff5a18"), 0.9))
		_:   # marmite
			var pot := MeshInstance3D.new()
			var cy2 := CylinderMesh.new()
			cy2.top_radius = 1.5 * s
			cy2.bottom_radius = 1.3 * s
			cy2.height = 1.9 * s
			pot.mesh = cy2
			pot.material_override = iron
			pot.position = Vector3(0.0, 0.95 * s, 0.0)
			tilt.add_child(pot)
			_box_in(tilt, Vector3(0.0, 1.92 * s, 0.0), Vector3(2.7 * s, 0.05 * s, 2.7 * s), _glow_mat(Color("#ffb040"), 1.2))
			_box_in(tilt, Vector3(1.7 * s, 1.5 * s, 0.0), Vector3(0.5 * s, 0.14 * s, 0.14 * s), iron)
			_box_in(tilt, Vector3(-1.7 * s, 1.5 * s, 0.0), Vector3(0.5 * s, 0.14 * s, 0.14 * s), iron)
	b.world.circles.append(Vector3(p.x, p.z, 0.7 * s))


# ===================================================================================== chaînes

## Chaîne qui pend du plafond jusqu'à `to` (hauteur du dernier maillon, 4), avec un crochet. Champs : `pos`,
## `to` (4), `top` (hauteur de la carte par défaut), `scale` (1).
static func _chain(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var top := float(o.get("top", b.wall_height if b.wall_height > 3.5 else 12.0))
	var to := float(o.get("to", 4.0))
	var s := float(o.get("scale", 1.0))
	var st := MeshKit.begin()
	var y := top
	var k := 0
	while y > to:
		if k % 2 == 0:
			MeshKit.box(st, Vector3(0.0, y, 0.0), Vector3(0.16 * s, 0.42 * s, 0.05 * s))
		else:
			MeshKit.box(st, Vector3(0.0, y, 0.0), Vector3(0.05 * s, 0.42 * s, 0.16 * s))
		y -= 0.3 * s
		k += 1
	# crochet
	MeshKit.box(st, Vector3(0.0, to - 0.35 * s, 0.0), Vector3(0.14 * s, 0.5 * s, 0.14 * s))
	MeshKit.box(st, Vector3(0.18 * s, to - 0.62 * s, 0.0), Vector3(0.36 * s, 0.12 * s, 0.12 * s))
	var m := MeshKit.flat_material(Color("#26222c"))
	m.roughness = 0.6
	var node := MeshKit.finish(st, m)
	node.name = "MorChaine"
	node.position = Vector3(p.x, 0.0, p.z)
	b.world.add_child(node)
	if bool(o.get("hang", false)):   # un quartier de viande au crochet
		var meat := MeshKit.flat_material(Color("#8a3a3a"))
		_box_in(node, Vector3(0.0, to - 1.2 * s, 0.0), Vector3(0.7 * s, 1.1 * s, 0.5 * s), meat)


# ==================================================================================== braseros

## Brasero sur trépied : cuvette de fer, flamme, lumière vacillante. Champs : `pos`, `scale` (1), `energy` (2), `color`.
static func _brazier(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var s := float(o.get("scale", 1.0))
	var parent := Node3D.new()
	parent.name = "MorBrasero"
	parent.position = p
	b.world.add_child(parent)
	var iron := MeshKit.flat_material(Color("#1c1822"))
	for k in 3:
		var a := TAU * float(k) / 3.0 + 0.5
		var leg := _box_in(parent, Vector3(cos(a) * 0.32 * s, 0.55 * s, sin(a) * 0.32 * s), Vector3(0.1 * s, 1.1 * s, 0.1 * s), iron)
		leg.rotation = Vector3(-sin(a) * 0.18, 0.0, cos(a) * 0.18)
	var bowl := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.62 * s
	cyl.bottom_radius = 0.34 * s
	cyl.height = 0.36 * s
	bowl.mesh = cyl
	bowl.material_override = iron
	bowl.position = Vector3(0.0, 1.15 * s, 0.0)
	parent.add_child(bowl)
	var col := Color(str(o.get("color", "#ff7a20")))
	_box_in(parent, Vector3(0.0, 1.34 * s, 0.0), Vector3(1.0 * s, 0.05 * s, 1.0 * s), _glow_mat(col, 2.4))
	var fire := Atmosphere.make_particles("fire")
	if fire != null:
		fire.position = Vector3(0.0, 1.45 * s, 0.0)
		fire.scale = Vector3(1.5, 1.5, 1.5) * s
		parent.add_child(fire)
	var l := Atmosphere.make_light(col.lightened(0.15), float(o.get("energy", 2.0)), 9.0 * s, false, 0.3)
	l.position = Vector3(0.0, 2.0 * s, 0.4 * s)
	parent.add_child(l)
	b.world.circles.append(Vector3(p.x, p.z, 0.5 * s))


# ====================================================================== marais : passerelles, reflets

## Garde-corps de passerelle : poteaux et cordes le long d'un segment (horizontal ou vertical), avec une
## lanterne tous les `lamp` poteaux. Champs : `from` [x, z], `to` [x, z], `step` (2,4), `height` (0,9), `both` (vrai :
## des deux côtés, avec `gap` entre les rangées, 3,2), `lamp` (0 : aucune).
static func _walkway(b, o: Dictionary) -> void:
	var f: Array = o.get("from", [0, 0])
	var t: Array = o.get("to", [4, 0])
	var a := Vector2(float(f[0]), float(f[1]))
	var c := Vector2(float(t[0]), float(t[1]))
	var step := float(o.get("step", 2.4))
	var hgt := float(o.get("height", 0.9))
	var gap := float(o.get("gap", 3.2))
	var parent := Node3D.new()
	parent.name = "MorPasserelle"
	b.world.add_child(parent)
	var wood := MeshKit.flat_material(Color("#2e2418"))
	var rope := MeshKit.flat_material(Color("#6a5a3c"))
	var dir := (c - a)
	var len := dir.length()
	if len < 0.1:
		return
	var nrm := Vector2(-dir.y, dir.x).normalized()
	var rows: Array = [0.0]
	if bool(o.get("both", true)):
		rows = [-gap * 0.5, gap * 0.5]
	var n := int(len / step) + 1
	var lamp := int(o.get("lamp", 0))
	for off: float in rows:
		var prev := Vector3.ZERO
		for i in n + 1:
			var q := a + dir * (float(i) / float(n)) + nrm * off
			var base: float = b.world.ground_y(q.x, q.y)
			var lean := sin(float(i) * 1.7 + off) * 0.06
			var post := _box_in(parent, Vector3(q.x, base + hgt * 0.5 + 0.1, q.y), Vector3(0.14, hgt + 0.3, 0.14), wood)
			post.rotation.z = lean
			var top := Vector3(q.x, base + hgt, q.y)
			if i > 0:
				var mid := (top + prev) * 0.5
				var seg := top - prev
				var r := _box_in(parent, mid + Vector3(0.0, -0.08, 0.0), Vector3(seg.length(), 0.05, 0.05), rope)
				r.rotation.y = -atan2(seg.z, seg.x)
				r.rotation.z = atan2(seg.y, Vector2(seg.x, seg.z).length())
			prev = top
			if lamp > 0 and i % lamp == 0 and off >= 0.0:
				var lamp_mat := _glow_mat(Color("#d8f0a8"), 2.2)
				_box_in(parent, top + Vector3(0.0, 0.5, 0.0), Vector3(0.22, 0.3, 0.22), lamp_mat)
				var l := Atmosphere.make_light(Color("#b8e8a0"), 0.9, 5.0, false, 0.18)
				l.position = top + Vector3(0.0, 0.7, 0.0)
				parent.add_child(l)


## Reflet de lumière sur l'eau noire : une traînée verticale floue sous une lanterne, qui ondule. Champs : `pos`,
## `length` (2,6), `width` (0,7), `color`, `phase`.
static func _reflection(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var len := float(o.get("length", 2.6))
	var wd := float(o.get("width", 0.7))
	var col := Color(str(o.get("color", "#d8f0a0")))
	var img := Image.create(16, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 16:
			var fx := absf(float(x) - 7.5) / 8.0
			var fy := float(y) / 63.0
			var ripple := 0.55 + 0.45 * sin(float(y) * 0.9)
			var a := clampf(1.0 - fx * fx * 1.3, 0.0, 1.0) * (1.0 - fy) * ripple
			img.set_pixel(x, y, Color(col.r, col.g, col.b, a * 0.8))
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var q := PlaneMesh.new()
	q.size = Vector2(wd, len)
	var node := MeshInstance3D.new()
	node.name = "MorReflet"
	node.mesh = q
	node.material_override = mat
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.position = Vector3(p.x, p.y + 0.03, p.z + len * 0.5)
	b.world.add_child(node)
	var tw := node.create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var ph := float(o.get("phase", 0.0))
	tw.tween_property(node, "scale:x", 1.25, 1.4 + ph * 0.3)
	tw.tween_property(node, "scale:x", 0.85, 1.4 + ph * 0.3)


## Feu follet : une petite flamme bleu-vert qui flotte au-dessus de l'eau, avec sa lueur. Champs : `pos`, `height` (0,9),
## `color` ("#8af0d0"), `drift` (0,5 : amplitude de la dérive en mètres).
static func _wisp(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var col := Color(str(o.get("color", "#8af0d0")))
	var node := Node3D.new()
	node.name = "MorFeuFollet"
	node.position = p + Vector3(0.0, float(o.get("height", 0.9)), 0.0)
	b.world.add_child(node)
	var core := _box_in(node, Vector3.ZERO, Vector3(0.16, 0.22, 0.16), _glow_mat(col.lightened(0.5), 3.2))
	core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var halo := Atmosphere.make_particles("fireflies")
	if halo != null:
		halo.amount = 6
		halo.emission_box_extents = Vector3(0.5, 0.4, 0.5)
		node.add_child(halo)
	var l := Atmosphere.make_light(col, 1.2, 5.5, false, 0.25)
	node.add_child(l)
	var drift := float(o.get("drift", 0.5))
	var tw := node.create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var y0 := node.position.y
	var x0 := node.position.x
	tw.tween_property(node, "position", Vector3(x0 + drift, y0 + 0.3, node.position.z), 2.6)
	tw.tween_property(node, "position", Vector3(x0 - drift, y0 - 0.1, node.position.z), 3.1)
