extends Node
## Musique du jeu, synthétisée par code à partir de data/music.json (aucun fichier audio).
## Chaque morceau est calculé une fois en tâche de fond, puis gardé sur le disque
## (user://musique) : les lancements suivants le rechargent tel quel.
##
## Notation d'une voix : des notes séparées par des espaces. « c4 » = do de l'octave 4,
## « f#3 » = fa dièse, « bb2 » = si bémol, « r » = silence, « c4+e4+g4 » = accord.
## « :8 » fixe la durée en pas (un pas = une double croche) ; sans cela, la durée est le
## champ « len » de la voix. L'octave est retenue d'une note à la suivante.
## Batterie (instrument « drums ») : k = grosse caisse, s = caisse claire, h = charleston.

const RATE := 22050
const TABLE := 1024
const MASK := TABLE - 1
const VERSION := 1
const VOLUME_DB := -9.0
const SILENT_DB := -50.0
const CACHE_DIR := "user://musique"
const SEMITONES := {"c": 0, "d": 2, "e": 4, "f": 5, "g": 7, "a": 9, "b": 11}

## harm : force de chaque harmonique ; attack et release en secondes ; decay : vitesse à
## laquelle le son retombe vers « sustain » ; vibrato et chorus : écarts de hauteur.
const INSTRUMENTS := {
	"flute": {"harm": [1.0, 0.28, 0.08, 0.03], "attack": 0.045, "decay": 0.0, "sustain": 1.0, "release": 0.12, "vibrato": 0.005},
	"reed": {"harm": [1.0, 0.0, 0.42, 0.0, 0.2, 0.0, 0.1, 0.0, 0.05], "attack": 0.03, "decay": 0.0, "sustain": 1.0, "release": 0.08, "vibrato": 0.004},
	"pluck": {"harm": [1.0, 0.5, 0.33, 0.2, 0.12, 0.08, 0.05], "attack": 0.004, "decay": 4.5, "sustain": 0.0, "release": 0.2},
	"bell": {"harm": [1.0, 0.1, 0.45, 0.05, 0.22, 0.0, 0.1], "attack": 0.002, "decay": 3.0, "sustain": 0.0, "release": 0.5},
	"strings": {"harm": [1.0, 0.5, 0.33, 0.25, 0.2, 0.16, 0.12, 0.09, 0.06, 0.04], "attack": 0.12, "decay": 0.0, "sustain": 1.0, "release": 0.25, "chorus": 0.006},
	"brass": {"harm": [1.0, 0.7, 0.5, 0.35, 0.22, 0.12, 0.06], "attack": 0.03, "decay": 2.0, "sustain": 0.7, "release": 0.08, "chorus": 0.003},
	"bass": {"harm": [1.0, 0.5, 0.18, 0.1], "attack": 0.005, "decay": 2.5, "sustain": 0.45, "release": 0.06},
	"square": {"harm": [1.0, 0.0, 0.33, 0.0, 0.2, 0.0, 0.14, 0.0, 0.11], "attack": 0.005, "decay": 1.5, "sustain": 0.6, "release": 0.05}
}

var current := ""               # identifiant du morceau demandé ("" = silence)
var _enabled := true            # faux sans carte son (tests sans fenêtre) : rien n'est calculé
var _streams: Dictionary = {}
var _pending: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _tweens: Array = [null, null]
var _active := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_enabled = DisplayServer.get_name() != "headless"
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = SILENT_DB
		add_child(p)
		_players.append(p)
	if _enabled:
		DirAccess.make_dir_recursive_absolute(CACHE_DIR)
		for id: String in Database.music:
			_prepare(id)


# ------------------------------------------------------------------- lecture

## Joue un morceau en boucle, avec un fondu depuis le précédent. "" = silence.
func play(id: String, fade: float = 0.9) -> void:
	if id == current:
		return
	current = id
	if not _enabled:
		return
	if _streams.has(id):
		_start(id, fade)
	else:
		_fade_player(_active, fade)
		_prepare(id)


