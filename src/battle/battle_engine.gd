extends RefCounted
## Moteur de combat au tour par tour : pures règles, aucun affichage.
##
## La scène de combat lui demande qui joue (next_actor), lui soumet une action
## (perform) et reçoit en retour une liste d'ÉVÉNEMENTS à mettre en scène :
##   {"type": "damage", "target": Combatant, "amount": 12, "weak": true, ...}
## Comme il ne touche à aucun nœud, il se teste sans fenêtre (tests/smoke_test.gd).
##
## Ordre des tours : chaque combattant a un temps d'attente de 1000 / vitesse.
## Celui dont l'attente est la plus courte joue, puis repart pour un tour.
## Un personnage deux fois plus rapide joue donc deux fois plus souvent.

const Combatant = preload("res://src/battle/combatant.gd")
const Rules = preload("res://src/battle/rules.gd")
const Carnet = preload("res://src/core/carnet.gd")

const WEAK_MULT := 1.5
const CRIT_MULT := 1.5
const CRIT_CHANCE := 0.06
const FLEE_CHANCE := 0.75
const MIN_HIT := 0.1            # même face à une esquive énorme, un coup sur dix touche
const MAX_CRIT := 0.8

# Élan (voir FORMAT_DONNEES.md, « Points d'élan »)
const ELAN_START := 1           # points d'élan de chaque héros au début du combat
const ELAN_GAIN := 1            # points gagnés au début de chacun de ses tours...
const ELAN_MAX := 5             # ...jusqu'à cette réserve
const ELAN_COMMIT_MAX := 3      # points qu'on peut engager en un tour
const ELAN_POWER := [1.0, 1.5, 2.0, 2.5]   # multiplicateur des dégâts d'une compétence selon les points engagés
const ELAN_HEAL := [1.0, 1.3, 1.6, 1.9]    # multiplicateur d'un soin
const ELAN_STATUS := 0.2        # chance de plus, par point, d'infliger un état à l'ennemi (soutien : +1 tour par point)
const ELAN_AUTO_BIG := 600      # le jeu automatique garde son élan, sauf contre un ennemi brisé ou de plus de PV que cela

var encounter: Dictionary = {}
var party: Array = []
var enemies: Array = []
var inventory: Dictionary = {}
var revealed: Dictionary = {}   # id d'ennemi -> faiblesses déjà découvertes
var rng := RandomNumberGenerator.new()
var guest := false              # équipe imposée par la rencontre (prologue) : rien n'est conservé
var can_flee := true
var result := ""                # "", "victory", "defeat", "fled"
var can_act := true             # renseigné par start_turn
var turn_count := 0
var party_turns := 0
var softness := 0.0             # Ramollissement du lieu : part des dégâts physiques perdue
var stolen := 0                 # écus fauchés pendant le combat (effet « steal »)
var _countering := false        # une riposte n'appelle pas de riposte
var _boost := 0                 # points d'élan engagés dans l'action en cours
var _boost_def: Dictionary = {}  # la compétence qui les reçoit (vide : attaque de base)
var diff: Dictionary = {}        # niveau de difficulté du combat (data/carnet.json) : PV et dégâts des ennemis, gains
var tally: Dictionary = {}       # bilan du combat pour le Carnet (dégâts, soins, plus gros coup...) ; voir Carnet.absorb
var _absorbed := false
var _cur_name := ""              # nom de l'action en cours (pour « plus gros coup »)


func setup(p_encounter: Dictionary, p_seed: int = -1) -> void:
	encounter = p_encounter
	diff = Carnet.difficulty_def()
	tally = {"dealt": 0, "taken": 0, "heal": 0, "crits": 0, "items": 0, "ko": {}, "skills": {}, "best": {}, "immune": {}, "loot": {}, "analyzed": {}}
	_absorbed = false
	if p_seed >= 0:
		rng.seed = p_seed
	else:
		rng.randomize()
	can_flee = bool(encounter.get("flee", true))
	softness = clampf(float(encounter.get("ramollissement", 0.0)), 0.0, 0.9)
	revealed = GameState.bestiary.duplicate(true)
	party = []
	enemies = []
	var forced: Variant = encounter.get("party")
	if forced is Array and not (forced as Array).is_empty():
		guest = true
		for e: Variant in forced:
			if e is Dictionary:
				party.append(_make_member(str(e.get("id", "")), int(e.get("level", 1)), -1, -1))
		var inv: Variant = encounter.get("inventory", {})
		inventory = (inv as Dictionary).duplicate(true) if inv is Dictionary else {}
	else:
		guest = false
		for id: Variant in GameState.active_party():
			var m: Dictionary = GameState.member(str(id))
			party.append(_make_member(str(id), int(m.get("level", 1)), int(m.get("hp", -1)), int(m.get("mp", -1)), true))
		inventory = GameState.inventory.duplicate(true)
	var counts := {}
	var list: Array = encounter.get("enemies", [])
	for id: Variant in list:
		counts[str(id)] = int(counts.get(str(id), 0)) + 1
	var seen := {}
	for id: Variant in list:
		var sid := str(id)
		seen[sid] = int(seen.get(sid, 0)) + 1
		var c := _make_enemy(sid)
		c.key = "%s#%d" % [sid, int(seen[sid])]
		if int(counts[sid]) > 1:
			c.name = "%s %s" % [c.name, "ABCDEFGH"[int(seen[sid]) - 1]]
		enemies.append(c)
	for c: Combatant in party:
		c.elan = ELAN_START
	for c: Combatant in all():
		c.wait = 1000.0 / c.speed()
		if c.side == "enemy":
			c.wait *= rng.randf_range(1.0, 1.08)
		else:
			c.wait *= 1.0 - clampf(c.passive("initiative"), 0.0, 0.9)


