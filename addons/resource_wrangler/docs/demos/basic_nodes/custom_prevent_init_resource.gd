class_name ARes
extends Resource

## Shows how to prevent the _init from running by accident while
## in the editor.

@export var name:String = "changed"

func _init() -> void:
	# How to prevent unwanted init in-engine
	if Engine.is_editor_hint(): return

	# In-game stuff
	print("I spawn ", name)
