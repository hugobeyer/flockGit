@tool
extends Resource
class_name BaseBehavior

enum TargetType { NODE_PATH, GROUP, UNIQUE_NAME }

@export var target_type: TargetType
@export var target_path: NodePath
@export var target_group: String
@export var target_unique_name: String

@export var duration: float = 1.0
@export var curve: Curve
@export var next_behavior: BaseBehavior

func execute(behavior_manager: Node):
    pass

func get_target(behavior_manager: Node) -> Node:
    var owner = behavior_manager.get_parent()
    match target_type:
        TargetType.NODE_PATH:
            return owner.get_node_or_null(target_path)
        TargetType.GROUP:
            var nodes = owner.get_tree().get_nodes_in_group(target_group)
            return nodes[0] if nodes.size() > 0 else null
        TargetType.UNIQUE_NAME:
            return owner.get_tree().root.get_node(NodePath("/root/" + target_unique_name))
    return null