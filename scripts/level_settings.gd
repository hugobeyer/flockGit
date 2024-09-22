extends Node  # Adjusted from Node3D to Node

@export var enemy_scenes: Array[PackedScene]  # Array of enemy scenes to choose from
@export var spawn_radius_min: float = 15.0  # Minimum distance from the player to spawn enemies
@export var spawn_radius_max: float = 25.0  # Maximum distance from the player to spawn enemies
@export var spawn_rate: float = 2.0  # Time interval between enemy spawns

var time_since_last_spawn = 0.0

func _ready():
	if enemy_scenes.size() == 0:
		print("No enemy scenes assigned!")
	else:
		print("Level Settings Ready")

func _process(_delta):
	time_since_last_spawn += _delta

	if time_since_last_spawn >= spawn_rate:
		spawn_enemy()
		time_since_last_spawn = 0.0

func spawn_enemy():
	if enemy_scenes.size() == 0:
		print("No enemy scenes to spawn!")
		return

	print("Spawning enemy...")  # Debugging line

	# Select a random enemy type from the array
	var random_index = randi() % enemy_scenes.size()
	var selected_enemy_scene = enemy_scenes[random_index]

	if not selected_enemy_scene:
		print("Invalid enemy scene!")
		return

	# Get the player's position
	var player_position = get_player_position()
	if player_position == Vector3.ZERO:
		print("Player position not found!")
		return  # If player position isn't found, don't spawn

	# Randomly select a spawn position around the player, outside the spawn radius
	var angle = randf() * PI * 2.0  # Random angle in radians
	var distance = randf_range(spawn_radius_min, spawn_radius_max)  # Random distance outside the spawn radius

	var spawn_position = Vector3(
		cos(angle) * distance,
		0,  # Assuming enemies spawn at Y = 0 (ground level)
		sin(angle) * distance
	)

	# Instantiate the selected enemy scene
	var enemy_instance = selected_enemy_scene.instantiate()

	# Set enemy position relative to the player's position
	enemy_instance.global_transform.origin = player_position + spawn_position

	# Add the enemy instance to the scene tree
	get_tree().current_scene.add_child(enemy_instance)
	print("Enemy spawned at: ", enemy_instance.global_transform.origin)

func get_player_position() -> Vector3:
	# Find the player in the scene, assuming the player is a Node3D and named "player_pos"
	var player = get_node_or_null("/root/Main/player_pos")  # Using the correct path to player_pos
	if player and player is Node3D:
		return player.global_transform.origin
	print("Player not found or not a Node3D")
	return Vector3.ZERO
