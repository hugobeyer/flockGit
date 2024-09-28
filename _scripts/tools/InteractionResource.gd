class_name InteractionResource
extends Resource

@export var interactions: Array:
    get:
        return interactions
    set(value):
        interactions = value.filter(func(item): return item is InteractionData)

func _init():
    interactions = []
