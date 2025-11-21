extends CanvasLayer

## Game Over Scene Script - HTML-inspired design
## Displays game over screen with danger blink and restart functionality

@onready var game_over_title: Label = $Control/CenterContainer/VBoxContainer/GameOverTitle
@onready var failure_text: Label = $Control/CenterContainer/VBoxContainer/FailureText
@onready var press_enter_text: Label = $Control/CenterContainer/VBoxContainer/PressEnterText
@onready var blink_timer: Timer = $Control/BlinkTimer
@onready var danger_blink_timer: Timer = $Control/DangerBlinkTimer
@onready var audio_player: AudioStreamPlayer = $Control/AudioStreamPlayer

# Animation state
var blink_visible: bool = true
var danger_bright: bool = false
var can_restart: bool = true

func _ready() -> void:
	print("=== Game Over Screen Ready ===")
	print("game_over_title: ", game_over_title)
	print("failure_text: ", failure_text)
	print("press_enter_text: ", press_enter_text)
	
	# Start animations
	_start_danger_blink_animation()
	_start_blink_animation()
	
	# Play game over sound if available
	_play_game_over_sound()

func _start_danger_blink_animation() -> void:
	"""Start the game over title danger blinking animation (like dangerBlink in HTML)"""
	if danger_blink_timer:
		danger_blink_timer.timeout.connect(_on_danger_blink_timer_timeout)

func _on_danger_blink_timer_timeout() -> void:
	"""Handle danger blink timer timeout - toggle game over title brightness and opacity"""
	if game_over_title:
		danger_bright = !danger_bright
		
		# Animate opacity and brightness change
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		
		if danger_bright:
			# Bright state: opacity 1.0, brightness 1.2
			tween.tween_method(_update_danger_effect, 0.0, 1.0, 0.25)
		else:
			# Dim state: opacity 0.5, brightness 1.0
			tween.tween_method(_update_danger_effect, 1.0, 0.0, 0.25)

func _update_danger_effect(progress: float) -> void:
	"""Update danger blink effect on game over title"""
	if game_over_title:
		# Opacity from 0.5 to 1.0
		var opacity = 0.5 + (progress * 0.5)
		
		# Brightness from 1.0 to 1.2
		var brightness = 1.0 + (progress * 0.2)
		
		game_over_title.modulate = Color(brightness, brightness, brightness, opacity)

func _start_blink_animation() -> void:
	"""Start the press enter text blinking animation"""
	if blink_timer:
		blink_timer.timeout.connect(_on_blink_timer_timeout)

func _on_blink_timer_timeout() -> void:
	"""Handle blink timer timeout - toggle press enter text visibility"""
	if press_enter_text:
		blink_visible = !blink_visible
		
		# Animate opacity change
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		
		var target_alpha = 1.0 if blink_visible else 0.3
		tween.tween_property(press_enter_text, "modulate:a", target_alpha, 0.4)

func _process(_delta: float) -> void:
	"""Handle input for restarting game"""
	if Input.is_action_just_pressed("ui_accept") and can_restart:
		_restart_game()

func _restart_game() -> void:
	"""Handle game restart"""
	can_restart = false
	
	print("ENTER pressed - restarting game")
	
	# Stop animations
	if blink_timer:
		blink_timer.stop()
	if danger_blink_timer:
		danger_blink_timer.stop()
	
	# Play click sound
	_play_click_sound()
	
	# Fade out animation
	await _play_exit_animation()
	
	# Unpause game first
	get_tree().paused = false
	
	# Restart current level directly (no need to queue_free since we're changing scenes)
	print("Restarting current level...")
	LevelManager.restart_current_level()

func _play_exit_animation() -> void:
	"""Play exit animation before restarting"""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	
	# Fade out all elements
	if game_over_title:
		tween.tween_property(game_over_title, "modulate:a", 0.0, 0.5)
	if failure_text:
		tween.tween_property(failure_text, "modulate:a", 0.0, 0.5)
	if press_enter_text:
		tween.tween_property(press_enter_text, "modulate:a", 0.0, 0.5)
	
	await tween.finished

func _play_game_over_sound() -> void:
	"""Play game over sound"""
	# TODO: Add game over sound if available
	pass

func _play_click_sound() -> void:
	"""Play UI click sound effect"""
	# TODO: Add click sound if available
	pass