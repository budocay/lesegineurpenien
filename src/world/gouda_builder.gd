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
const Tower = preload("res://src/world/gouda_tower.gd")
const SMOKE_SHADER = preload("res://src/gfx/shaders/fumee.gdshader")
const HALO_SHADER = preload("res://src/gfx/shaders/halo_feu.gdshader")
const FLAG_SHADER = preload("res://src/gfx/shaders/tour_etendard.gdshader")

const OBJECTS: Array[String] = ["gou_maison", "gou_tour", "gou_rempart", "gou_porte", "gou_deco", "gou_pavage"]

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
	var t0 := Time.get_ticks_msec()
	_surround(b, sp)
	_apron(b)
	_belvedere(b)
	if str(b.map.get("style", "")) == "gouda":
		_retaining(b)
		_skyline(b)
		_siege(b)
		_white_tower(b)
		if OS.get_environment("GLAN_HZ_TIME") != "":
			print("GOUDA %s : %d ms" % [str(b.map.get("id", "?")), Time.get_ticks_msec() - t0])


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
		if b.map.has("apron") and p.z > float(b.h) - 2.0:
			continue   # le parvis reste dégagé : un rocher posé devant la caméra basse serait un gros flou gris
		p.y = b._terrace_height(p.x, p.z)
		b._prop(str(low[i % low.size()]), {"solid": 0.0, "shadow": false}, p)


## Parvis au sud d'une carte à horizon (champ `apron`) : la caméra basse voit loin devant le joueur ;
## plutôt que l'herbe nue des abords, le dallage de la rue se prolonge (aucun mur : la caméra
## basse le verrait entre elle et le joueur). Champs : `depth` (profondeur, 10), `from` (où le dallage de
## la carte s'arrête, défaut le bord sud), `x0` et `x1` (étendue du dallage, défaut la largeur de la carte), `tile` (dalle, `gou_pave`). Tout est décor.
static func _apron(b) -> void:
	var ap: Variant = b.map.get("apron")
	if not (ap is Dictionary):
		return
	var depth := float((ap as Dictionary).get("depth", 10.0))
	var x0 := float((ap as Dictionary).get("x0", 0.0))
	var x1 := float((ap as Dictionary).get("x1", float(b.w)))
	var z0 := float((ap as Dictionary).get("from", float(b.h)))   # `from` : bord sud du dallage de la carte (les rangées de vide au-delà sont recouvertes)
	var z1 := float(b.h) + depth
	var parent := Node3D.new()
	parent.name = "GoudaParvis"
	b.world.add_child(parent)
	var st := MeshKit.begin()
	MeshKit.quad(st, Vector3(x0, 0.02, z0), Vector3(x1, 0.02, z0), Vector3(x1, 0.02, z1), Vector3(x0, 0.02, z1),
			Vector2(x0 * 0.5, z0 * 0.5), Vector2(x1 * 0.5, z1 * 0.5))
	var floor_node := MeshKit.finish(st, MeshKit.ground_material(Sprites.tile_texture(str((ap as Dictionary).get("tile", "gou_pave"))), 0.1), false)
	parent.add_child(floor_node)


## Belvédère (champ `belvedere`) : le nord de la carte s'ouvre sur le vide. L'herbe et les talus
## qui bouchaient la vue au nord disparaissent (les abords est, ouest et sud restent), et les plans de
## l'horizon passent sous le sol de la carte : on domine la ville en contrebas et la plaine.
## Champ : `z` (profondeur du bord, défaut 0).
static func _belvedere(b) -> void:
	var bv: Variant = b.map.get("belvedere")
	if not (bv is Dictionary):
		return
	var outer := _node(b, "Outskirts")
	if outer != null:
		outer.visible = false
	var cliffs := _node(b, "Cliffs")
	if cliffs != null:
		cliffs.visible = false
	var zn := float((bv as Dictionary).get("z", 0.0))
	var far := 70.0
	var st := MeshKit.begin()
	for r: Array in [[-far, zn, 0.0, float(b.h)], [float(b.w), zn, float(b.w) + far, float(b.h)], [-far, float(b.h), float(b.w) + far, float(b.h) + far]]:
		var ax: float = r[0]
		var az: float = r[1]
		var bx2: float = r[2]
		var bz: float = r[3]
		MeshKit.quad(st, Vector3(ax, 0.0, az), Vector3(bx2, 0.0, az), Vector3(bx2, 0.0, bz), Vector3(ax, 0.0, bz), Vector2(ax * 0.5, az * 0.5), Vector2(bx2 * 0.5, bz * 0.5))
	var node := MeshKit.finish(st, MeshKit.ground_material(Sprites.tile_texture(str(_spec(b)["outer"]))), false)
	node.name = "GoudaAbords"
	b.world.add_child(node)
	if (bv as Dictionary).has("terraces"):
		_terraces(b, (bv as Dictionary)["terraces"] as Dictionary, zn)


