extends Node2D
## Une partie : grille de chats à fusionner, mur à défendre, 10 vagues de zombies.

const COLS_X := [272.0, 411.0]
const ROWS_Y := [301.0, 416.0, 531.0, 646.0, 760.0]
const TRASH := 8
const CELL := 112.0
const FOOT := 48.0
const WAVES := 10
const WALL_MAX := 1000.0
const GAUGE := Rect2(667, 262, 28, 414)
const ENEMY_Y := Vector2(320, 860)
const SPAWN_X := 2260.0

## Renforts : clé, icône, prix de base, recharge (s)
const ADDONS := [
	{"id": "spikes", "icon": "AddonIcon8", "name": "Pièges", "cost": 25, "cd": 12.0},
	{"id": "tnt", "icon": "AddonIcon6", "name": "TNT", "cost": 40, "cd": 15.0},
	{"id": "boxing", "icon": "AddonIcon7", "name": "Boxeur", "cost": 55, "cd": 20.0},
	{"id": "guardian", "icon": "AddonIcon5", "name": "Gardien", "cost": 70, "cd": 25.0},
]

var main: Node
var level := 1

var coins := 0
var wall_hp := WALL_MAX
var wave := 0
var purchases := 0
var repairs := 0
var best_cat := 1
var grid: Array = []
var enemies: Array = []
var allies: Array = []
var over := false

var _to_spawn: Array = []
var _spawn_t := 0.0
var _between_t := 2.0
var _spikes_t := 0.0
var _wall_sfx_t := 0.0
var _cooldowns := {}

var _drag: Cat
var _drag_offset := Vector2.ZERO

var world: Node2D
var fx: Node2D
var marks: Node2D
var spikes_node: Node2D
var hud: Control
var _coin_label: Label
var _wave_label: Label
var _buy_btn: TextureButton
var _buy_label: Label
var _repair_btn: TextureButton
var _repair_label: Label
var _gauge_fill: ColorRect
var _addon_btns := {}
var _banner: Label
var _speed_btn: TextureButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	var bg := Sprite2D.new()
	bg.texture = A.tex("area%d" % ((level - 1) % 5 + 1))
	bg.centered = false
	add_child(bg)

	var gauge_bg := ColorRect.new()
	gauge_bg.color = Color(0.12, 0.15, 0.16)
	gauge_bg.position = GAUGE.position
	gauge_bg.size = GAUGE.size
	add_child(gauge_bg)
	_gauge_fill = ColorRect.new()
	_gauge_fill.color = Color(0.55, 0.92, 0.2)
	add_child(_gauge_fill)

	marks = Node2D.new()
	marks.draw.connect(_draw_marks)
	add_child(marks)
	spikes_node = Node2D.new()
	spikes_node.modulate.a = 0
	add_child(spikes_node)
	for i in 12:
		var s := Sprite2D.new()
		s.texture = A.tex("AddonIcon8")
		s.scale = Vector2(0.62, 0.62)
		s.position = Vector2(800 + (i % 2) * 85 + (i / 2 % 2) * 40, 330 + (i / 2) * 100)
		spikes_node.add_child(s)

	world = Node2D.new()
	world.y_sort_enabled = true
	add_child(world)
	fx = Node2D.new()
	add_child(fx)

	grid.resize(10)
	coins = int(round(30 * _lvl_mult()))
	_build_hud()
	var start_lvl := 1 + (level - 1) / 3
	_place_new_cat(start_lvl, 0)
	_place_new_cat(start_lvl, 1)
	_refresh_hud()


func _exit_tree() -> void:
	Engine.time_scale = 1.0


# --- Économie -------------------------------------------------------------

func _lvl_mult() -> float:
	return pow(1.1, level - 1)


func _enemy_base() -> float:
	return 22.0 * _lvl_mult() * pow(1.24, maxi(wave, 1) - 1)


func buy_level() -> int:
	return maxi(1, best_cat - 4)


func buy_cost() -> int:
	return int(round(8 * _lvl_mult() * pow(1.085, purchases) * pow(1.6, buy_level() - 1)))


func repair_cost() -> int:
	return int(round(30 * _lvl_mult() * pow(1.5, repairs)))


func addon_cost(a: Dictionary) -> int:
	return int(round(a.cost * _lvl_mult()))


