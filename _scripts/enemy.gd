@tool
extends CharacterBody3D

@export var enemy_type: EnemyType:
    set(value):
        enemy_type = value
        update_properties()
        notify_property_list_changed()

# Export Groups
@export_group("General Enemy Parameters")
@export var max_health: float = 100.0
@export var movement_speed: float = 5.0
@export var knockback_resistance: float = 2.0
@export var turn_speed: float = 4.0
@export var detection_range: float = 36.0
@export var damage: float = 10.0
@export var use_shield: bool = false
@export var use_melee: bool = false

@export_group("Flocking Parameters")
@export var flock_separation_weight: float = 3.0
@export var flock_alignment_weight: float = 2.0
@export var flock_cohesion_weight: float = 2.0
@export var flock_neighbor_distance: float = 3.0
@export var max_flock_neighbors: int = 5
@export var flock_weight_change_rate: float = 0.1
@export var max_flock_weight_multiplier: float = 2.0

@export_group("Death Effect Parameters")
@export var death_effect_scene: PackedScene
@export var death_effect_duration: float = 2.0

@export_group("Berserk Parameters")
@export var berserk_chance: float = 0.01
@export var berserk_speed_multiplier: float = 2.0
@export var berserk_duration: float = 5.0

@export_group("Wander Parameters")
@export var wander_radius: float = 10.0
@export var wander_interval: float = 3.0

@export_group("Wobble Effect Parameters")
@export var wobble_strength: float = 1.0
@export var wobble_decay: float = 5.0
@export_range(0, 1) var wobble_damping: float = 0.98

# Onready Variables
@onready var shield: EnemyShield = $EnemyShield if has_node("EnemyShield") else null
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var effects: EnemyEffects = $EnemyEffects
@onready var health_bar: Sprite3D = $HealthBar
@onready var melee_weapon = $MeleeWeapon if has_node("MeleeWeapon") else null

# State Variables (hidden from Inspector)
var _health: float
var _is_berserk: bool = false
var _time_alive: float = 0
var _wander_time: float = 0
var _wander_direction: Vector3 = Vector3.ZERO

# Physics Variables (hidden from Inspector)
var _knockback_velocity: Vector3 = Vector3.ZERO
var _wobble_velocity: Vector3 = Vector3.ZERO

# Reference Variables (hidden from Inspector)
var _player: Node3D = null
var _formation_manager: Node3D
var _ai_director: Node
var _spawner: Node

# Transform Variables (hidden from Inspector)
var _initial_mesh_transform: Transform3D

# Signals
signal enemy_killed(enemy)

var _formation_target: Vector3

func initialize(params: Dictionary):
    var enemy_params = params.get("enemy_params", {})
    var flocking_params = params.get("flocking_params", {})
    _ai_director = params.get("ai_director")
    _spawner = params.get("spawner")

    max_health = enemy_params.get("health", max_health)
    _health = max_health
    movement_speed = enemy_params.get("speed", movement_speed)
    damage = enemy_params.get("damage", damage)
    use_shield = enemy_params.get("use_shield", use_shield)
    use_melee = enemy_params.get("use_melee", use_melee)
    
    flock_separation_weight = flocking_params.get("separation_weight", flock_separation_weight)
    flock_alignment_weight = flocking_params.get("alignment_weight", flock_alignment_weight)
    flock_cohesion_weight = flocking_params.get("cohesion_weight", flock_cohesion_weight)
    
    # Initialize other properties as needed

func _ready():
    if not Engine.is_editor_hint():
        setup_nodes()
        update_health_bar()
        add_to_group("enemies")

func _get_property_list():
    var properties = []
    
    if enemy_type:
        # If enemy_type is set, hide default export variables
        properties.append({
            "name": "enemy_type",
            "type": TYPE_OBJECT,
            "usage": PROPERTY_USAGE_DEFAULT | PROPERTY_USAGE_SCRIPT_VARIABLE,
            "hint": PROPERTY_HINT_RESOURCE_TYPE,
            "hint_string": "EnemyType"
        })
    else:
        # If no enemy_type is set, show all default export variables
        properties = []
    
    return properties

func update_properties():
    if enemy_type:
        for property in enemy_type.get_property_list():
            if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
                set(property.name, enemy_type.get(property.name))

func get_property(key: String):
    if enemy_type:
        return enemy_type.get(key)
    return get(key)

