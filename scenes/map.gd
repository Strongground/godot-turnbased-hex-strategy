extends Node2D

# member vars here
var camera = null
var globals = null
var tiles = null
var hexmap = null

func _ready():
	set_fixed_process(true)
	set_process_input(true)
	camera = find_node("MainCamera")
	globals = get_node("/root/globals")
	hexmap = get_node("MapZones")
	print(hexmap)
	tiles = _create_tile_list(hexmap)

func _input(event):
	if event.type == 1:
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()

func _fixed_process(delta):
	pass
	
func _create_tile_list(tilemap):
	print(tilemap.get_used_cells())