func sell_value(lvl: int) -> int:
	return int(round(4 * _lvl_mult() * pow(1.8, lvl - 1)))


func add_coins(n: int) -> void:
	coins += n
	_refresh_hud()


# --- Grille ---------------------------------------------------------------

func slot_center(i: int) -> Vector2:
	return Vector2(COLS_X[i % 2], ROWS_Y[i / 2])


func slot_at(p: Vector2) -> int:
	for i in 10:
		var c := slot_center(i)
		if absf(p.x - c.x) < CELL * 0.62 and absf(p.y - c.y) < CELL * 0.55:
			return i
	return -1


func free_slot() -> int:
	for i in 10:
		if i != TRASH and grid[i] == null:
			return i
	return -1


func _place_new_cat(lvl: int, i: int) -> Cat:
	var c := Cat.new()
	c.game = self
	c.level = lvl
	c.slot = i
	c.position = slot_center(i) + Vector2(0, FOOT)
	grid[i] = c
	world.add_child(c)
	c.pop()
	best_cat = maxi(best_cat, lvl)
	return c


func _on_buy() -> void:
	var i := free_slot()
	var cost := buy_cost()
	if i < 0:
		_flash_text(_buy_btn.position + Vector2(170, -30), "Grille pleine !", Color(1, 0.6, 0.5))
		return
	if coins < cost:
		_flash_text(_buy_btn.position + Vector2(170, -30), "Pas assez de pièces", Color(1, 0.6, 0.5))
		return
	coins -= cost
	purchases += 1
	_place_new_cat(buy_level(), i)
	Sfx.play("buy")
	_refresh_hud()


func _unhandled_input(event: InputEvent) -> void:
	if over:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var p := get_global_mouse_position()
		if event.pressed:
			var i := slot_at(p)
			if i >= 0 and grid[i] != null:
				_drag = grid[i]
				_drag.dragging = true
				_drag.z_index = 20
				_drag_offset = _drag.position - p
				_drag.create_tween().tween_property(_drag, "scale", Vector2(1.15, 1.15), 0.1)
				marks.queue_redraw()
		elif _drag:
			_drop(slot_at(p))
	elif event is InputEventMouseMotion and _drag:
		_drag.position = get_global_mouse_position() + _drag_offset
		marks.queue_redraw()


func _drop(target: int) -> void:
	var c := _drag
	_drag = null
	c.dragging = false
	c.z_index = 0
	c.create_tween().tween_property(c, "scale", Vector2.ONE, 0.1)
	var src := c.slot
	if target == TRASH:
		var v := sell_value(c.level)
		grid[src] = null
		add_coins(v)
		_flash_text(slot_center(TRASH) + Vector2(0, -60), "+%d" % v, Color(1, 0.9, 0.3))
		Sfx.play("coin")
		c.queue_free()
	elif target < 0 or target == src:
		_snap(c, src)
	elif grid[target] == null:
		grid[src] = null
		grid[target] = c
		c.slot = target
		_snap(c, target)
	else:
		var other: Cat = grid[target]
		if other.level == c.level and c.level < Cat.MAX_LEVEL:
			grid[src] = null
			c.queue_free()
			other.level += 1
			best_cat = maxi(best_cat, other.level)
			other.refresh()
			other.pop()
			_spawn_fx("shootfx", other.position + Vector2(0, -60), 2.6)
			_flash_text(other.position + Vector2(0, -150), "Niveau %d !" % other.level, Color(1, 0.85, 0.2))
			Sfx.play("merge")
			_refresh_hud()
		else:
			grid[src] = other
			grid[target] = c
			other.slot = src
			c.slot = target
			_snap(other, src)
			_snap(c, target)
	marks.queue_redraw()


func _snap(c: Cat, i: int) -> void:
	c.create_tween().tween_property(c, "position", slot_center(i) + Vector2(0, FOOT), 0.12)