func stop(fade: float = 0.9) -> void:
	play("", fade)


## Morceau par défaut d'un usage : "title", "battle", "victory" (data/game.json, « music »).
func default(kind: String) -> String:
	var table: Variant = Database.game.get("music", {})
	return str((table as Dictionary).get(kind, "")) if table is Dictionary else ""


## Morceau d'une carte : le premier « music_states » dont la condition est vraie, sinon « music ».
func for_map(map: Dictionary) -> String:
	for s: Variant in map.get("music_states", []):
		if s is Dictionary and GameState.check(str(s.get("if", ""))):
			return str(s.get("music", ""))
	return str(map.get("music", ""))


func for_encounter(encounter: Dictionary) -> String:
	return str(encounter.get("music", default("battle")))


func _start(id: String, fade: float) -> void:
	var previous := _active
	_active = 1 - _active
	var p := _players[_active]
	_kill_tween(_active)
	var track: Dictionary = Database.music.get(id, {})
	p.stream = _streams[id]
	p.volume_db = SILENT_DB
	p.play()
	var target := VOLUME_DB + linear_to_db(clampf(float(track.get("volume", 1.0)), 0.05, 2.0))
	var tw := create_tween()
	tw.tween_property(p, "volume_db", target, maxf(0.05, fade * 0.6))
	_tweens[_active] = tw
	_fade_player(previous, fade)


func _fade_player(index: int, fade: float) -> void:
	_kill_tween(index)
	var p := _players[index]
	if not p.playing:
		return
	var tw := create_tween()
	tw.tween_property(p, "volume_db", SILENT_DB, maxf(0.05, fade))
	tw.tween_callback(p.stop)
	_tweens[index] = tw


func _kill_tween(index: int) -> void:
	var tw: Variant = _tweens[index]
	if tw is Tween and (tw as Tween).is_valid():
		(tw as Tween).kill()
	_tweens[index] = null


# ------------------------------------------------------------ mise en mémoire

func _prepare(id: String) -> void:
	if _streams.has(id) or _pending.has(id) or not Database.music.has(id):
		return
	var track: Dictionary = Database.music[id]
	var file := "%s_%d.pcm" % [id, (JSON.stringify(track) + str(VERSION)).hash()]
	var path := CACHE_DIR + "/" + file
	if FileAccess.file_exists(path):
		_store(id, FileAccess.get_file_as_bytes(path))
		return
	for old in DirAccess.get_files_at(CACHE_DIR):   # anciennes versions du même morceau
		if old.begins_with(id + "_") and old != file and old.trim_prefix(id + "_").get_basename().is_valid_int():
			DirAccess.remove_absolute(CACHE_DIR + "/" + old)
	_pending[id] = true
	WorkerThreadPool.add_task(_render_task.bind(id, track.duplicate(true), path))


func _render_task(id: String, track: Dictionary, path: String) -> void:
	var bytes := render(track)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_buffer(bytes)
		f.close()
	_store.call_deferred(id, bytes)


func _store(id: String, bytes: PackedByteArray) -> void:
	_pending.erase(id)
	if bytes.size() < 4:
		return
	var track: Dictionary = Database.music.get(id, {})
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = bytes
	if bool(track.get("loop", true)):
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = bytes.size() / 2
	_streams[id] = wav
	if id == current:
		_start(id, 0.9)


# ------------------------------------------------------------------ partition

