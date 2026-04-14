extends Control

@export var back_button: Button = null
@export var close_button: Button = null
@export var title_label: Label = null
@export var description_text: RichTextLabel = null
@export var theme_mgr: Node = null
@export var game: Node = null

var globals: Node = null

func _ready() -> void:
	if back_button != null:
		back_button.pressed.connect(_on_back_pressed)
	if close_button != null:
		close_button.pressed.connect(_on_close_pressed)
	globals = get_node_or_null("/root/globals")
	_load_current_scenario_description()

func _load_current_scenario_description() -> void:
	if globals == null:
		return
	
	var scenario_id = globals.selected_scenario
	if scenario_id == "":
		return
	
	if theme_mgr != null:
		var scenarios = theme_mgr.get_scenarios()
		if scenarios.has(scenario_id):
			var scenario_data = scenarios[scenario_id]
			if typeof(scenario_data) == TYPE_DICTIONARY:
				var display_name = str(scenario_data.get("display_name", scenario_id))
				var description = str(scenario_data.get("description", ""))
				
				if title_label != null:
					title_label.text = display_name
				
				if description_text != null:
					description_text.set_text(description)
			else:
				if description_text != null:
					description_text.set_text("[color=yellow]Invalid scenario data.[/color]")
		else:
			if description_text != null:
				description_text.set_text("[color=yellow]No description available.[/color]")
	else:
		if description_text != null:
			description_text.set_text("[color=yellow]Theme manager not available.[/color]")

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_close_pressed() -> void:
	queue_free()