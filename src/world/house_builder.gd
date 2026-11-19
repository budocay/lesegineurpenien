extends RefCounted
## Construit les maisons du style par défaut (villages des hommes et des Grobittes).
## Tout ce qui distingue une maison d'une autre (matière du mur, du toit, étage en encorbellement,
## lucarnes, enseigne, accessoires) vient de `spec`, tiré de façon stable de l'identifiant de la
## carte et de l'emprise : la même maison est identique à chaque lancement. Les champs du JSON
## priment toujours sur le tirage (voir docs/FORMAT_DONNEES.md, « Maisons »).
## La jouabilité ne change pas : emprise (`rect`), porte, passages, interactions, estompage.

const PA = preload("res://src/gfx/pixel_art.gd")
const MeshKit = preload("res://src/gfx/mesh_kit.gd")
const HP = preload("res://src/gfx/house_painter.gd")
const Atmosphere = preload("res://src/world/atmosphere.gd")

const WARM := Color("#ffb45e")
const TINTS := ["#e2cfa6", "#d9b98a", "#e6c6b0", "#c9d1b0", "#cfd4d8", "#eadfc8", "#dcae8c"]
const SHUTTERS := ["#3f6a8a", "#4f7a52", "#8a4a3c", "#6a5a8a", "#a8843c", "#5a7a8a"]
const WALLS := ["crepi", "colombage", "pierre", "planches"]
const DOORS := ["#3f7a52", "#a8483c", "#3f6ea0", "#d9a23a", "#6a4a8a", "#2f2c38", "#c8782a"]
const ROOF_OV := 0.4      # débord de l'avant-toit, côtés façade et dos
const ROOF_OS := 0.3      # débord du toit sur les pignons
const JETTY := 0.42       # encorbellement de l'étage


## Tirage stable pour la maison `o` de la carte `map`. Pur : aucune lecture du monde.
static func spec(map: Dictionary, o: Dictionary) -> Dictionary:
	var sp := _base_spec(map, o)
	# deux bâtiments d'une même carte ne partagent jamais mur + toit + porte : on varie, dans l'ordre
	# des cartes, ce que le JSON n'impose pas (mur, puis toit, puis couleur de porte)
	var done: Array[Dictionary] = []
	for h: Variant in map.get("objects", []):
		if not (h is Dictionary) or str((h as Dictionary).get("type", "")) != "house":
			continue
		if (h as Dictionary).get("rect") == o.get("rect"):
			break
		done.append(_dedupe(_base_spec(map, h as Dictionary), done, h as Dictionary))
	return _dedupe(sp, done, o)


static func _same_door(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) + absf(a.g - b.g) + absf(a.b - b.b) < 0.45


static func _clash(sp: Dictionary, done: Array[Dictionary]) -> bool:
	for d: Dictionary in done:
		if str(d["wall"]) == str(sp["wall"]) and str(d["roof"]) == str(sp["roof"]) and _same_door(d["door_color"], sp["door_color"]):
			return true
	return false


static func _dedupe(sp: Dictionary, done: Array[Dictionary], o: Dictionary) -> Dictionary:
	if not _clash(sp, done):
		return sp
	var grobitte := str(sp["style"]) == "grobitte"
	if not o.has("wall") and not grobitte:
		for w: String in WALLS:
			sp["wall"] = w
			if not _clash(sp, done):
				return sp
	if not o.has("roof") and not grobitte:
		for rf: String in ["rouge", "ardoise", "chaume"]:
			sp["roof"] = rf
			if not _clash(sp, done):
				return sp
	if not o.has("door_color"):
		for dc: String in DOORS:
			sp["door_color"] = Color.from_string(dc, Color("#3f7a52"))
			if not _clash(sp, done):
				return sp
	return sp


