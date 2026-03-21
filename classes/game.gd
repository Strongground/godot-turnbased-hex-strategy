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
# If exported/public values of a entity are filled with non-default values,
# use them. Otherwise, fill the attributes with the defaults from the theme.
#
# Make sure movement points are only deducted
# after the entity has entered a new hex tile, not at the end or the beginning of the
# movement phase summarized, because a movement in progress can be interrupted if
# an enemy entity is revealed or terrain changes blocks access.
# 
# Add a way of saving table of which entity type can attack which entity type

# member vars here
# unused members are commented out, but left here for later use
# onready var camera = find_child('MainCamera')
# onready var root = get_node('/root')
@export var globals: Node
@export var hexmap: TileMapLayer
@export var marker: Node2D
@export var hex_grid: Node2D
@export var rect: Control
@onready var hex_marker = find_child('HexMarker')
@onready var hex_fill = find_child('Hex_Fill')
@onready var arrow_marker = find_child('Arrow')
@onready var GUI = find_child('GUI')
@export var hex_highlight: Node2D
# var tiles = null
var tile_list = null
var hex_offset = null
var current_tile = null
# var counter = 0
var hex_directions = null
var all_tiles = null
var astar_grid: AStarGrid2D = null
var entities = []
# var click_counter = 0
# var start_position = null
# var target_position = null
var selected_unit = null
var theme = null
var factions = null
var movement_selection = false
var attack_selection = false
var resupply_selection = false
# Track whether the active player has attacked this turn.
var attack_made_this_turn = false
# Options
@export var grid_visible = false
@export var city_names_visible = true
@export var debug_logging = true
## Loop vars
var turn_counter = 0
var active_player = null
var active_player_rot_index = null
var player_rotation = []
var players = {}
var _last_mouse_pos = Vector2(INF, INF)
## Game Ressource Managers
@export var playerMgr: Node
@export var factionMgr: Node
@export var themeMgr: Node
@export var musicMgr: Node
## debug labels
@onready var label_player = find_child('CurrentPlayer')
@onready var label_turn = find_child('CurrentTurn')

func _ready():
	if globals == null:
		globals = get_node_or_null("/root/globals")
	_debug_log("_ready(): start")
	# Set hex grid to not visible
	hex_grid.modulate.a = 0
	# Define players, this should later be done either in the scenario
	# or the pre-scenario settings for multiplayer matches.
	var registered_players = [
		{'id': 0, 'name': 'Human Tester', 'factionID': 'usarmy', 'isHuman': true, 'stances': {'enemies':[1,2],'neutral':[3]}},
		{'id': 1, 'name': 'Test AI (Dumb)', 'factionID': 'taliban', 'isHuman': false, 'stances': {'enemies':[0,3],'allied':[2]}},
		{'id': 2, 'name': 'Test AI (Clever)', 'factionID': 'taliban', 'isHuman': false, 'stances': {'enemies':[0],'allied':[1],'neutral':[3]}},
		{'id': 3, 'name': 'Refugees', 'factionID': 'civilians', 'isHuman': false, 'stances': {'neutral':[0,1,2]}},
	]
	players = playerMgr.create_players(registered_players)
	_debug_log("_ready(): players created=" + str(players.size()))
	# Load theme
	var theme_name = "example-modern"
	if globals != null:
		var selected_theme_folder = globals.get("selected_theme_folder")
		if typeof(selected_theme_folder) == TYPE_STRING and selected_theme_folder != "":
			theme_name = selected_theme_folder
		else:
			var selected_theme = globals.get("selected_theme")
			if typeof(selected_theme) == TYPE_STRING and selected_theme != "":
				theme_name = selected_theme
	if not FileAccess.file_exists("res://themes/" + theme_name + "/config.json"):
		theme_name = _find_first_theme_folder()
	themeMgr.load_theme(theme_name)
	_debug_log("_ready(): theme loaded='" + str(theme_name) + "'")
	# Apply tile definitions from theme (if provided)
	var theme_tiles = themeMgr.get_tiles()
	if typeof(theme_tiles) == TYPE_ARRAY and not theme_tiles.is_empty():
		hexmap.set_tile_types(theme_tiles)
	# Create factions
	factionMgr.load_factions()
	_debug_log("_ready(): factions loaded=" + str(factionMgr.factions.size()))
	# Load list of music titles to play
	if DisplayServer.get_name() != "headless":
		musicMgr.play()
		_debug_log("_ready(): music manager play() called")
	else:
		_debug_log("_ready(): headless run, skipping music playback")
	hex_offset = Vector2(-6,0)
	# This table serves as easy shortcut for the grid local coordinate change
	# that needs to be done when a neighbour of a hex tile has to be found.
	# The mapping is identical for odd and even, so hex_directions[0] always
	# gives the northern neighbour.
	all_tiles = hexmap.get_used_cells()
	hex_directions = [
		# Even columns
		[[0, -1], [1, -1], [1, 0], [0, 1], [-1, 0], [-1, -1]],
		# Odd columns
		[[0, -1], [1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0]]
	]
	# Build a database of hex tiles and assorted calculations, a lookup table for easier checks.
	tile_list = self._build_hex_object_database()
	_debug_log("_ready(): tile_list built, size=" + str(tile_list.size()))
	self._build_astar_grid()
	_debug_log("_ready(): astar_grid built")
	# Place the units according to their ID and fill attributes.
	# Create a global list of all entities on the map, their type, positions and nodes
	entities = self._create_entity_list()
	_debug_log("_ready(): entities created, size=" + str(entities.size()))
	self._place_units()
	_debug_log("_ready(): _place_units() done")
	self._update_units()
	_debug_log("_ready(): _update_units() done")
	# GUI ready functions
	GUI.disable_movement_button(true)
	GUI.disable_attack_button(true)
	GUI.disable_supply_button(true)
	# Start first turn
	self._advance_player_rotation()
	_debug_log("_ready(): done")
	# for tile in tile_list:
	# 	self._render_dot(tile['id'])

