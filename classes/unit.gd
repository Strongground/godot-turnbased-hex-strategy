extends Node

### public class member vars
# unit type
export (bool) var unit_type = null
# unit owner
export (int) var unit_owner = null
# unit faction
export (int) var unit_faction = null
# direction the unit is facing visually
# 0 is left, 1 is right
export (int) var direction = null
# if a unit has e.g. various camo schemes (desert, woodland) or randomized appearance
# the detailed documentation for these go into the faction object
export (int) var graphical_scheme = null

func _ready():
	## Called every time the node is added to the scene.
	# visual direction of unit, 0 is "left", 1 is "right"
	direction = 1
	# 0 is "desert", 1 is "woodland"
	graphical_scheme = 1
	set_fixed_process(true)
	set_process_input(true)
	
func _input(event):
	# if event.type == InputEvent.MOUSE_BUTTON and event.button_index == BUTTON_LEFT and event.pressed:
	#     print("Clicked " + self.get_name())
	pass