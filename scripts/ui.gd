class_name UI
## Fabriques d'éléments d'interface à partir des textures du kit.

const DARK := Color(0.2, 0.1, 0.05)


static func label(text: String, font_size := 40, color := Color.WHITE, outline := 12) -> Label:
	var l := Label.new()
	l.text = text
	var s := LabelSettings.new()
	s.font_size = font_size
	s.font_color = color
	s.outline_size = outline
	s.outline_color = DARK
	s.shadow_size = 0
	s.shadow_color = Color(0, 0, 0, 0.35)
	s.shadow_offset = Vector2(0, 4)
	l.label_settings = s
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func image(key: String, pos: Vector2, size := Vector2.ZERO) -> TextureRect:
	var t := TextureRect.new()
	t.texture = A.tex(key)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.position = pos
	t.size = size if size != Vector2.ZERO else A.size_of(key)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Bouton texturé avec un texte centré et un petit rebond au clic.
static func button(key: String, pos: Vector2, size: Vector2, text := "", font_size := 44, pressed_key := "") -> TextureButton:
	var b := TextureButton.new()
	b.texture_normal = A.tex(key)
	if pressed_key != "":
		b.texture_pressed = A.tex(pressed_key)
	b.ignore_texture_size = true
	b.stretch_mode = TextureButton.STRETCH_SCALE
	b.position = pos
	b.size = size
	b.pivot_offset = size / 2
	if text != "":
		var l := label(text, font_size)
		l.set_anchors_preset(Control.PRESET_FULL_RECT)
		l.name = "Text"
		b.add_child(l)
	b.button_down.connect(func():
		Sfx.play("click", -6)
		b.create_tween().tween_property(b, "scale", Vector2(0.92, 0.92), 0.06))
	b.button_up.connect(func():
		b.create_tween().tween_property(b, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK))
	return b


static func panel(rect: Rect2, color := Color(0.17, 0.2, 0.3, 0.97)) -> Panel:
	var p := Panel.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(36)
	sb.set_border_width_all(8)
	sb.border_color = DARK
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.shadow_size = 18
	p.add_theme_stylebox_override("panel", sb)
	p.position = rect.position
	p.size = rect.size
	return p


static func dim(parent: Node, alpha := 0.6) -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(0, 0, 0, alpha)
	c.size = Vector2(2143, 1062)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	parent.add_child(c)
	return c
