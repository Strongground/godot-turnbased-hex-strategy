extends Control

@export var theme_mgr: Node
@export var unit_name: RichTextLabel
@export var unit_strength: RichTextLabel
@export var unit_actionpoints: RichTextLabel
@export var unit_ammo: RichTextLabel
@export var unit_modifiers: Node

var unit: Node
var _experience = 0.0
var _experience_defs = null

func _ready():
	pass

# Public method to show unit info in the popup, given a unit node.
func show_unit_info(unit_node) -> void:
	if unit_node == null or not is_instance_valid(unit_node):
		push_warning("UnitInfoPopup: Invalid unit node")
		return
	unit = unit_node
	var _unit_data: Dictionary = {}
	_experience = unit.experience
	_experience_defs = unit.experience_definitions
	_unit_data =_populate_unit_data()
	_populate_popup(_unit_data)

func _populate_unit_data() -> Dictionary:
	if unit == null or not is_instance_valid(unit):
		return {}
	var _unit_data: Dictionary = {}
	_unit_data["strength"] = unit.get_strength_points()
	_unit_data["movement_points"] = unit.get_movement_points()
	_unit_data["ammo"] = unit.get_ammo()
	_unit_data["experience"] = unit.experience
	_unit_data["modifiers"] = self.get_active_modifiers_info(unit)
	return _unit_data

func _populate_popup(_unit_data: Dictionary) -> void:
	if unit_name != null:
		unit_name.set_text(unit.display_name)
	if unit_strength != null:
		unit_strength.set_text(str(_unit_data["strength"]))
	if unit_actionpoints != null:
		unit_actionpoints.set_text(str(_unit_data["movement_points"]))
	if unit_ammo != null:
		unit_ammo.set_text(str(_unit_data["ammo"]))
	if unit_modifiers != null:
		# delete existing modifiers first
		for child in unit_modifiers.get_children():
			child.queue_free() 
		# create a modifier scene instance for each active modifier and populate it with the modifier's information
		for mod_id in _unit_data["modifiers"]:
			var mod_info = _unit_data["modifiers"][mod_id]
			var mod_instance = preload("res://classes/modifier_template.tscn").instantiate()
			mod_instance.instanciate(mod_info)
			unit_modifiers.add_child(mod_instance)

func get_active_modifiers_info(unit_node) -> Dictionary:
	var modifiers_info = {}
	for mod_id in unit_node.active_modifiers:
		var mod_data: Dictionary = unit_node.active_modifiers[mod_id]
		if mod_data == null or not mod_data.has("display_name"):
			continue
		var duration_text = ""
		if mod_data.has("duration"):
			var duration = mod_data["duration"]
			if duration == -1:
				duration_text = "Permanent"
			elif duration == 1:
				duration_text = "1 turn"
			elif duration > 1:
				duration_text = str(int(duration)) + " turns"
		var description = mod_data.get("description", "")
		var icon_path = ""
		if mod_data.has("icon"):
			icon_path =  mod_data["icon"]
		modifiers_info[mod_id] = {
			"id": mod_id,
			"display_name": mod_data.get("display_name", "Unknown"),
			"description": description,
			"duration": duration_text,
			"icon": get_theme_sprite_path(icon_path) + ".png",
			"modifiers": mod_data.get("modifiers", {})
		}
	return modifiers_info

func get_experience_rank() -> Dictionary:
	if _experience_defs == null:
		return {"display_name": "Unknown", "progress": 0.0, "next_rank": "Unknown"}
	var definitions: Array = []
	if typeof(_experience_defs) == TYPE_ARRAY:
		for entry in _experience_defs:
			if typeof(entry) == TYPE_DICTIONARY and entry.has("range"):
				definitions.append(entry)
	elif typeof(_experience_defs) == TYPE_DICTIONARY:
		for exp_level in _experience_defs:
			var exp_def = _experience_defs[exp_level]
			if typeof(exp_def) == TYPE_DICTIONARY and exp_def.has("range"):
				definitions.append(exp_def)
	for exp_def in definitions:
		if exp_def != null and exp_def.has("range"):
			var low = float(exp_def["range"][0])
			var high = float(exp_def["range"][1])
			if _experience >= low and _experience < high:
				var next_rank = _get_next_rank(exp_def)
				var progress = _calculate_progress(_experience, low, high)
				return {
					"display_name": str(exp_def.get("display_name", "Unknown")),
					"progress": progress,
					"next_rank": next_rank,
					"multiplier": float(exp_def.get("multiplier", 0.0))
				}
	return {"display_name": "Unknown", "progress": 0.0, "next_rank": "Unknown", "multiplier": 0.0}

func _get_next_rank(current_rank: Dictionary) -> String:
	var current_range = current_rank.get("range", [0.0, 1.0])
	var current_high = float(current_range[1])
	if _experience_defs == null:
		return "Unknown"
	var definitions: Array = []
	if typeof(_experience_defs) == TYPE_ARRAY:
		definitions = _experience_defs
	elif typeof(_experience_defs) == TYPE_DICTIONARY:
		for exp_level in _experience_defs:
			var exp_def = _experience_defs[exp_level]
			if typeof(exp_def) == TYPE_DICTIONARY and exp_def.has("range"):
				definitions.append(exp_def)
	for exp_def in definitions:
		if exp_def != null and exp_def.has("range"):
			var range_low = float(exp_def["range"][0])
			if range_low >= current_high:
				return str(exp_def.get("display_name", "Unknown"))
	return "Max Rank"

func _calculate_progress(current: float, low: float, high: float) -> float:
	var total_range = high - low
	if total_range <= 0:
		return 100.0
	var progress = current - low
	return clampf((progress / total_range) * 100.0, 0.0, 100.0)

func get_theme_sprite_path(sprite_path: String) -> String:
	if sprite_path.begins_with("res://"):
		return sprite_path
	if theme_mgr != null and theme_mgr.has_method("get_theme_base_path"):
		return theme_mgr.get_theme_base_path() + "/" + sprite_path
	var theme_name = theme_mgr.get_current_theme_name() if theme_mgr.has_method("get_current_theme_name") else ''
	return "res://themes/%s/%s" % [theme_name, sprite_path]

func _on_close_button_pressed() -> void:
	self.visible = false
	unit = null
