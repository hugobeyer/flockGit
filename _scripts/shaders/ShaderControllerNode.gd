@tool
extends Node

@export var interaction_resource: InteractionResource
@export var shader_controller: ShaderController:
    set(value):
        shader_controller = value
        if shader_controller and not shader_controller.material:
            shader_controller.material = ShaderMaterial.new()

func _ready():
    if not shader_controller:
        shader_controller = ShaderController.new()
        shader_controller.material = ShaderMaterial.new()
        ResourceSaver.save(shader_controller.material, "res://_scripts/shaders/shader_controller.tres")

func _process(delta):
    if interaction_resource:
        for interaction in interaction_resource.interactions:
            process_interaction(interaction, delta)

func process_interaction(interaction: InteractionData, delta: float):
    var target_node = get_node_or_null(interaction.target_node_path)
    if not target_node:
        return

    var interaction_value = 0.0
    match interaction.interaction_type:
        "Distance":
            interaction_value = process_distance_interaction(target_node)
        "Collision":
            interaction_value = process_collision_interaction(target_node)
        "Movement":
            interaction_value = process_movement_interaction(target_node, delta)
        "All":
            interaction_value = process_all_interactions(target_node, delta)

    apply_effect(interaction.shader_parameter, interaction.effect_type, interaction_value, interaction.effect_parameters)

func process_distance_interaction(target_node: Node) -> float:
    # Implement distance-based interaction logic
    return 0.0

func process_collision_interaction(target_node: Node) -> float:
    # Implement collision-based interaction logic
    return 0.0

func process_movement_interaction(target_node: Node, delta: float) -> float:
    # Implement movement-based interaction logic
    return 0.0

func process_all_interactions(target_node: Node, delta: float) -> float:
    # Implement combined interaction logic
    return 0.0

func apply_effect(shader_param: String, effect_type: String, value: float, effect_params: Dictionary):
    match effect_type:
        "Lerp":
            shader_controller.update_shader_param(shader_param, lerp(0, 1, value))
        "Delay":
            # Implement delay effect
            pass
        "Blink":
            # Implement blink effect
            pass
        "Displace":
            # Implement displace effect
            pass
        "Shake":
            # Implement shake effect
            pass

# Proxy methods to access ShaderController functionality
func set_shader(shader: Shader):
    shader_controller.set_shader(shader)

func get_shader() -> Shader:
    return shader_controller.get_shader()

func update_shader_param(param_name: String, value):
    shader_controller.update_shader_param(param_name, value)

func get_shader_param(param_name: String):
    return shader_controller.get_shader_param(param_name)

func apply_material_to_node(node: Node):
    shader_controller.apply_material_to_node(node)

func get_material() -> ShaderMaterial:
    return shader_controller.material

# Add any other necessary methods
