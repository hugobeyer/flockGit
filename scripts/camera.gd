extends Camera3D

# Variable to store the initial transform (position and rotation)
var initial_transform: Transform3D

# Reference to the player position node (parent of the camera)
var player_pos: Node3D

# Offset for the camera position (behind and above the player)
@export var camera_offset: Vector3 = Vector3(16, 32, 16)

func _ready():
	# Store the initial transform (position and rotation) set in the editor
	initial_transform = global_transform

	# Reference the player_pos using get_parent(), since the camera is a child of player_pos
	player_pos = get_parent()

func _process(_delta):
	if player_pos:
		# Apply an offset to keep the camera behind and above the player
		global_transform.origin = player_pos.global_transform.origin + camera_offset

		# Ensure the camera is looking at the player
		look_at(player_pos.global_transform.origin, Vector3.UP)
