extends RigidBody3D

@export var offset_to_player: Vector3 = Vector3(2, 2, 0)
@export var speed: float = 5.0
@export var max_speed: float = 15.0
@export var detection_radius: float = 10.0
@export var protection_radius: float = 5.0
@export var max_distance_from_player: float = 15.0
@export var noise_intensity: float = 2.0
@export var noise_time_scale: float = 1.0
@export var orbit_speed: float = 2.0
@export var orbit_radius: float = 3.0
@export var push_force: float = 20.0
@export var push_duration: float = 0.5
@export var cooldown_duration: float = 3.0
@export var fear_threshold: int = 5
@export var bravery_recovery_rate: float = 0.1
@export var attraction_force: float = 5.0
@export var bounce_force: float = 10.0

var player: Node3D
var target_position: Vector3
var noise = FastNoiseLite.new()
var time: float = 0.0
var detection_area: Area3D
var warning_effect: float = 0.0
var bravery: float = 1.0
var push_timer: float = 0.0
var cooldown_timer: float = 0.0

enum State { ORBITING, PUSHING, FLEEING, RETURNING }
var current_state = State.ORBITING
var current_enemies: Array = []
var orbit_angle: float = 0.0

@onready var buddy_mesh: MeshInstance3D = $BuddyHead/BuddyMesh

func _ready():
    noise.seed = randi()
    noise.fractal_octaves = 4
    noise.frequency = 0.5
    player = get_node("/root/Main/Player")
    global_position = player.global_position + offset_to_player
    create_detection_area()
    set_as_top_level(true)
    contact_monitor = true
    max_contacts_reported = 4
    connect("body_entered", Callable(self, "_on_body_entered"))
    # print("Buddy initialized")

func create_detection_area():
    detection_area = Area3D.new()
    var collision_shape = CollisionShape3D.new()
    var sphere_shape = SphereShape3D.new()
    
    sphere_shape.radius = detection_radius
    collision_shape.shape = sphere_shape
    
    detection_area.add_child(collision_shape)
    add_child(detection_area)
    
    detection_area.collision_mask = 0b10  # Set to detect layer 2
    detection_area.connect("body_entered", Callable(self, "_on_body_entered"))
    detection_area.connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body):
    if body.is_in_group("enemies") and body not in current_enemies:
        current_enemies.append(body)

func _on_body_exited(body):
    if body.is_in_group("enemies"):
        current_enemies.erase(body)

func change_state(new_state):
    # print("Changing state from ", current_state, " to ", new_state)
    current_state = new_state
    if new_state == State.PUSHING:
        push_timer = 0.0

func _physics_process(delta):
    time += delta
    cooldown_timer -= delta
    
    match current_state:
        State.ORBITING:
            handle_orbiting(delta)
        State.PUSHING:
            handle_pushing(delta)
        State.FLEEING:
            handle_fleeing(delta)
        State.RETURNING:
            handle_returning(delta)
    
    if global_position.distance_to(player.global_position) > max_distance_from_player:
        change_state(State.RETURNING)
    
    update_warning_effect(delta)
    update_bravery(delta)

func handle_orbiting(delta):
    orbit_angle += orbit_speed * delta
    var target_position = calculate_orbit_position()
    
    var attraction = (target_position - global_position).normalized() * attraction_force
    apply_central_force(attraction)
    
    check_for_threats()

func calculate_orbit_position() -> Vector3:
    var orbit_offset = Vector3(cos(orbit_angle), sin(orbit_angle) * 0.5, sin(orbit_angle)) * orbit_radius
    return player.global_position + offset_to_player + orbit_offset

func handle_pushing(delta):
    push_timer += delta
    if push_timer <= push_duration:
        var push_direction = (global_position - player.global_position).normalized()
        apply_central_force(push_direction * push_force)
        
        for enemy in current_enemies:
            if is_instance_valid(enemy):
                var push_vector = (enemy.global_position - global_position).normalized() * push_force
                if enemy is RigidBody3D:
                    enemy.apply_central_impulse(push_vector)
                elif enemy.has_method("apply_impulse"):
                    enemy.apply_impulse(push_vector)
                else:
                    enemy.global_position += push_vector * delta
    else:
        cooldown_timer = cooldown_duration
        change_state(State.ORBITING)

func handle_fleeing(delta):
    var flee_direction = (global_position - player.global_position).normalized()
    apply_central_force(flee_direction * max_speed)

func handle_returning(delta):
    var return_vector = (player.global_position + offset_to_player - global_position).normalized() * max_speed
    apply_central_force(return_vector)
    if global_position.distance_to(player.global_position + offset_to_player) < 1.0:
        change_state(State.ORBITING)

func update_warning_effect(delta):
    var target_warning = 1.0 if current_state in [State.PUSHING, State.FLEEING] else 0.0
    warning_effect = lerp(warning_effect, target_warning, delta * 5.0)
    buddy_mesh.set_instance_shader_parameter("lerp_wave", warning_effect)

func check_for_threats():
    if cooldown_timer <= 0:
        var close_enemies = 0
        for enemy in current_enemies:
            if is_instance_valid(enemy) and enemy.global_position.distance_to(player.global_position) < protection_radius:
                close_enemies += 1
        
        if close_enemies > 0 and bravery > 0.5 and current_state == State.ORBITING:
            change_state(State.PUSHING)
        elif close_enemies >= fear_threshold or bravery <= 0.2:
            change_state(State.FLEEING)

func update_bravery(delta):
    var enemy_count = len(current_enemies)
    if enemy_count > 0:
        bravery = max(bravery - delta * enemy_count * 0.1, 0.0)
    else:
        bravery = min(bravery + delta * bravery_recovery_rate, 1.0)

func _integrate_forces(state):
    if state.linear_velocity.length() > max_speed:
        state.linear_velocity = state.linear_velocity.normalized() * max_speed

func _process(_delta):
    check_for_threats()