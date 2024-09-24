extends Node3D  # Or whatever your main scene root node is

var kills_count: int = 0  # Track the number of kills
var label_kills: Label  # Reference to the kills label in the UI

func _ready():
	# Get the kills label from the UI (adjust the path as needed)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.connect("enemy_killed", Callable(self, "on_enemy_killed"))
	label_kills = get_node("LabelKills")
	update_kill_count()

# Function to increment kills and update the label
func on_enemy_killed():
	kills_count += 1
	print("Enemy killed! Current kills: ", kills_count)
	update_kill_count()

# Update the label with the current kill count
func update_kill_count():
	if label_kills:
		label_kills.text = "Kills: " + str(kills_count)
