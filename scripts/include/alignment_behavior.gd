class_name AlignmentBehavior
extends Node

var radius: float

func _init(alignment_radius: float = 5.0):
	radius = alignment_radius

func calculate(boid, neighbors) -> Vector3:
	var average_velocity = Vector3.ZERO
	for neighbor in neighbors:
		average_velocity += neighbor.velocity
	
	if neighbors.size() > 0:
		average_velocity /= neighbors.size()
		return (average_velocity - boid.velocity).normalized() * boid.max_speed
	
	return Vector3.ZERO
