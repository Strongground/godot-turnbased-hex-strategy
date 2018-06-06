extends Container

var camera = null
var game = null
var tile_info_popup = null
var tile_info_popup_text = null
var move_button = null
var panel = null
var panel_pos = null
var panel_size = null
var panel_area = null
var gui_elements = null

# Public helper function to check mouse local position against GUI elements
# @input {Vector2} The position of the mouse to check against
# @input {Node} The node that is checked for overlap
# @returns {Boolean} true if the mouse position is over a GUI element 
func is_gui_clicked():
	# @TODO Add list of all gui elements to iterate
	# for element in get_all_gui_elements():
	var click_pos = get_local_mouse_position()
	var inside_gui = true
	panel_pos = self.panel.rect_position
	panel_size = self.panel.get_size()
	print('click_pos: '+str(click_pos))
	print('panel_pos: '+str(panel_pos))
	print('panel_size: '+str(panel_size))
	return inside_gui

# Private getter for all elements in the current root, that are visible 
# and are descendants of GUI class
func get_all_gui_elements():
	var elements = null
	return elements
	
# Public setter for disabled state of move button
# @input {Boolean} true for disabled, false for enabled
func disable_movement_button(disabled):
	move_button.set_disabled(disabled)

# Init
func _ready():
	camera = get_parent()
	game = get_tree().get_current_scene()
	tile_info_popup = camera.find_node('Tile_Info')
	tile_info_popup_text = tile_info_popup.find_node('Tile_Text')
	move_button = find_node('MoveButton')
	##### Panel
	panel = find_node('Panel')

# Show a popup window with information about the selected tile
# @input {Object} the tile object which information should be shown
func _show_tile_info_popup(tile_object):
	var popup_pos = camera.get_screen_center()
	popup_pos = Vector2(
		popup_pos.x,
		popup_pos.y - self.get_size().y
	)
	tile_info_popup.set_position(popup_pos)
	tile_info_popup_text.set_text(String(tile_object))
	tile_info_popup.popup()

func _process(delta):
	var popup_pos = camera.get_screen_center()
	tile_info_popup.set_position(popup_pos)

# If MoveButton in GUI pressed, and a unit is selected,
# set movement selection
func _on_MoveButton_pressed():
	if game.selected_unit != null:
		game.movement_selection = true