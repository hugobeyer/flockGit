extends Node  # or whatever your base class is
const WaveResourceSc = preload("res://scripts/wave_resource.gd")

@onready var wave_list = $VBoxContainer/HBoxContainer/WaveListContainer/WaveList
@onready var enemy_count_spin_box = $VBoxContainer/HBoxContainer/WaveDetailsContainer/GridContainer/EnemyCountSpinBox
@onready var size_multiplier_spin_box = $VBoxContainer/HBoxContainer/WaveDetailsContainer/GridContainer/SizeMultiplierSpinBox
@onready var difficulty_option_button = $VBoxContainer/HBoxContainer/WaveDetailsContainer/GridContainer/DifficultyOptionButton
@onready var spawn_interval_spin_box = $VBoxContainer/HBoxContainer/WaveDetailsContainer/GridContainer/SpawnIntervalSpinBox

var wave_resource: WaveResourceSc
var current_wave_index: int = -1

func _ready():
	wave_resource = WaveResourceSc.new()
	update_wave_list()

func update_wave_list():
	wave_list.clear()
	if wave_resource:
		for i in range(wave_resource.waves.size()):
			wave_list.add_item("Wave " + str(i + 1))
	for i in range(wave_resource.waves.size()):
		wave_list.add_item("Wave " + str(i + 1))

func show_wave_details(wave):
	enemy_count_spin_box.value = wave.enemy_count
	size_multiplier_spin_box.value = wave.size_multiplier
	difficulty_option_button.selected = wave.get_difficulty()
	spawn_interval_spin_box.value = wave.spawn_interval

func _on_wave_list_item_selected(index):
	current_wave_index = index
	var wave = wave_resource.get_wave(index)
	if wave:
		show_wave_details(wave)

func _on_add_wave_button_pressed():
	var new_wave = WaveResourceSc.new()
	wave_resource.add_wave(new_wave)
	update_wave_list()
	var new_index = wave_resource.waves.size() - 1
	wave_list.select(new_index)
	_on_wave_list_item_selected(new_index)

func _on_remove_wave_button_pressed():
	if current_wave_index >= 0:
		wave_resource.remove_wave(current_wave_index)
		update_wave_list()
		if wave_resource.waves.size() > 0:
			wave_list.select(0)
			_on_wave_list_item_selected(0)
		else:
			current_wave_index = -1
			show_wave_details(WaveResourceSc.new())

func _on_enemy_count_spin_box_value_changed(value):
	if current_wave_index >= 0:
		var wave = wave_resource.get_wave(current_wave_index)
		if wave:
			wave.enemy_count = value

func _on_size_multiplier_spin_box_value_changed(value):
	if current_wave_index >= 0:
		var wave = wave_resource.get_wave(current_wave_index)
		if wave:
			wave.size_multiplier = value

func _on_difficulty_option_button_item_selected(index):
	if current_wave_index >= 0:
		var wave = wave_resource.get_wave(current_wave_index)
		if wave:
			wave.set_difficulty(index)

func _on_spawn_interval_spin_box_value_changed(value):
	if current_wave_index >= 0:
		var wave = wave_resource.get_wave(current_wave_index)
		if wave:
			wave.spawn_interval = value

func _on_save_button_pressed():
	# Implement save functionality
	pass

func _on_load_button_pressed():
	# Implement load functionality
	pass

func _on_preview_button_pressed():
	# Implement preview functionality
	pass

func _on_back_button_pressed():
	# Implement back functionality
	pass

func _on_file_dialog_file_selected(path: String):
	# Handle file selection
	pass
