extends Control

@export var default_config_file_path: String = "res://resources/spawn_default.json"
var scene_data = []
var file_dialog_open
var file_dialog_save

func _ready():
	# Connect the two FileDialogs
	file_dialog_open = $FileDialogOpen
	file_dialog_save = $FileDialogSave

	if file_dialog_open != null:
		file_dialog_open.connect("file_selected", Callable(self, "_on_file_open_selected"))
	else:
		show_message("FileDialogOpen node is missing")

	if file_dialog_save != null:
		file_dialog_save.connect("file_selected", Callable(self, "_on_file_save_selected"))
	else:
		show_message("FileDialogSave node is missing")

	$LabelMessage.visible = false  # Hide message by default

	# Connect the buttons
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

# Called when "Browse" button is pressed (opens scene files)
func _on_browse_pressed():
	file_dialog_open.file_mode = FileDialog.FILE_MODE_OPEN_FILE  # Set to file open mode
	file_dialog_open.set_filters(PackedStringArray(["*.tscn"]))  # Show only scene files
	file_dialog_open.popup()  # Open FileDialog for browsing

# Called when a file is selected (for Browse button)
func _on_file_open_selected(path):
	$PanelContainer/VBoxContainer/HBoxContainer/LabelScenePath.text = path.get_file()

# Called when "Add Scene" button is pressed
func _on_add_button_pressed():
	var scene_path = $PanelContainer/VBoxContainer/HBoxContainer/LabelScenePath.text
	var weight = $PanelContainer/VBoxContainer/HBoxContainer/SpinBoxWeight.value
	if scene_path == "" or weight <= 0:
		show_message("Invalid input")
		return
	add_scene_row(scene_path, weight)

# Called when "Save As" button is pressed (opens save dialog)
func _on_save_as_button_pressed():
	file_dialog_save.file_mode = FileDialog.FILE_MODE_SAVE_FILE  # Set to save file mode
	file_dialog_save.set_filters(PackedStringArray(["*.json"]))  # Filter for JSON files
	file_dialog_save.popup()

# Save the JSON data when a file is selected for saving
func _on_file_save_selected(path):
	if not path.right(5) == ".json":
		path += ".json"  # Ensure the file is saved with the .json extension

	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		show_message("Error opening file for writing")
		return

	var data = {"enemy_scenes": []}

	for entry in scene_data:
		data["enemy_scenes"].append({
			"scene": entry["scene"],
			"weight": entry["weight"]
		})

	var json_data = JSON.stringify(data, "\t")  # Convert the data to JSON format with indentation
	file.store_string(json_data)  # Write the JSON string to the file
	file.close()

	show_message("Data saved to " + path)

# Function to dynamically add a row for each scene with proper layout
func add_scene_row(scene_path: String, weight: float):
	var hbox = HBoxContainer.new()

	var label_scene = Label.new()
	label_scene.text = scene_path.get_file()
	label_scene.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var spin_box = SpinBox.new()
	spin_box.min_value = 0
	spin_box.max_value = 100
	spin_box.value = weight
	spin_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var remove_button = Button.new()
	remove_button.text = "Remove"
	remove_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

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
