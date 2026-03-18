extends Node2D

# This is the manager for game themes. A theme is described as a folder containing
# json files for some parts of the game, that are interchangeable, like factions, 
# units, weapons and modifiers. It also contains hexUnit graphics, sound effects, 
# it may contain custom GUI and missions and campaigns as well.

# Essentially this manager provides some generic getters that provide the data from
# the structured json files in an easy way for the game logic.

# member vars here
var standard_themes_path = 'res://themes'
var standard_sprite_path = 'graphics'
var standard_unit_sprites_path = 'units'
var standard_sounds_path = 'sounds'
var standard_sprite_format = 'png'
var fallback_unit_sprite_path = 'res://assets/images/humvee_placeholder_d.png'
@export var debug_logging = true
var theme_object = {}
var theme_path = ''
@onready var default_sounds = {} 

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
	if typeof(file_content) != TYPE_DICTIONARY or not file_content.has("data_files"):
		push_warning("ThemeManager: Invalid theme config: " + config_file)
		return {}
	_debug_log("load_theme(): loading '" + theme_name + "' from " + config_file)
	var data_files = _get_data_files(file_content)
	theme_object['base_path'] = theme_path
	theme_object['display_name'] = file_content['display_name']
	theme_object['name'] = file_content['name']
	# Take sprite path from config, or else standard path
	if 'sprites' in file_content:
		theme_object['sprites'] = file_content['sprites']
	else:
		theme_object['sprites'] = self.standard_sprite_path
	# Take hexUnit sprites path from config, or else standard path
	if 'unit_sprites' in file_content:
		theme_object['unit_sprites'] = file_content['unit_sprites']
	else:
		theme_object['unit_sprites'] = self.standard_unit_sprites_path
	# Load content of rest of files into theme object
	for data_filename in data_files:
		var data_file = data_files[data_filename]
		var file_path = theme_path + '/' + str(data_file)
		theme_object[data_filename] = _read_json(file_path)
	_debug_log("load_theme(): loaded data files " + str(data_files))
	self.theme_object = theme_object
	# Fill default sounds
	default_sounds = {
		'car': load(theme_path+'/'+standard_sounds_path+'/default_wheel_drive.wav'),
		'tank': load(theme_path+'/'+standard_sounds_path+'/default_tank_drive.wav'),
		'infantry': load(theme_path+'/'+standard_sounds_path+'/default_marching.wav')
	}
	_debug_log("load_theme(): active theme='" + get_current_theme_name() + "', units=" + str(theme_object.get("units", {}).size()))
	return theme_object

# Public getter for theme name string
# @returns {String} The internal name of the theme
func get_current_theme_name():
	return self.theme_object.get("name", "")

# Public getter for active theme base path.
func get_theme_base_path():
	return theme_path

func get_music_list():
	return self.theme_object.get("music", {})

# Public getter for sprite path
# @returns {String} Path where sprites of the theme are found
func get_sprite_path():
	return self.theme_path + '/' + self.standard_sprite_path

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
			var icon_path = _to_theme_resource_path(theme_object['factions'][faction_id]['icon'])
			if ResourceLoader.exists(icon_path):
				return load(icon_path)
			push_warning("ThemeManager: Missing faction icon: " + icon_path)

# Public getter for hexUnit object
# @returns {Dictionary} Dict containing all units and their attributes.
func get_units():
	if _is_theme_loaded():
		return theme_object['units']

# Public getter for tile definitions
# @returns {Array} Array containing tile attributes
func get_tiles():
	if _is_theme_loaded():
		return theme_object.get("tiles", [])

# Public getter for scenarios
# @returns {Dictionary} Dict containing all scenarios and their attributes
func get_scenarios():
	if _is_theme_loaded():
		return theme_object.get("scenarios", {})

# Public getter for specific hexUnit object
# @input {String} id of the hexUnit to get
# @returns {Array} Attributes of the hexUnit
func get_unit(unit_id):
	if _is_theme_loaded():
		var units = theme_object['units']
		if unit_id in units:
			return units[str(unit_id)]

