extends Node3D

var bullet_scene_path: String = "res://_scenes/bullet.tscn"
@export var fire_rate: float = 0.05
@export var bullet_speed: float = 50.0
@export var bullet_damage: float = 10.0
@export var muzzle_node: Node3D

@export var spread_count_bullet: int = 1
@export var spread_total_angle: float = 20.0
@export var spread_max_angle: float = 40.0
@export var spread_increase_speed: float = 5.0
@export var spread_polar_angle: float = 5.0

@export var recoil_force: float = 0.1
@export var recoil_recovery_speed: float = 0.05
var current_recoil: float = 0.0

@onready var player = get_parent()

var bullet_scene: PackedScene = null
var time_since_last_shot: float = 0.0
var current_spread_angle: float = 0.0
var current_polar_angle: float = 0.0
var current_recoil_offset: Vector3 = Vector3.ZERO

func _ready():
	bullet_scene = load(bullet_scene_path)

func _process(delta: float):
	time_since_last_shot += delta
	if Input.is_action_pressed("shoot") and time_since_last_shot >= fire_rate:
		shoot2()
		time_since_last_shot = 0.0
	# else:
	# 	reset_spread_angle()

	apply_recoil_force(delta)

func shoot2():
	if bullet_scene == null:
		print("bullet_scene is null")
		return

	var muzzle_position = global_transform.origin
	var forward_direction = global_transform.basis.z.normalized()  # Removed the negative sign
	var bullet = bullet_scene.instantiate()
	if bullet:
		get_tree().root.add_child(bullet)
		bullet.global_transform.origin = muzzle_position
		bullet.top_level = true
		
		bullet.velocity = forward_direction * bullet_speed
		
		if bullet.has_method("set_damage"):
			bullet.set_damage(bullet_damage)
		
		if bullet.has_method("set_bullet_owner"):
			bullet.set_bullet_owner(player)
		
		apply_recoil(-forward_direction)  # Inverted for recoil
		
		print("Bullet fired from position: ", muzzle_position)
		print("Bullet direction: ", forward_direction)
	else:
		print("Failed to instantiate bullet")

	var end_point = muzzle_position + forward_direction * 5
	draw_debug_line(muzzle_position, end_point, Color.RED)

func shoot_single_bullet(direction: Vector3):
	var bullet_instance = create_bullet_instance()
	if bullet_instance:
		set_bullet_properties(bullet_instance, direction)

func create_bullet_instance() -> Area3D:
	var bullet = bullet_scene.instantiate() as Area3D
	if bullet:
		get_tree().root.add_child(bullet)
		return bullet
	else:
		print("Failed to instantiate bullet")
		return null

func set_bullet_properties(bullet: Area3D, direction: Vector3):
	bullet.global_transform = muzzle_node.global_transform
	bullet.top_level = true
	bullet.velocity = direction * bullet_speed
	
	if bullet.has_method("set_damage"):
		bullet.set_damage(bullet_damage)
	
	if bullet.has_method("set_bullet_owner"):
		bullet.set_bullet_owner(player)
	
	apply_recoil(direction)

func apply_recoil(direction: Vector3):
	current_recoil += recoil_force
	current_recoil = min(current_recoil, PI / 4)  # Limit maximum recoil
	
	if player and player.has_method("update_recoil_offset"):
		player.update_recoil_offset(current_recoil)

func apply_recoil_force(delta: float):
	current_recoil = move_toward(current_recoil, 0, recoil_recovery_speed * delta)
	
	if player and player.has_method("update_recoil_offset"):
		player.update_recoil_offset(current_recoil)

func increase_spread_angle(delta: float):
	current_spread_angle = min(current_spread_angle + spread_increase_speed * delta, spread_max_angle)

func reset_spread_angle():
	current_spread_angle = spread_total_angle
	current_polar_angle = 0.0

func draw_debug_line(start: Vector3, end: Vector3, color: Color):
	var im = ImmediateMesh.new()
	var material = ORMMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(start)
	im.surface_add_vertex(end)
	im.surface_end()
	
	var mi = MeshInstance3D.new()
	mi.mesh = im
	mi.material_override = material
	add_child(mi)
	await get_tree().create_timer(0.1).timeout
	mi.queue_free()