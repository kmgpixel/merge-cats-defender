extends Node
## Accès aux planches de sprites générées par tools/build_assets.py (assets/atlas.json).

var data: Dictionary = {}
var _tex: Dictionary = {}


func _init() -> void:
	var f := FileAccess.open("res://assets/atlas.json", FileAccess.READ)
	data = JSON.parse_string(f.get_as_text())


func tex(key: String) -> Texture2D:
	if not _tex.has(key):
		_tex[key] = load(data[key].src)
	return _tex[key]


func size_of(key: String) -> Vector2:
	var d: Dictionary = data[key]
	if d.has("w"):
		return Vector2(d.w, d.h)
	return Vector2(d.fw, d.fh)
