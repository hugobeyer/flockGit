@tool
extends Control

var editor_interface: EditorInterface

@onready var enemy_list = $VBoxContainer/EnemyList
@onready var property_list = $VBoxContainer/PropertyList
@onready var new_property_name = $VBoxContainer/NewPropertyName
@onready var new_property_value = $VBoxContainer/NewPropertyValue
@onready var add_property_button = $VBoxContainer/AddPropertyButton

var current_enemy: Resource

func _ready():
    if add_property_button:
        add_property_button.connect("pressed", Callable(self, "_on_add_property_pressed"))
    if enemy_list:
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
    current_enemy = load("res://_resources/enemies/" + enemy_type_name + ".tres")
    refresh_property_list()

func refresh_property_list():
    property_list.clear()
    if current_enemy:
        for property in current_enemy.get_property_list():
            if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
                property_list.add_item("%s: %s" % [property.name, str(current_enemy.get(property.name))])

func _on_add_property_pressed():
    if current_enemy:
        var new_property = {
            new_property_name.text: new_property_value.text
        }
        current_enemy.extend_data(new_property)
        refresh_property_list()
        
        # Save the modified resource
        var err = ResourceSaver.save(current_enemy, current_enemy.resource_path)
        if err != OK:
            print("Failed to save the modified enemy type")

        # Refresh the editor to show new properties
        editor_interface.get_resource_filesystem().scan()
        editor_interface.get_inspector().refresh()