func setup_nodes():
    if get_property("use_shield"):
        setup_shield()
    if get_property("use_melee"):
        setup_melee_weapon()
    
    _player = get_tree().current_scene.get_node("Main/Player")
    if not _player:
        push_error("Player node not found!")
    
    # Store the initial transform of the mesh
    _initial_mesh_transform = mesh_instance.transform

    _formation_manager = get_parent().get_node("FormationManager")
    if _formation_manager:
        _formation_manager.add_enemy(self)

func setup_shield():
    if not enemy_type:
        return

    if enemy_type.use_shield:
        if shield:
            shield.visible = true
            shield.connect("shield_depleted", Callable(self, "_on_shield_depleted"))
        else:
            push_warning("Shield node not found for enemy that should have a shield: ", name)
    else:
        if shield:
            shield.visible = false

func setup_melee_weapon():
    if not enemy_type:
        return

    if enemy_type.use_melee:
        if melee_weapon:
            melee_weapon.set_process(true)
        else:
            push_warning("Melee weapon node not found for enemy that should have a melee weapon: ", name)
    else:
        if melee_weapon:
            melee_weapon.set_process(false)

func hit(direction: Vector3, hit_damage: float, impulse: float):
    var remaining_damage = hit_damage

    if use_shield and shield and shield.get_shield_strength() > 0:
        remaining_damage = shield.take_damage(hit_damage)
        
        if shield.has_method("apply_shield_effect"):
            shield.apply_shield_effect(direction * hit_damage)
        
        if shield.get_shield_strength() <= 0:
            _on_shield_depleted()
    else:
        shield = null  # Ensure shield is set to null if depleted

    if remaining_damage > 0:
        _health -= remaining_damage
        update_health_bar()
        if _health <= 0:
            die()
        else:
            apply_hit_wobble(direction * impulse)
            if effects:
                effects.apply_damage_effect(direction)

    var health_percentage = _health / get_property("max_health")
    set_property("flock_cohesion_weight", lerp(get_property("flock_cohesion_weight") * 2, get_property("flock_cohesion_weight") * 0.5, health_percentage))
    set_property("flock_separation_weight", lerp(get_property("flock_separation_weight") * 0.5, get_property("flock_separation_weight") * 2, health_percentage))

func update_health_bar():
    if health_bar:
        var health_percent = _health / max_health
        var shielded = is_instance_valid(shield) and shield.get_shield_strength() > 0
        health_bar.set_progress(health_percent, shielded)
        # Show the health bar only when necessary
        health_bar.visible = health_percent < 1.0 or shielded
    else:
        push_warning("Health bar is null or not assigned.")

func _process(delta):
    _time_alive += delta
    var weight_multiplier = min(1 + _time_alive * flock_weight_change_rate, max_flock_weight_multiplier)
    flock_alignment_weight = flock_alignment_weight * weight_multiplier
    flock_cohesion_weight = flock_cohesion_weight * weight_multiplier
    if _player and global_position.distance_to(_player.global_position) <= detection_range:
        orient_to_movement(delta)
    # Make the health bar face the camera/player
    if health_bar and _player:
        health_bar.look_at(_player.global_position, Vector3.UP)
    if not _is_berserk and randf() < berserk_chance * delta:
        enter_berserk_mode()

func orient_to_movement(delta):
    var move_direction = velocity.normalized()
    if move_direction.length() > 0.1:
        var target_transform = transform.looking_at(global_position + move_direction, Vector3.UP)
        global_transform = global_transform.interpolate_with(target_transform, turn_speed * delta)

func _physics_process(delta):
    if _player:
        var distance_to_player = global_position.distance_to(_player.global_position)
        if distance_to_player <= detection_range:
            move_towards_player(delta)
        else:
            wander(delta)
    apply_knockback(delta)
    move_and_slide()

    # Apply wobble effect
    apply_wobble(delta)

    # Add formation influence
    if _formation_target:
        var to_formation = (_formation_target - global_position).normalized()
        velocity += to_formation * movement_speed * 0.5 * delta

func wander(delta):
    _wander_time += delta
    if _wander_time >= wander_interval:
        _wander_time = 0
        _wander_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
    
    var wander_target = global_position + _wander_direction * wander_radius
    var direction = (wander_target - global_position).normalized()
    velocity = direction * movement_speed * 0.5  # Move slower while wandering
    
    orient_to_movement(delta)

