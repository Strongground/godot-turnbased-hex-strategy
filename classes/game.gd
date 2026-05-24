extends Node2D

signal setup_complete

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
@onready var range_overlay = find_child('RangeOverlay')
@onready var arrow_marker = find_child('Arrow')
@onready var GUI = find_child('GUI')
@export var hex_highlight: Node2D
@export var map_graphic: Sprite2D
var map_size = null
var tile_list = null
var current_tile = null
var hex_directions = null
var all_tiles = null
var astar_grid: AStarGrid2D = null
var entities = []
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
@export var debug_show_move_costs = false
## Loop vars
var turn_counter = 0
var active_player = null
var active_player_rot_index = -1
var player_rotation = []
var players = []
var _last_mouse_pos = Vector2(INF, INF)
var _setup_complete: bool = false
## Game Resource Managers
@export var playerMgr: Node
@export var factionMgr: Node
@export var themeMgr: Node
@export var musicMgr: Node
@export var settingsMgr: Node
@export var sfxMgr: Node
@export var weatherMgr: Node
## debug labels
const RANGE_VIS_NODE_NAME = "range_vis"
@onready var label_player = find_child('CurrentPlayer')
@onready var label_turn = find_child('CurrentTurn')

func _ready():
	if globals == null:
		globals = get_node_or_null("/root/globals")
	_ensure_launch_selection_context()
	_debug_log("_ready(): start")

	# Determine map size and make it public for easier access
	self.map_size = map_graphic.get_rect().size * map_graphic.get_scale()
	
	# Disable physics during initialization to prevent accessing uninitialized data
	set_process(false)
	
	# Initialize managers in dependency order
	# This prevents race conditions where one manager calls another before it's ready
	_debug_log("_ready(): initializing managers...")
	await _initialize_managers()
	
	# Now proceed with game setup
	_setup_game()
	print_debug("[Game] Globals initialized: selected_theme='" + globals.selected_theme + "', selected_scenario='" + globals.selected_scenario + "'")
	
	# Re-enable physics after setup is complete
	set_process(true)
	GUI.set_visible(true)
	_setup_complete = true
	emit_signal("setup_complete")
	_debug_log("_ready(): initialization complete")

func _ensure_launch_selection_context() -> void:
	if globals == null:
		return

	var scene_path = _get_current_scene_path()
	if scene_path == "":
		return

	if globals.selected_theme_folder == "":
		var theme_folder = _derive_theme_folder_from_scene_path(scene_path)
		if theme_folder != "":
			globals.set_selected_theme(theme_folder, theme_folder)
			_debug_log("_ensure_launch_selection_context(): inferred theme='" + theme_folder + "' from scene path")

	if globals.selected_scenario == "":
		var scenario_id = scene_path.get_file().get_basename()
		globals.set_selected_scenario(scenario_id, scene_path)
		_debug_log("_ensure_launch_selection_context(): inferred scenario='" + scenario_id + "' from scene path")

func _get_current_scene_path() -> String:
	if scene_file_path != "":
		return scene_file_path
	var current_scene = get_tree().current_scene
	if current_scene != null:
		return str(current_scene.scene_file_path)
	return ""

func _derive_theme_folder_from_scene_path(scene_path: String) -> String:
	var path_parts = scene_path.split("/")
	var themes_index = path_parts.find("themes")
	if themes_index != -1 and themes_index + 1 < path_parts.size():
		return path_parts[themes_index + 1]
	return ""

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
			current_entity.node._snap_to_grid()
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
	var unit_can_traverse = get_selected_unit().can_traverse
	# print("Unit can traverse: " + str(unit_can_traverse))
	if not target_terrain in unit_can_traverse:
		return false
	return true

# Public getter for currently selected unit
func get_selected_unit() -> Node:
	if self.selected_unit == null:
		return null
	var _selected_unit = _get_entity_by_id(self.selected_unit)
	if _selected_unit and _selected_unit.node and is_instance_valid(_selected_unit.node):
		return _selected_unit.node
	return null