# Public getter for table of experience levels 
# for this faction, with according display names, 
# ranges and multipliers
# @input {String} faction ID
# @returns {Array} Object with all experience levels and accompanying data for the given faction
func get_faction_experience_definitions(faction_id):
	if _is_theme_loaded():
		if faction_id in theme_object['factions']:
			return theme_object['factions'][faction_id]['experience']

# Public getter for the sprites/frames of an effect defined in the theme.
# @input {String} Effect ID
# @input {String} Effect Type, used to specify the folder
# @returns {Array} Object with all effect sprite names
func get_effect_sprites(effect_id, effect_type):
	if _is_theme_loaded():
		if effect_id in theme_object.get('effects', {}):
			var sprite_array = theme_object['effects'][effect_id].get('sprites', [])
			var i = 0
			# Add full res: path to frame image for SpriteFrames object to consume
			for element in sprite_array:
				sprite_array[i] = self.get_sprite_path() + '/sfx/' + effect_type + '/' + effect_id + '/' + sprite_array[i]
				i += 1
			return Array(sprite_array)
		return []

# Public getter for a units weapon object
# @input {String} Id of the hexUnit
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

# Public getter for sounds of a hexUnit based on a keyword.
# @input {String} unit_id, the ID of the hexUnit which should play the sound.
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
				if units[unit_id]['weapons'].size() > 0:
					var sound_path = theme_path + '/' + info['sound']
					if ResourceLoader.exists(sound_path):
						return load(sound_path)
					return null
			if keyword == 'hit':
				var impact_path = theme_path + '/' + info['sound_impact']
				if ResourceLoader.exists(impact_path):
					return load(impact_path)
				return null

# Public getter for sprites of a hexUnit.
# If a hexUnit has only one sprite, automatically generate a flipped copy of this
# sprite to allow for some variation in movement animation.
# @input {String} id of the hexUnit to get
# @outputs {Array} An array containing 2 or 6 image paths
func get_unit_sprites(unit_id):
	if _is_theme_loaded():
		var units = theme_object['units']
		var unit_id_key = str(unit_id)
		_debug_log("get_unit_sprites(): request for unit_id='" + unit_id_key + "'")
		if unit_id_key in units:
			if not units[unit_id_key].has('unit_sprites'):
				push_warning("ThemeManager: Unit '" + unit_id_key + "' has no unit_sprites definition.")
				return [fallback_unit_sprite_path]
			var unit_sprites_content = units[unit_id_key]['unit_sprites']
			_debug_log("get_unit_sprites(): raw unit_sprites type=" + str(typeof(unit_sprites_content)) + " value=" + str(unit_sprites_content))
			var selected_sprites = []
			if typeof(unit_sprites_content) == TYPE_STRING:
				# If only a single image is given as hexUnit sprite, flip it and save it as asset. If this asset
				# already exists next time the game starts, it is used.
				var original_sprite_path = str(unit_sprites_content)
				var flipped_sprite_path = _build_flipped_sprite_path(original_sprite_path)
				if not ResourceLoader.exists(_to_theme_resource_path(flipped_sprite_path)):
					_generate_flipped_version(original_sprite_path, flipped_sprite_path)
				selected_sprites = [original_sprite_path, flipped_sprite_path]
			elif typeof(unit_sprites_content) == TYPE_ARRAY:
				if unit_sprites_content.is_empty():
					push_warning("ThemeManager: Unit '" + unit_id_key + "' has an empty unit_sprites array.")
					return [fallback_unit_sprite_path]
				# If there is more than one array for hexUnit sprites, pick a random one.
				if typeof(unit_sprites_content[0]) == TYPE_ARRAY:
					selected_sprites = unit_sprites_content[randi() % unit_sprites_content.size()]
				# Else, just return the one existing array.
				else:
					selected_sprites = unit_sprites_content
			else:
				push_warning("ThemeManager: Unsupported unit_sprites type for hexUnit '" + unit_id_key + "'.")
				return [fallback_unit_sprite_path]
			_debug_log("get_unit_sprites(): selected sprite entries=" + str(selected_sprites))

			var resolved_sprites = []
			for sprite_entry in selected_sprites:
				if typeof(sprite_entry) != TYPE_STRING:
					continue
				var sprite_path = _to_theme_resource_path(str(sprite_entry))
				if ResourceLoader.exists(sprite_path):
					resolved_sprites.append(sprite_path)
				else:
					push_warning("ThemeManager: Missing hexUnit sprite '" + sprite_path + "' for hexUnit '" + unit_id_key + "'.")
					_debug_log("get_unit_sprites(): MISSING '" + sprite_path + "'")
			if resolved_sprites.is_empty():
				resolved_sprites.append(fallback_unit_sprite_path)
				_debug_log("get_unit_sprites(): using fallback sprite '" + fallback_unit_sprite_path + "'")
			_debug_log("get_unit_sprites(): resolved=" + str(resolved_sprites))
			return resolved_sprites
		_debug_log("get_unit_sprites(): unit_id not found in theme units: '" + unit_id_key + "'")
	else:
		_debug_log("get_unit_sprites(): theme not loaded yet.")
	_debug_log("get_unit_sprites(): returning fallback '" + fallback_unit_sprite_path + "'")
	return [fallback_unit_sprite_path]

