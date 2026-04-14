## Test script to verify GameState autoload is accessible and functional.
## Run this scene to confirm autoload registration works.
## Extended with integration tests for isometric types, ContentRegistry, and signals.
extends Node


## Reset GameState to clean state for test isolation.
## Called at the start and end of each test that modifies state to ensure
## tests do not pollute each other, even if assertions fail mid-test.
func _cleanup_gamestate() -> void:
	# Clear inventory
	GameState.debug_set_inventory({})
	# End any active session
	if GameState.session_active:
		GameState.end_session()
	# Reset location
	GameState.current_location = ""


func _ready() -> void:
	print("\n=== GameState Integration Tests ===\n")

	# Test 1: Check autoload exists
	if GameState == null:
		push_error("FAIL: GameState autoload is null")
		return
	print("PASS: GameState autoload exists")

	# Clean starting state for all tests
	_cleanup_gamestate()

	# Run all test functions
	test_player_instance_type()
	test_content_registry_init()
	test_item_data_lookup()
	test_inventory_with_signals()
	test_session_signals()
	test_location_change()

	print("\n=== All Tests Complete ===\n")

	# Auto-quit after 2 seconds to not leave the game running
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()


# --- Test Functions ---

## Test 1: Verify player_spawned signal has CharacterBody2D type
func test_player_instance_type() -> void:
	print("--- Testing player type annotation ---")
	var signals := GameState.get_signal_list()
	var player_spawned_found := false
	for sig in signals:
		if sig["name"] == "player_spawned":
			player_spawned_found = true
			print("  player_spawned signal found")
			# Check the signal argument type
			var args: Array = sig.get("args", [])
			if not args.is_empty():
				var arg_info: Dictionary = args[0]
				print("  Signal arg name: '%s', class_name: '%s'" % [arg_info.get("name", ""), arg_info.get("class_name", "")])

	if player_spawned_found:
		print("PASS: player_spawned signal exists")
	else:
		push_error("FAIL: player_spawned signal missing")

	# Also verify player_instance is typed correctly (should be null initially)
	var instance = GameState.player_instance
	if instance == null:
		print("PASS: player_instance is null initially (correct)")
	elif instance is CharacterBody2D:
		print("PASS: player_instance is CharacterBody2D type")
	else:
		push_error("FAIL: player_instance has unexpected type: %s" % instance.get_class())


## Test 2: Verify ContentRegistry initialization
func test_content_registry_init() -> void:
	print("--- Testing ContentRegistry initialization ---")

	var registry := GameState.get_content_registry()
	if registry == null:
		push_error("FAIL: ContentRegistry is null")
		return
	print("PASS: ContentRegistry accessible via GameState")

	if registry.is_base_loaded():
		print("PASS: Base content loaded (%d total items)" % registry.get_total_count())
	else:
		print("WARN: Base content not loaded (may be empty data files)")

	# Verify registry has required sub-registries
	if registry.items != null:
		print("  Items registry: %d items" % registry.items.count())
	else:
		push_error("FAIL: Items registry is null")

	if registry.recipes != null:
		print("  Recipes registry: %d recipes" % registry.recipes.count())
	else:
		push_error("FAIL: Recipes registry is null")


## Test 3: Verify item data lookup works through GameState
func test_item_data_lookup() -> void:
	print("--- Testing item data lookup ---")

	var registry := GameState.get_content_registry()
	if registry == null:
		push_error("FAIL: Registry unavailable for item test")
		return

	# Get all items and test lookup with first one (if any exist)
	var all_items := registry.items.get_all()
	if all_items.is_empty():
		print("SKIP: No items in registry (expected if base_items.json empty)")
		return

	var test_item: ResourceItemData = all_items[0]
	var lookup_result := GameState.get_item_data(test_item.id)
	if lookup_result != null and lookup_result.id == test_item.id:
		print("PASS: Item lookup works - found '%s'" % test_item.id)
	else:
		push_error("FAIL: Item lookup returned wrong result")

	# Test invalid item lookup
	var invalid_result := GameState.get_item_data("definitely_not_a_real_item_id_12345")
	if invalid_result == null:
		print("PASS: Invalid item lookup correctly returns null")
	else:
		push_error("FAIL: Invalid item lookup should return null")


