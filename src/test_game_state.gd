## Test script to verify GameState autoload is accessible and functional.
## Run this scene to confirm autoload registration works.
extends Node


func _ready() -> void:
	print("=== GameState Autoload Test ===")
	
	# Test 1: Check autoload exists
	if GameState == null:
		push_error("FAIL: GameState autoload is null")
		return
	print("PASS: GameState autoload exists")
	
	# Test 2: Check initial state
	print("  campaign_phase: ", GameState.campaign_phase)
	print("  current_location: '", GameState.current_location, "'")
	print("  session_active: ", GameState.session_active)
	
	# Test 3: Connect to signals
	GameState.session_started.connect(_on_session_started)
	GameState.session_ended.connect(_on_session_ended)
	GameState.location_changed.connect(_on_location_changed)
	print("PASS: Signal connections established")
	
	# Test 4: Test session lifecycle
	print("--- Testing session lifecycle ---")
	GameState.start_session()
	print("  session_active after start: ", GameState.session_active)
	
	# Test 5: Test location change
	GameState.change_location("test_location_1")
	print("  current_location: ", GameState.current_location)
	
	GameState.change_location("test_location_2")
	print("  current_location: ", GameState.current_location)
	
	# Test 6: End session
	GameState.end_session()
	print("  session_active after end: ", GameState.session_active)
	
	print("=== All Tests Complete ===")
	
	# Auto-quit after 2 seconds to not leave the game running
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()


func _on_session_started() -> void:
	print("  [SIGNAL] session_started emitted")


func _on_session_ended() -> void:
	print("  [SIGNAL] session_ended emitted")


func _on_location_changed(new_location: String) -> void:
	print("  [SIGNAL] location_changed emitted: ", new_location)