static func _base_spec(map: Dictionary, o: Dictionary) -> Dictionary:
	var r: Array = o.get("rect", [0, 0, 5, 4])
	var h: int = ("%s|%s" % [str(map.get("id", "")), str(r)]).hash()
	var sd := int(h & 0x7fffffff) % 9973
	var hw := float(r[2])
	var grobitte := str(o.get("style", "")) == "grobitte"
	var roof := str(o.get("roof", "rouge"))
	if grobitte:
		roof = "herbe"
	var wh := float(o.get("height", [2.4, 2.6, 2.8][int(PA.rnd(sd, 1, 17) * 3.0) % 3]))
	var rh := float(o.get("roof_height", [1.5, 1.7, 1.9][int(PA.rnd(sd, 2, 17) * 3.0) % 3]))
	if grobitte:
		wh = float(o.get("height", 2.3))
		rh = float(o.get("roof_height", 1.5))
	# matière du mur
	var wall := "crepi"
	var roll := PA.rnd(sd, 3, 17)
	if roof == "chaume":
		wall = "crepi" if roll < 0.3 else ("colombage" if roll < 0.6 else ("planches" if roll < 0.85 else "pierre"))
	elif roof == "ardoise":
		wall = "pierre" if roll < 0.35 else ("crepi" if roll < 0.7 else "colombage")
	else:
		wall = "crepi" if roll < 0.4 else ("colombage" if roll < 0.75 else ("pierre" if roll < 0.9 else "planches"))
	var storeys := int(o.get("storeys", 2 if wh >= 3.3 else 1))
	if storeys >= 2 and not o.has("wall") and roll > 0.2:
		wall = "colombage"
	if grobitte:
		wall = "crepi"
		storeys = 1
	wall = str(o.get("wall", wall))
	var tint_i := int(PA.rnd(sd, 4, 17) * float(TINTS.size())) % TINTS.size()
	var tint := Color.from_string(str(o.get("plaster", TINTS[tint_i])), Color("#e2cfa6"))
	var window: String = "rond" if grobitte else ["croisillons", "arche", "croisillons"][int(PA.rnd(sd, 5, 17) * 3.0) % 3]
	var door: String = "rond" if grobitte else ("cintre" if PA.rnd(sd, 6, 17) < 0.5 else "plat")
	var dormers := 0
	if not grobitte and rh >= 1.6 and hw >= 6.0 and storeys < 2:
		dormers = (2 if hw >= 9.0 else 1) if PA.rnd(sd, 7, 17) < 0.45 else 0
	dormers = int(o.get("dormers", dormers))
	var sign_kind := str(o.get("sign", ""))
	if sign_kind == "":
		var to_map := ""
		if o.get("to") is Dictionary:
			to_map = str((o["to"] as Dictionary).get("map", ""))
		var who := to_map + " " + str(o.get("dialogue", ""))
		if who.contains("auberge") or who.contains("poney"):
			sign_kind = "auberge"
		elif who.contains("fromag"):
			sign_kind = "fromage"
		elif who.contains("forge"):
			sign_kind = "forge"
		elif who.contains("ecurie"):
			sign_kind = "cheval"
		elif who.contains("mairie"):
			sign_kind = "horloge"
		elif who.contains("capitain") or who.contains("garde"):
			sign_kind = "blason"
		elif who.contains("cure"):
			sign_kind = "herbes"
	var extras := ["", "barrel", "crates", "flowers", ""]
	return {
		"seed": sd, "style": "grobitte" if grobitte else "", "roof": roof, "wall": wall, "tint": tint,
		"wh": wh, "rh": rh, "storeys": storeys, "jetty": storeys >= 2 and bool(o.get("jetty", true)),
		"window": window, "door": door, "dormers": dormers, "sign": sign_kind,
		"shutter": Color.from_string(SHUTTERS[int(PA.rnd(sd, 8, 17) * 6.0) % 6], Color("#3f6a8a")),
		"flowers": PA.rnd(sd, 9, 17) < 0.6, "ivy": PA.rnd(sd, 10, 17) < 0.3,
		"chimney_left": PA.rnd(sd, 11, 17) < 0.5, "chimney_brick": PA.rnd(sd, 12, 17) < 0.6,
		"extra": str(o.get("extra", extras[int(PA.rnd(sd, 13, 17) * 5.0) % 5])),
		"extra_left": PA.rnd(sd, 14, 17) < 0.5,
		"awning": bool(o.get("awning", true)) and wh >= 2.9,
		"door_color": Database.color(o.get("door_color", "#3f7a52"), Color("#3f7a52")),
	}


## Part d'éclairage de fenêtre : 1 au crépuscule et la nuit, moins en plein jour.
static func glow_factor(map: Dictionary) -> float:
	var amb := Database.get_ambiance(str(map.get("ambiance", "crepuscule")))
	var sun: Variant = amb.get("sun")
	if sun is Dictionary:
		return clampf((1.35 - float((sun as Dictionary).get("energy", 0.9))) / 0.4, 0.15, 1.0)
	return 1.0


