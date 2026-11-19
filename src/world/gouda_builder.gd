extends RefCounted
## Styles d'architecture du chapitre 6 : « gouda » (Minas Tartine : pierre blanche, ardoise,
## sept étages), « veille » (Sentier des Insomniaques : galerie aux lits de pierre), « port »
## (Port-Salé : quais, voiles de torchon noir) et « champ » (champs du Pelle-à-Tarte). Un seul
## constructeur les sert tous ; chaque style choisit ses textures et son décor d'abords dans
## la table STYLES. Rien ici ne s'applique à une carte sans l'un de ces champs `style`.
##
## Le constructeur de cartes (MapBuilder) délègue ici :
##  - `restyle(b)` : après le sol, retouche l'aspect de la carte (parois, murs d'intérieur,
##    abords et décor lointain des cartes extérieures) ;
##  - `object(b, type, o)` : les objets propres aux styles (maison blanche, tour, rempart, porte).
## Documentation : docs/FORMAT_DONNEES.md, section « Styles du chapitre 6 ».

const PA = preload("res://src/gfx/pixel_art.gd")
const MeshKit = preload("res://src/gfx/mesh_kit.gd")
const Atmosphere = preload("res://src/world/atmosphere.gd")
const Gouda = preload("res://src/gfx/gouda_painter.gd")

const OBJECTS: Array[String] = ["gou_maison", "gou_tour", "gou_rempart", "gou_porte"]

## Par style : sol des abords, falaises, marches, parois entre deux niveaux, mur d'intérieur,
## arbres ou décors plantés autour de la carte.
const STYLES := {
	"gouda": {"outer": "gou_herbe", "cliff": "gou_rempart", "stairs": "gou_marche", "relief": "gou_rempart",
			"wall": "gou_mur", "cap": "#d8d0bc", "glow": 0.1, "trees": ["elf_pine"], "tree_count": 56, "low": ["grass", "chu_pierre"]},
	"veille": {"outer": "gou_veille", "cliff": "gou_mur_veille", "stairs": "gou_veille", "relief": "gou_mur_veille",
			"wall": "gou_mur_veille", "cap": "#0c1211", "glow": 0.2, "trees": ["gou_lit_pierre"], "tree_count": 10, "low": ["chu_pierre"]},
	"port": {"outer": "gou_quai", "cliff": "gou_rempart", "stairs": "gou_quai", "relief": "gou_rempart",
			"wall": "gou_mur", "cap": "#3a3a44", "glow": 0.05, "trees": ["gou_voile"], "tree_count": 22, "low": ["gou_baril", "gou_ancre", "chu_pierre"]},
	"champ": {"outer": "gou_herbe", "cliff": "gou_boue", "stairs": "gou_boue", "relief": "gou_boue",
			"wall": "gou_mur", "cap": "#5a4226", "glow": 0.0, "trees": ["tree"], "tree_count": 40, "low": ["grass", "gou_pieux", "gou_boulets"]},
}


static func is_gouda(b) -> bool:
	return STYLES.has(str(b.map.get("style", "")))


static func _spec(b) -> Dictionary:
	return STYLES.get(str(b.map.get("style", "")), STYLES["gouda"])


static func _node(b, node_name: String) -> MeshInstance3D:
	return b.world.get_node_or_null(node_name) as MeshInstance3D


# ===================================================================== retouche

static func restyle(b) -> void:
	var sp := _spec(b)
	var st := _node(b, "ReliefStairs")
	if st != null:
		st.material_override = MeshKit.pixel_material(Sprites.tile_texture(str(sp["stairs"])))
	var rw := _node(b, "ReliefWalls")
	if rw != null:
		var rtex: Texture2D = Sprites.tile_texture(str(sp["relief"]))
		var rm := MeshKit.pixel_material(rtex)
		if str(b.map.get("style", "")) == "gouda":   # les murs de soutènement restent blancs, même à l'ombre
			rm.emission_enabled = true
			rm.emission = Color.WHITE
			rm.emission_operator = BaseMaterial3D.EMISSION_OP_ADD
			rm.emission_texture = rtex
			rm.emission_energy_multiplier = 0.18
		rw.material_override = rm
	var water := _node(b, "Water")
	if water != null:
		var wm := water.material_override as ShaderMaterial
		if wm != null:
			var spec: Dictionary = b.map.get("water", {})
			wm.set_shader_parameter("deep", Color(str(spec.get("deep", "#1a3a5a"))))
			wm.set_shader_parameter("shallow", Color(str(spec.get("shallow", "#4a8aa0"))))
			wm.set_shader_parameter("ripple", Color(str(spec.get("ripple", "#d8f0f4"))))
			wm.set_shader_parameter("glint", Color(str(spec.get("glint", "#ffffff"))))
	if bool(b.map.get("interior", false)):
		_restyle_interior(b, sp)
	else:
		_restyle_exterior(b, sp)


