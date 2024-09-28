extends Node

var player: Node3D
var shield: Node3D

func _ready():
	call_deferred("_initialize_references")

func _initialize_references():
	await get_tree().root.ready
	player = get_tree().get_first_node_in_group("player")
	shield = get_tree().get_first_node_in_group("shield")
	if not player:
		push_error("Player not found in scene tree")
	if not shield:
		push_error("Shield not found in scene tree")

func get_player() -> Node3D:
	return player

func get_shield() -> Node3D:
	return shield
