extends Camera3D

@export var player_pos: Node3D
@export var camera_offset: Vector3 = Vector3(55, 64, 44)
@export var max_offset: float = 20.0
@export_range(0, 1, 0.001) var attraction_strength: float = 0.6
@export_range(0, 1, 0.001) var damping: float = 0.5
@export_range(0, 1, 0.001) var blend_factor: float = 0.5
@export_range(0, 1, 0.001) var look_adjust_strength: float = 0.25
@export_range(0, 1, 0.001) var enemies_average_smoothing: float = 0.5

var camera_velocity: Vector3 = Vector3.ZERO
var smoothed_enemies_average: Vector3 = Vector3.ZERO

func _ready():
    smoothed_enemies_average = player_pos.global_position
    if not player_pos:
        player_pos = get_parent()
        if not player_pos:
            push_error("Player node not found. Please assign it in the editor or ensure the path is correct.")

func _process(delta):
    if player_pos:
        update_camera_position(delta)

func update_camera_position(delta):
    var player_target_position = player_pos.global_position + camera_offset
    var enemies_average = calculate_enemies_average()
    smoothed_enemies_average = smoothed_enemies_average.lerp(enemies_average, delta * (enemies_average_smoothing * 20.0))
    var blended_target_position = player_target_position.lerp(smoothed_enemies_average + camera_offset, blend_factor)
    
    apply_camera_movement(blended_target_position, delta)
    
    var look_blend = blend_factor * look_adjust_strength
    var look_target = player_pos.global_position.lerp(smoothed_enemies_average, look_blend)
    look_at(look_target, Vector3.UP)

func calculate_enemies_average() -> Vector3:
    var enemies = get_tree().get_nodes_in_group("enemies")
    if enemies.is_empty():
        return player_pos.global_position
    
    var sum = Vector3.ZERO
    for enemy in enemies:
        sum += enemy.global_position
    return sum / enemies.size()

func apply_camera_movement(target_position: Vector3, delta: float):
    var direction_to_target = target_position - global_position
    var distance_to_target = direction_to_target.length()
    
    if distance_to_target > max_offset:
        direction_to_target = direction_to_target.normalized() * max_offset
        target_position = global_position + direction_to_target
    
    var force = direction_to_target * (attraction_strength * 16)
    camera_velocity += force * delta
    camera_velocity = camera_velocity.lerp(Vector3.ZERO, (damping * 4.0) * delta)
    global_position += camera_velocity * delta
