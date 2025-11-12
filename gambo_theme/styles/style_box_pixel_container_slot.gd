@tool
extends "res://gambo_theme/styles/style_box_base.gd"

class_name StyleBoxPixelContainerSlot

func _init() -> void:
    print("StyleBoxPixelContainerSlot init")
    
    patch_margin_left = 12
    patch_margin_top = 12
    patch_margin_right = 12
    patch_margin_bottom = 12

    texture = load("res://gambo_theme/ui/pixel_style/container_pixel_slot.png")
    
    patch_scale = 1.0
    corner_radius = 9
    pixel_corner_style = true
    voxel_size = 3
    background_color = Color(0.2, 0.2, 0.3)
    