static func _restyle_interior(b, sp: Dictionary) -> void:
	var walls := _node(b, "Walls")
	if walls != null:
		var tex: Texture2D = Sprites.tile_texture(str(b.map.get("wall_tile", sp["wall"])))
		var m := MeshKit.pixel_material(tex)
		m.emission_enabled = true
		m.emission = Color.WHITE
		m.emission_operator = BaseMaterial3D.EMISSION_OP_ADD
		m.emission_texture = tex
		m.emission_energy_multiplier = float(b.map.get("wall_glow", sp["glow"]))
		walls.material_override = m
	var caps := _node(b, "WallCaps")
	if caps != null:
		caps.material_override = MeshKit.flat_material(Color(str(b.map.get("wall_cap", sp["cap"]))))


static func _restyle_exterior(b, sp: Dictionary) -> void:
	var outer := _node(b, "Outskirts")
	if outer != null:
		outer.material_override = MeshKit.ground_material(Sprites.tile_texture(str(sp["outer"])))
	var cliffs := _node(b, "Cliffs")
	if cliffs != null:
		cliffs.material_override = MeshKit.ground_material(Sprites.tile_texture(str(sp["cliff"])), 0.1)
	_surround(b, sp)
	if str(b.map.get("style", "")) == "gouda":
		_retaining(b)
		_skyline(b)
		_siege(b)


## Arbres ou décors plantés autour de la carte, puis un sous-bois bas.
static func _surround(b, sp: Dictionary) -> void:
	var rng: RandomNumberGenerator = b.rng
	var trees: Array = sp["trees"]
	var n := int(sp["tree_count"])
	for i in n:
		var p := Vector3.ZERO
		if i % 4 == 3 and b.map.has("skyline"):
			continue   # le nord est pris par les étages du fond
		if i % 4 == 2 and b.map.has("horizon"):
			continue   # la caméra basse des cartes à horizon se tient au sud : pas d'arbre qui lui masque le bas
		match i % 4:
			0: p = Vector3(rng.randf_range(-16.0, -0.9), 0.0, rng.randf_range(-1.0, float(b.h) + 6.0))
			1: p = Vector3(rng.randf_range(b.w + 0.9, b.w + 16.0), 0.0, rng.randf_range(-1.0, float(b.h) + 6.0))
			2: p = Vector3(rng.randf_range(-6.0, b.w + 6.0), 0.0, rng.randf_range(float(b.h) + 0.7, float(b.h) + 9.0))
			_: p = Vector3(rng.randf_range(-12.0, b.w + 12.0), 0.0, rng.randf_range(-12.0, -0.8))
		p.y = b._terrace_height(p.x, p.z)
		b._prop(str(trees[i % trees.size()]), {"solid": 0.0, "shadow": false, "scale": rng.randf_range(0.9, 1.25)}, p)
	var low: Array = sp["low"]
	for i in n:
		var p := Vector3(rng.randf_range(-12.0, b.w + 12.0), 0.0, rng.randf_range(-9.0, float(b.h) + 6.0))
		if p.x > 0.0 and p.x < b.w and p.z > 0.0 and p.z < b.h:
			continue
		if p.z < 0.0 and b.map.has("skyline"):
			continue
		p.y = b._terrace_height(p.x, p.z)
		b._prop(str(low[i % low.size()]), {"solid": 0.0, "shadow": false}, p)


# ===================================================== étages : murs de soutènement

