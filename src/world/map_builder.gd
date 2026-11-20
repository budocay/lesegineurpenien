extends RefCounted
## Construit une carte 3D complète à partir de sa description (data/maps/*.json).
## Le format des cartes est documenté dans docs/FORMAT_DONNEES.md.

const PA = preload("res://src/gfx/pixel_art.gd")
const MeshKit = preload("res://src/gfx/mesh_kit.gd")
const TilePainter = preload("res://src/gfx/tile_painter.gd")
const Atmosphere = preload("res://src/world/atmosphere.gd")
const Npc = preload("res://src/world/npc.gd")
const ElvenBuilder = preload("res://src/world/elven_builder.gd")
const DwarvenBuilder = preload("res://src/world/dwarven_builder.gd")
const HouseBuilder = preload("res://src/world/house_builder.gd")
const RiderBuilder = preload("res://src/world/rider_builder.gd")
const GoudaBuilder = preload("res://src/world/gouda_builder.gd")
const InteriorDress = preload("res://src/world/interior_dress.gd")
const WATER_SHADER = preload("res://src/gfx/shaders/water.gdshader")

const PPU := 24
const WARM := Color("#ffb45e")

## Types de sol. hole = pas de sol dessiné ; solid = infranchissable ; hard = bord net.
const GROUND := {
	"grass": {}, "path": {}, "cobble": {}, "soil": {}, "humus": {},
	"planks": {"hard": true}, "floor": {"hard": true},
	"water": {"hole": true, "solid": true},
	"void": {"hole": true, "solid": true, "hard": true},
	# style elfe (voir docs/FORMAT_DONNEES.md)
	"elf_flag": {}, "elf_flag_dim": {"hard": true}, "elf_path": {}, "elf_lawn": {},
	"elf_bridge": {"hard": true}, "elf_parquet": {"hard": true}, "elf_floor_dark": {"hard": true},
	# style nain (voir docs/FORMAT_DONNEES.md)
	"nain_dalle": {"hard": true}, "nain_veine": {"hard": true}, "nain_voie": {"hard": true}, "nain_voie_v": {"hard": true},
	"nain_pont": {"hard": true}, "nain_marbre": {"hard": true}, "nain_pate": {"hard": true}, "nain_roche_humide": {"hard": true, "puddles": true}, "nain_galets": {"hard": true},
	"nain_abime": {"hard": true, "solid": true}, "nain_neige": {}, "nain_sentier": {},
	# styles du chapitre 5 : cavalier, fongorn, isengarde, chutes (voir docs/FORMAT_DONNEES.md)
	"cav_herbe": {}, "cav_chemin": {}, "cav_planches": {"hard": true}, "cav_botte_sol": {},
	"ent_mousse": {}, "ent_sentier": {}, "ent_racines": {},
	"isen_dalle": {"hard": true}, "isen_fonte": {"hard": true}, "isen_farine": {},
	"isen_fosse": {"hard": true, "solid": true},
	"chu_roche": {"hard": true, "puddles": true}, "chu_gravier": {}, "chu_dalle": {"hard": true, "puddles": true},
	# styles du chapitre 6 : gouda, veille, port, champ (voir docs/FORMAT_DONNEES.md)
	"gou_pave": {"hard": true}, "gou_dalle": {"hard": true}, "gou_marbre": {"hard": true}, "gou_rempart": {"hard": true}, "gou_mur": {"hard": true},
	"gou_herbe": {}, "gou_boue": {"puddles": true}, "gou_veille": {"hard": true}, "gou_mur_veille": {"hard": true}, "gou_quai": {"hard": true}, "gou_ardoise": {"hard": true},
}

## Sols dont les grandes plaques sont teintées (voir `_mottle`) : [sombre, clair, force, clarté].
const MOTTLE := {
	"cav_herbe": ["#6f9a3c", "#d0aa50", 0.62, 0.14],
	"cav_chemin": ["#8a6c40", "#d8bc82", 0.5, 0.1],
	"nain_neige": ["#9db2d8", "#f4f2ee", 0.5, 0.08],
	"nain_sentier": ["#8a8590", "#d4cec8", 0.5, 0.1],
	"nain_roche_humide": ["#1c2c3e", "#58769a", 0.58, 0.16],
	# cinquième valeur : [largeur, hauteur] des dalles, pour que chacune ait sa propre teinte (voir `_mottle`)
	"nain_dalle": ["#262f52", "#5c5a80", 0.55, 0.1, [24, 16]],
	"nain_pont": ["#6a6580", "#aaa2bc", 0.5, 0.08, [16, 12]],
	"isen_dalle": ["#1e1c28", "#504b5c", 0.55, 0.1, [16, 12]],
	"floor": ["#6a4222", "#bc8a52", 0.5, 0.1],
	"chu_gravier": ["#56706e", "#a4b4a2", 0.5, 0.12],
	"ent_mousse": ["#2c5a2c", "#6a8a34", 0.5, 0.12],
	"isen_fosse": ["#0a0608", "#5a2214", 0.75, 0.2],
	"elf_flag": ["#9a9684", "#f4eeda", 0.6, 0.12, [24, 16]],
	"ent_racines": ["#1c3a1c", "#5a6a30", 0.6, 0.14],
	# chapitre 6 : mêmes plaques teintées pour que la boue, le quai ou la dalle ne soient plus d'une seule couleur
	"gou_boue": ["#3a2414", "#9a6a3a", 0.7, 0.14],
	"gou_herbe": ["#4a5a22", "#a8a040", 0.6, 0.12],
	"gou_quai": ["#2a2a34", "#6a6258", 0.55, 0.12, [24, 12]],
	"gou_veille": ["#1a3a32", "#4a7a62", 0.5, 0.1, [24, 12]],
	"gou_pave": ["#e2d8c2", "#fffaee", 0.4, 0.06, [24, 12]],
	"gou_dalle": ["#e8dfca", "#fffaf0", 0.4, 0.06, [24, 24]],
	"gou_marbre": ["#ece6d8", "#fffcf4", 0.35, 0.05, [48, 48]],
}

## Accessoires affichés comme des sprites debout.
const PROPS := {
	"tree": {"variants": 4, "solid": 0.42, "sway": 0.05, "flip": true, "jitter": 0.18},
	"bush": {"variants": 3, "solid": 0.42, "sway": 0.015, "flip": true},
	"flowers": {"variants": 4, "sway": 0.02},
	"grass": {"variants": 4, "sway": 0.04},
	"tallgrass": {"variants": 3, "sway": 0.05},
	"wheat": {"variants": 3, "sway": 0.02},
	"wilted": {"variants": 2},
	"barrel": {"solid": 0.36},
	"sign": {"solid": 0.25},
	"rock": {"variants": 2, "solid": 0.4},
	"boulder": {"variants": 2, "solid": 0.9},
	"stump": {"variants": 2, "solid": 0.3},
	"log": {"variants": 2},
	"mushrooms": {"variants": 2},
	"reeds": {"variants": 2, "sway": 0.03},
	"haystack": {"solid": 0.7},
	"fence": {"variants": 2},
	"pillar": {"solid": 0.5},
	"brazier": {"solid": 0.3, "glow": 0.45},
	"anvil": {"solid": 0.35},
	"forge": {"solid": 1.2, "glow": 0.3},
	"deadtree": {"solid": 0.35},
	"fern": {"variants": 3, "sway": 0.02},
	"bollard": {"solid": 0.3},
	"monument": {"solid": 1.1},
	"boat": {"variants": 2},
	"shelf": {},
	"window": {"glow": 0.9},
	# style elfe
	"elf_column": {"variants": 2, "solid": 0.3},
	"elf_arcade": {"variants": 4},
	"elf_tree": {"variants": 4, "solid": 0.42, "sway": 0.05, "flip": true, "jitter": 0.18},
	"elf_pine": {"variants": 2, "solid": 0.4, "sway": 0.03, "flip": true},
	"elf_hedge": {"variants": 4, "solid": 0.5},
	"elf_bench": {"solid": 0.5},
	"elf_statue": {"variants": 2, "solid": 0.4},
	"elf_fountain": {"solid": 1.0},
	"elf_desk": {"variants": 2, "solid": 0.6},
	"elf_forms": {"variants": 3},
	"elf_seat": {"variants": 2, "solid": 0.3},
	"elf_bookcase": {"variants": 3, "solid": 0.5},
	"elf_table": {"variants": 2, "solid": 0.6},
	"elf_flowers": {"variants": 3, "sway": 0.02},
	"elf_leaves": {"variants": 3},
	"elf_gate": {"variants": 2},
	"elf_banner": {"variants": 2},
	"elf_urn": {"variants": 2, "solid": 0.3},
	"elf_pergola": {},
	"elf_bridge_face": {},
	"elf_ivy": {"variants": 2, "sway": 0.02},
	"elf_stamp": {},
	# style nain
	"nain_sapin": {"variants": 2, "solid": 0.4, "sway": 0.02, "flip": true},
	"nain_cristal": {"variants": 3, "solid": 0.3, "glow": 1.1},
	"nain_wagonnet": {"variants": 2, "solid": 0.7},
	"nain_meule": {"variants": 2, "solid": 0.7},
	"nain_tombe": {"solid": 1.0},
	"nain_registre": {"solid": 0.5},
	"nain_porte": {"variants": 2},
	"nain_statue": {"solid": 0.5},
	"nain_squelette": {"variants": 2},
	"nain_panneau": {"solid": 0.3},
	"nain_stele": {"solid": 0.4},
	"nain_etabli": {"variants": 2, "solid": 0.7},
	"nain_gravats": {"variants": 3},
	"nain_neige_tas": {"variants": 2, "solid": 0.4},
	# styles du chapitre 5
	"cav_arbre": {"variants": 2, "solid": 0.4, "sway": 0.04, "flip": true, "jitter": 0.15},
	"cav_botte": {"solid": 0.6},
	"cav_etendard": {"variants": 2, "solid": 0.3, "sway": 0.015},
	"cav_brebis": {"variants": 2, "solid": 0.35},
	"cav_enclos": {},
	"cav_trone": {"solid": 0.6},
	"cav_lit": {"solid": 0.9},
	"cav_grange": {"solid": 1.6},
	"ent_arbre": {"variants": 3, "solid": 0.6, "sway": 0.015, "flip": true},
	"ent_panonceau": {"solid": 0.3},
	"ent_souche": {"solid": 0.35},
	"isen_four": {"variants": 2, "solid": 0.8, "glow": 0.5},
	"isen_marmite": {"solid": 0.5, "glow": 0.2},
	"isen_cage": {"solid": 0.45},
	"isen_sac": {"variants": 2, "solid": 0.4},
	"isen_cheminee": {"solid": 0.5, "glow": 0.3},
	"isen_pancarte": {"solid": 0.4},
	"isen_tour": {},
	"chu_pierre": {"variants": 2, "solid": 0.6},
	"chu_ecume": {},
	# habillage des villages et des écuries (src/gfx/decor_painter.gd) : presque sans obstacle
	"vil_puits": {"solid": 0.55}, "vil_banc": {"solid": 0.3}, "vil_brouette": {"solid": 0.25}, "vil_potager": {"variants": 3, "solid": 0.3},
	"vil_linge": {"variants": 2, "solid": 0.2}, "vil_boite": {"solid": 0.12}, "vil_butte": {"variants": 2},
	"gou_creneau": {"solid": 0.3}, "gou_banniere": {"variants": 2, "solid": 0.3, "sway": 0.015}, "gou_trebuchet": {"solid": 1.2},
	"gou_poirier": {"solid": 0.5, "sway": 0.01, "glow": 0.2}, "gou_lit_pierre": {"variants": 2, "solid": 0.6}, "gou_voile": {"variants": 2, "solid": 0.3, "sway": 0.02},
	"gou_baril": {"solid": 0.4}, "gou_boulets": {"solid": 0.4}, "gou_fontaine": {"solid": 1.0}, "gou_statue": {"solid": 0.5}, "gou_echelle": {"solid": 0.2},
	"gou_etal": {"variants": 2, "solid": 0.8}, "gou_pieux": {"solid": 0.5}, "gou_tente": {"variants": 2, "solid": 0.9}, "gou_brasier": {"solid": 0.3, "glow": 0.5}, "gou_ancre": {"solid": 0.3},
	"cav_ratelier": {"solid": 0.3}, "cav_abreuvoir": {"solid": 0.3}, "cav_cheval_bois": {"solid": 0.35}, "cav_brasero": {"solid": 0.25, "glow": 0.4},
}

var world: Node3D
var map: Dictionary = {}
var w := 0
var h := 0
var cells: Array[String] = []
var rng := RandomNumberGenerator.new()
var keep_clear: Array[Vector2] = []
var wall_height := 3.0
var _north_gaps: Array[Vector2] = []
var _tree_spots: Array[Vector2] = []

## Talus d'arrière-plan, au nord des cartes d'extérieur : (z du bord, hauteur).
const TERRACES: Array[Vector2] = [Vector2(-2.4, 1.4), Vector2(-8.5, 2.9)]


## Construction étalée (fluidité) : si `staged`, `build` rend la main au moteur (une image) dès qu'une étape a duré
## plus de 20 ms, pour que l'écran de chargement reste animé. Sans `staged` (tests), tout reste synchrone.
var staged := false
var _last_yield := 0


func _due() -> void:
	if staged and Time.get_ticks_usec() - _last_yield > 20000:
		await world.get_tree().process_frame
		_last_yield = Time.get_ticks_usec()


func build(p_world: Node3D, p_map: Dictionary) -> void:
	var t_start := Time.get_ticks_usec()
	await _build(p_world, p_map)   # construction étalée : sans cette attente, la carte est rendue à moitié construite
	if OS.get_environment("GLAN_FPS") != "":
		print("CONSTRUCTION ", p_map.get("id", "?"), " : ", (Time.get_ticks_usec() - t_start) / 1000, " ms")


