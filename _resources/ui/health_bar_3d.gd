extends Sprite3D

@export var progress: float = 1.0:
    set(value):
        progress = clamp(value, 0.0, 1.0)
        _update_bar()

func _ready():
    health = max_health
    update_health_bar()  # Add this line
    _update_bar()

func _update_bar():
    if texture:
        region_rect.size.x = texture.get_width() * progress
        region_enabled = true
