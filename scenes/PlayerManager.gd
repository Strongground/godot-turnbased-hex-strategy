extends "res://classes/game_manager.gd"

# This is the player manager. It creates players as well as keeps track of
# their index and stance to each other. This will become much more important
# once multiplayer is a viable concern.

@export var themeMgr: Node
@export var game: Node

# member vars here
var players: Array

func _ready():
	# Keep empty - initialization happens via initialize() method
	pass

func _initialize_internal() -> Variant:
	var active_theme_mgr = _get_theme_manager()
	if active_theme_mgr != null and is_instance_valid(active_theme_mgr):
		add_dependency(active_theme_mgr)
	_debug_log("_initialize_internal(): PlayerManager ready")
	players = _create_players(_get_player_options())
	return true

# Instanciate the associated nodes for each registered player.
# @input {Array} of dictionary objects of options to create new players.
# @returns {Array} of created player object references
func _create_players(player_options) -> Array:
	var result_array = []
	var i = 0
	for player_node in player_options:
		var player = load("res://classes/player.tscn")
		var player_instance = player.instantiate()
		player_instance.create(player_node['name'], player_node['factionID'], player_node['isHuman'], i)
		result_array.append({'node': player_instance, 'id': i})
		call_deferred('add_child', player_instance)
		i += 1
	# If information is given, pre-set the stance of the various players to each other
	# Else set all players to be each others enemies by default.
	self.players = result_array
	self._set_player_stances(player_options)
	return result_array

func _get_player_options():
	var active_theme_mgr = _get_theme_manager()
	if active_theme_mgr == null or not is_instance_valid(active_theme_mgr):
		return []
	var scenario_data = active_theme_mgr.get_current_scenario()
	print("PlayerManager._get_player_options(): scenario_data=" + str(scenario_data))
	if scenario_data.has("players"):
		return scenario_data["players"]
	else:
		return []

func _get_theme_manager() -> Node:
	if themeMgr != null and is_instance_valid(themeMgr):
		return themeMgr
	if game != null and is_instance_valid(game):
		return game.themeMgr
	return null

func _set_player_stances(player_options):
	for player_entry in self.players:
		for player_option in player_options:
			var player = player_entry.node
			if int(player_option['id']) == int(player.get_id()):
				var cur_stances = player_option['stances']
				if cur_stances.has('enemies'):
					player.enemies = _normalize_player_id_list(cur_stances['enemies'])
				if cur_stances.has('allies'):
					player.allies = _normalize_player_id_list(cur_stances['allies'])
				if cur_stances.has('neutral'):
					player.neutrals = _normalize_player_id_list(cur_stances['neutral'])

func _normalize_player_id_list(raw_ids) -> Array:
	var normalized: Array = []
	if typeof(raw_ids) != TYPE_ARRAY:
		return normalized
	for raw_id in raw_ids:
		normalized.append(int(raw_id))
	return normalized

func get_players():
	return self.players

# Get a player object by its id from the list of players.
# @returns {Object | False} If a player object with the given ID can
# be found, it is returned. Otherwise, false is returned.
func get_player_by_id(id):
	for player in self.players:
		if str(player.node.get_id()) == str(id):
			return player
	return false

# Public getter to return faction ID of player
# @input {String} ID of player
# @returns {String} ID of faction of player
func get_player_faction(id):
	for player in self.players:
		if str(player.node.get_id()) == str(id):
			return player.node.get_faction_id()
	return false
