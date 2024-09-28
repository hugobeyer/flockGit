@tool
extends Node
class_name ShaderManager

@export var shader_controller: ShaderController:
    set(value):
        shader_controller = value
        update_shader_params()

@export var interactions: Array[ShaderInteraction] = []:
    set(value):
        interactions = value
        for interaction in interactions:
            if interaction:
                interaction.shader_manager = self

var shader_params: Array[String] = []

# Keep any other existing properties here

func _ready():
    update_shader_params()
    for interaction in interactions:
        if interaction:
            interaction.shader_manager = self
    # Keep any existing _ready logic here

func _process(delta):
    if not shader_controller or not shader_controller.material:
        return
    
    for interaction in interactions:
        if interaction:
            var value = interaction.process(delta, self)
            shader_controller.update_shader_param(interaction.parameter_name, value)

func update_shader_params():
    shader_params.clear()
    if shader_controller and shader_controller.material and shader_controller.material.shader:
        var shader = shader_controller.material.shader
        for param in shader.get_shader_uniform_list():
            shader_params.append(param.name)

func get_target_node() -> Node3D:
    if shader_controller:
        return shader_controller._target_node if shader_controller._target_node else shader_controller
    return null

# Keep any other existing methods here