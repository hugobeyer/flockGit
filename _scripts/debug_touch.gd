extends Node3D

@onready var camera: Camera3D = get_node("/root/Main/GameCamera")
@onready var player: Node3D = get_node("/root/Main/Player")

var initial_position: Vector3 = Vector3.ZERO
var is_touching: bool = false

func _process(delta):
    if Input.is_action_just_pressed("touch"):
        initial_position = get_world_position(get_viewport().get_mouse_position())
        global_position = initial_position
        is_touching = true
        visible = true
    elif Input.is_action_just_released("touch"):
        is_touching = false
        visible = false

    if is_touching:
        var current_position = get_world_position(get_viewport().get_mouse_position())
        var direction = current_position - initial_position
        direction.y = 0  # Zero out the y-axis to keep it on the ground plane
        
        if direction.length_squared() > 0.001:
            look_at(initial_position + direction, Vector3.UP)

func get_world_position(screen_position: Vector2) -> Vector3:
    var from = camera.project_ray_origin(screen_position)
    var to = from + camera.project_ray_normal(screen_position) * 1000
    
    var space_state = get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.collide_with_areas = true
    var result = space_state.intersect_ray(query)
    
    if result:
        return result.position
    else:
        # If no intersection, project the ray onto the player's plane
        var player_plane = Plane(Vector3.UP, player.global_position.y)
        return player_plane.intersects_ray(from, to)
