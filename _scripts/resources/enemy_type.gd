extends Resource
class_name EnemyType

@export_group("Starting Features")
@export var use_shield: bool = false
@export var use_melee: bool = false

@export_group("General Enemy Parameters")
@export var max_health: float = 100.0
@export var movement_speed: float = 6.0
@export var knockback_resistance: float = 80.0
@export var turn_speed: float = 3.0
@export var detection_range: float = 32.0
@export var damage: float = 5.0

@export_group("Flocking Parameters")
@export var flock_separation_weight: float = 5.0
@export var flock_alignment_weight: float = 3.0
@export var flock_cohesion_weight: float = 2.0
@export var flock_neighbor_distance: float = 5.0
@export var max_flock_neighbors: int = 8
@export var flock_weight_change_rate: float = 0.1
@export var max_flock_weight_multiplier: float = 2.0

@export_group("Death Effect Parameters")
@export var death_effect_scene: PackedScene
@export var death_effect_duration: float = 1.0

@export_group("Berserk Parameters")
@export var berserk_chance: float = 0.0
@export var berserk_speed_multiplier: float = 2.0
@export var berserk_duration: float = 3.0

@export_group("Wander Parameters")
@export var wander_radius: float = 5.0
@export var wander_interval: float = 5.0

@export_group("Wobble Effect Parameters")
@export var wobble_strength: float = 1.0
@export var wobble_decay: float = 0.2
@export_range(0, 1) var wobble_damping: float = 0.9
