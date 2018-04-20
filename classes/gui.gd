extends Container

var camera = null
var root = null
var tile_info_popup = null
var tile_info_popup_text = null
var move_button = null
var panel = null
var panel_pos = null
var panel_size = null
var panel_area = null

# Public helper function to check mouse local position against GUI elements
# @TODO enhance this for other GUI elements, currently only checking against
# the main menu bar/panel
# @returns {Boolean} true if the mouse position is over a GUI element 
func is_gui_clicked():
	var click_pos = get_viewport().get_mouse_position()
	var panel_pos_y = panel_pos.y
	var viewport_size_y = get_viewport().size.y
	var panel_top_border_begin = get_viewport().size.y - panel_pos.y
	print('Click inside GUI: '+String(click_pos.y > panel_top_border_begin))
	return click_pos.y > panel_top_border_begin
	
# Public setter for disabled state of move button
# @input {Boolean} true for disabled, false for enabled
func disable_movement_button(disabled):
	move_button.set_disabled(disabled)

# Init
func _ready():
	set_process_input(true)
	camera = get_parent()
	root = get_tree().get_current_scene()
	tile_info_popup = camera.find_node('Tile_Info')
	tile_info_popup_text = tile_info_popup.find_node('Tile_Text')
	move_button = find_node('MoveButton')
	##### Panel
	panel = find_node('Panel')
	panel_pos = self.panel.get_transform()
	panel_pos = self.panel.rect_position
	panel_size = self.panel.get_size()

# Handle input
func _input_event(viewport, event, shape_idx):
	if event.type == InputEvent.MOUSE_BUTTON and event.button_index == BUTTON_LEFT and event.pressed:
		pass
	
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

func _physics_process(delta):
	var popup_pos = camera.get_screen_center()
	tile_info_popup.set_position(popup_pos)

# If MoveButton in GUI pressed, and a unit is selected,
# set movement selection
func _on_MoveButton_pressed():
	if root.selected_unit != null:
		root.movement_selection = true