extends SceneTree

var _failures: Array[String] = []


func _init() -> void:
	_run_checks()


func _run_checks() -> void:
	_check_project_setting("application/config/name", "OffTheRails")
	_check_project_setting("application/run/main_scene", "res://src/main.tscn")
	_check_project_setting("physics/3d/physics_engine", "Jolt Physics")
	_check_features()
	_check_autoload("EventHooks", "*res://src/scripting/event_hooks.gd")
	_check_autoload("GDAIMCPRuntime", "*uid://dcne7ryelpxmn")
	_check_autoload("GameState", "*res://src/autoloads/game_state.gd")
	_check_autoload("ModLoader", "*res://src/mod_system/mod_loader.gd")
	_check_setting_absent("dotnet/project/assembly_name")
	_check_resource_exists("res://src/main.tscn")
	_check_resource_exists("res://src/main.gd")
	_check_resource_exists("res://src/autoloads/game_state.gd")
	_check_resource_exists("res://src/mod_system/mod_loader.gd")
	_check_resource_exists("res://src/scripting/event_hooks.gd")
	_check_file_exists("res://addons/gdai-mcp-plugin-godot/plugin.cfg")
	_finish()


func _check_project_setting(name: String, expected: Variant) -> void:
	var actual: Variant = ProjectSettings.get_setting(name, null)
	if actual != expected:
		_fail("%s expected %s but got %s" % [name, str(expected), str(actual)])


func _check_setting_absent(name: String) -> void:
	if ProjectSettings.has_setting(name):
		_fail("%s should be absent" % name)


func _check_features() -> void:
	var features: PackedStringArray = ProjectSettings.get_setting(
		"application/config/features",
		PackedStringArray()
	)
	for feature in ["4.6", "Forward Plus"]:
		if not features.has(feature):
			_fail("application/config/features missing %s" % feature)


func _check_autoload(name: String, expected: String) -> void:
	_check_project_setting("autoload/%s" % name, expected)


func _check_resource_exists(path: String) -> void:
	if not ResourceLoader.exists(path):
		_fail("Missing resource: %s" % path)


func _check_file_exists(path: String) -> void:
	if not FileAccess.file_exists(path):
		_fail("Missing file: %s" % path)


func _fail(message: String) -> void:
	_failures.append(message)


func _finish() -> void:
	if not _failures.is_empty():
		for failure in _failures:
			push_error("[GodotCheck] %s" % failure)
		quit(1)
		return

	print("[GodotCheck] Project settings and required resources are valid.")
	quit(0)
