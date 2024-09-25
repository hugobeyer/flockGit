extends Node3D

@export var animation_player_path: NodePath = "AnimationPlayer"  # Path to the AnimationPlayer within the node hierarchy
@export var melee_node_path: NodePath = "."  # Path to the melee root node (default is current node)
@export var swing_animation: String = "swing"  # Name of the swing animation
@export var player_pos_path: NodePath = "/root/Main/player_pos"  # Path to the player_pos node

# Timing parameters
@export var animation_speed: float = 1.0  # Speed of the swing animation
@export var attack_radius: float = 1.66  # Radius within which the enemy can hit the player
@export var damage_interval: float = 0.2  # Time between each damage attempt
@export var damage_amount: float = 10.0  # Damage dealt to the player on each hit
@export var animation_delay: float = 0.1  # Offset delay before damage is applied

var player_pos: Node3D
var animation_player: AnimationPlayer
var melee_node: Node3D  # The node responsible for melee (could be the sword or similar)
var damage_timer: float = 0.0  # Internal timer to track damage intervals

func _ready():
	# Find player_pos using the node path
	player_pos = get_node_or_null(player_pos_path)
	if player_pos == null:
		print("player_pos not found at path: ", player_pos_path)
	else:
		print("player_pos found: ", player_pos)

	# Find the animation player using the node path
	animation_player = get_node_or_null(animation_player_path)
	if animation_player == null:
		print("AnimationPlayer not found at path: ", animation_player_path)
	else:
		print("AnimationPlayer found: ", animation_player)

	# Get the melee node (this is the root node of the Melee object)
	melee_node = get_node_or_null(melee_node_path)
	if melee_node == null:
		print("Melee node not found at path: ", melee_node_path)
	else:
		melee_node.visible = false  # Make melee node invisible until in range

# Function to play the swing animation with the correct settings
func play_swing_animation():
	if animation_player.has_animation(swing_animation):
		animation_player.play(swing_animation)
		animation_player.speed_scale = animation_speed
	else:
		print("Animation not found: ", swing_animation)

# Function to apply damage to the player if within range
func apply_damage_to_player(delta: float):
	if player_pos == null:
		return  # No player found

	var distance_to_player = global_transform.origin.distance_to(player_pos.global_transform.origin)

	if distance_to_player <= attack_radius:
		if melee_node.visible == false:
			melee_node.visible = true  # Make the melee node visible when within attack range
			play_swing_animation()  # Start playing the animation

		damage_timer += delta
		if damage_timer >= damage_interval + animation_delay:
			# Damage player and reset timer
			damage_player()
			damage_timer = 0.0
	else:
		melee_node.visible = false  # Hide melee node when out of range
		animation_player.stop()  # Stop the swing animation when the player is out of range

# Function to deal damage to the player (you can adjust this based on your player's health system)
func damage_player():
	if player_pos.has_method("take_damage"):
		player_pos.take_damage(damage_amount)
		print("Player hit for ", damage_amount, " damage.")
	else:
		print("Player does not have take_damage method.")

# Main update function
func _process(delta: float):
	apply_damage_to_player(delta)
