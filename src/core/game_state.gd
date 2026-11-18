extends Node
## État central de la partie : progression, drapeaux, quêtes, équipe, équipement,
## inventaire, argent, position. La sauvegarde n'est rien d'autre que ce dictionnaire
## écrit sur le disque.

signal flag_changed(flag: String, value: Variant)
signal quest_started(id: String)
signal quest_completed(id: String, reward: Dictionary)

const Rules = preload("res://src/battle/rules.gd")

const SAVE_VERSION := 3
const SLOTS := ["weapon", "armor", "trinket"]
const SLOT_NAMES := {"weapon": "Arme", "armor": "Tenue", "trinket": "Babiole"}
const STAT_NAMES := {"hp": "PV", "mp": "PM", "atk": "Attaque", "def": "Défense", "mag": "Magie", "res": "Résistance", "spd": "Vitesse"}
const MONEY_NAME := "écus"

var chapter: String = "chapitre_1"
var flags: Dictionary = {}
var quests: Dictionary = {}      # id de quête -> "active" ou "done" (absente : pas commencée)
var party: Array = []            # ids des personnages actifs
var roster: Dictionary = {}      # id -> {level, xp, hp, mp, equip: {emplacement: objet}, specialization, talents}
var bestiary: Dictionary = {}    # id d'ennemi -> faiblesses déjà découvertes
var inventory: Dictionary = {}   # id d'objet -> quantité (l'équipement porté n'y figure pas)
var money: int = 0
var map_id: String = ""
var spawn_id: String = ""
var player_pos: Array = []       # [x, z] en unités monde ; vide = utiliser spawn_id
var player_facing: String = "down"
var playtime: float = 0.0
var playing: bool = false

var _refreshing := false


func _process(delta: float) -> void:
	if playing:
		playtime += delta


func new_game() -> void:
	var start: Dictionary = Database.game.get("start", {})
	chapter = str(start.get("chapter", "chapitre_1"))
	flags = {}
	quests = {}
	inventory = {}
	var start_inv: Variant = start.get("inventory", {})
	if start_inv is Dictionary:
		for item: String in start_inv:
			inventory[item] = int(start_inv[item])
	roster = {}
	bestiary = {}
	party = []
	for id: Variant in start.get("party", ["glandoulf"]):
		add_to_party(str(id))
	money = int(start.get("money", 0))
	map_id = str(start.get("map", ""))
	spawn_id = str(start.get("spawn", ""))
	player_pos = []
	player_facing = "down"
	playtime = 0.0


## Fait entrer quelqu'un dans l'équipe. Avec catch_up, une nouvelle recrue arrive
## presque au niveau du meneur (un de moins) au lieu de repartir du niveau 1.
func add_to_party(id: String, catch_up: bool = false) -> void:
	var is_new := not (roster.get(id) is Dictionary)
	if not party.has(id):
		party.append(id)
	var m := member(id)
	if catch_up and is_new and party.size() > 1:
		m["level"] = maxi(1, int(member(leader())["level"]) - 1)
		m.erase("hp")
		m.erase("mp")
		member(id)
	refresh_quests()


## Fiche d'un membre de l'équipe (créée et complétée au besoin) : niveau, xp, PV et PM
## actuels, équipement porté.
func member(id: String) -> Dictionary:
	if not (roster.get(id) is Dictionary):
		roster[id] = {"level": 1, "xp": 0, "specialization": "", "talents": [], "equip": _starting_gear(id)}
	var m: Dictionary = roster[id]
	if not (m.get("equip") is Dictionary):
		m["equip"] = {}
	if not (m.get("talents") is Array):
		m["talents"] = []
	m["level"] = clampi(int(m.get("level", 1)), 1, Rules.MAX_LEVEL)
	m["xp"] = int(m.get("xp", 0))
	var stats := _stats(id, m)
	m["hp"] = clampi(int(m.get("hp", stats["hp"])), 0, int(stats["hp"]))
	m["mp"] = clampi(int(m.get("mp", stats["mp"])), 0, int(stats["mp"]))
	return m


