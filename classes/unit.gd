extends Entity

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
@export var direction: int = 0

# if a entity has e.g. various camo schemes (desert, woodland) or randomized appearance.
# the detailed documentation for these go into the faction object
# @TODO Ugly hack! This must be gotten from the ThemeMgr and the actual unit
@export_enum("Default:0", "Variant 1:1", "Variant 2:2", "Random:-1") var graphical_scheme: int = 0

# entity id, from which all additional data like sprite, entity attributes, name etc
# are loaded from units.data
@export var unit_id: String = ''

# For debugging sprite loading in detail
@export var debug_logging = false
@export var combat_debug = false

#################################################################################
# 
# Unit Attributes
# 
# Due to the nature of the current approach, the entity class currently needs to
# know of the existence of each and every attribute that exists. They are 
# exported here, so that a entity may be edited to be special, via the editor.
#
# More questions and implementation thoughts:
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
@export var display_name: String = ''

# Description of the entity, possibly shown in a ingame encyclopedia or on the
# extended info-screen for this entity.
@export var description: String = ''

# If this entity has the ability to hold supplies and also resupply allied units nearby.
@export var is_supplier: bool = false

# The amount of supplies this entity can hold, if it is a supplier.
@export var max_supply_storage: int = 0

# How much fuel supplies can this entity hold? This amount, added with all other supply types,
# can never exceed "this.max_supply_storage".
@export var supply_storage_fuel: int = 0

# How much ammo supplies can this entity hold? This amount, added with all other supply types,
# can never exceed "this.max_supply_storage".
@export var supply_storage_ammo: int = 0

# How much support supplies can this entity hold? This amount, added with all other supply types,
# can never exceed "this.max_supply_storage".
# 'Support' can refer to both medical equipment and food, so depending on the situation, the entity
# type and the scenario, this may be used with some flexibility.
@export var supply_storage_support: int = 0

# How much construction supplies can this entity hold? This amount, added with all other supply types,
# can never exceed "this.max_supply_storage".
@export var supply_storage_construction: int = 0

# The Unit's strength defines, depending on the nature of the entity, its technical
# or medical status.
# For example, a standard squad consists of 8 men. This translates
# directly to entity strength of "8". A successful hit against this entity may remove
# 1-2 points, making 1-2 men unable to fight (killing or wounding is treated equally
# here).
# For another example, a light vehicle group may consist of 3 vehicles, being able
# to function with some damage sustained, it could translate into 4 strength points.
# If the entity's strength drops to 0, the entity is considered lost, either destroyed or
# combat-ineffective. It is not shown any more on the game map.
# The attack value of this entity is also factored by the entity's strength. The lesser
# of a entity remains, the less damage it is able to inflict.
@export var unit_strength: int = 0

# Base defense value, this is used as a base to calculate how well this entity can
# defend from an attack. Based on the kind of attack, additional values are added
# These can also depend on the tile the entity is on, as well as type of the entity.
@export var base_defense: int = 0

# Is this entity armored? How much? Generally, armor piercing weapons have a greater effect on 
# armored targets, while explosive weapons have a bigger effect against soft targets.
# In alternative themed game-settings, this can act as a simple defense bonus, meaning
# that armored troops generally have more chance to not sustain a lot of damage when
# hit by certain weapons, while non-armored units do (e.g. classical roman era, where arrows
# against velites would do more damage than against heavily armored triarii).
@export var armor: int = 0

# What medium this entity can move in/on primarily.
# Expects an array with one string per traversable terrain type:
# "land", "river", "water", "mountain"
@export var can_traverse: Array = []

# Movement points
# These are consumed when moving from one tile to another tile. The amount of points
# used for this is based on the terrain type of the tile that is entered (not the one
# the entity is coming from).
@export var movement_points: int = 0

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
@export var fuel: int = 0

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
@export var weapons: Array = []

# Ammunition for its own weapons
# Basically, how many times can this entity attack until ammo runs out, not really how
# many shots it carries.
# An "attack" is the abstraction of the concept of an "attack run" or "fire mission".
# Think a fire mission for an artillery brigade, or support fire given by a vehicle
# group, where dozens/hundreds/thousands of shots may be fired.
# @TODO At the moment this is only a int, in future it needs to be converted to array or
# similar, to represent ammunition for each type of weapon, but also to allow for shared
# ammo for similar weapons (same caliber e.g.)
@export var ammo: int = 0

# Attack bonus
# This can be thought of as a "base_attack" bonus value to the entity. It could be used
# to signify better training of this entity or technical characteristics that would give
# it a significant attack boost compared to another entity with the same weapons. 
# It is simply added to the "weapons"[0]s "attack_strength" value.
# Most often this will be set via modifiers.
# Usage example: Standard infantry with assault rifles vs. elite commando units,
# using the same assault rifles but having much more skill, experience and training,
# thus doing more damage with the same weapon.
@export var attack_bonus: int = 0

# Experience
# A float value between 0 and 1.
# This is mostly a mechanic to gratify players for keeping their units alive for a long time.
# The gameplay effect is minor, experience level is mapped to one of n ranges. Each range 
# gives a multiplier. The multiplier negates (according to its value, higher == more) the
# inherent randomness in a lot of actions, e.g. getting hit, chance of hitting another entity,
# the order of single combat actions etc.
# It tries to portrait the increased routine and its effect in cancelling out the random influence
# in actions during combat.
@export var experience : float = 0

