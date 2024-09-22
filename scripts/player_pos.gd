extends CharacterBody3D

@export var SPEED: float = 5.0
var GRAVITY = ProjectSettings.get_setting("physics/3d/default_gravity")
var camera: Camera3D  # Reference to the camera

func _ready():
	# Get a reference to the camera
	camera = get_node("Camera")  # Adjust the path if needed

func _physics_process(delta):
	var input_direction = Vector3.ZERO

	# Get input for movement
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

		# Get the camera's XZ plane and apply movement relative to that
		var camera_basis = camera.global_transform.basis
		var move_direction = (camera_basis.x * input_direction.x) + (camera_basis.z * input_direction.z)
		move_direction.y = 0  # Ignore vertical movement (XZ plane only)
		move_direction = move_direction.normalized()

		# Set velocity based on the camera-relative direction
		velocity.x = move_direction.x * SPEED
		velocity.z = move_direction.z * SPEED
	else:
		# Gradually stop the player if no input is given
		velocity.x = lerp(velocity.x, 0.0, 0.1)
		velocity.z = lerp(velocity.z, 0.0, 0.1)

	# Apply gravity to keep the player grounded
	velocity.y += -GRAVITY * delta

	# Move the player using move_and_slide()
	move_and_slide()
