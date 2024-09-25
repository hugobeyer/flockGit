extends Node3D

@export var shield_strength: float = 150.0
@export var max_shield: float = 50.0
@export var recharge_rate: float = 1.0  # Recharge per second
@export var recharge_delay: float = 1.0  # Delay before recharge
@export var shield_display_duration: float = 0.3  # Time the shield appears

var recharge_timer: float = 0.0
var display_timer: float = 0.0  # Timer for showing shield effect

# Called every frame
func _process(delta):
	# Shield recharge logic
	if shield_strength < max_shield:
		recharge_timer += delta
		if recharge_timer >= recharge_delay:
			shield_strength += recharge_rate * delta
			shield_strength = clamp(shield_strength, 0, max_shield)

	# Handle shield visibility and shader updates
	if display_timer > 0:
		display_timer -= delta
		if display_timer <= 0:
			$MeshInstance3D.scale = Vector3.ZERO  # Hide shield
			$MeshInstance3D.set_instance_shader_parameter("shield_die", 1.0)  # Trigger shield die effect
		else:
			update_shader_parameters()

	# Hide the shield if its strength is zero
	if shield_strength <= 0:
		hide_shield()

# Function to hide the shield when strength is zero
func hide_shield():
	$MeshInstance3D.scale = Vector3.ZERO  # Hide the shield
	$MeshInstance3D.set_instance_shader_parameter("shield_die", 1.0)  # Trigger shield die effect

# Function to handle taking damage
func take_damage(damage: float) -> float:
	recharge_timer = 0.0  # Reset recharge timer on damage
	display_shield_effect()  # Show shield effect
	if shield_strength > 0:
		var remaining_damage = damage - shield_strength
		shield_strength -= damage
		if shield_strength < 0:
			shield_strength = 0
		$MeshInstance3D.set_instance_shader_parameter("shield_die", 1.0)  # Reset shield die effect
		return max(remaining_damage, 0)  # Return remaining damage to health
	return damage  # If no shield, all damage goes through

# Show shield effect for a brief moment and update shader parameters
func display_shield_effect():
	if shield_strength > 0:  # Only show if shield still has strength
		$MeshInstance3D.scale = Vector3.ONE  # Make shield visible
		display_timer = shield_display_duration  # Start shield display timer
		$MeshInstance3D.set_instance_shader_parameter("shield_die", 0.0)  # Reset shield die effect
		$MeshInstance3D.set_instance_shader_parameter("shield_hit", 1.0)  # Trigger shield hit effect
		$MeshInstance3D.set_instance_shader_parameter("shield_size_hit", 2.0)  # Set size for shield hit effect

# Update shader parameters over time
func update_shader_parameters():
	var hit_value = lerp($MeshInstance3D.get_instance_shader_parameter("shield_hit"), 0.0, 0.1)
	var size_value = lerp($MeshInstance3D.get_instance_shader_parameter("shield_size_hit"), 0.0, 0.1)
	var die_value = lerp($MeshInstance3D.get_instance_shader_parameter("shield_die"), 0.0, 0.1)

	$MeshInstance3D.set_instance_shader_parameter("shield_die", die_value)  # Reset shield die effect
	$MeshInstance3D.set_instance_shader_parameter("shield_hit", hit_value)
	$MeshInstance3D.set_instance_shader_parameter("shield_size_hit", size_value)
