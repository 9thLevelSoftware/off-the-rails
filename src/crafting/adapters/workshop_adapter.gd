class_name WorkshopAdapter
extends Node

## Adapter bridging Fabricator subsystem to JobScheduler.
## Manages crafting queue progression based on fabricator power state.
## Connects to fabricator_ready_changed signal to pause/resume queue.

## Reference to the fabricator subsystem
var _fabricator: Fabricator = null

## JobScheduler instance for queue management
var _scheduler: JobScheduler = null

## ExpeditionPauseHandler for auto-pausing during expeditions
var _pause_handler: ExpeditionPauseHandler = null

## RecipeRepository for loading recipes
var _recipe_repository: RecipeRepository = null

## CraftQueue for the workshop
var _queue: CraftQueue = null

## InventoryRepository for resource checks
var _inventory: InventoryRepository = null

## Station type for this adapter
const STATION_TYPE := "workshop"

## Maximum queue slots for workshop
const MAX_QUEUE_SLOTS := 3


func _ready() -> void:
	# Initialize crafting infrastructure
	_queue = CraftQueue.new(MAX_QUEUE_SLOTS)
	_inventory = InventoryRepository.new()
	_recipe_repository = RecipeRepository.new()
	_recipe_repository.load_all_recipes()

	# Create scheduler with queue and inventory
	var validator := RecipeValidator.new()
	_scheduler = JobScheduler.new(_queue, validator, _inventory)

	# Create pause handler and connect to GameState
	_pause_handler = ExpeditionPauseHandler.new(_scheduler)
	_pause_handler.connect_signals()

	print("[WorkshopAdapter] Initialized with %d-slot queue" % MAX_QUEUE_SLOTS)


## Set the fabricator reference and connect to its signals.
## Call this from WorkshopCar after fabricator is ready.
func set_fabricator(fabricator: Fabricator) -> void:
	# Disconnect from old fabricator if exists
	if _fabricator and is_instance_valid(_fabricator):
		if _fabricator.fabricator_ready_changed.is_connected(_on_fabricator_ready_changed):
			_fabricator.fabricator_ready_changed.disconnect(_on_fabricator_ready_changed)

	_fabricator = fabricator

	if _fabricator:
		_fabricator.fabricator_ready_changed.connect(_on_fabricator_ready_changed)
		# Sync initial state
		if _fabricator.is_ready_for_crafting():
			_scheduler.resume()
		else:
			_scheduler.pause("Fabricator offline")

		print("[WorkshopAdapter] Connected to fabricator")


func _process(delta: float) -> void:
	if _scheduler == null:
		return

	# Only tick scheduler when fabricator is ready for crafting
	if _fabricator and _fabricator.is_ready_for_crafting():
		# Apply crafting speed multiplier from fabricator
		var speed := _fabricator.get_crafting_speed()
		_scheduler.tick(delta * speed)


## Handle fabricator ready state changes.
func _on_fabricator_ready_changed(is_ready: bool) -> void:
	if is_ready:
		_scheduler.resume()
		print("[WorkshopAdapter] Fabricator ready - queue resumed")
	else:
		_scheduler.pause("Fabricator offline or no power")
		print("[WorkshopAdapter] Fabricator offline - queue paused")


## Enqueue a recipe for crafting.
## Returns JobScheduler.Result with success/failure info.
func enqueue_recipe(recipe: RecipeData) -> JobScheduler.Result:
	if _scheduler == null:
		return JobScheduler.Result.fail("Scheduler not initialized")

	# Validate station type
	if recipe.station != STATION_TYPE:
		return JobScheduler.Result.fail("Recipe requires %s station, not %s" % [recipe.station, STATION_TYPE])

	# Get player's profession for bonus calculation
	var profession_id := _get_player_profession_id()

	return _scheduler.enqueue_recipe(recipe, profession_id)


## Get player profession ID from GameState.
func _get_player_profession_id() -> String:
	if GameState.player_profession:
		return GameState.player_profession.id
	return ""


## Cancel a job by ID.
func cancel_job(job_id: int) -> JobScheduler.Result:
	if _scheduler == null:
		return JobScheduler.Result.fail("Scheduler not initialized")
	return _scheduler.cancel_job(job_id)


## Get current queue state.
func get_queue() -> CraftQueue:
	return _queue


## Get scheduler instance.
func get_scheduler() -> JobScheduler:
	return _scheduler


## Get recipe repository.
func get_recipe_repository() -> RecipeRepository:
	return _recipe_repository


## Get available recipes for this station.
## Filters by workshop station and default unlock status.
func get_available_recipes() -> Array[RecipeData]:
	# For V1, only default-unlocked recipes are available
	var unlock_status := {"schematics": [], "upgrades": [], "research": []}
	return _recipe_repository.get_available_recipes(STATION_TYPE, unlock_status)


## Check if a recipe can be crafted with current resources.
func can_craft_recipe(recipe: RecipeData) -> bool:
	var available := _inventory.get_all_resources()
	return recipe.can_craft_with(available)


## Get missing resources for a recipe.
func get_missing_resources(recipe: RecipeData) -> Dictionary:
	var available := _inventory.get_all_resources()
	return RecipeValidator.get_missing_resources(recipe, available)


## Check if fabricator is ready for crafting.
func is_ready_for_crafting() -> bool:
	return _fabricator != null and _fabricator.is_ready_for_crafting()


## Check if queue is paused.
func is_queue_paused() -> bool:
	return _scheduler != null and _scheduler.is_paused()


## Get current job count.
func get_job_count() -> int:
	return _queue.get_job_count() if _queue else 0


## Get maximum queue slots.
func get_max_slots() -> int:
	return MAX_QUEUE_SLOTS


func _exit_tree() -> void:
	# Disconnect from fabricator
	if _fabricator and is_instance_valid(_fabricator):
		if _fabricator.fabricator_ready_changed.is_connected(_on_fabricator_ready_changed):
			_fabricator.fabricator_ready_changed.disconnect(_on_fabricator_ready_changed)

	# Disconnect pause handler from GameState
	if _pause_handler:
		_pause_handler.disconnect_signals()
