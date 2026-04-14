## Test script to verify crafting domain classes work correctly.
## Run this scene to verify CraftJob, CraftQueue, and RecipeValidator.
extends Node

var test_recipe: RecipeData
var tests_passed: int = 0
var tests_failed: int = 0


func _ready() -> void:
	print("=== Crafting Domain Test Suite ===")
	print("")

	# Create a mock recipe for testing
	test_recipe = _create_mock_recipe()

	# Run all tests
	_test_recipe_data()
	_test_craft_job()
	_test_craft_queue()
	_test_recipe_validator()

	print("")
	print("=== Test Results ===")
	print("  Passed: %d" % tests_passed)
	print("  Failed: %d" % tests_failed)
	print("")

	if tests_failed > 0:
		push_error("Some tests failed!")
	else:
		print("All tests passed!")

	# Auto-quit after 2 seconds
	await get_tree().create_timer(2.0).timeout
	get_tree().quit()


func _create_mock_recipe() -> RecipeData:
	var recipe := RecipeData.new()
	recipe.id = "test_recipe"
	recipe.name = "Test Recipe"
	recipe.category = "consumable"
	recipe.station = "workshop"
	recipe.inputs = {"scrap_metal": 3, "wiring": 2}
	recipe.output = {"test_item": 2}
	recipe.craft_time = 60
	recipe.unlock = "default"
	recipe.profession_bonus = "engineer"
	recipe.description = "A test recipe"
	return recipe


func _assert(condition: bool, message: String) -> void:
	if condition:
		print("  PASS: %s" % message)
		tests_passed += 1
	else:
		push_error("  FAIL: %s" % message)
		tests_failed += 1


func _test_recipe_data() -> void:
	print("--- RecipeData Tests ---")

	_assert(test_recipe.id == "test_recipe", "Recipe ID is correct")
	_assert(test_recipe.has_profession_bonus(), "has_profession_bonus() returns true for engineer")
	_assert(test_recipe.get_input_cost("scrap_metal") == 3, "get_input_cost returns correct value")
	_assert(test_recipe.get_input_cost("nonexistent") == 0, "get_input_cost returns 0 for missing resource")
	_assert(test_recipe.get_output_quantity("test_item") == 2, "get_output_quantity returns correct value")
	_assert(test_recipe.get_craft_time_for_profession("engineer") == 45, "Profession bonus applies 25% reduction")
	_assert(test_recipe.get_craft_time_for_profession("medic") == 60, "No bonus for non-matching profession")
	_assert(test_recipe.is_default_unlocked(), "Default recipe is unlocked")
	_assert(test_recipe.get_total_input_cost() == 5, "get_total_input_cost sums correctly")
	_assert(test_recipe.get_total_output_quantity() == 2, "get_total_output_quantity sums correctly")

	# Test can_craft_with
	var enough := {"scrap_metal": 5, "wiring": 3}
	var not_enough := {"scrap_metal": 2, "wiring": 1}
	_assert(test_recipe.can_craft_with(enough), "can_craft_with returns true with enough resources")
	_assert(not test_recipe.can_craft_with(not_enough), "can_craft_with returns false with insufficient resources")


func _test_craft_job() -> void:
	print("--- CraftJob Tests ---")

	# Test job creation
	var job := CraftJob.create(1, test_recipe, "engineer")
	_assert(job.job_id == 1, "Job ID is set correctly")
	_assert(job.recipe == test_recipe, "Recipe is set correctly")
	_assert(job.total_time == 45.0, "Total time includes profession bonus")
	_assert(job.state == CraftJob.State.QUEUED, "Initial state is QUEUED")
	_assert(job.is_queued(), "is_queued() returns true")

	# Test job without profession bonus
	var job2 := CraftJob.create(2, test_recipe, "medic")
	_assert(job2.total_time == 60.0, "Total time is base when no profession match")

	# Test progress tracking
	job.start()
	_assert(job.is_in_progress(), "is_in_progress() returns true after start")
	_assert(job.get_progress_percent() == 0.0, "Progress starts at 0%")

	job.advance_time(22.5)
	_assert(abs(job.get_progress_percent() - 0.5) < 0.01, "Progress is 50% at half time")
	_assert(abs(job.get_remaining_time() - 22.5) < 0.01, "Remaining time is correct")

	var completed := job.advance_time(30.0)
	_assert(completed, "advance_time returns true when job completes")
	_assert(job.is_complete(), "is_complete() returns true after completion")
	_assert(job.get_progress_percent() == 1.0, "Progress is 100% when complete")

	# Test cancellation
	var job3 := CraftJob.create(3, test_recipe)
	job3.cancel()
	_assert(job3.is_cancelled(), "is_cancelled() returns true after cancel")


