extends Node3D  # or CharacterBody3D for 3D games

@export var enemy_scene: PackedScene
@onready var enemy_instance: CharacterBody3D  # Ensure this is of type CharacterBody3D
@onready var callPlayer: CharacterBody3D  # Ensure this is of type CharacterBody3D
@export_node_path var playerPath: NodePath

# Remove or comment out this line
# var player

@export var separation_weight: float = 1.5
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0
@export var obstacle_avoidance_weight: float = 2.0
@export var separation_radius: float = 5.0
@export var alignment_radius: float = 10.0
@export var cohesion_radius: float = 15.0
@export var obstacle_avoidance_radius: float = 10.0
@export var max_speed: float = 10.0
@export var max_force: float = 1.0
@export var smoothing_factor: float = 0.1

var behaviors: Array = []

var custom_velocity: Vector3 = Vector3.ZERO
var steering: Vector3 = Vector3.ZERO

var spawn_radius = 10.0  # Adjust this value as needed

func _ready():
	get_scene_instance_load_placeholder()
	callPlayer = get_node("/root/Main/Player")
	playerPath = get_path()
	
	# Instantiate enemy_instance from enemy_scene
	if enemy_scene:
		enemy_instance = enemy_scene.instantiate() as CharacterBody3D
		add_child(enemy_instance)
	else:
		push_warning("Enemy scene not set! Some functionality may be limited.")
	
	behaviors = [
		SeparationBehavior.new(separation_radius),
		AlignmentBehavior.new(alignment_radius),
		CohesionBehavior.new(cohesion_radius),
		ObstacleAvoidanceBehavior.new(obstacle_avoidance_radius)
	]

func calculate_flocking_force(entity: CharacterBody3D, all_entities: Array) -> Vector3:  # Change Node3D to CharacterBody3D
	var force = Vector3.ZERO
	
	for i in range(behaviors.size()):
		var behavior_force = behaviors[i].calculate(entity, all_entities)
		var weight = [separation_weight, alignment_weight, cohesion_weight, obstacle_avoidance_weight][i]
		force += behavior_force * weight
	
	return force.limit_length(max_force)
# Implement obstacle avoidance behavior
class LocalObstacleAvoidanceBehavior:
	var radius: float
	
	func _init(r: float): radius = r
	
	func calculate(entity: Node3D, obstacles: Array) -> Vector3:
		var steering = Vector3.ZERO
		for obstacle in obstacles:
			var distance = entity.global_position.distance_to(obstacle.global_position)
			if distance < radius:
				var avoidance_force = entity.global_position - obstacle.global_position
				avoidance_force = avoidance_force.normalized() * (radius - distance)
				steering += avoidance_force
		return steering

class LocalSeparationBehavior:
	var radius: float
	func _init(r: float): radius = r
	func calculate(entity: Node3D, neighbors: Array) -> Vector3:
		var steering = Vector3.ZERO
		var count = 0
		for neighbor in neighbors:
			var distance = entity.global_position.distance_to(neighbor.global_position)
			if neighbor != entity and distance < radius:
				var diff = entity.global_position - neighbor.global_position
				diff = diff.normalized() / distance
				steering += diff
				count += 1
		if count > 0:
			steering /= count
		return steering

class LocalAlignmentBehavior:
	var radius: float
	func _init(r: float): radius = r
	func calculate(entity: Node3D, neighbors: Array) -> Vector3:
		var steering = Vector3.ZERO
		var count = 0
		for neighbor in neighbors:
			var distance = entity.global_position.distance_to(neighbor.global_position)
			if neighbor != entity and distance < radius:
				steering += neighbor.velocity
				count += 1
		if count > 0:
			steering /= count
			steering = steering.normalized() * entity.max_speed - entity.velocity
		return steering

class LocalCohesionBehavior:
	var radius: float
	func _init(r: float): radius = r
	func calculate(entity: Node3D, neighbors: Array) -> Vector3:
		var steering = Vector3.ZERO
		var count = 0
		for neighbor in neighbors:
			var distance = entity.global_position.distance_to(neighbor.global_position)
			if neighbor != entity and distance < radius:
				steering += neighbor.global_position
				count += 1
		if count > 0:
			steering /= count
			steering = (steering - entity.global_position).normalized() * entity.max_speed - entity.velocity
		return steering

#func spawn_enemy():
	#if not enemy_scene or not callPlayer:
		#return
	#
	#var enemy = enemy_scene.instantiate()
	#var random_angle = randf() * 2 * PI
	#var spawn_position = callPlayer.global_position + Vector3(
		#cos(random_angle) * spawn_radius,
		#0,  # Assuming you want to spawn at the same Y level as the player
		#sin(random_angle) * spawn_radius
	#)
	#enemy.global_position = spawn_position
	#add_child(enemy)

func _physics_process(delta: float):
	if enemy_instance:
		var velocity = enemy_instance.move_and_slide()


func apply_flocking_behavior(delta: float, enemy: CharacterBody3D):
	var separation = get_separation_force()
	var alignment = get_alignment_force()
	var cohesion = get_cohesion_force()
	var pursuit = get_pursuit_force()
	
	
	steering = (separation * separation_weight +
				alignment * alignment_weight +
				 cohesion * cohesion_weight +
				pursuit)
	
	var velocity = enemy.velocity
	velocity += steering * delta
	velocity = velocity.limit_length(max_speed)
	enemy.velocity = velocity

func get_separation_force() -> Vector3:
	var force = Vector3.ZERO
	# Implement separation logic using Vector3
	return force

func get_alignment_force() -> Vector3:
	var force = Vector3.ZERO
	# Implement alignment logic using Vector3
	return force

func get_cohesion_force() -> Vector3:
	var force = Vector3.ZERO
	# Implement cohesion logic using Vector3
	return force

func get_pursuit_force() -> Vector3:
	var force = Vector3.ZERO
	# Implement pursuit logic using Vector3
	return force

# Add a method to set the enemy scene and player externally
func setup(new_enemy_scene: PackedScene, new_player: CharacterBody3D):
	enemy_scene = new_enemy_scene
	callPlayer = new_player  # Ensure this is of type CharacterBody3D