class_name CohesionBehavior
extends Node

var radius: float

func _init(cohesion_radius: float = 1.0):
	radius = cohesion_radius

func calculate(boid, neighbors) -> Vector3:
	var center_of_mass = Vector3.ZERO
	var neighbor_count = 0
	
	for neighbor in neighbors:
		if neighbor != boid and neighbor.global_position.distance_to(boid.global_position) <= radius:
			center_of_mass += neighbor.global_position
			neighbor_count += 1
	
	if neighbor_count > 0:
		center_of_mass /= neighbor_count
		var desired_velocity = (center_of_mass - boid.global_position).normalized() * boid.move_speed
		return (desired_velocity - boid.velocity).limit_length(boid.max_force)
	
	return Vector3.ZERO
