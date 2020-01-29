extends Node2D

# This is the player manager. It creates players as well as keeps track of
# their index and stance to each other. This will become much more important
# once multiplayer is a viable concern.

# member vars here
onready var root = get_node('/root')
var players = {}

func _ready():
	pass

# Instanciate the associated nodes for each registered player.
# @input {Array} of dictionary objects of options to create new players.
# @returns {Array} of created player object references
func create_players(player_options):
	var result_array = []
	var i = 0
	for player_node in player_options:
		var player = load("res://classes/player.tscn")
		var player_instance = player.instance()
		player_instance.create(player_node['name'], player_node['factionID'], player_node['isHuman'], i)
		result_array.append({'node': player_instance, 'id': i})
		call_deferred('add_child', player_instance)
		i += 1
	# If information is given, pre-set the stance of the various players to each other
	# Else set all players to be each others enemies by default.
	self.players = result_array
	self._set_player_stances(player_options)
	return result_array

func _set_player_stances(player_options):
	for player_entry in self.players:
		for player_option in player_options:
			var player = player_entry.node
			if player_option.id == player.get_id():
				var cur_stances = player_option.stances
				if cur_stances.has('enemies'):
					player.enemies = cur_stances.enemies
				if cur_stances.has('allies'):
					player.allies = cur_stances.allies
				if cur_stances.has('neutral'):
					player.neutrals = cur_stances.neutral

# Get a player object by its id from the list of players.
# @returns {Object | False} If a player object with the given ID can
# be found, it is returned. Otherwise, false is returned.
func get_player_by_id(id):
	for player in self.players:
		if player.node.get_id() == id:
			return player
	return false