func _make_member(id: String, level: int, hp: int, mp: int, geared: bool = false) -> Combatant:
	var c := Combatant.new()
	var def := Rules.battle_def(id)
	c.key = id
	c.source = id
	c.name = Database.get_character_name(id)
	c.side = "party"
	c.level = level
	c.base = Rules.stats_at(id, level)
	if geared:   # membre de la vraie équipe : son équipement compte
		c.base = GameState.member_stats(id)
		c.firm = GameState.has_firm_gear(id)
		c.passives = GameState.member_passives(id)
		c.immune = _strings(c.passives.get("immune", []))
	c.hp = c.max_hp() if hp < 0 else clampi(hp, 0, c.max_hp())
	c.mp = c.max_mp() if mp < 0 else clampi(mp, 0, c.max_mp())
	if c.hp <= 0:
		c.hp = 1   # personne ne commence un combat à terre
	c.skills = GameState.member_skills(id) if geared else Rules.skills_at(id, level)
	c.element = str(def.get("element", "contondant"))
	c.attack_name = str(def.get("attack_name", "Attaque"))
	c.attack_anim = str(def.get("attack_anim", ""))
	c.sprite = {"character": id}
	c.data = def
	return c


func _make_enemy(id: String) -> Combatant:
	var c := Combatant.new()
	var def := Database.get_enemy(id)
	c.source = id
	c.name = str(def.get("name", id))
	c.side = "enemy"
	var stats: Variant = def.get("stats", {})
	c.base = (stats as Dictionary).duplicate() if stats is Dictionary else {}
	var hp_mult := float(diff.get("enemy_hp", 1.0))
	if hp_mult != 1.0:   # difficulté : les données de l'ennemi ne bougent pas, seul son exemplaire du combat
		c.base["hp"] = maxi(1, int(round(float(c.base.get("hp", 1)) * hp_mult)))
	c.hp = c.max_hp()
	c.mp = 9999
	c.element = str(def.get("element", "contondant"))
	c.attack_name = str(def.get("attack_name", "Attaque"))
	c.attack_anim = str(def.get("attack_anim", ""))
	c.weak = _strings(def.get("weak", []))
	c.immune = _strings(def.get("immune", []))
	c.shield_max = int(def.get("shield", 0))
	c.shield = c.shield_max
	var ai_list: Variant = def.get("ai", [])
	c.ai = ai_list if ai_list is Array else []
	var sp: Variant = def.get("sprite", {})
	c.sprite = sp if sp is Dictionary else {}
	c.data = def
	c.xp = int(def.get("xp", 0))
	c.money = int(def.get("money", 0))
	var dr: Variant = def.get("drops", [])
	c.drops = dr if dr is Array else []
	return c


static func _strings(v: Variant) -> Array:
	var out: Array = []
	if v is Array:
		for s: Variant in v:
			out.append(str(s))
	return out


# ------------------------------------------------------------------ consultation

func all() -> Array:
	return party + enemies


func side_of(side: String) -> Array:
	return party if side == "party" else enemies


func living(side: String) -> Array:
	var out: Array = []
	for c: Combatant in side_of(side):
		if c.alive():
			out.append(c)
	return out


func fallen(side: String) -> Array:
	var out: Array = []
	for c: Combatant in side_of(side):
		if not c.alive():
			out.append(c)
	return out


func foes_of(actor: Combatant) -> String:
	return "enemy" if actor.side == "party" else "party"


## Faiblesses connues du joueur pour cet ennemi.
func known_weak(c: Combatant) -> Array:
	var v: Variant = revealed.get(c.source, [])
	return v if v is Array else []


## Définition complète d'une action : attaque de base, compétence ou objet.
func action_def(actor: Combatant, action: Dictionary) -> Dictionary:
	match str(action.get("type", "")):
		"attack":
			return {
				"name": actor.attack_name, "target": "enemy", "cost": 0, "anim": actor.attack_anim,
				"effects": [{"type": "damage", "stat": "atk", "power": 100, "element": actor.element}],
			}
		"skill":
			return Database.get_skill(str(action.get("id", "")))
		"item":
			return Database.get_item(str(action.get("id", "")))
	return {}


func skill_cost(skill_id: String) -> int:
	return int(Database.get_skill(skill_id).get("cost", 0))


func can_use_skill(actor: Combatant, skill_id: String) -> bool:
	return actor.side == "enemy" or actor.mp >= skill_cost(skill_id)


## Cibles possibles pour un type de ciblage, du point de vue de l'acteur.
func candidates(actor: Combatant, target_kind: String) -> Array:
	match target_kind:
		"enemy", "all_enemies":
			return living(foes_of(actor))
		"ally", "all_allies":
			return living(actor.side)
		"ally_ko":
			return fallen(actor.side)
		"self":
			return [actor]
	return []


static func is_group(target_kind: String) -> bool:
	return target_kind in ["all_enemies", "all_allies", "self"]


# ------------------------------------------------------------- ordre des tours

func _first(list: Array, waits: Dictionary) -> Combatant:
	var best: Combatant = null
	for c: Combatant in list:
		if not c.alive():
			continue
		if best == null or float(waits[c.key]) < float(waits[best.key]) - 0.0001:
			best = c
	return best


