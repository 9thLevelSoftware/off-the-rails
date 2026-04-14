class_name CraftingEventBus
extends RefCounted

## Singleton event bus for crafting system events.
## Routes signals between domain objects and UI/infrastructure.
## Stateless - only routes signals, no state management.

# --- Singleton ---
# LIFECYCLE WARNING: Objects that call get_instance() cache the reference.
# If reset_instance() is called (e.g., during test teardown), those objects
# will hold stale references and emit signals to a disconnected bus.
# CONSTRAINT: All dependent objects (WorkshopAdapter, CraftQueueManager, etc.)
# MUST be destroyed BEFORE calling reset_instance(). In tests, ensure proper
# teardown order: destroy adapters -> reset_instance() -> create new test fixtures.
static var _instance: CraftingEventBus = null


static func get_instance() -> CraftingEventBus:
	if _instance == null:
		_instance = CraftingEventBus.new()
	return _instance


## Reset the singleton instance (for test isolation).
## WARNING: All objects holding references to the old instance will be orphaned.
## Ensure all dependent objects are destroyed before calling this method.
static func reset_instance() -> void:
	_instance = null


# --- Job Lifecycle Signals ---
# Note: Using untyped signals to avoid class_name resolution issues with preload

## Emitted when a job is added to the queue (job: CraftJob)
signal job_queued(job)

## Emitted when a job transitions from QUEUED to IN_PROGRESS (job: CraftJob)
signal job_started(job)

## Emitted periodically as a job progresses (job: CraftJob, progress: float)
signal job_progress(job, progress: float)

## Emitted when a job completes successfully (job: CraftJob)
signal job_completed(job)

## Emitted when a job is cancelled (job: CraftJob)
signal job_cancelled(job)

## Emitted when a job fails (recipe: RecipeData, reason: String)
signal job_failed(recipe, reason: String)


# --- Queue State Signals ---

## Emitted when the queue is paused (e.g., during expedition)
signal queue_paused(reason: String)

## Emitted when the queue is resumed
signal queue_resumed()

## Emitted when all jobs are cleared from the queue
signal queue_cleared()

## Emitted when a job is added to the queue (job: CraftJob)
signal queue_job_added(job)

## Emitted when a job is removed from the queue (job: CraftJob)
signal queue_job_removed(job)

## Emitted when jobs are reordered in the queue
signal queue_reordered()


# --- UI Signals ---

## Emitted when crafting UI should be opened (requester: Object)
signal crafting_ui_requested(requester)


# --- Emission Methods ---
# These provide a clean API for emitting signals from other systems

func emit_job_queued(job) -> void:
	job_queued.emit(job)
	queue_job_added.emit(job)


func emit_job_started(job) -> void:
	job_started.emit(job)


func emit_job_progress(job, progress: float) -> void:
	job_progress.emit(job, progress)


func emit_job_completed(job) -> void:
	job_completed.emit(job)


func emit_job_cancelled(job) -> void:
	job_cancelled.emit(job)
	queue_job_removed.emit(job)


func emit_job_failed(recipe, reason: String) -> void:
	job_failed.emit(recipe, reason)


func emit_queue_paused(reason: String) -> void:
	queue_paused.emit(reason)


func emit_queue_resumed() -> void:
	queue_resumed.emit()


func emit_queue_cleared() -> void:
	queue_cleared.emit()


func emit_queue_job_removed(job) -> void:
	queue_job_removed.emit(job)


func emit_queue_reordered() -> void:
	queue_reordered.emit()


func emit_crafting_ui_requested(requester) -> void:
	crafting_ui_requested.emit(requester)