## Murs de soutènement de la ville haute : sous chaque terrasse dont le bord sud donne sur un
## vide (la tranchée entre deux niveaux), une paroi de pierre blanche descend jusqu'au sol,
## couronnée de créneaux ; le fond de la tranchée est dallé (champ `hole_tile` : autre tuile,
## la boue de la plaine pour la Croûte). Les passages et les collisions ne
## changent pas : tout est décor, posé hors de la case.
static func _retaining(b) -> void:
	var relief: bool = b.world.has_relief
	var walls := MeshKit.begin()
	var tops := MeshKit.begin()
	var floor_st := MeshKit.begin()
	var any := false
	for ty in b.h:
		for tx in b.w:
			var i: int = ty * b.w + tx
			if b._flag(b.cells[i], "hole"):
				var fx := float(tx)
				var fz := float(ty)
				MeshKit.quad(floor_st, Vector3(fx, 0.0, fz), Vector3(fx + 1.0, 0.0, fz), Vector3(fx + 1.0, 0.0, fz + 1.0), Vector3(fx, 0.0, fz + 1.0), Vector2(fx * 0.5, fz * 0.5), Vector2((fx + 1.0) * 0.5, (fz + 1.0) * 0.5))
				continue
			if not relief or ty + 1 >= b.h or b.world.stair_idx[i] >= 0:
				continue
			if not b._flag(b.cells[i + b.w], "hole"):
				continue
			var top: float = b.world.cell_h[i]
			if top < 0.1:
				continue
			any = true
			var x0 := float(tx)
			var z := float(ty + 1)
			MeshKit.quad(walls, Vector3(x0, top, z), Vector3(x0 + 1.0, top, z), Vector3(x0 + 1.0, 0.0, z), Vector3(x0, 0.0, z), Vector2(x0 * 0.5, (4.0 - top) * 0.5), Vector2((x0 + 1.0) * 0.5, 2.0))
			if tx % 2 == 0:   # créneaux au bord de la terrasse, une case sur deux
				MeshKit.box(tops, Vector3(x0 + 0.5, top + 0.3, z + 0.22), Vector3(0.9, 0.6, 0.44))
			MeshKit.quad(tops, Vector3(x0, top + 0.02, z), Vector3(x0 + 1.0, top + 0.02, z), Vector3(x0 + 1.0, top + 0.02, z + 0.44), Vector3(x0, top + 0.02, z + 0.44))
	if any:
		var wm := MeshKit.pixel_material(Sprites.tile_texture("gou_rempart"))
		var node := MeshKit.finish(walls, wm, true)
		node.name = "GoudaSoutenement"
		b.world.add_child(node)
		var cm := MeshKit.pixel_material(Sprites.tile_texture("gou_rempart"))
		var cn := MeshKit.finish(tops, cm, true)
		cn.name = "GoudaCreneaux"
		b.world.add_child(cn)
	var fl := MeshKit.finish(floor_st, MeshKit.ground_material(Sprites.tile_texture(str(b.map.get("hole_tile", "gou_mur"))), 0.1), false)
	fl.name = "GoudaTranchee"
	b.world.add_child(fl)


# ====================================================== le siège, vu des murs