## Fait avancer le temps jusqu'au prochain tour et renvoie celui qui joue.
func next_actor() -> Combatant:
	var waits := {}
	for c: Combatant in all():
		waits[c.key] = c.wait
	var actor := _first(all(), waits)
	if actor == null:
		return null
	var w := actor.wait
	for c: Combatant in all():
		if c.alive():
			c.wait -= w
	return actor


## Les n prochains à jouer après « current » (qui est en train de jouer).
func preview(n: int, current: Combatant = null) -> Array:
	var waits := {}
	for c: Combatant in all():
		waits[c.key] = c.wait
	if current != null:
		waits[current.key] = float(waits[current.key]) + 1000.0 / current.speed()
	var out: Array = []
	for _i in n:
		var c := _first(all(), waits)
		if c == null:
			break
		out.append(c)
		var w: float = waits[c.key]
		for o: Combatant in all():
			if o.alive():
				waits[o.key] = float(waits[o.key]) - w
		waits[c.key] = 1000.0 / c.speed()
	return out


# ------------------------------------------------------------------- un tour

## Début de tour : poison, sommeil... Renseigne can_act.
func start_turn(actor: Combatant) -> Array:
	var events: Array = []
	can_act = true
	actor.defending = false
	for id: String in actor.statuses.keys():
		var st := Database.get_status(id)
		var dot := float(st.get("dot", 0.0))
		if dot > 0.0 and actor.alive():
			var amount := maxi(1, int(round(actor.max_hp() * dot)))
			actor.hp = maxi(0, actor.hp - amount)
			events.append({"type": "damage", "target": actor, "amount": amount, "dot": true, "status": id})
			if not actor.alive():
				_ko(actor, events)
	if not actor.alive():
		can_act = false
		_check_end()
		return events
	# Élan : un point par tour, sauf après un tour où l'on en a engagé.
	if actor.side == "party":
		if actor.elan_rest:
			actor.elan_rest = false
		elif actor.elan < ELAN_MAX:
			actor.elan = mini(ELAN_MAX, actor.elan + ELAN_GAIN)
			events.append({"type": "elan", "target": actor, "amount": ELAN_GAIN})
	# Talents de récupération : ils jouent même si le personnage dort.
	var regen_hp := actor.passive("regen_hp")
	if regen_hp > 0.0 and actor.hp < actor.max_hp():
		var back := mini(actor.max_hp() - actor.hp, maxi(1, int(round(actor.max_hp() * regen_hp))))
		actor.hp += back
		events.append({"type": "heal", "target": actor, "amount": back})
	var regen_mp := int(actor.passive("regen_mp"))
	if regen_mp > 0 and actor.mp < actor.max_mp():
		var back_mp := mini(actor.max_mp() - actor.mp, regen_mp)
		actor.mp += back_mp
		events.append({"type": "mana", "target": actor, "amount": back_mp})
	var skip := actor.skipping_status()
	if skip != "":
		can_act = false
		actor.next_skill = ""   # un coup annoncé est interrompu : bouclier brisé, étourdissement, sommeil
		events.append({"type": "skip", "target": actor, "status": id_text(skip)})
	if actor.side == "party" and can_act:
		party_turns += 1
	return events


static func id_text(status_id: String) -> String:
	var st := Database.get_status(status_id)
	return str(st.get("skip_text", str(st.get("name", status_id)).to_lower()))


## Fin de tour : les états s'usent, puis le combattant repart pour un tour d'attente.
func end_turn(actor: Combatant) -> Array:
	var events: Array = []
	turn_count += 1
	if actor.alive():
		for id: String in actor.statuses.keys():
			var entry: Dictionary = actor.statuses[id]
			if bool(entry.get("fresh", false)):
				entry["fresh"] = false
				continue
			entry["turns"] = int(entry.get("turns", 1)) - 1
			if int(entry["turns"]) <= 0:
				actor.statuses.erase(id)
				events.append({"type": "status_end", "target": actor, "id": id})
				if id == "ebranle":
					actor.shield = actor.shield_max
					events.append({"type": "recover", "target": actor})
		actor.wait += 1000.0 / actor.speed()
	return events


