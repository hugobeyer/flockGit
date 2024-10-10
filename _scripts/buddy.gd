extends CharacterBody3D

# Exported variables for easy tuning
@export_group("Movement")
@export var offset_to_player: Vector3 = Vector3(2, 0, 0)
@export var hover_radius: float = 3.0
@export var follow_speed: float = 5.0
@export var wander_speed: float = 2.0
@export var charge_speed: float = 8.0
@export var detection_radius: float = 15.0  # Radius to detect enemies
@export var push_force: float = 10.0

@export_group("Behavior")
@export var fear_threshold: int = 3  # Number of enemies to trigger fear
@export var courage_threshold: int = 1  # Number of enemies to trigger courage
@export var warning_duration: float = 2.0
@export var warning_cooldown: float = 5.0

# Internal variables
var player: Node3D
var current_enemies: Array = []
var is_warning: bool = false
var cooldown_timer: float = 0.0
var behavior_state: String = "Idle"
var wander_timer: float = 0.0
var wander_direction: Vector3 = Vector3.ZERO
var original_scale: Vector3
var shake_timer: float = 0.0
var is_shaking: bool = false
var noise: FastNoiseLite

@onready var mesh: MeshInstance3D = $BuddyHead/BuddyMesh  # Reference to the buddy's mesh instance
@onready var tween: Tween = $Tween  # Reference to a Tween node for animations

func _ready():
    player = get_node("/root/Main/Player")
    global_position = player.global_position + offset_to_player
    original_scale = scale
    set_behavior("Idle")
    
    # Initialize noise generator
    noise = FastNoiseLite.new()
    noise.seed = randi()
    noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX_SMOOTH
    noise.frequency = 1.0  # Adjust frequency as needed

func _process(delta):
    if not player:
        return

    detect_enemies()
    determine_behavior()
    perform_behavior(delta)
    face_direction(delta)
    if is_shaking:
        apply_shake(delta)

func detect_enemies():
    # Use the detection radius to find enemies
    current_enemies.clear()
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        if enemy.global_position.distance_to(global_position) <= detection_radius:
            current_enemies.append(enemy)

func determine_behavior():
    if is_warning:
        return  # Don't change behavior during warning

    var enemy_count = current_enemies.size()
    if enemy_count >= fear_threshold:
        set_behavior("Fear")
    elif enemy_count >= courage_threshold:
        set_behavior("Charge")
    else:
        # Alternate between following and wandering
        if behavior_state != "Wander" and randf() < 0.01:
            set_behavior("Wander")
            wander_timer = randf_range(2.0, 5.0)
        elif behavior_state != "Follow":
            set_behavior("Follow")

func perform_behavior(delta):
    match behavior_state:
        "Follow":
            follow_player_with_hover(delta)
        "Wander":
            wander_around_player(delta)
        "Charge":
            charge_enemy()
        "Fear":
            flee_to_player(delta)

    if cooldown_timer > 0:
        cooldown_timer -= delta
    elif current_enemies.size() > 0 and not is_warning:
        start_warning()

func set_behavior(new_behavior: String):
    if behavior_state == new_behavior:
        return
    behavior_state = new_behavior

    # Reset any procedural effects from previous behaviors
    is_shaking = false
    scale = original_scale
    rotation.x = 0
    rotation.z = 0

    if behavior_state == "Charge":
        start_shaking()
    elif behavior_state == "Fear":
        start_shaking()

func follow_player_with_hover(delta):
    # Move around the player in a circle while hovering
    var time = float(Time.get_ticks_msec()) / 1000.0
    var hover_offset = Vector3(
        sin(time) * hover_radius,
        0,
        cos(time) * hover_radius
    )
    var target_position = player.global_position + hover_offset
    var move_direction = (target_position - global_position).normalized()
    velocity = move_direction * follow_speed
    move_and_slide()

