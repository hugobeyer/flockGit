@tool
extends MarginContainer

# MIT License
#
# Copyright (c) 2023 Donn Ingle (donn.ingle@gmail.com)
# Copyright (c) 2022 Nathan Hoad (Thank you!)
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


## This script concerns itself with the top menu bar.
## It manages the board_database for the board below.
## The board is in the MainView SCENE tho, so look there.

const VERBOSE := false

var editor_plugin: EditorPlugin

var board_database : NSrw.rwBoardDatabase:
	set(bd):
		board_database = bd
		if bd:
			%board_name.text = bd.id


var undo_redo: EditorUndoRedoManager:
	set(next_undo_redo):
		undo_redo = next_undo_redo
		board.undo_redo = next_undo_redo
	get:
		return undo_redo


var _messages := []
var FileSysDock := EditorInterface.get_file_system_dock()

@onready var board := %Board
@onready var opendialog:FileDialog
@onready var newdialog:FileDialog


func _ready() -> void:
	opendialog = dbatGeneralUtils.mk_file_dialog(
		["*.tres"], FileDialog.FILE_MODE_OPEN_FILE)
	add_child(opendialog)
	opendialog.file_selected.connect(_on_open_file_selected)

	newdialog = dbatGeneralUtils.mk_file_dialog(
		["*.tres"], FileDialog.FILE_MODE_SAVE_FILE)
	add_child(newdialog)
	newdialog.file_selected.connect(_on_newdialog_file_selected)

	FileSysDock.files_moved.connect(_file_changed_mainview, CONNECT_REFERENCE_COUNTED)
	FileSysDock.file_removed.connect(_file_rm_mainview, CONNECT_REFERENCE_COUNTED)

	%locate.icon = get_theme_icon(&"ShowInFileSystem", &"EditorIcons")
	%settings.icon = get_theme_icon(&"Tools", &"EditorIcons")
	%board_name.right_icon = get_theme_icon(&"Edit", &"EditorIcons")

	custom_minimum_size = Vector2(100,200)

func _exit_tree() -> void:
	remove_child(opendialog)
	remove_child(newdialog)


# PUBLIC FUNCS


func setup(_ep, _undoredo):
	self.editor_plugin = _ep
	self.undo_redo = _undoredo
	rwSettings.setup()
	board.setup(self)
	# let's see if the recent_boards list is still valid
	rwSettings.verify_recent_boards()
	board.board_tres_dropped.connect(func(r):
		call_deferred("_open_board", r.resource_path)
		)
	%feedback/msg.text = ""
	%board_name.text = ""
	### Get last board, or new
	#if board_database:
		#board_database.free() # cant it's recounted

	board_database = null
	board_database = rwSettings.get_most_recent_board()

	if board_database:
		_after_open()

	%main_menu.menu_pressed.connect(_menu_item_pressed)
	%main_menu.recent_pressed.connect(_open_recent)


# Thanks to https://mastodon.gamedev.place/@exoticorn
# Honestly, this func bends my brain! Thanks Exoticorn.
func feedback(msg:StringName, style=&"NORMAL"):
	var msg_speed := 1
	var _time
	_messages.push_back([msg,style])
	if _messages.size() == 1:
		%feedback.show()
		while not _messages.is_empty():
			var num:=_messages.size()
			_time = msg_speed/num
			var _tup = _messages[0]
			var _msg = _tup[0]
			%feedback/msg.text = _msg
			var styl = _tup[1]
			if styl == &"WARNING":
				%feedback/icon.texture = get_theme_icon(
					&"StatusWarning", &"EditorIcons")
				push_warning(_msg)
			elif styl == &"ERROR":
				%feedback/icon.texture = get_theme_icon(
					&"StatusError", &"EditorIcons")
				push_error(_msg)
			else:
				%feedback/icon.texture = get_theme_icon(
					&"NodeInfo", &"EditorIcons")
				print("Feedback: ", _msg)
			await get_tree().create_timer(_time).timeout
			_messages.pop_front()
		%feedback.hide()


## Called from plugin.gd
func apply_changes() -> void:
	if is_instance_valid(board):
		_save_board()

		board.apply_graph_settings()


# PRIVATE FUNCS


func _on_board_name_text_submitted(new_text: String) -> void:
	if not board_database: return
	rwSettings.rm_from_recent_boards(board_database.resource_path)
	board_database.rename(new_text, true)
	%main_menu.make_menu()
	_save_board()
	dbatGeneralUtils.refresh_filesystem()


