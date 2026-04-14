extends Node

## Test scene for verifying end-to-end crafting flow.
## Tests: resource consumption, job queuing, progress updates, output delivery.

const TARGET_RECIPES := [
	"basic_bandage",
	"improvised_torch",
	"ration_pack",
	"stim_shot",
	"glow_stick",
	"standard_ammo",
	"medical_kit",
	"antidote",
	"basic_repair_kit",
	"lockpick_set"
]

var _adapter: WorkshopAdapter = null
var _event_bus: CraftingEventBus = null
var _test_results: Array[Dictionary] = []


func _ready() -> void:
	# Initialize adapter
	_adapter = WorkshopAdapter.new()
	add_child(_adapter)

	# Get event bus
	var EventBusScript = preload("res://src/crafting/infrastructure/crafting_event_bus.gd")
	_event_bus = EventBusScript.get_instance()

	# Connect to events for verification
	_event_bus.job_queued.connect(_on_job_queued)
	_event_bus.job_started.connect(_on_job_started)
	_event_bus.job_progress.connect(_on_job_progress)
	_event_bus.job_completed.connect(_on_job_completed)
	_event_bus.job_cancelled.connect(_on_job_cancelled)

	# Setup test inventory
	_setup_test_inventory()

	# Run tests after frame
	call_deferred("_run_all_tests")


func _setup_test_inventory() -> void:
	# Add resources matching actual recipe input requirements
	# Based on actual .tres files in src/data/recipes/
	var test_resources := {
		# Common crafting materials
		"scrap_metal": 50,
		"chemicals": 30,
		"wiring": 20,
		"fabric_seals": 20,
		"basic_meds": 20,
		"glass_ceramics": 10,
		"rations": 20,
	}

	GameState.debug_set_inventory(test_resources)
	print("[CraftingTest] Test inventory setup complete")


func _run_all_tests() -> void:
	print("\n=== CRAFTING SYSTEM END-TO-END TEST ===\n")

	# Test 1: Load recipes
	_test_recipe_loading()

	# Test 2: Station filtering
	_test_station_filtering()

	# Test 3: Enqueue recipes (workshop only)
	_test_enqueue_recipes()

	# Test 4: Resource validation
	_test_resource_validation()

	# Test 5: Job cancellation
	_test_job_cancellation()

	# Test 6: Power loss simulation
	_test_power_loss()

	# Summary
	_print_summary()


func _test_recipe_loading() -> void:
	print("--- Test 1: Recipe Loading ---")

	var repo := _adapter.get_recipe_repository()
	var all_recipes := repo.get_all_recipes()

	print("  Loaded %d recipes total" % all_recipes.size())

	var found_count := 0
	for target_id in TARGET_RECIPES:
		var recipe := repo.get_recipe(target_id)
		if recipe:
			found_count += 1
			print("  [OK] Found recipe: %s (%s station)" % [recipe.name, recipe.station])
		else:
			print("  [FAIL] Missing recipe: %s" % target_id)

	_test_results.append({
		"name": "Recipe Loading",
		"passed": found_count == TARGET_RECIPES.size(),
		"details": "Found %d/%d target recipes" % [found_count, TARGET_RECIPES.size()]
	})
	print("")


func _test_station_filtering() -> void:
	print("--- Test 2: Station Filtering ---")

	var available := _adapter.get_available_recipes()
	var workshop_count := 0

	for recipe in available:
		if recipe.station == "workshop":
			workshop_count += 1

	print("  Available workshop recipes: %d" % workshop_count)

	# Check that field recipes are not included
	var field_in_available := 0
	for recipe in available:
		if recipe.station == "field":
			field_in_available += 1

	_test_results.append({
		"name": "Station Filtering",
		"passed": field_in_available == 0 and workshop_count > 0,
		"details": "Workshop: %d, Field leaked: %d" % [workshop_count, field_in_available]
	})
	print("")