func wander_around_player(delta):
    if wander_timer > 0:
        wander_timer -= delta
        var time = float(Time.get_ticks_msec()) / 1000.0
        var noise_x = noise.get_noise_2d(time, 0)
        var noise_z = noise.get_noise_2d(0, time)
        var noise_vector = Vector3(noise_x, 0, noise_z).normalized()
        var target_position = player.global_position + noise_vector * hover_radius
        var move_direction = (target_position - global_position).normalized()
        velocity = move_direction * wander_speed
        move_and_slide()
    else:
        set_behavior("Follow")

func charge_enemy():
    var nearest_enemy = get_nearest_enemy()
    if nearest_enemy:
        # Move beside the player before charging
        var side_position = player.global_position + Vector3(1.5, 0, 1.5)  # Position to the side of the player
        var direction_to_enemy = (nearest_enemy.global_position - side_position).normalized()

        # Tween movement towards the enemy, with a swirling effect
        tween.interpolate_property(self, "global_position", global_position, nearest_enemy.global_position + direction_to_enemy * 2.0, 0.5,
            Tween.TRANS_SINE, Tween.EASE_IN_OUT)
        tween.start()

        # After push, tween back to the player
        tween.interpolate_callback(self, 0.5, "return_to_player")

        # Increase size slightly during charge
        scale = original_scale * 1.2

func return_to_player():
    # Return to the player after charging
    tween.interpolate_property(self, "global_position", global_position, player.global_position + offset_to_player, 0.5,
        Tween.TRANS_SINE, Tween.EASE_IN_OUT)
    tween.start()

    # Reset scale
    scale = original_scale

func flee_to_player(delta):
    # Move behind the player when afraid
    var direction_to_player = (player.global_position - global_position).normalized()
    var behind_player_position = player.global_position - direction_to_player * 2.0  # 2 units behind the player
    var move_direction = (behind_player_position - global_position).normalized()
    velocity = move_direction * follow_speed
    move_and_slide()

    # Start shaking effect for fear indication
    is_shaking = true

func start_shaking():
    is_shaking = true
    shake_timer = 0.5  # Shake duration

func apply_shake(delta):
    if shake_timer > 0:
        shake_timer -= delta
        var shake_amount = 0.05
        rotation.x = sin(Time.get_ticks_msec() * 0.05) * shake_amount
        rotation.z = cos(Time.get_ticks_msec() * 0.05) * shake_amount
    else:
        is_shaking = false
        rotation.x = 0
        rotation.z = 0

func start_warning():
    is_warning = true
    cooldown_timer = warning_cooldown
    perform_warning_animation()
    is_warning = false

func perform_warning_animation():
    var elapsed_time = 0.0
    while elapsed_time < warning_duration:
        elapsed_time += get_process_delta_time()
        var t = sin(elapsed_time * 20.0) * 0.5 + 0.5  # Oscillate between 0 and 1

        # Modify the shader parameter using the override material
        mesh.set_instance_shader_parameter("lerp_wave", t)
        
        # Use a slight delay to create a smooth animation
        get_tree().process_frame

    # Reset the shader parameter after the animation ends
    mesh.set_instance_shader_parameter("lerp_wave", 0.0)

func push_enemy(enemy):
    if enemy and enemy.has_method("apply_impulse"):
        var push_direction = (enemy.global_position - global_position).normalized()
        enemy.apply_impulse(push_direction * push_force)
    else:
        # Apply knockback if enemy doesn't have apply_impulse
        if enemy.has_method("knockback"):
            var push_vector = (enemy.global_position - global_position).normalized() * push_force
            enemy.knockback(push_vector)

func get_nearest_enemy() -> Node3D:
    var nearest = null
    var nearest_distance = INF
    for enemy in current_enemies:
        var distance = enemy.global_position.distance_to(global_position)
        if distance < nearest_distance:
            nearest = enemy
            nearest_distance = distance
    return nearest

func face_direction(delta):
    if velocity.length() > 0.1:
        var target_rotation = atan2(-velocity.x, -velocity.z)
        rotation.y = lerp_angle(rotation.y, target_rotation, 5 * delta)
