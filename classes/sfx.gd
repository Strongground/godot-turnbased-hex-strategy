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
var lifetime = 0
var sprite_frames = null

func _ready():
	pass

# Receive coordinates for global position and of the effect
func initialize(position, id, effect_lifetime=self.lifetime):
	if effect_lifetime != self.lifetime:
		self.lifetime = effect_lifetime
	sprite_frames = SpriteFrames.new()
	var frames = themeMgr.get_effect_sprites(id)
	for frame in frames:
		var i = 0
		sprite_frames.set_frame('default', i, frame)
		i+=1
	self.animated_sprite.set_animation('default')
	self.animated_sprite.set_sprite_frames(sprite_frames)
	self.set_global_position(position)
	if effect_lifetime >= 0:
		var runtime = self.animated_sprite.get_sprite_frames().get_frame_count('default') / self.animated_sprite.get_sprite_frames().get_animation_speed('default')
		$lifetimer.set_wait_time(runtime)
		$lifetimer.start()

func _on_lifetimer_timeout():
	call_deferred('free')
