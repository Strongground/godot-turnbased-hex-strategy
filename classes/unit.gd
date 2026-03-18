extends "res://classes/entity.gd"

# Public class members

@export_group("Unit Properties")
# entity owner
# expect identifier of player
# @TODO Ugly hack! This must be gotten from the PlayerManager 
@export_enum("Human Tester:0", "Test AI (Dumb):1", "Test AI (Clever):2", "Refugees:3") var unit_owner: int = 0

# entity faction
# expect id of faction based on imported factions file from theme
# @TODO Ugly hack! This must be gotten from the ThemeMgr
@export_enum("Unset:", "US Army:usarmy", "Taliban:taliban", "Civilians:civilians") var unit_faction: String = ""

# direction the entity is facing visually
# @TODO this must be changed so it can be used with 1-6 directions. Possible directions
# and their respective mappings would be:
# * "none" = -1 (For static entites like buildings)
# * "left/right" = 0/1 (Done in software by mirroring)
# * "northwest/north/northeast/southeast/south/southwest" = 0,1,2,3,4,5
@export var direction = 0

# if a entity has e.g. various camo schemes (desert, woodland) or randomized appearance.
# the detailed documentation for these go into the faction object
# @TODO Ugly hack! This must be gotten from the ThemeMgr and the actual unit
@export_enum("Default:0", "Variant 1:1", "Variant 2:2", "Random:-1") var graphical_scheme: int = 0

# entity id, from which all additional data like sprite, entity attributes, name etc
# are loaded from units.data
@export var unit_id = ''

# For debugging sprite loading in detail
@export var debug_logging = false

#################################################################################
# 
# Unit Attributes
# 
# Due to the nature of the current approach, the entity class currently needs to
# know of the existence of each and every attribute that exists. They are 
# exported here, so that a entity may be edited to be special, via the editor.
#
# Questions remaining to be answered: 
# * How to describe what bonuses are active at a given entity instance?
# Easiest would be IDs in an array, which is bound to a specific purpose, like
# containing modifiers to defense value for this entity. This allows to give as
# many modifiers to a entity as desired.
# Downside of this approach: Either a lot of Arrays will exist, or modifiers
# can only be added to some base values. Which probably will be the smallest
# tradeoff.

# More questions and implementation thoughts:
# * How does experience works?
# * Can units be used in multiple connected scenarios? What info is tracked for
# the entity in this case? Killcount? Experience?
# * We need at least two additional attributes to simulate transportation and 
# the nature of vehicles to some degree of realism: 
# - "passengers" includes a reference to the entity transported
# - "capturable_by" a list of 0-n entity IDs, describing which units are able to make
# use of this equipment. If 0, it is not capturable. If -1 it is usable by all (think
# simple wooden siege ram, only requires muscle, no special skills, whereas you require
# a trained tank crew or pilot to commandeer a tank or plane.
# This system also would also allow for some fun stuff like a building (scenario goal?)
# that is only capturable by a spy etc. (Stealing blueprints or something like that).

#################################################################################
# Display name. This is a short string shown in-game.
@export var display_name = ''

# Description of the entity, possibly shown in a ingame encyclopedia or on the
# extended info-screen for this entity.
@export var description = ''

# If this entity has the ability to hold supplies and also resupply allied units nearby.
@export var is_supplier = null

# The amount of supplies this entity can hold, if it is a supplier.
@export var max_supply_storage = null

# How much fuel supplies can this entity hold? This amount, added with all other supply types,
# can never exceed "this.max_supply_storage".
@export var supply_storage_fuel = 0

# How much ammo supplies can this entity hold? This amount, added with all other supply types,
# can never exceed "this.max_supply_storage".
@export var supply_storage_ammo = 0

# How much support supplies can this entity hold? This amount, added with all other supply types,
# can never exceed "this.max_supply_storage".
# 'Support' can refer to both medical equipment and food, so depending on the situation, the entity
# type and the scenario, this may be used with some flexibility.
@export var supply_storage_support = 0

# How much construction supplies can this entity hold? This amount, added with all other supply types,
# can never exceed "this.max_supply_storage".
@export var supply_storage_construction = 0

# The Unit's strength defines, depending on the nature of the entity, its technical
# or medical status.
# For example, a standard squad consists of 8 men. This translates
# directly to entity strength of "8". A successful hit against this entity may remove
# 1-2 points, making 1-2 men unable to fight (killing or wounding is threated equally
# here).
# For another example, a light vehicle group may consist of 3 vehicles, being able
# to function with some damage sustained, it could translate into 4 strength points.
# If the entity's strength drops to 0, the entity is considered lost, either destroyed or
# combat-ineffective. It is not shown any more on the game map.
# The attack value of this entity is also factored by the entity's strength. The lesser
# of a entity remains, the less damage it is able to inflict.
@export var unit_strength = null

# Base defense value, this is used as a base to calculate how well this entity can
# defend from an attack. Based on the kind of attack, additional values are added
# These can also depend on the tile the entity is on, as well as type of the entity.
@export var base_defense = null