func _menu_item_pressed(what):
	match what:
		&"open":
			feedback(&"Saving current board first..")
			_save_board()
			opendialog.visible = true
		&"save":
			_save_board()
		&"new":
			feedback(&"Saving current board first..")
			_save_board()
			_new_board()
		&"clear":
			rwSettings.save_setting(&"recent_boards", [])
			%main_menu.make_menu()


## The "opendialog" dialog has finished
func _on_open_file_selected(paf: String) -> void:
	opendialog.visible = false
	_open_board(paf)


func _open_recent(paf:String):
	if board_database and board_database.resource_path == paf:
		return
	feedback(&"Saving current board first..")
	_save_board()
	_open_board(paf)


func _open_board(paf):
	if paf:
		if board_database and board_database.resource_path == paf:
			feedback(&"Already open.")
			return
		feedback(&"Opening board..")
		board_database = NSrw.rwBoardDatabase.load(paf)
		if not board_database:
			feedback("Failed to open that Board", &"ERROR")
			rwSettings.rm_from_recent_boards(paf)
			%main_menu.make_menu()
			_activate_buttons()
		else:
			_after_open()


func _after_open():
	%main_menu.make_menu()
	_activate_board()


func _save_board() -> void:
	# There's some startup timing thing that causes a bunch of errors.
	# Making sure there's an editor_plugin here seems to stop that.
	if not editor_plugin: return
	if not board_database: return
	board.save_graph_settings()
	var new_name:String = %board_name.text.replace(".tres","")
	# If the name was changed, then remove old file, take over new path
	if board_database.id != new_name:
		board_database.rename(new_name)
	if board_database.resource_path == "":
		feedback(&"Board needs a name.", &"WARNING")
		return
	board_database.save(board, new_name)
	rwSettings.add_to_recent_boards(board_database.resource_path)
	%main_menu.make_menu()


func _new_board() -> void:
	newdialog.show()

func _on_newdialog_file_selected(path: String) -> void:
	newdialog.hide()
	board.clear()

	board_database = NSrw.rwBoardDatabase.new()

	# flag that we made this board WITHIN rw ui:
	board_database.board_created_outside_rw = false

	# directly after new, set the resource_path
	board_database.set_new_paf(path)

	%board_name.text = board_database.id
	_activate_board()

	# Added this Spet 4 2024.
	_save_board()


func _activate_board() -> void:
	board.process_mode = Node.PROCESS_MODE_ALWAYS
	board.visible = true
	#board.update_minimum_size()
	feedback(&"Activating board.")
	board.from_serialized(board_database)
	_activate_buttons()
	#OS.low_processor_usage_mode = true


func _activate_buttons():
	%locate.visible = true
	%board_name.visible = true


var last_scroll_offset:Vector2
func _on_main_view_visibility_changed() -> void:
	var editor_scale: float = EditorInterface.get_editor_scale()
	if is_instance_valid(board):
		if not visible:
			last_scroll_offset = board.scroll_offset / editor_scale
		else:
			await board.fix_noodles()
			board.scroll_offset = last_scroll_offset * editor_scale


func _on_locate_pressed() -> void:
	EditorInterface.get_file_system_dock().navigate_to_path(
			board_database.resource_path)


func _on_settings_pressed() -> void:
	dbatGeneralUtils.show_settings(self)


func _file_changed_mainview(f,t):
	rwSettings.verify_recent_boards()


func _file_rm_mainview(paf):
	# Have seen this called where board_database is "Nil" ...Weird af.
	if board_database:
		# resource_path is empty because the resource has been deleted
		if board_database.resource_path == "":
			rwSettings.verify_recent_boards()
			%main_menu.make_menu()
			feedback("Board has just been deleted in the FileSystem!", &"WARNING")
			board_database = null
			_disable_board()


func _disable_board():
	print("HERE")
	OS.low_processor_usage_mode = false
	board.process_mode = Node.PROCESS_MODE_DISABLED
	%board_name.text = ""
	%locate.visible = false
	%board_name.visible = false
	%Board.visible = false # make it obvious that it's gone!


func _on_manage_resources_pressed() -> void:
	for _rwnode in board.map_id_to_rwnode.values():
		print(_rwnode.res)