static func _flat(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var m := MeshKit.flat_material(color, emission)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


static func _double(tex: Texture2D, emi: Texture2D = null, energy: float = 2.0) -> StandardMaterial3D:
	var m := MeshKit.pixel_material(tex, emi, energy)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


## Une boîte dans le groupe de couleur `hex` (une seule maille par couleur et par maison).
static func _tb(groups: Dictionary, hex: String, center: Vector3, size: Vector3) -> void:
	if not groups.has(hex):
		groups[hex] = MeshKit.begin()
	MeshKit.box(groups[hex], center, size)


static func _roof_y(top: float, zm: float, slope: float, z: float) -> float:
	return top - slope * absf(z - zm)


static func house(b, o: Dictionary) -> void:
	var map: Dictionary = b.map
	var world: Node3D = b.world
	var sp := spec(map, o)
	var r: Array = o.get("rect", [0, 0, 5, 4])
	var x0 := float(r[0])
	var z0 := float(r[1])
	var hw := float(r[2])
	var hd := float(r[3])
	var x1 := x0 + hw
	var z1 := z0 + hd
	var xm := (x0 + x1) * 0.5
	var zm := (z0 + z1) * 0.5
	var wh: float = sp["wh"]
	var rh: float = sp["rh"]
	var door_x := float(o.get("door", hw * 0.5))
	var windows: Array = o.get("windows", [])
	var door_color: Color = sp["door_color"]
	var lit := bool(o.get("lit", true))
	var grobitte: bool = sp["style"] == "grobitte"
	var glow := glow_factor(map)
	var key := "hs:%s:%s:%s:%s" % [str(map.get("id", "")), str(r), str(lit), str(door_color)]
	var node := Node3D.new()
	node.name = "House"
	node.set_meta("spec", sp)
	world.add_child(node)
	var parts: Array = []
	var trim := {}   # couleur -> SurfaceTool des petites pièces de bois, pierre et fer

	# textures de la maison, peintes une fois par variante
	var tex: Dictionary = Sprites.cached(key, func() -> Dictionary:
		var f := HP.front(sp, hw, wh, door_x, windows, door_color, lit)
		var sd := HP.side(sp, hd, wh, rh + (0.6 if grobitte else 0.0), lit)
		var back := PA.new_image(int(round(hw * 24.0)), int(round(wh * 24.0)))
		HP.wall(back, str(sp["wall"]), sp["tint"], int(sp["seed"]) + 91)
		HP.wall_trim(back, str(sp["wall"]), int(sp["seed"]), 9)
		return {
			"front": PA.texture(f["albedo"]), "front_e": PA.texture(f["emission"]),
			"side": PA.texture(sd["albedo"]), "side_e": PA.texture(sd["emission"]),
			"back": PA.texture(back),
		})
	var wall_k := 2.6 * glow
	var top := wh + rh
	var slope := rh / (hd * 0.5)

	# ---- façade (avec étage en encorbellement pour les grandes maisons)
	var st := MeshKit.begin()
	if sp["jetty"]:
		var yf := 2.34
		var vf := (wh - yf) / wh
		MeshKit.quad(st, Vector3(x0, yf, z1), Vector3(x1, yf, z1), Vector3(x1, 0, z1), Vector3(x0, 0, z1), Vector2(0, vf), Vector2.ONE)
		var top_f := wh - slope * JETTY
		var vt := (wh - top_f) / wh
		MeshKit.quad(st, Vector3(x0, top_f, z1 + JETTY), Vector3(x1, top_f, z1 + JETTY), Vector3(x1, yf, z1 + JETTY), Vector3(x0, yf, z1 + JETTY), Vector2(0, vt), Vector2(1, vf))
		_tb(trim, "#4a3122", Vector3(xm, yf - 0.05, z1 + JETTY * 0.5), Vector3(hw, 0.2, JETTY + 0.04))
		_tb(trim, "#4a3122", Vector3(x0 + 0.02, (yf + top_f) * 0.5, z1 + JETTY * 0.5), Vector3(0.08, top_f - yf, JETTY))
		_tb(trim, "#4a3122", Vector3(x1 - 0.02, (yf + top_f) * 0.5, z1 + JETTY * 0.5), Vector3(0.08, top_f - yf, JETTY))
		var n_br := maxi(2, int(hw / 2.6))
		for i in range(n_br + 1):
			var bx := x0 + 0.15 + (hw - 0.3) * float(i) / float(n_br)
			_tb(trim, "#3a2618", Vector3(bx, yf - 0.2, z1 + 0.09), Vector3(0.12, 0.26, 0.14))
	else:
		MeshKit.quad(st, Vector3(x0, wh, z1), Vector3(x1, wh, z1), Vector3(x1, 0, z1), Vector3(x0, 0, z1))
	var front_mesh := MeshKit.finish(st, MeshKit.pixel_material(tex["front"], tex["front_e"], wall_k))
	node.add_child(front_mesh)

	# ---- pignons (mur puis triangle ou arc) et dos
	var side_h := wh + rh + (0.6 if grobitte else 0.0)
	var vwh := (side_h - wh) / side_h
	var arc: Array[Vector2] = []   # profil du toit en tonneau des Grobittes : (z, y)
	var ysp := wh - 0.45
	var arc_r := hd * 0.5 + ROOF_OV
	if grobitte:
		var th1 := acos(clampf((hd * 0.5) / arc_r, 0.0, 1.0))
		var th := th1
		var steps := 10
		for i in range(steps + 1):
			th = lerpf(0.0, PI, float(i) / float(steps))
			arc.append(Vector2(zm + arc_r * cos(th), ysp + (rh + 0.6 - 0.15) * sin(th)))
	st = MeshKit.begin()
	for sx_i in 2:
		var xs := x0 if sx_i == 0 else x1
		var za := z0 if sx_i == 0 else z1
		var zb := z1 if sx_i == 0 else z0
		MeshKit.quad(st, Vector3(xs, wh, za), Vector3(xs, wh, zb), Vector3(xs, 0, zb), Vector3(xs, 0, za), Vector2(0, vwh), Vector2.ONE)
		if grobitte:
			# arc plein jusqu'au sol du toit : éventail depuis le milieu de la base
			var pts: Array[Vector3] = []
			for p: Vector2 in arc:
				if p.x >= z0 - 0.001 and p.x <= z1 + 0.001 and p.y >= wh - 0.001:
					pts.append(Vector3(xs, p.y, p.x))
			pts.insert(0, Vector3(xs, wh, z1))
			pts.append(Vector3(xs, wh, z0))
			var c0 := Vector3(xs, wh, zm)
			for i in range(pts.size() - 1):
				var uv_of := func(p: Vector3) -> Vector2:
					var u := (p.z - z0) / hd
					return Vector2(1.0 - u if sx_i == 1 else u, (side_h - p.y) / side_h)
				MeshKit.tri(st, c0, pts[i], pts[i + 1], uv_of.call(c0), uv_of.call(pts[i]), uv_of.call(pts[i + 1]))
		else:
			MeshKit.tri(st, Vector3(xs, wh, za), Vector3(xs, top, zm), Vector3(xs, wh, zb), Vector2(0, vwh), Vector2(0.5, 0), Vector2(1, vwh))
	var side_mesh := MeshKit.finish(st, _double(tex["side"], tex["side_e"], wall_k))
	node.add_child(side_mesh)
	st = MeshKit.begin()
	MeshKit.quad(st, Vector3(x1, wh, z0), Vector3(x0, wh, z0), Vector3(x0, 0, z0), Vector3(x1, 0, z0))
	node.add_child(MeshKit.finish(st, MeshKit.pixel_material(tex["back"])))

	# ---- toit
	var roof_node: MeshInstance3D
	var ye := wh - slope * ROOF_OV
	if grobitte:
		var total := 0.0
		for i in range(arc.size() - 1):
			total += arc[i].distance_to(arc[i + 1])
		var roof_tex: Texture2D = Sprites.cached("hr:%s" % key, func() -> Texture2D:
			return PA.texture(HP.roof(sp, hw + 2.0 * ROOF_OS, total)))
		st = MeshKit.begin()
		var acc := 0.0
		for i in range(arc.size() - 1):
			var seg := arc[i].distance_to(arc[i + 1])
			var va := acc / total
			var vb := (acc + seg) / total
			acc += seg
			MeshKit.quad(st, Vector3(x0 - ROOF_OS, arc[i + 1].y, arc[i + 1].x), Vector3(x1 + ROOF_OS, arc[i + 1].y, arc[i + 1].x), Vector3(x1 + ROOF_OS, arc[i].y, arc[i].x), Vector3(x0 - ROOF_OS, arc[i].y, arc[i].x), Vector2(0, vb), Vector2(1, va))
		roof_node = MeshKit.finish(st, _double(roof_tex))
		node.add_child(roof_node)
	else:
		var slen := Vector2(hd * 0.5 + ROOF_OV, rh + slope * ROOF_OV).length()
		var roof_tex: Texture2D = Sprites.cached("hr:%s" % key, func() -> Texture2D:
			return PA.texture(HP.roof(sp, hw + 2.0 * ROOF_OS, slen)))
		st = MeshKit.begin()
		MeshKit.quad(st, Vector3(x0 - ROOF_OS, top, zm), Vector3(x1 + ROOF_OS, top, zm), Vector3(x1 + ROOF_OS, ye, z1 + ROOF_OV), Vector3(x0 - ROOF_OS, ye, z1 + ROOF_OV))
		MeshKit.quad(st, Vector3(x1 + ROOF_OS, top, zm), Vector3(x0 - ROOF_OS, top, zm), Vector3(x0 - ROOF_OS, ye, z0 - ROOF_OV), Vector3(x1 + ROOF_OS, ye, z0 - ROOF_OV))
		roof_node = MeshKit.finish(st, MeshKit.pixel_material(roof_tex))
		node.add_child(roof_node)
		# rives et épaisseur de l'avant-toit : planches posées le long des pentes
		var rake := MeshKit.begin()
		for xr: float in [x0 - ROOF_OS, x1 + ROOF_OS]:
			var pa := Vector3(xr, ye, z1 + ROOF_OV)
			var pb := Vector3(xr, top, zm)
			var pc := Vector3(xr, ye, z0 - ROOF_OV)
			var up := Vector3(0, 0.17, 0)
			MeshKit.quad(rake, pa + up, pb + up, pb, pa)
			MeshKit.quad(rake, pb + up, pc + up, pc, pb)
		node.add_child(MeshKit.finish(rake, _flat(Color("#3c281c"))))
		var pal: Array = HP.ROOF_PAL.get(str(sp["roof"]), HP.ROOF_PAL["rouge"])
		_tb(trim, str(pal[3]), Vector3(xm, top + 0.02, zm), Vector3(hw + 2.0 * ROOF_OS + 0.1, 0.14, 0.22))
		_tb(trim, "#3c281c", Vector3(xm, ye - 0.03, z1 + ROOF_OV - 0.03), Vector3(hw + 2.0 * ROOF_OS, 0.1, 0.08))

	# ---- lucarnes sur le pan avant
	var dn: int = sp["dormers"]
	if dn > 0 and not grobitte:
		var dtex: Dictionary = Sprites.cached("hd:" + key, func() -> Dictionary:
			var d := HP.dormer(sp, lit)
			var dr := HP.roof(sp, 1.5, 1.6)
			return {"front": PA.texture(d["albedo"]), "front_e": PA.texture(d["emission"]), "roof": PA.texture(dr)})
		var dst := MeshKit.begin()
		var dro := MeshKit.begin()
		var dsd := MeshKit.begin()
		for i in dn:
			var frac := 0.5 if dn == 1 else (0.27 if i == 0 else 0.73)
			if dn == 1:
				frac = 0.3 if bool(sp["chimney_left"]) == false else 0.7
				frac = 1.0 - frac if hw < 7.0 else frac
			var xc := x0 + hw * frac
			var zf := zm + (z1 - zm) * 0.55
			var yf := _roof_y(top, zm, slope, zf)
			var wd := 0.5
			var wall_h := 0.875
			var ped := 0.375
			MeshKit.quad(dst, Vector3(xc - wd, yf + wall_h, zf), Vector3(xc + wd, yf + wall_h, zf), Vector3(xc + wd, yf, zf), Vector3(xc - wd, yf, zf), Vector2(0, 0.3), Vector2.ONE)
			MeshKit.tri(dst, Vector3(xc - wd, yf + wall_h, zf), Vector3(xc, yf + wall_h + ped, zf), Vector3(xc + wd, yf + wall_h, zf), Vector2(0, 0.3), Vector2(0.5, 0), Vector2(1, 0.3))
			var zt := zm + (top - (yf + wall_h)) / slope
			for sgn: float in [-1.0, 1.0]:
				var xw := xc + sgn * wd
				MeshKit.tri(dsd, Vector3(xw, yf, zf), Vector3(xw, yf + wall_h, zf), Vector3(xw, yf + wall_h, zt), Vector2.ZERO, Vector2.ZERO, Vector2.ZERO)
			var y_r := yf + wall_h + ped
			var z_r := zm + (top - y_r) / slope
			var drop := 0.75 * (wd + 0.1)
			var y_w := y_r - drop
			var z_w := zm + (top - y_w) / slope
			var zfo := zf + 0.12
			for sgn: float in [-1.0, 1.0]:
				var xe := xc + sgn * (wd + 0.1)
				MeshKit.quad(dro, Vector3(xc, y_r, zfo), Vector3(xc, y_r, z_r), Vector3(xe, y_w, z_w), Vector3(xe, y_w, zfo), Vector2.ZERO, Vector2.ONE)
		var dfm := MeshKit.finish(dst, _double(dtex["front"], dtex["front_e"], wall_k))
		var drm := MeshKit.finish(dro, _double(dtex["roof"]))
		var dsm := MeshKit.finish(dsd, _flat(PA.shade(sp["tint"], -0.18)))
		node.add_child(dfm)
		node.add_child(drm)
		node.add_child(dsm)

	# ---- cheminée
	if bool(o.get("chimney", true)):
		var cx := x0 + hw * (0.18 if bool(sp["chimney_left"]) else 0.82)
		var cz := zm - hd * 0.12
		var cy := top + (0.55 if not grobitte else 0.35)
		if grobitte:
			cz = zm
		var csz := Vector3(0.58, 1.5, 0.58) if not grobitte else Vector3(0.38, 1.0, 0.38)
		st = MeshKit.begin()
		MeshKit.box(st, Vector3(cx, cy, cz), csz)
		var ctile := "brick" if bool(sp["chimney_brick"]) else "stone"
		node.add_child(MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture(ctile))))
		var cap_y := cy + csz.y * 0.5
		_tb(trim, "#4a3a36", Vector3(cx, cap_y + 0.05, cz), Vector3(csz.x + 0.14, 0.12, csz.z + 0.14))
		_tb(trim, "#2f2a30", Vector3(cx - 0.12, cap_y + 0.22, cz), Vector3(0.14, 0.22, 0.14))
		_tb(trim, "#2f2a30", Vector3(cx + 0.12, cap_y + 0.2, cz), Vector3(0.14, 0.18, 0.14))
		if lit:
			var smoke := Atmosphere.make_particles("smoke")
			smoke.position = Vector3(cx, cap_y + 0.5, cz)
			node.add_child(smoke)

	# ---- porte : marche, auvent, lanterne, enseigne
	var xd := x0 + door_x
	if door_x >= 0.0:
		_tb(trim, "#8a8590", Vector3(xd, 0.04, z1 + 0.17), Vector3(1.9, 0.08, 0.34))
		_tb(trim, "#a8a3ac", Vector3(xd, 0.09, z1 + 0.12), Vector3(1.7, 0.04, 0.24))
		if bool(sp["awning"]):
			var ast := MeshKit.begin()
			MeshKit.quad(ast, Vector3(xd - 1.25, 2.78, z1), Vector3(xd + 1.25, 2.78, z1), Vector3(xd + 1.25, 2.44, z1 + 0.5), Vector3(xd - 1.25, 2.44, z1 + 0.5), Vector2.ZERO, Vector2(1.25, 0.35))
			node.add_child(MeshKit.finish(ast, MeshKit.pixel_material(Sprites.tile_texture("roof_" + (str(sp["roof"]) if sp["roof"] != "herbe" else "vert")))))
			_tb(trim, "#3c281c", Vector3(xd, 2.4, z1 + 0.5), Vector3(2.5, 0.07, 0.07))
			for sx: float in [-1.15, 1.15]:
				_tb(trim, "#3c281c", Vector3(xd + sx, 2.56, z1 + 0.27), Vector3(0.07, 0.07, 0.5))
			# lanterne suspendue au bord de l'auvent
			_tb(trim, "#2f2c38", Vector3(xd + 0.95, 2.34, z1 + 0.46), Vector3(0.02, 0.1, 0.02))
			_tb(trim, "#2f2c38", Vector3(xd + 0.95, 2.04, z1 + 0.46), Vector3(0.3, 0.05, 0.22))
			_tb(trim, "#2f2c38", Vector3(xd + 0.95, 2.34, z1 + 0.46), Vector3(0.3, 0.05, 0.22))
			var lamp := MeshKit.begin()
			MeshKit.box(lamp, Vector3(xd + 0.95, 2.19, z1 + 0.46), Vector3(0.2, 0.25, 0.14))
			node.add_child(MeshKit.finish(lamp, MeshKit.flat_material(Color("#ffd28a"), 4.0 * glow), false))
		# enseigne : potence, tringle et panneau peint
		if str(sp["sign"]) != "" and hw >= 6.0:
			var cands: Array[float] = [xd - 2.3, xd + 2.3, xd - 1.9, xd + 1.9, xd - 1.5, xd + 1.5]
			var best := cands[0]
			var best_d := -1.0
			for cxs: float in cands:
				if cxs < x0 + 0.9 or cxs > x1 - 0.9:
					continue
				var dmin := 99.0
				for wv: Variant in windows:
					dmin = minf(dmin, absf(cxs - (x0 + float(wv))))
				if dmin > best_d:
					best_d = dmin
					best = cxs
			var stex: Texture2D = Sprites.cached("hsg:" + str(sp["sign"]), func() -> Texture2D:
				return PA.texture(HP.sign_board(str(sp["sign"]))))
			var sy := clampf(wh - 0.6, 1.5, 2.0)
			_tb(trim, "#2f2c38", Vector3(best, sy + 0.55, z1 + 0.34), Vector3(0.07, 0.07, 0.7))
			_tb(trim, "#2f2c38", Vector3(best, sy + 0.55, z1 + 0.7), Vector3(1.2, 0.07, 0.07))
			_tb(trim, "#2f2c38", Vector3(best, sy + 0.38, z1 + 0.24), Vector3(0.05, 0.4, 0.05))
			var sst := MeshKit.begin()
			MeshKit.quad(sst, Vector3(best - 0.58, sy + 0.55, z1 + 0.7), Vector3(best + 0.58, sy + 0.55, z1 + 0.7), Vector3(best + 0.58, sy - 0.4, z1 + 0.7), Vector3(best - 0.58, sy - 0.4, z1 + 0.7))
			node.add_child(MeshKit.finish(sst, _double(stex), false))

	# ---- jardinières sous les fenêtres et lierre d'angle, en volume
	if not grobitte:
		if bool(sp["flowers"]):
			_planters(trim, sp, windows, x0, z1)
		if bool(sp["ivy"]):
			_ivy(node, sp, x0, x1, z1, wh, door_x >= 0.0, x0 + door_x, windows)

	# ---- toutes les petites pièces, une maille par couleur
	for hex: String in trim:
		node.add_child(MeshKit.finish(trim[hex], _flat(Color.from_string(hex, Color.BLACK))))

	# ---- lumières des fenêtres (sans ombre)
	if lit:
		for wx: Variant in windows:
			b._add_light(Vector3(x0 + float(wx), 1.25, z1 + 0.6), WARM, 1.1 * glow, 3.8, false)

	world.rects.append(Rect2(x0, z0, hw, hd))
	# tout ce qui compose la maison peut s'estomper quand elle passe devant la caméra
	for n: Node in node.get_children():
		if n is GeometryInstance3D:
			parts.append(n)
	world.occluders.append({"rect": Rect2(x0, z0, hw, hd), "nodes": parts, "fade": 0.0})

	# ---- accessoires contre le mur (jamais devant la porte)
	_extra(b, sp, x0, x1, z1, xd if door_x >= 0.0 else -99.0)

	# ---- porte : passage, interaction (inchangés)
	if door_x >= 0.0:
		b._add_light(Vector3(xd, wh - 0.6, z1 + 0.55), WARM, 1.6, 4.6, true, 0.08)
		var door_pos := Vector3(xd, 0.0, z1 + 0.35)
		var to: Variant = o.get("to")
		if to is Dictionary:
			world.warps.append({"rect": Rect2(xd - 0.45, z1, 0.9, 0.52), "map": str(to.get("map", "")), "spawn": str(to.get("spawn", ""))})
			b.keep_clear.append(Vector2(xd, z1 + 0.6))
		elif o.has("dialogue"):
			b._interactable(door_pos, o, "Examiner", null, 1.6)
		else:
			b.keep_clear.append(Vector2(xd, z1 + 0.6))