# Is this entity armored? How much? Generally, armor piercing weapons have a greater effect on 
# armored targets, while explosive weapons have a bigger effect against soft targets.
# In alternative themed game-settings, this can act as a simple defense bonus, meaning
# that armored troops generally have more chance to not sustain a lot of damage when
# hit by certain weapons, while non-armored units do (e.g. classical roman era, where arrows
# against velites would do more damage than against heavily armored triarii).
@export var armor = null

# What medium this entity can move in/on primarily.
# Expects an array with one string per traversable terrain type:
# "land", "river", "water", "mountain"
@export var can_traverse = []

# Movement points
# These are consumed when moving from one tile to another tile. The amount of points
# used for this is based on the terrain type of the tile that is entered (not the one
# the entity is coming from).
@export var movement_points = null

# Fuel
# This is a one-time value that only decreases with each movement over a hex tile.
# Based on the movement cost of the terrain, more or less fuel will be consumed, 
# if this will be calculated with a factor or 1:1 is to be decided.
# If fuel reaches 0, the entity cannot move any more.
# If fuel is -1, the check for enough fuel before each movement is ignored (for
# units that do not rely on motorization, like infantry).
# 
# @TODO In real life, if a armored entity would run out of fuel with no chance
# of resupply, they will certainly not sit there and wait. So in theory, nothing
# speaks against a mechanism that allows to tell crew to eject and continue fighting
# on foot. Such a system is needed anway for motorized transport, siege towers, landing
# craft, paratroopers etc.
@export var fuel = null

# Weapons
# What kind of attacks the entity has. Contains an array of the IDs of the weapons 
# which are in detail described in the weapons.yaml that comes with the game theme.
# This allows for multiple weapons per entity as would be the case
# in almost all real life examples (main weapon & sidearm like sword & dagger, rifle
# & grenades, vehicle cannon & machinegun etc.)
# Its rule can be narrowed down to "min 0 weapons, max x weapons for a entity". This way
# there can be unarmed units as well as units with secondary, tertiary... attacks. Think 
# fighter aircraft with a multitude of cannons, bombs, rockets etc.
# Since fully utilizing this and creating a system with matching ammo for each weapon
# warrants additional logic back- and frontend, this will be an after-thought for now.
@export var weapons = null

# Ammunition for its own weapons
# Basically, how many times can this entity attack until ammo runs out, not really how
# many shots it carries.
# An "attack" is the abstraction of the concept of an "attack run" or "fire mission".
# Think a fire mission for an artillery brigade, or support fire given by a vehicle
# group, where dozens/hundreds/thousands of shots may be fired.
# @TODO At the moment this is only a int, in future it needs to be converted to array or
# similar, to represent ammunition for each type of weapon, but also to allow for shared
# ammo for similar weapons (same caliber e.g.)
@export var ammo = null

# Attack bonus
# This can be thought of as a "base_attack" bonus value to the entity. It could be used
# to signify better training of this entity or technical characteristics that would give
# it a significant attack boost compared to another entity with the same weapons. 
# It is simply added to the "weapons"[0]s "attack_strength" value.
# Most often this will be set via modifiers.
# Usage example: Standard infantry with assault rifles vs. elite commando units,
# using the same assault rifles but having much more skill, experience and training,
# thus doing more damage with the same weapon.
@export var attack_bonus = null

# Experience
# This is mostly a mechanic to gratify players for keeping their units alive for a long time.
# The gameplay effect is minor, experience level is mapped to one of n ranges. Each range 
# gives a multiplier. The multiplier negates (according to its value, higher == more) the
# inherent randomness in a lot of actions, e.g. getting hit, chance of hitting another entity,
# the order of single combat actions etc.
# It tries to portrait the increased routine and its effect in cancelling out the random influence
# in actions during combat.
@export var experience = 0

# Unit sprites
# This array is for the representation of the entity in the game. It is responsible
# for the rendering of a entity on the game map itself.
# This accomododates everything between 1 static graphic (no direction specific graphics,
# in which case the game automatically creates a mirrored version to have at least two
# directional graphics) up to 6 images for each possible direction.
@export var unit_sprites = []

# Modifiers
# This array contains the IDs of all modifiers that should be applied to the entity.
# When the game starts, the corresponding modifier objects are pulled from the theme
# and their effects applied to the units base stats.
# Also, a 'has modifier/s' icon is shown at the entity in-game which, on hover, reveals the
# name and effects of the modifiers. Details can be found in the units detail screen (description
# and maybe icon of each modifier, mostly)
@export var modifiers = []

# Private class members
var animation_step_active = false
var animation_step = 0
var animation_path_array = []
var offset = null
var entity_representation = null
var last_movement_angle = null
var max_movement_points = 0
var experience_definitions = null
var active_modifiers = {}
var state_save = {}
@export_group("Internal Node References")
@export var unit_quick_panel: Control
@export var qp_strength_text: RichTextLabel
@export var qp_movement_text: RichTextLabel
@export var qp_ammo_text: RichTextLabel

