extends Control
## Carte des 15 niveaux (5 décors × 3 tours).

var main: Node


func _ready() -> void:
	size = Vector2(2143, 1062)
	add_child(UI.image("landing", Vector2.ZERO, size))
	UI.dim(self, 0.6).mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ribbon := UI.image("TitleRibbon", Vector2(1071 - 400, 40), Vector2(800, 242))
	add_child(ribbon)
	var title := UI.label("Choisis un niveau", 70)
	title.position = ribbon.position + Vector2(0, 40)
	title.size = Vector2(800, 120)
	add_child(title)

	for i in G.LEVELS:
		var lvl := i + 1
		var key := "LockedLevel"
		if lvl < G.unlocked:
			key = "GreenLevel"
		elif lvl == G.unlocked:
			key = "OrangeLvl"
		var pos := Vector2(440 + (i % 5) * 270, 330 + (i / 5) * 230)
		var b := UI.button(key, pos, Vector2(186, 198), "" if lvl > G.unlocked else str(lvl), 84)
		if b.has_node("Text"):
			b.get_node("Text").position.y = -14
		b.disabled = lvl > G.unlocked
		b.pressed.connect(main.start_level.bind(lvl))
		add_child(b)
		if lvl == G.unlocked:
			var tw := b.create_tween().set_loops()
			tw.tween_property(b, "rotation", 0.06, 0.5).set_trans(Tween.TRANS_SINE)
			tw.tween_property(b, "rotation", -0.06, 0.5).set_trans(Tween.TRANS_SINE)

	var home := UI.button("Icon_home", Vector2(60, 50), Vector2(120, 120))
	home.pressed.connect(main.show_title)
	add_child(home)

	var snd := UI.button("BtnSound" if G.sound else "BtnSoundOff", Vector2(1960, 50), Vector2(120, 120))
	snd.pressed.connect(func():
		G.sound = not G.sound
		G.save()
		snd.texture_normal = A.tex("BtnSound" if G.sound else "BtnSoundOff"))
	add_child(snd)
