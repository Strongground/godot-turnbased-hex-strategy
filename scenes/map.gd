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
var tile_list = null
var hexmap = null
var hex_offset = null
var current_tile = null
var marker = null
var root = null
var hex_marker = null
var counter = 0
var hex_directions = null
var all_tiles = null
var arrow_marker = null
var neighbour_position_rotation_table = null
var GUI = null
var units = []

func _ready():
	set_fixed_process(true)
	set_process_input(true)
	camera = find_node('MainCamera')
	root = get_node('/root')
	globals = get_node('/root/globals')
	hexmap = get_node('MapZones')
	marker = get_node('RedDot')
	hex_marker = find_node('HexMarker')
	arrow_marker = find_node('Arrow')
	GUI = find_node('GUI')
	hex_offset = Vector2(-6,0)
	# This table serves as easy shortcut for the grid local coordinate change
	# that needs to be done when a neighbour of a hex tile has to be found.
	# The sorting is identical for odd and even, so hex_directions[0] always
	# gives the northern neighbour.
	all_tiles = hexmap.get_used_cells()
	hex_directions = [
		# Even columns
	    [[0, -1], [1, -1], [1, 0], [0, 1], [-1, 0], [-1, -1]],
		# Odd columns
	    [[0, -1], [1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0]]
	]
	neighbour_position_rotation_table = {
		'n':  -90,
		'ne': -150,
		'se': 150,
		's':  90,
		'sw': 30,
		'nw': -30
	}
	tile_list = _build_hex_object_database()
	# Show the center of the screen as gotten from camera
	# _set_marker(camera.get_screen_center(), 'blue')
	# Create a global list of all units on the map and their positions
	self._create_unit_list()
	self._update_units()

# Build a database of tiles with look-up tables for neighbours and tileset information 
# to allow pathfinding and game logic to work.
# @returns {Array} List of all tiles on the map with precompiled information about every tile.
func _build_hex_object_database():
	var tiles = []
	var i = 0
	for tile in all_tiles:
		tiles.append({
			'id': i,
			'grid_pos': tile,
			'terrain': hexmap._get_tile_attribute_by_index(hexmap.get_cell(tile[0], tile[1]), 'terrain'),
			'move_cost': hexmap._get_tile_attribute_by_index(hexmap.get_cell(tile[0], tile[1]), 'move_cost'),
			'name': hexmap._get_tile_attribute_by_index(hexmap.get_cell(tile[0], tile[1]), 'name'),
			# contains the grid local positions of all neighbours. may also be null if no neighbour
			# exists for a direction.
			'neighbours': {
				'n':  _get_hex_neighbour_pos(tile, 0),
				'ne': _get_hex_neighbour_pos(tile, 1),
				'se': _get_hex_neighbour_pos(tile, 2),
				's':  _get_hex_neighbour_pos(tile, 3),
				'sw': _get_hex_neighbour_pos(tile, 4),
				'nw': _get_hex_neighbour_pos(tile, 5),
			}
		})
		i+=1
	return tiles

# Update all unit nodes. This is necessary because of strange ready()-order in Godot
func _update_units():
	for unit in units:
		unit.node.update() 

# Create a list of all units and their grid local positions
func _create_unit_list():
	for node in self.get_children():
		if 'entity_type' in node and node.entity_type == 'unit':
			units.append({
				'node': node,
				'grid_pos': self.get_hex_object_from_global_pos(node.get_global_pos()).grid_pos
			})

# Get the neighbouring tile of a given tile, by ID and direction
# @input {Int} ID of the hex for which the neighbour should be returned
# @input {Int} Direction of the neighbour that should be returned
# @returns {Vector2|null} grid local position of the neighbour or null if neighbour does not exist
func _get_hex_neighbour_pos(hex_position, direction):
	var parity = int(hex_position[0]) & 1
	var resolved_direction = self.hex_directions[parity][direction]
	var result_coordinates = Vector2(
		hex_position[0] + resolved_direction[0],
		hex_position[1] + resolved_direction[1])
	if result_coordinates in all_tiles:
		return result_coordinates
	else:
		return null