# Public setter for selected unit
# @input entity_id:String The ID of the entity that is currently selected, as stored in the game class.
func set_selected_unit(entity_id) -> void:
	if entity_id == null:
		selected_unit = null
		return
	var _selected_unit = _get_entity_by_id(entity_id)
	if _selected_unit and _selected_unit.node and is_instance_valid(_selected_unit.node):
		selected_unit = _selected_unit
	else:
		selected_unit = null	

# Get entity node by given id
# @input id:String
# @returns Node|Boolean 
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
			if node is Entity:
				node.game = self
				node.globals = globals
				if node.type == "entity":
					node.settingsMgr = settingsMgr
					node.themeMgr = themeMgr
					node.gui = GUI
					node.sfxMgr = sfxMgr
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
	if tile_list == null or tile_list.is_empty():
		return null
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
	if tile_list == null or tile_list.is_empty():
		return
	var tile = self._get_hex_object_from_global_pos(mouse_pos)
	# If tile is null, mouse was outside play area
	if tile == null:
		return
	hex_highlight.set_position(self.get_center_of_hex(hexmap.map_to_global(tile["grid_pos"])))

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
				if selected_entity and selected_entity.node != null:
					selected_entity.node.move_unit(selected_entity.node.get_global_position(), click_pos, selected_entity)
				_clear_action_selection_modes()
	# if clicked on entity
	elif unit_click and not gui_click:
		var current_entity = self._is_unit(click_pos, true).node
		# if clicked entity is owned by player, select it and evaluate its possibilities
		if current_entity.owned_by_active_player():
			if self.resupply_selection == true:
				var player_unit = _get_entity_by_id(self.selected_unit).node
				# Check if, for the player entity, resupplying the click pos is possible, and if yes, do it.
				player_unit.resupply(click_pos)
				_clear_action_selection_modes()
			elif self.attack_selection == true:
				_clear_action_selection_modes()
			else:
				_clear_action_selection_modes()
				current_entity.select()
				_refresh_selected_unit_ui()
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
						_clear_action_selection_modes()
						# Deselect all selectable entities
						self.deselect_all_entities()

# Process the current turn
func _end_turn():
	deselect_all_entities()
	_update_all_entities()
	_advance_player_rotation()
	weatherMgr.process_turn()
	turn_counter += 1
	attack_made_this_turn = false

# Internal function to update all entities, based on type or other criteria.
# Should ideally only be done once, so use this function for alle updates that should
# occur globally once in a turn.
func _update_all_entities():
	for current_entity in self.entities:
		if current_entity.type == 'entity':
			current_entity.node.reset_movement_points()
			current_entity.node.update_timed_modifiers()
		elif current_entity.type == 'editor_marker':
			current_entity.node.check_ownership()

# Internal function to advance player rotation, normally when turn ends.
func _advance_player_rotation():
	var _player_active = false
	var _next_player = ''
	if players.is_empty():
		push_warning("Game: Cannot advance player rotation because no players were loaded for the current scenario.")
		return false
	# first call of this function
	if self.player_rotation.is_empty() or self.active_player == null:
		self.player_rotation.clear()
		# set first human player as active
		for i in range(players.size()):
			var player = players[i]
			if player.node.is_human() and self.active_player == null:
				player.node.set_active(true)
				self.active_player = player.node
				self.active_player_rot_index = i
			# fill player rotation once
			self.player_rotation.append(player.node.get_id())
		if self.active_player == null:
			self.active_player = players[0].node
			self.active_player.set_active(true)
			self.active_player_rot_index = 0
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
	_refresh_selected_unit_ui()
	if active_player != null:
		label_player.set_text(str(active_player.get_id()))
	if turn_counter:
		label_turn.set_text(str(turn_counter))

func _clear_action_selection_modes() -> void:
	movement_selection = false
	attack_selection = false
	resupply_selection = false
	_clear_range_highlights()