func _build(p_world: Node3D, p_map: Dictionary) -> void:
	world = p_world
	map = p_map
	var size: Array = map.get("size", [20, 15])
	w = int(size[0])
	h = int(size[1])
	wall_height = float(map.get("wall_height", 3.0))
	rng.seed = hash(str(map.get("id", "carte")))
	# ombres de nuages sur le sol (champ `clouds`, 0 : aucune)
	RenderingServer.global_shader_parameter_set("cloud_shadow", float(map.get("clouds", 0.0)))
	_last_yield = Time.get_ticks_usec()
	_build_cells()
	world.grid_w = w
	world.grid_h = h
	world.blocked = PackedByteArray()
	world.blocked.resize(w * h)
	var has_water := false
	for i in w * h:
		world.blocked[i] = 1 if _flag(cells[i], "solid") else 0
		if cells[i] == "water":
			has_water = true
	_build_relief()
	await _due()
	_build_ground()
	await _due()
	if has_water:
		_build_water()
		await _due()
	if bool(map.get("interior", false)):
		_build_interior_walls()
		if not DwarvenBuilder.is_dwarven(self):
			_build_interior_apron()
			_build_interior_void()
		else:
			# plan noir sous le lac souterrain (-0,22) : plus de ciel étoilé visible au-delà de la roche
			_build_interior_void(-0.45)
	else:
		_build_outskirts()
	await _due()
	if ElvenBuilder.is_elven(self):
		ElvenBuilder.restyle(self)
	elif DwarvenBuilder.is_dwarven(self):
		DwarvenBuilder.restyle(self)
	elif RiderBuilder.is_rider(self):
		RiderBuilder.restyle(self)
	elif GoudaBuilder.is_gouda(self):
		GoudaBuilder.restyle(self)
	await _due()

	var spawns: Dictionary = map.get("spawns", {})
	for key: String in spawns:
		var sp: Dictionary = spawns[key]
		var p: Array = sp.get("pos", [0, 0])
		keep_clear.append(Vector2(float(p[0]) + 0.5, float(p[1]) + 0.5))

	var objects: Array = map.get("objects", [])
	for o: Dictionary in objects:
		if str(o.get("type", "")) != "scatter":
			_object(o)
			await _due()
	for o: Dictionary in objects:
		if str(o.get("type", "")) == "scatter":
			_scatter(o)
			await _due()
	_undergrowth()
	await _due()
	InteriorDress.dress(self)
	await _due()

	var amb := Database.get_ambiance(str(map.get("ambiance", "crepuscule")))
	world.followers = Atmosphere.build(world, amb, Rect2(0.0, 0.0, w, h))


# -------------------------------------------------------------------- relief

const DIRS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]   # N E S W
const LIP_H := 1.0 / 3.0   # hauteur du liseré d'herbe : 8 px de la texture « cliff_lip »
const SHADE_DEPTH := 0.55


## Hauteurs et rampes de la carte (champs `heights` et `stairs`) : remplit les tables du
## monde, pose les murs infranchissables entre deux niveaux et bâtit falaises, liserés
## d'herbe, ombres au pied et rampes. Une carte sans ces champs n'est pas touchée.
func _build_relief() -> void:
	var hs: Array = map.get("heights", [])
	var ss: Array = map.get("stairs", [])
	world.has_relief = false
	if (bool(map.get("interior", false)) and not DwarvenBuilder.is_dwarven(self) and not RiderBuilder.is_rider(self) and not GoudaBuilder.is_gouda(self)) or (hs.is_empty() and ss.is_empty()):
		return
	world.cell_h = PackedFloat32Array()
	world.cell_h.resize(w * h)
	world.stair_idx = PackedInt32Array()
	world.stair_idx.resize(w * h)
	world.stair_idx.fill(-1)
	world.edge_block = PackedByteArray()
	world.edge_block.resize(w * h)
	world.stairs = []
	for e: Dictionary in hs:
		var r := _rect2(e)
		for ty in range(int(r.position.y), int(r.end.y)):
			for tx in range(int(r.position.x), int(r.end.x)):
				if tx >= 0 and ty >= 0 and tx < w and ty < h and not _flag(cells[ty * w + tx], "hole"):
					world.cell_h[ty * w + tx] = float(e.get("h", 0.0))
	for e: Dictionary in ss:
		var dir := str(e.get("dir", "up"))
		if not dir in ["up", "down", "left", "right"]:
			push_warning("Escalier : direction inconnue : " + dir)
			continue
		var r := _rect2(e)
		var idx: int = world.stairs.size()
		world.stairs.append({"rect": r, "dir": dir, "from": float(e.get("from", 0.0)), "to": float(e.get("to", 1.0))})
		for ty in range(int(r.position.y), int(r.end.y)):
			for tx in range(int(r.position.x), int(r.end.x)):
				if tx >= 0 and ty >= 0 and tx < w and ty < h and not _flag(cells[ty * w + tx], "hole"):
					world.stair_idx[ty * w + tx] = idx
	world.has_relief = true

	var walls := MeshKit.begin()
	var lips := MeshKit.begin()
	var shades := MeshKit.begin()
	var any := false
	for ty in h:
		for tx in w:
			var i := ty * w + tx
			if _flag(cells[i], "hole"):
				continue
			for k in 4:
				var nx := tx + DIRS[k].x
				var ny := ty + DIRS[k].y
				var inside := nx >= 0 and ny >= 0 and nx < w and ny < h
				if inside and _flag(cells[ny * w + nx], "hole"):
					continue
				var pts := _edge_pts(tx, ty, k)
				var a0: float = world.cell_height_at(tx, ty, pts[0].x, pts[0].y)
				var a1: float = world.cell_height_at(tx, ty, pts[1].x, pts[1].y)
				var b0 := 0.0
				var b1 := 0.0
				if inside:
					b0 = world.cell_height_at(nx, ny, pts[0].x, pts[0].y)
					b1 = world.cell_height_at(nx, ny, pts[1].x, pts[1].y)
				if absf(a0 - b0) < 0.02 and absf(a1 - b1) < 0.02:
					continue
				world.edge_block[i] |= 1 << k
				if inside:
					world.edge_block[ny * w + nx] |= 1 << ((k + 2) % 4)
					if k == 0 or k == 3:
						continue   # le mur est bâti depuis l'autre case
				any = true
				var own_higher := a0 + a1 > b0 + b1
				var f := k if own_higher else (k + 2) % 4   # le mur regarde vers le côté bas
				var higher_flat := true
				if own_higher:
					higher_flat = world.stair_idx[i] < 0
				elif inside:
					higher_flat = world.stair_idx[ny * w + nx] < 0
				var t0 := maxf(a0, b0)
				var t1 := maxf(a1, b1)
				var l0 := minf(a0, b0)
				var l1 := minf(a1, b1)
				# gauche et droite vus depuis le côté bas
				var left_is_0 := f == 2 or f == 3
				var pl: Vector2 = pts[0] if left_is_0 else pts[1]
				var pr: Vector2 = pts[1] if left_is_0 else pts[0]
				var tl := t0 if left_is_0 else t1
				var tr := t1 if left_is_0 else t0
				var ll := l0 if left_is_0 else l1
				var lr := l1 if left_is_0 else l0
				var n := Vector3(DIRS[f].x, 0, DIRS[f].y)
				var along_l := pl.x if (f == 0 or f == 2) else pl.y
				var along_r := pr.x if (f == 0 or f == 2) else pr.y
				_quad_uv(walls, Vector3(pl.x, tl, pl.y), Vector3(pr.x, tr, pr.y), Vector3(pr.x, lr, pr.y), Vector3(pl.x, ll, pl.y),
						[Vector2(along_l * 0.5, (4.0 - tl) * 0.5), Vector2(along_r * 0.5, (4.0 - tr) * 0.5),
						Vector2(along_r * 0.5, (4.0 - lr) * 0.5), Vector2(along_l * 0.5, (4.0 - ll) * 0.5)], n)
				if higher_flat:
					var o := n * 0.025
					var bl := maxf(tl - LIP_H, ll)
					var br := maxf(tr - LIP_H, lr)
					_quad_uv(lips, Vector3(pl.x, tl, pl.y) + o, Vector3(pr.x, tr, pr.y) + o, Vector3(pr.x, br, pr.y) + o, Vector3(pl.x, bl, pl.y) + o,
							[Vector2(along_l * 0.5, 0.0), Vector2(along_r * 0.5, 0.0),
							Vector2(along_r * 0.5, (tr - br) / LIP_H), Vector2(along_l * 0.5, (tl - bl) / LIP_H)], n)
				# ombre portée au pied de la paroi, sur le côté bas
				var far := n * SHADE_DEPTH
				var yl := ll + 0.02
				var yr := lr + 0.02
				var cn := Color(0.04, 0.03, 0.06, 0.46)
				var cf := Color(0.04, 0.03, 0.06, 0.0)
				var vs: Array[Vector3] = [Vector3(pl.x, yl, pl.y), Vector3(pr.x, yr, pr.y), Vector3(pr.x, yr, pr.y) + far, Vector3(pl.x, yl, pl.y) + far]
				var cs: Array[Color] = [cn, cn, cf, cf]
				for q: int in [0, 1, 2, 0, 2, 3]:
					shades.set_normal(Vector3.UP)
					shades.set_color(cs[q])
					shades.add_vertex(vs[q])
	if any:
		var wall_node := MeshKit.finish(walls, MeshKit.pixel_material(Sprites.tile_texture("cliff")), true)
		wall_node.name = "ReliefWalls"
		world.add_child(wall_node)
		var lip_node := MeshKit.finish(lips, MeshKit.ground_material(Sprites.tile_texture("cliff_lip"), 0.05), false)
		lip_node.name = "ReliefLips"
		if bool(map.get("relief_lip", true)):   # `relief_lip` : faux, pas de liseré d'herbe au bord des estrades (salle de trône)
			world.add_child(lip_node)
		else:
			lip_node.free()
		var sm := StandardMaterial3D.new()
		sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		sm.vertex_color_use_as_albedo = true
		sm.cull_mode = BaseMaterial3D.CULL_DISABLED
		var shade_node := MeshKit.finish(shades, sm, false)
		shade_node.name = "ReliefShade"
		shade_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		world.add_child(shade_node)
	if not world.stairs.is_empty():
		var st := MeshKit.begin()
		for s: Dictionary in world.stairs:
			var r: Rect2 = s["rect"]
			var corners: Array[Vector2] = [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
			var vs: Array[Vector3] = []
			var uvs: Array[Vector2] = []
			var dir := str(s["dir"])
			var flip := -0.5 if (dir == "down" or dir == "right") else 0.5
			for c in corners:
				vs.append(Vector3(c.x, world.stair_height(s, c.x, c.y), c.y))
				if dir == "up" or dir == "down":
					uvs.append(Vector2(c.x * 0.5, c.y * flip))
				else:
					uvs.append(Vector2(c.y * 0.5, c.x * flip))
			_quad_uv(st, vs[0], vs[1], vs[2], vs[3], uvs, Vector3.ZERO)
		var stairs_node := MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture("steps")), true)
		stairs_node.name = "ReliefStairs"
		world.add_child(stairs_node)


## Les deux extrémités du bord k (0 nord, 1 est, 2 sud, 3 ouest) de la case (tx, ty).
func _edge_pts(tx: int, ty: int, k: int) -> Array[Vector2]:
	var x := float(tx)
	var z := float(ty)
	match k:
		0: return [Vector2(x, z), Vector2(x + 1.0, z)]
		1: return [Vector2(x + 1.0, z), Vector2(x + 1.0, z + 1.0)]
		2: return [Vector2(x, z + 1.0), Vector2(x + 1.0, z + 1.0)]
	return [Vector2(x, z), Vector2(x, z + 1.0)]


## Quadrilatère à UV explicites (a haut-gauche, b haut-droite, c bas-droite, d bas-gauche).
## Normale nulle : calculée depuis les sommets (surfaces inclinées).
func _quad_uv(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, uv: Array, n: Vector3) -> void:
	var nn := n
	if nn == Vector3.ZERO:
		nn = (d - a).cross(b - a).normalized()
	var v: Array[Vector3] = [a, b, c, d]
	for q: int in [0, 1, 2, 0, 2, 3]:
		st.set_normal(nn)
		st.set_uv(uv[q])
		st.add_vertex(v[q])


## Vrai si le sol est plat et de même niveau autour de p (rayon r) : sinon un décor poserait
## à cheval sur une falaise ou une rampe.
func _flat_around(p: Vector2, r: float) -> bool:
	if not world.has_relief:
		return true
	var hh: float = world.ground_y(p.x, p.y)
	for d: Vector2 in [Vector2.ZERO, Vector2(r, 0), Vector2(-r, 0), Vector2(0, r), Vector2(0, -r), Vector2(r, r), Vector2(-r, r), Vector2(r, -r), Vector2(-r, -r)]:
		var q := p + d
		var tx := clampi(int(floor(q.x)), 0, w - 1)
		var ty := clampi(int(floor(q.y)), 0, h - 1)
		if world.stair_idx[ty * w + tx] >= 0 or absf(world.cell_h[ty * w + tx] - hh) > 0.01:
			return false
	return true


# ----------------------------------------------------------------------- sol

func _build_cells() -> void:
	var ground: Dictionary = map.get("ground", {})
	var def := str(ground.get("default", "grass"))
	cells.resize(w * h)
	cells.fill(def)
	for f: Dictionary in ground.get("fills", []):
		var r: Array = f.get("rect", [0, 0, 0, 0])
		var t := str(f.get("type", def))
		if not GROUND.has(t):
			push_warning("Type de sol inconnu : " + t)
			continue
		for ty in range(int(r[1]), int(r[1]) + int(r[3])):
			for tx in range(int(r[0]), int(r[0]) + int(r[2])):
				if tx >= 0 and ty >= 0 and tx < w and ty < h:
					cells[ty * w + tx] = t


func _cell(tx: int, ty: int) -> String:
	return cells[clampi(ty, 0, h - 1) * w + clampi(tx, 0, w - 1)]


func _flag(type: String, flag: String) -> bool:
	var d: Dictionary = GROUND.get(type, {})
	return bool(d.get(flag, false))


func _cell_at_pixel(gx: float, gy: float) -> String:
	return _cell(int(floor(gx / PPU)), int(floor(gy / PPU)))


## Sols de terre et sols d'herbe : leur frontière est déchiquetée, bordée de terre battue qui déborde, de
## touffes et de cailloux (voir `_paint_ground`).
## Sols dont la tuile est retournée bloc par bloc (voir `_paint_ground`).
const VARY_TILES := ["ent_racines", "ent_mousse", "isen_fosse"]
const SOFT_PATH := ["path", "cav_chemin", "ent_sentier", "nain_sentier", "soil", "elf_path", "gou_boue"]
const SOFT_GRASS := ["grass", "cav_herbe", "ent_mousse", "elf_lawn", "gou_herbe", "chu_gravier", "humus"]