## Jardinières qui dépassent sous les fenêtres du rez-de-chaussée : caisse de bois, terreau, touffes de
## feuillage et fleurs en petits cubes, retombées sur le devant. Tirage stable (graine de la maison).
static func _planters(trim: Dictionary, sp: Dictionary, windows: Array, x0: float, z1: float) -> void:
	var sd: int = int(sp["seed"])
	var blooms := ["#e86a7a", "#f2d55c", "#f4f0e2", "#b98ae0", "#ff9a3c"]
	var pair: Array[String] = [blooms[sd % 5], blooms[(sd / 5 + 2) % 5]]
	for wi in windows.size():
		var xc := x0 + float(windows[wi])
		var zc := z1 + 0.13
		var wide := 0.76
		_tb(trim, "#6e4c33", Vector3(xc, 0.93, zc), Vector3(wide, 0.2, 0.26))
		_tb(trim, "#8c6644", Vector3(xc, 1.04, z1 + 0.02 + 0.13), Vector3(wide + 0.06, 0.04, 0.3))
		_tb(trim, "#3a2a1e", Vector3(xc, 1.06, zc), Vector3(wide - 0.06, 0.03, 0.2))
		_tb(trim, "#3c281c", Vector3(xc - wide * 0.5 + 0.04, 0.78, z1 + 0.05), Vector3(0.05, 0.1, 0.07))
		_tb(trim, "#3c281c", Vector3(xc + wide * 0.5 - 0.04, 0.78, z1 + 0.05), Vector3(0.05, 0.1, 0.07))
		var n := 7
		for k in n:
			var fx := xc - wide * 0.5 + 0.07 + (wide - 0.14) * float(k) / float(n - 1)
			var hgt := 0.1 + 0.1 * PA.rnd(k, wi, sd + 3)
			var gh: String = ["#3f7d43", "#4f9148", "#2f5a34"][int(PA.rnd(k, wi, sd + 4) * 3.0) % 3]
			_tb(trim, gh, Vector3(fx, 1.08 + hgt * 0.5, zc + (PA.rnd(k, wi, sd + 5) - 0.5) * 0.08), Vector3(0.12, hgt, 0.13))
			if PA.rnd(k, wi, sd + 6) < 0.65:
				_tb(trim, pair[(k + wi) % 2], Vector3(fx + 0.01, 1.08 + hgt + 0.03, zc + 0.02), Vector3(0.08, 0.07, 0.09))
			if k % 2 == 0:
				# feuillage retombant sur le devant de la caisse
				_tb(trim, "#3f7d43", Vector3(fx, 0.97, zc + 0.14), Vector3(0.09, 0.16 + 0.06 * PA.rnd(k, wi, sd + 7), 0.04))


