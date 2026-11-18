extends RefCounted
## Repère de quête : où mène l'étape en cours (champ facultatif `target` d'une étape de
## data/quests.json, voir docs/FORMAT_DONNEES.md). Fonctions seules, sans état de jeu propre :
## l'encart de quête (src/ui/objective_tracker.gd) et la marque flottante (src/ui/quest_marker.gd)
## s'en servent, et les tests vérifient que chaque cible existe.
##
## Une cible : {"map": "bittebourg", "npc": "pepin"} | {"map": ..., "dialogue": "potager"} | {"map": ..., "pos": [x, z]}
## ou {"map": ...} seul (on sait dans quelle carte aller, pas où). `target` peut aussi être une
## liste de cibles : toutes celles que la carte porte encore sont marquées.

static var _exits_cache: Dictionary = {}   # carte -> [{"pos": Vector2, "map": String}]


## Les cibles de l'étape en cours d'une quête (liste, vide si l'étape n'en déclare pas).
static func targets_of_step(quest_id: String, step: int) -> Array:
	var steps: Array = Database.get_quest(quest_id).get("steps", [])
	if step < 0 or step >= steps.size():
		return []
	var raw: Variant = (steps[step] as Dictionary).get("target")
	if raw is Dictionary:
		return [raw]
	if raw is Array:
		var out: Array = []
		for t: Variant in raw:
			if t is Dictionary:
				out.append(t)
		return out
	return []


## Problème d'une cible ("" si elle est correcte) : la carte, et l'objet visé, doivent exister.
static func problem(t: Dictionary) -> String:
	var map_id := str(t.get("map", ""))
	if not Database.has_map(map_id):
		return "carte inconnue « %s »" % map_id
	var objects: Array = Database.get_map(map_id).get("objects", [])
	if t.has("npc"):
		for o: Variant in objects:
			if o is Dictionary and str(o.get("type", "")) == "npc" and str(o.get("id", "")) == str(t["npc"]):
				return ""
		return "PNJ « %s » absent de la carte %s" % [str(t["npc"]), map_id]
	if t.has("dialogue"):
		for o: Variant in objects:
			if o is Dictionary and str(o.get("dialogue", "")) == str(t["dialogue"]):
				return ""
			if o is Dictionary and str(o.get("type", "")) == "npc" and str(o.get("id", "")) == str(t["dialogue"]):
				return ""
		return "dialogue « %s » absent de la carte %s" % [str(t["dialogue"]), map_id]
	if t.has("pos"):
		var p: Variant = t["pos"]
		if not (p is Array) or (p as Array).size() != 2:
			return "pos doit être [x, z]"
	return ""


# ---------------------------------------------------------------- dans la carte

## Position (monde) d'une cible dans la carte en cours, ou null si elle n'y est pas (ou plus).
static func world_position(world: Node3D, t: Dictionary) -> Variant:
	if world == null or str(t.get("map", "")) != str(world.get("map_id")):
		return null
	var height := 2.0
	if t.has("dialogue") or t.has("npc"):
		var key := str(t.get("dialogue", t.get("npc", "")))
		for it: Dictionary in world.interactables:
			var node: Variant = it.get("node")
			if node is Object and not is_instance_valid(node):
				continue
			var by_name: bool = t.has("npc") and node is Node and (node as Node).name == "Npc_" + str(t["npc"])
			if str(it.get("dialogue", "")) == key or by_name:
				var p: Vector3 = world.interactable_position(it)
				return p + Vector3(0.0, float(it.get("height", 1.3)) + 0.5, 0.0)
		for tr: Dictionary in world.triggers:
			if str(tr.get("dialogue", "")) == key:
				var c: Vector2 = (tr["rect"] as Rect2).get_center()
				return Vector3(c.x, world.ground_y(c.x, c.y) + height, c.y)
	if t.has("pos"):
		var xz: Array = t["pos"]
		return Vector3(float(xz[0]), world.ground_y(float(xz[0]), float(xz[1])) + height, float(xz[1]))
	return null


# ------------------------------------------------------------ d'une carte à l'autre

## Passages d'une carte vers les autres : portes de maison, bords, escaliers.
static func exits_of(map_id: String) -> Array:
	if _exits_cache.has(map_id):
		return _exits_cache[map_id]
	var out: Array = []
	for o: Variant in Database.get_map(map_id).get("objects", []):
		if not (o is Dictionary) or not ((o as Dictionary).get("to") is Dictionary):
			continue
		var d: Dictionary = o
		var dest := str((d["to"] as Dictionary).get("map", ""))
		var at := Vector2.ZERO
		if d.has("rect"):
			var r: Array = d["rect"]
			if str(d.get("type", "")) == "warp":
				at = Vector2(float(r[0]) + float(r[2]) * 0.5, float(r[1]) + float(r[3]) * 0.5)
			else:
				at = Vector2(float(r[0]) + float(d.get("door", float(r[2]) * 0.5)), float(r[1]) + float(r[3]))
		elif d.has("pos"):
			at = Vector2(float((d["pos"] as Array)[0]), float((d["pos"] as Array)[1]))
		if dest != "":
			out.append({"pos": at, "map": dest})
	_exits_cache[map_id] = out
	return out


## Premier passage à prendre pour aller de `from_map` à `to_map` (parcours en largeur) :
## {"pos": Vector2, "map": carte d'arrivée de ce passage}, ou {} si aucun chemin.
static func route(from_map: String, to_map: String) -> Dictionary:
	if from_map == to_map or not Database.has_map(from_map) or not Database.has_map(to_map):
		return {}
	var first: Dictionary = {}   # carte atteinte -> premier passage emprunté
	var queue: Array = [from_map]
	var seen := {from_map: true}
	while not queue.is_empty():
		var cur: String = queue.pop_front()
		for e: Dictionary in exits_of(cur):
			var nxt := str(e["map"])
			if seen.has(nxt) or not Database.has_map(nxt):
				continue
			seen[nxt] = true
			first[nxt] = first.get(cur, e)
			if nxt == to_map:
				return first[nxt]
			queue.append(nxt)
	return {}


## « vers l'est » : sens d'un passage vu de `from` (x vers l'est, z vers le sud).
static func compass(from: Vector2, to: Vector2) -> String:
	var d := to - from
	if absf(d.x) >= absf(d.y):
		return "vers l'est" if d.x > 0.0 else "vers l'ouest"
	return "vers le sud" if d.y > 0.0 else "vers le nord"


## Indication pour une cible dans une autre carte : « vers l'est : Brie » ; "" si on y est déjà.
static func direction_hint(from_map: String, player_xz: Vector2, t: Dictionary) -> String:
	var dest := str(t.get("map", ""))
	if dest == "" or dest == from_map:
		return ""
	var hop := route(from_map, dest)
	if hop.is_empty():
		return ""
	return "%s : %s" % [compass(player_xz, hop["pos"]), str(Database.get_map(dest).get("name", dest))]
