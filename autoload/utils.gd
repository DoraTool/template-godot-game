extends Node

## Godot 版本的工具函数
## 用于处理精灵的原点、缩放、碰撞体偏移等

## 重置精灵的原点和碰撞体偏移
## 根据当前动画配置自动调整精灵的原点和碰撞体位置
## @param sprite: AnimatedSprite2D 或 Sprite2D 节点
## @param animations_data: 动画配置数据 (Dictionary)
## @param collision_shape: CollisionShape2D 节点 (可选)
## @param facing_direction: 朝向方向 ("up", "down", "left", "right")
func reset_origin_and_offset(
	sprite: Node2D, 
	animations_data: Dictionary, 
	collision_shape: CollisionShape2D = null,
	facing_direction: String = "right"
) -> void:
	# 检查场景是否激活
	if not sprite.is_inside_tree():
		return
	
	# 验证 animations_data
	if animations_data.is_empty():
		push_error("animations_data is empty, please provide valid animation data")
		return
	
	if not animations_data.has("anims"):
		push_error("animations_data must have 'anims' key")
		return
	
	# 默认原点值
	var base_origin_x = 0.5
	var base_origin_y = 1.0
	
	# 获取当前动画的原点配置
	var current_anim_name = ""
	if sprite is AnimatedSprite2D:
		current_anim_name = sprite.animation
	elif sprite.has_method("get_current_animation"):
		current_anim_name = sprite.get_current_animation()
	
	if current_anim_name != "":
		var anims = animations_data.get("anims", [])
		for anim_config in anims:
			if anim_config.get("key", "") == current_anim_name:
				base_origin_x = anim_config.get("originX", 0.5)
				base_origin_y = anim_config.get("originY", 1.0)
				break
	
	# 验证朝向方向
	if facing_direction not in ["up", "down", "left", "right"]:
		push_error("facing_direction only supports: up, down, left, right")
		return
	
	# 根据朝向调整原点
	var anim_origin_x = (1.0 - base_origin_x) if facing_direction == "left" else base_origin_x
	var anim_origin_y = base_origin_y
	
	# 设置精灵的原点 (通过 offset)
	# Godot 中 Sprite2D 默认 centered = true, 原点在中心 (0.5, 0.5)
	# 我们需要通过 offset 来调整
	var texture_size = Vector2.ZERO
	if sprite is AnimatedSprite2D:
		var frames = sprite.sprite_frames
		if frames and frames.has_animation(current_anim_name):
			var frame_count = frames.get_frame_count(current_anim_name)
			if frame_count > 0:
				var frame_texture = frames.get_frame_texture(current_anim_name, sprite.frame)
				if frame_texture:
					texture_size = frame_texture.get_size()
	elif sprite is Sprite2D:
		if sprite.texture:
			texture_size = sprite.texture.get_size()

	if texture_size != Vector2.ZERO:
		# 计算需要的 offset
		# Godot 的 offset 是相对于精灵中心的偏移
		sprite.centered = false
		sprite.offset = Vector2(
			-texture_size.x * anim_origin_x,
			-texture_size.y * anim_origin_y
		)
	
	# # 调整碰撞体偏移，使其底部中心对齐动画帧的原点
	# if collision_shape and collision_shape.shape:
	# 	var shape = collision_shape.shape
	# 	var unscaled_body_size = Vector2.ZERO
		
	# 	# 获取碰撞体的未缩放尺寸
	# 	if shape is RectangleShape2D:
	# 		unscaled_body_size = shape.size / sprite.scale
	# 	elif shape is CircleShape2D:
	# 		var diameter = shape.radius * 2.0 / sprite.scale.x
	# 		unscaled_body_size = Vector2(diameter, diameter)
	# 	elif shape is CapsuleShape2D:
	# 		unscaled_body_size = Vector2(
	# 			shape.radius * 2.0 / sprite.scale.x,
	# 			shape.height / sprite.scale.y
	# 		)
		
	# 	# 计算碰撞体偏移
	# 	var sprite_size = texture_size * sprite.scale
	# 	collision_shape.position = Vector2(
	# 		sprite_size.x * anim_origin_x - unscaled_body_size.x * sprite.scale.x / 2.0,
	# 		sprite_size.y * anim_origin_y - unscaled_body_size.y * sprite.scale.y
	# 	)


