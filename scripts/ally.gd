class_name Ally
extends Node2D
## Renfort temporaire devant le mur : le boxeur fonce sur les zombies, le gardien tient la ligne.

var game
var kind := "boxing"
var dps := 10.0
var hp := 0.0
var life := 12.0
var reach := 120.0
var spr: AnimSprite
var _leaving := false
var _punch_t := 0.0


func _ready() -> void:
	spr = AnimSprite.new()
	add_child(spr)
	spr.play(kind + "_idle", true, 15)
	scale = Vector2(0.2, 0.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func take_damage(amount: float) -> void:
	if kind == "guardian":
		hp -= amount
		if hp <= 0:
			leave()


func blocks(e: Node2D) -> bool:
	if _leaving:
		return false
	var dx := e.position.x - position.x
	return dx > 0 and dx < 95 and absf(e.position.y - position.y) < 110


func _process(delta: float) -> void:
	if _leaving:
		return
	life -= delta
	if life <= 0:
		leave()
		return
	var t = game.nearest_enemy(position)
	if kind == "boxing" and t:
		var goal: Vector2 = t.position + Vector2(-80, 0)
		goal.x = maxf(goal.x, 760)
		position = position.move_toward(goal, 420 * delta)
	var hitting := t != null and position.distance_to(t.position) < reach
	spr.play(kind + ("_attack" if hitting else "_idle"), true, 20 if hitting else 15)
	if hitting:
		t.hurt(dps * delta)
		_punch_t -= delta
		if _punch_t <= 0:
			_punch_t = 0.35
			Sfx.play("punch", -4)


func leave() -> void:
	if _leaving:
		return
	_leaving = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.4)
	tw.tween_callback(queue_free)