# Unit sprites
# This array is for the representation of the entity in the game. It is responsible
# for the rendering of a entity on the game map itself.
# This accomododates everything between 1 static graphic (no direction specific graphics,
# in which case the game automatically creates a mirrored version to have at least two
# directional graphics) up to 6 images for each possible direction.
@export var unit_sprites = []
# Optional list of destroyed/debris sprites for this unit.
@export var destroyed_sprites = []
# Optional scale override for destroyed sprites.
@export var destroyed_sprite_scale = null
# Optional anchor definitions for spawning effects. Each anchor can define
# either a fixed offset or six direction-specific offsets.
@export var effect_anchors = {}
# Optional effect id used while this unit moves. If empty, the game falls back
# to a shared default movement effect.
@export var move_effect = ""
@export var move_effect_anchor = "center"
# Temporary combat modifiers (reset each turn)
@export var temp_attack_bonus = 0
@export var temp_defense_bonus = 0

# Modifiers
# This array contains the IDs of all modifiers that should be applied to the entity.
# When the game starts, the corresponding modifier objects are pulled from the theme
# and their effects applied to the units base stats.
# If a modifier is added to a unit, it is first marked as "applied" = false, so we can later
# (might be just a few cylces later, but "later" in terms of program logic) apply them to the
# units stats.
# Since modifiers can be applied from the scenario creator, but also dynamically during the game
# (e.g. a suppression), we track active modifiers in a different variable, "active_modifiers:Dictionary".
# A icon is shown at the entity in-game which, on hover, reveals the name and effects of
# the modifiers. Details can be found in the units detail screen (description, icon, stat changes
# of each modifier).
@export var modifiers = []
var active_modifiers = {}

# Private class members
var animation_step_active = false
var animation_step = 0
var animation_path_array = []
var offset = null
var entity_representation = null
var last_movement_angle = null
var max_movement_points = 0
var experience_definitions = null
var state_save = {}
enum UnitState {
	IDLE,
	SELECTED,
	MOVING,
	ATTACKING,
	GARRISONING,
	UNGARRISONING,
	GARRISONED,
	DYING,
	DEAD,
	BEING_SUPPLIED,
	SUPPLYING,
	SPENT
}
var state: int = UnitState.IDLE
var is_destroyed = false
var last_grid_pos = null
var stationary_turns = 0
var last_attacked_turn = null
var attack_streak = 0
var suppression_turns = 0
var _is_hovered_flag = false
const DAMAGE_VARIANCE = 0.2
const GRAZE_CHANCE = 0.2
const GRAZE_MULTIPLIER = 0.3
const DEFAULT_MOVEMENT_EFFECT_ID = "default_move_dust"
const DEFAULT_MOVEMENT_EFFECT_SCENE = "res://effects/core/move_dust_small.tscn"
@export_group("Internal Node References")
@export var unit_quick_panel: Control
@export var qp_state_text: RichTextLabel
@export var qp_strength_text: RichTextLabel
@export var qp_movement_text: RichTextLabel
@export var qp_ammo_text: RichTextLabel
@onready var modifiers_container: HBoxContainer = $ModifiersContainer

@onready var sound_emitter = $'SoundEmitter'
@onready var move_particles = $MoveParticles
@onready var attack_delay_timer = $'AttackEffectDelay'
@export var settingsMgr = null
@export var themeMgr = null
@export var gui = null
@export var sfxMgr = null

func _ready():
	super._ready()
	## Init ingame
	type = 'entity'
	# Set necessary offset for correct position relative to grid
	offset = Vector2(-6, 0) # @TODO Magic number!
	set_process_input(true)
	# Mark entity as selectable
	self.set_selectable(true)
	set_state(UnitState.IDLE)
	_debug_log("_ready(): node='" + name + "', unit_id='" + str(unit_id) + "', unit_faction='" + str(unit_faction) + "'")
	combat_debug = settingsMgr.get_combat_debug()
	# Call the base class ready function
	super._ready()

func _input(_event):
	pass

func _process(_delta):
	if unit_quick_panel != null and unit_quick_panel.visible:
		_update_quick_panel_transform()
	if _is_hovered():
		print("Unit '%s' is hovered." % display_name)
		show_quick_panel()
		_update_modifier_icons()
	else:
		if not is_selected():
			hide_quick_panel()

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
	if not can_receive_orders():
		return false
	var new_path = game.find_path(start_point, end_point, self)
	if new_path.is_empty():
		print_debug("No valid path found from " + str(start_point) + " to " + str(end_point))
		return false
	var start_grid = hexmap.global_to_map(start_point)
	while not new_path.is_empty() and new_path[0]["grid_pos"] == start_grid:
		new_path.remove_at(0)
	if new_path.is_empty():
		return false
	var path_cost = 0
	for tile in new_path:
		if path_cost + tile.move_cost > self.movement_points:
			print_debug("This movement would be too expensive: "+str(path_cost + tile.move_cost))
			return false
		path_cost += tile.move_cost
	self.set_move_path(new_path)
	# This is a debug method to visualize the path found by the pathfinding
	# game._show_path(new_path)
	self._play_sound('move')
	set_state(UnitState.MOVING)
	self.animate_path(new_path, moving_entity)
	self.deselect()

func _update_quick_panel() -> void:
	if qp_state_text != null:
		qp_state_text.text = _get_state_emoji(state)
	qp_strength_text.text = str(self.get_strength_points())
	qp_movement_text.text = str(self.get_movement_points())
	qp_ammo_text.text = str(self.get_ammo())

