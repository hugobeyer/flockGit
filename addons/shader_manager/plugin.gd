@tool
extends EditorPlugin

var inspector_plugin

func _enter_tree():
    add_custom_type("ShaderManager", "Node", preload("ShaderManager.gd"), preload("res://icon.png"))
    add_custom_type("ShaderInteraction", "Resource", preload("ShaderInteraction.gd"), preload("res://icon.png"))
    
    inspector_plugin = preload("ShaderInteractionInspectorPlugin.gd").new()
    add_inspector_plugin(inspector_plugin)

func _exit_tree():
    remove_custom_type("ShaderManager")
    remove_custom_type("ShaderInteraction")
    remove_inspector_plugin(inspector_plugin)

func _get_plugin_name():
    return "ShaderManager"

func _handles(object):
    return object is ShaderManager

func _make_visible(visible):
    if visible:
        var selected_nodes = get_editor_interface().get_selection().get_selected_nodes()
        if selected_nodes.size() > 0 and selected_nodes[0] is ShaderManager:
            inspector_plugin.shader_manager = selected_nodes[0]
