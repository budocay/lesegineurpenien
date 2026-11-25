extends RefCounted
## Le Carnet : tout ce qui se compte, se range ou se révèle au fil de la partie.
## Compteurs de partie (GameState.stats), fiches du bestiaire (GameState.bestiary_log, plus les
## faiblesses découvertes de GameState.bestiary), niveaux de difficulté, origine d'une
## caractéristique. Les textes viennent de data/carnet.json (format : docs/FORMAT_DONNEES.md).
## Pas de nœud ici : le moteur de combat, l'état de la partie et les écrans l'appellent.

const Rules = preload("res://src/battle/rules.gd")

const DIFFICULTY_IDS := ["promenade", "aventure", "epreuve"]
const DEFAULT_DIFFICULTY := "aventure"
const FALLBACK_NAMES := {"promenade": "Promenade", "aventure": "Aventure", "epreuve": "Épreuve"}
const STEP_LENGTH := 0.7   # un « pas » du compteur : tant d'unités de la carte parcourues


# ------------------------------------------------------------------ difficulté

static func difficulty_id() -> String:
	var id := str(Settings.get_value("difficulte"))
	return id if DIFFICULTY_IDS.has(id) else DEFAULT_DIFFICULTY


## Fiche d'un niveau de difficulté (vide pour un identifiant inconnu).
static func difficulty_def(id: String = "") -> Dictionary:
	if id == "":
		id = difficulty_id()
	var all: Variant = Database.carnet.get("difficulties", {})
	var d: Variant = (all as Dictionary).get(id, {}) if all is Dictionary else {}
	return d if d is Dictionary else {}


static func difficulty_name(id: String) -> String:
	return str(difficulty_def(id).get("name", FALLBACK_NAMES.get(id, id)))


## Multiplicateur d'un réglage (« enemy_hp », « enemy_dmg », « xp », « money ») : 1 si rien n'est dit.
static func mult(key: String, id: String = "") -> float:
	return float(difficulty_def(id).get(key, 1.0))


# ------------------------------------------------------------------- compteurs

static func fresh_stats() -> Dictionary:
	return {
		"combats": 0, "fuites": 0, "defaites": 0, "vaincus": 0,
		"degats_infliges": 0, "degats_subis": 0, "soins": 0, "critiques": 0, "objets": 0,
		"or_gagne": 0, "or_depense": 0, "pas": 0.0,
		"ko": {}, "competences": {},
		"record": {"who": "", "what": "", "amount": 0, "target": ""},
	}


## Compteurs d'une sauvegarde : tout ce qui manque (ancienne sauvegarde) vaut zéro.
static func merge_stats(raw: Variant) -> Dictionary:
	var out := fresh_stats()
	if not (raw is Dictionary):
		return out
	var d: Dictionary = raw
	for key: String in out:
		if not d.has(key):
			continue
		var v: Variant = d[key]
		if out[key] is Dictionary:
			if v is Dictionary:
				out[key] = (v as Dictionary).duplicate(true)
				if key == "record":
					var rec := fresh_stats()["record"] as Dictionary
					for k: String in rec:
						if not (out[key] as Dictionary).has(k):
							(out[key] as Dictionary)[k] = rec[k]
		elif out[key] is float:
			out[key] = float(v)
		else:
			out[key] = int(v)
	return out


static func bump(key: String, amount: Variant = 1) -> void:
	if not GameState.stats.has(key):
		GameState.stats[key] = fresh_stats().get(key, 0)
	GameState.stats[key] = GameState.stats[key] + amount


static func bump_in(key: String, sub: String, amount: int = 1) -> void:
	if not (GameState.stats.get(key) is Dictionary):
		GameState.stats[key] = {}
	var d: Dictionary = GameState.stats[key]
	d[sub] = int(d.get(sub, 0)) + amount


## Pas faits (affichés en entier) : le joueur marche, la distance s'additionne.
static func walk(distance: float) -> void:
	GameState.stats["pas"] = float(GameState.stats.get("pas", 0.0)) + distance / STEP_LENGTH


