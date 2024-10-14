extends Node

@export var average_level_time: float = 300.0  # 5 minutes in seconds
@export var difficulty_factor: float = 1.0  # 1.0 is normal, higher is harder
@export var max_difficulty_increase: float = 2.0  # Maximum difficulty multiplier

var current_time: float = 0.0
var current_difficulty: float = 1.0

# Enemy type weights (adjust these based on your preference)
var enemy_weights = {
    "basic": 1.0,
    "fast": 0.7,
    "tank": 0.5
}

func _process(delta):
    current_time += delta
    update_difficulty()

func update_difficulty():
    var time_factor = current_time / average_level_time
    current_difficulty = min(1.0 + (time_factor * difficulty_factor), max_difficulty_increase)

func get_enemy_type() -> String:
    var total_weight = 0.0
    for weight in enemy_weights.values():
        total_weight += weight * current_difficulty
    
    var random_value = randf() * total_weight
    var cumulative_weight = 0.0
    
    for enemy_type in enemy_weights:
        cumulative_weight += enemy_weights[enemy_type] * current_difficulty
        if random_value <= cumulative_weight:
            return enemy_type
    
    return "basic"  # Fallback

func get_enemy_parameters(enemy_type: String) -> Dictionary:
    var base_params = {
        "basic": {
            "health": 100.0,
            "speed": 5.0,
            "damage": 10.0
        },
        "fast": {
            "health": 75.0,
            "speed": 7.5,
            "damage": 7.5
        },
        "tank": {
            "health": 150.0,
            "speed": 3.5,
            "damage": 15.0
        }
    }
    
    var params = base_params[enemy_type]
    for key in params:
        params[key] *= current_difficulty
    
    return params

func get_flocking_parameters() -> Dictionary:
    return {
        "separation_weight": 1.0 * current_difficulty,
        "alignment_weight": 0.8 * current_difficulty,
        "cohesion_weight": 0.6 * current_difficulty
    }
