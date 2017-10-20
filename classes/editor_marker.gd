extends "res://classes/entity.gd"

## public class members
export var map_text = ""
export (String, "VILLAGE", "VICTORY", "REINFORCEMENT") var type = null

## internal class member go here
# icon to show in editor for this marker, helps the level designer
var icon = null
var hex_label_template = null

func _ready():
	# Initialization here
	hex_label_template = root.find_node('HexLabelTemplate')
	icon = find_node('Icon')
	# If map text is given, render it on the map
	if map_text.length() > 0:
		self.create_map_text(map_text)
	# Finally hide the marker in-game
	self.icon.set_opacity(0)

func create_map_text(text):
	var new_label = hex_label_template.duplicate()
	# set text
	new_label.set_bbcode(text)
	# set position
	new_label.set_pos(Vector2(
		self.get_pos().x - ((hexmap.get_cell_size().x / 2) - 20) - (new_label.get_text().length() * 7),
		self.get_pos().y - hexmap.get_cell_size().y + 20
	))
	# add to scene
	# new_label.set_opacity(0)
	root.call_deferred('add_child',new_label)