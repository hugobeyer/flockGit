extends Node3D

# Bullet and Shooting Properties
@export var bullet_scene_path: String = "res://scenes/bullet.tscn"
@export var fire_rate: float = 0.05  # Time between shots
@export var bullet_speed: float = 50.0  # Speed of the bullets
@export var bullet_damage: float = 10.0  # Damage dealt by the bullets
@export var muzzle_node: Node3D  # Node where bullets spawn

# Spread Properties
@export var spread_count_bullet: int = 1  # Number of bullets to shoot in a spread
@export var spread_total_angle: float = 20.0  # Total angle for the bullet spread

# Shake Properties
@export var shake_angle_multiplier: float = 1.0  # Multiplier for shake angle randomness
@export var shake_frequency: float = 5.0  # Frequency of shake randomness (how fast the angle changes)
@export var shake_intensity: float = 0.2  # Intensity of shake (affects how much the angle deviates)

# Recoil Properties
@export var recoil_intensity: float = 0.5  # How strong the recoil effect is
@export var recoil_smoothness: float = 0.2  # How smooth the recoil is
@export var recoil_randomness: float = 0.05  # Adds some random variation to the recoil

# Internal Variables
var bullet_scene: PackedScene = null
var time_since_last_shot: float = 0.0  # Track time between shots
var current_recoil_offset: Vector3 = Vector3.ZERO  # Track recoil offset

# Player references
var player_pos: Node3D
var player_rot: Node3D

func _ready():
	bullet_scene = load(bullet_scene_path)
	player_pos = get_node("/root/Main/player_pos")  # Reference to player position
	player_rot = get_node("/root/Main/player_pos/player_rot")  # Reference to player rotation

func _process(delta: float):
	time_since_last_shot += delta
	if Input.is_action_pressed("shoot") and time_since_last_shot >= fire_rate:
		shoot()
		time_since_last_shot = 0.0
	else:
		reset_recoil()  # Reset recoil when not shooting

	# Apply smooth recoil to the player
	smooth_recoil(delta)

# Function to handle shooting bullets with spread and shake
func shoot():
	if bullet_scene == null or muzzle_node == null:
		return  # Ensure bullet scene and muzzle node are set

	# Spread Logic
	if spread_count_bullet == 1:
		# No spread, shoot straight
		shoot_bullet(muzzle_node.global_transform.basis.z.normalized())
	else:
		# Calculate the base spread angle between bullets
		var angle_increment = spread_total_angle / (spread_count_bullet - 1)

		for i in range(spread_count_bullet):
			var base_angle = deg_to_rad(-spread_total_angle / 2 + i * angle_increment)

			# Get the bullet direction based on spread
			var bullet_direction = muzzle_node.global_transform.basis.z.normalized().rotated(Vector3.UP, base_angle)

			# Apply shake to each bullet's direction (independent of spread)
			var shake_noise = calculate_shake()
			var final_direction = bullet_direction.rotated(Vector3.UP, shake_noise)

			# Shoot the bullet
			shoot_bullet(final_direction)

# Helper function to shoot a single bullet
func shoot_bullet(bullet_direction: Vector3):
	# Instantiate and fire the bullet
	var bullet = bullet_scene.instantiate() as Area3D
	add_child(bullet)

	# Set bullet's position to muzzle's position and initialize its properties
	bullet.global_transform.origin = muzzle_node.global_transform.origin
	bullet.set_bullet_properties(bullet_damage, bullet_direction, bullet_speed)

	# Apply recoil after shooting
	apply_recoil(bullet_direction)

# Apply recoil based on shooting
func apply_recoil(bullet_direction: Vector3):
	# Calculate recoil direction (opposite of shooting direction)
	var recoil_direction = -player_rot.global_transform.basis.z.normalized()  # Use player_rot for recoil direction

	# Add a random factor to the recoil
	var random_recoil = Vector3(randf_range(-recoil_randomness, recoil_randomness), 0, randf_range(-recoil_randomness, recoil_randomness))

	# Apply recoil intensity
	var recoil_vector = (recoil_direction + random_recoil) * recoil_intensity

	# Accumulate recoil effect for smooth application
	current_recoil_offset += recoil_vector

# Smoothly return player to original position after recoil
func smooth_recoil(delta: float):
	# Interpolate recoil offset back to zero smoothly
	current_recoil_offset = current_recoil_offset.lerp(Vector3.ZERO, delta / recoil_smoothness)

	# Apply the recoil offset to the player position
	player_pos.translate(current_recoil_offset)

# Calculate the shake based on randomness and frequency
func calculate_shake() -> float:
	return sin(randf() * shake_frequency) * shake_intensity * shake_angle_multiplier

# Reset recoil when the player stops shooting
func reset_recoil():
	current_recoil_offset = Vector3.ZERO  # Reset recoil offset to zero
