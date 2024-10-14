# _scripts/ai/formation_manager.gd
extends Node3D

enum FormationType {NONE, DIAMOND, LINE, SCATTERED}

var enemy_formations: Dictionary = {}

func _ready():
    # Connect to the enemy_spawned and enemy_killed signals
    if SignalBus.has_signal("enemy_spawned"):
        SignalBus.connect("enemy_spawned", Callable(self, "add_enemy"))
    else:
        push_error("Signal 'enemy_spawned' does not exist.")
    
    if SignalBus.has_signal("enemy_killed"):
        SignalBus.connect("enemy_killed", Callable(self, "remove_enemy"))
    else:
        push_error("Signal 'enemy_killed' does not exist.")

func _process(delta):
    update_formations()

func add_enemy(enemy: CharacterBody3D):
    if enemy:
        var formation_type = determine_formation_type(enemy)
        enemy_formations[enemy] = formation_type

func remove_enemy(enemy: CharacterBody3D):
    if enemy_formations.has(enemy):
        enemy_formations.erase(enemy)

func update_formations():
    for enemy in enemy_formations.keys():
        if enemy:
            var offset = get_formation_offset(enemy)
            enemy.formation_target = enemy.global_position + offset

func get_formation_offset(enemy: CharacterBody3D) -> Vector3:
    var formation_type = enemy_formations.get(enemy, FormationType.NONE)
    var enemies_in_formation = enemy_formations.keys().filter(func(e): return enemy_formations[e] == formation_type)
    var index = enemies_in_formation.find(enemy)
    
    match formation_type:
        FormationType.DIAMOND:
            return diamond_formation(index)
        FormationType.LINE:
            return line_formation(index)
        FormationType.SCATTERED:
            return scattered_formation(index)
        _:
            return Vector3.ZERO

func determine_formation_type(enemy: CharacterBody3D) -> FormationType:
    if enemy.is_in_group("naked_imp"):
        return FormationType.SCATTERED
    elif enemy.is_in_group("fast_imp"):
        return FormationType.LINE
    elif enemy.is_in_group("shielded_imp"):
        return FormationType.DIAMOND
    else:
        return FormationType.NONE

func diamond_formation(index: int) -> Vector3:
    var row = int(sqrt(index))
    var col = index - (row * row)
    return Vector3(col * 2.0, 0, row * 2.0)

func line_formation(index: int) -> Vector3:
    return Vector3(index * 2.0, 0, 0)

func scattered_formation(index: int) -> Vector3:
    var noise = FastNoiseLite.new()
    noise.seed = index
    return Vector3(noise.get_noise_2d(index, 0) * 5.0, 0, noise.get_noise_2d(0, index) * 5.0)
