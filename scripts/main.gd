class_name WaveResource

extends Node3D

@export var kills_required_for_spread: int = 12  # Number of kills required to activate spread mode
@export var spread_duration: float = 10.0  # Duration for spread mode to stay active

var kills: int = 0  # Track number of kills
var gun: Node3D  # Reference to the player's gun

@onready var wave_system = $WaveSystem

@export var enemy_scene: PackedScene
@export var enemy_count: int = 10
var current_wave_index: int = 0

const WaveResourceScript = preload("res://scripts/wave_resource.gd")

func _ready():
	gun = get_node("Player/player_rot/Gun")  # Adjust to the correct gun node path
	
	# Connect to the SignalBus signal "enemy_killed"
	if SignalBus.has_signal("enemy_killed"):
			SignalBus.connect("enemy_killed", Callable(self, "_on_enemy_killed"))
	else:
			print("SignalBus does not have 'enemy_killed' signal.")

	# Connect to WaveSystem signals
	$WaveSystem.wave_completed.connect(_on_wave_completed)
	$WaveSystem.all_waves_completed.connect(_on_all_waves_completed)
	wave_system.start_waves()

# Called when an enemy is killed
func _on_enemy_killed():
	kills += 1  # Increment kill count
	if kills >= kills_required_for_spread:
		activate_spread_mode()

# Activate spread mode for a duration
func activate_spread_mode():
	if gun and gun.has_method("activate_spread_mode"):
		gun.activate_spread_mode()
		print("Spread mode activated")
		await get_tree().create_timer(spread_duration).timeout
		gun.spread_active = false  # Deactivate spread after the duration ends
		print("Spread mode deactivated")

func clear_all_enemies():
	for child in get_children():
		if child.is_in_group("enemies"):
			child.queue_free()

func _on_wave_completed():
	# Handle wave completion logic here
	pass

func _on_all_waves_completed():
	# Handle all waves completion logic here
	pass

func start_waves():
	if current_wave_index < enemy_count:
		start_next_wave()
	else:
		print("All waves completed")

func start_next_wave():
	current_wave_index += 1
	if current_wave_index == 1 and enemy_scene:  # Only one wave
		var wave = enemy_scene.instantiate()
		if wave is Resource and wave.get_script() is WaveResource:
			start_wave(wave)  # Changed from _start_wave to start_wave
		else:
			push_error("Invalid wave resource")
	else:
		emit_signal("all_waves_completed")

# Add this method if it doesn't exist
func start_wave(_wave):
	# Implement wave starting logic here
	pass
