extends "res://src/gfx/char_kit.gd"
## Objets tenus par les personnages (champ « held » du look) : poêle, épée, arc, hache...
##
## Un objet se dessine toujours dans un repère local : « g » est la poignée, « ang » la
## direction de l'objet (degrés, 0 = vers la droite de la case, 90 = vers le bas), u court le
## long de l'objet, v en travers. Les mêmes dessins servent aux quatre directions : la ligne
## « droite » est peinte retournée par _put.
##
## Quatre états :
##   repos  : rangé (à la ceinture, dans le dos), sans élargir la silhouette ; les perches
##            (fourche, balai, lance) restent debout dans la main, comme le bâton ;
##   marche : en main, le long du corps ;
##   combat : utilisé (lame abattue, hache levée, arc bandé, poêle qui s'abat) ;
##   KO     : lâché par terre.

## Objets longs qui restent debout dans la main, même au repos.
const POLES := ["fourche", "balai", "lance"]
## Tous les objets connus (champ « held »).
const HELD := ["poele", "epee", "rapiere", "dague", "serpe", "hache", "marteau", "arc", "registre", "gigot",
	"fourche", "balai", "lance"]

# angles (degrés) en main selon l'état : [face, profil, dos]
const ANG := {
	"blade": {"walk": [78.0, 112.0, 78.0], "strike": [-62.0, 125.0, -62.0], "up": [-88.0, -98.0, -88.0], "flail": [-62.0, -55.0, -62.0]},
	"haft": {"walk": [80.0, 100.0, 80.0], "strike": [-60.0, -100.0, -60.0], "up": [-82.0, -100.0, -82.0], "flail": [-80.0, -75.0, -80.0]},
	"pan": {"walk": [70.0, 100.0, 70.0], "strike": [-56.0, 112.0, -56.0], "up": [-84.0, -98.0, -84.0], "flail": [-70.0, -60.0, -70.0]},
	"bow": {"walk": [0.0, 180.0, 0.0], "strike": [0.0, 180.0, 0.0], "up": [0.0, 180.0, 0.0], "flail": [-30.0, 150.0, -30.0]},
}


static func _family(kind: String) -> String:
	match kind:
		"hache", "marteau":
			return "haft"
		"poele":
			return "pan"
		"arc":
			return "bow"
	return "blade"


## Longueur approximative de l'objet (de la poignée à l'extrémité).
static func _item_len(kind: String) -> float:
	match kind:
		"epee":
			return 31.0
		"rapiere":
			return 28.0
		"dague":
			return 15.0
		"serpe":
			return 22.0
		"hache", "marteau":
			return 27.0
		"poele":
			return 23.0
		"arc":
			return 36.0
		"registre":
			return 12.0
		"gigot":
			return 22.0
	return 30.0


## État de l'objet d'après la pose : rest, walk, strike, up, flail, slump.
static func _hmode() -> String:
	var arms := str(_p["arms"])
	if arms == "down":
		return "walk" if bool(_p.get("walk", false)) else "rest"
	return arms


static func _held_angle(kind: String, view: int, mode: String) -> float:
	var tab: Dictionary = ANG[_family(kind)]
	if not tab.has(mode):
		mode = "walk"
	return float((tab[mode] as Array)[view])


static func _pp(g: Vector2, a: Vector2, n: Vector2, u: float, v: float) -> Vector2:
	return g + a * u + n * v


# ----------------------------------------------------------------------- mains

## Main. mode 0 : pendante (face, dos), pouce côté corps (hs : côté de l'écran du bras) ;
## mode 1 : poing de profil, doigts vers l'avant ; mode 2 : poing fermé sur un manche.
static func _hand(hx: float, hy: float, mode: int, hs: int) -> void:
	var skin: Array = _c["skin"]
	var x := int(round(hx))
	var y := int(round(hy))
	match mode:
		1:
			_ell(hx - 0.3, hy + 0.3, 3.7, 3.5, skin)
			_put(x - 3, y - 1, skin[1])
			_put(x - 2, y - 1, skin[1])
			_put(x - 3, y + 1, skin[1])
			_put(x - 2, y + 1, skin[1])
			_put(x - 3, y + 2, skin[0])
			_cap(hx - 2.6, hy - 2.7, hx - 0.6, hy - 3.0, 1.1, 1.1, skin, 0.25)
			_put(x + 1, y + 2, skin[1])
		2:
			_ell(hx, hy, 3.7, 3.4, skin)
			for i in 7:
				_put(x - 3 + i, y, skin[1])
				_put(x - 3 + i, y + 2, skin[0] if i % 2 == 0 else skin[1])
			_put(x - 1, y - 1, skin[4])
			_put(x + 1, y - 1, skin[3])
			_cap(hx - 0.8, hy - 3.2, hx + 0.8, hy - 1.0, 1.2, 1.1, skin, 0.25)
		_:
			_ell(hx, hy + 0.6, 3.3, 4.0, skin)
			_cap(hx - float(hs) * 2.5, hy - 1.8, hx - float(hs) * 2.1, hy + 1.4, 1.2, 1.0, skin, 0.25)
			_put(x - 1, y + 1, skin[1])
			_put(x - 1, y + 2, skin[1])
			_put(x + 1, y + 1, skin[1])
			_put(x + 1, y + 2, skin[1])
			_put(x - 2, y + 3, skin[1])
			_put(x, y + 3, skin[1])
			_put(x + 2, y + 3, skin[1])
			_put(x, y - 2, skin[4])


