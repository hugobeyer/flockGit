class_name SeparationBehavior
extends Node

var radius: float

func _init(separation_radius: float = 3.0):
	radius = separation_radius

func calculate(boid, neighbors) -> Vector3:
	var separation_force = Vector3.ZERO
	var close_neighbors = 0
	
	for neighbor in neighbors:
		var distance = boid.global_position.distance_to(neighbor.global_position)
		if distance > 0 and distance < radius:
			var repulsion = boid.global_position - neighbor.global_position
			repulsion = repulsion.normalized() / distance
			separation_force += repulsion
			close_neighbors += 1
	
	if close_neighbors > 0:
		separation_force /= close_neighbors
	
	return separation_force.normalized() * boid.max_speed if separation_force != Vector3.ZERO else Vector3.ZERO
