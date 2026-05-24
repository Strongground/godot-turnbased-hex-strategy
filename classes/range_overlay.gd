extends Node2D

# Cached polygon draw jobs for current highlight render.
var _fill_polygons: Array = []
var _boundary_segments: Array = []

# Optional textured fill for range highlights.
@export var fill_texture: Texture2D
@export var fill_texture_scale: float = 1.0
@export var pattern_opacity: float = 0.25
# CanvasItem draw settings for textured fills.
@export var texture_repeat_mode: CanvasItem.TextureRepeat = CanvasItem.TEXTURE_REPEAT_ENABLED
@export var texture_filter_mode: CanvasItem.TextureFilter = CanvasItem.TEXTURE_FILTER_LINEAR

func _ready() -> void:
	# Ensure repeated UVs actually tile for draw_polygon().
	texture_repeat = texture_repeat_mode
	texture_filter = texture_filter_mode

# Clear all highlight polygons.
# @returns {Void}
func clear_highlights() -> void:
	_fill_polygons.clear()
	_boundary_segments.clear()
	queue_redraw()

# Set highlighted tiles by grid positions and redraw as polygons.
# @input {Array} grid_positions - grid local tile positions (Vector2i)
# @input {TileMapLayer} hexmap - tilemap to resolve grid to world coordinates
# @input {Node} globals - global helper for named colors
# @input {String} color_name - named color key for globals.getColor()
# @input {float} opacity - fill opacity from 0.0 to 1.0; set to 0.0 for outline only
# @returns {Void}
func set_highlight_tiles(grid_positions: Array, hexmap: TileMapLayer, globals: Node, color_name: String, opacity: float = 0.35) -> void:
	_fill_polygons.clear()
	_boundary_segments.clear()
	if hexmap == null or globals == null:
		queue_redraw()
		return
	var fill_opacity = opacity
	if fill_texture != null and fill_opacity <= 0.0:
		fill_opacity = pattern_opacity
	var fill_color = globals.getColor(color_name, fill_opacity)
	var outline_color = globals.getColor(color_name, minf(1.0, opacity + 0.35))
	var edge_counts: Dictionary = {}
	var edge_points: Dictionary = {}
	for grid_pos in grid_positions:
		var world_pos = hexmap.map_to_global(Vector2i(grid_pos))
		var center = Vector2(world_pos.x, world_pos.y)
		var polygon = _build_hex_polygon(center, hexmap.get_cell_size())
		if fill_opacity > 0.0:
			_fill_polygons.append({"points": polygon, "color": fill_color})
		_register_polygon_edges(polygon, edge_counts, edge_points)
	for edge_key in edge_counts.keys():
		if int(edge_counts[edge_key]) == 1:
			var edge = edge_points[edge_key]
			_boundary_segments.append({"a": edge["a"], "b": edge["b"], "color": outline_color})
	queue_redraw()

# Draw all cached highlight polygons.
# @returns {Void}
func _draw() -> void:
	for entry in _fill_polygons:
		var points: PackedVector2Array = entry["points"]
		var color: Color = entry["color"]
		if fill_texture != null:
			var tex_size = fill_texture.get_size()
			if tex_size.x > 0 and tex_size.y > 0:
				var uvs := PackedVector2Array()
				for point in points:
					var uv = (point / maxf(fill_texture_scale, 0.001)) / tex_size
					uvs.append(uv)
				var colors := PackedColorArray()
				for _i in range(points.size()):
					colors.append(color)
				draw_polygon(points, colors, uvs, fill_texture)
				continue
		draw_colored_polygon(points, color)
	for segment in _boundary_segments:
		draw_line(segment["a"], segment["b"], segment["color"], 2.0, true)

# Register all edges of a polygon and count shared boundaries.
# @input {PackedVector2Array} polygon - hex polygon points
# @input {Dictionary} edge_counts - edge usage counter map
# @input {Dictionary} edge_points - edge endpoints map
# @returns {Void}
func _register_polygon_edges(polygon: PackedVector2Array, edge_counts: Dictionary, edge_points: Dictionary) -> void:
	for i in range(polygon.size()):
		var a: Vector2 = polygon[i]
		var b: Vector2 = polygon[(i + 1) % polygon.size()]
		var edge_key = _get_edge_key(a, b)
		edge_counts[edge_key] = int(edge_counts.get(edge_key, 0)) + 1
		if not edge_points.has(edge_key):
			edge_points[edge_key] = {"a": a, "b": b}

# Build an undirected stable key for an edge so shared edges match.
# @input {Vector2} a - first edge point
# @input {Vector2} b - second edge point
# @returns {String} canonical edge key
func _get_edge_key(a: Vector2, b: Vector2) -> String:
	var ax = snappedf(a.x, 0.01)
	var ay = snappedf(a.y, 0.01)
	var bx = snappedf(b.x, 0.01)
	var by = snappedf(b.y, 0.01)
	var a_key = str(ax) + "," + str(ay)
	var b_key = str(bx) + "," + str(by)
	if a_key < b_key:
		return a_key + "|" + b_key
	return b_key + "|" + a_key

# Build a flat-top hex polygon around center.
# @input {Vector2} center - polygon center in local/global canvas coords
# @input {Vector2} cell_size - tile cell size from tilemap
# @returns {PackedVector2Array} hex polygon points
func _build_hex_polygon(center: Vector2, cell_size: Vector2) -> PackedVector2Array:
	var half_w = cell_size.x * 0.5
	var half_h = cell_size.y * 0.5
	var quarter_w = cell_size.x * 0.25
	return PackedVector2Array([
		center + Vector2(-quarter_w, -half_h),
		center + Vector2(quarter_w, -half_h),
		center + Vector2(half_w, 0),
		center + Vector2(quarter_w, half_h),
		center + Vector2(-quarter_w, half_h),
		center + Vector2(-half_w, 0),
	])
