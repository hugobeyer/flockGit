extends Node3D

@export var player_path: NodePath
@export var offset: Vector3 = Vector3(0, 2, 0)
@export var smoothness: float = 5.0

var player: Node3D

func _ready():
	player = get_node(player_path)

func _process(delta):
	if player:
		var target_position = player.global_position + offset
		global_position = global_position.lerp(target_position, smoothness * delta)