extends Node3D

@export var enemy_scene: PackedScene  # Scene for the enemy
@export var spawn_rate: float = 1.0  # Time between enemy spawns
@export var min_spawn_radius: float = 10.0  # Minimum distance from the player
@export var max_spawn_radius: float = 30.0  # Maximum distance from the player
@export var player: Node3D  # Reference to the player node (e.g., player_pos)

var time_since_last_spawn = 0.0
var enemies_alive = []

func _ready():
	# Initialization or setup, if needed
	pass

func _process(_delta):
	time_since_last_spawn += _delta

	if time_since_last_spawn >= spawn_rate:
		spawn_enemy()
		time_since_last_spawn = 0.0  # Reset the spawn timer

func spawn_enemy():
	if enemy_scene and player:
		var enemy_instance = enemy_scene.instantiate()

		# Add the enemy to the scene
		add_child(enemy_instance)

		# Now assign the player as the target after adding to the scene
		enemy_instance.enemy_target = player

		# Randomly spawn within a ring around the player using min/max spawn radius
		var random_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
		var random_distance = randf_range(min_spawn_radius, max_spawn_radius)
		var spawn_position = player.global_transform.origin + random_direction * random_distance

		enemy_instance.global_transform.origin = spawn_position

		enemies_alive.append(enemy_instance)

		# Connect the enemy destroyed signal to the level settings
		enemy_instance.connect("enemy_destroyed", Callable(self, "_on_enemy_destroyed"))

func _on_enemy_destroyed(enemy):
	enemies_alive.erase(enemy)
