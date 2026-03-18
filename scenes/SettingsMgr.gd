extends Node2D

# Define and export all the settings the game requires and that the
# player can manipulate.

# member vars here
@export var musicManager: Node
@export var sfxManager: Node
var scene_loaded = false
# public members
@export var generalVolume = 1.0
@export var musicVolume = 0.0
@export var sfxVolume = 1.0

func _ready():
	print('SettingsManager: I am loaded...')
	scene_loaded = true
	_update_general_volume(generalVolume)
	_update_music_volume(musicVolume)
	_update_sfx_volume(sfxVolume)

# public getter for general volume
func get_general_volume():
	return generalVolume

# public getter for music volume
func get_music_volume():
	return musicVolume

func get_sfx_volume():
	return sfxVolume

# private setter for music volume
func _update_music_volume(volume):
	musicVolume = volume
	if scene_loaded:
		musicManager.adjust_volume(volume)

# private setter for music volume
func _update_general_volume(volume):
	generalVolume = volume
	if scene_loaded:
		musicManager.adjust_volume(volume)
		sfxManager.adjust_volume(volume)

# private setter for sfx volume
func _update_sfx_volume(volume):
	sfxVolume = volume
	if scene_loaded:
		sfxManager.adjust_volume(volume)
