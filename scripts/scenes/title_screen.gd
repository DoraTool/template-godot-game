extends Control
## Title Screen - Main menu for the game

@onready var game_title: Label = $CenterContainer/VBoxContainer/GameTitle
@onready var subtitle_label: Label = $CenterContainer/VBoxContainer/SubtitleLabel
@onready var prompt_label: Label = $CenterContainer/VBoxContainer/PromptLabel
@onready var blink_timer: Timer = $BlinkTimer

var prompt_visible: bool = true
var can_start: bool = true


func _ready() -> void:
	# Load game title logo if available
	# if NetworkResourceLoader.is_cached("game_title"):
	# 	var texture = NetworkResourceLoader.get_cached_resource("game_title")
	# 	if texture:
	# 		logo_sprite.texture = texture
	
	# Connect timer signal for blinking effect
	blink_timer.timeout.connect(_on_blink_timer_timeout)
	
	# Add initial animation for title
	_play_title_animation()


func _play_title_animation() -> void:
	"""Play entrance animation for title and subtitle"""
	# Fade in title label
	game_title.modulate.a = 0.0
	var title_tween = create_tween()
	title_tween.set_trans(Tween.TRANS_SINE)
	title_tween.set_ease(Tween.EASE_OUT)
	title_tween.tween_property(game_title, "modulate:a", 1.0, 0.5)
	
	# Fade in subtitle with delay
	await get_tree().create_timer(0.2).timeout
	subtitle_label.modulate.a = 0.0
	var subtitle_tween = create_tween()
	subtitle_tween.set_trans(Tween.TRANS_SINE)
	subtitle_tween.set_ease(Tween.EASE_OUT)
	subtitle_tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.5)


func _process(_delta: float) -> void:
	# Check for ENTER key press to start game
	if Input.is_action_just_pressed("ui_accept") and can_start:
		_on_start_game_pressed()
	
	# Check for P key press to jump to Level 2 (debug/shortcut)
	if Input.is_key_pressed(KEY_P) and can_start:
		_on_level2_pressed()
	
	# Check for L key press to jump to Level 3 (debug/shortcut)
	if Input.is_key_pressed(KEY_L) and can_start:
		_on_level3_pressed()


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


func _on_level2_pressed() -> void:
	"""Handle P key press to jump directly to Level 2"""
	can_start = false
	blink_timer.stop()
	
	# Play button click sound if available
	_play_click_sound()
	
	# Animate out before transition
	await _play_exit_animation()
	
	# Jump directly to Level 2
	get_tree().change_scene_to_file("res://scenes/level2.tscn")


func _on_level3_pressed() -> void:
	"""Handle L key press to jump directly to Level 3"""
	can_start = false
	blink_timer.stop()
	
	# Play button click sound if available
	_play_click_sound()
	
	# Animate out before transition
	await _play_exit_animation()
	
	# Jump directly to Level 3
	get_tree().change_scene_to_file("res://scenes/level3.tscn")


func _play_exit_animation() -> void:
	"""Play exit animation before scene transition"""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN)
	
	# Fade out all content
	tween.tween_property(game_title, "modulate:a", 0.0, 0.4)
	tween.tween_property(subtitle_label, "modulate:a", 0.0, 0.4)
	tween.tween_property(prompt_label, "modulate:a", 0.0, 0.4)
	
	await tween.finished


func _play_click_sound() -> void:
	"""Play UI click sound effect"""
	if NetworkResourceLoader.is_cached("ui_click"):
		var sound = NetworkResourceLoader.get_cached_resource("ui_click")
		if sound:
			var audio_player = AudioStreamPlayer.new()
			audio_player.stream = sound
			audio_player.bus = &"Master"
			add_child(audio_player)
			audio_player.play()
			
			# Clean up after sound finishes
			await audio_player.finished
			audio_player.queue_free()
