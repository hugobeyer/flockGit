extends RigidBody3D

@export var bullet_speed: float = 50.0  # Speed of the bullet
@export var bullet_damage: float = 10.0  # Damage dealt by the bullet
@export var lifetime: float = 1.0  # Time in seconds before the bullet is destroyed
# Initialize bullet properties dynamically from the gun
func initialize_bullet(direction: Vector3, speed: float, damage: float, lifetime_duration: float) -> void:
	linear_velocity = direction.normalized() * speed  # Set the bullet velocity based on direction and speed
	bullet_damage = damage  # Set the damage of the bullet
	lifetime = lifetime_duration  # Set the lifetime of the bullet
	set_process(true)  # Start the process function to handle lifetime

# Called when the bullet collides with another body
func _on_bullet_body_entered(body: Node):
	if body.is_in_group("enemies"):
		if body.has_method("on_bullet_hit"):
			var bullet_direction = (body.global_transform.origin - global_transform.origin).normalized()
			body.on_bullet_hit(bullet_damage, bullet_direction)  # Apply damage to enemy
		queue_free()  # Destroy the bullet on collision

# Handle bullet's lifetime
func _process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0:
		queue_free()  # Destroy the bullet when its lifetime is over

# Ensure to connect the signal
func _ready():
	connect("body_entered", Callable(self, "_on_bullet_body_entered"))
