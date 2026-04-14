extends "res://classes/game_manager.gd"

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
@export var combat_debug = false
# debug
@export var mute_music_on_start = false

func _ready():
	# Keep empty - initialization happens via initialize() method
	pass

func _initialize_internal() -> Variant:
	# SettingsManager has no dependencies on other managers
	# Music and SFX managers will be initialized independently
	# Volume settings are applied later when music/SFX managers are ready
	if mute_music_on_start:
		_update_music_volume(-1.0) # @TODO This for testing only
	_debug_log("_initialize_internal(): SettingsManager ready")
	return true

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
	if scene_loaded and musicManager != null and is_instance_valid(musicManager):
		musicManager.adjust_volume(volume)

# private setter for music volume
func _update_general_volume(volume):
	generalVolume = volume
	if scene_loaded and musicManager != null and is_instance_valid(musicManager):
		musicManager.adjust_volume(volume)
	if scene_loaded and sfxManager != null and is_instance_valid(sfxManager):
		sfxManager.adjust_volume(volume)

# private setter for sfx volume
func _update_sfx_volume(volume):
	sfxVolume = volume
	if scene_loaded and sfxManager != null and is_instance_valid(sfxManager):
		sfxManager.adjust_volume(volume)

# Public getter for combat debug setting
func get_combat_debug():
	return combat_debug