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

@export var knockback_force: float = 500.0
@export var knockback_duration: float = 0.1

@export var pursuit_radius: float = 10.0
@export var obstacle_avoidance_radius: float = 3.0

var player_target: CharacterBody3D
var neighbors: Array = []
var health_label: Label3D

var knockback_timer: float = 0.0
var knockback_direction: Vector3 = Vector3.ZERO

func _ready():
	health_label = $Label3D
	update_health_label()

func _process(delta):
	if knockback_timer > 0:
		knockback_timer -= delta
		apply_knockback()
	else:
		if player_target:
			normal_movement()
func normal_movement():
# Example: move towards the player
	if player_target:
		var direction_to_player = (player_target.global_transform.origin - global_transform.origin).normalized()
		self.velocity = direction_to_player * move_speed  # Chase player
		move_and_slide()  # Apply movement

func apply_knockback():
	knockback_direction.y = 0
	var knockback_velocity = knockback_direction * knockback_force
	self.velocity.x += knockback_velocity.x
	self.velocity.z += knockback_velocity.z
	move_and_slide() 
	
	if player_target:
		if global_transform.origin.distance_to(player_target.global_transform.origin) <= pursuit_radius:
			chase_player()
		else:
			var separation = calculate_separation() * separation_weight
			var alignment = calculate_alignment() * alignment_weight
			var cohesion = calculate_cohesion() * cohesion_weight
			var avoidance = avoid_obstacles() * 2.0  # Avoid obstacles dynamically

			# Combine forces
			var combined_force = (separation + alignment + cohesion + avoidance).normalized()
			self.velocity = combined_force * move_speed

			# Move the enemy based on the combined forces
			move_and_slide()

func chase_player():
	if player_target:
		var direction_to_player = (player_target.global_transform.origin - global_transform.origin).normalized()
		self.velocity = direction_to_player * move_speed * 1.5
		move_and_slide()

func on_bullet_hit(damage: float, bullet_direction: Vector3):
	health -= damage
	
	knockback_direction = bullet_direction.normalized()
	knockback_timer = knockback_duration
	
	if health <= 0:
		die()
	else:
		update_health_label()


func die():
	#print("Enemy destroyed!")
	queue_free()

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
	query.to = global_transform.origin + self.velocity * obstacle_avoidance_radius
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
