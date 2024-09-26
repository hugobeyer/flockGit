extends Node3D

@export var separation_weight: float = 1.5
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0
@export var obstacle_avoidance_weight: float = 2.0
@export var separation_radius: float = 5.0
@export var alignment_radius: float = 10.0
@export var cohesion_radius: float = 15.0
@export var obstacle_avoidance_radius: float = 10.0
@export var max_speed: float = 10.0
@export var max_force: float = 25.0
@export var smoothing_factor: float = 0.1

var behaviors: Array = []

func _ready():
	behaviors = [
		SeparationBehavior.new(separation_radius),
		AlignmentBehavior.new(alignment_radius),
		CohesionBehavior.new(cohesion_radius),
		ObstacleAvoidanceBehavior.new(obstacle_avoidance_radius)
	]

func calculate_flocking_force(entity: Node3D, all_entities: Array) -> Vector3:
	var force = Vector3.ZERO
	
	for i in range(behaviors.size()):
		var behavior_force = behaviors[i].calculate(entity, all_entities)
		var weight = [separation_weight, alignment_weight, cohesion_weight, obstacle_avoidance_weight][i]
		force += behavior_force * weight
	
	return force.limit_length(max_force)

# You may need to implement these behavior classes or adjust based on your existing implementation
class LocalObstacleAvoidanceBehavior:
	var radius: float
	func _init(r: float): radius = r

class LocalSeparationBehavior:
	var radius: float
	func _init(r: float): radius = r

class LocalAlignmentBehavior:
	var radius: float
	var max_speed: float
	func _init(r: float, ms: float):
		radius = r
		max_speed = ms

class LocalCohesionBehavior:
	var radius: float
	var max_speed: float
	func _init(r: float, ms: float):
		radius = r
		max_speed = ms

class LocalFlockingBehavior:
	var separation: LocalSeparationBehavior
	var alignment: LocalAlignmentBehavior
	var cohesion: LocalCohesionBehavior
	var obstacle_avoidance: LocalObstacleAvoidanceBehavior

	func _init(sep: LocalSeparationBehavior, ali: LocalAlignmentBehavior, coh: LocalCohesionBehavior, obs: LocalObstacleAvoidanceBehavior):
		separation = sep
		alignment = ali
		cohesion = coh
		obstacle_avoidance = obs
