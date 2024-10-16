extends Node3D

signal gun_fired(recoil_force: Vector3)
signal recoil_reset()

#✦ 🔫 BULLET PARAMETERS 🔫                              ✦
#╘═════════════════════════════════════════════════════╛
@export_group("Bullet Parameters")
@export_range(0.01, 2.0) var fire_rate: float = 0.05
@export_range(1.0, 1000.0) var bullet_speed: float = 50.0
@export_range(1, 100) var bullet_damage: float = 10.0
@export_range(0.0, 100.0) var knockback: float = 10.0
@export var bullet_scene: PackedScene

#✦ 🧭 SPREAD PARAMETERS 🧭                             ✦
#╘═════════════════════════════════════════════════════╛
@export_group("Spread Parameters")
@export_range(1, 20) var spread_count_bullet: int = 1
@export_range(0.1, 360.0) var spread_count_angle: float = 20.0
@export_range(0.1, 45.0) var spread_count_randomize_angle: float = 5.0

#✦ 🔧 RECOIL PARAMETERS 🔧                             ✦
#╘═════════════════════════════════════════════════════╛
@export_group("Recoil Parameters")
## Base force of recoil applied to the gun
@export_range(0.001, 256.0) var recoil_force: float = 0.5
@export_range(0.001, 256.0) var max_recoil: float = 2.0
@export_range(0.01, 5.0) var recoil_amplitude: float = 45.0
@export_range(0.01, 5.0) var recoil_frequency: float = 1.0
@export_range(0.001, 16.0) var recoil_increase_duration: float = 1.0
@export var recoil_curve_time: Curve = Curve.new()
@export var recoil_mouse_up_curve: Curve = Curve.new()
@export var recoil_noise_speed: float = 1.0
@export var recoil_noise_texture: Texture2D  # This should now be a normal map texture
@export var recoil_linear_damp: float = 0.01
@export var recoil_angle_damp: float = 0.01

#✦ ⏱ RECOVERY PARAMETERS ⏱                             ✦
#╘═════════════════════════════════════════════════════╛
@export_group("Recovery Parameters")
@export_range(0.0001, 32.0) var recoil_mouse_up_recovery_time: float = 1.0

#✦ 🔧 NODE REFERENCES 🔧                               ✦
#╘═════════════════════════════════════════════════════╛
@export_group("Node References")
@onready var muzzle_node = get_node("Muzzle")
@onready var gun_node = self

# Add these new variables at the top of your script
var is_shooting: bool = false
var recoil_start_time: float = 0.0

# Variables
var current_recoil: float = 0.0
@onready var player = get_parent()
var time_since_last_shot: float = 0.0
var last_shot_time: float = 0.0
var current_recoil_offset: float = 0.0
var current_recoil_rotation_y: float = 0.0  # Only track Y-axis rotation for gun recoil
var noise_sample_x: float = 0.0  # Track the current X position for sampling the noise texture
var noise_sample_y: float = 0.0  # Track the current Y position for sampling the noise texture
var initial_gun_rotation: Vector3  # Store the initial rotation of the gun

# Debug cylinder export variables
@export_group("Debug Visualization")
@export var debug_cylinder_scene: PackedScene = preload("res://_meshes/debug/cyl_debug.tscn")
@export var debug_y_offset: float = 0.0
@export var debug_x_offset: float = 0.5
@export var debug_z_offset: float = 0.0
@export var debug_cylinder_spacing: float = 0.15

@export_subgroup("Debug Cylinder Colors")
@export var recoil_color_start: Color = Color.RED
@export var recoil_color_end: Color = Color.RED
@export var recovery_color_start: Color = Color.GREEN
@export var recovery_color_end: Color = Color.GREEN
@export var recoil_increase_color_start: Color = Color.ORANGE
@export var recoil_increase_color_end: Color = Color.ORANGE
@export var recoil_recovery_color_start: Color = Color.BLUE
@export var recoil_recovery_color_end: Color = Color.BLUE

# Debug cylinder variables
var recoil_cylinder: Node3D
var recovery_cylinder: Node3D
var recoil_increase_cylinder: Node3D
var recoil_recovery_cylinder: Node3D
var recoil_noise_cylinder: Node3D

# Add these new variables
var recoil_label: Sprite3D
var recovery_label: Sprite3D
var recoil_increase_label: Sprite3D
var recoil_recovery_label: Sprite3D

