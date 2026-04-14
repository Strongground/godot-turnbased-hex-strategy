extends CenterContainer

@export var display_name: Label
@export var icon: TextureRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func instanciate(modifier_data: Dictionary) -> void:
	var display_name_value = modifier_data.get("display_name", "Unknown Modifier")
	display_name.text = display_name_value
	var description = modifier_data.get("description", "")
	var modifiers = modifier_data.get("modifiers", {})
	var duration = modifier_data.get("duration", "")
	var tooltip = display_name_value + "\n" + description + ("\nActive for " + duration if duration != "" else "") + "\nAttribute Modifiers:\n"
	for attr in modifiers.keys():
		var mod_value = modifiers[attr]
		var mod_text = "%s: %s%d\n" % [attr.capitalize(), "+" if mod_value >= 0 else "", mod_value]
		tooltip += mod_text
	self.set_tooltip_text(tooltip)
	icon.texture = load(modifier_data.get("icon", "res://path/to/default/icon.png")) # @TODO Add Default Icon
