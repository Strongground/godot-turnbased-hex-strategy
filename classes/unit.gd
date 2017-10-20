extends "res://classes/entity.gd"

# Public class members
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
# unit id, from which all additional data like sprite, unit attributes, name etc
# are loaded from units.data
export var unit_id = ''
#################################################################################
# Unit attributes. 
# Due to the nature of this approach, the unit class currently needs to know of
# the existence of each and every attribute that exists. They are exported here, 
# so that a unit may be edited to be special via editor.
#################################################################################
# display_name
# base_defense
# type (hard, soft, air, sea)
# movement
# can_traverse
# # attack
# base_attack_hard
# base_attack_soft
# base_attack_air
# base_attack_sea

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

# If unit should face right, flip it. Otherwise, do nothing
# because all units should face left per default.
func _set_direction():
	if self.direction == "RIGHT":
		self.unit_sprite.set_flip_h(true)

func _input(event):
	pass

func _process(delta):
	pass

# Find a path to the target position from the current position of this unit
# @input {Vector2} The target position
func _find_path(target_position):
	pass