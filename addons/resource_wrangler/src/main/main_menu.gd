@tool
extends MenuButton

# Create an enum to store the options
enum Options {
	NEW,
	OPEN,
	SAVE,
	RECENT=4
}

signal menu_pressed(what)
signal recent_pressed(paf:String)


var popup:PopupMenu



func _ready():
	popup = get_popup()
	make_menu()
	popup.id_pressed.connect(_item_selected)


func make_menu():
	var new_icon = get_theme_icon(&"New", &"EditorIcons")
	var save_icon = get_theme_icon(&"Save", &"EditorIcons")
	var load_icon = get_theme_icon(&"Load", &"EditorIcons")
	var nodes_icon = get_theme_icon(&"GraphEdit", &"EditorIcons")
	popup.clear(true)
	popup.add_icon_item(new_icon, "New", Options.NEW)
	popup.add_icon_item(load_icon, "Open", Options.OPEN)
	popup.add_icon_item(save_icon, "Save", Options.SAVE)
	popup.add_separator()
	var list = rwSettings.get_setting(&"recent_boards")
	#print("**list:"); list.filter( func(e): print(e); return e )
	var i = Options.RECENT + 1
	if list:
		for paf in list:
			popup.add_icon_item(nodes_icon, paf, i)
			i += 1


func _item_selected(id: int):
	match id:
		Options.NEW:
			menu_pressed.emit(&"new")
		Options.OPEN:
			menu_pressed.emit(&"open")
		Options.SAVE:
			menu_pressed.emit(&"save")
		_:
			var txt = popup.get_item_text(id-1)
			recent_pressed.emit(txt)
