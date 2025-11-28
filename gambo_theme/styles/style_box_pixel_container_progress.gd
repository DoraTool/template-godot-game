@tool
extends "res://gambo_theme/styles/style_box_base.gd"

class_name StyleBoxPixelContainerProgress

func _init() -> void:
    patch_margin_left = 6
    patch_margin_top = 6
    patch_margin_right = 6
    patch_margin_bottom = 6

    texture = load("res://gambo_theme/ui/pixel_style/container_pixel_progress_fill.png")
    
    patch_scale = 1.0
    corner_radius = 3
    pixel_corner_style = true
    voxel_size = 3
    background_color = Color(0.6, 0.1, 1.0)
    