func _update_modifier_icons() -> void:
	if modifiers_container == null:
		return
	
	for child in modifiers_container.get_children():
		modifiers_container.remove_child(child)
	
	for mod_id in active_modifiers:
		var mod_data = active_modifiers[mod_id]
		if mod_data == null or not mod_data.has("icon"):
			continue
		
		var icon_path = mod_data["icon"]
		var resolved_path = _resolve_theme_sprite_path(icon_path + ".png")
		
		var texture_rect = TextureRect.new()
		texture_rect.custom_minimum_size = Vector2(24, 24)
		texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		
		var texture = load(resolved_path) as Texture2D
		if texture != null:
			texture_rect.texture = texture
			modifiers_container.add_child(texture_rect)

func _is_hovered() -> bool:
	return _is_hovered_flag

func show_quick_panel() -> void:
	var should_show = is_selected() or modifiers_container.visible or _is_hovered()
	unit_quick_panel.visible = should_show
	modifiers_container.visible = should_show and not active_modifiers.is_empty()
	_update_quick_panel_transform()
	_update_quick_panel()

func hide_quick_panel() -> void:
	unit_quick_panel.hide()
	modifiers_container.hide()

# @input {int} current_state - state enum value from UnitState
# @returns {String} emoji representing the state
func _get_state_emoji(current_state: int) -> String:
	match current_state:
		UnitState.IDLE:
			return "😴"
		UnitState.SELECTED:
			return "🎯"
		UnitState.MOVING:
			return "🚶"
		UnitState.ATTACKING:
			return "⚔️"
		UnitState.GARRISONING:
			return "🏠"
		UnitState.UNGARRISONING:
			return "🚪"
		UnitState.GARRISONED:
			return "🛡️"
		UnitState.DYING:
			return "💥"
		UnitState.DEAD:
			return "☠️"
		UnitState.BEING_SUPPLIED:
			return "📦"
		UnitState.SUPPLYING:
			return "⛽"
		UnitState.SPENT:
			return "🥵"
		_:
			return "❓"

# Set flag icon based on faction of entity
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

func _resolve_theme_sprite_path(sprite_path: String) -> String:
	if sprite_path.begins_with("res://"):
		return sprite_path
	if themeMgr != null and themeMgr.has_method("get_theme_base_path"):
		return themeMgr.get_theme_base_path() + "/" + sprite_path
	var theme_name = themeMgr.get_current_theme_name()
	return "res://themes/%s/%s" % [theme_name, sprite_path]

func _apply_destroyed_sprite(sprite_path: String) -> void:
	var resolved = _resolve_theme_sprite_path(sprite_path)
	var texture = load(resolved) as Texture2D
	if texture == null:
		return
	$UnitImage.texture = texture
	if destroyed_sprite_scale:
		$UnitImage.scale = Vector2(destroyed_sprite_scale, destroyed_sprite_scale)

func _play_death_animation() -> void:
	hide_quick_panel()
	var sprite_path = destroyed_sprites[randi() % destroyed_sprites.size()]
	var tween = create_tween()
	tween.tween_property($UnitImage, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		_apply_destroyed_sprite(sprite_path)
	)
	tween.tween_property($UnitImage, "modulate:a", 1.0, 0.2)

# This resets movement points to original value (e.g. when turn ends)
func reset_movement_points():
	self.movement_points = self.max_movement_points
	if self.movement_points > 0 and state == UnitState.SPENT:
		set_state(UnitState.IDLE)

# Public getter for the experience value. Returns a dictionary with all information
# about the current level of experience, like display_name of rank, multiplier (maybe
# icon in the future?)
# @returns {Dictionary} see description above
func get_experience():
	if experience_definitions == null:
		return null
	var definitions: Array = []
	if typeof(experience_definitions) == TYPE_ARRAY:
		for entry in experience_definitions:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			# Support list entries as direct definitions or keyed by rank id.
			if entry.has("range"):
				definitions.append(entry)
			else:
				for key in entry.keys():
					var exp_def = entry[key]
					if typeof(exp_def) == TYPE_DICTIONARY:
						definitions.append(exp_def)
	elif typeof(experience_definitions) == TYPE_DICTIONARY:
		for exp_level in experience_definitions:
			var exp_def = experience_definitions[exp_level]
			if typeof(exp_def) == TYPE_DICTIONARY:
				definitions.append(exp_def)
	for exp_def in definitions:
		if exp_def != null and exp_def.has("range"):
			var low = float(exp_def["range"][0])
			var high = float(exp_def["range"][1])
			if self.experience >= low and self.experience < high:
				return exp_def
	return null

func _get_experience_multiplier() -> float:
	var exp_def = get_experience()
	if exp_def == null:
		return 0.0
	return float(exp_def.get("multiplier", 0.0))

func _get_experience_display_name() -> String:
	var exp_def = get_experience()
	if exp_def == null:
		return "Unknown"
	return str(exp_def.get("display_name", "Unknown"))

# Public getter for the simple raw experience value. It just returns a float.
# @returns {Float}
func get_experience_points():
	return self.experience

# Public getter for owning players ID
# @returns {String} ID of owning player
func get_owner_id() -> int:
	return self.unit_owner

