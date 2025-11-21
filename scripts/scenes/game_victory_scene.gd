extends CanvasLayer

# Signal emitted when player wants to proceed to next level
signal proceed_to_next_level_requested

@onready var victory_title: Label = $Control/CenterContainer/VBoxContainer/VictoryTitle
@onready var subtitle: Label = $Control/CenterContainer/VBoxContainer/Subtitle
@onready var press_enter_text: Label = $Control/CenterContainer/VBoxContainer/PressEnterText
# Tween will be created dynamically
@onready var blink_timer: Timer = $Control/BlinkTimer
@onready var audio_player: AudioStreamPlayer = $Control/AudioStreamPlayer

# Animation state
var blink_visible: bool = true
var can_proceed: bool = true

func _ready() -> void:
	print("=== Victory Screen Ready ===")
	print("victory_title: ", victory_title)
	print("subtitle: ", subtitle)
	print("press_enter_text: ", press_enter_text)
	print("blink_timer: ", blink_timer)
	
	# Start animations
	_start_victory_pulse_animation()
	_start_blink_animation()
	
	# Play victory sound if available
	_play_victory_sound()

func _start_victory_pulse_animation() -> void:
	"""Start the victory title pulsing animation (like victoryPulse in HTML)"""
	if victory_title:
		var tween = create_tween()
		tween.set_loops()  # Infinite loop
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		
		# Pulse scale and brightness
		tween.tween_method(_update_victory_pulse, 0.0, 1.0, 1.0)
		tween.tween_method(_update_victory_pulse, 1.0, 0.0, 1.0)

func _update_victory_pulse(progress: float) -> void:
	"""Update victory title pulse effect"""
	if victory_title:
		# Scale from 1.0 to 1.1
		var scale_value = 1.0 + (progress * 0.1)
		victory_title.scale = Vector2(scale_value, scale_value)
		
		# Brightness from 1.0 to 1.2
		var brightness = 1.0 + (progress * 0.2)
		victory_title.modulate = Color(brightness, brightness, brightness, 1.0)

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
	"""Handle input for proceeding to next level"""
	if Input.is_action_just_pressed("ui_accept") and can_proceed:
		print("UI_ACCEPT detected in victory screen!")
		_proceed_to_next_level()
	
	# Also check for ENTER key directly as fallback
	if Input.is_physical_key_pressed(KEY_ENTER) and can_proceed:
		print("ENTER key detected directly in victory screen!")
		can_proceed = false  # Prevent multiple triggers
		_proceed_to_next_level()

func _proceed_to_next_level() -> void:
	"""Handle proceeding to next level"""
	can_proceed = false
	
	print("ENTER pressed - requesting next level transition")
	
	# Stop animations
	if blink_timer:
		blink_timer.stop()
	
	# Play click sound
	_play_click_sound()
	
	# Fade out animation
	await _play_exit_animation()
	
	# Emit signal to let the scene handle the transition
	print("Emitting proceed_to_next_level_requested signal")
	proceed_to_next_level_requested.emit()

func _play_exit_animation() -> void:
	"""Play exit animation before transitioning"""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	
	# Fade out all elements
	if victory_title:
		tween.tween_property(victory_title, "modulate:a", 0.0, 0.5)
	if subtitle:
		tween.tween_property(subtitle, "modulate:a", 0.0, 0.5)
	if press_enter_text:
		tween.tween_property(press_enter_text, "modulate:a", 0.0, 0.5)
	
	await tween.finished

func _play_victory_sound() -> void:
	"""Play victory fanfare sound"""
	# TODO: Add victory sound if available
	pass

func _play_click_sound() -> void:
	"""Play UI click sound effect"""
	# TODO: Add click sound if available
	pass

## Public method to set victory stats (simplified for HTML-style design)
func set_victory_stats(time: float, score: int, enemies: int) -> void:
	"""
	Set the victory stats (not displayed in this simple design)
	
	Args:
		time: Elapsed time in seconds
		score: Total score achieved  
		enemies: Number of enemies defeated
	"""
	# Stats not displayed in this simple HTML-inspired design
	print("Victory stats - Time: %s, Score: %d, Enemies: %d" % [time, score, enemies])