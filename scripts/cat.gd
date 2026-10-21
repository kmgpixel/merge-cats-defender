class_name Cat
extends Node2D
## Chat tireur posé sur une case de la grille. Deux chats de même niveau fusionnent.

const MAX_LEVEL := 15
const SPRITE_SCALE := 1.25

var game
var level := 1
var slot := -1
var dragging := false
var spr: AnimSprite
var _cooldown := 0.0
var _badge: Sprite2D
var _badge_label: Label


func _ready() -> void:
	spr = AnimSprite.new()
	spr.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	add_child(spr)
	spr.finished.connect(_on_anim_done)
	_badge = Sprite2D.new()
	_badge.scale = Vector2(1.5, 1.5)
	add_child(_badge)
	_badge_label = UI.label("", 30, Color.WHITE, 8)
	_badge_label.size = Vector2(60, 50)
	_badge_label.position = Vector2(-30, -27)
	_badge.add_child(_badge_label)
	refresh()
	_cooldown = randf() * interval()


func refresh() -> void:
	spr.play("cat%d_idle" % level, true, 15, true)
	_badge.texture = A.tex("uplogo%d" % level)
	_badge.position = Vector2(-52, -18)
	_badge_label.text = str(level)


static func damage_for(lvl: int) -> float:
	return 8.0 * pow(1.75, lvl - 1)


func interval() -> float:
	return 0.9


func muzzle() -> Vector2:
	var d: Dictionary = A.data["cat%d_shoot" % level]
	return global_position + Vector2(d.ox + d.fw - 10, -d.fh * 0.47) * SPRITE_SCALE


func _process(delta: float) -> void:
	if dragging:
		return
	_cooldown -= delta
	if _cooldown > 0:
		return
	var t: Node2D = game.pick_target()
	if t == null:
		_cooldown = 0.15
		return
	_cooldown = interval()
	spr.play("cat%d_shoot" % level, false, 30, true)
	game.spawn_bullet(muzzle(), t, damage_for(level), level)


func _on_anim_done() -> void:
	if spr.anim.ends_with("_shoot"):
		spr.play("cat%d_idle" % level, true, 15)


func pop() -> void:
	scale = Vector2(0.4, 0.4)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
