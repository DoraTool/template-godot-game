extends CanvasLayer


# Signal emitted when player wants to proceed to next level
signal proceed_to_title_screen_requested


@onready var game_complete_title: Label = $Control/CenterContainer/VBoxContainer/GameCompleteTitle
@onready var congratulations_text: RichTextLabel = $Control/CenterContainer/VBoxContainer/CongratulationsText
@onready var press_enter_text: Label = $Control/CenterContainer/VBoxContainer/PressEnterText
@onready var glow_timer: Timer = $Control/GlowTimer
@onready var blink_timer: Timer = $Control/BlinkTimer
@onready var rainbow_timer: Timer = $Control/RainbowTimer
@onready var audio_player: AudioStreamPlayer = $Control/AudioStreamPlayer

# Animation state
var glow_expanding: bool = false
var blink_visible: bool = true
var rainbow_hue: float = 0.0
var can_return: bool = true

# Rainbow colors (matching HTML rainbow animation)
var rainbow_colors: Array[Color] = [
	Color(1, 0, 0, 1),      # Red
	Color(1, 0.5, 0, 1),    # Orange
	Color(1, 1, 0, 1),      # Yellow
	Color(0, 1, 0, 1),      # Green
	Color(0, 1, 1, 1),      # Cyan
	Color(0.5, 0, 1, 1),    # Purple
]
var rainbow_index: int = 0

func _ready() -> void:
	print("=== Game Complete Screen Ready ===")
	print("game_complete_title: ", game_complete_title)
	print("congratulations_text: ", congratulations_text)
	print("press_enter_text: ", press_enter_text)
	
	# Start animations
	_start_glow_animation()
	_start_blink_animation()
	_start_rainbow_animation()
	
	# Play game complete sound if available
	_play_game_complete_sound()

func _start_glow_animation() -> void:
	"""Start the game complete title glow animation (like glow in HTML)"""
	if glow_timer:
		glow_timer.timeout.connect(_on_glow_timer_timeout)

func _on_glow_timer_timeout() -> void:
	"""Handle glow timer timeout - toggle title scale"""
	if game_complete_title:
		glow_expanding = !glow_expanding
		
		# Animate scale change
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_IN_OUT)
		
		var target_scale = Vector2(1.15, 1.15) if glow_expanding else Vector2(1.0, 1.0)
		tween.tween_property(game_complete_title, "scale", target_scale, 0.6)

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

func _start_rainbow_animation() -> void:
	"""Start the congratulations text rainbow animation"""
	if rainbow_timer:
		rainbow_timer.timeout.connect(_on_rainbow_timer_timeout)

func _on_rainbow_timer_timeout() -> void:
	"""Handle rainbow timer timeout - cycle through rainbow colors"""
	if congratulations_text:
		# Update rainbow color
		rainbow_index = (rainbow_index + 1) % rainbow_colors.size()
		var current_color = rainbow_colors[rainbow_index]
		
		# Apply color to RichTextLabel
		var color_hex = "#%02x%02x%02x" % [
			int(current_color.r * 255),
			int(current_color.g * 255),
			int(current_color.b * 255)
		]
		
		congratulations_text.text = "[center][color=%s]Congratulations!
You have completed all levels![/color][/center]" % color_hex

func _process(_delta: float) -> void:
	"""Handle input for returning to menu"""
	if Input.is_action_just_pressed("ui_accept") and can_return:
		_return_to_menu()

func _return_to_menu() -> void:
	"""Handle returning to main menu"""
	can_return = false
    
	# Stop animations
	if glow_timer:
		glow_timer.stop()
	if blink_timer:
		blink_timer.stop()
	if rainbow_timer:
		rainbow_timer.stop()
	
	# Play click sound
	_play_click_sound()
	
	# Fade out animation
	await _play_exit_animation()
	
	# Unpause game first
	get_tree().paused = false
	
	print("Returning to main menu...")
	proceed_to_title_screen_requested.emit()

func _play_exit_animation() -> void:
	"""Play exit animation before returning to menu"""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	
	# Fade out all elements
	if game_complete_title:
		tween.tween_property(game_complete_title, "modulate:a", 0.0, 0.5)
	if congratulations_text:
		tween.tween_property(congratulations_text, "modulate:a", 0.0, 0.5)
	if press_enter_text:
		tween.tween_property(press_enter_text, "modulate:a", 0.0, 0.5)
	
	await tween.finished

func _play_game_complete_sound() -> void:
	"""Play game complete fanfare sound"""
	# TODO: Add game complete sound if available
	pass

func _play_click_sound() -> void:
	"""Play UI click sound effect"""
	# TODO: Add click sound if available
	pass