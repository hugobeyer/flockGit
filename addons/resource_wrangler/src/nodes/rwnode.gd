@tool
class_name rwNode extends "node_base.gd"

## rwNode
##
## The node class for the Resource Wrangler plugin


##region licence
# MIT License
#
# Original Work Copyright (c) 2022 Nathan Hoad
# Modified work Copyright (c) 2023 Donn Ingle (donn.ingle@gmail.com)
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

signal popup_menu_request(position: Vector2)
signal slot_changed(newvalue)

const verbose := false
const verbose_draw_node := false
const verbose_change_signals := false
const verbose_preview := false
const boardClass := preload("../main/board.gd")


enum node_updown_state {LAST, UP,DOWN}
enum mode {NONE, CREATE, UPDATE, MISSING, RENEW}


var board: boardClass
var res: Resource
var resource_classname: String
var updown_state = node_updown_state.LAST

var _rwstate: int
var _title_grid_data: Dictionary
var _comment_text: String
var _updown := false
var _details_visible := true
var _undo_redo:EditorUndoRedoManager
var _automade: bool
var _editor_plugin: EditorPlugin
var _main_view
var _my_panel_normal: StyleBox
var _my_titlebar_normal: StyleBox
var _my_titlebar_selected: StyleBox
var _my_panel_selected: StyleBox
var _ed_settings := EditorInterface.get_editor_settings()
var _blank := Image.create(1,1,false,Image.FORMAT_RGBA8)
var _minimize_button:Button

@onready var comment_text_control: TextEdit = %comment_text
@onready var rwnode_classname_label := %classname
@onready var rwnode_icon := %icon
@onready var res_preview: TextureRect = %res_preview


func _ready() -> void:
	_theme_setup()

	%help.icon = get_theme_icon(&"Help", &"EditorIcons")
	%showinfs.icon = get_theme_icon(&"ShowInFileSystem", &"EditorIcons")
	%editscript.icon = get_theme_icon(&"GDScript", &"EditorIcons")
	%info.icon = get_theme_icon(&"NodeInfo", &"EditorIcons")
	%close.icon = get_theme_icon(&"Close", &"EditorIcons")
	%refresh.icon = get_theme_icon(&"Reload", &"EditorIcons")

	slot_changed.connect(_slot_changed)

	# weird titlebar fandango to put the X on the left
	# the label in the middle and the min buttton on the right
	var _h:HBoxContainer = get_titlebar_hbox()
	#_h.add_theme_constant_override("separation",4)
	#"theme_override_constants/separation",4)
	var _lab:Label = _h.get_child(0)
	#_lab.autowrap_mode = TextServer.AUTOWRAP_... # goes haywire
	_h.remove_child(_lab)
	var _close = %close.duplicate()
	_minimize_button = %min.duplicate()
	%close.visible = false
	%min.visible = false
	_h.add_child(_close)
	_h.add_child(_lab)
	_h.add_child(_minimize_button)



# -------------- PUBLIC FUNCS --------------------


func setup(_board:boardClass, _id, _size):
	self.size = _size
	self.name = _id
	dbatGeneralUtils.record_used_id(_id)
	self.board = _board
	self._undo_redo = _board.undo_redo
	self._editor_plugin = _board.editor_plugin
	self._main_view = _board.main_view


## Supply a dict of myself for saving.
func to_serialized(scale: float) -> Dictionary:
	# PS rp already blank...
	#print()
	#print("node to_serialized..")
	#print("  resource:", res)
	#print("  path:", res.resource_path)
	return {
		id = name,
		_comment_text = comment_text_control.text,
		position_offset = position_offset / scale,
		#size = size / scale,
		_updown = _updown,
		resource_class_name = resource_classname,
		resource = res,
		_details_visible = _details_visible
	}


## Refreshes the node so it reflects new data
func refresh_from_resource():
	_rwstate = mode.UPDATE
	await draw_node()


## Routine to build my initial data from the incoming dict.
## Also sets 'res' - my resource. Usually followed by call
## to draw_node func.
func from_serialized(data:Dictionary) -> void:
	_rwstate = data.get("state", mode.CREATE)
	var scale = data.get("editor_scale", 1.0)
	if _rwstate == mode.CREATE:
		_comment_text = data.get("_comment_text", "")
		position_offset = data.get("position_offset", Vector2.ZERO) * scale
		#size = data.get("size",Vector2.ONE) * scale
		_updown = data.get("_updown",false)
		updown_state = int(_updown) + 1
		_details_visible = data.get("_details_visible", false)
	res = data.get("resource", res)# get the new resource or the last one

	# PS rp is ok here...
	#print()
	#print("node from_serialized...")
	#print("  resource:", res)
	#print("  path:", res.resource_path)

	if not res: #oh shit..the resource file is bad!
		_rwstate = mode.MISSING
		assert(false, "rwnode.from_serialized: The resource is missing. Stopping.")


## Coroutine to fill the node with data and then draw it all.
## Disabled the changed signal so that changing my resource (res) will
## not emit that sig. Well, I hope it won't. It re-enables changed at the end.
func draw_node():
	if res.changed.is_connected(_resource_changed):
		res.changed.disconnect(_resource_changed)

	if res.has_signal(&"feedback"):
		res.feedback.connect(_main_view.feedback, CONNECT_REFERENCE_COUNTED)

	if res.has_signal(&"force_disconnect"):
		res.force_disconnect.connect(_force_disconnect, CONNECT_REFERENCE_COUNTED)

	_automade = res.resource_path.begins_with(
			rwSettings.automade_path)

	if _rwstate == mode.RENEW and res.get_script():
		var err : int = res.get_script().reload(true)
		if not err in [OK, ERR_ALREADY_IN_USE]:
			assert(false, "reload() error %s" % err)

	var slotidx:int=1
	resource_classname = dbatClassHacks.get_classname_from_a_resource(res)
	if resource_classname != dbatClassHacks.NO_CLASS_NAME:
		# if we are forced to RENEW: It means we want to
		# remove all the slots to later re-create them!
		if _rwstate == mode.RENEW:
			# check it has a script - ie is a custom script
			# we only care about those
			if res.get_script():
				var kids = get_children()
				for kid in kids:
					if kid.name != "topslot":
						remove_child(kid)
						kid.queue_free()
				_rwstate = mode.CREATE
			else:
				# not a custom script, so just go into UPDATE mode
				_rwstate = mode.UPDATE

		if _rwstate == mode.CREATE:
			slots.clear()
			slots.append({top_slot=true, is_array=false})

#region create/update all the slots body
		var properties = res.get_property_list()

		for i in range(properties.size()):
			if _allow_through(properties[i]):
				# this call returns string "Array" if any kind of array
				var property_classname =\
				_get_class_name_from_resource_property(properties[i])
				if property_classname != dbatClassHacks.NO_CLASS_NAME:
					var DATA_SLOT_SCENE
					var prop_var_value
					match _rwstate:
						mode.CREATE:
							DATA_SLOT_SCENE = NSrw.DataSlotScene.instantiate()
							# do now to get ready to run early
							add_child(DATA_SLOT_SCENE)
							# look up the property in the actual resource
							# i.e if there's a var called "BOO" in res, then
							# we are getting res.BOO
							prop_var_value = res.get(properties[i].name)
							if verbose_draw_node:
								print("CREATE on node:", name, " ",
									properties[i].name, " = prop_var_value:", prop_var_value)
						mode.UPDATE:
							DATA_SLOT_SCENE = slots[slotidx].data_slot_scene
							prop_var_value = slots[slotidx].slot_value # the NEW value

							# make sure to put the updated value into the
							# actual resource's variable.
							# !!!!! ALTERING RESOURCE !!!!!!!!!
							# NB : It prevents changes that would be the same
							# This means (for e.g) removing a port's value
							# i.e. var = null, HAPPENS ONLY ONCE. The next time you
							# press X this does not happen.
							var current_prop_val = res.get(properties[i].name)
							if verbose_draw_node:
								print()
								print("slots:", slots)
								print("UPDATE:", properties[i].name, " old:",
									current_prop_val, " to new:", prop_var_value)
							if current_prop_val != prop_var_value:
								if verbose_draw_node:
									print("    RWNODE UPDATE set on:", res)
									print("    ", properties[i].name, " was ", current_prop_val)
									print("    The plan: ", properties[i].name, " = ", prop_var_value)
								if prop_var_value is Array:
									# NOTE: Since 4.4 this works again!
									# This used to work in 4.2.x :(
									# This DOES NOT WORK in 4.3 stable ☹
									# res.set(properties[i].name, prop_var_value as Array)

									# 4.3 and down version:
									# _array is a Variant on purpose.
									var _array = res.get(properties[i].name)

									if prop_var_value:
										_array.clear() # to prevent doubling
										if verbose_draw_node:
											print("Setting Array")
											print(" _array:", _array)
											print(" prop name:", properties[i].name)
											print(" prop_var_value:", prop_var_value)
										# Relies on arrays being pointers and not copies
										_array.append_array(prop_var_value)
									else:
										if verbose_draw_node:
											print("Clearing Array")
										# seems redundant but must be done
										_array.clear()

								else:
									res.set(properties[i].name, prop_var_value)

								if verbose_draw_node:
									print("    The reality: ", properties[i].name, " = ", res.get(properties[i].name))


					var slot_dict = {}
					slot_dict["is_array"] = property_classname == "Array"
					slot_dict["slot_name"] = properties[i].name

					var slot_typename:String
					slot_typename = _get_slot_type_name(
							property_classname, properties[i])

					slot_dict["slot_type"] = slot_typename
					slot_dict["slot_value"] = prop_var_value
					slot_dict["data_slot_scene"] = DATA_SLOT_SCENE
					slot_dict["slot_index"] = slotidx

					if _rwstate == mode.CREATE:
						slots.append(slot_dict)

					# Set slot label
					var dsc = slot_dict.data_slot_scene
					var stypename:String = slot_dict.slot_type
					if slot_dict.is_array:#["is_array"]:
						stypename = "Array[%s]" % slot_dict.slot_type
					dsc.slot_label.text ="%s:" % slot_dict.slot_name
					dsc.slot_value_label.text ="%s %s" % [
						stypename,
						_shorten_resource_id(slot_dict.slot_value)
						]

					# Set slot INPUT port
					var slot_type:int
					var slot_icon = null
					var port_color: Color
					if slot_dict.is_array: #["is_array"]:
						# Array of type <slot_type>
						slot_icon = NSrw.array_porticon
						slot_type = _get_slot_type(slot_typename)
						port_color = _get_port_col(slot_typename)
					else:
						# Anything else
						slot_type = _get_slot_type(slot_typename)
						port_color = _get_port_col(slot_typename)

					set_slot(slotidx,
						true, slot_type, port_color,
						false,0, Color(0,1,0),
						slot_icon, # left icon
						null,
						true
					)

					if _rwstate == mode.CREATE:
						DATA_SLOT_SCENE.clear_button.pressed.connect(
							_slot_clear_button_pressed.bind(slotidx)
						)
					slotidx += 1
		## end for i in properties

		# Class Icon
		var icon:Texture2D = dbatClassHacks.get_icon_for(
			resource_classname,
			_editor_plugin,
		)
		if icon:
			rwnode_icon.texture = icon

		#Comment
		comment_text_control.text = _comment_text

		var graph_slot_type:int
		var out_port_color: Color
		graph_slot_type = _get_slot_type(resource_classname)
		out_port_color = _get_port_col(resource_classname)

		# Bottom edge col!
		_my_panel_normal.border_color = out_port_color

		if dbatClassHacks.get_parent_class(resource_classname) == "Resource":
			# If this node's res parent is a plain Resource, then no further
			# zero IN ports are required
			set_slot(0,
				true, -1, 0, # No zero in port
				true, 513, out_port_color,
				null, null, false
			)
		else:
			if rwSettings.get_setting(&"extended_functionality"):
				set_slot(0,
					true, 513, Color.RED, # The Extend/Mutate IN slot 0
					true, 513, out_port_color, # OUT graph_slot_type, out_port_color
					get_theme_icon(&"VisualShaderPort", &"EditorIcons"),
					null, false
				)
			else:
				set_slot(0,
					true, -1 , 0, # in-port is "virtually" there :)
					true, 513, out_port_color,
					null, null, false
				)
#endregion

	##COROUTINE PART
	if res.has_method(&"process"):
		if verbose_draw_node:
			print("    RWNODE await res.process:", self.name)
		var _wait = await res.process()
		if verbose_draw_node:
			print("    RWNODE back :", self.name)

	## Reconnect the changed sig.
	res.changed.connect(_resource_changed,CONNECT_REFERENCE_COUNTED)

	_render_node_gui()
	# PS rp ok here
	#print()
	#print("END OF draw node...")
	#print("  res:", res, " path:", res.resource_path)


func if_clone_change_style():
	var _is_clone:bool = board.detect_clone(res)
	var _title = res.resource_path.get_file()
	var regex = RegEx.new()
	#regex.compile("(.*)_.*\\.tres")
	regex.compile("(.*)_.*\\.?res")
	var result = regex.search(_title)
	if result:
		_title = result.get_string(1)
	if _is_clone:
		_title = "⭕ " + _title
		tooltip_text = "⭕ This is a clone"
		_change_colors(&"clone")
	else:
		tooltip_text = ""
		_change_colors()
	#title = "%s\nNode: %s" % [ _title , str(self.name) ]
	title = _title



# -------------- PRIVATE FUNCS --------------------



## Note: DOES NOT fire on startup/load as nodes are made
func _slot_changed(newvalue=null):
	if verbose_change_signals:
		print("\nSLOT CHANGED SIGNAL COMES IN. I am:", self.res)
		print("  newvalue:", newvalue)
	_change_signal_queue.append({f=_push_rerender_up_tree,arg=newvalue})
	call_deferred("_call_only_once")


func _resource_changed():
	if verbose_change_signals:
		print("RESOURCE CHANGED SIGNAL COMES IN. I am:", self.res)
	_change_signal_queue.append({f=_push_rerender_up_tree, arg=null})
	call_deferred("_call_only_once")


## In here, I check the stack and call only one then clear it.
## Hopefully this forces only one call to _push_rerender_up_tree
## even if two signals are contending for it.
static var _change_signal_queue : Array[Dictionary]
func _call_only_once():
	if _change_signal_queue:
		var _c = _change_signal_queue[0]
		_change_signal_queue.clear()
		if verbose_change_signals:
			print()
			print("======================================================================")
			print("| push render begins from :")
			print("| node:", self)
			print("| res:", self.res)
			print("| ", _change_signal_queue)
			print("| _c:", _c)#.get_object())
			print("======================================================================")
		_visited_clones.clear()
		_c.f.call()
		_change_signal_queue.clear()


		# Because change signals are emitted for each keypress
		# (If we were typing in a LineEdit (String) field!)
		# we have to return early or it's just chaos.
		# TODO: put some kind of timer in here maybe?
		if _c.arg is String: return

		# Refresh the inspector too!
		if board.focus_is_on_board:
			if dbatClassHacks.is_class_custom(resource_classname):
				board.inspect_node(self, true)


static var _visited_clones = []
## Recursive fingers of doubtful veracity reach-out to refresh
## the various nodes and clones of them.
##
## This func only runs from _call_only_once(). It doesn't run from
## the initial load process.
func _push_rerender_up_tree():
	if verbose_change_signals:
		print(" _push_rerender_up_tree awaits on...", self.name)

	# Does the setting of value into the rw node
	# Also sets mode.UPDATE
	await refresh_from_resource()

	if verbose_change_signals:
		print(" _push_rerender_up_tree back from await on ...", self.name)

	var all_i_connect_to : Array = board.get_connection_list().filter(
			func(d):return d.from_node == self.name)
	for conn in all_i_connect_to:
		var next_node = board.map_id_to_rwnode.get(conn.to_node)
		next_node._push_rerender_up_tree()

	# handle clones
	var _all_clones_of_me:Array = board.get_all_cloned_rwnodes_of(self)
	_all_clones_of_me.erase(self)
	for _cl in _all_clones_of_me:
		if _cl not in _visited_clones:
			_visited_clones.append(_cl)
			# in the case of clones, there are more nodes that
			# have slots with old data, so just setting the res above
			# still leaves other clone nodes with bad data
			_cl._replace_slots_from_resource() # go update all their data
			_cl._push_rerender_up_tree()


