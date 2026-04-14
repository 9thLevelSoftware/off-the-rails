class_name CraftJob
extends RefCounted

## Value object representing a single crafting job in progress.
## Tracks recipe, timing, and state for queue management.
## Pure domain object - no Node dependencies.

enum State {
	QUEUED,
	IN_PROGRESS,
	COMPLETED,
	CANCELLED
}

## Unique identifier for this job instance
var job_id: int

## The recipe being crafted
var recipe: RecipeData

## Total time to complete in seconds
var total_time: float

## Elapsed time in seconds
var elapsed_time: float = 0.0

## Current job state
var state: State = State.QUEUED

## Profession ID of crafter (for bonus calculation)
var crafter_profession: String = ""


## Private constructor - use static create() instead
func _init() -> void:
	pass


## Factory method to create a new CraftJob
static func create(p_job_id: int, p_recipe: RecipeData, p_crafter_profession: String = "") -> CraftJob:
	var job := CraftJob.new()
	job.job_id = p_job_id
	job.recipe = p_recipe
	job.crafter_profession = p_crafter_profession

	# Calculate total time with profession bonus
	if p_crafter_profession != "" and p_recipe.has_profession_bonus() and p_recipe.profession_bonus == p_crafter_profession:
		job.total_time = p_recipe.craft_time * 0.75  # 25% reduction
	else:
		job.total_time = float(p_recipe.craft_time)

	return job


## Get remaining time in seconds
func get_remaining_time() -> float:
	return maxf(0.0, total_time - elapsed_time)


## Get progress as percentage (0.0 to 1.0)
func get_progress_percent() -> float:
	if total_time <= 0.0:
		return 1.0
	return clampf(elapsed_time / total_time, 0.0, 1.0)


## Advance time by delta seconds
## Returns true if job completed during this update
func advance_time(delta: float) -> bool:
	if state != State.IN_PROGRESS:
		return false

	elapsed_time += delta

	if elapsed_time >= total_time:
		elapsed_time = total_time
		state = State.COMPLETED
		return true

	return false


## Check if job is complete
func is_complete() -> bool:
	return state == State.COMPLETED


## Check if job is cancelled
func is_cancelled() -> bool:
	return state == State.CANCELLED


## Check if job is actively in progress
func is_in_progress() -> bool:
	return state == State.IN_PROGRESS


## Check if job is waiting in queue
func is_queued() -> bool:
	return state == State.QUEUED


## Start the job (transition from QUEUED to IN_PROGRESS)
func start() -> bool:
	if state != State.QUEUED:
		return false
	state = State.IN_PROGRESS
	return true


## Cancel the job
func cancel() -> void:
	if state == State.COMPLETED:
		return  # Cannot cancel completed job
	state = State.CANCELLED


## Get state as string for debugging
func get_state_name() -> String:
	match state:
		State.QUEUED:
			return "QUEUED"
		State.IN_PROGRESS:
			return "IN_PROGRESS"
		State.COMPLETED:
			return "COMPLETED"
		State.CANCELLED:
			return "CANCELLED"
	return "UNKNOWN"


func _to_string() -> String:
	return "[CraftJob:%d %s %.1f/%.1f %s]" % [
		job_id,
		recipe.id if recipe else "null",
		elapsed_time,
		total_time,
		get_state_name()
	]
