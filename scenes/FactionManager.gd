extends "res://classes/game_manager.gd"

# This is the faction manager. It manages factions, d'oh.

# member vars here
@export var game: Node
var factions = {}

func _ready():
	# Keep empty - initialization happens via initialize() method
	pass

func _initialize_internal() -> Variant:
	# FactionManager depends on ThemeManager for loading factions
	if game != null and is_instance_valid(game):
		if game.themeMgr != null and is_instance_valid(game.themeMgr):
			_debug_log("_initialize_internal(): Awaiting themeMgr initialization")
			await game.themeMgr.initialize()
	_debug_log("_initialize_internal(): FactionManager ready")
	return true

# Get the faction object based on ID
# @input {String} containing the ID of the faction
# @returns {Reference} to the faction object
func get_faction(id):
	return factions[id]

# Create the factions
func load_factions():
	if game != null and is_instance_valid(game):
		if game.themeMgr != null and is_instance_valid(game.themeMgr):
			self.factions = game.themeMgr.get_factions()
