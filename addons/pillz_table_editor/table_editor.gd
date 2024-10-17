@tool
extends EditorPlugin

var editor_interface
var table_editor

func _enter_tree():
    editor_interface = get_editor_interface()
    table_editor = preload("res://addons/pillz_table_editor/scenes/main_panel.tscn").instantiate()
    table_editor.editor_interface = editor_interface
    # Change this line to use add_control_to_dock instead
    add_control_to_dock(DOCK_SLOT_RIGHT_UL, table_editor)

func _exit_tree():
    # And change this line accordingly
    remove_control_from_docks(table_editor)
    table_editor.free()

func _has_main_screen():
    return true

func _make_visible(visible):
    if table_editor:
        table_editor.visible = visible

func _get_plugin_name():
    return "Table Editor"

func _get_plugin_icon():
    # Use a built-in icon as a fallback
    return get_editor_interface().get_base_control().get_theme_icon("Node", "EditorIcons")
