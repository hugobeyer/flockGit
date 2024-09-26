extends CharacterBody3D

class_name Enemy

@export var max_speed: float = 100.0
@export var max_health: float = 100.0  # This will always be 100 (representing 100%)
@export var health: float = 100.0  # This represents the current health percentage

var player_target: CharacterBody3D
var target: Node3D

@onready var effects: EnemyEffects = $EnemyEffects
@onready var flocking: Node3D = $Flocking
@onready var enemy_shield: Node3D = $EnemyShield
@onready var health_label: Label3D = $HealthLabel
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D

func _ready():
	assert(effects, "EnemyEffects node not found. Please add it as a child of the Enemy.")
	assert(flocking, "Flocking node not found. Please add it as a child of the Enemy.")
	assert(enemy_shield, "EnemyShield node not found. Please add it as a child of the Enemy.")
	assert(health_label, "HealthLabel node not found. Please add a Label3D as a child of the Enemy.")
	assert(mesh_instance, "MeshInstance3D node not found. Please add it as a child of the Enemy.")
	update_health_display()

func _physics_process(delta):
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	var flocking_force = flocking.calculate_flocking_force(self, all_enemies)
	velocity += flocking_force * delta
	velocity = velocity.limit_length(flocking.max_speed)

	set_velocity(velocity)
	move_and_slide()
	velocity = velocity  # This updates velocity after collision

	if velocity.length() > 0.1:
		look_at(global_position + velocity, Vector3.UP)

func get_position_2d() -> Vector2:
	return Vector2(global_position.x, global_position.z)

func take_damage(amount: float, damage_direction: Vector3) -> void:
	if enemy_shield:
		amount = enemy_shield.take_damage(amount)
	
	if amount > 0:
		health -= amount
		health = max(health, 0)  # Ensure health doesn't go below 0
		update_health_display()
		effects.apply_damage_effect(Vector2(damage_direction.x, damage_direction.z))
		update_low_health_shader()
	
	if health <= 0:
		on_defeated()

func set_player_target(player: CharacterBody3D):
	self.player_target = player

func set_target(new_target: Node3D):
	target = new_target
	# Set up navigation to the target

func on_defeated():
	# Call this when the enemy is defeated
	get_node("/root/Main/WaveSystem").on_enemy_defeated()
	queue_free()

# Function to get health as a percentage string
func get_health_percentage() -> String:
	return str(round(health)) + "%"

func update_health_display() -> void:
	if health_label:
		health_label.text = get_health_percentage()

func flash_red() -> void:
	var tween = create_tween()
	tween.tween_method(set_flash_intensity, 0.0, 1.0, 0.1)
	tween.tween_method(set_flash_intensity, 1.0, 0.0, 0.1)

func set_flash_intensity(value: float) -> void:
	mesh_instance.set_instance_shader_parameter("flash_intensity", value)

func update_low_health_shader() -> void:
	var low_health_value = 1 - (health / 100)
	mesh_instance.set_instance_shader_parameter("low_health", low_health_value)