@onready var sound_emitter = $'SoundEmitter'
@onready var attack_delay_timer = $'AttackEffectDelay'
@export var settingsMgr: Node
@export var themeMgr: Node
@export var gui: Node
@export var sfxMgr: Node

# This function simply is a getter for the unit_id string, corresponding to
# one entry in the theme files.
func get_unit_id():
	return unit_id

# Public getter for display name
func get_unit_name():
	return display_name

# This function capsulates all actions necessary to move this entity
# from a start_point of the map to an end_point if it is possible.
# @input start_point {Vector2} The coordinates of the startpoint of the movement.
# This can differ from the current position of the entity if this method is used
# in cutscenes etc.
# @input end_point {Vector2} The coordinates of the target of the movement
# @input entity {Object} This is a reference to the entity in-game representing
# this entity and is needed to be passed back to a callback.
func move_unit(start_point, end_point, moving_entity):
	var new_path = game.find_path(start_point, end_point, self)
	if new_path.is_empty():
		print("No valid path found from " + str(start_point) + " to " + str(end_point))
		return false
	var path_cost = 0
	for i in range(new_path.size()):
		var tile = new_path[i]
		if i > 0:
			if path_cost + tile.move_cost > self.movement_points:
				print("This movement would be too expensive: "+str(path_cost + tile.move_cost))
				return false
			path_cost += tile.move_cost
	self.set_move_path(new_path)
	# This is a debug method to visualize the path found by the pathfinding
	# game._show_path(new_path)
	self._play_sound('move')
	self.animate_path(new_path, moving_entity)
	self.deselect()
	# Update movement points display
	# gui.update_unit_info("","","","")

func show_quick_panel() -> void:
	# Figure out entities position + offset so panel is above it
	var grid_coords = hexmap.global_to_map(self.get_global_position())
	unit_quick_panel.show()
	unit_quick_panel.set_global_position(self._get_centered_grid_pos(grid_coords, Vector2(-100,50)))
	_update_quick_panel()
	
func hide_quick_panel() -> void:
	unit_quick_panel.hide()
	
func _update_quick_panel() -> void:
	qp_strength_text.text = str(self.get_strength_points())
	qp_movement_text.text = str(self.get_movement_points())
	qp_ammo_text.text = str(self.get_ammo())

# Set crest icon based on faction of entity
func _set_faction_icon():
	var icon_texture = themeMgr.get_faction_icon(self.unit_faction)
	$Flag/FlagSin.set_texture(icon_texture)

# Public getter for faction
# @returns {String} The id of the faction according to theme
func get_faction():
	return self.unit_faction

# This function sets the sprite of the entity according to the themes-data object
# and the direction of the entity
# @input {int} The direction of the entity
func _set_sprite(dir):
	var sprites = themeMgr.get_unit_sprites(unit_id)
	_debug_log("_set_sprite(): direction=" + str(dir) + ", sprites_from_theme=" + str(sprites))
	var sprite_scale = themeMgr.get_sprite_scale(unit_id)
	if sprites == null or sprites.is_empty():
		push_warning("Unit '" + str(unit_id) + "': No sprite paths returned by ThemeManager.")
		_debug_log("_set_sprite(): no sprites returned, abort.")
		return
	var sprite_index = 0
	# If only one sprite per entity, use it (or the automatically generated 
	# flipped version to match general direction of entity),
	# else, use the apropriate oriented sprite out of the six possible ones.
	if sprites.size() == 2:
		if dir <= 2:
			sprite_index = 1
	elif sprites.size() > 1:
		sprite_index = clampi(dir, 0, sprites.size() - 1)
	_debug_log("_set_sprite(): using sprite_index=" + str(sprite_index) + " out of " + str(sprites.size()))
	var sprite_path = str(sprites[sprite_index])
	if not sprite_path.begins_with("res://"):
		var theme_name = themeMgr.get_current_theme_name()
		sprite_path = "res://themes/%s/%s" % [theme_name, sprite_path]
	_debug_log("_set_sprite(): loading texture from '" + sprite_path + "'")
	# Load texture based on above information
	var texture = load(sprite_path) as Texture2D
	if texture == null:
		push_warning("Unit '" + str(unit_id) + "': Could not load sprite '" + sprite_path + "'.")
		_debug_log("_set_sprite(): texture load FAILED. UnitImage keeps current texture.")
		return
	$UnitImage.texture = texture
	_debug_log("_set_sprite(): texture set successfully. resource_path='" + str(texture.resource_path) + "'")
	if sprite_scale:
		$UnitImage.scale = Vector2(sprite_scale, sprite_scale)
		_debug_log("_set_sprite(): applied sprite_scale=" + str(sprite_scale))

# This resets movement points to original value (e.g. when turn ends)
func reset_movement_points():
	self.movement_points = self.max_movement_points
	self._update_movementpoints_indicator()

