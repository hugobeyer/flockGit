extends CharacterBody3D

@export var health: float = 100.0
@export var move_speed: float = 5.0
@export var separation_radius: float = 5.0
@export var alignment_radius: float = 10.0
@export var separation_weight: float = 1.5
@export var alignment_weight: float = 1.0
@export var player_target_weight: float = 2.0
@export var use_fov: bool = true
@export var fov_angle_radians: float = PI / 2.0  # 90 degrees in radians
var enemy_target: Node3D  # Set dynamically from level_settings.gd

signal enemy_destroyed

var target_position: Vector3

func _ready():
	# We won't rely on the Inspector to set the target.
	# The target will be set dynamically from level_settings.gd after spawning.
	if enemy_target:
		target_position = enemy_target.global_transform.origin

func _process(_delta):
	if enemy_target:
		# Update target position in case the player moves
		target_position = enemy_target.global_transform.origin
		steer_toward_player_with_behaviors()

# Handle bullet hits
func on_bullet_hit(damage: float):
	health -= damage
	if health <= 0:
		emit_signal("enemy_destroyed", self)
		queue_free()

# Movement and behavior logic
func steer_toward_player_with_behaviors():
	var direction_to_player = (target_position - global_transform.origin).normalized()
	velocity = direction_to_player * move_speed
	move_and_slide()
