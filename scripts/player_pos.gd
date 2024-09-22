# This script is for movement (attached to the Player (CharacterBody3D))
extends CharacterBody3D

@export var SPEED: float = 5.0
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera: Camera3D  # Reference to the camera

func _ready():
	camera = get_node("Camera")

func _physics_process(delta):
	var input_direction = Vector3.ZERO

	if Input.is_action_pressed("move_forward"):
		input_direction.z -= 1
	if Input.is_action_pressed("move_backward"):
		input_direction.z += 1
	if Input.is_action_pressed("move_left"):
		input_direction.x -= 1
	if Input.is_action_pressed("move_right"):
		input_direction.x += 1

	if input_direction != Vector3.ZERO:
		input_direction = input_direction.normalized()

		# Move relative to the camera's XZ plane
		var camera_basis = camera.global_transform.basis
		var move_direction = (camera_basis.x * input_direction.x) + (camera_basis.z * input_direction.z)
		move_direction.y = 0  # Ignore vertical movement
		move_direction = move_direction.normalized()

		velocity.x = move_direction.x * SPEED
		velocity.z = move_direction.z * SPEED
	else:
		# Gradually stop the player
		velocity.x = lerp(velocity.x, 0.0, 0.1)
		velocity.z = lerp(velocity.z, 0.0, 0.1)

	# Apply gravity
	velocity.y += -GRAVITY * delta

	# Move the player
	move_and_slide()