## Lierre qui grimpe sur un angle de la façade : trois cartes à transparence franche, de plus en plus
## décollées du mur (la plus haute et la plus étroite en avant), plus quelques rameaux pendants. Pas
## d'angle de porte : le côté est tiré de la graine puis, si une porte ou une fenêtre est trop proche,
## on prend l'autre angle.
static func _ivy(node: Node3D, sp: Dictionary, x0: float, x1: float, z1: float, wh: float, has_door: bool, xd: float, windows: Array) -> void:
	var sd: int = int(sp["seed"])
	var left := sd % 2 == 0
	var ivy_w := 1.1
	var near := func(xc: float) -> bool:
		if has_door and absf(xc - xd) < 1.5:
			return true
		for wv: Variant in windows:
			if absf(xc - (x0 + float(wv))) < 0.75:
				return true
		return false
	if near.call(x0 + 0.45 if left else x1 - 0.45):
		left = not left
	if near.call(x0 + 0.45 if left else x1 - 0.45):
		return
	var height := wh * (0.62 + 0.28 * PA.rnd(sd, 31, 5))
	var key := "hiv:%d:%d" % [sd, int(left)]
	var texs: Array = Sprites.cached(key, func() -> Array:
		var out: Array = []
		for layer in 2:
			out.append(PA.texture(HP.ivy_card(int(ivy_w * 24.0) - (4 if layer == 1 else 0), int(height * 24.0) - (24 if layer == 1 else 0), layer, sd + layer * 11)))
		return out)
	var xa := x0 + 0.02 if left else x1 - 0.02 - ivy_w
	for layer in 2:
		var st := MeshKit.begin()
		var wl := ivy_w - (0.17 if layer == 1 else 0.0)
		var hl := height - (1.0 if layer == 1 else 0.0)
		var xs := xa + (0.0 if left else (ivy_w - wl))
		var zt := z1 + (0.05 if layer == 0 else 0.07)
		var zb := z1 + (0.05 if layer == 0 else 0.17)   # la couche avant s'écarte du mur par le bas
		MeshKit.quad(st, Vector3(xs, hl, zt), Vector3(xs + wl, hl, zt), Vector3(xs + wl, 0.0, zb), Vector3(xs, 0.0, zb))
		var mi := MeshKit.finish(st, _leaf_material(texs[layer]))
		node.add_child(mi)