func _draw_marks() -> void:
	if _drag == null:
		return
	for i in 10:
		var c: Cat = grid[i]
		if c and c != _drag and c.level == _drag.level and c.level < Cat.MAX_LEVEL:
			marks.draw_circle(slot_center(i) + Vector2(0, 20), 62, Color(1, 0.85, 0.15, 0.45))
	var t := slot_at(_drag.position - Vector2(0, FOOT))
	if t >= 0:
		marks.draw_rect(Rect2(slot_center(t) - Vector2(52, 52), Vector2(104, 104)), Color(1, 1, 1, 0.8), false, 6)
	if t == TRASH:
		marks.draw_string(ThemeDB.fallback_font, slot_center(TRASH) + Vector2(-60, -70), "Vendre +%d" % sell_value(_drag.level), HORIZONTAL_ALIGNMENT_CENTER, 120, 30, Color(1, 0.9, 0.3))


# --- Combat ---------------------------------------------------------------

func pick_target():
	var best = null
	for e in enemies:
		if e.alive() and e.position.x < 2120 and (best == null or e.position.x < best.position.x):
			best = e
	return best


func nearest_enemy(p: Vector2):
	var best = null
	var bd := INF
	for e in enemies:
		if e.alive() and e.position.x < 2100:
			var d := p.distance_squared_to(e.position)
			if d < bd:
				bd = d
				best = e
	return best


func blocking_ally(e: Node2D):
	for a in allies:
		if is_instance_valid(a) and a.blocks(e):
			return a
	return null


func spawn_bullet(from: Vector2, target: Node2D, dmg: float, lvl: int) -> void:
	var b := Bullet.new()
	b.game = self
	b.target = target
	b.damage = dmg
	b.texture = A.tex("bullet%d" % (1 + mini(2, (lvl - 1) / 5)))
	b.scale = Vector2(0.6, 0.6) * (1.0 + lvl * 0.03)
	b.position = from
	fx.add_child(b)
	_spawn_fx("shootfx", from + Vector2(8, 0), 1.0)
	Sfx.play("shoot", -10)


func hit_fx(p: Vector2) -> void:
	Sfx.play("hit", -8)
	var s := Sprite2D.new()
	s.texture = A.tex("bullet1")
	s.position = p
	s.modulate = Color(1, 1, 0.6, 0.9)
	s.scale = Vector2(0.3, 0.3)
	fx.add_child(s)
	var tw := s.create_tween().set_parallel()
	tw.tween_property(s, "scale", Vector2(0.7, 0.7), 0.12)
	tw.tween_property(s, "modulate:a", 0.0, 0.12)
	tw.chain().tween_callback(s.queue_free)


func _spawn_fx(key: String, p: Vector2, sc: float) -> void:
	var s := AnimSprite.new()
	s.play(key, false, 30)
	s.center_anchor()
	s.position = p
	s.scale = Vector2(sc, sc)
	s.finished.connect(s.queue_free)
	fx.add_child(s)


func damage_wall(amount: float) -> void:
	if over:
		return
	wall_hp -= amount
	_wall_sfx_t -= get_process_delta_time()
	if _wall_sfx_t <= 0:
		_wall_sfx_t = 0.5
		Sfx.play("wall", -6)
	_update_gauge()
	if wall_hp <= 0:
		_end(false)


func on_enemy_killed(e) -> void:
	add_coins(e.reward)
	_flash_text(e.position + Vector2(0, -170), "+%d" % e.reward, Color(1, 0.9, 0.3))
	Sfx.play("die", -4)


func _process(delta: float) -> void:
	if over:
		return
	enemies = enemies.filter(func(e): return is_instance_valid(e))
	allies = allies.filter(func(a): return is_instance_valid(a))
	_run_waves(delta)
	_run_spikes(delta)
	for k in _cooldowns.keys():
		_cooldowns[k] = maxf(0.0, _cooldowns[k] - delta)
	_refresh_addons()


func _run_waves(delta: float) -> void:
	if _to_spawn.is_empty():
		var alive := enemies.any(func(e): return e.alive())
		if alive:
			return
		if wave >= WAVES:
			_end(true)
			return
		_between_t -= delta
		if _between_t <= 0:
			_start_wave()
		return
	_spawn_t -= delta
	if _spawn_t <= 0:
		_spawn_t = maxf(0.5, 1.7 - wave * 0.08 - level * 0.025) * randf_range(0.7, 1.3)
		_spawn_enemy(_to_spawn.pop_front())


