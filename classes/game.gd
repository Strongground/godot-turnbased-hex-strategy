extends Node2D

# The map class should serve as a parent class from which all map instances in the game inherit
# general comfort functions to select hexes and display information about hexes (highlighting,
# showing of terrain information etc.). These functions are currently present in this ('game')
# class script.
#
# The map class may also contain information on the goals of the map such as victory hexes and 
# offer methods to get state of these goals (as long as they are hex or region based).
#
# This class should be used as parent for the map/game scene. The game scene will then be
# filled with the necessary entities either by hand (level editing in Godot) or automatically
# (procedurally generated levels?)
#
# Proposed structure of the scene tree during a running mission would be like this:
# game
# L main camera
# 	L GUI
# L map
# 	L map graphic
#   L overlays
#   L all entities


### Implementation Notes/TODO:
# Add a routine to populate the units in the game at the start
# If exported/public values of a unit are filled with non-default values,
# use them. Otherwise, fill the attributes with the defaults from the theme.
# Unit will need to get another set of default values, because the current
# depicts a specific unit already.
#
# Add the count of movement points. Make sure movement points are only deducted
# after the unit has entered a new hex tile, not at the end or the beginning of the
# movement phase summarized, because a movement in progress can be interrupted if
# an enemy unit is revealed or terrain changes blocks access.

# TODOs
# * Add a way of saving table of which unit type can attack which unit type

# member vars here
# unused members are commented out, but left here for later use
# onready var camera = find_node('MainCamera')
# onready var root = get_node('/root')
onready var globals = get_node('/root/globals')
onready var hexmap = get_node('MapZones')
onready var marker = get_node('RedDot')
onready var hex_grid = get_node('HexGridOverlay')
onready var rect = get_node('SizeRect')
onready var hex_marker = find_node('HexMarker')
onready var hex_fill = find_node('Hex_Fill')
onready var arrow_marker = find_node('Arrow')
onready var tween = find_node('Tween')
onready var GUI = find_node('GUI')
# var tiles = null
var tile_list = null
var hex_offset = null
var current_tile = null
# var counter = 0
var hex_directions = null
var all_tiles = null
var neighbour_position_rotation_table = null
var entities = []
# var click_counter = 0
# var start_position = null
# var target_position = null
var selected_unit = null
var theme = null
var factions = null
var movement_selection = false
var attack_selection = false
# Options
export var grid_visible = false
export var city_names_visible = true
## Loop vars
var turn_counter = 0
var active_player = null
var player_rotation = []
var players = {}
## Game Ressource Managers
onready var playerMgr = $PlayerManager
onready var factionMgr = $FactionManager
onready var themeMgr = $ThemeManager
## debug labels
onready var label_player = find_node('CurrentPlayer')
onready var label_turn = find_node('CurrentTurn')

func _ready():
	set_process_input(true)
	# Define players, this should later be done either in the scenario
	# or the pre-scenario settings for multiplayer matches.
	var registered_players = [
		{'id': 0, 'name': 'Human Tester', 'factionID': 0, 'isHuman': true, 'stances': {'enemies':[1,2],'neutral':[3]}},
		{'id': 1, 'name': 'Test AI (Dumb)', 'factionID': 1, 'isHuman': false, 'stances': {'enemies':[0,3],'allied':[2]}},
		{'id': 2, 'name': 'Test AI (Clever)', 'factionID': 1, 'isHuman': false, 'stances': {'enemies':[0],'allied':[1],'neutral':[3]}},
		{'id': 3, 'name': 'Refugees', 'factionID': 2, 'isHuman': false, 'stances': {'neutral':[0,1,2]}},
	]
	players = playerMgr.create_players(registered_players)
	# Load theme
	themeMgr.load_theme('example')
	# Create factions
	factionMgr.load_factions()
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
	# Build a database of hex tiles and assorted calculations, a lookup table for easier checks.
	tile_list = self._build_hex_object_database()
	# Place the units according to their ID and fill attributes.
	# Create a global list of all entities on the map, their type, positions and nodes
	entities = self._create_entity_list()
	self._place_units()
	self._update_units()
	# GUI ready functions
	GUI.disable_movement_button(true)
	GUI.disable_attack_button(true)
	# Start first turn
	self._advance_player_rotation()
	