func _soft_class(t: String) -> int:
	if SOFT_PATH.has(t):
		return 1
	if SOFT_GRASS.has(t):
		return 2
	return 0


func _paint_ground() -> ImageTexture:
	var disk_key := "ground:%s:%dx%d:%s" % [str(map.get("id", "")), w, h, ("\n".join(cells) + JSON.stringify(map)).md5_text()]
	var from_disk := Sprites.disk_load(disk_key)   # cache disque (fluidité) : la peinture dure de 0,1 à 1 s
	if from_disk != null and from_disk.get_width() == w * PPU and from_disk.get_height() == h * PPU:   # sinon : fichier abîmé, on repeint
		return PA.texture(from_disk)
	var img := PA.new_image(w * PPU, h * PPU)
	var noise := FastNoiseLite.new()
	noise.seed = 7
	noise.frequency = 0.055
	noise.fractal_type = FastNoiseLite.FRACTAL_FBM   # deux octaves : grandes ondulations et petits accrocs du bord
	noise.fractal_octaves = 2
	noise.fractal_lacunarity = 4.0
	noise.fractal_gain = 0.45
	var edge_spots: Array[Vector3i] = []
	var soft := PackedByteArray()   # classe de chaque case : 0 autre, 1 terre, 2 herbe (voir `_soft_class`)
	var hard_c := PackedByteArray()   # 1 si le sol de la case est « dur » (bord net)
	var hole_c := PackedByteArray()   # 1 si la case n'a pas de sol dessiné
	var has_water := false
	soft.resize(w * h)
	hard_c.resize(w * h)
	hole_c.resize(w * h)
	for ci in w * h:
		soft[ci] = _soft_class(cells[ci])
		hard_c[ci] = 1 if _flag(cells[ci], "hard") else 0
		hole_c[ci] = 1 if _flag(cells[ci], "hole") else 0
		if cells[ci] == "water":
			has_water = true
	for ty in h:
		for tx in w:
			var t := cells[ty * w + tx]
			var uniform := true
			for dy: int in [-1, 0, 1]:
				for dx: int in [-1, 0, 1]:
					if _cell(tx + dx, ty + dy) != t:
						uniform = false
			if uniform:
				if hole_c[ty * w + tx] == 0:
					if VARY_TILES.has(t):
						# sol de forêt : chaque bloc de 2 x 2 cases est retourné au hasard, pour que le motif de la tuile
						# (racines, brindilles) ne se répète jamais en rangées régulières
						var blk := PA.rnd(tx >> 1, ty >> 1, 1207)
						var cell_img := Sprites.tile_image(t).get_region(Rect2i((tx % 2) * PPU, (ty % 2) * PPU, PPU, PPU))
						if blk < 0.5:
							cell_img.flip_x()
							cell_img.flip_y()
						elif blk < 0.75:
							cell_img.flip_y()
						img.blit_rect(cell_img, Rect2i(0, 0, PPU, PPU), Vector2i(tx * PPU, ty * PPU))
					else:
						img.blit_rect(Sprites.tile_image(t), Rect2i((tx % 2) * PPU, (ty % 2) * PPU, PPU, PPU), Vector2i(tx * PPU, ty * PPU))
				continue
			# tuile de bordure : frontière irrégulière entre les matières. Le bruit de déformation est calculé par blocs
			# de 2 x 2 pixels (quatre fois moins d'appels) ; une tuile de sol dur ne se déforme pas.
			var t_hard := hard_c[ty * w + tx] == 1
			# tuile au bord de l'eau : le bord se déforme plus fort, même sur un sol dur (qui ne fait alors que céder
			# du terrain à l'eau), pour que la berge ne soit jamais une ligne droite à angles vifs
			var water_edge := false
			if has_water:
				for dy2: int in [-1, 0, 1]:
					for dx2: int in [-1, 0, 1]:
						if _cell(tx + dx2, ty + dy2) == "water":
							water_edge = true
			var amp := 17.0 if water_edge else 9.0
			var warp := PackedFloat32Array()
			if not t_hard or water_edge:
				var hb := PPU / 2
				warp.resize(hb * hb * 2)
				for by in hb:
					for bx in hb:
						var gx2 := float(tx * PPU + bx * 2)
						var gy2 := float(ty * PPU + by * 2)
						warp[(by * hb + bx) * 2] = noise.get_noise_2d(gx2, gy2) * amp
						warp[(by * hb + bx) * 2 + 1] = noise.get_noise_2d(gx2 + 300.0, gy2 + 170.0) * amp
			var last_use := ""
			var last_img: Image = null
			for py in PPU:
				for px in PPU:
					var gx := tx * PPU + px
					var gy := ty * PPU + py
					var wx := float(gx)
					var wy := float(gy)
					var use := t
					var ui := ty * w + tx
					var cxm := tx
					var cym := ty
					if not t_hard:
						var wi := ((py >> 1) * (PPU / 2) + (px >> 1)) * 2
						wx += warp[wi]
						wy += warp[wi + 1]
						cxm = clampi(int(floorf(wx / PPU)), 0, w - 1)
						cym = clampi(int(floorf(wy / PPU)), 0, h - 1)
						ui = cym * w + cxm
						if hard_c[ui] == 1:
							ui = ty * w + tx   # le sol dur voisin ne mord pas sur celui-ci
							cxm = tx
							cym = ty
						use = cells[ui]
					elif water_edge:
						var wi2 := ((py >> 1) * (PPU / 2) + (px >> 1)) * 2
						if _cell_at_pixel(wx + warp[wi2], wy + warp[wi2 + 1]) == "water":
							continue
					if hole_c[ui] == 1:
						continue
					if use != last_use:
						last_use = use
						last_img = Sprites.tile_image(use)
					var c := last_img.get_pixel(gx % 48, gy % 48)
					if hard_c[ui] == 0:
						if has_water and (_cell_at_pixel(wx, wy + 3.0) == "water" or _cell_at_pixel(wx, wy - 3.0) == "water" \
								or _cell_at_pixel(wx + 3.0, wy) == "water" or _cell_at_pixel(wx - 3.0, wy) == "water"):
							c = PA.shade(c, -0.22)
						elif use == "grass" and (_cell_at_pixel(wx, wy + 2.0) != "grass" or _cell_at_pixel(wx + 2.0, wy) != "grass"):
							c = PA.shade(c, -0.14)
						# bord de chemin : liseré de terre battue côté chemin, herbe foulée côté herbe, touffes et cailloux
						var kc := soft[ui]
						if kc != 0:
							var other := 3 - kc
							var cx0 := clampi(int(floorf((wx - 3.5) / PPU)), 0, w - 1)
							var cx1 := clampi(int(floorf((wx + 3.5) / PPU)), 0, w - 1)
							var cy0 := clampi(int(floorf((wy - 3.5) / PPU)), 0, h - 1)
							var cy1 := clampi(int(floorf((wy + 3.5) / PPU)), 0, h - 1)
							if soft[cym * w + cx0] == other or soft[cym * w + cx1] == other or soft[cy0 * w + cxm] == other or soft[cy1 * w + cxm] == other:
								var dr := PA.rnd(gx, gy, 990)
								if kc == 1:
									c = PA.shade(c, -0.16 - 0.12 * dr)   # liseré sombre côté chemin, lisible de loin
								elif dr < 0.6:
									c = PA.shade(c, -0.2)               # herbe foulée côté herbe
								else:
									c = PA.shade(c, 0.08)
								if dr > 0.955:
									edge_spots.append(Vector3i(gx, gy, kc))
					img.set_pixel(gx, gy, c)
	_edge_details(img, edge_spots)
	_mottle(img)
	_slabs(img)
	_scatter_puddles(img)
	_wear(img)
	Sprites.disk_store(disk_key, img)
	return PA.texture(img)


## Touffes d'herbe qui avancent sur la terre et cailloux qui roulent au bord du chemin, posés aux points relevés
## par `_paint_ground` (x, y, 1 : côté chemin, 2 : côté herbe).
func _edge_details(img: Image, spots: Array[Vector3i]) -> void:
	var gw := img.get_width()
	var gh := img.get_height()
	for sp: Vector3i in spots:
		if sp.y < 8 or sp.y > gh - 3 or sp.x < 3 or sp.x > gw - 4:
			continue
		if _flag(_cell_at_pixel(float(sp.x), float(sp.y - 4)), "hard"):
			continue
		var base := img.get_pixel(sp.x, sp.y)
		if sp.z == 2:
			var dark := PA.shade(base, -0.28)
			var light := PA.shade(base, 0.22)
			for k in 3:
				var bx := sp.x - 2 + k * 2
				var blen := 3 + int(PA.rnd(sp.x, sp.y, 992 + k) * 3.0)
				for j in blen:
					PA.px(img, bx + (j * (k - 1)) / 3, sp.y - j, dark if j < blen - 1 else light)
		else:
			var stone := Color("#8c8473").lerp(base, 0.25)
			PA.rect(img, sp.x, sp.y, 3, 2, PA.shade(stone, -0.2))
			PA.rect(img, sp.x, sp.y, 2, 1, PA.shade(stone, 0.18))
			PA.px(img, sp.x + 1, sp.y + 1, stone)


## Dalles à teinte propre (table SLABS : largeur, hauteur de la dalle, force de la teinte, chance de fêlure) : chaque
## dalle est un peu plus claire ou plus sombre que sa voisine, certaines sont fêlées ou ébréchées. La tuile du sol,
## répétée toutes les deux cases, ne dessine plus de rayures ni de grille.
const SLABS := {
	"elf_flag": [24, 16, 0.12, 0.5], "elf_flag_dim": [24, 16, 0.1, 0.45], "elf_floor_dark": [24, 16, 0.1, 0.4],
	"chu_dalle": [24, 16, 0.14, 0.6],
}   # largeur et hauteur : toujours 24 x 16 (les tuiles de ces sols)


func _slabs(img: Image) -> void:
	var kinds := {}
	for t: String in cells:
		if SLABS.has(t):
			kinds[t] = true
	if kinds.is_empty():
		return
	var patches := {}
	for t: String in kinds:
		var sp: Array = SLABS[t]
		var arr: Array[Image] = []
		for lv in 7:
			var k := float(lv - 3) / 3.0
			var pi := PA.new_image(int(sp[0]), int(sp[1]))
			pi.fill(Color(0.0, 0.0, 0.06, absf(k) * float(sp[2]) * 1.6) if k < 0.0 else Color(1.0, 0.97, 0.85, absf(k) * float(sp[2]) * 1.1))
			arr.append(pi)
		patches[t] = arr
	var gw := w * PPU
	var gh := h * PPU
	# toutes les tuiles de dalles ont la même taille (24 x 16) : un seul parcours
	var sw := 24
	var sh := 16
	for r in gh / sh:
		var off := (sw / 2) if (r % (48 / sh)) % 2 == 1 else 0
		var y0 := r * sh
		for c in range(0, gw / sw):
			var x0 := c * sw + off
			if x0 + sw > gw:
				continue
			var t := _cell(x0 / PPU, y0 / PPU)
			if not kinds.has(t):
				continue
			if _cell((x0 + sw - 1) / PPU, y0 / PPU) != t or _cell(x0 / PPU, (y0 + sh - 1) / PPU) != t or _cell((x0 + sw - 1) / PPU, (y0 + sh - 1) / PPU) != t:
				continue
			var sp: Array = SLABS[t]
			var lv := int(PA.rnd(c, r, 977) * 7.0)
			img.blend_rect(patches[t][lv], Rect2i(0, 0, sw, sh), Vector2i(x0, y0))
			# fêlure : petit éclair sombre qui part d'un bord de la dalle
			if PA.rnd(c, r, 978) < float(sp[3]):
				var cx := x0 + 3 + int(PA.rnd(c, r, 979) * float(sw - 6))
				var cy := y0 + 1
				var dir := 1 if PA.rnd(c, r, 980) < 0.5 else -1
				var steps := 4 + int(PA.rnd(c, r, 981) * float(sh - 6))
				for k in steps:
					cx += dir if (k % 3 == 2) else 0
					cy += 1
					if cy >= y0 + sh - 1 or cx <= x0 + 1 or cx >= x0 + sw - 2:
						break
					img.set_pixel(cx, cy, PA.shade(img.get_pixel(cx, cy), -0.34))
			# coin ébréché
			if PA.rnd(c, r, 982) < 0.22:
				var left := PA.rnd(c, r, 983) < 0.5
				var ex := x0 + 1 if left else x0 + sw - 3
				for k in 3:
					for j in 3 - k:
						img.set_pixel(ex + (k if left else 2 - k), y0 + sh - 2 - j, PA.shade(img.get_pixel(ex, y0 + sh - 2), -0.45))


## Teintes de grandes plaques, par type de sol (table MOTTLE) : `[teinte sombre, teinte claire, force,
## variation de clarté]`. Un bruit lent (plaques de 38 pixels, puis de 12) mélange le sol vers l'une ou
## l'autre teinte : la tuile, répétée toutes les deux cases, ne dessine plus de grille, et une plaine
## n'est plus d'une seule couleur. Calculé sur une grille au quart de la définition (rapide).
## Les sols de MOTTLE_OPTIN ne reçoivent leurs plaques teintées que si la carte porte `"mottle": true` (le calcul
## coûte cher sur les grandes cartes : il est réservé aux salles où le sol est un décor à part entière).
const MOTTLE_OPTIN := ["elf_flag"]


func _mottle_on(t: String) -> bool:
	return not MOTTLE_OPTIN.has(t) or bool(map.get("mottle", false))


