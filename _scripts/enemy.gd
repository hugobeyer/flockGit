extends CharacterBody3D

# General Enemy Parameters
@export_group("General Enemy Parameters")
@export var max_health: float = 100.0
@export var movement_speed: float = 5.0
@export var knockback_resistance: float = 2.0
@export var turn_speed: float = 4.0  # Radians per second
@export var detection_range: float = 20.0  # How far the enemy can detect the player

# Flocking Parameters
@export_group("Flocking Parameters")
@export var flock_separation_weight: float = 3.0
@export var flock_alignment_weight: float = 2.0
@export var flock_cohesion_weight: float = 2.0
@export var flock_neighbor_distance: float = 3.0
@export var max_flock_neighbors: int = 5  # Maximum number of neighbors to consider

# Other variables and nodes
@onready var shield: EnemyShield = $EnemyShield
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var effects: EnemyEffects = $EnemyEffects
@onready var health_bar: Sprite3D = $HealthBar

var health: float = 100.0
var knockback_velocity: Vector3 = Vector3.ZERO
var player: Node3D = null

func _ready():
    health = max_health
    if shield:
        shield.connect("shield_depleted", Callable(self, "_on_shield_depleted"))
    else:
        # Log a warning if shield is not found
        push_warning("Shield node not found!")
    player = get_tree().current_scene.get_node("Player")
    if not player:
        push_error("Player node not found!")
    update_health_bar()
    add_to_group("enemies")  # Add this enemy to the 'enemies' group

func hit(direction: Vector3, damage: float, impulse: float):
    var remaining_damage = damage

    if is_instance_valid(shield) and shield.get_shield_strength() > 0:
        remaining_damage = shield.take_damage(damage)
        
        if is_instance_valid(shield) and shield.has_method("apply_shield_effect"):
            shield.apply_shield_effect(direction * damage)
        
        if is_instance_valid(shield) and shield.get_shield_strength() <= 0:
            _on_shield_depleted()
    else:
        shield = null  # Ensure shield is set to null if depleted

    if remaining_damage > 0:
        health -= remaining_damage
        update_health_bar()
        if health <= 0:
            die()
        else:
            knockback_velocity = -direction * impulse * (1 / knockback_resistance)
            if effects:
                effects.apply_damage_effect(direction)

func update_health_bar():
    if health_bar:
        var health_percent = health / max_health
        var shielded = is_instance_valid(shield) and shield.get_shield_strength() > 0
        health_bar.set_progress(health_percent, shielded)
        # Show the health bar only when necessary
        health_bar.visible = health_percent < 1.0 or shielded
    else:
        push_warning("Health bar is null or not assigned.")

func _process(delta):
    if player and global_position.distance_to(player.global_position) <= detection_range:
        orient_to_movement(delta)
    # Make the health bar face the camera/player
    if health_bar and player:
        health_bar.look_at(player.global_position, Vector3.UP)

func orient_to_movement(delta):
    var move_direction = velocity.normalized()
    if move_direction.length() > 0.1:
        var target_transform = transform.looking_at(global_position + move_direction, Vector3.UP)
        global_transform = global_transform.interpolate_with(target_transform, turn_speed * delta)

func _physics_process(delta):
    move_towards_player(delta)
    apply_knockback(delta)
    move_and_slide()

func move_towards_player(delta):
    if player:
        var player_pos = player.global_position
        var direction_to_player = (player_pos - global_position)
        direction_to_player.y = 0  # Ignore vertical difference
        direction_to_player = direction_to_player.normalized()

        var flocking_force = calculate_flocking_force()
        flocking_force.y = 0

        var desired_direction = (direction_to_player + flocking_force).normalized()
        var desired_velocity = desired_direction * movement_speed

        # Smoothly interpolate velocity towards desired_velocity
        velocity = velocity.lerp(desired_velocity, delta * 5.0)
    else:
        # If player is null, stop moving
        velocity = velocity.lerp(Vector3.ZERO, delta * 5.0)

func apply_knockback(delta):
    velocity += knockback_velocity
    knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, delta * 5)  # Gradually reduce knockback

func die():
    queue_free()

func _on_shield_depleted():
    if is_instance_valid(shield):
        shield.queue_free()
        shield = null
    update_health_bar()

func calculate_flocking_force():
    var separation_force = Vector3.ZERO
    var alignment_force = Vector3.ZERO
    var cohesion_force = Vector3.ZERO
    var neighbor_count = 0

    var neighbors = []
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        if enemy == self:
            continue
        var offset = enemy.global_position - global_position
        var distance = offset.length()
        if distance < flock_neighbor_distance and distance > 0:
            neighbors.append([distance, enemy])  # Store as [distance, enemy]

    # Sort neighbors by distance
    neighbors.sort()

    # Limit the number of neighbors to max_flock_neighbors
    var max_neighbors = min(max_flock_neighbors, neighbors.size())
    for i in range(max_neighbors):
        var neighbor_info = neighbors[i]
        var distance = neighbor_info[0]
        var neighbor = neighbor_info[1]
        var offset = neighbor.global_position - global_position

        # Separation: steer away from nearby enemies
        separation_force += (global_position - neighbor.global_position).normalized() / distance
        # Alignment: match velocity with nearby enemies
        alignment_force += neighbor.velocity
        # Cohesion: move towards the average position of nearby enemies
        cohesion_force += neighbor.global_position
        neighbor_count += 1

    if neighbor_count > 0:
        # Average the forces
        separation_force = (separation_force / neighbor_count) * flock_separation_weight
        alignment_force = ((alignment_force / neighbor_count).normalized() - velocity.normalized()) * flock_alignment_weight
        cohesion_force = ((cohesion_force / neighbor_count) - global_position).normalized() * flock_cohesion_weight

    # Combine and normalize the flocking forces
    var flocking_force = (separation_force + alignment_force + cohesion_force).normalized() * 0.5  # Adjust the strength as needed

    return flocking_force
