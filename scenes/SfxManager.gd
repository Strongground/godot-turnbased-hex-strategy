extends Node2D

# This is a simple manager class for special effects nodes of all kinds. It 
# manages the correction creation, lifetime and destruction and removal of
# special effects nodes.

# member vars here
onready var root = get_node('/root')

func _ready():
	pass

# Instanciate a special effect node based on the file name given.
# @input {String} name of the id of the special effect
# @returns {Object} node that was created
func create_effect(grid_position, id):
	var sfx = load("res://classes/sfx.tscn")
	var sfx_instance = sfx.instance()
	root.get_node('Game').add_child(sfx_instance)
	sfx_instance.initialize(grid_position, id)
	return sfx_instance