# Get the hex tile object by world position
# @input {Vector2} hex_position - global position of tile
# @returns {Object} The tile object
func get_hex_object_from_global_pos(position):
	var grid_position = hexmap.world_to_map(position)
	for tile in tile_list:
		if tile['grid_pos'] == grid_position:
			return tile

# Get the hex tile object by grid local position
# @input {Vector2} hex_position - grid local position of tile
# @returns {Object} The tile object
func _get_hex_object_from_grid_pos(position):
	for tile in tile_list:
		if tile['grid_pos'] == position:
			return tile
	
# Get the hex tile object by its ID
# @input {int} The ID of the tile to get
# @returns {Object} The tile object
func _get_hex_object_from_id(id):
	for tile in tile_list:
		if tile['id'] == id:
			return tile

func _input(event):
	# Maybe outsource this to a click controller module, or maybe delegate all
	# click events to appropiate nodes from here. Ask Q/A
	if event.type == InputEvent.KEY:
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()
	elif event.is_action_pressed('mouse_click'):
		# Once set the actual global mouse position needed for conversion of the coordinates
		var click_pos = self.get_global_mouse_pos()
		### If clicked on tilemap
		if self._is_tilemap(click_pos) and not self._is_unit(click_pos):
			# On click on a tile, flood fill the map
			self._visit_map(click_pos)
			self._show_origin(tile_list)
			# Display information directly on top of the selected hex (position in different relations)
			self.highlight_hex(click_pos)
			# Set current tile attributes for use by decision logic
			current_tile = self.get_tile(click_pos)
			# Highlight neighbouring hexes of selected hex
			# self._highlight_neighbours(click_pos)
			# Show the popup with tile information
			# GUI._show_tile_info_popup(get_hex_object_from_global_pos(click_pos))
		elif self._is_unit(click_pos):
			print("A unit was clicked!")	
			# @TODO If unit clicked, call its get_path method

func _fixed_process(delta):
	pass

# Check if there is a tilemap at the given position
# Use this to wrap up input loop, to avoid NPE when clicked outside tilemap
# @input {Vector2} position of the click to check for tilemap
func _is_tilemap(position):
	var tile = get_hex_object_from_global_pos(position)
	if tile != null and tile.size() > 1:
		return true
	return false

# Determine if there is a unit at the grid local position that is given
# @input {Vector2} position of the click to check for unit
func _is_unit(position):
	var grid_position = hexmap.world_to_map(position)
	for unit in units:
		if unit.grid_pos == grid_position:
			return true
	return false

# Method to return a tiles attributes as defined in tilemap.gd
# @input {Vector2} global click position
# @returns {Object} the tile object
func get_tile(position):
	# Calculate grid position from world position
	var grid_pos = hexmap.world_to_map(position)
	# Get tile attributes based on tileset index
	var tile = hexmap._get_tile_attributes_by_index(hexmap.get_cell(grid_pos.x, grid_pos.y))
	# Enrich the returned tile object for debugging purposes
	tile.index = hexmap.get_cell(grid_pos.x, grid_pos.y)
	tile.position = grid_pos
	return tile
	
# Method to draw a outline on one tile at a time to highlight it
# @input {Vector2} position - of the click in global coordinates
func highlight_hex(position):
	# get grid local coordinates of hexagon from global click coordinates
	var global_hex_position = hexmap.world_to_map(position)
	# get global coordinates of hexagon from grid local coordinates
	var hex_world_pos = hexmap.map_to_world(global_hex_position)
	# calculate global position of hexagon highlight by adding half the cell size to the global hex position plus offset
	var highlight_pos = _get_center_of_hex(hex_world_pos)
	hex_marker.set_pos(highlight_pos)

