extends Area3D

@export var speed: float = 50.0  # Speed of the bullet
@export var damage: float = 10.0  # Damage dealt by the bullet
@export var lifetime: float = 1.5  # Lifetime of the bullet in seconds

var velocity: Vector3 = Vector3.ZERO  # Bullet velocity
var timer: float = 0.0  # Timer to track bullet lifetime

# Function to set bullet properties
func set_bullet_properties(new_damage: float, direction: Vector3, new_speed: float) -> void:
	damage = new_damage
	speed = new_speed
	velocity = direction.normalized() * speed  # Set velocity based on direction and speed

	# Rotate the bullet to face the direction of travel (Z+ axis)
	var bullet_direction = direction.normalized()
	look_at(global_transform.origin + bullet_direction, Vector3.UP)  # Rotate to face the correct direction

# Called when the node enters the scene tree for the first time
func _ready():
	set_as_top_level(true)  # Prevents bullet from inheriting parent transformations
	connect("body_entered", Callable(self, "_on_body_entered"))

# Function to handle body collisions
func _on_body_entered(body: Node):
	if body.is_in_group("enemies"):  # Ensure we only damage enemies
		if body.has_method("on_bullet_hit"):  # Ensure enemy can handle bullet damage
			var bullet_direction = (body.global_transform.origin - global_transform.origin).normalized()
			body.on_bullet_hit(damage, bullet_direction)  # Call enemy hit logic
		queue_free()  # Destroy bullet after hit

# Handle bullet movement and lifetime
func _process(delta):
	global_transform.origin += velocity * delta  # Move the bullet according to its velocity
	timer += delta
	if timer >= lifetime:
		queue_free()  # Destroy bullet after its lifetime expires