func _start_wave() -> void:
	wave += 1
	_between_t = 3.0
	var n := 5 + wave + level / 2
	var top := mini(8, 1 + (level - 1) / 2 + wave / 4)
	for i in n:
		_to_spawn.append("reg%d" % randi_range(maxi(1, top - 3), top))
	if wave == WAVES or (level >= 6 and wave == 5):
		_to_spawn.append("boss%d" % ((level - 1) % 7 + 1))
	_spawn_t = 0.5
	_show_banner("Vague %d / %d" % [wave, WAVES] if wave < WAVES else "Vague finale !")
	_refresh_hud()


func _spawn_enemy(kind: String) -> void:
	var e := Enemy.new()
	e.game = self
	e.kind = kind
	e.boss = kind.begins_with("boss")
	var base := _enemy_base()
	var idx := int(kind.substr(4 if e.boss else 3))
	e.max_hp = base * randf_range(0.9, 1.1) * (1.0 + (idx - 1) * 0.06)
	e.speed = randf_range(70, 105)
	e.dps = 12.0 * pow(1.07, level - 1) * (1.0 + wave * 0.05)
	e.reward = int(ceil(base * 0.2))
	if e.boss:
		e.max_hp *= 12.0 if wave == WAVES else 6.0
		e.speed = 48
		e.dps *= 5
		e.reward *= 12
		Sfx.play("boom", -4, 0.6)
	e.stop_x = randf_range(770, 810)
	e.position = Vector2(SPAWN_X, randf_range(ENEMY_Y.x, ENEMY_Y.y))
	world.add_child(e)
	enemies.append(e)


func _run_spikes(delta: float) -> void:
	if _spikes_t <= 0:
		return
	_spikes_t -= delta
	var dps := _enemy_base() * 0.8
	for e in enemies:
		if e.alive() and e.position.x < 980:
			e.slow_t = 0.3
			e.hurt(dps * delta)
	if _spikes_t <= 0:
		spikes_node.create_tween().tween_property(spikes_node, "modulate:a", 0.0, 0.3)


# --- Renforts -------------------------------------------------------------

func _use_addon(a: Dictionary) -> void:
	var cost := addon_cost(a)
	if _cooldowns.get(a.id, 0.0) > 0 or coins < cost:
		return
	match a.id:
		"spikes":
			_spikes_t = 6.0
			spikes_node.create_tween().tween_property(spikes_node, "modulate:a", 1.0, 0.2)
			Sfx.play("punch")
		"tnt":
			var c = _densest_point()
			if c == null:
				return
			_explode(c)
		"boxing", "guardian":
			var al := Ally.new()
			al.game = self
			al.kind = a.id
			if a.id == "boxing":
				al.dps = _enemy_base() * 1.6
				al.life = 12.0
				al.reach = 120.0
				al.position = Vector2(840, 590)
			else:
				al.dps = _enemy_base() * 0.9
				al.hp = WALL_MAX * 0.5
				al.life = 20.0
				al.reach = 170.0
				al.position = Vector2(880, 600)
			world.add_child(al)
			allies.append(al)
			Sfx.play("buy")
	coins -= cost
	_cooldowns[a.id] = a.cd
	_refresh_hud()


func _densest_point():
	var best = null
	var best_n := 0
	for e in enemies:
		if not e.alive() or e.position.x > 2080:
			continue
		var n := 0
		for o in enemies:
			if o.alive() and o.position.distance_to(e.position) < 230:
				n += 1
		if n > best_n:
			best_n = n
			best = e.position
	return best


func _explode(p: Vector2) -> void:
	_spawn_fx("explosion", p + Vector2(0, -80), 1.5)
	Sfx.play("boom")
	var dmg := _enemy_base() * 4.5
	for e in enemies:
		if e.alive() and e.position.distance_to(p) < 250:
			e.hurt(dmg)
	var tw := create_tween()
	for i in 6:
		tw.tween_property(self, "position", Vector2(randf_range(-12, 12), randf_range(-10, 10)), 0.04)
	tw.tween_property(self, "position", Vector2.ZERO, 0.04)


func _on_repair() -> void:
	var cost := repair_cost()
	if coins < cost or wall_hp >= WALL_MAX:
		return
	coins -= cost
	repairs += 1
	wall_hp = minf(WALL_MAX, wall_hp + WALL_MAX * 0.35)
	Sfx.play("buy")
	_update_gauge()
	_refresh_hud()


