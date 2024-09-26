class_name CohesionBehavior
extends Node

var radius: float

func _init(cohesion_radius: float = 10.0):
	radius = cohesion_radius

func calculate(boid, neighbors) -> Vector3:
	var center_of_mass = Vector3.ZERO
	for neighbor in neighbors:
		center_of_mass += neighbor.global_position
	
	if neighbors.size() > 0:
		center_of_mass /= neighbors.size()
		return (center_of_mass - boid.global_position).normalized() * boid.max_speed
	
	return Vector3.ZERO
