class_name rwMetadataExample
extends Resource

## The metadata all goes into this method. You can also override it
## in inheritors of this class to change the details.
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Custom Name", # What appears on the node itself
	&"category" : &"Custom Category", # Optional
	&"partial_save_name" : &"something", # influence the resource filename
	&"noinstance" : false # true would exclude this resource from the graph.
	}

@export var name:String = "default"

func _init() -> void:
	print("I spawn ", name)
