extends RefCounted
## Débuts de chapitre : fabrique à la demande une partie neuve et crédible au début d'un chapitre,
## à partir de la description de data/chapter_starts.json (format : docs/FORMAT_DONNEES.md).
## Aucun fichier de sauvegarde figé : les descriptions suivent l'évolution du jeu, et la partie
## fabriquée passe par les fonctions de GameState (niveaux, équipement, quêtes), pas par des
## champs écrits à la main quand une fonction existe.
## Ajouter un chapitre, c'est ajouter une entrée aux données, pas du code.

const Rules = preload("res://src/battle/rules.gd")
const PATH := "res://data/chapter_starts.json"

static var _cache: Array = []


## Les chapitres proposés, dans l'ordre du jeu (liste de dictionnaires).
static func entries() -> Array:
	if _cache.is_empty():
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(PATH))
		if parsed is Dictionary and (parsed as Dictionary).get("chapters") is Array:
			for e: Variant in (parsed as Dictionary)["chapters"]:
				if e is Dictionary:
					_cache.append(e)
	return _cache


static func reload() -> void:
	_cache = []


static func entry(id: String) -> Dictionary:
	for e: Dictionary in entries():
		if str(e.get("id", "")) == id:
			return e
	return {}


## Vrai si ce début passe par le prologue (le tout premier chapitre : « Nouvelle partie »).
static func is_new_game(id: String) -> bool:
	return bool(entry(id).get("new_game", false))


## Tous les drapeaux supposés posés au début du chapitre : ceux de ses prédécesseurs, puis les siens.
static func flags_for(id: String) -> Array:
	var out: Array = []
	for e: Dictionary in entries():
		for f: Variant in e.get("flags", []):
			if not out.has(str(f)):
				out.append(str(f))
		if str(e.get("id", "")) == id:
			break
	return out


## Fabrique la partie du chapitre `id` dans l'état `gs` (l'autoload GameState). Renvoie faux si le
## chapitre est inconnu. Ne touche ni au disque ni à l'affichage.
static func apply(gs: Node, id: String) -> bool:
	var e := entry(id)
	if e.is_empty() or bool(e.get("new_game", false)):
		return false
	gs.new_game()
	gs.inventory = {}
	gs.chapter = str(e.get("chapter", id))
	# l'équipe, dans l'ordre : les quatre premiers se battent, les autres attendent en réserve
	gs.party = []
	for who: Variant in e.get("party", []):
		gs.add_to_party(str(who))
	gs.bench = []
	for who: Variant in e.get("bench", []):
		var sid := str(who)
		if not gs.bench.has(sid):
			gs.bench.append(sid)
	# niveaux : par le gain d'expérience du moteur (il rend aussi les PV et les PM)
	var everyone: Array = (e.get("party", []) as Array) + (e.get("bench", []) as Array) + (e.get("away", []) as Array)
	var levels: Dictionary = e.get("levels", {}) if e.get("levels") is Dictionary else {}
	for who: Variant in everyone:
		var sid := str(who)
		_set_level(gs, sid, int(levels.get(sid, e.get("level", 1))))
	# le sac, puis l'équipement porté (pris dans le sac)
	for item: Variant in (e.get("items", {}) as Dictionary):
		_give(gs, str(item), int((e["items"] as Dictionary)[item]))
	var gear: Dictionary = e.get("gear", {}) if e.get("gear") is Dictionary else {}
	for who: Variant in everyone:
		_wear(gs, str(who), gear.get(str(who), {}) as Dictionary if gear.get(str(who)) is Dictionary else {})
	spend_talent_points(gs, e)
	gs.money = int(e.get("money", 0))
	# l'histoire : drapeaux posés directement (set_flag lancerait les quêtes une à une, avec leurs récompenses)
	for f: String in flags_for(id):
		gs.flags[f] = true
	_settle_quests(gs, e)
	gs.map_id = str(e.get("map", ""))
	gs.spawn_id = str(e.get("spawn", ""))
	gs.player_pos = []
	gs.player_facing = "down"
	for who: Variant in everyone:   # aussi la réserve, le banc et les absents
		var hurt: Dictionary = gs.member(str(who))
		var stats: Dictionary = gs.member_stats(str(who))
		hurt["hp"] = int(stats["hp"])
		hurt["mp"] = int(stats["mp"])
	gs.playtime = 0.0
	return true


## Niveau voulu, atteint par gain d'expérience (comme en jouant) : le personnage gagne ses compétences
## et ses points de talents au passage.
static func _set_level(gs: Node, who: String, level: int) -> void:
	var m: Dictionary = gs.member(who)
	var need := 0
	for l in range(int(m["level"]), clampi(level, 1, Rules.MAX_LEVEL)):
		need += Rules.xp_to_next(l)
	if need > 0:
		gs.grant_xp(who, need)


static func _give(gs: Node, item: String, count: int) -> void:
	if count > 0 and not Database.get_item(item).is_empty():
		gs.inventory[item] = int(gs.inventory.get(item, 0)) + count