## Exécute une action : {"type": "attack"|"skill"|"item"|"defend"|"flee", "id": ..., "target": Combatant}.
func perform(actor: Combatant, action: Dictionary) -> Array:
	var events: Array = []
	var type := str(action.get("type", "attack"))
	if type == "defend":
		actor.defending = true
		var gain := mini(actor.max_mp() - actor.mp, maxi(1, int(round(actor.max_mp() * 0.1))))
		if actor.side == "enemy":
			gain = 0
		actor.mp += gain
		events.append({"type": "defend", "target": actor, "mana": gain})
		return events
	if type == "flee":
		var ok := can_flee and rng.randf() < FLEE_CHANCE
		events.append({"type": "flee", "actor": actor, "ok": ok})
		if ok:
			result = "fled"
		return events

	var def := action_def(actor, action)
	if def.is_empty():
		type = "attack"
		def = action_def(actor, {"type": "attack"})
	if type == "skill":
		if not can_use_skill(actor, str(action.get("id", ""))):
			type = "attack"
			def = action_def(actor, {"type": "attack"})
		elif actor.side == "party":
			actor.mp -= int(def.get("cost", 0))
			_tally_skill(actor, str(action.get("id", "")))
	elif type == "item":
		var item_id := str(action.get("id", ""))
		if int(inventory.get(item_id, 0)) <= 0:
			return events
		inventory[item_id] = int(inventory[item_id]) - 1
		if int(inventory[item_id]) <= 0:
			inventory.erase(item_id)
		if actor.side == "party":
			tally["items"] = int(tally["items"]) + 1

	_cur_name = str(def.get("name", ""))
	# Élan engagé : seulement pour une attaque ou une compétence qui en tire parti.
	var elan_n := 0
	if actor.side == "party" and (type == "attack" or type == "skill"):
		var want := clampi(int(action.get("elan", 0)), 0, mini(ELAN_COMMIT_MAX, actor.elan))
		if want > 0 and elan_kind(actor, {"type": type, "id": str(action.get("id", ""))}) != "":
			elan_n = want
			actor.elan -= want
			actor.elan_rest = true
	var kind := str(def.get("target", "enemy"))
	var targets: Array = []
	var pool := candidates(actor, kind)
	if is_group(kind):
		targets = pool
	else:
		var wanted: Variant = action.get("target")
		if wanted != null and pool.has(wanted):
			targets = [wanted]
		elif not pool.is_empty():
			targets = [pool[rng.randi() % pool.size()]]
	var effects: Array = def.get("effects", [])
	var element := ""
	for fx: Variant in effects:
		if fx is Dictionary and str(fx.get("type", "")) == "damage":
			element = str(fx.get("element", actor.element))
	# animation : celle que nomme l'action, sinon celle qui porte son identifiant
	var anim := str(def.get("anim", ""))
	if anim == "" and type != "attack":
		anim = str(action.get("id", ""))
	events.append({"type": "cast", "actor": actor, "name": str(def.get("name", "")), "kind": type, "element": element, "targets": targets, "anim": anim, "elan": elan_n})
	if targets.is_empty():
		events.append({"type": "fizzle", "actor": actor})
		return events
	_boost = elan_n
	_boost_def = def if type == "skill" else {}
	var hits := 1 + elan_n if type == "attack" else 1   # l'attaque de base frappe une fois de plus par point d'élan
	for target: Combatant in targets:
		for h in hits:
			if not actor.alive() or (h > 0 and not target.alive()):
				break   # mis à terre par une riposte, ou cible déjà tombée avant un coup de plus
			if h > 0:   # coup suivant : l'animation se rejoue, sans annoncer le nom
				events.append({"type": "cast", "actor": actor, "name": "", "kind": type, "element": element, "targets": [target], "anim": anim, "elan": elan_n, "again": true})
			for fx: Variant in effects:
				if fx is Dictionary:
					_apply(actor, target, fx, events)
	_boost = 0
	_boost_def = {}
	_check_end()
	return events


## Ce que l'élan apporte à une action de héros : "hits" (attaque de base : un coup de plus par point),
## "power" (compétence offensive), "heal" (soin), "support" (état : plus sûr ou plus long), ou "" (rien :
## objet, défense, fuite, compétence sans effet à amplifier ou marquée « elan »: false).
func elan_kind(actor: Combatant, action: Dictionary) -> String:
	if actor.side != "party":
		return ""
	var type := str(action.get("type", "attack"))
	if type == "attack":
		return "hits"
	if type != "skill":
		return ""
	var def := Database.get_skill(str(action.get("id", "")))
	if def.is_empty() or def.get("elan", true) == false:
		return ""
	if _has_effect(def, "damage"):
		return "power"
	if _has_effect(def, "heal"):
		return "heal"
	if _has_effect(def, "status"):
		return "support"
	return ""


## Multiplicateur d'une compétence pour n points engagés (champ facultatif « elan_scale » : liste de
## quatre valeurs, pour les dégâts comme pour les soins).
func elan_mult(def: Dictionary, n: int, heal: bool = false) -> float:
	var table: Array = ELAN_HEAL if heal else ELAN_POWER
	var own: Variant = def.get("elan_scale")
	if own is Array and (own as Array).size() > ELAN_COMMIT_MAX:
		table = own
	return float(table[clampi(n, 0, ELAN_COMMIT_MAX)])


## Aperçu d'une action de héros sur une cible, sans hasard ni critique (les mêmes règles que `_apply`) :
## {"kind": "damage"|"heal"|"", "min", "max" (par coup), "hits", "weak" (faiblesse CONNUE du joueur seulement :
## une faiblesse qu'il n'a pas découverte n'est jamais trahie), "resist", "hit" (chance de toucher, 0..1), "lethal"}.
## `action` est celle qu'on passerait à perform, avec son élan.
func estimate(actor: Combatant, action: Dictionary, target: Combatant) -> Dictionary:
	var out := {"kind": "", "min": 0, "max": 0, "hits": 1, "weak": false, "resist": false, "hit": 1.0, "lethal": false}
	var def := action_def(actor, action)
	if def.is_empty() or target == null:
		return out
	var type := str(action.get("type", "attack"))
	var n := 0
	if actor.side == "party" and (type == "attack" or type == "skill") and elan_kind(actor, {"type": type, "id": str(action.get("id", ""))}) != "":
		n = clampi(int(action.get("elan", 0)), 0, mini(ELAN_COMMIT_MAX, actor.elan))
	var boost := elan_mult(def, n) if (n > 0 and type == "skill") else 1.0
	if type == "attack":
		out["hits"] = 1 + n
	var known := known_weak(target) if target.side == "enemy" else target.weak
	var lo := 0.0
	var hi := 0.0
	var chance := 1.0
	for fx: Variant in def.get("effects", []):
		if not (fx is Dictionary):
			continue
		match str(fx.get("type", "")):
			"damage":
				if target.side == actor.side:
					continue
				out["kind"] = "damage"
				var element := str(fx.get("element", actor.element))
				lo += maxf(1.0, _expected_damage(actor, target, fx, boost, 0.9, known))
				hi += maxf(1.0, _expected_damage(actor, target, fx, boost, 1.1, known))
				if known.has(element) and target.weak.has(element):
					out["weak"] = true
				if target.passive("guard") > 0.0 or target.passive("resist", element) > 0.0:
					out["resist"] = true
				if str(fx.get("stat", "atk")) == "atk":
					var evade := target.status_value("evade")
					chance = minf(chance, clampf((actor.stat("acc") - target.stat("eva")) / 100.0, MIN_HIT, 1.0) * (1.0 - evade))
			"heal":
				if out["kind"] == "":
					out["kind"] = "heal"
					var amount := float(fx.get("power", 0)) + target.max_hp() * float(fx.get("percent", 0.0))
					if fx.has("stat"):
						amount += actor.stat(str(fx["stat"])) * 1.5
					amount *= 1.0 + actor.passive("heal_boost")
					if n > 0 and actor.side == "party":
						amount *= elan_mult(def, n, true)
					var gain := mini(target.max_hp() - target.hp, maxi(1, int(round(amount))))
					lo = float(gain)
					hi = float(gain)
	out["min"] = int(round(lo))
	out["max"] = int(round(hi))
	out["hit"] = chance
	out["lethal"] = out["kind"] == "damage" and int(out["min"]) * int(out["hits"]) >= target.hp and chance >= 1.0
	return out