## Compétence la plus utilisée par un personnage : {"id", "name", "count"} ou {}.
static func favorite_skill(who: String) -> Dictionary:
	var used: Variant = (GameState.stats.get("competences", {}) as Dictionary).get(who, {})
	if not (used is Dictionary):
		return {}
	var best := ""
	var n := 0
	for id: String in used:
		if int(used[id]) > n:
			n = int(used[id])
			best = id
	if best == "":
		return {}
	return {"id": best, "name": str(Database.get_skill(best).get("name", best)), "count": n}


## Coffres du jeu : tous les dialogues « coffre_* » ; ouvert quand son drapeau « <id>_ouvert » est posé.
static func chests() -> Array:
	var out: Array = []
	for id: String in Database.dialogues:
		if id.begins_with("coffre_"):
			out.append(id)
	out.sort()
	return out


static func chests_opened() -> int:
	var n := 0
	for id: String in chests():
		if GameState.has_flag(id + "_ouvert"):
			n += 1
	return n


static func quests_done() -> int:
	var n := 0
	for id: String in Database.quests:
		if GameState.quest_state(id) == "done":
			n += 1
	return n


## « 12 h 05 » : durée de jeu en toutes lettres, pour les statistiques.
static func playtime_long() -> String:
	var total := int(GameState.playtime)
	return "%d h %02d min" % [total / 3600, (total % 3600) / 60]


# -------------------------------------------------------------------- bestiaire

static func creature_ids() -> Array:
	return Database.enemies.keys()


static func creature_log(id: String) -> Dictionary:
	var v: Variant = GameState.bestiary_log.get(id, {})
	return v if v is Dictionary else {}


## "unknown" (jamais croisée), "seen" (croisée) ou "beaten" (au moins une victoire : statistiques révélées).
static func creature_state(id: String) -> String:
	var lg := creature_log(id)
	if int(lg.get("beaten", 0)) > 0:
		return "beaten"
	if int(lg.get("seen", 0)) > 0 or GameState.bestiary.has(id):
		return "seen"
	return "unknown"


## [créatures croisées, créatures vaincues, total].
static func completion() -> Array:
	var met := 0
	var won := 0
	for id: String in creature_ids():
		match creature_state(id):
			"beaten":
				met += 1
				won += 1
			"seen":
				met += 1
	return [met, won, creature_ids().size()]


static func creature_text(id: String) -> String:
	var all: Variant = Database.carnet.get("creatures", {})
	return str((all as Dictionary).get(id, "")) if all is Dictionary else ""


static func weak_known(id: String) -> Array:
	var v: Variant = GameState.bestiary.get(id, [])
	return v if v is Array else []


static func immune_known(id: String) -> Array:
	var v: Variant = creature_log(id).get("immune", [])
	return v if v is Array else []


## Butin déjà obtenu de cette créature, et nombre de butins possibles encore inconnus.
static func loot_known(id: String) -> Array:
	var v: Variant = creature_log(id).get("loot", [])
	return v if v is Array else []


static func loot_unknown(id: String) -> int:
	var seen := {}
	for d: Variant in Database.get_enemy(id).get("drops", []):
		if d is Dictionary and not loot_known(id).has(str(d.get("item", ""))):
			seen[str(d.get("item", ""))] = true
	return seen.size()


## Reprise d'une ancienne sauvegarde : une créature dont on connaît une faiblesse a été croisée.
static func upgrade_log(raw: Dictionary, bestiary: Dictionary) -> Dictionary:
	var out := raw.duplicate(true)
	for id: String in bestiary:
		if not out.has(id):
			out[id] = {"seen": 1, "beaten": 0}
	return out


## Révèle tout d'une créature : faiblesses, insensibilités, statistiques (effet « analyze »).
static func analyze(id: String, weak: Array, immune: Array) -> void:
	var known: Array = weak_known(id).duplicate()
	for w: Variant in weak:
		if not known.has(str(w)):
			known.append(str(w))
	GameState.bestiary[id] = known
	var lg := creature_log(id).duplicate(true)
	var im: Array = immune_known(id).duplicate()
	for s: Variant in immune:
		if not im.has(str(s)):
			im.append(str(s))
	lg["immune"] = im
	lg["analyzed"] = true
	GameState.bestiary_log[id] = lg


