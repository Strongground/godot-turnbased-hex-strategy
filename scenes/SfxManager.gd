extends Node2D

# This is a simple manager class for special effects nodes of all kinds. It 
# manages the correction creation, lifetime and destruction and removal of
# special effects nodes.

# member vars here
onready var root = get_node('/root')

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
	var sfx_instance = sfx.instance()
	root.get_node('Game').add_child(sfx_instance)
	if permanent:
		sfx_instance.initialize(grid_position, id, type, -1)
	else:
		sfx_instance.initialize(grid_position, id, type)
	return sfx_instance
