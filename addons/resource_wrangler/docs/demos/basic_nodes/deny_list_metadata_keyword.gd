@tool
class_name DemoOfDenyList
extends Resource

## The metadata all goes into this method. You can also override it
## in inheritors of this class to change the details.
static func rw_metadata():
	return {
	&"display_class_name_as" : &"Reject Demo", # What appears on the node itself
	&"deny_list" : [&"ArrayMesh", &"StandardMaterial3D"]
	}

@export_group("Plug any Resource in, but it will refuse MeshInstance3D and Material ")
@export var Stuff:Array[Resource]
