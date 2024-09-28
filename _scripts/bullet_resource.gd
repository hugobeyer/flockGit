extends Resource
class_name BulletResource  # This registers the class so you can reference it in other scripts

@export var mesh: Mesh
@export var material: Material
@export var bullet_speed: float = 50.0
@export var bullet_lifetime: float = 5.0
