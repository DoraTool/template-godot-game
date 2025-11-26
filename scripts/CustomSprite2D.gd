@tool
class_name CustomSprite2D
extends Sprite2D

# CustomSprite2D class - extends Sprite2D
# Supports automatic scale calculation based on max width/height and additional custom scaling

# Export properties that can be set in the editor (0 means not set)
@export var max_width: float = 0.0 : set = set_max_width
@export var max_height: float = 0.0 : set = set_max_height

# Apply custom scale on top of max_width and max_height scaling
@export var custom_scale: Vector2 = Vector2(1.0, 1.0) : set = set_custom_scale

func _ready():
    # Initial scale calculation
    calculate_scale()
    
    # In editor mode, listen for texture changes
    if Engine.is_editor_hint():
        # Connect texture change signal (if it exists)
        if not texture_changed.is_connected(_on_texture_changed):
            texture_changed.connect(_on_texture_changed)

func _process(_delta):
    # Called every frame
    pass

# Set maximum width
func set_max_width(value: float):
    max_width = value if value > 0 else 0.0
    calculate_scale()
    
    # Notify property change in editor
    if Engine.is_editor_hint():
        notify_property_list_changed()

# Set maximum height
func set_max_height(value: float):
    max_height = value if value > 0 else 0.0
    calculate_scale()
    
    # Notify property change in editor
    if Engine.is_editor_hint():
        notify_property_list_changed()

func set_custom_scale(value: Vector2):
    custom_scale = value
    calculate_scale()
    
    # Notify property change in editor
    if Engine.is_editor_hint():
        notify_property_list_changed()

# Calculate scale based on max dimensions and texture size
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
    
    # Calculate respective scale ratios
    if has_max_width:
        scale_x = max_width / texture_size.x
    
    if has_max_height:
        scale_y = max_height / texture_size.y
    
    # Determine final scale based on settings
    if has_max_width and has_max_height:
        # Both set: ensure both constraints are met, don't exceed limits (use smaller scale)
        var final_scale = min(scale_x, scale_y)
        scale = Vector2(final_scale, final_scale)
    elif has_max_width and not has_max_height:
        # Only max width set, maintain aspect ratio
        scale = Vector2(scale_x, scale_x) * custom_scale
    elif not has_max_width and has_max_height:
        # Only max height set, maintain aspect ratio
        scale = Vector2(scale_y, scale_y) * custom_scale
    else:
        # Neither set (both are 0), use original size
        scale = Vector2(1.0, 1.0) * custom_scale
    
    # Show debug info in editor as well
    if Engine.is_editor_hint():
        print("Editor - Texture size: ", texture_size, " Max size: (", max_width, ", ", max_height, ") Scale: ", scale)
    
# Recalculate scale when texture changes
func _on_texture_changed():
    calculate_scale()