# "Place" units according to the ID of their placeholder entity. This means:
# Fill all atributes of the entity with the values of the unit with the given
# ID from the theme, while leaving non-default values.
func _place_units():
	# Fetch one-time list of all units in theme
	var theme_units = themeMgr.get_units()
	for entity in entities:
		# If entity is of type "unit" and the unit_id is existing in the theme
		if entity.type == 'unit' and entity.node.unit_id in theme_units:
			var unit_data = themeMgr.get_unit(entity.node.unit_id)
			entity.node.fill_attributes(unit_data)

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

# Update all unit nodes with their internal update-method. There is still
# udpates going on in the main game script that handles grid-position tables
# etc.
# This is necessary because of inconvenient ready()-order in Godot
func _update_units():
	for entity in entities:
		if entity.type == 'unit':
			entity.node.update() 

# Check if the given position is a valid move-destination for the given
# unit. @TODO Extend this method to take into account the type of unit
# that is given, because air units, amphibious units or sea units behave
# different than ground units on the same terrain.
# @input {Vector2} Position to be checked
# @input {Object} The unit for which the validity of the destination is checked
func _is_valid_destination(click_pos):
	var clicked_hex_object = self._get_hex_object_from_global_pos(click_pos)
	for entity in entities:
		if entity.grid_pos == clicked_hex_object.grid_pos:
			if not entity.node.is_container(): 
				return false
	return true

# Get entity by given id
# Either returns an entity object or 'false'
func _get_entity_by_id(id):
	for entity in entities:
		if entity.id == id:
			return entity
	return false

# Get entity by grid position
# Either returns an entity object or 'false'
func _get_entity_by_pos(pos):
	for entity in entities:
		if entity.grid_pos == pos:
			return entity
	return false

# Create a list of all entities and their grid local positions as well as nodes
func _create_entity_list():
	var result = []
	var i = 0
	var allowed_node_types = ["unit", "editor_marker"]
	for node in self.get_children():
		# if node is of allowed type
		if "type" in node and node.type in allowed_node_types:
			node.set_id(i)
			result.append({
				"id": i,
				"node": node,
				"type": node.get_type(),
				"grid_pos": self._get_hex_object_from_global_pos(node.get_global_position()).grid_pos
			})
			i += 1
	return result
	
# Update an entity in the global list of entities and their grid local positions.
# This needs to be done after a unit has changed location, since all calculations
# that involve position, are done with help of this global list.
func update_entity_list_entry(entity):
	entity.grid_pos = self._get_hex_object_from_global_pos(entity.node.get_global_position()).grid_pos

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
func _get_hex_object_from_global_pos(given_position):
	var grid_position = hexmap.world_to_map(given_position)
	for tile in tile_list:
		if tile['grid_pos'] == grid_position:
			return tile

# Get the hex tile object by grid local position
# @input {Vector2} hex_position - grid local position of tile
# @returns {Object} The tile object
func _get_hex_object_from_grid_pos(given_position):
	for tile in tile_list:
		if tile['grid_pos'] == given_position:
			return tile
	
# Get the hex tile object by its ID
# @input {int} The ID of the tile to get
# @returns {Object} The tile object
func _get_hex_object_from_id(id):
	for tile in tile_list:
		if tile['id'] == id:
			return tile


#### INPUT CONTROL ####

