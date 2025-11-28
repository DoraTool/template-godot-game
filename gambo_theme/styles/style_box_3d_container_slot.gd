@tool
extends "res://gambo_theme/styles/style_box_base.gd"

class_name StyleBox3DContainerSlot

func _init() -> void:
    patch_margin_left = 36
    patch_margin_top = 36
    patch_margin_right = 36
    patch_margin_bottom = 36

    texture = load("res://gambo_theme/ui/3d_style/container_3d_slot.png")
    
    patch_scale = 0.33
    corner_radius = 16
    pixel_corner_style = false
    background_color = Color(0.2, 0.2, 0.3)
    pass