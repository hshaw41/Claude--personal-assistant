extends Node

signal coins_changed(new_value: int)
signal diamonds_changed(new_value: int)
signal xp_changed(new_xp: int, new_level: int)
signal level_up(new_level: int)

var coins: int = 100
var diamonds: int = 5
var xp: int = 0
var level: int = 1

func add_coins(n: int) -> void:
	coins = max(0, coins + n)
	coins_changed.emit(coins)

func spend_coins(n: int) -> bool:
	if coins < n: return false
	coins -= n
	coins_changed.emit(coins)
	return true

func add_diamonds(n: int) -> void:
	diamonds = max(0, diamonds + n)
	diamonds_changed.emit(diamonds)

func spend_diamonds(n: int) -> bool:
	if diamonds < n: return false
	diamonds -= n
	diamonds_changed.emit(diamonds)
	return true

func add_xp(n: int) -> void:
	xp += n
	var old_level := level
	while level < Catalog.LEVEL_XP.size() and xp >= Catalog.LEVEL_XP[level]:
		level += 1
	xp_changed.emit(xp, level)
	if level > old_level:
		# Small diamond reward per level, Hay Day style.
		add_diamonds(1)
		level_up.emit(level)

func xp_into_level() -> int:
	return xp - Catalog.LEVEL_XP[level - 1]

func xp_for_next_level() -> int:
	if level >= Catalog.LEVEL_XP.size():
		return -1
	return Catalog.LEVEL_XP[level] - Catalog.LEVEL_XP[level - 1]

func to_dict() -> Dictionary:
	return {"coins": coins, "diamonds": diamonds, "xp": xp, "level": level}

func from_dict(d: Dictionary) -> void:
	coins = int(d.get("coins", 100))
	diamonds = int(d.get("diamonds", 5))
	xp = int(d.get("xp", 0))
	level = int(d.get("level", 1))
	coins_changed.emit(coins)
	diamonds_changed.emit(diamonds)
	xp_changed.emit(xp, level)
