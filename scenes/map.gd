extends Node2D

# General thougt on this class:
# The map class should serve as a parent class from which all maps in the game inherit
# general comfort functions to select hexes and display information about hexes (highlighting,
# showing of terrain information etc.)
# It may later also contain information on the goals of the map such as victory hexes and 
# offer methods to get state of these goals (as long as they are hex based).
#
# This class should be used as parent for the map/game scene. The game scene will then be
# filled with the necessary entities either by hand (level editing in Godot) or automatically
# (procedurally generated levels?)

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
var tile_list = null
var hex_offset = null
var current_tile = null

func _ready():
	set_fixed_process(true)
	set_process_input(true)
	camera = find_node('MainCamera')
	root = get_node('/root')
	globals = get_node('/root/globals')
	hexmap = get_node('MapZones')
	marker = get_node('RedDot')
	hex_marker = find_node('HexMarker')
	mouse_pos_ui = find_node('MousePos')
	camera_pos_ui = find_node('CameraPos')
	hex_offset = Vector2(-6,0)
	tile_list = [
		[-3, -7],
		[-1, -7],
		[1, -7],
		[3, -7],
		[5, -7],
		[7, -7],
		[9, -7],
		[11, -7],
		[13, -7],
		[15, -7],
		[17, -7],
		[19, -7],
		[21, -7],
		[23, -7],
		[25, -7],
		[-3, -6],
		[-2, -6],
		[-1, -6],
		[0, -6],
		[1, -6],
		[2, -6],
		[3, -6],
		[4, -6],
		[5, -6],
		[6, -6],
		[7, -6],
		[8, -6],
		[9, -6],
		[10, -6],
		[11, -6],
		[12, -6],
		[13, -6],
		[14, -6],
		[15, -6],
		[16, -6],
		[17, -6],
		[18, -6],
		[19, -6],
		[20, -6],
		[21, -6],
		[22, -6],
		[23, -6],
		[24, -6],
		[25, -6],
		[-3, -5],
		[-2, -5],
		[-1, -5],
		[0, -5],
		[1, -5],
		[2, -5],
		[3, -5],
		[4, -5],
		[5, -5],
		[6, -5],
		[7, -5],
		[8, -5],
		[9, -5],
		[10, -5],
		[11, -5],
		[12, -5],
		[13, -5],
		[14, -5],
		[15, -5],
		[16, -5],
		[17, -5],
		[18, -5],
		[19, -5],
		[20, -5],
		[21, -5],
		[22, -5],
		[23, -5],
		[24, -5],
		[25, -5],
		[-3, -4],
		[-2, -4],
		[-1, -4],
		[0, -4],
		[1, -4],
		[2, -4],
		[3, -4],
		[4, -4],
		[5, -4],
		[6, -4],
		[7, -4],
		[8, -4],
		[9, -4],
		[10, -4],
		[11, -4],
		[12, -4],
		[13, -4],
		[14, -4],
		[15, -4],
		[16, -4],
		[17, -4],
		[18, -4],
		[19, -4],
		[20, -4],
		[21, -4],
		[22, -4],
		[23, -4],
		[24, -4],
		[25, -4],
		[-3, -3],
		[-2, -3],
		[-1, -3],
		[0, -3],
		[1, -3],
		[2, -3],
		[3, -3],
		[4, -3],
		[5, -3],
		[6, -3],
		[7, -3],
		[8, -3],
		[9, -3],
		[10, -3],
		[11, -3],
		[12, -3],
		[13, -3],
		[14, -3],
		[15, -3],
		[16, -3],
		[17, -3],
		[18, -3],
		[19, -3],
		[20, -3],
		[21, -3],
		[22, -3],
		[23, -3],
		[24, -3],
		[25, -3],
		[-3, -2],
		[-2, -2],
		[-1, -2],
		[0, -2],
		[1, -2],
		[2, -2],
		[3, -2],
		[4, -2],
		[5, -2],
		[6, -2],
		[7, -2],
		[8, -2],
		[9, -2],
		[10, -2],
		[11, -2],
		[12, -2],
		[13, -2],
		[14, -2],
		[15, -2],
		[16, -2],
		[17, -2],
		[18, -2],
		[19, -2],
		[20, -2],
		[21, -2],
		[22, -2],
		[23, -2],
		[24, -2],
		[25, -2],
		[-3, -1],
		[-2, -1],
		[-1, -1],
		[0, -1],
		[1, -1],
		[2, -1],
		[3, -1],
		[4, -1],
		[5, -1],
		[6, -1],
		[7, -1],
		[8, -1],
		[9, -1],
		[10, -1],
		[11, -1],
		[12, -1],
		[13, -1],
		[14, -1],
		[15, -1],
		[16, -1],
		[17, -1],
		[18, -1],
		[19, -1],
		[20, -1],
		[21, -1],
		[22, -1],
		[23, -1],
		[24, -1],
		[25, -1],
		[-3, 0],
		[-2, 0],
		[-1, 0],
		[0, 0],
		[1, 0],
		[2, 0],
		[3, 0],
		[4, 0],
		[5, 0],
		[6, 0],
		[7, 0],
		[8, 0],
		[9, 0],
		[10, 0],
		[11, 0],
		[12, 0],
		[13, 0],
		[14, 0],
		[15, 0],
		[16, 0],
		[17, 0],
		[18, 0],
		[19, 0],
		[20, 0],
		[21, 0],
		[22, 0],
		[23, 0],
		[24, 0],
		[25, 0],
		[-3, 1],
		[-2, 1],
		[-1, 1],
		[0, 1],
		[1, 1],
		[2, 1],
		[3, 1],
		[4, 1],
		[5, 1],
		[6, 1],
		[7, 1],
		[8, 1],
		[9, 1],
		[10, 1],
		[11, 1],
		[12, 1],
		[13, 1],
		[14, 1],
		[15, 1],
		[16, 1],
		[17, 1],
		[18, 1],
		[19, 1],
		[20, 1],
		[21, 1],
		[22, 1],
		[23, 1],
		[24, 1],
		[25, 1],
		[-3, 2],
		[-2, 2],
		[-1, 2],
		[0, 2],
		[1, 2],
		[2, 2],
		[3, 2],
		[4, 2],
		[5, 2],
		[6, 2],
		[7, 2],
		[8, 2],
		[9, 2],
		[10, 2],
		[11, 2],
		[12, 2],
		[13, 2],
		[14, 2],
		[15, 2],
		[16, 2],
		[17, 2],
		[18, 2],
		[19, 2],
		[20, 2],
		[21, 2],
		[22, 2],
		[23, 2],
		[24, 2],
		[25, 2],
		[-3, 3],
		[-2, 3],
		[-1, 3],
		[0, 3],
		[1, 3],
		[2, 3],
		[3, 3],
		[4, 3],
		[5, 3],
		[6, 3],
		[7, 3],
		[8, 3],
		[9, 3],
		[10, 3],
		[11, 3],
		[12, 3],
		[13, 3],
		[14, 3],
		[15, 3],
		[16, 3],
		[17, 3],
		[18, 3],
		[19, 3],
		[20, 3],
		[21, 3],
		[22, 3],
		[23, 3],
		[24, 3],
		[25, 3],
		[-3, 4],
		[-2, 4],
		[-1, 4],
		[0, 4],
		[1, 4],
		[2, 4],
		[3, 4],
		[4, 4],
		[5, 4],
		[6, 4],
		[7, 4],
		[8, 4],
		[9, 4],
		[10, 4],
		[11, 4],
		[12, 4],
		[13, 4],
		[14, 4],
		[15, 4],
		[16, 4],
		[17, 4],
		[18, 4],
		[19, 4],
		[20, 4],
		[21, 4],
		[22, 4],
		[23, 4],
		[24, 4],
		[25, 4],
		[-3, 5],
		[-2, 5],
		[-1, 5],
		[0, 5],
		[1, 5],
		[2, 5],
		[3, 5],
		[4, 5],
		[5, 5],
		[6, 5],
		[7, 5],
		[8, 5],
		[9, 5],
		[10, 5],
		[11, 5],
		[12, 5],
		[13, 5],
		[14, 5],
		[15, 5],
		[16, 5],
		[17, 5],
		[18, 5],
		[19, 5],
		[20, 5],
		[21, 5],
		[22, 5],
		[23, 5],
		[24, 5],
		[25, 5],
		[-3, 6],
		[-2, 6],
		[-1, 6],
		[0, 6],
		[1, 6],
		[2, 6],
		[3, 6],
		[4, 6],
		[5, 6],
		[6, 6],
		[7, 6],
		[8, 6],
		[9, 6],
		[10, 6],
		[11, 6],
		[12, 6],
		[13, 6],
		[14, 6],
		[15, 6],
		[16, 6],
		[17, 6],
		[18, 6],
		[19, 6],
		[20, 6],
		[21, 6],
		[22, 6],
		[23, 6],
		[24, 6],
		[25, 6],
		[-3, 7],
		[-2, 7],
		[-1, 7],
		[0, 7],
		[1, 7],
		[2, 7],
		[3, 7],
		[4, 7],
		[5, 7],
		[6, 7],
		[7, 7],
		[8, 7],
		[9, 7],
		[10, 7],
		[11, 7],
		[12, 7],
		[13, 7],
		[14, 7],
		[15, 7],
		[16, 7],
		[17, 7],
		[18, 7],
		[19, 7],
		[20, 7],
		[21, 7],
		[22, 7],
		[23, 7],
		[24, 7],
		[25, 7],
		[-3, 8],
		[-2, 8],
		[-1, 8],
		[0, 8],
		[1, 8],
		[2, 8],
		[3, 8],
		[4, 8],
		[5, 8],
		[6, 8],
		[7, 8],
		[8, 8],
		[9, 8],
		[10, 8],
		[11, 8],
		[12, 8],
		[13, 8],
		[14, 8],
		[15, 8],
		[16, 8],
		[17, 8],
		[18, 8],
		[19, 8],
		[20, 8],
		[21, 8],
		[22, 8],
		[23, 8],
		[24, 8],
		[25, 8],
		[-3, 9],
		[-2, 9],
		[-1, 9],
		[0, 9],
		[1, 9],
		[2, 9],
		[3, 9],
		[4, 9],
		[5, 9],
		[6, 9],
		[7, 9],
		[8, 9],
		[9, 9],
		[10, 9],
		[11, 9],
		[12, 9],
		[13, 9],
		[14, 9],
		[15, 9],
		[16, 9],
		[17, 9],
		[18, 9],
		[19, 9],
		[20, 9],
		[21, 9],
		[22, 9],
		[23, 9],
		[24, 9],
		[25, 9]
	]
	# # Iterate over each tile and perform some action
	# for tile in tile_list:
	# 	self.display_terrain_type(tile)

