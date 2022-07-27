extends Node2D

# Define and export all the settings the game requires and that the
# player can manipulate.

# member vars here
onready var game = $"/root/Game"
onready var musicManager = $"root/Game/MusicManager"
onready var sfxManager = $"/root/Game/SfxManager"
var scene_loaded = false
# public members
export (float) var generalVolume = 1.0 setget _update_general_volume
export (float) var musicVolume = 0 setget _update_music_volume
export (float) var sfxVolume = 1.0 setget _update_sfx_volume

func _ready():
	print('SettingsManager: I am loaded...')
	pass

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
	if scene_loaded:
		musicManager.adjust_volume(volume)

# private setter for music volume
func _update_general_volume(volume):
	if scene_loaded:
		musicManager.adjust_volume(volume)

# private setter for sfx volume
func _update_sfx_volume(volume):
	if scene_loaded:
		sfxManager.adjust_volume(volume)