static func _leaf_material(tex: Texture2D) -> StandardMaterial3D:
	var m := MeshKit.pixel_material(tex)
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.5
	return m


## Tonneau, caisses ou fleurs au pied du mur, à l'écart de la porte ; sans tirage aléatoire du constructeur.
static func _extra(b, sp: Dictionary, x0: float, x1: float, z1: float, xd: float) -> void:
	var kind := str(sp["extra"])
	if kind == "":
		return
	var left := bool(sp["extra_left"])
	var x := x0 + 0.55 if left else x1 - 0.55
	if absf(x - xd) < 1.9:
		x = x1 - 0.55 if left else x0 + 0.55
		if absf(x - xd) < 1.9:
			return
	var pos := Vector3(x, 0.0, z1 + 0.5)
	match kind:
		"crates":
			var s := 0.6
			var st := MeshKit.begin()
			MeshKit.box(st, pos + Vector3(0, s * 0.5, 0), Vector3(s, s, s))
			MeshKit.box(st, pos + Vector3(0.12, s * 1.4, 0.02), Vector3(0.45, 0.45, 0.45))
			b._textured(st, "wood")
			b.world.circles.append(Vector3(pos.x, pos.z, 0.38))
		_:
			var def: Dictionary = b.PROPS.get(kind, {})
			var s_node := Sprites.make_sprite(Sprites.prop(kind, int(sp["seed"]) % int(def.get("variants", 1))), 0.0, 0.0)
			s_node.position = pos
			b.world.add_child(s_node)
			if float(def.get("solid", 0.0)) > 0.0:
				b.world.circles.append(Vector3(pos.x, pos.z, float(def["solid"])))