## Les terrasses de la ville en contrebas du belvédère (champ `terraces` de `belvedere` : `rings` (3), `step` (hauteur
## perdue par étage, 3), `gap` (profondeur d'un étage, 9), `scale` (taille des maisons, 1,7)) : de vrais murs de
## soutènement, des toits d'ardoise bleue, des murs crème, des jardins, des fenêtres allumées et des fumées de
## cheminée, qui descendent vers la plaine. Décor sans collision.
static func _terraces(b, tr: Dictionary, zn: float) -> void:
	var rings := int(tr.get("rings", 3))
	var step := float(tr.get("step", 3.0))
	var gap := float(tr.get("gap", 9.0))
	var sc := float(tr.get("scale", 1.7))
	var x0 := -36.0
	var x1 := float(b.w) + 36.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(b.map.get("id", "")) + "terrasses")
	var parent := Node3D.new()
	parent.name = "GoudaTerrasses"
	b.world.add_child(parent)
	var walls := MeshKit.begin()
	var tops := MeshKit.begin()
	var roofs := MeshKit.begin()
	var glass := MeshKit.begin()
	var green := MeshKit.begin()
	var chim: Array[Vector3] = []
	for k in rings:
		var ht := -2.0 - step * float(k)
		var zf := zn - 2.5 - float(k) * gap
		# mur de soutènement et sol de l'étage
		MeshKit.box(walls, Vector3((x0 + x1) * 0.5, ht - step * 0.5 - 0.5, zf), Vector3(x1 - x0, step + 1.0, 1.4))
		MeshKit.box(tops, Vector3((x0 + x1) * 0.5, ht - 0.15, zf - gap * 0.5), Vector3(x1 - x0, 0.3, gap))
		var cx := x0
		while cx < x1:   # créneaux
			MeshKit.box(tops, Vector3(cx, ht + 0.3, zf + 0.5), Vector3(0.9, 0.6, 0.5))
			cx += 2.2
		var hx := x0 + rng.randf_range(0.0, 3.0)
		while hx < x1 - 6.0:
			var hw := rng.randf_range(3.2, 5.8) * sc
			var hd := rng.randf_range(2.6, 3.4) * sc
			var hh := rng.randf_range(2.2, 3.4) * sc
			var r := rng.randf()
			var base := Vector3(hx + hw * 0.5, ht, zf - gap * 0.5 - hd * 0.1)
			if r < 0.78:
				_deco_house(walls, roofs, glass, base, Vector3(hw, hh, hd), rng)
				if rng.randf() < 0.45:
					var cxp := base.x + rng.randf_range(-hw * 0.3, hw * 0.3)
					MeshKit.box(walls, Vector3(cxp, ht + hh + hd * 0.3 + 0.8, base.z - hd * 0.15), Vector3(0.7, 1.6, 0.7))
					chim.append(Vector3(cxp, ht + hh + hd * 0.3 + 1.7, base.z - hd * 0.15))
			else:
				# un jardin : un massif bas et deux arbres taillés
				MeshKit.box(green, Vector3(base.x, ht + 0.25, base.z), Vector3(hw, 0.5, hd))
				for tj in 2:
					MeshKit.box(green, Vector3(base.x - hw * 0.25 + float(tj) * hw * 0.5, ht + 1.8, base.z), Vector3(1.9, 2.8, 1.9))
			hx += hw + rng.randf_range(0.8, 2.4) * sc
	var stone := MeshKit.pixel_material(Sprites.tile_texture("gou_rempart"))
	var slate := MeshKit.pixel_material(Sprites.tile_texture("gou_ardoise"))
	slate.cull_mode = BaseMaterial3D.CULL_DISABLED
	var lit := MeshKit.flat_material(Color("#f6d68a"), 1.4)
	var leaf := MeshKit.flat_material(Color("#5c8a52"))
	for pair: Array in [[walls, stone], [tops, stone], [roofs, slate], [glass, lit], [green, leaf]]:
		var node := MeshKit.finish(pair[0], pair[1], false)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(node)
	for i in chim.size():
		smoke(parent, chim[i], 4, 1.3, 6.0, 2.5, 0.14, Color(0.88, 0.88, 0.92, 0.5), 100 + i)


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
	var halo_mat := ShaderMaterial.new()
	halo_mat.shader = HALO_SHADER
	var halo_q := QuadMesh.new()
	halo_q.size = Vector2(7.0, 7.0)
	var fi := 0
	for fp: Vector3 in fires:
		fi += 1
		# colonne de fumée sombre qui monte et dérive avec le vent
		smoke(parent, fp + Vector3(0.0, 1.2, 0.0), 10, 1.8, 17.0, 6.0, 0.05, Color(0.22, 0.20, 0.20, 0.62), fi * 31)
		# braises : petites bouffées orange qui montent vite
		smoke(parent, fp + Vector3(0.0, 0.9, 0.0), 6, 0.22, 3.2, 0.8, 0.45, Color(1.0, 0.55, 0.16, 0.95), fi * 57)
		var hl := MeshInstance3D.new()
		hl.mesh = halo_q
		hl.material_override = halo_mat
		hl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		hl.position = fp + Vector3(0.0, 0.9, 0.3)
		hl.set_instance_shader_parameter("phase", float(fi) * 0.37)
		parent.add_child(hl)
	# étendards ennemis : fanions rouge sombre qui flottent au vent, plantés dans le camp
	var ban_tex := ImageTexture.create_from_image(_enemy_banner_image())
	for i in 7:
		var bp := Vector3(rng.randf_range(-12.0, float(b.w) + 12.0), 0.06, rng.randf_range(-depth + 6.0, -5.0))
		var pole := MeshKit.begin()
		MeshKit.box(pole, Vector3(0.0, 2.6, 0.0), Vector3(0.12, 5.2, 0.12))
		var pn := MeshKit.finish(pole, MeshKit.flat_material(Color(0.25, 0.17, 0.12)), false)
		pn.position = bp
		parent.add_child(pn)
		var fl := MeshKit.begin()
		for sgi in 8:
			var u0 := float(sgi) / 8.0
			var u1 := float(sgi + 1) / 8.0
			MeshKit.quad(fl, Vector3(1.8 * u0, 0.8, 0), Vector3(1.8 * u1, 0.8, 0), Vector3(1.8 * u1, -0.8, 0), Vector3(1.8 * u0, -0.8, 0), Vector2(u0, 0), Vector2(u1, 1))
		var fm := ShaderMaterial.new()
		fm.shader = FLAG_SHADER
		fm.set_shader_parameter("tex", ban_tex)
		fm.set_shader_parameter("amp", 0.25)
		var fnode := MeshKit.finish(fl, fm, false)
		fnode.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fnode.position = bp + Vector3(0.1, 4.4, 0.0)
		parent.add_child(fnode)


