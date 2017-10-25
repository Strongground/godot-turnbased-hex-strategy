extends Container

var camera = null
var root = null
var tile_info_popup = null
var tile_info_popup_text = null
var dot_marker = null

func _ready():
	set_fixed_process(true)
	set_process_input(true)
	camera = get_parent()
	root = get_node('/root')
	tile_info_popup = camera.find_node('Tile_Info')
	tile_info_popup_text = tile_info_popup.find_node('Tile_Text')
	dot_marker = find_node('RedDot')
	
# Show a popup window with information about the selected tile
# @input {Object} the tile object which information should be shown
func _show_tile_info_popup(tile_object):
	var popup_pos = camera.get_screen_center()
	popup_pos = Vector2(
		popup_pos.x,
		popup_pos.y - self.get_size().y
	)
	tile_info_popup.set_pos(popup_pos)
	tile_info_popup_text.set_text(String(tile_object))
	tile_info_popup.popup()

func _fixed_process(delta):
	var popup_pos = camera.get_screen_center()
	tile_info_popup.set_pos(popup_pos)