extends TileMap

# class member variables
var tile_types = [
	# 0
	{
		'name': 'Plain Grass',
		'move_cost': 1.0,
		'terrain': 'land'
	},
	# 1
	{
		'name': 'Forest',
		'move_cost': 5.0,
		'terrain': 'land'
	},
	# 2
	{
		'name': 'River',
		'move_cost': 10.0,
		'terrain': 'river'
	},
	# 3
	{
		'name': 'Road',
		'move_cost': 0.5,
		'terrain': 'land'
	},
	# 4
	{
		'name': 'Mountains',
		'move_cost': 12.0,
		'terrain': 'land'
	},
	# 5
	{
		'name': 'Village',
		'move_cost': 1.5,
		'terrain': 'land'
	},
	# 6
	{
		'name': 'Water',
		'move_cost': 1.0,
		'terrain': 'water'
	}
]

func _ready():
	pass

# Return a object with attributes for the tile with the given tileset index.
# @input Int the tileset index
func _get_tile_attributes_by_index(index):
	if index <= tile_types.size() or index >= 0:
		return tile_types[index]
	else:
		print("Error: tilemap.gd - No tile type with that index:"+String(index))
		return false

# Return a single attribute by its name for the tile with given tileset index.
# @input Int the tileset index
# @input String attribute name
func _get_tile_attribute_by_index(index, attribute):
	if index <= tile_types.size() or index >= 0:
		return tile_types[index][String(attribute)]
	else:
		print("Error: tilemap.gd - No tile type with that index:"+String(index))
		return false
