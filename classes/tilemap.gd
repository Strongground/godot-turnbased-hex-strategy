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
		'move_cost': 2.0,
		'terrain': 'land'
	},
	# 2
	{
		'name': 'River',
		'move_cost': 2.0,
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
		'move_cost': 5.0,
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
	},
	# 7
	{
		'name': 'Desert',
		'move_cost': 1.0,
		'terrain': 'land'
	},
	# 8
	{
		'name': 'City',
		'move_cost': 1.0,
		'terrain': 'land'
	}
]

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func _get_primary_layer_node():
	for child in get_children():
		if child is TileMapLayer:
			return child
	return null

# Return the tile index used by the game logic for the given grid position.
func get_tile_index(grid_pos: Vector2i, layer = 0) -> int:
	var coords = Vector2i(int(grid_pos.x), int(grid_pos.y))
	var source_id = super.get_cell_source_id(layer, coords)
	var atlas_coords = Vector2i(-1, -1)
	if source_id == -1:
		var layer_node = _get_primary_layer_node()
		if layer_node != null:
			source_id = layer_node.get_cell_source_id(coords)
			atlas_coords = layer_node.get_cell_atlas_coords(coords)
		if source_id == -1:
			return -1
	else:
		atlas_coords = super.get_cell_atlas_coords(layer, coords)
	if atlas_coords.x >= 0:
		return atlas_coords.x
	return source_id

# Return a object with attributes for the tile with the given tileset index.
# @input Int the tileset index
func _get_tile_attributes_by_index(index):
	if index >= 0 and index < tile_types.size():
		return tile_types[index]
	else:
		print("Error: tilemap.gd - No tile type with that index:"+str(index))
		return tile_types[0]

# Return an attribute by its name for the tile with given tileset index.__keys
# @input Int the tileset index
# @input String attribute name
func _get_tile_attribute_by_index(index, attribute):
	if index >= 0 and index < tile_types.size():
		return tile_types[index][str(attribute)]
	else:
		print("Error: tilemap.gd - No tile type with that index:"+str(index))
		return tile_types[0].get(str(attribute), null)
