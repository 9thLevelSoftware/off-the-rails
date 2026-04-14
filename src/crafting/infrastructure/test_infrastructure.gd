extends Node

## Test script for Phase 06-02 Infrastructure & Scheduling.
## Run this scene to verify all components work correctly.
## Uses global class_name references which are registered when running within Godot project.

var _tests_passed: int = 0
var _tests_failed: int = 0


func _ready() -> void:
	print("\n========================================")
	print("Phase 06-02: Infrastructure Tests")
	print("========================================\n")

	_test_game_state_inventory()
	_test_crafting_event_bus()
	_test_inventory_repository()
	_test_job_scheduler()
	_test_expedition_pause_handler()

	print("\n========================================")
	print("Results: %d passed, %d failed" % [_tests_passed, _tests_failed])
	print("========================================\n")

	if _tests_failed == 0:
		print("All tests PASSED!")
	else:
		print("Some tests FAILED!")

	# Auto-quit after tests
	await get_tree().create_timer(0.5).timeout
	get_tree().quit(0 if _tests_failed == 0 else 1)


func _assert(condition: bool, message: String) -> void:
	if condition:
		_tests_passed += 1
		print("  PASS: %s" % message)
	else:
		_tests_failed += 1
		print("  FAIL: %s" % message)


func _test_game_state_inventory() -> void:
	print("\n--- GameState Inventory Tests ---")

	# Reset inventory
	GameState.debug_set_inventory({})

	# Test add_to_inventory
	var new_qty := GameState.add_to_inventory("iron", 10)
	_assert(new_qty == 10, "add_to_inventory returns new quantity")
	_assert(GameState.get_inventory_quantity("iron") == 10, "get_inventory_quantity works")

	# Test has_inventory_quantity
	_assert(GameState.has_inventory_quantity("iron", 5), "has_inventory_quantity true for smaller amount")
	_assert(GameState.has_inventory_quantity("iron", 10), "has_inventory_quantity true for exact amount")
	_assert(not GameState.has_inventory_quantity("iron", 15), "has_inventory_quantity false for larger amount")

	# Test remove_from_inventory
	_assert(GameState.remove_from_inventory("iron", 3), "remove_from_inventory succeeds with enough")
	_assert(GameState.get_inventory_quantity("iron") == 7, "remove_from_inventory reduces quantity")
	_assert(not GameState.remove_from_inventory("iron", 10), "remove_from_inventory fails with not enough")
	_assert(GameState.get_inventory_quantity("iron") == 7, "failed remove doesn't change quantity")

	# Test has_all_inventory
	GameState.add_to_inventory("copper", 5)
	_assert(GameState.has_all_inventory({"iron": 5, "copper": 3}), "has_all_inventory true when have all")
	_assert(not GameState.has_all_inventory({"iron": 5, "gold": 1}), "has_all_inventory false when missing one")

	# Test consume_inventory
	_assert(GameState.consume_inventory({"iron": 2, "copper": 2}), "consume_inventory succeeds")
	_assert(GameState.get_inventory_quantity("iron") == 5, "consume reduces iron")
	_assert(GameState.get_inventory_quantity("copper") == 3, "consume reduces copper")
	_assert(not GameState.consume_inventory({"iron": 100}), "consume_inventory fails atomically")
	_assert(GameState.get_inventory_quantity("iron") == 5, "failed consume doesn't change inventory")

	# Test add_all_inventory
	GameState.add_all_inventory({"iron": 5, "gold": 10})
	_assert(GameState.get_inventory_quantity("iron") == 10, "add_all adds to existing")
	_assert(GameState.get_inventory_quantity("gold") == 10, "add_all creates new")

	# Clean up
	GameState.debug_set_inventory({})


func _test_crafting_event_bus() -> void:
	print("\n--- CraftingEventBus Tests ---")

	var bus := CraftingEventBus.get_instance()
	var bus2 := CraftingEventBus.get_instance()
	_assert(bus == bus2, "get_instance returns same instance (singleton)")

	# Test signal emission (simple smoke test)
	var pause_received := [false]
	var pause_reason_received := [""]

	var callback := func(reason: String) -> void:
		pause_received[0] = true
		pause_reason_received[0] = reason

	bus.queue_paused.connect(callback)
	bus.emit_queue_paused("test_reason")

	_assert(pause_received[0], "queue_paused signal received")
	_assert(pause_reason_received[0] == "test_reason", "queue_paused passes reason")

	bus.queue_paused.disconnect(callback)

	var resume_received := [false]
	var resume_callback := func() -> void:
		resume_received[0] = true

	bus.queue_resumed.connect(resume_callback)
	bus.emit_queue_resumed()
	_assert(resume_received[0], "queue_resumed signal received")
	bus.queue_resumed.disconnect(resume_callback)


