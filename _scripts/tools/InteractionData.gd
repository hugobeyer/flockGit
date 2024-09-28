@tool
class_name InteractionData
extends Resource

enum ParameterType {
    CUSTOM,
    ACTOR_INSTANCE_ID,
    UNIFORM_COLOR,
}

@export var parameter_type: ParameterType
@export var custom_parameter_name: String
@export var min_value: float = 0.0
@export var max_value: float = 1.0
@export var speed: float = 1.0
@export var is_color: bool = false
@export var color_value: Color = Color.WHITE
@export var is_int: bool = false

func get_parameter_name() -> String:
    match parameter_type:
        ParameterType.CUSTOM:
            return custom_parameter_name
        ParameterType.ACTOR_INSTANCE_ID:
            return "actor_instance_id"
        ParameterType.UNIFORM_COLOR:
            return "uniform_color"
        _:
            return "unknown_parameter"
