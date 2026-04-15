extends Node

## Integration test to verify mod loading and content registry unification.
## Run manually in editor or attach to a test scene.

func _ready() -> void:
	print("=== Integration Test ===")

	# Test 1: ModLoader ready
	if ModLoader.is_ready():
		print("PASS: ModLoader initialized")
		print("  Loaded mods: ", ModLoader.get_loaded_mod_ids())
	else:
		print("FAIL: ModLoader not ready")

	# Test 2: ContentRegistry unified
	var gs_registry = GameState.get_content_registry()
	var ml_registry = ModLoader.get_content_registry()
	if gs_registry == ml_registry:
		print("PASS: ContentRegistry unified")
	else:
		print("FAIL: ContentRegistry instances differ!")

	# Test 3: Base content loaded
	var item_count = gs_registry.items.get_all_ids().size()
	print("  Items in registry: ", item_count)

	# Test 4: Check for mod content (if any mods loaded)
	if ModLoader.get_loaded_mod_ids().size() > 0:
		print("PASS: Mods loaded - check if mod items appear in registry")
