class_name CarData
extends Resource

## Data resource defining train car properties.
## Used for data-driven car configuration (extended in Phase 6).

## Unique identifier for this car type
@export var car_id: String = ""

## Human-readable display name
@export var display_name: String = "Train Car"

## Scene path for instantiating this car type
@export var scene_path: String = ""

## Default position offset in the train
@export var default_position: int = 0