func _mottle(img: Image) -> void:
	var any := false
	for t: String in cells:
		if MOTTLE.has(t) and _mottle_on(t):
			any = true
			break
	if not any:
		return
	var hp := preload("res://src/gfx/house_painter.gd")
	var lw := w * PPU / 4 + 3
	var lh := h * PPU / 4 + 3
	var nl: PackedFloat32Array = hp.noise_map(lw, lh, 927, 9.5)
	var ns: PackedFloat32Array = hp.noise_map(lw, lh, 928, 3.0)
	var parsed := {}
	for ty in h:
		for tx in w:
			var t := cells[ty * w + tx]
			if not MOTTLE.has(t) or not _mottle_on(t):
				continue
			if not parsed.has(t):
				var m: Array = MOTTLE[t]
				parsed[t] = [Color(str(m[0])), Color(str(m[1])), float(m[2]), float(m[3]), m[4] if m.size() > 4 else null]
			var pm: Array = parsed[t]
			for py in PPU:
				for px in PPU:
					var gx := tx * PPU + px
					var gy := ty * PPU + py
					# échantillonnage bilinéaire de la grille au quart de définition (pas de carrés visibles)
					var fx := float(gx & 3) * 0.25
					var fy := float(gy & 3) * 0.25
					var i := (gy >> 2) * lw + (gx >> 2)
					var vl := lerpf(lerpf(nl[i], nl[i + 1], fx), lerpf(nl[i + lw], nl[i + lw + 1], fx), fy)
					var vs := lerpf(lerpf(ns[i], ns[i + 1], fx), lerpf(ns[i + lw], ns[i + lw + 1], fx), fy)
					var k := (vl - 0.5) * 2.0 + (vs - 0.5) * 0.7   # environ -1 à 1
					var c := img.get_pixel(gx, gy)
					if k < -0.12:
						c = c.lerp(pm[0], minf(1.0, (-k - 0.12) * 1.3) * float(pm[2]))
					elif k > 0.12:
						c = c.lerp(pm[1], minf(1.0, (k - 0.12) * 1.3) * float(pm[2]))
					img.set_pixel(gx, gy, PA.shade(c, (vs - 0.5) * float(pm[3])))


## Sols usés par la cuisine (table WEAR : force de la suie) : taches de suie en grandes plaques irrégulières,
## flaques d'huile noire qui reflètent les flammes, et rails de chariots (champ `rails` de la carte : liste de
## [x0, z0, x1, z1] en cases, horizontaux ou verticaux, posés seulement sur ces sols). Sans ces sols, ne fait rien.
const WEAR := {"isen_dalle": 0.55, "isen_fonte": 0.4}


func _wear(img: Image) -> void:
	var any := false
	for t: String in cells:
		if WEAR.has(t):
			any = true
			break
	if not any:
		return
	var hp := preload("res://src/gfx/house_painter.gd")
	var lw := w * PPU / 4 + 3
	var lh := h * PPU / 4 + 3
	var nl: PackedFloat32Array = hp.noise_map(lw, lh, 951, 8.0)
	var ns: PackedFloat32Array = hp.noise_map(lw, lh, 952, 2.6)
	for ty in h:
		for tx in w:
			var t := cells[ty * w + tx]
			if not WEAR.has(t):
				continue
			var strength: float = WEAR[t]
			for py in PPU:
				for px in PPU:
					var gx := tx * PPU + px
					var gy := ty * PPU + py
					var fx := float(gx & 3) * 0.25
					var fy := float(gy & 3) * 0.25
					var i := (gy >> 2) * lw + (gx >> 2)
					var vl := lerpf(lerpf(nl[i], nl[i + 1], fx), lerpf(nl[i + lw], nl[i + lw + 1], fx), fy)
					var vs := lerpf(lerpf(ns[i], ns[i + 1], fx), lerpf(ns[i + lw], ns[i + lw + 1], fx), fy)
					var k := (vl - 0.5) * 2.0 + (vs - 0.5) * 0.7
					var c := img.get_pixel(gx, gy)
					if k > 0.12:
						# suie : plus sombre, un peu tirée vers le brun-noir, bord irrégulier grâce au petit bruit
						c = PA.shade(c.lerp(Color("#120e0e"), minf(0.5, (k - 0.12) * 0.9) * strength), -minf(0.4, (k - 0.12) * 0.7) * strength)
					elif k < -0.45:
						c = PA.shade(c, (-k - 0.45) * 0.22)   # quelques plaques plus claires, frottées par les chariots
					img.set_pixel(gx, gy, c)
	# flaques d'huile : positions tirées au hasard (ni grille ni grappes serrées), beaucoup de petites et quelques
	# grandes, un espacement minimal entre deux flaques ; une grande zone de bruit crée amas et vides
	var oil: Array[Vector3] = []
	var tries := w * h * PPU * PPU / 420
	for i in tries:
		var cx := PA.rnd(i, 1, 963) * float(w * PPU)
		var cy := PA.rnd(i, 2, 963) * float(h * PPU)
		var zone := hp.vnoise(cx, cy, 961, 110.0)
		var p := clampf((zone - 0.36) * 1.3, 0.0, 0.5)
		if PA.rnd(i, 3, 962) >= p:
			continue
		var big := pow(PA.rnd(i, 4, 965), 2.4)
		var rx := 2.6 + 9.5 * big
		var ry := rx * (0.32 + 0.38 * PA.rnd(i, 5, 966))
		var ok := true
		for o: Vector3 in oil:
			if Vector2(cx - o.x, cy - o.y).length() < (rx + o.z) * 1.9 + 6.0:
				ok = false
				break
		if not ok:
			continue
		for q: Vector2 in [Vector2(-rx, 0), Vector2(rx, 0), Vector2(0, -ry), Vector2(0, ry)]:
			if not WEAR.has(_cell_at_pixel(cx + q.x, cy + q.y)):
				ok = false
		if not ok:
			continue
		oil.append(Vector3(cx, cy, rx))
		var ix := i
		var iy := 0
		# flaque d'huile noire, de forme irrégulière (deux lobes), liseré luisant très discret
		var lobe := 0.55 + 0.3 * PA.rnd(ix, iy, 967)
		var sgn := 1.0 if PA.rnd(ix, iy, 968) < 0.5 else -1.0
		PA.ellipse(img, cx, cy, rx, ry, Color("#0c0a0f"))
		PA.ellipse(img, cx + sgn * rx * 0.5, cy + ry * 0.25, rx * lobe, ry * lobe, Color("#0c0a0f"))
		PA.ellipse(img, cx - 0.4, cy - 0.3, rx * 0.8, ry * 0.7, Color("#14101a"))
		if rx > 5.0:
			PA.ellipse(img, cx - rx * 0.15, cy - ry * 0.45, rx * 0.55, maxf(0.9, ry * 0.12), Color("#3a3050"))
			PA.px(img, int(cx - rx * 0.35), int(cy - ry * 0.45), Color("#c06a38"))
			PA.px(img, int(cx + rx * 0.2), int(cy + ry * 0.2), Color("#2a3a64"))
	# rails de chariots
	for r: Variant in map.get("rails", []):
		if not (r is Array) or (r as Array).size() < 4:
			continue
		var ra: Array = r
		var x0 := int(float(ra[0]) * PPU)
		var y0 := int(float(ra[1]) * PPU)
		var x1 := int(float(ra[2]) * PPU)
		var y1 := int(float(ra[3]) * PPU)
		var horiz := absi(x1 - x0) >= absi(y1 - y0)
		var n := (absi(x1 - x0) if horiz else absi(y1 - y0))
		for a in n:
			var gx := (mini(x0, x1) + a) if horiz else x0
			var gy := y0 if horiz else (mini(y0, y1) + a)
			if not WEAR.has(_cell_at_pixel(float(gx), float(gy))):
				continue
			# traverses tous les 9 pixels, légèrement inégales ; deux rails de fer, ombre dessous
			if a % 9 < 3:
				var sl := 8 + int(PA.rnd(a / 9, gx / 97, 971) * 2.0)
				for o in range(-sl, sl + 1):
					var tx2 := gx if horiz else gx + o
					var ty2 := gy + o if horiz else gy
					var base := Color("#2a1c16") if (a % 9) != 0 else Color("#4a3426")
					img.set_pixel(clampi(tx2, 0, w * PPU - 1), clampi(ty2, 0, h * PPU - 1), base)
			# deux rails épais : trois pixels de large (dessus clair, flanc de fer, ombre dessous)
			for rail: int in [-5, 5]:
				for wd in 4:
					var off := rail - 1 + wd
					var rx2 := gx if horiz else gx + off
					var ry2 := gy + off if horiz else gy
					var col := Color("#c4c4d4") if wd == 1 else (Color("#8a8a9c") if wd == 2 else (Color("#6a6a7c") if wd == 0 else Color("#1e1e28")))
					img.set_pixel(clampi(rx2, 0, w * PPU - 1), clampi(ry2, 0, h * PPU - 1), col)


## Flaques semées sur les sols qui portent le flag `puddles` (roche mouillée des lacs souterrains). Positions,
## tailles et formes viennent d'un bruit lent et d'un tirage par case de 13 pixels, jamais d'une grille :
## des amas de flaques, de grands vides, quelques longues flaques plates. Chaque flaque tient entièrement sur
## des cases à flaques (quatre points de son contour sont vérifiés).
func _scatter_puddles(img: Image) -> void:
	var any := false
	for t: String in cells:
		if _flag(t, "puddles"):
			any = true
			break
	if not any:
		return
	var hp := preload("res://src/gfx/house_painter.gd")
	var cs := 13
	for gy in range(0, h * PPU, cs):
		for gx in range(0, w * PPU, cs):
			var ix := gx / cs
			var iy := gy / cs
			var zone := hp.vnoise(float(gx), float(gy), 931, 90.0)
			var zone2 := hp.vnoise(float(gx), float(gy), 932, 34.0)
			var p := clampf((zone - 0.38) * 1.7, 0.0, 0.7) * (0.35 + zone2)
			if PA.rnd(ix, iy, 933) >= p:
				continue
			var cx := float(gx) + PA.rnd(ix, iy, 934) * float(cs)
			var cy := float(gy) + PA.rnd(ix, iy, 935) * float(cs)
			var big := PA.rnd(ix, iy, 936)
			var rx := 3.0 + 11.0 * big * big * big + zone2 * 2.0
			var ry := rx * (0.32 + 0.3 * PA.rnd(ix, iy, 937))
			var ok := true
			for q: Vector2 in [Vector2(-rx, 0), Vector2(rx, 0), Vector2(0, -ry), Vector2(0, ry), Vector2(0, 0)]:
				if not _flag(_cell_at_pixel(cx + q.x - 1.0, cy + q.y - 1.0), "puddles") or not _flag(_cell_at_pixel(cx + q.x + 1.0, cy + q.y + 1.0), "puddles"):
					ok = false
			if not ok:
				continue
			PA.ellipse(img, cx, cy, rx, ry, Color("#1c2c46"))
			PA.ellipse(img, cx - 0.5, cy - 0.7, rx * 0.82, ry * 0.7, Color("#2a4a6e"))
			if rx > 5.5:
				PA.ellipse(img, cx - 0.5, cy - 1.0, rx * 0.74, ry * 0.42, Color("#3e6a92"))
				PA.ellipse(img, cx - rx * 0.3, cy - ry * 0.4, rx * 0.26, 0.9, Color("#a8d4f4"))


func _build_ground() -> void:
	var tex: Texture2D = Sprites.cached("ground:" + str(map.get("id", "")), _paint_ground)
	var mat := MeshKit.ground_material(tex, float(map.get("ground_variation", 0.07)))
	for ci in w * h:
		if cells[ci] == "water":
			# le sol se mouille, se parsème de galets et de mousse au bord de l'eau (voir ground.gdshader)
			mat.set_shader_parameter("shore_tex", _shore_texture())
			mat.set_shader_parameter("shore_rect", Vector4(0.0, 0.0, float(w), float(h)))
			break
	var st := MeshKit.begin()
	if world.has_relief:
		# sol en dalles : chacune à la hauteur de sa case (les rampes ont leur propre maillage)
		for ty in h:
			for tx in w:
				if world.stair_idx[ty * w + tx] >= 0:
					continue
				var y: float = world.cell_h[ty * w + tx]
				MeshKit.quad(st, Vector3(tx, y, ty), Vector3(tx + 1, y, ty), Vector3(tx + 1, y, ty + 1), Vector3(tx, y, ty + 1),
						Vector2(float(tx) / w, float(ty) / h), Vector2(float(tx + 1) / w, float(ty + 1) / h))
	else:
		MeshKit.quad(st, Vector3(0, 0, 0), Vector3(w, 0, 0), Vector3(w, 0, h), Vector3(0, 0, h))
	var node := MeshKit.finish(st, mat, false)
	node.name = "Ground"
	world.add_child(node)


func _ground_quad(st: SurfaceTool, x0: float, z0: float, x1: float, z1: float, y: float = 0.0) -> void:
	MeshKit.quad(st, Vector3(x0, y, z0), Vector3(x1, y, z0), Vector3(x1, y, z1), Vector3(x0, y, z1),
			Vector2(x0, z0) / MeshKit.TEX_UNITS, Vector2(x1, z1) / MeshKit.TEX_UNITS)


