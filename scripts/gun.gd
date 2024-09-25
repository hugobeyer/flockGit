extends Node3D

@export var bullet_scene_path: String = "res://scenes/bullet.tscn"  # Path to the bullet scene
@export var fire_rate: float = 0.05  # Time between shots
@export var bullet_speed: float = 50.0  # Speed of the bullets
@export var bullet_damage: float = 10.0  # Damage dealt by the bullets
@export var muzzle_node: Node3D  # Assign the muzzle node where bullets spawn

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

	# Get the bullet direction as the Z+ direction from the muzzle node
	var bullet_direction = muzzle_node.global_transform.basis.z.normalized()

	# Instantiate and fire the bullet
	var bullet = bullet_scene.instantiate() as Area3D
	add_child(bullet)  # Add bullet to the scene

	# Set bullet's position to muzzle's position and initialize its properties
	bullet.global_transform.origin = muzzle_node.global_transform.origin
	bullet.set_bullet_properties(bullet_damage, bullet_direction, bullet_speed)
