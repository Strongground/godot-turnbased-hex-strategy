extends Node2D

# Player Class
# This serves as anchor for the actual player, handling a subset of units
# on a given map. A player is always associated with one faction. 
# A player can have a stance towards other players.

# Basic members
var active = false
var faction = 0
var is_human = true
var player_name = ''
var identifer = 0
var enemies = []
var neutrals = []
var allies = []

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
		self.set_name(playerName)
	else:
		var tempName = 'UnknownPlayer'+String(self.get_instance_id())
		self.set_name(tempName)
	if factionID == null:
		self.faction = 0
	else:
		self.faction = factionID
	if is_human:
		self.is_human = true

# Public setter for display name of this player.
func set_name(name):
	self.player_name = String(name)
	
# Public getter for display name of this player.
func get_name():
	return self.player_name

# To get Godots node ID, use player.id, to get custom ID the
# game logic actually uses, use this
# public getter.
func get_id():
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

# Public getter to get the faction this players plays as.
func get_faction():
	return $FactionManager.get_faction(self.faction)

# Public getter to check wether this player is controlled by AI or a human.
func is_human():
	return is_human

# Public getter to check the stance of this player towards another player.
# If for some reason no stance is found for the player, the default of
# "neutral" is returned. The default stance could be a theme setting.
func get_stance_to(player):
	var id = player.get_id()
	if id in self.enemies:
		return 'enemy'
	elif id in self.allies:
		return 'ally'
	elif id in self.allies:
		return 'neutral'
	else:
		return 'neutral'