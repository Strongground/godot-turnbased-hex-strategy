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
export (bool) var key = true
export (bool) var drag = true
export (bool) var edge = false
export (bool) var wheel = true

export (float) var zoom_out_limit = 1
export (float) var zoom_in_limit = 0.5

# Camera speed in px/s.
export (int) var camera_speed = 450 

# Initial zoom value taken from Editor.
# @TODO Seems to have no effect
var camera_zoom = get_zoom()

# Value meaning how near to the window edge (in px) the mouse must be,
# to move a view.
export (int) var camera_margin = 50

# It changes a camera zoom value in units... (?, but it works... it probably
# multiplies camera size by 1+camera_zoom_speed)
const camera_zoom_speed = Vector2(0.0075, 0.0075)

# Vector of camera's movement / second.
var camera_movement = Vector2()

# Previous mouse position used to count delta of the mouse movement.
var _prev_mouse_pos = null

# Various internal variables used to calculate camera position against camera movement limits
var half_viewport_x = 0.0
var half_viewport_y = 0.0

var GUI = null
var GUI_zoomLabel = null
var GUI_position = null
var scale_factor = 1

# INPUTS

# Right mouse button was or is pressed.
var __rmbk = false
# Move camera by keys: left, top, right, bottom.
var __keys = [false, false, false, false]

func _ready():
	# This is the factor by which the viewport and all elements are upscaled on hidpi-screens,
	# use it as divider to get original coordinates. If no hidpi detected, it is set to 1,
	# which shold not affect anything, and thus can be used anyhwere
	if OS.get_screen_dpi() >= 240:
		scale_factor = 2
	set_h_drag_enabled(false)
	set_v_drag_enabled(false)
	set_enable_follow_smoothing(false)
	set_follow_smoothing(4)
	set_fixed_process(true)
	set_process_unhandled_input(true)
	GUI = find_node('GUI')
	GUI_zoomLabel = find_node('ZoomLevel')
	self._updateGUI()
	
func _updateGUI():
	# Set scale of GUI which happens to always be 0.5 more than camera_zoom level to look right
	# GUI.set_scale(camera_zoom + Vector2(0.5,0.5))
	# # Calc and set position of GUI from viewport height minus GUI heigth (with correct scale)
	# var viewport_size = get_viewport().get_rect().size
	# GUI_position = Vector2(
	# 	0,
	# 	(viewport_size.y / scale_factor) - (GUI.get_size().y * GUI.get_scale().y)
	# )
	# GUI.set_pos(GUI_position)
	# Debugging
	# print("GUI position is: "+String(GUI_position))
	pass

func _fixed_process(delta):
	half_viewport_x = get_viewport().get_rect().size.x / 2
	half_viewport_y = get_viewport().get_rect().size.y / 2
	
	# Move camera by keys defined in InputMap (ui_left/top/right/bottom).
	if key:
		# Left
		if __keys[0]:
			camera_movement.x -= camera_speed * delta
		# Top
		if __keys[1]:
			camera_movement.y -= camera_speed * delta
		# Right
		if __keys[2]:
			camera_movement.x += camera_speed * delta
		# Bottom
		if __keys[3]:
			camera_movement.y += camera_speed * delta
	
	# Move camera by mouse, when it's on the margin (defined by camera_margin).
	if edge:
		# Left
		if get_viewport().get_rect().size.x - get_viewport().get_mouse_pos().x <= camera_margin:
			camera_movement.x += camera_speed * delta
		# Top
		if get_viewport().get_mouse_pos().x <= camera_margin:
			camera_movement.x -= camera_speed * delta
		# Right
		if get_viewport().get_rect().size.y - get_viewport().get_mouse_pos().y <= camera_margin:
			camera_movement.y += camera_speed * delta
		# Bottom
		if get_viewport().get_mouse_pos().y <= camera_margin:
			camera_movement.y -= camera_speed * delta
	
	# When RMB is pressed, move camera by difference of mouse position
	if drag and __rmbk:
		camera_movement = _prev_mouse_pos - get_viewport().get_mouse_pos()
	
	# Update position of the camera if future position will be within camera limits
	var camera_new_left = get_pos().x + camera_movement.x - self.half_viewport_x
	var camera_new_right = get_pos().x + camera_movement.x + self.half_viewport_x
	var camera_new_top = get_pos().y + camera_movement.y - self.half_viewport_y
	var camera_new_bottom = get_pos().y + camera_movement.y + self.half_viewport_y
	
	if camera_new_left > self.get_limit(0) and camera_new_right < self.get_limit(2) and camera_new_top > self.get_limit(1) and camera_new_bottom < self.get_limit(3):
		self.set_pos(self.get_pos() + camera_movement * get_zoom())
	
	# Set camera movement to zero, update old mouse position.
	camera_movement = Vector2(0,0)
	_prev_mouse_pos = get_viewport().get_mouse_pos()

func _unhandled_input(event):
	if event.type == InputEvent.MOUSE_BUTTON:
		# Control by right mouse button.
		if event.is_pressed() and event.button_index==2 and drag:
			__rmbk = true
		else:
			__rmbk = false

		# Check if mouse wheel was used. Not handled by InputMap!
		if wheel:
			# Checking if future zoom won't be under 0 and zoom_in_limit.
			# In that case engine will flip screen.
			if event.button_index == BUTTON_WHEEL_UP and\
			zoom_in_limit > 0 and\
			camera_zoom.x - camera_zoom_speed.x > zoom_in_limit and\
			camera_zoom.y - camera_zoom_speed.y > zoom_in_limit:
				camera_zoom -= camera_zoom_speed
				GUI_zoomLabel.set_text(String(camera_zoom))
				set_zoom(camera_zoom)
				self._updateGUI()
			# Checking if future zoom won't be above zoom_out_limit.
			if event.button_index == BUTTON_WHEEL_DOWN and\
				camera_zoom.x + camera_zoom_speed.x < zoom_out_limit and\
				camera_zoom.y + camera_zoom_speed.y < zoom_out_limit:
				camera_zoom += camera_zoom_speed
				GUI_zoomLabel.set_text(String(camera_zoom))
				set_zoom(camera_zoom)
				self._updateGUI()
	# Control by keyboard handled by InputMap.
	if event.type == InputEvent.KEY and key:
		if event.is_action_pressed("ui_left"):
			__keys[0] = true
		if event.is_action_pressed("ui_up"):
			__keys[1] = true
		if event.is_action_pressed("ui_right"):
			__keys[2] = true
		if event.is_action_pressed("ui_down"):
			__keys[3] = true
		if event.is_action_released("ui_left"):
			__keys[0] = false
		if event.is_action_released("ui_up"):
			__keys[1] = false
		if event.is_action_released("ui_right"):
			__keys[2] = false
		if event.is_action_released("ui_down"):
			__keys[3] = false
