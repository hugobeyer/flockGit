extends Node3D

# Exported variables to drag and drop nodes in the Inspector
@export var camera: Camera3D  # Drag and drop the Camera node
@export var muzzle: Marker3D  # Drag and drop the Muzzle node
@export var bullet_resource: BulletResource  # Drag and drop the BulletResource here

var bullets = []

func _ready():
	# Optional: Ensure nodes are assigned
	if not camera or not muzzle:
		print("Camera or Muzzle node is missing!")

func _process(delta):
	# Rotate player to follow mouse position
	rotate_player_to_mouse()

	# Handle shooting with the left mouse button mapped to "shoot"
	if Input.is_action_just_pressed("shoot"):
		shoot()

	# Call the update_bullets function with the delta time
	update_bullets(delta)

func rotate_player_to_mouse():
	if not camera:
		return  # Ensure the camera is assigned
	
	# Example raycast using the camera and mouse position
	var space_state = get_world_3d().direct_space_state
	var mouse_position = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_direction = camera.project_ray_normal(mouse_position)
	
	# Additional logic for rotating based on raycast
	# ...


func shoot():
	if bullet_resource and muzzle and muzzle.is_inside_tree():
		var bullet_instance = MeshInstance3D.new()
		bullet_instance.mesh = bullet_resource.mesh
		bullet_instance.material_override = bullet_resource.material
		
		bullet_instance.global_transform.origin = muzzle.global_transform.origin
		bullet_instance.global_transform.basis = muzzle.global_transform.basis
		
		get_tree().current_scene.add_child(bullet_instance)

		bullets.append({
			"instance": bullet_instance,
			"speed": bullet_resource.bullet_speed,
			"lifetime": bullet_resource.bullet_lifetime
		})

# This function was missing; it's used to update the bullets' position and lifetime
func update_bullets(delta):
	var bullets_to_remove = []

	for bullet in bullets:
		# Update the bullet's position based on its speed
		bullet["instance"].translate(Vector3(0, 0, -bullet["speed"] * delta))

		# Update the bullet's lifetime
		bullet["lifetime"] -= delta

		# If the bullet's lifetime is up, queue it for removal
		if bullet["lifetime"] <= 0:
			bullet["instance"].queue_free()
			bullets_to_remove.append(bullet)

	# Remove expired bullets from the array
	for bullet in bullets_to_remove:
		bullets.erase(bullet)