## Update all clone slots with the resource data.
## in the case of clones, there are more nodes that
## have slots with old data, so just setting the res above
## still leaves other clone nodes with bad data
##
## Also disconnect/reconnect noodles - but I can't recall why
func _replace_slots_from_resource():
	for _idx in range(0,slots.size()):
		if slots[_idx].has("top_slot"): continue
		var var_name = slots[_idx].slot_name
		var var_val = self.res.get(var_name)
		slots[_idx].slot_value = var_val

		var _from_conn_dict = board.get_connection_list().filter(
			func(d):
				return d.to_node == self.name and d.to_port == _idx
		).pop_back()

		if _from_conn_dict:
			# we have a noodle here - so discon it
			var _from_node = board.map_id_to_rwnode[_from_conn_dict.from_node]
			# TODO: There is a case where var_val is an Array and this errors:
			# (When I drag/drop a res (clone) from fs into the value slot.)
			# SCRIPT ERROR: Invalid operands 'Array' and 'Object' in operator '!='
			#print("_from_node:", _from_node, " var_name:", var_name, " var_val:", var_val)
			if var_val is Array:
				#_main_view.feedback("Possible infinite loop in Array.", &"WARNING")
				continue

			# if the var_val is NOT already the resource, then remove the noodle
			if var_val != _from_node.res:
				board.disconnect_node(
					_from_conn_dict.from_node, _from_conn_dict.from_port,
					_from_conn_dict.to_node, _from_conn_dict.to_port
				)
				# This one is tabbed-in to save cpu time
				# if the var_val is NOT null, ie it's something, then make a noodle
				if var_val != null:
					# Make a new noodle
					var _correct_from_node = board.map_resource_to_rwnodes_list[var_val][0]
					board.connect_node(
						_correct_from_node.name, 0,
						_from_conn_dict.to_node, _from_conn_dict.to_port
					)


## Special case. Uses a lambda set in board._on_graph_connection_request
## This is used only when a node emits the force_disconnect signal.
func _force_disconnect():
	if board.discon:
		board.discon.call()
		board.discon = null


## This is where we do all the hide/show stuff
## for the node gui.
func _render_node_gui():
	var _fs:Theme = %classname.get_theme()
	%resname.clear()
	var _rname
	_rname = res.get(&"resource_name")
	if &"name" in res: _rname = res.name
	if _rname:
		%resname.append_text('"' + _rname + '"')

	rwnode_classname_label.clear()
	var _clsn
	_clsn = dbatClassHacks.get_metadata(resource_classname, &"display_class_name_as")
	if _clsn:
		rwnode_classname_label.append_text(_clsn)
	else:
		rwnode_classname_label.append_text(resource_classname)
		_clsn = resource_classname

	if _clsn and _rname:
		rwnode_classname_label.add_theme_font_size_override("normal_font_size",14)
		%resname.add_theme_font_size_override("normal_font_size",17)
	else:
		rwnode_classname_label.add_theme_font_size_override("normal_font_size",17)

	## Change the look
	## Can we find out if this node/res is a clone?
	if_clone_change_style()

	match updown_state:
		node_updown_state.DOWN:
			if _updown: #told to go up
				updown_state = node_updown_state.UP
		node_updown_state.UP:
			if _updown == false: #told to go down
				updown_state = node_updown_state.DOWN


	match updown_state:
		node_updown_state.DOWN:
			_minimize_button.icon = get_theme_icon(&"CodeFoldDownArrow",&"EditorIcons")
			#add_theme_stylebox_override( "titlebar", NSrw.title_normal)
			propagate_call("set_visible",[true])
			%close.visible = false
			%min.visible = false
			_set_preview() # Does its best to ensure a texture
			if _details_visible:
				%details.clear()
				var i = [&"File", &"AutoTriangle"][int(_automade)]
				var txt = ["In file system", "In automade"][int(_automade)]
				%details.add_item(
					txt,
					get_theme_icon(i, &"EditorIcons"),
					false)
				%details.add_item(
					"Node id : " + str(self.name),
					get_theme_icon(&"Node", &"EditorIcons"),
					false)
				%details.add_item(
					_shorten_resource_id(res, true),
					get_theme_icon(&"Object", &"EditorIcons"),
					false)
				%details.add_item(
					"Refcount %s" % str(res.get_reference_count()),
					get_theme_icon(&"CodeRegionFoldedRightArrow", &"EditorIcons"),
					false)
			%deets.visible = _details_visible
			var _icc:bool = dbatClassHacks.is_class_custom(resource_classname)
			%refresh.visible = _icc
			%editscript.visible = _icc
			%comment_text.custom_minimum_size=Vector2(0, 64)
			size = Vector2(0,0) # forces a nice shrinkwrap size.

		node_updown_state.UP:
			_minimize_button.icon = get_theme_icon(&"CodeFoldedRightArrow",&"EditorIcons")
			# Propogate false seems to be how to properly hide the slot children!
			propagate_call("set_visible",[false], true)
			self.visible = true
			%topslot.propagate_call("set_visible",[true], true)
			%close.visible = false
			%min.visible = false
			%info.visible = false
			%buttons.visible = false
			%details.visible = false
			%comment_text.visible = false
			res_preview.visible = false
			#add_theme_stylebox_override( "titlebar", NSrw.title_rolled_up)
			var _hboxkids := find_children("*","HBoxContainer",false,false)
			var tb = _hboxkids.pop_front() # title bar
			tb.propagate_call("set_visible",[true]) # make all its kids visible
			for s in _hboxkids: # Now hide the rest of the slots
				s.set_size(Vector2(1,0)) # Vital to moving the noodles up!
				s.propagate_call("set_visible",[false])
			var newsize = %icon_and_classname.size
			newsize.y += _hboxkids.size()*2 + 10 + tb.size.y
			size = newsize

	%close.visible = false
	%min.visible = false

	# Draw any extra extension gui stuff on the end
	if res.has_method("show_node_gui"):
		## we are a special resource
		res.show_node_gui(self, false)

	# Still have to do this in 4.4 dev
	_noodle_jiggle()



