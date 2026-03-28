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
var _source_id_index_map: Dictionary = {}

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
		var source = tile_set.get_source(source_id)
		if source is TileSetAtlasSource:
			var grid_size: Vector2i = source.get_atlas_grid_size()
			if grid_size.x <= 0 or grid_size.y <= 0:
				var atlas_texture = source.get_texture()
				if atlas_texture != null:
					var tex_size = atlas_texture.get_size()
					var tile_size = tile_set.tile_size
					if tile_size.x > 0 and tile_size.y > 0:
						grid_size = Vector2i(
							int(floor(float(tex_size.x) / float(tile_size.x))),
							int(floor(float(tex_size.y) / float(tile_size.y)))
						)
			# If this source only contains a single tile, atlas coords don't identify type.
			if grid_size.x <= 1 and grid_size.y <= 1:
				var mapped_index = _map_source_id_to_index(source_id)
				if mapped_index >= 0:
					return mapped_index
			if grid_size.x > 0:
				return int(atlas_coords.x + atlas_coords.y * grid_size.x)
			# Single-tile atlas source: try mapping by tile name.
			var tile_name = ""
			if source.has_method("get_tile_name"):
				tile_name = str(source.get_tile_name(atlas_coords))
			var name_index = _find_tile_type_index_by_name(tile_name)
			if name_index >= 0:
				return name_index
			# Fallback: map source ids to tile list order.
			var mapped_index = _map_source_id_to_index(source_id)
			if mapped_index >= 0:
				return mapped_index
			return int(atlas_coords.x)
		# Non-atlas sources don't use atlas coords for identity.
		var mapped_index = _map_source_id_to_index(source_id)
		if mapped_index >= 0:
			return mapped_index
		return source_id
	return source_id

func _find_tile_type_index_by_name(tile_name: String) -> int:
	if tile_name == "":
		return -1
	for i in range(tile_types.size()):
		var entry = tile_types[i]
		if entry.has("name") and str(entry["name"]).to_lower() == tile_name.to_lower():
			return i
	return -1

func _map_source_id_to_index(source_id: int) -> int:
	if tile_set == null:
		return -1
	if _source_id_index_map.is_empty():
		var source_ids: Array = []
		if tile_set.has_method("get_source_ids"):
			source_ids = tile_set.get_source_ids()
		elif tile_set.has_method("get_source_count") and tile_set.has_method("get_source_id"):
			var count = int(tile_set.get_source_count())
			for i in range(count):
				source_ids.append(tile_set.get_source_id(i))
		source_ids.sort()
		for i in range(mini(source_ids.size(), tile_types.size())):
			_source_id_index_map[int(source_ids[i])] = i
	if _source_id_index_map.has(source_id):
		return int(_source_id_index_map[source_id])
	return -1

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
