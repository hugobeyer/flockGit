extends Node3D

@export var bullet_scene_path: String = "res://scenes/bullet.tscn"
@export var fire_rate: float = 0.05
@export var bullet_speed: float = 64.0
@export var bullet_damage: float = 10.0
@export var muzzle_node: Node3D
@export var is_spread_enabled: bool = false  # Variable to enable spread shooting
@export var spread_angle: float = 8.0  # Spread angle for the bullets
@export var num_bullets: int = 5  # Number of bullets in the spread

var bullet_scene: PackedScene = null
var time_since_last_shot: float = 0.0

# Load the bullet scene when ready
func _ready():
	bullet_scene = load(bullet_scene_path)

# Called every frame, handle shooting logic
func _process(delta):
	time_since_last_shot += delta
	if Input.is_action_pressed("shoot") and time_since_last_shot >= fire_rate:
		shoot()
		time_since_last_shot = 0.0

# Function to handle shooting logic
func shoot():
	if bullet_scene == null or muzzle_node == null:
		return

	# If spread shooting is enabled, shoot multiple bullets
	if is_spread_enabled:
		# Start from a negative spread angle to a positive one, evenly distributing the bullets
		var base_direction = muzzle_node.global_transform.basis.z.normalized()
		var start_angle = -(spread_angle * (num_bullets - 1)) / 2.0

		for i in range(num_bullets):
			var angle_offset = deg_to_rad(start_angle + spread_angle * i)
			var direction = base_direction.rotated(Vector3.UP, angle_offset)
			spawn_bullet(direction)

	else:
		# Normal single shot without spread
		var bullet_direction = muzzle_node.global_transform.basis.z.normalized()
		spawn_bullet(bullet_direction)

# Function to instantiate and fire the bullet
func spawn_bullet(direction: Vector3):
	var bullet = bullet_scene.instantiate()
	add_child(bullet)
	bullet.global_transform.origin = muzzle_node.global_transform.origin
	bullet.set_bullet_properties(bullet_damage, bullet_speed, direction, fire_rate)
