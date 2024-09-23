extends Node3D

@export var enemy_scene: PackedScene  # Enemy scene to instantiate
@export var spawn_rate: float = 1.0  # Time between spawns
@export var min_spawn_radius: float = 12.0  # Minimum distance from the player
@export var max_spawn_radius: float = 20.0  # Maximum distance from the player

var time_since_last_spawn: float = 0.0
var player: CharacterBody3D  # Reference to the player

func _ready():
	player = get_node("/root/Main/player_pos") as CharacterBody3D


# Called every frame to manage enemy spawning
func _process(delta):
	time_since_last_spawn += delta

	if time_since_last_spawn >= spawn_rate:
		spawn_enemy()
		time_since_last_spawn = 0.0  # Reset the spawn timer

# Function to spawn an enemy at a random position around the player
func spawn_enemy():
	print("Spawning enemy...")  # Debug message
	if player == null:
		print("Error: Cannot spawn enemy. Player reference is null.")
		return

	if enemy_scene == null:
		print("Error: enemy_scene is not assigned.")
		return
		
	# Create the enemy instance
	var enemy_instance = enemy_scene.instantiate()
	
	# Add the enemy to the scene before setting the transform
	add_child(enemy_instance)
	
	# Make sure the enemy is inside the tree before modifying its global transform
	if enemy_instance.is_inside_tree():  # Ensure the node is inside the tree
		var spawn_position = get_random_position_around_player(min_spawn_radius, max_spawn_radius)
		print("Spawning enemy at position: ", spawn_position)  # Debug spawn position
		enemy_instance.global_transform.origin = spawn_position  # Set the spawn position
	else:
		print("Enemy not inside tree yet.")
		
	# Assign player as the target for the enemy
	if enemy_instance is CharacterBody3D:
		enemy_instance.player_target = player
		
		
# Function to get a random position around the player within a radius range
func get_random_position_around_player(min_radius: float, max_radius: float) -> Vector3:
	# Random angle in radians
	var angle = randf() * PI * 2.0
	
	# Random distance between min and max rasdius
	var distance = randf_range(min_radius, max_radius)

	# Polar coordinates to Cartesian (X, Z), keeping Y the same as the player's Y
	var player_pos = player.global_transform.origin
	var spawn_x = player_pos.x + cos(angle) * distance
	var spawn_z = player_pos.z + sin(angle) * distance

	# Keep Y coordinate the same as the player or adjust as needed
	return Vector3(spawn_x, player_pos.y, spawn_z)