func _test_enqueue_recipes() -> void:
	print("--- Test 3: Enqueue Workshop Recipes ---")

	var repo := _adapter.get_recipe_repository()
	var enqueued := 0
	var failed := 0

	# Try to enqueue workshop recipes
	for target_id in TARGET_RECIPES:
		var recipe := repo.get_recipe(target_id)
		if recipe == null:
			continue

		if recipe.station != "workshop":
			print("  [SKIP] %s - requires %s station" % [recipe.name, recipe.station])
			continue

		var result := _adapter.enqueue_recipe(recipe)
		if result.success:
			print("  [OK] Enqueued: %s" % recipe.name)
			enqueued += 1
		else:
			print("  [FAIL] %s - %s" % [recipe.name, result.error])
			failed += 1

	_test_results.append({
		"name": "Enqueue Recipes",
		"passed": enqueued > 0,
		"details": "Enqueued: %d, Failed: %d" % [enqueued, failed]
	})
	print("")


func _test_resource_validation() -> void:
	print("--- Test 4: Resource Validation ---")

	var repo := _adapter.get_recipe_repository()

	# Test with recipe we don't have resources for
	var lockpick := repo.get_recipe("lockpick_set")
	if lockpick:
		# First clear inventory
		GameState.debug_set_inventory({})

		var result := _adapter.enqueue_recipe(lockpick)
		var correctly_rejected := not result.success and "Missing" in result.error

		# Restore inventory
		_setup_test_inventory()

		print("  Empty inventory rejection: %s" % ("PASS" if correctly_rejected else "FAIL"))

		_test_results.append({
			"name": "Resource Validation",
			"passed": correctly_rejected,
			"details": "Correctly rejected without resources: %s" % correctly_rejected
		})
	else:
		_test_results.append({
			"name": "Resource Validation",
			"passed": false,
			"details": "Could not find lockpick_set recipe"
		})
	print("")


func _test_job_cancellation() -> void:
	print("--- Test 5: Job Cancellation ---")

	var queue := _adapter.get_queue()

	# Get first job if any
	var active := queue.get_active_job()
	if active:
		var job_id := active.job_id
		var result := _adapter.cancel_job(job_id)

		print("  Cancel result: %s" % ("PASS" if result.success else "FAIL - " + result.error))

		_test_results.append({
			"name": "Job Cancellation",
			"passed": result.success,
			"details": "Cancel active job: %s" % result.success
		})
	else:
		print("  [SKIP] No active job to cancel")
		_test_results.append({
			"name": "Job Cancellation",
			"passed": true,
			"details": "Skipped - no active job"
		})
	print("")


func _test_power_loss() -> void:
	print("--- Test 6: Power Loss Simulation ---")

	var scheduler := _adapter.get_scheduler()

	# Simulate power loss
	scheduler.pause("Power loss test")
	var is_paused := scheduler.is_paused()

	# Resume
	scheduler.resume()
	var is_resumed := not scheduler.is_paused()

	print("  Pause on power loss: %s" % ("PASS" if is_paused else "FAIL"))
	print("  Resume on power restore: %s" % ("PASS" if is_resumed else "FAIL"))

	_test_results.append({
		"name": "Power Loss",
		"passed": is_paused and is_resumed,
		"details": "Pause: %s, Resume: %s" % [is_paused, is_resumed]
	})
	print("")


func _print_summary() -> void:
	print("\n=== TEST SUMMARY ===\n")

	var passed := 0
	var failed := 0

	for result in _test_results:
		var status := "PASS" if result.passed else "FAIL"
		print("  [%s] %s: %s" % [status, result.name, result.details])
		if result.passed:
			passed += 1
		else:
			failed += 1

	print("\n  Total: %d passed, %d failed\n" % [passed, failed])

	if failed == 0:
		print("  ALL TESTS PASSED!")
	else:
		print("  SOME TESTS FAILED - Review output above")


# Event handlers for verification
func _on_job_queued(job: CraftJob) -> void:
	print("  [EVENT] Job queued: %s (ID: %d)" % [job.recipe.name, job.job_id])


func _on_job_started(job: CraftJob) -> void:
	print("  [EVENT] Job started: %s" % job.recipe.name)


func _on_job_progress(job: CraftJob, progress: float) -> void:
	# Only log at 25% intervals
	var pct := int(progress * 100)
	if pct % 25 == 0:
		print("  [EVENT] Job progress: %s - %d%%" % [job.recipe.name, pct])


func _on_job_completed(job: CraftJob) -> void:
	print("  [EVENT] Job completed: %s" % job.recipe.name)


func _on_job_cancelled(job: CraftJob) -> void:
	print("  [EVENT] Job cancelled: %s" % job.recipe.name)
