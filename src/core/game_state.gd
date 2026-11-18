extends Node
## État central de la partie : progression, drapeaux, quêtes, équipe, équipement,
## inventaire, argent, position. La sauvegarde n'est rien d'autre que ce dictionnaire
## écrit sur le disque.

signal flag_changed(flag: String, value: Variant)
signal quest_started(id: String)
signal quest_completed(id: String, reward: Dictionary)

const Rules = preload("res://src/battle/rules.gd")

const SAVE_VERSION := 4
## Emplacements d'équipement. Les identifiants weapon, armor et trinket sont ceux des
## anciennes sauvegardes ; head et trinket2 sont venus ensuite.
const SLOTS := ["weapon", "head", "armor", "trinket", "trinket2"]
const SLOT_NAMES := {"weapon": "Arme", "head": "Couvre-chef", "armor": "Tenue", "trinket": "Babiole", "trinket2": "Seconde babiole"}
## Emplacements qui reçoivent chaque sorte d'objet (champ « slot » d'un objet) : une babiole va dans l'un ou l'autre.
const ITEM_SLOTS := {"weapon": ["weapon"], "head": ["head"], "armor": ["armor"], "trinket": ["trinket", "trinket2"]}
const STAT_NAMES := {"hp": "PV", "mp": "PM", "atk": "Attaque", "def": "Défense", "mag": "Magie", "res": "Résistance", "spd": "Vitesse", "acc": "Précision", "eva": "Esquive", "crit": "Critique", "critdmg": "Dégâts crit."}
const MONEY_NAME := "écus"
const MAX_ACTIVE := 4            # une équipe ne se bat jamais à plus de quatre
const RESERVE_XP := 0.0          # part d'expérience de combat d'un réserviste : aucune (règle de l'auteur)

var chapter: String = "chapitre_1"
var flags: Dictionary = {}
var quests: Dictionary = {}      # id de quête -> "active" ou "done" (absente : pas commencée)
var party: Array = []            # ids de tous les personnages recrutés, dans l'ordre : les MAX_ACTIVE premiers se battent, les autres sont en réserve
var bench: Array = []            # compagnons séparés du groupe (chapitre 5 : l'équipe se scinde) ; leurs fiches restent dans le registre
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
	bench = []
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
## Renvoie "active" si la recrue prend place parmi les combattants, "reserve" si l'équipe
## de quatre est déjà pleine.
func add_to_party(id: String, catch_up: bool = false) -> String:
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
	return "active" if is_active(id) else "reserve"


## Scinde ou réunit le groupe (action de dialogue `groupe:a,b,c`). Les personnages listés
## forment l'équipe, dans cet ordre (le premier mène) ; les recrutés qui n'y sont pas passent
## sur le banc, fiche intacte (niveau, expérience, équipement, talents). Un personnage qui
## entre dans l'équipe et que son niveau laisse en retard sur ceux qui y étaient déjà les
## rattrape (il ne gagne pas d'expérience pendant son absence). Renvoie faux si rien de valable.
func set_group(ids: Array) -> bool:
	var next: Array = []
	for id: Variant in ids:
		var sid := str(id)
		if not next.has(sid) and not Rules.battle_def(sid).is_empty():
			next.append(sid)
	if next.is_empty():
		return false
	var top := 0
	for id: Variant in next:
		if party.has(id):
			top = maxi(top, int(member(str(id))["level"]))
	var away: Array = []
	for id: Variant in party + bench:
		if not next.has(id) and not away.has(id):
			away.append(id)
	for id: Variant in next:
		if not party.has(id):
			var m := member(str(id))
			if top > int(m["level"]):
				m["level"] = top
				m["xp"] = 0
				m.erase("hp")
				m.erase("mp")
				member(str(id))
	party = next
	bench = away
	refresh_quests()
	return true


## Les personnages qui se battent : les quatre premiers de la liste.
func active_party() -> Array:
	return party.slice(0, MAX_ACTIVE)


## Les recrutés qui ne se battent pas (mais voyagent avec le groupe et gagnent de l'expérience).
func reserve_party() -> Array:
	return party.slice(MAX_ACTIVE)


func is_active(id: String) -> bool:
	return party.find(id) in range(MAX_ACTIVE)


