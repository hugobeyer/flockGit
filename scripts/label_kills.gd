extends Label

var kills: int = 0  # Track the number of kills

# Called when the node enters the scene tree for the first time
func _ready():
	# Connect to the global "enemy_killed" signal on SignalBus
	SignalBus.connect("enemy_killed", Callable(self, "_on_enemy_killed"))
	update_kill_count()

# Called whenever an enemy is killed
func _on_enemy_killed(enemy_instance):
	kills += 1
	update_kill_count()

# Update the kill count display
func update_kill_count():
	text = "Kills: " + str(kills)
