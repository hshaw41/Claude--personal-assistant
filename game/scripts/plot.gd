extends Control

# A single farm plot. States: EMPTY -> PLANTED (growing) -> READY.
# Left click: plant selected crop (if EMPTY) or harvest (if READY).

signal harvested(crop_id: String, amount: int)
signal wants_plant(plot: Control)

enum State { EMPTY, PLANTED, READY }

var state: int = State.EMPTY
var crop_id: String = ""
var plant_time: float = 0.0     # unix seconds
var grow_s: float = 0.0

const PLOT_SIZE := Vector2(72, 72)

func _ready() -> void:
	custom_minimum_size = PLOT_SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	set_process(true)

func _process(_delta: float) -> void:
	if state == State.PLANTED:
		if _progress() >= 1.0:
			state = State.READY
		queue_redraw()

func _progress() -> float:
	if state != State.PLANTED: return 0.0
	var elapsed := Time.get_unix_time_from_system() - plant_time
	return clamp(elapsed / grow_s, 0.0, 1.0)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		match state:
			State.EMPTY:
				wants_plant.emit(self)
			State.READY:
				_harvest()

func plant(id: String) -> bool:
	if state != State.EMPTY: return false
	if not Catalog.CROPS.has(id): return false
	var cost: int = Catalog.CROPS[id].buy
	if not GameState.spend_coins(cost): return false
	crop_id = id
	grow_s = float(Catalog.CROPS[id].grow_s)
	plant_time = Time.get_unix_time_from_system()
	state = State.PLANTED
	queue_redraw()
	return true

func _harvest() -> void:
	# Hay Day gives 2x yield per plot.
	var yield_n: int = 2
	var added: int = Inventory.add(crop_id, yield_n)
	if added > 0:
		GameState.add_xp(Catalog.xp_for(crop_id) * added)
		harvested.emit(crop_id, added)
	state = State.EMPTY
	crop_id = ""
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, PLOT_SIZE)
	# Soil base.
	draw_rect(rect, Color("#6b4a2b"))
	# Furrows.
	for i in range(3):
		var y := 16 + i * 20
		draw_line(Vector2(6, y), Vector2(PLOT_SIZE.x - 6, y), Color("#523a22"), 2)
	# Border.
	draw_rect(rect, Color("#3a2414"), false, 2)

	match state:
		State.PLANTED:
			var p := _progress()
			var color := Catalog.color_for(crop_id)
			# Seedling (small) -> full (large).
			var radius: float = lerp(4.0, 18.0, p)
			var center := PLOT_SIZE / 2.0
			draw_circle(center, radius, color.darkened(0.3))
			draw_circle(center, radius * 0.7, color)
			# Progress bar.
			var bar_bg := Rect2(Vector2(6, PLOT_SIZE.y - 10), Vector2(PLOT_SIZE.x - 12, 4))
			draw_rect(bar_bg, Color(0, 0, 0, 0.5))
			var bar_fg := Rect2(bar_bg.position, Vector2(bar_bg.size.x * p, bar_bg.size.y))
			draw_rect(bar_fg, Color("#8cf05c"))
		State.READY:
			var color := Catalog.color_for(crop_id)
			var center := PLOT_SIZE / 2.0
			# Cluster of mature plants.
			for dx in [-14, 0, 14]:
				for dy in [-14, 14]:
					draw_circle(center + Vector2(dx, dy), 9, color.darkened(0.2))
					draw_circle(center + Vector2(dx, dy), 6, color)
			# Sparkle to indicate ready.
			draw_circle(Vector2(PLOT_SIZE.x - 10, 10), 4, Color("#ffffff"))

func to_save_dict() -> Dictionary:
	return {"state": state, "crop_id": crop_id, "plant_time": plant_time, "grow_s": grow_s}

func from_save_dict(d: Dictionary) -> void:
	state = int(d.get("state", State.EMPTY))
	crop_id = String(d.get("crop_id", ""))
	plant_time = float(d.get("plant_time", 0.0))
	grow_s = float(d.get("grow_s", 0.0))
	if state == State.PLANTED and _progress() >= 1.0:
		state = State.READY
	queue_redraw()
