extends CharacterBody3D

@export var offset_to_player: Vector3 = Vector3(2, 2, 0)
@export var speed: float = 5.0
@export var max_speed: float = 15.0
@export var detection_radius: float = 10.0  # Radius to detect enemies
@export var hover_height: float = 1.5
@export var hover_force: float = 20.0
@export var ground_check_distance: float = 2.0
@export var warning_duration: float = 1.0
@export var warning_bounce_distance: float = 2.0
@export var warning_cooldown: float = 5.0
@export var warning_curve: Curve
@export var warning_time: float = 0.6  # Total time for the warning animation

var player: Node3D
var current_enemies: Array = []
var warning_tween: Tween
var warning_target_position: Vector3
var is_warning: bool = false
var cooldown_timer: float = 0.0
var warning_progress: float = 0.0

@onready var ground_check: RayCast3D
@onready var mesh: MeshInstance3D = $MeshInstance3D  # Assuming you have a MeshInstance3D as a child

func _ready():
    player = get_node("/root/Main/Player")
    global_position = player.global_position + offset_to_player
    
    if not has_node("GroundCheck"):
        ground_check = RayCast3D.new()
        ground_check.name = "GroundCheck"
        add_child(ground_check)
    else:
        ground_check = $GroundCheck
    
    ground_check.enabled = true
    ground_check.target_position = Vector3(0, -ground_check_distance, 0)

func _physics_process(delta):
    detect_enemies()
    
    if cooldown_timer > 0:
        cooldown_timer -= delta
    
    if not is_warning and cooldown_timer <= 0:
        var nearest_enemy = get_nearest_enemy()
        if nearest_enemy:
            start_warning(nearest_enemy)
    
    apply_hover_force(delta)
    
    if not is_warning:
        # Move towards player when not warning
        var target_position = player.global_position + offset_to_player
        var move_direction = (target_position - global_position).normalized()
        velocity = velocity.move_toward(move_direction * max_speed, speed * delta)
    else:
        # Define move_direction when warning
        var move_direction = (warning_target_position - global_position).normalized()
        velocity = velocity.move_toward(move_direction * max_speed, speed * delta)
    
    move_and_slide()
    
    if global_position.y < hover_height:
        global_position.y = hover_height
        velocity.y = 0

func detect_enemies():
    current_enemies.clear()
    var potential_enemies = get_tree().get_nodes_in_group("enemies")
    
    for enemy in potential_enemies:
        if enemy.global_position.distance_to(global_position) <= detection_radius:
            current_enemies.append(enemy)

func get_nearest_enemy() -> Node3D:
    var nearest = null
    var nearest_distance = INF
    for enemy in current_enemies:
        var distance = enemy.global_position.distance_to(global_position)
        if distance < nearest_distance:
            nearest = enemy
            nearest_distance = distance
    return nearest

func start_warning(enemy: Node3D):
    is_warning = true
    var mid_point = (player.global_position + enemy.global_position) / 2
    var direction_to_enemy = (enemy.global_position - mid_point).normalized()
    var start_pos = global_position
    var end_pos = mid_point + direction_to_enemy * warning_bounce_distance
    
    warning_tween = create_tween()
    warning_tween.set_ease(Tween.EASE_IN_OUT)
    warning_tween.set_trans(Tween.TRANS_CUBIC)
    
    # Move to mid-point
    warning_tween.tween_method(
        func(t: float):
            global_position = start_pos.slerp(mid_point, t),
        0.0, 1.0, 0.2
    )
    
    # Bounce towards enemy
    warning_tween.tween_method(
        func(t: float):
            if warning_curve:
                t = warning_curve.sample(t)
            warning_progress = t
            global_position = mid_point.slerp(end_pos, t),
        0.0, 1.0, warning_time / 2
    )
    
    # Return to mid-point
    warning_tween.tween_method(
        func(t: float):
            if warning_curve:
                t = 1 - warning_curve.sample(1 - t)
            warning_progress = 1 - t
            global_position = end_pos.slerp(mid_point, t),
        0.0, 1.0, warning_time / 2
    )
    
    # Wait at the mid-point
    warning_tween.tween_interval(warning_duration - warning_time - 0.4)
    
    # Return to start position
    warning_tween.tween_method(
        func(t: float):
            global_position = mid_point.slerp(start_pos, t),
        0.0, 1.0, 0.2
    )
    
    warning_tween.tween_callback(end_warning)
    
    # Shader effect
    warning_tween.parallel().tween_method(set_shader_param, 0.0, 1.0, warning_duration)

func end_warning():
    is_warning = false
    warning_target_position = Vector3.ZERO
    set_shader_param(0.0)  # Reset shader parameter
    cooldown_timer = warning_cooldown

func set_shader_param(value: float):
    if mesh:
        mesh.set_instance_shader_parameter("lerp_wave", value)

func apply_hover_force(delta):
    if ground_check.is_colliding():
        var collision_point = ground_check.get_collision_point()
        var distance_to_ground = global_position.y - collision_point.y
        if distance_to_ground < hover_height:
            var force = (hover_height - distance_to_ground) * hover_force
            velocity.y += force * delta
    else:
        velocity.y -= 9.8 * delta  # Apply gravity if not near ground