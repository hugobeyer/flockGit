class_name EnemyEffects
extends Node3D

@export var flash_duration: float = 0.1
@export var flash_offset: float = 16.0
@export var flash_color: Color = Color(1.0, 0.417, 0.0, 1)
@export var flash_off_color: Color = Color(0, 0, 0, 0)

var mesh_instance: MeshInstance3D

func _ready():
    mesh_instance = get_parent().get_node("MeshInstance3D")
    mesh_instance.set_instance_shader_parameter("lerp_wave", 0)
    mesh_instance.set_instance_shader_parameter("lerp_wave_offset", 0)

func flash_red():
    var local_tween = create_tween()

    local_tween.tween_method(set_flash_intensity, 0.0, 1.0, flash_duration / 2)
    local_tween.tween_method(set_flash_intensity, 1.0, 0.0, flash_duration / 2)
    local_tween.tween_method(set_flash_color, flash_off_color, flash_color, flash_duration / 2)
    local_tween.tween_method(set_flash_color, flash_color, flash_off_color, flash_duration / 2)

func set_flash_intensity(value: float):
    mesh_instance.set_instance_shader_parameter("lerp_wave", value)
    mesh_instance.set_instance_shader_parameter("lerp_wave_offset", value * flash_offset)

func set_flash_color(color: Color):
    mesh_instance.set_instance_shader_parameter("lerp_color", color)

func apply_damage_effect(damage: Vector3):
    flash_red()

func _on_property_changed():
    mesh_instance.set_instance_shader_parameter("lerp_color", flash_color)
    mesh_instance.set_instance_shader_parameter("lerp_wave", 1.0)
    mesh_instance.set_instance_shader_parameter("lerp_wave_offset", flash_offset)
