extends PanelContainer

# Seed selector + quick-sell panel. Toggleable via S key.
signal seed_selected(id: String)

var farm_ref: Node
var _sell_list: VBoxContainer
var _seed_buttons: Array = []

func _ready() -> void:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	add_child(vb)

	var title := Label.new()
	title.text = "Shop"
	vb.add_child(title)

	var seed_header := Label.new()
	seed_header.text = "Seeds (click to select)"
	vb.add_child(seed_header)

	var seed_grid := GridContainer.new()
	seed_grid.columns = 2
	vb.add_child(seed_grid)
	for id in Catalog.CROPS.keys():
		var c: Dictionary = Catalog.CROPS[id]
		var btn := Button.new()
		btn.text = "%s  (%dc, %ds)" % [c.name, c.buy, c.grow_s]
		btn.pressed.connect(_on_seed_picked.bind(id))
		seed_grid.add_child(btn)
		_seed_buttons.append({"id": id, "btn": btn})

	var sep := HSeparator.new()
	vb.add_child(sep)

	var sell_header := Label.new()
	sell_header.text = "Quick sell (market price)"
	vb.add_child(sell_header)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(260, 220)
	vb.add_child(scroll)

	_sell_list = VBoxContainer.new()
	scroll.add_child(_sell_list)

	Inventory.changed.connect(_refresh_sell_list)
	_refresh_sell_list()
	_highlight_selected()

func attach(farm: Node) -> void:
	farm_ref = farm
	farm_ref.selected_crop_changed.connect(func(_id): _highlight_selected())

func _on_seed_picked(id: String) -> void:
	if farm_ref: farm_ref.set_selected_crop(id)
	seed_selected.emit(id)

func _highlight_selected() -> void:
	for entry in _seed_buttons:
		var btn: Button = entry.btn
		btn.disabled = false
		if farm_ref and farm_ref.selected_crop == entry.id:
			btn.modulate = Color("#ffe680")
		else:
			btn.modulate = Color("#ffffff")

func _refresh_sell_list() -> void:
	for c in _sell_list.get_children():
		c.queue_free()
	var all_items := {}
	for k in Inventory.silo: all_items[k] = Inventory.silo[k]
	for k in Inventory.barn: all_items[k] = Inventory.barn[k]
	if all_items.is_empty():
		var empty := Label.new()
		empty.text = "(nothing to sell)"
		_sell_list.add_child(empty)
		return
	for id in all_items:
		var row := HBoxContainer.new()
		var lbl := Label.new()
		lbl.text = "%s x%d @ %dc" % [Catalog.display_name(id), all_items[id], Catalog.sell_price(id)]
		lbl.custom_minimum_size.x = 170
		row.add_child(lbl)
		var sell1 := Button.new()
		sell1.text = "Sell 1"
		sell1.pressed.connect(_sell.bind(id, 1))
		row.add_child(sell1)
		var sell_all := Button.new()
		sell_all.text = "Sell all"
		sell_all.pressed.connect(_sell.bind(id, all_items[id]))
		row.add_child(sell_all)
		_sell_list.add_child(row)

func _sell(id: String, n: int) -> void:
	var have: int = Inventory.count(id)
	var sell_n: int = min(n, have)
	if sell_n <= 0: return
	if not Inventory.remove(id, sell_n): return
	GameState.add_coins(Catalog.sell_price(id) * sell_n)