# This function returns a boolean indicating if the currently active player
# is the owner of this entity.
# @returns {Boolean}
func owned_by_active_player():
	print_debug("ID of clicked entity:")
	print_debug('Active player: '+str(game.active_player.get_id()))
	print_debug('Entity owner: '+str(self.unit_owner))
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
	if not can_receive_orders():
		return false
	# Check if entity exists at position
	var is_unit = game._is_unit(grid_pos, true)
	if is_unit != null:
		var supplied_entity = is_unit.node
		# Check if entity is eligible for supplying
		if supplied_entity.owned_by_active_player() or supplied_entity.get_unit_stance() == 'ally':
			print_debug('Valid target for resupply. Resupplying now!')
			# Perform the supply action. It is not defined if supplying action takes action points,
			# but it definitely removes supplies from the supplying unit.
			# @TODO Add a check to prevent supplying more than the max supply storage of the target entity.

# This function should update the appearance of the entity, calculate stat
# changes etc. after each round. There is no need to do this in _process
# since its all turnbased anyway.
func update():
	self._set_sprite(direction)
	self._set_faction_icon()
	self._apply_mods()

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
	if is_destroyed:
		return
	if root != null and root.selected_unit == self.id:
		self.deselect()
		if root.has_method("_refresh_selected_unit_ui"):
			root._refresh_selected_unit_ui()
	set_state(UnitState.DYING)
	# If destroyed sprites are defined, keep a debris/remains version on the map.
	if destroyed_sprites != null and destroyed_sprites.size() > 0:
		is_destroyed = true
		self.set_selectable(false)
		self.set_container(true)
		self.type = "debris"
		game.remove_entity_from_list(self)
		_play_death_animation()
		set_state(UnitState.DEAD)
		return
	# Fallback: remove node
	set_state(UnitState.DEAD)
	game.remove_entity_from_list(self)
	call_deferred('free')

# Public method to damage this entity and update its strength indicators.
func damage(new_strength):
	self.unit_strength = new_strength
	self.add_experience(0.05) # @TODO Maybe restrict this to damage sustained in combat only?

# Public method to add experience to this entity. It takes a float value between 0 and 1, which is added to 
# the current experience value of the entity. If the resulting experience exceeds 1, it is capped at 1.
# If the threshold for the next experience level is reached, the entity's stats are increased according to the 
# definitions in the theme.
# @input {Float} exp_amount - A float value between 0 and 1 representing the amount of experience to add.
func add_experience(exp_amount):
	self.experience += exp_amount
	if self.experience > 1:
		self.experience = 1
	# @TODO Add level up mechanics here.

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
	return _get_weapon_in_range(enemy_unit.get_global_position(), enemy_unit) != null

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
	return false

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

# Returns all unique attack ranges across this units weapons.
# @returns {Array} sorted unique integer ranges
func get_attack_ranges() -> Array:
	var result: Array = []
	var weapons_array = _get_weapons_array()
	for weapon in weapons_array:
		if weapon == null:
			continue
		if weapon.has("range"):
			var weapon_range = int(weapon["range"])
			if weapon_range > 0 and not result.has(weapon_range):
				result.append(weapon_range)
	result.sort()
	return result

# Public function to control the direction the entity grapic
# is rotated. This is only cosmetic at the moment, but may
# be extended to allow for "attack from behind" bonus etc.
func turn_towards(_grid_pos):
	var target_global = Vector2.ZERO
	if typeof(_grid_pos) == TYPE_VECTOR2I:
		target_global = _get_centered_grid_pos(_grid_pos, self.offset)
	elif typeof(_grid_pos) == TYPE_VECTOR2:
		target_global = _grid_pos
	else:
		return
	var angle = rad_to_deg(self.get_angle_to(target_global))
	self.direction = self._get_direction(angle)
	self._set_sprite(self.direction)

func _start_move_particles() -> void:
	if move_particles == null:
		return
	var particles = move_particles.get_node_or_null("DustParticles")
	if particles != null:
		particles.restart()
		particles.emitting = true

func _stop_move_particles() -> void:
	if move_particles == null:
		return
	var particles = move_particles.get_node_or_null("DustParticles")
	if particles != null:
		particles.emitting = false

func _spawn_weapon_fire_effect(target_entity, weapon) -> void:
	if sfxMgr == null or weapon == null:
		return
	var effect_id = str(weapon.get("effect", ""))
	if effect_id.is_empty():
		return
	var target_position = target_entity.get_global_position()
	var anchor_id = str(weapon.get("effect_anchor", "center"))
	var effect_position = get_effect_anchor_global_position(anchor_id, target_position)
	var effect_rotation = _resolve_effect_rotation(str(weapon.get("effect_rotation_mode", "target")), effect_position, target_position)
	sfxMgr.create_effect(effect_position, effect_id, "weapons", false, {"rotation": effect_rotation})

func _spawn_weapon_impact_effect(target_entity, weapon) -> void:
	if sfxMgr == null or weapon == null or target_entity == null:
		return
	var effect_id = str(weapon.get("effect_impact", ""))
	if effect_id.is_empty():
		return
	var anchor_id = str(weapon.get("effect_impact_anchor", "center"))
	var effect_position = target_entity.get_global_position()
	if target_entity.has_method("get_effect_anchor_global_position"):
		effect_position = target_entity.get_effect_anchor_global_position(anchor_id, self.get_global_position())
	var effect_rotation = _resolve_effect_rotation(str(weapon.get("effect_impact_rotation_mode", "none")), effect_position, self.get_global_position())
	sfxMgr.create_effect(effect_position, effect_id, "weapons", false, {"rotation": effect_rotation})

