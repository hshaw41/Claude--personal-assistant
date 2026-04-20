extends Node

signal changed

# Separate barn (products) and silo (crops) like Hay Day.
var silo: Dictionary = {}   # crop_id -> int
var barn: Dictionary = {}   # product_id -> int

var silo_capacity: int = 50
var barn_capacity: int = 50

func _is_crop(id: String) -> bool:
	return Catalog.CROPS.has(id)

func _bucket(id: String) -> Dictionary:
	return silo if _is_crop(id) else barn

func _capacity(id: String) -> int:
	return silo_capacity if _is_crop(id) else barn_capacity

func _used(id: String) -> int:
	var b := _bucket(id)
	var total := 0
	for k in b: total += b[k]
	return total

func available_space(id: String) -> int:
	return _capacity(id) - _used(id)

func count(id: String) -> int:
	return _bucket(id).get(id, 0)

func add(id: String, n: int = 1) -> int:
	# Returns amount actually added (respecting capacity).
	var space := available_space(id)
	var added: int = min(n, space)
	if added <= 0: return 0
	var b := _bucket(id)
	b[id] = b.get(id, 0) + added
	changed.emit()
	return added

func remove(id: String, n: int = 1) -> bool:
	var b := _bucket(id)
	if b.get(id, 0) < n: return false
	b[id] -= n
	if b[id] <= 0: b.erase(id)
	changed.emit()
	return true

func has_all(requirements: Dictionary) -> bool:
	for k in requirements:
		if count(k) < int(requirements[k]):
			return false
	return true

func consume_all(requirements: Dictionary) -> bool:
	if not has_all(requirements): return false
	for k in requirements:
		remove(k, int(requirements[k]))
	return true

func expand_silo(by: int = 25) -> void:
	silo_capacity += by
	changed.emit()

func expand_barn(by: int = 25) -> void:
	barn_capacity += by
	changed.emit()

func to_dict() -> Dictionary:
	return {
		"silo": silo.duplicate(true),
		"barn": barn.duplicate(true),
		"silo_capacity": silo_capacity,
		"barn_capacity": barn_capacity,
	}

func from_dict(d: Dictionary) -> void:
	silo = d.get("silo", {}).duplicate(true)
	barn = d.get("barn", {}).duplicate(true)
	silo_capacity = int(d.get("silo_capacity", 50))
	barn_capacity = int(d.get("barn_capacity", 50))
	changed.emit()
