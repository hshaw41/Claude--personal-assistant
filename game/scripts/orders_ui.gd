extends PanelContainer

# Orders board UI. Toggleable via O key.

var _list: VBoxContainer

func _ready() -> void:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	add_child(vb)

	var title := Label.new()
	title.text = "Orders Board"
	vb.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(300, 320)
	vb.add_child(scroll)

	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)

	Orders.changed.connect(_refresh)
	Inventory.changed.connect(_refresh)
	_refresh()

func _refresh() -> void:
	for c in _list.get_children():
		c.queue_free()
	for i in range(Orders.active.size()):
		var o: Dictionary = Orders.active[i]
		var panel := PanelContainer.new()
		var vb := VBoxContainer.new()
		panel.add_child(vb)

		var req := Label.new()
		var parts := []
		for k in o.items:
			parts.append("%dx %s" % [o.items[k], Catalog.display_name(k)])
		req.text = ", ".join(parts)
		vb.add_child(req)

		var reward := Label.new()
		reward.text = "Reward: %dc / %d XP" % [o.coin_reward, o.xp_reward]
		vb.add_child(reward)

		var row := HBoxContainer.new()
		var fulfill_btn := Button.new()
		fulfill_btn.text = "Fulfill"
		fulfill_btn.disabled = not Orders.can_fulfill(i)
		fulfill_btn.pressed.connect(Orders.fulfill.bind(i))
		row.add_child(fulfill_btn)
		var discard_btn := Button.new()
		discard_btn.text = "Discard (1 gem)"
		discard_btn.disabled = GameState.diamonds < 1
		discard_btn.pressed.connect(Orders.discard.bind(i))
		row.add_child(discard_btn)
		vb.add_child(row)

		_list.add_child(panel)