## Prolonge l'herbe et la forêt au-delà de la carte pour que la caméra ne voie jamais le vide.
func _build_outskirts() -> void:
	var far := 70.0
	var river := -1
	for ty in h:
		if _cell(0, ty) == "water" and _cell(w - 1, ty) == "water":
			river = ty
			break
	var z_end := float(river) if river >= 0 else float(h) + far
	var grass_mat := MeshKit.ground_material(Sprites.tile_texture("grass"))
	var st := MeshKit.begin()
	_ground_quad(st, -far, -far, w + far, 0.0)
	_ground_quad(st, -far, 0.0, 0.0, z_end)
	_ground_quad(st, w, 0.0, w + far, z_end)
	if river < 0:
		_ground_quad(st, 0.0, h, w, h + far)
	# Relief d'arrière-plan : deux talus rocheux au nord, ouverts là où un chemin ou l'eau sort.
	_north_gaps.clear()
	var tx := 0
	while tx < w:
		if _cell(tx, 0) != "grass":
			var from := tx
			while tx < w and _cell(tx, 0) != "grass":
				tx += 1
			_north_gaps.append(Vector2(float(from) - 1.6, float(tx) + 1.6))
		else:
			tx += 1
	var cliffs := MeshKit.begin()
	var x := -far
	var spans: Array[Vector2] = []
	for g: Vector2 in _north_gaps:
		if g.x > x:
			spans.append(Vector2(x, g.x))
		x = maxf(x, g.y)
	if x < w + far:
		spans.append(Vector2(x, w + far))
	for s: Vector2 in spans:
		for t: Vector2 in TERRACES:
			var depth := far + t.x
			MeshKit.box(cliffs, Vector3((s.x + s.y) * 0.5, t.y * 0.5, t.x - depth * 0.5), Vector3(s.y - s.x, t.y, depth))
			_ground_quad(st, s.x, -far, s.y, t.x, t.y + 0.03)
	if not spans.is_empty():
		var rock := MeshKit.finish(cliffs, MeshKit.ground_material(Sprites.tile_texture("cliff"), 0.12), true)
		rock.name = "Cliffs"
		world.add_child(rock)
	var node := MeshKit.finish(st, grass_mat, false)
	node.name = "Outskirts"
	world.add_child(node)
	var side_z := z_end - 1.5
	var rustic := not ElvenBuilder.is_elven(self) and not DwarvenBuilder.is_dwarven(self) and not RiderBuilder.is_rider(self) and not GoudaBuilder.is_gouda(self)   # les styles elfe et nain plantent les leurs
	for i in (120 if rustic else 0):
		var p := Vector3.ZERO
		if i < 76:
			p = Vector3(rng.randf_range(-18.0, w + 18.0), 0, rng.randf_range(-18.0, -0.8))
		elif i < 98:
			p = Vector3(rng.randf_range(-18.0, -0.9), 0, rng.randf_range(0.0, side_z))
		else:
			p = Vector3(rng.randf_range(w + 0.9, w + 18.0), 0, rng.randf_range(0.0, side_z))
		p.y = _terrace_height(p.x, p.z)
		_prop("tree", {"solid": 0.0}, p)
	# sous-bois des abords : buissons, fougères et touffes au pied de la forêt
	for i in (150 if rustic else 0):
		var p := Vector3(rng.randf_range(-12.0, w + 12.0), 0, rng.randf_range(-9.0, -0.4))
		if i >= 110:
			var left := i % 2 == 0
			p = Vector3(rng.randf_range(-9.0, -0.5) if left else rng.randf_range(w + 0.5, w + 9.0), 0, rng.randf_range(0.0, side_z))
		p.y = _terrace_height(p.x, p.z)
		var kinds: Array = ["grass", "fern", "grass", "bush", "fern", "flowers"]
		_prop(str(kinds[i % kinds.size()]), {"solid": 0.0, "shadow": false}, p)


## Hauteur du sol hors de la carte (talus du nord).
func _terrace_height(x: float, z: float) -> float:
	for g: Vector2 in _north_gaps:
		if x > g.x - 0.4 and x < g.y + 0.4:
			return 0.0
	var y := 0.0
	for t: Vector2 in TERRACES:
		if z < t.x - 0.3:
			y = t.y
		elif z < t.x + 0.5:
			return y   # trop près du bord : on reste en bas, devant la paroi
	return y


## Végétation basse au pied des arbres de la carte : une seconde couche, sans obstacle.
func _undergrowth() -> void:
	var kinds: Array = ["fern", "grass", "fern", "flowers", "grass"]
	for spot: Vector2 in _tree_spots:
		var n := 1 + (rng.randi() % 2)
		for k in n:
			var p := spot + Vector2(rng.randf_range(-0.7, 0.7), rng.randf_range(0.1, 0.45))
			if p.x < 0.2 or p.y < 0.2 or p.x > w - 0.2 or p.y > h - 0.2:
				continue
			var cell := _cell(int(p.x), int(p.y))
			if cell != "grass" and cell != "soil" and cell != "humus":
				continue
			if not _flat_around(p, 0.4):
				continue
			_prop(str(kinds[rng.randi() % kinds.size()]), {"shadow": false}, Vector3(p.x, world.ground_y(p.x, p.y), p.y))


## Carte des distances à la rive, quatre échantillons par case : R, côté eau, distance à la rive divisée par 8 ;
## G, côté terre, distance à l'eau divisée par 2. La rive est celle du sol dessiné (son trou irrégulier), pas la
## frontière des cases : le liseré d'écume suit donc exactement la berge. L'eau lit R pour s'éclaircir près du bord,
## y faire son écume et s'assombrir vers le large (water.gdshader) ; le sol lit G pour se mouiller, se parsemer de
## galets et de mousse au bord de l'eau (ground.gdshader).
var _shore_cache: ImageTexture


func _shore_texture() -> ImageTexture:
	if _shore_cache != null:
		return _shore_cache
	var res := 4
	var gw := w * res
	var gh := h * res
	var gimg: Image = null
	var gtex: Variant = Sprites.cached("ground:" + str(map.get("id", "")), _paint_ground)
	if gtex is Texture2D:
		gimg = (gtex as Texture2D).get_image()
	# cases d'eau ou voisines d'une case d'eau : seules elles peuvent porter l'eau
	var nearw := PackedByteArray()
	nearw.resize(w * h)
	for ty in h:
		for tx in w:
			if cells[ty * w + tx] == "water":
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var nx := tx + dx
						var ny := ty + dy
						if nx >= 0 and ny >= 0 and nx < w and ny < h:
							nearw[ny * w + nx] = 1
	# les distances se calculent seulement sur la boîte qui entoure l'eau (plus neuf cases de marge : au-delà, elles
	# valent le maximum) ; hors de la boîte, tout reste à 255
	var bx0 := w
	var by0 := h
	var bx1 := -1
	var by1 := -1
	for ty in h:
		for tx in w:
			if cells[ty * w + tx] == "water":
				bx0 = mini(bx0, tx)
				bx1 = maxi(bx1, tx)
				by0 = mini(by0, ty)
				by1 = maxi(by1, ty)
	bx0 = maxi(0, bx0 - 9)
	by0 = maxi(0, by0 - 9)
	bx1 = mini(w - 1, bx1 + 9)
	by1 = mini(h - 1, by1 + 9)
	var cw := (bx1 - bx0 + 1) * res
	var ch := (by1 - by0 + 1) * res
	var wet := PackedByteArray()   # 1 : eau
	wet.resize(cw * ch)
	for y in ch:
		var cy := by0 + y / res
		for x in cw:
			var ci := cy * w + bx0 + x / res
			var is_w := cells[ci] == "water"
			if gimg != null and nearw[ci] == 1:
				var gx := (bx0 * res + x) * PPU / res + PPU / (2 * res)
				var gy := (by0 * res + y) * PPU / res + PPU / (2 * res)
				is_w = gimg.get_pixel(gx, gy).a < 0.5
			wet[y * cw + x] = 1 if is_w else 0
	var to_land := _chamfer(wet, cw, ch, 0)      # côté eau : distance à la terre
	var to_water := _chamfer(wet, cw, ch, 1)     # côté terre : distance à l'eau
	var data := PackedByteArray()
	data.resize(gw * gh * 2)
	data.fill(255)
	for y in ch:
		for x in cw:
			var i := y * cw + x
			var o := ((by0 * res + y) * gw + bx0 * res + x) * 2
			data[o] = int(clampf(to_land[i] / float(res) / 8.0, 0.0, 1.0) * 255.0)
			data[o + 1] = int(clampf(to_water[i] / float(res) / 2.0, 0.0, 1.0) * 255.0)
	_shore_cache = ImageTexture.create_from_image(Image.create_from_data(gw, gh, false, Image.FORMAT_RG8, data))
	return _shore_cache


## Distance (en échantillons, chanfrein 1 / 1,414) de chaque échantillon à l'échantillon le plus proche dont la valeur
## de `mask` est `target` ; 0 sur ceux-là. Deux passes.
func _chamfer(mask: PackedByteArray, gw: int, gh: int, target: int) -> PackedFloat32Array:
	var big := 1000.0
	var dist := PackedFloat32Array()
	dist.resize(gw * gh)
	for i in gw * gh:
		dist[i] = 0.0 if mask[i] == target else big
	for y in gh:
		for x in gw:
			var i := y * gw + x
			var v := dist[i]
			if x > 0:
				v = minf(v, dist[i - 1] + 1.0)
			if y > 0:
				v = minf(v, dist[i - gw] + 1.0)
				if x > 0:
					v = minf(v, dist[i - gw - 1] + 1.414)
				if x < gw - 1:
					v = minf(v, dist[i - gw + 1] + 1.414)
			dist[i] = v
	for y in range(gh - 1, -1, -1):
		for x in range(gw - 1, -1, -1):
			var i := y * gw + x
			var v := dist[i]
			if x < gw - 1:
				v = minf(v, dist[i + 1] + 1.0)
			if y < gh - 1:
				v = minf(v, dist[i + gw] + 1.0)
				if x < gw - 1:
					v = minf(v, dist[i + gw + 1] + 1.414)
				if x > 0:
					v = minf(v, dist[i + gw - 1] + 1.414)
			dist[i] = v
	return dist


## Les sources de lumière posées près de l'eau (cristaux, torches, braseros) s'y reflètent : un trait vertical
## qui part de leur pied, du côté de l'eau (voir `refl` dans water.gdshader). Douze reflets au plus.
func _water_reflections(mat: ShaderMaterial) -> void:
	var pts := PackedVector4Array()
	var cols := PackedVector4Array()
	for o: Variant in map.get("objects", []):
		if pts.size() >= 12 or not (o is Dictionary):
			continue
		var od: Dictionary = o
		var tp := str(od.get("type", ""))
		var def: Dictionary = PROPS.get(tp, {})
		var tint := Color("#ffb45e")
		if tp == "nain_cristal":
			tint = Color("#8adcff")
		elif tp != "nain_torche" and float(def.get("glow", 0.0)) <= 0.0:
			continue
		if not od.has("pos"):
			continue
		var pos: Array = od["pos"]
		var x := float(pos[0])
		var z := float(pos[1])
		var dir := 0.0
		for k: float in [1.6, 2.6]:
			if _cell_at_pixel(x * PPU, (z + k) * PPU) == "water":
				dir = 1.0
				break
			if _cell_at_pixel(x * PPU, (z - k) * PPU) == "water":
				dir = -1.0
				break
		if dir == 0.0:
			continue
		var reach := 2.4 if tp == "nain_cristal" else 1.8
		pts.append(Vector4(x, z, reach, dir))
		cols.append(Vector4(tint.r, tint.g, tint.b, 1.0))
	if pts.is_empty():
		return
	while pts.size() < 12:
		pts.append(Vector4(0.0, 0.0, 0.0, 0.0))
		cols.append(Vector4(0.0, 0.0, 0.0, 0.0))
	mat.set_shader_parameter("refl", pts)
	mat.set_shader_parameter("refl_c", cols)


func _build_water() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = WATER_SHADER
	mat.set_shader_parameter("shore_tex", _shore_texture())
	mat.set_shader_parameter("shore_rect", Vector4(0.0, 0.0, float(w), float(h)))
	_water_reflections(mat)
	var st := MeshKit.begin()
	if bool(map.get("interior", false)):
		# dans une salle, l'eau s'arrête aux murs : au-delà, le plan noir (sinon elle se voit de l'autre côté des parois)
		MeshKit.quad(st, Vector3(0, 0, 0), Vector3(w, 0, 0), Vector3(w, 0, h), Vector3(0, 0, h))
	else:
		MeshKit.quad(st, Vector3(-80, 0, -10), Vector3(w + 80, 0, -10), Vector3(w + 80, 0, h + 80), Vector3(-80, 0, h + 80))
	var node := MeshKit.finish(st, mat, false)
	node.position.y = -0.22
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.name = "Water"
	world.add_child(node)


## Intérieurs : murs automatiques là où le plancher touche le vide (fond et côtés seulement,
## le mur côté caméra reste ouvert, comme dans une maison de poupée).
func _build_interior_walls() -> void:
	var st := MeshKit.begin()
	var cap := MeshKit.begin()
	var hgt := wall_height
	var v1 := hgt / 3.0
	var any := false
	for ty in h:
		for tx in w:
			if _flag(_cell(tx, ty), "hole"):
				continue
			var x0 := float(tx)
			var x1 := x0 + 1.0
			var z0 := float(ty)
			var z1 := z0 + 1.0
			if ty == 0 or _wall_gap((ty - 1) * w + tx):
				MeshKit.quad(st, Vector3(x0, hgt, z0), Vector3(x1, hgt, z0), Vector3(x1, 0, z0), Vector3(x0, 0, z0),
						Vector2(x0 / 2.0, 0.0), Vector2(x1 / 2.0, v1))
				MeshKit.quad(cap, Vector3(x0 - 0.4, hgt, z0 - 0.4), Vector3(x1 + 0.4, hgt, z0 - 0.4), Vector3(x1 + 0.4, hgt, z0), Vector3(x0 - 0.4, hgt, z0))
				any = true
			if (tx == 0 or _wall_gap(ty * w + tx - 1)) and not _juts_out(tx - 1, ty):
				MeshKit.quad(st, Vector3(x0, hgt, z1), Vector3(x0, hgt, z0), Vector3(x0, 0, z0), Vector3(x0, 0, z1),
						Vector2(z1 / 2.0, 0.0), Vector2(z0 / 2.0, v1))
				MeshKit.quad(cap, Vector3(x0 - 0.4, hgt, z0), Vector3(x0, hgt, z0), Vector3(x0, hgt, z1), Vector3(x0 - 0.4, hgt, z1))
				any = true
			if (tx == w - 1 or _wall_gap(ty * w + tx + 1)) and not _juts_out(tx + 1, ty):
				MeshKit.quad(st, Vector3(x1, hgt, z0), Vector3(x1, hgt, z1), Vector3(x1, 0, z1), Vector3(x1, 0, z0),
						Vector2(z0 / 2.0, 0.0), Vector2(z1 / 2.0, v1))
				MeshKit.quad(cap, Vector3(x1, hgt, z0), Vector3(x1 + 0.4, hgt, z0), Vector3(x1 + 0.4, hgt, z1), Vector3(x1, hgt, z1))
				any = true
	if not any:
		return
	var walls := MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture(str(map.get("wall_tile", "interior_wall")))))
	walls.name = "Walls"
	world.add_child(walls)
	var caps := MeshKit.finish(cap, MeshKit.flat_material(Color("#0d0a12")))
	caps.name = "WallCaps"
	world.add_child(caps)


