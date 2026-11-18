#!/usr/bin/env python3
# Compose les onze morceaux de data/music.json (outil hors dépôt).
# Mélodies écrites en degrés de gamme ; accompagnements dérivés de la suite d'accords.
import json, re, sys

PC = {'c': 0, 'd': 2, 'e': 4, 'f': 5, 'g': 7, 'a': 9, 'b': 11}
SC = {'major': [0, 2, 4, 5, 7, 9, 11], 'mixolydian': [0, 2, 4, 5, 7, 9, 10],
      'dorian': [0, 2, 3, 5, 7, 9, 10], 'aeolian': [0, 2, 3, 5, 7, 8, 10],
      'phrygian': [0, 1, 3, 5, 7, 8, 10]}
NM = ['c', 'c#', 'd', 'd#', 'e', 'f', 'f#', 'g', 'g#', 'a', 'a#', 'b']
QUAL = {'M': [0, 4, 7], 'm': [0, 3, 7], 'P': [0, 7, 12], '7': [0, 4, 7, 10], 'd': [0, 3, 6]}


def nm(m):
    return NM[m % 12] + str(m // 12 - 1)


def addvel(bar, v):
    if v is None:
        return bar
    out = []
    for t in bar.split():
        if t.startswith('r:') or '@' in t:
            out.append(t)
        else:
            out.append(t + '@%d' % v)
    return ' '.join(out)


class Piece:
    def __init__(s, id, name, tempo, tonic, mode, bar, echo=0.2, reverb=0.2, loop=True, volume=1.0):
        s.id, s.name, s.tempo, s.bar, s.echo, s.reverb, s.loop, s.volume = id, name, tempo, bar, echo, reverb, loop, volume
        s.tonic = PC[tonic[0]] + (1 if tonic.endswith('#') else (-1 if len(tonic) > 1 and tonic.endswith('b') else 0))
        s.mode = mode
        s.scale = SC[mode]
        s.voices = []      # (key, instrument, volume, oct)
        s.data = {}
        s.chords = []      # midi pcs par mesure (pour l'analyse)
        s.sections = []
        s.alts = set()

    def voice(s, key, instrument, volume, oct=4):
        s.voices.append((key, instrument, volume, oct))
        s.data[key] = []

    def dm(s, d, alt, oct):
        i = d - 1
        return 12 * (oct + 1) + s.tonic + s.scale[i % 7] + 12 * (i // 7) + alt

    # ---------------------------------------------------------------- accords
    def chord(s, tok, oct=3):
        m = re.match(r"([b#]?)([1-7])(.*)$", tok)
        alt = 1 if m[1] == '#' else (-1 if m[1] == 'b' else 0)
        d = int(m[2])
        q = m[3]
        if alt:
            s.alts.add(tok)
        if q == '':
            return [s.dm(d, alt, oct), s.dm(d + 2, 0, oct), s.dm(d + 4, 0, oct)]
        root = s.dm(d, alt, oct)
        return [root + i for i in QUAL[q]]

    def voicing(s, ch, center):
        n = len(ch)
        best = None
        for inv in range(n):
            notes = ch[inv:] + [x + 12 for x in ch[:inv]]
            mean = sum(notes) / n
            sh = round((center - mean) / 12)
            notes = [x + 12 * sh for x in notes]
            cost = abs(sum(notes) / n - center)
            if best is None or cost < best[0]:
                best = (cost, notes)
        return sorted(best[1])

    # ---------------------------------------------------------------- mélodie
    def mel(s, text, oct, shift=0, vel=None):
        bars = []
        dflt = 2
        tokre = re.compile(r"^(r|[b#]?[1-7][',]*(?:\+[b#]?[1-7][',]*)*)(?::(\d+))?(?:@(\d))?$")
        for bar in text.split('|'):
            out = []
            tot = 0
            for tok in bar.split():
                if tok.startswith('='):
                    dflt = int(tok[1:])
                    continue
                m = tokre.match(tok)
                assert m, (s.id, tok)
                body, ln, v = m.groups()
                ln = int(ln) if ln else dflt
                if body == 'r':
                    out.append('r:%d' % ln)
                else:
                    ns = []
                    for part in body.split('+'):
                        mm = re.match(r"([b#]?)([1-7])([',]*)$", part)
                        alt = 1 if mm[1] == '#' else (-1 if mm[1] == 'b' else 0)
                        if alt:
                            s.alts.add(part)
                        o = oct + mm[3].count("'") - mm[3].count(',')
                        ns.append(s.dm(int(mm[2]) + shift, alt, o))
                    t = '+'.join(nm(x) for x in ns) + ':%d' % ln
                    if v:
                        t += '@' + v
                    out.append(t)
                tot += ln
            assert tot == s.bar, (s.id, bar.strip(), tot, s.bar)
            bars.append(addvel(' '.join(out), vel))
        return bars

    # ---------------------------------------------------------------- section
    def sec(s, name, chords, **specs):
        chs = chords.split()
        nb = len(chs)
        s.sections.append((name, nb))
        for ch in chs:
            s.chords.append(sorted(set(x % 12 for x in s.chord(ch))))
        for key, ins, vol, oct in s.voices:
            sp = specs.get(key)
            if sp is None:
                bars = ['r:%d' % s.bar] * nb
            elif isinstance(sp, str):
                bars = s.mel(sp, oct)
            elif isinstance(sp, M):
                bars = s.mel(sp.text, oct, sp.shift, sp.vel)
            else:
                bars = sp.render(s, chs)
            assert len(bars) == nb, (s.id, key, name, len(bars), nb)
            s.data[key] += bars

    def build(s):
        voices = []
        for key, ins, vol, oct in s.voices:
            bars = []
            for b in s.data[key]:
                if bars and re.fullmatch(r"r:\d+", bars[-1]) and re.fullmatch(r"r:\d+", b):
                    bars[-1] = 'r:%d' % (int(bars[-1][2:]) + int(b[2:]))
                else:
                    bars.append(b)
            if all(re.fullmatch(r"r:\d+", b) for b in bars):
                continue
            voices.append({'instrument': ins, 'volume': vol, 'len': 2, 'notes': bars})
        d = {'name': s.name, 'tempo': s.tempo, 'echo': s.echo, 'reverb': s.reverb}
        if not s.loop:
            d['loop'] = False
        if s.volume != 1.0:
            d['volume'] = s.volume
        d['voices'] = voices
        return d

    def meta(s):
        return {'id': s.id, 'tonic': s.tonic, 'scale': s.scale, 'bar': s.bar, 'chords': s.chords,
                'sections': s.sections, 'tempo': s.tempo, 'alts': sorted(s.alts)}


class M:
    def __init__(s, text, shift=0, vel=None):
        s.text, s.shift, s.vel = text, shift, vel


class Arp:
    def __init__(s, pat, center, vel=None):
        s.pat, s.center, s.vel = pat, center, vel

    def render(s, p, chs):
        out = []
        for ch in chs:
            v = p.voicing(p.chord(ch), s.center)
            n = len(v)
            toks = []
            tot = 0
            for t in s.pat.split():
                m = re.match(r"^([\d+\-]+|r):(\d+)(@\d)?$", t)
                assert m, t
                idx, ln, vl = m.groups()
                ln = int(ln)
                tot += ln
                if idx == 'r':
                    toks.append('r:%d' % ln)
                else:
                    ns = []
                    for i in idx.split('+'):
                        i = int(i)
                        ns.append(nm(v[i % n] + 12 * (i // n)))
                    toks.append('+'.join(ns) + ':%d' % ln + (vl or ''))
            assert tot == p.bar, (s.pat, tot)
            out.append(addvel(' '.join(toks), s.vel))
        return out


class Pad:
    def __init__(s, center, pick=None, vel=None, merge=True, add=None):
        s.center, s.pick, s.vel, s.merge, s.add = center, pick, vel, merge, add or []

    def render(s, p, chs):
        out = []
        groups = []
        for ch in chs:
            if s.merge and groups and groups[-1][0] == ch:
                groups[-1][1] += 1
            else:
                groups.append([ch, 1])
        for ch, n in groups:
            c = p.chord(ch)
            if s.pick is not None:
                c = [c[i] for i in s.pick]
                mean = sum(c) / len(c)
                sh = round((s.center - mean) / 12)
                v = sorted(x + 12 * sh for x in c)
            else:
                v = p.voicing(c, s.center)
            v = v + [v[0] + a for a in s.add]
            tok = '+'.join(nm(x) for x in v) + ':%d' % (p.bar * n)
            out.append(addvel(tok, s.vel))
            out += ['r:%d' % p.bar] * 0  # fusion : une seule note pour n mesures
            for _ in range(n - 1):
                out.append('')       # marqueur : mesure couverte par la note précédente
        # les mesures vides sont fusionnées avec la précédente
        res = []
        for b in out:
            if b == '':
                res.append('')
            else:
                res.append(b)
        return PadFix(res)


class PadFix(list):
    pass


class Bass:
    SYM = {'R': 0, 'F': 7, 'O': 12, 'D': -5, 'T': 4, 'm': 3}

    def __init__(s, pat, lo, vel=None):
        s.pat, s.lo, s.vel = pat, lo, vel

    def render(s, p, chs):
        out = []
        for ch in chs:
            c = p.chord(ch)
            rpc = c[0] % 12
            root = s.lo + ((rpc - s.lo) % 12)
            toks = []
            tot = 0
            for t in s.pat.split():
                m = re.match(r"^([RFODTm]|r):(\d+)(@\d)?$", t)
                assert m, t
                sym, ln, vl = m.groups()
                ln = int(ln)
                tot += ln
                if sym == 'r':
                    toks.append('r:%d' % ln)
                else:
                    toks.append(nm(root + Bass.SYM[sym]) + ':%d' % ln + (vl or ''))
            assert tot == p.bar, (s.pat, tot)
            out.append(addvel(' '.join(toks), s.vel))
        return out


class Drum:
    def __init__(s, pat, last=None, first=None, vel=None):
        s.pat, s.last, s.first, s.vel = pat, last, first, vel

    def render(s, p, chs):
        out = []
        for i in range(len(chs)):
            pat = s.pat
            if i == len(chs) - 1 and s.last:
                pat = s.last
            if i == 0 and s.first:
                pat = s.first
            tot = sum(int(re.match(r"^[^:]+:(\d+)", t)[1]) for t in pat.split())
            assert tot == p.bar, (pat, tot)
            out.append(addvel(pat, s.vel))
        return out


def fixpads(p):
    # Pad.render renvoie des mesures vides pour les mesures déjà couvertes : on les retire
    # en fusionnant leur durée dans la note (déjà comptée), donc simplement on les supprime
    pass


def finish_voice_bars(bars):
    return [b for b in bars if b != '']


# On redéfinit sec() pour traiter les pads : les mesures '' sont supprimées mais comptent.
_old_sec = Piece.sec


def _sec(s, name, chords, **specs):
    chs = chords.split()
    nb = len(chs)
    s.sections.append((name, nb))
    for ch in chs:
        s.chords.append(sorted(set(x % 12 for x in s.chord(ch))))
    for key, ins, vol, oct in s.voices:
        sp = specs.get(key)
        if sp is None:
            bars = ['r:%d' % s.bar] * nb
        elif isinstance(sp, str):
            bars = s.mel(sp, oct)
        elif isinstance(sp, M):
            bars = s.mel(sp.text, oct, sp.shift, sp.vel)
        else:
            bars = sp.render(s, chs)
        assert len(bars) == nb, (s.id, key, name, len(bars), nb)
        s.data[key] += [b for b in bars if b != '']


Piece.sec = _sec

OUT = {}
META = {}


def reg(p):
    OUT[p.id] = p.build()
    META[p.id] = p.meta()


# =============================================================== VILLAGE
def village():
    p = Piece('village', "Bittebourg, où tout tient debout", 116, 'g', 'major', 12, echo=0.18, reverb=0.25)
    p.voice('whistle', 'whistle', 0.5, 4)
    p.voice('fiddle', 'fiddle', 0.34, 4)
    p.voice('harp', 'harp', 0.34)
    p.voice('bourdon', 'strings', 0.15)
    p.voice('bass', 'bass', 0.34)
    p.voice('bodhran', 'drums', 0.3)
    a14 = ["=2 3 5 3 1':6", "=2 5 7 5 1':6", "=2 1' 6 4 6:6", "5:4 3:2 2:4 1:2"]
    a58 = ["=2 3 6 1' 3':6", "4':4 3':2 1':4 6:2", "=2 2' 7 5 7 2':4", "1':6 r:6"]
    ap58 = ["=2 6 1' 3' 1' 6 3", "=2 4 6 1' 6 4 6", "=2 5 7 2' 5' 2' 7", "1':8 5:4"]
    app58 = ["=2 3 6 1' 3':6", "4':4 3':2 1':4 6:2", "=2 2' 7 5 7 2':4", "1':12"]
    jig = "b:2@9 b:2@3 b:2@4 b:2@8 b:2@3 b:2@4"
    hA = Arp("0:2 1:2 2:2 3:2 2:2 1:2", 55)
    p.sec('A', "1 1 4 1 6 4 5 1",
          whistle=M('|'.join(a14 + a58), vel=5), harp=hA, bourdon=Pad(50, pick=[0, 2]), bass=Bass("R:6 F:6", 38))
    p.sec("A'", "1 1 4 1 6 4 5 1",
          whistle=M('|'.join(a14 + ap58), vel=6),
          fiddle="|".join(["=6 3, 5,", "=6 5, 3,", "=6 4, 6,", "=6 3, 5,", "=6 3, 6,", "=6 4, 6,", "=6 5, 7,", "5,:12"]),
          harp=hA, bourdon=Pad(50, pick=[0, 2]), bass=Bass("R:6 F:6", 38), bodhran=Drum(jig))
    p.sec('B', "4 1 4 1 b7M 4 5 5",
          fiddle="|".join(["=2 6 1' 4' 1' 6 1'", "=2 5 1' 3' 5':4 3'", "=2 4' 3' 1' 6 1' 3'", "1':6 5:3 3:3",
                           "=2 4' 2' b7 2' 4':4", "=2 4' 1' 6 1' 4':4", "=2 2' 4' 2' 7 5 7", "=2 5 7 2' 7 5:4"]),
          whistle="|".join(["r:12"] * 4 + ["b7:12", "1':12", "7:12", "5:12"]),
          harp=Arp("0:2 2:2 3:2 5:2 3:2 2:2", 55), bourdon=Pad(50, pick=[0, 2]), bass=Bass("R:6 O:3 F:3", 38), bodhran=Drum(jig))
    p.sec("A''", "1 1 4 1 6 4 5 1",
          whistle=M('|'.join(a14 + app58), vel=7),
          fiddle="|".join(["=6 3, 5,", "=6 5, 3,", "=6 4, 6,", "=6 3, 5,", "=6 3, 6,", "=6 4, 6,", "=6 5, 7,", "3,:12"]),
          harp=Arp("0:2 1:2 2:2 4:2 2:2 1:2", 55), bourdon=Pad(50, pick=[0, 2]), bass=Bass("R:6 F:3 R:3", 38), bodhran=Drum(jig))
    reg(p)


# =============================================================== FETE
def fete():
    p = Piece('fete', "La Fête des Amarres", 140, 'd', 'major', 16, echo=0.15, reverb=0.2)
    p.voice('fiddle', 'fiddle', 0.4, 4)
    p.voice('whistle', 'whistle', 0.3, 4)
    p.voice('harp', 'harp', 0.3)
    p.voice('strings', 'strings', 0.14)
    p.voice('bass', 'bass', 0.3)
    p.voice('bodhran', 'drums', 0.3)
    p.voice('hat', 'drums', 0.14)
    A = ["=2 3' 5' 3' 1' 5 1' 3' 1'", "=2 1' 6 1' 4' 2' 1' 6 4", "=2 5' 3' 1' 3' 5' 3' 1' 5",
         "=2 7 2' 7 5 7 2' 3' 2'", "=2 3' 5' 3' 1' 5 1' 3' 5'", "=2 2' 1' 6 1' 4' 3' 2' 1'",
         "=2 7 2' 7 5 7 2' 5' 2'", "=2 1' 3' 5' 3' 1':4 r:4"]
    B = ["=2 3' 1' 6 1' 3' 5' 3' 1'", "=2 6 1' 3' 6' 5' 3' 1' 6", "=2 4 6 1' 6 4' 1' 6 4",
         "=2 1' 2' 1' 6 4 6 1' 2'", "=2 5 7 2' 7 5' 2' 7 5", "=2 b7 2' 4' 2' b7 4' 2' b7",
         "=2 1' 3' 5' 3' 1' 5 3 1", "=2 3 5 1' 3' 5':4 r:4"]
    chA = "1 4 1 5 1 4 5 1"
    chB = "6 6 4 4 5 b7M 1 1"
    bod = "b:2@9 b:2@4 b:2@6 b:2@4 b:2@8 b:2@4 b:2@6 b:2@5"
    hat = "r:2 h:2 r:2 h:2 r:2 h:2 r:2 h:2"
    harp = Arp("r:2 0+1+2:2 r:2 0+1+2:2 r:2 0+1+2:2 r:2 0+1+2:2", 57)
    bas = Bass("R:4 F:4 R:4 F:4", 38)
    p.sec('A', chA, fiddle=M('|'.join(A), vel=6), harp=harp, bass=bas, bodhran=Drum(bod, last="k:2 s:2 k:2 s:2 k:1 s:1 k:1 s:1 k:2 s:2"[:0] or bod), hat=Drum(hat))
    p.sec("A'", chA, fiddle=M('|'.join(A), vel=6), whistle=M('|'.join(A), 7, vel=5), harp=harp, bass=bas,
          bodhran=Drum(bod), hat=Drum(hat))
    p.sec('B', chB, fiddle=M('|'.join(B), vel=6), harp=harp, strings=Pad(55, vel=5), bass=bas, bodhran=Drum(bod), hat=Drum(hat))
    p.sec("A''", chA, fiddle=M('|'.join(A), vel=7), whistle=M('|'.join(A), 7, vel=6), harp=harp, strings=Pad(55, vel=5), bass=bas,
          bodhran=Drum(bod, last="b:2@9 b:2@6 b:2@8 b:2@6 b:1@9 b:1@7 b:1@9 b:1@7 b:2@9 b:2@7"), hat=Drum(hat))
    reg(p)


# =============================================================== AUBERGE
def auberge():
    p = Piece('auberge', "Au Bon Mouillage", 92, 'a', 'dorian', 12, echo=0.18, reverb=0.3)
    p.voice('whistle', 'whistle', 0.4, 4)
    p.voice('fiddle', 'fiddle', 0.3, 4)
    p.voice('harp', 'harp', 0.36)
    p.voice('bass', 'bass', 0.3)
    p.voice('strings', 'strings', 0.16)
    p.voice('bodhran', 'drums', 0.24)
    A = ["5,:6 1:2 3:4", "2:6 1:2 7,:4", "1:4 5,:4 3,:4", "4,:6 6,:2 1:4",
         "3:6 7,:2 5,:4", "7,:6 2:2 4:4", "5,:4 7,:4 2:4", "1:8 r:4"]
    B = ["6:4 4:4 1:4", "4:6 1:2 6,:4", "3:4 1:4 5,:4", "1:6 2:2 3:4",
         "7,:4 2:4 4:4", "3:6 2:2 1:4", "2:4 7,:4 5,:4", "5,:8 r:4"]
    chA = "1 7 1 4 3 7 5 1"
    chB = "4 4 1 1 7 3 5 5"
    harp = Arp("r:4 1+2:4 1+2:4", 57)
    bas = Bass("R:4 r:4 F:4", 33)
    bod = "b:4@5 r:4 b:4@3"
    p.sec('A', chA, whistle=M('|'.join(A), vel=5), harp=harp, bass=bas)
    p.sec('B', chB, fiddle=M('|'.join(B), vel=5), whistle="|".join(["r:12"] * 4 + ["r:12"] * 4),
          harp=harp, bass=bas, strings=Pad(52, vel=4), bodhran=Drum(bod))
    A2 = A[:7] + ["1:12"]
    p.sec("A'", chA, fiddle=M('|'.join(A), vel=6), whistle=M('|'.join(A2), 7, vel=5), harp=harp, bass=bas,
          strings=Pad(52, vel=5), bodhran=Drum(bod))
    reg(p)


# =============================================================== CAMPAGNE
def campagne():
    p = Piece('campagne', "Le Pré Couché", 88, 'a', 'mixolydian', 16, echo=0.25, reverb=0.35)
    p.voice('flute', 'flute', 0.42, 4)
    p.voice('horn', 'horn', 0.24, 4)
    p.voice('harp', 'harp', 0.32)
    p.voice('strings', 'strings', 0.18)
    p.voice('bass', 'bass', 0.3)
    p.voice('bodhran', 'drums', 0.2)
    A = ["=2 1 3 5 3 1:4 5,:4", "=2 7, 2 4 2 7,:4 4,:4", "=2 4 6 1' 6 4:4 1:4", "=2 5 3 1 3 5:4 3:4",
         "6,:4 1:4 3:4 1:4", "4:4 6:4 1':4 6:4", "7,:4 2:4 4:4 2:4", "1:8 r:8"]
    B = ["4:8 6:4 1':4", "3':8 1':4 5:4", "6:6 5:2 3:4 1:4", "5:8 3:4 1:4",
         "4:4 6:4 1':8", "7:6 5:2 2:8", "7,:4 2:4 4:4 7:4", "5:4 3:4 1:8"]
    A2 = A[:3] + ["=2 5 3 1 3 1:8"]
    arp = Arp("0:2 1:2 2:2 1:2 3:2 2:2 1:2 2:2", 57)
    bas = Bass("R:8 F:8", 33)
    p.sec('A', "1 7 4 1 6 4 7 1", flute=M('|'.join(A), vel=5), harp=arp, strings=Pad(52, vel=5), bass=bas)
    p.sec('B', "4 1 6 1 4 5 7 1", flute=M('|'.join(B), vel=6), horn=Pad(50, pick=[0, 2], vel=5), harp=arp, strings=Pad(52, vel=5),
          bass=bas, bodhran=Drum("b:4@5 r:4 b:4@4 r:4"))
    p.sec("A'", "1 7 4 1", flute=M('|'.join(A2), vel=6), horn=Pad(50, pick=[0, 2], vel=4), harp=arp, strings=Pad(52, vel=4), bass=bas)
    reg(p)


# =============================================================== BOIS
def bois():
    p = Piece('bois', "Le Bois Penché", 60, 'b', 'aeolian', 16, echo=0.32, reverb=0.45)
    p.voice('whistle', 'whistle', 0.34, 4)
    p.voice('reed', 'reed', 0.3, 4)
    p.voice('bell', 'bell', 0.28)
    p.voice('strings', 'strings', 0.2)
    p.voice('choir', 'choir', 0.16)
    p.voice('drone', 'strings', 0.22)
    p.voice('timp', 'drums', 0.3)
    A = ["r:16", "r:8 5:4 3:4", "3:8 1:4 r:4", "r:16", "4:6 6:2 1':8", "7:4 6:4 4:8", "5:8 2:4 7,:4", "r:16"]
    B = ["6,:8 1:4 3:4", "7,:6 2:2 4:8", "1:8 3:4 5:4", "5:12 r:4", "4:4 6:4 1':8", "6:6 3:2 1:8", "5:8 7:4 2':4", "2':12 r:4"]
    chA = "1 1 6 6 4 4 5 5"
    chB = "6 7 1 1 4 6 5 5"
    p.sec('A', chA, whistle=M('|'.join(A), vel=4), bell=Arp("0:2 r:2 2:2 r:2 1:2 r:2 3:2 r:2", 76, vel=4),
          strings=Pad(55, vel=4), drone=Pad(40, pick=[0, 2]), choir=None)
    p.sec('B', chB, reed=M('|'.join(B), vel=5), bell=Arp("0:4 2:4 1:4 r:4", 76, vel=5), strings=Pad(55, vel=5),
          choir=Pad(60, vel=5), drone=Pad(40, pick=[0, 2]),
          timp=Drum("r:16", first="t:4@3 r:12"))
    reg(p)


# =============================================================== MARAIS
def marais():
    p = Piece('marais', "La Roselière", 66, 'd', 'phrygian', 12, echo=0.3, reverb=0.4)
    p.voice('reed', 'reed', 0.34, 4)
    p.voice('harp', 'harp', 0.34)
    p.voice('bell', 'bell', 0.22)
    p.voice('strings', 'strings', 0.2)
    p.voice('choir', 'choir', 0.16)
    p.voice('bass', 'bass', 0.36)
    p.voice('timp', 'drums', 0.28)
    A = ["1:6 3:3 5:3", "5:6 3:3 1:3", "2:6 4:3 6:3", "5:6 3:3 1:3", "6:6 1':3 3':3", "7:6 4:3 2:3"]
    B = ["1':6 6:3 3:3", "6:6 1':6", "2':6 7:3 4:3", "4:6 7:6", "6:6 4:3 2:3", "1:12"]
    A2 = A[:4] + ["2:6 4:3 6:3", "1:12"]
    arp = Arp("0:3 2:3 1:3 2:3", 48)
    p.sec('A', "1 1 2 1 6 7", reed=M('|'.join(A), vel=5), harp=arp, bell=Arp("r:6 0:6", 84, vel=4), strings=Pad(52, vel=4),
          bass=Bass("R:12", 26), timp=Drum("r:12", first="t:3@4 r:9"))
    p.sec('B', "6 6 7 7 2 1", reed=M('|'.join(B), vel=6), harp=arp, bell=Arp("r:6 0:6", 84, vel=4), strings=Pad(52, vel=5),
          choir=Pad(58, vel=4), bass=Bass("R:12", 26), timp=Drum("r:12", first="t:3@5 r:9"))
    p.sec("A'", "1 1 2 1 2 1", reed=M('|'.join(A2), vel=5), harp=arp, bell=Arp("r:6 0:6", 84, vel=4), strings=Pad(52, vel=4),
          choir=Pad(58, vel=3), bass=Bass("R:12", 26), timp=Drum("r:12", first="t:3@4 r:9"))
    reg(p)


# =============================================================== COMBAT
def combat():
    p = Piece('combat', "Aux armes, si vraiment il le faut", 168, 'e', 'aeolian', 16, echo=0.12, reverb=0.2)
    p.voice('brass', 'brass', 0.4, 4)
    p.voice('horn', 'horn', 0.3, 4)
    p.voice('spic', 'spic', 0.24)
    p.voice('bass', 'bass', 0.3)
    p.voice('drums', 'drums', 0.32)
    p.voice('timp', 'drums', 0.34)
    A = ["1:3 1:1 3:4 5:4 3:2 1:2", "5:3 5:1 1':4 7:4 5:4", "6:4 1':4 3':4 1':4", "7:4 2':4 4':8",
         "3':6 1':2 5:8", "4:4 6:4 1':4 6:4", "5:4 7:4 2':4 7:4", "1':12 r:4"]
    B = ["3:4 5:4 7:4 3':4", "7:6 4':2 2':8", "1':6 7:2 5:8", "6:4 1':4 3':8",
         "3':8 7:4 5:4", "7:4 2':4 4':4 2':4", "6:6 3':2 1':4 6:4", "5:4 7:4 2':8"]
    chA = "1 1 6 7 1 4 5 1"
    chB = "3 7 1 6 3 7 6 5"
    kit = "k:2 h:2 s:2 h:2 k:2 k:2 s:2 h:2"
    fill = "s:2 s:2 s:2 s:2 s:1 s:1 s:1 s:1 s:1 s:1 s:1 s:1"
    osA = Arp("0:2 1:2 2:2 1:2 0:2 1:2 2:2 1:2", 59)
    osB = Arp("0:1 1:1 2:1 1:1 0:1 1:1 2:1 1:1 0:1 1:1 2:1 1:1 0:1 1:1 2:1 1:1", 59)
    bA = Bass("R:4 R:2 O:2 R:4 R:2 O:2", 40)
    bB = Bass("R:2 R:2 F:2 R:2 R:2 F:2 O:2 F:2", 40)
    tp = "t:8@8 t:4@6 t:4@6"
    p.sec('A', chA, brass=M('|'.join(A), vel=6), spic=osA, bass=bA, drums=Drum(kit, last=fill), timp=Drum(tp))
    p.sec('B', chB, brass=M('|'.join(B), vel=7), horn=M('|'.join(B), -7, vel=5), spic=osB, bass=bB, drums=Drum(kit, last=fill),
          timp=Drum(tp))
    p.sec("A'", chA, brass=M('|'.join(A), vel=7), horn=M('|'.join(A), -7, vel=6), spic=osB, bass=bA, drums=Drum(kit, last=fill),
          timp=Drum(tp))
    p.sec("B'", chB, brass=M('|'.join(B), vel=8), horn=M('|'.join(B), -7, vel=6), spic=osB, bass=bB, drums=Drum(kit, last="k:2 s:1 s:1 k:2 s:1 s:1 k:2 s:2 s:1 s:1 s:1"[:0] or fill),
          timp=Drum(tp, last="t:1@5 t:1@6 t:1@6 t:1@7 t:1@7 t:1@8 t:1@8 t:1@9 t:2@9 t:2@9 t:2@9 t:2@9"))
    reg(p)


# =============================================================== BOSS
def boss():
    p = Piece('boss', "Ce qui ne dort jamais", 156, 'c', 'phrygian', 14, echo=0.14, reverb=0.3)
    p.voice('lowbrass', 'lowbrass', 0.36, 3)
    p.voice('brass', 'brass', 0.36, 4)
    p.voice('choir', 'choir', 0.22)
    p.voice('strings', 'strings', 0.2)
    p.voice('spic', 'spic', 0.2)
    p.voice('bass', 'bass', 0.3)
    p.voice('timp', 'drums', 0.34)
    p.voice('kit', 'drums', 0.28)
    A = ["1:4 3:4 5:6", "6:4 3:4 1':6", "5:6 3:4 1:4", "2:4 4:4 6:6", "1:4 5:4 1':6", "6:4 1':4 3':6", "7:4 2':4 4':6", "1':8 5:6"]
    B = ["1:6 5:4 3':4", "6:6 3':4 1':4", "2:6 4:4 6:4", "7:6 2':4 4':4", "1':6 7:4 5:4", "6:4 1':4 3':6", "2':6 4':4 2':4", "1':8 r:6"]
    C = ["6:4 1':4 3':6", "7:4 2':4 4':6", "1':4 3':4 5':6", "2':4 4':4 6':6", "6':4 3':4 1':6", "7:4 4':4 2':6", "2':4 4':4 6:6", "1':6 5:8"]
    chA = "1 6 1 2 1 6 7 1"
    chB = "1 6 2 7 1 6 2 1"
    chC = "6 7 1 2 6 7 2 1"
    bA = Bass("R:4@9 R:2@5 R:2@5 R:2@6 F:2@5 R:2@5", 36)
    bB = Bass("R:4@9 R:2@5 R:2@6 R:2@5 F:2@6 R:2@5", 36)
    tA = "t:4@9 r:4 t:6@6"
    kit = "k:4@9 s:4@7 k:2@8 r:2 s:2@6"
    osc = Arp("0:2 2:2 1:2 0:2 2:2 1:2 0:2", 55)
    chp = Pad(55, pick=[0, 2])
    p.sec('A', chA, lowbrass=M('|'.join(A), vel=7), bass=bA, timp=Drum(tA), choir=Pad(55, pick=[0, 2], vel=3))
    p.sec('B', chB, brass=M('|'.join(B), vel=7), lowbrass=M('|'.join(B), -7, vel=6), choir=chp, bass=bB, timp=Drum(tA), kit=Drum(kit))
    p.sec('C', chC, brass=M('|'.join(C), vel=8), lowbrass=M('|'.join(C), -7, vel=6), choir=chp, strings=Pad(60, vel=5), spic=osc,
          bass=bB, timp=Drum(tA), kit=Drum(kit),)
    p.sec("A'", chA, lowbrass=M('|'.join(A), vel=8), brass=M('|'.join(A), vel=7), choir=chp, strings=Pad(60, vel=5), spic=osc, bass=bA,
          timp=Drum(tA, last="t:1@4 t:1@5 t:1@5 t:1@6 t:1@6 t:1@7 t:1@7 t:1@8 t:1@8 t:1@8 t:1@9 t:1@9 t:1@9 t:1@9"), kit=Drum(kit))
    reg(p)


# =============================================================== MENACE
def menace():
    p = Piece('menace', "Neuf petits anneaux", 58, 'e', 'phrygian', 20, echo=0.3, reverb=0.45)
    p.voice('horn', 'horn', 0.42, 3)
    p.voice('lowbrass', 'lowbrass', 0.3, 3)
    p.voice('choir', 'choir', 0.26)
    p.voice('bass', 'bass', 0.3)
    p.voice('bell', 'bell', 0.24)
    p.voice('timp', 'drums', 0.34)
    A = ["1:12 5:8", "r:8 5:4 3:8", "2:12 6:8", "7,:12 5,:8", "1:20"]
    B = ["1:8 5:4 1':8", "6:8 3:4 1:8", "2:8 4:4 6:8", "7,:8 5,:4 7,:8", "1:12 r:8"]
    ch = "1P 1P 2P 7P 1P 1P 6P 2P 7P 1P"
    p.sec('A', "1P 1P 2P 7P 1P", horn=M('|'.join(A), vel=5), choir=Pad(55, vel=4), bass=Bass("R:20", 28, vel=5),
          bell=Arp("r:12 0:8", 76, vel=3), timp=Drum("r:20", first="t:4@9 r:16"))
    p.sec('B', "1P 6P 2P 7P 1P", horn=M('|'.join(B), vel=6), lowbrass=M('|'.join(B), -7, vel=5), choir=Pad(55, vel=6),
          bass=Bass("R:20", 28, vel=6), bell=Arp("r:12 0:8", 76, vel=4), timp=Drum("t:4@6 r:4 t:4@4 r:8", first="t:4@9 r:16", last="t:4@8 r:16"))
    reg(p)


# =============================================================== VICTOIRE
def victoire():
    p = Piece('victoire', "Victoire, et pas trop tôt", 126, 'bb', 'major', 16, echo=0.2, reverb=0.3, loop=False)
    p.voice('brass', 'brass', 0.46, 3)
    p.voice('horn', 'horn', 0.3, 3)
    p.voice('strings', 'strings', 0.22)
    p.voice('bass', 'bass', 0.26)
    p.voice('timp', 'drums', 0.3)
    A = ["1:3 1:1 5:4 1':8", "6:3 6:1 1':4 4':8", "7:3 7:1 2':4 5':8", "1':6 7:2 1':8",
         "4':4 6':4 1'':8", "5':4 7':4 2'':8", "2'':6 7':2 5':8", "1'':16"]
    p.sec('fanfare', "1 4 5 1 4 5 5 1", brass=M('|'.join(A), vel=7), horn=Pad(58, vel=5), strings=Pad(63, vel=5),
          bass=Bass("R:4 R:4 F:4 R:4", 34),
          timp=Drum("t:4@8 r:4 t:2@6 t:2@6 t:4@7", last="t+c:16@9"))
    reg(p)


for f in (village, fete, auberge, campagne, bois, marais, combat, boss, menace, victoire):
    f()

# titre en dernier (ordre du fichier réorganisé plus bas)


def titre():
    p = Piece('titre', "Le magicien qui remettait à demain", 72, 'f', 'major', 16, echo=0.25, reverb=0.4)
    p.voice('horn', 'horn', 0.46, 4)
    p.voice('flute', 'flute', 0.4, 4)
    p.voice('brass', 'brass', 0.36, 4)
    p.voice('strings', 'strings', 0.22)
    p.voice('harp', 'harp', 0.3)
    p.voice('cello', 'strings', 0.28)
    p.voice('choir', 'choir', 0.2)
    p.voice('timp', 'drums', 0.4)
    A = ["1:6 5:2 1':8", "7:4 6:4 5:4 3:4", "4:6 6:2 1':4 2':4", "1':8 5:4 3:4",
         "6:6 1':2 3':8", "2':4 1':4 6:4 4:4", "5:4 7:4 2':8", "2':6 7:2 5:8"]
    A2 = A[:7] + ["5:4 3':4 2':4 1':4"]
    B = ["2:4 4:4 6:8", "1':4 3':4 1':4 6:4", "2':8 1':4 6:4", "1':6 7:2 1':8",
         "2':6 1':2 2':4 4':4", "2':8 7:4 5:4", "3:8 5:4 7:4", "5:6 2':2 5:8"]
    harpA = Arp("0:2 1:2 2:2 1:2 3:2 2:2 1:2 2:2", 53)
    harpB = Arp("0:4 2:2 1:2 3:4 2:2 1:2", 53)
    cel = Bass("R:16", 36)
    p.sec('A', "1 3 4 1 6 4 5 5", horn=M('|'.join(A), vel=5), strings=Pad(57, vel=4), harp=harpA, cello=cel,
          timp=Drum("r:16", first="r:16", last="t:4@4 r:12"))
    p.sec('B', "2 6 4 1 2 5 3 5", flute=M('|'.join(B), vel=5), strings=Pad(57, vel=5), harp=harpB, cello=cel,
          choir=Pad(60, vel=4), timp=Drum("r:16", last="t:4@5 r:12"))
    p.sec("A'", "1 3 4 1 6 4 5 1", brass=M('|'.join(A2), vel=7), horn=M('|'.join(A2), -7, vel=6), strings=Pad(57, vel=6),
          harp=harpA, cello=cel, choir=Pad(60, vel=5),
          timp=Drum("t:4@7 r:4 t:4@5 r:4", last="t+c:4@9 r:12"))
    reg(p)


titre()

ORDER = ['titre', 'village', 'fete', 'auberge', 'campagne', 'bois', 'marais', 'combat', 'boss', 'menace', 'victoire']


def fmt_value(v):
    return json.dumps(v, ensure_ascii=False)


def write(path):
    lines = ['{']
    for ti, id in enumerate(ORDER):
        t = OUT[id]
        lines.append('\t%s: {' % json.dumps(id))
        lines.append('\t\t"name": %s,' % json.dumps(t['name'], ensure_ascii=False))
        head = '\t\t"tempo": %d, "echo": %s, "reverb": %s' % (t['tempo'], t['echo'], t['reverb'])
        if 'loop' in t:
            head += ', "loop": false'
        if 'volume' in t:
            head += ', "volume": %s' % t['volume']
        lines.append(head + ',')
        lines.append('\t\t"voices": [')
        for vi, v in enumerate(t['voices']):
            lines.append('\t\t\t{"instrument": "%s", "volume": %s, "len": 2, "notes": [' % (v['instrument'], v['volume']))
            for bi, b in enumerate(v['notes']):
                lines.append('\t\t\t\t%s%s' % (json.dumps(b), ',' if bi < len(v['notes']) - 1 else ''))
            lines.append('\t\t\t]}%s' % (',' if vi < len(t['voices']) - 1 else ''))
        lines.append('\t\t]')
        lines.append('\t}%s' % (',' if ti < len(ORDER) - 1 else ''))
    lines.append('}')
    open(path, 'w', encoding='utf-8').write('\n'.join(lines) + '\n')


if __name__ == '__main__':
    write(sys.argv[1])
    json.dump(META, open(sys.argv[2], 'w'))
    for id in ORDER:
        print(id, OUT[id]['tempo'], len(OUT[id]['voices']), 'voix')