# --------------------------------------------------------------------- objets

## Dessine l'objet : poignée en g, orienté de ang degrés.
##   sheath : lame dans son fourreau (rangé) ; pull : main qui tire la corde (arc) ;
##   open : registre ouvert.
static func _obj(kind: String, g: Vector2, ang: float, sheath: bool = false, pull: Vector2 = Vector2.ZERO,
		open: bool = false) -> void:
	var a := Vector2.from_angle(deg_to_rad(ang))
	var n := Vector2(-a.y, a.x)
	var steel: Array = _c["steel"]
	var wood: Array = _c["wood"]
	var gold: Array = _c["gold"]
	var lea: Array = _c["belt"]
	var iron: Array = _c["castiron"]
	match kind:
		"epee", "rapiere", "dague":
			var blen := 26.0
			var bw := 1.9
			var guard := 4.6
			if kind == "rapiere":
				blen = 24.0
				bw = 1.15
			elif kind == "dague":
				blen = 12.0
				bw = 1.7
				guard = 3.0
			var blade: Array = wood if sheath else steel
			if sheath:
				bw += 0.7
			_cap(_pp(g, a, n, -5.0, 0.0).x, _pp(g, a, n, -5.0, 0.0).y, _pp(g, a, n, 1.0, 0.0).x, _pp(g, a, n, 1.0, 0.0).y, 1.5, 1.5, _dim(wood))
			var pom := _pp(g, a, n, -6.0, 0.0)
			_ell(pom.x, pom.y, 1.9, 1.9, gold)
			if kind == "rapiere":
				# coquille et branche de garde
				var c0 := _pp(g, a, n, 0.5, 0.0)
				var c1 := _pp(g, a, n, 4.6, 0.0)
				_cap(c0.x, c0.y, c1.x, c1.y, 1.1, 3.9, gold)
				var k0 := _pp(g, a, n, 0.5, -3.0)
				var k1 := _pp(g, a, n, -4.5, -2.2)
				_line(k0.x, k0.y, k1.x, k1.y, gold[3])
			else:
				var g0 := _pp(g, a, n, 1.4, -guard)
				var g1 := _pp(g, a, n, 1.4, guard)
				_cap(g0.x, g0.y, g1.x, g1.y, 1.3, 1.3, gold)
			var s0 := 3.0 if kind != "rapiere" else 4.6
			_poly([_pp(g, a, n, s0, -bw), _pp(g, a, n, s0, bw), _pp(g, a, n, s0 + blen - 5.0, bw * 0.85),
				_pp(g, a, n, s0 + blen, 0.0), _pp(g, a, n, s0 + blen - 5.0, -bw * 0.85)], blade, 0.1)
			if sheath:
				var lk := _pp(g, a, n, s0, 0.0)
				_ell(lk.x, lk.y, 1.8, 1.8, gold)
				var ch0 := _pp(g, a, n, s0 + blen - 3.0, 0.0)
				var ch1 := _pp(g, a, n, s0 + blen + 0.5, 0.0)
				_cap(ch0.x, ch0.y, ch1.x, ch1.y, bw, 0.6, gold)
			else:
				var h0 := _pp(g, a, n, s0 + 0.5, -bw * 0.35)
				var h1 := _pp(g, a, n, s0 + blen - 3.0, -bw * 0.2)
				_line(h0.x, h0.y, h1.x, h1.y, steel[4])
				var e0 := _pp(g, a, n, s0 + 0.5, bw * 0.7)
				var e1 := _pp(g, a, n, s0 + blen - 5.0, bw * 0.6)
				_line(e0.x, e0.y, e1.x, e1.y, steel[1])
		"serpe":
			_cap(_pp(g, a, n, -6.0, 0.0).x, _pp(g, a, n, -6.0, 0.0).y, _pp(g, a, n, 8.0, 0.0).x, _pp(g, a, n, 8.0, 0.0).y, 1.4, 1.4, wood)
			var d0 := _pp(g, a, n, 7.0, 0.0)
			var d1 := _pp(g, a, n, 17.0, -1.0)
			var d2 := _pp(g, a, n, 15.0, -11.0)
			_bend(d0, d1, d2, 2.3, 0.6, steel, 0.1, 10)
			var r := _pp(g, a, n, 8.5, 0.0)
			_put(int(round(r.x)), int(round(r.y)), gold[3])
		"hache", "marteau":
			var hlen := 25.0
			_cap(_pp(g, a, n, -4.0, 0.0).x, _pp(g, a, n, -4.0, 0.0).y, _pp(g, a, n, hlen, 0.0).x, _pp(g, a, n, hlen, 0.0).y, 1.5, 1.4, wood)
			var ph := _pp(g, a, n, 0.5, 0.0)
			_cap(ph.x, ph.y, ph.x, ph.y, 1.9, 1.9, _dim(wood))
			if kind == "hache":
				# fer à barbe : lame large du côté du tranchant, talon court de l'autre
				_poly([_pp(g, a, n, 16.0, 2.2), _pp(g, a, n, 24.0, 2.2), _pp(g, a, n, 25.0, -3.0), _pp(g, a, n, 27.5, -10.5),
					_pp(g, a, n, 12.5, -10.5), _pp(g, a, n, 14.5, -3.0)], steel, 0.05)
				var t0 := _pp(g, a, n, 12.5, -10.2)
				var t1 := _pp(g, a, n, 27.0, -10.2)
				_line(t0.x, t0.y, t1.x, t1.y, steel[4])
				var m0 := _pp(g, a, n, 17.0, -2.0)
				var m1 := _pp(g, a, n, 22.0, -2.0)
				_line(m0.x, m0.y, m1.x, m1.y, steel[1])
			else:
				_poly([_pp(g, a, n, 17.0, -6.5), _pp(g, a, n, 26.0, -6.5), _pp(g, a, n, 26.0, 6.5), _pp(g, a, n, 17.0, 6.5)], iron, 0.1)
				var t2 := _pp(g, a, n, 17.5, -6.0)
				var t3 := _pp(g, a, n, 25.5, -6.0)
				_line(t2.x, t2.y, t3.x, t3.y, steel[3])
		"poele":
			var h0 := _pp(g, a, n, -3.0, 0.0)
			var h1 := _pp(g, a, n, 9.5, 0.0)
			_cap(h0.x, h0.y, h1.x, h1.y, 1.5, 1.5, iron)
			var pc := _pp(g, a, n, 16.0, 0.0)
			_ell(pc.x, pc.y, 7.2, 7.2, iron)
			var inner: Array = [iron[0], iron[0], iron[1], iron[1], iron[2]]
			_ell(pc.x + 0.4, pc.y + 0.4, 5.2, 5.2, inner)
			var hl := _pp(g, a, n, 16.0, 0.0) - Vector2(4.6, 4.6)
			_put(int(round(hl.x)), int(round(hl.y)), steel[4])
			_put(int(round(hl.x)) + 1, int(round(hl.y)) - 1, steel[3])
			var rv := _pp(g, a, n, 3.5, 0.0)
			_put(int(round(rv.x)), int(round(rv.y)), gold[3])
			var hole := _pp(g, a, n, -2.0, 0.0)
			_put(int(round(hole.x)), int(round(hole.y)), iron[0])
		"arc":
			var tip_a := _pp(g, a, n, -5.0, -18.0)
			var tip_b := _pp(g, a, n, -5.0, 18.0)
			var str_col := Color("#ece4cc")
			if pull != Vector2.ZERO:
				_line(tip_a.x, tip_a.y, pull.x, pull.y, str_col)
				_line(tip_b.x, tip_b.y, pull.x, pull.y, str_col)
				# flèche : de la corde au-delà de l'arc
				var dir := (g - pull).normalized()
				var head := g + dir * 11.0
				_line(pull.x, pull.y, head.x, head.y, wood[3])
				_line(pull.x + 1.0, pull.y, head.x + 1.0, head.y, wood[1])
				var perp := Vector2(-dir.y, dir.x)
				for k in 3:
					var f0 := pull + dir * float(k) * 1.6
					_line(f0.x, f0.y, f0.x - perp.x * 2.2, f0.y - perp.y * 2.2, Color("#d85a4a"))
					_line(f0.x, f0.y, f0.x + perp.x * 2.2, f0.y + perp.y * 2.2, Color("#d85a4a"))
				_poly([head + perp * 1.7, head - perp * 1.7, head + dir * 4.0], steel, 0.1)
			else:
				_line(tip_a.x, tip_a.y, tip_b.x, tip_b.y, str_col)
			_bend(g, _pp(g, a, n, 0.0, -9.0), tip_a, 1.7, 1.2, wood, 0.0, 10)
			_bend(g, _pp(g, a, n, 0.0, 9.0), tip_b, 1.7, 1.2, wood, 0.0, 10)
			var w0 := _pp(g, a, n, 0.0, -3.2)
			var w1 := _pp(g, a, n, 0.0, 3.2)
			_cap(w0.x, w0.y, w1.x, w1.y, 2.1, 2.1, lea)
			_ell(tip_a.x, tip_a.y, 1.3, 1.3, gold)
			_ell(tip_b.x, tip_b.y, 1.3, 1.3, gold)
		"registre":
			var cover: Array = _c["band"]
			if open:
				_poly([_pp(g, a, n, -9.0, -6.0), _pp(g, a, n, 0.0, -6.0), _pp(g, a, n, 0.0, 6.0), _pp(g, a, n, -9.0, 6.0)], _c["apron"], 0.2)
			_poly([_pp(g, a, n, 0.0, -6.0), _pp(g, a, n, 11.0, -6.0), _pp(g, a, n, 11.0, 6.0), _pp(g, a, n, 0.0, 6.0)], cover, 0.1)
			var s0 := _pp(g, a, n, 0.0, -6.0)
			var s1 := _pp(g, a, n, 0.0, 6.0)
			_line(s0.x, s0.y, s1.x, s1.y, cover[0])
			var p0 := _pp(g, a, n, 1.0, 6.6)
			var p1 := _pp(g, a, n, 10.5, 6.6)
			_line(p0.x, p0.y, p1.x, p1.y, SCLERA)
			var cl := _pp(g, a, n, 9.0, 0.0)
			_ell(cl.x, cl.y, 1.5, 1.5, gold)
			var t0 := _pp(g, a, n, 3.5, -2.5)
			var t1 := _pp(g, a, n, 7.0, -2.5)
			_line(t0.x, t0.y, t1.x, t1.y, gold[3])
		"gigot":
			var bone: Array = _c["bone"]
			var meat: Array = _c["meat"]
			var b0 := _pp(g, a, n, -5.0, 0.0)
			var b1 := _pp(g, a, n, 6.0, 0.0)
			_cap(b0.x, b0.y, b1.x, b1.y, 1.5, 1.5, bone)
			var k0 := _pp(g, a, n, -5.5, 0.0)
			_ell(k0.x, k0.y, 2.4, 2.4, bone)
			var m0 := _pp(g, a, n, 8.0, 0.0)
			var m1 := _pp(g, a, n, 17.0, 0.0)
			_cap(m0.x, m0.y, m1.x, m1.y, 3.6, 6.0, meat)
			var gl := _pp(g, a, n, 14.0, -3.0)
			_put(int(round(gl.x)), int(round(gl.y)), meat[4])
			_put(int(round(gl.x)) + 1, int(round(gl.y)), meat[3])
			var bt := _pp(g, a, n, 12.0, 3.0)
			_put(int(round(bt.x)), int(round(bt.y)), meat[0])


