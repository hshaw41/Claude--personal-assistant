extends Control

# A single animal that periodically produces a product. Click to collect.
# Requires feed: consumes feed item from barn when starting a new cycle.

signal collected(id: String, amount: int)

const SIZE := Vector2(96, 80)

var product_id: String = "egg"
var feed_id: String = "chicken_feed"
var cycle_s: float = 60.0
var cycle_start: float = 0.0
var state: String = "IDLE"   # IDLE, GROWING, READY

func _ready() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_input)
	set_process(true)

func configure(product: String, feed: String) -> void:
	product_id = product
	feed_id = feed
	cycle_s = float(Catalog.ANIMAL_PRODUCTS[product].cycle_s)

func _process(_delta: float) -> void:
	if state == "GROWING" and _progress() >= 1.0:
		state = "READY"
	queue_redraw()

func _progress() -> float:
	if state != "GROWING": return 0.0
	return clamp((Time.get_unix_time_from_system() - cycle_start) / cycle_s, 0.0, 1.0)

func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		match state:
			"IDLE":
				_try_start_cycle()
			"READY":
				_collect()

func _try_start_cycle() -> void:
	if not Inventory.has_all({feed_id: 1}): return
	Inventory.consume_all({feed_id: 1})
	cycle_start = Time.get_unix_time_from_system()
	state = "GROWING"

func _collect() -> void:
	var added := Inventory.add(product_id, 1)
	if added > 0:
		GameState.add_xp(Catalog.xp_for(product_id))
		collected.emit(product_id, added)
	state = "IDLE"

func _draw() -> void:
	# Pen background.
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#9c6d3a"))
	draw_rect(Rect2(Vector2(4, 4), SIZE - Vector2(8, 8)), Color("#caa472"))
	# Animal body (simple blob, color by species).
	var body_color := Color("#ffffff")
	match Catalog.ANIMAL_PRODUCTS[product_id].source:
		"chicken": body_color = Color("#fef3c7")
		"cow":     body_color = Color("#f3f4f6")
		"sheep":   body_color = Color("#e5e7eb")
		"pig":     body_color = Color("#fbcfe8")
	var c := SIZE / 2.0
	draw_circle(c, 22, body_color.darkened(0.15))
	draw_circle(c, 18, body_color)
	draw_circle(c + Vector2(14, -6), 8, body_color)  # head
	draw_circle(c + Vector2(16, -8), 2, Color.BLACK)  # eye

	if state == "GROWING":
		var bar_bg := Rect2(Vector2(6, SIZE.y - 10), Vector2(SIZE.x - 12, 4))
		draw_rect(bar_bg, Color(0, 0, 0, 0.5))
		draw_rect(Rect2(bar_bg.position, Vector2(bar_bg.size.x * _progress(), bar_bg.size.y)), Color("#8cf05c"))
	elif state == "READY":
		draw_circle(Vector2(SIZE.x - 10, 10), 5, Color("#ffffff"))

func to_save_dict() -> Dictionary:
	return {"product_id": product_id, "feed_id": feed_id, "cycle_s": cycle_s,
			"cycle_start": cycle_start, "state": state}

func from_save_dict(d: Dictionary) -> void:
	product_id = String(d.get("product_id", "egg"))
	feed_id = String(d.get("feed_id", "chicken_feed"))
	cycle_s = float(d.get("cycle_s", 60.0))
	cycle_start = float(d.get("cycle_start", 0.0))
	state = String(d.get("state", "IDLE"))
	if state == "GROWING" and _progress() >= 1.0:
		state = "READY"
	queue_redraw()