func _input(event):
	# Maybe outsource this to a click controller module, or maybe delegate all
	# click events to appropiate nodes from here. Ask Q/A
	if event.type == InputEvent.KEY:
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()
	elif event.is_action_pressed('mouse_click'):
		# Once set the actual global mouse position needed for conversion of the coordinates
		var click_pos = self.get_global_mouse_pos()
	
		# Display information directly on top of the selected hex (position in different relations)
		self.highlight_hex(click_pos)
		
		# Set current tile attributes for use by decision logic
		current_tile = self.get_tile(click_pos)

		# print("Current tile: "+String(current_tile))

		# try to mark the outer dimensions (via four edges) of the selected hexagon
		# based on double conversion of click_pos coordinates.
		# self.mark_hex_dimensions(click_pos)

func _fixed_process(delta):
	pass

# Method to return a tiles attributes as defined in tilemap.gd
# @input {Vector2} position - of the click in global coordinates
func get_tile(position):
	# Calculate grid position from world position
	var grid_pos = hexmap.world_to_map(position)
	# Get tile attributes based on tileset index
	var tile = hexmap._get_tile_attributes_by_index(hexmap.get_cell(grid_pos.x, grid_pos.y))
	# Enrich the returned tile object for debugging purposes
	tile.index = hexmap.get_cell(grid_pos.x, grid_pos.y)
	tile.position = grid_pos
	return tile
	
