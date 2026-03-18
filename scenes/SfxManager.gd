extends Node2D

# This is a simple manager class for special effects nodes of all kinds. It 
# manages the correction creation, lifetime and destruction and removal of
# special effects nodes.

@export var themeMgr: Node

func _ready():
	pass

# Instanciate a special effect node based on the effect ID given.
# @input {Vector2} global grid position of the effect
# @input {String} name of the id of the special effect
# @input {String} type of effect, e.g. "weapons" or "ambient"
# @input {Boolean} permanent Determine if the effect is permanent (i.e. the last frame will stay indefinitely) or will disappear (i.e. explosion)
# @TODO Refactor so that the value is translated to rounds, so giving "2" means the effect will be deleted after 2 rounds have passed.
# @returns {Object} node that was created
func create_effect(grid_position, id, type, permanent=false):
	var sfx = load("res://classes/sfx.tscn")
	var sfx_instance = sfx.instantiate()
	var game_node = get_node_or_null("/root/Game")
	if game_node == null:
		return null
	game_node.add_child(sfx_instance)
	sfx_instance.themeMgr = themeMgr
	if permanent:
		sfx_instance.initialize(grid_position, id, type, -1)
	else:
		sfx_instance.initialize(grid_position, id, type)
	return sfx_instance

func adjust_volume(volume):
	var game_node = get_node_or_null("/root/Game")
	if game_node == null:
		return false
	for child in game_node.get_children():
		if child.has_node("SoundEmitter"):
			var emitter = child.get_node("SoundEmitter")
			if emitter is AudioStreamPlayer:
				emitter.volume_db = volume * 80 - 80
	return true