## Test 4: Verify inventory operations with signal verification
func test_inventory_with_signals() -> void:
	print("--- Testing inventory operations with signals ---")
	_cleanup_gamestate()  # Clean start for test isolation

	var signal_received := false
	var received_item_id := ""
	var received_old_qty := -1
	var received_new_qty := -1

	var callback := func(item_id: String, old_qty: int, new_qty: int):
		signal_received = true
		received_item_id = item_id
		received_old_qty = old_qty
		received_new_qty = new_qty

	GameState.inventory_changed.connect(callback)
	signal_received = false  # Reset after any cleanup signal

	# Test add
	var test_item := "test_signal_item"
	GameState.add_to_inventory(test_item, 5)

	if signal_received and received_item_id == test_item and received_old_qty == 0 and received_new_qty == 5:
		print("PASS: inventory_changed signal emitted correctly on add")
	else:
		push_error("FAIL: inventory_changed signal incorrect (received=%s, item=%s, old=%d, new=%d)" % [signal_received, received_item_id, received_old_qty, received_new_qty])

	# Test remove
	signal_received = false
	GameState.remove_from_inventory(test_item, 2)

	if signal_received and received_new_qty == 3:
		print("PASS: inventory_changed signal emitted correctly on remove")
	else:
		push_error("FAIL: inventory_changed signal incorrect on remove")

	# Verify final quantity
	var final_qty := GameState.get_inventory_quantity(test_item)
	if final_qty == 3:
		print("PASS: Final inventory quantity correct (%d)" % final_qty)
	else:
		push_error("FAIL: Final inventory quantity wrong (expected 3, got %d)" % final_qty)

	# Test has_inventory_quantity
	if GameState.has_inventory_quantity(test_item, 3):
		print("PASS: has_inventory_quantity(3) returns true")
	else:
		push_error("FAIL: has_inventory_quantity(3) should return true")

	if not GameState.has_inventory_quantity(test_item, 4):
		print("PASS: has_inventory_quantity(4) returns false")
	else:
		push_error("FAIL: has_inventory_quantity(4) should return false")

	GameState.inventory_changed.disconnect(callback)
	_cleanup_gamestate()  # Clean end for test isolation


## Test 5: Verify session signal propagation
func test_session_signals() -> void:
	print("--- Testing session signal propagation ---")
	_cleanup_gamestate()  # Clean start for test isolation

	var started_received := false
	var ended_received := false

	var on_started := func(): started_received = true
	var on_ended := func(): ended_received = true

	GameState.session_started.connect(on_started)
	GameState.session_ended.connect(on_ended)

	# Test start
	GameState.start_session()
	if started_received and GameState.session_active:
		print("PASS: session_started signal emitted, state updated")
	else:
		push_error("FAIL: session_started issue (received=%s, active=%s)" % [started_received, GameState.session_active])

	# Test end
	GameState.end_session()
	if ended_received and not GameState.session_active:
		print("PASS: session_ended signal emitted, state updated")
	else:
		push_error("FAIL: session_ended issue (received=%s, active=%s)" % [ended_received, GameState.session_active])

	GameState.session_started.disconnect(on_started)
	GameState.session_ended.disconnect(on_ended)
	_cleanup_gamestate()  # Clean end for test isolation


## Test 6: Verify location change signal
func test_location_change() -> void:
	print("--- Testing location change ---")
	_cleanup_gamestate()  # Clean start for test isolation

	var location_received := ""
	var callback := func(new_location: String): location_received = new_location

	GameState.location_changed.connect(callback)

	# Test location change
	GameState.change_location("test_location_A")
	if location_received == "test_location_A" and GameState.current_location == "test_location_A":
		print("PASS: location_changed signal emitted for test_location_A")
	else:
		push_error("FAIL: location_changed not working (received=%s, current=%s)" % [location_received, GameState.current_location])

	# Test that same location doesn't emit signal
	location_received = ""
	GameState.change_location("test_location_A")
	if location_received == "":
		print("PASS: Duplicate location change correctly skipped")
	else:
		push_error("FAIL: Duplicate location should not emit signal")

	# Test different location
	GameState.change_location("test_location_B")
	if location_received == "test_location_B":
		print("PASS: location_changed signal emitted for test_location_B")
	else:
		push_error("FAIL: location_changed not emitted for new location")

	GameState.location_changed.disconnect(callback)
	_cleanup_gamestate()  # Clean end for test isolation
