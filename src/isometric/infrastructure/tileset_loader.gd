# Infrastructure service for loading tileset resources
# Provides caching and validation

class_name IsoTilesetLoader
extends RefCounted

const DEFAULT_TILESET_PATH = "res://assets/tilesets/iso_floor.tres"

var _cache: Dictionary = {}


# Load a tileset from path with caching
func load_tileset(path: String = DEFAULT_TILESET_PATH) -> TileSet:
	if _cache.has(path):
		return _cache[path]

	if not ResourceLoader.exists(path):
		push_error("Tileset not found: " + path)
		return null

	var tileset = load(path) as TileSet
	if tileset:
		_validate_tileset(tileset)
		_cache[path] = tileset
	return tileset


# Validate tileset has correct isometric configuration
func _validate_tileset(tileset: TileSet) -> void:
	if tileset.tile_shape != TileSet.TILE_SHAPE_ISOMETRIC:
		push_warning("Tileset is not isometric")
	if tileset.tile_size != Vector2i(64, 32):
		push_warning("Tileset tile size is not 64x32")


# Clear the cache (for hot-reloading during development)
func clear_cache() -> void:
	_cache.clear()


# Get all cached tilesets
func get_cached_paths() -> Array[String]:
	var paths: Array[String] = []
	for key in _cache.keys():
		paths.append(key)
	return paths
