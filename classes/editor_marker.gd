@tool
extends Entity

## public class members
@export var map_text = ""
@export_enum("SETTLEMENT", "VICTORY", "REINFORCEMENT") var marker_type: String = "SETTLEMENT"
var location_owner: int = -1

## internal class members go here
# icon to show in editor for this marker, helps the level designer
var icon = null
var hex_label_template = null
var village_icon = null
var reinforcements_icon = null
var victory_icon = null
# References to manager classes
@export var playerMgr: Node
@export var themeMgr: Node

func _ready():
	if Engine.is_editor_hint():
		return
	# Initialization here
	self.village_icon = load("res://assets/icons/editor_marker_city.png")
	self.reinforcements_icon = load("res://assets/icons/editor_marker_reinforcement.png")
	self.victory_icon = load("res://assets/icons/editor_marker_victory.png")
	self.type = 'editor_marker'
	self.hex_label_template = root.find_child('HexLabelTemplate', true, false)
	self.icon = find_child('Icon', true, false)
	# This entity can hold units
	set_container(true)
	# Call the base class ready function
	super._ready()

	# Finally hide the marker in-game
	self.icon.hide()
	$'OwnerIcon'.hide()

	# If map text is given and option to show it is "true", render it on the map
	if root.city_names_visible and map_text != null and map_text.length() > 0:
		self._create_map_text(map_text)

	# For victory markers, show colored outline
	if self.marker_type == 'VICTORY':
		$'hex_outline'.set_visible(true)
		$'hex_outline'.set_modulate(Color("ffa300ff"))
	# For reinforcement markers, show colored outline
	if self.marker_type == 'REINFORCEMENT':
		$'hex_outline'.set_visible(true)
		$'hex_outline'.set_modulate(Color("3b9125"))

	# Show owner icon
	$'OwnerIcon'.set_visible(true)

func initialize():
	if location_owner != -1:
		var faction_id = playerMgr.get_player_faction(location_owner)
		if faction_id:
			self.set_location_owner(location_owner)
			self._set_owner_icon(faction_id)

# Public getter for type of editor marker
func get_marker_type():
	return self.marker_type

func _create_map_text(text):
	var new_label = hex_label_template.duplicate()
	# set text
	new_label.text = "[center]" + str(text) + "[/center]"
	# set position
	new_label.set_position(Vector2(
		self.get_position().x - (new_label.get_size().x / 2),
		self.get_position().y - 60
	))
	# add to scene
	root.call_deferred('add_child', new_label)

func set_location_owner(owner_id: int) -> bool:
	if playerMgr.get_player_by_id(owner_id):
		self.location_owner = owner_id
		return true
	return false

func check_ownership():
	var overlapping_entities = self.get_overlapping_areas()
	if overlapping_entities.size() > 0:
		for checking_entity in overlapping_entities:
			if checking_entity.type == 'entity':
				self.set_location_owner(checking_entity.get_owner_id())
				self._set_owner_icon(checking_entity.get_faction())

func _set_owner_icon(owner_faction):
	var faction_icon = themeMgr.get_faction_icon(owner_faction)
	$OwnerIcon/FlagSin.texture = faction_icon

# --- Dynamic inspector dropdown for location_owner ---

func _get_property_list() -> Array:
	return [{
		"name": "location_owner",
		"type": TYPE_INT,
		"usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": _build_owner_enum_hint()
	}]

func _build_owner_enum_hint() -> String:
	var entries = ["Neutral:-1"]
	var scene_root = get_tree().get_edited_scene_root() if Engine.is_editor_hint() else get_tree().current_scene
	if scene_root == null:
		return ",".join(entries)
	var theme = _get_theme_from_path(scene_root.scene_file_path)
	if theme == "":
		return ",".join(entries)
	var scenario_key = scene_root.scene_file_path.get_file().get_basename()
	var scenarios = _read_json_file("res://themes/" + theme + "/scenarios.json")
	if scenarios == null or not scenarios.has(scenario_key):
		return ",".join(entries)
	var factions = _read_json_file("res://themes/" + theme + "/factions.json")
	for player in scenarios[scenario_key].get("players", []):
		var player_id = player.get("id", -1)
		if player_id < 0:
			continue
		var label: String = player.get("name", "Player " + str(player_id))
		var faction_id: String = player.get("factionID", "")
		if factions != null and factions.has(faction_id):
			label += " (" + factions[faction_id].get("display_name", faction_id) + ")"
		entries.append(label + ":" + str(player_id))
	return ",".join(entries)

func _get_theme_from_path(scene_path: String) -> String:
	var parts: PackedStringArray = scene_path.split("/")
	var idx = parts.find("themes")
	if idx < 0 or idx + 1 >= parts.size():
		return ""
	return parts[idx + 1]

func _read_json_file(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path):
		return null
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return null
	var result = JSON.parse_string(file.get_as_text())
	file.close()
	return result
