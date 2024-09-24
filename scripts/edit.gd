extends Control

@export var default_config_file_path: String = "res://resources/spawn_default.json"
var scene_data = []
var file_dialog

func _ready():
	file_dialog = $FileDialog
	if file_dialog != null:
		file_dialog.connect("file_selected", Callable(self, "_on_file_selected"))
	else:
		print("FileDialog node is missing")

	$LabelMessage.visible = false  # Hide the message label by default

	# Check other nodes
	if $ButtonAdd != null and $ButtonSaveAs != null and $ButtonBrowse != null:
		$ButtonAdd.connect("pressed", Callable(self, "_on_add_button_pressed"))
		$ButtonSaveAs.connect("pressed", Callable(self, "_on_save_as_button_pressed"))
		$ButtonBrowse.connect("pressed", Callable(self, "_on_browse_pressed"))
	else:
		print("One or more buttons are missing in the scene")

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

# Called when a file is selected (FileDialog)
func _on_file_selected(path):
	$LabelScenePath.text = path  # Set selected path to label

# Called when "Add Scene" button is pressed
func _on_add_button_pressed():
	var scene_path = $LabelScenePath.text
	var weight = $SpinBoxWeight.value
	
	if scene_path == "" or weight <= 0:
		show_message("Invalid input")
		return
	
	# Check if the VBoxContainer is correctly referenced
	if $VBoxContainer == null:
		print("VBoxContainer is missing")
		return
	
	add_scene_row(scene_path, weight)
	show_message("Added row for scene: " + scene_path)


# Function to dynamically add a row for each scene
func add_scene_row(scene_path: String, weight: float):
	var hbox = HBoxContainer.new()
	
	var label_scene = Label.new()
	label_scene.text = scene_path
	
	var spin_box = SpinBox.new()
	spin_box.min_value = 0
	spin_box.max_value = 100
	spin_box.value = weight
	
	hbox.add_child(label_scene)
	hbox.add_child(spin_box)
	
	$VBoxContainer.add_child(hbox)
	scene_data.append({"scene": scene_path, "weight": weight})

# Called when "Save As" button is pressed
func _on_save_as_button_pressed():
	file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE  # Set to save file mode
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
	timer.wait_time = 3.0  # Show the message for 3 seconds
	timer.one_shot = true
	timer.connect("timeout", Callable(self, "_on_message_timeout"))
	timer.start()

# Function to hide the message label after the timeout
func _on_message_timeout():
	$LabelMessage.visible = false
