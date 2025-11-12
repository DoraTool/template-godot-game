extends StyleBox

class_name StyleBoxBase


## Button background color (tint)
@export var background_color: Color = Color(0.6, 0.1, 1, 1):
	set(value):
		background_color = value
		emit_changed()

@export var corner_radius: int = 16:
	set(value):
		corner_radius = value
		emit_changed()

## Enable pixel art style corners (blocky/voxel style)
@export var pixel_corner_style: bool = false:
	set(value):
		pixel_corner_style = value
		emit_changed()

## Voxel size in pixels (each voxel is voxel_size x voxel_size pixels)
@export var voxel_size: int = 3:
	set(value):
		voxel_size = max(1, value)  # Minimum 1 pixel
		emit_changed()

@export var texture: Texture2D = null:
	set(value):
		texture = value
		emit_changed()

@export var patch_scale: float = 1.0:
	set(value):
		patch_scale = value
		emit_changed()


# NinePatch margins (can be overridden in subclass)
var patch_margin_left: int = 0
var patch_margin_top: int = 0
var patch_margin_right: int = 0
var patch_margin_bottom: int = 0

var expand_bottom: int = 0;

func _init() -> void:
	pass

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	# TODO
	print("StyleBoxBase draw")
	# Step 1: Draw rounded corner background layer
	_draw_rounded_background(to_canvas_item, rect)
	
	if not texture:
		return
	# Step 2: Draw nine-patch texture
	_draw_nine_patch(to_canvas_item, rect)


## Draw rounded corner background
func _draw_rounded_background(to_canvas_item: RID, rect: Rect2) -> void:
	if corner_radius <= 0:
		# No corner radius, draw simple rect
		RenderingServer.canvas_item_add_rect(to_canvas_item, rect, background_color)
		return
	
	# Clamp corner radius to half of the smallest dimension
	var max_radius = min(rect.size.x, rect.size.y) / 2.0
	var radius = min(corner_radius, max_radius)
	
	# Choose drawing style based on pixel_corner_style flag
	if pixel_corner_style:
		_draw_pixel_rounded_background(to_canvas_item, rect, radius)
	else:
		_draw_smooth_rounded_background(to_canvas_item, rect, radius)

## Draw smooth rounded corner background (original style)
func _draw_smooth_rounded_background(to_canvas_item: RID, rect: Rect2, radius: float) -> void:
	# Draw main rectangles (without corners)
	# Center rectangle
	RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(
		Vector2(radius, 0),
		Vector2(rect.size.x - radius * 2, rect.size.y)
	), background_color)
	
	# Left and right rectangles
	RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(
		Vector2(0, radius),
		Vector2(rect.size.x, rect.size.y - radius * 2)
	), background_color)
	
	# Draw four rounded corners using polygons
	_draw_rounded_corner(to_canvas_item, rect, Vector2(radius, radius), radius, 180, 270, background_color)  # Top-left
	_draw_rounded_corner(to_canvas_item, rect, Vector2(rect.size.x - radius, radius), radius, 270, 360, background_color)  # Top-right
	_draw_rounded_corner(to_canvas_item, rect, Vector2(radius, rect.size.y - radius), radius, 90, 180, background_color)  # Bottom-left
	_draw_rounded_corner(to_canvas_item, rect, Vector2(rect.size.x - radius, rect.size.y - radius), radius, 0, 90, background_color)  # Bottom-right

## Draw pixel art style rounded corner background
func _draw_pixel_rounded_background(to_canvas_item: RID, rect: Rect2, radius: float) -> void:
	# Draw center rectangle (full width and height minus corners)
	RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(
		Vector2(radius, 0),
		Vector2(rect.size.x - radius * 2, rect.size.y)
	), background_color)
	
	# Draw left and right side rectangles
	RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(
		Vector2(0, radius),
		Vector2(rect.size.x, rect.size.y - radius * 2)
	), background_color)
	
	# # Draw four pixel-style corners
	_draw_pixel_corner(to_canvas_item, rect, Vector2(0, 0), radius, "top_left")  # Top-left
	_draw_pixel_corner(to_canvas_item, rect, Vector2(rect.size.x, 0), radius, "top_right")  # Top-right
	_draw_pixel_corner(to_canvas_item, rect, Vector2(0, rect.size.y), radius, "bottom_left")  # Bottom-left
	_draw_pixel_corner(to_canvas_item, rect, Vector2(rect.size.x, rect.size.y), radius, "bottom_right")  # Bottom-right