## Prolonge le sol d'une pièce au sud de son bord (reflet du dernier tiers du plancher), assombri
## peu à peu : la caméra, qui s'arrête à des bornes fixes, ne voit plus jamais de bande noire sous
## la pièce. Purement décoratif : ni collision ni passage.
func _build_interior_apron() -> void:
	# bord sud de la pièce : dernière rangée dont la moitié au moins des cases est du plancher
	# (les renfoncements de porte dépassent et gardent leur propre sol)
	var edge := h
	for ty in range(h - 1, -1, -1):
		var floor_n := 0
		for tx in w:
			if not _flag(_cell(tx, ty), "hole"):
				floor_n += 1
		if floor_n * 2 >= w:
			edge = ty + 1
			break
	var depth := 8.0
	var z0 := float(edge)
	var z1 := float(h) + depth
	var v0 := z0 / float(h)
	var v1 := maxf(0.0, v0 - (z1 - z0) / float(h))
	var st := MeshKit.begin()
	MeshKit.quad(st, Vector3(-depth, -0.01, z0), Vector3(w + depth, -0.01, z0), Vector3(w + depth, -0.01, z1), Vector3(-depth, -0.01, z1),
			Vector2(0.0, v0), Vector2(1.0, v1))
	var tex: Texture2D = Sprites.cached("ground:" + str(map.get("id", "")), _paint_ground)
	var floor_node := MeshKit.finish(st, MeshKit.ground_material(tex), false)
	floor_node.name = "ApronFloor"
	world.add_child(floor_node)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.02, 0.015, 0.03, 0.0))
	grad.set_color(1, Color(0.02, 0.015, 0.03, 1.0))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.0, 0.0)
	gt.fill_to = Vector2(0.0, 1.0)
	gt.width = 4
	gt.height = 64
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = gt
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var fst := MeshKit.begin()
	MeshKit.quad(fst, Vector3(-depth, 0.03, z0), Vector3(w + depth, 0.03, z0), Vector3(w + depth, 0.03, z1), Vector3(-depth, 0.03, z1),
			Vector2(0.0, 0.0), Vector2(1.0, 1.0))
	var fade := MeshKit.finish(fst, mat, false)
	fade.name = "ApronFade"
	fade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(fade)


## Noir plein au-delà des murs : un grand plan noir sous le plancher, sans lumière ni brume, ferme tout ce que la
## caméra verrait par-dessus les murs ou à côté de la pièce (plus de demi-vide étoilé jusqu'au bord de l'écran).
func _build_interior_void(y: float = -0.07) -> void:
	var st := MeshKit.begin()
	MeshKit.quad(st, Vector3(-90, y, -90), Vector3(w + 90, y, -90), Vector3(w + 90, y, h + 90), Vector3(-90, y, h + 90))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color.BLACK
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.disable_fog = true
	var node := MeshKit.finish(st, mat, false)
	node.name = "InteriorVoid"
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(node)


## Vrai si la case d'indice i laisse un vide contre lequel bâtir un mur. Dans le style nain,
## l'eau d'un lac souterrain n'en est pas un : on la longe sans mur, le lac s'étend dans le noir.
func _wall_gap(i: int) -> bool:
	return _flag(cells[i], "hole") and not (cells[i] == "water" and DwarvenBuilder.is_dwarven(self))


## Vrai si un mur latéral posé contre la case vide (tx, ty) dépasserait de la pièce vers
## la caméra : c'est le cas des renfoncements de porte, dont le plancher avance au sud du
## mur du fond. On les laisse ouverts, sinon ils masquent l'entrée.
func _juts_out(tx: int, ty: int) -> bool:
	if tx < 0 or tx >= w or ty <= 0:
		return false
	return not _flag(cells[(ty - 1) * w + tx], "hole")


# -------------------------------------------------------------------- objets

func _p(o: Dictionary) -> Vector3:
	var p: Array = o.get("pos", [0, 0])
	var x := float(p[0]) + 0.5
	var z := float(p[1]) + 0.5
	return Vector3(x, world.ground_y(x, z), z)


func _object(o: Dictionary) -> void:
	var type := str(o.get("type", ""))
	if type != "trigger":
		# "unless" : l'objet disparaît quand le drapeau est posé ; "if" : il n'existe qu'ensuite.
		var unless := str(o.get("unless", ""))
		if unless != "":
			world.flag_deps[unless] = GameState.has_flag(unless)
			if GameState.has_flag(unless):
				return
		var only_if := str(o.get("if", ""))
		if only_if != "":
			world.flag_deps[only_if] = GameState.has_flag(only_if)
			if not GameState.has_flag(only_if):
				return
	match type:
		"monster": _monster(o)
		"encounter_zone": world.encounter_zones.append({"rect": _rect2(o), "table": str(o.get("table", ""))})
		"house":
			if ElvenBuilder.style_of(self, o) == "elfe":
				ElvenBuilder.house(self, o)
			else:
				HouseBuilder.house(self, o)
		"lantern": _lantern(o)
		"fence": _fence(o)
		"balustrade": _balustrade(o)
		"npc": _npc(o)
		"light": _light(o)
		"warp": _warp(o)
		"trigger": _trigger(o)
		"table": _table(o)
		"stool": _stool(o)
		"counter": _counter(o)
		"bed": _bed(o)
		"fireplace": _fireplace(o)
		"stove": _stove(o)
		"rug": _rug(o)
		"crate": _crate(o)
		"market_stall": _market_stall(o)
		_:
			if PROPS.has(type):
				_prop(type, o, _p(o))
			elif ElvenBuilder.object(self, type, o) or DwarvenBuilder.object(self, type, o) or RiderBuilder.object(self, type, o) or GoudaBuilder.object(self, type, o):
				pass
			else:
				push_warning("Type d'objet inconnu dans la carte %s : %s" % [str(map.get("id", "")), type])


func _interactable(pos: Vector3, o: Dictionary, default_label: String, node: Node3D = null, height: float = 1.3) -> void:
	var it := {
		"pos": pos,
		"dialogue": str(o.get("dialogue", "")),
		"label": str(o.get("label", default_label)),
		"reach": float(o.get("reach", 1.5)),
		"height": float(o.get("prompt_height", height)),
		"gated": bool(o.get("gated", false)),   # inaccessible tant qu'un obstacle scénarisé est là
	}
	if node != null:
		it["node"] = node
	world.interactables.append(it)
	keep_clear.append(Vector2(pos.x, pos.z))


func _prop(kind: String, o: Dictionary, pos: Vector3) -> Node3D:
	var def: Dictionary = PROPS.get(kind, {})
	var variants := int(def.get("variants", 1))
	var variant := int(o.get("variant", rng.randi() % variants))
	var tex := Sprites.prop(kind, variant)
	var node := Sprites.make_sprite(tex, float(def.get("sway", 0.0)), float(o.get("glow", def.get("glow", 0.0))))
	node.position = pos + Vector3(0, float(o.get("height", 0.0)), 0)
	var s := float(o.get("scale", 1.0))
	if def.has("jitter"):
		s *= 1.0 + rng.randf_range(-1.0, 1.0) * float(def["jitter"])
	var flip := bool(def.get("flip", false)) and rng.randf() < 0.5
	node.scale = Vector3(-s if flip else s, s, s)
	node.rotation.z = deg_to_rad(float(o.get("lean", 0.0)))
	world.add_child(node)
	var quad := node.get_child(0) as MeshInstance3D
	quad.set_instance_shader_parameter("sway_phase", rng.randf() * TAU)
	if not bool(o.get("shadow", true)):
		quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var solid := float(o.get("solid", def.get("solid", 0.0)))
	if solid > 0.0:
		world.circles.append(Vector3(pos.x, pos.z, solid))
	if o.has("dialogue"):
		_interactable(pos, o, "Examiner", null, tex.get_height() / float(PPU) * s * 0.75)
	if kind == "boat":
		var tw := node.create_tween().set_loops()
		tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		var y := node.position.y
		var period := rng.randf_range(1.6, 2.3)
		tw.tween_property(node, "position:y", y + 0.07, period)
		tw.tween_property(node, "position:y", y, period)
	return node


func _scatter(o: Dictionary) -> void:
	var kind := str(o.get("prop", "tree"))
	var r: Array = o.get("rect", [0, 0, w, h])
	var count := int(o.get("count", 10))
	var min_dist := float(o.get("min_dist", 1.0))
	var on: Array = o.get("on", ["grass"])
	var avoid: Array = o.get("avoid", [])
	rng.seed = int(o.get("seed", 1)) * 7919 + 13
	var def: Dictionary = PROPS.get(kind, {})
	var solid := float(def.get("solid", 0.0))
	var placed: Array[Vector2] = []
	var tries := 0
	while placed.size() < count and tries < count * 40:
		tries += 1
		var p := Vector2(rng.randf_range(float(r[0]), float(r[0]) + float(r[2])), rng.randf_range(float(r[1]), float(r[1]) + float(r[3])))
		if p.x < 0.3 or p.y < 0.3 or p.x > w - 0.3 or p.y > h - 0.3:
			continue
		var avoided := false
		for av: Variant in avoid:
			var ar: Array = av
			if Rect2(float(ar[0]), float(ar[1]), float(ar[2]), float(ar[3])).has_point(p):
				avoided = true
				break
		if avoided:
			continue   # zone dégagée demandée par la carte (champ « avoid »)
		if not on.has(_cell(int(p.x), int(p.y))):
			continue
		if not _flat_around(p, maxf(solid, 0.2) + 0.3):
			continue   # jamais à cheval sur une falaise ou une rampe
		var ok := true
		for q in placed:
			if q.distance_to(p) < min_dist:
				ok = false
				break
		if not ok:
			continue
		if solid > 0.0:
			for k in keep_clear:
				if k.distance_to(p) < solid + 1.1:
					ok = false
					break
			if ok and not world.is_free(p, solid + 0.45):
				ok = false
			# un obstacle ne doit jamais mordre sur un chemin d'une case de large
			if ok:
				var m := solid + 0.4
				for d: Vector2 in [Vector2(m, 0), Vector2(-m, 0), Vector2(0, m), Vector2(0, -m)]:
					var c := p + d
					if not on.has(_cell(clampi(int(c.x), 0, w - 1), clampi(int(c.y), 0, h - 1))):
						ok = false
			if ok:
				for wp: Dictionary in world.warps:
					var wr: Rect2 = wp["rect"]
					if wr.grow(1.2).has_point(p):
						ok = false
		else:
			for rect: Rect2 in world.rects:
				if rect.grow(0.15).has_point(p):
					ok = false
		if ok:
			placed.append(p)
			_prop(kind, {}, Vector3(p.x, world.ground_y(p.x, p.y), p.y))
			if kind == "tree":
				_tree_spots.append(p)


func _mesh_box(center: Vector3, size: Vector3, material: Material, shadow: bool = true) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	node.mesh = mesh
	node.material_override = material
	node.position = center
	if not shadow:
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(node)
	return node


func _add_light(pos: Vector3, color: Color, energy: float, light_range: float, shadow: bool, flicker: float = 0.0) -> OmniLight3D:
	var l := Atmosphere.make_light(color, energy, light_range, shadow, flicker)
	l.position = pos
	world.add_child(l)
	return l


