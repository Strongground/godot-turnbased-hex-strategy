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
	self.village_icon = load("res://assets/icons/editor_marker_city.png")
	self.reinforcements_icon = load("res://assets/icons/editor_marker_reinforcement.png")
	self.victory_icon = load("res://assets/icons/editor_marker_victory.png")
	self.type = 'editor_marker'
	self.hex_label_template = root.find_node('HexLabelTemplate')
	self.icon = find_node('Icon')
	set_container(true)
	# If map text is given and option to show it, is "true", render it on the map
	if root.city_names_visible && map_text.length() > 0:
		self._create_map_text(map_text)
	
	# Finally hide the marker in-game
	self.icon.hide()

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
