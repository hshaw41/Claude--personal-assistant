extends Node

# Orders board (Hay Day's truck/boat orders simplified).
# Each order = { items: {id: qty}, coin_reward, xp_reward }

signal changed

var active: Array = []
var max_orders: int = 4
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	# Seed with a few starter orders.
	for i in range(max_orders):
		active.append(_make_order())
	changed.emit()

func _make_order() -> Dictionary:
	var level := GameState.level
	var pool: Array = []
	# Only include items the player could plausibly produce.
	for id in Catalog.CROPS.keys():
		pool.append(id)
	if level >= 2:
		for id in Catalog.ANIMAL_PRODUCTS.keys():
			pool.append(id)
	if level >= 3:
		for id in Catalog.RECIPES.keys():
			pool.append(id)

	var num_items: int = rng.randi_range(1, min(3, 1 + level / 3))
	var items: Dictionary = {}
	var coin_total: int = 0
	var xp_total: int = 0
	for i in range(num_items):
		var id: String = pool[rng.randi() % pool.size()]
		var qty: int = rng.randi_range(2, 6)
		items[id] = items.get(id, 0) + qty
		coin_total += Catalog.sell_price(id) * qty
		xp_total += Catalog.xp_for(id) * qty
	# Order bonus over raw sell price.
	var bonus: float = 1.3 + rng.randf() * 0.5
	return {
		"items": items,
		"coin_reward": int(coin_total * bonus),
		"xp_reward": int(max(1, xp_total * 1.5)),
	}

func can_fulfill(idx: int) -> bool:
	if idx < 0 or idx >= active.size(): return false
	return Inventory.has_all(active[idx].items)

func fulfill(idx: int) -> bool:
	if not can_fulfill(idx): return false
	var o: Dictionary = active[idx]
	Inventory.consume_all(o.items)
	GameState.add_coins(o.coin_reward)
	GameState.add_xp(o.xp_reward)
	active.remove_at(idx)
	active.append(_make_order())
	changed.emit()
	return true

func discard(idx: int) -> bool:
	if idx < 0 or idx >= active.size(): return false
	# Cost 1 diamond like Hay Day.
	if not GameState.spend_diamonds(1): return false
	active.remove_at(idx)
	active.append(_make_order())
	changed.emit()
	return true

func to_dict() -> Dictionary:
	return {"active": active.duplicate(true), "max_orders": max_orders}

func from_dict(d: Dictionary) -> void:
	active = d.get("active", []).duplicate(true)
	max_orders = int(d.get("max_orders", 4))
	while active.size() < max_orders:
		active.append(_make_order())
	changed.emit()
