@tool
extends Node

@export var game_camera_path: NodePath  # Set this to the path of the GameCamera
@export var viewport_camera_path: NodePath  # Set this to the path of the ViewportCamera

func _ready():
    if Engine.is_editor_hint():
        if game_camera_path == NodePath("") or viewport_camera_path == NodePath(""):
            setup_scene()
        else:
            var game_camera = get_node_or_null(game_camera_path)
            var viewport_camera = get_node_or_null(viewport_camera_path)

            if not game_camera or not viewport_camera:
                push_error("GameCamera or ViewportCamera not found. Please check the paths.")
                return

            apply_camera_values(game_camera, viewport_camera)

func setup_scene():
    # Create CanvasLayer
    var canvas_layer = CanvasLayer.new()
    add_child(canvas_layer)

    # Create Control Node
    var control = Control.new()
    control.size_flags_horizontal = Control.SIZE_EXPAND
    control.size_flags_vertical = Control.SIZE_EXPAND
    canvas_layer.add_child(control)

    # Create Button for generating setup
    var generate_button = Button.new()
    generate_button.text = "Generate Viewport Setup"
    generate_button.custom_minimum_size = Vector2(200, 50)  # Set button size
    generate_button.size_flags_horizontal = Control.SIZE_EXPAND
    generate_button.size_flags_vertical = Control.SIZE_EXPAND
    control.add_child(generate_button)

    # Connect button press signal to the function that will generate the setup
    generate_button.connect("pressed", Callable(self, "_on_generate_button_pressed"))

func _on_generate_button_pressed():
    # Create TextureRect for rendering the viewport
    var texture_rect = TextureRect.new()
    texture_rect.custom_minimum_size = Vector2(640, 480)  # Set desired size
    add_child(texture_rect)

    # Create SubViewportContainer and SubViewport
    var sub_viewport_container = SubViewportContainer.new()
    add_child(sub_viewport_container)

    var sub_viewport = SubViewport.new()
    sub_viewport.size = Vector2(640, 480)
    sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    sub_viewport_container.add_child(sub_viewport)

    # Create GameCamera
    var game_camera = Camera3D.new()
    game_camera.name = "GameCamera"
    game_camera.current = true
    add_child(game_camera)
    game_camera_path = game_camera.get_path()

    # Create ViewportCamera
    var viewport_camera = Camera3D.new()
    viewport_camera.name = "ViewportCamera"
    sub_viewport.add_child(viewport_camera)
    viewport_camera_path = viewport_camera.get_path()

    # Set Viewport texture to TextureRect
    texture_rect.texture = sub_viewport.get_texture()

    # Apply Camera Settings
    apply_camera_values(game_camera, viewport_camera)

func apply_camera_values(game_camera: Camera3D, viewport_camera: Camera3D):
    viewport_camera.global_transform = game_camera.global_transform
    viewport_camera.fov = game_camera.fov
    viewport_camera.near = game_camera.near
    viewport_camera.far = game_camera.far
    viewport_camera.environment = game_camera.environment
    viewport_camera.current = false  # Set it to false to avoid making this the main camera.
