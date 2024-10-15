# This script is for movement (attached to the Player (CharacterBody3D))
extends CharacterBody3D

@export var SPEED: float = 6.0
@export var camera: Camera3D = null
@export var debug_touch = Node3D
@onready var gun =  get_node("/root/GameRoot/Main/Player/Gun")  # Adjust the path if necessary
@onready var playerSelf: CharacterBody3D
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")



var cur_shots: int = 0
var last_shot: float = 0
var is_firing: bool = false
var fire_start_time: float = 0.0

func _ready():
    playerSelf = self
    global_position = playerSelf.global_position

func _physics_process(delta):
    if not is_on_floor():
        velocity.y -= gravity * delta

    handle_movement(delta)
    handle_touch_input()
    # update_debug_node_position()  # Add this line
    
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

func _input(event):
    if event.is_action_pressed("fire"):
        is_firing = true
        if gun and gun.has_method("shoot2"):
            gun.shoot2()
    elif event.is_action_released("fire"):
        is_firing = false

func lerp(a: float, b: float, t: float) -> float:
    return a * (1 - t) + (b * t)

func update_debug_node_position():
    if debug_touch:
        debug_touch.global_position = global_position