@tool
extends "res://gambo_theme/styles/style_box_base.gd"

class_name StyleBox3DContainerClickable

func _init() -> void:
	patch_margin_left = 42
	patch_margin_top = 42
	patch_margin_right = 60
	patch_margin_bottom = 42

	texture = load("res://gambo_theme/ui/3d_style/container_3d_clickable.png")
	
	patch_scale = 0.33
	corner_radius = 16
	pixel_corner_style = false
	background_color = Color(0.6, 0.1, 1)

	content_margin_bottom = 6
	# expand_bottom = 6
	pass
