extends Area2D
### public class member vars
# none yet

### internal class member variables
var root = null
var selectable  = null
var selected = null
var hex_outline = null
var hexmap = null
var offset = null
var red_dot = null

## Called every time the node is added to the scene.
func _ready():
	set_fixed_process(true)
	set_process_input(true)
	# Default any entity to be selectable, override where necessary
	self.selectable = true
	# self.offset_x = -25.0
	self.offset = Vector2(-27.0, 9)
	# Get necessary siblings
	root = get_tree().get_current_scene()
	hex_outline = find_node("hex_outline")
	# @TODO Maybe get active map scene later, to get correct hex? Maybe let map be generic and have member "active"?
	hexmap = root.find_node('MapZones')
	red_dot = root.find_node('RedDot')
	# Default function calls
	self._deselect()
	self.snap_to_grid()

func _input_event(viewport, event, shape_idx):
	# if selectable, attempt to select
	if event.type == InputEvent.MOUSE_BUTTON and event.button_index == BUTTON_LEFT and event.pressed:
		if self.is_selectable() and not self.is_selected():
			self._select()
		
# Snap entity to the next suitable hex-tile
func snap_to_grid():
	var grid_coords = hexmap.world_to_map(self.get_global_pos())
	var world_coords = hexmap.map_to_world(grid_coords)
	# red_dot.set_pos(world_coords)
	world_coords += self.offset
	self.set_pos(world_coords)

# Getter for selectable
func is_selectable():
	return self.selectable

# Getter for state of selection
func is_selected():
	return self.selected

func _select():
	# deselect every other entity first
	for node in root.get_children():
		if node.has_method('is_selected') and node.is_selected():
			node._deselect()
	# now select this entity
	self.selected = true
	self._show_marker('red')
	
func _deselect():
	self.selected = false
	self._hide_marker()
		
func _show_marker(color):
	# show hex outline, color must be array of rgb values
	# possibly replace this with global pre-defined colors
	color = globals.getColor(color)
	hex_outline.set_modulate(Color(color[0], color[1], color[2]))
	hex_outline.set_opacity(1)
	
func _hide_marker():
	# hide any visible marker
	hex_outline.set_opacity(0)
	