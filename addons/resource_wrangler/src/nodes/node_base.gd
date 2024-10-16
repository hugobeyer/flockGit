@tool
class_name rwNodeBase
extends GraphNode

#const NSrw = preload("../../ns.gd")

## slots array
var slots:Array[Dictionary]

func get_slot_dict(port:int)->Dictionary:
	if port in range(0,slots.size()):
		return slots[get_input_port_slot(port)]
	assert(false, "%s port is not in the slots array" % port)
	return {}


# This was here to test drag/drop form a node to the inspector
# etc. So far so crashy.
#var dummyPreview : ColorRect
#var _draggo:=false
#
#func _process(delta: float) -> void:
	#if _draggo:
		#force_drag("Some data", dummyPreview)
	#else:
		#if is_instance_valid(dummyPreview):
			#if not dummyPreview.is_queued_for_deletion():
				#dummyPreview.queue_free()
#
#func _gui_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton:
		#if event.is_pressed():
			#if event.button_index == 1:
				#if not _draggo:
					#print("drag?")
					#dummyPreview = ColorRect.new()
					#dummyPreview.size = Vector2(50,50)
					#dummyPreview.color = Color(1,0,0,1)
					#_draggo = true
		#else:
			#print("drop?")
			#_draggo = false