func _test_craft_queue() -> void:
	print("--- CraftQueue Tests ---")

	# Test queue creation with slot limit
	var queue := CraftQueue.new(2)
	_assert(queue.max_slots == 2, "max_slots is set correctly")
	_assert(queue.is_empty(), "Queue starts empty")
	_assert(queue.can_add_job(), "can_add_job returns true for empty queue")

	# Test adding jobs
	var job1 := queue.add_job(test_recipe, "engineer")
	_assert(job1 != null, "First job added successfully")
	_assert(job1.is_in_progress(), "First job starts immediately")
	_assert(queue.get_job_count() == 1, "Job count is 1")

	var job2 := queue.add_job(test_recipe)
	_assert(job2 != null, "Second job added successfully")
	_assert(job2.is_queued(), "Second job is queued, not started")
	_assert(queue.get_job_count() == 2, "Job count is 2")
	_assert(queue.is_full(), "Queue is full with 2 slots")

	var job3 := queue.add_job(test_recipe)
	_assert(job3 == null, "Cannot add job when queue is full")

	# Test getting active job
	var active := queue.get_active_job()
	_assert(active == job1, "get_active_job returns first job")

	# Test queued jobs
	var queued := queue.get_queued_jobs()
	_assert(queued.size() == 1, "get_queued_jobs returns 1 job")
	_assert(queued[0] == job2, "Queued job is job2")

	# Test time advancement and completion
	var completed := queue.advance_time(50.0)  # Job1 takes 45s with engineer bonus
	_assert(completed.size() == 1, "One job completed")
	_assert(completed[0] == job1, "Completed job is job1")
	_assert(queue.get_job_count() == 1, "Job count is 1 after completion")

	# Job2 should now be active
	var new_active := queue.get_active_job()
	_assert(new_active == job2, "Job2 is now active")
	_assert(job2.is_in_progress(), "Job2 is in progress")

	# Test removal
	var removed := queue.remove_job(job2.job_id)
	_assert(removed, "Job removed successfully")
	_assert(queue.is_empty(), "Queue is empty after removal")

	# Test clear
	queue.add_job(test_recipe)
	queue.add_job(test_recipe)
	queue.clear()
	_assert(queue.is_empty(), "Queue is empty after clear")


func _test_recipe_validator() -> void:
	print("--- RecipeValidator Tests ---")

	# Test can_craft validation
	var enough := {"scrap_metal": 5, "wiring": 3}
	var not_enough := {"scrap_metal": 2, "wiring": 1}

	var result1 := RecipeValidator.can_craft(test_recipe, enough)
	_assert(result1.success, "can_craft succeeds with enough resources")

	var result2 := RecipeValidator.can_craft(test_recipe, not_enough)
	_assert(not result2.success, "can_craft fails with insufficient resources")
	_assert(result2.missing_resources.has("scrap_metal"), "Missing resources includes scrap_metal")
	_assert(result2.missing_resources["scrap_metal"] == 1, "Missing 1 scrap_metal")
	_assert(result2.missing_resources["wiring"] == 1, "Missing 1 wiring")

	# Test get_missing_resources
	var missing := RecipeValidator.get_missing_resources(test_recipe, not_enough)
	_assert(missing.size() == 2, "Two resources are missing")

	# Test craft time calculation
	var time1 := RecipeValidator.calculate_craft_time(test_recipe, "engineer", 1)
	_assert(abs(time1 - 45.0) < 0.01, "Time with engineer profession is 45s")

	var time2 := RecipeValidator.calculate_craft_time(test_recipe, "medic", 1)
	_assert(abs(time2 - 60.0) < 0.01, "Time without profession bonus is 60s")

	var time3 := RecipeValidator.calculate_craft_time(test_recipe, "engineer", 2)
	_assert(abs(time3 - 34.6) < 0.1, "Time with T2 station is ~34.6s (45/1.3)")

	var time4 := RecipeValidator.calculate_craft_time(test_recipe, "engineer", 4)
	_assert(abs(time4 - 22.5) < 0.01, "Time with T4 station is 22.5s (45/2)")

	# Test station validation
	var station_result := RecipeValidator.validate_station(test_recipe, "workshop")
	_assert(station_result.success, "validate_station succeeds for correct station")

	var wrong_station := RecipeValidator.validate_station(test_recipe, "armory")
	_assert(not wrong_station.success, "validate_station fails for wrong station")

	# Test unlock validation
	var unlock_checks := {"schematics": [], "upgrades": [], "research": []}
	var unlock_result := RecipeValidator.validate_unlock(test_recipe, unlock_checks)
	_assert(unlock_result.success, "Default recipe passes unlock validation")

	# Test max craft count
	var max_count := RecipeValidator.get_max_craft_count(test_recipe, {"scrap_metal": 9, "wiring": 4})
	_assert(max_count == 2, "Can craft 2 with 9 metal and 4 wiring (limited by wiring)")

	# Test batch calculations
	var batch_cost := RecipeValidator.get_batch_cost(test_recipe, 3)
	_assert(batch_cost["scrap_metal"] == 9, "Batch cost for 3x is 9 scrap_metal")
	_assert(batch_cost["wiring"] == 6, "Batch cost for 3x is 6 wiring")

	var batch_output := RecipeValidator.get_batch_output(test_recipe, 3)
	_assert(batch_output["test_item"] == 6, "Batch output for 3x is 6 test_items")
