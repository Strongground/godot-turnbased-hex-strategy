extends Node2D

# This element represents a effect. It can either be a 
# one-shot effect like an explosion, or something lasting
# like a crater or a trench.

# member vars here
onready var animated_sprite = $AnimatedSprite
onready var themeMgr =  $"/root/Game/ThemeManager"
# If 'lifetime' is -1, it will exist until manually deleted.
# If 'lifetime' is 0 (default), the effect will exist as long as the animation
# runs and then terminate itself.
# If 'lifetime' has any other value > 0, it will play for this amount of seconds
var lifetime = 0
var sprite_frames = null

func _ready():
	pass

# Receive coordinates for global position and of the effect
func initialize(position, id, effect_type, effect_lifetime=self.lifetime):
	if effect_lifetime != self.lifetime:
		self.lifetime = effect_lifetime
	sprite_frames = self.animated_sprite.get_sprite_frames()
	sprite_frames.add_animation(id)
	sprite_frames.set_animation_loop(id, false)
	self.animated_sprite.set_speed_scale(5)
	var frames = themeMgr.get_effect_sprites(id, effect_type)
	if !frames:
		print("Error: SFX: Effect "+id+" does not exist or couldn't be found!")
		call_deferred('free')
		return
	frames.invert()
	for frame in frames:
		var i = 0
		var tex = load(frame)
		sprite_frames.add_frame(id, tex, i)
		i = i + 1
	self.animated_sprite.set_animation(id)
	self.set_global_position(position)
	self.animated_sprite._set_playing(true)
	if effect_lifetime >= 0:
		var runtime
		if effect_lifetime == 0:
			runtime = self.animated_sprite.get_sprite_frames().get_frame_count(id) / (self.animated_sprite.get_speed_scale()*2)
		if effect_lifetime > 0:
			runtime = lifetime
		$lifetimer.set_wait_time(runtime)
		$lifetimer.start()

func _on_lifetimer_timeout():
	call_deferred('free')
