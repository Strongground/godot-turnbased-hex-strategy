extends Control

@export var hexmap: TileMapLayer
@export var game: Node
@export var move_button: TextureButton = null
@export var attack_button: TextureButton = null
@export var supply_button: TextureButton = null
@export var unit_info_popup: Node = null
@export var theme_mgr: Node = null
@export var shown_unit_name: Node = null
@export var unit_info_strength: Node = null
@export var unit_info_actionpoints: Node = null
@export var unit_info_ammo: Node = null
@export var panel: Node = null
@export var hexgrid_overlay: Node = null

var root = null
var unit_info = null
var panel_pos = null
var panel_size = null
var panel_area = null
var grid_visible = false

# Public helper function to check mouse local position against GUI elements
# @TODO enhance this for other GUI elements, currently only checking against
# the main menu bar/panel
# @returns {Boolean} true if the mouse position is over a GUI element 
func is_gui_clicked() -> bool:
	# var click_pos = get_viewport().get_mouse_position()
	# var panel_pos_y = panel_pos.y
	# var viewport_size_y = get_viewport().size.y
	# var panel_top_border_begin = viewport_size_y - panel_pos_y
	# var result = click_pos.y > panel_top_border_begin
	# print('Click inside GUI: '+str(result))
	# return result
	### Handle this differently, since the GUI is viewport sized and will intercept all clicks. 
	return false

# Public setter for disabled state of move button
# @input {Boolean} true for disabled, false for enabled
func disable_movement_button(disabled) -> void:
	move_button.set_disabled(disabled)
	
# Public setter for disabled state of attack button
# @input {Boolean} true for disabled, false for enabled
func disable_attack_button(disabled) -> void:
	attack_button.set_disabled(disabled)

# Public setter for disabled state of supply button
# @input {Boolean} true for disabled, false for enabled
func disable_supply_button(disabled) -> void:
	supply_button.set_disabled(disabled)

# Init
func _ready() -> void:
	set_process_input(true)
	root = get_tree().current_scene
	##### Panel
	panel_pos = panel.position
	panel_size = panel.size

# Handle input that was not handled yet, but was intended for GUI.
# Currently just stops event from propagating.
func _unhandled_input(_event):
	# if Input.is_action_just_pressed("mouse_click"):
	# 	print('Mouse click in GUI')
	# accept_event()
	### This approach no longer works, since the GUI is viewport sized and will intercept all clicks.
	pass

# Public helper method to update units infos in gui panel
func update_unit_info(unit_name, strength, actionpoints, ammo) -> void:
	update_unit_name(unit_name)
	update_unit_strength(strength)
	update_unit_actionpoints(actionpoints)
	update_unit_ammo(ammo)

# Public setter for unit name in GUI
func update_unit_name(value) -> void:
	if shown_unit_name != null and is_instance_valid(shown_unit_name):
		shown_unit_name.text = str(value)

# Public setter for unit strength indicator in GUI
func update_unit_strength(value) -> void:
	if unit_info_strength != null and is_instance_valid(unit_info_strength):
		unit_info_strength.text = str(value)

# Public setter for unit action points indicator in GUI
func update_unit_actionpoints(value) -> void:
	if unit_info_actionpoints != null and is_instance_valid(unit_info_actionpoints):
		unit_info_actionpoints.text = str(value)

# Public setter for unit ammo indicator in GUI
func update_unit_ammo(value) -> void:
	if unit_info_ammo != null and is_instance_valid(unit_info_ammo):
		unit_info_ammo.text = str(value)

func _physics_process(_delta) -> void:
	pass

# If MoveButton in GUI pressed, and a unit is selected,
# set movement selection
func _on_MoveButton_pressed() -> void:
	if root.selected_unit != null:
		if root.has_method("set_movement_selection_mode"):
			root.set_movement_selection_mode(true)
		else:
			root.movement_selection = true
			root.attack_selection = false
			root.resupply_selection = false

# If AttackButton in GUI pressed, and a unit is selected,
# set attack selection
func _on_AttackButton_pressed() -> void:
	if root.selected_unit != null:
		if root.has_method("set_attack_selection_mode"):
			root.set_attack_selection_mode(true)
		else:
			root.movement_selection = false
			root.attack_selection = true
			root.resupply_selection = false

# If SupplyButton in GUI pressed, and a capable unit is selected,
# set resupply selection
func _on_SupplyButton_pressed() -> void:
	if root.selected_unit != null:
		if root.has_method("set_resupply_selection_mode"):
			root.set_resupply_selection_mode(true)
		else:
			root.movement_selection = false
			root.attack_selection = false
			root.resupply_selection = true

# If the button is pressed, open a unit info popup showing the 
# selected unit's information.
func _on_UnitInfoButton_pressed() -> void:
	if game.get_selected_unit() != null:
		var selected_unit = game.get_selected_unit()
		if unit_info_popup != null and is_instance_valid(unit_info_popup):
			# var viewport_size = get_viewport_rect().size
			# var popup_size = unit_info_popup.size
			# var popup_pos = (viewport_size - popup_size) / 2.0
			# unit_info_popup.set_position(popup_pos)
			unit_info_popup.show_unit_info(selected_unit)
			unit_info_popup.visible = true
	else:
		print("ERROR: No unit selected.")

func _on_toggle_grid_button_pressed() -> void:
	var grid_opacity = 1.0
	var from_opacity = null
	var to_opacity = null
	if self.grid_visible:
		from_opacity = Color(1, 1, 1, grid_opacity)
		to_opacity = Color(1, 1, 1, 0)
		self.grid_visible = false
	else:
		from_opacity = Color(1, 1, 1, 0)
		to_opacity = Color(1, 1, 1, grid_opacity)
		self.grid_visible = true
	hexgrid_overlay.modulate = from_opacity
	var grid_tween = create_tween()
	grid_tween.set_trans(Tween.TRANS_LINEAR)
	grid_tween.set_ease(Tween.EASE_IN_OUT)
	grid_tween.tween_property(hexgrid_overlay, "modulate", to_opacity, 0.5)

func _on_end_turn_button_pressed() -> void:
	if game != null:
		game._end_turn()
