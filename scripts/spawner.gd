extends Node3D

class_name Spawner

@export var player_path: NodePath
@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var spawn_interval: float = 2.0
@export var max_enemies: int = 10
@export var min_spawn_radius: float = 5.0
@export var max_spawn_radius: float = 10.0
@export var spawn_height: float = 1.0

var timer: Timer
var enemy_count: int = 0
var player: CharacterBody3D
var enemy_container: Node3D

func _ready():
	print("Spawner _ready() called")
	print("Current player_path: ", player_path)
	await get_tree().process_frame
	
	if player_path.is_empty():
		push_error("player_path is not set in the Inspector")
	else:
		player = get_node_or_null(player_path)
		if player:
			print("Player found at path: ", player_path)
		else:
			push_error("Player not found at path: " + str(player_path))
	
	if not player:
		push_warning("Spawner will not function correctly without a valid player reference")
		return

	enemy_container = Node3D.new()
	enemy_container.name = "EnemyContainer"
	add_child(enemy_container)

	timer = Timer.new()
	add_child(timer)
	timer.timeout.connect(_on_spawn_timer_timeout)
	timer.set_wait_time(spawn_interval)
	timer.start()
	print("Timer started with interval: %s" % spawn_interval)

func _on_spawn_timer_timeout():
	print("Timer timeout")
	if enemy_count < max_enemies:
		call_deferred("spawn_enemy")
	else:
		print("Max enemies reached: %s/%s" % [enemy_count, max_enemies])

func spawn_enemy():
	print("Attempting to spawn enemy")
	if not player:
		push_error("Player is not set in the Spawner")
		return

	var enemy: Enemy = enemy_scene.instantiate()
	
	# Add the enemy to the container
	enemy_container.add_child(enemy)
	
	# Set the position after adding to the scene tree
	var spawn_position = get_random_position_around_player()
	enemy.global_position = spawn_position
	
	# Set the player target for the enemy
	enemy.set_player_target(player)
	
	enemy_count += 1

	print("Enemy spawned at: %s. Total enemies: %s" % [spawn_position, enemy_count])

func get_random_position_around_player() -> Vector3:
	if not player:
		push_error("Cannot get random position: player is not set")
		return global_position  # Return spawner's position as fallback

	var angle = randf() * TAU  # Random angle in radians (TAU is 2*PI)
	var distance = randf_range(min_spawn_radius, max_spawn_radius)

	var spawn_offset = Vector3(cos(angle) * distance, spawn_height, sin(angle) * distance)
	return player.global_position + spawn_offset

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		print("Debug: enemy_count = %s, max_enemies = %s" % [enemy_count, max_enemies])
		print("Timer time left: %s" % timer.time_left)
		if player:
			print("Player position: %s" % player.global_position)
		else:
			print("Player not set")

# Define enemy_resources before the loop
var enemy_resources = [
	# Add your enemy data here, for example:
	# { "weight": 0.5, "enemy_type": "Goblin" },
	# { "weight": 0.3, "enemy_type": "Orc" },
	# { "weight": 0.2, "enemy_type": "Dragon" }
]
