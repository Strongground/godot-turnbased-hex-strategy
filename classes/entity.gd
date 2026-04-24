## Base class for all entities in the game. This includes units, towns, markers, and more.
class_name Entity extends Area2D

### public class member vars
# is selectable by player
@export var selectable: bool = false

# Unique id for referencing in scenario win conditions or other scripted
# events. This is not required to be unique by the game, but it is recommended.
@export var unique_id: String = ''

### internal class member variables
@onready var root = get_tree().current_scene
@export var game: Node
@export var globals: Node
@onready var hex_outline = find_child("HexOutline", true, false)
@onready var hexmap = root.find_child("MapZones", true, false)
var selected: bool = false
var type: String = ''
var path: Array = []
var id: int
var container: bool = false

## Called every time the node is added to the scene.
func _ready():
	if Engine.is_editor_hint():
		self._snap_to_grid()
		return
	_connect_runtime_snap()

func _physics_process(_delta):
	if Engine.is_editor_hint():
		self._snap_to_grid()
		return

func initialize():
	pass

func _connect_runtime_snap():
	if game == null:
		game = get_tree().current_scene
	if game != null and game.has_method("is_setup_complete") and game.is_setup_complete():
		self._snap_to_grid()
		return
	if game != null and game.has_signal("setup_complete"):
		var snap_callback = Callable(self, "_on_game_setup_complete")
		if not game.setup_complete.is_connected(snap_callback):
			game.setup_complete.connect(snap_callback, CONNECT_ONE_SHOT)

func _on_game_setup_complete():
	self._snap_to_grid()

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
	if hexmap == null or root == null:
		return
	var grid_coords = hexmap.global_to_map(self.get_global_position())
	var world_coords = _get_centered_grid_pos(grid_coords, Vector2(0,0))
	if world_coords == null:
		return
	self.set_position(world_coords)

# Internal helper function that returns the centered coordinates corrected
# by given offset
# @input {Vector2} grid coordinates of a hex
# @input {Vector2} offset, this can depend on entity type
# @returns {Vector2} global coordinates that represent the center of a hex
func _get_centered_grid_pos(grid_coords, offset):
	if hexmap == null or root == null:
		return null
	var world_coords = hexmap.map_to_global(Vector2i(grid_coords))
	var center_coords = root.get_center_of_hex(world_coords)
	if center_coords == null:
		return null
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