## Un coup sans hasard : `factor` remplace le tirage de 0,9 à 1,1 ; ni critique ni esquive. `known` : faiblesses prises en compte.
func _expected_damage(actor: Combatant, target: Combatant, fx: Dictionary, boost: float, factor: float, known: Array) -> float:
	var stat_key := str(fx.get("stat", "atk"))
	var element := str(fx.get("element", actor.element))
	var att := actor.stat(stat_key)
	var dfn := target.stat("def" if stat_key == "atk" else "res")
	var amount := (att * 2.0 * float(fx.get("power", 100)) / 100.0 + float(fx.get("flat", 0))) * boost - dfn
	amount *= factor
	if stat_key == "atk" and softness > 0.0 and not actor.is_firm():
		amount *= 1.0 - softness
	if known.has(element) and target.weak.has(element):
		amount *= WEAK_MULT
	amount *= 1.0 + actor.passive("element_boost", element)
	if target.afflicted():
		amount *= 1.0 + actor.passive("vs_afflicted")
	amount *= 1.0 + actor.passive("fury") * (1.0 - float(actor.hp) / actor.max_hp())
	amount *= maxf(0.2, 1.0 - (0.0 if bool(fx.get("ignore_guard", false)) else target.passive("guard")))
	amount *= maxf(0.2, 1.0 - target.passive("resist", element))
	amount *= target.vulnerability()
	if target.defending:
		amount *= 0.5
	if actor.side == "enemy" and target.side == "party":
		amount *= float(diff.get("enemy_dmg", 1.0))
	return amount


## Multiplicateur de dégâts dû à l'élan engagé (1 pour l'attaque de base, qui frappe plusieurs fois).
func _damage_boost(actor: Combatant, _fx: Dictionary) -> float:
	if _boost <= 0 or actor.side != "party" or _boost_def.is_empty():
		return 1.0
	return elan_mult(_boost_def, _boost)


