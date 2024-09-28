extends Node

enum State { IDLE, EFFECT1, EFFECT2, EFFECT3 }

@export var shader_controller: Node  # Reference to your ShaderControllerNode

var current_state = State.IDLE
var state_timer = 0.0

func _process(delta):
    match current_state:
        State.IDLE:
            if Input.is_action_just_pressed("start_effect"):
                change_state(State.EFFECT1)
        State.EFFECT1:
            run_effect1(delta)
        State.EFFECT2:
            run_effect2(delta)
        State.EFFECT3:
            run_effect3(delta)

func change_state(new_state):
    current_state = new_state
    state_timer = 0.0
    match new_state:
        State.EFFECT1:
            shader_controller.update_shader_param("effect1_intensity", 0.0)
        State.EFFECT2:
            shader_controller.update_shader_param("effect2_scale", 1.0)
        State.EFFECT3:
            shader_controller.update_shader_param("effect3_color", Color.BLACK)

func run_effect1(delta):
    state_timer += delta
    var intensity = min(state_timer / 2.0, 1.0)
    shader_controller.update_shader_param("effect1_intensity", intensity)
    if state_timer >= 3.0:
        change_state(State.EFFECT2)

func run_effect2(delta):
    state_timer += delta
    var scale = 1.0 + sin(state_timer * 2.0) * 0.5
    shader_controller.update_shader_param("effect2_scale", scale)
    if state_timer >= 5.0:
        change_state(State.EFFECT3)

func run_effect3(delta):
    state_timer += delta
    var color = Color.BLACK.lerp(Color.WHITE, state_timer / 2.0)
    shader_controller.update_shader_param("effect3_color", color)
    if state_timer >= 2.0:
        change_state(State.IDLE)
