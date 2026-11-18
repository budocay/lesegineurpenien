extends Node
## Petits sons d'interface synthétisés par code (aucun fichier audio requis).

const RATE := 22050
const VOICES := 6

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	_streams["blip"] = _tone(520.0, 480.0, 0.035, 0.10, false)
	_streams["move"] = _tone(660.0, 660.0, 0.04, 0.12, true)
	_streams["confirm"] = _tone(520.0, 880.0, 0.11, 0.16, true)
	_streams["cancel"] = _tone(440.0, 280.0, 0.10, 0.14, true)
	_streams["door"] = _tone(180.0, 90.0, 0.22, 0.22, false)
	_streams["save"] = _tone(660.0, 1320.0, 0.28, 0.14, false)
	_streams["encounter"] = _tone(220.0, 990.0, 0.42, 0.16, true)
	_streams["hit"] = _tone(240.0, 70.0, 0.12, 0.24, true)
	_streams["weak"] = _tone(520.0, 130.0, 0.18, 0.24, true)
	_streams["magic"] = _tone(380.0, 1180.0, 0.3, 0.14, false)
	_streams["heal"] = _tone(520.0, 1040.0, 0.36, 0.12, false)
	_streams["status"] = _tone(330.0, 250.0, 0.26, 0.12, false)
	_streams["break"] = _tone(900.0, 110.0, 0.34, 0.22, true)
	_streams["ko"] = _tone(300.0, 50.0, 0.45, 0.2, false)
	_streams["victory"] = _tone(523.0, 1568.0, 0.6, 0.14, false)
	_streams["level"] = _tone(784.0, 1568.0, 0.4, 0.13, true)
	# sons de combat (animations) : fréquence de départ, d'arrivée, durée, volume, carré,
	# part de souffle, trémolo (battements par seconde)
	_streams["swoosh"] = _tone(900.0, 300.0, 0.14, 0.2, false, 1.0)
	_streams["clang"] = _tone(1400.0, 1250.0, 0.32, 0.16, true, 0.1, 40.0)
	_streams["slash"] = _tone(4000.0, 1500.0, 0.1, 0.22, false, 1.0)
	_streams["thud"] = _tone(160.0, 50.0, 0.14, 0.3, false, 0.3)
	_streams["boom"] = _tone(120.0, 30.0, 0.5, 0.34, false, 0.6)
	_streams["zap"] = _tone(1800.0, 200.0, 0.22, 0.2, true, 0.3, 60.0)
	_streams["fire"] = _tone(600.0, 1500.0, 0.35, 0.2, false, 1.0)
	_streams["snore"] = _tone(90.0, 60.0, 0.5, 0.22, true, 0.1, 18.0)
	_streams["gulp"] = _tone(300.0, 600.0, 0.12, 0.18, false)
	_streams["splat"] = _tone(500.0, 150.0, 0.16, 0.24, false, 0.7)
	_streams["buzz"] = _tone(220.0, 240.0, 0.3, 0.14, true, 0.0, 70.0)
	_streams["whistle"] = _tone(900.0, 2200.0, 0.4, 0.1, false)
	_streams["twang"] = _tone(600.0, 300.0, 0.2, 0.18, false, 0.0, 30.0)
	_streams["roar"] = _tone(140.0, 70.0, 0.5, 0.24, true, 0.4, 25.0)
	_streams["croak"] = _tone(180.0, 110.0, 0.3, 0.2, true, 0.0, 35.0)
	_streams["chime"] = _tone(1320.0, 1760.0, 0.4, 0.1, false)
	_streams["poof"] = _tone(400.0, 100.0, 0.3, 0.22, false, 1.0)
	_streams["yawn"] = _tone(500.0, 180.0, 0.7, 0.14, false, 0.0, 6.0)
	_streams["coin"] = _tone(1600.0, 2100.0, 0.15, 0.1, true)
	_streams["guard"] = _tone(300.0, 500.0, 0.2, 0.16, true)
	_streams["squeak"] = _tone(900.0, 1500.0, 0.12, 0.12, false)
	_streams["stomp"] = _tone(110.0, 40.0, 0.2, 0.3, false, 0.4)
	_streams["bubble"] = _tone(250.0, 700.0, 0.18, 0.16, false, 0.0, 20.0)
	_streams["pop"] = _tone(1500.0, 300.0, 0.08, 0.24, false, 0.6)
	_streams["fanfare"] = _tone(523.0, 1046.0, 0.45, 0.12, true, 0.0, 8.0)
	_streams["shriek"] = _tone(1500.0, 2600.0, 0.6, 0.12, true, 0.2, 50.0)
	_streams["munch"] = _tone(700.0, 300.0, 0.12, 0.2, false, 0.8, 25.0)
	_streams["burp"] = _tone(160.0, 90.0, 0.3, 0.2, true, 0.1, 30.0)
	_streams["wind"] = _tone(300.0, 700.0, 0.6, 0.16, false, 1.0)
	_streams["rustle"] = _tone(2500.0, 1200.0, 0.2, 0.16, false, 1.0, 30.0)
	_streams["bell"] = _tone(880.0, 870.0, 0.6, 0.1, false)
	_streams["elan"] = _tone(420.0, 760.0, 0.16, 0.13, true, 0.0, 14.0)   # l'élan qui monte : joué plus aigu à chaque point engagé
	_streams["elan_off"] = _tone(640.0, 380.0, 0.08, 0.1, true)
	_streams["shatter"] = _tone(2400.0, 200.0, 0.3, 0.2, false, 1.0, 45.0)   # bouclier en éclats
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		p.bus = Settings.BUS_EFFECTS
		add_child(p)
		_players.append(p)


func has(sound: String) -> bool:
	return _streams.has(sound)


func play(sound: String, pitch: float = 1.0) -> void:
	if not _streams.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[sound]
	p.pitch_scale = pitch
	p.play()


## noise : part de souffle (0 = son pur, 1 = souffle seul, filtré autour de la fréquence) ;
## tremolo : battements par seconde.
func _tone(f0: float, f1: float, duration: float, volume: float, square: bool, noise: float = 0.0, tremolo: float = 0.0) -> AudioStreamWAV:
	var n := int(duration * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = int(f0 * 31.0 + f1 * 7.0 + duration * 1000.0)
	var low := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(f0, f1, t)
		phase += f / RATE
		var s := sin(phase * TAU)
		if square:
			s = (0.6 if s > 0.0 else -0.6) + s * 0.4
		if noise > 0.0:
			low += (rng.randf_range(-1.0, 1.0) - low) * clampf(f * 6.0 / RATE, 0.02, 1.0)
			s = lerpf(s, low * 1.6, noise)
		if tremolo > 0.0:
			s *= 0.6 + 0.4 * sin(float(i) / RATE * tremolo * TAU)
		var env := minf(1.0, float(i) / (0.004 * RATE)) * (1.0 - t) * (1.0 - t)
		data.encode_s16(i * 2, int(clampf(s * env * volume, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav
