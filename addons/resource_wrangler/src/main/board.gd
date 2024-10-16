@tool
extends GraphEdit

##region licence
# MIT License
#
# Copyright (c) 2023 Donn Ingle (donn.ingle@gmail.com)
# Copyright (c) 2022 Nathan Hoad
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
##endregion


## Have been renaming slowly. The old word "things" mostly refers to rwNodes.
## May 2024 : Sorted public and private funcs apart.

signal popup_outmenu_request
signal board_tres_dropped(res)

# CHOP is all about the RMB noodle chopping UI to break connections.
enum CHOP{NONE, DRAWING, STOPPEDDRAWING, PROCESSING}

const NODE_SIZE := Vector2(150, 80)
const verbose_await := false
const verbose_foo := false


var map_id_to_rwnode: Dictionary = {}
var undo_redo: EditorUndoRedoManager
var main_view # directly reffed from other classes.
var editor_plugin: EditorPlugin
var map_resource_to_rwnodes_list = {}
## 'discon' lambda is for use on the force_disconnect signal (see rwnode) handler.
## it's for when a resource node wants to force a disconnect.
var discon
var ctrl_pressed:bool

var _ed_settings = EditorInterface.get_editor_settings()
var _chopstate:CHOP = CHOP.NONE
var _bgstyle:StyleBoxFlat = NSrw.graph_bgstyle
#var _editor_resource_picker := EditorResourcePicker.new()
var _current_chooser:rwChooserBase
var _chooser_situation = {}
var _selected_rwnode_name : String
var _FileSysDock : FileSystemDock
var _ll=[]

# helps prevent irksome focus issues between inspector
# and board and other views. E.g. when you select say a Node3D
# it should not suddenly swap the inspector to an rwnode should
# you edit that Node3D in the inspector.
var focus_is_on_board := true


# these are to do with dragging a resource (from an out noodle)
# to some resource slot in the Inspector.
var _dragging_a_resource:=false
var _dragging_data = {}
var _drag_resource_to_inspector_preview : TextureRect


@onready var out_menu := $OutmenuPopup
@onready var save_extended_class:FileDialog
@onready var node_menu := %node_menu


# -------------- VIRTUAL FUNCS --------------------


func _ready() -> void:
	show_zoom_label = true
	node_menu.board = self
	save_extended_class = dbatGeneralUtils.mk_file_dialog(
		["*.gd"], FileDialog.FILE_MODE_SAVE_FILE)
	add_child(save_extended_class)
	save_extended_class.file_selected.connect(_on_filedialogue_file_selected)
	apply_graph_settings()
	## Only way I could think to make sure that all out ports can connect to
	## a generic "Resource" type input port.
	var shres = dbatGeneralUtils.smallhash("Resource")
	for i in range(0,514):
		add_valid_connection_type(i, shres)
		add_valid_connection_type(513,i) #slot 0 IN and OUT can connect

	var inspect = EditorInterface.get_inspector()
	#_last_object_in_inspector = inspect.get_edited_object()

func _exit_tree() -> void:
	clear()
	# Trying to stop a segfault by manually removing the FileDialog
	# This was a Godot bug that was fixed, but I have not returned
	# to using the FileDialog Node since.
	remove_child(save_extended_class)
	map_id_to_rwnode.clear()
	clear_connections()


func _can_drop_data(position, dropped_data):
	return true


func _drop_data(position, dropped_data):
	#print("***DROPPED:", dropped_data)
	dropped_data.erase("from") # else crashes project.godot file.
	dropped_data["drop_pos"] = position
	call_deferred("_something_was_dropped", dropped_data)


# -------------- PUBLIC FUNCS --------------------


## Called from main_view.gd
func setup(_main_view):
	self.main_view = _main_view
	self.editor_plugin = _main_view.editor_plugin
	self._FileSysDock = _main_view.FileSysDock
	_style_bg()
	# Watch for moved files
	_FileSysDock.files_moved.connect(_file_changed_board, CONNECT_REFERENCE_COUNTED)


## Fetch some settings for the graph - called from main_view.gd
func apply_graph_settings() -> void:
	minimap_enabled = rwSettings.get_setting(&"minimap_enabled", false)
	minimap_size = rwSettings.get_setting(&"minimap_size", Vector2(200, 150))
	snapping_enabled = rwSettings.get_setting(&"snapping_enabled", true)
	snapping_distance = rwSettings.get_setting(&"snapping_distance", 20)

##  Save the graph - called from main_view.gd
func save_graph_settings():
	rwSettings.save_setting(&"minimap_enabled", minimap_enabled)
	rwSettings.save_setting(&"minimap_size", minimap_size)
	rwSettings.save_setting(&"snapping_enabled", snapping_enabled)
	rwSettings.save_setting(&"snapping_distance", snapping_distance)


## Erase all my nodes and connections - also called from main_view.gd
func clear() -> void:
	clear_connections()
	for nod in map_id_to_rwnode.values():
		remove_child(nod)
		nod.free()
	map_id_to_rwnode.clear()
	map_resource_to_rwnodes_list.clear()


## Bundle-up all my pertinent info into a dict
## Also called from board_data.gd
func to_serialized() -> Dictionary:
	var editor_scale: float = _get_editor_scale()
	var serialized_things: Array = []
	for gnode in map_id_to_rwnode.values():
		var d = gnode.to_serialized(editor_scale)
		serialized_things.append(d)
	var serialized_connections: Array = []
	for connection in get_connection_list():
		serialized_connections.append({
			from = connection.from_node,
			from_port = connection.from_port,
			to = connection.to_node,
			to_port = connection.to_port
		})
	#print("save scroll_offset as:", scroll_offset / editor_scale)
	return {
		scroll_offset = scroll_offset,# / editor_scale,
		zoom = zoom,
		rwnodes = serialized_things,
		connections = serialized_connections
	}


## TODO Test if necc still.
## Save all the node's resources
## There's (was?) a bug in Godot (Feb 2024) so I am
## forced to do this. It was not saving in a spotty way.
## Called from board_data.gd
func save_all_node_resources():
	for gnode in map_id_to_rwnode.values():
		var _res = gnode.res
		ResourceSaver.save(_res)


## Unbundle a board from the saved dict.
## Called from main_view.gd
func from_serialized(board_data:NSrw.rwBoardDatabase) -> void:
	# There's some startup timing rwnode that causes a bunch of errors
	# making sure there's an editor_plugin here seems to stop that.
	if not editor_plugin: return
	clear()

	## Make all the rwnodes—partially
	for nodedat in board_data.nodes_data.values():
		if nodedat.get(&"resource", null):
			_mk_rwnode(nodedat)
		else:
			main_view.feedback("Node had no resource, skipping.", &"ERROR")

	## Now go through them all *again* and draw them
	for _n:rwNode in map_id_to_rwnode.values():
		if verbose_await:
			print("  BOARD await _n.draw_node():", _n.name)
		await _n.draw_node()
		if verbose_await:
			print("  BACK BOARD await :", _n.name)

	for conn in board_data.connections:
		connect_node(
				conn.from,
				conn.from_port,
				conn.to,
				conn.to_port)
	zoom = board_data.board_zoom
	var editor_scale: float = _get_editor_scale()
	scroll_offset = board_data.scroll_offset * editor_scale
	await fix_noodles()
	#print("Loaded scroll_offset:", scroll_offset)


## Sometimes the graph connections are pointing to the wrong position
## on resized map_id_to_rwnode. This forces it to rerender.
## Also called from main_view.gd
func fix_noodles():
	var num := map_id_to_rwnode.size()
	if  num < 1: return
	var _z = zoom
	# This on it's own does not work:
	#  zoom = 20
	#  await get_tree().process_frame
	#  zoom = _z
	#  return
	# Doing it in a loop which does more work forces
	# the noodles to do the right thing (mostly).
	# BTW: I tried setting board.visible off and on
	# but it prevents the very reason for this whole
	# func. So, now it zooms from small to the last
	# zoom and looks quite good!
	OS.low_processor_usage_mode = false
	var f : float = zoom/num
	for z in range(0, num):
		var zm:float = lerpf(0.1, z, f)
		zoom = zm
		await get_tree().process_frame
	OS.low_processor_usage_mode = true

	# Old "jiggle" version
	#if map_id_to_rwnode.size() > 0:
		#await get_tree().process_frame
		#var first_thing = map_id_to_rwnode[map_id_to_rwnode.keys()[0]]
		## Noticed a lot of errors like
		## SCRIPT ERROR: Invalid get index 'position_offset'
		## (on base: 'previously freed')
		## Hence:
		#if not first_thing:
			#return
		## And:
		#if first_thing.is_queued_for_deletion():
			#return
#
		#first_thing.position_offset += Vector2.UP
		#await get_tree().process_frame
		#first_thing.position_offset -= Vector2.UP


## Open the selected rwnode in the Inspector
## and connect a signal for `property_edited`
## Also called in rwnode.gd
## WARNING: I think there is a bug in Godot where the
## refcount to the inspected object just keeps climbing.
## I reported this: https://github.com/godotengine/godot/issues/83904
func inspect_node(something:Variant, force:=false):
	if something is String:
		something = map_id_to_rwnode.get(something, null)

	if is_instance_valid(something):
		if not force and _selected_rwnode_name == something.name:
			# we are already seeing this one
			return
	if something is GraphNode:
		var inspect = EditorInterface.get_inspector()
		#_last_object_in_inspector = inspect.get_edited_object()

		#print()
		#print("inspect")
		#print("  ", something.res.resource_path)

		#if inspect.is_connected("property_edited",_inspector_prop_edited):
			#inspect.property_edited.disconnect(_inspector_prop_edited)
		#inspect.property_edited.connect(_inspector_prop_edited)
		inspect.property_edited.connect(_inspector_prop_edited,
				CONNECT_REFERENCE_COUNTED)


		# Force the inspector to redraw!
		if force:
			EditorInterface.inspect_object(null) # yay works!

		# Now this darn thing works :) I wish I could control
		# read/write access in the inspector though.
		if is_instance_valid(something):
			# Honestly, atm, the don't get the diff between inspect_object
			# and edit_resource
			#EditorInterface.inspect_object(something.res, "", true)
			EditorInterface.edit_resource(something.res)


## DROP from an OUTPUT to empty space Part 2
## The out_menu has finished its job.
## Called from outmenu_popup_menu.gd
func new_custom_extended_resource_part2(
		name_of_thing_we_are_extending,
		thing_we_are_extending,
		_position):
	save_extended_class.set_meta("situation", {
		switch = &"class",
		rwnode = thing_we_are_extending,
		thing_name = name_of_thing_we_are_extending,
		position = _position
	})
	save_extended_class.visible = true # see _on_filedialogue_file_selected


## True if the resource is duplicated (not unique) i.e. it is a "clone"
## Also called in rwnode.gd
func detect_clone(res:Resource) -> bool:
	return map_resource_to_rwnodes_list[res].size() > 1


## Also called in rwnode.gd
func get_all_cloned_rwnodes_of(rwnode) -> Array:
	var _res = rwnode.res
	var _ret=[]
	# map_resource_to_rwnodes_list is a dict holding an array
	for rw in map_resource_to_rwnodes_list[rwnode.res]:
		#if rw != rwnode: # i.e. not myself
		if detect_clone(rw.res):
			_ret.append(rw)
	return _ret


func duplicate_as_clone(thing_list=[]):
	# Duplicate means make a new rwNode and put the same
	# insides into it/them.
	# Position them a little to one side
	# Select all the new duplicates
	if not thing_list:
		thing_list = get_selected_rwnodes()

	var dupes=[]
	undo_redo.create_action("Duplicated nodes")
	for orig_thing in thing_list:
		var id:String=""
		id = dbatGeneralUtils.get_random_id()
		_initial_add_thing_pattern(
			orig_thing.res,
			id,
			orig_thing.position_offset + Vector2(50,100),
			null, #to rwnode not needed here
			null, #to port not needed
			null, #from rwnode not needed
			false # noodle_flag
		)
		dupes.append(id)
	undo_redo.commit_action()

	# redraw selected nodes in case some are now clones
	for orig_thing in thing_list:
		orig_thing.if_clone_change_style()

	for id in dupes:
		map_id_to_rwnode[id].selected = true


## Normal Dup
func duplicate_as_unique(thing_list=[]):
	if not thing_list:
		thing_list = get_selected_rwnodes()

	## Loop and make each res unique.
	var dupes=[]
	undo_redo.create_action("Duplicated nodes as unique")
	for orig_thing in thing_list:
		var id:String=""
		id = dbatGeneralUtils.get_random_id()
		## Docs say: For custom resources, duplicate() will fail
		## if Object._init() has been defined with required parameters.
		## Eek... :O TODO
		var new_res_obj = orig_thing.res.duplicate()
		_save_automade_resource(id, new_res_obj)
		_initial_add_thing_pattern(
				new_res_obj,
				id,
				orig_thing.position_offset + Vector2(50,100),
				null, #to rwnode not needed here
				null, #to port not needed
				null, #from rwnode not needed
				false #no noodles needed either
				)
		dupes.append(id)
	undo_redo.commit_action()

	# redraw selected nodes in case some are now clones
	for orig_thing in thing_list:
		orig_thing.if_clone_change_style()

	for id in dupes:
		map_id_to_rwnode[id].selected = true


func get_selected_rwnodes() -> Array:
	var _sel := map_id_to_rwnode.values().filter(
			func(n):return n.selected)
	if _sel.is_empty(): _selected_rwnode_name = ""
	return _sel


## Called from a signal handler in rwnode
func show_in_filesystem(rwnode):
	var fsd:FileSystemDock = EditorInterface.get_file_system_dock()
	fsd.navigate_to_path(rwnode.res.resource_path)


## Also called from chooser_node.gd
## weird func. We don't need the param because there's only one
## chooser graphnode to close.
func close_chooser_rwnode():
	if is_instance_valid(_current_chooser):
		remove_child(_current_chooser)
		_current_chooser.queue_free()
		_current_chooser = null



# -------------- PRIVATE FUNCS --------------------


## Alter the bg color of the graph
func _style_bg():
	var bgcol:Color = _ed_settings.get_setting("interface/theme/base_color")
	bgcol = bgcol.darkened(0.5)
	_bgstyle.bg_color = bgcol


func _get_editor_scale() -> float:
	return EditorInterface.get_editor_scale()


func _mk_rwnode(data: Dictionary = {}) -> rwNodeBase:
	var id: String = data.id
	var editor_scale: float = _get_editor_scale()
	var rwnode = NSrw.BASE_NODE_SCENE.instantiate()

	add_child(rwnode)
	rwnode.setup(self, id, NODE_SIZE * editor_scale)
	map_id_to_rwnode[id] = rwnode

	## Connect some sigs
	rwnode.popup_menu_request.connect(_on_thing_popup_menu_request.bind(rwnode))
	rwnode.delete_request.connect(_on_thing_delete_request.bind(rwnode))

	var _res:Resource = data.get("resource", null)

	## I am tracking the resource refs manually
	## so I can know which ones are "clones" later on.
	if map_resource_to_rwnodes_list.has(_res):
		map_resource_to_rwnodes_list[_res].append(rwnode)
	else:
		map_resource_to_rwnodes_list[_res] = [rwnode] # start a new array in that key

	data["editor_scale"] = editor_scale
	rwnode.from_serialized(data)
	#print()
	#print("_mk_rwnode AFTER rwnode.from_ser:", _res.resource_path)

	return rwnode


## Couroutine TODO check on this
func _add_rwnode_and_draw(data: Dictionary = {}) -> void:
	var rwnode = _mk_rwnode(data)
	if rwnode:
		await rwnode.draw_node()
		set_selected(rwnode)
		inspect_node(rwnode)


## RMB Offers Duplicate and Make Unique options on a node
func _on_thing_popup_menu_request(at_position: Vector2, thing: GraphNode):
	thing.selected = true
	node_menu.popup_if_valid_at(DisplayServer.mouse_get_position())


func _on_node_deselected(node: Node) -> void:
	_selected_rwnode_name = ""


func _on_delete_nodes_request(nodenames: Array[StringName]) -> void:
	undo_redo.create_action("Deleted selected nodes")
	for nname in nodenames:
		var rwnode = map_id_to_rwnode[nname]
		var id = rwnode.name
		_undo_redo_connections(undo_redo, id)
		undo_redo.add_do_method(self, "_delete_rwnode", id)
		undo_redo.add_undo_method(self, "_add_rwnode_and_draw",
				map_id_to_rwnode.get(id).to_serialized(_get_editor_scale()))
	undo_redo.commit_action()


## The general "kind" means "class" or "resource" or "board_database"
## A class is a script we wrote, else it's a built-in resource
func _get_general_kind_from_a_path(pth:String)->String:
	var _kind:String = &"unknown"
	var obj
	#if pth.is_absolute_path():
	#	obj = Resource.new()
	#else:
	obj = load(pth)
	if obj:
		if obj is Script:
			_kind = &"class"
		elif obj is NSrw.rwBoardDatabase:
			_kind = &"board_database"
		elif obj is Resource:
			_kind = &"resource"
	return _kind


func _make_a_new_resource_and_rwnode(classname)->Dictionary:
	var id = dbatGeneralUtils.get_random_id()
	var paf = dbatClassHacks.lookup_script_paf_by_classname(classname)
	var newobj
	if paf == "":
		# It's NOT a custom script, because there is no path.
		# ∴ it's a built-in class ∴ we can use ClassDb.
		# There are a bunch of resources that simply crash Godot
		# `Image` is one example. There are also some that the docs
		# state cannot be instanced by new()
		# Thus, this test:
		if ClassDB.can_instantiate(classname):
			newobj = ClassDB.instantiate(classname)
		else:
			return {status=FAILED}
	else:
		newobj = load(paf).new()
	_save_automade_resource(id, newobj)
	var _kind:String
	_kind = _get_general_kind_from_a_path(newobj.get_path())
	assert(_kind != &"unknown", "That resource class has resulted in a weird sitch.")
	return {status=OK, id=id, new_resource_obj=newobj}


func _make_new_resource_from_chooser(classname:String):
	var result = _make_a_new_resource_and_rwnode(classname)
	if result.status == FAILED:
		return
	undo_redo.create_action("Added node from popup chooser")

	undo_redo.add_do_method(self, "_add_rwnode_and_draw",
	{
		id = result.id,
		position_offset = _at_cursor_pos(),#_center_window_calc(),
		resource = result.new_resource_obj,
	})
	undo_redo.add_undo_method(self, "_delete_rwnode", result.id)
	undo_redo.commit_action()


func _something_was_dropped(dropped_data):
	#print(dropped_data)
	var good_drop = dropped_data.keys().any(
			func(i): return i in ["files", "resource"]
			)
	if not good_drop:
		main_view.feedback("Can't open that file.", &"WARNING")
		return

	## My hack to allow opening a board by dropping the tres into the graph.
	var _kind:String
	if "files" in dropped_data:
		var _paf = dropped_data.files[0]
		if _get_general_kind_from_a_path(_paf) == &"board_database":
			board_tres_dropped.emit(load(_paf)) # Talks to main_view
			return

	var res:Resource = dropped_data.get("resource", null)
	if res:
		# if there is a resource then there's no `files` key, so make it:
		# This happens when you drop a resource from the inspector!
		dropped_data["files"] = [res.get_path()]

	var tile_pos:Vector2 = dropped_data.get(&"drop_pos", Vector2.ZERO)
	for drop in dropped_data.files:
		_kind = _get_general_kind_from_a_path(drop)
		if _kind != &"unknown":
			tile_pos += Vector2(20,20)
			var new_dropped_data = {
				gen_kind = _kind,
				files = [drop], # array is for legacy reasons
				drop_pos = tile_pos
			}
			_add_thing_where_dropped(new_dropped_data)


func _add_thing_where_dropped(dropped_data)->void:
	var id = dbatGeneralUtils.get_random_id()
	#print("dropped")
	#print(id)
	#print(dropped_data)
	#print()
	#return
	var resource_path:String
	var new_res_obj:Resource
	var paf = dropped_data.files[0]
	#print("dropped:", dropped_data)
	if dropped_data.gen_kind == &"class":
		# we use can_we_inst here because it may be a custom OR built-in class.
		if dbatClassHacks.can_we_instantiate(dbatClassHacks.get_class_name_by_paf(paf)):
			var tmp = load(paf).new()
			if not tmp is Resource:
				main_view.feedback("That script cannot be instanced.", &"WARNING")
				return
			new_res_obj = tmp
			_save_automade_resource(id, new_res_obj)
			if "resource_path" in new_res_obj:
				resource_path = new_res_obj.resource_path
		else:
			main_view.feedback("That script cannot be instanced.", &"WARNING")
			return
	else:
		# it's a resource file
		new_res_obj = load(paf)

	undo_redo.create_action("Added dropped node")
	_initial_add_thing_pattern(
		new_res_obj,
		id,
		_drop_pos_calc(dropped_data.drop_pos),
		null, #to rwnode not needed here
		null, #to port not needed
		null, #from rwnode not needed
		false #no noodles needed either
	)
	undo_redo.commit_action()


func _save_automade_resource(id, res):
	if not res is Resource:
		main_view.feedback("%s is not a Resource" % res, &"WARNING")
		return
	var classname = dbatClassHacks.get_classname_from_a_resource(res)
	if classname == dbatClassHacks.NO_CLASS_NAME:
		classname = "unknownclass"
	var nam : String
	var partial_name : Variant #nb
	partial_name = dbatClassHacks.get_metadata(classname, &"partial_save_name")
	if partial_name != null:
		nam = "%s_%s_%s" % [classname, partial_name, id]
	else:
		nam = "%s_%s" % [classname, id]

	var ext:String = "res" if dbatClassHacks.get_metadata(classname, &"save_as_res_file") else "tres"
	#res.resource_path = "%s/resources/%s.tres" % \
	res.resource_path = "%s/resources/%s.%s" % \
			[rwSettings.automade_path, nam, ext]
	rwSettings.ensure_dirs()
	if ResourceSaver.save(res) != OK:
		main_view.feedback("Saving to %s failed" % res.resource_path, &"ERROR")


## Abstracted-out some common code involved in making graph nodes
## Be sure to wrap this in undo_redo.create and commit action()
## BEFORE calling.
func _initial_add_thing_pattern(
	resource, id, _position, to, to_port, from_rwnode, noodle_flag):

	undo_redo.add_do_method(self, "_add_rwnode_and_draw",
		{	id = id,
			position_offset = _position,
			resource = resource,
		 })
	undo_redo.add_undo_method(self, "_delete_rwnode", id)

	# If we have noodles we want to draw them
	if noodle_flag:
		undo_redo.add_do_method(self,   "connect_node"   , id, 0, to, to_port)
		undo_redo.add_undo_method(self, "disconnect_node", id, 0, to, to_port)

		# Important call.
		# `noodle_flag` means we are connecting an rwnode to this one
		# therefore the `slot_changed` signal must fire.
		from_rwnode.slot_changed.emit()


func _at_cursor_pos()->Vector2:
	return (get_local_mouse_position() + scroll_offset) / _get_editor_scale() / zoom


func _drop_pos_calc(pos)->Vector2:
	return (scroll_offset + pos)\
	/ _get_editor_scale() / zoom - NODE_SIZE * Vector2(1, 0.5)


func _center_window_calc()->Vector2:
	var editor_scale: float = _get_editor_scale()
	return (scroll_offset / editor_scale + size /
	editor_scale * 0.5 - NODE_SIZE * 0.5) / zoom



## This is the func connected to 'delete_request' sig from an rwnode
## (connected in this file, around line 458.)
## which then calls the func directly below DEFERRED.
func _on_thing_delete_request(rwnode: GraphNode):
	call_deferred("_pre_delete_rwnode", rwnode.name)
# ^
# |
# time gap between these funcs
# I can't recall why, but here we are.
# |
# v
## Runs when a graph node is closed with the X button
func _pre_delete_rwnode(id: String) -> void:
	undo_redo.create_action("Deleted a node")
	undo_redo.add_do_method(self, "_delete_rwnode", id)
	undo_redo.add_undo_method(self, "_add_rwnode_and_draw",
			map_id_to_rwnode.get(id).to_serialized(_get_editor_scale()))
	_undo_redo_connections(undo_redo, id)
	undo_redo.commit_action()


## Does not delete connections (noodles)
func _delete_rwnode(id: String) -> void:
	var rwnode = map_id_to_rwnode.get(id)
	if is_instance_valid(rwnode):
		var _res:Resource = rwnode.res
		if _res:
			## Adjust the mapping of refs to this resource.
			map_resource_to_rwnodes_list[_res].erase(rwnode)
			# Disconnect the changed signal!
			# If this res is a clone (i.e. there is at least one other
			# node with this resource on the graph) then we should not
			# remove the signals because it's still in play.
			if not detect_clone(_res):
				var sigs = _res.get_signal_connection_list(&"changed")
				for sig in sigs:
					var _call:Callable = sig.callable
					var cname := _call.get_method()
					if cname in [&"_render_node_gui", &"do_work"]:
						_res.disconnect(&"changed", _call)
		rwnode.free()
		map_id_to_rwnode.erase(id)
		dbatGeneralUtils.reclaim_used_id(id)


## A lame attempt to collect all the noodle work in one func.
## Ended up being used only twice.
func _undo_redo_connections(undo_redo, id):
	for connection in get_connection_list():
		if connection.from_node == id or connection.to_node == id:
			var from_port = connection.from_port
			var to_port = connection.to_port
			undo_redo.add_do_method(self, "disconnect_node",
			connection.from_node, from_port, connection.to_node, to_port)
			undo_redo.add_undo_method(self, "connect_node",
			connection.from_node, from_port, connection.to_node, to_port)



## Event fired when stuff in the inspector was changed.
## We want to update the slots array[dict] in the rwnode selected
## so that it resembles the actual resource (res) which has changed.
##
## Noticed that some properties of resources (G 4.2 alpha)
## *fail* to emit the signal that calls this func...
## e.g.GradientTexture2D:
## If you change the fill_to or fill_from in the widget thing in the
## inspector, this func does not run. I'd argue that it should? Dunno.
## TODO What did I do about that ^ Is it just working now?
## TODO This func needs undo.
func _inspector_prop_edited(p:String):

	#print("QUE?")
	# All we get is the NAME of some property (p) that changed.
	if _selected_rwnode_name:
		var _selected_rwnode = map_id_to_rwnode.get(_selected_rwnode_name, null)

		if _selected_rwnode:
			# get value of property p in the resource
			var value = _selected_rwnode.res.get(p)

			#print();print(_selected_rwnode.slots)
			# find in the slots where that property is mentioned (if at all)
			var seek:Array = _selected_rwnode.slots.filter(
					func(d):
						return d.has("slot_name") and d.slot_name == p)
			#print("_inspector_prop_edited:", p, " seek:", seek)
			#print(_selected_rwnode.slots)
			# If we are an actual resource:
			# we only want seek[0] so make sure the array is kosher:
			#if not seek.is_empty() and seek.size() == 1:
			if seek.size() == 1:
				var found = seek[0]
				if found.is_array:
					# Some element of an Array was deleted
					# So, an Array that has had element n removed, well, you can't
					# see what happened...
					# We *do* still have the OLD VALUE in the slot_value ...
					var old_list = found.slot_value
					var new_list = value
					for res in old_list:
						# i.e. if res is MISSING (∴ it's been deleted in inspector)
						if res not in new_list:
							var array_of_the_rwnode_of_that_res = map_id_to_rwnode.values().filter(
								func(rwnode):
									return rwnode.res == res
							)
							if not array_of_the_rwnode_of_that_res.is_empty():
							# Okay, we have found the rwnode that was
							# removed in the Inspector Array UI
								var deleted_name = array_of_the_rwnode_of_that_res[0].name
								#print(deleted_name)
								var conn_list = get_connection_list().filter(
										func(i): return i.from_node == deleted_name)
								if not conn_list.is_empty():
									# Okay, we have found a connection. If not ... Panic?
									var conn = conn_list.back()
									if not conn.is_empty():
										disconnect_node(conn.from_node,
											conn.from_port, conn.to_node, conn.to_port)
										# TODO: Undo here is problematic.
										# Something to do with the Inspector. Not sure.
										#undo_redo.create_action("Disconnect rwnode")
										#undo_redo.add_do_method(graph, "disconnect_node",
										# conn.from, conn.from_port, conn.to, conn.to_port)
										#undo_redo.add_undo_method(graph, "connect_node",
										#  conn.from, conn.from_port, conn.to, conn.to_port)
										#undo_redo.commit_action()
				else:
					# Was a resource item. Going to handle the case where it's reset
					# i.e. Clear or the reset button was used. prop goes to null.
					if found.has("slot_value"):
						if _selected_rwnode.res.get(p) == null:
							# value was reset to null, so remove any noodle
							var conn_list = get_connection_list().filter(
									func(i): return (
										i.to_node == _selected_rwnode.name
										and i.to_port == found.slot_index)
									)
							if conn_list:
								# TODO Undo for this?
								var conn = conn_list[0]
								if not conn.is_empty():
									disconnect_node(conn.from_node,
										conn.from_port, conn.to_node, conn.to_port)

				# Now assign the value to the slot_value
				seek[0].slot_value = value #update that dict, so the rwnode is fresh
				_selected_rwnode.slot_changed.emit()
			else:
				# we are non-resource properties in the inspector.
				#var inspect = EditorInterface.get_inspector()
				#print(p, " = ", value)
				#print(inspect.get_selected_path())
				#print(typeof(value))
				_selected_rwnode.slot_changed.emit(value)


## Signal handler connected in main_view.tscn
func _on_node_selected(node: Node) -> void:
	var nodes = get_selected_rwnodes()
	if nodes.size() > 1:
		grab_focus()
	else:
		if node is rwNode:
			_selected_rwnode_name = node.name
			inspect_node(node)
			# Some hack stuff to try get the rolledup nodes
			# not to drag immediately.
			if node.updown_state != node.node_updown_state.UP:
				inspect_node(node)


## RMB on the GraphEdit happened.
## Signal handler connected in main_view.tscn
func _on_graph_popup_request(at_position: Vector2) -> void:
	if _chopstate == CHOP.NONE:
		if _current_chooser:
			remove_child(_current_chooser)
			_current_chooser.queue_free()
			_current_chooser = null
		var chooser_thing: rwResourceChooser = \
				NSrw.ChooserThingScene.instantiate()
		add_child(chooser_thing)
		chooser_thing.new_chooser_choice_made.connect(
				_new_resource_chosen)
		chooser_thing.kind1_setup(
				self,
				_drop_pos_calc(at_position)
			)
		_current_chooser = chooser_thing


## Signal handler connected in main_view.tscn
func _on_graph_gui_input(event: InputEvent) -> void:
	if _dragging_a_resource: return
	#print("event:", event.as_text())
	if event is InputEventKey and event.is_pressed():
		#print(event.keycode)
		if event.keycode == KEY_ESCAPE:
			if _current_chooser:
				close_chooser_rwnode()
		if event.keycode == KEY_D and event.ctrl_pressed:
			duplicate_as_unique()

	# detect the ctrl + RMB to 'chop' noodles:
	if event is InputEventMouse:
		ctrl_pressed = event.ctrl_pressed
		var ctrl_not_pressed:bool = not event.ctrl_pressed
		var rmb_pressed:bool = event.button_mask == 2
		var rmb_not_pressed:bool = event.button_mask == 0
		var both_pressed = rmb_pressed and ctrl_pressed
		var only_rmb = rmb_pressed and ctrl_not_pressed
		var stopped = rmb_not_pressed or ctrl_not_pressed

		if only_rmb and _chopstate == CHOP.NONE:
			return

		if both_pressed and _chopstate == CHOP.NONE:
			_chopstate = CHOP.DRAWING
			grab_focus()

		if stopped and _chopstate == CHOP.DRAWING:
			_chopstate = CHOP.STOPPEDDRAWING

		# Now we handle the chop state

		if _chopstate == CHOP.NONE:
			return

		if _chopstate == CHOP.DRAWING:
			accept_event()
			_ll.append( event.position )
			queue_redraw()
			return

		var ll_from:Vector2
		var ll_to:Vector2
		if _chopstate == CHOP.STOPPEDDRAWING:
			accept_event()
			ll_from = Vector2(_ll.front().x, _ll.front().y)
			ll_to = Vector2(_ll.back().x, _ll.back().y)
			ll_from =  (scroll_offset + ll_from) / _get_editor_scale() / zoom
			ll_to =  (scroll_offset + ll_to) / _get_editor_scale() / zoom
			_ll.clear()
			queue_redraw()
			_chopstate = CHOP.PROCESSING

		if _chopstate == CHOP.PROCESSING:
			if get_connection_list():
				undo_redo.create_action("Chopped connections")
				for connection in get_connection_list():
					#print(connection)
					#{ "from_node": &"0fcbc1a1fe", "from_port": 0, "to_node": &"ec2c2b725c", "to_port": 2 }

					var from_node = get_node(NodePath(connection.from_node)) as GraphNode
					# the to_node is what gets data changed in its resource.
					var to_node = get_node(NodePath(connection.to_node)) as GraphNode
					var from_pos = from_node.get_output_port_position(
							connection.from_port)
					var to_pos = to_node.get_input_port_position(
							connection.to_port)
					from_pos += from_node.position_offset
					to_pos += to_node.position_offset
					var foo = Geometry2D.segment_intersects_segment(
						from_pos,
						to_pos,
					 	ll_from,
						ll_to
					)
					if foo:
						var _slot = to_node.slots[connection.to_port]
						var _varnam = _slot["slot_name"]
						#print(_slot)
						# if array:
						# get the res obj in to_node (the other node)
						# find that in the slot var of this to_port
						# that is the index to remove
						if _slot.is_array: #better than : get(&"is_array", false)
							var _var:Array = to_node.res.get(_varnam)
							var _idx = _var.find(from_node.res)
							var _element_val = _var[_idx]
							# now I can remove that item from the array
							undo_redo.add_do_method(self, "_rm_slot_array_element",
								to_node, _varnam, _idx, _slot)
							undo_redo.add_undo_method(self, "_set_slot_array_element",
								to_node, _varnam, _idx, _element_val, _slot)
						else:
							#  just clear the slot
							var _val = to_node.res.get(_varnam)
							undo_redo.add_do_method(self, "_unset_slot_value",
								to_node, _slot, from_node.res)
							undo_redo.add_undo_method(self, "_set_slot_value",
								to_node, _slot, _val)

						undo_redo.add_do_method(self, "disconnect_node",
								connection.from_node, connection.from_port,
								connection.to_node, connection.to_port)
						undo_redo.add_undo_method(self, "connect_node",
								connection.from_node, connection.from_port,
								connection.to_node, connection.to_port)
					undo_redo.commit_action()

				_chopstate = CHOP.NONE


func _draw() -> void:
	if _chopstate == CHOP.DRAWING:
		var _cp = _ll.front()
		var llsz = _ll.size()-1
		var chop = llsz / (_ll.back() - _ll.front()).length()
		var col = _ed_settings.get_setting("interface/theme/accent_color")
		for p in range(0,llsz):
			var _lp = _ll[p]
			var np = wrap(p+1,1,llsz)
			_cp = _ll[np]
			if np > p:
				col = col.lerp(Color(col,0.2),chop)
				draw_dashed_line(_lp,_cp,col,2)


## Detects if there is an infinite loop.
## Have added some logic to catch clone loops. TODO: test
func _loops_infinitely(start_from_name:StringName,start_to_name:StringName)->bool:
	# if we go directly into self, just bail
	if start_from_name == start_to_name: return true

	# get all the connections.
	var _conns = get_connection_list()
	# the one being requested is not yet in there, so add it.
	_conns.append({from_node=start_from_name, to_node = start_to_name})

	# prepare for clone detect
	var from_node = map_id_to_rwnode[start_from_name]
	var _all_clones_of_me:Array = get_all_cloned_rwnodes_of(from_node)
	for _rw in _all_clones_of_me:
		# where a to would go into a clone, make the "to_node" name
		# in _conns become "start_from_name" instead. That way we
		# reduce multiple clones to just start_from_name.
		for _c in _conns:
			if _c.to_node == _rw.name:
				_c.to_node = start_from_name

	# start the process of looking for loops
	var curr = start_from_name
	var _conns_in
	while true:
		#incoming noodles
		_conns_in = _conns.filter(func(d): return d.to_node == curr)
		var _todo = []
		while not _conns_in.is_empty():
			var _c = _conns_in.pop_front()
			# i must look for both name == name and res == res
			# because there may be two type A clones and one new
			# type A: A(clone) A(clone) and A(new)
			# the noodling between A(clone)s is handled by the
			# name == name test, but if A(clone) noodles to A(new)
			# then the we must compare types.
			var from_res = map_id_to_rwnode[_c.from_node].res
			var to_res = map_id_to_rwnode[start_to_name].res
			if (_c.from_node == start_to_name) or \
				(from_res == to_res):
				return true # Loop found!
			if _c.from_node not in _todo: _todo.append(_c)
		if not _todo.is_empty():
			_conns_in = _todo
			curr = _conns_in.pop_front().from_node
		else:
			break
	return false


## Signal connected in main_view.tscn
## A noodle has been dropped on a port. This func will check the
## types of the two ends of the connection. If they are related,
## it will allow the connection.
## It handles quite a lot of cases. Be careful in here...
func _on_graph_connection_request(from_node_name: StringName, from_port: int, to_node_name: StringName, to_port: int) -> void:
	if _loops_infinitely(from_node_name, to_node_name):
		main_view.feedback("Possible infinite loop detected.", &"WARNING")
		return

	var to_node : GraphNode = map_id_to_rwnode.get(to_node_name)
	var to_slot_dict = to_node.get_slot_dict(to_port)

	var from_node : GraphNode = map_id_to_rwnode.get(from_node_name)
	var from_resource = from_node.res

	if from_port == 0 and to_port == 0:
		# We are connecting from 0-IN to 0-OUT - the "extends" port
		# Thus allow anything, but not multiple noodles:
		# Don't connect to input that is already connected
		for con in get_connection_list():
			if to_node_name == con.to_node and to_port == con.to_port:
				main_view.feedback("Port occupied.", &"WARNING")
				return

	# Early check that this node is not *already* plugged in.
	if is_node_connected(from_node_name, from_port, to_node_name, to_port):
		main_view.feedback("Port already connected.", &"WARNING")
		return

	#print(to_slot_dict)
	if to_slot_dict.is_array: #get("is_array"):
		if to_slot_dict.slot_value == null:
			to_slot_dict.slot_value = []
		# Ensure this rwnode is not already in the array!
		if from_resource in to_slot_dict.slot_value:
			# Moan, but *allow* the noodle connection to happen
			# because resources may be added that have values in their slots
			# but no noodle coming in, so you can add it again if you want to.
			main_view.feedback("That resource is already in the array.",
				&"WARNING")

	# Confirm that the TYPES of incoming and the slot are compatible!
	var from_res_type :=  str(dbatClassHacks.get_classname_from_a_resource(from_resource))

	if to_slot_dict.get(&"slot_type", null) == null:
		# Holding ctrl will replace the target resource's `extends`
		# with the dropped resource's class_name
#region Attempted ovveride of extends - not much luck yet
		if ctrl_pressed:
			# TODO: open a menu asking:
			# Extend from dropped node?
			# Changing a parent class is kind of radical
			# There may be other nodes connected to the old class
			# TODO: How to deal with that?
			var to_resource = to_node.res
			var src:String = to_resource.script.source_code
			if src:
				var regex = RegEx.new()
				regex.compile("extends\\s(.*)\\s")
				var result = regex.search(src)
				if result:
					var current_extends:String = result.get_string(1).strip_edges()
					var dropped_extends:String = \
						dbatClassHacks.get_classname_from_a_resource(from_resource)
					# It may be that both resources are already extending
					# from the same class:
					if current_extends != dropped_extends:
						# ok, let's change the to_resource's extends
						print(" replace ", current_extends, " with ", dropped_extends)
						src = src.replace(current_extends, dropped_extends)
						print(src)
						var pth = to_resource.script.get_path()
						if pth:
							# :( ERROR: Another resource is loaded from path
							# 'res://plants/nubbin.gd' (possible cyclic resource inclusion)
							#to_resource.script.source_code = src
							#var new_script:GDScript = GDScript.new()
							#new_script.source_code = src
							#new_script.resource_path = pth
							#ResourceSaver.save(new_script,pth,ResourceSaver.FLAG_CHANGE_PATH)

							# Do a force-write over the old script!
							# This seems to work. Gulp!
							# NB source for pth must not be open in the editor.
							var file = FileAccess.open(pth, FileAccess.WRITE)
							file.store_string(src)
							file.close()
							to_resource.script.reload()
							main_view.feedback("Changed parent class to %s." % dropped_extends, &"WARNING")
							# Trying to refresh the script in the Editor
							# Nothing seems to work.
							# For now one must alt-tab out and into Godot again.

							#region Failed Script Update Attempts
							#EditorInterface.get_script_editor().reload_scripts()
							#var se = EditorInterface.get_script_editor()
							#se.editor_script_changed.emit(to_resource.script)
							#se.script_close.emit(to_resource.script)
							#EditorInterface.get_resource_filesystem().scan()
							#var interface = EditorInterface#.get_editor_settings()
							# Update the file
							#var fs = interface.get_resource_filesystem()
							#fs.update_file(pth)
							#ResourceSaver.save(to_resource)
							#endregion
							await get_tree().create_timer(0.5).timeout
		#endregion
		else:
			# Normal 0 on 0 drop
			var to_res_type : String = to_node.resource_classname
			var pclass := dbatClassHacks.get_parent_class(to_res_type)
			# This is a port 0 connection
			# Is the from_resource the *direct* ancestor of to_res?
			if pclass != from_res_type:
				main_view.feedback("Not a valid parent.", &"WARNING")
				return
	else:
		# This is a normal port connection (port 1 onwards)
		var l : Array
		var fmsg: String

		#region Type override - old code for perhaps maybe later etc.
		## Removing this for now. Leave code comment in case.
		## Chance to override the accepted types on the in ports
		## e.g. override_base_port_types = {&"texture":[&"ImageTexture", &"Texture2D"]}
		## Explain:
		## ImageTexture means Upstream < ImageTexture < Stop
		## Texture2D means Upstream < ImageTexture < Texture2D < Stop
		## Even though the actual port may say "Resource" it will only accept these
		## types. It's a hack to work around lack of interfaces in gdscript.
		#if false:#&"override_base_port_types" in to_node.res and \
				##not to_node.res.override_base_port_types.is_empty():
#
			#var _overrides_dict = to_node.res.override_base_port_types
			#if _overrides_dict:
				#var to_slot_name : String = to_slot_dict.slot_name
				#if to_slot_name in _overrides_dict.keys():
					#l.clear()
					#for klss in _overrides_dict[to_slot_name]:
						#_editor_resource_picker.base_type = klss
						#var _l : Array = _editor_resource_picker.get_allowed_types()
						#l.append_array(_l)
					#fmsg = "Rejected; must be at least %s:" % ",".join(_overrides_dict[to_slot_name])
		#else:
#endregion

		## A way to deny certain classes from being connected
		var deny_list = dbatClassHacks.get_metadata(to_node.resource_classname, &"deny_list")
		#print("DENY:", deny_list, " from:", from_res_type)
		if deny_list:
			if from_res_type in deny_list:
				main_view.feedback("%s is not allowed here." % from_res_type,
					 &"WARNING")
				return

		# We will use the type as-is
		# EditorResourcePicker is a Control Node!
		var _editor_resource_picker := EditorResourcePicker.new()
		#print("to_slot_dict.slot_type:", to_slot_dict.slot_type)
		_editor_resource_picker.base_type = to_slot_dict.slot_type
		l = _editor_resource_picker.get_allowed_types()
		# Trying to prevent weird Godot bug of malformed resources
		await get_tree().process_frame
		_editor_resource_picker.queue_free()

		l.append(to_slot_dict.slot_type) #include the damn original type!
		if not l: # weird af, but it happened to me!
			main_view.feedback("Strange error: get_allowed_types() failed.",
				 &"WARNING")
			return
		fmsg = "Types don't match. See output."

		if not from_res_type in l:
			main_view.feedback(fmsg, &"WARNING")
			# Sept 2024, having some weird cases where a resource is not
			# quite known to Godot and so legitimate noodles are denied.
			print("  ** POSSIBLE BUG NOTICE **")
			print("  Those types *may* actually match. Restart RW plugin if you think they should.")
			print("  Allowed types according to Godot. May be a large list:\n", l)
			print("  Incoming type, should be in that list if it's a match: ", from_res_type)
			print()
			return

	# Prepare potential disconn of old node - only if not an array port
	var _replaced_node:={}
	if not to_slot_dict.is_array: #get("is_array"):
		for con in get_connection_list():
			if to_node_name == con.to_node and to_port == con.to_port:
				_replaced_node = {old_con = con, old_slot_dict=to_slot_dict}
				break

	undo_redo.create_action("Connected nodes")
	undo_redo.add_do_method(self, "_set_slot_value", to_node, to_slot_dict, from_resource)
	undo_redo.add_do_method(self, "connect_node", from_node_name, from_port, to_node_name, to_port)

	# if Normal connection
	if not _replaced_node:
		undo_redo.add_undo_method(self, "_unset_slot_value", to_node, to_slot_dict, from_resource)
		undo_redo.add_undo_method(self, "disconnect_node", from_node_name, from_port, to_node_name, to_port)

		# lambda for use on the force_disconnect signal (see rwnode) handler.
		# It's for when a resource node wants to force a disconnect.
		discon = func():#auto-captures all local vars
			self.disconnect_node(from_node_name, from_port, to_node_name, to_port)
			# NB : Must be call_deferred bcoz we may still be in the previous push_rerender cycle.
			# This is vague. TODO: test etc.
			call_deferred("_unset_slot_value", to_node, to_slot_dict, from_resource)

	# If we had a previous connection that we're replacing.
	else:
		# undo: reset to last value
		var old_from_node : GraphNode = map_id_to_rwnode.get(_replaced_node.old_con.from_node)
		var old_from_resource = old_from_node.res
		undo_redo.add_undo_method(self, "_set_slot_value",
				to_node, _replaced_node.old_slot_dict, old_from_resource)
		# do: old conn away
		undo_redo.add_do_method(self, "disconnect_node",
				 _replaced_node.old_con.from_node,
				 _replaced_node.old_con.from_port,
				 to_node_name, to_port)
		#undo: old con comes back
		undo_redo.add_undo_method(self, "connect_node",
				_replaced_node.old_con.from_node,
				_replaced_node.old_con.from_port,
				to_node_name, to_port)
		#undo: new con goes away
		undo_redo.add_undo_method(self, "disconnect_node",
				from_node_name, from_port, to_node_name, to_port)

		# lambda for use on the force_disconnect signal (see rwnode) handler.
		# it's for when a resource node wants to force a disconnect.
		discon = func():#auto-captures all local vars
			self.disconnect_node(from_node_name, from_port, to_node_name, to_port)
			self.connect_node(
				_replaced_node.old_con.from_node,
				_replaced_node.old_con.from_port,
				to_node_name, to_port)
			# NB : Must be call_deferred bcoz we may still be in the previous push_rerender cycle.
			# This is vague. TODO: test etc.
			call_deferred("_set_slot_value",
				to_node, _replaced_node.old_slot_dict, old_from_resource)

	undo_redo.commit_action()