## 初始化精灵的缩放、原点和碰撞体
## 所有 Arcade Sprite 构造函数必须通过此函数初始化原点、缩放、大小、偏移
## @param sprite: Sprite2D 或 AnimatedSprite2D 节点
## @param origin: 原点位置 Vector2(x, y)，范围 0.0-1.0
## @param max_display_width: 最大显示宽度 (可选，默认 NAN 表示未设置)
## @param max_display_height: 最大显示高度 (可选，默认 NAN 表示未设置)
## @param body_width_factor: 碰撞体宽度相对于显示宽度的比例 (可选，默认 0.9)
## @param body_height_factor: 碰撞体高度相对于显示高度的比例 (可选，默认 0.9)
func init_scale(
	sprite: Node2D,
	origin: Vector2,
	collision_shape: CollisionShape2D = null,
	max_display_width: float = NAN,
	max_display_height: float = NAN,
	body_width_factor: float = 0.9,
	body_height_factor: float = 0.9
) -> void:
	# 获取纹理尺寸
	var texture_size = Vector2.ZERO
	if sprite is AnimatedSprite2D:
		var frames = sprite.sprite_frames
		if frames and frames.has_animation(sprite.animation):
			var frame_count = frames.get_frame_count(sprite.animation)
			if frame_count > 0:
				var frame_texture = frames.get_frame_texture(sprite.animation, 0)
				if frame_texture:
					texture_size = frame_texture.get_size()
	elif sprite is Sprite2D:
		if sprite.texture:
			texture_size = sprite.texture.get_size()
	
	if texture_size == Vector2.ZERO:
		push_error("Cannot get texture size from sprite")
		return
	
	# 设置原点 (通过 offset)
	sprite.centered = false
	sprite.offset = Vector2(
		-texture_size.x * origin.x,
		-texture_size.y * origin.y
	)
	
	# 计算显示尺寸和缩放
	var display_scale: float
	var display_width: float
	var display_height: float
	
	# 验证参数并计算缩放（完全按照原版 TypeScript 逻辑）
	if not is_nan(max_display_height) and not is_nan(max_display_width):
		# 同时指定了宽高，按比例缩放
		if texture_size.y / texture_size.x > max_display_height / max_display_width:
			display_height = max_display_height
			display_scale = max_display_height / texture_size.y
			display_width = texture_size.x * display_scale
		else:
			display_width = max_display_width
			display_scale = max_display_width / texture_size.x
			display_height = texture_size.y * display_scale
	elif not is_nan(max_display_height):
		# 只指定高度
		display_height = max_display_height
		display_scale = max_display_height / texture_size.y
		display_width = texture_size.x * display_scale
	elif not is_nan(max_display_width):
		# 只指定宽度
		display_width = max_display_width
		display_scale = max_display_width / texture_size.x
		display_height = texture_size.y * display_scale
	else:
		push_error("initScale input parameter maxDisplayHeight and maxDisplayWidth cannot be undefined at the same time")
		return
	
	# 设置缩放
	sprite.scale = Vector2(display_scale, display_scale)
	
	# 计算碰撞体尺寸（即使 body_width_factor 或 body_height_factor 是 NAN，也计算）
	var display_body_width = display_width * body_width_factor
	var display_body_height = display_height * body_height_factor
	
	# 设置碰撞体（只有当找到 collision_shape 且 shape 存在时）
	if collision_shape and collision_shape.shape:
		
		var shape = collision_shape.shape

		if shape is RectangleShape2D:
			shape.size = Vector2(display_body_width, display_body_height)
		elif shape is CapsuleShape2D:
			shape.radius = display_body_width / 2.0
			shape.height = display_body_height
		elif shape is CircleShape2D:
			shape.radius = min(display_body_width, display_body_height) / 2.0
		
		collision_shape.position = Vector2(0, -display_body_height * 0.5)

