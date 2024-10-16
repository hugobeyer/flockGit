class_name Plant
extends Resource

## The metadata all goes into this method:
static func rw_metadata():
	return {
	&"display_class_name_as" : &"A Plant", # What appears on the node itself
	&"category" : &"Plants", # Optional
	&"partial_save_name" : &"plant", # influence the resource filename
	&"noinstance" : false # true would exclude this resource from the graph.
	}


@export var name:String = "default"

func _init() -> void:
	print("Plant ", name, " spawns")
