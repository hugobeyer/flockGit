class_name Spawner
extends Node3D

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
var spawn_points: Array[Vector3] = []

@onready var nav_region: NavigationRegion3D = get_node("../NavigationRegion3D")

func _ready():
	print_scene_tree()  # This will help debug the scene structure
	call_deferred("setup")

func setup():
	player = get_node("/root/Main/Player")
	if not player:
		push_error("Player not found in 'player' group!")
		return

	enemy_container = Node3D.new()
	enemy_container.name = "EnemyContainer"
	add_child(enemy_container)

	generate_spawn_points()

	timer = Timer.new()
	timer.wait_time = spawn_interval
	timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))
	add_child(timer)
	timer.start()

	if not nav_region:
		push_warning("NavigationRegion3D not found. Path might be incorrect.")

func generate_spawn_points():
	spawn_points.clear()
	for i in range(max_enemies):
		spawn_points.append(get_random_position_around_player())

func _on_spawn_timer_timeout():
	if enemy_count < max_enemies:
		print("Attempting to spawn enemy. Current count: ", enemy_count)
		call_deferred("spawn_enemy")
	else:
		print("Max enemies reached: ", enemy_count)

# Preload the enemy scene at the top of the script
var EnemyScene = preload("res://scenes/enemy.tscn")

func spawn_enemy():
	var enemy_instance = EnemyScene.instantiate()
	if enemy_instance:
		if spawn_points.is_empty():
			push_warning("No spawn points available. Generating new ones.")
			generate_spawn_points()
		
		var spawn_position = spawn_points.pop_front()
		enemy_instance.global_transform.origin = spawn_position
		enemy_container.add_child(enemy_instance)
		enemy_count += 1
	else:
		push_error("Failed to spawn enemy")

func get_random_position_around_player() -> Vector3:
	if not player:
		push_error("Cannot get random position: player is not set")
		return global_position  # Return spawner's position as fallback

	var angle = randf() * TAU  # Random angle in radians (TAU is 2*PI)
	var distance = randf_range(min_spawn_radius, max_spawn_radius)

	var spawn_offset = Vector3(cos(angle) * distance, spawn_height, sin(angle) * distance)
	return player.global_position + spawn_offset

func _process(delta):
	if Input.is_action_just_pressed("ui_accept"):  # Spacebar by default
		print("Manual spawn triggered")
		spawn_enemy()

# Define enemy_resources before the loop
var enemy_resources = [
	# Add your enemy data here, for example:
	# { "weight": 0.5, "enemy_type": "Goblin" },
	# { "weight": 0.3, "enemy_type": "Orc" },
	# { "weight": 0.2, "enemy_type": "Dragon" }
]

# Add this function to print the entire scene tree for debugging
func print_scene_tree(node = get_tree().get_root(), indent = ""):
	print(indent + node.name + " (" + node.get_class() + ")")
	for child in node.get_children():
		print_scene_tree(child, indent + "  ")