# Public getter for the experience value. Returns a dictionary with all information
# about the current level of experience, like display_name of rank, multiplier (maybe
# icon in the future?)
# @returns {Dictionary} see description above
func get_experience():
	for exp_level in self.experience_definitions:
		if self.experience >= self.experience_definitions[exp_level]['range'][0] \
		or self.experience < self.experience_definitions[exp_level]['range'][1]:
			return self.experience_definitions[exp_level]

# Public getter for the simple raw experience value. It just returns a float.
# @returns {Float}
func get_experience_points():
	return self.experience

# Public getter for owning players ID
# @returns {Int} ID of owning player
func get_owner_id():
	return self.unit_owner

# This function returns a boolean indicating if the currently active player
# is the owner of this entity.
# @returns {Boolean}
func owned_by_active_player():
	#print("ID of clicked entity:")
	#print('Active player: '+str(game.active_player.get_id()))
	#print('Entity owner: '+str(self.unit_owner))
	return game.active_player.get_id() == self.unit_owner

# Returns the stance of the player this entity belongs to towards the current player.
# @returns {String} The stance of the owner of this entity to the current player.
# Can be one of: 'enemy', 'ally', 'neutral'
func get_unit_stance():
	var owner_player = game.playerMgr.get_player_by_id(self.unit_owner).node
	var stance = owner_player.get_stance_to(game.active_player)
	return stance

# Public getter for determining the state and capabilites of the entity
# @returns {Boolean}
func can_resupply():
	if self.is_supplier and (supply_storage_fuel > 0 or supply_storage_ammo > 0 \
	or supply_storage_support > 0 or supply_storage_construction > 0):
		return true
	return false

# Resupplies a entity at a given grid position if it is one of the players
# units or allied to the player.
# All supplies that are used by the target entity and that can be resupplied
# by this entity, will be resupplied.
# @input {Vector2} Grid pos to check for entity
func resupply(grid_pos):
	# Check if entity exists at position
	var is_unit = game._is_unit(grid_pos, true)
	if is_unit != null:
		var supplied_entity = is_unit.node
		# Check if entity is eligible for supplying
		if supplied_entity.owned_by_active_player() or supplied_entity.get_unit_stance() == 'ally':
			print('Valid target for resupply. Resupplying now!')
			# Perform the supply action. It is not defined if supplying action takes action points, 
			# but it definitely removes supplies from the supplying unit.

# This function should update the appearance of the entity, calculate stat
# changes etc. after each round. There is no need to do this in _process
# since its all turnbased anyway.
func update():
	self._set_sprite(direction)
	self._set_faction_icon()
	self._apply_mods()
	self._update_unitstrength_indicator()
	self._update_movementpoints_indicator()
	self._update_unitammo_indicator()
	if self.get_movement_points() <= 0:
		gui.disable_movement_button(true)
		gui.disable_attack_button(true)
	if self.get_ammo() <= 0:
		gui.disable_attack_button(true)

# Public getter for movement points of this entity.
# @returns {int} Movement points of this entity
func get_movement_points():
	return self.movement_points

# Public getter for entity strength.
# @returns {float} Strength points of this entity
func get_strength_points():
	return self.unit_strength

# Internal, updates movement points based on next tile movement.
func _update_movement_points(target_tile):
	self.movement_points -= target_tile.move_cost
	self._update_movementpoints_indicator()

# Internal, updates the indicator at the entity to show the movement points.
func _update_movementpoints_indicator():
	# $Panel/MovementPointsIndicator.set_bbcode(str(self.get_movement_points()))
	pass

# Internal, updates the visual unit_strength indicator, e.g. after getting attacked.
func _update_unitstrength_indicator():
	# $Panel/UnitStrengthIndicator.set_bbcode(str(self.get_strength_points()))
	pass

# Internal, updates the visual ammo counter at the entity, e.g. after attacking.
func _update_unitammo_indicator():
	# $Panel/UnitAmmoIndicator.set_bbcode(str(self.get_ammo()))
	pass

# Public getter for ammo left in this entity.
# @outputs {int} Ammo of this entity
func get_ammo():
	return self.ammo

# Public getter that checks if this entity is able to move.
# If it is a non-motorized entity or has fuel AND if entity has movement points, return true.
# @returns {Boolean} if fuel or movement points are depleted, return false, otherwise true.
func can_move():
	if (self.fuel == -1 or self.fuel > 0) and self.movement_points > 0:
		return true
	elif self.fuel == 0 or self.movement_points == 0:
		return false

# Public method to kill this entity. It removes this node from the games entities list,
# so after this it will not be considered by the game.
func kill():
	# - play death animation
	# - on animation finished, remove entity
	# for now, just remove node to show attack worked
	game.remove_entity_from_list(self)
	call_deferred('free')

# Public method to damage this entity and update its strength indicators.
func damage(new_strength):
	self.unit_strength = new_strength
	self._update_unitstrength_indicator()

