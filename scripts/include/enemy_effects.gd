class_name EnemyEffects
extends Node

signal knockback_finished

@export var knockback_duration: float = 0.2
@export var knockback_strength: float = 5.0
@export var flash_duration: float = 0.1

var enemy: CharacterBody3D
var mesh_instance: MeshInstance3D
var tween: Tween

func _ready():
	enemy = get_parent()
	assert(enemy is CharacterBody3D, "EnemyEffects must be a child of a CharacterBody3D")
	mesh_instance = enemy.get_node("MeshInstance3D")
	assert(mesh_instance, "MeshInstance3D not found on enemy")

func apply_knockback(direction: Vector2, force: float):
	var knockback_vector = direction.normalized() * force
	# Use knockback_vector instead of a global knockback variable
	# Apply the knockback to the enemy's position or velocity here

func flash_red():
	var local_tween = create_tween()
	local_tween.tween_method(set_flash_intensity, 0.0, 1.0, flash_duration / 2)
	local_tween.tween_method(set_flash_intensity, 1.0, 0.0, flash_duration / 2)

func set_flash_intensity(value: float):
	mesh_instance.set_instance_shader_parameter("flash_intensity", value)

func apply_damage_effect(damage_direction: Vector2):
	apply_knockback(damage_direction, 1.0)
	flash_red()
