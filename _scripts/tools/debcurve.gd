@tool
extends Node3D

@export var settings: CurveSettings:
    set(value):
        settings = value
        _request_update()

var _update_pending := false

func _ready():
    if not settings:
        settings = CurveSettings.new()
    update_mesh()

func _get(property):
    if settings and property in settings:
        return settings.get(property)
    return null

func _set(property, value):
    if settings and property in settings:
        settings.set(property, value)
        _request_update()
        return true
    return false

func _get_property_list():
    var properties = []
    if settings:
        properties = settings.get_property_list()
    # Filter out properties we don't want to expose directly
    properties = properties.filter(func(prop): return prop["name"] != "resource_local_to_scene" and prop["name"] != "resource_path")
    return properties

func _request_update():
    if not _update_pending:
        _update_pending = true
        call_deferred("update_mesh")

func update_mesh():
    _update_pending = false
    if not settings:
        return
    
    for child in get_children():
        if child is MeshInstance3D:
            child.queue_free()
    
    var mesh_instance = MeshInstance3D.new()
    var im = ImmediateMesh.new()
    var material = StandardMaterial3D.new()
    
    material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    material.albedo_color = settings.draw_color
    
    im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
    
    var min_y = INF
    var max_y = -INF
    var points = []
    
    for i in range(settings.draw_resolution + 1):
        var t = float(i) / settings.draw_resolution
        var x = t
        var y = trigon_signed(t)
        points.append(Vector2(x, y))
        min_y = min(min_y, y)
        max_y = max(max_y, y)
    
    for point in points:
        var x = point.x * settings.curve_scale
        var y = remap(point.y, min_y, max_y, 0, 1) * settings.amplitude
        im.surface_add_vertex(Vector3(x, y, 0))
    
    im.surface_end()
    
    mesh_instance.mesh = im
    mesh_instance.material_override = material
    
    add_child(mesh_instance)

func remap(value, old_min, old_max, new_min, new_max):
    var old_range = old_max - old_min
    if old_range == 0:
        return (new_min + new_max) / 2
    var new_range = new_max - new_min
    return (((value - old_min) * new_range) / old_range) + new_min

func _get_configuration_warnings() -> PackedStringArray:
    var warnings = PackedStringArray()
    if settings.amplitude == 0 or settings.curve_scale == 0:
        warnings.append("Amplitude or curve_scale is 0. The curve might not be visible.")
    return warnings

func trigon_signed(t: float) -> float:
    if not settings:
        return 0.0
    
    var primary_wave = sin(2 * PI * settings.primary_frequency * t + settings.phase_shift)
    var secondary_wave = cos(2 * PI * settings.secondary_frequency * t + settings.phase_shift)
    var tertiary_wave = sin(2 * PI * settings.tertiary_frequency * t + settings.phase_shift)
    
    var blended_wave = lerp(primary_wave, secondary_wave, settings.blend_factor)
    blended_wave = lerp(blended_wave, tertiary_wave, 0.3)
    
    # Apply distortion based on the selected type
    match settings.distortion_type:
        1:  # Pow
            blended_wave = pow(abs(blended_wave), 1 + settings.distortion) * sign(blended_wave)
        2:  # Atan2
            blended_wave = atan2(blended_wave, 1 - settings.distortion) / (PI/2)
        3:  # Bias
            blended_wave = (blended_wave + 1) / 2
            blended_wave = pow(blended_wave, log(settings.distortion) / log(0.5))
            blended_wave = blended_wave * 2 - 1
        4:  # SoftClip
            var x = blended_wave * (1 + settings.distortion)
            blended_wave = x / (1 + abs(x))
        5:  # Remainder
            blended_wave = fmod(blended_wave + settings.distortion, 2.0) - 1.0
    
    return clampf(blended_wave, -1.0, 1.0)
