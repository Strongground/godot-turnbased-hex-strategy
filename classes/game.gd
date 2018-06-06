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
# L map
# 	L map graphic
#   L overlays
# L all entities
# L main camera
# 	L GUI

# member vars here
var camera = null
var globals = null
var tiles = null
var tile_list = null
var hexmap = null
var hex_grid = null
var hex_offset = null
var current_tile = null
var marker = null
var rect = null
var root = null
var hex_marker = null
var hex_fill = null
var counter = 0
var hex_directions = null
var all_tiles = null
var arrow_marker = null
var neighbour_position_rotation_table = null
var GUI = null
var entities = []
var click_counter = 0
var start_position = null
var target_position = null
var selected_unit = null
var movement_selection = false
var tween = null
var grid_visible = false
var theme_manager = false
## Loop vars
var turn_counter = 0
var player_active = null
var player_rotation = []
var players = []
## debug labels
var label_player = null
var label_turn = null

func _ready():
    set_process_input(true)
    var registered_players = ['Human Tester', 'Test AI (Dumb)', 'Test AI (Clever)'] # Later this would need to come out of menu selection
    players = _create_players(registered_players)
    camera = find_node('MainCamera')
    root = get_node('/root')
    globals = get_node('/root/globals')
    hexmap = get_node('MapZones')
    marker = get_node('RedDot')
    hex_grid = get_node('HexGridOverlay')
    rect = get_node('SizeRect')
    hex_marker = find_node('HexMarker')
    hex_fill = find_node('Hex_Fill')
    arrow_marker = find_node('Arrow')
    tween = find_node('Tween')
    GUI = find_node('GUI')
    theme_manager = find_node('ThemeManager')
    label_player = find_node('CurrentPlayer')
    label_turn = find_node('CurrentTurn')
    # Load theme
    theme_manager.load_theme('example')
    hex_offset = Vector2(-6,0)
    # This table serves as easy shortcut for the grid local coordinate change
    # that needs to be done when a neighbour of a hex tile has to be found.
    # The sorting is identical for odd and even, so hex_directions[0] always
    # gives the northern neighbour.
    hex_directions = [
        # Even columns
        [[0, -1], [1, -1], [1, 0], [0, 1], [-1, 0], [-1, -1]],
        # Odd columns
        [[0, -1], [1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0]]
    ]
    all_tiles = hexmap.get_used_cells()
    neighbour_position_rotation_table = {
        'n':  -90,
        'ne': -150,
        'se': 150,
        's':  90,
        'sw': 30,
        'nw': -30
    }
    tile_list = _build_hex_object_database()
    # Create a global list of all entities on the map, their type, positions and nodes
    entities = self._create_entity_list()
    self._update_units()
    # GUI ready functions
    GUI.disable_movement_button(true)
    # Test load a unit from theme
    var test_unit = theme_manager.get_unit('militia_rifles')

# Instanciate the associated nodes for each registered player.
# @input {Array} of Strings to name the Nodes, ID will be created automatically
# @returns {Array} of player object references
func _create_players(registered_player_array):
    var result_array = []
    var i = 0
    for player_node_name in registered_player_array:
        var player = load("res://classes/player.tscn")
        var player_instance = player.instance()
        player_instance.set_name(String(player_node_name))
        result_array.append({'node': player_instance, 'id': i})
        add_child(player_instance)
        i += 1
    return result_array
    
# Get a player object by its id from the global array of players.
# @returns {Object|null} If a player object with the given ID can be found,
# it is returned. Otherwise, null is returned.
func get_player_by_id(id):
    for player in players:
        if player['id'] == id:
            return player
        else:
            return null

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
    for entity in entities:
        if entity.type == 'unit':
            entity.node.update() 

# Get entity of given id
func _get_entity_by_id(id):
    for entity in entities:
        if entity.id == id:
            return entity

# Create a list of all entities and their grid local positions as well as nodes
func _create_entity_list():
    var result = []
    var i = 0
    for node in self.get_children():
        if 'type' in node and node.type == 'unit' \
            or 'type' in node and node.type == 'editor_marker':
            node.set_id(i)
            result.append({
                'id': i,
                'node': node,
                'type': node.get_type(),
                'grid_pos': self._get_hex_object_from_global_pos(node.get_global_position()).grid_pos
            })
            i += 1
    return result

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

