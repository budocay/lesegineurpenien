extends Node3D
## Personnage non joueur : immobile ou flânant autour de son point de départ.

const CharacterSprite = preload("res://src/world/character_sprite.gd")

const RADIUS := 0.34
const WALK_SPEED := 1.1

var world: Node3D
var data: Dictionary = {}
var sprite: Node3D
var home := Vector2.ZERO
var wander := 0.0

var _wait := 2.0
var _walk := 0.0
var _dir := Vector2.ZERO


func setup(p_world: Node3D, o: Dictionary, pos: Vector3) -> void:
	world = p_world
	data = o
	position = pos
	home = Vector2(pos.x, pos.z)
	wander = float(o.get("wander", 0.0))
	_wait = randf_range(1.0, 3.5)
	sprite = CharacterSprite.new()
	add_child(sprite)
	sprite.setup(Sprites.character(str(o.get("id", ""))))
	sprite.facing = str(o.get("facing", "down"))
	var sc := float(o.get("scale", 1.0))
	if sc != 1.0:
		sprite.scale = Vector3(sc, sc, sc)   # personnage hors norme (Sauron) : plus haut que ses voisins


func face_towards(target: Vector3) -> void:
	var d := Vector2(target.x - position.x, target.z - position.z)
	if absf(d.x) > absf(d.y):
		sprite.facing = "left" if d.x < 0.0 else "right"
	else:
		sprite.facing = "up" if d.y < 0.0 else "down"


func _process(delta: float) -> void:
	var frozen: bool = not world.input_enabled and not world.attract
	if wander <= 0.0 or frozen:
		sprite.moving = false
		return
	if _walk > 0.0:
		_walk -= delta
		var p := Vector2(position.x, position.z) + _dir * WALK_SPEED * delta
		if p.distance_to(home) <= wander and world.is_free(p, RADIUS, self):
			position = Vector3(p.x, world.ground_y(p.x, p.y), p.y)
			sprite.moving = true
		else:
			_walk = 0.0
		if _walk <= 0.0:
			sprite.moving = false
			_wait = randf_range(1.5, 4.5)
	else:
		_wait -= delta
		if _wait <= 0.0:
			var dirs := [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
			var names := ["left", "right", "up", "down"]
			var i := randi() % 4
			_dir = dirs[i]
			sprite.facing = names[i]
			_walk = randf_range(0.5, 1.4)