# This method returns a Boolean indicating if it can attack a given entity,
# or if no target is given, general combat readiness.
# It takes into consideration both the state of this entity as well as the
# type and position of the given enemy entity.
# If nothing definitive can be determined, return false per default.
# @input {Object} -optional- The enemy entity, if not given, return basic
# combat readiness.
# @returns {Boolean} 
# @TODO Test if chosen weapon exists, has ammo / needs ammo, is in range
func can_attack_unit(enemy_unit):
	if enemy_unit == null:
		return self.combat_ready()
	if not self.combat_ready():
		return false
	return _get_weapon_in_range(enemy_unit.get_global_position()) != null

# Public getter for general combat readiness. This definition will likely
# change later, as this can be different for different types of units as
# well as may change due to design changes. Does attacking requires fuel
# and movement points to attack? At the moment, I say "yes".
# @returns {Boolean}
func combat_ready():
	var has_weapon = !self.weapons.is_empty()
	var has_ammo = self.get_ammo() > 0
	if has_weapon and has_ammo and self.get_movement_points() >= 1:
		return true
	return false

# Determines if the target (a grid position) is a valid attack target
# for this entity.
func is_valid_attack_target(grid_pos):
	# Check if entity exists at position
	var found_unit = game._is_unit(grid_pos, true)
	if found_unit != null:
		# Check if entity is hostile
		var target_entity = found_unit.node
		if target_entity.get_unit_stance() == 'enemy' && self.can_attack_unit(target_entity) == true:
			# Check if valid attack target for currently selected units weapons
			return true

# Simple public getter to return the first weapon found, if no weapon exists,
# return null.
# @returns {Dictionary, Null}
func get_main_weapon():
	if self.weapons.size() > 0:
		for weapon in self.weapons:
			return self.weapons[weapon]
	return null

# Public getter to get specific weapon by id
# @input {String} id of the weapon to retreive
# @returns {Dictionary} of all weapon attributes
func get_weapon(weapon_id):
	if weapon_id in weapons:
		return self.weapons[weapon_id]

# Public function to control the direction the entity grapic
# is rotated. This is only cosmetic at the moment, but may
# be extended to allow for "attack from behind" bonus etc.
func turn_towards(_grid_pos):
	# get direction of target grid_pos relative to this entity
	if self.unit_sprites.size() == 2:
		# determine how we should rotate, just towards x axis if only two sprites exist?
		pass
	elif self.unit_sprites.size() == 6:
		# ...or fully featured rotation if all six directional sprites exist
		pass