# Returns the centered position of the tile, which position is given
# @input {Vector2} global position of hex
# @output {Vector2} global position of center of hex
func _get_center_of_hex(position):
	return Vector2(position.x + self.hex_offset.x + (hexmap.get_cell_size().x/2),
				   position.y + self.hex_offset.y + (hexmap.get_cell_size().y/2))

# Breadth First Search implementation
# @input {Vector2} start_position from where to calculate the visitation
# @input {Vector2|null} (optional) target_position, global coordinates, stops the visitation
# early if the target is reached
func _visit_map(start_position, target_position=null):
	# No Queue() in GD, so using array instead for frontier
	var frontier = [] 
	# Start the visitation witht the tile gotten from the click position
	var start_tile = get_hex_object_from_global_pos(start_position)
	frontier.push_front(tile_list[start_tile['id']])
	
	var visited = []
	var current = null
	var next = null
	var i = 0
	while not frontier.empty():
		current = frontier[0]

		# if target_position is already found, stop vistation to speed up overall calculation
		if target_position != null and current['grid_pos'] == self.get_hex_object_from_global_pos(target_position)['grid_pos']:
			break

		frontier.pop_front()
		for neighbour in current['neighbours']:
			var next_tile_object = _get_hex_object_from_grid_pos(current['neighbours'][neighbour])
			# A neighbour may be null if the tile is on the edge of the map. In that case, skip.
			if next_tile_object != null:
				next = next_tile_object
			else:
				continue
			if not visited.has(next):
				next['came_from'] = {
					'id': current.id, 
					'dir': neighbour
				}
				frontier.append(next)
				visited.append(next)
		i += 1

# Helper function to help visualize the working of the flood fill
# @input {Vector2} The grid local position of the tile to mark
# @input {int} A counter to render onto the tile, that shows the order of flood filling
func _mark_grid_position(grid_position, counter):
	var new_marker = marker.duplicate()
	var counter_label = Label.new()
	var hex_world_pos = hexmap.map_to_world(grid_position)
	var marker_pos = _get_center_of_hex(hex_world_pos)
	counter_label.set_text(String(counter))
	new_marker.set_pos(marker_pos)
	counter_label.set_pos(Vector2(marker_pos.x, marker_pos.y + 15))
	self.add_child(new_marker)
	self.add_child(counter_label)
	counter_label.set_owner(get_tree().get_edited_scene_root())
	new_marker.set_owner(get_tree().get_edited_scene_root())

############################################################
# These methods are for debug purposes only
############################################################

# Helper function to visualize the breadcrumbs in each tile object added by flood fill
# by rendering an arrow on every tile, pointing to the origin tile.
# @input {Array} of tile objects
func _show_origin(tile_list):
	self._delete_all_nodes_with('OriginMarker')
	for tile in tile_list:
		var new_arrow = arrow_marker.duplicate()
		# Set custom name for the arrow marker, so it can be deleted later
		new_arrow.set_name('OriginMarker')
		var arrow_pos = hexmap.map_to_world(tile.grid_pos)
		arrow_pos = _get_center_of_hex(arrow_pos)
		# Use rotation lookup table to get from String like 'n' to a rotation degree
		# like '-90'
		var origin_dir = tile.came_from.dir
		var arrow_rotation = neighbour_position_rotation_table[origin_dir]
		new_arrow.set_rotd(arrow_rotation)
		new_arrow.set_pos(arrow_pos)
		self.add_child(new_arrow)
		new_arrow.set_owner(get_tree().get_edited_scene_root())

# Helper to delete all nodes that start with a certain string.
# This will add a @-sign in front of the given name_fragment because
# dynamically added nodes are auto-prefixed by this by Godot.
# @input {String} Nodes that contain this in their names, will get deleted
func _delete_all_nodes_with(name_fragment):
	for node in self.get_children():
		if node.get_name().begins_with('@'+name_fragment):
			node.queue_free()

