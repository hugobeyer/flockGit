# This script is for movement (attached to the Player (CharacterBody3D))
extends CharacterBody3D

@export var SPEED: float = 6.0

@onready var camera: Camera3D = get_node("/root/Main/GameCamera")
@onready var debug_touch: Node3D = get_node("/root/Main/debug_touch")

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
    if not is_on_floor():
        velocity.y -= gravity * delta

    handle_movement(delta)
    handle_touch_input()
    move_and_slide()

func handle_movement(delta):
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var camera_basis = camera.global_transform.basis
    var direction = (camera_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    direction.y = 0  # Ensure movement is only on the horizontal plane

    if direction:
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
        
        # Translate the debug_touch node along with the player
        debug_touch.global_position += Vector3(velocity.x, 0, velocity.z) * delta
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
        velocity.z = move_toward(velocity.z, 0, SPEED)

func handle_touch_input():
    if Input.is_action_pressed("touch"):
        var target_rotation = debug_touch.rotation.y
        rotation.y = target_rotation