## Équipement avec lequel un personnage rejoint l'équipe (bloc « equip » de sa fiche de combat).
func _starting_gear(id: String) -> Dictionary:
	var out := {}
	var gear: Variant = Rules.battle_def(id).get("equip", {})
	if gear is Dictionary:
		for slot: String in gear:
			if SLOTS.has(slot) and Database.item_kind(str(gear[slot])) == "equipment":
				out[slot] = str(gear[slot])
	return out


func _stats(id: String, m: Dictionary) -> Dictionary:
	var out := Rules.stats_at(id, int(m.get("level", 1)))
	var gear: Dictionary = m.get("equip", {})
	for slot: String in gear:
		var mods: Variant = Database.get_item(str(gear[slot])).get("mods", {})
		if mods is Dictionary:
			for key: String in mods:
				out[key] = int(out.get(key, 0)) + int(mods[key])
	for talent: Variant in _array(m.get("talents")):
		var bonus: Variant = Rules.talent_def(id, str(talent)).get("mods", {})
		if bonus is Dictionary:
			for key: String in bonus:
				out[key] = int(out.get(key, 0)) + int(bonus[key])
	out["hp"] = maxi(1, int(out["hp"]))
	out["mp"] = maxi(0, int(out["mp"]))
	out["spd"] = maxi(1, int(out["spd"]))
	return out


## Caractéristiques d'un membre de l'équipe, équipement compris.
func member_stats(id: String) -> Dictionary:
	return _stats(id, member(id))


## Rend tous ses PV et PM à l'équipe (repos à l'auberge).
func heal_party() -> void:
	for id: Variant in party:
		var m := member(str(id))
		var stats := member_stats(str(id))
		m["hp"] = int(stats["hp"])
		m["mp"] = int(stats["mp"])


## Ajoute de l'expérience. Renvoie {} ou, si le niveau monte,
## {"id", "name", "from", "to", "skills": [noms des compétences apprises],
## "points": points de talent gagnés}.
func grant_xp(id: String, amount: int) -> Dictionary:
	var m := member(id)
	var from := int(m["level"])
	m["xp"] = int(m["xp"]) + maxi(0, amount)
	var learned: Array = []
	while int(m["level"]) < Rules.MAX_LEVEL and int(m["xp"]) >= Rules.xp_to_next(int(m["level"])):
		m["xp"] = int(m["xp"]) - Rules.xp_to_next(int(m["level"]))
		m["level"] = int(m["level"]) + 1
		for s: String in Rules.skills_learned_at(id, int(m["level"])):
			learned.append(str(Database.get_skill(s).get("name", s)))
	if int(m["level"]) == from:
		return {}
	var stats := _stats(id, m)
	m["hp"] = int(stats["hp"])   # monter de niveau requinque
	m["mp"] = int(stats["mp"])
	var points := Rules.talent_points_at(int(m["level"])) - Rules.talent_points_at(from)
	if Rules.branches(id).is_empty():
		points = 0
	return {"id": id, "name": Database.get_character_name(id), "from": from, "to": int(m["level"]), "skills": learned, "points": points}


# ----------------------------------------------------------------------- talents
# Un point par niveau gagné (réglé dans game.json). Chaque personnage a deux branches
# (data/talents.json) ; dans une branche, les talents s'apprennent dans l'ordre.

## Identifiants des talents appris par un membre de l'équipe.
func talents_of(id: String) -> Array:
	return member(id)["talents"]


func has_talent(id: String, talent: String) -> bool:
	return talents_of(id).has(talent)


func talent_points_spent(id: String) -> int:
	var spent := 0
	for t: Variant in talents_of(id):
		var def := Rules.talent_def(id, str(t))
		if not def.is_empty():
			spent += Rules.talent_cost(def)
	return spent


