extends Node2D


var enabled := true

func _ready():
	# 启用内置可视化
	ProjectSettings.set_setting("debug/settings/visible_collision_shapes", true)
	ProjectSettings.set_setting("debug/settings/visible_canvas_item_rects", true)
	set_process(true)
	queue_redraw()

func _process(_delta):
	if enabled:
		queue_redraw()

func _draw():
	if not enabled:
		return

	print("_draw DebugVisualizer: ", enabled)

	# 绘制所有 Sprite2D 边框
	for sprite in get_tree().get_nodes_in_group("debug_sprites"):
		
		if sprite is Sprite2D and sprite.texture:
			var size = sprite.texture.get_size() * sprite.scale
			var top_left = sprite.global_position - size / 2
			draw_rect(Rect2(to_local(top_left), size), Color(1, 0, 0, 0.8), false, 2)

func toggle():
	enabled = !enabled
	print("DebugVisualizer: ", enabled)
	queue_redraw()
