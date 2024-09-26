extends Node3D

signal shield_depleted
signal shield_recharged

@export var shield_strength: float = 150.0
@export var max_shield: float = 150.0  # Changed to match initial shield_strength
@export var recharge_rate: float = 1.0  # Recharge per second
@export var recharge_delay: float = 1.0  # Delay before recharge
@export var shield_display_duration: float = 0.3  # Time the shield appears

var recharge_timer: float = 0.0
var display_timer: float = 0.0  # Timer for showing shield effect
var is_shield_depleted: bool = false

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready():
	if not mesh_instance:
		push_error("MeshInstance3D not found for EnemyShield")

func _process(delta):
	# Shield recharge logic
	if shield_strength < max_shield:
		recharge_timer += delta
		if recharge_timer >= recharge_delay:
			shield_strength += recharge_rate * delta
			shield_strength = clamp(shield_strength, 0, max_shield)
			if is_shield_depleted and shield_strength > 0:
				is_shield_depleted = false
				emit_signal("shield_recharged")

	# Handle shield visibility and shader updates
	if display_timer > 0:
		display_timer -= delta
		if display_timer <= 0:
			hide_shield()
		else:
			update_shader_parameters()

	# Hide the shield if its strength is zero
	if shield_strength <= 0 and not is_shield_depleted:
		hide_shield()
		is_shield_depleted = true
		emit_signal("shield_depleted")

func hide_shield():
	if mesh_instance:
		mesh_instance.scale = Vector3.ZERO  # Hide shield
		mesh_instance.set_instance_shader_parameter("shield_die", 1.0)  # Trigger shield die effect

func take_damage(damage: float) -> float:
	recharge_timer = 0.0  # Reset recharge timer on damage
	display_shield_effect()  # Show shield effect
	if shield_strength > 0:
		var remaining_damage = damage - shield_strength
		shield_strength -= damage
		if shield_strength < 0:
			shield_strength = 0
		if mesh_instance:
			mesh_instance.set_instance_shader_parameter("shield_die", 1.0)  # Reset shield die effect
		return max(remaining_damage, 0)  # Return remaining damage to health
	return damage  # If no shield, all damage goes through

func display_shield_effect():
	if shield_strength > 0 and mesh_instance:  # Only show if shield still has strength
		mesh_instance.scale = Vector3.ONE  # Make shield visible
		display_timer = shield_display_duration  # Start shield display timer
		mesh_instance.set_instance_shader_parameter("shield_die", 0.0)  # Reset shield die effect
		mesh_instance.set_instance_shader_parameter("shield_hit", 1.0)  # Trigger shield hit effect
		mesh_instance.set_instance_shader_parameter("shield_size_hit", 2.0)  # Set size for shield hit effect

func update_shader_parameters():
	if mesh_instance:
		var hit_value = lerp(mesh_instance.get_instance_shader_parameter("shield_hit"), 0.0, 0.1)
		var size_value = lerp(mesh_instance.get_instance_shader_parameter("shield_size_hit"), 0.0, 0.1)
		var die_value = lerp(mesh_instance.get_instance_shader_parameter("shield_die"), 0.0, 0.1)

		mesh_instance.set_instance_shader_parameter("shield_die", die_value)
		mesh_instance.set_instance_shader_parameter("shield_hit", hit_value)
		mesh_instance.set_instance_shader_parameter("shield_size_hit", size_value)

func get_shield_percentage() -> float:
	return (shield_strength / max_shield) * 100.0
