extends "res://classes/entity.gd"

## public class members
export var map_text = ""
export (String, "VILLAGE", "VICTORY", "REINFORCEMENT") var marker_type

## internal class members go here
# icon to show in editor for this marker, helps the level designer
var icon = null
var hex_label_template = null
var village_icon = null
var reinforcements_icon = null
var victory_icon = null

func _ready():
	# Initialization here
	village_icon = load("res://assets/icons/editor_marker_city.png")
	reinforcements_icon = load("res://assets/icons/editor_marker_reinforcement.png")
	victory_icon = load("res://assets/icons/editor_marker_victory.png")
	type = 'editor_marker'
	hex_label_template = root.find_node('HexLabelTemplate')
	icon = find_node('Icon')
	# If map text is given and option to show it, is "true", render it on the map
	if root.city_names_visible && map_text.length() > 0:
		self._create_map_text(map_text)
	
	### Icon handling
	# Finally hide the marker in-game
	self.icon.hide()

func _create_map_text(text):
	var new_label = hex_label_template.duplicate()
	# set text
	new_label.set_bbcode(text)
	# set position
	new_label.set_position(Vector2(
		self.get_position().x - ((hexmap.get_cell_size().x / 2) + 10) - (new_label.get_text().length() * 7),
		self.get_position().y - hexmap.get_cell_size().y
	))
	# add to scene
	root.call_deferred('add_child', new_label)