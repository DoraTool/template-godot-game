extends Control
# Loading Scene - Displays loading progress and transitions to game

@onready var progress_bar: ProgressBar = $CenterContainer/VBoxContainer/ProgressBar
@onready var progress_label: Label = $CenterContainer/VBoxContainer/ProgressLabel
@onready var status_label: Label = $CenterContainer/VBoxContainer/StatusLabel
@onready var hint_label: Label = $CenterContainer/VBoxContainer/HintLabel
@onready var loading_manager: LoadingManager = $LoadingManager

var is_loading: bool = false
var loading_dots: int = 0
var loading_timer: float = 0.0

func _ready() -> void:
	print("[LoadingScreen] ✓ Initialized")
	# Connect to loading manager signals
	loading_manager.loading_progress.connect(_on_loading_progress)
	loading_manager.loading_complete.connect(_on_loading_complete)
	loading_manager.loading_failed.connect(_on_loading_failed)
	print("[LoadingScreen] ✓ Signals connected")
	
	# Start loading after a brief delay
	await get_tree().create_timer(0.3).timeout
	print("[LoadingScreen] Starting loading...")
	_start_loading()

func _start_loading() -> void:
	if is_loading:
		return
	
	is_loading = true
	status_label.text = "Loading game assets..."
	print("[LoadingScreen] _start_loading() called, total_count=%d" % loading_manager.total_count)
	loading_manager.start_loading()

func _on_loading_progress(current: int, total: int, percent: float) -> void:
	progress_bar.value = percent
	progress_label.text = "%d / %d (%.1f%%)" % [current, total, percent]

func _on_loading_complete() -> void:
	status_label.text = "Loading complete! Starting game..."
	
	# Wait a moment before transitioning
	await get_tree().create_timer(0.5).timeout
	
	# Change to game scene
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _on_loading_failed(error: String) -> void:
	status_label.text = "Loading failed: " + error
	status_label.add_theme_color_override("font_color", Color.RED)

func _process(delta: float) -> void:
	if not is_loading:
		return
	
	# Animate loading dots
	loading_timer += delta
	if loading_timer >= 0.5:
		loading_timer = 0.0
		loading_dots = (loading_dots + 1) % 4
		
		var dots = ""
		for i in range(loading_dots):
			dots += "."
		
		hint_label.text = "Loading assets from network" + dots