# Attack a entity/entity
func attack(target_entity, weapon=null):
	if weapon == null:
		weapon = _get_weapon_in_range(target_entity.get_global_position())
		if weapon == null:
			print("Cannot comply, no weapon in range for this target.")
			return false
	else:
		if not _is_weapon_in_range(weapon, target_entity.get_global_position()):
			print("Cannot comply, target out of range for selected weapon.")
			return false
	# Play sound
	self._play_sound('attack', weapon)
	
	# Set some environmental parameters
	var defending_unit = target_entity
	var defender_effective_strength
	print('Defending entity is ',defending_unit['display_name'],' (',defending_unit.get_experience()['display_name'],')')
	var attacking_unit = self
	var attacker_effective_attack
	var attacking_unit_weapon = weapon
	print('Attacking entity is ',attacking_unit['display_name'],' (',attacking_unit.get_experience()['display_name'],')')
	
	# find out basic attributes
	defender_effective_strength = defending_unit['unit_strength'] + (defending_unit['unit_strength'] * (defending_unit['base_defense']/10))
	print('Defending entity has strength of ',defending_unit['unit_strength'],', effective strength of ',defender_effective_strength,' (',defending_unit['unit_strength'],'+',defending_unit['unit_strength'] * (defending_unit['base_defense']/10),')')
	attacker_effective_attack = attacking_unit_weapon['attack_strength'] + attacking_unit_weapon['attack_strength'] * (attacking_unit['unit_strength']/10)
	print('Attacking entity has effective attack of ',attacker_effective_attack,' (',attacking_unit_weapon['attack_strength'],'+',attacking_unit_weapon['attack_strength'] * (attacking_unit['unit_strength']/10),')')
	
	# adding attack_bonus
	if attacking_unit['attack_bonus'] != 0:
		attacker_effective_attack += attacking_unit['attack_bonus']
		print('Attacker has attack modifier of ',attacking_unit['attack_bonus'],' resulting in effective attack value change to: ',attacker_effective_attack)

	## Armor piercing weapon & armor effects
	if defending_unit['armor'] > 0:
		print('Defender has armor value of ',defending_unit['armor'])
		if attacking_unit_weapon['armor_piercing'] <= 0:
			attacker_effective_attack = attacker_effective_attack * 0.1
			print('Thus, the attacker is ineffective, will only deal ',attacker_effective_attack,' damage.')
		elif attacking_unit_weapon['armor_piercing'] >= 0:
			var at_factor = defending_unit['armor'] / attacking_unit_weapon['armor_piercing']
			attacker_effective_attack = attacker_effective_attack + at_factor
			print('But attackers weapons are armor piercing, dealing additional damage of ',at_factor,' totalling ',attacker_effective_attack,' attack value.')

	## Area of effect weapon
	if defending_unit['armor'] <= 0 and attacking_unit_weapon['explosive'] > 0:
		attacker_effective_attack = attacker_effective_attack * (attacking_unit_weapon['explosive'] * 0.5)
		var he_factor = ((attacker_effective_attack * (attacking_unit_weapon['explosive'])) - attacker_effective_attack) / 0.75
		attacker_effective_attack -= defending_unit['base_defense']
		print('Defender is soft target and attacker has HE weapons, attack will deal additional damage of ',he_factor,' totalling ',attacker_effective_attack,' attack value.')

	# #### Finally, battling it out
	prints('Attacker attempts attack with',attacker_effective_attack,'effective attack, while defender has',defender_effective_strength,'effective strength.')

	#### Good or bad luck
	# value_proximity = attacking_unit['effective_attack'] - defending_unit['effective_strength']
	# max_luck = random.randint(1,3)
	# luck = round(abs(1/(value_proximity*((max_luck-0.9)/(max_luck*1.8))+1/max_luck)), 2)
	# print('Luck:',luck)

	# # The events show from the perspective of the defender, so "good" means "good for the defender"
	# random_events = {
	# 	'pro_def': [
	# 		"A sudden gust of stormy wind alters the course of a projectile, altering it's angle ever so slightly, leading to a dramatically reduced impact on the target and next to no damage.",
	# 		'The projectile was a dud. It impacts without any effect, besides a few startled combatants.',
	# 		'A critter flowing into ones eyes is always unpleasant, much more if one is trying to fire at the same time. The shots go way too high, even leaving the battlefield.',
	# 		'A unexpectedly soft spot on the ground leads to a sudden drop of the defending entity, which in turn leads to a missed hit on part of the attacker.'
	# 		'At the end of the day, all combatants are humans, with a conscience. A few moments of hesitation, a missed shot.',
	# 	],
	# 	'pro_att': [
	# 		'Trick shot! While not planned, the shot manages to penetrate perfectly, hitting vital parts of the defending entity.',
	# 		'Having suffered heavy losses, the defending units cohesion is lost and the remaining wounded combatants give up or flee.',
	# 		'A sudden gust of stormy wind alters the course of a projectile, altering its angle ever so slightly, leading to a dramatically increased effect on the target.',
	# 		'The long extra hours of training have paid off! Every free hour that comrades spent sleeping, gambling or drinking, this lone combatant has used for training. Now the result is a perfect kill shot.'
	# 	]
	# }

	# Determine if hit or miss, based on experience of entity
	var rand = randf()
	var hit = false
	if rand >= (0.45 - get_experience()['multiplier']):
		print("Attacker scores a hit.")
		hit = true
	else:
		print("Attacker misses and the attack nds.")

	# Update base stats, ragardless of hit or miss
	if attacking_unit_weapon['use_ammo']:
		attacking_unit.ammo -= 1
	attacking_unit.movement_points -= 1
	attacking_unit.update()

	if hit:
		state_save = {
			'defending_unit': defending_unit,
			'defender_effective_strength': defender_effective_strength,
			'attacking_unit_weapon': attacking_unit_weapon,
			'attacker_effective_attack': attacker_effective_attack,
			'attacking_unit': attacking_unit
		}
		self.attack_delay_timer.start()
		# Hit
		# All this stuff about luck and random events and chance feels still way too uncontrollable. Not in a good way.
		# I am leaving this commented out until I can work on it.
		# if luck > 1.28:
		# 	if random.random() > 0.5:
		# 		attack_bonus = round(attacking_unit['effective_attack'] * luck,2)
		# 		print(random_events['pro_att'][random.randint(0, len(random_events['pro_att'])-1)],'// Attack increased by',attack_bonus,'adding up to effective attack of',attacking_unit['effective_attack'] + attack_bonus)
		# 		attacking_unit['effective_attack'] += attack_bonus
		# 	else:
		# 		print(random_events['pro_def'][random.randint(0, len(random_events['pro_def'])-1)], '// Attack decreased by',round((attacking_unit['effective_attack'] * luck) / attacking_unit['effective_attack'],2))
		# 		attacking_unit['effective_attack'] -= round((attacking_unit['effective_attack'] * luck) / attacking_unit['effective_attack'],2)

