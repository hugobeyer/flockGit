@tool
class_name rwResourceChooser extends "./chooser_node_base.gd"

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


## I split this into a base class because I had a second chooser
## which has since gone away.
## Maybe this will help if new future choosers need to happen...


static var last_filter:String

@onready var _filter = %filter
@onready var _resources = %resources

var items:Array[Dictionary]

var _categories:Dictionary

func _ready() -> void:
	editor_resource_picker.base_type="Resource"


func _setup(_board,_posoff):
	super(_board,_posoff)
	_filter.grab_focus()
	_filter.text = ""
	items.clear()
	_scan_for_node_categories()


func _setsize(list):
	var width = _resources.size.x
	var rows = 20
	if list.size() < rows: rows = list.size() + 1
	var rowh = _resources.get_item_rect(0).size.y
	var height = (rows * rowh)
	_resources.set("size", Vector2(width, height) )
	var thenode = Vector2(width, height + (3*rowh) )
	self.set("size", thenode )


## May 2024
## Moved the rw_metadata to a func in the resource script.
## Build-up an array named _categories that holds a dict
## The final item UI will be built from this array.
func _scan_for_node_categories():
	_categories.clear()
	var a = ProjectSettings.get_global_class_list()
	for dict in a:
		if dbatClassHacks.can_we_instantiate(dict.class):
			var _cat = dbatClassHacks.get_metadata(dict.class, &"category")
			if _cat:
				if not _categories.has(_cat):
					_categories[_cat] = []
				var _dn = dbatClassHacks.get_metadata(dict.class, &"display_class_name_as")
				if not _dn : _dn = dict.class
				_categories[_cat].append({_class_name = dict.class, label=_dn})


# MAKE_FROM_POPUP - list ALL resources possible
func kind1_setup(_board, _posoff):
	kind = KIND.MAKE_FROM_POPUP
	_setup(_board, _posoff)
	var los:Array = editor_resource_picker.get_allowed_types()
	if los:
		los.sort()
		# filter out those classes we cannot instantiate
		# We also can't make a basic "Resource" type. It goes haywire.
		los = los.filter(func(i):
			return dbatClassHacks.can_we_instantiate(i) and i != "Resource")

		var _tmplist = []
		items.clear()

		for _category_name in _categories.keys():
			# Make an Item that reps the Category
			items.append({
				kind = &"cat",
				label = _category_name,
				_class_name = &""
			})

			var _catdict = _categories[_category_name]
			for class_label_dict in _catdict: #Each dict in this category
				# Make an item for this resource class
				items.append({
					kind = &"class",
					label = class_label_dict.label,
					_class_name = class_label_dict._class_name
				})
				_tmplist.append(class_label_dict._class_name)

		# All the other Resource classnames
		items.append({
			kind = &"cat",
			label = "All Resources",
			_class_name = &""
		})
		# List all the other resources (not in categories)
		for _cn in los:
			if not _cn in _tmplist:
				items.append({
					kind = &"class_all",
					label = _cn,
					_class_name = _cn
				 })

		# Now go draw that all
		_fill_resources_list([])

	_filter.text = last_filter
	if last_filter:
		_do_filter(last_filter)


# MAKE_FROM_INPUT_PORT_DROP_TO_EMPTY - list specific family of resources
func kind2_setup(_board, _rwnode, _classname, _posoff, _slot, _to, _to_port):
	kind = KIND.MAKE_FROM_INPUT_PORT_DROP_TO_EMPTY
	_setup(_board, _posoff)
	var los:Array

	editor_resource_picker.base_type = _classname
	var ok:Array = editor_resource_picker.get_allowed_types()
	if ok:
		ok = ok.filter(func(i):
			return dbatClassHacks.can_we_instantiate(i) and i != "Resource")

	if dbatClassHacks.can_we_instantiate(_classname) and _classname not in ok:
		los.append(_classname)
	los.append_array(ok)

	if los:
		los.sort()
		var d := {
			"from_rwnode" = _rwnode,
			"from_slot" = _slot,
			"release_position" = _posoff,
			"to" = _to,
			"to_port" = _to_port,
		}
		if los.size() == 1:
			# I am hijacking this func to cater-for the case when there is
			# only *one* choice in the list, so don't bother me with a popup
			# Simulate the process and the click etc.
			set_meta("situation", d)
			new_chooser_choice_made.emit(kind, los[0])
			return
		else:
			items.clear()
			for _cn in los:
				items.append({
					kind = &"class_all",
					label = _cn,
					_class_name = _cn
				})
			_fill_resources_list([],d)

	_filter.text = last_filter
	if last_filter:
		_do_filter(last_filter)


var _ed_settings := EditorInterface.get_editor_settings()

func _fill_resources_list(_items, passthru_dict={}):
	if _items.is_empty():
		_items = items
	# Show the actual chooser node etc.
	_resources.clear()
	var i:int
	for _dict in _items:
		match _dict.kind:
			&"cat":
				i = _resources.add_item(_dict.label, null, false)
				var _col = _ed_settings.get_setting(
					"interface/theme/base_color").darkened(0.5)
				_resources.set_item_custom_bg_color(i,_col)
			&"class":
				var resclass = _dict._class_name
				if not resclass in _editor_plugin.blocked_resource_classes:
					var icon = dbatClassHacks.get_icon_for(resclass, _editor_plugin)
					resclass = "%s (%s)" % [_dict.label, _dict._class_name]
					i = _resources.add_item(resclass, icon)
					# Put the class_name into item metadata
					_resources.set_item_metadata(i,_dict._class_name)
			&"class_all":
				var resclass = _dict._class_name
				if not resclass in _editor_plugin.blocked_resource_classes:
					var icon = dbatClassHacks.get_icon_for(resclass, _editor_plugin)
					i = _resources.add_item(resclass, icon)
					# Put the class_name into item metadata
					_resources.set_item_metadata(i,_dict._class_name)

	# record that passed-thru dict from board in my meta
	if passthru_dict:
		set_meta("situation", passthru_dict)
	call_deferred("_setsize", _items)


func _on_filter_text_changed(new_text: String) -> void:
	if new_text:
		_do_filter(new_text)
		last_filter = new_text
	else:
		_fill_resources_list([])
	last_filter = new_text


func _do_filter(filter:String):
	var newa:Array = items.filter(
		func(d):
			# cover 'class' and 'class_all' in one go:
			return "class" in d.kind  and \
			_filter.text.to_upper() in d._class_name.to_upper()
	)
	_fill_resources_list(newa)


func _on_list_item_activated(index: int) -> void:
	# The actual class name is in the metadata
	var res_class_name : String = _resources.get_item_metadata(index)
	if res_class_name:
		new_chooser_choice_made.emit(kind, res_class_name)


func _on_filter_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.as_text():
			"Escape":
				board.call_deferred("close_chooser_rwnode")
