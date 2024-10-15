extends Label

var kills: int = 0

# Called when the node enters the scene tree for the first time
func _ready():
	text = "0"
	# Connect to the enemy_killed signal from the SignalBus
	SignalBus.connect("enemy_killed", Callable(self, "_on_enemy_killed"))

# Called whenever an enemy is killed
func _on_enemy_killed():
	kills += 1
	text = str(kills)
