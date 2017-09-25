extends Node2D

# member vars here
var camera = null
var globals = null
var tiles = null
var hexmap = null
var tile = null

func _ready():
	set_fixed_process(true)
	set_process_input(true)
	camera = find_node("MainCamera")
	globals = get_node("/root/globals")
	hexmap = get_node("MapZones")
	tiles = _create_tile_list(hexmap)

func _input(event):
	if event.type == InputEvent.KEY:
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()
	elif event.type == InputEvent.MOUSE_BUTTON:
		print("Got Tile "+String(self.get_tile(event.pos))+" at position "+String(event.pos))

func _fixed_process(delta):
	pass
	
func _create_tile_list(tilemap):
	var myfile = File.new()
	print('Start exporting tiles')
	myfile.open("res://tiles.txt", 3)
	myfile.store_string(String(tilemap.get_used_cells()))
	myfile.close()
	print('Done storing')

func get_tile(world_position):
	var grid_pos = hexmap.world_to_map(world_position)
	var tile = {
		'index': hexmap.get_cell(grid_pos.x, grid_pos.y),
		'attributes': hexmap._get_tile_type_by_index(hexmap.get_cell(grid_pos.x, grid_pos.y)),
		'position': grid_pos
	}
	return tile