## Lit une voix : renvoie {"events": [[début, durée, [notes]]...], "length": pas}.
func parse_voice(voice: Dictionary, errors: Array = []) -> Dictionary:
	var unit := maxi(1, int(voice.get("len", 2)))
	var octave := int(voice.get("octave", 4))
	var drums := str(voice.get("instrument", "")) == "drums"
	var raw: Variant = voice.get("notes", "")
	var text := ""
	if raw is Array:
		for part: Variant in raw:
			text += str(part) + " "
	else:
		text = str(raw)
	var events: Array = []
	var pos := 0
	for token in text.split(" ", false):
		var parts := token.split(":")
		var length := unit
		if parts.size() > 1:
			if not parts[1].is_valid_int() or int(parts[1]) < 1:
				errors.append("durée illisible : " + token)
				continue
			length = int(parts[1])
		if parts[0] != "r":
			var pitches: Array = []
			for pn in parts[0].split("+"):
				if drums:
					if pn == "k" or pn == "s" or pn == "h":
						pitches.append(pn)
					else:
						errors.append("percussion inconnue : " + token)
					continue
				var letter := pn.substr(0, 1)
				if not SEMITONES.has(letter):
					errors.append("note illisible : " + token)
					continue
				var k := 1
				var accidental := 0
				if k < pn.length() and pn[k] == "#":
					accidental = 1
					k += 1
				elif k < pn.length() and pn[k] == "b":
					accidental = -1
					k += 1
				var rest := pn.substr(k)
				if rest != "":
					if not rest.is_valid_int():
						errors.append("octave illisible : " + token)
						continue
					octave = int(rest)
				pitches.append(12 * (octave + 1) + int(SEMITONES[letter]) + accidental)
			if not pitches.is_empty():
				events.append([pos, length, pitches])
		pos += length
	return {"events": events, "length": pos}


## Vérifie un morceau ; renvoie la liste des problèmes (vide = tout va bien).
func check_track(track: Dictionary) -> Array:
	var errors: Array = []
	if float(track.get("tempo", 0)) < 30.0:
		errors.append("tempo absent ou trop lent")
	var voices: Variant = track.get("voices", [])
	if not (voices is Array) or (voices as Array).is_empty():
		errors.append("aucune voix")
		return errors
	var lengths: Array = []
	var total := 0
	for v: Variant in voices:
		if not (v is Dictionary):
			errors.append("voix mal formée")
			continue
		var ins := str(v.get("instrument", ""))
		if ins != "drums" and not INSTRUMENTS.has(ins):
			errors.append("instrument inconnu : " + ins)
		var p := parse_voice(v, errors)
		if int(p["length"]) == 0:
			errors.append("voix vide")
			continue
		lengths.append(int(p["length"]))
		total = maxi(total, int(p["length"]))
	for l: int in lengths:
		if total % l != 0:
			errors.append("une voix de %d pas ne tombe pas juste dans un morceau de %d pas" % [l, total])
	return errors


# ------------------------------------------------------------------- synthèse

## Calcule le morceau : échantillons 16 bits mono à RATE hertz.
func render(track: Dictionary) -> PackedByteArray:
	var voices: Array = track.get("voices", [])
	var step := 60.0 / maxf(30.0, float(track.get("tempo", 100))) / 4.0 * RATE
	var loop := bool(track.get("loop", true))
	var parsed: Array = []
	var total := 0
	for v: Variant in voices:
		var p := parse_voice(v as Dictionary)
		parsed.append(p)
		total = maxi(total, int(p["length"]))
	if total == 0:
		return PackedByteArray()
	var n := int(round(total * step)) + (0 if loop else int(RATE * 0.8))
	var buf := PackedFloat32Array()
	buf.resize(n)
	buf.fill(0.0)
	var sine := _table([1.0])
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261118
	for vi in voices.size():
		var voice: Dictionary = voices[vi]
		var p: Dictionary = parsed[vi]
		var vlen := int(p["length"])
		if vlen == 0:
			continue
		var amp := float(voice.get("volume", 0.4))
		var ins_name := str(voice.get("instrument", "flute"))
		var reps := maxi(1, total / vlen)
		var ins: Dictionary = INSTRUMENTS.get(ins_name, INSTRUMENTS["flute"])
		var table := _table(ins["harm"])
		for r in reps:
			for e: Array in p["events"]:
				var start := int((r * vlen + int(e[0])) * step)
				var notes: Array = e[2]
				if ins_name == "drums":
					for d: String in notes:
						_drum(buf, n, loop, start, d, amp, rng)
					continue
				var dur := int(int(e[1]) * step)
				var a := amp / sqrt(float(notes.size()))
				for m: int in notes:
					_note(buf, n, loop, start, dur, 440.0 * pow(2.0, (m - 69) / 12.0), a, ins, table, sine)
	var out := buf
	var echo := clampf(float(track.get("echo", 0.25)), 0.0, 0.6)
	if echo > 0.0:
		out = buf.duplicate()
		var delay := int(3.0 * step)
		for i in n:
			var a1 := i - delay
			var a2 := i - 2 * delay
			if loop:
				a1 = posmod(a1, n)
				a2 = posmod(a2, n)
			if a1 >= 0:
				out[i] += buf[a1] * echo
			if a2 >= 0:
				out[i] += buf[a2] * echo * echo
	var peak := 0.001
	for i in n:
		peak = maxf(peak, absf(out[i]))
	var gain := 0.85 / peak * 32767.0
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(out[i] * gain))
	return bytes