func _input(event):
	# @TODO Maybe outsource this to a click controller module, or maybe delegate all
	# click events to appropiate nodes from here. Ask Q/A
	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE:
			get_tree().quit()
	elif event.is_action_pressed('mouse_click'):
		# Once set the actual global mouse position needed for conversion of the coordinates
		var click_pos = self.get_global_mouse_position()
		print('Click registered at '+String(click_pos))
		
		### If clicked on empty spot on map, not on a unit or GUI
		var gui_click = GUI.is_gui_clicked()
		var map_click = self._is_tilemap(click_pos)
		var unit_click = self._is_unit(click_pos)
		if not unit_click and not gui_click and map_click:
			# Save tile information in local variable for easy access
			self.current_tile = self.get_tile(click_pos)
			print('Click was not on unit, was not on gui, but on map, on tile '+String(current_tile))
			# If a unit was previously selected
			if self.selected_unit != null:
				print('A unit is still selected...')
				# If the selected unit can move and the player clicks on a valid target destination, 
				# the click sets the movement destination and triggers pathfinding to it, saving
				# the resulting path array at the selected unit.
				if self.movement_selection == true and self._is_valid_destination(click_pos) == true:
					print('Move command issued. Click Pos is valid destination and unit can move.')
					var unit = _get_entity_by_id(self.selected_unit)
					unit.node.move_unit(unit.node.get_global_position(), click_pos, unit)
					self.movement_selection = false
		# if clicked on unit not belonging to player
		elif self.attack_selection == true and unit_click and not gui_click:
			print('Click was on a unit, was not on gui.')
			# Get own selected unit
			var player_unit = _get_entity_by_id(self.selected_unit).node
			# @TODO This is not triggered at the moment, fix
			# If the selected unit can attack and the player clicks on a valid target, initiate
			# an attack.
			if player_unit.is_valid_attack_target(click_pos):
				print('Attack command issued. Target is valid attack target.')
				var enemy_unit = self._is_unit(click_pos, true).node
				player_unit.attack(enemy_unit)
				self.attack_selection = false
				# Deselect all selectable entities
				self.deselect_all_entities()
		# Clicked on player unit
		elif unit_click:
			var unit = self._is_unit(click_pos, true).node
			if unit.owned_by_active_player():
				self.selected_unit = unit
				self.selected_unit.select()
				if unit.can_move():
					GUI.disable_movement_button(false)
				if unit.combat_ready():
					GUI.disable_attack_button(false)

			##### On click on two tiles, flood fill the map and get path from first to second click
#			if click_counter < 1:
#				print('First click')
#				# On first click, determine start position
#				start_position = click_pos
#				# increment click counter
#				click_counter += 1
#				# color clicked (starting) tile red
#				var vis_start_tile = self._get_hex_object_from_global_pos(start_position)
#				self._set_hex_fill(hexmap.map_to_world(vis_start_tile.grid_pos), 'red', 'path_vis')
#			elif click_counter == 1:
#				print('Second click')
#				# On second click, determine target position
#				# reset counter
#				click_counter += 1
#				target_position = click_pos
#				var path = self.find_path(start_position, target_position)
#				self._show_path(path)
#			else:
#				print('Third click')
#				# On third click reset click counter
#				click_counter = 0
#				# and delete path visualisation
#				self._delete_all_nodes_with('path_vis')
			#### END

			# Highlight neighbouring hexes of selected hex
			# self._highlight_neighbours(click_pos)
		
			# Show the popup with tile information
#			GUI._show_tile_info_popup(_get_hex_object_from_global_pos(click_pos))
#			GUI._show_tile_info_popup(current_tile)

# Process the current turn
func _end_turn():
	_advance_player_rotation()
	turn_counter += 1

func _advance_player_rotation():
	var player_active = false
	var next_player = ''
	# first call of this function
	if players.size() != player_rotation.size():
		# set first human player as active
		for player in players:
			if player.node.is_human() and self.active_player == null:
				player.node.set_active(true)
				self.active_player = player.node
			# fill player rotation once
			player_rotation.append(player.node.get_id())
		# for the initial call of this function, nothing more needs to
		# be done, exit here.
		return true
	# if this is not the initial call of this function, determine next player
	var counter = 0
	for player_id in player_rotation:
		var player = playerMgr.get_player_by_id(player_id)
		# found active player, set it to inactive and determine id of next one
		if player.is_active():
			# Set player entry in player_rotation to 'not active'
			player.set_active(false)
			# Set next player as active
			if (counter + 1) > players.size():
				counter = 0
			next_player = player_rotation[counter].node
			next_player.set_active(true)
			self.active_player = next_player
		counter += 1

