@tool
extends Tree

func _ready():
    if Engine.is_editor_hint():
        setup_preview_data()

func setup_preview_data():
    clear()
    set_column_titles_visible(true)
    set_columns(5)
    set_column_title(0, "Icon")
    set_column_title(1, "Name")
    set_column_title(2, "Health")
    set_column_title(3, "Damage")
    set_column_title(4, "Speed")
    
    set_column_expand(0, false)
    set_column_custom_minimum_width(0, 40)
    
    var root = create_item()
    hide_root = true
    
    var enemy_icon = preload("res://addons/pillz_table_editor/icons/icon.svg")
    
    var enemy1 = create_item(root)
    enemy1.set_icon(0, enemy_icon)
    enemy1.set_text(1, "Sample Enemy 1")
    enemy1.set_text(2, "100")
    enemy1.set_text(3, "10")
    enemy1.set_text(4, "5.0")
    
    var enemy2 = create_item(root)  
    enemy2.set_icon(0, enemy_icon)
    enemy2.set_text(1, "Sample Enemy 2")
    enemy2.set_text(2, "150")
    enemy2.set_text(3, "15")
    enemy2.set_text(4, "4.5")
    
    var enemy3 = create_item(root)
    enemy3.set_icon(0, enemy_icon)
    enemy3.set_text(1, "Sample Enemy 3")
    enemy3.set_text(2, "200")
    enemy3.set_text(3, "20")
    enemy3.set_text(4, "3.5")