# Public getter for scale information on sprites for specific hexUnit.
func get_sprite_scale(unit_id):
	if _is_theme_loaded():
		var units = theme_object['units']
		if str(unit_id) in units:
			var hexUnit = units[str(unit_id)]
			if 'sprite_scale' in hexUnit:
				return hexUnit['sprite_scale']

# For one-directional hexUnit sprites only, generate a simple flipped version, so at least
# two directions can be shown.
func _generate_flipped_version(sprite_path, target_path):
	if _is_theme_loaded():
		var source_path = _to_theme_resource_path(sprite_path)
		var target_resource_path = _to_theme_resource_path(target_path)
		_debug_log("_generate_flipped_version(): source=" + source_path + ", target=" + target_resource_path)
		var texture = load(source_path) as Texture2D
		if texture == null:
			push_warning("ThemeManager: Could not load sprite for flip generation: " + source_path)
			return
		var image = texture.get_image()
		if image == null:
			push_warning("ThemeManager: Could not read image data for: " + source_path)
			return
		image.flip_x()
		var result = image.save_png(target_resource_path)
		if result != OK:
			push_warning("ThemeManager: Failed to save flipped sprite '" + target_resource_path + "' (error " + str(result) + ").")
		else:
			_debug_log("_generate_flipped_version(): wrote flipped sprite successfully.")

func _build_flipped_sprite_path(sprite_path):
	var extension = '.' + standard_sprite_format
	if sprite_path.ends_with(extension):
		return sprite_path.substr(0, sprite_path.length() - extension.length()) + '-1' + extension
	return sprite_path + '-1.' + standard_sprite_format

func _to_theme_resource_path(path):
	var normalized = str(path)
	if normalized.begins_with('res://') or normalized.begins_with('user://'):
		return normalized
	if _is_theme_loaded():
		return theme_object['base_path'] + '/' + normalized
	return normalized

# This reads a JSON file and returns a dictionary containing all information from it.
# @input {String} the path to a file, relative to res://
# @outputs {Dictionary} A dictionary containing all nodes from the JSON file
func _read_json(file_path):
	var file_contents_json = {}
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_warning("ThemeManager: Could not open file: " + file_path)
		return file_contents_json
	var text = file.get_as_text()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY or typeof(parsed) == TYPE_ARRAY:
		return parsed
	push_warning("ThemeManager: Invalid JSON in " + file_path)
	return file_contents_json

# This function parses a themes config file given as an object.
# @input {Dictionary} config file as dict
# @outputs {Array} array containing all data files references in the config
func _get_data_files(config_dict):
	var data_files = {}
	if not config_dict.has("data_files"):
		return data_files
	for entry in config_dict["data_files"]:
		data_files[entry.keys()[0]] = entry.values()[0]
	return data_files

# Simple check to avoid NPE when getting something from theme
# @outputs {Boolean} True if the theme has loaded, false otherwise
func _is_theme_loaded():
	if self.theme_object.size() <= 0:
		return false
	return true

func _debug_log(message):
	if debug_logging:
		print("[Debug][ThemeMgr] " + message)
