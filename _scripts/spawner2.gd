extends Node3D

@export var player: Node3D  # Reference to the player node
@export var spawn_scene: PackedScene  # The scene to spawn
@export var min_radius: float = 10.0  # Minimum distance from player
@export var max_radius: float = 20.0  # Maximum distance from player
@export var spawn_count: int = 10  # Number of spawn points
@export var respawn_time: float = 30.0  # Time in seconds before respawning
@export var pursuit_speed: float = 5.0  # Speed at which boxes pursue the player

var spawn_points: Array[Vector3] = []
var spawned_objects: Array[Node3D] = []

func _ready():
    if not player:
        push_error("Player node not set in Spawner2. Please set it in the Inspector.")
        return
    if not spawn_scene:
        push_error("Spawn scene not set in Spawner2. Please set it in the Inspector.")
        return

    var timer = Timer.new()
    add_child(timer)
    timer.connect("timeout", Callable(self, "spawn_new_wave"))
    timer.set_wait_time(respawn_time)
    timer.set_one_shot(false)
    timer.start()

    spawn_new_wave()

func _process(delta):
    if player:
        update_objects(delta)

func spawn_new_wave():
    scatter_spawn_points()
    create_objects()

func scatter_spawn_points():
    if not player:
        return
    spawn_points.clear()
    for i in range(spawn_count):
        var random_angle = randf() * TAU
        var random_radius = randf_range(min_radius, max_radius)
        var offset = Vector3(cos(random_angle), 0, sin(random_angle)) * random_radius
        spawn_points.append(player.global_position + offset)

func create_objects():
    for point in spawn_points:
        var object = spawn_scene.instantiate()
        if not object is Node3D:
            push_error("Spawned scene must inherit from Node3D.")
            object.queue_free()
            continue
        
        add_child(object)
        object.global_position = point
        # Adjust Y position if the object has a size property
        if object.has_method("get_size"):
            object.global_position.y += object.get_size().y / 2
        spawned_objects.append(object)

func update_objects(delta):
    for object in spawned_objects:
        if is_instance_valid(object):
            # Orient towards player
            object.look_at(player.global_position, Vector3.UP)
            
            # Move towards player
            var direction = (player.global_position - object.global_position).normalized()
            object.global_position += direction * pursuit_speed * delta
            
            # Maintain Y position if the object has a size property
            if object.has_method("get_size"):
                object.global_position.y = object.get_size().y / 2

# ... rest of your code ...
