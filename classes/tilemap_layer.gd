extends TileMapLayer

# class member variables
var tile_types = [
	{"name": "Plain Grass", "move_cost": 1.0, "terrain": "land"},
	{"name": "Forest", "move_cost": 2.0, "terrain": "land"},
	{"name": "River", "move_cost": 2.0, "terrain": "river"},
	{"name": "Road", "move_cost": 0.5, "terrain": "land"},
	{"name": "Mountains", "move_cost": 5.0, "terrain": "land"},
	{"name": "Village", "move_cost": 1.5, "terrain": "land"},
	{"name": "Water", "move_cost": 1.0, "terrain": "water"},
	{"name": "Desert", "move_cost": 1.0, "terrain": "land"},
	{"name": "City", "move_cost": 1.5, "terrain": "land"}
]

# Compatibility wrapper for legacy code paths that used TileMap.get_cell_size().
func get_cell_size():
	if tile_set != null:
		return Vector2(tile_set.tile_size)
	return Vector2(128, 128)

# Compatibility wrapper for Godot 2/3 API.
func world_to_map(world_pos):
	return local_to_map(to_local(world_pos))

# Compatibility wrapper for Godot 2/3 API.
func map_to_world(grid_pos):
	return to_global(map_to_local(Vector2i(grid_pos)))

# Compatibility wrapper that mirrors the older API used in game.gd.
func get_used_cells_compat(_layer = 0):
	return get_used_cells()

# Compatibility wrapper for Godot 2/3 API.
func get_cell(x, y):
	var coords = Vector2i(int(x), int(y))
	var source_id = get_cell_source_id(coords)
	if source_id == -1:
		return -1
	var atlas_coords = get_cell_atlas_coords(coords)
	if atlas_coords.x >= 0:
		return atlas_coords.x
	return source_id

# Return a object with attributes for the tile with the given tileset index.
func _get_tile_attributes_by_index(index):
	if index >= 0 and index < tile_types.size():
		return tile_types[index]
	print("Error: tilemap_layer.gd - No tile type with that index:" + str(index))
	return tile_types[0]

# Return an attribute by its name for the tile with given tileset index.
func _get_tile_attribute_by_index(index, attribute):
	if index >= 0 and index < tile_types.size():
		return tile_types[index][str(attribute)]
	print("Error: tilemap_layer.gd - No tile type with that index:" + str(index))
	return tile_types[0].get(str(attribute), null)
