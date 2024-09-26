class_name AlignmentBehavior
extends Node

var radius: float

func _init(alignment_radius: float = 5.0):
	radius = alignment_radius

func calculate(boid, neighbors) -> Vector3:
	var average_velocity = Vector3.ZERO
	var neighbor_count = 0
	
	for neighbor in neighbors:
		if neighbor != boid and neighbor.global_position.distance_to(boid.global_position) <= radius:
			average_velocity += neighbor.velocity
			neighbor_count += 1
	
	if neighbor_count > 0:
		average_velocity /= neighbor_count
		return (average_velocity.normalized() * boid.move_speed - boid.velocity).limit_length(boid.max_force)
	
	return Vector3.ZERO
