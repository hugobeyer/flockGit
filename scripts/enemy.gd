extends CharacterBody3D

@export var health: float = 100.0
@export var max_health: float = 100.0
@export var move_speed: float = 3.0

@export var separation_weight: float = 1.5
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0
@export var separation_radius: float = 4.0
@export var alignment_radius: float = 6.0
@export var cohesion_radius: float = 6.0

@export var pursuit_radius: float = 10.0  # Distance to start chasing the player
@export var obstacle_avoidance_radius: float = 3.0  # Distance to detect obstacles
@export var knockback_force: float = 5.0  # Adjust this value to control how strong the knockback is

#var velocity: Vector3 = Vector3.ZERO
var player_target: CharacterBody3D  # The player that this enemy is targeting
var neighbors: Array = []
var health_label: Label3D  # Reference to the health label

func _ready():
	health_label = $Label3D  # Assuming the Label3D node is a direct child of the enemy
	update_health_label()  # Initialize health label at 100%

# Called every frame
func _process(_delta):
	if player_target:
		# If within pursuit radius, chase the player
		if global_transform.origin.distance_to(player_target.global_transform.origin) <= pursuit_radius:
			chase_player()
		else:
			# Compute flocking forces
			var separation = calculate_separation() * separation_weight
			var alignment = calculate_alignment() * alignment_weight
			var cohesion = calculate_cohesion() * cohesion_weight
			var avoidance = avoid_obstacles() * 2.0  # Avoid obstacles dynamically

			# Combine forces
			var combined_force = (separation + alignment + cohesion + avoidance).normalized()
			velocity = combined_force * move_speed

			# Move the enemy based on the combined forces
			move_and_slide()

# Behavior when chasing the player (dynamic condition)
# Chase player behavior
func chase_player():
	if player_target:
		var direction_to_player = (player_target.global_transform.origin - global_transform.origin).normalized()
		velocity = direction_to_player * move_speed * 1.5  # Increase speed while chasing
		move_and_slide()

# Function to handle when the enemy is hit by a bullet
func on_bullet_hit(damage: float, bullet_direction: Vector3):
	health -= damage
	#print("Enemy hit! Health is now: ", health)
	
	apply_knockback(bullet_direction)
	if health <= 0:
		die()
	else:
		update_health_label()  # Update health label after taking damage
		
# Function to apply knockback when hit by a bullet
func apply_knockback(direction: Vector3):
	# Ignore the Y-axis for horizontal knockback
	direction.y = 0
	# Normalize the direction to get the direction vector
	var knockback_velocity = direction.normalized() * knockback_force
	# Add this knockback to the enemy's current velocity (affect X and Z only)
	self.velocity.x += knockback_velocity.x
	self.velocity.z += knockback_velocity.z
# Function to handle enemy death
func die():
	#print("Enemy destroyed!")
	queue_free()  # Remove enemy from the scene

# Function to update the health label
func update_health_label():
	if health_label != null:
		# Ensure health is clamped between 0 and max_health
		health = clamp(health, 0, max_health)
		var health_percentage = (health / max_health) * 100
		health_label.text = str(health_percentage) + "%"  # Update label text to show percentage
	#else:
		#print("Health label is null.")

# Calculate separation to avoid crowding with neighbors
func calculate_separation() -> Vector3:
	var separation_force = Vector3.ZERO
	neighbors = get_neighbors(separation_radius)

	for neighbor in neighbors:
		var distance = global_transform.origin.distance_to(neighbor.global_transform.origin)
		if distance > 0:
			var push_direction = (global_transform.origin - neighbor.global_transform.origin).normalized()
			separation_force += push_direction / distance

	return separation_force.normalized()

# Calculate alignment to match the movement direction with neighbors
func calculate_alignment() -> Vector3:
	var avg_direction = Vector3.ZERO
	neighbors = get_neighbors(alignment_radius)

	for neighbor in neighbors:
		avg_direction += neighbor.velocity.normalized()

	if neighbors.size() > 0:
		avg_direction /= neighbors.size()

	return avg_direction.normalized()

# Calculate cohesion to move towards the average position of neighbors
func calculate_cohesion() -> Vector3:
	var avg_position = Vector3.ZERO
	neighbors = get_neighbors(cohesion_radius)

	for neighbor in neighbors:
		avg_position += neighbor.global_transform.origin

	if neighbors.size() > 0:
		avg_position /= neighbors.size()

	return (avg_position - global_transform.origin).normalized()

# Avoid obstacles dynamically using raycasting
func avoid_obstacles() -> Vector3:
	var obstacle_avoidance = Vector3.ZERO
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.from = global_transform.origin
	query.to = global_transform.origin + velocity * obstacle_avoidance_radius
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)
	if result:
		var hit_point = result.position
		var avoidance_direction = (global_transform.origin - hit_point).normalized()
		obstacle_avoidance = avoidance_direction

	return obstacle_avoidance

# Get nearby enemies within the given radius
# Get nearby enemies within the given radius
# Get nearby enemies within the given radius
func get_neighbors(radius: float) -> Array:
	var nearby_enemies = []
	var space_state = get_world_3d().direct_space_state

	# Create a spherical shape for the query based on the passed radius
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = radius

	# Create a query for the shape
	var query = PhysicsShapeQueryParameters3D.new()
	query.transform = global_transform  # Position the query at the current enemy location
	query.shape = sphere_shape  # Use the custom sphere shape with the given radius
	query.collide_with_bodies = true

	# Perform the query with a limit on the number of results
	var result = space_state.intersect_shape(query, 32)  # Example: Get up to 32 results
	
	for item in result:
		var body = item.collider
		if body != self and body.is_in_group("enemies"):
			nearby_enemies.append(body)

	return nearby_enemies
