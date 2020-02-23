extends Node2D

# This is the faction manager. It manages factions, d'oh.

# member vars here
onready var game = get_node('/root/Game')
var factions = {}

func _ready():
	pass

# Get the faction object based on ID
# @input {String} containing the ID of the faction
# @returns {Reference} to the faction object
func get_faction(id):
	return factions[id]

# Create the factions
func load_factions():
	self.factions = game.themeMgr.get_factions()
