extends "res://classes/entity.gd"

# Public class members
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
# Due to the nature of the current approach, the unit class currently needs to
# know of the existence of each and every attribute that exists. They are 
# exported here, so that a unit may be edited to be special via editor.
# ---
# To make it possible to have a complex system of bonuses and maluses for units
# values, that can be dynamically given to units based on location on the map
#  e.g. "entrenched, giving a bonus to defense against explosive weapons" or 
# "retreat"/"wounded" that are given by the scenario, and may wear off after a given
# number of rounds, there needs to be an external list of generic bonuses. These 
# will not be part of a base game but theme- or even scenario-specific.
# A hierarchy system will be used, where game-global bonuses are extended by game-
# theme bonuses which are in turn extended by scenario-specific bonuses.
# 
# Questions remaining to be answered: 
# * How to describe what bonuses are active at a given unit instance?
# Easiest would be IDs in an array, which is bound to a specific purpose, like
# containing modifiers to defense value for this unit. This allows to give as
# many modifiers to a unit as desired.
# Downside of this approach: Either a lot of Arrays will exist, or modifiers
# can only be added to some base values. Which probably will be the smallest
# tradeoff.
# 
# * How are weapons and their generic effects on target types described?
# Since weapons are theme-bound - just like units - it makes sense to describe them
# in the same manner: via YAML files containing structured information about weapons
# and their respective effects.

#################################################################################
# Display name. This is a string shown in-game.
export var display_name = ''

# Base defense value, this is used as a base to calculate how well this unit can
# defend from an attack. Based on the kind of attack, additional values are added
# These can also depend on the tile the unit is on, as well as type of the unit.
export (int) var base_defense = null

# Is this unit armored? How much? Generally, armor piercing weapons have a greater effect on 
# armored targets, while explosive weapons have a bigger effect against soft targets.
# In alternative themed game-settings, this can act as a simple defense bonus, meaning
# that armored troops generally have more chance to not sustain a lot of damage when
# hit by certain weapons, while non-armored units do (e.g. classical roman era, where arrows
# against velites would do more damage than against heavily armored triarii).
# @TODO How is this calculated, together with base_defense and AT/HE weapons?
export (int) var armor = 0

# What medium this unit can move in/on primarily.
# Expectes an array with one String per traversable terrain type:
# "LAND", "AIR", "RIVER", "WATER"
export (Array, String) var can_traverse = []

# Movement points
# These are consumed when moving from one tile to another tile. The amount of points
# used for this is based on the terrain type of the tile that is entered (not the one
# the unit is coming from).
export (int) var movement_points = 0

# Weapon
# What kind of main attack the unit has. Contains the ID of a weapon which is
# in detail described in the weapons.yaml that comes with the game theme.
# @TODO At the moment this only allows for one type of weapon per unit.
# In theory nothing speaks against multiple weapons per unit as would be the case
# in almost all real life examples (main weapon & sidearm like sword & dagger, rifle
# and & grenades, cannon & machinegun etc.)
# It could be narrowed down to min 0 weapons, max 2 weapons for a unit. This way
# there can be unarmed units as well as units with secondary attack. 
# Since this warrants additional logic back- and frontend, this will be an after-
# thought for now.
export (int) var main_weapon = 0

# Ammo for main weapon
# Basically, how many times can this unit attack until ammo runs out, not really how
# many shots it carries.
# An "attack" is the abstraction of the concept of an "attack run" or "fire mission".
# Think a fire mission for an artillery brigade, or support fire given by a vehicle
# group, where hundreds/thousands of shots are fired.
export (int) var main_ammo = 0

# Attack bonus
# This can be thought of as a "base_attack" bonus value to the unit. It could be used
# to signify better training of this unit or technical characteristics that would give
# it a significant attack boost compared to another unit with the same main_weapon. 
# It is simply added to the "main_weapon"s "attack_strength" value.
# Most often this will be set via modifiers.
export (int) var attack_bonus = 0

# Private class members
var animation_step_active = false
var animation_step = 0
var animation_path_array = []
var offset = null
var entity_representation = null

# This function returns a boolean indicating if the currently active player
# is the owner of this unit.
func owned_by_active_player():
	return root.player_active['id'] == self.unit_owner

# This function should update the appearance of the unit, calculate stat
# changes etc. after each round. There is no need to do this in _process
# since its all turnbased anyway.
func update():
	self._set_direction()
	

# Animates this units movement on a given path from one tile to another over
# n tiles in between
# @input {Array} the array containing every tile in order of the path
# @input {Object} this is the entity which represents this unit in the game.
# It mus be passed so it can be used in a callback later.
func animate_path(path_array, entity):
	self.entity_representation = entity
	animation_path_array = path_array
	_animate_step(path_array[0], 0)

##### Internal methods

func _animate_step(current_tile, step):
	animation_step_active = true
	animation_step = step
	$MoveTween.interpolate_property(self, 'position', self.get_global_position(), get_centered_grid_pos(current_tile['grid_pos'], self.offset), 1, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
	$MoveTween.start()

func _ready():
	## Init ingame
	type = 'unit'
	# Set necessary offset for correct position relative to grid
	offset = Vector2(-6, 0)
	set_process_input(true)

# If unit should face right, flip it. Otherwise, do nothing
# because all units should face left per default.
func _set_direction():
	if self.direction == "RIGHT":
		$UnitImage.set_flip_h(true)
	
func _input(event):
	pass

func _process(delta):
	pass

func _on_MoveTween_tween_completed(object, key):
	animation_step_active = false
	if animation_path_array.size()-1 > animation_step:
		# Animate next step
		animation_step += 1
		_animate_step(animation_path_array[animation_step], animation_step)
	else:
		# Done animating, update unit locally
		self.update()
		# ...then call global update
		# Global update is for udpating global look-up tables with grid positions
		root.update_entity_list_entry(entity_representation)
