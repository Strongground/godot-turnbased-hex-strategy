extends Node
class_name GameManager

"""
Base class for all manager classes in the game.

Provides async initialization pattern to handle cross-manager dependencies
without timing/race conditions. Managers should override _initialize_internal()
to perform their setup logic.

Usage pattern:
1. Export manager nodes in scene (no change from current approach)
2. Call await manager.initialize() in dependency order
3. Manager will automatically await dependencies before running _initialize_internal()

Initialization order (based on dependencies):
1. SettingsManager (no dependencies)
2. ThemeManager (no dependencies)  
3. PlayerManager (depends on ThemeManager)
4. WeatherManager (no dependencies)
5. FactionManager (depends on ThemeManager)
6. SfxManager (depends on ThemeManager)
7. MusicManager (depends on SettingsManager, ThemeManager)
"""

signal initialized

@export var debug_logging = true

var _is_initialized: bool = false
var _initialization_started: bool = false
var _dependencies: Array = []

func _ready():
	# Don't do anything here - all initialization should be in _initialize_internal()
	pass

func _debug_log(message):
	if debug_logging:
		print("[Debug][Manager] %s: %s" % [get_name(), message])

"""
Initialize this manager and all its dependencies.

This is the main entry point for manager initialization. Call it with:
    await manager.initialize()

The method will:
1. Check if already initialized (return immediately if so)
2. Await all dependencies in order
3. Call _initialize_internal() for actual setup
4. Emit 'initialized' signal
5. Mark as initialized

@returns Future that completes when initialization is done
"""
func initialize() -> Variant:
	if _is_initialized:
		_debug_log("Already initialized, skipping")
		return true
	
	if _initialization_started:
		_debug_log("Initialization already in progress, awaiting completion")
		await initialized
		return true
	
	_initialization_started = true
	_debug_log("Starting initialization")
	
	# Await all dependencies first
	for dep in _dependencies:
		if dep != null and is_instance_valid(dep):
			_debug_log("Awaiting dependency: %s" % dep.get_name())
			await dep.initialize()
	
	# Now initialize this manager
	var result = await _initialize_internal()
	
	if result:
		_is_initialized = true
		_debug_log("Initialization complete")
		emit_signal("initialized")
	else:
		_debug_log("Initialization failed")
	
	return result

"""
Override this method to implement manager-specific initialization logic.

This is called AFTER all dependencies have been initialized.
Use await within this method for any async operations (file loading, etc.)

@returns bool indicating success
"""
func _initialize_internal() -> Variant:
	# Default implementation does nothing
	return true

"""
Add a dependency that must be initialized before this manager.

@param manager The manager node that this manager depends on
"""
func add_dependency(manager: Node) -> void:
	if manager != null and is_instance_valid(manager):
		if not _dependencies.has(manager):
			_dependencies.append(manager)
			_debug_log("Added dependency: %s" % manager.get_name())

"""
Check if this manager is fully initialized.

@returns true if initialize() has completed successfully
"""
func is_initialized() -> bool:
	return _is_initialized

"""
Get the list of dependencies for this manager.

@returns Array of manager nodes
"""
func get_dependencies() -> Array:
	return _dependencies.duplicate()
