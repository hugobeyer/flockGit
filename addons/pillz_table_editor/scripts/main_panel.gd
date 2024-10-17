@tool
extends Control

const SETTINGS_SECTION = "Pillz Table Editor"
const DEFAULT_ICON_PATH = "res://addons/pillz_table_editor/icons/default.png"
const ADD_ICON_PATH = "res://addons/pillz_table_editor/icons/add.png"  # Make sure this path is correct

@onready var enemy_table = $VBoxContainer/EnemyTable
@onready var load_folder_button = $VBoxContainer/HBoxContainer/LoadFolderButton
@onready var clear_table_button = $VBoxContainer/HBoxContainer/ClearTableButton
@onready var column_visibility_button = $VBoxContainer/HBoxContainer/ColumnVisibilityButton
@onready var column_visibility_popup = $ColumnVisibilityPopup

var root: TreeItem
var add_item: TreeItem
var enemies = []
var current_folder: String = ""
var columns = ["Icon", "Name", "Health", "Damage", "Speed"]
var hidden_columns = []

func _ready():
    setup_table()
    load_folder_button.connect("pressed", _on_load_folder_pressed)
    clear_table_button.connect("pressed", _on_clear_table_pressed)
    column_visibility_button.connect("pressed", _on_column_visibility_pressed)
    enemy_table.connect("item_activated", _on_enemy_table_item_activated)

func setup_table():
    clear_table()
    if Engine.is_editor_hint():
        add_sample_data()
    else:
        refresh_enemy_table()
    add_empty_row()

func clear_table():
    enemy_table.clear()
    root = enemy_table.create_item()
    enemy_table.hide_root = true
    
    enemy_table.set_column_titles_visible(true)
    enemy_table.set_columns(columns.size())
    for i in range(columns.size()):
        enemy_table.set_column_title(i, columns[i])
        enemy_table.set_column_expand(i, true)  # Allow all columns to expand
    
    # Set a fixed width for the icon column
    enemy_table.set_column_expand(0, false)
    enemy_table.set_column_custom_minimum_width(0, 40)  # Adjust this value as needed

func add_sample_data():
    var default_icon = load(DEFAULT_ICON_PATH)
    var sample_data = [
        {"name": "Sample Enemy 1", "health": 100, "damage": 10, "speed": 5.0},
        {"name": "Sample Enemy 2", "health": 150, "damage": 15, "speed": 4.5},
        {"name": "Sample Enemy 3", "health": 200, "damage": 20, "speed": 3.5}
    ]
    for data in sample_data:
        var item = enemy_table.create_item(root)
        item.set_icon(0, default_icon)
        item.set_icon_max_width(0, 30)  # Limit icon size
        item.set_text(1, data.get("name", "Unknown"))
        item.set_text(2, str(data.get("health", 0)))
        item.set_text(3, str(data.get("damage", 0)))
        item.set_text(4, str(data.get("speed", 0.0)))

func add_enemy_to_table(enemy):
    var item = enemy_table.create_item(root)
    var default_icon = load(DEFAULT_ICON_PATH)
    
    # Handle icon
    if enemy.has("icon") and enemy.icon != null:
        item.set_icon(0, enemy.icon)
    else:
        item.set_icon(0, default_icon)
    item.set_icon_max_width(0, 30)  # Limit icon size
    
    # Handle name
    var enemy_name = "Unknown"
    if enemy.has("name") and enemy.name != null:
        enemy_name = enemy.name
    elif enemy.resource_path:
        enemy_name = enemy.resource_path.get_file().get_basename()
    item.set_text(1, enemy_name)
    
    # Handle other properties
    item.set_text(2, str(enemy.get("health", 0)))
    item.set_text(3, str(enemy.get("damage", 0)))
    item.set_text(4, str(enemy.get("speed", 0.0)))

func add_empty_row():
    add_item = enemy_table.create_item(root)
    var add_icon = load(ADD_ICON_PATH)
    if add_icon:
        add_item.set_icon(0, add_icon)
        add_item.set_icon_max_width(0, 30)  # Limit icon size
    for i in range(1, columns.size()):
        add_item.set_text(i, "")
    add_item.set_text(1, "Add new enemy")
    add_item.set_custom_color(1, Color.DARK_GRAY)

func refresh_enemy_table():
    clear_table()
    if current_folder.is_empty():
        print("No folder selected")
        return
    
    var dir = DirAccess.open(current_folder)
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if not dir.current_is_dir() and file_name.ends_with(".tres"):
                var enemy = load(current_folder.path_join(file_name))
                if enemy:
                    add_enemy_to_table(enemy)
            file_name = dir.get_next()
    else:
        print("An error occurred when trying to access the path.")
    
    add_empty_row()

func adjust_column_widths():
    var padding = 8  # 4px on each side
    for i in range(enemy_table.get_columns()):  # Changed from get_column_count() to get_columns()
        var max_width = 0
        var column_title = enemy_table.get_column_title(i)
        max_width = max(max_width, column_title.length() * 10)  # Approximate width

        var child = root.get_first_child()
        while child:
            var cell_text = child.get_text(i)
            max_width = max(max_width, cell_text.length() * 10)  # Approximate width
            child = child.get_next()

        max_width += padding
        enemy_table.set_column_custom_minimum_width(i, max_width)

func _on_load_folder_pressed():
    var dialog = FileDialog.new()
    dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
    dialog.access = FileDialog.ACCESS_RESOURCES
    dialog.connect("dir_selected", _on_folder_selected)
    add_child(dialog)
    dialog.popup_centered(Vector2(800, 600))

func _on_folder_selected(path):
    current_folder = path
    refresh_enemy_table()

func _on_clear_table_pressed():
    clear_table()

func _on_column_visibility_pressed():
    column_visibility_popup.popup(Rect2(get_global_mouse_position(), Vector2(200, 0)))

func _on_enemy_table_item_activated():
    var selected_item = enemy_table.get_selected()
    if selected_item == add_item:
        # Handle adding a new enemy
        print("Adding a new enemy")
        # Implement your logic for adding a new enemy here