func get_effect_anchor_global_position(anchor_id: String = "center", look_at_position: Vector2 = Vector2.ZERO) -> Vector2:
	if anchor_id.is_empty() or anchor_id == "center":
		return self.get_global_position()
	return self.get_global_position() + _get_effect_anchor_offset(anchor_id, look_at_position)

func _get_effect_anchor_offset(anchor_id: String, _look_at_position: Vector2 = Vector2.ZERO) -> Vector2:
	if typeof(effect_anchors) != TYPE_DICTIONARY or not effect_anchors.has(anchor_id):
		return Vector2.ZERO
	var anchor_definition = effect_anchors[anchor_id]
	if _is_directional_anchor_definition(anchor_definition):
		var directional_offsets = anchor_definition
		if typeof(anchor_definition) == TYPE_DICTIONARY:
			directional_offsets = anchor_definition.get("by_direction", [])
		var dir_index = clampi(self.direction, 0, directional_offsets.size() - 1)
		return _coerce_vector2(directional_offsets[dir_index])
	if typeof(anchor_definition) == TYPE_DICTIONARY:
		if anchor_definition.has("offset"):
			return _coerce_vector2(anchor_definition["offset"])
		if anchor_definition.has("default"):
			return _coerce_vector2(anchor_definition["default"])
	return _coerce_vector2(anchor_definition)

func _is_directional_anchor_definition(anchor_definition) -> bool:
	if typeof(anchor_definition) == TYPE_DICTIONARY:
		var directional_offsets = anchor_definition.get("by_direction", [])
		return typeof(directional_offsets) == TYPE_ARRAY and directional_offsets.size() >= 6
	return typeof(anchor_definition) == TYPE_ARRAY and anchor_definition.size() >= 6 and (typeof(anchor_definition[0]) == TYPE_ARRAY or typeof(anchor_definition[0]) == TYPE_VECTOR2 or typeof(anchor_definition[0]) == TYPE_VECTOR2I or typeof(anchor_definition[0]) == TYPE_DICTIONARY)

func _coerce_vector2(value) -> Vector2:
	if typeof(value) == TYPE_VECTOR2:
		return value
	if typeof(value) == TYPE_VECTOR2I:
		return Vector2(value)
	if typeof(value) == TYPE_ARRAY and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	if typeof(value) == TYPE_DICTIONARY and value.has("x") and value.has("y"):
		return Vector2(float(value["x"]), float(value["y"]))
	return Vector2.ZERO

func _resolve_effect_rotation(mode: String, effect_position: Vector2, reference_position: Vector2) -> float:
	match mode:
		"target", "from_source":
			if effect_position.is_equal_approx(reference_position):
				return 0.0
			return effect_position.angle_to_point(reference_position)
		"unit_direction":
			return _get_direction_rotation()
		_:
			return 0.0

func _get_direction_rotation() -> float:
	match self.direction:
		0:
			return deg_to_rad(150.0)
		1:
			return deg_to_rad(-150.0)
		2:
			return deg_to_rad(-90.0)
		3:
			return deg_to_rad(-30.0)
		4:
			return deg_to_rad(30.0)
		5:
			return deg_to_rad(90.0)
	return 0.0

