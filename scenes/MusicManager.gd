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
onready var game = get_node('/root/Game')
onready var settingsMgr = $"/root/Game/SettingsManager"
var standard_themes_path = 'res://themes'
var standard_music_path = 'music'
var playlist = null
var iterator = 0
var musicVolume = 0
var generalVolume = 0
onready var streamPlayer = $"/root/Game/BackgroundMusicPlayer"
# public members

func _ready():
	print('MusicManager: I am ready!')

# Private loader that makes sure there is music in the playlist
func _loadMusic():
	var raw_playlist = game.themeMgr.get_music_list()['playlist']
	self.playlist = []
	for entry in raw_playlist:
		var songfile = raw_playlist[entry]
		var theme_name = $"/root/Game/ThemeManager".get_current_theme_name()
		# print(standard_themes_path+'/'+theme_name+'/'+standard_music_path+'/'+songfile)
		self.playlist.append(load(standard_themes_path+'/'+theme_name+'/'+standard_music_path+'/'+songfile))

# Public function to start the playback
func play():
	self._loadMusic()
	self.adjust_volume(settingsMgr.get_music_volume())
	if self.playlist.size() > 0:
		self.streamPlayer.stream = playlist[0]
		self.streamPlayer.play()
	else:
		print('Playlist is empty!')

# Adjust volume of background music
func adjust_volume(volume):
	var volume_db = volume * 40 - 40
	self.streamPlayer.set_volume_db(volume_db)
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