## Draw pixel art style corner (blocky/voxel style)
func _draw_pixel_corner(to_canvas_item: RID, rect: Rect2, corner_pos: Vector2, radius: float, corner_type: String) -> void:
	# Calculate how many voxels fit in the radius
	var num_voxels = int(radius / voxel_size)
	if num_voxels <= 0:
		return
	
	# Draw voxels based on corner type
	match corner_type:
		"top_left":
			var pos = corner_pos;
			for i in range(num_voxels):
				var x_offset = 0
				var y_offset = i * voxel_size
				var w = i * voxel_size
				var h = voxel_size
				RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(
					pos + Vector2(x_offset, y_offset) + Vector2((num_voxels - i) * voxel_size, 0),
					Vector2(w, h)
				), background_color)
		"top_right":
			var pos = Vector2(rect.size.x - voxel_size * num_voxels, 0);
			for i in range(num_voxels):
				var x_offset = 0
				var y_offset = i * voxel_size
				var w = i * voxel_size
				var h = voxel_size
				RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(
					pos + Vector2(x_offset, y_offset) + Vector2(0, 0),
					Vector2(w, h)
				), background_color)
		
		"bottom_left":
			var pos = Vector2(0, rect.size.y - voxel_size * num_voxels);
			for i in range(num_voxels - 1):
				var x_offset = 0
				var y_offset = i * voxel_size
				var w = (num_voxels - i - 1) * voxel_size
				var h = voxel_size
				RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(
					pos + Vector2(x_offset, y_offset) + Vector2((i + 1) * voxel_size, 0),
					Vector2(w, h)
				), background_color)
		
		
		"bottom_right":
			var pos = Vector2(rect.size.x - voxel_size * num_voxels, rect.size.y - voxel_size * num_voxels);
			for i in range(num_voxels):
				var x_offset = 0
				var y_offset = i * voxel_size
				var w = (num_voxels - i - 1) * voxel_size
				var h = voxel_size
				RenderingServer.canvas_item_add_rect(to_canvas_item, Rect2(
					pos + Vector2(x_offset, y_offset) + Vector2(0, 0),
					Vector2(w, h)
				), background_color)

## Draw a rounded corner arc (smooth style)
func _draw_rounded_corner(to_canvas_item: RID, rect: Rect2, center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color) -> void:
	var points: PackedVector2Array = []
	var segments = 8  # Number of segments for smooth curve
	
	# Add center point
	points.append(center)
	
	# Add arc points
	for i in range(segments + 1):
		var angle_rad = deg_to_rad(start_angle + (end_angle - start_angle) * i / segments)
		var point = center + Vector2(cos(angle_rad), sin(angle_rad)) * radius
		points.append(point)
	
	# Draw filled polygon
	RenderingServer.canvas_item_add_polygon(to_canvas_item, points, PackedColorArray([color]))


## Draw nine-patch texture
func _draw_nine_patch(to_canvas_item: RID, rect: Rect2) -> void:
	var tex_size = texture.get_size()
	var btn_width = rect.size.x
	var btn_height = rect.size.y
	
	# Calculate source regions (from texture)
	var left = patch_margin_left
	var top = patch_margin_top
	var right = tex_size.x - patch_margin_right
	var bottom = tex_size.y - patch_margin_bottom
	
	# Calculate minimum size required for nine-patch
	var min_width = (patch_margin_left + patch_margin_right) * patch_scale
	var min_height = (patch_margin_top + patch_margin_bottom) * patch_scale
	
	# Calculate overall scale factors if button is smaller than minimum size
	var scale_x = 1.0
	var scale_y = 1.0
	
	if btn_width < min_width and min_width > 0:
		scale_x = btn_width / min_width
	
	if btn_height < min_height and min_height > 0:
		scale_y = btn_height / min_height
	
	# Calculate destination regions (on button) with overall scale applied
	var dest_left = patch_margin_left * patch_scale * scale_x
	var dest_top = patch_margin_top * patch_scale * scale_y
	var dest_right = btn_width - patch_margin_right * patch_scale * scale_x
	var dest_bottom = btn_height - patch_margin_bottom * patch_scale * scale_y
	
	# Draw 9 patches:
	# [0,0] [1,0] [2,0]   (top-left, top-center, top-right)
	# [0,1] [1,1] [2,1]   (middle-left, center, middle-right)
	# [0,2] [1,2] [2,2]   (bottom-left, bottom-center, bottom-right)
	
	# Top-left corner
	RenderingServer.canvas_item_add_texture_rect_region(
		to_canvas_item, 
		Rect2(0, 0, dest_left, dest_top), 
		texture, 
		Rect2(0, 0, left, top)
	)
	# Top-center (stretch horizontally)
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(dest_left, 0, dest_right - dest_left, dest_top), texture, Rect2(left, 0, right - left, top))
	   
	# Top-right corner
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(dest_right, 0, btn_width - dest_right, dest_top), texture, Rect2(right, 0, tex_size.x - right, top))
	 
	# Middle-left (stretch vertically)
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(0, dest_top, dest_left, dest_bottom - dest_top), texture, Rect2(0, top, left, bottom - top))
	  
	# Center (stretch both)
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(dest_left, dest_top, dest_right - dest_left, dest_bottom - dest_top), texture, Rect2(left, top, right - left, bottom - top))
	
	# Middle-right (stretch vertically)
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(dest_right, dest_top, btn_width - dest_right, dest_bottom - dest_top), texture, Rect2(right, top, tex_size.x - right, bottom - top))
	
	# Bottom-left corner
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(0, dest_bottom, dest_left, btn_height - dest_bottom), texture, Rect2(0, bottom, left, tex_size.y - bottom))
	
	# Bottom-center (stretch horizontally)
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(dest_left, dest_bottom, dest_right - dest_left, btn_height - dest_bottom), texture, Rect2(left, bottom, right - left, tex_size.y - bottom))
	  
	# Bottom-right corner
	RenderingServer.canvas_item_add_texture_rect_region(to_canvas_item, Rect2(dest_right, dest_bottom, btn_width - dest_right, btn_height - dest_bottom), texture, Rect2(right, bottom, tex_size.x - right, tex_size.y - bottom))
	 