# Attack a entity/entity
func attack(target_entity, weapon=null):
	if not can_receive_orders():
		return false
	if weapon == null:
		weapon = _get_weapon_in_range(target_entity.get_global_position(), target_entity)
		if weapon == null:
			print_combat_debug("Cannot comply, no weapon in range for this target.")
			return false
	else:
		if not _is_weapon_in_range(weapon, target_entity.get_global_position()):
			print_combat_debug("Cannot comply, target out of range for selected weapon.")
			return false
	set_state(UnitState.ATTACKING)
	turn_towards(target_entity.get_global_position())
	_spawn_weapon_fire_effect(target_entity, weapon)
	# Play sound
	self._play_sound('attack', weapon)
	
	# Set some environmental parameters
	var defending_unit = target_entity
	var defender_effective_strength
	print_combat_debug('Defending entity is ',defending_unit.display_name,' (',defending_unit._get_experience_display_name(),')')
	var attacking_unit = self
	var attacker_effective_attack
	var attacking_unit_weapon = weapon
	print_combat_debug('Attacking entity is ',attacking_unit.display_name,' (',attacking_unit._get_experience_display_name(),')')
	
	# find out basic attributes
	var defender_base_defense = defending_unit.base_defense + defending_unit.temp_defense_bonus
	var defense_factor = maxf(0.1, 1.0 + (defender_base_defense / 10.0))
	defender_effective_strength = defending_unit.unit_strength * defense_factor
	print_combat_debug('Defending entity has strength of ',defending_unit.unit_strength,', effective strength of ',defender_effective_strength,' (',defending_unit.unit_strength,'+',defending_unit.unit_strength * (defender_base_defense/10),')')
	attacker_effective_attack = attacking_unit_weapon['attack_strength'] + attacking_unit_weapon['attack_strength'] * (attacking_unit.unit_strength/10)
	print_combat_debug('Attacking entity has effective attack of ',attacker_effective_attack,' (',attacking_unit_weapon['attack_strength'],'+',attacking_unit_weapon['attack_strength'] * (attacking_unit.unit_strength/10),')')
	
	# adding attack_bonus
	var total_attack_bonus = attacking_unit.attack_bonus + attacking_unit.temp_attack_bonus
	if total_attack_bonus != 0:
		attacker_effective_attack += total_attack_bonus
		print_combat_debug('Attacker has attack modifier of ',total_attack_bonus,' resulting in effective attack value change to: ',attacker_effective_attack)

	## Armor piercing weapon & armor effects
	if defending_unit.armor > 0:
		print_combat_debug('Defender has armor value of ',defending_unit.armor)
		if attacking_unit_weapon['armor_piercing'] <= 0:
			attacker_effective_attack = attacker_effective_attack * 0.1
			print_combat_debug('Thus, the attacker is ineffective, will only deal ',attacker_effective_attack,' damage.')
		elif attacking_unit_weapon['armor_piercing'] >= 0:
			var at_factor = defending_unit.armor / attacking_unit_weapon['armor_piercing']
			attacker_effective_attack = attacker_effective_attack + at_factor
			print_combat_debug('But attackers weapons are armor piercing, dealing additional damage of ',at_factor,' totalling ',attacker_effective_attack,' attack value.')

	## Area of effect weapon
	if defending_unit.armor <= 0 and attacking_unit_weapon['explosive'] > 0:
		attacker_effective_attack = attacker_effective_attack * (attacking_unit_weapon['explosive'] * 0.5)
		var he_factor = ((attacker_effective_attack * (attacking_unit_weapon['explosive'])) - attacker_effective_attack) / 0.75
		attacker_effective_attack -= defending_unit.base_defense
		print_combat_debug('Defender is soft target and attacker has HE weapons, attack will deal additional damage of ',he_factor,' totalling ',attacker_effective_attack,' attack value.')

	# #### Finally, battling it out
	print_combat_debug('Attacker attempts attack with',attacker_effective_attack,'effective attack, while defender has',defender_effective_strength,'effective strength.')

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
	if rand >= (0.45 - _get_experience_multiplier()):
		print_combat_debug("Attacker scores a hit.")
		hit = true
	else:
		print_combat_debug("Attacker misses and the attack ends.")
	# Track that the defender was attacked (for suppression).
	defending_unit.register_attacked()

	# Apply damage variance/graze only on hit.
	if hit:
		var variance = randf_range(1.0 - DAMAGE_VARIANCE, 1.0 + DAMAGE_VARIANCE)
		var graze = 1.0
		if randf() <= GRAZE_CHANCE:
			graze = GRAZE_MULTIPLIER
		var post_variance_attack = attacker_effective_attack * variance
		var post_graze_attack = post_variance_attack * graze
		print_combat_debug("Damage variance:", "%.2f" % variance, "Graze multiplier:", "%.2f" % graze)
		print_combat_debug("Damage after variance:", "%.2f" % post_variance_attack, "Damage after graze:", "%.2f" % post_graze_attack)
		attacker_effective_attack = float("%.1f" % post_graze_attack)

	# Update base stats, ragardless of hit or miss
	if attacking_unit_weapon['use_ammo']:
		attacking_unit.ammo -= 1
	attacking_unit.movement_points -= 1
	attacking_unit.update()

	# Handle experience gain
	if hit:
		attacking_unit.experience += 0.05
		print_combat_debug(report_result(attacking_unit, 0.05))
	else:
		attacking_unit.experience += 0.03
		print_combat_debug(report_result(attacking_unit, 0.03))

	# If hit, apply damage and spawn effects, otherwise, just end the attack.
	if hit:
		state_save = {
			'defending_unit': defending_unit,
			'defender_effective_strength': defender_effective_strength,
			'defender_defense_factor': defense_factor,
			'attacking_unit_weapon': attacking_unit_weapon,
			'attacker_effective_attack': attacker_effective_attack,
			'attacking_unit': attacking_unit
		}
		self.attack_delay_timer.start()
	else:
		_finalize_action_state()
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

func print_combat_debug(...args) -> void:
	if not combat_debug:
		return
	var message: String = ""
	for arg in args:
		message += str(arg)
	print(message)

func report_result(attacking_unit, exp_value) -> String:
	return "Unit " + str(attacking_unit.display_name) + " gains " + str(exp_value) + " experience, total experience is now " + str(attacking_unit.experience) + " (" + attacking_unit._get_experience_display_name() + ")"

# Finish attack, because how Godot works (or rather, how I don't work)
func _process_attack_finish():
	var defending_unit = state_save['defending_unit']
	var defender_effective_strength = state_save['defender_effective_strength']
	var defender_defense_factor = state_save.get('defender_defense_factor', 1.0)
	var attacking_unit_weapon = state_save['attacking_unit_weapon']
	var attacker_effective_attack = state_save['attacker_effective_attack']
	var attacking_unit = state_save['attacking_unit']

	_spawn_weapon_impact_effect(defending_unit, attacking_unit_weapon)
	defending_unit._play_sound('hit', attacking_unit_weapon)

	# If attacker has attack value greater zero...
	if attacker_effective_attack > 0:
		print_combat_debug('Defending entity strength is calculated by',defender_effective_strength,'-',attacker_effective_attack,'rounded, which is ',"%.1f" % (defender_effective_strength - attacker_effective_attack))
		# Calculate how much strength is left after attack
		var new_effective_strength = float("%.1f" % (defender_effective_strength - attacker_effective_attack))
		var new_defender_strength = float("%.1f" % (new_effective_strength / maxf(defender_defense_factor, 0.1)))
		# Has attack managed to overcome effective defense boost?
		if new_effective_strength < defender_effective_strength:
			if float(new_defender_strength) <= 0:
				print_combat_debug('Defending unit is destroyed!')
				defending_unit.kill()
				# Handle experience gain for the attacking unit for killing the defender
				attacking_unit.experience += 0.08
				print_combat_debug(report_result(attacking_unit, 0.08))
			else:
				defending_unit.damage(new_defender_strength)
		else:
			print_combat_debug('Attack did not manage to get trough to defenders base strength.')
	_finalize_action_state()

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
	self.max_movement_points = self.movement_points
	self._populate_weapons()
	self._fill_mods()
	self.experience_definitions = themeMgr.get_faction_experience_definitions(self.unit_faction)
	_debug_log("fill_attributes(): done.")

