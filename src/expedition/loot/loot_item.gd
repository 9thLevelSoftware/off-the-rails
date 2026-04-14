class_name LootItem
extends Resource

## Data resource representing a single loot item.
## Used by LootContainer to define droppable items.

## The name/identifier of this item.
@export var item_name: String = ""

## How many of this item are present.
@export var quantity: int = 1

## The category/type of item (e.g., "generic", "weapon", "consumable", "material").
@export var item_type: String = "generic"


## Creates a new LootItem with the specified values.
static func create(p_name: String, p_quantity: int = 1, p_type: String = "generic") -> LootItem:
	var item := LootItem.new()
	item.item_name = p_name
	item.quantity = p_quantity
	item.item_type = p_type
	return item
