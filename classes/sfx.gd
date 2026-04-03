extends Node2D

# This element represents a effect. It can either be a
# one-shot effect like an explosion, or something lasting
# like a crater or a trench.
#
# It supports two effect authoring modes:
# - legacy sprite-frame animations loaded from theme data
# - scene-based effects with particles/AnimationPlayer

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite
@onready var effect_root: Node2D = $EffectRoot
@export var themeMgr: Node
@onready var sound_emitter = $SoundEmitter

# If 'lifetime' is -1, it will exist until manually deleted.
# If 'lifetime' is 0 (default), the effect will exist as long as the
# underlying scene/animation needs.
# If 'lifetime' has any other value > 0, it will play for this amount of seconds.
var lifetime = 0.0
var current_effect_instance: Node = null

func initialize(position, id, effect_type, effect_lifetime=self.lifetime, options: Dictionary = {}):
	if effect_lifetime != self.lifetime:
		self.lifetime = effect_lifetime
	global_position = position
	if options.has("rotation"):
		global_rotation = float(options["rotation"])
	if options.has("scale"):
		scale = options["scale"]
	_clear_effect_state()
	var effect_definition = {}
	if options.has("scene_path"):
		effect_definition["scene"] = str(options["scene_path"])
	if options.has("duration"):
		effect_definition["duration"] = float(options["duration"])
	if themeMgr != null and themeMgr.has_method("get_effect"):
		var themed_effect_definition = themeMgr.get_effect(id)
		if not themed_effect_definition.is_empty():
			effect_definition = themed_effect_definition
	if _initialize_scene_effect(effect_definition, options):
		_start_lifetime_timer(_resolve_effect_duration(effect_definition))
		return
	if _initialize_sprite_effect(id, effect_type):
		_start_lifetime_timer(_resolve_effect_duration(effect_definition, id))
		return
	call_deferred("free")

func _initialize_scene_effect(effect_definition: Dictionary, options: Dictionary) -> bool:
	if effect_definition == null or effect_definition.is_empty():
		return false
	var scene_path = str(effect_definition.get("scene", ""))
	if scene_path.is_empty() or themeMgr == null or not themeMgr.has_method("resolve_theme_resource_path"):
		return false
	var resolved_scene_path = themeMgr.resolve_theme_resource_path(scene_path)
	if not ResourceLoader.exists(resolved_scene_path):
		return false
	var packed_scene = load(resolved_scene_path) as PackedScene
	if packed_scene == null:
		return false
	current_effect_instance = packed_scene.instantiate()
	effect_root.add_child(current_effect_instance)
	if current_effect_instance.has_method("start"):
		current_effect_instance.start(options)
	return true

func _initialize_sprite_effect(id, effect_type) -> bool:
	if themeMgr == null or not themeMgr.has_method("get_effect_sprites"):
		return false
	var frames = themeMgr.get_effect_sprites(id, effect_type)
	if frames == null or frames.is_empty():
		return false
	var sprite_frames = SpriteFrames.new()
	sprite_frames.add_animation(id)
	sprite_frames.set_animation_loop(id, false)
	for frame in frames:
		var tex = load(frame)
		if tex != null:
			sprite_frames.add_frame(id, tex)
	if sprite_frames.get_frame_count(id) <= 0:
		return false
	animated_sprite.sprite_frames = sprite_frames
	animated_sprite.speed_scale = 5
	animated_sprite.animation = id
	animated_sprite.visible = true
	animated_sprite.play(id)
	return true

# Determines the duration of the effect based on various factors, including lifetime, effect definition, and legacy animation frames
func _resolve_effect_duration(effect_definition: Dictionary, legacy_animation_id = "") -> float:
	if lifetime < 0:
		return -1
	if lifetime > 0:
		return lifetime
	if effect_definition != null and not effect_definition.is_empty() and effect_definition.has("duration"):
		return float(effect_definition["duration"])
	if current_effect_instance != null and current_effect_instance.has_method("get_duration"):
		return float(current_effect_instance.get_duration())
	if legacy_animation_id != "" and animated_sprite.sprite_frames != null and animated_sprite.sprite_frames.has_animation(legacy_animation_id):
		var frame_count = animated_sprite.sprite_frames.get_frame_count(legacy_animation_id)
		return frame_count / maxf(animated_sprite.speed_scale * 2.0, 0.01)
	return 0.35

# Starts a timer to automatically free the effect after its duration has elapsed
func _start_lifetime_timer(effect_runtime: float) -> void:
	if effect_runtime < 0:
		return
	$lifetimer.wait_time = maxf(effect_runtime, 0.01)
	$lifetimer.start()

func _clear_effect_state() -> void:
	animated_sprite.stop()
	animated_sprite.visible = false
	animated_sprite.sprite_frames = SpriteFrames.new()
	for child in effect_root.get_children():
		child.queue_free()
	current_effect_instance = null

func _on_lifetimer_timeout():
	call_deferred('free')
