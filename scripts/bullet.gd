extends CharacterBody3D

@export var health: float = 100.0
@export var max_health: float = 100.0
@export var move_speed: float = 5.0
@export var hit_color: Color = Color(1, 0, 0)  # Color for when hit
@export var flash_duration: float = 0.2  # Time to flash red

var enemy_utils_instance = preload("res://scripts/enemy_utils.gd").new()
var enemy_behaviors_instance = preload("res://scripts/enemy_behaviors.gd").new()

signal enemy_destroyed

var original_albedo: Color
var enemy_label: Label3D
var mesh_instance: MeshInstance3D

func _ready():
	mesh_instance = $MeshInstance3D
	if mesh_instance:
		if not mesh_instance.material_override:
			mesh_instance.material_override = StandardMaterial3D.new()
		original_albedo = mesh_instance.material_override.albedo_color

	enemy_label = $Label3D
	update_health_display()

func _process(_delta):
	if enemy_target:
		steer_toward_player_with_behaviors()

# Function to handle bullet hits
func on_bullet_hit(damage: float):
	health -= damage
	print("Enemy hit! Health: ", health)

	# Flash red using the instance method from enemy_utils.gd
	enemy_utils_instance.flash_red(mesh_instance, original_albedo, hit_color, flash_duration)

	# Update health display
	enemy_utils_instance.update_health_display(health, max_health, enemy_label)

	if health <= 0:
		emit_signal("enemy_destroyed", self)
		queue_free()