## Le camp assiégeant qui s'étend au nord de la Croûte (champ `siege`) : un champ de boue
## qui prolonge la carte, des tentes, des brasiers, des pieux et des trébuchets en désordre,
## et des colonnes de fumée sombre qui montent des feux. Tout est décor, sans collision.
## Champs : `fires` (nombre de feux, 8), `depth` (profondeur du camp, 30).
static func _siege(b) -> void:
	var sg: Dictionary = b.map.get("siege", {})
	if sg.is_empty():
		return
	var depth := float(sg.get("depth", 30.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(b.map.get("id", "")) + "siege")
	var parent := Node3D.new()
	parent.name = "GoudaSiege"
	b.world.add_child(parent)
	var st := MeshKit.begin()
	MeshKit.quad(st, Vector3(-22.0, 0.0, -depth), Vector3(float(b.w) + 22.0, 0.0, -depth), Vector3(float(b.w) + 22.0, 0.0, -0.6), Vector3(-22.0, 0.0, -0.6),
			Vector2(-11.0, -depth * 0.5), Vector2((float(b.w) + 22.0) * 0.5, -0.3))
	var mud := MeshKit.finish(st, MeshKit.ground_material(Sprites.tile_texture("gou_boue"), 0.12), false)
	mud.position.y = 0.06
	parent.add_child(mud)
	var kinds: Array = ["gou_tente", "gou_pieux", "gou_brasier", "gou_tente", "gou_boulets", "gou_trebuchet", "gou_tente", "gou_brasier"]
	var fires: Array[Vector3] = []
	for i in int(sg.get("fires", 8)) * 3:
		var p := Vector3(rng.randf_range(-16.0, float(b.w) + 16.0), 0.0, rng.randf_range(-depth + 4.0, -2.0))
		var kind := str(kinds[i % kinds.size()])
		p.y = 0.06
		b._prop(kind, {"solid": 0.0, "shadow": false}, p)
		if kind == "gou_brasier":
			fires.append(p)
	var puff := GradientTexture2D.new()
	var grad := Gradient.new()
	grad.colors = PackedColorArray([Color(0.30, 0.27, 0.26, 0.55), Color(0.30, 0.27, 0.26, 0.0)])
	puff.gradient = grad
	puff.fill = GradientTexture2D.FILL_RADIAL
	puff.fill_from = Vector2(0.5, 0.5)
	puff.fill_to = Vector2(1.0, 0.5)
	puff.width = 64
	puff.height = 64
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_texture = puff
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	for fp: Vector3 in fires:
		for k in 7:
			var q := QuadMesh.new()
			var sz := 1.2 + float(k) * 0.7
			q.size = Vector2(sz, sz)
			var n := MeshInstance3D.new()
			n.mesh = q
			n.material_override = mat
			n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			n.position = fp + Vector3(float(k) * 0.35 + rng.randf_range(-0.3, 0.3), 1.6 + float(k) * 1.5, rng.randf_range(-0.3, 0.3))
			parent.add_child(n)


# ================================================================ étages du fond

## Les étages de la ville qui montent derrière la carte (champ `skyline`) : pour chaque
## niveau, un mur de soutènement crénelé (bannières du Poirier au pied), des maisons blanches
## à toit d'ardoise, puis la Tour Blanche, son étendard, et l'éperon de roche qui fend la ville.
## Champs : `base` (hauteur du bord nord de la carte), `z` (où commence le premier mur),
## `rings` (nombre d'étages), `step` (hauteur gagnée par étage), `gap` (profondeur d'un étage),
## `tower` (vrai : Tour Blanche et éperon), `tower_x`. Tout est décor, sans collision.
static func _skyline(b) -> void:
	var sk: Dictionary = b.map.get("skyline", {})
	if sk.is_empty():
		return
	var base := float(sk.get("base", 0.0))
	var z0 := float(sk.get("z", -8.0))
	var rings := int(sk.get("rings", 4))
	var step := float(sk.get("step", 3.2))
	var gap := float(sk.get("gap", 7.0))
	var span_x0 := -18.0
	var span_x1 := float(b.w) + 18.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(b.map.get("id", "")) + "fond")
	var parent := Node3D.new()
	parent.name = "GoudaFond"
	b.world.add_child(parent)
	var walls := MeshKit.begin()
	var roofs := MeshKit.begin()
	var tops := MeshKit.begin()
	var glass := MeshKit.begin()
	var spur := MeshKit.begin()
	var tower_x := float(sk.get("tower_x", float(b.w) * 0.5))
	var top_h := base
	for k in rings:
		var hk := base + step * float(k + 1)
		top_h = hk
		var zf := z0 - float(k) * gap              # face sud du mur de l'étage
		var zb := zf - gap                          # fond de l'étage
		MeshKit.box(walls, Vector3((span_x0 + span_x1) * 0.5, (hk - 2.0) * 0.5, (zf + zb) * 0.5), Vector3(span_x1 - span_x0, hk + 2.0, zf - zb))
		var cx := span_x0
		while cx < span_x1:   # créneaux
			MeshKit.box(tops, Vector3(cx, hk + 0.3, zf - 0.25), Vector3(0.8, 0.6, 0.5))
			cx += 1.7
		# maisons de l'étage
		var hx := span_x0 + rng.randf_range(0.0, 3.0)
		while hx < span_x1 - 4.0:
			var hw := rng.randf_range(3.0, 5.5)
			var hd := rng.randf_range(2.6, 3.6)
			var hh := rng.randf_range(2.4, 3.6)
			if absf(hx + hw * 0.5 - tower_x) > 4.5 or not bool(sk.get("tower", false)):
				_deco_house(walls, roofs, glass, Vector3(hx + hw * 0.5, hk, zb + gap * 0.5 + 0.6), Vector3(hw, hh, hd), rng)
			hx += hw + rng.randf_range(0.8, 2.6)
		# bannières du Poirier et brasiers au pied du mur
		var bx := span_x0 + 4.0 + float(k) * 2.3
		while bx < span_x1 - 3.0:
			b._prop("gou_banniere", {"solid": 0.0, "shadow": false}, Vector3(bx, hk - 3.0 if k == 0 else hk - 3.0, zf + 0.35))
			bx += 9.0
	if bool(sk.get("tower", false)):
		var zt := z0 - float(rings) * gap + 1.0
		var tw := 4.6
		var y := top_h
		# l'éperon : roche nue sous la tour, plus haute que le dernier étage
		var rock_h := 9.0
		var sx := tower_x
		for q in 4:
			var wq := 12.0 - float(q) * 2.4
			MeshKit.box(spur, Vector3(sx, top_h - 2.0 + (rock_h * (float(q) + 0.5) / 4.0) * 0.5 + float(q) * rock_h * 0.125, zt + 2.0 - float(q) * 0.6), Vector3(wq, rock_h * (float(q) + 1.0) / 4.0 + 4.0, 7.0 - float(q) * 0.8))
		y = top_h + rock_h
		# la Tour Blanche, trois fûts qui rétrécissent
		for q in 3:
			var wq := tw - float(q) * 0.9
			var hq := 7.0 - float(q) * 0.8
			MeshKit.box(walls, Vector3(tower_x, y + hq * 0.5, zt), Vector3(wq, hq, wq))
			MeshKit.box(tops, Vector3(tower_x, y + hq + 0.15, zt), Vector3(wq + 0.5, 0.3, wq + 0.5))
			for wn in 2:
				MeshKit.box(glass, Vector3(tower_x + (float(wn) - 0.5) * wq * 0.45, y + hq * 0.6, zt + wq * 0.5 + 0.03), Vector3(0.34, 0.95, 0.05))
			y += hq + 0.3
		var apex := Vector3(tower_x, y + 3.2, zt)
		var hh2 := 1.7
		MeshKit.tri(roofs, Vector3(tower_x - hh2, y, zt + hh2), apex, Vector3(tower_x + hh2, y, zt + hh2), Vector2(0, 2), Vector2(1, 0), Vector2(2, 2))
		MeshKit.tri(roofs, Vector3(tower_x + hh2, y, zt - hh2), apex, Vector3(tower_x - hh2, y, zt - hh2), Vector2(0, 2), Vector2(1, 0), Vector2(2, 2))
		MeshKit.tri(roofs, Vector3(tower_x - hh2, y, zt - hh2), apex, Vector3(tower_x - hh2, y, zt + hh2), Vector2(0, 2), Vector2(1, 0), Vector2(2, 2))
		MeshKit.tri(roofs, Vector3(tower_x + hh2, y, zt + hh2), apex, Vector3(tower_x + hh2, y, zt - hh2), Vector2(0, 2), Vector2(1, 0), Vector2(2, 2))
		# mât, étendard bleu nuit au Poirier blanc
		_box_in(parent, apex + Vector3(0.0, 1.4, 0.0), Vector3(0.1, 2.8, 0.1), MeshKit.flat_material(Color("#e8c050")))
		var cloth := MeshKit.flat_material(Color("#27365e"), 0.3)
		_box_in(parent, apex + Vector3(0.8, 2.1, 0.0), Vector3(1.6, 1.0, 0.06), cloth)
		var white := MeshKit.flat_material(Color("#f4f0e4"), 0.5)
		_box_in(parent, apex + Vector3(0.8, 2.0, 0.05), Vector3(0.1, 0.5, 0.04), white)
		_box_in(parent, apex + Vector3(0.8, 2.3, 0.05), Vector3(0.5, 0.3, 0.04), white)
	var stone := MeshKit.pixel_material(Sprites.tile_texture("gou_rempart"))
	var slate := MeshKit.pixel_material(Sprites.tile_texture("gou_ardoise"))
	slate.cull_mode = BaseMaterial3D.CULL_DISABLED
	var lit := MeshKit.flat_material(Color("#f6d68a"), 1.4)
	var rock := MeshKit.pixel_material(Sprites.tile_texture("gou_roche"))
	for pair: Array in [[walls, stone], [tops, stone], [roofs, slate], [glass, lit], [spur, rock]]:
		var node := MeshKit.finish(pair[0], pair[1], false)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(node)