## Points de talent qui restent à dépenser.
func talent_points(id: String) -> int:
	if Rules.branches(id).is_empty():
		return 0
	return maxi(0, Rules.talent_points_at(int(member(id)["level"])) - talent_points_spent(id))


## Points à dépenser dans toute l'équipe.
func party_talent_points() -> int:
	var total := 0
	for id: Variant in party:
		total += talent_points(str(id))
	return total


## "learned" (appris), "available" (on peut l'apprendre), "locked" (le précédent de la
## branche manque), "poor" (pas assez de points) ou "unknown".
func talent_state(id: String, talent: String) -> String:
	var def := Rules.talent_def(id, talent)
	if def.is_empty():
		return "unknown"
	if has_talent(id, talent):
		return "learned"
	var need := Rules.talent_requirement(id, talent)
	if need != "" and not has_talent(id, need):
		return "locked"
	if talent_points(id) < Rules.talent_cost(def):
		return "poor"
	return "available"


func learn_talent(id: String, talent: String) -> bool:
	if talent_state(id, talent) != "available":
		return false
	var m := member(id)
	(m["talents"] as Array).append(talent)
	m["specialization"] = specialization(id)
	return true


## Oublie tous les talents d'un personnage et renvoie le nombre de points rendus.
func reset_talents(id: String) -> int:
	var back := talent_points_spent(id)
	var m := member(id)
	m["talents"] = []
	m["specialization"] = ""
	member(id)   # les PV et PM actuels ne dépassent pas les nouveaux maximums
	return back


## Identifiant de la branche où le personnage a mis le plus de points ("" : aucune).
func specialization(id: String) -> String:
	var best := ""
	var best_points := 0
	for b: Dictionary in Rules.branches(id):
		var points := 0
		for t: Dictionary in Rules.branch_talents(b):
			if has_talent(id, str(t.get("id", ""))):
				points += Rules.talent_cost(t)
		if points > best_points:
			best_points = points
			best = str(b.get("id", ""))
	return best


func specialization_name(id: String) -> String:
	var spec := specialization(id)
	for b: Dictionary in Rules.branches(id):
		if str(b.get("id", "")) == spec:
			return str(b.get("name", spec))
	return ""


## Compétences d'un membre de l'équipe : celles de son niveau, puis celles de ses talents.
func member_skills(id: String) -> Array:
	var out := Rules.skills_at(id, int(member(id)["level"]))
	for t: Variant in talents_of(id):
		for s: Variant in _array(Rules.talent_def(id, str(t)).get("skills")):
			if not out.has(str(s)) and not Database.get_skill(str(s)).is_empty():
				out.append(str(s))
	return out


## Effets permanents des talents appris, additionnés : nombres, dictionnaires de nombres
## ("element_boost": {"feu": 0.15}) et listes ("immune": ["sonne"]).
func member_passives(id: String) -> Dictionary:
	var out := {}
	for t: Variant in talents_of(id):
		var passives: Variant = Rules.talent_def(id, str(t)).get("passives", {})
		if not (passives is Dictionary):
			continue
		for key: String in passives:
			var v: Variant = passives[key]
			if v is Dictionary:
				var sums: Dictionary = _dict(out.get(key))
				for sub: String in v:
					sums[sub] = float(sums.get(sub, 0.0)) + float(v[sub])
				out[key] = sums
			elif v is Array:
				var list: Array = _array(out.get(key))
				for x: Variant in v:
					if not list.has(str(x)):
						list.append(str(x))
				out[key] = list
			else:
				out[key] = float(out.get(key, 0.0)) + float(v)
	return out


## Remet d'aplomb les talents d'une sauvegarde : talents disparus des données retirés,
## et tout est rendu si le compte de points ne tombe plus juste.
func _clean_talents(id: String) -> void:
	var m := member(id)
	var kept: Array = []
	for t: Variant in _array(m.get("talents")):
		if not Rules.talent_def(id, str(t)).is_empty() and not kept.has(str(t)):
			kept.append(str(t))
	m["talents"] = kept
	if talent_points_spent(id) > Rules.talent_points_at(int(m["level"])):
		m["talents"] = []
	m["specialization"] = specialization(id)