# Enable/disable movement targeting mode and render possible movement range.
# @input {Boolean} enabled - true to activate movement mode, false to disable
# @returns {Void}
func set_movement_selection_mode(enabled: bool) -> void:
	if not enabled:
		movement_selection = false
		_clear_range_highlights()
		return
	if self.selected_unit == null:
		return
	movement_selection = true
	attack_selection = false
	resupply_selection = false
	_show_movement_range_for_selected()

# Enable/disable attack targeting mode and render attack range.
# @input {Boolean} enabled - true to activate attack mode, false to disable
# @returns {Void}
func set_attack_selection_mode(enabled: bool) -> void:
	if not enabled:
		attack_selection = false
		_clear_range_highlights()
		return
	if self.selected_unit == null:
		return
	movement_selection = false
	attack_selection = true
	resupply_selection = false
	_show_attack_range_for_selected()

# Enable/disable resupply targeting mode.
# @input {Boolean} enabled - true to activate resupply mode, false to disable
# @returns {Void}
func set_resupply_selection_mode(enabled: bool) -> void:
	if not enabled:
		resupply_selection = false
		_clear_range_highlights()
		return
	movement_selection = false
	attack_selection = false
	resupply_selection = true
	_clear_range_highlights()

# Remove all temporary range highlight markers from the scene.
# @returns {Void}
func _clear_range_highlights() -> void:
	if range_overlay != null and range_overlay.has_method("clear_highlights"):
		range_overlay.clear_highlights()
		return
	_delete_all_nodes_with(RANGE_VIS_NODE_NAME)

# Render range highlights for a list of grid positions.
# @input {Array} grid_positions - grid local tile positions
# @input {String} color_name - named color for highlight
# @input {float} opacity - fill opacity from 0.0 to 1.0
# @returns {Void}
func _render_range_highlights(grid_positions: Array, color_name: String, opacity: float = 0.35) -> void:
	if range_overlay != null and range_overlay.has_method("set_highlight_tiles"):
		range_overlay.set_highlight_tiles(grid_positions, hexmap, globals, color_name, opacity)
		return
	for grid_pos in grid_positions:
		_set_hex_fill(hexmap.map_to_global(grid_pos), color_name, RANGE_VIS_NODE_NAME, opacity)

# Render movement range for currently selected unit.
# @returns {Void}
func _show_movement_range_for_selected() -> void:
	_clear_range_highlights()
	if self.selected_unit == null:
		return
	var selected_entity = _get_entity_by_id(self.selected_unit)
	if not selected_entity or selected_entity.node == null:
		return
	var selected_unit_node = selected_entity.node
	if not selected_unit_node.can_move():
		return
	var reachable_tiles = _get_reachable_movement_tiles(selected_entity)
	_render_range_highlights(reachable_tiles, "blue", 0.0)

# Render attack range for currently selected unit.
# For multiple weapons, the highlighted range is the union of all weapon ranges.
# @returns {Void}
func _show_attack_range_for_selected() -> void:
	_clear_range_highlights()
	if self.selected_unit == null:
		return
	var selected_entity = _get_entity_by_id(self.selected_unit)
	if not selected_entity or selected_entity.node == null:
		return
	var selected_unit_node = selected_entity.node
	if not selected_unit_node.combat_ready():
		return
	var ranges: Array = []
	if selected_unit_node.has_method("get_attack_ranges"):
		ranges = selected_unit_node.get_attack_ranges()
	if ranges.is_empty():
		return
	var attack_tiles: Array = []
	for tile in tile_list:
		if tile["grid_pos"] == selected_entity.grid_pos:
			continue
		var distance = get_hex_distance(selected_entity.grid_pos, tile["grid_pos"])
		for weapon_range in ranges:
			if distance <= int(weapon_range):
				if not attack_tiles.has(tile["grid_pos"]):
					attack_tiles.append(tile["grid_pos"])
				break
	_render_range_highlights(attack_tiles, "red", 0.0)

