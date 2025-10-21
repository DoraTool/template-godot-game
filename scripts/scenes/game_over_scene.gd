extends Control

## Game Over Scene Script
## Displays game failure screen with attempt statistics and navigation options

@onready var retry_button: Button = $CenterContainer/VBoxContainer/ButtonHBox/RetryButton
@onready var menu_button: Button = $CenterContainer/VBoxContainer/ButtonHBox/MenuButton
@onready var audio_player: AudioStreamPlayer = $AudioStreamPlayer

# Game over stats
var level_number: int = 1
var time_survived: float = 0.0
var score_before_defeat: int = 0

func _ready() -> void:
	# Connect button signals
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	
	# Apply button styling
	_setup_button_styles()
	
	# Play game over sound if available
	_play_gameover_sound()
	
	# Update stats display
	_update_stats_display()
	
	# Setup input handling for ESC key
	get_tree().root.gui_focus_changed.connect(_on_focus_changed)


func _setup_button_styles() -> void:
	"""Setup button hover and press effects"""
	var buttons: Array[Button] = [retry_button, menu_button]
	
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


func _play_gameover_sound() -> void:
	"""Play game over sound effect"""
	if NetworkResourceLoader.is_cached("game_over_sound"):
		var sound = NetworkResourceLoader.get_cached_resource("game_over_sound")
		if sound:
			audio_player.stream = sound
			audio_player.play()


func _update_stats_display() -> void:
	"""Update the stats labels with current values"""
	var level_label: Label = $CenterContainer/VBoxContainer/StatsPanel/MarginContainer/StatsVBox/LevelStat/LevelValue
	var time_label: Label = $CenterContainer/VBoxContainer/StatsPanel/MarginContainer/StatsVBox/TimeStat/TimeValue
	var score_label: Label = $CenterContainer/VBoxContainer/StatsPanel/MarginContainer/StatsVBox/ScoreStat/ScoreValue
	
	# Display level number
	level_label.text = str(level_number)
	
	# Format time (time_survived is in seconds)
	var minutes: int = int(time_survived / 60.0)
	var seconds: int = int(time_survived) % 60
	time_label.text = "%dm %ds" % [minutes, seconds]
	
	# Format score with commas
	score_label.text = _format_number(score_before_defeat)


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


func _on_retry_pressed() -> void:
	"""Retry the current level"""
	await get_tree().create_timer(0.3).timeout
	print("Retry button pressed - Restart level %d" % level_number)
	# TODO: Implement level restart logic
	# For now, reload the game over scene (placeholder behavior)
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")


func _on_menu_pressed() -> void:
	"""Return to main menu"""
	await get_tree().create_timer(0.3).timeout
	print("Menu button pressed - Return to title")
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")


## Public method to set game over stats from game level
func set_gameover_stats(level: int, time_survived_seconds: float, score: int) -> void:
	"""
	Set the game over stats to display
	
	Args:
		level: Current level number
		time_survived_seconds: Time survived in seconds
		score: Score earned before defeat
	"""
	level_number = level
	time_survived = time_survived_seconds
	score_before_defeat = score
	
	if is_node_ready():
		_update_stats_display()