## Objet tenu en main selon l'état (marche, combat), poing refermé dessus.
## pull : main qui tire la corde d'un arc bandé.
static func _hold(kind: String, view: int, hand: Vector2, mode: String, pull: Vector2 = Vector2.ZERO) -> void:
	if mode == "slump":
		_drop(kind, hand)
		return
	var ang := _held_angle(kind, view, mode)
	var drawn := Vector2.ZERO
	if kind == "arc" and mode == "strike":
		drawn = pull
	_obj(kind, hand, ang, false, drawn, mode == "up")
	_hand(hand.x, hand.y, 2, 1)


## KO : l'objet gît par terre, tourné vers l'arrière, dans la case.
static func _drop(kind: String, hand: Vector2) -> void:
	var l := _item_len(kind)
	match kind:
		"arc":
			_obj(kind, Vector2(clampf(hand.x - 2.0, 24.0, 62.0), _foot - 4.0), -90.0)
		"poele":
			_obj(kind, Vector2(minf(hand.x - 4.0, 84.0 - l), _foot - 8.0), 0.0)
		_:
			_obj(kind, Vector2(clampf(minf(hand.x - 4.0, 84.0 - l), 8.0, 70.0), _foot - 4.0 if kind in ["hache", "marteau"] else _foot - 3.0), 0.0)


