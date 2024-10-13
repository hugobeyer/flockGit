extends Node

@onready var label_kills: Label = $PathToLabelKills

func _ready():
    SignalBus.connect("enemy_killed", Callable(self, "_on_enemy_killed"))

func _on_enemy_killed(_enemy):
    # The label_kills node will handle updating itself
    pass
