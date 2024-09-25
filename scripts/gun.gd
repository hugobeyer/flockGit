extends Node3D

@export var bullet_scene_path: String = "res://scenes/bullet.tscn"  # Path to the bullet scene
@export var fire_rate: float = 0.05  # Time between shots
@export var bullet_speed: float = 50.0  # Speed of the bullets (controlled by the gun)
@export var bullet_damage: float = 10.0  # Damage dealt by the bullets (controlled by the gun)
@export var bullet_lifetime: float = 3.0  # Lifetime of bullets (controlled by the gun)
@export var muzzle_node: Node3D  # The muzzle node where bullets spawn

var bullet_scene: PackedScene = null  # To store the packed bullet scene
var time_since_last_shot: float = 0.0  # Timer to track time between shots

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
		return  # Ensure bullet scene and muzzle node are set

	var bullet_direction = muzzle_node.global_transform.basis.z.normalized()

	# Instantiate and fire the bullet
	var bullet = bullet_scene.instantiate()
	add_child(bullet)  # Add bullet to the scene
	bullet.global_transform.origin = muzzle_node.global_transform.origin  # Set bullet's position

	# Pass all gun-related properties to the bullet via a method on the bullet (no need for bullet to manage them)
	if bullet.has_method("initialize_bullet"):
		bullet.initialize_bullet(bullet_direction, bullet_speed, bullet_damage, bullet_lifetime)  # Pass all parameters
