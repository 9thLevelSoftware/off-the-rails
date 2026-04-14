class_name JobScheduler
extends RefCounted

## Use case for scheduling and managing crafting jobs.
## Orchestrates CraftQueue, RecipeValidator, and InventoryRepository.
## Emits events through CraftingEventBus.


## Result inner class for operation outcomes
class Result extends RefCounted:
	var success: bool = false
	var error: String = ""
	var data: Variant = null

	static func ok(p_data: Variant = null) -> Result:
		var r := Result.new()
		r.success = true
		r.data = p_data
		return r

	static func fail(p_error: String) -> Result:
		var r := Result.new()
		r.success = false
		r.error = p_error
		return r


# --- Dependencies ---
## CraftQueue instance for job management
var _queue: CraftQueue
## RecipeValidator instance (uses static methods)
var _validator: RecipeValidator
## InventoryRepository instance for resource operations
var _inventory: InventoryRepository
## Event bus singleton for emitting signals
var _event_bus: CraftingEventBus

# --- State ---
var _paused: bool = false
var _pause_reason: String = ""


## Constructor
## @param queue: CraftQueue - The queue to manage jobs
## @param validator: RecipeValidator - Validator for recipe checks
## @param inventory: InventoryRepository - Repository for inventory operations
func _init(queue, validator, inventory) -> void:
	_queue = queue
	_validator = validator
	_inventory = inventory
	# Get the singleton - use preload to avoid class_name resolution issues
	var EventBusScript = preload("res://src/crafting/infrastructure/crafting_event_bus.gd")
	_event_bus = EventBusScript.get_instance()


## Enqueue a recipe for crafting.
## Validates recipe, checks resources, consumes inputs, and adds to queue.
## Returns Result with the created CraftJob on success.
func enqueue_recipe(recipe: RecipeData, profession_id: String = "") -> Result:
	if _paused:
		_event_bus.emit_job_failed(recipe, "Queue is paused")
		return Result.fail("Queue is paused: %s" % _pause_reason)

	if not _queue.can_add_job():
		_event_bus.emit_job_failed(recipe, "Queue is full")
		return Result.fail("Queue is full (%d/%d slots)" % [_queue.get_job_count(), _queue.max_slots])

	# Validate resources using static validator methods
	var available: Dictionary = _inventory.get_all_resources()
	var RecipeValidatorScript = preload("res://src/crafting/domain/recipe_validator.gd")
	var validation: RecipeValidator.ValidationResult = RecipeValidatorScript.can_craft(recipe, available)

	if not validation.success:
		_event_bus.emit_job_failed(recipe, validation.reason)
		return Result.fail(validation.reason)

	# Consume input resources
	if not recipe.inputs.is_empty():
		var consumed: bool = _inventory.consume_resources(recipe.inputs)
		if not consumed:
			_event_bus.emit_job_failed(recipe, "Failed to consume resources")
			return Result.fail("Failed to consume resources")

	# Add job to queue
	var job: CraftJob = _queue.add_job(recipe, profession_id)
	if job == null:
		# Should not happen given earlier checks, but handle gracefully
		_event_bus.emit_job_failed(recipe, "Failed to add job to queue")
		return Result.fail("Failed to add job to queue")

	# Emit events
	_event_bus.emit_job_queued(job)
	if job.is_in_progress():
		_event_bus.emit_job_started(job)

	return Result.ok(job)


## Advance time for the queue.
## Progresses active job and handles completions.
func tick(delta: float) -> void:
	if _paused:
		return

	if _queue.is_empty():
		return

	var active_job: CraftJob = _queue.get_active_job()
	if active_job == null:
		return

	# Advance queue time - this may complete and remove the job
	var completed_jobs: Array[CraftJob] = _queue.advance_time(delta)

	# Emit progress for current active job (if not completed)
	var current_job: CraftJob = _queue.get_active_job()
	if current_job and current_job.is_in_progress():
		_event_bus.emit_job_progress(current_job, current_job.get_progress_percent())

	# Handle completed jobs - emit BEFORE the job is fully gone
	for job in completed_jobs:
		# Emit completion event first (CRITIQUE FIX)
		_event_bus.emit_job_completed(job)
		_event_bus.emit_queue_job_removed(job)

		# Then add outputs to inventory
		if not job.recipe.output.is_empty():
			_inventory.add_resources(job.recipe.output)

		# Start next job if any
		var next_job: CraftJob = _queue.get_active_job()
		if next_job and next_job.is_in_progress():
			_event_bus.emit_job_started(next_job)


## Cancel a job by ID.
## Refunds 50% of input resources.
## Returns Result indicating success/failure.
func cancel_job(job_id: int) -> Result:
	var job: CraftJob = _queue.get_job(job_id)
	if job == null:
		return Result.fail("Job not found: %d" % job_id)

	var recipe: RecipeData = job.recipe

	# Calculate 50% refund
	var refund: Dictionary = {}
	for resource_id in recipe.inputs:
		var original_qty: int = recipe.inputs[resource_id]
		var refund_qty: int = int(float(original_qty) * 0.5)
		if refund_qty > 0:
			refund[resource_id] = refund_qty

	# Remove job from queue (this calls job.cancel() internally)
	var removed: bool = _queue.remove_job(job_id)
	if not removed:
		return Result.fail("Failed to remove job from queue")

	# Emit cancel event
	_event_bus.emit_job_cancelled(job)

	# Apply refund
	if not refund.is_empty():
		_inventory.add_resources(refund)

	return Result.ok(refund)


## Pause the queue.
## Jobs will not progress while paused.
func pause(reason: String = "") -> void:
	if _paused:
		return
	_paused = true
	_pause_reason = reason
	_event_bus.emit_queue_paused(reason)


## Resume the queue.
func resume() -> void:
	if not _paused:
		return
	_paused = false
	_pause_reason = ""
	_event_bus.emit_queue_resumed()

	# If there's a queued job at front, start it
	var active: CraftJob = _queue.get_active_job()
	if active == null:
		_queue.resume_active_job()
		active = _queue.get_active_job()
		if active and active.is_in_progress():
			_event_bus.emit_job_started(active)


## Clear all jobs from the queue.
## Does NOT refund resources.
func clear_queue() -> void:
	var jobs: Array[CraftJob] = _queue.get_all_jobs()
	_queue.clear()

	for job in jobs:
		_event_bus.emit_job_cancelled(job)

	_event_bus.emit_queue_cleared()


## Check if queue is paused.
func is_paused() -> bool:
	return _paused


## Get pause reason.
func get_pause_reason() -> String:
	return _pause_reason


## Get current queue.
func get_queue():  # Returns CraftQueue
	return _queue


## Move a job up in the queue.
## Returns Result indicating success/failure.
func move_job_up(job_id: int) -> Result:
	var moved: bool = _queue.move_job_up(job_id)
	if moved:
		_event_bus.emit_queue_reordered()
		return Result.ok()
	return Result.fail("Cannot move job up")


## Move a job down in the queue.
## Returns Result indicating success/failure.
func move_job_down(job_id: int) -> Result:
	var moved: bool = _queue.move_job_down(job_id)
	if moved:
		_event_bus.emit_queue_reordered()
		return Result.ok()
	return Result.fail("Cannot move job down")
