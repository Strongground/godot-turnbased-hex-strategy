@tool
extends EditorScript

const THEME_NAME := "example"
const UNIT_SCRIPT_PATH := "res://classes/hexUnit.gd"
const SKIP_KEYS := {
	"unit_faction": true,
	"unit_owner": true,
	"graphical_scheme": true
}

func _run():
	var scene_root = get_editor_interface().get_edited_scene_root()
	if scene_root == null:
		push_error("No edited scene open. Open a map scene and run this script again.")
		return

	var unit_defs = _load_unit_definitions(THEME_NAME)
	if unit_defs.is_empty():
		push_error("No hexUnit definitions loaded from theme '%s'." % THEME_NAME)
		return

	var unit_nodes = _find_unit_nodes(scene_root)
	var changed_units = 0
	var missing_faction_units = 0
	var unknown_unit_ids = 0

	for unit_node in unit_nodes:
		var unit_id = str(unit_node.get("unit_id"))
		if unit_id == "":
			unknown_unit_ids += 1
			push_warning("%s has no unit_id set." % unit_node.get_path())
			continue
		if not unit_defs.has(unit_id):
			unknown_unit_ids += 1
			push_warning("%s uses unknown unit_id '%s' for theme '%s'." % [unit_node.get_path(), unit_id, THEME_NAME])
			continue

		var unit_data = unit_defs[unit_id]
		if _apply_theme_defaults(unit_node, unit_data):
			changed_units += 1

		if str(unit_node.get("unit_faction")) == "":
			missing_faction_units += 1
			push_warning("%s has empty unit_faction. Set it manually in the inspector." % unit_node.get_path())

	print("Applied hexUnit theme defaults for scene: ", scene_root.name)
	print("Units inspected: ", unit_nodes.size())
	print("Units changed: ", changed_units)
	print("Units with empty unit_faction: ", missing_faction_units)
	print("Units with missing/unknown unit_id: ", unknown_unit_ids)

func _load_unit_definitions(theme_name: String) -> Dictionary:
	var path = "res://themes/%s/units.json" % theme_name
	if not FileAccess.file_exists(path):
		push_error("Theme units file missing: " + path)
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Could not open theme units file: " + path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Invalid JSON format in " + path)
		return {}
	return parsed

func _find_unit_nodes(root: Node) -> Array:
	var results: Array = []
	for node in root.find_children("*", "", true, false):
		var script: Script = node.get_script() as Script
		if script != null and script.resource_path == UNIT_SCRIPT_PATH:
			results.append(node)
	return results

func _apply_theme_defaults(unit_node: Node, unit_data: Dictionary) -> bool:
	var changed = false
	for key in unit_data.keys():
		var property_name = str(key)
		if SKIP_KEYS.has(property_name):
			continue
		if not _has_property(unit_node, property_name):
			continue
		var current_value = unit_node.get(property_name)
		if _is_unset(current_value):
			unit_node.set(property_name, unit_data[property_name])
			changed = true
	return changed

func _has_property(target: Object, property_name: String) -> bool:
	for prop in target.get_property_list():
		if str(prop.name) == property_name:
			return true
	return false

func _is_unset(value) -> bool:
	if value == null:
		return true
	if value is String and value == "":
		return true
	if value is Array and value.is_empty():
		return true
	if value is Dictionary and value.is_empty():
		return true
	return false
