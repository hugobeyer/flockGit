extends CharacterBody3D


@export var offset_to_player: Vector3 = Vector3(2, 0, 0)
@export var enemy_hover_offset: Vector3 = Vector3(0, 2, 0)
@export var smoothness: float = 0.1
@export var speed: float = 5.0
@export var detection_radius: float = 10.0
@export var max_distance_from_player: float = 15.0
@export var move_to_enemy_time: float = 0.5
@export var hover_time: float = 1.0
@export var return_time: float = 0.5
@export var bounce_height: float = 0.5
@export var bounce_speed: float = 5.0
@export var noise_intensity_curve: Curve
@export var noise_time_scale: float = 1.0
@export var warning_lerp_speed: float = 2.0  # Control how fast the warning effect changes

var player: Node3D
var original_position: Vector3
var target_position: Vector3
var noise = FastNoiseLite.new()
var time: float = 0.0
var detection_area: Area3D
var take_damage: float = 0.0

enum State { WANDERING, MOVING_TO_ENEMY, HOVERING, RETURNING }
var current_state = State.WANDERING
var state_timer: float = 0.0
var current_enemy: Node3D = null


func _ready():

    noise.seed = randi()
    player = get_node("/root/Main/Player")  # Adjust this path if necessary
    create_detection_area()
    print("Buddy initialized")


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
    print("Detection area created with radius: ", detection_radius, " and collision mask: ", detection_area.collision_mask)

func _on_body_entered(body):
    print("Body entered detection area: ", body.name)
    if body.is_in_group("enemies") and current_state == State.WANDERING:
        print("Enemy detected: ", body.name)
        current_enemy = body
        change_state(State.MOVING_TO_ENEMY)

func change_state(new_state):
    print("Changing state from ", current_state, " to ", new_state)
    current_state = new_state
    state_timer = 0.0

func _physics_process(delta):
    time += delta
    state_timer += delta
    
    match current_state:
        State.WANDERING:
            handle_wandering(delta)
        State.MOVING_TO_ENEMY:
            handle_moving_to_enemy(delta)
        State.HOVERING:
            handle_hovering(delta)
        State.RETURNING:
            handle_returning(delta)
    
    # Ensure buddy doesn't go too far from player
    var distance_to_player = global_position.distance_to(player.global_position)
    if distance_to_player > max_distance_from_player:
        change_state(State.RETURNING)
    
    # Clamp the Y component of the target position to be at least 2.0
    target_position.y = max(target_position.y, 2.0)
    
    # Lerp position
    global_position = global_position.lerp(target_position, smoothness)
    
    # Ensure the final position is also not below 2.0
    global_position.y = max(global_position.y, 2.0)
    
    # Update buddy_warning
    var target_warning = 1.0 if current_state != State.WANDERING else 0.0
    take_damage = lerp(take_damage, target_warning, delta * warning_lerp_speed)

    
    print("Current state: ", State.keys()[current_state], ", Position: ", global_position, ", Target: ", target_position, ", Warning: ", take_damage)

func handle_wandering(delta):
    original_position = player.global_position + offset_to_player
    var noise_value = noise.get_noise_1d(time * noise_time_scale)
    var noise_intensity = noise_intensity_curve.sample(abs(noise_value))
    var noise_offset = Vector3(noise_value, noise.get_noise_1d(time * noise_time_scale + 100), 0) * noise_intensity
    target_position = original_position + noise_offset

func handle_moving_to_enemy(delta):
    pass
    # if is_instance_valid(current_enemy):
    #     target_position = current_enemy.global_position + enemy_hover_offset
    #     print("Moving to enemy. Target position: ", target_position)
    #     if state_timer >= move_to_enemy_time:
    #         change_state(State.HOVERING)
    # else:
    #     print("Current enemy is not valid")
    #     change_state(State.RETURNING)

func handle_hovering(delta):
    if is_instance_valid(current_enemy):
        var bounce_offset = Vector3.UP * sin(state_timer * bounce_speed) * bounce_height
        target_position = current_enemy.global_position + enemy_hover_offset + bounce_offset
        if state_timer >= hover_time:
            change_state(State.RETURNING)
    else:
        change_state(State.RETURNING)

func handle_returning(delta):
    original_position = player.global_position + offset_to_player
    target_position = original_position
    if state_timer >= return_time:
        change_state(State.WANDERING)
        current_enemy = null

func _process(_delta):
    var mesh_instance = $BuddyHead/BuddyMesh
    mesh_instance.set_instance_shader_parameter("take_damage", take_damage)
    if current_state == State.WANDERING:
        var overlapping_bodies = detection_area.get_overlapping_bodies()
        print("Number of overlapping bodies: ", overlapping_bodies.size())
        for body in overlapping_bodies:
            print("Overlapping body: ", body.name, ", in group 'enemies': ", body.is_in_group("enemies"))
            if body.is_in_group("enemies"):
                print("Enemy found in _process: ", body.name)
                current_enemy = body
                change_state(State.MOVING_TO_ENEMY)
                break