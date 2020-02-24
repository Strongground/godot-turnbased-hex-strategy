extends "res://classes/entity.gd"

# Public class members

# unit owner
# expect identifier of player
export (int) var unit_owner = 0
# unit faction
# expect id of faction based on imported factions file from theme
export var unit_faction = ''
# direction the unit is facing visually
# @TODO this must be changed so it can be used with 1-6 directions. Possible directions
# and their resprective mappings would be:
# * "none" (For static entites like buildings)
# * "left/right" = 0/1 (Done in software by mirroring?)
# * "northwest/north/northeast/southeast/south/southwest" = 0,1,2,3,4,5,6
export (int) var direction = 0
# if a unit has e.g. various camo schemes (desert, woodland) or randomized appearance.
# the detailed documentation for these go into the faction object
export (int) var graphical_scheme = null
# unit id, from which all additional data like sprite, unit attributes, name etc
# are loaded from units.data
export var unit_id = ''
#################################################################################
# 
# Unit Attributes
# 
# Due to the nature of the current approach, the unit class currently needs to
# know of the existence of each and every attribute that exists. They are 
# exported here, so that a unit may be edited to be special via editor.
#
# Questions remaining to be answered: 
# * How to describe what bonuses are active at a given unit instance?
# Easiest would be IDs in an array, which is bound to a specific purpose, like
# containing modifiers to defense value for this unit. This allows to give as
# many modifiers to a unit as desired.
# Downside of this approach: Either a lot of Arrays will exist, or modifiers
# can only be added to some base values. Which probably will be the smallest
# tradeoff.

#################################################################################
# Display name. This is a short string shown in-game.
export var display_name = ''

# Description of the unit, possibly shown in a ingame encyclopedia or on the
# extended info-screen for this unit.
export var description = ''

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
export (int) var armor = null

# What medium this unit can move in/on primarily.
# Expects an array with one string per traversable terrain type:
# "land", "river", "water", "mountain"
export (Array, String) var can_traverse = []

# Movement points
# These are consumed when moving from one tile to another tile. The amount of points
# used for this is based on the terrain type of the tile that is entered (not the one
# the unit is coming from).
export (int) var movement_points = null

# Fuel
# This is a one-time value that only decreases with each movement over a hex tile.
# Based on the movement cost of the terrain, more or less fuel will be consumed, 
# if this will be calculated with a factor or 1:1 is to be decided.
# If fuel reaches 0, the unit cannot move any more.
# If fuel is -1, the check for enough fuel before each movement is ignored (for
# units that do not rely on motorization, like infantry).
# 
# @TODO In real life, if a armored unit would run out of fuel with no chance
# of resupply, they will certainly not sit there and wait. So in theorey, nothing
# speaks against a mechanism that allows to tell crew to eject and continue fighting
# on foot. Such a system is needed anway for motorized transport, siege towers, landing
# craft, paratroopers etc.
# It also means, that we need at least two additional attributes to simulate this to
# some degree of realism: 
# - "passengers" includes a reference to the unit transported
# - "capturable_by" a list of 0-n unit IDs, describing which units are able to make
# use of this equipment. If 0, it is not capturable. If -1 it is usable by all (think
# simple wooden siege ram, only requires muscle, no special skills, whereas you require
# a trained tank crew or pilot to commandeer a tank or plane.
# This system also would also allow for some fun stuff like a building (scenario goal?)
# that is only capturable by a spy etc. (Stealing blueprints or something like that).
export (int) var fuel = null

# Weapon
# What kind of main attack the unit has. Contains the ID of a weapon which is
# in detail described in the weapons.yaml that comes with the game theme.
# @TODO At the moment this only allows for one type of weapon per unit.
# In theory nothing speaks against multiple weapons per unit as would be the case
# in almost all real life examples (main weapon & sidearm like sword & dagger, rifle
# & grenades, vehicle cannon & machinegun etc.)
# It could be narrowed down to min 0 weapons, max x weapons for a unit. This way
# there can be unarmed units as well as units with secondary attacks. Think 
# fighter aircraft with a multitude of cannons, bombs, rockets etc.
# Since this warrants additional logic back- and frontend, this will be an after-
# thought for now.
export (int) var main_weapon = null

# Ammo for main weapon
# Basically, how many times can this unit attack until ammo runs out, not really how
# many shots it carries.
# An "attack" is the abstraction of the concept of an "attack run" or "fire mission".
# Think a fire mission for an artillery brigade, or support fire given by a vehicle
# group, where dozens/hundreds/thousands of shots may be fired.
export (int) var main_ammo = null

# Attack bonus
# This can be thought of as a "base_attack" bonus value to the unit. It could be used
# to signify better training of this unit or technical characteristics that would give
# it a significant attack boost compared to another unit with the same main_weapon. 
# It is simply added to the "main_weapon"s "attack_strength" value.
# Most often this will be set via modifiers.
export (int) var attack_bonus = null