func _set_slot_value(to_node, to_slot_dict, from_resource):
	if to_slot_dict.is_array: #get("is_array"):
		if from_resource not in to_slot_dict.slot_value:
			to_slot_dict.slot_value.append(from_resource)
			#print("append to slot dict:", from_resource)
	else:
		to_slot_dict.slot_value = from_resource
	to_node.slot_changed.emit()


# NOTE Sept 2024
# Because Arrays are pointers, having one var (slot) or another (res) reffing
# to one, really means two refs to one place.
# I should only touch slot here, not the res, but arrays kind of mess that up.
# TODO It would be cleaner if I could just pass this whole job over to the rwnode.
func _set_slot_array_element(the_node, the_array_varname, the_index, the_val, _slot):
	var _arr:Array = the_node.res.get(the_array_varname)
	_arr.insert(the_index, the_val)
	_slot.slot_value = _arr # What we do to the resource, we must do to the slot...
	the_node.slot_changed.emit()

# NOTE see ↑
func _rm_slot_array_element(the_node, the_array_varname, the_index, _slot):
	var _arr:Array = the_node.res.get(the_array_varname)
	_arr.remove_at(the_index)
	_slot.slot_value = _arr # What we do to the resource, we must do to the slot...
	the_node.slot_changed.emit()


func _unset_slot_value(to_node, to_slot_dict, from_resource):
	if to_slot_dict.is_array:#get("is_array"):
		to_slot_dict.slot_value.remove_at(to_slot_dict.slot_value.find(from_resource))
	else:
		to_slot_dict.slot_value = null
		#print("_unset_slot_value", to_node, to_slot_dict, from_resource)
	to_node.slot_changed.emit()#to_slot_dict)


## Part 1 of making a new rwNode and its resource from an INPUT SLOT DROP
func _make_from_input_port_drop_part1(classname, t, slot, release_position, to, to_port):
	# 1. Get a list of related resource types
	# 2. Make a new node type that lists them as choices
	# 3. clicking one will then proceed to replace this node
	#    with the new rwnode node.
	# I only want one chooser at any time
	if _current_chooser:
		remove_child(_current_chooser)
		_current_chooser.queue_free()
		_current_chooser = null

	var chooser_thing: rwResourceChooser = NSrw.ChooserThingScene.instantiate()
	add_child(chooser_thing)
	_current_chooser = chooser_thing
	chooser_thing.new_chooser_choice_made.connect(_new_resource_chosen)
	chooser_thing.kind2_setup(
			self,
			t,
			classname,
			_drop_pos_calc(release_position),
			slot,
			to,
			to_port
		)


## Part 2 of making a new rwNode and its resource after a
## Resource Chooser Button was pressed.
func _make_from_input_port_drop_part2(classname, _chooser_situation):
	#print("part2 Make a:", classname, " details:", _chooser_situation)
	#Go make a new resource etc.
	var result = _make_a_new_resource_and_rwnode(classname)
	if result.status == FAILED:
		main_view.feedback("Could not instance that resource.", &"WARNING")
		return

	# Update the slot_value
	if _chooser_situation["from_slot"].is_array:
		_chooser_situation["from_slot"].slot_value.append(result.new_resource_obj)
	else:
		_chooser_situation["from_slot"].slot_value = result.new_resource_obj

	undo_redo.create_action("Added node from noodle-drop chooser")
	_initial_add_thing_pattern(
		result.new_resource_obj,
		result.id,
		_chooser_situation["release_position"],
		_chooser_situation["to"],
		_chooser_situation["to_port"],
		_chooser_situation["from_rwnode"],
		true #make the noodles too
	)
	undo_redo.commit_action()


## Signal connected in main_view.tscn
## DROP from an INPUT SLOT (to) out to the GraphEdit(board)
## Will remake that slot into a graph node (if there is a resource, i.e. not null)
## Else will open a list of choices (buttons) to choose a resource to make.
func _on_connection_from_input_port_to_empty(
	to_node_name: StringName, to_port: int, release_position: Vector2) -> void:
	#print("_on_connection_from_input_port_to_empty:", release_position)

	var classname:String
	var drag_from_rwnode = map_id_to_rwnode.get(to_node_name)
	var slot = drag_from_rwnode.get_slot_dict(to_port)

	# TODO WEIRD, I once had a case where slot_value was actually nil (vs null)

	## Aug 2023
	## Was thinking of dropping out the parent class somehow
	## but the question is *which* actual RESOURCE would I choose?
	## So, maybe best to not do anything in this case.
	if slot.get("top_slot"):
		return

	# We are dragging from a NULL input: i.e. make a new resource
	# Or we are dragging out from an Array slot.
	#if slot.get("is_array") or slot.slot_value == null:
	if slot.is_array or slot.slot_value == null:
		classname = slot.slot_type
		if classname == "": classname = "Resource"
		_make_from_input_port_drop_part1(classname,
			drag_from_rwnode, slot, release_position, to_node_name, to_port)
		# part2 is run after a chooser button press release, if any.
	# We are dropping an exisiting resource.
	else:
		#Make sure a noodle is not already there:
		for con in get_connection_list():
			if to_node_name == con.to_node and to_port == con.to_port:
				return
		var dropped_resource = slot.slot_value
		var id = dbatGeneralUtils.get_random_id()
		var resource = slot.slot_value
		undo_redo.create_action("Added node from empty port")
		_initial_add_thing_pattern(
			resource,
			id,
			_drop_pos_calc(release_position),
			to_node_name,
			to_port,
			drag_from_rwnode,
			true # make the noodles too
		)
		undo_redo.commit_action()


