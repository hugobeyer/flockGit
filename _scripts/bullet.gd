extends Area3D

@export var speed: float = 30.0
@export var lifetime: float = 5.0
@export var damage: float = 10.0
@export var knockback_force: float = 10.0

var velocity: Vector3
var bullet_owner: Node3D = null
var lifetime_timer: Timer

func _ready():
    setup_lifetime_timer()

func setup_lifetime_timer():
    lifetime_timer = Timer.new()
    lifetime_timer.wait_time = lifetime
    lifetime_timer.one_shot = true
    lifetime_timer.connect("timeout", Callable(self, "_on_lifetime_timeout"))
    add_child(lifetime_timer)
    lifetime_timer.start()

func _physics_process(delta):
    translate(velocity * delta)

func set_bullet_owner(owner: Node3D):
    bullet_owner = owner

func _on_body_entered(body: Node):
    if body == bullet_owner:
        return
    if body.has_method("hit"):
        var knockback = -velocity.normalized() * knockback_force
        body.hit(knockback, damage)
    queue_free()

func _on_lifetime_timeout():
    queue_free()
