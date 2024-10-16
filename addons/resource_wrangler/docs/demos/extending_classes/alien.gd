class_name Alien
extends Resource

## The metadata all goes into this method:
static func rw_metadata():
	return {
	&"display_class_name_as" : &"An Alien", # What appears on the node itself
	&"category" : &"Aliens", # Optional
	&"partial_save_name" : &"alien", # influence the resource filename
	&"noinstance" : false # true would exclude this resource from the graph.
	}

@export var name:String = "Gorzak"

func _init() -> void:
	print("Alien ", name, " spawns")