# --- Interface ------------------------------------------------------------

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = Control.new()
	hud.size = Vector2(2143, 1062)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud)

	hud.add_child(UI.image("CoinBar", Vector2(80, 40), Vector2(338, 112)))
	hud.add_child(UI.image("CoinIcon", Vector2(40, 36), Vector2(124, 118)))
	_coin_label = UI.label("0", 50)
	_coin_label.position = Vector2(170, 52)
	_coin_label.size = Vector2(230, 86)
	hud.add_child(_coin_label)

	hud.add_child(UI.image("WaveBar", Vector2(1590, 40), Vector2(304, 110)))
	_wave_label = UI.label("", 44)
	_wave_label.position = Vector2(1680, 50)
	_wave_label.size = Vector2(205, 88)
	hud.add_child(_wave_label)

	var pause_btn := UI.button("SettingBtn", Vector2(1925, 40), Vector2(114, 110))
	pause_btn.pressed.connect(_show_pause)
	hud.add_child(pause_btn)
	_speed_btn = UI.button("BtnShopDisable", Vector2(1400, 52), Vector2(160, 92), "x1", 50)
	_speed_btn.pressed.connect(func():
		Engine.time_scale = 2.0 if Engine.time_scale < 1.5 else 1.0
		_speed_btn.get_node("Text").text = "x%d" % int(Engine.time_scale))
	hud.add_child(_speed_btn)

	_buy_btn = UI.button("BtnGreen", Vector2(80, 900), Vector2(340, 122), "", 40, "BtnGreenPressed")
	_buy_btn.pressed.connect(_on_buy)
	_buy_btn.add_child(UI.image("Icon_Cat", Vector2(14, 10), Vector2(100, 100)))
	_buy_label = UI.label("", 38)
	_buy_label.position = Vector2(110, 6)
	_buy_label.size = Vector2(220, 106)
	_buy_btn.add_child(_buy_label)
	hud.add_child(_buy_btn)

	_repair_btn = UI.button("BtnOrange", Vector2(450, 900), Vector2(337, 126), "", 40, "BtnOrangePressed")
	_repair_btn.pressed.connect(_on_repair)
	_repair_btn.add_child(UI.image("WallIcon", Vector2(16, 14), Vector2(96, 96)))
	_repair_label = UI.label("", 38)
	_repair_label.position = Vector2(110, 8)
	_repair_label.size = Vector2(215, 106)
	_repair_btn.add_child(_repair_label)
	hud.add_child(_repair_btn)

	for i in ADDONS.size():
		var a: Dictionary = ADDONS[i]
		var b := UI.button("YellowBox", Vector2(1380 + i * 182, 880), Vector2(158, 158))
		b.add_child(UI.image(a.icon, Vector2(22, 12), Vector2(114, 108)))
		var l := UI.label("%d" % addon_cost(a), 34)
		l.name = "Cost"
		l.position = Vector2(0, 108)
		l.size = Vector2(158, 46)
		b.add_child(l)
		var cd := ColorRect.new()
		cd.name = "Cd"
		cd.color = Color(0, 0, 0, 0.55)
		cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cd.position = Vector2(10, 10)
		cd.size = Vector2(138, 0)
		b.add_child(cd)
		b.pressed.connect(_use_addon.bind(a))
		hud.add_child(b)
		_addon_btns[a.id] = b

	_banner = UI.label("", 110)
	_banner.position = Vector2(0, 380)
	_banner.size = Vector2(2143, 200)
	_banner.modulate.a = 0
	hud.add_child(_banner)
	_update_gauge()


func _refresh_hud() -> void:
	if not _coin_label:
		return
	_coin_label.text = str(coins)
	_wave_label.text = "Vague %d/%d" % [maxi(wave, 1), WAVES]
	_buy_label.text = "Chat niv.%d\n%d" % [buy_level(), buy_cost()]
	_buy_btn.modulate = Color.WHITE if coins >= buy_cost() and free_slot() >= 0 else Color(0.6, 0.6, 0.6)
	_repair_label.text = "Réparer\n%d" % repair_cost()
	_repair_btn.modulate = Color.WHITE if coins >= repair_cost() and wall_hp < WALL_MAX else Color(0.6, 0.6, 0.6)
	_refresh_addons()


