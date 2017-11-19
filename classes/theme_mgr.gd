extends Node2D

# This is the manager for game themes. A theme is described as a folder containing
# json files for some parts which are interchangeable, like factions, units, weapons
# and modifiers. It also contains unit graphics, sound effects, it may contain
# custom GUI and missions and campaigns as well.

# Essentially it provides some generic getters that provide the data from the structured
# json files in an easy way for the game logic.

# member vars here
var root = null
var globals = null
var standard_themes_path = null
var theme_object = {}

func _ready():
    root = get_node('/root')
    globals = get_node('/root/globals')
    standard_themes_path = 'res://themes'

# Main function to get a theme from the standard themes folder. It reads the config.json
# which contains the references to all contained data files which in turn contain the 
# information about contained units etc. pp.
# @input {String} name of the theme, should be name of the theme folder
# @returns {Object} theme file
func load_theme(theme_name):
    var theme_path = standard_themes_path + '/' + theme_name
    var config_file = theme_path + '/config.json'
    var file_content = _read_json(config_file)
    var data_files = _get_data_files(file_content)
    theme_object['name'] = file_content['name']
    for data_file in data_files:
        var file_path = theme_path + '/' + String(data_file).split(':',1)[1].split(')',1)[0]
        theme_object[String(data_file).split(':',1)[0].split('(',1)[1]] = _read_json(file_path)
    print(String(theme_object))
    return theme_object

# Public Getter for unit object
# @outputs {Dictionary} Dict containing all units and their attributes.
func get_units():
    if _is_theme_loaded():
        result = theme_object['units']

# This reads a JSON file and returns a dictionary containing all information from it.
# @input {String} the path to a file, relative to res://
# @outputs {Dictionary} A dictionary containing all nodes from the JSON file
func _read_json(file_path):
    var file_contents_json = {}
    var file = File.new()
    file.open(file_path, file.READ)
    var text = file.get_as_text()
    file_contents_json.parse_json(text)
    file.close()
    return file_contents_json

# This function parses a themes config file given as an object.
# @input {Dictionary} config file as dict
# @outputs {Array} array containing all data files references in the config
func _get_data_files(config_dict):
    var data_files = []
    data_files = config_dict['data_files']
    return data_files

# Simple check to avoid NPE when getting something from theme
# @outputs {Boolean} True if the theme has loaded, false otherwise
func _is_theme_loaded():
    if self.theme_object.size() <= 0:
        return false
    return true