class_name ModErrorHandler
extends Node

## Handles mod loading errors gracefully — logs, emits signals, never crashes
##
## Design principle: NEVER crash on error — always log and continue.
## All errors are captured and made available for inspection while allowing
## the game to continue running with whatever mods loaded successfully.

signal error_occurred(error: ModError)
signal warning_occurred(warning: ModWarning)

enum ErrorType {
	MANIFEST_NOT_FOUND,
	MANIFEST_PARSE_FAILED,
	MANIFEST_INVALID,
	DEPENDENCY_MISSING,
	CONTENT_LOAD_FAILED,
	SCRIPT_LOAD_FAILED,
	SCRIPT_INVALID,
	SCRIPT_EXECUTION_ERROR,
}

enum WarningType {
	DEPRECATED_FIELD,
	OPTIONAL_DEPENDENCY_MISSING,
	CONTENT_OVERRIDE,
}

var _errors: Array[ModError] = []
var _warnings: Array[ModWarning] = []


## Create and log an error, emit signal, return error object.
## Never throws or crashes.
func handle_error(mod_id: String, error_type: ErrorType, message: String, details: Dictionary = {}) -> ModError:
	var error := ModError.new()
	error.mod_id = mod_id
	error.error_type = error_type
	error.message = message
	error.details = details
	error.timestamp = Time.get_unix_time_from_system()

	_errors.append(error)

	var type_name := _get_error_type_name(error_type)
	push_error("[ModLoader] %s in '%s': %s" % [type_name, mod_id, message])

	if not details.is_empty():
		push_error("[ModLoader] Details: %s" % str(details))

	error_occurred.emit(error)
	return error


## Create and log a warning, emit signal, return warning object.
func handle_warning(mod_id: String, warning_type: WarningType, message: String) -> ModWarning:
	var warning := ModWarning.new()
	warning.mod_id = mod_id
	warning.warning_type = warning_type
	warning.message = message
	warning.timestamp = Time.get_unix_time_from_system()

	_warnings.append(warning)

	var type_name := _get_warning_type_name(warning_type)
	push_warning("[ModLoader] %s in '%s': %s" % [type_name, mod_id, message])

	warning_occurred.emit(warning)
	return warning


## Return all errors for a specific mod.
func get_errors_for_mod(mod_id: String) -> Array[ModError]:
	var result: Array[ModError] = []
	for error in _errors:
		if error.mod_id == mod_id:
			result.append(error)
	return result


## Return all warnings for a specific mod.
func get_warnings_for_mod(mod_id: String) -> Array[ModWarning]:
	var result: Array[ModWarning] = []
	for warning in _warnings:
		if warning.mod_id == mod_id:
			result.append(warning)
	return result


## Return all errors.
func get_all_errors() -> Array[ModError]:
	return _errors.duplicate()


## Return all warnings.
func get_all_warnings() -> Array[ModWarning]:
	return _warnings.duplicate()


## Check if a mod has any errors.
func mod_has_errors(mod_id: String) -> bool:
	for error in _errors:
		if error.mod_id == mod_id:
			return true
	return false


## Clear all errors and warnings (useful for reloading).
func clear() -> void:
	_errors.clear()
	_warnings.clear()


func _get_error_type_name(error_type: ErrorType) -> String:
	match error_type:
		ErrorType.MANIFEST_NOT_FOUND:
			return "MANIFEST_NOT_FOUND"
		ErrorType.MANIFEST_PARSE_FAILED:
			return "MANIFEST_PARSE_FAILED"
		ErrorType.MANIFEST_INVALID:
			return "MANIFEST_INVALID"
		ErrorType.DEPENDENCY_MISSING:
			return "DEPENDENCY_MISSING"
		ErrorType.CONTENT_LOAD_FAILED:
			return "CONTENT_LOAD_FAILED"
		ErrorType.SCRIPT_LOAD_FAILED:
			return "SCRIPT_LOAD_FAILED"
		ErrorType.SCRIPT_INVALID:
			return "SCRIPT_INVALID"
		ErrorType.SCRIPT_EXECUTION_ERROR:
			return "SCRIPT_EXECUTION_ERROR"
		_:
			return "UNKNOWN_ERROR"


func _get_warning_type_name(warning_type: WarningType) -> String:
	match warning_type:
		WarningType.DEPRECATED_FIELD:
			return "DEPRECATED_FIELD"
		WarningType.OPTIONAL_DEPENDENCY_MISSING:
			return "OPTIONAL_DEPENDENCY_MISSING"
		WarningType.CONTENT_OVERRIDE:
			return "CONTENT_OVERRIDE"
		_:
			return "UNKNOWN_WARNING"


## Error data container.
class ModError:
	extends RefCounted

	var mod_id: String = ""
	var error_type: ErrorType = ErrorType.MANIFEST_NOT_FOUND
	var message: String = ""
	var details: Dictionary = {}
	var timestamp: float = 0.0

	func _to_string() -> String:
		return "[ModError] %s: %s" % [mod_id, message]


## Warning data container.
class ModWarning:
	extends RefCounted

	var mod_id: String = ""
	var warning_type: WarningType = WarningType.DEPRECATED_FIELD
	var message: String = ""
	var timestamp: float = 0.0

	func _to_string() -> String:
		return "[ModWarning] %s: %s" % [mod_id, message]
