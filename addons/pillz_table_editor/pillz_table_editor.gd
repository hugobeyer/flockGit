@tool
extends EditorPlugin

const SETTINGS_SECTION = "Pillz Table Editor"
const PLUGIN_ICON_PATH = "res://addons/pillz_table_editor/icons/default.png"
var main_panel
var editor_button


func _enter_tree():
    main_panel = preload("res://addons/pillz_table_editor/scenes/main_panel.tscn").instantiate()
    main_panel.hide()
    get_editor_interface().get_editor_main_screen().add_child(main_panel)
    
    editor_button = Button.new()
    editor_button.text = "Pillz Table Editor"
    var icon = load(PLUGIN_ICON_PATH)
    if icon:
        editor_button.icon = icon
    editor_button.connect("pressed", _on_editor_button_pressed)
    add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, editor_button)
    
    add_plugin_settings()
    add_tool_menu_item("Reload Pillz Table Editor", self._on_reload_plugin)

func _exit_tree():
    if main_panel:
        get_editor_interface().get_editor_main_screen().remove_child(main_panel)
        main_panel.queue_free()
    if editor_button:
        remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, editor_button)
        editor_button.free()
    remove_plugin_settings()
    remove_tool_menu_item("Reload Pillz Table Editor")

func _on_editor_button_pressed():
    # Toggle visibility
    _make_visible(!main_panel.visible)

func _make_visible(visible):
    if main_panel:
        main_panel.visible = visible

func _has_main_screen():
    return true

func _get_plugin_name():
    return "Pillz Table Editor"

func _get_plugin_icon():
    return load(PLUGIN_ICON_PATH)

func _refresh():
    get_editor_interface().get_resource_filesystem().scan()

func add_plugin_settings():
    # Default icons
    add_setting("default_enemy_icon", TYPE_STRING, PLUGIN_ICON_PATH)
    add_setting("default_add_icon", TYPE_STRING, "res://_textures/icons/IconsWenrexa/24.png")
    
    # Default folder
    add_setting("default_enemy_folder", TYPE_STRING, "res://_resources/enemies")
    
    # Additional creative settings
    add_setting("auto_refresh_interval", TYPE_FLOAT, 5.0)  # Auto-refresh interval in seconds
    add_setting("max_recent_folders", TYPE_INT, 5)  # Number of recent folders to remember
    add_setting("default_column_width", TYPE_INT, 100)  # Default width for columns
    add_setting("enable_drag_and_drop", TYPE_BOOL, true)  # Enable drag and drop for reordering
    add_setting("show_property_hints", TYPE_BOOL, true)  # Show property hints in tooltips
    add_setting("enable_quick_edit", TYPE_BOOL, false)  # Enable quick editing of values in the table
    add_setting("custom_enemy_color", TYPE_COLOR, Color.WHITE)  # Custom color for enemy rows

func remove_plugin_settings():
    var settings = [
        "default_enemy_icon", "default_add_icon", "default_enemy_folder",
        "auto_refresh_interval", "max_recent_folders", "default_column_width",
        "enable_drag_and_drop", "show_property_hints", "enable_quick_edit",
        "custom_enemy_color"
    ]
    for setting in settings:
        ProjectSettings.set_setting(SETTINGS_SECTION + "/" + setting, null)

func add_setting(name: String, type: int, default_value):
    var setting_name = SETTINGS_SECTION + "/" + name
    if !ProjectSettings.has_setting(setting_name):
        ProjectSettings.set_setting(setting_name, default_value)
        ProjectSettings.set_initial_value(setting_name, default_value)
    ProjectSettings.add_property_info({
        "name": setting_name,
        "type": type,
        "hint": PROPERTY_HINT_NONE,
        "hint_string": ""
    })

func _on_reload_plugin():
    print("Reloading Pillz Table Editor plugin...")
    
    # Remove existing panel
    if main_panel:
        get_editor_interface().get_editor_main_screen().remove_child(main_panel)
        main_panel.queue_free()
    
    # Re-instantiate the panel
    main_panel = preload("res://addons/pillz_table_editor/scenes/main_panel.tscn").instantiate()
    main_panel.hide()
    get_editor_interface().get_editor_main_screen().add_child(main_panel)
    
    # Refresh the editor
    get_editor_interface().get_resource_filesystem().scan()
    
    print("Pillz Table Editor plugin reloaded successfully.")
