# This script is for movement (attached to the Player (CharacterBody3D))
extends CharacterBody3D

@export var SPEED: float = 6.0
@export var ROTATION_SPEED: float = 10.0
@export_range(0.1, 1.0) var SHOOTING_THRESHOLD: float = 0.8
@export var camera: Camera3D = null
@onready var gun = get_node("Gun")
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

var thumbstick: Node = null
var input_vector: Vector2 = Vector2.ZERO
var is_shooting: bool = false
var has_left_deadzone: bool = false

func _ready():
    thumbstick = get_node("../../MainHUD/ControllerCanvas/MovementJoystick")
    if not thumbstick:
        push_error("Thumbstick not found. Make sure it's properly added to the scene.")
    else:
        thumbstick.connect("on_trigger", Callable(self, "_on_thumbstick_trigger"))
        thumbstick.connect("on_pressed", Callable(self, "_on_thumbstick_pressed"))
        thumbstick.connect("on_released", Callable(self, "_on_thumbstick_released"))
    
    if gun:
        # Check if the signals are already connected before connecting them
        if not gun.is_connected("gun_fired", Callable(self, "_on_gun_fired")):
            gun.connect("gun_fired", Callable(self, "_on_gun_fired"))
        if not gun.is_connected("recoil_reset", Callable(self, "_on_gun_recoil_reset")):
            gun.connect("recoil_reset", Callable(self, "_on_gun_recoil_reset"))

func _physics_process(delta):
    if not is_on_floor():
        velocity.y -= gravity * delta

    handle_movement(delta)
    handle_rotation(delta)
    
    move_and_slide()

func handle_movement(delta):
    var cam_basis = camera.global_transform.basis
    # Use the original (non-inverted) basis
    var direction = (cam_basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()
    
    # Scale down the movement
    velocity.x = -direction.x * SPEED * input_vector.length()
    velocity.z = -direction.z * SPEED * input_vector.length()

func handle_rotation(delta):
    if input_vector.length() > 0:
        var cam_basis = camera.global_transform.basis
        # Use the original (non-inverted) basis for rotation calculation
        var aim_direction = (cam_basis * Vector3(input_vector.x, 0, input_vector.y)).normalized()

        var target_rotation = atan2(aim_direction.x, aim_direction.z)
        var new_rotation = lerp_angle(rotation.y, target_rotation, ROTATION_SPEED * delta)
        
        rotation.y = new_rotation

func start_shooting():
    if not is_shooting and gun:
        is_shooting = true
        var direction = get_shoot_direction()  # This function must be defined in this script or in an inherited script
        gun.trigger_pressed(direction)

func stop_shooting():
    if is_shooting and gun:
        is_shooting = false
        gun.trigger_released()

func _on_thumbstick_trigger(stick_vector: Vector2, _elapsed: float):
    input_vector = stick_vector
    if input_vector.length() > thumbstick.deadzone_radius_percentage:
        has_left_deadzone = true
        if input_vector.length() > SHOOTING_THRESHOLD:
            start_shooting()
        else:
            stop_shooting()
    elif has_left_deadzone and input_vector.length() <= thumbstick.deadzone_radius_percentage:
        has_left_deadzone = false
        stop_shooting()

func _on_thumbstick_pressed(event):
    has_left_deadzone = false

func _on_thumbstick_released(_position: Vector2, _elapsed: float) -> void:
    input_vector = Vector2.ZERO
    stop_shooting()
    has_left_deadzone = false

func _input(event):
    if event.is_action_pressed("fire"):
        if gun and gun.has_method("shoot2"):
            gun.shoot2()

func _on_gun_fired(recoil_force_forward: Vector3) -> void:
    # Scale down the recoil force
    velocity += -recoil_force_forward * gun.get_recoil_value()
    
    # You might want to clamp the velocity to prevent excessive movement
    velocity = velocity.clamp(Vector3(-SPEED, -SPEED, -SPEED), Vector3(SPEED, SPEED, SPEED))

func get_shoot_direction() -> Vector2:
    # Example: Get the direction from a thumbstick or mouse position
    input_vector = Vector2.ZERO  # Default to zero vector if no input

    # Assuming you have a thumbstick node or similar input method
    if has_node("Thumbstick"):
        input_vector = thumbstick.get_value()  # Replace 'get_value' with your method to get the thumbstick's vector

    # Normalize the vector to ensure consistent behavior
    if input_vector.length() > 0:
        input_vector = input_vector.normalized()

    return input_vector

func handle_recoil(delta: float):
    if gun:  # Assuming you have a reference to the gun
        gun.handle_recoil(delta)

func start_recoil_recovery():
    if gun:
        gun.start_recoil_recovery()
