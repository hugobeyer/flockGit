@tool
extends Node3D

@export var amplitude: float = 1.0
@export var primary_frequency: float = 1.0
@export var secondary_frequency: float = 2.0
@export var phase_shift: float = 0.0
@export var blend_factor: float = 0.5
@export var draw_color: Color = Color.WHITE
@export var draw_resolution: int = 100
@export var curve_scale: float = 1.0

func _ready():
    update_mesh()

func trigon_signed(t: float) -> float:
    var primary_wave = sin(2 * PI * primary_frequency * t + phase_shift)
    var secondary_wave = cos(2 * PI * secondary_frequency * t + phase_shift)
    var blended_wave = lerp(primary_wave, secondary_wave, blend_factor)
    return blended_wave

func _process(delta):
    if Engine.is_editor_hint():
        update_mesh()

func update_mesh():
    for child in get_children():
        if child is MeshInstance3D:
            child.queue_free()
    
    var mesh_instance = MeshInstance3D.new()
    var im = ImmediateMesh.new()
    var material = StandardMaterial3D.new()
    
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = draw_color
    
    im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
    
    var min_y = INF
    var max_y = -INF
    var points = []
    
    for i in range(draw_resolution + 1):
        var t = float(i) / draw_resolution
        var x = t
        var y = trigon_signed(t)
        points.append(Vector2(x, y))
        min_y = min(min_y, y)
        max_y = max(max_y, y)
    
    for point in points:
        var x = point.x * curve_scale
        var y = remap(point.y, min_y, max_y, 0, 1) * amplitude
        im.surface_add_vertex(Vector3(x, y, 0))
    
    im.surface_end()
    
    mesh_instance.mesh = im
    mesh_instance.material_override = material
    
    add_child(mesh_instance)
    print("Mesh updated. Points: ", draw_resolution + 1, " Scale: ", curve_scale, " Amplitude: ", amplitude)

func remap(value, old_min, old_max, new_min, new_max):
    var old_range = old_max - old_min
    var new_range = new_max - new_min
    return (((value - old_min) * new_range) / old_range) + new_min

func _get_configuration_warnings() -> PackedStringArray:
    var warnings = PackedStringArray()
    if amplitude == 0 or curve_scale == 0:
        warnings.append("Amplitude or curve_scale is 0. The curve might not be visible.")
    return warnings
