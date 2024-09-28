@tool
extends Resource  # Change this to Resource if BaseBehavior is a Resource
class_name BehaviorOnEnterLerp

# Temporary do-nothing function
func execute(_target: Node):
    pass  # Do nothing

# Original code commented out:
"""
enum CollisionRole { COLLIDER, COLLIDEE }
enum DepleteAction { NONE, DIE, DISAPPEAR, CHANGE_SCENE }

# Collision and Health
@export_group("Collision and Health")
@export var collision_role: CollisionRole
@export var health_node: NodePath
@export var damage_attribute: String = "damage"
@export var initial_health: float = 100.0

# Shader Effect
@export_group("Shader Effect")
@export var shader_node: NodePath
@export var shader_parameter: String
@export var min_value: float = 0.0
@export var max_value: float = 1.0

# Actions
@export_group("Actions")
@export var kill_node: NodePath
@export var target_node: NodePath
@export var call_method_on_owner: String
@export var call_method_on_target: String
@export var set_property_on_owner: String
@export var set_property_on_target: String

# Depletion
@export_group("Depletion")
@export var deplete_action: DepleteAction
@export var scene_to_change: String

var elapsed_time: float = 0.0
var current_health: float

func apply_shader_parameter(target: Node, value: float):
    if target.get("material") is ShaderMaterial:
        target.material.set_shader_parameter(shader_parameter, value)
    elif target.get("material"):
        target.material.set_shader_parameter(shader_parameter, value)
    elif target is MeshInstance3D and target.get_surface_override_material(0):
        target.get_surface_override_material(0).set_shader_parameter(shader_parameter, value)
    elif target.get("mesh") and target.mesh.surface_get_material(0):
        target.mesh.surface_get_material(0).set_shader_parameter(shader_parameter, value)

func handle_depletion(node: Node):
    match deplete_action:
        DepleteAction.DIE:
            if node.has_method("die"):
                node.die()
            else:
                node.queue_free()
        DepleteAction.DISAPPEAR:
            if node is CanvasItem:
                node.hide()
            elif node is Node3D:
                node.visible = false
        DepleteAction.CHANGE_SCENE:
            if scene_to_change:
                node.get_tree().change_scene_to_file(scene_to_change)
        DepleteAction.NONE:
            pass
"""