## If all you have is a property name from some resource, gets
## the classname of that property.
## Slightly dodgy...
func _get_class_name_from_resource_property(propsdict):
	# var properties = res.get_property_list()
	var hs:String = propsdict.hint_string
	if propsdict.type == TYPE_ARRAY: #28
		return "Array"
	# works ok with one, or, more, csv, strings
	var theclass:PackedStringArray = hs.split(",",false)
	if theclass.is_empty():
		return dbatClassHacks.NO_CLASS_NAME
	var ret = String(theclass[0])
	return ret


func _theme_setup():
	_my_panel_normal = NSrw.frame_style.duplicate()
	_my_panel_selected = NSrw.frame_style.duplicate()
	_my_titlebar_normal = NSrw.title_normal.duplicate()
	_my_titlebar_selected = NSrw.title_normal.duplicate()

	# Add some StyleBoxes to the overrides
	add_theme_stylebox_override( &"panel", _my_panel_normal)
	add_theme_stylebox_override( &"panel_selected", _my_panel_selected)
	add_theme_stylebox_override( &"titlebar", _my_titlebar_normal)
	add_theme_stylebox_override( &"titlebar_selected", _my_titlebar_selected)
	_change_colors()


func _change_colors(blah := &"normal"):
	match blah:
		&"normal":
			_my_panel_normal.bg_color = \
				_ed_settings.get_setting("interface/theme/base_color")
			_my_titlebar_normal.bg_color = \
				_ed_settings.get_setting("interface/theme/base_color").darkened(0.5)
			_my_panel_selected.bg_color = \
				_ed_settings.get_setting("interface/theme/accent_color").darkened(0.3)
		&"clone":
			_my_panel_normal.bg_color = \
				_ed_settings.get_setting("interface/theme/base_color").darkened(0.15)
			_my_titlebar_normal.bg_color = \
				_ed_settings.get_setting("interface/theme/base_color")#.darkened(0.8)
			_my_panel_selected.bg_color = \
				_ed_settings.get_setting("interface/theme/accent_color").darkened(0.5)
	_my_titlebar_selected.bg_color = _my_panel_selected.bg_color


## Only allow is Object through. Disallow Scripts.
func _allow_through(dict:Dictionary)->bool:
	# When you call res.get_property_list you get too much info
	# Some of it is from ancestor classes that do not apply.
	# Example StandardMaterial3D has no orm_texture prop, but it's
	# in the list because it comes from BaseMaterial3D...
	# Happily, the usage flag is 0 when that prop is not intended for the
	# object involved!
	if dict.usage == 0: return false

	if dict.class_name in _editor_plugin.blocked_resource_classes:
		return false
	var obj = res.get(dict.name)
	if dict.name == "script":
		return false
	match dict.type:
		24 : return true #Object
		28 : #Array
			#24/17:BoxMesh == Array[BoxMesh] etc.
			# Ensure an Array[<Resource>]
			if "24/17:" in dict.hint_string: #TODO hard-coding stuff bad..
				return true
	return false


## I want automatic "slot type" ints for the graph ports
## I will try to make them from the hash of the string of a class_name.
func _get_slot_type(classname:String)->int:
	return dbatGeneralUtils.smallhash(_get_slot_type_name(classname,{}))


