extends Node
## Test de fumée, à lancer sans fenêtre :
##   Godot --headless --path . res://tests/smoke_test.tscn
## Vérifie les données, la génération des sprites, la construction des cartes,
## l'accessibilité de chaque PNJ et passage, les dialogues, la sauvegarde et le
## déroulé complet titre -> nouvelle partie -> changement de carte -> continuer.

const World = preload("res://src/world/world.gd")
const DialogueBox = preload("res://src/ui/dialogue_box.gd")
const MAIN = preload("res://scenes/main.tscn")
const BattleEngine = preload("res://src/battle/battle_engine.gd")
const BattleScene = preload("res://src/battle/battle_scene.gd")
const BattleUI = preload("res://src/battle/battle_ui.gd")
const Rules = preload("res://src/battle/rules.gd")
const MonsterPainter = preload("res://src/gfx/monster_painter.gd")
const GameMenu = preload("res://src/ui/game_menu.gd")
const TalentScreen = preload("res://src/ui/talent_screen.gd")
const BattleFx = preload("res://src/battle/battle_fx.gd")
const FxPainter = preload("res://src/gfx/fx_painter.gd")

var failures := 0
var checks := 0
var verbose := false


func check(cond: bool, what: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("  ECHEC : ", what)


func _ready() -> void:
	verbose = OS.get_cmdline_user_args().has("--verbose")
	SaveManager.save_path = "user://test_sauvegarde.json"
	SaveManager.delete_save()
	print("== Données ==")
	_test_data()
	print("== Sprites ==")
	_test_sprites()
	print("== Combat : règles ==")
	_test_engine()
	print("== Combat : équilibre (combats simulés) ==")
	_test_balance()
	print("== Quêtes, équipement, argent, Ramollissement ==")
	_test_step4()
	print("== Talents ==")
	_test_talents()
	print("== Animations de combat : données ==")
	_test_animations()
	print("== Musique ==")
	_test_music()
	_test_rendering()
	_test_chapter_2_data()
	if OS.has_environment("GLAN_QUICK"):
		print("%d vérifications, %d échec(s) (passage rapide : règles et équilibre seulement)." % [checks, failures])
		get_tree().quit(1 if failures > 0 else 0)
		return
	print("== Combat : scène et interface ==")
	await _test_battle_scene()
	print("== Animations de combat : jouées une à une ==")
	await _test_animation_play()
	print("== Cartes ==")
	for id in Database.list_maps():
		await _test_map(id)
		await _test_gated(id)
	# Bittebourg change au fil du chapitre : tout doit rester atteignable à chaque moment.
	var fete := ["intro_vue", "potager_soigne", "fete_commencee", "fusees_pretes"]
	await _test_map("bittebourg", fete, "soir de la Fête")
	await _test_map("bittebourg", fete + ["invasion", "naze_arrive"], "invasion")
	await _test_map("bittebourg", fete + ["invasion", "naze_arrive", "combat_morfales_quai", "combat_morfales_potager", "combat_morfales_auberge", "morfales_chasses"], "face au Naze")
	await _test_map("bittebourg", fete + ["naze_arrive", "combat_morfales_quai", "combat_morfales_potager", "combat_morfales_auberge", "morfales_chasses", "naze_vaincu", "route_ouverte", "source_trouvee"], "après le Naze")
	await _test_map("route_brie", ["combat_morfales_route"], "péage forcé")
	print("== Dialogues ==")
	await _test_dialogue_box()
	print("== Sauvegarde ==")
	_test_save()
	print("== Menus : équipe, inventaire, journal, boutique ==")
	await _test_menus()
	print("== Écran de talents ==")
	await _test_talent_screen()
	print("== Déroulé complet ==")
	await _test_flow()
	await _test_chapter_2()
	SaveManager.delete_save()
	print("")
	print("%d vérifications, %d échec(s)." % [checks, failures])
	print("RESULTAT : " + ("OK" if failures == 0 else "ECHEC"))
	get_tree().quit(1 if failures > 0 else 0)


# ------------------------------------------------------------------- données

func _walk_dialogue(id: String, nodes: Array) -> void:
	for n: Variant in nodes:
		check(n is Dictionary, "dialogue %s : entrée qui n'est pas un objet" % id)
		if not (n is Dictionary):
			continue
		var d: Dictionary = n
		var known := false
		for key: String in ["text", "if", "set", "choice", "action", "battle", "give", "join", "take", "money", "shop", "chapter", "banner", "music"]:
			if d.has(key):
				known = true
		if d.has("battle"):
			check(not Database.get_encounter(str(d["battle"])).is_empty(), "dialogue %s : combat inconnu « %s »" % [id, str(d["battle"])])
		if d.has("give"):
			check(not Database.get_item(str(d["give"])).is_empty(), "dialogue %s : objet inconnu « %s »" % [id, str(d["give"])])
		if d.has("take"):
			check(not Database.get_item(str(d["take"])).is_empty(), "dialogue %s : objet inconnu « %s »" % [id, str(d["take"])])
		if d.has("shop"):
			check(not Database.get_shop(str(d["shop"])).is_empty(), "dialogue %s : boutique inconnue « %s »" % [id, str(d["shop"])])
		if d.has("join"):
			check(not Rules.battle_def(str(d["join"])).is_empty(), "dialogue %s : recrue sans fiche de combat « %s »" % [id, str(d["join"])])
		check(known, "dialogue %s : entrée sans instruction connue : %s" % [id, str(d)])
		if d.has("who"):
			check(Database.characters.has(str(d["who"])), "dialogue %s : personnage inconnu « %s »" % [id, str(d["who"])])
		for key: String in ["then", "else"]:
			if d.has(key):
				check(d[key] is Array, "dialogue %s : « %s » doit être une liste" % [id, key])
				if d[key] is Array:
					_walk_dialogue(id, d[key])
		if d.has("choice"):
			check(d["choice"] is Array, "dialogue %s : « choice » doit être une liste" % id)
			if d["choice"] is Array:
				for opt: Variant in d["choice"]:
					check(opt is Dictionary and (opt as Dictionary).has("text"), "dialogue %s : choix sans texte" % id)
					if opt is Dictionary and (opt as Dictionary).get("then") is Array:
						_walk_dialogue(id, opt["then"])


func _music_nodes(node: Variant, found: Array) -> void:
	if node is Array:
		for child: Variant in node:
			_music_nodes(child, found)
	elif node is Dictionary:
		if node.has("music"):
			found.append(str(node["music"]))
		for key: Variant in node:
			_music_nodes(node[key], found)


## Rendu HD-2D : ambiances bien formées, shaders et décors de la passe présents.
func _test_rendering() -> void:
	var atmosphere = preload("res://src/world/atmosphere.gd")
	var with_rays := 0
	for id: String in Database.ambiances:
		var amb: Dictionary = Database.ambiances[id]
		for kind: Variant in amb.get("particles", []):
			check(atmosphere.PARTICLES.has(str(kind)), "ambiance %s : particules %s connues" % [id, kind])
		if amb.has("rays"):
			with_rays += 1
			var rays: Variant = amb["rays"]
			check(rays is Dictionary, "ambiance %s : rays est un dictionnaire" % id)
			if rays is Dictionary:
				var strength := float(rays.get("strength", 0.1))
				check(strength > 0.0 and strength <= 0.08, "ambiance %s : rayons discrets (force %s)" % [id, strength])
				check(float(rays.get("density", 0.01)) <= 0.02, "ambiance %s : rayons peu nombreux" % id)
	check(with_rays >= 2, "des ambiances ont des rayons de lumière")
	for path: String in ["ground", "water", "rays", "vignette"]:
		check(load("res://src/gfx/shaders/%s.gdshader" % path) is Shader, "shader %s chargé" % path)
	check(Sprites.tile_texture("cliff") != null, "texture de talus")
	var painter = preload("res://src/gfx/prop_painter.gd")
	for v in 3:
		var img: Image = painter.fern(v)
		check(img != null and not img.get_used_rect().size == Vector2i.ZERO, "fougère %d peinte" % v)
	# combat : personne ne se cache derrière son voisin, tout le monde tient à l'écran
	for n in range(1, 7):
		for big: float in [1.0, 1.6]:
			var scales: Array = []
			for i in n:
				scales.append(big if i == 0 else 1.0)
			var spots: Array[Vector3] = BattleScene.formation(scales)
			check(spots.size() == n, "formation à %d : une place par combattant" % n)
			for i in n:
				check(spots[i].x > 1.0 and spots[i].x < 6.6, "formation à %d : place %d dans le cadre" % [n, i])
				if i > 0:
					var gap := absf(spots[i].x - spots[i - 1].x)
					check(gap >= (1.3 if n <= 4 else 0.75), "formation à %d : écart %.2f entre voisins" % [n, gap])
	# le relief peint ne touche ni les contours ni la transparence
	var flat := Image.create(8, 8, false, Image.FORMAT_RGBA8)
	flat.fill_rect(Rect2i(2, 2, 4, 4), Color("#4f7d5a"))
	var pa = preload("res://src/gfx/pixel_art.gd")
	pa.relief(flat)
	check(flat.get_pixel(0, 0).a < 0.5, "relief : le vide reste vide")
	check(flat.get_pixel(2, 2).get_luminance() > flat.get_pixel(5, 5).get_luminance(), "relief : lumière en haut à gauche, ombre en bas à droite")
	for id: String in Database.arenas if "arenas" in Database else {}:
		var back: Variant = (Database.arenas[id] as Dictionary).get("backdrop", {})
		check(back is Dictionary, "arène %s : backdrop est un dictionnaire" % id)
		if back is Dictionary and back.has("tile"):
			check(Sprites.tile_texture(str(back["tile"])) != null, "arène %s : texture de fond" % id)
	var world_script = preload("res://src/world/world.gd")
	check(world_script.ZOOM > 0.7 and world_script.ZOOM <= 1.0, "caméra : rapprochement raisonnable")


func _test_music() -> void:
	check(Database.music.size() >= 10, "music.json chargé")
	for id: String in Database.music:
		var errors: Array = Music.check_track(Database.music[id])
		check(errors.is_empty(), "musique %s : %s" % [id, ", ".join(PackedStringArray(errors))])
	for kind: String in ["title", "battle", "victory"]:
		check(Database.music.has(Music.default(kind)), "musique par défaut : " + kind)
	for id in Database.list_maps():
		var map := Database.get_map(id)
		check(Database.music.has(str(map.get("music", ""))), "carte %s : musique connue" % id)
		for s: Variant in map.get("music_states", []):
			check(s is Dictionary and Database.music.has(str(s.get("music", ""))), "carte %s : musique d'état connue" % id)
	for id: String in Database.encounters:
		check(Database.music.has(Music.for_encounter(Database.encounters[id])), "rencontre %s : musique connue" % id)
	var in_dialogues: Array = []
	_music_nodes(Database.dialogues, in_dialogues)
	for id: String in in_dialogues:
		check(Database.music.has(id), "dialogue : musique %s connue" % id)
	check(in_dialogues.has("menace"), "le prologue lance sa musique")
	# un morceau est réellement calculé : il a la bonne durée et il s'entend
	var track: Dictionary = Database.music[Music.default("victory")]
	var bytes: PackedByteArray = Music.render(track)
	var peak := 0
	for i in range(0, bytes.size() - 1, 200):
		peak = maxi(peak, absi(bytes.decode_s16(i)))
	check(bytes.size() > Music.RATE * 2 * 6 and peak > 8000, "musique : la fanfare de victoire s'entend (%d octets, crête %d)" % [bytes.size(), peak])
	var parsed: Dictionary = Music.parse_voice({"len": 2, "notes": "c4 bb3:4 r f#5+a5"})
	check(int(parsed["length"]) == 10 and (parsed["events"] as Array).size() == 3, "musique : lecture d'une voix")
	check(int(parsed["events"][1][2][0]) == 58 and int(parsed["events"][2][2][0]) == 78, "musique : hauteur des notes")
	GameState.new_game()
	check(Music.for_map(Database.get_map("bittebourg")) == "village", "Bittebourg : musique du village au début")
	Music.play("village")
	check(Music.current == "village", "musique : morceau demandé retenu")
	Music.play("")
	print("  %d morceaux" % Database.music.size())


func _test_data() -> void:
	check(not Database.game.is_empty(), "game.json chargé")
	check(Database.characters.size() >= 5, "characters.json chargé")
	check(Database.dialogues.size() >= 10, "dialogues chargés")
	var start: Dictionary = Database.game.get("start", {})
	check(Database.has_map(str(start.get("map", ""))), "carte de départ existante")
	for id: String in Database.dialogues:
		_walk_dialogue(id, Database.get_dialogue(id))
	for id in Database.list_maps():
		var map := Database.get_map(id)
		check(str(map.get("id", "")) == id, "carte %s : champ id cohérent avec le nom du fichier" % id)
		check(Database.ambiances.has(str(map.get("ambiance", ""))), "carte %s : ambiance connue" % id)
		for e: Variant in map.get("on_enter", []):
			check(Database.has_dialogue(str(e.get("dialogue", ""))), "carte %s : dialogue d'entrée %s" % [id, str(e.get("dialogue", ""))])
		for o: Dictionary in map.get("objects", []):
			var type := str(o.get("type", ""))
			if type == "npc":
				check(Database.characters.has(str(o.get("id", ""))), "carte %s : PNJ %s décrit dans characters.json" % [id, str(o.get("id", ""))])
				check(Database.has_dialogue(str(o.get("dialogue", o.get("id", "")))), "carte %s : dialogue du PNJ %s" % [id, str(o.get("id", ""))])
			elif o.has("dialogue"):
				check(Database.has_dialogue(str(o["dialogue"])), "carte %s : dialogue %s" % [id, str(o["dialogue"])])
			var to: Variant = o.get("to")
			if to is Dictionary:
				var target := str(to.get("map", ""))
				check(Database.has_map(target), "carte %s : passage vers une carte existante (%s)" % [id, target])
				if Database.has_map(target):
					var spawns: Dictionary = Database.get_map(target).get("spawns", {})
					check(spawns.has(str(to.get("spawn", ""))), "carte %s : point d'arrivée %s dans %s" % [id, str(to.get("spawn", "")), target])
	print("  %d dialogues, %d personnages, %d cartes" % [Database.dialogues.size(), Database.characters.size(), Database.list_maps().size()])
	_test_battle_data()


func _check_effects(what: String, def: Dictionary) -> void:
	check(str(def.get("name", "")) != "", "%s : nom" % what)
	check(str(def.get("target", "")) in ["enemy", "all_enemies", "ally", "all_allies", "self", "ally_ko"], "%s : cible connue" % what)
	var effects: Variant = def.get("effects", [])
	check(effects is Array and not (effects as Array).is_empty(), "%s : au moins un effet" % what)
	if not (effects is Array):
		return
	for fx: Variant in effects:
		check(fx is Dictionary, "%s : effet mal formé" % what)
		if not (fx is Dictionary):
			continue
		var type := str(fx.get("type", ""))
		check(type in ["damage", "heal", "mana", "status", "cure", "revive", "steal"], "%s : type d'effet connu (%s)" % [what, type])
		if type == "damage":
			check(Database.elements.has(str(fx.get("element", ""))), "%s : élément connu" % what)
		if type == "status":
			check(Database.statuses.has(str(fx.get("id", ""))), "%s : état connu" % what)


func _check_enemy_list(what: String, list: Variant) -> void:
	check(list is Array and not (list as Array).is_empty(), "%s : au moins un ennemi" % what)
	if list is Array:
		for e: Variant in list:
			check(Database.enemies.has(str(e)), "%s : ennemi connu (%s)" % [what, str(e)])


func _test_battle_data() -> void:
	check(Database.elements.size() >= 4 and Database.statuses.size() >= 4, "éléments et états chargés")
	check(Database.statuses.has("ebranle"), "état « ebranle » présent (bouclier brisé)")
	for id: String in Database.skills:
		_check_effects("compétence " + id, Database.get_skill(id))
	for id: String in Database.items:
		var item := Database.get_item(id)
		check(str(item.get("name", "")) != "" and str(item.get("desc", "")) != "", "objet %s : nom et description" % id)
		match Database.item_kind(id):
			"equipment":
				check(GameState.SLOTS.has(str(item.get("slot", ""))), "équipement %s : emplacement connu" % id)
				check(item.get("mods") is Dictionary, "équipement %s : bonus" % id)
				for key: String in item.get("mods", {}):
					check(Rules.STATS.has(key), "équipement %s : caractéristique connue (%s)" % [id, key])
				for who: Variant in item.get("for", []):
					check(not Rules.battle_def(str(who)).is_empty(), "équipement %s : porteur connu (%s)" % [id, str(who)])
			"key":
				check(not Database.is_consumable(id), "objet de quête %s : sans effet de combat" % id)
			_:
				_check_effects("objet " + id, item)
	for id: String in Database.characters:
		var def := Rules.battle_def(id)
		if def.is_empty():
			continue
		check(Database.elements.has(str(def.get("element", ""))), "personnage %s : élément de l'attaque" % id)
		var learn: Dictionary = def.get("learn", {})
		for lv: String in learn:
			for s: Variant in learn[lv]:
				check(Database.skills.has(str(s)), "personnage %s : compétence connue (%s)" % [id, str(s)])
		check(int(Rules.stats_at(id, 1)["hp"]) > 0 and int(Rules.stats_at(id, 10)["hp"]) > int(Rules.stats_at(id, 1)["hp"]), "personnage %s : PV qui progressent" % id)
	for id: String in Database.enemies:
		var def := Database.get_enemy(id)
		check(int((def.get("stats", {}) as Dictionary).get("hp", 0)) > 0, "ennemi %s : PV" % id)
		for w: Variant in def.get("weak", []):
			check(Database.elements.has(str(w)), "ennemi %s : faiblesse connue (%s)" % [id, str(w)])
		for s: Variant in def.get("immune", []):
			check(Database.statuses.has(str(s)), "ennemi %s : immunité connue (%s)" % [id, str(s)])
		for a: Variant in def.get("ai", []):
			var sk := str((a as Dictionary).get("skill", ""))
			check(sk == "attack" or Database.skills.has(sk), "ennemi %s : compétence connue (%s)" % [id, sk])
		for d: Variant in def.get("drops", []):
			check(Database.items.has(str((d as Dictionary).get("item", ""))), "ennemi %s : butin connu" % id)
		var sp: Dictionary = def.get("sprite", {})
		check((sp.has("monster") and MonsterPainter.has(str(sp["monster"]))) or Database.characters.has(str(sp.get("character", ""))), "ennemi %s : sprite" % id)
	for id: String in Database.encounters:
		var enc := Database.get_encounter(id)
		_check_enemy_list("rencontre " + id, enc.get("enemies"))
		check(Database.arenas.has(str(enc.get("arena", ""))), "rencontre %s : arène connue" % id)
		for m: Variant in enc.get("party", []):
			check(not Rules.battle_def(str((m as Dictionary).get("id", ""))).is_empty(), "rencontre %s : équipe imposée valide" % id)
		for item: String in enc.get("inventory", {}):
			check(Database.items.has(item), "rencontre %s : objet connu (%s)" % [id, item])
	for id: String in Database.encounter_tables:
		var table: Dictionary = Database.encounter_tables[id]
		check(Database.arenas.has(str(table.get("arena", ""))), "table %s : arène connue" % id)
		for size in [1, 2, 4]:
			check(not Database.roll_encounter(id, size).is_empty(), "table %s : une rencontre possible pour %d personnage(s)" % [id, size])
		for g: Variant in table.get("groups", []):
			_check_enemy_list("table " + id, (g as Dictionary).get("enemies"))
	for id: String in Database.arenas:
		var arena := Database.get_arena(id)
		check(Database.ambiances.has(str(arena.get("ambiance", ""))), "arène %s : ambiance connue" % id)
	for id in Database.list_maps():
		for o: Dictionary in Database.get_map(id).get("objects", []):
			if str(o.get("type", "")) == "encounter_zone":
				check(Database.encounter_tables.has(str(o.get("table", ""))), "carte %s : table de rencontres connue" % id)
			if str(o.get("type", "")) == "monster":
				check(Database.enemies.has(str(o.get("id", ""))), "carte %s : monstre connu" % id)
	print("  %d compétences, %d objets, %d états, %d ennemis, %d rencontres, %d tables" % [
		Database.skills.size(), Database.items.size(), Database.statuses.size(), Database.enemies.size(),
		Database.encounters.size(), Database.encounter_tables.size()])


# ------------------------------------------------------------------- sprites

func _ascii(img: Image, region: Rect2i) -> void:
	var palette := {}
	var glyphs := ".#ox+=*%@abcdefghijklmnopqrstuvwyz0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
	for y in region.size.y:
		var line := ""
		for x in region.size.x:
			var c := img.get_pixel(region.position.x + x, region.position.y + y)
			if c.a < 0.5:
				line += " "
				continue
			var key := c.to_html(false)
			if not palette.has(key):
				palette[key] = glyphs[mini(palette.size(), glyphs.length() - 1)]
			line += str(palette[key])
		print("    |" + line + "|")


func _test_sprites() -> void:
	for id: String in Database.characters:
		var sheet := Sprites.character(id)
		var img: Image = sheet["image"]
		check(img.get_width() == 352 and img.get_height() == 192, "planche de %s : 352 x 192" % id)
		var fw: int = sheet["frame_w"]
		var fh: int = sheet["frame_h"]
		check((sheet["walk"] as Array).size() >= 4, "planche de %s : au moins quatre poses de marche" % id)
		check((sheet["idle_seq"] as Array).size() > 1, "planche de %s : repos animé" % id)
		for pose_name: String in ["attack", "cast", "hit", "ko"]:
			check((sheet["poses"] as Dictionary).has(pose_name), "planche de %s : pose %s" % [id, pose_name])
		# les quatre poses de marche sont toutes différentes, dans chaque direction
		for row in 4:
			var seen := {}
			for col: int in sheet["walk"]:
				seen[img.get_region(Rect2i(col * fw, row * fh, fw, fh)).get_data()] = true
			check(seen.size() == 4, "planche de %s : quatre poses de marche distinctes, ligne %d" % [id, row])
		var pimg: Image = Sprites.portrait(id).get_image()
		check(pimg.get_width() == 48 and pimg.get_height() == 48, "portrait de %s : 48 x 48" % id)
		for row in 4:
			for col in int(sheet["columns"]):
				var b := Sprites.PA.opaque_bounds(img, Rect2i(col * fw, row * fh, fw, fh))
				check(b.size.y > 12 and b.size.y < fh and b.position.y > 0, "planche de %s : case %d,%d non vide et dans le cadre" % [id, col, row])
				check(b.position.x > 0 and b.end.x < fw, "planche de %s : case %d,%d ne touche pas les bords" % [id, col, row])
		check(Sprites.portrait(id) != null, "portrait de %s" % id)
	for kind: String in MonsterPainter.SIZES:
		var sheet := Sprites.monster(kind)
		var mimg: Image = sheet["image"]
		for col in int(sheet["columns"]):
			var b := Sprites.PA.opaque_bounds(mimg, Rect2i(col * int(sheet["frame_w"]), 0, int(sheet["frame_w"]), int(sheet["frame_h"])))
			check(b.size.x > 10 and b.size.y > 10 and b.size.y <= int(sheet["frame_h"]), "monstre %s : pose %d dessinée" % [kind, col])
		check(Sprites.battler_icon({"monster": kind}) != null, "monstre %s : vignette" % kind)
	for kind: String in ["tree", "bush", "flowers", "grass", "wheat", "wilted", "barrel", "sign", "rock", "bollard", "monument", "boat", "shelf", "window"]:
		check(Sprites.prop(kind, 0).get_width() > 4, "sprite de décor %s" % kind)
	for kind: String in ["grass", "path", "cobble", "planks", "floor", "wood", "soil", "plaster", "brick", "stone", "iron", "interior_wall", "roof_rouge", "roof_vert", "roof_ardoise", "roof_chaume"]:
		var t := Sprites.tile_image(kind)
		check(t.get_width() == 48 and t.get_pixel(0, 0) != Color.MAGENTA, "texture %s" % kind)
	if verbose:
		for id: String in ["glandoulf", "sam", "pepine"]:
			var img: Image = Sprites.character(id)["image"]
			print("  %s : face, pas de côté, dos" % id)
			_ascii(img, Rect2i(0, 0, 32, 48))
			_ascii(img, Rect2i(32, 48, 32, 48))
			_ascii(img, Rect2i(0, 144, 32, 48))
		for kind: String in MonsterPainter.SIZES:
			print("  monstre : ", kind)
			var size: Vector2i = MonsterPainter.SIZES[kind]
			_ascii(Sprites.monster(kind)["image"], Rect2i(0, 0, size.x, size.y))
		for id: String in ["isidur", "sauron"]:
			print("  %s : face, côté" % id)
			_ascii(Sprites.character(id)["image"], Rect2i(0, 0, 32, 48))
			_ascii(Sprites.character(id)["image"], Rect2i(0, 48, 32, 48))
		print("  bitte d'amarrage / arbre")
		_ascii(Sprites.prop("bollard", 0).get_image(), Rect2i(0, 0, 22, 30))
		_ascii(Sprites.prop("tree", 0).get_image(), Rect2i(0, 0, 72, 100))


# -------------------------------------------------------------------- cartes

func _test_map(id: String, state: Array = [], label: String = "") -> void:
	var map := Database.get_map(id)
	GameState.new_game()
	for f: String in state:
		GameState.set_flag(f)
	var world: Node3D = World.new()
	add_child(world)
	var spawns: Dictionary = map.get("spawns", {})
	check(not spawns.is_empty(), "carte %s : au moins un point d'arrivée" % id)
	var t0 := Time.get_ticks_msec()
	world.setup(id, str(spawns.keys()[0]))
	var build_ms := Time.get_ticks_msec() - t0
	await get_tree().process_frame
	await get_tree().process_frame
	check(world.player != null, "carte %s : joueur créé" % id)
	check(world.camera != null and world.camera.current, "carte %s : caméra active" % id)

	# chaque point d'arrivée est libre et hors de tout passage
	for key: String in spawns:
		var sp: Dictionary = world.spawn_info(key)
		var p: Vector3 = sp["pos"]
		check(world.is_free(Vector2(p.x, p.z), 0.28, world.player), "carte %s : point d'arrivée %s dégagé" % [id, key])
		for wp: Dictionary in world.warps:
			var r: Rect2 = wp["rect"]
			check(not r.has_point(Vector2(p.x, p.z)), "carte %s : point d'arrivée %s hors d'un passage" % [id, key])

	# remplissage par diffusion : tout ce que le joueur peut atteindre à pied
	var step := 0.25
	var gw := int(world.grid_w / step) + 1
	var gh := int(world.grid_h / step) + 1
	var seen := PackedByteArray()
	seen.resize(gw * gh)
	var start := Vector2i(int(round(world.player.position.x / step)), int(round(world.player.position.z / step)))
	var queue: Array[Vector2i] = [start]
	seen[start.y * gw + start.x] = 1
	var head := 0
	while head < queue.size():
		var c := queue[head]
		head += 1
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if n.x < 0 or n.y < 0 or n.x >= gw or n.y >= gh or seen[n.y * gw + n.x] != 0:
				continue
			if world.is_free(Vector2(n.x * step, n.y * step), 0.28, world.player):
				seen[n.y * gw + n.x] = 1
				queue.append(n)
	var reachable := func(test: Callable) -> bool:
		for c: Vector2i in queue:
			if test.call(Vector2(c.x * step, c.y * step)):
				return true
		return false
	for it: Dictionary in world.interactables:
		if bool(it.get("gated", false)):
			continue   # vérifié dans _test_gated, une fois l'obstacle levé
		var ip: Vector3 = world.interactable_position(it)
		var reach := float(it["reach"]) - 0.1
		var ok: bool = reachable.call(func(p: Vector2) -> bool: return p.distance_to(Vector2(ip.x, ip.z)) <= reach)
		check(ok, "carte %s : « %s » (%s) atteignable à pied" % [id, str(it["dialogue"]), str(it["label"])])
	for wp: Dictionary in world.warps:
		var r: Rect2 = wp["rect"]
		var ok: bool = reachable.call(func(p: Vector2) -> bool: return r.has_point(p))
		check(ok, "carte %s : passage vers %s atteignable à pied" % [id, str(wp["map"])])
	print("  %s : %d x %d, construite en %d ms, %d PNJ, %d interactions, %d passages, %d cases atteignables" % [
		id if label == "" else "%s (%s)" % [id, label], world.grid_w, world.grid_h, build_ms, world.npcs.size(), world.interactables.size(), world.warps.size(), queue.size()])

	if verbose:
		for ty in world.grid_h:
			var line := ""
			for tx in world.grid_w:
				var ch := " "
				var any := false
				for sy in 4:
					for sx in 4:
						var gx: int = int(tx) * 4 + sx
						var gy: int = int(ty) * 4 + sy
						if seen[gy * gw + gx] != 0:
							any = true
				ch = "." if any else "#"
				for it: Dictionary in world.interactables:
					var ip: Vector3 = world.interactable_position(it)
					if int(ip.x) == tx and int(ip.z) == ty:
						ch = "N" if it.has("node") else "?"
				for wp: Dictionary in world.warps:
					var r: Rect2 = wp["rect"]
					if r.grow(0.3).has_point(Vector2(tx + 0.5, ty + 0.5)):
						ch = "W"
				if int(world.player.position.x) == tx and int(world.player.position.z) == ty:
					ch = "@"
				line += ch
			print("    " + line)
	remove_child(world)
	world.queue_free()
	await get_tree().process_frame


# ----------------------------------------------------------------- dialogues

func _play_through(box: Control, id: String, choice_index: int) -> int:
	var lines := 0
	var done := [false]
	var cb := func() -> void: done[0] = true
	box.finished.connect(cb, CONNECT_ONE_SHOT)
	box.start(id)
	for _i in 400:
		await get_tree().process_frame
		if done[0]:
			break
		if box.waiting:
			box.resume()   # ici, personne ne lance le combat : on passe à la suite
		elif box._choosing:
			var buttons: Array = box._choice_list.get_children()
			var b: Button = buttons[mini(choice_index, buttons.size() - 1)]
			b.pressed.emit()
		elif box._typing:
			box._finish_typing()
		else:
			lines += 1
			box._advance()
	check(done[0], "dialogue %s : se termine" % id)
	return lines


func _test_dialogue_box() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var box: Control = DialogueBox.new()
	layer.add_child(box)
	await get_tree().process_frame
	GameState.new_game()
	var total := 0
	for id: String in Database.dialogues:
		total += await _play_through(box, id, 0)   # première visite
		total += await _play_through(box, id, 1)   # seconde visite (drapeaux posés), autre choix
	check(not box.active and not box.visible, "boîte de dialogue refermée")
	check(GameState.has_flag("intro_vue") and GameState.has_flag("sam_vu"), "les dialogues posent leurs drapeaux")
	print("  %d dialogues joués deux fois, %d répliques affichées" % [Database.dialogues.size(), total])
	layer.queue_free()


# --------------------------------------------------------------- sauvegarde

func _test_save() -> void:
	GameState.new_game()
	GameState.set_flag("test_drapeau")
	GameState.map_id = "auberge"
	GameState.player_pos = [5.5, 6.25]
	GameState.player_facing = "left"
	GameState.playtime = 3725.0
	GameState.inventory = {"potion": 3}
	check(SaveManager.save_game(), "écriture de la sauvegarde")
	check(SaveManager.has_save(), "sauvegarde détectée")
	GameState.new_game()
	check(not GameState.has_flag("test_drapeau"), "nouvelle partie : état remis à zéro")
	check(SaveManager.load_game(), "lecture de la sauvegarde")
	check(GameState.has_flag("test_drapeau"), "drapeau restauré")
	check(GameState.map_id == "auberge", "carte restaurée")
	check(GameState.player_pos.size() == 2 and is_equal_approx(float(GameState.player_pos[0]), 5.5), "position restaurée")
	check(GameState.player_facing == "left", "orientation restaurée")
	check(int(GameState.inventory.get("potion", 0)) == 3, "inventaire restauré")
	check(GameState.playtime_text() == "1h02", "temps de jeu restauré")
	check(SaveManager.summary().begins_with("Au Bon Mouillage"), "résumé de sauvegarde : " + SaveManager.summary())
	SaveManager.delete_save()
	check(not SaveManager.has_save(), "sauvegarde supprimée")


# -------------------------------------------------------------------- combat

func _fight(encounter: Dictionary, seed_value: int) -> RefCounted:
	var e: RefCounted = BattleEngine.new()
	e.setup(encounter, seed_value)
	var turns := 0
	while str(e.result) == "" and turns < 800:
		turns += 1
		var actor: RefCounted = e.next_actor()
		if actor == null:
			break
		e.start_turn(actor)
		if str(e.result) == "" and bool(e.can_act):
			var action: Dictionary = e.ai_action(actor) if str(actor.side) == "enemy" else e.auto_action(actor)
			e.perform(actor, action)
		if str(e.result) == "":
			e.end_turn(actor)
	e.set_meta("turns", turns)
	return e


func _has_event(events: Array, type: String) -> bool:
	for ev: Dictionary in events:
		if str(ev.get("type", "")) == type:
			return true
	return false


func _test_engine() -> void:
	# progression
	GameState.new_game()
	check(Rules.xp_to_next(1) == 16 and Rules.xp_to_next(2) > Rules.xp_to_next(1), "seuils d'expérience croissants")
	check(Rules.skills_at("glandoulf", 1).has("etincelle") and not Rules.skills_at("glandoulf", 1).has("tonnerre"), "compétences selon le niveau")
	var up := GameState.grant_xp("glandoulf", 16)
	check(int(up.get("to", 0)) == 2 and (up.get("skills", []) as Array).has("Petit somme"), "montée de niveau et compétence apprise")
	check(int(GameState.member("glandoulf")["hp"]) == int(Rules.stats_at("glandoulf", 2)["hp"]), "monter de niveau rend tous les PV")
	check(GameState.grant_xp("glandoulf", 1).is_empty(), "pas de montée sans assez d'expérience")

	# faiblesse, bouclier, ébranlement
	GameState.new_game()
	var e: RefCounted = BattleEngine.new()
	e.setup({"enemies": ["limace_molle"], "arena": "pre"}, 3)
	var g: RefCounted = e.party[0]
	var slug: RefCounted = e.enemies[0]
	slug.base["hp"] = 9999
	slug.hp = 9999
	check(e.known_weak(slug).is_empty(), "faiblesses inconnues au départ")
	var ev: Array = e.perform(g, {"type": "skill", "id": "etincelle", "target": slug})
	check(_has_event(ev, "damage") and int(slug.hp) < 9999, "une compétence inflige des dégâts")
	check(int(g.mp) == int(g.max_mp()) - 3, "elle coûte du mana")
	check(e.known_weak(slug).has("feu"), "la faiblesse touchée est révélée")
	check(int(slug.shield) == 1, "le bouclier perd un point")
	ev = e.perform(g, {"type": "skill", "id": "etincelle", "target": slug})
	check(_has_event(ev, "break") and slug.has_status("ebranle"), "bouclier à zéro : l'ennemi est ébranlé")
	e.start_turn(slug)
	check(not bool(e.can_act), "un ennemi ébranlé passe son tour")
	e.end_turn(slug)
	check(not slug.has_status("ebranle") and int(slug.shield) == int(slug.shield_max), "il se ressaisit et retrouve son bouclier")
	var hp0 := int(slug.hp)
	e.perform(g, {"type": "attack", "target": slug})
	var plain := hp0 - int(slug.hp)
	check(plain > 0 and not e.known_weak(slug).has("contondant"), "l'attaque de base touche sans révéler de fausse faiblesse")
	g.mp = 0
	check(not e.can_use_skill(g, "etincelle"), "pas de compétence sans mana")

	# états : poison, sommeil, réveil
	g.statuses["poison"] = {"turns": 2, "fresh": false}
	hp0 = int(g.hp)
	e.start_turn(g)
	check(int(g.hp) == hp0 - 3 and bool(e.can_act), "le poison ronge 8 % des PV en début de tour")
	e.end_turn(g)
	e.start_turn(g)
	e.end_turn(g)
	check(not g.has_status("poison"), "le poison s'estompe")
	g.statuses["sommeil"] = {"turns": 2, "fresh": false}
	e.start_turn(g)
	check(not bool(e.can_act), "un personnage endormi passe son tour")
	ev = e.perform(slug, {"type": "attack", "target": g})
	check(_has_event(ev, "wake") and not g.has_status("sommeil"), "un coup le réveille")
	g.statuses["ramolli"] = {"turns": 3, "fresh": false}
	check(g.stat("atk") < float(g.base["atk"]), "Ramolli réduit l'attaque")
	g.statuses.clear()

	# défense, objets
	g.hp = g.max_hp()
	e.perform(g, {"type": "defend"})
	check(bool(g.defending) and int(g.mp) > 0, "se défendre rend un peu de mana")
	g.hp = 5
	var tisanes := int(e.inventory.get("tisane", 0))
	e.perform(g, {"type": "item", "id": "tisane", "target": g})
	check(int(g.hp) > 5 and int(e.inventory.get("tisane", 0)) == tisanes - 1, "une tisane soigne et se consomme")

	# victoire : butin appliqué
	slug.hp = 1
	e.perform(g, {"type": "attack", "target": slug})
	check(str(e.result) == "victory", "victoire quand le dernier ennemi tombe")
	var rewards: Dictionary = e.commit()
	check(int(rewards["xp"]) == 6 and int(GameState.member("glandoulf")["xp"]) == 6, "expérience distribuée")
	check(GameState.money == int(rewards["money"]) and GameState.money > 0, "argent gagné")
	check(int(GameState.member("glandoulf")["hp"]) == int(g.hp), "PV conservés après le combat")
	check(int(GameState.item_count("tisane")) >= tisanes - 1, "inventaire mis à jour")
	check((GameState.bestiary.get("limace_molle", []) as Array).has("feu"), "faiblesse retenue pour les combats suivants")

	# petit somme : soin contre un tour de sommeil
	GameState.new_game()
	GameState.member("glandoulf")["level"] = 2
	GameState.add_to_party("pepine")
	GameState.heal_party()
	e = BattleEngine.new()
	e.setup({"enemies": ["guepe_cidre", "guepe_cidre"], "arena": "pre"}, 5)
	g = e.party[0]
	var p: RefCounted = e.party[1]
	check(str(e.enemies[0].name) != str(e.enemies[1].name), "deux ennemis identiques portent des noms distincts")
	g.hp = 10
	e.start_turn(g)
	e.perform(g, {"type": "skill", "id": "petit_somme"})
	e.end_turn(g)
	check(int(g.hp) > 10 and g.has_status("sommeil"), "Petit somme soigne et endort")
	e.start_turn(g)
	check(not bool(e.can_act), "Glandoulf dort au tour suivant")
	e.end_turn(g)
	check(not g.has_status("sommeil"), "puis il se réveille")
	# soin d'un allié, réanimation
	p.hp = 0
	p.statuses.clear()
	check(e.candidates(g, "ally_ko").has(p) and not e.candidates(g, "ally").has(p), "un allié à terre ne peut qu'être relevé")
	e.inventory["racine"] = 1
	e.perform(g, {"type": "item", "id": "racine", "target": p})
	check(p.alive(), "la racine-qui-réveille relève un allié")
	g.hp = 4
	e.perform(p, {"type": "skill", "id": "cataplasme", "target": g})
	check(int(g.hp) > 4, "Pépine soigne un allié")
	# ordre des tours : la guêpe (vitesse 13) joue plus souvent que Glandoulf (vitesse 8)
	var order: Array = e.preview(30)
	var wasp_turns := 0
	var g_turns := 0
	for c: RefCounted in order:
		if c == e.enemies[0]:
			wasp_turns += 1
		elif c == g:
			g_turns += 1
	check(wasp_turns > g_turns and g_turns > 0, "les plus rapides jouent plus souvent (%d contre %d)" % [wasp_turns, g_turns])
	var first: RefCounted = e.next_actor()
	check(first != null and first.alive(), "un combattant vivant prend le tour")
	# défaite : rien n'est conservé
	var before := GameState.to_dict()
	g.hp = 1
	p.hp = 1
	var wasp: RefCounted = e.enemies[0]
	wasp.base["atk"] = 999
	e.perform(wasp, {"type": "attack", "target": g})
	e.perform(wasp, {"type": "attack", "target": p})
	check(str(e.result) == "defeat", "défaite quand toute l'équipe est à terre")
	e.commit()
	check(GameState.to_dict()["roster"] == before["roster"] and GameState.to_dict()["inventory"] == before["inventory"], "une défaite ne change rien à la partie")
	# fuite impossible contre un boss
	e = BattleEngine.new()
	e.setup(Database.get_encounter("grande_baveuse"), 2)
	ev = e.perform(e.party[0], {"type": "flee"})
	check(str(e.result) == "" and not bool(ev[0]["ok"]), "on ne fuit pas un boss")
	# équipe imposée du prologue
	GameState.new_game()
	e = BattleEngine.new()
	e.setup(Database.get_encounter("prologue_sauron"), 1)
	check(bool(e.guest) and e.party.size() == 2 and int(e.party[0].level) == 20, "prologue : Glandoulf et Isidur, niveau 20")
	check((e.party[0].skills as Array).has("bouquet_final"), "prologue : toutes les compétences disponibles")
	ev = e.perform(e.party[0], {"type": "skill", "id": "baillement", "target": e.enemies[0]})
	var immune := false
	for x: Dictionary in ev:
		if str(x.get("type", "")) == "status" and bool(x.get("immune", false)):
			immune = true
	check(immune and e.known_weak(e.enemies[0]).has("torpeur"), "Sauron craint la torpeur mais ne s'endort jamais")


const TEAM := ["glandoulf", "sam", "fripon", "pepine"]


## Une rencontre nommée, avec le Ramollissement de la carte d'où elle est lancée.
const BIBLE_TEAM := ["glandoulf", "sam", "fripon", "pepine", "aragrogne", "legolasse", "gimlette"]
const PASSIVES := ["crit", "element_boost", "status_chance", "heal_boost", "guard", "counter", "regen_mp", "regen_hp", "initiative", "money_bonus", "vs_afflicted", "fury", "immune"]


## Dépense les points de talent d'un personnage : une voie d'abord, le reste dans l'autre.
func _spend(id: String, first: int) -> void:
	var branches: Array = Rules.branches(id)
	if branches.size() != 2:
		return
	for b: Dictionary in [branches[first], branches[1 - first]]:
		for t: Dictionary in Rules.branch_talents(b):
			GameState.learn_talent(id, str(t.get("id", "")))


## Met un personnage seul dans l'équipe, au niveau voulu, avec les talents donnés.
func _solo(ids: Array, level: int, talents: Dictionary = {}) -> void:
	GameState.new_game()
	GameState.party = []
	for id: String in ids:
		GameState.add_to_party(id)
		GameState.member(id)["level"] = level
		for t: String in talents.get(id, []):
			check(GameState.learn_talent(id, t), "talent %s appris par %s" % [t, id])
	GameState.heal_party()


func _find(list: Array, source: String) -> RefCounted:
	for c: RefCounted in list:
		if str(c.source) == source:
			return c
	return null


func _test_talents() -> void:
	# --- les données : deux voies par personnage de la bible, cohérentes avec le reste
	var count := 0
	for id: String in Database.talents:
		check(BIBLE_TEAM.has(id), "talents.json : %s est un membre de l'équipe" % id)
	for id: String in BIBLE_TEAM:
		var ch := Database.get_character(id)
		check(not Rules.battle_def(id).is_empty(), "%s : fiche de combat" % id)
		var branches: Array = Rules.branches(id)
		check(branches.size() == 2, "%s : deux voies de talents" % id)
		var names: Array = ch.get("branches", [])
		var seen := {}
		for i in branches.size():
			var b: Dictionary = branches[i]
			check(i < names.size() and str(names[i]) == str(b.get("name", "")), "%s : la voie « %s » porte le nom de la bible" % [id, str(b.get("name", ""))])
			check(str(b.get("id", "")) != "" and str(b.get("desc", "")) != "", "%s : voie décrite" % id)
			var list: Array = Rules.branch_talents(b)
			check(list.size() >= 3, "%s : au moins trois talents par voie" % id)
			for t: Dictionary in list:
				var tid := str(t.get("id", ""))
				var what := "talent %s/%s" % [id, tid]
				count += 1
				check(tid != "" and not seen.has(tid), "%s : identifiant unique" % what)
				seen[tid] = true
				check(str(t.get("name", "")) != "" and str(t.get("desc", "")) != "", "%s : nom et description" % what)
				check(t.has("mods") or t.has("skills") or t.has("passives"), "%s : il apporte quelque chose" % what)
				for key: String in t.get("mods", {}):
					check(Rules.STATS.has(key), "%s : caractéristique connue (%s)" % [what, key])
				for s: Variant in t.get("skills", []):
					check(Database.skills.has(str(s)) and int(Database.get_skill(str(s)).get("cost", 0)) > 0, "%s : compétence connue et payante (%s)" % [what, str(s)])
				var passives: Dictionary = t.get("passives", {})
				for key: String in passives:
					check(PASSIVES.has(key), "%s : effet permanent connu (%s)" % [what, key])
				for s: Variant in passives.get("immune", []):
					check(Database.statuses.has(str(s)), "%s : immunité connue (%s)" % [what, str(s)])
				for s: String in passives.get("status_chance", {}):
					check(s == "all" or Database.statuses.has(s), "%s : état connu (%s)" % [what, s])
				for s: String in passives.get("element_boost", {}):
					check(Database.elements.has(s), "%s : élément connu (%s)" % [what, s])
	print("  %d talents pour %d personnages" % [count, BIBLE_TEAM.size()])

	# --- les points : un par niveau, dépensés dans l'ordre de chaque voie
	GameState.new_game()
	check(GameState.talent_points("glandoulf") == 0, "niveau 1 : aucun point de talent")
	check(not GameState.learn_talent("glandoulf", "meche_courte"), "niveau 1 : rien à apprendre")
	var up := GameState.grant_xp("glandoulf", Rules.xp_to_next(1))
	check(int(up.get("to", 0)) == 2 and int(up.get("points", 0)) == 1 and GameState.talent_points("glandoulf") == 1, "monter au niveau 2 donne un point de talent")
	check(GameState.talent_state("glandoulf", "petarade_t") == "locked" and not GameState.learn_talent("glandoulf", "petarade_t"), "le deuxième talent d'une voie attend le premier")
	check(GameState.learn_talent("glandoulf", "meche_courte") and GameState.talent_points("glandoulf") == 0, "premier talent appris, point dépensé")
	check(GameState.talent_state("glandoulf", "petarade_t") == "poor" and not GameState.learn_talent("glandoulf", "petarade_t"), "sans point, rien ne s'apprend")
	check(not GameState.learn_talent("glandoulf", "meche_courte"), "un talent ne s'apprend qu'une fois")
	check(not GameState.learn_talent("glandoulf", "cuir_epais"), "on n'apprend pas le talent d'un autre")
	check(GameState.specialization("glandoulf") == "pyrotechnicien" and GameState.specialization_name("glandoulf") == "Pyrotechnicien", "la voie suivie est reconnue")
	GameState.member("glandoulf")["level"] = 7
	check(GameState.talent_points("glandoulf") == 5, "niveau 7 : six points en tout")
	var mag := int(GameState.member_stats("glandoulf")["mag"])
	check(GameState.learn_talent("glandoulf", "petarade_t") and GameState.learn_talent("glandoulf", "poudre_seche"), "suite de la voie")
	check(GameState.talent_points("glandoulf") == 2, "les talents avancés coûtent deux points")
	check(int(GameState.member_stats("glandoulf")["mag"]) == mag + 3, "un talent peut augmenter une caractéristique")
	check((GameState.member_skills("glandoulf") as Array).has("petarade") and not (Rules.skills_at("glandoulf", 7) as Array).has("petarade"), "un talent peut donner une compétence")
	var e: RefCounted = BattleEngine.new()
	e.setup({"enemies": ["limace_molle"]}, 5)
	var g: RefCounted = e.party[0]
	check((g.skills as Array).has("petarade") and int(g.base["mag"]) == mag + 3, "le combat tient compte des talents")
	check(is_equal_approx(g.passive("crit"), 0.08) and is_equal_approx(g.passive("element_boost", "feu"), 0.15) and is_zero_approx(g.passive("counter")), "les effets permanents arrivent en combat")

	# --- sauvegarde
	var saved: Variant = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.new_game()
	check(saved is Dictionary and GameState.from_dict(saved), "sauvegarde relue")
	check(GameState.has_talent("glandoulf", "poudre_seche") and GameState.talent_points("glandoulf") == 2, "les talents survivent à la sauvegarde")
	(saved["roster"]["glandoulf"]["talents"] as Array).append("talent_disparu")
	check(GameState.from_dict(saved) and (GameState.talents_of("glandoulf") as Array).size() == 3, "un talent inconnu dans une sauvegarde est ignoré")
	saved["roster"]["glandoulf"]["level"] = 2
	check(GameState.from_dict(saved) and (GameState.talents_of("glandoulf") as Array).is_empty() and GameState.talent_points("glandoulf") == 1, "un compte de points impossible est remis à zéro")
	(saved["roster"]["glandoulf"] as Dictionary).erase("talents")
	check(GameState.from_dict(saved) and GameState.talent_points("glandoulf") == 1, "une sauvegarde d'avant les talents se charge")
	GameState.member("glandoulf")["level"] = 7
	_spend("glandoulf", 1)
	check(GameState.specialization("glandoulf") == "maitre_sieste" and GameState.talent_points("glandoulf") == 0, "une voie complète au niveau 7")
	check(GameState.reset_talents("glandoulf") == 6 and GameState.talent_points("glandoulf") == 6 and GameState.specialization("glandoulf") == "", "tout oublier rend tous les points")
	check(int(GameState.member("glandoulf")["hp"]) <= int(GameState.member_stats("glandoulf")["hp"]), "après l'oubli, les PV ne dépassent pas le maximum")

	# --- une recrue arrive avec des points à dépenser
	GameState.new_game()
	GameState.member("glandoulf")["level"] = 4
	GameState.add_to_party("sam", true)
	check(GameState.talent_points("sam") == 2 and GameState.party_talent_points() == 5, "une recrue de niveau 3 arrive avec deux points")
	check(GameState.party_summary().contains("5 points de talent"), "le menu de pause signale les points à dépenser")

	# --- les effets en combat
	var hits: Array = []
	for talents: Dictionary in [{}, {"glandoulf": ["meche_courte"]}]:
		_solo(["glandoulf"], 7, talents)
		e = BattleEngine.new()
		e.setup({"enemies": ["grande_baveuse"]}, 9)
		for ev: Dictionary in e.perform(e.party[0], {"type": "skill", "id": "etincelle", "target": e.enemies[0]}):
			if str(ev.get("type", "")) == "damage":
				hits.append(int(ev["amount"]))
	check(hits.size() == 2 and int(hits[1]) > int(hits[0]), "Mèche courte : le feu frappe plus fort (%s)" % str(hits))

	_solo(["glandoulf"], 3, {"glandoulf": ["sommeil_reparateur"]})
	e = BattleEngine.new()
	e.setup({"enemies": ["limace_molle"]}, 3)
	g = e.party[0]
	g.mp = 0
	g.statuses["sommeil"] = {"turns": 2, "fresh": false}
	var events: Array = e.start_turn(g)
	check(int(g.mp) == 1 and _has_event(events, "mana") and not bool(e.can_act), "Sommeil réparateur : un PM par tour, même endormi")

	_solo(["glandoulf", "fripon"], 3, {"fripon": ["doigts_de_fee", "pieds_legers"]})
	e = BattleEngine.new()
	e.setup({"enemies": ["grande_baveuse"]}, 3)
	var f := _find(e.party, "fripon")
	var boss: RefCounted = e.enemies[0]
	check(is_equal_approx(float(f.wait), 500.0 / float(f.speed())), "Pieds légers : Fripon prend de l'avance au début du combat")
	check(e.next_actor() == f, "Pieds légers : Fripon joue le premier")
	f.wait = 0.0
	events = e.perform(f, {"type": "skill", "id": "fauche", "target": boss})
	var expected := maxi(1, int(round(int(boss.money) * 0.5)))
	check(_has_event(events, "steal") and int(e.stolen) == expected and expected > 0, "Fauche : vole la moitié des écus de l'adversaire (%d)" % int(e.stolen))
	f.mp = f.max_mp()
	e.perform(f, {"type": "skill", "id": "fauche", "target": boss})
	check(int(e.stolen) == expected, "Fauche : une seule fois par adversaire")
	var purse := GameState.money
	boss.hp = 0
	e._check_end()
	var rewards: Dictionary = e.commit()
	check(str(e.result) == "victory" and int(rewards["money"]) == int(boss.money) + expected and GameState.money == purse + int(rewards["money"]), "Fauche : les écus volés s'ajoutent au butin")

	_solo(["glandoulf", "sam"], 7, {"sam": ["cuir_epais", "viens_y_voir_t", "fonte_emaillee", "retour_de_poele"]})
	e = BattleEngine.new()
	e.setup({"enemies": ["grande_baveuse"]}, 4)
	var sam := _find(e.party, "sam")
	boss = e.enemies[0]
	check(is_equal_approx(sam.passive("guard"), 0.12) and is_equal_approx(sam.passive("counter"), 0.35), "Poêle de Fer : garde et riposte en place")
	e.perform(sam, {"type": "skill", "id": "viens_y_voir"})
	check(sam.has_status("provocation"), "Viens-y voir : Sam est provocateur")
	var aimed := 0
	for i in 20:
		if e.ai_action(boss).get("target") == sam:
			aimed += 1
	check(aimed == 20, "Viens-y voir : l'adversaire vise toujours Sam (%d/20)" % aimed)
	var counters := 0
	for i in 40:
		sam.hp = sam.max_hp()
		boss.hp = boss.max_hp()
		var hp_before := int(boss.hp)
		events = e.perform(boss, {"type": "attack", "target": sam})
		if _has_event(events, "counter"):
			counters += 1
			check(int(boss.hp) < hp_before, "Retour de poêle : la riposte fait mal")
	check(counters >= 5 and counters <= 25, "Retour de poêle : Sam riposte environ une fois sur trois (%d/40)" % counters)

	_solo(["glandoulf", "pepine"], 7, {"pepine": ["tabac_de_caractere", "nuage_tonique_t", "nuage_acre_t", "brouillard_epais_t"]})
	e = BattleEngine.new()
	e.setup({"enemies": ["grande_baveuse"]}, 6)
	var pepine := _find(e.party, "pepine")
	boss = e.enemies[0]
	e.perform(pepine, {"type": "skill", "id": "brouillard_epais"})
	check(pepine.has_status("enfume") and e.party[0].has_status("enfume"), "Brouillard épais : toute l'équipe est enfumée")
	var misses := 0
	for i in 60:
		pepine.hp = pepine.max_hp()
		if _has_event(e.perform(boss, {"type": "attack", "target": pepine}), "miss"):
			misses += 1
	check(misses >= 8 and misses <= 30, "Brouillard épais : un coup physique sur trois environ rate (%d/60)" % misses)
	pepine.mp = pepine.max_mp()
	e.perform(pepine, {"type": "skill", "id": "nuage_acre"})
	var def_before := float(boss.base.get("def", 0))
	boss.statuses["demoralise"] = {"turns": 3, "fresh": false}
	check(float(boss.stat("def")) < def_before or def_before == 0.0, "Démoralisé : défense réduite")

	_solo(["gimlette"], 7, {"gimlette": ["crane_de_morbier", "meme_pas_mal"]})
	e = BattleEngine.new()
	e.setup({"enemies": ["limace_molle"]}, 2)
	check((e.party[0].immune as Array).has("sonne"), "Même pas mal : un talent peut immuniser contre un état")

	# --- chaque personnage peut aller au bout de chacune de ses voies et s'en servir en combat
	for id: String in BIBLE_TEAM:
		for first in 2:
			_solo([id], 13)
			_spend(id, first)
			check(GameState.talent_points(id) == 0 and (GameState.talents_of(id) as Array).size() == 8, "%s : douze points suffisent pour tout apprendre" % id)
			var fight := _fight({"enemies": ["limace_molle", "guepe_cidre"]}, 40 + first)
			check(str(fight.result) == "victory", "%s, tous talents appris : combat mené à son terme" % id)
			# Chaque compétence de talent se lance sans erreur.
			GameState.heal_party()
			var probe: RefCounted = BattleEngine.new()
			probe.setup({"enemies": ["grande_baveuse"]}, 60 + first)
			var me: RefCounted = probe.party[0]
			for s: String in me.skills:
				me.mp = me.max_mp()
				me.hp = me.max_hp()
				probe.enemies[0].hp = probe.enemies[0].max_hp()
				var out: Array = probe.perform(me, {"type": "skill", "id": s})
				check(_has_event(out, "cast"), "%s : %s se lance" % [id, s])
	GameState.new_game()


func _soft(encounter_id: String, softness: float) -> Dictionary:
	var enc := Database.get_encounter(encounter_id).duplicate(true)
	enc["ramollissement"] = softness
	return enc


func _test_balance() -> void:
	var cases := [
		["prologue (Glandoulf et Isidur, niv. 20)", ["glandoulf"], 1, Database.get_encounter("prologue_sauron"), 0.9],
		["seul niv. 1 contre une limace", ["glandoulf"], 1, {"enemies": ["limace_molle"]}, 0.9],
		["seul niv. 1 contre deux limaces", ["glandoulf"], 1, {"enemies": ["limace_molle", "limace_molle"]}, 0.5],
		["seul niv. 1 contre deux guêpes", ["glandoulf"], 1, {"enemies": ["guepe_cidre", "guepe_cidre"]}, 0.4],
		["seul niv. 1 contre un épouvantail", ["glandoulf"], 1, {"enemies": ["epouvantail_avachi"]}, 0.4],
		["à deux niv. 2 contre trois guêpes", ["glandoulf", "pepine"], 2, {"enemies": ["guepe_cidre", "guepe_cidre", "guepe_cidre"]}, 0.5],
		["à deux niv. 3 contre épouvantail et limaces", ["glandoulf", "pepine"], 3, {"enemies": ["epouvantail_avachi", "limace_molle", "limace_molle"]}, 0.5],
		["à deux niv. 4 contre la Grande Baveuse", ["glandoulf", "pepine"], 4, Database.get_encounter("grande_baveuse"), 0.5],
		["à quatre niv. 3 contre la Grande Baveuse", ["glandoulf", "sam", "fripon", "pepine"], 3, Database.get_encounter("grande_baveuse"), 0.8],
		# Étape 5 : les alentours de Bittebourg, la Fête et la route de Brie.
		["à deux niv. 3 contre un sanglier (bois)", ["glandoulf", "pepine"], 3, {"enemies": ["sanglier_flapi"], "ramollissement": 0.2}, 0.8],
		["à quatre niv. 4 contre sanglier et frelon", TEAM, 4, {"enemies": ["sanglier_flapi", "frelon_bois"], "ramollissement": 0.2}, 0.9],
		["à quatre niv. 4 contre sanglier et amanite", TEAM, 4, {"enemies": ["sanglier_flapi", "amanite_molle"], "ramollissement": 0.2}, 0.9],
		["à quatre niv. 4 contre le Vieux Solitaire", TEAM, 4, _soft("vieux_solitaire", 0.2), 0.8],
		["à quatre niv. 5 contre le Vieux Solitaire", TEAM, 5, _soft("vieux_solitaire", 0.2), 0.85],
		["à quatre niv. 5 contre grenouille et sangsue", TEAM, 5, {"enemies": ["grenouille_bouffie", "sangsue_roseaux"], "ramollissement": 0.2}, 0.9],
		["à quatre niv. 5 contre follet, grenouille, sangsue", TEAM, 5, {"enemies": ["feu_follet", "grenouille_bouffie", "sangsue_roseaux"], "ramollissement": 0.2}, 0.9],
		["à quatre niv. 5 contre Monseigneur", TEAM, 5, _soft("crapaud_buffle", 0.2), 0.8],
		["à quatre niv. 6 contre Monseigneur", TEAM, 6, _soft("crapaud_buffle", 0.2), 0.9],
		["à quatre niv. 6 contre les Morfales du quai", TEAM, 6, Database.get_encounter("morfales_quai"), 0.9],
		["à quatre niv. 6 contre les Morfales de l'auberge", TEAM, 6, Database.get_encounter("morfales_auberge"), 0.9],
		["à quatre niv. 5 contre le Naze", TEAM, 5, Database.get_encounter("naze"), 0.0],
		# Depuis l'étape 3 le Naze est réglé pour une équipe qui dépense ses points de talent
		# (voir plus bas) ; sans aucun talent il reste faisable, mais plus serré.
		["à quatre niv. 6 contre le Naze", TEAM, 6, Database.get_encounter("naze"), 0.5],
		["à quatre niv. 7 contre le Naze", TEAM, 7, Database.get_encounter("naze"), 0.85],
		["à quatre niv. 7 contre le péage de la route", TEAM, 7, _soft("morfales_route", 0.15), 0.9],
		["à quatre niv. 7 contre deux Morfales (route)", TEAM, 7, {"enemies": ["morfale_eclaireur", "morfale_eclaireur"], "ramollissement": 0.15}, 0.9],
		# Étape 3 : les mêmes combats avec les points de talent dépensés (dernier chiffre : 0 = première voie d'abord, 1 = seconde).
		["talents A, à deux niv. 3 contre épouvantail et limaces", ["glandoulf", "pepine"], 3, {"enemies": ["epouvantail_avachi", "limace_molle", "limace_molle"]}, 0.5, 0],
		["talents A, à deux niv. 4 contre la Grande Baveuse", ["glandoulf", "pepine"], 4, Database.get_encounter("grande_baveuse"), 0.5, 0],
		["talents A, à quatre niv. 4 contre le Vieux Solitaire", TEAM, 4, _soft("vieux_solitaire", 0.2), 0.8, 0],
		["talents B, à quatre niv. 4 contre le Vieux Solitaire", TEAM, 4, _soft("vieux_solitaire", 0.2), 0.8, 1],
		["talents A, à quatre niv. 5 contre Monseigneur", TEAM, 5, _soft("crapaud_buffle", 0.2), 0.8, 0],
		["talents B, à quatre niv. 5 contre Monseigneur", TEAM, 5, _soft("crapaud_buffle", 0.2), 0.8, 1],
		["talents A, à quatre niv. 6 contre les Morfales du quai", TEAM, 6, Database.get_encounter("morfales_quai"), 0.9, 0],
		["talents A, à quatre niv. 5 contre le Naze", TEAM, 5, Database.get_encounter("naze"), 0.0, 0],
		["talents B, à quatre niv. 5 contre le Naze", TEAM, 5, Database.get_encounter("naze"), 0.0, 1],
		["talents A, à quatre niv. 6 contre le Naze", TEAM, 6, Database.get_encounter("naze"), 0.9, 0],
		["talents B, à quatre niv. 6 contre le Naze", TEAM, 6, Database.get_encounter("naze"), 0.9, 1],
		["talents A, à quatre niv. 7 contre le Naze", TEAM, 7, Database.get_encounter("naze"), 0.95, 0],
		["talents A, à quatre niv. 7 contre le péage de la route", TEAM, 7, _soft("morfales_route", 0.15), 0.9, 0],
	]
	for case: Array in cases:
		var wins := 0
		var turns := 0
		var left := 0.0   # part des PV qui reste à l'équipe après une victoire
		var runs := 40
		for s in runs:
			GameState.new_game()
			GameState.party = []
			for id: String in case[1]:
				GameState.add_to_party(id)
				GameState.member(id)["level"] = int(case[2])
				if case.size() > 5:
					_spend(id, int(case[5]))
			GameState.heal_party()
			var e := _fight(case[3], 100 + s)
			check(str(e.result) != "", "%s : le combat se termine" % str(case[0]))
			turns += int(e.get_meta("turns"))
			if str(e.result) == "victory":
				wins += 1
				var hp := 0.0
				for c: RefCounted in e.party:
					hp += float(c.hp) / float(c.max_hp())
				left += hp / maxf(1.0, float((e.party as Array).size()))
		var rate := float(wins) / runs
		check(rate >= float(case[4]), "%s : %d %% de victoires en jeu automatique (attendu : au moins %d %%)" % [str(case[0]), int(rate * 100.0), int(float(case[4]) * 100.0)])
		print("  %-50s %3d %% de victoires, %2d tours, %3d %% des PV restants" % [str(case[0]), int(rate * 100.0), turns / runs, int(100.0 * left / maxf(1.0, float(wins)))])
	GameState.new_game()


## Données des animations : tout ce qui se joue en combat a la sienne, et elle est valide.
func _test_animations() -> void:
	var fx: Node3D = BattleFx.new()
	var errors: Array = fx.validate()
	for e: Variant in errors:
		check(false, str(e))
	check(errors.is_empty(), "animations : données valides (%d problème(s))" % errors.size())
	var own := {}
	for id: String in Database.skills:
		own[fx.anim_of(id, Database.get_skill(id))] = true
	check(own.size() == Database.skills.size(), "chaque compétence a une animation à elle (%d pour %d)" % [own.size(), Database.skills.size()])
	var attacks := {}
	for id: String in Database.characters:
		var ch := Database.get_character(id)
		if ch.has("battle"):
			attacks[str((ch["battle"] as Dictionary).get("attack_anim", ""))] = true
	check(attacks.size() >= 7, "les héros ont des attaques de base distinctes (%d)" % attacks.size())
	check(fx.resolve("etincelle", "feu") == "etincelle", "une compétence connue joue son animation")
	check(fx.resolve("competence_future", "feu") == "attaque_feu", "une compétence sans animation prend celle de son élément")
	check(fx.resolve("competence_future", "") == "defaut", "sans élément, animation par défaut")
	for kind: String in FxPainter.KINDS:
		var img: Image = FxPainter.paint(kind)
		var filled := 0
		for y in img.get_height():
			for x in img.get_width():
				if img.get_pixel(x, y).a > 0.5:
					filled += 1
		check(filled >= 4, "sprite d'effet %s : dessiné (%d px)" % [kind, filled])
		check(Sprites.fx(kind) != null, "sprite d'effet %s : accessible par Sprites.fx" % kind)
	fx.free()
	# le moteur de règles annonce l'animation dans l'événement « cast »
	GameState.new_game()
	var eng: RefCounted = BattleEngine.new()
	eng.setup({"enemies": ["limace_molle"], "arena": "pre"}, 3)
	var ev: Array = eng.perform(eng.party[0], {"type": "attack", "target": eng.enemies[0]})
	check(str(ev[0].get("anim", "")) == "coup_de_baton", "attaque de Glandoulf : animation coup_de_baton (%s)" % str(ev[0].get("anim", "")))
	ev = eng.perform(eng.party[0], {"type": "skill", "id": "etincelle", "target": eng.enemies[0]})
	check(str(ev[0].get("anim", "")) == "etincelle", "Étincelle : animation etincelle (%s)" % str(ev[0].get("anim", "")))
	if eng.enemies[0].alive():
		ev = eng.perform(eng.enemies[0], {"type": "attack"})
		check(str(ev[0].get("anim", "")) == "tete_molle", "attaque de la limace : animation tete_molle (%s)" % str(ev[0].get("anim", "")))
	GameState.new_game()


## Joue chaque animation pour de vrai (temps accéléré) : elle doit se voir, se terminer,
## ne rien laisser à l'écran et remettre le lanceur à sa place. Puis un combat entier
## avec les animations, et les poses de coup reçu, de KO et de retour.
func _test_animation_play() -> void:
	GameState.new_game()
	for who: String in ["pepine", "sam"]:
		GameState.add_to_party(who)
	for who: String in GameState.party:
		GameState.member(who)["level"] = 9
	GameState.heal_party()
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui: Control = BattleUI.new()
	layer.add_child(ui)
	await get_tree().process_frame
	var scene: Node3D = BattleScene.new()
	add_child(scene)
	scene.setup({"enemies": ["limace_molle", "sanglier_flapi", "guepe_cidre"], "arena": "pre"}, ui, 5)
	await get_tree().process_frame
	var allies: Array = []
	var foes: Array = []
	for c: RefCounted in scene.engine.party:
		allies.append(scene.actor_of(c))
	for c: RefCounted in scene.engine.enemies:
		foes.append(scene.actor_of(c))
	Engine.time_scale = 12.0
	var played := 0
	var index := 0
	for id: String in Database.animations:
		index += 1
		# une fois sur quatre, c'est un ennemi qui la joue contre l'équipe (effets retournés)
		var from_enemy := index % 4 == 0
		var caster: Node3D = foes[index % foes.size()] if from_enemy else allies[index % allies.size()]
		var targets: Array = allies if from_enemy else foes
		await scene.fx.play(id, caster, targets, "feu")
		var seen: bool = scene.fx.live_count() > 0 or caster.posing()
		var t0 := Time.get_ticks_msec()
		while (scene.fx.live_count() > 0 or caster.posing()) and Time.get_ticks_msec() - t0 < 8000:
			await get_tree().process_frame
		var clean: bool = scene.fx.live_count() == 0 and not caster.posing()
		var back: bool = caster.position.distance_to(caster.home) < 0.01 and absf(caster._body.rotation.z) < 0.001 \
				and caster._body.scale.is_equal_approx(caster._base_scale) and absf(caster._body.position.x) < 0.001
		if not (seen and clean and back):
			check(false, "animation %s : visible %s, nettoyée %s, lanceur en place %s" % [id, str(seen), str(clean), str(back)])
		else:
			played += 1
	check(played == Database.animations.size(), "%d animations jouées et terminées proprement sur %d" % [played, Database.animations.size()])

	# coup reçu, KO d'un ennemi, KO puis retour d'un allié
	var foe: Node3D = foes[0]
	foe.play_hit(true)
	await get_tree().process_frame
	check(absf(foe._body.rotation.z) > 0.0 or absf(foe._body.position.x) > 0.0, "coup reçu : le combattant recule")
	await foe.play_ko()
	check(foe.down and not foe.visible, "KO d'un ennemi : il s'aplatit et disparaît")
	var ally: Node3D = allies[1]
	ally.play_pose("cast", ally.home, 0.5)
	await ally.play_ko()
	check(ally.down and absf(ally._body.rotation.z + PI * 0.5) < 0.01, "KO d'un allié en pleine pose : il reste couché")
	ally.play_revive()
	var t1 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t1 < 400:
		await get_tree().process_frame
	check(not ally.down and absf(ally._body.rotation.z) < 0.001 and absf(ally._body.position.y - ally._hover) < 0.01, "retour d'un allié : debout à sa place")
	ui.close()
	remove_child(scene)
	scene.queue_free()
	await get_tree().process_frame

	# un combat entier joué avec ses animations (et non en mode « sans attente »)
	GameState.heal_party()
	var s: Node3D = BattleScene.new()
	add_child(s)
	s.auto = true
	s.setup({"enemies": ["limace_molle", "guepe_cidre", "champignon_dormeur"], "arena": "pre"}, ui, 11)
	s.run()
	var t2 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t2 < 90000:
		await get_tree().process_frame
		if ui._end_layer.visible:
			ui._on_end("ok" if str(s.engine.result) == "victory" else "title")
		if str(s.outcome) != "":
			break
	check(str(s.outcome) == "victory", "combat animé joué jusqu'au bout (issue : %s)" % str(s.outcome))
	var t3 := Time.get_ticks_msec()
	while s.fx.live_count() > 0 and Time.get_ticks_msec() - t3 < 3000:
		await get_tree().process_frame
	check(s.fx.live_count() == 0, "combat animé : aucun effet ne reste à l'écran")
	Engine.time_scale = 1.0
	ui.close()
	remove_child(s)
	s.queue_free()
	await get_tree().process_frame
	layer.queue_free()
	GameState.new_game()


func _test_battle_scene() -> void:
	GameState.new_game()
	GameState.add_to_party("pepine")
	var layer := CanvasLayer.new()
	add_child(layer)
	var ui: Control = BattleUI.new()
	layer.add_child(ui)
	await get_tree().process_frame

	# un combat joué « à la main » : attaque, puis compétence, puis le reste en automatique
	var scene: Node3D = BattleScene.new()
	add_child(scene)
	scene.fast = true
	scene.setup({"enemies": ["limace_molle", "guepe_cidre"], "arena": "pre"}, ui, 7)
	check(scene.actors.size() == 4 and scene.camera != null and scene.camera.current, "arène construite : 4 combattants, caméra active")
	scene.run()
	var did_attack := false
	var did_skill := false
	var saw_list := false
	for _i in 6000:
		await get_tree().process_frame
		if str(scene.outcome) != "":
			break
		if ui._state == ui.S.ROOT:
			check(ui._root_list.get_child_count() == 5, "menu : cinq actions")
			(ui._root_list.get_child(1 if did_attack and not did_skill else 0) as Button).pressed.emit()
		elif ui._state == ui.S.LIST:
			saw_list = true
			for b: Button in ui._list_items.get_children():
				if not b.disabled:
					b.pressed.emit()
					break
		elif ui._state == ui.S.TARGET:
			var p: Vector2 = scene.screen_point(ui._cands[ui._index], "top")
			check(is_finite(p.x) and is_finite(p.y), "la cible a une position à l'écran")
			if did_attack:
				did_skill = true
			did_attack = true
			ui._confirm_target()
			if did_skill:
				scene.auto = true
	check(did_attack and did_skill and saw_list, "attaque et compétence choisies par les menus")
	check(str(scene.outcome) in ["victory", "title"], "le combat va à son terme (issue : %s)" % str(scene.outcome))
	check(ui._timeline.get_child_count() > 2, "file des tours affichée")
	ui.close()
	remove_child(scene)
	scene.queue_free()

	# écrans de fin
	ui.show_victory({"xp": 12, "money": 4, "drops": {"tisane": 1}, "levelups": [{"name": "Glandoulf", "to": 2, "skills": ["Petit somme"]}]}, false)
	await get_tree().process_frame
	check(ui._end_layer.visible, "écran de victoire affiché")
	ui._on_end("ok")
	await get_tree().process_frame
	check(not ui._end_layer.visible, "écran de victoire refermé")
	ui.show_defeat()
	await get_tree().process_frame
	check(ui._end_layer.visible, "écran de défaite affiché")
	ui._on_end("retry")
	await get_tree().process_frame
	ui.close()

	# chaque rencontre nommée se construit et se joue toute seule, dans son arène
	for id: String in Database.encounters:
		GameState.new_game()
		for who: String in ["pepine", "sam", "fripon"]:
			GameState.add_to_party(who)
		for who: String in GameState.party:
			GameState.member(who)["level"] = 9
		GameState.heal_party()
		var s: Node3D = BattleScene.new()
		add_child(s)
		s.fast = true
		s.auto = true
		if id == "nazes_nuit":
			GameState.add_to_party("aragrogne")
			for who: String in GameState.party:
				GameState.member(who)["level"] = 10
			GameState.heal_party()
		s.setup(Database.get_encounter(id), ui)
		s.run()
		for _i in 6000:
			await get_tree().process_frame
			if str(s.outcome) != "":
				break
		check(str(s.outcome) == "victory", "rencontre %s : jouée jusqu'à la victoire (issue : %s)" % [id, str(s.outcome)])
		ui.close()
		remove_child(s)
		s.queue_free()
		await get_tree().process_frame
	layer.queue_free()
	GameState.new_game()


## Les objets marqués « gated » doivent devenir accessibles une fois l'obstacle scénarisé levé.
func _test_gated(id: String) -> void:
	var flags: Array = []
	var gated := false
	for o: Dictionary in Database.get_map(id).get("objects", []):
		if o.has("unless") and str(o.get("type", "")) != "trigger":
			flags.append(str(o["unless"]))
		if bool(o.get("gated", false)):
			gated = true
	if not gated:
		return
	GameState.new_game()
	for f: String in flags:
		GameState.set_flag(f)
	var world: Node3D = World.new()
	add_child(world)
	world.setup(id, str((Database.get_map(id).get("spawns", {}) as Dictionary).keys()[0]))
	await get_tree().process_frame
	var step := 0.25
	var gw := int(world.grid_w / step) + 1
	var gh := int(world.grid_h / step) + 1
	var seen := PackedByteArray()
	seen.resize(gw * gh)
	var start := Vector2i(int(round(world.player.position.x / step)), int(round(world.player.position.z / step)))
	var queue: Array[Vector2i] = [start]
	seen[start.y * gw + start.x] = 1
	var head := 0
	while head < queue.size():
		var c := queue[head]
		head += 1
		for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n := c + d
			if n.x < 0 or n.y < 0 or n.x >= gw or n.y >= gh or seen[n.y * gw + n.x] != 0:
				continue
			if world.is_free(Vector2(n.x * step, n.y * step), 0.28, world.player):
				seen[n.y * gw + n.x] = 1
				queue.append(n)
	for it: Dictionary in world.interactables:
		if not bool(it.get("gated", false)):
			continue
		var ip: Vector3 = world.interactable_position(it)
		var ok := false
		for c: Vector2i in queue:
			if Vector2(c.x * step, c.y * step).distance_to(Vector2(ip.x, ip.z)) <= float(it["reach"]) - 0.1:
				ok = true
				break
		check(ok, "carte %s : « %s » atteignable une fois l'obstacle levé" % [id, str(it["dialogue"])])
	remove_child(world)
	world.queue_free()
	GameState.new_game()
	await get_tree().process_frame


# ------------------------------------------------- étape 4 : quêtes, objets, argent

func _first_hit(softness: float, firm: bool) -> int:
	GameState.new_game()
	if firm:
		GameState.add_item("tuteur")
		GameState.equip("glandoulf", "tuteur")
	var e: RefCounted = BattleEngine.new()
	e.setup({"enemies": ["limace_molle"], "arena": "pre", "ramollissement": softness}, 4242)
	var events: Array = e.perform(e.party[0], {"type": "attack", "target": e.enemies[0]})
	for ev: Dictionary in events:
		if str(ev.get("type", "")) == "damage":
			return int(ev["amount"])
	return -1


func _test_step4() -> void:
	# données
	check(Database.quests.size() >= 4 and Database.shops.size() >= 1, "quêtes et boutiques chargées")
	for id: String in Database.quests:
		var q := Database.get_quest(id)
		check(str(q.get("name", "")) != "" and str(q.get("desc", "")) != "", "quête %s : nom et description" % id)
		check(str(q.get("start", "")) != "", "quête %s : condition de départ" % id)
		check(q.get("steps") is Array and not (q.get("steps", []) as Array).is_empty(), "quête %s : au moins une étape" % id)
		var r: Variant = q.get("reward", {})
		if r is Dictionary:
			for item: String in r.get("items", {}):
				check(Database.items.has(item), "quête %s : récompense connue (%s)" % [id, item])
	for id: String in Database.shops:
		var shop := Database.get_shop(id)
		check(Database.characters.has(str(shop.get("keeper", ""))), "boutique %s : marchand connu" % id)
		for e: Variant in shop.get("stock", []):
			var item := str((e as Dictionary).get("item", ""))
			check(Database.items.has(item), "boutique %s : article connu (%s)" % [id, item])
			check(int((e as Dictionary).get("price", Database.get_item(item).get("price", 0))) > 0, "boutique %s : prix de %s" % [id, item])
	check(Database.softness(Database.get_map("pre_couche")) > 0.0, "le Pré Couché est touché par le Ramollissement")
	check(Database.softness(Database.get_map("auberge")) == 0.0, "l'auberge est épargnée")

	# conditions
	GameState.new_game()
	check(GameState.check("") and GameState.check("party:glandoulf") and not GameState.check("party:sam"), "conditions : équipe")
	check(GameState.check("item:tisane") and GameState.check("item:tisane:2") and not GameState.check("item:tisane:3"), "conditions : objets")
	check(GameState.check("!inconnu") and not GameState.check("inconnu") and not GameState.check("party:glandoulf & inconnu"), "conditions : négation et « & »")
	GameState.money = 40
	check(GameState.check("money:40") and not GameState.check("money:41"), "conditions : argent")

	# quêtes : départ, étapes, fin, récompense
	var started: Array = []
	var finished: Array = []
	var on_start := func(id: String) -> void: started.append(id)
	var on_done := func(id: String, _reward: Dictionary) -> void: finished.append(id)
	GameState.quest_started.connect(on_start)
	GameState.quest_completed.connect(on_done)
	GameState.new_game()
	check(GameState.quest_state("bittes") == "", "quête pas commencée au départ")
	GameState.set_flag("cales_recues")
	check(GameState.quest_state("bittes") == "active" and started.has("bittes"), "un drapeau fait démarrer la quête")
	for f: String in ["bitte_1", "bitte_2", "bitte_3", "bitte_4"]:
		GameState.set_flag(f)
	check(GameState.quest_state("bittes") == "active", "la quête attend sa dernière étape")
	var before := GameState.money
	GameState.set_flag("bittes_payees")
	check(GameState.quest_state("bittes") == "done" and finished.has("bittes"), "la quête s'achève")
	check(GameState.money == before + 30 and GameState.item_count("noeud_cabestan") == 1, "récompense : écus et objet")
	GameState.set_flag("bittes_payees")
	check(GameState.money == before + 30, "la récompense n'est donnée qu'une fois")
	check(GameState.reward_text({"money": 30, "items": {"tuteur": 1}, "xp": 5}) == "30 écus, Tuteur en noisetier, 5 XP", "texte de récompense")

	# recrue : niveau proche du meneur, équipement de départ, quête accomplie
	GameState.set_flag("sam_vu")
	check(GameState.quest_state("poele") == "active", "la quête de la poêle démarre avec Sam")
	GameState.member("glandoulf")["level"] = 5
	GameState.add_to_party("sam", true)
	check(int(GameState.member("sam")["level"]) == 4, "une recrue arrive un niveau sous le meneur")
	check(GameState.equipped("sam", "weapon") == "poele_gamelle", "Sam arrive avec sa poêle")
	check(GameState.quest_state("poele") == "done", "recruter Sam achève la quête de la poêle")
	GameState.quest_started.disconnect(on_start)
	GameState.quest_completed.disconnect(on_done)

	# équipement
	GameState.new_game()
	var bare := GameState.member_stats("glandoulf")
	GameState.add_item("baton_ferre")
	GameState.add_item("serpette_affutee")
	GameState.add_item("gilet_batelier")
	check(not GameState.can_equip("glandoulf", "serpette_affutee") and not GameState.equip("glandoulf", "serpette_affutee"), "un objet réservé à quelqu'un d'autre est refusé")
	check(not GameState.can_equip("glandoulf", "tisane"), "une tisane ne s'équipe pas")
	check(GameState.equip("glandoulf", "baton_ferre") and GameState.equip("glandoulf", "gilet_batelier"), "équiper depuis le sac")
	var geared := GameState.member_stats("glandoulf")
	check(int(geared["mag"]) == int(bare["mag"]) + 3 and int(geared["atk"]) == int(bare["atk"]) + 2, "le bâton ferré augmente magie et attaque")
	check(int(geared["hp"]) == int(bare["hp"]) + 8 and int(geared["def"]) == int(bare["def"]) + 2, "le gilet augmente PV et défense")
	check(GameState.item_count("baton_ferre") == 0 and GameState.equipped("glandoulf", "weapon") == "baton_ferre", "l'objet équipé quitte le sac")
	var e: RefCounted = BattleEngine.new()
	e.setup({"enemies": ["limace_molle"], "arena": "pre"}, 7)
	check(int(e.party[0].base["mag"]) == int(geared["mag"]) and e.party[0].max_hp() == int(geared["hp"]), "l'équipement compte en combat")
	GameState.heal_party()
	check(int(GameState.member("glandoulf")["hp"]) == int(geared["hp"]), "le repos remplit les PV augmentés")
	check(GameState.unequip("glandoulf", "armor") and GameState.item_count("gilet_batelier") == 1, "retirer remet dans le sac")
	check(int(GameState.member("glandoulf")["hp"]) == int(bare["hp"]), "les PV redescendent au maximum sans le gilet")

	# objets hors combat
	GameState.new_game()
	check(GameState.use_item("tisane", "glandoulf") == "" and GameState.item_count("tisane") == 2, "une tisane n'est pas gâchée sur un bien portant")
	GameState.member("glandoulf")["hp"] = 5
	check(GameState.use_item("tisane", "glandoulf") != "" and int(GameState.member("glandoulf")["hp"]) > 5 and GameState.item_count("tisane") == 1, "tisane hors combat : PV rendus, objet consommé")
	GameState.member("glandoulf")["mp"] = 0
	check(GameState.use_item("cidre", "glandoulf") != "" and int(GameState.member("glandoulf")["mp"]) == 12, "cidre hors combat : mana rendu")
	check(not GameState.usable_outside("racine") and not GameState.usable_outside("cale"), "racine et cale ne s'utilisent pas depuis le sac")

	# argent
	GameState.new_game()
	GameState.money = 20
	check(GameState.buy("tisane", 8) and GameState.money == 12 and GameState.item_count("tisane") == 3, "achat")
	check(not GameState.buy("baton_ferre", 45) and GameState.money == 12 and GameState.item_count("baton_ferre") == 0, "achat refusé sans argent")
	check(GameState.sell("tisane") == 4 and GameState.money == 16 and GameState.item_count("tisane") == 2, "vente à moitié prix")
	GameState.add_item("cale")
	check(GameState.sell("cale") == 0 and GameState.item_count("cale") == 1, "un objet de quête ne se vend pas")

	# Ramollissement
	var plain := _first_hit(0.0, false)
	var soft := _first_hit(0.5, false)
	var firm := _first_hit(0.5, true)
	check(plain > 0 and soft < plain and soft >= int(plain * 0.4), "le Ramollissement émousse les coups physiques (%d -> %d)" % [plain, soft])
	check(firm >= plain, "un tuteur porté annule le Ramollissement (%d)" % firm)
	GameState.new_game()
	var em: RefCounted = BattleEngine.new()
	em.setup({"enemies": ["limace_molle"], "arena": "pre", "ramollissement": 0.5}, 11)
	var spell: Array = em.perform(em.party[0], {"type": "skill", "id": "etincelle", "target": em.enemies[0]})
	var soft_spell := false
	for ev: Dictionary in spell:
		if str(ev.get("type", "")) == "damage" and bool(ev.get("soft", false)):
			soft_spell = true
	check(not soft_spell, "la magie n'est pas touchée par le Ramollissement")
	em.party[0].statuses["galvanise"] = {"turns": 3, "fresh": false}
	check(em.party[0].is_firm(), "Galvanisé : insensible au Ramollissement")
	em.inventory = {"cale": 1, "tuteur": 1, "tisane": 1}
	check(Database.is_consumable("tisane") and not Database.is_consumable("cale") and not Database.is_consumable("tuteur"), "seuls les consommables servent en combat")

	# sauvegarde : quêtes et équipement
	GameState.new_game()
	GameState.set_flag("cales_recues")
	GameState.add_item("baton_ferre")
	GameState.equip("glandoulf", "baton_ferre")
	GameState.map_id = "bittebourg"
	var saved := GameState.to_dict()
	GameState.new_game()
	check(GameState.from_dict(saved), "relecture d'une sauvegarde de l'étape 4")
	check(GameState.quest_state("bittes") == "active" and GameState.equipped("glandoulf", "weapon") == "baton_ferre", "quêtes et équipement restaurés")
	var old := {"map_id": "bittebourg", "flags": {"pepine_vue": true}, "party": ["glandoulf"], "roster": {"glandoulf": {"level": 3, "xp": 4, "hp": 20, "mp": 10}}}
	check(GameState.from_dict(old), "relecture d'une sauvegarde d'avant l'étape 4")
	check(GameState.quest_state("potager") == "active" and GameState.equipped("glandoulf", "weapon") == "", "ancienne sauvegarde : journal reconstitué, équipement vide")
	GameState.new_game()
	print("  %d quêtes, %d boutique(s) ; coup de bâton : %d, ramolli de moitié : %d, avec tuteur : %d" % [Database.quests.size(), Database.shops.size(), plain, soft, firm])


func _test_menus() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var menu: Control = GameMenu.new()
	layer.add_child(menu)
	await get_tree().process_frame
	var closed := [0]
	menu.closed.connect(func() -> void: closed[0] += 1)
	GameState.new_game()
	GameState.set_flag("intro_vue")
	GameState.set_flag("cales_recues")
	GameState.add_item("baton_ferre")
	GameState.add_item("cale")

	menu.open("quests")
	await get_tree().process_frame
	check(menu.visible and (menu.entry_texts() as Array).size() == 2, "journal : deux quêtes en cours")
	check(str(menu._detail.text).contains("Trouver des compagnons"), "journal : le détail de la première quête est affiché")
	menu._on_focus(1)
	check(str(menu._detail.text).contains("Caler les trois bittes"), "journal : la première étape est affichée")
	check(not str(menu._detail.text).contains("Prévenir"), "journal : les étapes suivantes restent cachées")
	menu.close()
	check(closed[0] == 1 and not menu.visible, "journal refermé")

	menu.open("inventory")
	await get_tree().process_frame
	var rows: Array = menu.entry_texts()
	check(rows.size() == 4, "inventaire : quatre sortes d'objets (%d)" % rows.size())
	var baton := -1
	var tisane := -1
	for i in rows.size():
		if str(rows[i]).begins_with("Bâton ferré"):
			baton = i
		if str(rows[i]).begins_with("Tisane"):
			tisane = i
	menu.press(tisane)
	await get_tree().process_frame
	check(str(menu._title.text) == "Pour qui ?", "inventaire : une tisane demande une cible")
	menu.press(0)
	check(GameState.item_count("tisane") == 2 and str(menu._message.text) != "", "inventaire : pas de tisane gâchée, message affiché")
	GameState.member("glandoulf")["hp"] = 3
	menu.press(0)
	await get_tree().process_frame
	check(GameState.item_count("tisane") == 1 and int(GameState.member("glandoulf")["hp"]) > 3, "inventaire : tisane bue depuis le sac")
	menu.go_back()
	await get_tree().process_frame
	check(str(menu._title.text) == "Inventaire", "retour à l'inventaire")
	menu.press(baton)
	await get_tree().process_frame
	check(str(menu._title.text) == "Équiper qui ?", "inventaire : un équipement demande un porteur")
	menu.press(0)
	await get_tree().process_frame
	check(GameState.equipped("glandoulf", "weapon") == "baton_ferre", "inventaire : bâton équipé")
	menu.close()

	menu.open("team")
	await get_tree().process_frame
	check(str(menu._detail.text).contains("Bâton ferré") and str(menu._detail.text).contains("Magie"), "équipe : fiche avec statistiques et équipement")
	menu.press(0)
	await get_tree().process_frame
	check((menu.entry_texts() as Array).size() == 2, "équipe : la fiche propose équipement et talents")
	menu.press(0)
	await get_tree().process_frame
	check((menu.entry_texts() as Array).size() == 3, "équipe : trois emplacements")
	menu.press(0)
	await get_tree().process_frame
	menu.press((menu.entry_texts() as Array).size() - 1)   # « Retirer »
	await get_tree().process_frame
	check(GameState.equipped("glandoulf", "weapon") == "" and GameState.item_count("baton_ferre") == 1, "équipe : arme retirée")
	menu.go_back()
	await get_tree().process_frame
	check(str(menu._title.text) == "Glandoulf", "équipe : Annuler revient à la fiche du personnage")
	GameState.member("glandoulf")["level"] = 3   # deux points de talent
	var asked := [""]
	menu.talents_requested.connect(func(w: String) -> void: asked[0] = w)
	menu.press(1)
	check(asked[0] == "glandoulf", "équipe : la fiche demande l'écran de talents")
	menu.go_back()
	menu.go_back()
	check(not menu.visible, "équipe : Annuler remonte puis referme")

	GameState.money = 30
	menu.open_shop("etal_ursule")
	await get_tree().process_frame
	check((menu.entry_texts() as Array).size() == 3, "boutique : acheter, vendre, partir")
	for offer: Dictionary in menu.shop_offers():
		check(str(offer["item"]) != "poele_gamelle", "boutique : la poêle n'est pas en vente avant l'aveu de Fripon")
	GameState.set_flag("fripon_avoue")
	menu.press(0)
	await get_tree().process_frame
	check(str((menu.shop_offers() as Array)[0]["item"]) == "poele_gamelle", "boutique : la poêle apparaît après l'aveu")
	menu.press(0)
	check(GameState.item_count("poele_gamelle") == 0 and GameState.money == 30, "boutique : achat refusé sans assez d'écus")
	GameState.money = 45
	menu.press(0)
	await get_tree().process_frame
	check(GameState.item_count("poele_gamelle") == 1 and GameState.money == 5 and GameState.has_flag("poele_rachetee"), "boutique : poêle rachetée")
	check(str((menu.shop_offers() as Array)[0]["item"]) != "poele_gamelle", "boutique : la poêle n'est vendue qu'une fois")
	menu.go_back()
	await get_tree().process_frame
	menu.press(1)
	await get_tree().process_frame
	var sell_rows: Array = menu.entry_texts()
	var has_key := false
	for t: Variant in sell_rows:
		if str(t).begins_with("Cale") or str(t).begins_with("Poêle"):
			has_key = true
	check(not has_key and sell_rows.size() >= 2, "boutique : les objets de quête ne se vendent pas")
	var money := GameState.money
	menu.press(0)
	check(GameState.money > money, "boutique : vente")
	menu.close()
	await get_tree().process_frame
	GameState.new_game()
	layer.queue_free()


# ------------------------------------------------------------ écran de talents

func _test_talent_screen() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var screen: Control = TalentScreen.new()
	layer.add_child(screen)
	await get_tree().process_frame
	var closed := [0]
	screen.closed.connect(func() -> void: closed[0] += 1)
	GameState.new_game()
	GameState.member("glandoulf")["level"] = 3   # deux points
	GameState.add_to_party("pepine")
	GameState.member("pepine")["level"] = 2      # un point
	screen.open()
	await get_tree().process_frame
	await get_tree().process_frame
	check(screen.visible and str(screen.who) == "glandoulf", "talents : l'écran s'ouvre sur le premier qui a des points")
	check((screen.tab_ids() as Array).size() == 2, "talents : un onglet par membre de l'équipe")
	check((screen.talent_ids() as Array).size() == 8, "talents : deux voies de quatre talents")
	check(str(screen.points_text()).contains("2"), "talents : points à dépenser affichés (%s)" % str(screen.points_text()))
	var first: Button = screen._nodes["meche_courte"]
	check(str(first.focus_neighbor_bottom) != "" and str(first.focus_neighbor_right) != "", "talents : le curseur passe d'un talent à l'autre")
	check(get_viewport().gui_get_focus_owner() == first, "talents : le curseur démarre sur un talent qu'on peut apprendre")
	screen.focus_talent("petarade_t")
	check(str(screen.detail_text()).contains("PÉTARADE") and str(screen.detail_text()).contains("Il faut d'abord"), "talents : le détail dit ce qui manque")
	check(str(screen.detail_text()).contains("Nouvelle compétence"), "talents : le détail décrit la compétence débloquée")
	screen.press("petarade_t")   # deuxième de sa voie : encore fermé
	check(not GameState.has_talent("glandoulf", "petarade_t") and str(screen.message_text()) != "", "talents : un talent fermé ne s'apprend pas, message affiché")
	screen.press("meche_courte")
	await get_tree().process_frame
	await get_tree().process_frame
	check(GameState.has_talent("glandoulf", "meche_courte") and str(screen.state_of("meche_courte")) == "learned", "talents : talent appris depuis l'écran")
	check(str(screen.points_text()).contains("1"), "talents : le compteur de points baisse")
	check(get_viewport().gui_get_focus_owner() == screen._nodes["meche_courte"], "talents : le curseur reste sur le talent appris")
	check(str(screen.state_of("petarade_t")) == "available", "talents : le suivant de la voie s'ouvre")
	screen.press("sommeil_reparateur")
	await get_tree().process_frame
	check(GameState.has_talent("glandoulf", "sommeil_reparateur") and GameState.talent_points("glandoulf") == 0, "talents : on peut piocher dans les deux voies")
	screen.press("berceuse")
	check(not GameState.has_talent("glandoulf", "berceuse"), "talents : rien ne s'apprend sans point")
	screen.select("pepine")
	await get_tree().process_frame
	check(str(screen.who) == "pepine" and (screen.talent_ids() as Array).has("main_verte"), "talents : changer de personnage change l'arbre")
	screen.press("main_verte")
	await get_tree().process_frame
	check(GameState.has_talent("pepine", "main_verte"), "talents : Pépine apprend un talent")
	screen.select("glandoulf")
	await get_tree().process_frame
	screen.forget()
	await get_tree().process_frame
	check((GameState.talents_of("glandoulf") as Array).is_empty() and GameState.talent_points("glandoulf") == 2, "talents : tout oublier rend les points")
	check(GameState.has_talent("pepine", "main_verte"), "talents : l'oubli ne touche que le personnage affiché")
	screen.forget()
	check(str(screen.message_text()).contains("rien"), "talents : rien à oublier, message affiché")
	screen.close()
	check(closed[0] == 1 and not screen.visible, "talents : écran refermé")
	# Les sept personnages de la bible s'affichent, chaque talent a son détail.
	for id: String in BIBLE_TEAM:
		GameState.new_game()
		GameState.party = []
		GameState.add_to_party(id)
		GameState.member(id)["level"] = 13
		screen.open(id)
		await get_tree().process_frame
		check(str(screen.who) == id and (screen.talent_ids() as Array).size() == 8, "talents : l'arbre de %s s'affiche" % id)
		for tid: String in screen.talent_ids():
			screen.focus_talent(tid)
			check(str(screen.detail_text()).length() > 40, "talents : détail de %s/%s" % [id, tid])
			screen.press(tid)
		await get_tree().process_frame
		check(GameState.talent_points(id) == 0 and (GameState.talents_of(id) as Array).size() == 8, "talents : %s apprend tout depuis l'écran" % id)
		screen.close(true)
	GameState.new_game()
	layer.queue_free()


# ------------------------------------------------------------ déroulé complet

func _wait_idle(main: Node, seconds: float = 40.0) -> void:
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < int(seconds * 1000.0):
		await get_tree().process_frame
		if OS.has_environment("GLAN_TRACE") and Engine.get_process_frames() % 120 == 0:
			print("    [trace] mode %d combat %s occupé %s dialogue %s attente %s carte %s fondu %.2f" % [int(main.mode), str(main.battle != null), str(main.busy), str(main.dialogue.active), str(main.dialogue.waiting), str(main.world != null), main._fade.color.a])
			if main.battle != null:
				print("    [trace] issue « %s » moteur « %s » interface %d" % [str(main.battle.outcome), str(main.battle.engine.result), int(main.battle_ui._state)])
		if main.battle != null or main.busy:
			continue
		if main.menus.visible:
			main.menus.close()   # une boutique ouverte par un dialogue : on la referme
			continue
		if main.dialogue.active:
			if main.dialogue.waiting:
				continue
			if main.dialogue._choosing:
				var buttons: Array = main.dialogue._choice_list.get_children()
				if not buttons.is_empty():
					(buttons[0] as Button).pressed.emit()
			elif main.dialogue._typing:
				main.dialogue._finish_typing()
			else:
				main.dialogue._advance()
		elif main.world == null or main.world.input_enabled or main.mode == main.Mode.TITLE:
			return
	check(false, "le jeu ne revient pas au repos (combat : %s, occupé : %s, dialogue actif : %s, en attente : %s, carte : %s)" % [
		str(main.battle != null), str(main.busy), str(main.dialogue.active), str(main.dialogue.waiting), str(main.world != null)])
	if main.battle != null:
		print("    combat : issue « %s », résultat moteur « %s », état interface %d" % [str(main.battle.outcome), str(main.battle.engine.result), int(main.battle_ui._state)])


func _test_flow() -> void:
	var main: Node = MAIN.instantiate()
	main.auto_battles = true
	add_child(main)
	await _wait_idle(main)
	check(main.mode == main.Mode.TITLE, "écran-titre affiché")
	check(main.title.visible, "menu du titre visible")
	check(main.title._continue.disabled, "« Continuer » grisé sans sauvegarde")
	check(main.world != null and main.world.attract, "village en vitrine derrière le titre")

	main.start_new_game()
	await _wait_idle(main)
	check(main.mode == main.Mode.PLAY, "nouvelle partie lancée")
	check(main.world.map_id == "bittebourg", "départ à Bittebourg")
	check(GameState.has_flag("prologue_vu"), "prologue joué jusqu'au bout")
	check(GameState.has_flag("combat_prologue_sauron"), "combat du prologue gagné")
	check(int(GameState.member("glandoulf")["level"]) == 1 and int(GameState.member("glandoulf")["xp"]) == 0, "le prologue ne donne ni niveau ni expérience")
	check(not GameState.party.has("isidur"), "Isidur ne reste pas dans l'équipe")
	# reprise de l'histoire : Isidur garde l'anneau, il ne le confie plus à Glandoulf
	var prologue_text := FileAccess.get_file_as_string("res://data/dialogues/prologue.json")
	check(prologue_text.contains("Je le garde") and not prologue_text.contains("dans la paume du magicien"), "prologue : Isidur garde l'anneau")
	check(GameState.item_count("tisane") == 2, "inventaire de départ intact après le prologue")
	check(GameState.has_flag("intro_vue"), "scène d'introduction jouée")
	check(main.world.input_enabled and main.world.player.control, "le joueur a la main")

	# déplacement simulé vers la gauche
	var x0: float = main.world.player.position.x
	Input.action_press("move_left")
	for _i in 30:
		await get_tree().process_frame
	Input.action_release("move_left")
	await get_tree().process_frame
	check(main.world.player.position.x < x0 - 0.5, "Glandoulf avance quand on appuie à gauche (%.2f -> %.2f)" % [x0, main.world.player.position.x])
	check(main.world.player.facing == "left", "il regarde à gauche")
	var cam_x: float = main.world.camera.position.x
	check(absf(cam_x - main.world.player.position.x) < 6.0, "la caméra suit")

	# collision : un mur de maison arrête le joueur
	main.world.player.position = Vector3(23.0, 0.0, 12.0)
	Input.action_press("move_up")
	for _i in 90:
		await get_tree().process_frame
		if main.busy:
			break
	Input.action_release("move_up")
	await _wait_idle(main)
	check(main.world.map_id == "auberge", "entrer par la porte de l'auberge change de carte (carte : %s)" % main.world.map_id)
	check(GameState.has_flag("auberge_vue"), "scène d'entrée de l'auberge jouée")
	check(SaveManager.has_save(), "sauvegarde automatique au changement de lieu")

	# interaction avec un PNJ
	var sam: Node3D = null
	for n: Node3D in main.world.npcs:
		if str(n.data.get("id", "")) == "sam":
			sam = n
	check(sam != null, "Sam est dans l'auberge")
	if sam != null:
		main.world.player.position = sam.position + Vector3(-1.0, 0.0, 0.0)
		main.world.player.set_facing("right")
		await get_tree().process_frame
		await get_tree().process_frame
		check(not main.world.focus.is_empty() and str(main.world.focus.get("dialogue", "")) == "sam", "Sam est ciblé quand on lui fait face")
		GameState.flags.erase("sam_vu")
		main._on_interact(main.world.focus)
		await get_tree().process_frame
		check(main.dialogue.active, "le dialogue s'ouvre")
		check(not main.world.input_enabled, "le joueur est figé pendant le dialogue")
		await _wait_idle(main)
		check(GameState.has_flag("sam_vu"), "le dialogue de Sam va au bout")

	# sauvegarde manuelle puis retour au titre et « Continuer »
	main.world.player.position = Vector3(7.0, 0.0, 6.5)
	main.world.player.set_facing("down")
	check(SaveManager.save_game(), "sauvegarde manuelle")
	main.show_title()
	await _wait_idle(main)
	check(main.mode == main.Mode.TITLE, "retour à l'écran-titre")
	check(not main.title._continue.disabled, "« Continuer » disponible")
	main.continue_game()
	await _wait_idle(main)
	check(main.mode == main.Mode.PLAY and main.world.map_id == "auberge", "« Continuer » reprend dans l'auberge")
	check(main.world.player.position.distance_to(Vector3(7.0, 0.0, 6.5)) < 0.05, "position exacte restaurée")
	check(main.world.player.facing == "down", "orientation restaurée")
	check(GameState.has_flag("sam_vu"), "progression restaurée")

	# sortie de l'auberge
	main.world.player.position = Vector3(8.0, 0.0, 9.8)
	Input.action_press("move_down")
	for _i in 90:
		await get_tree().process_frame
		if main.busy:
			break
	Input.action_release("move_down")
	await _wait_idle(main)
	check(main.world.map_id == "bittebourg", "sortir de l'auberge ramène au village")
	check(main.world.player.position.distance_to(Vector3(23.0, 0.0, 11.1)) < 0.6, "arrivée devant la porte de l'auberge")

	print("  [étape] combat lancé depuis la carte")
	# combat lancé depuis la carte : la carte est mise de côté puis remise en place
	GameState.heal_party()
	var field: Node3D = main.world
	var outcome: String = await main.start_battle({"enemies": ["limace_molle"], "arena": "pre"})
	print("  [étape] combat terminé : ", outcome)
	check(outcome == "victory", "combat contre une limace gagné (issue : %s)" % outcome)
	check(main.battle == null and not main.battle_ui.visible, "scène de combat refermée")
	check(main.world == field and field.get_parent() == main and field.camera.current, "carte remise en place après le combat")
	check(int(GameState.member("glandoulf")["xp"]) > 0 or int(GameState.member("glandoulf")["level"]) > 1, "expérience gagnée")
	main.world.set_input(true)

	print("  [étape] Pépine rejoint")
	# Pépine rejoint l'équipe : elle disparaît de la carte
	GameState.set_flag("pepine_vue")
	main.run_dialogue("pepine")
	await _wait_idle(main)
	check(GameState.party.has("pepine"), "Pépine rejoint l'équipe")
	check(GameState.item_count("tisane") >= 3, "elle apporte ses tisanes")
	var still_there := false
	for n: Node3D in main.world.npcs:
		if str(n.data.get("id", "")) == "pepine":
			still_there = true
	check(not still_there, "Pépine n'est plus plantée devant son potager")
	check(main.world.input_enabled, "le joueur a la main après la reconstruction de la carte")

	print("  [étape] le Pré Couché")
	# le Pré Couché : rencontre aléatoire en marchant dans un champ
	GameState.member("glandoulf")["level"] = 8
	GameState.heal_party()
	main.change_map("pre_couche", "ouest")   # sans await : le dialogue d'arrivée est avancé par _wait_idle
	await _wait_idle(main)
	check(main.world.map_id == "pre_couche", "arrivée au Pré Couché")
	check(main.world.encounter_zones.size() == 2, "deux zones de rencontres")
	main.world.player.position = Vector3(12.0, 0.0, 5.0)
	await get_tree().process_frame
	main.world._enc_left = 0.4
	var fought := false
	Input.action_press("move_right")
	for _i in 240:
		await get_tree().process_frame
		if main.battle != null or main.busy:
			fought = true
			break
	Input.action_release("move_right")
	check(fought, "marcher dans le champ déclenche un combat")
	await _wait_idle(main)
	check(main.mode == main.Mode.PLAY and main.world != null and main.world.input_enabled, "retour sur la carte après la rencontre")

	print("  [étape] la Grande Baveuse")
	# la Grande Baveuse : combat lancé par un dialogue, puis l'obstacle disparaît
	GameState.heal_party()
	check(main.world.get_node_or_null("Monster_grande_baveuse") != null, "la Grande Baveuse barre l'enclos")
	main.run_dialogue("grande_baveuse")
	await _wait_idle(main)
	check(GameState.has_flag("baveuse_vaincue"), "la Grande Baveuse est vaincue")
	check(main.world != null and main.world.get_node_or_null("Monster_grande_baveuse") == null, "elle a quitté la carte")
	check(main.world != null and main.world.input_enabled, "le joueur a la main après le combat de boss")
	check(main.hud._soft.visible, "le témoin du Ramollissement est affiché au Pré Couché")

	print("  [étape] la quête du potager")
	check(GameState.quest_state("potager") == "active", "la quête du potager est en cours")
	main.run_dialogue("racines")
	await _wait_idle(main)
	check(GameState.has_flag("racines_prises") and GameState.item_count("racine") == 3, "racines cueillies")
	main.change_map("bittebourg", "route_est")
	await _wait_idle(main)
	check(main.world.map_id == "bittebourg", "retour à Bittebourg")
	main.run_dialogue("potager")
	await _wait_idle(main)
	check(GameState.quest_state("potager") == "done", "la quête du potager est accomplie")
	check(GameState.item_count("tuteur") == 1, "la récompense (tuteur) est dans le sac")
	check(main.world != null and main.world.input_enabled, "le joueur a la main après la quête")

	print("  [étape] la boutique d'Ursule")
	GameState.money = 60
	var tisanes := GameState.item_count("tisane")
	main.run_dialogue("ursule")
	for _i in 900:
		await get_tree().process_frame
		if main.menus.visible:
			break
		if main.dialogue.active and not main.dialogue.waiting:
			if main.dialogue._typing:
				main.dialogue._finish_typing()
			else:
				main.dialogue._advance()
	check(main.menus.visible, "le dialogue d'Ursule ouvre la boutique")
	check(main.dialogue.waiting, "le dialogue attend la fermeture de la boutique")
	main.menus.press(0)   # Acheter
	await get_tree().process_frame
	var offers: Array = main.menus.shop_offers()
	var row := -1
	for i in offers.size():
		if str(offers[i]["item"]) == "tisane":
			row = i
	check(row >= 0, "la tisane est en vente")
	main.menus.press(row)
	await get_tree().process_frame
	check(GameState.item_count("tisane") == tisanes + 1 and GameState.money == 52, "achat d'une tisane (argent : %d)" % GameState.money)
	main.menus.go_back()
	main.menus.go_back()
	await _wait_idle(main)
	check(not main.menus.visible and not main.dialogue.active, "boutique et dialogue refermés")
	check(main.world.input_enabled, "le joueur a la main après la boutique")

	print("  [étape] les écrans du menu de pause")
	main._open_pause()
	check(main.pause.visible, "menu de pause ouvert")
	for which: String in ["team", "inventory", "quests"]:
		main._on_pause_screen(which)
		await get_tree().process_frame
		check(main.menus.visible and not main.pause.visible, "écran « %s » ouvert depuis la pause" % which)
		check(not (main.menus.entry_texts() as Array).is_empty(), "écran « %s » : au moins une ligne" % which)
		main.menus.close()
		await get_tree().process_frame
		check(main.pause.visible and not main.menus.visible, "retour au menu de pause après « %s »" % which)
	main._on_pause_screen("talents")
	await get_tree().process_frame
	check(main.talents.visible and not main.pause.visible, "écran de talents ouvert depuis la pause")
	main.talents.close()
	await get_tree().process_frame
	check(main.pause.visible and not main.talents.visible, "retour au menu de pause après les talents")
	main._on_pause_screen("team")
	await get_tree().process_frame
	main.menus.press(0)
	await get_tree().process_frame
	main.menus.press(1)
	await get_tree().process_frame
	check(main.talents.visible and not main.menus.visible, "écran de talents ouvert depuis la fiche d'un personnage")
	main.talents.close()
	await get_tree().process_frame
	check(main.menus.visible and not main.talents.visible, "retour à l'équipe après les talents")
	main.menus.close()
	await get_tree().process_frame
	GameState.member(GameState.leader())["level"] = maxi(2, int(GameState.member(GameState.leader())["level"]))
	GameState.reset_talents(GameState.leader())
	main.pause.close(true)
	main._open_pause()
	check(str(main.pause._talents.text).contains("dépenser"), "la pause signale les points de talent à dépenser (%s)" % str(main.pause._talents.text))
	main.pause.close()
	check(main.world.input_enabled, "le joueur a la main après la pause")

	print("  [étape] la Fête des Amarres, l'invasion et le Naze")
	for who: String in ["sam", "fripon"]:
		if not GameState.party.has(who):
			GameState.add_to_party(who)
	for who: String in GameState.party:
		GameState.member(who)["level"] = 8
	GameState.heal_party()
	GameState.set_flag("fete_commencee")
	await get_tree().process_frame
	await _wait_idle(main)
	main.run_dialogue("ceremonie")
	await _wait_idle(main)
	check(GameState.has_flag("naze_arrive") and GameState.has_flag("invasion"), "la cérémonie déclenche l'invasion")
	var invaders := 0
	for n: Node3D in main.world.npcs:
		if str(n.data.get("dialogue", "")).begins_with("morfales_"):
			invaders += 1
	check(invaders == 3, "trois groupes de Morfales dans le village (%d)" % invaders)
	for where: String in ["morfales_quai", "morfales_potager", "morfales_auberge"]:
		GameState.heal_party()
		main.run_dialogue(where)
		await _wait_idle(main)
		check(GameState.has_flag("combat_" + where), "%s : Morfales chassés" % where)
	check(GameState.has_flag("morfales_chasses"), "les trois groupes chassés : le Naze se montre")
	var naze_here := false
	for n: Node3D in main.world.npcs:
		if str(n.data.get("dialogue", "")) == "naze":
			naze_here = true
	check(naze_here, "le Naze attend au pied de la Grande Bitte")
	GameState.heal_party()
	main.run_dialogue("naze")
	await _wait_idle(main, 120.0)
	check(GameState.has_flag("naze_vaincu"), "le Naze est vaincu")
	check(not GameState.has_flag("invasion"), "l'invasion est terminée")
	check(GameState.has_flag("route_ouverte") and GameState.item_count("premiere_amarre") == 1, "la route de Brie s'ouvre, la Première Amarre est dans le sac")
	check(main.world != null and main.world.input_enabled, "le joueur a la main après le Naze")
	var to_brie := false
	for wp: Dictionary in main.world.warps:
		if str(wp["map"]) == "route_brie":
			to_brie = true
	check(to_brie, "le passage vers la route de Brie existe")

	print("  [étape] la route de Brie et la fin du chapitre")
	main.change_map("route_brie", "est")
	await _wait_idle(main)
	check(main.world.map_id == "route_brie", "arrivée sur la route de Brie")
	GameState.heal_party()
	main.run_dialogue("peage_morfales")
	await _wait_idle(main, 90.0)
	check(GameState.has_flag("combat_morfales_route"), "le péage des Morfales est forcé")
	main.run_dialogue("fin_chapitre_1")
	await _wait_idle(main)
	check(GameState.has_flag("chapitre_1_fini"), "le chapitre 1 se termine")
	check(GameState.chapter == "chapitre_2", "le chapitre suivant est noté (%s)" % GameState.chapter)
	check(GameState.quest_state("ramollissement") == "done", "la quête principale du chapitre est accomplie")
	check(SaveManager.has_save(), "sauvegarde à la fin du chapitre")
	check(main.world != null and main.world.input_enabled, "le joueur garde la main après la fin du chapitre")
	main.queue_free()
	await get_tree().process_frame


# ------------------------------------------------------------------ chapitre 2

const TEAM5 := ["glandoulf", "sam", "fripon", "pepine", "aragrogne"]


## Taux de victoire d'une rencontre du chapitre 2 (jeu automatique, 40 combats).
func _c2_rate(ids: Array, level: int, enc: Dictionary, talents: int) -> float:
	var wins := 0
	var runs := 40
	for s in runs:
		GameState.new_game()
		GameState.party = []
		for id: String in ids:
			GameState.add_to_party(id)
			GameState.member(id)["level"] = level
			if talents >= 0:
				_spend(id, talents)
		GameState.heal_party()
		var e := _fight(enc, 100 + s)
		if str(e.result) == "victory":
			wins += 1
	return float(wins) / runs


func _test_chapter_2_data() -> void:
	print("== Chapitre 2 : données et équilibre ==")
	for id: String in ["brie", "poney_flagada", "poney_etage", "fromagerie", "caves_brie", "ferme_pinard"]:
		check(Database.get_map(id).has("music") and Database.get_map(id).has("spawns"), "carte %s : musique et points d'arrivée" % id)
	check(Database.get_item("plume_chantecler").get("firm", false) == true, "la plume de Chantecler rend ferme")
	check(not Database.get_character("aragrogne").is_empty(), "Aragrogne existe")
	var cases := [
		["Nazes, cinq niv. 9, talents A", TEAM5, 9, _soft("nazes_nuit", 0.3), 0.6, 0],
		["Nazes, cinq niv. 9, sans talents", TEAM5, 9, _soft("nazes_nuit", 0.3), 0.25, -1],
		["Chantecler, quatre niv. 8", TEAM, 8, _soft("chantecler", 0.2), 0.7, 0],
		["Vacherin, quatre niv. 8", TEAM, 8, _soft("vacherin", 0.2), 0.7, 0],
		["Gaston, Sam seul", ["sam"], 9, Database.get_encounter("duel_gaston"), 0.7, -1],
		["Veuve, Sam seul", ["sam"], 9, Database.get_encounter("duel_veuve"), 0.7, -1],
		["rats et mouches, quatre niv. 8", TEAM, 8, {"enemies": ["rat_cave", "rat_cave", "mouche_cave"], "ramollissement": 0.2}, 0.9, -1],
		["moisissure et ver, quatre niv. 8", TEAM, 8, {"enemies": ["ver_fromage", "moisi_bleu", "rat_cave"], "ramollissement": 0.2}, 0.9, -1],
	]
	for case: Array in cases:
		var rate := _c2_rate(case[1], int(case[2]), case[3], int(case[5]))
		check(rate >= float(case[4]), "%s : %d %% de victoires (attendu : au moins %d %%)" % [str(case[0]), int(rate * 100.0), int(float(case[4]) * 100.0)])
		print("  %-40s %3d %% de victoires" % [str(case[0]), int(rate * 100.0)])
	GameState.new_game()


## Déroulé du chapitre 2, à la suite du chapitre 1 (la sauvegarde de fin de chapitre 1 existe).
func _test_chapter_2() -> void:
	print("== Chapitre 2 : déroulé complet ==")
	var main: Node = MAIN.instantiate()
	main.auto_battles = true
	add_child(main)
	await _wait_idle(main)
	GameState.map_id = "route_brie"
	GameState.spawn_id = "est"
	GameState.player_pos = []
	SaveManager.save_game()
	main.continue_game()
	await _wait_idle(main)
	check(GameState.has_flag("chapitre_1_fini"), "reprise après le chapitre 1")
	check(main.world.map_id == "route_brie", "la partie reprend sur la route de Brie (%s)" % main.world.map_id)
	var to_brie := false
	for wp: Dictionary in main.world.warps:
		if str(wp["map"]) == "brie":
			to_brie = true
	check(to_brie, "la route de Brie mène à Brie une fois le chapitre 1 fini")

	main.change_map("brie", "route")
	await _wait_idle(main)
	check(main.world.map_id == "brie" and GameState.has_flag("brie_vue"), "arrivée à Brie")
	check(GameState.chapter == "chapitre_2" or GameState.quest_state("brie") != "", "la quête de Brie est lancée")
	for who: String in ["sam", "fripon", "pepine"]:
		if not GameState.party.has(who):
			GameState.add_to_party(who)
	for who: String in GameState.party:
		GameState.member(who)["level"] = 9
	GameState.heal_party()
	main.run_dialogue("sidonie")
	await _wait_idle(main)
	check(GameState.has_flag("sidonie_vue"), "Sidonie, marchande de la place")

	main.change_map("poney_flagada", "entree")
	await _wait_idle(main)
	check(main.world.map_id == "poney_flagada" and GameState.has_flag("poney_vu"), "le Poney Flagada")
	main.run_dialogue("aragrogne")
	await _wait_idle(main)
	check(GameState.party.has("aragrogne") and GameState.has_flag("aragrogne_equipe"), "Aragrogne rejoint l'équipe")
	GameState.member("aragrogne")["level"] = 9
	GameState.heal_party()

	# le concours de bras de fer : Sam seul
	main.run_dialogue("affiche_concours")
	await _wait_idle(main)
	check(GameState.has_flag("concours_inscrit"), "inscription au concours")
	var team_before: Array = GameState.party.duplicate()
	main.run_dialogue("gaston")
	await _wait_idle(main, 90.0)
	check(GameState.has_flag("combat_duel_gaston"), "demi-finale gagnée")
	main.run_dialogue("veuve")
	await _wait_idle(main, 90.0)
	check(GameState.has_flag("concours_gagne") and GameState.item_count("ceinture_champion") == 1, "finale gagnée : la ceinture est dans le sac (%s, %d)" % [str(GameState.has_flag("concours_gagne")), GameState.item_count("ceinture_champion")])
	check(GameState.party == team_before, "l'équipe est retrouvée après les duels")
	GameState.heal_party()

	# le poney qui ne se lève pas
	main.run_dialogue("barnabe")
	await _wait_idle(main)
	check(GameState.has_flag("poney_couche_vu"), "le poney couché")
	GameState.add_item("racine", 1)
	main.run_dialogue("ecurie")
	await _wait_idle(main)
	check(GameState.has_flag("poney_leve") and GameState.quest_state("poney") == "done", "le poney se relève")

	# la cave du fromager
	main.change_map("fromagerie", "entree")
	await _wait_idle(main)
	main.run_dialogue("persille")
	await _wait_idle(main)
	check(GameState.has_flag("cave_ouverte"), "la trappe de la cave est ouverte")
	main.change_map("caves_brie", "trappe")
	await _wait_idle(main)
	check(main.world.map_id == "caves_brie" and GameState.has_flag("cave_vue"), "dans la cave (%s, vue %s)" % [main.world.map_id, str(GameState.has_flag("cave_vue"))])
	main.run_dialogue("vacherin")
	await _wait_idle(main, 150.0)
	check(GameState.has_flag("vacherin_vaincu"), "le Vacherin est vaincu")
	GameState.heal_party()
	main.change_map("fromagerie", "trappe")
	await _wait_idle(main)
	main.run_dialogue("persille")
	await _wait_idle(main)
	check(GameState.has_flag("persille_paye") and GameState.quest_state("fromager") == "done", "le fromager est payé")

	# la ferme et Chantecler
	main.change_map("ferme_pinard", "nord")
	await _wait_idle(main)
	check(main.world.map_id == "ferme_pinard" and GameState.has_flag("ferme_vue"), "à la ferme Pinard (%s, vue %s)" % [main.world.map_id, str(GameState.has_flag("ferme_vue"))])
	main.run_dialogue("chantecler")
	await _wait_idle(main, 150.0)
	check(GameState.has_flag("chantecler_vaincu") and GameState.item_count("plume_chantecler") == 1, "Chantecler vaincu, sa plume est dans le sac")
	GameState.heal_party()

	# la nuit au Poney Flagada
	main.change_map("poney_flagada", "entree")
	await _wait_idle(main)
	main.run_dialogue("barnabe")
	await _wait_idle(main)
	check(GameState.has_flag("chambre_prise"), "les chambres sont prises")
	var stairs := false
	for wp: Dictionary in main.world.warps:
		if str(wp["map"]) == "poney_etage":
			stairs = true
	check(stairs, "l'escalier mène à l'étage")
	main.change_map("poney_etage", "escalier")
	await _wait_idle(main, 240.0)
	check(GameState.has_flag("nazes_vaincu"), "les deux Nazes sont vaincus")
	check(main.world != null and main.world.input_enabled, "le joueur a la main après la nuit")
	main.change_map("poney_flagada", "escalier")
	await _wait_idle(main)
	main.run_dialogue("barnabe")
	await _wait_idle(main)
	check(GameState.item_count("convocation_elrond") == 1, "la convocation du Conseil est dans le sac")
	main.change_map("brie", "route")
	await _wait_idle(main)
	main.run_dialogue("fin_chapitre_2")
	await _wait_idle(main)
	check(GameState.has_flag("chapitre_2_fini") and GameState.chapter == "chapitre_3", "le chapitre 2 se termine (%s)" % GameState.chapter)
	check(GameState.quest_state("brie") == "done", "la quête principale de Brie est accomplie")
	check(SaveManager.has_save(), "sauvegarde à la fin du chapitre 2")
	main.queue_free()
	await get_tree().process_frame
