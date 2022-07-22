extends Container

var camera = null
var game = null
var root = null
var tile_info_popup = null
var tile_info_popup_text = null
var panel = null
var unit_info = null
var unit_name = null
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
func is_gui_clicked():
	var click_pos = get_viewport().get_mouse_position()
	var panel_pos_y = panel_pos.y
	var viewport_size_y = get_viewport().size.y
	var panel_top_border_begin = viewport_size_y - panel_pos_y
	var result = click_pos.y > panel_top_border_begin
	print('Click inside GUI: '+String(result))
	return result

# Public setter for disabled state of move button
# @input {Boolean} true for disabled, false for enabled
func disable_movement_button(disabled):
	$Panel/MoveButton.set_disabled(disabled)
	
# Public setter for disabled state of attack button
# @input {Boolean} true for disabled, false for enabled
func disable_attack_button(disabled):
	$Panel/AttackButton.set_disabled(disabled)

# Public setter for disabled state of supply button
# @input {Boolean} true for disabled, false for enabled
func disable_supply_button(disabled):
	$Panel/SupplyButton.set_disabled(disabled)

# Init
func _ready():
	set_process_input(true)
	root = get_tree().get_current_scene()
	camera = root.find_node('MainCamera')
	tile_info_popup = root.find_node('Tile_Info')
	tile_info_popup_text = tile_info_popup.find_node('Tile_Text')
	unit_name = root.find_node('UnitName')
	unit_info_strength = root.find_node('UnitStrength')
	unit_info_actionpoints = root.find_node('UnitActionPoints')
	unit_info_ammo = root.find_node('UnitAmmo')
	##### Panel
	panel = find_node('Panel')
	panel_pos = self.panel.rect_position
	panel_size = self.panel.get_size()

# Handle input that was not handled yet, but was intended for GUI.
# Currently just stops event from propagating.
func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
		print('Mouse click in GUI')
	accept_event()

# Show a popup window with information about the selected tile
# @input {Object} the tile object which information should be shown
func _show_tile_info_popup(tile_object):
	var popup_pos = camera.get_screen_center()
	# popup_pos = Vector2(
	# 	popup_pos.x - self.get_size().x,
	# 	popup_pos.y - self.get_size().y
	# )
	tile_info_popup.set_position(popup_pos)
	tile_info_popup_text.set_text(String(tile_object))
	tile_info_popup.popup()

# Public helper method to update units infos in gui panel
func update_unit_info(name, strength, actionpoints, ammo):
	update_unit_name(name)
	update_unit_strength(strength)
	update_unit_actionpoints(actionpoints)
	update_unit_ammo(ammo)

# Public setter for unit name in GUI
func update_unit_name(value):
	unit_name.set_bbcode(String(value))

# Public setter for unit strength indicator in GUI
func update_unit_strength(value):
	unit_info_strength.set_bbcode(String(value))

# Public setter for unit action points indicator in GUI
func update_unit_actionpoints(value):
	unit_info_actionpoints.set_bbcode(String(value))

# Public setter for unit ammo indicator in GUI
func update_unit_ammo(value):
	unit_info_ammo.set_bbcode(String(value))

func _physics_process(delta):
	var popup_pos = camera.get_camera_screen_center()
	tile_info_popup.set_position(popup_pos)

# If MoveButton in GUI pressed, and a unit is selected,
# set movement selection
func _on_MoveButton_pressed():
	if root.selected_unit != null:
		root.movement_selection = true

# If AttackButton in GUI pressed, and a unit is selected,
# set attack selection
func _on_AttackButton_pressed():
	if root.selected_unit != null:
		root.attack_selection = true

# If SupplyButton in GUI pressed, and a capable unit is selected,
# set resupply selection
func _on_SupplyButton_pressed():
	if root.selected_unit != null:
		root.resupply_selection = true

func _on_UnitInfoButton_pressed():
	if $"/root/Game".selected_unit != null:
		var selected_unit_id = $"/root/Game".selected_unit
		var selected_unit = $"/root/Game"._get_entity_by_id(selected_unit_id).node
		var popup_pos = selected_unit.get_global_transform().get_origin()
		var movement_points = str(selected_unit.get_movement_points())
		$UnitInfo.set_position(popup_pos)
		$UnitInfo/UnitInfoText.set_text("Movement Points: " + movement_points)
		$UnitInfo.popup()
	else:
		print("ERROR: No unit selected.")
