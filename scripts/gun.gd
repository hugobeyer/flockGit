extends Node3D

@export var muzzle: Marker3D  # Assign the muzzle in the Inspector
@export var bullet_scene: PackedScene  # Bullet scene to instantiate
@export var bullet_speed: float = 50.0  # Speed of the bullet
@export var bullet_lifetime: float = 5.0  # Lifetime of the bullet
@export var fire_rate: float = 0.5  # Time between each bullet shot
@export var bullet_damage: float = 10.0  # Damage inflicted by each bullet
@export var shoot_radius: float = 15.0  # Radius within which enemies must be to shoot

var bullets = []
var time_since_last_shot = 0.0

func _ready():
	if not muzzle or not bullet_scene:
		print("Muzzle or bullet scene not assigned!")

func _process(_delta):
	# Increment the time since the last shot
	time_since_last_shot += _delta

	# Shoot only when enough time has passed based on the fire rate
	if time_since_last_shot >= fire_rate:
		if check_for_enemies_in_radius():
			shoot()
			time_since_last_shot = 0.0  # Reset the shot timer

	update_bullets(_delta)

func shoot():
	if not muzzle or not bullet_scene:
		return

	# Instantiate the bullet scene
	var bullet_instance = bullet_scene.instantiate()

	# Set the bullet's position to the muzzle's local space position
	bullet_instance.transform = muzzle.global_transform

	# Add the bullet instance to the scene tree
	get_tree().current_scene.add_child(bullet_instance)

	# Store the bullet instance and its lifetime
	bullets.append({
		"instance": bullet_instance,
		"lifetime": bullet_lifetime
	})

func update_bullets(_delta):
	var bullets_to_remove = []

	for bullet in bullets:
		var bullet_instance = bullet["instance"]

		# Move bullet in its local forward direction (positive Z axis)
		bullet_instance.translate(Vector3(0, 0, bullet_speed * _delta))

		# Decrease bullet lifetime
		bullet["lifetime"] -= _delta

		# Remove bullet if its lifetime is over
		if bullet["lifetime"] <= 0:
			bullet_instance.queue_free()
			bullets_to_remove.append(bullet)

	# Clean up expired bullets
	for bullet in bullets_to_remove:
		bullets.erase(bullet)

func check_for_enemies_in_radius() -> bool:
	# Find all enemies and check if any are within the shoot_radius
	var enemies = get_tree().get_nodes_in_group("enemies")  # Ensure enemies are in this group
	var player_position = global_transform.origin

	for enemy in enemies:
		if enemy is CharacterBody3D:
			var enemy_position = enemy.global_transform.origin
			if player_position.distance_to(enemy_position) <= shoot_radius:
				return true

	return false
