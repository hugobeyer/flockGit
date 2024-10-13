extends CharacterBody3D

# Exported variables for easy tuning
@export_group("Movement")
@export var hover_height: float = 1.5
@export var hover_radius: float = 3.0
@export var follow_speed: float = 5.0
@export var charge_speed: float = 15.0
@export var detection_radius: float = 15.0  # Radius to detect enemies
@export var push_force: float = 20.0
@export var wander_speed: float = 3.0  # Speed of wandering movement
@export var offset_to_player: Vector3 = Vector3(0, 4 ,0)  # Offset position relative to the player

@export_group("Behavior")
@export var fear_threshold: int = 4  # Number of enemies to trigger fear
@export var courage_threshold: int = 1  # Number of enemies to trigger courage
@export var warning_duration: float = 2.0
@export var warning_cooldown: float = 5.0
@export var spiral_attack_duration: float = 1.5

# Internal variables
var player: Node3D
var current_enemies: Array = []
var is_warning: bool = false
var cooldown_timer: float = 0.0
var behavior_state: String = "Idle"
var charging: bool = false
var charging_target_position: Vector3
var original_scale: Vector3
var spiral_attack_timer: float = 0.0
var is_shaking: bool = false
var warning_timer: float = 0.0  # Timer for the warning animation
var noise: FastNoiseLite

@onready var mesh: MeshInstance3D = $BuddyHead/BuddyMesh  # Reference to the buddy's mesh instance

func _ready():
    player = get_parent().get_node("Player")
    if player:
        global_position = player.global_position + offset_to_player
    original_scale = scale
    set_behavior("Idle")
    
    # Initialize noise generator for wandering
    noise = FastNoiseLite.new()
    noise.seed = randi()
    noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX_SMOOTH
    noise.frequency = 0.5  # Adjust frequency as needed to control smoothness of wandering

func _process(delta):
    if not player:
        return

    detect_enemies()
    determine_behavior()
    perform_behavior(delta)
    face_direction(delta)
    
    if is_shaking:
        apply_shake(delta)
    
    if is_warning:
        update_warning_animation(delta)

func get_bbox_center(target: Node3D) -> Vector3:
    return target.global_position  # Assuming enemies are spheres with their origin at the center

func detect_enemies():
    current_enemies.clear()
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        var enemy_center = get_bbox_center(enemy)
        if enemy_center.distance_to(global_position) <= detection_radius:
            current_enemies.append(enemy)

func determine_behavior():
    if is_warning or charging:
        return  # Don't change behavior during warning or charging

    var enemy_count = current_enemies.size()
    if enemy_count >= fear_threshold:
        set_behavior("Fear")
    elif enemy_count >= courage_threshold:
        set_behavior("Charge")
    else:
        set_behavior("Wander")

func perform_behavior(delta):
    if behavior_state == "Follow":
        follow_player(delta)
    elif behavior_state == "Charge":
        if not charging:
            initiate_charge()
        else:
            perform_charge(delta)
    elif behavior_state == "Fear":
        flee_to_player(delta)
    elif behavior_state == "Wander":
        wander_around_player(delta)

    if cooldown_timer > 0:
        cooldown_timer -= delta
    elif current_enemies.size() > 0 and not is_warning:
        start_warning()

    # Return to player's offset position after the behavior is complete
    if behavior_state == "Idle" or behavior_state == "Wander":
        return_to_offset(delta)

func set_behavior(new_behavior: String):
    if behavior_state == new_behavior:
        return
    behavior_state = new_behavior

    # Reset any procedural effects from previous behaviors
    is_shaking = false
    scale = original_scale

    if behavior_state == "Charge":
        start_shaking()
    elif behavior_state == "Fear":
        start_shaking()

func follow_player(delta):
    var target_position = player.global_position + offset_to_player
    var move_direction = (target_position - global_position).normalized()
    velocity = move_direction * follow_speed
    move_and_slide()

func wander_around_player(delta):
    var player_center = player.global_position
    var noise_offset_x = noise.get_noise_2d(get_process_delta_time() * 0.5, 0) * hover_radius
    var noise_offset_z = noise.get_noise_2d(0, get_process_delta_time() * 0.5) * hover_radius

    var target_position = player_center + Vector3(noise_offset_x, hover_height, noise_offset_z) + offset_to_player
    var move_direction = (target_position - global_position).normalized()
    velocity = move_direction * wander_speed
    move_and_slide()

func initiate_charge():
    var nearest_enemy = get_nearest_enemy()
    if nearest_enemy:
        charging_target_position = get_bbox_center(nearest_enemy)
        charging = true
        scale = original_scale * 1.5  # Increase size to indicate charging
        spiral_attack_timer = spiral_attack_duration

func perform_charge(delta):
    if charging:
        var target_position: Vector3

        if spiral_attack_timer > 0:
            spiral_attack_timer -= delta
            var angle = get_process_delta_time() * 5.0
            var spiral_offset = Vector3(sin(angle), 0, cos(angle)) * 0.5
            target_position = charging_target_position + spiral_offset
        else:
            target_position = charging_target_position

        var move_direction = (target_position - global_position).normalized()
        velocity = move_direction * charge_speed
        move_and_slide()

        if global_position.distance_to(charging_target_position) < 1.0:
            push_nearest_enemy()
            charging = false
            set_behavior("Wander")  # Return to wandering after charge

func flee_to_player(delta):
    var player_center = player.global_position
    var direction_to_player = (player_center - global_position).normalized()
    var behind_player_position = player_center - direction_to_player * 2.0
    var move_direction = (behind_player_position - global_position).normalized()
    velocity = move_direction * follow_speed
    move_and_slide()

    is_shaking = true  # Shake to indicate fear

func start_shaking():
    is_shaking = true

func apply_shake(delta):
    var shake_amount = 0.05
    rotation.x = sin(get_process_delta_time() * 0.05) * shake_amount
    rotation.z = cos(get_process_delta_time() * 0.05) * shake_amount

func start_warning():
    is_warning = true
    cooldown_timer = warning_cooldown
    warning_timer = warning_duration

func update_warning_animation(delta):
    if warning_timer > 0.0:
        warning_timer -= delta
        var t = sin((warning_duration - warning_timer) * 20.0) * 0.5 + 0.5  # Oscillate between 0 and 1
        mesh.set_instance_shader_parameter("lerp_wave", t)
    else:
        is_warning = false
        mesh.set_instance_shader_parameter("lerp_wave", 0.0)

func push_nearest_enemy():
    var nearest_enemy = get_nearest_enemy()
    if nearest_enemy and nearest_enemy.has_method("apply_impulse"):
        var push_direction = (get_bbox_center(nearest_enemy) - global_position).normalized()
        nearest_enemy.apply_impulse(push_direction * -push_force)

func get_nearest_enemy() -> Node3D:
    var nearest = null
    var nearest_distance = INF
    for enemy in current_enemies:
        var enemy_center = get_bbox_center(enemy)
        var distance = enemy_center.distance_to(global_position)
        if distance < nearest_distance:
            nearest = enemy
            nearest_distance = distance
    return nearest

func return_to_offset(delta):
    var target_position = player.global_position + offset_to_player
    var move_direction = (target_position - global_position).normalized()
    velocity = move_direction * follow_speed
    move_and_slide()

func face_direction(delta):
    if velocity.length() > 0.1:
        var target_rotation = atan2(-velocity.x, -velocity.z)
        rotation.y = lerp_angle(rotation.y, target_rotation, 5 * delta)