## Maison blanche du fond : un volume, un toit d'ardoise à deux pentes, une fenêtre allumée.
static func _deco_house(walls: SurfaceTool, roofs: SurfaceTool, glass: SurfaceTool, base: Vector3, size: Vector3, rng: RandomNumberGenerator) -> void:
	MeshKit.box(walls, base + Vector3(0.0, size.y * 0.5, 0.0), size)
	var x0 := base.x - size.x * 0.5 - 0.3
	var x1 := base.x + size.x * 0.5 + 0.3
	var zf := base.z + size.z * 0.5 + 0.3
	var zb := base.z - size.z * 0.5 - 0.3
	var zm := base.z
	var ye := base.y + size.y - 0.1
	var top := ye + minf(size.z * 0.5 + 0.3, 1.8)
	var sl := (size.z * 0.5 + 0.3) * 1.4
	MeshKit.quad(roofs, Vector3(x0, top, zm), Vector3(x1, top, zm), Vector3(x1, ye, zf), Vector3(x0, ye, zf), Vector2.ZERO, Vector2((x1 - x0) / 2.0, sl / 2.0))
	MeshKit.quad(roofs, Vector3(x1, top, zm), Vector3(x0, top, zm), Vector3(x0, ye, zb), Vector3(x1, ye, zb), Vector2.ZERO, Vector2((x1 - x0) / 2.0, sl / 2.0))
	MeshKit.tri(roofs, Vector3(x0, ye, zb), Vector3(x0, top, zm), Vector3(x0, ye, zf), Vector2(0, 1), Vector2(0.7, 0), Vector2(1.4, 1))
	MeshKit.tri(roofs, Vector3(x1, ye, zf), Vector3(x1, top, zm), Vector3(x1, ye, zb), Vector2(0, 1), Vector2(0.7, 0), Vector2(1.4, 1))
	for k in 1 + int(size.x / 2.6):
		if rng.randf() < 0.7:
			MeshKit.box(glass, Vector3(base.x - size.x * 0.5 + 0.9 + float(k) * 2.2, base.y + size.y * 0.55, base.z + size.z * 0.5 + 0.03), Vector3(0.34, 0.8, 0.05))


# ========================================================================= objets

static func object(b, type: String, o: Dictionary) -> bool:
	match type:
		"gou_maison": _house(b, o)
		"gou_tour": _tower(b, o)
		"gou_rempart": _wall(b, o)
		"gou_porte": _gate(b, o)
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


