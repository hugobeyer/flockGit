extends CharacterBody3D

@export var health: float = 100.0  # Enemy health
@export var size: Vector3 = Vector3(1, 1, 1)  # Enemy size
@export var speed: float = 5.0  # Movement speed
@export var random_walk_distance: float = 10.0  # Max distance for random walking
@export var sight_radius: float = 15.0  # Radius for detecting the player
@export var damage_force: float = 10.0  # Damage dealt to the player when close

var random_walk_target: Vector3
var player_position: Vector3 = Vector3.ZERO
var player: Node3D = null

func _ready():
	# Set the size of the enemy
	scale = size
	set_random_walk_target()

	# Try to find the player node safely at /root/Main/player_pos
	player = get_node_or_null("/root/Main/player_pos")  # Updated to use player_pos

func _process(_delta):
	if player and is_player_in_sight():
		move_towards_player(_delta)
	else:
		random_walk(_delta)

	if player and is_close_to_player():
		damage_player()

func set_random_walk_target():
	# Set a random target within the random_walk_distance
	var random_direction = Vector3(randf_range(-1.0, 1.0), 0, randf_range(-1.0, 1.0)).normalized()
	random_walk_target = global_transform.origin + random_direction * random_walk_distance

func random_walk(_delta):
	# Move towards the random walk target
	var direction = (random_walk_target - global_transform.origin).normalized()
	velocity = direction * speed
	move_and_slide()

	# If close to the random walk target, set a new one
	if global_transform.origin.distance_to(random_walk_target) < 1.0:
		set_random_walk_target()

func is_player_in_sight() -> bool:
	# Check if the player is within the sight radius
	if player:
		player_position = player.global_transform.origin
		return global_transform.origin.distance_to(player_position) <= sight_radius
	return false	

func move_towards_player(_delta):
	# Move the enemy towards the player
	var direction_to_player = (player_position - global_transform.origin).normalized()
	velocity = direction_to_player * speed
	move_and_slide()

func is_close_to_player() -> bool:
	# Check if the enemy is close enough to damage the player
	return global_transform.origin.distance_to(player_position) < 2.0

func damage_player():
	if player:
		# Example: player.take_damage(damage_force)
		pass