## Fanion ennemi : rouge sombre, bordure noire, crâne cornu stylisé.
static func _enemy_banner_image() -> Image:
	var im := Image.create(64, 40, false, Image.FORMAT_RGBA8)
	im.fill(Color(0.52, 0.09, 0.08))
	for x in 64:
		for y in 40:
			if x < 2 or x > 61 or y < 2 or y > 37:
				im.set_pixel(x, y, Color(0.12, 0.05, 0.05))
	im.fill_rect(Rect2i(24, 12, 16, 14), Color(0.92, 0.88, 0.8))
	im.fill_rect(Rect2i(28, 26, 8, 5), Color(0.92, 0.88, 0.8))
	im.fill_rect(Rect2i(27, 17, 3, 4), Color(0.12, 0.05, 0.05))
	im.fill_rect(Rect2i(34, 17, 3, 4), Color(0.12, 0.05, 0.05))
	im.fill_rect(Rect2i(20, 8, 4, 8), Color(0.92, 0.88, 0.8))
	im.fill_rect(Rect2i(40, 8, 4, 8), Color(0.92, 0.88, 0.8))
	return im


# ================================================================ fumées

## Colonne de fumée animée : `n` bouffées étalées sur toute la montée. `size` : diamètre au départ, `rise` : hauteur
## atteinte, `drift` : dérive du vent, `speed` : vitesse (1 / durée en secondes), `col` : couleur et opacité.
static func smoke(parent: Node3D, at: Vector3, n: int, size: float, rise: float, drift: float, speed: float, col: Color, seed_v: int) -> void:
	var mat := ShaderMaterial.new()
	mat.shader = SMOKE_SHADER
	mat.set_shader_parameter("col", col)
	mat.set_shader_parameter("speed", speed)
	mat.set_shader_parameter("rise", rise)
	mat.set_shader_parameter("drift", drift)
	var q := QuadMesh.new()
	q.size = Vector2(size, size)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for k in n:
		var mi := MeshInstance3D.new()
		mi.mesh = q
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		mi.position = at
		mi.set_instance_shader_parameter("phase", float(k) / float(n) + rng.randf_range(0.0, 0.05))
		parent.add_child(mi)