# Calculate all reachable movement target tiles in one pass.
# Uses a Dijkstra-style traversal over hex neighbours and movement costs.
# @input {Object} selected_entity - selected entity object from entities list
# @returns {Array} array of reachable grid positions (Vector2i)
func _get_reachable_movement_tiles(selected_entity) -> Array:
	var result: Array = []
	if selected_entity == null or selected_entity.node == null or tile_list == null:
		return result
	if tile_list == null:
		return result
	var selected_unit_node = selected_entity.node
	var max_points = float(selected_unit_node.get_movement_points())
	if max_points <= 0:
		return result

	var tile_by_pos = {}
	for tile in tile_list:
		tile_by_pos[tile["grid_pos"]] = tile

	var blocked_path_positions = _get_blocked_path_positions(selected_unit_node)
	var occupied_target_positions = _get_occupied_target_positions(selected_unit_node)

	var best_cost = {}
	var open_list: Array = [{"pos": selected_entity.grid_pos, "cost": 0.0}]
	best_cost[selected_entity.grid_pos] = 0.0

	while not open_list.is_empty():
		var best_index = 0
		for i in range(1, open_list.size()):
			if float(open_list[i]["cost"]) < float(open_list[best_index]["cost"]):
				best_index = i
		var current = open_list[best_index]
		open_list.remove_at(best_index)

		var current_pos: Vector2i = current["pos"]
		var current_cost = float(current["cost"])
		if current_cost > float(best_cost.get(current_pos, current_cost)):
			continue

		var open_tile = tile_by_pos.get(current_pos, null)
		if open_tile == null:
			continue

		for neighbour_key in open_tile["neighbours"]:
			var neighbour_grid = open_tile["neighbours"][neighbour_key]
			if neighbour_grid == null:
				continue
			var neighbour_pos = Vector2i(neighbour_grid)
			var neighbour_tile = tile_by_pos.get(neighbour_pos, null)
			if neighbour_tile == null:
				continue
			if not selected_unit_node.can_traverse.has(neighbour_tile["terrain"]):
				continue
			if blocked_path_positions.has(neighbour_pos):
				continue

			var next_cost = current_cost + float(neighbour_tile["move_cost"])
			if next_cost > max_points:
				continue
			if best_cost.has(neighbour_pos) and float(best_cost[neighbour_pos]) <= next_cost:
				continue

			best_cost[neighbour_pos] = next_cost
			open_list.append({"pos": neighbour_pos, "cost": next_cost})

			if neighbour_pos != selected_entity.grid_pos and not occupied_target_positions.has(neighbour_pos):
				if not result.has(neighbour_pos):
					result.append(neighbour_pos)

	return result

# Build set of blocked positions for movement pathing.
# Blocks enemy entities but allows traversal through allies (existing gameplay behavior).
# @input {Object} selected_unit_node - currently selected unit node
# @returns {Dictionary} map of blocked grid positions -> true
func _get_blocked_path_positions(selected_unit_node) -> Dictionary:
	var blocked_positions = {}
	for current_entity in entities:
		if current_entity.type != "entity":
			continue
		if current_entity.node == selected_unit_node:
			continue
		if current_entity.node.is_container():
			continue
		if current_entity.node.has_method("get_unit_stance"):
			if current_entity.node.get_unit_stance() == "enemy":
				blocked_positions[current_entity.grid_pos] = true
		else:
			blocked_positions[current_entity.grid_pos] = true
	return blocked_positions

# Build set of occupied target positions that cannot be move destinations.
# @input {Object} selected_unit_node - currently selected unit node
# @returns {Dictionary} map of occupied grid positions -> true
func _get_occupied_target_positions(selected_unit_node) -> Dictionary:
	var occupied_positions = {}
	for current_entity in entities:
		if current_entity.type != "entity":
			continue
		if current_entity.node == selected_unit_node:
			continue
		if current_entity.node.is_container():
			continue
		occupied_positions[current_entity.grid_pos] = true
	return occupied_positions

