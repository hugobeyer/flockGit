extends Node3D

@export var bullet_speed: float = 50.0
@export var bullet_damage: float = 10.0
@export var bullet_lifetime: float = 5.0

func _ready():
	# Start a timer to destroy the bullet after its lifetime expires
	var timer = Timer.new()
	timer.one_shot = true
	timer.wait_time = bullet_lifetime
	timer.connect("timeout", Callable(self, "queue_free"))  # Using Callable correctly
	add_child(timer)
	timer.start()

	# Connect the "body_entered" signal to the Area3D
	$Area3D.connect("body_entered", Callable(self, "_on_body_entered"))  # Correct Callable usage

func _process(delta):
	# Move the bullet forward along the Z axis
	translate(Vector3(0, 0, bullet_speed * delta))

# Called when the bullet collides with a body (e.g., an enemy)
func _on_body_entered(body):
	if body.is_in_group("enemies"):
		body.on_bullet_hit(bullet_damage)  # Call the enemy's hit function
		queue_free()  # Destroy the bullet after hitting the enemy
