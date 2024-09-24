extends Area3D

@export var damage: float = 7.0  # Damage dealt by the bullet
@export var speed: float = 64.0  # Speed of the bullet
@export var lifetime: float = 1.0  # Time in seconds before the bullet is destroyed
@export var fire_rate: float = 0.1  # Time in seconds before the bullet is destroyed


var velocity: Vector3 = Vector3.ZERO  # To store the bullet's initial velocity
var timer: float = 0.0  # Internal timer to track bullet lifetime

# Function to set the bullet properties dynamically from another script
func set_bullet_properties(new_damage: float, new_speed: float, direction: Vector3, new_fire_rate: float) -> void:
	damage = new_damage
	speed = new_speed
	velocity = direction.normalized() * speed  # Set the velocity based on the direction and speed
	fire_rate = new_fire_rate
	
	# Set the bullet's rotation to face the direction of travel
	look_at(global_transform.origin + velocity, Vector3.UP)

# This replaces connect(), using Godot 4's Callable system for signals
@onready var _body_entered_signal = Callable(self, "_on_body_entered")

# Called when the node enters the scene tree for the first time.
func _ready():
	set_as_top_level(true)  # Ensure the bullet doesn't inherit transformations from its parent
	body_entered.connect(_body_entered_signal)  # Directly connect the body_entered signal using Callable

# Function that runs when the bullet collides with another object
func _on_body_entered(body: Node):
	if body.is_in_group("enemies"):
		if body.has_method("on_bullet_hit"): 
			var bullet_direction = (body.global_transform.origin - global_transform.origin).normalized()
			body.on_bullet_hit(damage, bullet_direction)
			queue_free() 
			
func _process(delta):
	global_transform.origin += velocity * delta  # Move the bullet according to its velocity

	timer += delta
	if timer >= lifetime:
		queue_free()  # Destroy the bullet after its lifetime ends