func _physics_process(delta):
	if active_player != null:
		label_player.set_text(String(active_player.get_id()))
	if turn_counter:
		label_turn.set_text(String(turn_counter))

# Check if there is a tilemap at the given position.
# Use this to wrap up input loop, to avoid NPE when clicked outside tilemap.
# Offers strict mode (check if no entity at given coords) or standard
# mode, which just checks that no entity of type unit is a the given coords. 
# Background: The move
# logic allows moving onto certain types of entities (e.g. map logic entities 
# like cities), but not others (units, mainly). In this case it is necessary to
# check if there is a unit at the given coords or "something else", which qualifies
# as "tilemap" in this case.
# @input {Vector2} position of the click to check for tilemap
# @input {Boolean} (optional) Strict mode, checks against entities.
# @returns {Boolean} return true if there is no entity at given coords
func _is_tilemap(given_position, strict_mode=false):
	var tile = _get_hex_object_from_global_pos(given_position)
	var unit = _get_entity_by_pos(given_position)
	# Tilemap at given position
	if tile != null and tile.size() > 1:
		print("Found tilemap at given coords")
		# If a entity was found at the given coords
		if unit:
			# If strict mode enabled, return 'false' if any entity exists at given coords.
			# Per default, only return 'false' if a entity of type 'unit' is found.
			if strict_mode:
				print("Found entity in strict mode, no tilemap hit.")
				return false
			else:
				print("Did I find a unit?" + str(!(unit.node.get_type() == 'unit')))
				return !(unit.node.get_type() == 'unit')
		return true
	return false

# Determine if there is a unit at the grid local position that is given.
# @input {Vector2} position of the click to check for unit
# @input {Boolean} (optional) return unit object if true
# @returns {Boolean | Object} return true if there is a unit at given coords
# or the unit instance itself
func _is_unit(given_position, return_unit=false):
	var grid_position = hexmap.world_to_map(given_position)
	for entity in entities:
		if entity.node.get_type() == 'unit':
			if entity.grid_pos == grid_position:
				if return_unit == true:
					print("Found unit at location "+str(entity.node.get_global_position()))
					print(entity)
					return entity
				else:
					return true
	return false

# Deselects all selectable entities on the map 
func deselect_all_entities():
	for entity in entities:
		if entity.node.has_method('is_selected') and entity.node.is_selected():
			# If a unit is deselected, deactivate the move button in GUI
			if entity.type == 'unit':
				GUI.disable_movement_button(true)
				GUI.disable_attack_button(true)
			entity.node.deselect()

# Getter for unit_selected. This is faster than iterating over all
# units and check each for its 'selected' states
# @returns {Boolean} Returns true if a unit was selected.
func _is_unit_selected():
	for entity in entities:
		if entity.type == 'unit':
			if entity.node.is_selected():
				return true
	return false

# Method to return a tiles attributes as defined in tilemap.gd
# @input {Vector2} global click position
# @returns {Object} the tile object
func get_tile(given_position):
	# Calculate grid position from world position
	var grid_pos = hexmap.world_to_map(given_position)
	# Get tile attributes based on tileset index
	var tile = hexmap._get_tile_attributes_by_index(hexmap.get_cell(grid_pos.x, grid_pos.y))
	# Enrich the returned tile object for debugging purposes
	tile.index = hexmap.get_cell(grid_pos.x, grid_pos.y)
	tile.position = grid_pos
	return tile
	
# Method to draw a outline on one tile at a time to highlight it
# @input {Vector2} position - of the click in global coordinates
func highlight_hex(given_position):
	# get grid local coordinates of hexagon from global click coordinates
	var global_hex_position = hexmap.world_to_map(given_position)
	# get global coordinates of hexagon from grid local coordinates
	var hex_world_pos = hexmap.map_to_world(global_hex_position)
	# calculate global position of hexagon highlight by adding half the cell size to the global hex position plus offset
	var highlight_pos = _get_center_of_hex(hex_world_pos)
	hex_marker.set_position(highlight_pos)

