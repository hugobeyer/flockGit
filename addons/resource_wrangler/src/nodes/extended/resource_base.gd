@tool
class_name rwExtendedResourceBase
extends Resource

## Extend this class when you need a Resource
## That has extra gui things to draw *after*
## all the resource slots.

var SLOT_SCENE:Control

## If the gui is not instanced, do so
## Add it to the node parent
func show_node_gui(graphnode:GraphNode, SCENE_PRELOAD) -> void:
	#SCENE_PRELOAD can be a boolean (false) when it's called
	#directly from thing_node.gd during from_serialized
	#This means there is no override of this func, so we can catch that
	#by this check:
	if not SCENE_PRELOAD: return

	SLOT_SCENE = graphnode.get_node_or_null("Extension")
	if not SLOT_SCENE:
		SLOT_SCENE = SCENE_PRELOAD.instantiate()
		graphnode.add_child(SLOT_SCENE)