# ------------------------------------------------------------ inventaire, argent

func add_item(id: String, count: int = 1) -> void:
	var n := int(inventory.get(id, 0)) + count
	if n > 0:
		inventory[id] = n
	else:
		inventory.erase(id)
	refresh_quests()


func item_count(id: String) -> int:
	return int(inventory.get(id, 0))


func add_money(amount: int) -> void:
	money = maxi(0, money + amount)
	refresh_quests()


## Achète un objet. Faux (et rien ne change) si l'argent manque.
func buy(item: String, price: int) -> bool:
	if price < 0 or money < price or Database.get_item(item).is_empty():
		return false
	money -= price
	add_item(item, 1)
	return true


## Prix de rachat d'un objet (0 : invendable).
func sell_price(item: String, ratio: float = 0.5) -> int:
	var price := int(Database.get_item(item).get("price", 0))
	if price <= 0:
		return 0
	return maxi(1, int(floor(price * ratio)))


## Vend un exemplaire. Renvoie la somme reçue (0 si la vente est impossible).
func sell(item: String, ratio: float = 0.5) -> int:
	var gain := sell_price(item, ratio)
	if gain <= 0 or item_count(item) <= 0:
		return 0
	money += gain
	add_item(item, -1)
	return gain


## Vrai si l'objet peut servir depuis le menu, hors combat (il rend des PV ou du mana).
func usable_outside(item: String) -> bool:
	var def := Database.get_item(item)
	if str(def.get("target", "")) != "ally":
		return false
	for fx: Variant in def.get("effects", []):
		if fx is Dictionary and str(fx.get("type", "")) in ["heal", "mana"]:
			return true
	return false


## Utilise un objet sur un membre de l'équipe hors combat. Renvoie le texte de ce qui
## s'est passé, ou "" si l'objet n'aurait eu aucun effet (il n'est alors pas consommé).
func use_item(item: String, target: String) -> String:
	if item_count(item) <= 0 or not usable_outside(item) or not party.has(target):
		return ""
	var def := Database.get_item(item)
	var m := member(target)
	var stats := member_stats(target)
	var parts: Array = []
	for fx: Variant in def.get("effects", []):
		if not (fx is Dictionary):
			continue
		match str(fx.get("type", "")):
			"heal":
				var amount := float(fx.get("power", 0)) + float(stats["hp"]) * float(fx.get("percent", 0.0))
				var gain := mini(int(stats["hp"]) - int(m["hp"]), maxi(1, int(round(amount))))
				if gain > 0:
					m["hp"] = int(m["hp"]) + gain
					parts.append("+%d PV" % gain)
			"mana":
				var gain := mini(int(stats["mp"]) - int(m["mp"]), int(fx.get("power", 0)))
				if gain > 0:
					m["mp"] = int(m["mp"]) + gain
					parts.append("+%d PM" % gain)
	if parts.is_empty():
		return ""
	add_item(item, -1)
	return "%s : %s" % [Database.get_character_name(target), ", ".join(parts)]


# -------------------------------------------------------------------- équipement

func equipped(id: String, slot: String) -> String:
	return str((member(id)["equip"] as Dictionary).get(slot, ""))


func can_equip(id: String, item: String) -> bool:
	var def := Database.get_item(item)
	if str(def.get("kind", "")) != "equipment" or not SLOTS.has(str(def.get("slot", ""))):
		return false
	if Rules.battle_def(id).is_empty():
		return false
	var only: Variant = def.get("for")
	return not (only is Array) or (only as Array).is_empty() or (only as Array).has(id)