# "Place" units according to the ID of their placeholder entity. This means:
# Fill all atributes of the entity with the values of the entity with the given
# ID from the theme, while leaving non-default values.
func _place_units():
	# Fetch one-time list of all units in theme
	var theme_units = themeMgr.get_units()
	for new_entity in entities:
		# If entity is of type "entity" and the unit_id is existing in the theme
		if new_entity.type == 'entity' and new_entity.node.unit_id in theme_units:
			var unit_data = themeMgr.get_unit(new_entity.node.unit_id)
			_debug_log("_place_units(): applying theme data to node='" + new_entity.node.name + "', unit_id='" + str(new_entity.node.unit_id) + "', pre_faction='" + str(new_entity.node.unit_faction) + "'")
			new_entity.node.fill_attributes(unit_data)
		elif new_entity.type == 'entity':
			_debug_log("_place_units(): no theme data found for node='" + new_entity.node.name + "', unit_id='" + str(new_entity.node.unit_id) + "'")

func _debug_log(message):
	if debug_logging:
		print("[Debug][Game] " + message)

# Build a database of tiles with look-up tables for neighbours and tileset information 
# to allow pathfinding and game logic to work.
# @returns {Array} List of all tiles on the map with precompiled information about every tile.
func _build_hex_object_database():
	var tiles = []
	var i = 0
	for tile in all_tiles:
		var tile_index = hexmap.get_tile_index(Vector2i(tile))
		tiles.append({
			'id': i,
			'grid_pos': tile,
			'terrain': hexmap._get_tile_attribute_by_index(tile_index, 'terrain'),
			'move_cost': hexmap._get_tile_attribute_by_index(tile_index, 'move_cost'),
			'name': hexmap._get_tile_attribute_by_index(tile_index, 'name'),
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

# Build and configure AStarGrid2D for hex pathfinding.
func _build_astar_grid():
	if all_tiles == null or all_tiles.is_empty():
		astar_grid = null
		return
	astar_grid = AStarGrid2D.new()
	var cell_shape_hex = 2
	if ClassDB.class_has_integer_constant("AStarGrid2D", "CELL_SHAPE_HEXAGON"):
		cell_shape_hex = ClassDB.class_get_integer_constant("AStarGrid2D", "CELL_SHAPE_HEXAGON")
	astar_grid.cell_shape = cell_shape_hex
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.cell_size = hexmap.get_cell_size()
	# Determine bounds for the grid region.
	var min_x = int(all_tiles[0].x)
	var max_x = int(all_tiles[0].x)
	var min_y = int(all_tiles[0].y)
	var max_y = int(all_tiles[0].y)
	for cell in all_tiles:
		min_x = mini(min_x, int(cell.x))
		max_x = maxi(max_x, int(cell.x))
		min_y = mini(min_y, int(cell.y))
		max_y = maxi(max_y, int(cell.y))
	astar_grid.region = Rect2i(Vector2i(min_x, min_y), Vector2i(max_x - min_x + 1, max_y - min_y + 1))
	astar_grid.update()
	# Build lookup tables for quick assignment.
	var tile_by_pos = {}
	for tile in tile_list:
		tile_by_pos[tile["grid_pos"]] = tile
	# Set weights for used tiles and mark unused tiles as solid.
	for cell in all_tiles:
		var tile = tile_by_pos.get(cell, null)
		if tile != null:
			astar_grid.set_point_weight_scale(cell, float(tile["move_cost"]))
	for x in range(astar_grid.region.position.x, astar_grid.region.position.x + astar_grid.region.size.x):
		for y in range(astar_grid.region.position.y, astar_grid.region.position.y + astar_grid.region.size.y):
			var pos = Vector2i(x, y)
			if not tile_by_pos.has(pos):
				astar_grid.set_point_solid(pos, true)

# Apply per-unit traversal rules and dynamic blockers (e.g. enemy units).
func _apply_astar_unit_constraints(moving_unit):
	if astar_grid == null:
		return
	var can_traverse = []
	if moving_unit != null and moving_unit.can_traverse != null:
		can_traverse = moving_unit.can_traverse
	var blocked_positions = {}
	if moving_unit != null:
		for current_entity in entities:
			if current_entity.type != "entity":
				continue
			if current_entity.node == moving_unit:
				continue
			if current_entity.node.is_container():
				continue
			if current_entity.node.has_method("get_unit_stance"):
				if current_entity.node.get_unit_stance() == "enemy":
					blocked_positions[current_entity.grid_pos] = true
			else:
				blocked_positions[current_entity.grid_pos] = true
	for tile in tile_list:
		var solid = false
		if not can_traverse.is_empty() and not can_traverse.has(tile["terrain"]):
			solid = true
		if blocked_positions.has(tile["grid_pos"]):
			solid = true
		astar_grid.set_point_solid(tile["grid_pos"], solid)

# Update all entity nodes with their internal update-method. There is still
# udpates going on in the main game script that handles grid-position tables
# etc.
# This is necessary because of inconvenient ready()-order in Godot
func _update_units():
	for current_entity in entities:
		if current_entity.type == 'entity':
			current_entity.node.update() 

# Check if the given position is a valid move-to destination for the given
# entity.
# @input {Vector2} Position to be checked
# @input {Object} The entity for which the validity of the destination is checked
# @returns {Boolean}
func _is_valid_destination(click_pos):
	var clicked_hex_object = self._get_hex_object_from_global_pos(click_pos)
	# print("Checking if clicked position is valid destination. Clicked hex object: " + str(clicked_hex_object))
	# Find out if there is a entity on the clicked tile that blocks movement.
	for current_entity in entities:
		if current_entity.grid_pos == clicked_hex_object.grid_pos and not current_entity.node.is_container():
			return false
	var target_terrain = clicked_hex_object.terrain
	# print("Clicked terrain: " + str(target_terrain))
	var unit_can_traverse = _get_entity_by_id(self.selected_unit).node.can_traverse
	# print("Unit can traverse: " + str(unit_can_traverse))
	if not target_terrain in unit_can_traverse:
		return false
	return true

# Get entity by given id
# Either returns an entity object or 'false'
func _get_entity_by_id(id):
	for current_entity in entities:
		if current_entity.id == id:
			return current_entity
	return false

# Get entities array index from node ID
# return the index of the entity corresponding to a node in the
# global entities array.
func _get_entity_index_from_node(node):
	for current_entity in entities:
		if current_entity.node.get_instance_id() == node.get_instance_id():
			return current_entity.id

# Get entity by grid position
# Returns an entity dictionary, empty if no entity found
func _get_entity_by_pos(pos) -> Dictionary:
	for current_entity in entities:
		if current_entity.grid_pos == Vector2i(pos):
			return current_entity
	return {}

# Create a list of all entities and their grid local positions as well as nodes
func _create_entity_list():
	var result = []
	var i = 0
	var allowed_node_types = ["entity", "editor_marker"]
	for node in self.get_children():
		# if node is of allowed type
		if "type" in node and node.type in allowed_node_types:
			node.set_id(i)
			node.initialize()
			if node is entity:
				node.game = self
				node.globals = globals
			var hex_object = self._get_hex_object_from_global_pos(node.get_global_position())
			var grid_pos = null
			if hex_object == null:
				grid_pos = hexmap.global_to_map(node.get_global_position())
				_debug_log("_create_entity_list(): no tile object for node='" + node.name + "', fallback grid_pos=" + str(grid_pos))
			else:
				grid_pos = hex_object.grid_pos
			result.append({
				"id": i,
				"node": node,
				"type": node.get_type(),
				"grid_pos": grid_pos
			})
			i += 1
	return result

# Public function to remove an entity entry that has been freed from the game
func remove_entity_from_list(node):
	var id = self._get_entity_index_from_node(node)
	var i = 0
	for current_entity in self.entities:
		if current_entity.id == id:
			self.entities.remove_at(i)
		i += 1

# Update an entity in the global list of entities and their grid local positions.
# This needs to be done after a entity has changed location, since all calculations
# that involve position, are done with help of this global list.
func update_entity_list_entry(current_entity):
	var hex_object = self._get_hex_object_from_global_pos(current_entity.node.get_global_position())
	if hex_object != null:
		current_entity.grid_pos = hex_object.grid_pos

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

# Mark that an attack was executed this turn.
func register_attack(_attacking_unit):
	attack_made_this_turn = true

# Return current music mood based on combat activity this turn.
func get_music_mood() -> String:
	return "battle" if attack_made_this_turn else "peace"

# Find first theme folder that contains a config.json.
func _find_first_theme_folder() -> String:
	var dir = DirAccess.open("res://themes")
	if dir == null:
		return "example-modern"
	var candidates = []
	dir.list_dir_begin()
	var name = dir.get_next()
	while name != "":
		if dir.current_is_dir() and not name.begins_with("."):
			var config_path = "res://themes/" + name + "/config.json"
			if FileAccess.file_exists(config_path):
				candidates.append(name)
		name = dir.get_next()
	dir.list_dir_end()
	if candidates.is_empty():
		return "example-modern"
	candidates.sort()
	return candidates[0]

# Convert offset (even-q) coordinates to cube coordinates for distance calc.
func _offset_to_cube(coord: Vector2i) -> Vector3i:
	var q = int(coord.x)
	var r = int(coord.y)
	var z = r - int((q + (q & 1)) / 2)
	var x = q
	var y = -x - z
	return Vector3i(x, y, z)

# Get hex distance between two grid positions.
func get_hex_distance(start: Vector2i, target: Vector2i) -> int:
	if start == target:
		return 0
	var a = _offset_to_cube(start)
	var b = _offset_to_cube(target)
	return maxi(absi(a.x - b.x), maxi(absi(a.y - b.y), absi(a.z - b.z)))

# Get the hex tile object by world position
# @input {Vector2} hex_position - global position of tile
# @returns {Object} The tile object
func _get_hex_object_from_global_pos(given_position):
	var grid_position = hexmap.global_to_map(given_position)
	for tile in tile_list:
		if tile['grid_pos'] == grid_position:
			return tile

# Get the hex tile object by grid local position
# @input {Vector2} hex_position - grid local position of tile
# @returns {Object} The tile object
func _get_hex_object_from_grid_pos(given_position: Vector2i):
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
func _poll_input_actions():
	# Use action polling only. This avoids event-type checks and keeps remapping flexible.
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()
		return
	if Input.is_action_just_pressed("mouse_click"):
		_handle_primary_click(get_global_mouse_position())

func _update_mouse_hover():
	var mouse_pos = get_global_mouse_position()
	if mouse_pos == _last_mouse_pos:
		return
	_last_mouse_pos = mouse_pos
	var tile = self._get_hex_object_from_global_pos(mouse_pos)
	# If tile is null, mouse was outside play area
	if tile == null:
		return
	hex_highlight.set_position(self.get_center_of_hex(hexmap.map_to_global(tile["grid_pos"])))
	GUI.update_tile_info(tile)

func _handle_primary_click(click_pos):
	### If clicked on empty spot on map, not on a entity or GUI
	var gui_click = GUI.is_gui_clicked()
	var map_click = self._is_tilemap(click_pos)
	var unit_click = self._is_unit(click_pos)
	if not unit_click and not gui_click and map_click:
		# Save tile information in local variable for easy access
		self.current_tile = self.get_tile(click_pos)
		# If a entity was previously selected
		if self.selected_unit != null:
			# If the selected entity can move and the player clicks on a valid target destination, 
			# the click sets the movement destination and triggers pathfinding to it.
			if self.movement_selection == true and self._is_valid_destination(click_pos) == true:
				var selected_entity = _get_entity_by_id(self.selected_unit)
				selected_entity.node.move_unit(selected_entity.node.get_global_position(), click_pos, selected_entity)
				self.movement_selection = false
	# if clicked on entity
	elif unit_click and not gui_click:
		var current_entity = self._is_unit(click_pos, true).node
		# if clicked entity is owned by player, select it and evaluate its possibilities
		if current_entity.owned_by_active_player():
			if self.resupply_selection == true:
				var player_unit = _get_entity_by_id(self.selected_unit).node
				# Check if, for the player entity, resupplying the click pos is possible, and if yes, do it.
				player_unit.resupply(click_pos)
				self.resupply_selection = false
			elif self.attack_selection == true:
				self.attack_selection = false
			else:
				self.selected_unit = current_entity
				self.selected_unit.select()
				# Update entity stats in GUI
				GUI.update_unit_info(current_entity.get_unit_name(), current_entity.get_strength_points(), current_entity.get_movement_points(), current_entity.get_ammo())
				# Enable or disable action buttons based on units attributes
				GUI.disable_movement_button(not current_entity.can_move())
				GUI.disable_attack_button((not current_entity.combat_ready() or not current_entity.can_move()))
				GUI.disable_supply_button(not current_entity.can_resupply())
		else:
			# if clicked entity is not owned by player, see if a player-owned entity is selected...
			if self.selected_unit != null:
				var player_unit = _get_entity_by_id(self.selected_unit).node
				# If in attack mode
				if self.attack_selection == true:
					# Check if, for the player entity the click pos is a valid attack target
						if player_unit.is_valid_attack_target(click_pos):
							var enemy_unit = self._is_unit(click_pos, true).node
							player_unit.attack(enemy_unit)
							self.register_attack(player_unit)
							self.attack_selection = false
							# Deselect all selectable entities
							self.deselect_all_entities()

			##### On click on two tiles, flood fill the map and get path from first to second click
#			if click_counter < 1:
#				print('First click')
#				# On first click, determine start position
#				start_position = click_pos
#				# increment click counter
#				click_counter += 1
#				# color clicked (starting) tile red
#				var vis_start_tile = self._get_hex_object_from_global_pos(start_position)
#				self._set_hex_fill(hexmap.map_to_global(vis_start_tile.grid_pos), 'red', 'path_vis')
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
			GUI._show_tile_info_popup(_get_hex_object_from_global_pos(click_pos))
			GUI._show_tile_info_popup(current_tile)

# Process the current turn
func _end_turn():
	deselect_all_entities()
	_update_all_entities()
	_advance_player_rotation()
	turn_counter += 1
	attack_made_this_turn = false

# Internal function to update all entities, based on type or other criteria.
# Should ideally only be done once, so use this function for alle updates that should
# occur globally once in a turn.
func _update_all_entities():
	for current_entity in self.entities:
		print('Check entity: ',current_entity)
		if current_entity.type == 'entity':
			current_entity.node.reset_movement_points()
			current_entity.node.update_timed_modifiers()
		elif current_entity.type == 'editor_marker':
			if current_entity.node.get_marker_type() == 'VICTORY':
				current_entity.node.check_ownership()

# Internal function to advance player rotation, normally when turn ends.
func _advance_player_rotation():
	var _player_active = false
	var _next_player = ''
	# first call of this function
	if players.size() != self.player_rotation.size():
		# set first human player as active
		for i in range(players.size()):
			var player = players[i]
			if player.node.is_human() and self.active_player == null:
				player.node.set_active(true)
				self.active_player = player.node
				self.active_player_rot_index = i
			# fill player rotation once
			self.player_rotation.append(player.node.get_id())
		# for the initial call of this function, nothing more needs to
		# be done, exit here.
		return true
	# if this is not the initial call of this function, determine next player
	else:
		var _next_player_id = null
		if self.active_player_rot_index == self.player_rotation.size()-1:
			self.active_player_rot_index = 0
		else:
			self.active_player_rot_index += 1
		self.active_player.set_active(false)
		self.active_player = playerMgr.get_player_by_id(self.player_rotation[self.active_player_rot_index]).node
		self.active_player.set_active(true)
		print('Round ended. Current player is now ' + str(self.active_player.get_player_name()))
		return true

func _physics_process(_delta):
	_poll_input_actions()
	_update_mouse_hover()
	if active_player != null:
		label_player.set_text(str(active_player.get_id()))
	if turn_counter:
		label_turn.set_text(str(turn_counter))

# Check if there is a tilemap at the given position.
# Use this to wrap up input loop, to avoid NPE when clicked outside tilemap.
# Offers strict mode (check if no entity at given coords) or standard
# mode, which just checks that no entity of type entity is a the given coords.
#
# Background: The move logic allows moving onto certain types of entities
# (e.g. map logic entities like cities), but not others (units, mainly). 
# In this case it is necessary to check if there is a entity at the given coords
# or "something else", which qualifies as "tilemap" in this case.
#
# @input {Vector2} position of the click to check for tilemap
# @input {Boolean} (optional) Strict mode, checks against entities.
# @returns {Boolean} return true if there is no entity at given coords
func _is_tilemap(given_position, strict_mode=false):
	var tile = _get_hex_object_from_global_pos(given_position)
	var current_entity = _get_entity_by_pos(given_position)
	# Tilemap at given position
	if tile != null and tile.size() > 1:
		# print("Found tilemap at given coords")
		# If a entity was found at the given coords
		if current_entity:
			# If strict mode enabled, return 'false' if any entity exists at given coords.
			# Per default, only return 'false' if a entity of type 'entity' is found.
			if strict_mode:
				# print("Found entity in strict mode, no tilemap hit.")
				return false
			else:
				# print("Did I find a entity?" + str(!(current_entity.node.get_type() == 'entity')))
				return !(current_entity.node.get_type() == 'entity')
		return true
	return false

# Determine if there is a entity at the grid local position that is given.
# @input {Vector2} position of the click to check for entity
# @input {Boolean} (optional) return entity object if true
# @returns {Boolean | Object} return true if there is a entity at given coords
# or the entity instance itself
func _is_unit(given_position, return_unit=false):
	var grid_position = hexmap.global_to_map(given_position)
	for every_entity in entities:
		if every_entity.node.get_type() == 'entity':
			if every_entity.grid_pos == grid_position:
				if return_unit == true:
					# print("Found entity at location "+str(every_entity.node.get_global_position()))
					# print(every_entity)
					return every_entity
				else:
					return true
	return false

# Deselects all selectable entities on the map 
func deselect_all_entities():
	for every_entity in entities:
		if every_entity.node.has_method('is_selected') and every_entity.node.is_selected():
			# If a entity is deselected, deactivate the action buttons in GUI
			if every_entity.type == 'entity':
				GUI.disable_movement_button(true)
				GUI.disable_attack_button(true)
				GUI.disable_supply_button(true)
				GUI.update_unit_info("","","","")
			every_entity.node.deselect()
			self.selected_unit = null

# Getter for unit_selected. This is faster than iterating over all
# units and check each for its 'selected' states
# @returns {Boolean} Returns true if a entity was selected.
func _is_unit_selected():
	for every_entity in entities:
		if every_entity.type == 'entity':
			if every_entity.node.is_selected():
				return true
	return false

# Method to return a tiles attributes as defined in tilemap.gd
# @input {Vector2} global click position
# @returns {Object} the tile object
func get_tile(given_position):
	# Calculate grid position from world position
	var grid_pos = hexmap.global_to_map(given_position)
	# Get tile attributes based on tileset index
	var tile = hexmap._get_tile_attributes_by_index(hexmap.get_tile_index(Vector2i(grid_pos)))
	# Enrich the returned tile object for debugging purposes
	tile.index = hexmap.get_tile_index(Vector2i(grid_pos))
	tile.position = grid_pos
	return tile

# Method to draw a outline on one tile at a time to highlight it
# @input {Vector2} position - of the click in global coordinates
func highlight_hex(given_position):
	# get grid local coordinates of hexagon from global click coordinates
	var global_hex_position = hexmap.global_to_map(given_position)
	# get global coordinates of hexagon from grid local coordinates
	var hex_world_pos = hexmap.map_to_global(global_hex_position)
	# calculate global position of hexagon highlight by adding half the cell size to the global hex position plus offset
	var highlight_pos = get_center_of_hex(hex_world_pos)
	hex_marker.set_position(highlight_pos)

# Returns the centered position of the tile, whose position is given
# @input {Vector2} global position of hex
# @output {Vector2} global position of center of hex
func get_center_of_hex(given_position):
	return Vector2(given_position.x + self.hex_offset.x,
				   given_position.y + self.hex_offset.y)

# Determine path from tile to tile, all coordinates are global
# @input {Vector2} start_position, from this the start tile is derived
# @input {Vector2} target_position, from this the target tile is derived
# @returns {Array} path to the target tile
func find_path(start_position, target_position, moving_unit = null) -> Array:
	if astar_grid == null:
		_build_astar_grid()
	if astar_grid == null:
		return []
	_apply_astar_unit_constraints(moving_unit)
	var start_grid = hexmap.global_to_map(start_position)
	var target_grid = hexmap.global_to_map(target_position)
	var start_tile = self._get_hex_object_from_grid_pos(start_grid)
	var target_tile = self._get_hex_object_from_grid_pos(target_grid)
	if start_tile == null or target_tile == null:
		return []
	var id_path = astar_grid.get_id_path(start_grid, target_grid)
	if id_path.is_empty():
		return []
	var path: Array = []
	for grid_pos in id_path:
		var grid_pos_i = Vector2i(int(grid_pos.x), int(grid_pos.y))
		var tile = self._get_hex_object_from_grid_pos(grid_pos_i)
		if tile != null:
			path.append(tile)
	return path

# Helper function to help visualize the working of the flood fill
# @input {Vector2} The grid local position of the tile to mark
# @input {int} A counter to render onto the tile, that shows the order of flood filling
func _mark_grid_position(grid_position, counter):
	var new_marker = marker.duplicate()
	var counter_label = Label.new()
	var hex_world_pos = hexmap.map_to_global(Vector2i(grid_position))
	var marker_pos = get_center_of_hex(hex_world_pos)
	counter_label.set_text(str(counter))
	new_marker.set_position(marker_pos)
	counter_label.set_position(Vector2(marker_pos.x, marker_pos.y + 15))
	self.add_child(new_marker)
	self.add_child(counter_label)
	counter_label.set_owner(get_tree().get_edited_scene_root())
	new_marker.set_owner(get_tree().get_edited_scene_root())

#################################################################################
# These methods are for debug purposes only
# They should either be deleted, cleaned and integrated or very well hidden away
#################################################################################

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
				self._set_hex_fill(hexmap.map_to_global(tile.grid_pos), 'green', 'path_vis')
		# color last tile red (for "stop here")
		elif tile == path[path.size()-1]:
			self._set_hex_fill(hexmap.map_to_global(tile.grid_pos), 'red', 'path_vis')
		# color all other tiles blue
		else:
			self._set_hex_fill(hexmap.map_to_global(tile.grid_pos), 'blue', 'path_vis')


# Helper to delete all nodes that start with a certain string.
# This will search for given name_fragment plus @-sign in front because
# dynamically added nodes are auto-prefixed by this sign by Godot.
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
	var logfile = FileAccess.open(log_path + filename + file_ending, FileAccess.READ_WRITE)
	if logfile == null:
		return
	logfile.seek_end() # Find end
	logfile.store_string('\n') # Newline
	if message:
		logfile.store_string(str(message))

# Used to display additional information on top of the tile, also create a new marker on every
# tile click and does not delete the old one
# @input {Vector2} Global position of the tile
# @input {Color} Color of the markers created
# @input {Bool} If the coordinates should be rendered onto the tile
func highlight_every_hex(given_position, marker_color, show_coords):
	# get grid local coordinates of hexagon from global click coordinates
	var global_hex_position = hexmap.global_to_map(given_position)
	# get global coordinates of hexagon from grid local coordinates
	var hex_world_pos = hexmap.map_to_global(global_hex_position)
	# calculate global position of hexagon highlight by adding half the cell size to the global hex position plus offset
	var highlight_pos = get_center_of_hex(hex_world_pos)
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
		global_pos_label.set_text(str(hex_world_pos))
		grid_pos_label.set_text(str(global_hex_position))
		# add the elements to scene
		self.add_child(global_pos_label)
		self.add_child(grid_pos_label)
		global_pos_label.set_owner(get_tree().get_edited_scene_root())
		grid_pos_label.set_owner(get_tree().get_edited_scene_root())

# Create a highlight marker on a given hex that stays.
# This looks different than the hex highlight in that it
# overlays the whole hex with a transparent colored fill
# @input {Vector2} global position of the hex tile
# @input {Color} Color of the markers created
# @input {String} (optional) Name of the marker node
func _set_hex_fill(hex_world_pos, marker_color, opt_name=null):
	var highlight_pos = get_center_of_hex(hex_world_pos)
	# duplicate the highlight
	var new_hex_fill = hex_fill.duplicate()
	if opt_name != null:
		new_hex_fill.set_name(opt_name)
	new_hex_fill.set_modulate(globals.getColor(str(marker_color)))
	# position the highlight
	new_hex_fill.set_position(highlight_pos)
	# add the highlight to scene
	self.add_child(new_hex_fill)
	new_hex_fill.set_owner(get_tree().get_edited_scene_root())
# Highlight the neighbours of a hex tile at a given global position
# @input {Vector2} global position of the tile
func _highlight_neighbours(given_global_position):
	var selected_tile = self._get_hex_object_from_global_pos(given_global_position)
	for neighbour_entry in selected_tile['neighbours']:
		if selected_tile.neighbours[neighbour_entry] != null:
			var neighbour_grid_pos = Vector2i(selected_tile.neighbours[neighbour_entry])
			var neighbour_tile_pos = hexmap.map_to_global(neighbour_grid_pos)
			self._set_hex_fill(neighbour_tile_pos, 'red')

# Debug method to write every tile and its tilemap index into a file for checking.
# Per default the file is res://tiles.txt and it mus exist before calling this method.
# @input {Tilemap} tilemap for which all used tiles should be exported
func _export_tile_list(tilemap):
	var myfile = FileAccess.open("res://tiles.txt", FileAccess.WRITE)
	if myfile == null:
		return
	print('Start exporting tiles')
	myfile.store_string(str(tilemap.get_used_cells()))
	print('Done storing')

# Renders red dot at hex tile with id, relative to given parent
# @input {int} id of the hex tile to render the dot on
# @input {Object} parent node of the created sprite
func _render_dot(id):
	var new_marker = marker.duplicate()
	var tile = self._get_hex_object_from_id(id)
	var given_position = self.get_center_of_hex(hexmap.map_to_global(tile["grid_pos"]))
	new_marker.set_position(given_position)
	self.add_child(new_marker)
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
	var grid_pos = hexmap.global_to_map(given_position)
	# grid position back to global position
	var global_pos = hexmap.map_to_global(grid_pos)
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
func _display_hex_info(input_coordinates):
	var new_label = Label.new()
	var grid_pos = Vector2i(input_coordinates[0], input_coordinates[1])
	var tile_world_pos = hexmap.map_to_global(grid_pos)
	new_label.set_text(str(hexmap.get_tile_index(grid_pos)))
	new_label.set_position(tile_world_pos)
	self.add_child(new_label)
	new_label.set_owner(get_tree().get_edited_scene_root())

# Render given information onto the tile itself
# @input {Vector2} input_coordinates - grid local coordinates of tile
# @input {String} String that should be rendered on the tile
# @input {String} String that should be used as name for the created node
func _render_on_tile(input_coordinates, info, opt_name):
	var new_label = Label.new()
	var tile_world_pos = hexmap.map_to_global(Vector2i(input_coordinates[0], input_coordinates[1]))
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
	var grid_pos = Vector2i(grid_coordinates[0], grid_coordinates[1])
	new_label.set_text(str(hexmap._get_tile_attributes_by_index(hexmap.get_tile_index(grid_pos))['name']))
	# Set pos
	var tile_world_pos = hexmap.map_to_global(grid_pos)
	tile_world_pos.y += hexmap.get_cell_size().y / 2.0
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
	if self.grid_visible:
		from_opacity = Color(1, 1, 1, 0.3)
		to_opacity = Color(1, 1, 1, 0)
		self.grid_visible = false
	else:
		from_opacity = Color(1, 1, 1, 0)
		to_opacity = Color(1, 1, 1, 0.3)
		self.grid_visible = true
	hex_grid.modulate = from_opacity
	var grid_tween = create_tween()
	grid_tween.set_trans(Tween.TRANS_LINEAR)
	grid_tween.set_ease(Tween.EASE_IN_OUT)
	grid_tween.tween_property(hex_grid, "modulate", to_opacity, 2.0)

func _on_EndTurnButton_pressed():
	_end_turn()
