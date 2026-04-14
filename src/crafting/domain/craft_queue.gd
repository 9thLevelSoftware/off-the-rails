class_name CraftQueue
extends RefCounted

## Entity managing a queue of CraftJobs for a crafting station.
## Handles queue limits, job lifecycle, and time advancement.
## Pure domain object - no Node dependencies.

## Emitted when a job is added to the queue
signal job_added(job: CraftJob)

## Emitted when a job is removed from the queue (completed, cancelled, or manually removed)
signal job_removed(job: CraftJob)

## Emitted when the queue state changes (any add/remove/reorder)
signal queue_changed()

## Emitted when a job completes
signal job_completed(job: CraftJob)

## Array of CraftJob objects in queue order
var _jobs: Array[CraftJob] = []

## Maximum number of jobs allowed in queue
var max_slots: int = 1

## Next job ID to assign
var _next_job_id: int = 1

## Station tier (affects speed bonus, not directly used here but tracked)
var station_tier: int = 1


func _init(p_max_slots: int = 1) -> void:
	max_slots = p_max_slots


## Check if a new job can be added to the queue
func can_add_job() -> bool:
	return _jobs.size() < max_slots


## Get current number of jobs in queue
func get_job_count() -> int:
	return _jobs.size()


## Get available slot count
func get_available_slots() -> int:
	return maxi(0, max_slots - _jobs.size())


## Check if queue is empty
func is_empty() -> bool:
	return _jobs.is_empty()


## Check if queue is full
func is_full() -> bool:
	return _jobs.size() >= max_slots


## Add a job to the queue
## Returns the created job, or null if queue is full
func add_job(recipe: RecipeData, crafter_profession: String = "") -> CraftJob:
	if not can_add_job():
		return null

	var job := CraftJob.create(_next_job_id, recipe, crafter_profession)
	_next_job_id += 1
	_jobs.append(job)

	# If this is the only job, start it immediately
	if _jobs.size() == 1:
		job.start()

	job_added.emit(job)
	queue_changed.emit()
	return job


## Remove a job from the queue by job_id
## Returns true if job was found and removed
func remove_job(job_id: int) -> bool:
	for i in range(_jobs.size()):
		if _jobs[i].job_id == job_id:
			var job := _jobs[i]
			job.cancel()
			_jobs.remove_at(i)
			job_removed.emit(job)
			queue_changed.emit()

			# If we removed the active job, start the next one
			if i == 0 and not _jobs.is_empty():
				_jobs[0].start()

			return true
	return false


## Get the currently active (in-progress) job, or null if none
func get_active_job() -> CraftJob:
	if _jobs.is_empty():
		return null

	var first_job := _jobs[0]
	if first_job.is_in_progress():
		return first_job

	return null


## Get all queued jobs (not including active job)
func get_queued_jobs() -> Array[CraftJob]:
	var queued: Array[CraftJob] = []
	for i in range(1, _jobs.size()):
		if _jobs[i].is_queued():
			queued.append(_jobs[i])
	return queued


## Get all jobs in the queue (active + queued)
func get_all_jobs() -> Array[CraftJob]:
	return _jobs.duplicate()


## Get job by ID, or null if not found
func get_job(job_id: int) -> CraftJob:
	for job in _jobs:
		if job.job_id == job_id:
			return job
	return null


## Clear all jobs from the queue
func clear() -> void:
	for job in _jobs:
		job.cancel()
		job_removed.emit(job)

	_jobs.clear()
	queue_changed.emit()


## Advance time for the active job
## Returns array of completed jobs
func advance_time(delta: float) -> Array[CraftJob]:
	var completed: Array[CraftJob] = []

	if _jobs.is_empty():
		return completed

	var active_job := _jobs[0]
	if not active_job.is_in_progress():
		# Start the job if it's queued
		if active_job.is_queued():
			active_job.start()
		else:
			return completed

	var did_complete := active_job.advance_time(delta)

	if did_complete:
		completed.append(active_job)
		job_completed.emit(active_job)

		# Remove completed job and start next
		_jobs.remove_at(0)
		job_removed.emit(active_job)

		if not _jobs.is_empty():
			_jobs[0].start()

		queue_changed.emit()

	return completed


## Move a job up in the queue (closer to front)
## Returns true if move was successful
func move_job_up(job_id: int) -> bool:
	var index := _find_job_index(job_id)
	if index <= 0:  # Can't move first job or not found
		return false

	# Can't move into position 0 if that job is in progress
	if index == 1 and _jobs[0].is_in_progress():
		return false

	var job := _jobs[index]
	_jobs.remove_at(index)
	_jobs.insert(index - 1, job)
	queue_changed.emit()
	return true


## Move a job down in the queue (further from front)
## Returns true if move was successful
func move_job_down(job_id: int) -> bool:
	var index := _find_job_index(job_id)
	if index < 0 or index >= _jobs.size() - 1:  # Not found or already last
		return false

	# Can't move job at index 0 if it's in progress
	if index == 0 and _jobs[0].is_in_progress():
		return false

	var job := _jobs[index]
	_jobs.remove_at(index)
	_jobs.insert(index + 1, job)
	queue_changed.emit()
	return true


## Pause the active job (transition to QUEUED state)
## Returns true if successful
func pause_active_job() -> bool:
	if _jobs.is_empty():
		return false

	var active := _jobs[0]
	if not active.is_in_progress():
		return false

	# We don't have a PAUSED state, so we just leave it as is
	# The game phase system handles pausing via not calling advance_time
	return true


## Resume the active job
## Returns true if successful
func resume_active_job() -> bool:
	if _jobs.is_empty():
		return false

	var first := _jobs[0]
	if first.is_queued():
		return first.start()

	return first.is_in_progress()


## Get estimated total time to complete all queued jobs
func get_total_remaining_time() -> float:
	var total := 0.0
	for job in _jobs:
		if not job.is_cancelled() and not job.is_complete():
			total += job.get_remaining_time()
	return total


## Update max slots (e.g., from station upgrade)
func set_max_slots(new_max: int) -> void:
	max_slots = maxi(1, new_max)


## Find index of job by ID
func _find_job_index(job_id: int) -> int:
	for i in range(_jobs.size()):
		if _jobs[i].job_id == job_id:
			return i
	return -1


func _to_string() -> String:
	return "[CraftQueue: %d/%d jobs, active=%s]" % [
		_jobs.size(),
		max_slots,
		get_active_job().recipe.id if get_active_job() else "none"
	]
