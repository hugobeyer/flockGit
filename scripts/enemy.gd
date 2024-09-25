extends CharacterBody3D

signal enemy_killed  # Declare the signal for when the enemy dies

@export var health: float = 100.0
@export var max_health: float = 100.0
@export var move_speed: float = 4.0
@export var knockback_force: float = -0.5
@export var knockback_duration: float = 0.1

var player_target: CharacterBody3D
var neighbors: Array = []
var health_label: Label3D
var knockback_timer: float = 0.0
var knockback_direction: Vector3 = Vector3.ZERO
var flocking: Node3D

# Initialize the enemy
func _ready():
	health_label = $Label3D
	flocking = $Flocking  # Reference to the Flocking node
	update_health_label()

# Update every frame
func _process(delta):
	if knockback_timer > 0:
		knockback_timer -= delta
		apply_knockback()
		flash_red()  # Visual feedback for damage
	else:
		if player_target:
			normal_movement()

# Handle enemy movement logic
func normal_movement():
	if player_target:
		var distance_to_player = global_transform.origin.distance_to(player_target.global_transform.origin)

		# Calculate pursuit force
		var pursuit_force = Vector3.ZERO
		if distance_to_player <= flocking.pursuit_radius:
			pursuit_force = (player_target.global_transform.origin - global_transform.origin).normalized() * move_speed

		# Flocking behavior forces
		neighbors = get_neighbors(flocking.separation_radius)
		var separation = flocking.calculate_separation(self, neighbors) * flocking.separation_weight
		var alignment = flocking.calculate_alignment(self, neighbors) * flocking.alignment_weight
		var cohesion = flocking.calculate_cohesion(self, neighbors) * flocking.cohesion_weight
		var avoidance = flocking.avoid_obstacles(self) * 2.0
		var flocking_force = (separation + alignment + cohesion + avoidance).normalized() * move_speed

		# Combine pursuit and flocking forces
		var combined_force = (flocking_force + pursuit_force).normalized() * move_speed
		self.velocity = combined_force

		# Apply movement and face movement direction
		move_and_slide()
		if self.velocity.length() > 0.01:
			var direction = self.velocity.normalized()
			direction.y = 0  # Ensure the Y-axis remains unaffected
			var rotation_angle = atan2(direction.x, direction.z)
			var target_basis = Basis(Vector3(0, 1, 0), rotation_angle)
			global_transform.basis = global_transform.basis.slerp(target_basis, 0.1)  # Smooth rotation

# Apply knockback effect
func apply_knockback():
	knockback_direction.y = 0  # Ensure Y-axis remains unaffected
	var knockback_velocity = knockback_direction * knockback_force
	self.velocity.x += knockback_velocity.x
	self.velocity.z += knockback_velocity.z
	move_and_slide()  # Apply movement

# Visual feedback for taking damage
func flash_red() -> void:
	$MeshInstance3D.set_instance_shader_parameter("flash_intensity", 1.0)

	# Wait for a short duration and then reset the shader
	await get_tree().create_timer(0.2).timeout
	$MeshInstance3D.set_instance_shader_parameter("flash_intensity", 0.0)

# Called when hit by a bullet
func on_bullet_hit(damage: float, bullet_direction: Vector3):
	var remaining_damage = damage
	if $Shield != null:
		remaining_damage = $Shield.take_damage(damage)  # Shield absorbs part of the damage

	# Deduct health based on remaining damage
	health -= remaining_damage
	knockback_direction = bullet_direction.normalized()  # Set knockback direction
	knockback_timer = knockback_duration  # Apply knockback for the duration

	# Check for death
	if health <= 0:
		die()
	else:
		flash_red()  # Show damage effect
		update_health_label()

# Trigger enemy death
func die():
	SignalBus.emit_signal("enemy_killed", self)  # Emit the signal for enemy death
	queue_free()  # Remove the enemy from the scene

# Update health label
func update_health_label():
	if health_label != null:
		health = clamp(health, 0, max_health)
		var health_percentage = (health / max_health) * 100
		health_label.text = str(int(health_percentage)) + "%"

# Get nearby neighbors for flocking
func get_neighbors(radius: float) -> Array:
	var nearby_enemies = []
	var space_state = get_world_3d().direct_space_state

	# Create spherical shape for querying neighbors
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = radius

	# Query setup
	var query = PhysicsShapeQueryParameters3D.new()
	query.transform = global_transform  # Query location
	query.shape = sphere_shape  # Set query shape
	query.collide_with_bodies = true

	# Perform the query and collect results
	var result = space_state.intersect_shape(query, 32)
	for item in result:
		var body = item.collider
		if body != self and body.is_in_group("enemies"):
			nearby_enemies.append(body)

	return nearby_enemies
