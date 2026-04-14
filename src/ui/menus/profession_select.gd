class_name ProfessionSelect
extends CanvasLayer
## Profession selection screen shown after starting a new game.
## Displays available professions with their abilities and bonuses.
## Selection triggers game start with chosen profession.

signal profession_selected(profession: ProfessionData)
signal back_pressed

const ENGINEER_PATH := "res://src/data/professions/engineer.tres"
const MEDIC_PATH := "res://src/data/professions/medic.tres"

@onready var engineer_button: Button = $CenterContainer/VBoxContainer/ProfessionContainer/EngineerCard/MarginContainer/VBoxContainer/SelectButton
@onready var medic_button: Button = $CenterContainer/VBoxContainer/ProfessionContainer/MedicCard/MarginContainer/VBoxContainer/SelectButton
@onready var back_button: Button = $CenterContainer/VBoxContainer/BackButton

@onready var engineer_name: Label = $CenterContainer/VBoxContainer/ProfessionContainer/EngineerCard/MarginContainer/VBoxContainer/NameLabel
@onready var engineer_desc: Label = $CenterContainer/VBoxContainer/ProfessionContainer/EngineerCard/MarginContainer/VBoxContainer/DescLabel
@onready var engineer_abilities: Label = $CenterContainer/VBoxContainer/ProfessionContainer/EngineerCard/MarginContainer/VBoxContainer/AbilitiesLabel
@onready var engineer_bonuses: Label = $CenterContainer/VBoxContainer/ProfessionContainer/EngineerCard/MarginContainer/VBoxContainer/BonusesLabel

@onready var medic_name: Label = $CenterContainer/VBoxContainer/ProfessionContainer/MedicCard/MarginContainer/VBoxContainer/NameLabel
@onready var medic_desc: Label = $CenterContainer/VBoxContainer/ProfessionContainer/MedicCard/MarginContainer/VBoxContainer/DescLabel
@onready var medic_abilities: Label = $CenterContainer/VBoxContainer/ProfessionContainer/MedicCard/MarginContainer/VBoxContainer/AbilitiesLabel
@onready var medic_bonuses: Label = $CenterContainer/VBoxContainer/ProfessionContainer/MedicCard/MarginContainer/VBoxContainer/BonusesLabel

var _engineer_data: ProfessionData
var _medic_data: ProfessionData


func _ready() -> void:
	layer = 100  # Same layer as main menu

	# Load profession data
	_engineer_data = load(ENGINEER_PATH) as ProfessionData
	_medic_data = load(MEDIC_PATH) as ProfessionData

	if _engineer_data == null:
		push_error("[ProfessionSelect] Failed to load engineer profession")
	if _medic_data == null:
		push_error("[ProfessionSelect] Failed to load medic profession")

	# Connect buttons
	engineer_button.pressed.connect(_on_engineer_selected)
	medic_button.pressed.connect(_on_medic_selected)
	back_button.pressed.connect(_on_back_pressed)

	# Populate UI
	_populate_profession_card(_engineer_data, engineer_name, engineer_desc, engineer_abilities, engineer_bonuses)
	_populate_profession_card(_medic_data, medic_name, medic_desc, medic_abilities, medic_bonuses)

	# Focus first option
	engineer_button.grab_focus()

	print("[ProfessionSelect] Ready")


func _populate_profession_card(
	data: ProfessionData,
	name_label: Label,
	desc_label: Label,
	abilities_label: Label,
	bonuses_label: Label
) -> void:
	if data == null:
		return

	name_label.text = data.name
	desc_label.text = data.description

	# Format abilities
	var abilities_text := "Active Abilities:\n"
	for ability in data.active_abilities:
		var ability_name: String = ability.get("name", "Unknown")
		abilities_text += "  - %s\n" % ability_name
	abilities_label.text = abilities_text.strip_edges()

	# Format bonuses
	var bonuses_text := "Passive Bonuses:\n"
	for bonus in data.passive_bonuses:
		bonuses_text += "  - %s\n" % bonus
	bonuses_label.text = bonuses_text.strip_edges()


func _on_engineer_selected() -> void:
	if _engineer_data:
		profession_selected.emit(_engineer_data)


func _on_medic_selected() -> void:
	if _medic_data:
		profession_selected.emit(_medic_data)


func _on_back_pressed() -> void:
	back_pressed.emit()


## Shows the profession selection screen
func show_menu() -> void:
	visible = true
	engineer_button.grab_focus()


## Hides the profession selection screen
func hide_menu() -> void:
	visible = false