# Debug Logger that does not overflow like a %$§#"§$%&#%$§"*#+ every time more than one
# line of code is printed out simultaneously! Go hide under a rock... -.-
# @input {String} The file name of the log file
# @input {String|Object} The log message or object, will be converted to string
func debug_log(filename, message):
	var log_path = 'res://logs/'
	var file_ending = '.log'
	var logfile = File.new()
	logfile.open('res://logs/pathfinding.log', File.READ_WRITE)
	logfile.seek_end() # Find end
	logfile.store_string('\n') # Newline
	if message:
		logfile.store_string(String(message))
	logfile.close()

# Used to display additional information on top of the tile, also create a new marker on every
# tile click and does not delete the old one
# @input {Vector2} Global position of the tile
# @input {Color} Color of the markers created
# @input {Bool} If the coordinates should be rendered onto the tile
func highlight_every_hex(position, marker_color, show_coords):
	# get grid local coordinates of hexagon from global click coordinates
	var global_hex_position = hexmap.world_to_map(position)
	# get global coordinates of hexagon from grid local coordinates
	var hex_world_pos = hexmap.map_to_world(global_hex_position)
	# calculate global position of hexagon highlight by adding half the cell size to the global hex position plus offset
	var highlight_pos = _get_center_of_hex(hex_world_pos)
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

# Create a highlight marker on a given hex that stays.
# @input {Vector2} global position of the hex tile
# @input {Color} Color of the markers created
func _set_marker(hex_world_pos, marker_color):
	var highlight_pos = _get_center_of_hex(hex_world_pos)
	# duplicate the highlight
	var new_highlight = hex_marker.duplicate()
	new_highlight.set_modulate(globals.getColor(String(marker_color)))
	# position the highlight
	new_highlight.set_pos(highlight_pos)
	# add the highlight to scene
	self.add_child(new_highlight)
	
# Highlight the neighbours of a hex tile at a given global position
# @input {Vector2} global position of the tile
func _highlight_neighbours(global_position):
	var selected_tile = self.get_hex_object_from_global_pos(global_position)
	for neighbour_entry in selected_tile['neighbours']:
		if selected_tile.neighbours[neighbour_entry] != null:
			var neighbour_tile_pos = hexmap.map_to_world(selected_tile.neighbours[neighbour_entry])
			self._set_marker(neighbour_tile_pos, 'red')

# Debug method to write every tile and its tilemap index into a file for checking.
# Per default the file is res://tiles.txt and it mus exist before calling this method.
# @input {Tilemap} tilemap for which all used tiles should be exported
func _export_tile_list(tilemap):
	var myfile = File.new()
	print('Start exporting tiles')
	myfile.open("res://tiles.txt", 3)
	myfile.store_string(String(tilemap.get_used_cells()))
	myfile.close()
	print('Done storing')

# Tries to mark the dimensions of the hex tile based on hexmap based coordinates with dots
# @input {Vector2} world space coordinates of tiles
func _mark_hex_dimensions(position):
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

# Display various coordinates for hex tiles at grid-based coordinates
# Render the information onto the tile itself
# @input {Vector2} input_coordinates - grid local coordinates of tile
# @input {String} show_coordinates - String of the name of coordinates that should be shown
# Possible values are: "grid", "global", "id"
func _display_hex_info(input_coordinates, show_coordinates):
	var new_label = Label.new()
	var tile_world_pos = hexmap.map_to_world(Vector2(input_coordinates[0],input_coordinates[1]))
	# Set content of label based on parameters
	if show_coordinates == "global":
		new_label.set_text(String(tile_world_pos))
	elif show_coordinates == "grid":
		new_label.set_text(String(input_coordinates))
	elif show_coordinates == "id":
		new_label.set_text(String(hexmap.get_cell(input_coordinates[0],input_coordinates[1])))
	new_label.set_pos(tile_world_pos)
	self.add_child(new_label)
	new_label.set_owner(get_tree().get_edited_scene_root())

# Display the terrain type of the hex tile at grid based coordinates
# @input {Vector2} grid_coordinates - of tile
func _display_terrain_type(grid_coordinates):
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