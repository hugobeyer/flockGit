@icon("resources/adventure_room.cleaned.svg")
class_name advSpace
extends Resource

## Adventure Space
##
## This is a class that *is* a Resource

## The metadata all goes into this method. You can also override it
## in inheritors of this class to change the details.
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Adventure Space",
	&"category" : &"Adventure Demo",
	}

## Name
@export var name:String

## Description
@export var desc:String