func _apply(actor: Combatant, target: Combatant, fx: Dictionary, events: Array) -> void:
	var type := str(fx.get("type", ""))
	if type == "revive":
		if not target.alive():
			target.hp = maxi(1, int(round(target.max_hp() * float(fx.get("percent", 0.5)))))
			target.wait = 1000.0 / target.speed()
			events.append({"type": "revive", "target": target, "amount": target.hp})
		return
	if not target.alive():
		return
	match type:
		"damage":
			var stat_key := str(fx.get("stat", "atk"))
			var element := str(fx.get("element", actor.element))
			# Un état comme « Enfumé » peut faire rater un coup physique.
			var evade := target.status_value("evade")
			if evade > 0.0 and stat_key == "atk" and target.side != actor.side and rng.randf() < evade:
				events.append({"type": "miss", "target": target})
				return
			# Précision contre esquive, pour les coups physiques : touche avec (précision − esquive) %.
			# Magie et soins ne ratent jamais ; sans esquive ni précision faible, aucun tirage n'est fait.
			if stat_key == "atk" and target.side != actor.side:
				var hit := clampf((actor.stat("acc") - target.stat("eva")) / 100.0, MIN_HIT, 1.0)
				if hit < 1.0 and rng.randf() >= hit:
					events.append({"type": "miss", "target": target, "dodge": target.stat("eva") > 0.0})
					return
			var att := actor.stat(stat_key)
			var dfn := target.stat("def" if stat_key == "atk" else "res")
			var amount := (att * 2.0 * float(fx.get("power", 100)) / 100.0 + float(fx.get("flat", 0))) * _damage_boost(actor, fx) - dfn
			amount *= rng.randf_range(0.9, 1.1)
			# Le Ramollissement du lieu émousse tout coup physique, d'où qu'il vienne.
			var soft := stat_key == "atk" and softness > 0.0 and not actor.is_firm()
			if soft:
				amount *= 1.0 - softness
			# Critique : chance de la compétence (6 % par défaut) + écart de la caractéristique à 6 % + talents.
			var crit_chance := minf(MAX_CRIT, float(fx.get("crit", CRIT_CHANCE)) + (actor.stat("crit") - 6.0) / 100.0 + actor.passive("crit"))
			var crit := rng.randf() < crit_chance
			if crit:
				amount *= actor.stat("critdmg") / 100.0
			var weak := target.weak.has(element)
			if weak:
				amount *= WEAK_MULT
			# Talents de celui qui frappe, puis de celui qui encaisse.
			amount *= 1.0 + actor.passive("element_boost", element)
			if target.afflicted():
				amount *= 1.0 + actor.passive("vs_afflicted")
			amount *= 1.0 + actor.passive("fury") * (1.0 - float(actor.hp) / actor.max_hp())
			amount *= maxf(0.2, 1.0 - (0.0 if bool(fx.get("ignore_guard", false)) else target.passive("guard")))   # « ignore_guard » : un coup qui passe la parade des talents
			amount *= maxf(0.2, 1.0 - target.passive("resist", element))   # résistance à l'élément (équipement)
			amount *= target.vulnerability()
			if target.defending:
				amount *= 0.5
			if actor.side == "enemy" and target.side == "party":
				amount *= float(diff.get("enemy_dmg", 1.0))   # difficulté
			var dmg := maxi(1, int(round(amount)))
			target.hp = maxi(0, target.hp - dmg)
			_tally_damage(actor, target, dmg, crit)
			var reveal := false
			if weak and target.side == "enemy":
				var known: Array = known_weak(target).duplicate()
				if not known.has(element):
					known.append(element)
					revealed[target.source] = known
					reveal = true
			events.append({"type": "damage", "target": target, "amount": dmg, "weak": weak, "crit": crit, "element": element, "reveal": reveal, "soft": soft})
			if not target.alive():
				_ko(target, events)
				return
			for id: String in target.statuses.keys():
				if bool(Database.get_status(id).get("wake_on_hit", false)):
					target.statuses.erase(id)
					events.append({"type": "wake", "target": target, "id": id})
			if weak and target.shield > 0 and not target.has_status("ebranle"):
				target.shield -= 1
				if target.shield <= 0:
					target.statuses["ebranle"] = {"turns": 1, "fresh": target == actor}
					events.append({"type": "break", "target": target})
			# Riposte : celui qui vient d'encaisser un coup physique le rend aussitôt.
			var counter := target.passive("counter")
			if counter > 0.0 and not _countering and stat_key == "atk" and target.side != actor.side and actor.alive() and target.skipping_status() == "" and rng.randf() < counter:
				_countering = true
				var kept := _boost
				var kept_name := _cur_name
				_cur_name = "Riposte"
				_boost = 0   # la riposte n'emprunte rien à l'élan de celui qui a frappé
				events.append({"type": "counter", "actor": target})
				_apply(target, actor, {"type": "damage", "stat": "atk", "power": 100, "element": target.element}, events)
				_boost = kept
				_cur_name = kept_name
				_countering = false
		"heal":
			var amount := float(fx.get("power", 0)) + target.max_hp() * float(fx.get("percent", 0.0))
			if fx.has("stat"):
				amount += actor.stat(str(fx["stat"])) * 1.5
			amount *= 1.0 + actor.passive("heal_boost")
			if _boost > 0 and actor.side == "party":
				amount *= elan_mult(_boost_def, _boost, true)
			var gain := mini(target.max_hp() - target.hp, maxi(1, int(round(amount))))
			target.hp += gain
			if actor.side == "party" and target.side == "party":
				tally["heal"] = int(tally["heal"]) + gain
			events.append({"type": "heal", "target": target, "amount": gain})
		"mana":
			var gain := mini(target.max_mp() - target.mp, int(fx.get("power", 0)))
			if target.side == "enemy":
				gain = 0
			target.mp += gain
			events.append({"type": "mana", "target": target, "amount": gain})
		"status":
			var id := str(fx.get("id", ""))
			var st := Database.get_status(id)
			if st.is_empty():
				return
			if target.immune.has(id):
				if target.side == "enemy":
					_tally_immune(target.source, [id])   # une insensibilité qu'on vient de découvrir
				events.append({"type": "status", "target": target, "id": id, "applied": false, "immune": true})
				return
			var chance := float(fx.get("chance", 1.0))
			var turns := int(fx.get("turns", st.get("turns", 3)))
			if _boost > 0 and actor.side == "party" and not _boost_def.is_empty():
				if target.side == actor.side:
					turns += _boost   # un renfort dure plus longtemps
				else:
					chance = minf(1.0, chance * (1.0 + ELAN_STATUS * _boost))
			if target.side != actor.side:   # talents qui rendent les altérations plus sûres
				chance *= 1.0 + actor.passive("status_chance", id) + actor.passive("status_chance", "all")
				chance *= maxf(0.0, 1.0 - target.passive("status_resist", id) - target.passive("status_resist", "all"))   # équipement
			if rng.randf() >= chance:
				events.append({"type": "status", "target": target, "id": id, "applied": false, "immune": false})
				return
			target.statuses[id] = {"turns": turns, "fresh": target == actor}
			events.append({"type": "status", "target": target, "id": id, "applied": true, "immune": false})
		"cure":
			var cured: Array = []
			var only: Variant = fx.get("ids")
			for id: String in target.statuses.keys():
				if id == "ebranle":
					continue
				var wanted := bool(Database.get_status(id).get("negative", false))
				if only is Array:
					wanted = (only as Array).has(id)
				if wanted:
					target.statuses.erase(id)
					cured.append(id)
			events.append({"type": "cure", "target": target, "ids": cured})
		"analyze":   # révèle tout d'un ennemi : faiblesses, insensibilités, statistiques
			if target.side == "enemy":
				revealed[target.source] = (target.weak as Array).duplicate()
				_tally_immune(target.source, target.immune)
				(tally["analyzed"] as Dictionary)[target.source] = true
				events.append({"type": "analyze", "target": target})
		"steal":
			if actor.side != "party" or target.side != "enemy":
				return
			var loot := 0
			if not target.robbed and target.money > 0:
				loot = maxi(1, int(round(target.money * float(fx.get("percent", 0.5)))))
				stolen += loot
			target.robbed = true
			events.append({"type": "steal", "target": target, "amount": loot})


