extends Control

const Building := preload("res://scripts/building.gd")

var buildings: Array = []

# Building definitions with unlock level.
const DEFS := [
	{"id": "bakery",     "name": "Bakery",     "unlock": 2},
	{"id": "feed_mill",  "name": "Feed Mill",  "unlock": 1},
	{"id": "dairy",      "name": "Dairy",      "unlock": 3},
	{"id": "sugar_mill", "name": "Sugar Mill", "unlock": 6},
	{"id": "loom",       "name": "Loom",       "unlock": 8},
]

func _ready() -> void:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	add_child(vb)

	var label := Label.new()
	label.text = "Production"
	label.add_theme_color_override("font_color", Color("#ffffff"))
	vb.add_child(label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(260, 360)
	vb.add_child(scroll)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 6)
	scroll.add_child(inner)

	for def in DEFS:
		if GameState.level < def.unlock: continue
		var b := Building.new()
		inner.add_child(b)
		b.configure(def.id, def.name)
		buildings.append(b)

func to_save_dict() -> Dictionary:
	var arr := []
	for b in buildings: arr.append(b.to_save_dict())
	return {"buildings": arr}

func from_save_dict(d: Dictionary, _offline_s: float) -> void:
	var arr: Array = d.get("buildings", [])
	for i in range(min(arr.size(), buildings.size())):
		buildings[i].from_save_dict(arr[i])
