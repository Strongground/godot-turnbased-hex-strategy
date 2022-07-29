extends Node2D

# This is a simple manager class for special effects nodes of all kinds. It 
# manages the correction creation, lifetime and destruction and removal of
# special effects nodes.

# member vars here
onready var root = $'/root'

func _ready():
	pass

# Instanciate a special effect node based on the effect ID given.
# @input {Vector2} grid position (global) of the effect
# @input {String} id Name of the id of the special effect
# @input {String} type of effect, e.g. "weapons" or "ambient"
# @input {Boolean} permanent Determine if the effect is permanent (i.e. the last frame will stay indefinitely) or will disappear (i.e. explosion)
# @TODO Refactor so that the value permanent instead becomes "duration", -1 being indefinite. 
# Translate value to rounds, so giving "2" means the effect will be deleted after 2 rounds have passed.
# @returns {Object} node that was created
func create_effect(grid_position, id, type, permanent=false):
	var sfx = load("res://classes/sfx.tscn")
	var sfx_instance = sfx.instance()
	root.get_node('Game').add_child(sfx_instance)
	if permanent:
		sfx_instance.initialize(grid_position, id, type, -1)
	sfx_instance.initialize(grid_position, id, type)
	return sfx_instance