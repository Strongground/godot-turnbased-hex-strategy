extends Area2D
class_name entity
### public class member vars
# is selectable by player
export (bool) var selectable = null

### internal class member variables
onready var root = get_tree().get_current_scene()
onready var game = $"/root/Game"
onready var hex_outline = find_node("HexOutline")
onready var hexmap = root.find_node("MapZones")
onready var red_dot = root.find_node("RedDot") #Debug
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
		print("EDITOR!!!")
		# This is only executed in editor
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

# Getter for state of selection
func is_selected():
	return self.selected
	
# Deselect this entity
func deselect():
	self.selected = false
	self._hide_marker()
	if root.selected_unit != null:
		root.selected_unit = null

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
func set_path(path_array):
	self.path = path_array
	
# Getter for path array
func get_path():
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
	var grid_coords = hexmap.world_to_map(self.get_global_position())
	var world_coords = _get_centered_grid_pos(grid_coords, Vector2(-6,0))
	self.set_position(world_coords)

# Internal helper function that returns the centered coordinates corrected
# by given offset
# @input {Vector2} grid coordinates of a hex
# @input {Vector2} offset, this can depend on entity type
# @returns {Vector2} global coordinates that represent the center of a hex
func _get_centered_grid_pos(grid_coords, offset):
	var world_coords = hexmap.map_to_world(grid_coords)
	world_coords.x += ((hexmap.get_cell_size().x/2) + offset.x)
	world_coords.y += ((hexmap.get_cell_size().y/2) + offset.y)
	return world_coords
