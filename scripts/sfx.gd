extends Node
## Petits bruitages synthétisés (tools/make_sounds.py), joués sur un pool de lecteurs.

const NAMES := ["shoot", "hit", "merge", "buy", "coin", "boom", "die", "wall", "click", "win", "lose", "punch"]

var _streams := {}
var _players: Array[AudioStreamPlayer] = []
var _last := {}


func _ready() -> void:
	for n in NAMES:
		_streams[n] = load("res://sounds/%s.wav" % n)
	for i in 14:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)


func play(n: String, vol_db := 0.0, pitch := 1.0) -> void:
	if not G.sound:
		return
	# Évite la bouillie sonore quand dix chats tirent dans la même image
	var now := Time.get_ticks_msec()
	if now - int(_last.get(n, 0)) < 45:
		return
	_last[n] = now
	for p in _players:
		if not p.playing:
			p.stream = _streams[n]
			p.volume_db = vol_db
			p.pitch_scale = pitch * randf_range(0.94, 1.06)
			p.play()
			return
