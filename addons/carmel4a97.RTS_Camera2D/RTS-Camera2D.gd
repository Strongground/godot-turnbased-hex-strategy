# Copyright 2017 Kamil Lewan <carmel4a97@gmail.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

extends Camera2D

# Camera control settings:
# key - by keyboard
# drag - by clicking mouse button, right mouse button by default;
# edge - by moving mouse to the window edge
# wheel - zoom in/out by mouse wheel
@export var key = true
@export var drag = true
@export var edge = false
@export var wheel = true

@export var zoom_out_limit = 1
@export var zoom_in_limit = 0.5

# Camera speed in px/s.
@export var camera_speed = 450 

# Initial zoom value taken from Editor.
# @TODO Seems to have no effect
var camera_zoom = scale

# Value meaning how near to the window edge (in px) the mouse must be,
# to move a view.
@export var camera_margin = 50

# It changes a camera zoom value in units... (?, but it works... it probably
# multiplies camera size by 1+camera_zoom_speed. But why so incredibly small number? Was 0.0075)
@export var public_camera_zoom_speed = 1.0
var camera_zoom_speed = Vector2(0.03, 0.03)

# Vector of camera's movement / second.
var camera_movement = Vector2()

# Previous mouse position used to count delta of the mouse movement.
var _prev_mouse_pos = null

var GUI = null
var game = null
var scale_factor = 1

func _ready():
	game = get_tree().current_scene
	limit_enabled = true
	set_drag_horizontal_enabled(false)
	set_drag_vertical_enabled(false)
	position_smoothing_enabled = false
	position_smoothing_speed = 4
	GUI = find_child('GUI', true, false)
	self._updateGUI()
	
func _updateGUI():
	# Set scale of GUI to camera_zoom level so it is visually the same scale
	if GUI != null:
		GUI.scale = camera_zoom * scale_factor

# Get centered position relative to screen size 
func get_screen_center():
	var camera_position = self.position
	var vp_center = Vector2(
		camera_position.x / scale_factor,
		camera_position.y / scale_factor
	)
	return vp_center

func _physics_process(delta):
	# Move camera by keys defined in InputMap (ui_left/up/right/down).
	# But only if navigation by keyboard (key) is enabled.
	
	if key:
		# Left
		if Input.is_action_pressed("ui_left"):
			camera_movement.x -= camera_speed * delta
		# Top
		if Input.is_action_pressed("ui_up"):
			camera_movement.y -= camera_speed * delta
		# Right
		if Input.is_action_pressed("ui_right"):
			camera_movement.x += camera_speed * delta
		# Bottom
		if Input.is_action_pressed("ui_down"):
			camera_movement.y += camera_speed * delta
	
	# Move camera by mouse, when it's on the margin (defined by camera_margin).
	if edge:
		var mouse_pos = get_viewport().get_mouse_position()
		var viewport_size = get_viewport().size
		# Left
		if mouse_pos.x <= camera_margin:
			camera_movement.x -= camera_speed * delta
		# Right
		if viewport_size.x - mouse_pos.x <= camera_margin:
			camera_movement.x += camera_speed * delta
		# Top
		if mouse_pos.y <= camera_margin:
			camera_movement.y -= camera_speed * delta
		# Bottom
		if viewport_size.y - mouse_pos.y <= camera_margin:
			camera_movement.y += camera_speed * delta
	
	# When RMB is pressed, move camera by difference of mouse position
	if drag and Input.is_action_pressed("mouse_right_click") and _prev_mouse_pos != null:
		camera_movement = (_prev_mouse_pos - get_viewport().get_mouse_position()) * Vector2(2 - camera_zoom.x, 2 - camera_zoom.y)

	# Zoom purely via action polling.
	if wheel:
		if Input.is_action_just_pressed("ui_zoom_in") and\
		zoom_in_limit > 0 and\
		camera_zoom.x - camera_zoom_speed.x > zoom_in_limit and\
		camera_zoom.y - camera_zoom_speed.y > zoom_in_limit:
			camera_zoom -= camera_zoom_speed
			zoom = camera_zoom
			self._updateGUI()
		if Input.is_action_just_pressed("ui_zoom_out") and\
			camera_zoom.x + camera_zoom_speed.x < zoom_out_limit and\
			camera_zoom.y + camera_zoom_speed.y < zoom_out_limit:
			camera_zoom += camera_zoom_speed
			zoom = camera_zoom
			self._updateGUI()
	
	# Camera2D handles clamping against limit_* when limit_enabled is true.
	position = position + camera_movement * zoom
	
	# Set camera movement to zero, update old mouse position.
	camera_movement = Vector2(0,0)
	_prev_mouse_pos = get_viewport().get_mouse_position()
