extends MeshInstance3D

@export var max_radius: float = 10.0 : set = set_max_radius
@export var falloff_start: float = 8.0 : set = set_falloff_start

@onready var material: ShaderMaterial

func set_max_radius(value: float):
    max_radius = value
    if material:
        material.set_shader_parameter("max_radius", value)

func set_falloff_start(value: float):
    falloff_start = value
    if material:
        material.set_shader_parameter("falloff_start", value)

func _ready():
    # Initial setup
    set_max_radius(max_radius)
    set_falloff_start(falloff_start)
