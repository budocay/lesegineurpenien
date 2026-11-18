extends Node3D
## Le personnage dirigé par le joueur : déplacement libre, collisions gérées par le monde.

const CharacterSprite = preload("res://src/world/character_sprite.gd")

const SPEED := 4.0
const RADIUS := 0.28

var world: Node3D
var sprite: Node3D
var facing: String = "down"
var control: bool = false


func setup(p_world: Node3D, character_id: String) -> void:
	world = p_world
	sprite = CharacterSprite.new()
	add_child(sprite)
	sprite.setup(Sprites.character(character_id))


func set_facing(dir: String) -> void:
	if dir in ["down", "left", "right", "up"]:
		facing = dir
	sprite.facing = facing


func facing_vector() -> Vector2:
	match facing:
		"left": return Vector2.LEFT
		"right": return Vector2.RIGHT
		"up": return Vector2.UP
	return Vector2.DOWN


func _process(delta: float) -> void:
	var v := Vector2.ZERO
	if control:
		v = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var moved := false
	if v.length_squared() > 0.02:
		if v.length() > 1.0:
			v = v.normalized()
		var want_h := "left" if v.x < 0.0 else "right"
		var want_v := "up" if v.y < 0.0 else "down"
		if absf(v.x) < 0.2:
			facing = want_v
		elif absf(v.y) < 0.2:
			facing = want_h
		elif facing != want_h and facing != want_v:
			facing = want_h
		var p := Vector2(position.x, position.z)
		var step := v * SPEED * delta
		if world.is_free(p + step, RADIUS, self):
			p += step
			moved = true
		elif absf(step.x) > 0.0001 and world.is_free(p + Vector2(step.x, 0.0), RADIUS, self):
			p.x += step.x
			moved = true
		elif absf(step.y) > 0.0001 and world.is_free(p + Vector2(0.0, step.y), RADIUS, self):
			p.y += step.y
			moved = true
		position = Vector3(p.x, 0.0, p.y)
	sprite.facing = facing
	sprite.moving = moved