# Method to draw a outline of a tile to highlight it
# @input {Vector2} position - of the click in global coordinates
func highlight_hex(position):
	# get grid local coordinates of hexagon from global click coordinates
	var global_hex_position = hexmap.world_to_map(position)
	# get global coordinates of hexagon from grid local coordinates
	var hex_world_pos = hexmap.map_to_world(global_hex_position)
	# calculate global position of hexagon highlight by adding half the cell size to the global hex position plus offset
	var highlight_pos = Vector2(hex_world_pos.x + self.hex_offset.x + (hexmap.get_cell_size().x/2),
								hex_world_pos.y + self.hex_offset.y + (hexmap.get_cell_size().y/2))
	hex_marker.set_pos(highlight_pos)

############################################################
# These methods are for debug purposes only
############################################################

# Used to display additional information on top of the tile, also create a new marker on every
# tile click and does not delete the old one
# Also requires attribute for marker Color()
func highlight_every_hex(position, marker_color, show_coords):
	# get grid local coordinates of hexagon from global click coordinates
	var global_hex_position = hexmap.world_to_map(position)
	# get global coordinates of hexagon from grid local coordinates
	var hex_world_pos = hexmap.map_to_world(global_hex_position)
	# calculate global position of hexagon highlight by adding half the cell size to the global hex position plus offset
	var highlight_pos = Vector2(hex_world_pos.x + self.hex_offset.x + (hexmap.get_cell_size().x/2),
								hex_world_pos.y + self.hex_offset.y + (hexmap.get_cell_size().y/2))
	# duplicate the highlight
	var new_highlight = hex_marker.duplicate()
	new_highlight.set_modulate(marker_color)
	# position the highlight
	new_highlight.set_pos(highlight_pos)
	# add the highlight to scene
	self.add_child(new_highlight)
	new_highlight.set_owner(get_tree().get_edited_scene_root())
	# if label with coordinates should be shown, do it here
	if show_coords == true:
		# duplicate or create the labels
		var global_pos_label = Label.new()
		var grid_pos_label = Label.new()
		# Position the labels
		global_pos_label.set_pos(hex_world_pos)
		var grid_pos_label_pos = Vector2(hex_world_pos.x, hex_world_pos.y+20)
		grid_pos_label.set_pos(grid_pos_label_pos)
		# Fill the labels with text
		global_pos_label.set_text(String(hex_world_pos))
		grid_pos_label.set_text(String(global_hex_position))
		# add the elements to scene
		self.add_child(global_pos_label)
		self.add_child(grid_pos_label)
		global_pos_label.set_owner(get_tree().get_edited_scene_root())
		grid_pos_label.set_owner(get_tree().get_current_scene())
		

