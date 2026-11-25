#!/usr/bin/env python3
"""Audit d'économie et de progression : or gagné par chapitre (combats obligatoires, combats
aléatoires estimés, coffres, quêtes) face au prix des équipements vendus, et expérience face
au niveau attendu. Lecture seule des fichiers de data/ ; aucune dépendance de Godot.
Usage : python3 tests/audit_economie.py [--aleatoires N]   (N combats aléatoires par chapitre, 14 par défaut)
"""
import json, glob, os, sys, re

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
D = lambda p: json.load(open(os.path.join(ROOT, "data", p)))
RANDOM = int(sys.argv[sys.argv.index("--aleatoires") + 1]) if "--aleatoires" in sys.argv else 14
SPENT_ON_CONSUMABLES = 0.25   # part de l'or qui part en soins et vivres
EXPECTED_LEVEL = {1: 7, 2: 9, 3: 11, 4: 16, 5: 18, 6: 23, 7: 27}   # niveaux des tests d'équilibre

enemies, items, quests, shops = D("enemies.json"), D("items.json"), D("quests.json"), D("shops.json")
enc = D("encounters.json")
prog = D("game.json")["progression"]
xp_need = lambda l: max(1, round(prog["xp_base"] * l ** prog["xp_power"]))

TABLE_CHAPTER = {}
for chap, names in {1: "pre_couche_nord pre_couche_sud bois_sud bois_nord roseliere_nord roseliere_sud",
                    2: "route_brie ferme_brie caves_brie", 3: "col_biscottes archives",
                    4: "morbier_galeries morbier_halle morbier_profondeurs",
                    5: "plaine fongorn garde_manger isengarde",
                    6: "minas_croute minas_rues sentier port_sale pelle_a_tarte",
                    7: "marais_bouillon passe_plat col_arachnee cuisines banquet marches"}.items():
    for n in names.split():
        TABLE_CHAPTER[n] = chap
SHOP_CHAPTER = {"etal_ursule": 1, "marche_sidonie": 2, "fromagerie_persille": 2, "chancellerie": 3,
                "arsenal_sylvanor": 3, "rondin": 4, "cabecou_marche": 5, "minas_marche": 6, "port_cambuse": 6, "dernier_etal": 7}
QUEST_CHAPTER = {}
cur = 1
for qid, q in quests.items():   # l'ordre du fichier suit l'histoire : le chapitre monte quand la quête principale suivante arrive
    m = re.match(r"chapitre_(\d)_fini", str(q.get("complete", "")))
    QUEST_CHAPTER[qid] = cur
    if q.get("kind") == "principale" and m:
        cur = int(m.group(1)) + 1 if int(m.group(1)) < 7 else 7
# la quête principale d'un chapitre se termine à sa fin : on la range dans le chapitre qui s'achève
for qid, q in quests.items():
    m = re.match(r"chapitre_(\d)_fini", str(q.get("complete", "")))
    if m: QUEST_CHAPTER[qid] = int(m.group(1))
QUEST_CHAPTER["ramollissement"] = 1

def enc_gold_xp(eid):
    e = enc["encounters"].get(eid)
    if not e: return 0, 0
    return (sum(enemies[x].get("money", 0) for x in e["enemies"]), sum(enemies[x].get("xp", 0) for x in e["enemies"]))

def group_avg(table):
    t = enc["tables"][table]; g = t["groups"]; w = sum(x.get("weight", 1) for x in g)
    gold = sum(x.get("weight", 1) * sum(enemies[e].get("money", 0) for e in x["enemies"]) for x in g) / w
    xp = sum(x.get("weight", 1) * sum(enemies[e].get("xp", 0) for e in x["enemies"]) for x in g) / w
    return gold, xp