# Fill modifiers, that were given to the unit before game start, from themeMgr
func _fill_mods():
	for index in range(0, self.modifiers.size()):
		var modifier_id = modifiers[index]
		self.active_modifiers[modifier_id] = themeMgr.get_modifier(modifier_id)
		self.active_modifiers[modifier_id]['applied'] = false
	_update_modifier_icons()

func _add_dynamic_modifier(modifier_id: String) -> void:
	var modifier = themeMgr.get_modifier(modifier_id)
	if modifier == null:
		return
	self.active_modifiers[modifier_id] = modifier
	self.active_modifiers[modifier_id]['applied'] = false
	_update_modifier_icons()

func _update_stationary_state() -> void:
	var current_grid = hexmap.global_to_map(self.global_position)
	if last_grid_pos == null:
		last_grid_pos = current_grid
		stationary_turns = 0
		return
	if current_grid == last_grid_pos:
		stationary_turns += 1
	else:
		last_grid_pos = current_grid
		stationary_turns = 0

func _apply_cover_modifier() -> void:
	var tile = game._get_hex_object_from_grid_pos(Vector2i(hexmap.global_to_map(self.global_position)))
	if tile == null or not tile.has("name"):
		return
	var tile_name = str(tile["name"]).to_lower()
	var rule = _get_cover_rule(tile_name)
	if rule.is_empty():
		return
	if stationary_turns < int(rule["min_stay"]):
		return
	if randf() <= float(rule["chance"]):
		_add_dynamic_modifier(str(rule["modifier"]))

func _get_cover_rule(tile_name: String) -> Dictionary:
	# @TODO Since tiles are theme specific, all this should be simplified and the cover/chance value moved
	# to the theme data, so it can be defined per theme instead of hardcoded here. 
	if tile_name.find("forest") >= 0:
		return {"modifier": "cover_heavy", "chance": 0.9, "min_stay": 0}
	if tile_name.find("village") >= 0 or tile_name.find("city") >= 0:
		return {"modifier": "cover_heavy", "chance": 0.85, "min_stay": 0}
	if tile_name.find("mountain") >= 0:
		return {"modifier": "cover_medium", "chance": 0.7, "min_stay": 0}
	if tile_name.find("swamp") >= 0:
		return {"modifier": "cover_medium", "chance": 0.6, "min_stay": 0}
	if tile_name.find("river") >= 0:
		return {"modifier": "cover_light", "chance": 0.3, "min_stay": 1}
	if tile_name.find("desert") >= 0 or tile_name.find("plain") >= 0 or tile_name.find("road") >= 0:
		return {"modifier": "cover_light", "chance": 0.2, "min_stay": 1}
	return {}

func register_attacked():
	if game == null:
		return
	var current_turn = game.turn_counter
	if last_attacked_turn == null:
		attack_streak = 1
	elif last_attacked_turn == current_turn or last_attacked_turn == current_turn - 1:
		attack_streak += 1
	else:
		attack_streak = 1
	last_attacked_turn = current_turn
	if attack_streak >= 2:
		var exp_multiplier = _get_experience_multiplier()
		var base_chance = 0.6
		var chance = clampf(base_chance * (1.0 - exp_multiplier), 0.1, 0.9)
		if randf() <= chance:
			suppression_turns = 1

# Apply modifier changes to entity stats, also deletes mods if their max duration is reached.
# Marks every modifier with "applied" = true so it will not be added to the units stats twice.
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
	_update_modifier_icons()

# Public function to count down all active mods with duration. This is to be called
# every time a turn ends.
func update_timed_modifiers():
	# Reset temporary combat modifiers each turn.
	temp_attack_bonus = 0
	temp_defense_bonus = 0
	# Update stationary state and apply cover modifiers.
	_update_stationary_state()
	_apply_cover_modifier()
	# Apply suppression if active.
	if suppression_turns > 0:
		_add_dynamic_modifier("suppressed")
		suppression_turns -= 1
	# Apply any newly added modifiers.
	_apply_mods()
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
	_start_move_particles()
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
	# Face the direction before moving this step.
	self._set_sprite(self.direction)
	var move_tween = create_tween()
	move_tween.set_trans(timing)
	move_tween.set_ease(easing)
	var step_duration = clampf(1 * float(current_tile.move_cost), 0.2, 2.0)
	move_tween.tween_property(self, "global_position", _get_centered_grid_pos(current_tile['grid_pos'], self.offset), step_duration)
	move_tween.finished.connect(_on_move_tween_finished, CONNECT_ONE_SHOT)
	
# From the last movements angle, get the direction mapped, so it references
# to a direction sprite from the theme.
func _get_direction(angle):
	var dir = 0
	if angle > 145 and angle < 155:
		dir = 0
		print_debug("Moving southwest")
	elif angle > -155 and angle < -145:
		dir = 1
		print_debug("Moving northwest")
	elif angle > -95 and angle < -85:
		dir = 2
		print_debug("Moving north")
	elif angle > -35 and angle < -25:
		dir = 3
		print_debug("Moving northeast")
	elif angle > 25 and angle < 35:
		dir = 4
		print_debug("Moving southeast")
	elif angle > 85 and angle < 95:
		dir = 5
		print_debug("Moving south")
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