func _table(harm: Array) -> PackedFloat32Array:
	var t := PackedFloat32Array()
	t.resize(TABLE)
	var peak := 0.001
	for i in TABLE:
		var s := 0.0
		for h in harm.size():
			if float(harm[h]) != 0.0:
				s += float(harm[h]) * sin(TAU * float(h + 1) * float(i) / TABLE)
		t[i] = s
		peak = maxf(peak, absf(s))
	for i in TABLE:
		t[i] /= peak
	return t


func _note(buf: PackedFloat32Array, n: int, loop: bool, start: int, dur: int, freq: float, amp: float, ins: Dictionary, table: PackedFloat32Array, sine: PackedFloat32Array) -> void:
	var attack := maxi(1, int(float(ins.get("attack", 0.01)) * RATE))
	var release := maxi(1, int(float(ins.get("release", 0.1)) * RATE))
	var sustain := float(ins.get("sustain", 1.0))
	var decay_k := exp(-float(ins.get("decay", 0.0)) / RATE)
	var vib := float(ins.get("vibrato", 0.0))
	var chorus := float(ins.get("chorus", 0.0))
	var inc := freq / RATE
	var inc2 := inc * (1.0 + chorus)
	var vinc := 5.5 / RATE * TABLE
	var ph := 0.0
	var ph2 := 0.25
	var d := 1.0
	var total := dur + release
	for i in total:
		if vib > 0.0 and i > 2500:
			ph += inc * (1.0 + vib * sine[int(i * vinc) & MASK])
		else:
			ph += inc
		var v := table[int(ph * TABLE) & MASK]
		if chorus > 0.0:
			ph2 += inc2
			v = (v + table[int(ph2 * TABLE) & MASK]) * 0.5
		var env := sustain + (1.0 - sustain) * d
		d *= decay_k
		if i < attack:
			env *= float(i) / attack
		if i >= dur:
			env *= 1.0 - float(i - dur) / release
		var j := start + i
		if j >= n:
			if not loop:
				break
			j %= n
		buf[j] += v * env * amp


func _drum(buf: PackedFloat32Array, n: int, loop: bool, start: int, kind: String, amp: float, rng: RandomNumberGenerator) -> void:
	var length := int(RATE * (0.16 if kind == "k" else (0.14 if kind == "s" else 0.04)))
	var ph := 0.0
	var prev := 0.0
	for i in length:
		var t := float(i) / length
		var v := 0.0
		if kind == "k":
			ph += lerpf(150.0, 45.0, t) / RATE
			v = sin(ph * TAU) * (1.0 - t) * (1.0 - t) * 1.3
		elif kind == "s":
			ph += 190.0 / RATE
			v = rng.randf_range(-1.0, 1.0) * (1.0 - t) * (1.0 - t) * 0.7 + sin(ph * TAU) * 0.3 * pow(1.0 - t, 3.0)
		else:
			var w := rng.randf_range(-1.0, 1.0)
			v = (w - prev) * 0.35 * (1.0 - t)
			prev = w
		var j := start + i
		if j >= n:
			if not loop:
				break
			j %= n
		buf[j] += v * amp
