# wave_system.gd
extends Node3D

class_name WaveSystem

#signal wave_completed  # Add this line to define the signal

# @export var player_path: NodePath  # Commented out if not immediately necessary

# Comment out or remove any references to wave_resource

# Add a basic enemy scene
@export var enemy_scene: PackedScene

var current_wave_index = -1
var active_enemies = 0
var player: CharacterBody3D
var main_scene: Node  # Reference to the main scene
var waves = []  # Add this line at the beginning of your script

const WaveResourceScript = preload("res://scripts/wave_resource.gd")

# @export var wave_resource: Node = WaveResourceScript.new()
func _ready():
	player = get_tree().get_first_node_in_group("player")
	assert(player != null, "Player node not found!")
	main_scene = get_tree().current_scene  # Get reference to the main scene

	# Initialize waves here if not done elsewhere
	# waves = [WaveResource.new(), WaveResource.new(), ...]  # Example

	# Remove the direct enemy spawning code
	# Instead, you can start the wave system here if desired
	start_waves()

func start_waves():
	current_wave_index = -1
	start_next_wave()

func start_next_wave():
	current_wave_index += 1
	if current_wave_index < waves.size():  # Changed from enemy_scene.size()
		var wave = waves[current_wave_index]  # Changed from enemy_scene.instantiate()
		if wave is WaveResource:
			_start_wave(wave)
		else:
			push_error("Invalid wave resource at index " + str(current_wave_index))
	else:
		emit_signal("all_waves_completed")

func _start_wave(wave: WaveResource):
	for i in range(wave.enemy_scenes.size()):
		for j in range(wave.enemy_counts[i]):
			await get_tree().create_timer(wave.spawn_interval).timeout
			var spawn_point = _get_spawn_point_around_player(wave.min_spawn_distance, wave.max_spawn_distance)
			spawn_enemy(wave.enemy_scenes[i], spawn_point, wave.resource)

func _get_spawn_point_around_player(min_distance: float, max_distance: float) -> Vector3:
	var random_angle = randf() * TAU  # Random angle in radians
	var random_distance = randf_range(min_distance, max_distance)
	var offset = Vector3(
		cos(random_angle) * random_distance,
		0,  # Assuming you want enemies to spawn at the same Y level as the player
		sin(random_angle) * random_distance
	)
	return player.global_position + offset

# Place the spawn_enemy function here
func spawn_enemy(new_enemy_scene: PackedScene, spawn_point: Vector3, wave: WaveResource):  # Changed Resource to WaveResource
	var enemy = new_enemy_scene.instantiate()
	main_scene.add_child(enemy)  # Add to the main scene
	enemy.global_position = spawn_point
	
	# Apply wave-specific customizations
	if enemy.has_method("set_health"):
		enemy.set_health(enemy.health * wave.enemy_health_multiplier)
	
	if wave.has("enemy_size_multiplier"):
		enemy.scale *= wave.enemy_size_multiplier
	
	if enemy.has_method("set_knockback_resistance"):
		enemy.set_knockback_resistance(wave.enemy_knockback_resistance)
	if wave.enemy_material_overlay:
		# Assume the enemy has a MeshInstance child named "Mesh"
		enemy.get_node("Mesh").material_overlay = wave.enemy_material_overlay
	
	if wave.enemy_can_swing_sword and enemy.has_method("enable_sword_swing"):
		enemy.enable_sword_swing(wave.enemy_swing_speed)
	
	if enemy.has_method("set_target"):
		enemy.set_target(player)
	
	active_enemies += 1

func on_enemy_defeated():
	active_enemies -= 1
	if active_enemies == 0 and current_wave_index < waves.size():
		emit_signal("wave_completed")
		var current_wave = waves[current_wave_index]
		if current_wave is WaveResource:
			await get_tree().create_timer(current_wave.wave_interval).timeout
		start_next_wave()