func _refresh_addons() -> void:
	for a in ADDONS:
		var b: TextureButton = _addon_btns[a.id]
		var left: float = _cooldowns.get(a.id, 0.0)
		var cd: ColorRect = b.get_node("Cd")
		cd.size.y = 138 * left / a.cd
		cd.position.y = 10 + 138 - cd.size.y
		b.modulate = Color.WHITE if coins >= addon_cost(a) and left <= 0 else Color(0.65, 0.65, 0.65)


func _update_gauge() -> void:
	if not _gauge_fill:
		return
	var f := clampf(wall_hp / WALL_MAX, 0, 1)
	_gauge_fill.size = Vector2(GAUGE.size.x, GAUGE.size.y * f)
	_gauge_fill.position = GAUGE.position + Vector2(0, GAUGE.size.y * (1 - f))
	_gauge_fill.color = Color(0.55, 0.92, 0.2).lerp(Color(0.95, 0.25, 0.15), 1 - f)


func _show_banner(text: String) -> void:
	_banner.text = text
	_banner.scale = Vector2(0.6, 0.6)
	_banner.pivot_offset = _banner.size / 2
	var tw := _banner.create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.2)
	tw.parallel().tween_property(_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.1)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.3)


func _flash_text(p: Vector2, text: String, color: Color) -> void:
	var l := UI.label(text, 40, color, 10)
	l.size = Vector2(300, 60)
	l.position = p - Vector2(150, 30)
	fx.add_child(l)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y - 70, 0.8)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.tween_callback(l.queue_free)


func _show_pause() -> void:
	if over:
		return
	get_tree().paused = true
	var layer := CanvasLayer.new()
	layer.layer = 20
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)
	UI.dim(layer)
	layer.add_child(UI.panel(Rect2(721, 230, 700, 600)))
	var t := UI.label("Pause", 90)
	t.position = Vector2(721, 260)
	t.size = Vector2(700, 120)
	layer.add_child(t)
	var resume := UI.button("BtnGreen", Vector2(901, 410), Vector2(340, 122), "Reprendre", 48)
	resume.pressed.connect(func():
		get_tree().paused = false
		layer.queue_free())
	layer.add_child(resume)
	var quit := UI.button("BtnOrange", Vector2(901, 560), Vector2(340, 126), "Menu", 48)
	quit.pressed.connect(func():
		get_tree().paused = false
		main.show_levels())
	layer.add_child(quit)
	var snd := UI.button("BtnSound" if G.sound else "BtnSoundOff", Vector2(1300, 250), Vector2(100, 100))
	snd.pressed.connect(func():
		G.sound = not G.sound
		G.save()
		snd.texture_normal = A.tex("BtnSound" if G.sound else "BtnSoundOff"))
	layer.add_child(snd)


func _end(won: bool) -> void:
	if over:
		return
	over = true
	Engine.time_scale = 1.0
	if _drag:
		_drop(_drag.slot)
	if won:
		G.level_won(level)
	Sfx.play("win" if won else "lose")
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	UI.dim(layer, 0.55)
	layer.add_child(UI.panel(Rect2(571, 300, 1000, 560)))
	var art := UI.image("WinPopUp" if won else "LosePopUp", Vector2(521, 120), Vector2(1100, 482 * 1100 / (1100.0 if won else 1073.0)))
	art.size.y = 300
	layer.add_child(art)
	var msg := "Niveau %d réussi !" % level if won else "Le mur est tombé…"
	var l := UI.label(msg, 72)
	l.position = Vector2(571, 450)
	l.size = Vector2(1000, 120)
	layer.add_child(l)
	if won and level < G.LEVELS:
		var nxt := UI.button("BtnGreen", Vector2(1121, 640), Vector2(340, 122), "Suivant", 50)
		nxt.pressed.connect(main.start_level.bind(level + 1))
		layer.add_child(nxt)
	else:
		var again := UI.button("BtnGreen", Vector2(1121, 640), Vector2(340, 122), "Rejouer", 50)
		again.pressed.connect(main.start_level.bind(level))
		layer.add_child(again)
	var menu := UI.button("BtnOrange", Vector2(681, 640), Vector2(340, 126), "Menu", 50)
	menu.pressed.connect(main.show_levels)
	layer.add_child(menu)