# Returns the centered position of the tile, which position is given
# @input {Vector2} global position of hex
# @output {Vector2} global position of center of hex
func _get_center_of_hex(given_position):
	return Vector2(given_position.x + self.hex_offset.x + (hexmap.get_cell_size().x/2),
				   given_position.y + self.hex_offset.y + (hexmap.get_cell_size().y/2))

# Breadth First Search implementation
# @input {Vector2} start_position global coordinates, from where to calculate the visitation
# @input {Vector2|null} (optional) target_position, global coordinates, stops the visitation
# early if the target is reached
func _visit_map(start_position, target_position=null):
	# No Queue() in GD, so using array instead for frontier
	# No PriorityQueue() either in GD, so the frontier array will contain
	# a tuple in each entry, with the full tile-object and priority (a.k.a. cost).
	# We will then sort the array based on that value by using sorted with cost as 
	# key. Sadly, Godot does not offer 'sorted' function, so we implement this 
	# manually by using 'custom_sort'
	var frontier = []
	# Start the visitation witht the tile gotten from the click position
	var start_tile = _get_hex_object_from_global_pos(start_position)
	frontier.push_front([tile_list[start_tile['id']], 0]) # Start tile has cost 0
	
	var visited = []
	var current = null
	var next = null
	var i = 0
	var cost_so_far = {
		# Cost for start tile is always 0 and cost_so_far cannot be empty
		String(start_tile['id']): 0
	}

	# @DEBUG: Delete all debug path visualisations so there is no overlay.
	# This can be commented out if the path visualisation is commented out as well.
	self._delete_all_nodes_with('path_vis')
	
	while not frontier.empty():
		frontier.sort_custom(self, "_sort_by_second_attr") # First sort frontier by cost attribute in each tuple
		current = frontier[0] # Now current[0] gives the tile object, current[1] the associated cost

		# if target_position is already found, stop visitation to speed up overall calculation
		if target_position != null and current[0]['grid_pos'] == self._get_hex_object_from_global_pos(target_position)['grid_pos']:
			print('Found target tile, breaking now!')
			break
		
		frontier.pop_front()
		for neighbour in current[0]['neighbours']:
			var next_tile_object = _get_hex_object_from_grid_pos(current[0]['neighbours'][neighbour])
			# A neighbour may be null if the tile is on the edge of the map. In that case, skip.
			if next_tile_object != null:
				next = next_tile_object
			else:
				continue
			### Uniform cost search part
			# Calculate the movement cost by next tile movement cost and adding current
			var new_cost = cost_so_far[String(current[0]['id'])] + next['move_cost']
			if not cost_so_far.has(String(next['id'])) || new_cost < cost_so_far[String(next['id'])]:
				cost_so_far[String(next['id'])] = new_cost
				var cost = new_cost
				next['came_from'] = {
					'id': current[0].id,
					'dir': neighbour
				}
				frontier.append([next, cost])
				visited.append(next)
				# @DEBUG: Show movement cost per tile.
				self._render_on_tile(next['grid_pos'], String(cost_so_far[String(next['id'])]), 'path_vis')
		i += 1

# Determine path from tile to tile, all coordinates are global
# @input {Vector2} start_position, from this the start tile is derived
# @input {Vector2} target_position, from this the target tile is derived
# @returns {Array} path to the target tile
func find_path(start_position, target_position):
	self._visit_map(start_position, target_position)
	var start_tile = self._get_hex_object_from_global_pos(start_position)
	var target_tile = self._get_hex_object_from_global_pos(target_position)
	var current = null
	var path = []
	
	# add target to path array
	current = target_tile
	path.append(current)

	while current.id != start_tile.id:
		current = self._get_hex_object_from_id(current.came_from.id)
		path.append(current)
	
	# finally add start to path array
	path.append(start_tile)
	# invert path array so it goes from start to target and return
	path.invert()
	return path

