extends Control
## Écran d'accueil : illustration du kit, logo, « Touche pour jouer ».

var main: Node


func _ready() -> void:
	size = Vector2(2143, 1062)
	add_child(UI.image("landing", Vector2.ZERO, size))
	var logo := UI.image("Logo", Vector2(1071 - 430, 180), Vector2(860, 517))
	logo.pivot_offset = logo.size / 2
	add_child(logo)
	logo.scale = Vector2(0.3, 0.3)
	create_tween().tween_property(logo, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	var tap := UI.label("Touche pour jouer", 64)
	tap.position = Vector2(0, 790)
	tap.size = Vector2(2143, 120)
	add_child(tap)
	var tw := create_tween().set_loops()
	tw.tween_property(tap, "modulate:a", 0.25, 0.7)
	tw.tween_property(tap, "modulate:a", 1.0, 0.7)

	var credit := UI.label("Graphismes : CraftPix.net", 26, Color(1, 1, 1, 0.7), 6)
	credit.position = Vector2(1700, 1005)
	credit.size = Vector2(420, 50)
	add_child(credit)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		Sfx.play("click")
		main.show_levels()