## Équipe un objet pris dans le sac ; l'ancien y retourne.
func equip(id: String, item: String) -> bool:
	if not can_equip(id, item) or item_count(item) <= 0:
		return false
	var m := member(id)
	var slot := str(Database.get_item(item).get("slot", ""))
	var old := str((m["equip"] as Dictionary).get(slot, ""))
	(m["equip"] as Dictionary)[slot] = item
	add_item(item, -1)
	if old != "":
		add_item(old, 1)
	member(id)   # recale PV et PM sur les nouveaux maximums
	return true


func unequip(id: String, slot: String) -> bool:
	var m := member(id)
	var old := str((m["equip"] as Dictionary).get(slot, ""))
	if old == "":
		return false
	(m["equip"] as Dictionary).erase(slot)
	add_item(old, 1)
	member(id)
	return true


## Vrai si un objet porté rend insensible au Ramollissement.
func has_firm_gear(id: String) -> bool:
	var gear: Dictionary = member(id)["equip"]
	for slot: String in gear:
		if bool(Database.get_item(str(gear[slot])).get("firm", false)):
			return true
	return false


## Résumé de l'équipe pour le menu de pause.
func party_summary() -> String:
	var lines: Array = []
	for id: Variant in party:
		var m := member(str(id))
		var stats := member_stats(str(id))
		lines.append("%s   Nv %d   PV %d/%d   PM %d/%d" % [
			Database.get_character_name(str(id)), int(m["level"]), int(m["hp"]), int(stats["hp"]), int(m["mp"]), int(stats["mp"])])
	var points := party_talent_points()
	if points > 0:
		lines.append("%d point%s de talent à dépenser (Talents)" % [points, "s" if points > 1 else ""])
	return "\n".join(lines)


func leader() -> String:
	if party.is_empty():
		return str(Database.game.get("player", "glandoulf"))
	return str(party[0])


# ---------------------------------------------------------- drapeaux, conditions

func set_flag(flag: String, value: Variant = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)
	refresh_quests()


func get_flag(flag: String, fallback: Variant = false) -> Variant:
	return flags.get(flag, fallback)


func has_flag(flag: String) -> bool:
	var v: Variant = flags.get(flag, false)
	if v is bool:
		return v
	return v != null


## Évalue une condition du contenu. Plusieurs tests séparés par « & » doivent tous être vrais.
##   "drapeau"        le drapeau est posé            "!drapeau"       il ne l'est pas
##   "item:cale"      au moins un dans le sac        "item:cale:3"    au moins trois
##   "party:sam"      Sam est dans l'équipe          "money:40"       au moins 40 écus
##   "quest:poele"    quête en cours                 "quest_done:poele"  quête terminée
func check(cond: String) -> bool:
	for part: String in cond.split("&"):
		var c := part.strip_edges()
		if c == "":
			continue
		var negate := c.begins_with("!")
		if negate:
			c = c.substr(1).strip_edges()
		if _check_one(c) == negate:
			return false
	return true


func _check_one(c: String) -> bool:
	var bits := c.split(":")
	if bits.size() < 2:
		return has_flag(c)
	match bits[0]:
		"item":
			return item_count(bits[1]) >= (int(bits[2]) if bits.size() > 2 else 1)
		"party":
			return party.has(bits[1])
		"money":
			return money >= int(bits[1])
		"quest":
			return quest_state(bits[1]) == "active"
		"quest_done":
			return quest_state(bits[1]) == "done"
	return has_flag(c)


# ------------------------------------------------------------------------ quêtes

## "" (pas commencée), "active" ou "done".
func quest_state(id: String) -> String:
	return str(quests.get(id, ""))


## Fait démarrer et aboutir les quêtes dont les conditions (data/quests.json) sont
## remplies. Appelée toute seule dès qu'un drapeau, l'équipe ou l'inventaire change.
func refresh_quests(silent: bool = false) -> void:
	if _refreshing:
		return
	_refreshing = true
	var changed := true
	var guard := 0
	while changed and guard < 10:
		changed = false
		guard += 1
		for id: String in Database.quests:
			var q := Database.get_quest(id)
			if quest_state(id) == "":
				var start := str(q.get("start", ""))
				if start != "" and check(start):
					quests[id] = "active"
					changed = true
					if not silent:
						quest_started.emit(id)
			if quest_state(id) == "active":
				var complete := str(q.get("complete", ""))
				if complete != "" and check(complete):
					quests[id] = "done"
					changed = true
					var reward := _grant_reward(q.get("reward"))
					if not silent:
						quest_completed.emit(id, reward)
	_refreshing = false


