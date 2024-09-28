extends Camera3D

# Store the initial camera transform (position and rotation)
var initial_transform: Transform3D

# Exported reference to the player position node (parent of the camera)
@export var player_pos: Node3D  # Change this to Node3D

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
	if not player_pos:
		player_pos = get_node("/root/Main/Player")  # Move this to _ready

func _process(delta):
	if player_pos:
		# Calculate target position in global space
		var target_position = player_pos.global_position + camera_offset
		
		var direction_to_target = target_position - global_position
		var distance_to_target = direction_to_target.length()

		if distance_to_target > max_offset:
			direction_to_target = direction_to_target.normalized() * max_offset
			target_position = global_position + direction_to_target

		var force = direction_to_target * attraction_strength
		camera_velocity += force * delta
		camera_velocity = camera_velocity.lerp(Vector3.ZERO, damping * delta)

		# Update position, including Y-axis
		global_position += camera_velocity * delta

		# Look at the player, but keep the camera's up vector vertical
		look_at(player_pos.global_position, Vector3.UP)
