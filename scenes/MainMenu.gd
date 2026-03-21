extends Control

@export var theme_select: OptionButton = null
@export var scenario_select: OptionButton = null
@export var start_button: Button = null
@export var message_label: Label = null
@export var quit_button: Button = null
@export var menu_background: TextureRect = null

var _themes: Array = []
var _scenarios: Array = []

func _ready() -> void:
	_load_themes()
	if _themes.is_empty():
		_set_message("No themes found in res://themes")
		_start_enabled(false)
		return
	_theme_select_apply(0)

func _load_themes() -> void:
	_themes.clear()
	if theme_select != null:
		theme_select.clear()
	var dir = DirAccess.open("res://themes")
	if dir == null:
		_set_message("Cannot open res://themes")
		return
	dir.list_dir_begin()
	var name = dir.get_next()
	while name != "":
		if dir.current_is_dir() and not name.begins_with("."):
			var config_path = "res://themes/" + name + "/config.json"
			if FileAccess.file_exists(config_path):
				var config = _read_json(config_path)
				if typeof(config) == TYPE_DICTIONARY:
					var display_name = str(config.get("display_name", name))
					var theme_id = str(config.get("id", name))
					_themes.append({"id": theme_id, "folder": name, "display_name": display_name})
		name = dir.get_next()
	dir.list_dir_end()
	_themes.sort_custom(func(a, b): return str(a["display_name"]) < str(b["display_name"]))
	for i in range(_themes.size()):
		if theme_select != null:
			theme_select.add_item(_themes[i]["display_name"], i)
	if theme_select != null and not _themes.is_empty():
		theme_select.select(0)

func _load_scenarios(theme_folder: String) -> void:
	_scenarios.clear()
	if scenario_select != null:
		scenario_select.clear()
	var scenarios_path = "res://themes/" + theme_folder + "/scenarios.json"
	if not FileAccess.file_exists(scenarios_path):
		_set_message("Theme has no scenarios.json")
		_start_enabled(false)
		return
	var data = _read_json(scenarios_path)
	if typeof(data) != TYPE_DICTIONARY:
		_set_message("Invalid scenarios.json format")
		_start_enabled(false)
		return
	for scenario_id in data:
		var entry = data[scenario_id]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var display_name = str(entry.get("display_name", scenario_id))
		var scene_path = str(entry.get("scene", ""))
		_scenarios.append({"id": scenario_id, "display_name": display_name, "scene": scene_path})
	_scenarios.sort_custom(func(a, b): return str(a["display_name"]) < str(b["display_name"]))
	for i in range(_scenarios.size()):
		if scenario_select != null:
			scenario_select.add_item(_scenarios[i]["display_name"], i)
	if _scenarios.is_empty():
		_set_message("No scenarios found for theme")
		_start_enabled(false)
	else:
		if scenario_select != null:
			scenario_select.select(0)
		_set_message("")
		_start_enabled(true)

func _set_background(theme_folder : String):
	var background_path = "res://themes/" + theme_folder + "/theme-bg.png"
	if not FileAccess.file_exists(background_path):
		return
	var theme_bg = load(background_path)
	menu_background.set_texture(theme_bg)

func _theme_select_apply(index: int) -> void:
	if index < 0 or index >= _themes.size():
		return
	var theme_folder = str(_themes[index]["folder"])
	_load_scenarios(theme_folder)
	_set_background(theme_folder)

func _on_theme_selected(index: int) -> void:
	_theme_select_apply(index)

func _on_start_pressed() -> void:
	if _themes.is_empty() or _scenarios.is_empty():
		return
	var theme_index = theme_select.selected
	var scenario_index = scenario_select.selected
	if theme_index < 0 or theme_index >= _themes.size():
		return
	if scenario_index < 0 or scenario_index >= _scenarios.size():
		return
	var theme_id = str(_themes[theme_index]["id"])
	var theme_folder = str(_themes[theme_index]["folder"])
	var scenario = _scenarios[scenario_index]
	var scene_path = str(scenario.get("scene", ""))
	if scene_path == "" or not ResourceLoader.exists(scene_path):
		_set_message("Scenario scene missing: " + scene_path)
		return
	globals.set_selected_theme(theme_id, theme_folder)
	globals.set_selected_scenario(str(scenario.get("id", "")), scene_path)
	get_tree().change_scene_to_file(scene_path)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _start_enabled(enabled: bool) -> void:
	if start_button != null:
		start_button.disabled = not enabled

func _set_message(text: String) -> void:
	if message_label != null:
		message_label.text = text

func _read_json(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	var content = file.get_as_text()
	file.close()
	return JSON.parse_string(content)
