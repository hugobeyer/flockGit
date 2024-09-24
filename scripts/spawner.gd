extends Node3D

@export var enemy_resources: Array[EnemyData]  # Array to store EnemyData resources
@export var spawn_rate: float = 0.25
@export var min_spawn_radius: float = 12.0
@export var max_spawn_radius: float = 20.0
@export var max_spawned: int = 120
var current_spawned: int = 0
var time_since_last_spawn: float = 0.0
var player: CharacterBody3D

func _ready():
	player = get_node("/root/Main/player_pos") as CharacterBody3D

func _process(delta):
	time_since_last_spawn += delta
	if time_since_last_spawn >= spawn_rate:
		spawn_enemy()
		time_since_last_spawn = 0.0

# Load enemy resources directly from the editor
func spawn_enemy():
	if current_spawned >= max_spawned:
		return

	if player == null or enemy_resources.size() == 0:
		return

	# Select a random enemy based on weights
	var enemy_data = get_random_weighted_enemy()

	if enemy_data == null:
		return

	# Load the scene from the EnemyData resource
	# Assuming EnemyData has a "scene_path" variable that stores the path to the scene.
	var enemy_scene = load(enemy_data.scene_path) as PackedScene
	if enemy_scene == null:
		print("Failed to load scene from path: " + enemy_data.scene_path)
		return

	var enemy_instance = enemy_scene.instantiate()  # Now instantiate the scene
	add_child(enemy_instance)


	if enemy_instance.is_inside_tree():
		var spawn_position = get_random_position_around_player(min_spawn_radius, max_spawn_radius)
		enemy_instance.global_transform.origin = spawn_position
		enemy_instance.player_target = player
		current_spawned += 1

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

	return null

# Function to get a random position around the player within a radius range
func get_random_position_around_player(min_radius: float, max_radius: float) -> Vector3:
	var angle = randf() * PI * 2.0  # Random angle in radians
	var distance = randf_range(min_radius, max_radius)  # Random distance within range

	# Calculate the spawn position based on polar coordinates
	var player_pos = player.global_transform.origin
	var spawn_x = player_pos.x + cos(angle) * distance
	var spawn_z = player_pos.z + sin(angle) * distance

	# Keep the Y coordinate the same as the player or adjust as needed
	return Vector3(spawn_x, player_pos.y, spawn_z)

# Helper function to print messages for debugging
func show_message(msg: String):
	print(msg)  # Debug feedback