# Finish attack, because how Godot works (or rather, how I don't work)
func _process_attack_finish():
	var defending_unit = state_save['defending_unit']
	var defender_effective_strength = state_save['defender_effective_strength']
	var attacking_unit_weapon = state_save['attacking_unit_weapon']
	var attacker_effective_attack = state_save['attacker_effective_attack']
	var _attacking_unit = state_save['attacking_unit']

	if sfxMgr != null:
		sfxMgr.create_effect(defending_unit.get_global_position(), attacking_unit_weapon.effect_impact, 'weapons', true)
	defending_unit._play_sound('hit', attacking_unit_weapon)

	# If attacker has attack value greater zero...
	if attacker_effective_attack > 0:
		prints('Defending entity strength is calculated by',defender_effective_strength,'-',attacker_effective_attack,'rounded, which is ',"%.1f" % (defender_effective_strength - attacker_effective_attack))
		# Calculate how much strength is left after attack
		var new_defender_strength = float("%.1f" % ((defender_effective_strength - attacker_effective_attack)))
		# Has attack managed to overcome effective defense boost?
		if new_defender_strength < defender_effective_strength:
			if float(new_defender_strength) <= 0:
				prints('Defending unit is destroyed!')
				defending_unit.kill()
			else:
				defending_unit.damage(new_defender_strength)
		else:
			prints('Attack did not manage to get trough to defenders base strength.')

# Function to fill the attributes of the entity from the themes data object
# corresponding to it. If a value was filled by the level editor with a non-
# default value, it will not be overwritten.
# @input {Dictionary} a dict containing all the attribute values for this entity
func fill_attributes(data_object):
	_debug_log("fill_attributes(): start for unit_id='" + str(unit_id) + "', faction='" + str(unit_faction) + "'")
	for entry in data_object:
		if entry in self:
			set(entry, data_object[entry])
	_debug_log("fill_attributes(): after fill -> display_name='" + str(display_name) + "', unit_faction='" + str(unit_faction) + "', unit_strength=" + str(unit_strength) + ", base_defense=" + str(base_defense) + ", armor=" + str(armor))
	self._update_movementpoints_indicator()
	self.max_movement_points = self.movement_points
	self._populate_weapons()
	self._fill_mods()
	self.experience_definitions = themeMgr.get_faction_experience_definitions(self.unit_faction)
	self._update_unitammo_indicator()
	_debug_log("fill_attributes(): done.")

# Fill modifiers from theme
func _fill_mods():
	for index in range(0, self.modifiers.size()):
		var modifier_id = modifiers[index]
		self.active_modifiers[modifier_id] = themeMgr.get_modifier(modifier_id)
		self.active_modifiers[modifier_id]['applied'] = false

# Apply modifier changes to entity stats, also deletes mods if their max duration is reached.
func _apply_mods():
	var delete_mods = []
	for mod in self.active_modifiers:
		var active_mod = active_modifiers[mod]
		if (active_mod['duration'] > 0 or active_mod['duration'] == -1) and not active_mod['applied']:
			for attribute in active_mod['modifiers']:
				self[attribute] += active_mod['modifiers'][attribute]
			active_mod['applied'] = true
		else:
			delete_mods.append(mod)
	# Do some housekeeping, mods whose duration has expired should be cleaned from entity
	if delete_mods.size() > 0:
		for index in range(0,delete_mods.size()):
			self.active_modifiers.erase(delete_mods[index])

# Public function to count down all active mods with duration. This is to be called
# every time a turn ends.
func update_timed_modifiers():
	for mod in self.active_modifiers:
		var active_mod = active_modifiers[mod]
		if active_mod['duration'] > 0:
			active_mod['duration'] -= 1

# Animates this units movement on a given path from one tile to another over
# n tiles in between
# @input path_array {Array} the array containing every tile in order of the path
# @input entity {Object} this is the entity which represents this entity in the game.
# It must be passed so it can be used in a callback later.
func animate_path(path_array, moving_entity):
	self.entity_representation = moving_entity
	animation_path_array = path_array.duplicate()
	if animation_path_array.is_empty():
		return
	var current_grid = hexmap.global_to_map(self.global_position)
	if animation_path_array[0].grid_pos == current_grid:
		animation_path_array.remove_at(0)
	if animation_path_array.is_empty():
		return
	_animate_step(animation_path_array[0], 0, animation_path_array.size())

##### Internal methods

# Animate each step of the path, this is called recursively until the whole path is animated. It also updates the movement points of the entity after each step.
# @input current_tile {Object} the tile which is the target of the current step
# @input step {int} the current step in the path, starting with 0 for the first step
# @input max_steps {int} the total number of steps in the path
func _animate_step(current_tile, step, _max_steps):
	var easing = Tween.EASE_IN_OUT
	var timing = Tween.TRANS_LINEAR
	self._update_movement_points(current_tile)
	animation_step_active = true
	animation_step = step
	self.direction = self._get_direction(rad_to_deg(self.get_angle_to(_get_centered_grid_pos(current_tile['grid_pos'], self.offset))))
	var move_tween = create_tween()
	move_tween.set_trans(timing)
	move_tween.set_ease(easing)
	var step_duration = clampf(0.6 * float(current_tile.move_cost), 0.2, 2.0)
	move_tween.tween_property(self, "global_position", _get_centered_grid_pos(current_tile['grid_pos'], self.offset), step_duration)
	move_tween.finished.connect(_on_move_tween_finished, CONNECT_ONE_SHOT)
	
