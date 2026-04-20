extends Node

# Static game data. Add new crops/products here and they're available everywhere.
# Times are in real seconds (scaled down from Hay Day's minutes for PC play).

const CROPS := {
	"wheat":   {"name": "Wheat",   "grow_s": 5,   "buy": 1,   "sell": 3,   "xp": 1,  "color": "#e6c84c"},
	"corn":    {"name": "Corn",    "grow_s": 15,  "buy": 3,   "sell": 9,   "xp": 2,  "color": "#f0b429"},
	"carrot":  {"name": "Carrot",  "grow_s": 25,  "buy": 8,   "sell": 22,  "xp": 3,  "color": "#d97706"},
	"soybean": {"name": "Soybean", "grow_s": 40,  "buy": 15,  "sell": 38,  "xp": 4,  "color": "#84cc16"},
	"sugarcane":{"name":"Sugarcane","grow_s": 80, "buy": 40,  "sell": 95,  "xp": 6,  "color": "#22c55e"},
	"cotton":  {"name": "Cotton",  "grow_s": 140, "buy": 90,  "sell": 210, "xp": 9,  "color": "#f5f5dc"},
}

const ANIMAL_PRODUCTS := {
	"egg":   {"name": "Egg",   "sell": 20,  "xp": 2, "source": "chicken", "cycle_s": 60,  "color": "#fff4c2"},
	"milk":  {"name": "Milk",  "sell": 47,  "xp": 3, "source": "cow",     "cycle_s": 120, "color": "#fafafa"},
	"wool":  {"name": "Wool",  "sell": 70,  "xp": 4, "source": "sheep",   "cycle_s": 180, "color": "#e0e0e0"},
	"bacon": {"name": "Bacon", "sell": 111, "xp": 5, "source": "pig",     "cycle_s": 240, "color": "#f4a1a1"},
}

# Production recipes for buildings (bakery, feed mill, dairy, etc.)
const RECIPES := {
	"bread":        {"name": "Bread",        "inputs": {"wheat": 3},              "time_s": 9,   "sell": 21,  "xp": 3, "building": "bakery",   "color": "#caa472"},
	"corn_bread":   {"name": "Corn Bread",   "inputs": {"wheat": 2, "corn": 3},   "time_s": 30,  "sell": 56,  "xp": 6, "building": "bakery",   "color": "#d4a574"},
	"chicken_feed": {"name": "Chicken Feed", "inputs": {"wheat": 2, "corn": 2},   "time_s": 5,   "sell": 11,  "xp": 1, "building": "feed_mill","color": "#b59b5a"},
	"cow_feed":     {"name": "Cow Feed",     "inputs": {"soybean": 2, "wheat": 2},"time_s": 20,  "sell": 28,  "xp": 3, "building": "feed_mill","color": "#8f7a3d"},
	"cream":        {"name": "Cream",        "inputs": {"milk": 1},               "time_s": 20,  "sell": 95,  "xp": 4, "building": "dairy",    "color": "#fff8d6"},
	"butter":       {"name": "Butter",       "inputs": {"milk": 2},               "time_s": 30,  "sell": 119, "xp": 5, "building": "dairy",    "color": "#f7d774"},
	"cheese":       {"name": "Cheese",       "inputs": {"milk": 3},               "time_s": 60,  "sell": 144, "xp": 7, "building": "dairy",    "color": "#f4c15d"},
	"sugar":        {"name": "Sugar",        "inputs": {"sugarcane": 2},          "time_s": 60,  "sell": 106, "xp": 6, "building": "sugar_mill","color":"#f0f0f0"},
	"cloth":        {"name": "Cloth",        "inputs": {"cotton": 2},             "time_s": 90,  "sell": 315, "xp": 9, "building": "loom",     "color": "#efe4c8"},
}

# XP thresholds per level (cumulative). Index = level - 1.
const LEVEL_XP := [0, 4, 10, 18, 28, 42, 60, 85, 115, 150, 195, 250, 315, 395, 490, 600]

func all_sellable_ids() -> Array:
	var out := []
	for k in CROPS.keys(): out.append(k)
	for k in ANIMAL_PRODUCTS.keys(): out.append(k)
	for k in RECIPES.keys(): out.append(k)
	return out

func display_name(id: String) -> String:
	if CROPS.has(id): return CROPS[id].name
	if ANIMAL_PRODUCTS.has(id): return ANIMAL_PRODUCTS[id].name
	if RECIPES.has(id): return RECIPES[id].name
	return id

func sell_price(id: String) -> int:
	if CROPS.has(id): return CROPS[id].sell
	if ANIMAL_PRODUCTS.has(id): return ANIMAL_PRODUCTS[id].sell
	if RECIPES.has(id): return RECIPES[id].sell
	return 0

func xp_for(id: String) -> int:
	if CROPS.has(id): return CROPS[id].xp
	if ANIMAL_PRODUCTS.has(id): return ANIMAL_PRODUCTS[id].xp
	if RECIPES.has(id): return RECIPES[id].xp
	return 0

func color_for(id: String) -> Color:
	var hex := "#888888"
	if CROPS.has(id): hex = CROPS[id].color
	elif ANIMAL_PRODUCTS.has(id): hex = ANIMAL_PRODUCTS[id].color
	elif RECIPES.has(id): hex = RECIPES[id].color
	return Color(hex)
