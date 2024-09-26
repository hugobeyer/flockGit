class_name ObstacleAvoidanceBehavior
extends Node

var radius: float

func _init(avoidance_radius: float = 5.0):
	radius = avoidance_radius

func calculate(boid, obstacles) -> Vector3:
	var avoidance_force = Vector3.ZERO
	for obstacle in obstacles:
		var to_obstacle = obstacle.global_position - boid.global_position
		var distance = to_obstacle.length()
		
		if distance < radius:
			avoidance_force -= to_obstacle.normalized() * (radius - distance)
	
	return avoidance_force.normalized() * boid.move_speed if avoidance_force != Vector3.ZERO else Vector3.ZERO
