extends Node3D

@export var spawn_scene: PackedScene  # The scene to spawn
@export var player: Node3D  # The player node
@export var min_radius: float = 10.0  # Minimum distance from player
@export var max_radius: float = 20.0  # Maximum distance from player
@export var spawn_count: int = 5  # Number of spawn points
@export var respawn_time: float = 5.0  # Time in seconds before respawning
@export var pursuit_speed: float = 5.0  # Speed at which boxes pursue the player

var spawn_points: Array[Vector3] = []
var spawned_objects: Array[Node3D] = []

func _ready():
    if not player:
        player = get_tree().get_root().get_node("Main/Player")
    if not player:
        push_error("Player not found!")
        return

    generate_spawn_points()
    spawn_new_wave()

func generate_spawn_points():
    spawn_points.clear()
    for i in range(spawn_count):
        var angle = randf() * 2 * PI
        var radius = randf_range(min_radius, max_radius)
        var x = cos(angle) * radius
        var z = sin(angle) * radius
        spawn_points.append(Vector3(x, 0, z) + global_position)

func spawn_new_wave():
    for object in spawned_objects:
        if is_instance_valid(object):
            object.queue_free()
    spawned_objects.clear()
    
    create_objects()
    get_tree().create_timer(respawn_time).timeout.connect(spawn_new_wave)

func create_objects():
    for point in spawn_points:
        var object = spawn_scene.instantiate()
        if not object is Enemy:
            push_error("Spawned scene must be an Enemy or inherit from Enemy.")
            object.queue_free()
            continue
        
        add_child(object)
        object.global_position = point
        
        # Set up collision layers and masks
        object.collision_layer = 0b10  # Layer 2 for enemies
        object.collision_mask = 0b101  # Mask for layers 1 (player) and 3 (environment)
        
        # Set up the enemy
        object.player = player
        object.speed = pursuit_speed
        
        if object.has_node("NavigationAgent3D"):
            object.get_node("NavigationAgent3D").set_target_position(player.global_position)
        
        spawned_objects.append(object)
        print("Spawned enemy at: ", point)

# Remove the update_objects function, as the enemy will handle its own movement
func _process(delta):
    # This function can be removed if it's not needed for other purposes
    pass

# ... rest of your code ...
