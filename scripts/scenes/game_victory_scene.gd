extends Control

## Game Victory Scene Script
## Displays victory screen with stats and navigation options

@onready var next_level_button: Button = $CenterContainer/VBoxContainer/ButtonHBox/NextLevelButton
@onready var retry_button: Button = $CenterContainer/VBoxContainer/ButtonHBox/RetryButton
@onready var menu_button: Button = $CenterContainer/VBoxContainer/ButtonHBox/MenuButton
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

# Victory stats
var elapsed_time: float = 0.0
var total_score: int = 0
var enemies_defeated: int = 0

func _ready() -> void:
	# Connect button signals
	next_level_button.pressed.connect(_on_next_level_pressed)
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Apply button styling
	_setup_button_styles()
	
	# Play victory fanfare if available
	_play_victory_sound()
	
	# Update stats display
	_update_stats_display()
	
	# Setup input handling for ESC key
	get_tree().root.gui_focus_changed.connect(_on_focus_changed)


func _setup_button_styles() -> void:
	"""Setup button hover and press effects"""
	var buttons: Array[Button] = [next_level_button, retry_button, menu_button]
	
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


func _play_victory_sound() -> void:
	"""Play victory fanfare sound"""
	


func _update_stats_display() -> void:
	"""Update the stats labels with current values"""
	var time_label: Label = $CenterContainer/VBoxContainer/StatsPanel/MarginContainer/StatsVBox/TimeStat/TimeValue
	var score_label: Label = $CenterContainer/VBoxContainer/StatsPanel/MarginContainer/StatsVBox/ScoreStat/ScoreValue
	var enemies_label: Label = $CenterContainer/VBoxContainer/StatsPanel/MarginContainer/StatsVBox/EnemiesStat/EnemiesValue
	
	# Format time (elapsed_time is in seconds)
	var minutes: int = int(elapsed_time / 60.0)
	var seconds: int = int(elapsed_time) % 60
	time_label.text = "%dm %ds" % [minutes, seconds]
	
	# Format score with commas
	score_label.text = _format_number(total_score)
	
	# Display enemies defeated
	enemies_label.text = str(enemies_defeated)


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


func _on_next_level_pressed() -> void:
	"""Navigate to next level"""
	await get_tree().create_timer(0.3).timeout
	print("Next Level button pressed - Load next level")
	LevelManager.go_to_next_level()

func _on_retry_pressed() -> void:
	"""Retry current level"""
	await get_tree().create_timer(0.3).timeout
	# TODO: Reload current level scene
	print("Retry button pressed - Restart level")
	LevelManager.restart_current_level()


func _on_menu_pressed() -> void:
	"""Return to main menu"""
	await get_tree().create_timer(0.3).timeout
	print("Menu button pressed - Return to title")
	LevelManager.go_to_title()


## Public method to set victory stats from game level
func set_victory_stats(time: float, score: int, enemies: int) -> void:
	"""
	Set the victory stats to display
	
	Args:
		time: Elapsed time in seconds
		score: Total score achieved
		enemies: Number of enemies defeated
	"""
	elapsed_time = time
	total_score = score
	enemies_defeated = enemies
	
	if is_node_ready():
		_update_stats_display()
