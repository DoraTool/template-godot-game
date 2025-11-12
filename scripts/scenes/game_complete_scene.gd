extends Control

## Game Complete Scene Script
## Displays completion screen with overall game statistics and navigation options

@onready var restart_button: Button = $CenterContainer/VBoxContainer/ButtonHBox/RestartButton
@onready var menu_button: Button = $CenterContainer/VBoxContainer/ButtonHBox/MenuButton
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

# Overall game stats
var total_elapsed_time: float = 0.0
var total_score: int = 0
var levels_completed: int = 0
var total_levels: int = 0
var total_enemies_defeated: int = 0

func _ready() -> void:
	# Connect button signals
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Apply button styling
	_setup_button_styles()
	
	# Play victory fanfare if available
	_play_completion_sound()
	
	# Update stats display
	_update_stats_display()
	
	# Setup input handling for ESC key
	get_tree().root.gui_focus_changed.connect(_on_focus_changed)


func _setup_button_styles() -> void:
	"""Setup button hover and press effects"""
	var buttons: Array[Button] = [restart_button, menu_button]
	
	for btn in buttons:
		btn.mouse_entered.connect(_on_button_hover.bindv([btn]))
		btn.mouse_exited.connect(_on_button_unhover.bindv([btn]))
		btn.pressed.connect(_on_button_pressed.bindv([btn]))


func _on_button_hover(btn: Button) -> void:
	"""Handle button hover state"""
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.15)


func _on_button_unhover(btn: Button) -> void:
	"""Handle button unhover state"""
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15)


func _on_button_pressed(btn: Button) -> void:
	"""Handle button press state"""
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.1)


func _play_completion_sound() -> void:
	"""Play victory fanfare sound for game completion"""
	


func _update_stats_display() -> void:
	"""Update the stats labels with current values"""
	var total_time_label: Label = $CenterContainer/VBoxContainer/StatsPanel/MarginContainer/StatsVBox/TotalTimeStat/TotalTimeValue
	var total_score_label: Label = $CenterContainer/VBoxContainer/StatsPanel/MarginContainer/StatsVBox/TotalScoreStat/TotalScoreValue
	var levels_label: Label = $CenterContainer/VBoxContainer/StatsPanel/MarginContainer/StatsVBox/LevelsStat/LevelsValue
	var total_enemies_label: Label = $CenterContainer/VBoxContainer/StatsPanel/MarginContainer/StatsVBox/TotalEnemiesStat/TotalEnemiesValue
	
	# Format time (total_elapsed_time is in seconds)
	var hours: int = int(total_elapsed_time / 3600.0)
	var minutes: int = int((total_elapsed_time - hours * 3600.0) / 60.0)
	var seconds: int = int(total_elapsed_time) % 60
	
	if hours > 0:
		total_time_label.text = "%dh %dm %ds" % [hours, minutes, seconds]
	else:
		total_time_label.text = "%dm %ds" % [minutes, seconds]
	
	# Format total score with commas
	total_score_label.text = _format_number(total_score)
	
	# Display levels completed
	levels_label.text = "%d/%d" % [levels_completed, total_levels]
	
	# Display total enemies defeated
	total_enemies_label.text = str(total_enemies_defeated)


func _format_number(num: int) -> String:
	"""Format number with thousand separators"""
	var str_num = str(num)
	var formatted = ""
	var count = 0
	
	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = str_num[i] + formatted
		count += 1
	
	return formatted


func _on_focus_changed(_control: Control) -> void:
	"""Handle ESC key press"""
	if Input.is_action_just_pressed("ui_cancel"):
		_on_menu_pressed()


func _on_restart_pressed() -> void:
	"""Restart the entire game"""
	await get_tree().create_timer(0.3).timeout
	print("Restart button pressed - Restart entire game")
	# TODO: Reset game state and return to first level
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


func _on_menu_pressed() -> void:
	"""Return to main menu"""
	await get_tree().create_timer(0.3).timeout
	print("Menu button pressed - Return to title")
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


## Public method to set game completion stats
func set_completion_stats(
	total_time: float,
	total_game_score: int,
	completed_levels: int,
	max_levels: int,
	defeated_enemies: int
) -> void:
	"""
	Set the game completion stats to display
	
	Args:
		total_time: Total elapsed time in seconds
		total_game_score: Total score achieved across all levels
		completed_levels: Number of levels completed
		max_levels: Total number of levels in the game
		defeated_enemies: Total number of enemies defeated
	"""
	total_elapsed_time = total_time
	total_score = total_game_score
	levels_completed = completed_levels
	total_levels = max_levels
	total_enemies_defeated = defeated_enemies
	
	if is_node_ready():
		_update_stats_display()
