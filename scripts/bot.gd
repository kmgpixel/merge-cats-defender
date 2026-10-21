extends Node
## Joueur automatique pour tester l'équilibrage en headless :
## godot --headless --path . --fixed-fps 30 -- --bot=5

var game
var _t := 0.0


func _process(delta: float) -> void:
	if game.over:
		return
	_t -= delta
	if _t > 0:
		return
	_t = 0.4
	# Fusionne la première paire trouvée
	for i in 10:
		for j in range(i + 1, 10):
			var a = game.grid[i]
			var b = game.grid[j]
			if a and b and a.level == b.level and a.level < Cat.MAX_LEVEL:
				game._drag = a
				game._drop(j)
				return
	if game.free_slot() < 0:
		# Grille pleine sans paire : on vend le plus faible
		var low := -1
		for i in 10:
			if game.grid[i] and (low < 0 or game.grid[i].level < game.grid[low].level):
				low = i
		if low >= 0 and game.coins >= game.buy_cost():
			game._drag = game.grid[low]
			game._drop(game.TRASH)
	if game.wall_hp < game.WALL_MAX * 0.45 and game.coins >= game.repair_cost():
		game._on_repair()
	elif game.coins >= game.buy_cost() and game.free_slot() >= 0:
		game._on_buy()
	for a in game.ADDONS:
		if game.coins > game.addon_cost(a) * 3 and game.enemies.size() > 4:
			game._use_addon(a)
