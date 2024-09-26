extends Node3D  # Change from Node3D to CharacterBody3D

@export var animation_player_path: NodePath = "AnimationPlayer"
@export var melee_node_path: NodePath = "/root/Main/Enemy/MeleeWeapon/SwordArea"
@export var swing_animation: String = "swing_animation"
@export var player_pos_path: NodePath = "/root/Main/Player"

@export var animation_speed: float = 3.0
@export var attack_radius: float = 5.75
@export var damage_amount: float = 10.0

@export var animation_length: float = 2.0
@export var hit_window_start: float = 0.75
@export var hit_window_end: float = 1.25

var player_pos: Node3D
var animation_player: AnimationPlayer
var melee_node: Node3D
var can_attack: bool = true
var is_attacking: bool = false
var attack_timer: float = 0.0

func _ready():
	player_pos = get_node_or_null(player_pos_path)
	animation_player = get_node_or_null(animation_player_path)
	melee_node = get_node_or_null(melee_node_path)
	
	if melee_node:
		melee_node.visible = false
	#else:
		#push_error("Melee node not found at path: " + melee_node_path)

func _physics_process(delta: float):
	if can_attack and player_pos:
		var distance = global_position.distance_to(player_pos.global_position)
		if distance <= attack_radius:
			start_attack()
	
	if is_attacking:
		update_attack(delta)

func start_attack():
	if not is_attacking:
		is_attacking = true
		can_attack = false
		attack_timer = 0.0
		if melee_node:  # Ensure melee_node is valid
			melee_node.visible = true
		else:
			push_error("Melee node is null when starting attack.")
		play_swing_animation()

func update_attack(delta: float):
	attack_timer += delta
	
	if hit_window_start <= attack_timer and attack_timer <= hit_window_end:
		check_hit()
	
	if attack_timer >= animation_length:
		end_attack()

func check_hit():
	if player_pos.has_method("take_damage"):
		var distance = global_position.distance_to(player_pos.global_position)
		if distance <= attack_radius:
			player_pos.take_damage(damage_amount)
			print("Player hit for ", damage_amount, " damage.")

func end_attack():
	is_attacking = false
	if melee_node:
		melee_node.visible = false
	animation_player.stop()
	can_attack = true

func play_swing_animation():
	if animation_player.has_animation(swing_animation):
		animation_player.play(swing_animation)
		animation_player.speed_scale = animation_speed

func take_damage():
	can_attack = false
	is_attacking = false
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0, 0.2)
	await tween.finished
	queue_free()
