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
	{"name": "Desert", "move_cost": 2.0, "terrain": "land"},
	{"name": "City", "move_cost": 1.5, "terrain": "land"}
]

# Replace tile definitions at runtime (e.g. from a theme file).
func set_tile_types(new_tile_types: Array) -> void:
	if new_tile_types.is_empty():
		return
	tile_types = new_tile_types.duplicate(true)

# Return the tile index used by the game logic for the given grid position.
func get_tile_index(grid_pos: Vector2i) -> int:
	var source_id = get_cell_source_id(grid_pos)
	if source_id == -1:
		return -1
	var atlas_coords = get_cell_atlas_coords(grid_pos)
	if atlas_coords.x >= 0:
		return atlas_coords.x
	return source_id

func get_cell_size() -> Vector2:
	if tile_set != null:
		return Vector2(tile_set.tile_size)
	return Vector2(128, 128)

func global_to_map(given_position: Vector2) -> Vector2i:
	return local_to_map(to_local(given_position))

func map_to_global(grid_position: Vector2i) -> Vector2:
	return to_global(map_to_local(grid_position))

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