func _ko(target: Combatant, events: Array) -> void:
	if target.side == "party":
		var kos: Dictionary = tally["ko"]
		kos[target.source] = int(kos.get(target.source, 0)) + 1
	target.hp = 0
	target.statuses.clear()
	target.defending = false
	events.append({"type": "ko", "target": target})


func _check_end() -> void:
	if result != "":
		return
	if living("enemy").is_empty():
		result = "victory"
	elif living("party").is_empty():
		result = "defeat"


# ------------------------------------------------------------- choix automatiques

## Choix d'un ennemi, d'après la liste pondérée « ai » de sa fiche.
func ai_action(actor: Combatant) -> Dictionary:
	# Un ennemi peut changer de comportement quand il est mal en point (« ai_low », sous « low_at »).
	var list: Array = actor.ai
	var low: Variant = actor.data.get("ai_low")
	if low is Array and not (low as Array).is_empty() and float(actor.hp) / actor.max_hp() <= float(actor.data.get("low_at", 0.5)):
		list = low
	var total := 0.0
	for e: Variant in list:
		if e is Dictionary:
			total += float(e.get("weight", 1))
	var pick := "attack"
	if actor.next_skill != "":   # le coup annoncé au tour précédent tombe maintenant
		pick = actor.next_skill
		actor.next_skill = ""
		total = 0.0
	if total > 0.0:
		var roll := rng.randf() * total
		for e: Variant in list:
			if not (e is Dictionary):
				continue
			roll -= float(e.get("weight", 1))
			if roll <= 0.0:
				pick = str(e.get("skill", "attack"))
				actor.next_skill = str(e.get("next", ""))   # « next » : cette compétence annonce un coup, lancé au tour suivant
				break
	var foes := living(foes_of(actor))
	var target: Combatant = null
	if not foes.is_empty():
		target = foes[rng.randi() % foes.size()]
		var pierce := bool(Database.get_skill(pick).get("pierce", false))   # « pierce » : un coup qui ignore la provocation
		for f: Combatant in foes:   # un provocateur attire les coups
			if not pierce and f.status_value("taunt") > 0.0:
				target = f
				break
	if pick == "attack" or Database.get_skill(pick).is_empty():
		return {"type": "attack", "target": target}
	return {"type": "skill", "id": pick, "target": target}


## Choix raisonnable pour un allié : sert aux tests et au mode « combat automatique ». Il garde son
## élan, sauf contre un ennemi brisé ou massif (plus de ELAN_AUTO_BIG PV), ou quand la réserve est pleine.
func auto_action(actor: Combatant) -> Dictionary:
	var action := _auto_choice(actor)
	var kind := elan_kind(actor, action)
	var target: Variant = action.get("target")
	if (kind == "hits" or kind == "power") and actor.elan > 0 and target is Combatant:
		var foe: Combatant = target
		if foe.has_status("ebranle") or foe.max_hp() >= ELAN_AUTO_BIG:
			action["elan"] = mini(ELAN_COMMIT_MAX, actor.elan)
		elif actor.elan >= ELAN_MAX:
			action["elan"] = 2
	return action


func _auto_choice(actor: Combatant) -> Dictionary:
	var allies := living(actor.side)
	var weakest: Combatant = actor
	for a: Combatant in allies:
		if float(a.hp) / a.max_hp() < float(weakest.hp) / weakest.max_hp():
			weakest = a
	if float(weakest.hp) / weakest.max_hp() < 0.4:
		for id: String in actor.skills:
			var def := Database.get_skill(id)
			var kind := str(def.get("target", ""))
			if not can_use_skill(actor, id) or not _has_effect(def, "heal"):
				continue
			if kind in ["ally", "all_allies"] or (kind == "self" and weakest == actor):
				return {"type": "skill", "id": id, "target": weakest}
		for id: String in inventory:
			var def := Database.get_item(id)
			if _has_effect(def, "heal") and str(def.get("target", "")) == "ally":
				return {"type": "item", "id": id, "target": weakest}
	var foes := living(foes_of(actor))
	if foes.is_empty():
		return {"type": "defend"}
	var target: Combatant = foes[0]
	for f: Combatant in foes:
		if f.hp < target.hp:
			target = f
	var best := {"type": "attack", "target": target}
	var best_score := 100.0 * actor.stat("atk") * (WEAK_MULT if target.weak.has(actor.element) else 1.0)
	for id: String in actor.skills:
		if not can_use_skill(actor, id):
			continue
		var def := Database.get_skill(id)
		if not (str(def.get("target", "")) in ["enemy", "all_enemies"]):
			continue
		for fx: Variant in def.get("effects", []):
			if fx is Dictionary and str(fx.get("type", "")) == "damage":
				var score := float(fx.get("power", 100)) * actor.stat(str(fx.get("stat", "atk")))
				if target.weak.has(str(fx.get("element", ""))):
					score *= WEAK_MULT
				if score > best_score:
					best_score = score
					best = {"type": "skill", "id": id, "target": target}
	return best


