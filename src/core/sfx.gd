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
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(sound: String, pitch: float = 1.0) -> void:
	if not _streams.has(sound):
		return
	var p := _players[_next]
	_next = (_next + 1) % VOICES
	p.stream = _streams[sound]
	p.pitch_scale = pitch
	p.play()


func _tone(f0: float, f1: float, duration: float, volume: float, square: bool) -> AudioStreamWAV:
	var n := int(duration * RATE)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		phase += lerpf(f0, f1, t) / RATE
		var s := sin(phase * TAU)
		if square:
			s = (0.6 if s > 0.0 else -0.6) + s * 0.4
		var env := minf(1.0, float(i) / (0.004 * RATE)) * (1.0 - t) * (1.0 - t)
		data.encode_s16(i * 2, int(clampf(s * env * volume, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav
