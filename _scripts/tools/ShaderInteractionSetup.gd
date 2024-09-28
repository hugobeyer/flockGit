@tool
extends EditorScript

const PLUGIN_PATH = "res://addons/shader_manager/"

func _run():
    create_base_files()
    create_interaction_types()
    create_shader_manager()
    create_plugin_script()
    print("Shader Interaction System setup complete!")

func create_base_files():
    create_file("ShaderInteraction.gd", """
@tool
extends Resource
class_name ShaderInteraction

@export var parameter_name: String
@export var parameter_type: int
@export var current_value: Variant

func process(_delta: float, _shader_manager: Node) -> Variant:
    return current_value
""")

func create_interaction_types():
    create_distance_interaction()
    create_collision_interaction()
    create_movement_interaction()
    create_time_interaction()

func create_distance_interaction():
    create_file("DistanceInteraction.gd", """
@tool
extends ShaderInteraction
class_name DistanceInteraction

@export var target_node_path: NodePath
@export var min_distance: float = 1.0
@export var max_distance: float = 10.0
@export var min_value: float = 0.0
@export var max_value: float = 1.0

func process(_delta: float, shader_manager: Node) -> float:
    var target = shader_manager.get_node(target_node_path)
    if not target:
        return min_value
    var distance = shader_manager.global_transform.origin.distance_to(target.global_transform.origin)
    var t = inverse_lerp(min_distance, max_distance, distance)
    current_value = lerp(min_value, max_value, clamp(t, 0.0, 1.0))
    return current_value
""")

func create_collision_interaction():
    create_file("CollisionInteraction.gd", """
@tool
extends ShaderInteraction
class_name CollisionInteraction

@export var collision_mask: int = 1
@export var ray_length: float = 10.0
@export var value_on_collision: float = 1.0
@export var value_no_collision: float = 0.0

func process(_delta: float, shader_manager: Node) -> float:
    var space_state = shader_manager.get_world_3d().direct_space_state
    var query = PhysicsRayQueryParameters3D.create(shader_manager.global_transform.origin, 
                shader_manager.global_transform.origin + shader_manager.global_transform.basis.z * ray_length)
    query.collision_mask = collision_mask
    var result = space_state.intersect_ray(query)
    current_value = value_on_collision if result else value_no_collision
    return current_value
""")

func create_movement_interaction():
    create_file("MovementInteraction.gd", """
@tool
extends ShaderInteraction
class_name MovementInteraction

@export var max_speed: float = 10.0
@export var min_value: float = 0.0
@export var max_value: float = 1.0

var last_position: Vector3

func process(delta: float, shader_manager: Node) -> float:
    var current_position = shader_manager.global_transform.origin
    if last_position == Vector3.ZERO:
        last_position = current_position
        current_value = min_value
        return current_value
    var velocity = (current_position - last_position) / delta
    last_position = current_position
    var speed = velocity.length()
    current_value = lerp(min_value, max_value, clamp(speed / max_speed, 0.0, 1.0))
    return current_value
""")

func create_time_interaction():
    create_file("TimeInteraction.gd", """
@tool
extends ShaderInteraction
class_name TimeInteraction

@export var period: float = 1.0
@export var min_value: float = 0.0
@export var max_value: float = 1.0

func process(delta: float, _shader_manager: Node) -> float:
    var t = fmod(Time.get_ticks_msec() / 1000.0, period) / period
    current_value = lerp(min_value, max_value, t)
    return current_value
""")

func create_shader_manager():
    create_file("ShaderManager.gd", """
@tool
extends Node

@export var shader_controller: ShaderController
@export var interactions: Array[ShaderInteraction] = []

func _process(delta):
    if not shader_controller or not shader_controller.material:
        return
    
    for interaction in interactions:
        var value = interaction.process(delta, self)
        if value != null:
            shader_controller.update_shader_param(interaction.parameter_name, value)

func add_interaction(interaction: ShaderInteraction):
    interactions.append(interaction)
    notify_property_list_changed()

func remove_interaction(interaction: ShaderInteraction):
    interactions.erase(interaction)
    notify_property_list_changed()
""")

func create_plugin_script():
    create_file("plugin.gd", """
@tool
extends EditorPlugin

func _enter_tree():
    add_custom_type("ShaderManager", "Node", preload("ShaderManager.gd"), preload("res://icon.png"))
    add_custom_type("DistanceInteraction", "Resource", preload("DistanceInteraction.gd"), preload("res://icon.png"))
    add_custom_type("CollisionInteraction", "Resource", preload("CollisionInteraction.gd"), preload("res://icon.png"))
    add_custom_type("MovementInteraction", "Resource", preload("MovementInteraction.gd"), preload("res://icon.png"))
    add_custom_type("TimeInteraction", "Resource", preload("TimeInteraction.gd"), preload("res://icon.png"))

func _exit_tree():
    remove_custom_type("ShaderManager")
    remove_custom_type("DistanceInteraction")
    remove_custom_type("CollisionInteraction")
    remove_custom_type("MovementInteraction")
    remove_custom_type("TimeInteraction")
""")

func create_file(file_name: String, content: String):
    var file = FileAccess.open(PLUGIN_PATH + file_name, FileAccess.WRITE)
    file.store_string(content)
    file.close()
