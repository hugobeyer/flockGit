@tool
extends Resource
class_name ShaderInteraction

enum InteractionType { PROXIMITY, ANIMATION, TIMER }
enum TargetType { NODE_PATH, GROUP, UNIQUE_NAME }

var shader_manager: ShaderManager

# Keep all your existing exported properties here
@export var parameter_name: String
@export var interaction_type: InteractionType
@export var target_type: TargetType
@export var target_node_path: NodePath
@export var target_group: String
@export var target_unique_name: String
@export var min_value: float = 0.0
@export var max_value: float = 1.0
@export var min_distance: float = 1.0
@export var max_distance: float = 10.0

# Animation settings
@export var animation_player_path: NodePath
@export var animation_parameter: String = "blend_position"

# Timer settings
@export var period: float = 1.0
@export var curve: Curve

var current_value: float = 0.0
var timer: float = 0.0

# Keep any other existing properties here

func process(delta: float, shader_manager: ShaderManager) -> float:
    match interaction_type:
        InteractionType.PROXIMITY:
            return process_proximity(shader_manager)
        InteractionType.ANIMATION:
            return process_animation(shader_manager)
        InteractionType.TIMER:
            return process_timer(delta)
    return current_value

func process_proximity(shader_manager: ShaderManager) -> float:
    var target = get_target(shader_manager)
    var controller_node = shader_manager.get_target_node()
    if not target or not controller_node or not controller_node is Node3D or not target is Node3D:
        return min_value
    var distance = controller_node.global_transform.origin.distance_to(target.global_transform.origin)
    var t = inverse_lerp(max_distance, min_distance, distance)
    current_value = lerp(min_value, max_value, clamp(t, 0.0, 1.0))
    return current_value

func process_animation(shader_manager: ShaderManager) -> float:
    var anim_player = shader_manager.get_node_or_null(animation_player_path)
    if not anim_player:
        return min_value
    var blend = anim_player.get(animation_parameter)
    current_value = lerp(min_value, max_value, clamp(blend, 0.0, 1.0))
    return current_value

func process_timer(delta: float) -> float:
    timer += delta
    var t = fmod(timer, period) / period
    if curve:
        t = curve.sample(t)
    current_value = lerp(min_value, max_value, t)
    return current_value

func get_target(shader_manager: ShaderManager) -> Node:
    match target_type:
        TargetType.NODE_PATH:
            return shader_manager.get_node_or_null(target_node_path)
        TargetType.GROUP:
            if shader_manager.get_tree():
                var nodes = shader_manager.get_tree().get_nodes_in_group(target_group)
                return nodes[0] if nodes.size() > 0 else null
        TargetType.UNIQUE_NAME:
            if shader_manager.get_tree():
                return shader_manager.get_tree().get_root().get_node_or_null(NodePath("/root/" + target_unique_name))
    return null

# Keep your existing process_animation and process_timer methods here