func move_towards_player(delta):
    var distance_to_player = global_position.distance_to(_player.global_position)
    var aggression_factor = 1.0 - (distance_to_player / detection_range)
    var current_speed = lerp(movement_speed * 0.5, movement_speed * 1.5, aggression_factor)
    
    var player_pos = _player.global_position
    var direction_to_player = (player_pos - global_position)
    direction_to_player.y = 0  # Ignore vertical difference
    direction_to_player = direction_to_player.normalized()

    var flocking_force = calculate_flocking_force()
    flocking_force.y = 0

    var formation_offset = get_formation_offset()
    var desired_direction = (direction_to_player + flocking_force + formation_offset).normalized()
    var desired_velocity = desired_direction * current_speed

    velocity = velocity.lerp(desired_velocity, delta * 5.0)
    orient_to_movement(delta)

func get_formation_offset() -> Vector3:
    if _formation_manager:
        return _formation_manager.get_formation_offset(self)
    return Vector3.ZERO

func apply_knockback(delta):
    velocity += _knockback_velocity
    _knockback_velocity = _knockback_velocity.lerp(Vector3.ZERO, delta * 5)  # Gradually reduce knockback

func die():
    SignalBus.emit_signal("enemy_killed")
    emit_signal("enemy_killed", self)
    
    # Instantiate death effect
    if death_effect_scene:
        var death_effect = death_effect_scene.instantiate()
        get_parent().add_child(death_effect)
        death_effect.global_position = global_position
        
        # Ensure the particle system starts emitting
        if death_effect is GPUParticles3D:
            death_effect.emitting = true
        
        # Set up a timer to remove the effect after the specified duration
        var timer = get_tree().create_timer(death_effect_duration)
        timer.connect("timeout", Callable(death_effect, "queue_free"))
    
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
        separation_force += (global_position - neighbor.global_position) / distance
        # Alignment: match velocity with nearby enemies
        alignment_force += neighbor.velocity
        # Cohesion: move towards the average position of nearby enemies
        cohesion_force += neighbor.global_position
        neighbor_count += 1

    if neighbor_count > 0:
        # Average the forces
        separation_force = (separation_force / neighbor_count) * flock_separation_weight
        alignment_force = ((alignment_force / neighbor_count) - velocity) * flock_alignment_weight
        cohesion_force = ((cohesion_force / neighbor_count) - global_position) * flock_cohesion_weight

    # Combine and normalize the flocking forces
    var flocking_force = (separation_force + alignment_force + cohesion_force).normalized() * 4.0  # Adjust the strength as needed

    return flocking_force

func set_physics_enabled(enabled: bool):
    set_physics_process(enabled)
    # Do NOT disable the collider here
    # $CollisionShape3D.disabled = !enabled  # Remove this line if it exists

func enter_berserk_mode():
    _is_berserk = true
    movement_speed *= berserk_speed_multiplier
    flock_separation_weight *= 0.5  # Reduce separation to make them cluster more
    mesh.set_instance_shader_parameter("lerp_wave", 0.5)  # Visual indicator
    mesh.set_instance_shader_parameter("lerp_color", Color(1.5, 0.1, 0.1, 1.0))  # Visual indicator

    await get_tree().create_timer(berserk_duration).timeout
    exit_berserk_mode()

func exit_berserk_mode():
    var default_hit_color = mesh.get_instance_shader_parameter("lerp_color")  # Visual indicator
    _is_berserk = false
    movement_speed /= berserk_speed_multiplier
    flock_separation_weight *= 2  # Restore original separation
    mesh.set_instance_shader_parameter("lerp_wave", 0.0)  # Restore original color
    mesh.set_instance_shader_parameter("lerp_color", default_hit_color)  # Restore original color

func _exit_tree():
    if _formation_manager:
        _formation_manager.remove_enemy(self)

func apply_hit_wobble(force: Vector3):
    _wobble_velocity += force * wobble_strength

func apply_wobble(delta):
    # Calculate wobble rotation
    var wobble_rotation = Quaternion(Vector3(1, 0, 0), _wobble_velocity.z * delta) * Quaternion(Vector3(0, 0, 1), -_wobble_velocity.x * delta)
    
    # Apply wobble to mesh transform
    mesh_instance.transform = _initial_mesh_transform * Transform3D(wobble_rotation)

    # Decay wobble
    _wobble_velocity = _wobble_velocity.lerp(Vector3.ZERO, wobble_decay * delta)
    _wobble_velocity *= wobble_damping  # Additional damping

func set_property(key: String, value):
    if enemy_type:
        enemy_type.set(key, value)
    else:
        set(key, value)