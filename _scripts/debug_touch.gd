extends Node3D

var camera: Camera3D
var player: CharacterBody3D

var initial_position: Vector3 = Vector3.ZERO
var is_touching: bool = false

# Recoil variables
# @export var max_recoil: float = 10.0  # Maximum recoil force
# @export var recoil_recovery_speed: float = 5.0  # Force units per second
# @export var rotate_damp = .5
# var current_recoil: float = 0.0
# var recoil_direction: Vector3 = Vector3.ZERO

# func _ready():
#     camera = get_node("../GameCamera")
#     player = get_parent()
    
#     # Delay the initial position calculation
#     get_tree().create_timer(0.1).timeout.connect(set_initial_position)

# func set_initial_position():
#     var initial_screen_center = get_viewport().get_visible_rect().size / 2
#     # initial_position = get_world_position(initial_screen_center)
#     global_position = initial_position

# func _physics_process(delta):
#     if Input.is_action_just_pressed("touch"):
#         initial_position = get_world_position(get_viewport().get_mouse_position())
#         global_position = initial_position
#         is_touching = true
#         visible = true

#     elif Input.is_action_just_released("touch"):
#         is_touching = false
#         visible = false

#     if is_touching:
#         var current_position = get_world_position(get_viewport().get_mouse_position())
#         var direction = current_position - initial_position

#         direction.y = 0  # Zero out the y-axis to keep it on the ground plane
#         if direction.length_squared() > 0.001 * delta:
#             look_at(initial_position + direction, Vector3.UP)
#         global_position = lerp(get_world_position(get_viewport().get_mouse_position()), player.global_transform.origin, 0.99)  

#     else:

#         # Update rotation based on mouse position when not touching
#         update_rotation_from_mouse()
    
#     # Apply and recover from recoil
   

# func update_rotation_from_mouse():
#     var mouse_pos_3d = get_world_position(get_viewport().get_mouse_position())
#     var direction = (mouse_pos_3d - global_position).normalized()
#     direction.y = 0  # Ensure the direction is on the horizontal plane
#     if direction.length_squared() > 0.001:
#         look_at(global_position + direction, Vector3.UP)

# func get_world_position(screen_position: Vector2) -> Vector3:
#     if camera and player:
#         var from = camera.project_ray_origin(screen_position)
#         var to = from + camera.project_ray_normal(screen_position) * 1000
        
#         var space_state = get_world_3d().direct_space_state
#         var query = PhysicsRayQueryParameters3D.create(from, to)
#         # query.collide_with_areas = true
#         var result = space_state.intersect_ray(query)

#         if not result.is_empty():
#             return result.position
#         else:
#             # If no intersection, calculate a point on the same Y level as the player
#             var ray_direction = (to - from).normalized()
#             var player_y = player.global_position.y
#             var t = (player_y - from.y) / ray_direction.y
#             return from + ray_direction * t

#     return Vector3.ZERO  # Return a default value if camera or player is null