# Debug method to write every tile and its tilemap index into a file for checking
func create_tile_list(tilemap):
	var myfile = File.new()
	print('Start exporting tiles')
	myfile.open("res://tiles.txt", 3)
	myfile.store_string(String(tilemap.get_used_cells()))
	myfile.close()
	print('Done storing')

# Tries to mark the dimensions of the hex tile based on hexmap based coordinates with dots
# @input Vector2 world space coordinates of tiles
func mark_hex_dimensions(position):
	# global position to grid position
	var grid_pos = hexmap.world_to_map(position)
	# grid position back to global position
	var global_pos = hexmap.map_to_world(grid_pos)
	# get dimensions of cell
	var hex_size = hexmap.get_cell_size()
	# duplicate the markers
	var marker1 = marker.duplicate()
	var marker2 = marker.duplicate()
	var marker3 = marker.duplicate()
	var marker4 = marker.duplicate()
	# set positions of each marker
	# set top left (0,0)
	var pos1 = global_pos
	marker1.set_pos(pos1)
	# set top right (0+110,0)
	var pos2 = Vector2(global_pos.x+hex_size.x, global_pos.y)
	marker2.set_pos(pos2)
	# set bottom left (0,0+128)
	var pos3 = Vector2(global_pos.x, global_pos.y+hex_size.y)
	marker3.set_pos(pos3)
	# set bottom right (0+110,0+128)
	var pos4 = global_pos+hex_size
	marker4.set_pos(pos4)
	# add the markers to scene
	self.add_child(marker1)
	self.add_child(marker2)
	self.add_child(marker3)
	self.add_child(marker4)
	marker1.set_owner(get_tree().get_edited_scene_root())
	marker2.set_owner(get_tree().get_edited_scene_root())
	marker3.set_owner(get_tree().get_edited_scene_root())
	marker4.set_owner(get_tree().get_edited_scene_root())

# Display ID for hex tile at grid-based coordinates
# Overlay the information onto the tile itself
# @input {Vector2} grid_coordinates - of tile
# @input {String} counter - Int as string that counts up hexagon ids
func display_hex_id(grid_coordinates, counter=""):
	var tile_world_pos = hexmap.map_to_world(Vector2(grid_coordinates[0],grid_coordinates[1]))
	var new_label = Label.new()
	new_label.set_text(String(hexmap.get_cell(grid_coordinates[0],grid_coordinates[1]))+" - "+String(counter))
	new_label.set_pos(tile_world_pos)
	self.add_child(new_label)
	new_label.set_owner(get_tree().get_edited_scene_root())

# Display the terrain type of the hex tile at grid based coordinates
# @input {Vector2} grid_coordinates - of tile
func display_terrain_type(grid_coordinates):
	# Fill label
	var new_label = Label.new()
	new_label.set_text(String(hexmap._get_tile_attributes_by_index(hexmap.get_cell(grid_coordinates[0],grid_coordinates[1]))['name']))
	# Set pos
	var y_pos = grid_coordinates[1] + (hexmap.get_cell_size().y/2)
	var x_pos = grid_coordinates[0]
	var tile_world_pos = hexmap.map_to_world(Vector2(x_pos,y_pos))
	new_label.set_pos(tile_world_pos)
	# Attach label
	self.add_child(new_label)
	new_label.set_owner(get_tree().get_edited_scene_root())