# Keep GUI values and action button states synced to selected unit.
# @returns {Void}
func _refresh_selected_unit_ui() -> void:
	if GUI == null:
		return
	if self.selected_unit == null:
		_clear_range_highlights()
		GUI.disable_movement_button(true)
		GUI.disable_attack_button(true)
		GUI.disable_supply_button(true)
		GUI.update_unit_info("", "", "", "")
		return
	var selected_entity = _get_entity_by_id(self.selected_unit)
	if not selected_entity or selected_entity.node == null:
		_clear_range_highlights()
		GUI.disable_movement_button(true)
		GUI.disable_attack_button(true)
		GUI.disable_supply_button(true)
		GUI.update_unit_info("", "", "", "")
		return
	var current_unit = selected_entity.node
	GUI.update_unit_info(
		current_unit.get_unit_name(),
		current_unit.get_strength_points(),
		current_unit.get_movement_points(),
		current_unit.get_ammo()
	)
	var is_busy = false
	if current_unit.has_method("is_busy_state"):
		is_busy = current_unit.is_busy_state()
	elif current_unit.has_method("can_receive_orders"):
		is_busy = not current_unit.can_receive_orders()
	if is_busy:
		_clear_action_selection_modes()
	GUI.disable_movement_button(is_busy or not current_unit.can_move())
	GUI.disable_attack_button(is_busy or (not current_unit.combat_ready() or not current_unit.can_move()))
	GUI.disable_supply_button(is_busy or not current_unit.can_resupply())

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
	_clear_action_selection_modes()

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
	return Vector2(given_position.x,
				   given_position.y)

# Determine path from tile to tile, all coordinates are global
# @input {Vector2} start_position, from this the start tile is derived
# @input {Vector2} target_position, from this the target tile is derived
# @returns {Array} path to the target tile
func find_path(start_position, target_position, moving_unit = null) -> Array:
	var start_grid = hexmap.global_to_map(start_position)
	var target_grid = hexmap.global_to_map(target_position)
	return _find_path_on_hex(start_grid, target_grid, moving_unit)

