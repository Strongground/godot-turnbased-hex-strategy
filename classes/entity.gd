extends Area2D
class_name entity
### public class member vars
# is selectable by player
@export var selectable = null

### internal class member variables
@onready var root = get_tree().current_scene
@onready var game = $"/root/Game"
@onready var globals = get_node("/root/globals")
@onready var hex_outline = find_child("HexOutline", true, false)
@onready var hexmap = root.find_child("MapZones", true, false)
@onready var red_dot = root.find_child("RedDot", true, false) #Debug
var selected = null
var type = null
var path = null
var id = null
var container = null

## Called every time the node is added to the scene.
func _ready():
	self._snap_to_grid()

func _physics_process(_delta):
	if Engine.is_editor_hint():
		self._snap_to_grid()

func initialize():
	pass

# Getter for if this entity is selectable
func is_selectable():
	return self.selectable

# Setter for selectable attribute. Necessary for child classes.
func set_selectable(value):
	self.selectable = bool(value)

# Select this entity
func select():
	if self.selectable:
		# deselect every other entity first
		root.deselect_all_entities()
		# now select this entity
		self.selected = true
		self._show_marker('red')
		root.selected_unit = self.id
		# Call virtual handler for selection
		_on_selected()

# Getter for state of selection
func is_selected():
	return self.selected
	
# Deselect this entity
func deselect():
	self.selected = false
	self._hide_marker()
	if root.selected_unit != null:
		root.selected_unit = null
	# Call virtual handler for de-select
	_on_deselected()

# Setter to check if entity can be a container of other units (towns, markers)
func set_container(value):
	self.container = value

# Getter to check if entity can be a container of other units (towns, markers)
func is_container():
	return self.container

# Getter for type
func get_type():
	return self.type

# Setter for path array
func set_move_path(path_array):
	self.path = path_array
	
# Getter for path array
func get_move_path():
	return self.path

# Setter for id
func set_id(new_id):
	self.id = new_id

# Internal helper functions
func _show_marker(color):
	# show hex outline, color must be string representation of common color name
	$HexOutline.set_modulate(globals.getColor(color))
	$HexOutline.show()

# hide any visible marker
func _hide_marker():
	$HexOutline.hide()

# Snap entity to the next suitable hex-tile
func _snap_to_grid():
	var grid_coords = hexmap.global_to_map(self.get_global_position())
	var world_coords = _get_centered_grid_pos(grid_coords, Vector2(-6,0))
	self.set_position(world_coords)

# Internal helper function that returns the centered coordinates corrected
# by given offset
# @input {Vector2} grid coordinates of a hex
# @input {Vector2} offset, this can depend on entity type
# @returns {Vector2} global coordinates that represent the center of a hex
func _get_centered_grid_pos(grid_coords, offset):
	var world_coords = hexmap.map_to_global(Vector2i(grid_coords))
	var center_coords = root.get_center_of_hex(world_coords)
	center_coords.x += offset.x
	center_coords.y += offset.y
	return center_coords

# Base implementation is currently empty but must exist so derived classes can
# overwrite
func _on_selected():
	pass
	
# Base implementation is currently empty but must exist so derived classes can
# overwrite
func _on_deselected():
	pass
