@tool
class_name SizedSprite2D
extends Sprite2D

## A Sprite2D component that automatically scales based on specified dimensions
## Supports two scaling modes: CONTAIN (fit proportionally) and COVER (fill proportionally)

## Target width, 0 means no width constraint
@export var width: float = 0.0 : set = set_width
## Target height, 0 means no height constraint
@export var height: float = 0.0 : set = set_height
## Scaling mode, see Mode enum
@export var mode: Mode = Mode.CONTAIN : set = set_mode

## Scaling mode enumeration
enum Mode {
    CONTAIN,  ## Fit proportionally: image is fully displayed within specified dimensions, may have empty areas
    COVER     ## Fill proportionally: image fills the specified dimensions, may be partially cropped
}

## Called when the node is initialized
func _ready():
    # Calculate initial scale
    calculate_scale()
    
    # Connect texture change signal in editor for real-time preview
    if Engine.is_editor_hint():
        if not texture_changed.is_connected(_on_texture_changed):
            texture_changed.connect(_on_texture_changed)

## Custom property list for displaying calculated scale values in the editor
func _get_property_list():
    return [
        {
            "name": "scale",
            "type": TYPE_VECTOR2,
            "usage": PROPERTY_USAGE_DEFAULT
        }
    ]


## Setter method for target width
## @param value: Target width value, set to 0 if <= 0 (no width constraint)
func set_width(value: float):
    width = value if value > 0 else 0.0
    calculate_scale()
    
    # Notify property changes in editor for real-time updates
    if Engine.is_editor_hint():
        notify_property_list_changed()

## Setter method for target height
## @param value: Target height value, set to 0 if <= 0 (no height constraint)
func set_height(value: float):
    height = value if value > 0 else 0.0
    calculate_scale()
    
    # Notify property changes in editor for real-time updates
    if Engine.is_editor_hint():
        notify_property_list_changed()

## Setter method for scaling mode
## @param value: Scaling mode, see Mode enum
func set_mode(value: Mode):
    mode = value
    calculate_scale()
    # Notify property changes in editor for real-time updates
    if Engine.is_editor_hint():
        notify_property_list_changed()

## Calculate the final scale value based on the set width, height, and mode
func calculate_scale():
    # Cannot calculate scale without texture
    if not texture:
        return
    
    # Get original texture dimensions
    var texture_size = texture.get_size()
    if texture_size.x == 0 or texture_size.y == 0:
        return
    
    # Initialize scale ratios
    var scale_x = 1.0
    var scale_y = 1.0
    
    # Check if width and height constraints are set
    var has_width = width > 0
    var has_height = height > 0
    
    # Calculate X-axis scale ratio based on target width
    if has_width:
        scale_x = width / texture_size.x
    
    # Calculate Y-axis scale ratio based on target height
    if has_height:
        scale_y = height / texture_size.y
    
    # When both width and height are set, choose final scale ratio based on mode
    var base_scale: Vector2
    if has_width and has_height:
        if mode == Mode.CONTAIN:
            # CONTAIN mode: choose smaller scale ratio to ensure image is fully displayed within target area
            var final_scale = min(scale_x, scale_y)
            base_scale = Vector2(final_scale, final_scale)
        elif mode == Mode.COVER:
            # COVER mode: choose larger scale ratio to ensure image fills the target area
            var final_scale = max(scale_x, scale_y)
            base_scale = Vector2(final_scale, final_scale)

        # Apply the calculated scale value
        scale = base_scale

## Callback function when texture changes, recalculate scale
func _on_texture_changed():
    calculate_scale()