var recoil_noise_sprite: Sprite3D
var recoil_noise_label: Sprite3D
var recoil_accumulation: float = 0.0  # Add this variable to track recoil buildup

var is_recovering: bool = false
var recovery_start_time: float = 0.0

@export var camera_node: Camera3D  # Assign this in the Inspector

var thumbstick: Node = null
var fire_threshold: float = 0.5  # Adjust this value as needed

var is_trigger_pressed: bool = false

var shoot_direction: Vector2 = Vector2.ZERO

# Add these if they're not already present
var recoil_recovery_time: float = 0.5  # Adjust this value as needed
var is_recovering_from_recoil: bool = false
var recoil_recovery_start_time: float = 0.0

func _ready():
    if camera_node:
        if not camera_node:
            push_error("No camera found. Please assign a camera to the camera_node variable.")
    
    if debug_cylinder_scene == null:
        push_error("Debug cylinder scene could not be loaded. Check the provided path.")
    # else:
        # print("Debug cylinder scene successfully loaded in _ready().")
    
    if bullet_scene == null:
        push_error("Bullet scene could not be loaded. Check the provided path.")
    if recoil_noise_texture == null:
        push_error("Recoil noise texture could not be loaded. Assign a NoiseTexture2D.")
    if recoil_mouse_up_curve == null:
        push_error("Recoil mouse up recovery curve could not be loaded. Assign a Curve.")
    if gun_node == null:
        push_error("Gun node could not be loaded. Assign a valid Node3D for the gun.")
    else:
        # print("Bullet scene, noise texture, and recovery curve successfully loaded in _ready().")
        initial_gun_rotation = gun_node.rotation  # Store the initial rotation
    
    # Create debug sprites
    create_debug_cylinders()

    thumbstick = get_node("../../../MainHUD/ControllerCanvas/MovementJoystick")
    if not thumbstick:
        push_error("Thumbstick not found. Make sure it's properly added to the scene.")

    # Ensure muzzle_node is a child of the gun and positioned correctly
    muzzle_node = $Muzzle  # Adjust the path if necessary
    if not muzzle_node:
        push_error("Muzzle node not found!")
    else:
        print("Muzzle position: ", muzzle_node.global_transform.origin)

func create_debug_cylinders():
    recoil_cylinder = create_cylinder(recoil_color_start)
    recovery_cylinder = create_cylinder(recovery_color_start)
    recoil_increase_cylinder = create_cylinder(recoil_increase_color_start)
    recoil_recovery_cylinder = create_cylinder(recoil_recovery_color_start)
    recoil_noise_cylinder = create_cylinder(Color.WHITE)

    for cylinder in [recoil_cylinder, recovery_cylinder, recoil_increase_cylinder, recoil_recovery_cylinder, recoil_noise_cylinder]:
        if cylinder:
            add_child(cylinder)
        else:
            push_error("Failed to create cylinder instance.")

func create_cylinder(color: Color) -> Node3D:
    var cylinder = debug_cylinder_scene.instantiate()
    if cylinder:
        var mesh_instance = find_mesh_instance(cylinder)
        if mesh_instance:
            mesh_instance.set_instance_shader_parameter("emissive_color", color)
    return cylinder

func find_mesh_instance(node: Node) -> MeshInstance3D:
    if node is MeshInstance3D:
        return node
    for child in node.get_children():
        var result = find_mesh_instance(child)
        if result:
            return result
    return null

