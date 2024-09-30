extends Area3D

var velocity: Vector3
var damage: float
var lifetime: float = 5.0  # Default lifetime of 5 seconds
var time_alive: float = 0.0

func _ready():
    # Set the bullet's orientation based on its initial velocity
    if velocity != Vector3.ZERO:
        look_at(global_position + velocity, Vector3.UP)

func _physics_process(delta):
    global_translate(velocity * delta)
    time_alive += delta
    if time_alive >= lifetime:
        queue_free()
    
    var overlapping_bodies = get_overlapping_bodies()
    for body in overlapping_bodies:
        if body.has_method("hit"):
            body.hit(-velocity.normalized(), damage, velocity.length())
            queue_free()
            break

func _on_area_entered(area):
    if area.get_parent().has_method("hit"):
        area.get_parent().hit(-velocity.normalized(), damage, velocity.length())
    queue_free()

func set_damage(value: float):
    damage = value

func set_lifetime(value: float):
    lifetime = value
