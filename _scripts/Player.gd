# This script is for movement (attached to the Player (CharacterBody3D))
extends CharacterBody3D

@export var SPEED: float = 6.0
@export var rotation_speed: float = 10.0
@export var min_rotation_speed: float = 0.1

@onready var camera: Camera3D = get_node("/root/Main/GameCamera")
@onready var navigation_region: NavigationRegion3D = get_node("/root/Main/NavigationRegion3D")
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var initial_touch_position: Vector2 = Vector2.ZERO
var is_touching: bool = false
var initial_ground_position: Vector3 = Vector3.ZERO

@onready var debug_touch: Node3D = get_node("/root/Main/debug_touch")