func _get_slot_type_name(classname, prop_dict:Dictionary)->String:
	if classname == "Array":
		if prop_dict:
			if "24/17:" in prop_dict.hint_string:
				classname = prop_dict.hint_string.replace("24/17:","")
			# poss that classname = "" at this point. It was an array, but not
			# of a Resource type.
		else:
			classname = &"BAD_PROPERTY_ARRAY_TYPE"
		return classname

	# catch empty classname
	if classname == "" or classname == dbatClassHacks.NO_CLASS_NAME:
		_main_view.feedback("There is no class name for this object", &"WARNING")
		return dbatClassHacks.NO_CLASS_NAME

	if classname in _editor_plugin.blocked_resource_classes:
		return &"BLACKLISTED_CLASS"

	return classname


func _get_port_col(classname:String)->Color:
	var tot:=classname.length()
	# Doing this to get a unique number for the path of ancestors
	# A simple array.size() would be the same for different classes
	var ancestors := "".join(dbatClassHacks.get_ancestors(classname)).length()
	var c:Color = Color.BLACK
	var h:float = sin(deg_to_rad(ancestors + tot))
	var s:float = sin(deg_to_rad(ancestors) * PI)
	s = remap(s,-1., 1., 0.3, 0.7)
	c = c.from_hsv(h, s, 1.)
	return c


## This was a beast to get working. It makes preview textures
## of a resource which appear in the node.
func _set_preview():
	#print()
	#print("_set_preview")
	#print("  TOP")
	#print("   res:", res)
	#print("  path:", res.resource_path)

	if board and _editor_plugin:
		var rp := EditorInterface.get_resource_previewer()
		# This works better to force preview updates!
		rp.check_for_invalidation(res.resource_path)

		var _prev = res

		if &"preview_this" in res: # bug I reported was fixed! We can use `in` again!
			_prev = res.preview_this
			if verbose_preview:
				print("Using preview_this:", _prev)
			if not _prev: _prev = _blank

		if _prev is Mesh:
			if _prev is ArrayMesh: # ArrayMesh is not liked, so cast to Mesh
				_prev = _prev as Mesh

		elif _prev is NoiseTexture2D or _prev is Noise:
			if _prev is Noise:
				var _noisetex : NoiseTexture2D = NoiseTexture2D.new()
				_noisetex.noise = _prev
				await _noisetex.changed
				_prev =_noisetex.get_image()
			elif _prev is NoiseTexture2D:
				var _texture:NoiseTexture2D = _prev.duplicate()
				await _texture.changed
				_prev = _texture.get_image()
				if not _prev:
					_prev = _blank

		elif _prev is Gradient:
			var _gtex : GradientTexture2D = GradientTexture2D.new()
			_gtex.gradient = _prev
			_prev = _gtex.get_image()

		elif _prev is GradientTexture2D or _prev is GradientTexture1D:
			if _prev.gradient == null:
				_prev = _blank
			else:
				# had to force a duplicate to get a live preview.
				var _tmp = _prev.duplicate()
				# In the case of GradientTextures, await does not work
				# await _tmp.changed
				_prev = _tmp

		if verbose_preview:
			print("  set preview for:", _prev)

		#print()
		#print("_set_preview")
		#print("  END, before the queue call")
		#print("   res:", res)
		#print("  _prev:", _prev)
		#print("  path:", res.resource_path)
		#print("  _prev path:", _prev.resource_path)

		rp.queue_edited_resource_preview( _prev, self,
				"_resource_preview_ready", _prev)

		#print()
		#print("_set_preview")
		#print("  END after the queue")
		#print("  _prev:", _prev)
		#print("  path:", res.resource_path)
		#print("  _prev path:", _prev.resource_path)


## Part 2 of the preview process.
func _resource_preview_ready(path:String, texture:Texture2D,
		thumbnail_preview:Texture2D, nam):
	# PS rpath is gone here!
	#print()
	#print("_resource_preview_ready")
	#print("  path:", res.resource_path)

	res_preview.texture = null
	res_preview.owner = null # Prevent rwnode.tscn saving this data inside
	if texture:
		if verbose_preview:
			print("   ready with:", texture)
			print("   size:", texture.get_size())
		res_preview.texture = texture
		## Replaced this with better sizing choices in the actual scene file
		res_preview.visible = true
	else:
		res_preview.texture = null
		res_preview.custom_minimum_size = Vector2(0,0)
		res_preview.visible = false

	# have to redo this here to get node to resize...
	size = Vector2(0,0)


### Forces the noodles to line-up properly
func _noodle_jiggle():
	await get_tree().process_frame
	position_offset += Vector2.UP
	await get_tree().process_frame
	position_offset -= Vector2.UP


