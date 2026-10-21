extends Node
## Progression sauvegardée (IndexedDB sur le Web via user://).

const SAVE := "user://save.cfg"
const LEVELS := 15

var unlocked := 1
var sound := true


func _ready() -> void:
	var c := ConfigFile.new()
	if c.load(SAVE) == OK:
		unlocked = c.get_value("p", "unlocked", 1)
		sound = c.get_value("p", "sound", true)


func save() -> void:
	var c := ConfigFile.new()
	c.set_value("p", "unlocked", unlocked)
	c.set_value("p", "sound", sound)
	c.save(SAVE)


func level_won(level: int) -> void:
	unlocked = clampi(max(unlocked, level + 1), 1, LEVELS)
	save()
