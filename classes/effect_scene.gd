extends Node2D

@export var autoplay_animation: StringName = &"play"
@export var duration_override: float = 0.0
@export var auto_free: bool = true

@onready var animation_player: AnimationPlayer = get_node_or_null("AnimationPlayer")

# Starts the effect with optional parameters for position, rotation, and scale
func start(options: Dictionary = {}) -> void:
	if options.has("position"):
		global_position = options["position"]
	if options.has("rotation"):
		global_rotation = float(options["rotation"])
	if options.has("scale"):
		scale = options["scale"]
	_restart_particles(self)
	# Dynamically link signal to this script
	if animation_player != null and animation_player.has_animation(autoplay_animation):
		var finished_callable = Callable(self, "_on_animation_finished")
		if not animation_player.animation_finished.is_connected(finished_callable):
			animation_player.animation_finished.connect(finished_callable)
		animation_player.play(autoplay_animation)

# Returns the duration of the effect, either from the override or the animation length
func get_duration() -> float:
	if duration_override > 0.0:
		return duration_override
	if animation_player != null and animation_player.has_animation(autoplay_animation):
		return animation_player.get_animation(autoplay_animation).length
	return 2.0

# Recursively restart all particle systems in the node tree
func _restart_particles(node: Node) -> void:
	for child in node.get_children():
		_restart_particles(child)
	if node is GPUParticles2D:
		node.restart()
		node.emitting = true
	elif node is CPUParticles2D:
		node.restart()
		node.emitting = true

# Callback for when the animation finishes
func _on_animation_finished(animation_name: StringName) -> void:
	if animation_name != autoplay_animation:
		return
	if auto_free:
		call_deferred("free")
