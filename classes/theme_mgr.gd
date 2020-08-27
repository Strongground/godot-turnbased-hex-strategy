extends Node2D

# This is the manager for game themes. A theme is described as a folder containing
# json files for some parts of the game, that are interchangeable, like factions, 
# units, weapons and modifiers. It also contains unit graphics, sound effects, 
# it may contain custom GUI and missions and campaigns as well.

# Essentially this manager provides some generic getters that provide the data from
# the structured json files in an easy way for the game logic.

# member vars here
var standard_themes_path = 'res://themes'
var standard_sprite_path = 'graphics'
var standard_unit_sprites_path = 'units'
var standard_sounds_path = 'sounds'
var standard_sprite_format = 'png'
var theme_object = {}
var theme_path = ''
onready var default_sounds = {} 

func _ready():
	pass

# Main function to get a theme from the standard themes folder. It reads the config.json
# which contains the references to all contained data files which in turn contain the 
# information about contained units etc. pp.
# @TODO Make this OS agnostic (User folder, path separator etc.)
# @input {String} name of the theme folder
# @returns {Object} theme object
func load_theme(theme_name):
	theme_path = standard_themes_path + '/' + theme_name
	var config_file = theme_path + '/config.json'
	var file_content = _read_json(config_file)
	var data_files = _get_data_files(file_content)
	theme_object['base_path'] = theme_path
	theme_object['display_name'] = file_content['display_name']
	theme_object['name'] = file_content['name']
	# Take sprite path from config, or else standard path
	if 'sprites' in file_content:
		theme_object['sprites'] = file_content['sprites']
	else:
		theme_object['sprites'] = self.standard_sprite_path
	# Take unit sprites path from config, or else standard path
	if 'unit_sprites' in file_content:
		theme_object['unit_sprites'] = file_content['unit_sprites']
	else:
		theme_object['unit_sprites'] = self.standard_unit_sprites_path
	# Load content of rest of files into theme object
	for data_filename in data_files:
		var data_file = data_files[data_filename]
		var file_path = theme_path + '/' + String(data_file)
		theme_object[data_filename] = _read_json(file_path)
	self.theme_object = theme_object
	# Fill default sounds
	print(theme_path+'/'+standard_sounds_path+'/default_wheel_drive.wav')
	default_sounds = {
		'car': load(theme_path+'/'+standard_sounds_path+'/default_wheel_drive.wav'),
		'tank': load(theme_path+'/'+standard_sounds_path+'/default_tank_drive.wav'),
		'infantry': load(theme_path+'/'+standard_sounds_path+'/default_marching.wav')
	}
	return theme_object

# Public getter for theme name string
# @returns {String} The internal name of the theme
func get_current_theme_name():
	return self.theme_object.name

func get_music_list():
	return self.theme_object.music

# Public getter for sprite path
# @returns {String} Path where sprites of the theme are found
func get_sprite_path():
	return self.theme_object.sprite_path

# Public getter for factions
# @returns {Dictionary} Dict containing all factions and their attributes
func get_factions():
	if _is_theme_loaded():
		return theme_object['factions']

# Public getter for faction icon
# @input {String} The if of the faction, whose icon should be returned
# @returns {Texture} A texture containing the icon
func get_faction_icon(faction_id):
	if _is_theme_loaded():
		if faction_id in theme_object['factions']:
			var icon = load(theme_object['base_path']+'/'+theme_object.factions[faction_id].icon)
			return icon

# Public getter for unit object
# @returns {Dictionary} Dict containing all units and their attributes.
func get_units():
	if _is_theme_loaded():
		return theme_object['units']

# Public getter for specific unit object
# @input {String} id of the unit to get
# @returns {Array} Attributes of the unit
func get_unit(unit_id):
	if _is_theme_loaded():
		var units = theme_object['units']
		if unit_id in units:
			return units[String(unit_id)]

# Public getter for table of experience levels 
# for this faction, with according display names, 
# ranges and multipliers
# @input {String} faction ID
# @returns {Array} Object with all experience levels and accompanying data for the given faction
func get_faction_experience_definitions(faction_id):
	if _is_theme_loaded():
		if faction_id in theme_object['factions']:
			return theme_object['factions'][faction_id]['experience']

