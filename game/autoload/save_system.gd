extends Node

const SAVE_PATH := "user://savegame.json"

signal saved
signal loaded

# Registered savers: node must implement `to_save_dict()` and `from_save_dict(d)`.
var farm_ref: Node = null
var buildings_ref: Node = null
var animals_ref: Node = null

func save_game() -> void:
	var data := {
		"version": 1,
		"timestamp": Time.get_unix_time_from_system(),
		"game_state": GameState.to_dict(),
		"inventory": Inventory.to_dict(),
		"orders": Orders.to_dict(),
		"farm": farm_ref.to_save_dict() if farm_ref else {},
		"buildings": buildings_ref.to_save_dict() if buildings_ref else {},
		"animals": animals_ref.to_save_dict() if animals_ref else {},
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("Save failed: could not open %s" % SAVE_PATH)
		return
	f.store_string(JSON.stringify(data))
	f.close()
	saved.emit()

var _pending_data: Dictionary = {}
var _pending_offline_s: float = 0.0

func load_state() -> bool:
	# Phase 1: load game state, inventory, orders from disk. Call this
	# BEFORE instantiating UI that reads GameState.level for unlocks.
	_pending_data = {}
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null: return false
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Save file corrupt")
		return false
	_pending_data = parsed
	var now := Time.get_unix_time_from_system()
	var prev: float = float(_pending_data.get("timestamp", now))
	_pending_offline_s = max(0.0, now - prev)

	GameState.from_dict(_pending_data.get("game_state", {}))
	Inventory.from_dict(_pending_data.get("inventory", {}))
	Orders.from_dict(_pending_data.get("orders", {}))
	return true

func load_scene_state() -> void:
	# Phase 2: after UI exists, restore per-node state.
	if _pending_data.is_empty(): return
	if farm_ref: farm_ref.from_save_dict(_pending_data.get("farm", {}), _pending_offline_s)
	if buildings_ref: buildings_ref.from_save_dict(_pending_data.get("buildings", {}), _pending_offline_s)
	if animals_ref: animals_ref.from_save_dict(_pending_data.get("animals", {}), _pending_offline_s)
	loaded.emit()
	_pending_data = {}
