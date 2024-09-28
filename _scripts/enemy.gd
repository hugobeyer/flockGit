class_name Enemy
extends CharacterBody3D

@export var speed: float = 5.0
@export var turn_speed: float = 2.0
@export var separation_weight: float = 1.5
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0
@export var player_attraction_weight: float = 1.2
@export var neighbor_radius: float = 5.0

var player: Node3D
var flock: Array = []
var nav_agent: NavigationAgent3D

func _ready():
	nav_agent = NavigationAgent3D.new()
	add_child(nav_agent)
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5

func _physics_process(delta):
	if is_instance_valid(player):
		nav_agent.set_target_position(player.global_position)
	
	var next_path_position: Vector3 = nav_agent.get_next_path_position()
	var current_position: Vector3 = global_position
	
	var movement_vector: Vector3 = (next_path_position - current_position).normalized()
	
	var separation = get_separation()
	var alignment = get_alignment()
	var cohesion = get_cohesion()
	
	var flocking_vector = (separation * separation_weight + 
						   alignment * alignment_weight + 
						   cohesion * cohesion_weight).normalized()
	
	var desired_velocity = (movement_vector * player_attraction_weight + flocking_vector).normalized() * speed
	
	velocity = velocity.lerp(desired_velocity, turn_speed * delta)
	
	move_and_slide()
	
	if velocity.length() > 0.1:
		look_at(global_position + velocity, Vector3.UP)

func get_separation() -> Vector3:
	var separation = Vector3.ZERO
	var neighbors = 0
	for enemy in flock:
		if enemy != self and is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < neighbor_radius:
				separation += (global_position - enemy.global_position).normalized() / distance
				neighbors += 1
	return separation / neighbors if neighbors > 0 else Vector3.ZERO

func get_alignment() -> Vector3:
	var alignment = Vector3.ZERO
	var neighbors = 0
	for enemy in flock:
		if enemy != self and is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < neighbor_radius:
				alignment += enemy.velocity
				neighbors += 1
	return (alignment / neighbors).normalized() if neighbors > 0 else Vector3.ZERO

func get_cohesion() -> Vector3:
	var center = Vector3.ZERO
	var neighbors = 0
	for enemy in flock:
		if enemy != self and is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < neighbor_radius:
				center += enemy.global_position
				neighbors += 1
	return ((center / neighbors) - global_position).normalized() if neighbors > 0 else Vector3.ZERO