# Public getter for a units weapon object
# @input {String} Id of the unit
# @returns {Array} An object containing all the units weapons properties
# NOTE: In future, this needs to change to accomodate multi-weapon units
func get_weapon(weapon_id):
	if _is_theme_loaded():
		var weapons = theme_object['weapons']
		if weapon_id in weapons:
			return weapons[weapon_id]

# Public getter for a modifier.
# @input {String} modifier_id
func get_modifier(modifier_id):
	if _is_theme_loaded():
		var mods = theme_object['modifiers']
		if modifier_id in mods:
			return mods[modifier_id]

# Public getter for sounds of a unit based on a keyword.
# @input {String} unit_id, the ID of the unit which should play the sound.
# @input {String} keyword, describes the event, for which a sound should be played.
# @input {String} Additional info, optional. E.g. ID of the weapon for which to get the sound, since
# units can have multiple weapons.
func get_sound(unit_id, keyword, info=null):
	if _is_theme_loaded():
		var units = theme_object['units']
		if unit_id in units:
			if keyword == 'move':
				if 'move_sound' in units[unit_id]:
					if units[unit_id]['move_sound'] in self.default_sounds:
						return self.default_sounds[units[unit_id]['move_sound']]
			if keyword == 'attack' and info != null:
				var attack_sound = load(theme_path+'/'+info['sound'])
				print(theme_path+'/'+info['sound'])
				print(attack_sound)
				return attack_sound

# Public getter for sprites of a unit.
# If a unit has only one sprite, automatically generate a flipped copy of this
# sprite to allow for some variation in movement animation.
# @input {String} id of the unit to get
# @outputs {Array} An array containing 2 or 6 image paths
func get_unit_sprites(unit_id):
	if _is_theme_loaded():
		var units = theme_object['units']
		if String(unit_id) in units:
			var unit_sprites_content = units[String(unit_id)].unit_sprites
			if typeof(unit_sprites_content) == TYPE_STRING:
				# Explain
				var flipped_sprite_path = String(unit_sprites_content.rsplit('.png')[0]+'-1.'+standard_sprite_format)
				if not Directory.new().file_exists(theme_object['base_path']+'/'+flipped_sprite_path):
					_generate_flipped_version(unit_sprites_content, flipped_sprite_path)
				return [unit_sprites_content, flipped_sprite_path]
			elif typeof(unit_sprites_content) == TYPE_ARRAY:
				# If there is more than one array for unit sprites, pick a
				# random one.
				if typeof(unit_sprites_content[0]) == TYPE_ARRAY:
					return unit_sprites_content[randi() % unit_sprites_content.size()-1]
				# else, just return the one existing array.
				else:
					return unit_sprites_content

# Public getter for scale information on sprites for specific unit.
func get_sprite_scale(unit_id):
	if _is_theme_loaded():
		var units = theme_object['units']
		if String(unit_id) in units:
			var unit = units[String(unit_id)]
			if 'sprite_scale' in unit:
				return unit.sprite_scale

# For one-directional unit sprites only, generate a simple flipped version, so at least
# two directions can be shown.
func _generate_flipped_version(sprite_path, target_path):
	if _is_theme_loaded():
		var texture = load(theme_object['base_path']+'/'+sprite_path)
		var image = texture.get_data()
		image.lock()
		image.flip_x()
		image.unlock()
		image.save_png(theme_object['base_path']+'/'+target_path)

# This reads a JSON file and returns a dictionary containing all information from it.
# @input {String} the path to a file, relative to res://
# @outputs {Dictionary} A dictionary containing all nodes from the JSON file
func _read_json(file_path):
	var file_contents_json = {}
	var file = File.new()
	file.open(file_path, file.READ)
	var text = file.get_as_text()
	file_contents_json = parse_json(text)
	file.close()
	return file_contents_json

# This function parses a themes config file given as an object.
# @input {Dictionary} config file as dict
# @outputs {Array} array containing all data files references in the config
func _get_data_files(config_dict):
	var data_files = {}
	for entry in config_dict['data_files']:
		data_files[entry.keys()[0]] = entry.values()[0]
	return data_files

# Simple check to avoid NPE when getting something from theme
# @outputs {Boolean} True if the theme has loaded, false otherwise
func _is_theme_loaded():
	if self.theme_object.size() <= 0:
		return false
	return true