gold = {c: {"combats": 0, "alea": 0, "coffres": 0, "quetes": 0} for c in range(1, 8)}
xp = {c: {"combats": 0, "alea": 0, "quetes": 0} for c in range(1, 8)}
seen = set()
for f in sorted(glob.glob(os.path.join(ROOT, "data/dialogues/*.json"))):
    name = os.path.basename(f)
    m = re.match(r"chapitre_(\d)", name)
    chap = int(m.group(1)) if m else 1
    def walk(x, key):
        if isinstance(x, dict):
            if "battle" in x and x["battle"] in enc["encounters"] and (x["battle"], chap) not in seen:
                seen.add((x["battle"], chap)); g, p = enc_gold_xp(x["battle"])
                gold[chap]["combats"] += g; xp[chap]["combats"] += p
            if "money" in x and isinstance(x["money"], int) and x["money"] > 0 and str(key).startswith("coffre"):
                gold[chap]["coffres"] += x["money"]
            for k, v in x.items(): walk(v, key)
        elif isinstance(x, list):
            for v in x: walk(v, key)
    for k, v in json.load(open(f)).items():
        walk(v, k)
for table, chap in TABLE_CHAPTER.items():
    g, p = group_avg(table)
    gold[chap]["alea"] += g * RANDOM; xp[chap]["alea"] += p * RANDOM
for qid, q in quests.items():
    c = QUEST_CHAPTER[qid]; r = q.get("reward", {})
    gold[c]["quetes"] += r.get("money", 0); xp[c]["quetes"] += r.get("xp", 0)

# nb de tables aléatoires par chapitre : le total aléatoire est moyenné, pas multiplié
for c in range(1, 8):
    n = sum(1 for t, ch in TABLE_CHAPTER.items() if ch == c)
    if n: gold[c]["alea"] /= n; xp[c]["alea"] /= n

gear = {c: {} for c in range(1, 8)}
for sid, chap in SHOP_CHAPTER.items():
    for s in shops[sid]["stock"]:
        it = items[s["item"]]
        if it.get("kind") == "equipment":
            gear[chap][s["item"]] = s.get("price", it.get("price", 0))

print("OR PAR CHAPITRE (écus)  [aléatoires : %d combats par chapitre]" % RANDOM)
print("  chap | combats | alea | coffres | quetes | TOTAL | dispo equip | equip. a vendre | achetable")
cum = 0; leftover = 0
rows = []
for c in range(1, 8):
    g = gold[c]; tot = sum(g.values()); avail = tot * (1 - SPENT_ON_CONSUMABLES) + leftover
    prices = sorted(gear[c].values()); full = sum(prices)
    bought = 0; money = avail
    for p in prices:
        if money >= p: money -= p; bought += 1
    frac = (avail / full) if full else 0
    leftover = 0
    print("  %4d | %7d | %4d | %7d | %6d | %5d | %11d | %4d art. / %5d | %3d %% (%d/%d)" % (
        c, g["combats"], g["alea"], g["coffres"], g["quetes"], tot, avail, len(prices), full,
        min(100, int(100 * frac)), bought, len(prices)))
print("\nCUMUL (l'or se garde d'un chapitre à l'autre, l'équipement des chapitres passés reste achetable)")
cb = cg = 0
for c in range(1, 8):
    cb += sum(gold[c].values()) * (1 - SPENT_ON_CONSUMABLES); cg += sum(gear[c].values())
    print("  jusqu'au chap %d : or utile %6d, équipement vendu %6d -> %s" % (c, cb, cg, ("%3d %%" % min(999, int(100 * cb / cg))) if cg else "-"))
print("\nEXPÉRIENCE PAR CHAPITRE (par héros) et niveau atteint")
total = 0
lv = 1; rest = 0
for c in range(1, 8):
    x = xp[c]; gain = sum(x.values()); total += gain; rest += gain
    while rest >= xp_need(lv): rest -= xp_need(lv); lv += 1
    print("  chap %d : combats %5d, alea %5d, quetes %5d, total %6d -> niveau %2d (attendu %2d)  %s" % (
        c, x["combats"], x["alea"], x["quetes"], gain, lv, EXPECTED_LEVEL[c],
        "ok" if abs(lv - EXPECTED_LEVEL[c]) <= 2 else "ECART"))
print("\nSOINS vendus (prix par PV approximatif) :")
for iid, it in sorted(items.items(), key=lambda kv: kv[1].get("price", 0)):
    for e in it.get("effects", []):
        if e.get("type") == "heal" and it.get("price"):
            print("  %-26s %3d écus  soin %3d + %2d %%" % (iid, it["price"], e.get("power", 0), int(100 * e.get("percent", 0))))
            break
