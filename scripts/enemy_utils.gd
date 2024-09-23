extends Node

# Function to flash red on a mesh instance
func flash_red(mesh_instance: MeshInstance3D, original_albedo: Color, hit_color: Color, duration: float):
	if not mesh_instance or not is_inside_tree():
		return  # Ensure we are in the scene tree and mesh_instance exists

	var material = mesh_instance.material_override
	if not material:
		material = StandardMaterial3D.new()
		mesh_instance.material_override = material

	material.albedo_color = hit_color

	# Create a timer to revert the color after a short duration
	var timer = get_tree().create_timer(duration)
	timer.timeout.connect(Callable(self, "_reset_flash"), [mesh_instance, original_albedo])

# Method to reset the color back to the original
func _reset_flash(mesh_instance: MeshInstance3D, original_albedo: Color):
	if mesh_instance and mesh_instance.material_override:
		mesh_instance.material_override.albedo_color = original_albedo

# Function to update the health display on a label (enemy health bar or text)
func update_health_display(health: float, max_health: float, label: Label3D) -> void:
	if not label:
		return
	var health_percentage = (health / max_health) * 100
	label.text = str(round(health_percentage)) + "%"