func _house(o: Dictionary) -> void:
	var r: Array = o.get("rect", [0, 0, 5, 4])
	var x0 := float(r[0])
	var z0 := float(r[1])
	var hw := float(r[2])
	var hd := float(r[3])
	var x1 := x0 + hw
	var z1 := z0 + hd
	var wh := float(o.get("height", 2.5))
	var rh := float(o.get("roof_height", 1.7))
	var door_x := float(o.get("door", hw * 0.5))
	var windows: Array = o.get("windows", [])
	var door_color := Database.color(o.get("door_color", "#3f7a52"), Color("#3f7a52"))
	var lit := bool(o.get("lit", true))
	var roof := str(o.get("roof", "rouge"))
	var house := Node3D.new()
	house.name = "House"
	world.add_child(house)
	var first_child := world.get_child_count()

	var front: Dictionary = Sprites.cached("house:%s:%s" % [str(map.get("id", "")), str(r)], func() -> Dictionary:
		var f := TilePainter.house_front(hw, wh, door_x, windows, door_color, lit)
		return {"albedo": PA.texture(f["albedo"]), "emission": PA.texture(f["emission"])})
	var st := MeshKit.begin()
	MeshKit.quad(st, Vector3(x0, wh, z1), Vector3(x1, wh, z1), Vector3(x1, 0, z1), Vector3(x0, 0, z1))
	house.add_child(MeshKit.finish(st, MeshKit.pixel_material(front["albedo"], front["emission"], 2.6)))

	var side_tex: Texture2D = Sprites.cached("house_side:%.2f:%.2f" % [hd, wh], func() -> Texture2D:
		return PA.texture(TilePainter.house_side(hd, wh)))
	st = MeshKit.begin()
	MeshKit.quad(st, Vector3(x0, wh, z0), Vector3(x0, wh, z1), Vector3(x0, 0, z1), Vector3(x0, 0, z0))
	MeshKit.quad(st, Vector3(x1, wh, z1), Vector3(x1, wh, z0), Vector3(x1, 0, z0), Vector3(x1, 0, z1))
	house.add_child(MeshKit.finish(st, MeshKit.pixel_material(side_tex)))

	var zm := (z0 + z1) * 0.5
	var top := wh + rh
	st = MeshKit.begin()
	MeshKit.tri(st, Vector3(x0, wh, z0), Vector3(x0, top, zm), Vector3(x0, wh, z1), Vector2(0, rh / 2.0), Vector2(hd / 4.0, 0), Vector2(hd / 2.0, rh / 2.0))
	MeshKit.tri(st, Vector3(x1, wh, z1), Vector3(x1, top, zm), Vector3(x1, wh, z0), Vector2(0, rh / 2.0), Vector2(hd / 4.0, 0), Vector2(hd / 2.0, rh / 2.0))
	MeshKit.quad(st, Vector3(x1, wh, z0), Vector3(x0, wh, z0), Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector2.ZERO, Vector2(hw / 2.0, wh / 2.0))
	house.add_child(MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture("plaster"))))

	# toit à deux pans, faîtage parallèle à l'écran
	var ov := 0.4
	var os := 0.3
	var slope := rh / (hd * 0.5)
	var ye := wh - slope * ov
	var slen := Vector2(hd * 0.5 + ov, rh + slope * ov).length()
	var uv1 := Vector2((hw + 2.0 * os) / 2.0, slen / 2.0)
	st = MeshKit.begin()
	MeshKit.quad(st, Vector3(x0 - os, top, zm), Vector3(x1 + os, top, zm), Vector3(x1 + os, ye, z1 + ov), Vector3(x0 - os, ye, z1 + ov), Vector2.ZERO, uv1)
	MeshKit.quad(st, Vector3(x1 + os, top, zm), Vector3(x0 - os, top, zm), Vector3(x0 - os, ye, z0 - ov), Vector3(x1 + os, ye, z0 - ov), Vector2.ZERO, uv1)
	house.add_child(MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture("roof_" + roof))))
	var pal: Array = TilePainter.ROOFS.get(roof, TilePainter.ROOFS["rouge"])
	var dark := MeshKit.flat_material(Color.from_string(str(pal[3]), Color.BLACK))
	_mesh_box(Vector3((x0 + x1) * 0.5, top + 0.02, zm), Vector3(hw + 2.0 * os + 0.1, 0.14, 0.22), dark)
	_mesh_box(Vector3((x0 + x1) * 0.5, ye - 0.03, z1 + ov - 0.03), Vector3(hw + 2.0 * os, 0.1, 0.08), MeshKit.flat_material(Color("#3c281c")))

	if bool(o.get("chimney", true)):
		var cpos := Vector3(x0 + hw * 0.74, top - 0.25, zm - hd * 0.16)
		st = MeshKit.begin()
		MeshKit.box(st, cpos, Vector3(0.55, 1.3, 0.55))
		house.add_child(MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture("brick"))))
		_mesh_box(cpos + Vector3(0, 0.68, 0), Vector3(0.68, 0.1, 0.68), MeshKit.flat_material(Color("#4a3a36")))
		if lit:
			var smoke := Atmosphere.make_particles("smoke")
			smoke.position = cpos + Vector3(0, 0.8, 0)
			world.add_child(smoke)

	if lit:
		for wx: Variant in windows:
			_add_light(Vector3(x0 + float(wx), 1.25, z1 + 0.6), WARM, 1.1, 3.8, false)
	world.rects.append(Rect2(x0, z0, hw, hd))
	# tout ce qui compose la maison peut s'estomper quand elle passe devant la caméra
	var parts: Array = []
	for n: Node in house.get_children():
		if n is GeometryInstance3D:
			parts.append(n)
	for i in range(first_child, world.get_child_count()):
		var n := world.get_child(i)
		if n is GeometryInstance3D:
			parts.append(n)
	world.occluders.append({"rect": Rect2(x0, z0, hw, hd), "nodes": parts, "fade": 0.0})

	if door_x >= 0.0:
		var xd := x0 + door_x
		if bool(o.get("awning", true)) and wh >= 2.9:
			# auvent de tuiles au-dessus de la porte, sur deux consoles de bois
			var ast := MeshKit.begin()
			MeshKit.quad(ast, Vector3(xd - 1.25, 2.78, z1), Vector3(xd + 1.25, 2.78, z1), Vector3(xd + 1.25, 2.44, z1 + 0.5), Vector3(xd - 1.25, 2.44, z1 + 0.5), Vector2.ZERO, Vector2(1.25, 0.35))
			var awn := MeshKit.finish(ast, MeshKit.pixel_material(Sprites.tile_texture("roof_" + roof)))
			house.add_child(awn)
			var awn_parts: Array = [awn, _mesh_box(Vector3(xd, 2.4, z1 + 0.5), Vector3(2.5, 0.07, 0.07), MeshKit.flat_material(Color("#3c281c")), false)]
			for sx: float in [-1.15, 1.15]:
				awn_parts.append(_mesh_box(Vector3(xd + sx, 2.56, z1 + 0.27), Vector3(0.07, 0.07, 0.5), MeshKit.flat_material(Color("#3c281c")), false))
			(world.occluders.back()["nodes"] as Array).append_array(awn_parts)
		# la lanterne se pose au-dessus de l'arc de la porte (dont le sommet est à 2,1 unités)
		if wh >= 2.4:
			_mesh_box(Vector3(xd, maxf(wh - 0.3, 3.0), z1 + 0.1), Vector3(0.2, 0.26, 0.16), MeshKit.flat_material(Color("#ffd28a"), 4.0), false)
			_mesh_box(Vector3(xd, maxf(wh - 0.14, 3.16), z1 + 0.1), Vector3(0.28, 0.06, 0.24), MeshKit.flat_material(Color("#2f2c38")), false)
		_add_light(Vector3(xd, wh - 0.6, z1 + 0.55), WARM, 1.6, 4.6, true, 0.08)
		var door_pos := Vector3(xd, 0.0, z1 + 0.35)
		var to: Variant = o.get("to")
		if to is Dictionary:
			world.warps.append({"rect": Rect2(xd - 0.45, z1, 0.9, 0.52), "map": str(to.get("map", "")), "spawn": str(to.get("spawn", ""))})
			keep_clear.append(Vector2(xd, z1 + 0.6))
		elif o.has("dialogue"):
			_interactable(door_pos, o, "Examiner", null, 1.6)
		else:
			keep_clear.append(Vector2(xd, z1 + 0.6))


func _lantern(o: Dictionary) -> void:
	var p := _p(o)
	var wood := MeshKit.flat_material(Color("#4a3426"))
	_mesh_box(p + Vector3(0, 0.95, 0), Vector3(0.12, 1.9, 0.12), wood)
	_mesh_box(p + Vector3(0, 0.06, 0), Vector3(0.3, 0.12, 0.3), wood)
	_mesh_box(p + Vector3(0, 2.07, 0), Vector3(0.32, 0.36, 0.32), MeshKit.flat_material(Color("#ffcf82"), 4.5), false)
	_mesh_box(p + Vector3(0, 2.29, 0), Vector3(0.46, 0.08, 0.46), MeshKit.flat_material(Color("#2f2c38")), false)
	_mesh_box(p + Vector3(0, 2.37, 0), Vector3(0.2, 0.08, 0.2), MeshKit.flat_material(Color("#2f2c38")), false)
	var color := Database.color(o.get("color", "#ffb45e"), WARM)
	_add_light(p + Vector3(0, 2.0, 0.05), color, float(o.get("energy", 3.2)), float(o.get("range", 7.5)), bool(o.get("shadow", false)), 0.1)
	world.circles.append(Vector3(p.x, p.z, 0.2))
	keep_clear.append(Vector2(p.x, p.z))


func _fence(o: Dictionary) -> void:
	var pts: Array = o.get("points", [])
	var wood := MeshKit.flat_material(Color("#6b4a30"))
	var wood_l := MeshKit.flat_material(Color("#86603e"))
	var lean := float(o.get("lean", 0.0))
	for i in range(pts.size() - 1):
		var pa: Array = pts[i]
		var pb: Array = pts[i + 1]
		var a := Vector2(float(pa[0]) + 0.5, float(pa[1]) + 0.5)
		var b := Vector2(float(pb[0]) + 0.5, float(pb[1]) + 0.5)
		var length := a.distance_to(b)
		if length < 0.05:
			continue
		var n := maxi(1, int(round(length)))
		for k in range(n + 1):
			var q := a.lerp(b, float(k) / float(n))
			var post := _mesh_box(Vector3(q.x, world.ground_y(q.x, q.y) + 0.4, q.y), Vector3(0.13, 0.8, 0.13), wood)
			post.rotation.z = deg_to_rad(rng.randf_range(-lean, lean))
		var mid := (a + b) * 0.5
		var angle := -atan2(b.y - a.y, b.x - a.x)
		for y: float in [0.3, 0.6]:
			var rail := _mesh_box(Vector3(mid.x, world.ground_y(mid.x, mid.y) + y, mid.y), Vector3(length, 0.07, 0.05), wood_l)
			rail.rotation.y = angle
			rail.rotation.z = deg_to_rad(rng.randf_range(-lean, lean) * 0.3)
		var steps := int(ceil(length / 0.35))
		for k in range(steps + 1):
			var q := a.lerp(b, float(k) / float(steps))
			world.circles.append(Vector3(q.x, q.y, 0.17))


## Balustrade de pierre mousseuse qui suit le relief (terrasses, bords de gouffre). Champs : `points` (cases,
## comme `fence`), `height` (0,6). Blocs de teintes variées, chapeau plus clair, mousse au pied et sur le dessus.
func _balustrade(o: Dictionary) -> void:
	var pts: Array = o.get("points", [])
	var hgt := float(o.get("height", 0.6))
	var tones := [Color("#6f7478"), Color("#7d8286"), Color("#62686c"), Color("#868a8c")]
	for i in range(pts.size() - 1):
		var pa: Array = pts[i]
		var pb: Array = pts[i + 1]
		var a := Vector2(float(pa[0]) + 0.5, float(pa[1]) + 0.5)
		var b := Vector2(float(pb[0]) + 0.5, float(pb[1]) + 0.5)
		var length := a.distance_to(b)
		if length < 0.05:
			continue
		var n := maxi(1, int(round(length / 0.8)))
		var angle := -atan2(b.y - a.y, b.x - a.x)
		for k in range(n):
			var q := a.lerp(b, (float(k) + 0.5) / float(n))
			var seg := length / float(n)
			var gy: float = world.ground_y(q.x, q.y)
			var tone: Color = tones[rng.randi() % tones.size()]
			var block := _mesh_box(Vector3(q.x, gy + hgt * 0.5, q.y), Vector3(seg * 0.96, hgt, 0.3), MeshKit.flat_material(tone))
			block.rotation.y = angle
			var cap := _mesh_box(Vector3(q.x, gy + hgt + 0.04, q.y), Vector3(seg, 0.09, 0.38), MeshKit.flat_material(tone.lightened(0.12)))
			cap.rotation.y = angle
			if rng.randf() < 0.55:
				var moss := _mesh_box(Vector3(q.x + rng.randf_range(-0.12, 0.12), gy + hgt + 0.1, q.y), Vector3(seg * rng.randf_range(0.3, 0.7), 0.05, 0.3), MeshKit.flat_material(Color("#5a8a3c").darkened(rng.randf_range(0.0, 0.25))))
				moss.rotation.y = angle
			if rng.randf() < 0.5:
				var foot := _mesh_box(Vector3(q.x, gy + 0.12, q.y + 0.0), Vector3(seg * rng.randf_range(0.4, 0.9), 0.24, 0.34), MeshKit.flat_material(Color("#4f7a38").darkened(rng.randf_range(0.0, 0.2))))
				foot.rotation.y = angle
		var steps := int(ceil(length / 0.35))
		for k in range(steps + 1):
			var q2 := a.lerp(b, float(k) / float(steps))
			world.circles.append(Vector3(q2.x, q2.y, 0.17))


func _npc(o: Dictionary) -> void:
	var id := str(o.get("id", ""))
	if not Database.characters.has(id):
		push_warning("PNJ sans fiche dans characters.json : " + id)
	var pos := _p(o)
	var node := Npc.new()
	node.name = "Npc_" + id
	world.add_child(node)
	node.setup(world, o, pos)
	world.npcs.append(node)
	var data := o.duplicate()
	if not data.has("dialogue"):
		data["dialogue"] = id
	_interactable(pos, data, "Parler", node, float(node.sprite.height) * 0.72)


## Monstre visible sur la carte (gardien, boss) : première pose de sa planche, qui respire.
func _monster(o: Dictionary) -> void:
	var def := Database.get_enemy(str(o.get("id", "")))
	var sp: Dictionary = {}
	var spv: Variant = def.get("sprite", {})
	if spv is Dictionary:
		sp = spv
	var sheet := Sprites.monster(str(sp.get("monster", "")))
	var ppu := float(sheet["ppu"])
	var s := float(o.get("scale", sp.get("scale", 1.0)))
	var pos := _p(o)
	var node := Node3D.new()
	node.name = "Monster_" + str(o.get("id", ""))
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(float(sheet["frame_w"]) / ppu, float(sheet["frame_h"]) / ppu)
	quad.mesh = mesh
	var tex: Texture2D = sheet["texture"]
	quad.material_override = Sprites.sprite_material(tex, 0.0, 0.0, false)
	quad.position.y = mesh.size.y * 0.5 - float(sheet["foot"]) / ppu
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	node.add_child(quad)
	node.position = pos
	node.scale = Vector3(-s if bool(o.get("flip", false)) else s, s, s)
	world.add_child(node)
	quad.set_instance_shader_parameter("frame_rect", Vector4(0.0, 0.0, 1.0 / float(int(sheet["columns"])), 1.0))
	var tw := node.create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "scale:y", s * 1.05, 1.5)
	tw.tween_property(node, "scale:y", s, 1.5)
	world.circles.append(Vector3(pos.x, pos.z, float(o.get("solid", 0.45 * s))))
	if o.has("dialogue"):
		_interactable(pos, o, "Approcher", null, mesh.size.y * s * 0.8)


func _light(o: Dictionary) -> void:
	var p := _p(o)
	p.y += float(o.get("height", 2.4))
	_add_light(p, Database.color(o.get("color", "#ffb45e"), WARM), float(o.get("energy", 1.5)), float(o.get("range", 6.0)),
			bool(o.get("shadow", false)), float(o.get("flicker", 0.0)))


func _rect2(o: Dictionary) -> Rect2:
	var r: Array = o.get("rect", [0, 0, 1, 1])
	return Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))


func _warp(o: Dictionary) -> void:
	var to: Dictionary = o.get("to", {})
	world.warps.append({"rect": _rect2(o), "map": str(to.get("map", "")), "spawn": str(to.get("spawn", ""))})


func _trigger(o: Dictionary) -> void:
	world.triggers.append({
		"rect": _rect2(o),
		"dialogue": str(o.get("dialogue", "")),
		"unless": str(o.get("unless", "")),
	})


# ----------------------------------------------------------------- mobilier

func _textured(st: SurfaceTool, tile: String) -> MeshInstance3D:
	var node := MeshKit.finish(st, MeshKit.pixel_material(Sprites.tile_texture(tile)))
	world.add_child(node)
	return node


