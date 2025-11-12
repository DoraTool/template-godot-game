@tool
extends "res://gambo_theme/styles/style_box_base.gd"

class_name StyleBoxPixelContainerClickable

func _init() -> void:
    print("StyleBoxPixelContainerClickable init")
    
    patch_margin_left = 12
    patch_margin_top = 12
    patch_margin_right = 12
    patch_margin_bottom = 18

    texture = load("res://gambo_theme/ui/pixel_style/container_pixel_clickable.png")
    
    patch_scale = 1.0
    corner_radius = 9
    pixel_corner_style = true
    voxel_size = 3
    background_color = Color(0.6, 0.1, 1.0)
    content_margin_bottom = 6