static func _has_effect(def: Dictionary, type: String) -> bool:
	for fx: Variant in def.get("effects", []):
		if fx is Dictionary and str(fx.get("type", "")) == type:
			return true
	return false


# ---------------------------------------------------------------- fin du combat

## Applique l'issue du combat à l'état de la partie et renvoie le butin à afficher :
## {"xp", "money", "drops": {id: n}, "levelups": [{"name", "from", "to", "skills": [noms]}],
## "gains": {id: xp}, "progress": {id: {from_level, from_xp, to_level, to_xp, need}},
## "records": [textes], "new": [créatures découvertes], "first_win": [premières victoires]}.
## Range aussi le bilan dans le Carnet (une seule fois, sauf combat imposé par l'histoire).
func commit() -> Dictionary:
	var out := _commit_rewards()
	out["records"] = []
	out["new"] = []
	out["first_win"] = []
	if not guest and result != "" and not _absorbed:
		_absorbed = true
		for id: String in (tally["analyzed"] as Dictionary):
			Carnet.analyze(id, Database.get_enemy(id).get("weak", []), Database.get_enemy(id).get("immune", []))
		var book := Carnet.absorb(self)
		out["records"] = book["records"]
		out["new"] = book["new"]
		out["first_win"] = book["first_win"]
	return out


func _tally_damage(actor: Combatant, target: Combatant, dmg: int, crit: bool) -> void:
	if target.side == "party":
		tally["taken"] = int(tally["taken"]) + dmg
	elif actor.side == "party":
		tally["dealt"] = int(tally["dealt"]) + dmg
		if crit:
			tally["crits"] = int(tally["crits"]) + 1
		if dmg > int((tally["best"] as Dictionary).get("amount", 0)):
			tally["best"] = {"who": actor.source, "what": _cur_name, "amount": dmg, "target": target.name}


func _tally_skill(actor: Combatant, skill_id: String) -> void:
	var per: Dictionary = tally["skills"]
	if not (per.get(actor.source) is Dictionary):
		per[actor.source] = {}
	var mine: Dictionary = per[actor.source]
	mine[skill_id] = int(mine.get(skill_id, 0)) + 1


func _tally_immune(source: String, ids: Array) -> void:
	var im: Dictionary = tally["immune"]
	var list: Array = im.get(source, [])
	for id: Variant in ids:
		if not list.has(str(id)):
			list.append(str(id))
	im[source] = list


func _commit_rewards() -> Dictionary:
	var out := {"xp": 0, "money": 0, "drops": {}, "levelups": [], "gains": {}, "progress": {}}
	if guest or result == "defeat" or result == "":
		return out
	GameState.bestiary = revealed.duplicate(true)
	GameState.inventory = inventory.duplicate(true)
	for c: Combatant in party:
		var m: Dictionary = GameState.member(c.source)
		m["hp"] = maxi(1, c.hp)
		m["mp"] = c.mp
	if result != "victory":
		GameState.money += stolen   # ce qui est fauché reste fauché, même en fuyant
		Carnet.bump("or_gagne", stolen)
		return out
	for e: Combatant in enemies:
		out["xp"] = int(out["xp"]) + e.xp
		out["money"] = int(out["money"]) + e.money
		for d: Variant in e.drops:
			if d is Dictionary and rng.randf() < float(d.get("chance", 1.0)):
				var item := str(d.get("item", ""))
				if not Database.get_item(item).is_empty():
					out["drops"][item] = int(out["drops"].get(item, 0)) + int(d.get("count", 1))
					var found: Array = (tally["loot"] as Dictionary).get(e.source, [])
					found.append(item)
					(tally["loot"] as Dictionary)[e.source] = found
	out["xp"] = int(round(float(int(out["xp"])) * float(diff.get("xp", 1.0))))   # difficulté : gains
	out["money"] = int(round(float(int(out["money"])) * float(diff.get("money", 1.0))))
	var money_bonus := 0.0
	for c: Combatant in party:
		money_bonus += c.passive("money_bonus")
	out["money"] = int(round(float(int(out["money"]) + stolen) * (1.0 + money_bonus)))
	GameState.money += int(out["money"])
	Carnet.bump("or_gagne", int(out["money"]))
	for item: String in out["drops"]:
		GameState.add_item(item, int(out["drops"][item]))
	for c: Combatant in party:
		(out["gains"] as Dictionary)[c.source] = int(round(float(out["xp"]) * (1.0 + c.passive("xp_bonus"))))
		var before := GameState.member(c.source)
		var prog := {"from_level": int(before["level"]), "from_xp": int(before["xp"])}
		var up := GameState.grant_xp(c.source, int(round(float(out["xp"]) * (1.0 + c.passive("xp_bonus")))))
		var after := GameState.member(c.source)
		prog["to_level"] = int(after["level"])
		prog["to_xp"] = int(after["xp"])
		prog["need"] = Rules.xp_to_next(int(after["level"]))
		(out["progress"] as Dictionary)[c.source] = prog
		if not up.is_empty():
			(out["levelups"] as Array).append(up)
	# la réserve ne se bat pas : elle ne gagne rien tant que RESERVE_XP vaut zéro
	for id: Variant in GameState.reserve_party():
		if GameState.RESERVE_XP <= 0.0:
			break
		var up_r := GameState.grant_xp(str(id), int(ceil(float(out["xp"]) * GameState.RESERVE_XP)))
		if not up_r.is_empty():
			(out["levelups"] as Array).append(up_r)
	return out
