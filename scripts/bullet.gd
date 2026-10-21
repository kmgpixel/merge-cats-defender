class_name Bullet
extends Sprite2D
## Projectile tête chercheuse ; continue tout droit si sa cible meurt en route.

const SPEED := 1700.0

var game
var target
var damage := 8.0
var _dir := Vector2.RIGHT


func _process(delta: float) -> void:
	if is_instance_valid(target) and target.alive():
		var to: Vector2 = target.body_center() - global_position
		if to.length() < 40:
			target.hurt(damage)
			game.hit_fx(global_position)
			queue_free()
			return
		_dir = to.normalized()
	rotation = _dir.angle()
	global_position += _dir * SPEED * delta
	if global_position.x > 2300 or global_position.y < -100 or global_position.y > 1200:
		queue_free()