static func _stone_mat(wd: float, hgt: float) -> StandardMaterial3D:
	var m := MeshKit.pixel_material(Sprites.tile_texture("gou_rempart"))
	m.uv1_scale = Vector3(wd / 2.0, hgt / 2.0, 1.0)
	return m


## Maison blanche à toit d'ardoise. Champs : `rect` [x, z, largeur, profondeur] (pieds), `height`
## (4,2 : deux étages à partir de 5), `door` (abscisse de la porte dans la façade, -1 : sans),
## `windows` (abscisses des fenêtres), `lit` (vrai), `to` {map, spawn} (la porte mène à un intérieur)
## ou `dialogue` (la porte se lit), `chimney` (vrai). Bloque le passage.
static func _house(b, o: Dictionary) -> void:
	var r: Array = o.get("rect", [0, 0, 6, 4])
	var x0 := float(r[0])
	var z0 := float(r[1])
	var hw := float(r[2])
	var hd := float(r[3])
	var x1 := x0 + hw
	var z1 := z0 + hd
	var wh := float(o.get("height", 4.2))
	var door_x := float(o.get("door", hw * 0.5))
	var windows: Array = o.get("windows", [hw * 0.2, hw * 0.8])
	var lit := bool(o.get("lit", true))
	var enter: bool = o.get("to") is Dictionary
	var parent := Node3D.new()
	parent.name = "GoudaMaison"
	b.world.add_child(parent)
	var parts: Array = []
	var st := MeshKit.begin()
	MeshKit.box(st, Vector3((x0 + x1) * 0.5, wh * 0.5, (z0 + z1) * 0.5), Vector3(hw, wh, hd))
	var body := MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture("gou_rempart")))
	parent.add_child(body)
	parts.append(body)
	var front: Dictionary = Sprites.cached("gfront:%s:%s:%s" % [str(b.map.get("id", "")), str(r), str(enter)], func() -> Dictionary:
		var f := Gouda.facade(hw, wh, door_x, windows, lit, enter)
		return {"albedo": PA.texture(f["albedo"]), "emission": PA.texture(f["emission"])})
	st = MeshKit.begin()
	MeshKit.quad(st, Vector3(x0, wh, z1 + 0.02), Vector3(x1, wh, z1 + 0.02), Vector3(x1, 0, z1 + 0.02), Vector3(x0, 0, z1 + 0.02))
	var face := MeshKit.finish(st, MeshKit.pixel_material(front["albedo"], front["emission"], 2.0))
	parent.add_child(face)
	parts.append(face)
	# toit d'ardoise à deux pentes, faîtage le long de la façade
	var ov := 0.5
	var rh := minf(hd * 0.5 + ov, 2.6)
	var top := wh + rh
	var xl := x0 - ov
	var xr := x1 + ov
	var zf := z0 - ov
	var zb := z1 + ov
	var zm := (z0 + z1) * 0.5
	var ye := wh - 0.2
	var slope := Vector2(zb - zm, rh + 0.2).length() / 2.0
	st = MeshKit.begin()
	MeshKit.quad(st, Vector3(xl, top, zm), Vector3(xr, top, zm), Vector3(xr, ye, zb), Vector3(xl, ye, zb), Vector2.ZERO, Vector2((xr - xl) / 2.0, slope))
	MeshKit.quad(st, Vector3(xr, top, zm), Vector3(xl, top, zm), Vector3(xl, ye, zf), Vector3(xr, ye, zf), Vector2.ZERO, Vector2((xr - xl) / 2.0, slope))
	MeshKit.tri(st, Vector3(xl, ye, zf), Vector3(xl, top, zm), Vector3(xl, ye, zb), Vector2(0, slope), Vector2(slope * 0.5, 0), Vector2(slope * 2.0, slope))
	MeshKit.tri(st, Vector3(xr, ye, zb), Vector3(xr, top, zm), Vector3(xr, ye, zf), Vector2(0, slope), Vector2(slope * 0.5, 0), Vector2(slope * 2.0, slope))
	var roof_mat := MeshKit.pixel_material(Sprites.tile_texture("gou_ardoise"))
	roof_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var roof := MeshKit.finish(st, roof_mat)
	parent.add_child(roof)
	parts.append(roof)
	parts.append(_box_in(parent, Vector3((xl + xr) * 0.5, top + 0.05, zm), Vector3(xr - xl, 0.14, 0.18), MeshKit.flat_material(Color("#d8d4c8"))))
	if bool(o.get("chimney", true)):
		parts.append(_box_in(parent, Vector3(x0 + hw * 0.78, top + 0.1, zm - 0.3), Vector3(0.5, 1.2, 0.5), _stone_mat(0.5, 1.2)))
	b.world.rects.append(Rect2(x0, z0, hw, hd))
	if lit:
		for wx: Variant in windows:
			b._add_light(Vector3(x0 + float(wx), 1.4, z1 + 0.7), Color("#ffe4ae"), 0.8, 3.4, false)
	if door_x >= 0.0:
		var xd := x0 + door_x
		var door_pos := Vector3(xd, 0.0, z1 + 0.35)
		var to: Variant = o.get("to")
		if to is Dictionary:
			b.world.warps.append({"rect": Rect2(xd - 0.45, z1, 0.9, 0.52), "map": str((to as Dictionary).get("map", "")), "spawn": str((to as Dictionary).get("spawn", ""))})
			b.keep_clear.append(Vector2(xd, z1 + 0.6))
		elif o.has("dialogue"):
			b._interactable(door_pos, o, "Examiner", null, 1.6)
		else:
			b.keep_clear.append(Vector2(xd, z1 + 0.6))
	b.world.occluders.append({"rect": Rect2(x0, z0, hw, hd), "nodes": parts, "fade": 0.0})


