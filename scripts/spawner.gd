extends Node3D

@export var config_file_path: String = "res://path_to_config_file.json"  # Path to the config file

@export var spawn_rate: float = 0.25  # Time between spawns
@export var min_spawn_radius: float = 12.0  # Minimum distance from the player
@export var max_spawn_radius: float = 20.0  # Maximum distance from the player
@export var max_spawned: int = 120  # Maximum number of enemies that can be spawned
var enemy_scenes: Array = []  # Will store enemy data from JSON
var current_spawned: int = 0  # Track current number of spawned enemies

var time_since_last_spawn: float = 0.0
var player: CharacterBody3D  # Reference to the player

func _ready():
	player = get_node("/root/Main/player_pos") as CharacterBody3D
	load_enemy_scenes()  # Load enemy scenes from external file

# Load enemy scenes from the configuration file (e.g., JSON)
func load_enemy_scenes():
	var file = FileAccess.open(config_file_path, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data.error == OK:
			if data.result.has("enemy_scenes"):
				enemy_scenes = data.result["enemy_scenes"]
				print("Enemy scenes loaded:", enemy_scenes)
			else:
				print("No 'enemy_scenes' found in the config file.")
		else:
			print("Error parsing JSON: ", data.error)
		file.close()
	else:
		print("Configuration file not found:", config_file_path)

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

	if player == null or enemy_scenes.size() == 0:
		return

	# Select a random enemy based on weights
	var enemy_scene_path = get_random_weighted_scene()

	if enemy_scene_path == "":
		return

	# Load the enemy scene from its path
	var enemy_scene = load(enemy_scene_path)
	var enemy_instance = enemy_scene.instantiate()
	add_child(enemy_instance)

	if enemy_instance.is_inside_tree():
		var spawn_position = get_random_position_around_player(min_spawn_radius, max_spawn_radius)
		enemy_instance.global_transform.origin = spawn_position
		enemy_instance.player_target = player  # Assign player as target
		current_spawned += 1  # Increment the spawn count

# Function to get a random scene based on weights
func get_random_weighted_scene() -> String:
	var total_weight = 0.0
	for scene_data in enemy_scenes:
		total_weight += float(scene_data["weight"])

	var random_value = randf() * total_weight
	var current_weight = 0.0

	for scene_data in enemy_scenes:
		current_weight += float(scene_data["weight"])
		if random_value <= current_weight:
			return scene_data["scene"]  # Return the selected scene path

	return ""  # Return empty string if nothing is selected

# Function to get a random position around the player within a radius range
func get_random_position_around_player(min_radius: float, max_radius: float) -> Vector3:
	var angle = randf() * PI * 2.0
	var distance = randf_range(min_radius, max_radius)

	var player_pos = player.global_transform.origin
	var spawn_x = player_pos.x + cos(angle) * distance
	var spawn_z = player_pos.z + sin(angle) * distance

	return Vector3(spawn_x, player_pos.y, spawn_z)

# Function to handle enemy death
func on_enemy_died():
	current_spawned -= 1  # Decrease the spawned count
