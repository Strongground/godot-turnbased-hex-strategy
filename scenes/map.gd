extends Node2D

# member vars here
var camera = null
var globals = null
var tiles = null
var hexmap = null
var marker = null
var root = null
var hex_marker = null

func _ready():
	set_fixed_process(true)
	set_process_input(true)
	camera = find_node("MainCamera")
	globals = get_node("/root/globals")
	hexmap = get_node("MapZones")
	marker = get_node("RedDot")
	root = get_node("/root")
	hex_marker = find_node("HexMarker")
	self.display_hex_id()

func _input(event):
	if event.type == InputEvent.KEY:
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()
	elif event.type == InputEvent.MOUSE_BUTTON:
		marker.set_pos(event.pos)
		print("Got Tile "+String(self.get_tile(event.pos))+" at position "+String(event.pos))
		self.highlight_hex(event.pos)

func _fixed_process(delta):
	pass
	
# Debug method to write every tile and its tilemap index into a file for checking
func _create_tile_list(tilemap):
	var myfile = File.new()
	print('Start exporting tiles')
	myfile.open("res://tiles.txt", 3)
	myfile.store_string(String(tilemap.get_used_cells()))
	myfile.close()
	print('Done storing')

# Debug method to return a tiles attributes as defined in tilemap.gd
func get_tile(world_position):
	# Calculate grid position from world position
	var grid_pos = hexmap.world_to_map(world_position)
	# Get tile attributes based on tileset index
	var tile = hexmap._get_tile_type_by_index(hexmap.get_cell(grid_pos.x, grid_pos.y))
	# Enrich the returned tile object for debugging purposes
	tile.index = hexmap.get_cell(grid_pos.x, grid_pos.y)
	tile.position = grid_pos
	return tile
	
# Debug method to draw around the region of a tile to highlight it
func highlight_hex(position):
	# get hexagon from world_position
	var hex_position = hexmap.world_to_map(position)
	var hex_world_pos = hexmap.map_to_world(hex_position)
	var new_highlight = hex_marker.duplicate()
	new_highlight.set_pos(hex_world_pos)
	self.add_child(new_highlight)
	new_highlight.set_owner(get_tree().get_edited_scene_root())

func display_hex_id():
	var tile_world_pos = null
	for tile_x in range(-3, 26):
		for tile_y in range(-7, 10):
			# print("["+String(tile_x)+","+String(tile_y)+"]")
			tile_world_pos = hexmap.map_to_world(Vector2(tile_x, tile_y))
			# print("tile_world_pos set: "+String(tile_world_pos))
			# self.draw_circle(tile_world_pos, hexmap.get_cell_size().x, Color(globals.getColor('red')[0],globals.getColor('red')[1], globals.getColor('red')[2]))
			var new_label = Label.new()
			new_label.set_text(String(tile_world_pos))
			new_label.set_pos(tile_world_pos)
			self.add_child(new_label)
			new_label.set_owner(get_tree().get_edited_scene_root())
			## Highlight each hex tile
			var new_highlight = hex_marker.duplicate()
			new_highlight.set_pos(tile_world_pos)
			self.add_child(new_highlight)
			new_highlight.set_owner(get_tree().get_edited_scene_root())