## Habille un personnage : la tenue de départ est mise de côté, puis chaque pièce passe par le sac
## et par GameState.equip (qui vérifie que l'objet lui va).
static func _wear(gs: Node, who: String, gear: Dictionary) -> void:
	var m: Dictionary = gs.member(who)
	m["equip"] = {}
	for slot: String in gs.SLOTS:
		var item := str(gear.get(slot, ""))
		if item == "":
			continue
		_give(gs, item, 1)
		if not gs.equip(who, item, slot):
			push_warning("Début de chapitre : %s ne peut pas porter %s (%s)" % [who, item, slot])
			gs.inventory[item] = maxi(0, int(gs.inventory.get(item, 0)) - 1)
			if int(gs.inventory.get(item, 0)) <= 0:
				gs.inventory.erase(item)
	gs.member(who)


## POINTS DE TALENTS : la seule fonction de ce module qui connaît le système de talents. Chaque
## personnage a déjà reçu ses points avec ses niveaux ; elle les dépense selon le plan du chapitre
## (champ « talents » : {personnage: [branches dans l'ordre de préférence]}), comme un joueur qui
## remplit une voie avant de passer à l'autre. À adapter si le système de talents change.
static func spend_talent_points(gs: Node, e: Dictionary) -> void:
	var plan: Dictionary = e.get("talents", {}) if e.get("talents") is Dictionary else {}
	for who: String in plan:
		var wanted: Array = plan[who] if plan[who] is Array else []
		for branch_id: Variant in wanted:
			for b: Dictionary in Rules.branches(who):
				if str(b.get("id", "")) != str(branch_id):
					continue
				for t: Dictionary in Rules.branch_talents(b):
					if not gs.learn_talent(who, str(t.get("id", ""))):
						break   # plus de points, ou talent à débloquer d'abord : on passe à la suite
		gs.member(who)


## Quêtes : celles que les drapeaux disent finies sont closes sans récompense (l'argent et l'équipement
## du chapitre sont déjà dans les données) ; puis les quêtes qui démarrent d'elles-mêmes se lancent.
static func _settle_quests(gs: Node, e: Dictionary) -> void:
	gs.quests = {}
	for qid: String in Database.quests:
		var complete := str(Database.get_quest(qid).get("complete", ""))
		if complete != "" and gs.check(complete):
			gs.quests[qid] = "done"
	for qid: Variant in e.get("quests_done", []):
		gs.quests[str(qid)] = "done"
	gs.refresh_quests(true)


# --------------------------------------------------------------------------- vérification

## Problèmes d'une description (liste de textes ; vide : tout va bien). Sert au test automatique.
static func problems(e: Dictionary) -> Array:
	var out: Array = []
	var id := str(e.get("id", "?"))
	for key: String in ["id", "title", "place", "summary"]:
		if str(e.get(key, "")) == "":
			out.append("%s : champ « %s » manquant" % [id, key])
	if bool(e.get("new_game", false)):
		return out
	if not Database.has_map(str(e.get("map", ""))):
		out.append("%s : carte inconnue « %s »" % [id, str(e.get("map", ""))])
	else:
		var spawns: Variant = Database.get_map(str(e["map"])).get("spawns", {})
		if not (spawns is Dictionary and (spawns as Dictionary).has(str(e.get("spawn", "")))):
			out.append("%s : arrivée inconnue « %s » sur %s" % [id, str(e.get("spawn", "")), str(e["map"])])
	if (e.get("party", []) as Array).is_empty():
		out.append("%s : équipe vide" % id)
	var everyone: Array = (e.get("party", []) as Array) + (e.get("bench", []) as Array) + (e.get("away", []) as Array)
	for who: Variant in everyone:
		if Rules.battle_def(str(who)).is_empty():
			out.append("%s : personnage sans fiche de combat « %s »" % [id, str(who)])
	for who: Variant in (e.get("gear", {}) as Dictionary):
		if not everyone.has(who):
			out.append("%s : équipement donné à quelqu'un qui n'est pas là « %s »" % [id, str(who)])
		for slot: Variant in ((e["gear"] as Dictionary)[who] as Dictionary):
			var item := str(((e["gear"] as Dictionary)[who] as Dictionary)[slot])
			if Database.get_item(item).is_empty():
				out.append("%s : objet inconnu « %s »" % [id, item])
	for item: Variant in (e.get("items", {}) as Dictionary):
		if Database.get_item(str(item)).is_empty():
			out.append("%s : objet inconnu « %s »" % [id, str(item)])
	for q: Variant in e.get("quests_done", []):
		if Database.get_quest(str(q)).is_empty():
			out.append("%s : quête inconnue « %s »" % [id, str(q)])
	if str(e.get("main_quest", "")) != "" and Database.get_quest(str(e["main_quest"])).is_empty():
		out.append("%s : quête principale inconnue « %s »" % [id, str(e["main_quest"])])
	return out
