extends PanelContainer

# Top HUD: coins, diamonds, level + XP bar, inventory summary, save button.

var coins_label: Label
var diamonds_label: Label
var level_label: Label
var xp_bar: ProgressBar
var silo_label: Label
var barn_label: Label

func _ready() -> void:
	custom_minimum_size = Vector2(0, 56)
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	add_child(hbox)

	coins_label = _make_label("Coins: 0")
	hbox.add_child(coins_label)
	diamonds_label = _make_label("Diamonds: 0")
	hbox.add_child(diamonds_label)

	level_label = _make_label("Lv 1")
	hbox.add_child(level_label)

	xp_bar = ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(180, 16)
	xp_bar.min_value = 0
	xp_bar.max_value = 1
	hbox.add_child(xp_bar)

	silo_label = _make_label("Silo 0/0")
	hbox.add_child(silo_label)
	barn_label = _make_label("Barn 0/0")
	hbox.add_child(barn_label)

	var save_btn := Button.new()
	save_btn.text = "Save (F)"
	save_btn.pressed.connect(func(): SaveSystem.save_game())
	hbox.add_child(save_btn)

	GameState.coins_changed.connect(_on_coins)
	GameState.diamonds_changed.connect(_on_diamonds)
	GameState.xp_changed.connect(_on_xp)
	Inventory.changed.connect(_refresh_inv)

	_on_coins(GameState.coins)
	_on_diamonds(GameState.diamonds)
	_on_xp(GameState.xp, GameState.level)
	_refresh_inv()

func _make_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", Color("#ffffff"))
	return l

func _on_coins(n: int) -> void: coins_label.text = "Coins: %d" % n
func _on_diamonds(n: int) -> void: diamonds_label.text = "Diamonds: %d" % n

func _on_xp(_xp: int, lvl: int) -> void:
	level_label.text = "Lv %d" % lvl
	var into := GameState.xp_into_level()
	var need := GameState.xp_for_next_level()
	if need <= 0:
		xp_bar.max_value = 1
		xp_bar.value = 1
	else:
		xp_bar.max_value = need
		xp_bar.value = into

func _refresh_inv() -> void:
	var silo_used := 0
	for k in Inventory.silo: silo_used += Inventory.silo[k]
	var barn_used := 0
	for k in Inventory.barn: barn_used += Inventory.barn[k]
	silo_label.text = "Silo %d/%d" % [silo_used, Inventory.silo_capacity]
	barn_label.text = "Barn %d/%d" % [barn_used, Inventory.barn_capacity]
