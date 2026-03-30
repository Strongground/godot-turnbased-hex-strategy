extends Node2D

@export var game: Node
@export var ThemeMgr: Node

@onready var map_graphic: Node = game.get_node("MapGraphic")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var map_texture: Texture = map_graphic.get_texture()
	var map_scale: Vector2 = map_graphic.get_scale()
	$ColorRect.set_size(Vector2(map_texture.get_width()*map_scale.x, map_texture.get_height()*map_scale.y))
	self.set_visible(true)
	self.set_position(Vector2(0,0))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