func update_debug_cylinders():
    if not camera_node:
        push_error("Camera node is not set. Cannot update debug cylinders.")
        return

    var world_up = Vector3.UP
    var camera_forward = -camera_node.global_transform.basis.z
    var camera_right = camera_forward.cross(world_up).normalized()
    
    var base_position = global_transform.origin + world_up * debug_y_offset + camera_node.global_transform.basis.z * debug_z_offset

    # Position cylinders
    recoil_cylinder.global_transform.origin = base_position + camera_right * debug_x_offset
    recovery_cylinder.global_transform.origin = base_position + camera_right * (debug_x_offset + debug_cylinder_spacing)
    recoil_increase_cylinder.global_transform.origin = base_position + camera_right * (debug_x_offset + debug_cylinder_spacing * 2)
    recoil_recovery_cylinder.global_transform.origin = base_position + camera_right * (debug_x_offset + debug_cylinder_spacing * 3)
    recoil_noise_cylinder.global_transform.origin = base_position + camera_right * (debug_x_offset + debug_cylinder_spacing * 4)

    # Update recoil cylinder
    var recoil_progress = current_recoil_offset / max_recoil
    update_cylinder_scale(recoil_cylinder, recoil_progress)
    update_cylinder_color(recoil_cylinder, recoil_color_start, recoil_color_end, recoil_progress)

    # Update recovery cylinder
    update_cylinder_scale(recovery_cylinder, 1.0 - recoil_progress)
    update_cylinder_color(recovery_cylinder, recovery_color_start, recovery_color_end, 1.0 - recoil_progress)

    # Update recoil increase cylinder
    var current_time = Time.get_ticks_msec() / 1000.0
    var recoil_duration = current_time - recoil_start_time
    var recoil_increase_progress = recoil_duration / recoil_increase_duration
    var recoil_curve_value = recoil_curve_time.sample_baked(recoil_increase_progress) if recoil_curve_time else recoil_increase_progress
    update_cylinder_scale(recoil_increase_cylinder, recoil_curve_value if is_shooting else 0.1)
    update_cylinder_color(recoil_increase_cylinder, recoil_increase_color_start, recoil_increase_color_end, recoil_curve_value if is_shooting else 0.1)

    # Update recoil recovery cylinder
    var recovery_progress = 0.0
    if is_recovering:
        var recovery_duration = current_time - recovery_start_time
        recovery_progress = min(recovery_duration / recoil_mouse_up_recovery_time, 1.0)
    var recovery_curve_value = recoil_mouse_up_curve.sample_baked(recovery_progress)
    update_cylinder_scale(recoil_recovery_cylinder, recovery_curve_value if is_recovering else 0.1)
    update_cylinder_color(recoil_recovery_cylinder, recoil_recovery_color_start, recoil_recovery_color_end, recovery_curve_value if is_recovering else 0.1)

    # Update recoil noise cylinder
    if recoil_noise_texture:
        var noise_value = recoil_noise_texture.get_image().get_pixelv(Vector2(int(noise_sample_x) % recoil_noise_texture.get_width(), 0)).r
        update_cylinder_scale(recoil_noise_cylinder, max(noise_value, 0.01))
        update_cylinder_color(recoil_noise_cylinder, Color.BLACK, Color.WHITE, noise_value)

    # Ensure cylinders are aligned with world up and facing the camera
    for cylinder in [recoil_cylinder, recovery_cylinder, recoil_increase_cylinder, recoil_recovery_cylinder, recoil_noise_cylinder]:
        var look_at_pos = cylinder.global_transform.origin + camera_forward
        cylinder.look_at(look_at_pos, world_up)

func update_cylinder_scale(cylinder: Node3D, scale_y: float):
    var scale_mesh = cylinder.get_node("ScaleMesh")
    var mesh_instance = scale_mesh.get_node("MeshInstance3D") if scale_mesh else null
    
    if mesh_instance and mesh_instance is MeshInstance3D:
        var new_scale = Vector3(1, max(scale_y, 0.01), 1)
        var original_height = 4.0  # Assuming the original height is 1.0, adjust if different
        var height_difference = original_height * (new_scale.y - 1)
        
        # Scale the mesh
        mesh_instance.scale = new_scale
        
        # Move the mesh up to keep the bottom at the same position
        mesh_instance.position.y = height_difference / 2

func update_cylinder_color(cylinder: Node3D, start_color: Color, end_color: Color, progress: float):
    var mesh_instance = find_mesh_instance(cylinder)
    if mesh_instance:
        var color = start_color.lerp(end_color, progress)
        mesh_instance.set_instance_shader_parameter("emissive_color", color)
    else:
        push_error("Could not find MeshInstance3D in update_cylinder_color().")

func _process(delta: float):
    var current_time = Time.get_ticks_msec() / 1000.0
    time_since_last_shot = current_time - last_shot_time

    if is_shooting:
        time_since_last_shot += delta
        if time_since_last_shot >= fire_rate:
            shoot_bullet()
            time_since_last_shot = 0.0
    else:
        handle_recoil_recovery(delta)

    apply_recoil_to_player(delta)
    update_debug_cylinders()

