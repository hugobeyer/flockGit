@tool
@icon("../../assets/resource_wrangler_icon_32x32.small.svg")
# icon does not show :(
class_name rwBoardDatabaseResource
extends Resource

## Database of ONE board
##
## The class_name is intended to be private to this file only.
## I need it for types **within** this script.
## I have done this to prevent using NSrw.rwBoardDatabase here because
## that was causing mystery segfaults. Cyclic dependency I imagine.


# MIT License
#
# Copyright (c) 2023 Donn Ingle (donn.ingle@gmail.com)
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


var id:String = "":
	get:
		var _id = resource_path.\
				get_file().\
				replace(".tres","").\
				replace("res://","")
		return _id

@export var board_zoom:float = 1.0
@export var scroll_offset:= Vector2.ZERO
#@export var board_path:String = ""
@export var nodes_data:Dictionary
@export var connections:Array

# trying to allow users to create boards outside of RW
# TODO: This is still buggy
@export var board_created_outside_rw := true


## Do this directly after new()
func set_new_paf(new_bpaf:String):
	#board_path = new_bpaf
	#print("new id:", id)
	#print("take over path:", new_bpaf)
	take_over_path(new_bpaf)


## Rename the board file
func rename(new_name:String, force:=false):
	if new_name != id or force:
		var _id:String # new id, basically
		_id = new_name.replace(".tres","")
		var rp:String
		if resource_path.is_empty(): # This case is mysterious
			rp = "res://unknown_%s_.tres" % new_name # can't use _id here
		else:
			rp = resource_path.get_base_dir()
			rp = rp + "/" + _id + ".tres"
			DirAccess.rename_absolute(resource_path, rp)

		take_over_path(rp)
		dbatGeneralUtils.refresh_filesystem(rp)

#Replaced Sep 4 2024
#func OLDrename(new_name:String, force:=false):
	#if new_name != id or force:
		#var _id:String # new id, basically
		#_id = new_name.replace(".tres","")
		#var rp:String
		#if resource_path:
			#rp = resource_path.get_base_dir()
			## rm the old file.
			#var oldpaf = resource_path
			#DirAccess.remove_absolute(oldpaf) # gulp
		#if not rp:
			#rp = "res://unknown_%s_.tres" % new_name # can't use _id here
		#else:
			#rp = rp + "/" + _id + ".tres"
		##DirAccess.rename_absolute(oldpaf, rp)
		#take_over_path(rp)
		#dbatGeneralUtils.refresh_filesystem(rp)


func save(board, name:String):
	## Save all the node's resources
	## There's a bug in Godot (Feb 2024) so I am
	## forced to do this
	board.save_all_node_resources()

	## Now save the rest of the board
	var data = board.to_serialized()
	board_zoom = data.zoom
	scroll_offset = data.scroll_offset
	nodes_data.clear() # to avoid duplicates and old cruft
	for nod in data.rwnodes:
		nodes_data[nod.id] = nod
	connections = data.connections
	## 31 = ERR_INVALID_PARAMETER
	## 15 = ERR_FILE_UNRECOGNIZED
	# PS.resource_path is empty here
	#print()
	#print("Saving board")
	#print("  nodes_data:", nodes_data.values())
	#for _n in nodes_data.values():
		#print("  node.resource.resource_path = ", _n.resource.resource_path)
		#for nam in _n.resource.get_property_list():
			#print("  ", nam.name, " = ", _n.resource.get(nam.name))
	#print()
	#print(str(get_property_list()).replace("}, {","\n"))
	#return

	board_created_outside_rw = false

	var err := ResourceSaver.save(self, "", ResourceSaver.FLAG_CHANGE_PATH)
	if err != OK:
		assert(false, "Error number %s saving the board file." % err)
	dbatGeneralUtils.refresh_filesystem()


static func load(board_paf:String) -> rwBoardDatabaseResource:
	#print("load:", board_paf)
	var test_load:rwBoardDatabaseResource = load(board_paf)
	#test_load.id = board_paf.get_file().get_basename().replace(".tres","")
	if test_load == null:
		return null
	rwSettings.add_to_recent_boards(board_paf)
	return test_load
