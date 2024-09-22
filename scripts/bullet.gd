extends Area3D

export var speed = 50.0  # Adjust as needed
var direction = Vector3.ZERO

func _ready():
	# Remove the bullet after some time to prevent infinite bullets in the scene
	await get_tree().create_timer(5.0).timeout
	queue_free()

func _physics_process(delta):
	# Move the bullet forward
	global_transform.origin += direction * speed * delta
