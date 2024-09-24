extends Control

@export var default_config_file_path: String = "res://resources/spawn_default.json"
var scene_data = []
var file_dialog

func _ready():
	file_dialog = $FileDialog  # Connect FileDialog
	if file_dialog != null:
		file_dialog.connect("file_selected", Callable(self, "_on_file_save_selected"))
	else:
		show_message("FileDialog node is missing")

	$LabelMessage.visible = false  # Hide message by default

	# Connect the "Add Scene" and "Save As" buttons with correct paths
	var button_add = $PanelContainer/VBoxContainer/ButtonAdd
	var button_saveas = $PanelContainer/VBoxContainer/ButtonSaveAs
	var button_browse = $PanelContainer/VBoxContainer/HBoxContainer/ButtonBrowse
	button_add.connect("pressed", Callable(self, "_on_add_button_pressed"))
	button_saveas.connect("pressed", Callable(self, "_on_save_as_button_pressed"))
	button_browse.connect("pressed", Callable(self, "_on_browse_pressed"))

	load_json_data(default_config_file_path)

# Load JSON Data
func load_json_data(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var data = file.get_as_text()
		var result = JSON.parse_string(data)
		if result.get("error") == OK and result.get("result").has("enemy_scenes"):
			scene_data = result.get("result")["enemy_scenes"]
			for entry in scene_data:
				add_scene_row(entry["scene"], entry["weight"])
		else:
			show_message("Error parsing JSON file.")
		file.close()

# Called when "Browse" button is pressed
func _on_browse_pressed():
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE  # Set to open file mode
	file_dialog.popup()  # Open FileDialog

# Called when "Add Scene" button is pressed
func _on_add_button_pressed():
	var scene_path = $PanelContainer/VBoxContainer/HBoxContainer/LabelScenePath.text
	var weight = $PanelContainer/VBoxContainer/HBoxContainer/SpinBoxWeight.value
	if scene_path == "" or weight <= 0:
		show_message("Invalid input")
		return
	add_scene_row(scene_path, weight)

# Function to dynamically add a row for each scene with proper layout
func add_scene_row(scene_path: String, weight: float):
	var hbox = HBoxContainer.new()
	
	var label_scene = Label.new()
	label_scene.text = scene_path
	label_scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Expand to fill available space
	
	var spin_box = SpinBox.new()
	spin_box.min_value = 0
	spin_box.max_value = 100
	spin_box.value = weight
	spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL  # Expand to fill available space
	
	var remove_button = Button.new()
	remove_button.text = "Remove"
	remove_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER  # Keep centered and not expanding

	hbox.add_child(label_scene)
	hbox.add_child(spin_box)
	hbox.add_child(remove_button)

	$PanelContainer/VBoxContainer.add_child(hbox)

	scene_data.append({"scene": scene_path, "weight": weight, "hbox": hbox})
	
	remove_button.connect("pressed", Callable(self, "_on_remove_button_pressed").bind(hbox))

	show_message("Scene added: " + scene_path)

# Function to handle removing a row when the "Remove" button is pressed
func _on_remove_button_pressed(hbox):
	$PanelContainer/VBoxContainer.remove_child(hbox)
	for entry in scene_data:
		if entry["hbox"] == hbox:
			scene_data.erase(entry)
			break
	hbox.queue_free()

	show_message("Scene removed")

# Called when "Save As" button is pressed
func _on_save_as_button_pressed():
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE  # Set to save file mode
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM  # Allow navigating the file system
	file_dialog.set_filters(PackedStringArray(["*.json"]))  # Filter for JSON files
	file_dialog.popup()

# Save the JSON data when "Save As" is selected
func _on_file_save_selected(path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	var data = {"enemy_scenes": scene_data}
	var json_data = JSON.stringify(data)
	file.store_string(json_data)
	file.close()
	show_message("Data saved to " + path)

# Function to display a message for a few seconds and then hide it
func show_message(msg: String):
	$LabelMessage.text = msg
	$LabelMessage.visible = true

	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = 3.0  # Show message for 3 seconds
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_message_timeout"))
	timer.start()

# Function to hide the message label after the timeout
func _on_message_timeout():
	$LabelMessage.visible = false