func is_reserve(id: String) -> bool:
	return party.find(id) >= MAX_ACTIVE


## Échange un combattant et un réserviste : chacun prend la place de l'autre. Refusé si les
## deux sont du même côté, si l'un est inconnu, ou si l'on retire le meneur (le héros du
## jeu garde la tête de l'équipe, c'est lui que la caméra suit).
func swap_members(a: String, b: String) -> bool:
	var ia := party.find(a)
	var ib := party.find(b)
	if ia < 0 or ib < 0 or (ia < MAX_ACTIVE) == (ib < MAX_ACTIVE):
		return false
	if mini(ia, ib) == 0:
		return false
	party[ia] = b
	party[ib] = a
	return true


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
	out["acc"] = maxi(0, int(out["acc"]))
	out["eva"] = maxi(0, int(out["eva"]))
	out["crit"] = maxi(0, int(out["crit"]))
	out["critdmg"] = maxi(100, int(out["critdmg"]))
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
	var gear: Dictionary = member(id)["equip"]
	for slot: String in SLOTS:   # une pièce d'équipement peut donner des compétences (champ « skills » de l'objet)
		if gear.has(slot):
			for s: Variant in _array(Database.get_item(str(gear[slot])).get("skills")):
				if not out.has(str(s)) and not Database.get_skill(str(s)).is_empty():
					out.append(str(s))
	return out


## Effets permanents des talents appris, additionnés : nombres, dictionnaires de nombres
## ("element_boost": {"feu": 0.15}) et listes ("immune": ["sonne"]).
func member_passives(id: String) -> Dictionary:
	var out := {}
	var sources: Array = []
	for t: Variant in talents_of(id):
		sources.append(Rules.talent_def(id, str(t)).get("passives", {}))
	var gear: Dictionary = member(id)["equip"]
	for slot: String in SLOTS:   # l'équipement porté joue comme un talent (champ « passives » de l'objet)
		if gear.has(slot):
			sources.append(Database.get_item(str(gear[slot])).get("passives", {}))
	for passives: Variant in sources:
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


## Emplacements où cet objet peut aller (vide si ce n'est pas de l'équipement).
static func slots_for(item: String) -> Array:
	var def := Database.get_item(item)
	if str(def.get("kind", "")) != "equipment":
		return []
	return (ITEM_SLOTS.get(str(def.get("slot", "")), []) as Array).duplicate()


## Vrai si ce personnage peut porter cet objet : un porteur nommé (« for »), sinon le genre
## de l'objet (« type ») doit figurer dans la liste de son emplacement (bloc « gear » de sa fiche).
func can_equip(id: String, item: String) -> bool:
	var def := Database.get_item(item)
	if slots_for(item).is_empty():
		return false
	var battle := Rules.battle_def(id)
	if battle.is_empty():
		return false
	var only: Variant = def.get("for")
	if only is Array and not (only as Array).is_empty():
		return (only as Array).has(id)
	var type := str(def.get("type", ""))
	var gear: Variant = battle.get("gear", {})
	if type != "" and gear is Dictionary:
		var allowed: Variant = (gear as Dictionary).get(str(def.get("slot", "")), [])
		if allowed is Array and not (allowed as Array).is_empty():
			return (allowed as Array).has(type)
	return true


## Qui porte cet objet en ce moment : [{"who": id, "slot": emplacement}].
func worn_by(item: String) -> Array:
	var out: Array = []
	for id: Variant in party:
		var gear: Dictionary = member(str(id))["equip"]
		for slot: String in SLOTS:
			if str(gear.get(slot, "")) == item:
				out.append({"who": str(id), "slot": slot})
	return out


## Emplacement où irait cet objet pour ce personnage : celui demandé s'il convient, sinon la
## première place libre, à défaut la première place qui convient ("" si l'objet n'est pas de l'équipement).
func slot_for(id: String, item: String, slot: String = "") -> String:
	var fits := slots_for(item)
	if fits.is_empty():
		return ""
	if fits.has(slot):
		return slot
	for s: String in fits:
		if equipped(id, s) == "":
			return s
	return str(fits[0])


