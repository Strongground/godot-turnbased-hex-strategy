extends "res://classes/entity.gd"

# Public class members

# victory point owner
# expect id of faction based on imported factions file from theme
# further implications of a faction owning this point is defined elsewhere 
# (e.g. "player wins if victory point held" or "player who holds x victory points 
# held by for y amount of time wins"). This entity just handles a point that is
# capturable.
export var vp_owner = ''

# Private class members
onready var playerMgr =  $'/root/Game/PlayerManager'
onready var themeMgr =  $'/root/Game/ThemeManager'

## Called every time the node is added to the scene.
func _ready():
	## Init ingame
	type = 'victory_point'
	self._snap_to_grid()
	self.set_container(true)
	self.set_selectable(false)

func set_owner(id):
	if playerMgr.get_player_by_id(id):
		self.vp_owner = id
		return true
	return false

func check_ownership():
	var overlapping_entities = self.get_overlapping_areas()
	if overlapping_entities.size() > 0:
		for entity in overlapping_entities:
			if entity.type == 'unit':
				self.set_owner(entity.get_owner())
				self._set_owner_icon(entity.get_faction())

func _set_owner_icon(owner_faction):
	var faction_icon = themeMgr.get_faction_icon(owner_faction)
	$OwnerIcon/FlagSin.set_texture(faction_icon)
