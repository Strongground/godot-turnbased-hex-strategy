extends Node2D

# This is a simple manager class for special effects nodes of all kinds. It
# manages the correct creation, lifetime and destruction and removal of
# special effects nodes.

@export var themeMgr: Node
@export var game: Node

# Instantiate a special effect node based on the effect ID given.
# @input {Vector2} global position of the effect
# @input {String} name of the id of the effect
# @input {String} type of effect, e.g. "weapons" or "ambient"
# @input {Boolean} permanent Determine if the effect should remain until manually removed
# @input {Dictionary} options Optional transform/playback hints such as rotation or scale
# @returns {Object} node that was created
func create_effect(world_position, id, type, permanent=false, options: Dictionary = {}):
	if id == null:
		return null
	var effect_id = str(id)
	if effect_id.is_empty():
		return null
	var sfx = load("res://classes/sfx.tscn")
	var sfx_instance = sfx.instantiate()
	game.add_child(sfx_instance)
	# Pass down themeManager to instanciated sfx
	sfx_instance.themeMgr = themeMgr
	if permanent:
		sfx_instance.initialize(world_position, effect_id, type, -1, options)
	else:
		sfx_instance.initialize(world_position, effect_id, type, 0, options)
	return sfx_instance

func adjust_volume(volume):
	for child in game.get_children():
		if child.has_node("SoundEmitter"):
			var emitter = child.get_node("SoundEmitter")
			if emitter is AudioStreamPlayer:
				emitter.volume_db = volume * 80 - 80 # @TODO Get rid of magic numbers
	return true
