extends Node

# Calculate separation force based on nearby enemies
func calculate_separation_force(enemy: CharacterBody3D, radius: float, weight: float) -> Vector3:
	var separation_force = Vector3.ZERO
	var neighbors_count = 0

	# Get all enemies from the same group
	var enemies = enemy.get_tree().get_nodes_in_group("enemies")
	var enemy_pos = enemy.global_transform.origin

	for other_enemy in enemies:
		# Ensure we are dealing with CharacterBody3D and not the same enemy
		if other_enemy != enemy and other_enemy is CharacterBody3D:
			var other_pos = other_enemy.global_transform.origin
			var distance = enemy_pos.distance_to(other_pos)

			# Apply separation only within the radius
			if distance < radius and distance > 0:
				separation_force += (enemy_pos - other_pos).normalized() / distance
				neighbors_count += 1

	if neighbors_count > 0:
		separation_force /= neighbors_count
		separation_force = separation_force.normalized() * weight

	return separation_force

# Calculate alignment force based on nearby enemies
func calculate_alignment_force(enemy: CharacterBody3D, radius: float, weight: float) -> Vector3:
	var alignment_force = Vector3.ZERO
	var neighbors_count = 0

	# Get all enemies from the same group
	var enemies = enemy.get_tree().get_nodes_in_group("enemies")

	for other_enemy in enemies:
		# Ensure we are dealing with CharacterBody3D and not the same enemy
		if other_enemy != enemy and other_enemy is CharacterBody3D:
			var other_velocity = other_enemy.velocity
			var other_pos = other_enemy.global_transform.origin
			var distance = enemy.global_transform.origin.distance_to(other_pos)

			if distance < radius:
				alignment_force += other_velocity
				neighbors_count += 1

	if neighbors_count > 0:
		alignment_force /= neighbors_count
		alignment_force = alignment_force.normalized() * weight

	return alignment_force
