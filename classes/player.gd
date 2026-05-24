extends Node2D

# Player Class
# This serves as anchor for the actual player, handling a subset of units
# on a given map. A player is always associated with one faction. 
# A player can have a stance towards other players.

# Basic members
var active: bool = false
var faction: String = ""
var is_human_player: bool = true
var player_name: String = ''
var identifer: int = 0
var enemies: Array = []
var neutrals: Array = []
var allies: Array = []

func _ready():
	pass

# Fil this player instance from the options given to the player manager object.
# If no options are given for this player, default values are used.
func create(playerName, factionID=null, isHuman=false, id=null):
	if id == null:
		self.set_id(self.get_instance_id())
	else:
		self.set_id(id)
	if playerName.length() > 0:
		self.set_player_name(playerName)
	else:
		var tempName = "UnknownPlayer" + str(self.get_instance_id())
		self.set_player_name(tempName)
	if factionID == null:
		self.faction = ""
	else:
		self.faction = factionID
	if isHuman:
		self.is_human_player = true

# Public setter for display name of this player.
func set_player_name(name):
	self.player_name = str(name)
	
# Public getter for display name of this player.
func get_player_name():
	return self.player_name

# To get Godots node ID, use player.id, to get custom ID the
# game logic actually uses, use this public getter.
func get_id() -> int:
	return self.identifer

# To set the custom game ID, use this public setter.
func set_id(value):
	self.identifer = value

# Public getter to check if it is this players turn.
func is_active():
	return self.active

# Public setter to mark this player as active, meaning it is his turn.
func set_active(active):
	self.active = active

# Public getter to get the faction this player plays as.
func get_faction():
	return $FactionManager.get_faction(self.faction)

# Public getter to get faction ID this player plays as.
func get_faction_id():
	return faction

# Public getter to check wether this player is controlled by AI or a human.
func is_human():
	return is_human_player

# Public getter to check the stance of this player towards another player.
# If for some reason no stance is found for the player, the default of
# "neutral" is returned. The default stance could be a theme setting.
func get_stance_to(player):
	var id = player.get_id()
	if id in self.enemies:
		return 'enemy'
	elif id in self.allies:
		return 'ally'
	elif id in self.neutrals:
		return 'neutral'
	else:
		return 'neutral'
