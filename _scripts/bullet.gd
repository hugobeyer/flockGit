extends Area3D

@export var velocity: Vector3 = Vector3.ZERO
@export var damage: float = 0.01
@export var lifetime: float = 1.0
@export var knockback: float = 1.0

var bullet_owner: Node3D = null
var time_alive: float = 0.0

func _ready():
    connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta: float) -> void:
    global_translate(velocity * delta)
    time_alive += delta
    if time_alive >= lifetime:
        queue_free()
    
    var overlapping_bodies = get_overlapping_bodies()
    for body in overlapping_bodies:
        if body == bullet_owner:
            continue
        if body.has_method("hit"):
            body.hit(-velocity.normalized(), damage, velocity.length())
            queue_free()
            break

func _on_body_entered(body: Node3D) -> void:
    if body == bullet_owner:
        return
    if body.has_method("hit"):
        body.hit(-velocity.normalized(), damage, velocity.length())
    queue_free()

func set_velocity(new_velocity: Vector3) -> void:
    velocity = new_velocity

func set_damage(value: float):
    damage = value

func set_lifetime(value: float):
    lifetime = value

func set_knockback(value: float):
    knockback = value

func set_bullet_owner(new_owner: Node3D):
    bullet_owner = new_owner
