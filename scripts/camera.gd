extends Camera3D

# Store the initial camera transform (position and rotation)
var initial_transform: Transform3D

# Exported reference to the player position node (parent of the camera)
@export var player_pos: CharacterBody3D

# Offset for the camera position (relative to the player)
@export var camera_offset: Vector3 = Vector3(16, 32, 16)

# Camera smoothing variables
@export var max_offset: float = 10.0  # Maximum distance the camera can lag
@export var recovery_speed: float = 5.0  # How fast the camera recovers
@export var damping: float = 0.2  # Damping factor to control smoothness

# Internal camera velocity for physics-like movement
var camera_velocity: Vector3 = Vector3.ZERO

# Physics-like recovery to original position
var attraction_strength: float = 10.0  # How strongly the camera is pulled back

func _ready():
	# Store the initial transform (position and rotation) set in the editor
	initial_transform = global_transform

func _process(delta):
	if player_pos:
		# Calculate the target position for the camera, based on player position and offset
		var target_position = player_pos.global_transform.origin + camera_offset

		# Calculate the direction and distance to the target position
		var direction_to_target = target_position - global_transform.origin
		var distance_to_target = direction_to_target.length()

		# Limit the offset to the max distance allowed
		if distance_to_target > max_offset:
			direction_to_target = direction_to_target.normalized() * max_offset

		# Apply a physics-based spring force to smoothly attract the camera to the target position
		var force = direction_to_target * attraction_strength  # Attraction force
		camera_velocity += force * delta  # Update camera velocity based on force

		# Apply damping to reduce velocity over time (smooth recovery)
		camera_velocity = camera_velocity.lerp(Vector3.ZERO, damping * delta)

		# Update the camera's position based on the calculated velocity
		global_transform.origin += camera_velocity * delta

		# Ensure the camera is looking at the player
		look_at(player_pos.global_transform.origin, Vector3.UP)