# ================================================================ la Tour Blanche

## La Tour Blanche en trois dimensions (champ `white_tower`, voir gouda_tower.gd).
static func _white_tower(b) -> void:
	var wt: Variant = b.map.get("white_tower")
	if not (wt is Dictionary):
		return
	Tower.build(b.world, Sprites.tile_texture("gou_rempart"), Sprites.tile_texture("gou_ardoise"), Sprites.tile_texture("gou_roche"), wt as Dictionary)


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
		"gou_deco": _deco(b, o)
		"gou_pavage": _paving(b, o)
		_: return false
	return true


## Décor de rue posé par les données : `kind` (un décor `gou_...` de gouda_painter.gd : charrette, pots, fromages,
## caisses, banc, lunette, panneau, lampadaire, tonneaux, linge, buisson), `pos`, `variant`, `scale`, `solid`
## (rayon qui bloque, 0 par défaut), `glow` (lueur), `shadow`, et au besoin `dialogue` et `label`.
static func _deco(b, o: Dictionary) -> void:
	var o2: Dictionary = o.duplicate()
	if not o2.has("solid"):
		o2["solid"] = 0.0
	b._prop(str(o.get("kind", "gou_pots")), o2, b._p(o))


## Pavage varié (objet `gou_pavage`, à placer en dernier dans la liste des objets) : un calque de décalques posé sur les
## dalles dures, sans toucher au sol ni aux collisions. Champs : `gutter` (liste de `{x, z0, z1}` : caniveau central
## d'une rue, en cases), `wear` (dalles usées ou claires, par case, 0,35), `moss` (mousse et ombre de contact au pied des
## bâtiments, vrai), `seed`. Les cases d'escalier sont laissées nues.
static func _paving(b, o: Dictionary) -> void:
	const PX := 24
	var seed_v := int(o.get("seed", 1))
	var ap: Variant = b.map.get("apron")
	var rows: int = b.h + (int((ap as Dictionary).get("depth", 10)) if ap is Dictionary else 0)
	var ap_x0: int = int((ap as Dictionary).get("x0", 0)) if ap is Dictionary else 0
	var ap_x1: int = int((ap as Dictionary).get("x1", b.w)) if ap is Dictionary else 0
	var ap_from: int = int((ap as Dictionary).get("from", b.h)) if ap is Dictionary else b.h
	var img := Image.create(b.w * PX, rows * PX, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var wear := float(o.get("wear", 0.35))
	var relief: bool = b.world.has_relief
	var ok := PackedByteArray()
	ok.resize(b.w * rows)
	for ty in rows:
		for tx in b.w:
			var i: int = ty * b.w + tx
			if ty >= ap_from:
				if tx < ap_x0 or tx >= ap_x1:
					continue
			elif ty >= b.h or not b._flag(b.cells[i], "hard") or b._flag(b.cells[i], "hole"):
				continue
			elif relief and b.world.stair_idx[i] >= 0:
				continue
			ok[i] = 1
			var r := PA.rnd(tx, ty, seed_v * 13 + 5)
			if r < wear:
				var tone := Color(0.42, 0.36, 0.26, 0.10 + 0.12 * PA.rnd(tx, ty, seed_v + 71)) if PA.rnd(tx, ty, seed_v + 3) < 0.6 else Color(1, 1, 0.95, 0.16)
				var gx := (int(PA.rnd(tx, ty, seed_v + 9) * 2.0)) * 12
				var gy := (int(PA.rnd(tx, ty, seed_v + 17) * 2.0)) * 12
				img.fill_rect(Rect2i(tx * PX + gx + 1, ty * PX + gy + 1, 11, 11), tone)
			if PA.rnd(tx, ty, seed_v + 29) < 0.22:   # fissure
				var cx: int = tx * PX + int(PA.rnd(tx, ty, seed_v + 31) * 16.0) + 3
				var cy: int = ty * PX + int(PA.rnd(tx, ty, seed_v + 37) * 16.0) + 3
				for k in 7:
					img.set_pixel(cx + k, cy + (k * 5 / 7) % 3, Color(0.3, 0.26, 0.2, 0.55))
			if PA.rnd(tx, ty, seed_v + 43) < 0.28:   # cailloux
				var px_: int = tx * PX + int(PA.rnd(tx, ty, seed_v + 47) * 20.0) + 1
				var py: int = ty * PX + int(PA.rnd(tx, ty, seed_v + 53) * 20.0) + 1
				img.fill_rect(Rect2i(px_, py, 2, 1), Color(0.62, 0.58, 0.5, 0.8))
				img.set_pixel(px_, py + 1, Color(0.4, 0.36, 0.3, 0.7))
	# caniveau : une rigole creusée au milieu de la rue, bord de pierre sombre, filet d'eau clair
	for gd: Variant in o.get("gutter", []):
		var g: Dictionary = gd
		var gx0 := int(float(g.get("x", 0.0)) * PX) - 5
		for ty in range(int(g.get("z0", 0)), mini(int(g.get("z1", b.h)), rows)):
			for tx in range(int(float(g.get("x", 0.0))) - 1, int(float(g.get("x", 0.0))) + 1):
				if tx < 0 or tx >= b.w or ty < 0 or ty >= rows or ok[ty * b.w + tx] == 0:
					continue
				var rx := maxi(tx * PX, gx0)
				var rx2 := mini((tx + 1) * PX, gx0 + 10)
				if rx2 <= rx:
					continue
				img.fill_rect(Rect2i(rx, ty * PX, rx2 - rx, PX), Color(0.5, 0.45, 0.37, 0.8))
				var ix := maxi(tx * PX, gx0 + 2)
				var ix2 := mini((tx + 1) * PX, gx0 + 8)
				if ix2 > ix:
					img.fill_rect(Rect2i(ix, ty * PX, ix2 - ix, PX), Color(0.56, 0.63, 0.66, 0.85))
					var hx := maxi(tx * PX, gx0 + 3)
					if hx < ix2:
						img.fill_rect(Rect2i(hx, ty * PX + int(PA.rnd(tx, ty, seed_v + 61) * 18.0), 1, 4), Color(0.85, 0.94, 1.0, 0.9))
	# mousse et ombre de contact au pied des bâtiments (les rectangles pleins déjà posés)
	if bool(o.get("moss", true)):
		for rc: Variant in b.world.rects:
			var rr: Rect2 = rc
			var x0 := int(floor(rr.position.x)) - 1
			var x1 := int(ceil(rr.end.x)) + 1
			var z0 := int(floor(rr.position.y)) - 1
			var z1 := int(ceil(rr.end.y)) + 1
			for ty in range(maxi(z0, 0), mini(z1 + 1, rows)):
				for tx in range(maxi(x0, 0), mini(x1 + 1, b.w)):
					if ok[ty * b.w + tx] == 0:
						continue
					var cell := Rect2(float(tx), float(ty), 1.0, 1.0)
					var near := rr.grow(0.45)
					if not cell.intersects(near) or cell.intersects(rr.grow(-0.02)):
						continue
					# ombre de contact : la bande sombre sur le côté nord du bâtiment est cachée, on la veut au sud et aux flancs
					for yy in PX:
						for xx in PX:
							var wx := float(tx) + (float(xx) + 0.5) / float(PX)
							var wz := float(ty) + (float(yy) + 0.5) / float(PX)
							var dx := maxf(maxf(rr.position.x - wx, 0.0), wx - rr.end.x)
							var dz := maxf(maxf(rr.position.y - wz, 0.0), wz - rr.end.y)
							var d := sqrt(dx * dx + dz * dz)
							if d < 0.4:
								var a := (0.4 - d) / 0.4
								var cur := img.get_pixel(tx * PX + xx, ty * PX + yy)
								if PA.rnd(tx * PX + xx, ty * PX + yy, seed_v + 83) < 0.32 * a + 0.04 and d > 0.05 and d < 0.3:
									img.set_pixel(tx * PX + xx, ty * PX + yy, Color(0.36, 0.52, 0.28, 0.75) if PA.rnd(xx, yy, seed_v + 89) < 0.7 else Color(0.5, 0.64, 0.36, 0.75))
								elif cur.a < 0.3:
									img.set_pixel(tx * PX + xx, ty * PX + yy, Color(0.3, 0.26, 0.2, 0.3 * a))
	var tex := ImageTexture.create_from_image(img)
	var st := MeshKit.begin()
	var any := false
	for ty in rows:
		for tx in b.w:
			var i: int = ty * b.w + tx
			if ok[i] == 0:
				continue
			any = true
			var y: float = (b.world.cell_h[i] if relief and ty < b.h else 0.0) + (0.045 if ty >= ap_from else 0.03)
			var u0 := Vector2(float(tx) / float(b.w), float(ty) / float(rows))
			var u1 := Vector2(float(tx + 1) / float(b.w), float(ty + 1) / float(rows))
			MeshKit.quad(st, Vector3(tx, y, ty), Vector3(tx + 1, y, ty), Vector3(tx + 1, y, ty + 1), Vector3(tx, y, ty + 1), u0, u1)
	if not any:
		return
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 1.0
	m.metallic_specular = 0.0
	var node := MeshKit.finish(st, m, false)
	node.name = "GoudaPavage"
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.world.add_child(node)


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
	b.world.occluders.append({"rect": Rect2(x0, z0, hw, hd), "nodes": parts, "fade": 0.0, "local": true})


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
	b.world.occluders.append({"rect": Rect2(p.x - sz * 0.5, p.z - sz * 0.5, sz, sz), "nodes": parts, "fade": 0.0, "local": true})


## Rempart crénelé le long d'une ligne brisée de segments horizontaux ou verticaux. Champs :
## `points`, `height` (2,4), `thick` (0,9). Bloque le passage.
static func _wall(b, o: Dictionary) -> void:
	var pts: Array = o.get("points", [])
	var hgt := float(o.get("height", 2.4))
	var th := float(o.get("thick", 0.9))
	var mat := MeshKit.pixel_material(Sprites.tile_texture("gou_rempart"))
	for i in range(pts.size() - 1):
		var pa: Array = pts[i]
		var pc: Array = pts[i + 1]
		var a := Vector2(float(pa[0]), float(pa[1]))
		var c := Vector2(float(pc[0]), float(pc[1]))
		var lo := Vector2(minf(a.x, c.x), minf(a.y, c.y))
		var hi := Vector2(maxf(a.x, c.x), maxf(a.y, c.y))
		var base: float = b.world.ground_y((a.x + c.x) * 0.5, (a.y + c.y) * 0.5)
		var size := Vector3(maxf(hi.x - lo.x, th), hgt, maxf(hi.y - lo.y, th))
		var center := Vector3((lo.x + hi.x) * 0.5, base + hgt * 0.5, (lo.y + hi.y) * 0.5)
		b.world.rects.append(Rect2(center.x - size.x * 0.5, center.z - size.z * 0.5, size.x, size.z))
		# le rempart est taillé en tronçons de 2 mètres (une répétition de la texture) : seuls ceux qui
		# cachent le héros s'estompent, le reste du mur reste plein (voir World._fade_occluders)
		var horiz := (hi.x - lo.x) >= (hi.y - lo.y)
		var span := (hi.x - lo.x) if horiz else (hi.y - lo.y)
		var n_ch := maxi(1, ceili(span / 2.0))
		var sts: Array = []
		for k in n_ch:
			sts.append(MeshKit.begin())
		for k in n_ch:
			var c0 := float(k) * 2.0
			var c1 := minf(span, c0 + 2.0)
			var mid := lo.x + (c0 + c1) * 0.5 if horiz else lo.y + (c0 + c1) * 0.5
			var csz := Vector3(maxf(c1 - c0, th), hgt, size.z) if horiz else Vector3(size.x, hgt, maxf(c1 - c0, th))
			MeshKit.box(sts[k], Vector3(mid, base + hgt * 0.5, center.z) if horiz else Vector3(center.x, base + hgt * 0.5, mid), csz)
		var n := int(maxf(size.x, size.z) / 1.3)
		for k in range(n + 1):
			var t := float(k) / float(maxi(1, n))
			var q := Vector2(lerpf(lo.x, hi.x, t), lerpf(lo.y, hi.y, t))
			var ci := clampi(int(((q.x - lo.x) if horiz else (q.y - lo.y)) / 2.0), 0, n_ch - 1)
			MeshKit.box(sts[ci], Vector3(q.x, base + hgt + 0.25, q.y), Vector3(0.62, 0.5, 0.62))
		for k in n_ch:
			var c0 := float(k) * 2.0
			var c1 := minf(span, c0 + 2.0)
			var r := Rect2(lo.x + c0, center.z - size.z * 0.5, maxf(c1 - c0, th), size.z) if horiz else Rect2(center.x - size.x * 0.5, lo.y + c0, size.x, maxf(c1 - c0, th))
			var node := MeshKit.finish(sts[k], mat)
			node.name = "GoudaRempart"
			b.world.add_child(node)
			b.world.occluders.append({"rect": r, "nodes": [node], "fade": 0.0, "local": true})   # s'estompe quand il passe devant le héros


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
	var lintel: Array = []
	for s: float in [-1.0, 1.0]:
		var parts: Array = []   # un pilier = un estompage à lui (le héros passe entre les deux)
		var cx := p.x + s * (gap * 0.5 + tw * 0.5)
		parts.append(_box_in(parent, Vector3(cx, p.y + hgt * 0.5, p.z), Vector3(tw, hgt, 2.4), _stone_mat(tw, hgt)))
		parts.append(_box_in(parent, Vector3(cx, p.y + hgt + 0.15, p.z), Vector3(tw + 0.5, 0.3, 2.9), MeshKit.flat_material(Color("#d8d0bc"))))
		for k in 3:
			parts.append(_box_in(parent, Vector3(cx + (k - 1) * 1.0, p.y + hgt + 0.55, p.z + 1.2), Vector3(0.6, 0.6, 0.5), _stone_mat(0.6, 0.6)))
		b.world.rects.append(Rect2(cx - tw * 0.5, p.z - 1.2, tw, 2.4))
		b.world.occluders.append({"rect": Rect2(cx - tw * 0.5, p.z - 1.2, tw, 2.4), "nodes": parts, "fade": 0.0, "local": true})
	lintel.append(_box_in(parent, Vector3(p.x, p.y + hgt - 0.7, p.z), Vector3(gap + 0.2, 1.4, 2.4), _stone_mat(gap, 1.4)))
	lintel.append(_box_in(parent, Vector3(p.x, p.y + hgt + 0.15, p.z), Vector3(gap + 0.4, 0.3, 2.9), MeshKit.flat_material(Color("#d8d0bc"))))
	b.world.occluders.append({"rect": Rect2(p.x - gap * 0.5, p.z - 1.2, gap, 2.4), "nodes": lintel, "fade": 0.0, "local": true})
	var wood := MeshKit.flat_material(Color("#3a2a1c"))
	for k in 5:   # herse relevée sous le linteau
		lintel.append(_box_in(parent, Vector3(p.x - gap * 0.4 + k * gap * 0.2, p.y + hgt - 1.6, p.z + 0.4), Vector3(0.1, 0.8, 0.1), wood))
	var banner := MeshKit.flat_material(Color("#27365e"))
	lintel.append(_box_in(parent, Vector3(p.x, p.y + hgt - 2.6, p.z + 1.25), Vector3(1.0, 1.6, 0.05), banner))
	lintel.append(_box_in(parent, Vector3(p.x, p.y + hgt - 2.4, p.z + 1.29), Vector3(0.12, 0.5, 0.03), MeshKit.flat_material(Color("#f4f0e4"))))
	lintel.append(_box_in(parent, Vector3(p.x, p.y + hgt - 2.0, p.z + 1.29), Vector3(0.5, 0.4, 0.03), MeshKit.flat_material(Color("#f4f0e4"))))
	for s: float in [-1.0, 1.0]:
		var torch := Atmosphere.make_light(Color("#ffc870"), 1.6, 5.5, false, 0.2)
		torch.position = Vector3(p.x + s * (gap * 0.5 + 0.4), p.y + 2.2, p.z + 1.6)
		parent.add_child(torch)
