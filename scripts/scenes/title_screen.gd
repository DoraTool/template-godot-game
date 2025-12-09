extends Control
## Title Screen - Main menu for the game

@onready var prompt_label: Label = $CenterContainer/VBoxContainer/PromptLabel
@onready var blink_timer: Timer = $BlinkTimer

var prompt_visible: bool = true
var can_start: bool = true


func _ready() -> void:
	# Connect timer signal for blinking effect
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	

func _process(_delta: float) -> void:
	# Check for ENTER key press to start game
	if Input.is_action_just_pressed("ui_accept") and can_start:
		_on_start_game_pressed()


func _on_blink_timer_timeout() -> void:
	"""Toggle prompt label visibility for blinking effect"""
	prompt_visible = !prompt_visible
	prompt_label.visible = prompt_visible


func _on_start_game_pressed() -> void:
	"""Handle game start when ENTER is pressed"""
	can_start = false
	blink_timer.stop()
	
	# Play button click sound if available
	_play_click_sound()
	
	# Animate out before transition
	await _play_exit_animation()
	
	# Load first level
	var first_level = LevelManager.get_first_level_scene()
	if first_level != "":
		get_tree().change_scene_to_file(first_level)
	else:
		# Fallback: load loading scene if no levels defined
		push_error("No levels defined in LevelManager")
		get_tree().change_scene_to_file("res://scenes/loading.tscn")


func _play_exit_animation() -> void:
	"""Play exit animation before scene transition"""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	
	tween.tween_property(prompt_label, "modulate:a", 0.0, 0.4)
	
	await tween.finished


func _play_click_sound() -> void:
	"""Play UI click sound effect"""
	
