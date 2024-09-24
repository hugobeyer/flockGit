extends CharacterBody3D

signal enemy_killed  # Declare the signal


@export var health: float = 100.0
@export var max_health: float = 50.0
@export var move_speed: float = 4.0

@export var knockback_force: float = -0.5
@export var knockback_duration: float = 0.1


var player_target: CharacterBody3D
var neighbors: Array = []
var health_label: Label3D
var knockback_timer: float = 0.0
var knockback_direction: Vector3 = Vector3.ZERO
var flocking: Node3D

func _ready():
	health_label = $Label3D
	flocking = $Flocking  # Reference to the Flocking node
	update_health_label()

func _process(delta):	
	if knockback_timer > 0:
		knockback_timer -= delta
		apply_knockback()
	else:
		if player_target:
			normal_movement()

func normal_movement():
	if player_target:
		var distance_to_player = global_transform.origin.distance_to(player_target.global_transform.origin)

		# Calculate the pursuit force
		var pursuit_force = Vector3.ZERO
		if distance_to_player <= flocking.pursuit_radius:
			pursuit_force = (player_target.global_transform.origin - global_transform.origin).normalized() * move_speed

		# Flocking forces
		var neighbors = get_neighbors(flocking.separation_radius)
		var separation = flocking.calculate_separation(self, neighbors) * flocking.separation_weight
		var alignment = flocking.calculate_alignment(self, neighbors) * flocking.alignment_weight
		var cohesion = flocking.calculate_cohesion(self, neighbors) * flocking.cohesion_weight
		var avoidance = flocking.avoid_obstacles(self) * 2.0
		var flocking_force = (separation + alignment + cohesion + avoidance).normalized() * move_speed

		# Blend pursuit and flocking forces
		var combined_force = (flocking_force + pursuit_force).normalized() * move_speed
		self.velocity = combined_force

		# Apply movement and rotate to face movement direction
		move_and_slide()
		if self.velocity.length() > 0.01:
			var direction = self.velocity.normalized()
			direction.y = 0  # Keep Y axis unaffected
			var rotation_angle = atan2(direction.x, direction.z)
			var target_basis = Basis(Vector3(0, 1, 0), rotation_angle)
			global_transform.basis = global_transform.basis.slerp(target_basis, 0.1)  # Smooth rotation





func apply_knockback():
	# Zero out Y axis for knockback direction
	knockback_direction.y = 0
	var knockback_velocity = knockback_direction * knockback_force

	# Apply knockback to velocity
	self.velocity.x += knockback_velocity.x
	self.velocity.z += knockback_velocity.z

	# Apply movement after knockback
	move_and_slide()

	# Flash red effect to indicate damage taken
	flash_red()

func flash_red() -> void:
	# Set the per-instance shader parameter for flashing red
	$MeshInstance3D.set_instance_shader_parameter("flash_intensity", 1.0)

	await get_tree().create_timer(0.2).timeout

	# Revert the per-instance shader parameter to disable the flash
	$MeshInstance3D.set_instance_shader_parameter("flash_intensity", 0.0)

func chase_player():
	if player_target:
		var direction_to_player = (player_target.global_transform.origin - global_transform.origin).normalized()
		self.velocity = direction_to_player * move_speed * 1.5
		move_and_slide()

func on_bullet_hit(damage: float, bullet_direction: Vector3):
	var remaining_damage = damage
	if $Shield != null:
		remaining_damage = $Shield.take_damage(damage)  # Shield absorbs damage first
	
	health -= remaining_damage	
	knockback_direction = bullet_direction.normalized()
	knockback_timer = knockback_duration
	
	if health <= 0:
		die()
	else:
		update_health_label()

func die():
	#print("Enemy destroyed!")
	emit_signal("enemy_killed")  # Emit the signal when the enemy dies
	queue_free()

func update_health_label():
	if health_label != null:
		health = clamp(health, 0, max_health)
		var health_percentage = (health / max_health) * 100
		health_label.text = str(health_percentage) + "%"

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