## Tour carrée à créneaux et chapeau d'ardoise. Champs : `pos` (centre du pied), `size` (3),
## `height` (7), `cap` (vrai : toit pointu ; faux : terrasse crénelée). Bloque le passage.
static func _tower(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var sz := float(o.get("size", 3.0))
	var hgt := float(o.get("height", 7.0))
	var parent := Node3D.new()
	parent.name = "GoudaTour"
	b.world.add_child(parent)
	var parts: Array = []
	parts.append(_box_in(parent, p + Vector3(0.0, hgt * 0.5, 0.0), Vector3(sz, hgt, sz), _stone_mat(sz, hgt)))
	parts.append(_box_in(parent, p + Vector3(0.0, hgt + 0.1, 0.0), Vector3(sz + 0.5, 0.25, sz + 0.5), MeshKit.flat_material(Color("#d8d0bc"))))
	var dark := MeshKit.flat_material(Color("#1c2234"))
	for k in 3:   # meurtrières allumées
		parts.append(_box_in(parent, p + Vector3(0.0, 1.8 + k * 1.9, sz * 0.5 + 0.02), Vector3(0.28, 0.9, 0.06), dark))
	if bool(o.get("cap", true)):
		var st := MeshKit.begin()
		var a := Vector3(p.x, p.y + hgt + 2.6, p.z)
		var h2 := sz * 0.5 + 0.35
		var y0 := p.y + hgt + 0.25
		MeshKit.tri(st, Vector3(p.x - h2, y0, p.z + h2), a, Vector3(p.x + h2, y0, p.z + h2), Vector2(0, 2), Vector2(1, 0), Vector2(2, 2))
		MeshKit.tri(st, Vector3(p.x + h2, y0, p.z - h2), a, Vector3(p.x - h2, y0, p.z - h2), Vector2(0, 2), Vector2(1, 0), Vector2(2, 2))
		MeshKit.tri(st, Vector3(p.x - h2, y0, p.z - h2), a, Vector3(p.x - h2, y0, p.z + h2), Vector2(0, 2), Vector2(1, 0), Vector2(2, 2))
		MeshKit.tri(st, Vector3(p.x + h2, y0, p.z + h2), a, Vector3(p.x + h2, y0, p.z - h2), Vector2(0, 2), Vector2(1, 0), Vector2(2, 2))
		var mat := MeshKit.pixel_material(Sprites.tile_texture("gou_ardoise"))
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var cap := MeshKit.finish(st, mat)
		parent.add_child(cap)
		parts.append(cap)
		parts.append(_box_in(parent, a + Vector3(0.0, 0.5, 0.0), Vector3(0.06, 1.0, 0.06), MeshKit.flat_material(Color("#e8c050"))))
	else:
		var m := _stone_mat(0.6, 0.6)
		for ix in 3:
			for iz in 3:
				if ix == 1 and iz == 1:
					continue
				parts.append(_box_in(parent, p + Vector3((ix - 1) * (sz * 0.5 - 0.1), hgt + 0.55, (iz - 1) * (sz * 0.5 - 0.1)), Vector3(0.5, 0.6, 0.5), m))
	b.world.rects.append(Rect2(p.x - sz * 0.5, p.z - sz * 0.5, sz, sz))
	b.world.occluders.append({"rect": Rect2(p.x - sz * 0.5, p.z - sz * 0.5, sz, sz), "nodes": parts, "fade": 0.0})


## Rempart crénelé le long d'une ligne brisée de segments horizontaux ou verticaux. Champs :
## `points`, `height` (2,4), `thick` (0,9). Bloque le passage.
static func _wall(b, o: Dictionary) -> void:
	var pts: Array = o.get("points", [])
	var hgt := float(o.get("height", 2.4))
	var th := float(o.get("thick", 0.9))
	var mat := MeshKit.pixel_material(Sprites.tile_texture("gou_rempart"))
	for i in range(pts.size() - 1):
		var st := MeshKit.begin()
		var pa: Array = pts[i]
		var pc: Array = pts[i + 1]
		var a := Vector2(float(pa[0]), float(pa[1]))
		var c := Vector2(float(pc[0]), float(pc[1]))
		var lo := Vector2(minf(a.x, c.x), minf(a.y, c.y))
		var hi := Vector2(maxf(a.x, c.x), maxf(a.y, c.y))
		var base: float = b.world.ground_y((a.x + c.x) * 0.5, (a.y + c.y) * 0.5)
		var size := Vector3(maxf(hi.x - lo.x, th), hgt, maxf(hi.y - lo.y, th))
		var center := Vector3((lo.x + hi.x) * 0.5, base + hgt * 0.5, (lo.y + hi.y) * 0.5)
		MeshKit.box(st, center, size)
		var length := maxf(size.x, size.z)
		var n := int(length / 1.3)
		for k in range(n + 1):
			var t := float(k) / float(maxi(1, n))
			var q := Vector2(lerpf(lo.x, hi.x, t), lerpf(lo.y, hi.y, t))
			MeshKit.box(st, Vector3(q.x, base + hgt + 0.25, q.y), Vector3(0.62, 0.5, 0.62))
		var r := Rect2(center.x - size.x * 0.5, center.z - size.z * 0.5, size.x, size.z)
		b.world.rects.append(r)
		var node := MeshKit.finish(st, mat)
		node.name = "GoudaRempart"
		b.world.add_child(node)
		b.world.occluders.append({"rect": r, "nodes": [node], "fade": 0.0})   # s'estompe quand il passe devant le héros


## Grande Porte : deux tours, un linteau et un porche sombre où l'on passe (herse relevée).
## Champs : `pos` (centre du pied), `gap` (largeur du passage, 3), `height` (6). Seuls les
## deux piliers bloquent le passage.
static func _gate(b, o: Dictionary) -> void:
	var p: Vector3 = b._p(o)
	var gap := float(o.get("gap", 3.0))
	var hgt := float(o.get("height", 6.0))
	var tw := 3.0
	var parent := Node3D.new()
	parent.name = "GoudaPorte"
	b.world.add_child(parent)
	var parts: Array = []
	for s: float in [-1.0, 1.0]:
		var cx := p.x + s * (gap * 0.5 + tw * 0.5)
		parts.append(_box_in(parent, Vector3(cx, p.y + hgt * 0.5, p.z), Vector3(tw, hgt, 2.4), _stone_mat(tw, hgt)))
		parts.append(_box_in(parent, Vector3(cx, p.y + hgt + 0.15, p.z), Vector3(tw + 0.5, 0.3, 2.9), MeshKit.flat_material(Color("#d8d0bc"))))
		for k in 3:
			parts.append(_box_in(parent, Vector3(cx + (k - 1) * 1.0, p.y + hgt + 0.55, p.z + 1.2), Vector3(0.6, 0.6, 0.5), _stone_mat(0.6, 0.6)))
		b.world.rects.append(Rect2(cx - tw * 0.5, p.z - 1.2, tw, 2.4))
	parts.append(_box_in(parent, Vector3(p.x, p.y + hgt - 0.7, p.z), Vector3(gap + 0.2, 1.4, 2.4), _stone_mat(gap, 1.4)))
	parts.append(_box_in(parent, Vector3(p.x, p.y + hgt + 0.15, p.z), Vector3(gap + 0.4, 0.3, 2.9), MeshKit.flat_material(Color("#d8d0bc"))))
	b.world.occluders.append({"rect": Rect2(p.x - gap * 0.5 - tw, p.z - 1.2, gap + tw * 2.0, 2.4), "nodes": parts, "fade": 0.0})
	var wood := MeshKit.flat_material(Color("#3a2a1c"))
	for k in 5:   # herse relevée sous le linteau
		_box_in(parent, Vector3(p.x - gap * 0.4 + k * gap * 0.2, p.y + hgt - 1.6, p.z + 0.4), Vector3(0.1, 0.8, 0.1), wood)
	var banner := MeshKit.flat_material(Color("#27365e"))
	_box_in(parent, Vector3(p.x, p.y + hgt - 2.6, p.z + 1.25), Vector3(1.0, 1.6, 0.05), banner)
	_box_in(parent, Vector3(p.x, p.y + hgt - 2.4, p.z + 1.29), Vector3(0.12, 0.5, 0.03), MeshKit.flat_material(Color("#f4f0e4")))
	_box_in(parent, Vector3(p.x, p.y + hgt - 2.0, p.z + 1.29), Vector3(0.5, 0.4, 0.03), MeshKit.flat_material(Color("#f4f0e4")))
	for s: float in [-1.0, 1.0]:
		var torch := Atmosphere.make_light(Color("#ffc870"), 1.6, 5.5, false, 0.2)
		torch.position = Vector3(p.x + s * (gap * 0.5 + 0.4), p.y + 2.2, p.z + 1.6)
		parent.add_child(torch)
