extends Node3D

@export var separation_weight: float = 15.275
@export var alignment_weight: float = 32.25
@export var cohesion_weight: float = 0.26
@export var separation_radius: float = 3
@export var alignment_radius: float = 3.0
@export var cohesion_radius: float = 3.0
@export var obstacle_avoidance_radius: float = 4.0
@export var pursuit_radius: float = 32.0
var velocity: Vector3 = Vector3.ZERO

func calculate_separation(entity: Node3D, neighbors: Array) -> Vector3:
	var separation_force = Vector3.ZERO
	for neighbor in neighbors:
		var distance = entity.global_transform.origin.distance_to(neighbor.global_transform.origin)
		if distance > 0 and distance < separation_radius:
			var push_direction = (entity.global_transform.origin - neighbor.global_transform.origin).normalized()
			separation_force += push_direction / distance
	return separation_force.normalized()

func calculate_alignment(_entity: Node3D, neighbors: Array) -> Vector3:
	var avg_direction = Vector3.ZERO
	for neighbor in neighbors:
		avg_direction += neighbor.transform.basis.z  # Assume Z axis is forward
	if neighbors.size() > 0:
		avg_direction /= neighbors.size()
	return avg_direction.normalized()

func calculate_cohesion(_entity: Node3D, neighbors: Array) -> Vector3:
	var avg_position = Vector3.ZERO
	for neighbor in neighbors:
		avg_position += neighbor.global_transform.origin
	if neighbors.size() > 0:
		avg_position /= neighbors.size()
	return (avg_position - _entity.global_transform.origin).normalized()

func avoid_obstacles(_entity: Node3D) -> Vector3:
	var obstacle_avoidance = Vector3.ZERO
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()

	query.from = _entity.global_transform.origin
	query.to = _entity.global_transform.origin + _entity.velocity * obstacle_avoidance_radius  # Project forward
	query.collide_with_bodies = true

	var result = space_state.intersect_ray(query)
	if result:
		var hit_point = result.position
		var avoidance_direction = (_entity.global_transform.origin - hit_point).normalized()
		obstacle_avoidance = avoidance_direction

	return obstacle_avoidance