func _candle(pos: Vector3) -> void:
	_mesh_box(pos + Vector3(0, 0.08, 0), Vector3(0.07, 0.16, 0.07), MeshKit.flat_material(Color("#efe6d2")), false)
	_mesh_box(pos + Vector3(0, 0.21, 0), Vector3(0.05, 0.09, 0.05), MeshKit.flat_material(Color("#ffc46a"), 6.0), false)
	_add_light(pos + Vector3(0, 0.35, 0), WARM, 0.9, 3.4, false, 0.14)


func _table(o: Dictionary) -> void:
	var p := _p(o)
	var size: Array = o.get("size", [1.4, 0.9])
	var sx := float(size[0])
	var sz := float(size[1])
	var st := MeshKit.begin()
	MeshKit.box(st, p + Vector3(0, 0.56, 0), Vector3(sx, 0.1, sz))
	for dx: float in [-1.0, 1.0]:
		for dz: float in [-1.0, 1.0]:
			MeshKit.box(st, p + Vector3(dx * (sx * 0.5 - 0.1), 0.255, dz * (sz * 0.5 - 0.1)), Vector3(0.1, 0.51, 0.1))
	_textured(st, "wood")
	world.rects.append(Rect2(p.x - sx * 0.5, p.z - sz * 0.5, sx, sz))
	if bool(o.get("candle", false)):
		_candle(p + Vector3(0, 0.61, 0))
	if o.has("dialogue"):
		_interactable(p, o, "Examiner", null, 1.0)


func _stool(o: Dictionary) -> void:
	var p := _p(o)
	var st := MeshKit.begin()
	MeshKit.box(st, p + Vector3(0, 0.3, 0), Vector3(0.42, 0.08, 0.42))
	MeshKit.box(st, p + Vector3(0, 0.13, 0), Vector3(0.26, 0.26, 0.26))
	_textured(st, "wood")
	world.circles.append(Vector3(p.x, p.z, 0.22))


func _counter(o: Dictionary) -> void:
	var r := _rect2(o)
	var hgt := float(o.get("height", 0.8))
	var c := Vector3(r.position.x + r.size.x * 0.5, 0.0, r.position.y + r.size.y * 0.5)
	var st := MeshKit.begin()
	MeshKit.box(st, c + Vector3(0, hgt * 0.5, 0), Vector3(r.size.x, hgt, r.size.y))
	_textured(st, "wood")
	_mesh_box(c + Vector3(0, hgt + 0.035, 0), Vector3(r.size.x + 0.12, 0.07, r.size.y + 0.12), MeshKit.flat_material(Color("#b5834e")))
	world.rects.append(r)


## Étal de marché : comptoir de bois, quatre poteaux, auvent de toile rayée en pente (haut derrière, bas devant, pour
## ne jamais cacher la marchande), marchandises posées (meules, flacons, cageot) et saucissons pendus.
## `pos` [x, z] : coin nord-ouest du comptoir ; `width` (3 par défaut) ; `colors` : deux teintes de l'auvent ;
## `goods` : "fromage" (meules, par défaut), "bouteilles" ou "mixte".
func _market_stall(o: Dictionary) -> void:
	var p: Array = o.get("pos", [0, 0])
	var wd := float(o.get("width", 3.0))
	var x0 := float(p[0])
	var z0 := float(p[1])
	var cx := x0 + wd * 0.5
	var wood := MeshKit.flat_material(Color("#5a3e26"))
	var plank := MeshKit.flat_material(Color("#8a6038"))
	# comptoir et plateau
	_mesh_box(Vector3(cx, 0.4, z0 + 0.4), Vector3(wd, 0.8, 0.8), plank)
	_mesh_box(Vector3(cx, 0.83, z0 + 0.4), Vector3(wd + 0.14, 0.07, 0.92), MeshKit.flat_material(Color("#b5834e")))
	_mesh_box(Vector3(cx, 0.22, z0 + 0.82), Vector3(wd - 0.1, 0.34, 0.04), wood, false)
	# poteaux : deux devant (au bord du comptoir), deux derrière
	for sx: float in [x0 + 0.08, x0 + wd - 0.08]:
		_mesh_box(Vector3(sx, 1.35, z0 + 0.86), Vector3(0.1, 2.7, 0.1), wood)
		_mesh_box(Vector3(sx, 1.5, z0 - 1.1), Vector3(0.1, 3.0, 0.1), wood)
	# auvent : bandes alternées rouge et crème, du haut (derrière) vers le bas (devant)
	var ca := Color(str((o.get("colors", ["#a8382e", "#efe2c0"]) as Array)[0]))
	var cb := Color(str((o.get("colors", ["#a8382e", "#efe2c0"]) as Array)[1]))
	var nb := maxi(4, int(round(wd / 0.5)))
	var bw := wd / float(nb)
	for i in nb:
		var st := MeshKit.begin()
		var xa := x0 + bw * i
		var xb := xa + bw
		MeshKit.quad(st, Vector3(xa, 3.0, z0 - 1.1), Vector3(xb, 3.0, z0 - 1.1), Vector3(xb, 2.55, z0 + 0.95), Vector3(xa, 2.55, z0 + 0.95))
		var band := MeshKit.finish(st, MeshKit.flat_material(ca if i % 2 == 0 else cb), false)
		world.add_child(band)
	# volant festonné au bord bas de l'auvent
	for i in nb:
		_mesh_box(Vector3(x0 + bw * (i + 0.5), 2.47, z0 + 0.97), Vector3(bw * 0.92, 0.16, 0.03), MeshKit.flat_material(ca if i % 2 == 0 else cb), false)
	# marchandises sur le plateau
	var kind := str(o.get("goods", "fromage"))
	var gx := x0 + 0.35
	var k := 0
	while gx < x0 + wd - 0.3:
		var pick := (k + (0 if kind == "mixte" else (0 if kind == "fromage" else 1))) % 2
		if kind == "bouteilles":
			pick = 1
		if pick == 0:
			# meule de fromage (deux disques empilés) avec sa part entamée
			_mesh_box(Vector3(gx, 0.92, z0 + 0.36), Vector3(0.42, 0.16, 0.42), MeshKit.flat_material(Color("#e8c050")))
			_mesh_box(Vector3(gx, 1.06, z0 + 0.36), Vector3(0.34, 0.14, 0.34), MeshKit.flat_material(Color("#f0cc62")))
			_mesh_box(Vector3(gx + 0.12, 1.0, z0 + 0.58), Vector3(0.14, 0.1, 0.14), MeshKit.flat_material(Color("#c89a38")), false)
		else:
			# flacons : un grand vert, un petit ambré
			_mesh_box(Vector3(gx, 1.0, z0 + 0.36), Vector3(0.14, 0.3, 0.14), MeshKit.flat_material(Color("#3c7a4a")))
			_mesh_box(Vector3(gx + 0.2, 0.95, z0 + 0.5), Vector3(0.12, 0.2, 0.12), MeshKit.flat_material(Color("#c8842c")))
		gx += 0.62
		k += 1
	# saucissons pendus sous l'auvent (le bas de l'auvent est à 2,5)
	for i in 3:
		var sx2 := x0 + wd * (0.25 + 0.25 * i)
		_mesh_box(Vector3(sx2, 2.22, z0 - 0.35), Vector3(0.06, 0.5, 0.06), MeshKit.flat_material(Color("#8a3a30")), false)
		_mesh_box(Vector3(sx2 + 0.09, 2.3, z0 - 0.35), Vector3(0.06, 0.34, 0.06), MeshKit.flat_material(Color("#9a4a36")), false)
	# cageot au flanc du comptoir et lanterne pendue
	_mesh_box(Vector3(x0 + wd + 0.4, 0.3, z0 + 0.45), Vector3(0.6, 0.6, 0.6), plank)
	_mesh_box(Vector3(x0 + wd + 0.4, 0.66, z0 + 0.45), Vector3(0.44, 0.12, 0.44), MeshKit.flat_material(Color("#d8a040")), false)
	_mesh_box(Vector3(x0 + 0.3, 2.3, z0 + 0.75), Vector3(0.16, 0.22, 0.16), MeshKit.flat_material(Color("#ffcf82"), 4.0), false)
	_add_light(Vector3(x0 + 0.3, 2.2, z0 + 0.8), Color("#ffb45e"), 1.4, 4.0, false, 0.08)
	world.rects.append(Rect2(x0, z0, wd, 0.9))
	world.circles.append(Vector3(x0 + wd + 0.4, z0 + 0.45, 0.45))


## Lit : cadre de bois, matelas, couverture colorée (`color`) et oreiller du côté gauche. `rect` [x, z, l, p].
func _bed(o: Dictionary) -> void:
	var r := _rect2(o)
	var c := Vector3(r.position.x + r.size.x * 0.5, 0.0, r.position.y + r.size.y * 0.5)
	var st := MeshKit.begin()
	MeshKit.box(st, c + Vector3(0, 0.2, 0), Vector3(r.size.x, 0.4, r.size.y))
	MeshKit.box(st, c + Vector3(-r.size.x * 0.5 + 0.06, 0.55, 0), Vector3(0.12, 1.1, r.size.y))
	_textured(st, "wood")
	_mesh_box(c + Vector3(0.0, 0.46, 0), Vector3(r.size.x - 0.14, 0.12, r.size.y - 0.1), MeshKit.flat_material(Color("#e8dcc0")))
	_mesh_box(c + Vector3(0.3, 0.53, 0), Vector3(r.size.x - 0.7, 0.07, r.size.y - 0.08), MeshKit.flat_material(Color(str(o.get("color", "#8a3a3a")))))
	_mesh_box(c + Vector3(-r.size.x * 0.5 + 0.4, 0.56, 0), Vector3(0.4, 0.12, r.size.y * 0.6), MeshKit.flat_material(Color("#f4eee0")))
	world.rects.append(r)


func _fireplace(o: Dictionary) -> void:
	var p: Array = o.get("pos", [0, 0])
	var x := float(p[0]) + 0.5
	var z := float(p[1])
	var st := MeshKit.begin()
	MeshKit.box(st, Vector3(x - 0.8, 0.7, z + 0.3), Vector3(0.36, 1.4, 0.6))
	MeshKit.box(st, Vector3(x + 0.8, 0.7, z + 0.3), Vector3(0.36, 1.4, 0.6))
	MeshKit.box(st, Vector3(x, 1.56, z + 0.32), Vector3(2.0, 0.34, 0.68))
	MeshKit.box(st, Vector3(x, 1.73 + (wall_height - 1.73) * 0.5, z + 0.2), Vector3(1.3, wall_height - 1.73, 0.4))
	MeshKit.box(st, Vector3(x, 0.04, z + 0.5), Vector3(1.7, 0.08, 1.0))
	_textured(st, "stone")
	_mesh_box(Vector3(x, 0.7, z + 0.05), Vector3(1.3, 1.4, 0.1), MeshKit.flat_material(Color("#0d0a12")), false)
	var log_mat := MeshKit.flat_material(Color("#3c281c"))
	var l1 := _mesh_box(Vector3(x, 0.16, z + 0.36), Vector3(0.75, 0.13, 0.15), log_mat, false)
	l1.rotation.y = 0.3
	var l2 := _mesh_box(Vector3(x, 0.24, z + 0.36), Vector3(0.7, 0.12, 0.14), log_mat, false)
	l2.rotation.y = -0.35
	for kind: String in ["fire", "embers"]:
		var fx := Atmosphere.make_particles(kind)
		fx.position = Vector3(x, 0.26, z + 0.38)
		world.add_child(fx)
	_add_light(Vector3(x, 0.75, z + 1.0), Color("#ff9a4a"), float(o.get("energy", 5.0)), 9.5, true, 0.2)
	world.rects.append(Rect2(x - 1.0, z, 2.0, 0.65))
	if o.has("dialogue"):
		_interactable(Vector3(x, 0, z + 0.7), o, "Examiner", null, 1.9)


func _stove(o: Dictionary) -> void:
	var p: Array = o.get("pos", [0, 0])
	var x := float(p[0]) + 0.5
	var z := float(p[1])
	var st := MeshKit.begin()
	MeshKit.box(st, Vector3(x, 0.42, z + 0.36), Vector3(1.3, 0.84, 0.72))
	MeshKit.box(st, Vector3(x + 0.4, 0.84 + (wall_height - 0.84) * 0.5, z + 0.18), Vector3(0.24, wall_height - 0.84, 0.24))
	MeshKit.box(st, Vector3(x - 0.25, 0.97, z + 0.38), Vector3(0.42, 0.26, 0.42))
	_textured(st, "iron")
	_mesh_box(Vector3(x - 0.1, 0.36, z + 0.73), Vector3(0.44, 0.24, 0.03), MeshKit.flat_material(Color("#ff8a3c"), 5.0), false)
	_add_light(Vector3(x - 0.1, 0.5, z + 1.1), Color("#ff8a3c"), 1.8, 3.6, false, 0.18)
	world.rects.append(Rect2(x - 0.65, z, 1.3, 0.72))
	if o.has("dialogue"):
		_interactable(Vector3(x, 0, z + 0.8), o, "Examiner", null, 1.5)


func _rug(o: Dictionary) -> void:
	var r := _rect2(o)
	var main := Database.color(o.get("color", "#8a3040"), Color("#8a3040"))
	var border := Database.color(o.get("border", "#c9a24a"), Color("#c9a24a"))
	var tex: Texture2D = Sprites.cached("rug:%s:%s" % [str(r), main.to_html()], func() -> Texture2D:
		return PA.texture(TilePainter.rug(r.size.x, r.size.y, main, border)))
	var st := MeshKit.begin()
	MeshKit.quad(st, Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, 0, r.position.y), Vector3(r.end.x, 0, r.end.y), Vector3(r.position.x, 0, r.end.y))
	var node := MeshKit.finish(st, MeshKit.pixel_material(tex), false)
	node.position.y = 0.012
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(node)


func _crate(o: Dictionary) -> void:
	var p := _p(o)
	var s := float(o.get("size", 0.7))
	var st := MeshKit.begin()
	MeshKit.box(st, p + Vector3(0, s * 0.5, 0), Vector3(s, s, s))
	var node := _textured(st, "wood")
	node.rotation.y = deg_to_rad(float(o.get("turn", 0.0)))
	world.circles.append(Vector3(p.x, p.z, s * 0.6))
	if o.has("dialogue"):
		_interactable(p, o, "Ouvrir", null, s + 0.25)