## Signal handler connected in this file.
## A resource classname was chosen from a chooser.
func _new_resource_chosen(chooser_kind:int, classname:String):
	var dict = _current_chooser.get_meta("situation", {})
	close_chooser_rwnode()
	match chooser_kind:
		rwChooserBase.KIND.MAKE_FROM_INPUT_PORT_DROP_TO_EMPTY:
			_make_from_input_port_drop_part2(classname, dict)
		rwChooserBase.KIND.MAKE_FROM_POPUP:
			_make_new_resource_from_chooser(classname)


## Signal handler connected in main_view.tscn
func _on_graph_disconnection_request(from_node_name: StringName,
		from_port: int, to_node_name: StringName, to_port: int) -> void:
	#var from_node_res = map_id_to_rwnode.get(from_node).res
	#from_node_res.res.changed.disconnect()
	var node = map_id_to_rwnode.get(to_node_name)
	var slot_dict = node.get_slot_dict(to_port)
	# Deny slot disconnect if array
	#if slot_dict.get(&"is_array", false):
	if slot_dict.is_array:
		# Godot 4.2 : Tried to fake a drop from array, but it sucks.
		# I can't switch disconnect off for certain ports
		# The connect_request never fires, so it's all broken.
		#_on_connection_from_input_port_to_empty(
			#to_node, to_port, get_local_mouse_position()
		#)
		return
	undo_redo.create_action("Disconnected nodes")
	undo_redo.add_do_method(self, "disconnect_node", from_node_name,
			from_port, to_node_name, to_port)
	undo_redo.add_undo_method(self, "connect_node",  from_node_name,
			from_port, to_node_name, to_port)
	undo_redo.commit_action()


# PART 1 of dragging a Resource from an output port to the inspector!
# Holding SHIFT before dragging will trigger this...
# Makes the preview icon and set the drag data.
func _on_connection_drag_started(from_node: StringName, from_port: int, is_output: bool) -> void:
	if is_output:
		if Input.is_key_pressed(KEY_SHIFT):
			var rwn:rwNode = map_id_to_rwnode[from_node]
			#EditorInterface.inspect_object(_last_object_in_inspector)
			_drag_resource_to_inspector_preview = TextureRect.new()
			_drag_resource_to_inspector_preview.size = Vector2(16,16)
			_drag_resource_to_inspector_preview.texture = get_theme_icon(&"ResourcePreloader", &"EditorIcons")
			_dragging_data = {
			  	"type": "files",
			  	"files": [rwn.res.resource_path],
			  	#"from": null#rwn.res
			}
			_dragging_a_resource = true
			force_connection_drag_end() # stops the noodle!


# PART 2 of dragging a resource to Inspector.
# Continually calls force_drag
func _process(delta: float) -> void:
	if _dragging_a_resource:

		# It seems this has to happen continuously!
		force_drag(_dragging_data, _drag_resource_to_inspector_preview)


# PART 3 of dragging resource to Inspector.
# This one is how the drag ends.
# We free the icon.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_dragging_a_resource = false
		if is_instance_valid(_drag_resource_to_inspector_preview):
			if not _drag_resource_to_inspector_preview.is_queued_for_deletion():
				_drag_resource_to_inspector_preview.queue_free()


## Signal connected in main_view.tscn
## DROP from an OUTPUT to empty space
## PART 1
## Uses a popup menu.
## !! The popup script handles the choice and calls funcs in board !!
func _on_graph_connection_to_empty(from_node_name: StringName,
	from_port: int, release_position: Vector2) -> void:
	#open the POPUP MENU
	out_menu.popup_at(
		self,
		from_node_name, #LHS
		from_port,
		release_position
	)


## Signal 'files_moved' handler. Connected in this file.
## If a resource was moved, do something
func _file_changed_board(f,t):
	for node in map_id_to_rwnode.values():
		if node.res.resource_path == f:
			node.refresh_from_resource()


## Signal handler for 'file_selected' connected in this file.
## Handles saving a new class files (.gd) from the output drop menu
func _on_filedialogue_file_selected(path: String) -> void:
	var sitch = save_extended_class.get_meta("situation")
	if not sitch: return
	var rwnode = sitch.rwnode
	if sitch.switch == &"class":
		var _pos = sitch.position
		var _tn = sitch.thing_name
		_new_custom_extended_resource_part3(_tn, rwnode, _pos, path)
	save_extended_class.remove_meta("situation")
	save_extended_class.visible = false


## EXTEND
## Part 3
## Picks-up after the FileDialog has finished:
## Make the actual new gd script extended from rwnode at path
## At first I tried to use the actual class_name keyword, but it is simply
## not reliable. At least one can extend <path> and so I used that.
## Update: Seems fixed in 4.2 beta 1 - Now using class_name
##         However the class is not "registered" yet, so not perfect.
func _new_custom_extended_resource_part3(
	name_of_thing_we_are_extending,
	thing_we_are_extending,
	_position,
	path:String):
	if thing_we_are_extending.resource_classname.is_empty():
		main_view.feedback("There's no class name for the from node." +\
		" Try restarting the addon.", &"WARNING")
		return
	# Make a class name for our new script
	var script_class_name : String
	script_class_name = "%s%s" % ["res",
		path.
		get_file().
		split(".")[0].
		capitalize().
		replace(" ","")
	]
	var srccode:String
	if dbatClassHacks.is_class_custom(thing_we_are_extending.resource_classname):
		srccode = "class_name %s\nextends %s\n" % \
			[script_class_name, thing_we_are_extending.resource_classname]
		#srccode = "class_name %s\nextends \"%s\" # %s\n" % \
			#[script_class_name,
			#thing_we_are_extending.res.script.get_path(),
			#thing_we_are_extending.resource_classname]
	else:
		srccode = "class_name %s\nextends %s\n" % \
			[script_class_name, thing_we_are_extending.resource_classname]

	rwSettings.ensure_dirs()
	var new_script:GDScript = GDScript.new()
	new_script.source_code = srccode
	new_script.resource_path = path
	ResourceSaver.save(new_script) # writing the script file
	new_script = null
	dbatGeneralUtils.refresh_filesystem()

	await get_tree().create_timer(0.5).timeout

	var new_res:Resource = ResourceLoader.load(path, "",
		 ResourceLoader.CACHE_MODE_IGNORE).new()

	## Make a resource from it
	var id = dbatGeneralUtils.get_random_id()
	var newpath = "%s/resources/%s_%s.tres" % \
			[rwSettings.automade_path, script_class_name, id]
	new_res.take_over_path(newpath)
	assert(ResourceSaver.save(new_res) == OK, "Saving that object failed")

	undo_redo.create_action("Extended node")
	undo_redo.add_do_method(self, "_add_rwnode_and_draw",
	{	id = id,
		position_offset = _drop_pos_calc(_position),
		resource = new_res,
	})
	undo_redo.add_undo_method(self, "_delete_rwnode", id)

	undo_redo.add_do_method(self, "connect_node",
			name_of_thing_we_are_extending, 0, id, 0)
	undo_redo.add_undo_method(self, "disconnect_node",
			 name_of_thing_we_are_extending, 0, id, 0)
	undo_redo.commit_action()



## Signal handler connected in main_view.tscn
func _on_focus_entered() -> void:
	#print("FOCUS IN")
	focus_is_on_board = true
	OS.low_processor_usage_mode = true
	# Reconnect the inspector when focus comes back
	#var inspect = EditorInterface.get_inspector()
	#if not inspect.is_connected("property_edited",_inspector_prop_edited):
		#inspect.property_edited.connect(_inspector_prop_edited)

## Signal handler connected in main_view.tscn
func _on_focus_exited() -> void:
	#print("FOCUS OUT")
	focus_is_on_board = false
	OS.low_processor_usage_mode = false
	release_focus()
	## Release the inspector to other use.
	#var inspect = EditorInterface.get_inspector()
	#if inspect.is_connected("property_edited",_inspector_prop_edited):
		#inspect.property_edited.disconnect(_inspector_prop_edited)
