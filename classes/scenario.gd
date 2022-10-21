extends Node2D

# Define the current scenario, including victory and defeat conditions
# map and theme options.

# Private members
onready var game = get_node('/root/Game')
var standard_themes_path = 'res://themes'
# Public members
export (String) var theme = ""
export var players_definition = [
    {'id': 0, 'name': 'Human', 'factionID': 'usarmy', 'isHuman': true, 'stances': {'enemies':[1],'neutral':[2]}},
    {'id': 1, 'name': 'Computer', 'factionID': 'taliban', 'isHuman': false, 'stances': {'enemies':[0,2]}},
    {'id': 2, 'name': 'Civilians', 'factionID': 'civilians', 'isHuman': false, 'stances': {'neutral':[0,1,2]}}
]

func _ready():
    pass

# Public getter for player definition array. Each placer, their faction and stances towards
# other players is defined by this.
func get_players_def():
    return self.players_definition

# Public getter for scenario theme.
func get_theme():
    return self.theme