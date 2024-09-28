extends Node3D

# Bullet and Shooting Properties
var bullet_scene_path: String = "res://_scenes/bullet.tscn"
@export var fire_rate: float = 0.05  # Time between shots
@export var bullet_speed: float = 50.0  # Speed of the bullets
@export var bullet_damage: float = 10.0  # Damage dealt by the bullets
@export var muzzle_node: Node3D  # Node where bullets spawn

# Spread and Recoil Properties
@export var spread_count_bullet: int = 1  # Number of bullets to shoot in a spread
@export var spread_total_angle: float = 20.0  # Total angle for the bullet spread
@export var spread_max_angle: float = 40.0  # Max angle spread can reach over time
@export var spread_increase_speed: float = 5.0  # Speed of spread angle increase
@export var spread_polar_angle: float = 5.0  # Max polar angle shake to apply to spread

# Recoil Properties
@export var recoil_force: float = 0.1  # Force of the recoil applied to the player
@export var recoil_randomness: float = 0.1  # Adds some random variation to the recoil
@export var recoil_smoothness: float = 0.2  # How smooth the recoil effect is
@export var max_recoil_offset: float = 1.0  # Max recoil offset allowed

# Internal Variables
var bullet_scene: PackedScene = null
var time_since_last_shot: float = 0.0  # Track time between shots
var current_spread_angle: float = 0.0  # Gradually increase the spread angle
var current_polar_angle: float = 0.0  # Track spread's polar angle deviation
var current_recoil_offset: Vector3 = Vector3.ZERO  # Track current recoil offset

# Player references
var player_pos: Node3D
var player_rot: Node3D

func _ready():
	bullet_scene = load(bullet_scene_path)
	player_pos = get_node("/root/Main/Player")  # Reference to player position
	player_rot = get_node("/root/Main/Player/player_rot")  # Reference to player rotation

func _process(delta: float):
	time_since_last_shot += delta
	if Input.is_action_pressed("shoot") and time_since_last_shot >= fire_rate:
		shoot()
		time_since_last_shot = 0.0
		increase_spread_angle(delta)  # Gradually increase spread angle while shooting
	else:
		reset_spread_angle()  # Reset spread angle when player stops shooting

	# Apply recoil force to the player
	apply_recoil_force(delta)

# Function to handle shooting bullets with spread and recoil effect
func shoot():
	if bullet_scene == null or muzzle_node == null:
		return  # Ensure bullet scene and muzzle node are set

	if spread_count_bullet == 1:
		# No spread, shoot straight
		shoot_bullet(muzzle_node.global_transform.basis.z.normalized())
	else:
		# Calculate the base spread angle between bullets
		var angle_increment = current_spread_angle / (spread_count_bullet - 1)

		for i in range(spread_count_bullet):
			var base_angle = deg_to_rad(-current_spread_angle / 2 + i * angle_increment)

			# Get the bullet direction based on spread, but add recoil-induced deviation
			var bullet_direction = muzzle_node.global_transform.basis.z.normalized().rotated(muzzle_node.global_transform.basis.y, base_angle)

			# Apply polar angle shake based on recoil, which affects both horizontal and vertical directions
			bullet_direction = apply_polar_angle_shake(bullet_direction)

			# Shoot the bullet
			shoot_bullet(bullet_direction)

# Apply a gradual polar angle shake to bullet direction based on recoil
func apply_polar_angle_shake(bullet_direction: Vector3) -> Vector3:
	# Apply gradual polar angle deviation (simulating recoil causing inaccuracy)
	current_polar_angle += spread_polar_angle * randf()  # Gradually increase the polar angle

	# Apply random horizontal and vertical shake, clamped to max spread polar angle
	var horizontal_shake = deg_to_rad(clamp(randf_range(-current_polar_angle, current_polar_angle), -spread_polar_angle, spread_polar_angle))
	var vertical_shake = deg_to_rad(clamp(randf_range(-current_polar_angle, current_polar_angle), -spread_polar_angle, spread_polar_angle))

	# Rotate the bullet direction using the polar angles
	return bullet_direction.rotated(muzzle_node.global_transform.basis.y, horizontal_shake).rotated(muzzle_node.global_transform.basis.x, vertical_shake)

# Helper function to shoot a single bullet
func shoot_bullet(bullet_direction: Vector3):
	# Instantiate and fire the bullet
	var bullet = bullet_scene.instantiate() as Area3D
	add_child(bullet)

	# Set bullet's position to muzzle's position and initialize its properties
	bullet.global_transform = muzzle_node.global_transform
	bullet.set_bullet_properties(bullet_damage, bullet_direction, bullet_speed)

	# Apply recoil force after shooting
	apply_recoil(bullet_direction)

# Gradually increase the spread angle while shooting
func increase_spread_angle(delta: float):
	# Increase the spread angle, clamping to a maximum value
	current_spread_angle = min(current_spread_angle + spread_increase_speed * delta, spread_max_angle)

# Reset spread angle when the player stops shooting
func reset_spread_angle():
	current_spread_angle = spread_total_angle  # Reset to base spread
	current_polar_angle = 0.0  # Reset polar angle deviation

# Apply recoil force based on shooting
func apply_recoil(bullet_direction: Vector3):
	# Calculate recoil direction (opposite of shooting direction)
	var recoil_direction = -player_rot.transform.basis.z.normalized()

	# Add a random factor to the recoil
	var random_recoil = Vector3(randf_range(-recoil_randomness, recoil_randomness), 0, randf_range(-recoil_randomness, recoil_randomness))

	# Accumulate the recoil force for smooth application
	var total_recoil = (recoil_direction + random_recoil) * recoil_force

	# Apply recoil to the player position
	current_recoil_offset += total_recoil

# Apply the accumulated recoil force to the player smoothly
func apply_recoil_force(delta: float):
	# Interpolate recoil offset back to zero smoothly
	current_recoil_offset = current_recoil_offset.lerp(Vector3.ZERO, delta / recoil_smoothness)

	# Apply the recoil offset to the player position
	player_pos.translate_object_local(current_recoil_offset)
