# This script is for movement (attached to the Player (CharacterBody3D))
extends CharacterBody3D

@export var SPEED: float = 32.0
@onready var camera: Camera3D = get_node("/root/Main/Camera3D")

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	if not camera:
		push_error("Camera3D not found in the scene tree.")

func _physics_process(delta: float):
	var input_direction = get_input_direction()
	
	if input_direction != Vector3.ZERO:
		apply_movement(input_direction)
	else:
		apply_friction()

	apply_gravity(delta)
	move_and_slide()

func get_input_direction() -> Vector3:
	return Vector3(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		0,
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	).normalized()

func apply_movement(input_direction: Vector3):
	if camera:
		var camera_transform = camera.global_transform
		var flat_camera_basis = camera_transform.basis
		flat_camera_basis.y = Vector3.ZERO
		flat_camera_basis = flat_camera_basis.orthonormalized()
		
		var move_direction = flat_camera_basis * input_direction
		velocity = move_direction * SPEED
	else:
		velocity = input_direction * SPEED

func apply_friction():
	velocity = velocity.move_toward(Vector3.ZERO, SPEED * 0.05)

func apply_gravity(delta: float):
	velocity.y -= gravity * delta
