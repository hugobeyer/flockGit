@tool
extends Control

@export var shader_controller_path: NodePath
@onready var shader_controller: Node = get_node(shader_controller_path)

@export var selected_parameter: String
@export var parameter_time: float = 0.0 : 
    set(value):
        parameter_time = value
        _update_shader_param()

@export var parameter_curve: Curve :
    set(value):
        parameter_curve = value
        _update_shader_param()

var parameters: Array = []

func _ready():
    if Engine.is_editor_hint():
        _update_parameter_list()

func _update_parameter_list():
    if shader_controller:
        parameters = shader_controller.get_shader_param_list()
        notify_property_list_changed()

func _update_shader_param():
    if shader_controller and selected_parameter and parameter_curve:
        var value = parameter_curve.sample(parameter_time)
        shader_controller.update_shader_param(selected_parameter, value)

func _get_property_list():
    var properties = []
    
    properties.append({
        "name": "selected_parameter",
        "type": TYPE_STRING,
        "usage": PROPERTY_USAGE_DEFAULT,
        "hint": PROPERTY_HINT_ENUM,
        "hint_string": ",".join(parameters.map(func(p): return p.name))
    })
    
    return properties

func _set(property, value):
    if property == "selected_parameter":
        selected_parameter = value
        return true
    return false

func _get(property):
    if property == "selected_parameter":
        return selected_parameter
    return null