func _shorten_resource_id(r, not_too_short=false)->String:
	# r is an Object or an Array
	if r is Array:
		if r.is_empty():
			return ""#<empty array>"
		return "<%s>" % r.size()
	if r:
		var s = str(r)
		var ret : String
		if not_too_short:
			var hash = s.find("#")+2
			ret = "RES %s..%s" % [s.substr(hash,4), s.right(5)]
		else:
			ret = "…%s" % [s.right(5)]
			#ret = "<RES#%s..%s" % [s.substr(11,4), s.right(6)]
		ret = ret.rstrip(">")
		return ret
	return ""#<null>"


func _on_refresh_pressed() -> void:
	_rwstate = mode.RENEW
	await draw_node()


func _on_info_pressed() -> void:
	_details_visible = not _details_visible
	_render_node_gui()


func _on_editscript_pressed() -> void:
	## Open the resource's script in the editor
	var s:Script = res.get_script()
	EditorInterface.edit_script(s)
	EditorInterface.set_main_screen_editor("Script")


func _on_showinfs_pressed() -> void:
	board.show_in_filesystem(self)


func _on_close_pressed() -> void:
	delete_request.emit()


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		#if event.double_click:
			#_updown = !_updown
			#accept_event()
			#_render_node_gui()
		#else:
		if not event.double_click:
			# The start of a drag node
			if event.button_mask == 1:
				if self.res is Shader:
					accept_event() # prevent weird draggin situations
				board.inspect_node(self, true)

			if event.button_index == 2:
				accept_event()
				emit_signal("popup_menu_request", event.global_position)

	if event is InputEventKey and event.is_pressed():
		match event.as_text():
			"Escape":
				board.grab_focus()


## This is here so we can undo moves of nodes
func _on_dragged(from: Vector2, to: Vector2) -> void:
	_undo_redo.create_action("Move node")
	_undo_redo.add_do_method(self, "_set_position_offset",  to)
	_undo_redo.add_undo_method(self, "_set_position_offset", from)
	_undo_redo.commit_action()


func _set_position_offset(offset: Vector2) -> void:
	position_offset = offset


## Used *only* from an undoredo in _slot_clear_button_pressed below
## Triggers a slot_changed signal so the node gets redrawn etc.
func _set_slot_value(idx, val):
	slots[idx].slot_value = val
	slot_changed.emit()


## Clear the slot's name and value
## Also remove any noodle going into it.
func _slot_clear_button_pressed(idx):
	var val = slots[idx].slot_value
	_undo_redo.create_action("Clear slot")
	if slots[idx].is_array:
		_undo_redo.add_do_method(self, "_set_slot_value", idx, [])
		_undo_redo.add_undo_method(self, "_set_slot_value", idx, val)
		_undo_redo.add_undo_method(self, "refresh_from_resource")
	else:
		_undo_redo.add_do_method(self, "_set_slot_value", idx, null)
		_undo_redo.add_undo_method(self, "_set_slot_value", idx, val)
		_undo_redo.add_undo_method(self, "refresh_from_resource")
	var cl = board.get_connection_list()
	# find myself in the list, also narrow it down to the exact to_port
	# should return only one element (or none) in cl:
	cl = cl.filter(func(i):return i.to_node == self.name and i.to_port == idx)
	if not cl.is_empty():
		for d in cl:
			var from_port = d.from_port
			var to_port = d.to_port
			var from_node = d.from_node
			var to_node = self.name
			_undo_redo.add_do_method(
					board, "disconnect_node", from_node, from_port, to_node, to_port)
			_undo_redo.add_undo_method(
					board, "connect_node",  from_node, from_port, to_node, to_port)
	_undo_redo.commit_action()
	accept_event()
	# board inspect_node is now done in the changed handlers, in call_only_once


## Open help!!
func _on_help_pressed() -> void:
	var _ed = EditorInterface.get_script_editor().get_current_editor()
	if not _ed:
		if dbatClassHacks.is_class_custom(resource_classname):
			# force the script to show in the editor and then try again.
			var s:Script = res.get_script()
			EditorInterface.edit_script(s)
			EditorInterface.set_main_screen_editor("Script")
			await get_tree().physics_frame
	# try again...
	_ed = EditorInterface.get_script_editor().get_current_editor()
	if _ed:
		_ed.go_to_help.emit(resource_classname)
		return
	_main_view.feedback("Can't open the help. Open the script editor (to any script) and try again.")



func _on_min_pressed() -> void:
	_updown = !_updown
	_render_node_gui()
