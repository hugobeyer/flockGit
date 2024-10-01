extends CharacterBody3D

@export var max_health: float = 100.0
@export var movement_speed: float = 5.0
@export var knockback_resistance: float = 0.5
@export var knockback_force: float = 10.0
@export var turn_speed: float = 2.0  # Radians per second
@export var detection_range: float = 20.0  # How far the enemy can detect the player

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
    player = get_node("/root/Main/Player")
    if not player:
        push_error("Player node not found!")
    update_health_bar()
    await get_tree().create_timer(1.0).timeout

func hit(direction: Vector3, damage: float, impulse: float):
    print("Enemy hit! Damage: ", damage)
    var remaining_damage = damage
    if shield and shield.get_shield_strength() > 0:
        remaining_damage = shield.take_damage(damage)
        if shield.has_method("apply_shield_effect"):
            shield.apply_shield_effect(direction * damage)
        else:
            print("Warning: apply_shield_effect method not found in EnemyShield")
    
    if remaining_damage > 0:
        health -= remaining_damage
        update_health_bar()
        if health <= 0:
            die()
        else:
            knockback_velocity = -direction * impulse * (1/knockback_resistance)
            if effects:
                effects.apply_damage_effect(direction)

func update_health_bar():
    if health_bar:
        health_bar.progress = health / max_health

func _process(delta):
    if player and global_position.distance_to(player.global_position) <= detection_range:
        orient_to_player(delta)

func orient_to_player(delta):
    var direction = player.global_position - global_position
    direction.y = 0  # Ignore vertical difference
    
    if direction.length() > 0.1:  # Avoid jittering when very close
        var target_transform = transform.looking_at(player.global_position, Vector3.UP)
        global_transform = global_transform.interpolate_with(target_transform, turn_speed * delta)

func _physics_process(delta):
    move_towards_player(delta)
    apply_knockback(delta)
    move_and_slide()

func move_towards_player(delta):
    var player = get_tree().get_nodes_in_group("player")
    if player.size() > 0:
        var direction = (player[0].global_position - global_position).normalized()
        direction.y = 0
        velocity = direction * movement_speed

func apply_knockback(delta):
    velocity += knockback_velocity
    knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, delta * 5)  # Gradually reduce knockback

func die():
    print("Enemy died!")
    queue_free()

func _on_shield_depleted():
    if shield:
        print("Shield depleted!")
        shield.queue_free()
        shield = null
    update_health_bar()