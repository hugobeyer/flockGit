class_name EnemyEffects
extends Node3D

@export var flash_duration: float = 0.1
@onready var flash_color: Color = Color(1, 0, 0)

var mesh_instance: MeshInstance3D

func _ready():
	mesh_instance = get_parent().get_node("MeshInstance3D")
	# mesh_instance.set_instance_shader_parameter("lerp_color", default_color)

func flash_red():
	if mesh_instance:
		var local_tween = create_tween()

		local_tween.tween_method(set_flash_intensity, 0.0, 1.0, flash_duration / 2)
		local_tween.tween_method(set_flash_intensity, 1.0, 0.0, flash_duration / 2)
		local_tween.tween_property(self, "modulate", set_flash_color, flash_duration / 2)
		local_tween.tween_property(self, "modulate", set_flash_color, flash_duration / 2)

func set_flash_intensity(value: float):
	mesh_instance.set_instance_shader_parameter("lerp_wave", value)

func set_flash_color(color: Color):
	flash_color = color
	mesh_instance.set_instance_shader_parameter("lerp_color", flash_color)

func apply_damage_effect(damage: Vector3):
	flash_red()
