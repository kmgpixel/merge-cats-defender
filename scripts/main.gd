extends Node
## Aiguillage entre écran titre, carte des niveaux et partie.

const TitleScreen := preload("res://scripts/title_screen.gd")
const LevelSelect := preload("res://scripts/level_select.gd")
const Game := preload("res://scripts/game.gd")

var current: Node
var _rotate_hint: ColorRect


func _ready() -> void:
	_build_rotate_hint()
	get_window().size_changed.connect(_check_orientation)
	_check_orientation()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--bot="):
			_run_bot(int(arg.substr(6)))
			return
	show_title()


func _run_bot(level: int) -> void:
	start_level(level)
	var bot: Node = preload("res://scripts/bot.gd").new()
	bot.game = current
	current.add_child(bot)
	var t0 := Time.get_ticks_msec()
	while not current.over:
		await get_tree().process_frame
	await get_tree().create_timer(2.5).timeout
	print("BOT niveau %d : %s | vague %d | mur %d | meilleur chat %d | %.0f s jeu | %d ms" % [
		level, "GAGNÉ" if current.wall_hp > 0 else "PERDU", current.wave, current.wall_hp,
		current.best_cat, Engine.get_process_frames() / 30.0, Time.get_ticks_msec() - t0])
	get_tree().quit()


func _swap(n: Node) -> void:
	if current:
		current.queue_free()
	current = n
	add_child(n)


func show_title() -> void:
	var s := TitleScreen.new()
	s.main = self
	_swap(s)


func show_levels() -> void:
	var s := LevelSelect.new()
	s.main = self
	_swap(s)


func start_level(level: int) -> void:
	var g := Game.new()
	g.level = level
	g.main = self
	_swap(g)


## Sur téléphone en portrait, le jeu (paysage) serait minuscule : on invite à tourner l'écran.
## (On masque le Control lui-même : un CanvasLayer caché laisse passer le blocage des clics.)
func _build_rotate_hint() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)
	_rotate_hint = UI.dim(layer, 0.92)
	var l := UI.label("Tourne ton téléphone\nen mode paysage ↻", 110)
	l.size = Vector2(2143, 1062)
	_rotate_hint.add_child(l)


func _check_orientation() -> void:
	var s := get_window().size
	_rotate_hint.visible = s.y > s.x * 1.1
