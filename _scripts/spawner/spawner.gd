extends Node3D

@export var enemy_scenes: Dictionary = {
    "basic": preload("res://_scenes/enemy_types/naked_imp.tscn"),
    "fast": preload("res://_scenes/enemy_types/fast_imp.tscn"),
    "tank": preload("res://_scenes/enemy_types/shielded_imp.tscn")
}


@export var min_spawn_radius: float = 15.0
@export var max_spawn_radius: float = 25.0
@export var spawn_height: float = 1.0
@export var below_ground_offset: float = 5.0
@export var rise_duration: float = 1.0
@export var max_enemies: int = 50
@export var min_spawn_interval: float = 0.5
@export var max_spawn_interval: float = 2.0
@export var min_cluster_points: int = 1
@export var max_cluster_points: int = 3
@export var min_enemies_per_cluster: int = 2
@export var max_enemies_per_cluster: int = 5
@export var cluster_radius: float = 5.0

var player: Node3D
var active_enemies: int = 0
var spawn_timer: Timer
var spawn_points: Array = []
var ai_director: Node

func set_ai_director(director: Node):
    ai_director = director

func _ready():
    ai_director = get_node("../AIDirector")
    player = get_parent().get_node("Player")
    if not player:
        push_error("Player not found at path: 'parent'/Player")
        return    
    setup_spawn_timer()
    SignalBus.connect("enemy_killed", Callable(self, "_on_enemy_killed"))

func setup_spawn_timer():
    spawn_timer = Timer.new()
    spawn_timer.timeout.connect(generate_spawn_points)
    add_child(spawn_timer)
    set_next_spawn_interval()

func set_next_spawn_interval():
    var next_interval = randf_range(min_spawn_interval, max_spawn_interval)
    spawn_timer.set_wait_time(next_interval)
    spawn_timer.start()

func generate_spawn_points():
    var num_clusters = randi_range(min_cluster_points, max_cluster_points)
    
    for _i in range(num_clusters):
        var cluster_center_radius = randf_range(min_spawn_radius, max_spawn_radius)
        var cluster_center_angle = randf() * 2 * PI
        var cluster_center = get_spawn_position(cluster_center_radius, cluster_center_angle)
        
        generate_cluster_points(cluster_center)
    
    replace_points_with_enemies()
    set_next_spawn_interval()

func generate_cluster_points(cluster_center: Vector3):
    var points_in_cluster = randi_range(min_enemies_per_cluster, max_enemies_per_cluster)
    
    for _i in range(points_in_cluster):
        if active_enemies + spawn_points.size() >= max_enemies:
            break
        
        var angle = randf() * 2 * PI
        var radius = randf() * cluster_radius
        var spawn_position = cluster_center + Vector3(cos(angle) * radius, 0, sin(angle) * radius)
        
        spawn_points.append(spawn_position)

func replace_points_with_enemies():
    for point in spawn_points:
        if active_enemies >= max_enemies:
            break
        spawn_enemy(point)
    
    spawn_points.clear()

func spawn_enemy(spawn_position: Vector3):
    var enemy_type = ai_director.get_enemy_type()
    var enemy_scene = enemy_scenes[enemy_type]
    var enemy_instance = enemy_scene.instantiate()
    var below_position = spawn_position - Vector3(0, below_ground_offset, 0)
    
    enemy_instance.global_position = below_position
    add_child(enemy_instance)
    
    # Apply AI Director parameters
    var enemy_params = ai_director.get_enemy_parameters(enemy_type)
    enemy_instance.max_health = enemy_params["health"]
    enemy_instance.movement_speed = enemy_params["speed"]
    enemy_instance.damage = enemy_params["damage"]
    
    var flocking_params = ai_director.get_flocking_parameters()
    enemy_instance.flock_separation_weight = flocking_params["separation_weight"]
    enemy_instance.flock_alignment_weight = flocking_params["alignment_weight"]
    enemy_instance.flock_cohesion_weight = flocking_params["cohesion_weight"]
    
    # Wait for the rising animation to complete
    var tween = create_tween()
    tween.tween_property(enemy_instance, "global_position", spawn_position, rise_duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

    if enemy_instance.has_method("initialize"):
        enemy_instance.initialize(self)

    # Wait for the rising animation to complete
    await tween.finished

    # If there's a custom physics enable method, call it
    if enemy_instance.has_method("set_physics_enabled"):
        enemy_instance.set_physics_enabled(true)

    enemy_instance.connect("enemy_killed", Callable(SignalBus, "emit_signal").bind("enemy_killed"))

    active_enemies += 1

func get_spawn_position(radius: float, angle: float) -> Vector3:
    var player_pos = get_player_position()
    var x = cos(angle) * radius
    var z = sin(angle) * radius
    return Vector3(x, spawn_height, z) + player_pos

func get_player_position() -> Vector3:
    if player:
        return player.global_position
    else:
        push_error("Player reference is null in get_player_position")
        return Vector3.ZERO

func _on_enemy_killed():
    active_enemies -= 1