# Unit sprites
# This array is for the representation of the unit in the game. It is responsible
# for the rendering of a unit on the game map itself.
# This will probably change some times in the future to allow for a maximum of
# flexibility in how much effort one want to put into unit graphics.
# So this should be able to accomododate everything between 1 static graphic (no
# direction specific graphics) up to 6 images for each possible direction.
export (Array) var unit_sprites = []

# Private class members
var animation_step_active = false
var animation_step = 0
var animation_path_array = []
var offset = null
var entity_representation = null
var last_movement_angle = null
var max_movement_points = 0

# This function simply is a getter for the unit_id string, corresponding to
# one entry in the theme files.
func get_unit_id():
	return unit_id

# This function capsulates all actions necessary to move this unit
# from a start_point of the map to an end_point if it is possible.
# @input start_point {Vector2} The coordinates of the startpoint of the movement.
# This can differ from the current position of the unit if this method is used
# in cutscenes etc.
# @input end_point {Vector2} The coordinates of the target of the movement
# @input entity {Object} This is a reference to the entity in-game representing
# this unit and is needed to be passed back to a callback.
func move_unit(start_point, end_point, entity):
	var new_path = game.find_path(start_point, end_point)
	var path_cost = 0
	for i in range(new_path.size()):
		var tile = new_path[i]
		if i > 0:
			if path_cost + tile.move_cost > self.movement_points:
				print("This movement would be too expensive: "+String(path_cost + tile.move_cost))
				return false
			path_cost += tile.move_cost
	self.set_path(new_path)
	# This is a debug method to visualize the path found by the pathfinding
#	game._show_path(new_path)
	self.animate_path(new_path, entity)
	self.deselect()

# Set crest icon based on faction of unit
func _set_faction_icon():
	var icon_texture = $"/root/Game/ThemeManager".get_faction_icon(self.unit_faction)
	$FactionIcon.set_texture(icon_texture)

# This function sets the sprite of the unit according to the themes-data object
# and the direction of the unit
# @input {int} The direction of the unit
func _set_sprite(direction):
	var sprites = $"/root/Game/ThemeManager".get_unit_sprites(unit_id)
	var theme_name = $"/root/Game/ThemeManager".get_current_theme_name()
	var sprite_scale = $"/root/Game/ThemeManager".get_sprite_scale(unit_id)
	var sprite_index = null
	var texture = null
	# If only one sprite per unit, use it (or the automatically generated 
	# flipped version to match general direction of unit),
	# else, use the apropriate oriented sprite out of the six possible ones.
	if sprites.size() == 2:
		sprite_index = 0
		if direction <= 2:
			sprite_index = 1
	elif sprites.size() == 6:
		sprite_index = direction
	# Load texture based on above information
	texture = load("res://themes/"+theme_name+"/"+sprites[sprite_index])
	$UnitImage.set_texture(texture)
	if sprite_scale:
		$UnitImage.set_scale(Vector2(sprite_scale, sprite_scale))

# This resets movement points to original value (e.g. when turn ends)
func reset_movement_points():
	self.movement_points = self.max_movement_points
	self._update_movementpoints_indicator()

# This function returns a boolean indicating if the currently active player
# is the owner of this unit.
func owned_by_active_player():
	print("ID of clicked unit:")
	print(game.active_player.get_id())
	print(self.unit_owner)
	return game.active_player.get_id() == self.unit_owner

# Returns the stance of the player this unit belongs to towards the current player.
# @returns {String} The stance of the owner of this unit to the current player.
# Can be one of: 'enemy', 'ally', 'neutral'
func get_unit_stance():
	var owner_player = game.playerMgr.get_player_by_id(self.unit_owner).node
	var stance = owner_player.get_stance_to(game.active_player)
	return stance

# This function should update the appearance of the unit, calculate stat
# changes etc. after each round. There is no need to do this in _process
# since its all turnbased anyway.
func update():
	self._set_sprite(direction)
	self._set_faction_icon()
	
# Public getter for movement points of this unit.
# @outputs {int} Movement points of this unit
func get_movement_points():
	return self.movement_points

# Internal, updates movement points based on next tile movement.
func _update_movement_points(target_tile):
	self.movement_points -= target_tile.move_cost
	self._update_movementpoints_indicator()

# Internal, updates the indicator at the unit to show the movement points.
func _update_movementpoints_indicator():
	$MovementPointsIndicator.set_bbcode('[center]'+String(self.movement_points)+'[/center]')

# Public getter for ammo left in this unit.
# @outputs {int} Movement points of this unit
func get_ammo():
	return self.main_ammo

# Public getter that checks if this unit is able to move.
# If it is a non-motorized unit, or fuel AND movement points are positive,
# return "true", else if fuel AND movement points are depleted, return false.
func can_move():
	if self.fuel == -1 or (self.fuel > 0 and self.movement_points > 0):
		return true
	elif self.fuel == 0 or self.movement_points == 0:
		return false

