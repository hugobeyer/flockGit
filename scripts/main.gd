extends Node3D

@export var kills_required_for_spread: int = 12  # Number of kills required to activate spread mode
@export var spread_duration: float = 10.0  # Duration for spread mode to stay active

var kills: int = 0  # Track number of kills
var gun: Node3D  # Reference to the player's gun

func _ready():
	gun = get_node("/root/Main/player_pos/player_rot/Gun")  # Adjust to the correct gun node path
	
	# Connect to the SignalBus signal "enemy_killed"
	if SignalBus.has_signal("enemy_killed"):
		SignalBus.connect("enemy_killed", Callable(self, "_on_enemy_killed"))
	else:
		print("SignalBus does not have 'enemy_killed' signal.")

# Called when an enemy is killed
func _on_enemy_killed(killer: Node3D):
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
