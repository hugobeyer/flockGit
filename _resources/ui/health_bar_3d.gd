extends Sprite3D

@export var color0: Color = Color.GREEN    # Shielded color
@export var color1: Color = Color.YELLOW   # Full health color
@export var color2: Color = Color.RED      # Low health color
@export var color3: Color = Color.YELLOW      # Low health color

@export var bar_width_px: int = 100        # Width in pixels
@export var bar_height_px: int = 14        # Height in pixels

var progress: float = 1.0
var is_shielded: bool = true
var initial_scale: Vector3
var shielded_texture: GradientTexture2D
var health_texture: GradientTexture2D

func _ready():
    # Create unique GradientTexture2D instances for shielded and health states
    shielded_texture = GradientTexture2D.new()
    health_texture = GradientTexture2D.new()

    # Set width and height for both textures
    shielded_texture.width = bar_width_px
    shielded_texture.height = bar_height_px
    health_texture.width = bar_width_px
    health_texture.height = bar_height_px

    # Create unique Gradient instances
    shielded_texture.gradient = Gradient.new()
    health_texture.gradient = Gradient.new()

    # Set the gradient for the shielded texture (solid color0)
    shielded_texture.gradient.add_point(0.0, color0)
    shielded_texture.gradient.add_point(1.0, color0)


    # Set the gradient for the health texture (gradient from color1 to color2)
    health_texture.gradient.add_point(0.0, color1)
    health_texture.gradient.add_point(1.0, color1)

    # Set initial texture based on shielded state
    texture = shielded_texture if is_shielded else health_texture

    # Set initial scale based on the texture's dimensions
    var tex_width = float(bar_width_px)
    var tex_height = float(bar_height_px)

    # Convert texture dimensions to world units (adjust scaling_factor as needed)
    var scaling_factor = 0.01  # Adjust this value based on your game's scale
    initial_scale = Vector3(tex_width * scaling_factor, tex_height * scaling_factor, 1.0)
    scale = initial_scale

    update_bar()
    update_modulate()

func set_progress(value: float, shielded: bool):
    progress = clamp(value, 0.0, 1.0)
    if is_shielded != shielded:
        is_shielded = shielded
        # Swap the texture based on shielded state
        texture = shielded_texture if is_shielded else health_texture
    update_bar()
    update_modulate()

func update_modulate():
    if is_shielded:
        pass        # Reset modulate when shielded
        # modulate = Color.GHOST_WHITE
    else:
        # Lerp between color1 and color2 based on health percentage
        var lerped_color = color1.lerp(color2, 1.0 - progress)
        modulate = lerped_color

func update_bar():
    # Adjust the scale of the Sprite3D based on progress
    var new_scale = initial_scale
    new_scale.x *= progress
    scale = new_scale

func _process(delta):
    # Ensure the health bar always faces the camera or player
    var player = get_tree().current_scene.get_node("Player")
    if player:
        look_at(player.global_position, Vector3.UP)