# This function returns a Boolean indicating if it can attack a given unit,
# or if no target is given, general combat readiness.
# It takes into consideration both the state of this unit as well as the
# type and position of the given enemy unit.
# If nothing definitive can be determined, return false per default.
# @input {Object} The enemy unit
# @outputs {Boolean} 
func can_attack_unit(enemy_unit):
	if enemy_unit != null:
		var is_in_range = self._is_in_range(enemy_unit.get_global_position())
		var has_weapon = self.main_weapon != null
		var has_ammo = self.main_ammo > 0
		if has_weapon and has_ammo and self.can_move() and is_in_range == true:
			return true
	return false

# Public getter for general combat readiness. This definition will likely
# change later, as this can be different for different types of units as
# well as may change due to design changes. Requires a unit fuel and movement-
# points to attack? At the moment, I say "yes".
func combat_ready():
	var has_weapon = self.main_weapon != null
	var has_ammo = self.main_ammo > 0
	if has_weapon and has_ammo and self.can_move():
		return true
	return false

# Determines if the target (a grid position) is a valid attack target
# for this unit.
func is_valid_attack_target(grid_pos):
	# Check if unit exists at position
	var is_unit = game._is_unit(grid_pos, true)
	if is_unit != null:
		# Check if unit is hostile
		var unit = is_unit.node
		if unit.get_unit_stance() == 'enemy':
			# Check if valid attack target for currently selected units weapons
			var enemy_unit = unit
			if self.can_attack_unit(enemy_unit) == true:
				print("Can attack unit")
				return true

# Attack a unit/entity
func attack(entity):
	print('ATTACKING!')
	self.main_ammo -= 1
	return true

# Function to fill the attributes of the unit from the themes data object
# corresponding to it. If a value was filled by the level editor with a non-
# default value, it will not be overwritten.
# @input {Dictionary} a dict containing all the attribute values for this unit
func fill_attributes(data_object):
	for entry in data_object:
		if entry in self:
			set(entry, data_object[entry])
	self._update_movementpoints_indicator()
	self.max_movement_points = self.movement_points

# Animates this units movement on a given path from one tile to another over
# n tiles in between
# @input path_array {Array} the array containing every tile in order of the path
# @input entity {Object} this is the entity which represents this unit in the game.
# It must be passed so it can be used in a callback later.
func animate_path(path_array, entity):
	self.entity_representation = entity
	animation_path_array = path_array
	_animate_step(path_array[0], 0, path_array.size())

##### Internal methods
func _animate_step(current_tile, step, max_steps):
	var easing = Tween.EASE_IN_OUT
	var timing = null
	if step > 0:
		self._update_movement_points(current_tile)
	animation_step_active = true
	animation_step = step
	self.direction = self._get_direction(rad2deg(self.get_angle_to(_get_centered_grid_pos(current_tile['grid_pos'], self.offset))))
	if step == 0:
		timing = Tween.TRANS_SINE
	elif step == max_steps-1:
		timing = Tween.TRANS_QUAD
		easing = Tween.EASE_OUT
	else:
		timing = Tween.TRANS_LINEAR
	$MoveTween.interpolate_property(self, 'position', self.get_global_position(), _get_centered_grid_pos(current_tile['grid_pos'], self.offset), 1, timing, easing)
	$MoveTween.start()
	
	
# From the last movements angle, get the direction mapped, so it references
# to a direction sprite from the theme.
func _get_direction(angle):
	var direction = 0
	if angle > 145 && angle < 155:
		direction = 0
		# print("Moving southwest")
	elif angle > -155 && angle < -145:
		direction = 1
		# print("Moving northwest")
	elif angle > -95 && angle < -85:
		direction = 2
		# print("Moving north")
	elif angle > -35 && angle < -25:
		direction = 3
		# print("Moving northeast")
	elif angle > 25 && angle < 35:
		direction = 4
		# print("Moving southeast")
	elif angle > 85 && angle < 95:
		direction = 5
		# print("Moving south")
	return direction
	
# @TODO Find out how to calc distance between two points, read up on
# red blob games blog about it.
func _is_in_range(target):
	return true

func _ready():
	## Init ingame
	type = 'unit'
	# Set necessary offset for correct position relative to grid
	offset = Vector2(-6, 0)
	set_process_input(true)

func _input(event):
	pass

func _process(delta):
	pass

func _on_MoveTween_tween_completed(object, key):
	animation_step_active = false
	if animation_path_array.size()-1 > animation_step:
		# Animate next step
		animation_step += 1
		_animate_step(animation_path_array[animation_step], animation_step, animation_path_array.size())
		self.update()
	else:
		# Done animating, update unit locally
		self.update()
		# ...then call global update
		# Global update is for udpating global look-up tables with grid positions
		root.update_entity_list_entry(entity_representation)
