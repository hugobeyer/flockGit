# This script is for movement (attached to the Player (CharacterBody3D))
extends CharacterBody3D

@export var SPEED: float = 6.0
@export var INITIAL_RECOIL_VELOCITY: float = 1.0
@export var RECOIL_PUSHBACK_VELOCITY: float = 2.0
@export var ANGULAR_RECOIL_DAMPING: float = 5.0
@export var LINEAR_RECOIL_DAMPING: float = 3.0
@export var RECOIL_INTENSITY_VARIATION: float = 0.2
@export var MAX_RECOIL_INTENSITY: float = 2.0
@export var MAX_RECOIL_RAMP_TIME: float = 2.0
@export var RECOIL_RAMP_CURVE: Curve

@export var recoil_reset: float = 0.5
@export var recovery_time: float = 0.05
@export var bump: float = 0.02
@export var recoil: float = 0.05

@export var debug_node_offset: Vector3 = Vector3(0, 1, 2)  # Adjust this offset as needed

@onready var camera: Camera3D = get_node("/root/Main/GameCamera")
@onready var debug_touch: Node3D = get_node("/root/Main/debug_touch")
@onready var gun = $Gun
@onready var recoil_bar: Sprite3D = $RecoilBar  # Adjust the path if necessary
@onready var playerSelf: CharacterBody3D
@onready var floormesh: MeshInstance3D = get_node("/root/Main/FloorStatic/FloorMesh")
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var recoil_pattern = [
    [1, recoil, -recoil/2, 0.77, 1],
    [6, bump/2.0, -bump/4, 0.77, -1],
    [11, bump/2.0, -bump/4, 0.77, 1],
]

var cur_shots: int = 0
var last_shot: float = 0
var is_firing: bool = false
var recoil_rotation: float = 0.0
var recoil_velocity: Vector3 = Vector3.ZERO
var fire_start_time: float = 0.0

func _ready():
    if RECOIL_RAMP_CURVE == null:
        RECOIL_RAMP_CURVE = Curve.new()
        RECOIL_RAMP_CURVE.add_point(Vector2(0, 1))
        RECOIL_RAMP_CURVE.add_point(Vector2(1, 2))
    playerSelf = get_node("/root/Main/Player")
    global_position = playerSelf.global_position

func _process(delta):
    floormesh.set_instance_shader_parameter("player_position", global_position)

func _physics_process(delta):
    if not is_on_floor():
        velocity.y -= gravity * delta

    handle_movement(delta)
    handle_touch_input()
    #update_debug_node_position()  # Add this line
    
    if is_firing:
        shoot_recoil()
    
    rotation.y += recoil_rotation
    velocity += recoil_velocity
    
    recoil_rotation = move_toward(recoil_rotation, 0, delta * ANGULAR_RECOIL_DAMPING)
    recoil_velocity = recoil_velocity.move_toward(Vector3.ZERO, delta * LINEAR_RECOIL_DAMPING)
    
    update_recoil_bar()  # Add this line
    
    move_and_slide()

func handle_movement(delta):
    var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
    var direction = (camera.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
    if direction:
        velocity.x = direction.x * SPEED
        velocity.z = direction.z * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
        velocity.z = move_toward(velocity.z, 0, SPEED)

func handle_touch_input():
    if Input.is_action_pressed("touch"):
        var target_rotation = debug_touch.rotation.y
        rotation.y = target_rotation

func shoot_recoil():
    var current_time = Time.get_ticks_msec() / 1000.0
    
    if current_time - last_shot > recoil_reset:
        cur_shots = 1
        recoil_rotation = 0
        recoil_velocity = Vector3.ZERO
        fire_start_time = current_time
    else:
        cur_shots += 1
    
    last_shot = current_time
    
    if cur_shots >= 11:
        cur_shots = 2
    
    var ramp_time = min(current_time - fire_start_time, MAX_RECOIL_RAMP_TIME)
    var ramp_factor = RECOIL_RAMP_CURVE.sample(ramp_time / MAX_RECOIL_RAMP_TIME)
    
    var intensity_multiplier = ramp_factor * clamp((-1.0 + randf_range(-RECOIL_INTENSITY_VARIATION, RECOIL_INTENSITY_VARIATION)),0,1)
    
    var initial_recoil = INITIAL_RECOIL_VELOCITY * intensity_multiplier * (1 if randf() > 0.5 else -1)
    apply_recoil_rotation(initial_recoil)
    
    var pushback_direction = -global_transform.basis.z
    var pushback_velocity = pushback_direction * RECOIL_PUSHBACK_VELOCITY * intensity_multiplier
    apply_recoil_velocity(pushback_velocity)
    
    for pattern in recoil_pattern:
        if cur_shots <= pattern[0]:
            apply_recoil_pattern(pattern, intensity_multiplier)
            break

func apply_recoil_pattern(pattern, intensity_multiplier: float):
    var num = 0.0
    while abs(num - float(pattern[1])) > 0.0001:
        num = lerp(num, float(pattern[1]), pattern[3])
        var rec = num * intensity_multiplier
        apply_recoil_rotation(rec * pattern[4])
        await get_tree().process_frame
    
    while abs(num - float(pattern[2])) > 0.0001:
        num = lerp(num, float(pattern[2]), pattern[3])
        var rec = num * intensity_multiplier
        apply_recoil_rotation(rec * pattern[4])
        await get_tree().process_frame

func apply_recoil_rotation(rotation_amount: float):
    recoil_rotation += rotation_amount
    
    var max_rotation = deg_to_rad(MAX_RECOIL_INTENSITY * 10)
    recoil_rotation = clamp(recoil_rotation, -max_rotation, max_rotation)

func apply_recoil_velocity(pushback_velocity: Vector3):
    var current_recoil_intensity = recoil_velocity.length()
    var new_recoil_intensity = current_recoil_intensity + pushback_velocity.length()
    if new_recoil_intensity > MAX_RECOIL_INTENSITY:
        var scale_factor = 1.0 - (new_recoil_intensity - MAX_RECOIL_INTENSITY) / new_recoil_intensity
        pushback_velocity *= scale_factor
    
    recoil_velocity += pushback_velocity

func _input(event):
    if event.is_action_pressed("fire"):
        is_firing = true
        if gun and gun.has_method("shoot2"):
            gun.shoot2()
    elif event.is_action_released("fire"):
        is_firing = false

func lerp(a: float, b: float, t: float) -> float:
    return a * (1 - t) + (b * t)

func update_recoil_bar():
    if recoil_bar:
        # Calculate recoil intensity as a percentage
        var recoil_intensity = recoil_velocity.length() / MAX_RECOIL_INTENSITY
        recoil_intensity = clamp(recoil_intensity, 0.0, 1.0)
        
        # Update bar width (assuming the original width is 1.0)
        recoil_bar.scale.x = recoil_intensity
        
        # Update bar color (blue to red)
        recoil_bar.modulate = Color(recoil_intensity, 0, 1 - recoil_intensity)

func update_debug_node_position():
    if debug_touch:
        debug_touch.global_position = global_position