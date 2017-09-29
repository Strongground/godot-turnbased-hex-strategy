extends Node2D

# member vars here
var camera = null
var globals = null
var tiles = null
var hexmap = null
var marker = null
var root = null
var hex_marker = null
var counter = 0
var mouse_pos_ui = null
var camera_pos_ui = null

func _ready():
	set_fixed_process(true)
	set_process_input(true)
	camera = find_node("MainCamera")
	globals = get_node("/root/globals")
	hexmap = get_node("MapZones")
	marker = get_node("RedDot")
	root = get_node("/root")
	hex_marker = find_node("HexMarker")
	mouse_pos_ui = find_node("MousePos")
	camera_pos_ui = find_node("CameraPos")
	# array_tiles = self.build_array_of_tiles()
	# Call functions for every hex based on grid based coordinates array
	# self.for_every_hex(array_tiles)

func _input(event):
	if event.type == InputEvent.KEY:
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()
	elif event.is_action_pressed('mouse_click'):
		# Once set the actual global mouse position needed for conversion of the coordinates
		var click_pos = self.get_global_mouse_pos()
	
		# Sets a red dot at event position
		# marker.set_pos(self.get_global_mouse_pos())
		
		# Print out infos about the tile under event position
		print("Got Tile "+String(self.get_tile(click_pos)))
		
		# Display information directly on top of the selected hex (position in different relations)
		self.highlight_hex(click_pos)
		
		# try to mark the outer dimensions (via four edges) of the selected hexagon
		# based on double conversion of event.pos coordinates.
		# self.mark_hex_dimensions(self.get_global_mouse_pos())

func _fixed_process(delta):
	pass
# For every grid-coordinate in hexmap, do the following 
func for_every_hex(tile_coords):
	for tile in tile_coords:
		counter += 1
		# var grid_position = Vector2(tile_x, tile_y)
		# var global_position = hexmap.map_to_world(grid_position)
		# self.mark_hex_dimensions(global_position)
		self.display_hex_id(tile_coords[0], tile_coords[1])

func build_array_of_tiles():
	var tiles = Array()
	var i = 0
	for tile_x in range(-3, 26):
		for tile_y in range(-7, 10):
			tiles[i] = [tile_x, tile_y]
			i += 1
	return tiles

# Debug method to write every tile and its tilemap index into a file for checking
func create_tile_list(tilemap):
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
	
# Debug method to draw coordinates and a outline of a tile to highlight it
func highlight_hex(position):
	# get coordinates of hexagon in grid from global pixel coordinates
	var hex_position = hexmap.world_to_map(position)
	# get global coordinates of hexagon based on grid local coordinates
	var hex_world_pos = hexmap.map_to_world(hex_position)
	# Draw some infos on the tile
	var new_highlight = hex_marker.duplicate()
	var global_pos_label = Label.new()
	var grid_pos_label = Label.new()
	print("CellSize: "+String(hexmap.get_cell_size()))
	var highlight_pos = hexmap.get_cell_size() + hex_world_pos
	new_highlight.set_pos(highlight_pos)
	global_pos_label.set_text(String(hex_world_pos))
	global_pos_label.set_pos(hex_world_pos)
	grid_pos_label.set_text(String(hex_position))
	var grid_pos_label_pos = Vector2(hex_world_pos.x, hex_world_pos.y+20)
	grid_pos_label.set_pos(grid_pos_label_pos)
	self.add_child(new_highlight)
	self.add_child(global_pos_label)
	self.add_child(grid_pos_label)
	new_highlight.set_owner(get_tree().get_edited_scene_root())
	global_pos_label.set_owner(get_tree().get_edited_scene_root())
	grid_pos_label.set_owner(get_tree().get_edited_scene_root())

# Tries to mark the dimensions of the hex tile based on hexmap based coordinates with dots
# @input Vector2
func mark_hex_dimensions(position=null):
	var grid_pos = hexmap.world_to_map(position)
	var global_pos = hexmap.map_to_world(grid_pos)
	var hex_size = hexmap.get_cell_size()
	var marker1 = marker.duplicate()
	var marker2 = marker.duplicate()
	var marker3 = marker.duplicate()
	var marker4 = marker.duplicate()
	# 0,0
	marker1.set_pos(global_pos)
	# 110,0
	var pos2 = Vector2(global_pos.x+hex_size.x, global_pos.y)
	marker2.set_pos(pos2)
	# 110,128
	var pos3 = global_pos+hex_size
	marker3.set_pos(pos3)
	# 0,128
	var pos4 = Vector2(global_pos.x+hex_size.x, global_pos.y+hex_size.y)
	marker4.set_pos(pos4)
	self.add_child(marker1)
	self.add_child(marker2)
	self.add_child(marker3)
	self.add_child(marker4)
	marker1.set_owner(get_tree().get_edited_scene_root())
	marker2.set_owner(get_tree().get_edited_scene_root())
	marker3.set_owner(get_tree().get_edited_scene_root())
	marker4.set_owner(get_tree().get_edited_scene_root())

# Display ID for hex tile at grid-based coordinates tile_x and tile_y
# Overlay the information onto the tile itself
# @input Float
func display_hex_id(tile_x, tile_y):
	var tile_world_pos = null
	# print("["+String(tile_x)+","+String(tile_y)+"]")
	tile_world_pos = hexmap.map_to_world(Vector2(tile_x, tile_y))
	# print("tile_world_pos set: "+String(tile_world_pos))
	# self.draw_circle(tile_world_pos, hexmap.get_cell_size().x, Color(globals.getColor('red')[0],globals.getColor('red')[1], globals.getColor('red')[2]))
	var new_label = Label.new()
	new_label.set_text(String(tile_world_pos))
	new_label.set_pos(tile_world_pos)
	self.add_child(new_label)
	new_label.set_owner(get_tree().get_edited_scene_root())
