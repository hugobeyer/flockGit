extends Node3D

@export var camera: Camera3D  # Exported so you can assign the Camera node in the Inspector

func _ready():
	if not camera:
		print("Camera node not assigned!")

func _process(_delta):
	rotate_player_to_mouse()

func rotate_player_to_mouse():
	if not camera:
		return

	# Get mouse position and project ray from the camera through the mouse position
	var mouse_position = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_position)
	var ray_direction = camera.project_ray_normal(mouse_position)
	
	# Set ray length and end point
	var ray_length = 1000.0
	var ray_end = ray_origin + ray_direction * ray_length

	# Prepare raycast query
	var space_state = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = ray_origin
	ray_query.to = ray_end
	ray_query.collide_with_areas = true
	ray_query.collide_with_bodies = true

	# Perform raycast
	var result = space_state.intersect_ray(ray_query)

	if result:
		var hit_position = result.position
		var player_position = global_transform.origin

		# Calculate direction to the mouse position, ignore Y axis (XZ plane)
		var direction_to_mouse = (hit_position - player_position).normalized()
		direction_to_mouse.y = 0

		# Calculate the yaw rotation (rotation around Y axis)
		var new_rotation_y = atan2(direction_to_mouse.x, direction_to_mouse.z)
		
		# Apply the rotation to the player
		rotation_degrees.y = rad_to_deg(new_rotation_y)

		#print("Player rotation set to: ", rotation_degrees.y)
	#else:
		#print("Raycast did not hit anything")
