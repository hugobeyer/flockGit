extends Sprite3D

@export var color0: Color = Color(0.871, 0.826, 0.456)    # Shielded color
@export var color1: Color = Color(0.778, 0.867, 0.156)  # Full health color (swizzled with color2)
@export var color2: Color = Color(0.988, 0.156, 0.156)      # Low health color (swizzled with color1)

@export var bar_width_px: int = 100        # Width in pixels
@export var bar_height_px: int = 14        # Height in pixels

@export var shake_amount: float = 0.05     # Maximum shake offset
@export var shake_duration: float = 0.5    # Duration of the shake in seconds

var progress: float = 1.0
var is_shielded: bool = false
var initial_scale: Vector3
var health_texture: GradientTexture2D
var shake_time: float = 0.0
var original_position: Vector3

func _ready():
    # Create a unique GradientTexture2D instance for the health bar
    health_texture = GradientTexture2D.new()

    # Set width and height for the texture
    health_texture.width = bar_width_px
    health_texture.height = bar_height_px

    # Create a unique Gradient instance
    health_texture.gradient = Gradient.new()

    # Set the gradient for the health texture
    health_texture.gradient.add_point(0.0, color2)  # Low health color
    health_texture.gradient.add_point(1.0, color1)  # Full health color

    # Set the texture
    texture = health_texture

    # Set initial scale based on the texture's dimensions
    var tex_width = float(bar_width_px)
    var tex_height = float(bar_height_px)

    # Convert texture dimensions to world units (adjust scaling_factor as needed)
    var scaling_factor = 0.01  # Adjust this value based on your game's scale
    initial_scale = Vector3(tex_width * scaling_factor, tex_height * scaling_factor, 1.0)
    scale = initial_scale

    original_position = position
    update_bar()
    update_modulate()

func set_progress(value: float, shielded: bool):
    if is_shielded and not shielded:
        # Shield was just depleted, start shaking
        shake_time = shake_duration
    
    progress = clamp(value, 0.0, 1.0)
    is_shielded = shielded
    update_bar()
    update_modulate()

func update_modulate():
    if is_shielded:
        modulate = color0  # Use shielded color
    else:
        modulate = Color.WHITE  # Use default modulate to show the gradient

func update_bar():
    # Adjust the scale of the Sprite3D based on progress
    var new_scale = initial_scale
    new_scale.x *= progress
    scale = new_scale

func _process(delta):
    if shake_time > 0:
        shake_time -= delta
        var shake_offset = Vector3(
            randf_range(-1, 1) * shake_amount,
            randf_range(-1, 1) * shake_amount,
            0
        )
        position = original_position + shake_offset
        
        if shake_time <= 0:
            position = original_position
