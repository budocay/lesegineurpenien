extends OmniLight3D
## Fait vaciller une lumière (lanterne, bougie, feu).

var amount: float = 0.1
var speed: float = 6.0

var _base := 1.0
var _phase := 0.0


func _ready() -> void:
	_base = light_energy
	_phase = randf() * 100.0


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0 * speed + _phase
	light_energy = _base * (1.0 + amount * (sin(t) * 0.5 + sin(t * 2.3 + 1.7) * 0.3 + sin(t * 5.1) * 0.2))