# Helper function to help visualize the working of the flood fill
# @input {Vector2} The grid local position of the tile to mark
# @input {int} A counter to render onto the tile, that shows the order of flood filling
func _mark_grid_position(grid_position, counter):
	var new_marker = marker.duplicate()
	var counter_label = Label.new()
	var hex_world_pos = hexmap.map_to_world(grid_position)
	var marker_pos = _get_center_of_hex(hex_world_pos)
	counter_label.set_text(String(counter))
	new_marker.set_position(marker_pos)
	counter_label.set_position(Vector2(marker_pos.x, marker_pos.y + 15))
	self.add_child(new_marker)
	self.add_child(counter_label)
	counter_label.set_owner(get_tree().get_edited_scene_root())
	new_marker.set_owner(get_tree().get_edited_scene_root())

# Sorting helper to compare second attribut of two given arrays
# @input {Array} Array A to compare
# @input {Array} Array B to compare
# @output {Boolean} True if second attribute from A is smaller than
# second attribute from B
func _sort_by_second_attr(a, b):
	return a[1] < b[1]

##########################################################################
# These methods are for debug purposes only
# They should be deleted, cleaned and integrated or very well hidden away
##########################################################################

# Helper function to visualize the path found by flood fill by rendering
# a marker on top of every tile in the path
# @input {Array} the found path
func _show_path(path, mark_start_tile=true):
	for tile in path:
		# don't color first tile, if option is set to false
		if tile == path[0]:
			if mark_start_tile:
				pass
			# else, color first tile green (for "start here")
			else:
				self._set_hex_fill(hexmap.map_to_world(tile.grid_pos), 'green', 'path_vis')
		# color last tile red (for "stop here")
		elif tile == path[path.size()-1]:
			self._set_hex_fill(hexmap.map_to_world(tile.grid_pos), 'red', 'path_vis')
		# color all other tiles blue
		else:
			self._set_hex_fill(hexmap.map_to_world(tile.grid_pos), 'blue', 'path_vis')


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
		new_arrow.set_position(arrow_pos)
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
func highlight_every_hex(given_position, marker_color, show_coords):
	# get grid local coordinates of hexagon from global click coordinates
	var global_hex_position = hexmap.world_to_map(given_position)
	# get global coordinates of hexagon from grid local coordinates
	var hex_world_pos = hexmap.map_to_world(global_hex_position)
	# calculate global position of hexagon highlight by adding half the cell size to the global hex position plus offset
	var highlight_pos = _get_center_of_hex(hex_world_pos)
	# duplicate the highlight
	var new_highlight = hex_marker.duplicate()
	new_highlight.set_modulate(marker_color)
	# position the highlight
	new_highlight.set_position(highlight_pos)
	# add the highlight to scene
	self.add_child(new_highlight)
	new_highlight.set_owner(get_tree().get_edited_scene_root())
	# if label with coordinates should be shown, do it here
	if show_coords == true:
		# duplicate or create the labels
		var global_pos_label = Label.new()
		var grid_pos_label = Label.new()
		# Position the labels
		global_pos_label.set_position(hex_world_pos)
		var grid_pos_label_pos = Vector2(hex_world_pos.x, hex_world_pos.y+20)
		grid_pos_label.set_position(grid_pos_label_pos)
		# Fill the labels with text
		global_pos_label.set_text(String(hex_world_pos))
		grid_pos_label.set_text(String(global_hex_position))
		# add the elements to scene
		self.add_child(global_pos_label)
		self.add_child(grid_pos_label)
		global_pos_label.set_owner(get_tree().get_edited_scene_root())
		grid_pos_label.set_owner(get_tree().get_current_scene())

# Create a highlight marker on a given hex that stays.
# This looks different than the hex highlight in that it
# overlays the whole hex with a transparent colored fill
# @input {Vector2} global position of the hex tile
# @input {Color} Color of the markers created
# @input {String} (optional) Name of the marker node
func _set_hex_fill(hex_world_pos, marker_color, opt_name=null):
	var highlight_pos = _get_center_of_hex(hex_world_pos)
	# duplicate the highlight
	var new_hex_fill = hex_fill.duplicate()
	if opt_name != null:
		new_hex_fill.set_name(opt_name)
	new_hex_fill.set_modulate(globals.getColor(String(marker_color)))
	# position the highlight
	new_hex_fill.set_position(highlight_pos)
	# add the highlight to scene
	self.add_child(new_hex_fill)
	