# Pathfinding over the same hex adjacency used for range finding.
# @input {Vector2i} start_grid
# @input {Vector2i} target_grid
# @input {Object} moving_unit
# @returns {Array} tile objects for the path (including start + target)
func _find_path_on_hex(start_grid: Vector2i, target_grid: Vector2i, moving_unit = null) -> Array:
	var path: Array = []
	if start_grid == target_grid:
		return path
	var tile_by_pos = {}
	for tile in tile_list:
		tile_by_pos[tile["grid_pos"]] = tile
	if not tile_by_pos.has(start_grid) or not tile_by_pos.has(target_grid):
		return path
	var blocked_positions = {}
	if moving_unit != null:
		blocked_positions = _get_blocked_path_positions(moving_unit)
	var can_traverse: Array = []
	if moving_unit != null and moving_unit.can_traverse != null:
		can_traverse = moving_unit.can_traverse

	var open_list: Array = [{"pos": start_grid, "cost": 0.0}]
	var best_cost = {start_grid: 0.0}
	var came_from: Dictionary = {}

	while not open_list.is_empty():
		var best_index = 0
		for i in range(1, open_list.size()):
			if float(open_list[i]["cost"]) < float(open_list[best_index]["cost"]):
				best_index = i
		var current = open_list[best_index]
		open_list.remove_at(best_index)
		var current_pos: Vector2i = current["pos"]
		if current_pos == target_grid:
			break
		var current_tile = tile_by_pos.get(current_pos, null)
		if current_tile == null:
			continue
		for neighbour_key in current_tile["neighbours"]:
			var neighbour_grid = current_tile["neighbours"][neighbour_key]
			if neighbour_grid == null:
				continue
			var neighbour_pos = Vector2i(neighbour_grid)
			var neighbour_tile = tile_by_pos.get(neighbour_pos, null)
			if neighbour_tile == null:
				continue
			if not can_traverse.is_empty() and not can_traverse.has(neighbour_tile["terrain"]):
				continue
			if blocked_positions.has(neighbour_pos):
				continue
			var next_cost = float(best_cost.get(current_pos, 0.0)) + float(neighbour_tile["move_cost"])
			if not best_cost.has(neighbour_pos) or next_cost < float(best_cost[neighbour_pos]):
				best_cost[neighbour_pos] = next_cost
				came_from[neighbour_pos] = current_pos
				open_list.append({"pos": neighbour_pos, "cost": next_cost})

	if not came_from.has(target_grid):
		return []
	var grid_path: Array = []
	var cursor = target_grid
	grid_path.append(cursor)
	while cursor != start_grid:
		if not came_from.has(cursor):
			return []
		cursor = came_from[cursor]
		grid_path.append(cursor)
	grid_path.reverse()
	for grid_pos in grid_path:
		var tile = tile_by_pos.get(grid_pos, null)
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
# Handles both prefixed ("@name") and plain runtime node names.
# @input {String} name_fragment - nodes with matching prefix are deleted
# @returns {Void}
func _delete_all_nodes_with(name_fragment):
	print("Deleting all nodes with name starting with '" + name_fragment + "'")
	for node in self.get_children():
		var node_name = str(node.get_name())
		if node_name.begins_with('@' + name_fragment) or node_name.begins_with(name_fragment):
			print("Deleting node: " + node_name)
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
# @input {String} Color name of the marker
# @input {String} (optional) Name of the marker node
# @input {float} (optional) Opacity from 0.0 to 1.0
# @returns {Void}
func _set_hex_fill(hex_world_pos, marker_color, opt_name=null, opt_opacity=1.0):
	var highlight_pos = get_center_of_hex(hex_world_pos)
	# duplicate the highlight
	var new_hex_fill = hex_fill.duplicate()
	if opt_name != null:
		new_hex_fill.set_name(opt_name)
	new_hex_fill.set_modulate(globals.getColor(str(marker_color), float(opt_opacity)))
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

# Debug helper: render movement costs on every tile.
func _display_move_costs() -> void:
	_delete_all_nodes_with("move_cost_label")
	for tile in tile_list:
		var new_label = Label.new()
		new_label.set_text(str(tile["move_cost"]))
		new_label.set_name("move_cost_label")
		var tile_world_pos = get_center_of_hex(hexmap.map_to_global(tile["grid_pos"]))
		tile_world_pos.y += hexmap.get_cell_size().y * 0.15
		new_label.set_position(tile_world_pos)
		self.add_child(new_label)
		new_label.set_owner(get_tree().get_edited_scene_root())

##########################################################################
# Automatically created methods for signalling
##########################################################################

func _on_EndTurnButton_pressed():
	_end_turn()

