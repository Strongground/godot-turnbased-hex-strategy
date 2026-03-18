extends Control

@onready var hexmap = $"/root/Game/MapZones"
@onready var game = $"/root/Game"
@export var tile_info: RichTextLabel = null
@export var move_button: TextureButton = null
@export var attack_button: TextureButton = null
@export var supply_button: TextureButton = null

var camera = null
var root = null
var tile_info_popup = null
var tile_info_popup_text = null
var panel = null
var unit_info = null
var shown_unit_name = null
var unit_info_strength = null
var unit_info_actionpoints = null
var unit_info_ammo = null
var panel_pos = null
var panel_size = null
var panel_area = null

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
	camera = root.find_child('MainCamera', true, false)
	tile_info_popup = root.find_child('Tile_Info', true, false)
	tile_info_popup_text = tile_info_popup.find_child('Tile_Text', true, false)
	shown_unit_name = root.find_child('UnitName', true, false)
	unit_info_strength = root.find_child('UnitStrength', true, false)
	unit_info_actionpoints = root.find_child('UnitActionPoints', true, false)
	unit_info_ammo = root.find_child('UnitAmmo', true, false)
	##### Panel
	panel = find_child('Panel', true, false)
	panel_pos = panel.position
	panel_size = panel.size
	if tile_info_popup != null and not tile_info_popup.has_method("popup"):
		tile_info_popup.visible = false
	if $UnitInfo != null and not $UnitInfo.has_method("popup"):
		$UnitInfo.visible = false

# Handle input that was not handled yet, but was intended for GUI.
# Currently just stops event from propagating.
func _unhandled_input(_event):
	# if Input.is_action_just_pressed("mouse_click"):
	# 	print('Mouse click in GUI')
	# accept_event()
	### This approach no longer works, since the GUI is viewport sized and will intercept all clicks.
	pass

# Show a popup window with information about the selected tile
# @input {Object} the tile object which information should be shown
func _show_tile_info_popup(tile_object) -> void:
	var popup_pos = camera.get_screen_center()
	tile_info_popup.set_position(popup_pos)
	tile_info_popup_text.set_text(str(tile_object))
	if tile_info_popup.has_method("popup"):
		tile_info_popup.popup()
	else:
		tile_info_popup.visible = true

# Public helper method to update units infos in gui panel
func update_unit_info(unit_name, strength, actionpoints, ammo) -> void:
	update_unit_name(unit_name)
	update_unit_strength(strength)
	update_unit_actionpoints(actionpoints)
	update_unit_ammo(ammo)

# Public setter for unit name in GUI
func update_unit_name(value) -> void:
	shown_unit_name.text = str(value)

# Public setter for unit strength indicator in GUI
func update_unit_strength(value) -> void:
	unit_info_strength.text = str(value)

# Public setter for unit action points indicator in GUI
func update_unit_actionpoints(value) -> void:
	unit_info_actionpoints.text = str(value)

# Public setter for unit ammo indicator in GUI
func update_unit_ammo(value) -> void:
	unit_info_ammo.text = str(value)

func update_tile_info(tile) -> void:
	tile_info.text = str(tile.name)

func _physics_process(_delta) -> void:
	var popup_pos = camera.get_screen_center()
	tile_info_popup.set_position(popup_pos)

# If MoveButton in GUI pressed, and a unit is selected,
# set movement selection
func _on_MoveButton_pressed() -> void:
	if root.selected_unit != null:
		root.movement_selection = true

# If AttackButton in GUI pressed, and a unit is selected,
# set attack selection
func _on_AttackButton_pressed() -> void:
	if root.selected_unit != null:
		root.attack_selection = true

# If SupplyButton in GUI pressed, and a capable unit is selected,
# set resupply selection
func _on_SupplyButton_pressed() -> void:
	if root.selected_unit != null:
		root.resupply_selection = true

func _on_UnitInfoButton_pressed() -> void:
	if $"/root/Game".selected_unit != null:
		var selected_unit_id = $"/root/Game".selected_unit
		var selected_unit = $"/root/Game"._get_entity_by_id(selected_unit_id).node
		var popup_pos = selected_unit.get_global_transform().get_origin()
		var movement_points = str(selected_unit.get_movement_points())
		$UnitInfo.set_position(popup_pos)
		$UnitInfo/UnitInfoText.set_text("Movement Points: " + movement_points)
		if $UnitInfo.has_method("popup"):
			$UnitInfo.popup()
		else:
			$UnitInfo.visible = true
	else:
		print("ERROR: No unit selected.")

func _on_toggle_grid_button_pressed() -> void:
	pass # Replace with function body.

func _on_end_turn_button_pressed() -> void:
	pass # Replace with function body.
