extends Node3D

@export var enemy_scene: PackedScene  # Scene for the enemy
@export var wave_delay: float = 5.0  # Time to wait between waves
@export var enemies_per_wave: int = 5  # Number of enemies per wave
@export var spawn_rate: float = 1.0  # Time between enemy spawns within a wave
@export var spawn_radius: float = 20.0  # Radius around the player to spawn enemies
@export var max_waves: int = 10  # Total number of waves
@export var cluster_radius: float = 10.0  # Radius for clustering enemies
@export var cluster_weight: float = 0.5  # How strongly enemies cluster together
@export var player: Node3D  # Reference to the player

var current_wave = 0
var enemies_spawned_in_wave = 0
var time_since_last_spawn = 0.0
var time_since_last_wave = 0.0
var enemies_alive = []
var cluster_positions = []

func _ready():
	generate_cluster_positions()

func _process(_delta):
	if current_wave < max_waves:
		time_since_last_wave += _delta
		if time_since_last_wave >= wave_delay and enemies_spawned_in_wave < enemies_per_wave:
			time_since_last_spawn += _delta
			if time_since_last_spawn >= spawn_rate:
				spawn_enemy()
				enemies_spawned_in_wave += 1
				time_since_last_spawn = 0.0
		elif enemies_spawned_in_wave >= enemies_per_wave and enemies_alive.is_empty():
			current_wave += 1
			enemies_spawned_in_wave = 0
			time_since_last_wave = 0.0
			generate_cluster_positions()

# Generate random cluster positions around the player
func generate_cluster_positions():
	cluster_positions.clear()
	for i in range(enemies_per_wave):
		var random_pos = global_transform.origin + Vector3(randf_range(-spawn_radius, spawn_radius), 0, randf_range(-spawn_radius, spawn_radius))
		cluster_positions.append(random_pos)

# Spawn an enemy and assign the player as the target
func spawn_enemy():
	if enemy_scene:
		var enemy_instance = enemy_scene.instantiate()

		# Add the enemy to the scene first, before modifying its transform
		add_child(enemy_instance)

		# Assign the player as the enemy's target
		enemy_instance.enemy_target = player  # Pass the player to the enemy

		# Now modify the position after it's inside the tree
		var random_cluster_pos = cluster_positions[randi() % cluster_positions.size()]
		var offset = Vector3(randf_range(-cluster_radius, cluster_radius), 0, randf_range(-cluster_radius, cluster_radius)) * cluster_weight
		enemy_instance.global_transform.origin = random_cluster_pos + offset

		enemies_alive.append(enemy_instance)

		# Connect the enemy destroyed signal to the level settings
		enemy_instance.connect("enemy_destroyed", Callable(self, "_on_enemy_destroyed"))

# When an enemy is destroyed, remove it from the alive list
func _on_enemy_destroyed(enemy):
	enemies_alive.erase(enemy)
