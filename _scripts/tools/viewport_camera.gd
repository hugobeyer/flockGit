extends Node

@export var game_camera_path: NodePath  # Set this to the path of the GameCamera
@export var viewport_camera_path: NodePath  # Set this to the path of the ViewportCamera

func _ready():
    var game_camera = get_node_or_null(game_camera_path)
    var viewport_camera = get_node_or_null(viewport_camera_path)

    if not game_camera or not viewport_camera:
        push_error("GameCamera or ViewportCamera not found. Please check the paths.")
        return

    apply_camera_values(game_camera, viewport_camera)

func _process(delta):
    var game_camera = get_node_or_null(game_camera_path)
    var viewport_camera = get_node_or_null(viewport_camera_path)
    if game_camera and viewport_camera:
        apply_camera_values(game_camera, viewport_camera)

func apply_camera_values(game_camera: Camera3D, viewport_camera: Camera3D):
    viewport_camera.global_transform = game_camera.global_transform
    viewport_camera.fov = game_camera.fov
    viewport_camera.near = game_camera.near
    viewport_camera.far = game_camera.far
    viewport_camera.environment = game_camera.environment
    viewport_camera.current = false  # Set it to false to avoid making this the main camera.