func _test_inventory_repository() -> void:
	print("\n--- InventoryRepository Tests ---")

	# Reset inventory
	GameState.debug_set_inventory({"scrap": 20, "fuel": 10})

	var repo := InventoryRepository.new()

	_assert(repo.has_resource("scrap", 15), "has_resource true for available")
	_assert(not repo.has_resource("scrap", 25), "has_resource false for unavailable")
	_assert(repo.get_resource_quantity("scrap") == 20, "get_resource_quantity returns correct value")

	_assert(repo.has_all_resources({"scrap": 10, "fuel": 5}), "has_all_resources true")
	_assert(not repo.has_all_resources({"scrap": 10, "gems": 5}), "has_all_resources false for missing")

	_assert(repo.consume_resources({"scrap": 5, "fuel": 3}), "consume_resources succeeds")
	_assert(repo.get_resource_quantity("scrap") == 15, "consume reduces scrap")
	_assert(repo.get_resource_quantity("fuel") == 7, "consume reduces fuel")

	repo.add_resources({"scrap": 5, "gems": 10})
	_assert(repo.get_resource_quantity("scrap") == 20, "add_resources adds to existing")
	_assert(repo.get_resource_quantity("gems") == 10, "add_resources creates new")

	var all := repo.get_all_resources()
	_assert("scrap" in all and "fuel" in all and "gems" in all, "get_all_resources returns all items")

	# Clean up
	GameState.debug_set_inventory({})


func _test_job_scheduler() -> void:
	print("\n--- JobScheduler Tests ---")

	# Set up test recipe
	var recipe := RecipeData.new()
	recipe.id = "test_bandage"
	recipe.name = "Test Bandage"
	recipe.inputs = {"cloth": 2}
	recipe.output = {"bandage": 1}
	recipe.craft_time = 10
	recipe.station = "field"

	# Set up inventory
	GameState.debug_set_inventory({"cloth": 10})

	# Create scheduler
	# Note: RecipeValidator only has static methods, so we pass null (not used directly)
	var queue := CraftQueue.new(3)
	var inventory := InventoryRepository.new()
	var scheduler := JobScheduler.new(queue, null, inventory)

	# Test enqueue
	var result := scheduler.enqueue_recipe(recipe, "engineer")
	_assert(result.success, "enqueue_recipe succeeds with resources")
	_assert(result.data != null, "enqueue_recipe returns job")
	_assert(GameState.get_inventory_quantity("cloth") == 8, "enqueue consumes inputs")

	# Test queue state
	_assert(queue.get_job_count() == 1, "queue has 1 job")
	_assert(queue.get_active_job() != null, "queue has active job")

	# Test tick progression
	scheduler.tick(5.0)
	var active := queue.get_active_job()
	_assert(active != null and active.elapsed_time == 5.0, "tick advances job time")

	# Test completion
	scheduler.tick(6.0)  # Should complete at 10.0 seconds
	_assert(queue.is_empty(), "job removed from queue after completion")
	_assert(GameState.get_inventory_quantity("bandage") == 1, "completion adds outputs to inventory")

	# Test enqueue when paused
	GameState.debug_set_inventory({"cloth": 10})
	scheduler.pause("test")
	var paused_result := scheduler.enqueue_recipe(recipe)
	_assert(not paused_result.success, "enqueue fails when paused")
	_assert("paused" in paused_result.error.to_lower(), "error mentions paused")

	scheduler.resume()

	# Test cancel with refund
	var cancel_result := scheduler.enqueue_recipe(recipe)
	_assert(cancel_result.success, "enqueue after resume succeeds")
	var cloth_before := GameState.get_inventory_quantity("cloth")

	var job_to_cancel: CraftJob = cancel_result.data
	var cancel := scheduler.cancel_job(job_to_cancel.job_id)
	_assert(cancel.success, "cancel_job succeeds")

	# 50% refund of 2 cloth = 1 cloth
	var cloth_after := GameState.get_inventory_quantity("cloth")
	_assert(cloth_after == cloth_before + 1, "cancel refunds 50%% of inputs")

	# Clean up
	GameState.debug_set_inventory({})


func _test_expedition_pause_handler() -> void:
	print("\n--- ExpeditionPauseHandler Tests ---")

	# Create scheduler
	# Note: RecipeValidator only has static methods, so we pass null (not used directly)
	var queue := CraftQueue.new(3)
	var inventory := InventoryRepository.new()
	var scheduler := JobScheduler.new(queue, null, inventory)

	var handler := ExpeditionPauseHandler.new(scheduler)

	# Test manual pause/resume
	handler.pause_for_expedition()
	_assert(scheduler.is_paused(), "pause_for_expedition pauses scheduler")
	_assert(handler.is_paused_for_expedition(), "is_paused_for_expedition true")

	handler.resume_from_expedition()
	_assert(not scheduler.is_paused(), "resume_from_expedition resumes scheduler")
	_assert(not handler.is_paused_for_expedition(), "is_paused_for_expedition false after resume")

	# Test signal connection
	handler.connect_signals()
	_assert(GameState.scene_transition_completed.is_connected(handler._on_scene_transition_completed),
		"connect_signals connects to GameState signal")

	# Test disconnect
	handler.disconnect_signals()
	_assert(not GameState.scene_transition_completed.is_connected(handler._on_scene_transition_completed),
		"disconnect_signals disconnects from GameState signal")

	print("  (Note: Scene transition signal tests require running game)")
