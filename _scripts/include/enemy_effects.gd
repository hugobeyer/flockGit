class_name EnemyEffects
extends Node3D

signal knockback_finished

@export var knockback_strength: float = 5.0
@export var flash_duration: float = 0.1

var enemy: CharacterBody3D
var mesh_instance: MeshInstance3D

func _ready():
	enemy = get_parent()
	assert(enemy is CharacterBody3D, "EnemyEffects must be a child of a RigidBody3D")
	mesh_instance = enemy.get_node("PivotPoint/MeshInstance3D")
	if not mesh_instance:
		push_warning("MeshInstance3D not found on enemy. Visual effects may not work.")

# func apply_knockback(direction: Vector3, force: float):
# 	if enemy:
# 		enemy.apply_impulse(direction * force, Vector3.ZERO)
# 	else:
# 		push_warning("Enemy reference is null. Knockback not applied.")

func flash_red():
	if mesh_instance:
		var local_tween = create_tween()
		local_tween.tween_method(set_flash_intensity, 0.0, 1.0, flash_duration / 2)
		local_tween.tween_method(set_flash_intensity, 1.0, 0.0, flash_duration / 2)
	else:
		push_warning("Cannot apply visual effect: MeshInstance3D not found on enemy.")

func set_flash_intensity(value: float):
	mesh_instance.set_instance_shader_parameter("lerp_wave", value)

func apply_damage_effect(damage_direction: Vector3):
	# apply_knockback(damage_direction, knockback_strength)
	flash_red()