func _grant_reward(r: Variant) -> Dictionary:
	if not (r is Dictionary):
		return {}
	var reward: Dictionary = r
	money += maxi(0, int(reward.get("money", 0)))
	var items: Variant = reward.get("items", {})
	if items is Dictionary:
		for item: String in items:
			var n := int(inventory.get(item, 0)) + int(items[item])
			if n > 0:
				inventory[item] = n
	var xp := int(reward.get("xp", 0))
	if xp > 0:
		for id: Variant in party:
			grant_xp(str(id), xp)
	return reward


## Texte d'une récompense : « 30 écus, Nœud de cabestan, 30 XP ».
func reward_text(reward: Dictionary) -> String:
	var parts: Array = []
	if int(reward.get("money", 0)) > 0:
		parts.append("%d %s" % [int(reward["money"]), MONEY_NAME])
	var items: Variant = reward.get("items", {})
	if items is Dictionary:
		for item: String in items:
			var label := str(Database.get_item(item).get("name", item))
			parts.append(label if int(items[item]) == 1 else "%s ×%d" % [label, int(items[item])])
	if int(reward.get("xp", 0)) > 0:
		parts.append("%d XP" % int(reward["xp"]))
	return ", ".join(parts)


# -------------------------------------------------------------------- sauvegarde

func to_dict() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"chapter": chapter,
		"flags": flags.duplicate(true),
		"quests": quests.duplicate(true),
		"party": party.duplicate(),
		"roster": roster.duplicate(true),
		"bestiary": bestiary.duplicate(true),
		"inventory": inventory.duplicate(true),
		"money": money,
		"map_id": map_id,
		"spawn_id": spawn_id,
		"player_pos": player_pos.duplicate(),
		"player_facing": player_facing,
		"playtime": playtime,
	}


func from_dict(d: Dictionary) -> bool:
	if not d.has("map_id") or str(d.get("map_id", "")) == "":
		return false
	chapter = str(d.get("chapter", "chapitre_1"))
	flags = _dict(d.get("flags"))
	quests = _dict(d.get("quests"))
	for id: String in quests.keys():
		if not (str(quests[id]) in ["active", "done"]):
			quests.erase(id)
	roster = _dict(d.get("roster"))
	bestiary = _dict(d.get("bestiary"))
	inventory = _dict(d.get("inventory"))
	party = _array(d.get("party"))
	money = int(d.get("money", 0))
	_refreshing = true   # pas de quête qui démarre au milieu du chargement
	if party.is_empty():
		add_to_party(str(Database.game.get("player", "glandoulf")))
	for id: Variant in party:
		member(str(id))   # complète les fiches des anciennes sauvegardes
		_clean_talents(str(id))
	for item: String in inventory.keys():
		inventory[item] = int(inventory[item])
	_refreshing = false
	map_id = str(d.get("map_id", ""))
	spawn_id = str(d.get("spawn_id", ""))
	player_pos = _array(d.get("player_pos"))
	player_facing = str(d.get("player_facing", "down"))
	playtime = float(d.get("playtime", 0.0))
	refresh_quests(true)   # une sauvegarde d'avant les quêtes retrouve son journal, sans fanfare
	return true


func playtime_text() -> String:
	var total := int(playtime)
	return "%dh%02d" % [total / 3600, (total % 3600) / 60]


static func _dict(v: Variant) -> Dictionary:
	if v is Dictionary:
		return (v as Dictionary).duplicate(true)
	return {}


static func _array(v: Variant) -> Array:
	if v is Array:
		return (v as Array).duplicate(true)
	return []
