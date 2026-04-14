class_name QueueDisplay
extends PanelContainer

## UI panel for displaying the crafting queue.
## Shows active job with progress bar and queued jobs with cancel buttons.
## CRITIQUE FIX: Connects ONLY to CraftingEventBus, not CraftQueue directly.

## Emitted when a job cancel is requested
signal cancel_requested(job_id: int)

## UI References
@onready var title_label: Label = $VBox/TitleLabel
@onready var active_job_panel: PanelContainer = $VBox/ActiveJobPanel
@onready var active_job_name: Label = $VBox/ActiveJobPanel/ActiveVBox/ActiveJobName
@onready var progress_bar: ProgressBar = $VBox/ActiveJobPanel/ActiveVBox/ProgressBar
@onready var time_remaining_label: Label = $VBox/ActiveJobPanel/ActiveVBox/TimeRemainingLabel
@onready var queued_list: VBoxContainer = $VBox/QueuedJobsScroll/QueuedList
@onready var empty_label: Label = $VBox/EmptyLabel
@onready var pause_indicator: Label = $VBox/PauseIndicator

## Event bus reference
var _event_bus: CraftingEventBus = null

## Current active job reference (for UI updates)
var _active_job: CraftJob = null

## Queued jobs list (for UI rebuild)
var _queued_jobs: Array[CraftJob] = []

## Paused state
var _paused: bool = false


func _ready() -> void:
	# Get event bus singleton
	var EventBusScript = preload("res://src/crafting/infrastructure/crafting_event_bus.gd")
	_event_bus = EventBusScript.get_instance()

	# Connect to event bus signals
	_event_bus.job_queued.connect(_on_job_queued)
	_event_bus.job_started.connect(_on_job_started)
	_event_bus.job_progress.connect(_on_job_progress)
	_event_bus.job_completed.connect(_on_job_completed)
	_event_bus.job_cancelled.connect(_on_job_cancelled)
	_event_bus.queue_paused.connect(_on_queue_paused)
	_event_bus.queue_resumed.connect(_on_queue_resumed)
	_event_bus.queue_cleared.connect(_on_queue_cleared)

	# Initial state
	_update_display()


func _exit_tree() -> void:
	# Disconnect from event bus
	if _event_bus:
		if _event_bus.job_queued.is_connected(_on_job_queued):
			_event_bus.job_queued.disconnect(_on_job_queued)
		if _event_bus.job_started.is_connected(_on_job_started):
			_event_bus.job_started.disconnect(_on_job_started)
		if _event_bus.job_progress.is_connected(_on_job_progress):
			_event_bus.job_progress.disconnect(_on_job_progress)
		if _event_bus.job_completed.is_connected(_on_job_completed):
			_event_bus.job_completed.disconnect(_on_job_completed)
		if _event_bus.job_cancelled.is_connected(_on_job_cancelled):
			_event_bus.job_cancelled.disconnect(_on_job_cancelled)
		if _event_bus.queue_paused.is_connected(_on_queue_paused):
			_event_bus.queue_paused.disconnect(_on_queue_paused)
		if _event_bus.queue_resumed.is_connected(_on_queue_resumed):
			_event_bus.queue_resumed.disconnect(_on_queue_resumed)
		if _event_bus.queue_cleared.is_connected(_on_queue_cleared):
			_event_bus.queue_cleared.disconnect(_on_queue_cleared)


## Handle job queued event.
func _on_job_queued(job: CraftJob) -> void:
	# If no active job, this becomes active
	if _active_job == null and job.is_in_progress():
		_active_job = job
	else:
		_queued_jobs.append(job)
	_update_display()


## Handle job started event.
func _on_job_started(job: CraftJob) -> void:
	_active_job = job
	# Remove from queued list if present
	var idx := _find_job_index(job.job_id)
	if idx >= 0:
		_queued_jobs.remove_at(idx)
	_update_display()


## Handle job progress event.
func _on_job_progress(job: CraftJob, progress: float) -> void:
	if _active_job and _active_job.job_id == job.job_id:
		_update_active_job_display(progress)


## Handle job completed event.
func _on_job_completed(job: CraftJob) -> void:
	if _active_job and _active_job.job_id == job.job_id:
		_active_job = null
	_update_display()


## Handle job cancelled event.
func _on_job_cancelled(job: CraftJob) -> void:
	# Remove from active or queued
	if _active_job and _active_job.job_id == job.job_id:
		_active_job = null
	else:
		var idx := _find_job_index(job.job_id)
		if idx >= 0:
			_queued_jobs.remove_at(idx)
	_update_display()


## Handle queue paused event.
func _on_queue_paused(reason: String) -> void:
	_paused = true
	pause_indicator.text = "PAUSED: %s" % reason
	pause_indicator.visible = true


## Handle queue resumed event.
func _on_queue_resumed() -> void:
	_paused = false
	pause_indicator.visible = false


## Handle queue cleared event.
func _on_queue_cleared() -> void:
	_active_job = null
	_queued_jobs.clear()
	_update_display()


## Find job index in queued jobs array.
func _find_job_index(job_id: int) -> int:
	for i in range(_queued_jobs.size()):
		if _queued_jobs[i].job_id == job_id:
			return i
	return -1


## Update the full display.
func _update_display() -> void:
	# Check if queue is empty
	var is_empty := (_active_job == null and _queued_jobs.is_empty())

	empty_label.visible = is_empty
	active_job_panel.visible = (_active_job != null)

	# Update active job display
	if _active_job:
		active_job_name.text = _active_job.recipe.name
		_update_active_job_display(_active_job.get_progress_percent())

	# Update queued jobs list
	_rebuild_queued_list()


## Update active job progress display.
func _update_active_job_display(progress: float) -> void:
	if not _active_job:
		return

	progress_bar.value = progress * 100.0
	var remaining := _active_job.get_remaining_time()
	time_remaining_label.text = "Time remaining: %s" % _format_time(int(remaining))


## Rebuild the queued jobs list UI.
func _rebuild_queued_list() -> void:
	# Clear existing
	for child in queued_list.get_children():
		child.queue_free()

	# Add queued jobs
	for job in _queued_jobs:
		var row := HBoxContainer.new()

		var name_label := Label.new()
		name_label.text = job.recipe.name
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		var cancel_btn := Button.new()
		cancel_btn.text = "Cancel"
		cancel_btn.pressed.connect(_on_cancel_job_pressed.bind(job.job_id))
		row.add_child(cancel_btn)

		queued_list.add_child(row)


## Handle cancel button press for a queued job.
func _on_cancel_job_pressed(job_id: int) -> void:
	cancel_requested.emit(job_id)


## Format seconds to human-readable time.
@warning_ignore("integer_division")
func _format_time(seconds: int) -> String:
	if seconds < 60:
		return "%ds" % seconds
	var minutes := seconds / 60
	var remaining_seconds := seconds % 60
	if remaining_seconds == 0:
		return "%dm" % minutes
	return "%dm %ds" % [minutes, remaining_seconds]


## Manually set jobs (for initial state sync).
func sync_with_queue(queue: CraftQueue) -> void:
	_active_job = queue.get_active_job()
	_queued_jobs.clear()
	for job in queue.get_queued_jobs():
		_queued_jobs.append(job)
	_update_display()
