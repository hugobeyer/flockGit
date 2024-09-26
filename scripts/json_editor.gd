extends Control

@export var config_file_path: String = "res://resources/spawn_default.json"
var scene_data = []

# Reference to the FileDialog
var file_dialog

func _ready():
	load_json_data()
	file_dialog = $FileDialog  # Reference to the FileDialog in the scene
	file_dialog.connect("file_selected", self, "_on_file_selected")

# Open the FileDialog when "Load" button is pressed
func _on_load_button_pressed():
	file_dialog.popup()  # Open the FileDialog

# When a file is selected, place it in the LineEdit
func _on_file_selected(path):
	$LineEdit.text = path  # Set the selected path in the LineEdit

# Called when "Add" button is pressed to add new scene data
func _on_add_button_pressed():
	var scene_path = $LineEdit.text
	var weight = $SpinBox.value
	var new_entry = {"scene": scene_path, "weight": weight}
	scene_data.append(new_entry)
	update_ui()  # Optionally update the UI to reflect new data

# Save the data to JSON when "Save" button is pressed
func _on_save_button_pressed():
	save_json_data()

# Save the data into the JSON file
func save_json_data():
	var file = FileAccess.open(config_file_path, FileAccess.WRITE)
	var data = {"enemy_scenes": scene_data}
	file.store_string(JSON.stringify(data))
	file.close()

# Load existing JSON data
func load_json_data():
	var file = FileAccess.open(config_file_path, FileAccess.READ)
	if file:
		var data = JSON.parse_string(file.get_as_text())
		if data.error == OK and data.result.has("enemy_scenes"):
			scene_data = data.result["enemy_scenes"]
			update_ui()  # Optionally update the UI to reflect loaded data
		file.close()

# Updates the UI with loaded or new entries (optional if needed)
func update_ui():
	# Implement how to refresh or display the current scene_data array in your UI
	pass