# ------------------------------------------------------------------------ rangé

## Objet rangé, vu de face : à la hanche gauche (côté écran), sur la tenue.
static func _stow_front(kind: String, cx: float, belt_y: float) -> void:
	var ax := cx - _hs - _bulge + 3.5
	match kind:
		"epee":
			_obj("epee", Vector2(ax + 1.0, belt_y - 4.0), 100.0, true)
		"rapiere":
			_obj("rapiere", Vector2(ax + 1.0, belt_y - 4.0), 100.0, true)
		"dague":
			_obj("dague", Vector2(ax + 1.0, belt_y - 2.0), 100.0, true)
		"serpe":
			_obj("serpe", Vector2(ax + 1.0, belt_y - 1.0), 100.0)
		"hache", "marteau":
			_obj(kind, Vector2(ax + 4.0, belt_y + 22.0), -97.0)
		"poele":
			_obj("poele", Vector2(ax + 1.0, belt_y + 1.0), 95.0)
		"registre":
			_obj("registre", Vector2(ax + 1.0, belt_y), 92.0)
		"arc":
			# bandoulière, empennage du carquois au-dessus de l'épaule, bout de l'arc
			var lea: Array = _c["belt"]
			_cap(cx + _hs - 3.0, _ny + 2.0, cx - _hs + 2.0, belt_y, 1.5, 1.5, lea)
			_cap(cx - _hs + 1.0, _ny - 1.0, cx - _hs - 1.5, _ny - 6.0, 1.3, 1.0, _c["wood"])
			for k in 3:
				var fx := cx + _hs - 4.0 + float(k) * 2.4
				_line(fx, _ny - 1.0, fx + 1.0, _ny - 6.0 - float(k % 2), _c["wood"][3])
				_put(int(round(fx)) + 1, int(round(_ny)) - 6 - (k % 2), Color("#d85a4a"))
				_put(int(round(fx)), int(round(_ny)) - 5 - (k % 2), Color("#d85a4a"))


