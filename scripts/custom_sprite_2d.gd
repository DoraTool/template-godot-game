@tool
class_name CustomSprite2D
extends Sprite2D

# CustomSprite2D class - extends Sprite2D
# Supports automatic scaling calculation based on max width/height and custom scaling on top of that

# Export properties that can be set in the editor (0 means not set)
@export var max_width: float = 0.0 : set = set_max_width
@export var max_height: float = 0.0 : set = set_max_height

# Apply custom scaling on top of max_width and max_height
@export var custom_scale: Vector2 = Vector2(1.0, 1.0) : set = set_custom_scale

# Internal variable to track internally calculated scaling
var _last_calculated_base_scale: Vector2 = Vector2(1.0, 1.0)

var _last_scale_ratio: Vector2 = Vector2(1.0, 1.0)

func _ready():
    # Initial scale calculation
    calculate_scale()
    
    # In editor mode, listen for texture changes
    if Engine.is_editor_hint():
        # Connect texture change signal (if it exists)
        if not texture_changed.is_connected(_on_texture_changed):
            texture_changed.connect(_on_texture_changed)

# Get property list to allow scale property to be intercepted
func _get_property_list():
    return [
        {
            "name": "scale",
            "type": TYPE_VECTOR2,
            "usage": PROPERTY_USAGE_DEFAULT
        }
    ]

func _process(_delta):
    # Called every frame
    if Engine.is_editor_hint():
        var _scale_ratio = scale / _last_calculated_base_scale
        if _scale_ratio != _last_scale_ratio:
            custom_scale = _scale_ratio
            _last_scale_ratio = _scale_ratio

# Set maximum width
func set_max_width(value: float):
    max_width = value if value > 0 else 0.0
    calculate_scale()
    
    # Notify property changes in editor
    if Engine.is_editor_hint():
        notify_property_list_changed()

# Set maximum height
func set_max_height(value: float):
    max_height = value if value > 0 else 0.0
    calculate_scale()
    
    # Notify property changes in editor
    if Engine.is_editor_hint():
        notify_property_list_changed()

func set_custom_scale(value: Vector2):
    custom_scale = value
    calculate_scale()
    # Notify property changes in editor
    if Engine.is_editor_hint():
        notify_property_list_changed()

# Calculate scaling based on maximum dimensions and image size
func calculate_scale():
    if not texture:
        return
    
    var texture_size = texture.get_size()
    if texture_size.x == 0 or texture_size.y == 0:
        return
    
    var scale_x = 1.0
    var scale_y = 1.0
    
    # Check if max width and height are set (0 means not set)
    var has_max_width = max_width > 0
    var has_max_height = max_height > 0
    
    # Calculate respective scaling ratios
    if has_max_width:
        scale_x = max_width / texture_size.x
    
    if has_max_height:
        scale_y = max_height / texture_size.y
    
    # Calculate base scale (excluding custom_scale)
    var base_scale: Vector2
    if has_max_width and has_max_height:
        # Both are set: ensure both are satisfied, don't exceed limits (take smaller scale value)
        var final_scale = min(scale_x, scale_y)
        base_scale = Vector2(final_scale, final_scale)
    elif has_max_width and not has_max_height:
        # Only max width is set, maintain aspect ratio
        base_scale = Vector2(scale_x, scale_x)
    elif not has_max_width and has_max_height:
        # Only max height is set, maintain aspect ratio
        base_scale = Vector2(scale_y, scale_y)
    else:
        # Neither is set (both are 0), use original size
        base_scale = Vector2(1.0, 1.0)
    
    # Record base scale for calculations during editor dragging
    _last_calculated_base_scale = base_scale
    
    # Calculate final scale (base scale * custom scale)
    var final_scale_value = base_scale * custom_scale
    
    # Set property directly
    scale = final_scale_value

    _last_scale_ratio = scale / _last_calculated_base_scale
    
# Recalculate scaling when texture changes
func _on_texture_changed():
    calculate_scale()