## Caractéristiques qu'aurait ce personnage avec cet objet à la place de ce qu'il porte
## (item vide : l'emplacement `slot` est vidé). Rien n'est modifié.
func stats_with(id: String, item: String, slot: String = "") -> Dictionary:
	var m: Dictionary = member(id).duplicate(true)
	var gear: Dictionary = m["equip"]
	if item == "":
		gear.erase(slot)
	else:
		gear[slot_for(id, item, slot)] = item
	return _stats(id, m)


## Équipe un objet pris dans le sac ; l'ancien y retourne. Sans emplacement précisé, une babiole
## prend la première place libre (à défaut, la première).
func equip(id: String, item: String, slot: String = "") -> bool:
	if not can_equip(id, item) or item_count(item) <= 0:
		return false
	var target := slot_for(id, item, slot)
	var m := member(id)
	var old := str((m["equip"] as Dictionary).get(target, ""))
	(m["equip"] as Dictionary)[target] = item
	add_item(item, -1)
	if old != "":
		add_item(old, 1)
	member(id)   # recale PV et PM sur les nouveaux maximums
	return true


## Personnages recrutables (ceux qui ont des talents) : sert à dire qui peut porter quoi.
func playable_ids() -> Array:
	var out: Array = []
	for id: String in Database.characters:
		if not Rules.battle_def(id).is_empty() and not Rules.branches(id).is_empty():
			out.append(id)
	return out


func unequip(id: String, slot: String) -> bool:
	var m := member(id)
	var old := str((m["equip"] as Dictionary).get(slot, ""))
	if old == "":
		return false
	(m["equip"] as Dictionary).erase(slot)
	add_item(old, 1)
	member(id)
	return true


## Remet d'aplomb l'équipement d'une sauvegarde : objet disparu des données retiré, objet qui
## ne va pas à son emplacement (ou qu'un personnage ne peut plus porter) rendu au sac.
func _clean_equipment(id: String) -> void:
	var gear: Dictionary = member(id)["equip"]
	for slot: String in gear.keys():
		var item := str(gear[slot])
		if Database.get_item(item).is_empty():
			gear.erase(slot)
		elif not slots_for(item).has(slot) or not can_equip(id, item):
			gear.erase(slot)
			add_item(item, 1)


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
	for id: Variant in active_party():
		var m := member(str(id))
		var stats := member_stats(str(id))
		lines.append("%s   Nv %d   PV %d/%d   PM %d/%d" % [
			Database.get_character_name(str(id)), int(m["level"]), int(m["hp"]), int(stats["hp"]), int(m["mp"]), int(stats["mp"])])
	if not reserve_party().is_empty():
		var names: Array = []
		for id: Variant in reserve_party():
			names.append(Database.get_character_name(str(id)))
		lines.append("En réserve : " + ", ".join(names))
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
		"bench": bench.duplicate(),
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


func from_dict(d_in: Dictionary) -> bool:
	var d: Dictionary = migrate_old_ids(d_in)   # anciens noms de personnages -> nouveaux
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
	bench = _array(d.get("bench"))
	money = int(d.get("money", 0))
	_refreshing = true   # pas de quête qui démarre au milieu du chargement
	if party.is_empty():
		add_to_party(str(Database.game.get("player", "glandoulf")))
	for id: Variant in party + bench:
		member(str(id))   # complète les fiches des anciennes sauvegardes
		_clean_talents(str(id))
		_clean_equipment(str(id))
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


# Anciens identifiants de personnages (avant la décision 62) et leurs remplaçants.
const OLD_IDS := {"fripon": "froton", "pepine": "pepin", "legolasse": "digoulasse", "gimlette": "grimli"}


# Reprise des sauvegardes : remplace les anciens identifiants partout où ils apparaissent
# (équipe, fiches, drapeaux, quêtes, bestiaire...), dans les clés comme dans les valeurs.
static func migrate_old_ids(v: Variant) -> Variant:
	if v is Dictionary:
		var out := {}
		for k: Variant in (v as Dictionary).keys():
			out[migrate_old_ids(k)] = migrate_old_ids((v as Dictionary)[k])
		return out
	if v is Array:
		var arr := []
		for e: Variant in (v as Array):
			arr.append(migrate_old_ids(e))
		return arr
	if v is String:
		var s: String = v
		for old: String in OLD_IDS.keys():
			s = s.replace(old, str(OLD_IDS[old]))
		return s
	return v


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
