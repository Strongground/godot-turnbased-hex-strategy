extends Node2D

# This is the manager class to handle the music playback during the game.
# First step: Just play music, defined in the theme.
# Second step: Play music based on the faction you're playing with.
# Third step: Situational aware music, based on what happens in the game: 
# By default play cautious or even peaceful songs... When enemies are
# in range of your units, play dangerous music, during combat play action-driven
# music, etc.
# Define all these in theme.
#
# Also define and utilize music volume but get it - like all settings - from SettingsMgr.

# member vars here
@export var game: Node
@export var settingsMgr: Node
var standard_themes_path = 'res://themes'
var standard_music_path = 'music'
var playlist = null
var iterator = 0
var musicVolume = 1
var generalVolume = 1
@export var streamPlayer: AudioStreamPlayer
var current_mood = ""
var current_faction = ""
var _mood_check_timer = 0.0
# Seconds between mood checks for switching music.
var mood_check_interval = 1.0
# public members

func _ready():
	if streamPlayer == null:
		streamPlayer = AudioStreamPlayer.new()
		streamPlayer.name = "BackgroundMusicPlayer"
		var parent_node = game if game != null else self
		parent_node.add_child.call_deferred(streamPlayer)
		streamPlayer.finished.connect(_on_AudioStreamPlayer_finished)
	print('MusicManager: I am ready!')

func _process(delta):
	_mood_check_timer += delta
	if _mood_check_timer < mood_check_interval:
		return
	_mood_check_timer = 0.0
	_sync_music_state()

# Private loader that makes sure there is music in the playlist
func _loadMusic():
	var raw_playlist = _get_music_entries()
	self.playlist = []
	for songfile in raw_playlist:
		var resolved = _resolve_music_path(songfile)
		if ResourceLoader.exists(resolved):
			self.playlist.append(load(resolved))

# Public function to start the playback
func play():
	self._sync_music_state(true)
	self.adjust_volume(settingsMgr.get_music_volume())
	if self.playlist.size() > 0:
		self.streamPlayer.stream = playlist[0]
		self.streamPlayer.play()
	else:
		print('Playlist is empty!')

# Adjust volume of background music
func adjust_volume(volume):
	if streamPlayer == null:
		return false
	var volume_db = volume * 80 - 80
	self.streamPlayer.volume_db = volume_db
	return true

# Public function to play next song
func play_next():
	if self.iterator + 1 < self.playlist.size():
		self.iterator += 1
	else:
		self.iterator = 0
	self.streamPlayer.stream = self.playlist[iterator]
	self.streamPlayer.play()

# Automatically play next song after one has finished
func _on_AudioStreamPlayer_finished():
	self.play_next()

func _exit_tree():
	if streamPlayer != null:
		streamPlayer.stop()
		streamPlayer.stream = null
	playlist = []

func _get_active_faction_id() -> String:
	if game != null and game.active_player != null:
		return str(game.active_player.get_faction_id())
	return "all"

func _get_current_mood() -> String:
	if game != null and game.has_method("get_music_mood"):
		return str(game.get_music_mood())
	return "peace"

func _resolve_music_path(songfile: String) -> String:
	var base_path = ""
	if game != null and game.themeMgr != null and game.themeMgr.has_method("get_theme_base_path"):
		base_path = game.themeMgr.get_theme_base_path()
	if base_path == "":
		var theme_name = game.themeMgr.get_current_theme_name()
		base_path = standard_themes_path + '/' + theme_name
	return base_path + '/' + standard_music_path + '/' + songfile

func _get_music_entries() -> Array:
	var music_def = game.themeMgr.get_music_list()
	if typeof(music_def) != TYPE_DICTIONARY:
		return []
	# Legacy format: playlist dict or array
	if music_def.has("playlist"):
		var legacy = music_def["playlist"]
		if typeof(legacy) == TYPE_DICTIONARY:
			return legacy.values()
		if typeof(legacy) == TYPE_ARRAY:
			return legacy
		return []
	# New format: faction -> mood -> array
	var faction_id = _get_active_faction_id()
	var faction_def = music_def.get(faction_id, music_def.get("all", {}))
	if typeof(faction_def) != TYPE_DICTIONARY:
		return []
	var mood = _get_current_mood()
	var mood_list = faction_def.get(mood, [])
	if typeof(mood_list) == TYPE_ARRAY:
		return mood_list
	return []

func _sync_music_state(force=false):
	var new_faction = _get_active_faction_id()
	var new_mood = _get_current_mood()
	if not force and new_faction == current_faction and new_mood == current_mood:
		return
	current_faction = new_faction
	current_mood = new_mood
	_loadMusic()
	iterator = 0
	if playlist != null and playlist.size() > 0:
		_fade_to_track(playlist[0])

func _fade_to_track(stream: AudioStream):
	if streamPlayer == null:
		return
	var target_volume = settingsMgr.get_music_volume() * 80 - 80
	var tween = create_tween()
	tween.tween_property(streamPlayer, "volume_db", -80, 0.8)
	tween.tween_callback(func():
		streamPlayer.stream = stream
		streamPlayer.play()
	)
	tween.tween_property(streamPlayer, "volume_db", target_volume, 0.8)
