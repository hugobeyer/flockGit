@tool
extends Node3D
class_name ShaderController

@export var material: ShaderMaterial:
    set(value):
        material = value
        if material:
            material.resource_local_to_scene = true
        update_configuration_warnings()
        _update_material()

@export var target_node: NodePath
var _target_node: Node3D

func _ready():
    if not material:
        material = ShaderMaterial.new()
        material.resource_local_to_scene = true
    _update_target_node()
    _update_material()

func _update_target_node():
    _target_node = get_node_or_null(target_node)
    _update_material()

func _update_material():
    if _target_node and _target_node is VisualInstance3D:
        _target_node.material_override = material
    elif material:
        # If no target node, apply to self if possible
        var mesh_instance = _find_mesh_instance(self)
        if mesh_instance:
            mesh_instance.material_override = material

func _find_mesh_instance(node: Node) -> MeshInstance3D:
    if node is MeshInstance3D:
        return node
    for child in node.get_children():
        var result = _find_mesh_instance(child)
        if result:
            return result
    return null

func update_shader_param(param_name: String, value: Variant):
    if material:
        material.set_shader_parameter(param_name, value)

func _get_configuration_warnings():
    var warnings = []
    if not material:
        warnings.append("No material assigned.")
    if not _target_node and not _find_mesh_instance(self):
        warnings.append("No target node assigned and no MeshInstance3D found as child.")
    return warnings

func _notification(what):
    if what == NOTIFICATION_PATH_RENAMED:
        _update_target_node()

# Keep any other existing methods here
