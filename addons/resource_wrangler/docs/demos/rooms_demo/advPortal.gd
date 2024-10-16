@icon("resources/adventure_door.cleaned.svg")
class_name advPortal
extends Resource

## Adventure Portal

## The metadata all goes into this method. You can also override it
## in inheritors of this class to change the details.
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Adventure Portal",
	&"category" : &"Adventure Demo",
	}

@export var name:String
@export var desc:String
@export var locked:bool

@export var spaces:Array[advSpace]