func update_recoil(delta: float, current_time: float):
    var recoil_duration = current_time - recoil_start_time
    var recoil_progress = min(recoil_duration / recoil_increase_duration, 1.0)
    var curve_value = recoil_curve_time.sample_baked(recoil_progress)
    
    # Calculate recoil increment
    var recoil_increment = recoil_force * curve_value * delta
    recoil_accumulation += recoil_increment
    recoil_accumulation = min(recoil_accumulation, max_recoil)
    
    # Calculate recoil offset
    var local_back_direction = -player.global_transform.basis.z * recoil_accumulation
    current_recoil_offset = local_back_direction.length()
    current_recoil_offset = clamp(current_recoil_offset, 0, max_recoil)

    # Apply recoil to the gun's rotation
    if gun_node and recoil_noise_texture:
        noise_sample_x += recoil_noise_speed * recoil_frequency * delta
        var noise_value = recoil_noise_texture.get_image().get_pixelv(Vector2(int(noise_sample_x) % recoil_noise_texture.get_width(), 0)).r * 2.0 - 1.0
        var recoil_angle = noise_value * recoil_amplitude * max(curve_value, 0.1)
        gun_node.rotate_y(deg_to_rad(recoil_angle))
        var max_rotation = deg_to_rad(max_recoil * curve_value)
        gun_node.rotation.y = clamp(gun_node.rotation.y, initial_gun_rotation.y - max_rotation, initial_gun_rotation.y + max_rotation)

func apply_recoil_to_player(delta: float):
    if player:
        var recoil_direction = -player.global_transform.basis.z
        var recoil_offset = recoil_direction * current_recoil_offset * delta
        player.global_translate(recoil_offset)

func shoot():
    var current_time = Time.get_ticks_msec() / 1000.0
    if current_time - last_shot_time >= fire_rate:
        shoot_bullet()
        last_shot_time = current_time
        # Reset recoil accumulation when starting a new burst
        if not is_shooting:
            recoil_accumulation = 0.0

func handle_recoil_recovery(delta: float):
    if is_recovering:
        var current_time = Time.get_ticks_msec() / 1000.0
        var recovery_progress = (current_time - recovery_start_time) / recoil_mouse_up_recovery_time
        
        if recovery_progress >= 1.0:
            is_recovering = false
            recoil_accumulation = 0.0
            current_recoil_offset = 0.0
            if gun_node:
                gun_node.rotation = initial_gun_rotation
            reset_noise_sampling()
        else:
            var recovery_curve_value = recoil_mouse_up_curve.sample_baked(recovery_progress)
            recoil_accumulation = lerp(recoil_accumulation, 0.0, recovery_curve_value * delta)
            current_recoil_offset = lerp(current_recoil_offset, 0.0, recovery_curve_value * delta)
            
            if gun_node:
                gun_node.rotation = gun_node.rotation.lerp(initial_gun_rotation, recovery_curve_value * delta)

func shoot_bullet():
    var muzzle_transform = muzzle_node.global_transform
    var forward_direction = muzzle_transform.basis.z.normalized()

    var rng = RandomNumberGenerator.new()
    rng.randomize()

    # Calculate the base spread angle between bullets
    var base_spread_angle = spread_count_angle / max(1, spread_count_bullet - 1)

    for i in range(spread_count_bullet):
        var bullet_seed = rng.randi()
        var bullet_rng = RandomNumberGenerator.new()
        bullet_rng.seed = bullet_seed

        # Calculate the spread angle for this bullet
        var spread_angle = (i - (spread_count_bullet - 1) / 2.0) * base_spread_angle
        var random_angle_variation = bullet_rng.randf_range(-spread_count_randomize_angle, spread_count_randomize_angle)
        var final_spread_angle = spread_angle + random_angle_variation
        
        var angle_offset = deg_to_rad(final_spread_angle)
        var random_rotation = bullet_rng.randf() * TAU

        # Calculate spread direction
        var spread_direction = Quaternion(muzzle_transform.basis.y, angle_offset) * forward_direction
        spread_direction = Quaternion(forward_direction, random_rotation) * spread_direction

        # Ensure spread_direction is not zero
        if spread_direction.is_equal_approx(Vector3.ZERO):
            spread_direction = forward_direction  # Use a default direction

        # Calculate recoil angle
        var recoil_noise_sample = bullet_rng.randf() * recoil_noise_texture.get_width()
        var recoil_noise_value = recoil_noise_texture.get_image().get_pixelv(Vector2(int(recoil_noise_sample) % recoil_noise_texture.get_width(), 0)).r * 2 - 1
        var bullet_recoil_angle = recoil_noise_value * recoil_amplitude * get_recoil_value()
        spread_direction = Quaternion(muzzle_transform.basis.y, deg_to_rad(bullet_recoil_angle)) * spread_direction

        var bullet = bullet_scene.instantiate()
        if bullet:
            get_tree().root.add_child(bullet)
            bullet.global_transform.origin = muzzle_node.global_transform.origin
            
            # Set bullet rotation
            bullet.global_transform = bullet.global_transform.looking_at(
                bullet.global_transform.origin + spread_direction, 
                Vector3.UP
            )

            # Set velocity
            if bullet.has_method("set_velocity"):
                var velocity = spread_direction.normalized() * bullet_speed
                bullet.set_velocity(velocity)

            if bullet.has_method("set_bullet_owner"):
                bullet.set_bullet_owner(player)
            if bullet.has_method("set_damage"):
                bullet.set_damage(bullet_damage)
            if bullet.has_method("set_knockback"):
                bullet.set_knockback(knockback)
            if bullet.has_method("set_lifetime"):
                bullet.set_lifetime(3.0)

    # Calculate and apply recoil
    var recoil_force_forward = -forward_direction * get_recoil_value()
    apply_recoil(forward_direction)
    emit_signal("gun_fired", recoil_force_forward)

    # Update noise sample position
    noise_sample_x = fmod(noise_sample_x + recoil_frequency, float(recoil_noise_texture.get_width()))

