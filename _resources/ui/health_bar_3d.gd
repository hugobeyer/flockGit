extends Sprite3D

var progress: float = 1.0

func set_progress(value: float):
    progress = clamp(value, 0.0, 1.0)
    update_bar()

func update_bar():
    # Assuming the texture is 100 pixels wide
    region_rect.size.x = progress * 100
    region_enabled = true

func _ready():
    update_bar()
