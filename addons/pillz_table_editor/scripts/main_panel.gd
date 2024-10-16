@tool
extends Control

var editor_interface: EditorInterface

@onready var enemy_list = $VBoxContainer/EnemyList
@onready var property_list = $VBoxContainer/PropertyList
@onready var new_property_name = $VBoxContainer/NewPropertyName
@onready var new_property_value = $VBoxContainer/NewPropertyValue
@onready var add_property_button = $VBoxContainer/AddPropertyButton

func _ready():
    add_property_button.connect("pressed", Callable(self, "_on_add_property_pressed"))
    enemy_list.connect("item_selected", Callable(self, "_on_enemy_selected"))
    refresh_enemy_list()

func refresh_enemy_list():
    enemy_list.clear()
    var dir = DirAccess.open("res://_resources/enemies")
    if dir:
        dir.list_dir_begin()
        var file_name = dir.get_next()
        while file_name != "":
            if file_name.ends_with(".tres"):
                enemy_list.add_item(file_name.get_basename())
            file_name = dir.get_next()

func _on_enemy_selected(index):
    var enemy_type_name = enemy_list.get_item_text(index)
    var enemy_type = load("res://_resources/enemies/" + enemy_type_name + ".tres")
    if enemy_type is EnemyType:
        refresh_property_list(enemy_type)

func refresh_property_list(enemy_type: EnemyType):
    property_list.clear()
    for property in enemy_type.get_property_list():
        if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
            property_list.add_item("%s: %s" % [property.name, str(enemy_type.get(property.name))])

func _on_add_property_pressed():
    var selected_enemy = enemy_list.get_selected_items()
    if selected_enemy.is_empty():
        print("No enemy type selected")
        return
    
    var enemy_type_name = enemy_list.get_item_text(selected_enemy[0])
    var enemy_type = load("res://_resources/enemies/" + enemy_type_name + ".tres")
    
    if enemy_type is EnemyType:
        var new_properties = {
            new_property_name.text: new_property_value.text
        }
        enemy_type.extend_data(new_properties)
        refresh_property_list(enemy_type)
        print("Added new property to ", enemy_type_name)
    else:
        print("Selected resource is not an EnemyType")

    # Save the modified resource
    var err = ResourceSaver.save(enemy_type, "res://_resources/enemies/" + enemy_type_name + ".tres")
    if err != OK:
        print("Failed to save the modified enemy type")

    # Refresh the editor to show new properties
    editor_interface.get_resource_filesystem().scan()
    editor_interface.get_inspector().refresh()