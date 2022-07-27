extends "res://classes/entity.gd"

## public class members
export var map_text = ""
export (String, "VILLAGE", "VICTORY", "REINFORCEMENT") var marker_type
export (String) var location_owner = null

## internal class members go here
# icon to show in editor for this marker, helps the level designer
var icon = null
var hex_label_template = null
var village_icon = null
var reinforcements_icon = null
var victory_icon = null
# References to manager classes
onready var playerMgr =  $'/root/Game/PlayerManager'
onready var themeMgr =  $'/root/Game/ThemeManager'

func _ready():
	# Initialization here
	self.village_icon = load("res://assets/icons/editor_marker_city.png")
	self.reinforcements_icon = load("res://assets/icons/editor_marker_reinforcement.png")
	self.victory_icon = load("res://assets/icons/editor_marker_victory.png")
	self.type = 'editor_marker'
	self.hex_label_template = root.find_node('HexLabelTemplate')
	self.icon = find_node('Icon')
	set_container(true)
	
	# Finally hide the marker in-game
	self.icon.hide()
	$'OwnerIcon'.hide()
	
	# If map text is given and option to show it, is "true", render it on the map
	if root.city_names_visible && map_text.length() > 0:
		self._create_map_text(map_text)
	
	# For victory markers, show outline
	if self.marker_type == 'VICTORY':
		$'hex_outline'.set_visible(true)
	# For reinforcement markers, show different outline
	if self.marker_type == 'REINFORCEMENT':
		$'hex_outline'.set_visible(true)
		$'hex_outline'.set_modulate(Color("3b9125"))
	
	# Show owner icon
	$'OwnerIcon'.set_visible(true)


func initialize():
	if location_owner:
		var faction_id = playerMgr.get_player_faction(location_owner)
		if faction_id:
			self.set_owner(location_owner)
			self._set_owner_icon(faction_id)

# Public getter for type of editor marker
func get_marker_type():
	return self.marker_type

func _create_map_text(text):
	var new_label = hex_label_template.duplicate()
	# set text
	new_label.set_bbcode("[center]"+String(text)+"[/center]")
	# set position
	new_label.set_position(Vector2(
		self.get_position().x - (new_label.get_size().x / 2),
		self.get_position().y - 60
	))
	# add to scene
	root.call_deferred('add_child', new_label)

func set_owner(id):
	if playerMgr.get_player_by_id(id):
		self.location_owner = id
		return true
	return false

func check_ownership():
	var overlapping_entities = self.get_overlapping_areas()
	if overlapping_entities.size() > 0:
		for entity in overlapping_entities:
			if entity.type == 'unit':
				self.set_owner(entity.get_owner())
				self._set_owner_icon(entity.get_faction())

func _set_owner_icon(owner_faction):
	var faction_icon = themeMgr.get_faction_icon(owner_faction)
	$OwnerIcon/FlagSin.set_texture(faction_icon)