## Objet rangé, vu de dos : en travers du dos, ou à la hanche.
static func _stow_back(kind: String, cx: float, ny: float, belt_y: float) -> void:
	var ax := cx - _hs - _bulge + 3.5
	match kind:
		"epee":
			_obj("epee", Vector2(cx + _hs + 1.0, ny + 1.0), 115.0, true)
		"rapiere":
			_obj("rapiere", Vector2(cx + _hs + 1.0, ny + 1.0), 115.0, true)
		"dague":
			_obj("dague", Vector2(cx + 6.0, belt_y + 2.0), 172.0, true)
		"serpe":
			_obj("serpe", Vector2(cx - 5.0, belt_y - 1.0), 98.0)
		"hache", "marteau":
			_obj(kind, Vector2(cx - _hs + 3.0, belt_y + 8.0), -62.0)
		"poele":
			_obj("poele", Vector2(cx + 2.0, _ny + _th * 0.92), -100.0)
		"registre":
			_obj("registre", Vector2(ax + 1.0, belt_y), 92.0)
		"arc":
			var lea: Array = _c["belt"]
			# carquois en biais, flèches qui dépassent l'épaule, arc contre le dos
			_obj("arc", Vector2(cx - _hs + 6.0, ny + _th * 0.55), 0.0)
			_cap(cx - 5.0, belt_y + 1.0, cx + 6.0, ny + 3.0, 2.8, 3.2, lea)
			_ell(cx + 6.0, ny + 3.0, 3.4, 1.6, _dim(lea))
			for k in 3:
				var fx := cx + 3.0 + float(k) * 2.6
				_line(fx, ny + 3.0, fx + 1.0, ny - 3.0 - float(k % 2), _c["wood"][3])
				_put(int(round(fx)) + 1, int(round(ny)) - 3 - (k % 2), Color("#d85a4a"))
				_put(int(round(fx)), int(round(ny)) - 2 - (k % 2), Color("#d85a4a"))


