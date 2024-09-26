extends Node3D

@export var enemy_resources: Array[Resource]  # Array to store only EnemyData resources
@export var spawn_rate: float = 0.25  # Time between spawns
@export var min_spawn_radius: float = 12.0  # Minimum distance from the player
@export var max_spawn_radius: float = 20.0  # Maximum distance from the player
@export var max_spawned: int = 120  # Maximum number of enemies that can be spawned
var current_spawned: int = 0
var time_since_last_spawn: float = 0.0
var player: CharacterBody3D

func _ready():
	player = get_node("/root/Main/Player") as CharacterBody3D

# Called every frame to manage enemy spawning
func _process(delta):
	time_since_last_spawn += delta

	if time_since_last_spawn >= spawn_rate:
		spawn_enemy()
		time_since_last_spawn = 0.0  # Reset the spawn timer

# Function to spawn an enemy at a random position around the player
func spawn_enemy():
	if current_spawned >= max_spawned:
		return  # Don't spawn more if the limit is reached

	if player == null or enemy_resources.size() == 0:
		return

	# Select a random enemy based on weights
	var enemy_data = get_random_weighted_enemy()

	if enemy_data == null:
		return

	# Load the enemy scene from the EnemyData resource
	var enemy_scene = load(enemy_data.scene_path)
	if enemy_scene == null:
		show_message("Failed to load scene: " + enemy_data.scene_path)
		return

	var enemy_instance = enemy_scene.instantiate()
	add_child(enemy_instance)

	if enemy_instance.is_inside_tree():
		var spawn_position = get_random_position_around_player(min_spawn_radius, max_spawn_radius)
		enemy_instance.global_transform.origin = spawn_position
		enemy_instance.player_target = player  # Assign player as target
		current_spawned += 1  # Increment the spawn count

# Function to get a random enemy based on weights
func get_random_weighted_enemy() -> EnemyData:
	var total_weight = 0.0
	for enemy_data in enemy_resources:
		total_weight += float(enemy_data.weight)

	var random_value = randf() * total_weight
	var current_weight = 0.0

	for enemy_data in enemy_resources:
		current_weight += float(enemy_data.weight)
		if random_value <= current_weight:
			return enemy_data  # Return the selected enemy data

	return null  # Return null if nothing is selected

# Function to get a random position around the player within a radius range
func get_random_position_around_player(min_radius: float, max_radius: float) -> Vector3:
	var angle = randf() * PI * 2.0
	var distance = randf_range(min_radius, max_radius)

	var player_pos = player.global_transform.origin
	var spawn_x = player_pos.x + cos(angle) * distance
	var spawn_z = player_pos.z + sin(angle) * distance

	return Vector3(spawn_x, player_pos.y, spawn_z)

# Function to display a message (can be tied to a label in the UI)
func show_message(msg: String):
	print(msg)  # Replace with actual UI feedback
