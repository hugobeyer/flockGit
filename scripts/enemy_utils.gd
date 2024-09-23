extends Node

# Flash the enemy red when hit, then revert to original color
func flash_red(mesh_instance: MeshInstance3D, original_albedo: Color, hit_color: Color, flash_duration: float):
	# Change the albedo color to the hit color
	mesh_instance.material_override.albedo_color = hit_color
	
	# Restore original albedo after flash_duration
	await get_tree().create_timer(flash_duration).timeout
	mesh_instance.material_override.albedo_color = original_albedo

# Function to update health display on a Label3D
func update_health_display(health: float, max_health: float, label: Label3D):
	if label:
		var percentage = (health / max_health) * 100
		label.text = str(round(percentage)) + "%"