## Objet rangé, vu de profil (regard à gauche) : à la hanche proche, ou dans le dos.
static func _stow_side(kind: String, tx: float, belt_y: float, hs: float) -> void:
	match kind:
		"epee":
			_obj("epee", Vector2(tx - 2.0, belt_y - 3.0), 68.0, true)
		"rapiere":
			_obj("rapiere", Vector2(tx - 2.0, belt_y - 3.0), 68.0, true)
		"dague":
			_obj("dague", Vector2(tx - 3.0, belt_y - 1.0), 100.0, true)
		"serpe":
			_obj("serpe", Vector2(tx - 1.0, belt_y - 1.0), 96.0)
		"hache", "marteau":
			_obj(kind, Vector2(tx + 2.5, belt_y + 24.0), -100.0)
		"poele":
			_obj("poele", Vector2(tx + 0.5, belt_y + 1.0), 92.0)
		"registre":
			_obj("registre", Vector2(tx, belt_y + 1.0), 90.0)
		"arc":
			var lea: Array = _c["belt"]
			_obj("arc", Vector2(tx + hs + 2.5, _ny + _th * 0.55), 0.0)
			_cap(tx + hs - 5.0, _ny + 4.0, tx + hs - 1.0, belt_y + 3.0, 2.4, 2.6, lea)
			for k in 3:
				var fx := tx + hs - 6.0 + float(k) * 2.0
				_line(fx, _ny + 4.0, fx - 0.5, _ny - 2.0 - float(k % 2), _c["wood"][3])
				_put(int(round(fx)), int(round(_ny)) - 2 - (k % 2), Color("#d85a4a"))


# --------------------------------------------------------------------- perches

## Perche debout dans la main (fourche, balai, lance), comme le bâton : l'extrémité utile
## est en haut (le balai a ses brins en bas).
static func _pole(kind: String, hx: float, hy: float, arms: String) -> void:
	var wood: Array = _c["wood"]
	var steel: Array = _c["steel"]
	var plen := 44.0
	match kind:
		"fourche":
			plen = 40.0
		"balai":
			plen = 36.0
	var top := hy - plen
	var bot := minf(_foot - 1.0, hy + 30.0)
	var tilt := 0.0
	match arms:
		"strike":
			top = hy - 26.0
			bot = hy + 12.0
			tilt = 4.0
		"up":
			top = hy - 26.0
			bot = hy + 12.0
		"flail":
			top = hy - 22.0
			bot = hy + 22.0
			tilt = 8.0
		"slump":
			top = hy - 30.0
			bot = hy + 6.0
			tilt = -10.0
	top = maxf(top, 14.0)
	var tx := hx - tilt
	_cap(hx - tilt, top, hx + tilt, bot, 1.7, 1.7, wood)
	match kind:
		"fourche":
			_cap(tx - 4.2, top + 3.0, tx + 4.2, top + 3.0, 1.2, 1.2, steel)
			for k in 3:
				var px := tx - 4.2 + float(k) * 4.2
				_cap(px, top + 3.0, px, top - 7.0, 1.1, 0.6, steel)
			_ell(tx, top + 4.0, 2.4, 2.0, _dim(steel))
		"lance":
			_poly([Vector2(tx - 2.6, top + 2.0), Vector2(tx + 2.6, top + 2.0), Vector2(tx + 0.5, top - 10.0)], steel, 0.1)
			_cap(tx - 3.2, top + 2.0, tx + 3.2, top + 2.0, 1.0, 1.0, _c["gold"])
			# fanion
			_poly([Vector2(tx + 1.0, top + 6.0), Vector2(tx + 10.0, top + 8.0), Vector2(tx + 1.0, top + 11.0)], _c["band"], 0.0)
		"balai":
			var st: Array = _c["straw"]
			var by := bot
			_poly([Vector2(tx - 1.8, by - 6.0), Vector2(tx + 1.8, by - 6.0), Vector2(tx + 6.5, by + 4.0), Vector2(tx - 6.5, by + 4.0)], st, 0.0, true)
			for k in 4:
				_line(tx - 4.0 + float(k) * 2.6, by - 1.0, tx - 5.0 + float(k) * 3.3, by + 3.0, st[1])
			_cap(tx - 2.0, by - 6.0, tx + 2.0, by - 6.0, 1.3, 1.3, _c["belt"])
	_hand(hx, hy, 2, 1)
