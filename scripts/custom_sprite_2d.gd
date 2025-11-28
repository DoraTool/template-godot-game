@tool
class_name CustomSprite2D
extends Sprite2D

# CustomSprite2D 类 - 继承自 Sprite2D
# 支持根据最大宽高自动计算缩放和在最大宽高基础上再进行自定义缩放

# 导出属性，可在编辑器中设置（0 表示未设置）
@export var max_width: float = 0.0 : set = set_max_width
@export var max_height: float = 0.0 : set = set_max_height

# 在 max_width 和 max_height 的基础上，再进行自定义缩放
@export var custom_scale: Vector2 = Vector2(1.0, 1.0) : set = set_custom_scale

# 内部变量，用于跟踪内部计算缩放
var _last_calculated_base_scale: Vector2 = Vector2(1.0, 1.0)

var _last_scale_ratio: Vector2 = Vector2(1.0, 1.0)

func _ready():
    # 初始计算缩放
    calculate_scale()
    
    # 在编辑器模式下，监听纹理变化
    if Engine.is_editor_hint():
        # 连接纹理变化信号（如果存在的话）
        if not texture_changed.is_connected(_on_texture_changed):
            texture_changed.connect(_on_texture_changed)

# 获取属性列表，让 scale 属性可以被拦截
func _get_property_list():
    return [
        {
            "name": "scale",
            "type": TYPE_VECTOR2,
            "usage": PROPERTY_USAGE_DEFAULT
        }
    ]

func _process(_delta):
    # 每帧调用
    if Engine.is_editor_hint():
        var _scale_ratio = scale / _last_calculated_base_scale
        if _scale_ratio != _last_scale_ratio:
            custom_scale = _scale_ratio
            _last_scale_ratio = _scale_ratio

# 设置最大宽度
func set_max_width(value: float):
    max_width = value if value > 0 else 0.0
    calculate_scale()
    
    # 在编辑器中通知属性变化
    if Engine.is_editor_hint():
        notify_property_list_changed()

# 设置最大高度
func set_max_height(value: float):
    max_height = value if value > 0 else 0.0
    calculate_scale()
    
    # 在编辑器中通知属性变化
    if Engine.is_editor_hint():
        notify_property_list_changed()

func set_custom_scale(value: Vector2):
    custom_scale = value
    calculate_scale()
    # 在编辑器中通知属性变化
    if Engine.is_editor_hint():
        notify_property_list_changed()

# 根据最大尺寸和图片尺寸计算缩放
func calculate_scale():
    if not texture:
        return
    
    var texture_size = texture.get_size()
    if texture_size.x == 0 or texture_size.y == 0:
        return
    
    var scale_x = 1.0
    var scale_y = 1.0
    
    # 检查是否设置了最大宽度和高度（0 表示未设置）
    var has_max_width = max_width > 0
    var has_max_height = max_height > 0
    
    # 计算各自的缩放比例
    if has_max_width:
        scale_x = max_width / texture_size.x
    
    if has_max_height:
        scale_y = max_height / texture_size.y
    
    # 计算基础缩放（不包含 custom_scale）
    var base_scale: Vector2
    if has_max_width and has_max_height:
        # 都设置了：保证都满足，不要超出限制（取较小的缩放值）
        var final_scale = min(scale_x, scale_y)
        base_scale = Vector2(final_scale, final_scale)
    elif has_max_width and not has_max_height:
        # 只设置了最大宽度，保持比例
        base_scale = Vector2(scale_x, scale_x)
    elif not has_max_width and has_max_height:
        # 只设置了最大高度，保持比例
        base_scale = Vector2(scale_y, scale_y)
    else:
        # 都未设置（都为0），使用原始大小
        base_scale = Vector2(1.0, 1.0)
    
    # 记录基础缩放，用于编辑器拖拽时的计算
    _last_calculated_base_scale = base_scale
    
    # 计算最终缩放（基础缩放 * 自定义缩放）
    var final_scale_value = base_scale * custom_scale
    
    # 直接设置属性
    scale = final_scale_value

    _last_scale_ratio = scale / _last_calculated_base_scale
    
# 当纹理改变时重新计算缩放
func _on_texture_changed():
    calculate_scale()
