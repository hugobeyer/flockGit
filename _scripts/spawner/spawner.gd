extends Node3D

@export var enemy_scene: PackedScene
@export var spawn_radius: float = 20.0
@export var spawn_height: float = 1.0  # Added spawn height
@export var max_enemies: int = 50
@export var spawn_interval: float = 1.0
@export var physics_enable_delay: float = 0.01  # Delay before enabling physics

var player: Node3D
var active_enemies: int = 0
var spawn_timer: Timer

func _ready():
    player = get_node("/root/Main/Player")
    if not player:
        push_error("Player not found at path: /root/Main/Player")
        return    
    setup_spawn_timer()

func setup_spawn_timer():
    spawn_timer = Timer.new()
    spawn_timer.set_wait_time(spawn_interval)
    spawn_timer.timeout.connect(spawn_enemy)
    add_child(spawn_timer)
    spawn_timer.start()

func spawn_enemy():
    if active_enemies >= max_enemies:
        return
    
    var enemy = enemy_scene.instantiate()
    var spawn_position = get_random_spawn_position()
    
    # Set enemy position before adding it to the scene tree
    enemy.global_position = spawn_position
    
    # Now add the enemy to the scene tree
    add_child(enemy)

    # Initialize enemy if needed
    if enemy.has_method("initialize"):
        enemy.initialize(self)

    # Delay enabling physics if needed
    if enemy.has_method("set_physics_enabled"):
        await get_tree().create_timer(physics_enable_delay).timeout
        enemy.set_physics_enabled(true)

    active_enemies += 1

func get_random_spawn_position() -> Vector3:
    var random_angle = randf() * 2 * PI
    var x = cos(random_angle) * spawn_radius
    var z = sin(random_angle) * spawn_radius
    return Vector3(x, spawn_height, z) + global_position

func get_player_position() -> Vector3:
    if player:
        return player.global_position
    else:
        push_error("Player reference is null in get_player_position")
        return Vector3.ZERO