# Initialize all managers in dependency order.
# This is the core solution to timing/race condition issues.
# Each manager's initialize() method will await its dependencies before running.
func _initialize_managers() -> Variant:
	_debug_log("_initialize_managers(): starting initialization sequence")
	
	# Initialize managers in dependency order:
	# 1. SettingsManager (no dependencies)
	# 2. ThemeManager (no dependencies, but provides data to others)
	# 3. PlayerManager (depends on ThemeManager)
	# 4. WeatherManager (no dependencies)
	# 5. FactionManager (depends on ThemeManager)
	# 6. SfxManager (depends on ThemeManager)
	# 7. MusicManager (depends on SettingsManager, ThemeManager)
	
	if settingsMgr != null and is_instance_valid(settingsMgr):
		_debug_log("_initialize_managers(): initializing SettingsManager")
		await settingsMgr.initialize()
		_debug_log("_initialize_managers(): SettingsManager ready")
	
	if themeMgr != null and is_instance_valid(themeMgr):
		_debug_log("_initialize_managers(): initializing ThemeManager")
		themeMgr.game = self
		await themeMgr.initialize()
		_debug_log("_initialize_managers(): ThemeManager ready")
		themeMgr.load_theme(_determine_theme_name())
		_debug_log("_initialize_managers(): theme loaded")

		if weatherMgr != null and is_instance_valid(weatherMgr):
			themeMgr.initialize_weather_from_scenario()

		# Finally pass current scenario ID to themeMgr
		themeMgr.set_current_scenario_id(globals.selected_scenario)

	if playerMgr != null and is_instance_valid(playerMgr):
		_debug_log("_initialize_managers(): initializing PlayerManager")
		playerMgr.game = self
		await playerMgr.initialize()
		_debug_log("_initialize_managers(): PlayerManager ready")
	
	if weatherMgr != null and is_instance_valid(weatherMgr):
		_debug_log("_initialize_managers(): initializing WeatherManager")
		weatherMgr.game = self
		await weatherMgr.initialize()
		_debug_log("_initialize_managers(): WeatherManager ready")
	
	if factionMgr != null and is_instance_valid(factionMgr):
		_debug_log("_initialize_managers(): initializing FactionManager")
		factionMgr.game = self
		await factionMgr.initialize()
		_debug_log("_initialize_managers(): FactionManager ready")
	
	if sfxMgr != null and is_instance_valid(sfxMgr):
		_debug_log("_initialize_managers(): initializing SfxManager")
		sfxMgr.game = self
		await sfxMgr.initialize()
		_debug_log("_initialize_managers(): SfxManager ready")
	
	if musicMgr != null and is_instance_valid(musicMgr):
		_debug_log("_initialize_managers(): initializing MusicManager")
		musicMgr.game = self
		await musicMgr.initialize()
		_debug_log("_initialize_managers(): MusicManager ready")
	
	_debug_log("_initialize_managers(): all managers initialized")
	return true

# Get Map size
func get_map_size() -> Vector2:
	return self.map_size

func is_setup_complete() -> bool:
	return _setup_complete

func _snap_runtime_entities_to_grid() -> void:
	for node in get_children():
		if node is Entity and node.has_method("_snap_to_grid"):
			node._snap_to_grid()

# Setup the game after managers are initialized
func _setup_game():
	_debug_log("_setup_game(): start")
	
	# Set hex grid to not visible
	hex_grid.modulate.a = 0
	players = playerMgr.get_players()

	# Apply tile definitions from theme (if provided)
	var theme_tiles = themeMgr.get_tiles()
	if typeof(theme_tiles) == TYPE_ARRAY and not theme_tiles.is_empty():
		hexmap.set_tile_types(theme_tiles)
	# Create factions
	factionMgr.load_factions()
	_debug_log("_setup_game(): factions loaded=" + str(factionMgr.factions.size()))
	# Load list of music titles to play
	if DisplayServer.get_name() != "headless":
		musicMgr.play()
		_debug_log("_setup_game(): music manager play() called")
	else:
		_debug_log("_setup_game(): headless run, skipping music playback")
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
	_debug_log("_setup_game(): tile_list built, size=" + str(tile_list.size()))
	self._build_astar_grid()
	_debug_log("_setup_game(): astar_grid built")
	if debug_show_move_costs:
		_display_move_costs()
	# Snap runtime entities only after hex centering data is ready, so the entity
	# list is built from their final in-game positions.
	_snap_runtime_entities_to_grid()
	# Place the units according to their ID and fill attributes.
	# Create a global list of all entities on the map, their type, positions and nodes
	entities = self._create_entity_list()
	_debug_log("_setup_game(): entities created, size=" + str(entities.size()))
	self._place_units()
	_debug_log("_setup_game(): _place_units() done")
	self._update_units()
	_debug_log("_setup_game(): _update_units() done")
	# GUI ready functions
	GUI.disable_movement_button(true)
	GUI.disable_attack_button(true)
	GUI.disable_supply_button(true)
	# Start first turn
	self._advance_player_rotation()
	_debug_log("_setup_game(): done")

# Helper to determine which theme to load
func _determine_theme_name() -> String:
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
	return theme_name
