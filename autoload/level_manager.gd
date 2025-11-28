## Level Manager - Manages game level order and navigation
## This is an autoload singleton that provides level management functionality

extends Node

# Level order list - Define all levels in the order they should be played
const LEVEL_ORDER: PackedStringArray = [
	"res://scenes/level1.tscn",
	"res://scenes/level2.tscn"
]

# Current level tracking
var current_level_path: String = ""

## Get the key of the next level scene
## Returns null if current level is not found or if it's the last level
func get_next_level_scene(current_scene_key: String) -> String:
	var current_index = LEVEL_ORDER.find(current_scene_key)
	
	# If it's the last level or current level not found, return empty string
	if current_index == -1 or current_index >= LEVEL_ORDER.size() - 1:
		return ""
	
	return LEVEL_ORDER[current_index + 1]


## Check if the specified level is the last level
func is_last_level() -> bool:
	var current_index = LEVEL_ORDER.find(current_level_path)
	return current_index == LEVEL_ORDER.size() - 1


## Get the key of the first level scene
## Returns empty string if no levels are defined
func get_first_level_scene() -> String:
	if LEVEL_ORDER.size() > 0:
		return LEVEL_ORDER[0]
	return ""


## Get total number of levels
func get_level_count() -> int:
	return LEVEL_ORDER.size()


## Get current level index
func get_level_index(scene_key: String) -> int:
	return LEVEL_ORDER.find(scene_key)

## Start the game from the first level
func start_game() -> void:
	if LEVEL_ORDER.size() > 0:
		current_level_path = LEVEL_ORDER[0]
		get_tree().change_scene_to_file(current_level_path)

## Go to the next level
func go_to_next_level() -> void:
	var next_level = get_next_level_scene(current_level_path)
	if next_level != "":
		current_level_path = next_level
		get_tree().change_scene_to_file(current_level_path)
	else:
		# Game complete
		get_tree().change_scene_to_file("res://scenes/game_complete.tscn")

## Restart current level
func restart_current_level() -> void:
	if current_level_path != "":
		get_tree().change_scene_to_file(current_level_path)
	else:
		# Fallback to first level if current_level_path is empty
		var first_level = get_first_level_scene()
		if first_level != "":
			current_level_path = first_level
			get_tree().change_scene_to_file(current_level_path)
		else:
			print("ERROR: No levels defined in LEVEL_ORDER")

## Go to title screen
func go_to_title() -> void:
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

## Handle player death
func player_died() -> void:
	# Ensure current_level_path is set (fallback to first level if empty)
	if current_level_path == "":
		current_level_path = get_first_level_scene()
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func restart_game() -> void:
	go_to_title()