extends Control

# Container for all animal pens. Unlocks species by level.
const AnimalPen := preload("res://scripts/animal_pen.gd")

var pens: Array = []

func _ready() -> void:
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	add_child(vbox)

	var label := Label.new()
	label.text = "Animals  (click to feed / collect)"
	label.add_theme_color_override("font_color", Color("#ffffff"))
	vbox.add_child(label)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	vbox.add_child(grid)

	# Map product -> feed item. (Simplified Hay Day feed chain.)
	var species := [
		{"product": "egg",   "feed": "chicken_feed", "unlock": 1},
		{"product": "milk",  "feed": "cow_feed",     "unlock": 2},
		{"product": "wool",  "feed": "cow_feed",     "unlock": 4},
		{"product": "bacon", "feed": "cow_feed",     "unlock": 6},
	]
	for s in species:
		if GameState.level < s.unlock: continue
		var pen := AnimalPen.new()
		pen.configure(s.product, s.feed)
		grid.add_child(pen)
		pens.append(pen)

func to_save_dict() -> Dictionary:
	var arr := []
	for p in pens: arr.append(p.to_save_dict())
	return {"pens": arr}

func from_save_dict(d: Dictionary, _offline_s: float) -> void:
	var arr: Array = d.get("pens", [])
	for i in range(min(arr.size(), pens.size())):
		pens[i].from_save_dict(arr[i])
