@tool
extends EditorPlugin

var editor_interface
var enemy_editor

func _enter_tree():
    editor_interface = get_editor_interface()
    enemy_editor = preload("res://addons/pillz_table_editor/main_panel.tscn").instantiate()
    enemy_editor.editor_interface = editor_interface
    editor_interface.get_editor_main_screen().add_child(enemy_editor)
    _make_visible(false)

func _exit_tree():
    if enemy_editor:
        enemy_editor.queue_free()

func _has_main_screen():
    return true

func _make_visible(visible):
    if enemy_editor:
        enemy_editor.visible = visible

func _get_plugin_name():
    return "Enemy Editor"

func _get_plugin_icon():
    return editor_interface.get_base_control().get_theme_icon("Node", "EditorIcons")
