class_name Enemy
extends CharacterBody3D

var initial_position: Vector3
var direction: Vector3

@export var move_speed: float = 5.0
@export var max_force: float = 0.5
@export var use_dash: bool = true
@export var health: float = 100.0
@export var max_health: float = 100.0

# Flocking parameters
@export var separation_weight: float = 1.5
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0
@export var flocking_radius: float = 5.0

# Melee attack parameters
@export var melee_damage: float = 10.0
@export var melee_cooldown: float = 1.0

@onready var dash_behavior: EnemyDash = $EnemyDash if has_node("EnemyDash") else null
@onready var shield = $EnemyShield if has_node("EnemyShield") else null
@onready var melee_hitbox: Area3D = $MeleeWeapon/SwordArea
@onready var melee_animation: AnimationPlayer = $MeleeWeapon/AnimationPlayer
@onready var effects: Node3D = $EnemyEffects
@onready var player_target: CharacterBody3D = get_node("/root/Main/Player")

var steering: Vector3 = Vector3.ZERO
var last_melee_time: float = 0.0

func _ready():
	initial_position = global_position
	if not dash_behavior:
		push_error("EnemyDash node not found")
	if not shield:
		push_warning("EnemyShield node not found on " + name)
	if not melee_hitbox:
		push_error("MeleeHitbox node not found")
	if not effects:
		push_error("Effects node not found")
	
	if dash_behavior:
		dash_behavior.connect("dash_completed", Callable(self, "_on_dash_completed"))
	if shield:
		shield.connect("shield_depleted", Callable(self, "_on_shield_depleted"))
		shield.connect("shield_recharged", Callable(self, "_on_shield_recharged"))
	
	if use_dash:
		start_new_dash()

func _physics_process(delta: float):
	if dash_behavior and dash_behavior.is_dashing:
		velocity = dash_behavior.process(delta, global_position)
	else:
		apply_flocking_behavior(delta)
	
	move_and_slide()
	
	if velocity.length() > 0.1:
		look_at(global_position + velocity, Vector3.UP)
	
	attempt_melee_attack()

func apply_flocking_behavior(delta: float):
	var separation = get_separation_force()
	var alignment = get_alignment_force()
	var cohesion = get_cohesion_force()
	var pursuit = get_pursuit_force()
	
	steering = (separation * separation_weight +
				alignment * alignment_weight +
				cohesion * cohesion_weight +
				pursuit)
	
	steering = steering.limit_length(max_force)
	velocity += steering
	velocity = velocity.limit_length(move_speed)

# ... (keep the flocking-related functions: get_separation_force, get_alignment_force, get_cohesion_force, get_pursuit_force, get_neighbors)

func start_new_dash():
	if not use_dash or not dash_behavior:
		return
	
	if player_target:
		var direction_to_player = (player_target.global_position - global_position).normalized()
		dash_behavior.start_dash(global_position, direction_to_player)
	else:
		var random_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
		dash_behavior.start_dash(global_position, random_direction)

func _on_dash_completed():
	if use_dash:
		await get_tree().create_timer(randf_range(1.0, 3.0)).timeout
		start_new_dash()

func toggle_dash(enable: bool):
	use_dash = enable
	if use_dash:
		start_new_dash()
	elif dash_behavior:
		dash_behavior.stop_dash()

func take_damage(damage: float):
	if shield:
		var remaining_damage = shield.take_damage(damage)
		if remaining_damage > 0:
			apply_health_damage(remaining_damage)
	else:
		apply_health_damage(damage)
	
	if effects:
		effects.play("hit")

func apply_health_damage(damage: float):
	health -= damage
	health = max(health, 0)
	if health <= 0:
		die()

func die():
	if effects:
		effects.play("death")
	# Wait for death animation to finish
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_shield_depleted():
	if effects:
		effects.play("shield_break")

func _on_shield_recharged():
	if effects:
		effects.play("shield_recharge")

func attempt_melee_attack():
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_melee_time >= melee_cooldown:
		if melee_hitbox and melee_animation:  # Ensure melee_hitbox and melee_animation are valid
			melee_animation.play("swing_animation")  # Play the swing animation
			var targets = melee_hitbox.get_overlapping_bodies()
			for target in targets:
				if target.has_method("take_damage"):
					target.take_damage(melee_damage)
					last_melee_time = current_time
					if effects:
						effects.play("melee_attack")
					break
		else:
			push_error("MeleeHitbox or AnimationPlayer node not found")

# ... (rest of the existing code)

# Add this function
func get_cohesion_force():
	# Implement cohesion logic here
	return Vector3.ZERO  # Placeholder return, replace with actual implementation

func get_separation_force():
	# Implement separation logic
	return Vector3.ZERO  # Placeholder

func get_alignment_force():
	# Implement alignment logic
	return Vector3.ZERO  # Placeholder

func get_pursuit_force():
	# Implement pursuit logic
	return Vector3.ZERO  # Placeholder
