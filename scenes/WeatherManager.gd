extends "res://classes/game_manager.gd"

@export var game: Node
@export var cloud_shadows: ColorRect

var current_weather: String
var current_temperature: int
var current_time: int
var is_random_weather: bool
var is_day_night_cycle_active: bool
var random_weather_options: Array = []
var max_temp: int
var min_temp: int

var shader_parameters: Dictionary = {
	"sunny": {"cloud_threshold": 0.693, "cloud_softness": 1.0, "shadow_darkness": 0.2},
	"cloudy": {"cloud_threshold": 0.6, "cloud_softness": 0.5, "shadow_darkness": 0.25},
	"overcast": {"cloud_threshold": 0.4, "cloud_softness": 0.5, "shadow_darkness": 0.3}
}

### This Manager class manages the weather effects both visually in the game as well as any modifiers that weather effects may have.
# It gets its information from the themes scenarios.json, where weather is defined.

func _ready():
	# Keep empty - initialization happens via initialize() method
	pass

func _initialize_internal() -> Variant:
	# WeatherManager has no dependencies on other managers
	# But it can optionally wait for ThemeManager to be ready if game references it
	if game != null and is_instance_valid(game):
		if game.themeMgr != null and is_instance_valid(game.themeMgr):
			_debug_log("_initialize_internal(): Awaiting themeMgr initialization for weather data")
			await game.themeMgr.initialize()
	_debug_log("_initialize_internal(): WeatherManager ready")
	cloud_shadows.set_custom_minimum_size(game.get_map_size())
	return true

# This method is called every turn by the GameManager. It updates the weather effects 
# and temperature based on the current weather and time of day. If random weather is enabled, 
# it will also change the weather randomly each turn. If the day-night cycle is active, it will 
# also change the time of day each turn.
func process_turn():
	if is_random_weather:
		change_weather()
	if is_day_night_cycle_active:
		change_time_of_day()
	update_weather_effects()
	set_temperature()

# Public method to initialize the weather system with the information from the scenario file.
# It is called by the ThemeMgr when the scenario is loaded.
func init_weather_system(weather_information):
	is_random_weather = bool(weather_information["random_weather"].size() > 0)
	is_day_night_cycle_active = weather_information["day_night_cycle"]
	current_time = weather_information["time_of_day"]
	current_weather = weather_information["weather"]
	random_weather_options = weather_information["random_weather"]
	max_temp = weather_information["max_temp"]
	min_temp = weather_information["min_temp"]
	update_weather_effects()
	set_temperature()

# This method updates the shader parameters for the cloud shadows based on the current weather. It is called every turn to 
# ensure that the visual effects are consistent with the current weather conditions.
func update_weather_effects():
	cloud_shadows.get_material().set_shader_parameter("cloud_threshold", shader_parameters[current_weather]["cloud_threshold"])
	cloud_shadows.get_material().set_shader_parameter("cloud_softness", shader_parameters[current_weather]["cloud_softness"])
	cloud_shadows.get_material().set_shader_parameter("shadow_darkness", shader_parameters[current_weather]["shadow_darkness"])

# Public setter to change the weather. It can be called by other classes to change the weather conditions, 
# or it can be called internally if random weather is enabled.
func change_weather(new_weather: String = ""):
	if new_weather:
		current_weather = new_weather
	if is_random_weather:
		var random_value = randf()
		var cumulative_probability = 0.0
		for weather_option in random_weather_options:
			for weather_type in weather_option.keys():
				cumulative_probability += weather_option[weather_type]
				if random_value < cumulative_probability:
					current_weather = weather_type
					break
		
# Public setter to change the time of day. It can be called by other classes to change the time of day,
# or it can be called internally if the day-night cycle is active.
func change_time_of_day(new_time: int = -1):
	if new_time && new_time >= 0 && new_time < 24:
		current_time = new_time
	if is_day_night_cycle_active:
		current_time = (current_time + 1) % 24

func set_temperature(new_temperature: int = -1):
	if new_temperature >= 0:
		current_temperature = new_temperature
	else:
		# This method should calculate the temperature based on the current time. It is assumed that during noon the max temperature is reached, and during midnight the min temperature is reached. 
		# The temperature should change gradually throughout the day, following a sine wave pattern. The max and min temperatures are defined in the scenario file.
		var time_factor = (current_time - 12) / 12.0 # Normalize time to range [-1, 1]
		var temperature_range = max_temp - min_temp
		new_temperature = min_temp + (temperature_range / 2) * (1 + sin(time_factor * PI)) # Sine wave pattern for temperature change
		current_temperature = new_temperature

func get_current_weather() -> String:
	return current_weather

func get_current_time() -> int:
	return current_time

func get_current_temperature() -> int:
	return current_temperature
