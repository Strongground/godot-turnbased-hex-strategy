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
var move_tween = null
var animation_step_active = false
var animation_step = 0
var animation_path_array = []
var offset = null

# This function should update the appearance of the unit, calculate stat changes etc.
# ater each round. There is no need to do this in _process since its all turnbased anyway.
func update():
	self._set_direction()

# Animates this units movement on a given path from one tile to another over via n tiles
# @input {Array} the array containing every tile in order of the path
func animate_path(path_array):
	animation_path_array = path_array
	_animate_step(path_array[0], 0)

func _animate_step(current_tile, step):
	animation_step_active = true
	self.animation_step = step
	move_tween.interpolate_property(self, 'transform/pos', self.get_global_pos(), get_centered_grid_pos(current_tile['grid_pos'], self.offset), 1, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	move_tween.start()

##### Internal methods
func _ready():
	## Init ingame
	type = 'unit'
	# Set necessary offset for correct position relative to grid
	offset = Vector2(-6, 0)
	set_fixed_process(true)
	set_process_input(true)
	unit_sprite = find_node('UnitImage')
	move_tween = find_node('MoveTween')

# If unit should face right, flip it. Otherwise, do nothing
# because all units should face left per default.
func _set_direction():
	if self.direction == "RIGHT":
		self.unit_sprite.set_flip_h(true)

# Calculate the path from a given tile to another given tile, all in grid local coordinates
# @input {Vector2} current_position - from where to calculate the path
# @input {Vector2} target_position
# @returns {Array} list of tiles to visit, in order of visitation
func _get_path(target_position):
	return root._visit_map(self.grid_location, target_position)
	
func _input(event):
	pass

func _process(delta):
	pass

func _on_MoveTween_tween_complete(object, key):
	animation_step_active = false
	if animation_path_array.size()-1 > animation_step:
		# Animate next step
		animation_step += 1
		_animate_step(animation_path_array[animation_step], animation_step)
	else:
		# Done animating, update unit
		self.update()