func apply_recoil(direction: Vector3):
    is_recovering = false  # Reset recovery when new recoil is applied
    
    var recoil_value = get_recoil_value()
    
    # Calculate recoil offset
    var local_back_direction = player.to_local(direction) * -recoil_value
    current_recoil_offset = local_back_direction.length()
    current_recoil_offset = clamp(current_recoil_offset, 0, max_recoil)

    # Apply recoil to the gun's rotation
    if gun_node and recoil_noise_texture:
        # Use recoil_noise_speed to control the sampling rate
        noise_sample_x += recoil_noise_speed * recoil_frequency * (recoil_value / max_recoil)
        noise_sample_y += recoil_noise_speed * recoil_frequency * (recoil_value / max_recoil) * 0.7  # Slightly different rate for Y
        
        # Sample the normal map texture
        var texture_size = recoil_noise_texture.get_width()  # Assuming square texture
        var sample_pos = Vector2(
            fmod(noise_sample_x, float(texture_size)) / float(texture_size),
            fmod(noise_sample_y, float(texture_size)) / float(texture_size)
        )
        var normal = recoil_noise_texture.get_image().get_pixelv(sample_pos * texture_size)
        
        # Convert normal map values from [0, 1] to [-1, 1] range
        var recoil_x = (normal.r * 2.0 - 1.0) * recoil_amplitude * (recoil_value / max_recoil)
        var recoil_y = (normal.g * 2.0 - 1.0) * recoil_amplitude * (recoil_value / max_recoil)
        
        # Apply recoil rotation
        gun_node.rotate_y(deg_to_rad(recoil_x))
        gun_node.rotate_x(deg_to_rad(recoil_y))
        
        # Clamp rotation to prevent excessive recoil
        var max_rotation = deg_to_rad(recoil_value)
        gun_node.rotation.y = clamp(gun_node.rotation.y, initial_gun_rotation.y - max_rotation, initial_gun_rotation.y + max_rotation)
        gun_node.rotation.x = clamp(gun_node.rotation.x, initial_gun_rotation.x - max_rotation, initial_gun_rotation.x + max_rotation)

func apply_recoil_force(delta: float):
    # Apply translation recoil to player
    if player:
        player.translate(Vector3(0, 0, -current_recoil_offset * delta))

    # Apply Y-axis recoil to gun_node rotation
    # if gun_node:
        # gun_node.rotate_y(current_recoil_rotation_y * delta)

func reset_recoil():
    if not is_recovering:
        is_recovering = true
        recovery_start_time = Time.get_ticks_msec() / 1000.0
    emit_signal("recoil_reset")

func get_recoil_value() -> float:
    var curve_time = min(time_since_last_shot / recoil_increase_duration, 1.0)
    var curve_value = recoil_curve_time.sample_baked(curve_time)
    return curve_value * max_recoil

func reset_noise_sampling():
    noise_sample_x = 0.0
    noise_sample_y = 0.0

func trigger_pressed(direction: Vector2):
    is_trigger_pressed = true
    shoot_direction = direction
    is_shooting = true

func trigger_released():
    is_trigger_pressed = false
    shoot_direction = Vector2.ZERO
    is_shooting = false
    reset_recoil()