# Highlight the neighbours of a hex tile at a given global position
# @input {Vector2} global position of the tile
func _highlight_neighbours(given_global_position):
	var selected_tile = self._get_hex_object_from_global_pos(given_global_position)
	for neighbour_entry in selected_tile['neighbours']:
		if selected_tile.neighbours[neighbour_entry] != null:
			var neighbour_tile_pos = hexmap.map_to_world(selected_tile.neighbours[neighbour_entry])
			self._set_hex_fill(neighbour_tile_pos, 'red')

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

# Renders red dot at given position relative to given parent
# @input {Vector2} position to render dot
# @input {Object} parent node of the created sprite
func _render_dot(given_position, parent):
	var new_marker = marker.duplicate()
	new_marker.set_position(given_position)
	parent.add_child(new_marker)
	new_marker.set_owner(get_tree().get_edited_scene_root())

# Renders a texture frame at given position, with given size, 
# relative to given parent
# @input {Vector2} top left position to begin render box
# @input {Vector2} size dimensions of the box
# @input {Object} parent node of the created box
func _render_size_rect(given_position, size, parent):
	var new_rect = rect.duplicate()
	new_rect.set_position(given_position)
	new_rect.set_size(size)
	parent.add_child(new_rect)
	new_rect.set_owner(get_tree().get_edited_scene_root())

# Tries to mark the dimensions of the hex tile based on hexmap based coordinates with dots
# @input {Vector2} world space coordinates of tiles
func _mark_hex_dimensions(given_position):
	# global position to grid position
	var grid_pos = hexmap.world_to_map(given_position)
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
	marker1.set_position(pos1)
	# set top right (0+110,0)
	var pos2 = Vector2(global_pos.x+hex_size.x, global_pos.y)
	marker2.set_position(pos2)
	# set bottom left (0,0+128)
	var pos3 = Vector2(global_pos.x, global_pos.y+hex_size.y)
	marker3.set_position(pos3)
	# set bottom right (0+110,0+128)
	var pos4 = global_pos+hex_size
	marker4.set_position(pos4)
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
	new_label.set_text(String(hexmap.get_cell(input_coordinates[0],input_coordinates[1])))
	new_label.set_position(tile_world_pos)
	self.add_child(new_label)
	new_label.set_owner(get_tree().get_edited_scene_root())

# Render given information onto the tile itself
# @input {Vector2} input_coordinates - grid local coordinates of tile
# @input {String} String that should be rendered on the tile
# @input {String} String that should be used as name for the created node
func _render_on_tile(input_coordinates, info, opt_name):
	var new_label = Label.new()
	var tile_world_pos = hexmap.map_to_world(Vector2(input_coordinates[0],input_coordinates[1]))
	new_label.set_text(info)
	new_label.set_position(tile_world_pos)
	if opt_name != null:
		new_label.set_name(opt_name)
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
	new_label.set_position(tile_world_pos)
	# Attach label
	self.add_child(new_label)
	new_label.set_owner(get_tree().get_edited_scene_root())

##########################################################################
# Automatically created methods for signalling
##########################################################################

func _on_ToggleGridButton_pressed():
	var from_opacity = null
	var to_opacity = null
	if grid_visible:
		from_opacity = Color(1, 1, 1, 0.3)
		to_opacity = Color(1, 1, 1, 0)
		grid_visible = false
	else:
		from_opacity = Color(1, 1, 1, 0)
		to_opacity = Color(1, 1, 1, 0.3)
		grid_visible = true
	tween.interpolate_property(hex_grid, 'modulate', from_opacity, to_opacity, 2.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

func _on_EndTurnButton_pressed():
	_end_turn()
