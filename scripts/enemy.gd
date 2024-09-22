extends CharacterBody3D

@export var health: float = 100.0
@export var move_speed: float = 5.0
@export var separation_radius: float = 5.0
@export var alignment_radius: float = 10.0
@export var separation_weight: float = 1.5
@export var alignment_weight: float = 1.0
@export var player_target_weight: float = 2.0
@export var use_fov: bool = true
@export var fov_angle_radians: float = PI / 2.0  # 90 degrees in radians
@export var enemy_target: NodePath  # Path to the player

signal enemy_destroyed

var target_position: Vector3

func _ready():
	if has_node(enemy_target):
		target_position = get_node(enemy_target).global_transform.origin

func _process(_delta):
	if target_position != Vector3.ZERO:
		steer_toward_player_with_behaviors()

# Combine steer separation, steer alignment, and movement toward the player
func steer_toward_player_with_behaviors():
	var separation_force = Vector3.ZERO
	var alignment_force = Vector3.ZERO
	var total_neighbors = 0

	var neighbors = get_tree().get_nodes_in_group("enemies")

	for neighbor in neighbors:
		if neighbor == self:
			continue
		
		var distance = global_transform.origin.distance_to(neighbor.global_transform.origin)

		# Separation with falloff based on distance
		if distance < separation_radius:
			var falloff = (separation_radius - distance) / separation_radius
			var push_away_force = (global_transform.origin - neighbor.global_transform.origin).normalized() * falloff
			separation_force += push_away_force * separation_weight
			total_neighbors += 1

		# Alignment behavior
		if distance < alignment_radius:
			var neighbor_velocity = neighbor.velocity.normalized()
			var angle_to_neighbor = get_facing_angle(neighbor.global_transform.origin)

			if not use_fov or (use_fov and angle_to_neighbor <= fov_angle_radians / 2):
				alignment_force += neighbor_velocity * alignment_weight
				total_neighbors += 1

	if total_neighbors > 0:
		alignment_force /= total_neighbors

	var direction_to_player = (target_position - global_transform.origin).normalized()
	var steer_force = direction_to_player * player_target_weight

	var total_force = steer_force + separation_force + alignment_force
	velocity = total_force.normalized() * move_speed
	move_and_slide()

	if global_transform.origin.distance_to(target_position) <= 0.5:
		on_target_reached()

func get_facing_angle(target_pos: Vector3) -> float:
	var dir_to_target = (target_pos - global_transform.origin).normalized()
	var facing_dir = global_transform.basis.z.normalized()
	var dot_product = clamp(facing_dir.dot(dir_to_target), -1.0, 1.0)
	return acos(dot_product)

func on_bullet_hit(damage: float):
	health -= damage
	if health <= 0:
		emit_signal("enemy_destroyed", self)
		queue_free()

func on_target_reached():
	velocity = Vector3.ZERO