func _get_weapons_array() -> Array:
	if weapons == null:
		return []
	if typeof(weapons) != TYPE_ARRAY:
		_populate_weapons()
	if typeof(weapons) == TYPE_ARRAY:
		return weapons
	return []

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
		print_combat_debug("Weapon " + weapon.display_name + " is out of range.")
		return false
	return distance <= _get_weapon_range(weapon)

func _get_weapon_in_range(target_global_pos: Vector2, target_unit = null):
	var weapons_array = _get_weapons_array()
	if weapons_array.is_empty():
		return null
	var best_weapon = null
	var best_score = -INF
	for weapon in weapons_array:
		if weapon == null:
			continue
		if not _is_weapon_in_range(weapon, target_global_pos):
			continue
		if target_unit == null:
			return weapon
		var score = _estimate_weapon_effective_attack(weapon, target_unit)
		if score > best_score:
			best_score = score
			best_weapon = weapon
	return best_weapon

func _is_in_range(target_global_pos: Vector2) -> bool:
	return _get_weapon_in_range(target_global_pos) != null

# Internal function to estimate the effective attack value of a weapon against a target unit,
# taking into account the weapon's attack strength, the unit's strength, attack bonuses, and 
# the target's defense and armor.
func _estimate_weapon_effective_attack(weapon, target_unit) -> float:
	if weapon == null or target_unit == null:
		return -INF
	var attack_strength = float(weapon.get("attack_strength", 0))
	var attack_value = attack_strength + (attack_strength * (self.unit_strength / 10.0))
	attack_value += float(self.attack_bonus) + float(self.temp_attack_bonus)
	var target_armor = float(target_unit.armor)
	if target_armor > 0:
		var armor_piercing = float(weapon.get("armor_piercing", 0))
		if armor_piercing <= 0:
			attack_value *= 0.1
		else:
			attack_value += target_armor / armor_piercing
	elif float(weapon.get("explosive", 0)) > 0:
		attack_value *= float(weapon.get("explosive", 0)) * 0.5
		attack_value -= float(target_unit.base_defense)
	return attack_value

# Internal function to populate weapon list with actual theme objects
func _populate_weapons() -> void:
	var weapon_ids = self.weapons
	self.weapons = []
	for weapon_id in weapon_ids:
		self.weapons.append(themeMgr.get_weapon(weapon_id))

func _update_quick_panel_transform() -> void:
	if unit_quick_panel == null or hexmap == null:
		return
	# Keep the panel anchored above the unit in world space.
	var grid_coords = hexmap.global_to_map(self.get_global_position())
	unit_quick_panel.set_global_position(self._get_centered_grid_pos(grid_coords, Vector2(-100,50)))
	# Counter camera zoom so the panel stays a consistent size on screen.
	var camera := get_viewport().get_camera_2d()
	if camera != null:
		var zoom := camera.zoom
		if zoom.x != 0 and zoom.y != 0:
			unit_quick_panel.scale = Vector2(1.0 / zoom.x, 1.0 / zoom.y)
	# Scale around center to avoid drifting when zoom changes.
	unit_quick_panel.pivot_offset = unit_quick_panel.size * 0.5

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
		# Global update is for updating global look-up tables with grid positions
		root.update_entity_list_entry(entity_representation)
		_stop_move_particles()
	_finalize_action_state()

func _on_MoveTween_tween_completed(_object, _key):
	_on_move_tween_finished()

func _on_AttackEffectDelay_timeout():
	attack_delay_timer.stop()
	self._process_attack_finish()

func _on_mouse_entered():
	_is_hovered_flag = true
	if not is_selected():
		show_quick_panel()

func _on_mouse_exited():
	_is_hovered_flag = false
	if not is_selected():
		hide_quick_panel()

func _on_selected():
	set_state(UnitState.SELECTED)
	show_quick_panel()
	
func _on_deselected():
	if state == UnitState.SELECTED:
		set_state(UnitState.IDLE)
	hide_quick_panel()

func set_state(new_state: int) -> void:
	if state == new_state:
		return
	state = new_state
	if unit_quick_panel != null and unit_quick_panel.visible:
		_update_quick_panel()

func get_state() -> int:
	return state

func can_receive_orders() -> bool:
	return state == UnitState.IDLE or state == UnitState.SELECTED

# Returns true if the unit is in a blocking action/death state.
# @returns {Boolean}
func is_busy_state() -> bool:
	return state in [
		UnitState.MOVING,
		UnitState.ATTACKING,
		UnitState.GARRISONING,
		UnitState.UNGARRISONING,
		UnitState.BEING_SUPPLIED,
		UnitState.SUPPLYING,
		UnitState.DYING,
		UnitState.DEAD
	]

# Returns state enum key as readable string.
# @returns {String}
func get_state_name() -> String:
	return UnitState.keys()[state]

func _finalize_action_state() -> void:
	if state == UnitState.DEAD or state == UnitState.DYING:
		return
	if self.get_movement_points() <= 0:
		set_state(UnitState.SPENT)
	else:
		set_state(UnitState.IDLE)

func _debug_log(message):
	if debug_logging:
		print("[Debug][Unit:" + name + "|" + str(unit_id) + "] " + message)
