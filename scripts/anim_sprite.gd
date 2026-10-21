class_name AnimSprite
extends Sprite2D
## Joue une animation d'une planche de l'atlas, ancrée au centre bas (les pieds).

signal finished

var anim := ""
var fps := 20.0
var loop := true
var _t := 0.0
var _n := 1
var _done := false


func play(key: String, p_loop := true, p_fps := 20.0, restart := false) -> void:
	if key == anim and not restart:
		return
	var d: Dictionary = A.data[key]
	frame = 0
	texture = A.tex(key)
	hframes = int(d.cols)
	vframes = int(ceil(float(d.n) / float(d.cols)))
	centered = false
	offset = Vector2(d.ox, d.oy)
	_n = int(d.n)
	anim = key
	loop = p_loop
	fps = p_fps
	_t = 0.0
	_done = false


## Recentre la planche sur l'origine (effets qui ne posent pas au sol).
func center_anchor() -> void:
	var d: Dictionary = A.data[anim]
	offset = Vector2(-d.fw / 2.0, -d.fh / 2.0)


func _process(delta: float) -> void:
	if _n <= 1 or _done:
		return
	_t += delta * fps
	var f := int(_t)
	if f >= _n:
		if loop:
			_t = fmod(_t, _n)
			f = int(_t)
		else:
			f = _n - 1
			_done = true
			finished.emit()
	frame = f
