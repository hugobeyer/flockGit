extends CharacterBody3D

@export var max_health: float = 100.0
@export var movement_speed: float = 5.0
@export var knockback_resistance: float = 0.5

var health: float
var knockback_velocity: Vector3 = Vector3.ZERO

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var effects: EnemyEffects = $EnemyEffects

func _ready():
    health = max_health

func hit(direction: Vector3, damage: float, knockback: float):
    health -= damage
    if health <= 0:
        die()
    else:
        knockback_velocity = direction * knockback * (1 - knockback_resistance)
        if effects:
            effects.apply_damage_effect(direction)

func _physics_process(delta):
    move_towards_player(delta)
    apply_knockback(delta)

func move_towards_player(delta):
    var player = get_tree().get_nodes_in_group("player")
    if player.size() > 0:
        var direction = (player[0].global_position - global_position).normalized()
        direction.y = 0
        velocity = direction * movement_speed

func apply_knockback(delta):
    velocity += knockback_velocity
    knockback_velocity = knockback_velocity.lerp(Vector3.ZERO, delta * 5)
    move_and_slide()

func die():
    queue_free()