# From the last movements angle, get the direction mapped, so it references
# to a direction sprite from the theme.
func _get_direction(angle):
	var dir = 0
	if angle > 145 and angle < 155:
		dir = 0
		# print("Moving southwest")
	elif angle > -155 and angle < -145:
		dir = 1
		# print("Moving northwest")
	elif angle > -95 and angle < -85:
		dir = 2
		# print("Moving north")
	elif angle > -35 and angle < -25:
		dir = 3
		# print("Moving northeast")
	elif angle > 25 and angle < 35:
		dir = 4
		# print("Moving southeast")
	elif angle > 85 and angle < 95:
		dir = 5
		# print("Moving south")
	return dir

# internal function to play sounds
# @input {String} The reason for sound emitting, one of a given list of keywords: 
# - move
# - attack
# - hit
# - death
# - resupply
# - ...
# Note that "hit" sound does include the effect on the entity of a successful hit, but not the
# sound of the weapon hit itself. So e.g. the sound of a soft body being hit by a sword/arrow
# will emit from the entity but the sound of the sword swing/arrow flying will be emitted
# by the effect/sfx node which is dynamically spawned upon attack. This way, a missed attack
# won't play a "hit" sound and overall less unique sounds are necessary.
# These keywords reference either a sound given in the entity definition in the theme, or
# a fallback default sound is used, that either the theme supplies or the base game.
# @input {String} info, optional additional info
func _play_sound(keyword, info=null):
	self.sound_emitter.volume_db = settingsMgr.get_sfx_volume()
	var stream = themeMgr.get_sound(self.unit_id, keyword, info)
	if stream == null:
		return
	self.sound_emitter.stream = stream
	self.sound_emitter.play()

func _get_weapons_dict() -> Dictionary:
	if weapons == null:
		return {}
	if typeof(weapons) != TYPE_DICTIONARY:
		_populate_weapons()
	if typeof(weapons) == TYPE_DICTIONARY:
		return weapons
	return {}

func _get_distance_to_target(target_global_pos: Vector2) -> int:
	if game == null or hexmap == null:
		return -1
	var self_grid = hexmap.global_to_map(self.global_position)
	var target_grid = hexmap.global_to_map(target_global_pos)
	return game.get_hex_distance(Vector2i(self_grid), Vector2i(target_grid))

func _get_weapon_range(weapon) -> int:
	if weapon == null:
		return 0
	if weapon.has("range"):
		return int(weapon["range"])
	return 1

func _is_weapon_in_range(weapon, target_global_pos: Vector2) -> bool:
	var distance = _get_distance_to_target(target_global_pos)
	if distance < 0:
		return false
	return distance <= _get_weapon_range(weapon)

func _get_weapon_in_range(target_global_pos: Vector2):
	var weapons_dict = _get_weapons_dict()
	if weapons_dict.is_empty():
		return null
	for weapon_id in weapons_dict:
		var weapon = weapons_dict[weapon_id]
		if weapon == null:
			continue
		if _is_weapon_in_range(weapon, target_global_pos):
			return weapon
	return null

func _is_in_range(target_global_pos: Vector2) -> bool:
	return _get_weapon_in_range(target_global_pos) != null

# Internal function to populate weapon list with actual theme objects
func _populate_weapons():
	var weapon_ids = self.weapons
	self.weapons = {}
	for weapon_id in weapon_ids:
		self.weapons[weapon_id] = themeMgr.get_weapon(weapon_id)

func _ready():
	## Init ingame
	type = 'entity'
	# Set necessary offset for correct position relative to grid
	offset = Vector2(-6, 0)
	set_process_input(true)
	# Mark entity as selectable
	self.set_selectable(true)
	_debug_log("_ready(): node='" + name + "', unit_id='" + str(unit_id) + "', unit_faction='" + str(unit_faction) + "'")

func _input(_event):
	pass

func _process(_delta):
	pass

func _on_move_tween_finished():
	animation_step_active = false
	if animation_path_array.size()-1 > animation_step:
		# Animate next step
		animation_step += 1
		_animate_step(animation_path_array[animation_step], animation_step, animation_path_array.size())
		self.update()
	else:
		# Done animating, update entity locally
		self.update()
		# $"/root/Game"._delete_all_nodes_with('path_vis')
		# ...then call global update
		# Global update is for udpating global look-up tables with grid positions
		root.update_entity_list_entry(entity_representation)

func _on_MoveTween_tween_completed(_object, _key):
	_on_move_tween_finished()

func _on_AttackEffectDelay_timeout():
	attack_delay_timer.stop()
	self._process_attack_finish()

func _on_selected():
	self.show_quick_panel()
	
func _on_deselected():
	self.hide_quick_panel()

func _debug_log(message):
	if debug_logging:
		print("[Debug][Unit:" + name + "|" + str(unit_id) + "] " + message)