## Range le bilan d'un combat (compteurs et fiches) dans la partie. `engine` est un BattleEngine ;
## renvoie {"records": [textes], "new": [noms des créatures découvertes], "first_win": [idem, première victoire]}.
static func absorb(engine: RefCounted) -> Dictionary:
	var out := {"records": [], "new": [], "first_win": []}
	var t: Dictionary = engine.tally
	var res := str(engine.result)
	if res == "victory":
		bump("combats")
	elif res == "fled":
		bump("fuites")
	elif res == "defeat":
		bump("defaites")
	bump("degats_infliges", int(t.get("dealt", 0)))
	bump("degats_subis", int(t.get("taken", 0)))
	bump("soins", int(t.get("heal", 0)))
	bump("critiques", int(t.get("crits", 0)))
	bump("objets", int(t.get("items", 0)))
	for who: String in t.get("ko", {}):
		bump_in("ko", who, int(t["ko"][who]))
	for who: String in t.get("skills", {}):
		for skill: String in t["skills"][who]:
			if not (GameState.stats["competences"] is Dictionary):
				GameState.stats["competences"] = {}
			var per: Dictionary = GameState.stats["competences"]
			if not (per.get(who) is Dictionary):
				per[who] = {}
			per[who][skill] = int((per[who] as Dictionary).get(skill, 0)) + int(t["skills"][who][skill])
	var best: Dictionary = t.get("best", {})
	var rec: Dictionary = GameState.stats["record"]
	if int(best.get("amount", 0)) > int(rec.get("amount", 0)):
		GameState.stats["record"] = best.duplicate()
		if int(rec.get("amount", 0)) > 0 or res == "victory":
			out["records"].append("Nouveau record : %s, « %s », %d dégâts d'un seul coup !" % [
				Database.get_character_name(str(best.get("who", ""))), str(best.get("what", "")), int(best.get("amount", 0))])
	# fiches du bestiaire
	var met_here := {}
	for e: RefCounted in engine.enemies:
		met_here[str(e.source)] = true
	for id: String in met_here:
		var before := creature_state(id)
		var lg := creature_log(id).duplicate(true)
		lg["seen"] = int(lg.get("seen", 0)) + 1
		if not lg.has("map"):
			lg["map"] = GameState.map_id
		if res == "victory":
			var killed := 0
			for e: RefCounted in engine.enemies:
				if str(e.source) == id and not e.alive():
					killed += 1
			lg["beaten"] = int(lg.get("beaten", 0)) + killed
			bump("vaincus", killed)
		var seen_im: Array = (lg.get("immune", []) as Array).duplicate() if lg.get("immune") is Array else []
		for s: Variant in (t.get("immune", {}) as Dictionary).get(id, []):
			if not seen_im.has(str(s)):
				seen_im.append(str(s))
		lg["immune"] = seen_im
		if t.get("loot", {}).has(id):
			var loot: Array = (lg.get("loot", []) as Array).duplicate() if lg.get("loot") is Array else []
			for item: Variant in t["loot"][id]:
				if not loot.has(str(item)):
					loot.append(str(item))
			lg["loot"] = loot
		GameState.bestiary_log[id] = lg
		var name := str(Database.get_enemy(id).get("name", id))
		if before == "unknown":
			(out["new"] as Array).append(name)
		if res == "victory" and before != "beaten" and int(lg.get("beaten", 0)) > 0:
			(out["first_win"] as Array).append(name)
	return out


# ----------------------------------------------------- origine d'une caractéristique

## D'où vient une caractéristique : {"base": valeur du niveau, "gear": [{"item","slot","value"}],
## "other": le reste (talents et autres bonus), "total"}.
static func stat_sources(who: String, key: String) -> Dictionary:
	var m := GameState.member(who)
	var base := int(Rules.stats_at(who, int(m["level"])).get(key, 0))
	var gear: Array = []
	var gear_sum := 0
	var worn: Dictionary = m["equip"]
	for slot: String in GameState.SLOTS:
		if not worn.has(slot):
			continue
		var mods: Variant = Database.get_item(str(worn[slot])).get("mods", {})
		if mods is Dictionary and (mods as Dictionary).has(key) and int(mods[key]) != 0:
			gear.append({"item": str(worn[slot]), "slot": slot, "value": int(mods[key])})
			gear_sum += int(mods[key])
	var total := int(GameState.member_stats(who).get(key, 0))
	return {"base": base, "gear": gear, "other": total - base - gear_sum, "total": total}
