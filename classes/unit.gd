extends "res://classes/entity.gd"

# Public class members
# unit id, from which all additional data like sprite, gameplay attributes, name etc
# are loaded from units.data
export var unit_id = ''
# unit type
# possible values: air=1, land=2, sea=3, river=4
export (int) var unit_type = 1
# unit owner
# expect index of player 
export (int) var unit_owner = 0
# unit faction
# expect index of faction based on imported factions file
# @TODO create faction manager where an array with faction objects is created 
# based on a data file, containing detailed information about units, rules, names, etc.
export (int) var unit_faction = 0
# direction the unit is facing visually
export (String, "LEFT", "RIGHT") var direction = "RIGHT"
# if a unit has e.g. various camo schemes (desert, woodland) or randomized appearance
# the detailed documentation for these go into the faction object
export (int) var graphical_scheme = null

# Private class members
var unit_sprite = null

# This function should update the appearance of the unit, calculate stat changes etc.
# ater each round. There is no need to do this in _process since its all turnbased anyway.
func update():
	self._set_direction()

##### Internal methods
func _ready():
	## Init ingame
	set_fixed_process(true)
	set_process_input(true)
	unit_sprite = find_node('UnitImage')
	# Call _update to set all attributes and appearance initially based on editor config
	self.update()

# If unit should face right, flip it
func _set_direction():
	if self.direction == "RIGHT":
		self.unit_sprite.set_flip_h(true)

func _input(event):
	pass

func _process(delta):
	pass