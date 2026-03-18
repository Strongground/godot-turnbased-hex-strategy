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

# Compatibility wrapper for legacy code paths that used TileMap.get_cell_size().
func get_cell_size():
	if tile_set != null:
		return Vector2(tile_set.tile_size)
	return Vector2(128, 128)

# Compatibility wrapper for Godot 2/3 API.
func world_to_map(world_pos):
	var layer = _get_primary_layer_node()
	if layer != null:
		return layer.local_to_map(layer.to_local(world_pos))
	return local_to_map(to_local(world_pos))

# Compatibility wrapper for Godot 2/3 API.
func map_to_world(grid_pos):
	var layer = _get_primary_layer_node()
	if layer != null:
		return layer.to_global(layer.map_to_local(Vector2i(grid_pos)))
	return to_global(map_to_local(Vector2i(grid_pos)))

# Compatibility wrapper that also supports converted TileMapLayer children.
func get_used_cells_compat(layer = 0):
	var cells = super.get_used_cells(layer)
	if cells.size() > 0:
		return cells
	var layer_node = _get_primary_layer_node()
	if layer_node != null:
		return layer_node.get_used_cells()
	return cells

# Compatibility wrapper for Godot 2/3 API.
func get_cell(x, y):
	var coords = Vector2i(int(x), int(y))
	var source_id = super.get_cell_source_id(0, coords)
	var atlas_coords = Vector2i(-1, -1)
	if source_id == -1:
		var layer_node = _get_primary_layer_node()
		if layer_node != null:
			source_id = layer_node.get_cell_source_id(coords)
			atlas_coords = layer_node.get_cell_atlas_coords(coords)
		if source_id == -1:
			return -1
	else:
		atlas_coords = super.get_cell_atlas_coords(0, coords)
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
