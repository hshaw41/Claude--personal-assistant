extends Node2D

# Entry scene. Builds the UI tree in code (no fragile .tscn authoring).
# Layout:
#   Top: HUD (full width)
#   Left: Farm grid
#   Right top: Animals, bottom: Production buildings
#   Bottom-right floating: Shop + Orders panels (toggleable)

const Farm := preload("res://scripts/farm.gd")
const HUD := preload("res://scripts/hud.gd")
const Shop := preload("res://scripts/shop.gd")
const OrdersUI := preload("res://scripts/orders_ui.gd")
const Animals := preload("res://scripts/animals.gd")
const Buildings := preload("res://scripts/buildings.gd")

var farm: Node
var animals: Node
var buildings: Node
var shop_panel: Node
var orders_panel: Node

func _ready() -> void:
	# Load persistent state FIRST so animals/buildings unlock at the right level.
	SaveSystem.load_state()

	# Background.
	var bg := ColorRect.new()
	bg.color = Color("#4a7c3a")
	bg.anchor_right = 1
	bg.anchor_bottom = 1
	add_child(bg)

	# Root UI.
	var root := Control.new()
	root.anchor_right = 1
	root.anchor_bottom = 1
	add_child(root)

	# HUD.
	var hud := HUD.new()
	hud.anchor_right = 1
	hud.offset_bottom = 56
	root.add_child(hud)

	# Farm (left).
	farm = Farm.new()
	farm.offset_left = 16
	farm.offset_top = 72
	farm.custom_minimum_size = Vector2(352, 352)
	root.add_child(farm)

	# Selected crop label under farm.
	var sel_label := Label.new()
	sel_label.text = "Planting: Wheat"
	sel_label.offset_left = 16
	sel_label.offset_top = 72 + 352 + 8
	sel_label.add_theme_color_override("font_color", Color("#ffffff"))
	root.add_child(sel_label)
	farm.selected_crop_changed.connect(func(id): sel_label.text = "Planting: %s" % Catalog.display_name(id))

	# Animals (top-right).
	animals = Animals.new()
	animals.offset_left = 400
	animals.offset_top = 72
	root.add_child(animals)

	# Buildings (right middle).
	buildings = Buildings.new()
	buildings.offset_left = 640
	buildings.offset_top = 72
	root.add_child(buildings)

	# Shop (hidden panel, toggled via S).
	shop_panel = Shop.new()
	shop_panel.anchor_right = 0
	shop_panel.offset_left = 16
	shop_panel.offset_top = 440
	shop_panel.visible = false
	root.add_child(shop_panel)
	shop_panel.attach(farm)

	# Orders (hidden panel, toggled via O).
	orders_panel = OrdersUI.new()
	orders_panel.offset_left = 900
	orders_panel.offset_top = 72
	orders_panel.visible = false
	root.add_child(orders_panel)

	# Hints footer.
	var hints := Label.new()
	hints.text = "[S] Shop  [O] Orders  [F] Save"
	hints.anchor_top = 1
	hints.anchor_bottom = 1
	hints.offset_top = -24
	hints.offset_left = 16
	hints.add_theme_color_override("font_color", Color("#ffffff"))
	root.add_child(hints)

	# Register node refs and restore per-scene state.
	SaveSystem.farm_ref = farm
	SaveSystem.animals_ref = animals
	SaveSystem.buildings_ref = buildings
	SaveSystem.load_scene_state()

	# Autosave every 30s so offline progress is roughly preserved on hard close.
	var timer := Timer.new()
	timer.wait_time = 30.0
	timer.autostart = true
	timer.timeout.connect(func(): SaveSystem.save_game())
	add_child(timer)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_shop"):
		shop_panel.visible = not shop_panel.visible
	elif event.is_action_pressed("toggle_orders"):
		orders_panel.visible = not orders_panel.visible
	elif event.is_action_pressed("save_game"):
		SaveSystem.save_game()
