class_name Enemy
extends Node2D
## Zombie qui marche vers le mur puis le frappe. Les renforts peuvent le bloquer.

var game
var kind := "reg1"
var boss := false
var max_hp := 20.0
var hp := 20.0
var speed := 80.0
var dps := 10.0
var reward := 5
var stop_x := 780.0
var state := "walk"
var slow_t := 0.0
var spr: AnimSprite
var _bar_bg: ColorRect
var _bar: ColorRect


func _ready() -> void:
	hp = max_hp
	spr = AnimSprite.new()
	add_child(spr)
	spr.play(kind + "_walk", true, 10)
	spr.finished.connect(_on_anim_done)
	var h: float = A.data[kind + "_walk"].fh
	var w := 130.0 if boss else 90.0
	_bar_bg = ColorRect.new()
	_bar_bg.color = Color(0.15, 0.05, 0.05, 0.85)
	_bar_bg.size = Vector2(w, 14)
	_bar_bg.position = Vector2(-w / 2, -h - 8)
	_bar_bg.visible = boss
	add_child(_bar_bg)
	_bar = ColorRect.new()
	_bar.color = Color(1, 0.35, 0.25) if boss else Color(0.55, 0.95, 0.3)
	_bar.size = Vector2(w - 4, 10)
	_bar.position = Vector2(2, 2)
	_bar_bg.add_child(_bar)


func alive() -> bool:
	return state != "dead"


func body_center() -> Vector2:
	return global_position + Vector2(-10, -A.data[kind + "_walk"].fh * 0.5)


func _process(delta: float) -> void:
	if state == "dead":
		return
	slow_t -= delta
	var blocker = game.blocking_ally(self)
	if blocker:
		_attack()
		blocker.take_damage(dps * delta)
	elif position.x > stop_x:
		state = "walk"
		spr.play(kind + "_walk", true, 10)
		position.x -= speed * (0.4 if slow_t > 0 else 1.0) * delta
	else:
		_attack()
		game.damage_wall(dps * delta)


func _attack() -> void:
	state = "attack"
	spr.play(kind + "_attack", true, 15)


func hurt(amount: float) -> void:
	if state == "dead":
		return
	hp -= amount
	_bar_bg.visible = true
	_bar.size.x = (_bar_bg.size.x - 4) * clampf(hp / max_hp, 0, 1)
	spr.modulate = Color(1.8, 1.4, 1.4)
	create_tween().tween_property(spr, "modulate", Color.WHITE, 0.15)
	if hp <= 0:
		state = "dead"
		_bar_bg.visible = false
		spr.play(kind + "_dead", false, 15)
		game.on_enemy_killed(self)


func _on_anim_done() -> void:
	if state == "dead":
		var tw := create_tween()
		tw.tween_interval(0.4)
		tw.tween_property(self, "modulate:a", 0.0, 0.4)
		tw.tween_callback(queue_free)