func _input(event):
    # Maybe outsource this to a click controller module, or maybe delegate all
    # click events to appropiate nodes from here. Ask Q/A
    if event is InputEventKey:
        if event.scancode == KEY_ESCAPE:
            get_tree().quit()
    elif event.is_action_pressed('mouse_click'):
        # Once set the actual global mouse position needed for conversion of the coordinates
        var click_pos = self.get_global_mouse_position()
        
        ### If clicked on tilemap
        if self._is_tilemap(click_pos) and not self._is_unit(click_pos) and not GUI.is_gui_clicked():
            
            # Deselect all selectable entities
            #self.deselect_all_entities()

            # If in state of movement and unit owned by active player is selected, next click 
            # sets movement target and triggers pathfinding to it, saving the resulting path 
            # array at the selected unit.
            if self.movement_selection == true and self.selected_unit != null:
                var unit = _get_entity_by_id(self.selected_unit)
                var new_path = find_path(unit.node.get_global_position(), click_pos)
                unit.node.set_path(new_path)
                # _show_path(new_path)
                unit.node.animate_path(new_path)
                unit.node.deselect()
                self.movement_selection = false

            ##### On click on two tiles, flood fill the map and get path from first to second click
            # if click_counter < 1:
            # 	print('First click')
            # 	# On first click, determine start position
            # 	start_position = click_pos
            # 	# increment click counter
            # 	click_counter += 1
            # 	# color clicked (starting) tile red
            # 	var vis_start_tile = self._get_hex_object_from_global_pos(start_position)
            # 	self._set_hex_fill(hexmap.map_to_world(vis_start_tile.grid_pos), 'red', 'path_vis')
            # elif click_counter == 1:
            # 	print('Second click')
            # 	# On second click, determine target position
            # 	# reset counter
            # 	click_counter += 1
            # 	target_position = click_pos
            # 	var path = self.find_path(start_position, target_position)
            # 	self._show_path(path)
            # else:
            # 	print('Third click')
            # 	# On third click reset click counter
            # 	click_counter = 0
            # 	# and delete path visualisation
            # 	self._delete_all_nodes_with('path_vis')
            #### END
                
            # Set current tile attributes for use by decision logic
            current_tile = self.get_tile(click_pos)

            # Highlight neighbouring hexes of selected hex
            # self._highlight_neighbours(click_pos)
            
            # Show the popup with tile information
            # GUI._show_tile_info_popup(_get_hex_object_from_global_pos(click_pos))

        ### Unit was selected
        elif self._is_unit(click_pos):
            var selected_unit = self._is_unit(click_pos, true)
            selected_unit.node.select()
            GUI.disable_movement_button(false)

# Process the current turn
func _end_turn():
    _advance_player_rotation()
    turn_counter += 1

func _advance_player_rotation():
    var player_status = null
    var next_player = ''
    # populate the player_rotation first time this method is called
    if players.size() != player_rotation.size():
        for count in range(0, players.size()):
            # for first player, set to active (because he is the only one) 
            if count == 0:
                player_status = true
            else:
                player_status = false
            player_rotation.append({
                'id': count,
                'active': player_status
            })
    # determine next player id
    for player in player_rotation:
        # found active player, set it to inactive and determine id of next one
        if player['active']:
            # Set player entry in player_rotation to 'not active'
            player['active'] = false
            # Set player object itself to 'not active'
            players[player['id']]['node'].set_active(false)
            if player['id']+1 > players.size()-1:
                # if we reached end of list of players, set next_player index to 0 again
                next_player = players[0]['node']
                # Set next player in player_rotation 'active'
                player_rotation[0]['active'] = true
            else:
                # else set to current players id + 1
                next_player = players[(player['id']+1)]['node']
                # Set next player in player_rotation 'active'
                player_rotation[player['id']+1]['active'] = true
            # Set next player object 'active'
            next_player.set_active(true)
            player_active = next_player
            break
    
func _process(delta):
    if player_active != null:
        label_player.set_text(String(player_active['id']))
    if turn_counter:
        label_turn.set_text(String(turn_counter))

# Check if there is a tilemap at the given position
# Use this to wrap up input loop, to avoid NPE when clicked outside tilemap
# @input {Vector2} position of the click to check for tilemap
# @returns {Boolean} return true if there is no entity at given coords
func _is_tilemap(given_position):
    var tile = _get_hex_object_from_global_pos(given_position)
    if tile != null and tile.size() > 1:
        return true
    return false

# Determine if there is a unit at the grid local position that is given
# @input {Vector2} position of the click to check for unit
# @input {Boolean} (optional) return unit object if true
# @returns {Boolean | Object} return true if there is a unit at given coords
func _is_unit(given_position, return_unit=false):
    var grid_position = hexmap.world_to_map(given_position)
    for entity in entities:
        if entity.node.get_type() == 'unit':
            if entity.grid_pos == grid_position:
                if return_unit == true:
                    return entity
                else:
                    return true
    return false

# Deselects all selectable entities on the map 
func deselect_all_entities():
    for entity in entities:
        if entity.node.has_method('is_selected') and entity.node.is_selected():
            # If a unit is deselected
            if entity.type == 'unit':
                GUI.disable_movement_button(true)
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
    # Start the visitation with the tile gotten from the click position
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
                # Show movement cost per tile
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
func _show_path(path):
    for tile in path:
        # don't color first tile, this is done in input loop for immediate visual feedback
        if tile == path[0]:
            pass
        # color last tile green
        elif tile == path[path.size()-1]:
            self._set_hex_fill(hexmap.map_to_world(tile.grid_pos), 'green', 'path_vis')
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
