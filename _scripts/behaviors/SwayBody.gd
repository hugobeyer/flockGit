extends RigidBody3D

@export var return_force: float = 50.0
@export var max_angle: float = 30.0

var initial_rotation: Vector3

func _ready():
    initial_rotation = rotation
    freeze = true  # Freeze position, but allow rotation

func _physics_process(delta):
    # Apply force to return to initial rotation
    var current_rotation = rotation
    var angle_diff = initial_rotation - current_rotation
    angle_diff = Vector3(
        clamp(angle_diff.x, -deg_to_rad(max_angle), deg_to_rad(max_angle)),
        clamp(angle_diff.y, -deg_to_rad(max_angle), deg_to_rad(max_angle)),
        clamp(angle_diff.z, -deg_to_rad(max_angle), deg_to_rad(max_angle))
    )
    apply_torque(angle_diff * return_force)
