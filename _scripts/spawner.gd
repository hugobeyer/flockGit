extends Node3D

@export var enemy_scene: PackedScene
@export var spawn_radius: float = 10.0
@export var max_enemies: int = 10
@export var spawn_interval: float = 2.0
@export var max_spawn_attempts: int = 10

var player: Node3D
var enemies: Array = []
var nav_region: NavigationRegion3D
var spawn_timer: Timer

var EnemyScene = preload("res://scenes/enemy.tscn")

func _ready():
	player = get_node("/root/Main/Player")
	nav_region = get_node("/root/Main/NavigationRegion3D")
	
	spawn_timer = Timer.new()
	add_child(spawn_timer)
	spawn_timer.wait_time = spawn_interval
	spawn_timer.connect("timeout", Callable(self, "_on_spawn_timer_timeout"))
	spawn_timer.start()

func _on_spawn_timer_timeout():
	if enemies.size() < max_enemies:
		var spawn_position = get_spawn_position()
		if spawn_position != Vector3.ZERO:
			var enemy = enemy_scene.instantiate()
			enemy.global_position = spawn_position
			enemy.player = player
			enemy.flock = enemies
			add_child(enemy)
			enemies.append(enemy)

func get_spawn_position() -> Vector3:
	if not is_inside_tree():
		print("Spawner not yet in scene tree. Cannot get spawn position.")
		return Vector3.ZERO  # Return Vector3.ZERO instead of null
	
	# Your existing logic to determine spawn position
	var spawn_position_2d = Vector2.ZERO  # Initialize with a default 2D vector
	# ... your existing code to calculate spawn position
	return Vector3(spawn_position_2d.x, spawn_position_2d.y, 0)  # Convert to Vector3

func _process(_delta):
	enemies = enemies.filter(func(enemy): return is_instance_valid(enemy))

func spawn_enemy():
	var spawn_position = get_spawn_position()  # Assuming this function exists and returns a Vector2 or Vector3
	var enemy_instance = EnemyScene.instantiate()
	enemy_instance.global_position = spawn_position
	add_child(enemy_instance)
