extends PanelContainer

# Production building (bakery, feed mill, dairy, etc.).
# Click a recipe row to queue it; click an output slot to collect.
# Simplified to one slot per building (Hay Day has queues — extensible later).

signal collected(id: String, amount: int)

var building_id: String = ""
var label_text: String = ""

var busy: bool = false
var cur_recipe: String = ""
var start_time: float = 0.0

var _title_label: Label
var _status_label: Label
var _recipe_list: VBoxContainer

func _ready() -> void:
	set_process(true)
	_build_ui()

func configure(id: String, title: String) -> void:
	building_id = id
	label_text = title
	if _title_label:
		_title_label.text = title
		_rebuild_recipe_list()

func _build_ui() -> void:
	custom_minimum_size = Vector2(240, 0)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	add_child(vb)

	_title_label = Label.new()
	_title_label.text = label_text
	vb.add_child(_title_label)

	_status_label = Label.new()
	_status_label.text = "Idle"
	vb.add_child(_status_label)

	_recipe_list = VBoxContainer.new()
	_recipe_list.add_theme_constant_override("separation", 2)
	vb.add_child(_recipe_list)
	_rebuild_recipe_list()

func _rebuild_recipe_list() -> void:
	if _recipe_list == null: return
	for c in _recipe_list.get_children():
		c.queue_free()
	for recipe_id in Catalog.RECIPES.keys():
		var r: Dictionary = Catalog.RECIPES[recipe_id]
		if r.building != building_id: continue
		var btn := Button.new()
		btn.text = _format_recipe(recipe_id, r)
		btn.pressed.connect(_on_recipe_pressed.bind(recipe_id))
		_recipe_list.add_child(btn)

func _format_recipe(id: String, r: Dictionary) -> String:
	var inputs := []
	for k in r.inputs:
		inputs.append("%dx %s" % [r.inputs[k], Catalog.display_name(k)])
	return "%s (%s, %ds)" % [r.name, ", ".join(inputs), int(r.time_s)]

func _on_recipe_pressed(recipe_id: String) -> void:
	if busy:
		# Collect if ready.
		if _progress() >= 1.0:
			_collect()
		return
	var r: Dictionary = Catalog.RECIPES[recipe_id]
	if not Inventory.has_all(r.inputs): return
	Inventory.consume_all(r.inputs)
	cur_recipe = recipe_id
	start_time = Time.get_unix_time_from_system()
	busy = true

func _progress() -> float:
	if not busy: return 0.0
	var r: Dictionary = Catalog.RECIPES[cur_recipe]
	return clamp((Time.get_unix_time_from_system() - start_time) / float(r.time_s), 0.0, 1.0)

func _process(_delta: float) -> void:
	if not busy:
		_status_label.text = "Idle"
		return
	var p := _progress()
	if p >= 1.0:
		_status_label.text = "Ready: %s  (click recipe to collect)" % Catalog.display_name(cur_recipe)
	else:
		_status_label.text = "Making %s... %d%%" % [Catalog.display_name(cur_recipe), int(p * 100)]

func _collect() -> void:
	var added := Inventory.add(cur_recipe, 1)
	if added > 0:
		GameState.add_xp(Catalog.xp_for(cur_recipe))
		collected.emit(cur_recipe, added)
	busy = false
	cur_recipe = ""

func to_save_dict() -> Dictionary:
	return {"building_id": building_id, "busy": busy, "cur_recipe": cur_recipe, "start_time": start_time}

func from_save_dict(d: Dictionary) -> void:
	building_id = String(d.get("building_id", building_id))
	busy = bool(d.get("busy", false))
	cur_recipe = String(d.get("cur_recipe", ""))
	start_time = float(d.get("start_time", 0.0))
