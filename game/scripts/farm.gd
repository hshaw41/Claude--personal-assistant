extends Control

# 4x4 grid of plots. Tracks the currently selected crop to plant.

const Plot := preload("res://scripts/plot.gd")
const GRID_COLS := 4
const GRID_ROWS := 4
const GUTTER := 8

signal selected_crop_changed(crop_id: String)

var selected_crop: String = "wheat"
var plots: Array = []

func _ready() -> void:
	var grid := GridContainer.new()
	grid.columns = GRID_COLS
	grid.add_theme_constant_override("h_separation", GUTTER)
	grid.add_theme_constant_override("v_separation", GUTTER)
	grid.anchor_right = 1
	grid.anchor_bottom = 1
	add_child(grid)

	for i in range(GRID_COLS * GRID_ROWS):
		var p := Plot.new()
		p.wants_plant.connect(_on_plot_wants_plant)
		grid.add_child(p)
		plots.append(p)

func set_selected_crop(id: String) -> void:
	if Catalog.CROPS.has(id):
		selected_crop = id
		selected_crop_changed.emit(id)

func _on_plot_wants_plant(plot: Control) -> void:
	# Ignore if the player can't afford or doesn't unlock the crop yet.
	plot.plant(selected_crop)

func to_save_dict() -> Dictionary:
	var arr := []
	for p in plots:
		arr.append(p.to_save_dict())
	return {"plots": arr, "selected_crop": selected_crop}

func from_save_dict(d: Dictionary, _offline_s: float) -> void:
	var arr: Array = d.get("plots", [])
	for i in range(min(arr.size(), plots.size())):
		plots[i].from_save_dict(arr[i])
	var sel := String(d.get("selected_crop", "wheat"))
	set_selected_crop(sel)
