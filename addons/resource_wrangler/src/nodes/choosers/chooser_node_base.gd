@tool
class_name rwChooserBase
extends GraphNode

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

signal new_chooser_choice_made(kind:int, txt:String)

enum KIND {
	NONE,
	MAKE_FROM_POPUP,
	MAKE_FROM_INPUT_PORT_DROP_TO_EMPTY,
	MAKE_FROM_OUTPUT_DROP_TO_EMPTY
}

#const NSrw = preload("../../../ns.gd")

var board:Control
var _editor_plugin:EditorPlugin:
	get:
		return board.main_view.editor_plugin

var kind : KIND = KIND.NONE

# July 2023 : The EditorResourcePicker object is a Node, but I could
# not figure out how to show or use it. It's still useful but I had to
# make the entire gui manually.
@onready var editor_resource_picker := EditorResourcePicker.new()


func _exit_tree() -> void:
	if not editor_resource_picker.is_queued_for_deletion():
		editor_resource_picker.queue_free()


func _on_close_request() -> void:
	board._close_chooser_thing()


func _setup(_board,_posoff):
	board = _board
	position_offset = _posoff


func _on_filter_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		match event.as_text():
			"Escape":
				board.call_deferred("_close_chooser_thing")
